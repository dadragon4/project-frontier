-- The player's own preferences (as opposed to MovementConfig, which holds
-- the game's tuning numbers and is the same for everyone).
--
-- Not saved yet: values reset every time the player joins. Saving belongs
-- to the persistence work in Phase 5.

local Settings = {}

local values = {
	-- true: no head bob, lean, tilt or roll camera spin; smaller landing dip
	-- and field-of-view changes. For players who get motion sick.
	ReduceCameraMotion = false,

	-- "Auto":   vault / mantle / ledge grab happen when you move into an
	--           obstacle (on the ground or in the air).
	-- "Manual": they only happen when you press or hold Space at the
	--           obstacle (rewarded with a small stamina refund once stamina
	--           exists).
	-- Keyboard default is Auto (user decision 2026-11-10).
	ClamberMode = "Auto",
}

local changed = Instance.new("BindableEvent")

-- Fires (name, value) whenever a setting changes.
Settings.Changed = changed.Event

function Settings.get(name: string): any
	return values[name]
end

function Settings.set(name: string, value: any)
	if values[name] == nil then
		error("Unknown setting: " .. name)
	end
	if values[name] ~= value then
		values[name] = value
		changed:Fire(name, value)
	end
end

return Settings
