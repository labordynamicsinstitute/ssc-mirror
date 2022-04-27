/*
CREATED:	8 Sep 2017
AUTHOR:		Victoria N Nyaga
PURPOSE: 	To fit a bivariate random-effects model to diagnostic data and 
			produce a series of graphs(sroc and forestsplots).
VERSION: 	1.0.0
NOTES
1. Variable names should not contain underscore(_)
2. Data should be sorted and no duplicates
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
UPDATES
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DATE:						DETAILS:
24.08.2020
							grid: Grid lines between studies
							noveral in help file changed to noOVerall
							Print full matrix of rr when data is not repeated
							Print # of studies
							Correct the tick & axis position for sp
							Correct computation of the I2
							graphsave(filename) option included
03.09.2020					Change paired to comparative
14.19.2020					Correct way of counting the distinct groups in the meta-analysis
							Check to ensure variable names do no contain underscore.
12.02.2021					paired data: a b c d comparator index covariates, by(byvar)
							comparator, index, byvar need to be string
							Need to test more with more covariates!!!
09.07.2021					cimodel > cimethod
							Overal isq not showing with dp>2
01.02.2022					Change paired to matched
							paired data: n1 n2 N comparator index covariates, by(byvar)
							Subgroup analysis with superimposed graphs; stratify option
							stratify not an option for paired, matched or network
15.03.22					design(independent|matched|paired|comparative|network, baselevel(string))
						    network data: n N Assignment covariates ....repeated measurements per study							

*/



