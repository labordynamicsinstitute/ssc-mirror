*! version 2.0.1 09mar2026
*! midas_hmc - Bayesian Diagnostic Meta-Analysis via Hamiltonian Monte Carlo
*! Ben A. Dwamena, University of Michigan
*! Enhanced with stanrun v2.0 for improved performance and features

cap program drop midas_hmc
program define midas_hmc, eclass sortpreserve byable(recall)
version 17.0

if _by() {
    local BY `"by `_byvars'`_byrc0':"'
}

if !replay() {

    #delimit ;
    syntax varlist(min=4 max=4) [if] [in] ,
        ID(varlist min=1 max=2)
        COVariance(string asis) MODELfile(string) [
        MUPrior(string asis)
        SIGMAPrior(string asis)
        PHIPrior(string asis)
        RHOPrior(string asis)
        LAMDAPrior(string asis)
        OUTPUTfile(string)
        STANDir(string)
        HPD Level(cilevel)
        SEED(integer -1)
        CHAINS(integer 4)
        WARMup(integer -1)
        ITER(integer -1)
        THIN(integer -1)
        THREADS(integer -1)
        THREADSperchain(integer -1)
        ADAPTdelta(real -1)
        MAXtreedepth(integer -1)
        VARiational
        VIalgorithm(string)
        SORTby(varlist min=1)
        SHOWcode
        LOG
        noCOEFficients
        noSUMmary
        noHEADer
        noFITstats
        CONVERGEstats
        HETstats
        HSROC
        REVman * ] ;
    #delimit cr

    nois di ""
    nois di in white "............................................................"
    nois di ""
    nois di in white "........ MIDAS-HMC: Meta-analysis of DTA studies ........"
    nois di ""
    nois di in white "............................................................"
    nois di ""

    // Validate input data
    tokenize `varlist'
    local tp `1'
    local fp `2'
    local fn `3'
    local tn `4'

    quietly {
        marksample touse
        if _by() {
            replace `touse' = 0 if `_byindex' != _byindex()
        }

        // Check for negative values
        count if (`tp' < 0 | `fp' < 0 | `fn' < 0 | `tn' < 0) & `touse'
        if r(N) > 0 {
            noi di as error "Error: Negative cell counts detected"
            exit 198
        }

        // Check for non-integers
        count if (mod(`tp',1)!=0 | mod(`fp',1)!=0 | mod(`fn',1)!=0 | mod(`tn',1)!=0) & `touse'
        if r(N) > 0 {
            noi di as error "Error: Non-integer cell counts detected"
            exit 198
        }

        // Check for studies with zero diseased or zero non-diseased
        count if ((`tp'+`fn')==0 | (`fp'+`tn')==0) & `touse'
        if r(N) > 0 {
            noi di as error "Error: Some studies have zero diseased or zero non-diseased patients"
            noi di as error "These studies cannot provide valid diagnostic accuracy estimates"
            exit 198
        }
    }

    // Check stanrun installation
    capture which stanrun
    if _rc {
        di as error "stanrun command not found. Please install stanrun v2.0+"
        di as error "Required files: stanrun.ado, stanrun.sthlp"
        di as error "CmdStan download: https://mc-stan.org/cmdstan/"
        exit 199
    }

    // Validate covariance option
    local valid_cov "iwishart hiwishart sciwishart cholesky spherical cholefisher product"
    if `:list covariance in valid_cov' == 0 {
        di as error "Invalid covariance specification: `covariance'"
        di as error "Valid options are: `valid_cov'"
        exit 198
    }

    // default priors
    if "`muprior'" == "" {
        local muprior "normal(0,100)"
    }
    if "`sigmaprior'" == "" {
        local sigmaprior "cauchy(0,2.5)"
    }
    if "`phiprior'" == "" {
        local phiprior "uniform(0.5*3.14,3.14)"
    }
    if "`lamdaprior'" == "" {
        local lamdaprior "normal(0,100)"
    }
    if "`rhoprior'" == "" {
        local rhoprior "uniform(-1, 0)"
    }

    qui {
        local alph = (100-`level')/200
        local model "Bivariate Binomial Logit-Normal Random Intercepts Model"

        if ~missing("`log'") {
            local detail "noisily"
        }

        if wordcount("`covariance'") > 1 {
            opts_exclusive "iwishart hiwishart sciwishart cholesky spherical cholefisher product"
        }

        if `level' < 10 | `level' > 99 {
            di as error "level() must be between 10 and 99"
            exit 198
        }

        global touse = `touse'

        preserve
        tempvar sum sumtp sumfn sumtn sumfp prev

        egen `sumtp' = total(`tp') if `touse'
        egen `sumfn' = total(`fn') if `touse'
        egen `sumtn' = total(`tn') if `touse'
        egen `sumfp' = total(`fp') if `touse'

        global sumtpfn = `sumtp' + `sumfn'
        global sumtnfp = `sumtn' + `sumfp'

        gen `prev' = (`tp' + `fn')/(`tp' + `tn' + `fn' + `fp') if `touse'
        sum `prev'
        local prev = r(mean)
        local prevmin = r(min)
        local prevmax = r(max)

        qui gen long midas_denom1 = `1' + `3' if `touse'
        qui gen long midas_denom2 = `2' + `4' if `touse'
        qui gen long midas_dep1 = `1' if `touse'
        qui gen long midas_dep2 = `4' if `touse'

        egen midas_studylabel = concat(`id') if `touse', p(" ")

        qui sort midas_studylabel
        qui gen midas_studyid = _n

        tempname varlistmat
        mkmat `1' `2' `3' `4' if `touse', mat(`varlistmat') rownames(midas_studylabel)
        matrix colnames `varlistmat' = tp fp fn tn
        local varlist `varlistmat'
        count if `touse'
        global midas_nobs = r(N)

        ereturn scalar nstudies = $midas_nobs

        qui keep midas_denom* midas_dep* midas_studyid midas_studylabel `touse'
        qui keep if `touse'

        // Save working dataset for later merges
        qui save "midas_input_data.dta", replace

        qui gen double midas_invnum1 = 1/midas_denom1
        sum midas_invnum1, meanonly
        global avnum1 = r(mean)

        qui gen double midas_invnum2 = 1/midas_denom2
        sum midas_invnum2, meanonly
        global avnum2 = r(mean)

        // build Stan model
        midasstan_model, cov(`covariance') model(`modelfile') ///
            mup(`muprior') sigmap(`sigmaprior') phip(`phiprior') ///
            rhop(`rhoprior') lamdap(`lamdaprior')

        if !missing("`showcode'") {
            nois type "`modelfile'"
        }

        // Build stanrun options
        tempfile _midas_tmpcsv
        local stanrun_opts "modelfile(`modelfile')"
        if "`outputfile'" != "" {
            local stanrun_opts "`stanrun_opts' outputfile(`outputfile')"
        }
        local stanrun_opts "`stanrun_opts' globals(midas_nobs)"
        local stanrun_opts "`stanrun_opts' load diagnose nopywarn"

        if "`standir'" != "" {
            local stanrun_opts "`stanrun_opts' cmdstandir(`standir')"
        }

        if "`variational'" == "" {
            // MCMC mode
            local stanrun_opts "`stanrun_opts' chains(`chains')"
            if `warmup' > 0 {
                local stanrun_opts "`stanrun_opts' warmup(`warmup')"
            }
            if `iter' > 0 {
                local stanrun_opts "`stanrun_opts' iter(`iter')"
            }
            if `thin' > 0 {
                local stanrun_opts "`stanrun_opts' thin(`thin')"
            }
            if `threads' > 0 {
                local stanrun_opts "`stanrun_opts' threads(`threads')"
            }
            if `threadsperchain' > 0 {
                local stanrun_opts "`stanrun_opts' threadsperchain(`threadsperchain')"
            }
            if `adaptdelta' > 0 {
                if `adaptdelta' > 1 {
                    noi di as error "adaptdelta must be between 0 and 1"
                    exit 198
                }
                local stanrun_opts "`stanrun_opts' adaptdelta(`adaptdelta')"
            }
            if `maxtreedepth' > 0 {
                local stanrun_opts "`stanrun_opts' maxtreedepth(`maxtreedepth')"
            }
        }
        else {
            // Variational Inference mode
            local stanrun_opts "`stanrun_opts' variational"
            if "`vialgorithm'" != "" {
                if !inlist("`vialgorithm'", "meanfield", "fullrank") {
                    noi di as error "vialgorithm must be 'meanfield' or 'fullrank'"
                    exit 198
                }
                local stanrun_opts "`stanrun_opts' vialgorithm(`vialgorithm')"
            }
        }

        if `seed' >= 0 {
            local stanrun_opts "`stanrun_opts' seed(`seed')"
        }

        // Display configuration
        noi di ""
        noi di as result "Running Bayesian meta-analysis via stanrun v2.0"
        if "`variational'" == "" {
            noi di as text "Method: MCMC with HMC/NUTS"
            noi di as text "Chains: `chains'"
            if `warmup' > 0 noi di as text "Warmup: `warmup'"
            if `iter' > 0 noi di as text "Iterations: `iter'"
        }
        else {
            noi di as text "Method: Variational Inference (ADVI)"
        }
        noi di as text "Covariance prior: `covariance'"
        noi di ""

        // Call stanrun (must be noisily for shell commands to work)
        noi stanrun midas_dep1 midas_dep2 midas_denom1 midas_denom2, `stanrun_opts'

        // Check if stanrun completed successfully
        capture confirm variable mul1
        if _rc {
            noi di as error "stanrun fitting failed. Check model specification and data."
            noi di as error "Try running with the log option for detailed output."
            exit 198
        }

        // Process stanrun output
        gen double logitsen = mul1
        gen double logitspe = mul2
        gen double varlogitsen = sigma11
        gen double varlogitspe = sigma22
        gen double covvars = sigma12
        gen double corrvars = rho
        gen long chainvar = chain

        local _midas_outfile "`c(tmpdir)'/midas_output_data.dta"
