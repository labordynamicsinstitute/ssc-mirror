*! version 1.0.0 24apr2026 Leonhard Benedikt Friedel
capture program drop multisynth
program define multisynth, rclass
    version 16.0

    syntax varname(numeric) [if] [in], ///
        UNIT(varname numeric) ///
        TIME(varname numeric) ///
        TREATED(varname numeric) ///
        POST(varname numeric) ///
        [CONTROLS(varlist numeric) CTRLWEIGHT(real 0.25) SAVING(string) REPLACE WSAVING(string) WREPLACE GRAPH]

    marksample touse
    local y `varlist'
    preserve

    capture assert inlist(`treated', 0, 1) if `touse' & !missing(`treated')
    if _rc {
        di as err "treated() must contain only 0/1 values in the estimation sample"
        exit 459
    }

    capture assert inlist(`post', 0, 1) if `touse' & !missing(`post')
    if _rc {
        di as err "post() must contain only 0/1 values in the estimation sample"
        exit 459
    }

    if `ctrlweight' < 0 {
        di as err "ctrlweight() must be nonnegative"
        exit 198
    }

    if "`saving'" != "" & "`replace'" == "" {
        capture confirm new file "`saving'"
        if _rc {
            di as err "file already exists; specify replace to overwrite"
            exit 602
        }
    }

    if "`wsaving'" != "" & "`wreplace'" == "" {
        capture confirm new file "`wsaving'"
        if _rc {
            di as err "wsaving() file already exists; specify wreplace to overwrite"
            exit 602
        }
    }

    quietly keep if `touse'
    keep `unit' `time' `treated' `post' `y' `controls'
    quietly count
    if r(N) == 0 {
        di as err "no observations in sample"
        restore
        exit 2000
    }

    sort `unit' `time'

    capture isid `unit' `time'
    if _rc {
        di as err "unit() and time() must uniquely identify observations"
        restore
        exit 459
    }

    by `unit': egen __treated_min = min(`treated')
    by `unit': egen __treated_max = max(`treated')
    capture assert __treated_min == __treated_max
    if _rc {
        di as err "treated() must be constant within unit"
        restore
        exit 459
    }

    capture by `unit' (`time'): assert `post' >= `post'[_n-1] if _n > 1
    if _rc {
        di as err "post() must not switch from 1 back to 0 within unit"
        restore
        exit 459
    }

    capture assert (`treated' == 0 & `post' == 0) | (`treated' == 1)
    if _rc {
        di as err "never-treated units must have post() == 0 in all periods"
        restore
        exit 459
    }

    quietly gen double __treat_time_candidate = `time' if `post' == 1
    by `unit': egen __first_treat = min(__treat_time_candidate)
    drop __treat_time_candidate

    capture assert !missing(__first_treat) if `treated' == 1
    if _rc {
        di as err "treated() == 1 units must have at least one period with post() == 1"
        restore
        exit 459
    }

    quietly levelsof `unit' if `treated' == 1, local(treated_units)
    local n_treated : word count `treated_units'
    if `n_treated' == 0 {
        di as err "no treated units found; no unit has treated() == 1"
        restore
        exit 2000
    }

    quietly summarize `unit', meanonly
    local max_unit = r(max)

    drop __treated_min __treated_max

    quietly {

    tempfile base clone_rows treated_full alltimes treated_pre pretimes donor_full donor_ywide donor_ctrlmeans weightscur synthcur augmented weights_long
    save "`base'", replace

    use "`base'", clear
    keep if 0
    gen byte clone = .
    gen byte donor = .
    gen double source_unit = .
    gen double ms_id = .
    gen double event_time = .
    save "`clone_rows'", replace

    use "`base'", clear
    keep if 0
    keep `unit'
    rename `unit' donor_unit
    gen double source_unit = .
    gen double weight      = .
    gen long   __rank      = .
    gen double pre_rmspe   = .
    gen double pre_r2      = .
    save "`weights_long'", replace

    local completed = 0
    local skipped = 0
    local clone_index = 0

    foreach tu of local treated_units {
        use "`base'", clear
        quietly summarize __first_treat if `unit' == `tu', meanonly
        local treat_time = r(min)

        keep if `unit' == `tu'
        sort `time'
        quietly count
        local Tfull = r(N)
        if `Tfull' == 0 {
            local ++skipped
            continue
        }

        gen long __seq = _n
        quietly summarize __seq if `post' == 1, meanonly
        if missing(r(min)) {
            local ++skipped
            continue
        }
        local firstpostseq = r(min)

        gen double event_time = __seq - `firstpostseq'
        replace event_time = event_time + 1 if event_time >= 0
        save "`treated_full'", replace

        keep `time'
        save "`alltimes'", replace

        use "`treated_full'", clear
        keep if `post' == 0
        quietly count
        local Tpre = r(N)
        if `Tpre' == 0 {
            local ++skipped
            continue
        }

        gen long __pre_index = _n
        save "`treated_pre'", replace

        keep `time' __pre_index
        save "`pretimes'", replace

        use "`base'", clear
        keep if `treated' == 0
        drop if `unit' == `tu'

        quietly merge m:1 `time' using "`alltimes'", keep(match) nogenerate
        drop if missing(`y')
        foreach x of local controls {
            drop if missing(`x')
        }

        sort `unit' `time'
        by `unit': egen __nfull = count(`time')
        keep if __nfull == `Tfull'

        quietly levelsof `unit', local(eligible_donors)
        local J : word count `eligible_donors'
        if `J' == 0 {
            local ++skipped
            continue
        }

        save "`donor_full'", replace

        quietly merge m:1 `time' using "`pretimes'", keep(match) nogenerate
        sort `unit' __pre_index
        keep `unit' __pre_index `y'
        quietly reshape wide `y', i(`unit') j(__pre_index)
        sort `unit'
        save "`donor_ywide'", replace

        if "`controls'" != "" {
            use "`donor_full'", clear
            quietly merge m:1 `time' using "`pretimes'", keep(match) nogenerate
            collapse (mean) `controls', by(`unit')
            sort `unit'
            save "`donor_ctrlmeans'", replace
        }

        use "`treated_pre'", clear
        mkmat `y', matrix(y_pre)
        if "`controls'" != "" {
            collapse (mean) `controls'
            mkmat `controls', matrix(xbar)
        }
        else {
            capture matrix drop xbar
        }

        use "`donor_ywide'", clear
        sort `unit'
        mkmat `y'*, matrix(DY)

        if "`controls'" != "" {
            use "`donor_ctrlmeans'", clear
            sort `unit'
            mkmat `controls', matrix(DX)
            local has_controls = 1
        }
        else {
            capture matrix drop DX
            local has_controls = 0
        }

        quietly mata: multisynth_run(`ctrlweight', `has_controls')

        use "`donor_ywide'", clear
        sort `unit'
        gen double weight = .
        quietly count
        local J = r(N)
        forvalues j = 1/`J' {
            replace weight = el(W, 1, `j') in `j'
        }
        keep `unit' weight
        save "`weightscur'", replace

        local cur_rmspe = __ms_rmspe
        local cur_r2    = __ms_r2
        use "`weightscur'", clear
        gsort -weight
        gen long   __rank      = _n
        gen double source_unit = `tu'
        gen double pre_rmspe   = `cur_rmspe'
        gen double pre_r2      = `cur_r2'
        rename `unit' donor_unit
        append using "`weights_long'"
        save "`weights_long'", replace

        use "`donor_full'", clear
        quietly merge m:1 `unit' using "`weightscur'", keep(match) nogenerate
        gen double __wy = weight * `y'
        foreach x of local controls {
            gen double __w_`x' = weight * `x'
        }

        if "`controls'" == "" {
            collapse (sum) synth_y = __wy, by(`time')
        }
        else {
            local synthspec
            foreach x of local controls {
                local synthspec `synthspec' (sum) synth_`x' = __w_`x'
            }
            collapse (sum) synth_y = __wy `synthspec', by(`time')
        }
        save "`synthcur'", replace

        use "`treated_full'", clear
        merge 1:1 `time' using "`synthcur'", keep(match) nogenerate
        replace `y' = synth_y
        drop synth_y
        foreach x of local controls {
            replace `x' = synth_`x'
            drop synth_`x'
        }

        local ++clone_index
        replace `treated' = 0
        gen byte clone = 1
        gen byte donor = 0
        gen double source_unit = `tu'
        gen double ms_id = `max_unit' + `clone_index'
        capture drop __*
        append using "`clone_rows'"
        save "`clone_rows'", replace

        local ++completed
    }

    if `completed' == 0 {
        noisily di as err "no treated units could be processed with the available donor support"
        restore
        exit 2001
    }

    use "`base'", clear
    sort `unit' `time'
    by `unit': gen long __seq = _n
    quietly gen double __first_post_seq_candidate = __seq if `post' == 1
    by `unit': egen __first_post_seq = min(__first_post_seq_candidate)
    drop __first_post_seq_candidate

    quietly gen double event_time = .
    quietly replace event_time = __seq - __first_post_seq if `treated' == 1
    quietly replace event_time = event_time + 1 if `treated' == 1 & event_time >= 0

    gen byte clone = 0
    gen byte donor = (`treated' == 0)
    gen double source_unit = `unit'
    gen double ms_id = `unit'
    capture drop __*

    append using "`clone_rows'"
    capture drop __*
    sort ms_id `time'
    save "`augmented'", replace

    } // end quietly

    if "`saving'" != "" {
        save "`saving'", `replace'
    }

    if "`wsaving'" != "" {
        quietly {
            use "`weights_long'", clear
            reshape wide donor_unit weight, i(source_unit pre_rmspe pre_r2) j(__rank)
            quietly ds donor_unit*
            local maxrank : word count `r(varlist)'
            foreach v of varlist donor_unit* {
                local num = substr("`v'", 11, .)
                rename `v' donor_`num'
            }
            foreach v of varlist weight* {
                local num = substr("`v'", 7, .)
                rename `v' w_`num'
            }
            local ordervars source_unit
            forvalues r = 1/`maxrank' {
                local ordervars `ordervars' donor_`r' w_`r'
            }
            local ordervars `ordervars' pre_rmspe pre_r2
            order `ordervars'
        }
        if "`wreplace'" != "" local wreplace_opt replace
        save "`wsaving'", `wreplace_opt'
    }

    return scalar treated_units_total = `n_treated'
    return scalar treated_units_completed = `completed'
    return scalar treated_units_skipped = `skipped'
    return scalar ctrlweight = `ctrlweight'
    return scalar clone_units_added = `completed'
    if "`saving'" != "" {
        return local saved_file "`saving'"
    }
    if "`wsaving'" != "" {
        return local wsaved_file "`wsaving'"
    }
    restore
    use "`augmented'", clear

    if "`graph'" != "" {
        preserve
            quietly keep if (`treated' == 1 & clone == 0) | clone == 1
            quietly gen double __treated_y = `y' if `treated' == 1 & clone == 0
            quietly gen double __clone_y   = `y' if clone == 1
            collapse (mean) treated_y = __treated_y clone_y = __clone_y, by(event_time)
            twoway ///
                (line treated_y event_time, lcolor(navy) lwidth(medthick)) ///
                (line clone_y   event_time, lcolor(maroon) lpattern(dash) lwidth(medthick)), ///
                xline(0, lcolor(gs8) lpattern(shortdash)) ///
                xtitle("Event time") ///
                ytitle("Average outcome") ///
                legend(order(1 "Observed treated" 2 "Synthetic clone")) ///
                title("Average observed and synthetic paths")
        restore
    }
end

mata:
real colvector multisynth_softmax(real colvector theta)
{
    real scalar m
    real colvector z
    m = max(theta)
    z = exp(theta :- m)
    return(z :/ sum(z))
}

real rowvector multisynth_optimize(real matrix Y,
                                   real colvector y,
                                   real matrix X,
                                   real colvector x,
                                   real scalar ctrlw)
{
    real colvector theta, w, resid, dL_dw, grad
    real scalar T, K, lr, iter

    T     = rows(Y)
    theta = J(cols(Y), 1, 0)
    lr    = 0.05

    for (iter = 1; iter <= 2000; iter++) {
        w     = multisynth_softmax(theta)
        resid = y :- Y * w
        dL_dw = (-2 / T) * (Y' * resid)

        if (ctrlw > 0 & rows(X) > 0) {
            K     = rows(x)
            dL_dw = dL_dw :+ ctrlw * (-2 / K) * (X' * (x :- X * w))
        }

        // softmax Jacobian-vector product: (diag(w) - w*w') * dL_dw
        grad  = w :* dL_dw :- w * (w' * dL_dw)

        if (max(abs(grad)) < 1e-8) break
        theta = theta :- lr * grad
    }

    return(multisynth_softmax(theta)')
}

void multisynth_run(real scalar ctrlw, real scalar hasctrl)
{
    real matrix Y, X
    real colvector y, x, yhat, resid
    real rowvector W
    real scalar ymean, ss_res, ss_tot

    Y = st_matrix("DY")'
    y = st_matrix("y_pre")

    if (hasctrl == 1) {
        X = st_matrix("DX")'
        x = st_matrix("xbar")'
    }
    else {
        X = J(0, cols(Y), .)
        x = J(0, 1, .)
    }

    W     = multisynth_optimize(Y, y, X, x, ctrlw)
    st_matrix("W", W)

    yhat   = Y * W'
    resid  = y :- yhat
    ymean  = mean(y)
    ss_res = sum(resid:^2)
    ss_tot = sum((y :- ymean):^2)
    st_numscalar("__ms_rmspe", sqrt(mean(resid:^2)))
    st_numscalar("__ms_r2",   (ss_tot == 0 ? 1 : 1 - ss_res / ss_tot))
}
end
