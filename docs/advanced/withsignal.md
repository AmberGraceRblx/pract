---
layout: default
title: Updating Components with a Signal
nav_order: 4
parent: Advanced Guide
permalink: advanced/withsignal
---

# Pract.withSignal

So far, we've seen components/elements that update with props and state. However, there may be instances where it is better to update our elements once every frame, or every time a signal fires in general.

`Pract.withSignal` is a higher-order function that updates the wrapped component everytime props change, or the wrapped signal fires. Unlike other higher-order functions, `withSignal` directly takes a component in as an argument, rather than a closure creator that returns a component.

The following example takes our previous example using [Portals](./portals), and updates each HUD Marker every frame to match the position of an adornee!
```lua
local RunService = game:GetService('RunService')

-- This component creates a BasePart with a nametag BillboardGui when mounted, which redraws every
-- RenderStepped frame!
local HUDMarker = Pract.withSignal(
    RunService.RenderStepped,
    function(props: {adornee: BasePart, text: string})
        return Pract.stamp(script.MarkerPart, {
            CFrame = adornee.CFrame
        }, {
            BillboardGui = Pract.index {
                Nametag = Pract.decorate({
                    Text = props.text,
                })
            }
        })
    end
)

-- This component creates a portal that mounts its children to workspace instead of our GUI tree!
local function HUDMarkers(props: {})
    return Pract.portal(workspace, {
        Marker1 = Pract.create(HUDMarker, {
            adornee = workspace.SomeAdorneePart,
            text = "Now that's thinking with Portals!",
        })
    })
end

-- Our MainHUD is purely a ScreenGui tree, but ties our HUDMarkers visibility to its visibility!
local function MainHUD()
    return Pract.stamp(script.MainHUDTemplate, {
        -- ...
    }, {
        HUDMarkers = Pract.create(HUDMarkers)
    })
end
```

In this example, we could just set the adornee of our BillBoardGui to the `adornee` passed through props, rather than stamping a part that matches our Adornee's CFrame. There may be cases, however, in which you want to adjust HUD Markers which are ScreenGui objects instead of BillboardGui objects, and position them over our adornee. In those cases, it makes sense to update the component once per frame.

#### Up next: [Context Providers & Consumers](./contextproviders)