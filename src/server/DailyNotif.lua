local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")

local OCUserNotification = require(ServerScriptService.OpenCloud.V2.UserNotification)

local PlayerHistoryStore = DataStoreService:GetDataStore("PlayerHistory")
local DailyNotifyStore = DataStoreService:GetDataStore("DailyNotificationLog")

local NotificationMessageId = "0fb281b4-44d7-7d4b-9b24-a4e163c9222c"
local NotificationType = "MOMENT"
local DAILY_NOTIFY_LIMIT = 10

local function getTodayKey()
	local date = os.date("!*t")
	return string.format("daily_%04d_%02d_%02d", date.year, date.month, date.day)
end

local function getAllPastPlayerIds()
	local success, result = pcall(function()
		return PlayerHistoryStore:GetAsync("PlayerUserIds")
	end)
	return (success and type(result) == "table") and result or {}
end

local function getNotifiedToday()
	local key = getTodayKey()
	local success, result = pcall(function()
		return DailyNotifyStore:GetAsync(key)
	end)
	return (success and type(result) == "table") and result or {}
end

local function saveNotifiedToday(ids)
	local key = getTodayKey()
	pcall(function()
		DailyNotifyStore:SetAsync(key, ids)
	end)
end

local function pickRandomUnnotified(allIds, notified, count)
	local pool = {}
	local already = {}

	for _, id in ipairs(notified) do
		already[id] = true
	end

	for _, id in ipairs(allIds) do
		if not already[id] then
			table.insert(pool, id)
		end
	end

	local selected = {}
	for _ = 1, math.min(count, #pool) do
		local index = math.random(1, #pool)
		table.insert(selected, pool[index])
		table.remove(pool, index)
	end

	return selected
end

local function notifyPlayers(userIds)
	for _, userId in ipairs(userIds) do
		local payload = {
			payload = {
				messageId = NotificationMessageId,
				type = NotificationType
			}
		}
		local result = OCUserNotification.createUserNotification(userId, payload)
	end
end

local function mergeTables(t1, t2)
	local result = {}
	for _, v in ipairs(t1) do
		table.insert(result, v)
	end
	for _, v in ipairs(t2) do
		table.insert(result, v)
	end
	return result
end

task.spawn(function()
	local allPlayers = getAllPastPlayerIds()
	local alreadyNotified = getNotifiedToday()

	local toNotify = pickRandomUnnotified(allPlayers, alreadyNotified, DAILY_NOTIFY_LIMIT)

	if #toNotify > 0 then
		notifyPlayers(toNotify)
		saveNotifiedToday(mergeTables(alreadyNotified, toNotify))
	end
end)
