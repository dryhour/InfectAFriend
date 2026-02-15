local Players = game:GetService("Players")
local rs = game:GetService('ReplicatedStorage')

local function attachWithWeld(model, limb, offset)
	offset = offset or CFrame.new()

	local primary = model.PrimaryPart
	model:PivotTo(limb.CFrame * offset)

	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.Massless = true
		end
	end

	local weld = Instance.new("Weld")
	weld.Part0 = limb
	weld.Part1 = primary
	weld.C0 = limb.CFrame:ToObjectSpace(primary.CFrame)
	weld.Parent = primary
end

local function setAnchor(model, bool)
	for i, part in ipairs(model:GetChildren()) do
		part.Anchored = bool
	end
end

local claws_fx = workspace.ClawFx
local function removeClaws(character)
	local player_folder = claws_fx:FindFirstChild(character.Name)
	if player_folder then
		for i, claw in ipairs(player_folder:GetChildren()) do
			if claw.Name == "Claws" then
				claw:Destroy()
			end
		end
	end
end

local function createClaws(character, equipped)
	if equipped == "" then equipped = "def" end
	local claws = rs:WaitForChild("Claws")
	local left = claws[equipped]:Clone()
	local right = claws[equipped]:Clone()
	
	-- print("creating claws")

	local player_folder = claws_fx:FindFirstChild(character.Name)
	if not player_folder then
		player_folder = Instance.new("Folder")
		player_folder.Name = character.Name
		player_folder.Parent = claws_fx
	end
	left.Name = "Claws"
	right.Name = "Claws"

	setAnchor(left, false)
	setAnchor(right, false)

	left.Parent = player_folder
	right.Parent = player_folder

	local leftArm   = character:FindFirstChild("Left Arm") or character:FindFirstChild("LeftHand") or character:FindFirstChild("LeftUpperArm")
	local rightArm  = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand") or character:FindFirstChild("RightUpperArm")

	if not (leftArm and rightArm) then
		warn("Couldn't find arms on this rig (R6 vs R15?).")
		return
	end

	attachWithWeld(left,  leftArm,  CFrame.new(0, -0.5, -0.25) * CFrame.Angles(math.rad(-90), 0, 0))
	attachWithWeld(right, rightArm, CFrame.new(0, -0.5, -0.25) * CFrame.Angles(math.rad(-90), 0, 0))
end

local updateClaws = rs.updateClaws
updateClaws.OnServerEvent:Connect(function(plr, clawname, equipping)
	local hidden_leaderstats = plr and plr:FindFirstChild("hidden_leaderstats")
	local equippedClaw = hidden_leaderstats and hidden_leaderstats:FindFirstChild("EquippedClaw")
	local ownedClaws = hidden_leaderstats and hidden_leaderstats:FindFirstChild("OwnedClaws")
	
	equippedClaw.Value = clawname
	
	if not equipping then
		local list = ownedClaws.Value
		if list == "" then
			ownedClaws.Value = clawname .. "1"
		else
			local parts = {}
			local found = false

			for entry in string.gmatch(list, "([^|]+)") do
				local name, count = entry:match("^(%a+)(%d+)$")
				if name == clawname then
					count = tonumber(count) + 1
					entry = name .. count
					found = true
				end
				table.insert(parts, entry)
			end

			if not found then
				table.insert(parts, clawname .. "1")
			end

			ownedClaws.Value = table.concat(parts, "|")
		end
	end
end)

local clawsRemote = rs.clawsRemote
clawsRemote.OnServerEvent:Connect(function(plr, added)
	-- print("called")
	local char = plr.Character
	if not char then return end
	
	-- print("passed char check")

	local hls = plr:FindFirstChild("hidden_leaderstats")
	if not hls then return end
	
	-- print("passed hidden check")

	local equippedClaw = hls:FindFirstChild("EquippedClaw")
	
	-- print(equippedClaw)

	if added then
		if not equippedClaw then return end
		local clawName = equippedClaw.Value ~= "" and equippedClaw.Value or "def"
		createClaws(char, clawName)
	else
		removeClaws(char)
	end
end)