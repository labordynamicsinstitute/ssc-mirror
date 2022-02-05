*! version 1.0.3  02feb2022
program tolong
    version 15
    syntax anything(name=stubs equalok everything) [, i(varlist) j(string) *]
    if "`i'" == "" {
        local i _i
        confirm new variable _i
        local _i _i
    }
    if `"`j'"' == "" local j _j
    confirm new variable `j'
    mata: _tolong()
    order `i' `j'
end

exit

version history
---------------

version 1.0.2

1. Stub variable values stored as doubles were sometimes incorrectly stored
   in float precision. This has been fixed.

2. Stub variable indices whose values exceeded float precision were
   incorrectly stored as float instead of long or double. This has been fixed.

3. Stub variable indices that exceed the largest integer Stata can store
   (9007199254740992) were stored as doubles but still lost precision. To
   preserve all digits, the variable j is now stored in string format if
   any of j's values exceeds the largest integer value Stata can store.

version 1.0.3

1. When reshaping two or more variables with non-overlapping stub indices,
   under certain conditions, the first stub variable values were not correctly
   matched to the indices. This has been fixed.

