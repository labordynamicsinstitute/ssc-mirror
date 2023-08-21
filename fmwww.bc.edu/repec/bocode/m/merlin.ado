*! version 2.4.0  16aug2023 MJC

/*
History
2.4.0
- bhazard() with loglogistic, gamma, lognormal should've thrown an error as it 
  wasn't supported; now it is!
- bug fix; multilevel bernoulli would fail - now fixed
- left-truncation with a multilevel survival models has been re-written
- general tidying & improvements under the hood
- density added to predict
06feb2023 version 2.3.0 
- help file link fixes
- chintpoints() now added and doc'd in stmerlin help file
- error check added within rcs(..,df(#)) for repeated knots
- z-scores and p-values now shown when option eform is used
- bug fix: introduced in v2.0.0, predict with option marginal erroneously 
  returned fixedonly predictions; now fixed
- bug fix: stmerlin with option bhazard() would tend to not converge due to 
  calling analytic derivatives in situations where it shouldn't; now fixed
17jan2023 version 2.2.0 - eform added to merlin & stmerlin
                        - bug fixes for ob. level models
18mar2022 version 2.1.5 - bug fix; family(rp,...) models could error out when 
                          element interactions were specified and the number of 
                          basis functions created was >1. Now fixed.
22feb2022 version 2.1.4 - bug fix; multivariate gaussian or poisson models would 
                          show an indexing error when they had different numbers 
                          of observations per outcome - now fixed
22dec2021 version 2.1.3 - missed quietly on bootstrap results; now fixed
08dec2021 version 2.1.2 - bug fix in Cox with ties and no delayed entry
07dec2021 version 2.1.1 - improved grid search performance
03dec2021 version 2.1.0 - now conducts a grid search (grid = 0.1,1) for starting values of random effect variances
                        - missing quietly's with predict, ci's after Cox model; now fixed
                        - family(bernoulli, pwexp, gompertz) would fail; now fixed
                        - bug fix with predictions called from predictms following user logh or h; now fixed
19mar2021 version 2.0.2 - bug fix; predictions from a delayed entry Cox model ignored the entry time, now fixed
14mar2021 version 2.0.1 - improved performance handling large clusters (many observations within a cluster); numerical underflow and 
                          overflow are now much less likely in such settings
                        - bug fix for multivariate models, if an if statement was specifed in model 2 then it would be ignored; now fixed
                        - bug fix; if missed in stmerlin, dist(rp), now fixed
04mar2021 version 2.0.0	- The following models now use a gf2 evaluator (analytic score and Hessian), resulting in substantial speed gains:
                                -> Univariate or multivariate (stacked/stratified) fixed effects models:
                                        - family(rp)
                                        - family(loghazard)
                                        - family(hazard)
                                        - family(exponential)
                                        - family(weibull)
                                        - family(cox)
                                        - family(logchazard)
                                        - family(gaussian)
                                        - family(poisson)
                                        - family(pwexponential)
                                        - family(gompertz)
                                        - note, this applies to all models in -stmerlin-
                                        - survival models maintain this speed gain even in the presence of complex time-time interactions, due to an 
                                          internal chain rule function
                                        - note, if parameters are linked across models in a multivariate model, then gf0 will be used
                                -> The following univariate models will use a gf1 evaluator (analytic score only):
                                        - family(rp) with interval-censoring or as a relative survival model (bhazard() option)
                                        - family(loghazard) with interval-censoring
                                        - family(exponential) with interval-censoring
                                        - family(weibull) with interval-censoring
                                        - family(pwexponential) with interval-censoring
                                        - family(gompertz) with interval-censoring
                                -> The following univariate models will still use a gf0 evaluator:
                                        - family(exponential) with bhazard() i.e. a relative survival model
                                        - family(weibull) with bhazard() i.e. a relative survival model
                                        - family(pwexponential) with bhazard() i.e. a relative survival model
                                        - family(gompertz) with bhazard() i.e. a relative survival model
                        - General minor speed improvements for all models, due to a re-write of how design matrices and the complex linear predictor 
                          are stored and called, respectively. This may result in some minor changes in estimates compared to v1.15.3.
                        - standardised/study population-averaged predictions are now available through the standardise option of predict. This 
                          specifies that the predicted statistic be computed marginally with respect to the independent variables, implemented 
                          by calculating the statistic separately for all observed covariate patterns, and taking the average. standardise can 
                          be used in combination with at(), or at1() and at2() to obtain estimates of marginal estimands. Currently only available 
                          with fixed effects models.
                        - family(hazard, failure()) has been added to fit a general parametric additive hazard model. This simply defines the 
                          hazard function equal to a complex linear predictor, with the cumulative hazard function evaluated using numerical 
                          integration. No constraints are applied to ensure the hazard function remains positive; the function is simple estimated 
                          from the data. Currently only available with fixed effects models.
                        - predict, totalsurvival added to allow prediction of the all-cause survival function, following the estimation of a 
                          competing risks survival model. 
                        - conditional survival and cumulative incidence predictions are now available through the ltruncated() option of predict. 
                          This allows prediction of survival or cumulative incidence function, conditional on being event free at user-defined 
                          times > 0. 
                        - -predict, reffects- and -predict, reses- added to calculate cluster-specific posterior means (empirical Bayes estimates) 
                          of the random effects, and their standard errors, respectively. Currently only available for two-level models. 
                        - chintpoints() option added to specify the number of Gauss-Legendre quadrature points to evaluate the cumulative hazard 
                          when it's analytically intractible. Default is chintpoints(30). Option also added to predict.
                        - -predict, fitted- added to calculate cluster-specific predictions after fitting a two-level model. Predictions include 
                          both estimates of the fixed effects and posterior means of the random effects.
                        - -predict, userfunction()- added to allow a user-defined prediction to be obtained, in the form of a Mata function, 
                          utilising merlin's utility functions.
                        - timevar() option is no longer required when modelling time-dependent effects in a survival model, the time variable 
                          is automatically detected and matched. This can still be overriden by using the timevar() option if the user wishes 
                          to use a different variable.
                        - -stmerlin- now supports multiple timescale survival models
                        - -stmerlin, distribution(rp)-, to fit a Royston-Parmar spline model on the log cumulative hazard scale has improved 
                          starting values, resulting in faster model fitting.
                        - -stmerlin- now supports -merlin-'s linear predictor syntax, so non-linear effects can be directly specified using the rcs(), fp(), 
                          bs() and pc() elements to create restricted cubic splines, fractional polynomials, B-splines and piecewise-constant splines, 
                          respectively. Interactions of such elements are also now supported. This makes predictions in the presence of non-linear effects 
                          substantially easier than other commands, as the basis functions are created internally - the value of the input variable, such as 
                          age, is all that needs to be defined in the -at()- statement of -predict-.
                        - -merlin- results table now displays "Fixed effects regression model" when no random effects are included in a model, instead of 
                          "Mixed effects regression model".
                        - prior to version 2, a random effect interacted with an element that created more than 1 basis function, e.g., 
                          rcs(time, df(3))#M1[id]@1, interacted each basis function with the same, single random effect. Version 2 introduces more expected 
                          behavior, forming a random effect for each basis function coefficient, e.g., rcs(time, df(3))#M1[id]@1 would create the random 
                          effects M1a, M1b and M1c, one for each basis function, respectively.
                        - the accuracy of differentiation with respect to time is improved when using the dEV[] or dXB[] elements - now analytic rather than 
                          using finite differences.
                        - lot of minor tidying, including improved error handling
22feb2021: version 1.15.3 - bug introduced in 1.15.2; survival models would error out if the user did not have -multistate- also installed, as it contained a subroutine used by -merlin-, now fixed
19feb2021: version 1.15.2 - bug; covariance() specification was not picked up by predict, so the default independent was always assumed - this has been fixed
  - bug; when predicting survival with cis, the lower and upper limits were labelled the wrong way around - this has been fixed
  - bug; rare index error could occur when predict was called with a restricted sample & a survival prediction, and 0 events were in the sample - now fixed
09feb2021: version 1.15.1 - bug fix; indexing error caused interval censored survival models to error out, now fixed
18jan2021: version 1.15.0 - pc() default behavior has changed. Now by default it does not include a binary indicator for the first 
                            interval i.e., before the first knot. To include an indicator for all intervals use the noreference option
17dec2020: version 1.14.0 - added pc() element to specify a piecewise constant spline function
                          - added chintpoints() to specify the number of Gauss-Legendre quadrature points, default is 30
15dec2020: version 1.13.0 - family(pwexponential) added to fit the piecewise-exponential survival model, with option knots() for user-defined cut-points
                                -- synced with stmerlin
                          - [NOTDOC] synced all elements with timevar() and ltruncated() matching
                          - [NOTDOC] synced elements with [m]offset == ltruncated() matching
                          - [NOTDOC] all survival models synced with numerical integration predictms predictions (passing t0, so including multiple timescales)
                          - [NOTDOC] block use of offsets when called through predictms, devcode1() overrides
28oct2020: version 1.12.1 - bug fix: stmerlin, dist(rcs) noorthog failed; now fixed
                          - bug fix: covariance(identity) with a 2+ level model error'd out, initial value dimension was incorrect; now fixed
                          - bug fix: internal constraints were left behind after a predict call; now fixed
20sep2020: version 1.12.0 - family(lognormal) added for the log normal AFT survival model
                                -- synced with stmerlin
                          - family(loglogistic) added for the log logistic AFT survival model
                                -- synced with stmerlin
17sep2020: version 1.11.1 - bug fixes in family(ggamma) with ltruncated()
                          - ltruncated() efficiency improved
16sep2020: version 1.11.0 - memory leak issue fixed; results in speed improvements, especially ci prediction, and repeated model fits
                          - any constraints specified through @ notation are now dropped post-estimation, otherwise the max limit could be met if used in simulations
                          - stmerlin; orthog default missed in dist(rcs), now fixed
21aug2020: version 1.10.1 - bug fix; zeros option of predict was ignored if ci was specified - now fixed
25jun2020: verison 1.10   - stmerlin added; wrapper function for standard survival models
                          - survival family(ggamma) added for generalised gamma AFT model
                          - bootstrap cis for family(cox) predictions sped up by adding starting values from main model
                          - eta and hratio predictions after fitting a Cox model use the delta method for cis 
                          - error check added for rp opts when !family(rp)
                          - galahad removed in prep for multistate merge
                          - help file edits
                          - bug fix; predictions error'd out following cox model, now fixed
                          - bug fix; indexing error with ltruncated() and ob level models when not all obs had ltruncation; now fixed
                          - bug fix; for family(gamma), function name mismatch meant it never got called
                          - bug fix; model specific in's ignored, now fixed
                          - bug fix; global if/in conditions were ignored, now fixed
                          - bug fix; model specific if/in conditions were not passed to starting value call and caused an error, now fixed 
                          - bug fix; if/in conditions now handled in predict - previously, any that were specified in the model were 
                            applied, which would restrict out of sample predictions, now fixed
                          - bug fix; family(user) with chfunction() error'd out - now fixed
21mar2020: version 1.9.0 - survsim added to main help file as an associated command
                         - galahad updated to 1.3.0
                                 - some behind the scenes syncing with survsim
17mar2020: version 1.8.1 - noorthog was missing from help file for family(rp,...) -> now documented
                         - galahad updated to 1.2.1:
                                 - bug fix; singleevent option failed -> now fixed
                                 - help file example fixes for new transprob option
                                 - bug fix; missing error check, Cox model is not currently supported							
07mar2020: version 1.8.0 - bug fix; when model had timevar, but predict didn't, predict erronesouly filled in outcome in timevar, for non-survival outcomes -> now fixed
                         - galahad updated to 1.2.0:
                                 - hazard option added to galahad to predict each transition-specific hazard function
                                 - survival changed to singleevent
                                 - survival now predicts transition-specific survival functions
                                 - transprob option now required to request transition probabilities
                                 - bug fix: visit with cis incorrectly returned los predictions instead -> now fixed.
                                 - bug fix: visit with standardise didn't divide by total obs -> now fixed
                                 - bug fix: contrasts with visit, new variable names were incorrect -> now fixed
                                 - bug fix: userlink, transformation not applied to point estimate when calculating CI -> now fixed
                                 - bug fix: contrasts and ci, point estimates weren't passed -> now fixed
23feb2020: version 1.7.0 - bug fix: predict cif with single survival outcome always used numerical integration, even when it was unnecessary; now fixed
                         - left truncation now supported for family(cox)
                         - almost all predictions now working for family(cox), with cis calculated using bootstrapping
                         - reps() added to predict for bootstrap cis for Cox model predictions, default 100
                         - offset() and moffset() can now both be specified in fp(), rcs() and bs() elements
                         - help file updates04feb2020: version 1.6.0 - family(cox) added
03feb2020: version 1.5.2 - improvements and bug fixes to exptorcs, now creates new variable for offset internally, with report
                         - bug fixes in ghgraph
                         - merlin help file improvements
30jan2020: version 1.5.1 - moffset() added (documented) to add the negative of an offset variable for use in rcs(), fp() and bs() elements
                         - bug fix introduced in 1.5.0 preventing ci working with predict - now fixed
                         - updates to main help file, documenting stmixed and galahad
                         - ghgraph added, including help file
28jan2020: version 1.5.0 - galahad added to the package for multi-state model predictions
21jan2020: version 1.4.0 - bug fix; merlin _t  drug, family(rp, failure(_d) df(3)) should have exited with a missing bracket error - now fixed
                         - logchazard option added to predict
04dec2019: version 1.3.0 - *ratio predictions added and documented
                         - zeros option added to predict for baseline predictions
                         - bug fix; error check added to ensure there is at least one observation per outcome, per cluster
                         - bug fix; predicting with an rp model displayed spline variable creation message, now suppressed
                         - bug fix; predicting survival at 0 when log(t) was included in a model gave a missing value - now replaced with a 1
                         - bug fix; at(), at1() amd at2() were not documented in the predict help file - now fixed.
                         - bug fix; multiple survival models and rcs() with event option caused an indexing error - now fixed
21aug2019: version 1.2.6 - internal tidying
30jun2019: version 1.2.5 - minor help file edits
                         - bug fix in predictions; cif with timevar and competing risks model caused an error when survival time was included in predictor
05jun2019: version 1.2.4 - some tidying
28may2019: version 1.2.3 - iterate() added to adaptopts(), help file for estimation updated 
24may2019: version 1.2.2 - exptorcs ado added which turns expected rates into a spline based merlin model, for Weibull et al. (Submitted)
                         - bug fix - "timevar() required" error message appeared when rcs(), fp() or bs() was specified, even when it wasn't required; now fixed
25mar2019: version 1.2.1 - bug fix; predict from a model with multiple outcomes and model specific ifs/ins errored out - now fixed
                         - bug fix; overall weights could've been specified but would have been ignored - now not allowed
18mar2019: version 1.2.0 - bug; poisson logl functions missed from build - now fixed
                         - weights() added to allow sampling weights
                         - at1() and at2() added to predict for difference predictions - h,s,cif,rmst,mu,eta difference options added
                         - bug; survival model using log time + interval censoring + left interval contained a 0, would error - now fixed
27feb2019: version 1.1.0 - bug fix; predict with ci and outcome() was ignored so defaulted to outcome(1) - now fixed
                         - doc fix for knots() with rp - does include boundary knots
                         - bug fix for starting values with gompertz which prevented fitting; now fixed
                         - family(logchazard) added for general models on the log cumulative hazard scale
                         - family(rcs) replaced with more general family(loghazard) for log hazard scale models
                         - interval censoring added -> linterval() option added to survival familys, only allowed in one model
                         - model-specific ifs or ins now allowed
07aug2018: version 1.0.7 - added error check for presence of * in predictor
                         - bug introduced in 1.0.6 stopped matching of timevar() with rcs() variable; now fixed
                         - error check on . caused merlin to error out when specifying decimal points in knots(); now fixed
27jul2018: version 1.0.6 - random now documented
                         - chazard and survival predictions missing for family(exp); now added
                         - note added to end of results table that baseline splines not shown
                         - when specifying only a random slope with no random intercept - an internal parsing error occurred; now fixed.
16may2018: version 1.0.5 - ltruncated() added for delayed-entry/left-truncation in survival models
06may2018: version 1.0.4 - bs() element added for B-spline functions
                         - minor edit to step size in numerical differentiation used in d?[] elements
                         - mf() displayed function name left over from development; now removed
                         - more error checks added
                         - bug fixes
30apr2018: version 1.0.3 - bug fix; at() was ignored in predict when ci was specified - now fixed
                         - predict, failure removed, cif is used instead
                         - predict, cif calculation improved for family(rp)
                         - predict, cif and rmst can be used with competing risks
                         - predict, ... causes() added for use with cif and rmst. If left unspecified, all survival 
                           models assumed to be cause-specific models which can be overriden by causes().
                         - predict, timelost added which is the integral of the cause-specific cif
                         - predict, totaltimelost added which is the integral of the sum of all cause-specific cifs
                         - numerical differentiation used internally improved, thanks to Mark Clements
                         - mjcerror left from megenreg
                         - documentation for adaptopts() had unavailable options - now removed
25apr2018: version 1.0.2 - predict, cif added for cumulative incidence function for competing risks models
                         - bug fix in predict, if neither fixedonly or marginal were specified, no prediction was produced
24apr2018: version 1.0.1 - predict, failure added
                         - predict, rmft added
                         - postestimation doc was incomplete for some statistics
23apr2018: version 1.0.0 - merlin released to SSC
                         - megenreg -> merlin
                         - bug fix with if statements - merlin_modeltouses_post_xb() creating tousei was giving missings not 0s. Now fixed.
                         - offset() added to fp() and rcs()
                         - error check added for . notation or ## in CLP
                         - handling of elements re-written -> @ only for constraints
                         - predict function added - fixedonly and margina allowed
                         - results help file
                         - EV now expected value of response, added XB for expected value of linear predictor
                         - random effects must be M#[]
                         - documented all utility functions
                         - results table greatly improved
                         - interactions between fp() and rcs() etc now allowed
16dec2017: version 0.1.8 - family(gamma) added
                         - bug fix in inverse links for EV functions
20nov2017: version 0.1.7 - bug fix in not documented links when using family(user)
                         - mf() element added = user-defined mata function
                         - family(rcs) added
                         - startval for @s changed from 0 to 0.0001
                         - ereturn list additions
27oct2017: version 0.1.6 - fixed output of bernoulli model, labelled equation cloglog when it should be logit (was still using logit)
                         - random effects in results table now transformed to sds and corrs, display much improved
                         - replay fixed
23oct2017: version 0.1.5 - added family(lquantile [, quantile(#)]) for linear quantile regression
                         - stable added to sort operations
20oct2017: version 0.1.4 - default cumulative hazard integration changed to 15-point Gauss-Kronrod
                         - loghfunction() added to family(user)
                         - improved error checks
19oct2017: version 0.1.3 - starting value for @ parameters changed to 0.1 in prev. release; put back to 0s
                         - minor improvements to the mlib
15oct2017: version 0.1.2 - constraints() fixed, family(null) now working with ob. level models
12oct2017: version 0.1.1 - restartvalues() added
08oct2017: version 0.1.0 - dev. release
*/

