--!strict

local Types = require(script.Parent.Types)
local withDeferredState = require(script.Parent.withDeferredState)
local withLifecycle = require(script.Parent.withLifecycle)

local function classComponent(componentMethods: Types.ClassComponentMethods)
	local metatableIndex = {__index = componentMethods}
	return withDeferredState(function(getState, setState, subscribeState)
		setState {}
		return withLifecycle(function(forceUpdate: () -> ())
			--local unsubscribeForceUpdateBinding = subscribeState(forceUpdate)
			local unsubscribeCBSet = {}--{[unsubscribeForceUpdateBinding] = true}
			local self_without_mt: Types.ClassComponentSelf = {
				props = {} :: Types.PropsArgument,
				state = getState() :: Types.ClassState,
				setState = function(
					self: Types.ClassComponentSelf,
					partialStateUpdate: Types.ClassStateUpdate
				)
					local saveState = getState()
					if typeof(partialStateUpdate) == 'table' then
						local stateChanged = false
						for key, newValue in pairs(partialStateUpdate) do
							if saveState[key] ~= newValue then
								stateChanged = true
								break
							end
						end
						
						if stateChanged then
							local newState = {}
							for key, value in pairs(saveState) do
								newState[key] = value
							end
							for key, value in pairs(partialStateUpdate) do
								newState[key] = value
							end
							setState(newState)
						end
					else
						self:setState(partialStateUpdate(saveState, self.props))
					end
				end,
				subscribeState = function(self: Types.ClassComponentSelf, listener: () -> ())
					local unsubscribe = subscribeState(listener)
					unsubscribeCBSet[unsubscribe] = true
					return function()
						unsubscribeCBSet[unsubscribe] = nil
						unsubscribe()
					end
				end,
			}
			local self = setmetatable(self_without_mt, metatableIndex)
			
			local function wrapOptionalLifecycleMethod(
				name: string
			): ((Props: Types.PropsArgument) -> ())?
				local wrapped = self[name]
				if wrapped then
					return function(props: Types.PropsArgument)
						self.props = props
						self.state = getState()
						wrapped(self)
						self.state = getState()
					end
				end
				return nil
			end
			
			local shouldUpdate; do
				local _shouldUpdate = self.shouldUpdate
				if _shouldUpdate then
					shouldUpdate = function(newProps: Types.PropsArgument)
						return _shouldUpdate(self, newProps, getState())
					end
				end
			end
			
			return {
				render = function(props: Types.PropsArgument)
					self.props = props
					self.state = getState()
					local element = self:render()
					self.state = getState()
					return element
				end,
				init = wrapOptionalLifecycleMethod 'init',
				didMount = wrapOptionalLifecycleMethod 'didMount',
				willUpdate = wrapOptionalLifecycleMethod 'willUpdate',
				didUpdate = wrapOptionalLifecycleMethod 'didUpdate',
				shouldUpdate = shouldUpdate,
				willUnmount = function(props: Types.PropsArgument)
					self.props = props
					self.state = getState()
					local cbs = {}
					for cb in pairs(unsubscribeCBSet) do
						table.insert(cbs, cb)
					end
					for i = 1, #cbs do
						task.spawn(cbs[i])
					end
					self.state = getState()
					if self.willUnmount then
						self:willUnmount()
						self.state = getState()
					end
				end,
			}
		end)
	end)
end

return classComponent