/*++++++++++++++++++++++	METAPRED +++++++++++++++++++++++++++++++++++++++++++
						WRAPPER FUNCTION
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
cap program drop metapreg
program define metapreg, eclass sortpreserve byable(recall)
version 14.1

	#delimit ;
	syntax varlist(min=2) [if] [in], 
		STudyid(varname) [
		ALphasort
		AStext(integer 50) 
		CImethod(string) 
		CIOpts(string) 
		DIAMopts(string) 
		DOUBLE 
		DOWNload(string asis) 
		DP(integer 2) 
		Level(integer 95) 
		INTeraction
		LABEL(string) 
		LCols(varlist) 
		Model(string) 
		noGRaph 
		noOVerall 
		noOVLine 
		noSTats 
		noSUBgroup 
		noITAble 
		OLineopts(string) 
		outplot(string)
		SUMTable(string) //none|logit|abs|rr|all
		DESign(string) //design(independent|matched|paired|comparative|network, baselevel(string))
		POINTopts(string) 
		POwer(integer 0)
		PREDciOpt(string)
		RCols(varlist) 
		PREDIction  //prediction
		SORtby(varlist) 
		SUBLine
		SUMMARYonly
		SUMStat(string asis)
		TEXts(real 1.0) 
		XLAbel(passthru)
		XLIne(passthru)	/*silent option*/	
		XTick(passthru)  
		noMC /*No Model comparison - Saves time*/
		PROGress /*See the model fitting*/
		graphsave(string)
		by(varname)
		STRatify  /*Stratified analysis, requires byvar()*/
		logscale
		*] ;
	#delimit cr
	
	preserve

	marksample touse, strok 
	qui drop if !`touse'

	tempvar rid event total invtotal use id neolabel es se lci uci grptotal uniq mu use rid lpi upi obsid
	tempname nltest mctest samtrix logodds rrout absout logoddsi rrouti absouti    ///
		coefmat coefvar BVar WVar  omat isq2 bghet bshet lrtestp V dftestnl ptestnl lrtest ///
		outr absoutp absoutpi hetout hetouti
	/*Check for mu; its reserved*/
	qui ds
	local vlist = r(varlist)
	foreach v of local vlist {
		if "`v'" == "mu" {
			di in re "mu is a reserved variable name; drop or rename mu"
			exit _rc
		}
	}
	gen mu = 1
	gen _ESAMPLE = 0
	
	if _by() {
		global by_index_ = _byindex()
		if "`graph'" == "" & "$by_index_" == "1" {
			cap graph drop _all
		}
	}
	else {
		global by_index_ 
	}
	if "`design'" == "" {
		local design = "independent"
	}
	else {
		tokenize "`design'", parse(",")
		local design `1'
		local baselevel "`3'"
	
	}
	if ("`design'" == "matched") | ("`design'" == "paired") {
		tempvar index byvar assignment idpair ipair
	}
	local fopts `"`options'"'
	
	/*Check if variables exist*/
	foreach var of local varlist {
		cap confirm var `var'
		if _rc!=0  {
			di in re "Variable `var' not in the dataset"
			exit _rc
		}
	}
	
	//General housekeeping
	if 	"`model'" == "" {
		local model random
	}
	else {
		tokenize "`model'", parse(",")
		local model `1'
		local modelopts "`3'"
	}

	if strpos("`model'", "f") == 1 {
		local model "fixed"
	}
	else if strpos("`model'", "r") == 1 {
		local model "random"
	}
	else {
		di as error "Invalid option `model'"
		di as error "Specify either -fixed- or -random-"
		exit
	}
	if "`model'" == "fixed" & strpos("`modelopts'", "ml") != 0 {
		di as error "Option ml not allowed in `modelopts'"
		exit
	}
	if "`model'" == "fixed" & strpos("`modelopts'", "irls") != 0 {
		di as error "Option irls not allowed in `modelopts'"
		exit
	}
	
	qui count
	if `=r(N)' < 2 {
		di as err "Insufficient data to perform meta-analysis"
		exit 
	}
	if `=r(N)' < 3 & "`model'" == "random"  {
		local model fixed //If less than 3 studies, use fixed model
		di as res _n  "Note: Fixed-effects model imposed whenever number of studies is less than 3."
		if "`modelopts'" != "" {
			local modelopts
			di as res _n  "Warning: Model options ignored."
			di as res _n  "Warning: Consider specifying options for the fixed-effects model should the model not converge."
		}
	}
	if `level'<1 {
		local level `level'*100
	}
	if `level'>99 | `level'<10 {
		local level 95
	}
	if `astext'>99 | `astext' <1 {
		local astext 50
	}

	//Number of studies in the analysis
	cap assert "`studyid'" != ""
	if _rc!=0 {
		di as err "The study identifier variable is not specified"
		di as err "Specify it with STUDYID(varname) "
		exit _rc
	}
	
	tokenize `varlist'
	if "`design'" == "independent" | "`design'" == "comparative" | "`design'" == "network"  {
		gen `event' = `1'
		gen `total' = `2'
		
		forvalues num = 1/2 {
			cap confirm integer number `num'
			if _rc != 0 {
				di as error "`num' found where integer expected"
				exit
			}
		}
		cap assert `total' >= `event' if (`event' ~= .)
		if _rc != 0 {
			di as err "Order should be {n N}. Check your data."
			exit _rc
		}
		local depvars "`1' `2'" 
		macro shift 2
	}
	else if "`design'" == "matched" {
		local a = "`1'"
		local b = "`2'"
		local c = "`3'"
		local d = "`4'"
		cap assert "`6'" != ""
		if _rc != 0 {
			di as err "matched data requires atleast 6 variable"
			exit _rc
		}
		local depvars "`1' `2' `3' `4'"
		local Comparator = "`6'"
		local Index = "`5'"
		
		forvalues num = 1/4 {
			cap confirm integer number `num'
			if _rc != 0 {
				di as error "`num' found where integer expected"
				exit
			}
		}
		cap confirm string variable `5'
		if _rc != 0 {
			di as error "The first & second covariate in matched analysis should be a string"
			exit _rc
		}
		cap confirm string variable `6'
		if _rc != 0 {
			di as error "The first & second covariate in matched analysis should be a string"
			exit _rc
		}
		macro shift 6
	}
	else if "`design'" == "paired" {
		local event1 = "`1'"
		local event2 = "`2'"
		local Total = "`3'"
		cap assert "`5'" != ""
		if _rc != 0 {
			di as err "paired data requires atleast 5 variable"
			exit _rc
		}
		local depvars "`1' `2' `3'"
		local Comparator = "`5'"
		local Index = "`4'"
		
		cap assert ((`Total' >= `event1') & (`Total' >= `event2')) if ((`event1' ~= .) & (`event2' ~= .))
		if _rc != 0 {
			di as err "Order should be {n1 n2 N}. Check your data."
			exit _rc
		}
		
		forvalues num = 1/3 {
			cap confirm integer number `num'
			if _rc != 0 {
				di as error "`num' found where integer expected"
				exit
			}
		}
		cap confirm string variable `4'
		if _rc != 0 {
			di as error "The first & second covariate in paired analysis should be a string"
			exit _rc
		}
		cap confirm string variable `5'
		if _rc != 0 {
			di as error "The first & second covariate in paired analysis should be a string"
			exit _rc
		}
		macro shift 5
	}
	
	local regressors "`*'"
	local p: word count `regressors'
	
	if "`design'" == "comparative" | "`design'" == "network"{
		cap assert `p' > 0
		if _rc != 0 {
			di as error "`design' analysis requires at least 1 covariate to be specified"
			exit _rc
		}
	}
	if "`design'" == "comparative" | "`design'" == "network"  {
		gettoken first confounders : regressors
		if "`first'" != "" {
			cap confirm string variable `first'
			if _rc != 0 {
				di as error "The first covariate in `design' analysis should be a string"
				exit _rc
			}
		}
		cap assert ("`first'" != "`by'") & ("`output'" != "rr")
		if _rc != 0 { 
				di as error "Remove the option by(`by') or specify a different by-variable"
				exit _rc
		}
	}
	if "`outplot'" == "" {
		local outplot = "abs"
	}
	else {
		if "`outplot'" == "rr" {
			cap assert "`design'" != "independent"
			if _rc != 0 {
				di as error "Option outplot(rr) only avaialable for comparative/matched/paired/network designs with first covariate as string"
				di as error "Specify the first string covariate and the appropriate design(comparative/matched/paired/network)"
				exit _rc
			}
		}
	}
	if "`design'" == "matched" | "`design'" == "paired" {
		local outplot = "rr"
	}
	
	cap assert ("`outplot'" == "rr") | ("`outplot'" == "abs") 
	if _rc != 0  {
		di as error "Invalid option in outplot(`outplot')"
		exit _rc
	}
	if "`sumstat'" == "" {
		if "`outplot'" == "abs" {
			local sumstat = "Proportion"
		}
		else {
			local sumstat = "Proportion Ratio"
		}
	}
	if "`prediction'" != "" & "`outplot'" == "rr" {
		local prediction 
		di as res "NOTE: Predictions only computed for absolute measures. The option _prediction_ will be ignored"
	}
		
	//check no underscore in the variable names
	if strpos("`regressors'", "_") != 0  {
		di as error "Underscore is a reserved character and covariate(s) containing underscore(s) is(are) not allowed"
		di as error "Rename the covariate(s) to remove the underscore(s) character(s)"
		exit	
	}
	
	if `p' < 2 & "`interaction'" !="" & ("`design'" != "`matched'" | "`design'" != "`paired'" ) {
		di as error "Interactions allowed with atleast 2 covariates"
		exit
	}
	
	//=======================================================================================================================
	tempfile master
	qui save "`master'"
		
	*declare study labels for display
	if "`label'"!="" {
		tokenize "`label'", parse("=,")
		while "`1'"!="" {
			cap confirm var `3'
			if _rc!=0  {
				di as err "Variable `3' not defined"
				exit
			}
			local `1' "`3'"
			mac shift 4
		}
	}	
	qui {
		*put name/year variables into appropriate macros
		if "`namevar'"!="" {
			local lbnvl : value label `namevar'
			if "`lbnvl'"!=""  {
				quietly decode `namevar', gen(`neolabel')
			}
			else {
				gen str10 `neolabel'=""
				cap confirm string variable `namevar'
				if _rc==0 {
					replace `neolabel'=`namevar'
				}
				else if _rc==7 {
					replace `neolabel'=string(`namevar')
				}
			}
		}
		if "`namevar'"==""  {
			cap confirm numeric variable `studyid'
			if _rc != 0 {
				gen `neolabel' = `studyid'
			}
			if _rc == 0{
				gen `neolabel' = string(`studyid')
			}
		}
		if "`yearvar'"!="" {
			local yearvar "`yearvar'"
			cap confirm string variable `yearvar'
			if _rc==7 {
				local str "string"
			}
			if "`namevar'"=="" {
				replace `neolabel'=`str'(`yearvar')
			}
			else {
				replace `neolabel'=`neolabel'+" ("+`str'(`yearvar')+")"
			}
		}
	}
	if "`design'" == "matched" | "`design'" =="paired" {
		longsetup `varlist', rid(`rid') assignment(`assignment') event(`event') total(`total') idpair(`idpair') `design'

		qui gen `ipair' = "Yes"
		qui replace `ipair' = "No" if `idpair'
	}
	else {
		qui gen `rid' = _n
	}
	//byvar
	if "`by'" != "" {		
		cap confirm string variable `by'
		if _rc != 0 {
			di as error "The by() variable should be a string"
			exit _rc
		}
		if strpos(`"`varlist'"', "`by'") == 0 {
			tempvar byvar
			my_ncod `byvar', oldvar(`by')
			drop `by'
			rename `byvar' `by'
		}
	}
	
	buildregexpr `varlist', `interaction' `alphasort' `design' ipair(`ipair') `baselevel'
	
	local regexpression = r(regexpression)
	local catreg = r(catreg)
	local contreg = r(contreg)
	local basecode = r(basecode)
	
	if "`interaction'" != "" { 
		local varx = r(varx)
		local typevarx = r(typevarx)		
	}
	if "`design'" == "comparative" {
		*local varx : word 1 of `regressors'
		gettoken varx catreg : catreg
		local typevarx = "i"
	}
	
	if "`design'" == "paired" | "`design'" == "matched" { 
		local varx = "`ipair'"
		local typevarx = "i"		
	}
	
	local pcont: word count `contreg'
	if "`typevarx'" != "" & "`typevarx'" == "c" {
		local ++pcont
	} 
	if `pcont' > 0 {
		local continuous = "continuous"
	}
	
	/*Model presenations*/
	if "`design'" == "independent" | "`design'" == "comparative" {
		local nu = "mu"
	}
	else if "`design'" == "paired" | "`design'" == "matched" {
		if "`interaction'" != "" {
			local nu = "Ipair*`Comparator' + `Index'"
		}
		else {
			local nu = "mu + Ipair + `Index'"
		}			
	}
	else {
		*network
		local nu = "mu.drug"
	}

	local VarX: word 1 of `regressors'
	forvalues i=1/`p' {
		local c:word `i' of `regressors'
		
		local nu = "`nu' + `c'"		
		if "`interaction'" != "" & `i' > 1 {
				local nu = "`nu' + `c'*`VarX'"			
		}
	}
	
	if ("`catreg'" != " " | "`typevarx'" =="i" | ("`design'" == "comparative" | "`design'" == "matched" | "`design'" == "paired"))  {
		di _n "{phang}Base levels{p_end}"
		di _n as txt "{pmore} Variable  -- Base Level{p_end}"
		
		if "`design'" == "matched" | "`design'" == "paired" {
			local catregs = "`catreg' `Index'"
		}

		if "`design'" == "comparative" {
			local catregs = "`catreg' `varx'" 
		}
		if "`design'" == "network" {
			tokenize `catreg'
			macro shift
			local catregs "`*'"
		}
		if "`design'" == "independent" {
			local catregs "`catreg'"
		}
		foreach fv of local catregs  {
			local lab:label `fv' 1
			di "{pmore} `fv'  -- `lab'{p_end}"	
		}
		if "`design'" == "network" {
			local lab:label `first' `basecode'
			di "{pmore} `first'  -- `lab'{p_end}"
		}
	}
	
	if "`subgroup'" == "" & ("`catreg'" != "" | "`typevarx'" =="i" ) {
		if "`outplot'" == "abs" {
			if "`typevarx'" =="i" {
				local groupvar = "`varx'"
			}
			else {
				local groupvar : word 1 of `catreg'
			}
		}
		if "`outplot'" == "rr" & "`varx'" != "" {
			local groupvar : word 1 of `catreg'
		}
	}
	
	if "`by'" != "" {
		local groupvar "`by'"
		local byvar "`by'"
		*How many times to loop
		qui label list `by'
		local nlevels = r(max)
	}
	if "`design'" == "network" {
		local groupvar "`first'"
		local overall "nooverall"
		if "`outplot'" == "rr" {
			local itable "noitable"
		}
	} 
	*Stratify not allow in paired, matched or network analysis
	if "`stratify'" != "" {
		if "`design'" == "matched" | "`design'" == "matched" | "`design'" == "matched" {
			di as res "NOTE: The option stratify is ignored in `design' analysis"
			local stratify
		}
	}
	
	*Check by is active & that there are more than 1 levels
	if "`stratify'" != "" {
		if "`by'" == "" {
			di as error "The by() variable needs to be specified in stratified analysis"
			exit			
		}
		else {
			if `nlevels' < 2 {
				di as error "The by() variable should have atleast 2 categories in stratified analysis"	
				exit
			}
		}
	}
	
	if "`groupvar'" == "" {
		local subgroup nosubgroup
	}
	
	qui gen `use' = .
	
	*Loop should begin here
	if "`stratify'" == "" {
		local nlevels = 0
	}
	local i = 1
	local modeli = "`model'"
	local modeloptsi = "`modelopts'"
	local byrownames 
	
	//Should run atleast once
	while `i' < `=`nlevels' + 2' {
		*Stratify except the last loop for the overall
		if (`i' < `=`nlevels' + 1') & ("`stratify'" != "") {
			local strataif `"if `by' == `i'"'
			local ilab:label `by' `i'
			local stratalab `":`by' = `ilab'"'
			local ilab = ustrregexra("`ilab'", " ", "_")
			local byrownames = "`byrownames' `by':`ilab'"
			
			*Check if there is enough data in each strata
			//Number of obs in the analysis
			qui egen `obsid' = group(`rid') if `by' == `i'
			qui summ `obsid'
			local Nobs= r(max)
			drop `obsid'	

			//Number of studies in the analysis
			qui egen `uniq' = group(`studyid') if `by' == `i'
			qui summ `uniq'
			local Nuniq = r(max)
			drop `uniq'	
		}
		else {
			//Nullify
			local strataif 
			local stratalab ": Full"
			if "`stratify'" != "" {
				local byrownames = "`byrownames' Overall"	
			}
			
			//Number of obs in the analysis
			qui count
			local Nobs= r(N)
			if "`design'" == "matched" | "`design'" == "paired" {
				local Nobs = `Nobs'*0.5
			}
			qui egen `uniq' = group(`studyid')
			qui summ `uniq'
			local Nuniq = r(max)
			drop `uniq'
		}
		if "`design'" == "comparative" {
			cap assert `Nobs'/`Nuniq' == 2 
			if _rc != 0 {
				di as error "Comparative analysis requires 2 observations per study"
				exit _rc
			}
		}
		if "`design'" == "network" {
			cap assert `Nobs'/`Nuniq' >= 2 
			if _rc != 0 {
				di as error "Network design requires atleast 2 observations per study"
				exit _rc
			}
		}		
		if `Nobs' < 3 & "`model'" == "random"  {
			local modeli fixed //If less than 3 studies, use fixed model
			if "`modelopts'" != "" {
				local modeloptsi
				di as res _n  "Warning: Model options ignored."
				di as res _n  "Warning: Consider specifying options for the fixed-effects model."
			}
		}
		
		di as res _n "*********************************** Fitted model`stratalab' ***************************************"  _n
		
		tokenize `depvars'
		if "`design'" == "independent" | "`design'" == "network" {
			di "{phang} `1' ~ binomial(logit(p), `2'){p_end}"
		}
		else if "`design'" == "matched"  {
			di "{phang} `1' + `2'  ~ binomial(logit(p), `1' + `2' + `3' + `4'){p_end}"
			di "{phang} `1' + `3' ~ binomial(logit(p), `1' + `2' + `3' + `4'){p_end}"
		}
		else if "`design'" == "paired" {
			di "{phang} `1' ~ binomial(logit(p), `3'){p_end}"
			di "{phang} `2' ~ binomial(logit(p), `3'){p_end}"
		}
		
		if "`modeli'" == "random" {
			*local nu = "`nu' + `studyid'"
			di "{phang} logit(p) = `nu' + `studyid'{p_end}"	
			di "{phang}`studyid' ~ N(0, sigma.sq){p_end}"
		}
		else {
			di "{phang} logit(p) = `nu'{p_end}"		
		}
		if "`design'" == "paired" | "`design'" == "matched" {
			di "{phang} Ipair = 0 if 1st pair{p_end}"
			di "{phang} Ipair = 1 if 2nd pair{p_end}"
		}
		if "`design'" == "network" {
			di "{phang}`first' ~ N(0, tau.sq){p_end}"
			qui label list `first'
			local nfirst = r(max)
		}
			
		di _n
		di "{phang}" as txt "Number of observations = " as res "`Nobs'{p_end}"
		di "{phang}" as txt "Number of studies = " as res "`Nuniq'{p_end}"
		if "`design'" == "network" {
			di "{phang}" as txt "Number of `first's = " as res "`nfirst'{p_end}"
		}

		
		di _n"*********************************** ************* ***************************************" _n
		
		*Run model if more than 1 study
		if `Nobs' > 1 {
			preg `event' `total' `strataif', studyid(`studyid') use(`use') regexpression(`regexpression') nu(`nu') ///
				regressors(`regressors') catreg(`catreg') contreg(`contreg') level(`level') varx(`varx') typevarx(`typevarx')  /// 
				`progress' model(`model') modelopts(`modelopts') `mc' `interaction' `design' by(`by') `stratify' baselevel(`basecode') ///
				comparator(`Comparator')
	
			mat `logoddsi' = r(logodds)
			if "`catreg'" != " " | "`typevarx'" == "i"  {
				mat `rrouti' = r(rrout)
				local inltest = r(inltest)
				if "`inltest'" == "yes" & "`stratify'" == "" {
					mat `nltest' = r(nltest) 
				}
			}
			else{
				local rr "norr"
			}
			if (`p' > 0) & ("`mc'" =="") { 
				mat `mctest' = r(mctest) 
			}
			
			mat `absouti' = r(absout)

			if "`model'" == "random" { 
				mat `absoutpi' = r(absoutp)
				mat `hetouti' = r(hetout)
			}
			else {
				mat `absoutpi' = J(1, 6, 0)
				mat `hetouti' = J(1, 6, 0)
			}
		}
		*if 1 study
		else {
			mat `logoddsi' = J(1, 6, 0)
			mat `absouti' = J(1, 6, 0)
			mat `absoutpi' = J(1, 6, 0)
			mat `hetouti' = J(1, 6, 0)
			mat `rrouti' = J(1, 6, 1)
						
			replace `use' == 1
		}
		
		*Stack the matrices
		if `i' == 1 {
			mat `absout' =	`absouti'
			if "`rr'" == "" {			
				mat `rrout' =	`rrouti'
			}			
			mat `logodds' = `logoddsi'
			mat `absoutp' = `absoutpi'
			mat `hetout' = `hetouti'		
		}
		else {
			mat `absout' = `absout' \ `absouti'	
			if "`rr'" == "" {
				mat `rrout' = `rrout' \ `rrouti'
			}
			mat `logodds' = `logodds' \ `logoddsi'
			mat `absoutp' = `absoutp' \ `absoutpi'
			mat `hetout' = `hetout' \ `hetouti'
		}
		local ++i
	} 
	*End loop
	//rownames for the matrix
	if "`stratify'" != "" & `p'== 0 {
		mat rownames `hetout' = `byrownames'
		mat rownames `absout' = `byrownames'
		mat rownames `absoutp' = `byrownames'
		mat rownames `logodds' = `byrownames'
	}
	
	//CI
	if "`outplot'" == "rr" {
		local se
	}
	if "`outplot'" == "rr" & "`design'" == "network" {
		local summaryonly "summaryonly"
	}
	
	if "`design'" == "matched" | "`design'" == "paired" {
		*widesetup `event' `total', sid(`rid') idpair(`assignment')  jvar(`comparator')
		
		sort `rid'
		qui drop `assignment' `ipair'
		qui reshape wide `event' `total', i(`rid') j(`idpair')
		*qui reshape wide `event' `total' `index' `assignment', i(`rid') j(`comparator')	
		
		*koopmanci `event'1 `total'1 `event'0 `total'0, rr(`es') upperci(`uci') lowerci(`lci') alpha(`=1 - `level'*0.01')
		*gen `id' = `rid'
		
	}
		
	qui metapregci `depvars', studyid(`studyid') es(`es') se(`se') uci(`uci') lci(`lci') `design' ///
		id(`id') rid(`rid') regressors(`regressors') outplot(`outplot') level(`level') ///
		cimethod(`cimethod') lcols(`lcols') rcols(`rcols')  sortby(`sortby')
	
	local depvars = r(depvars)
	local rcols = r(rcols)
	local lcols = r(lcols)
	local sortby = r(sortby)
	if (`p' > 0) {
		local indvars = r(regressors)
	}
			
	prep4show `id' `use' `neolabel' `es' `lci' `uci' `se', `design' ///
		sortby(`sortby') groupvar(`groupvar') grptotal(`grptotal') 	///
		outplot(`outplot') rrout(`rrout') absout(`absout') absoutp(`absoutp') hetout(`hetout')	///
	    `subgroup' `summaryonly' dp(`dp') pcont(`pcont') model(`model') `prediction'	///
		`overall' download(`download') indvars(`indvars') depvars(`depvars') `stratify' level(`level')
	
	if "`itable'" == "" {
		disptab `id'  `use' `neolabel' `es' `lci' `uci' `grptotal', `itable' dp(`dp') power(`power') ///
			`subgroup' sumstat(`sumstat') 
    }		
		
	//Extra tables
	if ("`sumtable'" != "none") {
		di as res _n "****************************************************************************************"
	}
	//logodds
	if  (("`sumtable'" == "all") |(strpos("`sumtable'", "logit") != 0)) {
		printmat, matrixout(`logodds') type(logit) dp(`dp') power(`power') `continuous'
	}
	//abs
	if  (("`sumtable'" == "all") |(strpos("`sumtable'", "abs") != 0)) {
		printmat, matrixout(`absout') type(abs) dp(`dp') power(`power') `continuous'
	}
	//het
	if "`model'" =="random" {			
		printmat, matrixout(`hetout') type(het) dp(`dp') `design'
	}
	
	//rr
	if (("`sumtable'" == "all") | (strpos("`sumtable'", "rr") != 0)) & (("`catreg'" != " ") | ("`typevarx'" == "i"))   {
		//rr
		printmat, matrixout(`rrout') type(rr) dp(`dp') power(`power') 
		
		//rr equal
		if "`inltest'" == "yes" {
			printmat, matrixout(`nltest') type(rre) dp(`dp')
		}		
	}	
	//model comparison
	if ((`p' > 0 & "`design'" != "network") | (`p' > 1 & "`design'" == "network")) & ("`mc'" =="") {
		printmat, matrixout(`mctest') type(mc) dp(`dp')  
	}
	
	//Draw the forestplot
	if "`graph'" == "" {
		fplot `es' `lci' `uci' `use' `neolabel' `grptotal' `id', ///	
			studyid(`studyid') power(`power') dp(`dp') level(`level') ///
			groupvar(`groupvar') `prediction'  ///
			outplot(`outplot') lcols(`lcols') rcols(`rcols') ///
			ciopts(`ciopts') astext(`astext') diamopts(`diamopts') ///
			olineopts(`olineopts') sumstat(`sumstat') pointopt(`pointopts') ///
			`double' `subline' texts(`texts') `xlabel' `xtick' ///
			`ovline' `stats'  graphsave(`graphsave')`fopts' `xline' `logscale' `design'
	}
	
	cap ereturn clear

	cap confirm matrix `mctest'
	if _rc == 0 {
		ereturn matrix mctest = `mctest'
	}
	cap confirm matrix `hetout'
	if _rc == 0 {
		ereturn matrix hetout = `hetout'
	}
	cap confirm matrix `nltest'
	if _rc == 0 {
		ereturn matrix rrtest = `nltest'
	}
	cap confirm matrix `logodds'
	if _rc == 0 {
		ereturn matrix logodds = `logodds'
	}
	cap confirm matrix `absout'
	if _rc == 0 {
		ereturn matrix absout = `absout'
	}
	cap confirm matrix `absoutp'
	if _rc == 0 {
		ereturn matrix absoutp = `absoutp'
	}
	cap confirm matrix `rrout'
	if _rc == 0 {
		ereturn matrix rrout = `rrout'
	}
	restore	
end

/**************************************************************************************************
							METAPREGCI - CONFIDENCE INTERVALS
**************************************************************************************************/
capture program drop metapregci
program define metapregci, rclass
	version 14.1
	#delimit ;
	syntax varlist(min=2 max=4), studyid(varname) [es(name) se(name) uci(name) lci(name)
		id(name) rid(varname) regressors(varlist) outplot(string) level(integer 95) 
		cimethod(string) lcols(varlist) rcols(varlist) matched paired sortby(varlist) comparative network independent
		];
	#delimit cr
	tempvar uniq event event1 event2 total total1 total2 a b c d
	gettoken idpair confounders : regressors
	
	tokenize `varlist'
	if "`matched'`paired'" == "" {
		generate `event' = `1'
		generate `total' = `2'
		local depvars "`1' `2'"
	}
	else if "`matched'" != ""  {
		gen `a' = `1'
		gen `b' = `2'
		gen `c' = `3'
		gen `d' = `4'
		local depvars "`1' `2' `3' `4'"
		gen `id' = _n
	}
	else {
		generate `event1' = `1'
		generate `event2' = `2'
		generate `total1' = `3'
		generate `total2' = `3'
		local depvars "`1' `2' `3'"
		gen `id' = _n
	}	
	
	if "`outplot'" == "rr" {
		if "`network'" != "" {
			gen `id' = _n
			gen `es' = .
			gen `lci' = .
			gen `uci' = .
		}
		if "`matched'" != "" { //constrained maximum likelihood estimation
			cmlci `a' `b' `c' `d', rr(`es') upperci(`uci') lowerci(`lci') alpha(`=1 - `level'*0.01')
		}
		if "`paired'" !="" {		
			koopmanci `event1' `total1' `event2' `total2', rr(`es') upperci(`uci') lowerci(`lci') alpha(`=1 - `level'*0.01')
		}
		if "`comparative'" != "" {
			egen `uniq' = group(`studyid')
			qui summ `uniq'
			local NStudies = r(max)
			qui count
			local Nobs = r(N) /*Check if the number of studies is half*/
			cap assert (`Nobs'/`NStudies') == 2
			if _rc != 0 {
				di as error "More than two observations per study for some studies"
				exit _rc, STATA
			}
			sort `regressors' `rid'
			egen `id' = seq(), f(1) t(`NStudies') b(1) 
			sort `id'  `idpair'
			
			if "`=`studyid'[1]'" != "`=`studyid'[2]'" {
				di as error "Data not properly sorted. `studyid' in row 1 and 2 should be the same. "
				exit _rc, STATA
			}
			widesetup `event' `total' `confounders', sid(`id') idpair(`idpair') sortby(`sortby')
			local vlist = r(vlist)
			local cc0 = r(cc0)
			local cc1 = r(cc1)

			koopmanci `event'1 `total'1 `event'0 `total'0, rr(`es') upperci(`uci') lowerci(`lci') alpha(`=1 - `level'*0.01')
			
			//Rename the varying columns
			foreach v of local vlist {
				rename `v'0 `v'_`cc0'
				label var `v'_`cc0' "`v'_`cc0'"
				rename `v'1 `v'_`cc1'
				label var `v'_`cc1' "`v'_`cc1'"
			}
			
			//make new lcols
			foreach lcol of local lcols {
				local lenvar = strlen("`lcol'")
				
				foreach v of local vlist {
					local matchstr = substr("`v'", 1, `lenvar')
					
					if strmatch("`matchstr'", "`lcol'") == 1 {
						continue, break
					}
				}
				
				if strmatch("`matchstr'", "`lcol'") == 1 {
					local lcols_rr "`lcols_rr' `lcol'_`cc0' `lcol'_`cc1'"
				}
				else {
					local lcols_rr "`lcols_rr' `lcol'"
				}
			}
			local lcols "`lcols_rr'"
			
			//make new rcols
			foreach rcol of local rcols {
				local lenvar = strlen("`rcol'")

				foreach v of local vlist {
					local matchstr = substr("`v'", 1, `lenvar')
					
					if strmatch("`matchstr'", "`rcol'") == 1 {
						continue, break
					}
				}
				
				if strmatch("`matchstr'", "`rcol'") == 1 {
					local rcols_rr "`rcols_rr' `rcol'_`cc0' `rcol'_`cc1'"
				}
				else {
					local rcols_rr "`rcols_rr' `rcol'"
				}
			}
			local rcols "`rcols_rr'"
			
			//make new sortby
			foreach byv of local sortby {
				local lenvar = strlen("`byv'")

				foreach v of local vlist {
					local matchstr = substr("`v'", 1, `lenvar')
					
					if strmatch("`matchstr'", "`byv'") == 1 {
						continue, break
					}
				}
				
				if strmatch("`matchstr'", "`byv'") == 1 {
					local rcols_rr "`sortby_rr' `byv'_`cc0' `byv'_`cc1'"
				}
				else {
					local sortby_rr "`sortby_rr' `byv'"
				}
			}
			local sortyby "`sortby_rr'"
			
			//make new depvars		
			foreach depvar of local depvars {
				local lenvar = strlen("`depvar'")

				foreach v of local vlist {
					local matchstr = substr("`v'", 1, `lenvar')
					
					if strmatch("`matchstr'", "`depvar'") == 1 {
						continue, break
					}
				}
				
				if strmatch("`matchstr'", "`depvar'") == 1 {
					local depvars_rr "`depvars_rr' `depvar'_`cc0' `depvar'_`cc1'"
				}
				else {
					local depvars_rr "`depvars_rr' `depvar'"
				}
			}
			
			local depvars "`depvars_rr'"
			
			//make new indvars
			foreach indvar of local confounders {
				local lenvar = strlen("`indvar'")

				foreach v of local vlist {
					local matchstr = substr("`v'", 1, `lenvar')
					
					if strmatch("`matchstr'", "`indvar'") == 1 {
						continue, break
					}
				}
				
				if strmatch("`matchstr'", "`indvar'") == 1 {
					local indvars_rr "`indvars_rr' `indvar'_`cc0' `indvar'_`cc1'"
				}
				else {
					local indvars_rr "`indvars_rr' `indvar'"
				}
			}
			local regressors "`indvars_rr'"
			local p: word count `confounders' 
			if `p' == 0 {
				local regressors = " "
			}
		}
	}
	else {
		metapreg_propci `total' `event', p(`es') se(`se') lowerci(`lci') upperci(`uci') cimethod(`cimethod') level(`level')
		gen `id' = _n
	}
	if "`rcols'" =="" {
		local rcols = " "
	}
	if "`lcols'" =="" {
		local lcols = " "
	}
	if "`sortby'" =="" {
		local sortby = " "
	}
	return local regressors = "`regressors'"
	return local depvars = "`depvars'"
	return local rcols = "`rcols'"
	return local lcols = "`lcols'"
	return local sortby = "`sortby'"
end
/**************************************************************************************************
							PREG - LOGISTIC REGRESSION
**************************************************************************************************/
capture program drop preg
program define preg, rclass

	version 14.1
	#delimit ;

	syntax varlist(min=2 ) [if] [in], studyid(varname) use(varname) [
		regexpression(string)
		nu(string)
		regressors(varlist)
		varx(varname)
		typevarx(string)
		catreg(varlist)
		contreg(varlist)
		level(integer 95)
		DP(integer 2)
		progress
		model(string)
		modelopts(string)
		noMC
		interaction	
		comparative
		matched
		paired
		network
		by(varname)
		stratify
		baselevel(passthru)
		comparator(varname)
			*];

	#delimit cr
	marksample touse, strok 
	
	tempvar event total invtotal
	tempname coefmat coefvar testlr V logodds absout absoutp rrout nltest hetout mctest
	
	tokenize `varlist'
	qui gen `event' = `1' 
	qui gen `total' = `2'
		//fit the model
	if "`progress'" != "" {
		local echo noi
	}
	else {
		local echo qui
	}
	//Just initialize
		
	gettoken first confounders : regressors
	local p: word count `regressors'
	
	
	if "`matched'`paired'" != "" {		
		tokenize `regexpression'
		local one "`1'"
		local two "`2'"
		local three "`3'"
		
		if "`interaction'" != "" {
			tokenize `one', parse("#")
			tokenize `1', parse(".")
			local ipair "`3'"
			
			tokenize `two', parse(".")
			local index "`3'"
		}
		else {
			tokenize `two', parse(".")
			local ipair "`3'"
		
			tokenize `three', parse(".")
			local index "`3'"
		}
	}
	
	`echo' logitreg `event' `total' if `touse', modelopts(`modelopts') model(`model') regexpression(`regexpression') sid(`studyid') level(`level') nested(`first') `network'
	
	local DF = e(N) -  e(k) 
	if "`model'" == "random" {
		local BHET = e(chi2_c)
		local P_BHET = e(p_c)
		if "`network'" == "" {
			local DF_BHET = 1
		}
		else {
			local DF_BHET = 2
		}
	}
	else {
		local BHET = .
		local P_BHET = .
		local DF_BHET = .
	}

	estimates store metapreg_modest
	qui replace _ESAMPLE = e(sample) 
	qui replace `use' = 1 if (_ESAMPLE == 1)
	
	mat `coefmat' = e(b)
	mat `coefvar' = e(V)

	if "`model'" == "random" {
		local npar = colsof(`coefmat')
		if "`network'" == "" {
			local TAU21 = exp(`coefmat'[1, `npar'])^2 //Between study variance	1
			local TAU22 = 0
		}
		else {
			local TAU21 = exp(`coefmat'[1, `=`npar'-1'])^2 //Between study variance	1
			local TAU22 = exp(`coefmat'[1, `npar'])^2 //Between study variance	2
		}		
	}
	else {
		local TAU21 = 0
		local TAU22 = 0
	}
	local ISQ1 = .
	local ISQ2 = .
	if (`p' == 0) & ("`model'" == "random") & "`paired'`matched'" == "" {
		/*Compute I2*/				
		qui gen `invtotal' = 1/`total'
		qui summ `invtotal' if `touse'
		local invtotal= r(sum)
		local K = r(N)
		local Esigma = (exp(`TAU21'*0.5 + `coefmat'[1, 1]) + exp(`TAU21'*0.5 - `coefmat'[1, 1]) + 2)*(1/(`K'))*`invtotal'
		local ISQ1 = `TAU21'/(`Esigma' + `TAU21')*100	
	}
	else if "`network'" != "" & ("`model'" == "random") {
		local ISQ1 = `TAU21'/(`TAU21' + `TAU22')*100
		local ISQ2 = `TAU22'/(`TAU21' + `TAU22')*100		
	}
	if ((`p' > 0 & "`network'" == "") | (`p' > 1 & "`network'" != "") | ("`interaction'" != "" & "`paired'`matched'" != "") ) & "`mc'" == "" {	
		di _n"*********************************** ************* ***************************************" _n
		di as txt _n "Just a moment - Fitting reduced model(s) for comparison"
		if "`network'`interaction'" !="" {
			if "`matched'`paired'" != "" {
				local confariates "`comparator'"	
			}
			else {
				local confariates "`confounders'"
			}
		}
		else {
			local confariates "`regressors'"
		}
		local initial 1
		foreach c of local confariates {
			local nureduced	
			if ("`interaction'" != "" & "`paired'`matched'" != "")  {
					local omterm = "`c'*`ipair'"
					
					gettoken start end : regexpression
					
					local nureduced "mu i.`ipair' `end'"
					local eqreduced = "Ipair + `end'"
					
			}
			else {						
				foreach term of local regexpression {
					if "`interaction'" != "" {
						if strpos("`term'", "`c'#") != 0 & strpos("`term'", "`first'") != 0 {
							local omterm = "`c'*`first'"
						}
						else {
							local nureduced "`nureduced' `term'"
						}
					}
					else{
						if ("`term'" == "i.`c'")|("`term'" == "c.`c'")|("`term'" == "`c'") {
							local omterm = "`c'"
						} 
						else {
							local nureduced "`nureduced' `term'"
						}
					}
				}
				local eqreduced = subinstr("`nu'", "+ `omterm'", "", 1)
			}
			
			di as res _n "Ommitted : `omterm' in logit(p)"
			if "`model'"  == "random" {
				di as res "{phang} logit(p) = `eqreduced' + `studyid'{p_end}"
			}
			else {
				di as res "{phang} logit(p) = `eqreduced'{p_end}"
			}
			
			`echo' logitreg `event' `total' if `touse',  modelopts(`modelopts') model(`model') regexpression(`nureduced') sid(`studyid') level(`level')  nested(`first') `network'
			estimates store metapreg_Null
			
			//LR test the model
			qui lrtest metapreg_modest metapreg_Null, force
			local lrp :di %10.`dp'f chi2tail(r(df), r(chi2))
			local lrchi2 = r(chi2)
			local lrdf = r(df)
			estimates drop metapreg_Null
			
			if `initial' == 1  {
				mat `mctest' = [`lrchi2', `lrdf', `lrp']
			}
			else {
				mat `mctest' = [`lrchi2', `lrdf', `lrp'] \ `mctest'
			}
			local rownameslr "`rownameslr' `omterm'"
			
			local initial 0
		}
		//Ultimate null model
		if (`p' > 1 & "`network'" == "") | (`p' > 2 & "`network'" != "")  {
			di as res _n "Ommitted : All covariate effects in logit(p)"
			
			
			if "`network'" != ""  {
				local regexpression "ibn.`first'"
			}
			else if "`paired'`matched'" != "" {
				local regexpression "mu i.`ipair' i.`index'"
			}
			else {
				local regexpression "mu"
			}
			
			`echo' logitreg `event' `total' if `touse', modelopts(`modelopts') model(`model') regexpression(mu) sid(`studyid') level(`level')  nested(`first') `network'
			estimates store metapreg_Null
			
			qui lrtest metapreg_modest metapreg_Null
			local lrchi2 = r(chi2)
			local lrdf = r(df)
			local lrp :di %10.`dp'f r(p)
			
			estimates drop metapreg_Null
			
			mat `mctest' = `mctest' \ [`lrchi2', `lrdf', `lrp']
			local rownameslr "`rownameslr' All"
		}
		mat rownames `mctest' = `rownameslr'
		mat colnames `mctest' =  chi2 df p
	}
	
	//LOG ODDS
	estp, estimates(metapreg_modest) `interaction' catreg(`catreg') contreg(`contreg') level(`level') model(`model') ///
		varx(`varx') typevarx(`typevarx') by(`by') regexpression(`regexpression') `matched' `paired' `network' `stratify' ///
		comparator(`comparator')
	mat `logodds' = r(outmatrix)
	
	//ABS
	estp, estimates(metapreg_modest) `interaction'  catreg(`catreg') contreg(`contreg') level(`level')  model(`model') ///
		varx(`varx') typevarx(`typevarx') expit by(`by') regexpression(`regexpression') `matched' `paired' `network' `stratify'  ///
		comparator(`comparator')
	mat `absout' = r(outmatrix)
	mat `absoutp' = r(outmatrixp)
	
	//RR
	if "`catreg'" != "" | "`typevarx'" == "i" {
		estr, estimates(metapreg_modest) `comparative'  catreg(`catreg') level(`level') comparator(`comparator') `interaction' ///
			varx(`varx') typevarx(`typevarx') by(`by') `matched' `paired' `stratify' `network' regexpression(`regexpression') `baselevel'
		
		mat `rrout' = r(outmatrix)
		local inlrest = r(inltest)
		if "`inltest'" == "yes" {
			mat `nltest' = r(nltest) //if RR by groups are equal
		}
	}

	//===================================================================================
	//Return the matrices
	if "`network'" != "" {
		mat `hetout' = (`DF_BHET', `BHET' ,`P_BHET', `TAU21', `TAU22', `ISQ1', `ISQ2')
		mat colnames `hetout' = DF Chisq p sigmasq tausq Isqsigma Isqtau
	}
	else {
		if (`p' == 0) & ("`model'" == "random") & "`paired'`matched'" == "" {
			mat `hetout' = (`DF_BHET', `BHET' ,`P_BHET', `TAU21', `ISQ1')
			mat colnames `hetout' = DF Chisq p sigmasq Isqsigma
		}
		else {
			mat `hetout' = (`DF_BHET', `BHET' ,`P_BHET', `TAU21')
			mat colnames `hetout' = DF Chisq p sigmasq
		}
	}
	mat rownames `hetout' = Model
	return matrix hetout = `hetout'
	return local inltest = "`inltest'"
										
	cap confirm matrix `logodds'
	if _rc == 0 {
		return matrix logodds = `logodds'
	}
	cap confirm matrix `absout'
	if _rc == 0 {
		return matrix absout = `absout'
	}
	cap confirm matrix `absoutp'
	if _rc == 0 {
		return matrix absoutp = `absoutp'
	}
	cap confirm matrix `rrout'
	if _rc == 0 {
		return matrix rrout = `rrout'
	}
	if "`inltest'" == "yes" {
		return matrix nltest = `nltest'
	}
	cap confirm matrix `mctest'
	if _rc == 0 {
		return matrix mctest = `mctest'
	}	
end


/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: myncod +++++++++++++++++++++++++
								Decode by order of data
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/	
cap program drop my_ncod
program define my_ncod
version 14.1

	syntax newvarname(gen), oldvar(varname)
	
	qui {
		cap confirm numeric var `oldvar'
		tempvar by_num 
		
		if _rc == 0 {				
			decode `oldvar', gen(`by_num')
			drop `oldvar'
			rename `by_num' `oldvar'
		}

		* The _by variable is generated according to the original
		* sort order of the data, and not done alpha-numerically

		qui count
		local N = r(N)
		cap drop `varlist'
		gen `varlist' = 1 in 1
		local lab = `oldvar'[1]
		cap label drop `oldvar'
		if "`lab'" != ""{
			label define `oldvar' 1 "`lab'"
		}
		local found1 "`lab'"
		local max = 1
		forvalues i = 2/`N'{
			local thisval = `oldvar'[`i']
			local already = 0
			forvalues j = 1/`max'{
				if "`thisval'" == "`found`j''"{
					local already = `j'
				}
			}
			if `already' > 0{
				replace `varlist' = `already' in `i'
			}
			else{
				local max = `max' + 1
				replace `varlist' = `max' in `i'
				local lab = `oldvar'[`i']
				if "`lab'" != ""{
					label define `oldvar' `max' "`lab'", modify
				}
				local found`max' "`lab'"
			}
		}

		label values `varlist' `oldvar'
		label copy `oldvar' `varlist', replace
		
	}
