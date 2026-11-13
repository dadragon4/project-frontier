-- Scripted movement checks, run on the greybox test course.
-- Development tool only; switched by DevConfig.MovementTests.
--
-- Why: checking movement by hand (or by an AI agent pressing simulated keys
-- one at a time) is slow. This plays through every ability by itself in
-- about a minute and a half and reports one PASS / FAIL line per check.
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
--
-- Stamina and FLOW are checked twice over: first on the numbers alone (the
-- Stamina and FlowChain modules, given made-up values, no character), then
-- on the course with the real character.
-- Positions below are test-course coordinates (see TestCourse.server.luau).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ConfigFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Config = require(ConfigFolder:WaitForChild("MovementConfig"))
local DevConfig = require(ConfigFolder:WaitForChild("DevConfig"))
local Stamina = require(ReplicatedStorage.Shared:WaitForChild("Stamina"))
local FlowChain = require(ReplicatedStorage.Shared:WaitForChild("FlowChain"))
local Settings = require(script.Parent.Parent:WaitForChild("Settings"))

local TRIGGER = "RunMovementTests"
local REPORT = "MovementTestReport"

local ORIGIN: Vector3 = DevConfig.TestCourse.Origin
local NORTH = Vector3.new(0, 0, -1) -- down the course, away from the spawn
local SOUTH = -NORTH
local EAST = Vector3.new(1, 0, 0)
local ACTIONS = { "Sprint", "Crouch", "Jump", "Roll" }

local MovementTests = {}

