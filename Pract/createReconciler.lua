--!strict
local CollectionService = game:GetService('CollectionService')
local Types = require(script.Parent.Types)
local PractGlobalSystems = require(script.Parent.PractGlobalSystems)

local Symbols = require(script.Parent.Symbols)
local ElementKinds = Symbols.ElementKinds
local Symbol_ElementKind = Symbols.ElementKind
local Symbol_None = Symbols.None
local Symbol_Children = Symbols.Children

local APPLY_PROPS_ERROR = [[
Error applying props:
	%s
]]

local TEMPLATE_STAMP_ERROR = [[
Error creating stamp:
	%s
]]

local UPDATE_PROPS_ERROR = [[
Error updating props:
	%s
]]

local MISSING_PARENT_ERROR = [[
Attempt to mount index or decorate node on a nil parent host
]]

local DEFAULT_CREATED_CHILD_NAME = "PractTree"

local NOOP = function() end

-- Creates a closure-based reconciler which handles Pract systems globally

local function createReconciler(): Types.Reconciler
	local reconciler: Types.Reconciler
	local mountVirtualNode: (
		element: Types.Element | boolean | nil,
		hostContext: Types.HostContext
	) -> Types.VirtualNode?
	local updateVirtualNode: (
		virtualNode: Types.VirtualNode,
		newElement: Types.Element | boolean | nil
	) -> Types.VirtualNode?
	local unmountVirtualNode: (virtualNode: Types.VirtualNode) -> ()
	local updateChildren: (
		virtualNode: Types.VirtualNode,
		hostParent: Instance,
		childElements: {Types.Element}?
	) -> ()
	local mountVirtualTree: (
		element: Types.Element,
		hostInstance: Instance?,
		hostKey: string?
	) -> Types.PractTree
	local updateVirtualTree
	local unmountVirtualTree

	-- Closure for calling functional components with hook context included, as well as
	-- unmounting these components.
	local mountChildFunctionalComponent
	local updateChildFunctionalComponent
	local unmountChildFunctionalComponent
	do
		local currentHookParentNode: Types.VirtualNode? = nil
		local currentHookComponent: Types.Component? = nil
		local currentHookProps: Types.PropsArgument? = nil
		local currentHookNextContext: Types.ComponentHookContext? = nil
		local currentMountingHostContext: Types.HostContext? = nil

		local function compareDeps(
			lastDeps: {any}?,
			nextDeps: {any}?
		)
			if lastDeps and nextDeps then
				if #lastDeps == #nextDeps then
					for i = 1, #lastDeps do
						if lastDeps[i] ~= nextDeps[i] then
							return false
						end
					end

					return true
				end
				return false
			end
			-- If either dependencies are nil, break memoization
			return false
		end

		local function cleanupLastHookContext(
			lastHookContext: Types.ComponentHookContext?,
			nextHookContext: Types.ComponentHookContext?
		)
			if lastHookContext then
				local nextOrderedStates = nil
				if nextHookContext then
					nextOrderedStates = nextHookContext.orderedStates
				end

				local lastOrderedStates = lastHookContext.orderedStates
				local lastUseEffectStates = lastOrderedStates.useEffect
				if lastUseEffectStates then
					local nextUseEffectStates = nil
					if nextOrderedStates then
						nextUseEffectStates = nextOrderedStates.useEffect
					end

					for
						i = if nextUseEffectStates then (#nextUseEffectStates + 1) else 1,
							#lastUseEffectStates
					do
						local lastState = lastUseEffectStates[i]
						local cleanup = lastState.cleanup
						local saveCancelled = lastState.cancelled
						lastState.cancelled = true
						if cleanup and not saveCancelled then
							task.spawn(cleanup)
						end
					end
				end
				local lastCustomHookStates = lastOrderedStates.customHook
				if lastCustomHookStates then
					local nextCustomHookStates = nil
					if nextOrderedStates then
						nextCustomHookStates = nextOrderedStates.customHook
					end

					for
						i = if nextCustomHookStates then (#nextCustomHookStates + 1) else 1,
							#lastCustomHookStates
					do
						local lastState = lastCustomHookStates[i]
						local cleanup = lastState.closure.cleanup
						if cleanup then
							task.spawn(cleanup)
						end
					end
				end
			end
		end

		-- Current conventional requirement from reconciler: the functional component
		-- child node muMUSTst ALWAYS have a single "_child" node under it.
		local function callChildFunctionalComponent(
			parentNode: Types.VirtualNode,
			component: Types.Component,
			props: Types.PropsArgument,
			mountingHostContext: Types.HostContext?
		)
			currentHookParentNode = parentNode
			currentHookComponent = component
			currentHookProps = props
			currentMountingHostContext = mountingHostContext
			-- Always reset here in case external code errored last reconcile
			currentHookNextContext = nil
			
			local saveHookContext = parentNode._hookContext
			local element = component(props)
			parentNode._childLastComponent = component
			parentNode._childLastProps = props
			
			-- Clean up all hook side effects beyond what was newly defined
			if saveHookContext ~= currentHookNextContext then
				cleanupLastHookContext(saveHookContext, currentHookNextContext)
				parentNode._hookContext = currentHookNextContext
			end
			
			currentHookParentNode = nil
			currentHookComponent = nil
			currentHookProps = nil
			currentHookNextContext = nil
			return element
		end

		local function assertInRenderPhase()
			if not currentHookParentNode then
				error(
					'Invalid hook call. Pract hooks can only be called inside of the body '
					.. ' of a function component. This could happen for one of the '
					.. ' following reasons:\n'
					.. '1. You might be breaking the Rules of Hooks\n'
					.. '2. You might have more than one copy of Pract in the same app\n'
					.. 'See https://reactjs.org/link/invalid-hook-call for tips about how'
					.. 'to debug and fix this problem.'
				)
			end
		end

		local function getLastHookContext(): Types.ComponentHookContext?
			return (currentHookParentNode :: Types.VirtualNode)._hookContext
		end
		local function getNextHookContext(): Types.ComponentHookContext
			if currentHookNextContext then
				return currentHookNextContext
			else
				local cacheQueueUpdateClosure = nil
				local lastContext = (currentHookParentNode :: Types.VirtualNode)._hookContext
				if lastContext then
					cacheQueueUpdateClosure = lastContext.cacheQueueUpdateClosure
				end

				local nextContext: Types.ComponentHookContext = {
					orderedStates = {},
					createdHeartbeatCount = PractGlobalSystems.HeartbeatFrameCount,
					cacheQueueUpdateClosure = cacheQueueUpdateClosure
				}
				currentHookNextContext = nextContext
				return nextContext
			end
		end
		local function getOrderedStateIndex(
			nextHookContext: Types.ComponentHookContext,
			id: string
		): number
			local orderedStates = nextHookContext.orderedStates[id]
			if orderedStates then
				return #orderedStates + 1
			else
				return 1
			end
		end

		local function createQueueUpdateClosure()
			assertInRenderPhase()

			local context = currentHookNextContext :: Types.ComponentHookContext
			if not context then
				return function() end
			end

			if context.cacheQueueUpdateClosure then
				return context.cacheQueueUpdateClosure
			end
			
			local closure_parentNode = currentHookParentNode :: Types.VirtualNode
			local alreadyQueueing = false
			local lastUpdateHeartbeatCount = context.createdHeartbeatCount
			local function queueUpdate()
				if closure_parentNode._wasUnmounted then
					return
				end
				if alreadyQueueing then
					return
				end
				
				alreadyQueueing = true

				task.defer(function()
					if closure_parentNode._wasUnmounted then
						return
					end

					if
						PractGlobalSystems.HeartbeatFrameCount
						== lastUpdateHeartbeatCount
					then
						PractGlobalSystems.HeartbeatSignal:Wait()
					end
					
					if closure_parentNode._wasUnmounted then
						return
					end
					
					alreadyQueueing = false
					lastUpdateHeartbeatCount = PractGlobalSystems.HeartbeatFrameCount
					updateChildFunctionalComponent(
						closure_parentNode,
						closure_parentNode._childLastComponent,
						closure_parentNode._childLastProps
					)
				end)
			end
			context.cacheQueueUpdateClosure = queueUpdate
			return queueUpdate
		end
		
		PractGlobalSystems._reconcilerHookCallbacks = {
			useState = function(initialState)
				assertInRenderPhase()
				local lastHookContext = getLastHookContext()
				local nextHookContext = getNextHookContext()
				local index = getOrderedStateIndex(
					nextHookContext,
					"useState"
				)
				
				local lastOrderedState = nil
				if lastHookContext then
					local lastOrderedStates = lastHookContext.orderedStates.useState
					if lastOrderedStates then
						lastOrderedState = lastOrderedStates[index]
					end
				end

				local nextStateValue = nil
				if lastOrderedState ~= nil then
					nextStateValue = lastOrderedState.value
				else
					if typeof(initialState) == "function" then
						nextStateValue = (initialState :: any)()
					else
						nextStateValue = initialState
					end
				end
				
				local nextOrderedStates
				do
					local _nextOrderedStates = nextHookContext.orderedStates.useState
					if _nextOrderedStates then
						nextOrderedStates = _nextOrderedStates
					else
						nextOrderedStates = {}
						nextHookContext.orderedStates.useState = nextOrderedStates
					end
				end
				
				local cacheSetState
				if lastOrderedState then
					cacheSetState = lastOrderedState.setState
				else
					local queueUpdate = createQueueUpdateClosure()
					local closure_parentNode = currentHookParentNode :: Types.VirtualNode
					
					cacheSetState = function(stateUpdate)
						-- setState and queueUpdate calls are currently expected
						-- to be able to be called from any point, including
						-- inside a render function.
						-- Updates will simply be deferred until all non-yielding
						-- threads finish.
						
						-- This allows for behavior such as calling setState twice
						-- in a row without reconciling twice in a row,
						-- as well as calling setState during an effect.
						
						task.defer(function()
							local latestContext = closure_parentNode._hookContext
							if latestContext and not closure_parentNode._wasUnmounted then
								local latestOrderedStates = latestContext.orderedStates.useState
								if latestOrderedStates then
									latestOrderedStates[index] = {
										value = stateUpdate,
										setState = cacheSetState
									}
									queueUpdate()
								end
							end
						end)
					end
				end
				table.insert(
					nextOrderedStates,
					{
						value = nextStateValue,
						setState = cacheSetState
					}
				)

				return nextStateValue, cacheSetState
			end,
			useMemo = function(create, nextDeps)
				assertInRenderPhase()
				local lastHookContext = getLastHookContext()
				local nextHookContext = getNextHookContext()
				local index = getOrderedStateIndex(
					nextHookContext,
					"useMemo"
				)
				
				local lastOrderedState = nil
				if lastHookContext then
					local lastOrderedStates = lastHookContext.orderedStates.useMemo
					if lastOrderedStates then
						lastOrderedState = lastOrderedStates[index]
					end
				end
				
				local nextStateValue = nil
				if lastOrderedState ~= nil and compareDeps(lastOrderedState.deps, nextDeps) then
					nextStateValue = lastOrderedState.value
				else
					nextStateValue = create()
				end
				
				local nextOrderedStates
				do
					local _nextOrderedStates = nextHookContext.orderedStates.useMemo
					if _nextOrderedStates then
						nextOrderedStates = _nextOrderedStates
					else
						nextOrderedStates = {}
						nextHookContext.orderedStates.useMemo = nextOrderedStates
					end
				end
				table.insert(nextOrderedStates, { value = nextStateValue, deps = nextDeps :: any })
				return nextStateValue
			end,
			useEffect = function(effect, nextDeps)
				assertInRenderPhase()
				local lastHookContext = getLastHookContext()
				local nextHookContext = getNextHookContext()
				local index = getOrderedStateIndex(
					nextHookContext,
					"useEffect"
				)
				
				local lastOrderedState = nil
				if lastHookContext then
					local lastOrderedStates = lastHookContext.orderedStates.useEffect
					if lastOrderedStates then
						lastOrderedState = lastOrderedStates[index]
					end
				end

				local shouldRunEffect
				local reuseCleanup: (() -> ())? = nil
				if lastOrderedState ~= nil then
					if nextDeps and compareDeps(lastOrderedState.deps, nextDeps) then
						shouldRunEffect = false
						reuseCleanup =  lastOrderedState.cleanup
					else
						lastOrderedState.cancelled = true
						local cleanup = lastOrderedState.cleanup
						if cleanup then
							task.spawn(cleanup)
						end
						shouldRunEffect = true
					end
				else
					shouldRunEffect = true
				end

				local nextState = {
					deps = nextDeps :: {any}?,
					cleanup = reuseCleanup,
					cancelled = false
				}
				if shouldRunEffect then
					local queueUpdate = createQueueUpdateClosure()
					task.spawn(function()
						local cleanup = (effect :: any)(queueUpdate)
						if nextState.cancelled then
							if cleanup then
								cleanup()
							end
							return
						end
						nextState.cleanup = cleanup
					end)
				end
				
				local nextOrderedStates
				do
					local _nextOrderedStates = nextHookContext.orderedStates.useEffect
					if _nextOrderedStates then
						nextOrderedStates = _nextOrderedStates
					else
						nextOrderedStates = {}
						nextHookContext.orderedStates.useEffect = nextOrderedStates
					end
				end
				table.insert(nextOrderedStates, nextState)
			end,
			useConsumer = function(context: any)
				assertInRenderPhase()
				local childContext; do
					local childNode = (currentHookParentNode :: any)._child :: Types.VirtualNode?
					if childNode then
						childContext = childNode._hostContext
					else
						childContext = currentMountingHostContext
							or (currentHookParentNode :: Types.VirtualNode)._hostContext
					end
				end
				local providerChain = childContext.providers
				
				local key = context._symbol
				for i = #providerChain, 1, -1 do
					local provider = providerChain[i]
					local object = provider.find(key)
					if object then
						return object.getValue()
					end
				end
				
				error(tostring(context) .. " was not provided by a parent component!")
			end,
			customHook = (function<HookArgs..., HookReturns...>(
				lifecycleClosureCB: (
					queueUpdate: () -> ()
				) -> Types.CustomHookLifecycle<(HookArgs...) -> HookReturns...>,
				...: HookArgs...
			): HookReturns...
				assertInRenderPhase()
				local lastHookContext = getLastHookContext()
				local nextHookContext = getNextHookContext()
				local index = getOrderedStateIndex(
					nextHookContext,
					"customHook"
				)
				
				local lastOrderedState = nil
				if lastHookContext then
					local lastOrderedStates = lastHookContext.orderedStates.customHook
					if lastOrderedStates then
						lastOrderedState = lastOrderedStates[index]
					end
				end
				
				local shouldCreateClosure
				if lastOrderedState ~= nil then
					if lifecycleClosureCB ~= lastOrderedState.createClosure then
						shouldCreateClosure = true

						local lastClosureCleanup = lastOrderedState.closure.cleanup
						if lastClosureCleanup then
							task.spawn(lastClosureCleanup)
						end
					else
						shouldCreateClosure = false
					end
				else
					shouldCreateClosure = true
				end

				local nextClosure
				if shouldCreateClosure then
					local queueUpdate = createQueueUpdateClosure()
					nextClosure = lifecycleClosureCB(queueUpdate)
				else
					nextClosure = (lastOrderedState :: any).closure
				end

				local nextState = {
					closure = nextClosure,
					createClosure = lifecycleClosureCB,
				}

				local nextOrderedStates
				do
					local _nextOrderedStates = nextHookContext.orderedStates.customHook
					if _nextOrderedStates then
						nextOrderedStates = _nextOrderedStates
					else
						nextOrderedStates = {}
						nextHookContext.orderedStates.customHook = nextOrderedStates
					end
				end
				table.insert(nextOrderedStates, nextState)

				return nextClosure.call(...)
			end) :: any, 
		}

		mountChildFunctionalComponent = function(
			parentNode: Types.VirtualNode,
			component: Types.Component,
			props: Types.PropsArgument,
			context: Types.HostContext?
		)
			parentNode._child = mountVirtualNode(
				callChildFunctionalComponent(
					parentNode,
					component,
					props,
					context
				),
				context or parentNode._hostContext
			)
		end

		updateChildFunctionalComponent = function(
			parentNode: Types.VirtualNode,
			component: Types.Component,
			props: Types.PropsArgument
		)
			parentNode._child = updateVirtualNode(
				parentNode._child,
				callChildFunctionalComponent(
					parentNode,
					component,
					props
				)
			)
		end

		unmountChildFunctionalComponent = function(parentNode: Types.VirtualNode)
			cleanupLastHookContext(parentNode._hookContext, nil)
			unmountVirtualNode(parentNode._child)
		end
	end
	
	local function replaceVirtualNode(
		virtualNode: Types.VirtualNode,
		newElement: Types.Element
	): Types.VirtualNode?
		local hostContext = virtualNode._hostContext
		
		-- If updating this node has caused a component higher up the tree to re-render
		-- and updateChildren to be re-entered then this node could already have been
		-- unmounted in the previous updateChildren pass.
		if not virtualNode._wasUnmounted then
			unmountVirtualNode(virtualNode)
		end

		return mountVirtualNode(newElement, hostContext)
	end
	
	local applyDecorationProp: (
			virtualNode: Types.VirtualNode,
		propKey: string,
		newValue: any,
		oldValue: any,
		eventMap: {[any]: RBXScriptConnection?},
		instance: Instance
	) -> (); do
		local specialApplyPropHandlers = {} :: {
			[any]: (
				virtualNode: Types.VirtualNode,
				newValue: any,
				oldValue: any,
				eventMap: {[any]: RBXScriptConnection?},
				instance: Instance
			) -> ()
		}
		specialApplyPropHandlers[Symbol_Children] = NOOP -- Handled in a separate pass
		specialApplyPropHandlers[Symbols.OnUnmountWithHost] = NOOP -- Handled in unmount
		specialApplyPropHandlers[Symbols.OnMountWithHost] = NOOP -- Handled in mount
		specialApplyPropHandlers[Symbols.OnRenderWithHost] = NOOP -- Handled in update
		
		specialApplyPropHandlers[Symbols.Attributes] = function(
			virtualNode,
			newValue,
			oldValue,
			eventMap,
			instance
		)
			if newValue == oldValue then return end
			if oldValue == nil then
				for attrKey, attrValue in pairs(newValue) do
					if attrValue == Symbol_None then
						instance:SetAttribute(attrKey, nil)
					else
						instance:SetAttribute(attrKey, attrValue)
					end
				end
			elseif newValue == nil then
				-- Leave a footprint unless None is explicitly specified
			else
				for attrKey, attrValue in pairs(newValue) do
					if attrValue == Symbol_None then
						attrValue = nil
					end
					
					if oldValue[attrKey] ~= attrValue then
						instance:SetAttribute(attrKey, attrValue)
					end
				end
				for attrKey, oldValue in pairs(newValue) do
					if newValue[attrKey] == nil then
						instance:SetAttribute(attrKey, nil)
					end
				end
			end
		end
		
		do
			specialApplyPropHandlers[Symbols.CollectionServiceTags] = function(
				virtualNode,
				newValue,
				oldValue,
				eventMap,
				instance
			)
				if newValue == oldValue then return end
				if oldValue == nil then
					for i = 1, #newValue do
						if not CollectionService:HasTag(instance, newValue[i]) then
							CollectionService:AddTag(instance, newValue[i])
						end
					end
				elseif newValue == nil then
					for i = 1, #oldValue do
						if CollectionService:HasTag(instance, oldValue[i]) then
							CollectionService:RemoveTag(instance, oldValue[i])
						end
					end
				else
					local oldTagsSet = {}
					for i = 1, #oldValue do
						oldTagsSet[oldValue[i]] = true
					end
					
					local newTagsSet = {}
					for i = 1, #newValue do
						newTagsSet[newValue[i]] = true
					end
					
					for i = 1, #oldValue do
						local tag = oldValue[i]
						if not newTagsSet[tag] then
							CollectionService:RemoveTag(instance, tag)
						end
					end
					
					for i = 1, #newValue do
						local tag = newValue[i]
						if not oldTagsSet[tag] then
							CollectionService:AddTag(instance, tag)
						end
					end
				end
			end
		end
		
		do
			local function applyAttrChangedSignal(
				virtualNode: Types.VirtualNode,
				attrKey: string,
				newValue: any,
				oldValue: any,
				eventMap: {[any]: RBXScriptConnection?},
				instance: Instance
			)
				if oldValue == Symbol_None then
					oldValue = nil
				end
				if newValue == Symbol_None then
					newValue = nil
				end
				if newValue == oldValue then return end
				local signal = instance:GetAttributeChangedSignal(attrKey)
				if oldValue == nil then
					eventMap[attrKey] = signal:Connect(function(...)
						local cbMap = virtualNode._currentElement.props
							[Symbols.AttributeChangedSignals]
						if cbMap then
							local cb = cbMap[attrKey]
							if cb then
								if virtualNode._deferDecorationEvents then
									local args = table.pack(...)
									task.defer(function()
										if virtualNode._wasUnmounted then return end
										cb(instance, table.unpack(args, 1, args.n))
									end)
								else
									cb(instance, ...)
								end
							end
						end
					end)
				end
			end
			specialApplyPropHandlers[Symbols.AttributeChangedSignals] = function(
				virtualNode,
				newValue,
				oldValue,
				eventMap,
				instance
			)
				if newValue == oldValue then return end
				
				local attrsChangedEventMap
				if oldValue == nil then
					attrsChangedEventMap = {}
					eventMap[Symbols.AttributeChangedSignals] = attrsChangedEventMap :: any
					for attrKey, cb in pairs(newValue) do
						applyAttrChangedSignal(virtualNode, attrKey, cb, nil,
							attrsChangedEventMap, instance)
					end
				elseif newValue == nil then
					attrsChangedEventMap = eventMap[Symbols.AttributeChangedSignals] :: any
					for attrKey, oldCB in pairs(oldValue) do
						applyAttrChangedSignal(virtualNode, attrKey, nil, oldCB,
							attrsChangedEventMap, instance)
					end
				else
					attrsChangedEventMap = eventMap[Symbols.AttributeChangedSignals] :: any
					for attrKey, oldCB in pairs(oldValue) do
						applyAttrChangedSignal(virtualNode, attrKey, newValue[attrKey], oldCB,
							attrsChangedEventMap, instance)
					end
					for attrKey, cb in pairs(newValue) do
						if not oldValue[attrKey] then
							applyAttrChangedSignal(virtualNode, attrKey, cb, nil,
								attrsChangedEventMap, instance)
						end
					end
				end
			end
		end
		
		do
			local function applyPropChangedSignal(
				virtualNode: Types.VirtualNode,
				propKey: string,
				newValue: any,
				oldValue: any,
				eventMap: {[any]: RBXScriptConnection?},
				instance: Instance
			)
				if oldValue == Symbol_None then
					oldValue = nil
				end
				if newValue == Symbol_None then
					newValue = nil
				end
				local signal = instance:GetPropertyChangedSignal(propKey)
				if oldValue == nil then
					eventMap[propKey] = signal:Connect(function(...)
						local cbMap = virtualNode._currentElement.props
							[Symbols.PropertyChangedSignals]
						if cbMap then
							local cb = cbMap[propKey]
							if cb then
								if virtualNode._deferDecorationEvents then
									local args = table.pack(...)
									task.defer(function()
										if virtualNode._wasUnmounted then return end
										cb(instance, table.unpack(args, 1, args.n))
									end)
								else
									cb(instance, ...)
								end
							end
						end
					end)
				end
			end
			specialApplyPropHandlers[Symbols.PropertyChangedSignals] = function(
				virtualNode,
				newValue,
				oldValue,
				eventMap,
				instance
			)
				if oldValue == Symbol_None then
					oldValue = nil
				end
				if newValue == Symbol_None then
					newValue = nil
				end
				if newValue == oldValue then return end
				local propsChangedEventMap
				if oldValue == nil then
					propsChangedEventMap = {}
					eventMap[Symbols.PropertyChangedSignals] = propsChangedEventMap :: any
					for propKey, cb in pairs(newValue) do
						applyPropChangedSignal(virtualNode, propKey, cb, nil,
							propsChangedEventMap, instance)
					end
				elseif newValue == nil then
					propsChangedEventMap = eventMap[Symbols.PropertyChangedSignals] :: any
					for propKey, oldCB in pairs(oldValue) do
						applyPropChangedSignal(virtualNode, propKey, nil, oldCB,
							propsChangedEventMap, instance)
					end
				else
					propsChangedEventMap = eventMap[Symbols.PropertyChangedSignals] :: any
					for propKey, oldCB in pairs(oldValue) do
						applyPropChangedSignal(virtualNode, propKey, newValue[propKey], oldCB,
							propsChangedEventMap, instance)
					end
					for propKey, cb in pairs(newValue) do
						if not oldValue[propKey] then
							applyPropChangedSignal(virtualNode, propKey, cb, nil,
								propsChangedEventMap, instance)
						end
					end
				end
			end
		end
		
		function applyDecorationProp(
			virtualNode: Types.VirtualNode,
			propKey: string,
			newValue: any,
			oldValue: any,
			eventMap: {[any]: RBXScriptConnection?},
			instance: Instance
		)
			if oldValue == Symbol_None then
				oldValue = nil
			end
			if newValue == Symbol_None then
				newValue = nil
			end
			local handler = specialApplyPropHandlers[propKey]
			if handler then
				handler(virtualNode, newValue, oldValue, eventMap, instance)
				return
			end
			
			if newValue == oldValue then return end
			
			if oldValue == nil then
				local defaultValue = (instance :: any)[propKey]
				if typeof(defaultValue) == 'RBXScriptSignal' then
					eventMap[propKey] = defaultValue:Connect(function(...)
						local cb = virtualNode._currentElement.props[propKey]
						if cb then
							if virtualNode._deferDecorationEvents then
								local args = table.pack(...)
								task.defer(function()
									if virtualNode._wasUnmounted then return end
									cb(instance, table.unpack(args, 1, args.n))
								end)
							else
								cb(instance, ...)
							end
						end
					end)
				else
					(instance :: any)[propKey] = newValue
				end
			elseif newValue == nil then
				local conn = eventMap[propKey]
				if conn then
					conn:Disconnect()
				end
				
				-- Else we don't do anything to this property unless it's specified as None.
				-- Pract can leave footprints in property changes.
			else
				if eventMap[propKey] then	-- The new callback will automatically be located if the
											-- event fires.
					return
				end
				(instance :: any)[propKey] = newValue
			end
		end
	end
	
	local function updateDecorationProps(
		virtualNode: Types.VirtualNode,
		newProps: Types.PropsArgument,
		oldProps: Types.PropsArgument,
		instance: Instance
	)
		local eventMap = virtualNode._eventMap
		virtualNode._deferDecorationEvents = true
		virtualNode._lastUpdateInstance = instance
		
		-- Apply props that were added or updated
		for propKey, newValue in pairs(newProps) do
			local oldValue = oldProps[propKey]
			
			applyDecorationProp(
				virtualNode, propKey, newValue, oldValue, eventMap, instance)
		end
		
		-- Clean up props that were removed
		for propKey, oldValue in pairs(oldProps) do
			local newValue = newProps[propKey]
			
			if newValue == nil then
				applyDecorationProp(
					virtualNode, propKey, nil, oldValue, eventMap, instance)
			end
		end
		
		virtualNode._deferDecorationEvents = false
	end
	local function updateLifecycleProps(
		newProps: Types.PropsArgument,
		instance: Instance
	)
		local onUpdateCB = newProps[Symbols.OnRenderWithHost]
		if onUpdateCB then
			task.spawn(onUpdateCB, instance, newProps)
		end
	end
	local function mountDecorationProps(
		virtualNode: Types.VirtualNode,
		props: Types.PropsArgument,
		instance: Instance
	)
		virtualNode._lastUpdateInstance = instance
		
		local eventMap = {}
		virtualNode._eventMap = eventMap
		
		virtualNode._deferDecorationEvents = true
		
		for propKey, initValue in pairs(props) do
			applyDecorationProp(
				virtualNode, propKey, initValue, nil, eventMap, instance)
		end
		
		virtualNode._deferDecorationEvents = false
	end

	local function mountLifecycleProps(
		virtualNode: Types.VirtualNode,
		props: Types.PropsArgument,
		instance: Instance
	)
		local onMountCB = props[Symbols.OnMountWithHost]
		if onMountCB then
			task.spawn(
				onMountCB,
				instance,
				props,
				function(cleanupCallback: () -> ())
					if virtualNode._wasUnmounted then
						cleanupCallback()
						return
					end
					
					local specialPropCleanupCallbacks
						= virtualNode._specialPropCleanupCallbacks
					if not specialPropCleanupCallbacks then
						specialPropCleanupCallbacks = {}
						virtualNode._specialPropCleanupCallbacks
							= specialPropCleanupCallbacks
					end
					table.insert(specialPropCleanupCallbacks, cleanupCallback)
				end
			)
		end

		updateLifecycleProps(props, instance)
	end
	
	local function unmountDecorationProps(
		virtualNode: Types.VirtualNode,
		willDestroy: boolean
	)
		local lastProps = virtualNode._currentElement.props
		local eventMap = virtualNode._eventMap
		if eventMap then
			virtualNode._eventMap = nil
			
			if not willDestroy then
				local eventMaps = {eventMap}
				local attrsChangedEvents = eventMap[Symbols.AttributeChangedSignals]
				if attrsChangedEvents then
					eventMap[Symbols.AttributeChangedSignals] = nil
					table.insert(eventMaps, attrsChangedEvents)
				end
				local propsChangedEvents = eventMap[Symbols.PropertyChangedSignals]
				if propsChangedEvents then
					eventMap[Symbols.PropertyChangedSignals] = nil
					table.insert(eventMaps, propsChangedEvents)
				end
				for i = 1, #eventMaps do
					for key, conn in pairs(eventMaps[i]) do
						conn:Disconnect()
					end
				end
			end
		end
		
		local lastUpdateInstance = virtualNode._lastUpdateInstance
		if lastUpdateInstance then
			if not willDestroy then
				local lastTags = lastProps[Symbols.CollectionServiceTags]
				if lastTags then
					for i = 1, #lastTags do
						CollectionService:RemoveTag(lastUpdateInstance, lastTags[i])
					end
				end
				local lastAttrs = lastProps[Symbols.Attributes]
				if lastAttrs then
					for attrName, value in pairs(lastAttrs) do
						lastUpdateInstance:SetAttribute(attrName, nil)
					end
				end
			end
		end
	end

	local function unmountLifecycleProps(virtualNode: Types.VirtualNode)
		local toCallWithHostInstance = {}
	
		local lastElement = virtualNode._currentElement
		local onUnmountCB = lastElement.props[Symbols.OnUnmountWithHost]
		if onUnmountCB then
			table.insert(toCallWithHostInstance, onUnmountCB)
		end
		
		local specialPropCleanupCallbacks = virtualNode._specialPropCleanupCallbacks
		if specialPropCleanupCallbacks then
			virtualNode._specialPropCleanupCallbacks = nil
			for i = 1, #specialPropCleanupCallbacks do
				table.insert(toCallWithHostInstance, specialPropCleanupCallbacks[i])
			end
		end
		
		local lastUpdateInstance = virtualNode._lastUpdateInstance
		if lastUpdateInstance then
			for i = 1, #toCallWithHostInstance do
				task.spawn(toCallWithHostInstance[i], lastUpdateInstance)
			end
		end
	end
	
	local function getIndexedChildFromHost(hostContext: Types.HostContext): Instance?
		local siblingClusterCache = hostContext.siblingClusterCache
		if siblingClusterCache then
			local lastInstance = siblingClusterCache.lastProvidedInstance
			if lastInstance then
				return lastInstance
			end
		end

		local instance
		
		local parent = hostContext.instance
		if parent then
			local childKey = hostContext.childKey
			if childKey then
				instance = parent:FindFirstChild(childKey)
			else
				instance = parent
			end
		else
			error(MISSING_PARENT_ERROR)
		end
		
		return instance
	end
	local function createHost(
		instance: Instance?,
		key: string?,
		providers: {Types.InternalContextProvider},
		siblingClusterCache: Types.SiblingClusterCache?
	): Types.HostContext
		return {
			instance = instance,
			childKey = key,
			-- List (from root to last provider) of ancestor context providers in this tree
			providers = providers,
			siblingClusterCache = siblingClusterCache,
		}
	end
	local function createVirtualNode(
		element: Types.Element,
		host: Types.HostContext,
		contextProviders: {Types.InternalContextProvider}?
	): Types.VirtualNode
		return {
			--[Symbols.IsPractVirtualNode] = true,
			_wasUnmounted = false,
			_hostContext = host,
			_currentElement = element,
		}
	end
	
	local mountNodeOnChild, unmountOnChildNode; do
		function unmountOnChildNode(node: Types.VirtualNode)
			if node._resolved then
				local resolvedNode = node._resolvedNode
				if resolvedNode then
					unmountVirtualNode(resolvedNode)
				end
			end
		end
		
		function mountNodeOnChild(virtualNode: Types.VirtualNode)
			local hostContext = virtualNode._hostContext
			local hostInstance = hostContext.instance :: Instance
			local hostKey = hostContext.childKey :: string
			
			local onChildElement = {
				[Symbol_ElementKind] = ElementKinds.OnChild,
				wrappedElement = virtualNode._currentElement,
			}
			virtualNode._currentElement = onChildElement
			virtualNode._resolved = false
			
			task.spawn(function()
				local triesAttempted = 0
				repeat
					triesAttempted = triesAttempted + 1
					
					local threadResumeEvent = Instance.new("BindableEvent")
					local childAddedConn = hostInstance.ChildAdded:Connect(function(child: Instance)
						if child.Name == hostKey then
							threadResumeEvent:Fire(child)
						end
					end)
					local didResume = false
					task.delay(PractGlobalSystems.ON_CHILD_TIMEOUT_INTERVAL, function()
						if not didResume then
							threadResumeEvent:Fire(nil)
						end
					end)
					local child = threadResumeEvent.Event:Wait()
					didResume = true
					childAddedConn:Disconnect()
					threadResumeEvent:Destroy()
			
					if virtualNode._wasUnmounted then return end
					if child then
						virtualNode._resolved = true
						virtualNode._resolvedNode = mountVirtualNode(
							virtualNode._currentElement.wrappedElement,
							hostContext
						)
						return
					elseif triesAttempted == 1 then
						warn(
							'Attempt to mount decorate or index element on child "'
							.. hostKey
							.. '" of '
							.. hostInstance:GetFullName()
							.. " timed out. Perhaps the child key was named incorrectly?"
						)
					end
				until false
			end)
		end
	end

	local nodeCanUpdateWithElement: (
		virtualNode: Types.VirtualNode,
		newElement: Types.Element
	) -> boolean
	do
		local nodeCanUpdateWithElementByKind = {} :: {
			[Types.Symbol]: (virtualNode: Types.VirtualNode, newElement: Types.Element) -> boolean
		}
		nodeCanUpdateWithElementByKind[ElementKinds.Stamp] = function(virtualNode, newElement)
			return virtualNode._currentElement.template == newElement.template
		end
		nodeCanUpdateWithElementByKind[ElementKinds.Portal] = function(virtualNode, newElement)
			return virtualNode._currentElement.hostParent == newElement.hostParent
		end
		nodeCanUpdateWithElementByKind[ElementKinds.RenderComponent] = function(virtualNode, newElement)
			return virtualNode._currentElement.component == newElement.component
		end
		nodeCanUpdateWithElementByKind[ElementKinds.SignalComponent] = function(virtualNode, newElement)
			return virtualNode._currentElement.signal == newElement.signal
		end
			
		setmetatable(nodeCanUpdateWithElementByKind, {
			__index = function()
				return function() return true end
			end
		})

		function nodeCanUpdateWithElement(virtualNode, newElement)
			local currentElement = virtualNode._currentElement
			
			local kind = (newElement :: any)[Symbol_ElementKind]
			if currentElement[Symbol_ElementKind] == kind then
				return nodeCanUpdateWithElementByKind[kind](virtualNode, newElement :: any)
			else
				return false
			end
		end
	end
	
	do
		local updateByElementKind = {} :: {
			[Types.Symbol]: (
				virtualNode: Types.VirtualNode,
				newElement: Types.Element
			) -> Types.VirtualNode?
		}
		
		-- OnChild elements should never be created by the user; new node replacements for
		-- unresolved onChild nodes are handled elsewhere as an exceptional case instead.
		-- updateByElementKind[ElementKinds.OnChild] = function(virtualNode)
		-- 	virtualNode._currentElement.wrappedElement = virtualNode
		-- 	return virtualNode
		-- end
		
		updateByElementKind[ElementKinds.Decorate] = function(virtualNode, newElement)
			local instance = virtualNode._instance
			if not instance then
				instance = getIndexedChildFromHost(virtualNode._hostContext)
			end
			if instance then
				local success, err: string? = pcall(
					updateDecorationProps,
					virtualNode,
					newElement.props,
					virtualNode._currentElement.props,
					instance
				)
				
				if not success then
					local fullMessage = UPDATE_PROPS_ERROR:format(err)
					error(fullMessage, 0)
				end
				
				
				updateChildren(virtualNode, instance, newElement.props[Symbol_Children])
				updateLifecycleProps(newElement.props, instance)
			end
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.Index] = function(virtualNode, newElement)
			local instance = virtualNode._instance
			if not instance then
				instance = getIndexedChildFromHost(virtualNode._hostContext)
			end
			if instance then
				updateChildren(virtualNode, instance, newElement.children)
			end
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.Stamp] = function(virtualNode, newElement)
			local siblingClusterCache = virtualNode._hostContext.siblingClusterCache
			if siblingClusterCache then
				siblingClusterCache.lastProvidedInstance = virtualNode._instance
			end

			local success, err: string? = pcall(
				updateDecorationProps,
				virtualNode,
				newElement.props,
				virtualNode._currentElement.props,
				virtualNode._instance
			)
			
			if not success then
				local fullMessage = UPDATE_PROPS_ERROR:format(err)
				error(fullMessage, 0)
			end
			
			updateChildren(virtualNode, virtualNode._instance, newElement.props[Symbol_Children])
			updateLifecycleProps(newElement.props, virtualNode._instance)
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.CreateInstance] = function(virtualNode, newElement)
			local siblingClusterCache = virtualNode._hostContext.siblingClusterCache
			if siblingClusterCache then
				siblingClusterCache.lastProvidedInstance = virtualNode._instance
			end

			local success, err: string? = pcall(
				updateDecorationProps,
				virtualNode,
				newElement.props,
				virtualNode._currentElement.props,
				virtualNode._instance
			)
			
			if not success then
				local fullMessage = UPDATE_PROPS_ERROR:format(err)
				error(fullMessage, 0)
			end
			
			updateChildren(virtualNode, virtualNode._instance, newElement.props[Symbol_Children])
			updateLifecycleProps(newElement.props, virtualNode.instance)
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.Portal] = function(virtualNode, newElement)
			updateChildren(virtualNode, newElement.hostParent, newElement.children)
			
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.RenderComponent] = function(virtualNode, newElement)
			updateChildFunctionalComponent(
				virtualNode,
				newElement.component,
				newElement.props
			)
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.LifecycleComponent] = function(virtualNode, newElement)
			-- We don't care if our makeLifecycleClosure changes in this case, since the component
			-- returned from withLifecycle should be unique.
			
			local closure = virtualNode._lifecycleClosure :: Types.Lifecycle
			local saveElement = virtualNode._currentElement
			
			local shouldUpdate = closure.shouldUpdate
			if shouldUpdate then
				if not shouldUpdate(newElement.props, saveElement.props) then
					return virtualNode
				end
			end
			
			local willUpdate = closure.willUpdate
			if willUpdate then
				task.spawn(willUpdate, newElement.props, saveElement.props)
			end
			
			-- Apply render update
			updateChildFunctionalComponent(
				virtualNode,
				closure.render,
				newElement.props
			)
			
			local didUpdate = closure.didUpdate
			if didUpdate then
				if not virtualNode._collateDeferredUpdateCallback then
					virtualNode._collateDeferredUpdateCallback = true
					task.defer(function()
						virtualNode._collateDeferredUpdateCallback = nil
						if virtualNode._wasUnmounted then return end
						
						local cb = virtualNode._lifecycleClosure.didUpdate
						local lastProps = virtualNode._currentElement.props
						if cb and lastProps then
							cb(lastProps)
						end
					end)
				end
			end
			
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.StateComponent] = function(virtualNode, newElement)
			updateChildFunctionalComponent(
				virtualNode,
				virtualNode._renderClosure,
				newElement.props
			)
			
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.SignalComponent] = function(virtualNode, newElement)
			updateChildFunctionalComponent(
				virtualNode,
				newElement.render,
				newElement.props
			)
			
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.ContextProvider] = function(virtualNode, newElement)
			updateChildFunctionalComponent(
				virtualNode,
				virtualNode._renderClosure,
				newElement.props
			)
			
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.ContextConsumer] = function(virtualNode, newElement)
			updateChildFunctionalComponent(
				virtualNode,
				virtualNode._renderClosure,
				newElement.props
			)
			
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.SiblingCluster] = function(virtualNode, newElement)
			local parentHost = virtualNode._hostContext
			local siblingHost = virtualNode._siblingHost
			local siblingClusterCache = siblingHost.siblingClusterCache :: Types.SiblingClusterCache
			local siblings = virtualNode._siblings
			local elements = newElement.elements

			local nonNilElements = table.create(#elements)
			for i = 1, #elements do
				if typeof(elements[i]) == "table" then
					table.insert(nonNilElements, elements[i])
				end
			end

			-- Save/replace cache
			local saveConsumedInstances = siblingClusterCache.lastUpdateConsumedInstances
			local nextConsumedInstances = table.create(#nonNilElements)
			local lastProvidedInstance = nil
			local parentSiblingClusterCache = parentHost.siblingClusterCache
			if parentSiblingClusterCache then
				lastProvidedInstance = parentSiblingClusterCache.lastProvidedInstance
			end
			siblingClusterCache.lastProvidedInstance = lastProvidedInstance
			siblingClusterCache.lastUpdateConsumedInstances = nextConsumedInstances

			-- First pass: See which elements are incompatible by type
			local shouldReplacePastIndex = #siblings + 1
			local shouldUnmountIndicesInFirstPass = {}
			for i = 1, #siblings do
				local element = nonNilElements[i]
				if not (element and nodeCanUpdateWithElement(siblings[i], element :: any)) then
					shouldUnmountIndicesInFirstPass[i] = true
					shouldReplacePastIndex = shouldReplacePastIndex or i
				else
					shouldUnmountIndicesInFirstPass[i] = false
				end
			end

			-- We want to unmount existing components before we mount new ones!
			for i = 1, #siblings do
				if shouldUnmountIndicesInFirstPass[i] then
					unmountVirtualNode(siblings[i])
				end
			end

			local nextSiblings = table.create(#nonNilElements)

			-- Second pass: Mount nodes until we find a differing provided instance
			for i = 1, math.min(shouldReplacePastIndex, #siblings) do
				lastProvidedInstance = siblingClusterCache.lastProvidedInstance
				nextConsumedInstances[i] = lastProvidedInstance
				if shouldUnmountIndicesInFirstPass[i] then
					-- Create a new virtual node at this index now that we have unmounted all
					-- previous incompatible nodes.
					local node = mountVirtualNode(
						elements[i],
						siblingHost
					)
					if node then
						table.insert(nextSiblings, node)
					end
				else
					-- We should re-mount a component later in a sibling cluster iff it relies on a
					-- previous sibling's created instance!
					local consumedInstance = saveConsumedInstances[i]
					if consumedInstance ~= lastProvidedInstance then
						shouldReplacePastIndex = i
						break
					else
						local node = updateVirtualNode(
							siblings[i],
							nonNilElements[i]
						)
						if node then
							table.insert(nextSiblings, node)
						end
					end
				end
			end
			
			-- Third pass: Unmount nodes from [shouldReplacePastIndex, #siblings]
			for i = shouldReplacePastIndex, #siblings do
				if not shouldUnmountIndicesInFirstPass[i] then
					unmountVirtualNode(siblings[i])
				end
			end
			
			-- Mount nodes from [shouldReplacePastIndex, #siblings]
			for i = shouldReplacePastIndex, #siblings do
				lastProvidedInstance = siblingClusterCache.lastProvidedInstance
				nextConsumedInstances[i] = lastProvidedInstance
				local node = mountVirtualNode(
					nonNilElements[i],
					siblingHost
				)
				if node then
					table.insert(nextSiblings, node)
				end
			end

			-- Fourth pass: mount nodes from (#siblings, #nonNilElements]
			for i = #siblings + 1, #nonNilElements do
				local node = mountVirtualNode(
					nonNilElements[i],
					siblingHost
				)
				if node then
					table.insert(nextSiblings, node)
				end
			end
			
			virtualNode._siblings = nextSiblings

			-- Propogate the last provided instance to the parent
			if parentSiblingClusterCache then
				local instanceToProvide = siblingClusterCache.lastProvidedInstance
				if instanceToProvide then
					parentSiblingClusterCache.lastProvidedInstance = instanceToProvide
				end
			end
			return virtualNode
		end

		setmetatable(updateByElementKind, {__index = function(_, elementKind: any?)
			error(
				("Attempt to update VirtualNode with unhandled ElementKind %s")
					:format(tostring(elementKind))
			)
		end})
		
		function updateVirtualNode(
			virtualNode: Types.VirtualNode,
			newElement: Types.Element | boolean | nil
		): Types.VirtualNode?
			local currentElement = virtualNode._currentElement
			if currentElement == newElement then return virtualNode end
			
			if typeof(newElement) == 'boolean' or newElement == nil then
				unmountVirtualNode(virtualNode)
				return nil
			end
			
			local kind = (newElement :: any)[Symbol_ElementKind]
			if nodeCanUpdateWithElement(virtualNode, newElement :: any) then
				local nextNode = updateByElementKind[kind](virtualNode, newElement :: any)
				if nextNode then
					nextNode._currentElement = newElement :: any
				end
				return nextNode
			else
				-- Special case — replace our node with a resolved node
				if currentElement[Symbol_ElementKind] == ElementKinds.OnChild then
					if virtualNode._resolved then
						-- Place in child node if it was latently resolved and mounted
						local resolvedNode = virtualNode._resolvedNode :: Types.VirtualNode
						if resolvedNode then
							return updateVirtualNode(resolvedNode, newElement)
						end
						return resolvedNode
					else
						-- Compare the elementkind of our wrapped element, and simply swap it out
						-- if it has not changed.
						if virtualNode._currentElement.wrappedElement[Symbol_ElementKind]
						== kind then
							virtualNode._currentElement.wrappedElement = newElement
							return virtualNode
						end
					end
				end
				
				-- Else, unmount this node and replace it with a new node.
				return replaceVirtualNode(virtualNode, newElement :: any)
			end
		end
	end
	
	local function mountChildren(virtualNode: Types.VirtualNode)
		virtualNode._updateChildrenCount = 0
		virtualNode._children = {}
	end
	
	local function unmountChildren(virtualNode: Types.VirtualNode)
		for _, childNode in pairs(virtualNode._children) do
			unmountVirtualNode(childNode)
		end
	end
	
	function updateChildren(
		virtualNode: Types.VirtualNode,
		hostParent: Instance,
		newChildElements: Types.ChildrenArgument?
	)
		local newChildElements: Types.ChildrenArgument = newChildElements or {}
		virtualNode._updateChildrenCount = virtualNode._updateChildrenCount + 1
		
		local saveUpdateChildrenCount = virtualNode._updateChildrenCount
		local childrenMap = virtualNode._children
		
		-- Changed or removed children
		local keysToRemove = {}
		for childKey, childNode in pairs(childrenMap) do
			local newElement = newChildElements[childKey]
			local newNode = updateVirtualNode(childNode, newElement)
			
			-- If updating this node has caused a component higher up the tree to re-render
			-- and updateChildren to be re-entered for this virtualNode then
			-- this result is invalid and needs to be disgarded.
			if virtualNode._updateChildrenCount ~= saveUpdateChildrenCount then
				if newNode and newNode ~= childrenMap[childKey] then
					unmountVirtualNode(newNode)
				end
				return
			end
			if newNode ~= nil then
				childrenMap[childKey] = newNode
			else
				table.insert(keysToRemove, childKey)
			end
		end
		
		for i = 1, #keysToRemove do
			local childKey = keysToRemove[i]
			childrenMap[childKey] = nil
		end
		
		-- Added children
		for childKey, newElement in pairs(newChildElements) do
			if childrenMap[childKey] == nil then
				local childNode = mountVirtualNode(
					newElement,
					createHost(
						hostParent,
						tostring(childKey),
						virtualNode._hostContext.providers,
						nil
					)
				)
				
				-- If updating this node has caused a component higher up the tree to re-render
				-- and updateChildren to be re-entered for this virtualNode then
				-- this result is invalid and needs to be discarded.
				if virtualNode._updateChildrenCount ~= saveUpdateChildrenCount then
					if childNode then
						unmountVirtualNode(childNode)
					end
					return
				end
				
				-- mountVirtualNode can return nil if the element is a boolean
				if childNode ~= nil then
					virtualNode._children[childKey] = childNode
				end
			end
		end
	end
	
	do
		local mountByElementKind = {} :: {
			[Types.Symbol]: (virtualNode: Types.VirtualNode) -> ()
		}
		
		mountByElementKind[ElementKinds.Stamp] = function(virtualNode)
			local element = virtualNode._currentElement
			local props = element.props
			local hostContext = virtualNode._hostContext
			
			local instance; do
				--local success, err = pcall(function()
					instance = element.template:Clone()
				--	if not instance then
				--		error('Template instance was destroyed or not archivable')
				--	end
				--end)
				
				--if not success then
				--	local fullMessage = TEMPLATE_STAMP_ERROR:format(err)
				--	error(fullMessage, 0)
				--end
			end
			
			instance.Name = hostContext.childKey or DEFAULT_CREATED_CHILD_NAME
			
			local success, err: string? = pcall(
				mountDecorationProps,
				virtualNode, props, instance
			)
			
			if not success then
				local fullMessage = APPLY_PROPS_ERROR:format(err)
				error(fullMessage, 0)
			end
			
			mountChildren(virtualNode)
			updateChildren(virtualNode, instance, props[Symbol_Children])
			
			instance.Parent = hostContext.instance
			virtualNode._instance = instance

			local siblingClusterCache = hostContext.siblingClusterCache
			if siblingClusterCache then
				siblingClusterCache.lastProvidedInstance = instance
			end

			mountLifecycleProps(virtualNode, props, instance)
		end
		mountByElementKind[ElementKinds.CreateInstance] = function(virtualNode)
			local element = virtualNode._currentElement
			local props = element.props
			local instance = Instance.new(element.className)
			local hostContext = virtualNode._hostContext
			instance.Name = hostContext.childKey or DEFAULT_CREATED_CHILD_NAME
			
			local success, err: string? = pcall(
				mountDecorationProps,
				virtualNode, props, instance
			)
			
			if not success then
				local fullMessage = APPLY_PROPS_ERROR:format(err)
				error(fullMessage, 0)
			end
			
			mountChildren(virtualNode)
			updateChildren(virtualNode, instance, props[Symbol_Children])
			
			instance.Parent = hostContext.instance
			virtualNode._instance = instance

			local siblingClusterCache = hostContext.siblingClusterCache
			if siblingClusterCache then
				siblingClusterCache.lastProvidedInstance = instance
			end

			mountLifecycleProps(virtualNode, props, instance)
		end
		mountByElementKind[ElementKinds.Index] = function(virtualNode)
			local element = virtualNode._currentElement
			local instance = virtualNode._instance
			if not instance then
				instance = getIndexedChildFromHost(virtualNode._hostContext)
			end
			if instance then
				mountChildren(virtualNode)
				updateChildren(virtualNode, instance, element.children)
			else
				mountNodeOnChild(virtualNode)	-- hostContext.instance and hostContext.childKey
												-- must exist in this case!
			end
		end
		mountByElementKind[ElementKinds.Decorate] = function(virtualNode)
			local element = virtualNode._currentElement
			local props = element.props
			local instance = virtualNode._instance
			if not instance then
				instance = getIndexedChildFromHost(virtualNode._hostContext)
			end
			if instance then
				local success, err: string? = pcall(
					mountDecorationProps,
					virtualNode, props, instance
				)
				
				if not success then
					local fullMessage = APPLY_PROPS_ERROR:format(err)
					error(fullMessage, 0)
				end
				
				mountChildren(virtualNode)
				updateChildren(virtualNode, instance, props[Symbol_Children])

				mountLifecycleProps(virtualNode, props, instance)
			else
				mountNodeOnChild(virtualNode)	-- hostContext.instance and hostContext.childKey
												-- must exist in this case!
			end
		end

		mountByElementKind[ElementKinds.Portal] = function(virtualNode)
			local element = virtualNode._currentElement
			mountChildren(virtualNode)
			updateChildren(virtualNode, element.hostParent, element.children)
		end

		mountByElementKind[ElementKinds.RenderComponent] = function(virtualNode)
			local element = virtualNode._currentElement
			mountChildFunctionalComponent(
				virtualNode,
				element.component,
				element.props
			)
		end
		
		mountByElementKind[ElementKinds.LifecycleComponent] = function(virtualNode)
			local lastDeferredUpdateHeartbeatCount = -1
			local function forceUpdate()
				if not virtualNode._child then return end
				
				if not virtualNode._collateDeferredForcedUpdates then
					virtualNode._collateDeferredForcedUpdates = true
					task.defer(function()
						-- Allow a maximum of one update per frame (during Heartbeat)
						-- with forceUpdate calls in this closure.
						if lastDeferredUpdateHeartbeatCount
							== PractGlobalSystems.HeartbeatFrameCount then
							game:GetService('RunService').Heartbeat:Wait()
						end
						lastDeferredUpdateHeartbeatCount
							= PractGlobalSystems.HeartbeatFrameCount
						
						-- Resume
						virtualNode._collateDeferredForcedUpdates = nil
						if virtualNode._wasUnmounted then return end
						
						local saveElement = virtualNode._currentElement
						
						updateChildFunctionalComponent(
							virtualNode,
							virtualNode._lifecycleClosure.render,
							saveElement.props
						)
					end)
				end
			end
			
			local element = virtualNode._currentElement
			local closure = element.makeLifecycleClosure(forceUpdate) :: Types.Lifecycle
			
			local init = closure.init
			if init then
				init(element.props)
			end
			
			virtualNode._lifecycleClosure = closure
			mountChildFunctionalComponent(
				virtualNode,
				closure.render,
				element.props
			)
			
			local didMount = closure.didMount
			if didMount then
				task.spawn(didMount, element.props)
			end
		end
		
		mountByElementKind[ElementKinds.StateComponent] = function(virtualNode)
			local currentState = nil :: any
			local stateListenerSet = {} :: {[() -> ()]: boolean}
			local lastDeferredChangeHeartbeatCount = -1
			local function getState()
				return currentState
			end
			local function setState(nextState)
				-- If we aren't mounted, set currentState without any side effects
				if not virtualNode._child then
					currentState = nextState
					return
				end
				if virtualNode._wasUnmounted then
					currentState = nextState
					return
				end
				
				currentState = nextState

				local element = virtualNode._currentElement
				if element.deferred then
					if not virtualNode._collateDeferredState then
						virtualNode._collateDeferredState = true
						task.defer(function()
							-- Allow a maximum of one update per frame (during Heartbeat)
							-- with this state closure.
							if lastDeferredChangeHeartbeatCount
								== PractGlobalSystems.HeartbeatFrameCount then
								game:GetService('RunService').Heartbeat:Wait()
							end
							lastDeferredChangeHeartbeatCount
								= PractGlobalSystems.HeartbeatFrameCount
							
							-- Resume
							virtualNode._collateDeferredState = nil
							
							local listenersToCall = {}
							for cb in pairs(stateListenerSet) do
								table.insert(listenersToCall, cb)
							end
							
							-- Call external listeners before updating
							for i = 1, #listenersToCall do
								local cb = listenersToCall[i]
								task.spawn(function()
									-- Abort if side effects cause the component to unmount
									if virtualNode._wasUnmounted then return end
									cb()
								end)
							end
							-- Abort if side effects cause the component to unmount
							if virtualNode._wasUnmounted then return end
							
							updateChildFunctionalComponent(
								virtualNode,
								virtualNode._renderClosure,
								virtualNode._currentElement.props
							)
						end)
					end
				else
					local listenersToCall = {}
					for cb in pairs(stateListenerSet) do
						table.insert(listenersToCall, cb)
					end
					
					-- Call external listeners before updating
					for i = 1, #listenersToCall do
						local cb = listenersToCall[i]
						task.spawn(function()
							-- Abort if side effects cause the component to unmount
							if virtualNode._wasUnmounted then return end
							cb()
						end)
					end
					-- Abort if side effects cause the component to unmount
					if virtualNode._wasUnmounted then return end
					
					updateChildFunctionalComponent(
						virtualNode,
						virtualNode._renderClosure,
						element.props
					)
				end
			end
			local function subscribeState(callback: () -> ())
				if virtualNode._wasUnmounted then
					return NOOP
				end
				
				stateListenerSet[callback] = true
				
				return function()
					stateListenerSet[callback] = nil
				end
			end
			
			local element = virtualNode._currentElement
			local closure = element.makeStateClosure(getState, setState, subscribeState)
			
			virtualNode._renderClosure = closure
			mountChildFunctionalComponent(
				virtualNode,
				closure,
				element.props
			)
		end
		mountByElementKind[ElementKinds.SignalComponent] = function(virtualNode)
			local element = virtualNode._currentElement
			virtualNode._connection = element.signal:Connect(function()
				if virtualNode._wasUnmounted then return end
				
				local currentElement = virtualNode._currentElement
				updateChildFunctionalComponent(
					virtualNode,
					currentElement.render,
					currentElement.props
				)
			end)
			mountChildFunctionalComponent(
				virtualNode,
				element.render,
				element.props
			)
		end
		mountByElementKind[ElementKinds.ContextProvider] = function(virtualNode)
			local hostContext = virtualNode._hostContext
			
			local providedObjectsMap = {} :: {[string]: any}
			local provider: Types.InternalContextProvider = {
				find = function(key: string)
					return providedObjectsMap[key]
				end,
				provide = function(key, object)
					providedObjectsMap[key] = object
				end,
				unprovide = function(key)
					providedObjectsMap[key] = nil
				end,
			}
			local lastProviderChain = hostContext.providers
			local nextProviderChain = table.create(#lastProviderChain + 1)
			for i = 1, #lastProviderChain do
				table.insert(nextProviderChain, lastProviderChain[i])
			end
			table.insert(nextProviderChain, provider)
			
			local element = virtualNode._currentElement
			local closure = element.makeClosure(function(key: string, object: any)
				provider.provide(key, object)
				return function()
					provider.unprovide(key)
				end
			end)
			
			mountChildFunctionalComponent(
				virtualNode,
				closure,
				element.props,
				createHost(
					hostContext.instance,
					hostContext.childKey,
					nextProviderChain,
					hostContext.siblingClusterCache
				)
			)
			virtualNode._renderClosure = closure
		end
		mountByElementKind[ElementKinds.ContextConsumer] = function(virtualNode)
			local providerChain = virtualNode._hostContext.providers
			
			local element = virtualNode._currentElement
			local closure = element.makeClosure(function(key: string): any?
				for i = #providerChain, 1, -1 do
					local provider = providerChain[i]
					local object = provider.find(key)
					if object then
						return object
					end
				end
				return nil
			end)
			mountChildFunctionalComponent(
				virtualNode,
				closure,
				element.props
			)
			virtualNode._renderClosure = closure
		end
		
		mountByElementKind[ElementKinds.SiblingCluster] = function(virtualNode)
			local providedHost = virtualNode._hostContext
			local lastProvidedInstance: Instance? = nil
			local consumedInstances: {[number]: Instance?} = {}

			local parentSiblingClusterCache = providedHost.siblingClusterCache
			if parentSiblingClusterCache then
				lastProvidedInstance = parentSiblingClusterCache.lastProvidedInstance
			end

			local siblingClusterCache = {
				lastProvidedInstance = lastProvidedInstance,
				lastUpdateConsumedInstances = consumedInstances,
			}
			local siblingHost = createHost(
				providedHost.instance,
				providedHost.childKey,
				providedHost.providers,
				siblingClusterCache
			)
			virtualNode._siblingHost = siblingHost
			local elements = virtualNode._currentElement.elements
			local siblings = table.create(#elements)

			for i = 1, #elements do
				lastProvidedInstance = siblingClusterCache.lastProvidedInstance
				consumedInstances[i] = lastProvidedInstance
				local node = mountVirtualNode(
					elements[i],
					siblingHost
				)
				if node then
					table.insert(siblings, node)
				end
			end
			
			virtualNode._siblings = siblings

			if parentSiblingClusterCache and lastProvidedInstance then
				parentSiblingClusterCache.lastProvidedInstance = lastProvidedInstance
			end

			return virtualNode
		end

		setmetatable(mountByElementKind, {__index = function(_, elementKind: any?)
			error(
				("Attempt to mount invalid VirtualNode of ElementKind %s")
					:format(tostring(elementKind))
			)
		end})
		
		function mountVirtualNode(
			element: Types.Element | boolean | nil,
			hostContext: Types.HostContext
		): Types.VirtualNode?
			if typeof(element) == 'boolean' or element == nil then
				return nil
			end
			
			local virtualNode = createVirtualNode(
				element :: any,
				hostContext
			)
			
			mountByElementKind[
				(element :: Types.Element)[Symbol_ElementKind]
			](virtualNode)
			
			return virtualNode
		end
	end
	
	do
		local unmountByElementKind = {} :: {
			[Types.Symbol]: (virtualNode: Types.VirtualNode) -> ()
		}

		unmountByElementKind[ElementKinds.OnChild] = unmountOnChildNode
		unmountByElementKind[ElementKinds.Decorate] = function(virtualNode)
			unmountChildren(virtualNode)
			unmountDecorationProps(virtualNode, false)
			unmountLifecycleProps(virtualNode)
		end
		unmountByElementKind[ElementKinds.CreateInstance] = function(virtualNode)
			unmountChildren(virtualNode)
			local instance = virtualNode._instance
			instance:Destroy()
			unmountDecorationProps(virtualNode, true)
			unmountLifecycleProps(virtualNode)
		end
		unmountByElementKind[ElementKinds.Stamp] = function(virtualNode)
			unmountChildren(virtualNode)
			local instance = virtualNode._instance
			instance:Destroy()
			unmountDecorationProps(virtualNode, true)
			unmountLifecycleProps(virtualNode)
		end
		unmountByElementKind[ElementKinds.Portal] = function(virtualNode)
			unmountChildren(virtualNode)
		end
		unmountByElementKind[ElementKinds.RenderComponent] = unmountChildFunctionalComponent
		unmountByElementKind[ElementKinds.Index] = function(virtualNode)
			unmountChildren(virtualNode)
		end
		unmountByElementKind[ElementKinds.LifecycleComponent] = function(virtualNode)
			local saveElement = virtualNode._currentElement
			local closure = virtualNode._lifecycleClosure :: Types.Lifecycle
			
			local willUnmount = closure.willUnmount
			if willUnmount then
				task.spawn(willUnmount, saveElement.props)
			end
			
			unmountChildFunctionalComponent(virtualNode)
		end
		unmountByElementKind[ElementKinds.StateComponent] = unmountChildFunctionalComponent
		unmountByElementKind[ElementKinds.SignalComponent] = function(virtualNode)
			virtualNode._connection:Disconnect()
			unmountChildFunctionalComponent(virtualNode)
		end
		unmountByElementKind[ElementKinds.ContextProvider] = unmountChildFunctionalComponent
		unmountByElementKind[ElementKinds.ContextConsumer] = unmountChildFunctionalComponent
		unmountByElementKind[ElementKinds.SiblingCluster] = function(virtualNode)
			local siblings = virtualNode._siblings
			for i = 1, #siblings do
				unmountVirtualNode(siblings[i])
			end
		end

		setmetatable(unmountByElementKind, {__index = function(_, elementKind: any?)
			error(
				("Attempt to unmount VirtualNode with unhandled ElementKind %s")
					:format(tostring(elementKind))
			)
		end})
		
		function unmountVirtualNode(virtualNode: Types.VirtualNode)
			virtualNode._wasUnmounted = true
			unmountByElementKind[
				(virtualNode._currentElement :: Types.Element)[Symbol_ElementKind]
			](virtualNode)
		end
	end
	
	function updateVirtualTree(tree: Types.PractTree, newElement: Types.Element)
		local rootNode = tree._rootNode
		if rootNode then
			tree._rootNode = updateVirtualNode(rootNode, newElement)
		end
	end
	
	function mountVirtualTree(
		element: Types.Element,
		hostInstance: Instance?,
		hostChildKey: string?
	): Types.PractTree
		if (typeof(element) ~= 'table') or (element[Symbol_ElementKind] == nil) then
			error(
				("invalid argument #1 to Pract.mount (Pract.Element expected, got %s)")
					:format(typeof(element))
			)
		end
		
		local tree = {
			[Symbols.IsPractTree] = true,
			_rootNode = (nil :: any) :: Types.VirtualNode?,
			_mounted = true,
		}
		
		tree._rootNode = mountVirtualNode(
			element,
			createHost(
				hostInstance,
				hostChildKey,
				{},
				nil
			)
		)
		
		return tree
	end
	
	function unmountVirtualTree(tree: Types.PractTree)
		if (typeof(tree) ~= 'table') or (tree[Symbols.IsPractTree] ~= true) then
			error(
				("invalid argument #1 to Pract.unmount (Pract.Tree expected, got %s)")
					:format(typeof(tree))
			)
		end
		
		tree._mounted = false
		
		local rootNode = tree._rootNode
		if rootNode then
			unmountVirtualNode(rootNode)
		end
	end
	
	reconciler = {
		mountVirtualTree = mountVirtualTree,
		updateVirtualTree = updateVirtualTree,
		unmountVirtualTree = unmountVirtualTree,

		createHost = createHost,
	}
	
	return reconciler
end

return createReconciler
