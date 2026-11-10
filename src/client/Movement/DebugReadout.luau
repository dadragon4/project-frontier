-- A small on-screen readout for tuning: current state and speeds.
-- Development tool only; switched by DevConfig.ShowDebugReadout.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DebugReadout = {}
DebugReadout.__index = DebugReadout

function DebugReadout.new(controller)
	local self = setmetatable({}, DebugReadout)

	local gui = Instance.new("ScreenGui")
	gui.Name = "MovementDebugReadout"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0, 1)
	label.Position = UDim2.new(0, 16, 1, -16)
	label.Size = UDim2.fromOffset(260, 84)
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.4
	label.BorderSizePixel = 0
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Code
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Text = ""
	label.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingTop = UDim.new(0, 6)
	padding.Parent = label

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	self.gui = gui

	self.connection = RunService.RenderStepped:Connect(function()
		label.Text = string.format(
			"state     %s\nintended  %5.1f studs/s\nactual    %5.1f studs/s\ngrounded  %s",
			controller.stateName,
			controller:getSpeed(),
			controller:getActualSpeed(),
			tostring(controller.grounded)
		)
	end)

	return self
end

function DebugReadout:destroy()
	self.connection:Disconnect()
	self.gui:Destroy()
end

return DebugReadout
