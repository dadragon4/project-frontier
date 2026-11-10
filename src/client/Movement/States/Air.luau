-- Airborne (jumping or falling). Speed is carried; the player can steer a
-- little.
--
-- While airborne:
--   - pushing into a ledge of the right height starts a Mantle.
-- On landing:
--   - crouch pressed during this time in the air, and the fall was at least
--     Roll.MinFallHeight                                        -> Roll
--   - crouch held, or tapped just before landing, moving fast   -> Slide
--   - crouch held, moving slowly                                -> Crouch
--   - otherwise Sprint or Walk.

local Air = {}

function Air.update(ctx, dt: number): string?
	local config = ctx.config

	if ctx.grounded and ctx.airTime == 0 then
		local pressedInAir = ctx.input.pressedSince("Crouch", ctx.leftGroundAt)
		if pressedInAir and ctx.lastFallHeight >= config.Roll.MinFallHeight then
			return "Roll"
		end

		local held = ctx.input.isDown("Crouch")
		local tapped = ctx.input.isBuffered("Crouch", config.Buffer.Slide)
		if (held or tapped) and ctx:getSpeed() >= config.Slide.MinSpeed then
			return "Slide"
		end
		if held then
			return "Crouch"
		end
		if ctx:wantsSprint() then
			return "Sprint"
		end
		return "Walk"
	end

	if os.clock() - ctx.lastMantleEnd > config.Mantle.Cooldown then
		local ledge = ctx:findLedge()
		if ledge then
			ctx.pendingLedge = ledge
			return "Mantle"
		end
	end

	ctx:airSteer(dt)
	return nil
end

return Air
