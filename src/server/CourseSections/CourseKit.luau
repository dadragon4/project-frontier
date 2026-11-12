-- Shared building blocks for the extra test-course sections (strafe lane,
-- slide park, FLOW circuit). Every position is an offset from the course
-- origin: x is east, z is south, so "north" (-z) is away from the spawn.
--
-- Markers, gates and reset posts are all walk-through AND invisible to
-- raycasts (CanQuery off). The movement code finds obstacles with raycasts,
-- so this guarantees a marker can never be vaulted, mantled or wall-run.

local Players = game:GetService("Players")

local Kit = {}

Kit.OBSTACLE_COLOR = Color3.fromRGB(70, 130, 200)
Kit.LOW_COLOR = Color3.fromRGB(215, 140, 50)
Kit.MARKER_COLOR = Color3.fromRGB(240, 240, 240)
Kit.GATE_COLOR = Color3.fromRGB(80, 220, 140)
Kit.RESET_COLOR = Color3.fromRGB(230, 80, 80)

function Kit.folder(course: Folder, name: string): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = course
	return folder
end

function Kit.part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- A solid box resting on the floor, centred at (x, z).
function Kit.box(parent: Instance, origin: Vector3, name: string, size: Vector3, x: number, z: number, color: Color3?): Part
	local position = origin + Vector3.new(x, size.Y / 2, z)
	return Kit.part(parent, name, size, CFrame.new(position), color or Kit.OBSTACLE_COLOR)
end

-- Floating text above a part. Returns the TextLabel so timers can rewrite it.
function Kit.label(part: BasePart, text: string, width: number?): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(width or 220, 36)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + 2, 0)
	billboard.MaxDistance = 150
	billboard.Adornee = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.35
	label.BorderSizePixel = 0
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Code
	label.TextSize = 16
	label.Text = text
	label.Parent = billboard

	billboard.Parent = part
	return label
end

local function ghost(part: BasePart)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
end

-- A painted line on the floor, `sizeX` by `sizeZ`, centred at (x, z).
function Kit.strip(parent: Instance, origin: Vector3, name: string, sizeX: number, sizeZ: number, x: number, z: number, text: string?): Part
	local strip = Kit.part(
		parent,
		name,
		Vector3.new(sizeX, 0.1, sizeZ),
		CFrame.new(origin + Vector3.new(x, 0.05, z)),
		Kit.MARKER_COLOR
	)
	ghost(strip)
	if text then
		Kit.label(strip, text, 90)
	end
	return strip
end

-- A see-through curtain you run through. It only notices players (Touched);
-- it does not block or slow anything.
function Kit.gate(parent: Instance, origin: Vector3, name: string, size: Vector3, x: number, z: number, y: number?): Part
	local gate = Kit.part(
		parent,
		name,
		size,
		CFrame.new(origin + Vector3.new(x, (y or 0) + size.Y / 2, z)),
		Kit.GATE_COLOR
	)
	ghost(gate)
	gate.CanTouch = true
	gate.Transparency = 0.8
	gate.Material = Enum.Material.Neon
	return gate
end

-- Calls `callback(player)` when a player's character enters the gate.
-- A character has many body parts and each one fires Touched, so repeats
-- within `quiet` seconds are ignored.
function Kit.onPlayerEnter(gate: BasePart, callback: (Player) -> (), quiet: number?)
	local lastSeen: { [Player]: number } = {}
	gate.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		local now = os.clock()
		if lastSeen[player] and now - lastSeen[player] < (quiet or 0.5) then
			return
		end
		lastSeen[player] = now
		callback(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastSeen[player] = nil
	end)
end

-- A ramp like the original 15 degree one: the low end ("foot") is at
-- z = footZ and it climbs toward the north. Returns the ramp, how high it
-- rises, and the z of its top edge.
function Kit.ramp(parent: Instance, origin: Vector3, name: string, degrees: number, width: number, length: number, x: number, footZ: number): (Part, number, number)
	local angle = math.rad(degrees)
	local rise = math.sin(angle) * length
	local run = math.cos(angle) * length
	-- Middle of the top surface, then half the slab's thickness down along
	-- the surface's normal, so the walking surface starts exactly at the floor.
	local middle = Vector3.new(x, rise / 2, footZ - run / 2)
	local normal = Vector3.new(0, math.cos(angle), math.sin(angle))
	local ramp = Kit.part(
		parent,
		name,
		Vector3.new(width, 1, length),
		CFrame.new(origin + middle - normal * 0.5) * CFrame.Angles(angle, 0, 0),
		Kit.OBSTACLE_COLOR
	)
	return ramp, rise, footZ - run
end

-- A flat start platform at the top of a ramp.
function Kit.deck(parent: Instance, origin: Vector3, name: string, width: number, depth: number, x: number, topZ: number, rise: number): Part
	return Kit.part(
		parent,
		name,
		Vector3.new(width, 1, depth),
		CFrame.new(origin + Vector3.new(x, rise - 0.5, topZ - depth / 2)),
		Kit.OBSTACLE_COLOR
	)
end

-- An optional checkpoint: a thin red post beside a section. Standing near it
-- shows a "Reset" prompt on the E key; pressing it moves you to `target`.
-- Nothing happens unless you press E, and no movement key uses E.
-- (ProximityPrompt is Roblox's built-in "press a key when nearby" object.)
function Kit.resetPost(parent: Instance, origin: Vector3, name: string, x: number, z: number, target: CFrame, text: string): Part
	local post = Kit.box(parent, origin, name, Vector3.new(1, 4, 1), x, z, Kit.RESET_COLOR)
	ghost(post)
	post.Transparency = 0.3

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Reset"
	prompt.ObjectText = text
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = post
	prompt.Triggered:Connect(function(player)
		local character = player.Character
		if character then
			character:PivotTo(CFrame.new(origin) * target)
		end
	end)
	return post
end

-- Where a reset puts you: standing at (x, z), `height` above the floor,
-- facing north or south.
function Kit.standAt(x: number, z: number, height: number, facingSouth: boolean?): CFrame
	local position = Vector3.new(x, height + 4, z)
	return CFrame.lookAt(position, position + Vector3.new(0, 0, if facingSouth then 1 else -1))
end

return Kit
