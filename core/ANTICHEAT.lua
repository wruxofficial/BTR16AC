local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local WHITELIST = {
	["puturnamehere"] = true,
}

local ALLOWED_GUI_NAMES = {
	["queuegui"] = true,
}

local SUSPICIOUS_NAMES = {
	["synapse"] = true,
	["krnl"] = true,
	["scriptware"] = true,
	["fluxus"] = true,
	["sirhurt"] = true,
	["dx9ware"] = true,
	["arceus"] = true,
	["vega"] = true,
	["oxygen"] = true,
	["inf yield"] = true,
	["infyield"] = true,
	["infinite yield"] = true,
	["protosmasher"] = true,
	["kavo"] = true,
	["jjsploit"] = true,
	["wearedevs"] = true,
	["c00lgui"] = true,
	["c00l gui"] = true,
	["coolgui"] = true,
	["cool gui"] = true,
	["c00lgui reborn"] = true,
	["reborn"] = true,
	["server destruction"] = true,
	["serverdestruction"] = true,
	["server destroy"] = true,
	["serverdestroy"] = true,
	["cmdx"] = true,
	["cmd-x"] = true,
	["cmdx gui"] = true,
	["cmdxgui"] = true,
	["darkdex"] = true,
	["dex"] = true,
	["dex explorer"] = true,
	["dexexplorer"] = true,
	["remote spy"] = true,
	["remotespy"] = true,
	["simplespy"] = true,
	["hydroxide"] = true,
	["hoarcekat"] = true,
	["iysploit"] = true,
	["v3rmillion"] = true,
	["v3rm"] = true,
	["rspy"] = true,
	["betterspy"] = true,
	["scriptblox"] = true,
	["scriptblox gui"] = true,
	["nameless"] = true,
	["nameless admin"] = true,
	["rayfield"] = true,
	["orion"] = true,
	["luna"] = true,
}

local SUSPICIOUS_BUTTON_NAMES = {
	["kill all"] = true,
	["killall"] = true,
	["fly"] = true,
	["noclip"] = true,
	["god mode"] = true,
	["godmode"] = true,
	["infinite jump"] = true,
	["explode all"] = true,
	["server wipe"] = true,
	["map wipe"] = true,
	["flood"] = true,
	["clear terrain"] = true,
	["clearterrain"] = true,
	["apoc troll"] = true,
	["apoctroll"] = true,
	["set skybox"] = true,
	["setskybox"] = true,
	["unanchor all"] = true,
	["unanchorall"] = true,
	["decal spam"] = true,
	["decalspam"] = true,
	["force teleport"] = true,
	["forceteleport"] = true,
	["kick all"] = true,
	["kickall"] = true,
	["x admin"] = true,
	["xadmin"] = true,
	["lag gui"] = true,
	["laggui"] = true,
	["create baseplate"] = true,
	["createbaseplate"] = true,
	["intimidation"] = true,
	["global message gui"] = true,
	["globalmessagegui"] = true,
	["server destruction"] = true,
	["serverdestruction"] = true,
	["server destroy"] = true,
	["silent executor"] = true,
	["silentexecutor"] = true,
	["nilzer"] = true,
	["johr"] = true,
	["scrub's admin"] = true,
	["scrubsadmin"] = true,
	["nexpluvia"] = true,
	["nexpluvia admin"] = true,
	["rspy"] = true,
	["remote spy"] = true,
	["remotespy"] = true,
}

local MAX_BUTTONS_IN_GUI = 50
local MAX_TEXTBOXES_IN_GUI = 10
local SUSPICIOUS_BUTTON_THRESHOLD = 2
local GUI_SCAN_INTERVAL = 5

local MAX_HEIGHT = 2500
local MAX_WALKSPEED = 100
local MAX_JUMPPOWER = 200
local MAX_MAXHEALTH = 500
local MAX_FLING_VELOCITY = 500
local HEALTH_TOLERANCE = 5
local KICK_MESSAGE = "Exploiting detected."
local RESTORE_COOLDOWN = 10
local USE_KICK = true
local USE_JEFF = true

local MapBackup = nil
local SkyBackup = nil
local IsRestoring = false
local LastRestore = 0
local HoneypotPart = nil

