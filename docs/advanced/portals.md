---
layout: default
title: Portals
nav_order: 3
parent: Advanced Guide
permalink: advanced/portals
---

# Pract.portal

Sometimes, our UI tree might have a reason not to look like a pure top-down instance heirarchy. A good example of this is having BillboardGuis tied to our HUD—we want these to appear and disappear based on whether or not our HUD is visible, but BillBoardGui objects need parts parented to `workspace` in order to function!

`Pract.portal` allow us to set an arbitrary _host instance_ for child elements to decorate or be parented to as the first argment. The second argument is a table of children.

```lua
-- This component creates a BasePart with a nametag BillboardGui when mounted.
local function HUDMarker(props: {position: Vector3, text: string})
    return Pract.stamp(script.MarkerPart, {
        CFrame = CFrame.new(props.position)
    }, {
        BillboardGui = Pract.index {
            Nametag = Pract.decorate({
                Text = props.text,
            })
        }
    })
end

-- This component creates a portal that mounts its children to workspace instead of our GUI tree!
local function HUDMarkers(props: {})
    return Pract.portal(workspace, {
        Marker1 = Pract.create(HUDMarker, {
            position = Vector3.new(0, 20, 0),
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

#### Up next: [Updating Components with a Signal](./withsignal)