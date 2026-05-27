*! qcointall v1.0.0 — Master command: runs ALL quantile cointegration tests
*! Calls:
*!   - xqcoint   (Xiao 2009 FM + Kuriyama 2016 CUSUM)
*!   - qpolycoint (Li, Zheng & Guo 2016 polynomial + linearity Wald)
*!   - fqardl, type(qcoint) (Furno 2020 residual-based aux QR)
*!   - tuqcoint  (Tu, Liang & Wang 2022 NP local-constant) — if zvar() given
*!   - liqcoint_fc (Li, Zhang & Zheng 2025 functional-coef) — if zvar() given
*!   - qardl     (Cho-Kim-Shin 2015 QARDL, SSC) — if ARDL(p,q) requested
*! Produces:
*!   - Combined comparison table of cointegration verdicts
*!   - Combined plot: beta(tau) and test statistic vs tau across methods
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026

capture program drop qcointall
program define qcointall, rclass
    version 14.0

    syntax varlist(min=2 numeric ts) [if] [in], ///
        TAU(numlist >0 <1 sort) ///
        [Zvar(varname numeric) ///
         Porder(integer 3) ///
         ARDLpq(numlist min=2 max=2 integer >0) ///
         LEADS(integer 1) LAGS(integer 1) ///
         FULL ///
         GRAPHdir(string) ///
         GRAPH ///
         NOCOMBined ///
         SKIPxq SKIPpoly SKIPfurno SKIPtu SKIPliFC SKIPqardl ///
         SKIProbust SKIPconst]

    marksample touse
    qui count if `touse'
    local nobs = r(N)
    gettoken depvar indepvars : varlist
    local k : word count `indepvars'
    local ntau : word count `tau'

    // FULL mode: show every table and produce every graph
    if "`full'" != "" {
        local notable_opt ""
        local graph_opt "graph"
        // Make sure we run the new tests too
        if "`skiprobust'" == "" local run_robust 1
        if "`skipconst'"  == "" local run_const  1
    }
    else {
        local notable_opt "notable"
        local graph_opt ""
    }

    // Graph save directory
    if "`graphdir'" == "" {
        local graphdir "`c(pwd)'"
    }
    local pngprefix "`graphdir'/qcointall"

    di as txt _n "{hline 78}"
    di as res _col(3) "qcointall: Comprehensive Quantile Cointegration Battery"
    di as txt "{hline 78}"
    di as txt _col(3) "Dep. variable     : " as res "`depvar'"
    di as txt _col(3) "Indep. vars (I(1)): " as res "`indepvars'"
    if "`zvar'" != "" {
        di as txt _col(3) "Stationary cov. z : " as res "`zvar'"
    }
    di as txt _col(3) "Quantiles (#=" as res `ntau' as txt "): " as res "`tau'"
    di as txt _col(3) "Observations      : " as res `nobs'
    di as txt "{hline 78}"

    // ============================================================
    // 1. xqcoint  (Xiao 2009 FMQR + Kuriyama 2016 CUSUM)
    // ============================================================
    if "`skipxq'" == "" {
        di as txt _n as res _col(3) "[1/8] xqcoint  --  Xiao (2009) FMQR + Kuriyama (2016) CUSUM"
        di as txt _col(3) "{hline 70}"
        capture noisily xqcoint `varlist' if `touse', tau(`tau') `notable_opt' `graph_opt'
        if _rc == 0 {
            tempname xq_beta xq_cs
            mat `xq_beta' = e(beta_set)
            mat `xq_cs'   = e(cs_set)
            return matrix xq_beta = `xq_beta', copy
            return matrix xq_cs   = `xq_cs', copy
            if "`full'" != "" {
                capture graph export "`pngprefix'_1_xqcoint.png", replace width(1400) height(700)
                if _rc == 0 di as txt _col(5) "graph saved: `pngprefix'_1_xqcoint.png"
            }
        }
        else {
            di as err _col(5) "xqcoint failed: rc=" _rc
        }
    }

    // ============================================================
    // 2. qpolycoint  (Li 2016 polynomial + linearity Wald)
    // ============================================================
    if "`skippoly'" == "" {
        di as txt _n as res _col(3) "[2/8] qpolycoint  --  Li, Zheng & Guo (2016) polynomial + Wald"
        di as txt _col(3) "{hline 70}"
        capture noisily qpolycoint `varlist' if `touse', tau(`tau') porder(`porder') `notable_opt' `graph_opt'
        if _rc == 0 {
            tempname poly_coef poly_q poly_pval
            mat `poly_coef' = e(coef_set)
            mat `poly_q'    = e(tQ_set)
            mat `poly_pval' = e(pval_set)
            return matrix poly_coef = `poly_coef', copy
            return matrix poly_q    = `poly_q', copy
            return matrix poly_pval = `poly_pval', copy
            if "`full'" != "" {
                capture graph export "`pngprefix'_2_qpolycoint.png", replace width(1400) height(700)
                if _rc == 0 di as txt _col(5) "graph saved: `pngprefix'_2_qpolycoint.png"
            }
        }
        else {
            di as err _col(5) "qpolycoint failed: rc=" _rc
        }
    }

    // ============================================================
    // 3. Furno (2020) via fqardl, type(qcoint)
    // ============================================================
    if "`skipfurno'" == "" {
        di as txt _n as res _col(3) "[3/8] fqardl type(qcoint)  --  Furno (2020) residual-based test"
        di as txt _col(3) "{hline 70}"
        capture noisily fqardl `varlist' if `touse', tau(`tau') type(qcoint)
        if _rc == 0 {
            tempname furno_res
            capture mat `furno_res' = e(qcoint_results)
            if _rc == 0 {
                return matrix furno_res = `furno_res', copy
            }
        }
        else {
            di as err _col(5) "fqardl qcoint failed: rc=" _rc
        }
    }

    // ============================================================
    // 4. xqcoint_robust  (Xiao Section 3.3 KS/CVM partial-sum test)
    // ============================================================
    if "`skiprobust'" == "" {
        di as txt _n as res _col(3) "[4/8] xqcoint_robust  --  Xiao (2009) Section 3.3 KS/CVM test"
        di as txt _col(3) "{hline 70}"
        capture noisily xqcoint_robust `varlist' if `touse', tau(`tau') leads(`leads') lags(`lags') `graph_opt'
        if _rc == 0 {
            tempname rb_ks rb_cvm
            mat `rb_ks'  = e(ks_set)
            mat `rb_cvm' = e(cvm_set)
            return matrix robust_ks  = `rb_ks', copy
            return matrix robust_cvm = `rb_cvm', copy
            if "`full'" != "" {
                capture graph export "`pngprefix'_4_robust.png", replace width(1400) height(700)
                if _rc == 0 di as txt _col(5) "graph saved: `pngprefix'_4_robust.png"
            }
        }
        else {
            di as err _col(5) "xqcoint_robust failed: rc=" _rc
        }
    }

    // ============================================================
    // 5. xqcoint_const  (Xiao Section 3.2 constancy test)
    // ============================================================
    if "`skipconst'" == "" {
        di as txt _n as res _col(3) "[5/8] xqcoint_const  --  Xiao (2009) Section 3.2 constancy test"
        di as txt _col(3) "{hline 70}"
        capture noisily xqcoint_const `varlist' if `touse', tau(`tau') `graph_opt'
        if _rc == 0 {
            tempname cn_vhat cn_cv
            mat `cn_vhat' = e(Vhat)
            mat `cn_cv'   = e(cv_mat)
            return matrix const_vhat = `cn_vhat', copy
            return matrix const_cv   = `cn_cv', copy
            if "`full'" != "" {
                capture graph export "`pngprefix'_5_const.png", replace width(1400) height(700)
                if _rc == 0 di as txt _col(5) "graph saved: `pngprefix'_5_const.png"
            }
        }
        else {
            di as err _col(5) "xqcoint_const failed: rc=" _rc
        }
    }

    // ============================================================
    // 6. tuqcoint  (Tu et al 2022) -- only if zvar provided
    // ============================================================
    if "`skiptu'" == "" & "`zvar'" != "" {
        di as txt _n as res _col(3) "[6/8] tuqcoint  --  Tu, Liang & Wang (2022) NP local-constant"
        di as txt _col(3) "{hline 70}"
        local tau_med : word `=ceil(`ntau'/2)' of `tau'
        capture noisily tuqcoint `depvar' `: word 1 of `indepvars'' `zvar' if `touse', ///
            tau(`tau_med') ngrid(15) `notable_opt' `graph_opt'
        if _rc == 0 {
            tempname tu_mhat
            mat `tu_mhat' = e(mhat_grid)
            return matrix tu_mhat = `tu_mhat', copy
            di as txt _col(5) "Fitted m_hat surface returned (median tau)."
            if "`full'" != "" {
                capture graph export "`pngprefix'_6_tuqcoint.png", replace width(1400) height(700)
                if _rc == 0 di as txt _col(5) "graph saved: `pngprefix'_6_tuqcoint.png"
            }
        }
        else {
            di as err _col(5) "tuqcoint failed: rc=" _rc
        }
    }
    else if "`zvar'" == "" {
        di as txt _n as txt _col(3) "[6/8] tuqcoint           SKIPPED (zvar() not provided)"
    }

    // ============================================================
    // 7. liqcoint_fc  (Li et al 2025) -- only if zvar provided
    // ============================================================
    if "`skiplifc'" == "" & "`zvar'" != "" {
        di as txt _n as res _col(3) "[7/8] liqcoint_fc  --  Li, Zhang & Zheng (2025) functional-coef"
        di as txt _col(3) "{hline 70}"
        local tau_med : word `=ceil(`ntau'/2)' of `tau'
        capture noisily liqcoint_fc `varlist' if `touse', tau(`tau_med') zvar(`zvar') ngrid(15) `notable_opt' `graph_opt'
        if _rc == 0 {
            tempname lfc_beta
            mat `lfc_beta' = e(beta_grid)
            return matrix lfc_beta = `lfc_beta', copy
            di as txt _col(5) "Fitted beta_hat(z) curve returned (median tau)."
            if "`full'" != "" {
                capture graph export "`pngprefix'_7_liqcoint_fc.png", replace width(1400) height(700)
                if _rc == 0 di as txt _col(5) "graph saved: `pngprefix'_7_liqcoint_fc.png"
            }
        }
        else {
            di as err _col(5) "liqcoint_fc failed: rc=" _rc
        }
    }
    else if "`zvar'" == "" {
        di as txt _n as txt _col(3) "[7/8] liqcoint_fc        SKIPPED (zvar() not provided)"
    }

    // ============================================================
    // 8. qardl (CKS 2015) -- only if ARDL(p,q) requested
    // ============================================================
    if "`skipqardl'" == "" & "`ardlpq'" != "" {
        di as txt _n as res _col(3) "[8/8] qardl  --  Cho, Kim & Shin (2015) QARDL (SSC)"
        di as txt _col(3) "{hline 70}"
        tokenize "`ardlpq'"
        local ap `1'
        local aq `2'
        capture noisily qardl `varlist' if `touse', tau(`tau') p(`ap') q(`aq')
        if _rc != 0 {
            di as err _col(5) "qardl failed: rc=" _rc as txt "  (is the SSC qardl installed?)"
        }
    }
    else if "`ardlpq'" == "" {
        di as txt _n as txt _col(3) "[8/8] qardl              SKIPPED (no ardlpq() given)"
    }

    // ============================================================
    // COMBINED VERDICT TABLE
    // ============================================================
    if "`skipxq'" == "" | "`skippoly'" == "" | "`skipfurno'" == "" {
        di as txt _n "{hline 78}"
        di as res _col(3) "Combined Cointegration Verdict at each Quantile"
        di as txt _col(3) "Legend:   ** = reject H0 of NO-cointegration at 1%"
        di as txt _col(3) "          *  = reject at 5%"
        di as txt _col(3) "          .  = fail to reject (or test does not apply)"
        di as txt "{hline 78}"
        di as txt "        tau     xqcoint     qpolycoint     fqardl(furno)"
        di as txt "        ---     CUSUM       Wald linearity  aux-QR t"
        di as txt "  {hline 65}"

        // xqcoint thresholds (Hao-Inder, k regressors):
        // pull from e() if available — but xqcoint has been overwritten by later calls
        // We saved the matrices in return values
        forvalues r = 1/`ntau' {
            local tv : word `r' of `tau'
            di as txt "  " %5.2f `tv' "   |" _c

            // xqcoint CUSUM
            capture local cs_val = `xq_cs'[`r', 1]
            if _rc == 0 {
                if `cs_val' > 1.4255      di as err %10.4f `cs_val' " **" _c
                else if `cs_val' > 1.1684 di as err %10.4f `cs_val' "  *" _c
                else                       di as res %10.4f `cs_val' "  ." _c
            }
            else di as txt "       n/a    " _c

            // qpolycoint Wald
            capture local q_val = `poly_q'[`r', 1]
            capture local p_val = `poly_pval'[`r', 1]
            if _rc == 0 {
                if `p_val' < 0.01      di as err %10.4f `q_val' " **" _c
                else if `p_val' < 0.05 di as err %10.4f `q_val' "  *" _c
                else                    di as res %10.4f `q_val' "  ." _c
            }
            else di as txt "       n/a    " _c

            // Furno t-ratio (column 2 of qcoint_results)
            capture local furno_t = `furno_res'[`r', 2]
            capture local furno_cv5 = `furno_res'[`r', 3]
            capture local furno_cv1 = `furno_res'[`r', 4]
            if _rc == 0 {
                if `furno_t' < `furno_cv1'      di as err %10.4f `furno_t' " **" _c
                else if `furno_t' < `furno_cv5' di as err %10.4f `furno_t' "  *" _c
                else                             di as res %10.4f `furno_t' "  ." _c
            }
            else di as txt "       n/a    " _c

            di ""
        }
        di as txt "  {hline 65}"
        di as txt _col(3) "Note: xqcoint and qpolycoint test specific alternatives;"
        di as txt _col(3) "      fqardl(furno) tests stationarity of residuals at tau."
    }

    // ============================================================
    // COMBINED GRAPH — quick overlay of xqcoint CUSUM and qpolycoint Wald vs tau
    // ============================================================
    if ("`graph'" != "" | "`full'" != "") & "`nocombined'" == "" {
        // Only build if xq_cs exists
        capture confirm matrix `xq_cs'
        if _rc == 0 {
            _qcointall_combined_graph, taulist(`tau') ///
                xqmat(`xq_cs') depvar("`depvar'") indepvars("`indepvars'")
            if "`full'" != "" {
                capture graph export "`pngprefix'_combined.png", replace width(1400) height(700)
                if _rc == 0 di as txt _col(5) "graph saved: `pngprefix'_combined.png"
            }
        }
    }

    // ============================================================
    // SUMMARY (full mode only)
    // ============================================================
    if "`full'" != "" {
        di as txt _n "{hline 78}"
        di as res _col(3) "qcointall: FULL battery complete"
        di as txt _col(3) "Graphs exported to: " as res "`graphdir'/"
        di as txt _col(5) "qcointall_1_xqcoint.png"
        di as txt _col(5) "qcointall_2_qpolycoint.png"
        di as txt _col(5) "qcointall_4_robust.png"
        di as txt _col(5) "qcointall_5_const.png"
        if "`zvar'" != "" {
            di as txt _col(5) "qcointall_6_tuqcoint.png"
            di as txt _col(5) "qcointall_7_liqcoint_fc.png"
        }
        di as txt _col(5) "qcointall_combined.png"
        di as txt "{hline 78}"
    }
end


capture program drop _qcointall_combined_graph
program define _qcointall_combined_graph
    syntax, TAULIST(numlist) XQMAT(name) DEPVAR(string) INDEPVARS(string)

    preserve
    drop _all
    local ntau : word count `taulist'
    qui set obs `ntau'
    qui gen double tau = .
    qui gen double xq = .
    forvalues r = 1/`ntau' {
        local tv : word `r' of `taulist'
        qui replace tau = `tv' in `r'
        qui replace xq = `xqmat'[`r', 1] in `r'
    }

    twoway (line xq tau, lcolor(navy) lwidth(medthick)) ///
           (scatter xq tau, mcolor(black) msize(small)), ///
        yline(1.1684, lcolor(orange) lpattern(dash)) ///
        yline(1.4255, lcolor(red) lpattern(dash)) ///
        title("qcointall: xqcoint CUSUM CS({&tau})", size(medium)) ///
        subtitle("Dep: `depvar'  on  `indepvars'  (Hao-Inder k=1 5%=orange, 1%=red)", size(small)) ///
        xtitle("Quantile {&tau}") ytitle("CS({&tau})") ///
        legend(off) graphregion(color(white)) plotregion(color(white)) ///
        name(qcall_stats, replace)

    restore
end
