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
	-- the same key so that early presses can be buffered, and because Space
	-- is also the manual vault / mantle / ledge-grab key and the wall-jump key.
	Jump = { Enum.KeyCode.Space },
	QuickTurn = { Enum.KeyCode.R },
	Settings = { Enum.KeyCode.P },
}

local Input = {}

local keyToAction: { [Enum.KeyCode]: string } = {}
local heldKeys: { [Enum.KeyCode]: boolean } = {}
local virtualHeld: { [string]: boolean } = {}
local heldCount: { [string]: number } = {}
local lastPressTime: { [string]: number } = {} -- cleared when a press is consumed
-- Raw press history for double-tap detection. Not affected by consume(),
-- because the first tap of a double-tap is often used by something else
-- (for example it starts a slide).
local rawLastPress: { [string]: number } = {}
local rawPrevPress: { [string]: number } = {}
local doubleTapUsed: { [string]: number } = {}
local started = false

local pressedEvent = Instance.new("BindableEvent")
-- Fires (actionName) the moment an action goes down. For things like
-- opening a menu, which react to a press rather than check every frame.
Input.Pressed = pressedEvent.Event

local function press(action: string)
	local count = (heldCount[action] or 0) + 1
	heldCount[action] = count
	if count == 1 then
		local now = os.clock()
		lastPressTime[action] = now
		rawPrevPress[action] = rawLastPress[action]
		rawLastPress[action] = now
		pressedEvent:Fire(action)
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
	table.clear(rawLastPress)
	table.clear(rawPrevPress)
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

-- Was the action pressed twice in quick succession: the second press within
-- `window` seconds of the first, and the second press within the last
-- `recent` seconds? Each double-tap only counts once (see consumeDoubleTap).
function Input.doubleTapped(action: string, window: number, recent: number): boolean
	local last = rawLastPress[action]
	local prev = rawPrevPress[action]
	if last == nil or prev == nil or doubleTapUsed[action] == last then
		return false
	end
	return last - prev <= window and os.clock() - last <= recent
end

-- Was the action pressed within the last `window` seconds, whether or not
-- that press has been consumed?
function Input.recentlyPressed(action: string, window: number): boolean
	local last = rawLastPress[action]
	return last ~= nil and os.clock() - last <= window
end

function Input.consumeDoubleTap(action: string)
	doubleTapUsed[action] = rawLastPress[action]
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
