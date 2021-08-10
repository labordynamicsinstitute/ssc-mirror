*! version 1.0.1  19nov2020
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
