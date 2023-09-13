local RunService = game:GetService("RunService")

-- a table with premade priorities
local HumanoidProperties = require(script:WaitForChild("HumanoidProperties"))
-- a module for bindable events and a module for remote events
local Signal = require(script:WaitForChild("Signal")) require(script:WaitForChild("Red"))

local stateconfig = {}
stateconfig.Name = "NewState"
stateconfig.Priority = 0
stateconfig.Properties = {}
stateconfig.__index = stateconfig

local statemachine = {}
statemachine.__index = statemachine

local module = {}
module.Classes = {}

function module.CreateStateConfig(info: {}): Stateconfig
	info = info or {}
	return setmetatable(info, stateconfig)
end

function module.CreateClass(humanoid: Humanoid): Statemachine
	local class = setmetatable({}, statemachine)
	
	class.Humanoid = humanoid
	class.State = ""
	class.States = {}
	class.CheckingRate = 200
	class.CheckingLast = time()-class.CheckingRate
	class.Checking = RunService.Heartbeat:Connect(function()
		if time() - class.CheckingLast < class.CheckingRate then return end
		
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
		local config = {
			Name = name,
			Priority = config.Priority,
			Properties = config.Properties
		}
		
		local newConfig = setmetatable(config, stateconfig)
		class:AddState(newConfig)
	end
	
	class.Priorities = class.States
	
	module.Classes[humanoid] = class
	
	return class
end

function module.GetClass(humanoid: Humanoid): Statemachine
	local existingClass = module.Classes[humanoid]
	
	return existingClass or module.CreateClass(humanoid)
end

function statemachine.AddState(self: Statemachine, stateconfig: Stateconfig)
	stateconfig = stateconfig or module.CreateStateConfig()
	
	if self.States[stateconfig.Name] then
		warn("State with this name already exists:", stateconfig.Name)
	else
		self.States[stateconfig.Name] = {
			Checks = {},
			Signal = Signal.new(),
			PrevEnabled = stateconfig.Name == "Default",
			PrevActive = false,
			Allowed = true, -- checks
			Enabled = stateconfig.Name == "Default",
			Active = false,
			Priority = stateconfig.Priority,
			Properties = stateconfig.Properties,
		}
		
		self:Update()
	end
end

function statemachine.RemoveState(self: Statemachine, state_name: string)
	if self.States[state_name] then
		self.States[state_name] = nil
		self:Update()
	end
end

function statemachine.Update(self: Statemachine)
	local enabledClasses = {}

	for i, class in self.States do
		if class.Enabled then
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
		if #enabledClasses > 0 and enabledClasses[1][1] == i then
			-- highest priority
			class.Active = true
			
			for property, value in class.Properties do
				local success = pcall(function()
					self.Humanoid[property] = value
				end)
			end
			
			self.State = i
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

function statemachine.ListenToChange(self: Statemachine, state_name: string): RBXScriptSignal
	return self.States[state_name].Signal
end

function statemachine.AddCheck(self: Statemachine, state_name: string, checkId: any, checkFunction: () -> ())
	if self.States[state_name] then
		self.Checks[checkId] = checkFunction
	else
		warn("Could not find a state with this name:", state_name)
	end
end

function statemachine.RemoveCheck(self: Statemachine, state_name: string, checkId: () -> ())
	if self.States[state_name] then
		self.Checks[checkId] = nil
	else
		warn("Could not find a state with this name:", state_name)
	end
end

function statemachine.CanActivate(self: Statemachine, state_name: string)
	if self.States[state_name] then
		local priority = self.Priority
		local highestPrioritiy = 0

		for i, v in self.States do
			if v.Enabled and v.Allowed and v.Priority >= highestPrioritiy then
				highestPrioritiy = v.Priority
			end
		end

		if priority > highestPrioritiy then
			return true
		else
			return self.Active
		end
	else
		warn("Could not find a state with this name:", state_name)
	end
end

function statemachine.SetEnabled(self: Statemachine, state_name: string, enabled: boolean)
	if self.States[state_name] then
		self.States[state_name].Enabled = enabled
		self:Update()
		return self.States[state_name].Active
	else
		warn("Could not find a state with this name:", state_name)
	end
end

if RunService:IsClient() then
	local Red = require(script:WaitForChild("Red")).Client("Priority3")
	
	Red:On("SetEnabled", function(humanoid: Humanoid, ...)
		local class = module.GetClass(humanoid)
		class:SetEnabled(...)
	end)
end

export type Statemachine = typeof(module.GetClass(script))
export type Stateconfig = typeof(setmetatable({}, stateconfig))

return module
