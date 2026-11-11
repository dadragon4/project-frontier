-- Scripted movement checks, run on the greybox test course.
-- Development tool only; switched by DevConfig.MovementTests.
--
-- Why: checking movement by hand (or by an AI agent pressing simulated keys
-- one at a time) is slow. This plays through every ability by itself in
-- about 40 seconds and reports one PASS / FAIL line per check.
--
-- How to run: `python3 tools/studio.py test` from the project folder (it
-- starts a play session, runs this and prints the report). Or, while
-- playing, set the attribute "RunMovementTests" on your Player to any new
-- value; the report appears in the attribute "MovementTestReport".
--
-- How it drives the character: it holds actions through Input.setVirtual
-- (the same door on-screen touch buttons will use) and sets the
-- controller's wishOverride for the walk direction. Everything after that
-- is the real movement code.
--
-- It checks that states and speeds are correct. It cannot judge feel.
-- Positions below are test-course coordinates (see TestCourse.server.luau).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ConfigFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Config = require(ConfigFolder:WaitForChild("MovementConfig"))
local DevConfig = require(ConfigFolder:WaitForChild("DevConfig"))
local Settings = require(script.Parent.Parent:WaitForChild("Settings"))

local TRIGGER = "RunMovementTests"
local REPORT = "MovementTestReport"

local ORIGIN: Vector3 = DevConfig.TestCourse.Origin
local NORTH = Vector3.new(0, 0, -1) -- down the course, away from the spawn
local SOUTH = -NORTH
local ACTIONS = { "Sprint", "Crouch", "Jump" }

local MovementTests = {}

