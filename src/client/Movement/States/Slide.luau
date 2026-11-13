-- Sliding: started by tapping crouch while sprinting straight ahead.
-- Direction is mostly locked; friction slows it on flat ground; slopes
-- add or remove speed. Down a slope it has no friction and lasts until the
-- slope levels out.
--
-- How it ends:
--   by itself (out of speed or distance)  -> Sprint, or Walk if out of stamina
--   crouch pressed                        -> Crouch
--   sprint pressed                        -> Sprint
--   jump                                  -> Air
-- Under a low roof it always ends crouched. The roll key does nothing here.
-- Slide.Cooldown keeps sprint and slide from being spammed.

local Slide = {
	staminaCost = "Slide", -- paid once, when the slide starts
	flowAction = "Slide", -- counts toward a FLOW chain
	allowsClamber = true, -- vault / mantle can start from here
}

-- Where a slide goes when it ends by itself.
local function finished(ctx): string
	return if ctx:canUseStamina() then "Sprint" else "Walk"
end

function Slide.enter(ctx)
	local slide = ctx.config.Slide
	ctx.crouched = true
	-- The crouch press that started this slide has now been used.
	ctx.input.consume("Crouch")
	ctx.slideStartedAt = os.clock()
	-- A slide started while in FLOW has a higher top speed on slopes.
	ctx.slideInFlow = ctx.flow:inFlow()
	ctx.slideFlatDistance = 0 -- studs travelled on flat ground so far

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
		return finished(ctx)
	end
	local direction = ctx.velocity / speed

	-- Steering: the slide turns toward where the player is looking, at a
	-- fixed rate (SteerRate radians per second, whatever the angle: the lerp
	-- fraction below divides by it). Keys do not steer a slide.
	--
	-- The rate is the point. The old camera steering turned the slide by a
	-- share of however far the view moved that frame, so a fast flick
	-- whipped it round and a player on a high mouse sensitivity steered
	-- harder than one on a low setting. Here the mouse's speed does not
	-- matter: holding the view off to one side keeps the slide curving
	-- toward it until it lines up, and looking straight ahead stops it.
	local angle = math.acos(math.clamp(direction:Dot(ctx.forward), -1, 1))
	if angle > 1e-3 then
		local turn = math.min(slide.SteerRate * dt / angle, 1)
		local steered = direction:Lerp(ctx.forward, turn)
		if steered.Magnitude > 1e-3 then
			direction = steered.Unit
		end
	end

	-- Slopes: downhill adds speed, uphill removes it. `slope` is the sine of
	-- the slope along our direction: 0 flat, positive downhill.
	local normal = ctx:getFloorNormal()
	local slope = direction:Dot(Vector3.new(normal.X, 0, normal.Z))
	local onDownSlope = slope >= math.sin(math.rad(slide.SlopeMinAngle))
	speed += slope * slide.SlopeAccel * dt

	-- Friction slows the slide, except while heading down a slope.
	if not onDownSlope then
		speed -= slide.Friction * dt
	end

	-- One cap, chosen by where we are: a slide heading downhill is allowed
	-- past the flat MaxSpeed, and further still if it started in FLOW.
	-- (Clamping to MaxSpeed first and only then taking the slope cap would
	-- leave the slope caps unreachable whenever they are the higher number.)
	local cap = if not onDownSlope
		then slide.MaxSpeed
		elseif ctx.slideInFlow then slide.FlowSlopeMaxSpeed
		else slide.SlopeMaxSpeed
	speed = math.clamp(speed, 0, cap)
	if not onDownSlope then
		ctx.slideFlatDistance += speed * dt
	end
	ctx.velocity = direction * speed

	-- A flat slide never travels further than MaxFlatDistance.
	if ctx.slideFlatDistance >= slide.MaxFlatDistance then
		return finished(ctx)
	end

	-- Out of speed (never on a downward slope).
	if speed < slide.EndSpeed and not onDownSlope then
		return finished(ctx)
	end

	-- Sprint pressed (a new press) goes back to a sprint. In Toggle mode the
	-- press just flipped the switch off, so turn it back on.
	if
		ctx.stateTime >= slide.MinTime
		and ctx.input.pressedSince("Sprint", ctx.slideStartedAt)
		and ctx.wishDir ~= Vector3.zero
		and ctx:canUseStamina()
	then
		ctx.input.consume("Sprint")
		ctx.sprintOn = true
		return "Sprint"
	end

	-- Pressing crouch again ends the slide early.
	if ctx.stateTime >= slide.MinTime and ctx.input.isBuffered("Crouch", ctx.config.Buffer.Slide) then
		return "Crouch"
	end

	return nil
end

return Slide
