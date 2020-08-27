--[[
Instance Encode Module by TheNexusAvenger. API Dump run by Ananimus

This module is meant to serve as a replacement to Staravnt's Instanc Encoder module.
This version is meant to be safe to update (and easy) to the latests API.

Limitations:
1. No Union Data
2. No Script Source (Unless you set PluginSecurity to false and use it as a plugin)
3. New UserData has to be manually supported (I will do this as long as I still support this model)


Module:Encode(Instance,SerializeUserdataToString)
	Encodes a given instance to a table. Objects that can't be created (such
	as services) and properties that can't be accessed from the given security
	level (such as Source from a LocalScript) won't be serialized. If
	SerializeUserdataToString is set to true, it will encode the UserData (such
	as Vector3, UDim2, NumberSequence, etc) into strings which can be used for JSON,
	and will just keep it as Userdata if it isn't true.
	
Module:Decode(Table)
	Decodes the given table back to the instances given by Module:Encode(). Automatically
	detects if SerializeUserdataToString was true or not, so that input is not
	needed.
	
Steps for updaing API:
1. Run the API Compiler plugin (https://www.roblox.com/item.aspx?id=421192186)
	HttpService must be enabled to operate.
2. Place the module created (in ServerScriptService) into the InstanceEncode Modul	
	
	
	
	
	
	
Config:	
]]
--Set to false to not have the properties with these security levels ignored.

--Server Script: All true
--Local Script: All true
--Plugin/Command Line: Only RobloxSecurity is true

local SecurityLevelsIgnored = { 
	RobloxSecurity = true,
	RobloxPlaceSecurity = true,
	RobloxScriptSecurity = true,
	LocalUserSecurity = true,
	WritePlayerSecurity = true,
	PluginSecurity = true,
}

--Properties ignored for serialization. Shouldn't need to be messed with.
local IgnoredProperties = {
	BaseScript = {
		LinkedSource = true,
	},
	ModuleScript = {
		LinkedSource = true,
	},
	BasePart = {
		Position = true,
		Rotation = true,
	},
}

--If true, it will not serialize any instances with Archivable set to false.
--The behavior is the same as how :Clone() is handled.
local RespectArchivableProperty = false



-----Config ends here-----







local CompiledApi = require(script:WaitForChild("CompiledApi"))

local match,gsub = string.match,string.gsub
local insert = table.insert
local BrickColornew,Axesnew,CFramenew,Color3new = BrickColor.new,Axes.new,CFrame.new,Color3.new
local Facesnew,Raynew,Vector2new,Vector3new = Faces.new,Ray.new,Vector2.new,Vector3.new
local Rectnew,UDimnew,UDim2new,NumberRangenew = Rect.new,UDim.new,UDim2.new,NumberRange.new
local ColorSequencenew,NumberSequencenew,NumberSequenceKeypointnew = ColorSequence.new,NumberSequence.new,NumberSequenceKeypoint.new
local Instancenew,PhysicalPropertiesnew = Instance.new,PhysicalProperties.new

local Module = {}
local Properties = {}
local function HasTag(Table,Value)
	for _,Tag in pairs(Table) do
		if Tag == Value then
			return true
		end
	end
	return false
end

local function CheckSecurityOfTags(Tags)
	for Security,Included in pairs(SecurityLevelsIgnored) do
		if Included == true and HasTag(Tags,Security) then
			return false
		end
	end
	return true
end

local function AddPropertiesToClass(ClassName,InheritenceClass,DontStoreDefaults)
	if ClassName and InheritenceClass then
		local Class = CompiledApi[InheritenceClass]
		if Class.Properties then
			for PropertyName,Table in pairs(Class.Properties) do
				if not IgnoredProperties[InheritenceClass] or IgnoredProperties[InheritenceClass][PropertyName] ~= true then
					local Tags = Table.Tags
					if not HasTag(Tags,"deprecated") and not HasTag(Table.Tags,"hidden") and not HasTag(Tags,"readonly") and CheckSecurityOfTags(Tags) then
						table.insert(Properties[ClassName],{Name=PropertyName,ValueType=Table.ValueType})
					end
				end
			end
		end
		
		if Class.Superclass then
			AddPropertiesToClass(ClassName,Class.Superclass)
		end
	end
