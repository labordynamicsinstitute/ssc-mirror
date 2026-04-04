*! version 2.07 09mar2026
*! Ben Adarkwa Dwamena (University of Michigan)
*! midas_inla: INLA engine for bivariate DTA meta-analysis
*! Requires: R + INLA installed and accessible via rpath()
*! v2.07: all six covariance priors (iwishart, cholesky, siw, huangwand,
*!   spherical, prodnormal) now fully compatible with INLA 25.x rgeneric API.
*!   Rgeneric fixes: (1) log.norm.const returns numeric(0) not scalar 0;
*!   (2) build.S inlined inside each rgeneric closure (child R process scoping);
*!   (3) inla.rgeneric.define n=2*nstudies with Q using Diagonal(n/2,...);
*!   (4) num.threads='1:1' for serial R callback safety;
*!   (5) initial values tuned c(-0.5,-0.5,0), spherical c(-0.5,-0.5,0.785);
*!   (6) removed verbose/safe debug flags for production use.
*!   Stata-side: reshape fixed via keep (not drop); mat sems transpose removed.
*! v2.06: fixed $ eaten by Stata macro expansion in file write for rgeneric
*!   Q/log.norm.const/log.prior (tmp$S, tmp$sigma2, tmp$rho became tmp,
*!   causing "Error in solve.default(tmp): 'a' must be a numeric matrix");
*!   also fixed $studyid, $P1, $P2 in R output extraction lines;
*!   uses filefilter DOLLAR->$ approach for safe literal $ emission;
*!   fixed iwishart hyper spec for INLA >=24.x (prec->theta, n->2*nstudies);
*!   converted all S4 @ slot accessors to S3 $ list accessors (midas@dic,
*!   midas@waic, midas@cpo, midas@summary.*, hyper@mlik,
*!   hyper@internal.marginals.hyperpar) for INLA 25.x compatibility.
*! v2.05: purged Python scaffolding from rinla_script (if/elif/else/for/def/pass/True/False);
*!   replaced mata:hmc_mat() with native Stata summarize/corr in inla_mat;
*!   removed orphan bhess/Vhess references; removed spurious R if(TRUE){} wrapper;
*!   added global touse cleanup; StudyIds now dropped after use.
*! v2.04: study-level INLA indexing fixes; avgn1/avgn2 passed to inla_mat;
*!   oldpwd restore fixed; cross-platform R call; helper drop-on-call extended;
*!   ASCII-safe labels; string-option tests normalized.

cap program drop midas_inla
program define midas_inla, eclass byable(recall) sortpreserve

if _by() {
    local BY `"by `_byvars'`_byrc0':"'
}

