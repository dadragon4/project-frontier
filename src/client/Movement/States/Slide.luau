-- Sliding: direction is mostly locked, speed bleeds off through friction,
-- and slopes add or remove speed. Jumping out of a slide keeps the speed
-- (the Air state takes over as soon as the character leaves the ground).

local Slide = {}

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

	-- Friction always slows the slide.
	speed -= slide.Friction * dt

	-- Slopes: the floor normal leans toward downhill. Sliding downhill adds
	-- speed, sliding uphill removes it, in proportion to steepness.
	local normal = ctx:getFloorNormal()
	local downhill = Vector3.new(normal.X, 0, normal.Z)
	local steepness = downhill.Magnitude -- 0 on flat ground
	if steepness > 0.01 then
		speed += direction:Dot(downhill / steepness) * steepness * slide.SlopeAccel * dt
	end

	speed = math.clamp(speed, 0, slide.MaxSpeed)
	ctx.velocity = direction * speed

	local held = ctx.input.isDown("Crouch")

	if speed < slide.EndSpeed then
		return if held then "Crouch" else "Walk"
	end

	-- Letting go of crouch ends the slide early.
	if not held and ctx.stateTime >= slide.MinTime then
		return if ctx:wantsSprint() then "Sprint" else "Walk"
	end

	return nil
end

return Slide
