-- Crouched on the ground. Crouch is a toggle: it stays until the player
-- taps crouch again, starts sprinting, or goes prone. It also stays while
-- there is no room to stand.

local Crouch = {
	clearsSprintToggle = true, -- a toggled sprint would stand straight back up
}

function Crouch.enter(ctx)
	ctx.crouched = true
	-- The key press that brought us here has now been used.
	ctx.input.consume("Crouch")
end

function Crouch.update(ctx, dt: number): string?
	local config = ctx.config

	if not ctx.grounded then
		return "Air"
	end

	local key = ctx:crouchKey()
	if key == "hold" then
		return "Prone"
	elseif key == "tap" then
		ctx.input.consume("Crouch")
		if ctx:hasHeadroom() then
			return "Walk"
		end
	end

	-- Holding sprint while moving stands you up and runs.
	if ctx:wantsSprint() and ctx:hasHeadroom() then
		return "Sprint"
	end

	ctx:accelerate(config.CrouchSpeed, config.GroundAccel, config.GroundDecel, dt)
	return nil
end

return Crouch