end
	/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: logitreg +++++++++++++++++++++++++
								Fit the logistic regression
	+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	 
cap program drop logitreg
program define logitreg
	version 14.1
	syntax varlist [if] [in], [ model(string) modelopts(string asis) regexpression(string) sid(varname) level(integer 95) matched paired network independent comparative nested(string)]
	
	marksample touse, strok 
	
	if "`network'" != "" & "`model'" == "random" {
		local nested = `"|| (`nested': )"'
	}
	else {
		local nested
	}

	tokenize `varlist'	
	if ("`model'" == "fixed") {
		capture noisily binreg `1' `regexpression' if `touse', noconstant n(`2') ml `modelopts' l(`level')
		local success = _rc
	}
	if ("`model'" == "random") {
		if strpos(`"`modelopts'"', "intpoi") == 0  {
			qui count
			if `=r(N)' < 7 {
				local ipoints = `"intpoints(`=r(N)')"'
			}
		}
		//First trial
		#delim ;
		capture noisily  meqrlogit (`1' `regexpression' if `touse', noc )|| 
		  (`sid':  ) `nested' ,
		  binomial(`2') `ipoints' `modelopts' l(`level');
		#delimit cr 
		
		local success = _rc
		
		if `success' != 0 {
			//First fit laplace to get better starting values
			noi di _n"*********************************** ************* ***************************************" 
			noi di as txt _n "Just a moment - Obtaining better initial values "
			noi di   "*********************************** ************* ***************************************" 
			local lapsuccess 1
			if (strpos(`"`modelopts'"', "from") == 0) {
				#delim ;
				capture noisily  meqrlogit (`1' `regexpression' if `touse', noc )|| 
					(`sid':  ) `nested' ,
					binomial(`2') laplace l(`level');
				#delimit cr 
				
				local lapsuccess = _rc //0 is success
				if `lapsuccess' == 0 {
					qui estimates table
					tempname initmat
					mat `initmat' = r(coef)

					local ninits = rowsof(`initmat')
					forvalues e = 1(1)`ninits' {
						local init = `initmat'[`e', 1]
						if `init' != .b {
							if `e' == 1 {
								local inits = `"`init'"'
							}
							else {
								local inits = `"`inits', `init'"'
							}
						}
					}
					mat `initmat' = (`inits')
				}
				local inits = `"from(`initmat', copy)"'
			}
			
			if strpos(`"`modelopts'"', "iterate") == 0  {
				local modelopts = `"iterate(30) `modelopts'"'
			}

			//second trial with initial values
			#delim ;
			capture noisily  meqrlogit (`1' `regexpression' if `touse', noc )|| 
			  (`sid':  ) `nested' ,
			  binomial(`2') `ipoints' `modelopts' `inits' l(`level');
			#delimit cr 
			
			local success = _rc
		}
		
		//Try to refineopts 3 times
		if strpos(`"`modelopts'"', "refineopts") == 0 {
			local converged = e(converged)
			local try = 1
			while `try' < 3 & `converged' == 0 {
			
				#delim ;					
				capture noisily  meqrlogit (`1' `regexpression' if `touse', noc )|| 
					(`sid': ) `nested' ,
					binomial(`2') `ipoints' `modelopts' l(`level') refineopts(iterate(`=10 * `try''));
				#delimit cr 
				
				local success = _rc
				local converged = e(converged)
				local try = `try' + 1
			}
		}
		*Try matlog if still difficult
		if (strpos(`"`modelopts'"', "matlog") == 0) & ((`converged' == 0) | (`success' != 0)) {
			if strpos(`"`modelopts'"', "refineopts") == 0 {
				local refineopts = "refineopts(iterate(50))"
			}
			#delim ;
			capture noisily  meqrlogit (`1' `regexpression' if `touse', noc )|| 
				(`sid': ) `nested' ,
				binomial(`2') `ipoints' `modelopts' l(`level') `refineopts' matlog;
			#delimit cr
			
			local success = _rc 
			
			local converged = e(converged)
		}
	}
	*If not converged, exit and offer possible solutions
	if `success' != 0 {
		di as error "Model fitting failed"
		di as error "Try fitting a simpler model or better model option specifications"
		exit `success'
	}
end

	/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: metadta_PROPCI +++++++++++++++++++++++++
								CI for proportions
	++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	cap program drop metapreg_propci
	program define metapreg_propci
	version 14.1

		syntax varlist [if] [in], p(name) se(name)lowerci(name) upperci(name) [cimethod(string) level(real 95)]
		
		qui {	
			tokenize `varlist'
			gen `p' = .
			gen `lowerci' = .
			gen `upperci' = .
			gen `se' = .
			
			count `if' `in'
			forvalues i = 1/`r(N)' {
				local N = `1'[`i']
				local n = `2'[`i']

				cii proportions `N' `n', `cimethod' level(`level')
				
				replace `p' = r(proportion) in `i'
				replace `lowerci' = r(lb) in `i'
				replace `upperci' = r(ub) in `i'
				replace `se' =  r(se) in `i'
			}
		}
	end
/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: LONGSETUP +++++++++++++++++++++++++
							Transform data to long format
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
cap program drop longsetup
program define longsetup
version 14.1

syntax varlist, rid(name) assignment(name) event(name) total(name) idpair(name) [ matched paired network independent comparative ]

	qui {
	
		tokenize `varlist'
		
		if "`matched'" != "" {		
			/*The four variables should contain numbers*/
			forvalue i=1(1)4 {
				capture confirm numeric var ``i''
					if _rc != 0 {
						di as error "The variable ``i'' must be numeric"
						exit
					}	
			}
			/*4 variables per study : a b c d*/
			gen `event'1 = `1' + `2'  /* a + b */
			gen `event'0 = `1' + `3'  /* a + c */
			gen `total'1 = `1' + `2' + `3' + `4'  /* n */
			gen `total'0 = `1' + `2' + `3' + `4'  /* n */
			gen `assignment'1 = `5'
			gen `assignment'0 = `6'
		}
		else {
			/*paired: The three variables should contain numbers*/
			forvalue i=1(1)3 {
				capture confirm numeric var ``i''
					if _rc != 0 {
						di as error "The variable ``i'' must be numeric"
						exit
					}	
			}
			/*3 variables per study : n1 n2 N*/
			gen `event'1 = `1'  /* n1 */
			gen `event'0 = `2'  /* n2 */
			gen `total'1 = `3'  /* N */
			gen `total'0 = `3'  /* N */
			gen `assignment'1 = `4'
			gen `assignment'0 = `5'
		}
		
		gen `rid' = _n		
		reshape long `event' `total' `assignment', i(`rid') j(`idpair')
	}
end	
/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: WIDESETUP +++++++++++++++++++++++++
							Transform data to wide format
	+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	cap program drop widesetup
	program define widesetup, rclass
	version 14.1

	syntax varlist, sid(varlist) idpair(varname) [sortby(varlist) jvar(varname) matched paired network independent comparative]

		qui{
			tokenize `varlist'

			tempvar modey diffy
			*if "`matched'" == "" {
				tempvar jvar
				gen `jvar' = `idpair' - 1
			*}
			
			/*Check for varying variable and store them*/
			ds
			local vnames = r(varlist)
			local vlist
			foreach v of local vnames {	
				cap drop `modey' `diffy'
				bysort `sid': egen `modey' = mode(`v'), minmode
				egen `diffy' = diff(`v' `modey')
				sum `diffy'
				local sumy = r(sum)
				if (strpos(`"`varlist'"', "`v'") == 0) & (`sumy' > 0) & "`v'" != "`jvar'" & "`v'" != "`idpair'" {
					local vlist "`vlist' `v'"
				}
			}
			cap drop `modey' `diffy'
			
			sort `sid' `jvar' `sortby'
			
			/*2 variables per study : n N*/			
			reshape wide `1' `2'  `idpair' `vlist', i(`sid') j(`jvar')
			local cc0 = `idpair'0[1]
			local cc1 = `idpair'1[1]
			local idpair0 : lab `idpair' `cc0'
			local idpair1 : lab `idpair' `cc1'
			
			return local vlist = "`vlist'"
			return local cc0 = "`idpair0'"
			return local cc1 = "`idpair1'"
		}
	end	
