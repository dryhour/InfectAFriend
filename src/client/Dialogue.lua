local folder = script.Parent -- Folder containing your trigger parts
local rs = game:GetService("ReplicatedStorage")
local event = rs:WaitForChild("ShowUI")

local dialogueSound = game:GetService('SoundService'):WaitForChild('ui_sounds'):WaitForChild("text")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local DialogueTemplate = rs:WaitForChild("DialogueGUI")
local SellDisplay = rs:WaitForChild("SellGUI")

local function tweenTransparency(label, targetTransparency, duration)
	local textTween = TweenService:Create(label, TweenInfo.new(duration), {
		TextTransparency = targetTransparency
	})
	
	local backTween = TweenService:Create(label, TweenInfo.new(duration), {
		BackgroundTransparency = targetTransparency
	})

	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		local strokeTween = TweenService:Create(stroke, TweenInfo.new(duration), {
			Transparency = targetTransparency
		})
		strokeTween:Play()
	end

	textTween:Play()
	backTween:Play()
end

local function typeTextRich(label, fullText, delayPerLetter)
	label.RichText = true
	label.Text = ""

	if dialogueSound and dialogueSound:IsA("Sound") then
		dialogueSound:Play()
	end

	-- Try to split at the first <font> tag
	local splitStart = fullText:find("<font")
	if not splitStart then
		-- No rich text: fallback to plain typing
		for i = 1, #fullText do
			if dialogueSound then
				dialogueSound:Play()
			end
			label.Text = string.sub(fullText, 1, i)
			task.wait(delayPerLetter)
		end
	else
		local baseText = string.sub(fullText, 1, splitStart - 1)
		local richText = string.sub(fullText, splitStart)

		-- Animate the baseText only
		for i = 1, #baseText do
			label.Text = string.sub(baseText, 1, i)
			if dialogueSound then
				dialogueSound:Play()
			end
			task.wait(delayPerLetter)
		end

		-- Append the styled text
		label.Text = baseText .. richText
	end

	-- Tween to transparency after a short delay
	task.delay(0.8, function()
		tweenTransparency(label, 1, 1) -- Fade to 100% transparent over 1 second
	end)

	if dialogueSound then
		dialogueSound:Stop()
	end
end


local activeUI = {
	SellGUI = nil,
	SellAnchor = nil,
	NPCDialogue = nil,
	PlayerDialogue = nil,
	Highlight = nil
}

local Dialogue = {}

function Dialogue:NPC(model, text)
	if activeUI.NPCDialogue then activeUI.NPCDialogue:Destroy() end
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if not root then return end

	local gui = DialogueTemplate:Clone()
	gui.Adornee = root
	gui.Parent = model
	gui.Enabled = true

	local frame = gui:FindFirstChild("Frame")
	local label = frame and frame:FindFirstChildWhichIsA("TextLabel")
	if label then typeTextRich(label, text, 0.05) end
	activeUI.NPCDialogue = gui
end

function Dialogue:Player(text)
	if activeUI.PlayerDialogue then activeUI.PlayerDialogue:Destroy() end

	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
	if not root then return end

	local gui = DialogueTemplate:Clone()
	gui.Adornee = root
	gui.Parent = player:WaitForChild("PlayerGui")
	gui.Enabled = true

	local frame = gui:FindFirstChild("Frame")
	local label = frame and frame:FindFirstChildWhichIsA("TextLabel")
	if label then typeTextRich(label, text, 0.05) end

	activeUI.PlayerDialogue = gui
	task.delay(2.5, function()
		if gui == activeUI.PlayerDialogue then
			gui:Destroy()
			activeUI.PlayerDialogue = nil
		end
	end)
end

local blur = game.Lighting:WaitForChild("Blur")
local debris = game:GetService('Debris')

local function toggleBlur(enable)
	TweenService:Create(blur, TweenInfo.new(0.3), {Size = enable and 15 or 0}):Play()
end

local function showShopUI(name)
	local string_Value = Instance.new('StringValue')
	string_Value.Value = name
	string_Value.Parent = workspace
	debris:AddItem(string_Value, 1)
	toggleBlur(true)
end

local function hideShopUI()
	toggleBlur(false)
end

