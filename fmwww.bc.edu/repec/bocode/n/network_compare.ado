/*
*! Ian White # 6apr2018
	included in network package 
	added measure() option
	corrected in pairs format
Created 17 March 2015
*/
prog def network_compare
syntax, [CLear Format(string) SAving(string) Replace STUBWidth(int 10) EForm Level(cilevel) *]
local outputformat = cond(mi("`format'"),"%6.3f","`format'")

// Load saved network parameters
if mi("`_dta[network_allthings]'") {
	di as error "Data are not in network format"
	exit 459
}
foreach thing in `_dta[network_allthings]' {
    local `thing' : char _dta[network_`thing']
}


if "`e(network)'" != "consistency" & "`e(cmd)'" != "metareg" {
    di as error "network compare must follow network meta consistency"
    exit 459
}

* Set up postfile
tempname post
if mi("`saving'") tempfile saving
postfile `post' str10 trt1 str10 trt2 b se using `saving', `replace'

* Run lincom commands and post results
local trtlist `ref' `trtlistnoref'
local trtlist : list sort trtlist
foreach trt1 in `trtlist' {
    if "`trt1'" != "`ref'" {
        if "`format'"=="augmented" local lincom lincom [`y'_`trt1']_cons 
        if "`format'"=="standard"  local lincom lincom [`y'_1]`trtdiff'1_`trt1'
*        if "`format'"=="pairs"     local lincom lincom [`y']`trtdiff'_`trt1'
        if "`format'"=="pairs"     local lincom lincom `trtdiff'_`trt1'
    }
    else local lincom lincom 
    foreach trt2 in `trtlist' {
        if "`trt2'"=="`trt1'" continue
        if "`trt2'" == "`ref'" local lincom2 `lincom'
        else {
            if "`format'"=="augmented" local lincom2 `lincom' -[`y'_`trt2']_cons 
            if "`format'"=="standard"  local lincom2 `lincom' -[`y'_1]`trtdiff'1_`trt2'
*            if "`format'"=="pairs"     local lincom2 `lincom' -[`y']`trtdiff'_`trt2'
            if "`format'"=="pairs"     local lincom2 `lincom' -`trtdiff'_`trt2'
        }
        qui `lincom2'
        post `post' ("`trt1'") ("`trt2'") (-r(estimate)) (r(se))
    }
}
postclose `post'

* Load results and display
preserve
local lowmeasure =lower("`measure'")
use `saving', clear
label var b "`measure', trt2 - trt1"
label var trt2 "Treatment"
label var trt1 "Comparator"
if !mi("`eform'") {
    gen eb = exp(b)
    local crit = invnorm((`level'+100)/200)
    gen eblow = exp(b - `crit' * se)
    gen ebupp = exp(b + `crit' * se)
    gen eci = "("+string(eblow,"`outputformat'")+","+string(ebupp,"`outputformat'")+")"
    local contents eb eci
    local contentslong exponentiated `lowmeasure' (and its `level'% CI)
    label var eb "exp(b)"
    label var eblow "exp(b): lower CL"
    label var eb "exp(b): upper CL"
    label var eb "exp(b): confidence interval"
}
else {
    local contents b se
    local contentslong `lowmeasure' and its standard error
}
di as text "Table of `contentslong' for Treatment vs. Comparator:" _c
local command tabdisp trt1 trt2, c(`contents') format(`outputformat') stubwidth(`stubwidth') `options'
`command'

* Finish off if clear option used
if !mi("`clear'") {
    di as text "Comparison data are now loaded into memory"
    global F9 `command'
    di as text "Use F9 to redisplay them"
    restore, not
}

end

