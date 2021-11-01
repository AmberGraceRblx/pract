---
layout: default
title: "\"Create\" Elements"
nav_order: 3
parent: Basic Guide
permalink: basic/instancingelements
---

# What are Elements?

_Elements_ are at the core of Pract code, and serve a similar purpose to React/[Roact](https://roblox.github.io/roact/guide/elements/) elements. In Pract, however, there are many types of elements, which can be used not just for creating new instances, but also for using pre-designed UI as a template.

Elements are like a blueprint given to the Pract engine, telling Pract in detail what the relevant parts of your UI should look like. When a Pract element is _mounted_ to a host, Pract will convert these elements into actual Gui instances as efficiently as possible.

## Mounting a "Create" Element

```lua
local myElement = Pract.create("TextLabel", {
    Text = "Hello, Elements!",
})
```

A "Create" element will automatically create a new Instance using Roblox's `Instance.new` method when mounted. These new instances will retain all of the default properties on the object returned by `Instance.new` unless specified otherwise.

The first argument is the ClassName of the instance we want to create, and the second argument is a table of properties we want to assign to the instance.

We can also pass a third argument to specify the child instances we want to create.

```lua
local myElement = Pract.create("TextLabel", {
    Text = "Hello, Elements!",
}, {
    MyChild = Pract.create("UIScale", {
        Scale = 2,
    }),
})
```

This keys of this child table will automatically determine the name of the instance that is created.

To create the Gui instances themselves, we first need to mount them to a *host*. To mount a component, we can specify a *host instance* and *host child name* using the `Pract.mount` method.

```lua
local myHandle = Pract.mount(myElement, workspace, "Waffles")
```

The _host instance_ is the instance that our newly-created instances will be parented to. The _host key_ is the default name that our created instances will be renamed to when they are mounted.

`Pract.mount` returns a handle that can be used to update or destroy our created instances using `Pract.update` and `Pract.mount`.

## Updating our Gui

To change the UI that was created by Pract, our handle needs to be updated with new Elements. Pract will compare the first element that we mounted with the next element we mounted and create/destroy/modify the necessary instances to match our new elements.

```lua
local nextElement = Pract.create("TextLabel", {
    Text = "Hello, Updates!",
}, {
    MyChild = Pract.create("UIScale", {
        Scale = 3,
    })
})
```

To update our instances, call `Pract.update` on our handle with the new element tree as the second argument.

```lua
Pract.update(myHandle, nextElement)
```

## Destroying our Gui

The `Pract.unmount` method will destroy any instances created by Pract under our handle, and automatically clean up everything for you.
```lua
Pract.unmount(myHandle)
```

# Incrementing Counter Example

The example given in Roact's guide can just easily be implemented in Pract without changing much of the code at all! Much of Roact's code can ostensibly be converted to Pract code, although there are very important differences between the two libraries that will be seen later on.

The following code assumes you have Pract installed under `game.ReplicatedStorage`, and the code is run somewhere from a `LocalScript`:

```lua
--!strict
local Pract = require(game.ReplicatedStorage.Pract)

-- Create a function that creates the elements for our UI.
-- Later, we'll use components, which are the best way to organize UI in Roact.
local function clock(currentTime: number)
    return Pract.create("ScreenGui", {}, {
        TimeLabel = Pract.create("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            Text = "Time Elapsed: " .. currentTime
        })
    })
end

local PlayerGui = game.Players.LocalPlayer:WaitForChild('PlayerGui')

-- Create our initial UI, with a host instance of PlayerGui and a host child name of "Clock UI"
local currentTime = 0
local handle = Pract.mount(clock(currentTime), PlayerGui, "Clock UI")

-- Every second, update the UI to show our new time.
while true do
    task.wait(1)

    currentTime = currentTime + 1
    handle = Pract.update(handle, clock(currentTime))
end
```

The next section will cover _Components_, which are an ideal method provided by the Pract library for composing, re-using, and organizing UI design.

#### Up Next: [Components](components)