--!strict



-- Util types
export type ChildrenArgument = {[any]: Element | boolean | nil}
export type PropsArgument = {[any]: any}
export type Symbol = {}
--export type StateUpdate<S, P> = {[any]: any} | (state: S, props: P) -> {[any]: any}
--export type SetStateCB<S, P> = (stateUpdate: StateUpdate<S, P>) -> ()



-- Public types
export type Element = {
	[any]: any,
}
export type Component = (props: any) -> any
--export type ComponentTyped<P> = (props: P) -> any
export type ClassState = {[string]: any}
export type ClassStateUpdateThunk = (state: ClassState, props: PropsArgument) -> ClassState
export type ClassStateUpdate = ClassState | ClassStateUpdateThunk
export type ClassComponentSelf = {
	[any]: any,
	props: PropsArgument,
	state: ClassState,
	setState: (
		self: ClassComponentSelf,
		partialStateUpdate: ClassStateUpdate
	) -> (),
	subscribeState: (self: ClassComponentSelf, listener: () -> ()) -> (() -> ())
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
export type Lifecycle = {
	render: Component,
	init: ((props: any) -> ())?,
	didMount: ((props: any) ->())?,
	shouldUpdate: ((newProps: any, oldProps: any) -> boolean)?,
	willUpdate: ((props: any, oldProps: any) -> ())?,
	didUpdate: ((props: any) -> ())?,
	willUnmount: ((props: any) -> ())?,
}



-- Unit testing types
export type UnitTestAsserts = {
	truthy: (value: any) -> (),
	falsy: (value: any) -> (),
	errors: (cb: () -> ()) -> (),
	no_errors: (cb: () -> ()) -> (),
	equal: (expected: any, actual: any) -> (),
	deep_equal: (expected: any, actual: any) -> (),
	not_equal: (expected: any, actual: any) -> (),
	not_deep_equal: (expected: any, actual: any) -> (),
}
export type UnitTester = (
	test: (
		moduleToTest: ModuleScript,
		withDescribeCallback: (
			describe: (
				unitName: string,
				withItCallback: (
					it: (
						behaviorDescription: string,
						withAssertsCallback: (
							asserts: UnitTestAsserts
						) -> ()
					) -> ()
				) -> ()
			) -> ()
		) -> ()
	) -> ()
) -> ()



-- Internal reconciler types
export type ContextProvider = {
	find: (name: string) -> any?,
	provide: (name: string, object: any?) -> (),
	unprovide: (name: string) -> (),
}
export type HostContext = {	-- Immutable type used as an object reference passed down in trees; the
							-- purpose of grouping these together is because typically components
							-- share the same host and context information except in special cases.
							-- This reduces memory usage and simplifies node visiting processes.
	instance: Instance?,
	childKey: string?,
	providers: {ContextProvider},
}
export type VirtualNode = {
	[any]: any,
	_wasUnmounted: boolean,
	_currentElement: Element,
	_hostContext: HostContext,
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
	
	mountVirtualNode: (element: Element | boolean, host: HostContext) -> ()
}

return nil