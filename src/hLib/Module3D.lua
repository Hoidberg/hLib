																																																							--[[
____________________________________________________________________________________________________________________________________________________________________________

	@CloneTrooper1019, 2014-,2015 <3

	(Some code provided by Mark Langen, also known as stravant)

		This module comes with API for controlling 3D to 2D. 

		PLEASE NOTE: 
			The API assumes there is nothing in front of the model being displayed
	 		(whether its a GUI, or anything in the workspace) 
			

____________________________________________________________________________________________________________________________________________________________________________

	API DETAILS
____________________________________________________________________________________________________________________________________________________________________________
		
		* Module3D:Attach3D(Instance guiObj, Instance model, bool useExtentsSize = false)
			
			Description:
				* Attaches a part/model to the center of the gui object specified.
				* Can have its offset changed as well as its active state. By default the model is hidden, and you need to call SetActive onto it manually
			
			Arguments:
				* Instance guiObj
					- guiObj must be any kind of Gui object that contains a "Position" property, such as a Frame, ImageLabel, etc.
				* Instance model
				 	- model can be either a Model, or a BasePart (Part, Wedge, Truss, etc).
				* bool useExtents = false
					- Whether or not the module should calculate the bounds of the model using Model:GetExtentsSize() or Model:GetModelSize()
					- This argument is optional, and excluding it will set it to false
					- See these wiki pages to know the difference:
						* http://wiki.roblox.com/index.php?title=API:Class/Model/GetModelSize
						* http://wiki.roblox.com/index.php?title=API:Class/Model/GetExtentsSize
			Returns:
				* Controller
					- This is a small library representing the 3D model. It has a few functions and one property.
						* Controller:SetActive(boolean active)
							- Toggles whether or not the 3D Object should be shown or not
						* Controller:SetOffset(CoordinateFrame Offset)
							- Sets a CFrame offset from the location its trying to place the 3D Model.
							- Note that by default, it sets the CFrame a blank CFrame.new()				
						* Controller:SetCFrame(CoordinateFrame Offset) [deprecated]
							- Does the same thing as SetOffset, 
							- This only exists for compatability with older versions and should not be used.
						* Controller:End()
							- Effectively removes the model and disconnects its movement events.
						* Controller.Object3D
							- The current model being used.
				
			Example Code:
			
				----------------------------------------------------------------------------------------------------------
				local self = script.Parent
				local frame = self:WaitForChild("Frame")
				local module3D = require(self:WaitForChild("Module3D"))
				local model = workspace:WaitForChild("Guy")
			
				local activeModel = handler:Attach3D(frame,model)
				activeModel:SetActive(true)
				activeModel:SetCFrame(CFrame.Angles(0,math.pi,0))
				----------------------------------------------------------------------------------------------------------
____________________________________________________________________________________________________________________________________________________________________________
		
		* Module3D:AnimAttach3D( BasePart rootPart, GuiObject guiObj )
			
			Description:
				* This functions almost identical to the Attach3D function, however there are some important differences.
					* The model is not cloned, instead it is inputted directly. So if you want to reuse the source model, make sure you clone it prior.
					* It expects that all parts are connected with Motor6D, and will not do any welding unlike Attach3D
					* The argument SHOULD be the RootPart for the animation (so if you are using a character it should be the HumanoidRootPart)
					* The Controller class which is returned also has a LoadAnimation function which returns an AnimationTrack to be played on the model.
____________________________________________________________________________________________________________________________________________________________________________
	
		* Module3d:AdornScreenGuiToWorld(Instance screenGui, number depth = 1)
			
			Description:
				* This function takes a ScreenGui, and turns it into a BillboardGui
				* The BillboardGui is adorned to a part which mirrors the CFrame of the Camera, 
				   and applies a forward offset to the BillboardGui based on the depth value.
			
			Arguments:
				* Instance screenGui
					- guiObj must be a ScreenGui. If you only need to do this with one frame, its reccomended you just make the entire ScreenGui an adorn.
				* number depth = 1
				 	- How many studs in front of the camera the GUI will be.
					- This argument is optional, and excluding it will set it to 1.
			
			Returns:
				* Instance SurfaceGui
					- This is the SurfaceGui version of your ScreenGui.
				* 3dGuiModifier
					- This is a small library with 2 functions. It allows you to change the depth of the WorldGui, and reset it back to a ScreenGui.
						* 3dController:SetDepth(number depth)
							- Sets a new depth value.
						* 3dGuiModifier:Reset()
							- Returns the ScreenGui to its former state, Destroys the old BillboardGui, and disconnects the movement event.
							
			Example Code:
			
				local oldGui = script.Parent
				local module3D = require(oldGui:WaitForChild("Module3D"))
				local newGui,modifier = handler:AdornScreenGuiToWorld(screenGui,3)
				print(oldGui.Parent,newGui.Parent)
				wait(1)
				modifier:SetDepth(2)
				wait(1)
				modifier:Reset()
				print(oldGui.Parent,newGui.Parent)
				
				----------------------------------------------------------------------------------------------------------
			
			Notes:
				* BillboardGuis can't receive input properly on mobile devices.
				   I advice only using this method for backdrops instead of interactive elements.
____________________________________________________________________________________________________________________________________________________________________________																																																																--]]

