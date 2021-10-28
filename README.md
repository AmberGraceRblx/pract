# Pract - A UI Engine for Roblox

> **Warning: Pract is currently in beta, and lacks any test coverage as it stands. Documentation is also still in development.**
> 
Pract is a **declarative** UI engine for Roblox.

Pract takes inspiration from Facebook's [React](https://reactjs.org/), and LPGHatGuy's [Roact](https://github.com/Roblox/roact), with an emphasis on providing **practical** features for bringing Roblox UI projects to life while still maintaining Roact's declarative code style.

# Core Concepts

## Virtual Tree
A virtual tree is at the core of Pract, and mirrors the structure of an instance tree. Pract uses this virtual tree to detect changes in the UI defined by your code, and compares these changes with the Roblox GUI instances that the tree is mounted on.

Example, from a LocalScript:
```lua
local helloPract = Pract.mount(
    Pract.create(
        'ScreenGui',
        {ResetOnSpawn = false},
        {
            HelloLabel = Pract.create(
                'TextLabel',
                 {
                    BackgroundTransparency = 1, Text='Hello, Pract!', TextSize=24,
                    Position = UDim2.fromScale(0.5,0.35), AnchorPoint = Vector2.new(0.5,0.5)
                },
                {}
            )
        }
    ),
    game.Players.LocalPlayer:WaitForChild('PlayerGui')
)
```
Instance created by Pract:
![image](https://user-images.githubusercontent.com/93293456/139168972-49572640-604f-4781-a6f8-ba8ef98509ac.png)

## Elements
Pract elements are descriptive instructions on how to build some GUI view.

### "Create" Elements
A "Create" element 
```lua

```
