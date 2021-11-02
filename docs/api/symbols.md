---
layout: default
title: Symbols
nav_order: 3
parent: API Reference
permalink: /api/symbols
---

# Pract Symbols

> Warning: API Documentation is still a work in progress, and Pract's feature set has not yet been finalized.

See: [Events and Symbols](../basic/eventssymbols) for a more in-depth guide on how to use the basic Pract symbols

## Pract.None

Represents a value that should be assigned to "nil" on a modified Instance, since Pract cannot read the literal value `nil` as a table value in props.

## Pract.Attributes

Can be used as a key in the props of an Instance-modifying element. Will assign/modify/remove attributes on this instance via `instance:SetAttribute()`. The value specified in props should be typed as `{[string]: any}`, or a dictionary with string keys (the attribute names) and attribute-compatible values.

Example:
```lua
local function FrameWithAttribute(props: {})
    return Pract.create('Frame', {
        [Pract.Attributes] = {
            SomeAttributeName = 'Some Attribute Value',
        }
    })
end
```

For `Pract.decorate` and `Pract.index` elements, these attributes will be removed when unmounted. For `Pract.create` and `Pract.stamp`, they will not be removed since the instances will be destroyed by Pract regardless.

## Pract.CollectionServiceTags

Can be used as a key in the props of an Instance-modifying element. Will assign/modify/remove tags on this instance via `CollectionService:AddTag` and `CollectionService:RemoveTag`. The value 

For `Pract.decorate` and `Pract.index` elements, these tags will be removed when unmounted. For `Pract.create` and `Pract.stamp`, they will not be removed since the instances will be destroyed by Pract regardless. The value specified in props should be typed as `{string}`, or an array of strings.

Example:
```lua
local function FrameWithTags(props: {})
    return Pract.create('Frame', {
        [Pract.CollectionServiceTags] = {'ApplyColorScheme', 'Foo'}
    })
end
```

## Pract.Children

Can be used as a key in the props for any element type that accepts props. The value in props should be typed as `Pract.ChildrenArgument`, or `{[any]: Element | boolean | nil}`. The keys of this table will be converted to a string via `tostring` and used as the [host child name](../basic/templatingelements#host-context) of the element at the corresponding value.

Any `boolean` or `nil` typed elements in the children table will be ignored. This allows for the following kinds of conditional expressions to be used:
```lua
local function ConditionalChild(props: {isGlowing: boolean})
    return Pract.stamp(script.CardTemplate, {
        [Pract.Children] = {
            Glow = props.isGlowing and Pract.stamp(script.GlowTemplate)
                -- If this condition evaluates to false, we ignore this child.
        }
    })
end
```

Please note that if you provide a `children` argument to `Pract.create`, `Pract.decorate`, or `Pract.stamp`, the argument provided will overwrite the `Pract.Children` key specified in props.

## Pract.AttributeChangedSignals

Can be used as a key in the props of an Instance-modifying element. Will connect listeners to an event retrieved via `instance:GetAttributeChangedSignal()`. The value in props should be typed as `{[string]: (rbx: any) -> ()}`, or a dictionary with the attribute names as keys, and the event listeners themselves as values.

Example:
```lua
local function FrameWithAttributeDetection(props: {})
    return Pract.create('Frame', {
        [Pract.AttributeChangedSignals] = {
            Foo = function(rbx: Frame)
                print("The attribute 'Foo' of", rbx:GetFullName(), "changed!")
            end,
        }
    })
end
```

## Pract.PropertyChangedSignals

Can be used as a key in the props of an Instance-modifying element. Will connect listeners to an event retrieved via `instance:GetPropertyChangedSignal()`. The value in props should be typed as `{[string]: (rbx: any) -> ()}`, or a dictionary with the property names as keys, and the event listeners themselves as values.

Example:
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
## Pract.OnMountWithHost

Can be used as a key in the props of an Instance-modifying element. Will fire the listener when the element is mounted in a defered thread. The value in props should be typed as `(rbx: any, props: any, setOnCleanup: (cleanupCallback: () -> ()) -> ()) -> ()`

Example:
```lua
type Props = {}
local function TweeningFrameOnMount(props: Props)
    return Pract.create('Frame', {
        [Pract.OnMountWithHost] = function(
            rbx: Frame,
            props: Props,
            setOnCleanup: (
                cleanupCallback: () -> ()
            ) -> ()
        )
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

            -- We can stop and reset our tween if the component is unmounted while it tweening
            setOnCleanup(function()
                tween:Stop()
            end)
        end,
    })
end
```

## Pract.OnUpdateWithHost

Can be used as a key in the props of an Instance-modifying element. Will fire the listener when the element is updated in a defered thread. The value in props should be typed as `(rbx: any, props: any) -> ()`

Example:
```lua
type Props = {}
local function PrintsOnUpdate(props: Props)
    return Pract.create('Frame', {
        [Pract.OnUpdateWithHost] = function(rbx: Frame, props: Props)
            print("The component managing", rbx:GetFullName(), "has updated!")
        end,
    })
end
```

## Pract.OnUnmountWithHost

Can be used as a key in the props of an Instance-modifying element. Will fire the listener when the element is unmounted in a defered thread. The value in props should be typed as `(rbx: any) -> ()`

```lua
type Props = {}
local function PrintsOnUpdate(props: Props)
    return Pract.create('Frame', {
        [Pract.OnUnmountWithHost] = function(rbx: Frame)
            print("The component managing", rbx:GetFullName(), "was unmounted!")
        end,
    })
end
```
