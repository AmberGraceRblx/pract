---
layout: default
title: Templating
nav_order: 5
parent: Basic Guide
permalink: basic/templating
---

# Templating

In the [Hello, Pract example](hellopract), we saw two different methods of designing our UI with code:
1. Use `Pract.create` to design our entire UI tree in code, from scratch
2. Design our UI using templates in Roblox's UI editor, and only write code for the essential parts using `Pract.decorate` and `Pract.stamp` elements.

In this section, we will cover ways to effectively use templating in order to write more concise and flexible Pract code.

## Storing your templates

Templates are instances that can be stored anywhere in roblox's instance tree. It is a good idea to store templates in a consistent location in your project. There are many ways you can organize, and there's no such thing as a right or wrong way to do this!

If you are using Roblox Studio's script editor to write all of your code, you may want to store your templates directly under the `ModuleScripts` that use them. If you are using Rojo to sync your code from a folder of `.lua` files, you may want to organize all of your templates in one location (in ReplicatedStorage, StarterPlayer, or even StarterGui, for example).

However you choose to organize your templates, just make sure you are providing a valid path to these templates in your code. In the following examples, they will assume you placed your templates directly under the `LocalScript`/`ModuleScript` that uses these templates.

## Stamp Elements

Stamp Elements work similarly to Create Elements, except that instead of creating a new instance using `Instance.new` when mounted, a Stamp component will call `instance:Clone()` on the template passed into it when it is mounted, and will be destroyed when unmounted.

```lua
local function FancyGreetingCard(props: {name: string})
    return Pract.stamp(script.GreetingCardTemplate, {
        Text = 'Hello, ' .. props.name
    })
end
```

You can also pass in a third children argument to create instances directly under your cloned instance
```lua
local function GreetEveryone(props: {}): Pract.Element
    return Pract.stamp(script.GreetingListTemplate, {}, {
            -- In the previous section, we created a layout through Pract:
            -- Layout = Pract.create("UIListLayout"),
            -- Now we can just include this as part of our template!
        HelloCole = Pract.create(FancyGreetingCard, {
            name = "Cole Cassidy"
        }),
        HelloTorb = Pract.create(FancyGreetingCard, {
            name = "Torbjörn Lindholm"
        })
    })
end
```

Stamped instances will be parented to their _host instance_ and automatically named to their _host child name_

## Decorate Elements

In the example of our "FancyGreetingCard" component, what if we wanted to have our greeting card itself be a `Frame` with a `TextLabel` nested inside of it? In this case, we could create a template with the TextLabel omitted, and then create another template for the TextLabel:

```lua
local function FancyGreetingCard(props: {name: string})
    return Pract.stamp(script.GreetingCardTemplate, {}, {
        GreetingLabel = Pract.stamp(script.GreetingLabelTemplate, {
            Text = 'Hello, ' .. props.name
        })
    })
end
```

However, this can get unweildly the more sub-components of our template we need to have. Instead, we can place this GreetingLabel directly inside of our GreetingCardTemplate and simply use a Decorate component to modify the pre-existing label:

```lua
local function FancyGreetingCard(props: {name: string})
    return Pract.stamp(script.GreetingCardTemplate, {}, {
        GreetingLabel = Pract.decorate({
            Text = 'Hello, ' .. props.name
        })
    })
end
```

Decorate can also take in a second argument for children elements:
```lua
local function FancyGreetingCard(props: {name: string})
    local text = 'Hello, ' .. props.name
    return Pract.stamp(script.GreetingCardTemplate, {}, {
        GreetingLabel = Pract.decorate({
            Text = text,
        }, {
            Shadow = Pract.decorate({
                Text = text,
            })
        })
    })
end
```

## Index Elements

Finally, if you want have a template that you need to index the children of, but don't actually need to change any of the properties, `Pract.index` takes in a single children argument.

```lua
local function FancyGreetingCard(props: {name: string})
    return Pract.stamp(script.GreetingCardTemplate, {}, {
        CenteringFrame = Pract.index({
            GreetingLabel = Pract.decorate({
                Text = 'Hello, ' .. props.name
            })
        })
    })
end
```

## Host Context

An important concept before we proceed is the idea of "host context."
A host context is essentially the circumstances in which a Pract element is mounted. A Pract element on its own can specify many of its own properties **except** for its own `Name` and `Parent`. These properties must be determined by code outside of the element itself.

Whenever you mount a root element, you may (but don't always have to) specify a **host instance** and **host child name**.

When a Stamp or Create Element is nested inside of another Element, the instance generated by the parent element becomes the **host instance** of its children, and the keys provided in the child table become the **host child names** if its children.

> Note: While `Pract.create` and `Pract.stamp` elements create/destroy an instance which is named after the **host child name** and parented to the **host instance**, `Pract.decorate` and `Pract.index` elements behave differently. If a **host child name** is specified, `Pract.decorate` and `Pract.index` will search their **host instance** for an existing child with the **host child name**. If no **host child name** is specified, they will simply index or decorate the **host instance** itself! If no **host instance** is specified, they will raise an error when mounted.

#### Up Next: [State](state)