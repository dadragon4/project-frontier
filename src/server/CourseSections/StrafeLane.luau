-- Strafe and counter-strafe lane (x 250..330, z 95..150; the slalom runs on to z 70).
--
-- Stand on the centre line facing north (toward the cover block) and strafe
-- left and right. The lines either side are 4, 8, 12 and 16 studs out, so
-- you can read off how far a strafe, a stop or a reversal carries you.
-- The tall block is cover to strafe out from behind; the pylons are a slalom.

local Kit = require(script.Parent.CourseKit)

local StrafeLane = {}

local CENTRE_X = 290

function StrafeLane.build(course: Folder, origin: Vector3)
	local folder = Kit.folder(course, "StrafeLane")

	Kit.strip(folder, origin, "CentreLine", 0.5, 45, CENTRE_X, 122.5, "Strafe lane: centre")
	for _, distance in { 4, 8, 12, 16 } do
		for _, side in { -1, 1 } do
			Kit.strip(folder, origin, "Line" .. distance, 0.3, 45, CENTRE_X + side * distance, 122.5, distance .. " studs")
		end
	end

	-- 12 high so it is plain cover: too tall to vault, mantle or grab.
	local cover = Kit.box(folder, origin, "Cover", Vector3.new(6, 12, 1), CENTRE_X, 98)
	Kit.label(cover, "Cover: strafe out from behind")

	-- Slalom: pylons 15 studs apart (z 145 down to 70), stepping half a stud left and right of
	-- x = 322. Each pylon is 1 wide, so together they cover the centre line and
	-- there is no straight path through: you have to weave round every one.
	for index = 0, 5 do
		local x = 322 + (if index % 2 == 0 then -0.5 else 0.5)
		Kit.box(folder, origin, "Pylon" .. (index + 1), Vector3.new(1, 12, 1), x, 145 - index * 15, Kit.LOW_COLOR)
	end

	Kit.resetPost(folder, origin, "Reset", 252, 148, Kit.standAt(CENTRE_X, 140, 0), "Strafe lane")
end

return StrafeLane
