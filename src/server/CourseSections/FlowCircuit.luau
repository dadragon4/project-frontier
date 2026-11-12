-- FLOW circuit (x 150..335, z -55..-155): one lap that chains the moves.
--
-- Run it clockwise, starting through the green start/finish gate:
--   leg 1, east:   vault the box, slide under the bar, mantle the block
--   leg 2, north:  wall-run along the wall on your right
--   leg 3, west:   jump and grab the tall block, pull up, run across,
--                  drop off the far end and roll
--   leg 4:         sprint west, then south, back through the gate
--
-- The sign over the gate shows the last and best lap. A lap only counts if
-- you passed every checkpoint gate in order, so cutting a corner shows no
-- time. The wall's label shows how long the last pass along it took.
--
-- Times are taken by the server when your character touches a gate. That is
-- accurate to about a frame or two: fine for comparing runs, not a stopwatch.

local Players = game:GetService("Players")

local Kit = require(script.Parent.CourseKit)

local FlowCircuit = {}

local LEG1_Z = -60
local LEG3_Z = -140

function FlowCircuit.build(course: Folder, origin: Vector3)
	local folder = Kit.folder(course, "FlowCircuit")

	-- Leg 1, heading east.
	local vault = Kit.box(folder, origin, "FlowVaultBox", Vector3.new(3, 2.5, 16), 200, LEG1_Z)
	Kit.label(vault, "FLOW 1: vault (2.5 high)")

	local bar = Kit.part(
		folder,
		"FlowSlideBar",
		Vector3.new(2, 1, 16),
		CFrame.new(origin + Vector3.new(230, 5, LEG1_Z)), -- underside 4.5 above the floor
		Kit.LOW_COLOR
	)
	Kit.label(bar, "FLOW 2: slide under (4.5 clearance)")

	local mantle = Kit.box(folder, origin, "FlowMantleBlock", Vector3.new(16, 5, 16), 262, LEG1_Z)
	Kit.label(mantle, "FLOW 3: mantle (5 high)")

	-- Leg 2, heading north, wall on the right.
	local wall = Kit.box(folder, origin, "FlowWallRunWall", Vector3.new(2, 14, 50), 327, -100)
	local wallLabel = Kit.label(wall, "FLOW 4: wall-run", 260)
	for distance = 0, 50, 5 do
		local text = if distance % 10 == 0 then distance .. " studs" else nil
		Kit.strip(folder, origin, "WallMark" .. distance, 8, 0.5, 321, -75 - distance, text)
	end

	-- Leg 3, heading west. 8 high is too tall to mantle, so it is a ledge
	-- grab; the 8 stud drop off the far end is enough for a roll.
	local ledge = Kit.box(folder, origin, "FlowLedgeBlock", Vector3.new(42, 8, 20), 269, LEG3_Z)
	Kit.label(ledge, "FLOW 5: grab, pull up, drop and roll (8 high)")

	-- Gates, in lap order. Each is a tall curtain across the running line.
	local acrossX = Vector3.new(0.5, 14, 24) -- crossed heading east or west
	local acrossZ = Vector3.new(24, 14, 0.5) -- crossed heading north or south
	local start = Kit.gate(folder, origin, "StartFinish", acrossZ, 165, -70)
	start.Transparency = 0.6
	local sign = Kit.label(start, "FLOW lap: run through to start", 320)
	local checkpoints = {
		Kit.gate(folder, origin, "Checkpoint1", acrossX, 210, LEG1_Z), -- after the vault
		Kit.gate(folder, origin, "Checkpoint2", acrossX, 240, LEG1_Z), -- after the slide bar
		Kit.gate(folder, origin, "Checkpoint3", acrossX, 280, LEG1_Z), -- after the mantle block
		Kit.gate(folder, origin, "WallEntry", acrossZ, 316, -75),
		Kit.gate(folder, origin, "WallExit", acrossZ, 316, -125),
		Kit.gate(folder, origin, "Checkpoint6", acrossX, 240, LEG3_Z), -- after the drop
	}

	-- Per player: when the lap started, which checkpoint comes next, best lap.
	local lapStart: { [Player]: number } = {}
	local nextCheckpoint: { [Player]: number } = {}
	local best: { [Player]: number } = {}
	local wallEntered: { [Player]: number } = {}

	Kit.onPlayerEnter(start, function(player)
		local now = os.clock()
		if lapStart[player] and nextCheckpoint[player] > #checkpoints then
			local lap = now - lapStart[player]
			best[player] = math.min(best[player] or lap, lap)
			sign.Text = string.format("%s: lap %.2f s (best %.2f s)", player.Name, lap, best[player])
		end
		-- Crossing the gate always starts a fresh lap.
		lapStart[player] = now
		nextCheckpoint[player] = 1
	end, 1)

	for index, gate in checkpoints do
		Kit.onPlayerEnter(gate, function(player)
			if nextCheckpoint[player] == index then
				nextCheckpoint[player] = index + 1
			end
			if gate.Name == "WallEntry" then
				wallEntered[player] = os.clock()
			elseif gate.Name == "WallExit" and wallEntered[player] then
				wallLabel.Text = string.format("FLOW 4: wall pass %.2f s (50 studs)", os.clock() - wallEntered[player])
				wallEntered[player] = nil
			end
		end)
	end

	Players.PlayerRemoving:Connect(function(player)
		lapStart[player] = nil
		nextCheckpoint[player] = nil
		best[player] = nil
		wallEntered[player] = nil
	end)

	-- Puts you just north of the gate, facing south through it.
	Kit.resetPost(folder, origin, "Reset", 180, -80, Kit.standAt(165, -82, 0, true), "FLOW circuit: to the start")
end

return FlowCircuit
