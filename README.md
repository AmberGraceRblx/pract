# Pract - A UI Engine for Roblox

Pract is a **declarative** UI engine for Roblox, written in Roblox's [Luau](https://luau-lang.org/)

Pract takes inspiration from Facebook's [React](https://reactjs.org/) and LPGHatGuy's [Roact](https://github.com/Roblox/roact), with an emphasis on providing **practical** features for bringing Roblox UI projects to life while still maintaining Roact's declarative code style.

Pract allows you to design your UI entirely in code, use a template designed in roblox's UI editor, or a mix of both.

# [Documentation](https://ambergracerblx.github.io/pract)

See the [full Pract documentation](https://ambergracerblx.github.io/pract) for a detailed guide on how to use Pract, with examples.

Basic usage example:
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
Alternative form (using a cloned template):
```lua
--!strict
local Pract = require(game.ReplicatedStorage.Pract)

local PlayerGui = game.Players.LocalPlayer:WaitForChild('PlayerGui')

-- Create our virtual GUI elements from a cloned template under this script
local element = Pract.stamp(script.MyGuiTemplate, {}, {
    HelloLabel = Pract.decorate({Text = 'Hello, Pract!'})
})

-- Mount our virtual GUI elements into real instances, parented to PlayerGui
local virtualTree = Pract.mount(element, PlayerGui)
```
Both examples can generate the same instances:
![image](https://user-images.githubusercontent.com/93293456/139168972-49572640-604f-4781-a6f8-ba8ef98509ac.png)

# Installation

You can install Pract using one of the following methods:

## Method 1: Inserting Pract directly into your place
1. Download [the latest rbxm release on Github](https://github.com/ambers-careware/pract/releases/)
2. Right click the object in the Roblox Studio Explorer that you want to insert Pract into (such as ReplicatedStorage) and select `Insert from File...`
3. Locate the rbxm file that you downloaded and click `Open`


## Method 2: Syncing via Rojo
1. Install [Rojo](https://rojo.space/) and initialize your game as a Rojo project if you have not already done so
1. Download [the latest Source Code release (zip file) on Github](https://github.com/ambers-careware/pract/releases/)
3. Extract the `Pract` folder from the repository into a location of your choosing within your Rojo project's source folder (e.g. `src/shared`)
4. Sync your project using Rojo

# Contributing

If Pract eventually reaches a point of widespread use, I certainly would not want to maintain the library on my own! Feel free to fork/branch this repository and create [pull requests](https://github.com/ambers-careware/pract/pulls) for anything you wish to change with this library, as well as using [github's issues page](https://github.com/ambers-careware/pract/issues).

I would also appreciate if anyone wanted to help set up a discord for me. This depends on how widely used this library actually becomes on release; I don't think I can really do it all on my own, nor make maintaining Pract my sole focus on life, so having more people involved in the continued development and publicizing of this library would be appreciated!

I believe Roact (similarly, Elttob's [Fusion](https://elttob.github.io/Fusion/)) as a library is a great concept, but can be impractical and antithetical to Roblox's UI design workflow for many users. My hope is that I can incorporate the features/use cases of Roact into Pract, such that Pract acts as a superset to Roact and a compelling alternative. Because Roact does not have features that support templating as part of the framework, many people turn to other methods of designing their UI projects. My hope with Pract is to have those people reconsider a using a React-like library in their project.
