-- Every movement tuning number lives here, so feel can be changed without
-- touching logic. ALL VALUES ARE UNTUNED FIRST GUESSES.
--
-- Not in here: the player's own preferences (src/client/Settings.luau) and
-- the key bindings (src/client/Input.luau).
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
	-- While sprinting, how quickly extra speed above sprint speed (from a
	-- slide-hop or a vault) bleeds away. Low = the extra speed lingers.
	OverSpeedDecel = 10,

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

	-- Slide-hop: jumping out of a slide adds a little speed. Combined with
	-- OverSpeedDecel, you keep a bit of the slide's speed after landing.
	SlideHop = {
		Boost = 3,
		MaxSpeed = 26, -- the boost never takes you above this
		Cooldown = 1.0, -- seconds between boosted hops
	},

	-- Roll. Two ways in:
	--   air roll:    crouch pressed while airborne, and the fall (highest
	--                point to landing) was at least MinFallHeight;
	--   ground roll: crouch pressed twice quickly while on the ground.
	Roll = {
		MinFallHeight = 6,
		DoubleTapWindow = 0.3, -- max seconds between the two crouch presses
		Duration = 0.55,
		MinSpeed = 10, -- a roll always carries you forward at least this fast
		MaxSpeed = 24, -- landing faster than this is trimmed to this
		Friction = 6, -- speed lost per second during the roll
		CameraSpin = 360, -- forward camera rotation over the roll; 0 turns it off
	},

	-- Clambering = vault, mantle and ledge grab. Heights are measured from
	-- the floor you are standing on, or jumped from, to the obstacle's top.
	-- Which one happens:
	--   up to Vault.MaxHeight, and thin enough with floor behind -> vault over
	--   up to Mantle.MaxHeight (and not vaultable)                -> mantle onto
	--   up to LedgeGrab.MaxHeight, airborne                       -> hang from it
	Clamber = {
		WallCheckDistance = 2.2, -- how close to the obstacle you must be
		Reach = 3.4, -- how far above the root part (body centre) the hands can grab
		Cooldown = 0.3, -- seconds after one clamber before the next can start
		MinGroundSpeed = 3, -- Automatic mode on the ground: must be moving at least this fast
		ManualPressWindow = 0.25, -- Manual mode: Space pressed this recently (or held) counts
	},

	Vault = {
		MinHeight = 1.2, -- lower than this is just a step
		MaxHeight = 3.0,
		MaxDepth = 4, -- obstacles deeper than this are mantled onto instead
		LandingGap = 1.5, -- how far past the far edge you land
		RootClearance = 2.0, -- body centre passes this far above the top (legs tucked)
		MinSpeed = 10, -- a vault always moves at least this fast
		MaxSpeed = 26,
		SpeedKeep = 0.95, -- share of speed kept coming out of the vault
		MinDuration = 0.3,
		CameraDip = 4, -- small downward look during the vault
	},

	Mantle = {
		MinHeight = 1.2,
		MaxHeight = 6.5,
		RiseSpeed = 14, -- studs/second while pulling up
		ForwardTime = 0.15, -- seconds to move onto the ledge once up
		ExitSpeed = 10, -- forward speed when the mantle finishes (capped by entry speed)
		CameraDip = 6, -- small downward look while pulling up
	},

	LedgeGrab = {
		MaxHeight = 10, -- tallest ledge that can be grabbed (still limited by Reach)
		WallGap = 0.9, -- body centre's distance from the wall while hanging
		HangDrop = 2.4, -- body centre's distance below the ledge top while hanging
		ShimmySpeed = 4, -- sideways speed along the ledge
	},

	-- Wall-run: jump alongside a wall while moving along it.
	WallRun = {
		MinSpeed = 12, -- need at least this much speed to start, and it ends below half of it
		MaxSpeed = 26,
		MinAirTime = 0.08, -- must have been airborne this long first
		MinHeightAboveFloor = 1.0, -- feet must be at least this high
		CheckDistance = 2.0, -- how close to the wall (from body centre)
		MaxApproachDot = 0.6, -- 0 = must be exactly parallel; higher allows a steeper angle into the wall
		StickDistance = 2.5, -- if the wall is further than this, the run ends
		StickForce = 2, -- small push into the wall to stay on it
		UpKick = 6, -- upward speed when the run starts
		Gravity = 12, -- how fast the run curves downward (normal gravity is about 196)
		Friction = 2, -- speed lost per second
		MaxDuration = 1.3,
		WallJumpOut = 14, -- sideways speed away from the wall on a wall jump
		WallJumpHeight = 3.25, -- height of a wall jump
		WallJumpKeep = 0.8, -- share of the run speed kept on a wall jump
	},

	-- Quick turn (R): the view swings round 180 degrees.
	QuickTurn = {
		Duration = 0.18, -- seconds for the full half-turn
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

	-- Small camera movements that make motion feel physical. "Reduce camera
	-- motion" in the player's settings turns most of these off.
	CameraFeel = {
		BobAmount = 0.12, -- head bob height at sprint speed
		BobFrequency = 0.55, -- bob cycles per stud travelled (scaled)
		StrafeLean = 1.5, -- tilt when moving sideways
		WallRunTilt = 10, -- tilt away from the wall while wall-running
		DipMinFall = 1.5, -- falls shorter than this give no landing dip
		DipPerStud = 0.08, -- landing dip depth per stud fallen
		DipMax = 0.9, -- deepest landing dip
		DipDuration = 0.3,
		ReducedDipScale = 0.35, -- landing dip size with reduced camera motion
		ReducedFovScale = 0.5, -- speed FOV change with reduced camera motion
	},
}
