-- Development-only switches. Nothing here is game design.

return {
	-- Show the on-screen movement readout (state and speed).
	ShowDebugReadout = true,

	-- Let the scripted movement tests be started (see src/client/Dev/MovementTests).
	-- They need the test course.
	MovementTests = true,

	TestCourse = {
		-- Build the greybox movement course when the server starts and spawn
		-- players on it.
		Enabled = true,
		-- Built high in the air so it cannot overlap anything already in the place.
		Origin = Vector3.new(0, 500, 0),
	},
}