end

for Class,Table in pairs(CompiledApi) do
	Properties[Class] = {}
	AddPropertiesToClass(Class,Class)
end

function Module:Encode(Instance,SerializeUserdataToString)
	local InstancesToEncode = {}
	
	local function SerializeUserdata(UserData,Type)
		if SerializeUserdataToString ~= true then return UserData end
		if Type == "Axes" then
			return tostring(UserData)
		elseif Type == "BrickColor" then
			return tostring(UserData)
		elseif Type == "CoordinateFrame" then
			return tostring(UserData)
		elseif Type == "Color3" then
			return tostring(UserData)
		elseif Type == "Faces" then
			return tostring(UserData)
		elseif Type == "Ray" then
			return tostring(UserData)
		elseif Type == "Rect" then
			return tostring(UserData)
		elseif Type == "UDim" then
			return tostring(UserData)
		elseif Type == "UDim2" then
			return tostring(UserData)
		elseif Type == "Vector2" then
			return tostring(UserData)
		elseif Type == "Vector3" then
			return tostring(UserData)
		elseif Type == "ColorSequence" then
			return tostring(UserData)
		elseif Type == "NumberRange" then
			return tostring(UserData)
		elseif Type == "NumberSequence" then
			return tostring(UserData)
		elseif Type == "Rect2D" then
			return tostring(UserData)
		elseif Type == "PhysicalProperties" then
			return tostring(UserData)
		else
			local EnumItem = match(tostring(UserData),"Enum%.[%a%d]+%.([%a%d]+)")
			if EnumItem then
				return EnumItem
			else
				warn("Unused Data Type: "..Type.." ("..tostring(UserData)..")")
				return nil
			end
		end
	end
	
	local function AddToTable(Instance)
		if not HasTag(CompiledApi[Instance.ClassName].Tags,"notCreatable") and (RespectArchivableProperty == false or Instance.Archivable == true) then
			insert(InstancesToEncode,Instance)
			for _,Instance in pairs(Instance:GetChildren()) do
				AddToTable(Instance)
			end		
		end
	end
	AddToTable(Instance)
	
	local function GetInstanceId(Ins)
		for Id,Instance in pairs(InstancesToEncode) do
			if Ins == Instance then
				return Id
			end
		end
		return nil
	end
	
	local EncodedInstances = {}
	for Id,Ins in pairs(InstancesToEncode) do
		local InstanceTable = {}
		
		for _,Property in pairs(Properties[Ins.ClassName]) do
			local PropertyName = Property.Name
			if Property.ValueType == "Object" then
				local Ref = GetInstanceId(Ins[PropertyName])
				if Ref then 
					InstanceTable[PropertyName] = Ref					
				end
			else
				local Prop = Ins[Property.Name]
				if type(Prop) == "userdata" then
					InstanceTable[PropertyName] = SerializeUserdata(Prop,Property.ValueType)
				else
					InstanceTable[PropertyName] = Prop
				end
			end
		end
		
		InstanceTable.ClassName = Ins.ClassName
		insert(EncodedInstances,InstanceTable)
	end
	
	return EncodedInstances
end


