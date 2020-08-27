																																																																																																																															--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║ ▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ ║
║▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌║
║▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀▀▀  ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀ ║
║▐░▌       ▐░▌▐░▌               ▐░▌     ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌          ║
║▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄      ▐░▌     ▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄ ║
║▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░▌     ▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌║
║▐░█▀▀▀▀▀▀▀█░▌ ▀▀▀▀▀▀▀▀▀█░▌     ▐░▌     ▐░▌       ▐░▌▐░█▀▀▀▀█░█▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ║
║▐░▌       ▐░▌          ▐░▌     ▐░▌     ▐░▌       ▐░▌▐░▌     ▐░▌  ▐░▌          ║
║▐░▌       ▐░▌ ▄▄▄▄▄▄▄▄▄█░▌     ▐░▌     ▐░█▄▄▄▄▄▄▄█░▌▐░▌      ▐░▌ ▐░█▄▄▄▄▄▄▄▄▄ ║
║▐░▌       ▐░▌▐░░░░░░░░░░░▌     ▐░▌     ▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌║
║ ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀       ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀ ║
║						   ╔═══════════════════════╗ 						   ║
╠══════════════════════════╣ Object Storage Module ╠═══════════════════════════╣
║						  ╔╩═══════════════════════╩╗						   ║
║						  ║ Made with ♥	by Hoidberg ║						   ║
╚═════════════════════════╩═════════════════════════╩══════════════════════════╝
																																																																																																																															]]
local objectStorage = {}
local RunService = game:GetService("RunService")
local InstanceEncoder = require(script.InstanceEncoder)

local BAD_ARGUMENT = "bad argument #%d (%s expected, got %s)"

local function expectA(t, parameter) -- function taken from https://devforum.roblox.com/t/396022/18
    assert(parameter, BAD_ARGUMENT:format(1, t, "nil"))
    assert(typeof(parameter) == t, BAD_ARGUMENT:format(1, t, typeof(parameter)))

    print(parameter)
end

return function(obj)
	expectA("Instance", obj)
	local hStore = {}
	local mathError = "There is no need to call any math functions"
	local objName = obj.Name
	setmetatable(hStore, {
		__index = function() error("There is no need to call index") end,
		__concat = function(Table, Value) error("There is no need to call concat") end,
		__unm = function(Table) error(mathError) end,
		__add = function(Table, Value) error(mathError) end,
		__sub = function(Table, Value) error(mathError) end,
		__mul = function(Table, Value) error(mathError) end,
		__div = function(Table, Value) error(mathError) end,
		__mod = function(Table, Value) error(mathError) end,
		__pow = function(Table, Value) error(mathError) end,
		__tostring = function(Table) return objName end,
		__eq = function(Table, Value) error(mathError) end,
		__it = function(Table, Value) error(mathError) end,
		__le = function(Table, Value) error(mathError) end,
		__metatable = "You cannot modify the metatable of hStore"
	})
	local encodedObj = InstanceEncoder:Encode(obj)
	
	table.insert(objectStorage, table.getn(objectStorage) + 1, encodedObj)
	obj:Destroy()
	
	function hStore:get()
		return InstanceEncoder:Decode(encodedObj)
	end
	
	hStore.EncodedObject = encodedObj
	
	return hStore
end