/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: PREP4SHOW +++++++++++++++++++++++++
							Prepare data for display table and graph
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
cap program drop prep4show
program define prep4show
version 14.1

	#delimit ;
	syntax varlist, [rrout(name) absout(name) absoutp(name) sortby(varlist) by(varname) hetout(name) model(string) prediction
		groupvar(varname) summaryonly nooverall nosubgroup outplot(string) grptotal(name) download(string asis) 
		indvars(varlist) depvars(varlist) dp(integer 2) stratify pcont(integer 0) level(integer 95)
		comparative network independent paired matched]
	;
	#delimit cr
	tempvar  expand 
	tokenize `varlist'
	 
	local id = "`1'"
	local use = "`2'"
	local label = "`3'"
	local es = "`4'"
	local lci = "`5'"
	local uci = "`6'"
	if "`7'" != "" {
		local serror = "`7'"
	}
	
	qui {		
		gen `expand' = 1

		//Groups
		if "`groupvar'" != "" {	
			
			bys `groupvar' : egen `grptotal' = count(`id') //# studies in each group
			gsort `groupvar' `sortby' `id'
			bys `groupvar' : replace `expand' = 1 + 1*(_n==1) + 3*(_n==_N) 
			expand `expand'
			gsort `groupvar' `sortby' `id' `expand'
			bys `groupvar' : replace `use' = -2 if _n==1  //group label
			bys `groupvar' : replace `use' = 2 if _n==_N-2  //summary
			bys `groupvar' : replace `use' = 4 if _n==_N-1  //prediction
			bys `groupvar' : replace `use' = 0 if _n==_N //blank */
			replace `id' = `id' + 1 if `use' == 1
			replace `id' = `id' + 2 if `use' == 2  //summary 
			replace `id' = `id' + 3 if `use' == 4  //Prediction
			replace `id' = `id' + 4 if `use' == 0 //blank
			replace `label' = "Summary" if `use' == 2 
			
			qui label list `groupvar'
			local nlevels = r(max)
			forvalues l = 1/`nlevels' {
				if "`outplot'" == "abs" {
					local S_1 = `absout'[`=`pcont' +`l'', 1]
					local S_3 = `absout'[`=`pcont' +`l'', 5]
					local S_4 = `absout'[`=`pcont' +`l'', 6]
					if "`prediction'" != "" {
						local S_5 = `absoutp'[`l', 1]
						local S_6 = `absoutp'[`l', 2]
					}
					if "`model'" == "random" & "`indvars'" == "" & "`stratify'" !="" {
						local isq = `hetout'[`l', 5]
						local phet = `hetout'[`l', 3]
						replace `label' = "Summary (Isq = " + string(`isq', "%10.`=`dp''f") + "%, p = " + string(`phet', "%10.`=`dp''f") + ")" if `use' == 2 & `groupvar' == `l'	
					}	 
				}
				else {
					local S_1 = `rrout'[`l', 1]
					local S_3 = `rrout'[`l', 5]
					local S_4 = `rrout'[`l', 6]
				}
				local lab:label `groupvar' `l'
				replace `label' = "`lab'" if `use' == -2 & `groupvar' == `l'
				replace `label' = "`lab'" if `use' == 2 & `groupvar' == `l'	& "`outplot'" == "rr" & "`network'" != ""		
				replace `es'  = `S_1' if `use' == 2 & `groupvar' == `l'	
				replace `lci' = `S_3' if `use' == 2 & `groupvar' == `l'	
				replace `uci' = `S_4' if `use' == 2 & `groupvar' == `l'	
				//Predictions
				if "`outplot'" == "abs" & "`prediction'" != "" {
					replace `lci' = `S_5' if `use' == 4 & `groupvar' == `l'	
					replace `uci' = `S_6' if `use' == 4 & `groupvar' == `l'	
				}
			}
		}
		else {
			egen `grptotal' = count(`id') //# studies total
		}
		//Overall
		if "`overall'" == "" {		
			gsort  `groupvar' `sortby' `id' 
			replace `expand' = 1 + 3*(_n==_N)
			expand `expand'
			gsort  `groupvar' `sortby' `id' `expand'
			replace `use' = 4 if _n==_N  //Prediction
			replace `use' = 3 if _n==_N-1  //Overall
			replace `use' = 0 if _n==_N-2 //blank
			replace `id' = `id' + 3 if _n==_N  //Prediction
			replace `id' = `id' + 2 if _n==_N-1  //Overall
			replace `id' = `id' + 1 if _n==_N-2 //blank
			//Fill in the right info
			if "`outplot'" == "abs" {
				local nrows = rowsof(`absout')
				local S_1 = `absout'[`nrows', 1]
				local S_3 = `absout'[`nrows', 5]
				local S_4 = `absout'[`nrows', 6]
				
				//predictions
				if "`prediction'" != "" {
					local nrows = rowsof(`absoutp')
					local S_5 = `absoutp'[`nrows', 1]
					local S_6 = `absoutp'[`nrows', 2]
				}			
			}
			else {
				local nrows = rowsof(`rrout')
				local S_1 = `rrout'[`nrows', 1]
				local S_3 = `rrout'[`nrows', 5]
				local S_4 = `rrout'[`nrows', 6]
			}
			if "`model'" == "random" & "`indvars'" == ""  & "`outplot'" == "abs" {
				local nrows = rowsof(`hetout')
				local isq = `hetout'[`nrows', 5]
				local phet = `hetout'[`nrows', 3]
				replace `label' = "Overall (Isq = " + string(`isq', "%10.`=`dp''f") + "%, p = " + string(`phet', "%10.`=`dp''f") + ")" if `use' == 3
			}
			else {
				replace `label' = "Overall" if `use' == 3
			}		
			
			replace `es' = `S_1' if `use' == 3	
			replace `lci' = `S_3' if `use' == 3
			replace `uci' = `S_4' if `use' == 3
			//Predictions
			if "`outplot'" == "abs" & "`prediction'" != "" {
				replace `lci' = `S_5' if _n==_N
				replace `uci' = `S_6' if _n==_N
			}
		}
		count if `use'==1 
		replace `grptotal' = `=r(N)' if `use'==3
		replace `grptotal' = `=r(N)' if _n==_N
		
		replace `label' = "" if `use' == 0
		replace `es' = . if `use' == 0 | `use' == -2 | `use' == 4  //4 is prediction 
		replace `lci' = . if `use' == 0 | `use' == -2
		replace `uci' = . if `use' == 0 | `use' == -2
		
		gsort `groupvar' `sortby'  `id' 
		
		replace `label' = "Predictive Interval" if `use' == 4
	}
	
	if "`download'" != "" {
		local ZOVE -invnorm((100-`level')/200)
		preserve
		qui {
			cap drop _ES  _SE _LCI _UCI _USE _LABEL 
			gen _ES = `es'
			gen _SE = `serror'
			gen _LCI = `lci'
			gen _UCI = `uci'
			gen _USE = `use'
			gen _LABEL = `label'
			gen _ID = `id'
			replace _ID = _n
			replace _SE = ( `uci' - `lci')/(2*`ZOVE') if _SE == 0
			
			keep if _USE == 1
			keep `depvars' `indvars' `groupvar' _ES _SE _LCI _UCI _ESAMPLE _LABEL _ID 
		}
		di _n "Data saved"
		di "CAUTION: For n=N or n=0, _SE=0"
		di "and approximated with _SE = (_UCI – _LCI)/(2*Z(`level'))"
		noi save "`download'", replace
		
		restore
	}
	qui {
		if "`network'" == "" | ("`network'" != "" & "`outplot'" != "rr") {
			drop if (`use' == 2 | `use' == 3) & (`grptotal' == 1)  //drop summary if 1 study
		}
		drop if (`use' == 1 & "`summaryonly'" != "" & `grptotal' > 1) | (`use' == 2 & "`subgroup'" != "") | (`use' == 3 & "`overall'" != "") | (`use' == 4 & "`prediction'" == "") //Drop unnecessary rows
		
		if "`network'" != "" & "`outplot'" == "rr" {
			drop if `use' == 1 | `use' == -2
			replace `use' = 1 if `use' == 2
		}
		
		gsort `groupvar' `sortby' `id' 
		
		replace `id' = _n
		gsort `id' 
	}
end	
/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: DISPTAB +++++++++++++++++++++++++
							Prepare data for display table and graph
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
cap program drop disptab
program define disptab
version 14.1
	#delimit ;
	syntax varlist, [nosubgroup nooverall level(integer 95) sumstat(string asis) 
	dp(integer 2) power(integer 0) ]
	;
	#delimit cr
	
	tempvar id use label es lci uci grptotal
	tokenize `varlist'
	qui gen `id' = `1'
	qui gen `use' = `2'
	qui gen `label' = `3'
	qui gen `es' = `4'
	qui gen `lci' = `5'
	qui gen `uci' = `6'
	qui gen `grptotal' = `7'
	preserve
	tempvar tlabellen 
	//study label
	local studylb: variable label `label'
	if "`studylb'" == "" {
		local studylb "Study"
	}		
	local studylen = strlen("`studylb'")
	
	qui gen `tlabellen' = strlen(`label')
	qui summ `tlabellen'
	local nlen = r(max) + 2 
	local nlens = strlen("`sumstat'")
	
	local level: displ %2.0f `level'
	local start : disp %2.0f `=`nlen'/2 - `studylen'/2'
	
	di as res _n "***********************************************************************"
	di as res "{pmore2} Study specific measures : `sumstat'  {p_end}"
	di as res    "***********************************************************************" 
			  
	di  _n  as txt _col(`start') "`studylb'" _col(`nlen') "|  "   _skip(5) "`sumstat'" ///
			  _skip(5) "[`level'% Conf. Interval]" 
			  
	di  _dup(`=`nlen'-1') "-" "+" _dup(44) "-" 
	qui count
	local N = r(N)
	
	forvalues i = 1(1)`N' {
		//Group labels
		if ((`use'[`i']== -2)){ 
			di _col(2) as txt `label'[`i'] _col(`nlen') "|  "
		}
		//Studies
		if ((`use'[`i'] ==1)) { 
			di _col(2) as txt `label'[`i'] _col(`nlen') "|  "  ///
			_skip(5) as res  %10.`=`dp''f  `es'[`i']*(10^`power') /// 
			_col(`=`nlen' + 20') %10.`=`dp''f `lci'[`i']*(10^`power') ///
			_skip(5) %10.`=`dp''f `uci'[`i']*(10^`power')  
		}
		//Summaries
		if ( (`use'[`i']== 3) | ((`use'[`i']== 2) & (`grptotal'[`i'] > 1))){
			if ((`use'[`i']== 2) & (`grptotal'[`i'] > 1)) {
				di _col(2) as txt _col(`nlen') "|  " 
			}
			if (`use'[`i']== 2)	{
				local sumtext = "Summary"
			}
			else {
				local sumtext = "Overall"			
			}		
			di _col(2) as txt "`sumtext'" _col(`nlen') "|  "  ///
			_skip(5) as res  %10.`=`dp''f  `es'[`i']*(10^`power') /// 
			_col(`=`nlen' + 20') %10.`=`dp''f `lci'[`i']*(10^`power') ///
			_skip(5) %10.`=`dp''f `uci'[`i']*(10^`power') 
		}
		//Blanks
		if (`use'[`i'] == 0 ){
			di as txt _dup(`=`nlen'-1') "-" "+" _dup(44) "-"		
		}
	}		
	restore
end

	/*++++++++++++++++	SUPPORTING FUNCTIONS: BUILDEXPRESSIONS +++++++++++++++++++++
				buildexpressions the regression and estimation expressions
	+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	cap program drop buildregexpr
	program define buildregexpr, rclass
	version 13.1
		
		syntax varlist, [interaction alphasort matched paired network independent comparative ipair(varname) baselevel(string)]
		
		tempvar holder
		tokenize `varlist'

		if "`matched'`paired'" == "" {
			macro shift 2
			local regressors "`*'"
		}
		else {
			if "`matched'" != "" {
				local index = "`5'"
				local comparator = "`6'"
				macro shift 6
				}
			else {
				local index = "`4'"
				local comparator = "`5'"
				macro shift 5
			}			
			local regressors "`*'"
			
			my_ncod `holder', oldvar(`index')
			drop `index'
			rename `holder' `index'

			my_ncod `holder', oldvar(`ipair')
			drop `ipair'
			rename `holder' `ipair'
			
			my_ncod `holder', oldvar(`comparator')
			drop `comparator'
			rename `holder' `comparator'
		}
		
		local p: word count `regressors'
		
		local catreg " "
		local contreg " "
		
		if "`independent'`comparative'" != "" {
			local regexpression = "mu"
		}
		else if "`matched'`paired'" != "" {
			if "`interaction'" != "" {				
				local regexpression = "ibn.`ipair'#ibn.`comparator' i.`index'"
				//nulllify
				local interaction
			}
			else {
				local regexpression = "mu i.`ipair' i.`index'"	
			}
		}
		else { 
			*network
			local regexpression 
		}
		
		local basecode 1
		tokenize `regressors'
		forvalues i = 1(1)`p' {			
			capture confirm numeric var ``i''
			if _rc != 0 {
				if "`alphasort'" != "" {
					sort ``i''
				}
				my_ncod `holder', oldvar(``i'')
				drop ``i''
				rename `holder' ``i''
				local prefix_`i' "i"
			}
			else {
				local prefix_`i' "c"
			}
			if "`network'" != "" & `i'==1 {
				local prefix_`i' "ibn"
				if "`baselevel'" != "" {
					//Find the base level
					qui label list ``i''
					local nlevels = r(max)
					local found = 0
					local level 1
					while !`found' & `level' < `=`nlevels'+1' {
						local lab:label ``i'' `level'
						if "`lab'" == "`baselevel'" {
							local found = 1
							local basecode `level'
						}
						local ++level
					}
				}
			}
			/*Add the proper expression for regression*/
			local regexpression = "`regexpression' `prefix_`i''.``i''"
			
			if `i' > 1 & "`interaction'" != "" {
				local regexpression = "`regexpression' `prefix_`i''.``i''#`prefix_1'.`1'"	
			}
			//Pick out the interactor variable
			if `i' == 1 & "`interaction'" != "" {
				local varx = "``i''"
				local typevarx = "`prefix_`i''"
			}
			*if (`i' > 1 & "`interaction'" != "" ) |  "`interaction'" == "" { //store the rest of  variables
			if strpos("`prefix_`i''","i")  != 0 {
				local catreg "`catreg' ``i''"
			}
			else {
				local contreg "`contreg' ``i''"
			}
			*}
		}
		
		if "`interaction'" != "" {
			return local varx = "`varx'"
			return local typevarx  = "`typevarx'"
		}				
		return local  regexpression = "`regexpression'"
		return local  catreg = "`catreg'"
		return local  contreg = "`contreg'"
		return local basecode = "`basecode'"
	end