-- `mode` is "quick" for the short suite, anything else for the full one.
local function run(input, c, mode: string): string
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
	local function courseZ(): number
		return c.root.Position.Z - ORIGIN.Z
	end

	-- Change a config number for the current test only (for example,
	-- switch regeneration off so that only an action's cost moves the
	-- stamina number). Every change is undone before the next test.
	local tuned = {}
	local function tune(group, key: string, value)
		table.insert(tuned, { group = group, key = key, value = group[key] })
		group[key] = value
	end
	local function untune()
		for index = #tuned, 1, -1 do
			local change = tuned[index]
			change.group[change.key] = change.value
		end
		table.clear(tuned)
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
		c.jumpCount = 0 -- nor jump fatigue
		c._jumpFatigueUntil = -math.huge
		-- Nor may the previous test's stamina use or FLOW chain carry over.
		c.stamina:refill()
		c.flow:reset()
		c.lastSlideEnd = -math.huge -- no slide cooldown left over either
		c.lastFlowReward = 0
		c.lastMomentumDiscount = 0
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
			-- Sprint still held: the slide ends by itself, back into a sprint.
			check("slide ends in a sprint", sawState("Sprint", 3), now())

			release("Sprint")
			sawState("Walk", 1)
			tap("Crouch")
			sawState("Crouch", 0.5)
			task.wait(1)
			check(
				"crouch stays without the key, at crouch speed and height",
				near(c:getActualSpeed(), Config.CrouchSpeed, 1) and c._appliedDrop >= Config.Crouch.Drop - 0.05,
				now()
			)
			hold("Sprint")
			check("sprint key stands up from a crouch", sawState("Sprint", 0.5), now())
		end,

		function() -- Toggle sprint mode: the key switches sprinting on and off
			Settings.set("SprintMode", "Toggle")
			place(0, 120)
			move(NORTH)
			tap("Sprint") -- a tap, not a hold: the key is already let go
			local started = sawState("Sprint", 1)
			task.wait(1)
			check(
				"a tap of the sprint key sprints on without holding it",
				started and c.stateName == "Sprint" and near(c:getActualSpeed(), Config.SprintSpeed, 1),
				now()
			)

			tap("Sprint")
			check("a second tap ends the sprint", sawState("Walk", 1), now())
		end,

		function() -- Toggle sprint mode: stopping clears the switch
			Settings.set("SprintMode", "Toggle")
			place(0, 120)
			move(NORTH)
			tap("Sprint")
			sawState("Sprint", 1)
			move(Vector3.zero) -- let go of the direction
			task.wait(0.5)
			move(NORTH) -- and set off again
			task.wait(0.8)
			check(
				"stopping clears the sprint switch",
				not c.sprintOn and c.stateName == "Walk",
				string.format("%s, switch %s", now(), tostring(c.sprintOn))
			)
		end,

		function() -- Toggle sprint mode: the switch survives a slide
			Settings.set("SprintMode", "Toggle")
			place(0, 120)
			move(NORTH)
			tap("Sprint")
			sawState("Sprint", 1)
			task.wait(1.2) -- let the sprint build up, or it is too slow to slide
			tap("Crouch") -- slides, and ends back in a sprint with the switch still on
			local slid = sawState("Slide", 0.5)
			check(
				"with the sprint switch on, a slide ends in a sprint",
				slid and sawState("Sprint", 3) and c.sprintOn,
				string.format("%s, switch %s", now(), tostring(c.sprintOn))
			)
		end,

		function() -- Toggle sprint mode: running out of stamina clears the switch
			Settings.set("SprintMode", "Toggle")
			tune(Config.Stamina, "RegenRate", 0) -- stay exhausted, so the check is not a race
			place(0, 120)
			move(NORTH)
			tap("Sprint")
			sawState("Sprint", 1)
			c.stamina:set(0)
			task.wait(0.5)
			check(
				"running out of stamina clears the sprint switch",
				not c.sprintOn and c.stateName ~= "Sprint",
				string.format("%s, switch %s", now(), tostring(c.sprintOn))
			)
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
			task.wait(0.7)
			-- No friction on the slope, so it sits at the slope's speed cap.
			local cap = Config.Slide.SlopeMaxSpeed
			check(
				"slide holds the slope speed cap down a slope",
				slid and c.stateName == "Slide" and near(c:getSpeed(), cap, 0.5),
				string.format("%s at %.1f (cap %d)", c.stateName, c:getSpeed(), cap)
			)
			local ended = waitFor(function()
				return c.stateName ~= "Slide"
			end, 4)
			check("slope slide carries on until the flat", ended and heightAboveCourse() < 1, now())
		end,

		function() -- a slope slide started in FLOW has the higher cap
			place(45, 20, 13.3)
			c.flow.count = Config.Flow.MinActions -- as if a chain had just been completed
			c.flow.lastEndedAt = os.clock()
			move(SOUTH)
			hold("Sprint")
			task.wait(0.6)
			tap("Crouch")
			local slid = sawState("Slide", 0.3)
			release("Sprint")
			task.wait(0.7)
			local cap = Config.Slide.FlowSlopeMaxSpeed
			check(
				"a slope slide started in FLOW has the higher cap",
				slid and c.stateName == "Slide" and near(c:getSpeed(), cap, 0.5),
				string.format("%s at %.1f (cap %d)", c.stateName, c:getSpeed(), cap)
			)
			waitFor(function()
				return c.stateName ~= "Slide"
			end, 4)
		end,

		function() -- a flat slide never travels further than Slide.MaxFlatDistance
			tune(Config.Slide, "Friction", 0) -- without the limit this slide would never end
			place(0, 120)
			move(NORTH)
			hold("Sprint")
			task.wait(1.2)
			tap("Crouch")
			local slid = sawState("Slide", 0.3)
			local startZ = courseZ()
			release("Sprint")
			local ended = waitFor(function()
				return c.stateName ~= "Slide"
			end, 3)
			local travelled = startZ - courseZ()
			local limit = Config.Slide.MaxFlatDistance
			check(
				"a flat slide stops within the distance limit",
				slid and ended and travelled > limit - 4 and travelled < limit + 2,
				string.format("%.1f studs (limit %d)", travelled, limit)
			)
		end,

		function() -- in FLOW: faster sprint, wider view; both end with the chain
			tune(Config.Stamina, "SprintDrain", 0)
			local camera = workspace.CurrentCamera
			place(0, 120)
			move(NORTH)
			hold("Sprint")
			task.wait(1.5)
			local normalSpeed, normalFov = c:getSpeed(), camera.FieldOfView
			c.flow.count = Config.Flow.MinActions
			c.flow.lastEndedAt = os.clock()
			task.wait(1.5)
			local flowSpeed, flowFov = c:getSpeed(), camera.FieldOfView
			check(
				"in FLOW the sprint is faster and the view wider",
				near(flowSpeed, normalSpeed + Config.Flow.SprintSpeedAdd, 0.5) and flowFov > normalFov + 2,
				string.format("speed %.1f -> %.1f, FOV %.1f -> %.1f", normalSpeed, flowSpeed, normalFov, flowFov)
			)
			-- Sprinting is not a FLOW action, so the chain runs out.
			waitFor(function()
				return not c.flow:inFlow()
			end, Config.Flow.Window + 1)
			task.wait(1.2)
			check(
				"the FLOW speed goes when the chain ends",
				not c.flow:inFlow() and near(c:getSpeed(), Config.SprintSpeed, 0.5),
				string.format("%.1f", c:getSpeed())
			)
			release("Sprint")
		end,

		function() -- hotfixes 2026-11-12: slide direction and length, wall-run needs a sprint, look-down limit, sprint sway
			local camera = workspace.CurrentCamera

			-- Sliding backwards is not possible.
			place(0, 120)
			c.forwardOverride = NORTH
			move(SOUTH)
			hold("Sprint")
			task.wait(1.2)
			tap("Crouch")
			-- (It crouches instead, and the held sprint key then stands back up.)
			check("no slide while sprinting backwards", not sawState("Slide", 0.4), now())
			release("Sprint")

			-- No diagonal slide either.
			place(0, 120)
			c.forwardOverride = NORTH
			move((NORTH + EAST).Unit)
			hold("Sprint")
			task.wait(1.2)
			tap("Crouch")
			check("no slide on a forward diagonal", not sawState("Slide", 0.4), now())
			release("Sprint")
			c.forwardOverride = nil

			-- A normal flat slide is about 15 studs.
			place(0, 120)
			move(NORTH)
			hold("Sprint")
			task.wait(1.2)
			tap("Crouch")
			local slid = sawState("Slide", 0.3)
			local startZ = courseZ()
			release("Sprint")
			waitFor(function()
				return c.stateName ~= "Slide"
			end, 3)
			local travelled = startZ - courseZ()
			check("a normal flat slide travels about 15 studs", slid and near(travelled, 15, 2), string.format("%.1f studs", travelled))

			-- A sprint sways the view left and right.
			place(0, 120)
			move(NORTH)
			hold("Sprint")
			task.wait(1)
			local most = 0
			local untilTime = os.clock() + 1
			while os.clock() < untilTime do
				local _, _, roll = camera.CFrame:ToOrientation()
				most = math.max(most, math.abs(math.deg(roll)))
				RunService.RenderStepped:Wait()
			end
			check(
				"sprinting forward tilts the view left and right",
				most > Config.CameraFeel.SprintSwayTilt * 0.5,
				string.format("up to %.2f degrees", most)
			)
			release("Sprint")
			move(Vector3.zero)

			-- The view cannot go further down than MaxLookDown.
			task.wait(0.5)
			local position = camera.CFrame.Position
			camera.CFrame = CFrame.lookAt(position, position + Vector3.new(0, -1, -0.1)) -- nearly straight down
			task.wait(0.3)
			local down = -math.deg(math.asin(camera.CFrame.LookVector.Y))
			check(
				"the view cannot look further down than the limit",
				near(down, Config.Camera.MaxLookDown, 1.5),
				string.format("%.1f degrees down (limit %d)", down, Config.Camera.MaxLookDown)
			)
			camera.CFrame = CFrame.lookAt(position, position + NORTH)

			-- Walking (at the wall-run's minimum speed) and jumping beside a wall does not wall-run.
			place(-48.6, -62)
			move(NORTH)
			waitFor(function()
				return courseZ() <= -74
			end, 3)
			tap("Jump")
			check("no wall-run without a sprint first", not sawState("WallRun", 1), now())
		end,

		function() -- hotfixes 2026-11-12 (second set): how a slide ends; wall to wall; FLOW wall-run
			-- Crouch pressed during the slide: it ends in a crouch.
			place(0, 120)
			move(NORTH)
			hold("Sprint")
			task.wait(1.2)
			tap("Crouch")
			local slid = sawState("Slide", 0.3)
			task.wait(Config.Slide.MinTime + 0.05)
			release("Sprint")
			tap("Crouch")
			check("crouch pressed during a slide ends it in a crouch", slid and sawState("Crouch", 0.5), now())

			-- Out of stamina: the slide ends in a walk, even with sprint held.
			tune(Config.Stamina, "RegenRate", 0)
			place(0, 120)
			move(NORTH)
			hold("Sprint")
			task.wait(1.2)
			c.stamina:set(2) -- the slide's cost takes the last of it
			tap("Crouch")
			slid = sawState("Slide", 0.3)
			check("out of stamina, a slide ends in a walk", slid and sawState("Walk", 3), now())
			release("Sprint")
			untune()

			-- A wall jump carries you to the opposite wall, which starts a fresh run.
			place(-48.6, -62)
			move(NORTH)
			hold("Sprint")
			waitFor(function()
				return courseZ() <= -74
			end, 3)
			tap("Jump")
			local first = sawState("WallRun", 1)
			task.wait(0.3)
			tap("Jump")
			local second = waitFor(function()
				return c.stateName == "WallRun" and c.wallNormal ~= nil and c.wallNormal.X > 0.5
			end, 1.5)
			check(
				"a wall jump onto the opposite wall starts a new wall-run",
				first and second,
				string.format("%s, wall normal x %s", now(), if c.wallNormal then string.format("%.1f", c.wallNormal.X) else "-")
			)
			release("Sprint")

			-- No time limit: a run along the 60 stud wall lasts more than the old 1.3 s.
			place(-48.6, -62)
			move(NORTH)
			hold("Sprint")
			waitFor(function()
				return courseZ() <= -74
			end, 3)
			tap("Jump")
			sawState("WallRun", 1)
			local started = os.clock()
			waitFor(function()
				return c.stateName ~= "WallRun"
			end, 5)
			local normalTime = os.clock() - started
			check("a wall-run lasts until the ground, past the old 1.3 s limit", normalTime > 1.6, string.format("%.2f s", normalTime))
			release("Sprint")

			-- Started in FLOW, it curves down more slowly.
			place(-48.6, -62)
			c.flow.count = Config.Flow.MinActions
			c.flow.lastEndedAt = os.clock()
			move(NORTH)
			hold("Sprint")
			waitFor(function()
				return courseZ() <= -74
			end, 3)
			tap("Jump")
			local ran = sawState("WallRun", 1)
			check(
				"a wall-run started in FLOW uses the flatter curve",
				ran and c.wallRun ~= nil and c.wallRun.gravity == Config.WallRun.FlowGravity,
				now()
			)
			release("Sprint")
		end,

		function() -- pressing sprint while strafing skips the build-up
			place(0, 120)
			c.forwardOverride = NORTH -- looking up the course, moving sideways
			move(EAST)
			task.wait(0.6)
			hold("Sprint")
			local sprinting = sawState("Sprint", 0.5)
			local target = Config.SprintSpeed * Config.StrafeSpeedScale
			check(
				"sprint pressed while strafing is at full strafe speed at once",
				sprinting and near(c:getSpeed(), target, 0.5),
				string.format("%.1f (sprint-strafe speed %.1f)", c:getSpeed(), target)
			)
			release("Sprint")
			-- The body follows the jump in speed (it is not mistaken for a wall).
			hold("Sprint")
			task.wait(0.4)
			check("the body follows the snap", near(c:getActualSpeed(), target, 1.5), string.format("actual %.1f", c:getActualSpeed()))
			release("Sprint")

			place(0, 120)
			move(NORTH)
			task.wait(0.6)
			hold("Sprint")
			sprinting = sawState("Sprint", 0.5)
			check(
				"sprint pressed while walking forward still builds up",
				sprinting and c:getSpeed() < Config.SprintSpeed - 4,
				string.format("%.1f", c:getSpeed())
			)
			release("Sprint")
			c.forwardOverride = nil
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

		function() -- vault over the 3 stud box, the tallest that still vaults
			place(95, 75)
			move(NORTH)
			hold("Sprint")
			local vaulted = sawState("Vault", 3)
			waitFor(function()
				return c.stateName ~= "Vault" and c.airTime == 0
			end, 2)
			local z = c.root.Position.Z - ORIGIN.Z
			check("vault over the 3 stud box", vaulted and z < 63.5, string.format("%s, z %.1f", now(), z))
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

		function() -- stamina rules, on the numbers alone (no character involved)
			-- Its own values, so retuning MovementConfig cannot break these.
			local cfg = { Max = 100, RegenRate = 15, RegenDelay = 1, ExhaustedSpeedScale = 0.7, RecoverAt = 15 }
			local s = Stamina.new(cfg)
			check("stamina starts at its maximum", s.current == 100 and not s.exhausted)

			local taken = s:spend(30)
			local over = s:spend(500)
			check(
				"spending never takes stamina below zero",
				taken == 30 and over == 70 and s.current == 0,
				string.format("took %d then %d, left %d", taken, over, s.current)
			)
			check("zero stamina means exhausted, with the speed multiplier", s.exhausted and s:speedScale() == 0.7)
			s:refund(14)
			local stillExhausted = s.exhausted
			s:refund(1)
			check(
				"exhaustion lasts until the recovery threshold, not just above zero",
				stillExhausted and not s.exhausted and s:speedScale() == 1
			)
			local gained = s:refund(500)
			check("a refund never takes stamina above the maximum", s.current == 100 and gained == 85)

			s:refill()
			s:spend(40)
			s:step(0.5)
			local duringDelay = s.current
			s:step(1.5) -- the other half of the delay, then one second of regeneration
			check(
				"regeneration starts after the delay, at the set rate",
				duringDelay == 60 and near(s.current, 75, 0.001),
				string.format("%.1f during the delay, %.1f after", duringDelay, s.current)
			)

			local oneStep, manySteps = Stamina.new(cfg), Stamina.new(cfg)
			oneStep:spend(60)
			manySteps:spend(60)
			oneStep:step(2)
			for _ = 1, 200 do
				manySteps:step(0.01)
			end
			check(
				"regeneration is the same at any frame rate",
				near(oneStep.current, manySteps.current, 0.01),
				string.format("%.2f in one step, %.2f in 200", oneStep.current, manySteps.current)
			)

			s:refill()
			s:spend(10)
			s:step(0.9)
			s:spend(1)
			s:step(0.9)
			check("spending again restarts the regeneration delay", s.current == 89, string.format("%.1f", s.current))

			-- Momentum.
			local discount, speedThatCounts = Stamina.momentumDiscount, Stamina.qualifyingSpeed
			check("no momentum discount standing still", discount(0, 25, 0.5) == 0)
			check(
				"the discount grows with speed, up to the maximum and no further",
				near(discount(12.5, 25, 0.5), 0.25, 1e-6) and discount(25, 25, 0.5) == 0.5 and discount(80, 25, 0.5) == 0.5
			)
			local diagonal = (NORTH + EAST).Unit * 20
			check(
				"only speed straight ahead counts as momentum",
				near(speedThatCounts(NORTH * 20, NORTH * 20, NORTH), 20, 0.001)
					and speedThatCounts(EAST * 25, EAST * 25, NORTH) == 0
					and speedThatCounts(SOUTH * 25, SOUTH * 25, NORTH) == 0
					and near(speedThatCounts(diagonal, diagonal, NORTH), 14.14, 0.01)
			)
			local falling = NORTH * 10 + Vector3.new(0, -80, 0)
			check("falling speed does not count as momentum", near(speedThatCounts(falling, falling, NORTH), 10, 0.001))
			check(
				"speed into a wall, or from being shoved, does not count",
				speedThatCounts(NORTH * 25, Vector3.zero, NORTH) == 0 and speedThatCounts(Vector3.zero, NORTH * 25, NORTH) == 0
			)
			check(
				"the discount comes off the action's cost",
				Stamina.discountedCost(15, 0) == 15 and Stamina.discountedCost(15, 0.5) == 7.5
			)
		end,

		function() -- FLOW chain rules, on the numbers alone
			local cfg = {
				Window = 2,
				MinActions = 3,
				Reward = 5,
				MaxRewardPerChain = 10,
				MinActionTime = 0.15,
				Actions = { Slide = true, Roll = true, WallRun = true, WallJump = true, Mantle = true, SlideHop = true, Dive = false },
			}
			local t = 0 -- a made-up clock
			-- One whole action: wait `gap`, begin, last `duration`, finish.
			local function act(chain, name: string, duration: number?, gap: number?): number
				t += gap or 0.2
				chain:begin(name, t)
				t += duration or 0.5
				return chain:finish(name, duration or 0.5, t)
			end

			local chain = FlowChain.new(cfg)
			local first, second, third = act(chain, "Slide"), act(chain, "WallRun"), act(chain, "Roll")
			check(
				"slide, wall-run, roll: the third action pays the chain reward",
				first == 0 and second == 0 and third == 5 and chain.count == 3,
				string.format("rewards %d %d %d", first, second, third)
			)

			chain = FlowChain.new(cfg)
			act(chain, "WallRun")
			local wallJump = chain:instant("WallJump", t)
			check(
				"wall-run, wall jump, slide: instant actions count too",
				wallJump == 0 and act(chain, "Slide") == 5 and chain.count == 3
			)

			chain = FlowChain.new(cfg)
			act(chain, "Slide")
			act(chain, "WallRun", 0.5, 1.9)
			local insideWindow = chain.count
			local late = act(chain, "Roll", 0.5, 2.1)
			check(
				"a chain carries on inside the window and starts again after it",
				insideWindow == 2 and late == 0 and chain.count == 1,
				string.format("%d inside the window, %d after it", insideWindow, chain.count)
			)
			check("time left in the window is reported", near(chain:timeLeft(t + 0.5) or -1, 1.5, 0.001))

			chain = FlowChain.new(cfg)
			act(chain, "Slide", 10) -- a ten second slide, far longer than the window
			act(chain, "WallRun")
			check("the window does not run during a long action", chain.count == 2)

			chain = FlowChain.new(cfg)
			local repeats = act(chain, "Slide") + act(chain, "Slide") + act(chain, "Slide") + act(chain, "Slide")
			local afterRepeats = chain.count
			act(chain, "WallRun", 0.5, 1.5)
			check(
				"the same action over and over counts once, but keeps the chain alive",
				repeats == 0 and afterRepeats == 1 and chain.count == 2
			)

			chain = FlowChain.new(cfg)
			act(chain, "Slide")
			act(chain, "WallRun", 0.05) -- dropped at once
			local afterAbort = chain.count
			act(chain, "Dive") -- switched off in this test's Actions
			act(chain, "Walk") -- not an action at all
			check(
				"dropped, switched-off and unknown actions do not count",
				afterAbort == 1 and chain.count == 1 and not chain.inProgress
			)

			chain = FlowChain.new(cfg)
			local total = 0
			for index = 1, 12 do
				total += act(chain, if index % 2 == 1 then "Slide" else "WallRun")
			end
			check(
				"a loop of two moves pays up to the chain's limit, then nothing",
				total == 10 and chain.count == 12,
				string.format("%d stamina from %d actions", total, chain.count)
			)
			local fresh = act(chain, "Roll", 0.5, 2.5) + act(chain, "Slide") + act(chain, "WallRun")
			check("after the chain has ended, a new one can earn again", fresh == 5 and chain.count == 3)
		end,

		function() -- sprint drain, and when stamina comes back
			local s = c.stamina
			local cfg = Config.Stamina

			place(0, 120)
			move(NORTH)
			hold("Sprint")
			sawState("Sprint", 1)
			local before, started = s.current, os.clock()
			local last, rose = before, false
			waitFor(function()
				rose = rose or s.current > last + 1e-6
				last = s.current
				return os.clock() - started >= 1
			end, 2)
			local elapsed = os.clock() - started
			check(
				"sprinting drains stamina at the set rate",
				near(before - s.current, cfg.SprintDrain * elapsed, 1.5),
				string.format("%.1f in %.2f s (expected %.1f)", before - s.current, elapsed, cfg.SprintDrain * elapsed)
			)
			check("no stamina comes back while sprinting", not rose)

			release("Sprint")
			move(Vector3.zero)
			task.wait(0.1)
			local afterSprint = s.current
			task.wait(cfg.RegenDelay * 0.5)
			local duringDelay = s.current
			task.wait(cfg.RegenDelay * 0.5 + 0.6)
			check(
				"stamina comes back after the delay, not before",
				duringDelay <= afterSprint + 1e-6 and s.current > afterSprint + 1,
				string.format("%.1f after sprinting, %.1f during the delay, %.1f later", afterSprint, duringDelay, s.current)
			)
		end,

		function() -- one-time costs and the momentum discount
			local s = c.stamina
			local costs = Config.Stamina.Costs
			local maxDiscount = Config.Stamina.MomentumMaxDiscount
			-- With sprint drain and regeneration off, only an action's own
			-- cost moves the stamina number.
			tune(Config.Stamina, "SprintDrain", 0)
			tune(Config.Stamina, "RegenRate", 0)

			place(0, 120)
			move(NORTH)
			hold("Sprint")
			task.wait(1.5)
			local before = s.current
			tap("Crouch")
			local slid = sawState("Slide", 0.3)
			task.wait(0.3) -- many more frames of sliding: still only the one charge
			release("Sprint")
			check(
				"a slide at full sprint costs stamina once, at the full discount",
				slid and near(before - s.current, costs.Slide * (1 - maxDiscount), 0.75),
				string.format("cost %.2f, discount %.0f%%", before - s.current, c.lastMomentumDiscount * 100)
			)

			place(0, 120)
			move(NORTH)
			hold("Sprint")
			task.wait(1.5)
			before = s.current
			hold("Crouch")
			local dived = sawState("Dive", 0.6)
			release("Crouch")
			release("Sprint")
			check(
				"a dive at full sprint costs stamina once, at the full discount",
				dived and near(before - s.current, costs.Dive * (1 - maxDiscount), 1),
				string.format("cost %.2f, discount %.0f%%", before - s.current, c.lastMomentumDiscount * 100)
			)
			sawState("Prone", 2)

			place(0, 120)
			move(NORTH)
			task.wait(0.8)
			before = s.current
			local walkDiscount = maxDiscount * Config.WalkSpeed / Config.SprintSpeed
			tap("Roll")
			local rolled = sawState("Roll", 0.5)
			check(
				"a roll at walk speed gets a smaller discount",
				rolled and near(before - s.current, costs.Roll * (1 - walkDiscount), 0.75),
				string.format("cost %.2f, discount %.0f%%", before - s.current, c.lastMomentumDiscount * 100)
			)
			sawState("Walk", 2)

			place(0, 120)
			c.forwardOverride = NORTH -- looking up the course, moving sideways
			move(EAST)
			task.wait(0.8)
			before = s.current
			tap("Roll")
			rolled = sawState("Roll", 0.5)
			check(
				"a sideways roll gets no discount",
				rolled and near(before - s.current, costs.Roll, 0.3),
				string.format("cost %.2f, discount %.0f%%", before - s.current, c.lastMomentumDiscount * 100)
			)
			c.forwardOverride = nil
			sawState("Walk", 2)

			-- Actions that do not start: a roll while standing still, and a
			-- crouch tap while only walking (a crouch, not a slide).
			place(0, 120)
			before = s.current
			tap("Roll")
			task.wait(0.4)
			local noRoll = c.stateName ~= "Roll"
			move(NORTH)
			task.wait(0.3)
			tap("Crouch")
			local crouched = sawState("Crouch", 0.5)
			check(
				"a roll or slide that does not start costs nothing",
				noRoll and crouched and s.current == before,
				string.format("%s, stamina %.1f", c.stateName, s.current)
			)
		end,

		function() -- exhaustion
			local s = c.stamina
			local cfg = Config.Stamina
			local scale = cfg.ExhaustedSpeedScale

			-- Resting recovers: the delay, then regeneration up to the threshold.
			place(0, 120)
			s:set(0)
			s:spend(0) -- starts the regeneration delay, as running dry would
			local exhausted = s.exhausted
			task.wait(cfg.RegenDelay + cfg.RecoverAt / cfg.RegenRate + 0.5)
			check(
				"an exhausted player recovers by resting",
				exhausted and not s.exhausted,
				string.format("stamina %.1f", s.current)
			)

			-- Regeneration off from here, so exhaustion lasts while measuring.
			tune(cfg, "RegenRate", 0)
			place(0, 120)
			s:set(0)
			move(NORTH)
			task.wait(1.2)
			check(
				"exhausted walking is slowed",
				s.exhausted and near(c:getActualSpeed(), Config.WalkSpeed * scale, 1),
				now()
			)
			hold("Sprint")
			task.wait(1)
			check(
				"an exhausted player cannot sprint",
				c.stateName == "Walk" and near(c:getActualSpeed(), Config.WalkSpeed * scale, 1),
				now()
			)
			tap("Roll")
			check("an exhausted player cannot roll", not sawState("Roll", 0.4), now())
			release("Sprint")

			-- Running dry in the middle of a sprint: the sprint ends, and even
			-- at that speed neither a slide nor a dive can start.
			place(0, 120)
			move(NORTH)
			hold("Sprint")
			task.wait(1.5)
			s:set(0)
			local blocked = c:getSpeed() >= Config.Dive.MinSpeed and not c:canSlide() and not c:canDive()
			tap("Crouch")
			local slid = sawState("Slide", 0.3)
			check(
				"running dry ends the sprint, and no slide or dive can start",
				blocked and not slid and c.stateName ~= "Sprint",
				now()
			)
			-- Sprint is still held: once recovered, the sprint comes back.
			s:refund(cfg.RecoverAt)
			check("sprint returns once exhaustion is over", sawState("Sprint", 0.5), now())
			release("Sprint")

			place(0, 120)
			s:set(0)
			s:refund(cfg.RecoverAt - 1)
			move(NORTH)
			task.wait(1)
			local slowBelowThreshold = s.exhausted and near(c:getActualSpeed(), Config.WalkSpeed * scale, 1)
			s:refund(1)
			task.wait(0.8)
			check(
				"normal speed returns at the recovery threshold, not before",
				slowBelowThreshold and not s.exhausted and near(c:getActualSpeed(), Config.WalkSpeed, 1),
				now()
			)
		end,

		function() -- manual clamber refund
			local s = c.stamina
			local refund = Config.Stamina.ManualClamberRefund
			tune(Config.Stamina, "SprintDrain", 0)
			tune(Config.Stamina, "RegenRate", 0)
			local function clambering(): boolean
				return c.stateName == "Vault" or c.stateName == "Mantle"
			end

			-- Automatic mode: over the 2 stud box, nothing is given back.
			place(95, 120)
			s:set(50)
			move(NORTH)
			hold("Sprint")
			local vaulted = waitFor(clambering, 3)
			waitFor(function()
				return not clambering() and c.airTime == 0
			end, 2)
			check("an automatic vault gives no stamina back", vaulted and s.current == 50, string.format("stamina %.1f", s.current))

			-- Manual mode, walking into the 3 stud box: nothing happens until
			-- Space is pressed, and the refund comes once.
			Settings.set("ClamberMode", "Manual")
			place(95, 75)
			s:set(50)
			move(NORTH)
			task.wait(1.5)
			check(
				"in manual mode, no key means no clamber and no refund",
				not clambering() and s.current == 50,
				string.format("%s, stamina %.1f", c.stateName, s.current)
			)
			tap("Jump")
			local clambered = waitFor(clambering, 1)
			waitFor(function()
				return not clambering() and c.airTime == 0
			end, 2)
			check(
				"a manual clamber gives the refund, once",
				clambered and near(s.current, 50 + refund, 0.001),
				string.format("stamina %.1f (expected %.1f)", s.current, 50 + refund)
			)
		end,

		function() -- FLOW chain on the course: slide, jump out of it, wall-run, wall jump
			local s = c.stamina
			local flow = Config.Flow
			tune(Config.Stamina, "SprintDrain", 0)
			tune(Config.Stamina, "RegenRate", 0)
			tune(flow, "MinActions", 3)
			tune(Config.Stamina, "WallRunDrain", 0)

			place(-48.6, -62)
			s:set(50)
			move(NORTH)
			hold("Sprint")
			waitFor(function()
				return courseZ() <= -68
			end, 3)
			tap("Crouch")
			local slid = sawState("Slide", 0.3)
			local slideDiscount = c.lastMomentumDiscount
			local slideCost = 50 - s.current
			waitFor(function()
				return courseZ() <= -78
			end, 2)
			tap("Jump") -- out of the slide, beside the wall
			local ran = sawState("WallRun", 1)
			task.wait(0.3)
			tap("Jump") -- wall jump
			waitFor(function()
				return c.stateName ~= "WallRun"
			end, 0.5)
			task.wait(0.1)
			-- Slide (1), jump out of it (2), wall-run (3: pays), wall jump (4).
			check(
				"slide, jump, wall-run, wall jump: a chain of four, paid once",
				slid and ran and c.flow.count == 4 and c.lastFlowReward == flow.Reward and c.flow:inFlow() and c.flow:meter() == 1,
				string.format("%d actions, last reward %d, meter %.0f%%", c.flow.count, c.lastFlowReward, c.flow:meter() * 100)
			)
			check(
				"the momentum discount and the chain reward both apply, separately",
				slideDiscount > 0.3
					and near(slideCost, Config.Stamina.Costs.Slide * (1 - slideDiscount), 0.01)
					and near(s.current, 50 - slideCost + flow.Reward, 0.01),
				string.format("slide cost %.2f at %.0f%% off, stamina %.2f", slideCost, slideDiscount * 100, s.current)
			)

			-- Stop, and let the window run out.
			release("Sprint")
			move(Vector3.zero)
			waitFor(function()
				return c.airTime == 0 and c.stateName == "Walk"
			end, 3)
			task.wait(flow.Window + 0.4)
			check(
				"the chain ends when its window runs out, and FLOW with it",
				c.flow.count == 0 and c.flow:meter() == 0 and not c.flow:inFlow(),
				c.flow.count .. " actions"
			)
		end,

		function() -- FLOW chain on the course: slide, jump, mantle
			local s = c.stamina
			local flow = Config.Flow
			tune(Config.Stamina, "SprintDrain", 0)
			tune(Config.Stamina, "RegenRate", 0)
			tune(flow, "MinActions", 3)

			-- Toward the 4 stud box, whose near face is at z = 21.5.
			place(95, 55)
			s:set(50)
			move(NORTH)
			hold("Sprint")
			waitFor(function()
				return courseZ() <= 46
			end, 3)
			tap("Crouch")
			local slid = sawState("Slide", 0.3)
			waitFor(function()
				return courseZ() <= 31
			end, 2)
			tap("Jump")
			local mantled = sawState("Mantle", 1.5)
			release("Sprint")
			sawState("Walk", 2)
			task.wait(0.1)
			check(
				"slide, jump, mantle: the mantle completes the chain",
				slid and mantled and c.flow.count == 3 and c.lastFlowReward == flow.Reward,
				string.format("%d actions, last reward %d, %.1f up", c.flow.count, c.lastFlowReward, heightAboveCourse())
			)
		end,

		function() -- slide: no roll out of it; sprint cuts it short; a cooldown before the next
			local s = c.stamina
			tune(Config.Stamina, "SprintDrain", 0)
			tune(Config.Stamina, "RegenRate", 0)

			place(0, 120)
			move(NORTH)
			hold("Sprint")
			task.wait(1.5)
			tap("Crouch")
			local slid = sawState("Slide", 0.3)
			local afterSlide = s.current
			tap("Roll")
			task.wait(0.2)
			check(
				"the roll key does nothing during a slide",
				slid and c.stateName == "Slide" and s.current == afterSlide,
				now()
			)

			-- Sprint has been held all along, which must not end the slide.
			-- Letting go and pressing it again must.
			release("Sprint")
			task.wait(0.05)
			hold("Sprint")
			local cut = sawState("Sprint", 0.3)
			check("pressing sprint again cuts a slide into a sprint", cut and not c.crouched, now())

			local fastEnough = c:getSpeed() >= Config.Slide.MinSpeed
			tap("Crouch")
			local tooSoon = sawState("Slide", 0.3)
			check(
				"no new slide during the cooldown, and no stamina charged",
				fastEnough and not tooSoon and s.current == afterSlide,
				string.format("%s, stamina %.1f", now(), s.current)
			)

			task.wait(Config.Slide.Cooldown)
			sawState("Sprint", 0.5)
			tap("Crouch")
			check("a slide starts again once the cooldown is over", sawState("Slide", 0.3), now())
			release("Sprint")
		end,

		function() -- hanging from a ledge drains stamina
			local s = c.stamina
			place(60, -110)
			move(NORTH)
			waitFor(function()
				return courseZ() <= -114.5
			end, 2)
			tap("Jump")
			local hanging = sawState("LedgeHang", 1.5)
			move(Vector3.zero)
			local before, started = s.current, os.clock()
			task.wait(1)
			local elapsed = os.clock() - started
			local expected = Config.Stamina.LedgeHangDrain * elapsed
			check(
				"hanging from a ledge drains stamina at the set rate",
				hanging and c.stateName == "LedgeHang" and near(before - s.current, expected, 1),
				string.format("%.1f in %.2f s (expected %.1f)", before - s.current, elapsed, expected)
			)
			s:set(0)
			check(
				"running out of stamina while hanging lets go",
				waitFor(function()
					return c.stateName ~= "LedgeHang"
				end, 0.5) and s.exhausted,
				now()
			)

			-- Exhausted (and kept that way): the same jump grabs nothing.
			tune(Config.Stamina, "RegenRate", 0)
			place(60, -110)
			s:set(0)
			move(NORTH)
			waitFor(function()
				return courseZ() <= -114.5
			end, 3)
			tap("Jump")
			check("an exhausted player cannot grab a ledge", not sawState("LedgeHang", 1.5), now())
		end,

		function() -- wall-running drains stamina, and needs some
			local s = c.stamina
			tune(Config.Stamina, "SprintDrain", 0)
			tune(Config.Stamina, "RegenRate", 0)
			local function runUp()
				place(-48.6, -62)
				move(NORTH)
				hold("Sprint")
				waitFor(function()
					return courseZ() <= -74
				end, 3)
			end

			runUp()
			tap("Jump")
			local ran = sawState("WallRun", 1)
			local before, started = s.current, os.clock()
			task.wait(0.5)
			local elapsed = os.clock() - started
			local stillRunning = c.stateName == "WallRun"
			-- Arriving at a sprint, momentum takes a share off the drain.
			local expected = Config.Stamina.WallRunDrain * c.drainScale * elapsed
			check(
				"wall-running drains stamina at the set rate, less the momentum discount",
				ran and stillRunning and c.drainScale < 0.9 and near(before - s.current, expected, 1),
				string.format(
					"%.1f in %.2f s (expected %.1f, %.0f%% off)",
					before - s.current,
					elapsed,
					expected,
					(1 - c.drainScale) * 100
				)
			)
			s:set(0)
			task.wait(0.3)
			check("a wall-run that has started finishes even with no stamina", c.stateName == "WallRun", now())

			runUp()
			s:set(0)
			tap("Jump")
			check("an exhausted player cannot wall-run", not sawState("WallRun", 1), now())
			release("Sprint")
		end,
	}

	-- The quick suite (`python3 tools/studio.py quick`): one pass over the
	-- main features, one check each. Every line says what was done (input)
	-- and what happened (output), so a failure can be read without opening
	-- this file.
	local function expect(name: string, given: string, ok: boolean, got: string)
		check(name, ok, `input: {given} | output: {got}`)
	end

	local quickTests = {
		function()
			place(0, 120)
			move(NORTH)
			task.wait(1.5)
			expect("walk", "W for 1.5 s", c.stateName == "Walk" and near(c:getActualSpeed(), Config.WalkSpeed, 1), now() .. ` (want Walk at {Config.WalkSpeed})`)

			hold("Sprint")
			task.wait(1.5)
			expect("sprint", "W + Shift for 1.5 s", c.stateName == "Sprint" and near(c:getActualSpeed(), Config.SprintSpeed, 1), now() .. ` (want Sprint at {Config.SprintSpeed})`)

			tap("Crouch")
			local slid = sawState("Slide", 0.3)
			expect("slide", "tap C while sprinting", slid and c:getSpeed() > Config.SprintSpeed, now() .. ` (want Slide above {Config.SprintSpeed})`)
			expect("slide ends in a sprint", "keep Shift held", sawState("Sprint", 3), now() .. " (want Sprint)")

			release("Sprint")
			sawState("Walk", 1)
			tap("Crouch")
			local crouched = sawState("Crouch", 0.5)
			task.wait(1)
			expect("crouch", "let go of Shift, tap C, keep W", crouched and near(c:getActualSpeed(), Config.CrouchSpeed, 1), now() .. ` (want Crouch at {Config.CrouchSpeed})`)
		end,

		function()
			place(0, 120)
			holdCrouch()
			expect("prone", "hold C, standing", sawState("Prone", 0.5), now() .. " (want Prone)")
		end,

		function()
			place(0, 120)
			move(NORTH)
			hold("Sprint")
			task.wait(1.2)
			hold("Crouch")
			local dived = sawState("Dive", 0.6)
			local prone = sawState("Prone", 2)
			release("Crouch")
			expect("dive", "hold C while sprinting", dived and prone, now() .. " (want Dive, landing Prone)")
		end,

		function()
			place(0, 120)
			local peak = 0
			tap("Jump")
			sawState("Air", 0.5)
			waitFor(function()
				peak = math.max(peak, heightAboveCourse())
				return c.root.AssemblyLinearVelocity.Y < 0 and heightAboveCourse() < 1.5
			end, 2)
			expect("jump", "Space, standing", near(peak, Config.JumpHeight, 0.75), string.format("peak %.2f studs (want %s)", peak, Config.JumpHeight))
		end,

		function()
			place(0, 120)
			move(NORTH)
			task.wait(0.5)
			tap("Roll")
			expect("roll", "Ctrl while walking", sawState("Roll", 0.5), now() .. " (want Roll)")
		end,

		function()
			place(95, 120)
			move(NORTH)
			hold("Sprint")
			local vaulted = sawState("Vault", 3)
			waitFor(function()
				return c.stateName ~= "Vault" and c.airTime == 0
			end, 2)
			expect("vault", "sprint into the 2 stud box", vaulted and courseZ() < 108.5, string.format("%s, z %.1f (want Vault, past z 108.5)", c.stateName, courseZ()))
		end,

		function()
			place(95, 30)
			move(NORTH)
			local mantled = sawState("Mantle", 3)
			sawState("Walk", 2)
			expect("mantle", "walk into the 4 stud box", mantled and near(heightAboveCourse(), 4, 0.5), string.format("%.1f up (want 4)", heightAboveCourse()))
		end,

		function()
			place(60, -110)
			move(NORTH)
			waitFor(function()
				return courseZ() <= -114.5
			end, 2)
			tap("Jump")
			local hung = sawState("LedgeHang", 1.5)
			move(Vector3.zero)
			task.wait(0.2)
			tap("Jump")
			sawState("Mantle", 0.5)
			sawState("Walk", 2)
			expect("ledge grab and pull up", "jump at the 8 stud wall, then Space", hung and near(heightAboveCourse(), 8, 0.5), string.format("hung %s, %.1f up (want 8)", tostring(hung), heightAboveCourse()))
		end,

		function()
			place(-48.6, -62)
			move(NORTH)
			hold("Sprint")
			waitFor(function()
				return courseZ() <= -74
			end, 3)
			tap("Jump")
			expect("wall-run", "sprint beside the wall, Space", sawState("WallRun", 1), now() .. " (want WallRun)")
			task.wait(0.3)
			tap("Jump")
			task.wait(0.15)
			expect("wall jump", "Space during the wall-run", c.stateName == "Air" and c.velocity.X < -5, string.format("%s, x speed %.1f (want Air, below -5)", c.stateName, c.velocity.X))
			release("Sprint")
		end,

		function()
			tune(Config.Stamina, "RegenRate", 0)
			place(0, 120)
			move(NORTH)
			hold("Sprint")
			sawState("Sprint", 1)
			local before, started = c.stamina.current, os.clock()
			task.wait(1)
			local used, want = before - c.stamina.current, Config.Stamina.SprintDrain * (os.clock() - started)
			expect("stamina", "sprint for 1 s", near(used, want, 1.5), string.format("used %.1f (want %.1f)", used, want))
			release("Sprint")
		end,

		function()
			tune(Config.Stamina, "SprintDrain", 0)
			place(0, 120)
			move(NORTH)
			hold("Sprint")
			task.wait(1.5)
			c.flow.count = Config.Flow.MinActions -- as if a chain had just been completed
			c.flow.lastEndedAt = os.clock()
			task.wait(1.5)
			local want = Config.SprintSpeed + Config.Flow.SprintSpeedAdd
			expect("FLOW", "sprint, chain completed", c.flow:inFlow() and near(c:getSpeed(), want, 0.5), string.format("%.1f, in FLOW %s (want %s)", c:getSpeed(), tostring(c.flow:inFlow()), want))
			release("Sprint")
		end,
	}

	local clamberMode = Settings.get("ClamberMode")
	Settings.set("ClamberMode", "Auto")
	-- Every check below holds the sprint key down and lets it go to stop, so
	-- the suite runs in Hold mode. The toggled sprint (the player's default)
	-- has its own checks, which switch the setting themselves.
	local sprintMode = Settings.get("SprintMode")
	Settings.set("SprintMode", "Hold")
	for index, test in (if mode == "quick" then quickTests else tests) do
		local ok, err = pcall(test)
		if not ok then
			check("test " .. index .. " stopped early", false, tostring(err))
		end
		-- Undo anything the test changed for itself, even if it stopped early.
		untune()
		Settings.set("ClamberMode", "Auto")
		Settings.set("SprintMode", "Hold")
	end
	jumpWatch:Disconnect()
	place(0, 140)
	c.wishOverride = nil
	c.forwardOverride = nil
	Settings.set("ClamberMode", clamberMode)
	Settings.set("SprintMode", sprintMode)

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
		-- The trigger's value says which suite: "quick ..." or a number (full).
		local value = player:GetAttribute(TRIGGER)
		local mode = if typeof(value) == "string" and string.sub(value, 1, 5) == "quick" then "quick" else "full"
		local ok, report = pcall(run, input, controller, mode)
		player:SetAttribute(REPORT, if ok then report else "ERROR " .. tostring(report))
		running = false
	end)
end

return MovementTests
