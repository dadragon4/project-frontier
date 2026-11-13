-- Runs the current movement state and owns the character's intended
-- horizontal velocity.
--
-- Roblox's Humanoid still does the physical walking (floor contact, stairs,
-- replication). Each frame we work out a velocity with our own rules and
-- tell the Humanoid to walk that way at that speed. Some states (mantle,
-- vault, ledge hang, wall-run) switch the Humanoid to its "Physics" state
-- and move the body themselves.
--
-- The character is always in exactly one state. A state module has:
--     enter(ctx, previousStateName)   optional
--     update(ctx, dt) -> string?      return another state's name to switch
--     exit(ctx)                       optional
-- and optional flags:
--     controlsBody        moves the body itself (no walk instructions)
--     blocksJump          no jumping from here
--     allowsGroundRoll    the roll key rolls from here
--     allowsClamber       vault / mantle / ledge grab can start here
--     staminaCost         costs stamina once, on entering (key of Stamina.Costs)
--     staminaDrain        costs stamina per second (key of Config.Stamina)
--     flowAction          counts toward a FLOW chain under this name
--     clearsSprintToggle  entering it switches a toggled sprint off
-- ctx is this controller.
--
-- All stamina and FLOW bookkeeping happens in setState, the one place
-- every state change goes through, so each action is counted exactly once.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("MovementConfig"))
local Stamina = require(Shared:WaitForChild("Stamina"))
local FlowChain = require(Shared:WaitForChild("FlowChain"))
local Settings = require(script.Parent.Parent:WaitForChild("Settings"))
local Detection = require(script.Parent:WaitForChild("Detection"))

local StatesFolder = script.Parent:WaitForChild("States")
local States = {
	Walk = require(StatesFolder:WaitForChild("Walk")),
	Sprint = require(StatesFolder:WaitForChild("Sprint")),
	Crouch = require(StatesFolder:WaitForChild("Crouch")),
	Slide = require(StatesFolder:WaitForChild("Slide")),
	Air = require(StatesFolder:WaitForChild("Air")),
	Roll = require(StatesFolder:WaitForChild("Roll")),
	Mantle = require(StatesFolder:WaitForChild("Mantle")),
	Vault = require(StatesFolder:WaitForChild("Vault")),
	LedgeHang = require(StatesFolder:WaitForChild("LedgeHang")),
	WallRun = require(StatesFolder:WaitForChild("WallRun")),
	Prone = require(StatesFolder:WaitForChild("Prone")),
	Dive = require(StatesFolder:WaitForChild("Dive")),
}

local RENDER_STEP_NAME = "FrontierMovement"
local PRE_STEP_NAME = "FrontierMovementPre"

local MovementController = {}
MovementController.__index = MovementController

-- Raycast checks (obstacles, walls, room to stand) live in Detection.luau.
for name, fn in Detection do
	MovementController[name] = fn
end

