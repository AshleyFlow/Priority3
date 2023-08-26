local RunService = game:GetService("RunService")

local HumanoidProperties = require(script:WaitForChild("HumanoidProperties")) -- contains presets of states
local Signal = require(script:WaitForChild("Signal")) require(script:WaitForChild("Red")) -- bindableevent and remotevent

local module = {}
module.Classes = {}
module.__index = module

function module.CreateClass(humanoid: Humanoid)
	local class = setmetatable({}, module)
	
	class.Humanoid = humanoid
	class.States = {}
	class.Checking = RunService.Heartbeat:Connect(function()
		local update = false
		
		for i, state in class.States do
			local allowed = true
			
			for i, check in state.Checks do
				if check() ~= true then
					allowed = false
					break
				end
			end
			
			if state.Allowed ~= allowed then
				state.Allowed = allowed
				update = true
			end
		end
		
		if update then
			class:Update()
		end
	end)
	
	for name, config in HumanoidProperties do
		class.States[name] = {
			Checks = {},
			Signal = Signal.new(),
			PrevEnabled = false,
			PrevActive = false,
			Allowed = true, -- checks
			Enabled = false,
			Active = false,
			Priority = config.Priority,
			Properties = config.Properties,
		}
	end
	
	class.Priorities = class.States
	class:SetEnabled("Default", true)
	
	module.Classes[humanoid] = class
	
	return class
end

function module.GetClass(humanoid: Humanoid)
	local existingClass = module.Classes[humanoid]
	
	return existingClass or module.CreateClass(humanoid)
end

function module:Update()
	local enabledClasses = {}

	for i, class in self.States do
		if class.Enabled then
			--[[
			local allowed = true
			
			for i, v in class.Checks do
				-- run checks
				
				if v() == true then
					-- allowed
				else
					-- not allowed
					allowed = false
					break
				end
			end
			]]
			
			if class.Allowed then
				-- allowed to be active
				table.insert(enabledClasses, {i, class.Priority})
			end
		end
	end
	
	table.sort(enabledClasses, function(a,b)
		return a[2] > b[2]
	end)
	
	for i, class in self.States do
		if enabledClasses[1][1] == i then
			-- highest priority
			class.Active = true
			
			for property, value in class.Properties do
				local success = pcall(function()
					self.Humanoid[property] = value
				end)
			end
		else
			-- not highest priority
			class.Active = false
		end
		
		if class.Enabled ~= class.PrevEnabled or class.Active ~= class.PrevActive then
			class.Signal:Fire(class.Enabled, class.Active)
			class.PrevEnabled = class.Enabled
			class.PrevActive = class.Active
		end
		
		if RunService:IsServer() then
			local Red = require(script:WaitForChild("Red")).Server("Priority3")
			Red:FireAll("SetEnabled", self.Humanoid, i, class.Enabled)
		end
	end
end

function module:ListenToChange(state_name: string)
	return self.States[state_name].Signal
end

function module:AddCheck(state_name: string, checkId: any, checkFunction: any)
	local class = self.States[state_name]
	if not class then return end

	class.Checks[checkId] = checkFunction
end

function module:RemoveCheck(state_name: string, checkId: any)
	local class = self.States[state_name]
	if not class then return end

	class.Checks[checkId] = nil
end

function module:CanActivate(state_name: string)
	local class = self.States[state_name]
	if not class then return end
	
	local priority = class.Priority
	local highestPrioritiy = 0
	
	for i, v in self.States do
		if v.Enabled and v.Allowed and v.Priority >= highestPrioritiy then
			highestPrioritiy = v.Priority
		end
	end
	
	if priority > highestPrioritiy then
		return true
	else
		return class.Active
	end
end

function module:SetEnabled(state_name: string, enabled: boolean)
	if self.States[state_name] then
		self.States[state_name].Enabled = enabled
		self:Update()
		return self.States[state_name].Active
	else
		warn("Could not find a priority class named:", state_name)
	end
end

if RunService:IsClient() then
	local Red = require(script:WaitForChild("Red")).Client("Priority3")
	
	Red:On("SetEnabled", function(humanoid: Humanoid, ...)
		local class = module.GetClass(humanoid)
		class:SetEnabled(...)
	end)
end

return module
