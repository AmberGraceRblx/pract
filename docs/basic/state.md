---
layout: default
title: State
nav_order: 6
parent: Basic Guide
permalink: basic/state
---

# Higher-Order Functions

A _higher-order function_ (HOF) is a function that takes in another function (called a "callback") as an argument, and essentially "supercharges" that callback functions with extra behavior or features.

Right now we've explored ways we can design our UI using Elements, and simplifying it using Components and their associated `props`. While Components and Elements can accomplish a lot, they require the entire Pract tree to be reconciled every single time you wish to make any change to the UI whatsoever.

Instead, it would be better to have some way to update only _part of our UI_ on an as-needed basis—for example, changing the color of a button (and only that button) when hovering over it, or upticking a "coins" counter when we pick up a coin.

# State

State allows you to store and update some value inherent to a component once it has mounted, and only re-render the component itself every time this state changes. In order to give our component state, we need to supercharge it using the `Pract.withState` higher-order function:

```lua
local MyHoverButton = Pract.withState(function(getHovering, setHovering): Pract.Component
    -- This is what's called a closure; code that's run here is only run once when the component is
    -- mounted!
    -- getHovering allows us to get our state, and setHovering allows us to set our state.

    -- Initialize our state
    setHovering(false)

    -- Our callback needs to return a Component! This component will be called every time our state
    -- or props change.
    return function(props: {text: string}): Pract.Element
        local color
        if getHovering() == true then
            color = Color3.fromRGB(0, 255, 0)
        else
            color = Color3.fromRGB(255, 255, 255)
        end

        return Pract.create('TextButton', {
            BackgroundColor3 = color,
            Text = props.text
            MouseEnter = function() -- We can pass in a function as props, and Pract will
                                    -- automatically connect it to the signal.
                setHovering(true)
            end,
            MouseLeave = function() -- Note: this event is finnicky, and I would recommend using
                                    -- InputBegan/InputEnded instead for hover logic.
                setHovering(false)
            end,
        })
    end
end)
```

> Note that calling `Pract.withState` creates two nested components: One that's returned by `Pract.withState`, and one that's returned by the callback we pass into `Pract.withState`. The component we return from our callback depends on both `state` and `props`, while the component returned by `Pract.withState` depends on neither.

## Widget Clicker Example:

```lua
--!strict
local Pract = require(game.ReplicatedStorage.Pract)

-- The following two Components are stateless (they render purely from props)
local function ClicksLabel(props: {clicks: number})
    return Pract.create('TextLabel', {
        Size = UDim2.new(1, 0, 0.5, 0),
        Text = string.format('You have clicked the widget %d times!', props.clicks)
    })
end

local function WidgetButton(props: {onClick: () -> ()})
    return Pract.create('TextButton', {
        Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(255, 0, 0), Text = string.format('WIDGET'),
        MouseButton1Click = props.onClick,
    })
end

-- Here, we have a root-level Component with state:
local WidgetClicker = Pract.withState(function(getClicks, setClicks)
    -- Initialize our state with zero when the component is mounted.
    setClicks(0)

    -- Our callback needs to return a Component function! This will be called every time our state
    -- or props change.
    return function(props: {})
        return Pract.create('ScreenGui', {}, {
            ClicksDisplay = Pract.create(ClicksLabel, {
                clicks = getClicks()
            }),
            Widget = Pract.create(WidgetButton, {
                onClick = function()
                    setClicks(getClicks() + 1)
                end,
            })
        })
    end
end)

-- Note how we never have to call Pract.update, since the state HOF (higher-order function) takes
-- care of updates for us!
Pract.mount(
    Pract.create(WidgetClicker),
    game.Players.LocalPlayer:WaitForChild('PlayerGui'),
    'Widget Clicker'
)
```

> The above example has a few complex parts to it, so take your time to examine it and read the comments carefully. Try to recreate this yourself using templated Stamp/Index/Decorate Elements instead of Create Elements!


## Subscribing to state

In addition to `getState` and `setState`, the `withState` Higher-Order Function also passes in a third argument, `subscribeState`, which allows you to listen for state changes and process or debug them elsewhere. `subscribeState` returns an "unsubscribe" function, and all listeners for state changes will be cleaned up if the stateful component is ever unmounted:

```lua
local MyHoverButton = Pract.withState(function(
    getHovering,
    setHovering,
    subscribeHovering
): Pract.Component
    -- Initialize our state
    setHovering(false)

    -- Debug our state
    local unsubscribe = subscribeHovering(function()
        print("Hovering state changed to", getHovering())
    end)

    return function(props: {text: string}): Pract.Element
        local color
        if getHovering() == true then
            color = Color3.fromRGB(0, 255, 0)
        else
            color = Color3.fromRGB(255, 255, 255)
        end

        return Pract.create('TextButton', {
            BackgroundColor3 = color,
            Text = props.text
            MouseEnter = function()
                setHovering(true)
            end,
            MouseLeave = function()
                setHovering(false)
            end,
            MouseButton1Click = function()
                print("You clicked the button! We will no longer print hovering state updates.")
                unsubscribe()
            end
        })
    end
end)
```

## Deferred state
While `Pract.withState` exposes functions for changing state which will immedaitely trigger an update in Pract when changed, Pract also provides `Pract.withDeferredState`, which will only trigger updates at a maximum of once per frame.

It's recommended that you use `withDeferredState` unless you absolutely need immediate state updates.

#### Up Next: [Lifecycle](lifecycle)