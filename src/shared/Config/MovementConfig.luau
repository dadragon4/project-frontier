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
	WalkSpeed = 16,
	SprintSpeed = 25,
	CrouchSpeed = 9,

	-- How quickly speed changes on the ground
	GroundAccel = 100, -- from standing still up to walk speed
	SprintAccel = 50, -- from walk speed up to sprint speed
	GroundDecel = 75, -- slowing down when input stops or the target speed drops
	-- While sprinting, how quickly extra speed above sprint speed (from a
	-- slide-hop or a vault) bleeds away. Low = the extra speed lingers.
	OverSpeedDecel = 10,

	-- How hard the character brakes the part of its momentum that is NOT in
	-- the direction the player is now pushing (turning, or reversing). Higher
	-- = sharper turns, lower = more "ice". This is what stops quick turns from
	-- feeling slippery.
	TurnFriction = 80,

	-- How hard the character brakes when the player pushes AGAINST the way
	-- they are moving (left while moving right, back while moving forward):
	-- a reversal, or "counter-strafe". Studs/second^2. Higher = the
	-- character stops and comes back sooner; too high feels abrupt and
	-- robotic. Lower = more drag before it turns round. Keep it above
	-- GroundDecel, so pressing the opposite key stops you faster than
	-- letting go does. TurnFriction (above) is the other half: it handles
	-- sideways leftovers when turning a corner.
	ReverseDecel = 140,

	-- Moving sideways or backwards is slower than moving straight ahead, in
	-- every ground state (walk, sprint, crouch, prone). These are the share
	-- of the state's top speed you get; directions in between are blended.
	StrafeSpeedScale = 0.85, -- flat sideways
	BackSpeedScale = 0.6, -- straight back

	-- Air
	AirAccel = 20, -- steering strength while airborne (speed itself is kept)
	JumpHeight = 5, -- Roblox's default is 7.2
	CoyoteTime = 0.12, -- how long after leaving the ground we still count as grounded (and may still jump)
	JumpCooldown = 0.5, -- seconds after landing from a jump before you can jump again (0 = straight away; wall jumps are not affected)

	-- Input buffering: how long an early press is remembered.
	Buffer = {
		Jump = 0.15,
		Slide = 0.15, -- a crouch tap made just before it can be used (for example just before landing)
		Roll = 0.15,
	},

	-- The crouch key does two jobs. Let go within this time and it is a tap
	-- (crouch, slide, stand up); keep it down this long and it is a hold
	-- (prone, dive).
	CrouchHoldTime = 0.25,

	-- If our intended speed exceeds the real speed by more than this, we assume
	-- the character hit something and drop the intended speed to match.
	BlockedSpeedTolerance = 8,

	Crouch = {
		Drop = 1.2, -- how far the body lowers
		MinHipHeight = 0.3, -- never lower the hips closer to the ground than this
		-- Studs per second the body moves down or up. (This used to be
		-- "1 / seconds for the whole move", with the value 8; 10 studs per
		-- second over the 1.2 stud drop is the same speed.)
		TransitionRate = 10,
		StandingHeadHeight = 2.6, -- top of head above the root part's centre when standing
		HeadroomRadius = 0.8, -- width of the "can I stand up here?" probe
	},

	Slide = {
		MinSpeed = 14, -- must be moving at least this fast to start a slide
		-- Seconds after one slide ends before the next can start, so sprint
		-- and slide cannot be spammed (user ruling 2026-11-11; the value is
		-- the agent's guess). During it, a crouch tap crouches instead.
		-- Higher = fewer slides in a row.
		Cooldown = 1.0,
		Boost = 4, -- speed added when a slide starts
		-- No boost if the previous slide ended more recently than this.
		-- Only matters when it is longer than Cooldown above.
		BoostCooldown = 1.0,
		MaxSpeed = 34,
		Friction = 22, -- speed lost per second on flat ground (higher = shorter slide)
		SlopeAccel = 45, -- speed gained per second on a (theoretical) vertical slope
		EndSpeed = 10, -- slide ends (into crouch or walk) when speed falls below this
		MinTime = 0.25, -- cannot cancel a slide (with crouch or sprint) before this
		SteerRate = 1.2, -- how fast the slide direction can turn, radians per second
		-- Sliding down a slope at least this steep (degrees) has no friction
		-- and does not end until the slope levels out.
		SlopeMinAngle = 5,
	},

	-- Prone: lying down. The body is lowered as far as the rig allows; it is
	-- not laid flat yet (that waits for the custom rig and animations).
	Prone = {
		Drop = 1.75, -- how far the body lowers. This is at the MinHipHeight limit for an R15 rig; do not raise it without checking the feet.
		Speed = 3, -- crawl speed
		Accel = 20,
		MinTime = 0.35, -- cannot get up before this
		TransitionRate = 3, -- studs per second the body lowers into, or rises out of, prone
	},

	-- Dive: a forward leap that lands prone. Hold crouch while sprinting.
	Dive = {
		MinSpeed = 18, -- must be moving at least this fast
		Boost = 4, -- speed added at the start
		MaxSpeed = 30, -- the boost never takes you above this
		Height = 2.5, -- how high the leap rises
	},

	-- Slide-hop: jumping out of a slide adds a little speed. Combined with
	-- OverSpeedDecel, you keep a bit of the slide's speed after landing.
	SlideHop = {
		Boost = 3,
		MaxSpeed = 26, -- the boost never takes you above this
		Cooldown = 1.0, -- seconds between boosted hops
	},

	-- Roll (Ctrl, or Command on a Mac). Two ways in:
	--   air roll:    roll pressed while airborne, and the fall (highest
	--                point to landing) was at least MinFallHeight;
	--   ground roll: roll pressed while walking or sprinting (not while
	--                standing still, and not out of a slide).
	Roll = {
		MinFallHeight = 6,
		Duration = 0.55,
		MinSpeed = 10, -- a roll always carries you forward at least this fast
		MaxSpeed = 24, -- landing faster than this is trimmed to this
		Friction = 6, -- speed lost per second during the roll
		CameraSpin = 360, -- forward camera rotation over the roll; 0 turns it off
	},

	-- Stamina. INITIAL TUNING VALUES (user, 2026-11-11), not final balance.
	-- Stamina is in points; the rules are in src/shared/Stamina.luau.
	Stamina = {
		Max = 100, -- a full bar. Higher = longer before running out of everything below.
		-- Points per second while in the Sprint state. At 8, a full bar is
		-- 12.5 seconds of sprinting. Higher = shorter sprints.
		SprintDrain = 8,
		-- Points per second while wall-running (user ruling 2026-11-11; the
		-- value is the agent's guess). At 10, the longest wall-run (1.3 s)
		-- costs 13. Running out ends the run.
		WallRunDrain = 10,
		-- Points per second while hanging from a ledge (user ruling
		-- 2026-11-11; the value is the agent's guess). At 5, a full bar is 20
		-- seconds of hanging. Running out makes the player let go, and
		-- an exhausted player cannot grab a ledge.
		LedgeHangDrain = 5,
		-- Paid once, when the action starts. Higher = fewer of them per bar.
		-- Momentum (below) takes up to half off.
		Costs = {
			Slide = 15,
			Roll = 15, -- ground rolls and air rolls alike
			Dive = 20,
		},
		RegenRate = 15, -- points per second coming back. Higher = shorter rests.
		-- Seconds after the last time stamina was spent before it starts
		-- coming back. Sprinting spends all the time, so nothing comes back
		-- while sprinting. Higher = a longer pause before recovery begins.
		RegenDelay = 1,
		-- Exhaustion starts when stamina reaches zero. While it lasts, nothing
		-- that needs stamina can start (sprint, slide, dive, roll, wall-run,
		-- ledge hang), and walk, crouch and crawl speeds are multiplied by
		-- this (so is the speed that steering in the air can build up to).
		-- Vaults and mantles are not affected. Lower = harsher.
		ExhaustedSpeedScale = 0.7,
		-- Exhaustion ends when stamina is back up to this, not as soon as it
		-- is above zero, so it cannot flicker. Higher = exhaustion lasts longer.
		RecoverAt = 15,
		-- Momentum: the most that speed can take off an action's cost (0.5 =
		-- half price). The discount is zero standing still and reaches this
		-- at SprintSpeed, counting only speed straight ahead (where the
		-- player is looking). Higher = speed matters more.
		MomentumMaxDiscount = 0.5,
		-- Points given back for a vault or mantle done in Manual clamber
		-- mode. (Agent's guess.) Not given for a ledge grab, which could be
		-- repeated on the spot.
		ManualClamberRefund = 3,
	},

	-- FLOW chain: linking abilities into one sequence gives a little stamina
	-- back. INITIAL TUNING VALUES (user, 2026-11-11), not final balance.
	-- The rules are in src/shared/FlowChain.luau.
	Flow = {
		-- Seconds allowed between one action finishing and the next
		-- beginning. Higher = more forgiving chains.
		Window = 2,
		-- Every this many counted actions, the chain pays Reward. The same
		-- action twice in a row counts once. Lower = easier rewards.
		MinActions = 3,
		Reward = 5, -- stamina points per payout
		-- The most one chain can pay in total. After that it pays nothing
		-- until it has ended and a new chain begins. This is what stops a
		-- repeated loop of moves from producing stamina for ever.
		MaxRewardPerChain = 10,
		-- An action that lasted less than this (dropped the instant it
		-- began) does not count. Seconds. (Agent's guess.)
		MinActionTime = 0.15,
		-- Which actions count. Set one to false to take it out.
		-- SlideHop is a jump out of a slide; a plain jump does not count.
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
		-- Roblox's character steps over anything up to about 2 studs by itself, so lower
		-- obstacles are treated as steps (user ruling 2026-11-11). 1.9 rather than 2.0 so
		-- an obstacle exactly 2 studs tall still counts as a vault.
		MinHeight = 1.9,
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
		MinHeight = 1.9, -- same reason as Vault.MinHeight
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
		MinSpeed = 16, -- need at least this much speed to start, and it ends below half of it
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
		BobAmount = 0.20, -- head bob height at sprint speed
		BobFrequency = 0.45, -- bob cycles per stud travelled (scaled)
		SideBobAmount = 0.10, -- side-to-side sway at sprint speed (one sway left and right per two steps)
		StrafeBobAdd = 0.14, -- extra side-to-side sway (studs) when moving flat sideways
		StrafeBobTrade = 0.5, -- share of the up-and-down bob removed when moving flat sideways
		StrafeLean = 1.5, -- tilt when moving sideways
		WallRunTilt = 10, -- tilt away from the wall while wall-running
		DipMinFall = 1.5, -- falls shorter than this give no landing dip
		DipPerStud = 0.08, -- landing dip depth per stud fallen
		DipMax = 0.9, -- deepest landing dip
		DipDuration = 0.3,
		ReducedDipScale = 0.35, -- landing dip size with reduced camera motion
		ReducedFovScale = 0.5, -- speed FOV change with reduced camera motion
		SideTilt = 0.5, -- tilt when moving sideways (with reduced camera motion)
	},
}
