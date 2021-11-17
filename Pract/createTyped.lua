--!strict

local Types = require(script.Parent.Types)

type CreateTyped = <PropsType>(
	component: (PropsType) -> Types.Element,
	props: PropsType
) -> (Types.Element)
local createTyped: CreateTyped = function(component, props)
	return component(props)
end :: any

return createTyped
