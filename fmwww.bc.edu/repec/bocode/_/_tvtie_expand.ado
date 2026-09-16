*! _tvtie_expand 1.2.0 13sep2026
*! Levent Kutlu
*! Copyright (C) 2026 Levent Kutlu. GNU GPL v3; see tvtie_license.txt.
program define _tvtie_expand, rclass
    version 16.0
    syntax anything(name=terms) [, ENdogenous(varlist numeric)]
    quietly fvexpand `terms'
    local expanded "`r(varlist)'"
    local names ""
    local functions ""
    local bases ""
    foreach term of local expanded {
        local components : subinstr local term "#" " ", all
        local involves 0
        local normalized ""
        foreach component of local components {
            local base "`component'"
            if strpos("`component'",".") {
                if substr("`component'",1,2)!="c." {
                    di as error "Only continuous factor notation is supported: c.x, c.x#c.x, and c.x##c.w."
                    exit 198
                }
                local base=substr("`component'",3,.)
            }
            capture confirm numeric variable `base'
            if _rc {
                di as error "Continuous terms must use observed numeric variables without time-series operators."
                exit 198
            }
            local bases `bases' `base'
            local isendo : list base in endogenous
            if `isendo' local involves 1
            if "`normalized'"=="" local normalized "c.`base'"
            else local normalized "`normalized'#c.`base'"
        }
        if !strpos("`term'","#") local normalized "`base'"
        local names `names' `normalized'
        if `involves' & strpos("`term'","#") local functions `functions' `normalized'
    }
    local names : list uniq names
    local functions : list uniq functions
    local bases : list uniq bases
    return local terms "`names'"
    return local functions "`functions'"
    return local bases "`bases'"
end
