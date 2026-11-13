-- In the air (jumping or falling). Speed is carried; you can steer a little.
--
-- A jump out of a slide gets a small slide-hop boost. In the air,
-- MovementController checks for vault / mantle / ledge grab, and a wall
-- beside you starts a wall-run if you left the ground sprinting.
-- On landing: Roll (roll pressed and a long enough fall), Slide (crouch
-- tapped, fast enough), otherwise Sprint or Walk.

local Air = {
	allowsClamber = true,
}

function Air.enter(ctx, previous: string)
	-- A wall-run needs a sprint first (or a slide or wall-run, which come from one).
	ctx.airFromSprint = previous == "Sprint" or previous == "Slide" or previous == "WallRun"
	-- After a wall jump, the opposite wall can be caught at a steep angle.
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
			-- No air roll (fall too short or no stamina): drop the press so it does
			-- not turn into a ground roll on landing.
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
