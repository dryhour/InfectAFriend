local webhook = "https://discord.com/api/webhooks/1392680123253391523/c_fGYGthBq8xpIXAa3PhYNAjVlDA3kRISJcowD3RVD9RtuBMzosvoUsJffOK9LXLeZjm"
local filteringFunction = game.ReplicatedStorage.FilteringFunction 
local HTTP = game:GetService("HttpService")
 
function filteringFunction.OnServerInvoke(player, msg)
    local payload = HTTP:JSONEncode({
        content = msg,
		username = "📣Feedback: "..player.Name.."🌟"
    })
   
    HTTP:PostAsync(webhook, payload)
    return "Feedback recieved!"
end





























--By Xtrarez