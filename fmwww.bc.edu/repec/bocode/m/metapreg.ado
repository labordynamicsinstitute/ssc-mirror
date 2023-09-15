/*
CREATED:	8 Sep 2017
AUTHOR:		Victoria N Nyaga
PURPOSE: 	Generalized linear fixed, mixed & random effects modelling of binomial data.
VERSION: 	3.0.0
NOTES
1. Variable names and group names should not contain underscore(_)
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
15.03.2022					design(independent|matched|paired|comparative|network, baselevel(string))
						    network data: n N Assignment covariates ....repeated measurements per study	
27.05.2022					Corrections on absoutp
							stratify + comparative + outplot(RR) 
11.02.2023					change network to abnetwork, paired to pcbnetwork, matched to mcbnetwork							
							Work on: hetout, stratify marginal results with 1 study
07.03.2023					change independent to general
21.03.2023					Compute weights from the maximized log likelihood
							Exact inference in few studies
18.04.2023					Use t-distribution for summaries
05.06.2023					Simulate posterior distributions
							smooth:Option to generate smooth estimates							
26.07.2023 					if version 16; use melogit instead of meqrlogit							
*/



/*++++++++++++++++++++++	METAPREG +++++++++++++++++++++++++++++++++++++++++++
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
		CImethod(string) //i=[wald, exact, score], o=[wald, exact, score, t]
		CIOpts(string) 
		DIAMopts(string) 
		DOUBLE 
		GOF //Goodness of fit
		DOWNload(string asis) 
		DP(integer 2) 
		Level(integer 95) 
		INTeraction
		LABEL(string) 
		LCols(varlist) 
		Model(string) //model(random|mixed|fixed|hexact, options)
		noGRaph 
		noOVerall 
		noOVLine 
		noSTats 
		noSUBgroup 
		noITAble
		noWT
		noBox
		SMooth
		OLineopts(string) 
		outplot(string)
		SUMTable(string) //none|logit|abs|rr|all
		DESign(string) //design(general|matched-mcbnetwork|paired-pcbnetwork|comparative|network-abnetwork, baselevel(string) | cov(inde|unstr))
		POINTopts(string) 
		BOXopts(string) 
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

	tempvar rid event nonevent total invtotal use id neolabel ///
			es se lci uci grptotal uniq mu use rid lpi upi obsid ///
			modeles modellci modeluci
			
	tempname nltest mctest samtrix logodds rrout absout logoddsi rrouti absouti    ///
			coefmat coefvar BVar WVar  omat isq2 bghet bshet lrtestp V dftestnl ptestnl lrtest ///
		outr absoutp absoutpi hetout hetouti popabsout popabsouti poprrout poprrouti
	/*Check for mu; its reserved*/
	qui ds
	local vlist = r(varlist)
	foreach v of local vlist {
		if "`v'" == "mu" {
			di in re "mu is a reserved variable name; drop or rename mu"
			exit _rc
		}
	}
	qui {		
		cap gen mu = 1
		cap gen _ESAMPLE = 0
		cap drop _WT
		gen _WT = .
		cap gen `modeles' = .
		cap gen `modellci' = .
		cap gen `modeluci' = .
	}
	
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
		local design = "general"
	}
	else {
		tokenize "`design'", parse(",")
		local design `1'
		
		//options
		local desopts "`3'"
		while "`desopts'" != "" {
			gettoken option desopts : desopts
			macro shift
			if strpos("`option'", "base") != 0 {
				local baselevel "`option'"
			}
			else if strpos("`option'", "cov") != 0 {
				local cov "`option'"
			}
			else {
				di as error "`option' not allowed in specifying the design()"
				exit
			}
		}
		if "`cov'" != "" {
			cap assert ("`design'" == "comparative")
			if _rc!=0 {
				di as error "The option `cov' only allowed in comparative meta-analysis"
				exit
			}
			if strpos("`cov'", "ind") !=0 {
				local cov "independent"
			}
			else if strpos("`cov'", "unst") !=0 {
				local cov "unstructured"
			}
			else {
				di as error "`cov' not allowed in specifying the design()"
				exit
			}
		}
	}	
	//depracated options
	if 	"`design'" == "paired" {
		di as res "Use of the option -design(paired)- is deprecated and replaced with -design(pcbnetwork)-"
		local design "pcbnetwork"
	}
	
	if "`design'" == "matched"  {
		di as res "Use of the option -design(matched)- is deprecated and replaced with -design(mcbnetwork)-"
		local design "mcbnetwork"
	}
	if "`design'" == "network" {
		di as res "Use of the option -design(network)- is deprecated and replaced with -design(abnetwork)-"
		local design "abnetwork"
	}
	
	if ("`design'" == "mcbnetwork") | ("`design'" == "pcbnetwork") {
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
	//Mixed or random are synonym
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
	else if (strpos("`model'", "r") == 1) | (strpos("`model'", "m") == 1) {
		local model "random"
	}
	else if strpos("`model'", "h") == 1 {
		local model "hexact"
	}
	else {
		di as error "Invalid option `model'"
		di as error "Specify either fixed, random, mixed, or hexact"
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

	//Avoid Incosistencies & Redundancies
	if "`stratify'" != "" & "`summaryonly'" != "" {
		local wt nowt
	}

	//Graph options
	if "`summaryonly'" != "" {
		local box "nobox"
	}
	
	if "`outplot'" == "abs" & "`design'" == "comparative" & "`model'" == "fixed" {
		local design "general" 	
	}
	
	qui count
	if `=r(N)' < 2 {
		di as err "Insufficient data to perform meta-analysis"
		exit 
	}
	if `=r(N)' < 3 & "`model'" != "hexact" {
		local model hexact //If less than 3 studies, use exact
		di as res _n  "Note: Homo-exact model imposed whenever number of studies is less than 3."
		if "`modelopts'" != "" {
			local modelopts
			di as res _n  "Warning: Model options ignored."
			di as res _n  "Warning: Consider re-specifying options for the fixed-effects model should the model not converge."
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
	if "`design'" == "general" | "`design'" == "comparative" | "`design'" == "abnetwork"  {
		gen `total' = `2'
		gen `event' = `1'
				
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
	else if "`design'" == "mcbnetwork" {
		local a = "`1'"
		local b = "`2'"
		local c = "`3'"
		local d = "`4'"
		cap assert "`6'" != ""
		if _rc != 0 {
			di as err "mcbnetwork data requires atleast 6 variable"
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
			di as error "The first & second covariate in cbnetwork analysis should be a string"
			exit _rc
		}
		cap confirm string variable `6'
		if _rc != 0 {
			di as error "The first & second covariate in cbnetwork analysis should be a string"
			exit _rc
		}
		macro shift 6
	}
	else if "`design'" == "pcbnetwork" {
		local event1 = "`1'"
		local event2 = "`2'"
		local Total = "`3'"
		cap assert "`5'" != ""
		if _rc != 0 {
			di as err "pcbnetwork data requires atleast 5 variable"
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
			di as error "The first & second covariate in pcbnetwork analysis should be a string"
			exit _rc
		}
		cap confirm string variable `5'
		if _rc != 0 {
			di as error "The first & second covariate in pcbnetwork analysis should be a string"
			exit _rc
		}
		macro shift 5
	}
	
	local regressors "`*'"
	local p: word count `regressors'
	
	if "`model'" == "hexact" {
		cap assert `p' == 0	
		if _rc != 0 {
			di as error "Covariates not allowed in the `model' model. Specify model(fixed) or model(mixed)"
			exit _rc
		}
	}
	
	if "`design'" == "comparative" | "`design'" == "abnetwork" {
		if "`model'" != "fixed" {
			cap assert `p' > 0
			if _rc != 0 {
				di as error "`design' analysis requires at least 1 covariate to be specified"
				exit _rc
			}
		}
		else {
			cap assert `p' > 1
			if _rc != 0 {
				di as error "`design' analysis requires at least 2 covariate to be specified"
				exit _rc
			}
		}
	}
	if "`design'" == "comparative" | "`design'" == "abnetwork"  {
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
			cap assert "`design'" != "general"
			if _rc != 0 {
				di as error "Option outplot(rr) only avaialable for comparative/mcbnetwork/pcbnetwork/abnetwork designs with first covariate as string"
				di as error "Specify the first string covariate and the appropriate design(comparative/mcbnetwork/pcbnetwork/abnetwork)"
				exit _rc
			}
		}
	}
	if "`design'" == "mcbnetwork" | "`design'" == "pcbnetwork" {
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
		//CI method
	if "`outplot'" == "rr" {
		if "`cimethod'" != "" {
			local ocimethod "`cimethod'"
			if (strpos("`ocimethod'", "t") != 1) &  (strpos("`ocimethod'", "w") != 1){
				di as error "Option `ocimethod' not allowed in cimethod(`cimethod')"
				exit	
			}
		}
		else {
			local ocimethod "wald"
		}
		if "`design'" == "mcbnetwork" {
			local icimethod "CML"
		}
		if "`design'" == "pcbnetwork" | "`design'" == "comparative"  {
			local icimethod "Koopman"
		}		
	}
	else {
		if "`cimethod'" != "" { 
			tokenize "`cimethod'", parse(",")
			local icimethod "`1'"
			if "`3'" != "" {
				local ocimethod = strltrim("`3'")
			}
		}
		if "`icimethod'" != "" {
			if (strpos("`icimethod'", "ex") != 1) & (strpos("`icimethod'", "wi") != 1) &  (strpos("`icimethod'", "wa") != 1) & (strpos("`icimethod'", "e") != 1) & (strpos("`icimethod'", "ag") != 1) & (strpos("`icimethod'", "je") != 1)   {
				di as error "Option `icimethod' not allowed in cimethod(`cimethod')"
				exit	
			}
		}
		else {
			local icimethod "wilson"
		}
		if "`ocimethod'" != "" {
			if "`model'" == "random" | "`model'" == "fixed" {
				if (strpos("`ocimethod'", "t") != 1) &  (strpos("`ocimethod'", "w") != 1){
					di as error "Option `ocimethod' not allowed in cimethod(`cimethod')"
					exit	
				}
			}
			else {
				if (strpos("`ocimethod'", "ex") != 1) & (strpos("`ocimethod'", "wi") != 1) &  (strpos("`ocimethod'", "wa") != 1) & (strpos("`icimethod'", "e") != 1) & (strpos("`ocimethod'", "ag") != 1) & (strpos("`ocimethod'", "je") != 1)   {
					di as error "Option `ocimethod' not allowed in cimethod(`cimethod')"
					exit	
				}
			}
		}
		else {
			if "`model'" == "random" | "`model'" == "fixed" { 
				local ocimethod "wald" 
			}
			else {
				local ocimethod "wilson"
			}
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
	
	if `p' < 2 & "`interaction'" !="" & ("`design'" != "`mcbnetwork'" | "`design'" != "`pcbnetwork'" ) {
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
	if "`design'" == "mcbnetwork" | "`design'" =="pcbnetwork" {
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
	
	buildregexpr `varlist', `interaction' `alphasort' `design' ipair(`ipair') `baselevel'  studyid(`studyid')
	
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
		local baselab:label `varx' 1
	}
	
	if "`design'" == "pcbnetwork" | "`design'" == "mcbnetwork" { 
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
	if ("`design'" == "general" | "`design'" == "comparative" ) {
		local nu = "mu"
	}
	else if "`design'" == "pcbnetwork" | "`design'" == "mcbnetwork" {
		if "`interaction'" != "" {
			local nu = "Ipair*`Comparator' + `Index'"
		}
		else {
			local nu = "mu + Ipair + `Index'"
		}			
	}
	else if "`design'" == "abnetwork" {
		local nu = "mu.`first'"
	}
	

	local VarX: word 1 of `regressors'
	forvalues i=1/`p' {
		local c:word `i' of `regressors'
		local nu = "`nu' + `c'"		
		
		if "`interaction'" != "" & `i' > 1 {
				local nu = "`nu' + `c'*`VarX'"			
		}
	}
	
	if ("`catreg'" != " " | "`typevarx'" =="i" | ("`design'" == "comparative" | "`design'" == "mcbnetwork" | "`design'" == "pcbnetwork"))  {

		if "`design'" == "mcbnetwork" | "`design'" == "pcbnetwork" {
			local catregs = "`catreg' `Index'"
		}

		if "`design'" == "comparative" {
			local catregs = "`catreg' `varx'" 
		}
		if "`design'" == "abnetwork" {
			tokenize `catreg'
			macro shift
			local catregs "`*'"
		}
		if "`design'" == "general" {
			local catregs "`catreg'"
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
	if "`design'" == "abnetwork" {
		local groupvar "`first'"
		local overall "nooverall"
		if "`outplot'" == "rr" {
			local itable "noitable"
		}
	} 
	*Stratify not allow in pcbnetwork, mcbnetwork or abnetwork analysis
	if "`stratify'" != "" {
		if ("`design'" == "pcbnetwork") | ("`design'" == "mcbnetwork") | ("`design'" == "abnetwork") {
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
	//nullify groupvar if its the studyid
	if "`groupvar'" == "`studyid'" {
		local groupvar
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
	local byrownames 
	local bybirownames
	
	
	if "`design'" == "abnetwork"  {
		local hetdim 7
	}
	else {
		if (`p' == 0) & ("`model'" == "random") &  ("`design'" != "pcbnetwork" | "`design'" != "mcbnetwork" )  {
			local hetdim 5
		}
		else {
			local hetdim 4
		}
	}
	
	//Should run atleast once
	while `i' < `=`nlevels' + 2' {
		local modeli = "`model'"
		local modeloptsi = "`modelopts'"
	
		//don't run last loop if stratify
		if (`i' > `nlevels') & ("`stratify'" != "") & ("`design'" == "comparative") {
			continue, break
		}
		
		*Stratify except the last loop for the overall
		if (`i' < `=`nlevels' + 1') & ("`stratify'" != "") {
			local strataif `"if `by' == `i'"'
			local ilab:label `by' `i'
			local stratalab `":`by' = `ilab'"'
			local ilab = ustrregexra("`ilab'", " ", "_")
			local byrownames = "`byrownames' `by':`ilab'"
			if "`design'" == "comparative" & "`stratify'" != "" {
				local bybirownames = "`bybirownames' `ilab':`baselab' `ilab':`ilab'"
			}

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
			if "`design'" == "mcbnetwork" | "`design'" == "pcbnetwork" {
				local Nobs = `Nobs'*0.5
			}
			qui egen `uniq' = group(`studyid')
			qui summ `uniq'
			local Nuniq = r(max)
			drop `uniq'
		}
		if "`design'" == "comparative" {
			cap assert mod(`Nobs', 2) == 0 
			if _rc != 0 {
				di as error "Comparative analysis requires 2 observations per study"
				exit _rc
			}
		}
		if "`design'" == "abnetwork" {
			cap assert `Nobs'/`Nuniq' >= 2 
			if _rc != 0 {
				di as error "abnetwork design requires atleast 2 observations per study"
				exit _rc
			}
		}		
		if (`Nobs' < 3 & "`modeli'" != "hexact" & "`design'" != "comparative") | ((`Nobs' < 5 ) & ("`modeli'" == "random") & ("`design'" == "comparative")) {
			local modeli hexact //If less than 3 studies, use exact model
			if "`modeloptsi'" != "" {
				local modeloptsi
				noi di as res _n  "Warning: `model'-effects model options ignored."
				noi di as res _n  "Warning: Homo-exact model fitted instead."
			}
		}
		
		di as res _n "*********************************** Fitted model`stratalab' ***************************************"  _n
		
		tokenize `depvars'
		if "`design'" == "general" | "`design'" == "abnetwork" | "`design'" == "comparative" {
				di "{phang} `1' ~ binomial(p, `2'){p_end}"
		}
		else if "`design'" == "mcbnetwork"  {
			di "{phang} `1' + `2'  ~ binomial(p, `1' + `2' + `3' + `4'){p_end}"
			di "{phang} `1' + `3' ~ binomial(p, `1' + `2' + `3' + `4'){p_end}"
		}
		else if "`design'" == "pcbnetwork" {
			di "{phang} `1' ~ binomial(p, `3'){p_end}"
			di "{phang} `2' ~ binomial(p, `3'){p_end}"
		}
		
		if "`modeli'" == "random" {
			if "`cov'" == "" {
				di "{phang} logit(p) = `nu' + `studyid'{p_end}"	
			}
			else {
				di "{phang} logit(p) = `nu' + `first'.`studyid' + `studyid'{p_end}"	
			}
			if "`cov'" == "" {
				di "{phang}`studyid' ~ N(0, tau2){p_end}"
			}
			if "`cov'" == "independent" {
				di "{phang}`studyid' ~ N(0, tau2){p_end}"
				di "{phang}`first'.`studyid' ~ N(0, sigma2){p_end}"
			}
			if "`cov'" == "unstructured" {
				di "{phang}`studyid',`first'.`studyid'  ~ biv.normal(0, Sigma){p_end}"
			}
			
		}
		else if "`modeli'" == "fixed" {
			di "{phang} logit(p) = `nu'{p_end}"		
		}
		if "`design'" == "pcbnetwork" | "`design'" == "mcbnetwork" {
			di "{phang} Ipair = 0 if 1st pair{p_end}"
			di "{phang} Ipair = 1 if 2nd pair{p_end}"
		}
		if "`design'" == "abnetwork" {
			di "{phang}`first' ~ N(0, sigma2){p_end}"
			qui label list `first'
			local nfirst = r(max)
		}		
		if ("`catreg'" != " " | "`typevarx'" =="i" | ("`design'" == "comparative" | "`design'" == "mcbnetwork" | "`design'" == "pcbnetwork"))  {
			di _n "{phang}Base levels{p_end}"
			di _n as txt "{pmore} Variable  -- Base Level{p_end}"
		}
		foreach fv of local catregs  {			
			local lab:label `fv' 1
			if "`fv'" != "`studyid'" {
				di "{pmore} `fv'  -- `lab'{p_end}"
			}			
		}
		if "`design'" == "abnetwork" {
			local lab:label `first' `basecode'
			di "{pmore} `first'  -- `lab'{p_end}"
		}
			
		di _n
		di "{phang}" as txt "Number of observations = " as res "`Nobs'{p_end}"
		di "{phang}" as txt "Number of studies = " as res "`Nuniq'{p_end}"
		if "`design'" == "abnetwork" {
			di "{phang}" as txt "Number of `first's = " as res "`nfirst'{p_end}"
		}

		di _n"*********************************** ************* ***************************************" _n
		
		*Run model if more than 1 study
		if (`Nobs' > 1) {
			preg `event' `total' `strataif', rid(`rid') studyid(`studyid') use(`use') regexpression(`regexpression') nu(`nu') ///
				regressors(`regressors') catreg(`catreg') contreg(`contreg') level(`level') varx(`varx') typevarx(`typevarx')  /// 
				`progress' model(`modeli') modelopts(`modeloptsi') `mc' `interaction' `design' by(`by') `stratify' baselevel(`basecode') ///
				comparator(`Comparator') cimethod(`ocimethod') `gof'  ///
				modeles(`modeles')  modellci(`modellci') modeluci(`modeluci') outplot(`outplot') `smooth' cov(`cov')
	
			mat `logoddsi' = r(logodds)
			mat `popabsouti' = r(popabsout)
			local mdf = r(mdf) //mdf = 0 if saturated
			
			if "`catreg'" != " " | "`typevarx'" == "i"  {
				mat `rrouti' = r(rrout)
				mat `poprrouti' = r(poprrout)
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
			mat `absoutpi' = r(absoutp)

			if "`modeli'" == "random" { 
				mat `hetouti' = r(hetout)	
			}
			else {
				/*if "`design'" != "comparative" {
					mat `absoutpi' = J(1, 2, 0)
				}
				else {
					mat `absoutpi' = J(2, 2, 0)
				}*/
				
				mat `hetouti' = J(1, `hetdim', .)
			}
		}
		*if 1 study or exact inference
		else {
			mat `logoddsi' = J(1, 6, .)
			mat `popabsouti' = J(1, 5, .)
			mat `absouti' = J(1, 6, .)
			mat `absoutpi' = J(1, 2, .)
			mat `hetouti' = J(1, `hetdim', .)		
			mat `rrouti' = J(1, 6, 1)
			mat `poprrouti' = J(1, 5, 1)			
			qui replace `use' = 1 `strataif'
		}
		
		*Stack the matrices
		if `i' == 1 {
			mat `absout' =	`absouti'
			if "`rr'" == "" {			
				mat `rrout' =	`rrouti'
				mat `poprrout' = `poprrouti'
			}			
			mat `logodds' = `logoddsi'
			mat `popabsout' = `popabsouti'
			mat `absoutp' = `absoutpi'
			mat `hetout' = `hetouti'		
		}
		else {
			mat `absout' = `absout' \ `absouti'
			mat `popabsout' = `popabsout' \ `popabsouti'				
			if "`rr'" == "" {
				mat `rrout' = `rrout' \ `rrouti'
				mat `poprrout' = `poprrout' \ `poprrouti'
			}
			mat `logodds' = `logodds' \ `logoddsi'
			mat `absoutp' = `absoutp' \ `absoutpi'
			mat `hetout' = `hetout' \ `hetouti'
		}
		local ++i
	} 

	*End loop
	//rownames for the matrix
	if "`stratify'" != "" & `i' > 1 {
		mat rownames `hetout' = `byrownames'
		
		if "`design'" != "comparative" {
			mat rownames `absout' = `byrownames'
			mat rownames `popabsout' = `byrownames'
			mat rownames `absoutp' = `byrownames'
			mat rownames `logodds' = `byrownames'
		}
		else {
			mat rownames `absout' = `bybirownames'
			mat rownames `popabsout' = `bybirownames'
			mat rownames `absoutp' = `bybirownames'
			mat rownames `logodds' = `bybirownames'
		}

		if "`rr'" == "" {
			mat rownames `rrout' = `byrownames'
			mat rownames `poprrout' = `byrownames'
		}
	}
	//If stratify, no overall for comparative
	if "`stratify'" != "" & "`design'" == "comparative" {
		local overall "nooverall"
	}
	
	//CI
	if "`outplot'" == "rr" {
		local se
	}
	if "`outplot'" == "rr" & "`design'" == "abnetwork" {
		local summaryonly "summaryonly"
		local smooth
	}
	
	if "`design'" == "mcbnetwork" | "`design'" == "pcbnetwork" {
		*widesetup `event' `total', sid(`rid') idpair(`assignment')  jvar(`comparator')
		
		sort `rid'
		qui drop `assignment' `ipair'
		
		qui reshape wide `event' `total' _WT `modeles' `modellci' `modeluci', i(`rid') j(`idpair')
		*qui reshape wide `event' `total' `index' `assignment', i(`rid') j(`comparator')	
		
		*koopmanci `event'1 `total'1 `event'0 `total'0, rr(`es') upperci(`uci') lowerci(`lci') alpha(`=1 - `level'*0.01')
		*gen `id' = `rid'

		//Add the weights
		qui gen _WT = _WT0 + _WT1
		qui drop _WT0  _WT1
		
		qui gen `modeles' = `modeles'1
		qui drop `modeles'0 `modeles'1
		
		qui gen `modellci' = `modellci'1
		qui drop `modellci'0 `modellci'1
		
		qui gen `modeluci' = `modeluci'1
		qui drop `modeluci'0 `modeluci'1
	}
		
	qui metapregci `depvars', studyid(`studyid') first(`first') es(`es') se(`se') uci(`uci') lci(`lci') `design' ///
		id(`id') rid(`rid') regressors(`regressors') outplot(`outplot') level(`level') ///
		cimethod(`icimethod') lcols(`lcols') rcols(`rcols')  sortby(`sortby') by(`by')  ///
		modeles(`modeles') modellci(`modellci') modeluci(`modeluci') `smooth'
	
	local depvars = r(depvars)
	local rcols = r(rcols)
	local lcols = r(lcols)
	local sortby = r(sortby)
	if (`p' > 0) {
		local indvars = r(regressors)
	}
	
	if `mdf' == 0 {
		local smooth
	}
	
	
	qui prep4show `id' `use' `neolabel' `es' `lci' `uci' `modeles' `modellci' `modeluci', `design' ///
		sortby(`sortby') groupvar(`groupvar') grptotal(`grptotal') se(`se') 	///
		outplot(`outplot') rrout(`rrout') poprrout(`poprrout') popabsout(`popabsout') absout(`absout') absoutp(`absoutp') hetout(`hetout')	///
	    `subgroup' `summaryonly' dp(`dp') pcont(`pcont') model(`model') `prediction'	///
		`overall' download(`download') indvars(`indvars') depvars(`depvars') `stratify' level(`level')
	
	if "`itable'" == "" {
		disptab `id'  `use' `neolabel' `es' `lci' `uci' `grptotal' `modeles' `modellci' `modeluci', `itable' dp(`dp') power(`power') ///
			`subgroup' sumstat(`sumstat') level(`level') `wt' `smooth' ocimethod(`ocimethod') icimethod(`icimethod') model(`model') 
    }		
		
	//Extra tables
	if ("`sumtable'" != "none") {
		di as res _n "****************************************************************************************"
	}
	//logodds
	if  (("`sumtable'" == "all") |(strpos("`sumtable'", "logit") != 0)) {
		printmat, matrixout(`logodds') type(logit) p(`p') dp(`dp') power(`power') `continuous' model(`model')
	}
	//abs
	if  (("`sumtable'" == "all") |(strpos("`sumtable'", "abs") != 0)) {
		printmat, matrixout(`absout') type(abs) p(`p') dp(`dp') power(`power') `continuous'  model(`model')
	}
	//Pop p 
	if  (("`sumtable'" == "all") |(strpos("`sumtable'", "abs") != 0)) & "`model'" !="hexact" {
		printmat, matrixout(`popabsout') type(popabs) dp(`dp') power(`power') 
	}
	//het
	if "`model'" =="random" {			
		printmat, matrixout(`hetout') type(het) dp(`dp') `design'
	}
	
	//rr
	if (("`sumtable'" == "all") | (strpos("`sumtable'", "rr") != 0)) & (("`catreg'" != " ") | ("`typevarx'" == "i"))   {
		//rr
		printmat, matrixout(`rrout') type(rr) p(`p') dp(`dp') power(`power')  model(`model')
		
		//rr equal
		if "`inltest'" == "yes" {
			printmat, matrixout(`nltest') type(rre) dp(`dp')
		}

		printmat, matrixout(`poprrout') type(poprr) p(`p') dp(`dp') power(`power')  model(`model')
	}	
	//model comparison
	if ((`p' > 0 & "`design'" != "abnetwork") | (`p' > 1 & "`design'" == "abnetwork")) & ("`mc'" =="") {
		printmat, matrixout(`mctest') type(mc) dp(`dp')  
	}
	
	//Draw the forestplot
	if "`graph'" == "" {
		fplot `es' `lci' `uci' `use' `neolabel' `grptotal' `id' `modeles' `modellci' `modeluci', model(`model') ///	
			studyid(`studyid') power(`power') dp(`dp') level(`level') ///
			groupvar(`groupvar') `prediction'  ///
			outplot(`outplot') lcols(`lcols') rcols(`rcols') ///
			ciopts(`ciopts') astext(`astext') diamopts(`diamopts') ///
			olineopts(`olineopts') sumstat(`sumstat') pointopt(`pointopts') boxopt(`boxopts') ///
			`double' `subline' texts(`texts') `xlabel' `xtick' ///
			`ovline' `stats'  graphsave(`graphsave')`fopts' `xline' `logscale' `design' `wt' `box' `smooth'
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
		ereturn matrix popabsout = `popabsout'
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
		ereturn matrix poprrout = `poprrout'
	}
	restore	
end

/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: ESTCOVAR +++++++++++++++++++++++++
							Compose the var-cov matrix
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
cap program drop estcovar
program define estcovar, rclass
version 14.1

	syntax, matrix(name) cov(string) 
	*matrix is colvector
	tempname matcoef rosevar rawvar
	mat `matcoef' = `matrix''
	local nrows = rowsof(`matcoef')
	*Initialize - Default
	mat	`rosevar' = (0, 0\ ///
				0, 0)
	mat	`rawvar' = (0, 0\ ///
				0, 0)			

	if strpos("`cov'", "uns") != 0 {
		mat	`rosevar' = (exp(`matcoef'[`nrows' - 1 , 1])^2, exp(`matcoef'[ `nrows' - 1, 1])*exp(`matcoef'[`nrows' - 2, 1])*tanh(`matcoef'[ `nrows', 1])\ ///
					exp(`matcoef'[ `nrows' - 1, 1])*exp(`matcoef'[`nrows' - 2, 1])*tanh(`matcoef'[ `nrows', 1]), exp(`matcoef'[ `nrows' - 2, 1])^2)
					
		mat	`rawvar' = (`matcoef'[`nrows' - 1 , 1], `matcoef'[ `nrows', 1]\ ///
					`matcoef'[ `nrows', 1], `matcoef'[ `nrows' - 2, 1])			
		local k = 3
	}		
	else if strpos("`cov'", "ind") != 0 {
		mat	`rawvar' = (`matcoef'[ `nrows', 1], 0\ ///
					0, `matcoef'[ `nrows' - 1, 1])
		mat	`rosevar' = (exp(`matcoef'[ `nrows', 1])^2, 0\ ///
					0, exp(`matcoef'[ `nrows'-1, 1])^2)			
		local k = 2
	}
	return matrix rosevar = `rosevar' 
	return matrix rawvar = `rawvar' 
	return local k = `k' 
end

/**************************************************************************************************
							METAPREGCI - CONFIDENCE INTERVALS
**************************************************************************************************/
capture program drop metapregci
program define metapregci, rclass
	version 14.1
	#delimit ;
	syntax varlist(min=2 max=4), studyid(varname) [first(varname) es(name) se(name) uci(name) lci(name)
		id(name) rid(varname) regressors(varlist) outplot(string) level(integer 95) by(varname)
		cimethod(string) lcols(varlist) rcols(varlist) mcbnetwork pcbnetwork sortby(varlist) 
		comparative abnetwork general modeles(varname) modellci(varname) modeluci(varname) smooth
		];
	#delimit cr
	tempvar uniq event event1 event2 total total1 total2 a b c d idpair
	*gettoken idpair confounders : regressors
	
	tokenize `varlist'
	if "`mcbnetwork'`pcbnetwork'" == "" {
		generate `event' = `1'
		generate `total' = `2'
		local depvars "`1' `2'"
	}
	else if "`mcbnetwork'" != ""  {
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
		if "`abnetwork'" != "" {
			gen `id' = _n
			gen `es' = .
			gen `lci' = .
			gen `uci' = .
		}
		if "`mcbnetwork'" != "" { //constrained maximum likelihood estimation
			cmlci `a' `b' `c' `d', rr(`es') upperci(`uci') lowerci(`lci') alpha(`=1 - `level'*0.01')
		}
		if "`pcbnetwork'" !="" {		
			koopmanci `event1' `total1' `event2' `total2', rr(`es') upperci(`uci') lowerci(`lci') alpha(`=1 - `level'*0.01')
		}
		if "`comparative'" != "" {
			egen `id' = group(`studyid' `by')
			sort `id' `rid'
			by `id': egen `idpair' = seq()

			qui count
			local Nobs = r(N) /*Check if the number of studies is half*/
			cap assert  mod(`Nobs', 2) == 0 
			if _rc != 0 {
				di as error "More than two observations per study for some studies"
				exit _rc, STATA
			}

			sort `id'  `idpair'
			
			if "`=`studyid'[1]'" != "`=`studyid'[2]'" {
				di as error "Data not properly sorted. `studyid' in row 1 and 2 should be the same. "
				exit _rc, STATA
			}
			
			widesetup `event' `total' `confounders' , sid(`id') idpair(`idpair') sortby(`sortby')
			local vlist = r(vlist)
			local cc0 = r(cc0)
			local cc1 = r(cc1)
			
			koopmanci `event'1 `total'1 `event'0 `total'0, rr(`es') upperci(`uci') lowerci(`lci') alpha(`=1 - `level'*0.01')
						
			//Rename the varying columns
			local newcc0: label `first' `cc0'
			local newcc1: label `first' `cc1'
			
			foreach v of local vlist {
				rename `v'0 `v'_`cc0'
				label var `v'_`cc0' "`v'_`newcc0'"
				rename `v'1 `v'_`cc1'
				label var `v'_`cc1' "`v'_`newcc1'"
			}
			//Add the weights
			qui gen _WT = _WT_1 + _WT_2
			qui drop _WT_1  _WT_2
			
			//Remove unnecessary columns
			if "`smooth'" !="" {
				qui drop `modeles'_1
				rename `modeles'_2 `modeles'
				
				qui drop `modellci'_1
				rename `modellci'_2 `modellci'
				
				qui drop `modeluci'_1
				rename `modeluci'_2 `modeluci'
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
	if "`sortby'" == "" {
		local sortby = " "
	}
	return local regressors = "`regressors'"
	return local depvars = "`depvars'"
	return local rcols = "`rcols'"
	return local lcols = "`lcols'"
	return local sortby = "`sortby'"
end
/**************************************************************************************************
							PREG - REGRESSIONS 
**************************************************************************************************/
capture program drop preg
program define preg, rclass

	version 14.1
	#delimit ;

	syntax varlist(min=2 ) [if] [in], studyid(varname) use(varname) [
		regexpression(string) nu(string) baselevel(passthru) rid(varname)
		regressors(varlist) varx(varname) typevarx(string) comparator(varname) catreg(varlist) contreg(varlist)
		cimethod(string) cov(string)
		level(integer 95)
		DP(integer 2)
		progress
		model(string) modelopts(string) outplot(string)
		noMC noCONstant
		interaction	
		comparative mcbnetwork pcbnetwork abnetwork
		by(varname) stratify
		GOF
		modeles(varname) modelse(varname) modellci(varname) modeluci(varname) smooth
			*];

	#delimit cr
	marksample touse, strok 
	
	tempvar event total invtotal predevent ill iw
	tempname coefmat coefvar testlr V logodds absout absoutp rrout nltest hetout mctest absexact newobs matgof popabsout poprrout rosevar rawvar
	
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
	
	
	if "`mcbnetwork'`pcbnetwork'" != "" {		
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
	`echo' fitmodel `event' `total' if `touse', modelopts(`modelopts') model(`model') regexpression(`regexpression') ///
		sid(`studyid') level(`level') nested(`first') `abnetwork' cov(`cov') 

	estimates store metapreg_modest
	qui replace _ESAMPLE = e(sample) 
	qui replace `use' = 1 if (_ESAMPLE == 1)
	
	mat `coefmat' = e(b)
	mat `coefvar' = e(V)
	
	local DF = e(N) -  e(k)
	local mdf = e(df) //mdf = 0 if saturated model

	if "`model'" == "random" {
		local BHET = e(chi2_c)
		local P_BHET = e(p_c)
		if "`abnetwork'" == "" {
			local DF_BHET = 1
		}
		else {
			local DF_BHET = 2
		}
		if "`cov'" != "" {
			estcovar, matrix(`coefmat') cov(`cov')
			local DF_BHET = r(k)
			mat `rosevar' = r(rosevar)  //var-cov matrix
			mat `rawvar' = r(rawvar)  //raw var-cov matrix
			mat colnames `rosevar' = intercept slope
			mat rownames `rosevar' = intercept slope
			mat colnames `rawvar' = intercept slope
			mat rownames `rawvar' = intercept slope
		}
	}
	else {
		local BHET = .
		local P_BHET = .
		local DF_BHET = .
	}
	
	qui estat ic
	mat `matgof' = r(S)
	local BIC =  `matgof'[1, 6]
	
	//Display GOF
	if ("`gof'" != "") {
		di as text "Goodness of Fit Criterion"
		mat `matgof' = `matgof'[1..., 5..6]
		mat rownames `matgof' = Value
		#delimit ;
		noi matlist `matgof',  
					cspec(& %7s |   %8.`=`dp''f &  %8.`=`dp''f o2&) 
					rspec(&-&) underscore  nodotz
		;
		#delimit cr 
	}

	if "`model'" == "hexact" {
		qui {
		//Exact inference
			mat `absexact' = J(1, 6, .)
			sum `event' if `touse'
			local sumevent = r(sum)
			sum `total' if `touse'
			local sumtotal = r(sum)
			local DF = r(N) - 1

			cii prop `sumtotal' `sumevent', `cimethod' level(`level') 
			
			mat `absexact'[1, 1] = r(proportion) 
			mat `absexact'[1, 2] = r(se)
			mat `absexact'[1, 5] = r(lb) 
			mat `absexact'[1, 6] = r(ub)
			
			local zvalue = (`absexact'[1, 1] - 0.5)/sqrt(0.25/`sumtotal')
			mat `absexact'[1, 3] = `zvalue'
			
			local pvalue = normprob(-abs(`zvalue'))*2
			mat `absexact'[1, 4] = `pvalue'
			}
	}
	
	//Obtain the prediction
	if "`model'" != "hexact" {
		//if random, needs atleast 7 studies to run predict command
		qui count
		local nobs = r(N)
		if "`model'" == "random" {
			if ((`nobs' < 7) & ("`model'" == "random")) {
				local multipler = int(ceil(7/`nobs'))
				qui expand `multipler', gen(`newobs')
			}
		}
		qui predict `predevent', mu
		//Revert to original data if filler data was generated
		 if (("`model'" == "random") & (`nobs' < 7))  {
			qui keep if !`newobs'
		}
	}
	else {
		qui gen `predevent' = `absexact'[1, 1]*`total' if (_ESAMPLE == 1)
	}
	
	//compute the weight
	if "`model'" == "random" {
		qui gen `iw' = `total'*(`predevent'/`total')*(1 - `predevent'/`total')
	}
	else {
		qui gen `iw' = `total'
	}
	
	//compute the relative weight
	*qui gen `ill' = `event'*ln(`predevent'/`total') + (`total' - `event')*ln(1 - (`predevent'/`total')) if (_ESAMPLE == 1)	
	qui sum `iw' if (_ESAMPLE == 1)
	local W = r(sum)
	
	//compute the weights
	qui replace _WT = (`iw'/`W')*100 if (_ESAMPLE == 1) & (_WT == .)

	if "`model'" == "random" {
		local npar = colsof(`coefmat')
		local scalefn "exp"
		local scalepow "2"
		
		if "`abnetwork'`cov'" == "" {
			local TAU21 = `scalefn'(`coefmat'[1, `npar'])^`scalepow' //Between study variance	1
			local TAU22 = 0
		}
		else if "`abnetwork'" != "" {
			local TAU21 = `scalefn'(`coefmat'[1, `=`npar'-1'])^`scalepow' //Between study variance	1
			local TAU22 = `scalefn'(`coefmat'[1, `npar'])^`scalepow' //Between study variance	2
		}
		else if "`cov'" != "" {
			local TAU21 = `rosevar'[1, 1]
			local TAU22 = `rosevar'[2, 2]
			if "`cov'" == "unstructured" {
				local rho = tanh(`rawvar'[1, 2])
			}  
		}
	}
	else {
		local TAU21 = 0
		local TAU22 = 0
	}
	local ISQ1 = .
	local ISQ2 = .
	if (`p' == 0) & ("`model'" == "random") & ("`pcbnetwork'`mcbnetwork'" == "")  {
		/*Compute I2*/				
		qui gen `invtotal' = 1/`total'
		qui summ `invtotal' if `touse'
		local invtotal= r(sum)
		local K = r(N)
		local Esigma = (exp(`TAU21'*0.5 + `coefmat'[1, 1]) + exp(`TAU21'*0.5 - `coefmat'[1, 1]) + 2)*(1/(`K'))*`invtotal'
		local ISQ1 = `TAU21'/(`Esigma' + `TAU21')*100	
	}
	else if "`abnetwork'`cov'" != "" & ("`model'" == "random") {
		local ISQ1 = `TAU21'/(`TAU21' + `TAU22')*100
		local ISQ2 = `TAU22'/(`TAU21' + `TAU22')*100		
	}
	local redindex 0
	if ((`p' > 0 & "`abnetwork'" == "") | (`p' > 1 & "`abnetwork'" != "") | ("`interaction'" != "" & "`pcbnetwork'`mcbnetwork'" != "") ) & "`mc'" == "" {
		
		di _n"*********************************** ************* ***************************************" _n
		di as txt _n "Just a moment - Fitting reduced model(s) for comparison"
		if "`abnetwork'`interaction'" !="" {
			if "`mcbnetwork'`pcbnetwork'" != "" {
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
			if ("`interaction'" != "" & "`pcbnetwork'`mcbnetwork'" != "")  {
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
			local ++redindex
			di as res _n "`redindex'. Ommitted `omterm' in logit(p)"
			if "`model'"  == "random" {
				di as res "{phang} logit(p) = `eqreduced' + `studyid'{p_end}"
			}
			else {
				di as res "{phang} logit(p) = `eqreduced'{p_end}"
			}
			if "`omterm'" == "`first'" {
				local newcov 
			}
			else {
				local newcov "`cov'"
			}
			
			`echo' fitmodel `event' `total' if `touse',  modelopts(`modelopts') model(`model') ///
				regexpression(`nureduced') sid(`studyid') level(`level')  nested(`first') `abnetwork' cov(`newcov')
			
			qui estat ic
			mat `matgof' = r(S)
			local BICmc = `matgof'[1, 6]
			estimates store metapreg_Null
			
			//LR test the model
			qui lrtest metapreg_modest metapreg_Null, force
			local lrp :di %10.`dp'f chi2tail(r(df), r(chi2))
			local lrchi2 = r(chi2)
			local lrdf = r(df)
			estimates drop metapreg_Null
			
			if `initial' == 1  {
				mat `mctest' = [`lrchi2', `lrdf', `lrp', `=`BIC' -`BICmc'']
			}
			else {
				mat `mctest' =  `mctest' \ [`lrchi2', `lrdf', `lrp', `=`BIC' -`BICmc'']
			}
			local rownameslr "`rownameslr' `omterm'"
			
			local initial 0
		}
		//Ultimate null model
		if (`p' > 1 & "`abnetwork'" == "") | (`p' > 2 & "`abnetwork'" != "")  {
			local ++redindex 
			di as res _n "`redindex'. Ommitted all covariate effects in logit(p)"
			
			
			if "`abnetwork'" != ""  {
				local regexpression "ibn.`first'"
			}
			else if "`pcbnetwork'`mcbnetwork'" != "" {
				local regexpression "mu i.`ipair' i.`index'"
			}
			else {
				local regexpression "mu"
			}
			
			`echo' fitmodel `event' `total' if `touse', modelopts(`modelopts') model(`model') regexpression(mu) ///
				sid(`studyid') level(`level')  nested(`first') `abnetwork' 
			
			qui estat ic
			mat `matgof' = r(S)
			local BICmc = `matgof'[1, 6]
			
			estimates store metapreg_Null
			
			qui lrtest metapreg_modest metapreg_Null
			local lrchi2 = r(chi2)
			local lrdf = r(df)
			local lrp :di %10.`dp'f r(p)
			
			estimates drop metapreg_Null
			
			mat `mctest' = `mctest' \ [`lrchi2', `lrdf', `lrp', `=`BIC' -`BICmc'']
			local rownameslr "`rownameslr' All"
		}
		mat rownames `mctest' = `rownameslr'
		mat colnames `mctest' =  chi2 df p Delta_BIC
	}
	
	//LOG ODDS
	estp, studyid(`studyid') estimates(metapreg_modest) `interaction' catreg(`catreg') contreg(`contreg') level(`level') model(`model') cimethod(`cimethod')  ///
		varx(`varx') typevarx(`typevarx') by(`by') regexpression(`regexpression') `mcbnetwork' `comparative' `pcbnetwork' `abnetwork' `stratify'  ///
		comparator(`comparator') 	
	mat `logodds' = r(outmatrix)
	
	//simulations
	postsim, orderid(`rid') studyid(`studyid') todo(abs) estimates(metapreg_modest) logodds(`logodds') ///
			level(`level')  model(`model')  by(`by') `comparative' `interaction' `abnetwork' ///
			`mcbnetwork' varx(`varx')  cov(`cov')
			
	mat `popabsout' = r(outmatrix)
	
	//ABS
	estp, studyid(`studyid') estimates(metapreg_modest) `interaction'  catreg(`catreg') ///
		contreg(`contreg') level(`level')  model(`model') cimethod(`cimethod') ///
		varx(`varx') typevarx(`typevarx') expit by(`by') regexpression(`regexpression') ///
		`comparative' `mcbnetwork' `pcbnetwork' `abnetwork' `stratify'  ///
		comparator(`comparator') 
	mat `absout' = r(outmatrix)
	mat `absoutp' = r(outmatrixp)
	
	//RR
	if "`catreg'" != "" | "`typevarx'" == "i" {
		estr, studyid(`studyid') estimates(metapreg_modest)  catreg(`catreg') ///
			level(`level') comparator(`comparator') `interaction' cimethod(`cimethod') ///
			varx(`varx') typevarx(`typevarx') by(`by') `mcbnetwork' `pcbnetwork' ///
			`comparative' `abnetwork' `stratify' ///
			regexpression(`regexpression') `baselevel' 
		
		mat `rrout' = r(outmatrix)
		local inltest = r(inltest)
		if "`inltest'" == "yes" {
			mat `nltest' = r(nltest) //if RR by groups are equal
		}
		
		//simulations
		postsim, orderid(`rid') studyid(`studyid') todo(rr) estimates(metapreg_modest) rrout(`rrout') ///
				 level(`level')  model(`model')  by(`by') `comparative' `interaction' `abnetwork' ///
				 `baselevel' `mcbnetwork' varx(`varx')  cov(`cov')
		
		mat `poprrout' = r(outmatrix)
		
	}

	//Smooth estimates
	//simulations
	if "`smooth'" != "" {
		postsim, orderid(`rid') studyid(`studyid') todo(smooth) estimates(metapreg_modest)  ///
				level(`level')  model(`model')  by(`by') `comparative'  ///
				modeles(`modeles') modellci(`modellci') modeluci(`modeluci') outplot(`outplot')	///
				`interaction' `abnetwork'  `mcbnetwork' varx(`varx')  cov(`cov')
	}

	if "`model'" == "hexact" {
		cap confirm matrix `absout'
		if _rc == 0 {
			local nrowsp = rowsof(`absout')
		}
		else{
			mat `absout' = `absexact'
		}
		//Replace the value with the exact
		forvalues r = 1(1)`nrowsp' {
			forvalues c = 1(1)6 {
				mat `absout'[`r', `c']	 = `absexact'[1, `c']	
			}			
		}
		mat colnames `absout' = Mean SE z(score) P>|z| Lower Upper
	}
	//===================================================================================
	//Return the matrices
	if "`abnetwork'`cov'" != "" {
		if "`cov'" == "unstructured" {
			mat `hetout' = (`DF_BHET', `BHET' ,`P_BHET', `TAU21', `TAU22', `rho', `ISQ1', `ISQ2')
			mat colnames `hetout' = DF Chisq p tau2 sigma2 rho I2tau I2sigma 
		}
		else {
			mat `hetout' = (`DF_BHET', `BHET' ,`P_BHET', `TAU21', `TAU22', `ISQ1', `ISQ2')
			mat colnames `hetout' = DF Chisq p tau2 sigma2 I2tau I2sigma 
		}
	}
	else {
		if (`p' == 0) & ("`model'" == "random") & "`pcbnetwork'`mcbnetwork'" == "" {
			mat `hetout' = (`DF_BHET', `BHET' ,`P_BHET', `TAU21', `ISQ1')
			mat colnames `hetout' = DF Chisq p tau2 I2tau 
		}
		else {
			mat `hetout' = (`DF_BHET', `BHET' ,`P_BHET', `TAU21')
			mat colnames `hetout' = DF Chisq p tau2 
		}
	}
	mat rownames `hetout' = Model
	return matrix hetout = `hetout'
	return local inltest = "`inltest'"
										
	cap confirm matrix `logodds'
	if _rc == 0 {
		return matrix logodds = `logodds'
		return matrix popabsout = `popabsout'
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
		return matrix poprrout = `poprrout'
	}
	if "`inltest'" == "yes" {
		return matrix nltest = `nltest'
	}
	cap confirm matrix `mctest'
	if _rc == 0 {
		return matrix mctest = `mctest'
	}
	return scalar mdf = `mdf'
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
	/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: FITMODEL +++++++++++++++++++++++++
								Fit the regression model
	+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	 
cap program drop fitmodel
program define fitmodel
	version 14.1
	syntax varlist [if] [in], [ model(string) modelopts(string asis) regexpression(string) sid(varname) ///
		level(integer 95) mcbnetwork pcbnetwork abnetwork general comparative nested(string) cov(string) ]
	
	marksample touse, strok 
	
	tokenize `varlist'
	if "`cov'" != "" {
		local varx "`nested'"
		if "`cov'" == "unstructured" {
			local cov "cov(`cov')"
		}
		else {
			local cov
		}
	}
	else {
		local varx
		local cov
	}
	if "`abnetwork'" != "" & "`model'" == "random" {
		local nested = `"|| (`nested': )"'
	}
	else {
		local nested
	}
	
	if _caller() >= 16 {
		local fitcommand "melogit"
	}
	else {
		local fitcommand "meqrlogit"
	}
	
	if ("`model'" != "random") {
		capture noisily binreg `1' `regexpression' if `touse', noconstant n(`2') ml `modelopts' l(`level')
		*capture noisily glm `1' `regexpression' if `touse', noconstant family(binomial `2') link(`flink') ml `modelopts' l(`level')
		local success = _rc
	}
	if ("`model'" == "random") {
		if strpos(`"`modelopts'"', "intpoi") == 0  {
			qui count if `touse'
			if `=r(N)' < 7 {
				local ipoints = `"intpoints(`=r(N)')"'
			}
		}
		else {
			qui count if `touse'
			local nobs =r(N)
			
			local oldopts `"`modelopts'"'
			local modelopts
			while `"`oldopts'"' != "" {
				gettoken first oldopts : oldopts
				if strpos(`"`first'"', "intpoi")!= 0  {
					local b1 = strpos(`"`first'"', "(") + 1
					local b2 = strpos(`"`first'"', ")") 
					local oldpoints = substr(`"`first'"', `b1', `=`b2'-`b1'')
					if `oldpoints' > `nobs' {
						local ipoints = `"intpoints(`nobs')"'
					}
					local first
				}
				local modelopts "`modelopts' `first'"
				if "`first'" == "" {
					local local modelopts "`modelopts' `oldopts'"
					continue, break
				}
			}
		}
		//First trial
		#delim ;
		capture noisily  `fitcommand' (`1' `regexpression' if `touse', noconstant )|| 
		  (`sid': `varx' , `cov') `nested' ,
		  binomial(`2') `ipoints' `modelopts' l(`level') ;
		#delimit cr 
		
		local success = _rc
		
		if `success' != 0 {
			//First fit laplace to get better starting values
			noi di _n"*********************************** ************* ***************************************" 
			noi di as txt _n "Just a moment - Obtaining better initial values "
			noi di   "*********************************** ************* ***************************************" 
			local lapsuccess 1
			
			if "`fitcommand'" == "meqrlogit" {
				local laplace "laplace"
			}
			else {
				local laplace "intmethod(laplace)"
			}
			
			if (strpos(`"`modelopts'"', "from") == 0) {
				#delim ;
				capture noisily  `fitcommand' (`1' `regexpression' if `touse', noconstant )|| 
					(`sid': `varx' , `cov') `nested' ,
					binomial(`2') `laplace' l(`level') ;
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
			capture noisily  `fitcommand' (`1' `regexpression' if `touse', noconstant )|| 
			  (`sid': `varx', `cov') `nested' ,
			  binomial(`2') `ipoints' `modelopts' `inits' l(`level') ;
			#delimit cr 
			
			local success = _rc
		}
		
		//Try to refineopts 3 times
		if strpos(`"`modelopts'"', "refineopts") == 0 & ("`fitcommand'" == "meqrlogit") {
			local converged = e(converged)
			local try = 1
			while `try' < 3 & `converged' == 0 {
			
				#delim ;					
				capture noisily  `fitcommand' (`1' `regexpression' if `touse', noconstant )|| 
					(`sid': `varx' , `cov') `nested' ,
					binomial(`2') `ipoints' `modelopts' l(`level') refineopts(iterate(`=10 * `try''));
				#delimit cr 
				
				local success = _rc
				local converged = e(converged)
				local try = `try' + 1
			}
		}
		*Try matlog if still difficult
		if (strpos(`"`modelopts'"', "matlog") == 0) & ("`fitcommand'" == "meqrlogit") & ((`converged' == 0) | (`success' != 0)) {
			if strpos(`"`modelopts'"', "refineopts") == 0 {
				local refineopts = "refineopts(iterate(50))"
			}
			#delim ;
			capture noisily  `fitcommand' (`1' `regexpression' if `touse', noconstant )|| 
				(`sid': `varx' , `cov') `nested' ,
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

syntax varlist, rid(name) assignment(name) event(name) total(name) idpair(name) [ mcbnetwork pcbnetwork abnetwork general comparative ]

	qui {
	
		tokenize `varlist'
		
		if "`mcbnetwork'" != "" {		
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
			/*pcbnetwork: The three variables should contain numbers*/
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

	syntax varlist, sid(varlist) idpair(varname) [sortby(varlist) jvar(varname) mcbnetwork pcbnetwork abnetwork general comparative]

		qui{
			tokenize `varlist'

			tempvar modey diffy
			*if "`mcbnetwork'" == "" {
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
	syntax varlist, [poprrout(name) rrout(name) popabsout(name) absout(name) absoutp(name) sortby(varlist) by(varname) hetout(name) model(string) prediction
		groupvar(varname) se(varname) summaryonly nooverall nosubgroup outplot(string) grptotal(name) download(string asis) 
		indvars(varlist) depvars(varlist) dp(integer 2) stratify pcont(integer 0) level(integer 95)
		comparative abnetwork general pcbnetwork mcbnetwork
		]
	;
	#delimit cr
	tempvar  expand serror
	tokenize `varlist'
	 
	local id = "`1'"
	local use = "`2'"
	local label = "`3'"
	local es = "`4'"
	local lci = "`5'"
	local uci = "`6'"
	local modeles = "`7'"
	local modelplo = "`8'"
	local modelpup = "`9'"
	
	if "`se'" !="" {
		gen `serror' = `se'
	}
	else{
		gen `serror' = 0
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
			*replace `label' = "Summary" if `use' == 2 
			replace `label' = "Group Mean" if `use' == 2 
			replace _WT = . if `use' == 2 
			
			qui label list `groupvar'
			local nlevels = r(max)
			forvalues l = 1/`nlevels' {
				if "`outplot'" == "abs" {
					if "`model'" == "hexact" {
					local S_1 = `absout'[`=`pcont' +`l'', 1]
					local S_3 = `absout'[`=`pcont' +`l'', 5]
					local S_4 = `absout'[`=`pcont' +`l'', 6]
					}
					else { 
					
					local S_1 = `popabsout'[`l', 1]
					local S_3 = `popabsout'[`l', 4]
					local S_4 = `popabsout'[`l', 5]
					}
					if "`prediction'" != "" {
						local S_5 = `absoutp'[`l', 1]
						local S_6 = `absoutp'[`l', 2]
					}
					if "`model'" == "random" & "`indvars'" == "" & "`stratify'" !="" {
						local isq = `hetout'[`l', 5]
						local phet = `hetout'[`l', 3]
						*replace `label' = "Summary (Isq = " + string(`isq', "%10.`=`dp''f") + "%, p = " + string(`phet', "%10.`=`dp''f") + ")" if `use' == 2 & `groupvar' == `l' & `grptotal' > 2
						replace `label' = "Group Mean (Isq = " + string(`isq', "%10.`=`dp''f") + "%, p = " + string(`phet', "%10.`=`dp''f") + ")" if `use' == 2 & `groupvar' == `l' & `grptotal' > 2						
					}	 
				}
				else {
					local S_1 = `poprrout'[`l', 1]
					local S_3 = `poprrout'[`l', 4]
					local S_4 = `poprrout'[`l', 5]
				}
				local lab:label `groupvar' `l'
				replace `label' = "`lab'" if `use' == -2 & `groupvar' == `l'
				replace `label' = "`lab'" if `use' == 2 & `groupvar' == `l'	& "`outplot'" == "rr" & "`abnetwork'" != ""		
				replace `es'  = `S_1' if `use' == 2 & `groupvar' == `l'	
				replace `lci' = `S_3' if `use' == 2 & `groupvar' == `l'	
				replace `uci' = `S_4' if `use' == 2 & `groupvar' == `l'	
				//Predictions
				if "`outplot'" == "abs" & "`prediction'" != "" {
					replace `lci' = `S_5' if `use' == 4 & `groupvar' == `l'	
					replace `uci' = `S_6' if `use' == 4 & `groupvar' == `l'	
				}
				//Weights
				sum _WT if `use' == 1 & `groupvar' == `l'
				local groupwt = r(sum)
				replace _WT = `groupwt' if `use' == 2 & `groupvar' == `l'	
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
				
				if "`model'" == "hexact" {
					local nrows = rowsof(`absout')
					local S_1 = `absout'[`nrows', 1]
					local S_3 = `absout'[`nrows', 5]
					local S_4 = `absout'[`nrows', 6]
				}
				else {
					local nrows = rowsof(`popabsout')
					local S_1 = `popabsout'[`nrows', 1]
					local S_3 = `popabsout'[`nrows', 4]
					local S_4 = `popabsout'[`nrows', 5]
				}
				//predictions
				if "`prediction'" != "" {
					local nrows = rowsof(`absoutp')
					local S_5 = `absoutp'[`nrows', 1]
					local S_6 = `absoutp'[`nrows', 2]
				}			
			}
			else {
				local nrows = rowsof(`poprrout')
				local S_1 = `poprrout'[`nrows', 1]
				local S_3 = `poprrout'[`nrows', 4]
				local S_4 = `poprrout'[`nrows', 5]
			}
			if "`model'" == "random" & "`indvars'" == ""  & "`outplot'" == "abs" {
				local nrows = rowsof(`hetout')
				local isq = `hetout'[`nrows', 5]
				local phet = `hetout'[`nrows', 3]
				*replace `label' = "Overall (Isq = " + string(`isq', "%10.`=`dp''f") + "%, p = " + string(`phet', "%10.`=`dp''f") + ")" if `use' == 3
				replace `label' = "Population Mean (Isq = " + string(`isq', "%10.`=`dp''f") + "%, p = " + string(`phet', "%10.`=`dp''f") + ")" if `use' == 3
			}
			else {
				*replace `label' = "Overall" if `use' == 3
				replace `label' = "Population Mean" if `use' == 3
			}		
			
			replace `es' = `S_1' if `use' == 3	
			replace `lci' = `S_3' if `use' == 3
			replace `uci' = `S_4' if `use' == 3
			replace _WT = . if (`use' == 3) & ("`stratify'" != "")
			replace _WT = 100 if (`use' == 3) & ("`stratify'" == "")
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
		
		replace `label' = "Predictive t Interval" if `use' == 4 & "`model'" == "random"
		replace `label' = "t Interval" if `use' == 4 & "`model'" != "random"
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
			keep `depvars' `indvars' `groupvar' _ES _SE _LCI _UCI _ESAMPLE _WT _LABEL _ID 
		}
		di _n "Data saved"
		di "CAUTION: For n=N or n=0, _SE=0"
		di "and approximated with _SE = (_UCI – _LCI)/(2*Z(`level'))"
		noi save "`download'", replace
		
		restore
	}
	qui {
		if "`abnetwork'" == "" | ("`abnetwork'" != "" & "`outplot'" != "rr") {
			drop if (`use' == 2 | `use' == 3) & (`grptotal' == 1)  //drop summary if 1 study
		}
		drop if (`use' == 1 & "`summaryonly'" != "" & `grptotal' > 1) | (`use' == 2 & "`subgroup'" != "") | (`use' == 3 & "`overall'" != "") | (`use' == 4 & "`prediction'" == "") //Drop unnecessary rows
		
		if "`abnetwork'" != "" & "`outplot'" == "rr" {
			drop if `use' == 1 | `use' == -2
			replace `use' = 1 if `use' == 2
		}
		//Remove weight if 1 study - Show the weight; otherwise gives the impression the study did not contribute
		*qui replace _WT= . if (`use' == 1) & (`grptotal' == 1) 
		
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
	syntax varlist, [nosubgroup nooverall level(integer 95) sumstat(string asis) model(string)
	dp(integer 2) power(integer 0) nowt smooth icimethod(string) ocimethod(string)]
	;
	#delimit cr
	
	tempvar id use label es lci uci grptotal modeles modellci modeluci
	tokenize `varlist'
	qui {
		gen `id' = `1'
		gen `use' = `2'
		gen `label' = `3'
		gen `es' = `4'
		gen `lci' = `5'
		gen `uci' = `6'
		gen `grptotal' = `7'
		if "`smooth'" !="" {
			gen `modeles' = `8'
			gen `modellci' = `9'
			gen `modeluci' = `10'
		}
	}
	
	preserve
	tempvar tlabellen 
	//study label
	local studylb: variable label `label'
	if "`studylb'" == "" {
		local studylb "Study"
	}		
	local studylen = strlen("`studylb'")
 
	qui gen `tlabellen' = strlen(`label')
	qui summ `tlabellen' if `use' == 1 
		
	local nlen = `=max(r(max), 12) + 2' 
	local nlens = strlen("`sumstat'")
	
	local level: displ %2.0f `level'
	local start: displ %2.0f `=`nlen'/2 - `studylen'/2 + 2'
	
	di as res _n "***********************************************************************"
	if "`smooth'" != "" {
		di as res "{pmore2} Study specific `sumstat' :  Observed (Smoothed) {p_end}"
	}
	else {
		di as res "{pmore2} Study specific `sumstat'  {p_end}"
	}
	di as res    "***********************************************************************" 
	
	local colstat = int(`=`nlen' + `nlens'*0.5')
	
	
	if "`wt'" =="" {
		local dispwt "% Weight"
	}
	if "`smooth'" !=""  {
		/*
		di  _n  as txt _col(`start') "`studylb'" _col(`nlen') "|  "   _skip(5) "Estimate" ///
		  _col(`=`nlen' + `nlens' + 20') "Lower - `icimethod' (Wald) CI- Upper" _skip(10) "`dispwt'"
		  */
		  
		di  _n  as txt _col(`start') "`studylb'" _col(`nlen') "|  "   _skip(5) "Estimate" ///
		  _col(`=`nlen' + `nlens' + 20') "Lower - `icimethod' (Wald) CI- Upper" _col(`=`nlen' + `nlens' + 60') "`dispwt'"  
		
		local colwt = int(`=`nlen' + `nlens' + 55')
	}
	else{
		di  _n  as txt _col(`start') "`studylb'" _col(`nlen') "|  "   _skip(5) "Estimate" ///
		  _col(`=`nlen' + `nlens' + 10') "`=(100-`level')/2'% - `icimethod' CI- `=100 - (100-`level')/2'%" _col(`=`nlen' + `nlens' + 40') "`dispwt'"
	
		local colwt = int(`=`nlen' + `nlens' + 35')
	}
	di  _dup(`=`nlen'-1') "-" "+" _dup(57) "-" 
	
	qui count
	local N = r(N)
	
	//Find the length of the estimates
	qui {
		tempvar hold holdstr slimest
		gen `hold' = `uci'*(10^`power')
		tostring `hold', gen(`holdstr') format(%10.`dp'f) force
		gen `slimest' = strlen(strltrim(`holdstr'))
		sum `slimest'
		local est_i_len = r(max)
	}
		
	forvalues i = 1(1)`N' {
		//Weight
		if "`wt'" =="" {
			local ww = _WT[`i']
		}
		//Group labels
		if ((`use'[`i']== -2)){ 
			di _col(2) as txt `label'[`i'] _col(`nlen') "|  "
		}
		
		//Studies 
		if ((`use'[`i'] ==1)) {
					
			//Smooth estimates
			if "`smooth'" !="" {
				local open " ("
				local close ")"
				local aesclose "%1s"
				
				local aes "%`=`est_i_len''.`=`dp''f"
				local mes "`modeles'[`i']*(10^`power')"
				local mlci "`modellci'[`i']*(10^`power')"
				local muci "`modeluci'[`i']*(10^`power')"
			}
			
			di _col(2) as txt `label'[`i'] _col(`nlen') "|  "  ///
			_col(`colstat')  as res  %10.`=`dp''f  `es'[`i']*(10^`power')  "`open'" `aes' `mes' "`close'"  /// 
			_col(`=`nlen' + `nlens' + 5') %10.`=`dp''f `lci'[`i']*(10^`power') "`open'" `aes' `mlci'  `aesclose' "`close'"  ///
			_skip(5) %10.`=`dp''f `uci'[`i']*(10^`power') "`open'" `aes' `muci' "`close'"   _col(`colwt') %10.`=`dp''f `ww'
		}
		//Summaries
		if ( (`use'[`i']== 3) | ((`use'[`i']== 2) & (`grptotal'[`i'] > 1))){
			if ((`use'[`i']== 2) & (`grptotal'[`i'] > 1)) {
				di _col(2) as txt _col(`nlen') "|  " 
			}
			if (`use'[`i']== 2)	{
				local sumtext = "Group Mean"
			}
			else {
				local sumtext = "Population Mean"			
			}
			if "`smooth'" != "" {
				di _col(2) as txt "`sumtext'" _col(`nlen') "|  "  ///
					_col(`=`colstat'+8') as res  %`=`est_i_len''.`=`dp''f  `es'[`i']*(10^`power') /// 
					_col(`=`nlen' + `nlens' + 22') %`=`est_i_len''.`=`dp''f `lci'[`i']*(10^`power') ///
					_skip(14) %`=`est_i_len''.`=`dp''f `uci'[`i']*(10^`power') _col(`colwt')  %10.`=`dp''f `ww'
			}
			else {
				di _col(2) as txt "`sumtext'" _col(`nlen') "|  "  ///
				_col(`colstat') as res  %10.`=`dp''f  `es'[`i']*(10^`power') /// 
				_col(`=`nlen' + `nlens' + 5') %10.`=`dp''f `lci'[`i']*(10^`power') ///
				_skip(5) %10.`=`dp''f `uci'[`i']*(10^`power') _col(`colwt')  %10.`=`dp''f `ww'
			}
		}
		//Blanks
		if (`use'[`i'] == 0 ){
			di as txt _dup(`=`nlen'-1') "-" "+" _dup(57) "-"		
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
		
		syntax varlist, [interaction alphasort mcbnetwork pcbnetwork abnetwork general comparative ipair(varname) baselevel(string) studyid(varname) ]
		
		tempvar holder
		tokenize `varlist'

		if "`mcbnetwork'`pcbnetwork'" == "" {
			macro shift 2
			local regressors "`*'"
		}
		else {
			if "`mcbnetwork'" != "" {
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
		
		if ("`general'`comparative'" != "")  {
			local regexpression = "mu"
		}
		else if "`mcbnetwork'`pcbnetwork'" != "" {
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
			*abnetwork 
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
			if "`abnetwork'" != "" & `i'==1 {
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
			
			if "``i''" == "`studyid'" {
				continue
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
		syntax, estimates(string) studyid(varname) [expit DP(integer 2) model(string) varx(varname) typevarx(string) regexpression(string) ///
			comparator(varname) cimethod(string) mcbnetwork pcbnetwork abnetwork general comparative stratify interaction ///
			catreg(varlist) contreg(varlist) power(integer 0) level(integer 95) by(varname) ]
		
		tempname coefmat outmatrix outmatrixp matrixout bycatregmatrixout catregmatrixout contregmatrixout row outmatrixr overall Vmatrix byVmatrix
		
		tokenize `regexpression'
		if "`mcbnetwork'`pcbnetwork'" != "" {
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
		if "`abnetwork'" != "" {
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
		
		//Expression for logodds prediction
		local expression "predict(xb)"
						
		
		if "`idpairconcat'" != ""{
			local marginlist = `"`varx'"'
		}
		else {
			local marginlist
		}
		while "`catreg'" != "" {
			tokenize `catreg'
			if ("`1'" != "`by'" & "`by'" != "") | "`by'" =="" {
				if ("`1'" != "`studyid'") {
				
					if "`idpairconcat'" != ""{
						local marginlist = `"`marginlist' `1'"'
					}
					local marginlist = `"`marginlist' `1'`idpairconcat'"'
				}
			}
			macro shift 
			local catreg `*'
		}
		qui estimates restore `estimates'
		local df = e(N) -  e(k) 
		mat `coefmat' = e(b)
		if "`model'" == "random" {
			local npar = colsof(`coefmat')
			if "`abnetwork'" == "" {
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
			qui margin , `expression' over(`by') level(`level')
			
			mat `bycatregmatrixout' = r(table)'
			mat `byVmatrix' = r(V)
			mat `bycatregmatrixout' = `bycatregmatrixout'[1..., 1..6]
			
			local byrnames :rownames `bycatregmatrixout'
			local byncatreg = rowsof(`bycatregmatrixout')
		}
		
		if "`abnetwork'`mcbnetwork'`pcbnetwork'" == ""  {
			local grand "grand"
			local Overall "Overall"			
		}
		if "`comparative'" != "" & "`stratify'" != "" {
			local grand
			local Overall
		}
		local ncatreg 0
		
		qui margin `marginlist', `expression' `grand' level(`level')
					
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
				qui margin, `expression' at(`v'=`vmean') level(`level')
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
		
		if (`ncatreg' > 0 & `byncatreg' > 0) {
			mat `matrixout' =  `bycatregmatrixout' \ `catregmatrixout'
		}
		if (`ncatreg' > 0 & `byncatreg' == 0) {
			mat `matrixout' =  `catregmatrixout' 
		}
		
		if (`ncatreg' == 0 & `byncatreg' > 0) {
			mat `matrixout' =  `bycatregmatrixout' 
		}
		
		if (`ncontreg' > 0) {
			mat `matrixout' =  `contregmatrixout' \ `matrixout'
		}
		
		//t distribution
		if "`cimethod'" == "t" {
			forvalues r = 1(1)`=`byncatreg' + `ncatreg' + `ncontreg''  {
					local tstat = `matrixout'[`r', 3]
					mat `matrixout'[`r', 4] = ttail(`df', abs(`tstat'))*2
					mat `matrixout'[`r', 5] = `matrixout'[`r', 1] - invttail((`df'), 0.5-`level'/200) * `matrixout'[`r', 2]
					mat `matrixout'[`r', 6] = `matrixout'[`r', 1] + invttail((`df'), 0.5-`level'/200) * `matrixout'[`r', 2]
			}
		}
		
		if "`expit'" != "" {
			forvalues r = 1(1)`=`byncatreg' + `ncatreg' + `ncontreg''  {
				mat `matrixout'[`r', 1] = invlogit(`matrixout'[`r', 1])
				mat `matrixout'[`r', 5] = invlogit(`matrixout'[`r', 5])
				mat `matrixout'[`r', 6] = invlogit(`matrixout'[`r', 6])
			}
		}

		local catrownames = ""
		if "`mcbnetwork'`pcbnetwork'" != "" {
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
					if strpos("`rname`r''", "b") != 0 {
						local leftlabel = ustrregexra("`leftlabel'", "bn", "")	
					}
					local lab:label `leftv' `leftlabel'
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
					if strpos("`leftlabel'", "b") != 0 {
						local leftlabel = ustrregexra("`leftlabel'", "bn", "")
					}
					local llab:label `leftv' `leftlabel'
				} 
				else {
					local llab
				}
				
				if strpos("`rightlabel'", "c") == 0 {
					if strpos("`rightlabel'", "o") != 0 {
						local indexo = strlen("`rightlabel'") - 1
						local rightlabel = substr("`rightlabel'", 1, `indexo')
					}
					if strpos("`rightlabel'", "b") != 0 {
						local rightlabel = ustrregexra("`rightlabel'", "bn", "")
					}
					local rlab:label `rightv' `rightlabel'
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
			////check no underscore in the group names, replace with -
			if strpos("`lab'", "_") != 0 {
				local lab = ustrregexra("`lab'", "_", "-")
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
			if "`cimethod'" == "t" { 
				mat colnames `matrixout' = Mean SE t P>|t| Lower Upper
			}
			else {
				mat colnames `matrixout' = Mean SE z P>|z| Lower Upper
			}
		}
		else {
			if "`cimethod'"== "t" {
				mat colnames `matrixout' = Mean SE(logit) t(logit) P>|t| Lower Upper
			}
			else{
				mat colnames `matrixout' = Mean SE(logit) z(logit) P>|z| Lower Upper
			}
			
		}
		if "`expit'" != "" {			
			mat colnames `outmatrixp' = Lower Upper
			mat rownames `outmatrixp' = `catrownames' `Overall'
		}
		return matrix outmatrixp = `outmatrixp'	
		return matrix outmatrix = `matrixout'
	end	

/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS:  postsim +++++++++++++++++++++++++
							Simulate & summarize posterior distribution
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/	
cap program drop postsim
program define postsim, rclass
version 14.1
	#delimit ;
	syntax [if] [in], todo(string) orderid(varname) studyid(varname) estimates(name) [ logodds(name) rrout(name)
	modeles(varname) modellci(varname) modeluci(varname) outplot(string) baselevel(integer 1) cov(string)
	model(string) comparative  by(varname) level(real 95) interaction abnetwork mcbnetwork  varx(varname)]
	;
	#delimit cr 
	
	marksample touse, strok
	
	tempname rawcoef varrawcoef X beta sims popabsout popabsouti poprrout poprrouti
	
	tempvar feff sfeff reff sreff reff1 sreff1 reff2 sreff2 eta insample newobs idpair gid rid hold holdleft holdright ///
			simmu sumphat meanphat subset subsetid subsetid1 sumphat1 ///
			meanphat1 gid1 modelp modelrr modelse sumrrhat meanrrhat
	
	//Restore 
	qui {
		estimates restore `estimates'
		gen `insample' = e(sample)

		//Coefficients estimates and varcov
		mat `rawcoef' = e(b)
		local ncoef = colsof(`rawcoef')
		local rho = 0
		if "`model'" == "random" {
			if "`abnetwork'`cov'" == "" {
				local nfeff = `=`ncoef' - 1'
			}
			else if ("`abnetwork'" != "") | ("`cov'" =="independent") {
				local nfeff = `=`ncoef' - 2'
			}
			else if "`cov'" =="unstructured" {
				local nfeff = `=`ncoef' - 3'
				local rho = tanh(`rawcoef'[1, `ncoef'])
			}
		}
		else {
			local nfeff = `ncoef'
		}
		mat `rawcoef' = `rawcoef'[1, 1..`nfeff']
		mat `varrawcoef' = e(V)
		mat `varrawcoef' = `varrawcoef'[1..`nfeff', 1..`nfeff']

		//Predict		
		//Fill data if less than 7
		count
		local nobs = r(N)
		if ((`nobs' < 7) & ("`model'" == "random")) {
			local multipler = int(ceil(7/`nobs'))
			qui expand `multipler', gen(`newobs')
		}
		
		predict `feff', xb
		predict `sfeff', stdp
		
		if "`model'" == "random" {
			if "`abnetwork'`cov'" == "" {
				predict `reff', reffects reses(`sreff')
				gen `eta' = `feff' + `reff'
				gen `modelse' = sqrt(`sreff'^2 + `sfeff'^2) if `insample'==1
			}
			else if "`abnetwork'" !="" | "`cov'" !="" {
				predict `reff1' `reff2', reffects reses(`sreff1' `sreff2')
				
				replace `sreff1' = sqrt((1 - (`rho')^2)*(`sreff1'^2)) //Corrected variance
				replace `sreff2' = sqrt((1 - (`rho')^2)*(`sreff2'^2)) //Corrected variance
				
				gen `reff' = `reff1' + `reff2'
				gen `sreff' = sqrt(`sreff1'^2 + `sreff2'^2)				
				gen `eta' = `feff' + `reff1' + `reff2'
				gen `modelse' = sqrt(`sreff1'^2 + `sreff2'^2 + `sfeff'^2) if `insample'==1
			}
		}
		else {
			gen `eta' = `feff' 
			gen `modelse' = `sfeff' if `insample'==1
		}
		
		
		//Revert to original data if filler data was generated
		if (("`model'" == "random") & (`nobs' < 7))  {
			keep if !`newobs'
		}
		
		//Smooth estimates
		gen `modelp' = invlogit(`eta') if `insample'==1
		
		//identifiers
		sort `insample' `orderid'
		*egen `rid' = seq() if `insample'==1  //rowid
		
		if "`comparative'`mcbnetwork'`abnetwork'" != ""  {
			egen `gid' = group(`studyid' `by') if `insample'==1  
			sort `gid' `orderid' `varx'
			by `gid': egen `idpair' = seq()
			egen `rid' = seq() if `insample'==1  //rowid
			
			if "`abnetwork'" == "" {
				gen `modelrr' = `modelp'[_n] / `modelp'[_n-1] if (`gid'[_n]==`gid'[_n-1]) & (`idpair' == 2)
			}
		}
		else {
			egen `rid' = seq() if `insample'==1  //rowid
			gen `gid' = `rid'
		}
		
		//Generate designmatrix
		local colnames :colnames `rawcoef'
		local nvars: word count `colnames'
		forvalues i=1(1)`nvars' {
			tempvar v`i' beta`i'
			
			local var`i' : word `i' of `colnames'	
			
			//Interaction
			tokenize `var`i'', parse("#")
			local left = "`1'"
			local right = "`3'"
			
			tokenize `left', parse(.)
			local leftleft = "`1'"
			local leftright = "`3'"
			
			//Constant or continous
			if "`right'" == ""  & "`leftright'" == "" {
				gen `v`i'' = `leftleft'
			}
			
			//Main categorical effects
			if "`right'" == "" & "`leftright'" != "" {
				if strpos("`leftleft'", "bn") != 0 {
					local leftleft = ustrregexra("`leftleft'", "bn", "")
				}
				if strpos("`leftleft'", "b") != 0 {
					local leftleft = ustrregexra("`leftleft'", "b", "")
				}		
				
				gen `v`i'' = 0 
				replace `v`i'' = 1 if `leftright' == `leftleft'
			}
			
			//Interactions
			if "`right'" != "" {
				tokenize `right', parse(.)
				local rightleft = "`1'"
				local rightright = "`3'"
			
				//continous left
				if strpos("`leftleft'", "c") == 1 {
					local factorleft 0
				}
				else {
					local factorleft 1
				}
				
				//continous right
				if strpos("`rightleft'", "c") == 1 {
					local factorright 0
				}
				else {
					local factorright 1
				}
				
				if `factorleft' == 1  {		
					//Categorical
					if strpos("`leftleft'", "bn") != 0 {
						local leftleft = ustrregexra("`leftleft'", "bn", "")
					}
					if strpos("`leftleft'", "b") != 0 {
						local leftleft = ustrregexra("`leftleft'", "b", "")
					}
					if strpos("`leftleft'", "o") != 0 {
						local leftleft = ustrregexra("`leftleft'", "o", "")
					}
					
					if `factorright' == 1 {
						if strpos("`rightleft'", "bn") != 0 {
							local rightleft = ustrregexra("`rightleft'", "bn", "")
						}
						if strpos("`rightleft'", "b") != 0 {
							local rightleft = ustrregexra("`rightleft'", "b", "")
						}
						if strpos("`rightleft'", "o") != 0 {
							local rightleft = ustrregexra("`rightleft'", "o", "")
						}
						
						gen `v`i'' = 0
						replace `v`i'' = 1 if (`leftright' == `leftleft') & (`rightright' == `rightleft')
				
					}
					else {
						gen `v`i'' = 0
						replace `v`i'' = 1*`rightright' if (`leftright' == `leftleft') 
					}
				}
				else {
					//Continous
					if `factorright' == 1 {
						if strpos("`rightleft'", "bn") != 0 {
							local rightleft = ustrregexra("`rightleft'", "bn", "")
						}
						if strpos("`rightleft'", "b") != 0 {
							local rightleft = ustrregexra("`rightleft'", "b", "")
						}
						gen `v`i'' = 0
						replace `v`i'' = 1*`leftright' if (`rightright' == `rightleft')
						
					}
					else {
						gen `v`i'' = .
						replace `v`i'' = `leftright'*`rightright'
					}
				}	
			}
			local vnamelist "`vnamelist' `v`i''"
			local bnamelist "`bnamelist' `beta`i''"
		}
		
		set matsize 1000

		//make matrices from the dataset
		//roweq(`idpair')
		mkmat `vnamelist' if `insample'==1, matrix(`X')  rownames(`rid')
		
		tempvar present
		gen `present' = 1	
		//Simulate the parameters
		set obs 1000

		drawnorm `bnamelist', n(1000) cov(`varrawcoef') means(`rawcoef') seed(1)

		mkmat `bnamelist', matrix(`beta')

		mat `sims' = `beta'*`X''

		//Construct the names
		local ncols = colsof(`sims') //length of the vector
		local cnames :colnames `sims'
		
		local matcolnames
		
		forvalues c=1(1)`ncols' {
			local matrid : word `c' of `cnames'

			tempvar festudy`matrid'
			local matcolnames = "`matcolnames' `festudy`matrid''"
		}

		//pass the names
		matname `sims' `matcolnames', col(.) explicit

		//Bring the matrix to the dataset
		svmat `sims', names(col)

		//# of obs
		count if `insample' == 1
		local nobs = r(N)
		
		//Generate the p's and rr's
		forvalues j=1(1)`nobs' { 
			tempvar phat`j' 
				
			if "`comparative'`mcbnetwork'`abnetwork'" == "" {
				tempvar restudy`j' phat`j' 
			
				if "`model'" == "random" {
					//re  
					sum `reff' if `rid'==`j' 
					local reff`j' = r(mean)
					
					//se
					sum `sreff' if `rid'==`j' 
					local sreff`j' = r(mean)
				
					qui gen `restudy`j'' = rnormal(`reff`j'', `sreff`j'')
					gen `phat`j'' = invlogit(`restudy`j'' + `festudy`j'')
				}
				else {
					gen `phat`j'' = invlogit(`festudy`j'')
				}
			}
			if "`comparative'" != "" | "`mcbnetwork'" != "" | "`abnetwork'" != "" {
				sum `gid' if `rid' == `j'
				local index = r(min)
				
				sum `idpair' if `rid' == `j'
				local pair = r(min)
				
				//Generate the variables
				tempvar phat_`pair'`index'
				
				if "`model'" == "random" {				
					if `pair' == 1 {
						//re - same per study
						sum `reff' if `gid'==`index' 
						local reff`j' = r(mean)
					
						//se
						sum `sreff' if `gid'==`index' 
						local sreff`j' = r(mean)
					
						tempvar restudy`index'
						
						gen `restudy`index'' = rnormal(`reff`j'', `sreff`j'')
					}
					gen `phat`j'' = invlogit(`restudy`index'' + `festudy`j'')
				}
				else {
					gen `phat`j'' = invlogit(`festudy`j'')
				}
				if "`abnetwork'" == "" {
					//Create the pairs
					gen `phat_`pair'`index'' = `phat`j''
					
					if `pair' == 2 {
						tempvar rrhat`index'
						gen `rrhat`index'' = `phat_2`index'' / `phat_1`index''
					}
				}
			}	
		}
				
		if "`todo'" == "abs" {
			//Summarize p
			local nrows = rowsof(`logodds') //length of the vector
			local rnames :rownames `logodds'
			local eqnames :roweq `logodds'
			local newnrows = 0
			local mindex = 0
				
			foreach vari of local eqnames {		
				local ++mindex
				local group : word `mindex' of `rnames'
				
				
				//Skip if continous variable
				if (strpos("`vari'", "_") == 1) & ("`group'" != "Overall"){
					continue
				}
				
				cap drop `subset' `subsetid'
				
				if "`group'" != "Overall" {
					if strpos("`vari'", "*") == 0 {
					*if "`interaction'" == "" {
						cap drop `hold'
						decode `vari', gen(`hold')
						cap drop `subset'
						local latentgroup = ustrregexra("`group'", "_", " ")
						gen `subset' = 1 if `hold' == "`latentgroup'" & `insample' == 1 
					}
					else {
						tokenize `vari', parse("*")
						local leftvar = "`1'"
						local rightvar = "`3'"
						
						tokenize `group', parse("|")
						local leftgroup = "`1'"
						local rightgroup = "`3'"
						
						cap drop `holdleft' `holdright'
						decode `leftvar', gen(`holdleft')
						decode `rightvar', gen(`holdright')
						cap drop `subset'
						local latentleftgroup = ustrregexra("`leftgroup'", "_", " ")
						local latentrightgroup = ustrregexra("`rightgroup'", "_", " ")
						gen `subset' = 1 if (`holdleft' == "`latentleftgroup'") & (`holdright' == "`latentrightgroup'") & (`insample' == 1)
					}					
					*egen `subsetid' = group(`rid') if `subset' == 1
					egen `subsetid' = seq() if `subset' == 1
				}
				else {
					//All
					gen `subset' = 1 if `insample' == 1 
					gen `subsetid' = `rid'
				}
				
				count if `subset' == 1 
				local nsubset = r(N)
				
				//Compute mean of simulated values
				cap drop `sumphat' `meanphat'
				gen `sumphat' = 0	
				forvalues j=1(1)`nsubset' { 
					sum `rid' if `subsetid' == `j'
					local index = r(min)
					replace `sumphat' = `sumphat' + `phat`index''
				}
				
				//Obtain mean of modelled estimates
				sum `modelp' if `subset' == 1
				local meanmodelp = r(mean)
						
				gen `meanphat' = `sumphat'/`nsubset'
				//Standard error
				sum `meanphat'	
				local postse = r(sd)
				
				//Obtain the quantiles
				centile `meanphat', centile(50 `=(100-`level')/2' `=100 - (100-`level')/2')
				local median = r(c_1) //Median
				local lowerp = r(c_2) //Lower centile
				local upperp = r(c_3) //Upper centile
				
				mat `popabsouti' = (`meanmodelp', `postse', `median', `lowerp', `upperp')
				mat rownames `popabsouti' = `vari':`group'
				
				//Stack the matrices
				local ++newnrows
				if `newnrows' == 1 {
					mat `popabsout' = `popabsouti'	
				}
				else {
					mat `popabsout' = `popabsout'	\  `popabsouti'
				}
			}
		}
		
		if "`todo'" == "rr" {
			//Summarize RR
			local nrows = rowsof(`rrout') //length of the vector
			local rnames :rownames `rrout'
			local eqnames :roweq  `rrout'
			local newnrows 0
			
			if "`comparative'`mcbnetwork'" == "" {
				local catvars : list uniq eqnames	
				foreach vari of local catvars {
					
					cap drop `hold'	
					decode `vari', gen(`hold')
					label list `vari'
					local ngroups = r(max)
					local baselab:label `vari' `baselevel'
					
					//count in basegroup
					tempvar meanphat`baselevel' meanrrhat`baselevel' gid`baselevel' sumphat`baselevel' subsetid`baselevel'
					tempname poprrouti`baselevel'
					
					count if `vari' == `baselevel' & `insample' == 1
					local ngroup`baselevel' = r(N)
					
					egen `subsetid`baselevel'' = group(`rid') if `vari' == `baselevel' & `insample' == 1
					
					cap drop `sumphat`baselevel'' `meanphat`baselevel''
					//basegroup
					gen `sumphat`baselevel'' = 0
					
					forvalues j=1(1)`ngroup`baselevel'' {
						sum `rid' if `subsetid`baselevel'' == `j'
						local index = r(min)
						
						qui replace `sumphat`baselevel'' = `sumphat`baselevel'' + `phat`index''
					}
					gen `meanphat`baselevel'' = `sumphat`baselevel''/`ngroup`baselevel''
					
					sum `modelp' if `vari' == `baselevel' & `insample' == 1
					local meanmodelp`baselevel' = r(mean)
					
					mat `poprrouti`baselevel'' = (1, 0, 1, 1, 1)
					local baselab = ustrregexra("`baselab'", " ", "_")
					mat rownames `poprrouti`baselevel'' = `vari':`baselab'
					
					//Other groups
					forvalues g=1(1)`ngroups' {
						if `g' != `baselevel' {
							tempvar meanphat`g' meanrrhat`g' gid`g' sumphat`g' subsetid`g'
							tempname poprrouti`g'
							
							local glab:label `vari' `g'
							count if `vari' == `g' & `insample' == 1
							local ngroup`g' = r(N)	
							egen `subsetid`g'' = group(`rid') if `vari' == `g' & `insample' == 1
							
							gen `sumphat`g'' = 0
							
							//Group of interest
							forvalues j=1(1)`ngroup`g'' {
								sum `rid' if `subsetid`g'' == `j'
								local index = r(min)			
								qui replace `sumphat`g'' = `sumphat`g'' + `phat`index''
							}
							
							gen `meanphat`g'' = `sumphat`g''/`ngroup`g''
							
							//Generate RR 
							gen `meanrrhat`g'' = `meanphat`g'' / `meanphat`baselevel''

							//Obtain mean of modelled estimates
							sum `modelp' if `vari' == `g' & `insample' == 1
							local meanmodelp`g' = r(mean)
							local meanmodelrr`g' = `meanmodelp`g'' / `meanmodelp`baselevel''
							
							//Standard error
							sum `meanrrhat`g''
							local postse = r(sd)
							
							//Obtain the quantiles
							centile `meanrrhat`g'', centile(50 `=(100-`level')/2' `=100 - (100-`level')/2')
							local median = r(c_1) //Median
							local lowerp = r(c_2) //Lower centile
							local upperp = r(c_3) //Upper centile
													
							mat `poprrouti`g'' = (`meanmodelrr`g'', `postse', `median', `lowerp', `upperp')
							local glab = ustrregexra("`glab'", " ", "_")
							mat rownames `poprrouti`g'' = `vari':`glab'
						}
						if `g' == 1 {
							mat `poprrouti' = `poprrouti`g''
						}
						else {
							//Stack the matrices
							mat `poprrouti' = `poprrouti'	\  `poprrouti`g''
						}
					}
					//Stack the matrices
					local ++newnrows
					if `newnrows' == 1 {
						mat `poprrout' = `poprrouti'	
					}
					else {
						mat `poprrout' = `poprrout'	\  `poprrouti'
					}
				}
			}
			
			if "`comparative'" != "" | "`mcbnetwork'" != "" {
				//Comparative RR
				local mindex 0
				local newnrows 0
				foreach vari of local eqnames {		
					local ++mindex
					local group : word `mindex' of `rnames'
					
					cap drop `subset'
					if "`group'" != "Overall" {
						cap drop `hold'
						decode `vari', gen(`hold')
						
						local latentgroup = ustrregexra("`group'", "_", " ")
						gen `subset' = 1 if `hold' == "`latentgroup'"  & `insample' == 1
					}
					else {
						//All
						gen `subset' = 1  if `insample' == 1
					}
					cap drop `subsetid'
					egen `subsetid' = seq()	 if `subset' == 1
					
					count if `subset' == 1 & `idpair' == 2
					local nsubset = r(N)
					
					//Compute mean of simulated values
					cap drop `sumrrhat'
					gen `sumrrhat' = 0	
					forvalues j=1(1)`nobs' { 
						sum `gid' if `subsetid' == `j'
						local index = r(min)
						
						sum `idpair' if `subsetid' == `j'
						local pair = r(min)
						
						if `pair' == 2 {
							qui replace `sumrrhat' = `sumrrhat' + `rrhat`index''
						}
					}
					
					//Obtain mean of modelled estimates
					sum `modelrr' if `subset' == 1
					local meanmodelrr = r(mean)
					
					cap drop `meanrrhat'
					gen `meanrrhat' = `sumrrhat'/`nsubset'
					//Standard error
					sum `meanrrhat'	
					local postse = r(sd)
					
					//Obtain the quantiles
					centile `meanrrhat' , centile(50 `=(100-`level')/2' `=100 - (100-`level')/2')
					local median = r(c_1) //Median
					local lowerp = r(c_2) //Lower centile
					local upperp = r(c_3) //Upper centile
					
					mat `poprrouti' = (`meanmodelrr', `postse', `median', `lowerp', `upperp')
					mat rownames `poprrouti' = `vari':`group'
					
					//Stack the matrices
					local ++newnrows
					if `newnrows' == 1 {
						mat `poprrout' = `poprrouti'	
					}
					else {
						mat `poprrout' = `poprrout'	\  `poprrouti'
					}
				}
			}
		}
		if "`todo'" == "smooth" {
			replace `modeles' = `modelp' if  `insample' == 1
			//Smooth p's
			if "`outplot'" == "abs" {
				//postci
				local critvalue -invnorm((100-`level')/200)
				replace `modellci' = invlogit(`eta' - `critvalue'*`modelse') if  `insample' == 1 //lower
				replace `modeluci' = invlogit(`eta' + `critvalue'*`modelse') if  `insample' == 1 //upper
			
			}
			
			//Smooth rr's
			if "`outplot'" == "rr" {
				replace `modeles' = `modelrr' if  `insample' == 1
				
				*sum `gid' if `insample' == 1 
				count if `insample' == 1 & `idpair' == 2
				local nstudies = r(N)
				
				egen `subsetid' = seq()	if `insample' == 1 & `idpair' == 2
			
				forvalues j=1(1)`nstudies' {
					
					sum `gid' if `subsetid' == `j'
					local index = r(min)
					
					//Obtain the quantiles
					centile `rrhat`index'', centile(50 `=(100-`level')/2' `=100 - (100-`level')/2')
					local median = r(c_1) //Median
					local lowerp = r(c_2) //Lower centile
					local upperp = r(c_3) //Upper centile
					
					replace `modellci' = `lowerp' if (`gid' == `index') & (`idpair' == 2) &  `insample' == 1
					replace `modeluci' = `upperp' if (`gid' == `index') & (`idpair' == 2) &  `insample' == 1
				}		 
			}
		}
		
		drop if `present' != 1
	}
		
	//Return matrices
	if "`todo'" =="abs" {
		mat colnames `popabsout' = Mean SE Median Lower Upper
		return matrix outmatrix = `popabsout'
	}
	if "`todo'" == "rr" {
		mat colnames `poprrout' = Mean SE Median Lower Upper
		return matrix outmatrix = `poprrout'
	}

end

/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: PRINTMAT +++++++++++++++++++++++++
							Print the outplot matrix beautifully
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
cap program drop printmat
program define printmat
	version 13.1
	syntax, matrixout(name) type(string) [sumstat(string) dp(integer 2) power(integer 0) ///
		mcbnetwork pcbnetwork abnetwork general comparative continuous p(integer 0) model(string)]
	
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
			noi matlist `matrixout', rowtitle(Parameter) 
						cspec(& %`rownamesmaxlen's |  %8.`=`dp''f &  %8.0f &  %8.`=`dp''f o2&) 
						rspec(`rspec') underscore nodotz
			;
			#delimit cr			
		}
		if "`type'" == "popabs" | "`type'" == "poprr" {
			if "`type'" == "popabs" {
				local parm "Proportion"
			}
			else {
				local parm "Proportion Ratio"
			}
		
			di as res _n "****************************************************************************************"
			di as res _n "Population-averaged estimates: `parm' "
			
			tempname mat2print
			mat `mat2print' = `matrixout'
			local nrows = rowsof(`mat2print')
			
			forvalues r = 1(1)`nrows' {
				mat `mat2print'[`r', 1] = `mat2print'[`r', 1]*10^`power'
				mat `mat2print'[`r', 3] = `mat2print'[`r', 3]*10^`power'
				mat `mat2print'[`r', 4] = `mat2print'[`r', 4]*10^`power'
				mat `mat2print'[`r', 5] = `mat2print'[`r', 5]*10^`power'
						
				forvalues c = 1(1)5 {
					local cell = `mat2print'[`r', `c'] 
					if "`cell'" == "." {
						mat `mat2print'[`r', `c'] == .z
					}
				}
			}
			
			#delimit ;
			noi matlist `mat2print', rowtitle(Parameter) 
						cspec(& %`rownamesmaxlen's |  %8.`=`dp''f &  %8.`=`dp''f & %8.`=`dp''f & %8.`=`dp''f & %8.`=`dp''f o2&) 
						rspec(`rspec') underscore nodotz
			;
			#delimit cr		
			
			
		}
		if ("`type'" == "logit") | ("`type'" == "abs") | ("`type'" == "rr")  {
			if ("`model'" == "random") {
				local typeinf "Conditional"
			}
			else {
				local typeinf "Marginal"
			}
			di as res _n "****************************************************************************************"
			if ("`type'" == "logit") { 
				di as res "{pmore2} `typeinf' Summary: Log odds {p_end}"
			}
			if ("`type'" == "abs") { 
				di as res "{pmore2} `typeinf' summary: Proportion {p_end}"
			}
			if ("`type'" == "rr") {
				di as res "{pmore2} `typeinf' summary: Proportion Ratio {p_end}"
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
			noi matlist `mat2print', rowtitle(Parameter) 
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
			local rownamesmaxlen = max(`rownamesmaxlen', 17) //Check if there is a longer name
			#delimit ;
			noi matlist `matrixout', rowtitle(Omitted Parameter) 
				cspec(& %`=`rownamesmaxlen' + 2's |  %8.`=`dp''f &  %8.0f &  %8.`=`dp''f &  %15.`=`dp''f o2&) 
				rspec(`rspec') underscore nodotz
			;
		
			#delimit cr
			if "`interaction'" !="" {
				di as txt "*NOTE: Model with and without interaction parameter(s)"
			}
			else {
				di as txt "*NOTE: Model with and without main parameter(s)"
			}
			
			di as txt "*NOTE: Delta BIC = BIC (specified model) - BIC (reduced model) "
		}
		
		if ("`continuous'" != "") {
			di as txt "NOTE: For continuous variable margins are computed at their respective mean"
		} 
		if ("`type'" == "abs") {
			di as txt "NOTE: H0: Est = 0.5 vs. H1: Est != 0.5"
		}
		if ("`type'" == "rr") {
			di as txt "NOTE: H0: Est = 1 vs. H1: Est != 1"
		}
		if ("`type'" == "logit") {
			di as txt "NOTE: H0: Est = 0 vs. H1: Est != 0"
		}
		if ("`type'" == "popabs") | ("`type'" == "poprr") {
			di as txt "NOTE: `level'% centiles obtained from 1000 simulations of the posterior distribution"
		}
		if ("`type'" == "logit") { 
			di  _n				
			display `"{stata "estimates replay metapreg_modest":Click to show the raw estimates}"'
		}
		
end	

/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: ESTRCORE +++++++++++++++++++++++++
							Obtain the RR after modelling
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
cap program drop estrcore
program define estrcore, rclass
version 13.1

syntax, marginlist(string) [cimethod(string) varx(varname) by(varname) confounders(varlist) level(integer 95) ///
	baselevel(integer 1) df(string)]
		
	tempname lcoef lV outmatrix nltest
	

	//Expression for logodds prediction
	local expression "predict(xb)"

	
	//Approximate sampling distribution critical value
	if "`cimethod'" != "wald" {
		local critvalue invttail(`df', `=(100-`level')/200')
	}
	else {
		local critvalue -invnorm((100-`level')/200)
	}
	qui margins `marginlist', `expression' over(`by') post level(`level')

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
			local init 1
			
			forvalues l = 1/`nlevels' {
				if `l' != `baselevel' {
					/*if `init' == 1 {
						local test_`c' = "_b[`c'_`l']"
						local init 0
					}
					else {
						local test_`c' = "_b[`c'_`l'] = `test_`c''"
					}*/
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
		if "`cimethod'" != "wald" {
			mat `outmatrix'[`r', 4] = ttail(`df', abs(`outmatrix'[`r', 3]))*2   /*p-value*/
		}
		else {
			mat `outmatrix'[`r', 4] =  normprob(-abs(`outmatrix'[`r', 3]))*2  /*p-value*/
		}
		mat `outmatrix'[`r', 5] = exp(`lcoef'[1, `r'] - `critvalue' * sqrt(`lV'[1, `r'])) /*lower*/
		mat `outmatrix'[`r', 6] = exp(`lcoef'[1, `r'] + `critvalue' * sqrt(`lV'[1, `r'])) /*upper*/
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
		syntax, estimates(string) studyid(varname) [catreg(varlist) typevarx(string) varx(varname) comparator(varname) cimethod(string) ///
			level(integer 95) DP(integer 2) mcbnetwork pcbnetwork abnetwork general comparative stratify power(integer 0) by(varname) ///
			regexpression(string) baselevel(integer 1)  interaction  ]
		
		//Expression for logodds prediction
		local expression "predict(xb)"

		
		//Approximate sampling distribution critical value
		if "`cimethod'" != "wald" {
			qui estimates restore `estimates'
			local df = e(N) -  e(k)
			local critvalue invttail(`df', `=(100-`level')/200')
		}
		else {
			local critvalue -invnorm((100-`level')/200)
		}
		
		if "`comparative'`mcbnetwork'`pcbnetwork'" != "" {
			local idpairconcat "#`varx'"
		}
		
		if "`mcbnetwork'`pcbnetwork'" != "" {
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
		*if "`mcbnetwork'`pcbnetwork'" != "" {			
		*	local confounders "`by' `catreg'"
		*}

		local marginlist
		while "`catreg'" != "" {
			tokenize `catreg'
			local first "`1'"
			macro shift 
			local catreg `*'
			if "`first'" != "`studyid'" {
				local marginlist = `"`marginlist' `first'`idpairconcat'"'
			}
		}
		
		tempname lcoef lV outmatrix row outmatrixr overall  nltest rowtestnl testmat2print bymat ///
				bynltest compmat compnltest catregmat catregnltest varxcoef
				
		local nrowsout 0
		local nrowsnl 0
		local nby 0
		local ncomp 0
		local ncatreg 0
		
		if "`by'" != "" & "`typevarx'" == "i" & "`stratify'" == "" {
			qui estimates restore `estimates'
			local df = e(N) -  e(k)
			
			estrcore, marginlist(`varx') varx(`varx') by(`by') confounders(`by') df(`df') 
			
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
		
		qui label list `comparator'
		local nc = r(max)
		if ("`by'" != "`comparator'") & ("`comparator'" != "") & (`nc' > 1) {	
			qui estimates restore `estimates'
			local df = e(N) -  e(k)
			
			estrcore, marginlist(`varx') varx(`varx') by(`comparator') confounders(`comparator') df(`df') 
			
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
			local df = e(N) -  e(k)
			
			if "`comparative'`mcbnetwork'`pcbnetwork'" != "" { 
				estrcore, marginlist(`marginlist') varx(`varx') confounders(`confounders') baselevel(`baselevel') df(`df') 
			}
			else {
				estrcore, marginlist(`marginlist') confounders(`confounders') baselevel(`baselevel') df(`df') 
			}
			
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

		if "`comparative'`mcbnetwork'`pcbnetwork'" != "" {			
			mat `overall' = J(1, 6, .)		
			
			
				qui estimates restore `estimates'
				local df = e(N) -  e(k)
				
				qui margins `varx', `expression' post level(`level')
				
				mat `varxcoef' = e(b)'
				local varxcats:rownames `varxcoef'
				
				forvalues r = 1(1)2 {
					local rname`r':word `r' of `varxcats'
					tokenize `rname`r'', parse(.)
					local coef`r' = "`1'"
					if strpos("`coef`r''", "bn") != 0 {
						local coef`r' = ustrregexra("`coef`r''", "bn", "")
					}
				}
						
				//log metric
				qui nlcom (Overall: ln(invlogit(_b[`coef2'.`varx'])) - ln(invlogit(_b[`coef1'.`varx']))) 
						  
				mat `lcoef' = r(b)
				mat `lV' = r(V)
				mat `lV' = vecdiag(`lV')
				mat `overall'[1, 1] = exp(`lcoef'[1,1])  //rr
				mat `overall'[1, 2] = sqrt(`lV'[1, 1]) //se
				mat `overall'[1, 3] = `lcoef'[1, 1]/sqrt(`lV'[1, 1]) //zvalue
				if "`cimethod'" != "wald" {
					mat `overall'[1, 4] = ttail(`df', -abs(`overall'[1, 3]))*2 //pvalue
				}
				else {
					mat `overall'[1, 4] = normprob(-abs(`overall'[1, 3]))*2 //pvalue
				}
				mat `overall'[1, 5] = exp(`lcoef'[1, 1] - `critvalue'*sqrt(`lV'[1, 1])) //ll
				mat `overall'[1, 6] = exp(`lcoef'[1, 1] + `critvalue'*sqrt(`lV'[1, 1])) //ul
			
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
		
		if "`cimethod'" == "wald" {
			mat colnames `outmatrix' = Mean SE(lrr) z(lor) P>|z| Lower Upper
		}
		else {
			mat colnames `outmatrix' = Mean SE(lrr) t(lor) P>|t| Lower Upper
		}
			
		if `nrowsnl' > 0 {
			local inltest = "yes"
			mat colnames `nltest' = chi2 df p
			return matrix nltest = `nltest'
		}
		else {
			local inltest = "no"
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
	
/*==================================== GETWIDTH  ================================================*/
/*===============================================================================================*/
capture program drop getlen
program define getlen
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
		noWT
		noBox
		OLineopts(string) 
		outplot(string) 
		SUMStat(string asis) 
		POINTopts(string) 
		BOXopts(string) 
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
		abnetwork
		pcbnetwork
		mcbnetwork
		general
		smooth
		model(string)
		*
	  ];
	#delimit cr
	
	local fopts `"`options'"'
	
	tempvar es modeles lci modellci uci modeluci lpi upi ilci iuci predid use label tlabel id newid df expand orig flag ///
	
	tokenize "`varlist'", parse(" ")

	qui {
		gen `es'		=`1'*(10^`power')
		gen `lci'   	=`2'*(10^`power')
		gen `uci'   	=`3'*(10^`power')
		gen byte `use'	=`4'
		gen str `label'	=`5'
		gen `df' 		= `6'
		gen `id' 		= `7'
		
		if "`smooth'" !="" {
			gen `modeles' 	= `8'*(10^`power')
			gen `modellci' 	= `9'*(10^`power')
			gen `modeluci' 	= `10'*(10^`power')
		}

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
		if "`abnetwork'" != "" & "`outplot'" == "rr" {
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
	
		tempvar estText index predText predLabel wtText modelestText
		
		gen str `estText' = string(`es', "%10.`=`dp''f") + " (" + string(`lci', "%10.`=`dp''f") + ", " + string(`uci', "%10.`=`dp''f") + ")"  if (`use' == 1 | `use' == 2 | `use' == 3)
		
		if "`smooth'" !="" {
			gen str `modelestText' = string(`modeles', "%10.`=`dp''f") + " (" + string(`modellci', "%10.`=`dp''f") + ", " + string(`modeluci', "%10.`=`dp''f") + ")"  if (`use' == 1 )
			replace `modelestText' = string(`es', "%10.`=`dp''f") + " (" + string(`lci', "%10.`=`dp''f") + ", " + string(`uci', "%10.`=`dp''f") + ")"  if (`use' == 2 | `use' == 3)
			replace `estText' = " " if (`use' == 2 | `use' == 3)
		}
		if "`wt'" == "" {
			gen str `wtText' = string(_WT, "%10.`=`dp''f") if (`use' == 1 | `use' == 2 | `use' == 3)
		}
		
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
			replace `es' = ln(`es')
			replace `lci' = ln(`lci')
			replace `uci' = ln(`uci')
			
			if "`smooth'" !="" { 
				replace `modeles'  = ln(`modeles')
				replace `modellci' = ln(`modellci')
				replace `modeluci' = ln(`modeluci')
			}
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
			replace `es' = . if `index' == 2
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
		if "`wt'" == "" {
			local rcols = "`wtText' " + "`rcols'"
			label var `wtText' "% Weight"
		}
		if "`smooth'" !=""  {
			local rcols = "`modelestText' " + "`rcols'"
			label var `modelestText' "Smooth Est (`level'% CI)"
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
				/*if ((`rcolsN' > 2) & ("`wt'`stats'" == "") &  ("`smooth'" !="")) | ((`rcolsN' > 1) & (("`wt'`stats'" != "") | ("`smooth'" == "")))  {
					replace `rightLB`rcolsN'' = "" if (`use' != 1  )
				}*/
				replace `rightLB`rcolsN'' = "" if (`use' == 0 |  `use' == -2 )
				
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
			getlen `leftLB`i'' `leftWD`i''
			qui summ `leftWD`i'' if `use' != 3 	// DON'T INCLUDE OVERALL STATS AT THIS POINT
			local maxL = r(max)
			local leftWDtotNoTi = `leftWDtotNoTi' + `maxL'
			replace `leftWD`i'' = `maxL'
		}
		tempvar titleLN				// CHECK IF OVERALL LENGTH BIGGER THAN REST OF LCOLS
		getlen `leftLB1' `titleLN'	
		qui summ `titleLN' if `use' == 3
		local leftWDtot = max(`leftWDtotNoTi', r(max))

		forvalues i = 1/`rcolsN'{
			getlen `rightLB`i'' `rightWD`i''
			qui summ `rightWD`i'' if  `use' != 3
			
			replace `rightWD`i'' = r(max)
			local rightWDtot = `rightWDtot' + r(max)
		}
		

		// CHECK IF NOT WIDE ENOUGH (I.E., OVERALL INFO TOO WIDE)
		// LOOK FOR EDGE OF DIAMOND summ `lci' if `use' == ...

		tempvar maxLeft
		getlen `leftLB1' `maxLeft'
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
		gen `DIAMtopX'    = `es' if (`use' == 2 | `use' == 3)
		
		replace `DIAMleftX' = `DXmin' if (`lci' < `DXmin' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMleftX' = . if (`es' < `DXmin' ) & (`use' == 2 | `use' == 3) 
		//If one study, no diamond
		replace `DIAMleftX' = . if (`df' < 2) & (`use' == 2 | `use' == 3) 
		
		replace `DIAMleftY1' = `id' + 0.4*(abs((`DXmin' -`lci')/(`es'-`lci'))) if (`lci' < `DXmin' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMleftY1' = . if (`es' < `DXmin' ) & (`use' == 2 | `use' == 3) 
	
		replace `DIAMleftY2' = `id' - 0.4*( abs((`DXmin' -`lci')/(`es'-`lci')) ) if (`lci' < `DXmin' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMleftY2' = . if (`es' < `DXmin' ) & (`use' == 2 | `use' == 3) 
		
		replace `DIAMrightX' = `DXmax' if (`uci' > `DXmax' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMrightX' = . if (`es' > `DXmax' ) & (`use' == 2 | `use' == 3) 
		//If one study, no diamond
		replace `DIAMrightX' = . if (`df' == 1) & (`use' == 2 | `use' == 3) 
	
		replace `DIAMrightY1' = `id' + 0.4*( abs((`uci'-`DXmax' )/(`uci'-`es')) ) if (`uci' > `DXmax' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMrightY1' = . if (`es' > `DXmax' ) & (`use' == 2 | `use' == 3) 

		replace `DIAMrightY2' = `id' - 0.4*( abs((`uci'-`DXmax' )/(`uci'-`es')) ) if (`uci' > `DXmax' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMrightY2' = . if (`es' > `DXmax' ) & (`use' == 2 | `use' == 3) 

		replace `DIAMbottomY' = `id' - 0.4*( abs((`uci'-`DXmin' )/(`uci'-`es')) ) if (`es' < `DXmin' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMbottomY' = `id' - 0.4*( abs((`DXmax' -`lci')/(`es'-`lci')) ) if (`es' > `DXmax' ) & (`use' == 2 | `use' == 3) 

		replace `DIAMtopY' = `id' + 0.4*( abs((`uci'-`DXmin' )/(`uci'-`es')) ) if (`es' < `DXmin' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMtopY' = `id' + 0.4*( abs((`DXmax' -`lci')/(`es'-`lci')) ) if (`es' > `DXmax' ) & (`use' == 2 | `use' == 3) 

		replace `DIAMtopX' = `DXmin'  if (`es' < `DXmin' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMtopX' = `DXmax'  if (`es' > `DXmax' ) & (`use' == 2 | `use' == 3) 
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
		local diamopts "lcolor(red)"
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
	//Box options
	if "`box'" == "" {
		local iw = "[aw = _WT]"
		if `"`boxopts'"' != "" & strpos(`"`boxopts'"',"msy") == 0{
			local boxopts = `"`boxopts' msymbol(square)"' 
		}
		if `"`boxopts'"' != "" & strpos(`"`boxopts'"',"msi") == 0{
			local boxopts = `"`boxopts' msize(0.5)"' 
		}
		if `"`boxopts'"' != "" & strpos(`"`boxopts'"',"mco") == 0{
			local boxopts = `"`boxopts' mcolor("180 180 180")"' 
		}
		if `"`boxopts'"' == "" {
			local boxopts "msymbol(square) msize(.5) mcolor("180 180 180")"
		}
		else{
			local boxopts `"`boxopts'"'
		}
	}
	if ("`box'" != "") {
		local boxopts "msymbol(none)"
		local iw
	}
	
	
	//Point options
	if "`smooth'" != "" {
		local pointsymbol "msymbol(Oh)"
		local pointcolor "mcolor("128 128 128")"
		local pointsize "msize(small)"
	}
	else {
		local pointsymbol "msymbol(O)"
		local pointcolor "mcolor("0 0 0")"
		local pointsize "msize(vsmall)"
	}
	
	if `"`pointopts'"' != "" & strpos(`"`pointopts'"',"msy") == 0 {
		local pointopts = `"`pointopts' `pointsymbol'"' 
	}
	if `"`pointopts'"' != "" & strpos(`"`pointopts'"',"ms") == 0 {
		local pointopts = `"`pointopts' `pointsize'"' 
	}
	if `"`pointopts'"' != "" & strpos(`"`pointopts'"',"mc") == 0 {
		local pointopts = `"`pointopts' `pointcolor'"' 
	}
	if `"`pointopts'"' == "" {
		local pointopts `"`pointsymbol' `pointsize' `pointcolor'"'
	}
	else{
		local pointopts `"`pointopts'"'
	}
	
	//Smooth Point options
	if `"`smoothpointopts'"' != "" & strpos(`"`smoothpointopts'"',"msy") == 0 {
		local smoothpointopts = `"`smoothpointopts' msymbol(D)"' 
	}
	if `"`smoothpointopts'"' != "" & strpos(`"`smoothpointopts'"',"ms") == 0 {
		local smoothpointopts = `"`smoothpointopts' msize(vsmall)"' 
	}
	if `"`smoothpointopts'"' != "" & strpos(`"`smoothpointopts'"',"mc") == 0 {
		local smoothpointopts = `"`smoothpointopts' mcolor("0 0 0")"' 
	}
	if `"`smoothpointopts'"' == ""{
		local smoothpointopts "msymbol(D) msize(vsmall) mcolor("0 0 0")"
	}
	else{
		local smoothpointopts `"`smoothpointopts'"'
	}
	
	// CI options
	if `"`ciopts'"' == "" {
		if "`smooth'" != "" {
			local ciopts = `"`ciopts' lwidth(1.25) lcolor(gs13)"'
		}
		else {
			local ciopts = `"`ciopts' lcolor("0 0 0")"' 
		}
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
		if "`smooth'" != "" {
			if strpos(`"`ciopts'"',"lc") == 0 {
				local ciopts = `"`ciopts' lcolor(red)"' 
			}
			if strpos(`"`ciopts'"',"lw") == 0 {
				local ciopts = `"`ciopts' lwidth(2)"' 
			}
		}
		else {
			local ciopts = `"`ciopts' lcolor("0 0 0")"' 
		}
		
		local ciopts `"`ciopts'"'
	}
	//Smooth ci
	if `"`smoothciopts'"' == "" {
		local smoothciopts "lcolor("0 0 0")"
	}
	else {
		if strpos(`"`smoothciopts'"',"hor") != 0 | strpos(`"`smoothciopts'"',"vert") != 0{
			di as error "Options horizontal/vertical not allowed in ciopts()"
			exit
		}
		if strpos(`"`smoothciopts'"',"con") != 0{
			di as error "Option connect() not allowed in ciopts()"
			exit
		}
		if strpos(`"`smoothciopts'"',"lp") != 0 {
			di as error "Option lpattern() not allowed in ciopts()"
			exit
		}
		if strpos(`"`smoothciopts'"',"lw") == 0 {
				local smoothciopts = `"`smoothciopts' lwidth(.5)"' 
		}

		local smoothciopts `"`smoothciopts'"'
	}
	
	// PREDCI options
	if `"`predciopts'"' == "" {
		local predciopts "lcolor(red) lpattern(solid)"
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
			local predciopts = `"`predciopts' lcolor(red)"' 
		}
		local predciopts `"`predciopts'"'
	}
	// Arrow options
	if `"`arrowopts'"' == "" {
		if "`smooth'" != "" {
			local arrowopts "mcolor(red) lstyle(none)"
		}
		else {
			local arrowopts "mcolor("0 0 0") lstyle(none)"
		}
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
		local olineopts "lwidth(thin) lcolor(red) lpattern(shortdash)"
	}
	qui summ `id'
	local DYmin = r(min)
	local DYmax = r(max) + 2
	
	qui summ `es' if `use' == 3 
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
			summ `es' if `use' == 2  & `groupvar' == `l' 
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
		replace `es' = . if (round(`es', 0.001) < round(`DXmin' , 0.001)) & (`use' == 1 | `use' == 4) 
		replace `es' = . if (round(`es', 0.001) > round(`DXmax' , 0.001)) & (`use' == 1 | `use' == 4) 

		if "`smooth'" != "" {
			replace `modellci' = `DXmin'  if (round(`modellci', 0.001) < round(`DXmin' , 0.001)) & (`use' == 1) 
			replace `modeluci' = `DXmax'  if (round(`modeluci', 0.001) > round(`DXmax' , 0.001)) & (`modeluci' !=.) & (`use' == 1 ) 
			
			replace `modellci' = . if (round(`modeluci', 0.001) < round(`DXmin' , 0.001)) & (`modeluci' !=. ) & (`use' == 1 ) 
			replace `modeluci' = . if (round(`modellci', 0.001) > round(`DXmax' , 0.001)) & (`modellci' !=. ) & (`use' == 1 )
			replace `modeles' = . if (round(`modeles', 0.001) < round(`DXmin' , 0.001)) & (`use' == 1 ) 
			replace `modeles' = . if (round(`modeles', 0.001) > round(`DXmax' , 0.001)) & (`use' == 1 )
		}
		
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
	if "`smooth'" != "" {
		local xboxcenter "`modeles'"
		local smoothcommands1 "(pcspike `id' `modellci' `id' `modeluci' if `use' == 1 , `smoothciopts')"
		local smoothcommands2 "(scatter `id' `modeles' if `use' == 1 , `smoothpointopts')"
	}
	else {
		local xboxcenter "`es'"
	}
	
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
	 /*PLOT BOXES AND PUT ALL THE GRAPH OPTIONS IN THERE */ 
		(scatter `id' `xboxcenter' `iw' if `use' == 1, 
			`boxopts'		
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
		`smoothcommands1'		
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
		(scatter `id' `es' if `use' == 1 , `pointopts')	
		`smoothcommands2' `overallCommand'	
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