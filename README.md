# Pract - A UI Engine for Roblox

> **Warning: Pract is currently in beta, and lacks any test coverage as it stands. Documentation is also still in development.**
> 
Pract is a **declarative** UI engine for Roblox.

Pract takes inspiration from Facebook's [React](https://reactjs.org/), and LPGHatGuy's [Roact](https://github.com/Roblox/roact), with an emphasis on providing **practical** features for bringing Roblox UI projects to life while still maintaining Roact's declarative code style.

Unlike Roact, Pract provides constructs for cloning or modifying existing GuiObject templates, rather than having to generate the entire UI from scratch. This means you can design your UI in roblox's UI editor and make certain modifications without having to adjust the Pract code!

# [Documentation](https://ambers-careware.github.io/pract)

See the [full Pract documentation](https://ambers-careware.github.io/pract) for a detailed guide on how to use Pract, with examples.

```lua
--!strict
local Pract = require(game.ReplicatedStorage.Pract)

local PlayerGui = game.Players.LocalPlayer:WaitForChild('PlayerGui')

-- Create our virtual GUI elements
local element = Pract.create('ScreenGui', {ResetOnSpawn = false}, {
    HelloLabel = Pract.create('TextLabel', {
        Text = 'Hello, Pract!', TextSize = 24, BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.35), AnchorPoint = Vector2.new(0.5, 0.5)
    })
})

-- Mount our virtual GUI elements into real instances, parented to PlayerGui
local virtualTree = Pract.mount(element, PlayerGui)
```

![image](https://user-images.githubusercontent.com/93293456/139168972-49572640-604f-4781-a6f8-ba8ef98509ac.png)
