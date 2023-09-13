*! version 1.6.2 11 February 1998* version 1.6.1 6 August 1997* version 1.6.0 7 May 1997* Nick Cox <n.j.cox@durham.ac.uk> and Tony Brady <tbrady@phls.co.uk>* spike plot, histogram or rootogram to show fine structureprogram define spikeplt    version 4.0    local varlist "req ex max(1)"    local if "opt"    local in "opt"    local weight "aweight fweight iweight"    #delimit ;    local options "Round(real 0) FRAC ROOT Zero(real 0) TOtal SHift     L2title(str) B2title(str) Connect(str) Symbol(str) BY(str) *" ;    #delimit cr    parse "`*'"    if "`root'" == "root" & "`frac'" == "frac" {        di in r "must choose between -root- and -frac- options"        exit 198    }    if "`total'" == "total" {        di _n in g "Sorry: total option not available"    }    preserve    tempvar data wt freq nby level    qui {        keep if `varlist' != .        if "`if'" != "" | "`in'" != "" { keep `if' `in' }        if "`shift'" == "shift" {            gen `data' = 0.5 * `round' /*             */ + round(`varlist'- 0.5 * `round',`round')        }        else gen `data' = round(`varlist',`round')        local dfmt : format `varlist'        format `data' `dfmt'        local dlab : value label `varlist'        label val `data' `dlab'        if "`exp'" == "" { local exp "= 1" }        gen `wt' `exp'        egen `freq' = sum(`wt'), by(`data' `by')        if "`frac'" == "frac" {            if "`by'" != "" { local byby ", by(`by')" }            egen `nby' = sum(`wt') `byby'            replace `freq' = `freq' / `nby'        }        else if "`root'" == "root" { replace `freq' = sqrt(`freq') }        sort `by' `data'        by `by' `data': keep if _n == 1        gen `level' = `zero'    }    if "`l2title'" == "" {        if "`frac'" == "frac" { local l2title = "Fraction" }        else if "`root'" == "root" { local l2title = "Root of frequency" }        else local l2title = "Frequency"    }    if "`b2title'" == "" {        local b2title : variable label `varlist'        if "`b2title'" == "" { local b2title "`varlist'" }    }    if "`connect'" == "" { local connect "||" }    if "`symbol'" == "" { local symbol "ii" }    if "`by'" != "" { local options "by(`by') `options'" }    graph `freq' `level' `data' , /*     */ c(`connect') sy(`symbol') l2("`l2title'") b2("`b2title'") `options'end