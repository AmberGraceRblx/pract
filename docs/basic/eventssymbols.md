---
layout: default
title: Events and Symbols
nav_order: 8
parent: Basic Guide
permalink: basic/eventssymbols
---

# Events

In addition to changing an Instance's properties through props, `Pract.create`, `Pract.decorate`, and `Pract.stamp` will automatically connect/disconnect signals to listener functions specified through props. The first parameter passed through this function will always be the actual mounted instance:

```lua
local function ClickButton(props: {})
    return Pract.create('TextButton', {
        MouseButton1Click = function(rbx: TextButton)
            print("We clicked", rbx:GetFullName())
        end,
    })
end
```

If an event passes argument to its listeners, they will be appended after the `rbx` parameter:
```lua
local function HoverButton(props: {hoverBegan: () -> (), hoverEnded: () -> ()})
    return Pract.create('TextButton', {
        InputBegan = function(rbx: TextButton, input: InputObject)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                props.hoverBegan()
            end
        end,
        InputEnded = function(rbx: TextButton, input: InputObject)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                props.hoverEnded()
            end
        end,
    })
end
```

## Symbols

Pract provides special objects called **symbols** which allow you to change more in an instance than can be achieved with regular props alone.

## Prop value symbols

The `Pract.None` symbol specifies values we want Pract to set to nil. Because the key-value table provided in props does not allow `nil` to be stored as a value, we need to use `Pract.None` instead to tell Pract to set our property to `nil` for us.

```lua
local function MySurfaceGui(props: {adornee: Instance?})
    local adornee: any = props.adornee

    -- We cannot directly assign our adornee to nil through props, so we must use a symbol here!
    if adornee == nil then
        adornee = Pract.None
    end

    return Pract.create('SurfaceGui', {
        Adornee = adornee
    })
end
```

## Prop key symbols

### Setting Attributes

`Pract.Attributes` lets you specify a table of attributes to be set on the mounted instance via roblox's `instance:SetAttibute()` and `instance:GetAttribute()` api

```lua
local function FrameWithAttribute(props: {})
    return Pract.create('Frame', {
        [Pract.Attributes] = {
            SomeAttributeName = 'Some Attribute Value',
        }
    })
end
```

### Tagging your instances

`Pract.CollectionServiceTags` specifies a list of tags to be given to the mounted instance via roblox's `CollectionService:AddTag()` API. When unmounted, these tags will be removed from the instance.

```lua
local function FrameWithTags(props: {})
    return Pract.create('Frame', {
        [Pract.CollectionServiceTags] = {'ApplyColorScheme', 'Foo'}
    })
end
```

### GetAttributeChangedSignal/GetPropertyChangedSignal

`Pract.AttributeChangedSignals` and `Pract.PropertyChangedSignals` allows listening to certain events that can only be retrieved through the `instance:GetAttributeChangedSignal()` and `instance:GetPropertyChangedSignal()` methods

```lua
local function FrameWithAbsoluteSizeDetection(props: {})
    return Pract.create('Frame', {
        [Pract.PropertyChangedSignals] = {
            AbsoluteSize = function(rbx: Frame)
                print("The absolute size of", rbx:GetFullName(), "changed!")
            end,
        }
    })
end
```

## Lifecycle event symbols

Pract provides the following special symbols for lifecycle events with instance-based elements: `Pract.OnMountWithHost`, `Pract.OnUpdateWithHost`, `Pract.OnUnmountWithHost`. These are called in deferred time, and expose the `rbx` parameter like normal events. They can be used to apply tween effects:

```lua
local function TweeningFrameOnMount(props: {})
    return Pract.create('Frame', {
        [Pract.OnMountWithHost] = function(rbx: Frame)
            -- Note: It is usually not recommended that you directly set an instance's properties
            -- through events, and handle it through Pract props instead. In the case of tweens
            -- though, it is better that we directly set these properties here so that the tween
            -- takes care of these changes, rather than being managed by Pract in any way.
            rbx.Position = UDim2.fromScale(0, 0)
            rbx.AnchorPoint = Vector2.new(0, 0)

            local tween = game:GetService('TweenService'):Create(
                rbx,
                TweenInfo.new(10),
                {
                    Position = UDim2.fromScale(1, 1)
                    AnchorPoint = Vector2.new(1, 1)
                }
            )
            tween:Play()
        end,
    })
end
```

#### Up next: Advanced guide (coming soon)
    - Combining elements
    - Portals
    - Updating with a signal
    - Using external state
    - Context providers/consumers