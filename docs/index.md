---
layout: default
title: Getting Started
nav_order: 1
permalink: /
---

# Introduction to Pract


Pract is a **declarative** UI engine for Roblox, written in Roblox's [Luau](https://luau-lang.org/)

Pract takes inspiration from Facebook's [React](https://reactjs.org/) and LPGHatGuy's [Roact](https://github.com/Roblox/roact), with an emphasis on providing **practical** features for bringing Roblox UI projects to life while still maintaining Roact's declarative code style.

Pract allows you to design your UI entirely in code, use a template designed in roblox's UI editor, or a mix of both. This documentation will show usage examples and detail how to effectively design your own UI code with the library's features.

## Getting Started

You can install Pract using one of the following methods:


### Method 1: Inserting Pract directly into your place
1. Download [the latest rbxm release on Github](https://github.com/ambers-careware/pract/releases/)
2. Right click the object in the Roblox Studio Explorer that you want to insert Pract into (such as ReplicatedStorage) and select `Insert from File...`
3. Locate the rbxm file that you downloaded and click `Open`


### Method 2: Syncing via Rojo
1. Install [Rojo](https://rojo.space/) and initialize your game as a Rojo project if you have not already done so
2. [Download the Pract repository](https://github.com/ambers-careware/pract/archive/refs/heads/main.zip)
3. Extract the `Pract` folder from the repository into a location of your choosing within your Rojo project's source folder (e.g. `src/shared`)
4. Sync your project using Rojo


#### Up Next: [Hello, Pract!](hellopract)