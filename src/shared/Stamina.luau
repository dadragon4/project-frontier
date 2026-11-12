-- Stamina: the numbers only. No Roblox services, no character, no clock of
-- its own: everything it needs is passed in. That keeps it easy to check,
-- and lets the server run the very same rules later to verify what a
-- client reports (the client simulates its own stamina for now).
--
-- The rules:
--   - spending takes stamina, never below zero, and restarts the wait
--     before stamina comes back (RegenDelay);
--   - once that wait is over, stamina comes back at RegenRate per second;
--   - reaching zero makes the player "exhausted" (ground movement is
--     slowed). Exhaustion lasts until stamina is back up to RecoverAt, not
--     just above zero, so it cannot flicker on and off;
--   - a refund (manual clamber, a FLOW chain) adds stamina without
--     restarting the wait.
--
-- `config` is MovementConfig.Stamina. It is read every time, not copied,
-- so tuning a number takes effect straight away.

local Stamina = {}
Stamina.__index = Stamina

local function planar(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

function Stamina.new(config)
	local self = setmetatable({}, Stamina)
	self.config = config
	self.max = config.Max
	self.current = config.Max
	self.exhausted = false
	self.regenDelayLeft = 0 -- seconds until stamina starts coming back
	return self
end

-- Take `amount` of stamina. If there is not enough, what is left is taken
-- and the player becomes exhausted: an action is never refused for lack of
-- stamina. Returns how much was actually taken.
-- Even an empty-handed attempt restarts the regeneration wait, so repeating
-- actions at zero stamina keeps you exhausted.
function Stamina:spend(amount: number): number
	local taken = math.clamp(amount, 0, self.current)
	self.current -= taken
	self.regenDelayLeft = self.config.RegenDelay
	if self.current <= 1e-6 then
		self.current = 0
		self.exhausted = true
	end
	return taken
end

-- Give stamina back, never above the maximum. Returns how much was added.
function Stamina:refund(amount: number): number
	local gained = math.clamp(amount, 0, self.max - self.current)
	self.current += gained
	if self.exhausted and self.current >= self.config.RecoverAt then
		self.exhausted = false
	end
	return gained
end

-- Advance time by `dt` seconds: count down the wait, then regenerate with
-- whatever time is left over. Because the leftover is used, the result is
-- the same at any frame rate.
function Stamina:step(dt: number)
	if self.regenDelayLeft > 0 then
		local waited = math.min(dt, self.regenDelayLeft)
		self.regenDelayLeft -= waited
		dt -= waited
	end
	if dt > 0 then
		self:refund(self.config.RegenRate * dt)
	end
end

-- Multiplier for ordinary ground speed: 1 normally, lower while exhausted.
function Stamina:speedScale(): number
	return if self.exhausted then self.config.ExhaustedSpeedScale else 1
end

-- Back to full, as on spawning. Used by the scripted tests.
function Stamina:refill()
	self.current = self.max
	self.exhausted = false
	self.regenDelayLeft = 0
end

-- Set stamina directly (scripted tests). Zero means exhausted.
function Stamina:set(value: number)
	self.current = math.clamp(value, 0, self.max)
	if self.current <= 0 then
		self.exhausted = true
	elseif self.current >= self.config.RecoverAt then
		self.exhausted = false
	end
end

-- Momentum: how much of the player's speed counts toward a cheaper action.
--
-- Only speed that is real, intended and forward counts:
--   - `intended` is the velocity the movement code is asking for and
--     `actual` is what the body is really doing. Taking the lower of the
--     two means running into a wall (intended but not actual) and being
--     shoved (actual but not intended) both earn nothing;
--   - both are measured along `facing` (where the player is looking,
--     flattened), so sideways and backward speed earn nothing;
--   - vertical speed (falling) is ignored.
function Stamina.qualifyingSpeed(intended: Vector3, actual: Vector3, facing: Vector3): number
	local forward = planar(facing)
	if forward.Magnitude < 1e-4 then
		return 0
	end
	forward = forward.Unit
	return math.max(math.min(planar(intended):Dot(forward), planar(actual):Dot(forward)), 0)
end

-- The share of an action's cost that momentum takes off: nothing standing
-- still, rising in a straight line to `maxDiscount` at `fullSpeed`, and no
-- more than that however fast you go.
function Stamina.momentumDiscount(speed: number, fullSpeed: number, maxDiscount: number): number
	return maxDiscount * math.clamp(speed / fullSpeed, 0, 1)
end

function Stamina.discountedCost(baseCost: number, discount: number): number
	return baseCost * (1 - discount)
end

return Stamina