local function SendSystemMessage(text)
	pcall(function()
		local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
		if chatEvent then
			local messageEvent = chatEvent:FindFirstChild("OnMessageDoneFiltering")
			if messageEvent then
				messageEvent:FireAllClients({
					Message = text,
					FromSpeaker = "SERVER",
					SpeakerUserId = 0,
					OriginalFromSpeaker = "SERVER",
					OriginalSpeakerUserId = 0,
					MessageId = tostring(math.random(1, 1000000)),
					Channel = "RBXGeneral",
				})
			end
		end
	end)
end

local function LogTrigger(reason, player)
	local name = "Unknown"
	if player then
		name = player.Name
	end
	warn("[ANTICHEAT] " .. name .. " | " .. reason)
end

local function CreateHoneypot()
	if HoneypotPart and HoneypotPart.Parent then return end
	HoneypotPart = Instance.new("Part")
	HoneypotPart.Name = "AntiWipe_Honeypot_Part"
	HoneypotPart.Size = Vector3.new(1, 1, 1)
	HoneypotPart.Position = Vector3.new(0, 5000, 0)
	HoneypotPart.Anchored = true
	HoneypotPart.Transparency = 1
	HoneypotPart.CanCollide = false
	HoneypotPart.Parent = Workspace

	local tag = Instance.new("BoolValue")
	tag.Name = "BTR16AC_Honeypot"
	tag.Parent = HoneypotPart
end

local function FindSky()
	for _, child in pairs(Lighting:GetChildren()) do
		if child:IsA("Sky") then
			return child
		end
	end
	return nil
end

local function CreateBackups()
	MapBackup = Instance.new("Folder")
	MapBackup.Name = "MapBackup_Internal"
	MapBackup.Parent = ServerStorage

	for _, object in pairs(Workspace:GetChildren()) do
		if not object:IsA("Camera")
			and not object:IsA("Terrain")
			and not Players:GetPlayerFromCharacter(object)
			and object ~= script
			and object ~= HoneypotPart then
			pcall(function()
				local clone = object:Clone()
				if clone then
					clone.Parent = MapBackup
				end
			end)
		end
	end

	local sky = FindSky()
	if sky then
		SkyBackup = sky:Clone()
		SkyBackup.Name = "SkyBackup_Internal"
		SkyBackup.Parent = ServerStorage
	end
end

local function IsProtected(player)
	if not player then return true end
	if WHITELIST[player.Name] then return true end
	if player.UserId == game.CreatorId then return true end
	return false
end

local function KickPlayer(player, reason)
	if not USE_KICK then return end
	if IsProtected(player) then return end
	pcall(function()
		player:Kick(reason)
	end)
end

local function PlayJeff(player)
	if not USE_JEFF then return end
	if IsProtected(player) then return end
	local pgui = player:FindFirstChild("PlayerGui")
	if not pgui then return end
	local customJeff = ServerStorage:FindFirstChild("JEFF")
	if not customJeff then return end
	pcall(function()
		local screamClone = customJeff:Clone()
		screamClone.Parent = pgui
		Debris:AddItem(screamClone, 5)
	end)
end

local function IsSuspiciousName(name)
	if not name then return false end
	local lower = string.lower(name)
	return SUSPICIOUS_NAMES[lower] == true
end

local function IsSuspiciousButtonName(name)
	if not name then return false end
	local lower = string.lower(name)
	return SUSPICIOUS_BUTTON_NAMES[lower] == true
end

local function AnalyzeGui(gui)
	local buttonCount = 0
	local textboxCount = 0
	local suspiciousButtons = {}

	local function scan(object)
		if object:IsA("TextButton") or object:IsA("ImageButton") then
			buttonCount = buttonCount + 1
			local added = false
			if IsSuspiciousButtonName(object.Name) then
				table.insert(suspiciousButtons, object.Name)
				added = true
			end
			if not added and object.Text and IsSuspiciousButtonName(object.Text) then
				table.insert(suspiciousButtons, object.Text)
			end
		elseif object:IsA("TextBox") then
			textboxCount = textboxCount + 1
		end

		for _, child in pairs(object:GetChildren()) do
			scan(child)
		end
	end

	scan(gui)

	if #suspiciousButtons >= SUSPICIOUS_BUTTON_THRESHOLD then
		return "Suspicious buttons: " .. table.concat(suspiciousButtons, ", ")
	end

	if IsSuspiciousName(gui.Name) then
		return "Suspicious GUI name: " .. gui.Name
	end

	if buttonCount >= MAX_BUTTONS_IN_GUI then
		return "Too many buttons: " .. buttonCount
	end

	if textboxCount >= MAX_TEXTBOXES_IN_GUI then
		return "Too many textboxes: " .. textboxCount
	end

	return nil