function Dialogue:HideAll()
	hideShopUI()
	if activeUI.NPCDialogue then activeUI.NPCDialogue:Destroy() activeUI.NPCDialogue = nil end
	if activeUI.PlayerDialogue then activeUI.PlayerDialogue:Destroy() activeUI.PlayerDialogue = nil end
end

--// Hover Effect
local function addHoverEffect(button)
	local originalSize = button.Size
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	button.MouseEnter:Connect(function()
		TweenService:Create(button, tweenInfo, {
			Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, originalSize.Y.Scale, originalSize.Y.Offset + 10)
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, tweenInfo, {
			Size = originalSize
		}):Play()
	end)
end

--// Highlight
local function highlightModel(model)
	--[[if activeUI.Highlight then activeUI.Highlight:Destroy() end
	local hl = Instance.new("Highlight")
	hl.FillTransparency = 1
	hl.OutlineColor = Color3.new(1,1,1)
	hl.Adornee = model
	hl.Parent = model
	activeUI.Highlight = hl]]
end

ProximityPromptService.PromptShown:Connect(function(prompt)
	local model = prompt.Parent.Parent
	if model and model:IsA("Model") then
		highlightModel(model)
	end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	if activeUI.Highlight then
		activeUI.Highlight:Destroy()
		activeUI.Highlight = nil
	end
end)

local currentNPC = nil

local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

-- local ShopUI = PlayerGui:WaitForChild("Shop"):WaitForChild("Frame")
-- local closeShopBtn = ShopUI:WaitForChild("CloseShop")


