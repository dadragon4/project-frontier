-- Running. Speed builds up over time rather than switching on instantly.
-- Works in any direction; sideways and backwards are slower.

local Sprint = {
	staminaDrain = "SprintDrain", -- costs stamina for as long as it lasts
	allowsGroundRoll = true, -- the roll key rolls from here
	allowsClamber = true, -- vault / mantle can start from here
}

function Sprint.enter(ctx, previous: string?)
	ctx.crouched = false

	-- Pressing sprint while already strafing: go straight to sprint-strafe
	-- speed, with no build-up, so quick strafes answer at once. Only from a
	-- walk, only when already moving the way the player is pushing, and only
	-- when that push is sideways (see StrafeSprintSnapDot).
	local config = ctx.config
	local wish = ctx.wishDir
	if
		previous == "Walk"
		and wish ~= Vector3.zero
		and math.abs(wish:Dot(ctx.forward)) <= config.StrafeSprintSnapDot
		and ctx.velocity:Dot(wish) > 1
	then
		ctx.velocity = wish * ctx:sprintSpeed() * ctx:directionSpeedScale() * ctx.stamina:speedScale()
		-- The body needs a few frames to catch up with this jump in speed;
		-- do not mistake that for running into a wall.
		ctx.blockedGraceUntil = os.clock() + 0.2
	end
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
	ctx:accelerate(ctx:sprintSpeed(), accel, config.GroundDecel, dt, config.OverSpeedDecel)
	return nil
end

return Sprint
