-- Finding things in the world for the movement states: obstacles to vault,
-- mantle or hang from, walls to run along, and "is there room here?" checks.
--
-- Everything works by raycasts (an invisible line fired from a point; it
-- reports the first thing it hits) and box overlap checks.
--
-- Every function takes the MovementController as `self`. The controller
-- copies them onto itself, so states call them as ctx:findObstacle() etc.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("MovementConfig"))

local Detection = {}

local function planar(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Is anything solid inside this box?
function Detection.isBlocked(self, cframe: CFrame, size: Vector3): boolean
	return #Workspace:GetPartBoundsInBox(cframe, size, self.overlapParams) > 0
end

-- Is there room to stand with the feet at `point`?
function Detection.roomToStand(self, point: Vector3): boolean
	local height = self:getStandingHeight()
	local center = point + Vector3.new(0, height / 2 + 0.15, 0)
	return not self:isBlocked(CFrame.new(center), Vector3.new(1.6, height, 1.6))
end

-- Find the top of the obstacle whose face was hit at `wallHit`, between
-- heights minTopY and maxTopY. Returns the RaycastResult on the top, or nil.
function Detection._probeTop(self, wallHit: RaycastResult, inward: Vector3, minTopY: number, maxTopY: number)
	local probe = wallHit.Position + inward * 0.6
	local probeTop = Vector3.new(probe.X, maxTopY + 0.05, probe.Z)
	-- If the obstacle is taller than maxTopY, this probe starts inside it. A
	-- ray that starts inside a part does not hit that part, so the check
	-- below catches that case instead.
	if self:isBlocked(CFrame.new(probeTop), Vector3.new(0.2, 0.2, 0.2)) then
		return nil
	end
	local topHit = Workspace:Raycast(probeTop, Vector3.new(0, -(maxTopY - minTopY + 0.1), 0), self.rayParams)
	if not topHit or topHit.Normal.Y < 0.7 then
		return nil
	end
	return topHit
end

-- Plan a vault over an obstacle whose top was found at `top`. Returns the
-- obstacle description, or nil if it cannot be vaulted (too deep, nowhere
-- to land, or no room to pass over).
function Detection._planVault(self, top: Vector3, inward: Vector3, baseY: number)
	local vault = Config.Vault

	-- Walk along the top until it ends, to find the far edge.
	local edgeDistance = nil
	local d = 0.5
	while d <= vault.MaxDepth do
		local onTop = Workspace:Raycast(top + inward * d + Vector3.new(0, 0.3, 0), Vector3.new(0, -0.8, 0), self.rayParams)
		if not onTop then
			edgeDistance = d
			break
		end
		d += 0.5
	end
	if not edgeDistance then
		return nil
	end

	-- A floor to land on behind it, no higher than where we started.
	local landing = top + inward * (edgeDistance + vault.LandingGap)
	local floor = Workspace:Raycast(
		Vector3.new(landing.X, top.Y + 0.3, landing.Z),
		Vector3.new(0, -(top.Y - baseY + 4), 0),
		self.rayParams
	)
	if not floor or floor.Normal.Y < 0.7 or floor.Position.Y > baseY + 1 then
		return nil
	end
	if not self:roomToStand(floor.Position) then
		return nil
	end

	-- Room to pass over the top with the legs tucked.
	local span = top + inward * (edgeDistance / 2) + Vector3.new(0, 1.6, 0)
	if self:isBlocked(CFrame.lookAt(span, span + inward), Vector3.new(1.6, 2.8, edgeDistance)) then
		return nil
	end

	return { kind = "Vault", top = top, inward = inward, landing = floor.Position }
end

-- Where the body hangs from a ledge near horizontal point `point`, for a
-- ledge whose top is about `topY`. Returns (hangPosition, topPosition), or
-- nil if there is no grabbable ledge there.
function Detection.ledgeAt(self, point: Vector3, inward: Vector3, topY: number)
	local ledge = Config.LedgeGrab
	local from = Vector3.new(point.X, topY - 0.5, point.Z) - inward * 2
	local wall = Workspace:Raycast(from, inward * 3, self.rayParams)
	if not wall or math.abs(wall.Normal.Y) > 0.3 or (-wall.Normal):Dot(inward) < 0.8 then
		return nil
	end
	local probe = wall.Position + inward * 0.6
	local topHit = Workspace:Raycast(Vector3.new(probe.X, topY + 0.6, probe.Z), Vector3.new(0, -1.2, 0), self.rayParams)
	if not topHit or topHit.Normal.Y < 0.7 then
		return nil
	end
	local face = Vector3.new(wall.Position.X, topHit.Position.Y, wall.Position.Z)
	local hangPosition = face - inward * ledge.WallGap - Vector3.new(0, ledge.HangDrop, 0)
	return hangPosition, topHit.Position
end

-- Look for something to vault over, mantle onto or hang from, in the
-- direction the player is pushing. Returns nil, or a table whose `kind` is
-- the state to enter ("Vault", "Mantle" or "LedgeHang").
--
-- Steps:
--   1. Is there a wall just ahead (checked at chest, waist and knee height)?
--   2. Find its top, within reach.
--   3. Low and thin with floor behind  -> Vault.
--      Within mantle height            -> Mantle (if there is room on top).
--      Taller, and we are airborne     -> LedgeHang (if there is room to hang).
function Detection.findObstacle(self)
	local wish = self.wishDir
	if wish == Vector3.zero then
		return nil
	end
	local rootPos = self.root.Position

	-- 1. Wall ahead.
	local wallHit
	for _, drop in { 0, 1.5, 2.5 } do
		local hit = Workspace:Raycast(rootPos - Vector3.new(0, drop, 0), wish * Config.Clamber.WallCheckDistance, self.rayParams)
		if hit and math.abs(hit.Normal.Y) < 0.3 then
			wallHit = hit
			break
		end
	end
	if not wallHit then
		return nil
	end
	local inward = planar(-wallHit.Normal)
	if inward.Magnitude < 0.01 then
		return nil
	end
	inward = inward.Unit
	-- Must be pushing roughly into the wall, not brushing past it.
	if inward:Dot(wish) < 0.5 then
		return nil
	end

	-- 2. The top.
	local airborne = not self.grounded
	local baseY = if airborne then self.lastGroundY else self:getFeetY()
	local maxHeight = if airborne then Config.LedgeGrab.MaxHeight else Config.Mantle.MaxHeight
	local minTopY = baseY + Config.Vault.MinHeight
	local maxTopY = math.min(baseY + maxHeight, rootPos.Y + Config.Clamber.Reach)
	if maxTopY <= minTopY then
		return nil
	end
	local topHit = self:_probeTop(wallHit, inward, minTopY, maxTopY)
	if not topHit then
		return nil
	end
	local top = topHit.Position
	local height = top.Y - baseY

	-- 3. Decide.
	if height <= Config.Vault.MaxHeight then
		local vault = self:_planVault(top, inward, baseY)
		if vault then
			return vault
		end
	end
	if height >= Config.Mantle.MinHeight and height <= Config.Mantle.MaxHeight then
		if self:roomToStand(top + inward * 1.0) then
			return { kind = "Mantle", top = top, inward = inward }
		end
		return nil
	end
	if airborne and height > Config.Mantle.MaxHeight then
		local hangPosition, ledgeTop = self:ledgeAt(top, inward, top.Y)
		if hangPosition and not self:isBlocked(CFrame.new(hangPosition), Vector3.new(1.6, 2.5, 0.6)) then
			return { kind = "LedgeHang", top = ledgeTop, inward = inward, hangPosition = hangPosition }
		end
	end
	return nil
end

-- Look for a wall beside the character to run along. Returns the
-- RaycastResult on the wall, or nil.
function Detection.findWallRunWall(self)
	local wallRun = Config.WallRun
	local speed = self:getSpeed()
	if speed < wallRun.MinSpeed then
		return nil
	end
	local along = self.velocity / speed
	if self.wishDir == Vector3.zero or self.wishDir:Dot(along) < 0.3 then
		return nil
	end

	-- High enough above the floor.
	local downDistance = self:getStandingRootHeight() + wallRun.MinHeightAboveFloor
	if Workspace:Raycast(self.root.Position, Vector3.new(0, -downDistance, 0), self.rayParams) then
		return nil
	end

	local right = along:Cross(Vector3.yAxis)
	for _, side in { right, -right } do
		local hit = Workspace:Raycast(self.root.Position, side * wallRun.CheckDistance, self.rayParams)
		if hit and math.abs(hit.Normal.Y) < 0.2 and math.abs(along:Dot(hit.Normal)) < wallRun.MaxApproachDot then
			local sameWall = self.lastWallNormal and hit.Normal:Dot(self.lastWallNormal) > 0.9
			if not sameWall then
				return hit
			end
		end
	end
	return nil
end

return Detection
