*! version 0.1.0 08jun2026
program define ordaxaca, eclass sortpreserve
    version 17.0

    if replay() {
        if "`e(cmd)'" != "ordaxaca" {
            error 301
        }
        _ordaxaca_display
        exit
    }

    syntax varlist(fv numeric min=2) [if] [in] [fw aw pw iw], ///
        BY(varname numeric) ///
        BASE(real) ///
        COMPare(real) ///
        [ MODEL(string) OUTcomes(numlist) SVY ESTOPts(string asis) ]

    marksample touse
    markout `touse' `by'

    gettoken depvar indepvars : varlist

    if "`model'" == "" local model "ologit"
    local model = lower("`model'")

    if !inlist("`model'", "ologit", "oprobit") {
        di as err "model() must be ologit or oprobit"
        exit 198
    }

    if `base' == `compare' {
        di as err "base() and compare() must identify different groups"
        exit 198
    }

    if "`svy'" != "" & "`weight'" != "" {
        di as err "When svy is specified, set weights using svyset, not command weights"
        exit 198
    }

    local wgt ""
    if "`weight'" != "" {
        local wgt "[`weight'`exp']"
    }

    quietly count if `touse' & `by' == `base'
    local Nbase = r(N)

    quietly count if `touse' & `by' == `compare'
    local Ncomp = r(N)

    if `Nbase' == 0 {
        di as err "No observations found for base(`base')"
        exit 2000
    }

    if `Ncomp' == 0 {
        di as err "No observations found for compare(`compare')"
        exit 2000
    }

    if "`outcomes'" == "" {
        quietly levelsof `depvar' if `touse' & inlist(`by', `base', `compare'), local(outcomes)
    }

    local K : word count `outcomes'

    if `K' == 0 {
        di as err "No outcome categories found"
        exit 2000
    }

    tempname estbase estcomp
    tempname R b V M
    tempname mean_base mean_comp mean_cf diff explained unexplained

    /*
        Estimate ordered model for the base group.
        For survey data, use subpop() rather than dropping the other group.
    */

    if "`svy'" != "" {
        quietly svy, subpop(if `touse' & `by' == `base'): ///
            `model' `depvar' `indepvars', `estopts'
    }
    else {
        quietly `model' `depvar' `indepvars' ///
            if `touse' & `by' == `base' `wgt', `estopts'
    }

    estimates store `estbase'

    /*
        Estimate ordered model for the comparison group.
    */

    if "`svy'" != "" {
        quietly svy, subpop(if `touse' & `by' == `compare'): ///
            `model' `depvar' `indepvars', `estopts'
    }
    else {
        quietly `model' `depvar' `indepvars' ///
            if `touse' & `by' == `compare' `wgt', `estopts'
    }

    estimates store `estcomp'

    /*
        Result matrix:
        outcome
        base_mean     = mean Pr(Y = k | X_base, beta_base)
        cf_mean       = mean Pr(Y = k | X_compare, beta_base)
        compare_mean  = mean Pr(Y = k | X_compare, beta_compare)
        diff          = base_mean - compare_mean
        explained     = base_mean - cf_mean
        unexplained   = cf_mean - compare_mean
    */

    matrix `R' = J(`K', 7, .)
    matrix colnames `R' = outcome base_mean cf_mean compare_mean diff explained unexplained

    matrix `b' = J(1, 3 * `K', .)

    local rownames ""
    local colnames ""

    local r = 1
    local cindex = 1

    foreach ycat of numlist `outcomes' {

        tempvar p_base p_comp

        /*
            Predictions from base-group model.
        */

		quietly estimates restore `estbase'
        quietly predict double `p_base' if `touse', outcome(`ycat')

        if "`svy'" != "" {
            quietly svy, subpop(if `touse' & `by' == `base'): mean `p_base'
            scalar `mean_base' = _b[`p_base']

            quietly svy, subpop(if `touse' & `by' == `compare'): mean `p_base'
            scalar `mean_cf' = _b[`p_base']
        }
        else {
            quietly mean `p_base' if `touse' & `by' == `base' `wgt'
            matrix `M' = e(b)
            scalar `mean_base' = `M'[1,1]

            quietly mean `p_base' if `touse' & `by' == `compare' `wgt'
            matrix `M' = e(b)
            scalar `mean_cf' = `M'[1,1]
        }

        /*
            Predictions from comparison-group model.
        */

        quietly estimates restore `estcomp'
        quietly predict double `p_comp' if `touse', outcome(`ycat')

        if "`svy'" != "" {
            quietly svy, subpop(if `touse' & `by' == `compare'): mean `p_comp'
            scalar `mean_comp' = _b[`p_comp']
        }
        else {
            quietly mean `p_comp' if `touse' & `by' == `compare' `wgt'
            matrix `M' = e(b)
            scalar `mean_comp' = `M'[1,1]
        }

        scalar `diff'        = `mean_base' - `mean_comp'
        scalar `explained'   = `mean_base' - `mean_cf'
        scalar `unexplained' = `mean_cf'   - `mean_comp'

        matrix `R'[`r',1] = `ycat'
        matrix `R'[`r',2] = `mean_base'
        matrix `R'[`r',3] = `mean_cf'
        matrix `R'[`r',4] = `mean_comp'
        matrix `R'[`r',5] = `diff'
        matrix `R'[`r',6] = `explained'
        matrix `R'[`r',7] = `unexplained'

        matrix `b'[1,`cindex'] = `diff'
        local colnames "`colnames' diff_out`ycat'"
        local ++cindex

        matrix `b'[1,`cindex'] = `explained'
        local colnames "`colnames' expl_out`ycat'"
        local ++cindex

        matrix `b'[1,`cindex'] = `unexplained'
        local colnames "`colnames' unex_out`ycat'"
        local ++cindex

        local rownames "`rownames' out`ycat'"
        local ++r
    }

    matrix rownames `R' = `rownames'
    matrix colnames `b' = `colnames'

    matrix `V' = J(colsof(`b'), colsof(`b'), 0)
    matrix colnames `V' = `colnames'
    matrix rownames `V' = `colnames'

    ereturn post `b' `V', esample(`touse')
    ereturn matrix decomp = `R'

    ereturn local cmd "ordaxaca"
    ereturn local depvar "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local by "`by'"
    ereturn local model "`model'"
    ereturn local outcomes "`outcomes'"
    ereturn local base "`base'"
    ereturn local compare "`compare'"
    ereturn local svy "`svy'"
    ereturn scalar N_base = `Nbase'
    ereturn scalar N_compare = `Ncomp'

    _ordaxaca_display

    estimates drop `estbase' `estcomp'
    capture matrix drop __ordaxaca_R
end

program define _ordaxaca_display
    version 17.0

    tempname D
    matrix `D' = e(decomp)

    di as text ""
    di as text "Nonlinear Oaxaca decomposition for ordered outcomes"
    di as text "{hline 72}"
    di as text "Model:           " as result "`e(model)'"
    di as text "Dependent var.:  " as result "`e(depvar)'"
    di as text "Group variable:  " as result "`e(by)'"
    di as text "Base group:      " as result "`e(base)'" ///
        as text "   N = " as result e(N_base)
    di as text "Compare group:   " as result "`e(compare)'" ///
        as text "   N = " as result e(N_compare)

    if "`e(svy)'" != "" {
        di as text "Survey design:   " as result "svyset design used"
    }

    di as text "{hline 72}"
    di as text "Decomposition results"
    di as text "{hline 72}"

    matlist `D', names(columns) format(%12.6f)

    di as text "{hline 72}"
    di as text "Diff        = Base - Compare"
    di as text "Explained   = Base - Counterfactual"
    di as text "Unexplained = Counterfactual - Compare"
    di as text ""
end