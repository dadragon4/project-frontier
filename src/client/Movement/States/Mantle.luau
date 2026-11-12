-- Mantle: pulling up onto a ledge found by MovementController:findObstacle(),
-- or from a LedgeHang.
--
-- For the duration, the Humanoid is put into its "Physics" state, which
-- stops it walking or applying gravity corrections of its own, and this
-- state moves the body directly along a two-part path:
--   1. straight up until the feet are above the ledge,
--   2. forward onto the ledge.
-- Then the Humanoid is handed back and normal movement resumes.

local Mantle = {
	flowAction = "Mantle", -- counts toward a FLOW chain
	controlsBody = true,
	blocksJump = true,
}

local function easeOut(t: number): number
	t = math.clamp(t, 0, 1)
	return 1 - (1 - t) * (1 - t)
end

function Mantle.enter(ctx)
	local mantle = ctx.config.Mantle
	local ledge = ctx.pendingObstacle
	ctx.pendingObstacle = nil
	ctx.crouched = false

	local root = ctx.root
	local start = root.Position
	-- Root height at which the feet are just above the ledge top.
	local rootAboveFeet = ctx.humanoid.HipHeight + root.Size.Y / 2
	local upY = ledge.top.Y + rootAboveFeet + 0.25
	local landing = ledge.top + ledge.inward * 1.0

	ctx.mantle = {
		start = start,
		up = Vector3.new(start.X, upY, start.Z),
		finish = Vector3.new(landing.X, upY, landing.Z),
		riseTime = math.max((upY - start.Y) / mantle.RiseSpeed, 0.08),
		exitVelocity = ledge.inward * math.min(ctx:getSpeed(), mantle.ExitSpeed),
		rotation = root.CFrame.Rotation,
	}

	ctx.velocity = Vector3.zero
	ctx.humanoid:ChangeState(Enum.HumanoidStateType.Physics)
end

function Mantle.exit(ctx)
	local m = ctx.mantle
	ctx.mantle = nil
	ctx.lastClamberEnd = os.clock()
	ctx.cameraPitch = 0
	ctx.velocity = m.exitVelocity
	-- Treat the character as freshly on the ground, not mid-jump.
	ctx.airTime = 0
	ctx._jumped = false
	ctx.humanoid:ChangeState(Enum.HumanoidStateType.Running)
end

function Mantle.update(ctx, _dt: number): string?
	local mantle = ctx.config.Mantle
	local m = ctx.mantle
	local t = ctx.stateTime

	local position
	if t < m.riseTime then
		position = m.start:Lerp(m.up, easeOut(t / m.riseTime))
	elseif t < m.riseTime + mantle.ForwardTime then
		position = m.up:Lerp(m.finish, easeOut((t - m.riseTime) / mantle.ForwardTime))
	else
		position = m.finish
	end

	local root = ctx.root
	root.CFrame = CFrame.new(position) * m.rotation
	root.AssemblyLinearVelocity = Vector3.zero
	-- A small downward look while pulling up.
	ctx.cameraPitch = -math.rad(mantle.CameraDip) * math.sin(math.pi * math.clamp(t / m.riseTime, 0, 1))

	if t >= m.riseTime + mantle.ForwardTime then
		return if ctx:wantsSprint() then "Sprint" else "Walk"
	end
	return nil
end

return Mantle
