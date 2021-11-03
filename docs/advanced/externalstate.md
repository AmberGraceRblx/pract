---
layout: default
title: Using Pract With Third-Party Systems
nav_order: 6
parent: Advanced Guide
permalink: advanced/externalstate
---

# State management

[State management](https://en.wikipedia.org/wiki/State_management) is the art of efficiently displaying your project's different state variables as UI without any errors or incorrect/outdated information being displayed to the user.

An example of state is how many coins a player has. This could be stored in a singleton "PlayerData" module, as Attributes, or through any other system in your project. In order for Pract to display accurate information, connecting components to a single source of truth for state is ideal.

# Connecting external state

Pract's [Higher-Order Functions](../api/hofs) provide a rich, composition-based way of updating our components whenever we wish to do so. Because of this, Pract is flexible and can adapt to nearly any external state-based system.

## Connecting Attribute-based external state

Let's look at a way we can link a "CoinsDisplay" component to our project's "Coins" state through attributes.

```lua
-- This component is not connected to any state, and purely defines the visuals of our coins display
local function CoinsDisplay(props: {coins: number})
    return Pract.stamp(script.CoinsDisplayTemplate, {

    }, {
        CoinsLabel = Pract.decorate({
            Text = string.format('Coins: %d', props.coins)
        })
    })
end

-- This component links our CoinsDisplay to a player's "Coins" attribute, and updates it every time
-- the attribute changes
type Props = {player: Player}
local LinkedCoinsDisplay = function(props: Props)
	return Pract.create(
		Pract.withSignal(
			props.player:GetAttributeChangedSignal('Coins'),
			function(props: Props)
                return Pract.create(CoinsDisplay, {
                    coins = props.player:GetAttribute('Coins')
                })
            end
		),
		props
	)
end

local function App(props: {})
    return Pract.create(LinkedCoinsDisplay, {
        player = game.Players.LocalPlayer
    })
end
```

You could make a generalized higher-order function that links Attribute state to another component:
```lua
-- This function is a long utility, but it can be re-used in many scenarios!
local function connectAttributes(
        -- This is the component whose props should derive from an arbitrary instance's Attributes
    wrappedComponent: Pract.Component,
        -- This determines the instance we will listen to when mounted, based on the props provided.
    getInstanceFromProps: (props: any) -> Instance,
        -- This determines which attributes will force an update in our wrappedComponent
    attributesToConnect: {string},
        -- This determines our wrappedComponent's props
    mapAttributesToProps: (attributes: {[string]: any}, props: any) -> any
): Pract.Component
    return Pract.withLifecycle(function(forceUpdate)
        local conns = {}
        local function connectInstance(instance: Instance)
            for i = 1, #attributesToConnect do
                table.insert(
                    conns,
                    instance:GetAttributeChangedSignal(
                        attributesToConnect[i]
                    ):Connect(forceUpdate)
                )
            end
        end
        local function disconnectCurrentInstance()
            for i = 1, #conns do
                conns[i]:Disconnect()
            end
            conns = {}
        end

        local currentInstance
        return {
            init = function(props: Pract.PropsArgument)
                currentInstance = getInstanceFromProps(props)
                connectInstance(currentInstance)
            end,
            render = function(props: Pract.PropsArgument)
                -- If the props have changed the instance we are tracking, then we should disconnect
                -- our current listeners and re-connect new ones.
                local nextInstance = getInstanceFromProps(props)
                if nextInstance ~= currentInstance then
                    disconnectCurrentInstance()
                    connectInstance(nextInstance)

                    currentInstance = nextInstance
                end
                return Pract.create(
                    wrappedComponent,
                    mapAttributesToProps(currentInstance:GetAttributes(), props)
                )
            end,
            willUnmount = function()
                disconnectCurrentInstance()
            end,
        }
    end)
end
```
```lua
-- The following code is equivalent to the last example, using our generalized utility.
type LinkedCoinsDisplayProps = {player: Player}
local LinkedCoinsDisplay = connectAttributes(
    CoinsDisplay,
    function(props: LinkedCoinsDisplayProps) return props.player end,
    {'Coins'},
    function(playerAttributes, otherProps: LinkedCoinsDisplayProps)
        -- Get the props to pass to our CoinsDisplay component from the passed Player's attributes
        return {
            coins = playerAttributes.Coins,
        }
    end
)

local function App(props: {})
    return Pract.create(LinkedCoinsDisplay, {
        player = game.Players.LocalPlayer
    })
end
```

In general, it may be useful to create a generalized higher-order function that tailors Pract to work with your project's state or data systems.

# Using Pract to manage state

In the [previous example](./contextproviders), we saw the use of `Pract.withContextProvider` to provide state all the way from a root component to a descendant component.

It may be ideal to not use external state at all, and use Pract's constructs to handle any UI-based state instead.

This depends on the needs of your project.

## Using Pract with Rodux

LPGHatGuy's [Rodux](https://github.com/Roblox/rodux) is a roblox-endorsed state management library that is tailored to work with Roact.

While there is no official Pract-Rodux library yet (if someone creates one, please make an [issue on github](https://github.com/ambers-careware/pract/issues) to add it to the official documentation here!), it should be easy to create one using Pract's higher-order functions.

Just like React-Redux uses React's context provider/consumer features, you could create similar components and connectors using `Pract.withContextProvider`, `Pract.withContextConsumer`, and `Pract.withLifecycle` to force updates (which would be automatically throttled to once per frame in Pract rather than needing to be throttled by Rodux itself) every time state changes in the Rodux store.

## Using Pract with a state singleton module

Another way state can be organized in a project is by having singleton modules which store this state and fire BindableEvents when the state changes:

```lua
--!strict
local CoinsState = {}

local CHANGED_EVENT = Instance.new('BindableEvent')

local playerToCoins = {} :: {[Player]: number}
function CoinsState.Get(player: Player): number
    return playerToCoins[player]
end

function CoinsState.Set(player: Player, coins: number)
    playerToCoins[player] = coins
    CHANGED_EVENT:Fire(player)
end

CoinsState.Changed = CHANGED_EVENT.Event

return MyState
```

Pract can easily connect components to state module singletons like this:
```lua
-- This HOF could potentially be returned by our CoinsState module itself for convenience!
local function connectToCoinsState(
    wrappedComponent: Pract.Component,
    -- This gets the player that we should listen to the coins state for from the returned
    -- component's props
    getPlayerFromProps: (props: any) -> Player,
    getPropsFromCoins: (coins: number, otherProps: any) -> any
): Pract.Component
    return Pract.withLifecycle(function(forceUpdate)
        local connection
        local lastPlayer
        return {
            init = function(props: Pract.PropsArgument)
                lastPlayer = getPlayerFromProps(props)
                connection = CoinsState.Changed:Connect(function(player)
                    if player == lastPlayer then
                        forceUpdate()
                    end
                end)
            end,
            render = function(props: Pract.PropsArgument)
                lastPlayer = getPlayerFromProps(props)
                return Pract.create(
                    wrappedComponent,
                    getPropsFromCoins(CoinsState.Get(lastPlayer), props)
                )
            end,
            willUnmount = function()
                connection:Disconnect()
            end,
        }
    end)
end
```
```lua
type LinkedCoinsDisplayProps = {player: Player}
local LinkedCoinsDisplay = connectToCoinsState(
    CoinsDisplay,
    function(props: LinkedCoinsDisplayProps) return props.player end,
    function(coins: number, otherProps: LinkedCoinsDisplayProps)
        -- Get the props to pass to our CoinsDisplay component from the CoinsState data
        return {
            coins = coins,
        }
    end
)

local function App(props: {})
    return Pract.create(LinkedCoinsDisplay, {
        player = game.Players.LocalPlayer
    })
end
```

## Other ways to connect Pract components with third-party state

As long as your custom state system has a way to detect changes in state, you can always use `Pract.withLifecycle` to force an update on a wrapped component when this change happens, and use the `willUnmount` lifecycle hook to clean up any listeners when the linked Pract component unmounts.

Try to avoid repeating yourself, and make your own helper higher-order functions or components to connect your third-party state with Pract. That way, using external state can be just as easy as using a pre-made utlilty with your Pract component!

#### Up Next: ???

You've reached the end of the Pract documentation.
Much of this documentation is a first draft, and may be subject to change in the future. Collaborators would be appreciated in improving the documentation and functionality of the Pract library in general!