local function run(input, c): string
	local lines = {}
	local passed, total = 0, 0

	local function check(name: string, ok: boolean, detail: string?)
		total += 1
		if ok then
			passed += 1
		end
		table.insert(lines, `{if ok then "PASS" else "FAIL"} {name}{if detail then "  (" .. detail .. ")" else ""}`)
	end

	local function waitFor(predicate: () -> boolean, timeout: number): boolean
		local deadline = os.clock() + timeout
		while os.clock() < deadline do
			if predicate() then
				return true
			end
			RunService.RenderStepped:Wait()
		end
		return predicate()
	end

	local function sawState(name: string, timeout: number): boolean
		return waitFor(function()
			return c.stateName == name
		end, timeout)
	end

	local function hold(action: string)
		input.setVirtual(action, true)
	end
	local function release(action: string)
		input.setVirtual(action, false)
	end
	local function tap(action: string)
		hold(action)
		task.wait(0.05)
		release(action)
	end
	local function move(direction: Vector3)
		c.wishOverride = direction
	end
	local function now(): string
		return string.format("%s at %.1f", c.stateName, c:getActualSpeed())
	end
	local function near(value: number, target: number, tolerance: number): boolean
		return math.abs(value - target) <= tolerance
	end
	local function heightAboveCourse(): number
		return c:getFeetY() - ORIGIN.Y
	end

	-- Stand still at (x, z) on the course, `y` studs above its floor.
	local function place(x: number, z: number, y: number?, crouched: boolean?)
		for _, action in ACTIONS do
			release(action)
		end
		move(Vector3.zero)
		if c.stateName == "LedgeHang" then
			tap("Crouch")
		end
		waitFor(function()
			return not c.state.controlsBody
		end, 2)
		if crouched then
			hold("Crouch")
			waitFor(function()
				return c._appliedDrop >= Config.Crouch.Drop - 0.05
			end, 1)
		end
		local rootAboveFeet = c.root.Position.Y - c:getFeetY()
		c.character:PivotTo(CFrame.new(ORIGIN + Vector3.new(x, (y or 0) + rootAboveFeet + 0.1, z)))
		c.root.AssemblyLinearVelocity = Vector3.zero
		c.velocity = Vector3.zero
		-- Long enough that a crouch tap from the previous test cannot pair up
		-- with one in the next test as a double-tap.
		task.wait(0.4)
		waitFor(function()
			return c.airTime == 0 and (c.stateName == "Walk" or c.stateName == "Crouch")
		end, 2)
	end

	local jumps = 0
	local jumpWatch = c.humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping then
			jumps += 1
		end
	end)

	local tests = {
		function() -- walk, sprint, slide, crouch: one run down the sprint lane
			place(0, 120)
			move(NORTH)
			task.wait(1.5)
			check("walk", c.stateName == "Walk" and near(c:getActualSpeed(), Config.WalkSpeed, 1), now())

			hold("Sprint")
			task.wait(1.5)
			check("sprint", c.stateName == "Sprint" and near(c:getActualSpeed(), Config.SprintSpeed, 1), now())

			hold("Crouch")
			local slid = sawState("Slide", 0.3)
			check("slide starts with a boost", slid and c:getSpeed() > Config.SprintSpeed, now())
			check("slide ends in crouch", sawState("Crouch", 3), now())

			release("Sprint")
			task.wait(1)
			check(
				"crouch speed and height",
				near(c:getActualSpeed(), Config.CrouchSpeed, 1) and c._appliedDrop >= Config.Crouch.Drop - 0.05,
				now()
			)
		end,

		function() -- cannot stand up under the crouch tunnel's roof
			place(-45, 86, 0, true)
			release("Crouch")
			task.wait(0.5)
			check("stays crouched under a roof", c.stateName == "Crouch", now())
			move(SOUTH)
			check("stands once clear of the roof", sawState("Walk", 3), now())
		end,

		function() -- jump height, then a jump pressed just before landing
			place(0, 120)
			local peak = 0
			jumps = 0
			tap("Jump")
			sawState("Air", 0.5)
			waitFor(function()
				peak = math.max(peak, heightAboveCourse())
				return c.root.AssemblyLinearVelocity.Y < 0 and heightAboveCourse() < 1.5
			end, 2)
			check("jump height", near(peak, Config.JumpHeight, 0.75), string.format("%.2f studs", peak))
			tap("Jump")
			task.wait(0.6)
			check("buffered jump", jumps == 2, jumps .. " jumps")
		end,

		function() -- coyote jump: pressed just after walking off the 8 stud ledge
			place(-100, 45, 8)
			jumps = 0
			-- The coyote window is only a frame or two long when Studio runs
			-- slowly (it does when its window is in the background), and this
			-- script can only react once per frame. Widen the window to four
			-- frames in that case, so the check still exercises the code.
			local tuned = Config.CoyoteTime
			local window = math.max(tuned, RunService.RenderStepped:Wait() * 4)
			Config.CoyoteTime = window
			move(NORTH)
			waitFor(function()
				return c.airTime > 0
			end, 2)
			tap("Jump")
			task.wait(0.3)
			Config.CoyoteTime = tuned
			check(
				"coyote jump",
				jumps == 1,
				if window > tuned then string.format("window widened to %.2f s for a slow frame rate", window) else nil
			)
		end,

		function() -- jump cooldown: a jump pressed during the cooldown is ignored, one after it works
			place(0, 120)
			local tuned = Config.JumpCooldown
			Config.JumpCooldown = 0.5
			jumps = 0
			tap("Jump")
			sawState("Air", 0.5)
			waitFor(function()
				return not c._jumped
			end, 2)
			tap("Jump") -- straight after landing: should be blocked
			task.wait(0.7) -- past the cooldown; a remembered blocked press would fire by now
			local duringCooldown = jumps - 1
			tap("Jump")
			task.wait(0.3)
			Config.JumpCooldown = tuned
			local afterCooldown = jumps - 1 - duringCooldown
			check(
				"jump cooldown",
				duringCooldown == 0 and afterCooldown == 1,
				string.format("%d jumps during the cooldown, %d after", duringCooldown, afterCooldown)
			)
		end,

		function() -- air roll: crouch pressed during an 8 stud fall
			place(-100, 45, 8)
			move(NORTH)
			sawState("Air", 2)
			tap("Crouch")
			check("air roll after a long fall", sawState("Roll", 2), now())
		end,

		function() -- ground roll: crouch double-tap
			place(0, 120)
			move(NORTH)
			task.wait(0.5)
			tap("Crouch")
			task.wait(0.1)
			tap("Crouch")
			check("ground roll", sawState("Roll", 0.5), now())
		end,

		function() -- vault over the 2 stud box
			place(95, 120)
			move(NORTH)
			hold("Sprint")
			local vaulted = sawState("Vault", 3)
			waitFor(function()
				return c.stateName ~= "Vault" and c.airTime == 0
			end, 2)
			local z = c.root.Position.Z - ORIGIN.Z
			check("vault", vaulted and z < 108.5, string.format("%s, z %.1f", now(), z))
		end,

		function() -- mantle onto the 4 stud box
			place(95, 30)
			move(NORTH)
			local mantled = sawState("Mantle", 3)
			sawState("Walk", 2)
			check("mantle", mantled and near(heightAboveCourse(), 4, 0.5), string.format("%.1f up", heightAboveCourse()))
		end,

		function() -- ledge grab on the 8 stud wall, then pull up
			place(60, -110)
			move(NORTH)
			waitFor(function()
				return c.root.Position.Z - ORIGIN.Z <= -114.5
			end, 2)
			tap("Jump")
			check("ledge grab", sawState("LedgeHang", 1.5), now())
			move(Vector3.zero)
			task.wait(0.2)
			tap("Jump")
			sawState("Mantle", 0.5)
			sawState("Walk", 2)
			check("pull up from a hang", near(heightAboveCourse(), 8, 0.5), string.format("%.1f up", heightAboveCourse()))
		end,

		function() -- wall-run along the wall-run wall, then wall jump
			place(-48.6, -62)
			move(NORTH)
			hold("Sprint")
			waitFor(function()
				return c.root.Position.Z - ORIGIN.Z <= -74
			end, 3)
			tap("Jump")
			check("wall-run", sawState("WallRun", 1), now())
			task.wait(0.3)
			tap("Jump")
			task.wait(0.15)
			-- The wall is on the +X side, so a wall jump pushes toward -X.
			check("wall jump", c.stateName == "Air" and c.velocity.X < -5, string.format("%s, x speed %.1f", c.stateName, c.velocity.X))
		end,
	}

	local clamberMode = Settings.get("ClamberMode")
	Settings.set("ClamberMode", "Auto")
	for index, test in tests do
		local ok, err = pcall(test)
		if not ok then
			check("test " .. index .. " stopped early", false, tostring(err))
		end
	end
	jumpWatch:Disconnect()
	place(0, 140)
	c.wishOverride = nil
	Settings.set("ClamberMode", clamberMode)

	return `{passed}/{total} passed\n{table.concat(lines, "\n")}`
end

-- `getController` returns the current MovementController (or nil).
function MovementTests.start(input, getController: () -> any)
	local player = Players.LocalPlayer
	local running = false
	player:GetAttributeChangedSignal(TRIGGER):Connect(function()
		local controller = getController()
		if running or not controller then
			return
		end
		running = true
		player:SetAttribute(REPORT, nil)
		local ok, report = pcall(run, input, controller)
		player:SetAttribute(REPORT, if ok then report else "ERROR " .. tostring(report))
		running = false
	end)
end

return MovementTests
