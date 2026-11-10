-- Client entry point. Starts input once, then builds the movement
-- controller, camera and debug readout each time the character spawns.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DevConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("DevConfig"))

local Input = require(script.Parent:WaitForChild("Input"))
local MovementController = require(script.Parent:WaitForChild("Movement"):WaitForChild("MovementController"))
local DebugReadout = require(script.Parent:WaitForChild("Movement"):WaitForChild("DebugReadout"))
local FirstPersonCamera = require(script.Parent:WaitForChild("Camera"):WaitForChild("FirstPersonCamera"))

local player = Players.LocalPlayer

Input.start()

local active: { any } = {}

local function teardown()
	for _, object in active do
		object:destroy()
	end
	table.clear(active)
end

local function onCharacterAdded(character: Model)
	teardown()

	local controller = MovementController.new(character, Input)
	table.insert(active, controller)
	table.insert(active, FirstPersonCamera.new(controller))
	if DevConfig.ShowDebugReadout then
		table.insert(active, DebugReadout.new(controller))
	end

	controller.humanoid.Died:Once(teardown)
end

player.CharacterAdded:Connect(onCharacterAdded)
player.CharacterRemoving:Connect(teardown)

if player.Character then
	onCharacterAdded(player.Character)
end
