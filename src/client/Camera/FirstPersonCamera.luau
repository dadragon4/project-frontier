-- First-person view: locks the camera to first person, keeps your body
-- visible, and adds the movements that make motion feel physical: field of
-- view that widens with speed, head bob and sway, a sprint tilt, a landing
-- dip, leans and tilts (strafe, slide, wall-run), pitch from moves (roll,
-- mantle, vault), the quick turn, and a limit on looking down.
-- "Reduce camera motion" turns most of these off.
--
-- Roblox's camera script still does the mouse-look; we add our effects just
-- after it. It builds each frame from the camera's current direction, so we
-- take last frame's effects off just before it runs, or they would pile up.

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
	-- Locked first person captures the mouse, so Roblox's shift-lock (also Left Shift) cannot clash with sprint.
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

-- Roblox hides the whole character in first person. Show the body again so
-- you can look down and see it; keep the head (and hats, hair) hidden.
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

	-- Quick turn: applied straight to the camera, because it is meant to stick.
	if controller.quickTurnRemaining > 0 then
		local step = math.min(controller.quickTurnRemaining, math.pi / Config.QuickTurn.Duration * dt)
		controller.quickTurnRemaining -= step
		controller.quickTurnApplied += step -- so it is not mistaken for camera steering
		local cf = camera.CFrame
		camera.CFrame = CFrame.new(cf.Position) * CFrame.Angles(0, step, 0) * cf.Rotation
	end

	-- Look-down limit, so the view never goes inside the body. Also meant to stick.
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

	-- Head bob follows distance travelled, so it matches the steps: up and down
	-- every step, side to side every two.
	local targetBob = 0
	if BOB_STATES[state] and controller.grounded and speed > 1 then
		self.bobPhase += speed * dt * feel.BobFrequency
		targetBob = math.clamp(speed / Config.SprintSpeed, 0, 1)
	end
	self.bobWeight += (targetBob * motion - self.bobWeight) * blend(10, dt)
	-- Strafing sways more and bounces less. sideness: 0 forward or back, 1 flat sideways.
	local sideness = 0
	if speed > 1 and flatRight.Magnitude > 0.01 then
		sideness = math.abs((controller.velocity / speed):Dot(flatRight.Unit))
	end
	local bobY = math.sin(self.bobPhase * 2) * self.bobWeight * feel.BobAmount * (1 - feel.StrafeBobTrade * sideness)
	-- Walking has its own sway, reached in full at walk speed.
	local sideAmount = feel.SideBobAmount
	if state == "Walk" then
		sideAmount = feel.WalkSideBobAmount * Config.SprintSpeed / Config.WalkSpeed
	end
	local bobX = math.sin(self.bobPhase) * self.bobWeight * (sideAmount + feel.StrafeBobAdd * sideness)

	-- Sprint tilt: the view rocks left and right with the steps when sprinting forward.
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
