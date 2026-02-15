local character = script.Parent
local primaryPart = character.PrimaryPart or character:WaitForChild("HumanoidRootPart")

-- Wait for sounds named "Jumping" and "Running" inside the primaryPart
local jumpingSound = primaryPart:WaitForChild("Jumping", 5)  -- Wait up to 5 seconds
local runningSound = primaryPart:WaitForChild("Running", 5)

for _,v in character:WaitForChild('HumanoidRootPart'):GetDescendants() do 
	if v:IsA("Sound") then
		v:Stop() 
		v:Destroy()
	end
end

if jumpingSound and runningSound then
	jumpingSound.Volume = 0
	runningSound.Volume = 0
else
	warn("Jumping or Running sound not found in PrimaryPart")
end
