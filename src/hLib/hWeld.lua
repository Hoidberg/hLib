return function(Part0, Part1)
	if typeof(Part0) == "Instance" and typeof(Part1) == "Instance" then
		local Weld = Instance.new("Weld", Part0)
		Weld.Name = ("%s_hWeld"):format(Part1.Name)
		Weld.Part0 = Part0
		Weld.Part1 = Part1
		Weld.C0 = Part0.CFrame:inverse()
		Weld.C1 = Part1.CFrame:inverse()
	end
end
