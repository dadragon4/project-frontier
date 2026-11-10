-- Every movement tuning number lives here, so feel can be changed without
-- touching logic. ALL VALUES ARE UNTUNED FIRST GUESSES.
--
-- Units: distances in studs, speeds in studs/second, accelerations in
-- studs/second^2, times in seconds, angles in degrees.

return {
	-- Ground speeds
	WalkSpeed = 14,
	SprintSpeed = 24,
	CrouchSpeed = 8,

	-- How quickly speed changes on the ground
	GroundAccel = 60, -- reaching walk speed
	SprintAccel = 28, -- building from walk speed up to sprint speed
	GroundDecel = 50, -- slowing down when input stops or the target speed drops

	-- Sprint only engages while moving mostly forward. 1 = exactly forward,
	-- 0 = sideways allowed.
	SprintForwardDot = 0.3,

	-- Air
	AirAccel = 20, -- steering strength while airborne (speed itself is kept)
	JumpHeight = 4.5, -- Roblox's default is 7.2
	CoyoteTime = 0.12, -- how long after leaving the ground we still count as grounded (and may still jump)

	-- Input buffering: how long an early press is remembered.
	Buffer = {
		Jump = 0.15,
		Slide = 0.15,
	},

	-- If our intended speed exceeds the real speed by more than this, we assume
	-- the character hit something and drop the intended speed to match.
	BlockedSpeedTolerance = 8,

	Crouch = {
		Drop = 1.2, -- how far the body lowers
		MinHipHeight = 0.3, -- never lower the hips closer to the ground than this
		TransitionRate = 8, -- 1 / seconds to go fully down or up
		StandingHeadHeight = 2.6, -- top of head above the root part's centre when standing
		HeadroomRadius = 0.8, -- width of the "can I stand up here?" probe
	},

	Slide = {
		MinSpeed = 18, -- must be moving at least this fast to start a slide
		Boost = 6, -- speed added when a slide starts
		BoostCooldown = 1.0, -- no boost if the previous slide ended more recently than this
		MaxSpeed = 40,
		Friction = 14, -- speed lost per second on flat ground
		SlopeAccel = 45, -- speed gained per second on a (theoretical) vertical slope
		EndSpeed = 9, -- slide ends when speed falls below this
		MinTime = 0.25, -- cannot cancel a slide before this
		SteerRate = 1.2, -- how fast the slide direction can turn, radians per second
	},

	Camera = {
		Offset = Vector3.new(0, 0, -0.6), -- pushes the view forward so the torso does not fill the screen
		BaseFov = 80,
		SprintFovAdd = 8,
		SlideFovAdd = 12,
		FovRate = 8, -- higher = FOV follows speed more quickly
		SlideRoll = 4, -- camera tilt during a slide
		RollRate = 10,
	},
}
