*=============================================================================
* mmqrtest_example.do -- full self-test / demonstration of mmqrtest
* Merwan Roudane (merwanroudane920@gmail.com)
*
* Run from the folder that contains mmqrtest.ado:
*     do mmqrtest_example.do
*
* Four simulated designs with KNOWN truth (Machado & Santos Silva 2019,
* eq. 8 variants; Canay 2011), so every verdict can be checked:
*
*   A  pure location-shift FE, homoskedastic     -> nothing rejects
*   B  scale depends on X, common delta          -> only scalerel rejects
*   C  M&SS eq.(8) with kappa=1 (delta_i = f(a_i)) -> scalerel, distfe,
*                                                    canay reject
*   D  shape effect (skewness depends on X)      -> spec rejects
*   E  negative-scale design                     -> scalepos VIOLATION
*=============================================================================
version 14.0
clear all
discard
set more off

local REPS  150          // bootstrap reps for canay (use 500 for papers)
local SEED  20260612

capture which mmqrtest
if _rc {
    display as error "mmqrtest.ado not found on the adopath -- run this do-file"
    display as error "from the folder that contains it, or net install first."
    exit 111
}
capture which mmqreg
if _rc {
    display as error "mmqreg is required: ssc install mmqreg"
    exit 111
}

tempname RES
matrix `RES' = J(15,2,.)   // collected p-values / flags for the scoreboard

*-----------------------------------------------------------------------------
* helper: simulate a panel.  scale spec differs by scenario
*-----------------------------------------------------------------------------
capture program drop simpanel
program define simpanel
    args scen n T seed
    clear
    set seed `seed'
    set obs `n'
    gen long id = _n
    gen double a_i  = rchi2(1)              // location FE
    gen double ch_i = rchi2(1)
    expand `T'
    bysort id: gen int t = _n
    gen double chit = rchi2(1)
    gen double x    = 0.5*(a_i + chit)       // x > 0, correlated with a_i
    gen double z    = rnormal()
    if ("`scen'"=="A") {
        * pure location shift, homoskedastic: scale = 2
        gen double y = a_i + x + 2*z
    }
    if ("`scen'"=="B") {
        * scale depends on x, delta common: scale = 1 + 0.7x > 0
        gen double y = a_i + x + (1 + 0.7*x)*z
    }
    if ("`scen'"=="C") {
        * M&SS eq.(8), kappa=1: scale = 1 + x + a_i  (delta_i heterogeneous)
        gen double y = a_i + x + (1 + x + a_i)*z
    }
    if ("`scen'"=="D") {
        * shape effect: error skewness depends on x -> NOT location-scale
        gen double sk = (rchi2(1)-1)/sqrt(2)
        gen double v  = cond(x>0.8, sk, z)
        gen double y  = a_i + x + (1 + 0.3*x)*v
        drop sk v
    }
    if ("`scen'"=="E") {
        * fitted scale goes negative for small x: true sd = |x - 0.25|,
        * so the Glejser line ~ 0.8x - 0.2 is negative for x < ~0.25
        replace x = 0.1 + 1.9*runiform()
        gen double y = a_i + x + (x - 0.25)*z
    }
    xtset id t
end

