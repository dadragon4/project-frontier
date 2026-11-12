-- Owns the character's intended horizontal velocity and runs the current
-- movement state.
--
-- How it drives the character: Roblox's Humanoid still does the physical
-- walking (ground contact, stairs, replication to other players). Every
-- frame we decide a velocity using our own acceleration rules, then tell
-- the Humanoid "walk in this direction at this speed". Some states (mantle,
-- vault, ledge hang, wall-run) instead put the Humanoid in its "Physics"
-- state and move the body directly.
--
-- A "state" is one mode of movement. The character is always in exactly
-- one. Each state module has:
--     enter(ctx, previousStateName)   optional
--     update(ctx, dt) -> string?      return another state's name to switch
--     exit(ctx)                       optional
--     controlsBody = true             optional: the state moves the body
--                                     itself, so the controller must not
--                                     send walk instructions
--     blocksJump = true               optional: no buffered/coyote jumps
--     allowsGroundRoll = true         optional: the roll key rolls from here
--     allowsClamber = true            optional: vault / mantle / ledge grab
--                                     can start from this state
--     staminaCost = "Slide"           optional: entering the state costs
--                                     stamina (a key of Config.Stamina.Costs)
--     staminaDrain = "SprintDrain"    optional: being in the state drains
--                                     stamina, at that rate per second (a
--                                     key of Config.Stamina)
--     flowAction = "Slide"            optional: the state counts toward a
--                                     FLOW chain under this name
-- where ctx is this controller.
--
-- Stamina and FLOW: the rules live in Shared/Stamina and Shared/FlowChain.
-- States only carry the three labels above; all charging happens here, in
-- setState, the one place every change of state goes through. So an action
-- is charged exactly once, and a change that never happens costs nothing.

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

-- Obstacle and wall detection (findObstacle, findWallRunWall, roomToStand,
-- isBlocked, ledgeAt) lives in Detection.luau and is used as methods here.
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
	self.airPeakY = 0 -- highest the feet have been during the current time in the air
	self.lastFallHeight = 0 -- how far the feet dropped (peak to landing) on the most recent landing

	-- Simulated on this client for now, like the movement itself. The
	-- server will run the same two modules to check it (M1.4).
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

	-- Fires for every jump, whether Roblox's control script or our buffered
	-- jump started it.
	self._stateChanged = self.humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping then
			self._jumped = true
			self._jumpedAt = os.clock()
			self.input.consume("Jump")
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

	-- While a state moves the body directly (controlsBody), gravity would
	-- still pull it down between our frames, so a wall-run sinks and a hang
	-- sags, worse at low frame rates. This upward force, equal to the
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

	-- Three things happen in order every frame:
	--   1. (just before Roblox's control script) we clear the Humanoid's move
	--      direction;
	--   2. Roblox's control script, at Input priority, reads the keyboard /
	--      thumbstick / touch stick and tells the Humanoid which way the
	--      player wants to go;
	--   3. (just after) we read that wish from Humanoid.MoveDirection, apply
	--      our own acceleration rules, and give the Humanoid our instruction,
	--      which is the one it ends up following.
	-- Step 1 matters because our own instruction from the previous frame is
	-- still stored in MoveDirection. Without clearing it, a frame where the
	-- control script stays silent would read our old instruction back as if
	-- the player had asked for it.
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

	-- Charge the new state's stamina cost first: the old state's exit and
	-- the new state's enter both change the velocity (a slide adds its
	-- boost, a vault zeroes it), and the momentum discount must be measured
	-- on the speed the player arrived with.
	if newState.staminaCost then
		self.lastMomentumDiscount = self:momentumDiscount()
		local cost = Config.Stamina.Costs[newState.staminaCost]
		self.stamina:spend(Stamina.discountedCost(cost, self.lastMomentumDiscount))
	end
	-- A state whose drain is cheaper with momentum (wall-run): fix the
	-- discount now, for the whole time the state lasts.
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

	-- Instant FLOW actions reported during this change (a wall jump, a
	-- jump out of a slide) are counted last, so the chain sees them after
	-- the action they ended: "wall-run, then wall jump", not the reverse.
	for _, action in self._flowQueue do
		self:_payFlow(self.flow:instant(action, now))
	end
	table.clear(self._flowQueue)
end

