-- Stops players' arms and legs colliding with the world.
--
-- Why: during mantle, vault, ledge hang and wall-run the Humanoid is in its
-- "Physics" state, and in that state it makes every body part solid. The
-- hands then push into the wall (for example while hanging) and shove the
-- body out of place. Setting CanCollide from a script does not stick,
-- because the Humanoid keeps resetting it.
--
-- A collision group is a label on parts; two groups can be told not to
-- collide. Limbs go into "PlayerLimbs", which does not collide with
-- "Default" (the world). The root part and torso stay in Default, so the
-- character still cannot pass through walls or floors. In ordinary walking
-- the Humanoid already keeps limbs non-solid, so nothing changes there.
--
-- Collision groups have to be registered on the server.

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local GROUP = "PlayerLimbs"
local CORE = { HumanoidRootPart = true, UpperTorso = true, LowerTorso = true, Torso = true, Head = true }

PhysicsService:RegisterCollisionGroup(GROUP)
PhysicsService:CollisionGroupSetCollidable(GROUP, "Default", false)
PhysicsService:CollisionGroupSetCollidable(GROUP, GROUP, false)

local function setGroup(part: Instance)
	if part:IsA("BasePart") and not CORE[part.Name] then
		part.CollisionGroup = GROUP
	end
end

local function onCharacter(character: Model)
	for _, part in character:GetChildren() do
		setGroup(part)
	end
	character.ChildAdded:Connect(setGroup)
end

local function onPlayer(player: Player)
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		onCharacter(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do
	onPlayer(player)
end
