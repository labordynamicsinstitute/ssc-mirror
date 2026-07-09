*! totimpact 1.0.0  08jul2026
*! Total impact effects in time series regressions (Pesaran & Smith, 2014)
*! Author: Merwan Roudane  <merwanroudane920@gmail.com>
*! https://github.com/merwanroudane
*
* totimpact estimates the TOTAL impact effect lambda_i of a regressor, which
* allows for the indirect effects that arise from the historical correlations
* among the regressors (mutatis mutandis), as opposed to the ceteris paribus
* effect measured by the ordinary multiple-regression coefficient beta_i.
*
* Reference:
*   Pesaran, M.H. and Smith, R.P. (2014). Signs of impact effects in time
*   series regression models. Economics Letters 122(1), 150-153.
*   doi:10.1016/j.econlet.2013.11.015

program define totimpact, rclass
    version 14.0

    // ------------------------------------------------------------------
    // Parse: standalone  ->  totimpact depvar indepvars [if][in] [, opts]
    //        postestim.   ->  totimpact           [if][in] [, opts]
    // ------------------------------------------------------------------
    gettoken first : 0, parse(" ,")
    local ispost = 0
    if ("`first'"=="" | "`first'"=="," | "`first'"=="if" | "`first'"=="in") {
        local ispost = 1
    }

    if (`ispost') {
        syntax [if] [in] [, Focus(varlist numeric) Level(cilevel) ///
                            GAMMA GRAPh PLOTs(string) Name(string) ///
                            SAVing(string) noHEADer ]
        _ti_efetch
        local dv    "`r(dv)'"
        local ivars "`r(ivars)'"
    }
    else {
        gettoken dv 0 : 0
        syntax varlist(numeric) [if] [in] [, Focus(varlist numeric) ///
                            Level(cilevel) GAMMA GRAPh PLOTs(string) ///
                            Name(string) SAVing(string) noHEADer ]
        confirm numeric variable `dv'
        local ivars "`varlist'"
    }

    // ------------------------------------------------------------------
    // Sample
    // ------------------------------------------------------------------
    marksample touse, novarlist
    if (`ispost') {
        qui replace `touse' = 0 if !e(sample)
    }
    markout `touse' `dv' `ivars'

    local nv : word count `ivars'
    if (`nv'==0) {
        di as error "no regressors specified"
        exit 102
    }

    // Default focus = every regressor; validate a user-supplied subset.
    if ("`focus'"=="") local focus "`ivars'"
    foreach fv of local focus {
        local ok : list fv in ivars
        if (!`ok') {
            di as error "focus variable {bf:`fv'} is not among the regressors"
            exit 198
        }
    }

    // ------------------------------------------------------------------
    // Engine
    // ------------------------------------------------------------------
    tempname res gam stat
    mata: _totimpact_engine("`dv'", "`ivars'", "`touse'", ///
                            "`res'", "`gam'", "`stat'")

    local omega2 = `stat'[1,1]
    local df     = `stat'[1,2]
    local N      = `stat'[1,3]
    local k      = `stat'[1,4]

    if (`df' < 1) {
        di as error "too few observations: residual d.f. = `df'"
        exit 2001
    }

    matrix rownames `res' = `ivars'
    matrix colnames `res' = direct indirect total se adj
    matrix rownames `gam' = `ivars'
    matrix colnames `gam' = `ivars'

    local alpha = (100-`level')/200
    local tcrit = invttail(`df', `alpha')

    // ------------------------------------------------------------------
    // Header
    // ------------------------------------------------------------------
    if ("`header'"!="noheader") {
        di ""
        di as txt "Total impact effects (Pesaran & Smith, 2014)"
        di as txt "Outcome variable: " as res "`dv'"
        di as txt "Observations = " as res `N' as txt ///
                  "   Regressors = " as res `k' ///
                  as txt "   Residual d.f. = " as res `df'
        di as txt "Root MSE (full model, omega) = " as res %9.4f sqrt(`omega2')
        di as txt "{hline 73}"
        di as txt %-13s "Variable" ///
                  %10s "Direct" %10s "Indirect" %10s "Total" ///
                  %11s "Std.Err." %9s "t" %9s "P>|t|"
        di as txt "{hline 73}"
    }

    // ------------------------------------------------------------------
    // Per-focus rows + build return table
    // ------------------------------------------------------------------
    tempname rtab
    local rn ""
    local flipped ""
    foreach fv of local focus {
        local idx : list posof "`fv'" in ivars

        local b   = `res'[`idx',1]
        local ind = `res'[`idx',2]
        local tot = `res'[`idx',3]
        local se  = `res'[`idx',4]

        local t  = `tot'/`se'
        local p  = 2*ttail(`df', abs(`t'))
        local ll = `tot' - `tcrit'*`se'
        local ul = `tot' + `tcrit'*`se'

        local star ""
        if (`p'<.10)  local star "*"
        if (`p'<.05)  local star "**"
        if (`p'<.01)  local star "***"

        // sign-flip flag: total effect has opposite sign to the coefficient
        local flip = 0
        if (`b'!=0 & sign(`tot')!=sign(`b')) local flip = 1
        if (`flip') local flipped "`flipped' `fv'"

        if ("`header'"!="noheader") {
            di as txt %-13s abbrev("`fv'",12) ///
               as res %10.4f `b' %10.4f `ind' %10.4f `tot' ///
               %11.4f `se' %9.3f `t' %9.3f `p' as txt "`star'"
        }

        matrix `rtab' = nullmat(`rtab') \ ///
              (`b', `ind', `tot', `se', `t', `p', `ll', `ul')
        local rn "`rn' `fv'"
    }

    if ("`header'"!="noheader") {
        di as txt "{hline 73}"
        di as txt "Total = Direct + Indirect. Std.Err. and t use omega from the"
        di as txt "full multiple regression (eq. 21); * p<.10  ** p<.05  *** p<.01."
        if ("`flipped'"!="") {
            di as err "Sign reversal (Total vs Direct) for:`flipped'"
        }
    }

    matrix colnames `rtab' = direct indirect total se t p ll ul
    matrix rownames `rtab' = `rn'

    // ------------------------------------------------------------------
    // Optional gamma (co-movement) matrix display
    // ------------------------------------------------------------------
    if ("`gamma'"!="") {
        di ""
        di as txt "Co-movement coefficients gamma_ji = cov(x_j,x_i)/var(x_i)"
        di as txt "(column i = response of every regressor to a shift in x_i)"
        matlist `gam', format(%8.4f)
    }

    // ------------------------------------------------------------------
    // Optional graphs (built-in twoway; drawn BEFORE any return-matrix move)
    // ------------------------------------------------------------------
    local dograph 0
    if ("`plots'"!="") {
        local glist = lower(trim("`plots'"))
        local dograph 1
    }
    else if ("`graph'"!="") {
        local glist "all"
        local dograph 1
    }

    if (`dograph') {
        if (strpos(" `glist' ", " all ")) local glist "compare decompose gamma"
        local sel ""
        foreach g of local glist {
            if ("`g'"=="decomp") local g "decompose"
            if (!inlist("`g'","compare","decompose","gamma")) {
                di as error "plots(): unknown plot type {bf:`g'} " ///
                            "(choose compare, decompose, gamma, or all)"
                exit 198
            }
            local sel "`sel' `g'"
        }
        local sel : list uniq sel
        local nplot : word count `sel'

        local fnm "totimpact"
        if ("`name'"!="") local fnm "`name'"

        if (`nplot'==1) {
            if ("`sel'"=="compare") ///
                _ti_g_compare   `res' "`focus'" "`ivars'" "`dv'" `df' `tcrit' `fnm' ""
            if ("`sel'"=="decompose") ///
                _ti_g_decompose `res' "`focus'" "`ivars'" "`dv'" `fnm' ""
            if ("`sel'"=="gamma") ///
                _ti_g_gamma     `gam' "`ivars'" `fnm' ""
        }
        else {
            tempname G1 G2 G3
            local slots "`G1' `G2' `G3'"
            local drawn ""
            local i 0
            foreach g of local sel {
                local ++i
                local nm : word `i' of `slots'
                if ("`g'"=="compare") ///
                    _ti_g_compare   `res' "`focus'" "`ivars'" "`dv'" `df' `tcrit' `nm' "nodraw"
                if ("`g'"=="decompose") ///
                    _ti_g_decompose `res' "`focus'" "`ivars'" "`dv'" `nm' "nodraw"
                if ("`g'"=="gamma") ///
                    _ti_g_gamma     `gam' "`ivars'" `nm' "nodraw"
                local drawn "`drawn' `nm'"
            }
            graph combine `drawn', name(`fnm', replace) ///
                  title("Total impact effects: `dv'", size(medium)) ///
                  subtitle("Pesaran & Smith (2014)", size(small))
        }
        if (`"`saving'"'!="") quietly graph save `fnm' `"`saving'"', replace
    }

    // ------------------------------------------------------------------
    // Returned results
    // ------------------------------------------------------------------
    tempname bvec lvec
    matrix `bvec' = `res'[1...,1]'
    matrix `lvec' = `res'[1...,3]'
    matrix colnames `bvec' = `ivars'
    matrix colnames `lvec' = `ivars'

    return matrix table  = `rtab'
    return matrix gamma  = `gam'
    return matrix lambda = `lvec'
    return matrix direct = `bvec'
    return scalar rmse   = sqrt(`omega2')
    return scalar df     = `df'
    return scalar k      = `k'
    return scalar N      = `N'
    return local focus   "`focus'"
    return local depvar  "`dv'"
    return local cmd     "totimpact"
end

// ----------------------------------------------------------------------
// Fetch depvar / regressors from a stored regress fit (postestimation)
// ----------------------------------------------------------------------
program define _ti_efetch, rclass
    if ("`e(cmd)'"=="") {
        di as error "no estimation results found; either give a varlist or"
        di as error "run {cmd:regress} first, then {cmd:totimpact}"
        exit 301
    }
    if ("`e(cmd)'"!="regress") {
        di as error "totimpact postestimation requires {cmd:regress};" ///
                    " found e(cmd) = `e(cmd)'"
        exit 301
    }
    local dv "`e(depvar)'"
    local iv : colnames e(b)
    local iv : subinstr local iv "_cons" "", word
    return local dv    "`dv'"
    return local ivars "`iv'"
end

// ----------------------------------------------------------------------
// Graph 1 -- direct vs total, with a confidence spike on the total effect
// ----------------------------------------------------------------------
program define _ti_g_compare
    args res focus ivars dv df tcrit gname nodraw

    tempname C
    local ylab ""
    local r 0
    foreach fv of local focus {
        local ++r
        local idx : list posof "`fv'" in ivars
        local b   = `res'[`idx',1]
        local tot = `res'[`idx',3]
        local se  = `res'[`idx',4]
        matrix `C' = nullmat(`C') \ ///
              (`r', `b', `tot', `tot'-`tcrit'*`se', `tot'+`tcrit'*`se')
        local ylab `"`ylab' `r' "`=abbrev("`fv'",14)'""'
    }
    matrix colnames `C' = idx direct total ll ul

    preserve
        clear
        quietly svmat double `C', names(col)
        twoway (rspike ll ul idx, horizontal lcolor(navy) lwidth(medthick)) ///
               (scatter idx total,  msymbol(O)  mcolor(navy)      msize(medlarge)) ///
               (scatter idx direct, msymbol(Th) mcolor(cranberry) msize(medlarge)), ///
               yscale(reverse) ylabel(`ylab', angle(0) noticks nogrid) ///
               ymtick(none) ///
               xline(0, lpattern(dash) lcolor(gs9)) ///
               legend(order(2 "Total impact ({&lambda})" 3 "Direct ({&beta})") ///
                      rows(1) pos(6) size(small)) ///
               xtitle("Effect on `dv'") ytitle("") ///
               title("Direct vs total impact", size(medium)) ///
               note("Spike: CI for the total impact effect", size(vsmall)) ///
               name(`gname', replace) `nodraw'
    restore
end

// ----------------------------------------------------------------------
// Graph 2 -- decomposition of the total effect into direct + indirect
// ----------------------------------------------------------------------
program define _ti_g_decompose
    args res focus ivars dv gname nodraw

    tempname D
    local xlab ""
    local r 0
    foreach fv of local focus {
        local ++r
        local idx : list posof "`fv'" in ivars
        local b   = `res'[`idx',1]
        local tot = `res'[`idx',3]
        local ind = `tot' - `b'
        matrix `D' = nullmat(`D') \ (`r', `b', `ind', `tot')
        local xlab `"`xlab' `r' "`=abbrev("`fv'",12)'""'
    }
    matrix colnames `D' = dx direct indirect total
    local xhi = `r' + 0.6

    // Three bars from zero per regressor (side by side): Direct, Indirect,
    // Total. This stays unambiguous even when Total reverses Direct's sign.
    preserve
        clear
        quietly svmat double `D', names(col)
        gen xd = dx - 0.25
        gen xi = dx
        gen xt = dx + 0.25
        twoway (bar direct   xd, barwidth(0.24) color(navy)) ///
               (bar indirect xi, barwidth(0.24) color(orange)) ///
               (bar total    xt, barwidth(0.24) color(forest_green)), ///
               yline(0, lcolor(gs9)) ///
               xlabel(`xlab', noticks) xscale(range(0.4 `xhi')) ///
               legend(order(1 "Direct ({&beta})" 2 "Indirect" ///
                            3 "Total ({&lambda})") rows(1) pos(6) size(small)) ///
               ytitle("Effect on `dv'") xtitle("") ///
               title("Direct + indirect = total", size(medium)) ///
               note("Direct {&beta}{sub:i} + indirect = total impact {&lambda}{sub:i}", ///
                    size(vsmall)) ///
               name(`gname', replace) `nodraw'
    restore
end

// ----------------------------------------------------------------------
// Graph 3 -- heatmap of the co-movement coefficients gamma_ji
// ----------------------------------------------------------------------
program define _ti_g_gamma
    args gam ivars gname nodraw

    local k : word count `ivars'
    tempname L
    matrix `L' = J(`k'*`k', 3, .)
    local r 0
    forvalues i = 1/`k' {
        forvalues j = 1/`k' {
            local ++r
            matrix `L'[`r',1] = `i'
            matrix `L'[`r',2] = `j'
            matrix `L'[`r',3] = `gam'[`j',`i']
        }
    }
    matrix colnames `L' = gx gy gv

    local ax ""
    local i 0
    foreach v of local ivars {
        local ++i
        local ax `"`ax' `i' "`=abbrev("`v'",10)'""'
    }
    local hi = `k' + 0.5
    local sz = cond(`k'<=3, 6, cond(`k'<=6, 4, 2.5))

    preserve
        clear
        quietly svmat double `L', names(col)
        gen byte bin = 3
        quietly replace bin = 1 if gv <  -0.50
        quietly replace bin = 2 if gv >= -0.50 & gv < -0.10
        quietly replace bin = 3 if gv >= -0.10 & gv <  0.10
        quietly replace bin = 4 if gv >=  0.10 & gv <  0.50
        quietly replace bin = 5 if gv >=  0.50
        gen str8 lbl = string(gv, "%4.2f")
        twoway (scatter gy gx if bin==1, msymbol(S) msize(*`sz') mcolor(maroon)) ///
               (scatter gy gx if bin==2, msymbol(S) msize(*`sz') mcolor(orange)) ///
               (scatter gy gx if bin==3, msymbol(S) msize(*`sz') mcolor(gs12)) ///
               (scatter gy gx if bin==4, msymbol(S) msize(*`sz') mcolor(ltblue)) ///
               (scatter gy gx if bin==5, msymbol(S) msize(*`sz') mcolor(navy)) ///
               (scatter gy gx if inlist(bin,1,5), msymbol(i) mlabel(lbl) ///
                      mlabpos(0) mlabcolor(white) mlabsize(small)) ///
               (scatter gy gx if inlist(bin,2,3,4), msymbol(i) mlabel(lbl) ///
                      mlabpos(0) mlabcolor(black) mlabsize(small)), ///
               legend(off) ///
               xlabel(`ax', noticks) ylabel(`ax', angle(0) noticks) ///
               xscale(range(0.5 `hi')) yscale(range(0.5 `hi') reverse) ///
               xtitle("shift in x{sub:i}  (column)") ///
               ytitle("response of x{sub:j}  (row)") ///
               title("Co-movement {&gamma}{sub:ji}", size(medium)) ///
               note("{&gamma}{sub:ji} = cov(x{sub:j},x{sub:i}) / var(x{sub:i})", ///
                    size(vsmall)) ///
               name(`gname', replace) `nodraw'
    restore
end

// ----------------------------------------------------------------------
// Mata engine
// ----------------------------------------------------------------------
version 14.0
mata:

void _totimpact_engine(string scalar yv, string scalar xv, string scalar tv,
                       string scalar resnm, string scalar gamnm,
                       string scalar statnm)
{
    real colvector  y, yc, dgSXX, beta, lambda, indirect, se, seN, adj
    real matrix     X, Xc, SXX, gamma
    real colvector  SXy, rssN, o2N
    real scalar     T, k, sst, rss, dfres, omega2

    y = st_data(., yv, tv)
    X = st_data(., tokens(xv), tv)
    T = rows(X)
    k = cols(X)

    // demean (c-conformable: T x k  minus  1 x k)
    yc = y :- mean(y)
    Xc = X :- mean(X)

    SXX = quadcross(Xc, Xc)        // k x k  = (T-1) * cov(X)
    SXy = quadcross(Xc, yc)        // k x 1
    sst = quadcross(yc, yc)        // scalar

    // full multiple-regression slopes (intercept absorbed by demeaning)
    beta   = invsym(SXX) * SXy
    dgSXX  = diagonal(SXX)

    // Total impact effect: lambda_i = cov(y,x_i)/var(x_i) = SXy_i / SXX_ii
    // (identical to the simple-regression slope of y on x_i, Pesaran-Smith eq.19)
    lambda   = SXy :/ dgSXX
    indirect = lambda - beta

    dfres  = T - k - 1
    rss    = sst - beta' * SXy     // 1 x 1
    omega2 = rss / dfres

    // Corrected standard error uses omega from the FULL model (eq. 21)
    se = sqrt(omega2 :/ dgSXX)

    // Naive simple-regression sigma_i, only to report the omega_i/omega factor
    rssN = sst :- (lambda:^2 :* dgSXX)
    o2N  = rssN :/ (T - 2)
    seN  = sqrt(o2N :/ dgSXX)
    adj  = seN :/ se

    // gamma_ji = SXX_ji / SXX_ii (each column i scaled by its diagonal)
    gamma = SXX :/ dgSXX'

    st_matrix(resnm,  (beta, indirect, lambda, se, adj))
    st_matrix(gamnm,  gamma)
    st_matrix(statnm, (omega2, dfres, T, k, sst))
}

end
