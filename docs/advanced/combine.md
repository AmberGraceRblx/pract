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
local function HoverInput(props: {began: () -> (), ended: () -> ())})
    return Pract.decorate {
        InputBegan = function(rbx: TextButton, input: InputObject)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                props.hoverBegan()
            end
        end,
        InputEnded = function(rbx: TextButton, input: InputObject)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                props.hoverEnded()
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

#### Up next: [Using Pract.Children in Components](./children)