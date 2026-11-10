-- Roll. Two ways in (see MovementConfig.Roll):
--   air roll:    on landing from a big enough fall, if crouch was pressed
--                while airborne (decided in Air);
--   ground roll: crouch double-tapped while on the ground (decided in
--                MovementController).
--
-- The character stays low, rolls forward (at least Roll.MinSpeed), and the
-- camera turns over once. When the roll finishes, the next state depends on
-- what is held.

local Roll = {}

local function smoothstep(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

function Roll.enter(ctx, previous: string)
	local roll = ctx.config.Roll
	ctx.crouched = true
	ctx.input.consume("Crouch")
	ctx.input.consumeDoubleTap("Crouch")

	-- Air roll: keep going the way we were travelling.
	-- Ground roll: go where the player is pushing, else the way we were
	-- moving, else straight ahead.
	local speed = ctx:getSpeed()
	local direction
	if previous ~= "Air" and ctx.wishDir ~= Vector3.zero then
		direction = ctx.wishDir
	elseif speed > 0.5 then
		direction = ctx.velocity / speed
	else
		direction = ctx.forward
	end
	ctx.rollDirection = direction
	ctx.velocity = direction * math.clamp(speed, roll.MinSpeed, roll.MaxSpeed)

	-- While the camera turns over, stop the character turning to follow it.
	ctx.humanoid.AutoRotate = false
end

function Roll.exit(ctx)
	ctx.cameraPitch = 0
	ctx.humanoid.AutoRotate = true
end

function Roll.update(ctx, dt: number): string?
	local roll = ctx.config.Roll

	-- Rolled off an edge.
	if not ctx.grounded then
		return "Air"
	end

	local speed = math.max(ctx:getSpeed() - roll.Friction * dt, 0)
	ctx.velocity = ctx.rollDirection * speed

	local progress = ctx.stateTime / roll.Duration
	ctx.cameraPitch = -math.rad(roll.CameraSpin) * smoothstep(progress)

	if progress >= 1 then
		if ctx.input.isDown("Crouch") then
			return "Crouch"
		end
		if ctx:wantsSprint() then
			return "Sprint"
		end
		return "Walk"
	end
	return nil
end

return Roll