-- The share of an action's stamina cost that the player's momentum would
-- take off if the action started right now. See Stamina.qualifyingSpeed
-- for what counts as momentum.
function MovementController:momentumDiscount(): number
	local speed = Stamina.qualifyingSpeed(self.velocity, self.root.AssemblyLinearVelocity, self.forward)
	return Stamina.momentumDiscount(speed, Config.SprintSpeed, Config.Stamina.MomentumMaxDiscount)
end

-- For states to report a FLOW action that is not a state of its own.
-- Call it just before, or while, changing state.
function MovementController:flowInstant(action: string)
	table.insert(self._flowQueue, action)
end

function MovementController:_payFlow(reward: number)
	if reward > 0 then
		self.lastFlowReward = reward
		self.stamina:refund(reward)
	end
end

-- Is the player asking to sprint? Sprint works in any direction; sideways
-- and backwards are just slower (see directionSpeedScale).
-- Not while exhausted: see canUseStamina.
function MovementController:wantsSprint(): boolean
	return self.input.isDown("Sprint") and self.wishDir ~= Vector3.zero and self:canUseStamina()
end

-- Sprint top speed: higher while in FLOW.
function MovementController:sprintSpeed(): number
	return Config.SprintSpeed + (if self.flow:inFlow() then Config.Flow.SprintSpeedAdd else 0)
end

-- May the player start something that needs stamina? Not while exhausted
-- (user ruling 2026-11-11): from running out until stamina is back up to
-- Stamina.RecoverAt, there is no sprint, slide, dive, roll, wall-run or
-- ledge hang. Walking, crouching, crawling, jumping, vaulting and mantling
-- need no stamina and still work.
-- With some stamina left, but less than an action costs, the action still
-- starts: it takes what is left, and that is what exhausts the player.
function MovementController:canUseStamina(): boolean
	return not self.stamina.exhausted
end

-- Can a dive start right now?
function MovementController:canDive(): boolean
	return self:getSpeed() >= Config.Dive.MinSpeed and self:canUseStamina()
end

-- How much of a state's top speed is available in the direction the player
-- is pushing: 1 straight ahead, StrafeSpeedScale flat sideways,
-- BackSpeedScale straight back, blended smoothly in between.
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

-- Can a slide start right now? Fast enough, not exhausted, and not straight
-- after the previous slide (Slide.Cooldown stops sprint and slide being
-- spammed).
function MovementController:canSlide(): boolean
	local slide = Config.Slide
	return self:getSpeed() >= slide.MinSpeed
		and os.clock() - self.lastSlideEnd >= slide.Cooldown
		and self:canUseStamina()
end

-- What the crouch key is asking for right now:
--   "tap"   it was pressed and let go quickly (crouch / slide / stand up)
--   "hold"  it has been kept down long enough (prone / dive)
--   nil     neither
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

-- Ground movement shared by Walk, Sprint and Crouch: steer the velocity
-- toward the wished direction at `targetSpeed`.
--
-- The velocity is split into two parts:
--   along: how fast we are already moving in the direction the player is
--          pushing (negative if we are moving the opposite way);
--   side:  everything else (left-over momentum from before a turn).
-- The side part is braked hard by TurnFriction, so turning does not slide
-- like ice. The along part speeds up with `accel` or slows with `decel`
-- (or `overDecel`, if given, when above the target speed), and if it is
-- negative (the player is pushing against their own momentum: a reversal,
-- or "counter-strafe") it is braked by ReverseDecel first.
--
-- Exhaustion (no stamina left) lowers the target speed here, so it slows
-- exactly the states that use this function, and nothing else.
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
		-- The gentle `overDecel` is for extra speed carried straight ahead
		-- (slide-hop, vault). The further the push is from straight ahead,
		-- the more the ordinary `decel` takes over, so forward sprint speed
		-- cannot be carried into a strafe or a backpedal.
		local ahead = math.max(wish:Dot(self.forward), 0)
		local rate = if overDecel then decel + (overDecel - decel) * ahead else decel
		along = math.max(along - rate * dt, targetSpeed)
	end

	self.velocity = wish * along + side
end

-- Air movement: keep speed, allow some steering.
function MovementController:airSteer(dt: number)
	if self.wishDir == Vector3.zero then
		return
	end
	-- Below walk speed, steering may build up to walk speed in that
	-- direction (slower sideways and backwards, as on the ground; and
	-- slower when exhausted, or hopping would be a way round exhaustion).
	local walkSpeed = Config.WalkSpeed * self:directionSpeedScale() * self.stamina:speedScale()
	local carrySpeed = math.max(self.velocity.Magnitude, walkSpeed)
	self.velocity = moveToward(self.velocity, self.wishDir * carrySpeed, Config.AirAccel * dt)