local function planar(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Move vector `current` toward `target` by at most `maxDelta`.
local function moveToward(current: Vector3, target: Vector3, maxDelta: number): Vector3
	local delta = target - current
	local distance = delta.Magnitude
	if distance <= maxDelta or distance < 1e-4 then
		return target
	end
	return current + delta / distance * maxDelta
end

function MovementController.new(character: Model, input)
	local self = setmetatable({}, MovementController)

	self.character = character
	self.humanoid = character:WaitForChild("Humanoid") :: Humanoid
	self.root = character:WaitForChild("HumanoidRootPart") :: BasePart
	self.input = input
	self.config = Config
	self.settings = Settings

	self.velocity = Vector3.zero -- intended horizontal velocity
	self.wishDir = Vector3.zero -- direction the player is asking for (unit, or zero)
	self.forward = Vector3.new(0, 0, -1) -- camera facing, flattened
	self.grounded = true
	self.airTime = 0
	self.crouched = false -- states set this; the body lowers to match
	self.sprintOn = false -- Toggle sprint mode: is the sprint switch on? (see wantsSprint)
	self.prone = false -- true in Prone and Dive (set by setState); the body lowers further
	self.lastSlideEnd = -math.huge
	self.lastSlideHop = -math.huge
	self.leftGroundAt = 0 -- os.clock() when the feet last left the floor
	self.landedAt = 0 -- os.clock() of the most recent landing
	self.lastClamberEnd = -math.huge
	self.pendingObstacle = nil -- found by findObstacle, read by Vault / Mantle / LedgeHang
	self.pendingWall = nil -- found by findWallRunWall, read by WallRun
	self.wallNormal = nil -- set while wall-running (the camera tilts away from it)
	self.lastWallNormal = nil -- the wall last run on; cannot run it again until landing
	self.wishOverride = nil -- set by scripted tests to replace the player's move direction
	self.forwardOverride = nil -- set by scripted tests to replace the camera's facing
	self.cameraPitch = 0 -- extra camera pitch in radians, applied by the camera
	self.quickTurnRemaining = 0 -- radians of quick-turn still to apply; the camera does the turning
	self.quickTurnApplied = 0 -- radians of quick-turn the camera applied since the last frame (not steering)
	self.lastYaw = nil -- camera heading last frame, for camera steering
	self.cameraYawDelta = 0 -- how far the view turned this frame, radians (left is positive)
	self.airPeakY = 0 -- highest the feet have been during the current time in the air
	self.lastFallHeight = 0 -- how far the feet dropped (peak to landing) on the most recent landing

	-- Run on this client for now; the server will check it later (M1.4).
	self.stamina = Stamina.new(Config.Stamina)
	self.flow = FlowChain.new(Config.Flow)
	self.drainScale = 1 -- share of the current state's stamina drain that is charged (momentum lowers it)
	self.blockedGraceUntil = 0 -- until this time, a speed jump is not treated as hitting a wall
	self.lastMomentumDiscount = 0 -- share taken off the most recent action's cost (debug readout, tests)
	self.lastFlowReward = 0 -- stamina the most recent chain payout gave (debug readout, tests)
	self._flowQueue = {} -- instant FLOW actions waiting for the current change of state to finish

	self.stateName = ""
	self.state = nil
	self.stateTime = 0

	self._appliedDrop = 0 -- studs the body is currently lowered by
	self._destroyed = false
	self._jumped = false -- true from take-off until we are back on the ground
	self._jumpedAt = 0
	self._jumpLandedAt = -math.huge -- when we last landed from a jump (for the jump cooldown)
	self._jumpOff = false -- true while the Humanoid's own jump is switched off
	self.jumpCount = 0 -- jumps in the current run of jumps (jump fatigue)
	self._jumpFatigueUntil = -math.huge -- no jumping before this (after the lowest jump)
	self._lastJumpHeight = Config.JumpHeight -- how high the jump in progress was set to go

	-- Fires for every jump, whoever started it.
	self._stateChanged = self.humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping then
			self._jumped = true
			self._jumpedAt = os.clock()
			self.input.consume("Jump")
			-- Jump fatigue: note this jump's height; the next one is lower.
			self._lastJumpHeight = self.humanoid.JumpHeight
			self.jumpCount += 1
		end
	end)

	-- Toggle sprint mode: flip the switch on the press itself, so a press
	-- that a state uses up (a slide cut short) still counts.
	self._sprintPressed = input.Pressed:Connect(function(action: string)
		if action == "Sprint" and self.settings.get("SprintMode") == "Toggle" then
			self.sprintOn = not self.sprintOn
		end
	end)

	self.rayParams = RaycastParams.new()
	self.rayParams.FilterType = Enum.RaycastFilterType.Exclude
	self.rayParams.FilterDescendantsInstances = { character }

	self.overlapParams = OverlapParams.new()
	self.overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	self.overlapParams.FilterDescendantsInstances = { character }
	self.overlapParams.RespectCanCollide = true

	self.lastGroundY = self:getFeetY() -- height of the floor we last stood on

	-- While a state moves the body itself, gravity would still drag it down
	-- between frames (a wall-run sinks, a hang sags). This force, equal to the
	-- character's weight, cancels gravity during those states only.
	local attachment = Instance.new("Attachment")
	attachment.Name = "FrontierGravityCancel"
	attachment.Parent = self.root
	local gravityCancel = Instance.new("VectorForce")
	gravityCancel.Name = "FrontierGravityCancel"
	gravityCancel.Attachment0 = attachment
	gravityCancel.RelativeTo = Enum.ActuatorRelativeTo.World
	gravityCancel.ApplyAtCenterOfMass = true
	gravityCancel.Enabled = false
	gravityCancel.Parent = self.root
	self._gravityCancel = gravityCancel

	self.humanoid.UseJumpPower = false
	self.humanoid.JumpHeight = Config.JumpHeight

	self:setState("Walk")

	-- Each frame, in order:
	--   1. just before Roblox's control script: clear the Humanoid's move direction;
	--   2. Roblox's control script reads the keys / stick into it;
	--   3. just after: we read that wish, apply our rules, and give the Humanoid
	--      the final instruction.
	-- Step 1 stops last frame's instruction being read back as if the player
	-- had pressed it.
	RunService:BindToRenderStep(PRE_STEP_NAME, Enum.RenderPriority.Input.Value - 1, function()
		if self.humanoid.Parent then
			self.humanoid:Move(Vector3.zero, false)
		end
	end)
	RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Input.Value + 1, function(dt)
		self:_update(dt)
	end)

	return self
