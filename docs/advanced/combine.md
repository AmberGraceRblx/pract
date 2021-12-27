---
layout: default
title: Combining Elements
nav_order: 1
parent: Advanced Guide
permalink: advanced/combine
---

# Pract.combine

A unique feature of Pract is that the library allows and encouraging _mounting multiple elements to the same host!_ This allows you to have multiple components which modify or connect events to the same instance.

`Pract.combine` will mount multiple elements to the same hostContext. One direct use case is having re-usable input-handling components

```lua
local function HoverInput(props: {began: () -> (), ended: () -> ()})
    return Pract.decorate {
        InputBegan = function(rbx: TextButton, input: InputObject)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                props.began()
            end
        end,
        InputEnded = function(rbx: TextButton, input: InputObject)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                props.ended()
            end
        end,
        -- Though this currently only captures desktop hovering, we could potentially use this to
        -- capture mobile events (such as tapping over a GuiObject for a long period of time)
        -- or any other cross-platform event handling!
    }
end

local MyFancyButton = Pract.withDeferredState(function(getHovering, setHovering)
    return function(props: {text: string, clicked: () -> ()})
        return Pract.combine(
            -- This component is purely visual; it simply defines the visuals from state and props!
            Pract.stamp(script.FancyButtonTemplate, {
                Text = props.text,
                TextColor3 = if getHovering()
                    then Color3.fromRGB(0, 255, 255)
                    else Color3.fromRGB(255, 255, 255),
                MouseButton1Click = props.clicked,
            }),
            -- This component is purely functional; it encapsulates a reusable hover input event
            -- system that might otherwise be tedious to re-write every time we create a button in
            -- our UI.
            -- This component will decorate the instance created by `Pract.stamp` above.
            Pract.create(HoverInput, {
                began = function()
                    setHovering(true)
                end,
                ended = function()
                    setHovering(false)
                end,
            })
        )
    end
end)
```

`Pract.combine` can make it really easy to make your UI cross-platform compatible, without having to re-write cross platform input code every time you create a new button! Simply create a decorator component like our `HoverInput` above, and combine it with a platform-agnostic visual component!

## Host Propogation

The order in which you combine elements matters when determining the _host context_ of each element being combined.

For example, you can combine the element `Pract.create("Frame")` with `Pract.decorate({Size = UDim2.fromOffset(20, 20)})` to both create and decorate the same instance. As in the Hoverinput example, this can be used to make "decorative" components that add functionality to another pre-created element. The Pract reconciler will automatically match _decorative_ elements with _instancing_ element's hosts. This means that the order in which you combine elements matters.

As a rule of thumb:
    - Place `Pract.stamp` and `Pract.create("ClassName")` elements earlier in the combined tuple.
    - Place `Pract.decorate` and `Pract.index` elements later in the combined tuple.
    - If a component returns a `Pract.stamp`/`Pract.create("ClassName")` element, place the
    `Pract.create(Component)` expression earlier in the combined tuple. Otherwise, place it later.

## A Caveat On Combine Order

When a `Pract.combine` element is updated, the order of combined elements matter when determining which elements are unmounted/remounted!
Here's a simple example that highlights the behavior:

```lua
local function ValueDecorator(props: {value: string})
    return Pract.decorate({
        Value = props.value,
        [Pract.OnMountWithHost] = function()
            print(value .. " mounted!")
        end,
        [Pract.OnUnmountWithHost] = function()
            print(value .. " mounted!")
        end,
    })
end

local tree = Pract.mount(
    Pract.combine(
        Pract.create("StringValue", workspace),
        Pract.create(ValueDecorator, {value = "Foo"}),
        Pract.create(ValueDecorator, {value = "Bar"})
    ),
    "MyStringValue"
)
```

This should create a StringValue named "MyStringValue" in workspace, with a value finally set to "Bar".
The output should show that "Foo" mounted and then "Bar" mounted:

```txt
Foo mounted!
Bar mounted!
```

If we update our tree with our "Foo" element removed, we will see the positionally-dependent behavior of `combine` in action:

```lua
Pract.update(
    tree,
    Pract.combine(
        Pract.create("StringValue", workspace),
        Pract.create(ValueDecorator, {value = "Bar"})
    )
)
```

Our output shows that both "Foo" and "Bar" were unmounted before re-mounting "Bar"; this is because "Bar" was moved from the third position on our `combine` tuple to the second position. Pract recognizes that the component type at each position has changed, and will re-mount these components instead of performing a regular update:

```txt
Foo unmounted!
Bar unmounted!
Bar mounted!
```

If your combine expression contains a conditional list of elements, make sure that all of your conditional elements (i.e. elements that are only _sometimes_ in a component's combine tuple) are placed `_last_` in the combine tuple where possible.

Example:
```lua
--!strict
local Pract = require(game.ReplicatedStorage.Pract)
local StampingComponent = require(game.ReplicatedStorage.StampingComponent)
local RecoloringComponent = require(game.ReplicatedStorage.RecoloringComponent)
local RepositioningComponent = require(game.ReplicatedStorage.RepositioningComponent)

local function MyComponent(props: {reposition: boolean})
    local elements: {Pract.Element} = {}

    table.insert(elements, Pract.create(StampingComponent, {}))
    table.insert(elements, Pract.create(RecoloringComponent, {}))

    -- Because this element is conditional, we want it to be placed LAST in our array of elements!
    if props.reposition then
     table.insert(elements, Pract.create(RepositioningComponent, {}))
    end

    -- Convert our array of elements to a tuple of combined elements
    return Pract.combine(unpack(elements))
end
```

#### Up next: [Using Pract.Children in Components](./children)