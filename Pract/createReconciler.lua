local CollectionService = game:GetService("CollectionService")
--!strict

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
		specialApplyPropHandlers[Symbols.OnMountWithHost] = function(
			virtualNode,
			newValue,
			oldValue,
			eventMap,
			instance
		)
			if not virtualNode._calledOnMountWithHost then
				virtualNode._calledOnMountWithHost = true
				if not newValue then return end
				
				task.defer(function()
					if virtualNode._wasUnmounted then return end
					
					local currentElement = virtualNode._currentElement
					local props = currentElement.props
					local cb = props[Symbols.OnMountWithHost]
					local instance = virtualNode._lastUpdateInstance
					if cb and instance then
						cb(instance, props, function(cleanupCallback: () -> ())
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
						end)
					end
				end)
			end
		end
		specialApplyPropHandlers[Symbols.OnUpdateWithHost] = function(
			virtualNode,
			newValue,
			oldValue,
			eventMap,
			instance
		)
			if not newValue then return end
			if not virtualNode._collateDeferredUpdateCallback then
				virtualNode._collateDeferredUpdateCallback = true
				task.defer(function()
					virtualNode._collateDeferredUpdateCallback = nil
					if virtualNode._wasUnmounted then return end
					
					local props = virtualNode._currentElement.props
					local cb = props[Symbols.OnUpdateWithHost]
					local instance = virtualNode._lastUpdateInstance
					if cb and instance then
						cb(instance, props)
					end
				end)
			end
		end
		
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
			local CollectionService = game:GetService('CollectionService')
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
		
		local toCallWithHostInstance = {}
		local specialPropCleanupCallbacks = virtualNode._specialPropCleanupCallbacks
		if specialPropCleanupCallbacks then
			virtualNode._specialPropCleanupCallbacks = nil
			for i = 1, #specialPropCleanupCallbacks do
				table.insert(toCallWithHostInstance, specialPropCleanupCallbacks[i])
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
	
			local lastElement = virtualNode._currentElement
			local onUnmountCB = lastElement.props[Symbols.OnUnmountWithHost]
			if onUnmountCB then
				table.insert(toCallWithHostInstance, onUnmountCB)
			end
			
			for i = 1, #toCallWithHostInstance do
				task.defer(toCallWithHostInstance[i], lastUpdateInstance)
			end
		end
	end
	
	local function getIndexedChildFromHost(hostContext: Types.HostContext): Instance?
		local siblingClusterCache = hostContext.siblingClusterCache
		if siblingClusterCache then
			local lastInstance = siblingClusterCache.lastProvidedInstance
			if lastInstance then
				siblingClusterCache.idxToConsumedInstanceHost[
					siblingClusterCache.currentSiblingIdx
				] = lastInstance
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
		providers: {Types.ContextProvider},
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
		contextProviders: {Types.ContextProvider}?
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
			
			local siblingClusterCache = hostContext.siblingClusterCache
			task.defer(function()
				local triesAttempted = 0
				repeat
					triesAttempted = triesAttempted + 1
					
					local child: any
					if siblingClusterCache then
						local lastInstance = siblingClusterCache.lastProvidedInstance
						if lastInstance then
							siblingClusterCache.idxToConsumedInstanceHost[
								siblingClusterCache.currentSiblingIdx
							] = lastInstance
							child = lastInstance
							break
						end
					end

					if not child then
						child = hostInstance:WaitForChild(
							hostKey,
							PractGlobalSystems.ON_CHILD_TIMEOUT_INTERVAL
						)
					end
			
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
			if virtualNode._currentElement.template ~= newElement.template then
				return replaceVirtualNode(virtualNode, newElement)
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
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.CreateInstance] = function(virtualNode, newElement)
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
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.Portal] = function(virtualNode, newElement)
			local element = virtualNode._currentElement
			if element.hostParent ~= newElement.hostParent then
				return replaceVirtualNode(virtualNode, newElement)
			end
			updateChildren(virtualNode, newElement.hostParent, newElement.children)
			
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.RenderComponent] = function(virtualNode, newElement)
			local saveElement = virtualNode._currentElement
			if saveElement.component ~= newElement.component then
				return replaceVirtualNode(virtualNode, newElement)
			end
			
			virtualNode._child = updateVirtualNode(
				virtualNode._child,
				newElement.component(newElement.props)
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
			virtualNode._child = updateVirtualNode(
				virtualNode._child,
				closure.render(newElement.props)
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
			virtualNode._child = updateVirtualNode(
				virtualNode._child,
				virtualNode._renderClosure(newElement.props)
			)
			
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.SignalComponent] = function(virtualNode, newElement)
			if virtualNode._currentElement.signal ~= newElement.signal then
				return replaceVirtualNode(virtualNode, newElement)
			end
			
			virtualNode._child = updateVirtualNode(
				virtualNode._child,
				newElement.render(newElement.props)
			)
			
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.ContextProvider] = function(virtualNode, newElement)
			virtualNode._child = updateVirtualNode(
				virtualNode._child,
				virtualNode._renderClosure(newElement.props)
			)
			
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.ContextConsumer] = function(virtualNode, newElement)
			virtualNode._child = updateVirtualNode(
				virtualNode._child,
				virtualNode._renderClosure(newElement.props)
			)
			
			return virtualNode
		end
		
		updateByElementKind[ElementKinds.SiblingCluster] = function(virtualNode, newElement)
			local siblingHost = virtualNode._hostContext
			local siblingClusterCache = siblingHost.siblingClusterCache :: Types.SiblingClusterCache
			local siblings = virtualNode._siblings
			local elements = newElement.elements
			local nextSiblings = table.create(#elements)

			local idxToConsumedInstanceHost = siblingClusterCache.idxToConsumedInstanceHost
			local providedInstanceHostSet = siblingClusterCache.providedInstanceHostSet
			for i = 1, #siblings do
				siblingClusterCache.currentSiblingIdx = i
				-- We should re-mount a component later in a sibling cluster iff it relies on a
				-- previous sibling's created instance!
				local consumedInstance = idxToConsumedInstanceHost[i]
				if consumedInstance and not providedInstanceHostSet[consumedInstance] then
					table.insert(nextSiblings, replaceVirtualNode(
						siblings[i],
						elements[i]
					))
				else
					table.insert(nextSiblings, updateVirtualNode(
						siblings[i],
						elements[i])
					)
				end
			end
			
			for i = #siblings + 1, #elements do
				siblingClusterCache.currentSiblingIdx = i
				table.insert(nextSiblings, mountVirtualNode(
					elements[i],
					siblingHost
				))
			end
			
			virtualNode._siblings = nextSiblings
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
			if currentElement[Symbol_ElementKind] == kind then
				local nextNode = updateByElementKind[kind](virtualNode, newElement :: any)
				if nextNode then
					nextNode._currentElement = newElement :: any
				end
				return nextNode
			else
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
				siblingClusterCache.providedInstanceHostSet[instance] = true
				siblingClusterCache.idxToProvidedInstanceHost[
					siblingClusterCache.currentSiblingIdx
				] = instance
				siblingClusterCache.lastProvidedInstance = instance
			end
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
				siblingClusterCache.providedInstanceHostSet[instance] = true
				siblingClusterCache.idxToProvidedInstanceHost[
					siblingClusterCache.currentSiblingIdx
				] = instance
				siblingClusterCache.lastProvidedInstance = instance
			end
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
			local props = element.props
			local child = mountVirtualNode(
				element.component(props),
				virtualNode._hostContext
			)
			virtualNode._child = child
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
						
						virtualNode._child = updateVirtualNode(
							virtualNode._child,
							virtualNode._lifecycleClosure.render(saveElement.props)
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
			virtualNode._child = mountVirtualNode(
				closure.render(element.props),
				virtualNode._hostContext
			)
			
			local didMount = closure.didMount
			if didMount then
				task.defer(didMount, element.props)
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
							
							virtualNode._child = updateVirtualNode(
								virtualNode._child,
								virtualNode._renderClosure(virtualNode._currentElement.props)
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
					
					virtualNode._child = updateVirtualNode(
						virtualNode._child,
						virtualNode._renderClosure(element.props)
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
			
			virtualNode._child = mountVirtualNode(
				closure(element.props),
				virtualNode._hostContext
			)
			virtualNode._renderClosure = closure
		end
		mountByElementKind[ElementKinds.SignalComponent] = function(virtualNode)
			local element = virtualNode._currentElement
			virtualNode._child = mountVirtualNode(
				element.render(element.props),
				virtualNode._hostContext
			)
			virtualNode._connection = element.signal:Connect(function()
				if virtualNode._wasUnmounted then return end
				
				local currentElement = virtualNode._currentElement
				local props = currentElement.props
				virtualNode._child = updateVirtualNode(
					virtualNode._child,
					currentElement.render(props)
				)
			end)
		end
		mountByElementKind[ElementKinds.ContextProvider] = function(virtualNode)
			local hostContext = virtualNode._hostContext
			
			local providedObjectsMap = {} :: {[string]: any}
			local provider: Types.ContextProvider = {
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
			
			virtualNode._child = mountVirtualNode(
				closure(element.props),
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
			local hostContext = virtualNode._hostContext
			local providerChain = hostContext.providers
			
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
			virtualNode._child = mountVirtualNode(
				closure(element.props),
				hostContext
			)
			virtualNode._renderClosure = closure
		end
		
		mountByElementKind[ElementKinds.SiblingCluster] = function(virtualNode)
			local providedHost = virtualNode._hostContext
			local siblingClusterCache = {
				currentSiblingIdx = 1,
				providedInstanceHostSet = {},
				idxToProvidedInstanceHost = {},
				idxToConsumedInstanceHost = {},
				lastProvidedInstance = nil,
			}
			local siblingHost = createHost(
				providedHost.instance,
				providedHost.childKey,
				providedHost.providers,
				siblingClusterCache
			)
			virtualNode._hostContext = siblingHost
			local elements = virtualNode._currentElement.elements
			local siblings = table.create(#elements)

			for i = 1, #elements do
				siblingClusterCache.currentSiblingIdx = i
				table.insert(siblings, mountVirtualNode(
					elements[i],
					siblingHost
				))
			end
			
			virtualNode._siblings = siblings
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
		--[[
			This utility should thoroughly clear cached values within a sibling cluster, if one
			exists in the host context.

			The issue with behavior consistency in sibling clusters is in situations like the
			following example:

				1. Mount a pract tree with a Pract.combine element, containing a Pract.stamp and
				Pract.decorate component.

					When mounted, the stamp element will stamp a template instance, and via the
					sibling cluster cache, the decorate element will decorate the previously stamped
					instance in this cluster.
				
				2. Update the pract tree with a similar Pract.combine element—the only difference
				being that the stamp element has changed its template!

					When updated, the first stamp element in this sibling cluster must be replaced--
					that is, it should be unmounted then mounted again with the new template.

					The issue here is that the next Pract.decorate element in this cluster DEPENDS
					on the host created via the previous stamp element! This means it must be
					replaced (unmounted then mounted again) as well! This is handled in the sibling
					cluster update code.
			
			The current solution to this issue uses a cache within the host context itself; this
			implementation is a little obscure and prone to memory leaks if it isn't designed with
			airtight code. In addition, adding element types to Pract would require taking sibling
			cluster behavior in the future. Unit tests can alleviate some of these issues, but
			the combinatorial possibilities/proliferation of element types could make this hard to
			thoroughly unit test with newly implemented element types. In addition, the sibling
			cluster needs to propogate into certain nested hosts or elements using the same host.
		]]
		local function unmountSiblingClusterHost(
			hostContext: Types.HostContext,
			instance: Instance
		)
			local siblingClusterCache = hostContext.siblingClusterCache
			if siblingClusterCache then
				local currentSiblingIdx = siblingClusterCache.currentSiblingIdx
				local idxToProvidedInstanceHost = siblingClusterCache.idxToProvidedInstanceHost
				local idxToConsumedInstanceHost = siblingClusterCache.idxToConsumedInstanceHost
				local providedInstanceHostSet = siblingClusterCache.providedInstanceHostSet
				providedInstanceHostSet[instance] = nil
				idxToProvidedInstanceHost[currentSiblingIdx] = nil
				idxToConsumedInstanceHost[currentSiblingIdx] = nil
				if siblingClusterCache.lastProvidedInstance == instance then
					local maxIdx, maxInst = next(idxToProvidedInstanceHost)
					for idx, inst in pairs(idxToProvidedInstanceHost) do
						if idx > maxIdx then
							maxIdx = idx
							maxInst = inst
						end
					end

					siblingClusterCache.lastProvidedInstance = maxInst
				end
			end
		end

		local unmountByElementKind = {} :: {
			[Types.Symbol]: (virtualNode: Types.VirtualNode) -> ()
		}

		unmountByElementKind[ElementKinds.OnChild] = unmountOnChildNode
		unmountByElementKind[ElementKinds.Decorate] = function(virtualNode)
			unmountDecorationProps(virtualNode, false)
			unmountChildren(virtualNode)
		end
		unmountByElementKind[ElementKinds.CreateInstance] = function(virtualNode)
			unmountDecorationProps(virtualNode, true)
			unmountChildren(virtualNode)
			local instance = virtualNode._instance
			unmountSiblingClusterHost(virtualNode._hostContext, instance)
			instance:Destroy()
		end
		unmountByElementKind[ElementKinds.Stamp] = function(virtualNode)
			unmountDecorationProps(virtualNode, true)
			unmountChildren(virtualNode)
			local instance = virtualNode._instance
			unmountSiblingClusterHost(virtualNode._hostContext, instance)
			instance:Destroy()
		end
		unmountByElementKind[ElementKinds.Portal] = function(virtualNode)
			unmountChildren(virtualNode)
		end
		unmountByElementKind[ElementKinds.RenderComponent] = function(virtualNode)
			unmountVirtualNode(virtualNode._child)
		end
		unmountByElementKind[ElementKinds.Index] = function(virtualNode)
			unmountChildren(virtualNode)
		end
		unmountByElementKind[ElementKinds.LifecycleComponent] = function(virtualNode)
			local saveElement = virtualNode._currentElement
			local closure = virtualNode._lifecycleClosure :: Types.Lifecycle
			
			local willUnmount = closure.willUnmount
			if willUnmount then
				willUnmount(saveElement.props)
			end
			
			unmountVirtualNode(virtualNode._child)
		end
		unmountByElementKind[ElementKinds.StateComponent] = function(virtualNode)
			unmountVirtualNode(virtualNode._child)
		end
		unmountByElementKind[ElementKinds.SignalComponent] = function(virtualNode)
			virtualNode._connection:Disconnect()
			unmountVirtualNode(virtualNode._child)
		end
		unmountByElementKind[ElementKinds.ContextProvider] = function(virtualNode)
			unmountVirtualNode(virtualNode._child)
		end
		unmountByElementKind[ElementKinds.ContextConsumer] = function(virtualNode)
			unmountVirtualNode(virtualNode._child)
		end
		unmountByElementKind[ElementKinds.SiblingCluster] = function(virtualNode)
			local siblingHost = virtualNode._hostContext
			local siblingClusterCache = siblingHost.siblingClusterCache :: Types.SiblingClusterCache
			local siblings = virtualNode._siblings
			for i = 1, #siblings do
				siblingClusterCache.currentSiblingIdx = i
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