if !replay() {

    // Force helpers to reload from ado on every call (clears stale cached versions)
    cap program drop makeinladata inla_mat midas_sim_data inla_weights
    cap program drop inla_ppp inla_reffects inla_fitted rinla_script
    cap program drop inla_sumstats inla_sumstats_hpd inla_sumstats_interp
    cap program drop _inla_summarize

    //------------------------------------------------------------------
    // 1. Parse syntax
    //------------------------------------------------------------------
    #delimit ;
    syntax varlist(min=4 max=4) [if] [in] ,
    Rpath(string)
    [ WORKdir(string)
    ID(varname)
    LINK(string)
    COVmatrix(string)
    MANual
    APProximation(string)
    INTegration(string)
    NIP(integer 20)
    SORTby(varlist min=1)
    STABLE
    HPD
    Level(cilevel)
    noCOEFficients
    noSUMmary
    noHEADer
    noFITstats
    HETstats
    HSROC
    SHOWcode
    REVman
    * ] ;
    #delimit cr

    // Resolve working directory (default = c(sysdir_personal))
    if `"`workdir'"' == "" {
        local workdir = subinstr(c(sysdir_personal), "\", "/", .)
    }
    else {
        local workdir = subinstr(`"`workdir'"', "\", "/", .)
    }
    while substr("`workdir'", length("`workdir'"), 1) == "/" ///
    & length("`workdir'") > 3 {
        local workdir = substr("`workdir'", 1, length("`workdir'")-1)
    }

    // cross-platform directory existence test
    local oldpwd = c(pwd)
    cap cd "`workdir'"
    if _rc {
        cap mkdir "`workdir'"
        cap cd "`workdir'"
        if _rc {
            di as error "workdir `workdir' does not exist and could not be created"
            exit 693
        }
    }
    cap cd "`oldpwd'"

    //------------------------------------------------------------------
    // 2. Mark sample and basic setup
    //------------------------------------------------------------------
    quietly {
        preserve
        marksample touse
        markout `touse'

        if _by() {
            qui replace `touse' = 0 if `_byindex' != _byindex()
        }

        global touse = `touse'
        noi di ""
        noi di in white "............................................................"
        noi di ""
        noi di in white "........ MIDAS-INLA: Meta-analysis of DTA studies ........"
        noi di ""
        noi di in white "............................................................"
        noi di ""

        tokenize `varlist'
        local tp `1'
        local fp `2'
        local fn `3'
        local tn `4'

        tempvar pid StudyIds
        local alph = (100-`level')/200

        // Study ID handling
        if "`id'" != "" {
            egen StudyIds = concat(`id'), p(" ")
        }
        else {
            tempvar _idgen
            gen `_idgen' = string(_n)
            egen StudyIds = concat(`_idgen'), p(" ")
        }

        // Link functions: logit is default
        if wordcount("`link'") > 1 {
            opts_exclusive "logit probit cloglog"
        }

        local model "Bivariate Generalized Linear Mixed Model"

        if "`link'" == "logit" | "`link'" == "l" | "`link'" == "" {
            local link "logit"
        }
        else if "`link'" == "probit" | "`link'" == "p" {
            local link "probit"
        }
        else if "`link'" == "cloglog" | "`link'" == "c" {
            local link "cloglog"
        }

        // Approximation, integration, covariance options
        if wordcount("`integration'") > 1 {
            opts_exclusive "ccd grid"
        }
        if wordcount("`approximation'") > 1 {
            opts_exclusive "laplace simple gaussian"
        }
        if wordcount("`covmatrix'") > 1 {
            opts_exclusive "iwishart cholesky sciwishart hiwishart spherical product siw huangwand prodnormal"
        }
        // Alias old names to new names for consistency with midas_mh
        if "`covmatrix'" == "siw"        local covmatrix "sciwishart"
        if "`covmatrix'" == "huangwand"  local covmatrix "hiwishart"
        if "`covmatrix'" == "prodnormal" local covmatrix "product"
        if !inlist("`covmatrix'", "", "iwishart", "cholesky", "sciwishart", "hiwishart", "spherical", "product") {
            di as error "covmatrix(`covmatrix') invalid -- must be one of: iwishart cholesky sciwishart hiwishart spherical product"
            di as error "  (aliases: siw=sciwishart, huangwand=hiwishart, prodnormal=product)"
            exit 198
        }

        if `level' < 10 | `level' > 99 {
            di as error "level() must be between 10 and 99"
            exit 198
        }

        if "`sortby'" != "" {
            gsort `sortby'
            local sortby "`sortby'"
        }

        // Export original data and create design matrix for weights
        tempname _matraw
        sort StudyIds
        cap drop _midas_id
        gen _midas_id = _n
        save "`workdir'/midas_input_data.dta", replace
        mkmat `tp' `fp' `fn' `tn', mat(`_matraw') rownames(StudyIds)
        matrix colnames `_matraw' = tp fp fn tn
        count if `touse'
        local numobs = r(N)
        local _midas_nobs = _N
    }

    //------------------------------------------------------------------
    // 3. Totals and prevalence
    //------------------------------------------------------------------
    tempvar sumtp sumfn sumtn sumfp prev
    egen `sumtp' = total(`tp') if `touse'
    egen `sumfn' = total(`fn') if `touse'
    egen `sumtn' = total(`tn') if `touse'
    egen `sumfp' = total(`fp') if `touse'
    quietly gen `prev' = (`tp' + `fn')/(`tp' + `tn' + `fn' + `fp') if `touse'
    quietly su `prev'
    local prev = r(mean)
    local prevmin = r(min)
    local prevmax = r(max)

    capture cd "`workdir'"

    //------------------------------------------------------------------
    // 4. Build R script and call INLA
    //------------------------------------------------------------------
    capture erase "`workdir'/midas.R"
    rinla_script , cov("`covmatrix'") ///
        app("`approximation'") integration("`integration'") ///
        nip(`nip') link("`link'") workdir("`workdir'")

    if "`showcode'" != "" {
        nois type "`workdir'/midas.R"
    }

    makeinladata `tp' `fp' `fn' `tn', workdir("`workdir'")
    tempname avg_N1 avg_N2
    scalar `avg_N1' = r(avgn1)
    scalar `avg_N2' = r(avgn2)

    if c(os) == "Windows" {
        local rpath_cmd = subinstr(`"`rpath'"', "/", "\\", .)
        local workdir_cmd = subinstr(`"`workdir'"', "/", "\\", .)
        local rscript_file "`workdir_cmd'\\midas.R"
        local rlog_file   "`workdir_cmd'\\midas_log.txt"
        // Detect Rscript vs R executable
        if regexm(lower("`rpath_cmd'"), "rscript") {
            // Rscript: run script directly
            shell "`rpath_cmd'" --no-restore --no-save "`rscript_file'" > "`rlog_file'" 2>&1
        }
        else {
            // R.exe: use CMD BATCH
            shell "`rpath_cmd'" CMD BATCH --no-restore --no-save "`rscript_file'" "`rlog_file'"
        }
    }
    else {
        if regexm(lower("`rpath'"), "rscript") {
            shell "`rpath'" --no-restore --no-save "`workdir'/midas.R" > "`workdir'/midas_log.txt" 2>&1
        }
        else {
            shell "`rpath'" CMD BATCH --no-restore --no-save "`workdir'/midas.R" "`workdir'/midas_log.txt"
        }
    }

    // Check if R produced output; if not, show log
    capture confirm file "`workdir'/midalik.csv"
    if _rc {
        nois di as error "R did not produce output. Check R log:"
        nois type "`workdir'/midas_log.txt"
        exit 601
    }

    nois di ""
    nois di ""

    //------------------------------------------------------------------
    // 5. Import R results
    //------------------------------------------------------------------
    import delimited "`workdir'/midalik.csv", clear
    local ll = like[1]
    local llg = like[2]

    inla_ppp, workdir("`workdir'")
    local dbar = r(dbar)
    local dhat = r(dhat)
    local pD = r(pD)
    local DIC = r(DIC)
    local WAIC = r(WAIC)
    local pDW = r(pDW)

    inla_fitted, workdir("`workdir'")
    tempname xb cpo pred modfit residuals
    mat `xb' = r(xb)
    mat `cpo' = r(cpo)
    mat `pred' = r(pred)
    mat `modfit' = r(modfit)
    mat `residuals'= r(residuals)
    local logscore = r(logscore)

    midas_sim_data, workdir("`workdir'")
    tempname midas_sim_data
    mat `midas_sim_data' = r(midas_sim_data)

    inla_reffects, workdir("`workdir'")
    tempname reffects
    mat `reffects' = r(reffects)

    inla_mat, workdir("`workdir'") nobs(`_midas_nobs') avgn1(`=`avg_N1'') avgn2(`=`avg_N2'')
    tempname V b Vsum bsum bsummed bsumsd
    tempname Vhsroc bhsroc VIsquared bIsquared
    tempname bhsrocmed bhsrocsd bIsqmed bIsqsd bmed bsd

    mat `V' = r(V)
    mat `b' = r(b)
    mat _Sigma = (`b'[1,3], `b'[1,5] \ `b'[1,5], `b'[1,4])
    local covmus = r(covmus)
    mat `Vsum' = r(Vsum)
    mat `bsum' = r(bsum)

    mat `Vhsroc' = r(Vhsroc)
    mat `bhsroc' = r(bhsroc)

    mat `VIsquared'= r(VIsq)
    mat `bIsquared'= r(bIsq)

    mat `bsummed' = r(bsummed)
    mat `bsumsd' = r(bsumsd)

    mat `bhsrocmed'= r(bhsrocmed)
    mat `bhsrocsd' = r(bhsrocsd)

    mat `bIsqmed' = r(bIsqmed)
    mat `bIsqsd' = r(bIsqsd)

    mat `bmed' = r(bmed)
    mat `bsd' = r(bsd)

    inla_weights, workdir("`workdir'") nobs(`_midas_nobs')
    tempname studywgts
    mat `studywgts' = r(studyweights)

    //------------------------------------------------------------------
    // 6. Post results into e()
    //------------------------------------------------------------------
    ereturn post `b' `V'
    restore
    tempvar tousecopy
    gen `tousecopy' = $touse
    cap drop _midas_touse
    gen byte _midas_touse = `tousecopy'
    ereturn repost, esample(`tousecopy')

    // matrices
    // store varlist (study labels matrix) for postestimation
    ereturn matrix varlist = `_matraw', copy
    foreach i in Vsum bsum Vhsroc bhsroc VIsquared bIsquared ///
    pred xb residuals reffects modfit cpo {
        ereturn matrix `i' = ``i'', copy
    }
    foreach i in bsummed bsumsd bhsrocmed bhsrocsd ///
    bIsqmed bIsqsd bmed bsd midas_sim_data {
        ereturn matrix `i' = ``i'', copy
    }
    ereturn matrix studywgts = `studywgts', copy

    // scalars
    ereturn scalar nstudies = `numobs'
    ereturn scalar ll = `ll'
    ereturn scalar llg = `llg'
    ereturn scalar dbar = `dbar'
    ereturn scalar dhat = `dhat'
    ereturn scalar pD = `pD'
    ereturn scalar DIC = `DIC'
    ereturn scalar pDW = `pDW'
    ereturn scalar WAIC = `WAIC'
    ereturn scalar logscore = `logscore'
    ereturn scalar k = 5
    ereturn scalar kf = 2
    ereturn scalar kr = 3
    ereturn scalar N = `numobs'

    quietly summarize `tp' if _midas_touse, meanonly
    local sumtp_scalar = r(sum)
    quietly summarize `fn' if _midas_touse, meanonly
    local sumfn_scalar = r(sum)
    local nndis = `sumtp_scalar' + `sumfn_scalar'
    ereturn scalar Ndis = `nndis'

    quietly summarize `tn' if _midas_touse, meanonly
    local sumtn_scalar = r(sum)
    quietly summarize `fp' if _midas_touse, meanonly
    local sumfp_scalar = r(sum)
    local nnodis = `sumtn_scalar' + `sumfp_scalar'
    ereturn scalar Nnodis = `nnodis'

    ereturn scalar covmus = `covmus'
    ereturn scalar prev = `prev'
    ereturn scalar prevmin = `prevmin'
    ereturn scalar prevmax = `prevmax'
    ereturn scalar level = `level'
    ereturn scalar avgNse = `avg_N1'
    ereturn scalar avgNsp = `avg_N2'

    ereturn local predict _no_predict
    if "`sortby'" != "" {
        ereturn local sortby `sortby'
    }

    //------------------------------------------------------------------
    // 7. Labels and meta-info for MIDAS postestimation
    //------------------------------------------------------------------
    if "`approximation'" == "" | "`approximation'" == "laplace" {
        ereturn scalar nip = `nip'
    }

    ereturn local title "Meta-analysis of Diagnostic Accuracy Studies"
    ereturn local estmethod "Integrated Nested Laplace Approximations"
    ereturn local model `"`model'"'

    if "`covmatrix'" == "cholesky" {
        ereturn local covprior "Cholesky Decomposition"
    }
    else if "`covmatrix'" == "iwishart" | "`covmatrix'" == "" {
        ereturn local covprior "Inverse Wishart Formulation"
    }
    else if "`covmatrix'" == "sciwishart" {
        ereturn local covprior "Scaled Inverse Wishart (O'Malley type)"
    }
    else if "`covmatrix'" == "hiwishart" {
        ereturn local covprior "Huang-Wand hierarchical prior"
    }
    else if "`covmatrix'" == "spherical" {
        ereturn local covprior "Spherical (Gaussian on angle phi, rho = cos(phi))"
    }
    else if "`covmatrix'" == "product" {
        ereturn local covprior "Product-normal (regression-type, lambda-controlled)"
    }

    if "`approximation'" == "" | "`approximation'" == "laplace" {
        ereturn local strategy "Full Laplace"
    }
    else if "`approximation'" == "simple" {
        ereturn local strategy "Simplified Laplace"
    }
    else if "`approximation'" == "gaussian" {
        ereturn local strategy "Gaussian"
    }

    if "`integration'" == "grid" | "`integration'" == "" {
        ereturn local int_strategy "GRID"
    }
    else if "`integration'" == "ccd" {
        ereturn local int_strategy "CCD"
    }

    ereturn local fam "Binomial"
    ereturn local link `link'

    ereturn local cmdline "midas_inla `0'"
    ereturn local package "midas"
    ereturn local Package "Midas"
    ereturn local cmd "midas_inla"

    capture erase "`workdir'/midalik.csv"
    capture erase "`workdir'/midadic.csv"
    capture erase "`workdir'/inlares.csv"
    capture erase "`workdir'/inlasim.csv"
    capture erase "`workdir'/reffects.csv"
    cap drop _midas_touse
    macro drop touse
}
else {
    if "`e(cmd)'" != "midas_inla" error 301
    if _by() error 190

    #delimit ;
    syntax [if] [in] ,
    [ Level(cilevel)
    noHEADer
    noCOEFficients
    noSUMmary
    noFITstats
    HETstats
    MODdiag
    HSROC
    REVman
    cc(real 0.5)
    MScale(real 0.80)
    TEXTScale(real 1.00)
    SCHEME(passthru)
    * ] ;
    #delimit cr
}

//----------------------------------------------------------------------
// 8. Replay / display section (shared)
//----------------------------------------------------------------------
local level = e(level)
nois di ""
nois di ""

if "`header'" == "" {
    nois di in smcl as text "{hline 76}"
    nois di as txt _n e(title) _n
    nois di in smcl as text "{hline 76}"
    nois di ""
    nois di as txt _n "Via " in yellow e(model) _n
    nois di as txt _n "Estimation Method: " in yellow e(estmethod) _n
    nois di as txt _n "Approximation Strategy: " in yellow e(strategy) _n
    nois di as txt _n "Integration Strategy: " in yellow e(int_strategy) _n
    nois di as txt _n "Family: " in yellow e(fam) _n
    nois di as txt _n "Link: " in yellow e(link) _n
    nois di as txt _n "Covariance Matrix Prior: " in yellow e(covprior) _n

    if !missing(e(nip)) {
        nois di as txt _n "Number of Integration Points: " in yellow e(nip) _n
    }

    nois di ""
    nois di as txt "Number of studies" _col(60) "= " ///
        _col(64) as res %5.0f e(N)
    nois di ""
    nois di as txt "Reference-positive Units" _col(60) "= " ///
        _col(64) as res %5.0f e(Ndis)
    nois di ""
    nois di as txt "Reference-negative Units" _col(60) "= " ///
        _col(64) as res %5.0f e(Nnodis)
    nois di ""
    nois di as txt "Pretest Prob of Disease" _col(60) "= " ///
        _col(64) as res %5.2f e(prev)
}

nois di ""
nois di ""
nois di ""

if "`fitstats'" == "" {
    nois di in smcl as text "{hline 76}"
    nois di ""
    nois di as text "Log marginal-likelihood (Integration)" _col(60) "= " ///
        _col(64) as res %5.2f e(ll)
    nois di ""
    nois di as text "Log marginal-likelihood (Gaussian)" _col(60) "= " ///
        _col(64) as res %5.2f e(llg)
    nois di ""
    nois di as text "Mean of the Deviance" _col(60) "= " ///
        _col(64) as res %5.2f e(dbar)
    nois di ""
    nois di as text "Deviance of the Mean" _col(60) "= " ///
        _col(64) as res %5.2f e(dhat)
    nois di ""
    nois di as text "Effective number of parameters (DIC)" _col(60) "= " ///
        _col(64) as res %5.0f e(pD)
    nois di ""
    nois di as text "Effective number of parameters (WAIC)" _col(60) "= " ///
        _col(64) as res %5.0f e(pDW)
    nois di ""
    nois di as text "Deviance Information Criterion" _col(60) "= " ///
        _col(64) as res %5.2f e(DIC)
    nois di ""
    nois di ""
    nois di as text "Watanabe-Akaike Information Criterion" _col(60) "= " ///
        _col(64) as res %5.2f e(WAIC)
    nois di ""
    nois di as text "Cross-validated Logarithmic Score" _col(60) "= " ///
        _col(64) as res %5.2f e(logscore)
    nois di ""
}

nois di ""
nois di ""
nois di ""

//----------------------------------------------------------------------
// 9. Coefficient and summary tables from simulation matrix
//----------------------------------------------------------------------
if "`coefficients'" == "" {
    preserve
    mat data = e(midas_sim_data)
    clear
    qui svmat data, names(col)
    nois di in smcl in gr _newline(1) "{hilite: Fixed and Random Effects Estimates:}"
    if "`hpd'" == "" {
        nois inla_sumstats logitsen logitspe varlogitsen varlogitspe covvars corrvars
    }
    else {
        nois inla_sumstats logitsen logitspe varlogitsen varlogitspe covvars corrvars, hpd
    }
    restore
}

if "`summary'" == "" {
    preserve
    mat data = e(midas_sim_data)
    clear
    qui svmat data, names(col)
    gen double sen = invlogit(logitsen)
    gen double spe = invlogit(logitspe)
    gen double lrp = sen/(1-spe)
    gen double lrn = (1-sen)/spe
    gen double ldor = logitsen + logitspe
    nois di in smcl in gr _newline(1) "{hilite: Summary Test Performance Estimates:}"
    if "`hpd'" == "" {
        nois inla_sumstats sen spe lrp lrn ldor
    }
    else {
        nois inla_sumstats sen spe lrp lrn ldor, hpd
    }
    restore
}

//----------------------------------------------------------------------
// 10. Heterogeneity statistics
//----------------------------------------------------------------------
if "`hetstats'" != "" {
    preserve
    mat data = e(midas_sim_data)
    clear
    qui svmat data, names(col)
    qui gen I2_Sen = .
    qui gen I2_Spe = .
    qui gen I2_Biv = .
    local _avN1 = e(avgNse)
    local _avN2 = e(avgNsp)
    local _Nhs = e(N)
    forvalues i = 1/`_Nhs' {
        mat Vblogit`i' = (varlogitsen[`i'], covvars[`i'] \ covvars[`i'], varlogitspe[`i'])
        qui replace I2_Sen = varlogitsen[`i']/(varlogitsen[`i'] + ///
        (`_avN1'*(exp((varlogitsen[`i']/2)+logitsen[`i']) + ///
        exp((varlogitsen[`i']/2)-logitsen[`i']) + 2))) in `i'
        qui replace I2_Spe = varlogitspe[`i']/(varlogitspe[`i'] + ///
        (`_avN2'*(exp((varlogitspe[`i']/2)+logitspe[`i']) + ///
        exp((varlogitspe[`i']/2)-logitspe[`i']) + 2))) in `i'
        qui replace I2_Biv = ///
        sqrt(exp(log(det(Vblogit`i'))))/( ///
        sqrt(exp(log(det(Vblogit`i')))) + ///
        sqrt((`_avN1'*(exp((varlogitsen[`i']/2)+logitsen[`i']) + ///
        exp((varlogitsen[`i']/2)-logitsen[`i']) + 2)) * ///
        (`_avN2'*(exp((varlogitspe[`i']/2)+logitspe[`i']) + ///
        exp((varlogitspe[`i']/2)-logitspe[`i']) + 2)))) in `i'
    }
    nois di in smcl in gr _newline(1) "{hilite: Heterogeneity/Inconsistency Statistics:}"
    if "`hpd'" == "" {
        nois inla_sumstats I2_Sen I2_Spe I2_Biv
    }
    else {
        nois inla_sumstats I2_Sen I2_Spe I2_Biv, hpd
    }
    restore
}

//----------------------------------------------------------------------
// 11. HSROC derived parameters
//----------------------------------------------------------------------
if "`hsroc'" != "" {
    preserve
    mat data = e(midas_sim_data)
    clear
    qui svmat data, names(col)
    gen double Alpha = (varlogitsen/varlogitspe)^(0.25)*logitspe + ///
    (varlogitspe/varlogitsen)^(0.25)*logitsen
    gen double Theta = 0.5*((varlogitsen/varlogitspe)^(0.25)*logitspe - ///
    (varlogitspe/varlogitsen)^(0.25)*logitsen)
    gen double beta = 0.5*log(varlogitsen/varlogitspe)
    gen double s2alpha= 2*(sqrt(varlogitspe*varlogitsen)+covvars)
    gen double s2theta= 0.5*(sqrt(varlogitspe*varlogitsen)-covvars)
    nois di in smcl in gr _newline(1) "{hilite: Derived HSROC Model Estimates:}"
    if "`hpd'" == "" {
        nois inla_sumstats Alpha Theta beta s2alpha s2theta
    }
    else {
        nois inla_sumstats Alpha Theta beta s2alpha s2theta, hpd
    }
    restore
}

//----------------------------------------------------------------------
// 12. RevMan export table
//----------------------------------------------------------------------
if "`revman'" != "" {
    tempname bcoef Vcoef coef2
    mat `bcoef' = e(b)
    mat `Vcoef' = e(V)
    local cov01 = `Vcoef'[1,2]
    qui _coef_table, bmatrix(`bcoef') vmatrix(`Vcoef')
    mat `coef2' = r(table)'
    local sp = `coef2'[2,1]
    local spse = `coef2'[2,2]
    local sn = `coef2'[1,1]
    local snse = `coef2'[1,2]
    local reffs1= `coef2'[3,1]
    local reffs2= `coef2'[4,1]
    local covlogit = `coef2'[5,1]
    local corrlogit = `coef2'[6,1]

    nois di in smcl as text "{hline 76}"
    nois di in smcl in gr _newline(1) "{hilite: Required Information for Export into RevMan}"
    nois di ""
    nois di in smcl in blue "{title: Parameters for SROC Curve}"
    nois di ""
    nois di as text "{hilite:E(logitse)}: Expected mean logit sensitivity" ///
        _col(66) " = " _col(70) as res %5.4f `sn'
    nois di ""
    nois di as text "{hilite:E(logitsp)}: Expected mean logit specificity" ///
        _col(66) " = " _col(70) as res %5.4f `sp'
    nois di ""
    nois di as text "{hilite:Var(logitse)}: Between-study variance of logit sensitivity" ///
        _col(66) " = " _col(70) as res %5.4f `reffs1'
    nois di ""
    nois di as text "{hilite:Var(logitsp)}: Between-study variance of logit specificity" ///
        _col(66) " = " _col(70) as res %5.4f `reffs2'
    nois di ""
    nois di as text "{hilite:Cov(logits)}: Between-study Covariance" ///
        _col(66) " = " _col(70) as res %5.4f `covlogit'
    nois di ""
    nois di as text "{hilite:Corr(logits)}: Between-study Correlation" ///
        _col(66) " = " _col(70) as res %5.4f `corrlogit'
    nois di ""
    nois di ""
    nois di in smcl in blue "{title: Parameters for Confidence and Prediction Regions:}"
    nois di ""
    nois di as text "{hilite:SE(E(logitse))}: SE of expected mean logit sensitivity" ///
        _col(66) " = " _col(70) as res %5.4f `snse'
    nois di ""
    nois di as text "{hilite:SE(E(logitsp))}: SE of expected mean logit specificity" ///
        _col(66) " = " _col(70) as res %5.4f `spse'
    nois di ""
    nois di as text "{hilite:Cov(Es)}: Covariance between mean logits" ///
        _col(66) " = " _col(70) as res %5.4f `cov01'
    nois di ""
    nois di as text "{hilite:Studies}: Number of Studies included in meta-analysis" ///
        _col(66) " = " _col(70) as res %2.0f e(N)
    nois di ""
}

nois di ""
nois di ""

//----------------------------------------------------------------------
// 13. Model diagnostics plot (Deviance residual vs leverage)
//----------------------------------------------------------------------
if "`moddiag'" != "" {
    preserve
    clear
    mat bb = e(modfit)
    qui svmat bb, names(col)

    foreach modlab in 0.5 1 1.5 2.0 2.5 3.0 3.5 4.0 {
        local modlabpts `"`modlabpts' `=`modlab'' 0 "`modlab'" "'
    }
    gen obs = _n
    replace dri = 5.0 if dri > 5.0
    replace dri = -5.0 if dri < -5.0

    #delimit ;
    twoway ///
    (scatter pdi dri) ///
    (scatter pdi dri if dri <2.0 & dri >-2.0, mlw(medthin) mfc(green) mlc(black) msize(*1.5) ms(O)) ///
    (scatter pdi dri if dri >2.0 | dri < -2.0, mlw(medthin) mfc(cranberry) mlc(black) msize(*1.5) ms(O)) ///
    (scatter pdi dri if dri >2.0 | dri < -2.0, msymbol(i) mlabposition(0) mlabel(obs) mlabsize(*.5) mlabcolor(black)) ///
    (function y = 1-x^2, range(-1 1)) ///
    (function y = 2-x^2, range(-1.4 1.4)) ///
    (function y = 3-x^2, range(-1.7 1.7)) ///
    (function y = 4-x^2, range(-2 2)) ///
    (scatteri `modlabpts' (7), msymbol(+) mcolor(black) mlabcolor(black) mlabsize(small)),
    legend(off)
    xtitle("Deviance Residual")
    ytitle("Leverage")
    xlabel(-5(1)5)
    ylab(none) yticks(none)
    xline(0, lcolor(black))
    plotregion(margin(zero));
    #delimit cr

    restore
}

end


/***********************************************************************
Helper programs: data export, matrices, study-weights, PPP, etc.
***********************************************************************/

capture program drop makeinladata
program define makeinladata, rclass
syntax varlist(min=4 max=4) [if] [in] , WORKdir(string)
tokenize `varlist'
local tp `1'
local fp `2'
local fn `3'
local tn `4'

quietly {
    cap preserve
    marksample touse
    markout `touse'

    tempvar diid dis P Y N inv_N
    tempname avg_N1 avg_N2

    gen `N'1 = int(`tp' + `fn') if `touse'
    gen `N'2 = int(`tn' + `fp') if `touse'
    gen `Y'1 = int(`tp') if `touse'
    gen `Y'2 = int(`tn') if `touse'

    gen `inv_N'1 = 1/`N'1 if `touse'
    su `inv_N'1, meanonly
    scalar `avg_N1' = r(mean)

    gen `inv_N'2 = 1/`N'2 if `touse'
    su `inv_N'2, meanonly
    scalar `avg_N2' = r(mean)

    drop `inv_N'1 `inv_N'2

    gen `diid' = _n
    reshape long `Y' `N', i(`diid') j(`dis')
    tab `dis', gen(P)
    export delimited `diid' `dis' P1 P2 `Y' `N' using "`workdir'/midas_inla.csv", replace

    return scalar avgn1 = `avg_N1'
    return scalar avgn2 = `avg_N2'
    cap restore
}
end


capture program drop inla_mat
program define inla_mat, rclass
syntax , WORKdir(string) [ NOBS(string) AVGN1(real 0) AVGN2(real 0) ]
local _nobs = int(real("`nobs'"))
if missing(`_nobs') | `_nobs'==0 local _nobs = 0
cap preserve
quietly import delimited "`workdir'/inlasim.csv", clear

tempname Vblogit
tempvar varlogitsen varlogitspe logitsen logitspe corrvars covvars
tempvar sen spe lrn lrp ldor I2sen I2spe I2
tempvar Alpha Theta beta s2alpha s2theta

gen `logitsen' = logitsen
gen `logitspe' = logitspe
gen `varlogitsen'= 1/exp(logtau1)
gen `varlogitspe'= 1/exp(logtau2)
gen `corrvars' = 2*invlogit(tcorr) - 1
gen `covvars' = sqrt(`varlogitsen')*sqrt(`varlogitspe')*`corrvars'

gen double `sen' = invlogit(`logitsen')
gen double `spe' = invlogit(`logitspe')
gen double `lrp' = `sen'/(1-`spe')
gen double `lrn' = (1-`sen')/`spe'
gen double `ldor'= `logitsen' + `logitspe'

gen double `Alpha' = (`varlogitsen'/`varlogitspe')^(0.25)*`logitspe' + ///
(`varlogitspe'/`varlogitsen')^(0.25)*`logitsen'
gen double `Theta' = 0.5*((`varlogitsen'/`varlogitspe')^(0.25)*`logitspe' - ///
(`varlogitspe'/`varlogitsen')^(0.25)*`logitsen')
gen double `beta' = 0.5*log(`varlogitsen'/`varlogitspe')
gen double `s2alpha'= 2*(sqrt(`varlogitspe'*`varlogitsen')+`covvars')
gen double `s2theta'= 0.5*(sqrt(`varlogitspe'*`varlogitsen')-`covvars')

qui gen `I2sen' = .
qui gen `I2spe' = .
qui gen `I2' = .

local _avN1 = `avgn1'
local _avN2 = `avgn2'
forvalues i = 1/`_nobs' {
    mat `Vblogit'`i' = (`varlogitsen'[`i'], `covvars'[`i'] \ `covvars'[`i'], `varlogitspe'[`i'])

    qui replace `I2sen' = `varlogitsen'[`i']/(`varlogitsen'[`i'] + ///
    (`_avN1'*(exp((`varlogitsen'[`i']/2)+`logitsen'[`i']) + ///
    exp((`varlogitsen'[`i']/2)-`logitsen'[`i']) + 2))) in `i'

    qui replace `I2spe' = `varlogitspe'[`i']/(`varlogitspe'[`i'] + ///
    (`_avN2'*(exp((`varlogitspe'[`i']/2)+`logitspe'[`i']) + ///
    exp((`varlogitspe'[`i']/2)-`logitspe'[`i']) + 2))) in `i'

    qui replace `I2' = ///
    sqrt(exp(log(det(`Vblogit'`i'))))/( ///
    sqrt(exp(log(det(`Vblogit'`i')))) + ///
    sqrt((`_avN1'*(exp((`varlogitsen'[`i']/2)+`logitsen'[`i']) + ///
    exp((`varlogitsen'[`i']/2)-`logitsen'[`i']) + 2)) * ///
    (`_avN2'*(exp((`varlogitspe'[`i']/2)+`logitspe'[`i']) + ///
    exp((`varlogitspe'[`i']/2)-`logitspe'[`i']) + 2)))) in `i'
}

qui corr `logitsen' `logitspe', cov
return scalar covmus = r(cov_12)

// ---- Summary block: compute means, medians, SEMs, cov matrices ----
// Uses native Stata summarize + corr instead of mata: hmc_mat()

// (a) Summary performance
local varlist "`sen' `spe' `lrp' `lrn' `ldor'"
local sumnames "Sens Spec LRP LRN LOR"
_inla_summarize `varlist'
mat means = r(_mean)
mat colnames means = `sumnames'
return matrix bsum = means, copy
mat medians = r(_median)
mat colnames medians = `sumnames'
return matrix bsummed = medians, copy
mat sems = r(_sem)
mat colnames sems = `sumnames'
return matrix bsumsd = sems, copy
mat covs = r(_cov)
mat colnames covs = `sumnames'
mat rownames covs = `sumnames'
return matrix Vsum = covs, copy

// (b) HSROC
local varlist "`Alpha' `Theta' `beta' `s2alpha' `s2theta'"
local hsrocnames "Alpha Theta beta s2alpha s2theta"
_inla_summarize `varlist'
mat means = r(_mean)
mat colnames means = `hsrocnames'
return matrix bhsroc = means, copy
mat medians = r(_median)
mat colnames medians = `hsrocnames'
return matrix bhsrocmed = medians, copy
mat sems = r(_sem)
mat colnames sems = `hsrocnames'
return matrix bhsrocsd = sems, copy
mat covs = r(_cov)
mat colnames covs = `hsrocnames'
mat rownames covs = `hsrocnames'
return matrix Vhsroc = covs, copy

// (c) I-squared
local varlist "`I2sen' `I2spe' `I2'"
local isqnames "I2sen I2spe I2biv"
_inla_summarize `varlist'
mat means = r(_mean)
mat colnames means = `isqnames'
return matrix bIsq = means, copy
mat medians = r(_median)
mat colnames medians = `isqnames'
return matrix bIsqmed = medians, copy
mat sems = r(_sem)
mat colnames sems = `isqnames'
return matrix bIsqsd = sems, copy
mat covs = r(_cov)
mat colnames covs = `isqnames'
mat rownames covs = `isqnames'
return matrix VIsq = covs, copy

// (d) Coefficient-level
local varlist "`logitsen' `logitspe' `varlogitsen' `varlogitspe' `covvars' `corrvars'"
local coefnames "logitsen logitspe varlogitsen varlogitspe covvars corrvars"
_inla_summarize `varlist'
mat means = r(_mean)
mat colnames means = `coefnames'
return matrix b = means, copy
mat medians = r(_median)
mat colnames medians = `coefnames'
return matrix bmed = medians, copy
mat sems = r(_sem)
mat colnames sems = `coefnames'
return matrix bsd = sems, copy
mat covs = r(_cov)
mat colnames covs = `coefnames'
mat rownames covs = `coefnames'
return matrix V = covs, copy

cap restore
end


/***********************************************************************
_inla_summarize: native Stata replacement for mata: hmc_mat().
Computes mean, median, SEM, and variance-covariance matrix for a varlist.
Returns r(_mean), r(_median), r(_sem), r(_cov).
***********************************************************************/
capture program drop _inla_summarize
program define _inla_summarize, rclass
syntax varlist

local k : word count `varlist'
tempname mn md se

// mean row vector
mat `mn' = J(1, `k', .)
// median row vector
mat `md' = J(1, `k', .)
// SEM row vector
mat `se' = J(1, `k', .)

local j = 0
foreach v of varlist `varlist' {
    local ++j
    qui summarize `v', detail
    mat `mn'[1, `j'] = r(mean)
    mat `md'[1, `j'] = r(p50)
    local n = r(N)
    local sd = r(sd)
    if `n' > 1 {
        mat `se'[1, `j'] = `sd' / sqrt(`n')
    }
    else {
        mat `se'[1, `j'] = .
    }
}

// covariance matrix
qui corr `varlist', cov
tempname C
mat `C' = r(C)

return matrix _mean = `mn'
return matrix _median = `md'
return matrix _sem = `se'
return matrix _cov = `C'

end


capture program drop midas_sim_data
program define midas_sim_data, rclass
syntax , WORKdir(string)
cap preserve
quietly import delimited "`workdir'/inlasim.csv", clear

tempvar varlogitsen varlogitspe logitsen logitspe corrvars covvars matid
gen `matid' = _n
gen `logitsen' = logitsen
gen `logitspe' = logitspe
gen `varlogitsen' = 1/exp(logtau1)
gen `varlogitspe' = 1/exp(logtau2)
gen `corrvars' = 2*invlogit(tcorr) - 1
gen `covvars' = sqrt(`varlogitsen')*sqrt(`varlogitspe')*`corrvars'

mkmat `logitsen' `logitspe' `varlogitsen' `varlogitspe' `covvars' `corrvars', ///
mat(midas_sim_data) rownames(`matid')
local datanames "logitsen logitspe varlogitsen varlogitspe covvars corrvars"
mat colnames midas_sim_data = `datanames'

return matrix midas_sim_data = midas_sim_data, copy
cap restore
end


capture program drop inla_weights
program define inla_weights, rclass sortpreserve
syntax , WORKdir(string) [ NOBS(string) ]
local _nobs = int(real("`nobs'"))
if missing(`_nobs') | `_nobs'==0 local _nobs = 0
cap preserve

tempvar varprop last disgroup
tempname varp B G V invV fish varb weight Z ZZ A X XT invn studywgts Vwgt invVwgt fishwgt varbwgt weightwgt

quietly import delimited diid dis P1 P2 Y N using "`workdir'/midas_inla.csv", clear
gen `disgroup'1 = P1
gen `disgroup'2 = P2

mkmat `disgroup'2 `disgroup'1, mat(`X')
gen `invn' = 1/N
mat `XT' = `X''
mkmat `invn', mat(`A')
mat `A' = diag(`A')
mat `Z' = I(2*`_nobs')
mat `ZZ' = I(`_nobs')

quietly import delimited "`workdir'/inlares.csv", clear
bysort id: gen `last' = _n == _N
gen `varprop' = fitmq*(1-fitmq)
mkmat `varprop', mat(`B')
mat `B' = diag(`B')
mat `G' = `ZZ'#_Sigma
mat `Vwgt' = (`Z'*`G'*`Z'') + (`A'*syminv(`B'))

mat `invVwgt' = invsym(`Vwgt')
mat `fishwgt' = `XT'*`invVwgt'*`X'
mat `varbwgt' = invsym(`fishwgt')

forvalues i = 1/`_nobs' {
    mat `Vwgt'`i' = `Vwgt'
    mat `Vwgt'`i'[(`i'*2)-1,(`i'*2)-1] = 1000000000
    mat `Vwgt'`i'[(`i'*2)-1,`i'*2] = 0
    mat `Vwgt'`i'[`i'*2,(`i'*2)-1] = 0
    mat `Vwgt'`i'[`i'*2,`i'*2] = 1000000000

    mat `invVwgt'`i' = invsym(`Vwgt'`i')
    mat `fishwgt'`i' = `XT'*`invVwgt'`i'*`X'
    mat `fishwgt'`i'_`i' = `fishwgt' - `fishwgt'`i'
    mat `weightwgt'`i' = `varbwgt'*`fishwgt'`i'_`i'*`varbwgt'

    mat pctwgt`i'sens = 100*(`weightwgt'`i'[1,1]/`varbwgt'[2,2])
    mat pctwgt`i'spec = 100*(`weightwgt'`i'[2,2]/`varbwgt'[1,1])
    scalar pctwgt`i' = 100*(trace(`weightwgt'`i')/trace(`varbwgt'))
}

tempvar senwgt spewgt bivwgt
qui keep if `last' == 1
qui gen `senwgt' = .
qui gen `spewgt' = .
qui gen `bivwgt' = .
forvalues i = 1/`_nobs' {
    qui replace `senwgt' = pctwgt`i'sens[1,1] in `i'
    qui replace `spewgt' = pctwgt`i'spec[1,1] in `i'
    qui replace `bivwgt' = pctwgt`i' in `i'
}

qui merge 1:1 _n using "`workdir'/midas_input_data.dta", nogen
mkmat `senwgt' `spewgt' `bivwgt' if `last' == 1, mat(`studywgts') rownames(StudyIds)
mat colnames `studywgts' = senwgt spewgt bivwgt

return matrix studyweights = `studywgts', copy
cap restore
end


capture program drop inla_ppp
program define inla_ppp, rclass
syntax , WORKdir(string)
cap preserve
quietly import delimited "`workdir'/midadic.csv", clear
return scalar dbar = dic[1]
return scalar dhat = dic[2]
return scalar pD = dic[3]
return scalar DIC = dic[4]
return scalar WAIC = dic[5]
return scalar pDW = dic[6]
cap restore
end


capture program drop inla_reffects
program define inla_reffects, rclass
syntax , WORKdir(string)
cap preserve
quietly import delimited "`workdir'/reffects.csv", clear

tempname reffects
gsort -p1 p2 id
keep id grp reffmn reffsd
rename reffmn randeff
rename reffsd serandeff
sort id
quietly reshape wide randeff serandeff, i(id) j(grp)
qui merge 1:1 _n using "`workdir'/midas_input_data.dta", nogen
mkmat randeff1 randeff2 serandeff1 serandeff2, mat(`reffects') rownames(StudyIds)
return matrix reffects = `reffects', copy
cap restore
end


capture program drop inla_fitted
program define inla_fitted, rclass
syntax , WORKdir(string)
cap preserve
quietly import delimited "`workdir'/inlares.csv", clear

tempname xb cpo pred modfit residuals
tempvar logcpo

gen `logcpo' = log(cpo)
su `logcpo', meanonly
return scalar logscore = -r(mean)
drop `logcpo'

gsort -p1 p2 id
cap confirm var pwi
if _rc gen double pwi = .
keep id grp fitlq fitmq fituq pit cpo lplq lpmq lpuq dici pdi pwi dhati dbari dri
sort id
quietly reshape wide fitlq fitmq fituq pit cpo lplq lpmq lpuq ///
dici pdi pwi dhati dbari dri, i(id) j(grp)

qui merge 1:1 _n using "`workdir'/midas_input_data.dta", nogen

mkmat fitlq1 fitmq1 fituq1 fitlq2 fitmq2 fituq2, mat(`xb') rownames(StudyIds)
mkmat pit1 cpo1 pit2 cpo2, mat(`cpo') rownames(StudyIds)

rename lpmq1 eta1
rename lpmq2 eta2
gen double pred1 = invlogit(eta1)
gen double pred2 = invlogit(eta2)
mkmat eta1 eta2 pred1 pred2, mat(`pred') rownames(StudyIds)

gen double dici = dici1 + dici2
gen double pdi = pdi1 + pdi2
gen double pwi = pwi1 + pwi2
gen double dhati= dhati1+ dhati2
gen double dbari= dbari1+ dbari2
gen double dri = dri1 + dri2

mkmat dici pdi pwi dhati dbari dri, mat(`modfit') rownames(StudyIds)
mkmat dri, mat(`residuals') rownames(StudyIds)

return matrix xb = `xb', copy
return matrix cpo = `cpo', copy
return matrix pred = `pred', copy
return matrix modfit = `modfit', copy
return matrix residuals= `residuals', copy

cap restore
end


/***********************************************************************
rinla_script: build midas.R directly with six covariance priors.
***********************************************************************/

capture program drop rinla_script
program define rinla_script
syntax [if] [in] , ///
[ COVmatrix(string) MANual APProximation(string) ///
INTegration(string) NIP(integer 20) LINK(string) ///
WORKdir(string) ]

if "`link'" == "" {
    local link "logit"
}
if "`workdir'" == "" {
    local workdir = subinstr(c(sysdir_personal), "\\", "/", .)
    while substr("`workdir'", length("`workdir'"), 1) == "/" & length("`workdir'") > 3 {
        local workdir = substr("`workdir'", 1, length("`workdir'")-1)
    }
}

tempname binla
file open `binla' using "`workdir'/midas.R", write replace text

file write `binla' "# ---- user-writable library setup ----" _n
file write `binla' "user_lib <- Sys.getenv('R_LIBS_USER')" _n
file write `binla' "if (nchar(user_lib) == 0) user_lib <- file.path(Sys.getenv('USERPROFILE'), 'R', 'win-library', paste0(R.version[['major']], '.', substr(R.version[['minor']], 1, 1)))" _n
file write `binla' "if (!dir.exists(user_lib)) dir.create(user_lib, recursive = TRUE)" _n
file write `binla' ".libPaths(c(user_lib, .libPaths()))" _n
file write `binla' "# ---- install missing CRAN dependencies ----" _n
file write `binla' "for (pkg in c('Matrix', 'mvtnorm')) {" _n
file write `binla' "  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg, lib = user_lib, repos = 'https://cloud.r-project.org')" _n
file write `binla' "}" _n
file write `binla' "# ---- install or reinstall INLA if missing/broken ----" _n
file write `binla' "inla_ok <- tryCatch({ loadNamespace('INLA'); TRUE }, error = function(e) FALSE)" _n
file write `binla' "if (!inla_ok) {" _n
file write `binla' "  cat('INLA not available or broken. Installing from INLA repo...\n')" _n
file write `binla' "  install.packages('INLA', lib = user_lib, repos = c(INLA = 'https://inla.r-inla-download.org/R/stable', CRAN = 'https://cloud.r-project.org'), dep = TRUE)" _n
file write `binla' "}" _n
file write `binla' "library(INLA)" _n
file write `binla' "suppressPackageStartupMessages(library(Matrix))" _n
file write `binla' "suppressPackageStartupMessages(library(mvtnorm))" _n
file write `binla' "quantiles <- c(0.025, 0.5, 0.975)" _n
file write `binla' "midas.dir <- '`workdir''" _n
file write `binla' "midas.data <- read.csv(paste0(midas.dir,'/midas_inla.csv'), header = TRUE)" _n
file write `binla' "colnames(midas.data) <- c('diid','dis','P1','P2','Y','N')" _n
file write `binla' "N2 <- nrow(midas.data)" _n
file write `binla' "nstudies <- length(unique(midas.data[['diid']]))" _n
file write `binla' "N <- midas.data[['N']]" _n
file write `binla' "midas.long <- midas.data[order(midas.data[['diid']], midas.data[['dis']]), ]" _n
file write `binla' "midas.long[['studyid']] <- midas.long[['diid']]" _n

if "`link'" == "logit" | "`link'" == "l" {
    file write `binla' "invlink <- function(x) exp(x)/(1+exp(x))" _n
}
else if "`link'" == "probit" | "`link'" == "p" {
    file write `binla' "invlink <- function(x) pnorm(x)" _n
}
else if "`link'" == "cloglog" | "`link'" == "c" {
    file write `binla' "invlink <- function(x) exp(-exp(-x))" _n
}

file write `binla' "midas.build.S <- function(theta) {" _n
file write `binla' " sigma1sq <- exp(theta[1])" _n
file write `binla' " sigma2sq <- exp(theta[2])" _n
file write `binla' " rho <- 2/(1+exp(-theta[3])) - 1" _n
file write `binla' " v <- matrix(c(1, rho, rho, 1), 2, 2)" _n
file write `binla' " s <- diag(sqrt(c(sigma1sq, sigma2sq)))" _n
file write `binla' " S <- s %*% v %*% s" _n
file write `binla' " return(list(S = S, sigma2 = c(sigma1sq, sigma2sq), rho = rho))" _n
file write `binla' "}" _n

// cholesky
file write `binla' "midas.chol <- function (cmd = c('graph','Q','mu','initial','log.norm.const','log.prior','quit'), theta = NULL) {" _n
file write `binla' " cmd <- match.arg(cmd)" _n
file write `binla' " build.S <- function(theta) { sigma1sq <- exp(theta[1]); sigma2sq <- exp(theta[2]); rho <- 2/(1+exp(-theta[3]))-1; v <- matrix(c(1,rho,rho,1),2,2); s <- diag(sqrt(c(sigma1sq,sigma2sq))); S <- s%*%v%*%s; return(list(S=S, sigma2=c(sigma1sq,sigma2sq), rho=rho)) }" _n
file write `binla' " graph <- function() Q()" _n
file write `binla' " Q <- function() { tmp <- build.S(theta); S.inv <- solve(tmpDOLLARS); D <- Matrix::Diagonal(n/2, x = rep(1, n/2)); return(INLA::inla.as.sparse(kronecker(D, S.inv))) }" _n
file write `binla' " mu <- function() numeric(0)" _n
file write `binla' " log.norm.const <- function() numeric(0)" _n
file write `binla' " log.prior <- function() { tmp <- build.S(theta); sigsq <- tmpDOLLARsigma2; sigma <- sqrt(sigsq); lam <- 1; lp_sig <- sum(dexp(sigma, rate = lam, log = TRUE) + log(sigma/2)); lp_rho <- log(2*exp(-theta[3])/(1+exp(-theta[3]))^2); val <- lp_sig + lp_rho; return(val) }" _n
file write `binla' " initial <- function() c(-0.5, -0.5, 0)" _n
file write `binla' " quit <- function() invisible()" _n
file write `binla' " if (is.null(theta)) theta <- initial()" _n
file write `binla' " val <- switch(cmd,'graph'=graph(),'Q'=Q(),'mu'=mu(),'initial'=initial(),'log.norm.const'=log.norm.const(),'log.prior'=log.prior(),'quit'=quit())" _n
file write `binla' " return(val)" _n
file write `binla' "}" _n

// siw
file write `binla' "midas.siw <- function (cmd = c('graph','Q','mu','initial','log.norm.const','log.prior','quit'), theta = NULL) {" _n
file write `binla' " cmd <- match.arg(cmd)" _n
file write `binla' " build.S <- function(theta) { sigma1sq <- exp(theta[1]); sigma2sq <- exp(theta[2]); rho <- 2/(1+exp(-theta[3]))-1; v <- matrix(c(1,rho,rho,1),2,2); s <- diag(sqrt(c(sigma1sq,sigma2sq))); S <- s%*%v%*%s; return(list(S=S, sigma2=c(sigma1sq,sigma2sq), rho=rho)) }" _n
file write `binla' " graph <- function() Q()" _n
file write `binla' " Q <- function() { tmp <- build.S(theta); S.inv <- solve(tmpDOLLARS); D <- Matrix::Diagonal(n/2, x = rep(1, n/2)); return(INLA::inla.as.sparse(kronecker(D, S.inv))) }" _n
file write `binla' " mu <- function() numeric(0); log.norm.const <- function() numeric(0)" _n
file write `binla' " log.prior <- function() { tmp <- build.S(theta); sigsq <- tmpDOLLARsigma2; sigma <- sqrt(sigsq); nu <- 3; A <- 1.5; lp_sig <- sum(dt(sigma/A, df = nu, log = TRUE) - log(A) + log(sigma/2)); eta <- 2; u <- (tmpDOLLARrho + 1)/2; lp_beta <- dbeta(u, eta, eta, log = TRUE) + log(1/2); lp_jac_theta <- log(2*exp(-theta[3])/(1+exp(-theta[3]))^2); return(lp_sig + lp_beta + lp_jac_theta) }" _n
file write `binla' " initial <- function() c(-0.5, -0.5, 0); quit <- function() invisible(); if (is.null(theta)) theta <- initial(); val <- switch(cmd,'graph'=graph(),'Q'=Q(),'mu'=mu(),'initial'=initial(),'log.norm.const'=log.norm.const(),'log.prior'=log.prior(),'quit'=quit()); return(val) }" _n

// huangwand
file write `binla' "midas.hwand <- function (cmd = c('graph','Q','mu','initial','log.norm.const','log.prior','quit'), theta = NULL) {" _n
file write `binla' " cmd <- match.arg(cmd)" _n
file write `binla' " build.S <- function(theta) { sigma1sq <- exp(theta[1]); sigma2sq <- exp(theta[2]); rho <- 2/(1+exp(-theta[3]))-1; v <- matrix(c(1,rho,rho,1),2,2); s <- diag(sqrt(c(sigma1sq,sigma2sq))); S <- s%*%v%*%s; return(list(S=S, sigma2=c(sigma1sq,sigma2sq), rho=rho)) }" _n
file write `binla' " graph <- function() Q()" _n
file write `binla' " Q <- function() { tmp <- build.S(theta); S.inv <- solve(tmpDOLLARS); D <- Matrix::Diagonal(n/2, x = rep(1, n/2)); return(INLA::inla.as.sparse(kronecker(D, S.inv))) }" _n
file write `binla' " mu <- function() numeric(0); log.norm.const <- function() numeric(0)" _n
file write `binla' " log.prior <- function() { tmp <- build.S(theta); sigsq <- tmpDOLLARsigma2; sigma <- sqrt(sigsq); nu <- 4; A <- 1; lp_sig <- sum(dt(sigma/A, df = nu, log = TRUE) - log(A) + log(sigma/2)); eta <- 2; u <- (tmpDOLLARrho + 1)/2; lp_beta <- dbeta(u, eta, eta, log = TRUE) + log(1/2); lp_jac_theta <- log(2*exp(-theta[3])/(1+exp(-theta[3]))^2); return(lp_sig + lp_beta + lp_jac_theta) }" _n
file write `binla' " initial <- function() c(-0.5, -0.5, 0); quit <- function() invisible(); if (is.null(theta)) theta <- initial(); val <- switch(cmd,'graph'=graph(),'Q'=Q(),'mu'=mu(),'initial'=initial(),'log.norm.const'=log.norm.const(),'log.prior'=log.prior(),'quit'=quit()); return(val) }" _n

// spherical
file write `binla' "midas.sph <- function (cmd = c('graph','Q','mu','initial','log.norm.const','log.prior','quit'), theta = NULL) {" _n
file write `binla' " cmd <- match.arg(cmd)" _n
file write `binla' " build.S.sph <- function(theta) { sigma1sq <- exp(theta[1]); sigma2sq <- exp(theta[2]); phi <- theta[3]; rho <- cos(phi); v <- matrix(c(1, rho, rho, 1), 2, 2); s <- diag(sqrt(c(sigma1sq, sigma2sq))); S <- s %*% v %*% s; return(list(S = S, sigma2 = c(sigma1sq, sigma2sq), rho = rho, phi = phi)) }" _n
file write `binla' " graph <- function() Q()" _n
file write `binla' " Q <- function() { tmp <- build.S.sph(theta); S.inv <- solve(tmpDOLLARS); D <- Matrix::Diagonal(n/2, x = rep(1, n/2)); return(INLA::inla.as.sparse(kronecker(D, S.inv))) }" _n
file write `binla' " mu <- function() numeric(0); log.norm.const <- function() numeric(0)" _n
file write `binla' " log.prior <- function() { tau_theta <- 2; return(sum(dnorm(theta, mean = 0, sd = tau_theta, log = TRUE))) }" _n
file write `binla' " initial <- function() c(-0.5, -0.5, 0.785); quit <- function() invisible(); if (is.null(theta)) theta <- initial(); val <- switch(cmd,'graph'=graph(),'Q'=Q(),'mu'=mu(),'initial'=initial(),'log.norm.const'=log.norm.const(),'log.prior'=log.prior(),'quit'=quit()); return(val) }" _n
file write `binla' "midas.pn <- function (cmd = c('graph','Q','mu','initial','log.norm.const','log.prior','quit'), theta = NULL) {" _n
file write `binla' " cmd <- match.arg(cmd)" _n
file write `binla' " build.S <- function(theta) { sigma1sq <- exp(theta[1]); sigma2sq <- exp(theta[2]); rho <- 2/(1+exp(-theta[3]))-1; v <- matrix(c(1,rho,rho,1),2,2); s <- diag(sqrt(c(sigma1sq,sigma2sq))); S <- s%*%v%*%s; return(list(S=S, sigma2=c(sigma1sq,sigma2sq), rho=rho)) }" _n
file write `binla' " graph <- function() Q()" _n
file write `binla' " Q <- function() { tmp <- build.S(theta); S.inv <- solve(tmpDOLLARS); D <- Matrix::Diagonal(n/2, x = rep(1, n/2)); return(INLA::inla.as.sparse(kronecker(D, S.inv))) }" _n
file write `binla' " mu <- function() numeric(0); log.norm.const <- function() numeric(0)" _n
file write `binla' " log.prior <- function() { tau_logsd <- 1.5; lambda <- 1.0; tau_rho <- 1/sqrt(lambda); lp_sd <- dnorm(theta[1], mean = 0, sd = tau_logsd, log = TRUE) + dnorm(theta[2], mean = 0, sd = tau_logsd, log = TRUE); lp_rho <- dnorm(theta[3], mean = 0, sd = tau_rho, log = TRUE); return(lp_sd + lp_rho) }" _n
file write `binla' " initial <- function() c(-0.5, -0.5, 0); quit <- function() invisible(); if (is.null(theta)) theta <- initial(); val <- switch(cmd,'graph'=graph(),'Q'=Q(),'mu'=mu(),'initial'=initial(),'log.norm.const'=log.norm.const(),'log.prior'=log.prior(),'quit'=quit()); return(val) }" _n

// linear combination for lincomb
file write `binla' "P1P2 <- INLA::inla.make.lincomb(P1=1, P2=1)" _n
file write `binla' "names(P1P2) <- 'P1P2'" _n

// model selection: covmatrix branches
file write `binla' "if ('`covmatrix'' == 'iwishart' || '`covmatrix'' == '') {" _n
file write `binla' "  formula <- Y ~ f(studyid, model='iid2d', n=2*nstudies, hyper=list(theta=list(prior='wishart2d', param=c(4,1,2,0.1)))) + P1 + P2 - 1" _n
file write `binla' "} else if ('`covmatrix'' == 'cholesky') {" _n
file write `binla' "  modelobj <- INLA::inla.rgeneric.define(midas.chol, n = 2*nstudies)" _n
file write `binla' "  formula <- Y ~ f(studyid, model=modelobj, n=2*nstudies) + P1 + P2 - 1" _n
file write `binla' "} else if ('`covmatrix'' == 'sciwishart') {" _n
file write `binla' "  modelobj <- INLA::inla.rgeneric.define(midas.siw, n = 2*nstudies)" _n
file write `binla' "  formula <- Y ~ f(studyid, model=modelobj, n=2*nstudies) + P1 + P2 - 1" _n
file write `binla' "} else if ('`covmatrix'' == 'hiwishart') {" _n
file write `binla' "  modelobj <- INLA::inla.rgeneric.define(midas.hwand, n = 2*nstudies)" _n
file write `binla' "  formula <- Y ~ f(studyid, model=modelobj, n=2*nstudies) + P1 + P2 - 1" _n
file write `binla' "} else if ('`covmatrix'' == 'spherical') {" _n
file write `binla' "  modelobj <- INLA::inla.rgeneric.define(midas.sph, n = 2*nstudies)" _n
file write `binla' "  formula <- Y ~ f(studyid, model=modelobj, n=2*nstudies) + P1 + P2 - 1" _n
file write `binla' "} else if ('`covmatrix'' == 'product') {" _n
file write `binla' "  modelobj <- INLA::inla.rgeneric.define(midas.pn, n = 2*nstudies)" _n
file write `binla' "  formula <- Y ~ f(studyid, model=modelobj, n=2*nstudies) + P1 + P2 - 1" _n
file write `binla' "}" _n

// inla call
file write `binla' "midas <- INLA::inla(formula, family='binomial', data=midas.long, control.family=list(link='`link''), Ntrials=N," _n

if "`approximation'" == "gaussian" {
    if "`integration'" == "" | "`integration'" == "grid" {
        file write `binla' " quantiles=quantiles, control.inla=list(numint.maxfeval=200000, strategy='gaussian', int.strategy='grid')," _n
    }
    else {
        file write `binla' " quantiles=quantiles, control.inla=list(numint.maxfeval=200000, strategy='gaussian', int.strategy='ccd')," _n
    }
}
else if "`approximation'" == "simple" {
    if "`integration'" == "" | "`integration'" == "grid" {
        file write `binla' " quantiles=quantiles, control.inla=list(numint.maxfeval=200000, strategy='simplified.laplace', int.strategy='grid')," _n
    }
    else {
        file write `binla' " quantiles=quantiles, control.inla=list(numint.maxfeval=200000, strategy='simplified.laplace', int.strategy='ccd')," _n
    }
}
else {
    if "`integration'" == "" | "`integration'" == "grid" {
        file write `binla' " quantiles=quantiles, control.inla=list(numint.maxfeval=200000, strategy='laplace', npoints=`nip', int.strategy='grid')," _n
    }
    else {
        file write `binla' " quantiles=quantiles, control.inla=list(numint.maxfeval=200000, strategy='laplace', npoints=`nip', int.strategy='ccd')," _n
    }
}

file write `binla' " control.compute=list(dic=TRUE, waic=TRUE, cpo=TRUE, mlik=TRUE), lincomb=P1P2" _n
if "`covmatrix'" != "iwishart" & "`covmatrix'" != "" {
    file write `binla' " , num.threads='1:1'" _n
}
file write `binla' ")" _n

// output section — uses DOLLAR placeholder (S3 list $ access for INLA >=24.x)
file write `binla' "hyper <- INLA::inla.hyperpar(midas)" _n
file write `binla' "dic <- matrix(NA, 6, 1); rownames(dic) <- c('dbar','dhat','pD','dic','waic','pDW')" _n
file write `binla' "dic[1,] <- midasDOLLARdicDOLLARmean.deviance; dic[2,] <- midasDOLLARdicDOLLARdeviance.mean; dic[3,] <- midasDOLLARdicDOLLARp.eff; dic[4,] <- midasDOLLARdicDOLLARdic; dic[5,] <- midasDOLLARwaicDOLLARwaic; dic[6,] <- midasDOLLARwaicDOLLARp.eff" _n
file write `binla' "midadic <- data.frame(dic); colnames(midadic) <- 'dic'" _n
file write `binla' "midalik <- data.frame(hyperDOLLARmlik); colnames(midalik) <- 'like'" _n
file write `binla' "obsyn <- data.frame(midas.long[, c('diid','dis','P1','P2','Y','N')]); colnames(obsyn) <- c('id','grp','P1','P2','Y','N')" _n
file write `binla' "sumfit <- data.frame(midasDOLLARsummary.fitted.values[, 3:5]); colnames(sumfit) <- c('fitlq','fitmq','fituq')" _n
file write `binla' "dici <- midasDOLLARdicDOLLARlocal.dic; pdi <- midasDOLLARdicDOLLARlocal.p.eff; pwi <- rep(as.numeric(midasDOLLARwaicDOLLARp.eff), N2); dhati <- dici - pdi; dbari <- dici - 2*pdi" _n
file write `binla' "mu <- numeric(N2); YY <- numeric(N2); YH <- numeric(N2); NN <- numeric(N2)" _n
file write `binla' "for (i in 1:N2) { if (midas.long[['dis']][i] == 1) { YY[i] <- max(midas.long[['Y']][i], 0.5); NN[i] <- max(midas.long[['N']][i], 1); mu[i] <- midasDOLLARsummary.fixed['P1','mean']; YH[i] <- NN[i]*invlink(mu[i]) } else { YY[i] <- max(midas.long[['Y']][i], 0.5); NN[i] <- max(midas.long[['N']][i], 1); mu[i] <- midasDOLLARsummary.fixed['P2','mean']; YH[i] <- NN[i]*invlink(mu[i]) } }" _n
file write `binla' "sgn <- ifelse((YH-YY) >= 0, 1, -1); dri <- sgn*sqrt(abs(dbari))" _n
file write `binla' "dres <- data.frame(cbind(dici,pdi,pwi,dhati,dbari,dri)); colnames(dres) <- c('dici','pdi','pwi','dhati','dbari','dri')" _n
file write `binla' "reffects <- data.frame(midasDOLLARsummary.randomDOLLARstudyid[1:N2,2:6]); colnames(reffects) <- c('reffmn','reffsd','refflb','reffmd','reffub')" _n
file write `binla' "linpred <- data.frame(midasDOLLARsummary.linear.predictor[,3:5]); colnames(linpred) <- c('lplq','lpmq','lpuq')" _n
file write `binla' "pit <- midasDOLLARcpoDOLLARpit; cpo <- midasDOLLARcpoDOLLARcpo; pred <- data.frame(cbind(pit,cpo))" _n
file write `binla' "inlares <- data.frame(cbind(obsyn,dres,pred,sumfit,linpred)); reffects <- data.frame(cbind(obsyn,reffects))" _n
file write `binla' "lgtse <- midasDOLLARmarginals.fixedDOLLARP1; logitsen <- round(INLA::inla.rmarginal(nstudies, lgtse), 4)" _n
file write `binla' "lgtsp <- midasDOLLARmarginals.fixedDOLLARP2; logitspe <- round(INLA::inla.rmarginal(nstudies, lgtsp), 4)" _n
file write `binla' "if ('`covmatrix'' == 'spherical') {" _n
file write `binla' " tau1 <- hyperDOLLARinternal.marginals.hyperpar[[1]]; logtau1 <- round(INLA::inla.rmarginal(nstudies, tau1), 4); tau2 <- hyperDOLLARinternal.marginals.hyperpar[[2]]; logtau2 <- round(INLA::inla.rmarginal(nstudies, tau2), 4); phi_marg <- hyperDOLLARinternal.marginals.hyperpar[[3]]; phi_draw <- INLA::inla.rmarginal(nstudies, phi_marg); rho_draw <- cos(phi_draw); tcorr <- round(stats::qlogis((rho_draw + 1)/2), 4)" _n
file write `binla' "} else if ('`covmatrix'' == 'product') {" _n
file write `binla' " theta1_marg <- hyperDOLLARinternal.marginals.hyperpar[[1]]; theta2_marg <- hyperDOLLARinternal.marginals.hyperpar[[2]]; lambda_marg <- hyperDOLLARinternal.marginals.hyperpar[[3]]; theta1_draw <- INLA::inla.rmarginal(nstudies, theta1_marg); theta2_draw <- INLA::inla.rmarginal(nstudies, theta2_marg); lambda_draw <- INLA::inla.rmarginal(nstudies, lambda_marg); sigma1 <- exp(theta1_draw); sigma2 <- exp(theta2_draw); var1 <- sigma1; var2 <- sigma2 + sigma1*lambda_draw^2; rho_draw <- lambda_draw*sqrt(sigma1)/sqrt(var2); logtau1 <- round(log(1/var1), 4); logtau2 <- round(log(1/var2), 4); tcorr <- round(stats::qlogis((rho_draw + 1)/2), 4)" _n
file write `binla' "} else {" _n
file write `binla' " tau1 <- hyperDOLLARinternal.marginals.hyperpar[[1]]; logtau1 <- round(INLA::inla.rmarginal(nstudies, tau1), 4); tau2 <- hyperDOLLARinternal.marginals.hyperpar[[2]]; logtau2 <- round(INLA::inla.rmarginal(nstudies, tau2), 4); rho_marg <- hyperDOLLARinternal.marginals.hyperpar[[3]]; tcorr <- round(INLA::inla.rmarginal(nstudies, rho_marg), 4)" _n
file write `binla' "}" _n
file write `binla' "inlasim <- data.frame(cbind(logitsen,logitspe,logtau1,logtau2,tcorr)); colnames(inlasim) <- c('logitsen','logitspe','logtau1','logtau2','tcorr')" _n
file write `binla' "inlasim <- data.frame(cbind(inlasim, data.frame(diid=sort(unique(midas.long[['diid']])), dis=rep(1, nstudies), P1=rep(1, nstudies), P2=rep(0, nstudies), Y=rep(NA, nstudies), N=rep(NA, nstudies))))" _n
file write `binla' "write.csv(midalik, paste0(midas.dir,'/midalik.csv'), row.names=FALSE)" _n
file write `binla' "write.csv(midadic, paste0(midas.dir,'/midadic.csv'), row.names=FALSE)" _n
file write `binla' "write.csv(reffects, paste0(midas.dir,'/reffects.csv'), row.names=FALSE)" _n
file write `binla' "write.csv(inlasim, paste0(midas.dir,'/inlasim.csv'), row.names=FALSE)" _n
file write `binla' "write.csv(inlares, paste0(midas.dir,'/inlares.csv'), row.names=FALSE)" _n

file close `binla'

// Replace DOLLAR placeholder with literal $ (avoids Stata macro expansion)
tempfile _tmpR
copy "`workdir'/midas.R" `_tmpR', replace
local dlr = char(36)
filefilter `_tmpR' "`workdir'/midas.R", from("DOLLAR") to("`dlr'") replace

end


program inla_sumstats , rclass byable(recall)
version 12.1
syntax varlist [if] [in] , [ ///
HPD ///
Level(cilevel) ///
CORrelations ///
COVariances ///
Save(string) ///
]

preserve
cap estimates store _midas_estimates
marksample touse, novarlist
qui keep if `touse'
if _N < 2 {
    di as err "Calculation requires at least two iterations"
    restore
    exit(0)
}
tempvar order
tempname mV C
cap tsset
local oldt = r(timevar)
gen `order' = _n
qui tsset `order'
if `"`save'"' != "" {
    tokenize `"`save'"' , parse(" ,")
    tempname pf
    postfile `pf' str20 parameter n mean sd sem median lb ub using `"`1'"', `3'
}
di in smcl as txt "{hline 13}{c TT}{hline 64}"
if "`hpd'" == "" {
    di in smcl in gr "Parameter {c |} mean sd" `" mcse median [`=strsubdp("`level'")'% Cred. Interval]"'
}
else {
    di in smcl in gr "Parameter {c |} mean sd" `" mcse median [`=strsubdp("`level'")'% HPD]"'
}
di in smcl as txt "{hline 13}{c +}{hline 64}"
local lcentile = (100-`level')/2
local ucentile = 100-`lcentile'
local i = 0
foreach v of varlist `varlist' {
    qui summ `v'
    local mn = r(mean)
    local sd = r(sd)
    local n = r(N)
    qui centile `v'
    local md = r(c_1)
    local lb "."
    local ub "."
    if "`hpd'" == "" & `n' > 5 {
        qui centile `v' , centile(`lcentile')
        local lb = r(c_1)
        qui centile `v' , centile(`ucentile')
        local ub = r(c_1)
    }
    else if `n' > 5 {
        inla_sumstats_hpd `v' , alpha(`level')
        local lb = r(low)
        local ub = r(high)
    }
    qui cap prais `v'
    if _rc == 0 {
        matrix `mV' = e(V)
        local se = sqrt(`mV'[1 , 1])
    }
    else local se "."
    di in smcl in gr %-12s "`v'" " {c |}" in ye %9.2f `mn' " " %9.2f `sd' %9.2f `se' " " %9.2f `md' " " %9.2f `lb' " " %9.2f `ub'
    local i = `i' + 1
    return local par`i' "`v'"
    return scalar n`i' = `n'
    return scalar mn`i' = `mn'
    return scalar sd`i' = `sd'
    return scalar se`i' = `se'
    return scalar md`i' = `md'
    return scalar lb`i' = `lb'
    return scalar ub`i' = `ub'
    if "`save'" != "" {
        post `pf' ("`v'") (`n') (`mn') (`sd') (`se') (`md') (`lb') (`ub')
    }
}
di in smcl as txt "{hline 13}{c BT}{hline 64}"

if "`covariances'" != "" {
    di as txt _newline "Covariances"
    corr `varlist' `if' `in', cov
    matrix `C' = r(C)
    return matrix V = `C'
}
if "`correlations'" != "" {
    di as txt _newline "Correlations"
    corr `varlist' `if' `in'
    matrix `C' = r(C)
    return matrix C = `C'
}
if "`save'" != "" {
    postclose `pf'
}
cap tsset `oldt'
restore
cap estimates restore _midas_estimates
end

program inla_sumstats_hpd , rclass
syntax varlist (max = 1 min = 1) [if] [in] [ , alpha(real 95.0) ]
version 12.1

quietly {
    marksample touse
    local theta = "`varlist'"
    local a = 100 - `alpha'
    local a1 = `a' / 2
    centile `theta' , centile(`a1' 50 )
    local theta1 = r(c_1)
    local thetam = r(c_2)
    preserve
    tempvar x f cf tmp
    local n = 1000
    if `n' > _N {
        set obs `n'
    }
    kdensity `theta' , gen(`x' `f') nograph n(`n')
    gen `cf' = sum(`f')
    su `cf'
    replace `cf' = `cf' / r(max)
    su `x'
    local step = (r(max)-r(min)) / 100
    local xthreshold = 0.001*`step'
    local athreshold = 0.0001
    if `step' <= 1e-7 {
        local xlow "."
        local xhigh "."
        local a1 "."
        local a2 "."
    }
    else {
        local xlow = `theta1'
        gen `tmp' = .
        local done = 0
        while `done' == 0 & `step' > `xthreshold' {
            inla_sumstats_interp `x' `cf' , value(`xlow')
            local a1 = r(fvalue)
            inla_sumstats_interp `x' `f' if `x' < `thetam' , value(`xlow')
            local fx = r(fvalue)
            inla_sumstats_interp `f' `x' if `x' > `thetam' , value(`fx') down
            local xhigh = r(fvalue)
            inla_sumstats_interp `x' `cf' , value(`xhigh')
            local a2 = 1 - r(fvalue)
            local asum = (`a1' + `a2') * 100
            if abs(`asum'-`a') < `athreshold' {
                local done = 1
            }
            else if `asum' > `a' {
                local xlow = `xlow' - `step'
            }
            else {
                local xlow = `xlow' + `step'
            }
            local step = `step' * 0.9
        }
        if `xhigh' == . {
            local xlow "."
            local a1 "."
            local a2 "."
        }
    }
    restore
    return scalar low = `xlow'
    return scalar high = `xhigh'
    return scalar larea = `a1' * 100
    return scalar rarea = `a2' * 100
}
end

program inla_sumstats_interp , rclass
syntax varlist (min = 2 max = 2) [if] , value(real) [ down ]
version 12.1
marksample touse
tokenize "`varlist'"

local x = "`1'"
local f = "`2'"
tempvar p
gen `p' = _n
if "`down'" == "" {
    su `p' if `x' < `value' & `touse'
}
else {
    su `p' if `x' > `value' & `touse'
}
local p1 = r(max)
local x1 = `x'[`p1']
local f1 = `f'[`p1']
local p1 = `p1' + 1
local x2 = `x'[`p1']
local f2 = `f'[`p1']
return scalar fvalue = `f1' + (`value'-`x1') * (`f2'-`f1') / (`x2'-`x1')
end
