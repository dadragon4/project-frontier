-- Running. Speed builds up over time rather than switching on instantly.
-- Works in any direction; sideways and backwards are slower.

local Sprint = {
	staminaDrain = "SprintDrain", -- costs stamina for as long as it lasts
	allowsGroundRoll = true, -- the roll key rolls from here
	allowsClamber = true, -- vault / mantle can start from here
}

function Sprint.enter(ctx)
	ctx.crouched = false
end

function Sprint.update(ctx, dt: number): string?
	local config = ctx.config

	if not ctx.grounded then
		return "Air"
	end

	-- Crouch key: tap to slide, hold to dive. Too slow for either (or too
	-- soon after the last slide), and it behaves as it does when walking
	-- (crouch / prone).
	local key = ctx:crouchKey()
	if key == "tap" then
		return if ctx:canSlide() then "Slide" else "Crouch"
	elseif key == "hold" then
		return if ctx:canDive() then "Dive" else "Prone"
	end

	if not ctx:wantsSprint() then
		return "Walk"
	end

	-- Below walk speed pick up speed at the normal rate; above it, build
	-- toward sprint speed slowly. What counts is the speed in the direction
	-- being pushed, not the total: after cutting sideways out of a sprint
	-- you are still moving fast, but not yet in the new direction, and that
	-- new direction should pick up at the normal rate.
	local along = ctx.velocity:Dot(ctx.wishDir)
	local accel = if along < config.WalkSpeed then config.GroundAccel else config.SprintAccel
	-- Extra speed from a slide-hop or vault bleeds away gently (OverSpeedDecel).
	ctx:accelerate(config.SprintSpeed, accel, config.GroundDecel, dt, config.OverSpeedDecel)
	return nil
end

return Sprint
