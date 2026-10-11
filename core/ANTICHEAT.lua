local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local WHITELIST_NAMES = {
	["puturnamehere"] = true,
}

local WHITELIST_IDS = {
	[0] = true,
}

local ALLOWED_GUI_NAMES = {
	["queuegui"] = true,
}

local TRUSTED_GUI_TAG = "BTR16AC_Trusted"
local NO_RESTORE_TAG = "BTR16AC_NoRestore"
local HOOKED_TAG = "BTR16AC_Hooked"

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
local SUSPICIOUS_BUTTON_THRESHOLD = 4
local GUI_SCAN_INTERVAL = 5
local GUI_SCAN_DEBOUNCE = 1.5

local MAX_HEIGHT_OFFSET = 2500
local MAX_WALKSPEED = 100
local MAX_JUMPPOWER = 200
local MAX_MAXHEALTH = 500
local MAX_FLING_VELOCITY = 500
local HEALTH_TOLERANCE = 5
local KICK_MESSAGE = "Exploiting detected."
local RESTORE_COOLDOWN = 10
local USE_KICK = true
local USE_JEFF = true

local MAX_HORIZONTAL_SPEED = 500
local MAX_VERTICAL_RISE = 400
local MOVEMENT_CHECK_INTERVAL = 0.25

local REMOTE_RATE_LIMIT = 30
local REMOTE_RATE_WINDOW = 1
local REMOTE_KICK_THRESHOLD = 5

local MAX_BACKUP_DESCENDANTS = 5000
local MAX_BACKUP_DESCENDANTS_PER_CHILD = 2000

local MASS_REMOVAL_WINDOW = 5
local MASS_REMOVAL_THRESHOLD = 20
local FULL_WIPE_THRESHOLD = 0.5

local MapBackup = nil
local SkyBackup = nil
local IsRestoring = false
local LastRestore = 0
local HoneypotPart = nil
local ActiveCharacters = {}
local BackupByPath = {}
local BackupByObject = setmetatable({}, {__mode = "k"})
local InitialObjectCount = 0

local LastGuiScan = setmetatable({}, {__mode = "k"})
local RemoteRateData = {}
local RemoteHooked = setmetatable({}, {__mode = "k"})

local RemovedCount = 0
local RemovedWindow = 0

