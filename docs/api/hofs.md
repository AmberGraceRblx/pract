---
layout: default
title: Higher-Order Functions & Component Creators
nav_order: 2
parent: API Reference
permalink: /api/hofs
---

> DEPRECATED - Most higher order functions that ship with Pract are now deprecated in favor of
[Hooks](./hooks)!

# Higher-Order Functions

> Warning: API Documentation is still a work in progress, and Pract's feature set has not yet been finalized.

[Higher-Order Functions](../basic/state#higher-order-functions), in Pract, are functions that take another function (or table of functions) as an argument, and return a [Component](../basic/components) and essentially "supercharges" another component that we define.

Typically the argument passed in is a function that creates a [Closure](https://en.wikipedia.org/wiki/Closure_(computer_programming)) with our supercharged parameters passed in, and should return a `Component` that renders based on these supercharged parameters.

These closure creator functions are called once when the component mounts, and their returned component (or `render` function) is called by the reconciler whenever the component updates.

## Pract.withState

```lua
Pract.withState(
	makeClosureCallback: (
		getState: () -> any,
		setState: (any) -> (),
		subscribeState: (() -> ()) -> (() -> ())
	) -> Pract.Component
): Pract.Component
```

See: [State](../basic/state) for a more detailed usage guide on `Pract.withState`

Returns a [Component](../basic/components); takes in a closure creator function, with a state hook accessed through a `getState`, `setState`, and `subscribeState` function.
`getState` returns the current value of the state. `setState` sets the current value of the state and immediately triggers an update on `makeClosureCallback`'s returned component. `subscribeState` allows a listener to be fired when state changes (so long as the component is still mounted), and returns an `unsubscribe` function to unsubscribe the listener from state changes.

## Pract.withDeferredState

```lua
Pract.withDeferredState(
	makeClosureCallback: (
		getState: () -> any,
		setState: (any) -> (),
		subscribeState: (() -> ()) -> (() -> ())
	) -> Pract.Component
): Pract.Component
```

Returns a [Component](../basic/components); acts identically to [Pract.withState](#practwithstate), with the exception that `setState` will only trigger an update to `makeClosureCallback`'s returned component once per frame.

## Pract.withLifecycle

```lua
Pract.withLifecycle(
	makeClosureCallback: (
        forceUpdate: () -> ()
    ) -> Pract.Lifecycle
): Pract.Component
```

See: [Lifecycle](../basic/lifecycle) for a more detailed usage guide on `Pract.withLifecycle`

Returns a [Component](../basic/components); takes in a closure creator function, with a `forceUpdate` function that will trigger an update (throttled to only update at most once per frame), and returns a `Pract.Lifecycle` object. This lifecycle object is a table of functions that must include a `render` function, which is a component that will be called every time an update happens. Other functions on this table will run at different points of the component's lifecycle when mounted. See [Lifecycle](../basic/lifecycle#putting-it-all-together) for a full list of lifecycle functions.

Lifecycle type definition:
```lua
type Pract.Lifecycle = {
	render: Pract.Component,
	init: ((props: any) -> ())?,
	didMount: ((props: any) ->())?,
	shouldUpdate: ((newProps: any, oldProps: any) -> boolean)?,
	willUpdate: ((props: any, oldProps: any) -> ())?,
	didUpdate: ((props: any) -> ())?,
	willUnmount: ((props: any) -> ())?,
}
```

## Pract.withSignal

```lua
Pract.withSignal(
	signal: RBXScriptSignal,
	wrappedComponent: Pract.Component
): Pract.Component
```

Returns a [Component](../basic/components); takes in a signal (to be connected when mounted and disconnected when unmounted). Every time the signal is fired, an update in the wrapped component will be triggered.

## Pract.withContextProvider

```lua
Pract.withContextProvider(
	makeClosureCallback: (
		provide: (string, any) -> (() -> ())
	) -> Pract.Component
): Pract.Component
```

Returns a [Component](../basic/components); `makeClosureCallback` is passed in a special `provide` function, which adds an object to every child's host context, which can later be consumed by any descendant `Pract.withContextConsumer`-wrapped component. `provide` takes in any string as the object's key, and the object itself as the second argument. `provide` also returns an `unprovide` function (which will automatically be called when the provider component is unmounted).

## Pract.withContextConsumer

```lua
Pract.withContextConsumer(
	makeClosureCallback: (
		consume: (key: string) -> any
	) -> Pract.Component
): Pract.Component
```

Returns a [Component](../basic/components); `makeClosureCallback` is passed in a special `consume` function, which takes in any key, and returns an  object provided by the last ancestor `Pract.withContextProvider`-wrapped component. If the object does not exist (i.e. no object was provided by an ancestor component at that key), `consume` will return nil.

## Pract.classComponent

```lua
Pract.classComponent(
    methods: Types.ClassComponentMethods
): Pract.Component
```

Returns a [Component](../basic/components); Takes in a table of class methods, which must include a `render` function. These methods are similar to those on a Lifecycle table, except that they take in a special `self` argument representing the mounted class component. See [Class Components](../basic/classcomponents) for a more detailed usage guide.

ClassComponentMethods type definition:
```lua
type Pract.ClassComponentMethods = {
	-- You can add custom methods or values to this table, as it will be used as the
	-- __index table for the self object's metatable.
	[any]: any,

	render: (self: Pract.ClassComponentSelf) -> Element,
	init: ((self: Pract.ClassComponentSelf) -> ())?,
	didMount: ((self: Pract.ClassComponentSelf) ->())?,
	shouldUpdate: ((
		self: Pract.ClassComponentSelf,
		newProps: Pract.PropsArgument,
		newState: Pract.ClassState
	) -> boolean)?,
	willUpdate: ((
		self: Pract.ClassComponentSelf,
		newProps: Pract.PropsArgument,
		newState: Pract.ClassState
	) -> ())?,
	didUpdate: ((self: Pract.ClassComponentSelf) -> ())?,
	willUnmount: ((self: Pract.ClassComponentSelf) -> ())?,
}
```