-- Every movement tuning number lives here, so feel can be changed without
-- touching logic. Why each rule exists is in MOVEMENT_SPEC.md and DECISIONS.md.
--
-- Not in here: the player's own preferences (src/client/Settings.luau) and
-- the key bindings (src/client/Input.luau).
--
-- Units: distances in studs, speeds in studs/second, accelerations in
-- studs/second^2, times in seconds, angles in degrees.
-- For scale: a standard R15 character is about 5.5 studs tall.

return {
	-- Ground speeds
	WalkSpeed = 16,
	SprintSpeed = 25,
	CrouchSpeed = 9,

	-- How quickly speed changes on the ground
	GroundAccel = 100, -- from standing still up to walk speed
	SprintAccel = 50, -- from walk speed up to sprint speed
	GroundDecel = 75, -- slowing down when you let go or the top speed drops
	-- Extra speed above sprint speed (from a slide-hop or vault) fades at
	-- this rate. Lower = it lingers.
	OverSpeedDecel = 10,

	-- Braking of leftover sideways momentum when turning. Higher = sharper
	-- turns; lower = more slippery.
	TurnFriction = 80,

	-- Braking when pushing against your own momentum (a counter-strafe).
	-- Keep it above GroundDecel, so the opposite key stops you faster than
	-- letting go. Too high feels robotic.
	ReverseDecel = 140,

	-- Sideways and backwards are slower than straight ahead, in every
	-- ground state. These are shares of the state's top speed.
	StrafeSpeedScale = 0.85, -- flat sideways
	BackSpeedScale = 0.6, -- straight back
	-- Pressing sprint while strafing jumps straight to sprint-strafe speed.
	-- Counts as strafing when the push is at most this close to straight
	-- ahead or back: 0.5 = more than 60 degrees off.
	StrafeSprintSnapDot = 0.5,

	-- Air
	AirAccel = 20, -- key steering strength in the air (speed is kept)
	-- Turning the view bends your flight by this share of the turn.
	-- 0 = off, 1 = flight follows the view exactly.
	AirCameraSteer = 0.3,

	-- Jump
	JumpHeight = 7, -- a fresh jump (Roblox's default is 7.2)
	-- Jump fatigue: each jump in a row is JumpHeightStep lower, down to
	-- JumpMinHeight. Landing the lowest jump blocks jumping for
	-- JumpFatigueCooldown. JumpRestTime on the ground restores full height.
	JumpHeightStep = 2,
	JumpMinHeight = 5,
	JumpFatigueCooldown = 0.7,
	JumpRestTime = 0.6,
	-- Gravity is this many times stronger on the way down, so a jump feels
	-- weighted. Height is unchanged. 1 = Roblox's plain arc.
	JumpFallGravityScale = 1.2,
	CoyoteTime = 0.12, -- you can still jump this long after walking off an edge
	JumpCooldown = 0.4, -- after landing, wait this long before jumping again (wall jumps excepted)

	-- How long an early press is remembered.
	Buffer = {
		Jump = 0.15,
		Slide = 0.15, -- a crouch tap made just before it can be used
		Roll = 0.15,
	},

	-- Crouch key: let go within this time = tap (crouch, slide, stand up);
	-- hold this long = hold (prone, dive).
	CrouchHoldTime = 0.25,

	-- If the real speed falls this far below the intended speed, we assume
	-- we ran into something and lower the intended speed to match.
	BlockedSpeedTolerance = 8,

	Crouch = {
		Drop = 1.2, -- how far the body lowers
		MinHipHeight = 0.3, -- the hips never get closer to the ground than this
		TransitionRate = 10, -- studs per second the body moves down or up
		StandingHeadHeight = 2.6, -- top of the head above the body centre, standing
		HeadroomRadius = 0.8, -- width of the "room to stand up?" check
	},

	Slide = {
		MinSpeed = 14, -- slowest speed a slide can start at
		-- Only slides straight ahead: movement must be within this of where
		-- you look. 0.9 = about 25 degrees, so diagonals do not slide.
		MinForwardDot = 0.9,
		Cooldown = 1.0, -- after a slide, wait this long before the next
		Boost = 4, -- speed added when a slide starts
		BoostCooldown = 1.0, -- no boost if the last slide ended this recently
		MaxSpeed = 26,
		SlopeMaxSpeed = 28, -- top speed down a slope
		FlowSlopeMaxSpeed = 30, -- the same, for a slide started in FLOW
		MaxFlatDistance = 25, -- the furthest a slide goes on flat ground
		Friction = 25, -- speed lost per second on flat ground (25 = about 15 studs)
		SlopeAccel = 40, -- speed gained per second on a (theoretical) vertical slope
		EndSpeed = 10, -- the slide ends below this speed
		MinTime = 0.22, -- crouch or sprint cannot end a slide before this
		SteerRate = 1.287, -- key steering, radians per second (about 74 degrees)
		-- Turning the view turns the slide by this share of the turn.
		-- 0 = off, 1 = the slide follows the view exactly.
		CameraSteer = 0.4,
		SlopeMinAngle = 5, -- slopes at least this steep have no friction
	},

	-- Lying down. The body is only lowered for now; laying it flat waits
	-- for the custom rig.
	Prone = {
		Drop = 1.75, -- how far the body lowers; the R15 limit, check the feet before raising it
		Speed = 3, -- crawl speed
		Accel = 20,
		MinTime = 0.35, -- cannot get up before this
		TransitionRate = 3, -- studs per second the body lowers or rises
	},

	-- A forward leap that lands prone (hold crouch while sprinting).
	Dive = {
		MinSpeed = 18, -- slowest speed a dive can start at
		Boost = 4, -- speed added at the start
		MaxSpeed = 30, -- the boost never goes above this
		Height = 2.5, -- how high the leap rises
	},

	-- Jumping out of a slide adds a little speed.
	SlideHop = {
		Boost = 3,
		MaxSpeed = 26, -- the boost never goes above this
		Cooldown = 1.0, -- time between boosted hops
	},

	-- Roll (Ctrl, or Command on a Mac): in the air before a long enough
	-- fall, or on the ground while moving forward.
	Roll = {
		MinFallHeight = 6, -- an air roll needs a fall at least this high
		Duration = 0.55,
		MinSpeed = 10, -- a roll always moves at least this fast
		MaxSpeed = 24, -- faster than this is trimmed
		Friction = 6, -- speed lost per second during the roll
		CameraSpin = 360, -- camera turn over the roll; 0 = off
	},

	-- Stamina, in points. The rules are in src/shared/Stamina.luau.
	Stamina = {
		Max = 100,
		SprintDrain = 5, -- per second while sprinting (at 5, a full bar lasts 20 s)
		-- Per second while wall-running, less the momentum discount. A run
		-- that has started always finishes, even at zero.
		WallRunDrain = 8,
		-- Per second while hanging from a ledge. At zero you let go, and an
		-- exhausted player cannot grab a ledge.
		LedgeHangDrain = 5,
		-- Paid once, when the action starts. Momentum takes up to half off.
		Costs = {
			Slide = 5,
			Roll = 10, -- air and ground rolls alike
			Dive = 10,
		},
		RegenRate = 15, -- points per second coming back
		RegenDelay = 1, -- seconds after the last spend before it comes back
		-- At zero you are exhausted: nothing that needs stamina can start,
		-- and walk, crouch and crawl speeds are multiplied by this.
		ExhaustedSpeedScale = 0.7,
		-- Exhaustion lasts until stamina is back up to this, so it cannot
		-- flicker on and off.
		RecoverAt = 15,
		-- The most forward speed can take off a cost (0.5 = half price),
		-- reached at sprint speed.
		MomentumMaxDiscount = 0.5,
		-- Given back for a vault or mantle in Manual clamber mode.
		ManualClamberRefund = 3,
	},

	-- FLOW chain: linking moves gives stamina back. The rules are in
	-- src/shared/FlowChain.luau.
	Flow = {
		Window = 3, -- seconds to start the next move after one finishes
		MinActions = 3, -- moves that complete a chain (the same move twice counts once)
		Reward = 25, -- stamina for completing a chain
		MaxRewardPerChain = 25, -- the most one chain can pay
		-- While in FLOW (chain completed, until it ends):
		SprintSpeedAdd = 5, -- added to sprint top speed
		FovAdd = 5, -- added to the field of view, degrees
		MinActionTime = 0.15, -- a move shorter than this does not count
		-- Moves that count. SlideHop is a jump out of a slide.
		Actions = {
			Slide = true,
			Dive = true,
			Roll = true,
			WallRun = true,
			WallJump = true,
			SlideHop = true,
			Vault = true,
			Mantle = true,
		},
	},

	-- Clambering = vault, mantle and ledge grab. Heights are from the floor
	-- you stand on (or jumped from) to the obstacle's top:
	--   up to Vault.MaxHeight, thin, with floor behind -> vault over
	--   up to Mantle.MaxHeight                        -> mantle onto
	--   up to LedgeGrab.MaxHeight, in the air         -> hang from it
	Clamber = {
		WallCheckDistance = 2.2, -- how close to the obstacle you must be
		Reach = 3.4, -- how far above the body centre the hands can grab
		Cooldown = 0.3, -- time between clambers
		MinGroundSpeed = 3, -- Automatic mode: slowest speed that clambers from the ground
		ManualPressWindow = 0.25, -- Manual mode: Space pressed this recently (or held) counts
	},

	Vault = {
		-- Roblox steps over anything under about 2 studs by itself. 1.9 so
		-- a 2-stud obstacle still vaults.
		MinHeight = 1.9,
		-- 3.2 so a 3-stud obstacle reliably vaults (the feet sit a hair
		-- above or below the floor).
		MaxHeight = 3.2,
		MaxDepth = 4, -- deeper obstacles are mantled onto instead
		LandingGap = 1.5, -- how far past the far edge you land
		RootClearance = 2.0, -- the body centre passes this far above the top
		MinSpeed = 10, -- a vault always moves at least this fast
		MaxSpeed = 26,
		SpeedKeep = 0.95, -- share of speed kept
		MinDuration = 0.3,
		CameraDip = 4, -- small downward look during the vault
	},

	Mantle = {
		MinHeight = 1.9, -- same reason as Vault.MinHeight
		MaxHeight = 10,
		RiseSpeed = 14, -- speed while pulling up
		ForwardTime = 0.12, -- time to move onto the ledge once up
		ExitSpeed = 10, -- forward speed at the end (never more than you arrived with)
		CameraDip = 6, -- small downward look while pulling up
	},

	LedgeGrab = {
		MaxHeight = 10, -- tallest ledge that can be grabbed (also limited by Reach)
		WallGap = 0.9, -- body centre's distance from the wall while hanging
		HangDrop = 2.4, -- body centre's distance below the ledge top
		ShimmySpeed = 4, -- sideways speed along the ledge
	},

	-- Wall-run: jump beside a wall while sprinting along it.
	WallRun = {
		MinSpeed = 16, -- slowest speed to start; the run ends below half of this
		MaxSpeed = 26,
		MinAirTime = 0.08, -- must be in the air this long first
		MinHeightAboveFloor = 1.0, -- feet must be at least this high
		CheckDistance = 5.0, -- how close to the wall (from the body centre)
		MaxApproachDot = 0.6, -- how steeply you may meet the wall: 0 = parallel only
		WallToWallApproachDot = 0.95, -- the same, right after a wall jump (so the opposite wall catches you)
		StickDistance = 2.5, -- the run ends if the wall is further than this
		StickForce = 2, -- small push into the wall to stay on it
		UpKick = 2, -- upward speed at the start: higher = the run rises higher (2 = about half a stud)
		-- How fast the run curves down. There is no time limit; it lasts
		-- until the feet reach the ground. At 3, about 2.2 s. Lower = longer.
		Gravity = 3,
		FlowGravity = 2, -- the same, for a run started in FLOW (about 3 s)
		Friction = 2, -- speed lost per second
		WallJumpOut = 14, -- sideways speed away from the wall on a wall jump
		WallJumpHeight = 3.25, -- height of a wall jump
		WallJumpKeep = 0.8, -- share of run speed kept on a wall jump
	},

	-- Quick turn (R): the view swings round 180 degrees.
	QuickTurn = {
		Duration = 0.18, -- seconds for the half-turn
	},

	Camera = {
		Offset = Vector3.new(0, 0, -0.9), -- pushes the view forward so the torso does not fill the screen
		MaxLookDown = 60, -- degrees below level; stops the view going inside the body (Roblox allows 80)
		BaseFov = 80,
		SprintFovAdd = 8,
		SlideFovAdd = 12,
		FovRate = 8, -- higher = the field of view follows speed faster
		SlideRoll = 4, -- camera tilt during a slide
		RollRate = 10,
	},

	-- Small camera movements that make motion feel physical. "Reduce camera
	-- motion" in settings turns most of them off.
	CameraFeel = {
		BobAmount = 0.25, -- up-and-down head bob at sprint speed
		BobFrequency = 0.45, -- bob cycles per stud travelled (scaled)
		SprintSwayTilt = 1.0, -- left/right view tilt with the steps while sprinting forward, degrees
		WalkSideBobAmount = 0.1, -- side-to-side sway while walking, at walk speed
		SideBobAmount = 0.08, -- side-to-side sway at sprint speed (sprint, crouch, crawl)
		StrafeBobAdd = 0.14, -- extra side-to-side sway when moving flat sideways
		StrafeBobTrade = 0.5, -- share of the up-and-down bob removed when moving flat sideways
		StrafeLean = 1.5, -- tilt when moving sideways
		WallRunTilt = 10, -- tilt away from the wall while wall-running
		DipMinFall = 1.5, -- shorter falls give no landing dip
		DipPerStud = 0.10, -- landing dip depth per stud fallen
		DipMax = 0.12, -- deepest landing dip
		DipDuration = 0.3,
		ReducedDipScale = 0.35, -- landing dip size with reduced camera motion
		ReducedFovScale = 0.5, -- speed field-of-view change with reduced camera motion
		SideTilt = 0.5, -- tilt when moving sideways (with reduced camera motion)
	},
}
