*! qnardl_mgraph v1.1.0  28may2026
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*! Plot dynamic multiplier paths from qnardl results.
*!
*! Per-variable panels showing m⁺(h), m⁻(h), and asymmetry m⁺−m⁻ at the
*! chosen quantile (defaults to median).
*!
*! Requires qnardl was run with the {opt multipliers} option.

program define qnardl_mgraph
    version 14.0

    syntax , [ TYpe(string) Tau(numlist max=1) SAVing(string) ///
               XSize(real 10) YSize(real 7) SCheme(string) ]

    if "`e(cmd)'" != "qnardl" {
        di as error "qnardl_mgraph: estimation results from qnardl required"
        exit 301
    }
    capture confirm matrix e(mult_pos)
    if _rc {
        di as error "qnardl_mgraph: no multiplier results in e()."
        di as error "  Re-run with: {bf:qnardl, multipliers(...)}"
        exit 198
    }

    if "`type'" == ""    local type "median"
    if "`scheme'" == ""  local scheme "s2color"

    capture set autotabgraphs on

    tempname mpos mneg
    matrix `mpos' = e(mult_pos)
    matrix `mneg' = e(mult_neg)
    local kasym = e(k)
    local horizon = e(horizon_mult)
    local Hp1 = `horizon' + 1
    local asymvars = e(asymvars)
    local taus : rownames `mpos'
    local ntau = rowsof(`mpos')

    // Pick the tau row to plot — default to closest to median
    local pickrow = 1
    if "`tau'" != "" {
        local pickrow = 0
        forvalues i = 1/`ntau' {
            local tv : word `i' of `taus'
            if abs(`tv' - `tau') < 1e-8  local pickrow = `i'
        }
        if `pickrow' == 0 {
            di as error "qnardl_mgraph: tau=`tau' was not estimated; available: `taus'"
            exit 198
        }
    }
    else {
        local mindist = .
        forvalues i = 1/`ntau' {
            local tv : word `i' of `taus'
            local d = abs(`tv' - 0.5)
            if `d' < `mindist' {
                local mindist = `d'
                local pickrow = `i'
            }
        }
    }
    local tau_show : word `pickrow' of `taus'

    preserve
    qui clear
    qui set obs `Hp1'
    qui gen int horizon = _n - 1

    forvalues j = 1/`kasym' {
        local vn : word `j' of `asymvars'
        qui gen double mp_`j' = .
        qui gen double mn_`j' = .
        qui gen double asym_`j' = .
        forvalues h = 0/`horizon' {
            local col = (`j' - 1) * `Hp1' + `h' + 1
            local mp = `mpos'[`pickrow', `col']
            local mn = `mneg'[`pickrow', `col']
            qui replace mp_`j' = `mp' in `=`h'+1'
            qui replace mn_`j' = `mn' in `=`h'+1'
            qui replace asym_`j' = `mp' - `mn' in `=`h'+1'
        }
    }

    local panels ""
    forvalues j = 1/`kasym' {
        local vn : word `j' of `asymvars'
        local gname "_qnmg_`j'"
        qui twoway (line mp_`j' horizon, lcolor(green) lwidth(medthick)) (line mn_`j' horizon, lcolor(orange_red) lwidth(medthick) lpattern(dash)) (line asym_`j' horizon, lcolor(cranberry) lwidth(thin) lpattern(shortdash)), yline(0, lcolor(gs10) lpattern(dot)) title(`"`vn'"', size(medsmall)) ytitle("Resp.", size(small)) xtitle("Horizon", size(small)) ylabel(, labsize(small) angle(horizontal)) xlabel(, labsize(small)) legend(order(1 "m{sup:+}" 2 "m{sup:-}" 3 "asym.") rows(1) size(small) region(lwidth(none))) plotregion(margin(small)) graphregion(margin(small)) scheme(`scheme') name(`gname', replace) nodraw
        local panels `panels' `gname'
    }

    local mcols = cond(`kasym' <= 2, `kasym', cond(`kasym' <= 4, 2, 3))
    if `kasym' == 1 {
        local solo : word 1 of `panels'
        graph display `solo', xsize(`xsize') ysize(`ysize')
    }
    else {
        graph combine `panels', cols(`mcols') imargin(small) title("QNARDL dynamic multipliers", size(medium)) subtitle(`"tau = `tau_show', H = `horizon'"', size(small)) xsize(`xsize') ysize(`ysize') name(qnardl_mult, replace)
        if "`saving'" != "" graph export "`saving'_mult.png", replace
    }
    restore

    forvalues j = 1/`kasym' {
        capture graph drop _qnmg_`j'
    }
    di as txt _n "qnardl_mgraph: multiplier paths plotted at tau = " `tau_show'
    di as txt "  Named graph in memory: " as res "qnardl_mult"
    di as txt "  Display later with:    {bf:graph display qnardl_mult}"
end