local function GetFullPath(object)
	local ancestors = {}
	local current = object.Parent
	while current and current ~= game do
		table.insert(ancestors, current)
		if current == Workspace then break end
		current = current.Parent
	end

	if #ancestors == 0 then
		return nil
	end

	local path = object.Name
	for i = 1, #ancestors do
		path = ancestors[i].Name .. "." .. path
	end
	return path
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
	local names = {"Part", "SpawnLocation", "Model", "Block", "Base"}
	local chosenName = names[math.random(1, #names)]
	HoneypotPart = Instance.new("Part")
	HoneypotPart.Name = chosenName
	HoneypotPart.Size = Vector3.new(4, 1, 2)
	HoneypotPart.Position = Vector3.new(math.random(-500, 500), 5000, math.random(-500, 500))
	HoneypotPart.Anchored = true
	HoneypotPart.Transparency = 0
	HoneypotPart.CanCollide = true
	HoneypotPart.BrickColor = BrickColor.new("Medium stone grey")
	HoneypotPart.Material = Enum.Material.Plastic
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

local function RegisterBackup(object, clone, path)
	if not clone then return end
	BackupByObject[object] = clone
	if path then
		BackupByPath[path] = clone
	end
end

local function CreateBackups()
	MapBackup = Instance.new("Folder")
	MapBackup.Name = "MapBackup_Internal"
	MapBackup.Parent = ServerStorage

	BackupByPath = {}
	BackupByObject = setmetatable({}, {__mode = "k"})

	local count = 0
	for _, object in pairs(Workspace:GetChildren()) do
		if not object:IsA("Camera")
			and not object:IsA("Terrain")
			and not Players:GetPlayerFromCharacter(object)
			and object ~= script
			and object ~= HoneypotPart then
			count = count + 1
			pcall(function()
				local descendants = object:GetDescendants()
				if #descendants > MAX_BACKUP_DESCENDANTS then
					return
				end
				local clone = object:Clone()
				if clone then
					clone.Parent = MapBackup
					RegisterBackup(object, clone, "Workspace." .. object.Name)
					local subCount = 0
					for _, descendant in pairs(object:GetDescendants()) do
						if subCount >= MAX_BACKUP_DESCENDANTS_PER_CHILD then break end
						subCount = subCount + 1
						local descPath = GetFullPath(descendant)
						if descPath then
							pcall(function()
								local descClone = descendant:Clone()
								if descClone then
									BackupByObject[descendant] = descClone
									BackupByPath[descPath] = descClone
								end
							end)
						end
					end
				end
			end)
		end
	end
	InitialObjectCount = count

	local sky = FindSky()
	if sky then
		SkyBackup = sky:Clone()
		SkyBackup.Name = "SkyBackup_Internal"
		SkyBackup.Parent = ServerStorage
	end
end

local function IsProtected(player)
	if not player then return true end
	if WHITELIST_NAMES[player.Name] then return true end
	if WHITELIST_IDS[player.UserId] then return true end
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then return true end
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
				if object:FindFirstChild(TRUSTED_GUI_TAG) then
					return false
				end
				local now = tick()
				if LastGuiScan[object] and now - LastGuiScan[object] < GUI_SCAN_DEBOUNCE then
					return false
				end
				LastGuiScan[object] = now
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

local function RestoreByPath(path)
	if not path then return false end
	local backup = BackupByPath[path]
	if backup then
		pcall(function()
			local clone = backup:Clone()
			clone.Parent = Workspace
		end)
		return true
	end
	return false
end

local function RestoreSingleObject(object, path)
	if not object then return false end
	if object:FindFirstChild(NO_RESTORE_TAG) then return false end
	local backup = BackupByObject[object]
	if backup then
		pcall(function()
			local clone = backup:Clone()
			clone.Parent = Workspace
		end)
		return true
	end
	if path then
		return RestoreByPath(path)
	end
	return false
end

local function CountCurrentWorkspaceObjects()
	local count = 0
	for _, obj in pairs(Workspace:GetChildren()) do
		if not obj:IsA("Camera")
			and not obj:IsA("Terrain")
			and not Players:GetPlayerFromCharacter(obj)
			and obj ~= script then
			count = count + 1
		end
	end
	return count
end

local function RestoreHoneypotOnly()
	if HoneypotPart and HoneypotPart.Parent then return end
	HoneypotPart = nil
	CreateHoneypot()
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

local function SetupCharacter(player, character)
	if ActiveCharacters[player] then
		pcall(function()
			ActiveCharacters[player].disconnect()
		end)
		ActiveCharacters[player] = nil
	end

	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then return end
	local hum = character:WaitForChild("Humanoid", 10)
	if not hum then return end

	local lastPosition = root.Position
	local lastTime = tick()
	local connections = {}
	local stopped = false

	if not IsProtected(player) and hum.Health > hum.MaxHealth + HEALTH_TOLERANCE then
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
		if stopped then return end
		if IsProtected(player) then return end
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
		if stopped then return end
		if IsProtected(player) then return end
		if newState == Enum.HumanoidStateType.Flying then
			if not hum.PlatformStand and hum.FloorMaterial == Enum.Material.Air then
				LogTrigger("Illegal State: Flying", player)
				PlayJeff(player)
				KickPlayer(player, KICK_MESSAGE)
			end
		end
	end))

	table.insert(connections, hum.Died:connect(function()
		stopped = true
		cleanupConnections()
	end))

	table.insert(connections, character.AncestryChanged:connect(function()
		if not character:IsDescendantOf(Workspace) then
			stopped = true
			cleanupConnections()
		end
	end))

	local disconnectFunc = function()
		stopped = true
		cleanupConnections()
	end
	ActiveCharacters[player] = {disconnect = disconnectFunc}

	spawn(function()
		while not stopped
			and character.Parent
			and root.Parent
			and hum.Health > 0
			and character:IsDescendantOf(Workspace) do
			wait(MOVEMENT_CHECK_INTERVAL)

			if IsRestoring or stopped then break end
			if IsProtected(player) then
				lastPosition = root.Position
				lastTime = tick()
			else
				local currentTime = tick()
				local dt = currentTime - lastTime
				if dt <= 0 then dt = MOVEMENT_CHECK_INTERVAL end

				local currentPosition = root.Position
				local distance = (currentPosition - lastPosition).magnitude

				local horizontalVelocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z).magnitude
				local verticalRise = (currentPosition.Y - lastPosition.Y) / dt
				local state = hum:GetState()

				if horizontalVelocity > MAX_FLING_VELOCITY then
					LogTrigger("Fling: " .. math.floor(horizontalVelocity), player)
					PlayJeff(player)
					KickPlayer(player, KICK_MESSAGE)
					break
				end

				local onGround = hum.FloorMaterial ~= Enum.Material.Air and hum.FloorMaterial ~= Enum.Material.Water

				if onGround
					and state ~= Enum.HumanoidStateType.Seated
					and state ~= Enum.HumanoidStateType.Physics then
					local maxAllowedDistance = (hum.WalkSpeed * dt * 1.5) + 5
					if distance > maxAllowedDistance then
						LogTrigger("Speedhack/Teleport: " .. math.floor(distance / dt) .. " studs/s", player)
						PlayJeff(player)
						KickPlayer(player, KICK_MESSAGE)
						break
					end
					if horizontalVelocity > MAX_HORIZONTAL_SPEED then
						LogTrigger("Horizontal Speed: " .. math.floor(horizontalVelocity), player)
						PlayJeff(player)
						KickPlayer(player, KICK_MESSAGE)
						break
					end
				end

				local maxHeight = Workspace.FallenPartsDestroyHeight + MAX_HEIGHT_OFFSET
				if maxHeight < 2500 then maxHeight = 2500 end
				if currentPosition.Y > maxHeight then
					LogTrigger("Flyhack: " .. math.floor(currentPosition.Y), player)
					PlayJeff(player)
					KickPlayer(player, KICK_MESSAGE)
					break
				end

				if verticalRise > MAX_VERTICAL_RISE
					and not onGround
					and not hum.PlatformStand
					and state ~= Enum.HumanoidStateType.Jumping
					and state ~= Enum.HumanoidStateType.Freefall then
					LogTrigger("Vertical Teleport: " .. math.floor(verticalRise) .. " studs/s", player)
					PlayJeff(player)
					KickPlayer(player, KICK_MESSAGE)
					break
				end

				lastPosition = currentPosition
				lastTime = currentTime
			end
		end

		if ActiveCharacters[player] and ActiveCharacters[player].disconnect == disconnectFunc then
			ActiveCharacters[player] = nil
		end
	end)
