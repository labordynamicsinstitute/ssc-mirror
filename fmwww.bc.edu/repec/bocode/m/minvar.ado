*! version 1.0.0  29aug2026  Justin Dyer
*! minvar -- longitudinal measurement invariance testing with effects-coded sem
*
* Fits configural, weak (equal loadings), strong (equal loadings and
* intercepts), and optionally strict (equal residual variances) models across
* the timepoints/groups supplied in k1()...k16(), with any number of
* indicators. Reports fit and nested comparisons following Putnick &
* Bornstein (2016), and optionally saves factor scores from the strong model.
*
* Identification: effects coding (Little, Slegers, & Card 2006) -- within each
* factor the loadings sum to the number of indicators and the intercepts sum
* to 0, so the latent variables keep the metric of the items and factor means
* are estimated at every timepoint.
* Labels: L<t>_<i> = loading of indicator i at timepoint t,
*         T<t>_<i> = intercept of indicator i at timepoint t,
*         RV<i>    = residual variance of indicator i (strict model only)
*   configural: every timepoint has its own L<t>_ and T<t>_ labels
*   weak:       all timepoints share timepoint 1's loading labels (L1_)
*   strong:     all timepoints share L1_ and T1_ labels
*   strict:     as strong, plus RV<i> shared across timepoints
* The residual of each item is allowed to covary with the residual of the SAME
* item at every other timepoint; cross-time residual covariances stay free in
* every model, including strict.

