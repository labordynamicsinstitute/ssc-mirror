*! grangerspec 1.0.34  05aug2026
*! Granger causality tests across frequencies: Granger-causality spectra (Farne & Montanari, Computational Economics, 2022)
*! Author: H. Ozan Eruygur
*!         AHBV University, Ankara, Turkiye.
*!         Department of Economics
*!         ozaneruygur.com
*!         eruygur@gmail.com
*!         Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara, Turkiye
*!         eruygurakademi.com
*!         eruygurakademi@gmail.com
*! Stata port of the R package grangers 0.1.1 by Farne and Montanari
*! Farne, M., Montanari, A. (2022) Computational Economics 59, 935-966

program define grangerspec, rclass
    version 14.0
    syntax varlist(min=2 max=3 numeric ts) [if] [in] [, IC(string) MAXlag(integer -1) P(integer 0) P1(integer 0) P2(integer 0) TYPe(string) NOTABle BOOT NBoots(integer 1000) CONF(real 0.95) SEED(string) BOOTdata(string) DIFF BONFadjust BC ]

    * ---- mode: 2 vars = unconditional, 3 vars = conditional --------------
    local nv : word count `varlist'
    tokenize `varlist'
    local xv "`1'"
    local yv "`2'"
    if (`nv'==3) local zv "`3'"
    local mode = cond(`nv'==2, "uncond", "cond")

    * ---- defaults mirroring the R signature ------------------------------
    * ic.chosen = "SC", max.lag = min(4, length(x)-1), type.chosen = "none"
    if ("`ic'"=="") local ic "sc"
    local ic = lower("`ic'")
    if !inlist("`ic'","aic","hq","sc","fpe") {
        di as error "ic() must be one of aic, hq, sc, fpe (as in R vars::VAR)"
        exit 198
    }
    if ("`type'"=="") local type "none"
    if !inlist("`type'","none","const","trend") {
        di as error "type() must be one of none, const, trend (as in R vars::VAR)"
        exit 198
    }

    * ---- tsset check ------------------------------------------------------
    capture quietly tsset
    if _rc {
        di as error "data must be tsset before using grangerspec"
        exit 459
    }
    if ("`r(panelvar)'"!="") {
        di as error "grangerspec is a time-series command; data are xtset as a panel"
        exit 459
    }
    local tvar "`r(timevar)'"
    local tsf : format `tvar'
    local unit "periods"
    if (strpos("`tsf'","%tq")>0) local unit "quarters"
    else if (strpos("`tsf'","%tm")>0) local unit "months"
    else if (strpos("`tsf'","%tw")>0) local unit "weeks"
    else if (strpos("`tsf'","%th")>0) local unit "half-years"
    else if (strpos("`tsf'","%ty")>0) local unit "years"
    else if (strpos("`tsf'","%td")>0) local unit "days"

    * ---- estimation sample: must be one contiguous block -----------------
    marksample touse
    quietly count if `touse'
    local N = r(N)
    if (`N'<3) {
        di as error "too few usable observations"
        exit 2001
    }
    tempvar obsno
    quietly gen long `obsno' = _n
    quietly summarize `obsno' if `touse', meanonly
    if (r(max)-r(min)+1 != `N') {
        di as error "the estimation sample contains gaps; grangerspec needs one contiguous block (as the R original assumes a complete series)"
        exit 459
    }
    quietly summarize `tvar' if `touse', meanonly
    if (r(max)-r(min) != `N'-1) {
        di as error "the time variable has gaps over the estimation sample"
        exit 459
    }

    * max.lag default = min(4, N-1) exactly as in R
    if (`maxlag'==-1) local maxlag = min(4, `N'-1)
    if (`maxlag'>`N'-1) {
        di as error "The chosen number of lags is larger than or equal to the time length"
        exit 198
    }
    if (`maxlag'<1) {
        di as error "maxlag() must be at least 1"
        exit 198
    }

    * ---- Breitung-Candelon branch (bc_test_uncond / bc_test_cond ports) --
    if ("`bc'"!="") {
        if ("`boot'"!="" | "`diff'"!="" | "`bonfadjust'"!="" | "`bootdata'"!="" | "`seed'"!="") {
            di as error "bc cannot be combined with boot, diff, bonfadjust, seed(), or bootdata()"
            exit 198
        }
        if (`p1'!=0 | `p2'!=0) {
            di as error "the BC test fits a single VAR; use p() instead of p1()/p2()"
            exit 198
        }
        if (`conf'<=0 | `conf'>=1) {
            di as error "conf() must lie strictly between 0 and 1"
            exit 198
        }
        local iscond = cond("`mode'"=="cond", 1, 0)
        mata: gs_bc("`varlist'", "`touse'", `maxlag', "`ic'", "`type'", `p', `conf', `iscond')
        tempname FR FT PV TH RT
        matrix `FR' = r(freq)
        matrix `FT' = r(F)
        matrix `PV' = r(pval)
        matrix `TH' = r(Fthr)
        matrix `RT' = r(roots)
        local nfreq = rowsof(`FR')
        local Npad  = r(npad)
        local pbc   = r(p)
        local etyp "`type'"
        local nsig  = r(nsig)
        tempname SIGA
        if (`nsig'>0) matrix `SIGA' = r(freq_sig)
        tempname MR
        scalar `MR' = `RT'[1,1]
        local stab = cond(`MR'<1, "stable", "NOT stable")
        if (`nsig'>0) {
            _gs_ranges `SIGA' `=`FR'[2,1]-`FR'[1,1]'
            local rng "`r(ranges)'"
        }
        local f1 : di %6.4f `FR'[1,1]
        local cy1 ""
        local cy2 ""
        if (`nsig'>0) {
            local cy1 : di %5.1f 1/`SIGA'[rowsof(`SIGA'),1]
            local cy2 : di %5.1f 1/`SIGA'[1,1]
        }
        di ""
        di as text "=========================================================================="
        if (`iscond') di as text "Breitung-Candelon test conditional on a third variable"
        else di as text "Breitung-Candelon (2006) parametric F test, unconditional"
        di as text "=========================================================================="
        di ""
        di as text "Model"
        di as text "{hline 74}"
        di as text "  Effect variable (x): {res}`xv'{txt}     Cause variable (y): {res}`yv'"
        if (`iscond') di as text "  Third variable in the VAR (z): {res}`zv'"
        di as text "  Sample: n = {res}`N'{txt}     Fourier frequencies: {res}`nfreq'{txt} (padded length {res}`Npad'{txt})"
        di as text "  Model: VAR(p = {res}`pbc'{txt}), deterministic terms: {res}`etyp'{txt}; order " cond(`p'>0, "user-supplied", "by `=upper("`ic'")', max lag `maxlag'")
        di as text "  Stability: largest companion root modulus = {res}" %7.4f `MR' "{txt}  (`stab')"
        di as text "      (a stable VAR requires every companion root modulus to lie below one)"
        di as text "  Frequencies: f is in cycles per `unit' (omega = 2*pi*f); a cycle at"
        di as text "      frequency f lasts 1/f `unit': f = `f1' is the longest cycle (`Npad' `unit'),"
        di as text "      f = 0.5000 the shortest (2 `unit')"
        di ""
        di as text "Hypothesis and critical values"
        di as text "{hline 74}"
        di as text "  H0 (each frequency): y does not Granger-cause x at that frequency"
        if (`iscond') di as text "      in the VAR including z"
        di as text "  Statistic: F(2, n-2p) on the trigonometric restriction of the y-lag"
        di as text "      coefficients; F(1, n-p) at the last frequency"
        di as text "  Critical values (alpha = " %5.3f 1-`conf' as text "): interior {res}" %8.4f `TH'[1,1] "{txt}, last frequency {res}" %8.4f `TH'[`nfreq',1]
        if ("`table'"=="") {
            di ""
            di as text "Results by frequency"
            di as text "{hline 74}"
            di as text %10s "frequency" %10s "period" %14s "F statistic" %12s "p-value" %16s "decision"
            di as text "  {hline 62}"
            forvalues i = 1/`nfreq' {
                local s1 "Do not reject"
                if (`PV'[`i',1] < 1-`conf') local s1 "Reject"
                di as result %10.6f `FR'[`i',1] %10.1f 1/`FR'[`i',1] %14.6f `FT'[`i',1] %12.6f `PV'[`i',1] as text %16s "`s1'"
            }
            di as text "  {hline 62}"
            di as text "  period = 1/f, the length of the cycle in `unit'"
        }
        di ""
        di as text "Decision and conclusion"
        di as text "{hline 74}"
        di as text "  Decision at alpha = " %5.3f 1-`conf' as text ":"
        if (`nsig'>0) di as text "    Reject H0 at {res}`nsig'{txt} of {res}`nfreq'{txt} frequencies: {res}`rng'{txt} (cycles of `cy1'-`cy2' `unit')"
        else di as text "    Do not reject H0 at any frequency"
        if (`nsig'>0 & `iscond') di as text "  Conclusion: `yv' Granger-causes `xv' (given `zv' in the VAR) at the"
        else if (`nsig'>0) di as text "  Conclusion: `yv' Granger-causes `xv' at {res}`rng'{txt} (cycles of `cy1'-`cy2' `unit')."
        if (`nsig'>0 & `iscond') di as text "      {res}`rng'{txt} (cycles of `cy1'-`cy2' `unit')."
        if (`nsig'==0) di as text "  Conclusion: no evidence that `yv' Granger-causes `xv' at any frequency."
        return scalar n     = `N'
        return scalar npad  = `Npad'
        return scalar nfreq = `nfreq'
        return scalar p     = `pbc'
        return scalar conf  = `conf'
        return scalar nsig  = `nsig'
        return local  ic    "`ic'"
        return local  type  "`type'"
        return local  type_eff "`etyp'"
        return local  mode  = cond(`iscond', "bc_cond", "bc_uncond")
        return local  cmd   "grangerspec"
        return local  xvar  "`xv'"
        return local  yvar  "`yv'"
        if (`iscond') return local zvar "`zv'"
        if (`nsig'>0) {
            return matrix freq_sig = `SIGA'
        }
        return matrix freq  = `FR'
        return matrix F     = `FT'
        return matrix pval  = `PV'
        return matrix Fthr  = `TH'
        return matrix roots = `RT'
        exit
    }

    * ---- bootstrap inference branch (Granger.inference.* ports) ----------
    if ("`boot'"=="" & ("`bootdata'"!="" | "`seed'"!="" | "`diff'"!="" | "`bonfadjust'"!="")) {
        di as error "options nboots(), conf(), seed(), bootdata(), diff, and bonfadjust require the boot option"
        exit 198
    }
    if ("`boot'"!="") {
        if (`conf'<=0 | `conf'>=1) {
            di as error "conf() must lie strictly between 0 and 1"
            exit 198
        }
        if (`nboots'<1) {
            di as error "nboots() must be at least 1"
            exit 198
        }
        if ("`mode'"=="cond" & !((`p1'==0 & `p2'==0) | (`p1'>0 & `p2'>0))) {
            di as error "p1() and p2() must be both zero (IC selection) or both positive (fixed orders); the R original handles only these two cases and crashes otherwise"
            exit 198
        }
        if ("`diff'"!="" & "`mode'"!="cond") {
            di as error "diff requires three variables: the difference test compares the unconditional and the conditional spectrum"
            exit 198
        }
        if ("`bonfadjust'"!="" & "`diff'"=="") {
            di as error "bonfadjust applies only to the difference test (option diff)"
            exit 198
        }
        local nser = cond("`mode'"=="uncond", 2, 3)
        local usebp 0
        if ("`bootdata'"!="") {
            local usebp 1
            preserve
            quietly use "`bootdata'", clear
            unab bvars : _all
            local nbv : word count `bvars'
            if (mod(`nbv',`nser')!=0) {
                restore
                di as error "bootdata() must contain `nser'*B numeric columns: the B x-replicates, then the B y-replicates" cond(`nser'==3, ", then the B z-replicates", "")
                exit 198
            }
            mata: GS_BP = st_data(., tokens(st_local("bvars")))
            restore
        }
        if ("`seed'"!="") set seed `seed'
        if ("`mode'"=="cond" & "`diff'"!="") {
            local badj = cond("`bonfadjust'"!="", 1, 0)
            mata: gs_boot_diff("`xv' `yv' `zv'", "`touse'", `maxlag', "`ic'", "`type'", `p', `p1', `p2', `nboots', `conf', `usebp', `badj')
            local statyes = r(stat_yes)
            local Bused = r(nboots)
            local nsr0 = r(nonstat_rate)
            local nsr1 = r(nonstat_rate1)
            local nsr2 = r(nonstat_rate2)
            if (`statyes'==0) {
                capture mata: mata drop GS_BP
                di ""
                di as error "no bootstrap replicate produced stationary VARs in all three models (stat_yes = 0); only stat_yes is returned (as in the R original)"
                return scalar stat_yes = 0
                return scalar nonstat_rate  = `nsr0'
                return scalar nonstat_rate1 = `nsr1'
                return scalar nonstat_rate2 = `nsr2'
                return scalar nboots = `Bused'
                return local cmd "grangerspec"
                exit
            }
            tempname FR DG QS QI QMS QMI NS0 NS1 NS2
            matrix `FR' = r(freq)
            matrix `DG' = r(diff)
            scalar `QS'  = r(q_diff_sup)
            scalar `QI'  = r(q_diff_inf)
            scalar `QMS' = r(q_diff_max_sup)
            scalar `QMI' = r(q_diff_max_inf)
            scalar `NS0' = r(nonstat_rate)
            scalar `NS1' = r(nonstat_rate1)
            scalar `NS2' = r(nonstat_rate2)
            local nfreq = rowsof(`FR')
            local Npad  = r(npad)
            local porig  = r(p_orig)
            local porig1 = r(p_orig1)
            local porig2 = r(p_orig2)
            local n1 = r(nsig_sup)
            local n2 = r(nsig_inf)
            local n3 = r(nsig_max_sup)
            local n4 = r(nsig_max_inf)
            tempname SIGA SIGB SIGC SIGD
            if (`n1'>0) matrix `SIGA' = r(freq_sup)
            if (`n2'>0) matrix `SIGB' = r(freq_inf)
            if (`n3'>0) matrix `SIGC' = r(freq_max_sup)
            if (`n4'>0) matrix `SIGD' = r(freq_max_inf)
            capture mata: mata drop GS_BP
            local step = `FR'[2,1]-`FR'[1,1]
            if (`n1'>0) {
                _gs_ranges `SIGA' `step'
                local rng1 "`r(ranges)'"
            }
            if (`n2'>0) {
                _gs_ranges `SIGB' `step'
                local rng2 "`r(ranges)'"
            }
            if (`n3'>0) {
                _gs_ranges `SIGC' `step'
                local rng3 "`r(ranges)'"
            }
            if (`n4'>0) {
                _gs_ranges `SIGD' `step'
                local rng4 "`r(ranges)'"
            }
            local f1 : di %6.4f `FR'[1,1]
            if (`n1'>0) {
                local cy11 : di %5.1f 1/`SIGA'[rowsof(`SIGA'),1]
                local cy12 : di %5.1f 1/`SIGA'[1,1]
            }
            if (`n2'>0) {
                local cy21 : di %5.1f 1/`SIGB'[rowsof(`SIGB'),1]
                local cy22 : di %5.1f 1/`SIGB'[1,1]
            }
            if (`n3'>0) {
                local cy31 : di %5.1f 1/`SIGC'[rowsof(`SIGC'),1]
                local cy32 : di %5.1f 1/`SIGC'[1,1]
            }
            if (`n4'>0) {
                local cy41 : di %5.1f 1/`SIGD'[rowsof(`SIGD'),1]
                local cy42 : di %5.1f 1/`SIGD'[1,1]
            }
            di ""
            di as text "=========================================================================="
            di as text "Bootstrap test on the difference between the unconditional and the"
            di as text "conditional spectrum (Farne and Montanari 2022)"
            di as text "=========================================================================="
            di ""
            di as text "Model"
            di as text "{hline 74}"
            di as text "  Effect (x): {res}`xv'{txt}   Cause (y): {res}`yv'{txt}   Conditioning (z): {res}`zv'"
            di as text "  Sample: n = {res}`N'{txt}     Fourier frequencies: {res}`nfreq'{txt}     Replicates: B = {res}`Bused'{txt}" cond(`usebp'," (bootdata)","")
            di as text "  Spectra from VAR(p = {res}`porig'{txt}), VAR(p1 = {res}`porig1'{txt}), VAR(p2 = {res}`porig2'{txt})"
            di as text "  Non-stationary replicates excluded: (x,y) {res}" %5.1f 100*`NS0' "{txt}%, (x,z) {res}" %5.1f 100*`NS1' "{txt}%, (x,y,z) {res}" %5.1f 100*`NS2' "{txt}%"
            di as text "  Frequencies: f is in cycles per `unit' (omega = 2*pi*f); a cycle at"
            di as text "      frequency f lasts 1/f `unit': f = `f1' is the longest cycle (`Npad' `unit'),"
            di as text "      f = 0.5000 the shortest (2 `unit')"
            di ""
            di as text "Hypothesis and critical values"
            di as text "{hline 74}"
            di as text "  H0 (each frequency): the unconditional and the conditional causality"
            di as text "      of y to x coincide (the past of z mediates none of the effect)"
            di as text "  Statistic: signed difference GC(y->x) - GC(y->x given z) at each frequency"
            di as text "  Critical values: two-sided quantiles of the bootstrap median difference"
            local mlab = cond(`badj', "Bonferroni band:", "max band:")
            di as text "      confidence band (conf = {res}`conf'{txt}):" _col(41) "[{res}" %12.6f `QI' "{txt} , {res}" %12.6f `QS' "{txt} ]"
            di as text "      `mlab'" _col(41) "[{res}" %12.6f `QMI' "{txt} , {res}" %12.6f `QMS' "{txt} ]"
            if ("`table'"=="") {
                di ""
                di as text "Results by frequency"
                di as text "{hline 74}"
                local mhdr = cond(`badj', "Bonf band", "max band")
                di as text %10s "frequency" %10s "period" %18s "diff = GCu - GCc" %16s "conf band" %16s "`mhdr'"
                di as text "  {hline 70}"
                forvalues i = 1/`nfreq' {
                    local s1 "Do not reject"
                    if (`DG'[`i',1] > `QS') local s1 "Reject"
                    else if (`DG'[`i',1] < `QI') local s1 "Reject"
                    local s2 "Do not reject"
                    if (`DG'[`i',1] > `QMS') local s2 "Reject"
                    else if (`DG'[`i',1] < `QMI') local s2 "Reject"
                    di as result %10.6f `FR'[`i',1] %10.1f 1/`FR'[`i',1] %18.6f `DG'[`i',1] as text %16s "`s1'" %16s "`s2'"
                }
                di as text "  {hline 70}"
                di as text "  period = 1/f, the length of the cycle in `unit'; the sign of the"
                di as text "  difference shows the direction (negative = conditional above unconditional)"
            }
            di ""
            di as text "Decision and conclusion"
            di as text "{hline 74}"
            di as text "  Decision at alpha = " %5.3f 1-`conf' as text " (confidence band):"
            if (`n1'>0) di as text "    Reject H0 (difference above band) at {res}`n1'{txt} of {res}`nfreq'{txt} frequencies: {res}`rng1'{txt} (cycles of `cy11'-`cy12' `unit')"
            if (`n2'>0) di as text "    Reject H0 (difference below band) at {res}`n2'{txt} of {res}`nfreq'{txt} frequencies: {res}`rng2'{txt} (cycles of `cy21'-`cy22' `unit')"
            if (`n1'==0 & `n2'==0) di as text "    Do not reject H0 at any frequency"
            local mdl = cond(`badj', "Bonferroni band", "max band")
            di as text "  Decision (`mdl'):"
            if (`n3'>0) di as text "    Reject H0 (difference above band) at {res}`n3'{txt} of {res}`nfreq'{txt} frequencies: {res}`rng3'{txt} (cycles of `cy31'-`cy32' `unit')"
            if (`n4'>0) di as text "    Reject H0 (difference below band) at {res}`n4'{txt} of {res}`nfreq'{txt} frequencies: {res}`rng4'{txt} (cycles of `cy41'-`cy42' `unit')"
            if (`n3'==0 & `n4'==0) di as text "    Do not reject H0 at any frequency"
            di ""
            if (`n1'>0) di as text "  Conclusion: part of the effect of `yv' on `xv'"
            if (`n1'>0) di as text "      is mediated by `zv' at {res}`rng1'{txt} (cycles of `cy11'-`cy12' `unit')."
            if (`n2'>0) di as text "  Conclusion: conditioning on `zv' strengthens the measured causality"
            if (`n2'>0) di as text "      from `yv' to `xv' at {res}`rng2'{txt} (cycles of `cy21'-`cy22' `unit')."
            if (`n1'==0 & `n2'==0) di as text "  Conclusion: no significant difference between the two spectra."
            return scalar n       = `N'
            return scalar npad    = `Npad'
            return scalar nfreq   = `nfreq'
            return scalar nboots  = `Bused'
            return scalar conf    = `conf'
            return scalar stat_yes = 1
            return scalar nonstat_rate  = `NS0'
            return scalar nonstat_rate1 = `NS1'
            return scalar nonstat_rate2 = `NS2'
            return scalar p_orig  = `porig'
            return scalar p_orig1 = `porig1'
            return scalar p_orig2 = `porig2'
            return scalar q_diff_sup     = `QS'
            return scalar q_diff_inf     = `QI'
            return scalar q_diff_max_sup = `QMS'
            return scalar q_diff_max_inf = `QMI'
            return scalar nsig_sup     = `n1'
            return scalar nsig_inf     = `n2'
            return scalar nsig_max_sup = `n3'
            return scalar nsig_max_inf = `n4'
            return local  ic   "`ic'"
            return local  type "`type'"
            return local  bonf = cond(`badj', "adjusted", "asis")
            return local  cmd  "grangerspec"
            return local  xvar "`xv'"
            return local  yvar "`yv'"
            return local  zvar "`zv'"
            if (`n1'>0) {
                return matrix freq_sup = `SIGA'
            }
            if (`n2'>0) {
                return matrix freq_inf = `SIGB'
            }
            if (`n3'>0) {
                return matrix freq_max_sup = `SIGC'
            }
            if (`n4'>0) {
                return matrix freq_max_inf = `SIGD'
            }
            return matrix freq = `FR'
            return matrix diff = `DG'
            exit
        }
        if ("`mode'"=="cond") {
            mata: gs_boot_cond("`xv' `yv' `zv'", "`touse'", `maxlag', "`ic'", "`type'", `p1', `p2', `nboots', `conf', `usebp')
            local statyes = r(stat_yes)
            local Bused = r(nboots)
            local nsr1 = r(nonstat_rate1)
            local nsr2 = r(nonstat_rate2)
            if (`statyes'==0) {
                capture mata: mata drop GS_BP
                di ""
                di as error "no bootstrap replicate produced stationary VARs in both models (stat_yes = 0); only stat_yes is returned (as in the R original)"
                return scalar stat_yes = 0
                return scalar nonstat_rate1 = `nsr1'
                return scalar nonstat_rate2 = `nsr2'
                return scalar nboots = `Bused'
                return local cmd "grangerspec"
                exit
            }
            tempname FR G1 QX QMX NSR1 NSR2 DM1 DM2
            matrix `FR' = r(freq)
            matrix `G1' = r(gc_yxz)
            scalar `QX'  = r(q_x_z)
            scalar `QMX' = r(q_max_x_z)
            scalar `NSR1' = r(nonstat_rate1)
            scalar `NSR2' = r(nonstat_rate2)
            scalar `DM1' = r(delay1_mean)
            scalar `DM2' = r(delay2_mean)
            local nfreq = rowsof(`FR')
            local Npad  = r(npad)
            local porig1 = r(p_orig1)
            local porig2 = r(p_orig2)
            local n1 = r(nsig)
            local n3 = r(nsig_max)
            tempname SIGA SIGC
            if (`n1'>0) matrix `SIGA' = r(freq_sig)
            if (`n3'>0) matrix `SIGC' = r(freq_sig_max)
            capture mata: mata drop GS_BP
            local step = `FR'[2,1]-`FR'[1,1]
            if (`n1'>0) {
                _gs_ranges `SIGA' `step'
                local rng1 "`r(ranges)'"
            }
            if (`n3'>0) {
                _gs_ranges `SIGC' `step'
                local rng3 "`r(ranges)'"
            }
            local f1 : di %6.4f `FR'[1,1]
            local cy11 ""
            local cy12 ""
            if (`n1'>0) {
                local cy11 : di %5.1f 1/`SIGA'[rowsof(`SIGA'),1]
                local cy12 : di %5.1f 1/`SIGA'[1,1]
            }
            if (`n3'>0) {
                local cy31 : di %5.1f 1/`SIGC'[rowsof(`SIGC'),1]
                local cy32 : di %5.1f 1/`SIGC'[1,1]
            }
            di ""
            di as text "=========================================================================="
            di as text "Bootstrap test on the conditional spectrum"
            di as text "(Farne and Montanari 2022)"
            di as text "=========================================================================="
            di ""
            di as text "Model"
            di as text "{hline 74}"
            di as text "  Effect (x): {res}`xv'{txt}   Cause (y): {res}`yv'{txt}   Conditioning (z): {res}`zv'"
            di as text "  Sample: n = {res}`N'{txt}     Fourier frequencies: {res}`nfreq'{txt}     Replicates: B = {res}`Bused'{txt}" cond(`usebp'," (bootdata)","")
            di as text "  Spectrum from VAR(p1 = {res}`porig1'{txt}) and VAR(p2 = {res}`porig2'{txt})"
            di as text "  Non-stationary replicates excluded: (x,z) {res}" %5.1f 100*`NSR1' "{txt}%, (x,y,z) {res}" %5.1f 100*`NSR2' "{txt}%"
            di as text "  Mean bootstrap orders: {res}" %5.2f `DM1' "{txt} and {res}" %5.2f `DM2'
            di as text "  Frequencies: f is in cycles per `unit' (omega = 2*pi*f); a cycle at"
            di as text "      frequency f lasts 1/f `unit': f = `f1' is the longest cycle (`Npad' `unit'),"
            di as text "      f = 0.5000 the shortest (2 `unit')"
            di ""
            di as text "Hypothesis and critical values"
            di as text "{hline 74}"
            di as text "  H0: x is stochastically independent of y given z, i.e. zero"
            di as text "      conditional Granger causality at every frequency"
            di as text "  Statistic: the estimated conditional causality spectrum at each frequency"
            di as text "  Critical values: quantiles of the bootstrap median causality"
            di as text "      frequency-wise (conf = {res}`conf'{txt}):" _col(41) "{res}" %12.6f `QX'
            di as text "      overall (Bonferroni):" _col(41) "{res}" %12.6f `QMX'
            if ("`table'"=="") {
                di ""
                di as text "Results by frequency"
                di as text "{hline 74}"
                di as text %10s "frequency" %10s "period" %20s "GC(y -> x given z)" %16s "decision"
                di as text "  {hline 56}"
                forvalues i = 1/`nfreq' {
                    local s1 "Do not reject"
                    if (`G1'[`i',1] > `QMX') local s1 "Reject**"
                    else if (`G1'[`i',1] > `QX') local s1 "Reject"
                    di as result %10.6f `FR'[`i',1] %10.1f 1/`FR'[`i',1] %20.6f `G1'[`i',1] as text %16s "`s1'"
                }
                di as text "  {hline 56}"
                di as text "  period   = 1/f, the length of the cycle in `unit'"
                di as text "  Reject   = above the frequency-wise critical value"
                di as text "  Reject** = also above the Bonferroni critical value, so the overall"
                di as text "             (all-frequencies) test rejects H0 as well"
            }
            di ""
            di as text "Decision and conclusion"
            di as text "{hline 74}"
            di as text "  Decision at alpha = " %5.3f 1-`conf' as text ":"
            if (`n1'>0) di as text "    frequency-wise: Reject H0 at {res}`n1'{txt} of {res}`nfreq'{txt} frequencies: {res}`rng1'{txt} (cycles of `cy11'-`cy12' `unit')"
            else di as text "    frequency-wise: Do not reject H0 at any frequency"
            if (`n3'>0) di as text "    overall (Bonferroni): Reject H0; significant at {res}`rng3'{txt} (cycles of `cy31'-`cy32' `unit')"
            else di as text "    overall (Bonferroni): Do not reject H0"
            di ""
            if (`n3'>0) di as text "  Conclusion: `yv' Granger-causes `xv' given `zv' (overall H0"
            if (`n3'>0) di as text "      rejected); the causal link is concentrated at {res}`rng3'{txt} (cycles of `cy31'-`cy32' `unit')."
            else if (`n1'>0) di as text "  Conclusion: frequency-wise evidence of conditional causality at {res}`rng1'{txt} (cycles of `cy11'-`cy12' `unit'),"
            if (`n3'==0 & `n1'>0) di as text "      but the conservative overall test does not reject independence."
            if (`n1'==0 & `n3'==0) di as text "  Conclusion: no evidence of conditional causality at any frequency."
            return scalar n       = `N'
            return scalar npad    = `Npad'
            return scalar nfreq   = `nfreq'
            return scalar nboots  = `Bused'
            return scalar conf    = `conf'
            return scalar stat_yes = 1
            return scalar nonstat_rate1 = `NSR1'
            return scalar nonstat_rate2 = `NSR2'
            return scalar delay1_mean   = `DM1'
            return scalar delay2_mean   = `DM2'
            return scalar p_orig1 = `porig1'
            return scalar p_orig2 = `porig2'
            return scalar q_x_z     = `QX'
            return scalar q_max_x_z = `QMX'
            return scalar nsig     = `n1'
            return scalar nsig_max = `n3'
            return local  ic   "`ic'"
            return local  type "`type'"
            return local  cmd  "grangerspec"
            return local  xvar "`xv'"
            return local  yvar "`yv'"
            return local  zvar "`zv'"
            if (`n1'>0) {
                return matrix freq_sig = `SIGA'
            }
            if (`n3'>0) {
                return matrix freq_sig_max = `SIGC'
            }
            return matrix freq   = `FR'
            return matrix gc_yxz = `G1'
            exit
        }
        mata: gs_boot_uncond("`xv' `yv'", "`touse'", `maxlag', "`ic'", "`type'", `p', `nboots', `conf', `usebp')
        local statyes = r(stat_yes)
        local Bused = r(nboots)
        local nsr = r(nonstat_rate)
        if (`statyes'==0) {
            capture mata: mata drop GS_BP
            di ""
            di as error "no stationary VAR was estimated across the bootstrap samples (stat_yes = 0); only stat_yes is returned (as in the R original)"
            return scalar stat_yes = 0
            return scalar nonstat_rate = `nsr'
            return scalar nboots = `Bused'
            return local cmd "grangerspec"
            exit
        }
        tempname FR G1 G2 QX QY QMX QMY NSR DM
        matrix `FR' = r(freq)
        matrix `G1' = r(gc_yx)
        matrix `G2' = r(gc_xy)
        scalar `QX'  = r(q_x)
        scalar `QY'  = r(q_y)
        scalar `QMX' = r(q_max_x)
        scalar `QMY' = r(q_max_y)
        scalar `NSR' = r(nonstat_rate)
        scalar `DM'  = r(delay_mean)
        local nfreq = rowsof(`FR')
        local Npad  = r(npad)
        local porig = r(p_orig)
        local n1 = r(nsig_yx)
        local n2 = r(nsig_xy)
        local n3 = r(nsig_max_yx)
        local n4 = r(nsig_max_xy)
        tempname SIGA SIGB SIGC SIGD
        if (`n1'>0) matrix `SIGA' = r(freq_sig_yx)
        if (`n2'>0) matrix `SIGB' = r(freq_sig_xy)
        if (`n3'>0) matrix `SIGC' = r(freq_sig_max_yx)
        if (`n4'>0) matrix `SIGD' = r(freq_sig_max_xy)
        capture mata: mata drop GS_BP
        local step = `FR'[2,1]-`FR'[1,1]
        if (`n1'>0) {
            _gs_ranges `SIGA' `step'
            local rng1 "`r(ranges)'"
        }
        if (`n2'>0) {
            _gs_ranges `SIGB' `step'
            local rng2 "`r(ranges)'"
        }
        if (`n3'>0) {
            _gs_ranges `SIGC' `step'
            local rng3 "`r(ranges)'"
        }
        if (`n4'>0) {
            _gs_ranges `SIGD' `step'
            local rng4 "`r(ranges)'"
        }
        local f1 : di %6.4f `FR'[1,1]
        local cyA1 ""
        local cyA2 ""
        if (`n1'>0) {
            local cyA1 : di %5.1f 1/`SIGA'[rowsof(`SIGA'),1]
            local cyA2 : di %5.1f 1/`SIGA'[1,1]
        }
        if (`n2'>0) {
            local cyB1 : di %5.1f 1/`SIGB'[rowsof(`SIGB'),1]
            local cyB2 : di %5.1f 1/`SIGB'[1,1]
        }
        if (`n3'>0) {
            local cyC1 : di %5.1f 1/`SIGC'[rowsof(`SIGC'),1]
            local cyC2 : di %5.1f 1/`SIGC'[1,1]
        }
        if (`n4'>0) {
            local cyD1 : di %5.1f 1/`SIGD'[rowsof(`SIGD'),1]
            local cyD2 : di %5.1f 1/`SIGD'[1,1]
        }
        di ""
        di as text "=========================================================================="
        di as text "Bootstrap test on the unconditional spectra, both directions"
        di as text "(Farne and Montanari 2022)"
        di as text "=========================================================================="
        di ""
        di as text "Model"
        di as text "{hline 74}"
        di as text "  Effect variable (x): {res}`xv'{txt}     Cause variable (y): {res}`yv'"
        di as text "  Sample: n = {res}`N'{txt}     Fourier frequencies: {res}`nfreq'{txt}     Replicates: B = {res}`Bused'{txt}" cond(`usebp'," (bootdata)","")
        di as text "  Spectra from VAR(p = {res}`porig'{txt}); mean bootstrap order: {res}" %5.2f `DM'
        di as text "  Non-stationary replicates excluded: {res}" %5.1f 100*`NSR' "{txt}%"
        di as text "  Frequencies: f is in cycles per `unit' (omega = 2*pi*f); a cycle at"
        di as text "      frequency f lasts 1/f `unit': f = `f1' is the longest cycle (`Npad' `unit'),"
        di as text "      f = 0.5000 the shortest (2 `unit')"
        di ""
        di as text "Hypothesis and critical values"
        di as text "{hline 74}"
        di as text "  H0: x and y are stochastically independent, i.e. zero Granger"
        di as text "      causality at every frequency (each direction tested separately)"
        di as text "  Statistic: the estimated causality spectrum at each Fourier frequency"
        di as text "  Critical values: quantiles of the bootstrap median causality"
        di as text _col(24) %12s "y -> x" _col(40) %12s "x -> y"
        di as text "      frequency-wise:" _col(24) "{res}" %12.6f `QX' _col(40) "{res}" %12.6f `QY'
        di as text "      overall (Bonf):" _col(24) "{res}" %12.6f `QMX' _col(40) "{res}" %12.6f `QMY'
        if ("`table'"=="") {
            di ""
            di as text "Results by frequency"
            di as text "{hline 74}"
            di as text %10s "frequency" %8s "period" %14s "GC(y -> x)" %15s "decision" %14s "GC(x -> y)" %15s "decision"
            di as text "  {hline 76}"
            forvalues i = 1/`nfreq' {
                local s1 "Do not reject"
                if (`G1'[`i',1] > `QMX') local s1 "Reject**"
                else if (`G1'[`i',1] > `QX') local s1 "Reject"
                local s2 "Do not reject"
                if (`G2'[`i',1] > `QMY') local s2 "Reject**"
                else if (`G2'[`i',1] > `QY') local s2 "Reject"
                di as result %10.6f `FR'[`i',1] %8.1f 1/`FR'[`i',1] %14.6f `G1'[`i',1] as text %15s "`s1'" as result %14.6f `G2'[`i',1] as text %15s "`s2'"
            }
            di as text "  {hline 76}"
            di as text "  period   = 1/f, the length of the cycle in `unit'"
            di as text "  Reject   = above the frequency-wise critical value"
            di as text "  Reject** = also above the Bonferroni critical value, so the overall"
            di as text "             (all-frequencies) test rejects H0 as well"
        }
        di ""
        di as text "Decision and conclusion"
        di as text "{hline 74}"
        di as text "  Decision at alpha = " %5.3f 1-`conf' as text ":"
        di as text "    y -> x (`yv' causing `xv'):"
        if (`n1'>0) di as text "      frequency-wise: Reject H0 at {res}`n1'{txt} of {res}`nfreq'{txt} frequencies: {res}`rng1'{txt} (cycles of `cyA1'-`cyA2' `unit')"
        else di as text "      frequency-wise: Do not reject H0 at any frequency"
        if (`n3'>0) di as text "      overall (Bonferroni): Reject H0; significant at {res}`rng3'{txt} (cycles of `cyC1'-`cyC2' `unit')"
        else di as text "      overall (Bonferroni): Do not reject H0"
        di as text "    x -> y (`xv' causing `yv'):"
        if (`n2'>0) di as text "      frequency-wise: Reject H0 at {res}`n2'{txt} of {res}`nfreq'{txt} frequencies: {res}`rng2'{txt} (cycles of `cyB1'-`cyB2' `unit')"
        else di as text "      frequency-wise: Do not reject H0 at any frequency"
        if (`n4'>0) di as text "      overall (Bonferroni): Reject H0; significant at {res}`rng4'{txt} (cycles of `cyD1'-`cyD2' `unit')"
        else di as text "      overall (Bonferroni): Do not reject H0"
        di ""
        if (`n3'>0) {
            di as text "  Conclusion: `yv' Granger-causes `xv' (overall H0 rejected);"
            di as text "      the causal link is concentrated at {res}`rng3'{txt} (cycles of `cyC1'-`cyC2' `unit')."
        }
        else if (`n1'>0) {
            di as text "  Conclusion: frequency-wise evidence that `yv' causes `xv',"
            di as text "      but the overall test does not reject independence."
        }
        else di as text "  Conclusion: no evidence that `yv' causes `xv' at any frequency."
        if (`n4'>0) {
            di as text "  Conclusion: `xv' Granger-causes `yv' (overall H0 rejected);"
            di as text "      the causal link is concentrated at {res}`rng4'{txt} (cycles of `cyD1'-`cyD2' `unit')."
        }
        else if (`n2'>0) {
            di as text "  Conclusion: frequency-wise evidence that `xv' causes `yv',"
            di as text "      but the overall test does not reject independence."
        }
        else di as text "  Conclusion: no evidence that `xv' causes `yv' at any frequency."
        return scalar n       = `N'
        return scalar npad    = `Npad'
        return scalar nfreq   = `nfreq'
        return scalar nboots  = `Bused'
        return scalar conf    = `conf'
        return scalar stat_yes = 1
        return scalar nonstat_rate = `NSR'
        return scalar delay_mean   = `DM'
        return scalar p_orig  = `porig'
        return scalar q_x     = `QX'
        return scalar q_y     = `QY'
        return scalar q_max_x = `QMX'
        return scalar q_max_y = `QMY'
        return scalar nsig_yx = `n1'
        return scalar nsig_xy = `n2'
        return scalar nsig_max_yx = `n3'
        return scalar nsig_max_xy = `n4'
        return local  ic   "`ic'"
        return local  type "`type'"
        return local  cmd  "grangerspec"
        return local  xvar "`xv'"
        return local  yvar "`yv'"
        if (`n1'>0) {
            return matrix freq_sig_yx = `SIGA'
        }
        if (`n2'>0) {
            return matrix freq_sig_xy = `SIGB'
        }
        if (`n3'>0) {
            return matrix freq_sig_max_yx = `SIGC'
        }
        if (`n4'>0) {
            return matrix freq_sig_max_xy = `SIGD'
        }
        return matrix freq  = `FR'
        return matrix gc_yx = `G1'
        return matrix gc_xy = `G2'
        exit
    }

    * ---- run the Mata engine ---------------------------------------------
    * Replicates the actual behavior of grangers 0.1.1: in the IC-selection
    * path the R call VAR(y, ic=, lag.max=, type.chosen) sends type.chosen
    * into the p slot (overwritten by selection) and type defaults to const,
    * so IC-selected models are ALWAYS fitted with a constant; only the
    * fixed-order path VAR(y, p=, type.chosen) honors type.chosen.
    if ("`mode'"=="uncond") {
        local etype = cond(`p'>0, "`type'", "const")
        mata: gs_uncond("`xv' `yv'", "`touse'", `maxlag', "`ic'", "`etype'", `p')
    }
    else {
        local etype1 = cond(`p1'>0, "`type'", "const")
        local etype2 = cond(`p2'>0, "`type'", "const")
        mata: gs_cond("`xv' `yv' `zv'", "`touse'", `maxlag', "`ic'", "`etype1'", "`etype2'", `p1', `p2')
    }

    * ---- retrieve results posted by Mata ---------------------------------
    tempname FR SG RT G1 G2 SG2 RT2
    matrix `FR' = r(freq)
    local nfreq = rowsof(`FR')
    local Npad  = r(npad)
    if ("`mode'"=="uncond") {
        local pu = r(p)
        matrix `G1' = r(gc_yx)
        matrix `G2' = r(gc_xy)
        matrix `SG' = r(sigma)
        matrix `RT' = r(roots)
    }
    else {
        local pc1 = r(p1)
        local pc2 = r(p2)
        matrix `G1' = r(gc_yxz)
        matrix `SG' = r(sigma1)
        matrix `SG2' = r(sigma2)
        matrix `RT' = r(roots1)
        matrix `RT2' = r(roots2)
    }

    * ---- display ----------------------------------------------------------
    tempname MR1 MR2
    if ("`mode'"=="uncond") scalar `MR1' = `RT'[1,1]
    else {
        scalar `MR1' = `RT'[1,1]
        scalar `MR2' = `RT2'[1,1]
    }
    local f1 : di %6.4f `FR'[1,1]
    di ""
    di as text "=========================================================================="
    if ("`mode'"=="uncond") di as text "Unconditional Granger-causality spectrum in both directions (Geweke 1982)"
    else di as text "Conditional Granger-causality spectrum given a third variable (Geweke 1984)"
    di as text "=========================================================================="
    di ""
    di as text "Model"
    di as text "{hline 74}"
    di as text "  Effect variable (x): {res}`xv'{txt}     Cause variable (y): {res}`yv'"
    if ("`mode'"=="cond") di as text "  Conditioning variable (z): {res}`zv'"
    di as text "  Sample: n = {res}`N'{txt}     Fourier frequencies: {res}`nfreq'{txt} (padded length {res}`Npad'{txt})"
    if ("`mode'"=="uncond") di as text "  Model: VAR(p = {res}`pu'{txt}), deterministic terms: {res}`etype'{txt}; order " cond(`p'>0, "user-supplied", "by `=upper("`ic'")', max lag `maxlag'")
    else di as text "  Models: VAR(p1 = {res}`pc1'{txt}) on (x,z) and VAR(p2 = {res}`pc2'{txt}) on (x,y,z), deterministic terms: {res}`etype1'{txt}, {res}`etype2'"
    local quirk 0
    if ("`mode'"=="uncond" & "`etype'"!="`type'") local quirk 1
    if ("`mode'"=="cond" & ("`etype1'"!="`type'" | "`etype2'"!="`type'")) local quirk 1
    if (`quirk') di as text "  (IC-selected orders are fitted with a constant)"
    if ("`mode'"=="uncond") di as text "  Stability: largest companion root modulus = {res}" %7.4f `MR1' "{txt}  (" cond(`MR1'<1,"stable","NOT stable") ")"
    else di as text "  Stability: largest root moduli = {res}" %7.4f `MR1' "{txt} and {res}" %7.4f `MR2' "{txt}  (" cond(`MR1'<1 & `MR2'<1,"stable","NOT stable") ")"
    di as text "      (a stable VAR requires every companion root modulus to lie below one)"
    di as text "  Frequencies: f is in cycles per `unit' (omega = 2*pi*f); a cycle at"
    di as text "      frequency f lasts 1/f `unit': f = `f1' is the longest cycle (`Npad' `unit'),"
    di as text "      f = 0.5000 the shortest (2 `unit')"
    if ("`table'"=="") {
        di ""
        di as text "Causality spectra by frequency"
        di as text "{hline 74}"
        if ("`mode'"=="uncond") {
            di as text %10s "frequency" %10s "period" %16s "GC(y -> x)" %16s "GC(x -> y)"
            di as text "  {hline 52}"
            forvalues i = 1/`nfreq' {
                di as result %10.6f `FR'[`i',1] %10.1f 1/`FR'[`i',1] %16.6f `G1'[`i',1] %16.6f `G2'[`i',1]
            }
            di as text "  {hline 52}"
        }
        else {
            di as text %10s "frequency" %10s "period" %20s "GC(y -> x given z)"
            di as text "  {hline 42}"
            forvalues i = 1/`nfreq' {
                di as result %10.6f `FR'[`i',1] %10.1f 1/`FR'[`i',1] %20.6f `G1'[`i',1]
            }
            di as text "  {hline 42}"
        }
        di as text "  period = 1/f, the length of the cycle in `unit'"
    }
    di ""
    di as text "  Note: the spectra describe the strength of the causal link at each"
    di as text "  frequency; use option boot or bc for formal inference. Residual"
    di as text "  covariances and all root moduli are stored in r()."

    * ---- returns ----------------------------------------------------------
    return scalar n     = `N'
    return scalar npad  = `Npad'
    return scalar nfreq = `nfreq'
    return local  ic    "`ic'"
    return local  type  "`type'"
    if ("`mode'"=="uncond") return local type_eff "`etype'"
    else return local type_eff "`etype1' `etype2'"
    return local  cmd   "grangerspec"
    return local  xvar  "`xv'"
    return local  yvar  "`yv'"
    return matrix freq  = `FR'
    if ("`mode'"=="uncond") {
        return scalar p = `pu'
        return matrix gc_yx  = `G1'
        return matrix gc_xy  = `G2'
        return matrix sigma  = `SG'
        return matrix roots  = `RT'
    }
    else {
        return local  zvar "`zv'"
        return scalar p1 = `pc1'
        return scalar p2 = `pc2'
        return matrix gc_yxz = `G1'
        return matrix sigma1 = `SG'
        return matrix sigma2 = `SG2'
        return matrix roots1 = `RT'
        return matrix roots2 = `RT2'
    }
end

* -----------------------------------------------------------------------
* build a compact "a-b, c, d-e" range string from a grid-frequency vector
* -----------------------------------------------------------------------
program define _gs_ranges, rclass
    args matname step
    local k = rowsof(`matname')
    local start = `matname'[1,1]
    local prev  = `matname'[1,1]
    local out ""
    forvalues i = 2/`k' {
        local cur = `matname'[`i',1]
        if (abs(`cur'-`prev'-`step') < 1e-9) {
            local prev = `cur'
        }
        else {
            local a : di %6.4f `start'
            local b : di %6.4f `prev'
            if (`prev' > `start'+1e-12) {
                local piece "`a'-`b'"
            }
            else {
                local piece "`a'"
            }
            if ("`out'"=="") {
                local out "`piece'"
            }
            else {
                local out "`out', `piece'"
            }
            local start = `cur'
            local prev  = `cur'
        }
    }
    local a : di %6.4f `start'
    local b : di %6.4f `prev'
    if (`prev' > `start'+1e-12) {
        local piece "`a'-`b'"
    }
    else {
        local piece "`a'"
    }
    if ("`out'"=="") {
        local out "`piece'"
    }
    else {
        local out "`out', `piece'"
    }
    return local ranges "`out'"
end

* =======================================================================
* Mata engine.  Inside mata use // comments only.
* =======================================================================
version 14.0
mata:
mata set matastrict on

// ---- smallest highly composite (2,3,5) integer >= n : R stats::nextn ----
real scalar gs_nextn(real scalar n)
{
    real scalar m, r
    m = n
    while (1) {
        r = m
        while (mod(r,2)==0) r = r/2
        while (mod(r,3)==0) r = r/3
        while (mod(r,5)==0) r = r/5
        if (r==1) return(m)
        m = m + 1
    }
}

// ---- deterministic-term matrix for rows t0+1..T (type as in vars::VAR) --
// type: 0 = none, 1 = const, 2 = trend  (trend counts from t0+1 as in vars)
real matrix gs_det(real scalar Tn, real scalar t0, real scalar dtyp)
{
    if (dtyp==1) return(J(Tn-t0,1,1))
    if (dtyp==2) return(((t0+1)::Tn))
    return(J(Tn-t0,0,0))
}

// ---- OLS VAR(p) on rows t0+1..T ; returns A (K x K*p), Sigma, roots ----
// Sigma follows summary.varest: cov(resids)*(obs-1)/(obs - K*p - ndet),
// i.e. the DEMEANED residual crossproduct over (obs - K*p - ndet)
void gs_varfit(real matrix W, real scalar p, real scalar t0, real scalar dtyp, real matrix A, real matrix Sigma, real colvector rts, real matrix E)
{
    real matrix Y, Z, B, D, Comp
    real rowvector mu
    real scalar Tn, K, t, k, l, i, obs, ndet
    complex colvector ev
    Tn = rows(W)
    K  = cols(W)
    Y = W[(t0+1)..Tn, .]
    Z = J(Tn-t0, K*p, 0)
    for (t = t0+1; t <= Tn; t++) {
        for (k = 1; k <= p; k++) {
            for (l = 1; l <= K; l++) {
                Z[t-t0, (k-1)*K+l] = W[t-k, l]
            }
        }
    }
    D = gs_det(Tn, t0, dtyp)
    ndet = cols(D)
    Z = (Z, D)
    B = luinv(quadcross(Z,Z))*quadcross(Z,Y)
    E = Y - Z*B
    obs = Tn - t0
    mu = colsum(E)/obs
    Sigma = quadcross(E :- mu, E :- mu)/(obs - K*p - ndet)
    A = J(K, K*p, 0)
    for (k = 1; k <= p; k++) {
        for (i = 1; i <= K; i++) {
            for (l = 1; l <= K; l++) {
                A[i, (k-1)*K+l] = B[(k-1)*K+l, i]
            }
        }
    }
    if (p==1) Comp = A
    else {
        Comp = J(K*p, K*p, 0)
        Comp[1..K, .] = A
        Comp[(K+1)..(K*p), 1..(K*(p-1))] = I(K*(p-1))
    }
    ev = eigenvalues(Comp)'
    rts = abs(ev)
    rts = sort(rts, -1)
}

// ---- lag order selection replicating vars::VARselect --------------------
// common sample drops the first maxlag rows; detint = ndet per equation
real scalar gs_varselect(real matrix W, real scalar maxlag, string scalar ic, real scalar dtyp)
{
    real matrix Y, Z, B, E, Sg, D
    real scalar Tn, K, samp, i, t, k, l, best, val, ld, detint, popt
    Tn = rows(W)
    K  = cols(W)
    samp = Tn - maxlag
    D = gs_det(Tn, maxlag, dtyp)
    detint = cols(D)
    best = .
    popt = 1
    for (i = 1; i <= maxlag; i++) {
        Y = W[(maxlag+1)..Tn, .]
        Z = J(samp, K*i, 0)
        for (t = maxlag+1; t <= Tn; t++) {
            for (k = 1; k <= i; k++) {
                for (l = 1; l <= K; l++) {
                    Z[t-maxlag, (k-1)*K+l] = W[t-k, l]
                }
            }
        }
        Z = (Z, D)
        B = luinv(quadcross(Z,Z))*quadcross(Z,Y)
        E = Y - Z*B
        Sg = quadcross(E,E)/samp
        ld = ln(det(Sg))
        if (ic=="aic") val = ld + (2/samp)*(i*K*K + K*detint)
        else if (ic=="hq") val = ld + (2*ln(ln(samp))/samp)*(i*K*K + K*detint)
        else if (ic=="sc") val = ld + (ln(samp)/samp)*(i*K*K + K*detint)
        else val = ((samp + i*K + detint)/(samp - i*K - detint))^K * exp(ld)
        if (val < best) {
            best = val
            popt = i
        }
    }
    return(popt)
}

// ---- Fourier frequency grid: (1..floor(Npad/2))/Npad, Npad = nextn(n) ---
// replicates spec.pgram default fast=TRUE zero-padding to a (2,3,5)-smooth n
real colvector gs_freq(real scalar n)
{
    real scalar Npad, nf
    Npad = gs_nextn(n)
    nf = floor(Npad/2)
    return((1::nf)/Npad)
}

// ---- unconditional spectra kernel given a fitted VAR (literal R lines) --
void gs_uncspec(real matrix A, real matrix Sigma, real scalar p, real colvector fr, real colvector gyx, real colvector gxy)
{
    real matrix Px, P2
    real scalar K, nf, li, k
    complex matrix ADD, H, Hx, H2
    complex scalar ez, a1, a3, b1, b3
    K = 2
    nf = rows(fr)
    Px = (1, 0 \ -Sigma[1,2]/Sigma[1,1], 1)
    P2 = (1, -Sigma[2,1]/Sigma[2,2] \ 0, 1)
    gyx = J(nf,1,0)
    gxy = J(nf,1,0)
    for (li = 1; li <= nf; li++) {
        ADD = J(K,K,C(0,0))
        for (k = 1; k <= p; k++) {
            ez = exp(C(0, -2*pi()*k*fr[li]))
            ADD = ADD - A[., (k-1)*K+1 .. k*K]*ez
        }
        H  = luinv(ADD + I(K))
        Hx = luinv(Px*(ADD + I(K)))
        H2 = luinv(P2*(ADD + I(K)))
        a1 = 0.25*Hx[1,1]*Sigma[1,1]*conj(Hx[1,1])
        a3 = 0.25*H[1,2]*Sigma[2,2]*conj(H[1,2])
        gyx[li] = ln(abs(a1 + a3)/abs(a1))
        b1 = 0.25*H2[2,2]*Sigma[2,2]*conj(H2[2,2])
        b3 = 0.25*H[2,1]*Sigma[1,1]*conj(H[2,1])
        gxy[li] = ln(abs(b1 + b3)/abs(b1))
    }
}

// ---- unconditional spectra (Granger.unconditional, literal) -------------
void gs_uncond(string scalar vars, string scalar touse, real scalar maxlag, string scalar ic, string scalar typ, real scalar pfix)
{
    real matrix W, A, Sigma, E
    real colvector rts, fr, gyx, gxy
    real scalar Tn, p, dtyp
    W = st_data(., tokens(vars), touse)
    Tn = rows(W)
    dtyp = (typ=="const" ? 1 : (typ=="trend" ? 2 : 0))
    if (pfix>0) p = pfix
    else p = gs_varselect(W, maxlag, ic, dtyp)
    gs_varfit(W, p, p, dtyp, A, Sigma, rts, E)
    fr = gs_freq(Tn)
    gs_uncspec(A, Sigma, p, fr, gyx, gxy)
    st_matrix("r(freq)", fr)
    st_matrix("r(gc_yx)", gyx)
    st_matrix("r(gc_xy)", gxy)
    st_matrix("r(sigma)", Sigma)
    st_matrix("r(roots)", rts)
    st_numscalar("r(p)", p)
    st_numscalar("r(npad)", gs_nextn(Tn))
}

// ---- circular index as in tseries boot.c WRAP ---------------------------
real scalar gs_wrap(real scalar i, real scalar n)
{
    if (i > n) return(mod(i-1,n)+1)
    return(i)
}

// ---- stationary bootstrap of Politis-Romano, literal port of StatBoot ---
// (tseries boot.c) with the tsbootstrap default mean block b = 3.15*n^(1/3)
real matrix gs_statboot(real colvector x, real scalar B)
{
    real scalar n, pg, bfac, i, j, w, I, L
    real matrix out
    n = rows(x)
    pg = 1/(3.15*n^(1/3))
    bfac = (-1)/ln(1-pg)
    out = J(n, B, 0)
    for (w = 1; w <= B; w++) {
        i = 1
        while (i <= n) {
            I = floor(runiform(1,1)*n + 1)
            L = floor(bfac*rexponential(1,1,1))
            j = 0
            while (j < L & i <= n) {
                out[i,w] = x[gs_wrap(I+j,n)]
                i = i + 1
                j = j + 1
            }
        }
    }
    return(out)
}

// ---- R stats::median for a vector ---------------------------------------
real scalar gs_median(real colvector v)
{
    real colvector s
    real scalar m
    s = sort(v, 1)
    m = rows(s)
    if (mod(m,2)==1) return(s[(m+1)/2])
    return((s[m/2] + s[m/2+1])/2)
}

// ---- R stats::quantile default type 7 -----------------------------------
real scalar gs_quantile7(real colvector v, real scalar pr)
{
    real colvector s
    real scalar m, h, lo
    s = sort(v, 1)
    m = rows(s)
    if (m==1) return(s[1])
    h = (m-1)*pr + 1
    lo = floor(h)
    if (lo >= m) return(s[m])
    return(s[lo] + (h-lo)*(s[lo+1]-s[lo]))
}

// ---- bootstrap inference (Granger.inference.unconditional, literal) -----
// p==0 path: every bootstrap VAR goes through the IC path (const quirk).
// p>0 path replicates the R call chain exactly: the user p is overwritten
// by IC selection under type.chosen (pmod); bootstrap spectra are computed
// at fixed p=pmod with type "none" (Granger.unconditional own default);
// delay_bp is the IC selection under type.chosen on each bootstrap pair.
// Original spectra are always recomputed through the IC path (const quirk),
// as the R code calls Granger.unconditional(x,y,ic,max.lag,F).
void gs_boot_uncond(string scalar vars, string scalar touse, real scalar maxlag, string scalar ic, string scalar typu, real scalar pop, real scalar nboots, real scalar conf, real scalar usebp)
{
    external real matrix GS_BP
    real matrix W, Wb, Ab, Sb, Eb, Xb, Yb, A0, S0, E0
    real colvector fr, rb, gyx, gxy, med_yx, med_xy, delay, stat, g0yx, g0xy, r0, sel, sf
    real scalar Tn, nf, B, w, dtypu, pmod, pb, qx, qy, qmx, qmy, confb, nsr, statyes, porig
    W = st_data(., tokens(vars), touse)
    Tn = rows(W)
    fr = gs_freq(Tn)
    nf = rows(fr)
    dtypu = (typu=="const" ? 1 : (typu=="trend" ? 2 : 0))
    if (usebp) {
        if (rows(GS_BP) != Tn) {
            errprintf("bootdata() has %g rows but the estimation sample has %g observations\n", rows(GS_BP), Tn)
            exit(498)
        }
        B  = cols(GS_BP)/2
        Xb = GS_BP[., 1..B]
        Yb = GS_BP[., (B+1)..(2*B)]
    }
    else {
        B  = nboots
        Xb = gs_statboot(W[.,1], B)
        Yb = gs_statboot(W[.,2], B)
    }
    pmod = 0
    if (pop > 0) pmod = gs_varselect(W, maxlag, ic, dtypu)
    med_yx = J(B,1,0)
    med_xy = J(B,1,0)
    delay  = J(B,1,0)
    stat   = J(B,1,0)
    for (w = 1; w <= B; w++) {
        Wb = (Xb[.,w], Yb[.,w])
        if (pop == 0) {
            pb = gs_varselect(Wb, maxlag, ic, 1)
            delay[w] = pb
            gs_varfit(Wb, pb, pb, 1, Ab, Sb, rb, Eb)
        }
        else {
            delay[w] = gs_varselect(Wb, maxlag, ic, dtypu)
            pb = pmod
            gs_varfit(Wb, pb, pb, 0, Ab, Sb, rb, Eb)
        }
        gs_uncspec(Ab, Sb, pb, fr, gyx, gxy)
        med_yx[w] = gs_median(gyx)
        med_xy[w] = gs_median(gxy)
        if (max(rb) >= 1) stat[w] = 1
    }
    nsr = sum(stat)/B
    statyes = ((1-nsr) >= 1/B ? 1 : 0)
    st_numscalar("r(stat_yes)", statyes)
    st_numscalar("r(nonstat_rate)", nsr)
    st_numscalar("r(nboots)", B)
    if (statyes == 0) return
    sel = selectindex(stat :== 0)
    qx  = gs_quantile7(med_yx[sel], conf)
    qy  = gs_quantile7(med_xy[sel], conf)
    confb = 1 - (1-conf)/nf
    qmx = gs_quantile7(med_yx[sel], confb)
    qmy = gs_quantile7(med_xy[sel], confb)
    porig = gs_varselect(W, maxlag, ic, 1)
    gs_varfit(W, porig, porig, 1, A0, S0, r0, E0)
    gs_uncspec(A0, S0, porig, fr, g0yx, g0xy)
    st_matrix("r(freq)", fr)
    st_matrix("r(gc_yx)", g0yx)
    st_matrix("r(gc_xy)", g0xy)
    st_numscalar("r(p_orig)", porig)
    st_numscalar("r(npad)", gs_nextn(Tn))
    st_numscalar("r(q_x)", qx)
    st_numscalar("r(q_y)", qy)
    st_numscalar("r(q_max_x)", qmx)
    st_numscalar("r(q_max_y)", qmy)
    st_numscalar("r(delay_mean)", mean(delay[sel]))
    sf = selectindex(g0yx :> qx)
    st_numscalar("r(nsig_yx)", rows(sf))
    if (rows(sf) > 0) st_matrix("r(freq_sig_yx)", fr[sf])
    sf = selectindex(g0xy :> qy)
    st_numscalar("r(nsig_xy)", rows(sf))
    if (rows(sf) > 0) st_matrix("r(freq_sig_xy)", fr[sf])
    sf = selectindex(g0yx :> qmx)
    st_numscalar("r(nsig_max_yx)", rows(sf))
    if (rows(sf) > 0) st_matrix("r(freq_sig_max_yx)", fr[sf])
    sf = selectindex(g0xy :> qmy)
    st_numscalar("r(nsig_max_xy)", rows(sf))
    if (rows(sf) > 0) st_matrix("r(freq_sig_max_xy)", fr[sf])
}

// ---- conditional spectrum (Granger.conditional lines, literal) ----------
void gs_cond(string scalar vars, string scalar touse, real scalar maxlag, string scalar ic, string scalar typ1, string scalar typ2, real scalar p1f, real scalar p2f)
{
    real matrix W, W1, W2, A1, S1, A2, S2, E1, E2
    real colvector r1, r2, fr, gc
    real scalar Tn, p1, p2, dtyp1, dtyp2
    string rowvector tk
    tk = tokens(vars)
    W  = st_data(., tk, touse)
    Tn = rows(W)
    W1 = W[., (1,3)]
    W2 = W
    dtyp1 = (typ1=="const" ? 1 : (typ1=="trend" ? 2 : 0))
    dtyp2 = (typ2=="const" ? 1 : (typ2=="trend" ? 2 : 0))
    if (p1f>0) p1 = p1f
    else p1 = gs_varselect(W1, maxlag, ic, dtyp1)
    if (p2f>0) p2 = p2f
    else p2 = gs_varselect(W2, maxlag, ic, dtyp2)
    gs_varfit(W1, p1, p1, dtyp1, A1, S1, r1, E1)
    gs_varfit(W2, p2, p2, dtyp2, A2, S2, r2, E2)
    fr = gs_freq(Tn)
    gs_cndspec(A1, S1, p1, A2, S2, p2, fr, gc)
    st_matrix("r(freq)", fr)
    st_matrix("r(gc_yxz)", gc)
    st_matrix("r(sigma1)", S1)
    st_matrix("r(sigma2)", S2)
    st_matrix("r(roots1)", r1)
    st_matrix("r(roots2)", r2)
    st_numscalar("r(p1)", p1)
    st_numscalar("r(p2)", p2)
    st_numscalar("r(npad)", gs_nextn(Tn))
}

// ---- conditional spectrum kernel given the two fitted VARs (literal) ----
void gs_cndspec(real matrix A1, real matrix S1, real scalar p1, real matrix A2, real matrix S2, real scalar p2, real colvector fr, real colvector gc)
{
    real matrix Pm1, P1m, P2m, Pm
    real scalar nf, li, k, den
    complex matrix A1D, A2D, H11, H12, G, Q
    complex scalar ez, s1, s2, s3
    nf = rows(fr)
    Pm1 = (1, 0 \ -S1[1,2]/S1[1,1], 1)
    P1m = (1, 0, 0 \ -S2[2,1]/S2[1,1], 1, 0 \ -S2[3,1]/S2[1,1], 0, 1)
    den = S2[2,2] - S2[2,1]/S2[1,1]*S2[1,2]
    P2m = (1, 0, 0 \ 0, 1, 0 \ 0, -(S2[3,2] - S2[3,1]/S2[1,1]*S2[1,2])/den, 1)
    Pm  = P1m*P2m
    gc = J(nf,1,0)
    for (li = 1; li <= nf; li++) {
        A1D = J(2,2,C(0,0))
        for (k = 1; k <= p1; k++) {
            ez = exp(C(0, -2*pi()*k*fr[li]))
            A1D = A1D + A1[., (k-1)*2+1 .. k*2]*ez
        }
        A2D = J(3,3,C(0,0))
        for (k = 1; k <= p2; k++) {
            ez = exp(C(0, -2*pi()*k*fr[li]))
            A2D = A2D + A2[., (k-1)*3+1 .. k*3]*ez
        }
        H11 = luinv(Pm1*(I(2) - A1D))
        H12 = luinv(Pm*(I(3) - A2D))
        G = J(3,3,C(0,0))
        G[1,1] = H11[1,1]
        G[1,3] = H11[1,2]
        G[3,1] = H11[2,1]
        G[3,3] = H11[2,2]
        G[2,2] = C(1)
        Q = luinv(G)*H12
        s1 = Q[1,1]*S2[1,1]*conj(Q[1,1])
        s2 = Q[1,2]*S2[2,2]*conj(Q[1,2])
        s3 = Q[1,3]*S2[3,3]*conj(Q[1,3])
        gc[li] = ln(abs(s1 + s2 + s3)/abs(s1))
    }
}

// ---- bootstrap inference (Granger.inference.conditional, literal) -------
// All three series are bootstrapped independently by the stationary
// bootstrap, exactly as in the R code (which differs from the residual
// bootstrap described in the paper for the pair (X,W)).
// p1==p2==0 path: every bootstrap VAR goes through the IC path (const
// quirk), and delays are those IC selections. p1>0 and p2>0 path: the
// orders are genuinely fixed (no lag.max in the R calls), the bootstrap
// spectra are computed at fixed p1,p2 with type "none" (the own default
// of Granger.conditional), and delay1/delay2 stay equal to p1,p2.
// Stationarity is flagged separately for the two models; the quantiles
// use the intersection of stationary replicates, while delay1_mean and
// delay2_mean average over each model's own stationary subset.
// The original spectrum is always recomputed through the IC path.
void gs_boot_cond(string scalar vars, string scalar touse, real scalar maxlag, string scalar ic, string scalar typu, real scalar p1o, real scalar p2o, real scalar nboots, real scalar conf, real scalar usebp)
{
    external real matrix GS_BP
    real matrix W, Wxz, Wxyz, Xb, Yb, Zb, A1, S1, E1, A2, S2, E2, A01, S01, E01, A02, S02, E02
    real colvector fr, rb1, rb2, gc, med, delay1, delay2, t1, t2, statv, sel, sel1, sel2, g0, r01, r02, sf
    real scalar Tn, nf, B, w, dtypu, pb1, pb2, qx, qmx, confb, nsr1, nsr2, statyes, po1, po2
    W = st_data(., tokens(vars), touse)
    Tn = rows(W)
    fr = gs_freq(Tn)
    nf = rows(fr)
    dtypu = (typu=="const" ? 1 : (typu=="trend" ? 2 : 0))
    if (usebp) {
        if (rows(GS_BP) != Tn) {
            errprintf("bootdata() has %g rows but the estimation sample has %g observations\n", rows(GS_BP), Tn)
            exit(498)
        }
        B  = cols(GS_BP)/3
        Xb = GS_BP[., 1..B]
        Yb = GS_BP[., (B+1)..(2*B)]
        Zb = GS_BP[., (2*B+1)..(3*B)]
    }
    else {
        B  = nboots
        Xb = gs_statboot(W[.,1], B)
        Yb = gs_statboot(W[.,2], B)
        Zb = gs_statboot(W[.,3], B)
    }
    med    = J(B,1,0)
    delay1 = J(B,1,0)
    delay2 = J(B,1,0)
    t1     = J(B,1,0)
    t2     = J(B,1,0)
    for (w = 1; w <= B; w++) {
        Wxz  = (Xb[.,w], Zb[.,w])
        Wxyz = (Xb[.,w], Yb[.,w], Zb[.,w])
        if (p1o == 0) {
            pb1 = gs_varselect(Wxz, maxlag, ic, 1)
            pb2 = gs_varselect(Wxyz, maxlag, ic, 1)
            delay1[w] = pb1
            delay2[w] = pb2
            gs_varfit(Wxz, pb1, pb1, 1, A1, S1, rb1, E1)
            gs_varfit(Wxyz, pb2, pb2, 1, A2, S2, rb2, E2)
        }
        else {
            pb1 = p1o
            pb2 = p2o
            delay1[w] = pb1
            delay2[w] = pb2
            gs_varfit(Wxz, pb1, pb1, 0, A1, S1, rb1, E1)
            gs_varfit(Wxyz, pb2, pb2, 0, A2, S2, rb2, E2)
        }
        gs_cndspec(A1, S1, pb1, A2, S2, pb2, fr, gc)
        med[w] = gs_median(gc)
        if (max(rb1) >= 1) t1[w] = 1
        if (max(rb2) >= 1) t2[w] = 1
    }
    statv = (t1 :== 0) :& (t2 :== 0)
    nsr1 = sum(t1)/B
    nsr2 = sum(t2)/B
    statyes = (sum(statv) >= 1 ? 1 : 0)
    st_numscalar("r(stat_yes)", statyes)
    st_numscalar("r(nonstat_rate1)", nsr1)
    st_numscalar("r(nonstat_rate2)", nsr2)
    st_numscalar("r(nboots)", B)
    if (statyes == 0) return
    sel  = selectindex(statv)
    sel1 = selectindex(t1 :== 0)
    sel2 = selectindex(t2 :== 0)
    qx  = gs_quantile7(med[sel], conf)
    confb = 1 - (1-conf)/nf
    qmx = gs_quantile7(med[sel], confb)
    po1 = gs_varselect(W[., (1,3)], maxlag, ic, 1)
    po2 = gs_varselect(W, maxlag, ic, 1)
    gs_varfit(W[., (1,3)], po1, po1, 1, A01, S01, r01, E01)
    gs_varfit(W, po2, po2, 1, A02, S02, r02, E02)
    gs_cndspec(A01, S01, po1, A02, S02, po2, fr, g0)
    st_matrix("r(freq)", fr)
    st_matrix("r(gc_yxz)", g0)
    st_numscalar("r(p_orig1)", po1)
    st_numscalar("r(p_orig2)", po2)
    st_numscalar("r(npad)", gs_nextn(Tn))
    st_numscalar("r(q_x_z)", qx)
    st_numscalar("r(q_max_x_z)", qmx)
    st_numscalar("r(delay1_mean)", mean(delay1[sel1]))
    st_numscalar("r(delay2_mean)", mean(delay2[sel2]))
    sf = selectindex(g0 :> qx)
    st_numscalar("r(nsig)", rows(sf))
    if (rows(sf) > 0) st_matrix("r(freq_sig)", fr[sf])
    sf = selectindex(g0 :> qmx)
    st_numscalar("r(nsig_max)", rows(sf))
    if (rows(sf) > 0) st_matrix("r(freq_sig_max)", fr[sf])
}

// ---- bootstrap difference test (Granger.inference.difference, literal) --
// Signed difference uncond - cond per frequency; per-replicate median of
// the signed differences; two-sided thresholds at (1-conf)/2 and
// 1-(1-conf)/2 on the stationary intersection of THREE flags (uncond VAR,
// bivariate x,z VAR, trivariate VAR). The R 0.1.1 "max" band sets
// alpha_b = (1-conf)/F but plugs it into the LEVEL formulas, so its
// quantile levels are (1-alpha_b)/2 and 1-(1-alpha_b)/2, a hair around the
// median; bonfadj=1 replaces them by the intended alpha_b/2 and
// 1-alpha_b/2 (not available in R). Original curves recomputed via the IC
// path, and the same p/p1/p2 call-chain quirks as in the other two
// inference functions are replicated.
void gs_boot_diff(string scalar vars, string scalar touse, real scalar maxlag, string scalar ic, string scalar typu, real scalar pop, real scalar p1o, real scalar p2o, real scalar nboots, real scalar conf, real scalar usebp, real scalar bonfadj)
{
    external real matrix GS_BP
    real matrix W, Wxy, Wxz, Wxyz, Xb, Yb, Zb, Au, Su, Eu, A1, S1, E1, A2, S2, E2, A0u, S0u, E0u, A01, S01, E01, A02, S02, E02
    real colvector fr, ru, rb1, rb2, gyx, gxy, gcc, dvec, med, t0v, t1v, t2v, statv, sel, g0yx, g0xy, g0c, d0, r0u, r01, r02, sf
    real scalar Tn, nf, B, w, dtypu, pmod, pbu, pb1, pb2, qs, qi, qms, qmi, alphab, nsr0, nsr1, nsr2, statyes, po, po1, po2
    W = st_data(., tokens(vars), touse)
    Tn = rows(W)
    fr = gs_freq(Tn)
    nf = rows(fr)
    dtypu = (typu=="const" ? 1 : (typu=="trend" ? 2 : 0))
    if (usebp) {
        if (rows(GS_BP) != Tn) {
            errprintf("bootdata() has %g rows but the estimation sample has %g observations\n", rows(GS_BP), Tn)
            exit(498)
        }
        B  = cols(GS_BP)/3
        Xb = GS_BP[., 1..B]
        Yb = GS_BP[., (B+1)..(2*B)]
        Zb = GS_BP[., (2*B+1)..(3*B)]
    }
    else {
        B  = nboots
        Xb = gs_statboot(W[.,1], B)
        Yb = gs_statboot(W[.,2], B)
        Zb = gs_statboot(W[.,3], B)
    }
    pmod = 0
    if (pop > 0) pmod = gs_varselect(W[., (1,2)], maxlag, ic, dtypu)
    med = J(B,1,0)
    t0v = J(B,1,0)
    t1v = J(B,1,0)
    t2v = J(B,1,0)
    for (w = 1; w <= B; w++) {
        Wxy  = (Xb[.,w], Yb[.,w])
        Wxz  = (Xb[.,w], Zb[.,w])
        Wxyz = (Xb[.,w], Yb[.,w], Zb[.,w])
        if (pop == 0) {
            pbu = gs_varselect(Wxy, maxlag, ic, 1)
            gs_varfit(Wxy, pbu, pbu, 1, Au, Su, ru, Eu)
        }
        else {
            pbu = pmod
            gs_varfit(Wxy, pbu, pbu, 0, Au, Su, ru, Eu)
        }
        gs_uncspec(Au, Su, pbu, fr, gyx, gxy)
        if (max(ru) >= 1) t0v[w] = 1
        if (p1o == 0) {
            pb1 = gs_varselect(Wxz, maxlag, ic, 1)
            pb2 = gs_varselect(Wxyz, maxlag, ic, 1)
            gs_varfit(Wxz, pb1, pb1, 1, A1, S1, rb1, E1)
            gs_varfit(Wxyz, pb2, pb2, 1, A2, S2, rb2, E2)
        }
        else {
            pb1 = p1o
            pb2 = p2o
            gs_varfit(Wxz, pb1, pb1, 0, A1, S1, rb1, E1)
            gs_varfit(Wxyz, pb2, pb2, 0, A2, S2, rb2, E2)
        }
        gs_cndspec(A1, S1, pb1, A2, S2, pb2, fr, gcc)
        if (max(rb1) >= 1) t1v[w] = 1
        if (max(rb2) >= 1) t2v[w] = 1
        dvec = gyx - gcc
        med[w] = gs_median(dvec)
    }
    statv = (t0v :== 0) :& (t1v :== 0) :& (t2v :== 0)
    nsr0 = sum(t0v)/B
    nsr1 = sum(t1v)/B
    nsr2 = sum(t2v)/B
    statyes = (sum(statv) >= 1 ? 1 : 0)
    st_numscalar("r(stat_yes)", statyes)
    st_numscalar("r(nonstat_rate)", nsr0)
    st_numscalar("r(nonstat_rate1)", nsr1)
    st_numscalar("r(nonstat_rate2)", nsr2)
    st_numscalar("r(nboots)", B)
    if (statyes == 0) return
    sel = selectindex(statv)
    qi = gs_quantile7(med[sel], (1-conf)/2)
    qs = gs_quantile7(med[sel], 1-(1-conf)/2)
    alphab = (1-conf)/nf
    if (bonfadj) {
        qmi = gs_quantile7(med[sel], alphab/2)
        qms = gs_quantile7(med[sel], 1-alphab/2)
    }
    else {
        qmi = gs_quantile7(med[sel], (1-alphab)/2)
        qms = gs_quantile7(med[sel], 1-(1-alphab)/2)
    }
    po = gs_varselect(W[., (1,2)], maxlag, ic, 1)
    gs_varfit(W[., (1,2)], po, po, 1, A0u, S0u, r0u, E0u)
    gs_uncspec(A0u, S0u, po, fr, g0yx, g0xy)
    po1 = gs_varselect(W[., (1,3)], maxlag, ic, 1)
    po2 = gs_varselect(W, maxlag, ic, 1)
    gs_varfit(W[., (1,3)], po1, po1, 1, A01, S01, r01, E01)
    gs_varfit(W, po2, po2, 1, A02, S02, r02, E02)
    gs_cndspec(A01, S01, po1, A02, S02, po2, fr, g0c)
    d0 = g0yx - g0c
    st_matrix("r(freq)", fr)
    st_matrix("r(diff)", d0)
    st_numscalar("r(p_orig)", po)
    st_numscalar("r(p_orig1)", po1)
    st_numscalar("r(p_orig2)", po2)
    st_numscalar("r(npad)", gs_nextn(Tn))
    st_numscalar("r(q_diff_sup)", qs)
    st_numscalar("r(q_diff_inf)", qi)
    st_numscalar("r(q_diff_max_sup)", qms)
    st_numscalar("r(q_diff_max_inf)", qmi)
    sf = selectindex(d0 :> qs)
    st_numscalar("r(nsig_sup)", rows(sf))
    if (rows(sf) > 0) st_matrix("r(freq_sup)", fr[sf])
    sf = selectindex(d0 :< qi)
    st_numscalar("r(nsig_inf)", rows(sf))
    if (rows(sf) > 0) st_matrix("r(freq_inf)", fr[sf])
    sf = selectindex(d0 :> qms)
    st_numscalar("r(nsig_max_sup)", rows(sf))
    if (rows(sf) > 0) st_matrix("r(freq_max_sup)", fr[sf])
    sf = selectindex(d0 :< qmi)
    st_numscalar("r(nsig_max_inf)", rows(sf))
    if (rows(sf) > 0) st_matrix("r(freq_max_inf)", fr[sf])
}

// ---- Breitung-Candelon tests (bc_test_uncond / bc_test_cond, literal) ---
// The restriction is R(w)*beta = 0 on the y-lag coefficients of the x
// equation (Breitung and Candelon 2006, eqs. 10-13). The R 0.1.1 code is
// replicated exactly, including: the two sequential (non-exclusive) if
// blocks, whereby the IC branch selects the order under the const quirk
// and then FALLS THROUGH into the fixed-order branch, refitting the VAR
// at that order with type.chosen (default none), which is the model the
// test actually uses; the restriction covariance built from the y-lag
// block alone (not the full regressor matrix); the full series length n
// in the F denominators; the conditional variant evaluating the
// trigonometric rows at HALF the angular frequency (cos(pi f k) instead
// of cos(2 pi f k)); the single-restriction F(1, n-p) at the last
// frequency; and the promotion of p = 1 (user-supplied or IC-selected)
// to p = 2.
void gs_bc(string scalar vars, string scalar touse, real scalar maxlag, string scalar ic, string scalar typu, real scalar pop, real scalar conf, real scalar iscond)
{
    real matrix W, A, Sg, E, Xall, XX, XXi, Rm, Rm1
    real colvector rts, fr, beta, Ftest, pval, Fthr, sf, d
    real scalar Tn, nf, K, p, dtypu, sse, li, k, t, mult, wald, n
    W = st_data(., tokens(vars), touse)
    Tn = rows(W)
    K  = cols(W)
    fr = gs_freq(Tn)
    nf = rows(fr)
    dtypu = (typu=="const" ? 1 : (typu=="trend" ? 2 : 0))
    if (pop <= 0) {
        p = gs_varselect(W, maxlag, ic, 1)
        if (p == 1) p = 2
    }
    else {
        p = (pop == 1 ? 2 : pop)
    }
    gs_varfit(W, p, p, dtypu, A, Sg, rts, E)
    beta = J(p,1,0)
    for (k = 1; k <= p; k++) {
        beta[k] = A[1, (k-1)*K + 2]
    }
    sse = quadcross(E[.,1], E[.,1])
    Xall = J(Tn-p, p, 0)
    for (t = p+1; t <= Tn; t++) {
        for (k = 1; k <= p; k++) {
            Xall[t-p, k] = W[t-k, 2]
        }
    }
    XX  = quadcross(Xall, Xall)
    XXi = luinv(XX)
    mult = (iscond ? pi() : 2*pi())
    n = Tn
    Ftest = J(nf,1,0)
    pval  = J(nf,1,0)
    Fthr  = J(nf,1,0)
    for (li = 1; li <= nf; li++) {
        if (li < nf) {
            Rm = J(2,p,0)
            for (k = 1; k <= p; k++) {
                Rm[1,k] = cos(mult*fr[li]*k)
                Rm[2,k] = sin(mult*fr[li]*k)
            }
            d = -Rm*beta
            wald = d'*luinv(Rm*XXi*Rm')*d
            Ftest[li] = (wald/2)/(sse/(n - 2*p))
            pval[li]  = Ftail(2, n - 2*p, Ftest[li])
            Fthr[li]  = invFtail(2, n - 2*p, 1-conf)
        }
        else {
            Rm1 = J(1,p,0)
            for (k = 1; k <= p; k++) {
                Rm1[1,k] = cos(mult*fr[li]*k)
            }
            d = -Rm1*beta
            wald = d'*luinv(Rm1*XXi*Rm1')*d
            Ftest[li] = (wald/1)/(sse/(n - 1*p))
            pval[li]  = Ftail(1, n - 1*p, Ftest[li])
            Fthr[li]  = invFtail(1, n - 1*p, 1-conf)
        }
    }
    sf = selectindex(pval :< (1-conf))
    st_matrix("r(freq)", fr)
    st_matrix("r(F)", Ftest)
    st_matrix("r(pval)", pval)
    st_matrix("r(Fthr)", Fthr)
    st_matrix("r(roots)", rts)
    st_numscalar("r(p)", p)
    st_numscalar("r(npad)", gs_nextn(Tn))
    st_numscalar("r(nsig)", rows(sf))
    if (rows(sf) > 0) st_matrix("r(freq_sig)", fr[sf])
}

end
