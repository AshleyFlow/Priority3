# <div align="center">deprecated in favor of priority 5</div>
https://github.com/HighFlowey/Priority

# <div align="center">Priority3 [statemachine]</div>
## Priority based state machine for Roblox
<hr>

you can use this module to easily add priority based states to your humanoids or other types of instances and have full control over them

# <div align="center">Get</div>
<hr>

### Roblox marketplace:
https://www.roblox.com/library/14087292942/Priority3

### Github:
https://github.com/HighFlowey/Priority3/releases/tag/Release
<hr>

# <div align="center">API Document</div>
<hr>

### **Properties**

* class.State: **string** --> current active state

* ~~class.Priorities.StateName: **state** (read-only)~~ replaced with class.States.StateName but it still works

* class.States.StateName: **state** (read-only)

* state.Properties: **table** → example: {WalkSpeed = 16}

* state.PrevEnabled: **boolean** (read-only) --> changes to state.Enabled after class:ListenToChange is fired

* state.PrevActive: **boolean** (read-only) --> changes to state.Active after class:ListenToChange is fired

* state.Enabled: **boolean** (read-only)

* state.Active: **boolean** (read-only)

* state.Checks: **table** --> contains functions that give permission for activating the state

### **Functions**

* module.GetClass( object: Instance ): **class**

* module.CreateStateConfig(info: {} | nil): Stateconfig

### **Methods**

* class:SetEnabled( state_name: string, enabled: boolean ): **boolean** --> enables/disables the state and returns its active property

* class:AddState(config: Stateconfig): void

* class:RemoveState(state_name: string): void

* class:Update(): **void** --> use this after manually changing properties of a state

* class:AddCheck(state_name: string, checkId: string|any, checkFunction: function) --> add a check function for a state to let the module know if its allowed to activate it or not (return true to allow return nothing to not allow) also it checks run checks after every frame

* class:CanActivate(state_name: string): **boolean** --> returns true if a state can have the highest priority among other enable states

### **Events**
* class:ListenToChange( state_name: string ):Connect(enabled: boolean, active: boolean): **RBXScriptConnection**
