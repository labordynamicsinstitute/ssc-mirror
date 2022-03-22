*! version 2.0.2  03mar2022
*! version 2.0.1  10jun2021
*! version 2.0.0  08dec2020
*! version 1.1.0  12jun2019
*! version 1.0.1  09jan2018
*! version 1.0.0  01jan2018
/*
-xtsfkk-
version 1.0.0 
January 1, 2018
Program Author: Dr. Mustafa Ugur Karakaplan
E-mail: mukarakaplan@yahoo.com
Website: www.mukarakaplan.com

Recommended Citations:

The following citations are recommended for referring to the xtsfkk
program package, underlying econometric methodology, and examples:

+ Karakaplan, Mustafa U. (2018) "xtsfkk: Stata Module for Endogenous 
Panel Stochastic Frontier Models." Available at Boston College, 
Department of Economics, Statistical Software Components (SSC) S458445.

+ Karakaplan, Mustafa U. and Kutlu, Levent (2017) "Endogeneity in Panel
Stochastic Frontier Models." Applied Economics


More Recommended Citations:

Karakaplan, Mustafa U. (2017) "Fitting Endogenous Stochastic Frontier
Models in Stata." The Stata Journal

Karakaplan, Mustafa U. and Kutlu, Levent (2017) "Handling Endogeneity in
Stochastic Frontier Analysis." Economics Bulletin

Karakaplan, Mustafa U. and Kutlu, Levent (2019) "School District
Consolidation Policies: Endogenous Cost Inefficiency and Saving
Reversals." Empirical Economics

Kutlu, Levent (2010) "Battese–Coelli Estimator with Endogenous 
Regressors." Economics Letters 
*/

