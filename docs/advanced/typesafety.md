---
layout: default
title: Type Safety
nav_order: 7
parent: Advanced Guide
permalink: advanced/typesafety
---

# Type Safety

> Note: This section assumes you have a basic understanding of Luau's [type system](https://luau-lang.org/typecheck).

Pract is compatible with Luau's [type system](https://luau-lang.org/typecheck), and provides variants of previously-discussed features for creating typesafe components!

Pract's design puts an emphasis on type system use being _opt-in_, as some people may not wish to use Luau's type system in their code. Pract's default constructs have lenient typings, while offering constructs with stricter typings.

At the time this page is being written, Luau's type system is somewhat underdeveloped, and as such, using Pract with types in strict mode requires a number of conventional tricks to properly assert or annotate types. This article is not completely future-proof, and Pract's type constructs are subject to change. For now, using types with Pract is possible as long as you remember to annotate types where needed.

## Typing component props

Pract exports a type `ComponentTyped<Props>` that allows you to annotate your components as having a particular type.
A good rule of thumb when typing components is to export the component's props with the module containing the component's code.

Example:
```lua
--!strict

local Pract = require(game.ReplicatedStorage.Pract)

-- This type can be checked statically both in our component function, and with external code using
-- our component.
export type Props = {
    size: UDim2,
}
-- Here, we annotate our component to be typed with our props
local MyComponent: Pract.ComponentTyped<Props> = function(props)
    return Pract.create("Frame", {
        Size = props.size,
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
    })
end

return MyComponent
```

## Using a typed component externally

In order for our `Props` type to be validated by exeternal code, we need to use the [`Pract.createTyped`](../api/elements#pract_createtyped) function, which will validate the props we provide to our component.

```lua
--!strict

local Pract = require(game.ReplicatedStorage.Pract)
local MyComponent = require(game.ReplicatedStorage.MyComponent)

local function App(props: {})
    -- If this props table being passed through does not match the MyComponent.Props type, we will
    -- see script analysis warnings about the type mismatch!
    return Pract.createTyped(MyComponent, {
        size = UDim2.fromOffset(200, 300),
    })
end

return App
```

## Typing components using Higher-Order Functions

One pitfall/necessary convention for using types under roblox's current type system is that, if you use Pract's higher-order functions, you will need to place type annotations in the correct place in order to have proper type safety.

Consider the following example of a lifecycle component:

```lua
--!strict

-- THIS EXAMPLE WILL ERROR AT RUNTIME!

local Pract = require(game.ReplicatedStorage.Pract)

export type Props = {
    size: UDim2,
}
local MyComponent: Pract.ComponentTyped<Props> = Pract.withLifecycle(function(forceUpdate)
    return {
        render = function(props) -- props will be typed as any by default!
            return Pract.create("Frame", {
                Size = props.THIS_SHOULD_NOT_EXIST,
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
            })
        end
    }
end)

return MyComponent
```

Even though our `Props` type will be checked in code using this component, the component itself does not correctly type `props`, and under Roblox's current type system, there is no way to create good constructs that will automate this. For now, make sure you manually give `props` a type annotation:

```lua
--!strict

-- THIS EXAMPLE WILL ERROR AT RUNTIME!
-- However, we will be able to catch this error through type checking before even running the game!

local Pract = require(game.ReplicatedStorage.Pract)

export type Props = {
    size: UDim2,
}
local MyComponent: Pract.ComponentTyped<Props> = Pract.withLifecycle(function(forceUpdate)
    return {
        render = function(props: Props) -- Here, we manually annotate our props type
            return Pract.create("Frame", {
                Size = props.THIS_SHOULD_NOT_EXIST, -- We will correctly see a script analysis warning here!
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
            })
        end
    }
end)

return MyComponent
```

## Typing class components

Class components probably require the largest amount of manual effort in typing, and can never be 100% typesafe. However, there are still some conventions that can be used to improve type safety while writing class components:

```lua
--!strict

local Pract = require(game.ReplicatedStorage.Pract)

type State = { -- We generally don't need to export our state type, since it is private.
    hovering: boolean,
}
export type Props = {
    size: UDim2,
}
local MyClassComponent: Pract.ComponentTyped<Props> = Pract.classComponent({
    init = function(self)
        -- The type of "self" will automatically be inferred to a generic Pract
        -- type ("Pract.ClassComponentSelf"); however, state and props will by typed as "any" by
        -- default. As such, we need to annotate our types strategically.

        -- Here, it is a good idea to store our initial state in a typed variable:
        local initialState: State = {
            hovering = false,
        }
        self:setState(initialState)
    end,
    render = function(self)
        -- Because props and state are typed as any, it is a good idea to store them into annotated
        -- variables here:
        local state: State = self.state
        local props: Props = self.props

        return Pract.create("Frame", {
            Size = props.size, -- Here, "props.size" is type-checked!
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = if state.hovering -- Here, "state.hovering" is type-checked!
                then Color3.fromRGB(0, 120, 255)
                else Color3.fromRGB(255, 255, 255),
            MouseEnter = function()
                self:setState({
                    hovering = true -- This currently can't be type-checked, unfortunately.
                })
            end,
            MouseLeave = function()
                self:setState({
                    hovering = false
                })
            end,
        })
    end,
})

return MyClassComponent
```

## Custom class component methods

Currently, class components are typed with a `{[any]: any}` index type. This means you can add custom methods to your class, but they will by typed as `any`. This means that `self` will not be automatically typed unlike other lifecycle methods. One pitfall of this is that they currently cannot be typechecked, so be wary of this:

```lua
--!strict

local Pract = require(game.ReplicatedStorage.Pract)

type State = {
    hovering: boolean,
}
export type Props = {
    size: UDim2,
}
local MyClassComponent: Pract.ComponentTyped<Props> = Pract.classComponent({
    init = function(self)
        local initialState: State = {
            hovering = false,
        }
        self:setState(initialState)
    end,
                -- Note: we should manually type "self" in custom methods!
    setHovering = function(self: Pract.ClassComponentSelf, hovering: boolean)
        self:setState({
            hovering = hovering,
        })
    end,
    render = function(self)
        local state: State = self.state
        local props: Props = self.props

        return Pract.create("Frame", {
            Size = props.size,
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = if state.hovering
                then Color3.fromRGB(0, 120, 255)
                else Color3.fromRGB(255, 255, 255),
            MouseEnter = function()
                self:setHovering(true) -- This method will not be type-checked!
            end,
            MouseLeave = function()
                self:setHovering(false)
            end,
        })
    end,
})

return MyClassComponent
```

## Conclusion

Using types with Pract is useful for scaled codebases, and can make it so that you never pass in bad props to a component. However, this requires some manual type annotation, and may not be suitable for every project. Consider whether and/or where type safety is necessary in your project. The conventions of type annotations in Pract code may be harder to understand to people unversed in Pract/Luau's type system in general. On the other hand, type constructs can catch errors in your code before even running a playtest.

#### Up Next: ???

You've reached the end of the Pract documentation.
Much of this documentation is a first draft, and may be subject to change in the future. Collaborators would be appreciated in improving the documentation and functionality of the Pract library in general!