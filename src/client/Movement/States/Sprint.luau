-- Running. Speed builds up; works in any direction, slower sideways and back.

local Sprint = {
	staminaDrain = "SprintDrain", -- costs stamina for as long as it lasts
	allowsGroundRoll = true, -- the roll key rolls from here
	allowsClamber = true, -- vault / mantle can start from here
}

function Sprint.enter(ctx, previous: string?)
	ctx.crouched = false

	-- Sprint pressed while already strafing (from a walk, moving sideways):
	-- jump straight to sprint-strafe speed, so quick strafes answer at once.
	local config = ctx.config
	local wish = ctx.wishDir
	if
		previous == "Walk"
		and wish ~= Vector3.zero
		and math.abs(wish:Dot(ctx.forward)) <= config.StrafeSprintSnapDot
		and ctx.velocity:Dot(wish) > 1
	then
		ctx.velocity = wish * ctx:sprintSpeed() * ctx:directionSpeedScale() * ctx.stamina:speedScale()
		-- The body takes a few frames to catch up; that is not a wall.
		ctx.blockedGraceUntil = os.clock() + 0.2
	end
end

function Sprint.update(ctx, dt: number): string?
	local config = ctx.config

	if not ctx.grounded then
		return "Air"
	end

	-- Crouch key: tap = slide, hold = dive (or crouch / prone if too slow).
	local key = ctx:crouchKey()
	if key == "tap" then
		return if ctx:canSlide() then "Slide" else "Crouch"
	elseif key == "hold" then
		return if ctx:canDive() then "Dive" else "Prone"
	end

	if not ctx:wantsSprint() then
		return "Walk"
	end

	-- Normal acceleration up to walk speed, then slower up to sprint speed.
	-- Measured in the pushed direction, so cutting sideways out of a sprint
	-- picks up the new direction at the normal rate.
	local along = ctx.velocity:Dot(ctx.wishDir)
	local accel = if along < config.WalkSpeed then config.GroundAccel else config.SprintAccel
	-- Extra speed from a slide-hop or vault fades gently.
	ctx:accelerate(ctx:sprintSpeed(), accel, config.GroundDecel, dt, config.OverSpeedDecel)
	return nil
end

return Sprint
