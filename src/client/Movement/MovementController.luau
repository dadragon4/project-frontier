-- Owns the character's intended horizontal velocity and runs the current
-- movement state.
--
-- How it drives the character: Roblox's Humanoid still does the physical
-- walking (ground contact, stairs, replication to other players). Every
-- frame we decide a velocity using our own acceleration rules, then tell
-- the Humanoid "walk in this direction at this speed".
--
-- A "state" is one mode of movement (Walk, Sprint, Crouch, Slide, Air). The
-- character is always in exactly one. Each state module has:
--     enter(ctx, previousStateName)   optional
--     update(ctx, dt) -> string?      return another state's name to switch
--     exit(ctx)                       optional
-- where ctx is this controller.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("MovementConfig"))

local StatesFolder = script.Parent:WaitForChild("States")
local States = {
	Walk = require(StatesFolder:WaitForChild("Walk")),
	Sprint = require(StatesFolder:WaitForChild("Sprint")),
	Crouch = require(StatesFolder:WaitForChild("Crouch")),
	Slide = require(StatesFolder:WaitForChild("Slide")),
	Air = require(StatesFolder:WaitForChild("Air")),
}

local RENDER_STEP_NAME = "FrontierMovement"
local PRE_STEP_NAME = "FrontierMovementPre"

local MovementController = {}
MovementController.__index = MovementController

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

	self.velocity = Vector3.zero -- intended horizontal velocity
	self.wishDir = Vector3.zero -- direction the player is asking for (unit, or zero)
	self.forward = Vector3.new(0, 0, -1) -- camera facing, flattened
	self.grounded = true
	self.airTime = 0
	self.crouched = false -- states set this; the body lowers to match
	self.lastSlideEnd = -math.huge

	self.stateName = ""
	self.state = nil
	self.stateTime = 0

	self._crouchAlpha = 0
	self._appliedDrop = 0
	self._destroyed = false
	self._jumped = false -- true from take-off until we are back on the ground
	self._jumpedAt = 0

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
	if self.state and self.state.exit then
		self.state.exit(self)
	end

	self.stateName = name
	self.state = States[name]
	self.stateTime = 0

	if self.state.enter then
		self.state.enter(self, previous)
	end
end

-- Is the player asking to sprint, and allowed to?
function MovementController:wantsSprint(): boolean
	return self.input.isDown("Sprint")
		and self.wishDir ~= Vector3.zero
		and self.wishDir:Dot(self.forward) > Config.SprintForwardDot
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
function MovementController:accelerate(targetSpeed: number, accel: number, decel: number, dt: number)
	local target = self.wishDir * targetSpeed
	-- Speeding up uses accel; slowing down (no input, or above the target
	-- speed) uses decel.
	local rate = if target.Magnitude >= self.velocity.Magnitude then accel else decel
	self.velocity = moveToward(self.velocity, target, rate * dt)
end

-- Air movement: keep speed, allow some steering.
function MovementController:airSteer(dt: number)
	if self.wishDir == Vector3.zero then
		return
	end
	local carrySpeed = math.max(self.velocity.Magnitude, Config.WalkSpeed)
	self.velocity = moveToward(self.velocity, self.wishDir * carrySpeed, Config.AirAccel * dt)
end

function MovementController:_readInput()
	local camera = Workspace.CurrentCamera
	local _, yaw = camera.CFrame:ToOrientation()
	local facing = CFrame.Angles(0, yaw, 0)
	self.forward = facing.LookVector

	-- The direction Roblox's control script just asked for, in world space.
	-- It already accounts for the camera and for whichever device is in use.
	local wish = planar(self.humanoid.MoveDirection)
	if wish.Magnitude > 0.01 then
		self.wishDir = wish.Unit
	else
		self.wishDir = Vector3.zero
	end
end

function MovementController:_readGround(dt: number)
	local onFloor = self.humanoid.FloorMaterial ~= Enum.Material.Air
	if onFloor then
		self.airTime = 0
	else
		self.airTime += dt
	end
	-- A jump is over once we are on a floor again. (The short delay is
	-- because the floor is still detected for a frame or two after take-off.)
	if self._jumped and onFloor and os.clock() - self._jumpedAt > 0.2 then
		self._jumped = false
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
function MovementController:_handleJump()
	if self._jumped then
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

-- If we ran into something, our intended speed is higher than the real
-- speed. Drop it, so we do not leave the wall at full speed.
function MovementController:_reconcileBlocked()
	local intended = self.velocity.Magnitude
	if intended < 0.01 then
		return
	end
	local actual = self:getActualSpeed()
	if intended - actual > Config.BlockedSpeedTolerance then
		self.velocity = self.velocity.Unit * actual
	end
end

function MovementController:_applyCrouchHeight(dt: number)
	local crouch = Config.Crouch
	local target = if self.crouched then 1 else 0
	local step = crouch.TransitionRate * dt
	if self._crouchAlpha < target then
		self._crouchAlpha = math.min(self._crouchAlpha + step, target)
	else
		self._crouchAlpha = math.max(self._crouchAlpha - step, target)
	end

	-- Work out the standing hip height from the current one, so this keeps
	-- working if the avatar's size changes after spawning.
	local humanoid = self.humanoid
	local standing = humanoid.HipHeight + self._appliedDrop
	local maxDrop = math.max(math.min(crouch.Drop, standing - crouch.MinHipHeight), 0)
	local drop = maxDrop * self._crouchAlpha
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
	self:_reconcileBlocked()

	self.stateTime += dt
	local nextState = self.state.update(self, dt)
	if nextState then
		self:setState(nextState)
	end

	self:_applyCrouchHeight(dt)
	self:_applyToHumanoid()
end

return MovementController
