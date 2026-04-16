*! midas_mh.ado
*! Bayesian bivariate random–effects meta-analysis of DTA data
*! Author: Ben A. Dwamena (bdwamena@umich.edu)

**********************************************************************
*  Hierarchical logdensity priors for sciwishart and Huang–Wand (HIW)
**********************************************************************

capture program drop midas_sciwishart_sigma_logprior
program define midas_sciwishart_sigma_logprior, rclass
    // Half-t_4(0, 2.5) prior for SD
    args sigma

    local nu = 4
    local s  = 2.5

    if `sigma' <= 0 {
        return scalar lnf = -1e10
        exit
    }

    local z    = 1 + (`sigma'^2 / (`nu'*`s'^2))
    local logp = - ((`nu' + 1)/2)*ln(`z')

    return scalar lnf = `logp'
end

capture program drop midas_sciwishart_pair_logprior
program define midas_sciwishart_pair_logprior, rclass
    // Joint prior for (sigma1, sigma2): sum of independent half-t_4(0,2.5)
    args sigma1 sigma2

    quietly midas_sciwishart_sigma_logprior `sigma1'
    local l1 = r(lnf)

    quietly midas_sciwishart_sigma_logprior `sigma2'
    local l2 = r(lnf)

    return scalar lnf = `l1' + `l2'
end

