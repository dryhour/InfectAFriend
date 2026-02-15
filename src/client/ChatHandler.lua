local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

-- Configuration
local MESSAGE_INTERVAL = 90 -- seconds
local PREFIX = "[Tip] "
local SUFFIX = ""

-- List of possible messages
local MESSAGES = {
	"Stay alive longer for more COINS!",
	"Having fun? Invite friends to play!❤️",
	"Did you know: You can get explosions by spinning for them in crates!",
	"You get a new reward DAILY! Join back the next day to keep receiving rewards.",
	"Did you know: You can explode the infected early by powering generators.",
	"Have fun and follow ROBLOX's TOS.",
	"Customize your character with TRAILS, EXPLOSIONS, INFECTED COLORS, and ABILITIES!",
	"Having fun? Join our group!",
	"Having fun? 👍Like and favorite our game!❤️",
	"Use abilities to YOUR Advantage!",
	"Customize your character and gain more money per second!",
	"Earn money offline!",
}

-- List of possible colors (RGB values)
local COLORS = {
	Color3.fromRGB(255, 0, 0),     -- Red
	Color3.fromRGB(0, 255, 0),     -- Green
	Color3.fromRGB(0, 170, 255),   -- Blue
	Color3.fromRGB(255, 255, 0),   -- Yellow
	Color3.fromRGB(255, 105, 180), -- Pink
	Color3.fromRGB(255, 165, 0),   -- Orange
	Color3.fromRGB(160, 32, 240),  -- Purple
}

-- Function to send a message with a random color
local function sendRandomMessage()
	-- Check if TextChatService is available
	if not TextChatService then
		warn("TextChatService is not available")
		return
	end

	local success, errorMessage = pcall(function()
		local randomMessage = MESSAGES[math.random(1, #MESSAGES)]
		local randomColor = COLORS[math.random(1, #COLORS)]

		local fullMessage = PREFIX .. randomMessage .. SUFFIX
		-- Convert Color3 to HTML hex format
		local function color3ToHex(color)
			return string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
		end

		-- Your random color and message
		local hexColor = color3ToHex(randomColor)
		local styledMessage = string.format("<font color='%s'>%s</font>", hexColor, fullMessage)

		-- Display the rich text message
		game:GetService("TextChatService").TextChannels.RBXGeneral:DisplaySystemMessage(styledMessage)


	end)

	if not success then
		warn("Failed to send message:", errorMessage)
	end
end

task.wait(.5)
local welcomeMessage = "👋 Welcome, "..game.Players.LocalPlayer.Name.."!"
game:GetService("TextChatService").TextChannels.RBXGeneral:DisplaySystemMessage(welcomeMessage)

-- Main loop
local function startMessageLoop()
	while true do
		sendRandomMessage()
		task.wait(MESSAGE_INTERVAL)
	end
end

-- Start the system
local success, err = pcall(startMessageLoop)
if not success then
	warn("Message loop failed:", err)
end