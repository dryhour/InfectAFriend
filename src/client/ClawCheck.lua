local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character

local rs = game:GetService("ReplicatedStorage")
local clawsRemote = rs:WaitForChild("clawsRemote")

local tagger_conn
local already_checked = false

local function bindTagValues(tag_values)
	if tagger_conn then
		tagger_conn:Disconnect()
		tagger_conn = nil
	end
	
	-- print("checking")

	local tagger = tag_values:WaitForChild("tagger")
	
	-- print("founded")

	if tagger.Value then
		already_checked = true
		clawsRemote:FireServer(true)
	else
		already_checked = false
		clawsRemote:FireServer(false)
	end

	tagger_conn = tagger.Changed:Connect(function(value)
		if value and not already_checked then
			-- print("claws")
			already_checked = true
			-- print("fired")
			clawsRemote:FireServer(true)
		elseif not value and already_checked then
			-- print("no claws")
			already_checked = false
			clawsRemote:FireServer(false)
		end
	end)
end

local existing = character:FindFirstChild("tag_values")
if existing then
	bindTagValues(existing)
end

character.ChildAdded:Connect(function(item)
	-- print(item)
	if item.Name == "tag_values" then
		bindTagValues(item)
	end
end)

character.ChildRemoved:Connect(function(item)
	if item.Name == "tag_values" then
		if tagger_conn then
			tagger_conn:Disconnect()
			tagger_conn = nil
		end
		already_checked = false
		clawsRemote:FireServer(false)
	end
end)
