-- First-person presentation: locks the view to first person, keeps the
-- player's own body visible, and adds speed-based field of view and a
-- slight tilt while sliding.
--
-- Roblox's own camera script still does the mouse-look. We run just after
-- it each frame and adjust the result.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("MovementConfig"))

local RENDER_STEP_NAME = "FrontierFirstPersonCamera"

local FirstPersonCamera = {}
FirstPersonCamera.__index = FirstPersonCamera

function FirstPersonCamera.new(controller)
	local self = setmetatable({}, FirstPersonCamera)
	self.controller = controller
	self.character = controller.character
	self.roll = 0

	local player = Players.LocalPlayer
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	-- Left Shift is our sprint key, so turn off Roblox's shift-lock toggle.
	player.DevEnableMouseLock = false

	controller.humanoid.CameraOffset = Config.Camera.Offset

	RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value + 1, function(dt)
		self:_update(dt)
	end)

	return self
end

function FirstPersonCamera:destroy()
	RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
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

	-- Tilt while sliding. The camera script rebuilds the camera's position
	-- every frame, so this does not accumulate.
	local targetRoll = if controller.stateName == "Slide" then math.rad(cameraConfig.SlideRoll) else 0
	local rollBlend = 1 - math.exp(-cameraConfig.RollRate * dt)
	self.roll += (targetRoll - self.roll) * rollBlend
	if math.abs(self.roll) > 1e-4 then
		camera.CFrame *= CFrame.Angles(0, 0, self.roll)
	end
end

return FirstPersonCamera