*=============================================================================
display as result _n "(A) ALL NULLS TRUE: location-shift FE, homoskedastic"
display as text      "    expected: every test PASSES / fails to reject"
*=============================================================================
simpanel A 100 20 1001
mmqreg y x, absorb(id) quantile(25 50 75)
mmqrtest all, reps(`REPS') seed(`SEED') graph name(gA)
matrix `RES'[1,1] = r(nneg)         // expect 0
matrix `RES'[2,1] = r(p_scalerel)   // expect > .01 (true null, single draw)
matrix `RES'[3,1] = r(p_spec)       // expect > .01 (true null, single draw)
matrix `RES'[4,1] = r(p_distfe)     // expect > .01 (true null, single draw)
matrix `RES'[5,1] = r(p_canay)      // expect > .01 (true null, single draw)

* --- mechanical checks on the way ---
mmqreg                               // replay must still work: e() restored
assert "`e(cmd)'"=="mmqreg"
mmqrtest distfe y x, id(id)          // standalone syntax
assert r(p)<.
mmqrtest scalepos, generate(chkA)    // generate() option
assert chkA_sigma<.
drop chkA_sigma chkA_delta

*=============================================================================
display as result _n "(B) SCALE RELEVANT, DELTA COMMON: scale = 1 + 0.7x"
display as text      "    expected: scalerel REJECTS; distfe & canay do not"
*=============================================================================
simpanel B 100 20 1002
mmqreg y x, absorb(id) quantile(25 50 75)
mmqrtest scalerel, graph name(gB_scalerel)
matrix `RES'[6,1] = r(p)            // expect < .05
mmqrtest distfe, graph name(gB_distfe)
matrix `RES'[7,1] = r(p)            // expect > .01 (true null, single draw)
mmqrtest canay, reps(`REPS') seed(`SEED') graph name(gB_canay)
matrix `RES'[8,1] = r(p)            // expect > .01 (true null, single draw)

*=============================================================================
display as result _n "(C) M&SS eq.(8) kappa=1: distributional fixed effects"
display as text      "    expected: scalerel, distfe and canay all REJECT"
*=============================================================================
simpanel C 100 20 1003
mmqreg y x, absorb(id) quantile(25 50 75)
mmqrtest all, reps(`REPS') seed(`SEED') graph name(gC)
matrix `RES'[9,1]  = r(p_scalerel)  // expect < .05
matrix `RES'[10,1] = r(p_distfe)    // expect < .05
matrix `RES'[11,1] = r(p_canay)     // expect < .05

*=============================================================================
display as result _n "(D) SHAPE EFFECT: skewness depends on x"
display as text      "    expected: spec REJECTS the location-scale family"
*=============================================================================
simpanel D 200 25 1004
mmqreg y x, absorb(id) quantile(25 50 75)
mmqrtest spec, graph name(gD_spec)
matrix `RES'[12,1] = r(p)           // expect < .05

*=============================================================================
display as result _n "(E) NEGATIVE SCALE DESIGN"
display as text      "    expected: scalepos flags a VIOLATION"
*=============================================================================
simpanel E 100 20 1005
mmqreg y x, absorb(id) quantile(50) nowarning
mmqrtest scalepos, graph name(gE_scalepos)
matrix `RES'[13,1] = r(nneg)        // expect > 0

*=============================================================================
* factor-variable handling (standalone, internal mmqreg refit)
*=============================================================================
simpanel B 80 15 1006
gen byte dbin = (mod(id,2)==0 & t>7) | (mod(id,2)==1 & t>10)
mmqrtest scalerel y x i.dbin, id(id) quantile(25 75)
matrix `RES'[14,1] = (r(p)<.)       // expect 1 = ran and returned a p-value

*=============================================================================
display as result _n "(F) SIZE CHECK: distfe under a true null, 20 seeds"
display as text      "    expected: about 1 rejection in 20 at the 5% level"
*=============================================================================
local rej = 0
forvalues s = 1/20 {
    qui simpanel A 100 20 `=3000+`s''
    qui mmqrtest distfe y x, id(id)
    if (r(p)<.05) local rej = `rej' + 1
    display as text "." _continue
}
display as text " done"
display as text "    rejections at 5% level: " as result "`rej'" ///
    as text " of 20  (empirical size = " as result %4.2f `rej'/20 as text ")"
matrix `RES'[15,1] = `rej'          // expect <= 3 of 20

*=============================================================================
* SCOREBOARD
*=============================================================================
display as result _n "{hline 72}"
display as result "  mmqrtest SELF-TEST SCOREBOARD"
display as text   "{hline 72}"
local i = 0
foreach row in ///
    "A scalepos nneg=0          :eq0" ///
    "A scalerel p>.01           :gt" ///
    "A spec     p>.01           :gt" ///
    "A distfe   p>.01           :gt" ///
    "A canay    p>.01           :gt" ///
    "B scalerel p<.05           :lt" ///
    "B distfe   p>.01           :gt" ///
    "B canay    p>.01           :gt" ///
    "C scalerel p<.05           :lt" ///
    "C distfe   p<.05           :lt" ///
    "C canay    p<.05           :lt" ///
    "D spec     p<.05           :lt" ///
    "E scalepos nneg>0          :gt0" ///
    "FV syntax  returned p      :gt0" ///
    "F size     rej<=3 of 20    :sz" {
    local i = `i' + 1
    local lab  = substr("`row'",1,27)
    local rule = substr("`row'",strpos("`row'",":")+1,.)
    local v = `RES'[`i',1]
    local ok "FAIL"
    if ("`rule'"=="eq0" & `v'==0)          local ok "ok"
    if ("`rule'"=="gt"  & `v'>.01 & `v'<.) local ok "ok"
    if ("`rule'"=="lt"  & `v'<.05)         local ok "ok"
    if ("`rule'"=="gt0" & `v'>0  & `v'<.)  local ok "ok"
    if ("`rule'"=="sz"  & `v'<=3 & `v'<.)  local ok "ok"
    if ("`ok'"=="ok") {
        display as text "   `lab'" as text "  value = " ///
            as result %8.4f `v' as text "   [" as result "`ok'" as text "]"
    }
    else {
        display as text "   `lab'" as text "  value = " ///
            as result %8.4f `v' as text "   [" as error "`ok'" as text "]"
    }
}
display as text "{hline 72}"
display as text "  Notes: rows testing a TRUE null (A and B 'fail to reject' rows) are"
display as text "  single stochastic draws; the threshold is p > .01 because a 5%-level"
display as text "  test lands in (.01,.05) by chance in about 4 of 100 draws -- that is"
display as text "  correct size, not a code error. Row F verifies size directly: the"
display as text "  distfe rejection rate over 20 independent true-null panels should be"
display as text "  near 1 in 20. Use reps(500) and larger n,T for power checks."
display as text "{hline 72}"

*=============================================================================
* GRAPH GALLERY: every graph stays in memory; re-display and export PNGs
*   (graphs are named by scenario: gA_* battery A, gB_*, gC_* battery C,
*    gD_spec, gE_scalepos; *_dash are the combined dashboards)
*=============================================================================
display as result _n "GRAPH GALLERY"
qui graph dir
local glist "`r(list)'"
display as text "  graphs in memory: " as result "`glist'"
foreach g of local glist {
    graph display `g'
    capture graph export "mmqrtest_`g'.png", replace width(1400)
}
display as text "  PNG copies saved in " as result "`c(pwd)'"
display as text "  click the Graph window tabs, or type: graph display gC_dash"
