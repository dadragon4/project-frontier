-- Builds the greybox movement test course when the server starts, and
-- spawns players on it. Development tool only; switched by
-- DevConfig.TestCourse.Enabled.
--
-- The course is built by code rather than by hand so that every obstacle
-- has a known, written-down size, and so it lives in version control.
--
-- Facing the course from the spawn point (looking toward -Z):
--   far left   ledges for mantling            (M1.2)
--   left       crouch tunnel, then slide bar
--   centre     sprint lane with a marker every 20 studs
--   right      15 degree ramp for slope slides
--   far right  vault boxes                    (M1.2)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DevConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("DevConfig"))

if not DevConfig.TestCourse.Enabled then
	return
end

local ORIGIN: Vector3 = DevConfig.TestCourse.Origin -- top surface of the floor, centre

local FLOOR_COLOR = Color3.fromRGB(99, 102, 108)
local MARKER_COLOR = Color3.fromRGB(240, 240, 240)
local OBSTACLE_COLOR = Color3.fromRGB(70, 130, 200)
local LOW_COLOR = Color3.fromRGB(215, 140, 50)

local existing = Workspace:FindFirstChild("TestCourse")
if existing then
	existing:Destroy()
end

local course = Instance.new("Folder")
course.Name = "TestCourse"

local function makePart(name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = course
	return part
end

-- A box resting on the floor: `offset` is its centre on the floor plane.
local function makeBox(name: string, size: Vector3, offset: Vector3, color: Color3): Part
	local position = ORIGIN + Vector3.new(offset.X, size.Y / 2, offset.Z)
	return makePart(name, size, CFrame.new(position), color)
end

local function addLabel(part: BasePart, text: string)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(220, 36)
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
end

-- Floor: 280 wide (X) by 320 long (Z).
makePart("Floor", Vector3.new(280, 2, 320), CFrame.new(ORIGIN - Vector3.new(0, 1, 0)), FLOOR_COLOR)

-- Sprint lane (centre): a strip every 20 studs, starting at the spawn line.
local LANE_START_Z = 130
for distance = 0, 260, 20 do
	local strip = makePart(
		"Marker" .. distance,
		Vector3.new(20, 0.1, 1),
		CFrame.new(ORIGIN + Vector3.new(0, 0.05, LANE_START_Z - distance)),
		MARKER_COLOR
	)
	strip.CanCollide = false
	addLabel(strip, distance .. " studs")
end

-- Crouch tunnel (left): the roof's underside is 4.5 studs above the floor.
-- A standing character does not fit; a crouched one does.
local CLEARANCE = 4.5
local tunnel = makePart(
	"CrouchTunnel",
	Vector3.new(16, 1, 40),
	CFrame.new(ORIGIN + Vector3.new(-45, CLEARANCE + 0.5, 70)),
	LOW_COLOR
)
addLabel(tunnel, "Crouch tunnel: 4.5 clearance")

-- Slide bar (left, further on): same clearance, but only 2 studs deep, with
-- a run-up before it.
local bar = makePart(
	"SlideBar",
	Vector3.new(16, 1, 2),
	CFrame.new(ORIGIN + Vector3.new(-45, CLEARANCE + 0.5, -40)),
	LOW_COLOR
)
addLabel(bar, "Slide bar: 4.5 clearance")

-- Ramp (right): 15 degrees, 60 studs long. Run up it, turn round, slide down.
local RAMP_ANGLE = math.rad(15)
local RAMP_LENGTH = 60
local rampRise = math.sin(RAMP_ANGLE) * RAMP_LENGTH
local ramp = makePart(
	"Ramp15",
	Vector3.new(20, 1, RAMP_LENGTH),
	CFrame.new(ORIGIN + Vector3.new(45, rampRise / 2 - 0.5, 40)) * CFrame.Angles(RAMP_ANGLE, 0, 0),
	OBSTACLE_COLOR
)
addLabel(ramp, "Ramp: 15 degrees")

-- Vault boxes (far right), for M1.2: 3 studs deep, rising heights.
for index, height in { 2, 3, 4, 5 } do
	local box = makeBox(
		"VaultBox" .. height,
		Vector3.new(16, height, 3),
		Vector3.new(95, 0, 110 - (index - 1) * 45),
		OBSTACLE_COLOR
	)
	addLabel(box, "Vault box: " .. height .. " high")
end

-- Ledges (far left), for M1.2: platforms of rising height.
for index, height in { 6, 8, 10 } do
	local ledge = makeBox(
		"Ledge" .. height,
		Vector3.new(16, height, 16),
		Vector3.new(-100, 0, 100 - (index - 1) * 50),
		OBSTACLE_COLOR
	)
	addLabel(ledge, "Ledge: " .. height .. " high")
end

-- Spawn at the start of the sprint lane, facing down it.
local spawn = Instance.new("SpawnLocation")
spawn.Name = "TestCourseSpawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.CFrame = CFrame.new(ORIGIN + Vector3.new(0, 0.5, LANE_START_Z + 10))
spawn.Anchored = true
spawn.Neutral = true
spawn.Transparency = 0.5
spawn.Color = MARKER_COLOR
spawn.Parent = course

course.Parent = Workspace

local function sendToCourse(player: Player)
	player.RespawnLocation = spawn
	-- Anyone who spawned before this script ran is moved over directly.
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
	end
end

Players.PlayerAdded:Connect(sendToCourse)
for _, player in Players:GetPlayers() do
	sendToCourse(player)
end
