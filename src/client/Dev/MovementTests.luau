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
local EAST = Vector3.new(1, 0, 0)
local ACTIONS = { "Sprint", "Crouch", "Jump", "Roll" }

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
	-- Hold crouch long enough to count as a hold (prone / dive), then let go.
	local function holdCrouch()
		hold("Crouch")
		task.wait(Config.CrouchHoldTime + 0.15)
		release("Crouch")
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
		if crouched and c.stateName ~= "Crouch" then
			tap("Crouch")
			waitFor(function()
				return c._appliedDrop >= Config.Crouch.Drop - 0.05
			end, 1)
		end
		local rootAboveFeet = c.root.Position.Y - c:getFeetY()
		c.character:PivotTo(CFrame.new(ORIGIN + Vector3.new(x, (y or 0) + rootAboveFeet + 0.1, z)))
		c.root.AssemblyLinearVelocity = Vector3.zero
		c.velocity = Vector3.zero
		task.wait(0.4) -- let the body settle
		-- Crouch and prone are toggles: stand back up unless asked to crouch.
		if not crouched and (c.stateName == "Crouch" or c.stateName == "Prone") then
			tap("Crouch")
		end
		-- Wait until fully up (or fully crouched): getting up from prone is slow.
		local drop = if crouched then Config.Crouch.Drop else 0
		waitFor(function()
			return c.airTime == 0
				and c.stateName == (if crouched then "Crouch" else "Walk")
				and math.abs(c._appliedDrop - drop) < 0.05
		end, 3)
		-- A jump in the previous test must not leave its cooldown running.
		c._jumpLandedAt = -math.huge
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

			tap("Crouch") -- a tap, not a hold: the slide must carry on by itself
			local slid = sawState("Slide", 0.3)
			check("tap crouch while sprinting slides, with a boost", slid and c:getSpeed() > Config.SprintSpeed, now())
			-- Sprint is let go, or the crouch at the end would stand straight
			-- back up into a sprint.
			release("Sprint")
			check("slide ends in crouch", sawState("Crouch", 3), now())

			task.wait(1)
			check(
				"crouch stays without the key, at crouch speed and height",
				near(c:getActualSpeed(), Config.CrouchSpeed, 1) and c._appliedDrop >= Config.Crouch.Drop - 0.05,
				now()
			)
			hold("Sprint")
			check("sprint key stands up from a crouch", sawState("Sprint", 0.5), now())
		end,

		function() -- a slide down the 15 degree ramp keeps going until the ramp ends
			-- The ramp's high end is at z = 11; at z = 20 its surface is about 13.1 up.
			place(45, 20, 13.3)
			move(SOUTH) -- downhill
			hold("Sprint")
			task.wait(0.6)
			tap("Crouch")
			local slid = sawState("Slide", 0.3)
			release("Sprint")
			local startSpeed = c:getSpeed()
			task.wait(0.7)
			check(
				"slide keeps its speed down a slope",
				slid and c.stateName == "Slide" and c:getSpeed() >= startSpeed,
				string.format("%s, %.1f then %.1f", c.stateName, startSpeed, c:getSpeed())
			)
			check("slope slide ends in crouch on the flat", sawState("Crouch", 4) and heightAboveCourse() < 1, now())
		end,

		function() -- crouch toggle
			place(0, 120)
			tap("Crouch")
			local crouched = sawState("Crouch", 0.5)
			tap("Crouch")
			check("tap crouch toggles crouch", crouched and sawState("Walk", 0.5), now())
		end,

		function() -- cannot stand up under the crouch tunnel's roof, crouched or prone
			place(-45, 86, 0, true)
			tap("Crouch")
			task.wait(0.5)
			check("stays crouched under a roof", c.stateName == "Crouch", now())

			holdCrouch()
			local prone = sawState("Prone", 0.5)
			task.wait(Config.Prone.MinTime + 0.2)
			tap("Crouch")
			task.wait(0.5)
			check("stays prone under a roof", prone and c.stateName == "Prone", now())

			move(SOUTH)
			waitFor(function()
				return c.root.Position.Z - ORIGIN.Z > 92.5
			end, 4)
			tap("Crouch")
			check("stands once clear of the roof", sawState("Walk", 1), now())
		end,

		function() -- slower sideways and backwards; sprint works in any direction
			place(0, 120)
			c.forwardOverride = NORTH -- "looking" up the course while moving other ways
			move(SOUTH)
			task.wait(1.2)
			local back = Config.WalkSpeed * Config.BackSpeedScale
			check("walking backwards is capped", near(c:getActualSpeed(), back, 1), now())
			hold("Sprint")
			task.wait(1.2)
			local backSprint = Config.SprintSpeed * Config.BackSpeedScale
			check("sprint works backwards, slower", c.stateName == "Sprint" and near(c:getActualSpeed(), backSprint, 1), now())
			move(EAST)
			task.wait(1.2)
			local sideSprint = Config.SprintSpeed * Config.StrafeSpeedScale
			check("sprint works sideways, slower", c.stateName == "Sprint" and near(c:getActualSpeed(), sideSprint, 1), now())
			c.forwardOverride = nil
		end,

		function() -- strafing: reversal time, no speed gained from diagonals or direction tricks
			place(0, 120)
			c.forwardOverride = NORTH
			local strafe = Config.WalkSpeed * Config.StrafeSpeedScale

			move(NORTH + EAST)
			task.wait(0.8)
			check("diagonal is no faster than straight ahead", c:getActualSpeed() <= Config.WalkSpeed + 0.3, now())

			-- Counter-strafe: moving right at full strafe speed, push left.
			move(EAST)
			task.wait(0.8)
			local started = os.clock()
			local fastest = 0
			move(-EAST)
			waitFor(function()
				fastest = math.max(fastest, c:getSpeed())
				return c.velocity.X <= -strafe * 0.9
			end, 2)
			local took = os.clock() - started
			-- Time to brake at ReverseDecel, then build 90% of the speed back.
			local expected = strafe / Config.ReverseDecel + strafe * 0.9 / Config.GroundAccel
			check(
				"counter-strafe reverses quickly, with no speed spike",
				took <= expected + 0.15 and fastest <= strafe + 0.3,
				string.format("%.2f s (ideal %.2f), top %.1f", took, expected, fastest)
			)

			-- Cutting sideways out of a forward sprint: the new direction
			-- picks up at the normal rate, so not much speed is lost.
			move(NORTH)
			hold("Sprint")
			task.wait(1.2)
			local lowest = math.huge
			local cutAt = os.clock()
			move(EAST)
			waitFor(function()
				lowest = math.min(lowest, c:getSpeed())
				return c.velocity.X >= Config.SprintSpeed * Config.StrafeSpeedScale * 0.9
			end, 2)
			check(
				"sprint cut to the side keeps most of its speed",
				lowest >= Config.SprintSpeed * 0.7 and os.clock() - cutAt <= 0.4,
				string.format("lowest %.1f, %.2f s", lowest, os.clock() - cutAt)
			)
			release("Sprint")
			task.wait(0.4)

			-- Sprint forward, then "look behind" so the same motion counts as
			-- backpedalling: the forward speed must not be kept.
			move(NORTH)
			hold("Sprint")
			task.wait(1.2)
			c.forwardOverride = SOUTH
			task.wait(0.4)
			local backSprint = Config.SprintSpeed * Config.BackSpeedScale
			check("forward sprint speed is not carried into a backpedal", c:getSpeed() <= backSprint + 0.5, now())
			release("Sprint")

			-- Jumping while backpedalling must not speed you up in the air.
			c.forwardOverride = NORTH
			move(SOUTH)
			task.wait(0.8)
			local back = Config.WalkSpeed * Config.BackSpeedScale
			local airTop = 0
			tap("Jump")
			sawState("Air", 0.5)
			waitFor(function()
				airTop = math.max(airTop, c:getSpeed())
				return c.stateName ~= "Air"
			end, 2)
			check("no speed gained in the air while backpedalling", airTop <= back + 0.5, string.format("top %.1f, cap %.1f", airTop, back))
			c.forwardOverride = nil
		end,

		function() -- prone: hold crouch; crawl; tap to stand
			place(0, 120)
			holdCrouch()
			local prone = sawState("Prone", 0.5)
			waitFor(function()
				return c._appliedDrop >= Config.Prone.Drop - 0.1
			end, 2)
			check("hold crouch goes prone, body lowered", prone, string.format("%s, lowered %.2f", c.stateName, c._appliedDrop))
			move(NORTH)
			task.wait(1)
			check("crawl speed", near(c:getActualSpeed(), Config.Prone.Speed, 0.75), now())
			tap("Crouch")
			check("tap crouch stands up from prone", sawState("Walk", 1), now())
		end,

		function() -- dive: hold crouch while sprinting
			place(0, 120)
			move(NORTH)
			hold("Sprint")
			task.wait(1.2)
			local startY = c.root.Position.Y
			local rise = 0
			hold("Crouch")
			local dived = sawState("Dive", 0.6)
			local landedProne = waitFor(function()
				rise = math.max(rise, c.root.Position.Y - startY)
				return c.stateName == "Prone"
			end, 2)
			release("Crouch")
			check("dive leaves the ground", dived and rise > 1, string.format("rose %.1f studs", rise))
			check("dive lands prone", landedProne, now())
		end,

		function() -- jump height, then a jump pressed just before landing
			place(0, 120)
			-- With a jump cooldown, a jump pressed just before landing is
			-- (correctly) refused, so the cooldown is off for this check.
			local tuned = Config.JumpCooldown
			Config.JumpCooldown = 0
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
			Config.JumpCooldown = tuned
			check("buffered jump (cooldown off)", jumps == 2, jumps .. " jumps")
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

		function() -- air roll: roll pressed during an 8 stud fall
			place(-100, 45, 8)
			move(NORTH)
			sawState("Air", 2)
			tap("Roll")
			check("air roll after a long fall", sawState("Roll", 2), now())
		end,

		function() -- ground roll: roll key while moving, not while standing
			place(0, 120)
			tap("Roll")
			check("no roll while standing still", not sawState("Roll", 0.4), now())
			move(NORTH)
			task.wait(0.5)
			tap("Roll")
			check("ground roll while walking", sawState("Roll", 0.5), now())
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
	c.forwardOverride = nil
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
