---
layout: default
title: Hooks
nav_order: 4
parent: API Reference
permalink: /api/hooks
---

# Pract API reference

> Warning: API Documentation is still a work in progress, and Pract's feature set has not yet been finalized.

Hooks are a functions that can be called inside component functions. They allow you to use state and other Pract features without wrapping your component in a HOF or class.

Some hooks have a [React equivalent](https://reactjs.org/docs/hooks-reference.html); refer to the React documentation for best-practices and function.

It is important, when using hooks to follow the [Rules of Hooks](https://reactjs.org/docs/hooks-rules.html)
Summarized as follows:

## Only Call Hooks at the Top Level
Don’t call Hooks inside loops, conditions, or nested functions. Instead, always use Hooks at the top level of your \[Pract\] component, before any early returns. By following this rule, you ensure that Hooks are called in the same order each time a component renders. That’s what allows \[Pract\] to correctly preserve the state of Hooks between multiple useState and useEffect calls. (If you’re curious, we’ll explain this in depth below.)

## Only Call Hooks from \[Pract\] Functions
## Don’t call Hooks from regular \[Luau\] functions. Instead, you can:

✅ Call Hooks from \[Pract\] function components.
✅ Call Hooks from custom Hooks (we’ll learn about them on the next page).
By following this rule, you ensure that all stateful logic in a component is clearly visible from its source code.

The current list of hooks added to Pract in 0.9.13 is as follows:

# Pract.useState

useState takes in a default state (or function that returns a default state),
and returns the current state, as well as a function to update the state.

Example usage:
```lua
local function MyComponent(props: {})
    local active, setActive = Pract.useState(false)
    return Pract.create("Frame", {
        Color = if active
            then Color3.fromRGB(80, 255, 80)
            else Color3.fromRGB(180, 180, 180),
        MouseButton1Click = function()
            setActive(not active)
        end,
    })
end
```

`Pract.useState` can replace `Pract.withState`.

`Pract.setState` updates the component with new state, and is safe to call from anywhere, as pract will simply defer state updates and reconciliation to the end of all currently-executing threads.

If the inital state is expensive to calculate, you can pass a callback to `Pract.useState`:

```lua
local function MyComponent(props: {})
    local coins, setCoins = Pract.useState(function()
        return someExpensiveCalculation()
    end)
    -- . . .
    return Pract.combine()
end
```



# Pract.useMemo

`Pract.useMemo` returns a value that is calculated once and then cached every time the component updates. For example:

```lua
local function MyComponent(props: {})
    local millionthDigitOfPi = Pract.useMemo(function()
        return someExpensiveCalculation()
    end)
    -- . . .
    return Pract.combine()
end
```

`Pract.useMemo` also takes in a second parameter called "deps" with is a list of values that the cache is dependent on. If any of the deps have changed, the function enclosed in `Pract.useMemo` will be called again, and the value will be updated with a new one.

Example of deps:
```lua
local function MyComponent(props: {player: Player})
    local codeName = Pract.useMemo(function()
        return someExpensiveCalculation(props.Player)
    end, {props.Player})
    -- . . .
    return Pract.combine()
end
```
In the above example, the "Player" prop is a dependency. Whenever "Player" changes, `codeName` updates. Because the function passed into `Pract.useMemo` is a closure, it is important to add every value it is dependent to the deps in order for state to be accurately shown.

`Pract.useMemo` can also be used to cache entire pract components for a small performance gain! For example:
```lua
local function MyComponent(props: {player: Player})
    local myFrame = Pract.useMemo(function()
        return Pract.create("Frame")
    end, {props.Player})
    -- . . .
    return Pract.index({
        Frame = myFrame,
    })
end
```

# Pract.useEffect

`Pract.useEffect` can be used cause some side effect every time the component updates, or every time a condition changes after the component has updated. The effect will be called after all currently-executing threads have finished:

```lua
local function MyComponent(props: {})
    Pract.useEffect(function()
        -- Makes an Http requests and prints
        -- the responce every time the
        -- component updates.
        local res = makeHttpRequest()
        print(rest)
    end)
    -- . . .
    return Pract.create("Frame")
end
```

`Pract.useEffect` can also take deps (a table of dependencies). If deps are provided, the effect will only be called every time the deps have changed:

```lua
local function MyComponent(props: {player: Player})
    Pract.useEffect(function()
        print(
            "Hello,",
            props.Player.DisplayName .. "!"
        )
    end, {props.Player})
    -- . . .
    return Pract.create("Frame")
end
```

It is important to mind that the effect is a closure, and thus needs to have any value that can change (e.g. props, returns from another hook) as a dependency in the deps table. Failing to do so can lead to undefined behavior that is hard to debug.

`Pract.useEffect` can also optionally return a "cleanup" function to maintain consistency with React, though it is recommended to use `Pract.createHook` for things like this instead. The cleanup function is called whenever the dependencies change, or the component is unmounted:

```lua
local function MyComponent(props: {player: Player})
    Pract.useEffect(function()
        setSomeExternalState(true)
        return function()
            setSomeExternalState(false)
        end
    end, {})
    -- . . .
    return Pract.create("Frame")
end
```

# Pract.useSignalUpdates

We've see hooks in the past that cause the updating component to redraw under some future condition.
While you can write custom code (using `Pract.useEffect` or `Pract.createHook`) that updates the component every time a signal is fired, Pract offers a utility to connect/disconnect this signal when mounted/unmounted respectively, and update the component every time the signal is fired:

```lua
local RunService = game:GetService("RunService")
local RenderStepped = RunService.RenderStepped
local function MyComponent(props: {player: Player})
    -- This statement causes the component to update every frame:
    Pract.useSignalUpdates(RenderStepped)
    local startTime = Pract.useMemo(os.clock)
    -- Since this component updates every frame, we can rely on this value:
    local currentTime = os.clock()

    return Pract.create("TextLabel", {
        Text = string.format(
            "This component has been mounted for exactly %.2f seconds!",
            -- We can use os.clock() since we have
            currentTime - startTime
        )
    })
end
```

# Pract.useConsumer

The following functions are also added:


# Pract.createContext
# Pract.createHook

Full documentation is coming soon.