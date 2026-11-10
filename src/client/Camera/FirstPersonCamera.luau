-- First-person presentation: locks the view to first person, keeps the
-- player's own body visible, and adds speed-based field of view, a slight
-- tilt while sliding, and the camera turn-over during a roll.
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

local PRE_STEP_NAME = "FrontierFirstPersonCameraPre"
local RENDER_STEP_NAME = "FrontierFirstPersonCamera"

local FirstPersonCamera = {}
FirstPersonCamera.__index = FirstPersonCamera

function FirstPersonCamera.new(controller)
	local self = setmetatable({}, FirstPersonCamera)
	self.controller = controller
	self.character = controller.character
	self.roll = 0
	self.applied = CFrame.identity -- the effect we added last frame

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

function FirstPersonCamera:_update(dt: number)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local cameraConfig = Config.Camera
	local controller = self.controller

	self:_showBody()

	-- Field of view widens with speed.
	local speed = controller:getSpeed()
	local sprintRange = math.max(Config.SprintSpeed - Config.WalkSpeed, 0.01)
	local sprintAmount = math.clamp((speed - Config.WalkSpeed) / sprintRange, 0, 1)
	local targetFov = cameraConfig.BaseFov + cameraConfig.SprintFovAdd * sprintAmount
	if controller.stateName == "Slide" then
		targetFov = cameraConfig.BaseFov + cameraConfig.SlideFovAdd
	end
	-- Frame-rate independent smoothing.
	local fovBlend = 1 - math.exp(-cameraConfig.FovRate * dt)
	camera.FieldOfView += (targetFov - camera.FieldOfView) * fovBlend

	-- Tilt while sliding.
	local targetRoll = if controller.stateName == "Slide" then math.rad(cameraConfig.SlideRoll) else 0
	local rollBlend = 1 - math.exp(-cameraConfig.RollRate * dt)
	self.roll += (targetRoll - self.roll) * rollBlend

	-- Combine this frame's effects: roll turn-over (pitch) and slide tilt.
	local effect = CFrame.Angles(controller.cameraPitch, 0, 0) * CFrame.Angles(0, 0, self.roll)
	camera.CFrame *= effect
	self.applied = effect
end

return FirstPersonCamera