end

function MovementController:destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._stateChanged:Disconnect()
	self._sprintPressed:Disconnect()
	self._gravityCancel.Enabled = false
	RunService:UnbindFromRenderStep(PRE_STEP_NAME)
	RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
end

function MovementController:getSpeed(): number
	return self.velocity.Magnitude
end

function MovementController:getActualSpeed(): number
	return planar(self.root.AssemblyLinearVelocity).Magnitude
end

function MovementController:setState(name: string)
	-- Never stand up into a ceiling.
	if (name == "Walk" or name == "Sprint") and self.crouched and not self:hasHeadroom() then
		name = "Crouch"
	end
	if name == self.stateName then
		return
	end

	local previous = self.stateName
	local previousState = self.state
	local newState = States[name]
	local now = os.clock()

	-- Crouching, sliding or going prone switches a toggled sprint off.
	if newState.clearsSprintToggle then
		self.sprintOn = false
	end

	-- Charge the stamina cost first, before exit/enter change the speed: the
	-- momentum discount uses the speed the player arrived with.
	if newState.staminaCost then
		self.lastMomentumDiscount = self:momentumDiscount()
		local cost = Config.Stamina.Costs[newState.staminaCost]
		self.stamina:spend(Stamina.discountedCost(cost, self.lastMomentumDiscount))
	end
	-- Wall-run: momentum makes its drain cheaper for the whole run.
	self.drainScale = 1
	if newState.drainUsesMomentum then
		self.lastMomentumDiscount = self:momentumDiscount()
		self.drainScale = 1 - self.lastMomentumDiscount
	end

	if previousState and previousState.exit then
		previousState.exit(self)
	end
	-- The old state's action is over: it may complete a FLOW chain.
	if previousState and previousState.flowAction then
		self:_payFlow(self.flow:finish(previousState.flowAction, self.stateTime, now))
	end

	self.stateName = name
	self.state = newState
	self.stateTime = 0
	self.prone = name == "Prone" or name == "Dive"
	if newState.flowAction then
		self.flow:begin(newState.flowAction, now)
	end

	local controlling = self.state.controlsBody == true
	if controlling then
		self._gravityCancel.Force = Vector3.new(0, self.root.AssemblyMass * Workspace.Gravity, 0)
	end
	self._gravityCancel.Enabled = controlling

	if self.state.enter then
		self.state.enter(self, previous)
	end

	-- Instant FLOW moves reported during this change (wall jump, slide hop)
	-- count after the move they ended: "wall-run, then wall jump".
	for _, action in self._flowQueue do
		self:_payFlow(self.flow:instant(action, now))
	end
	table.clear(self._flowQueue)
end

-- How much of an action's stamina cost momentum would take off right now
-- (see Stamina.qualifyingSpeed).
function MovementController:momentumDiscount(): number
	local speed = Stamina.qualifyingSpeed(self.velocity, self.root.AssemblyLinearVelocity, self.forward)
	return Stamina.momentumDiscount(speed, Config.SprintSpeed, Config.Stamina.MomentumMaxDiscount)
end

-- For moves that are not states of their own. Call just before or while changing state.
function MovementController:flowInstant(action: string)
	table.insert(self._flowQueue, action)
end

function MovementController:_payFlow(reward: number)
	if reward > 0 then
		self.lastFlowReward = reward
		self.stamina:refund(reward)
	end
end

