-- Hanging from a ledge that is too tall to mantle.
--
--   Space            pull up (a mantle from the hang), if there is room on top
--   Crouch           let go
--   left / right     shimmy along the ledge, as long as it continues
--
-- Hanging drains stamina, and running out makes the player let go (user
-- rulings 2026-11-11). An exhausted player cannot grab a ledge at all
-- (MovementController:_checkClamber), or they would grab and drop at once.

local LedgeHang = {
	staminaDrain = "LedgeHangDrain", -- holding on costs stamina for as long as it lasts
	controlsBody = true,
	blocksJump = true,
}

local function hold(ctx)
	local hang = ctx.hang
	local root = ctx.root
	root.CFrame = CFrame.lookAt(hang.position, hang.position + hang.inward)
	root.AssemblyLinearVelocity = Vector3.zero
end

function LedgeHang.enter(ctx)
	local obstacle = ctx.pendingObstacle
	ctx.pendingObstacle = nil
	ctx.crouched = false
	ctx.velocity = Vector3.zero

	ctx.hang = {
		top = obstacle.top,
		inward = obstacle.inward,
		position = obstacle.hangPosition,
		startedAt = os.clock(),
	}
	ctx.humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	ctx.humanoid.AutoRotate = false
	hold(ctx)
end

function LedgeHang.exit(ctx)
	ctx.hang = nil
	ctx.humanoid.AutoRotate = true
	ctx.lastClamberEnd = os.clock()
	ctx:releaseBody(Enum.HumanoidStateType.Freefall, Vector3.zero)
end

function LedgeHang.update(ctx, dt: number): string?
	local config = ctx.config.LedgeGrab
	local hang = ctx.hang
	local input = ctx.input

	-- Only presses made after grabbing count (not the Space that grabbed).
	if input.pressedSince("Jump", hang.startedAt + 0.05) then
		input.consume("Jump")
		if ctx:roomToStand(hang.top + hang.inward * 1.0) then
			ctx.pendingObstacle = { kind = "Mantle", top = hang.top, inward = hang.inward }
			return "Mantle"
		end
	end

	if input.pressedSince("Crouch", hang.startedAt) then
		input.consume("Crouch")
		return "Air"
	end

	-- Out of stamina: the grip gives way. Checked after the keys, so a
	-- pull-up pressed at the last moment still happens.
	if ctx.stamina.current <= 0 then
		return "Air"
	end

	-- Shimmy: move sideways only if the ledge carries on there.
	local right = hang.inward:Cross(Vector3.yAxis)
	local side = ctx.wishDir:Dot(right)
	if math.abs(side) > 0.5 then
		local step = right * math.sign(side) * config.ShimmySpeed * dt
		local position, top = ctx:ledgeAt(hang.top + step, hang.inward, hang.top.Y)
		if position and not ctx:isBlocked(CFrame.new(position), Vector3.new(1.6, 2.5, 0.6)) then
			hang.position = position
			hang.top = top
		end
	end

	hold(ctx)
	return nil
end

return LedgeHang
