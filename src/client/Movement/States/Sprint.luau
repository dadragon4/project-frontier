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

	ctx:accelerate(config.SprintSpeed, config.SprintAccel, config.GroundDecel, dt)
	return nil
end

return Sprint