cap program drop minvar
program minvar, rclass
    version 15
    syntax [if], [ ///
        k1(string) k2(string) k3(string) k4(string) ///
        k5(string) k6(string) k7(string) k8(string) ///
        k9(string) k10(string) k11(string) k12(string) ///
        k13(string) k14(string) k15(string) k16(string) ///
        t1(string) t2(string) t3(string) t4(string) ///
        t5(string) t6(string) t7(string) t8(string) ///
        t9(string) t10(string) t11(string) t12(string) ///
        t13(string) t14(string) t15(string) t16(string) ///
        factors(integer 0) indnum(integer 0) ///
        SAVE(string) NAME(string) ///
        cov(string) cov2(string) cov3(string) cov4(string) ///
        cov5(string) cov6(string) cov7(string) cov8(string) ///
        STRONGonly STRICT METHod(string) SEMopts(string) NOMINDices LOG ]

    local maxk 16

    * ---- t#() is accepted as a synonym for k#() ----
    forvalues j = 1/`maxk' {
        if `"`k`j''"' != "" & `"`t`j''"' != "" {
            di as error "both k`j'() and t`j'() were specified -- use one or the other"
            exit 198
        }
        if `"`k`j''"' == "" & `"`t`j''"' != "" local k`j' `"`t`j''"'
    }
    if `"`k1'"' == "" | `"`k2'"' == "" {
        di as error "k1() and k2() are required (indicator lists for the first two timepoints/groups)"
        exit 198
    }

    * ---- number of timepoints/groups ----
    local T 0
    forvalues j = 1/`maxk' {
        if `"`k`j''"' != "" {
            if `j' != `T' + 1 {
                local prev = `j' - 1
                di as error "k`j'() was specified but k`prev'() is empty -- fill in k#() in order"
                exit 198
            }
            local T `j'
        }
    }
    if `factors' == 0 local factors `T'
    if `factors' > `T' {
        di as error "factors(`factors') requested but only `T' k#() lists were given"
        exit 198
    }
    if `factors' < 2 {
        di as error "at least two timepoints/groups are required"
        exit 198
    }
    if `factors' < `T' {
        di as text "note: `T' k#() lists given; using only the first `factors' because of factors(`factors')"
    }

    * ---- expand/validate the variable lists ----
    forvalues j = 1/`factors' {
        unab k`j' : `k`j''
    }

    * ---- number of indicators ----
    local nind = wordcount(`"`k1'"')
    if `nind' < 2 {
        di as error "k1() must contain at least 2 indicators"
        exit 198
    }
    forvalues j = 2/`factors' {
        local nj = wordcount(`"`k`j''"')
        if `nj' != `nind' {
            di as error "k`j'() has `nj' variables but k1() has `nind' -- every k#() needs the same items in the same order"
            exit 198
        }
    }
    if `indnum' != 0 & `indnum' != `nind' {
        di as error "indnum(`indnum') does not match the `nind' variables in k1()"
        exit 198
    }

    * ---- name() for the latent variables / saved factor scores ----
    if "`name'" == "" {
        di as error "name() is required, e.g. name(anx) creates latents anx1 anx2 ..."
        exit 198
    }
    * (existing `name'# variables are tolerated by sem and are only replaced,
    *  just before predict, when save(yes) is specified)

    if "`method'" == "" local method mlmv
    * iteration logs are suppressed unless the log option is given
    local logopt nolog
    if "`log'" != "" local logopt
    local usercov `cov' `cov2' `cov3' `cov4' `cov5' `cov6' `cov7' `cov8'

    * ---- latent variable list ----
    local latlist
    forvalues j = 1/`factors' {
        local latlist `latlist' `name'`j'
    }

    * ---- residual covariances: same item across every pair of timepoints ----
    local rescov
    forvalues i = 1/`nind' {
        local last = `factors' - 1
        forvalues j = 1/`last' {
            local v1 : word `i' of `k`j''
            local jp1 = `j' + 1
            forvalues s = `jp1'/`factors' {
                local v2 : word `i' of `k`s''
                local rescov `rescov' cov(e.`v1'*e.`v2')
            }
        }
    }

    * ---- build the model specifications ----
    foreach m in config weak strong {
        local spec_`m'
    }
    forvalues j = 1/`factors' {
        local var1 : word 1 of `k`j''
        foreach m in config weak strong {
            * which timepoint's labels apply to loadings (lt) and intercepts (tt)
            if "`m'" == "config" {
                local lt `j'
                local tt `j'
            }
            else if "`m'" == "weak" {
                local lt 1
                local tt `j'
            }
            else {
                local lt 1
                local tt 1
            }
            local lsum
            local isum
            forvalues i = 2/`nind' {
                local lsum `lsum'-L`lt'_`i'
                local isum `isum'-T`tt'_`i'
            }
            local s (`name'`j'@(`nind'`lsum') -> `var1')
            forvalues i = 2/`nind' {
                local vi : word `i' of `k`j''
                local s `s' (`name'`j'@L`lt'_`i' -> `vi')
            }
            local s `s' (`var1' <- _cons@(0`isum'))
            forvalues i = 2/`nind' {
                local vi : word `i' of `k`j''
                local s `s' (`vi' <- _cons@T`tt'_`i')
            }
            local spec_`m' `spec_`m'' `s'
        }
    }

    * ---- fit the models ----
    if "`strongonly'" != "" & "`strict'" != "" {
        di as error "strict cannot be combined with strongonly"
        exit 198
    }
    if "`strongonly'" != "" local models strong
    else if "`strict'" != "" local models config weak strong strict
    else local models config weak strong
    local lastm = word("`models'", wordcount("`models'"))

    * strict model: strong + each item's residual variance equated across
    * timepoints (labels RV<i>); cross-time residual covariances stay free
    local strictvar
    if "`strict'" != "" {
        forvalues i = 1/`nind' {
            forvalues j = 1/`factors' {
                local vi : word `i' of `k`j''
                local strictvar `strictvar' var(e.`vi'@RV`i')
            }
        }
        local spec_strict `spec_strong'
    }

    local lbl_config "configural (free loadings and intercepts)"
    local lbl_weak   "weak / metric (equal loadings)"
    local lbl_strong "strong / scalar (equal loadings and intercepts)"
    local lbl_strict "strict / residual (equal loadings, intercepts, residual variances)"

    foreach m of local models {
        local extra
        if "`m'" == "strict" local extra `strictvar'
        di as result _n "{hline 70}"
        di as result "minvar: `lbl_`m'' model"
        if "`log'" == "" {
            di as text "fitting -- started `c(current_time)'; results display when estimation finishes"
        }
        di as result "{hline 70}"
        timer clear 97
        timer on 97
        sem `spec_`m'' `if', ///
            `rescov' `usercov' `extra' ///
            latent(`latlist') means(`latlist') ///
            method(`method') `semopts' `logopt' nocapslatent
        timer off 97
        qui timer list 97
        di as text "(fit in " as result %5.1f r(t97) as text " seconds)"
        timer clear 97
        estimates store `m'
        local `m'_N = e(N)
        estat gof, stats(all)
        local `m'_cfi   = r(cfi)
        local `m'_tli   = r(tli)
        local `m'_rmsea = r(rmsea)
        local `m'_lb90  = r(lb90_rmsea)
        local `m'_ub90  = r(ub90_rmsea)
        local `m'_srmr  = r(srmr)
        local `m'_chi2  = r(chi2_ms)
        local `m'_df    = r(df_ms)
        if "`nomindices'" == "" cap noisily estat mindices
    }

    * ---- nested-model comparisons (run quietly; shown in the table) ----
    local complist
    local prev
    foreach m of local models {
        if "`prev'" != "" {
            qui lrtest `prev' `m'
            local lrchi2_`m' = r(chi2)
            local lrdf_`m'   = r(df)
            local lrp_`m'    = r(p)
            local dcfi_`m'   = ``m'_cfi'   - ``prev'_cfi'
            local drmsea_`m' = ``m'_rmsea' - ``prev'_rmsea'
            local dsrmr_`m'  = ``m'_srmr'  - ``prev'_srmr'
            local prevof_`m' `prev'
            local complist `complist' `m'
        }
        local prev `m'
    }

    * ---- fit table (layout follows Putnick & Bornstein 2016, Table 3) ----
    local mlab_config "Configural"
    local mlab_weak   "Weak (metric)"
    local mlab_strong "Strong (scalar)"
    local mlab_strict "Strict (resid.)"
    local slab_config "Configural"
    local slab_weak   "Weak"
    local slab_strong "Strong"
    local slab_strict "Strict"

    di as result _n "{hline 78}"
    di as text "Measurement invariance: model fit and nested comparisons"
    di as result "{hline 78}"
    di as text "Model" _col(21) "chi2" _col(27) "df" _col(33) "CFI" _col(40) "TLI" _col(45) "RMSEA  [90% CI]" _col(69) "SRMR"
    di as text "{hline 78}"
    foreach m of local models {
        di as text %-15s "`mlab_`m''" ///
            as result _col(16) %9.2f ``m'_chi2' ///
            _col(26) %4.0f ``m'_df' ///
            _col(31) %6.3f ``m'_cfi' ///
            _col(38) %6.3f ``m'_tli' ///
            _col(45) %6.3f ``m'_rmsea' ///
            "  [" %5.3f ``m'_lb90' ", " %5.3f ``m'_ub90' "]" ///
            _col(68) %6.3f ``m'_srmr'
    }
    if "`complist'" != "" {
        di as result "{hline 78}"
        di as text "Comparison" _col(25) "Dchi2" _col(32) "Ddf" _col(40) "p" _col(45) "DCFI" _col(52) "DRMSEA" _col(61) "DSRMR"
        di as result "{hline 78}"
        foreach m of local complist {
            local pv `prevof_`m''
            di as text %-21s "`slab_`m'' vs `slab_`pv''" ///
                as result _col(22) %8.2f `lrchi2_`m'' ///
                _col(31) %4.0f `lrdf_`m'' ///
                _col(36) %6.3f `lrp_`m'' ///
                _col(43) %7.3f `dcfi_`m'' ///
                _col(52) %7.3f `drmsea_`m'' ///
                _col(60) %7.3f `dsrmr_`m''
        }
    }
    di as result "{hline 78}"
    if "`method'" == "mlmv" {
        di as text "N = " as result ``lastm'_N' ///
            as text ".  Estimation: method(mlmv), FIML -- all available observations used."
    }
    else {
        di as text "N = " as result ``lastm'_N' as text ".  Estimation: method(`method')."
    }
    if ``lastm'_srmr' >= . {
        di as text "SRMR is not available under method(mlmv) when data contain missing values."
    }

    * ---- what would constitute invariance ----
    if "`complist'" != "" {
        di as text _n "Invariance guidelines (Putnick & Bornstein 2016, Dev Review 41:71-90):"
        di as text "  A step is supported when fit does not meaningfully worsen relative to the"
        di as text "  previous model: DCFI >= -.010 (Cheung & Rensvold 2002), together with"
        di as text "  DRMSEA <= .015 and DSRMR <= .030 for the weak step or <= .015 for the"
        di as text "  strong/strict steps (Chen 2007). A nonsignificant Dchi2 (p > .05) also"
        di as text "  supports invariance, but chi2 is oversensitive in large samples, so the"
        di as text "  DCFI criterion is usually given precedence."
    }

    * ---- factor scores from the strong model ----
    if "`save'" == "yes" {
        if "`strict'" != "" qui estimates restore strong
        forvalues j = 1/`factors' {
            cap drop `name'`j'
            predict `name'`j' if e(sample)==1, latent(`name'`j')
            label variable `name'`j' "`name'`j' factor score (strong invariance)"
        }
        di as text _n "Factor scores saved: " as result "`latlist'"
        if "`strongonly'" == "" {
            if `dcfi_strong' < -.01 {
                di as error _n "Warning: strong (scalar) invariance is questionable (DCFI = " ///
                    %6.3f `dcfi_strong' " < -.010)."
                di as error "Factor scores were saved anyway; consider a partial-invariance"
                di as error "model before comparing means."
            }
        }
    }

    * ---- clean up the estimates-store marker variables ----
    * one per statement: drop is all-or-nothing, and not every model is fit
    * on every path
    cap drop _est_config
    cap drop _est_weak
    cap drop _est_strong
    cap drop _est_strict

    * ---- returned results ----
    foreach m of local models {
        return scalar cfi_`m'   = ``m'_cfi'
        return scalar tli_`m'   = ``m'_tli'
        return scalar rmsea_`m' = ``m'_rmsea'
        return scalar srmr_`m'  = ``m'_srmr'
        return scalar chi2_`m'  = ``m'_chi2'
        return scalar df_`m'    = ``m'_df'
    }
    foreach m of local complist {
        return scalar dcfi_`m'   = `dcfi_`m''
        return scalar drmsea_`m' = `drmsea_`m''
        return scalar dsrmr_`m'  = `dsrmr_`m''
        return scalar lrchi2_`m' = `lrchi2_`m''
        return scalar lrdf_`m'   = `lrdf_`m''
        return scalar lrp_`m'    = `lrp_`m''
    }
    return scalar N       = ``lastm'_N'
    return scalar factors = `factors'
    return scalar indnum  = `nind'
    return local  latent  `latlist'
end
