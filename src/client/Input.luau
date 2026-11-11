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
--
-- Tap and hold: one key can mean two things. A "tap" is a press that was
-- let go again quickly; a "hold" is a press kept down. A tap is only known
-- once the key comes back up, so tap actions fire on release.

local UserInputService = game:GetService("UserInputService")

local BINDINGS: { [string]: { Enum.KeyCode } } = {
	Sprint = { Enum.KeyCode.LeftShift },
	-- Tap: crouch / slide / stand up. Hold: prone / dive.
	Crouch = { Enum.KeyCode.C },
	-- LeftSuper / LeftMeta is the Command key on a Mac (and the Windows key on
	-- a PC, where Windows itself takes the key press). Scripts cannot ask
	-- which operating system the player is on, so all of these are bound
	-- everywhere: Mac players roll with Command or Ctrl, PC players with Ctrl.
	Roll = {
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
local rawLastPress: { [string]: number } = {} -- like lastPressTime, but not cleared by consume()
local downSince: { [string]: number } = {} -- when the current hold began; nil once it is consumed or released
local lastTapTime: { [string]: number } = {} -- when the last tap was let go; cleared when consumed
local lastTapHeld: { [string]: number } = {} -- how long that tap was held down
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
		rawLastPress[action] = now
		downSince[action] = now
		pressedEvent:Fire(action)
	end
end

local function release(action: string)
	local count = math.max((heldCount[action] or 0) - 1, 0)
	heldCount[action] = count
	-- A press that was already acted on (consumed) does not also count as a tap.
	if count == 0 and downSince[action] then
		local now = os.clock()
		lastTapTime[action] = now
		lastTapHeld[action] = now - downSince[action]
		downSince[action] = nil
	end
end

local function releaseEverything()
	table.clear(heldKeys)
	table.clear(virtualHeld)
	table.clear(heldCount)
	table.clear(lastPressTime)
	table.clear(rawLastPress)
	table.clear(downSince)
	table.clear(lastTapTime)
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

-- Was the action tapped: held for no longer than `maxHold` seconds, let go
-- within the last `window` seconds, and not yet consumed?
function Input.tapped(action: string, maxHold: number, window: number): boolean
	local tappedAt = lastTapTime[action]
	return tappedAt ~= nil and lastTapHeld[action] <= maxHold and os.clock() - tappedAt <= window
end

-- How many seconds the action has been held down. 0 if it is not down, or
-- if this press has already been consumed.
function Input.heldFor(action: string): number
	local since = downSince[action]
	return if since then os.clock() - since else 0
end

-- Was the action pressed within the last `window` seconds, whether or not
-- that press has been consumed?
function Input.recentlyPressed(action: string, window: number): boolean
	local last = rawLastPress[action]
	return last ~= nil and os.clock() - last <= window
end

-- Mark the most recent press of this action as used, whether it was a
-- press, a tap or a hold that is still going.
function Input.consume(action: string)
	lastPressTime[action] = nil
	lastTapTime[action] = nil
	downSince[action] = nil
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
