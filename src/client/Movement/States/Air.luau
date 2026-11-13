-- Airborne (jumping or falling). Speed is carried; the player can steer a
-- little.
--
-- Entering from a jump out of a slide gives a small slide-hop boost.
-- While airborne:
--   - vault / mantle / ledge grab are checked by MovementController;
--   - a wall beside you, while moving along it, starts a WallRun, but
--     only if you were sprinting when you left the ground.
-- On landing:
--   - roll pressed during this time in the air, and the fall was at least
--     Roll.MinFallHeight                              -> Roll
--   - crouch tapped just before landing, moving fast  -> Slide
--   - otherwise Sprint or Walk.

local Air = {
	allowsClamber = true,
}

function Air.enter(ctx, previous: string)
	-- A wall-run needs a sprint first (user ruling 2026-11-12): it can only
	-- start if this time in the air began from a sprint, from a slide (which
	-- itself comes out of a sprint) or from another wall-run.
	ctx.airFromSprint = previous == "Sprint" or previous == "Slide" or previous == "WallRun"
	-- Flying off a wall after a wall jump: the opposite wall can be caught
	-- at a steeper angle (see Detection.findWallRunWall).
	ctx.afterWallJump = previous == "WallRun" and ctx.wallJumped == true
	local hop = ctx.config.SlideHop
	if previous == "Slide" and ctx._jumped then
		-- A jump out of a slide is a FLOW action, boosted or not.
		ctx:flowInstant("SlideHop")
		if os.clock() - ctx.lastSlideHop > hop.Cooldown then
			local speed = ctx:getSpeed()
			if speed > 0.5 then
				local boosted = math.min(speed + hop.Boost, math.max(speed, hop.MaxSpeed))
				ctx.velocity = ctx.velocity / speed * boosted
				ctx.lastSlideHop = os.clock()
			end
		end
	end
end

function Air.update(ctx, dt: number): string?
	local config = ctx.config

	if ctx.grounded and ctx.airTime == 0 then
		if ctx.input.pressedSince("Roll", ctx.leftGroundAt) then
			if ctx.lastFallHeight >= config.Roll.MinFallHeight and ctx:canUseStamina() then
				return "Roll"
			end
			-- Too short a fall for an air roll (or no stamina for one): the
			-- press is dropped, so it does not turn into a ground roll the
			-- moment we land.
			ctx.input.consume("Roll")
		end

		if ctx:crouchKey() == "tap" and ctx:canSlide() then
			return "Slide"
		end
		if ctx:wantsSprint() then
			return "Sprint"
		end
		return "Walk"
	end

	if ctx.airFromSprint and ctx.airTime >= config.WallRun.MinAirTime and ctx:canUseStamina() then
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