-- Is the player asking to sprint? Any direction counts; not while exhausted.
-- Settings.SprintMode: "Toggle" (default) uses the `sprintOn` switch;
-- "Hold" sprints only while the key is held.
function MovementController:wantsSprint(): boolean
	local asking = if self.settings.get("SprintMode") == "Toggle"
		then self.sprintOn
		else self.input.isDown("Sprint")
	return asking and self.wishDir ~= Vector3.zero and self:canUseStamina()
end

-- The sprint switch turns itself off when the player stops pushing a
-- direction or runs out of stamina. (Crouched states turn it off in setState.)
function MovementController:_updateSprintToggle()
	if self.settings.get("SprintMode") ~= "Toggle" then
		-- Hold mode: keep it off, so switching modes never starts a sprint by itself.
		self.sprintOn = false
		return
	end
	if self.sprintOn and (self.wishDir == Vector3.zero or not self:canUseStamina()) then
		self.sprintOn = false
	end
end

-- Sprint top speed: higher while in FLOW.
function MovementController:sprintSpeed(): number
	return Config.SprintSpeed + (if self.flow:inFlow() then Config.Flow.SprintSpeedAdd else 0)
end

-- Can the player start something that needs stamina? Not while exhausted.
-- With a little stamina left, the action still starts and takes what is left.
function MovementController:canUseStamina(): boolean
	return not self.stamina.exhausted
end

-- Can a dive start right now?
function MovementController:canDive(): boolean
	return self:getSpeed() >= Config.Dive.MinSpeed and self:canUseStamina()
end

-- Share of top speed in the pushed direction: 1 ahead, StrafeSpeedScale
-- sideways, BackSpeedScale back, blended in between.
function MovementController:directionSpeedScale(): number
	if self.wishDir == Vector3.zero then
		return 1
	end
	-- The dot product is 1 when pushing straight ahead, 0 sideways, -1 back.
	local ahead = self.wishDir:Dot(self.forward)
	local strafe = Config.StrafeSpeedScale
	if ahead >= 0 then
		return strafe + (1 - strafe) * ahead
	end
	return strafe + (Config.BackSpeedScale - strafe) * -ahead
end

-- Can a slide start? Fast enough, facing the way you move, not exhausted, cooldown over.
function MovementController:canSlide(): boolean
	local slide = Config.Slide
	local speed = self:getSpeed()
	return speed >= slide.MinSpeed
		-- Straight ahead only: no backwards, sideways or diagonal slides.
		and self.velocity:Dot(self.forward) >= speed * slide.MinForwardDot
		and os.clock() - self.lastSlideEnd >= slide.Cooldown
		and self:canUseStamina()
end

-- What the crouch key is asking for: "tap", "hold" or nil.
-- The state that acts on it must call input.consume("Crouch").
function MovementController:crouchKey(): string?
	if self.input.tapped("Crouch", Config.CrouchHoldTime, Config.Buffer.Slide) then
		return "tap"
	end
	if self.input.heldFor("Crouch") >= Config.CrouchHoldTime then
		return "hold"
	end
	return nil
end

-- Is there room above to stand up?
function MovementController:hasHeadroom(): boolean
	local drop = self._appliedDrop
	if drop <= 0.01 then
		return true
	end
	local crouch = Config.Crouch
	local distance = drop + crouch.StandingHeadHeight - crouch.HeadroomRadius
	local hit = Workspace:Spherecast(
		self.root.Position,
		crouch.HeadroomRadius,
		Vector3.new(0, distance, 0),
		self.rayParams
	)
	return hit == nil
end

-- Height of the bottom of the feet.
function MovementController:getFeetY(): number
	return self.root.Position.Y - self.humanoid.HipHeight - self.root.Size.Y / 2
end

-- Distance from the feet to the root part's centre when standing.
function MovementController:getStandingRootHeight(): number
	return self.humanoid.HipHeight + self._appliedDrop + self.root.Size.Y / 2
end

-- Height of the whole character when standing (feet to top of head).
function MovementController:getStandingHeight(): number
	return self:getStandingRootHeight() + Config.Crouch.StandingHeadHeight
end

-- The surface normal under the character (straight up on flat ground).
function MovementController:getFloorNormal(): Vector3
	local hit = Workspace:Raycast(self.root.Position, Vector3.new(0, -8, 0), self.rayParams)
	if hit then
		return hit.Normal
	end
	return Vector3.yAxis