local function toggleAllPrompts(enable)
	for _, prompt in ipairs(workspace:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") then
			-- prompt.Enabled = enable
		end
	end
end

local function respondAfter(seconds, message, reenablePrompts)
	if currentNPC then
		task.delay(seconds, function()
			Dialogue:NPC(currentNPC, message)
			task.delay(2, function()
				Dialogue:HideAll()
				if reenablePrompts then
					toggleAllPrompts(true)
				end
			end)
		end)
	end
end

--// Create anchor part (utility function)
local function createAnchorPart()
	local part = Instance.new("Part")
	part.Name = "SellAnchor"
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Transparency = 1
	part.Parent = workspace
	return part
end

local function animateGUIIn(gui, duration)
	for _, descendant in ipairs(gui:GetDescendants()) do
		-- Animate GuiObject (frames, buttons, etc.)
		if descendant:IsA("GuiObject") then
			local originalBG = descendant.BackgroundTransparency
			descendant.BackgroundTransparency = 1
			TweenService:Create(descendant, TweenInfo.new(duration), {
				BackgroundTransparency = originalBG
			}):Play()
		end

		-- Animate text elements
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
			local originalText = descendant.TextTransparency
			descendant.TextTransparency = 1
			TweenService:Create(descendant, TweenInfo.new(duration), {
				TextTransparency = originalText
			}):Play()
		end

		-- Animate UIStroke
		if descendant:IsA("UIStroke") then
			local originalStroke = descendant.Transparency
			descendant.Transparency = 1
			TweenService:Create(descendant, TweenInfo.new(duration), {
				Transparency = originalStroke
			}):Play()
		end
	end

	gui.Enabled = true
end



local function createSellGUI(name, dialogue)
	hideSellGUI()

	local prefix = "[\""
	local suffix = "\"]"

	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")

	-- Create and position anchor part
	local anchor = createAnchorPart()
	anchor.Position = hrp.Position + Vector3.new(-0.5, 0.5, 0)

	-- Continuously update anchor position and orientation
	local connection
	connection = RunService.RenderStepped:Connect(function()
		if activeUI.SellGUI and anchor and anchor.Parent and hrp and hrp.Parent then
			anchor.Position = hrp.Position + Vector3.new(-0.5, 0.5, 0)
			anchor.CFrame = CFrame.new(anchor.Position, Camera.CFrame.Position)
		else
			if connection then connection:Disconnect() end
		end
	end)

	-- Set up GUI
	local gui = SellDisplay:Clone()
	gui.Adornee = anchor
	gui.Parent = PlayerGui
	gui.Enabled = false

	animateGUIIn(gui, 0.5)

	activeUI.SellGUI = gui
	activeUI.SellAnchor = anchor

	-- Button logic
	local frame = gui:WaitForChild("Frame")
	local buttons = {
		Option1 = function()
			hideSellGUI()
			Dialogue:Player(dialogue.Ask1.Value)
			local msg = dialogue.Answer1.Value
			task.delay(1.5, function()
				Dialogue:HideAll()
				showShopUI(name)
			end)
			respondAfter(1.5, msg, true)
		end,

		Option2 = function()
			hideSellGUI()
			Dialogue:Player(dialogue.Ask2.Value)
			local msg = dialogue.Answer2.Value
			respondAfter(1.5, msg, true)
		end,

		Option3 = function()
			hideSellGUI()
			Dialogue:Player(dialogue.Ask3.Value)
			local msg = dialogue.Answer3.Value
			respondAfter(1.5, msg, true)
		end,

		Cancel = function()
			hideSellGUI()
			Dialogue:Player("...")
			respondAfter(1.5, dialogue.CancelResponse.Value, true)
		end,
	}

	local messages = {
		Option1 = dialogue.AskGui1.Value,
		Option2 = dialogue.AskGui2.Value,
		Option3 = dialogue.AskGui3.Value,
		Cancel = "Leave",
	}

	for optionName, callback in pairs(buttons) do
		local btn = frame:FindFirstChild(optionName)
		if btn then
			local messageText = messages[optionName] or "..."
			btn.Text = prefix .. messageText .. suffix -- This applies ["..."]
			addHoverEffect(btn)
			btn.MouseButton1Click:Connect(callback)
		end
	end
end


--// Hide GUI and clean up
function hideSellGUI()
	if activeUI.SellGUI then
		activeUI.SellGUI:Destroy()
		activeUI.SellGUI = nil
	end

	if activeUI.SellAnchor then
		activeUI.SellAnchor:Destroy()
		activeUI.SellAnchor = nil
	end
	toggleAllPrompts(true) -- ✅ enable prompts again after interaction
end



ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeredPlayer)
	if triggeredPlayer ~= player then return end

	toggleAllPrompts(false) -- ⛔ disable all prompts temporarily

	if prompt.Name == "NpcPrompt" then
		
		prompt.Enabled = false
		task.delay(5, function()
			prompt.Enabled = true
		end)
		local proxPart = prompt.Parent
		local dialogue = proxPart.Dialogue
		
		local cancel = false
		
		local targetPosition = proxPart.Position
		local function monitorDistance()
			local connection
			connection = RunService.RenderStepped:Connect(function()
				local character = player.Character
				if not character or not character:FindFirstChild("HumanoidRootPart") then return end

				local hrp = character.HumanoidRootPart
				local distance = (hrp.Position - targetPosition).Magnitude

				if distance > 15 then
					toggleAllPrompts(true)
					cancel = true
					Dialogue:HideAll()
					hideSellGUI()
					currentNPC = nil
					-- Stop checking once GUI is hidden
					if connection then
						connection:Disconnect()
					end
				end
			end)
		end
		
		local npc = proxPart.Parent.npc
		currentNPC = npc
		Dialogue:NPC(npc, dialogue.Opening.Value)
		monitorDistance()
		task.delay(1, function()
			if not cancel then
				Dialogue:HideAll()
				local name = proxPart.Parent.Name
				createSellGUI(name, dialogue)
			end
		end)

	elseif prompt.Name == "SellShop" then
		local npc = prompt.Parent.Parent
		currentNPC = npc
		Dialogue:NPC(npc, "Got anything to sell?")
		task.delay(1.5, function()
			Dialogue:HideAll()
			createSellGUI()
		end)
	end

end)

--[[for _, part in pairs(folder:GetChildren()) do
	if part:IsA("Folder") or part:IsA("Model") or part:IsA("BasePart") then
		local proxPart = part:FindFirstChild("ProxPart")
		if proxPart and proxPart:IsA("BasePart") then
			local prompt = proxPart:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					if proxPart.Parent:FindFirstChild('npc') then
						local dialogue = proxPart.Parent.npc
						local npc = script.Parent
						currentNPC = npc
						Dialogue:NPC(npc, "Redy to Buy sum CRATES!!")
						task.delay(1.5, function()
							Dialogue:HideAll()
							local name = proxPart.Parent.Name
							createSellGUI(name)
						end)
					end
				end)
			else
				warn("No ProximityPrompt found inside " .. proxPart:GetFullName())
			end
		else
			warn("No ProxPart found inside " .. part:GetFullName())
		end
	end
end]]--