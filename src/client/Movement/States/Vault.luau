-- Vault: going over a low, thin obstacle in one movement, keeping speed.
--
-- Like Mantle, the Humanoid is put in its "Physics" state and the body is
-- moved directly, here along a smooth arc (a quadratic curve) from where
-- the vault starts, over the obstacle, to the landing spot. Then the body
-- is released into the air with the vault's speed and the Air state handles
-- the landing.

local Vault = {
	controlsBody = true,
	blocksJump = true,
}

local function planar(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Point on a quadratic curve from a to c, pulled toward b, at u (0 to 1).
local function curve(a: Vector3, b: Vector3, c: Vector3, u: number): Vector3
	local v = 1 - u
	return a * (v * v) + b * (2 * v * u) + c * (u * u)
end

function Vault.enter(ctx)
	local config = ctx.config.Vault
	local obstacle = ctx.pendingObstacle
	ctx.pendingObstacle = nil
	ctx.crouched = false

	local root = ctx.root
	local start = root.Position
	local landing = obstacle.landing
	local finish = Vector3.new(landing.X, landing.Y + ctx:getStandingRootHeight() + 0.1, landing.Z)

	-- Choose the curve's middle control point so the body centre is at
	-- top + RootClearance halfway through.
	local clearY = obstacle.top.Y + config.RootClearance
	local middle = (start + finish) / 2
	local controlY = (clearY - 0.25 * (start.Y + finish.Y)) / 0.5

	local speed = math.clamp(ctx:getSpeed(), config.MinSpeed, config.MaxSpeed)
	local distance = planar(finish - start).Magnitude

	ctx.vault = {
		start = start,
		control = Vector3.new(middle.X, controlY, middle.Z),
		finish = finish,
		duration = math.max(distance / speed, config.MinDuration),
		exitVelocity = obstacle.inward * speed * config.SpeedKeep,
		rotation = root.CFrame.Rotation,
	}

	ctx.velocity = Vector3.zero
	ctx.humanoid:ChangeState(Enum.HumanoidStateType.Physics)
end

function Vault.exit(ctx)
	local vault = ctx.vault
	ctx.vault = nil
	ctx.cameraPitch = 0
	ctx.lastClamberEnd = os.clock()
	ctx:releaseBody(Enum.HumanoidStateType.Freefall, vault.exitVelocity)
end

function Vault.update(ctx, _dt: number): string?
	local config = ctx.config.Vault
	local vault = ctx.vault
	local u = math.min(ctx.stateTime / vault.duration, 1)

	local root = ctx.root
	root.CFrame = CFrame.new(curve(vault.start, vault.control, vault.finish, u)) * vault.rotation
	root.AssemblyLinearVelocity = Vector3.zero
	ctx.cameraPitch = -math.rad(config.CameraDip) * math.sin(math.pi * u)

	if u >= 1 then
		return "Air"
	end
	return nil
end

return Vault
