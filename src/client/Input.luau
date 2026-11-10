-- Turns physical inputs into named actions ("Sprint", "Crouch", "Jump").
--
-- Movement code only ever asks about actions, never about keys. Adding
-- gamepad or touch later means adding bindings here (or calling
-- Input.setVirtual from an on-screen button) with no change to movement.
--
-- The walk direction itself is not handled here: it comes from Roblox's own
-- control script, which already understands keyboard, thumbstick and touch.
--
-- Input buffering: every press is time-stamped. Movement code can ask "was
-- this pressed within the last X seconds?" instead of "is it pressed on
-- exactly this frame?". A press that comes slightly too early (for example
-- jump just before landing) is then still honoured on the first frame it
-- becomes possible. Once a press has been acted on it is "consumed" so it
-- cannot trigger twice.

local UserInputService = game:GetService("UserInputService")

local BINDINGS: { [string]: { Enum.KeyCode } } = {
	Sprint = { Enum.KeyCode.LeftShift },
	-- LeftSuper / LeftMeta is the Command key on a Mac (and the Windows key on
	-- a PC, where Windows itself takes the key press). Scripts cannot ask
	-- which operating system the player is on, so all of these are bound
	-- everywhere: Mac players use Command or C, PC players use Ctrl or C.
	Crouch = {
		Enum.KeyCode.C,
		Enum.KeyCode.LeftControl,
		Enum.KeyCode.LeftSuper,
		Enum.KeyCode.LeftMeta,
	},
	-- Roblox's control script still performs the ordinary jump. We listen to
	-- the same key only so that early presses can be buffered.
	Jump = { Enum.KeyCode.Space },
}

local Input = {}

local keyToAction: { [Enum.KeyCode]: string } = {}
local heldKeys: { [Enum.KeyCode]: boolean } = {}
local virtualHeld: { [string]: boolean } = {}
local heldCount: { [string]: number } = {}
local lastPressTime: { [string]: number } = {}
local started = false

local function press(action: string)
	local count = (heldCount[action] or 0) + 1
	heldCount[action] = count
	if count == 1 then
		lastPressTime[action] = os.clock()
	end
end

local function release(action: string)
	heldCount[action] = math.max((heldCount[action] or 0) - 1, 0)
end

local function releaseEverything()
	table.clear(heldKeys)
	table.clear(virtualHeld)
	table.clear(heldCount)
	table.clear(lastPressTime)
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

	UserInputService.InputBegan:Connect(function(input)
		-- Ignore keys while the player is typing (chat, text fields).
		if UserInputService:GetFocusedTextBox() then
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

-- Was the action pressed within the last `window` seconds, and not yet
-- consumed?
function Input.isBuffered(action: string, window: number): boolean
	local pressedAt = lastPressTime[action]
	return pressedAt ~= nil and os.clock() - pressedAt <= window
end

-- Was the action pressed at or after time `since` (an os.clock() value),
-- and not yet consumed?
function Input.pressedSince(action: string, since: number): boolean
	local pressedAt = lastPressTime[action]
	return pressedAt ~= nil and pressedAt >= since
end

-- Mark the most recent press of this action as used.
function Input.consume(action: string)
	lastPressTime[action] = nil
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

return Input
