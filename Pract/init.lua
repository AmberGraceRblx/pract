--!strict
-- Created by DataBrain, licensed as public domain.

-- See this website for an in-depth Pract Documentation:
-- https://ambers-careware.github.io/pract/

local Pract = {}
Pract._VERSION = '0.9.13'

local Types = require(script.Types)
local PractGlobalSystems = require(script.PractGlobalSystems)
PractGlobalSystems.Run()

-- Public types
export type Tree = Types.PractTree
export type Component = Types.Component
export type ComponentTyped<PropsType> = Types.ComponentTyped<PropsType>
export type Element = Types.Element
export type PropsArgument = Types.PropsArgument
export type ChildrenArgument = Types.ChildrenArgument
export type ClassComponentMethods = Types.ClassComponentMethods
-- export type ClassComponentMethodsTyped<P, S> = Types.ClassComponentMethodsTyped<P, S>
export type ClassComponentSelf = Types.ClassComponentSelf
-- export type ClassComponentSelfTyped<P, S> = Types.ClassComponentSelfTyped<P, S>
export type ClassState = Types.ClassState
export type Lifecycle = Types.Lifecycle
export type Context = Types.PublicContextObject
export type HookLifecycle<T = (...any) -> ...any> = Types.CustomHookLifecycle<T>
-- export type LifecycleTyped<P> = Types.LifecycleTyped<P>

-- Public library values

-- Base element functions
Pract.create = require(script.create)
Pract.createTyped = (Pract.create :: any) :: <PropsType>(
	component: ComponentTyped<PropsType>,
	props: PropsType
) -> (Types.Element)
Pract.index = require(script.index)
Pract.stamp = require(script.stamp)
Pract.decorate = require(script.decorate)
Pract.portal = require(script.portal)
Pract.combine = require(script.combine)

-- Functional component hooks
Pract.useState = require(script.useState)
Pract.useStateTyped = (Pract.useState :: any) :: <S>(initialState: S) -> (S, (S) -> ())
Pract.useStateThunkTyped = (Pract.useState :: any) :: <S>(initialState: () -> S) -> (S, (S) -> ())
Pract.useMemo = require(script.useMemo)
Pract.useEffect = require(script.useEffect)
Pract.createContext = require(script.createContext)
Pract.useConsumer = require(script.useConsumer)
Pract.useSignalUpdates = require(script.useSignalUpdates)
Pract.createHook = require(script.createHook)

-- Virtual tree functions
local createReconciler = require(script.createReconciler)
local robloxReconciler = createReconciler()
Pract.mount = robloxReconciler.mountVirtualTree
Pract.update = robloxReconciler.updateVirtualTree
Pract.unmount = robloxReconciler.unmountVirtualTree

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
-- Deprecated for name clarity; use OnRenderWithHost instead.
Pract.OnUpdateWithHost = Symbols.OnRenderWithHost
Pract.OnRenderWithHost = Symbols.OnRenderWithHost

-- Decoration prop value symbols
Pract.None = Symbols.None

-- Higher-order component wrapper functions (mostly deprecated in favor of hooks)

-- Deprecated
Pract.withLifecycle = require(script.withLifecycle)
-- Pract.withLifecycleTyped = (Pract.withLifecycle :: any) :: <P>(
-- 	closureCreator: (forceUpdate: () -> ()) -> LifecycleTyped<P>
-- ) -> ComponentTyped<P>
-- Deprecated
Pract.withState = require(script.withState)
-- Deprecated
Pract.withDeferredState = require(script.withDeferredState)
-- Deprecated
Pract.withSignal = require(script.withSignal)
-- Deprecated
Pract.withContextProvider = require(script.withContextProvider)
-- Deprecated
Pract.withContextConsumer = require(script.withContextConsumer)
-- Discouraged
Pract.classComponent = require(script.classComponent)
-- Pract.classComponentTyped = (Pract.classComponent :: any) :: <P, S>(
-- 	methods: ClassComponentMethodsTyped<P, S>
-- ) -> ComponentTyped<P>

-- Use this library to make the world a better place :)

return Pract