end

-- Hand the body back to the Humanoid after a state that moved it directly.
-- `velocity` is the full 3D velocity to leave with.
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

	-- The direction Roblox's control script just asked for, in world space.
	-- It already accounts for the camera and for whichever device is in use.
	local wish = planar(self.humanoid.MoveDirection)
	-- Scripted tests (Dev/MovementTests) steer the character by setting
	-- wishOverride; the direction pushed then also counts as "forward".
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
		-- Roblox keeps reporting the floor for a frame or two after a jump
		-- starts, while the body is already rising. Ignore those frames, or
		-- the "floor we jumped from" would be measured too high.
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
	-- A jump is over once we are on a floor again. (The short delay is
	-- because the floor is still detected for a frame or two after take-off.)
	if self._jumped and onFloor and os.clock() - self._jumpedAt > 0.2 then
		self._jumped = false
		self._jumpLandedAt = os.clock()
	end

	-- A short grace period stops stairs and small bumps counting as
	-- "airborne". A deliberate jump counts as airborne straight away.
	self.grounded = self.airTime <= Config.CoyoteTime and not self._jumped
end

-- Buffered jump and coyote jump.
--   Buffered: jump pressed slightly before landing fires on landing.
--   Coyote:   jump pressed slightly after running off an edge still fires.
-- An ordinary jump (pressed while standing on the ground) is done by
-- Roblox's control script and never reaches the code below.
--
-- Jump cooldown: for JumpCooldown seconds after landing from a jump, the
-- Humanoid's Jumping state is switched off. That blocks Roblox's own jump
-- as well as ours. A press during the cooldown stays remembered for the
-- usual buffer time, so a press just before the cooldown ends still jumps.
-- The same switch is used while a state has blocksJump (for example prone,
-- where Space means "get up", not "jump").
function MovementController:_handleJump()
	local cooling = os.clock() - self._jumpLandedAt < Config.JumpCooldown
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
		-- Just left an edge: the Humanoid would refuse a normal jump in
		-- mid-air, so force the jump state.
		self.humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
	-- The press is consumed when the Humanoid actually enters its Jumping
	-- state (see StateChanged above). If it never does, the press expires.
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

-- Ground roll: the roll key pressed while moving on the ground. Standing
-- still does not roll.
function MovementController:_checkGroundRoll(): string?
	if
		self.state.allowsGroundRoll
		and self.grounded
		and self:getSpeed() > 1
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
	-- An exhausted player cannot hold a ledge (see LedgeHang), so does not
	-- grab one. Vaults and mantles are unaffected.
	if obstacle and obstacle.kind == "LedgeHang" and not self:canUseStamina() then
		obstacle = nil
	end
	if obstacle then
		self.pendingObstacle = obstacle
		-- Manual clambering gives a little stamina back (design decision
		-- 2026-11-10). This point is only reached when the vault or mantle
		-- is about to start, once per clamber. A ledge grab gives nothing:
		-- grabbing, dropping and grabbing again could repeat it on the spot.
		if manual and obstacle.kind ~= "LedgeHang" then
			self.stamina:refund(Config.Stamina.ManualClamberRefund)
		end
		return obstacle.kind
	end
	return nil
end

-- If we ran into something, our intended speed is higher than the real
-- speed. Drop it, so we do not leave the wall at full speed.
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

-- Lower or raise the body toward the height the current state asks for:
-- prone, crouched or standing. "Drop" is how many studs lower than standing.
function MovementController:_applyBodyHeight(dt: number)
	local crouch = Config.Crouch
	local prone = Config.Prone
	local target = if self.prone then prone.Drop elseif self.crouched then crouch.Drop else 0

	-- Work out the standing hip height from the current one, so this keeps
	-- working if the avatar's size changes after spawning.
	local humanoid = self.humanoid
	local standing = humanoid.HipHeight + self._appliedDrop
	target = math.clamp(target, 0, math.max(standing - crouch.MinHipHeight, 0))

	-- Going into prone, and coming back up out of it, is deliberately slow.
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
	self:_readGround(dt)
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

	-- Sprinting and ledge hanging drain stamina. Because every spend
	-- restarts the wait before stamina comes back, nothing comes back
	-- while they last.
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
