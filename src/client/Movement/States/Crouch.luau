-- Crouched on the ground. Stays crouched while the key is held, or while
-- there is no room to stand.

local Crouch = {
	allowsGroundRoll = true, -- double-tapping crouch here starts a roll
}

function Crouch.enter(ctx)
	ctx.crouched = true
end

function Crouch.update(ctx, dt: number): string?
	local config = ctx.config

	if not ctx.grounded then
		return "Air"
	end

	if not ctx.input.isDown("Crouch") and ctx:hasHeadroom() then
		return "Walk"
	end

	ctx:accelerate(config.CrouchSpeed, config.GroundAccel, config.GroundDecel, dt)
	return nil
end

return Crouch
