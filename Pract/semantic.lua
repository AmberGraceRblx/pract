--!strict

local Types = require(script.Parent.Types)
local Symbols = require(script.Parent.Symbols)

local SemanticFragmentMT = {
	__index = {
		[Symbols.ElementKind] = Symbols.ElementKinds.IncompleteSemanticElement
	},
	__call = function(self: any, arg: any)
		local _args = self._args
		
		local save_argsGiven = self._argsGiven
		local next_argsGiven = save_argsGiven + 1
		self._argsGiven = next_argsGiven
		
		_args[next_argsGiven] = arg
		if next_argsGiven == #self._defaultArgs then
			return self._wrappedFunction(unpack(_args))
		end
		
		return self
	end,
}

--type CallableSemanticFactory = (any) -> ((any) -> ((any) -> ((any) -> ((any) -> any))))

local function semanticFactory(
	wrappedFunction: (...any) -> Types.Element,
	defaultArgs: {any}
): any
	if #defaultArgs < 2 then
		return wrappedFunction :: any
	end
	
	return function(firstArg: any)
		local _args = table.create(#defaultArgs)
		_args[1] = firstArg
		return setmetatable({
			_args = _args,
			_argsGiven = 1,
			_wrappedFunction = wrappedFunction,
			_defaultArgs = defaultArgs,
		}, SemanticFragmentMT) :: any
	end
end

local semanticCreate = semanticFactory(
	require(script.Parent.create),
	{'undefinedsemantictype', {}, {}}
)
local semanticStamp = semanticFactory(
	require(script.Parent.stamp),
	{nil, {}, {}}
)
local semanticDecorate = semanticFactory(
	require(script.Parent.decorate),
	{{}, {}}
)
local semanticIndex = require(script.Parent.index)
local semanticPortal = semanticFactory(
	require(script.Parent.portal),
	{nil, {}}
)
local semanticCombine = require(script.Parent.combine)
--local semanticFragment = semanticFactory(fragment, {})

local semantic = {}
function semantic.untyped()
	return 	semanticCreate,
			semanticStamp,
			semanticDecorate,
			semanticIndex :: any,
			semanticPortal,
			semanticCombine :: any
end

function semantic.typed()
	return 	(semanticCreate :: any) :: (classNameOrComponent: string | Types.Component) -> (
				(props: Types.PropsArgument) -> (
					(children: Types.ChildrenArgument?) -> Types.Element
				)
			),
			(semanticStamp :: any) :: (template: Instance) -> (
				(props: Types.PropsArgument) -> (
					(children: Types.ChildrenArgument?) -> Types.Element
				)
			),
			(semanticDecorate :: any) :: (props: Types.PropsArgument) -> (
				(children: Types.ChildrenArgument?) -> Types.Element
			),
			semanticIndex,
			(semanticPortal :: any) :: (hostParent: Instance) -> (
				(children: Types.ChildrenArgument?) -> Types.Element
			),
			semanticCombine
end

return semantic