-- Prone: lying down and crawling. Entered by holding crouch (from standing,
-- walking or crouching) or by landing a Dive.
--
-- Known limitation: a Roblox Humanoid cannot lie down, so for now the body
-- is only lowered as far as it will go and stays upright. In first person
-- that reads as lying down; other players see a very short standing
-- character. Laying the body flat waits for the custom rig and animations.
--
-- Getting down and up is deliberately slow. Tap crouch, or press jump, to
-- stand up, if there is room to.

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
				-- Start the jump cooldown, so the Space that stands you up
				-- does not also make you hop.
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
