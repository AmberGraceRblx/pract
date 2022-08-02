--!strict



-- Util types
export type ChildrenArgument = {[any]: any}--{[any]: Element | boolean | nil}
export type PropsArgument = any -- {[any]: any}
export type Symbol = {}
--export type StateUpdate<P, S> = {[any]: any} | (state: P, props: P) -> {[any]: any}
--export type SetStateCB<P, S> = (stateUpdate: StateUpdate<P, S>) -> ()



-- Public types
export type Element = {
	[any]: any,
}
export type Component = (props: any) -> Element
export type ComponentTyped<PropsType> = (props: PropsType) -> Element
--export type ComponentTyped<P> = (props: P) -> any
export type ClassState = any
export type PartialClassState = {[string]: any}
export type ClassStateUpdateThunk = (state: ClassState, props: PropsArgument) -> PartialClassState
export type ClassStateUpdateThunkTyped<P, S> = (state: P, props: P) -> S
export type ClassStateUpdate = PartialClassState | ClassStateUpdateThunk
export type ClassStateUpdateTyped<P, S> = S | ClassStateUpdateThunkTyped<P, S>
export type ClassComponentSelf = {
	[any]: any,
	props: PropsArgument,
	state: ClassState,
	setState: (
		self: ClassComponentSelf,
		partialStateUpdate: ClassStateUpdate
	) -> (),
	subscribeState: (self: ClassComponentSelf, listener: () -> ()) -> (() -> ()),
	forceUpdate: (self: ClassComponentSelf) -> (),
}
export type ClassComponentSelfTyped<P, S> = {
	[any]: (self: ClassComponentSelfTyped<P, S>, ...any) -> ...any,
	props: P,
	state: S,
	setState: (
		self: ClassComponentSelfTyped<P, S>,
		partialStateUpdate: ClassStateUpdateTyped<P, S>
	) -> (),
	subscribeState: (self: ClassComponentSelfTyped<P, S>, listener: () -> ()) -> (() -> ()),
	forceUpdate: (self: ClassComponentSelfTyped<P, S>) -> (),
}
export type ClassComponentMethods = {
	[any]: any,
	render: (self: ClassComponentSelf) -> Element,
	init: ((self: ClassComponentSelf) -> ())?,
	didMount: ((self: ClassComponentSelf) ->())?,
	shouldUpdate: ((
		self: ClassComponentSelf,
		newProps: PropsArgument,
		newState: ClassState
	) -> boolean)?,
	willUpdate: ((self: ClassComponentSelf, newProps: PropsArgument, newState: ClassState) -> ())?,
	didUpdate: ((self: ClassComponentSelf) -> ())?,
	willUnmount: ((self: ClassComponentSelf) -> ())?,
}
export type ClassComponentMethodsTyped<P, S> = {
	[any]: any,
	render: (self: ClassComponentSelfTyped<P, S>) -> Element,
	init: ((self: ClassComponentSelfTyped<P, S>) -> ())?,
	didMount: ((self: ClassComponentSelfTyped<P, S>) ->())?,
	shouldUpdate: ((
		self: ClassComponentSelfTyped<P, S>,
		newProps: P,
		newState: S
	) -> boolean)?,
	willUpdate: ((self: ClassComponentSelfTyped<P, S>, newProps: P, newState: S) -> ())?,
	didUpdate: ((self: ClassComponentSelfTyped<P, S>) -> ())?,
	willUnmount: ((self: ClassComponentSelfTyped<P, S>) -> ())?,
}
export type Lifecycle = {
	render: Component,
	init: ((props: any) -> ())?,
	didMount: ((props: any) ->())?,
	shouldUpdate: ((newProps: any, oldProps: any) -> boolean)?,
	willUpdate: ((props: any, oldProps: any) -> ())?,
	didUpdate: ((props: any) -> ())?,
	willUnmount: ((props: any) -> ())?,
}
export type LifecycleTyped<P> = {
	render: Component,
	init: ((props: P) -> ())?,
	didMount: ((props: P) ->())?,
	shouldUpdate: ((newProps: P, oldProps: P) -> boolean)?,
	willUpdate: ((props: P, oldProps: P) -> ())?,
	didUpdate: ((props: P) -> ())?,
	willUnmount: ((props: P) -> ())?,
}
export type CustomHookLifecycle<T> = {
	call:  T,
	cleanup: (() -> ())?,
}



-- Internal reconciler types
export type InternalContextProvider = {
	find: (name: string) -> any?,
	provide: (name: string, object: any?) -> (),
	unprovide: (name: string) -> (),
}
export type PublicContextObject = {
	Provider: ComponentTyped<{
		value: any,
		child: Element,
	}>
}
export type SiblingClusterCache = {
	lastProvidedInstance: Instance?,
	lastUpdateConsumedInstances: {[number]: Instance?},
}
export type HostContext = {	-- Immutable type used as an object reference passed down in trees; the
							-- purpose of grouping these together is because typically components
							-- share the same host and context information except in special cases.
							-- This reduces memory usage and simplifies node visiting processes.
	instance: Instance?,
	childKey: string?,
	providers: {InternalContextProvider},
	siblingClusterCache: SiblingClusterCache?,
}
export type EffectCallback = () -> (() -> ())?
export type ComponentHookContext = {
	createdHeartbeatCount: number,
	cacheQueueUpdateClosure: (() -> ())?,
	orderedStates: {
		useState: {{ value: any, setState: (value: any) -> () }}?,
		useMemo: {{ value: any, deps: {any}}}?,
		useEffect: {{
			cleanup: (() -> ())?,
			deps: {any}?,
			cancelled: boolean,
		}}?,
		customHook: {{ closure: any, createClosure: any }}?,
	},
}
export type VirtualNode = {
	[any]: any,
	_wasUnmounted: boolean,
	_currentElement: Element,
	_hostContext: HostContext,
	_hookContext: ComponentHookContext?
}
export type PractTree = {
	[Symbol]: any,
	_rootNode: VirtualNode?,
	_mounted: boolean,
}
export type Reconciler = {
	mountVirtualTree: (
		element: Element,
		hostInstance: Instance?,
		hostKey: string?
	) -> PractTree,
	updateVirtualTree: (tree: PractTree, newElement: Element) -> (),
	unmountVirtualTree: (tree: PractTree) -> (),

	createHost: (
		instance: Instance?,
		key: string?,
		providers: {InternalContextProvider},
		siblingClusterCache: SiblingClusterCache?
	) -> HostContext
}
export type HookReconciler = <HookArgs..., HookReturns...>(
	lifecycleClosureCB: (
		queueUpdate: () -> ()
	) -> CustomHookLifecycle<(HookArgs...) -> HookReturns...>,
	HookArgs...
) -> HookReturns...

return nil
