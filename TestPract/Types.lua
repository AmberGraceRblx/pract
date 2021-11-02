--!strict

export type UnitTestAsserts = {
	truthy: (value: any) -> (),
	falsy: (value: any) -> (),
	errors: (cb: () -> ()) -> (),
	equal: (expected: any, actual: any) -> (),
	deep_equal: (expected: any, actual: any) -> (),
	not_equal: (expected: any, actual: any) -> (),
	not_deep_equal: (expected: any, actual: any) -> (),
}
export type It = (
    behaviorDescription: string,
    withExpectCallback: (
        expect: UnitTestAsserts
    ) -> ()
) -> ()
export type Describe = (
    unitName: string,
    withItCallback: (
        it: It
    ) -> ()
) -> ()
export type Spec = (
    practLibraryLocation: any,
    describe: Describe
) -> ()

export type UnitTestOutput = {
    print: (...any) -> (),
    warn: (string) -> (),
    error: (string, number?) -> (),
}
export type UnitTester = (
    specModules: {ModuleScript},
    practLibraryLocation: ModuleScript,
    output: UnitTestOutput
) -> boolean

return nil