-- A small settings window, opened and closed with P.
--
-- In locked first person the mouse is captured in the middle of the screen.
-- A button with Modal = true releases it while the button is visible, so
-- the player can click the options.
--
-- This is a plain development-stage panel. Its final look belongs to the UI
-- direction work (retro-futuristic OS + tactical display).

local Players = game:GetService("Players")

local Settings = require(script.Parent.Parent:WaitForChild("Settings"))

local SettingsPanel = {}

local TEXT = Color3.fromRGB(220, 235, 245)
local ACCENT = Color3.fromRGB(120, 200, 255)
local PANEL = Color3.fromRGB(16, 20, 26)
local BUTTON = Color3.fromRGB(32, 40, 52)

local function makeLabel(parent: Instance, text: string, position: UDim2, size: UDim2, alignment: Enum.TextXAlignment)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = Enum.Font.Code
	label.TextSize = 16
	label.TextColor3 = TEXT
	label.TextXAlignment = alignment
	label.Text = text
	label.Parent = parent
	return label
end

local function makeButton(parent: Instance, position: UDim2, size: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.AutoButtonColor = true
	button.BackgroundColor3 = BUTTON
	button.BorderSizePixel = 0
	button.Position = position
	button.Size = size
	button.Font = Enum.Font.Code
	button.TextSize = 16
	button.TextColor3 = ACCENT
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = button
	return button
end

function SettingsPanel.start(input)
	local gui = Instance.new("ScreenGui")
	gui.Name = "SettingsPanel"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10
	gui.Enabled = false

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(360, 190)
	frame.BackgroundColor3 = PANEL
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = ACCENT
	stroke.Transparency = 0.4
	stroke.Parent = frame

	local title = makeLabel(frame, "SETTINGS", UDim2.fromOffset(16, 10), UDim2.new(1, -32, 0, 24), Enum.TextXAlignment.Left)
	title.TextColor3 = ACCENT
	makeLabel(frame, "[P] close", UDim2.fromOffset(16, 10), UDim2.new(1, -32, 0, 24), Enum.TextXAlignment.Right)

	makeLabel(frame, "Camera motion", UDim2.fromOffset(16, 52), UDim2.fromOffset(160, 32), Enum.TextXAlignment.Left)
	local motionButton = makeButton(frame, UDim2.fromOffset(200, 52), UDim2.fromOffset(144, 32))

	makeLabel(frame, "Clambering", UDim2.fromOffset(16, 96), UDim2.fromOffset(160, 32), Enum.TextXAlignment.Left)
	local clamberButton = makeButton(frame, UDim2.fromOffset(200, 96), UDim2.fromOffset(144, 32))

	local closeButton = makeButton(frame, UDim2.new(0.5, -60, 1, -46), UDim2.fromOffset(120, 32))
	closeButton.Text = "Close"
	-- Releases the mouse while the panel is showing.
	closeButton.Modal = true

	local function refresh()
		motionButton.Text = if Settings.get("ReduceCameraMotion") then "Reduced" else "Full"
		clamberButton.Text = if Settings.get("ClamberMode") == "Manual" then "Manual (Space)" else "Automatic"
	end

	motionButton.Activated:Connect(function()
		Settings.set("ReduceCameraMotion", not Settings.get("ReduceCameraMotion"))
	end)
	clamberButton.Activated:Connect(function()
		Settings.set("ClamberMode", if Settings.get("ClamberMode") == "Manual" then "Auto" else "Manual")
	end)
	closeButton.Activated:Connect(function()
		gui.Enabled = false
	end)
	input.Pressed:Connect(function(action)
		if action == "Settings" then
			gui.Enabled = not gui.Enabled
		end
	end)
	Settings.Changed:Connect(refresh)
	refresh()

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

return SettingsPanel
