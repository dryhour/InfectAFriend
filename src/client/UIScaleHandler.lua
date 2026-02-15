local BASE_SIZE = 1200
local MIN_TEXT_SIZE = 25
local MAX_TEXT_SIZE = 45
local TEXT_HEIGHT_RATIO = 0.4
local CHAR_WIDTH_FACTOR = 0.1 -- Approx. width per character in TextSize units

local camera = workspace.CurrentCamera
local players = game:GetService("Players")
local player = players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local strokeData = {}
local textObjects = {}

local function clamp(val, min, max)
	return math.max(min, math.min(max, val))
end

-- Register strokes
local function registerUIStroke(stroke)
	if not strokeData[stroke] then
		strokeData[stroke] = stroke.Thickness
	end
end

-- Register text
local function registerTextObject(obj)
	if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
		textObjects[obj] = true
	end
end

-- Register everything inside GUI
local function registerElements(container)
	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("UIStroke") then
			registerUIStroke(descendant)
		elseif descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
			registerTextObject(descendant)
		end
	end
end

-- Handle adding/removing
local function onDescendantAdded(descendant)
	if descendant:IsA("UIStroke") then
		registerUIStroke(descendant)
	elseif descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
		registerTextObject(descendant)
	end
end

local function onDescendantRemoved(descendant)
	strokeData[descendant] = nil
	textObjects[descendant] = nil
end

-- Register PlayerGui
for _, gui in ipairs(playerGui:GetChildren()) do
	if gui:IsA("ScreenGui") then
		registerElements(gui)
	end
end

playerGui.DescendantAdded:Connect(onDescendantAdded)
playerGui.DescendantRemoving:Connect(onDescendantRemoved)

-- Scaling
local lastScale = nil
-- Utility: Check if string is likely an emoji (basic heuristic)
local CHAR_WIDTH_FACTOR = 0.5 -- Approximate per-character width

local function isPureEmoji(text)
	for _, codepoint in utf8.codes(text) do
		local c = utf8.char(codepoint)
		if c:match("%w") or c:match("[%p%s]") then
			return false
		end
	end
	return true
end

local function updateAllScales()
	local scale = math.round((camera.ViewportSize.X / BASE_SIZE) * 1000) / 1000
	if scale == lastScale then return end
	lastScale = scale

	for stroke, initialThickness in pairs(strokeData) do
		if stroke and stroke.Parent then
			stroke.Thickness = initialThickness * scale
		end
	end

	for obj in pairs(textObjects) do
		if obj and obj.Parent then
			local text = obj.Text or ""
			local width = obj.AbsoluteSize.X
			local height = obj.AbsoluteSize.Y

			if isPureEmoji(text) or obj.Name == 'Image' or obj.Name == 'Details'
				or obj.Name == 'ArrayLabel' or obj.Name == 'TextName' or obj.Name == 'TextLabel' 
				or obj.Parent.Name == "Runner" or obj.Parent.Name == "Tagger"
				or obj.Parent.Name == "Ability" or obj.Parent.Name == "RobuxAbility"
				or obj.Name == "Description"
				or obj.Parent:FindFirstChild("RarityLeft")
			then
				-- Skip emoji-only objects
				continue
			end

			obj.TextScaled = false
			local charCount = math.max(#text, 1)

			if obj.Name == "Title" then
				-- Special handling for Title objects
				local maxSizeBasedOnHeight = height * TEXT_HEIGHT_RATIO
				local initialSize = math.min(MAX_TEXT_SIZE, maxSizeBasedOnHeight)
				local requiredWidth = charCount * (initialSize * CHAR_WIDTH_FACTOR)
				
				if not obj:FindFirstChild('UITextSizeConstraint') then
					local tsc = Instance.new('UITextSizeConstraint')
					tsc.Parent = obj
					tsc.MinTextSize = 20
					if camera.ViewportSize.Y < 700 then
						tsc.MinTextSize = 15
					end
					tsc.MaxTextSize = 55
				end

				if requiredWidth > width then
					-- For Titles, scale down to fit width if needed
					local sizeBasedOnWidth = width / (charCount * CHAR_WIDTH_FACTOR)
					local newSize = math.min(sizeBasedOnWidth, maxSizeBasedOnHeight)
					newSize = math.max(newSize, MIN_TEXT_SIZE)
					obj.TextSize = newSize
					obj.TextWrapped = false
				else
					obj.TextSize = initialSize
					obj.TextWrapped = (requiredWidth * 0.95) > width
				end
			else
				-- Original behavior for all other objects
				local sizeBasedOnWidth = width / (charCount * CHAR_WIDTH_FACTOR)
				local sizeBasedOnHeight = height * TEXT_HEIGHT_RATIO
				local newSize = math.min(sizeBasedOnWidth, sizeBasedOnHeight)
				newSize = math.clamp(newSize, MIN_TEXT_SIZE, MAX_TEXT_SIZE)
				obj.TextSize = newSize

				local expectedTextWidth = charCount * (newSize * CHAR_WIDTH_FACTOR)
				obj.TextWrapped = expectedTextWidth > width
			end
		end
	end
end



camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateAllScales)
updateAllScales()