local moduleAPI = {}
local c = workspace.CurrentCamera
local player = game.Players.LocalPlayer
local rs = game:GetService("RunService")

local argTemp = "Argument #%d"
local shouldTemp = "%s should be %s (not %s)"

local function vowel(name)
	local vowels = "aeiou"
	local char = name:match(".")
	if not string.sub(name,1,2) == "us" then
		for vowel in vowels:gmatch(".") do
			if char == vowel and string.sub(name,1,2) ~= "us" then
				return "an '"..name.."'"
			end
		end
	end
	return "a "..name
end

local function checkArgs(args)
	local arg = 1
	for var,check in pairs(args) do
		local s = argTemp:format(arg)
		assert(var ~= nil, s.." missing or nil")
		local valueType = type(var)
		if type(check) == "function" then
			local isValid,argumentType = check(var)
			assert(isValid, shouldTemp:format(s, vowel(argumentType), vowel(valueType)))
		else
			assert(valueType == check, shouldTemp:format(s, vowel(check), vowel(valueType)))
		end
		arg = arg + 1
	end
end

local function getDepthForWidth(partWidth, visibleSize)
	local resolution = c.ViewportSize
	local aspectRatio = resolution.X / resolution.Y
	local hfactor = math.tan(math.rad(c.FieldOfView)/2)
	local wfactor = aspectRatio*hfactor
	return -(-0.5*resolution.X*partWidth/(visibleSize*wfactor))
end

function moduleAPI:Attach3D(guiObj,model,useExtentsSize)
	checkArgs 
	{
		[guiObj] = function () 
			return guiObj:IsA("GuiObject"), "GuiObject" 
		end;
	 	[model] = function () 
			return (model:IsA("Model") or model:IsA("BasePart")),"Model or BasePart"
		end
	}
	-- Create our 3D Model
	local m = Instance.new("Model")
	m.Name = model.Name.."_3D"
	m.Parent = c
	
	-- Gather up and tweak the parts.
	local parts = {}
	
	if model:IsA("BasePart") then
		local this = model:clone()
		this.Parent = m
		table.insert(parts,this)
	else
		local function recurse(obj)
			for _,v in pairs(obj:GetChildren()) do
				local part do
					if v:IsA("BasePart") then
						part = v:clone()
					elseif v:IsA("Hat") and v:findFirstChild("Handle") then
						part = v.Handle:clone()
					end
				end
				if part then
					local cf = part.CFrame
					part.Parent = m
					part.CFrame = cf
					if part.Name == "Head" then
						part.Name = "head"
					end
					table.insert(parts,part)
				elseif not v:IsA("Model") and not v:IsA("Sound") and not v:IsA("Script") then
					v:clone().Parent = m
				else
					recurse(v)
				end
			end
		end
		recurse(model)
	end
	
	-- Create a primary center part for our model.
	
	local extents = (useExtentsSize and m:GetExtentsSize() or m:GetModelSize())
	local maxExtent = math.max(extents.X,extents.Y,extents.Z) * 1.2
	
	local primary = Instance.new("Part")
	primary.Anchored = true
	primary.Transparency = 1
	primary.CanCollide = false
	primary.Name = "Centroid"
	primary.FormFactor = "Custom"
	primary.Size = extents
	primary.CFrame = CFrame.new(m:GetModelCFrame().p)
	primary.Parent = m
	m.PrimaryPart = primary
	
	-- Weld the parts in our model to our primary part.
	
	for _,v in pairs(parts) do
		v.Anchored = false
		v.CanCollide = false
		local w = Instance.new("Weld")
		w.Part0 = primary
		w.Part1 = v
		w.C0 = primary.CFrame:toObjectSpace(v.CFrame)
		w.Parent = primary
	end
	
	-- Hook up the code for CFraming the model in 3D space.

	local cf = CFrame.new()
	local active = false
	
	local lib = {}
	lib.Object3D = m
	
	function lib:SetActive(b)
		checkArgs{[b] = "boolean"}
		active = b
	end
	
	function lib:SetOffset(newCF)
		checkArgs{[newCF] = function () 
			local isCFrame = pcall(function () return newCF:components() end)
			return isCFrame,"CFrame"
		end}
		cf = newCF	
	end
	
	function lib:SetCFrame(newCF)
		lib:SetOffset(newCF)
	end
	
	function lib:GetDepth()
		local size = math.min(guiObj.AbsoluteSize.X, guiObj.AbsoluteSize.Y)
		return getDepthForWidth(maxExtent, size)
	end
	
	function lib:GetDepthForBackdrop()
		local depth = lib:GetDepth()
		return depth + maxExtent
	end
	
	local nowhere = CFrame.new(99999,99999,99999)
	
	local function updateModel()
		local nextCF = nowhere
		if active then
			local camCF = c.CoordinateFrame
			local sizeX,sizeY = guiObj.AbsoluteSize.X, guiObj.AbsoluteSize.Y
			local posX,posY = guiObj.AbsolutePosition.X + (sizeX / 2), guiObj.AbsolutePosition.Y + (sizeY / 2)
			local posZ = lib:GetDepth()
			nextCF = CFrame.new(c:ScreenPointToRay(posX,posY,posZ).Origin) * (camCF-camCF.p) * cf
		end
		primary.Anchored = false
		primary.CFrame = nextCF
		primary.Anchored = true
	end
	
	local con = rs.RenderStepped:connect(updateModel)
	
	function lib:End()
		con:disconnect()
		m:Destroy()
	end
	return lib