program merlin, eclass 
        version 15.1

        if replay() {
                if "`e(cmd)'" != "merlin" {
                        error 301
                }
                Display `0'
                exit
        }
		
        if substr("`0'",1,1)!="(" {
                di as error "missing bracket"
                exit 198
        }
        
        tempname GML
        capture noisily Estimate `GML' `0'
        local rc = c(rc)
        if "`c(prefix)'"!="morgana" {
                capture n mata: merlin_cleanup("`GML'")
                capture drop `GML'*
                capture mata: mata drop chazf hazf loglf
        }
        else ereturn local object "`GML'"
		
        if (`rc') {
                capture mata: merlin_cleanup("`GML'")
                capture drop `GML'*
                capture mata: mata drop chazf hazf loglf
                exit `rc'
        }
        ereturn local cmdline `"merlin `0'"'
end

program Estimate, eclass
        version 15.1
        gettoken GML : 0

        Fit `0'		//!! should leave behind diopts

		mata: merlin_ereturn("`GML'")
		
        if "`c(prefix)'"!="morgana" {
                Display, `diopts'
        }
end

program Fit, eclass sortpreserve
        version 15.1
        gettoken GML 0 : 0

        tempname touse b
        merlin_parse `GML', touse(`touse') : `0'
        if "`r(predict)'"!="" | "`c(prefix)'"=="morgana" | "`c(prefix)'"=="crossval" {
                exit
        }
        local hasopts   `"`r(hasopts)'"'
        local mltype    `"`r(mltype)'"'
        local mleval    `"`r(mleval)'"'
        local mlspec    `"`r(mlspec)'"'
        local mlopts    `"`r(mlopts)'"'
        local mlvce     `"`r(mlvce)'"'
        local mlwgt     `"`r(mlwgt)'"'
        local mlcns	`"`r(constr)'"'
        local mlinitcns	`"`r(initconstr)'"'
        local nolog     `"`r(nolog)'"'
        local mlprolog  `"`r(mlprolog)'"'
	local mftodrop  `r(mftodrop)'
        c_local diopts  `"`r(diopts)'"'
        local mlfrom    `"`r(mlfrom)'"'
        local mlzeros	`"`r(mlzeros)'"'
        local modellabels `"`r(modellabels)'"'
        if "`mlcns'" != "" {
                local cnsopt constraint(`mlcns')
        }
		
        if "`mlfrom'"!="" {
                matrix `b' = r(b)
                local mlinit init(`b',copy)
        }
        
        di
        di as txt "Fitting full model:"

        cap n ml model `mltype' `mleval'              		///
                                `mlspec'                        ///
                                `mlwgt'                         ///
                                if `touse',                     ///
                                `mlopts'                        ///
                                `mlvce'                         ///
                                `mlprolog'                      ///
                                `cnsopt'                        ///
                                `mlinit'			///
                                collinear                       ///
                                maximize     	                ///
                                missing    		        ///
                                nopreserve   	                ///
                                search(off)                     ///
                                userinfo(`GML')	                ///
                                wald(0)
                                                                                                         
        if _rc>0 {
        
                if _rc==1400 & "`mlzeros'"=="" {
                
                        di ""
                        di as text "-> Starting values failed - trying zero vector"
                
                        ml model `mltype' 	`mleval'              		///
                                                `mlspec'                        ///
                                                `mlwgt'                         ///
                                                if `touse',                     ///
                                                `mlopts'                        ///
                                                `mlvce'                         ///
                                                `mlprolog'                      ///
                                                `cnsopt'                        ///
                                                collinear                       ///
                                                maximize     	                ///
                                                missing    		        ///
                                                nopreserve   	                ///
                                                search(off)                     ///
                                                userinfo(`GML')	                ///
                                                wald(0)   	                    
                }
                else {
                        exit _rc
                }
                
        }
        
        ereturn local predict   merlin_p
        ereturn local from = "`mlfrom'"!=""
        ereturn local hasopts = `hasopts'
        ereturn local cmd merlin
        ereturn local modellabels "`modellabels'"
        cap mata: mata drop `mftodrop'
        if "`mlcns'" != "" {
                cap constraint drop `mlcns'
        }
end

program Display
        syntax [,       noHeader        ///
                        noDVHeader      ///
                        noLegend        ///
                        notable         ///
                        EFORM           ///
                        *               ///
        ]

        _get_diopts diopts, `options'
        if e(estimates) == 0 {
                local coefl coeflegend selegend
                local coefl : list diopts & coefl
                if `"`coefl'"' == "" {
                        local diopts `diopts' coeflegend
                }
        }
		
        local Nrelevels = `e(Nlevels)'-1
        
        if "`eform'"!="" {
                local exp exp prob
        }
        
        local plus
        if "`e(Nres1)'"!="" {
                local plus plus
                local neq = `e(k_eq)'
                forval l=1/`Nrelevels' {
                        local neq = `neq' - `e(Nreparams`l')'
                }
                local neq neq(`neq')
        }

        _coef_table_header
        if "`exp'"!="" {
                local coeftitle exp(b)
        }
        else    local coeftitle 
        _coef_table, neq(0) plus nocnsreport coeftitle("`coeftitle'")
        
        local spflag = 0
		
        forval mod = 1/`e(Nmodels)' {
                
                if "`e(modellabels)'"!="" {
                        local y : word `mod' of `e(modellabels)'
                }
                else {
                        local y : word 1 of `e(response`mod')'
                        if "`y'"=="" {
                                local y null
                        }
                }
                _diparm __lab__, label("`y':") eqlabel
                
                local Ncmps : word count `e(Nvars_`mod')'
                
                forval c = 1/`Ncmps' {
                
                        local clab : word `c' of `e(cmplabels`mod')'
                        local np : word `c' of `e(Nvars_`mod')'
                        if `np'>1 {
                                forval el=1/`np' {
                                        _diparm _cmp_`mod'_`c'_`el', ///
                                                label("`clab':`el'") ///
                                                `exp'
                                }
                        }
                        else {
                                _diparm _cmp_`mod'_`c'_1, label("`clab'") ///
                                                `exp'
                        }
                        
                }
                
                if `e(constant`mod')' {
                        _diparm cons`mod', label("_cons") `exp'
                }
        
                if `e(ndistap`mod')'>0 & "`e(family`mod')'"!="rp" & "`e(family`mod')'"!="aft" {
                        if "`exp'"!="" {
                                _diparm __sep__	
                        }
                        if "`e(family`mod')'"=="weibull" {
                                _diparm dap`mod'_1, label("log(gamma)") 
                        }
                        else if "`e(family`mod')'"=="gompertz" {
                                _diparm dap`mod'_1, label("gamma") 
                        }
                        else if "`e(family`mod')'"=="beta" {
                                _diparm dap`mod'_1, label("log(s)") 
                        }
                        else if "`e(family`mod')'"=="negbinomial" {
                                _diparm dap`mod'_1, label("log(alpha)") 
                        }
                        else if "`e(family`mod')'"=="gamma" {
                                _diparm dap`mod'_1, label("log(s)") 
                        }
                        else if "`e(family`mod')'"=="ggamma" {
                                _diparm dap`mod'_1, label("log(sigma)") 
                                _diparm dap`mod'_2, label("kappa") 
                        }
                        else if "`e(family`mod')'"=="gaussian" | "`e(family`mod')'"=="lquantile" {
                                _diparm dap`mod'_1, label("sd(resid.)") exp
                        }
                        else if "`e(family`mod')'"=="ordinal" {
                                forval a=1/`e(ndistap`mod')' {
                                        _diparm dap`mod'_`a', label("cut`a'")
                                }
                        }
                        else {
                                forval a=1/`e(ndistap`mod')' {
                                        _diparm dap`mod'_`a', label("dap:`a'")
                                }
                        }
                }

                if "`e(family`mod')'"=="rp" | "`e(family`mod')'"=="aft" {
                        local spflag = 1
                }
        
                if `e(nap`mod')'>0 {
                        forval a=1/`e(nap`mod')' {
                                _diparm ap`mod'_`a', label("ap:`a'")
                        }
                }
        
                if `mod'==`e(Nmodels)' & `e(Nlevels)'==1 {
                        _diparm __bot__	
                }
                else {
                        _diparm __sep__	
                }

        }		
        
        //VCV display
        if "`e(Nres1)'"!="" {
                
                forval i=1/`Nrelevels' {
                        local lev : word `i' of `e(levelvars)'
                        _diparm __lab__ , label("`lev':") eqlabel
                        
                        forval j=1/`e(Nreparams`i')' {
                                local param : word `j' of `e(re_eqns`i')'
                                local scale : word `j' of `e(re_ivscale`i')'
                                local label : word `j' of `e(re_label`i')'
                                _diparm `param', `scale' label(`label')
                        }
                        if `i'<`Nrelevels' {
                                _diparm __sep__
                        }
                }
                
                _diparm __bot__
        }
        
        if "`e(penalty)'"!="" {
                di as text " Estimation: Maximum Penalised Likelihood"
                di as text "    Penalty: `e(penalty)' with lambda = `e(lambda)'"
        }
        if `spflag' {
                di as text "    Warning: Baseline spline coefficients not shown - use ml display"
        }
        
end

exit
