*! version 1.0.6  07oct2022  I I Bolotov
program define arimaauto, rclass byable(recall)
	version 15.1
	/*
		Finds the best [S]ARIMA[X] model with the help of the Hyndman-Khandakar 
		algorithm through stepwise traversing of the model space or a bulk      
		estimation. The user can choose between LLF, AIC, and SIC and pass      
		arguments to arima (estimation), hegy, dfgls, and kpss (unit root tests)
		commands. The output is consistent with (SSC) arimasel.                 

		Author: Ilya Bolotov, MBA, Ph.D.                                        
		Date: 15 January 2022                                                   
	*/
	tempname ictests icarima limits tests models vmaxLLF vminAIC vminSIC	///
			 title rspec cspec
	// check for third-party packages from SSC                                  
	cap which hegy
	if _rc {
		di as err "click to install {net sj 16-3 st0453:hegy} (dependency)"
		error 111
	}
	cap which kpss
	if _rc {
		di as err "installing {helpb kpss} (dependency)"
		ssc install kpss
	}
	// replay last result                                                       
	if replay() {
		if _by() {
			error 190
		}
		cap confirm mat r(models)
		if _rc {
			di as err "results of arimaauto not found"
			exit 301
		}
		/* copy return values                                                 */
		loc `ictests' `=r(ictests)'
		loc `icarima' `=r(icarima)'
		mat `limits'  = r(limits)
		mat `tests'   = r(tests)
		mat `models'  = r(models)
		sca `vmaxLLF' = r(maxllf)
		sca `vminAIC' = r(minaic)
		sca `vminSIC' = r(minsic)
		/* print output                                                       */
		cap confirm mat `tests'
		if ! _rc {
			loc `title' = "Unit root tests:"
			loc `rspec' = "& - `= "& " * rowsof(`tests')'"
			loc `cspec' = "& %12s | %10.0f | %5.0f | %9.6f & %9.6f & " +	///
						  "%9.6f & %9.6f &"
			matlist `tests', title(``title'') rspec(``rspec'') cspec(``cspec'')
		}
		cap confirm mat `models'
		if ! _rc {
			loc `title' = "Model space:"
			loc `rspec' = "& - `= "& " * rowsof(`models')'"
			loc `cspec' = "& %12s | %4.0f & %4.0f & %4.0f & %4.0f & " +		///
						  "%5.0f | %9.4f & %9.4f & %9.4f &"
			matlist `models', title(``title'') rspec(``rspec'') cspec(``cspec'')
		}
		di as res _n "Max LLF: Model `=`vmaxLLF''"
		di as res    "Min AIC: Model `=`vminAIC''"
		di as res    "Min SIC: Model `=`vminSIC''"
		di as res _n "Best selected based on `=ustrupper("``icarima''")':"
		arima
		/* return output                                                      */
		cap ret        loc ictests  ``ictests''
		cap ret        loc icarima  ``icarima''
		cap ret hidden mat limits = `limits'
		cap ret        mat tests  = `tests'
		cap ret        mat models = `models'
		cap ret        sca maxllf = `vmaxLLF'
		cap ret        sca minaic = `vminAIC'
		cap ret        sca minsic = `vminSIC'
		cap ret        sca N      = e(N)
		cap ret        sca np     = e(df_m) + 1
		exit 0
	}
	// syntax                                                                   
	syntax																	///
	[varlist(ts fv)] [if] [in] [iw] [,										///
		ARIMA(numlist int min=3 max=3 >-1)									///
		SARIMA(numlist int min=4 max=4 >-1)									///
		MAX(numlist int min=2 max=2 >-1)									///
		MMAX(numlist int min=2 max=2 >-1)									///
		HEGY(string asis) DFGLS(string asis) KPSS(string asis)				///
			MAXLag(numlist integer >=0 max=1)								///
		Level(cilevel) Mode(string) IC(string)								///
		STATionary noSEASonal												///
		noSTEPwise															///
			MAXModels(numlist integer >=1 max=1)							///
		INVRoot(real `=1/1.001')											///
		ITERate(int 100) TRACE(int 0) *										///
	]
	// adjust and preprocess options                                            
	loc iw        = cond(`"`weight'`exp'"' == "", "",  `"[`weight'`exp']"'     )
	loc maxlag    = cond(`"`maxlag'"'      == "", ".", `"`maxlag'"'            )
	loc maxmodels = cond(`"`maxmodels'"'   == "", ".", `"`maxmodels'"'         )
	// examine data
	qui tsset, noq
	if "`r(panelvar)'" != "" {
		di as err "command may not be used with panel data"
		exit 459
	}
	if trim(`"`seasonal'"') == "" &   ! inlist(r(unit1), ".", "q", "m") {
		di as err "hegy must be used with monthly or quarterly data"		///
		_n as txt "please check " as res "tsset" as txt " or " as res "xtset"
		exit 459
	}
	if trim(`"`seasonal'"') == "" & _N <= cond(r(unit1) == "q",  4, 12) {
		di as err "observation numbers out of range for hegy"				///
		_n as txt "must be greater than " as res cond(r(unit1) == "q", 4, 12)
		exit 459
	}
	// pass arguments to ARIMAAuto                                              
	mata: AA = ARIMAAuto()
	mata: AA.put("varlist","`varlist'"                                         )
	mata: AA.put("ifin",   `"`if' `in'"'                                       )
	mata: AA.put("iw",     `"`iw'"'                                            )
	mata: AA.put("level",  `level'                                             )
	mata: AA.put("mode",   `"`mode'"'                                          )
	mata: AA.put("ic",     `"`ic'"'                                            )
	mata: AA.put("o_hegy", `"`hegy'"'                                          )
	mata: AA.put("o_dfgls",`"`dfgls'"'                                         )
	mata: AA.put("o_kpss", `"`kpss'"'                                          )
	mata: AA.put("o_arima",`"`options'"'                                       )
	mata: AA.put("f_s",    `"`seasonal'"'   == "" ? 1 : 0                      )
	mata: AA.put("f_i",    `"`stationary'"' == "" ? 1 : 0                      )
	mata: AA.put("f_sw",   `"`stepwise'"'   == "" ? 1 : 0                      )
	mata: AA.put("f_t",    `trace'                                             )
	mata: AA.put("L",      ("`max'","`mmax'","`invroot'","`maxlag'",        ///
	                       "`maxmodels'","`iterate'")                          )
	mata: AA.put("MS",     ("`arima'","`sarima'")                              )
	// run ARIMAAuto                                                            
	mata: AA.start()
	/* get information criteria                                               */
	mata: st_local("`ictests'", AA.get("mode")                                 )
	mata: st_local("`icarima'", AA.get("ic")                                   )
	/* get limits                                                             */
	mata: st_matrix("`limits'", AA.get("L")'                                   )
	mata: if (length(AA.get("L"))) st_matrixrowstripe(                      ///
		"`limits'", (J(8,1,""),("AR","MA","MAR","MMA","invroot","lags",     ///
		                        "models","iterations")')                    ///
	);;
	mata: if (length(AA.get("L"))) st_matrixcolstripe(                      ///
		"`limits'", (J(1,1,""),("value"))                                   ///
	);;
	/* get tests                                                              */
	mata: st_matrix("`tests'",  AA.get("T")                                    )
	mata: if (length(AA.get("T"))) st_matrixrowstripe(                      ///
		"`tests'", (((""\(rows(AA.get("T")) == 1 ? J(0,1,"")              : ///
		              (subinstr(((mod(rows(AA.get("T")), 2) ? "S"         + ///
		                 strofreal(AA.get("MS")[1,7]) + "." : "") + "D") :+ ///
		                 strofreal((0::floor(rows(AA.get("T"))/2)-1)#       ///
		                 J(2,1,1)) :+ ".", "D0.", ""))))                 :+ ///
		                 "`: word 1 of `varlist''"                          ///
		            ),("HEGY",                                              ///
		            tokens("DFGLS KPSS " * floor(rows(AA.get("T"))/2)))')[  ///
		            (mod(rows(AA.get("T")), 2)?.:2::rows(AA.get("T"))+1),.] ///
	);;
	mata: if (length(AA.get("T"))) st_matrixcolstripe(                      ///
		"`tests'", (J(6,1,""),("unit root","lags","Stat",                   ///
		                       ("1%","5%","10%"):+" crit")')                ///
	);;
	/* get models                                                             */
	mata: st_matrix("`models'", AA.get("MS")[,(1,3,4,6,8,10..12)]              )
	mata: if (length(AA.get("MS"))) st_matrixrowstripe(                     ///
		"`models'", (J(rows(AA.get("MS")),1,""),                            ///
		             ("Model" :+ strofreal(1::rows(AA.get("MS")))))         ///
	);;
	mata: if (length(AA.get("MS"))) st_matrixcolstripe(                     ///
		"`models'", (J(8,1,""),("AR","MA","MAR","MMA","const","LLF",        ///
		                        "AIC","SIC")')                              ///
	);;
	/* get the best [S]ARIMA[X] model based on LLF, AIC, SIC                  */
	mata: st_numscalar(                                                     ///
		"`vmaxLLF'",                                                        ///
		selectindex(AA.get("MS")[,10] :== max(AA.get("MS")[,10]))           ///
	)
	mata: st_numscalar(                                                     ///
		"`vminAIC'",                                                        ///
		selectindex(AA.get("MS")[,11] :== min(AA.get("MS")[,11]))           ///
	)
	mata: st_numscalar(                                                     ///
		"`vminSIC'",                                                        ///
		selectindex(AA.get("MS")[,12] :== min(AA.get("MS")[,12]))           ///
	)
	// print output                                                             
	cap confirm mat `tests'
	if ! _rc {
		di as res _n "Unit root tests:"
		loc `rspec' = "& - `= "& " * rowsof(`tests')'"
		loc `cspec' = "& %12s | %10.0f | %5.0f | %9.6f & %9.6f & " +		///
					  "%9.6f & %9.6f &"
		matlist `tests', title(``title'') rspec(``rspec'') cspec(``cspec'')
	}
	cap confirm mat `models'
	if ! _rc {
		di as res _n "Model space:"
		loc `rspec' = "& - `= "& " * rowsof(`models')'"
		loc `cspec' = "& %12s | %4.0f & %4.0f & %4.0f & %4.0f & " +			///
					  "%5.0f | %9.4f & %9.4f & %9.4f &"
		matlist `models', title(``title'') rspec(``rspec'') cspec(``cspec'')
	}
	di as res _n "Max LLF: Model `=`vmaxLLF''"
	di as res    "Min AIC: Model `=`vminAIC''"
	di as res    "Min SIC: Model `=`vminSIC''"
	di as res _n "Best model based on `=ustrupper("``icarima''")':"
	arima
	// return output                                                            
	cap ret        loc ictests  ``ictests''
	cap ret        loc icarima  ``icarima''
	cap ret hidden mat limits = `limits'
	cap ret        mat tests  = `tests'
	cap ret        mat models = `models'
	cap ret        sca maxllf = `vmaxLLF'
	cap ret        sca minaic = `vminAIC'
	cap ret        sca minsic = `vminSIC'
	cap ret        sca N      = e(N)
	cap ret        sca np     = e(df_m) + 1
	// clear memory                                                             
	mata: mata drop AA
end
