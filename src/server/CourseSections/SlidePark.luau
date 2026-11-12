-- Slide park (x 150..330, z -40..150).
--
-- Three ramps of 10, 20 and 25 degrees beside each other, built like the
-- original 15 degree ramp: start on the deck at the top, sprint, tap crouch
-- and slide down toward the south. Lines on the flat beyond show how far
-- the slide carried, in studs from the foot of the ramp.
--
-- Further east, a wide 12 degree ramp with three walls across it. Each wall
-- has one gap, alternately left, right, left: steering the slide through
-- them makes an S.

local Kit = require(script.Parent.CourseKit)

local SlidePark = {}

local FOOT_Z = 40 -- where the three ramps meet the floor
local RAMP_WIDTH = 20
local RAMP_LENGTH = 60

local STEER_X = 290
local STEER_FOOT_Z = 60
local STEER_DEGREES = 12
local STEER_WIDTH = 40
local STEER_LENGTH = 90
local GAP_WIDTH = 14

function SlidePark.build(course: Folder, origin: Vector3)
	local folder = Kit.folder(course, "SlidePark")

	for index, degrees in { 10, 20, 25 } do
		local x = 165 + (index - 1) * 25
		local ramp, rise, topZ = Kit.ramp(folder, origin, "Ramp" .. degrees, degrees, RAMP_WIDTH, RAMP_LENGTH, x, FOOT_Z)
		Kit.label(ramp, "Ramp: " .. degrees .. " degrees")
		Kit.deck(folder, origin, "Deck" .. degrees, RAMP_WIDTH, 10, x, topZ, rise)
		Kit.resetPost(
			folder,
			origin,
			"Reset" .. degrees,
			x + 12,
			FOOT_Z + 4,
			Kit.standAt(x, topZ - 5, rise, true),
			degrees .. " degree ramp: to the top"
		)
	end

	-- Slide distance lines across all three run-outs, every 5 studs.
	for distance = 5, 110, 5 do
		local text = if distance % 10 == 0 then distance .. " studs" else nil
		Kit.strip(folder, origin, "Runout" .. distance, 70, 0.5, 190, FOOT_Z + distance, text)
	end

	-- Steering ramp.
	local steer, rise, topZ = Kit.ramp(folder, origin, "SteerRamp", STEER_DEGREES, STEER_WIDTH, STEER_LENGTH, STEER_X, STEER_FOOT_Z)
	Kit.label(steer, "Slide steering: 12 degrees, through the gaps")
	Kit.deck(folder, origin, "SteerDeck", STEER_WIDTH, 10, STEER_X, topZ, rise)
	Kit.resetPost(
		folder,
		origin,
		"ResetSteer",
		STEER_X + STEER_WIDTH / 2 + 4,
		STEER_FOOT_Z + 4,
		Kit.standAt(STEER_X, topZ - 5, rise, true),
		"Steering ramp: to the top"
	)

	-- The walls stand on the slope, so they share the ramp's tilt. They are
	-- 12 high because a slide into anything low turns into a vault, which
	-- would let you skip the steering.
	local angle = math.rad(STEER_DEGREES)
	local normal = Vector3.new(0, math.cos(angle), math.sin(angle))
	local half = STEER_WIDTH / 2
	for index, gapCentre in { -9, 9, -9 } do
		local alongFromFoot = STEER_LENGTH - index * 22 -- 68, 46 and 24 studs up from the foot
		local onSurface = Vector3.new(
			STEER_X,
			math.sin(angle) * alongFromFoot,
			STEER_FOOT_Z - math.cos(angle) * alongFromFoot
		)
		local spans = {
			{ -half, gapCentre - GAP_WIDTH / 2 },
			{ gapCentre + GAP_WIDTH / 2, half },
		}
		for side, span in spans do
			local width = span[2] - span[1]
			local centre = onSurface + Vector3.new((span[1] + span[2]) / 2, 0, 0) + normal * 6
			Kit.part(
				folder,
				"SteerWall" .. index .. (if side == 1 then "West" else "East"),
				Vector3.new(width, 12, 1),
				CFrame.new(origin + centre) * CFrame.Angles(angle, 0, 0),
				Kit.LOW_COLOR
			)
		end
	end
end

return SlidePark
