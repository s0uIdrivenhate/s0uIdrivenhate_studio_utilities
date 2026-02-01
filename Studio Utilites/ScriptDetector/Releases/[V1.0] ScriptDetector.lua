local h="5468616e6b20796f7520736f206d75636820666f72207573696e67206d7920536372697074204465746563746f722c20616e79206f7468657220706572736f6e20636c61696d696e6720746f20626520746865206f726967696e616c2063726561746f72206f74686572207468616e207330756964726976656e68617465206973206120736372697074206b696464696520616e642073686f756c64206265207265706f7274656420746f206d6521"
print(h:gsub("..",function(c)return string.char(tonumber(c,16))end)) -- Ignore this, it's not harmful nor dangerous!

local RUNNING_TIME = tick()
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local function assureFolder(name)
	local f = Workspace:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name  = name
		f.Parent = Workspace
	end
	return f
end

local folderScripts   = assureFolder("Detected_Scripts")
local folderLocal     = assureFolder("Detected_LocalScripts")
local folderModules   = assureFolder("Detected_ModuleScripts")

local keepNames = {
	["Detected_Scripts"]      = true,
	["Detected_LocalScripts"] = true,
	["Detected_ModuleScripts"]= true,
}


local seen = {}

local function fullPath(obj)
	local t = {}
	while obj and obj ~= game do
		table.insert(t, 1, obj.Name)
		obj = obj.Parent
	end
	return table.concat(t, ".")
end

local function addPulsingHighlight(part)
	if part:FindFirstChild("DetectedHighlight") then return end
	local h = Instance.new("Highlight")
	h.Name = "DetectedHighlight"
	h.Adornee = part
	h.FillColor = Color3.fromRGB(81,0,255)
	h.OutlineColor = Color3.fromRGB(0,34,255)
	h.FillTransparency = 0.7
	h.OutlineTransparency = 0.5
	h.Parent = part

	local tweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(h, tweenInfo, {FillTransparency = 1, OutlineTransparency = 1}):Play()
end

local detectedCount = 0

local function markAncestorOf(scriptObj)
	local ancestor = scriptObj.Parent
	while ancestor and ancestor ~= Workspace do
		if ancestor:IsA("Model") or ancestor:IsA("BasePart") then
			if not seen[ancestor] then
				seen[ancestor] = true
				return ancestor
			else
				return nil
			end
		end
		ancestor = ancestor.Parent
	end
	if not seen[scriptObj] then
		seen[scriptObj] = true
		return scriptObj
	end
	return nil
end

local function handleScript(scriptObj)
	if not scriptObj:IsA("LuaSourceContainer") then return end
	if seen[scriptObj] then return end
	seen[scriptObj] = true

	if scriptObj:IsA("Script") or scriptObj:IsA("LocalScript") then
		scriptObj.Disabled = true
	elseif scriptObj:IsA("ModuleScript") then
		scriptObj.Parent = nil
	end

	local clone = scriptObj:Clone()
	if scriptObj:IsA("LocalScript") then
		clone.Parent = folderLocal
	elseif scriptObj:IsA("ModuleScript") then
		clone.Parent = folderModules
	elseif scriptObj:IsA("Script") then
		clone.Parent = folderScripts
	end
	warn("Info: detected & disabled script in \"" .. fullPath(scriptObj) .. "\"")

	local ancestor = scriptObj.Parent
	while ancestor and ancestor ~= Workspace do
		if ancestor:IsA("Model") or ancestor:IsA("BasePart") then
			if not seen[ancestor] then
				seen[ancestor] = true
				for _, p in ipairs(ancestor:GetDescendants()) do
					if p:IsA("BasePart") then addPulsingHighlight(p) end
				end
				if ancestor:IsA("BasePart") then addPulsingHighlight(ancestor) end
			end
			break
		end
		ancestor = ancestor.Parent
	end

	detectedCount = detectedCount + 1
end

local function scan(root)
	for _, child in ipairs(root:GetChildren()) do
		if keepNames[child.Name] then continue end

		if child:IsA("LuaSourceContainer") then
			handleScript(child)
		end

		for _, script in ipairs(child:GetDescendants()) do
			if script:IsA("LuaSourceContainer") then
				handleScript(script)
			end
		end

		if child:IsA("PVInstance") then
			scan(child)
		end
	end
end

scan(Workspace)

local elapsed = tick() - RUNNING_TIME
warn(string.format("Scan complete! %d script(s) disabled, cloned & pulsing in %.2f s.",
	detectedCount, elapsed))
