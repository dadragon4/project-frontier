-- Standing on the ground, walking or idle.

local Walk = {
	allowsGroundRoll = true, -- the roll key rolls from here (if moving)
	allowsClamber = true, -- vault / mantle can start from here
}

function Walk.enter(ctx)
	ctx.crouched = false
end

function Walk.update(ctx, dt: number): string?
	local config = ctx.config

	if not ctx.grounded then
		return "Air"
	end

	-- Crouch key: tap to crouch, hold to go prone (or dive, if still
	-- carrying enough speed).
	local key = ctx:crouchKey()
	if key == "tap" then
		return "Crouch"
	elseif key == "hold" then
		return if ctx:getSpeed() >= config.Dive.MinSpeed then "Dive" else "Prone"
	end

	if ctx:wantsSprint() then
		return "Sprint"
	end

	ctx:accelerate(config.WalkSpeed, config.GroundAccel, config.GroundDecel, dt)
	return nil
end

return Walk
