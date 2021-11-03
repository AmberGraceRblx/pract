---
layout: default
title: Elements & Element Creators
nav_order: 1
parent: API Reference
permalink: /api/elements
---

# Element Creators

> Warning: API Documentation is still a work in progress, and Pract's feature set has not yet been finalized.

## Pract.create

```lua
Pract.create(
	classNameOrComponent: string | Pract.Component,
	props: Pract.PropsArgument?,
	children: Pract.ChildrenArgument?
): Pract.Element
```

Creates an [element](../basic/instancingelements) representing a newly-created instance or component. Elements are like blueprints, which Pract uses to determine how to create/destroy/modify instances to match this blueprint.

If the first argument to `Pract.create` is a string, Pract will call `Instance.new(...)` when mounted, and parent the newly-created instance to its [host instance](../basic/templatingelements#host-context), if one exists. Pract will assign the created instance's properties depending on the `props` argument provided. Pract will also rename this instance to its [host child name](../basic/templatingelements#host-context), if provided, or the string "PractTree" by default.

The `children` argument is shorthand for `Pract.Children` and will override that symbol in props, if provided. The children table should be a record with the child names as keys, and child elements as values. The keys will determine the [host child names](../basic/templatingelements#host-context) of the child elements when mounted.

If the first argument to `Pract.create` is a [Component](../basic/components) (a function, typed `(Pract.PropsArgument) -> Pract.Element`), Pract will call this component when mounted or updating with the props provided as the component's first argument, and then mount or update the component's returned elements to the same host context.

## Pract.stamp

```lua
Pract.stamp(
    template: Instance,
    props: Pract.PropsArgument?,
    children: Pract.ChildArgument?
): Pract.Element
```

Creates an element representing an instance to be cloned and decorated from the template.

When mounted, pract will call `template:Clone()`, parent it to the [host instance](../basic/templatingelements#host-context), rename the template to the [host child name](../basic/templatingelements#host-context), if provided (otherwise, it will be named "PractTree"), and assign the instance's properties based on the `props` argument provided. Will mount any children provided.

## Pract.decorate

```lua
Pract.decorate(
    props: Pract.PropsArgument?,
    children: Pract.ChildArgument?
): Pract.Element
```

Creates an element representing an existing instance to be decorated when found.

When mounted, pract will wait for a child of the [host instance](../basic/templatingelements#host-context) (if it does not exist, will throw an error) named after the [host child name](../basic/templatingelements#host-context) (if it does not exist, will instead decorate the host instance itself), and assign the instance's properties based on the `props` argument provided. Will mount any children provided once the decorated instance is found.

## Pract.index

```lua
Pract.index(
    children: Pract.ChildArgument?
): Pract.Element
```

Creates an element representing an existing instance to be indexed in a tree, but not modified.

When mounted, pract will wait for a child of the [host instance](../basic/templatingelements#host-context) (if it does not exist, will throw an error) named after the [host child name](../basic/templatingelements#host-context) (if it does not exist, will instead decorate the host instance itself. Will mount any children provided once the indexed instance is found.

## Pract.portal

```lua
Pract.portal(
    hostInstance: Instance,
    children: Pract.ChildArgument?
): Pract.Element
```

Creates an element representing an explicit change in host context

When mounted, pract will mount its child elements with the provided `hostInstance` as the child elements' [host instance](../basic/templatingelements#host-context), and the keys of the children map as the [host child names](../basic/templatingelements#host-context)



## Pract.combine

```lua
Pract.combine(
    ...: Pract.Element
): Pract.Element
```

See: [State](../advanced/combine) for more detailed examples using `Pract.combine`

Returns an element which instructs pract to mount multiple elements with the same host context. A good use case for this is having components dedicated to user input mounted together with components, which decorate the same instance. With `Pract.combine`, user input components can be re-used, while visual components can be more specialized.