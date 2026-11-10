-- Running. Speed builds up over time rather than switching on instantly.

local Sprint = {}

function Sprint.enter(ctx)
	ctx.crouched = false
end

function Sprint.update(ctx, dt: number): string?
	local config = ctx.config

	if not ctx.grounded then
		return "Air"
	end

	if ctx.input.isDown("Crouch") then
		if ctx:getSpeed() >= config.Slide.MinSpeed then
			return "Slide"
		end
		return "Crouch"
	end

	if not ctx:wantsSprint() then
		return "Walk"
	end

	-- Below walk speed (for example straight after turning round) pick up
	-- speed at the normal rate; above it, build toward sprint speed slowly.
	local accel = if ctx:getSpeed() < config.WalkSpeed then config.GroundAccel else config.SprintAccel
	ctx:accelerate(config.SprintSpeed, accel, config.GroundDecel, dt)
	return nil
end

return Sprint
