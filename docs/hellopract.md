---
layout: default
title: Hello, Pract!
nav_order: 2
permalink: /hellopract
---

# Hello, Pract!

> Note: These examples will assume you have [installed Pract](index) into `game.ReplicatedStorage`. If you have installed Pract elsewhere, please adjust any require statements in these examples to match where you have installed Pract!

Add a `LocalScript` in `game.StarterPlayer.StarterPlayerScripts`, in Roblox Studio or through Rojo, and paste the following code:
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

When you run a Roblox Studio playtest, you should see a text label on your screen with the text "Hello, Pract!"

![image](https://user-images.githubusercontent.com/93293456/139168972-49572640-604f-4781-a6f8-ba8ef98509ac.png)

Congratulations, you have mounted your first Pract element!

# Hello, Templates!

While the example above specifies how our UI is designed in the code itself, this can be re-written using templates, a feature of Pract which should make our code look even simpler, as well as giving you more flexibility to design how you want your UI to look!

Open up the `LocalScript` that you created, and replace the code from the above example with the following new code:
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

**NOTE:** Before you can run this code, you will need to have a correctly-formatted template named `HelloPractTemplate` parented to your `LocalScript`

Let's design our template:
1. Right click `game.StarterGui` and insert a `ScreenGui`. Name it `HelloPractTemplate` and set `ResetOnSpawn` to false 
![image](https://media.istockphoto.com/vectors/coming-soon-lettering-coming-soon-for-promotion-advertisement-sale-vector-id1221240925?k=20&m=1221240925&s=612x612&w=0&h=HX77CIwJ34u7qUMpI_W5z4dDnEbHGv66mGXVTpIccv8=)
2. Right click `HelloPractTemplate` and insert a `TextLabel`. Make sure it's named `HelloLabel` (with the correct spelling/capitalization). Edit properties like BackgroundTransparency, Font, FontSize, and TextColor3 in order to achieve the desired visual design.
![image](https://media.istockphoto.com/vectors/coming-soon-lettering-coming-soon-for-promotion-advertisement-sale-vector-id1221240925?k=20&m=1221240925&s=612x612&w=0&h=HX77CIwJ34u7qUMpI_W5z4dDnEbHGv66mGXVTpIccv8=)
3. Once we have finished designing our template, drag it into our `LocalScript` so that it is parented to our `LocalScript`
![image](https://media.istockphoto.com/vectors/coming-soon-lettering-coming-soon-for-promotion-advertisement-sale-vector-id1221240925?k=20&m=1221240925&s=612x612&w=0&h=HX77CIwJ34u7qUMpI_W5z4dDnEbHGv66mGXVTpIccv8=)

When you run a playtest, your template will be copied into your PlayerGui, with a slight modification to the HelloLabel showing a random number between 1 and 99.

![image](https://media.istockphoto.com/vectors/coming-soon-lettering-coming-soon-for-promotion-advertisement-sale-vector-id1221240925?k=20&m=1221240925&s=612x612&w=0&h=HX77CIwJ34u7qUMpI_W5z4dDnEbHGv66mGXVTpIccv8=)

You can modify properties of your template to change the look of the UI without having to edit any of the Pract code! Using templates allows your code to focus more on the functional parts of the UI, and less on the aesthetic parts, which can be separately from code.

In this section, we created three different types of "Elements," which are returned when calling the `Pract.create`, `Pract.stamp`, and `Pract.decorate` functions. The next section discusses what Elements really are, the difference between the basic types of Elements, and how they are used by the Pract engine to build our UI from code and templates.

#### Next Up: [Elements](elements)