end

local function ScanPlayerGui(player)
	if IsProtected(player) then return end
	local pgui = player:FindFirstChild("PlayerGui")
	if not pgui then return end

	local function scan(object)
		if object:IsA("ScreenGui") then
			if not ALLOWED_GUI_NAMES[object.Name] then
				local reason = AnalyzeGui(object)
				if reason then
					LogTrigger("Illegal GUI: " .. reason, player)
					PlayJeff(player)
					pcall(function()
						object:Destroy()
					end)
					KickPlayer(player, KICK_MESSAGE)
					return true
				end
			end
		end

		for _, child in pairs(object:GetChildren()) do
			if scan(child) then
				return true
			end
		end
		return false
	end

	scan(pgui)
end

local function RestoreEverything()
	if IsRestoring then return end
	local now = os.time()
	if now - LastRestore < RESTORE_COOLDOWN then return end
	LastRestore = now
	IsRestoring = true

	local oldHoneypot = HoneypotPart

	local ok, err = pcall(function()
		for _, object in pairs(Workspace:GetChildren()) do
			if object ~= oldHoneypot
				and object ~= script
				and not object:IsA("Camera")
				and not object:IsA("Terrain")
				and not Players:GetPlayerFromCharacter(object) then
				pcall(function()
					object:Destroy()
				end)
			end
		end

		for _, object in pairs(Lighting:GetChildren()) do
			if object:IsA("Sky") then
				pcall(function()
					object:Destroy()
				end)
			end
		end

		if MapBackup then
			for _, backupObject in pairs(MapBackup:GetChildren()) do
				pcall(function()
					local clone = backupObject:Clone()
					clone.Parent = Workspace
				end)
			end
		end

		if SkyBackup then
			pcall(function()
				local skyClone = SkyBackup:Clone()
				skyClone.Parent = Lighting
			end)
		end
	end)

	if oldHoneypot and oldHoneypot.Parent then
		pcall(function()
			oldHoneypot:Destroy()
		end)
	end

	HoneypotPart = nil
	CreateHoneypot()

	for _, player in pairs(Players:GetPlayers()) do
		pcall(function()
			player:LoadCharacter()
		end)
	end
	
	IsRestoring = false

	if not ok then
		warn("[ANTICHEAT] Restore failed: " .. tostring(err))
	end
end

CreateHoneypot()
CreateBackups()

SendSystemMessage("[SERVER] : BTR16AC LOADED any cheating is not allowed any attempt to cheat will be restricted and exploiter will be screamed")

Workspace.ChildRemoved:connect(function(child)
	if IsRestoring then return end
	if child == HoneypotPart then
		LogTrigger("Honeypot destroyed (Map Wipe Attempt)")
		RestoreEverything()
		return
	end
	if child:FindFirstChild("BTR16AC_Honeypot") then
		LogTrigger("Honeypot destroyed (Map Wipe Attempt)")
		RestoreEverything()
	end
end)

