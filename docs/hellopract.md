---
layout: default
title: Hello, Pract!
nav_order: 2
permalink: /hellopract
---

# Hello, Pract!

> Note: These examples will assume you have [installed Pract](index.md) into `game.ReplicatedStorage`. If you have installed Pract elsewhere, please adjust any require statements in these examples to match where you have installed Pract!

Add a `LocalScript` in `game.StarterPlayer.StarterPlayerScripts`, in Roblox Studio or through Rojo:
```lua
--!strict
local Pract = require(game.ReplicatedStorage.Pract)
local PlayerGui = game.Players.LocalPlayer:WaitForChild('PlayerGui')

local element = Pract.create('ScreenGui', {ResetOnSpawn = false}, {
    HelloLabel = Pract.create('TextLabel', {
        Text = 'Hello, Pract!', TextSize = 24, BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.35), AnchorPoint = Vector2.new(0.5, 0.5)
    })
})

Pract.mount(element, PlayerGui)
```
When you run the game, you should see a text label on your screen with the text "Hello, Pract!"
![image](https://user-images.githubusercontent.com/93293456/139168972-49572640-604f-4781-a6f8-ba8ef98509ac.png)

# Hello, Templates!

While the example above specifies how your UI is designed in the code itself, let's re-write this example to use templates, a feature of Pract which should make our code look even simpler, as well as giving you more flexibility to design how you want your UI to look!

Open up the LocalScript that you created, and replace the code from the above example with the following new code:
```lua
--!strict
local Pract = require(game.ReplicatedStorage.Pract)
local PlayerGui = game.Players.LocalPlayer:WaitForChild('PlayerGui')

local myLuckyNumber = math.random(1, 99)

local element = Pract.stamp(script.HelloPractTemplate, {}, {
    HelloLabel = Pract.decorate({Text = string.format('Your lucky number is %d', myLuckyNumber)})
})

Pract.mount(element, PlayerGui)
```

**NOTE:** Before you run this code, you will first need to actually create the template, and name parts of the template correctively (case-sensitive!)

Design your template in `game.StarterGui` through roblox's UI editor. When you're done, make sure the template is a ScreenGui named "HelloPractTemplate", and it has a TextLabel under it named "HelloLabel". Finally, make sure this templated is parented to your LocalScript.

> (Picture coming soon when roblox isn't down)

When you run a playtest, your template will be copied into your PlayerGui, with a slight modification showing a random number between 1 and 99.

> (Picture coming soon when roblox isn't down)

#### Next Up: [Elements](elements.md)