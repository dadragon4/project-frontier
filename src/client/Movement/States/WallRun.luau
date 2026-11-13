-- Wall-run: running along a wall beside you, started from the air.
--
-- The Humanoid goes into its "Physics" state and the body is moved each
-- frame: along the wall, with a small upward kick that curves down, and a
-- slight push into the wall.
--   Space    wall jump (can carry you onto the opposite wall: a fresh run)
--   Crouch   drop off
-- No time limit: it ends when the feet reach a floor, the wall ends or
-- speed runs out. A run started in FLOW curves down more slowly.
-- The same wall cannot be run twice in a row before landing.

local Workspace = game:GetService("Workspace")

local WallRun = {
	flowAction = "WallRun", -- counts toward a FLOW chain
	staminaDrain = "WallRunDrain", -- costs stamina for as long as it lasts
	drainUsesMomentum = true, -- arriving fast makes the drain cheaper
	controlsBody = true,
	blocksJump = true,
}

local function planar(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

function WallRun.enter(ctx)
	local config = ctx.config.WallRun
	local hit = ctx.pendingWall
	ctx.pendingWall = nil
	ctx.crouched = false

	local normal = planar(hit.Normal).Unit
	local along = ctx.velocity - normal * ctx.velocity:Dot(normal)
	local direction = if along.Magnitude > 0.01 then along.Unit else ctx.forward

	ctx.wallRun = {
		normal = normal,
		direction = direction,
		speed = math.clamp(ctx:getSpeed(), config.MinSpeed, config.MaxSpeed),
		verticalSpeed = config.UpKick,
		-- Decided at the start: a run started in FLOW lasts longer.
		gravity = if ctx.flow:inFlow() then config.FlowGravity else config.Gravity,
		startedAt = os.clock(),
	}
	ctx.wallJumped = false
	ctx.wallNormal = normal
	ctx.humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	ctx.humanoid.AutoRotate = false
end

function WallRun.exit(ctx)
	local run = ctx.wallRun
	ctx.wallRun = nil
	ctx.wallNormal = nil
	ctx.lastWallNormal = run.normal
	ctx.humanoid.AutoRotate = true
	ctx:releaseBody(Enum.HumanoidStateType.Freefall, run.exitVelocity or (run.direction * run.speed))
end

function WallRun.update(ctx, dt: number): string?
	local config = ctx.config.WallRun
	local run = ctx.wallRun
	local root = ctx.root
	local input = ctx.input

	if input.pressedSince("Jump", run.startedAt + 0.05) then
		input.consume("Jump")
		-- A wall jump is a FLOW move of its own.
		ctx:flowInstant("WallJump")
		ctx.wallJumped = true -- lets the Air state catch the opposite wall
		local up = math.sqrt(2 * Workspace.Gravity * config.WallJumpHeight)
		local horizontal = run.normal * config.WallJumpOut + run.direction * run.speed * config.WallJumpKeep
		run.exitVelocity = horizontal + Vector3.new(0, up, 0)
		return "Air"
	end

	if input.pressedSince("Crouch", run.startedAt) then
		input.consume("Crouch")
		run.exitVelocity = run.direction * run.speed + run.normal * 2
		return "Air"
	end

	-- Still a wall beside us?
	local wall = Workspace:Raycast(root.Position, -run.normal * config.StickDistance, ctx.rayParams)
	if not wall or wall.Normal:Dot(run.normal) < 0.8 then
		run.exitVelocity = run.direction * run.speed + Vector3.new(0, run.verticalSpeed, 0)
		return "Air"
	end

	-- Reached a floor or out of speed? (Not stamina: a started run always finishes.)
	local floor = Workspace:Raycast(root.Position, Vector3.new(0, -(ctx:getStandingRootHeight() + 0.3), 0), ctx.rayParams)
	if
		floor
		or run.speed < config.MinSpeed * 0.5
	then
		run.exitVelocity = run.direction * run.speed + Vector3.new(0, run.verticalSpeed, 0)
		return "Air"
	end

	run.verticalSpeed -= run.gravity * dt
	run.speed = math.max(run.speed - config.Friction * dt, 0)

	root.AssemblyLinearVelocity = run.direction * run.speed
		+ Vector3.new(0, run.verticalSpeed, 0)
		- run.normal * config.StickForce
	root.CFrame = CFrame.lookAt(root.Position, root.Position + run.direction)
	ctx.velocity = run.direction * run.speed
	return nil
end

return WallRun