Players.PlayerAdded:connect(function(player)
	player:WaitForChild("PlayerGui", 10)

	local pguiConnections = {}

	table.insert(pguiConnections, player.PlayerGui.ChildAdded:connect(function(child)
		if IsRestoring then return end
		if IsProtected(player) then return end
		if child:IsA("Message") then return end
		if child:IsA("Hint") then return end
		if child:IsA("ScreenGui") == false then
			if not child:IsA("Folder") then return end
		end
		if ALLOWED_GUI_NAMES[child.Name] then return end

		spawn(function()
			wait(0.1)
			ScanPlayerGui(player)
		end)
	end))

	table.insert(pguiConnections, player.PlayerGui.DescendantAdded:connect(function(desc)
		if IsRestoring then return end
		if IsProtected(player) then return end
		if not desc:IsA("TextButton")
			and not desc:IsA("ImageButton")
			and not desc:IsA("TextBox") then
			return
		end

		spawn(function()
			wait(0.1)
			ScanPlayerGui(player)
		end)
	end))

	table.insert(pguiConnections, Players.PlayerRemoving:connect(function(leaving)
		if leaving == player then
			for _, c in pairs(pguiConnections) do
				pcall(function()
					c:Disconnect()
				end)
			end
			pguiConnections = {}
		end
	end))

	player.CharacterAdded:connect(function(character)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not root then return end
		local hum = character:WaitForChild("Humanoid", 10)
		if not hum then return end

		local lastPosition = root.Position
		local connections = {}

		if hum.Health > hum.MaxHealth + HEALTH_TOLERANCE then
			LogTrigger("Godmode (Health > MaxHealth): " .. hum.Health, player)
			PlayJeff(player)
			KickPlayer(player, KICK_MESSAGE)
			return
		end

		local function cleanupConnections()
			for _, c in pairs(connections) do
				pcall(function()
					c:Disconnect()
				end)
			end
			connections = {}
		end

		table.insert(connections, hum.Changed:connect(function(property)
			if property == "Health" then
				if hum.Health > hum.MaxHealth + HEALTH_TOLERANCE then
					LogTrigger("Godmode: " .. hum.Health, player)
					PlayJeff(player)
					KickPlayer(player, KICK_MESSAGE)
				end
			elseif property == "WalkSpeed" then
				if hum.WalkSpeed > MAX_WALKSPEED then
					LogTrigger("WalkSpeed: " .. hum.WalkSpeed, player)
					PlayJeff(player)
					KickPlayer(player, KICK_MESSAGE)
				end
			elseif property == "JumpPower" then
				if hum.JumpPower > MAX_JUMPPOWER then
					LogTrigger("JumpPower: " .. hum.JumpPower, player)
					PlayJeff(player)
					KickPlayer(player, KICK_MESSAGE)
				end
			elseif property == "MaxHealth" then
				if hum.MaxHealth > MAX_MAXHEALTH then
					LogTrigger("MaxHealth: " .. hum.MaxHealth, player)
					PlayJeff(player)
					KickPlayer(player, KICK_MESSAGE)
				end
			end
		end))

		table.insert(connections, hum.StateChanged:connect(function(oldState, newState)
			if newState == Enum.HumanoidStateType.Flying then
				LogTrigger("Illegal State: Flying", player)
				PlayJeff(player)
				KickPlayer(player, KICK_MESSAGE)
			end
		end))

		table.insert(connections, hum.Died:connect(function()
			cleanupConnections()
		end))

		table.insert(connections, character.AncestryChanged:connect(function()
			if not character:IsDescendantOf(Workspace) then
				cleanupConnections()
			end
		end))

		while character.Parent
			and root.Parent
			and hum.Health > 0
			and character:IsDescendantOf(Workspace) do
			wait(0.5)

			if IsRestoring then break end

			local currentPosition = root.Position
			local distance = (currentPosition - lastPosition).magnitude
			local allowedDistance = (hum.WalkSpeed * 0.5) + 30

			local horizontalVelocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z).magnitude
			if horizontalVelocity > MAX_FLING_VELOCITY then
				LogTrigger("Fling: " .. math.floor(horizontalVelocity), player)
				PlayJeff(player)
				KickPlayer(player, KICK_MESSAGE)
				break
			end

			if distance > allowedDistance and hum.FloorMaterial ~= Enum.Material.Air then
				LogTrigger("Speedhack/Teleport: " .. math.floor(distance), player)
				PlayJeff(player)
				KickPlayer(player, KICK_MESSAGE)
				break
			end

			if currentPosition.Y > MAX_HEIGHT then
				LogTrigger("Flyhack: " .. math.floor(currentPosition.Y), player)
				PlayJeff(player)
				KickPlayer(player, KICK_MESSAGE)
				break
			end

			if currentPosition.Y - lastPosition.Y > 500 then
				LogTrigger("Vertical Teleport: " .. math.floor(currentPosition.Y - lastPosition.Y), player)
				PlayJeff(player)
				KickPlayer(player, KICK_MESSAGE)
				break
			end

			lastPosition = currentPosition
		end

		cleanupConnections()
	end)
end)

spawn(function()
	while wait(GUI_SCAN_INTERVAL) do
		for _, player in pairs(Players:GetPlayers()) do
			pcall(function()
				ScanPlayerGui(player)
			end)
		end
	end
end)
