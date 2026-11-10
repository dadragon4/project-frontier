-- Standing on the ground, walking or idle.

local Walk = {
	allowsGroundRoll = true, -- double-tapping crouch here starts a roll
}

function Walk.enter(ctx)
	ctx.crouched = false
end

function Walk.update(ctx, dt: number): string?
	local config = ctx.config

	if not ctx.grounded then
		return "Air"
	end

	if ctx.input.isDown("Crouch") then
		-- Still carrying sprint speed and crouch was pressed a moment ago: slide.
		if ctx.input.isBuffered("Crouch", config.Buffer.Slide) and ctx:getSpeed() >= config.Slide.MinSpeed then
			return "Slide"
		end
		return "Crouch"
	end

	if ctx:wantsSprint() then
		return "Sprint"
	end

	ctx:accelerate(config.WalkSpeed, config.GroundAccel, config.GroundDecel, dt)
	return nil
end

return Walk
