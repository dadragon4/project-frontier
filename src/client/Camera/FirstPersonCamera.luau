-- First-person presentation: locks the view to first person, keeps the
-- player's own body visible, and adds the camera movements that make motion
-- feel physical:
--   - field of view widens with speed;
--   - head bob while running (up and down, plus a side-to-side sway),
--     scaled by speed, and a left/right tilt with the steps when sprinting;
--   - the view cannot look further down than Camera.MaxLookDown;
--   - a dip on landing, deeper for bigger falls;
--   - a slight lean when strafing, a tilt while sliding, and a stronger tilt
--     away from the wall while wall-running;
--   - extra pitch requested by movement states (roll turn-over, mantle and
--     vault dips);
--   - the quick turn.
-- "Reduce camera motion" (Settings) turns off the bob, lean, tilts and
-- pitch effects, and shrinks the landing dip and FOV change.
--
-- Roblox's own camera script still does the mouse-look. We run just after
-- it each frame and add our effects on top.
--
-- Important: Roblox's camera script works out each new frame's view from the
-- camera's *current* direction. If our effects were left in place, it would
-- build on them and they would pile up (a roll would leave the view stuck
-- upside down). So just before Roblox's camera script runs, we take our
-- previous frame's effect back off.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("MovementConfig"))
local Settings = require(script.Parent.Parent:WaitForChild("Settings"))

local PRE_STEP_NAME = "FrontierFirstPersonCameraPre"
local RENDER_STEP_NAME = "FrontierFirstPersonCamera"

local BOB_STATES = { Walk = true, Sprint = true, Crouch = true, Prone = true }

local FirstPersonCamera = {}
FirstPersonCamera.__index = FirstPersonCamera

function FirstPersonCamera.new(controller)
	local self = setmetatable({}, FirstPersonCamera)
	self.controller = controller
	self.character = controller.character
	self.applied = CFrame.identity -- the effect we added last frame
	self.tilt = 0
	self.bobPhase = 0
	self.bobWeight = 0 -- 0 = no bob, 1 = full bob at sprint speed
	self.lastLandingSeen = controller.landedAt
	self.dipDepth = 0
	self.dipStartedAt = -math.huge

	local player = Players.LocalPlayer
	-- In locked first person the mouse is always captured, so Roblox's
	-- shift-lock toggle (also on Left Shift) does not interfere with sprint.
	player.CameraMode = Enum.CameraMode.LockFirstPerson

	controller.humanoid.CameraOffset = Config.Camera.Offset

	RunService:BindToRenderStep(PRE_STEP_NAME, Enum.RenderPriority.Camera.Value - 1, function()
		self:_removeEffect()
	end)
	RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value + 1, function(dt)
		self:_update(dt)
	end)

	return self
end

function FirstPersonCamera:destroy()
	RunService:UnbindFromRenderStep(PRE_STEP_NAME)
	RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
	self:_removeEffect()
end

function FirstPersonCamera:_removeEffect()
	local camera = Workspace.CurrentCamera
	if camera and self.applied ~= CFrame.identity then
		camera.CFrame *= self.applied:Inverse()
	end
	self.applied = CFrame.identity
end

-- In first person Roblox hides the whole character every frame. Undo that
-- for the body so the player can look down and see it. The head and
-- anything attached to it (hair, hats) stay hidden so they do not block
-- the view.
function FirstPersonCamera:_showBody()
	for _, child in self.character:GetChildren() do
		if child:IsA("BasePart") and child.Name ~= "Head" then
			child.LocalTransparencyModifier = 0
		end
	end
end

-- Frame-rate independent smoothing factor.
local function blend(rate: number, dt: number): number
	return 1 - math.exp(-rate * dt)
end

