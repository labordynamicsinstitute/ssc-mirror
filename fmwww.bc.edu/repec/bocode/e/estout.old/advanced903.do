capt prog drop e_stci
*! version 1.0.0  16sep2008  Ben Jann
prog e_stci, eclass
    version 9.2
    syntax [if] [in] [ , by(varname) Median Rmean Emean p(str) * ]
    local stat "p50"
    if `"`p'"'!=""          local stat `"p`p'"'
    else if "`rmean'"!=""   local stat "rmean"
    else if "`emean'"!=""   local stat "emean"
    tempname b V N_sub lb ub
    marksample touse
    if "`by'"!="" {
        markout `touse' `by', strok
        qui levelsof `by' if `touse', local(levels)
    }
    local levels `"`levels' "total""'
    gettoken l rest : levels, quotes
    while (`"`l'"'!="") {
        if `"`rest'"'=="" local lcond
        else              local lcond `" & `by'==`l'"'
        qui stci if `touse'`lcond', `median' `rmean' `emean' `p' `options'
        mat `b' = nullmat(`b'), r(`stat')
        mat `V' = nullmat(`V'), r(se)^2
        mat `N_sub' = nullmat(`N_sub'), r(N_sub)
        mat `lb' = nullmat(`lb'), r(lb)
        mat `ub' = nullmat(`ub'), r(ub)
        gettoken l rest : rest
    }
    foreach m in b V N_sub lb ub {
        mat coln ``m'' = `levels'
    }
    if matmissing(`V') {
        mat `V' = `b'' * `b' * 0  // set V to zero
    }
    else {
        mat `V' = diag(`V')
    }
    eret post `b' `V'
    eret matrix N_sub = `N_sub'
    eret matrix lb = `lb'
    eret matrix ub = `ub'
    eret local cmd "e_stci"
end
webuse page2
stci, by(group)
e_stci, by(group)
ereturn list
estout, cell("N_sub b(label(50%)) se lb ub")