end

function moduleAPI:AdornScreenGuiToWorld(screenGui,depth)
	checkArgs
	{
		[screenGui] = function ()
			return (screenGui:IsA("ScreenGui") or screenGui:IsA("BillboardGui")) or false,"ScreenGui or BillboardGui"
		end
	}
	local depth = type(depth) == "number" and depth or 1
	local s = Instance.new("BillboardGui",screenGui.Parent)
	s.Name = screenGui.Name
	local adorn = Instance.new("Part",s)
	adorn.Name = screenGui.Name.."_Adornee"
	adorn.FormFactor = "Custom"
	adorn.Anchored = true
	adorn.CanCollide = false
	adorn.Size = Vector3.new()
	adorn.Transparency = 1
	adorn.Locked = true
	local con
	local modifier = {}
	function modifier:SetDepth(n)
		checkArgs(n,"number")
		depth = n
	end
	function modifier:Reset()
		screenGui.Parent = s.Parent
		for _,v in pairs(s:GetChildren()) do
			v.Parent = screenGui
		end
		con:disconnect()
		adorn:Destroy()
		s:Destroy()
	end
	local function updateAdorn()
		local success,did = pcall(function ()
			local res = c.ViewportSize
			adorn.CFrame = c.CoordinateFrame
			s.Size = UDim2.new(0,res.X,0,res.Y)
			s.StudsOffset = Vector3.new(0,0,-depth)
			return true
		end)
		if not success or not did then
			warn(script:GetFullName()..": The adornee was destroyed! The gui has been reset.")
			modifier:Reset()
		end
	end
	con = rs.RenderStepped:connect(updateAdorn)
	s.Adornee = adorn
	for _,v in pairs(screenGui:GetChildren()) do
		v.Parent = s
	end
	screenGui.Parent = nil
	return s,modifier
end

function moduleAPI:AnimAttach3D(rootPart,guiObj)
	checkArgs
	{
		[rootPart] = function ()
			return rootPart:IsA("BasePart") or false,"BasePart"
		end;
		[guiObj] = function () 
			return guiObj:IsA("GuiObject") or false,"GuiObject" 
		end;
	}
	
	local model = rootPart.Parent
	assert(model and model:IsA("Model"),"rootPart.Parent should be a Model")
	local animator = model:FindFirstChild("AnimationController")
	if not animator then
		animator = Instance.new("AnimationController",model)
	end
	
	model.PrimaryPart = rootPart
	
	local cf = CFrame.new()
	local active = false
	local maxExtent = model:GetModelSize().magnitude
	
	local lib = {}
	lib.Object3D = model
	
	model.Parent = c
	
	function lib:SetActive(b)
		checkArgs{[b] = "boolean"}
		active = b
	end
	
	function lib:SetOffset(newCF)
		checkArgs
		{
			[newCF] = function () 
				local isCFrame = pcall(function () return newCF:components() end)
				return isCFrame,"CFrame"
			end
		}
		cf = newCF	
	end
	
	function lib:SetCFrame(newCF)
		lib:SetOffset(newCF)
	end
	
	function lib:GetDepth()
		local size = math.min(guiObj.AbsoluteSize.X, guiObj.AbsoluteSize.Y)
		return getDepthForWidth(maxExtent, size)
	end
	
	function lib:LoadAnimation(anim)
		checkArgs
		{
			[anim] = function ()
				return anim:IsA("Animation") or false,"Animation"
			end
		}
		return animator:LoadAnimation(anim)
	end
	
	local nowhere = CFrame.new(99999,99999,99999)
	
	local function updateModel()
		local nextCF = nowhere
		if active then
			local camCF = c.CoordinateFrame
			local sizeX,sizeY = guiObj.AbsoluteSize.X, guiObj.AbsoluteSize.Y
			local posX,posY = guiObj.AbsolutePosition.X + (sizeX / 2), guiObj.AbsolutePosition.Y + (sizeY / 2)
			local posZ = lib:GetDepth()
			nextCF = CFrame.new(c:ScreenPointToRay(posX,posY,posZ).Origin) * (camCF-camCF.p) * cf
		end
		model.PrimaryPart = rootPart
		rootPart.Anchored = true
		model:SetPrimaryPartCFrame(nextCF)
	end
	
	local con = rs.RenderStepped:connect(updateModel)
	
	function lib:End()
		con:disconnect()
	end
	
	return lib
end

return moduleAPI