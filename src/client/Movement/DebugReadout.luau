-- A small on-screen readout for tuning: current state, speeds, stamina and
-- FLOW. This is a developer tool, not the player's stamina display: how (or
-- whether) players see stamina is a separate design decision.
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
	label.Size = UDim2.fromOffset(330, 184)
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
		local stamina = controller.stamina
		local flow = controller.flow

		-- When stamina will next come back.
		local regen
		if controller.state.staminaDrain then
			regen = "none (draining)"
		elseif stamina.regenDelayLeft > 0 then
			regen = string.format("in %.1f s", stamina.regenDelayLeft)
		elseif stamina.current >= stamina.max then
			regen = "full"
		else
			regen = "regenerating"
		end

		-- Time left to carry the chain on; "..." while an action is under way.
		local timeLeft = flow:timeLeft(os.clock())
		local window = if flow.inProgress then "..." elseif timeLeft then string.format("%.1f s", timeLeft) else "-"

		label.Text = string.format(
			"state     %s\nintended  %5.1f studs/s\nactual    %5.1f studs/s\ngrounded  %s\n"
				.. "stamina   %5.1f / %d%s\nregen     %s\n"
				.. "momentum  %2.0f%% off an action started now\n"
				.. "last paid %2.0f%% off (slide, roll, dive or wall-run)\n"
				.. "chain     %d actions, window %s, last +%d\n"
				.. "FLOW      %3.0f%%%s",
			controller.stateName,
			controller:getSpeed(),
			controller:getActualSpeed(),
			tostring(controller.grounded),
			stamina.current,
			stamina.max,
			if stamina.exhausted then "  EXHAUSTED" else "",
			regen,
			controller:momentumDiscount() * 100,
			controller.lastMomentumDiscount * 100,
			flow.count,
			window,
			controller.lastFlowReward,
			flow:meter() * 100,
			if flow:inFlow() then "  IN FLOW" else ""
		)
	end)

	return self
end

function DebugReadout:destroy()
	self.connection:Disconnect()
	self.gui:Destroy()
end

return DebugReadout
