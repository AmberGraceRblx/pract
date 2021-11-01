---
layout: default
title: Class Components
nav_order: 8
parent: Basic Guide
permalink: basic/classcomponents
---

# Class Components

A class component essentially combines State and Lifecycle components, described in the previous section.

Class components have an almost-identical structure to [Roact's class components](https://roblox.github.io/roact/guide/components/).

State and Lifecycle are decoupled from components in Pract because, almost all of the time, there isn't a need to have both of these things in every single component.

In the case of class components, the class' methods are pre-defined, and passed in as the first argument to `Pract.classComponent` .
`Pract.classComponent` actually uses `Pract.withLifecycle` and `Pract.withDeferredState` under the hood to combine the two!
```lua
local MyClassComponent = Pract.classComponent {
    init = function(self)
        -- We should initialize our state here.
        self:setState({
            foo = 'Fighters'
        })
    end,
    render = function(self)
        return Pract.create('TextLabel', {
            Text = self.state.foo
        })
    end,
}
```

Unlike `Pract.withState`, `self.setState` takes in a _partial_ table of state updates. This means you can specify the portion of your state to update:
```lua
local MyButton = Pract.classComponent {
    init = function(self)
        -- We should initialize our state here.
        self:setState {
            clicks = 0,
            hovering = false
        }
    end,
    render = function(self)
        local color
        if self.state.hovering then
            color = Color3.fromRGB(255, 0, 0)
        else
            color = Color3.fromRGB(255, 255, 255)
        end
        return Pract.create('TextButton', {
            Text = self.props.text,
            BackgroundColor3 = color,
            MouseButton1Click = function()
                self:setState {
                    clicks = self.state.clicks + 1
                }
            end,
            HoverBegan = function()
                self:setState {
                    hovering = true
                }
            end,
            HoverEnded = function()
                self:setState {
                    hovering = false
                }
            end,
        })
    end,
}
```

## Self Members

The `self` object passed to each of these lifecycle method is an object that stores _state_, _props_, and _callbacks_ on the component while it is mounted; you can also assign variables to `self` on your own!

| `self.state` | Holds the last value that state was set to (updated after `self:setState()` was called) |
| `self.props` | Holds the las value that props was set to (updated just before `render` was called) |
| `self:setState(stateUpdate)` | Updates a portion of the state. If the state change is redundant, no update is triggered. |
| `self:subscribeState(listener)` | Subscribes a listener function to any changes in the component's state. Returns an `unsubsribe` function. |
| `self:forceUpdate()` | Forces the component to update (so long as `shouldUpdate` does not return false, if provided) |

## Class Component Lifecycle

A class component's lifecycle methods are similar to `withLifecycle` component lifecycle, but the arguments passed are slightly different.
```lua
local MyButton = Pract.classComponent {
    init = function(self)
        print("Init", self.props, self.state)
    end,
    didMount = function(self)
        print("Did Mount", self.props, self.state)
    end,
    render = function(self)
        print("Render", self.props, self.state)
        return Pract.create('Frame')
    end,
    shouldUpdate = function(self, newProps, newState)
        local oldProps = self.props
        local oldState, self.state
        print("Should Update (from", oldProps, oldState, "to", newProps, newState, ")")
        return true
    end,
    willUpdate = function(self, newProps, newState)
        local oldProps = self.props
        local oldState, self.state
        print("Will Update (from", oldProps, oldState, "to", newProps, newState, ")")
    end,
    didUpdate = function(self)
        print("Did Update", self.props, self.state)
    end,
    willUnmount = function(self)
        print("Will Unmount", self.props, self.state)
    end,
}
```

## Incrementing Counter using Class Components

We can implement the counter example from previous sections using a class component!

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

local Upticker = Pract.classComponent {
    init = function(self)
        self:setState {
            time = 0
        }
        self.mounted = true
        task.spawn(function()
            repeat
                task.wait(1)

                self:setState{ time = self.state.time + 1 }
            until not self.mounted
        end)
    end,
    willUnmount = function(self)
        self.mounted = false
    end,
    render = function(self)
        return Pract.create(Clock, {
            time = self.state.time
        })
    end,
}

local PlayerGui = game.Players.LocalPlayer:WaitForChild('PlayerGui')
local handle = Pract.mount(Pract.create(Upticker), PlayerGui, "Clock UI")
```

#### Up Next: [Events and Symbolic Properties](eventssymbols)