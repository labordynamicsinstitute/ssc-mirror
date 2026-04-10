*! ml_fragility v1.4.0  metaLong for Stata 14.1
*! Leave-One-Out and Leave-k-Out Fragility Analysis
*! Subir Hait, Michigan State University  |  haitsubi@msu.edu
*!
*! FIX v1.4.0: expanded all single-line { cmd; cmd } blocks to proper
*! multi-line blocks — Stata 14.1 does not allow code after open brace
*! on the same line inside ado programs (r(198)).
*! Also uses tempfile instead of preserve/restore to avoid r(621),
*! and tempvar exclude flag in LkO to avoid r(132).

program define ml_fragility, rclass
    version 14.1

    syntax varlist(min=2 max=2 numeric) [if] [in] , ///
        STUDy(varname)        ///
        TIME(varname numeric) ///
        METAfile(string asis) ///
        [                     ///
        ALpha(real 0.05)      ///
        MAXK(integer 5)       ///
        noSMALLsample         ///
        SAVing(string asis)   ///
        REPLACE               ///
        ]

    tokenize `varlist'
    local yi `1'
    local vi `2'

    /* ---- Mark analytic sample ----------------------------------------- */
    marksample touse
    markout `touse' `time' `yi' `vi'
    capture confirm string variable `study'
    if !_rc {
        quietly replace `touse' = 0 if trim(`study') == ""
    }
    else {
        quietly replace `touse' = 0 if missing(`study')
    }

    /* ---- Load ml_meta results ----------------------------------------- */
    preserve
    quietly use `"`metafile'"', clear
    capture confirm variable time k theta se df t_stat p_val ci_lb ci_ub tau2
    if _rc {
        di as error "metafile() is not a valid ml_meta results file."
        restore
        exit 198
    }
    local n_times = _N
    tempname meta_mat
    mkmat time k theta se df t_stat p_val ci_lb ci_ub tau2, matrix(`meta_mat')
    restore

    /* ---- Save working data to tempfile --------------------------------- */
    quietly keep if `touse'
    quietly keep `yi' `vi' `study' `time'
    quietly sort `time' `study'
    tempfile workdata
    quietly save `workdata'

    /* ---- Result matrix: n_times x 6 ---------------------------------- */
    tempname frag_mat
    matrix `frag_mat' = J(`n_times', 6, .)
    matrix colnames `frag_mat' = ///
        time k_studies p_original sig_original fragility_index frag_quotient

    local study_removed_list ""

    /* ================================================================== */
    /*  Main loop over time points                                        */
    /* ================================================================== */
    forvalues row = 1/`n_times' {

        local t_val  = `meta_mat'[`row', 1]
        local k_t    = `meta_mat'[`row', 2]
        local p_orig = `meta_mat'[`row', 7]
        local tau2_t = `meta_mat'[`row', 10]

        matrix `frag_mat'[`row', 1] = `t_val'
        matrix `frag_mat'[`row', 2] = `k_t'
        matrix `frag_mat'[`row', 3] = `p_orig'

        local sig_orig = 0
        if !missing(`p_orig') & `p_orig' < `alpha' {
            local sig_orig = 1
        }
        matrix `frag_mat'[`row', 4] = `sig_orig'

        if missing(`p_orig') | `k_t' < 3 {
            local study_removed_list `"`study_removed_list' ".""'
            continue
        }

        /* ---- Load this time slice from tempfile --------------------- */
        quietly use `workdata', clear
        quietly keep if `time' == `t_val'

        quietly levelsof `study', local(all_studies)
        local n_studies : word count `all_studies'
        local tau2_use  = max(0, `tau2_t')
        local flip_k    = .
        local flip_study "."

        /* ============================================================ */
        /*  LEAVE-ONE-OUT (LOO)                                         */
        /* ============================================================ */
        foreach s of local all_studies {

            tempvar wi_loo
            quietly gen double `wi_loo' = ///
                1 / (`vi' + `tau2_use') if `study' != "`s'"

            quietly levelsof `study' if `study' != "`s'", local(rem_s)
            local k_rem : word count `rem_s'

            if `k_rem' < 2 {
                drop `wi_loo'
                continue
            }

            capture quietly regress `yi' [aw=`wi_loo'] ///
                if `study' != "`s'", vce(cluster `study')

            if _rc {
                drop `wi_loo'
                continue
            }

            local theta_l = _b[_cons]
            local se_l    = _se[_cons]
            local k_cl    = e(N_clust)

            if "`smallsample'" == "" {
                local df_l = max(1, `k_cl' - 1)
            }
            else {
                local df_l = 1e6
            }

            local t_l   = `theta_l' / `se_l'
            local p_l   = 2 * ttail(`df_l', abs(`t_l'))
            local sig_l = (`p_l' < `alpha')
            drop `wi_loo'

            if `sig_l' != `sig_orig' {
                local flip_k     = 1
                local flip_study = `"`s'"'
                continue, break
            }
        }

        /* ============================================================ */
        /*  LEAVE-k-OUT (k=2..maxk) — only if LOO found no flip        */
        /*  Uses tempvar EXCLUDE FLAG to avoid r(132)                  */
        /* ============================================================ */
        if missing(`flip_k') & `maxk' > 1 {

            local k_upper = min(`maxk', `k_t' - 2)

            forvalues kk = 2/`k_upper' {
                if !missing(`flip_k') {
                    continue, break
                }

                local n_combos   = min(500, `= comb(`k_t', `kk')')
                local found_flip = 0

                forvalues ctry = 1/`n_combos' {
                    if !missing(`flip_k') {
                        continue, break
                    }

                    /* Build numeric index list 1..n_studies */
                    local avail_idx ""
                    forvalues idx = 1/`n_studies' {
                        local avail_idx "`avail_idx' `idx'"
                    }

                    /* Exclusion flag tempvar */
                    tempvar excl
                    quietly gen byte `excl' = 0

                    /* Randomly pick kk study indices to exclude */
                    forvalues pick = 1/`kk' {
                        local n_av : word count `avail_idx'
                        local rpos = ceil(runiform() * `n_av')
                        local chosen_idx : word `rpos' of `avail_idx'
                        local chosen_s   : word `chosen_idx' of `all_studies'
                        quietly replace `excl' = 1 if `study' == "`chosen_s'"
                        local avail_idx : list avail_idx - chosen_idx
                    }

                    quietly levelsof `study' if !`excl', local(rem_lko)
                    local k_lko : word count `rem_lko'

                    if `k_lko' < 2 {
                        drop `excl'
                        continue
                    }

                    tempvar wi_lko
                    quietly gen double `wi_lko' = ///
                        1 / (`vi' + `tau2_use') if !`excl'

                    capture quietly regress `yi' [aw=`wi_lko'] ///
                        if !`excl', vce(cluster `study')

                    if _rc {
                        drop `excl' `wi_lko'
                        continue
                    }

                    local theta_lk = _b[_cons]
                    local se_lk    = _se[_cons]
                    local k_cl_lk  = e(N_clust)

                    if "`smallsample'" == "" {
                        local df_lk = max(1, `k_cl_lk' - 1)
                    }
                    else {
                        local df_lk = 1e6
                    }

                    local t_lk   = `theta_lk' / `se_lk'
                    local p_lk   = 2 * ttail(`df_lk', abs(`t_lk'))
                    local sig_lk = (`p_lk' < `alpha')
                    drop `excl' `wi_lko'

                    if `sig_lk' != `sig_orig' {
                        local flip_k     = `kk'
                        local found_flip = 1
                        continue, break
                    }

                }  /* end combo loop */

                if `found_flip' {
                    continue, break
                }

            }  /* end kk loop */
        }  /* end LkO block */

        /* ---- Store results ----------------------------------------- */
        if !missing(`flip_k') {
            matrix `frag_mat'[`row', 5] = `flip_k'
            matrix `frag_mat'[`row', 6] = `flip_k' / `k_t'
        }
        local study_removed_list `"`study_removed_list' "`flip_study'""'

    }  /* end time loop */

    /* ================================================================== */
    /*  Build output dataset                                              */
    /* ================================================================== */
    quietly {
        clear
        svmat double `frag_mat', names(col)

        label var time            "Follow-up time"
        label var k_studies       "Studies at this time point"
        label var p_original      "Original p-value"
        label var sig_original    "Originally significant (1=yes)"
        label var fragility_index "Min removals to flip significance"
        label var frag_quotient   "fragility_index / k_studies"

        gen str40 study_removed = ""
        local ridx = 0
        foreach sname of local study_removed_list {
            local ridx = `ridx' + 1
            quietly replace study_removed = `"`sname'"' in `ridx'
        }
        label var study_removed "Study removed to flip significance (LOO)"

        char _dta[ml_type]  "ml_fragility"
        char _dta[ml_alpha] "`alpha'"
        char _dta[ml_maxk]  "`maxk'"
    }

    /* ================================================================== */
    /*  Display                                                           */
    /* ================================================================== */
    di _newline
    di as txt "  {hline 72}"
    di as txt "  metaLong: Leave-k-out Fragility Analysis"
    di as txt "  max_k = `maxk'  |  alpha = `alpha'"
    di as txt "  {hline 72}"
    di as txt _col(4)  "Time" _col(12) "k"  _col(18) "p_orig" ///
              _col(28) "Sig?" _col(35) "FI" _col(42) "FQ"     ///
              _col(52) "Study removed"
    di as txt "  {hline 72}"

    forvalues row = 1/`n_times' {
        local t_r  = `frag_mat'[`row', 1]
        local k_r  = `frag_mat'[`row', 2]
        local po_r = `frag_mat'[`row', 3]
        local so_r = `frag_mat'[`row', 4]
        local fi_r = `frag_mat'[`row', 5]
        local fq_r = `frag_mat'[`row', 6]
        local sr   : word `row' of `study_removed_list'

        if missing(`po_r') {
            di as txt %7.1f `t_r' " " %4.0f `k_r' "   (skipped)"
            continue
        }

        local sig_lbl = cond(`so_r'==1, "yes", "no ")
        local fi_str  = cond(missing(`fi_r'), ">`maxk'", string(`fi_r', "%4.0f"))
        local fq_str  = cond(missing(`fq_r'), "  .   ",  string(`fq_r', "%6.3f"))

        di as txt %7.1f `t_r' " " as res %4.0f `k_r' ///
           %9.4f `po_r' "  `sig_lbl'  `fi_str'  `fq_str'  `sr'"
    }
    di as txt "  {hline 72}"
    di as txt "  FI = Fragility Index (min removals to flip);  FQ = FI / k"

    /* ================================================================== */
    /*  Save                                                              */
    /* ================================================================== */
    if `"`saving'"' != "" {
        if "`replace'" != "" {
            quietly save `saving', replace
        }
        else {
            quietly save `saving'
        }
        di as txt _newline "  Results saved to: " as res `"`saving'"'
    }

    return matrix fragility = `frag_mat'
    return scalar alpha     = `alpha'
    return scalar maxk      = `maxk'

end