end

-- Ground movement (Walk, Sprint, Crouch): steer toward the pushed direction
-- at `targetSpeed`.
--   along: speed in the pushed direction (negative = moving the other way);
--   side:  leftover momentum from before a turn, braked by TurnFriction.
-- `along` speeds up with `accel` and slows with `decel` (or `overDecel` above
-- the target). Pushing against your own momentum brakes with ReverseDecel.
-- Exhaustion lowers the target speed here.
function MovementController:accelerate(targetSpeed: number, accel: number, decel: number, dt: number, overDecel: number?)
	targetSpeed *= self:directionSpeedScale() * self.stamina:speedScale()
	local wish = self.wishDir
	if wish == Vector3.zero then
		self.velocity = moveToward(self.velocity, Vector3.zero, decel * dt)
		return
	end

	local along = self.velocity:Dot(wish)
	local side = self.velocity - wish * along
	side = moveToward(side, Vector3.zero, Config.TurnFriction * dt)

	if along < targetSpeed then
		local rate = if along < 0 then Config.ReverseDecel else accel
		along = math.min(along + rate * dt, targetSpeed)
	else
		-- The gentle overDecel only applies straight ahead, so forward speed
		-- cannot be carried into a strafe or backpedal.
		local ahead = math.max(wish:Dot(self.forward), 0)
		local rate = if overDecel then decel + (overDecel - decel) * ahead else decel
		along = math.max(along - rate * dt, targetSpeed)
	end

	self.velocity = wish * along + side
end

-- Turn a flat vector by `share` of this frame's camera turn (camera steering). Speed is unchanged.
function MovementController:cameraSteered(v: Vector3, share: number): Vector3
	return CFrame.Angles(0, self.cameraYawDelta * share, 0) * v
end

function MovementController:airSteer(dt: number)
	-- Camera steering bends the flight, keys or not.
	self.velocity = self:cameraSteered(self.velocity, Config.AirCameraSteer)
	if self.wishDir == Vector3.zero then
		return
	end
	-- Key steering can build speed up to walk speed (slower sideways, back
	-- and when exhausted, so hopping is no way round it).
	local walkSpeed = Config.WalkSpeed * self:directionSpeedScale() * self.stamina:speedScale()
	local carrySpeed = math.max(self.velocity.Magnitude, walkSpeed)
	self.velocity = moveToward(self.velocity, self.wishDir * carrySpeed, Config.AirAccel * dt)
end

-- Hand the body back to the Humanoid, leaving with this 3D velocity.
function MovementController:releaseBody(humanoidState: Enum.HumanoidStateType, velocity: Vector3)
	self.velocity = planar(velocity)
	self.root.AssemblyLinearVelocity = velocity
	self.humanoid:ChangeState(humanoidState)
end

function MovementController:_readInput()
	local camera = Workspace.CurrentCamera
	local _, yaw = camera.CFrame:ToOrientation()
	local facing = CFrame.Angles(0, yaw, 0)
	self.forward = facing.LookVector

	-- How far the view turned since last frame, for camera steering. The
	-- quick turn is not a steer, so it is taken out.
	local delta = if self.lastYaw then yaw - self.lastYaw - self.quickTurnApplied else 0
	self.cameraYawDelta = (delta + math.pi) % (2 * math.pi) - math.pi
	self.lastYaw = yaw
	self.quickTurnApplied = 0

	-- Where Roblox's control script asked to go (already camera-relative).
	local wish = planar(self.humanoid.MoveDirection)
	-- Scripted tests steer with wishOverride (which also counts as facing).
	if self.wishOverride then
		wish = self.wishOverride
		if self.forwardOverride then
			self.forward = self.forwardOverride
		elseif wish.Magnitude > 0.01 then
			self.forward = wish.Unit
		end
	end
	if wish.Magnitude > 0.01 then
		self.wishDir = wish.Unit
	else
		self.wishDir = Vector3.zero
	end
end