program xtsfkk
	version 15
	if replay() {
		if "`2'"=="version" | "`2'"=="ver" | "`2'"=="vers" | "`2'"=="versi" | "`2'"=="versio" {
			di _n(1) "{bf:{ul:Version}}"
			di _n(1) "{txt}{sf}    xtsfkk version 2.0.1"
			di "    June 10, 2021"
			di _n(1) "{bf:{ul:Program Author}}"
			di _n(1) "    Dr. Mustafa Ugur Karakaplan"
			di `"    E-mail: {browse "mailto:mukarakaplan@yahoo.com":mukarakaplan@yahoo.com}"'
			di "    Website: {browse www.mukarakaplan.com}"
			di _n(1) "{pstd}For comments, suggestions, or questions about {cmd: xtsfkk}, please send an email to me."
			di _n(1) "{bf:{ul:Recommended Citations}}"
			di _n(1) "{pstd}The following citations are recommended for referring to the xtsfkk program package, the underlying econometric methodology, and examples: {p_end}"
			di _n(1) `"{phang}+ Karakaplan, Mustafa U. (2018) "xtsfkk: Stata Module for Endogenous Panel Stochastic Frontier Models." Available at Boston College, Department of Economics, Statistical Software Components (SSC) {browse "https://ideas.repec.org/c/boc/bocode/s458445.html":S458445}{p_end}"'
			di _n(1) `"{phang}+ Karakaplan, Mustafa U. and Kutlu, Levent (2017) "Endogeneity in Panel Stochastic Frontier Models." {browse "http://www.tandfonline.com/doi/abs/10.1080/00036846.2017.1363861":Applied Economics}{p_end}"'
			di _n(1) "{help xtsfkk##citation:{bf:{ul:More Recommended Citations}}}"
			exit
		}
		else if ("`e(cmd)'" != "xtsfkk") error 301
		Replay `0'
	}
	else {
		nobreak {
			local mats = c(matsize)
			local ados = c(adosize)
			local nice = c(niceness)
			local mataf = c(matafavor)
			local matac = c(matacache)
			
			capture set matsize `=cond(c(SE)=0, 800, 11000)'
			capture set matsize `=cond(c(MP)=0, 11000, 65534)'
			capture set adosize 10000
			capture set niceness 0
			capture mata: mata set matafavor speed
			capture mata: mata set matacache 5000
			
			capture noisily break Estimate `0'
			
			capture set matsize `mats'
			capture set adosize `ados'
			capture set niceness `nice'
			capture mata: mata set matafavor `mataf'
			capture mata: mata set matacache `matac'
		}
	}
end

program uwfilter, rclass
		syntax varlist(fv ts), [noCONStant]
		return local het = "`varlist'"
		return local fvops = "`s(fvops)'"
		if ("`constant'"!="noconstant") return local nocons = 0
		else return local nocons = 1
end

program Estimate, eclass
	syntax varlist(min=2 fv ts) [pweight fweight iweight aweight] [if] [in], ///
	[noCONStant COST PRODuction Uhet(string) Whet(string)  ///
	ENdogenous(varlist fv ts) Instruments(varlist fv ts) EXogenous(varlist fv ts) LEAVEout(varlist fv ts)  ///
	INITial(string) DELVE FAST SAVE(string) LOAD(string) ///
	EFFiciency(string) TEST TIMER BEEP1 BEEP2(integer 0) DIFficult ITERate(string) TECHnique(string) ///
	HEADER COMPare NICEly MLDISplay(string) NOMESSage ] 
	
	if ("`timer'"!="") {
		local time1 = clock(c(current_time),"hms")
		local day1 = date(c(current_date),"DMY")
	}

	marksample touse
	
	eret clear
	
	local fvops = "`s(fvops)'"
	local tsops = "`s(tsops)'"
		
	capture xtset
	if (_rc!=0) {
		di as error "{p} Use {bf:xtset} to specify panel and time variables"
		error _rc
	}
	else {
		local PV = r(panelvar)
		local TV = r(timevar)
	}	
	
	gettoken lhs frontier : varlist
	_fv_check_depvar `lhs'
	
	if "`weight'" != "" local wgt "[`weight'`exp']"
	
		
	local porc = "production" //default is production frontier
	local torc = "tech"
	tempvar prod
	scalar `prod' = 1
	if ("`production'" !="" & "`cost'" !="") {
		di as error "{p}Specify either {bf:{ul:prod}uction} or {bf:{ul:cost}}. Do not specify both."
		error 198
	}
	else if ("`cost'" !="") {
		local porc = "cost"
		local torc = "cost"
		scalar `prod' = -1
	}
	
	//clean strings
	foreach x in lhs frontier uhet whet endogenous instruments exogenous leaveout { //allexogenous {
		local `x': list retokenize `x'
		local `x': list uniq `x'
	}

	//convert uhet whet strings to varlists
	if ("`uhet'"!="") {
		uwfilter `uhet'
		local uhet = r(het)
		if ("`fvops'" != "true") local fvops = "`r(fvops)'"
		local unocons = r(nocons)
	}
	else local unocons = 0
	
	if ("`whet'"!="") {
		uwfilter `whet'
		local whet = r(het)
		if ("`fvops'" != "true") local fvops = "`r(fvops)'"
		local wnocons = r(nocons)
	}
	else local wnocons = 0
		

	if(strpos("`technique'","bhhh")!= 0 & "`fast'"=="") {
		di as error "{p}bhhh technique is only allowed with the {bf:fast} option."
		error 198
	}
	
	if ("`nomessage'"=="") {
		capture estimates drop ModelEN
		capture estimates drop ModelEX
	}

	local exo=0
	if (("`endogenous'"=="" | "`instruments'"=="")) { 
		if ("`nomessage'"=="") di as error "{p}Specify both {bf:{ul:en}dogenous()} and {bf:{ul:i}nstruments()} to analyze the endogenous model."
		local exo=1		
		di _n(2) in red "Analyzing the exogenous model (Model EX)..." _n(1)
	}
	

	if (`exo'==0) {
		local EE="Endogenous"
		local EEE="En"
		local WV="lnsig2w"
	}
	else {
		local EE="Exogenous"
		local EEE="Ex"
		local WV="lnsig2v"
	}

	if ("`efficiency'"!="") {
		tokenize "`efficiency'", parse(",", " ") 
		if ("`2'"!="," & "`2'"!="") {
			di as error "{p}Too many efficiency variables are specified to be generated."
			error 103
		}
		if ("`3'"!="replace" & `exo'==0) {
			capture confirm variable `1'_EN, exact
			if !_rc {
				di as error "{p}`1'_EN is specified to be the efficiency variable but the variable is already in the data. Either specify a new efficiency variable or specify the {bf:replace} option."
				error 110
			}
		}
		if ("`3'"!="replace" & (`exo'==1 | "`compare'"!="")) {
			capture confirm variable `1'_EX, exact
			if !_rc {
				di as error "{p}`1'_EX is specified to be the efficiency variable but the variable is already in the data. Either specify a new efficiency variable or specify the {bf:replace} option."
				error 110
			}
		}
		local effvar = "`1'"
	}

	if ("`instruments'"!="") {
		forvalues j = 1/`=wordcount("`instruments'")' {
			if (strpos("`frontier'", "`=word("`instruments'", `j')'") != 0) {
				di as error "{p}Instrumental variable `=word("`instruments'", `j')' is specified as a frontier variable."
				error 110			
			}
			if (strpos("`uhet'", "`=word("`instruments'", `j')'") != 0) {
				di as error "{p}Instrumental variable `=word("`instruments'", `j')' is specified as a uhet variable."
				error 110			
			}
			if (strpos("`whet'", "`=word("`instruments'", `j')'") != 0) {
				di as error "{p}Instrumental variable `=word("`instruments'", `j')' is specified as a whet variable."
				error 110			
			}
			if (strpos("`endogenous'", "`=word("`instruments'", `j')'") != 0) {
				di as error "{p}Instrumental variable `=word("`instruments'", `j')' is specified as an endogenous variable."
				error 110			
			}					
			if (strpos("`exogenous'", "`=word("`instruments'", `j')'") != 0 | strpos("`leaveout'", "`=word("`instruments'", `j')'") != 0) {
				di as error "{p}Instrumental variable `=word("`instruments'", `j')' is specified as an included exogenous variable."
				error 110			
			}					
		}			
	}
	
	if ("`exogenous'" !="" & "`leaveout'" !="") {
		di as error "{p}Specify either {bf:{ul:ex}ogenous({it:exovarlist})} or {bf:{ul:leave}out({it:lovarlist})}. Do not specify both."
		error 198
	}
	
	local p = wordcount("`endogenous'")		

	forvalues j = 1/`p' {
		if (strpos("`frontier'", "`=word("`endogenous'", `j')'") ==0) {
			if (strpos("`uhet'", "`=word("`endogenous'", `j')'") ==0) {
				di as error "{p}`=word("`endogenous'", `j')' is specified as an endogenous variable but not specified as a frontier or uhet variable."
				error 198
			}
		}
	}
	
	// form allexogenous
	if ("`exogenous'"=="") {
		local allexogenous "`frontier' `uhet' `whet'"
		local leftout = wordcount("`leaveout'")
		forvalues j = 1/`leftout' {
			local allexogenous : subinstr local allexogenous "`=word("`leaveout'", `j')'" "", word all
		}
		local allexogenous "`instruments' `allexogenous'"		
	}
	else local allexogenous "`instruments' `exogenous'"

	forvalues j = 1/`p' {
		local allexogenous : subinstr local allexogenous "`=word("`endogenous'", `j')'" "", word all
	}

	local allexogenous: list retokenize allexogenous
	local allexogenous: list uniq allexogenous


	
	
	
	if ("`fvops'" == "true") {
		tempname mo
		foreach x in frontier uhet whet allexogenous {
			_rmcoll ``x'', `constant' expand
			local cnames `r(varlist)'
			local bp: word count `cnames'
			if (("`x'"=="frontier") & ("`constant'"!="noconstant")) | ///
				(("`x'"=="uhet") & (`unocons'!=1)) | ///
				(("`x'"=="whet") & (`wnocons'!=1)) | ///
				("`x'"!="frontier" & "`x'"!="uhet" & "`x'"!="whet") {
				local bp = `bp' + 1 //this is for the constant in the eq
				local cons _cons
			}
			else local cons //empty
			tempname b_`x' mo_`x'
			matrix `b_`x'' = J(1, `bp', 0)
			matrix colnames `b_`x'' = `cnames' `cons' //this line is needed for the next line
			_ms_omit_info `b_`x''
			matrix `mo_`x'' = r(omit)
		}
		matrix `mo' = `mo_frontier', `mo_uhet', `mo_whet'
		forvalues j = 1/`p' {
			matrix `mo' = `mo', `mo_allexogenous'
		}
		if (`p'!=0) matrix `mo' = `mo', J(1, `=`p'+(`p'*`p'+1)/2',0)
	}
	
	markout `touse' `lhs' `frontier' `uhet' `whet' `endogenous' `instruments' `allexogenous'

	if("`header'"!="") {
		di _n(2) in red "{p}{sf:`c(current_date)'  `c(current_time)'}" 
		di _n(2) in red "{p}{sf:`=upper("`EE' Panel Stochastic `porc' Frontier Model (Model `EEE')")'}"
		di _n(1) in red "{p}{sf:Dependent Variable:} " as text "`lhs'"			
		di _n(1) in red "{p}{sf:Frontier Variable`=cond(`=wordcount("`frontier'")'+`=cond("`constant'"!="noconstant",1,0)'>1,"s","")':} " as text "`=cond("`constant'"!="noconstant","Constant ","")'`frontier'"
		di _n(1) in red "{p}{sf:U Variable`=cond(`=wordcount("`uhet'")'+`=cond(`unocons'!=1,1,0)'>1,"s","")':} " as text "`=cond(`unocons'!=1,"Constant ","")'`uhet'"
		di _n(1) in red "{p}{sf:W Variable`=cond(`=wordcount("`whet'")'+`=cond(`wnocons'!=1,1,0)'>1,"s","")':} " as text "`=cond(`wnocons'!=1,"Constant ","")'`whet'"
		di _n(1) in red "{p}{sf:Endogenous Variable`=cond(`=wordcount("`endogenous'")'>1,"s","")':} " as text "`endogenous'"
		di _n(1) in red "{p}{sf:Added Instrument`=cond(`=wordcount("`instruments'")'>1,"s","")':} " as text "`instruments'"
		di _n(1) in red "{p}{sf:Exogenous Variable`=cond(`=wordcount("`allexogenous'")'>1,"s","")':} " as text "`allexogenous'{p_end}"
		capture xtset
		di _n(1) in red "{p}Panel Variable: " as text "`r(panelvar)'"
		di _n(1) in red "{p}Time Variable: " as text "`r(timevar)'" _n(2)
	}

	
	if("`load'"!="" & "`delve'"!="") {
   		di _n(1) in red "The {bf:load} option overrides the {bf:delve} option." 
	}
	
	if("`load'"!="" & "`initial'"!="") {
   		di _n(1) in red "The {bf:load} option overrides the {bf:initial} option." 
	}

	if("`load'"=="" & "`initial'"!="" & "`delve'"!="") { 
	    di _n(1) in red "The {bf:initial} option overrides the {bf:delve} option." 
	}
	
	if("`load'"=="" & "`initial'"=="" & "`delve'"!="") { 
		di _n(1) in red "Delving into the problem..." 
	
		forvalues j = 1/`p' {
			capture regress `=word("`endogenous'", `j')' `allexogenous'  `wgt' if `touse'
			tempvar `=word("`endogenous'", `j')'_res
			predict ``=word("`endogenous'", `j')'_res', res
			tempname B`=`j'+1'
			matrix `B`=`j'+1''=e(b)
		}
		
		local wc1 = wordcount("`frontier'")
		local wc2 = wordcount("`uhet'")
		local wc3 = wordcount("`whet'")
		
		local f_res = ""
		forvalues j = 1/`wc1' {
			capture confirm variable ``=word("`frontier'", `j')'_res'
			if !_rc local f_res = "`f_res'``=word("`frontier'", `j')'_res' " //which frontier vars has a _res
		}
		
		local u_res = ""
		forvalues j = 1/`wc2' {
			capture confirm variable ``=word("`uhet'", `j')'_res'
			if !_rc local u_res = "`u_res'``=word("`uhet'", `j')'_res' " //which uhet vars has a _res
		}

		local w_res = ""
		forvalues j = 1/`wc3' {
			capture confirm variable ``=word("`whet'", `j')'_res' //which whet vars has a _res
			if !_rc local w_res = "`w_res'``=word("`whet'", `j')'_res' "
		}
		
		tempname B1
		capture xtsfkk `lhs' `frontier' `f_res' `wgt' if `touse', `porc' u(`u_res' `uhet') w(`whet') `constant' `fast' iter(50)  //nomess //tech(bfgs dfp ) 
		matrix `B1'=e(b)
		
		tempname C
		matrix `C' = (`B1'["y1","frontier_`lhs':`=word("`frontier'", 1)'".."frontier_`lhs':`=word("`frontier'", `wc1')'"])
		if("`constant'"!="noconstant") matrix `C' = (`C',`B1'["y1","frontier_`lhs':_cons"])
		matrix `C' = (`C',`B1'["y1","lnsig2u:`=word("`uhet'", 1)'".."lnsig2u:`=word("`uhet'", `wc2')'"])
		matrix `C' = (`C',`B1'["y1","lnsig2u:_cons"])
		matrix `C' = (`C',`B1'["y1","lnsig2v:`=word("`whet'", 1)'".."lnsig2v:`=word("`whet'", `wc3')'"])
		forvalues j = 1/`p' {
			matrix `C' = (`C',`B`=`j'+1'')
			matrix `C' = (`C', runiform(-1,1))
		}
		forvalues j = 1/`=(`p'*(`p'+1))/2' {
			matrix `C' = (`C', runiform(-1,1))
		}
	local initial "`C'"			
	}		
	
	if ("`save'"!="") {
		capture matin4
		if (_rc==199) capture ssc install matin4-matout4
		local savedmatrix = "`save'"
		capture copy "`savedmatrix'" "`savedmatrix'.old", replace
	}
	
	if ("`load'"!="") {
		capture matin4
		if (_rc==199) capture ssc install matin4-matout4
		matin4 loadedmatrix using "`load'"
		local initial "loadedmatrix"
	}
	
	

	
	
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
		
	mata {
		M = moptimize_init()
		
		moptimize_init_touse(M, "`touse'")
		
		if (`exo'==0) moptimize_init_valueid(M, "Model EN log likelihood")
		else moptimize_init_valueid(M, "Model EX log likelihood")

		PV = st_data(., "`PV'", "`touse'") //the panel variable
		moptimize_init_by(M,PV)
		
		
		if ("`fast'"=="") {
			moptimize_init_evaluatortype(M,"d0")
			moptimize_init_userinfo(M,2,0) //fast route
		}
		else {
			moptimize_init_evaluatortype(M,"gf0") //lf0
			moptimize_init_userinfo(M,2,1) //fast route
		}

		moptimize_init_userinfo(M,3,`p') //p = number of endogenous variables
		V = panelsetup(PV, 1)
		
		Ti = V[,2] - V[,1] :+ 1
		moptimize_init_userinfo(M,4,Ti) //count of id
		moptimize_init_userinfo(M,5,V) //2 column matrix first-last obs of id
		moptimize_init_userinfo(M,6,st_numscalar("`prod'")) //prod or cost

		moptimize_init_userinfo(M,8,rows(PV)) //count of nonempty observations sample
		
		if (`exo'==0) moptimize_init_evaluator(M, &xtsfkk_ugur())
		else moptimize_init_evaluator(M, &xtsfkk_ugurex())
	
		moptimize_init_depvar(M,1,"`lhs'") //M_y
		
		moptimize_init_eq_indepvars(M,1,"`frontier'") //xb
		moptimize_init_eq_name(M,1,"frontier_`lhs'")
		if ("`constant'"=="noconstant") moptimize_init_eq_cons(M,1, "off")

		moptimize_init_eq_indepvars(M,2,"`uhet'") //uhet
		moptimize_init_eq_name(M,2,"lnsig2u")
		if (`unocons'==1) moptimize_init_eq_cons(M,2, "off")

		moptimize_init_eq_indepvars(M,3,"`whet'") //whet
		moptimize_init_eq_name(M,3,"`WV'")
		if (`wnocons'==1) moptimize_init_eq_cons(M,3, "off")

		if (`exo'==0) {
		    
			for (j=1; j<=`p'; j++) { //`p' number of endogenous variables
				moptimize_init_depvar(M,j+1,tokens("`endogenous'")[j]) //M_yz#

				moptimize_init_eq_indepvars(M,j+3,"`allexogenous'") //zd#
				moptimize_init_eq_name(M,j+3,"ivr"+strofreal(j)+"_"+subinstr(tokens("`endogenous'")[j],".","_"))
								
				moptimize_init_eq_freeparm(M,j+3+`p',"on") //eta#
				moptimize_init_eq_name(M,j+3+`p',"eta"+strofreal(j)+"_"+subinstr(tokens("`endogenous'")[j],".","_"))
			}
			
			for (j=1; j<=(`p'^2+`p')/2; j++) {
				moptimize_init_eq_freeparm(M,j+3+2*`p',"on") //le#
				moptimize_init_eq_name(M,j+3+2*`p',"le"+strofreal(j))
			}
		}

		if ("`fvops'" == "true") {
			mo_v = st_matrix("`mo'")
			p = cols(mo_v)
			ko = sum(mo_v)
			if (ko>0) {
				Ct = J(0, p, .)
				for(j=1; j<=p; j++) {
					if (mo_v[j]==1) {
						Ct  = Ct \ e(j, p)
					}
				}
				Ct = Ct, J(ko, 1, 0)
			}
			else Ct = J(1,p,0)
			moptimize_init_constraints(M, Ct) 
		}
		
		if ("`technique'"=="") moptimize_init_technique(M, "bfgs")
		else moptimize_init_technique(M, "`technique'")

		if ("`difficult'"=="") moptimize_init_singularHmethod(M,"m-marquardt")
		else moptimize_init_singularHmethod(M,"hybrid") //difficult

		if("`fast'"=="") { //when fast is not specified
			moptimize_init_conv_ptol(M, 1e-4)    //D:1e-6  //ML:1e-4
			moptimize_init_conv_vtol(M, 0)  	 //D:1e-7  //ML:0
			//moptimize_init_conv_nrtol(M, 1e-5) //D:1e-5
			moptimize_init_conv_ignorenrtol(M,"off") //off
		}
		else {
			moptimize_init_conv_ptol(M, 1e-3) 
			moptimize_init_conv_vtol(M, 1e-7) 
			moptimize_init_conv_nrtol(M, 1e-4)
			moptimize_init_conv_ignorenrtol(M,"on") //off
		}

		if ("`initial'"!="") moptimize_init_coefs(M, st_matrix("`initial'")) //HELP'te YOK!!!!

		if ("`iterate'"=="") moptimize_init_conv_maxiter(M,16000)
		else moptimize_init_conv_maxiter(M,`iterate')

		moptimize_init_conv_warning(M, "on")
		moptimize_init_tracelevel(M, "value")
		
		moptimize(M)
		moptimize_result_post(M)
		
		st_numscalar("e(converged)", moptimize_result_converged(M))
		st_numscalar("e(ll)", moptimize_result_value(M))
		st_numscalar("e(k_autoCns)", ko) //this is not to view the omitted constraints

		}

********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************

if e(converged)==0 di in red "Model did NOT converge!"
else di in red "Model converged!"

	eret local cmd "xtsfkk"
	eret local cmdbase "ml"
	
	if (`exo'==0) {
		estimates title: Model EN
		estimates store ModelEN
		eret scalar NEN = e(N)
		eret scalar llEN = e(ll)
		
		if ("`nicely'"=="") { 
			di _n(2) "{bf:`EE' stochastic `=substr("`porc'",1,4)' frontier model with normal/half-normal specification}"
			ml display, neq(`=`p'*2+3') `mldisplay'		//+3 for les
		}			
		else {
			local NEN = trim("`: di %16.0f e(NEN)'")
			local llEN = trim("`: di %16.2f e(llEN)'")
			local etalist = ""
			forvalues j = 1/`p' {
				local ivin = subinstr(word("`endogenous'", `j'),".","_",.)
				local beta`j': di %4.3f round(_b[/:eta`j'_`ivin'],0.001)
				local seta`j': di %4.3f round(_se[/:eta`j'_`ivin'],0.001)
				tempname peta`j'
				scalar `peta`j''= (2 * ttail(10^16,abs(_b[/:eta`j'_`ivin']/_se[/:eta`j'_`ivin'])))
				local steta="   "
				if (scalar(`peta`j'')<0.001) local steta="***"
				else if (scalar(`peta`j'')<0.01) local steta="** "
				else if (scalar(`peta`j'')<0.05) local steta="*  "
				else if (scalar(`peta`j'')<0.10) local steta="`=cond(c(stata_version)<14,"+","`=uchar(8224)'")'  "
				local rmargin=55 //if with compare `tw'-(`cw'+1) 64-9
				if ("`compare'"=="") local rmargin=34 // 43-9
				if (`j'!=`p') local etalist = "`etalist'" + ///
					"{bf:`=abbrev("eta`j' (`=word("`endogenous'", `j')')",22)'}" + ///
					"{ralign `=`rmargin'-`=strlen("`=abbrev("eta`j' (`=word("`endogenous'", `j')')",22)'")'':{bf:`beta`j''`steta'}}" + ///
					"{ralign 9:{bf:(`seta`j'')}}" + "{break}"
				if (`j'==`p') local etalist = "`etalist'" + ///
					"{bf:`=abbrev("eta`j' (`=word("`endogenous'", `j')')",22)'}" + ///
					"{ralign `=`rmargin'-`=strlen("`=abbrev("eta`j' (`=word("`endogenous'", `j')')",22)'")'':{bf:`beta`j''`steta'}}" + ///
					"{ralign 9:{bf:(`seta`j'')}}"
			}
		}		
		
		if ("`test'"!="" | "`nicely'"!="") {
			local etaeq = ""
			forvalues j = 1/`p' {
				local ivin = subinstr(word("`endogenous'", `j'),".","_",.)
				local etaeq "`etaeq'[/]eta`j'_`ivin' "	
			}			
			if ("`nicely'"=="") {
				di _n(2) "{bf:{center 64:eta Endogeneity Test}}"
				di "{hline 64}"
				di "Ho: Correction for endogeneity is not necessary."
				di "Ha: There is endogeneity in the model and correction is needed."
				test "`etaeq'"
				if (r(p)<0.001) di _n(1) "{bf:Result: Reject Ho at 0.1% level.}"
				else if (r(p)<0.01) di _n(1) "{bf:Result: Reject Ho at 1% level.}"
				else if (r(p)<0.05) di _n(1) "{bf:Result: Reject Ho at 5% level.}"
				else if (r(p)<0.1) di _n(1) "{bf:Result: Reject Ho at 10% level.}"
				else di _n(1) "{bf:Result: Cannot reject Ho at 10% level.}"
			}
			else capture test "`etaeq'"
			local etatestp : di %5.3f r(p)
			local etatestX2 : di %4.2f r(chi2)
			eret scalar etatestp = r(p)
			eret scalar etatestX2 = r(chi2)
		}						
		
		if ("`efficiency'"!="" | "`nicely'"!="") {
			tempvar term1 eit eit2 Ti eidot2 hit2 hidot2 exh eidothidot lnsigu2 lnsigw2 xb muistar sigistar ENeff
			quietly {
				gen double `term1' = 0  if `touse'
				forvalues j = 1/`p' {
					tempvar zd`j' epsilon`j'
					tempname eta`j'
					local ivin = subinstr(word("`endogenous'", `j'),".","_",.)
					scalar `eta`j'' = _b[/:eta`j'_`ivin']
					predict double `zd`j''  if `touse', xb equation(ivr`j'_`ivin')
					gen double `epsilon`j'' = `=word("`endogenous'", `j')' - `zd`j'' if `touse'
					replace `term1' = `term1' +  scalar(`eta`j'') * `epsilon`j''  if `touse'
				}
				predict double `lnsigu2' if `touse', xb equation(lnsig2u)
				predict double `lnsigw2' if `touse', xb equation(lnsig2w)
				predict double `xb' if `touse', xb equation(frontier_`lhs')
				gen double `eit' = `lhs' - `xb' - `term1'  if `touse'
				sort `PV' `TV'
				by `PV': egen double `Ti' = count(`TV') if `touse'
				gen double `eit2' = `eit'^2 if `touse'
				by `PV': egen double `eidot2' = total(`eit2') if `touse'			
				gen double `hit2' = exp(`lnsigu2') / exp(_b[lnsig2u:_cons])  if `touse'
				by `PV': egen double `hidot2' = total(`hit2') if `touse'
				gen double `exh' = `eit' * sqrt(`hit2') if `touse'
				by `PV': egen double `eidothidot' = total(`exh') if `touse'				
				gen double `muistar' = ((- (scalar(`prod') * exp(_b[lnsig2u:_cons])*`eidothidot'))/(exp(_b[lnsig2u:_cons])*`hidot2'+exp(_b[lnsig2w:_cons]))) if `touse'
				gen double `sigistar' = sqrt((exp(_b[lnsig2u:_cons])*exp(_b[lnsig2w:_cons]))/(exp(_b[lnsig2u:_cons])*`hidot2'+exp(_b[lnsig2w:_cons]))) if `touse'
				gen double `ENeff' = exp( -sqrt(`hit2') * ( `muistar' + ((`sigistar' * normalden(`muistar'/`sigistar'))/normal(`muistar'/`sigistar')))) if `touse'
				if ("`efficiency'"!="") {
					capture drop `effvar'_EN			
					gen double `effvar'_EN=`ENeff'  if `touse'
				}
			}
			if ("`nicely'"=="") {
				capture summ `ENeff' `wgt' if `touse', d
				di _n(2) "{bf:{center 50:Summary of Model EN `=proper("`torc'")' Efficiency}}"
				di "{hline 50}"
				di "{txt}Mean Efficiency{tab}{tab}" r(mean)
				di "Median Efficiency{tab}" r(p50)
				di "Minimum Efficiency{tab}" r(min)
				di "Maximum Efficiency{tab}" r(max)
				di "Standard Deviation{tab}" r(sd)				
				di _n(1) "where"
				di "0 = Perfect `torc' inefficiency"
				di "1 = Perfect `torc' efficiency"				
			}
			else capture summ `ENeff' `wgt' if `touse', d
			eret scalar meaneffEN = r(mean)
			eret scalar medeffEN = r(p50)
			local meaneffEN : di %6.4f e(meaneffEN)
			local medeffEN : di %6.4f e(medeffEN)
		}
	
		if ("`compare'"!="") {
			xtsfkk `lhs' `frontier' `wgt' if `touse', `porc' u(`uhet') w(`whet') `constant' `difficult' iter(`iterate') tech(`technique') `nicely' eff(`efficiency') nomess //noref
		}
	
		if ("`compare'"!="" & "`nicely'"!="") {
			local NEX = trim("`: di %16.0f e(NEX)'")
			local llEX = trim("`: di %16.2f e(llEX)'")
			local meaneffEX : di %6.4f e(meaneffEX)
			local medeffEX : di %6.4f e(medeffEX)
			local vw = 22 //variable name width
			local cw = 8 //column width
			local tw = `vw' + 1 + `cw' + 3 + 1 + `cw' + 1 + `cw' + 3 + 1 + `cw' //table width
			if("`constant'"!="noconstant") local firsteq="#1:_cons #1:* "
			else local firsteq="#1:* "
			capture di _b[lnsig2u:_cons]
			if (_rc!=111) local secondeq="lnsig2u:_cons lnsig2u:*"
			else local secondeq="lnsig2u:*"
			capture di _b[lnsig2v:_cons]
			if (_rc!=111) local thirdeq="lnsig2v:_cons lnsig2v:* lnsig2w:_cons lnsig2w:*"
			else local thirdeq="lnsig2v:* lnsig2w:*"
			capture estout
			if (_rc==199) capture ssc install estout
			if (c(stata_version)<14) local eql ""Dep.var: `lhs'" "Dep.var: ln(sigma`=char(178)'_u)" "Dep.var: ln(sigma`=char(178)'_v)" "Dep.var: ln(sigma`=char(178)'_w)""
			else version 14: local eql ""Dep.var: `lhs'" "Dep.var: ln(`=uchar(963)'`=uchar(178)'_u)" "Dep.var: ln(`=uchar(963)'`=uchar(178)'_v)" "Dep.var: ln(`=uchar(963)'`=uchar(178)'_w)""
			estout ModelEX ModelEN, ///
				title({bf:Table: Estimation Results})  ///
				mlabels("       Model EX" "       Model EN", span) ///
				collabel(none) ///
				varwidth(`vw') ///
				modelwidth(`cw') ///
				equations(1:1) ///
				starlevels(`=cond(c(stata_version)<14,"+","`=uchar(8224)'")' 0.10 * 0.05 ** 0.01 *** 0.001) ///
				cells("b(star fmt(3)) se(par fmt(3))") ///
				keep(#1: lnsig2u: lnsig2v: lnsig2w:) ///
				order(`firsteq' `secondeq' `thirdeq') ///
				varlabels(_cons Constant) ///
				eqlabel( `eql' , span)			
			di "`etalist'"
			di "{hline `tw'}"
			di "eta Endogeneity Test  " ///
				"{bf:{ralign `=1+`cw'+3+1+`cw'+1+`cw'+3':X2=`etatestX2'}{ralign `=1+`cw'':p=`etatestp'}}"
			di "{hline `tw'}"
			di "Observations          " ///
				"{space 2}{bf:{center `=`cw'+3+1+`cw'':`NEX'}{space 1}{center `=`cw'+3+1+`cw'':`NEN'}}" 
			di "Log Likelihood        " ///
				"{space 2}{bf:{center `=`cw'+3+1+`cw'':`llEX'}{space 1}{center `=`cw'+3+1+`cw'':`llEN'}}" 
			di "Mean " substr(proper("`torc'"),1,4) " Efficiency  " ///
				"{space 2}{bf:{center `=`cw'+3+1+`cw'':`meaneffEX'}{space 1}{center `=`cw'+3+1+`cw'':`meaneffEN'}}" 
			di "Median " substr(proper("`torc'"),1,4) " Efficiency" ///
				"{space 2}{bf:{center `=`cw'+3+1+`cw'':`medeffEX'}{space 1}{center `=`cw'+3+1+`cw'':`medeffEN'}}" 
			di "{hline `tw'}"
			di "{p 0 0 0 `tw'}Notes: Standard errors are in parentheses. Symbols indicate significance at the {bind:0.1% (***)}, {bind:1% (**)}, {bind:5% (*),} and {bind:10% (`=cond(c(stata_version)<14,"+","`=uchar(8224)'")')} levels."
			di "{hline `tw'}"			
		}
	
		if ("`compare'"=="" & "`nicely'"!="") {
			local vw = 22 //variable name width
			local cw = 8 //column width
			local tw = `vw' + 1 + `cw' + 3 + 1 + `cw' //table width
			if("`constant'"!="noconstant") local firsteq="#1:_cons #1:*"
			else local firsteq="#1:*"
			capture di _b[lnsig2u:_cons]
			if (_rc!=111) local secondeq="lnsig2u:_cons lnsig2u:*"
			else local secondeq="lnsig2u:*"
			capture di _b[lnsig2w:_cons]
			if (_rc!=111) local thirdeq="lnsig2w:_cons lnsig2w:*"
			else local thirdeq="lnsig2w:*"
			capture estout
			if (_rc==199) capture ssc install estout
			if (c(stata_version)<14) local eql ""Dep.var: `lhs'" "Dep.var: ln(sigma`=char(178)'_u)" "Dep.var: ln(sigma`=char(178)'_w)""
			else local eql ""Dep.var: `lhs'" "Dep.var: ln(`=uchar(963)'`=uchar(178)'_u)" "Dep.var: ln(`=uchar(963)'`=uchar(178)'_w)""
			estout ModelEN, ///  
				title({bf:Table: Estimation Results})  ///
				mlabels("       Model EN", span) ///  
				collabel(none) ///
				varwidth(`vw') ///
				modelwidth(`cw') /// 
				equations(1) ///
				starlevels(`=cond(c(stata_version)<14,"+","`=uchar(8224)'")' 0.10 * 0.05 ** 0.01 *** 0.001) ///
				cells("b(star fmt(3)) se(par fmt(3))") ///
				keep(#1: lnsig2u: lnsig2w:) ///
				order(`firsteq' `secondeq' `thirdeq') ///
				varlabels(_cons Constant) ///
				eqlabel( `eql' , span)
			di "`etalist'"
			di "{hline `tw'}"
			di "eta Endogeneity Test  " ///
				"{bf:{ralign `=1+`cw'+3':X2=`etatestX2'}{ralign `=1+`cw'':p=`etatestp'}}"
			di "{hline `tw'}"
			di "Observations          " ///
				"{space 2}{bf:{center `=`cw'+3+1+`cw'':`NEN'}}" 
			di "Log Likelihood        " ///
				"{space 2}{bf:{center `=`cw'+3+1+`cw'':`llEN'}}" 
			di "Mean " substr(proper("`torc'"),1,4) " Efficiency  " ///
				"{space 2}{bf:{center `=`cw'+3+1+`cw'':`meaneffEN'}}" 
			di "Median " substr(proper("`torc'"),1,4) " Efficiency" ///
				"{space 2}{bf:{center `=`cw'+3+1+`cw'':`medeffEN'}}" 
			di "{hline `tw'}"
			di "{p 0 0 0 `tw'}Notes: Standard errors are in parentheses. Symbols indicate significance at the {bind:0.1% (***)}, {bind:1% (**)}, {bind:5% (*),} and {bind:10% (`=cond(c(stata_version)<14,"+","`=uchar(8224)'")')} levels."
			di "{hline `tw'}"			
		}	
	}
	
	
	if (`exo'==1) {
		estimates title: Model EX
		estimates store ModelEX
		eret scalar NEX = e(N)
		eret scalar llEX = e(ll)
		
		if ("`nicely'"=="") { 
			di _n(2) "{bf:`EE' stochastic `=substr("`porc'",1,4)' frontier model with normal/half-normal specification}"
			ml display, neq(`=`p'*2+3') `mldisplay'		
		}
		else {
			local NEX = trim("`: di %16.0f e(NEX)'")
			local llEX = trim("`: di %16.2f e(llEX)'")
		}		
		
		if ("`efficiency'"!="" | "`nicely'"!="") {
			tempvar term1 eit eit2 Ti eidot2 hit2 hidot2 exh eidothidot lnsigu2 lnsigv2 xb muistar sigistar EXeff
			quietly {
				predict double `lnsigu2' if `touse', xb equation(lnsig2u)
				predict double `lnsigv2' if `touse', xb equation(lnsig2v)
				predict double `xb' if `touse', xb equation(frontier_`lhs')
				gen double `eit' = `lhs' - `xb' if `touse'
				sort `PV' `TV'
				by `PV': egen double `Ti' = count(`TV') if `touse'
				gen double `eit2' = `eit'^2 if `touse'
				by `PV': egen double `eidot2' = total(`eit2') if `touse'				
				gen double `hit2' = exp(`lnsigu2') / exp(_b[lnsig2u:_cons])  if `touse'
				by `PV': egen double `hidot2' = total(`hit2') if `touse'
				gen double `exh' = `eit' * sqrt(`hit2') if `touse'
				by `PV': egen double `eidothidot' = total(`exh') if `touse'
				gen double `muistar' = ((- (scalar(`prod') * exp(_b[lnsig2u:_cons])*`eidothidot'))/(exp(_b[lnsig2u:_cons])*`hidot2'+exp(_b[lnsig2v:_cons]))) if `touse'
				gen double `sigistar' = sqrt((exp(_b[lnsig2u:_cons])*exp(_b[lnsig2v:_cons]))/(exp(_b[lnsig2u:_cons])*`hidot2'+exp(_b[lnsig2v:_cons]))) if `touse'
				gen double `EXeff' = exp( -sqrt(`hit2') * ( `muistar' + ((`sigistar' * normalden(`muistar'/`sigistar'))/normal(`muistar'/`sigistar')))) if `touse'
				if ("`efficiency'"!="") {
					capture drop `effvar'_EX			
					gen double `effvar'_EX=`EXeff' if `touse'
				}
			}
			if ("`nicely'"=="") {
				capture summ `EXeff' `wgt' if `touse', d
				di _n(2) "{bf:{center 50:Summary of Model EX `=proper("`torc'")' Efficiency}}"
				di "{hline 50}"
				di "{txt}Mean Efficiency{tab}{tab}" r(mean)
				di "Median Efficiency{tab}" r(p50)
				di "Minimum Efficiency{tab}" r(min)
				di "Maximum Efficiency{tab}" r(max)
				di "Standard Deviation{tab}" r(sd)				
				di _n(1) "where"
				di "0 = Perfect `torc' inefficiency"
				di "1 = Perfect `torc' efficiency"				
			}
			else capture summ `EXeff' `wgt' if `touse', d
			eret scalar meaneffEX = r(mean)
			eret scalar medeffEX = r(p50)
			local meaneffEX : di %6.4f e(meaneffEX)
			local medeffEX : di %6.4f e(medeffEX)
		}
					
		if ("`nicely'"!="" & "`nomessage'"=="") {
			local vw = 22 //variable name width
			local cw = 8 //column width
			local tw = `vw' + 1 + `cw' + 3 + 1 + `cw' //table width
			if("`constant'"!="noconstant") local firsteq="#1:_cons #1:*"
			else local firsteq="#1:*"
			capture di _b[lnsig2u:_cons]
			if (_rc!=111) local secondeq="lnsig2u:_cons lnsig2u:*"
			else local secondeq="lnsig2u:*"
			capture di _b[lnsig2v:_cons]
			if (_rc!=111) local thirdeq="lnsig2v:_cons lnsig2v:*"
			else local thirdeq="lnsig2v:*"
			capture estout
			if (_rc==199) capture ssc install estout
			if (c(stata_version)<14) local eql ""Dep.var: `lhs'" "Dep.var: ln(sigma`=char(178)'_u)" "Dep.var: ln(sigma`=char(178)'_w)""
			else local eql ""Dep.var: `lhs'" "Dep.var: ln(`=uchar(963)'`=uchar(178)'_u)" "Dep.var: ln(`=uchar(963)'`=uchar(178)'_v)""
			estout ModelEX, ///  
				title({bf:Table: Estimation Results})  ///
				mlabels("       Model EX", span) ///  
				collabel(none) ///
				varwidth(`vw') ///
				modelwidth(`cw') /// 
				equations(1) ///
				starlevels(`=cond(c(stata_version)<14,"+","`=uchar(8224)'")' 0.10 * 0.05 ** 0.01 *** 0.001) ///
				cells("b(star fmt(3)) se(par fmt(3))") ///
				keep(#1: lnsig2u: lnsig2v:) ///
				order(`firsteq' `secondeq' `thirdeq') ///
				varlabels(_cons Constant) ///
				eqlabel( `eql' , span)
			di "Observations          " ///
				"{space 2}{bf:{center `=`cw'+3+1+`cw'':`NEX'}}" 
			di "Log Likelihood        " ///
				"{space 2}{bf:{center `=`cw'+3+1+`cw'':`llEX'}}" 
			di "Mean " substr(proper("`torc'"),1,4) " Efficiency  " ///
				"{space 2}{bf:{center `=`cw'+3+1+`cw'':`meaneffEX'}}" 
			di "Median " substr(proper("`torc'"),1,4) " Efficiency" ///
				"{space 2}{bf:{center `=`cw'+3+1+`cw'':`medeffEX'}}" 
			di "{hline `tw'}"
			di "{p 0 0 0 `tw'}Notes: Standard errors are in parentheses. Symbols indicate significance at the {bind:0.1% (***)}, {bind:1% (**)}, {bind:5% (*),} and {bind:10% (`=cond(c(stata_version)<14,"+","`=uchar(8224)'")')} levels."
			di "{hline `tw'}"			
		}		
	}	


	if ("`nomessage'"=="") {	
			di _n(1) "{bf:{ul:Recommended Citations}}"
			di _n(1) "{pstd}The following citations are recommended for referring to the xtsfkk program package, the underlying econometric methodology, and examples: {p_end}"
			di _n(1) `"{phang}+ Karakaplan, Mustafa U. (2018) "xtsfkk: Stata Module for Endogenous Panel Stochastic Frontier Models." Available at Boston College, Department of Economics, Statistical Software Components (SSC) {browse "https://ideas.repec.org/c/boc/bocode/s458445.html":S458445}{p_end}"'
			di _n(1) `"{phang}+ Karakaplan, Mustafa U. and Kutlu, Levent (2017) "Endogeneity in Panel Stochastic Frontier Models." {browse "http://www.tandfonline.com/doi/abs/10.1080/00036846.2017.1363861":Applied Economics}{p_end}"'
			di _n(1) "{help xtsfkk##citation:{bf:{ul:Click for more recommended citations.}}}"
			di _n(1) `"Visit {browse "http://www.mukarakaplan.com":www.mukarakaplan.com} for updates."'
	}
	
	capture drop _est_ModelEN
	capture drop _est_ModelEX

	if ("`timer'"!="") {
		local time2 = clock(c(current_time),"hms")
		local day2 = date(c(current_date),"DMY")
		Timermessage `day1' `day2' `time1' `time2'
	}
	
	if ("`beep1'"!="") beep
	if (`beep2'!=.) {
		while `beep2'!=0 {
			beep
			sleep 1000
			local beep2 = `beep2'-1
		}
	}

	
end

program Timermessage
	args d1 d2 t1 t2
	local rt1 = (`d2'-`d1')*24*60*60 + (`t2'-`t1')/1000 - 1
	local hrs = `=int(`rt1'/3600)'
	local mins = `=int((`rt1'-(int(`rt1'/3600)*3600))/60)'
	local secs = `=int(`rt1' - int(`rt1'/3600)*3600 - int((`rt1'-(int(`rt1'/3600)*3600))/60)*60)'
	
	if `hrs'==0 local hours = ""
	else if `hrs'==1 local hours = "1 hour"
	else local hours = "`hrs' hours"
	
	if `hrs'!=0 {
		if (`mins'!=0 & `secs'!=0) local and1 = ", "
		else local and1 = " and "
	}
	else local and1 = ""
	
	if `mins'>1 local minis = "`mins' minutes"
	else if `mins'==1 local minis = "1 minute"
	else local minis = ""
	
	if (`mins'!=0 & `secs'!=0) local and2 = " and "
	else local and2 = ""
	
	if `secs'>1 local secds = "`secs' seconds"
	else if `secs'==1 local secds = "1 second"
	else if `secs'<1 & (`hrs'==0 & `mins'==0) local secds = "less than a second"
	else local secds = ""
	
	di _n(2) in red "Completed in `hours'`and1'`minis'`and2'`secds'." 
end

program Replay
	syntax [, Level(cilevel)]
	capture estimates restore ModelEN
	di "{hline `=c(linesize)'}"
	di "{center `=c(linesize)':{bf:MODEL EN}}"
	di "{hline `=c(linesize)'}"
	ml display, level(`level') 
	di _n(2)
	capture estimates restore ModelEX
	if !_rc {
		di "{hline `=c(linesize)'}"
		di "{center `=c(linesize)':{bf:MODEL EX}}"
		di "{hline `=c(linesize)'}"
		ml display, level(`level')
	}
end


********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************


mata:
	void xtsfkk_ugur(transmorphic scalar M, real scalar todo, real rowvector b,
					real colvector lnf, real rowvector g, real matrix H) { //real matrix g
		p = moptimize_util_userinfo(M,3) //p = number of endogenous variables
		Ti = moptimize_util_userinfo(M,4) //count of id
		V = moptimize_util_userinfo(M,5) //2 column matrix first-last obs of id
		N = moptimize_util_userinfo(M,8) //count of nonempty observations sample
		sigu2c = exp(b[|moptimize_util_eq_indices(M,2)|][cols(b[|moptimize_util_eq_indices(M,2)|])]) 
		sigw2c = exp(b[|moptimize_util_eq_indices(M,3)|][cols(b[|moptimize_util_eq_indices(M,3)|])]) 

		M_yz = moptimize_util_depvar(M,2)
		zd = moptimize_util_xb(M,b,4)
		eta = moptimize_util_xb(M,b,4+p)
		epsilon = M_yz - zd
		EPS = epsilon
		term1 = eta * epsilon
		
		for (j=2; j<=p; j++) { 
			M_yz = moptimize_util_depvar(M,j+1)
			zd = moptimize_util_xb(M,b,j+3)
			eta = moptimize_util_xb(M,b,j+3+p)
			epsilon = M_yz - zd
			EPS = (EPS, epsilon)
			term1 = term1 + eta * epsilon
		}
		
		le = moptimize_util_xb(M,b,p*2+4)
		
		LE = le
		for (j=2; j<=(p^2+p)/2; j++) {
			le = moptimize_util_xb(M,b,j+3+2*p)
			LE = (LE,le)
		}
		
		L = J(p,p,0)
		s = 1	
		for (i=1; i<=p; i++) {
			for (j=1; j<=i; j++) {
				L[i,j] = LE[s]
				s = s + 1
			}
		}
		
		LL = cross(L',L') 
		twopi = 2*pi()
		
		eit = moptimize_util_depvar(M,1) - moptimize_util_xb(M,b,1) - term1
		hit2 = exp(moptimize_util_xb(M,b,2)) / sigu2c
		if (rows(moptimize_util_xb(M,b,2))==1) hit2 = exp(J(N,1,moptimize_util_xb(M,b,2))) / sigu2c 

		denom = sigu2c*(panelsum(hit2, V)) :+ sigw2c
		sigistar = sqrt((sigu2c*sigw2c):/denom)
		term3 = ((-moptimize_util_userinfo(M,6)*sigu2c*(panelsum(eit :* sqrt(hit2), V))):/denom) :/ sigistar

		//if (fast==0) 
		lnf = moptimize_util_sum(M, -0.5 * (Ti * ln(twopi*sigw2c) + ((panelsum(eit:^2, V)) / sigw2c) - term3:^2) ///
				+ ln((sigistar) / (sqrt(sigu2c) * 0.5)) + lnnormal(term3)) ///
				- 0.5 * (moptimize_util_userinfo(M,8) * ln(det(twopi*LL)) + (trace(invsym(LL) * cross(EPS,EPS))))
		//else lnf = lnfn
				
		if (st_local("savedmatrix") != "") {
			st_matrix("b", moptimize_result_coefs(M))
			stata("capture matout4 b using " + st_local("savedmatrix") + ", replace")
			

		}
		
	}

	
	
	
	void xtsfkk_ugurex(transmorphic scalar M, real scalar todo, real rowvector b,
					real colvector lnf, real rowvector g, real matrix H) {
		
		Ti = moptimize_util_userinfo(M,4) //count of id
		V = moptimize_util_userinfo(M,5) //2 column matrix first-last obs of id
		N = moptimize_util_userinfo(M,8) //count of nonempty observations sample

		sigu2c = exp(b[|moptimize_util_eq_indices(M,2)|][cols(b[|moptimize_util_eq_indices(M,2)|])]) 
		sigv2c = exp(b[|moptimize_util_eq_indices(M,3)|][cols(b[|moptimize_util_eq_indices(M,3)|])]) 
		
		twopi = 2*pi()
		eit = moptimize_util_depvar(M,1) - moptimize_util_xb(M,b,1) //- term1

		hit2 = exp(moptimize_util_xb(M,b,2)) / sigu2c
		if (rows(moptimize_util_xb(M,b,2))==1) hit2 = exp(J(N,1,moptimize_util_xb(M,b,2))) / sigu2c 

		
		denom = sigu2c*(panelsum(hit2, V)) :+ sigv2c

		sigistar = sqrt((sigu2c*sigv2c):/denom)
		term3 = ((-moptimize_util_userinfo(M,6)*sigu2c*(panelsum(eit :* sqrt(hit2), V))):/denom) :/ sigistar
				
		//if (fast==0) 
		lnf = moptimize_util_sum(M, -0.5 * (Ti * ln(twopi*sigv2c) + ((panelsum(eit:^2, V)) / sigv2c) - term3:^2) ///
				+ ln((sigistar) / (sqrt(sigu2c) * 0.5)) + lnnormal(term3)) 
		//else lnf = lnfn
						
		if (st_local("savedmatrix") != "") {
			st_matrix("b", moptimize_result_coefs(M))
			stata("capture matout4 b using " + st_local("savedmatrix") + ", replace")
		}
	}
	
end
