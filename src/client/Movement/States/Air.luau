-- Airborne (jumping or falling). Speed is carried; the player can steer a
-- little.
--
-- Entering from a jump out of a slide gives a small slide-hop boost.
-- While airborne:
--   - vault / mantle / ledge grab are checked by MovementController;
--   - a wall beside you, while moving along it, starts a WallRun.
-- On landing:
--   - crouch pressed during this time in the air, and the fall was at least
--     Roll.MinFallHeight                                        -> Roll
--   - crouch held, or tapped just before landing, moving fast   -> Slide
--   - crouch held, moving slowly                                -> Crouch
--   - otherwise Sprint or Walk.

local Air = {
	allowsClamber = true,
}

function Air.enter(ctx, previous: string)
	local hop = ctx.config.SlideHop
	if previous == "Slide" and ctx._jumped and os.clock() - ctx.lastSlideHop > hop.Cooldown then
		local speed = ctx:getSpeed()
		if speed > 0.5 then
			local boosted = math.min(speed + hop.Boost, math.max(speed, hop.MaxSpeed))
			ctx.velocity = ctx.velocity / speed * boosted
			ctx.lastSlideHop = os.clock()
		end
	end
end

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

	if ctx.airTime >= config.WallRun.MinAirTime then
		local wall = ctx:findWallRunWall()
		if wall then
			ctx.pendingWall = wall
			return "WallRun"
		end
	end

	ctx:airSteer(dt)
	return nil
end

return Air