function MovementController:_readGround(dt: number)
	local onFloor = self.humanoid.FloorMaterial ~= Enum.Material.Air
	local feetY = self:getFeetY()
	if onFloor then
		if self.airTime > 0 then
			-- Just landed: remember how far we fell.
			self.lastFallHeight = math.max(self.airPeakY - feetY, 0)
			self.landedAt = os.clock()
			self.lastWallNormal = nil
		end
		self.airPeakY = feetY
		self.airTime = 0
		-- The floor is still reported for a frame or two after take-off; ignore
		-- it, or the take-off height would be measured too high.
		if not self._jumped then
			self.lastGroundY = feetY
		end
	else
		if self.airTime == 0 then
			self.leftGroundAt = os.clock() - dt
		end
		self.airTime += dt
		self.airPeakY = math.max(self.airPeakY, feetY)
	end
	-- A jump is over once we are back on a floor (after a short delay, as above).
	if self._jumped and onFloor and os.clock() - self._jumpedAt > 0.2 then
		self._jumped = false
		self._jumpLandedAt = os.clock()
		-- Landed the lowest jump: no jumping for a while, then full height.
		if self._lastJumpHeight <= Config.JumpMinHeight + 0.01 then
			self._jumpFatigueUntil = os.clock() + Config.JumpFatigueCooldown
			self.jumpCount = 0
		end
	end

	-- A short grace period, so stairs and bumps are not "airborne". A jump is airborne at once.
	self.grounded = self.airTime <= Config.CoyoteTime and not self._jumped
end

-- Buffered jump: pressed just before landing, fires on landing.
-- Coyote jump: pressed just after running off an edge, still fires.
-- (A normal jump from the ground is done by Roblox's control script.)
-- During the jump cooldown, or in a blocksJump state (prone: Space means
-- "get up"), the Humanoid's Jumping state is switched off entirely.
function MovementController:_handleJump()
	local now = os.clock()

	-- Jump fatigue: a rest brings back full height. Set the next jump's height
	-- now, because Roblox's control script starts a normal jump.
	if self.jumpCount > 0 and not self._jumped and now - self._jumpLandedAt >= Config.JumpRestTime then
		self.jumpCount = 0
	end
	local height = math.max(Config.JumpHeight - Config.JumpHeightStep * self.jumpCount, Config.JumpMinHeight)
	if not self._jumped and self.humanoid.JumpHeight ~= height then
		self.humanoid.JumpHeight = height
	end

	-- Weighted fall: extra gravity on the way down (not while a state moves the body).
	if self._jumped and not self.state.controlsBody and self.root.AssemblyLinearVelocity.Y < 0 then
		local extra = Workspace.Gravity * (Config.JumpFallGravityScale - 1)
		self.root.AssemblyLinearVelocity -= Vector3.new(0, extra * self._frameDt, 0)
	end

	local cooling = now - self._jumpLandedAt < Config.JumpCooldown or now < self._jumpFatigueUntil
	local off = cooling or self.state.blocksJump == true
	if off ~= self._jumpOff then
		self._jumpOff = off
		self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, not off)
	end

	if self._jumped or off then
		return
	end
	if not self.input.isBuffered("Jump", Config.Buffer.Jump) then
		return
	end

	if self.airTime == 0 then
		-- On the ground with a remembered press: ask for a normal jump.
		self.humanoid.Jump = true
	elseif self.airTime <= Config.CoyoteTime then
		-- Just off an edge: the Humanoid refuses a mid-air jump, so force it.
		self.humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
	-- The press is used up when the Humanoid actually jumps (StateChanged above).
end

-- Quick turn: the camera performs the actual rotation over a few frames.
function MovementController:_handleQuickTurn()
	if self.input.isBuffered("QuickTurn", 0.1) then
		self.input.consume("QuickTurn")
		if self.quickTurnRemaining <= 0 and not self.state.controlsBody then
			self.quickTurnRemaining = math.pi
		end
	end
end

-- Ground roll: the roll key while moving forward on the ground.
function MovementController:_checkGroundRoll(): string?
	if
		self.state.allowsGroundRoll
		and self.grounded
		and self:getSpeed() > 1
		-- Forwards only (user ruling 2026-11-13): strafing and moving
		-- backwards do not roll, the same window a slide uses.
		and self.velocity.Unit:Dot(self.forward) >= Config.Roll.MinForwardDot
		and self:canUseStamina()
		and self.input.isBuffered("Roll", Config.Buffer.Roll)
	then
		return "Roll"
	end
	return nil
end

