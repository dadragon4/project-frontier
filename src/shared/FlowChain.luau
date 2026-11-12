-- FLOW chain: rewards linking movement abilities into one sequence
-- (slide, wall-run, roll...). Separate from momentum, which makes a single
-- action cheaper: momentum rewards preparation, a chain rewards execution.
--
-- Like Stamina, this is numbers only: no Roblox services and no clock of
-- its own. The caller passes the current time (`now`, in seconds).
--
-- How a chain works:
--   - an action counts when it FINISHES, and only if it lasted at least
--     MinActionTime. An action dropped the instant it began does not count;
--   - the next action must BEGIN within Window seconds of the previous one
--     finishing. The window does not run while an action is under way, so a
--     long slide down a slope cannot break a chain;
--   - the same action twice in a row keeps the chain alive but adds
--     nothing, so repeating one move is not a chain;
--   - every MinActions counted actions pays Reward stamina, up to
--     MaxRewardPerChain for one chain. After that the chain pays nothing
--     more until it has ended (the window ran out) and a new one begins;
--   - once the chain has MinActions counted actions the player is
--     "in FLOW" until the chain ends (see inFlow and meter).
--
-- `config` is MovementConfig.Flow, read every time so tuning takes effect
-- straight away. This module only says how much a chain has earned; the
-- caller hands that to Stamina.

local FlowChain = {}
FlowChain.__index = FlowChain

function FlowChain.new(config)
	local self = setmetatable({}, FlowChain)
	self.config = config
	self:reset()
	return self
end

function FlowChain:reset()
	self.count = 0 -- actions counted in the current chain
	self.lastAction = nil -- name of the last action that finished
	self.lastEndedAt = nil -- when it finished
	self.rewarded = 0 -- stamina this chain has paid so far
	self.inProgress = false -- an action is under way: the window is paused
end

-- Seconds left to begin the next action. nil if there is no chain, or an
-- action is under way.
function FlowChain:timeLeft(now: number): number?
	if self.inProgress or not self.lastEndedAt then
		return nil
	end
	return math.max(self.config.Window - (now - self.lastEndedAt), 0)
end

-- The hidden FLOW meter: 0 with no chain, 1 (100%) once the chain has
-- MinActions counted actions. Each counted action fills an equal share.
function FlowChain:meter(): number
	return math.min(self.count / self.config.MinActions, 1)
end

-- "In FLOW": the meter is full. It lasts until the chain ends.
function FlowChain:inFlow(): boolean
	return self.count >= self.config.MinActions
end

-- End the chain if its window has run out. Call every frame.
function FlowChain:update(now: number)
	if not self.inProgress and self.lastEndedAt and now - self.lastEndedAt > self.config.Window then
		self:reset()
	end
end

-- A qualifying action has started.
function FlowChain:begin(action: string, now: number)
	if not self.config.Actions[action] then
		return
	end
	self:update(now)
	self.inProgress = true
end

-- The action has ended after `duration` seconds. Returns the stamina the
-- chain earns for it (usually 0).
function FlowChain:finish(action: string, duration: number, now: number): number
	local config = self.config
	if not config.Actions[action] then
		return 0
	end
	self.inProgress = false
	if duration < config.MinActionTime then
		-- Dropped straight away: as if it never happened.
		return 0
	end

	self.lastEndedAt = now
	if action == self.lastAction then
		return 0
	end
	self.lastAction = action
	self.count += 1

	if self.count % config.MinActions ~= 0 then
		return 0
	end
	local reward = math.min(config.Reward, config.MaxRewardPerChain - self.rewarded)
	if reward <= 0 then
		return 0
	end
	self.rewarded += reward
	return reward
end

-- An action with no duration (a wall jump, a jump out of a slide).
function FlowChain:instant(action: string, now: number): number
	if not self.config.Actions[action] then
		return 0
	end
	local wasInProgress = self.inProgress
	self:update(now)
	local reward = self:finish(action, self.config.MinActionTime, now)
	-- An instant action can happen during another one (a wall jump is
	-- reported while the wall-run is still ending); leave that one running.
	self.inProgress = wasInProgress
	return reward
end

return FlowChain
