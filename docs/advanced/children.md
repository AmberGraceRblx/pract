---
layout: default
title: Using Pract.Children in Components
nav_order: 2
parent: Advanced Guide
permalink: advanced/children
---

# Pract.Children

All of the basic [Element Creator](../api/elements) functions take in an optional children argument, which will mount the child elements on their parent element's created or decorated instance.

It is also possible to provide a children argument to components when we create them—however, we need to explicitly handle children props in order to do so! To do so, we can access the `Pract.Children` key in our passed-in props:

```lua
local function FancyList(props: {[any]: any, heading: string]})
    -- Get our children passed in through props (note that this can be nil!)
    local passedInChildren = props[Pract.Children] or {}

    return Pract.stamp(script.ListTemplate, {}, {
        -- Decorate a "Heading" label in our template
        Heading = Pract.decorate({
            Text = props.heading,
        }),
        -- Dump our passed-in children into a frame named "List", inside our stamped template
        List = Pract.index(passedInChildren)
    })
end
local function App(props: {})
    return Pract.create(FancyList, {
        heading = 'List of Things'
    }, { -- These are assigned to the [Pract.Children] key of our props:
        [1] = Pract.create('TextLabel', {
            Text = 'Apples',
        }),
        [2] = Pract.create('TextLabel', {
            Text = 'Builderman is my dad',
        }),
    })
end
```

See the [API Docs](../api/symbols#practchildren) for a more technical documentation of the `Pract.Children` symbol.

#### Up next: [Portals](./portals)