-- Vault / mantle / ledge grab.
--   Automatic mode: happens when moving into an obstacle.
--   Manual mode:    only while Space is held or was just pressed.
function MovementController:_checkClamber(): string?
	if not self.state.allowsClamber then
		return nil
	end
	local clamber = Config.Clamber
	if os.clock() - self.lastClamberEnd < clamber.Cooldown then
		return nil
	end
	local manual = Settings.get("ClamberMode") == "Manual"
	if manual then
		if not (self.input.isDown("Jump") or self.input.recentlyPressed("Jump", clamber.ManualPressWindow)) then
			return nil
		end
	elseif self.grounded and self:getSpeed() < clamber.MinGroundSpeed then
		return nil
	end

	local obstacle = self:findObstacle()
	-- An exhausted player cannot hold a ledge, so does not grab one.
	if obstacle and obstacle.kind == "LedgeHang" and not self:canUseStamina() then
		obstacle = nil
	end
	if obstacle then
		self.pendingObstacle = obstacle
		-- Manual clambering gives a little stamina back. Not for a ledge grab,
		-- which could be repeated on the spot.
		if manual and obstacle.kind ~= "LedgeHang" then
			self.stamina:refund(Config.Stamina.ManualClamberRefund)
		end
		return obstacle.kind
	end
	return nil
end

-- Ran into something: lower the intended speed to the real one.
function MovementController:_reconcileBlocked()
	local intended = self.velocity.Magnitude
	if intended < 0.01 then
		return
	end
	local actual = self:getActualSpeed()
	if os.clock() < self.blockedGraceUntil then
		return
	end
	if intended - actual > Config.BlockedSpeedTolerance then
		self.velocity = self.velocity.Unit * actual
	end
end

-- Move the body toward the height the state wants: prone, crouched or standing.
function MovementController:_applyBodyHeight(dt: number)
	local crouch = Config.Crouch
	local prone = Config.Prone
	local target = if self.prone then prone.Drop elseif self.crouched then crouch.Drop else 0

	-- Worked out from the current hip height, so a resized avatar still works.
	local humanoid = self.humanoid
	local standing = humanoid.HipHeight + self._appliedDrop
	target = math.clamp(target, 0, math.max(standing - crouch.MinHipHeight, 0))

	-- Prone is deliberately slow to get into and out of.
	local inProneRange = self.prone or self._appliedDrop > crouch.Drop + 0.01
	local step = (if inProneRange then prone.TransitionRate else crouch.TransitionRate) * dt
	local drop = self._appliedDrop
	if drop < target then
		drop = math.min(drop + step, target)
	else
		drop = math.max(drop - step, target)
	end
	humanoid.HipHeight = standing - drop
	self._appliedDrop = drop
end

function MovementController:_applyToHumanoid()
	local humanoid = self.humanoid
	local speed = self.velocity.Magnitude
	if speed > 0.05 then
		humanoid.WalkSpeed = speed
		humanoid:Move(self.velocity / speed, false)
	else
		humanoid.WalkSpeed = Config.WalkSpeed
		humanoid:Move(Vector3.zero, false)
	end
end

function MovementController:_update(dt: number)
	if self._destroyed then
		return
	end
	local humanoid = self.humanoid
	if humanoid.Health <= 0 or not self.root.Parent then
		return
	end

	self:_readInput()
	self:_updateSprintToggle()
	self:_readGround(dt)
	self._frameDt = dt -- for the weighted fall in _handleJump
	self:_handleJump()
	if not self.state.controlsBody then
		self:_reconcileBlocked()
	end
	self:_handleQuickTurn()

	local forced = self:_checkGroundRoll() or self:_checkClamber()
	if forced then
		self:setState(forced)
	end

	self.stateTime += dt
	local nextState = self.state.update(self, dt)
	if nextState then
		self:setState(nextState)
	end

	-- Sprinting, wall-running and hanging drain stamina (nothing comes back meanwhile).
	if self.state.staminaDrain then
		self.stamina:spend(Config.Stamina[self.state.staminaDrain] * self.drainScale * dt)
	end
	self.stamina:step(dt)
	self.flow:update(os.clock())

	self:_applyBodyHeight(dt)
	if not self.state.controlsBody then
		self:_applyToHumanoid()
	end
end

return MovementController
