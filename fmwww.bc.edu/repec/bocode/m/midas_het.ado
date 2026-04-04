*! midas_het.ado  v1.0.1  Ben Adarkwa Dwamena  2026
*! Post-estimation heterogeneity decomposition for MIDAS
*! Burke-weighted I² contributions: tabular + forest plot
*!
*! Syntax:
*!   midas_het [, SAVEgraph(filename) NOGRaph FORMAT(fmt)]
*!
*! Options:
*!   savegraph(filename)  save forest plot to filename (no extension needed;
*!                        both .pdf and .eps written for LaTeX import)
*!   nograph              suppress forest plot
*!   format(fmt)          numeric display format for I² columns (default %6.4f)
*!
*! Requires in e():
*!   e(cmd)           "midas_mle" | "midas_qrsim" | "midas_mh" |
*!                    "midas_hmc" | "midas_inla"  [or e(cmd)="midas"]
*!   e(studywgts) or e(studyweights)  n×3 Burke weight matrix
*!   e(bIsquared)     1×3 overall I² row vector
*!==========================================================


*==========================================================
* MAIN COMMAND: midas_het
*==========================================================
capture program drop midas_het
program define midas_het, eclass

    version 16.0

    syntax [, SAVEgraph(string) NOGRaph FORMAT(string)]

    *--- Default display format ---*
    if `"`format'"' == "" local format "%6.4f"

    *----------------------------------------------------------
    * Guard 1: must follow a MIDAS estimation command
    * e(cmd) may be "midas" or the full command name depending
    * on which Stata estimation engine the estimator uses;
    * test both e(cmd) and e(cmd2) against known tokens
    *----------------------------------------------------------
    local cmd2 = e(cmd2)

    *--- Recognised estimator tokens in e(cmd2) ---*
    local valid_cmd2 "mle qrsim mh hmc inla"

    *--- Also accept if e(cmd) itself is a MIDAS command name ---*
    local valid_cmd  "midas midas_mle midas_qrsim midas_mh midas_hmc midas_inla"

    local cmd_ok = 0
    foreach v of local valid_cmd2 {
        if `"`cmd2'"' == "`v'" local cmd_ok = 1
    }
    foreach v of local valid_cmd {
        if `"`e(cmd)'"' == "`v'" local cmd_ok = 1
    }

    if !`cmd_ok' {
        di as err "midas_het requires estimation by a MIDAS command " ///
                  "(midas_mle, midas_qrsim, midas_mh, midas_hmc, midas_inla)."
        exit 301
    }

    *--- If cmd2 still empty OR numeric missing, infer from e(cmd) ---*
    if `"`cmd2'"' == "" | `"`cmd2'"' == "." {
        local ecmd = e(cmd)
        foreach tok in mle qrsim mh hmc inla {
            if `"`ecmd'"' == "midas_`tok'" local cmd2 "`tok'"
        }
    }

    if `"`cmd2'"' == "" {
        di as err "midas_het: cannot identify estimator from e(cmd) or e(cmd2)."
        exit 301
    }

    *----------------------------------------------------------
    * Guard 2: retrieve weight matrix from e(studywgts)
    * All five MIDAS estimators post e(studywgts) with columns
    * senwgt spewgt bivwgt
    *----------------------------------------------------------
    capture confirm matrix e(studywgts)
    if _rc {
        di as err "midas_het: e(studywgts) not found."
        di as err "Re-run a MIDAS estimation command first."
        exit 301
    }
    local nr = rowsof(e(studywgts))
    if `nr' < 2 | colsof(e(studywgts)) != 3 {
        di as err "midas_het: e(studywgts) has wrong dimensions."
        exit 503
    }
    local wgt_mname "studywgts"

    *----------------------------------------------------------
    * Guard 3: recover I² values
    * Preference order:
    *   (a) e(bIsquared) already posted by estimator
    *   (b) scalars i2_sens, i2_spec, i2_biv in e()
    *   (c) scalars of same name in r() (some estimators use
    *       return rather than ereturn for scalars)
    *----------------------------------------------------------
    tempname bI2tmp
    local i2_ok = 0

    capture matrix `bI2tmp' = e(bIsquared)
    if !_rc & rowsof(`bI2tmp') == 1 & colsof(`bI2tmp') == 3 {
        matrix _midas_het_bI2 = `bI2tmp'
        local i2s = _midas_het_bI2[1,1]
        local i2p = _midas_het_bI2[1,2]
        local i2b = _midas_het_bI2[1,3]
        matrix drop _midas_het_bI2
        local i2_ok = 1
    }

    if !`i2_ok' {
        foreach s in i2_sens i2_spec i2_biv {
            local v = e(`s')
            if `"`v'"' == "" {
                capture scalar `s'_tmp = `s'
                if !_rc local v = `s'_tmp
            }
            local `s' = `v'
        }
        if !missing(`i2_sens') & !missing(`i2_spec') & !missing(`i2_biv') {
            local i2s = `i2_sens'
            local i2p = `i2_spec'
            local i2b = `i2_biv'
            local i2_ok = 1
        }
    }

    if !`i2_ok' {
        di as err "midas_het: cannot recover I² values. " ///
                  "Ensure e(bIsquared) or scalars i2_sens/i2_spec/i2_biv " ///
                  "are available after estimation."
        exit 301
    }

    *--- All three must be non-missing ---*
    foreach s in i2s i2p i2b {
        if missing(``s'') {
            di as err "midas_het: I² value ``s'' is missing " ///
                      "for estimator `cmd2'."
            exit 459
        }
    }

    *----------------------------------------------------------
    * Guard 4: weight columns must sum to positive values
    *----------------------------------------------------------
    tempname Wg
    matrix `Wg' = e(`wgt_mname')
    forvalues j = 1/3 {
        local csum = 0
        forvalues i = 1/`nr' {
            local csum = `csum' + `Wg'[`i',`j']
        }
        if `csum' <= 0 {
            di as err "midas_het: weight column `j' of e(`wgt_mname') " ///
                      "sums to ≤ 0 for estimator `cmd2'."
            exit 503
        }
    }

    *----------------------------------------------------------
    * Per-estimator metadata
    *----------------------------------------------------------
    if "`cmd2'" == "mle" {
        local wt_src "Model-based posterior precision (bivariate GLMM via meglm; intmethod: mvaghermite / mcaghermite / pcaghermite)"
        local elbl   "MLE — adaptive Gauss-Hermite quadrature"
    }
    else if "`cmd2'" == "qrsim" {
        local wt_src "Model-based posterior precision (maximum simulated likelihood, quasi-random Monte Carlo / Halton sequences)"
        local elbl   "QR simulation — MSL"
    }
    else if "`cmd2'" == "mh" {
        local wt_src "Posterior mean precision (Bayesian Metropolis-Hastings via bayesmh)"
        local elbl   "Bayesian Metropolis-Hastings"
    }
    else if "`cmd2'" == "hmc" {
        local wt_src "Full posterior precision (HMC, integrates over variance posterior)"
        local elbl   "HMC — CmdStan"
    }
    else if "`cmd2'" == "inla" {
        local wt_src "Marginal posterior precision (INLA Laplace approximation)"
        local elbl   "INLA"
    }
    else {
        local wt_src "Unknown — estimator `cmd2' not recognised"
        local elbl   "`cmd2'"
    }
    *--- I² source is uniform across all estimators ---*
    local i2_src "Zhou-Dendukuri method"

    *----------------------------------------------------------
    * Core computation
    *----------------------------------------------------------
    tempname W bI2 H Hpct C __s

    *--- Pull weight matrix directly from e(studywgts) ---*
    matrix `W'   = e(studywgts)
    matrix colnames `W' = senwgt spewgt bivwgt

    local rn : rownames `W'

    matrix `bI2' = (`i2s', `i2p', `i2b')
    matrix colnames `bI2' = I2_sens I2_spec I2_biv

    *--- Mata apportionment: function compiled at ado load time ---*

    mata: st_matrix("`H'", ///
        midas_apportion_i2(st_matrix("`W'"), st_matrix("`bI2'")))

    matrix `Hpct' = 100 * `H'

    matrix colnames `H'    = I2_sens_contrib I2_spec_contrib I2_biv_contrib
    matrix colnames `Hpct' = I2_sens_pctpt   I2_spec_pctpt   I2_biv_pctpt

    if `"`rn'"' != "" {
        matrix rownames `H'    = `rn'
        matrix rownames `Hpct' = `rn'
        matrix rownames `W'    = `rn'
    }

    *--- Weight-column audit sums ---*
    matrix `C' = J(1,3,.)
    forvalues j = 1/3 {
        scalar `__s' = 0
        forvalues i = 1/`nr' {
            scalar `__s' = `__s' + `W'[`i',`j']
        }
        matrix `C'[1,`j'] = `__s'
    }
    matrix colnames `C' = senwgt_sum spewgt_sum bivwgt_sum

    *----------------------------------------------------------
    * Copy H and Hpct to permanent names BEFORE ereturn consumes them
    *----------------------------------------------------------
    matrix _midas_het_H    = `H'
    matrix _midas_het_Hpct = `Hpct'
    matrix _midas_het_C    = `C'

    *----------------------------------------------------------
    * Hold the caller's estimation results so midas_het does
    * not clobber e() — proper postestimation behaviour
    *----------------------------------------------------------
    _estimates hold _midas_het_hold, restore nullok

    *----------------------------------------------------------
    * Post heterogeneity matrices to e()
    *----------------------------------------------------------
    ereturn matrix studyweights = `W'
    ereturn matrix bIsquared    = `bI2'
    ereturn matrix studyI2      = `H'
    ereturn matrix studyI2pct   = `Hpct'
    ereturn matrix wtcheck      = `C'

    *----------------------------------------------------------
    * TABULAR DISPLAY via list
    *----------------------------------------------------------
    di as txt _n "  midas_het — Post-estimation heterogeneity decomposition"
    di as txt "  Estimator : `elbl'"

    preserve
    quietly {
        clear
        local nr2 = rowsof(_midas_het_H)
        set obs `=`nr2' + 2'

        gen str22  Study        = ""
        gen double Sens_I2      = .
        gen double Sens_pct     = .
        gen double Spec_I2      = .
        gen double Spec_pct     = .
        gen double Biv_I2       = .
        gen double Biv_pct      = .

        *--- Study rows ---*
        forvalues i = 1/`nr2' {
            local lbl : word `i' of `rn'
            if `"`lbl'"' == "" local lbl "Study `i'"
            replace Study    = "`lbl'"                          in `i'
            replace Sens_I2  = _midas_het_H[`i',1]             in `i'
            replace Sens_pct = _midas_het_Hpct[`i',1]          in `i'
            replace Spec_I2  = _midas_het_H[`i',2]             in `i'
            replace Spec_pct = _midas_het_Hpct[`i',2]          in `i'
            replace Biv_I2   = _midas_het_H[`i',3]             in `i'
            replace Biv_pct  = _midas_het_Hpct[`i',3]          in `i'
        }

        *--- Overall I² row ---*
        local r1 = `nr2' + 1
        replace Study    = "Overall I2"    in `r1'
        replace Sens_I2  = `i2s'           in `r1'
        replace Sens_pct = 100             in `r1'
        replace Spec_I2  = `i2p'           in `r1'
        replace Spec_pct = 100             in `r1'
        replace Biv_I2   = `i2b'           in `r1'
        replace Biv_pct  = 100             in `r1'

        *--- Weight sums row ---*
        local r2 = `nr2' + 2
        local wc1 = _midas_het_C[1,1]
        local wc2 = _midas_het_C[1,2]
        local wc3 = _midas_het_C[1,3]
        replace Study    = "Wt col sums"   in `r2'
        replace Sens_I2  = `wc1'           in `r2'
        replace Spec_I2  = `wc2'           in `r2'
        replace Biv_I2   = `wc3'           in `r2'

        format Study    %-22s
        format Sens_I2 Spec_I2 Biv_I2   `format'
        format Sens_pct Spec_pct Biv_pct %6.1f

        label var Study    "Study"
        label var Sens_I2  "Sens I2(pp)"
        label var Sens_pct "Sens (%)"
        label var Spec_I2  "Spec I2(pp)"
        label var Spec_pct "Spec (%)"
        label var Biv_I2   "Biv I2(pp)"
        label var Biv_pct  "Biv (%)"
    }

    list Study Sens_I2 Sens_pct Spec_I2 Spec_pct Biv_I2 Biv_pct , ///
        clean noobs separator(`nr2') abbreviate(22)

    restore

    *--- Drop permanent display matrices ---*
    matrix drop _midas_het_H _midas_het_Hpct _midas_het_C

    *--- Footnotes ---*
    di as txt "  Weight source : `wt_src'"
    di as txt "  I2 source     : `i2_src' (Zhou & Dendukuri 2014)"
    di as txt "  pp = percentage points; (%) = study share of overall I2"

    *----------------------------------------------------------
    * FOREST PLOT
    *----------------------------------------------------------
    if "`nograph'" == "" {
        _midas_het_forest `i2s' `i2p' `i2b' "`elbl'" `"`savegraph'"'
    }

    *--- Restore caller's estimation results ---*
    _estimates unhold _midas_het_hold

end


*==========================================================
* _midas_het_forest
* Internal — called by midas_het only
* Args: i2s i2p i2b elbl savegraph
* Three-panel linked forest plot: Sensitivity | Specificity | Bivariate
*==========================================================
capture program drop _midas_het_forest
program define _midas_het_forest

    args i2s i2p i2b elbl savegraph

    version 16.0

    tempname H bI2 Hpct
    matrix `H'    = e(studyI2)
    matrix `bI2'  = e(bIsquared)
    matrix `Hpct' = e(studyI2pct)

    local n  = rowsof(`H')
    local rn : rownames `H'

    preserve

    quietly {
        clear
        set obs `n'

        gen int    study_n   = _n
        gen str40  study_lbl = ""
        gen double i2_sens   = .
        gen double i2_spec   = .
        gen double i2_biv    = .
        gen double zero      = 0

        forvalues i = 1/`n' {
            local lbl : word `i' of `rn'
            if `"`lbl'"' == "" local lbl "Study `i'"
            replace study_lbl = "`lbl'"          in `i'
            replace i2_sens   = `H'[`i',1] * 100 in `i'
            replace i2_spec   = `H'[`i',2] * 100 in `i'
            replace i2_biv    = `H'[`i',3] * 100 in `i'
        }

        *--- Reverse order: study 1 at top ---*
        gen int ypos = `n' + 1 - study_n
    }

    *--- Shared x-axis: scale to maximum per-study value across all three ---*
    quietly summarize i2_sens
    local xmax = r(max)
    quietly summarize i2_spec
    local xmax = max(`xmax', r(max))
    quietly summarize i2_biv
    local xmax = max(`xmax', r(max))

    if `xmax' <= 0.05       local xceil = 0.05
    else if `xmax' <= 0.1   local xceil = 0.1
    else if `xmax' <= 0.25  local xceil = 0.25
    else if `xmax' <= 0.5   local xceil = 0.5
    else if `xmax' <= 1     local xceil = 1
    else if `xmax' <= 2     local xceil = 2
    else if `xmax' <= 5     local xceil = 5
    else if `xmax' <= 10    local xceil = 10
    else if `xmax' <= 25    local xceil = 25
    else if `xmax' <= 50    local xceil = 50
    else                    local xceil = 100
    local xmax = `xceil'

    if `xmax' <= 0.05       local xstep = 0.01
    else if `xmax' <= 0.1   local xstep = 0.02
    else if `xmax' <= 0.25  local xstep = 0.05
    else if `xmax' <= 0.5   local xstep = 0.1
    else if `xmax' <= 1     local xstep = 0.2
    else if `xmax' <= 2     local xstep = 0.5
    else if `xmax' <= 5     local xstep = 1
    else if `xmax' <= 10    local xstep = 2
    else if `xmax' <= 25    local xstep = 5
    else if `xmax' <= 50    local xstep = 10
    else                    local xstep = 20

    if `xmax' <= 0.5        local xfmt "%5.2f"
    else if `xmax' <= 5     local xfmt "%4.1f"
    else                    local xfmt "%4.0f"

    *--- Y-axis labels (left panel only) ---*
    local ylabs ""
    forvalues i = 1/`n' {
        local lbl  = study_lbl[`i']
        local yval = ypos[`i']
        local ylabs `"`ylabs' `yval' "`lbl'""'
    }

    *--- Formatted overall I² for panel titles ---*
    local ls = string(round(`i2s'*100, 0.1))
    local lp = string(round(`i2p'*100, 0.1))
    local lb = string(round(`i2b'*100, 0.1))

    *------------------------------------------------------------------
    * Single-plot three-panel layout with numeric columns (eforest style)
    * Layout per panel:  [bar zone] [I²(pp) col] [%(col)]
    *------------------------------------------------------------------
    local numgap  = `xmax' * 0.55       // gap between bar end and first num col
    local ncol1   = `xmax' + `numgap'           // I²(pp) col x-pos
    local ncol2   = `xmax' + `numgap' * 2.4     // % col x-pos
    local pwidth  = `xmax' + `numgap' * 3.6     // total width of one panel

    local gap    = `pwidth' * 0.05      // gap between panels
    local col2   = `pwidth' + `gap'
    local col3   = 2 * `col2'
    local xtotal = `col3' + `pwidth'

    quietly {
        *--- Percentage share from Hpct matrix (already = 100*H[i,j]/I2j) ---*
        gen double pct_sens = .
        gen double pct_spec = .
        gen double pct_biv  = .
        forvalues i = 1/`n' {
            replace pct_sens = `Hpct'[`i',1] in `i'
            replace pct_spec = `Hpct'[`i',2] in `i'
            replace pct_biv  = `Hpct'[`i',3] in `i'
        }

        gen double x0       = 0
        gen double xs       = i2_sens
        gen double xp       = `col2' + i2_spec
        gen double xb       = `col3' + i2_biv
        gen double xp0      = `col2'
        gen double xb0      = `col3'

        *--- x-tick positions: label only 0 and xmax per panel, unlabelled intermediates ---*
        local xticks ""
        local xtstep = `xstep'
        local xt = 0
        while `xt' <= `xmax' + 0.0001 {
            local ticklbl = string(`xt', "`xfmt'")
            *--- Only label 0 and xmax; intermediates get blank label ---*
            local isend = 0
            if abs(`xt') < 0.00001                  local isend 1
            if abs(`xt' - `xmax') < `xstep'*0.01   local isend 1
            if `isend' {
                local xticks `"`xticks' `xt' "`ticklbl'" `=`col2'+`xt'' "`ticklbl'" `=`col3'+`xt'' "`ticklbl'""'
            }
            else {
                local xticks `"`xticks' `xt' " " `=`col2'+`xt'' " " `=`col3'+`xt'' " ""'
            }
            local xt = `xt' + `xtstep'
        }

        local div1 = `col2' - `gap'/2
        local div2 = `col3' - `gap'/2
    }

    *--- Build mlabel strings for numeric columns ---*
    quietly {
        gen str10 lbl_s1 = string(i2_sens, "`xfmt'")
        gen str7  lbl_s2 = string(round(pct_sens, 0.1), "%4.1f") + "%"
        gen str10 lbl_p1 = string(i2_spec, "`xfmt'")
        gen str7  lbl_p2 = string(round(pct_spec, 0.1), "%4.1f") + "%"
        gen str10 lbl_b1 = string(i2_biv,  "`xfmt'")
        gen str7  lbl_b2 = string(round(pct_biv,  0.1), "%4.1f") + "%"

        *--- Fixed x positions for the 6 numeric columns ---*
        gen double xn_s1 = `ncol1'
        gen double xn_s2 = `ncol2'
        gen double xn_p1 = `col2' + `ncol1'
        gen double xn_p2 = `col2' + `ncol2'
        gen double xn_b1 = `col3' + `ncol1'
        gen double xn_b2 = `col3' + `ncol2'

        *--- Overall I² row (obs n+1) ---*
        set obs `=`n'+1'
        local nplus1 = `n' + 1
        replace ypos   = -0.3        in `nplus1'
        replace lbl_s1 = string(`i2s'*100, "`xfmt'")  in `nplus1'
        replace lbl_s2 = "100%"      in `nplus1'
        replace lbl_p1 = string(`i2p'*100, "`xfmt'")  in `nplus1'
        replace lbl_p2 = "100%"      in `nplus1'
        replace lbl_b1 = string(`i2b'*100, "`xfmt'")  in `nplus1'
        replace lbl_b2 = "100%"      in `nplus1'
        replace xn_s1  = `ncol1'     in `nplus1'
        replace xn_s2  = `ncol2'     in `nplus1'
        replace xn_p1  = `col2' + `ncol1'  in `nplus1'
        replace xn_p2  = `col2' + `ncol2'  in `nplus1'
        replace xn_b1  = `col3' + `ncol1'  in `nplus1'
        replace xn_b2  = `col3' + `ncol2'  in `nplus1'
    }

    *--- Column header row positions ---*
    local ytitle_row  = `n' + 2.0    // text sits in middle of header band
    local yhdr_top    = `n' + 2.6    // top of header band
    local yhdr_bot    = `n' + 1.4    // bottom of header band — gap above study 1

    *--- Header shading: add two obs spanning each panel, use rarea ---*
    quietly {
        local nbase = `n' + 1   // obs n+1 already used for overall row
        set obs `=`nbase' + 4'
        local r1 = `nbase' + 1
        local r2 = `nbase' + 2
        local r3 = `nbase' + 3
        local r4 = `nbase' + 4

        gen double sh_lo = `yhdr_bot'
        gen double sh_hi = `yhdr_top'

        *--- Panel 1: x from 0 to pwidth ---*
        gen double sh_x1 = .
        replace sh_x1 = 0          in `r1'
        replace sh_x1 = `pwidth'   in `r2'
        *--- Panel 2: x from col2 to col2+pwidth ---*
        gen double sh_x2 = .
        replace sh_x2 = `col2'               in `r1'
        replace sh_x2 = `=`col2'+`pwidth''   in `r2'
        *--- Panel 3: x from col3 to col3+pwidth ---*
        gen double sh_x3 = .
        replace sh_x3 = `col3'               in `r1'
        replace sh_x3 = `=`col3'+`pwidth''   in `r2'
        *--- Dummy obs for r3/r4 to avoid missing obs warnings ---*
        replace sh_x1 = `pwidth'   in `r3'
        replace sh_x2 = `=`col2'+`pwidth'' in `r3'
        replace sh_x3 = `=`col3'+`pwidth'' in `r3'
        replace sh_x1 = `pwidth'   in `r4'
        replace sh_x2 = `=`col2'+`pwidth'' in `r4'
        replace sh_x3 = `=`col3'+`pwidth'' in `r4'
    }

    *--- X-ticks: use double step to avoid crowding, angle 45 ---*
    local xstep2 = `xstep' * 2   // half as many ticks per panel
    if `xstep2' > `xmax' local xstep2 = `xstep'  // fallback if xmax is small

    local xticks2 ""
    local xt = 0
    while `xt' <= `xmax' + 0.0001 {
        local ticklbl = string(`xt', "`xfmt'")
        local xticks2 `"`xticks2' `xt' "`ticklbl'" `=`col2'+`xt'' "`ticklbl'" `=`col3'+`xt'' "`ticklbl'""'
        local xt = `xt' + `xstep2'
    }

    twoway ///
        (area sh_hi sh_x1 if inrange(_n,`r1',`r2'), cmissing(n) fcolor("51 105 173%18") lcolor(none) base(`yhdr_bot')) ///
        (area sh_hi sh_x2 if inrange(_n,`r1',`r2'), cmissing(n) fcolor("205 92 55%18")  lcolor(none) base(`yhdr_bot')) ///
        (area sh_hi sh_x3 if inrange(_n,`r1',`r2'), cmissing(n) fcolor("67 135 80%18")  lcolor(none) base(`yhdr_bot')) ///
        (rcap x0 xs ypos if ypos >= 1, horizontal lcolor("51 105 173") lwidth(medthin)) ///
        (scatter ypos xs  if ypos >= 1, msymbol(O) mcolor("51 105 173") msize(small)) ///
        (rcap xp0 xp ypos if ypos >= 1, horizontal lcolor("205 92 55")  lwidth(medthin)) ///
        (scatter ypos xp  if ypos >= 1, msymbol(D) mcolor("205 92 55")  msize(small)) ///
        (rcap xb0 xb ypos if ypos >= 1, horizontal lcolor("67 135 80")  lwidth(medthin)) ///
        (scatter ypos xb  if ypos >= 1, msymbol(T) mcolor("67 135 80")  msize(small)) ///
        (scatter ypos xn_s1, msymbol(none) mlabel(lbl_s1) mlabsize(vsmall) mlabcolor(gs4) mlabposition(3)) ///
        (scatter ypos xn_s2, msymbol(none) mlabel(lbl_s2) mlabsize(vsmall) mlabcolor(gs4) mlabposition(3)) ///
        (scatter ypos xn_p1, msymbol(none) mlabel(lbl_p1) mlabsize(vsmall) mlabcolor(gs4) mlabposition(3)) ///
        (scatter ypos xn_p2, msymbol(none) mlabel(lbl_p2) mlabsize(vsmall) mlabcolor(gs4) mlabposition(3)) ///
        (scatter ypos xn_b1, msymbol(none) mlabel(lbl_b1) mlabsize(vsmall) mlabcolor(gs4) mlabposition(3)) ///
        (scatter ypos xn_b2, msymbol(none) mlabel(lbl_b2) mlabsize(vsmall) mlabcolor(gs4) mlabposition(3)) ///
        , ///
        xscale(range(0 `xtotal') noline) ///
        yscale(range(-0.8 `=`n'+3.0') noline) ///
        ylabel(`ylabs', angle(0) labsize(vsmall) nogrid notick) ///
        ytitle("") ///
        xlabel(`xticks2', labsize(vsmall) notick custom nogrid) ///
        xtitle("I{superscript:2} contribution (percentage points)", size(vsmall)) ///
        xline(`div1' `div2', lcolor(gs7) lwidth(medthin)) ///
        yline(0.6, lcolor(gs7) lwidth(thin)) ///
        yline(`yhdr_bot' `yhdr_top', lcolor(gs7) lwidth(thin)) ///
        legend(off) ///
        text(`ytitle_row'  `=`xmax'/2'              "{bf:Sensitivity}", size(small) color("51 105 173") justification(center)) ///
        text(`ytitle_row'  `=`col2'+`xmax'/2'       "{bf:Specificity}", size(small) color("205 92 55")  justification(center)) ///
        text(`ytitle_row'  `=`col3'+`xmax'/2'       "{bf:Bivariate}",   size(small) color("67 135 80")  justification(center)) ///
        text(`ytitle_row'  `=`ncol1'+`numgap'*0.3'  "{bf:I{superscript:2}(pp)}",      size(vsmall)   color(gs3)          justification(center)) ///
        text(`ytitle_row'  `=`ncol2'+`numgap'*0.3'  "{bf:(%)}",         size(vsmall)   color(gs3)          justification(center)) ///
        text(`ytitle_row'  `=`col2'+`ncol1'+`numgap'*0.3' "{bf:I{superscript:2}(pp)}", size(vsmall)  color(gs3)          justification(center)) ///
        text(`ytitle_row'  `=`col2'+`ncol2'+`numgap'*0.3' "{bf:(%)}",    size(vsmall)  color(gs3)          justification(center)) ///
        text(`ytitle_row'  `=`col3'+`ncol1'+`numgap'*0.3' "{bf:I{superscript:2}(pp)}", size(vsmall)  color(gs3)          justification(center)) ///
        text(`ytitle_row'  `=`col3'+`ncol2'+`numgap'*0.3' "{bf:(%)}",    size(vsmall)  color(gs3)          justification(center)) ///
        text(-0.3        0  "{bf:Overall I{superscript:2}}:",  size(vsmall) color(gs3) justification(left)) ///
        title("Burke-weighted I{superscript:2} contributions by study", ///
              size(small) color(gs4)) ///
        subtitle("Estimator: `elbl'", size(vsmall) color(gs8)) ///
        plotregion(lcolor(none) margin(small)) ///
        graphregion(color(white)) bgcolor(white) ///
        ysize(8) xsize(12)

    *--- Export if savegraph() specified ---*
    if `"`savegraph'"' != "" {
        quietly graph export `"`savegraph'.pdf"', replace
        quietly graph export `"`savegraph'.eps"', replace
        di as txt "  Graph saved: `savegraph'.pdf / .eps"
    }

    restore

end


*==========================================================
* _midas_apportion_compile
* Compiles midas_apportion_i2() into Mata on demand.
* Called by midas_het when the function is not in memory
* (e.g. after discard or in a fresh Stata session).
* Mata code must live outside any program define block.
*==========================================================
capture mata: mata drop midas_apportion_i2()
mata:
real matrix midas_apportion_i2(real matrix W, real matrix bI2)
{
    real scalar n, k, j
    real matrix H, csum
    n    = rows(W)
    k    = cols(W)
    H    = J(n, k, 0)
    csum = colsum(W)
    for (j = 1; j <= k; j++) {
        if (csum[1,j] > 0) {
            H[.,j] = (W[.,j] :/ csum[1,j]) :* bI2[1,j]
        }
    }
    return(H)
}
end
