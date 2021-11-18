--!strict

local Types = require(script.Parent.Types)
local withDeferredState = require(script.Parent.withDeferredState)
local withLifecycle = require(script.Parent.withLifecycle)
local Symbols = require(script.Parent.Symbols)

local Symbol_None = Symbols.None

local INIT_EMPTY_STATE = {}
table.freeze(INIT_EMPTY_STATE)

local INIT_EMPTY_PROPS = {}
table.freeze(INIT_EMPTY_PROPS)

local function classComponent(componentMethods: Types.ClassComponentMethods)
	local metatableIndex = {__index = componentMethods}
	return withDeferredState(function(getState, setState, subscribeState)
		setState(INIT_EMPTY_STATE)
		return withLifecycle(function(forceUpdate: () -> ())
			--local unsubscribeForceUpdateBinding = subscribeState(forceUpdate)
			local unsubscribeCBSet = {}--{[unsubscribeForceUpdateBinding] = true}
			local self_without_mt: Types.ClassComponentSelf = {
				props = INIT_EMPTY_PROPS :: Types.PropsArgument,
				state = getState() :: Types.ClassState,
				setState = function(
					self: Types.ClassComponentSelf,
					partialStateUpdate: Types.ClassStateUpdate
				)
					local saveState = getState()
					if typeof(partialStateUpdate) == 'table' then
						local stateChanged = false
						for key, newValue in pairs(partialStateUpdate) do
							if newValue == Symbol_None then
								newValue = nil
							end
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
								if value == Symbol_None then
									value = nil
								end
								newState[key] = value
							end
							table.freeze(newState)
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
				forceUpdate = forceUpdate,
			}
			local self = setmetatable(self_without_mt, metatableIndex)
			
			local function wrapOptionalLifecycleMethod(
				name: string
			): ((Props: Types.PropsArgument) -> ())?
				local wrapped = self[name]
				if wrapped then
					return function(props: Types.PropsArgument)
						wrapped(self)
					end
				end
				return nil
			end
			
			local _render = self.render
			local _shouldUpdate = self.shouldUpdate
			local _init = self.init
			local willUpdate; do
				local _willUpdate = self.willUpdate
				if _willUpdate then
					willUpdate = function(newProps: Types.PropsArgument)
						_willUpdate(self, newProps, getState())
					end
				end
			end
			
			return {
				render = function(props: Types.PropsArgument)
					return _render(self)
				end,
				init = function(props: Types.PropsArgument)
					self.props = props
					if _init then
						_init(self)
					end
					self.state = getState()
				end,
				didMount = wrapOptionalLifecycleMethod 'didMount',
				willUpdate = willUpdate,
				didUpdate = wrapOptionalLifecycleMethod 'didUpdate',
				shouldUpdate = function(newProps: Types.PropsArgument)
					local newState = getState()
					if _shouldUpdate then
						if _shouldUpdate(self, newProps, newState) == false then
							self.state = getState()
							self.props = newProps
							return false
						end
						newState = getState()
					end
					self.props = newProps
					self.state = newState -- We set state here specifically

					return true
				end,
				willUnmount = function(props: Types.PropsArgument)
					local cbs = {}
					for cb in pairs(unsubscribeCBSet) do
						table.insert(cbs, cb)
					end
					for i = 1, #cbs do
						task.spawn(cbs[i])
					end
					if self.willUnmount then
						self:willUnmount()
					end
				end,
			}
		end)
	end)
end

return classComponent