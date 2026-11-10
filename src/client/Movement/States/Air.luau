-- Airborne (jumping or falling). Speed is carried; the player can steer a
-- little. Landing chooses the next state from what the player is holding,
-- so holding crouch into a fast landing chains straight into a slide.

local Air = {}

function Air.update(ctx, dt: number): string?
	local config = ctx.config

	if ctx.grounded and ctx.airTime == 0 then
		if ctx.input.isDown("Crouch") then
			if ctx:getSpeed() >= config.Slide.MinSpeed then
				return "Slide"
			end
			return "Crouch"
		end
		if ctx:wantsSprint() then
			return "Sprint"
		end
		return "Walk"
	end

	ctx:airSteer(dt)
	return nil
end

return Air
