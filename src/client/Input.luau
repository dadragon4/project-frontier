-- Turns physical inputs into named actions ("Sprint", "Crouch").
--
-- Movement code only ever asks about actions, never about keys. Adding
-- gamepad or touch later means adding bindings here (or calling
-- Input.setVirtual from an on-screen button) with no change to movement.
--
-- The walk direction itself is not handled here: it comes from Roblox's own
-- control script, which already understands keyboard, thumbstick and touch.

local UserInputService = game:GetService("UserInputService")

local BINDINGS: { [string]: { Enum.KeyCode } } = {
	Sprint = { Enum.KeyCode.LeftShift },
	Crouch = { Enum.KeyCode.LeftControl, Enum.KeyCode.C },
}

local Input = {}

local keyToAction: { [Enum.KeyCode]: string } = {}
local heldKeys: { [Enum.KeyCode]: boolean } = {}
local virtualHeld: { [string]: boolean } = {}
local heldCount: { [string]: number } = {}
local pressedThisFrame: { [string]: boolean } = {}
local started = false

local function press(action: string)
	local count = (heldCount[action] or 0) + 1
	heldCount[action] = count
	if count == 1 then
		pressedThisFrame[action] = true
	end
end

local function release(action: string)
	heldCount[action] = math.max((heldCount[action] or 0) - 1, 0)
end

local function releaseEverything()
	table.clear(heldKeys)
	table.clear(virtualHeld)
	table.clear(heldCount)
	table.clear(pressedThisFrame)
end

function Input.start()
	if started then
		return
	end
	started = true

	for action, keys in BINDINGS do
		for _, key in keys do
			keyToAction[key] = action
		end
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- gameProcessed is true when Roblox already used the input, for
		-- example while the player is typing in chat.
		if gameProcessed then
			return
		end
		local action = keyToAction[input.KeyCode]
		if action and not heldKeys[input.KeyCode] then
			heldKeys[input.KeyCode] = true
			press(action)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if heldKeys[input.KeyCode] then
			heldKeys[input.KeyCode] = nil
			release(keyToAction[input.KeyCode])
		end
	end)

	-- If the window loses focus we never see the key-up, so let go of everything.
	UserInputService.WindowFocusReleased:Connect(releaseEverything)
end

-- Is the action currently held?
function Input.isDown(action: string): boolean
	return (heldCount[action] or 0) > 0
end

-- Did the action go from up to down during this frame?
function Input.wasPressed(action: string): boolean
	return pressedThisFrame[action] == true
end

-- For on-screen (touch) buttons: hold or release an action from code.
function Input.setVirtual(action: string, down: boolean)
	if down and not virtualHeld[action] then
		virtualHeld[action] = true
		press(action)
	elseif not down and virtualHeld[action] then
		virtualHeld[action] = nil
		release(action)
	end
end

-- Called once at the end of every movement update.
function Input.endFrame()
	table.clear(pressedThisFrame)
end

return Input
