-- Module by Quenty

local Time = {}

--[[
	Time.seconds(secs)
	Time.minutes(min) -- converts minutes to seconds
	Time.days(days) -- converts days to seconds
	Time.years(years)
	Time.now() -- tick()
	Time.formatDate(secs) -- 11/12 13:51:45
	Time.relative(secs) -- 3 months ago
	Time.isPast(secs) -- returns whether the time is in the past
--]]

local minutesPerHour = 60
local hoursPerDay = 24
local daysPerWeek = 7
local daysPerMonth = 30
local daysPerYear = 365.25
local secondsPerMinute = 60
local secondsPerHour = secondsPerMinute * minutesPerHour
local secondsPerDay = secondsPerHour * hoursPerDay
local secondsPerWeek = secondsPerDay * daysPerWeek
local secondsPerMonth = secondsPerDay * daysPerMonth
local secondsPerYear = secondsPerDay * daysPerYear

local regularYear = 365
local leapYear = 366

--[[NOLICAIK's Timestamp generator--]]
local ydays = {
	{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31},
	{31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
};
local days_abbrev = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"}
local months_abbrev = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}

function gmtime_r(tsecs, tmbuf)
	local monthsize, yearsize
	local dayclock, dayno
	local year = 1970
	dayclock = math.floor(tsecs % secondsPerDay)
	dayno = math.floor(tsecs / secondsPerDay)
	tmbuf.sec = math.floor(dayclock % 60)
	tmbuf.min = math.floor((dayclock % secondsPerHour) / 60)
	tmbuf.hour = math.floor(dayclock / secondsPerHour)
	tmbuf.wday = math.floor((dayno + 4) % 7)
	yearsize = (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) and leapYear or regularYear
	while dayno >= yearsize do
		dayno = dayno - yearsize
		year = year + 1
		yearsize = (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) and leapYear or regularYear
	end
	tmbuf.year = year
	tmbuf.yday = dayno
	tmbuf.mon = 0
	monthsize = ydays[(year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) and 2 or 1][tmbuf.mon + 1]
	while dayno >= monthsize do
		dayno = dayno - monthsize
		tmbuf.mon = tmbuf.mon + 1
		monthsize = ydays[(year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) and 2 or 1][tmbuf.mon + 1]
	end
	tmbuf.mday = dayno + 1
	return tmbuf
end

function asctime(tmbuf)
	return string.format("%s/%02u %02u:%02u", tmbuf.mon, tmbuf.mday, tmbuf.hour, tmbuf.min)
end

function GMT(timestamp)
	return asctime(gmtime_r(timestamp, {}))
end

function timeFormat(num, unitName)
	if (num == 1) then
		return tostring(num) .. ' ' .. unitName .. ''
	else
		return tostring(num) .. ' ' .. unitName .. 's'
	end
end

function Time.relative(stamp)
	local now = Time.now()
	local diff = Time.length(now - stamp)
	return diff .. ' ago'
end

function Time.length(stamp)
	local len = math.abs(stamp)
	
	local years = math.floor( len / secondsPerYear ) 
	local months = math.floor( len / secondsPerMonth )
	local weeks = math.floor( len / secondsPerWeek )
	local days = math.floor( len / secondsPerDay )
	local hours = math.floor( len / secondsPerHour )
	local minutes = math.floor( len / secondsPerMinute )
	local seconds = math.floor( len  )
	
	if (years > 0) then
		return timeFormat(years, 'year')
	elseif (months > 0) then
		return timeFormat(months, 'month')
	elseif (weeks > 0) then
		return timeFormat(weeks, 'week')
	elseif (days > 0) then
		return timeFormat(days, 'day')
	elseif (hours > 0) then
		return timeFormat(hours, 'hour')
	elseif (minutes > 0) then
		return timeFormat(minutes, 'minute')
	elseif (seconds > 0) then
		return timeFormat(seconds, 'second')
	else
		return timeFormat(0, 'second')
	end
end

function Time.seconds(seconds)
	return math.ceil( seconds  )
end

function Time.minutes(minutes)
	return math.ceil( minutes * secondsPerMinute )
end

function Time.days(days)
	return math.ceil( days * secondsPerDay  )
end

function Time.years(years)
	return math.ceil( secondsPerDay * daysPerYear * years )
end

function Time.now()
	return math.ceil( tick() )
end

function Time.format(timestamp)
	return GMT(timestamp)
end

function Time.isPast(seconds)
	return (Time.now() > seconds)
end

return Time