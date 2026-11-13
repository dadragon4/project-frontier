-- Dive: a leap in the direction you are already moving that lands prone.
-- Entered by holding crouch while moving fast (see Sprint and Walk).
--
-- The direction is fixed when the dive starts; there is no steering in the
-- air. The body lowers toward prone during the flight.

local Workspace = game:GetService("Workspace")

local Dive = {
	staminaCost = "Dive", -- paid once, when the dive starts
	flowAction = "Dive", -- counts toward a FLOW chain
	blocksJump = true,
	clearsSprintToggle = true, -- a dive ends prone, not sprinting
}

function Dive.enter(ctx)
	local dive = ctx.config.Dive
	ctx.crouched = true
	ctx.input.consume("Crouch")

	local speed = ctx:getSpeed()
	local direction = if speed > 0.5 then ctx.velocity / speed else ctx.forward
	speed = math.min(speed + dive.Boost, math.max(speed, dive.MaxSpeed))

	-- The upward speed that reaches exactly `Height` under gravity.
	local up = math.sqrt(2 * Workspace.Gravity * dive.Height)
	-- Freefall tells the Humanoid it is in the air, so it does not hold the
	-- feet to the floor.
	ctx:releaseBody(Enum.HumanoidStateType.Freefall, direction * speed + Vector3.new(0, up, 0))

	-- The floor is still reported for a frame or two after take-off. Only
	-- look for the landing once we have actually left the ground.
	ctx.diveLeftGround = false
end

function Dive.update(ctx, _dt: number): string?
	if ctx.airTime > 0 then
		ctx.diveLeftGround = true
	elseif ctx.diveLeftGround or ctx.stateTime > 0.3 then
		-- Landed (or never got off the ground, for example under a low roof).
		return "Prone"
	end
	return nil
end

return Dive
