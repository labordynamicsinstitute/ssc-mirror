*! _finegray_check_data Version 1.3.2  2026/09/08
*! Verify that post-estimation commands still see the finegray estimation data
*! Author: Timothy P Copeland, Karolinska Institutet
*! Program class: internal

capture program drop _finegray_check_data
program define _finegray_check_data
    version 16.0
    local _orig_varabbrev = c(varabbrev)
    set varabbrev off

    capture noisily {
        * The `_finegray_estimated' characteristic is stored in the DATASET, so
        * whether it is here depends on which copy of the data is in memory --
        * not on whether e() holds a finegray fit.  The natural cross-session
        * workflow saves the analysis data, fits, saves the estimates, and comes
        * back later:  use <data>  ->  estimates use <est>.  That data was
        * written BEFORE the fit and carries no characteristic, so this test
        * used to end at r(301) "re-run finegray" -- while finegray.sthlp
        * documents r(459) and the one-line `estimates esample:' repair for
        * exactly that workflow, and that repair does work.  (Saving the data
        * AFTER the fit carried the characteristic and did reach r(459), which
        * is why the released behaviour depended on save order.)
        *
        * Recognise the restored-estimates case -- a finegray fit in e() carrying
        * its data signature -- and let it through to the checks below, which
        * are the ones that can actually adjudicate it: the empty-sample branch
        * names the cause and the repair, and the signature comparison rejects a
        * sample re-declared over the wrong rows.  Nothing is computed here, so
        * the relaxation stays fail-closed at every exit.
        *
        * The test is deliberately NOT "and e(sample) is empty".  It was, and
        * that was self-defeating: the message tells the user to run
        * `estimates esample:', after which e(sample) is no longer empty and the
        * very next command hit r(301) again -- an instruction that could not be
        * followed.  What the characteristic uniquely carried is the entry-time
        * column of a multiple-record fit; that is now also in e(entryvar), and
        * the three post-estimation readers fall back to it, so a restored fit
        * that needs an entry column the data does not have stops by name
        * instead of quietly using per-record _t0.
        * "0" is the mark a fit writes when it starts mutating package-owned
        * columns, so it says the previous fit's state was DELIBERATELY
        * invalidated -- a re-fit began and did not finish.  That is never
        * adjudicable from e(): the prior fit's signature variables can be
        * untouched by the failed re-fit and would compare equal.  Refuse it
        * outright, and reserve the fall-through for a characteristic that is
        * simply absent.
        *
        * Ahead of all of that: a fit on mi data is refused here as well as
        * at each command's own entry point.  The entry-point guards give the
        * actionable message; this one exists so that a future post-estimation
        * path added without its own guard still fails closed rather than
        * resolving e(designvars) into tempvar names some other command has
        * since reused.
        if `"`e(postest)'"' == "unavailable_mi" {
            display as error "post-estimation is not available after a fit on mi data"
            display as error "refit on a single dataset ({bf:mi extract 0, clear} for the"
            display as error "complete-case data) and run {bf:finegray} there;"
            display as error "see {help finegray##mi:help finegray}"
            exit 301
        }

        * Results from a finegray that recorded the design columns as
        * e(covariates) carry the narrow coefficient stripe and no
        * e(designvars); this version's consumers read e(b) through the
        * non-base filter and would pair such results by luck.  Same refusal
        * as finegray_predict's entry, for the commands that come through here.
        if `"`e(designvars)'"' == "" & `"`e(covariates)'"' != "" {
            display as error "estimation results predate this version of finegray"
            display as error "e(designvars) is not set; re-run {bf:finegray} before this post-estimation command"
            exit 301
        }

        local _fg_state `"`_dta[_finegray_estimated]'"'
        local _fg_restored = 0
        if `"`_fg_state'"' != "1" {
            if `"`_fg_state'"' == "" & `"`e(cmd)'"' == "finegray" ///
                & `"`e(datasignature)'"' != "" {
                local _fg_restored = 1
            }
            if `_fg_restored' == 0 {
                display as error "finegray estimation state is not active"
                display as error "re-run {bf:finegray} before this post-estimation command"
                exit 301
            }
        }

        local _sig `"`e(datasignature)'"'
        local _sigvars `"`e(datasignaturevars)'"'
        if `"`_sig'"' == "" | `"`_sigvars'"' == "" {
            display as error "finegray estimation signature is not available"
            display as error "re-run {bf:finegray} before this post-estimation command"
            exit 301
        }

        * EXISTENCE only, not type: a weight expression may read a STRING
        * variable -- [pw = real(strvar)] -- and strvar is in the signature
        * because the rebuilt weight depends on it.  A type change is still
        * refused, by the signature comparison below: _datasignature checksums
        * a string variable differently from the numeric one it replaced.
        foreach _v of local _sigvars {
            capture confirm variable `_v'
            if _rc {
                display as error "estimation variable `_v' no longer exists"
                display as error "re-run {bf:finegray} before this post-estimation command"
                exit 459
            }
        }

        * An EMPTY e(sample) is a different failure and needs a different name.
        * `estimates use' restores e() but not the sample marker -- the marker
        * is a property of the data in memory, and a saved estimation set does
        * not carry one -- so the signature below is computed over zero rows,
        * comes back as `0:k:0:0', and compares unequal to the fit's.  Reported
        * as "data have changed" that sends the user hunting for a corruption
        * of data they never touched.  Name the real cause and the one command
        * that fixes it.  Kept ahead of the comparison for that reason only:
        * the comparison itself would reject this case anyway, with the wrong
        * message.  This is also the branch the missing-characteristic
        * fall-through above lands in.  Guarded by
        * test_finegray_estimates_use.do.
        quietly count if e(sample)
        if r(N) == 0 {
            display as error "the finegray estimation sample is empty"
            display as error "{bf:estimates use} restores e() but not e(sample), so no"
            display as error "observation is marked as having been used in the fit"
            display as error "re-declare it with {bf:estimates esample:} over the variables in"
            display as error "{bf:e(datasignaturevars)}, or re-run {bf:finegray}"
            exit 459
        }

        capture quietly _datasignature `_sigvars' if e(sample), nodefault nonames
        if _rc | `"`r(datasignature)'"' != `"`_sig'"' {
            display as error "data have changed since finegray was estimated"
            display as error "re-run {bf:finegray} before this post-estimation command"
            exit 459
        }

        * The package-owned _fg_* design columns are DERIVED from the raw factor
        * variables, so they are not in the data signature: dropping them is
        * supported, and the consumers that need them rebuild them on demand.
        * But a _fg_ column that is still present and no longer equals what the
        * fit-time expansion implies is tampering, and it is invisible to a
        * signature over the raw variables -- finegray_cif and finegray_phtest
        * read these columns by name, so flipping _fg_grp_2 silently moved the
        * CIF from 0.21287138 to 0.21088124 at rc 0.
        *
        * e(fvsemantic) lists the fit-time terms in order and e(designvars) the
        * columns they were stored in, so the two pair up positionally HERE --
        * both were written by the same fit, which is what makes it safe (the
        * defect this guards was pairing against the *current* data instead).
        local _fvsem `"`e(fvsemantic)'"'
        if `"`_fvsem'"' != "" {
            local _nb_terms ""
            foreach _t of local _fvsem {
                if regexm("`_t'", "[0-9]+b\.") continue
                local _nb_terms "`_nb_terms' `_t'"
            }
            local _covcols "`e(designvars)'"
            local _n_nb : word count `_nb_terms'
            local _n_cc : word count `_covcols'
            if `_n_nb' != `_n_cc' {
                display as error "internal error: e(fvsemantic) and e(designvars) disagree"
                exit 198
            }

            forvalues _k = 1/`_n_nb' {
                local _term : word `_k' of `_nb_terms'
                local _col  : word `_k' of `_covcols'
                * A dropped column is fine -- it gets rebuilt downstream.
                capture confirm numeric variable `_col'
                if _rc continue

                tempvar _want
                quietly gen double `_want' = 1 if e(sample)
                local _parts = subinstr(subinstr("`_term'", "##", "#", .), "#", " ", .)
                local _bad = 0
                foreach _p of local _parts {
                    if regexm("`_p'", "^([0-9]+)[a-z]*\.(.+)$") {
                        local _lv = regexs(1)
                        local _vr = regexs(2)
                        capture confirm numeric variable `_vr'
                        if _rc {
                            local _bad = 1
                            continue, break
                        }
                        quietly replace `_want' = `_want' * (`_vr' == `_lv') ///
                            if e(sample)
                    }
                    else {
                        local _vr = subinstr("`_p'", "c.", "", .)
                        capture confirm numeric variable `_vr'
                        if _rc {
                            local _bad = 1
                            continue, break
                        }
                        quietly replace `_want' = `_want' * `_vr' if e(sample)
                    }
                }
                if `_bad' {
                    drop `_want'
                    continue
                }

                * EXACT.  `_want' repeats the same product the fit built the
                * column from, on the same rows, so the two agree bit for bit
                * when nothing has been modified; an absolute 1e-9 band let a
                * small-scale tampering (or a design column rescaled by 1e-10)
                * pass as unmodified.  The missing-pattern clause still carries
                * the missing-vs-nonmissing case, which `!=' alone would report
                * for one direction and not the other.
                quietly count if e(sample) & ///
                    (`_col' != `_want' | ///
                     missing(`_col') != missing(`_want'))
                local _ndiff = r(N)
                drop `_want'
                if `_ndiff' > 0 {
                    display as error "design column `_col' (`_term') has been modified since estimation"
                    display as error "`_ndiff' observation(s) no longer match the fitted factor term"
                    display as error "re-run {bf:finegray} before this post-estimation command"
                    exit 459
                }
            }
        }
    }
    local rc = _rc
    set varabbrev `_orig_varabbrev'
    if `rc' exit `rc'
end
