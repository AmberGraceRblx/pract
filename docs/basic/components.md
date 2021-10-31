---
layout: default
title: Components
nav_order: 4
parent: Basic Guide
permalink: basic/components
---

# Components

In Pract, a Component is a function that takes in a table of variables (called _props_), and returns exactly one element. Usually a component represents some part of our UI that changes its appearance depending on the current state of our application.

Unlike Roact/React, all components in Pract are purely functional, meaning they must always be a function that takes in a `props` table and returns an Element. In later sections, we will see that the Pract library provides what are called _higher-order functions_, which supercharges a component and provides a richer, composition-based system for writing components.

## Greeting Component

```lua
local function Greeting(props: {name: string}): Pract.Element
    return Pract.create("TextLabel", {
        Text = "Hello, " .. props.name,
    })
end
```

The above component returns a Create Element for a TextLabel with a changing Text property depending on the `name` prop that is passed in.

To use our component, we can mount another Create Element that takes in our Component function itself as the first argument, rather than an instance ClassName:

```lua
local myElement = Pract.create(Greeting, {
    name = 'Brigitte Lindholm',
})
```

> Note that we are never directly calling our Greeting function! We are simply creating an element that tells Pract to call this function later on once we mount our element.

In this case, we are creating an element specified with our `Greeting` component, and telling it to create a more detailed component from just a name.

## Nested Components

In Pract applications, components are typically nested to form a scalable application with re-usable code! This mirrors the structure of React/Roact applications.

```lua
--!strict
local Pract = require(game.ReplicatedStorage.Pract)

local function Greeting(props: {name: string}): Pract.Element
    return Pract.create("TextLabel", {
        Text = "Hello, " .. props.name
    })
end

local function GreetEveryone(props: {}): Pract.Element
    return Pract.create("ScreenGui", {}, {
        Layout = Pract.create("UIListLayout"),

        HelloCole = Pract.create(Greeting, {
            name = "Cole Cassidy"
        }),

        HelloBones = Pract.create(Greeting, {
            name = "Bones Hillman"
        })
    })
end

-- Note that DefineOurApp is NOT a component because
--   a) It does not take in a props argument, and
--   b) We are directly calling DefineOurApp instead telling Pract to call it later on.
local function DefineOurApp()
    return Pract.create(GreetEveryone)
end

local myTree = Pract.mount(
    DefineOurApp(),
    game.Players.LocalPlayer:WaitForChild('PlayerGui'),
    'GreetingGui'
)
```

In the next section, we will finally cover the other types of Pract elements, which sets the library apart from Roact and allows you to write much more flexible and condensed UI code, as well as simplifying the UI design process.

#### Up Next: [Templating](templating)