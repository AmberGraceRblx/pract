--!strict

local Types = require(script.Parent.Types)

local createTyped: <PropsType>(component: (PropsType) -> Types.Element, props: PropsType) = function(component, props)
	return component(props)
end

return createTyped
