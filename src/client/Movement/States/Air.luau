-- Airborne (jumping or falling). Speed is carried; the player can steer a
-- little.
--
-- While airborne:
--   - pushing into a ledge of the right height starts a Mantle.
-- On landing:
--   - crouch pressed at any point during this time in the air  -> Roll
--   - crouch held from before leaving the ground, moving fast  -> Slide
--   - crouch held, moving slowly                               -> Crouch
--   - otherwise Sprint or Walk.

local Air = {}

function Air.update(ctx, dt: number): string?
	local config = ctx.config

	if ctx.grounded and ctx.airTime == 0 then
		if ctx.input.pressedSince("Crouch", ctx.leftGroundAt) then
			return "Roll"
		end
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
