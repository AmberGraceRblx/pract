--!strict
-- Created by DataBrain, licensed as public domain.

local Pract = {}
Pract._VERSION = '0.9.5'    -- Beta version; test coverage is still needed.
                            -- Be wary of bugs and an incomplete feature set if using in production.

local Types = require(script.Types)
local PractGlobalSystems = require(script.PractGlobalSystems)
PractGlobalSystems.Run()

-- Public types
export type Tree = Types.PractTree
export type Component = Types.Component
export type Element = Types.Element
export type PropsArgument = Types.PropsArgument
export type ChildrenArgument = Types.ChildrenArgument
export type ClassComponentMethods = Types.ClassComponentMethods
export type ClassState = Types.ClassState
export type Lifecycle = Types.Lifecycle

-- Public library values

-- Base element functions
Pract.create = require(script.create)
Pract.index = require(script.index)
Pract.stamp = require(script.stamp)
Pract.decorate = require(script.decorate)
Pract.portal = require(script.portal)
Pract.combine = require(script.combine)

-- Virtual tree functions
local createReconciler = require(script.createReconciler)
local robloxReconciler = createReconciler()
Pract.mount = robloxReconciler.mountVirtualTree
Pract.update = robloxReconciler.updateVirtualTree
Pract.unmount = robloxReconciler.unmountVirtualTree

-- Higher-order component wrapper functions

Pract.withLifecycle = require(script.withLifecycle)
Pract.withState = require(script.withState)
Pract.withDeferredState = require(script.withDeferredState)
Pract.withSignal = require(script.withSignal)
Pract.withContextProvider = require(script.withContextProvider)
Pract.withContextConsumer = require(script.withContextConsumer)
Pract.classComponent = require(script.classComponent)

-- Symbols:

local Symbols = require(script.Symbols)

-- Decoration prop key symbols
Pract.Children = Symbols.Children
Pract.Attributes = Symbols.Attributes
Pract.CollectionServiceTags = Symbols.CollectionServiceTags
Pract.PropertyChangedSignals = Symbols.PropertyChangedSignals
Pract.AttributeChangedSignals = Symbols.AttributeChangedSignals
Pract.OnMountWithHost = Symbols.OnMountWithHost
Pract.OnUnmountWithHost = Symbols.OnUnmountWithHost
Pract.OnUpdateWithHost = Symbols.OnUpdateWithHost

-- Decoration prop value symbols
Pract.None = Symbols.None

return Pract