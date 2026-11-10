-- Wall-run: running along a wall beside you, entered from the air.
--
-- The Humanoid is put in its "Physics" state and the body's velocity is
-- set every frame: along the wall, with a small upward kick at the start
-- that curves down over the run, and a small push into the wall to stay on
-- it.
--
--   Space    wall jump: push off away from the wall, keeping most of the speed
--   Crouch   drop off the wall
-- The run also ends when the wall ends, the feet reach a floor, speed runs
-- out, or after WallRun.MaxDuration. The same wall cannot be run again
-- until the player lands (MovementController.lastWallNormal).

local Workspace = game:GetService("Workspace")

local WallRun = {
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
		startedAt = os.clock(),
	}
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

	-- Reached a floor, or ran out of time or speed?
	local floor = Workspace:Raycast(root.Position, Vector3.new(0, -(ctx:getStandingRootHeight() + 0.3), 0), ctx.rayParams)
	if floor or ctx.stateTime >= config.MaxDuration or run.speed < config.MinSpeed * 0.5 then
		run.exitVelocity = run.direction * run.speed + Vector3.new(0, run.verticalSpeed, 0)
		return "Air"
	end

	run.verticalSpeed -= config.Gravity * dt
	run.speed = math.max(run.speed - config.Friction * dt, 0)

	root.AssemblyLinearVelocity = run.direction * run.speed
		+ Vector3.new(0, run.verticalSpeed, 0)
		- run.normal * config.StickForce
	root.CFrame = CFrame.lookAt(root.Position, root.Position + run.direction)
	ctx.velocity = run.direction * run.speed
	return nil
end

return WallRun
