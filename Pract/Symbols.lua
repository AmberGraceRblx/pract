--!strict

local createSymbol = require(script.Parent.createSymbol)


local Symbols = {}

-- Element kinds to be used in record-based conditionals (visitor pattern reconciler)
local ElementKinds = {}
ElementKinds.CreateInstance = createSymbol('CreateInstance')
ElementKinds.Stamp = createSymbol('Stamp')
ElementKinds.OnChild = createSymbol('OnChild')
ElementKinds.Decorate = createSymbol('Decorate')
ElementKinds.Index = createSymbol('Index')
ElementKinds.Portal = createSymbol('Portal')
ElementKinds.RenderComponent = createSymbol('RenderComponent')
ElementKinds.LifecycleComponent = createSymbol('LifecycleComponent')
ElementKinds.StateComponent = createSymbol('StateComponent')
ElementKinds.SignalComponent = createSymbol('SignalComponent')
ElementKinds.ContextProvider = createSymbol('ContextProvider')
ElementKinds.ContextConsumer = createSymbol('ContextConsumer')
ElementKinds.SiblingCluster = createSymbol('SiblingCluster')
Symbols.ElementKinds = ElementKinds

-- Decoration prop key symbols
Symbols.Attributes = createSymbol('Attributes')
Symbols.CollectionServiceTags = createSymbol('CollectionServiceTags')
Symbols.Children = createSymbol('Children')
Symbols.AttributeChangedSignals = createSymbol('AttributeChangedSymbols')
Symbols.PropertyChangedSignals = createSymbol('PropertyChangedSignals')
Symbols.OnMountWithHost = createSymbol('OnMountWithHost')
Symbols.OnUnmountWithHost = createSymbol('OnUnmountWithHost')
Symbols.OnRenderWithHost = createSymbol('OnRenderWithHost')

-- Decoration prop value symbols
Symbols.None = createSymbol('None')

-- Internal symbols
Symbols.IsPractTree = createSymbol('IsPractTree')
Symbols.ElementKind = createSymbol('ElementKind')
--Symbols.IsPractVirtualNode = createSymbol('IsPractVirtualNode')

return Symbols