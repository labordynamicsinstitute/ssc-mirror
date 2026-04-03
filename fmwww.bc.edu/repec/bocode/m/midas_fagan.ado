program define midas_fagan, rclass byable(recall) sortpreserve
version 15

// pretest probability(ies) required; allow 1–3
syntax [if] [in], PRETESTprob(numlist min=1 max=3) ///
[ LRPlus(real 0) LRMinus(real 0) USEMODEL * ]

// ensure we are following a midas_* estimation
capture assert e(package) == "midas"
if _rc != 0 {
di as error "Last estimation command was not a midas subcommand such as mle, qrsim, mh, hmc or inla"
error 301
}

// obtain model-based summary LR+ and LR−
tempname bfagan Vfagan faganmat
mat `bfagan' = e(bsum)
mat `Vfagan' = e(Vsum)
quietly _coef_table, bmatrix(`bfagan') vmatrix(`Vfagan')
mat `faganmat' = r(table)'

// rows 4 and 5 assumed to be log(LR+) and log(LR−) or LR+ and LR− as in your code
local mlrp = `faganmat'[4,1]
local mlrn = `faganmat'[5,1]

// hybrid: allow overrides
// if lrplus() specified, override model LR+; otherwise use model value
if `lrplus' != 0 {
local lrp_use = `lrplus'
}
else {
local lrp_use = `mlrp'
}

// if lrminus() specified, override model LR−; otherwise use model value
if `lrminus' != 0 {
local lrn_use = `lrminus'
}
else {
local lrn_use = `mlrn'
}

// build one Fagan nomogram per pretest probability
local graphlist ""
local num = wordcount("`pretestprob'")
forvalues k = 1/`num' {
local p : word `k' of `pretestprob'
local graphlist "`graphlist' plot`k'"
fagani `p' `lrp_use' `lrn_use', ///
legend(pos(6) col(1) forcesize symxsize(*.25)) ///
name(plot`k', replace) nodraw `options'
}

// aspect ratio according to number of panels
if `num' == 1 {
local aspratio "ysize(7) xsize(4)"
}
else if `num' == 2 {
local aspratio "ysize(5) xsize(7)"
}
else if `num' == 3 {
local aspratio "ysize(4) xsize(9)"
}

noisily graph combine `graphlist', row(1) `aspratio'

end


// helper: single Fagan diagram for a given pretest prob and LR+/LR−
program define fagani, rclass
version 15

syntax anything [if] [in], [ LEGENDopts(string) * ]

tempname prev lrp lrn
quietly {

tokenize "`anything'"
scalar `prev' = `1'
scalar `lrp' = `2'
scalar `lrn' = `3'

// geometry on log-odds scale
local prprob = logit(1-`prev')
local postprob1 = logit(`prev') + log(`lrp')
local postprob2 = logit(`prev') + log(`lrn')

// tick labels for probability axes (left/right)
local ylab ""
foreach p in 0.1 0.2 0.3 0.5 0.7 1 2 3 5 7 10 ///
20 30 40 50 60 70 80 90 93 95 97 98 99 99.3 99.5 99.7 99.8 99.9 {
local ylab `"`ylab' `=ln(`p' / (100 - `p'))' "`p'" "'
}

// tick labels for LR axis
local lrpts ""
foreach lr in 0.001 0.002 0.005 0.01 0.02 0.05 0.1 0.2 0.5 1 2 5 10 20 50 100 200 500 1000 {
local lrpts `"`lrpts' `=-.5*ln(`lr')' 0 "`lr'" "'
}

// probabilities in %
local priorprob = 100*`prev'
local postprobpos = 100*invlogit(`postprob1')
local postprobneg = 100*invlogit(`postprob2')

// text for legend
local notebb1 : di "Prior Prob (%) = " %5.0f `priorprob'
local notebb2 : di "LR_Positive = " %5.3f `lrp'
local notebb3 : di "Post_Prob_Pos (%) = " %5.0f `postprobpos'
local notebb4 : di "LR_Negative = " %5.3f `lrn'
local notebb5 : di "Post_Prob_Neg (%) = " %5.0f `postprobneg'

// default legend if none or not turned off
if "`legendopts'" != "off" {
if "`legendopts'" == "" {
local legendopts `"pos(6) rowgap(1) col(1)"'
}
local legendopts `" order(5 "`notebb1'" 6 "`notebb2'" "`notebb3'" 7 "`notebb4'" "`notebb5'") `legendopts'"'
}

// build the nomogram
#delimit ;
twoway ///
(scatteri 0 0, mcolor(none) yaxis(1)
ylab(`ylab', angle(0) tpos(cross))
yscale(reverse axis(1))
ytitle("Pre-test Probability (%)", axis(1))) ///
(scatteri 0 0, mcolor(none) yaxis(2)
ylab(`ylab', angle(0) tpos(cross) axis(2))
ytitle("Post-test Probability (%)", axis(2))) ///
(scatteri `lrpts', msymbol(+) mcolor(black)
mlabcolor(black) mlabsize(medsmall)) ///
(pci -3.4538776 0 3.4538776 0,
recast(pcspike) lcolor(black)
xscale(range(-1 1)) xsize(4) ysize(7)
xscale(off) ylab(, nogrid)
text(-4 0 "Likelihood Ratio", place(n))) ///
(scatteri `prprob' -1, msymbol(D) yaxis(2)) ///
(pcarrowi `prprob' -1 `postprob1' 1,
yaxis(2) lpattern(solid) lwidth(vthin)) ///
(pcarrowi `prprob' -1 `postprob2' 1,
yaxis(2) lpattern(dash) lwidth(thin)),
legend(`legendopts' size(*.75)) `options' ;
#delimit cr
}
end