qui save "`_midas_outfile'", replace

        tempvar matid
        gen int `matid' = _n

        mkmat loglik*, mat(loglike) rownames(`matid')
        mkmat p1* p2* phat1* phat2*, mat(stan_pred) rownames(`matid')
        mkmat chainvar mul1 mul2 sigma11 sigma22 sigma12 rho, ///
            mat(midas_sim_data) rownames(`matid')

        local datanames "chainvar logitsen logitspe varlogitsen varlogitspe covvars corrvars"
        mat colnames midas_sim_data = `datanames'

        tempname midas_sim_data loglike stan_pred
        mat `stan_pred' = stan_pred
        mat `loglike' = loglike
        mat `midas_sim_data' = midas_sim_data

        // study-level fits
        midas_stan_fitted
        tempname modfit residuals reffects
        mat `modfit' = r(midasmh_fit)
        mat `residuals' = r(residuals)
        mat `reffects' = r(reffects)
        local logscore = r(logscore)

        // summarize stanrun output
        midas_stan_mat
        tempname V b Vsum bsum bsummed bsumsd bhessmed bhesssd
        tempname Vhsroc bhsroc Vhess bhess VIsquared bIsquared
        tempname bhsrocmed bhsrocsd bIsqmed bIsqsd bmed bsd

        mat `V' = r(V)
        mat `b' = r(b)
        mat Sigma = (`b'[1,3], `b'[1,5] \ `b'[1,5], `b'[1,4])
        local covmuls = r(covmuls)
        mat `Vsum' = r(Vsum)
        mat `bsum' = r(bsum)
        mat `Vhsroc' = r(Vhsroc)
        mat `bhsroc' = r(bhsroc)
        mat `VIsquared' = r(VIsq)
        mat `bIsquared' = r(bIsq)
        mat `bhess' = r(bhess)
        mat `Vhess' = r(Vhess)
        mat `bsummed' = r(bsummed)
        mat `bsumsd' = r(bsumsd)
        mat `bhsrocmed' = r(bhsrocmed)
        mat `bhsrocsd' = r(bhsrocsd)
        mat `bIsqmed' = r(bIsqmed)
        mat `bIsqsd' = r(bIsqsd)
        mat `bhessmed' = r(bhessmed)
        mat `bhesssd' = r(bhesssd)
        mat `bmed' = r(bmed)
        mat `bsd' = r(bsd)

        // percentage weights and predicted matrices
        stan_weights
        tempname studywgts pred
        mat `studywgts' = r(stan_weights)
        mat `pred' = r(pred)

        // fit statistics
        stan_prp
        local loglll = r(loglll)
        local dbar = r(dbar)
        local dhat = r(dhat)
        local pD = r(pd)
        local DIC = r(dic)
        local pDW = r(pwaic)
        local WAIC = r(waic)

        // convergence statistics (only for MCMC)
        if "`variational'" == "" {
            stan_converge
            tempname converge
            mat `converge' = r(converge)
            local maxgrubin = r(rmax)
        }
        else {
            local maxgrubin = .
            tempname converge
            mat `converge' = J(1,5,.)
        }

        // post results
        eret post `b' `V'
        restore

        tempvar tousecopy
        gen `tousecopy' = $touse
        ereturn repost, esample(`tousecopy')

        foreach i in varlist Vsum bsum Vhsroc bhsroc VIsquared bIsquared ///
                     converge loglike pred midas_sim_data {
            ereturn matrix `i' = ``i'', copy
        }

        foreach i in bhess Vhess bsummed bsumsd bhsrocmed bhsrocsd ///
                     bIsqmed bIsqsd bhessmed bhesssd bmed bsd {
            ereturn matrix `i' = ``i'', copy
        }

        foreach i in modfit residuals reffects studywgts {
            ereturn matrix `i' = ``i'', copy
        }

        ereturn scalar k = 5
        ereturn scalar kf = 2
        ereturn scalar kr = 3
        ereturn scalar N = $midas_nobs
        ereturn scalar dis = $sumtpfn
        ereturn scalar nodis = $sumtnfp
        ereturn scalar prev = `prev'
        ereturn scalar prevmin = `prevmin'
        ereturn scalar prevmax = `prevmax'
        ereturn scalar level = `level'
        ereturn scalar avgNse = $avnum1
        ereturn scalar avgNsp = $avnum2
        ereturn scalar chains = `chains'
        ereturn scalar mcsize = `iter'
        ereturn scalar burnin = `warmup'
        ereturn scalar mgrubin = `maxgrubin'
        ereturn scalar covmuls = `covmuls'
        eret scalar loglll = `loglll'
        ereturn scalar dbar = `dbar'
        ereturn scalar dhat = `dhat'
        ereturn scalar pD = `pD'
        ereturn scalar DIC = `DIC'
        ereturn scalar pwaic = `pDW'
        ereturn scalar WAIC = `WAIC'
        ereturn scalar logscore = `logscore'
        ereturn local predict _no_predict
        eret local filename "`_midas_outfile'"

        if "`variational'" != "" {
            ereturn local method "Variational Inference (ADVI)"
            if "`vialgorithm'" != "" {
                ereturn local vialgorithm "`vialgorithm'"
            }
            else {
                ereturn local vialgorithm "meanfield"
            }
        }
        else {
            ereturn local method "MCMC (HMC/NUTS)"
        }

        if ~missing("`sortby'") {
            eret local sortby `sortby'
        }

        ereturn local title "Meta-analysis of Diagnostic Test Accuracy Data"
        ereturn local estmethod "Hamiltonian Monte Carlo and No U-Turn Sampling"
        ereturn local model `model'

        if "`covariance'" == "iwishart" {
            ereturn local covprior "Inverse Wishart Formulation"
        }
        else if "`covariance'" == "sciwishart" {
            ereturn local covprior "Scaled Inverse Wishart Formulation"
        }
        else if "`covariance'" == "hiwishart" {
            ereturn local covprior "Hierarchical Inverse Wishart Formulation"
        }
        else if "`covariance'" == "cholesky" {
            ereturn local covprior "Cholesky Decomposition"
        }
        else if "`covariance'" == "spherical" {
            ereturn local covprior "Spherical Decomposition"
        }
        else if "`covariance'" == "cholefisher" {
            ereturn local covprior "Cholesky Decomposition/Fisher Z Transformation"
        }
        else if "`covariance'" == "product" {
            ereturn local covprior "Product-Normal Formulation"
        }

        ereturn local fam "Binomial"
        ereturn local link "Logit"
        ereturn local cmdline "midas_hmc `0'"
        ereturn local package "midas"
        ereturn local cmd "midas_hmc"

        // Clean up temp files
        // convergestats cleanup handled by tempfile
        capture erase "stanrun_chains.csv"
        capture erase "stanrun_data.R"
        capture erase "midas_input_data.dta"
    }

    // Display results after estimation (invoke replay logic)
    midas_hmc, level(`level') `header' `coefficients' `summary' ///
        `fitstats' `hetstats' `hsroc' `convergestats' `revman'
}
else {
    // ================================================================
    // Replay
    // ================================================================
    if "`e(cmd)'" != "midas_hmc" error 301
    if _by() error 190

    #delimit ;
    syntax [if] [in] ,
        [ Level(cilevel)
        noHEADer
        noCOEFficients
        noSUMmary
        noFITstats
        HETstats
        HSROC
        CONVERGEstats
        REVman
        MODdiag
        * ] ;
    #delimit cr

    local level = cond(missing(`level'), e(level), `level')

    if missing("`header'") {
        di ""
        di in smcl as text "{hline 76}"
        di as txt _n e(title) _n
        di in smcl as text "{hline 76}"
        di ""
        di as txt "Model: " " " in yellow e(model)
        di as txt "Estimation: " " " in yellow e(estmethod)
        di as txt "Method: " " " in yellow e(method)
        di as txt "Family: " " " in yellow e(fam)
        di as txt "Link: " " " in yellow e(link)
        di as txt "Covariance prior: " " " in yellow e(covprior)
        di ""
        di as txt "Number of studies" _col(60) "= " ///
            _col(64) as result %5.0f e(N)
        di as txt "Reference-positive units" _col(60) "= " ///
            _col(64) as result %5.0f e(dis)
        di as txt "Reference-negative units" _col(60) "= " ///
            _col(64) as result %5.0f e(nodis)
        di as txt "Pretest probability of disease" _col(60) "= " ///
            _col(64) as result %5.2f e(prev)
        di ""
    }

    nois di ""
    if missing("`fitstats'") {
        nois di in smcl as text "{hline 76}"
        nois di ""
        nois di as text "Log-Likelihood" _col(60) "= " _col(64) as res %7.2f e(loglll)
        nois di ""
        nois di as text "Mean of the Deviance" _col(60) "= " _col(64) as res %7.2f e(dbar)
        nois di ""
        nois di as text "Deviance of the Mean" _col(60) "= " _col(64) as res %7.2f e(dhat)
        nois di ""
        nois di as text "Deviance Information Criterion" _col(60) "= " _col(64) as res %7.2f e(DIC)
        nois di ""
        nois di as text "Watanabe-Akaike Information Criterion" _col(60) "= " _col(64) as res %7.2f e(WAIC)
        nois di ""
        nois di as text "Cross-validated Logarithmic Score" _col(60) "= " _col(64) as res %7.2f e(logscore)
        nois di ""
        nois di as txt "Maximum Gelman-Rubin Convergence Statistic" _col(60) "=" _col(62) as result %9.4f e(mgrubin)
        nois di ""
    }

    nois di ""
    if missing("`coefficients'") {
        preserve
        use "`e(filename)'", clear
        nois di in smcl in gr _newline(1) "{hilite: Fixed and Random Effects Estimates:}"
        nois inla_sumstats logitsen logitspe varlogitsen varlogitspe covvars corrvars
        restore
    }

    if missing("`summary'") {
        preserve
        use "`e(filename)'", clear
        gen double sen = invlogit(logitsen)
        gen double spe = invlogit(logitspe)
        gen double lrp = sen/(1-spe)
        gen double lrn = (1-sen)/spe
        gen double ldor = logitsen + logitspe
        nois di in smcl in gr _newline(1) "{hilite: Summary Test Performance Estimates:}"
        nois inla_sumstats sen spe lrp lrn ldor
        restore
    }

    if "`hetstats'" != "" {
        cap preserve
        use "`e(filename)'", clear
        qui gen I2sen = .
        qui gen I2spe = .
        qui gen I2biv = .
        forvalues i = 1/$midas_nobs {
            mat Vblogit`i' = (varlogitsen[`i'], covvars[`i'] \ covvars[`i'], varlogitspe[`i'])
            qui replace I2sen = varlogitsen[`i']/(varlogitsen[`i'] + ///
                ($avnum1*(exp(((varlogitsen[`i'])/2)+logitsen[`i']) + ///
                exp(((varlogitsen[`i'])/2)-logitsen[`i'])+2))) in `i'
            qui replace I2spe = varlogitspe[`i']/(varlogitspe[`i'] + ///
                ($avnum2*(exp(((varlogitspe[`i'])/2) + ///
                logitspe[`i'])+exp(((varlogitspe[`i'])/2)-logitspe[`i'])+2))) in `i'
            qui replace I2biv = sqrt(exp(log(det(Vblogit`i'))))/(sqrt(exp(log(det(Vblogit`i')))) + ///
                sqrt(($avnum1*(exp(((varlogitsen[`i'])/2)+logitsen[`i']) + ///
                exp(((varlogitsen[`i'])/2)-logitsen[`i'])+2)) * ///
                ($avnum2*(exp(((varlogitspe[`i'])/2)+logitspe[`i']) + ///
                exp(((varlogitspe[`i'])/2)-logitspe[`i'])+2)))) in `i'
        }
        nois di in smcl in gr _newline(1) "{hilite: Heterogeneity/Inconsistency Statistics:}"
        nois inla_sumstats I2sen I2spe I2biv
        cap restore
    }

    nois di ""
    if "`hsroc'" != "" {
        cap preserve
        use "`e(filename)'", clear
        gen double Alpha = (varlogitsen/varlogitspe)^(0.25)*logitspe + ///
            (varlogitspe/varlogitsen)^(0.25)*logitsen
        gen double Theta = 0.5*((varlogitsen/varlogitspe)^(0.25)*logitspe - ///
            (varlogitspe/varlogitsen)^(0.25)*logitsen)
        gen double beta = 0.5*log(varlogitsen/varlogitspe)
        gen double s2alpha = 2*(sqrt(varlogitspe*varlogitsen)+covvars)
        gen double s2theta = 0.5*(sqrt(varlogitspe*varlogitsen)-covvars)
        nois di in smcl in gr _newline(1) "{hilite: Derived HSROC Model Estimates:}"
        nois inla_sumstats Alpha Theta beta s2alpha s2theta
        cap restore
    }

    if "`convergestats'" != "" {
        nois di in smcl in gr _newline(1) "{hilite: Convergence Statistics:}"
        tempname converge
        mat `converge' = e(converge)
        nois _matrix_table `converge', format(%7.2f %7.0f)
        nois di ""
    }

    if "`revman'" != "" {
        tempname bcoef Vcoef coef2
        mat `bcoef' = e(b)
        mat `Vcoef' = e(V)
        local cov01 = `Vcoef'[1,2]
        qui _coef_table, bmatrix(`bcoef') vmatrix(`Vcoef')
        mat `coef2' = r(table)'
        local sn = `coef2'[1,1]
        local snse = `coef2'[1,2]
        local sp = `coef2'[2,1]
        local spse = `coef2'[2,2]
        local reffs1 = `coef2'[3,1]
        local reffs2 = `coef2'[4,1]
        local covlogit = `coef2'[5,1]
        local corrlogit = `coef2'[6,1]
        nois di in smcl as text "{hline 76}"
        nois di in smcl in gr _newline(1) "{hilite: Required Information for Export into RevMan}"
        nois di ""
        nois di in smcl in blue "{title: Parameters for SROC Curve}"
        nois di ""
        nois di as text "{hilite:E(logitse)}: Expected mean logit sensitivity" _col(66) " = " _col(70) as res %5.4f `sn'
        nois di as text "{hilite:E(logitsp)}: Expected mean logit specificity" _col(66) " = " _col(70) as res %5.4f `sp'
        nois di as text "{hilite:Var(logitse)}: Between-study variance of logit sensitivity" _col(66) " = " _col(70) as res %5.4f `reffs1'
        nois di as text "{hilite:Var(logitsp)}: Between-study variance of logit specificity" _col(66) " = " _col(70) as res %5.4f `reffs2'
        nois di as text "{hilite:Cov(logits)}: Between-study Covariance" _col(66) " = " _col(70) as res %5.4f `covlogit'
        nois di as text "{hilite:Corr(logits)}: Between-study Correlation" _col(66) " = " _col(70) as res %5.4f `corrlogit'
        nois di ""
        nois di in smcl in blue "{title: Parameters for Confidence and Prediction Regions:}"
        nois di ""
        nois di as text "{hilite:SE(E(logitse))}: SE of expected mean logit sensitivity" _col(66) " = " _col(70) as res %5.4f `snse'
        nois di as text "{hilite:SE(E(logitsp))}: SE of expected mean logit specificity" _col(66) " = " _col(70) as res %5.4f `spse'
        nois di as text "{hilite:Cov(Es)}: Covariance between mean logit sen and spe" _col(66) " = " _col(70) as res %5.4f `cov01'
        nois di as text "{hilite:Studies}: Number of Studies" _col(66) " = " _col(70) as res %2.0f e(N)
        nois di ""
    }

    if "`moddiag'" != "" {
        preserve
        clear
        mat bb = e(modfit)
        qui svmat bb, names(col)
        foreach modlab in 0.5 1 1.5 2.0 2.5 3.0 3.5 4.0 {
            local modlabpts `"`modlabpts' `=`modlab'' 0 "`modlab'" "'
        }
        qui gen obs = _n
        #delimit ;
        tw (scatter pdi dresidi)
           (scatter pdi dresidi if dresidi < 2.0 | dresidi > -2.0,
            mlw(medthin) mfc(green) mlc(black) msize(*1.5) ms(O))
           (scatter pdi dresidi if dresidi > 2.0 | dresidi < -2.0,
            mlw(medthin) mfc(cranberry) mlc(black) msize(*1.5) ms(O))
           (scatter pdi dresidi if dresidi > 2.0 | dresidi < -2.0,
            ms(i) mlabp(0) mlabel(obs) mlabs(*.5) mlabc(black))
           (function y=1-x^2, range(-1 1) lcolor(green))
           (function y=4-x^2, range(-2 2) lcolor(cranberry))
           (scatteri `modlabpts' (7), msymbol(+) mcolor(black)
            mlabcolor(black) mlabsize(small)),
           legend(off) xti("Deviance Residual") yti("Leverage")
           xlab(-5(1)5) ylab(none) yticks(none)
           xline(0, lcolor(black)) plotr(m(zero)) ;
        #delimit cr
        restore
    }
}

end
capture program drop stan_weights
program define stan_weights, rclass sortpreserve
    version 16.1
    syntax [,]

    cap preserve
    tempname Xmat XTmat Zmat ZZmat Amat Bmat Gmat Sigma
    tempname Vmat invmat fish varb pred
    tempvar pred1 pred2 pred eta1 eta2 eta idvar
    tempvar groupvar true invn varp studyid studygroup sstag

    clear
    qui svmat stan_pred, names(col)
    drop phat*

    gen `studyid' = _n
    qui sreshape long p1 p2, i(`studyid') j(`studygroup')

    qui bys `studygroup': egen double `pred'1 = mean(p1)
    qui bys `studygroup': egen double `pred'2 = mean(p2)
    qui bys `studygroup': egen double `eta'1  = mean(logit(p1))
    qui bys `studygroup': egen double `eta'2  = mean(logit(p2))

    egen `sstag' = tag(`studygroup')
    qui keep if `sstag' == 1

    gen midas_studylabel = `studygroup'
    mkmat `pred'1 `pred'2 `eta'1 `eta'2, matrix(`pred') rownames(midas_studylabel)
    matname `pred' pred1 pred2 eta1 eta2, columns(.) explicit
    return matrix pred = `pred', copy

    keep `pred'*
    qui merge 1:1 _n using "midas_input_data.dta", nogen

    gen `idvar' = _n
    qui sreshape long `pred' midas_denom midas_dep, i(`idvar') j(`groupvar')
    qui tab `groupvar', gen(`true')

    mat `Sigma' = Sigma

    // fixed-effect design
    mkmat `true'1 `true'2, mat(`Xmat')
    mat `XTmat' = `Xmat''

    // random effects
    gen double `invn' = 1/max(midas_denom,1)
    mkmat `invn', mat(`Amat')
    mat `Amat' = diag(`Amat')

    gen double `varp' = (`pred')*(1-`pred')
    mkmat `varp', mat(`Bmat')
    mat `Bmat' = diag(`Bmat')

    mat `Zmat' = I(_N)
    mat `ZZmat' = I(0.5*_N)
    mat `Gmat'  = `ZZmat'#`Sigma'

    mat `Vmat'  = (`Zmat'*`Gmat'*`Zmat'') + (`Amat'*syminv(`Bmat'))
    mat `invmat' = invsym(`Vmat')
    mat `fish'   = `XTmat'*`invmat'*`Xmat'
    mat `varb'   = invsym(`fish')

    qui forvalues i = 1/$midas_nobs {
        mat `Vmat'`i' = `Vmat'
        mat `Vmat'`i'[(`i'*2)-1,(`i'*2)-1] = 1000000000
        mat `Vmat'`i'[(`i'*2)-1,`i'*2]     = 0
        mat `Vmat'`i'[`i'*2,(`i'*2)-1]     = 0
        mat `Vmat'`i'[`i'*2,`i'*2]         = 1000000000

        mat `invmat'`i' = invsym(`Vmat'`i')
        mat `fish'`i'   = `XTmat'*`invmat'`i'*`Xmat'
        mat `fish'`i'_`i' = `fish' - `fish'`i'
        mat weight`i' = `varb'*`fish'`i'_`i'*`varb'

        mat pctwgt`i'sens = 100*(weight`i'[1,1]/`varb'[1,1])
        mat pctwgt`i'spec = 100*(weight`i'[2,2]/`varb'[2,2])
        scalar wgt`i'     = 100*trace(weight`i')/trace(`varb')
    }

    qui keep `idvar' `groupvar' `pred' midas_dep midas_denom midas_studylabel midas_studyid
    qui sreshape wide

    tempvar senwgt spewgt bivwgt
    tempname studywgts
    nois di ""
    nois di ""
    qui gen double `senwgt' = .
    qui gen double `spewgt' = .
    qui gen double `bivwgt' = .

    qui forvalues i = 1/$midas_nobs {
        qui replace `senwgt' = pctwgt`i'sens[1,1] in `i'
        qui replace `spewgt' = pctwgt`i'spec[1,1] in `i'
        qui replace `bivwgt' = wgt`i'           in `i'
    }

    mkmat `senwgt' `spewgt' `bivwgt', matrix(`studywgts') rownames(midas_studylabel)
    matname `studywgts' senwgt spewgt bivwgt, columns(.) explicit
    return matrix stan_weights = `studywgts', copy

    cap restore
end


/********************************************************************************
* midas_stan_fitted
********************************************************************************/
capture program drop midas_stan_fitted
program define midas_stan_fitted, rclass sortpreserve
    version 16.1
    syntax [, TITle FORMAT(string)]

    cap preserve
    mat pred = stan_pred
    clear
    qui svmat pred, names(col)

    gen id = _n
    qui sreshape long phat1 phat2 p1 p2, i(id) j(midas_studyid)

    qui merge m:1 midas_studyid using "midas_input_data.dta", nogen

    tempvar xb pobs1 pobs2 phati yhati ytilde explike loglike meanlike ///
            ptilde dbar dhat dici pdi dresid dresidi sign scaledr deviance ///
            dbari dhati cpoi logscore kldi pkldi sstag randeff serandeff ///
            mulogitsen mulogitspe relogitsen relogitspe idd nkldi
    tempname midasestimates residuals reffects

    gen double `phati'1 = p1
    gen double `phati'2 = p2
    gen double `xb'1    = logit(p1)
    gen double `xb'2    = logit(p2)
    gen double `relogitsen' = `xb'1 - logit(phat1)
    gen double `relogitspe' = `xb'2 - logit(phat2)

    qui bys midas_studylabel: egen double `ptilde'1 = mean(`phati'1)
    qui bys midas_studylabel: egen double `ptilde'2 = mean(`phati'2)

    gen double `yhati'1 = midas_denom1*`phati'1
    gen double `yhati'2 = midas_denom2*`phati'2

    gen double `ytilde'1 = midas_denom1*`ptilde'1
    gen double `ytilde'2 = midas_denom2*`ptilde'2

    qui {
        #delimit ;
        gen double `dbari'1 =
            cond(midas_dep1 >0 & midas_dep1 < midas_denom1,
                 2*midas_dep1*ln(midas_dep1/`yhati'1) +
                 2*(midas_denom1-midas_dep1)*ln((midas_denom1-midas_dep1)/(midas_denom1-`yhati'1)),
                 cond(midas_dep1==0,
                      2*midas_denom1*ln(midas_denom1/(midas_denom1-`yhati'1)),
                      2*midas_dep1*ln(midas_dep1/`yhati'1)));
        #delimit cr

        #delimit ;
        gen double `dbari'2 =
            cond(midas_dep2 >0 & midas_dep2 < midas_denom2,
                 2*midas_dep2*ln(midas_dep2/`yhati'2) +
                 2*(midas_denom2-midas_dep2)*ln((midas_denom2-midas_dep2)/(midas_denom2-`yhati'2)),
                 cond(midas_dep2==0,
                      2*midas_denom2*ln(midas_denom2/(midas_denom2-`yhati'2)),
                      2*midas_dep2*ln(midas_dep2/`yhati'2)));
        #delimit cr
    }

    qui {
        #delimit ;
        gen double `dhati'1 =
            cond(midas_dep1 >0 & midas_dep1 < midas_denom1,
                 2*midas_dep1*ln(midas_dep1/`ytilde'1) +
                 2*(midas_denom1-midas_dep1)*ln((midas_denom1-midas_dep1)/(midas_denom1-`ytilde'1)),
                 cond(midas_dep1==0,
                      2*midas_denom1*ln(midas_denom1/(midas_denom1-`ytilde'1)),
                      2*midas_dep1*ln(midas_dep1/`ytilde'1)));
        #delimit cr

        #delimit ;
        gen double `dhati'2 =
            cond(midas_dep2 >0 & midas_dep2 < midas_denom2,
                 2*midas_dep2*ln(midas_dep2/`ytilde'2) +
                 2*(midas_denom2-midas_dep2)*ln((midas_denom2-midas_dep2)/(midas_denom2-`ytilde'2)),
                 cond(midas_dep2==0,
                      2*midas_denom2*ln(midas_denom2/(midas_denom2-`ytilde'2)),
                      2*midas_dep2*ln(midas_dep2/`ytilde'2)));
        #delimit cr
    }

    gen double `pobs1' = midas_dep1/midas_denom1
    gen double `pobs2' = midas_dep2/midas_denom2

    gen `sign'1 = (`yhati'1-midas_dep1)/abs(`yhati'1-midas_dep1)
    gen `sign'2 = (`yhati'2-midas_dep2)/abs(`yhati'2-midas_dep2)

    gen double `dresid'1 = (`sign'1*sqrt(abs(`dbari'1)))
    gen double `dresid'2 = (`sign'2*sqrt(abs(`dbari'2)))

    gen double `dresid' = `dresid'1 + `dresid'2
    qui bys midas_studylabel: egen double `dresidi' = mean(`dresid')

    gen double `loglike'1 = midas_dep1*log(invlogit(`xb'1)) + ///
        (midas_denom1-midas_dep1)*log(1-invlogit(`xb'1))
    gen double `loglike'2 = midas_dep2*log(invlogit(`xb'2)) + ///
        (midas_denom2-midas_dep2)*log(1-invlogit(`xb'2))
    gen double `loglike'  = `loglike'1 + `loglike'2

    qui bys midas_studylabel: egen double `meanlike' = mean(`loglike')
    gen double `deviance' = -2*`loglike'

    qui bys midas_studylabel: egen double `randeff'1 = mean(`relogitsen')
    qui bys midas_studylabel: egen double `randeff'2 = mean(`relogitspe')
    qui bys midas_studylabel: egen double `serandeff'1 = sd(`relogitsen')
    qui bys midas_studylabel: egen double `serandeff'2 = sd(`relogitspe')

    gen double `explike' = exp(`loglike')
    egen double `cpoi' = hmean(`explike'), by(midas_studyid)

    gen double `dbar' = `dbari'1 + `dbari'2
    qui bys midas_studylabel: egen double `dbari' = mean(`dbar')

    gen double `dhat' = `dhati'1 + `dhati'2
    qui bys midas_studylabel: egen double `dhati' = mean(`dhat')

    egen `sstag' = tag(midas_studylabel)
    qui keep if `sstag' == 1

    gen double `logscore' = -log(`cpoi')
    gen double `kldi'     = `logscore' + `meanlike'
    gen double `nkldi'    = 1-exp(-`kldi')
    gen double `pdi'      = `dbari' - `dhati'
    gen double `dici'     = `dbari' + `pdi'

    qui sort midas_studylabel

    mkmat `pobs1' `pobs2' `phati'1 `phati'2 `pdi' `dresidi' `logscore' `kldi' `nkldi', ///
        matrix(`midasestimates') rownames(midas_studylabel)

    mkmat `randeff'1 `randeff'2 `serandeff'1 `serandeff'2, ///
        matrix(`reffects') rownames(midas_studylabel)

    mkmat `dresidi', ///
        matrix(`residuals') rownames(midas_studylabel)

    qui sum `logscore', meanonly
    return scalar logscore = r(mean)

    qui sum `loglike', meanonly
    return scalar logll = r(sum)

    matname `midasestimates' pobs1 pobs2 phati1 phati2 pdi dresidi logscore kldi nkldi, columns(.) explicit
    return matrix midasmh_fit = `midasestimates', copy

    matname `residuals' dresidi, columns(.) explicit
    return matrix residuals = `residuals', copy

    matname `reffects' randeff1 randeff2 serandeff1 serandeff2, columns(.) explicit
    return matrix reffects = `reffects', copy

    cap restore
end


/********************************************************************************
* midas_stan_mat
********************************************************************************/
capture program drop midas_stan_mat
program define midas_stan_mat, rclass
    cap preserve
    tempname Vblogit
    tempvar varlogitsen varlogitspe logitsen logitspe corrvars covvars
    tempvar sen spe lrn lrp ldor I2sen I2spe I2
    tempvar Alpha Theta beta s2alpha s2theta

    gen double `logitsen'    = mul1
    gen double `logitspe'    = mul2
    gen double `varlogitsen' = sigma11
    gen double `varlogitspe' = sigma22
    gen double `covvars'     = sigma12
    gen double `corrvars'    = rho

    gen double `sen' = invlogit(`logitsen')
    gen double `spe' = invlogit(`logitspe')
    gen double `lrp' = `sen'/(1-`spe')
    gen double `lrn' = (1-`sen')/`spe'
    gen double `ldor'= `logitsen' + `logitspe'

    gen double `Alpha'  = (`varlogitsen'/`varlogitspe')^(0.25)*`logitspe' + ///
                          (`varlogitspe'/`varlogitsen')^(0.25)*`logitsen'
    gen double `Theta'  = 0.5*((`varlogitsen'/`varlogitspe')^(0.25)*`logitspe' - ///
                          (`varlogitspe'/`varlogitsen')^(0.25)*`logitsen')
    gen double `beta'   = 0.5*log(`varlogitsen'/`varlogitspe')
    gen double `s2alpha'= 2*(sqrt(`varlogitspe'*`varlogitsen')+`covvars')
    gen double `s2theta'= 0.5*(sqrt(`varlogitspe'*`varlogitsen')-`covvars')

    qui gen `I2sen' = .
    qui gen `I2spe' = .
    qui gen `I2'    = .

    forvalues i = 1/$midas_nobs {
        mat `Vblogit'`i' = (`varlogitsen'[`i'], `covvars'[`i'] \ `covvars'[`i'], `varlogitspe'[`i'])

        qui replace `I2sen' = `varlogitsen'[`i']/(`varlogitsen'[`i'] + ///
            ($avnum1*(exp((`varlogitsen'[`i']/2)+`logitsen'[`i']) + ///
            exp((`varlogitsen'[`i']/2)-`logitsen'[`i']) + 2))) in `i'

        qui replace `I2spe' = `varlogitspe'[`i']/(`varlogitspe'[`i'] + ///
            ($avnum2*(exp((`varlogitspe'[`i']/2)+`logitspe'[`i']) + ///
            exp((`varlogitspe'[`i']/2)-`logitspe'[`i']) + 2))) in `i'

        qui replace `I2' =  sqrt(exp(log(det(`Vblogit'`i')))) / ///
            (sqrt(exp(log(det(`Vblogit'`i')))) + ///
            sqrt(($avnum1*(exp((`varlogitsen'[`i']/2)+`logitsen'[`i']) + ///
            exp((`varlogitsen'[`i']/2)-`logitsen'[`i']) + 2)) * ///
            ($avnum2*(exp((`varlogitspe'[`i']/2)+`logitspe'[`i']) + ///
            exp((`varlogitspe'[`i']/2)-`logitspe'[`i']) + 2)))) in `i'
    }

    qui correlate `logitsen' `logitspe', covariance
    return scalar covmuls = r(cov_12)

    // summary test performance
    local varlist "`sen' `spe' `lrp' `lrn' `ldor'"
    local sumnames: di "Sens Spec LRp LRn LOR"
    mata: stan_mat("`varlist'", "`touse'")
    mat means = r(mean)
    mat colnames means = `sumnames'
    return matrix bsum = means, copy
    mat medians = r(median)
    mat colnames medians = `sumnames'
    return matrix bsummed = medians, copy
    mat sems = r(sem)'
    mat colnames sems = `sumnames'
    return matrix bsumsd = sems, copy
    mat covs = r(cov)
    mat colnames covs = `sumnames'
    mat rownames covs = `sumnames'
    return matrix Vsum = covs, copy

    // HSROC
    local varlist "`Alpha' `Theta' `beta' `s2alpha' `s2theta'"
    local hsrocnames: di "Alpha Theta beta s2alpha s2theta"
    mata: stan_mat("`varlist'", "`touse'")
    mat means = r(mean)
    mat colnames means = `hsrocnames'
    return matrix bhsroc = means, copy
    mat medians = r(median)
    mat colnames medians = `hsrocnames'
    return matrix bhsrocmed = medians, copy
    mat sems = r(sem)'
    mat colnames sems = `hsrocnames'
    return matrix bhsrocsd = sems, copy
    mat covs = r(cov)
    mat colnames covs = `hsrocnames'
    mat rownames covs = `hsrocnames'
    return matrix Vhsroc = covs, copy

    // I^2
    local varlist "`I2sen' `I2spe' `I2'"
    local isqnames: di "I2sen I2spe I2biv"
    mata: stan_mat("`varlist'", "`touse'")
    mat means = r(mean)
    mat colnames means = `isqnames'
    return matrix bIsq = means, copy
    mat medians = r(median)
    mat colnames medians = `isqnames'
    return matrix bIsqmed = medians, copy
    mat sems = r(sem)'
    mat colnames sems = `isqnames'
    return matrix bIsqsd = sems, copy
    mat covs = r(cov)
    mat colnames covs = `isqnames'
    mat rownames covs = `isqnames'
    return matrix VIsq = covs, copy

    // Hessian-scale parameters
    local varlist "`logitsen' `logitspe' `varlogitsen' `varlogitspe' `covvars'"
    local hessnames: di "logitsen logitspe varlogitsen varlogitspe covvars"
    mata: stan_mat("`varlist'", "`touse'")
    mat means = r(mean)
    mat colnames means = `hessnames'
    return matrix bhess = means, copy
    mat medians = r(median)
    mat colnames medians = `hessnames'
    return matrix bhessmed = medians, copy
    mat sems = r(sem)'
    mat colnames sems = `hessnames'
    return matrix bhesssd = sems, copy
    mat covs = r(cov)
    mat colnames covs = `hessnames'
    mat rownames covs = `hessnames'
    return matrix Vhess = covs, copy

    // coefficient-scale parameters
    local varlist "`logitsen' `logitspe' `varlogitsen' `varlogitspe' `covvars' `corrvars'"
    local coefnames: di "logitsen logitspe varlogitsen varlogitspe covvars corrvars"
    mata: stan_mat("`varlist'", "`touse'")
    mat means = r(mean)
    mat colnames means = `coefnames'
    return matrix b = means, copy
    mat medians = r(median)
    mat colnames medians = `coefnames'
    return matrix bmed = medians, copy
    mat sems = r(sem)'
    mat colnames sems = `coefnames'
    return matrix bsd = sems, copy
    mat covs = r(cov)
    mat colnames covs = `coefnames'
    mat rownames covs = `coefnames'
    return matrix V = covs, copy

    cap restore
end


/********************************************************************************
* stan_prp and Mata _stan_prp
********************************************************************************/
capture program drop stan_prp
program define stan_prp, rclass
    version 17
    syntax [, TITle FORMAT(string asis)]

    preserve
    mat loglike = loglike
    clear
    qui svmat loglike

    forvalues junk = 1/$midas_nobs {
        rename loglike`junk' loglik`junk'1
    }
    rename loglike# loglike#, renumber(1)
    rename loglike# loglik#2

    forvalues junk = 1/$midas_nobs {
        egen loglike`junk' = rowtotal(loglik`junk'1 loglik`junk'2)
    }
    keep loglike*
    egen loglike = rowtotal(loglike*)

    tempvar varlist maxlike explike loowgtnorm loowgtreg
    gen `varlist' = loglike
    egen `maxlike' = max(`varlist')
    egen `explike' = mean((1/exp(`varlist'-`maxlike')))
    gen  `loowgtnorm' = (1/exp(`varlist'-`maxlike'))/`explike'
    gen  `loowgtreg'  = min(`loowgtnorm', sqrt(_N))

    mata: _stan_prp("`varlist' `loowgtreg'", "`touse'")
    tempname tmp
    mat `tmp' = r(biccv)
    matrix rownames `tmp' = value

    nois di ""
    if "`title'" != "" {
        di as smcl "{hilite: Bayesian Posterior Predictive Performance Metrics}"
    }
    nois di ""
    nois _matrix_table `tmp', formats(`format')
    nois di ""

    ret matrix ppp      = `tmp'
    ret scalar deviance = r(deviance)
    ret scalar pd       = r(pd)
    ret scalar elppddev = r(elppd_dev)
    ret scalar pwaic    = r(p_waic)
    ret scalar elppdwaic= r(elppd_waic)
    ret scalar waic     = r(waic)
    ret scalar ploo     = r(p_loo)
    ret scalar elppdloo = r(elppd_loo)
    ret scalar loocv    = r(loo_cv)
    ret scalar dbar     = r(dbar)
    ret scalar dic      = r(dic)
    ret scalar dhat     = r(dhat)
    ret scalar lppd     = r(lppd)
    ret scalar loglll   = r(loglll)
    restore
end

mata:
void _stan_prp(string scalar varlist, string scalar touse)
{
    real matrix    M
    real colvector loowgtraw, loowgtnorm, loowgtreg
    real rowvector biccv
    real scalar    nobs, lppd, elppd_dev, waic, p_waic, elppd_waic
    real scalar    elppd_loo, p_loo, i, pd, dbar, dhat, dic, loo_cv, deviance, loglll

    M = .
    st_view(M,., tokens(varlist), touse)

    nobs    = rows(M)
    loglll  = mean(M[.,1])
    deviance= mean(-2*M[.,1])
    dbar    = -2*mean(M[.,1])
    pd      = variance(-2*M[.,1])/2
    dic     = dbar + pd
    dhat    = dbar - pd
    lppd    = log(mean(exp(M[.,1])))
    elppd_dev = -2*log(mean(exp(M[.,1])))
    p_waic  = variance(M[.,1])
    elppd_waic = log(mean(exp(M[.,1]))) - variance(M[.,1])
    waic    = -2*(log(mean(exp(M[.,1])))-variance(M[.,1]))

    for(i=1; i<=nobs; i++) {
        loowgtraw  = 1:/exp(M[i,1]:-max(M[.,1]))
        loowgtnorm = (1:/exp(M[i,1]:-max(M[.,1]))):/mean(1:/exp(M[.,1]:-max(M[.,1])))
        loowgtreg  = M[i,2]
        elppd_loo  = log(mean(exp(M[i,1]):*loowgtreg):/mean(loowgtreg))
    }

    p_loo = lppd - elppd_loo
    loo_cv = -2*elppd_loo
    biccv = (deviance, dic, loo_cv, waic)

    st_numscalar("r(loglll)",  loglll)
    st_numscalar("r(deviance)",deviance)
    st_numscalar("r(pd)",      pd)
    st_numscalar("r(lppd)",    lppd)
    st_numscalar("r(p_waic)",  p_waic)
    st_numscalar("r(elppd_dev)", elppd_dev)
    st_numscalar("r(elppd_waic)",elppd_waic)
    st_numscalar("r(waic)",    waic)
    st_numscalar("r(p_loo)",   p_loo)
    st_numscalar("r(elppd_loo)", elppd_loo)
    st_numscalar("r(loo_cv)",  loo_cv)
    st_numscalar("r(dbar)",    dbar)
    st_numscalar("r(dhat)",    dhat)
    st_numscalar("r(dic)",     dic)
    st_matrix("r(biccv)", biccv)
    st_matrixcolstripe("r(biccv)", ("","Deviance"\"","DIC"\"","LOOCV"\"","WAIC"))
}
end


/********************************************************************************
* midasstan_model
********************************************************************************/
cap program drop midasstan_model
program define midasstan_model
    syntax , COVariance(string) [MODELname(string) MUPrior(string asis) ///
        SIGMAPrior(string asis) PHIPrior(string asis) RHOPrior(string asis) ///
        LAMDAPrior(string asis) *]

    tempname h
    file open `h' using "`modelname'", write text replace

    // --- data block (all covariances) ---
    file write `h' "data {" _n
    file write `h' "int<lower = 0> midas_nobs;" _n
    file write `h' "array[midas_nobs] int<lower=0> midas_dep1;" _n
    file write `h' "array[midas_nobs] int<lower=0> midas_denom1;" _n
    file write `h' "array[midas_nobs] int<lower=0> midas_dep2;" _n
    file write `h' "array[midas_nobs] int<lower=0> midas_denom2;" _n
    file write `h' "}" _n

    // --- covariance-specific blocks ---
    if "`covariance'" == "iwishart" {
        file write `h' "transformed data{" _n
        file write `h' "cov_matrix[2] Omega;" _n
        file write `h' "Omega = diag_matrix(rep_vector(1.0,2));" _n
        file write `h' "}" _n
        file write `h' "parameters {" _n
        file write `h' "vector[2] mul;" _n
        file write `h' "cov_matrix[2] Sigma;" _n
        file write `h' "array[midas_nobs] vector[2] logitp;" _n
        file write `h' "}" _n
        file write `h' "transformed parameters {" _n
        file write `h' "real rho;" _n
        file write `h' "array[2] vector[midas_nobs] p;" _n
        file write `h' "rho = Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2]);" _n
        file write `h' "for (a in 1:2) {" _n
        file write `h' "for (b in 1:midas_nobs) {" _n
        file write `h' "p[a][b] = inv_logit(logitp[b][a]);" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "model {" _n
        file write `h' "mul ~ `muprior';" _n
        file write `h' "Sigma ~ inv_wishart(3, Omega);" _n
        file write `h' "logitp ~ multi_normal(mul, Sigma);" _n
        file write `h' "midas_dep1 ~ binomial(midas_denom1, p[1]);" _n
        file write `h' "midas_dep2 ~ binomial(midas_denom2, p[2]);" _n
        file write `h' "}" _n
    }
    else if "`covariance'" == "hiwishart" {
        file write `h' "parameters {" _n
        file write `h' "vector[2] mul;" _n
        file write `h' "vector[2] lamda;" _n
        file write `h' "cov_matrix[2] Sigma;" _n
        file write `h' "array[midas_nobs] vector[2] logitp;" _n
        file write `h' "}" _n
        file write `h' "transformed parameters {" _n
        file write `h' "real rho;" _n
        file write `h' "array[2] vector[midas_nobs] p;" _n
        file write `h' "cov_matrix[2] Omega;" _n
        file write `h' "Omega = 4*diag_matrix(lamda);" _n
        file write `h' "rho = Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2]);" _n
        file write `h' "for (a in 1:2) {" _n
        file write `h' "for (b in 1:midas_nobs) {" _n
        file write `h' "p[a][b] = inv_logit(logitp[b][a]);" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "model {" _n
        file write `h' "mul ~ `muprior';" _n
        file write `h' "lamda ~ gamma(0.5, 1);" _n
        file write `h' "Sigma ~ inv_wishart(3, Omega);" _n
        file write `h' "logitp ~ multi_normal(mul, Sigma);" _n
        file write `h' "midas_dep1 ~ binomial(midas_denom1, p[1]);" _n
        file write `h' "midas_dep2 ~ binomial(midas_denom2, p[2]);" _n
        file write `h' "}" _n
    }
    else if "`covariance'" == "sciwishart" {
        file write `h' "parameters {" _n
        file write `h' "vector[2] mul;" _n
        file write `h' "vector<lower=0> [2] delta;" _n
        file write `h' "cov_matrix[2] Q;" _n
        file write `h' "array[midas_nobs] vector[2] logitp;" _n
        file write `h' "}" _n
        file write `h' "transformed parameters {" _n
        file write `h' "cov_matrix[2] Sigma;" _n
        file write `h' "matrix[2,2] Omega;" _n
        file write `h' "real rho;" _n
        file write `h' "array[2] vector[midas_nobs] p;" _n
        file write `h' "Omega = 3*diag_matrix(rep_vector(1,2));" _n
        file write `h' "Sigma[1,1] = delta[1]*delta[1]*Q[1,1];" _n
        file write `h' "Sigma[1,2] = delta[1]*delta[2]*Q[1,2];" _n
        file write `h' "Sigma[2,2] = delta[2]*delta[2]*Q[2,2];" _n
        file write `h' "Sigma[2,1] = delta[1]*delta[2]*Q[1,2];" _n
        file write `h' "for (i in 1:2) {" _n
        file write `h' "for (j in 1:i) {" _n
        file write `h' "Sigma[i, j] = Sigma[j,i];" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "rho = Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2]);" _n
        file write `h' "for (a in 1:2) {" _n
        file write `h' "for (b in 1:midas_nobs) {" _n
        file write `h' "p[a][b] = inv_logit(logitp[b][a]);" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "model {" _n
        file write `h' "mul ~ `muprior';" _n
        file write `h' "delta ~ lognormal(0, 1);" _n
        file write `h' "Q ~ inv_wishart(3, Omega);" _n
        file write `h' "logitp ~ multi_normal(mul, Sigma);" _n
        file write `h' "midas_dep1 ~ binomial(midas_denom1, p[1]);" _n
        file write `h' "midas_dep2 ~ binomial(midas_denom2, p[2]);" _n
        file write `h' "}" _n
    }
    else if "`covariance'" == "cholesky" {
        file write `h' "parameters {" _n
        file write `h' "array[midas_nobs] vector[2] logitp;" _n
        file write `h' "vector[2] mul;" _n
        file write `h' "vector<lower=0>[2] sigma;" _n
        file write `h' "real rho;" _n
        file write `h' "}" _n
        file write `h' "transformed parameters {" _n
        file write `h' "array[2] vector[midas_nobs] p;" _n
        file write `h' "corr_matrix[2] Omega;" _n
        file write `h' "cov_matrix[2] Sigma;" _n
        file write `h' "Omega[1, 1] = 1;" _n
        file write `h' "Omega[1, 2] = rho;" _n
        file write `h' "Omega[2, 1] = rho;" _n
        file write `h' "Omega[2, 2] = 1 ;" _n
        file write `h' "Sigma = quad_form_diag(Omega,sigma);" _n
        file write `h' "for (i in 1:2) {" _n
        file write `h' "for (j in 1:i) {" _n
        file write `h' "Sigma[i, j] = Sigma[j,i];" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "for (a in 1:2) {" _n
        file write `h' "for (b in 1:midas_nobs) {" _n
        file write `h' "p[a][b] = inv_logit(logitp[b][a]);" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "model {" _n
        file write `h' "mul ~ `muprior';" _n
        file write `h' "sigma ~ `sigmaprior';" _n
        file write `h' "rho ~ `rhoprior';" _n
        file write `h' "logitp ~ multi_normal(mul, Sigma);" _n
        file write `h' "midas_dep1 ~ binomial(midas_denom1, p[1]);" _n
        file write `h' "midas_dep2 ~ binomial(midas_denom2, p[2]);" _n
        file write `h' "}" _n
    }
    else if "`covariance'" == "product" {
        file write `h' "parameters {" _n
        file write `h' "array[midas_nobs] vector[2] logitp;" _n
        file write `h' "vector<lower=0>[2] sigma;" _n
        file write `h' "real mul1;" _n
        file write `h' "vector[2] lamda;" _n
        file write `h' "}" _n
        file write `h' "transformed parameters {" _n
        file write `h' "array[2] vector[midas_nobs] p;" _n
        file write `h' "real rho;" _n
        file write `h' "matrix[2,2] Sigma;" _n
        file write `h' "vector[2] mul;" _n
        file write `h' "mul[1] = mul1;" _n
        file write `h' "mul[2] = (lamda[1]+lamda[2]*(mul1));" _n
        file write `h' "rho =(lamda[2]*sigma[1])/(sqrt(sigma[1])*sqrt(sigma[2]+sigma[1]*lamda[2]^2));" _n
        file write `h' "Sigma[1,1] = sigma[1];" _n
        file write `h' "Sigma[1,2] = lamda[2]*sigma[1];" _n
        file write `h' "Sigma[2,1] = lamda[2]*sigma[1];" _n
        file write `h' "Sigma[2,2] = sigma[2] + sigma[1]*lamda[2]^2;" _n
        file write `h' "for (i in 1:2) {" _n
        file write `h' "for (j in 1:i) {" _n
        file write `h' "Sigma[i, j] = Sigma[j,i];" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "for (a in 1:2) {" _n
        file write `h' "for (b in 1:midas_nobs) {" _n
        file write `h' "p[a][b] = inv_logit(logitp[b][a]);" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "model {" _n
        file write `h' "mul ~ `muprior';" _n
        file write `h' "mul1~ `muprior';" _n
        file write `h' "lamda ~ `lamdaprior';" _n
        file write `h' "sigma ~ `sigmaprior';" _n
        file write `h' "logitp ~ multi_normal(mul, Sigma);" _n
        file write `h' "midas_dep1 ~ binomial(midas_denom1, p[1]);" _n
        file write `h' "midas_dep2 ~ binomial(midas_denom2, p[2]);" _n
        file write `h' "}" _n
    }
    else if "`covariance'" == "cholefisher" {
        file write `h' "parameters {" _n
        file write `h' "array[midas_nobs] vector[2] logitp;" _n
        file write `h' "vector[2] mul;" _n
        file write `h' "vector<lower=0>[2] sigma;" _n
        file write `h' "real etarho;" _n
        file write `h' "}" _n
        file write `h' "transformed parameters {" _n
        file write `h' "array[2] vector[midas_nobs] p;" _n
        file write `h' "real rho;" _n
        file write `h' "corr_matrix[2] Omega;" _n
        file write `h' "cov_matrix[2] Sigma;" _n
        file write `h' "rho = tanh(etarho);" _n
        file write `h' "Omega[1, 1] = 1;" _n
        file write `h' "Omega[1, 2] = rho;" _n
        file write `h' "Omega[2, 1] = rho;" _n
        file write `h' "Omega[2, 2] = 1;" _n
        file write `h' "Sigma = quad_form_diag(Omega, sigma);" _n
        file write `h' "for (i in 1:2) {" _n
        file write `h' "for (j in 1:i) {" _n
        file write `h' "Sigma[i, j] = Sigma[j,i];" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "for (a in 1:2) {" _n
        file write `h' "for (b in 1:midas_nobs) {" _n
        file write `h' "p[a][b] = inv_logit(logitp[b][a]);" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "model {" _n
        file write `h' "mul ~ `muprior';" _n
        file write `h' "sigma ~ `sigmaprior';" _n
        file write `h' "etarho ~ normal(0, 10);" _n
        file write `h' "logitp ~ multi_normal(mul, Sigma);" _n
        file write `h' "midas_dep1 ~ binomial(midas_denom1, p[1]);" _n
        file write `h' "midas_dep2 ~ binomial(midas_denom2, p[2]);" _n
        file write `h' "}" _n
    }
    else if "`covariance'" == "spherical" {
        file write `h' "parameters {" _n
        file write `h' "array[midas_nobs] vector[2] logitp;" _n
        file write `h' "vector[2] mul;" _n
        file write `h' "vector<lower=0>[2] sigma;" _n
        file write `h' "real phi;" _n
        file write `h' "}" _n
        file write `h' "transformed parameters {" _n
        file write `h' "array[2] vector[midas_nobs] p;" _n
        file write `h' "real rho;" _n
        file write `h' "corr_matrix[2] Omega;" _n
        file write `h' "cov_matrix[2] Sigma;" _n
        file write `h' "rho = cos(phi);" _n
        file write `h' "Omega[1,1] = 1;" _n
        file write `h' "Omega[1,2] = rho;" _n
        file write `h' "Omega[2,1] = rho;" _n
        file write `h' "Omega[2,2] = 1 ;" _n
        file write `h' "Sigma = quad_form_diag(Omega,sigma);" _n
        file write `h' "for (i in 1:2) {" _n
        file write `h' "for (j in 1:i) {" _n
        file write `h' "Sigma[i, j] = Sigma[j,i];" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "for (a in 1:2) {" _n
        file write `h' "for (b in 1:midas_nobs) {" _n
        file write `h' "p[a][b] = inv_logit(logitp[b][a]);" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "}" _n
        file write `h' "model {" _n
        file write `h' "mul ~ `muprior';" _n
        file write `h' "sigma ~ `sigmaprior';" _n
        file write `h' "phi ~ `phiprior';" _n
        file write `h' "logitp ~ multi_normal(mul, Sigma);" _n
        file write `h' "midas_dep1 ~ binomial(midas_denom1, p[1]);" _n
        file write `h' "midas_dep2 ~ binomial(midas_denom2, p[2]);" _n
        file write `h' "}" _n
    }

    // --- generated quantities (all covariances) ---
    file write `h' "generated quantities {" _n
    file write `h' "vector[2*midas_nobs] loglik;" _n
    file write `h' "array[midas_nobs] vector[2] logitphat;" _n
    file write `h' "array[2] vector[midas_nobs] phat;" _n
    file write `h' "for (i in 1:midas_nobs) {" _n
    file write `h' "loglik[i] = binomial_lpmf(midas_dep1[i] | midas_denom1[i], p[1][i]);" _n
    file write `h' "}" _n
    file write `h' "for (i in (midas_nobs+1):(2*midas_nobs)) {" _n
    file write `h' "loglik[i] = binomial_lpmf(midas_dep2[i-midas_nobs] | midas_denom2[i-midas_nobs], p[2][i-midas_nobs]);" _n
    file write `h' "}" _n
    file write `h' "for (i in 1:midas_nobs) {" _n
    file write `h' "logitphat[i] = multi_normal_rng(mul, Sigma);" _n
    file write `h' "}" _n
    file write `h' "for (a in 1:2) {" _n
    file write `h' "for (b in 1:midas_nobs) {" _n
    file write `h' "phat[a][b] = inv_logit(logitphat[b][a]);" _n
    file write `h' "}" _n
    file write `h' "}" _n
    file write `h' "}" _n

    file close `h'
end


/********************************************************************************
* stan_fitstats (unused, kept for completeness)
********************************************************************************/
capture program drop stan_fitstats
program define stan_fitstats, rclass
    preserve
    clear
    svmat loglike
    forvalues junk = 1/$midas_nobs {
        rename loglike`junk' loglik`junk'1
    }
    rename loglike# loglike#, renumber(1)
    rename loglike# loglik#2

    forvalues junk = 1/$midas_nobs {
        egen loglike`junk' = rowtotal(loglik`junk'1 loglik`junk'2)
    }
    keep loglike*
    xpose, clear
    local nobs = _N

    tempvar pwaic meanlike lppd waic
    egen double `pwaic' = rowsd(v1-v`nobs')
    replace `pwaic' = `pwaic'*`pwaic'

    foreach var of varlist v* {
        gen double like`var' = exp(`var')
    }
    egen double `meanlike' = rowmean(likev1-likev`nobs')
    gen double `lppd'      = log(`meanlike')
    gen double `waic'      = -2*(`lppd' - `pwaic')

    sum `waic', meanonly
    return scalar waic = r(sum)
    sum `pwaic', meanonly
    return scalar pwaic = r(sum)
    restore
end


/********************************************************************************
* Mata: stan_mat
********************************************************************************/
mata:
void stan_mat(string scalar varlist, string scalar touse)
{
    real matrix M
    real rowvector stan_means, stan_medians
    real matrix stan_covs
    real colvector stan_sem

    M = .
    st_view(M, ., tokens(varlist), 0)
    stan_means   = mean(M)
    stan_medians = mm_median(M)
    stan_covs    = variance(M)
    stan_sem     = sqrt(diagonal(stan_covs))

    st_matrix("r(mean)",   stan_means)
    st_matrix("r(median)", stan_medians)
    st_matrix("r(sem)",    stan_sem)
    st_matrix("r(cov)",    stan_covs)
}
end


/********************************************************************************
* stan_converge + mcmcconverge + Mata mvfun
********************************************************************************/
capture program drop stan_converge
program define stan_converge, rclass sortpreserve
    version 17.0
    syntax [,]

    cap preserve
    bysort chain: gen niter = _n
    local _convpath "`c(pwd)'/midas_convergestats.dta"
    mcmcconverge mul1 mul2 sigma11 sigma22 sigma12 rho, iter(niter) chain(chain) ///
        saving("`_convpath'") replace
    use "`_convpath'", clear
    tempvar rowid
    decode variable, gen(`rowid')
    mkmat Rhat neff, mat(converge) rownames(`rowid')
    local cvstatsnames: di "logitse logitspe varlogitsen varlogitspe covvars corrvars"
    mat rownames converge = `cvstatsnames'
    sum Rhat, meanonly
    return scalar rmax = r(max)
    return matrix converge = converge, copy
    cap restore
end


program mcmcconverge
    version 12.1
    // Gelman-Carlin-Stern-Rubin convergence statistics

    syntax varlist [if] [in], iter(varname) chain(varname) saving(string asis) [replace]

    marksample touse
    preserve
    qui keep `iter' `chain' `varlist' `touse'
    qui keep if `touse'

    capture assert _N>0
    if _rc!=0 {
        display("failed: no data satisfy the specifications.")
        exit
    }

    qui xtset `chain' `iter'
    capture assert "`r(balanced)'"!="unbalanced"
    if _rc!=0 {
        display("failed: chains have different numbers of observations.")
        exit
    }

    qui levelsof `chain', local(usechains)
    local nc : word count `usechains'
    local niters = _N/`nc'
    unab vars : `varlist'
    local nv : word count `vars'

    mata: mvfun("`vars'","`chain'")
    qui gen double varplus = (B+(`niters'-1)*W)/`niters'
    qui gen double Rhat    = sqrt(varplus/W)
    qui gen double neff    = `niters'*`nc'*varplus/B
    qui gen double neffmin = min(neff,`niters'*`nc')

    capture lab drop _all
    forvalues i=1/`nv' {
        local v : word `i' of `vars'
        lab def variable `i' "`v'", add
    }
    lab values variable variable
    lab var B       "between-sequence variance"
    lab var W       "within-sequence variance"
    lab var varplus "marginal posterior variance"
    lab var Rhat    "potential scale reduction"
    lab var neff    "effective number of independent draws"
    lab var neffmin "min(neff, actual number of draws)"

    qui compress
    qui save `saving', `replace'
end

mata:
mata set matastrict on
mata set matafavor speed

void mvfun(string scalar vars, string scalar chain)
{
    real matrix cvec, cinfo, x, res_m, res_v, work, B
    real scalar c, nc, nx, i

    cvec  = st_data(.,chain)
    cinfo = panelsetup(cvec,1)
    nc    = rows(cinfo)
    x     = st_data(.,vars)
    nx    = cols(x)

    res_m = J(nc,nx,0)
    res_v = J(nc,nx,0)

    for(c=1; c<=nc; c++) {
        work       = panelsubmatrix(x,c,cinfo)
        res_m[c,.] = mean(work)
        for(i=1; i<=nx; i++) {
            res_v[c,i]= variance(work[.,i])
        }
    }

    stata("qui drop _all")
    st_addobs(nx)
    (void) st_addvar("long","variable")
    st_store(.,1,range(1,nx,1))
    (void) st_addvar("double","B")
    B = J(nx,1,.)
    for(i=1; i<=nx; i++) {
        B[i,1] = variance(res_m[.,i])
    }
    st_store(.,2,B*rows(work))
    (void) st_addvar("double","W")
    st_store(.,3,mean(res_v)')
}
end



// Minimal 2022 modification of mcmcstats by John Thompson (2012)
program inla_sumstats , rclass byable(recall)
   version 12.1
   syntax varlist [if] [in] , [ ///
   Hpd                          /// give HPD rather than credible intervals
   Level(cilevel)               /// % for credible or HPD intervals
   CORrelations                 /// add the correlation matrix to the output
   COVariances                  /// add the covariance matrix to the output
   Save(string)                 /// file to save the table of results
   ]
   
   preserve
   
   cap estimates store _midas_estimates
   marksample touse, novarlist
   qui keep if `touse'
*-------------------------------------
* test remaining number obs
*-------------------------------------
   if _N < 2 {
      di as err "Calculation requires at least two iterations"
      restore
      exit(0)
   }
*-------------------------------------
* perform calculations
*-------------------------------------
   tempvar order
   tempname mV C
   cap tsset
   local oldt = r(timevar)
   gen `order' = _n
   qui tsset `order'
*-------------------------------------
* parse save option & open file
*-------------------------------------
   if `"`save'"' != "" {
      tokenize `"`save'"' , parse(" ,")
      tempname pf
      postfile `pf' str20 parameter n mean sd sem median lb ub using `"`1'"', `3'
   }
*--------------------------------
* summarize each variable in turn
*--------------------------------
 	di in smcl as txt "{hline 13}{c TT}{hline 64}"
   if "`hpd'" == "" {
      di in smcl in gr "Parameter    {c |}     mean      sd"  /*
	*/ `"      mcse       median    [`=strsubdp("`level'")'% Cred. Interval]"'
    }
    else {
     di in smcl in gr "Parameter    {c |}      mean      sd"  /*
	*/ `"      mcse      median          [`=strsubdp("`level'")'% HPD]"'
    }
    	di in smcl as txt "{hline 13}{c +}{hline 64}"
   local lcentile = (100-`level')/2
   local ucentile = 100-`lcentile'
   local i = 0
   foreach v of varlist `varlist' {
*---------------------------------------
* Calculated the statistics
*---------------------------------------
      qui summ `v' 
      local mn = r(mean)
      local sd = r(sd)
      local n = r(N)
      qui centile `v' 
      local md = r(c_1)
      local lb "."
      local ub "."
      if "`hpd'" == "" & `n' > 5 {
         qui centile `v'  , cen(`lcentile')
         local lb = r(c_1)
         qui centile `v'  , cen(`ucentile')
         local ub = r(c_1)
      }
      else if `n' > 5 {
         inla_sumstats_hpd `v'  , alpha(`level')
         local lb = r(low)
         local ub = r(high)
      }
      qui cap prais `v' 
      if _rc == 0 {
         matrix `mV' = e(V)
         local se = sqrt(`mV'[1 , 1])
      }
      else local se "."
    di in smcl in gr %-12s "`v'" " {c |}" /*
		*/ in ye %9.2f `mn' 	/*
		*/ " " %9.2f `sd' 	/*
		*/ %9.2f `se'		/*
		*/ "  "  %9.2f `md' 	/*
		*/ "   " %9.2f `lb' 	/*
		*/ "  " %9.2f `ub'
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

*-------------------------------------
* add correlations & covariances
*-------------------------------------
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
*-------------------------------------
* close save file
*-------------------------------------
   if "`save'" != "" {
      postclose `pf'
   }
   cap tsset `oldt'
   restore
   
cap estimates restore _midas_estimates
end

*-------------------------------------
* Approximate HPD interval
*-------------------------------------
program inla_sumstats_hpd , rclass
   syntax varlist (max = 1 min = 1) [if] [in] [ , alpha(real 95.0) ]
   version 12.1
   
   quietly {
      marksample touse
      local theta = "`varlist'"
      
*--------------------------------
* Initial values based on credible interval
*--------------------------------
      local a = 100 - `alpha'
      local a1 = `a' / 2
      centile `theta'  , centile(`a1' 50 )
      local theta1 = r(c_1)
      local thetam = r(c_2)    
*--------------------------------
* smoothed density of theta in (x,f)
*--------------------------------    
      preserve
      tempvar x f cf tmp
      local n = 1000
      if `n' > _N {
         set obs `n'
      }
      kdensity `theta'  , gen(`x' `f') nograph n(`n')
      gen `cf' = sum(`f')
      su `cf'
      replace `cf' = `cf' / r(max)
      su `x'
      local step = (r(max)-r(min)) / 100
      local xthreshold = 0.001*`step' 
      local athreshold = 0.0001  
*--------------------------------
* Iterate
*--------------------------------   
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
         * area to left of xlow
         inla_sumstats_interp `x' `cf'  , value(`xlow')
         local a1 = r(fvalue)
         * xhigh corresponding to xlow
         inla_sumstats_interp `x' `f' if `x' < `thetam' , value(`xlow')
         local fx = r(fvalue)
         inla_sumstats_interp `f' `x' if `x' > `thetam' , value(`fx') down
         local xhigh = r(fvalue)
         * area to right of xlow
         inla_sumstats_interp `x' `cf'  , value(`xhigh')
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

*-------------------------------------
* Interpolations
*-------------------------------------
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

