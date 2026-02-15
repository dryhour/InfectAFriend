local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local musicFolder = SoundService:WaitForChild("music")
local battleFolder = SoundService:WaitForChild("battlemusic")
local inGameValue = ReplicatedStorage:WaitForChild("InGame")
local finisherValue = ReplicatedStorage:WaitForChild("FinisherBeingUsed")

local eventMusicFolder = workspace:WaitForChild("eventmusic")

local currentSound = Instance.new("Sound")
currentSound.Parent = SoundService
currentSound.Volume = 0
currentSound.Looped = false

local TARGET_VOLUME = 0.25
local TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Tween volume utility
local function tweenVolume(sound, goalVolume)
	local tween = TweenService:Create(sound, TWEEN_INFO, { Volume = goalVolume })
	tween:Play()
	tween.Completed:Wait()
end

-- Play a new random track from a folder
local function playRandomTrack(folder)
	local tracks = folder:GetChildren()
	if #tracks == 0 then
		warn("No tracks in folder:", folder.Name)
		return
	end

	if currentSound.IsPlaying then
		tweenVolume(currentSound, 0)
		currentSound:Stop()
	end

	local chosen = tracks[math.random(1, #tracks)]
	currentSound.SoundId = chosen.SoundId
	currentSound:Play()
	tweenVolume(currentSound, TARGET_VOLUME)
end

-- Mute all sounds in a folder
local function muteAll(folder)
	for _, sound in ipairs(folder:GetChildren()) do
		if sound:IsA("Sound") then
			if sound.IsPlaying then
				TweenService:Create(sound, TWEEN_INFO, { Volume = 0 }):Play()
			end
		end
	end

	-- Also mute current playing sound
	if currentSound.IsPlaying then
		tweenVolume(currentSound, 0)
	end
end

-- Music control loop
task.spawn(function()
	while true do
		if not finisherValue.Value then
			local folder = inGameValue.Value and battleFolder or musicFolder
			playRandomTrack(folder)

			-- Wait between 10–25 seconds or break on InGame change
			local delay = math.random(10, 25)
			local startTime = tick()

			local connection
			connection = inGameValue.Changed:Connect(function()
				connection:Disconnect()
				startTime = 0 -- break the loop
			end)

			while tick() - startTime < delay do
				if finisherValue.Value then
					break
				end
				task.wait(1)
			end

			if connection.Connected then
				connection:Disconnect()
			end
		else
			muteAll(musicFolder)
			muteAll(battleFolder)
			muteAll(eventMusicFolder)
			task.wait(1) -- check again in 1 second
		end
	end
end)