function Module:Decode(Table)
	local NewInstance
	local CreatedInstances = {}
	local ObjectsToAssign = {}
	
	local Num = "([%-%d%.e]+)"
	local function DeserializeUserdata(String,Type)
		if type(String) ~= "string" or Type == "string" or Type == "Content" or Type == "ProtectedString" then return String end
		if Type == "Axes" then
			local X,Y,Z = match(String,"X"),match(String,"Y"),match(String,"Z")
			
			local AxesTable = {}
			if X then insert(AxesTable,Enum.Axis.X) end
			if Y then insert(AxesTable,Enum.Axis.Y) end
			if Z then insert(AxesTable,Enum.Axis.Z) end
			return Axesnew(unpack(AxesTable))
		elseif Type == "BrickColor" then
			return BrickColornew(String)
		elseif Type == "CoordinateFrame" then
			local X,Y,Z,A,B,C,D,E,F,G,H,I = match(String,Num..", "..Num..", "..Num..", "..Num..", "..Num..", "..Num..", "..Num..", "..Num..", "..Num..", "..Num..", "..Num..", "..Num)
			return CFramenew(X,Y,Z,A,B,C,D,E,F,G,H,I)
		elseif Type == "Color3" then
			local R,G,B = match(String,Num..", "..Num..", "..Num)
			return Color3new(R,G,B)
		elseif Type == "Faces" then
			local Top,Bottom = match(String,"Top"),match(String,"Bottom")
			local Left,Right = match(String,"Left"),match(String,"Right")
			local Front,Back = match(String,"Front"),match(String,"Back")
			
			local FacesTable = {}
			if Top then insert(FacesTable,Enum.NormalId.Top) end
			if Bottom then insert(FacesTable,Enum.NormalId.Bottom) end
			if Left then insert(FacesTable,Enum.NormalId.Left) end
			if Right then insert(FacesTable,Enum.NormalId.Right) end
			if Front then insert(FacesTable,Enum.NormalId.Front) end
			if Back then insert(FacesTable,Enum.NormalId.Back) end
			return Facesnew(unpack(FacesTable))
		elseif Type == "Ray" then
			local X1,Y1,Z1,X2,Y2,Z2 = match(String,Num..", "..Num..", "..Num.."}, {"..Num..", "..Num..", "..Num)
			return Raynew(Vector3new(X1,Y1,Z1),Vector3new(X2,Y2,Z2))
		elseif Type == "Rect" or Type == "Rect2D" then
			local W,X,Y,Z = match(String,Num..", "..Num..", "..Num..", "..Num)
			return Rectnew(W,X,Y,Z)
		elseif Type == "UDim" then
			local X,Y = match(String,Num..", "..Num)
			return UDimnew(X,Y)
		elseif Type == "UDim2" then
			local X1,Y1,X2,Y2 = match(String,Num..", "..Num.."}, {"..Num..", "..Num)
			return UDim2new(X1,Y1,X2,Y2)
		elseif Type == "Vector2" then
			local X,Y = match(String,Num..", "..Num)
			return Vector2new(X,Y)
		elseif Type == "Vector3" then
			local X,Y,Z = match(String,Num..", "..Num..", "..Num)
			return Vector3new(X,Y,Z)
		elseif Type == "ColorSequence" then
			local _,R1,G1,B1,_,_,R2,G2,B2,_ = match(String,Num.." "..Num.." "..Num.." "..Num.." "..Num.." "..Num.." "..Num.." "..Num.." "..Num.." "..Num)
			return ColorSequencenew(Color3new(R1,G1,B1),Color3new(R2,G2,B2))
		elseif Type == "NumberRange" then
			local X,Y = match(String,Num.." "..Num)
			return NumberRangenew(X,Y)
		elseif Type == "NumberSequence" then
			local Keypoints = {}
			gsub(String,Num.." "..Num.." "..Num,function(Time,Value,Envelope)
				insert(Keypoints,NumberSequenceKeypointnew(Time,Value,Envelope))
			end)
			return NumberSequencenew(Keypoints)
		elseif Type == "PhysicalProperties" then
			local Density,Friction,Elasticity,FrictionWeight,ElasticityWeight = match(String,Num.." "..Num.." "..Num.." "..Num.." "..Num)
			return PhysicalPropertiesnew(Density,Friction,Elasticity,FrictionWeight,ElasticityWeight)
		else
			return Enum[Type][String]
		end
	end
	
	for Id,InstanceTable in pairs(Table) do
		local ClassName = InstanceTable.ClassName
		local Ins = Instancenew(ClassName)
	
		for _,PropertyTable in pairs(Properties[ClassName]) do	
			local PropertyName = PropertyTable.Name		
			local Property = InstanceTable[PropertyName]
			if Property ~= nil then
				if PropertyTable.ValueType == "Object" then
					table.insert(ObjectsToAssign,{Ins,PropertyName,Property})
				else
					Ins[PropertyName] = DeserializeUserdata(Property,PropertyTable.ValueType)
				end
			end
		end
		
		
		
		if Id == 1 then
			NewInstance = Ins
		end
		CreatedInstances[Id] = Ins
	end
	
	for _,ObjectTable in pairs(ObjectsToAssign) do
		ObjectTable[1][ObjectTable[2]] = CreatedInstances[ObjectTable[3]]
	end
	return NewInstance
end

return Module