capture program drop midas_hiwishart_sigma_logprior
program define midas_hiwishart_sigma_logprior, rclass
    // Huang–Wand-style half-t_1(0,25) ~ Cauchy(0,25) on SD
    args sigma

    local A = 25

    if `sigma' <= 0 {
        return scalar lnf = -1e10
        exit
    }

    local z    = 1 + (`sigma'^2 / (`A'^2))
    local logp = - ln(`z')

    return scalar lnf = `logp'
end

capture program drop midas_hiwishart_pair_logprior
program define midas_hiwishart_pair_logprior, rclass
    // Joint prior for (sigma1, sigma2): sum of independent half-Cauchy(0,25)
    args sigma1 sigma2

    quietly midas_hiwishart_sigma_logprior `sigma1'
    local l1 = r(lnf)

    quietly midas_hiwishart_sigma_logprior `sigma2'
    local l2 = r(lnf)

    return scalar lnf = `l1' + `l2'
end


**********************************************************************
*  main program: midas_mh
**********************************************************************

capture program drop midas_mh
program define midas_mh, eclass sortpreserve byable(recall)
    version 17.0

    if _by() {
        local BY "by `_byvars'`_byrc0':"
    }

    if !replay() {

        // ------------------------------------------------------------
        // 1. Syntax and options
        // ------------------------------------------------------------
        #delimit ;
        syntax varlist(min=4 max=4 numeric) [if] [in] ,
            ID(varlist min=1 max=2)
            COVariance(string)
            [ MUPrior(string asis)
              SIGMAPrior(string asis)
              PHIPrior(string asis)
              RHOPrior(string asis)
              LAMDAPrior(string asis)
              CHains(integer 4)
              MCSize(integer 20000)
              BURN(integer 20000)
              THIN(integer 1)
              DOTS(integer 10000)
              HPD
              Level(cilevel)
              SEED(integer 12345)
			  PARallel
			  noHEADer
              noCOEFficients
              noSUMmary
              noFITstats
              HETstats
              HSROC
              REVman
              CONVERGEstats
              * ];
        #delimit cr

        quietly {

            // esample marker BEFORE preserve so it survives restore
            marksample touse
           

            if _by() {
                quietly replace `touse' = 0 if `_byindex' != _byindex()
            }

            tempvar esample
            gen byte `esample' = `touse'

            preserve

            // --------------------------------------------------------
            // Default priors (user-override allowed)
            // --------------------------------------------------------
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
                // default for corrlogits / z: mildly negative correlation
                local rhoprior "uniform(-1,0)"
            }

            // covariance-specific tweaks if user did not override sigmaprior()
            if "`sigmaprior'" == "" & lower("`covariance'")=="sciwishart" {
                // sciwishart: moderately heavy-tailed SDs (kept as Cauchy here
                // but main refinement now via logdensity() block)
                local sigmaprior "cauchy(0,2.5)"
            }
            if "`sigmaprior'" == "" & lower("`covariance'")=="hiwishart" {
                // HIW/Huang–Wand: keep generic here; refinement via logdensity()
                local sigmaprior "cauchy(0,2.5)"
            }

            // --------------------------------------------------------
            // bayesparallel availability check
            // --------------------------------------------------------
            if "`parallel'" != "" {
                capture which bayesparallel
                if _rc {
                    display as error "bayesparallel command not found"
                    display as error ///
                        "try -net install bayesparallel- from the appropriate site"
                    error 111
                }
            }

            // credible interval level
            if `level' < 10 | `level' > 99 {
                di as error "level() must be between 10 and 99"
                exit 198
            }

            // --------------------------------------------------------
            // 2. covariance options
            // --------------------------------------------------------

            local covariance = lower("`covariance'")
            if !inlist("`covariance'","iwishart","cholesky","spherical", ///
                                      "cholefisher","product","sciwishart","hiwishart") {
                di as error "Unsupported covariance(): `covariance'"
                exit 198
            }

            local model "Bivariate Binomial `link'-Normal Random Intercepts Model"

            // --------------------------------------------------------
            // 3. Data setup (tp fp fn tn -> long format for bayesmh)
            // --------------------------------------------------------
            tokenize `varlist'
            local tp `1'
            local fp `2'
            local fn `3'
            local tn `4'

            tempvar sumtp sumfn sumtn sumfp prev
            egen `sumtp' = total(`tp') if `touse'
            egen `sumfn' = total(`fn') if `touse'
            egen `sumtn' = total(`tn') if `touse'
            egen `sumfp' = total(`fp') if `touse'

            global sumtpfn = `sumtp' + `sumfn'
            global sumtnfp = `sumtn' + `sumfp'

            gen `prev' = (`tp' + `fn') / ///
                (`tp' + `tn' + `fn' + `fp') if `touse'
            summarize `prev', meanonly
            local prev    = r(mean)
            local prevmin = r(min)
            local prevmax = r(max)

            // denominators and outcomes
            quietly gen long _midas_denom1 = `tp' + `fn'
            quietly gen long _midas_denom2 = `fp' + `tn'
            quietly gen long _midas_dep1   = `tp'
            quietly gen long _midas_dep2   = `tn'

            // study labels / ids
            egen _midas_studylabel = concat(`id'), p(" ")
            sort _midas_studylabel
            gen _midas_studyid = _n

            tempname varlistmat
            mkmat `tp' `fp' `fn' `tn', mat(`varlistmat') rownames(_midas_studylabel)
            matrix colnames `varlistmat' = tp fp fn tn
            local varlist `varlistmat'
            count if `touse'
            global midas_nobs = r(N)
            ereturn scalar nstudies = $midas_nobs

            // --------------------------------------------------------
            // 3a. Initialization control
            // --------------------------------------------------------
            * 1. Frequentist inits 
			mh_inits0 tp fp fn tn
			tempname b V C
			matrix `b' = r(b)
			matrix `V' = r(V)

			quietly _coef_table, bmatrix(`b') vmatrix(`V')
			matrix `C' = r(table)'

			* Means (centers)
			local mu1      = el(`C', 1, 1)   // muA
			local mu2      = el(`C', 2, 1)   // muB
			local muvar1   = el(`C', 6, 1)   // s2A
			local muvar2   = el(`C', 7, 1)   // s2B
			local mucorr   = el(`C', 5, 1)   // corr
			local lamda    = el(`C', 9, 1)   // lamda
			local zfish    = el(`C', 10, 1)
			local phi      = el(`C', 11, 1)

			* SEs (scales)
			local mu1se    = el(`C', 1, 2)
			local mu2se    = el(`C', 2, 2)
			local muvar1se = el(`C', 6, 2)
			local muvar2se = el(`C', 7, 2)
			local mucorrse = el(`C', 5, 2)
			local lamdase  = el(`C', 9, 2) 
			local zfishse  = el(`C', 10, 2)  
			local phise    = el(`C', 11, 2)

			* 2. Generate chain-specific initialization strings
			if "`covariance'"=="cholefisher" {
			#delimit; 
			mh_inits1, nchains(`chains')                              
			unconstrained(_midas_dep:1._midas_dis_status _midas_dep:2._midas_dis_status)               
			positive(sigma1 sigma2)
			fisherz(z)
			center(_midas_dep:1._midas_dis_status=`mu1' _midas_dep:2._midas_dis_status=`mu2'                              
			sigma1=`muvar1' sigma2=`muvar2' z=`zfish')                                              
			scale(_midas_dep:1._midas_dis_status=`mu1se' _midas_dep:2._midas_dis_status=`mu2se'                            
			sigma1=`muvar1se' sigma2=`muvar2se' z=`zfishse');  
			#delimit cr 
			}
			else if inlist("`covariance'","cholesky","sciwishart","hiwishart"){
			#delimit; 
			mh_inits1, nchains(`chains')                              
			unconstrained(_midas_dep:1._midas_dis_status _midas_dep:2._midas_dis_status)               
			positive(sigma1 sigma2)                        
			corr(corrlogits)                               
			center(                                         
			_midas_dep:1._midas_dis_status=`mu1' _midas_dep:2._midas_dis_status=`mu2'                              
			sigma1=`muvar1' sigma2=`muvar2' corrlogits=`mucorr')                                              
			scale(_midas_dep:1._midas_dis_status=`mu1se' _midas_dep:2._midas_dis_status=`mu2se'                            
			sigma1=`muvar1se' sigma2=`muvar2se' corrlogits=`mucorrse');  
			#delimit cr 
			}
			else if "`covariance'"=="product" {
			#delimit; 
			mh_inits1, nchains(`chains')                              
			unconstrained(_midas_dep:1._midas_dis_status _midas_dep:2._midas_dis_status lamda1)               
			positive(sigma1 sigma2)                                                      
			center(_midas_dep:1._midas_dis_status=`mu1' _midas_dep:2._midas_dis_status=`mu2'                              
			sigma1=`muvar1' sigma2=`muvar2' lamda1=`lamda')                                              
			scale(_midas_dep:1._midas_dis_status=`mu1se' _midas_dep:2._midas_dis_status=`mu2se'                            
			sigma1=`muvar1se' sigma2=`muvar2se' lamda1=`lamdase');  
			#delimit cr
			}
			else if "`covariance'"=="spherical" {
			#delimit; 
			mh_inits1, nchains(`chains')                              
			unconstrained(_midas_dep:1._midas_dis_status _midas_dep:2._midas_dis_status)               
			positive(sigma1 sigma2)
			phi(phi)
			center(_midas_dep:1._midas_dis_status=`mu1' _midas_dep:2._midas_dis_status=`mu2'                              
			sigma1=`muvar1' sigma2=`muvar2' phi=`phi')                                              
			scale(_midas_dep:1._midas_dis_status=`mu1se' _midas_dep:2._midas_dis_status=`mu2se'                            
			sigma1=`muvar1se' sigma2=`muvar2se' phi=`phise');  
			#delimit cr
			} 
			else if "`covariance'"=="iwishart" {
			#delimit; 
			mh_inits1, nchains(`chains')                              
			unconstrained(_midas_dep:1._midas_dis_status _midas_dep:2._midas_dis_status)               
			center(_midas_dep:1._midas_dis_status=`mu1' _midas_dep:2._midas_dis_status=`mu2')                                              
			scale(_midas_dep:1._midas_dis_status=`mu1se' _midas_dep:2._midas_dis_status=`mu2se');  
			#delimit cr
			}
			local inits `r(init_all)'	

            // --------------------------------------------------------
            // 3b. Drop to long-format data for bayesmh
            // --------------------------------------------------------
            keep _midas_denom1 _midas_denom2 ///
                 _midas_dep1   _midas_dep2   ///
                 _midas_studyid _midas_studylabel

            quietly save "C:/ado/personal/midas_input_data.dta", replace

            // average denominators
            gen double _midas_invnum1 = 1/_midas_denom1
            summarize _midas_invnum1, meanonly
            global avnum1 = r(mean)

            gen double _midas_invnum2 = 1/_midas_denom2
            summarize _midas_invnum2, meanonly
            global avnum2 = r(mean)

            // reshape to long for bayesmh
            reshape long _midas_dep _midas_denom, i(_midas_studyid) j(_midas_dis_status)

            fvset base none _midas_dis_status _midas_studyid

            // --------------------------------------------------------
            // 4. Likelihood and priors for bayesmh
            // --------------------------------------------------------
            #delimit ;
            local parameters_likelihood : di 
                "bayesmh _midas_dep " 
                "1._midas_dis_status#U1[_midas_studyid] " 
                "2._midas_dis_status#U2[_midas_studyid] " 
                "1._midas_dis_status 2._midas_dis_status, " 
                "likelihood(binlogit(_midas_denom)) noconstant";
            #delimit cr

            // Priors / hyperpriors and parameter blocks
            if ("`covariance'" == "iwishart") {
                #delimit ;
                local priors_blocks : di 
                    "prior({U1 U2}, mvn0(2, {Sigma, m})) " 
                    "prior({Sigma, m}, iwishart(2,3,I(2))) " 
                    "prior({_midas_dep:},`muprior' split)";
                #delimit cr
            }
            else if ("`covariance'" == "product") {
                #delimit ;
                local priors_blocks : di ///
                    "prior({U1 U2}, mvn0(2, (({sigma1}^2, ({lamda1}*{sigma1}^2) \ " 
                    "({lamda1}*{sigma1}^2), ({sigma2}^2+{lamda1}^2*{sigma1}^2))))) " 
                    "prior({sigma1 sigma2}, `sigmaprior' split) " 
                    "prior({lamda1},`lamdaprior') " 
                    "prior({_midas_dep:},`muprior' split) " 
                    "block({sigma1 sigma2}, split) block({_midas_dep:}, split) " 
                    "block({U1}, split) block({U2}, split)";
                #delimit cr
            }
            else if ("`covariance'" == "spherical") {
                #delimit ;
                local priors_blocks : di 
                    "prior({U1 U2}, mvn0(2, (diag(({sigma1}, {sigma2}))*(1, " 
                    "cos({phi}) \ " 
                    "cos({phi}), 1)*diag(({sigma1}, {sigma2}))))) " 
                    "prior({sigma1} {sigma2}, `sigmaprior' split) " 
                    "prior({phi}, `phiprior') " 
                    "prior({_midas_dep:},`muprior' split) " 
                    "block({sigma1} {sigma2}, split) block({_midas_dep:}, split) " 
                    "block({U1}, split) block({U2}, split)";
                #delimit cr
            }
            else if ("`covariance'" == "cholesky") {
                #delimit ;
                local priors_blocks : di 
                    "prior({U1 U2}, mvn0(2, (diag(({sigma1}, {sigma2}))*((1, " 
                    "{corrlogits} \ " 
                    "{corrlogits}, 1))*(diag(({sigma1}, {sigma2})))))) " 
                    "prior({sigma2} {sigma1}, `sigmaprior' split) " 
                    "prior({corrlogits}, `rhoprior') " 
                    "prior({_midas_dep:},`muprior' split) " 
                    "block({sigma1 sigma2}, split) block({_midas_dep:}, split) " 
                    "block({U1}, split) block({U2}, split)";
                #delimit cr
            }
            else if ("`covariance'" == "cholefisher") {
                #delimit ;
                local priors_blocks : di 
                    "prior({U1 U2}, mvn0(2, (diag(({sigma1}, {sigma2}))*(1, " 
                    "(2*invlogit({z})-1) \ " ///
                    "(2*invlogit({z})-1), 1)*diag(({sigma1}, {sigma2})))))" 
                    "prior({sigma1} {sigma2}, `sigmaprior' split) " 
                    "prior({z},`rhoprior') " 
                    "prior({_midas_dep:},`muprior' split) " 
                    "block({sigma1 sigma2}, split) block({_midas_dep:}, split) " 
                    "block({U1}, split) block({U2}, split)";
                #delimit cr
            }
            else if ("`covariance'" == "sciwishart") {
                // Scaled inverse-Wishart: Cholesky parametrization, heavy-tailed SDs via logdensity()
				tempname sigma1 sigma2 
				scalar define `sigma1'=1.5
				scalar define `sigma2'=1.5
				midas_sciwishart_pair_logprior `sigma1' `sigma2'
				local scilp = r(lnf)
                #delimit ;
                local priors_blocks : di 
                    "prior({U1 U2}, mvn0(2, (diag(({sigma1}, {sigma2}))*((1, " 
                    "{corrlogits} \ " 
                    "{corrlogits}, 1))*(diag(({sigma1}, {sigma2}))))))" 
                    "prior({sigma1 sigma2}, logdensity(`scilp')) " 
                    "prior({corrlogits}, `rhoprior') " 
                    "prior({_midas_dep:},`muprior' split) " 
                    "block({sigma1 sigma2}, split) block({_midas_dep:}, split) " 
                    "block({U1}, split) block({U2}, split)";
                #delimit cr
            }
            else if ("`covariance'" == "hiwishart") {
                // Huang–Wand hierarchical (Cholesky parameterization) via logdensity()
				tempname sigma1 sigma2 
				scalar define `sigma1'=1.5
				scalar define `sigma2'=1.5
				midas_hiwishart_pair_logprior `sigma1' `sigma2'
				local hiwlp = r(lnf)
                #delimit ;
                local priors_blocks : di 
                    "prior({U1 U2}, mvn0(2, (diag(({sigma1}, {sigma2}))*((1, " 
                    "{corrlogits} \ " 
                    "{corrlogits}, 1))*(diag(({sigma1}, {sigma2}))))))" 
                    "prior({sigma1 sigma2}, logdensity(`hiwlp')) " 
                    "prior({corrlogits}, `rhoprior') " 
                    "prior({_midas_dep:},`muprior' split) " 
                    "block({sigma1 sigma2}, split) block({_midas_dep:}, split) " 
                    "block({U1}, split) block({U2}, split)";
                #delimit cr
            }

            // --------------------------------------------------------
            // 5. MCMC settings
            // --------------------------------------------------------
            #delimit ;
            local mcmc_settings : di ///
                "burnin(`burn') mcmcsize(`mcsize') dots(`dots') " 
                "rseed(`seed') thin(`thin') nchains(`chains') ";
            #delimit cr

            // --------------------------------------------------------
            // 6. Fit model via bayesmh or bayesparallel
            // --------------------------------------------------------
            if "`parallel'" == "" {
                noisily di as text "Simulating " as result `chains' as text ///
                    " sequential chains .............."

                #delimit ;
                `parameters_likelihood'
                `priors_blocks'
                `mcmc_settings'
				`inits'
                saving("C:/ado/personal/midas_output_data.dta", replace);
                #delimit cr
            }
            else {
                noisily di as text "Simulating " as result `chains' as text ///
                    " parallel chains ................."

                #delimit ;
               bayesparallel, nproc(`chains'): ///
                    `parameters_likelihood'
                    `priors_blocks'
                    `mcmc_settings'
					`inits';
                #delimit cr
				bayesmh, saving("C:/ado/personal/midas_output_data.dta", replace)
            }

            // --------------------------------------------------------
            // 7. Post-processing: call helper routines and post results
            // --------------------------------------------------------
            tempname modfit residuals reffects pred midas_sim_data
            tempname V b Vsum bsum bsummed bsumsd bhessmed bhesssd
            tempname Vhsroc bhsroc Vhess bhess VIsquared bIsquared
            tempname bhsrocmed bhsrocsd bIsqmed bIsqsd bmed bsd studywgts

            // user-defined helper programs (assumed installed)
            mh_fit
            matrix `modfit'    = r(midasmh_fit)
            matrix `residuals' = r(residuals)
            matrix `reffects'  = r(reffects)
            local logscore     = r(logscore)

            mh_weights, covmat(`covariance')
            matrix `studywgts' = r(mh_weights)
            matrix `pred'      = r(pred)

            mh_matrices, covmat(`covariance')
			local midasfile = r(midasfile)
            local covmus = r(covmus)
            matrix `V' = r(V)
            matrix `b' = r(b)

            matrix `Vsum' = r(Vsum)
            matrix `bsum' = r(bsum)

            matrix `Vhsroc' = r(Vhsroc)
            matrix `bhsroc' = r(bhsroc)

            matrix `VIsquared' = r(VIsq)
            matrix `bIsquared' = r(bIsq)

            matrix `bhess' = r(bhess)
            matrix `Vhess' = r(Vhess)

            matrix `bsummed' = r(bsummed)
            matrix `bsumsd'  = r(bsumsd)

            matrix `bhsrocmed' = r(bhsrocmed)
            matrix `bhsrocsd'  = r(bhsrocsd)

            matrix `bIsqmed' = r(bIsqmed)
            matrix `bIsqsd'  = r(bIsqsd)

            matrix `bhessmed' = r(bhessmed)
            matrix `bhesssd'  = r(bhesssd)

            matrix `bmed' = r(bmed)
            matrix `bsd'  = r(bsd)

            mh_ppp
            local loglll = r(loglll)
            local dbar   = r(dbar)
            local dhat   = r(dhat)
            local pD     = r(pd)
            local DIC    = r(dic)
            local pDW    = r(p_waic)
            local WAIC   = r(waic)

            tempname converge
            mh_converge, covmat(`covariance')
            matrix `converge' = r(converge)
            local maxgrubin   = r(rmax)

            // post results to e()
            ereturn post `b' `V'

            restore

            // esample repost from preserved marker
            ereturn repost, esample(`esample')

            // store matrices
            foreach M in varlist Vsum bsum Vhsroc bhsroc Vhess VIsquared ///
                        bIsquared studywgts pred residuals reffects modfit ///
                        converge {
                ereturn matrix `M' = ``M'', copy
            }

            foreach M in bhess Vhess bsummed bsumsd bhsrocmed bhsrocsd ///
                        bIsqmed bIsqsd bhessmed bhesssd bmed bsd ///
                         {
                ereturn matrix `M' = ``M'', copy
            }

            // also pass filename for replay
            ereturn local midas_filename "`midasfile'"

            ereturn scalar loglll    = `loglll'
            ereturn scalar dbar      = `dbar'
            ereturn scalar dhat      = `dhat'
            ereturn scalar pD        = `pD'
            ereturn scalar DIC       = `DIC'
            ereturn scalar pDW       = `pDW'
            ereturn scalar WAIC      = `WAIC'
            ereturn scalar logscore  = `logscore'
            ereturn scalar k         = 5
            ereturn scalar kf        = 2
            ereturn scalar kr        = 3
            ereturn scalar mgrubin   = `maxgrubin'
            ereturn scalar nburn     = `burn'
            ereturn scalar nchains   = `chains'
            ereturn scalar nthin     = `thin'
            ereturn scalar mcmcsize  = `mcsize'
            ereturn scalar N         = $midas_nobs
            ereturn scalar Ndis      = $sumtpfn
            ereturn scalar Nnodis    = $sumtnfp
            ereturn scalar covmus    = `covmus'
            ereturn scalar prev      = `prev'
            ereturn scalar prevmin   = `prevmin'
            ereturn scalar prevmax   = `prevmax'
            ereturn scalar level     = `level'
            ereturn scalar avgNse    = $avnum1
            ereturn scalar avgNsp    = $avnum2
            ereturn local  predict   "_no_predict"

            ereturn local title      "Meta-analysis of Diagnostic Test Accuracy Data"
            ereturn local estmethod  "Markov Chain Monte Carlo Simulation"
            ereturn local model      `model'

            if "`covariance'" == "iwishart" {
                ereturn local covprior "Inverse Wishart Formulation"
            }
            else if "`covariance'" == "cholesky"  {
                ereturn local covprior "Cholesky Decomposition"
            }
            else if "`covariance'" == "spherical" {
                ereturn local covprior "Spherical Decomposition"
            }
            else if "`covariance'" == "cholefisher" {
                ereturn local covprior "Cholesky/Fisher Z Transformation"
            }
            else if "`covariance'" == "product" {
                ereturn local covprior "Product-Normal Formulation"
            }
            else if "`covariance'" == "sciwishart" {
                ereturn local covprior "Scaled Inverse-Wishart (Cholesky parameterization)"
            }
            else if "`covariance'" == "hiwishart" {
                ereturn local covprior "Huang–Wand hierarchical covariance prior"
            }

            ereturn local fam   "Binomial"
            ereturn local link  "logit"
            ereturn local cmd   "midas_mh"
            ereturn local cmdline "midas_mh `0'"
            ereturn local package "midas"
        }
        // Display results after estimation (invoke replay logic)
        nois midas_mh, level(`level') `header' `coefficients' `summary' ///
            `fitstats' `hetstats' `hsroc' `convergestats' `revman'
    }
    else {
        // ------------------------------------------------------------
        // Replay
        // ------------------------------------------------------------

        if "`e(cmd)'" != "midas_mh" {
            error 301
        }
        if _by() error 190

        #delimit ;
        syntax [if] [in] , 
            [Level(cilevel) 
            noHEADer 
			noCOEFficients 
            noSUMmary 
			HSROC 
			noFITstats 
			HETstats 
            CONVERGEstats
			REVman
			MODdiag
            * ];
        #delimit cr

        local level = cond(missing(`level'), e(level), `level')

        if missing("`header'") {
            di ""
            di in smcl as text "{hline 76}"
            di as txt _n e(title) _n
            di in smcl as text "{hline 76}"
            di ""
            di as txt "Model: "              " " in yellow e(model)
            di as txt "Estimation: "         " " in yellow e(estmethod)
            di as txt "Family: "             " " in yellow e(fam)
            di as txt "Link: "               " " in yellow e(link)
            di as txt "Covariance prior: "   " " in yellow e(covprior)
            di ""
            di as txt "Number of studies" _col(60) "= " ///
                _col(64) as result %5.0f e(N)
            di as txt "Reference-positive units" _col(60) "= " ///
                _col(64) as result %5.0f e(Ndis)
            di as txt "Reference-negative units" _col(60) "= " ///
                _col(64) as result %5.0f e(Nnodis)
            di as txt "Pretest probability of disease" _col(60) "= " ///
                _col(64) as result %5.2f e(prev)
            di ""
        }

        nois di ""
        nois di ""
        if missing("`fitstats'") {
            nois di in smcl as text "{hline 76}"
            nois di ""
            nois di as text  "Log-Likelihood" _col(60) "= " _col(64) as res %7.2f  e(loglll)
            nois di ""
            nois di as text  "Mean of the Deviance" _col(60) "= " _col(64) as res %7.2f  e(dbar)
            nois di ""
            nois di as text  "Deviance of the Mean" _col(60) "= " _col(64) as res %7.2f  e(dhat)
            nois di ""
            nois di as text  "Deviance Information Criterion" _col(60) "= " _col(64) as res %7.2f  e(DIC)
            nois di ""
            nois di as text  "Watanabe-Akaike Information Criterion" _col(60) "= " _col(64) as res %7.2f  e(WAIC)
            nois di ""
            nois di as text  "Cross-validated Logarithmic Score" _col(60) "= " _col(64) as res %7.2f  e(logscore)
            nois di ""
            nois di as txt "Maximum Gelman–Rubin Convergence Statistic" _col(60) "=" _col(62) as result %9.4f e(mgrubin)
            nois di ""
        }
        nois di ""
        nois di ""
        nois di ""
        if  missing("`coefficients'") {
            preserve
            use "`e(midas_filename)'", clear
            nois di  in smcl in gr  _newline(1)  "{hilite: Fixed and Random Effects Estimates:}"

            if "`hpd'" == ""  {
                nois mh_sumstats  logitsen logitspe varlogitsen varlogitspe covvars corrvars
            }
            else {
                nois mh_sumstats  logitsen logitspe varlogitsen varlogitspe covvars corrvars, hpd
            }
            restore
        }

        if  missing("`summary'") {
            preserve
            use "`e(midas_filename)'", clear

            gen double sen =invlogit(logitsen)
            gen double spe = invlogit(logitspe)
            gen double lrp = sen/(1-spe)
            gen double lrn =(1-sen)/spe
            gen double ldor = logitsen + logitspe
            gen double dor = exp(ldor)
            nois di in smcl in gr  _newline(1)   "{hilite: Summary Test Performance Estimates:}"
            if "`hpd'" == ""  {
                nois mh_sumstats  sen spe lrp lrn dor ldor
            }
            else  {
                nois mh_sumstats  sen spe lrp lrn dor ldor, hpd
            }
            restore
        }
        if "`hetstats'" != "" {
            cap preserve
            use "`e(midas_filename)'", clear
            qui gen I2sen = .
            qui gen I2spe = .
            qui gen I2biv = .
            forvalues i = 1/$midas_nobs {
                mat Vblogit`i'=(varlogitsen[`i'] , covvars[`i'] \ covvars[`i'] , varlogitspe[`i'])
                qui replace I2sen = varlogitsen[`i']/(varlogitsen[`i']+  ///
                    ($avnum1*(exp(((varlogitsen[`i'])/2)+logitsen[`i'])+ ///
                    exp(((varlogitsen[`i'])/2)-logitsen[`i'])+2))) in `i'

                qui replace I2spe = varlogitspe[`i']/(varlogitspe[`i']+ ///
                    ($avnum2*(exp(((varlogitspe[`i'])/2)+  ///
                    logitspe[`i'])+exp(((varlogitspe[`i'])/2)-logitspe[`i'])+2))) in `i'

                qui replace  I2biv =  sqrt(exp(log(det(Vblogit`i'))))/(sqrt(exp(log(det(Vblogit`i'))))+ ///
                    sqrt(($avnum1*(exp(((varlogitsen[`i'])/2)+logitsen[`i'])+ ///
                    exp(((varlogitsen[`i'])/2)-logitsen[`i'])+2))* ///
                    ($avnum2*(exp(((varlogitspe[`i'])/2)+logitspe[`i'])+ ///
                    exp(((varlogitspe[`i'])/2)-logitspe[`i'])+2)))) in `i'
            }
            nois di in smcl in gr  _newline(1) "{hilite: Heterogeneity/Inconsistency Statistics:}"
            if "`hpd'" == ""  {
                nois mh_sumstats I2sen I2spe I2biv
            }
            else  {
                nois mh_sumstats I2sen I2spe I2biv, hpd
            }
            cap restore
        }
        nois di ""
        nois di ""
        if "`hsroc'" != "" {
            cap preserve
            use "`e(midas_filename)'", clear
            gen double Alpha = (varlogitsen/varlogitspe)^(0.25)*logitspe+(varlogitspe/varlogitsen)^(0.25)*logitsen
            gen double Theta = 0.5*((varlogitsen/varlogitspe)^(0.25)*logitspe-(varlogitspe/varlogitsen)^(0.25)*logitsen)
            gen double beta = 0.5*log(varlogitsen/varlogitspe)
            gen double s2alpha = 2*(sqrt(varlogitspe*varlogitsen)+covvars)
            gen double s2theta = 0.5*(sqrt(varlogitspe*varlogitsen)-covvars)
            nois di in smcl in gr  _newline(1) "{hilite: Derived HSROC Model Estimates:}"
            if "`hpd'" == ""  {
                nois mh_sumstats Alpha Theta beta s2alpha s2theta
            }
            else {
                nois mh_sumstats Alpha Theta beta s2alpha s2theta, hpd
            }
            cap restore
        }

        if "`convergestats'" != ""    {
            nois di in smcl in gr  _newline(1) "{hilite: Convergence Statistics:}"
            tempname converge
            mat `converge' = e(converge)
            nois _matrix_table `converge', format(%7.2f  %7.0f)
            nois di ""
            nois di ""
            nois di ""
        }

        if "`revman'" != "" {
            tempname bcoef Vcoef coef2
            mat `bcoef'=e(b)
            mat `Vcoef'=e(V)
            local cov01=`Vcoef'[1,2]
            qui _coef_table , bmatrix(`bcoef')  vmatrix(`Vcoef')
            mat `coef2'=r(table)'
            local  sn = `coef2'[1,1]
            local  snse = `coef2'[1,2]
            local  sp = `coef2'[2,1]
            local  spse = `coef2'[2,2]
            local reffs1 = `coef2'[3,1]
            local reffs2 = `coef2'[4,1]
            local covlogit = `coef2'[5,1]
            local corrlogit = `coef2'[6,1]
            nois di in smcl as text "{hline 76}"
            nois di  in smcl in gr  _newline(1)  "{hilite: Required Information for Export into RevMan}"
            nois di ""
            nois di ""
            nois di ""
            nois di  in smcl in blue  "{title: Parameters for SROC Curve}"
            nois di ""
            nois di as text "{hilite:E(logitse)}" as text ": Expected mean logit sensitivity" _col(66) " =   " _col(70) as res %5.4f `sn'
            nois di ""
            nois di as text "{hilite:E(logitsp)}" as text ": Expected mean logit specificity" _col(66) " =   " _col(70) as res %5.4f `sp'
            nois di ""
            nois di as text  "{hilite:Var(logitse)}" as text ": Between-study variance of logit sensitivity" _col(66) " =   " _col(70) as res %5.4f `reffs1'
            nois di ""
            nois di as text  "{hilite:Var(logitsp)}" as text ": Between-study variance of logit specificity" _col(66) " =   " _col(70) as res %5.4f `reffs2'
            nois di ""
            nois di as text  "{hilite:Cov(logits)}" as text ": Between-study Covariance" _col(66) " =   " _col(70) as res %5.4f `covlogit'
            nois di ""
            nois di as text  "{hilite:Corr(logits)}" as text": Between-study Correlation" _col(66) " =  " _col(70) as res %5.4f `corrlogit'
            nois di ""
            nois di ""
            nois di ""
            nois di  in smcl in blue "{title: Parameters for Confidence and Prediction Regions:}"
            nois di ""
            nois di as text "{hilite:SE(E(logitse))}" as text ": Standard error of expected mean logit sensitivity" _col(66) " =   " _col(70) as res %5.4f `snse'
            nois di ""
            nois di as text  "{hilite:SE(E(logitsp))}" as text ": Standard error of expected mean logit specificity" _col(66) " =   " _col(70) as res %5.4f `spse'
            nois di ""
            nois di  as text "{hilite:Cov(Es)}" as text ": Covariance between mean logit sensitivity and specificity" _col(66) " =  " _col(70) as res %5.4f `cov01'
            nois di ""
            nois di as text  "{hilite:Studies}" as text ": Number of Studies included in meta-analysis" _col(66) " =   " _col(70) as res %2.0f e(N)
            nois di ""
        }
        if "`moddiag'" != "" {   
            preserve
            clear
            mat bb=e(modfit)
            qui svmat bb, names(col)
            foreach modlab in 0.5 1 1.5 2.0 2.5 3.0 3.5 4.0 {
                local modlabpts `"`modlabpts' `=`modlab' ' 0 "`modlab'" "'
            }
            qui gen obs=_n
            #delimit;
            tw (scatter pdi dresidi)(scatter pdi dresidi if dresidi <2.0 | dresidi > -2.0,
            mlw(medthin) mfc(green) mlc(black) msize(*1.5) ms(O))
            (scatter pdi dresidi if dresidi >2.0 | dresidi < -2.0, mlw(medthin)
            mfc(cranberry) mlc(black) msize(*1.5) ms(O))
            (scatter pdi dresidi if dresidi > 2.0 | dresidi < -2.0, ms(i) mlabp(0)
            mlabel(obs) mlabs(*.5) mlabc(black))
            (function y=1-x^2, range(-1 1) lcolor(green))(function y=4-x^2, range(-2 2) lcolor(cranberry))
            (scatteri `modlabpts' (7), msymbol(+) mcolor(black) mlabcolor(black)
            mlabsize(small)), legend(off)  xti("Deviance Residual") yti("Leverage ") xlab(-5(1)5)
            ylab(none) yticks(none) /*ysc(noline)*/  xline(0, lcolor(black)) plotr(m(zero));
            #delimit cr
            restore
        }

    }

end


**********************************************************************
*  Helper: mh_weights
**********************************************************************

capture program drop mh_weights
program define mh_weights, rclass sortpreserve
version 16.1
syntax , COVmat(string)

if (`"`e(cmd)'"' != "bayesmh" & `"`e(prefix)'"' != "bayes") {
    di as err "last estimates not found"
    exit 301
}
cap preserve
postutil clear
tempname Xmat XTmat Zmat ZZmat Amat Bmat Gmat predfile
tempname Vmat invmat fish varb pred
tempvar pred1 pred2 pred eta1 eta2 eta idvar groupvar dep invn varp
tempfile predresults

*--- Build exprlist for single bayesstats summary call across all studies ---*
local exprlist ""
forvalues i = 1/$midas_nobs {
    if `i' == 1 {
        local term "(P1_1: invlogit({_midas_dep:1bn._midas_dis_status} + {U1[_midas_studyid]:1})) (P2_1: invlogit({_midas_dep:2._midas_dis_status} + {U2[_midas_studyid]:1})) (P3_1: ({_midas_dep:1bn._midas_dis_status} + {U1[_midas_studyid]:1})) (P4_1: ({_midas_dep:2._midas_dis_status} + {U2[_midas_studyid]:1}))"
    }
    else {
        local term "(P1_`i': invlogit({_midas_dep:1bn._midas_dis_status} + {U1[_midas_studyid]:`i'})) (P2_`i': invlogit({_midas_dep:2._midas_dis_status} + {U2[_midas_studyid]:`i'})) (P3_`i': ({_midas_dep:1bn._midas_dis_status} + {U1[_midas_studyid]:`i'})) (P4_`i': ({_midas_dep:2._midas_dis_status} + {U2[_midas_studyid]:`i'}))"
    }
    local exprlist "`exprlist' `term'"
}
qui bayesstats summary `exprlist'
tempname summary_all
matrix `summary_all' = r(summary)

postfile `predfile' `pred'1 `pred'2 `eta'1 `eta'2 using `predresults', replace
forvalues i = 1/$midas_nobs {
    local r1 = (`i'-1)*4 + 1
    local r2 = (`i'-1)*4 + 2
    local r3 = (`i'-1)*4 + 3
    local r4 = (`i'-1)*4 + 4
    post `predfile' (`summary_all'[`r1',4]) (`summary_all'[`r2',4]) (`summary_all'[`r3',4]) (`summary_all'[`r4',4])
}
postclose `predfile'
postutil clear
use `predresults', clear

qui merge 1:1 _n using "C:/ado/personal/midas_input_data.dta", nogen
qui sort _midas_studylabel

qui gen double `pred1' =`pred'1
qui gen double `pred2' =`pred'2
qui gen double `eta1' = `eta'1
qui gen double `eta2' = `eta'2
mkmat `pred1' `pred2' `eta1' `eta2', matrix(`pred') rownames(_midas_studylabel)
matname `pred' pred1 pred2 eta1 eta2, columns(.) explicit
return matrix pred = `pred', copy

gen `idvar' =_n
qui reshape long `pred' `eta' _midas_dep _midas_denom, i(`idvar') j(`groupvar')
qui tab `groupvar', gen(`dep')

tempname Sigma
if "`covmat'" == "iwishart" { // Inverse iwishart Formulation
    mat `Sigma' = (e(mean)[1,3], e(mean)[1,4] \ e(mean)[1,4], e(mean)[1,5])
}
else if "`covmat'" == "product" { // Product Normal Formulation
    mat `Sigma' = (e(mean)[1,4]^2, e(mean)[1,3]*e(mean)[1,4]^2 \ ///
                   e(mean)[1,3]*e(mean)[1,4]^2, (e(mean)[1,5]^2 + e(mean)[1,4]^2*e(mean)[1,3]*e(mean)[1,3]))
}
else if "`covmat'" == "spherical" { // Spherical Decomposition
    mat `Sigma' = (e(mean)[1,4]^2, cos(e(mean)[1,3])*e(mean)[1,4]*e(mean)[1,5] \ ///
                   cos(e(mean)[1,3])*e(mean)[1,4]*e(mean)[1,5] , e(mean)[1,5]^2)
}
else if inlist("`covmat'","cholesky","sciwishart","hiwishart") { // Cholesky-family
    mat `Sigma' = (e(mean)[1,4]^2, e(mean)[1,3]*e(mean)[1,4]*e(mean)[1,5] \ ///
                   e(mean)[1,3]*e(mean)[1,4]*e(mean)[1,5], e(mean)[1,5]^2)
}
else if "`covmat'" == "cholefisher" { // Cholesky/Fisher Transformation
    mat `Sigma' = (e(mean)[1,3]^2,  (2*invlogit(e(mean)[1,5])-1)*e(mean)[1,3]*e(mean)[1,4] \ ///
                   (2*invlogit(e(mean)[1,5])-1)*e(mean)[1,3]*e(mean)[1,4], e(mean)[1,4]^2)
}

// create the fixed effect design matrix
mkmat `dep'1 `dep'2, mat(`Xmat')

// transpose the design matrix
mat `XTmat' = `Xmat''

// create the random effects design matrix
gen double `invn' = 1/_midas_denom
mkmat `invn', mat(`Amat')
mat `Amat' = diag(`Amat')

// Bernoulli variance
gen double `varp' = ((`pred')*(1-`pred'))
mkmat `varp', mat(`Bmat')
mat `Bmat' = diag(`Bmat')

// G matrix containing variances of the random effects
mat `Zmat' = I(_N)
mat `ZZmat' = I(0.5*_N)
mat `Gmat' =`ZZmat'#`Sigma'

// within-trial, between-trial, and total variance matrix for observations
mat `Vmat' = (`Zmat'*`Gmat'*`Zmat'') + (`Amat'*syminv(`Bmat'))

// invert V
mat `invmat' = invsym(`Vmat')

// Fisher information matrix
mat `fish' = `XTmat'*`invmat'*`Xmat'

// invert Fisher information
mat `varb' = invsym(`fish')

// Loop over studies to obtain trial-specific percentage weights
qui forvalues i = 1/$midas_nobs {
    mat `Vmat'`i' = `Vmat'

    // Replace trial i so that it has near-zero information
    mat `Vmat'`i'[(`i'*2)-1,(`i'*2)-1] = 1000000000
    mat `Vmat'`i'[(`i'*2)-1,`i'*2] = 0
    mat `Vmat'`i'[`i'*2,(`i'*2)-1] = 0
    mat `Vmat'`i'[`i'*2,`i'*2] = 1000000000

    // recalculate matrices when trial i removed
    mat `invmat'`i' = invsym(`Vmat'`i')
    mat `fish'`i'   = `XTmat'*`invmat'`i'*`Xmat'
    mat `fish'`i'_`i' = `fish' - `fish'`i'

    mat weight`i' = `varb'*`fish'`i'_`i'*`varb'

    // percentage weight for sensitivity
    mat pctwgt`i'sens = 100*(weight`i'[1,1]/`varb'[1,1])

    // percentage weight for specificity
    mat pctwgt`i'spec = 100*(weight`i'[2,2]/`varb'[2,2])

    // overall bivariate percentage weight
    scalar wgt`i' = 100*trace(weight`i')/trace(`varb')
}

// Save the percentage weights to matrix
qui keep `idvar' `groupvar' `pred' `eta' _midas_dep _midas_denom _midas_studylabel _midas_studyid
qui reshape wide
tempvar senwgt spewgt bivwgt
tempname studywgts
nois di ""
nois di ""
qui gen double `senwgt' =.
qui gen double `spewgt' =.
qui gen double `bivwgt' =.
qui forvalues i = 1/$midas_nobs {
    qui replace `senwgt' = pctwgt`i'sens[1,1]    in `i'
    qui replace `spewgt' = pctwgt`i'spec[1,1]    in `i'
    qui replace `bivwgt' = wgt`i'                in `i'
}
mkmat `senwgt' `spewgt' `bivwgt', matrix(`studywgts') rownames(_midas_studylabel)
matname `studywgts' senwgt spewgt bivwgt, columns(.) explicit

return matrix mh_weights = `studywgts', copy

cap restore

end


**********************************************************************
*  Helper: mh_fit
**********************************************************************

capture program drop mh_fit
program define mh_fit, rclass sortpreserve
version 16.1
syntax [, TITle  FORMAT(string asis) ]

if (`"`e(cmd)'"' != "bayesmh" & `"`e(prefix)'"' != "bayes") {
    di as err "last estimates not found"
    exit 301
}

cap preserve

use "`e(filename)'", clear

tempvar mulogitsen mulogitspe relogitsen relogitspe idd nkldi
tempvar xbi  pobs1 pobs2 phati yhati ytilde explike loglike meanlike
tempvar ptilde dbar dhat dici pdi dresid dresidi sign scaledr
tempvar deviance dbari dhati cpoi logscore kldi pkldi sstag
tempvar randeff serandeff
tempname  midasestimates residuals reffects

qui keep eq*

rename eq1_p1 `mulogitsen'
rename eq1_p2 `mulogitspe'

forvalues junk=1/$midas_nobs {
    rename eq2_p`junk' `relogitsen'`junk'
    rename eq3_p`junk' `relogitspe'`junk'
}
drop eq*

gen `idd'= _n

qui reshape long `relogitsen' `relogitspe', i(`idd') j(_midas_studyid)
gen double `xbi'1 = `mulogitsen' + `relogitsen'
gen double `xbi'2 = `mulogitspe' + `relogitspe'

qui merge m:1 _midas_studyid using "C:/ado/personal/midas_input_data.dta", nogen

gen double `phati'1 = invlogit(`xbi'1)
gen double `phati'2 = invlogit(`xbi'2)

qui bys _midas_studylabel : egen double `ptilde'1 = mean(`phati'1)
qui bys _midas_studylabel : egen double `ptilde'2 = mean(`phati'2)

gen double `yhati'1 = _midas_denom1*`phati'1
gen double `yhati'2 = _midas_denom2*`phati'2

gen double `ytilde'1 = _midas_denom1*`ptilde'1
gen double `ytilde'2 = _midas_denom2*`ptilde'2

qui {
#delimit;
gen double `dbari'1 = 
cond(_midas_dep1 >0 & _midas_dep1 < _midas_denom1,
2*_midas_dep1*ln(_midas_dep1/`yhati'1) + 2*(_midas_denom1-_midas_dep1)*ln((_midas_denom1-_midas_dep1)/(_midas_denom1-`yhati'1)),
cond(_midas_dep1==0, 2*_midas_denom1*ln(_midas_denom1/(_midas_denom1-`yhati'1)), 2*_midas_dep1*ln(_midas_dep1/`yhati'1)));
#delimit cr

#delimit;
gen double `dbari'2 = 
cond(_midas_dep2 >0 & _midas_dep2 < _midas_denom2,
2*_midas_dep2*ln(_midas_dep2/`yhati'2) + 2*(_midas_denom2-_midas_dep2)*ln((_midas_denom2-_midas_dep2)/(_midas_denom2-`yhati'2)),
cond(_midas_dep2==0, 2*_midas_denom2*ln(_midas_denom2/(_midas_denom2-`yhati'2)), 2*_midas_dep2*ln(_midas_dep2/`yhati'2)));
#delimit cr
}

qui {
#delimit;
gen double `dhati'1 = 
cond(_midas_dep1 >0 & _midas_dep1 < _midas_denom1,
2*_midas_dep1*ln(_midas_dep1/`ytilde'1) + 2*(_midas_denom1-_midas_dep1)*ln((_midas_denom1-_midas_dep1)/(_midas_denom1-`ytilde'1)),
cond(_midas_dep1==0, 2*_midas_denom1*ln(_midas_denom1/(_midas_denom1-`ytilde'1)), 2*_midas_dep1*ln(_midas_dep1/`ytilde'1)));
#delimit cr

#delimit;
gen double `dhati'2 = 
cond(_midas_dep2 >0 & _midas_dep2 < _midas_denom2,
2*_midas_dep2*ln(_midas_dep2/`ytilde'2) + 2*(_midas_denom2-_midas_dep2)*ln((_midas_denom2-_midas_dep2)/(_midas_denom2-`ytilde'2)),
cond(_midas_dep2==0, 2*_midas_denom2*ln(_midas_denom2/(_midas_denom2-`ytilde'2)), 2*_midas_dep2*ln(_midas_dep2/`ytilde'2)));
#delimit cr
}

gen double `pobs1' = _midas_dep1/_midas_denom1
gen double `pobs2' = _midas_dep2/_midas_denom2

gen `sign'1= (`yhati'1-_midas_dep1)/abs(`yhati'1-_midas_dep1)
gen `sign'2= (`yhati'2-_midas_dep2)/abs(`yhati'2-_midas_dep2)

gen double `dresid'1 = (`sign'1*sqrt(abs(`dbari'1)))
gen double `dresid'2 = (`sign'2*sqrt(abs(`dbari'2)))

gen double `dresid'= `dresid'1 + `dresid'2
qui bys _midas_studylabel : egen double `dresidi'= mean(`dresid')

gen double `loglike'1 = _midas_dep1*log(invlogit(`xbi'1)) + (_midas_denom1-_midas_dep1)*log(1-invlogit(`xbi'1))
gen double `loglike'2 = _midas_dep2*log(invlogit(`xbi'2)) + (_midas_denom2-_midas_dep2)*log(1-invlogit(`xbi'2))
gen double `loglike' = `loglike'1 + `loglike'2
qui bys _midas_studylabel : egen double `meanlike' = mean(`loglike')
gen double `deviance' = -2*`loglike'

qui bys _midas_studylabel : egen double `randeff'1 = mean(`relogitsen')
qui bys _midas_studylabel : egen double `randeff'2 = mean(`relogitspe')
qui bys _midas_studylabel : egen double `serandeff'1 = sd(`relogitsen')
qui bys _midas_studylabel : egen double `serandeff'2 = sd(`relogitspe')

gen double `explike' = exp(`loglike')
egen double `cpoi' = hmean(`explike'), by(_midas_studyid)

gen double `dbar' = `dbari'1 + `dbari'2
qui bys _midas_studylabel : egen double `dbari' = mean(`dbar')

gen double `dhat' = `dhati'1 + `dhati'2
qui bys _midas_studylabel : egen double `dhati' = mean(`dhat')

egen `sstag'= tag(_midas_studylabel)
qui keep if `sstag' == 1

gen double `logscore' = -log(`cpoi')

gen double `kldi' = `logscore' + `meanlike'

//normalized Kullback-Leibler divergence
gen double `nkldi' = 1-exp(-`kldi')

gen double  `pdi' = `dbari' - `dhati'
gen double `dici' = `dbari' +  `pdi'
qui sort _midas_studylabel

mkmat `pobs1' `pobs2' `phati'1 `phati'2 `pdi' `dresidi' `logscore', ///
    matrix(`midasestimates')  rownames(_midas_studylabel)

mkmat `randeff'1 `randeff'2 `serandeff'1 `serandeff'2, ///
    matrix(`reffects')  rownames(_midas_studylabel)

mkmat `dresidi', ///
    matrix(`residuals')  rownames(_midas_studylabel)

qui sum `logscore', meanonly
return scalar logscore = r(mean)

qui sum `loglike', meanonly
return scalar logll = r(sum)

matname `midasestimates' pobs1 pobs2 phati1 phati2 pdi dresidi logscore, columns(.) explicit
return matrix midasmh_fit = `midasestimates', copy

matname `residuals' dresidi, columns(.) explicit
return matrix residuals = `residuals', copy

matname `reffects' randeff1 randeff2 serandeff1 serandeff2, columns(.) explicit
return matrix reffects = `reffects', copy

cap restore

end


**********************************************************************
*  Helper: mh_matrices
**********************************************************************

capture program drop mh_matrices
program define mh_matrices, rclass sortpreserve
version 16.1
syntax , COVmat(string)

if (`"`e(cmd)'"' != "bayesmh" & `"`e(prefix)'"' != "bayes") {
    di as err "last estimates not found"
    exit 301
}

cap preserve
use "`e(filename)'", clear
tempname Vblogit
tempvar varlogitsen varlogitspe logitsen logitspe corrvars covvars
tempvar sen spe lrn lrp ldor dor I2sen I2spe I2
tempvar Alpha Theta beta s2alpha s2theta chainvar

gen long `chainvar' = _chain

gen double `logitsen' = eq1_p1
gen double `logitspe' = eq1_p2

if "`covmat'" == "iwishart" { // Inverse Wishart Formulation
    gen double `varlogitsen' = eq0_p1
    gen double `varlogitspe' = eq0_p3
    gen double `covvars'= eq0_p2
    gen double `corrvars'= `covvars'/(sqrt(`varlogitsen')* sqrt(`varlogitspe'))
}
else if "`covmat'" == "product" { // Product Normal Formulation
    gen double `varlogitsen' = eq0_p2^2
    gen double `varlogitspe' = eq0_p3^2 + eq0_p2^2*eq0_p1^2
    gen double `covvars'= eq0_p1*eq0_p2^2
    gen double `corrvars'= `covvars'/(sqrt(`varlogitsen')* sqrt(`varlogitspe'))
}
else if "`covmat'" == "spherical" { // Spherical Decomposition
    gen double `varlogitsen' = eq0_p2^2
    gen double `varlogitspe' = eq0_p3 ^2
    gen double `corrvars'=  cos(eq0_p1)
    gen double `covvars'= `corrvars'*sqrt(`varlogitsen')* sqrt(`varlogitspe')
}
else if inlist("`covmat'","cholesky","sciwishart","hiwishart") { // Cholesky-family
    gen double `varlogitsen' = eq0_p2^2
    gen double `varlogitspe' = eq0_p3^2
    gen double `corrvars'= eq0_p1
    gen double `covvars'= `corrvars'*sqrt(`varlogitsen')* sqrt(`varlogitspe')
}
else if "`covmat'" == "cholefisher" { // cholefisher Transformation
    gen double `varlogitsen' = eq0_p1^2
    gen double `varlogitspe' = eq0_p2^2
    gen double `corrvars'= (2*invlogit(eq0_p3)-1)
    gen double `covvars'= `corrvars'*sqrt(`varlogitsen')* sqrt(`varlogitspe')
}

gen double `sen' =invlogit(`logitsen')
gen double `spe' = invlogit(`logitspe')
gen double `lrp' = `sen'/(1-`spe')
gen double `lrn' =(1-`sen')/`spe'
gen double `ldor' = `logitsen' + `logitspe'
gen double `dor' = exp(`ldor')

gen double `Alpha' = (`varlogitsen'/`varlogitspe')^(0.25)*`logitspe'+(`varlogitspe'/`varlogitsen')^(0.25)*`logitsen'
gen double `Theta' = 0.5*((`varlogitsen'/`varlogitspe')^(0.25)*`logitspe'-(`varlogitspe'/`varlogitsen')^(0.25)*`logitsen')
gen double `beta' = 0.5*log(`varlogitsen'/`varlogitspe')
gen double `s2alpha' = 2*(sqrt(`varlogitspe'*`varlogitsen')+`covvars')
gen double `s2theta' = 0.5*(sqrt(`varlogitspe'*`varlogitsen')-`covvars')

qui gen `I2sen' = .
qui gen `I2spe' = .
qui gen `I2' = .

forvalues i = 1/$midas_nobs {
    mat `Vblogit'`i'=(`varlogitsen'[`i'] , `covvars'[`i'] \ `covvars'[`i'] , `varlogitspe'[`i'])

    qui replace `I2sen' = `varlogitsen'[`i']/(`varlogitsen'[`i']+  ///
        ($avnum1*(exp(((`varlogitsen'[`i'])/2)+`logitsen'[`i'])+ ///
        exp(((`varlogitsen'[`i'])/2)-`logitsen'[`i'])+2))) in `i'

    qui replace `I2spe' = `varlogitspe'[`i']/(`varlogitspe'[`i']+ ///
        ($avnum2*(exp(((`varlogitspe'[`i'])/2)+  ///
        `logitspe'[`i'])+exp(((`varlogitspe'[`i'])/2)-`logitspe'[`i'])+2))) in `i'

    qui replace  `I2' =  sqrt(exp(log(det(`Vblogit'`i'))))/(sqrt(exp(log(det(`Vblogit'`i'))))+ ///
        sqrt(($avnum1*(exp(((`varlogitsen'[`i'])/2)+`logitsen'[`i'])+ ///
        exp(((`varlogitsen'[`i'])/2)-`logitsen'[`i'])+2))* ///
        ($avnum2*(exp(((`varlogitspe'[`i'])/2)+`logitspe'[`i'])+ ///
        exp(((`varlogitspe'[`i'])/2)-`logitspe'[`i'])+2)))) in `i'
}

qui correlate `logitsen' `logitspe', covariance
return scalar covmus = r(cov_12)

// summary matrices

local varlist "`sen' `spe' `lrp' `lrn' `dor' `ldor'"
local sumnames "Sens Spec LRP LRN DOR LOR"
mata: mh_mat("`varlist'", "")
mat means =  r(mean)
mat colnames means = `sumnames'
return matrix bsum = means, copy
mat medians =  r(median)
mat colnames medians = `sumnames'
return matrix bsummed = medians, copy
mat sems = r(sem)'
mat colnames sems =`sumnames'
return matrix bsumsd = sems, copy
mat covs= r(cov)
mat colnames covs = `sumnames'
mat rownames covs =`sumnames'
return matrix Vsum = covs, copy

local varlist "`Alpha' `Theta' `beta' `s2alpha' `s2theta'"
local hsrocnames "Alpha Theta beta s2alpha s2theta" 
mata: mh_mat("`varlist'", "")
mat means =  r(mean)
mat colnames means = `hsrocnames'
return matrix bhsroc = means, copy
mat medians =  r(median)
mat colnames medians = `hsrocnames'
return matrix bhsrocmed = medians, copy
mat sems = r(sem)'
mat colnames sems = `hsrocnames'
return matrix bhsrocsd = sems, copy
mat covs= r(cov)
mat colnames covs = `hsrocnames'
mat rownames covs = `hsrocnames'
return matrix Vhsroc = covs, copy

local varlist "`I2sen' `I2spe' `I2'"
local isqnames "I2sen I2spe I2biv"
mata: mh_mat("`varlist'", "")
mat means =  r(mean)
mat colnames means = `isqnames'
return matrix bIsq = means, copy
mat medians =  r(median)
mat colnames medians = `isqnames'
return matrix bIsqmed = medians, copy
mat sems = r(sem)'
mat colnames sems = `isqnames'
return matrix bIsqsd = sems, copy
mat covs= r(cov)
mat colnames covs = `isqnames'
mat rownames covs = `isqnames'
return matrix VIsq = covs, copy

local varlist "`logitsen' `logitspe' `varlogitsen' `varlogitspe' `covvars' "
local hessnames "logitsen logitspe varlogitsen varlogitspe covvars"
mata: mh_mat("`varlist'", "")
mat means =  r(mean)
mat colnames means = `hessnames'
return matrix bhess = means, copy
mat medians =  r(median)
mat colnames medians = `hessnames'
return matrix bhessmed = medians, copy
mat sems = r(sem)'
mat colnames sems = `hessnames'
return matrix bhesssd = sems, copy
mat covs= r(cov)
mat colnames covs = `hessnames'
mat rownames covs = `hessnames'
return matrix Vhess = covs, copy

tempvar matid
gen `matid' = _n
local varlist "`logitsen' `logitspe' `varlogitsen' `varlogitspe' `covvars' `corrvars'"
local coefnames "logitsen logitspe varlogitsen varlogitspe covvars corrvars"
mata: mh_mat("`varlist'", "")
mat means =  r(mean)
mat colnames means = `coefnames'
return matrix b = means, copy
mat medians =  r(median)
mat colnames medians = `coefnames'
return matrix bmed = medians, copy
mat sems = r(sem)'
mat colnames sems =`coefnames'
return matrix bsd = sems, copy
mat covs= r(cov)
mat colnames covs = `coefnames'
mat rownames covs =`coefnames'
return matrix V = covs, copy

global simnobs=_N
postutil clear
qui postfile _midasfile chainvar logitsen logitspe varlogitsen varlogitspe covvars  corrvars using ///
"C:/ado/personal/midas_sim_data.dta", replace
qui forvalues i = 1/$simnobs {
    post _midasfile  (`chainvar'[`i']) (`logitsen'[`i']) (`logitspe'[`i']) (`varlogitsen'[`i']) (`varlogitspe'[`i']) (`covvars'[`i']) (`corrvars'[`i'])
}
postclose _midasfile
postutil clear
use "C:/ado/personal/midas_sim_data.dta", clear

return local midasfile "C:/ado/personal/midas_sim_data.dta"
cap restore
end


**********************************************************************
*  Helper: mh_ppp + Mata core
**********************************************************************

capture program drop mh_ppp
program define mh_ppp, rclass
version 15
syntax [, TITle  FORMAT(string asis) ]

if (`"`e(cmd)'"' != "bayesmh" & `"`e(prefix)'"' != "bayes") {
    di as err "last estimates not found"
    exit 301
}
if (`"`e(filename)'"'=="") {
    di as err "simulation results not found"
    exit 301
}

local estfile: di e(filename)

use `estfile', clear

tempvar varlist maxlike explike loowgtnorm loowgtreg
gen `varlist' = _loglikelihood
egen  `maxlike'=max(`varlist')

egen `explike'=mean((1/exp(`varlist'-`maxlike')))

gen `loowgtnorm'=(1/exp(`varlist'-`maxlike'))/`explike'

gen  `loowgtreg'=min(`loowgtnorm', sqrt(_N))

mata: _mh_ppp("`varlist' `loowgtreg'", "")
tempname tmp
mat `tmp'= r(biccv)
matrix rownames `tmp'= value
nois di ""
if  "`title'" != "" {
    di as smcl  "{hilite: Bayesian Posterior Predictive Performance Metrics}"
}
nois di ""
_matrix_table  `tmp', formats(`format')
nois di ""

ret matrix ppp =  `tmp'
ret scalar deviance = r(deviance)
ret scalar pd = r(pd)
ret scalar elppddev = r(elppd_dev)
ret scalar pwaic = r(p_waic)
ret scalar elppdwaic = r(elppd_waic)
ret scalar waic = r(waic)
ret scalar ploo = r(p_loo)
ret scalar elppdloo = r(elppd_loo)
ret scalar loocv = r(loo_cv)
ret scalar dbar = r(dbar)
ret scalar dic = r(dic)
ret scalar dhat = r(dhat)
ret scalar lppd= r(lppd)
ret scalar loglll = r(loglll)
end


version 12.1
mata:

mata set matastrict on
mata set matafavor speed
void _mh_ppp(string scalar varlist, string scalar touse)
{
    real matrix         M
    real colvector      loowgtraw, loowgtnorm, loowgtreg
    real rowvector      biccv
    real scalar         nobs, lppd, elppd_dev, waic, p_waic, elppd_waic
    real scalar         elppd_loo, p_loo, i, pd, dbar, dhat, dic, loo_cv, deviance
    real scalar         loglll

    M =.
    st_view(M,., tokens(varlist), touse)
    nobs=rows(M)
    loglll=mean(M[.,1])
    deviance=mean(-2*M[.,1])
    dbar = -2:*mean(M[.,1])
    pd=variance(-2:*M[.,1])/2
    dic=dbar:+pd
    dhat=dbar-pd
    lppd=log(mean(exp(M[.,1])))
    elppd_dev=-2*log(mean(exp(M[.,1])))
    p_waic=variance(M[.,1])
    elppd_waic=log(mean(exp(M[.,1])))-variance(M[.,1])
    waic=-2*(log(mean(exp(M[.,1])))-variance(M[.,1]))
    for(i=1;i <= nobs; i++) {
        loowgtraw=1/exp(M[i,1]-max(M[.,1]))
        loowgtnorm=(1/exp(M[i,1]-max(M[.,1])))/mean((1/exp(M[i,1]-max(M[.,1]))))
        loowgtreg=M[i,2]
        elppd_loo=log(mean(exp(M[i,1]):*loowgtreg)/mean(loowgtreg))
    }
    p_loo = lppd-elppd_loo
    loo_cv = -2*elppd_loo
    biccv=(deviance, dic, loo_cv,  waic)
    st_numscalar("r(loglll)", loglll)
    st_numscalar("r(deviance)", deviance)
    st_numscalar("r(pd)", pd)
    st_numscalar("r(lppd)", lppd)
    st_numscalar("r(p_waic)", p_waic)
    st_numscalar("r(elppd_dev)", elppd_dev)
    st_numscalar("r(elppd_waic)", elppd_waic)
    st_numscalar("r(waic)", waic)
    st_numscalar("r(p_loo)", p_loo)
    st_numscalar("r(elppd_loo)", elppd_loo)
    st_numscalar("r(loo_cv)", loo_cv)
    st_numscalar("r(dbar)", dbar)
    st_numscalar("r(dhat)", dhat)
    st_numscalar("r(dic)", dic)
    st_matrix("r(biccv)", biccv)
    st_matrixcolstripe("r(biccv)", ("","Deviance"\"","DIC"\"","LOOCV"\"","WAIC"))
}

end


**********************************************************************
*  Helper: mh_converge + mcmcconverge infrastructure
**********************************************************************

capture program drop mh_converge
program define mh_converge, rclass sortpreserve
version 17.0
syntax , COVmat(string)

if (`"`e(cmd)'"' != "bayesmh" & `"`e(prefix)'"' != "bayes") {
    di as err "last estimates not found"
    exit 301
}

cap preserve
use "`e(filename)'", clear
keep eq1_p*  eq0_p* _chain

gen double logitsen = eq1_p1
gen double logitspe = eq1_p2

if "`covmat'" == "iwishart" { // Inverse iwishart Formulation
    gen double varlogitsen = eq0_p1
    gen double varlogitspe = eq0_p3
    gen double covlogits = eq0_p2
    gen double corrlogits = covlogits/(sqrt(varlogitsen)* sqrt(varlogitspe))
}
else if "`covmat'" == "product" { // Product Normal Formulation
    gen double varlogitsen = eq0_p2^2
    gen double varlogitspe = eq0_p3^2 + eq0_p2^2*eq0_p1^2
    gen double covlogits = eq0_p1*eq0_p2^2
    gen double corrlogits = covlogits/(sqrt(varlogitsen)* sqrt(varlogitspe))
}
else if "`covmat'" == "spherical" { // Spherical Decomposition
    gen double varlogitsen = eq0_p2^2
    gen double varlogitspe = eq0_p3^2
    gen double corrlogits =  cos(eq0_p1)
    gen double covlogits = corrlogits*sqrt(varlogitsen)* sqrt(varlogitspe)
}
else if inlist("`covmat'","cholesky","sciwishart","hiwishart") { // Cholesky-family
    gen double varlogitsen = eq0_p2^2
    gen double varlogitspe = eq0_p3^2
    gen double corrlogits = eq0_p1
    gen double covlogits= corrlogits*sqrt(varlogitsen)* sqrt(varlogitspe)
}
else if "`covmat'" == "cholefisher" { // cholefisher Transformation
    gen double varlogitsen = eq0_p1^2
    gen double varlogitspe = eq0_p2^2
    gen double corrlogits = (2*invlogit(eq0_p3)-1)
    gen double covlogits = corrlogits*sqrt(varlogitsen)* sqrt(varlogitspe)
}
bysort _chain: gen niter = _n

// Save convergestats alongside the bayesmh output file

mcmcconverge logitsen logitspe varlogitsen varlogitspe covlogits corrlogits, iter(niter) chain(_chain) saving("convergestats.dta") replace
use "convergestats.dta", clear
tempvar rowid
decode variable, gen(`rowid')
mkmat  Rhat  neff , mat(converge)  rownames(`rowid')
local cvstatsnames "logitse logitspe varlogitsen varlogitspe covvars corrvars" 
mat rownames converge = `cvstatsnames'
sum Rhat, meanonly
return scalar rmax = r(max)
return matrix converge = converge, copy
cap restore

end


capture program drop mcmcconverge
program mcmcconverge

  version 12.1

  *Gelman-Carlin-Stern-Rubin convergence statistics for mcmc chains
  * varlist: variables to analyze
  * iter: variable identifying iterations of the sampler
  * chain: variable identifying separate chains

  syntax varlist [if] [in], iter(varname) chain(varname) saving(string asis) [replace]

  marksample touse

  preserve

  qui keep `iter' `chain' `varlist' `touse'
  qui keep if `touse'

  *check that we still have data
  capture assert _N>0
  if _rc!=0 {
    display("failed: no data satisfy the specifications.")
    exit
    }

  *check that each chain has the same number of obs
  qui xtset `chain' `iter'
  capture assert "`r(balanced)'"!="unbalanced"
  if _rc!=0 {
    display("failed: chains have different numbers of observations.")
    exit
    }

  *proceed

  qui levelsof `chain', local(usechains)
  local nc : word count `usechains'
  local niters=_N/`nc'
  unab vars : `varlist'
  local nv : word count `vars'

  *means and variances within chains
  mata: mvfun("`vars'","`chain'")
  qui gen double varplus=(B+(`niters'-1)*W)/`niters'
  qui gen double Rhat=sqrt(varplus/W)
  qui gen double neff=`niters'*`nc'*varplus/B
  qui gen double neffmin=min(neff,`niters'*`nc')

  capture lab drop _all
  forvalues i=1/`nv' {
    local v : word `i' of `vars'
    lab def variable `i' "`v'", add
    }
  lab values variable variable
  lab var B "between-sequence variance"
  lab var W "within-sequence variance"
  lab var varplus "marginal posterior variance"
  lab var Rhat "potential scale reduction from further simulations"
  lab var neff "effective number of independent draws"
  lab var neffmin "min(neff,actual number of draws)"

  qui compress
  qui save `saving', `replace'

end



version 12.1
mata:

mata set matastrict on
mata set matafavor speed

void mvfun(string scalar vars, string scalar chain)
  {
  real matrix cvec, cinfo, x, res_m, res_v, work, B
  real scalar c, nc, nx, i
  cvec=st_data(.,chain)
  cinfo=panelsetup(cvec,1)
  nc=rows(cinfo)
  x=st_data(.,vars)
  nx=cols(x)
  res_m=J(nc,nx,0)
  res_v=J(nc,nx,0)
  for(c=1;c<=nc;c++) {
    work=panelsubmatrix(x,c,cinfo)
    res_m[c,.]=mean(work)
    for(i=1;i<=nx;i++) {
      res_v[c,i]=variance(work[.,i])
      }
    }
  stata("qui drop _all")
  st_addobs(nx)
  (void) st_addvar("long","variable")
  st_store(.,1,range(1,nx,1))
  (void) st_addvar("double","B")
  B=J(nx,1,.)
  for(i=1;i<=nx;i++) {
    B[i,1]=variance(res_m[.,i])
    }
  st_store(.,2,B*rows(work))
  (void) st_addvar("double","W")
  st_store(.,3,mean(res_v)')
  }

end


**********************************************************************
*  Helper: mh_sumstats, HPD utilities
**********************************************************************

capture program drop mh_sumstats
program mh_sumstats , rclass byable(recall)
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
*/ `"      mcse       median          [`=strsubdp("`level'")'% HPD]"'
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
         mh_sumstats_hpd `v'  , alpha(`level')
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
*/ in ye %9.4f `mn' /*
*/ " " %9.4f `sd' /*
*/ %9.4f `se' /*
*/ "  "  %9.4f `md' /*
*/ "   " %9.4f `lb' /*
*/ "  " %9.4f `ub'
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


capture program drop mh_sumstats_hpd
program mh_sumstats_hpd , rclass
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
         mh_sumstats_interp `x' `cf'  , value(`xlow')
         local a1 = r(fvalue)
         * xhigh corresponding to xlow
         mh_sumstats_interp `x' `f' if `x' < `thetam' , value(`xlow')
         local fx = r(fvalue)
         mh_sumstats_interp `f' `x' if `x' > `thetam' , value(`fx') down
         local xhigh = r(fvalue)
         * area to right of xlow
         mh_sumstats_interp `x' `cf'  , value(`xhigh')
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


capture program drop mh_sumstats_interp
program mh_sumstats_interp , rclass
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


*! mh_inits1.ado
*! Automated chain-specific initialization for bayesmh
*! Author: Ben Adarkwa Dwamena, MD

capture program drop mh_inits1
program define mh_inits1, rclass
    version 15

    // syntax: no varlist; all options declared explicitly
    syntax , NCHAINS(integer) ///
        [ UNCONstrained(string asis) ///
          POSitive(string asis) ///
          CORR(string asis) ///
          FISHERZ(string asis) ///
          PHI(string asis) ///
          SIMPLEX(string asis) ///
          CENTER(string asis) ///
          SCALE(string asis) ///
          SEED(integer 12345) ///
          RNGStream(integer 0) ///
          FMT(string) ///
          COMPACT ]

    if "`fmt'" == "" local fmt "%9.5f"

    local L_u   "`unconstrained'"
    local L_p   "`positive'"
    local L_r   "`corr'"
    local L_z   "`fisherz'"
    local L_phi "`phi'"
    local L_s   "`simplex'"

    local center_map "`center'"
    local scale_map  "`scale'"

    quietly set seed `seed'
    local space " "
    if "`compact'" != "" local space ""

    local all ""
    local allwrap ""
    local NL = char(10)

    // ------------------------ LOOP OVER CHAINS ------------------------
    forvalues k = 1/`nchains' {
        local spec ""

        if `rngstream' > 0 {
            quietly set rngstream `= `rngstream' + `k' - 1'
        }

        // --- Unconstrained ---
        foreach nm of local L_u {
            quietly _getcs `nm' u "`center_map'" "`scale_map'"
            local v = r(c) + r(s)*rnormal()
            local spec "`spec'`space'{`nm'} `=strofreal(`v',"`fmt'")'"
        }

        // --- Positive (log) ---
        foreach nm of local L_p {
            quietly _getcs `nm' p "`center_map'" "`scale_map'"
            local lv = ln(r(c)) + r(s)*rnormal()
            local v = exp(`lv')
            if `v' <= 1e-10 local v = 1e-6
            if `v' >= 1e+10 local v = 1e+6
            local spec "`spec'`space'{`nm'} `=strofreal(`v',"`fmt'")'"
        }

        // --- Correlation (Fisher-z) ---
        foreach nm of local L_r {
            quietly _getcs `nm' r "`center_map'" "`scale_map'"
            local z   = atanh(r(c)) + r(s)*rnormal()
            local rho = tanh(`z')
            if abs(`rho') >= 0.995 local rho = 0.995*sign(`rho')
            local spec "`spec'`space'{`nm'} `=strofreal(`rho',"`fmt'")'"
        }

        // --- Fisher-z ---
        foreach nm of local L_z {
            quietly _getcs `nm' z "`center_map'" "`scale_map'"
            local v = r(c) + r(s)*rnormal()
            local spec "`spec'`space'{`nm'} `=strofreal(`v',"`fmt'")'"
        }

        // --- Angular phi ---
        foreach nm of local L_phi {
            quietly _getcs `nm' phi "`center_map'" "`scale_map'"
            local phi = r(c) + r(s)*rnormal()
            if `phi' < 0.001 local phi = 0.001
            if `phi' > c(pi)-0.001 local phi = c(pi)-0.001
            local spec "`spec'`space'{`nm'} `=strofreal(`phi',"`fmt'")'"
        }

        // --- Simplex ---
        if "`L_s'" != "" {
            local G : word count `L_s'
            if `G' == 1 {
                local nm : word 1 of `L_s'
                local spec "`spec'`space'{`nm'} 1'"
            }
            else {
                local first : word 1 of `L_s'
                quietly _getcs `first' s "`center_map'" "`scale_map'"

                tempname SUM
                scalar `SUM' = 0

                forvalues j = 1/`G' {
                    scalar __z`j' = rnormal()
                    scalar __w`j' = exp(r(s)*__z`j')
                    scalar `SUM' = `SUM' + __w`j'
                }

                forvalues j = 1/`G' {
                    scalar __p`j' = __w`j'/`SUM'
                    local nm : word `j' of `L_s'
                    local spec "`spec'`space'{`nm'} `=strofreal(scalar(__p`j'),"`fmt'")'"
                }
            }
        }

        return local init`k' "`spec'"

        // composite one-line
        local all "`all' init`k'(`spec')"

        // composite wrapped
        if `k' == 1 {
            local allwrap "init`k'(`spec') ///"
        }
        else if `k' < `nchains' {
            local allwrap "`allwrap'`NL'init`k'(`spec') ///"
        }
        else {
            local allwrap "`allwrap'`NL'init`k'(`spec')"
        }
    }

    return local init_all "`all'"
    return local init_all_wrap "`allwrap'"
end


capture program drop _getcs
program define _getcs, rclass
    version 15
    // Syntax: _getcs name domain center_map scale_map
    args name domain center_map scale_map

    tempname c s
    scalar `c' = .
    scalar `s' = .

    // Default centers by domain
    if "`domain'" == "u"   scalar `c' = 0
    if "`domain'" == "p"   scalar `c' = 1
    if "`domain'" == "r"   scalar `c' = 0
    if "`domain'" == "z"   scalar `c' = 0
    if "`domain'" == "phi" scalar `c' = c(pi)/2
    if "`domain'" == "s"   scalar `c' = 0

    // Default scales by domain
    if "`domain'" == "u"   scalar `s' = 1
    if "`domain'" == "p"   scalar `s' = 0.5
    if "`domain'" == "r"   scalar `s' = 0.5
    if "`domain'" == "z"   scalar `s' = 0.5
    if "`domain'" == "phi" scalar `s' = 0.7
    if "`domain'" == "s"   scalar `s' = 0.3

    // ---- Center overrides: parse "name=expr" tokens ----
    if "`center_map'" != "" {
        local tmp `center_map'
        while "`tmp'" != "" {
            gettoken pair tmp : tmp
            if strpos("`pair'","=") {
                gettoken lhs rhs : pair, parse("=")

                // Strip leading "=" if present
                if substr("`rhs'",1,1) == "=" {
                    local rhs = substr("`rhs'",2,.)
                }

                // Remove spaces from rhs (e.g. "  1.23 " -> "1.23")
                local rhs = subinstr("`rhs'"," ","",.)

                if "`lhs'" == "`name'" {
                    scalar `c' = real("`rhs'")
                }
            }
        }
    }

    // ---- Scale overrides: parse "name=#" tokens ----
    if "`scale_map'" != "" {
        local tmp2 `scale_map'
        while "`tmp2'" != "" {
            gettoken pair tmp2 : tmp2
            if strpos("`pair'","=") {
                gettoken lhs rhs : pair, parse("=")

                if substr("`rhs'",1,1) == "=" {
                    local rhs = substr("`rhs'",2,.)
                }

                local rhs = subinstr("`rhs'"," ","",.)

                if "`lhs'" == "`name'" {
                    scalar `s' = real("`rhs'")

                }
            }
        }
    }

    return scalar c = scalar(`c')
    return scalar s = scalar(`s')
end



// a hack from metandi
cap program drop mh_inits0 
program define mh_inits0, rclass sortpreserve
version 8.2
syntax varlist(min=4 max=4) [if] [in] [,  ]
preserve
marksample touse
tokenize `varlist'
local true1  `1' // TP
local false0 `2' // FP
local false1 `3' // FN
local true0  `4' // TN

// reshape data to long format  
qui {
gen long _midas_i = _n
gen long _midas_n1 = `true1' +`false1' if `touse'
gen long _midas_n0 = `true0' + `false0' if `touse'
gen long _midas_true1 = `true1' 
gen long _midas_true0 = `true0'

//  d1 is diseased (sensitivity) d0 is nondiseased (specificity) 
reshape long _midas_n _midas_true, i(_midas_i) j(_midas_d1)
sort _midas_i _midas_d1
gen byte _midas_d0 = 1 - _midas_d1 
		
	
tempvar tf // true (pos or neg) fraction 
gen `tf' = _midas_true / _midas_n if `touse'

// run univariate models to get good starting values 
foreach g of numlist 1 0 {
if `g'==1 local ss Sensitivity, Se
else   local ss Specificity, Sp

// use mean TPF/TNF as starting value for summary proportion 
summ `tf' if _midas_d`g', meanonly
matrix b0uni = ( logit( r(mean) ), 0.5 )
xtmelogit (_midas_true _midas_d`g' if _midas_d`g' & `touse', nocons) ///
(_midas_i: _midas_d`g' , nocons ), ///
binomial(_midas_n)  from(b0uni) refineopts(iterate(3))  coeflegend

matrix b`g' = e(b) // 1st element is logit(TF), 2nd is ln(SD)
predict _midas_u`g' if `touse', reffects
			}

	
// construct starting values 

correlate _midas_u1 _midas_u0 if `touse'
drop _midas_u1 _midas_u0
matrix b0 = (b1[1,1], b0[1,1], b1[1,2], b0[1,2], tanh(r(rho)))
	
		
// fit full bivariate model 
xtmelogit _midas_true _midas_d1 _midas_d0, nocons ///
|| _midas_i: _midas_d1 _midas_d0, nocons covariance(un) ///
binomial(_midas_n) intp(7)  `xtmeopts' `log' `trace' ///
refineopts(iterate(3)) from(b0) 
capture _estimates drop _midas
_estimates hold _midas, copy


// c22 v small -> corrlogits=+/-1 & numerical problem if include in nlcom
local corrterm "tanh([atr1_1_1_2]_b[_cons])"
if [atr1_1_1_2]_b[_cons] < -4 local corrterm "(-1)"
if [atr1_1_1_2]_b[_cons] >  4 local corrterm "1"
		
nlcom ///
( muA: _b[_midas_d1] ) ( muB: _b[_midas_d0] ) ( sdA: [lns1_1_1]_b[_cons])  /// 
( sdB: [lns1_1_2]_b[_cons]) ( corr: `corrterm')  ///
( s2A: exp(2 * [lns1_1_1]_b[_cons]) )  ( s2B: exp(2 * [lns1_1_2]_b[_cons]) ) /// 
( sAB: exp([lns1_1_1]_b[_cons]) * exp([lns1_1_2]_b[_cons]) * `corrterm' ) ///
(lamda: `corrterm'*exp(2 * [lns1_1_2]_b[_cons])/exp(2 * [lns1_1_1]_b[_cons])) ///
(fisherz: [atr1_1_1_2]_b[_cons])(phi: acos(`corrterm'))

matrix binit= r(b)
matrix Vinit= r(V)
return matrix b= binit
return matrix V= Vinit
		} 
restore
		
end
/********************************************************************************
* Mata: mh_mat
********************************************************************************/
mata: mata clear
mata:
void mh_mat(string scalar varlist, string scalar touse)
{
    real matrix M
    real rowvector mh_means, mh_medians
    real matrix mh_covs
    real colvector mh_sem

    M = .
    st_view(M, ., tokens(varlist), 0)
    mh_means   = mean(M)
    mh_medians = mm_median(M)
    mh_covs    = variance(M)
    mh_sem     = sqrt(diagonal(mh_covs))

    st_matrix("r(mean)",   mh_means)
    st_matrix("r(median)", mh_medians)
    st_matrix("r(sem)",    mh_sem)
    st_matrix("r(cov)",    mh_covs)
}
end


