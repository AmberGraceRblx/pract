---
layout: default
title: Lifecycle
nav_order: 7
parent: Basic Guide
permalink: basic/lifecycle
---

# Lifecycle

We've discussed some concepts about Pract's virtual GUI tree—Elements are **mounted** in a host context, can be **updated** by being replaced with new elements, and can be **unmounted** to clean up UI components and instances.

Certain points on the timeline between a component or instance being _mounted_ and _unmounted_ is called its **lifecycle**, and we can write components that perform special behaviors during parts of their lifecycle.

The `Pract.lifecycle` takes in a closure function (which is called once when the component is mounted), and should return a table of type `Pract.Lifecycle`. This table must have a `render` function which is a component.

```lua
local MyLifecycleComponent = Pract.withLifecycle(function(): Pract.Lifecycle
    return {
        render = function(props: {text: string})
            return Pract.create('TextLabel', {
                Text = text,
            })
        end,
    }
end)

local myElement = Pract.create(MyLifecycleComponent, {text = 'Hello, Lifecycle!'})
```

The code above acts equivalently to the components we've seen before. Let's add what's called a _lifecycle hook_, and print something just before a component finishes mounting:

```lua
local MyLifecycleComponent = Pract.withLifecycle(function(): Pract.Lifecycle
    return {
        init = function(props: {text: string})
            print("We are mounting our lifecycle component with text", props.text)
        end,
        render = function(props: {text: string})
            print("We are rendering our lifecycle component with text", props.text)
            return Pract.create('TextLabel', {
                Text = text,
            })
        end,
    }
end)
```

If we mount this component, then update it, it should only print our mounting message once, and our rendering message twice:

> (Image coming soon when roblox isn't down)

The following hooks can be used in a lifecycle component: `init`, `render`, `didMount`, `shouldUpdate`, `willUpdate`, `didUpdate`, `willUnmount`

### **_Mounting_ process in Pract:**

1. Pract is told to mount an element (via `Pract.mount` or otherwise)
2. The `withLifecycle` closure function is called, and the Lifecycle table is returned
3. `init` is called with the first props passed into the component
4. `render` is called to get the component's elements
5. Gui instances are created/destroyed/modified to match the elements returned by the render component
6. `didMount` is called with the first props passed into the component

### **_Updating_ proccess in Pract:**

1. An update is triggered on a mounted component (via `Pract.update`, or otherwise)
2. `shouldUpdate` function on the Lifecycle is called if it exists. This function takes in the new and old props, and should return a boolean (true or false). If it returns true, we continue updating; if it returns false, we stop the update immediately.
3. `willUpdate` is called with the new props
4. `render` is called to get the component's updated elements
5. Gui instances are created/destroyed/modified to match the elements returned by the render component
6. `didUpdate` is called with the new props

### **_Unmounting_ proccess in Pract:**

1. An unmount is triggered on a mounted component (via `Pract.unmount`, or otherwise)
2. `willUnmount` function on the Lifecycle is called if it exists. This function takes in the new and old props, and should return a boolean (true or false). If it returns true, we continue updating; if it returns false, we stop the update immediately.
3. `willUpdate` is called with the new props
4. `render` is called to get the component's updated elements
5. Gui instances are created/destroyed/modified to match the elements returned by the render component
6. `didUpdate` is called with the new props

## Putting it all together

In addition to all of this, the `withLifecycle` closure is passed in a function called `forceUpdate`, which will trigger an update on the nested Lifecycle component when called. This will automatically be throttled to happen once per frame at most.

A completely filled-out lifecycle component which uses all lifecycle hooks will look like this:

```lua
type Props = {}
local MyLifecycleComponent = Pract.withLifecycle(function(forceUpdate): Pract.Lifecycle
    print("Closure called")
    return {
        init = function(firstProps: Props)
            print("Init")
        end,
        didMount = function(firstProps: Props)
            print("Did mount")
        end,
        render = function(props: Props)
            print("Render") -- Note: You should avoid having side effects in the render function
                            -- itself.
            return Pract.create('Frame')
        end,
        shouldUpdate = function(props: Props)
            print("Should update?")
            return true -- If we return false here, an update will abort.
        end,
        willUpdate = function(props: Props)
            print("Will update")
        end,
        didUpdate = function(props: Props)
            print("Did update")
        end,
        willUnmount = function(lastProps: Props)
            print("Will unmount")
        end,
    }
end)
```

## Incrementing Counter using State and Lifecycle

```lua
--!strict
local Pract = require(game.ReplicatedStorage.Pract)

local function Clock(props: {time: number})
    return Pract.create("ScreenGui", {}, {
        TimeLabel = Pract.create("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            Text = "Time Elapsed: " .. props.time
        })
    })
end

-- This component will begin a loop that upticks our state every second until it is unmounted!
local Upticker = Pract.withDeferredState(function(getTime, setTime)
    -- Initialize our time state
    setTime(0)

    -- Because Pract.withLifecycle returns a component, we can nest it here!
    return Pract.withLifecycle(function())
        local mounted = true
        return {
            init = function()
                -- Start a new thread here which ends when the component is unmounted
                task.spawn(function()
                    repeat
                        task.wait(1)

                        setTime(getTime() + 1) -- This will automatically trigger an update.
                    until not mounted
                end)
            end,
            render = function(props: {}) -- This render component can depend on both state and props
                return Pract.create(Clock, {
                    time = getTime()
                })
            end,
            willUnmount = function()
                mounted = false
            end,
        }
    end)
end)

local PlayerGui = game.Players.LocalPlayer:WaitForChild('PlayerGui')
local handle = Pract.mount(Pract.create(Upticker), PlayerGui, "Clock UI")
```

Note how in this example, we never have to call `Pract.update`! That is because all state-based
updates are contained within the Upticker component intself.

#### Up Next: [Class Components](classcomponents)