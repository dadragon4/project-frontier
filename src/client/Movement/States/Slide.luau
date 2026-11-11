-- Sliding: direction is mostly locked, speed bleeds off through friction,
-- and slopes add or remove speed. Jumping out of a slide keeps the speed
-- (the Air state takes over as soon as the character leaves the ground).
--
-- Started by tapping crouch while sprinting; the key does not need to be
-- held. On flat ground it ends, crouched, when the speed runs out. Down a
-- slope there is no friction and it carries on until the slope levels out.
-- Pressing crouch again ends it early (into a crouch); so does jumping.

local Slide = {
	allowsGroundRoll = true, -- the roll key rolls from here
	allowsClamber = true, -- vault / mantle can start from here
}

function Slide.enter(ctx)
	local slide = ctx.config.Slide
	ctx.crouched = true
	-- The crouch press that started this slide has now been used.
	ctx.input.consume("Crouch")

	local speed = ctx:getSpeed()
	local direction = if speed > 0.01 then ctx.velocity / speed else ctx.forward

	-- A small push at the start, unless the player is chaining slides.
	if os.clock() - ctx.lastSlideEnd > slide.BoostCooldown then
		speed = math.min(speed + slide.Boost, math.max(speed, slide.MaxSpeed))
	end

	ctx.velocity = direction * speed
end

function Slide.exit(ctx)
	ctx.lastSlideEnd = os.clock()
end

function Slide.update(ctx, dt: number): string?
	local slide = ctx.config.Slide

	if not ctx.grounded then
		return "Air"
	end

	local speed = ctx:getSpeed()
	if speed < 0.01 then
		return "Crouch"
	end
	local direction = ctx.velocity / speed

	-- Limited steering toward where the player is pushing.
	if ctx.wishDir ~= Vector3.zero then
		local angle = math.acos(math.clamp(direction:Dot(ctx.wishDir), -1, 1))
		if angle > 1e-3 then
			local turn = math.min(slide.SteerRate * dt / angle, 1)
			local steered = direction:Lerp(ctx.wishDir, turn)
			if steered.Magnitude > 1e-3 then
				direction = steered.Unit
			end
		end
	end

	-- Slopes: the floor normal leans toward downhill. Sliding downhill adds
	-- speed, sliding uphill removes it, in proportion to steepness.
	-- `slope` is 0 on flat ground, positive heading downhill, negative uphill
	-- (it is the sine of the slope's angle along our direction).
	local normal = ctx:getFloorNormal()
	local slope = direction:Dot(Vector3.new(normal.X, 0, normal.Z))
	local onDownSlope = slope >= math.sin(math.rad(slide.SlopeMinAngle))
	speed += slope * slide.SlopeAccel * dt

	-- Friction slows the slide, except while heading down a slope.
	if not onDownSlope then
		speed -= slide.Friction * dt
	end

	speed = math.clamp(speed, 0, slide.MaxSpeed)
	ctx.velocity = direction * speed

	-- Out of speed: the slide ends in a crouch. (Not on a downward slope,
	-- where it keeps going until the slope levels out.)
	if speed < slide.EndSpeed and not onDownSlope then
		return "Crouch"
	end

	-- Pressing crouch again ends the slide early.
	if ctx.stateTime >= slide.MinTime and ctx.input.isBuffered("Crouch", ctx.config.Buffer.Slide) then
		return "Crouch"
	end

	return nil
end

return Slide