end

local function CleanMessagesAndHints(parent)
	local children = parent:GetChildren()
	for i = 1, #children do
		local v = children[i]
		if v:IsA("Message") or v:IsA("Hint") then
			pcall(function()
				v:Destroy()
			end)
		elseif #v:GetChildren() > 0 then
			CleanMessagesAndHints(v)
		end
	end
end

local function ScanForMessagesInPlayerGui(player)
	local pgui = player:FindFirstChild("PlayerGui")
	if not pgui then return end
	CleanMessagesAndHints(pgui)
end

local function KillMessageOrHint(instance)
	if not instance then return false end
	if instance:IsA("Message") or instance:IsA("Hint") then
		spawn(function()
			wait(1)
			if instance then
				pcall(function()
					instance:Destroy()
				end)
			end
		end)
		return true
	end
	return false
end

Players.PlayerAdded:connect(function(player)
	local pgui = player:WaitForChild("PlayerGui", 10)
	if not pgui then return end

	player.CharacterAdded:connect(function(character)
		SetupCharacter(player, character)
	end)

	if player.Character then
		spawn(function()
			SetupCharacter(player, player.Character)
		end)
	end

	local pguiConnections = {}
	local removed = false

	table.insert(pguiConnections, pgui.ChildAdded:connect(function(child)
		if removed then return end
		if IsRestoring then return end
		if IsProtected(player) then return end
		if KillMessageOrHint(child) then return end
		if not child:IsA("ScreenGui")
			and not child:IsA("BillboardGui")
			and not child:IsA("SurfaceGui")
			and not child:IsA("Folder") then
			return
		end
		if ALLOWED_GUI_NAMES[child.Name] then return end

		spawn(function()
			wait(0.1)
			if removed then return end
			ScanPlayerGui(player)
		end)
	end))

	table.insert(pguiConnections, pgui.DescendantAdded:connect(function(desc)
		if removed then return end
		if IsRestoring then return end
		if IsProtected(player) then return end
		if KillMessageOrHint(desc) then return end
		if not desc:IsA("TextButton")
			and not desc:IsA("ImageButton")
			and not desc:IsA("TextBox") then
			return
		end

		spawn(function()
			wait(0.1)
			if removed then return end
			ScanPlayerGui(player)
		end)
	end))

	local removeConn
	removeConn = Players.PlayerRemoving:connect(function(leaving)
		if leaving == player then
			removed = true
			for _, c in pairs(pguiConnections) do
				pcall(function()
					c:Disconnect()
				end)
			end
			pguiConnections = {}
			if ActiveCharacters[player] then
				pcall(function()
					ActiveCharacters[player].disconnect()
				end)
				ActiveCharacters[player] = nil
			end
			RemoteRateData[player] = nil
			if removeConn then
				removeConn:Disconnect()
			end
		end
	end)
end)

