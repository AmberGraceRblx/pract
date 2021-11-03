---
layout: default
title: Context Providers & Consumers
nav_order: 5
parent: Advanced Guide
permalink: advanced/contextproviders
---

# Pract.withContextProvider

With Pract's heirarchical structure lets you pass callbacks up and down a tree, allowing for a scalable, holostic UI design.
However, there may be cases in which this heirarchy becomes unwieldy:

```lua
local MainHUD = require(game.ReplicatedStorage.Contexts.MainHUD)
local Menu1 = require(game.ReplicatedStorage.Contexts.Menu1)
local Menu2 = require(game.ReplicatedStorage.Contexts.Menu2)
local Menu3 = require(game.ReplicatedStorage.Contexts.Menu3)

local ContextSelector = Pract.withDeferredState(function(getContext, setContext)
    -- Set our default context to "MainHUD"
    setContext('MainHUD')
    return function(props: {})
        local currentContext = Pract.combine() -- Empty element if no context is selected
        if getContext() == 'MainHUD' then
            return Pract.create(MainHUD, {
                menuButtonClicked = function(menuName: string)
                    setContext(menuName)
                end
            })
        elseif getContext() == 'Menu1' then
            return Pract.create(Menu1, {
                exitButtonClicked = function()
                    setContext('MainHUD')
                end
            })
        elseif getContext() == 'Menu2' then
            return Pract.create(Menu2, {
                exitButtonClicked = function()
                    setContext('MainHUD')
                end
            })
        elseif getContext() == 'Menu3' then
            return Pract.create(Menu3, {
                exitButtonClicked = function()
                    setContext('MainHUD')
                end
            })
        end

        return Pract.index {
            Contexts = Pract.index {
                -- Create our context-named element based on the value of our state
                [getContext()] = currentContext
            }
        }
    end
end)
local function App(props: {})
    return Pract.index {
        -- Mount our app on AppGui when it's copied from StarterGui
        AppGui = Pract.create(ContextSelector)
    }
end
Pract.Mount(App, game.Players.LocalPlayer:WaitForChild('PlayerGui'))
```

While conditionally switching our context in this pattern may be a necessary evil, notice how each of our menus has to specify a callback for when any navigation button is clicked (such as an "exit" button in our menus).

The more navigation buttons we add to our UI, the more we will have to handle this in our ContextSelector component!
This becomes worsened by the fact that every ancestor component of any navigation-related button needs to handle a navigation callback.

A better approach to navigation would be to expose our `setContext` state through what's called a _context provider!_

`Pract.withContextProvider` is a higher-order function that allows us to expose values to descendants deep in the element tree without specifying these values through props:
```lua
local MainHUD = require(game.ReplicatedStorage.Contexts.MainHUD)
local Menu1 = require(game.ReplicatedStorage.Contexts.Menu1)
local Menu2 = require(game.ReplicatedStorage.Contexts.Menu2)
local Menu3 = require(game.ReplicatedStorage.Contexts.Menu3)

-- This is a much more concise way of organizing our contexts, since we don't have to handle any
-- navigation callbacks through props!
local ContextCreators: {[string]: () -> Pract.Element} = {
    MainHUD = function() return Pract.create(MainHUD) end,
    Menu1 = function() return Pract.create(Menu1) end,
    Menu2 = function() return Pract.create(Menu2) end,
    Menu3 = function() return Pract.create(Menu3) end,
}
local ContextSelector = Pract.withDeferredState(function(getContext, setContext)
    -- Set our default context to "MainHUD"
    setContext('MainHUD')

    -- This function is provided to our descendants deep in the element tree without specifying it
    -- in props!
    local function navigateToContext(newContext: string)
        -- As an added bonus, we can throw an error here if the context provided is invalid.
        if not ContextCreators[newContext] then
            error('Attempt to navigate to nonexistent context "' .. newContext ..'"!')
        end
        setContext(newContext)
    end
    
    -- Since withContextProvider returns a component, we can chain it here!
    return Pract.withContextProvider(function(provide))
        -- We can expose our navigateToContext function through the provide function!
        provide('navigateToContext', navigateToContext)

        return function(props: {})
            local currentContextCreator = ContextCreators[getContext()]

            return Pract.index {
                Contexts = Pract.index {
                    -- Create our context-named element based on the value of our state
                    [getContext()] = currentContextCreator()
                }
            }
        end
    end
    end
end)
local function App(props: {})
    return Pract.index {
        -- Mount our app on AppGui when it's copied from StarterGui
        AppGui = Pract.create(ContextSelector)
    }
end
Pract.Mount(App, game.Players.LocalPlayer:WaitForChild('PlayerGui'))
```

## Consuming objects provided by an ancestor component

The example above exposes a function (`navigateToContext`) to any descendant elements in the tree. In order to actually access this function later on, we need to wrap a component using `Pract.withContextConsumer`:

```lua
-- This is an unlinked component; it lets props passed in determine what happens when the button is
-- clicked.
local function ExitButton(props: {clicked: () -> ()})
    -- Here we decorate an existing instance named ExitButton in our Menu1Template, stamped by the
    -- Menu1 component below.
    return Pract.decorate({
        Text = 'Exit',
        MouseButton1Click = props.clicked,
    })
end

local LinkedExitButton = Pract.withContextConsumer(function(consume)
    -- Here we consume the object provided by our ancestor "ContextSelector" component, and link our
    -- ExitButton's "clicked" callback to app navigation.
    local navigateToContext: (string) -> () = consume('navigateToContext')
    return function(props: {})
        return Pract.create(ExitButton, {
            clicked = function()
                navigateToContext('MainHUD')
            end
        })
    end
end)
local function Menu1()
    return Pract.stamp(script.Menu1Template, {
        -- ...
    }, {
        ExitButton = Pract.create(LinkedExitButton),
    })
end
```

Context providers and consumers have a very specific use case, and do not need to be used heavily in your UI code; `withContextProvider` is more optimized for UI trees that has only a few context providers. Providing many objects in single a `withContextProvider`-wrapped is the optimal way to use context providers, as `withContextConsumer` will search through every ancestor `withContextProvider`-wrapped component until it finds a matching key.

Generally, providers/consumers are more useful in a large-scale UI apps with deep component heirarchies, than they are in small-scale Pract applications.

#### Up next: [Using Pract With Third-Party Systems](./externalstate)