local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local tagger_gui = script.Parent:WaitForChild("TaggerGui")

-- Initial state
tagger_gui.Enabled = false
tagger_gui.Tagger.Visible = false
tagger_gui.Runner.Visible = false
tagger_gui.TaggerScreen.Visible = false

RunService.RenderStepped:Connect(function()
	local character = player.Character
	if not character then
		tagger_gui.Enabled = false
		return
	end

	local tagger_values = character:FindFirstChild("tag_values")
	if not tagger_values or not tagger_values:FindFirstChild("tagger") then
		tagger_gui.Enabled = false
		return
	end

	tagger_gui.Enabled = true

	local isTagger = tagger_values.tagger.Value
	tagger_gui.Tagger.Visible = isTagger
	tagger_gui.TaggerScreen.Visible = isTagger
	tagger_gui.Runner.Visible = not isTagger
end)

local ss = game:GetService('SoundService')
tagger_gui.Changed:Connect(function()
	if tagger_gui.Enabled == false then
		ss.ui_sounds.heartbeat:Stop()
	end
end)
tagger_gui.Tagger.Changed:Connect(function()
	if tagger_gui.Tagger.Visible == true then
		ss.ui_sounds.roar:Play()
		ss.ui_sounds.heartbeat:Play()
	else
		ss.ui_sounds.heartbeat:Stop()
	end
end)