Workspace.DescendantAdded:connect(function(desc)
	KillMessageOrHint(desc)
end)

Workspace.DescendantRemoving:connect(function(desc)
	if IsRestoring then return end

	local path = GetFullPath(desc)

	if desc == HoneypotPart then
		LogTrigger("Honeypot destroyed - restoring honeypot only")
		spawn(function()
			wait(0.1)
			RestoreHoneypotOnly()
		end)
		return
	end

	if desc:FindFirstChild("BTR16AC_Honeypot") then
		LogTrigger("Honeypot destroyed - restoring honeypot only")
		spawn(function()
			wait(0.1)
			RestoreHoneypotOnly()
		end)
		return
	end

	if desc.Parent == Workspace
		and not desc:IsA("Camera")
		and not desc:IsA("Terrain")
		and not Players:GetPlayerFromCharacter(desc) then
		local now = tick()
		if now - RemovedWindow > MASS_REMOVAL_WINDOW then
			RemovedCount = 0
			RemovedWindow = now
		end
		RemovedCount = RemovedCount + 1

		local currentCount = CountCurrentWorkspaceObjects()
		if InitialObjectCount > 0 and currentCount < InitialObjectCount * FULL_WIPE_THRESHOLD then
			LogTrigger("Full map wipe detected: " .. currentCount .. "/" .. InitialObjectCount)
			RemovedCount = 0
			RestoreEverything()
			return
		end

		if RemovedCount > MASS_REMOVAL_THRESHOLD then
			LogTrigger("Mass object removal: " .. RemovedCount .. " objects")
			RemovedCount = 0
		end

		if not desc:FindFirstChild(NO_RESTORE_TAG) then
			spawn(function()
				wait(0.1)
				if not desc.Parent then
					RestoreSingleObject(desc, path)
				end
			end)
		end
	end
end)

local function HookRemote(remote)
	if not remote:IsA("RemoteEvent") then return end
	if RemoteHooked[remote] then return end
	RemoteHooked[remote] = true
	local tag = Instance.new("BoolValue")
	tag.Name = HOOKED_TAG
	tag.Parent = remote

	remote.OnServerEvent:connect(function(player, ...)
		if IsProtected(player) then return end
		local now = tick()
		local data = RemoteRateData[player]
		if not data then
			data = {remotes = {}}
			RemoteRateData[player] = data
		end
		local remoteData = data.remotes[remote]
		if not remoteData then
			remoteData = {count = 0, window = now, flagged = 0}
			data.remotes[remote] = remoteData
		end
		if now - remoteData.window > REMOTE_RATE_WINDOW then
			remoteData.count = 0
			remoteData.window = now
		end
		remoteData.count = remoteData.count + 1
		if remoteData.count > REMOTE_RATE_LIMIT then
			remoteData.flagged = remoteData.flagged + 1
			if remoteData.flagged >= REMOTE_KICK_THRESHOLD then
				LogTrigger("Remote spam: " .. remote.Name .. " " .. remoteData.count .. " calls", player)
				PlayJeff(player)
				KickPlayer(player, KICK_MESSAGE)
			end
		end
	end)
end

local function ScanRemotes(parent)
	for _, obj in pairs(parent:GetChildren()) do
		pcall(function()
			if obj:IsA("RemoteEvent") then
				HookRemote(obj)
			end
			if #obj:GetChildren() > 0 then
				ScanRemotes(obj)
			end
		end)
	end
end

ReplicatedStorage.DescendantAdded:connect(function(desc)
	if desc:IsA("RemoteEvent") then
		HookRemote(desc)
	end
end)

spawn(function()
	ScanRemotes(ReplicatedStorage)
end)

spawn(function()
	while wait(GUI_SCAN_INTERVAL) do
		for _, player in pairs(Players:GetPlayers()) do
			pcall(function()
				ScanPlayerGui(player)
				ScanForMessagesInPlayerGui(player)
			end)
		end
	end
end)

CreateHoneypot()
CreateBackups()
CleanMessagesAndHints(Workspace)
