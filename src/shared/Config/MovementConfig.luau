-- Every movement tuning number lives here, so feel can be changed without
-- touching logic. ALL VALUES ARE UNTUNED FIRST GUESSES.
--
-- Units: distances in studs, speeds in studs/second, accelerations in
-- studs/second^2, times in seconds, angles in degrees.
-- For scale: a standard R15 character is about 5.5 studs tall.

return {
	-- Ground speeds
	WalkSpeed = 12,
	SprintSpeed = 20,
	CrouchSpeed = 7,

	-- How quickly speed changes on the ground
	GroundAccel = 40, -- from standing still up to walk speed
	SprintAccel = 14, -- from walk speed up to sprint speed
	GroundDecel = 50, -- slowing down when input stops or the target speed drops

	-- How hard the character brakes the part of its momentum that is NOT in
	-- the direction the player is now pushing (turning, or reversing). Higher
	-- = sharper turns, lower = more "ice". This is what stops quick turns from
	-- feeling slippery.
	TurnFriction = 90,

	-- Sprint only engages while moving mostly forward. 1 = exactly forward,
	-- 0 = sideways allowed.
	SprintForwardDot = 0.3,

	-- Air
	AirAccel = 20, -- steering strength while airborne (speed itself is kept)
	JumpHeight = 3.25, -- Roblox's default is 7.2
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
		MinSpeed = 16, -- must be moving at least this fast to start a slide
		Boost = 4, -- speed added when a slide starts
		BoostCooldown = 1.0, -- no boost if the previous slide ended more recently than this
		MaxSpeed = 34,
		Friction = 22, -- speed lost per second on flat ground (higher = shorter slide)
		SlopeAccel = 45, -- speed gained per second on a (theoretical) vertical slope
		EndSpeed = 10, -- slide ends (into crouch or walk) when speed falls below this
		MinTime = 0.25, -- cannot cancel a slide before this
		SteerRate = 1.2, -- how fast the slide direction can turn, radians per second
	},

	-- Roll: crouch pressed while airborne, before touching the ground.
	Roll = {
		Duration = 0.55,
		MinSpeed = 10, -- a roll always carries you forward at least this fast
		MaxSpeed = 24, -- landing faster than this is trimmed to this
		Friction = 6, -- speed lost per second during the roll
		CameraSpin = 360, -- forward camera rotation over the roll; 0 turns it off
	},

	-- Mantle: climbing up onto a ledge. Automatic for now: jump at a ledge
	-- while pushing toward it. Heights are measured from the ground you
	-- jumped from to the top of the ledge.
	Mantle = {
		MinHeight = 3, -- lower than this: just jump onto it (vaulting comes later)
		MaxHeight = 6.5, -- higher than this: out of reach (ledge grab comes later)
		Reach = 3.4, -- how far above the root part (body centre) the hands can grab
		WallCheckDistance = 2.2, -- how close to the wall you must be
		RiseSpeed = 14, -- studs/second while pulling up
		ForwardTime = 0.15, -- seconds to move onto the ledge once up
		ExitSpeed = 10, -- forward speed when the mantle finishes (capped by entry speed)
		Cooldown = 0.3, -- seconds before another mantle can start
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
