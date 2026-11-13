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
	-- Pressing sprint while already strafing (moving sideways) goes straight
	-- to sprint-strafe speed with no build-up, for quick strafes (user ruling
	-- 2026-11-12). "Sideways" means the push is at least this far from
	-- straight ahead or straight back: 0.5 = more than 60 degrees off, so
	-- pure left/right counts and forward diagonals do not. 0 = only exactly
	-- sideways; 1 = any direction.
	StrafeSprintSnapDot = 0.5,
	StrafeSpeedScale = 0.85, -- flat sideways
	BackSpeedScale = 0.6, -- straight back

	-- Air
	AirAccel = 20, -- steering strength while airborne (speed itself is kept)
	-- Camera steering in the air (user request 2026-11-12): turning the view
	-- turns your momentum by this share of the turn, whether or not a key is
	-- held. 0.3 = look 90 degrees left and your flight bends 27 degrees left.
	-- Speed is kept. 0 = off; 1 = momentum follows the view exactly.
	AirCameraSteer = 0.3,
	-- Height of a fresh jump, in studs (Roblox's default is 7.2). Raised
	-- from 5 to 7 (user ruling 2026-11-13).
	JumpHeight = 7,
	-- Jump fatigue (user ruling 2026-11-13): each jump in a row is this much
	-- lower than the one before (7, 5, 3), down to JumpMinHeight. Landing
	-- the lowest jump blocks jumping for JumpFatigueCooldown seconds; after
	-- that the next jump is full height again. Resting on the ground for
	-- JumpRestTime seconds without jumping also brings back the full height.
	JumpHeightStep = 2,
	JumpMinHeight = 5,
	JumpFatigueCooldown = 0.7,
	JumpRestTime = 0.6,
	-- Weighted fall (user ruling 2026-11-13): on the way down from a jump,
	-- gravity is this many times stronger, like jumping with equipment.
	-- The rise and the height are unchanged; you just come down faster.
	-- 1 = Roblox's plain arc; higher = heavier
	JumpFallGravityScale = 1.2,
	CoyoteTime = 0.12, -- how long after leaving the ground we still count as grounded (and may still jump)
	JumpCooldown = 0.4, -- seconds after landing from a jump before you can jump again (0 = straight away; wall jumps are not affected)

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
		-- A slide only starts when moving forward (user ruling 2026-11-12):
		-- the movement must be within this of where the player is looking.
		-- 0.9 = up to about 25 degrees off: straight ahead slides; diagonals
		-- (45 degrees), sideways and backwards crouch instead (no diagonal
		-- slide, user ruling 2026-11-12). Lower = wider angles allowed.
		MinForwardDot = 0.9,
		-- Seconds after one slide ends before the next can start, so sprint
		-- and slide cannot be spammed (user ruling 2026-11-11; the value is
		-- the agent's guess). During it, a crouch tap crouches instead.
		-- Higher = fewer slides in a row.
		Cooldown = 1.0,
		Boost = 4, -- speed added when a slide starts
		-- No boost if the previous slide ended more recently than this.
		-- Only matters when it is longer than Cooldown above.
		BoostCooldown = 1.0,
		MaxSpeed = 26,
		-- Top speed while sliding DOWN A SLOPE (user ruling 2026-11-12). The
		-- slide stops gaining speed here, and a slide that arrives on a slope
		-- faster than this is trimmed to it. Higher = faster ramp slides.
		SlopeMaxSpeed = 28,
		-- The same cap for a slide that was started while in FLOW.
		FlowSlopeMaxSpeed = 30,
		-- The furthest a slide may travel on flat ground, in studs (user
		-- ruling 2026-11-12). Friction normally ends it sooner; this is the
		-- limit however fast it started. Distance covered on a slope does
		-- not count. Higher = longer flat slides allowed.
		MaxFlatDistance = 25,
		-- Speed lost per second on flat ground (higher = shorter slide). At 25
		-- a normal slide travels about 15 studs (it was 22, about 17 studs;
		-- shortened by 2 studs, user ruling 2026-11-12). Slopes have no friction.
		Friction = 25,
		SlopeAccel = 40, -- speed gained per second on a (theoretical) vertical slope
		EndSpeed = 10, -- slide ends (into crouch or walk) when speed falls below this
		MinTime = 0.22, -- cannot cancel a slide (with crouch or sprint) before this
		-- How fast the slide direction can turn, radians per second. 1.287 is
		-- about 74 degrees per second (was 1.2, about 69; raised by 5 degrees
		-- per second, user ruling 2026-11-12). Higher = the slide steers more.
		SteerRate = 1.287,
		-- Camera steering (user request 2026-11-12): turning the view turns
		-- the slide by this share of the turn, on top of the key steering
		-- above. 0.5 = look 90 degrees left and the slide bends 45 degrees.
		-- Speed is kept. 0 = off; 1 = the slide follows the view exactly.
		CameraSteer = 0.4,
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
		-- value is the agent's guess). At 10, a run of about 2.3 s (the
		-- normal length, see WallRun) costs 23. Momentum takes up to half off, as for the costs below,
		-- measured when the run starts. A run that has started always
		-- finishes, even if stamina runs out during it (user rulings 2026-11-12).
		WallRunDrain = 10,
		-- Points per second while hanging from a ledge (user ruling
		-- 2026-11-11; the value is the agent's guess). At 5, a full bar is 20
		-- seconds of hanging. Running out makes the player let go, and
		-- an exhausted player cannot grab a ledge.
		LedgeHangDrain = 5,
		-- Paid once, when the action starts. Higher = fewer of them per bar.
		-- Momentum (below) takes up to half off.
		Costs = {
			Slide = 10,
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
		Window = 3,
		-- Every this many counted actions, the chain pays Reward. The same
		-- action twice in a row counts once. Lower = easier rewards.
		MinActions = 3,
		Reward = 25, -- stamina points per payout
		-- The most one chain can pay in total. After that it pays nothing
		-- until it has ended and a new chain begins. This is what stops a
		-- repeated loop of moves from producing stamina for ever. Equal to
		-- Reward, so a chain pays once: when it is completed.
		MaxRewardPerChain = 25,
		-- Being "in FLOW" (user rulings 2026-11-12): from the moment a chain
		-- reaches MinActions (the hidden FLOW meter is at 100%) until the
		-- chain ends. While it lasts:
		SprintSpeedAdd = 5, -- sprint top speed goes up by this (walk, crouch and crawl do not)
		FovAdd = 5, -- the view widens by this many degrees
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
		-- 3.2 rather than 3.0 for the same reason as MinHeight: the height is measured
		-- from the live feet position, which is a hair above or below the floor, so an
		-- obstacle exactly 3 studs tall would otherwise land either side of the limit
		-- and sometimes mantle instead (user ruling 2026-11-12).
		MaxHeight = 3.2,
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
		MaxHeight = 10,
		RiseSpeed = 14, -- studs/second while pulling up
		ForwardTime = 0.12, -- seconds to move onto the ledge once up
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
		CheckDistance = 5.0, -- how close to the wall (from body centre)
		MaxApproachDot = 0.6, -- 0 = must be exactly parallel; higher allows a steeper angle into the wall
		-- The same limit straight after a wall jump, when you are flying
		-- across toward the opposite wall at a steep angle. Looser, so a
		-- jump from one wall to another catches the new wall (user ruling
		-- 2026-11-12). The new wall starts a fresh run.
		WallToWallApproachDot = 0.95,
		StickDistance = 2.5, -- if the wall is further than this, the run ends
		StickForce = 2, -- small push into the wall to stay on it
		UpKick = 6, -- upward speed when the run starts
		-- How fast the run curves downward (normal gravity is about 196).
		-- There is no time limit: the run lasts until the feet reach the
		-- ground (or the wall ends, or you jump or drop off). At 6 that is
		-- about 2.3 s, roughly 50 studs at sprint speed. Lower = longer runs.
		-- (User ruling 2026-11-12; the values are the agent's guess.)
		Gravity = 6,
		FlowGravity = 4, -- the same, for a run started while in FLOW: about 3.4 s
		Friction = 2, -- speed lost per second
		WallJumpOut = 14, -- sideways speed away from the wall on a wall jump
		WallJumpHeight = 3.25, -- height of a wall jump
		WallJumpKeep = 0.8, -- share of the run speed kept on a wall jump
	},

	-- Quick turn (R): the view swings round 180 degrees.
	QuickTurn = {
		Duration = 0.18, -- seconds for the full half-turn
	},

	Camera = {
		Offset = Vector3.new(0, 0, -0.9), -- pushes the view forward so the torso does not fill the screen
		-- How far down the player can look, in degrees below level (Roblox
		-- allows 80). Lower = cannot look as far down, so the view never
		-- ends up inside the character's own body. (User ruling 2026-11-12;
		-- the value is the agent's guess.)
		MaxLookDown = 60,
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
		BobAmount = 0.25, -- head bob height at sprint speed
		BobFrequency = 0.45, -- bob cycles per stud travelled (scaled)
		-- Left/right TILT of the view (degrees) with each pair of steps while
		-- sprinting forward or on a forward diagonal.
		SprintSwayTilt = 1.0,
		-- Side-to-side sway (studs) while WALKING, at walk speed (user ruling
		-- 2026-11-12). SideBobAmount below covers sprint, crouch and crawl.
		WalkSideBobAmount = 0.1,
		SideBobAmount = 0.08, -- side-to-side sway at sprint speed (one sway left and right per two steps)
		StrafeBobAdd = 0.14, -- extra side-to-side sway (studs) when moving flat sideways
		StrafeBobTrade = 0.5, -- share of the up-and-down bob removed when moving flat sideways
		StrafeLean = 1.5, -- tilt when moving sideways
		WallRunTilt = 10, -- tilt away from the wall while wall-running
		DipMinFall = 1.5, -- falls shorter than this give no landing dip
		DipPerStud = 0.10, -- landing dip depth per stud fallen
		DipMax = 0.12, -- deepest landing dip
		DipDuration = 0.3,
		ReducedDipScale = 0.35, -- landing dip size with reduced camera motion
		ReducedFovScale = 0.5, -- speed FOV change with reduced camera motion
		SideTilt = 0.5, -- tilt when moving sideways (with reduced camera motion)
	},
}