function FirstPersonCamera:_update(dt: number)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local cameraConfig = Config.Camera
	local feel = Config.CameraFeel
	local controller = self.controller
	local reduced = Settings.get("ReduceCameraMotion")
	local motion = if reduced then 0 else 1
	local state = controller.stateName
	local speed = controller:getSpeed()

	self:_showBody()

	-- Quick turn. Unlike the effects below, this rotation is meant to stick,
	-- so it is applied straight to the camera and not recorded in
	-- self.applied (Roblox's camera script then carries on from the new
	-- direction).
	if controller.quickTurnRemaining > 0 then
		local step = math.min(controller.quickTurnRemaining, math.pi / Config.QuickTurn.Duration * dt)
		controller.quickTurnRemaining -= step
		controller.quickTurnApplied += step -- so it is not mistaken for camera steering
		local cf = camera.CFrame
		camera.CFrame = CFrame.new(cf.Position) * CFrame.Angles(0, step, 0) * cf.Rotation
	end

	-- Stop the view going further down than MaxLookDown, so it never ends
	-- up inside the player's own body. Like the quick turn, this correction
	-- is applied straight to the camera so that it sticks.
	local lookDown = -math.asin(math.clamp(camera.CFrame.LookVector.Y, -1, 1))
	local excess = lookDown - math.rad(cameraConfig.MaxLookDown)
	if excess > 0 then
		camera.CFrame *= CFrame.Angles(excess, 0, 0)
	end

	-- Field of view widens with speed.
	local fovScale = if reduced then feel.ReducedFovScale else 1
	local sprintRange = math.max(Config.SprintSpeed - Config.WalkSpeed, 0.01)
	local sprintAmount = math.clamp((speed - Config.WalkSpeed) / sprintRange, 0, 1)
	local fovAdd = cameraConfig.SprintFovAdd * sprintAmount
	if state == "Slide" or state == "WallRun" then
		fovAdd = cameraConfig.SlideFovAdd
	end
	-- In FLOW the view widens a little more.
	if controller.flow:inFlow() then
		fovAdd += Config.Flow.FovAdd
	end
	local targetFov = cameraConfig.BaseFov + fovAdd * fovScale
	camera.FieldOfView += (targetFov - camera.FieldOfView) * blend(cameraConfig.FovRate, dt)

	-- Tilt: slide tilt, strafe lean, wall-run tilt.
	local right = camera.CFrame.RightVector
	local flatRight = Vector3.new(right.X, 0, right.Z)
	local targetTilt = 0
	if state == "Slide" then
		targetTilt += math.rad(cameraConfig.SlideRoll)
	end
	if BOB_STATES[state] and controller.grounded then
		local sideways = controller.velocity:Dot(flatRight) / Config.SprintSpeed
		targetTilt -= math.clamp(sideways, -1, 1) * math.rad(feel.StrafeLean)
	end
	if controller.wallNormal then
		-- Lean the head away from the wall.
		local wallOnLeft = controller.wallNormal:Dot(flatRight) > 0
		targetTilt += (if wallOnLeft then -1 else 1) * math.rad(feel.WallRunTilt)
	end
	self.tilt += (targetTilt * motion - self.tilt) * blend(cameraConfig.RollRate, dt)

	-- Head bob, driven by distance travelled so it matches footsteps.
	-- The up-and-down bob repeats every step; the sideways sway is half as
	-- fast, so the head moves over to the left foot, then the right.
	local targetBob = 0
	if BOB_STATES[state] and controller.grounded and speed > 1 then
		self.bobPhase += speed * dt * feel.BobFrequency
		targetBob = math.clamp(speed / Config.SprintSpeed, 0, 1)
	end
	self.bobWeight += (targetBob * motion - self.bobWeight) * blend(10, dt)
	-- Strafing rocks the head sideways more and bounces it less.
	-- "sideness" is 0 moving straight ahead or back, 1 moving flat sideways.
	local sideness = 0
	if speed > 1 and flatRight.Magnitude > 0.01 then
		sideness = math.abs((controller.velocity / speed):Dot(flatRight.Unit))
	end
	local bobY = math.sin(self.bobPhase * 2) * self.bobWeight * feel.BobAmount * (1 - feel.StrafeBobTrade * sideness)
	-- Walking has its own sway amount, reached in full at walk speed
	-- (bobWeight is speed / sprint speed, so it is scaled back up here).
	local sideAmount = feel.SideBobAmount
	if state == "Walk" then
		sideAmount = feel.WalkSideBobAmount * Config.SprintSpeed / Config.WalkSpeed
	end
	local bobX = math.sin(self.bobPhase) * self.bobWeight * (sideAmount + feel.StrafeBobAdd * sideness)

	-- Sprint sway: the view tilts left and right with the steps while
	-- sprinting forward or on a forward diagonal (none flat sideways or
	-- backwards). It follows the same rhythm as the sideways bob.
	local sway = 0
	if state == "Sprint" and speed > 1 then
		local forwardness = math.max(controller.velocity:Dot(controller.forward) / speed, 0)
		sway = math.sin(self.bobPhase) * self.bobWeight * math.rad(feel.SprintSwayTilt) * forwardness
	end

	-- Landing dip (not after a roll, which has its own camera movement).
	if controller.landedAt ~= self.lastLandingSeen then
		self.lastLandingSeen = controller.landedAt
		local fall = controller.lastFallHeight
		if fall > feel.DipMinFall and state ~= "Roll" then
			local scale = if reduced then feel.ReducedDipScale else 1
			self.dipDepth = math.min((fall - feel.DipMinFall) * feel.DipPerStud, feel.DipMax) * scale
			self.dipStartedAt = os.clock()
		end
	end
	local dipProgress = (os.clock() - self.dipStartedAt) / feel.DipDuration
	local dip = if dipProgress < 1 then self.dipDepth * math.sin(math.pi * dipProgress) else 0

	-- Combine this frame's effects.
	local effect = CFrame.new(bobX, bobY - dip, 0)
		* CFrame.Angles(controller.cameraPitch * motion, 0, 0)
		* CFrame.Angles(0, 0, self.tilt + sway)
	camera.CFrame *= effect
	self.applied = effect
end

return FirstPersonCamera
