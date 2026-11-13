-- Prone: lying down and crawling. From holding crouch, or landing a dive.
-- Getting down and up is deliberately slow; tap crouch or press Space to
-- stand, if there is room.
--
-- Limitation: a Roblox Humanoid cannot lie down, so the body is only
-- lowered and stays upright until the custom rig exists.

local Prone = {
	blocksJump = true, -- Space means "get up" here, not "jump"
	clearsSprintToggle = true, -- a toggled sprint would stand straight back up
}

function Prone.enter(ctx)
	ctx.crouched = true
	ctx.input.consume("Crouch")
end

function Prone.update(ctx, dt: number): string?
	local config = ctx.config
	local prone = config.Prone

	if not ctx.grounded then
		return "Air"
	end

	if ctx.stateTime >= prone.MinTime then
		local jumpPressed = ctx.input.isBuffered("Jump", config.Buffer.Jump)
		if jumpPressed or ctx:crouchKey() == "tap" then
			ctx.input.consume("Crouch")
			ctx.input.consume("Jump")
			if jumpPressed then
				-- Start the jump cooldown, so the Space that stands you up is not also a hop.
				ctx._jumpLandedAt = os.clock()
			end
			if ctx:hasHeadroom() then
				return "Walk"
			end
		end
	end

	ctx:accelerate(prone.Speed, prone.Accel, config.GroundDecel, dt)
	return nil
end

return Prone