/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS:  ESTP +++++++++++++++++++++++++
							estimate log odds or proportions after modelling
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/	
	cap program drop estp
	program define estp, rclass
	version 14.1
		syntax, estimates(string) [expit DP(integer 2) model(string) varx(varname) typevarx(string) regexpression(string) comparator(varname) ///
				matched paired network independent comparative stratify interaction catreg(varlist) contreg(varlist) power(integer 0) level(integer 95) by(varname)]
		
		tempname coefmat outmatrix outmatrixp matrixout bycatregmatrixout catregmatrixout contregmatrixout row outmatrixr overall Vmatrix byVmatrix
		
		tokenize `regexpression'
		if "`matched'`paired'" != "" {
			 if "`interaction'" != "" {
				tokenize `2', parse(".")
			 }
			 else {
				tokenize `3', parse(".")
			 }
			local index "`3'"
			local catreg = "`3' `catreg'"
			local varx //nullify
			if "`by'" != "`comparator'" {
				*local catreg = "`comparator' `catreg'"
			}
		}
		if "`network'" != "" {
			tokenize `2', parse(".")
			local assignment "`3'"
			local catreg = "`3' `catreg'"
		}
		
		if "`interaction'" != "" & "`typevarx'" == "i" {
			local idpairconcat "#`varx'"
		}
		
		if "`typevarx'" == "i"  {
			if "`catreg'" == "" {
				local catreg = "`varx'"
			}
		}
		else {
			if "`contreg'" == "" {
				local contreg = "`varx'"
			}
		}
		local marginlist
		while "`catreg'" != "" {
			tokenize `catreg'
			if ("`1'" != "`by'" & "`by'" != "") | "`by'" =="" {
				local marginlist = `"`marginlist' `1'`idpairconcat'"'
			}
			macro shift 
			local catreg `*'
		}
		qui estimates restore `estimates'
		local df = e(N) -  e(k) 
		mat `coefmat' = e(b)
		if "`model'" == "random" {
			local npar = colsof(`coefmat')
			if "`network'" == "" {
				local TAU21 = exp(`coefmat'[1, `npar'])^2 //Between study variance	1
				local TAU22 = 0
			}
			else {
				local TAU21 = exp(`coefmat'[1, `=`npar'-1'])^2 //Between study variance	1
				local TAU22 = exp(`coefmat'[1, `npar'])^2 //Between study variance	2
			}
		}
		else {
			local TAU21 = 0
			local TAU22 = 0
		}
		
		local byncatreg 0
		if "`by'" != "" & "`stratify'"  == "" {
			qui margin , predict(xb) over(`by') level(`level')
			
			mat `bycatregmatrixout' = r(table)'
			mat `byVmatrix' = r(V)
			mat `bycatregmatrixout' = `bycatregmatrixout'[1..., 1..6]
			
			local byrnames :rownames `bycatregmatrixout'
			local byncatreg = rowsof(`bycatregmatrixout')
		}
		
		if "`network'`matched'`paired'" == "" {
			local grand "grand"
			local Overall "Overall"
		}
		qui margin `marginlist', predict(xb) `grand' level(`level')
					
		mat `catregmatrixout' = r(table)'
		mat `Vmatrix' = r(V)
		mat `catregmatrixout' = `catregmatrixout'[1..., 1..6]
		
		local rnames :rownames `catregmatrixout'	
		local ncatreg = rowsof(`catregmatrixout')
		
		local init 1
		local ncontreg 0
		local contrownames = ""
		if "`contreg'" != "" {
			foreach v of local contreg {
				summ `v', meanonly
				local vmean = r(mean)
				qui margin, predict(xb) at(`v'=`vmean') level(`level')
				mat `matrixout' = r(table)'
				mat `matrixout' = `matrixout'[1..., 1..6]
				if `init' {
					local init 0
					mat `contregmatrixout' = `matrixout' 
				}
				else {
					mat `contregmatrixout' =  `contregmatrixout' \ `matrixout'
				}
				local contrownames = "`contrownames' `v'"
				local ++ncontreg
			}
		}
		
		mat `outmatrixp' = J(`=`byncatreg' + `ncatreg'', 2, .)
		if "`expit'" != "" {
			forvalues r = 1(1)`byncatreg' {
				mat `outmatrixp'[`r', 1] = invlogit(`bycatregmatrixout'[`r',1] - invttail((`df'), 0.5-`level'/200) * sqrt(`bycatregmatrixout'[`r',2]^2 + `TAU21'^2  + `TAU22'^2))
				mat `outmatrixp'[`r', 2] = invlogit(`bycatregmatrixout'[`r',1] + invttail((`df'), 0.5-`level'/200)* sqrt(`bycatregmatrixout'[`r',2]^2 + `TAU21'^2 + `TAU22'^2))
			}
			forvalues r = `=`byncatreg' + 1'(1)`=`byncatreg' + `ncatreg''{
				mat `outmatrixp'[`r', 1] = invlogit(`catregmatrixout'[`=`r' - `byncatreg'', 1] - invttail((`df'), 0.5-`level'/200) * sqrt(`catregmatrixout'[`=`r' - `byncatreg'', 2]^2 + `TAU21'^2  + `TAU22'^2))
				mat `outmatrixp'[`r', 2] = invlogit(`catregmatrixout'[`=`r' - `byncatreg'', 1] + invttail((`df'), 0.5-`level'/200)* sqrt(`catregmatrixout'[`=`r' - `byncatreg'', 2]^2 + `TAU21'^2  + `TAU22'^2))
			}
		}
		
		if "`by'" != "" & "`stratify'" == "" {
			mat `matrixout' =  `bycatregmatrixout' \ `catregmatrixout'
		}
		else {
			mat `matrixout' =  `catregmatrixout' 
		}
		
		if (`ncontreg' > 0) {
			mat `matrixout' =  `contregmatrixout' \ `matrixout'
		}
		
		if "`expit'" != "" {
			forvalues r = 1(1)`=`byncatreg' + `ncatreg' + `ncontreg''  {
				mat `matrixout'[`r', 1] = invlogit(`matrixout'[`r', 1])
				mat `matrixout'[`r', 5] = invlogit(`matrixout'[`r', 5])
				mat `matrixout'[`r', 6] = invlogit(`matrixout'[`r', 6])
			}
		}

		local catrownames = ""
		if "`matched'`paired'" != "" {
			local rownamesmaxlen : strlen local Index
			local rownamesmaxlen = max(`rownamesmaxlen', 10)
		}
		else {
			local rownamesmaxlen = 10 /*Default*/
		}
		
		//# equations
		local init 0

		local rnames = "`byrnames' `rnames'" //attach the bynames
		
		//Except the grand rows	
		forvalues r = 1(1)`=`byncatreg' + `ncatreg'  - `="`grand'"!=""'' {
			//Labels
			local rname`r':word `r' of `rnames'
			tokenize `rname`r'', parse("#")					
			local left = "`1'"
			local right = "`3'"
			
			tokenize `left', parse(.)
			local leftv = "`3'"
			local leftlabel = "`1'"
			
			//no Interaction
			if "`right'" == "" {
				if "`leftv'" != "" {
					if strpos("`leftlabel'", "o") != 0 {
						local indexo = strlen("`leftlabel'") - 1
						local leftlabel = substr("`leftlabel'", 1, `indexo')
					}
					if strpos("`rname`r''", "1b") == 0 {
						local lab:label `leftv' `leftlabel'
					}
					else {
						local lab:label `leftv' 1
					}
					local eqlab "`leftv'"
				}
				else {
					local lab "`leftlabel'"
					local eqlab ""
				}
				local nlencovl : strlen local llab
				local nlencov = `nlencovl' + 1					
			}
			else {
				//Interaction
				tokenize `right', parse(.)
				local rightv = "`3'"
				local rightlabel = "`1'"
				
				if strpos("`leftlabel'", "c") == 0 {
					if strpos("`leftlabel'", "o") != 0 {
						local indexo = strlen("`leftlabel'") - 1
						local leftlabel = substr("`leftlabel'", 1, `indexo')
					}
					if strpos("`leftlabel'", "1b") == 0 {
						local llab:label `leftv' `leftlabel'
					}
					else {
						local llab:label `leftv' 1
					}
				} 
				else {
					local llab
				}
				
				if strpos("`rightlabel'", "c") == 0 {
					if strpos("`rightlabel'", "o") != 0 {
						local indexo = strlen("`rightlabel'") - 1
						local rightlabel = substr("`rightlabel'", 1, `indexo')
					}
					if strpos("`rightlabel'", "1b") == 0 {
						local rlab:label `rightv' `rightlabel'
					}
					else {
						local rlab:label `rightv' 1
					}
				} 
				else {
					local rlab
				}
				
				if (("`rlab'" != "") + ("`llab'" != "")) ==  0 {
					local lab = "`leftv'#`rightv'"
					local eqlab = ""
				}
				if (("`rlab'" != "") + ("`llab'" != "")) ==  1 {
					local lab = "`llab'`rlab'" 
					local eqlab = "`leftv'*`rightv'"
				}
				if (("`rlab'" != "") + ("`llab'" != "")) ==  2 {
					local lab = "`llab'|`rlab'" 
					local eqlab = "`leftv'*`rightv'"
				}
				local nlencovl : strlen local leftv
				local nlencovr : strlen local rightv
				local nlencov = `nlencovl' + `nlencovr' + 1
			}
			
			local lab = ustrregexra("`lab'", " ", "_")
			
			local nlenlab : strlen local lab
			if "`eqlab'" != "" {
				local nlencov = `nlencov'
			}
			else {
				local nlencov = 0
			}
			local rownamesmaxlen = max(`rownamesmaxlen', min(`=`nlenlab' + `nlencov' + 1', 32)) /*Check if there is a longer name*/
			local catrownames = "`catrownames' `eqlab':`lab'"
		}
		
	
		local rownames = "`contrownames' `catrownames' `Overall'"
		mat rownames `matrixout' = `rownames'
					
		if "`expit'" == "" {
			mat colnames `matrixout' = Logit SE z P>|z| Lower Upper
		}
		else {
			mat colnames `matrixout' = Proportion SE(logit) z(logit) P>|z| Lower Upper
		}
		if "`expit'" != "" {			
			mat colnames `outmatrixp' = Lower Upper
			mat rownames `outmatrixp' = `catrownames' `Overall'
			return matrix outmatrixp = `outmatrixp'	
		}
		return matrix outmatrix = `matrixout'
	end	
	
	
/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: PRINTMAT +++++++++++++++++++++++++
							Print the outplot matrix beautifully
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
cap program drop printmat
program define printmat
	version 13.1
	syntax, matrixout(name) type(string) [sumstat(string) dp(integer 2) power(integer 0) matched paired network independent comparative continuous]
	
		local nrows = rowsof(`matrixout')
		local ncols = colsof(`matrixout')
		local rnames : rownames `matrixout'
		local rspec "--`="&"*`=`nrows' - 1''-"
		
		local rownames = ""
		local rownamesmaxlen = 10 /*Default*/
		forvalues r = 1(1)`nrows' {
			local rname : word `r' of `rnames'
			local nlen : strlen local rname
			local rownamesmaxlen = max(`rownamesmaxlen', min(`nlen', 32)) //Check if there is a longer name
		}
		
		local nlensstat : strlen local sumstat
		local nlensstat = max(10, `nlensstat')
		if "`type'" == "rre" {
			di as res _n "****************************************************************************************"
			di as txt _n "Wald-type test for nonlinear hypothesis"
			di as txt _n "{phang}H0: All (log)RR equal vs. H1: Some (log)RR different {p_end}"

			#delimit ;
			noi matlist `matrixout', rowtitle(Effect) 
						cspec(& %`rownamesmaxlen's |  %8.`=`dp''f &  %8.`=`dp''f &  %8.`=`dp''f o2&) 
						rspec(`rspec') underscore nodotz
			;
			#delimit cr			
		}
		if ("`type'" == "logit") | ("`type'" == "abs") | ("`type'" == "rr")  {
			di as res _n "****************************************************************************************"
			if ("`type'" == "logit") { 
				di as res "{pmore2} Marginal summary: Log odds {p_end}"
			}
			if ("`type'" == "abs") { 
				di as res "{pmore2} Marginal summary: Absolute measures {p_end}"
			}
			if ("`type'" == "rr") {
				di as res "{pmore2} Marginal summary: Relative measures {p_end}"
			}
			di as res    "****************************************************************************************" 
			tempname mat2print
			mat `mat2print' = `matrixout'
			local nrows = rowsof(`mat2print')
			forvalues r = 1(1)`nrows' {
				mat `mat2print'[`r', 1] = `mat2print'[`r', 1]*10^`power'
				mat `mat2print'[`r', 5] = `mat2print'[`r', 5]*10^`power'
				mat `mat2print'[`r', 6] = `mat2print'[`r', 6]*10^`power'
						
				forvalues c = 1(1)6 {
					local cell = `mat2print'[`r', `c'] 
					if "`cell'" == "." {
						mat `mat2print'[`r', `c'] == .z
					}
				}
			}
			
			#delimit ;
			noi matlist `mat2print', rowtitle(Effect) 
						cspec(& %`rownamesmaxlen's |  %`nlensstat'.`=`dp''f &  %9.`=`dp''f &  %8.`=`dp''f &  %15.`=`dp''f &  %8.`=`dp''f &  %8.`=`dp''f o2&) 
						rspec(`rspec') underscore  nodotz
			;
			#delimit cr
		}
		if ("`type'" == "het") {
			di as res _n "****************************************************************************************"
			di as txt _n "Test of heterogeneity - LR Test: RE model vs FE model"
			
			tempname mat2print
			mat `mat2print' = `matrixout'
			forvalues r = 1(1)`nrows' {
				forvalues c = 1(1)`ncols' {
					local cell = `mat2print'[`r', `c'] 
					if "`cell'" == "." {
						mat `mat2print'[`r', `c'] == .z
					}
				}
			}
				
			#delimit ;
			noi matlist `mat2print', 
						cspec(& %`rownamesmaxlen's |  %8.0f `="&  %10.`=`dp''f "*`=`ncols'-1'' o2&) 
						rspec(`rspec') underscore nodotz
			;
			#delimit cr	
		}
		if ("`type'" == "mc") {
			di as res _n "****************************************************************************************"
			di as txt _n "Model comparison(s): Leave-one-out LR Test(s)"
			local rownamesmaxlen = max(`rownamesmaxlen', 15) //Check if there is a longer name
			#delimit ;
			noi matlist `matrixout', rowtitle(Excluded Effect) 
				cspec(& %`=`rownamesmaxlen' + 2's |  %8.0f &  %8.`=`dp''f &  %8.`=`dp''f o2&) 
				rspec(`rspec') underscore nodotz
			;
		
			#delimit cr
			if "`interaction'" !="" {
				di as txt "*NOTE: Model with and without interaction effect(s)"
			}
			else {
				di as txt "*NOTE: Model with and without main effect(s)"
			}
		}
		
		if ("`continuous'" != "") {
			di as txt "NOTE: For continuous variable margins are computed at their respective mean"
		} 
		if ("`type'" == "abs") {
			di as txt "NOTE: H0: P = 0.5 vs. H1: P != 0.5"
		}
		
end	

/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: ESTRCORE +++++++++++++++++++++++++
							Obtain the RR after modelling
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
cap program drop estrcore
program define estrcore, rclass
version 13.1

syntax, marginlist(string) [varx(varname) by(varname) confounders(varlist) level(integer 95) baselevel(integer 1) ]
	local ZOVE -invnorm((100-`level')/200)
	tempname lcoef lV outmatrix nltest
	
	qui margins `marginlist', predict(xb) over(`by') post level(`level')

	local EstRlnexpression
	foreach c of local confounders {	
		qui label list `c'
		local nlevels = r(max)
		local test_`c'
		
		if "`varx'" != "" {
			forvalues l = 1/`nlevels' {
				if `l' == 1 {
					local test_`c' = "_b[`c'_`l']"
				}
				else {
					local test_`c' = "_b[`c'_`l'] = `test_`c''"
				}
				local EstRlnexpression = "`EstRlnexpression' (`c'_`l': ln(invlogit(_b[`l'.`c'#2.`varx'])) - ln(invlogit(_b[`l'.`c'#1.`varx'])))"	
			}
		}
		else {					
			local test_`c' = "_b[`c'_`baselevel']"
			
			forvalues l = 1/`nlevels' {
				if `l' != `baselevel' {
					local test_`c' = "_b[`c'_`l'] = `test_`c''"
				}
				local EstRlnexpression = "`EstRlnexpression' (`c'_`l': ln(invlogit(_b[`l'.`c'])) - ln(invlogit(_b[`baselevel'.`c'])))"	
			}
		}
	}

	qui nlcom `EstRlnexpression', post level(`level')
	mat `lcoef' = e(b)
	mat `lV' = e(V)
	mat `lV' = vecdiag(`lV')	
	local ncols = colsof(`lcoef') //length of the vector
	local rnames :colnames `lcoef'

	local rowtestnl			
	local i = 1

	foreach c of local confounders {
		qui label list `c'
		local nlevels = r(max)
		if (`nlevels' > 2 & "`varx'" == "") | (`nlevels' > 1 & "`varx'" != "" ){
			qui testnl (`test_`c'')
			local testnl_`c'_chi2 = r(chi2)				
			local testnl_`c'_df = r(df)
			local testnl_`c'_p = r(p)

			if `i'==1 {
				mat `nltest' =  [`testnl_`c'_chi2', `testnl_`c'_df', `testnl_`c'_p']
			}
			else {
				mat `nltest' = `nltest' \ [`testnl_`c'_chi2', `testnl_`c'_df', `testnl_`c'_p']
			}
			 
			local ++i
			local rowtestnl = "`rowtestnl' `c' "
		}
	}
	mat `outmatrix' = J(`ncols', 6, .)
	
	forvalues r = 1(1)`ncols' {
		mat `outmatrix'[`r', 1] = exp(`lcoef'[1,`r']) /*Estimate*/
		mat `outmatrix'[`r', 2] = sqrt(`lV'[1, `r']) /*se in log scale, power 1*/
		mat `outmatrix'[`r', 3] = `lcoef'[1,`r']/sqrt(`lV'[1, `r']) /*Z in log scale*/
		mat `outmatrix'[`r', 4] =  normprob(-abs(`outmatrix'[`r', 3]))*2  /*p-value*/
		mat `outmatrix'[`r', 5] = exp(`lcoef'[1, `r'] - `ZOVE' * sqrt(`lV'[1, `r'])) /*lower*/
		mat `outmatrix'[`r', 6] = exp(`lcoef'[1, `r'] + `ZOVE' * sqrt(`lV'[1, `r'])) /*upper*/
	}
	
	local rownames = ""
	local rownamesmaxlen = 10 /*Default*/
	
	local nrows = rowsof(`outmatrix')
	forvalues r = 1(1)`nrows' {
		local rname`r':word `r' of `rnames'
		tokenize `rname`r'', parse("_")					
		local left = "`1'"
		local right = "`3'"
		if "`3'" != "" {
			local lab:label `left' `right'
			local lab = ustrregexra("`lab'", " ", "_")
			local nlen : strlen local lab
			local rownamesmaxlen = max(`rownamesmaxlen', min(`nlen', 32)) //Check if there is a longer name
			local rownames = "`rownames' `left':`lab'" 
		}
	}
	mat rownames `outmatrix' = `rownames'
	
	if `i' > 1 {
		mat rownames `nltest' = `rowtestnl'
		return matrix nltest = `nltest'	
	}
	return local i = "`i'"
	return matrix outmatrix = `outmatrix'

end	
/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: ESTR +++++++++++++++++++++++++
							Estimate RR after modelling
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	cap program drop estr
	program define estr, rclass
	version 13.1
		syntax, estimates(string) [catreg(varlist) typevarx(string) varx(varname) comparator(varname) ///
			level(integer 95) DP(integer 2) matched paired network independent comparative stratify power(integer 0) by(varname) ///
			regexpression(string) baselevel(integer 1)  interaction ]
		
		local ZOVE -invnorm((100-`level')/200)
		if "`comparative'`matched'`paired'" != "" {
			local idpairconcat "#`varx'"
		}
		//Nullify by
		*if "`stratify'" != "" {
		*	local by
		*}
		local confounders "`catreg'"
		
		if "`matched'`paired'" != "" {
			tokenize `regexpression'
			if "`interaction'" != "" {
				tokenize `2', parse(".")
			 }
			 else {
				tokenize `3', parse(".")
			 }
			local index "`3'"
			if "`by'" ! = "`index'" {
				local catreg = "`3' `catreg'"
			}
			local stratify //nullify
		}
		
		local confounders "`catreg'"
		*if "`matched'`paired'" != "" {			
		*	local confounders "`by' `catreg'"
		*}

		local marginlist
		while "`catreg'" != "" {
			tokenize `catreg'
			local marginlist = `"`marginlist' `1'`idpairconcat'"'
			macro shift 
			local catreg `*'
		}
		
		tempname lcoef lV outmatrix row outmatrixr overall  nltest rowtestnl testmat2print bymat ///
				bynltest compmat compnltest catregmat catregnltest
				
		local nrowsout 0
		local nrowsnl 0
		local nby 0
		local ncomp 0
		local ncatreg 0
		
		if "`by'" != "" & "`typevarx'" == "i" {
			qui estimates restore `estimates'
			estrcore, marginlist(`varx') varx(`varx') by(`by') confounders(`by')
			
			matrix `bymat' = r(outmatrix)
			local nby = rowsof(`bymat')
			local iby = r(i)
			if `iby' > 1 {
				matrix `bynltest' = r(nltest)
				matrix `nltest' = `bynltest'
				local nrowsnl = rowsof(`nltest')
			}
			mat `outmatrix' = `bymat'
			local nrowsout = rowsof(`outmatrix')
		}
		
		if "`by'" != "`comparator'" {
			qui estimates restore `estimates'
			estrcore, marginlist(`varx') varx(`varx') by(`comparator') confounders(`comparator')
			
			matrix `compmat' = r(outmatrix)
			local ncomp = rowsof(`compmat')
			local icomp = r(i)
			if `icomp' > 1 {
				matrix `compnltest' = r(nltest)
				if `nrowsnl' > 0 {
					matrix `nltest' = `nltest' \ `compnltest'
				}
				else {
					matrix `nltest' = `compnltest'
				}
				local nrowsnl = rowsof(`nltest')
			}
			
			if `nrowsout' > 0 {
				matrix `outmatrix' = `outmatrix' \ `compmat'
			}
			else {
				matrix `outmatrix' = `compmat'	
			}
			local nrowsout = rowsof(`outmatrix')
		}	
			
		
		if "`marginlist'" != "" {
			qui estimates restore `estimates'
			estrcore, marginlist(`marginlist') varx(`varx') confounders(`confounders') baselevel(`baselevel')
			
			matrix `catregmat' = r(outmatrix)
			local ncatreg = rowsof(`catregmat')
			local icatreg = r(i)
			if `icatreg' > 1 {
				matrix `catregnltest' = r(nltest)
				if `nrowsnl' > 0 {
					matrix `nltest' = `nltest' \ `catregnltest'
				}
				else {
					matrix `nltest' = `catregnltest'	
				}
				local nrowsnl = rowsof(`nltest')
			}
			if `nrowsout' > 0 {
				matrix `outmatrix' = `outmatrix' \ `catregmat'
			}
			else {
				matrix `outmatrix' = `catregmat'
			}
			
			local nrowsout = rowsof(`outmatrix')
		}

		if "`comparative'`matched'`paired'" != "" {		
			mat `overall' = J(1, 6, .)		
			qui estimates restore `estimates'
			qui margins `varx', predict(xb) post level(`level')
					
			//log metric
			qui nlcom (Overall: ln(invlogit(_b[2.`varx'])) - ln(invlogit(_b[1.`varx']))) 
					  
			mat `lcoef' = r(b)
			mat `lV' = r(V)
			mat `lV' = vecdiag(`lV')
			mat `overall'[1, 1] = exp(`lcoef'[1,1])  //rr
			mat `overall'[1, 2] = sqrt(`lV'[1, 1]) //se
			mat `overall'[1, 3] = `lcoef'[1, 1]/sqrt(`lV'[1, 1]) //zvalue
			mat `overall'[1, 4] = normprob(-abs(`lcoef'[ 1, 1]/sqrt(`lV'[1, 1])))*2 //pvalue
			mat `overall'[1, 5] = exp(`lcoef'[1, 1] - `ZOVE'*sqrt(`lV'[1, 1])) //ll
			mat `overall'[1, 6] = exp(`lcoef'[1, 1] + `ZOVE'*sqrt(`lV'[1, 1])) //ul
			mat rownames `overall' = :Overall
			
			if `nrowsout' > 0 {
				matrix `outmatrix' = `outmatrix' \ `overall'
			}
			else {
				matrix `outmatrix' = `overall'
			}
			local nrowsout = rowsof(`outmatrix')
		}
		
		if "`sumstat'" =="" {
			local sumstat = "Ratio"
		}
		
		mat colnames `outmatrix' = `sumstat' SE(lor) z(lor) P>|z| Lower Upper
			
		if `nrowsnl' > 0 {
			local inltest = "Yes"
			mat colnames `nltest' = chi2 df p
			return matrix nltest = `nltest'
		}
		return local inltest = "`inltest'"
		return matrix outmatrix = `outmatrix'
	end	
	/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: 	KOOPMANCI +++++++++++++++++++++++++
								CI for RR
	++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	cap program drop koopmanci
	program define koopmanci
	version 14.1

		syntax varlist, RR(name) lowerci(name) upperci(name) [alpha(real 0.05)]
		
		qui {	
			tokenize `varlist'
			gen `rr' = . 
			gen `lowerci' = .
			gen `upperci' = .
			
			count
			forvalues i = 1/`r(N)' {
				local n1 = `1'[`i']
				local N1 = `2'[`i']
				local n2 = `3'[`i']
				local N2 = `4'[`i']

				koopmancii `n1' `N1' `n2' `N2', alpha(`alpha')
				mat ci = r(ci)
				
				if (`n1' == 0) &(`n2'==0) {
					replace `rr' = 0 in `i'
				}
				else {
					replace `rr' = (`n1'/`N1')/(`n2'/`N2')  in `i'	
				}
				replace `lowerci' = ci[1, 1] in `i'
				replace `upperci' = ci[1, 2] in `i'
			}
		}
	end
	
	/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: KOOPMANCII +++++++++++++++++++++++++
								CI for RR
	++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	cap program drop koopmancii
	program define koopmancii, rclass
	version 14.1
		syntax anything(name=data id="data"), [alpha(real 0.05)]
		
		local len: word count `data'
		if `len' != 4 {
			di as error "Specify full data: n1 N1 n2 N2"
			exit
		}
		
		foreach num of local data {
			cap confirm integer number `num'
			if _rc != 0 {
				di as error "`num' found where integer expected"
				exit
			}
		}
		
		tokenize `data'
		cap assert ((`1' <= `2') & (`3' <= `4'))
		if _rc != 0{
			di as err "Order should be n1 N1 n2 N2"
			exit _rc
		}
		
		mata: koopman_ci((`1', `2', `3', `4'), `alpha')
		
		return matrix ci = ci
		return scalar alpha = `alpha'	

	end
/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: 	KOOPMANCI +++++++++++++++++++++++++
								CI for RR
	++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	cap program drop cmlci
	program define cmlci
	version 14.1

		syntax varlist, RR(name) lowerci(name) upperci(name) [alpha(real 0.05)]
		
		qui {	
			tokenize `varlist'
			gen `rr' = . 
			gen `lowerci' = .
			gen `upperci' = .
			
			count
			forvalues i = 1/`r(N)' {
				local a = `1'[`i']
				local b = `2'[`i']
				local c = `3'[`i']
				local d = `4'[`i']

				cmlcii `a' `b' `c' `d', alpha(`alpha')
				mat ci = r(ci)
				
				local n = `a' + `b' + `c' + `d'
	
				local p1 = (`a' + `b')/`n'
				local p0 = (`a' + `c')/`n'
				
				local RR = `p1'/`p0'
				
				replace `rr' = `RR' in `i'
				replace `lowerci' = ci[1, 1] in `i'
				replace `upperci' = ci[1, 2] in `i'
			}
		}
	end
	
	/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: KOOPMANCII +++++++++++++++++++++++++
								CI for RR
	++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	cap program drop cmlcii
	program define cmlcii, rclass
	version 14.1
		syntax anything(name=data id="data"), [alpha(real 0.05)]
		
		local len: word count `data'
		if `len' != 4 {
			di as error "Specify full data: a b c d"
			exit
		}
		
		foreach num of local data {
			cap confirm integer number `num'
			if _rc != 0 {
				di as error "`num' found where integer expected"
				exit
			}
		}
		
		tokenize `data'
		mata: cml_ci((`1', `2', `3', `4'), `alpha')
		
		return matrix ci = ci
		return scalar alpha = `alpha'	

	end
	

/*	SUPPORTING FUNCTIONS: FPLOT ++++++++++++++++++++++++++++++++++++++++++++++++
			The forest plot
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
// Some re-used code from metaprop, metadta

	capture program drop fplot
	program define fplot
	version 14.1	
	#delimit ;
	syntax varlist [if] [in] [,
		STudyid(varname)
		POWer(integer 0)
		DP(integer 2) 
		Level(integer 95)
		Groupvar(varname)		
		AStext(integer 50)
		ARRowopt(string) 		
		CIOpts(string) 
		DIAMopts(string) 
		DOUble 
 		LCols(varlist)
		RCols(varlist) 		
		noOVLine 
		noSTATS
		OLineopts(string) 
		outplot(string) 
		SUMStat(string asis) 
		POINTopts(string) 
		predciopts(string)
		SUBLine 
		TEXts(real 1.0) 
		XLAbel(string) 
		XLIne(string) 
		XTick(string)
		GRID
		GRAphsave(string asis)
		prediction
		logscale
		comparative
		network
		paired
		matched
		independent
		*
	  ];
	#delimit cr
	
	local fopts `"`options'"'
	
	tempvar effect lci uci lpi upi ilci iuci predid use label tlabel id newid df  expand orig flag ///
	
	tokenize "`varlist'", parse(" ")

	qui {
		gen `effect'=`1'*(10^`power')
		gen `lci'   =`2'*(10^`power')
		gen `uci'   =`3'*(10^`power')
		gen byte `use'=`4'
		gen str `label'=`5'
		gen `df' = `6'
		gen `id' = `7'

		//Add five spaces on top of the dataset and 1 space below
		qui summ `id'
		gen `expand' = 1
		replace `expand' = 1 + 5*(`id'==r(min))  + 1*(`id'==r(max)) 
		expand `expand'
		sort `id' `use'

		replace `id' = _n in 1/6
		replace `id' = `id' + 5 if _n>6
		replace `label' = "" in 1/5
		replace `use' = -2 in 1/4
		replace `use' = 0 in 5
		replace `id' = _N  if _N==_n
		replace `use' = 0  if _N==_n
		replace `label' = "" if _N==_n
		
		gen `flag' = 1
		replace `flag' = 0 in 1/4
						
		//studylables
		if "`network'" != "" & "`outplot'" == "rr" {
			local studylb: variable label `groupvar'
			if "`studylb'" == "" {
				label var `label' "`groupvar'"
			}
			else {
				label var `label' "`studylb'"
			}
		}
		else {
			local studylb: variable label `studyid'
			if "`studylb'" == "" {
				label var `label' "`studyid'"
			}
			else {
				label var `label' "`studylb'"
			}
		}
		
		*local titleOff = 0
		if "`lcols'" == "" {
			local lcols = "`label'"
			*local titleOff = 1
		}
		else {
			local lcols "`label' `lcols'"
		}
				
		egen `newid' = group(`id')
		replace `id' = `newid'
		drop `newid'
	
		tempvar estText index predText predLabel
		gen str `estText' = string(`effect', "%10.`=`dp''f") + " (" + string(`lci', "%10.`=`dp''f") + ", " + string(`uci', "%10.`=`dp''f") + ")"  if (`use' == 1 | `use' == 2 | `use' == 3)
		
		if "`prediction'" != "" {
			tempvar lenestext

			replace `estText' =  " (" + string(`lci', "%10.`=`dp''f") + ", " + string(`uci', "%10.`=`dp''f") + ")"  if (`use' == 4)
			qui gen `lenestext' = length(`estText')
			qui summ `lenestext' if `use' == 1
			local lentext = r(max)
			qui summ `lenestext' if `use' == 4
			local lenic = r(min)
			local lenwhite = `lentext' - `lenic' 
			
			replace `estText' = ".  `=`lenwhite'*" "'" + `estText'  if (`use' == 4)
			
		}
		// GET MIN AND MAX DISPLAY
		// SORT OUT TICKS- CODE PINCHED FROM MIKE AND FIRandomED. TURNS OUT I'VE BEEN USING SIMILAR NAMES...
		// AS SUGGESTED BY JS JUST ACCEPT ANYTHING AS TICKS AND RESPONSIBILITY IS TO USER!
	
		if "`logscale'" != "" {
			replace `effect' = ln(`effect')
			replace `lci' = ln(`lci')
			replace `uci' = ln(`uci')
		}
		qui summ `lci', detail
		local DXmin = r(min)
		qui summ `uci', detail
		local DXmax = r(max)
				
		if "`xlabel'" != "" {
			if "`logscale'" != "" {
				local DXmin = ln(min(`xlabel'))
				local DXmax = ln(max(`xlabel'))
			}
			else{
				local DXmin = min(`xlabel')
				local DXmax = max(`xlabel')
			}
		}
		if "`xlabel'"=="" {
			local xlabel "0, `DXmax'"
		}

		local lblcmd ""
		tokenize "`xlabel'", parse(",")
		while "`1'" != ""{
			if "`1'" != ","{
				local lbl = string(`1',"%7.3g")
				if "`logscale'" != "" {
					if "`1'" == "0" {
						local val = ln(`=10^(-`dp')')
					}
					else {
						local val = ln(`1')
					}
				}
				else {
					local val = `1'
				}

				local lblcmd `lblcmd' `val' "`lbl'"
			}
			mac shift
		}
		
		if "`xtick'" == ""{
			local xtick = "`xlabel'"
		}

		local xtick2 = ""
		tokenize "`xtick'", parse(",")
		while "`1'" != ""{
			if "`1'" != ","{
				if "`logscale'" != "" {
					if "`1'" == "0" {
						local val = ln(`=10^(-`dp')')
					}
					else {
						local val = ln(`1')
					}
				}
				else {
					local val = `1'
				}
				local xtick2 = "`xtick2' " + string(`val')
			}
			if "`1'" == ","{
				local xtick2 = "`xtick2'`1'"
			}
			mac shift
		}
		local xtick = "`xtick2'"
		
		local DXmin = (min(`xtick',`DXmin'))
		local DXmax = (max(`xtick',`DXmax'))
		
		*local DXmin= (min(`xlabel',`xtick',`DXmin'))
		*local DXmax= (max(`xlabel',`xtick',`DXmax'))

		local DXwidth = `DXmax'-`DXmin'
	} // END QUI

	/*===============================================================================================*/
	/*==================================== COLUMNS   ================================================*/
	/*===============================================================================================*/
	qui {	// KEEP QUIET UNTIL AFTER DIAMONDS
			
		// DOUBLE LINE OPTION
		if "`double'" != "" & ("`lcols'" != "" | "`rcols'" != ""){
			replace `expand' = 1
			replace `expand' = 2 if `use' == 1
			expand `expand'
			sort `id' `use'
			bys `id' : gen `index' = _n
			sort  `id' `use' `index'
			egen `newid' = group(`id' `index')
			replace `id' = `newid'
			drop `newid'
			
			replace `use' = 1 if `index' == 2
			replace `effect' = . if `index' == 2
			replace `lci' = . if `index' == 2
			replace `uci' = . if `index' == 2
			replace `estText' = "" if `index' == 2			

			foreach var of varlist `lcols' `rcols' {
			   cap confirm string var `var'
			   if _rc == 0 {				
					tempvar length words tosplit splitwhere best
					gen `splitwhere' = 0
					gen `best' = .
					gen `length' = length(`var')
					summ `length', det
					gen `words' = wordcount(`var')
					gen `tosplit' = 1 if `length' > r(max)/2+1 & `words' >= 2
					summ `words', det
					local max = r(max)
					forvalues i = 1/`max'{
						replace `splitwhere' = strpos(`var', word(`var',`i')) ///
						 if abs( strpos(`var',word(`var',`i')) - length(`var')/2 ) < `best' ///
						 & `tosplit' == 1
						replace `best' = abs(strpos(`var',word(`var',`i')) - length(`var')/2) ///
						 if abs(strpos(`var',word(`var',`i')) - length(`var')/2) < `best' 
					}

					replace `var' = substr(`var',1,(`splitwhere'-1)) if (`tosplit' == 1) & (`index' == 1)
					replace `var' = substr(`var',`splitwhere',length(`var')) if (`tosplit' == 1) & (`index' == 2)
					replace `var' = "" if (`tosplit' != 1) & (`index' == 2) & (`use' == 1)
					drop `length' `words' `tosplit' `splitwhere' `best'
			   }
			   if _rc != 0{
				replace `var' = . if (`index' == 2) & (`use' == 1)
			   }
			}
		}
				
		local maxline = 1

		if "`lcols'" != "" {
			tokenize "`lcols'"
			local lcolsN = 0

			while "`1'" != "" {
				cap confirm var `1'
				if _rc!=0  {
					di in re "Variable `1' not defined"
					exit _rc
				}
				local lcolsN = `lcolsN' + 1
				tempvar left`lcolsN' leftLB`lcolsN' leftWD`lcolsN'
				cap confirm string var `1'
				if _rc == 0{
					gen str `leftLB`lcolsN'' = `1'
				}
				if _rc != 0{
					cap decode `1', gen(`leftLB`lcolsN'')
					if _rc != 0{
						local f: format `1'
						gen str `leftLB`lcolsN'' = string(`1', "`f'")
						replace `leftLB`lcolsN'' = "" if `leftLB`lcolsN'' == "."
					}
				}
				replace `leftLB`lcolsN'' = "" if (`use' != 1) & (`lcolsN' != 1)
				local colName: variable label `1'
				if "`colName'"==""{
					local colName = "`1'"
				}

				// WORK OUT IF TITLE IS BIGGER THAN THE VARIABLE
				// SPREAD OVER UP TO FOUR LINES IF NECESSARY
				local titleln = length("`colName'")
				tempvar tmpln
				gen `tmpln' = length(`leftLB`lcolsN'')
				qui summ `tmpln' if `use' == 1
				local otherln = r(max)
				drop `tmpln'
				// NOW HAVE LENGTH OF TITLE AND MAX LENGTH OF VARIABLE
				local spread = int(`titleln'/`otherln') + 1
				if `spread' > 4{
					local spread = 4
				}
				local line = 1
				local end = 0
				gettoken now remain : colName

				while `end' == 0 {
					replace `leftLB`lcolsN'' =  `leftLB`lcolsN'' + " " + "`now'" in `line' 
					
					gettoken now remain : remain
					if ("`now'" == "") | (`line' == 4) {
						local end = 1
					}
					if length("`remain'") > `titleln'/`spread' {
						if `end' == 0 {
							local line = `line' + 1
						}
					}
				}
				if `line' > `maxline' {
					local maxline = `line'
				}
				mac shift
			}
		}
		if "`stats'" == "" {
			local rcols = "`estText' " + "`rcols'"
			label var `estText' "`sumstat' (`level'% CI)"
		}

		tempvar extra
		gen `extra' = " "
		label var `extra' " "
		local rcols = "`rcols' `extra'"

		local rcolsN = 0
		if "`rcols'" != "" {
			tokenize "`rcols'"
			local rcolsN = 0
			
			while "`1'" != ""{
				cap confirm var `1'
				if _rc!=0  {
					di in re "Variable `1' not defined"
					exit _rc
				}
				local rcolsN = `rcolsN' + 1
				tempvar right`rcolsN' rightLB`rcolsN' rightWD`rcolsN'
				cap confirm string var `1'
				if _rc == 0{
					gen str `rightLB`rcolsN'' = `1'
				}
				if _rc != 0{
					local f: format `1'
					gen str `rightLB`rcolsN'' = string(`1', "`f'")
					replace `rightLB`rcolsN'' = "" if `rightLB`rcolsN'' == "."
				}
				if `rcolsN' > 1 {
					replace `rightLB`rcolsN'' = "" if (`use' != 1)
				}
				local colName: variable label `1'
				if "`colName'"==""{
					local colName = "`1'"
				}

				// WORK OUT IF TITLE IS BIGGER THAN THE VARIABLE
				// SPREAD OVER UP TO FOUR LINES IF NECESSARY
				local titleln = length("`colName'")
				tempvar tmpln
				gen `tmpln' = length(`rightLB`rcolsN'')
				qui summ `tmpln' if `use' == 1
				local otherln = r(max)
				drop `tmpln'
				// NOW HAVE LENGTH OF TITLE AND MAX LENGTH OF VARIABLE
				local spread = int(`titleln'/`otherln')+1
				if `spread' > 4{
					local spread = 4
				}

				local line = 1
				local end = 0

				gettoken now remain : colName
				while `end' == 0 {
					replace `rightLB`rcolsN'' = `rightLB`rcolsN'' + " " + "`now'" in `line'
					gettoken now remain : remain

					if ("`now'" == "") | (`line' == 4) {
						local end = 1
					}
					if  length("`remain'") > `titleln'/`spread' {
						if `end' == 0 {
							local line = `line' + 1
						}
					}
				}
				if `line' > `maxline'{
					local maxline = `line'
				}
				mac shift
			}
		}

		// now get rid of extra title rows if they weren't used
		if `maxline'==3 {
			drop in 4 
		}
		if `maxline'==2 {
			drop in 3/4 
		}
		if `maxline'==1 {
			drop in 2/4 
		}
				
		egen `newid' = group(`id')
		replace `id' = `newid'
		drop `newid'
				
		local borderline = `maxline' + 0.75
		 
		
		local leftWDtot = 0
		local rightWDtot = 0
		local leftWDtotNoTi = 0

		forvalues i = 1/`lcolsN'{
			getWidth `leftLB`i'' `leftWD`i''
			qui summ `leftWD`i'' if `use' != 3 	// DON'T INCLUDE OVERALL STATS AT THIS POINT
			local maxL = r(max)
			local leftWDtotNoTi = `leftWDtotNoTi' + `maxL'
			replace `leftWD`i'' = `maxL'
		}
		tempvar titleLN				// CHECK IF OVERALL LENGTH BIGGER THAN REST OF LCOLS
		getWidth `leftLB1' `titleLN'	
		qui summ `titleLN' if `use' == 3
		local leftWDtot = max(`leftWDtotNoTi', r(max))

		forvalues i = 1/`rcolsN'{
			getWidth `rightLB`i'' `rightWD`i''
			qui summ `rightWD`i'' if  `use' != 3
			
			replace `rightWD`i'' = r(max)
			local rightWDtot = `rightWDtot' + r(max)
		}
		

		// CHECK IF NOT WIDE ENOUGH (I.E., OVERALL INFO TOO WIDE)
		// LOOK FOR EDGE OF DIAMOND summ `lci' if `use' == ...

		tempvar maxLeft
		getWidth `leftLB1' `maxLeft'
		qui count if `use' == 2 | `use' == 3 
		if r(N) > 0 {
			summ `maxLeft' if `use' == 2 | `use' == 3 	// NOT TITLES THOUGH!
			local max = r(max)
			if `max' > `leftWDtotNoTi'{
				// WORK OUT HOW FAR INTO PLOT CAN EXTEND
				// WIDTH OF LEFT COLUMNS AS FRACTION OF WHOLE GRAPH
				local x = `leftWDtot'*(`astext'/100)/(`leftWDtot'+`rightWDtot')
				tempvar y
				// SPACE TO LEFT OF DIAMOND WITHIN PLOT (FRAC OF GRAPH)
				gen `y' = ((100-`astext')/100)*(`lci'-`DXmin') / (`DXmax'-`DXmin') 
				qui summ `y' if `use' == 2 | `use' == 3
				local extend = 1*(r(min)+`x')/`x'
				local leftWDtot = max(`leftWDtot'/`extend',`leftWDtotNoTi') // TRIM TO KEEP ON SAFE SIDE
													// ALSO MAKE SURE NOT LESS THAN BEFORE!
			}

		}
		local LEFT_WD = `leftWDtot'
		local RIGHT_WD = `rightWDtot'
		
		*local ratio = `astext'		// USER SPECIFIED- % OF GRAPH TAKEN BY TEXT (ELSE NUM COLS CALC?)
		local textWD = (`DXwidth'*(`astext'/(100-`astext'))) /(`leftWDtot' + `rightWDtot')
		*local textWD = ((100-`astext')/100)*(`DXwidth') / (`DXwidth')
		*local textWD = ((100-`astext')/100)*(`DXwidth') / (`DXwidth')
		forvalues i = 1/`lcolsN'{
			gen `left`i'' = `DXmin' - `leftWDtot'*`textWD'
			local leftWDtot = `leftWDtot'-`leftWD`i''
		}

		gen `right1' = `DXmax'
		forvalues i = 2/`rcolsN'{
			local r2 = `i' - 1
			gen `right`i'' = `right`r2'' + `rightWD`r2''*`textWD'
		}

		local AXmin = `left1'
		local AXmax = `DXmax' + `rightWDtot'*`textWD'

		// DIAMONDS 
		tempvar DIAMleftX DIAMrightX DIAMbottomX DIAMtopX DIAMleftY1 DIAMrightY1 DIAMleftY2 DIAMrightY2 DIAMbottomY DIAMtopY
		
		gen `DIAMleftX'   = `lci' if `use' == 2 | `use' == 3 
		gen `DIAMleftY1'  = `id' if (`use' == 2 | `use' == 3) 
		gen `DIAMleftY2'  = `id' if (`use' == 2 | `use' == 3) 
		
		gen `DIAMrightX'  = `uci' if (`use' == 2 | `use' == 3)
		gen `DIAMrightY1' = `id' if (`use' == 2 | `use' == 3)
		gen `DIAMrightY2' = `id' if (`use' == 2 | `use' == 3)
		
		gen `DIAMbottomY' = `id' - 0.4 if (`use' == 2 | `use' == 3)
		gen `DIAMtopY' 	  = `id' + 0.4 if (`use' == 2 | `use' == 3)
		gen `DIAMtopX'    = `effect' if (`use' == 2 | `use' == 3)
		
		replace `DIAMleftX' = `DXmin' if (`lci' < `DXmin' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMleftX' = . if (`effect' < `DXmin' ) & (`use' == 2 | `use' == 3) 
		//If one study, no diamond
		replace `DIAMleftX' = . if (`df' < 2) & (`use' == 2 | `use' == 3) 
		
		replace `DIAMleftY1' = `id' + 0.4*(abs((`DXmin' -`lci')/(`effect'-`lci'))) if (`lci' < `DXmin' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMleftY1' = . if (`effect' < `DXmin' ) & (`use' == 2 | `use' == 3) 
	
		replace `DIAMleftY2' = `id' - 0.4*( abs((`DXmin' -`lci')/(`effect'-`lci')) ) if (`lci' < `DXmin' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMleftY2' = . if (`effect' < `DXmin' ) & (`use' == 2 | `use' == 3) 
		
		replace `DIAMrightX' = `DXmax' if (`uci' > `DXmax' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMrightX' = . if (`effect' > `DXmax' ) & (`use' == 2 | `use' == 3) 
		//If one study, no diamond
		replace `DIAMrightX' = . if (`df' == 1) & (`use' == 2 | `use' == 3) 
	
		replace `DIAMrightY1' = `id' + 0.4*( abs((`uci'-`DXmax' )/(`uci'-`effect')) ) if (`uci' > `DXmax' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMrightY1' = . if (`effect' > `DXmax' ) & (`use' == 2 | `use' == 3) 

		replace `DIAMrightY2' = `id' - 0.4*( abs((`uci'-`DXmax' )/(`uci'-`effect')) ) if (`uci' > `DXmax' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMrightY2' = . if (`effect' > `DXmax' ) & (`use' == 2 | `use' == 3) 

		replace `DIAMbottomY' = `id' - 0.4*( abs((`uci'-`DXmin' )/(`uci'-`effect')) ) if (`effect' < `DXmin' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMbottomY' = `id' - 0.4*( abs((`DXmax' -`lci')/(`effect'-`lci')) ) if (`effect' > `DXmax' ) & (`use' == 2 | `use' == 3) 

		replace `DIAMtopY' = `id' + 0.4*( abs((`uci'-`DXmin' )/(`uci'-`effect')) ) if (`effect' < `DXmin' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMtopY' = `id' + 0.4*( abs((`DXmax' -`lci')/(`effect'-`lci')) ) if (`effect' > `DXmax' ) & (`use' == 2 | `use' == 3) 

		replace `DIAMtopX' = `DXmin'  if (`effect' < `DXmin' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMtopX' = `DXmax'  if (`effect' > `DXmax' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMtopX' = . if ((`uci' < `DXmin' ) | (`lci' > `DXmax' )) & (`use' == 2 | `use' == 3) 
		
		gen `DIAMbottomX' = `DIAMtopX'
	} // END QUI

	forvalues i = 1/`lcolsN'{
		local lcolCommands`i' "(scatter `id' `left`i'', msymbol(none) mlabel(`leftLB`i'') mlabcolor(black) mlabpos(3) mlabsize(`texts'))"
	}

	forvalues i = 1/`rcolsN' {
		local rcolCommands`i' "(scatter `id' `right`i'', msymbol(none) mlabel(`rightLB`i'') mlabcolor(black) mlabpos(3) mlabsize(`texts'))"
	}
	
	if `"`diamopts'"' == "" {
		local diamopts "lcolor("0 0 100")"
	}
	else {
		if strpos(`"`diamopts'"',"hor") != 0 | strpos(`"`diamopts'"',"vert") != 0 {
			di as error "Options horizontal/vertical not allowed in diamopts()"
			exit
		}
		if strpos(`"`diamopts'"',"con") != 0{
			di as error "Option connect() not allowed in diamopts()"
			exit
		}
		if strpos(`"`diamopts'"',"lp") != 0{
			di as error "Option lpattern() not allowed in diamopts()"
			exit
		}
		local diamopts `"`diamopts'"'
	}
	//Point options
	if `"`pointopts'"' != "" & strpos(`"`pointopts'"',"msy") == 0{
		local pointopts = `"`pointopts' msymbol(O)"' 
	}
	if `"`pointopts'"' != "" & strpos(`"`pointopts'"',"ms") == 0{
		local pointopts = `"`pointopts' msize(vsmall)"' 
	}
	if `"`pointopts'"' != "" & strpos(`"`pointopts'"',"mc") == 0{
		local pointopts = `"`pointopts' mcolor(black)"' 
	}
	if `"`pointopts'"' == ""{
		local pointopts "msymbol(O) msize(vsmall) mcolor("0 0 0")"
	}
	else{
		local pointopts `"`pointopts'"'
	}
	// CI options
	if `"`ciopts'"' == "" {
		local ciopts "lcolor("0 0 0")"
	}
	else {
		if strpos(`"`ciopts'"',"hor") != 0 | strpos(`"`ciopts'"',"vert") != 0{
			di as error "Options horizontal/vertical not allowed in ciopts()"
			exit
		}
		if strpos(`"`ciopts'"',"con") != 0{
			di as error "Option connect() not allowed in ciopts()"
			exit
		}
		if strpos(`"`ciopts'"',"lp") != 0 {
			di as error "Option lpattern() not allowed in ciopts()"
			exit
		}
		if `"`ciopts'"' != "" & strpos(`"`ciopts'"',"lc") == 0{
			local ciopt = `"`ciopts' lcolor("0 0 0")"' 
		}
		local ciopts `"`ciopts'"'
	}
	// PREDCI options
	if `"`predciopts'"' == "" {
		local predciopts "lcolor("0 0 0") lpattern(solid)"
	}
	else {
		if strpos(`"`predciopts'"',"hor") != 0 | strpos(`"`predciopts'"',"vert") != 0{
			di as error "Options horizontal/vertical not allowed in predciopts()"
			exit
		}
		if strpos(`"`predciopts'"',"con") != 0{
			di as error "Option connect() not allowed in predciopts()"
			exit
		}
		if `"`predciopts'"' != "" & strpos(`"`predciopts'"',"lp") == 0 {
			local predciopts = `"`predciopts' lpattern(solid)"' 
		}
		if `"`predciopts'"' != "" & strpos(`"`predciopts'"',"lc") == 0{
			local predciopts = `"`predciopts' lcolor("0 0 0")"' 
		}
		local predciopts `"`predciopts'"'
	}
	// Arrow options
	if `"`arrowopts'"' == "" {
		local arrowopts "mcolor("0 0 0") lstyle(none)"
	}
	else {
		local forbidden "connect horizontal vertical lpattern lwidth lcolor lsytle"
		foreach option of local forbidden {
			if strpos(`"`arrowopts'"',"`option'")  != 0 {
				di as error "Option `option'() not allowed in arrowopts()"
				exit
			}
		}
		if `"`arrowopts'"' != "" & strpos(`"`arrowopts'"',"mc") == 0{
			local arrowopts = `"`arrowopts' mcolor("0 0 0")"' 
		}
		local arrowopts `"`arrowopts' lstyle(none)"'
	}

	// END GRAPH OPTS

	tempvar tempOv overrallLine ovMin ovMax h0Line
	
	if `"`olineopts'"' == "" {
		local olineopts "lwidth(thin) lcolor(maroon) lpattern(shortdash)"
	}
	qui summ `id'
	local DYmin = r(min)
	local DYmax = r(max) + 2
	
	qui summ `effect' if `use' == 3 
	local overall = r(max)
	if `overall' > `DXmax' | `overall' < `DXmin' | "`ovline'" != "" {	// ditch if not on graph
		local overallCommand ""
	}
	else {
		local overallCommand `" (pci `=`DYmax'-2' `overall' `borderline' `overall', `olineopts') "'
	
	}
	if "`ovline'" != "" {
		local overallCommand ""
	}
	if "`subline'" != "" & "`groupvar'" != "" {
		local sublineCommand ""		
		qui label list `groupvar'
		local nlevels = r(max)
		forvalues l = 1/`nlevels' {
			summ `effect' if `use' == 2  & `groupvar' == `l' 
			local tempSub`l' = r(mean)
			qui summ `id' if `use' == 1 & `groupvar' == `l'
			local subMax`l' = r(max) + 1
			local subMin`l' = r(min) - 2
			qui count if `use' == 1 & `groupvar' == `l' 
			if r(N) > 1 {
				local sublineCommand `" `sublineCommand' (pci `subMin`l'' `tempSub`l'' `subMax`l'' `tempSub`l'', `olineopts')"'
			}
		}
	}
	else {
		local sublineCommand ""
	}

	if `"`xline'"' != "" {
		tokenize "`xline'", parse(",")
		if "`logscale'" != "" {
			if "`1'" == "0" {
				local xlineval = ln(`=10^(-`dp')')
			}
			else {
				local xlineval = ln(`1')
			}
		}
		else {
			local xlineval = `1'
		}
		if "`3'" == "" {
			local xlineopts = "`3'"
		}
		else {
			local xlineopts = "lcolor(black)"
		}
		local xlineCommand `" (pci `=`DYmax'-2' `xlineval' `borderline' `xlineval', `xlineopts') "'
	}

	qui {
		//Generate indicator on direction of the off-scale arro
		tempvar rightarrow leftarrow biarrow noarrow rightlimit leftlimit offRhiY offRhiX offRloY offRloX offLloY offLloX offLhiY offLhiX
		gen `rightarrow' = 0
		gen `leftarrow' = 0
		gen `biarrow' = 0
		gen `noarrow' = 0
		
		replace `rightarrow' = 1 if ///
			(round(`uci', 0.001) > round(`DXmax' , 0.001)) & ///
			(round(`lci', 0.001) >= round(`DXmin' , 0.001))  & ///
			(`use' == 1 | `use' == 4) & (`uci' != .) & (`lci' != .)
			
		replace `leftarrow' = 1 if ///
			(round(`lci', 0.001) < round(`DXmin' , 0.001)) & ///
			(round(`uci', 0.001) <= round(`DXmax' , 0.001)) & ///
			(`use' == 1 | `use' == 4) & (`uci' != .) & (`lci' != .)
		
		replace `biarrow' = 1 if ///
			(round(`lci', 0.001) < round(`DXmin' , 0.001)) & ///
			(round(`uci', 0.001) > round(`DXmax' , 0.001)) & ///
			(`use' == 1 | `use' == 4) & (`uci' != .) & (`lci' != .)
			
		replace `noarrow' = 1 if ///
			(`leftarrow' != 1) & (`rightarrow' != 1) & (`biarrow' != 1) & ///
			(`use' == 1 | `use' == 4) & (`uci' != .) & (`lci' != .)	

		replace `lci' = `DXmin'  if (round(`lci', 0.001) < round(`DXmin' , 0.001)) & (`use' == 1 | `use' == 4) 
		replace `uci' = `DXmax'  if (round(`uci', 0.001) > round(`DXmax' , 0.001)) & (`uci' !=.) & (`use' == 1 | `use' == 4) 
		
		replace `lci' = . if (round(`uci', 0.001) < round(`DXmin' , 0.001)) & (`uci' !=. ) & (`use' == 1 | `use' == 4) 
		replace `uci' = . if (round(`lci', 0.001) > round(`DXmax' , 0.001)) & (`lci' !=. ) & (`use' == 1 | `use' == 4)
		replace `effect' = . if (round(`effect', 0.001) < round(`DXmin' , 0.001)) & (`use' == 1 | `use' == 4) 
		replace `effect' = . if (round(`effect', 0.001) > round(`DXmax' , 0.001)) & (`use' == 1 | `use' == 4) 		
		
		summ `id'
		local xaxislineposition = r(max)

		local xaxis "(pci `xaxislineposition' `DXmin' `xaxislineposition' `DXmax', lwidth(thin) lcolor(black))"
		/*Xaxis 1 title */
		local xaxistitlex `=(`DXmax' + `DXmin')*0.5'
		local xaxistitle  (scatteri `=`xaxislineposition' + 2.25' `xaxistitlex' "`sumstat'", msymbol(i) mlabcolor(black) mlabpos(0) mlabsize(`texts'))
		/*xticks*/
		local ticksx
		tokenize "`xtick'", parse(",")	
		while "`1'" != "" {
			if "`1'" != "," {
				local ticksx "`ticksx' (pci `xaxislineposition'  `1' 	`=`xaxislineposition'+.25' 	`1' , lwidth(thin) lcolor(black)) "
			}
			macro shift 
		}
		/*labels*/
		local xaxislabels
		tokenize `lblcmd'
		while "`1'" != ""{			
			local xaxislabels "`xaxislabels' (scatteri `=`xaxislineposition'+1' `1' "`2'", msymbol(i) mlabcolor(black) mlabpos(0) mlabsize(`texts'))"
			macro shift 2
		}
		if "`grid'" != "" {
			tempvar gridy gridxmax gridxmin
			
			gen `gridy' = `id' + 0.5
			gen `gridxmax' = `AXmax'
			gen `gridxmin' = `left1'
			local betweengrids "(pcspike `gridy' `gridxmin' `gridy' `gridxmax'  if `use' == 1 , lwidth(vvthin) lcolor(gs12))"	
		}

		//prediction
		if "`prediction'" != "" {
			gen `ilci' = `lci'[_n-1]
			gen `iuci' = `uci'[_n-1]
			replace `ilci' = . if `use' != 4 
			replace `iuci' = . if `use' != 4
			gen `predid' = `id'[_n-1]
			*replace `id' = `predid' if `use' == 4
			
			local cipred0 "(pcspike `predid' `lci' `predid' `ilci' if `use' == 4 , `predciopts') (pcspike `predid' `uci' `predid' `iuci' if `use' == 4 , `predciopts')"
			local cipred1 "(pcarrow `predid' `ilci' `predid' `lci' if `leftarrow' == 1  & `use' == 4, `arrowopts')	(pcarrow `predid' `iuci' `predid' `uci' if `rightarrow' == 1 & `use' == 4, `arrowopts')"
		}		
	}	// end qui	
	/*===============================================================================================*/
	/*====================================  GRAPH    ================================================*/
	/*===============================================================================================*/
	#delimit ;
	twoway
	 /*NOTE FOR RF, AND OVERALL LINES FIRST */ 
		`overallCommand' `sublineCommand' `xlineCommand' `xaxis' `xaxistitle' 
		`ticksx' `xaxislabels' 
	 /*COLUMN VARIABLES */
		`lcolCommands1' `lcolCommands2' `lcolCommands3' `lcolCommands4'  `lcolCommands5'  `lcolCommands6'
		`lcolCommands7' `lcolCommands8' `lcolCommands9' `lcolCommands10' `lcolCommands11' `lcolCommands12'
		`rcolCommands1' `rcolCommands2' `rcolCommands3' `rcolCommands4'  `rcolCommands5'  `rcolCommands6' 
		`rcolCommands7' `rcolCommands8' `rcolCommands9' `rcolCommands10' `rcolCommands11' `rcolCommands12' 
	 /*PLOT EMPTY POINTS AND PUT ALL THE GRAPH OPTIONS IN THERE */ 
		(scatter `id' `effect' if `use' == 1, 
			msymbol(none)		
			yscale(range(`DYmin' `DYmax') noline reverse)
			ylabel(none) ytitle("")
			xscale(range(`AXmin' `AXmax') noline)
			xlabel(none)
			yline(`borderline', lwidth(thin) lcolor(gs12))
			xtitle("") legend(off) xtick(""))
	 /*HERE ARE GRIDS */
		`betweengrids'			
	 /*HERE ARE THE CONFIDENCE INTERVALS */
		(pcspike `id' `lci' `id' `uci' if `use' == 1 , `ciopts')	
	 /*ADD ARROWS */
		(pcarrow `id' `uci' `id' `lci' if `leftarrow' == 1 &  `use' == 1 , `arrowopts')	
		(pcarrow `id' `lci' `id' `uci' if `rightarrow' == 1 &  `use' == 1, `arrowopts')	
		(pcbarrow `id' `lci' `id' `uci' if `biarrow' == 1 &  `use' == 1, `arrowopts')	
	 /*DIAMONDS FOR SUMMARY ESTIMATES -START FROM 9 O'CLOCK */
		(pcspike `DIAMleftY1' `DIAMleftX' `DIAMtopY' `DIAMtopX' if (`use' == 2 | `use' == 3) , `diamopts')
		(pcspike `DIAMtopY' `DIAMtopX' `DIAMrightY1' `DIAMrightX' if (`use' == 2 | `use' == 3) , `diamopts')
		(pcspike `DIAMrightY2' `DIAMrightX' `DIAMbottomY' `DIAMbottomX' if (`use' == 2 | `use' == 3) , `diamopts')
		(pcspike `DIAMbottomY' `DIAMbottomX' `DIAMleftY2' `DIAMleftX' if (`use' == 2 | `use' == 3) , `diamopts') 
	 /*HERE ARE THE PREDICTION INTERVALS */
		`cipred0'		
	 /*ADD ARROWS */
		`cipred1'
	 /*LAST OF ALL PLOT EFFECT MARKERS TO CLARIFY  */
		(scatter `id' `effect' if `use' == 1 , `pointopts')		
		,`fopts' 
		;
		#delimit cr		
			
		if "$by_index_" != "" {
			qui graph dir
			local gnames = r(list)
			local gname: word 1 of `gnames'
			tokenize `gname', parse(".")
			local gname `1'
			if "`3'" != "" {
				local ext =".`3'"
			}
			
			qui graph rename `gname'`ext' `gname'_$by_index_`ext', replace
			if "`graphsave'" != "" {
				graph save `graphsave'_$by_index, replace
			}
		}
		else {
			if "`graphsave'" != "" {
				di _n
				graph save `graphsave', replace
			}			
		}
end

/*==================================== GETWIDTH  ================================================*/
/*===============================================================================================*/
capture program drop getWidth
program define getWidth
version 14.1
//From metaprop

qui{

	gen `2' = 0
	count
	local N = r(N)
	forvalues i = 1/`N'{
		local this = `1'[`i']
		local width: _length "`this'"
		replace `2' =  `width' in `i'
	}
} 

end

