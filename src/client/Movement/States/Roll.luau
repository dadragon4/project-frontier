-- Roll: entered on landing when crouch was pressed while airborne.
--
-- The character stays low, keeps rolling forward in the direction it was
-- travelling (at least Roll.MinSpeed), and the camera turns over once.
-- When the roll finishes, the next state depends on what is held.

local Roll = {}

local function smoothstep(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

function Roll.enter(ctx)
	local roll = ctx.config.Roll
	ctx.crouched = true
	ctx.input.consume("Crouch")

	local speed = ctx:getSpeed()
	local direction = if speed > 0.5 then ctx.velocity / speed else ctx.forward
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
