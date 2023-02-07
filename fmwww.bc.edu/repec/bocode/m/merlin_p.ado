
program merlin_p, sortpreserve
        version 14.2
        local vv : display "version " string(_caller()) ":"

        tempname tname
        capture noisily `vv' Predict `tname' `0'
        local rc = c(rc)
        capture drop `tname'*
        capture mata: rmexternal("`tname'")
        exit `rc'
end

program Predict
        version 14.2
        gettoken GML 0 : 0
        syntax  anything(name=vlist)	      		                ///
                [if] [in] [,                                            ///
                                                                        ///
				OUTcome(string)		                ///
                                                                /// statistics
                                MU                                      ///
                                ETA                                     ///
                                SURVival                                ///
				TOTALSURVival		                ///
				CIF			                ///
				Hazard			                ///
				CHazard			                ///
				LOGCHazard		                ///
				RMST			                ///
				TIMELost		                ///
				TOTALTIMELost		                ///
				CAUSES(string)		                ///
				USERFunction(string)	                ///
				USER			                ///
                                                                        ///
                                FIXEDonly                               ///
                                MARGinal                                ///
				FITted			                ///
				STANDardise		                ///
				PANel(numlist max=1)	                ///
                                                                        ///
				CI			                ///
				REPS(numlist int max=1 >=10)		///
				TIMEvar(varname)			///
				LTRUNCated(varname)			///
				AT(string)				///
				ZEROs					///
									///
				REFfects				///
				RESES					///
									///
				AT1(string)				///
				AT2(string)				///
				SDIFFerence				///
				HDIFFerence				///
				CIFDIFFerence				///
				RMSTDIFFerence				///
				MUDIFFerence				///
				ETADIFFerence				///
				SRatio					///
				HRatio					///
				CIFRatio				///
				RMSTRatio				///
				MURatio					///
				ETARatio				///
									///
                                INTPoints(numlist int max=1 >0) 	///
				CHINTPoints(numlist int max=1 >15)	///	-overrides those use in estimation-
									///
				DEBUG					///	NOTDOC
				BLUPIF(string)				///
				TRANSMATrix(string)			///     NOTDOC
				TRANSPROB(numlist max=1)		///     NOTDOC
				LOS(numlist max=1)			///     NOTDOC
				OVERoutcome(string)			///     NOTDOC
				BASEHazard				///     NOTDOC
				PASSBASEH(varlist)			///     NOTDOC
				DEVCODE1(passthru)                      ///
				DEVCODE2(passthru)			///
				DEVCODE3(passthru)			///
				DEVCODE4(passthru)			///
				DEVCODE5(passthru)			///
				DEVCODE6(passthru)			///
				DEVCODE7(string)			///     predict
									///		
                        ]					        //

        local newvar `vlist'
        local devcodes `devcode1' `devcode2' `devcode3' `devcode4' `devcode5' `devcode6'
		
        if "`intpoints'" == "1" {
                di as err "invalid intpoints() option;"
                di as err "intpoints(1) is not allowed by predict"
                exit 198
        }
		
        if "`debug'"!="" {
                local noisily noisily
        }
		
        // parse statistics
        if "`transprob'"!="" {
                local tprob tprob
        }
        if "`los'"!="" {
                local tlos tlos
        }
        if "`userfunction'"!="" {
                local user user
        }
        local STAT      `mu'            	///
                        `eta'           	///
                        `survival'      	///
			`totalsurvival'		///
			`cif'			///
                        `hazard'      		///
			`chazard'      		///
			`logchazard'		///				
                        `rmst'		    	///
                        `timelost'		///
                        `totaltimelost'		///
                        `user'			///
                        `sdifference'		///
                        `hdifference'		///
                        `cifdifference'		///
                        `rmstdifference'	///
                        `mudifference'		///
                        `etadifference'		///
                        `sratio'		///
                        `hratio'		///
                        `cifratio'		///
                        `rmstratio'		///
                        `muratio'		///
                        `etaratio'		///
                        `tprob'			///
                        `tlos'			///
                        `basehazard'		///
                        `reffects'		///
                        `reses'			//
						
        opts_exclusive "`STAT'"

        if "`STAT'" == "" {
                di as txt "(option {bf:mu} assumed)"
                local STAT mu
        }

        if ("`marginal'"!="" | "`reffects'"!="" | "`reses'"!="" | "`fitted'"!="") & "`e(levelvars)'"=="" {
                di as error "marginal/reffects/reses/fitted require random effects in your model"
                exit 1986
        }
        
        if "`ltruncation'"!="" & ("`STAT'"!="survival" | "`timevar'"=="") {
                di as error "ltruncation() only allowed with survival and timevar()"
                exit 198
        }
        
        if (strpos("`STAT'","difference") | strpos("`STAT'","ratio")) & ("`at1'"=="" | "`at2'"=="") {
                di as error "at1() and at2() required with ?ratio and ?difference predictions"
                exit 198
        }
        
        if "`outcome'"!="" & "`STAT'"=="tprob" {
                di as error "outcome() not allowed with transprob()/los()"
                exit 198
        }
        
        if "`ltruncated'"!="" & "`STAT'"!="survival" & "`STAT'"!="cif" & "`STAT'"!="totalsurvival" {
                di as error "ltruncated() can only be used with survival/totalsurvival/cif"
                exit 198
        }
        
        if "`standardise'"!="" {
                if "`STAT'"=="hazard" | "`STAT'"=="hdifference" | "`STAT'"=="hratio" {
                        di as error "standardise not supported with `STAT'"
                        exit 198
                }
                if "`STAT'"=="chazard" | "`STAT'"=="chdifference" | "`STAT'"=="chratio" {
                        di as error "standardise not supported with `STAT'"
                        exit 198
                }
                if "`e(levelvars)'"!="" {
                        di as error "standardise not supported with multilevel models"
                        exit 198
                }
        }
		
        if "`e(family1)'"=="cox" {
                if ("`STAT'"=="rmst" | "`STAT'"=="rmft" | "`STAT'"=="timelost") {
                        di as error "`STAT' not currently available with family(cox)"
                        exit 198
                }
                if "`timevar'"!="" {
                        di as error "timevar() not allowed with family(cox)"
                        exit 198
                }
                if "`ltruncated'"!="" {
                        di as error "ltruncated() not allowed with family(cox)"
                        exit 198
                }
        } 
        
        if "`fitted'"!="" {
                if `e(Nlevels)'>2 {
                        di as error "fitted not supported when the model has >2 levels"
                        exit 198
                }
        }
        else {
                if "`panel'"!="" {
                        di as error "panel() only valid with fitted"
                        exit 198
                }
        }
		
        // parse options
        
        opts_exclusive "`fixedonly' `fitted' `marginal'"
        local xbtype "`fixedonly'`fitted'`marginal'"
        if "`xbtype'"=="" {
                local xbtype "fixedonly"
        }

        if ("`fitted'"!="" & "`ci'"!="") {
                di as error "fitted and ci not supported"
                exit 198
        }
        
        if "`outcome'"=="" {
                local outcome = 1
        }
        
        if "`reffects'"!="" | "`reses'"!="" {
                
                if "`e(re_dist1)'"!="normal" {
                        di as error "reffects/reses not supported with t-distributed random effects"
                        exit 198
                }
                //handle stub
                _stubstar2names `newvar', nvars(`e(Nres1)')
                local newvar `s(varlist)'	
        }
        else {
                _stubstar2names `newvar', nvars(1)
        }
        local newvar `s(varlist)'	
		
        // postestimation sample
        
        tempname touse
        if "`e(family`outcome')'"=="cox" {
                gen byte `touse' = e(sample)
        }
        else {
                mark `touse' `if' `in'
        }

        if "`timevar'"!="" {
                if "`standardise'"=="" {
                        markout `touse' `timevar'
                }
                local ptvar ptvar(`timevar')					//merlin_build_touses() updated on this
        }
        else {
                if "`e(failure`outcome')'"!="" & "`e(family`outcome')'"!="cox" {
                        local timevar : word 1 of `e(response`outcome')'
                        local ptvar ptvar(`timevar')
                        if "`standardise'"=="" {
                                markout `touse' `timevar'
                        }
                }
        }
		
        //integration method
        
        if "`e(levelvars)'"!="" {
                local Nrelevels = e(Nlevels) - 1
                forval k=1/`Nrelevels' {
                        local ims `ims' `e(intmethod`k')'
                        if "`intpoints'"=="" {
                                local ips `ips' `e(intpoints`k')'
                        }
                        else {
                                local ips `ips' `intpoints'
                        }
                }

                if ("`fitted'"!="" | "`reffects'"!="" | "`reses'"!="") & "`ims'"=="ghermite" {
                        local ims "mvaghermite"
                }
                if "`marginal'"!="" {
                        mata: st_local("ims",subinstr(st_local("ims"),"mvaghermite","ghermite"))
                }
                local intmethods intmethod(`ims')
                local intpoints intpoints(`imp')
        }
        
        if "`chintpoints'"!="" {
                local pchintpoints pchintpoints(`chintpoints')
        }
        
        if "`e(transmatrix)'"!="" | "`transmatrix'"!="" {
                if "`e(transmatrix)'"!="" {
                        tempname tmat
                        matrix `tmat' = e(transmatrix)
                        local passtmat transmatrix(`tmat')
                }
                else {
                        local passtmat transmatrix(`transmatrix')
                } 
        }
		
        //====================================================================================================================//
        
        // if Cox, get basehaz before any data is changed
        if "`e(family1)'"=="cox" {
                if "`STAT'"!="basehazard" {
                        forvalues i=1/`e(Nmodels)' {
                                tempvar baseh`i'
                                if "`passbaseh'"=="" {
                                        qui predict `baseh`i'' if `touse', ///
                                                basehazard outcome(`i')
                                }
                                else {
                                        qui gen `baseh`i'' = `: word `i' of `passbaseh''
                                }
                        }
                }
                if "`ci'"!="" & ("`STAT'"!="eta" & "`STAT'"!="hratio") {
                        //point estimates - cis below
                        predict `newvar', `STAT' `xbtype' outcome(`outcome') 	///
                                at(`at') at1(`at1') at2(`at2') 			///
                                `zeros'						///
                                timevar(`timevar') ltruncated(`ltruncated')	///
                                `devcodes' 					///
                                `standardise' overoutcome(`overoutcome')	///
                                userf(`userfunction')				///
                                `passtmat' 					///
                                `debug'                                         //
                }
        }
        
        //====================================================================================================================//
		
        local globalopts `globalopts' outcome(`outcome')
        local globalopts `globalopts' `zeros'
        local globalopts `globalopts' `devcodes'
        local globalopts `globalopts' `standardise' 
        local globalopts `globalopts' overoutcome(`overoutcome')
        local globalopts `globalopts' userfunction(`userfunction') 
        local globalopts `globalopts' panel(`panel')
        local globalopts `globalopts' blupif(`blupif')
        local globalopts `globalopts' `passtmat'
        local globalopts `globalopts' `debug' 
        
        //not included -> 
        // at(),at1(),at2()
        // timevar(),ltruncated()
			
        //====================================================================================================================//
        //Preserve data for out of sample prediction etc.
        tempfile newvars 
        preserve	

        if "`ci'"=="" {

                //zeros
                if "`zeros'" != "" {
                        foreach var in `e(allvars)' {
                                //skip response vars and those in at()
                                local todo 1
                                forvalues i=1/`e(Nmodels)' {
                                        local resp `e(response`i')'
                                        if `"`: list posof `"`var'"' in resp'"' != "0"  { 
                                                local todo 0
                                        }
                                }
                                if `"`: list posof `"`var'"' in at'"' == "0" & `todo' { 
                                        qui replace `var' = 0 if `touse'
                                }
                        }
                }
                
                //Out of sample predictions using at()
                if "`at'" != "" {
                        tokenize `at'
                        while "`1'"!="" {
                                unab 1: `1'
                                cap confirm var `1'
                                if _rc {
                                        di in red "invalid at(... `1' `2' ...)"
                                        exit 198
                                }
                                cap confirm num `2'
                                if _rc {
                                        di in red "invalid at(... `1' `2' ...)"
                                        exit 198
                                }
                                qui replace `1' = `2' if `touse'
                                mac shift 2
                        }
                }	
                
                //handle overoutcome()
                if "`overoutcome'"!="" {
                        local copyat `at'						//prevents overoutcome's at() overiding main one
                        local 0 `overoutcome'
                        syntax anything , [AT(string)]
                        confirm integer number `anything'
                        local overmodel `anything'
                        tokenize `at'
                        while "`1'"!="" {
                                unab 1: `1'
                                cap confirm var `1'
                                if _rc {
                                        di in red "invalid at(... `1' `2' ...) in overoutcome(...)"
                                        exit 198
                                }
                                cap confirm num `2'
                                if _rc {
                                        di in red "invalid at(... `1' `2' ...) in overoutcome(...)"
                                        exit 198
                                }
                                //stored and changed internally within the merlin object
                                local overatvars `overatvars' `1'
                                local overatvals `overatvals' `2'
                                mac shift 2
                        }
                        local at `copyat'						//restore
                }

                //==========================================================================================//
                                        
                if !strpos("`STAT'","difference") & !strpos("`STAT'","ratio") & "`ltruncated'"=="" {
                
                        //get coefficients and refill struct
                        tempname best
                        mat `best' = e(b)
                        
                        //remove any options
                        local cmd `e(cmdline)'
                        gettoken merlin cmd : cmd
                        gettoken cmd rhs : cmd, parse(",") bind
                        if substr("`rhs'",1,1)=="," {
                                local opts substr("`rhs'",2,.)
                                local 0 , `opts'
                                syntax , [COVariance(passthru) REDISTribution(passthru) DF(passthru) Weights(passthru) *]
                                local opts `covariance' `redistribution' `df' `weights'
                        }

                        //recall merlin
                        tempname tousem
                        quietly `noisily' merlin_parse `GML' , touse(`tousem') : `cmd'  ///
                                                             , 				///
                                        `opts'						///
                                        predict 					///
                                        predtouse(`touse')			        ///
                                        nogen 						///
                                        from(`best') 				        ///
                                        `intmethods' 				        ///
                                        `intpoints' 				        ///
                                        `pchintpoints'				        ///	
                                        `ptvar'						///
                                        `standardise'				        ///
                                        `passtmat'					///
                                        `reffects'					///
                                        `reses'						///
                                        `devcodes'					///
                                        indicator(`e(indicator)')                       ///    
                                        `debug'                                         //
                                        
                        //tidy up constraints
                        local mlcns		`"`r(constr)'"'
                        if "`mlcns'" != "" {
                                cap constraint drop `mlcns'
                        }

                        mata: merlin_predict("`GML'","`newvar'","`touse'","`STAT'","`xbtype'")

                }
                else if strpos("`STAT'","difference") {
                        
                        local diff survival
                        if "`STAT'"=="hdifference" {
                                local diff hazard
                        }
                        else if "`STAT'"=="cifdifference" {
                                local diff cif
                        }
                        else if "`STAT'"=="rmstdifference" {
                                local diff rmst
                        }
                        else if "`STAT'"=="mudifference" {
                                local diff mu
                        }
                        else if "`STAT'"=="etadifference" {
                                local diff eta
                        }
                        
                        predictnl double `newvar' = predict(`diff' `xbtype' at(`at1') timevar(`timevar') `globalopts') 	///
                                             - predict(`diff' `xbtype' at(`at2') timevar(`timevar') `globalopts')	///
                                             if `touse'
                }
                else if strpos("`STAT'","ratio") {
                        
                        local ratio survival
                        if "`STAT'"=="hratio" {
                                local ratio hazard
                                if "`e(family1)'"=="cox" {
                                        local ratio eta
                                        local timevar
                                }
                        }
                        else if "`STAT'"=="cifratio" {
                                local ratio cif
                        }
                        else if "`STAT'"=="rmstratio" {
                                local ratio rmst
                        }
                        else if "`STAT'"=="muratio" {
                                local ratio mu
                        }
                        else if "`STAT'"=="etaratio" {
                                local ratio eta
                        }
                        
                        if "`e(family1)'"=="cox" {
                                predictnl double `newvar' = exp(predict(`ratio' `xbtype' at(`at1') timevar(`timevar') `globalopts')     ///
                                                     - 	predict(`ratio' `xbtype' at(`at2') timevar(`timevar') `globalopts')) 	        ///
                                          if `touse'
                        }
                        else {
                                predictnl double `newvar' = 	predict(`ratio' `xbtype' at(`at1') timevar(`timevar') `globalopts') 	///
                                                        /       predict(`ratio' `xbtype' at(`at2') timevar(`timevar') `globalopts') 	///
                                                          if `touse'
                        }
                        
                }		
                else {
                        //ltruncated
                        if "`STAT'"=="survival" {
                                predictnl double `newvar' = predict(survival `xbtype' at(`at') timevar(`timevar') `globalopts') ///
                                                     / predict(survival `xbtype' at(`at') timevar(`ltruncated') `globalopts') 	///
                                                     if `touse'
                        }
                        else if "`STAT'"=="totalsurvival" {
                                predictnl double `newvar' = predict(totalsurvival `xbtype' at(`at') timevar(`timevar') `globalopts')    ///
                                                     / predict(totalsurvival `xbtype' at(`at') timevar(`ltruncated') 	`globalopts') 	///
                                                     if `touse'
                        }
                        else {
                                predictnl double `newvar' = (	predict(cif `xbtype' at(`at') timevar(`timevar') `globalopts')     ///
                                                     - predict(cif `xbtype' at(`at') timevar(`ltruncated') `globalopts'))          ///
                                                     / predict(totalsurvival `xbtype' at(`at') timevar(`ltruncated') `globalopts') ///
                                                     if `touse'
                        }
                }
                
                //handle special cases at time = 0, mainly for log(t) issues
                if  "`e(family1)'"!="cox" {
                        if ("`STAT'"=="survival" | "`STAT'"=="totalsurvival") & "`ltruncated'"=="" {
                                quietly replace `newvar' = 1 if `timevar'==0
                        }
                        else if ("`STAT'"=="survival" | "`STAT'"=="totalsurvival") & "`ltruncated'"!="" {
                                quietly replace `newvar' = 1 if `timevar'==`ltruncated' & !missing(`timevar')
                        }
                        else if "`STAT'"=="cif" & "`ltruncated'"!="" {
                                quietly replace `newvar' = 0 if `timevar'==`ltruncated' & !missing(`timevar')
                        }
                        else if ("`STAT'"=="cif" | "`STAT'"=="chazard"          ///
                                | "`STAT'"=="rmst" | "`STAT'"=="sdifference"    ///
                                | "`STAT'"=="cifdifference"                     ///
                                | "`STAT'"=="rmstdifference") {
                                quietly replace `newvar' = 0 if `timevar'==0
                        }
                }
                MISSMSG `newvar'

        }
        else {
                
                if "`e(family1)'"!="cox" {
                
                        if "`STAT'"=="tprob" {
                                local STAT transprob(`transprob')
                                local outcome 
                        }
                        if "`STAT'"=="tlos" {
                                local STAT los(`los')
                                local outcome 
                        }
                        
                        if "`hratio'"!="" | "`basehazard'"!="" | "`hazard'"!="" {
                                local func log(
                                local close )
                        }
                        else if "`survival'"!="" | "`totalsurvival'"!="" { 
                                local func log(-log(
                                local close ))
                        }

                        predictnl double `newvar' = `func'			                ///
                                  predict(`STAT' `xbtype' at(`at') at1(`at1') at2(`at2') 	///
                                          timevar(`timevar') ltruncated(`ltruncated')		///
                                          `globalopts')						///
                                          `close'						///
                                  if `touse', ci(`newvar'_lci `newvar'_uci)
                        if "`func'"=="log(" {
                                qui {
                                        replace `newvar' = exp(`newvar')
                                        replace `newvar'_lci = exp(`newvar'_lci)
                                        replace `newvar'_uci = exp(`newvar'_uci)
                                }
                        }
                        else if "`func'"=="log(-log(" {
                                qui {
                                        replace `newvar' = exp(-exp(`newvar'))
                                        tempvar _lci _uci
                                        gen double `_uci' = `newvar'_lci
                                        gen double `_lci' = `newvar'_uci
                                        replace `newvar'_lci = exp(-exp(`_lci'))
                                        replace `newvar'_uci = exp(-exp(`_uci'))
                                }
                                if "`ltruncated'"=="" {
                                        quietly replace `newvar' 	= 1 if `timevar'==0
                                        quietly replace `newvar'_lci 	= 1 if `timevar'==0
                                        quietly replace `newvar'_uci 	= 1 if `timevar'==0
                                }
                                else {
                                        quietly replace `newvar' = 1 if `timevar'==`ltruncated' & !missing(`timevar')
                                        quietly replace `newvar'_lci = 1 if `timevar'==`ltruncated' & !missing(`timevar')
                                        quietly replace `newvar'_uci = 1 if `timevar'==`ltruncated' & !missing(`timevar')
                                }
                        }
                }
                else {
                
                        if "`STAT'"=="eta" {
                                predictnl double `newvar' = predict(`STAT' `xbtype' at(`at') at1(`at1') at2(`at2')      ///
                                                            timevar(`timevar') ltruncated(`ltruncated')	`globalopts')	///
                                                 if `touse', ci(`newvar'_lci `newvar'_uci)	
                        }
                        else if "`STAT'"=="hratio" {
                                local timevar
                                predictnl double `newvar' = predict(eta `xbtype' at(`at1')  timevar(`timevar') `globalopts') 	///
                                                            -                                                                   ///
                                                            predict(eta `xbtype' at(`at2') timevar(`timevar') `globalopts')	///
                                                 if `touse', ci(`newvar'_lci `newvar'_uci)	
                                qui {
                                        replace `newvar' = exp(`newvar')
                                        replace `newvar'_lci = exp(`newvar'_lci)
                                        replace `newvar'_uci = exp(`newvar'_uci)
                                }
                        }	
                        else {
                        
                                //bootstrap cis
                                
                                tempname m1
                                qui est store `m1'
                                
                                tempname inits
                                mat `inits' = e(b)
                                
                                if "`reps'"=="" {
                                        local reps = 100
                                }
                                
                                _dots 0 , title("Calculating CIs via bootstrap") reps(`reps')
                                local tvar : word 1 of `e(response`outcome')'
                                forvalues r = 1/`reps' {

                                        qui gen _coreid = _n    //if `touse'

                                        bsample if `touse'
                                        
                                        if !`e(from)' {
                                                if `e(hasopt)' {
                                                        local from "from(`inits')"
                                                }
                                                else {
                                                        local from ",from(`inits')"
                                                }
                                        }
                                        
                                        capture `e(cmdline)' `from'
                                        local rc = c(rc)
                                        if `rc' {
                                                di as error "Error in bootstrap sample `r' model fit"
                                                exit `rc'
                                        }

                                        cap predict _merlin_cox, `STAT'                  ///
                                                                `xbtype'                 ///
                                                                at(`at')                 ///
                                                                at1(`at1') at2(`at2') 	 ///
                                                                timevar(`timevar')       ///
                                                                ltruncated(`ltruncated') ///
                                                                `globalopts'             //
                                        local rc = c(rc)
                                        if `rc' exit `rc'
                                        keep _coreid _merlin_cox
                                        tempfile preds`r'
                                        qui save `preds`r''
                                        restore
                                        preserve
                                        _dots `r' 0
                                        
                                }
                                
                                qui use `preds1', clear
                                forvalues r=2/`reps' {
                                        qui append using `preds`r''
                                }
                                
                                qui bys _coreid : egen `newvar'_lci = pctile(_merlin_cox), p(2.5)
                                qui bys _coreid : egen `newvar'_uci = pctile(_merlin_cox), p(97.5)
                                qui bys _coreid : keep if _n==1
                                sort _coreid
                                qui est restore `m1'
                        
                        }
                }
                
        }
			
			
        //====================================================================//
	// Restore original data and merge in new variables 

        local keep `newvar'
        if "`e(family1)'"=="cox" & ("`ci'"!="" & "`STAT'"!="eta" & "`STAT'"!="hratio") {
                local keep
        }

        if "`ci'" != "" { 
                local keep `keep' `newvar'_lci `newvar'_uci 
        }
        
        keep `keep'
        qui save `newvars'
        restore
        merge 1:1 _n using `newvars', nogenerate noreport
				
end

program MISSMSG
        tempname touse
        quietly gen byte `touse' = 1
        markout `touse' `0'
        quietly count if !`touse'
        if r(N) {
                di as txt "(`r(N)' missing values generated)"
        }
end

program FILL
        gettoken touse 0 : 0
        foreach var of local 0 {
                local gvars : char `var'[gvars]
                if "`gvars'" != "" {
                        quietly bysort `gvars' (`var') : ///
                        replace `var' = `var'[1] if `touse'
                }
                quietly replace `var' = . if !`touse'
        }
end

exit
