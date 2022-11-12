/*
CREATED:	8 Sep 2017
AUTHOR:		Victoria N Nyaga
PURPOSE: 	To fit a bivariate random-effects model to diagnostic data and 
			produce a series of graphs(sroc and forestsplots).
VERSION: 	2.0.0
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
14.09.2020					Correct way of counting the distinct groups in the meta-analysis
							Check to ensure variable names do no contain underscore.
15.02.2021					paired data: tp1 fp1 .. fn2 tn2 comparator index covariates, by(byvar)
							comparator, index, byvar need to be string
							Need to test more with more covariates!!!
							vline > xline
29.03.2021					order tp fp fn tn
07.05.2021					Reduce the blank lines in the output
11.05.2021					fixed dp = 4 for p-value, fixed dp=0 for df
14.06.2021					Graph save issues
17.06.2021					Subline fix
15.10.2021					Subgroup analysis with superimposed graphs; stratify option
09.06.2022					Network meta-analysis; 
26.07.2022					REF(label, top|bottom) ; default is bottom
01.08.2022					Renamed network to abnetwork; and paired to cbnetwork
10.10.2022					introduce variance only on se or sp

FUTURE 						Work on the absolutes for the paired analysis; 

*/



/*++++++++++++++++++++++	METADTA +++++++++++++++++++++++++++++++++++++++++++
						WRAPPER FUNCTION
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
cap program drop metadta
program define metadta, eclass sortpreserve byable(recall)
version 14.0

	#delimit ;
	syntax varlist(min=4) [if] [in],  /*tp fp fn tn tp2 fp2 fn2 tn2  */
	STudyid(varname) /*Study Idenfier*/
	[
	STRatify  /*Stratified analysis, requires byvar()*/
	LAbel(string asis) /*namevar=namevar, yearvar=yearvar*/
	DP(integer 2) /*Decimal place*/
	POWer(integer 0) /*Exponentiating power*/  
	MODel(string asis) /*fixed (1 < n < 3) | random (random)*/ 
	COV(string asis) /*UNstructured(default)|INdependent | IDentity | EXchangeable, also includes second covariance for the network*/
	SORTby(varlist) /*order data by varlist. How data appears on the table and forest plot*/
	INteraction(string) /*sesp(default)|se|sp*/ 
	CVeffect(string) /*sesp(default)|se|sp*/ 
	Level(integer 95) /*Significance level*/
	COMParative /*Comparative data or not*/
	SUMtable(string) /*Which summary tables to present:abs|logodds|rr|all*/
	CImethod(string) /*ci method for the study proportions*/
	noFPlot /*No forest plot*/
	noITable /*No study specific summary table*/
	noHTable /*No heterogeneity table*/
	noMC /*No Model comparison - Saves time*/
	PROGress /*See the model fitting*/
	noSRoc /*No SROC*/
	noOVerall /*Dont report the overall in the Itable & fplot*/ 
	noSUBgroup /*Dont report the subgroup in the Itable & fplot*/ 
	SUMMaryonly /*Present only summary in the Itable & fplot*/
	DOWNload(string) /*Keep a copy of data used in the plotting*/
	Alphasort /*Sort the categorical variable alphabetically*/
	FOptions(string asis) /*Options specific to the forest plot*/
	SOptions(string asis) /*Options specific to the sroc plot*/
	by(varname)  /*the grouping variable*/
	PAIRed  /*Paired; now called CBnetwork*/
	CBnetwork /*AB network*/
	ABnetwork /*AB network*/
	REF(string asis) /*Reference level in network, comparative analysis */
	] ;
	#delimit cr
	
	preserve
	cap ereturn clear
	marksample touse, strok 
	qui drop if !`touse'

	tempvar rid se sp event total invtotal use id neolabel es lci uci grptotal uniq rowid obsid
	tempname logodds absout logoddsi absouti rrout rrouti sptestnl setestnl sptestnli setestnli selogodds absoutse selogoddsi ///
		absoutsei serrout serrouti splogodds absoutsp splogoddsi absoutspi ///
		sprrout sprrouti coefmat coefvar BVar BVari WVar WVari Esigma omat isq2 isq2i Isq Isq2 Isq2i ///
		bghet refe bgheti refei lrtestp V Vi dftestnl ptestnl semc semci spmc spmci samtrix ///
		serow sprow serrow sprrow nltest
	
	if _by() {
		global by_index_ = _byindex()
		if ("`fplot'" == "" | "`sroc'" == "") & "$by_index_" == "1" {
			cap graph drop _all
			global fplotname = 0
			global srocname = 0
		}
	}
	else {
		global by_index_ 
	}
	
	/*Check if variables exist*/
	foreach var of local varlist {
		cap confirm var `var'
		if _rc!=0  {
			di in re "Variable `var' not in the dataset"
			exit _rc
		}
	}
	
	/*Check for mu; its reserved*/
	qui ds
	local vlist = r(varlist)
	foreach v of local vlist {
		if ("`v'" == "se") | ("`v'" == "sp") {
			di as error "se/sp is a reserved variables name; drop or rename se/sp"
			exit _rc
		}
	}
	//define the design of analysis
	if "`paired'" != "" {
		di as res "Use of the option -paired- is deprecated and replaced with -cbnetwork-"
		local cbnetwork "cbnetwork"
	}
	if "`abnetwork'`comparative'`cbnetwork'" != "" {
		cap assert ("`cbnetwork'" != "") + ("`comparative'" != "") + ("`abnetwork'" != "") == 1
		if _rc!=0  {
			di as error "Define 1 option from: `cbnetwork' `comparative' `abnetwork'"
			exit _rc
		}
	}
	
	if "`cbnetwork'" != "" {
		local design = "cbnetwork"
	}
	else if "`comparative'" != "" {
		local design = "comparative"
	}
	else if "`abnetwork'" != "" {
		local design = "abnetwork"
	}
	else if "`abnetwork'`comparative'`cbnetwork'" == "" { 
		local design = "independent"  //default design
	}
	
	//General housekeeping
	if 	"`ref'" != "" {
		tokenize "`ref'", parse(",")
		local ref `1'
		local refpos "`3'"
	}
	if "`refpos'" != "" {
		if (strpos("`refpos'", "top") == 1) {
			local refpos "top"
		}
		else if (strpos("`refpos'", "bot") == 0) {
			local refpos "bottom"
		}
		else {
			di as error "Option `refpos' not allowed in ref(`ref', `refpos')"
			exit
		}
	}

	
	//default
	if "`refpos'" == "" {
		local refpos "bottom"
	}
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
		di as error "Option `model' not allowed in [`model', `modelopts']"
		di as error "Specify either -fixed- or -random-"
		exit
	}
	if "`model'" == "fixed" & strpos("`modelopts'", "ml") != 0 {
		di as error "Option ml not allowed in [`model', `modelopts']"
		exit
	}
	if "`model'" == "fixed" & strpos("`modelopts'", "irls") != 0 {
		di as error "Option irls not allowed in [`model', `modelopts']"
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
			di as res _n  "Warning: Consider specifying options for the fixed-effects model."
		}
	}
	if "`model'" == "random" {
		if "`cov'" != "" {
			tokenize "`cov'", parse(",")
			if "`1'" != "," {
				local bcov "`1'"
				local wcov "`3'"
			}
			else{
				local bcov 
				local wcov "`2'"
			}
			
			if "`bcov'" != "" {
				if strpos("`bcov'", "un")== 1 {
					local bcov = "unstructured"
				}	
				else if ustrregexm("`bcov'", "ind", 1){
					local bcov = "independent"
				}
				else if ustrregexm("`bcov'", "id", 1){
					local bcov = "identity"
				}
				else if strpos("`bcov'", "ex") == 1 {
					local bcov = "exchangeable"
				}
				else if strpos("`bcov'", "se") == 1 {
					local bcov = "se"
				}
				else if strpos("`bcov'", "sp") == 1 {
					local bcov = "sp"
				}
				else {
					di as error "Allowed covariance structures: se, sp, unstructured, independent, identity, or exchangeable"
					exit
				}
			}
			
			if "`abnetwork'`cbnetwork'" != "" & "`wcov'" != "" {
				if ustrregexm("`wcov'", "ind", 1){
					local wcov = "independent"
				}
				else if ustrregexm("`wcov'", "id", 1){
					local wcov = "identity"
				}
				else if ustrregexm("`wcov'", "ze", 1){
					local wcov "zero"
				}
				else {
					di as error "Allowed second covariance structures: independent, identity or zero"
					exit
				}
			}
		}
		if "`bcov'" == ""  {
			local bcov = "unstructured"	
		}
		if "`abnetwork'`cbnetwork'" != "" {
			if "`wcov'" == "" {
				local wcov = "independent"
			}
			if "`wcov'" == "zero" {
				local wcov 
			}
		}
	}
	else {
		local bcov
		local wcov
	}		
	if `level' < 1 {
			local level `level'*100
	}
	if `level'>99 | `level'<10 {
		local level 95
	}

	/*By default the regressor variabels apply to both sensitivity and specificity*/
	if "`cveffect'" == "" {
		local cveffect "sesp"
	}
	else {
		local rc_ = ("`cveffect'"=="sesp") + ("`cveffect'"=="se") + ("`cveffect'"=="sp")
		if `rc_' != 1 {
			di as err "Options cveffect(`cveffect') incorrectly specified"
			di as err "Allowed options: sesp, se sp"
			exit
		}
	}
	if "`interaction'" != "" {
		if ("`interaction'" != "`cveffect'") & ("`cveffect'" != "sesp"){
			di as err "Conflict in cveffect(`cveffect') & interaction(`interaction')"
			exit
		}
	}

	tokenize `varlist'
	if "`design'" != "cbnetwork" {		
		local depvars "`1' `2' `3' `4'" //	tp fp fn tn 
	
	macro shift 4
	}
	else {
		tempvar index byvar assignment idpair
		cap assert "`10'" != ""
		if _rc != 0 {
			di as err "cbnetwork data requires atleast 10 variable"
			exit _rc
		}
		local depvars "`1' `2' `3' `4' `5' `6' `7' `8'" //	tp1 fp1 fn1 tn1 tp2 fp2 fn2 tn2
		local tp = "`1'"
		local fp = "`2'"
		local fn = "`3'"
		local tn = "`4'"
		local Comparator = "`10'"
		local Index = "`9'"
		
		forvalues num = 1/8 {
			cap confirm integer number `num'
			if _rc != 0 {
				di as error "`num' found where integer expected"
				exit
			}
		}
		cap confirm string variable `9'
		if _rc != 0 {
			di as error "The index variable in cbnetwork analysis should be a string"
			exit, _rc
		}
		cap confirm string variable `10'
		if _rc != 0 {
			di as error "The comparator variable in cbnetwork analysis should be a string"
			exit, _rc
		}
		macro shift 10
		
	}
	local regressors "`*'" 
	gettoken varx confounders : regressors
	local p: word count `regressors'
	*local idpair: word 1 of `regressors'
	
	if ("`design'" == "independent") & ("`stratify'" != "") & ("`by'" != "") & (`p' > 0) {
		di as err "Re-frame your analysis. The options _stratify & by()_ in meta-regression is confusing. Consider using the prefix by: instead"
		exit
	}
	
	//check no underscore in the variable names
	if strpos("`regressors'", "_") != 0  {
		di as error "Underscore is a reserved character and covariate(s) containing underscore(s) are not allowed"
		di as error "Rename the covariate(s) and remove the underscore(s) character"
		exit	
	}
	
	if `p' < 2 & "`interaction'" !="" {
		di as error "Interactions allowed with atleast 2 covariates"
		exit
	}
	if ("`design'" == "comparative") | ("`design'" == "abnetwork")  {
		gettoken first confounders : regressors
		cap assert `p' > 0
		if _rc != 0 {
			di as error "`design' analysis requires at least 1 covariate to be specified"
			exit _rc
		}
		*gettoken varx confounders : regressors
		if "`first'" != "" {
			cap confirm string variable `first'
			if _rc != 0 {
				di as error "The first covariate in `design' analysis should be a string"
				exit, _rc
			}
		}
		local typevarx = "i"
	}
	
	//=======================================================================================================================
	//=======================================================================================================================
	tempfile master
	qui save "`master'"
	
	fplotcheck,`design' `foptions' first(`first') by(`by') //Forest plot advance housekeeping
	local outplot = r(outplot)
	local foptions = r(foptions)
	local lcols = r(lcols)
	if "`lcols'" == " " { //if empty
		local lcols
	}
	
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
		
	//Long format
	longsetup `varlist', rid(`rid') se(`se') event(`event') total(`total') `design' rowid(`rowid')  idpair(`idpair') assignment(`assignment') first(`first')
	//Index
	if "`design'" == "cbnetwork" {
		tempvar ipair
		qui gen `ipair' = "Yes"
		qui replace `ipair' = "No" if `idpair'
	}

	//byvar
	if "`by'" != "" {
		cap confirm string variable `by'
		if _rc != 0 {
			di as error "The by() variable should be a string"
			exit, _rc
		}
		if strpos(`"`varlist'"', "`by'") == 0 {
			tempvar byvar
			my_ncod `byvar', oldvar(`by')
			drop `by'
			rename `byvar' `by'
		}
	}
	
		
	buildregexpr `varlist', cveffect(`cveffect') interaction(`interaction') se(`se') sp(`sp') `alphasort' `design'  ipair(`ipair') baselevel(`ref')
	
	local regexpression = r(regexpression)
	local seregexpression = r(seregexpression)
	local spregexpression = r(spregexpression)
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
		local baselab:label `varx' `basecode'
		if `basecode' == 1 {
			local indexcode "2"
		}
		else {
			local indexcode "1"
		}
		local indexlab:label `varx' `indexcode'
	}
	local pcat: word count `catreg'
	
	/*if "`cbnetwork'" != "" {
		local varx = "`index'"
		local typevarx  = "i"
	*/
	
	
	/*if ("`cbnetwork'" == "") & ("`comparative'" == "") & ("`interaction'" == "")  {
		local varx 
		local typevarx  
	}*/
	if "`design'" == "cbnetwork" { 
		local varx = "`ipair'"
		local typevarx = "i"		
	}
	
	
	//Ensure varx in comparative is bi-categorical
	if "`comparative'" != "" {
		qui label list `varx'
		local ncat = r(max)
		cap assert `ncat' == 2
		if _rc != 0 {
			di as error "Comparative analysis requires that `varx' only has 2 categories but found `ncat'"
			exit _rc
		} 
	}
	
	local pcont: word count `contreg'
	if "`typevarx'" != "" & "`typevarx'" == "c" {
		local ++pcont
	}

	if `pcont' > 0 {
		local continuous = "continuous"
	}
	
	/*Model presenations*/
	local regressorss "`regressors'"
	/*Overall*/
	local lmuse = "mu_lse"
	local lmusp = "mu_lsp"
	
	if "`design'" == "independent" | "`design'" == "comparative" {	
		local nuse = "mu_lse"
		local nusp = "mu_lsp"
	}
	else if "`design'" == "cbnetwork" {
		if "`interaction'" != "" { 
			local nuse = "mu_lse + Ipair*`Comparator' + `Index'"
			local nusp = "mu_lsp + Ipair*`Comparator' + `Index'"
		}
		else {
			local nuse = "mu_lse + Ipair + `Index'"
			local nusp = "mu_lsp + Ipair + `Index'"
		}
	}
	else {
		*abnetwork
		local nuse = "mu.`first'_lse"
		local nusp = "mu.`first'_lsp"
		tokenize `regressors'
		mac shift
		local regressorss "`*'"
	}
	
	//Build the rest of the equation
	*local VarX: word 1 of `regressors'
	local q: word count `regressors'
	forvalues i=1/`q' {
		local c:word `i' of `regressorss'
		
		//se
		if "`cveffect'" != "sp" {
			local nuse = "`nuse' + `c'"
			if ("`interaction'" == "sesp" | "`interaction'" == "se") & `i' > 1 {
				local nuse = "`nuse' + `c'*`varx'"
			}
		}
		
		//sp
		if "`cveffect'" != "se" {
			local nusp = "`nusp' + `c'"
			if ("`interaction'" == "sesp" | "`interaction'" == "sp") & `i' > 1 {
				local nusp = "`nusp' + `c'*`varx'"
			}
		}
	}
	if ("`catreg'" != " " | "`typevarx'" =="i" | ("`design'" == "comparative" | "`design'" == "cbnetwork"))  {

		if "`design'" == "cbnetwork" {
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
		if "`design'" == "independent" {
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
		if "`outplot'" == "rr" & "`varx'" !="" {
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
	if "`by'" == "" & "`cbnetwork'" != "" {
		local groupvar  "`Index'"
		local byvar "`Index'"
	} 
	
	*Stratify not allow in cbnetwork or abnetwork analysis
	if "`stratify'" != "" {
		if ("`design'" == "cbnetwork") | ("`design'" == "abnetwork")  {
			di as error"The option stratify is not allowed in `design' analysis"
			exit
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
		//nomc 
		local mc
	}
	
	if "`groupvar'" == "" {
		local subgroup nosubgroup
	}
	
	qui gen `sp' = 1 - `se'
	*qui gen `use' = .
	
	//fit the model
	if "`progress'" != "" {
		local echo noi
	}
	else {
		local echo qui
	}
	
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
		if (`p' == 0) & ("`model'" == "random") &  ("`design'" != "cbnetwork" )  {
			local hetdim 5
		}
		else {
			local hetdim 4
		}
	}
	
	if "`outplot'" == "abs" {
		local sumstatse "Sensitivity"
		local sumstatsp "Specificity"
	}
	else {
		local sumstatse "Relative Sensitivity"
		local sumstatsp "Relative Specificity"
	}
	
	//Should run atleast once
	while `i' < `=`nlevels' + 2' {
		local modeli = "`model'"
		local modeloptsi = "`modelopts'"
	
		//don't run last loop if stratify
		*if (`i' > `nlevels') & ("`stratify'" != "") & ("`design'" == "comparative") {
		*	local overall "nooverall"
		*	continue, break
		*}
	
		*Stratify except the last loop for the overall
		if (`i' < `=`nlevels' + 1') & ("`stratify'" != "") {
			local strataif `"if `by' == `i'"'
			local ilab:label `by' `i'
			local stratalab `":`by' = `ilab'"'
			local ilab = ustrregexra("`ilab'", " ", "_")
			local byrownames = "`byrownames' `by':`ilab'"
			if "`design'" == "comparative" & "`stratify'" != "" {
				local bybirownames = "`bybirownames' `ilab':`baselab' `ilab':`indexlab' `ilab':Overall"
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
			if "`stratify'" != "" {
				local stratalab ": Full"
				local byrownames = "`byrownames' Overall"	
			}
			
			//Number of obs in the analysis
			qui count
			local Nobs= r(N)
			if "`cbnetwork'" != "" {
				local Nobs = `Nobs'*0.25
			}
			else {
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
		if `Nuniq' < 3 & "`modeli'" == "random"  {
			local modeli fixed //If less than 3 studies, use fixed model
			if "`modeloptsi'" != "" {
				local modeloptsi
				di as res _n  "Warning: Random-effects model options ignored."
				di as res _n  "Warning: Fixed-effects model fitted instead."
			}
		}
		

		
		di as res _n "*********************************** Fitted model`stratalab' ***************************************" 
		
		tokenize `varlist'
		di "{phang} `1' ~ binomial(se, `1' + `3'){p_end}"
		di "{phang} `4' ~ binomial(sp, `4' + `2'){p_end}"
		if "`modeli'" == "random" {
			di "{phang} logit(se) = `nuse' + `studyid'_lse{p_end}"
			di "{phang} logit(sp) = `nusp' + `studyid'_lsp{p_end}"
		}
		else {
			di "{phang} logit(se) = `nuse'{p_end}"
			di "{phang} logit(sp) = `nusp'{p_end}"
		}
		if "`modeli'" == "random" {
			if "`bcov'" == "se" {
				di "{phang}`studyid'_lse ~ normal(0, sigma){p_end}"
			}
			else if "`bcov'" == "sp"  {
				di "{phang}`studyid'_lsp ~ normal(0, sigma){p_end}"
			}
			else {
				di "{phang}`studyid'_lse, `studyid'_lsp ~ biv.normal(0, sigma){p_end}"
			}
		}
		if "`design'" == "cbnetwork"  {
			di "{phang} Ipair = 0 if 1st set{p_end}"
			di "{phang} Ipair = 1 if 2nd set{p_end}"
		}
		if "`design'" == "abnetwork" {
			if "`wcov'" == "identity" {
				di "{phang}`first'_lse, `first'_lsp  ~ N(0, `first'.tau2){p_end}"
			}
			else if "`wcov'" == "independent"  {
				di "{phang}`first'_lse ~ N(0, `first'_lse.tau2){p_end}"
				di "{phang}`first'_lsp ~ N(0, `first'_lsp.tau2){p_end}"
			}
			qui label list `first'
			local nfirst = r(max)
		}
		if "`design'" == "cbnetwork" {
			if "`wcov'" == "identity" {
				di "{phang}Ipair_lse, Ipair_lsp  ~ N(0, Ipair.tau2){p_end}"
			}
			else if "`wcov'" == "independent"  {
				di "{phang}Ipair_lse ~ N(0, Ipair_lse.tau2){p_end}"
				di "{phang}Ipair_lsp ~ N(0, Ipair_lsp.tau2){p_end}"
			}
		}
		if ("`catreg'" != " " | "`typevarx'" =="i" | ("`design'" == "comparative" | "`design'" == "cbnetwork"))  {
			di _n "{phang}Base levels{p_end}"
			di _n as txt "{pmore} Variable  -- Base Level{p_end}"
		}
		foreach fv of local catregs  {			
			local lab:label `fv' 1
			di "{pmore} `fv'  -- `lab'{p_end}"	
		}
		if "`design'" == "abnetwork" {
			local lab:label `first' `basecode'
			di "{pmore} `first'  -- `lab'{p_end}"
		}
		
		di as txt "{phang}Number of observations = " as res "`Nobs'{p_end}"
		di as txt "{phang}Number of studies = " as res "`Nuniq'{p_end}"
		if "`design'" == "abnetwork" {
			di as txt "{phang}Number of `first's = " as res "`nfirst'{p_end}"
		}
	
		*Run model if more than 1 study
		if `Nobs' > 1 {
			`echo' madamodel `event' `total' `se' `sp' `strataif', bcov(`bcov') wcov(`wcov') modelopts(`modeloptsi') model(`modeli') ///
			regexpression(`regexpression') sid(`studyid') `design' ipair(`ipair') level(`level') nested(`first')

			estimates store metadta_modest

			cap drop _ESAMPLE
			qui gen _ESAMPLE = e(sample)
			
			mat `coefmat' = e(b)
			mat `coefvar' = e(V)
			
		}
		else {
			mat `coefmat' = (0 , 0)
			mat `coefvar' = e(V)
		}

		estcovar, matrix(`coefmat') model(`modeli') bcov(`bcov') wcov(`wcov') `design'
		local kcov = r(k) //#covariance parameters
		mat `BVari' = r(BVar)  //Between var-cov
		mat `WVari' = r(WVar)  //Within var-cov
		mat colnames `BVari' = logitse logitsp
		mat rownames `BVari' = logitse logitsp
		
		mat colnames `WVari' = logitse logitsp
		mat rownames `WVari' = logitse logitsp
		
		local tausesp 	= `BVari'[1, 2]
		local rho 		= `BVari'[1, 2]/sqrt(`BVari'[1, 1]*`BVari'[2, 2])
		local tau2se 	= `BVari'[1, 1]
		local tau2sp	= `BVari'[2, 2]
		local tau2g		= (1 - (`BVari'[1, 2]/sqrt(`BVari'[1, 1]*`BVari'[2, 2]))^2)*`BVari'[1, 1]*`BVari'[2, 2]
			
		if("`sumtable'" != "") {
			local loddslabel = "Log_odds"
			local abslabel = "Proportion"
			local rrlabel = "Rel_Ratio"
		}
		if `Nobs' > 1 {
			local S_1 = e(N) -  e(k) //df
		}
		else {
			local S_1 = .
		}
		
		local S_2 = . //between study heterogeneity chi2
		local S_3 = . // between study heterogeneity pvalues
		local i2g = . //Isq
		local i2se = . //Isqse
		local i2sp = . //Isqsp
		local S_81 = . //Full vs Null chi2 -- se
		local S_91 = . //Full vs Null  pvalue -- se
		local S_891 = . //Full vs Null  df -- se
		local S_82 = . //Full vs Null chi2 -- sp
		local S_92 = . //Full vs Null  pvalue -- sp
		local S_892 = . //Full vs Null  df -- sp

		//Consider a reduced model	
		if "`modeli'" == "random" {
			qui estimates restore metadta_modest
			local S_2 = e(chi2_c)
			local S_3 = e(p_c)
		}
	
		if `p' == 0 & "`design'" == "independent" {
			/*Compute I2*/
			mat `Esigma' = J(2, 2, 0) /*Expected within study variance*/
			
			if "`strataif'" != "" {
				qui gen `invtotal' = 1/`total'
				
				qui summ `invtotal' if `se' & `by' == `i'
				local invtotalse = r(sum)
				
				qui summ `invtotal' if `sp' & `by' == `i'
				local invtotalsp = r(sum)
				drop `invtotal'
			}
			else {
				qui gen `invtotal' = 1/`total'
				qui summ `invtotal' if `se'
				local invtotalse = r(sum)
				
				qui summ `invtotal' if `sp' 
				local invtotalsp = r(sum)
			}

			mat `Esigma'[1, 1] = (exp(`BVari'[1, 1]*0.5 + `coefmat'[1, 1]) + exp(`BVari'[1, 1]*0.5 - `coefmat'[1, 1]) + 2)*(1/(`Nuniq'))*`invtotalse'
			mat `Esigma'[2, 2] = (exp(`BVari'[2, 2]*0.5 + `coefmat'[1, 2]) + exp(`BVari'[2, 2]*0.5 - `coefmat'[1, 2]) + 2)*(1/(`Nuniq'))*`invtotalsp'
			
			local detEsigma = `Esigma'[1, 1]*`Esigma'[2, 2]
			
			local detSigma = (1 - (`BVari'[2, 1]/sqrt(`BVari'[1, 1]*`BVari'[2, 2]))^2)*`BVari'[1, 1]*`BVari'[2, 2]
			
			local IsqE = sqrt(`detSigma')/(sqrt(`detEsigma') + sqrt(`detSigma'))
			
			local i2g = `IsqE'
			local i2se = (`BVari'[1, 1]/(`Esigma'[1, 1] + `BVari'[1, 1]))  //se
			local i2sp = (`BVari'[2, 2]/(`Esigma'[2, 2] + `BVari'[2, 2])) //sp
		}
		
		local nmc = 0
		if (`p' > 0  & "`mc'" == "") {
			forvalues j=1/2 {
				local S_9`j' = .
				local S_8`j' = .
				local S_89`j' = .
			}
			

			if "`interaction'" !="" {
				local confariates "`confounders'"
			}
			if "`interaction'" ==""  {
				if ("`design'" == "abnetwork" | "`design'" == "comparative") {
					tokenize `regressors'
					macro shift
					local confariates "`*'"
				}
				else {
					local confariates "`regressors'"
				}
				
			}
			local initialse 1
			local initialsp 1
			local rownamesmcse
			local rownamesmcsp
			
			if "`confariates'" != "" {
				di "*********************************** ************* ***************************************"
				di as txt "Just a moment - Fitting reduced models for comparisons"
			}
			foreach c of local confariates {
				if "`cveffect'" != "sp" {
					if "`interaction'" =="sesp" | "`interaction'" =="se" {
						local xterm = "`c'#`typevarx'.`varx'"
						local xnu = "`c'*`varx'"
					}
					else {
						local xterm = "`c'"
						local xnu = "`c'"
					}
					//Sensivitivity terms
					local nullse		
					foreach term of local seregexpression {
						if ("`term'" != "i.`xterm'#c.`se'")&("`term'" != "c.`xterm'#c.`se'")&("`term'" != "`xterm'#c.`se'") {
							local nullse "`nullse' `term'"
						} 
					}
					local nullnuse = subinstr("`nuse'", "+ `xnu'", "", 1)
					di as res _n "Ommitted : `xnu' in logit(se)"
					di as res "{phang} logit(se) = `nullnuse'{p_end}"
					di as res "{phang} logit(sp) = `nusp'{p_end}"
					
					local nullse = "`nullse' `spregexpression'"
					`echo' madamodel `event' `total' `se' `sp' `strataif',  bcov(`bcov') wcov(`wcov') modelopts(`modelopts') model(`model') ///
					regexpression(`nullse') sid(`studyid') `design' ipair(`ipair') level(`level') nested(`first')
					
					estimates store metadta_Nullse
					
					//LR test the model
					qui lrtest metadta_modest metadta_Nullse
					local selrp :di %10.`dp'f chi2tail(r(df), r(chi2))
					local selrchi2 = r(chi2)
					local selrdf = r(df)
					estimates drop metadta_Nullse
					
					if `initialse'  {
						mat `semci' = [`selrchi2', `selrdf', `selrp']
						local initialse 0
					}
					else {
						mat `semci' = [`selrchi2', `selrdf', `selrp'] \ `semci'
					}
					local rownamesmcse "`rownamesmcse' `xnu'"
				}
				if "`cveffect'" != "se" {
					if "`interaction'" =="sesp" | "`interaction'" =="sp" {
						local xterm = "`c'#`typevarx'.`varx'"
						local xnu = "`c'*`varx'"
					}
					else {
						local xterm = "`c'"
						local xnu = "`c'"
					}
					//Specificity terms
					local nullsp		
					foreach term of local spregexpression {
						if ("`term'" != "i.`xterm'#c.`sp'")&("`term'" != "c.`xterm'#c.`sp'")&("`term'" != "`xterm'#c.`sp'") {
							local nullsp "`nullsp' `term'"
						} 
					}
					
					local nullnusp = subinstr("`nusp'", "+ `xnu'", "", 1)
					di as res _n "Ommitted : `xnu' in logit(sp)"
					di as res "{phang} logit(se) = `nuse'{p_end}"
					di as res "{phang} logit(sp) = `nullnusp'{p_end}"
					
					local nullsp = "`seregexpression' `nullsp'" 
					`echo' madamodel `event' `total' `se' `sp' `strataif', bcov(`bcov') wcov(`wcov') modelopts(`modelopts') model(`model') ///
					regexpression(`nullsp') sid(`studyid') `design' ipair(`ipair') level(`level') nested(`first')
					estimates store metadta_Nullsp
					
					//LR test the model
					qui lrtest metadta_modest metadta_Nullsp
					local splrp :di %10.`dp'f chi2tail(r(df), r(chi2))
					local splrchi2 = r(chi2)
					local splrdf = r(df)
					estimates drop metadta_Nullsp
					
					if `initialsp' {
						mat `spmci' = [`splrchi2', `splrdf', `splrp']
						local initialsp 0
					}
					else {
						mat `spmci' = [`splrchi2', `splrdf', `splrp'] \ `spmci'
					}
					local rownamesmcsp "`rownamesmcsp' `xnu'"
				}
				local ++nmc
			}
			
			//Ultimate null model if more than one term
			if (`p' > 0) & (`nmc' > 1) {
				if "`cveffect'" != "sp" {
					local nullse `se'		
					local nullse = "`nullse' `spregexpression'"
					`echo' madamodel `event' `total' `se' `sp' `strataif',  bcov(`bcov') wcov(`wcov') modelopts(`modelopts') model(`model') regexpression(`nullse') ///
					sid(`studyid') `design' ipair(`ipair') level(`level') nested(`first')
					estimates store metadta_Nullse
					
					qui lrtest metadta_modest metadta_Nullse
					local selrp :di %10.`dp'f chi2tail(r(df), r(chi2))
					local selrchi2 = r(chi2)
					local selrdf = r(df)
					estimates drop metadta_Nullse
					
					if `initialse'  {
						mat `semci' = [`selrchi2', `selrdf', `selrp']
						local initialse 0
					}
					else {
						mat `semci' = `semci' \ [`selrchi2', `selrdf', `selrp']
					}
					local rownamesmcse "`rownamesmcse' All"
				}
				if "`cveffect'" != "se" {
					local nullsp `sp'
					local nullsp = "`seregexpression' `nullsp'"
					`echo' madamodel `event' `total' `se' `sp' `strataif',  bcov(`bcov') wcov(`wcov') modelopts(`modelopts') model(`model') regexpression(`nullsp') ///
					sid(`studyid') `design' ipair(`ipair') level(`level') nested(`first')
					estimates store metadta_Nullsp
					
					qui lrtest metadta_modest metadta_Nullsp
					local splrp :di %10.`dp'f chi2tail(r(df), r(chi2))
					local splrchi2 = r(chi2)
					local splrdf = r(df)
					estimates drop metadta_Nullsp
					
					if `initialsp' {
						mat `spmci' = [`splrchi2', `splrdf', `splrp']
						local initialsp 0
					}
					else {
						mat `spmci' = `spmci' \ [`splrchi2', `splrdf', `splrp']
					}
					local rownamesmcsp "`rownamesmcsp' All"
				}	
			}
			
			if "`cveffect'" != "sp" & `nmc' > 0 {
				mat roweq `semci' = Sensitivity
				mat rownames `semci' = `rownamesmcse'
				mat colnames `semci' =  chi2 df pval
			}

			if "`cveffect'" != "se" & `nmc' > 0 {
				mat roweq `spmci' = Specificity
				mat rownames `spmci' = `rownamesmcsp'
				mat colnames `spmci' = chi2 df pval
			}
		}
		if `nmc' == 0 {
			local mc "nomc"
		}
		
		mat `BVari' = (`tau2se', `i2se', `tau2sp', `i2sp', `tau2g', `i2g', `tausesp', `rho')
		mat colnames `BVari' = sensitivity:tausq sensitivity:isq specificity:tausq specificity:isq Generalized:tausq Generalized:isq covar rho 
		mat rownames `BVari' = Overall
		
		*mat `isq2i' = (`S_71', `S_7' \ `S_7', `S_72') //Isq
		*mat `Isq2i' = (`S_7' , `S_71', `S_72')
		*mat colnames `Isq2i' = Generalized logitse logitse
		*mat rownames `Isq2i' = Overall
		
		//model comparison
		*mat `mci' = (`S_81', `S_91',  `S_891', `S_82', `S_92' ,  `S_892' ) // Full vs Null 
		*mat colnames `mci' = sensitivity:Chi2 sensitivity:pval sensitivity:df specificity:Chi2 specificity:pval specificity:df
		*mat rownames `bgheti' = overall
		
		mat `refei' = (`S_2', `kcov', `S_3') // chisq re vs fe, df, pv re vs fe
		mat colnames `refei' = Chi2 df pval
		mat rownames `refei' = Overall
		
	
		if `Nobs' > 1 {		
			
			//LOG ODDS			
			estp `strataif', estimates(metadta_modest) sumstat(`loddslabel') depname(Effect) interaction(`interaction') cveffect(`cveffect') ///
				catreg(`catreg') contreg(`contreg') se(`se') level(`level') dp(`dp') varx(`varx') typevarx(`typevarx') ///
				by(`by') regexpression(`regexpression') `design'  `stratify'

			mat `Vi' = r(Vmatrix) //var-cov for catreg & overall 

			mat `logoddsi' = r(outmatrix)
			mat `selogoddsi' = r(outmatrixse)
			mat `splogoddsi' = r(outmatrixsp)
			
			if "`interaction'" == "" {
				//names of the V matrix
				local vnames
				local rnames :rownames `Vi'
				local nrowsv = rowsof(`Vi')
				forvalues r = 1(1)`nrowsv' {
				//Labels
					local rname`r':word `r' of `rnames'
					tokenize `rname`r'', parse("#")					
					
					local left = "`1'"
					local right = "`3'"
					
					tokenize `left', parse(.)
					local parm = substr("`1'", 1, 1)
					if `parm' == 0 {
						local eqlab "sp"
					}
					else {
						local eqlab "se"
					}
					
					if "`right'" == "" {
						local lab = "Overall"
					}
					else {
						tokenize `right', parse(.)
						local rightv = "`3'"
						local rightlabel = substr("`1'", 1, 1)
					
						local rlab:label `rightv' `rightlabel'
						local rlab = ustrregexra("`rlab'", " ", "-")
						local lab = "`rightv'_`rlab'"
					}
					
					local vnames = "`vnames' `eqlab':`lab'"	
				}
				mat rownames `Vi' = `vnames'
				mat colnames `Vi' = `vnames'
			}
				
			//ABS
			estp `strataif', estimates(metadta_modest) sumstat(`abslabel') depname(Effect) interaction(`interaction') cveffect(`cveffect') ///
				catreg(`catreg') contreg(`contreg')  se(`se') level(`level') expit power(`power') dp(`dp') varx(`varx') ///
				typevarx(`typevarx') by(`byvar') regexpression(`regexpression') `design' `stratify' 
		
			
			mat `absouti' = r(outmatrix)
			mat `absoutsei' = r(outmatrixse)
			mat `absoutspi' = r(outmatrixsp)
			
			//RR
			if `pcat' > 0 | "`typevarx'" == "i" {
				estr `strataif', estimates(metadta_modest) sumstat(`rrlabel') `comparative' cveffect(`cveffect') ///
				catreg(`catreg') se(`se') level(`level') power(`power') dp(`dp') varx(`varx') ///
				typevarx(`typevarx') by(`byvar') `stratify' regexpression(`regexpression') `design' ///
				baselevel(`basecode') refpos(`refpos')  comparator(`Comparator')
			
				mat `rrouti' = r(outmatrix)
				mat `serrouti' = r(outmatrixse)
				mat `sprrouti' = r(outmatrixsp)
				
				local inltest = r(inltest)

				if "`inltest'" == "yes" {
					mat `setestnli' = r(setestnl) //Equality of RR
					mat `sptestnli' = r(sptestnl) 
				}
			}
			else {
				local rr "norr"
			}
		}
		*if one study
		else { 
			mat `absouti' = J(2, 6, 0)
			mat `absoutsei' = J(1, 6, 0)
			mat `absoutspi' = J(1, 6, 0)
			
			mat `rrouti' = J(2, 6, 1)
			mat `serrouti' = J(1, 6, 1)
			mat `sprrouti' = J(1, 6, 1)
			
			mat `setestnli' = J(1, 3, .)
			mat `sptestnli' = J(1, 3, .)			
			
			mat `Vi' = J(2, 2, .) //var-cov for catreg & overall 
			mat `logoddsi' = J(2, 6, 0)
			mat `selogoddsi' = J(1, 6, 0)
			mat `splogoddsi'	= J(1, 6, 0)
			mat	`BVari' = J(1, 8, .)
			mat	`WVari' = J(1, 2, 0)
			if ((`p' > 0 & "`design'" != "abnetwork") | (`p' > 1 & "`design'" == "abnetwork")) & "`mc'" == "" {
				mat `semci'	= J(1, 3, .)
				mat `spmci'	= J(1, 3, .)
			}			
		}
		if "`stratify'" != "" {
			if ((`p' > 0 & "`design'" != "abnetwork") | (`p' > 1 & "`design'" == "abnetwork")) & "`mc'" == "" {
				mat roweq `semci' = Sensitivity
				mat roweq `spmci' = Specificity
				
				mat coleq `semci' = `by'
				mat coleq `spmci' = `by'
			}
		}
		
		*Stack the matrices
		if `i' == 1 {
			mat `absout' =	`absouti'	
			mat `absoutse' = `absoutsei'	
			mat `absoutsp' = `absoutspi'
			if "`rr'" == "" {
				mat `rrout' =	`rrouti'
				mat `serrout' = `serrouti'	
				mat `sprrout' = `sprrouti'
				
				if "`inltest'" == "yes" {
					mat `setestnl' = `setestnli' //Equality of RR
					mat `sptestnl' = `sptestnli' 
				}
			}
			mat `BVar' = `BVari'
			mat `WVar' = `WVari'
			mat `V' = `Vi' //var-cov for catreg & overall 
			mat `logodds' = `logoddsi'
			mat `selogodds' = `selogoddsi'
			mat `splogodds' = `splogoddsi'	
			*mat `bghet' = `bgheti'
			mat `refe' = `refei'
			*mat `Isq2' =  `Isq2i'
			if ((`p' > 0 & "`design'" != "abnetwork") | (`p' > 1 & "`design'" == "abnetwork")) & "`mc'" == "" {
				mat `semc'	= `semci'
				mat `spmc'	= `spmci'
			}
		}
		else {
			mat `absout' = `absout' \ `absouti'
			mat `absoutse' = `absoutse' \ `absoutsei'
			mat `absoutsp' =  `absoutsp' \ `absoutspi'
			if "`rr'" == "" {
				mat `rrout' = `rrout' \ `rrouti'
				mat `serrout' = `serrout' \ `serrouti'
				mat `sprrout' =  `sprrout' \ `sprrouti'
				
				if "`inltest'" == "yes" {
					mat `setestnl' = `setestnl' \ `setestnli' //Equality of RR
					mat `sptestnl' = `sptestnl' \ `sptestnli' 
				}
			}
			mat `BVar' = `BVar' \ `BVari'
			mat `WVar' = `WVar' \ `WVari'
			mat `V' = `V' \ `Vi' 
			mat `logodds' = `logodds' \ `logoddsi'
			mat `selogodds' = `selogodds' \ `selogoddsi'
			mat `splogodds' = `splogodds' \ `splogoddsi'
			if ((`p' > 0 & "`design'" != "abnetwork") | (`p' > 1 & "`design'" == "abnetwork")) & "`mc'" == "" {
				mat `semc'	= `semc' \ `semci'
				mat `spmc'	= `spmc' \ `semci'
			}
			*mat `bghet' =`bghet' \ `bgheti' 
			mat `refe' = `refe' \ `refei'
			*mat `Isq2' = `Isq2' \ `Isq2i'
		}
		local ++i
	}
	*Loop should end here
	
	//rownames for the matrix
	if "`stratify'" != "" & `i' > 1 {
		*mat rownames `hetout' = `byrownames'
		mat `serow' = J(1, 6, .)
		mat `sprow' = J(1, 6, .)
		
		mat rownames `serow' = "*--Sensitivity--*"
		mat rownames `sprow' = "*--Specificity--*" //19 characters
		
		if "`design'" != "comparative" {
			mat rownames `absoutse' = `byrownames'
			mat rownames `absoutsp' = `byrownames'
			mat rownames `selogodds' = `byrownames'
			mat rownames `splogodds' = `byrownames'
		}
		else {
			mat rownames `absoutse' = `bybirownames'
			mat rownames `absoutsp' = `bybirownames'
			mat rownames `selogodds' = `bybirownames'
			mat rownames `splogodds' = `bybirownames'
		}
		
		mat `absoutse' = `serow' \  `absoutse'
		mat `absoutsp' = `sprow' \  `absoutsp'
		mat `absout' = `absoutse' \ `absoutsp'
		
		mat colnames `absout' = Estimate SE(logit) z(logit) P>|z| Lower Upper
		mat colnames `absoutse' = Estimate SE(logit) z(logit) P>|z| Lower Upper
		mat colnames `absoutsp' = Estimate SE(logit) z(logit) P>|z| Lower Upper

			
		if "`rr'" == "" {
			mat `serrow' = J(1, 6, .)
			mat `sprrow' = J(1, 6, .)
			
			mat rownames `serrow' = "Relative Sensitivity"
			mat rownames `sprrow' = "Relative Specificity"  //20 chars
		
			mat rownames `serrout' = `byrownames'
			mat rownames `sprrout' = `byrownames'
			
			mat `serrout' = `serrow' \  `serrout'
			mat `sprrout' = `sprrow' \  `sprrout'
			mat `rrout' = `serrout' \ `sprrout'
			
			mat colnames `rrout' = Estimate SE(log) z(log) P>|z| Lower Upper
			mat colnames `serrout' = Estimate SE(log) z(log) P>|z| Lower Upper
			mat colnames `sprrout' = Estimate SE(log) z(log) P>|z| Lower Upper
		}
		
		mat rownames `BVar' = `byrownames'
		mat rownames `refe' = `byrownames'
		*mat coleq `spmc' = `byrownames'
		*mat coleq `semc' = `byrownames'
	}
	
	if "`rr'" == "" {
		if "`inltest'" == "yes" {
			mat `nltest' = `setestnl' \ `sptestnl'
		}
	}

	//CI
	if "`outplot'" == "rr" {
		if "`design'" == "comparative" {
			drop `sp'
			gettoken idpair confounders : regressors
			/*tokenize `regressors'
			macro shift
			local confounders `*'*/
			qui count
			local Nobs = `=r(N)'*0.25
			*cap assert mod(`Nobs', 2) == 0 /*Check if the number of studies is half*/
			if _rc != 0 {
				di as error "Some studies cannot be compared properly"
				exit _rc, STATA
			}
			
			sort `se' `regressors' `rid'
			egen `id' = seq(), f(1) t(`Nobs') b(1) 
			sort `id' `se' `varx'
			widesetup `event' `total' `confounders', idpair(`varx') se(`se') sid(`id') `design'
			gen `sp' = 1 - `se'
			local vlist = r(vlist)
			local cc0 = r(cc0)
			local cc1 = r(cc1)
				
			if "`refpos'" == "bottom" {	
				koopmanci `event'`=`indexcode'-1' `total'`=`indexcode'-1' `event'`=`basecode'-1' `total'`=`basecode'-1', rr(`es') upperci(`uci') lowerci(`lci') alpha(`=1 - `level'*0.01')
			}
			else {
				koopmanci `event'`=`basecode'-1' `total'`=`basecode'-1' `event'`=`indexcode'-1' `total'`=`indexcode'-1', rr(`es') upperci(`uci') lowerci(`lci') alpha(`=1 - `level'*0.01')
			}
			
			//Rename the varying columns
			foreach v of local vlist {
				rename `v'0 `v'_`cc0'
				label var `v'_`cc0' "`v'_`cc0'"
				rename `v'1 `v'_`cc1'
				label var `v'_`cc1' "`v'_`cc1'"
			}
			
			//make new lcols, rcols
			foreach v of local lcols {
				if strpos("`vlist'", "`v'") != 0 {
					local lcols_rr "`lcols_rr' `v'_`cc0' `v'_`cc1'"
				}
				else {
					local lcols_rr "`lcols_rr' `v'"
				}
			}
			local lcols "`lcols_rr'"
			
			//make new depvars
			local depvars_rr 
			
			foreach v of local depvars {
				if strpos("`vlist'", "`v'") != 0 {
					local depvars_rr "`depvars_rr' `v'_`cc0' `v'_`cc1'"
				}
				else {
					local depvars_rr "`depvars_rr' `v'"
				}
			}
			local depvars "`depvars_rr'"
			
			//make new indvars
			local indvars_rr 
			
			foreach v of local indvars {
				if strpos("`vlist'", "`v'") != 0 {
					local indvars_rr "`indvars_rr' `v'_`cc0' `v'_`cc1'"
				}
				else {
					local indvars_rr "`indvars_rr' `v'"
				}
			}
			local regressors "`indvars_rr'"
		}
		if "`design'" == "cbnetwork" {
			sort `rowid' `se' `rid'
			drop `sp' `rid'
			qui reshape wide `event' `total' `ipair' `assignment', i(`rowid' `se') j(`idpair')	
			
			koopmanci `event'1 `total'1 `event'0 `total'0, rr(`es') upperci(`uci') lowerci(`lci') alpha(`=1 - `level'*0.01')
			gen `id' = `rowid'
		}
		if "`design'" == "abnetwork" {
			gen `id' = _n
			qui gen `es' = .
			qui gen `lci' = .
			qui gen `uci' = .
		}
	}
	else {
		metadta_propci `total' `event', p(`es') lowerci(`lci') upperci(`uci') cimethod(`cimethod') level(`level')
		gen `id' = _n
	}
	forvalues l = 1(1)6 {
		local S_`l'1 = .
		local S_`l'2 = .
	}

	//===================================================================================
	//Prepare data for display
	gen `use' = 1  //Individual studies
	
	prep4show `id' `se' `use' `neolabel' `es' `lci' `uci', ///
		sortby(`sortby') groupvar(`groupvar') grptotal(`grptotal') 	///
		outplot(`outplot') serrout(`serrout') absoutse(`absoutse') absoutsp(`absoutsp') 	   	    ///
		sprrout(`sprrout') `subgroup' `summaryonly' `stratify' ///
		`overall' download(`download') indvars(`regressors') depvars(`depvars') `design'
		

	//Extra tables
	if ("`sumtable'" != "none") {
		di as res _n "****************************************************************************************"
	}
	//het
	if "`model'" == "random" & "`htable'" == "" {			
		printmat, matrixout(`BVar') type(bhet) dp(`dp') `design'  p(`p')
	}
	//re vs fe
	if "`model'" == "random" & "`htable'" == "" {			
		printmat, matrixout(`refe') type(refe) dp(`dp') `design' 
	}
	//logodds
	/*if  (("`sumtable'" == "all") |(strpos("`sumtable'", "logit") != 0)) {
		printmat, matrixout(`logodds') type(logit) dp(`dp') power(`power') `continuous' cveffect(`cveffect')
	}*/
	//abs
	if  (("`sumtable'" == "all") |(strpos("`sumtable'", "abs") != 0)) {
		printmat, matrixout(`absout') type(abs) dp(`dp') power(`power') `continuous' cveffect(`cveffect')
	}
	//rr
	if (("`sumtable'" == "all") |(strpos("`sumtable'", "rr") != 0)) & (`pcat' > 0 | "`typevarx'" == "i") {
	*if (("`sumtable'" == "all" & `pcat' > 0) | (strpos("`sumtable'", "rr") != 0)) & (("`catreg'" != " ") | ("`typevarx'" == "i"))   {
		//rr
		printmat, matrixout(`rrout') type(rr) dp(`dp') power(`power') cveffect(`cveffect')
		
		//rr equal
		if "`inltest'" == "yes" {
			printmat, matrixout(`nltest') type(rre) dp(`dp') cveffect(`cveffect')
		}		
	}	
	//model comparison
	if ((`p' > 0 & "`design'" != "abnetwork") | (`p' > 1 & "`design'" == "abnetwork")) & ("`mc'" =="") {
		printmat, matrixoutse(`semc') matrixoutsp(`spmc') type(mc) dp(`dp') cveffect(`cveffect')
	}
	//Display heterogeneity
	if "`model'" == "random" & "`htable'" == "" {
		*disphetab, `htable' dp(`dp') /*isq2(`Isq2')*/ bshet(`bshet')  bvar(`BVari') wvar(`WVari') p(`p')  
	}
	//Display the studies
	if "`itable'" == "" {
		disptab `id' `se' `use' `neolabel' `es' `lci' `uci' `grptotal', `itable' dp(`dp') power(`power') ///
			`subgroup' `overall' sumstatse(`sumstatse') sumstatsp(`sumstatsp')  	///
			isq2(`isq2') bghet(`bghet') bshet(`bshet') model(`model') bvar(`BVar') 	///
			catreg(`catreg') outplot(`outplot') interaction(`interaction') ///
			se_lrtest(`se_lrtest') sp_lrtest(`sp_lrtest') p(`p') `mc' `design'
	}
	
	//Draw the forestplot
	if "`fplot'" == "" {
		fplot `es' `lci' `uci' `use' `neolabel' `grptotal' `id' `se', ///	
			studyid(`studyid') power(`power') dp(`dp') level(`level') ///
			groupvar(`groupvar')  ///
			outplot(`outplot') lcols(`lcols') `foptions' `design' 
	}
	
	//Draw the SROC curve
	if "`outplot'" == "rr" {
		local sroc "nosroc"
	}
	if "`sroc'" == "" {		
		if "`groupvar'" == "" & `p' > 0  {
			di as res "NOTE: SROC presented for the overall mean."
		}
		use "`master'", clear
		sroc `varlist',  model(`model') selogodds(`selogodds') splogodds(`splogodds') v(`V') bvar(`BVar') ///
			groupvar(`groupvar') cimethod(`cimethod') level(`level') p(`p') `soptions' `stratify'
	}
	
	cap ereturn clear
	if ((`p' > 0 & "`design'" != "abnetwork") |(`p' > 1 & "`design'" == "abnetwork")) & "`mc'" == "" {
		ereturn matrix mctestse = `semc' //model comparison se
		ereturn matrix mctestsp = `spmc' //model comparison se
		*ereturn matrix bghet = `bghet' //Full vs Null model
	}
	/*if `p' == 0 & "`cbnetwork'" == "" {
		ereturn matrix isq2 = `isq2' //isq2
	}*/
	/*if "`inltest'" == "yes" {
		ereturn matrix setestnl = `setestnl' //Equality of RR - se
		ereturn matrix sptestnl = `sptestnl'
	}*/	
	cap confirm matrix `logodds'
	if _rc == 0 {
		ereturn matrix logodds = `logodds' //logodds se and sp
		ereturn matrix Vlogodds = `V' //var-cov for catreg & overall 
	}
	cap confirm matrix `absout'
	if _rc == 0 {
		ereturn matrix absout = `absout'
		ereturn matrix absoutse = `absoutse'
		ereturn matrix absoutsp = `absoutsp'
	}
	cap confirm matrix `rrout'
	if _rc == 0 {
		ereturn matrix rrout = `rrout'
		ereturn matrix serrout = `serrout'
		ereturn matrix sprrout = `sprrout'
	}	

	ereturn matrix refe = `refe' //Re vs FE 
	ereturn matrix vcovar = `BVar' //var-covar between logit se and logit sp
	if "`abnetwork'" != "" {
		ereturn matrix wvar = `WVar' //2nd variance
	}
	
	restore 
end

/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: INDEX +++++++++++++++++++++++++
							Find index of word in a string
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

cap program drop index
program define index, rclass
version 14.0

	syntax, source(string asis) word(string asis)
	local nwords: word count `source'
	local found 0
	local index 1

	while (!`found') & (`index' <= `nwords'){
		local iword:word `index' of `source'
		if "`iword'" == `word' {
			local found 1
		}
		local index = `index' + 1
	}
	
	if `found' {
		local index = `index' - 1
	}
	else{
		local index = 0
	}
	return local index `index'
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
/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: MADAMODEL +++++++++++++++++++
							Fit the logistic model
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
cap program drop madamodel
program define madamodel
version 14.0

	syntax varlist [if], [ bcov(string) wcov(string) model(string) modelopts(string asis) regexpression(string) sid(varname) ///
		nested(varname) comparative ipair(varname) level(integer 95) abnetwork cbnetwork independent comparative]
		tokenize `varlist'	
		
		marksample touse, strok
		
		if "`abnetwork'`cbnetwork'" != "" & "`wcov'" != "" {
			local nested = `"|| (`nested'`ipair': `3' `4', noc cov(`wcov'))"'
		}
		else {
			local nested
		}
		
		if ("`bcov'" == "se") | ("`bcov'" == "sp"){
			if ("`bcov'" == "se") {
				local re = "`3'"
			}
			else {
				local re = "`4'"
			}
			local cov
		}
		else {
			local re = "`3' `4'"
			local cov = "cov(`bcov')"
		}
		
	
		if ("`model'" == "fixed") {
			capture noisily binreg `1' `regexpression' if `touse', noconstant n(`2') ml `modelopts' l(`level')
			local success = _rc
		}
		if ("`model'" == "random") {		
			if strpos(`"`modelopts'"', "(iterate") == 0  {
				local modelopts = `"iterate(30) `modelopts'"'
			}
			if strpos(`"`modelopts'"', "intpoi") == 0  {
				qui count if `touse'
				if `=r(N)' < 7 {
					local modelopts = `"intpoints(`=r(N)') `modelopts'"'
				}
			}
			
			//First trial
			#delim ;
			capture noisily meqrlogit (`1' `regexpression' if `touse', noc )|| 
			  (`sid': `re', noc `cov') `nested',
			  binomial(`2') `modelopts' l(`level');
			#delimit cr 
			
			local success = _rc
			local converged = e(converged)
			local try = 1
			//Try to refineopts 2 times
			if strpos(`"`modelopts'"', "refineopts") == 0 {				
				if (`try' < 4) & ((`converged' == 0) | (`success' != 0)) {
					local ++try 
					local refine "refineopts(iterate(`=10 * `try''))"
					#delim ;					
					capture noisily meqrlogit (`1' `regexpression' if `touse', noc )|| 	
							(`sid': `re', noc `cov') `nested',						
							binomial(`2') `modelopts' l(`level') `refine' ;
					#delimit cr 
					
					local success = _rc
					
					local converged = e(converged) 
				}
			}
			if strpos(`"`modelopts'"', "refineopts") == 0 {				
				if (`try' < 4) & ((`converged' == 0) | (`success' != 0)) {
					local ++try 
					local refine "refineopts(iterate(`=10 * `try''))"
					#delim ;					
					capture noisily meqrlogit (`1' `regexpression' if `touse', noc )|| 	
							(`sid': `re', noc `cov') `nested',						
							binomial(`2') `modelopts' l(`level') `refine' ;
					#delimit cr 
					
					local success = _rc
					
					local converged = e(converged) 
				}
			}
			*Try matlog if still difficult
			if (strpos(`"`modelopts'"', "matlog") == 0) & ((`converged' == 0) | (`success' != 0)) {
				local ++try 
				#delim ;
				capture noisily meqrlogit (`1' `regexpression' if `touse', noc )|| 
					(`sid': `re', noc `cov') `nested',
					binomial(`2') `modelopts' l(`level') `refine' matlog;
				#delimit cr
				
				local success = _rc				
				local converged = e(converged)
			}
		}
		if `success' != 0 {
			*display as error "Unexpected error performing regression"
			di as err "Model could not converge after `try' attempts with different options. Try fitting a simpler model"
            exit `success'
		}
end
	/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: metadta_PROPCI +++++++++++++++++++++++++
								CI for proportions
	++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	cap program drop metadta_propci
	program define metadta_propci
	version 14.1

		syntax varlist [if] [in], p(name) lowerci(name) upperci(name) [cimethod(string) level(real 95)]
		
		qui {	
			tokenize `varlist'
			gen `p' = .
			gen `lowerci' = .
			gen `upperci' = .
			
			count `if' `in'
			forvalues i = 1/`r(N)' {
				local N = `1'[`i']
				local n = `2'[`i']

				cii proportions `N' `n', `cimethod' level(`level')
				
				replace `p' = r(proportion) in `i'
				replace `lowerci' = r(lb) in `i'
				replace `upperci' = r(ub) in `i'
			}
		}
	end
/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: WIDESETUP +++++++++++++++++++++++++
							Transform data to wide format
	+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	cap program drop widesetup
	program define widesetup, rclass
	version 14.1

	syntax varlist, [sid(varlist) idpair(varname) se(varname) comparative sortby(varlist) cbnetwork rowid(varname) index(varname) assignment(varname) comparator(varname) ]

		qui{
			tokenize `varlist'
			local event = "`1'"
			local total = "`2'"

			tempvar jvar modey diffy
		
			if "`cbnetwork'" == "" {
				gen `jvar' = `idpair' - 1
				
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
						if "`se'" != "" & "`v'" == "`se'"{
							local v
						}
						local vlist "`vlist' `v'"
					}
				}
				cap drop `modey' `diffy'
				
				sort `sid' `jvar' `sortby'
				
				/*2 variables per study : n N*/			
				reshape wide `event' `total'  `idpair' `vlist', i(`sid' `se') j(`jvar')
			}
			if "`cbnetwork'" != "" { 
				reshape wide `varlist', i(`sid') j(`se')
				
				drop `sid'
				
				reshape wide `event'0 `total'0 `event'1 `total'1 `index' `assignment', i(`rowid') j(`comparator')
			
			}
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
version 14.0

	#delimit ;
	syntax varlist, [serrout(name) sprrout(name) absoutse(name) absoutsp(name) sortby(varlist) 
		groupvar(varname) summaryonly nooverall nosubgroup outplot(string) grptotal(name) download(string asis) 
		indvars(varlist) depvars(varlist) comparative abnetwork independent cbnetwork stratify ] 
	;
	#delimit cr
	tempvar sp  expand 
	tokenize `varlist'
	 
	local id = "`1'"
	local se = "`2'" 
	local use = "`3'"
	local label = "`4'"
	local es = "`5'"
	local lci = "`6'"
	local uci = "`7'"
	qui {
		gen `sp' = 1 - `se'

		gen `expand' = 1

		//Groups
		if "`groupvar'" != "" {
			bys `groupvar' `se' : egen `grptotal' = count(`id') //# studies in each group
			gsort `groupvar' `se' `sortby' `id'
			bys `groupvar' `se' : replace `expand' = 1 + 1*(_n==1) + 2*(_n==_N)
			expand `expand'
			gsort `groupvar' `se' `sortby' `id' `expand'
			bys `groupvar' `se' : replace `use' = -2 if _n==1  //group label
			bys `groupvar' `se' : replace `use' = 2 if _n==_N-1  //subgroup
			bys `groupvar' `se' : replace `use' = 0 if _n==_N //blank
			replace `id' = `id' + 1 if `use' == 1
			replace `id' = `id' + 2 if `use' == 2  //subgroup
			replace `id' = `id' + 3 if `use' == 0 //blank
			replace `label' = "Summary" if `use' == 2
			
			qui label list `groupvar'
			local nlevels = r(max)
			local c = 0
			local m = 1
			
			forvalues l = 1/`nlevels' {
				if "`outplot'" == "abs" {
					if ("`stratify'" !="") {
						local c = 1
						if ("`comparative'" !="") {
							local m = 3
						}
					}
					
					local S_112 = `absoutse'[`=`l'*`m' + `c'', 1]
					local S_122 = `absoutsp'[`=`l'*`m' + `c'', 1]
					
					local S_312 = `absoutse'[`=`l'*`m' + `c'', 5]
					local S_322 = `absoutsp'[`=`l'*`m' + `c'', 5]
					
					local S_412 = `absoutse'[`=`l'*`m' + `c'', 6]
					local S_422 = `absoutsp'[`=`l'*`m' + `c'', 6]
				}
				else {
					if ("`abnetwork'" !="") | ("`stratify'" !="")  {
						local c = 1
					}
					local S_112 = `serrout'[`=`l' + `c'', 1]
					local S_122 = `sprrout'[`=`l' + `c'', 1]
					
					local S_312 = `serrout'[`=`l' + `c'', 5]
					local S_322 = `sprrout'[`=`l' + `c'', 5]
					
					local S_412 = `serrout'[`=`l' + `c'', 6]
					local S_422 = `sprrout'[`=`l' + `c'', 6]
				}
				local lab:label `groupvar' `l'
				replace `label'  = "`lab'" if `use' == -2 & `groupvar' == `l'	
				replace `label' = "`lab'" if `use' == 2 & `groupvar' == `l'	& "`outplot'" == "rr" & "`abnetwork'" != ""
				replace `es' = `S_112'*`se' + `S_122'*`sp' if `use' == 2 & `groupvar' == `l'	
				replace `lci' = `S_312'*`se' + `S_322'*`sp' if `use' == 2 & `groupvar' == `l'	
				replace `uci' = `S_412'*`se' + `S_422'*`sp' if `use' == 2 & `groupvar' == `l'	
			}
		}
		else {
			bys `se' : egen `grptotal' = count(`id') //# studies total
		}
		
		//Overall
		//Overall
		if "`overall'" == "" {	
			gsort  `se' `groupvar' `sortby' `id'
			bys `se' : replace `expand' = 1 + 2*(_n==_N)
			expand `expand'
			gsort  `se' `groupvar' `sortby' `id' `expand'
			bys `se' : replace `use' = 3 if _n==_N-1  //Overall
			bys `se' : replace `use' = 0 if _n==_N //blank
			bys `se' : replace `id' = `id' + 1 if _n==_N-1  //Overall
			bys `se' : replace `id' = `id' + 2 if _n==_N //blank
			//Fill in the right info
			if "`outplot'" == "abs" {
				local senrows = rowsof(`absoutse')
				local spnrows = rowsof(`absoutsp')
				local S_11 = `absoutse'[`senrows', 1] //p (se)
				local S_31 = `absoutse'[`senrows', 5] //ll
				local S_41 = `absoutse'[`senrows', 6] //ul
				
				local S_12 = `absoutsp'[`spnrows', 1] //p (sp)
				local S_32 = `absoutsp'[`spnrows', 5] //ll
				local S_42 = `absoutsp'[`spnrows', 6] //ul
				}
			else {
				local senrows = rowsof(`serrout')
				local spnrows = rowsof(`sprrout')
				local S_11 = `serrout'[`senrows', 1] //p (se)
				local S_31 = `serrout'[`senrows', 5] //ll
				local S_41 = `serrout'[`senrows', 6] //ul
				
				local S_12 = `sprrout'[`spnrows', 1] //p (sp)
				local S_32 = `sprrout'[`spnrows', 5] //ll
				local S_42 = `sprrout'[`spnrows', 6] //ul
			}
			
			replace `es' = `S_11'*`se' + `S_12'*`sp' if `use' == 3	
			replace `lci' = `S_31'*`se' + `S_32'*`sp' if `use' == 3
			replace `uci' = `S_41'*`se' + `S_42'*`sp' if `use' == 3
			replace `label' = "Overall" if `use' == 3
		}
		
		count if `use'==1 & `se'==1
		replace `grptotal' = `=r(N)' if `use'==3
		replace `grptotal' = `=r(N)' if _n==_N
		
		replace `label' = "" if `use' == 0
		replace `es' = . if `use' == 0 | `use' == -2
		replace `lci' = . if `use' == 0 | `use' == -2
		replace `uci' = . if `use' == 0 | `use' == -2
		
		gsort `se' `groupvar' `sortby'  `id' 
	}
	
	if "`download'" != "" {
		preserve
		qui {
			cap drop _ES _LCI _UCI _USE _LABEL _PARAMETER
			gen _ES = `es'
			gen _LCI = `lci'
			gen _UCI = `uci'
			gen _USE = `use'
			gen _LABEL = `label'
			gen _PARAMETER = `se'
			gen _ID = `id'
			
			keep `depvars' `indvars' _ES _LCI _UCI _ESAMPLE _USE _LABEL _PARAMETER _ID
		}
		di _n "Data saved"
		noi save "`download'", replace
		
		restore
	}
	qui {
		//Drop unnecessary rows
		if "`abnetwork'" == "" | ("`abnetwork'" != "" & "`outplot'" != "rr") {
			drop if (`use' == 2 | `use' == 3 ) & (`grptotal' == 1) //drop summary if 1 study
		}		
		drop if (`use' == 1 & "`summaryonly'" != "" & `grptotal' > 1) 
		
		//remove label if summary only
		replace `label' = `label'[_n-1] if (`use' == 2 & "`summaryonly'" != "") 
		
		//Drop unnecessary rows
		drop if (`use' == 2 & "`subgroup'" != "") 
		drop if (`use' == -2 & "`summaryonly'" != "") 
		drop if (`use' == 3 & "`overall'" != "") 
		
		if "`abnetwork'" != "" & "`outplot'" == "rr" {
			drop if `use' == 1 | `use' == -2
			replace `use' = 1 if `use' == 2
		}
		
		gsort `se' `groupvar' `sortby'  `id' 
		bys `se' : replace `id' = _n 
		gsort `id' `se' 
	}
end	

/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: DISPHETAB +++++++++++++++++++++++++
							Display table 
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
cap program drop disphetab
program define disphetab
version 14.0
#delimit ;
syntax [, isq2(name) bshet(name) dp(integer 2) bvar(name) wvar(name)  p(integer 0)] ;
	#delimit cr
	
	local rho 		= `bvar'[1, 2]/sqrt(`bvar'[1, 1]*`bvar'[2, 2])
	local tau2se 	= `bvar'[1, 1]
	local tau2sp	= `bvar'[2, 2]
	local tau2g		= (1 - (`bvar'[1, 2]/sqrt(`bvar'[1, 1]*`bvar'[2, 2]))^2)*`bvar'[1, 1]*`bvar'[2, 2]
	di as txt "Between-study heterogeneity" 
	di as txt _col(28) "covar" _cont
	di as res _n _col(28) %5.`=`dp''f `covar' 
	
	di as txt _col(28) "rho" _cont
	di as res _n _col(28) %5.`=`dp''f `rho' 
	
	di as txt  _col(28) "Tau.sq" _cont
	if `p' == 0  {
		di as txt _col(45) "I^2(%)" _cont
		local isq2b  = `isq2'[1, 1]*100
		local isq2se = `isq2'[1, 2]*100
		local isq2sp = `isq2'[1, 3]*100
	}			
	di as txt _n  "Generalized" _cont	
	di as res   _col(28) %5.`=`dp''f `tau2g' _col(45) %5.`=`dp''f `isq2b'  
	di as txt  "Sensitivity" _cont	
	di as res    _col(28) %5.`=`dp''f `tau2se' _col(45) %5.`=`dp''f `isq2se'  
	di as txt  "Specificity" _cont
	di as res    _col(28) %5.`=`dp''f `tau2sp' _col(45) %5.`=`dp''f `isq2sp'

	di as txt  _col(30) "Chi2"  _skip(8) "degrees of" _cont
	di as txt _n  _col(28) "statistic" 	_skip(6) "freedom"      _skip(8)"p-val"   _cont
	
	local chisq = `bshet'[1, 1]
	local df 	= `bshet'[1, 2]
	local pv 	= `bshet'[1, 3]	
			
	di as txt _n "LR Test: RE vs FE model" _cont
	di as res _col(25) %10.`=`dp''f `chisq' _col(45) `df' _col(52) %10.4f `pv'  
	
end
/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: DISPTAB +++++++++++++++++++++++++
							Display table 
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
cap program drop disptab
program define disptab
version 14.0
	#delimit ;
	syntax varlist, [nosubgroup nooverall level(integer 95) sumstatse(string asis) 
	sumstatsp(string asis) noitable dp(integer 2) power(integer 0) isq2(name) 
	bghet(name) bshet(name) model(string) bvar(name) catreg(string) outplot(string) 
	interaction(string) se_lrtest(name) sp_lrtest(name) p(integer 0) noMC independent cbnetwork comparative abnetwork]
	;
	#delimit cr
	
	tempvar id se use label es lci uci df
	tokenize `varlist'
	qui gen `id' = `1'
	qui gen `se' = `2' 
	qui gen `use' = `3'
	qui gen `label' = `4'
	qui gen `es' = `5'
	qui gen `lci' = `6'
	qui gen `uci' = `7'
	qui gen `df' = 8
	
	if "`outplot'" == "abs" {
		local sumstat "Absolute Measures"
	}
	else {
		local sumstat "Relative Measures"
	}
	preserve
	
		tempvar tlabellen 
		//study label
		local studylb: variable label `label'
		if "`studylb'" == "" {
			local studylb "Study"
		}		
		qui replace `se' = `se' + 1
		qui widesetup `label', sid(`id') idpair(`se')
		
		qui gen `tlabellen' = strlen(`label'0)
		qui summ `tlabellen'
		local nlen = r(max) + 5 
		local nlense = strlen("`sumstatse'")
		local nlensp = strlen("`sumstatsp'")
		di as res  "****************************************************************************************"
		di as res "{pmore2} Study specific test accuracy: `sumstat'  {p_end}"
		di as res    "****************************************************************************************" 
		
		di _n as txt _col(`nlen') "| "   _skip(`=22 - round(`nlense'/2)') "`sumstatse'" ///
				  _skip(`=44 - (22 - round(`nlense'/2)) - `nlense' - 1')	"| " _skip(`=22 - round(`nlensp'/2)') "`sumstatsp'" _cont
				  
		di  _n  as txt _col(2) "`studylb'" _col(`nlen') "| "   _skip(5) "Estimate" ///
				  _skip(5) "[`level'% Conf. Interval]"  ///
				  _skip(5)	"| " _skip(5) "Estimate" ///
				  _skip(5) "[`level'% Conf. Interval]" 
				  
		di  _dup(`=`nlen'-1') "-" "+" _dup(44) "-" "+" _dup(44) "-"
		qui count
		local N = r(N)
		
		forvalues i = 1(1)`N' {
			//Group labels
			if ((`use'[`i']== -2)){ 
				di _col(2) as txt `label'0[`i'] _col(`nlen') "|  " _col(`=`nlen' + 45') "|  "
			}
			//Studies -- se
			if ((`use'[`i'] ==1)) { 
				di _col(2) as txt `label'1[`i'] _col(`nlen') "|  "  ///
				_skip(5) as res  %5.`=`dp''f  `es'1[`i']*(10^`power') /// 
				_col(`=`nlen' + 20') %5.`=`dp''f `lci'1[`i']*(10^`power') ///
				_skip(5) %5.`=`dp''f `uci'1[`i']*(10^`power')  _cont
			}
			//studies - sp
			if (`use'[`i'] ==1 )   { 
				di as txt _col(`=`nlen' + 45') "|  "  ///
				_skip(5) as res  %5.`=`dp''f  `es'0[`i']*(10^`power') /// 
				_col(`=`nlen' + 66') %5.`=`dp''f `lci'0[`i']*(10^`power') ///
				_skip(5) %5.`=`dp''f `uci'0[`i']*(10^`power')  
			}
			//Summaries
			if ( (`use'[`i']== 3) | ((`use'[`i']== 2) & (`df'[`i'] > 1))){
				if ((`use'[`i']== 2) & (`df'[`i'] > 1)) {
					di _col(2) as txt _col(`nlen') "|  " _col(`=`nlen' + 45') "|  "
				}		
				di _col(2) as txt `label'0[`i'] _col(`nlen') "|  "  ///
				_skip(5) as res  %5.`=`dp''f  `es'1[`i']*(10^`power') /// 
				_col(`=`nlen' + 20') %5.`=`dp''f `lci'1[`i']*(10^`power') ///
				_skip(5) %5.`=`dp''f `uci'1[`i']*(10^`power') ///
				as txt _col(`=`nlen' + 45') "|  " ///
				_skip(5) as res  %5.`=`dp''f  `es'0[`i']*(10^`power') /// 
				_col(`=`nlen' + 66') %5.`=`dp''f `lci'0[`i']*(10^`power') ///
				_skip(5) %5.`=`dp''f `uci'0[`i']*(10^`power') 
			}
			//Blanks
			if (`use'[`i'] == 0 ){
				di as txt _dup(`=`nlen'-1') "-" "+" _dup(44) "-" "+" _dup(44) "-"		
				di as txt _col(`nlen') "|  " _col(`=`nlen' + 45') "|  "
			}
		}
	
	/*if (`p' > 0 ) {
		if (`p' > 0) & ("`mc'" =="") {
			local S_81 = `bghet'[1, 1] //chi
			local S_91 = `bghet'[1, 2] //p
			local S_891 = `bghet'[1, 3] //df
			local S_82= `bghet'[2, 1] //chi
			local S_92 = `bghet'[2, 2] //p
			local S_892 = `bghet'[2, 3] //df
			if (`p' > 0) {
			
			di as txt _n  "LR Test: Full Model vs Intercept-only Model" _n   
			
			di as txt  _col(30) "Chi2"  _skip(8) "degrees of" _cont
			di as txt _n  _col(28) "statistic" 	_skip(6) "freedom"      _skip(8)"p-val"   _cont
			
			di as txt _n "Sensitivity " _cont
			di as res  _col(25) %10.`=`dp''f `S_81' _col(45) `S_891' _col(52) %10.4f `S_91'   _cont
			di as txt _n "Specificity" _cont
			di as res  _col(25) %10.`=`dp''f `S_82' _col(45) `S_892' _col(52) %10.4f `S_92'  
			}	

			mat colnames `testmat2print' = chi2 df p
		}			
	}*/

	restore
end
/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: PRINTMAT +++++++++++++++++++++++++
							Print the outplot matrix beautifully
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
cap program drop printmat
program define printmat
	version 13.1
	syntax, type(string) [cveffect(string) matrixout(name) matrixoutse(name) ///
			matrixoutsp(name) sumstat(string) dp(integer 2) p(integer 0) power(integer 0) ///
			matched cbnetwork abnetwork independent comparative continuous ]
		
		local rownamesmaxlen = 10		
		if ("`type'" != "mc") {
			local nrows = rowsof(`matrixout')
			local ncols = colsof(`matrixout')
			local rnames : rownames `matrixout'
			
			forvalues r = 1(1)`nrows' {
				local rname : word `r' of `rnames'
				local nlen : strlen local rname
				local rownamesmaxlen = max(`rownamesmaxlen', min(`nlen', 32)) //Check if there is a longer name
			}
		}
			
		if ("`type'" == "abs") {	
			if `nrows' > 4 {
				if "`cveffect'" == "sesp" {
					local rspec "---`="&"*`=`nrows'/2 - 2''--`="&"*`=`nrows'/2 - 2''-"
				}
				else if "`cveffect'" == "se" {
					local rspec "---`="&"*`=`nrows'-4''---"
				}
				else if "`cveffect'" == "sp" {
					local rspec "-----`="&"*`=`nrows'-4''-"
				}
			}
			else {
				local rspec "----"
			}
		}
		if ("`type'" == "rr") {
		local rownamesmaxlen = 20
			if `nrows' > 4 {
				if "`cveffect'" == "sesp" {
				 local rspec "---`="&"*`=`nrows'/2 - 2''--`="&"*`=`nrows'/2 - 2''-"
				 
				}
				else if "`cveffect'" == "se" {
					local rspec "---`="&"*`=`nrows'-4''---"
				}
				else if "`cveffect'" == "sp" {
					local rspec "-----`="&"*`=`nrows'-4''-"
				}
			}
			else {
				local rspec "--&-&-"
			}
			
		}
				
		local nlensstat : strlen local sumstat
		local nlensstat = max(10, `nlensstat')
		
		if "`type'" == "rre" {
			local rownamesmaxlen = max(`rownamesmaxlen', 20) //Check if there is a longer name
			local rspec "--`="&"*`=`nrows'-1''-"
			di as res _n "****************************************************************************************"
			di as txt _n "Wald-type test for nonlinear hypothesis"
			di as txt _n "{phang}H0: All (log)RR equal vs. H1: Some (log)RR different {p_end}"

			#delimit ;
			noi matlist `matrixout', rowtitle(Effect) 
						cspec(& %`rownamesmaxlen's |  %8.`=`dp''f &  %8.0f &  %8.4f o2&) 
						rspec(`rspec') underscore nodotz
			;
			#delimit cr			
		}
		if ("`type'" == "logit") | ("`type'" == "abs") | ("`type'" == "rr")  {
			di as res _n "****************************************************************************************"
			if ("`type'" == "logit") { 
				di as res "{pmore2} Marginal summary measures of test accuracy: Log odds {p_end}"
			}
			if ("`type'" == "abs") { 
				di as res "{pmore2} Marginal summary measures of test accuracy: Absolute measures {p_end}"
			}
			if ("`type'" == "rr") {
				di as res "{pmore2} Marginal summary measures of test accuracy: Relative measures {p_end}"
			}
			di as res    "****************************************************************************************" 
			*tempname mat2print
			*mat `mat2print' = `matrixout'
			local nrows = rowsof(`matrixout')
			forvalues r = 1(1)`nrows' {
				mat `matrixout'[`r', 1] = `matrixout'[`r', 1]*10^`power'
				mat `matrixout'[`r', 5] = `matrixout'[`r', 5]*10^`power'
				mat `matrixout'[`r', 6] = `matrixout'[`r', 6]*10^`power'
						
				forvalues c = 1(1)6 {
					local cell = `matrixout'[`r', `c'] 
					if "`cell'" == "." {
						mat `matrixout'[`r', `c'] == .z
					}
				}
			}
			
			#delimit ;
			noi matlist `matrixout', rowtitle(Effect) 
						cspec(& %`rownamesmaxlen's |  %`nlensstat'.`=`dp''f &  %9.`=`dp''f &  %8.`=`dp''f &  %15.`=`dp''f &  %8.`=`dp''f &  %8.`=`dp''f o2&) 
						rspec(`rspec') underscore  nodotz
			;
			#delimit cr
		}
		if ("`type'" == "bhet") {
				di as res _n "****************************************************************************************"
				di as txt _n "Between-study heterogeneity statistics"
				
			if `nrows' > 1 {
				local rspec "-`="&"*`nrows''-"
		
				*tempname mat2print
				*mat `mat2print' = `matrixout'
				forvalues r = 1(1)`nrows' {
					forvalues c = 1(1)`ncols' {
						local cell = `matrixout'[`r', `c'] 
						if "`cell'" == "." {
							mat `matrixout'[`r', `c'] == .z
						}
					}
				}
					
				#delimit ;
				noi matlist `matrixout', 
							cspec(& %`rownamesmaxlen's |  %13.`=`dp''f `="&  %13.`=`dp''f "*`=`ncols'-1'' o2&) 
							rspec(`rspec') underscore nodotz
				;
				#delimit cr	
			}
			else {			
				local rho 		= `matrixout'[1, 8]
				local covar 	= `matrixout'[1, 7]
				local tau2se 	= `matrixout'[1, 1]
				local tau2sp	= `matrixout'[1, 3]
				local tau2g		= `matrixout'[1, 5]
				
				di as txt _col(28) "covar"  _col(45) "rho"_cont
				di as res _n _col(28) %5.`=`dp''f `covar' _col(45) %5.`=`dp''f `rho' 
				
				di as txt  _col(28) "Tau.sq" _cont
				di as txt _col(45) "I^2(%)" _cont
				if `p' == 0  {					
					local isq2g  = `matrixout'[1, 6]*100
					local isq2se = `matrixout'[1, 2]*100
					local isq2sp = `matrixout'[1, 4]*100
				}
				else {
					local isq2g  = `matrixout'[1, 6]
					local isq2se = `matrixout'[1, 2]
					local isq2sp = `matrixout'[1, 4]
				}
				di as txt _n  "Generalized" _cont	
				di as res   _col(28) %5.`=`dp''f `tau2g' _col(45) %5.`=`dp''f `isq2g'  
				di as txt  "Sensitivity" _cont	
				di as res    _col(28) %5.`=`dp''f `tau2se' _col(45) %5.`=`dp''f `isq2se'  
				di as txt  "Specificity" _cont
				di as res    _col(28) %5.`=`dp''f `tau2sp' _col(45) %5.`=`dp''f `isq2sp'
			}
		}
		if ("`type'" == "mc") {
			cap confirm matrix `matrixoutse'
			local semat = _rc
			
			cap confirm matrix `matrixoutsp'
			local spmat = _rc
	
			tempname matrixout
			if (`=`semat' + `spmat'') == 0 {
				mat `matrixout' = `matrixoutse' \ `matrixoutsp' 
				local nrowse = rowsof(`matrixoutse')
				local nrowsp = rowsof(`matrixoutsp')
				local rspec "--`="&"*`=`nrowse'-1''-`="&"*`=`nrowsp'-1''-"
			}
			else if `semat' == 0 {
				mat `matrixout' = `matrixoutse' 
				local nrowse = rowsof(`matrixoutse')
				local rspec "--`="&"*`=`nrowse'-1''-"
			}
			else {
				mat `matrixout' = `matrixoutsp' 
				local nrowsp = rowsof(`matrixoutsp')
				local rspec "--`="&"*`=`nrowsp'-1''-"
			}
			
			local ncols = colsof(`matrixout')
			local nrows = rowsof(`matrixout')
			local rnames : rownames `matrixout'
			
			local rownamesmaxlen = 15
			forvalues r = 1(1)`nrows' {
				local rname : word `r' of `rnames'
				local nlen : strlen local rname
				local rownamesmaxlen = max(`rownamesmaxlen', min(`nlen', 32)) //Check if there is a longer name
			}
			
			di as res _n "****************************************************************************************"
			di as txt _n "Model comparison(s): Leave-one/all-out LR Test(s)"
			#delimit ;
			noi matlist `matrixout', rowtitle(Excluded Effect(s)) 
				cspec(& %`=`rownamesmaxlen' + 2's |  %8.`=`dp''f  `="&  %8.`=`dp''f "*`=`ncols'-1'' o2&) 
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
		if ("`type'" == "refe") {
			di as txt _n "LR Test: RE vs FE model" 
			if `nrows' > 1 {
				local rspec "--`="&"*`=`nrows'-1''-"
				*tempname mat2print
				*mat `mat2print' = `matrixout'
				forvalues r = 1(1)`nrows' {
					forvalues c = 1(1)`ncols' {
						local cell = `matrixout'[`r', `c'] 
						if "`cell'" == "." {
							mat `matrixout'[`r', `c'] == .z
						}
					}
				}
					
				#delimit ;
				noi matlist `matrixout', 
							cspec(& %`rownamesmaxlen's |  %8.0f `="&  %10.`=`dp''f "*`=`ncols'-1'' o2&) 
							rspec(`rspec') underscore nodotz
				;
				#delimit cr	
			}
			else {
				local chisq = `matrixout'[1, 1]
				local df 	= `matrixout'[1, 2]
				local pv 	= `matrixout'[1, 3]
				
				di as txt  _col(10) "Chi2"  _skip(8) "degrees of" _cont
				di as txt _n  _col(8) "statistic" 	_skip(6) "freedom"      _skip(8)"p-val"   
				di as res _col(5) %10.`=`dp''f `chisq' _col(25) `df' _col(34) %10.4f `pv' 
			}
		}
		
		if ("`continuous'" != "") {
			di as txt "NOTE: For continuous variable margins are computed at their respective mean"
		} 
		if ("`type'" == "abs") {
			di as txt "NOTE: H0: P = 0.5 vs. H1: P != 0.5"
		}
		
end	

/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: LONGSETUP +++++++++++++++++++++++++
							Transform data to long format
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
cap program drop longsetup
program define longsetup
version 14.0

syntax varlist, rid(name) event(name) total(name) se(name) [first(name) rowid(name) assignment(name) idpair(name) cbnetwork abnetwork independent comparative ]

	qui{
		tempvar tp tn fp fn 
		tokenize `varlist'
		if "`cbnetwork'" == "" {
			local nvar = 4
		}
		else {
			local nvar = 8
		}		
		/*The four variables should contain numbers*/
		forvalue i=1(1)`nvar' {
			capture confirm numeric var ``i''
				if _rc != 0 {
					di as error "The variable ``i'' must be numeric"
					exit
				}	
		}
		if "`cbnetwork'" != "" {
			gen `tp'1 = `1'
			gen `fp'1 = `2'
			gen `fn'1 = `3'
			gen `tn'1 = `4'
			gen `tp'0 = `5'
			gen `fp'0 = `6'
			gen `fn'0 = `7'
			gen `tn'0 = `8'
			gen `rowid' = _n
			gen `assignment'1 = `9'
			gen `assignment'0 = `10'
			
			reshape long `tp' `fp' `fn'  `tn' `assignment', i(`rowid') j(`idpair')
		}
		else {
			gen `tp' = `1'
			gen `fp' = `2'
			gen `fn' = `3'
			gen `tn' = `4'
		}
		
		/*4 variables per study : TP TN FP FN*/
		gen `event'1 = `tp'  /*TP*/
		gen `event'0 = `tn'  /*TN*/
		gen `total'1 = `tp' + `fn'  /*DIS = TP + FN*/
		gen `total'0 = `tn' + `fp' /*NDIS = TN + FP*/
		
		gen `rid' = _n	
		if "`abnetwork'" != "" {
			reshape long `event' `total', i(`rid' `first') j(`se')
		}
		else {
			reshape long `event' `total', i(`rid') j(`se')
		}
	}
end

	/*++++++++++++++++	SUPPORTING FUNCTIONS: BUILDEXPRESSIONS +++++++++++++++++++++
				buildexpressions the regression and estimation expressions
	+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	cap program drop buildregexpr
	program define buildregexpr, rclass
	version 13.1
		
		syntax varlist, [cveffect(string) interaction(string) se(name) sp(name) alphasort cbnetwork abnetwork independent comparative ipair(varname) baselevel(string)]
		
		tempvar holder
		tokenize `varlist'
		if "`cbnetwork'" == "" {
			macro shift 4
			local regressors "`*'"
		}
		else {
			local index = "`9'"
			local comparator = "`10'"
			macro shift 10
			local regressors "`*'"
			
			my_ncod `holder', oldvar(`index')
			drop `index'
			rename `holder' `index'
			
			my_ncod `holder', oldvar(`comparator')
			drop `comparator'
			rename `holder' `comparator'

			my_ncod `holder', oldvar(`ipair')
			drop `ipair'
			rename `holder' `ipair'
			
		}
		local p: word count `regressors'
		
		if "`independent'`comparative'" != "" {
			local seregexpression = `"`se'"'
			local spregexpression = `"`sp'"'
		}
		else if "`cbnetwork'" != "" {
			if "`interaction'" == "" {	
				local seregexpression = `"`se' i.`ipair'#c.`se' i.`index'#c.`se' "'
				local spregexpression = `"`sp'  i.`ipair'#c.`sp' i.`index'#c.`sp'"'
			}
			else {
				local seregexpression = `"`se' i.`ipair'#i.`comparator'#c.`se' i.`index'#c.`se' "'
				local spregexpression = `"`sp'  i.`ipair'#i.`comparator'#c.`sp' i.`index'#c.`sp'"'
				//nulllify
				local interaction
			}
		}
		else {
			*abnetwork
			local seregexpression
			local spregexpression
		}
	
		local catreg " "
		local contreg " "
		
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
			if "`abnetwork'`comparative'" != "" & `i'==1 {
				if "`abnetwork'" != "" {
					local prefix_`i' "ibn"
				}
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
			local seregexpression = "`seregexpression' `prefix_`i''.``i''#c.`se'"
			local spregexpression = "`spregexpression' `prefix_`i''.``i''#c.`sp'"
			
			if `i' > 1 & "`interaction'" != "" {
				if "`interaction'" == "se" {
					local seregexpression = "`seregexpression' `prefix_`i''.``i''#`prefix_1'.`1'#c.`se'"
				}
				else if "`interaction'" == "sp" {
					local spregexpression = "`spregexpression' `prefix_`i''.``i''#`prefix_1'.`1'#c.`sp'"
				}
				else {
					local seregexpression = "`seregexpression' `prefix_`i''.``i''#`prefix_1'.`1'#c.`se'"
					local spregexpression = "`spregexpression' `prefix_`i''.``i''#`prefix_1'.`1'#c.`sp'"
				}
			}
			//Pick out the interactor variable
			if `i' == 1 /*& "`interaction'" != "" */{
				local varx = "``i''"
				if 	"`abnetwork'" != "" {
					local prefix_`i' = "i"
				}
				local typevarx = "`prefix_`i''"
			}
			* (`i' > 1 & "`interaction'" != "" ) |  "`interaction'" == ""  { //store the rest of  variables
			if "`prefix_`i''" == "i" {
				local catreg "`catreg' ``i''"
			}
			else {
				local contreg "`contreg' ``i''"
			}
			*}/
		}
		if "`cveffect'" == "sp" {
			local seregexpression "`se'"
		}
		else if "`cveffect'" == "sp" {
			local spregexpression "`sp'"
		}
		
		return local varx = "`varx'"
		return local typevarx  = "`typevarx'"
		return local  regexpression = "`seregexpression' `spregexpression'"
		return local seregexpression =  "`seregexpression'"
		return local spregexpression  = "`spregexpression'"
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
		syntax [if], estimates(string) [sumstat(string) depname(string) expit se(varname) DP(integer 2)) ///
			cveffect(string) interaction(string) catreg(varlist) contreg(varlist) power(integer 0) ///
			level(integer 95) by(varname) varx(varname) typevarx(string) regexpression(string) abnetwork cbnetwork stratify independent comparative ]
		
			tempname outmatrix contregmatrixout catregmatrixout bycatregmatrixout secontregmatrixout spcontregmatrixout outmatrixse ///
				outmatrixsp serow sprow outmatrixse outmatrixsp outmatrixr overallse overallsp Vmatrix byVmatrix
			
			*Nullify by			
			*if "`stratify'" != "" {
			*	local by
			*}
			marksample touse, strok
			
			tokenize `regexpression'
			
			if "`cbnetwork'" != "" {
				if "`interaction'" != "" {
					tokenize `2', parse("#")
					tokenize `1', parse(".")
				 }
				 else {
					tokenize `3', parse("#")
					tokenize `1', parse(".")
				 }
	
				local index "`3'"
				local catreg = "`3' `catreg'"
				local varx //nullify
			}
			
			if "`abnetwork'" != "" {
				tokenize `1', parse("#")
				tokenize `1', parse(".")
				
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
			if "`typevarx'" == "c"  {
				if "`contreg'" == "" {
					local contreg = "`varx'"
				}
			}
			
			local marginlist
			while "`catreg'" != "" {
				tokenize `catreg'
				if ("`1'" != "`by'" & "`by'" != "") | ("`by'" =="") {
					local marginlist = `"`marginlist' `1'`idpairconcat'"'
				}
				macro shift 
				local catreg `*'
			}
			qui estimates restore `estimates'
			
			local byncatreg 0
			if "`by'" != "" & "`stratify'"  == "" {
				qui margin if `touse', predict(xb) over(`se' `by') level(`level')
				
				mat `bycatregmatrixout' = r(table)'
				mat `byVmatrix' = r(V)
				mat `bycatregmatrixout' = `bycatregmatrixout'[1..., 1..6]
				
				local byrnames :rownames `bycatregmatrixout'
				local byncatreg = rowsof(`bycatregmatrixout')
			}
			
			/*if "`abnetwork'`cbnetwork'" == ""  {
				local grand "grand"
				local Overall "Overall"
			}*/
			/*if "`comparative'" != "" & "`stratify'" != "" {
				local grand
				local Overall
			}
			else {*/
				local grand "grand"
				local Overall "Overall"
			*}
			
			local ncatreg 0
			qui margin `marginlist' if `touse', over(`se') predict(xb) `grand' level(`level')
						
			mat `catregmatrixout' = r(table)'
			mat `Vmatrix' = r(V)
			mat `catregmatrixout' = `catregmatrixout'[1..., 1..6]
			
			local rnames :rownames `catregmatrixout'
			local ncatreg = rowsof(`catregmatrixout')
			
			local init 1
			local ncontreg 0
			local contserownames = ""
			local contsprownames = ""
			if "`contreg'" != "" {
				foreach v of local contreg {
					summ `v' if `touse', meanonly
					local vmean = r(mean)
					qui margin if `touse', over(`se') predict(xb) at(`v'=`vmean') level(`level')
					mat `contregmatrixout' = r(table)'
					mat `contregmatrixout' = `contregmatrixout'[1..., 1..6]
					if `init' {
						local init 0
						mat `secontregmatrixout' = `contregmatrixout'[2, 1...] 
						mat `spcontregmatrixout' = `contregmatrixout'[1, 1...] 
					}
					else {
						mat `secontregmatrixout' =  `secontregmatrixout' \ `contregmatrixout'[2, 1...]
						mat `spcontregmatrixout' =  `spcontregmatrixout' \ `contregmatrixout'[1, 1...]
					}
					local contserownames = "`contserownames' `v'"
					local contsprownames = "`contsprownames' `v'"
					local ++ncontreg
				}
				mat rownames `secontregmatrixout' = `contserownames'
				mat rownames `spcontregmatrixout' = `contsprownames'
			}
			
			if "`expit'" != "" {
				forvalues r = 1(1)`byncatreg' {
					mat `bycatregmatrixout'[`r', 1] = invlogit(`bycatregmatrixout'[`r', 1])
					mat `bycatregmatrixout'[`r', 5] = invlogit(`bycatregmatrixout'[`r', 5])
					mat `bycatregmatrixout'[`r', 6] = invlogit(`bycatregmatrixout'[`r', 6])
				}
				forvalues r = 1(1)`ncatreg' {
					mat `catregmatrixout'[`r', 1] = invlogit(`catregmatrixout'[`r', 1])
					mat `catregmatrixout'[`r', 5] = invlogit(`catregmatrixout'[`r', 5])
					mat `catregmatrixout'[`r', 6] = invlogit(`catregmatrixout'[`r', 6])
				}
				forvalues r = 1(1)`ncontreg' {
					mat `secontregmatrixout'[`r', 1] = invlogit(`secontregmatrixout'[`r', 1])
					mat `secontregmatrixout'[`r', 5] = invlogit(`secontregmatrixout'[`r', 5])
					mat `secontregmatrixout'[`r', 6] = invlogit(`secontregmatrixout'[`r', 6])
					
					mat `spcontregmatrixout'[`r', 1] = invlogit(`spcontregmatrixout'[`r', 1])
					mat `spcontregmatrixout'[`r', 5] = invlogit(`spcontregmatrixout'[`r', 5])
					mat `spcontregmatrixout'[`r', 6] = invlogit(`spcontregmatrixout'[`r', 6])
				}
			}
			
			local serownames = ""
			local sprownames = ""
			
			local rownamesmaxlen = 10 /*Default*/
			
			*if "`grand'" != "" {
				local nrowss = `ncatreg' + `byncatreg' - 2 //Except the grand rows
			*}
			*else {
			local nrowscat = `ncatreg' + `byncatreg' 
			*}
			
			
			//# equations
			if "`cveffect'" == "sesp" {
				local keq 2
			}
			else {
				local keq 1
			} 
			mat `serow' = J(1, 6, .)
			mat `sprow' = J(1, 6, .)

			
			local initse 0
			local initsp 0	
			local rnames = "`byrnames' `rnames'" //attach the bynames	
			
			//Except the grand rows	
			forvalues r = 1(1)`=`byncatreg' + `ncatreg'  - `=2*`="`grand'"!=""''' {
				//Labels
				local rname`r':word `r' of `rnames'
				tokenize `rname`r'', parse("#")					
				local parm = "`1'"
				local left = "`3'"
				local right = "`5'"
				
				tokenize `left', parse(.)
				local leftv = "`3'"
				local leftlabel = "`1'"
				
				if "`right'" == "" {
					if "`leftv'" != "" {
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
				
				if "`cbnetwork'" != "" & "`eqlab'"=="`index'" {
					local eqlab "`index'"
				}
				
				//se or sp
				local parm = substr("`parm'", 1, 1)
				if `r' > `=`byncatreg'' {
					mat `outmatrixr' = `catregmatrixout'[`=`r' - `byncatreg'', 1...] //select the r'th row
				}
				else{
					mat `outmatrixr' = `bycatregmatrixout'[`r', 1...] //select the r'th row
				}

				if `parm' == 0 {
					if `initsp' == 0 {
						mat `outmatrixsp' = `outmatrixr'
					}
					else {
						mat `outmatrixsp' = `outmatrixsp' \ `outmatrixr'
					}
					local initsp 1
					local sprownames = "`sprownames' `eqlab':`lab'"
				}
				else {
					if `initse' == 0 {
						mat `outmatrixse' = `outmatrixr'
					}
					else {
						mat `outmatrixse' = `outmatrixse' \ `outmatrixr'
					}
					local initse 1
					local serownames = "`serownames' `eqlab':`lab'"
				}
			}
			
			if `nrowscat'  > 2 {
				mat rownames `outmatrixse' = `serownames'
				mat rownames `outmatrixsp' = `sprownames'
			}			
			/*if "`interaction'" != "" {
				mat rownames `serow' = "Sensitivity--**"
				mat rownames `sprow' = "**--Specificity--**" //19 characters
			}
			else {*/
			mat rownames `serow' = "Sensitivity"
			mat rownames `sprow' = "Specificity" //19 characters
			
			local rownamesmaxlen = max(`rownamesmaxlen', 19) /*Check if there is a longer name*/
			
			*if "`grand'" != "" {
				mat `overallsp' = `catregmatrixout'[`=`ncatreg'-1', 1...]
				mat `overallse' = `catregmatrixout'[`ncatreg', 1...]
			/*}
			else {
				mat `overallsp' =
				mat `overallse' =				
			}*/
			mat rownames `overallse' = "Overall"
			mat rownames `overallsp' = "Overall"
						
			
			if `=`ncatreg' + `byncatreg' - 2' > 0 | `ncontreg' > 0 {
				if "`cveffect'" == "sesp" {
					*local rspec "---`="&"*`=`nrowss'/2 + `ncontreg'''--`="&"*`=`nrowss'/2 + `ncontreg'''-"
					if (`=`ncatreg' + `byncatreg' - 2' > 0) & (`ncontreg' > 0) {
						mat `outmatrix' = `serow' \ `outmatrixse' \ `secontregmatrixout' \ `overallse' \ `sprow' \ `outmatrixsp' \ `spcontregmatrixout' \ `overallsp'
					}
					else if (`=`ncatreg' + `byncatreg' - 2' > 0) & (`ncontreg' == 0) {
						mat `outmatrix' = `serow' \ `outmatrixse' \ `overallse' \ `sprow' \ `outmatrixsp' \ `overallsp'
					}
					else if (`=`ncatreg' + `byncatreg' - 2' == 0) & (`ncontreg' > 0) {
						mat `outmatrix' = `serow' \ `secontregmatrixout' \ `overallse' \ `sprow' \ `spcontregmatrixout' \ `overallsp'
					}
				}
				else {
					if "`cveffect'" == "se" {
						if (`=`ncatreg' + `byncatreg' - 2' > 0) & (`ncontreg' > 0) {
							mat `outmatrix' = `serow' \ `outmatrixse' \ `secontregmatrixout' \ `overallse' \ `sprow' \ `overallsp'
						}
						else if (`=`ncatreg' + `byncatreg' - 2' > 0) & (`ncontreg' == 0) {
							mat `outmatrix' = `serow' \ `outmatrixse' \ `overallse' \ `sprow' \ `overallsp'
						}
						else if (`=`ncatreg' + `byncatreg' - 2' == 0) & (`ncontreg' > 0) {
							mat `outmatrix' = `serow' \ `secontregmaritxout' \ `overallse' \ `sprow' \ `overallsp'
						}
						*local rspec "---`="&"*`=(`ncatreg' + `byncatreg' - 2)/2 + `ncontreg'''---"
					}
					else {
						if (`=`ncatreg' + `byncatreg' - 2' > 0) & (`ncontreg' > 0) { 
							mat `outmatrix' = `serow' \ `overallse' \ `sprow' \ `outmatrixsp' \ `spcontregmatrixout' \ `overallsp'
						}
						else if (`=`ncatreg' + `byncatreg' - 2' > 0) & (`ncontreg' == 0) { 
							mat `outmatrix' = `serow' \ `overallse' \ `sprow' \ `outmatrixsp' \ `overallsp'
						}
						else if (`=`ncatreg' + `byncatreg' - 2' == 0) & (`ncontreg' > 0) { 
							mat `outmatrix' = `serow' \ `overallse' \ `sprow' \ `spcontregmatrixout' \ `overallsp'
						}
						*local rspec "-----`="&"*`=(`ncatreg' + `byncatreg' - 2)/2 + `ncontreg'''-"
					}
				}
				
				if (`=`ncatreg' + `byncatreg' - 2' > 0) & (`ncontreg' > 0) {
					mat `outmatrixse' = `outmatrixse' \ `secontregmatrixout' \ `overallse' 
					mat `outmatrixsp' = `outmatrixsp' \ `spcontregmatrixout' \ `overallsp' 				
				}
				else if (`=`ncatreg' + `byncatreg' - 2' > 0) & (`ncontreg' == 0) {
					mat `outmatrixse' = `outmatrixse' \ `overallse' 
					mat `outmatrixsp' = `outmatrixsp' \ `overallsp' 
				}
				else if (`=`ncatreg' + `byncatreg' - 2' == 0) & (`ncontreg' > 0) {
					mat `outmatrixse' = `secontregmatrixout' \ `overallse' 
					mat `outmatrixsp' = `spcontregmatrixout' \ `overallsp' 
				}
			}
			else {
				mat rownames `overallse' = "Sensitivity"
				mat rownames `overallsp' = "Specificity"
				mat `outmatrixse' =  `overallse' 
				mat `outmatrixsp' = `overallsp' 
				*local rspec "----"
				mat `outmatrix' =  `overallse' \ `overallsp'
				local rownamesmaxlen = max(`rownamesmaxlen', 12) /*Check if there is a longer name*/
			}			
			if "`expit'" == "" {
				mat colnames `outmatrix' = `sumstat' SE z P>|z| Lower Upper
				mat colnames `outmatrixse' = `sumstat' SE z P>|z| Lower Upper
				mat colnames `outmatrixsp' = `sumstat' SE z P>|z| Lower Upper
			}
			else {
				mat colnames `outmatrix' = `sumstat' SE(logit) z(logit) P>|z| Lower Upper
				mat colnames `outmatrixse' = `sumstat' SE(logit) z(logit) P>|z| Lower Upper
				mat colnames `outmatrixsp' = `sumstat' SE(logit) z(logit) P>|z| Lower Upper
			}
			
		return matrix outmatrixse = `outmatrixse'
		return matrix outmatrixsp = `outmatrixsp'		
		return matrix outmatrix = `outmatrix'
		return matrix Vmatrix = `Vmatrix'
	end	
/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: ESTR +++++++++++++++++++++++++
							Estimate RR after modelling
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	cap program drop estr
	program define estr, rclass
	version 13.1
		syntax [if], estimates(string) [catreg(varlist) varx(varname) typevarx(string) sumstat(string) comparator(varname) ///
		se(varname) comparative level(integer 95) DP(integer 2) power(integer 0) ///
		cveffect(string) independent cbnetwork abnetwork stratify comparative by(varname) ///
		regexpression(string) baselevel(integer 1) refpos(string)]
		
		marksample touse, strok
		
		local ZOVE -invnorm((100 - `level')/200)
		
		tokenize `regexpression'
		if "`cbnetwork'" != "" {
			if "`interaction'" != "" {
				tokenize `2', parse("#")
				tokenize `1', parse(".")
			 }
			 else {
				tokenize `3', parse("#")
				tokenize `1', parse(".")
			 }

			local index "`3'"
			*if "`by'" == "" {
			*	local by = "`3'"
			*}
			*local varx //nullify
		}
		
		if "`abnetwork'`independent'" != "" {
			//nullify
			local varx
			local typevarx
		}
		
		if "`comparative'" != "" {
			*tokenize `catreg'
			*macro shift
			*local catreg "`*'"
			local idpairconcat "#`varx'"
			local typevarx "i"
			*Nullify by			
			if "`stratify'" != "" {
				local by
			}
		}
		*if "`by'`comparator'" != ""  {
			local confounders "`by' `catreg'"
		/*}
		else {
			local confounders "`catreg'"
		}*/
		local marginlist
		while "`catreg'" != "" {
			tokenize `catreg'
			local marginlist = `"`marginlist' `1'`idpairconcat'"'
			macro shift 
			local catreg "`*'"
		}
		
		tempname lcoef lV outmatrix outmatrixse outmatrixsp serow sprow outmatrixse outmatrixsp outmatrixr overallse overallsp setestnl sptestnl serowtestnl sprowtestnl testmat2print
		
		if "`marginlist'" != "" | ("`varx'" != "" & "`by'" != "" ){
			qui estimates restore `estimates'
			if "`marginlist'" != "" {
				qui margins `marginlist' if `touse', predict(xb) over(`se') post level(`level')
			}
			if "`varx'" != "" & "`by'" != ""  {
				qui margins `varx' if `touse', predict(xb) over(`se' `by') post level(`level')
			}
			
			local EstRlnexpression
			foreach c of local confounders {	
				qui label list `c'
				local nlevels = r(max)
				local sp_test_`c'
				local se_test_`c'
				
				if "`typevarx'" == "i" {
					forvalues l = 1/`nlevels' {
						if `l' == 1 {
							local sp_test_`c' = "_b[sp_`c'_`l']"
							local se_test_`c' = "_b[se_`c'_`l']"
						}
						else {
							local sp_test_`c' = "_b[sp_`c'_`l'] = `sp_test_`c''"
							local se_test_`c' = "_b[se_`c'_`l'] = `se_test_`c''"
						}
						local EstRlnexpression = "`EstRlnexpression' (sp_`c'_`l': ln(invlogit(_b[0.`se'#`l'.`c'#2.`varx'])) - ln(invlogit(_b[0.`se'#`l'.`c'#1.`varx'])))"	
						local EstRlnexpression = "`EstRlnexpression' (se_`c'_`l': ln(invlogit(_b[1.`se'#`l'.`c'#2.`varx'])) - ln(invlogit(_b[1.`se'#`l'.`c'#1.`varx'])))"	
					}
				}
				else {
					local sp_test_`c' = "_b[sp_`c'_`baselevel']"
					local se_test_`c' = "_b[se_`c'_`baselevel']"
					local init 1
					
					forvalues l = 1/`nlevels' {
						if "abnetwork" !="" {
							if `l' == 1 {
								local sp_test_`c' = "_b[sp_`c'_`l']"
								local se_test_`c' = "_b[se_`c'_`l']"
							}
							else {
								local sp_test_`c' = "_b[sp_`c'_`l'] = `sp_test_`c''"
								local se_test_`c' = "_b[se_`c'_`l'] = `se_test_`c''"
							}
						}
						else {
							if `l' != `baselevel' {
								if `init' == 1 {
									local sp_test_`c' = "_b[sp_`c'_`l']"
									local se_test_`c' = "_b[se_`c'_`l']"
									local init 0
								}
								else {
									local sp_test_`c' = "_b[sp_`c'_`l'] = `sp_test_`c''"
									local se_test_`c' = "_b[se_`c'_`l'] = `se_test_`c''"
								}
							}
						}
						if "`refpos'" == "top" {
							local EstRlnexpression = "`EstRlnexpression' (sp_`c'_`l': ln(invlogit(_b[0.`se'#`baselevel'.`c'])) - ln(invlogit(_b[0.`se'#`l'.`c'])))"	
							local EstRlnexpression = "`EstRlnexpression' (se_`c'_`l': ln(invlogit(_b[1.`se'#`baselevel'.`c'])) - ln(invlogit(_b[1.`se'#`l'.`c'])))"	
						}
						else {
							local EstRlnexpression = "`EstRlnexpression' (sp_`c'_`l': ln(invlogit(_b[0.`se'#`l'.`c'])) - ln(invlogit(_b[0.`se'#`baselevel'.`c'])))"	
							local EstRlnexpression = "`EstRlnexpression' (se_`c'_`l': ln(invlogit(_b[1.`se'#`l'.`c'])) - ln(invlogit(_b[1.`se'#`baselevel'.`c'])))"	
						}
						
					}
				
				}
			}			
			qui nlcom `EstRlnexpression', post level(`level') iterate(200)
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
				if (`nlevels' > 2 & "`comparative'" == "") | (`nlevels' > 1 & ("`comparative'" != "" | "`cbnetwork'" != "" )){
					qui testnl (`se_test_`c''), iterate(200)
					local se_testnl_`c'_chi2 = r(chi2)				
					local se_testnl_`c'_df = r(df)
					local se_testnl_`c'_p = r(p)
					qui testnl (`sp_test_`c'')
					local sp_testnl_`c'_chi2 = r(chi2)
					local sp_testnl_`c'_df = r(df)
					local sp_testnl_`c'_p = r(p)
					if `i'==1 {
						mat `setestnl' =  [`se_testnl_`c'_chi2', `se_testnl_`c'_df', `se_testnl_`c'_p']
						mat `sptestnl' =  [`sp_testnl_`c'_chi2', `sp_testnl_`c'_df', `sp_testnl_`c'_p']
					}
					else {
						mat `setestnl' = `setestnl' \ [`se_testnl_`c'_chi2', `se_testnl_`c'_df', `se_testnl_`c'_p']
						mat `sptestnl' = `sptestnl' \ [`sp_testnl_`c'_chi2', `sp_testnl_`c'_df', `sp_testnl_`c'_p']
					}
					 
					local ++i
					local rowtestnl = "`rowtestnl' `c' "
				}
			}
			
			if `i' > 1 {
				mat rownames `setestnl' = `rowtestnl'
				mat rownames `sptestnl' = `rowtestnl'
				mat colnames `setestnl' = chi2 df p
				mat colnames `sptestnl' = chi2 df p
				
				mat roweq `setestnl' = Relative_Sensitivity
				mat roweq `sptestnl' = Relative_Specificity
								
				*mat `testmat2print' =  `setestnl'  \ `sptestnl' 
				*mat colnames `testmat2print' = chi2 df p
				
				local inltest = "yes"
			}
			else {
				local inltest = "no"
			}
			
			if "`comparative'" != ""  | "`cbnetwork'" != ""  {
				mat `outmatrix' = J(`=`ncols' + 2', 6, .)
			}
			else {
				mat `outmatrix' = J(`ncols', 6, .)
			}
			
			forvalues r = 1(1)`ncols' {
				mat `outmatrix'[`r', 1] = exp(`lcoef'[1,`r']) /*Estimate*/
				mat `outmatrix'[`r', 2] = sqrt(`lV'[1, `r']) /*se in log scale, power 1*/
				mat `outmatrix'[`r', 3] = `lcoef'[1,`r']/sqrt(`lV'[1, `r']) /*Z in log scale*/
				mat `outmatrix'[`r', 4] =  normprob(-abs(`outmatrix'[`r', 3]))*2  /*p-value*/
				mat `outmatrix'[`r', 5] = exp(`lcoef'[1, `r'] - `ZOVE' * sqrt(`lV'[1, `r'])) /*lower*/
				mat `outmatrix'[`r', 6] = exp(`lcoef'[1, `r'] + `ZOVE' * sqrt(`lV'[1, `r'])) /*upper*/
			}
		}
		else {
			mat `outmatrix' = J(2, 6, .)
			local ncols = 0
		}
		if "`typevarx'" == "i" {	
			qui estimates restore `estimates'
			qui margins `varx' if `touse', predict(xb) over(`se') post level(`level')
					
			//log metric
			if `baselevel' == 1 {
				local indexlevel "2"
			}
			else {
				local indexlevel "1"
			}
			if "`refpos'" == "bottom" {
				qui nlcom (sp_Overall: ln(invlogit(_b[0.`se'#`indexlevel'.`varx'])) - ln(invlogit(_b[0.`se'#`baselevel'.`varx']))) ///
					  (se_Overall: ln(invlogit(_b[1.`se'#`indexlevel'.`varx'])) - ln(invlogit(_b[1.`se'#`baselevel'.`varx']))), iterate(200)
			}
			else {
				qui nlcom (sp_Overall: ln(invlogit(_b[0.`se'#`baselevel'.`varx'])) - ln(invlogit(_b[0.`se'#`indexlevel'.`varx']))) ///
						  (se_Overall: ln(invlogit(_b[1.`se'#`baselevel'.`varx'])) - ln(invlogit(_b[1.`se'#`indexlevel'.`varx']))), iterate(200)
			}			
			mat `lcoef' = r(b)
			mat `lV' = r(V)
			mat `lV' = vecdiag(`lV')
			
			forvalues r=1(1)2 {
				mat `outmatrix'[`=`ncols' + `r'', 1] = exp(`lcoef'[1,`r'])  //rr
				mat `outmatrix'[`=`ncols' + `r'', 2] = sqrt(`lV'[1, `r']) //se
				mat `outmatrix'[`=`ncols' + `r'', 3] = `lcoef'[1, `r']/sqrt(`lV'[1, `r']) //zvalue
				mat `outmatrix'[`=`ncols' + `r'', 4] = normprob(-abs(`lcoef'[ 1, `r']/sqrt(`lV'[1, `r'])))*2 //pvalue
				mat `outmatrix'[`=`ncols' + `r'', 5] = exp(`lcoef'[1, `r'] - `ZOVE'*sqrt(`lV'[1, `r'])) //ll
				mat `outmatrix'[`=`ncols' + `r'', 6] = exp(`lcoef'[1, `r'] + `ZOVE'*sqrt(`lV'[1, `r'])) //ul
			}
			local rnames = "`rnames' sp_Overall se_Overall"
		}
		
		local sprownames = ""
		local serownames = ""
		local rspec = "-" /*draw lines or not between the rows*/
		local rownamesmaxlen = 10 /*Default*/
		
		local nrows = rowsof(`outmatrix')

		local initse 0
		local initsp 0
		forvalues r = 1(1)`ncols' {
			local rname`r':word `r' of `rnames'
			tokenize `rname`r'', parse("_")					
			local parm = "`1'"
			local left = "`3'"
			local right = "`5'"
			mat `outmatrixr' = `outmatrix'[`r', 1...] //select the r'th row
			if "`5'" != "" {
				local lab:label `left' `right'
				local lab = ustrregexra("`lab'", " ", "_")
				local nlen : strlen local lab
				local rownamesmaxlen = max(`rownamesmaxlen', min(`nlen', 32)) //Check if there is a longer name
				local `parm'rownames = "``parm'rownames' `left':`lab'" 
				if `init`parm'' == 0 {
					mat `outmatrix`parm'' = `outmatrixr'
				}
				else {
					mat `outmatrix`parm'' = `outmatrix`parm'' \ `outmatrixr'
				}
				local init`parm' 1
			}
		}
		if `ncols' > 0 {
			mat rownames `outmatrixse' = `serownames'
			mat rownames `outmatrixsp' = `sprownames'
		}
		*mat out = `outmatrix'	
		mat `serow' = J(1, 6, .)
		mat `sprow' = J(1, 6, .)
		
		mat rownames `serow' = "Relative Sensitivity"
		mat rownames `sprow' = "Relative Specificity"  //20 chars
		local rownamesmaxlen = max(`rownamesmaxlen', 21) //Check if there is a longer name
		
		if ("`comparative'" !="" | "`cbnetwork'" != "") {
			mat `overallsp' = `outmatrix'[`=`nrows'-1', 1...]
			mat `overallse' = `outmatrix'[`nrows', 1...]
			
			mat rownames `overallse' = "Overall"
			mat rownames `overallsp' = "Overall"
		}

		if `ncols' > 0 & ("`comparative'`cbnetwork'" != ""){
			if "`cveffect'" == "sesp" {
				*local rspec "---`="&"*`=`nrows'/2 - 1''--`="&"*`=`nrows'/2 - 1''-"
				mat `outmatrix' = `serow' \ `outmatrixse' \ `overallse'  \ `sprow' \ `outmatrixsp' \ `overallsp'
			}
			else if "`cveffect'" == "se" { 
				mat `outmatrix' = `serow' \ `outmatrixse' \ `overallse'  \ `sprow' \  `overallsp'
				}
			else {
				mat `outmatrix' = `serow' \ `overallse'  \ `sprow' \ `outmatrixsp' \ `overallsp'
			}
				*local rspec "--`="&"*`=`nrows'/2''-"
			
			mat `outmatrixse' = `outmatrixse' \ `overallse' 
			mat `outmatrixsp' = `outmatrixsp' \ `overallsp' 
		}
		if `ncols' > 0 &  "`cbnetwork'`comparative'" =="" {
			if "`cveffect'" == "sesp" {
				*local rspec "---`="&"*`=`nrows'/2 - 1''--`="&"*`=`nrows'/2 - 1''-"
				mat `outmatrix' = `serow' \ `outmatrixse'  \ `sprow' \ `outmatrixsp'
				mat `outmatrixse' = `serow' \ `outmatrixse'
				mat `outmatrixsp' = `sprow'  \ `outmatrixsp'
			}
			else {
				if "`cveffect'" == "se" { 
					mat `outmatrix' = `serow' \ `outmatrixse'
					mat `outmatrixse' = `serow' \ `outmatrixse'
					mat `outmatrixsp' = J(1, 6, .)
				}
				else {
					mat `outmatrix' = `sprow'  \ `outmatrixsp'
					mat `outmatrixsp' = `sprow'  \ `outmatrixsp'
					mat `outmatrixse' = J(1, 6, .)
				}
				*local rspec "--`="&"*`=`nrows'/2'-1'-"
			}		
		}
		if `ncols' == 0 {
			mat `outmatrixse' =  `overallse' 
			mat `outmatrixsp' = `overallsp'
			mat `outmatrix' = `serow' \ `outmatrixse'  \ `sprow' \ `outmatrixsp'
			*local rspec "--&-&-"			
		}	

		mat colnames `outmatrixse' = `sumstat' SE(lor) z(lor) P>|z| Lower Upper
		mat colnames `outmatrixsp' = `sumstat' SE(lor) z(lor) P>|z| Lower Upper
		mat colnames `outmatrix' = `sumstat' SE(lor) z(lor) P>|z| Lower Upper

		if "`inltest'" == "yes" {
			return matrix setestnl = `setestnl'
			return matrix sptestnl = `sptestnl'
		}
		return local inltest = "`inltest'"
		return matrix outmatrix = `outmatrix'
		return matrix outmatrixse = `outmatrixse'
		return matrix outmatrixsp = `outmatrixsp'
	end	
/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: ESTCOVAR +++++++++++++++++++++++++
							Compose the var-cov matrix
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
cap program drop estcovar
program define estcovar, rclass
version 14.0

	syntax, matrix(name) model(string) [ bcov(string) wcov(string) abnetwork cbnetwork comparative independent ]
	*matrix is colvector
	tempname matcoef BVar WVar
	mat `matcoef' = `matrix''
	local nrows = rowsof(`matcoef')
	*Initialize - Default
	mat	`BVar' = (0, 0\ ///
				0, 0)
	mat	`WVar' = (0, 0\ ///
				0, 0)
	local b = 0
	local w = 0	
	
	if "`model'" == "random" {
		*WVAR
		if "`abnetwork'" != "" {
			if strpos("`wcov'", "ind") != 0 {
				mat	`WVar' = (exp(`matcoef'[ `nrows' - 1, 1])^2, 0\ ///
							0, exp(`matcoef'[ `nrows', 1])^2)
				local w = 2
			}
			else if strpos("`wcov'", "id") != 0 {
				mat	`WVar' = (exp(`matcoef'[ `nrows', 1])^2, 0 \ ///
					0, exp(`matcoef'[ `nrows', 1])^2)
				local w = 1
			}
		}

		*BVAR
		if strpos("`bcov'", "uns") != 0 {
			mat	`BVar' = (exp(`matcoef'[`nrows' - 2 - `w', 1])^2, exp(`matcoef'[ `nrows' - 1 - `w', 1])*exp(`matcoef'[`nrows' - 2 - `w', 1])*tanh(`matcoef'[ `nrows' - `w', 1])\ ///
						exp(`matcoef'[ `nrows' - 1 - `w', 1])*exp(`matcoef'[`nrows' - 2 - `w', 1])*tanh(`matcoef'[ `nrows' - `w', 1]), exp(`matcoef'[ `nrows' - 1 - `w', 1])^2)
			local b = 3
		}		
		else if strpos("`bcov'", "ind") != 0 {
			mat	`BVar' = (exp(`matcoef'[ `nrows' - 1 - `w', 1])^2, 0\ ///
						0, exp(`matcoef'[ `nrows' - `w', 1])^2)
			local b = 2
		}
		else if strpos("`bcov'", "exc") != 0 {
			mat	`BVar' = (exp(`matcoef'[ `nrows' - 1 - `w', 1])^2, exp(`matcoef'[ `nrows' - 1 - `w', 1])*exp(`matcoef'[ `nrows' - 1 - `w', 1])*tanh(`matcoef'[ `nrows' - `w', 1])\ ///
						exp(`matcoef'[ `nrows' - 1 - `w', 1])*exp(`matcoef'[ `nrows' - 1 - `w', 1])*tanh(`matcoef'[ `nrows' - `w', 1]), exp(`matcoef'[ `nrows' - 1 - `w', 1])^2)
			local b = 2
		}
		else if (strpos("`bcov'", "id") != 0) {
			mat	`BVar' = (exp(`matcoef'[ `nrows' - `w', 1])^2, 0\ ///
				0, exp(`matcoef'[ `nrows' - `w', 1])^2)
				
			local b = 1
		}
		else if (strpos("`bcov'", "sp") != 0) {
			mat	`BVar' = (0, 0\ ///
				0, exp(`matcoef'[ `nrows' - `w', 1])^2)
				
			local b = 1
		}
		else if (strpos("`bcov'", "se") != 0) {
			mat	`BVar' = (exp(`matcoef'[ `nrows' - `w', 1])^2, 0\ ///
				0, 0)
				
			local b = 1
		}
	}
		
	local k = `b' + `w'
	
	return matrix WVar = `WVar' 
	return matrix BVar = `BVar' 
	return local k = `k' 
end
	/*+++++++++++++++++++++++++	SUPPORTING FUNCTIONS: 	KOOPMANCI +++++++++++++++++++++++++
								CI for RR
	++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	cap program drop koopmanci
	program define koopmanci
	version 14.0

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
	version 14.0
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
/*	SUPPORTING FUNCTIONS: FPLOTCHECK ++++++++++++++++++++++++++++++++++++++++++
			Advance housekeeping for the fplot
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	capture program drop fplotcheck
	program define fplotcheck, rclass
	version 14.1	
	#delimit ;
	syntax  [,
		/*Passed from top*/
		COMParative 
		/*passed via foptions*/
		AStext(integer 50) 				
		CIOpt(passthru) 
		DIAMopt(passthru) 
		DOUble 
 		LCols(varlist) 
		noOVLine 
		noSTATS
		ARRowopt(passthru) 		
		OLineopt(passthru) 
		OUTplot(string) 
		PLOTstat(passthru) //comma seperated
		POINTopt(passthru) 
		SUBLine 
		TEXts(real 1.5) 
		XLIne(passthru)	/*silent option*/
		XLAbel(passthru) 
		XTick(passthru) 
		GRID
		GRAphsave(passthru)
		cbnetwork
		logscale
		abnetwork
		independent
		first(varname)
		by(varname)
		*
	  ];
	#delimit cr
	
		if `astext' > 90 | `astext' < 10 {
		di as error "Percentage of graph as text (ASTEXT) must be within 10-90%"
		di as error "Must have some space for text and graph"
		exit
	}
	if `texts' < 0 {
		di as res "Warning: Negative text size (TEXTSize) are ignored"
		local texts 1
	}	
	
	if "`outplot'" == "" {
		local outplot abs
	}
	else {
		local outplot = strlower("`outplot'")
		local rc_ = ("`outplot'" == "rr") + ("`outplot'" == "abs")
		if `rc_' != 1 {
			di as error "Options outplot(`outplot') incorrectly specified"
			di as error "Allowed options: abs, rr"
			exit
		}
		if "`outplot'" == "rr" {
			cap assert "`abnetwork'`comparative'`cbnetwork'" != "" 
			if _rc != 0 {
				di as error "Option outplot(rr) only avaialable with abnetwork/comparative/cbnetwork analysis"
				di as error "Specify analysis with -abnetwork/comparative/cbnetwork- option"
				exit _rc
			}
		}
		if ("`first'" != "" & "`by'" != "") & "`comparative'" != "" {
			cap assert ("`first'" != "`by'") & ("`output'" != "rr")
			if _rc != 0 { 
					di as error "Remove the option by(`by') or specify a different by-variable"
					exit _rc
			}
		}
	}
	foreach var of local lcols {
		cap confirm var `var'
		if _rc!=0  {
			di in re "Variable `var' not in the dataset"
			exit _rc
		}
	}
	if "`lcols'" =="" {
		local lcols " "
	}
	if "`astext'" != "" {
		local astext "astext(`astext')"
	}
	if "`texts'" != "" {
		local texts "texts(`texts')"
	}
	local foptions `"`astext' `ciopt' `diamopt' `arrowopt' `double' `ovline' `stats' `olineopt' `plotstat' `pointopt' `subline' `texts' `xlabel' `xtick' `grid' `xline'  `logscale' `graphsave' `options'"'
	return local outplot = "`outplot'"
	return local lcols ="`lcols'"
	return local foptions = `"`foptions'"'
end

/*	SUPPORTING FUNCTIONS: FPLOT ++++++++++++++++++++++++++++++++++++++++++++++++
			The forest plot
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
// Some re-used code from metaprop

	capture program drop fplot
	program define fplot
	version 14.1	
	#delimit ;
	syntax varlist [if] [in] [,
	    /*Passed from top options*/
		STudyid(varname)
		POWer(integer 0)
		DP(integer 2) 
		Level(integer 95)
		/*passed from within*/	
		Groupvar(varname)		
		/*passed via foptions*/
		AStext(integer 50)
		ARRowopt(string) 		
		CIOpt(string) 
		DIAMopt(string) 
		DOUble 
 		LCols(varlist) 
		noOVLine 
		noSTATS 
		OLineopt(string) 
		OUTplot(string) 
		PLOTstat(string asis) /*comma seperated*/
		POINTopt(string) 
		SUBLine 
		TEXts(real 1.5) 
		XLIne(string asis)
		XLAbel(string) 
		XTick(string)
		GRID
		GRAPHSave(string asis)
		logscale
		abnetwork
		cbnetwork
		comparative
		independent
		*
	  ];
	#delimit cr
	
	local foptions `"`options'"'
	if strpos(`"`foptions'"', "graphregion") == 0 {
			local foptions `"graphregion(color(white)) `foptions'"'
		}
	
	tempvar effect lci uci use label tlabel id newid se  df  expand orig ///
	
	tokenize "`varlist'", parse(" ")

	qui {
		gen `effect'=`1'*(10^`power')
		gen `lci'   =`2'*(10^`power')
		gen `uci'   =`3'*(10^`power')
		gen byte `use'=`4'
		gen str `label'=`5'
		gen `df' = `6'
		gen `id' = `7'
		gen `se' = `8'
		
		if "`plotstat'"=="" {
			local outplot = strlower("`outplot'")
			if "`outplot'" == "rr" {
				local plotstatse "Relative Sensitivity"
				local plotstatsp "Relative Specificity"
			}
			else {
				local plotstatse "Sensitivity"
				local plotstatsp "Specificity"
			}
		}
		else {
			tokenize "`plotstat'", parse(",")
			local plotstatse "`1'"
			local plotstatsp "`3'"
		}
		qui summ `id'
		gen `expand' = 1
		replace `expand' = 1 + 1*(`id'==r(min)) 
		expand `expand'
		
		replace `id' = `id' + 1 if _n>2
		replace `label' = "" if `id'==1
		replace `use' = 0 if `id'==1
		
		sort `id' `se'
		
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
		if "`lcols'" == "" {
			local lcols "`label'"
		}
		else {
			local lcols "`label' `lcols'"
		}
		
		egen `newid' = group(`id')
		replace `id' = `newid'
		drop `newid'

		tempvar estText estTextse estTextsp index
		gen str `estText' = string(`effect', "%10.`=`dp''f") + " (" + string(`lci', "%10.`=`dp''f") + ", " + string(`uci', "%10.`=`dp''f") + ")"  if (`use' == 1 | `use' == 2 | `use' == 3)

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

		local DXmin1= (min(`xtick',`DXmin'))
		local DXmax1= (max(`xtick',`DXmax'))
		*local DXmin1= (min(`xlabel',`xtick',`DXmin'))
		*local DXmax1= (max(`xlabel',`xtick',`DXmax'))
		

		local DXwidth = `DXmax1'-`DXmin1'
	} // END QUI

	/*===============================================================================================*/
	/*==================================== COLUMNS   ================================================*/
	/*===============================================================================================*/
	qui {	// KEEP QUIET UNTIL AFTER DIAMONDS
	
		local titleOff = 0
		
		if "`lcols'" == "" {
			local lcols = "`label'"
			local titleOff = 1
		}
		
		// DOUBLE LINE OPTION
		if "`double'" != "" & ("`lcols'" != "" | "`stats'" == ""){
			*gen `orig' = `id'
			replace `expand' = 1
			replace `expand' = 2 if `use' == 1
			expand `expand'
			sort `id' `se'
			bys `id' `se': gen `index' = _n
			sort  `se' `id' `index'
			egen `newid' = group(`id' `index')
			replace `id' = `newid'
			drop `newid'
			
			replace `use' = 1 if `index' == 2
			replace `effect' = . if `index' == 2
			replace `lci' = . if `index' == 2
			replace `uci' = . if `index' == 2
			replace `estText' = "" if `index' == 2			
			/*
			replace `id' = `id' + 0.75 if `id' == `id'[_n-1] & `se' == `se'[_n-1] & (`use' == 1)
			replace `use' = 1 if mod(`id',1) != 0 
			replace `effect' = .  if mod(`id',1) != 0
			replace `lci' = . if mod(`id',1) != 0
			replace `uci' = . if mod(`id',1) != 0
			replace `estText' = "" if mod(`id',1) != 0
			*/
			foreach var of varlist `lcols' {
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
					replace `splitwhere' = strpos(`var',word(`var',`i')) ///
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

		tempvar flag
		summ `id' 
		local max = r(max)
		local new = r(N) + 4
		set obs `new' 
		gen `flag' = 0
		replace `flag' = 1 if `id' == .
		forvalues i = 1/4 {	// up to four lines for titles
			local Nnew`i' = r(N)+`i' 
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
				replace `leftLB`lcolsN'' = "" if (`use' != 1) | (`se' != 1)
				local colName: variable label `1'
				if "`colName'"==""{
					local colName = "`1'"
				}

				// WORK OUT IF TITLE IS BIGGER THAN THE VARIABLE
				// SPREAD OVER UP TO FOUR LINES IF NECESSARY
				local titleln = length("`colName'")
				tempvar tmpln
				gen `tmpln' = length(`leftLB`lcolsN'')
				qui summ `tmpln' if `use' != 0
				local otherln = r(max)
				drop `tmpln'
				// NOW HAVE LENGTH OF TITLE AND MAX LENGTH OF VARIABLE
				local spread = int(`titleln'/`otherln') + 1
				if `spread' > 4{
					local spread = 4
				}
				local line = 1
				local end = 0
				local count = -1
				local c2 = -2

				local first = word("`colName'",1)
				local last = word("`colName'",`count')
				local nextlast = word("`colName'",`c2')

				while `end' == 0 {
					replace `leftLB`lcolsN'' = "`last'" + " " + `leftLB`lcolsN'' in `Nnew`line'' //`Nnew`line'' ONDOC
					local check = `leftLB`lcolsN''[`Nnew`line'' ] + " `nextlast'"	// what next will be

					local count = `count'-1
					local last = word("`colName'",`count')
					if "`last'" == ""{
						local end = 1
					}

					if length(`leftLB`lcolsN''[`Nnew`line'']) > `titleln'/`spread' | ///
					  length("`check'") > `titleln'/`spread' & "`first'" == "`nextlast'" {
						if `end' == 0{
							local line = `line'+1
						}
					}
				}
				if `line' > `maxline'{
					local maxline = `line'
				}
				mac shift
			}
		}
		if `titleOff' == 1	{ 
			forvalues i = 1/4{
				replace `leftLB1' = "" in `Nnew`i''  		// get rid of horrible __var name
			}
		}
			
		replace `leftLB1' = `label' if (`use' == -2 |`use' == 2 | `use' == 3)  	// put titles back in (overall, sub est etc.)

		if "`stats'" == "" {		
			gen `estTextse' = `estText'  if `se'== 1
			gen `estTextsp' = `estText' + " " if `se'== 0
			local rcols = "`estTextse' `estTextsp'" 
			label var `estTextse' "`plotstatse' (`level'% CI)"
			label var `estTextsp' "`plotstatsp' (`level'% CI)"
		}
		else {
			gen `extra1' = " "
			gen `extra2' = " "
			label var `extra1' " "
			label var `extra2' " "
			local rcols = "`extra1' `extra2'" 
		}

		local rcolsN = 0
		if "`rcols'" != "" {
			tokenize "`rcols'"
			local rcolsN = 0
			while "`1'" != "" {
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
				if _rc != 0 {
					local f: format `1'
					gen str `rightLB`rcolsN'' = string(`1', "`f'")
					replace `rightLB`rcolsN'' = "" if `rightLB`rcolsN'' == "."
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
				qui summ `tmpln' if `use' != 0
				local otherln = r(max)
				drop `tmpln'
				// NOW HAVE LENGTH OF TITLE AND MAX LENGTH OF VARIABLE
				local spread = int(`titleln'/`otherln')+1
				if `spread' > 4{
					local spread = 4
				}

				local line = 1
				local end = 0
				local count = -1
				local c2 = -2

				local first = word("`colName'",1)
				local last = word("`colName'",`count')
				local nextlast = word("`colName'",`c2')

				while `end' == 0 {
					replace `rightLB`rcolsN'' = "`last'" + " " + `rightLB`rcolsN'' in `Nnew`line''
					local check =  `rightLB`rcolsN''[`Nnew`line''] + " `nextlast'"	// what next will be 

					local count = `count'-1
					local last = word("`colName'",`count')
					if "`last'" == ""{
						local end = 1
					}
					if length(`rightLB`rcolsN''[`Nnew`line'']) > `titleln'/`spread' | ///
					  length("`check'") > `titleln'/`spread' & "`first'" == "`nextlast'" {
						if `end' == 0{
							local line = `line' +1
						}
					}
				}
				if `line' > `maxline' { 
					local maxline = `line' 
				}
				mac shift
			}
		}

		// now get rid of extra title rows if they weren't used
		if `maxline'==3 {
			drop in `Nnew4' 
		}
		if `maxline'==2 {
			drop in `Nnew3'/`Nnew4' 
		}
		if `maxline'==1 {
			drop in `Nnew2'/`Nnew4' 
		}
		
		count if !`flag'
		forvalues i = 1/`maxline' {	// up to four lines for titles
			local multip = 1
			local add = 0
			local idNew`i' = `i'
			local Nnew`i' = r(N)+`i' 
			local tmp = `Nnew`i''
			replace `id' = `maxline' -`idNew`i'' + 1  in `tmp'
			replace `use' = 0 in `tmp'
			if `i' == `maxline' {
				local borderline = `idNew`i'' + 0.75
			}
		}
		summ `id' if `flag'
		local max = ceil(r(max))
		replace `id' = `id' + `max' if `flag'==0
		replace `expand' = 1
		replace `expand' = 2 if `flag' 
		replace `se' = 0 if `se' == .
		count if `expand' > 1
		local nnewlines = r(N)
		expand `expand'
		replace `se' = 1 in `=_N - `nnewlines' + 1'/`=_N'
		replace `use' = -2 if `flag'
		sort `id' `se'
		
		local skip = 1
		if "`stats'" == "" {				// sort out titles for stats and weight, if there
			local skip = 3
		}
		if "`stats'" != "" {
			local skip = 2
		}

		replace `rightLB1' = "" if (`se' == 0)
		replace `rightLB2' = "" if (`se' == 1)
		
		forvalues i = 1/`lcolsN'{
			replace `leftLB`i'' = "" if (`se' == 0)
		}
		
		local leftWDtot = 0
		local rightWDtot = 0
		forvalues i = 1/`lcolsN'{
			getWidth `leftLB`i'' `leftWD`i''
			qui summ `leftWD`i''
			local maxL = r(max)
			local leftWDtot = `leftWDtot' + `maxL'
			replace `leftWD`i'' = `maxL'
			local leftWD`i' = `maxL' 
		}
		forvalues i = 1/`rcolsN'{
			getWidth `rightLB`i'' `rightWD`i''
			qui summ `rightWD`i'' 
			replace `rightWD`i'' = r(max)
			local rightWD`i' = r(max)
			local rightWDtot = `rightWDtot' + r(max)
		}
	
		local LEFT_WD = `leftWDtot'
		local RIGHT_WD = `rightWDtot'
		local ratio = `astext'		// USER SPECIFIED- % OF GRAPH TAKEN BY TEXT (ELSE NUM COLS CALC?)
		local textWD = ((2*`DXwidth')/(1-`ratio'/100)-(2*`DXwidth')) /(`leftWDtot'+`rightWDtot')
	
		local AXmin = `DXmin1' - `leftWDtot'*`textWD'
		local AXmax = `DXmax1' + `DXwidth' + `rightWDtot'*`textWD'
	
		local step 0
		forvalues i = 1/`lcolsN'{
			gen `left`i'' = `AXmin' + `step'
			local step = `leftWD`i''*`textWD' + `step'
		}
		
		local DXmin2 = `DXmax1' + `rightWD1'*`textWD'
		local DXmax2 = `DXmin2'  + `DXwidth'
		
		gen `right1' = `DXmax1'
		gen `right2' = `DXmax2'
		
		*replace `effect' = `effect' + `DXmax1' - `DXmin1'  + 0.5*`rightWDtot'*`textWD'  if !`se'
		*replace `lci' = `lci' + `DXmax1' - `DXmin1' + 0.5*`rightWDtot'*`textWD'  if !`se'
		*replace `uci' = `uci' + `DXmax1' - `DXmin1' + 0.5*`rightWDtot'*`textWD'  if !`se'	
		
		/* 16-09-2020
		replace `effect' = `effect' + `DXmin2'   if !`se'
		replace `lci' = `lci' + `DXmin2' if !`se'
		replace `uci' = `uci' + `DXmin2' if !`se'
		*/
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

		replace `DIAMleftX' = `DXmin1' if (`lci' < `DXmin1' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMleftX' = . if (`effect' < `DXmin1' ) & (`use' == 2 | `use' == 3) 
		//If one study, no diamond
		replace `DIAMleftX' = . if (`df' < 2) & (`use' == 2 | `use' == 3) 
		
		replace `DIAMleftY1' = `id' + 0.4*(abs((`DXmin1' -`lci')/(`effect'-`lci'))) if (`lci' < `DXmin1' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMleftY1' = . if (`effect' < `DXmin1' ) & (`use' == 2 | `use' == 3) 
	
		replace `DIAMleftY2' = `id' - 0.4*( abs((`DXmin1' -`lci')/(`effect'-`lci')) ) if (`lci' < `DXmin1' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMleftY2' = . if (`effect' < `DXmin1' ) & (`use' == 2 | `use' == 3) 
		
		replace `DIAMrightX' = `DXmax`r'' if (`uci' > `DXmax1' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMrightX' = . if (`effect' > `DXmax1' ) & (`use' == 2 | `use' == 3) 
		//If one study, no diamond
		replace `DIAMrightX' = . if (`df' == 1) & (`use' == 2 | `use' == 3) 
	
		replace `DIAMrightY1' = `id' + 0.4*( abs((`uci'-`DXmax1' )/(`uci'-`effect')) ) if (`uci' > `DXmax1' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMrightY1' = . if (`effect' > `DXmax1' ) & (`use' == 2 | `use' == 3) 

		replace `DIAMrightY2' = `id' - 0.4*( abs((`uci'-`DXmax1' )/(`uci'-`effect')) ) if (`uci' > `DXmax1' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMrightY2' = . if (`effect' > `DXmax1' ) & (`use' == 2 | `use' == 3) 

		replace `DIAMbottomY' = `id' - 0.4*( abs((`uci'-`DXmin1' )/(`uci'-`effect')) ) if (`effect' < `DXmin1' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMbottomY' = `id' - 0.4*( abs((`DXmax1' -`lci')/(`effect'-`lci')) ) if (`effect' > `DXmax1' ) & (`use' == 2 | `use' == 3) 

		replace `DIAMtopY' = `id' + 0.4*( abs((`uci'-`DXmin1' )/(`uci'-`effect')) ) if (`effect' < `DXmin1' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMtopY' = `id' + 0.4*( abs((`DXmax1' -`lci')/(`effect'-`lci')) ) if (`effect' > `DXmax1' ) & (`use' == 2 | `use' == 3) 

		replace `DIAMtopX' = `DXmin1'  if (`effect' < `DXmin1' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMtopX' = `DXmax1'  if (`effect' > `DXmax1' ) & (`use' == 2 | `use' == 3) 
		replace `DIAMtopX' = . if ((`uci' < `DXmin1' ) | (`lci' > `DXmax1' )) & (`use' == 2 | `use' == 3) 
	
		gen `DIAMbottomX' = `DIAMtopX'

	} // END QUI

	forvalues i = 1/`lcolsN'{
		local lcolCommands`i' "(scatter `id' `left`i'', msymbol(none) mlabel(`leftLB`i'') mlabcolor(black) mlabpos(3) mlabsize(`texts'))"
	}

	forvalues i = 1/`rcolsN' {
		local rcolCommands`i' "(scatter `id' `right`i'', msymbol(none) mlabel(`rightLB`i'') mlabcolor(black) mlabpos(3) mlabsize(`texts'))"
	}
	
	if `"`diamopt'"' == "" {
		local diamopt "lcolor("255 0 0")"
	}
	else {
		if strpos(`"`diamopt'"',"hor") != 0 | strpos(`"`diamopt'"',"vert") != 0 {
			di as error "Options horizontal/vertical not allowed in diamopt()"
			exit
		}
		if strpos(`"`diamopt'"',"con") != 0{
			di as error "Option connect() not allowed in diamopt()"
			exit
		}
		if strpos(`"`diamopt'"',"lp") != 0{
			di as error "Option lpattern() not allowed in diamopt()"
			exit
		}
		local diamopt `"`diamopt'"'
	}
	//Point options
	if `"`pointopt'"' != "" & strpos(`"`pointopt'"',"msy") == 0{
		local pointopt = `"`pointopt' msymbol(O)"' 
	}
	if `"`pointopt'"' != "" & strpos(`"`pointopt'"',"msi") == 0{
		local pointopt = `"`pointopt' msize(vsmall)"' 
	}
	if `"`pointopt'"' != "" & strpos(`"`pointopt'"',"mc") == 0{
		local pointopt = `"`pointopt' mcolor(black)"' 
	}
	if `"`pointopt'"' == ""{
		local pointopt "msymbol(O) msize(vsmall) mcolor("0 0 0")"
	}
	else{
		local pointopt `"`pointopt'"'
	}
	// CI options
	if `"`ciopt'"' == "" {
		local ciopt "lcolor("0 0 0")"
	}
	else {
		if strpos(`"`ciopt'"',"hor") != 0 | strpos(`"`ciopt'"',"ver") != 0{
			di as error "Options horizontal/vertical not allowed in ciopt()"
			exit
		}
		if strpos(`"`ciopt'"',"con") != 0{
			di as error "Option connect() not allowed in ciopt()"
			exit
		}
		if strpos(`"`ciopt'"',"lp") != 0{
			di as error "Option lpattern() not allowed in ciopt()"
			exit
		}
		if `"`ciopt'"' != "" & strpos(`"`ciopt'"',"lc") == 0{
			local ciopt = `"`ciopt' lcolor("0 0 0")"' 
		}
		local ciopt `"`ciopt'"'
	}
	// Arrow options
	if `"`arrowopt'"' == "" {
		local arrowopt "mcolor("0 0 0") lstyle(none)"
	}
	else {
		local forbidden "connect horizontal vertical lpattern lwidth lcolor lsytle"
		foreach option of local forbidden {
			if strpos(`"`arrowopt'"',"`option'")  != 0 {
				di as error "Option `option'() not allowed in arrowopt()"
				exit
			}
		}
		if `"`arrowopt'"' != "" & strpos(`"`arrowopt'"',"mc") == 0{
			local arrowopt = `"`arrowopt' mcolor("0 0 0")"' 
		}
		local arrowopt `"`arrowopt' lstyle(none)"'
	}

	// END GRAPH OPTS

	tempvar tempOv overrallLine ovMin ovMax h0Line
	
	if `"`olineopt'"' == "" {
		local olineopt "lwidth(thin) lcolor(red) lpattern(shortdash)"
	}
	if `"`vlineopt'"' == "" {
		local vlineopt "lwidth(thin) lcolor(black) lpattern(solid)"
	}
	qui summ `id'
	local DYmin = r(min)
	local DYmax = r(max)+2
	
	forvalues r= 1(1)2 {
		qui summ `effect' if `use' == 3 & `se' == `=2 - `r''
		local overall`r' = r(max)
		/*if `r'== 2 {
			local overall2 =  `overall`r'' + `DXmin2'  
		}
		local overallCommand`r' `" (pci `=`DYmax'-2' `overall`r'' `borderline' `overall`r'', `olineopt') "'
		*/
						
		if `overall`r'' > `DXmax1' | `overall`r'' < `DXmin1' | "`ovline'" != "" {	// ditch if not on graph
			local overallCommand`r' ""
		}
		else {
			if `r'== 2 {
				local overall`r' =  `overall`r'' + `DXmin2' - `DXmin1'
			}
			local overallCommand`r' `" (pci `=`DYmax'-2' `overall`r'' `borderline' `overall`r'', `olineopt') "'
		
		}
		if "`ovline'" != "" {
			local overallCommand`r' ""
		}
		if "`subline'" != "" & "`groupvar'" != "" {
			local sublineCommand`r' ""
			
			qui label list `groupvar'
			local nlevels = r(max)
			forvalues l = 1/`nlevels' {
				qui summ `effect' if `use' == 2  & `groupvar' == `l' & (`se' == `=`r' - 1')
				local tempSub`l' = r(mean)
				if `r'== 1 {
					local tempSub`l' = `tempSub`l'' + `DXmin2' - `DXmin1'
				}
				qui summ `id' if `use' == 1 & `groupvar' == `l'
				local subMax`l' = r(max) + 1
				local subMin`l' = r(min) - 2
				qui count if `use' == 1 & `groupvar' == `l' & (`se' == `=`r' - 1')
				if r(N) > 1 {
					local sublineCommand`r' `" `sublineCommand`r'' (pci `subMin`l'' `tempSub`l'' `subMax`l'' `tempSub`l'', `olineopt')"'
				}
			}
		}
		else {
			local sublineCommand`r' ""
		}
	}
	if `"`xline'"' != `""' {
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
			if "`3'" != "" {
				local xlineopts = "`3'"
			}
			else {
				local xlineopts = "lcolor(black)"
			}
			local xlineval2 =  `xlineval' + `DXmin2' - `DXmin1'
			local vlineCommand1 `" (pci `=`DYmax'-2' `xlineval' `borderline' `xlineval', `xlineopts') "'
			local vlineCommand2 `" (pci `=`DYmax'-2' `xlineval2' `borderline' `xlineval2', `xlineopts') "'
			
			if (`xlineval' > `DXmax1' | `xlineval' < `DXmin1') & "`xline'" != "" {	// ditch if not on graph
				local vlineCommand1 ""
				local vlineCommand2 ""
			}
		}

	qui {
		//Generate indicator on direction of the off-scale arro
		tempvar rightarrow leftarrow biarrow noarrow rightlimit leftlimit offRhiY offRhiX offRloY offRloX offLloY offLloX offLhiY offLhiX
		gen `rightarrow' = 0
		gen `leftarrow' = 0
		gen `biarrow' = 0
		gen `noarrow' = 0
		
		replace `rightarrow' = 1 if ///
			(((round(`uci', 0.001) > round(`DXmax1' , 0.001)) & (round(`lci', 0.001) >= round(`DXmin1' , 0.001)))  |  ///	
			((round(`uci', 0.001) > round(`DXmax1' , 0.001)) & (round(`lci', 0.001) > round(`DXmax1' , 0.001))))  &  ///
			(`use' == 1) & (`uci' != .) & (`lci' != .)
			
			
		replace `leftarrow' = 1 if ///
			(((round(`lci', 0.001) < round(`DXmin1' , 0.001)) & (round(`uci', 0.001) <= round(`DXmax1' , 0.001))) | ///
			((round(`lci', 0.001) < round(`DXmin1' , 0.001)) & (round(`uci', 0.001) < round(`DXmin1' , 0.001)))) & ///
			(`use' == 1) & (`uci' != .) & (`lci' != .)
		
		replace `biarrow' = 1 if ///
			(round(`lci', 0.001) < round(`DXmin1' , 0.001)) & ///
			(round(`uci', 0.001) > round(`DXmax1' , 0.001)) & ///
			(`use' == 1) & (`uci' != .) & (`lci' != .)
			
		replace `noarrow' = 1 if ///
			(`leftarrow' != 1) & (`rightarrow' != 1) & (`biarrow' != 1) & ///
			(`use' == 1) & (`uci' != .) & (`lci' != .)	

		replace `lci' = `DXmin1'  if (round(`lci', 0.001) < round(`DXmin1' , 0.001)) & (`lci' !=.) & (`use' == 1) 
		replace `uci' = `DXmax1'  if (round(`uci', 0.001) > round(`DXmax1' , 0.001)) & (`uci' !=.) & (`use' == 1) 
		
		replace `lci' = `DXmax1' - 0.00001  if (round(`lci', 0.001) > round(`DXmax1' , 0.001)) & (`lci' !=. ) & (`use' == 1) 
		replace `uci' = `DXmin1' + 0.00001  if (round(`uci', 0.001) < round(`DXmin1' , 0.001)) & (`uci' !=. ) & (`use' == 1) 
		
		*replace `lci' = . if (round(`lci', 0.001) > round(`DXmax1' , 0.001)) & (`lci' !=. ) & (`use' == 1) 
		*replace `uci' = . if (round(`uci', 0.001) < round(`DXmin1' , 0.001)) & (`uci' !=. ) & (`use' == 1) 

		replace `effect' = . if (round(`effect', 0.001) < round(`DXmin1' , 0.001)) & (`use' == 1) 
		replace `effect' = . if (round(`effect', 0.001) > round(`DXmax1' , 0.001)) & (`use' == 1)

		summ `id'
		local xaxislineposition = r(max)

		local xaxis1 "(pci `xaxislineposition' `DXmin1' `xaxislineposition' `DXmax1', lwidth(thin) lcolor(black))"
		local xaxis2 "(pci `xaxislineposition' `DXmin2' `xaxislineposition' `DXmax2', lwidth(thin) lcolor(black))"
		
		/*Xaxis 1 title */
		local xaxistitlex1 `=(`DXmax1' + `DXmin1')*0.5'
		local xaxistitlex2 `=(`DXmax2' + `DXmin2')*0.5'
		local xaxistitle1  (scatteri `=`xaxislineposition' + 2.25' `xaxistitlex1' "`plotstatse'", msymbol(i) mlabcolor(black) mlabpos(0) mlabsize(`texts'))
		local xaxistitle2  (scatteri `=`xaxislineposition' + 2.25' `xaxistitlex2' "`plotstatsp'", msymbol(i) mlabcolor(black) mlabpos(0) mlabsize(`texts'))
		
		/*xticks*/
		local ticksx1
		local ticksx2
		tokenize "`xtick'", parse(",")	
		while "`1'" != "" {
			if "`1'" != "," {
				forvalues r=1(1)2 {
					local where = `1'
					if `r' == 2 {          
						local where = `1' + `DXmin2' - `DXmin1'
					}
					local ticksx`r' "`ticksx`r'' (pci `xaxislineposition'  `where' 	`=`xaxislineposition'+.25' 	`where' , lwidth(thin) lcolor(black)) "
				}
			}
			macro shift 
		}
		/*labels*/
		local xaxislabels
		tokenize `lblcmd'
		while "`1'" != ""{
			forvalues r = 1(1)2 {
				local where = `1'
				if `r' == 2 {
					*local where = `1' + `DXmax1' - `DXmin1' + 0.5*`rightWDtot'*`textWD' 
					local where = `1' + `DXmin2' - `DXmin1'
				}
				local xaxislabels`r' "`xaxislabels`r'' (scatteri `=`xaxislineposition'+1' `where' "`2'", msymbol(i) mlabcolor(black) mlabpos(0) mlabsize(`texts'))"
			}
			macro shift 2
		}
		if "`grid'" != "" {
			tempvar gridy gridxmax gridxmin
			
			gen `gridy' = `id' + 0.5
			gen `gridxmax' = `AXmax'
			gen `gridxmin' = `left1'
			local betweengrids "(pcspike `gridy' `gridxmin' `gridy' `gridxmax'  if `use' == 1 , lwidth(vvthin) lcolor(gs12))"	
		}
		
		//Shift the position of sensitivitiy plot
		replace `lci' = `lci' + `DXmin2' - `DXmin1' if !`se' 
		replace `uci' = `uci' + `DXmin2' - `DXmin1' if !`se' 
		replace `effect' = `effect' + `DXmin2' - `DXmin1' if !`se' 
		
		replace `DIAMbottomX' = `DIAMbottomX' + `DXmin2' - `DXmin1' if !`se' 
		replace `DIAMtopX' = `DIAMtopX' + `DXmin2' - `DXmin1' if !`se' 
		replace `DIAMleftX' = `DIAMleftX' + `DXmin2' - `DXmin1' if !`se' 
		replace `DIAMrightX' = `DIAMrightX' + `DXmin2' - `DXmin1' if !`se' 			
	}	// end qui	
	/*===============================================================================================*/
	/*====================================  GRAPH    ================================================*/
	/*===============================================================================================*/
		
	#delimit ;
	twoway
	 /*NOTE FOR RF, AND OVERALL LINES FIRST */ 
		`notecmd' `overallCommand1' `sublineCommand1' `overallCommand2' `sublineCommand2' `hetGroupCmd'  `xaxis1' `xaxistitle1' 
		`ticksx1' `xaxislabels1'  `xaxis2' `xaxistitle2'  `ticksx2' `xaxislabels2' `vlineCommand1' `vlineCommand2'
	 /*COLUMN VARIABLES */
		`lcolCommands1' `lcolCommands2' `lcolCommands3' `lcolCommands4' `lcolCommands5' `lcolCommands6'
		`lcolCommands7' `lcolCommands8' `lcolCommands9' `lcolCommands10' `lcolCommands11' `lcolCommands12'
		`rcolCommands1' `rcolCommands2' 
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
		(pcspike `id' `lci' `id' `uci' if `use' == 1 , `ciopt')	
	 /*ADD ARROWS  `ICICmd1' `ICICmd2' `ICICmd3'*/
		(pcarrow `id' `uci' `id' `lci' if `leftarrow' == 1 , `arrowopt')	
		(pcarrow `id' `lci' `id' `uci' if `rightarrow' == 1 , `arrowopt')	
		(pcbarrow `id' `lci' `id' `uci' if `biarrow' == 1 , `arrowopt')	
	 /*DIAMONDS FOR SUMMARY ESTIMATES -START FROM 9 O'CLOCK */
		(pcspike `DIAMleftY1' `DIAMleftX' `DIAMtopY' `DIAMtopX' if (`use' == 2 | `use' == 3) , `diamopt')
		(pcspike `DIAMtopY' `DIAMtopX' `DIAMrightY1' `DIAMrightX' if (`use' == 2 | `use' == 3) , `diamopt')
		(pcspike `DIAMrightY2' `DIAMrightX' `DIAMbottomY' `DIAMbottomX' if (`use' == 2 | `use' == 3) , `diamopt')
		(pcspike `DIAMbottomY' `DIAMbottomX' `DIAMleftY2' `DIAMleftX' if (`use' == 2 | `use' == 3) , `diamopt') 
	 /*LAST OF ALL PLOT EFFECT MARKERS TO CLARIFY  */
		(scatter `id' `effect' if `use' == 1 , `pointopt')		
		,`foptions' name(fplot, replace)
		;
		#delimit cr		
			
		if "$by_index_" != "" {
			qui graph dir
			local gnames = r(list)
			local gname: word $by_index_ of `gnames'
			tokenize `gname', parse(".")
			if "`3'" != "" {
				local ext =".`3'"
			}
			
			qui graph rename fplot`ext' fplot$by_index_`ext', replace
		}
		if `"`graphsave'"' != `""' {
			di _n
			noi graph save `graphsave', replace
		}			
		
end

/*==================================== GETWIDTH  ================================================*/
/*===============================================================================================*/
capture program drop getWidth
program define getWidth
version 14.0
//From metaprop

qui{
	gen `2' = 0
	count
	local N = r(N)
	forvalues i = 1/`N'{
		local this = `1'[`i']
		local width: _length "`this'"
		replace `2' =  `width' +1 in `i'
	}
} 

end
/*+++++++++++++++++++	SUPPORTING FUNCTIONS: SROC ++++++++++++++++++++++++++++++++++++
				   DRAW THE SROC CURVES, CROSSES, CONFIDENCE & PREDICTION REGION
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	cap program drop sroc
	program define sroc
		version 14.0

		#delimit ;
		syntax varlist,	
			selogodds(name) /*Log odds for se*/
			splogodds(name) /*Log odds for sp*/
			v(name) /*Var-cov for log odds se & se*/
			bvar(name) /*Between study var-cov*/
			model(string) /*model*/
			[
			groupvar(name) /*Grouping variable*/
			p(integer 0) /*No of parameters in the regression equation*/
			cimethod(string) /*How to compute the study-specific CI*/
			LEVel(integer 95) /*Significance level*/
			
			COLorpalette(string) /*soptions: Colors seperated by space*/
			noPREDiction  /*soptions:no Prediction region*/
			noCURve  /*soptions:no curve*/
			Bubbles /*soptions: size of study by bubbles*/
			BUBbleid /*soptions: Identify the bubbles by index*/
			SPointopt(string) /*soptions: options study points*/
			OPointopt(string) /*soptions: options the overall summary points*/
			CUrveopt(string) /*soptions: options the CI points*/
			CIopt(string) /*soptions: options the CI points*/
			PREDCIopt(string) /*soptions: options the PREDCI points*/
			BUBOpt(string) /*soptions: options the bubble points*/
			BIDopt(string) /*soptions: options the bubble ID points*/
			GRAPHSave(string asis)
			STRAtify  /*Stratify*/
			* /*soptions:Other two-way options*/
			]
			;
		#delimit cr
		tempvar se selci seuci sp splci spuci csp Ni rowid Dis tp fp NDis fn tn mu gvar
		tempname vi bvari
		
		local soptions `"`options'"'
		
		tokenize `varlist'
		gen `tp' = `1'
		gen `fp' = `2'
		gen `fn' = `3'
		gen `tn' = `4'
		gen `Dis' = (`tp' + `fn')
		gen `NDis' = (`fp' + `tn')		
		gen `Ni' = `Dis' +`NDis'
		gen `rowid' = _n
		
		if "`groupvar'" != "" {
			my_ncod `gvar', oldvar(`groupvar') //
		}
		//CI
		metadta_propci `Dis' `tp', p(`se') lowerci(`selci') upperci(`seuci') cimethod(`cimethod') level(`level')
		metadta_propci `NDis' `tn', p(`sp') lowerci(`splci') upperci(`spuci') cimethod(`cimethod') level(`level')
		
		gen `csp' = 1 - `sp'				
		
		/*If categorical variable, obtain the sroc and the drawing parameters for each level*/
		if "`groupvar'" != "" {
			qui label list `gvar'
			local nlevels = r(max)
		}
		else {
			gen `gvar' = 1
			local nlevels = 1
		}
		if "`colorpalette'" == "" {
			local colorpalette  "black forest_green cranberry blue sienna orange emerald magenta dknavy gray purple"
		}
		else {
			local kcolors : word count `colorpalette'
			if (`kcolors' < `nlevels') {
				di as error "Please specify the colours to be used for all the `nlevels' levels of `gvar'" 
				di as error "colours should be separated by space in the colorpalette() option"
				exit
			}
		}
		local index 0
		local centre
		local kross
		local sroc
		local points
		local rings
		local idbubble
		local cregion
		local pregion
		local legendlabel
		local legendorder
		/*Options*/
		// CI options
		if `"`ciopt'"' == "" {
			local ciopt "lpattern(dash)"
		}
		else {
			local forbidden "lcolor"
			foreach option of local forbidden {
				if strpos(`"`ciopt'"',"`option'")  != 0 {
					di as error "Option `option'() not allowed in ciopt()"
					exit
				}
			}
		}
		
		// PREDCI options
		if `"`predciopt'"' == "" {
			local predciopt "lpattern(-.)"
		}
		else {
			local forbidden "lcolor"
			foreach option of local forbidden {
				if strpos(`"`predciopt'"',"`option'")  != 0 {
					di as error "Option `option'() not allowed in predciopt()"
					exit
				}
			}
			if `"`predciopt'"' != "" & strpos(`"`predciopt'"',"lpattern") == 0{
				local predciopt = `"`predciopt' lpattern(-.)"' 
			}
		}
		
		// Overall Point options
		if `"`opointopt'"' == "" {
			local opointopt "msymbol(D)"
		}
		else {
			local forbidden "mcolor"
			foreach option of local forbidden {
				if strpos(`"`opointopt'"',"`option'")  != 0 {
					di as error "Option `option'() not allowed in opointopt()"
					exit
				}
			}
			if `"`opointopt'"' != "" & strpos(`"`opointopt'"',"msymbol") == 0{
				local opointopt = `"`opointopt' msymbol(D)"' 
			}
		}
		
		// Study point options
		if `"`spointopt'"' == "" {
			local spointopt "msymbol(o)"
		}
		else {
			local forbidden "mcolor"
			foreach option of local forbidden {
				if strpos(`"`spointopt'"',"`option'")  != 0 {
					di as error "Option `option'() not allowed in spointopt()"
					exit
				}
			}
			if `"`spointopt'"' != "" & strpos(`"`spointopt'"',"msymbol") == 0{
				local spointopt = `"`spointopt' msymbol(o)"' 
			}
		}
		
		// Curve options
		if `"`curveopt'"' != "" {
			local forbidden "lcolor"
			foreach option of local forbidden {
				if strpos(`"`curveopt'"',"`option'")  != 0 {
					di as error "Option `option'() not allowed in curveopt()"
					exit
				}
			}
		}
		
		// Bubble options
		if `"`bubopt'"' == "" {
			local bubopt "msymbol(Oh)"
		}
		else {
			local forbidden "mcolor"
			foreach option of local forbidden {
				if strpos(`"`bubopt'"',"`option'")  != 0 {
					di as error "Option `option'() not allowed in bubopt()"
					exit
				}
			}
			if `"`bubopt'"' != "" & strpos(`"`bubopt'"',"msymbol") == 0{
				local bubopt = `"`bubopt' msymbol(Oh)"' 
			}
		}
		
		//Bubble ID options
		if `"`bidopt'"' == "" {
			local bidopt "mlabsize(`texts') msymbol(i) mlabel(`rowid')"
		}
		else {
			local forbidden "mcolor mlabcolor "
			foreach option of local forbidden {
				if strpos(`"`bidopt'"',"`option'")  != 0 {
					di as error "Option `option'() not allowed in bidopt()"
					exit
				}
			}
			if `"`bidopt'"' != "" & strpos(`"`bidopt'"',"mlabsize") == 0{
				local bidopt = `"`bidopt' mlabsize(`texts')"' 
			}
			if `"`bidopt'"' != "" & strpos(`"`bidopt'"',"msymbol") == 0{
				local bidopt = `"`bidopt' msymbol(i)"' 
			}
			if `"`bidopt'"' != "" & strpos(`"`bidopt'"',"mlabel") == 0{
				local bidopt = `"`bidopt' mlabel(`rowid')"' 
			}
		}
	
		qui {
			local already 0
			if `p' > 1 {
					local nrows = rowsof(`splogodds')
					local ovindex = rowsof(`v')
				}
				
			mat `bvari' = (`bvar'[1 ,1], `bvar'[1, 7] \ `bvar'[1, 7], `bvar'[1, 3])
			mat `vi' = `v'
			
			forvalues j=1/`nlevels' {
				
				*Take out the right matrix
				if "`stratify'" != "" {
					mat `bvari' = (`bvar'[`j' ,1], `bvar'[`j', 7] \ `bvar'[`j', 7], `bvar'[`j', 3])
					mat `vi' = (`v'[`=2*`j' - 1' ,1], `v'[`=2*`j' - 1' ,2] \ `v'[`=2*`j'',1], `v'[`=2*`j'',2])

				}
			
				local color:word `j' of `colorpalette'
				qui count if `gvar' == `j'
				//Centre
				if r(N) > 1 {
					if `p' > 1 {
						local mux`j' = 1 - invlogit(`splogodds'[`nrows', 1])
						local muy`j' = invlogit(`selogodds'[`nrows', 1])
					}
					else{
						local mux`j' = 1 - invlogit(`splogodds'[`j', 1])
						local muy`j' = invlogit(`selogodds'[`j', 1])
					}
				}
				else {						
					qui summ `sp' if `gvar' == `j'
					local mux`j' = 1 - r(mean)
					
					qui summ `se' if `gvar' == `j'
					local muy`j' = r(mean)
				}
				local centre `"`centre' (scatteri `muy`j'' `mux`j'', mcolor(`color') `opointopt')"'
				if `nlevels' == 1 {
					local ++index
					local legendlabel `"lab(`index' "Summary point") `legendlabel'"'
					local legendorder `"`index'  `legendorder'"'				
				}
				//Crosses
				if "`model'" == "fixed" | (r(N) < 3 & "`model'" == "random" ){ 
					if r(N) > 1 {
						if `p' > 1 {
							local leftX`j' = 1 - invlogit(`splogodds'[`nrows', 6])
							local leftY`j' = invlogit(`selogodds'[`nrows', 1])
							
							local rightX`j' = 1 - invlogit(`splogodds'[`nrows', 5])
							local rightY`j' = invlogit(`selogodds'[`nrows', 1])
							
							local topX`j' = 1 - invlogit(`splogodds'[`nrows', 1])
							local topY`j' = invlogit(`selogodds'[`nrows', 6])
							
							local bottomX`j' = 1 - invlogit(`splogodds'[`nrows', 1])
							local bottomY`j' = invlogit(`selogodds'[`nrows', 5])
						}
						else{
							local leftX`j' = 1 - invlogit(`splogodds'[`j', 6])
							local leftY`j' = invlogit(`selogodds'[`j', 1])
							
							local rightX`j' = 1 - invlogit(`splogodds'[`j', 5])
							local rightY`j' = invlogit(`selogodds'[`j', 1])
							
							local topX`j' = 1 - invlogit(`splogodds'[`j', 1])
							local topY`j' = invlogit(`selogodds'[`j', 6])
							
							local bottomX`j' = 1 - invlogit(`splogodds'[`j', 1])
							local bottomY`j' = invlogit(`selogodds'[`j', 5])
						}
					}
					else {						
						qui summ `splci' if `gvar' == `j'
						local leftX`j' = 1 - r(mean)
						local leftY`j' = `muy`j''
						
						qui summ `spuci' if `gvar' == `j'
						local rightX`j' = 1 - r(mean)
						local rightY`j' = `muy`j''
						
						local topX`j' = `mux`j''
						qui summ `selci' if `gvar' == `j'
						local topY`j' =  r(mean)
						
						local bottomX`j' = `mux`j''
						qui summ `seuci' if `gvar' == `j'
						local bottomY`j' =  r(mean)
					}
					local kross `"`kross' (pci `leftY`j'' `leftX`j'' `rightY`j'' `rightX`j'', lcolor(`color') `ciopt') (pci `topY`j'' `topX`j'' `bottomY`j'' `bottomX`j'', lcolor(`color') `ciopt') "'
					if `nlevels' == 1 {
						local ++index
						local legendlabel `"lab(`index' "Confidence intervals") `legendlabel'"'
						local legendorder `"`index'  `legendorder'"'
						local ++index						
					}
				}
				else {
				//Confidence & prediction ellipses
					if !`already' {
						qui set obs 500
						local already 1
					}
					qui summ `csp' if `gvar' == `j' 
					local max`j' = min(0.9999, r(min))
					local min`j' = max(0.0001, r(max))
					local N`j' = r(N)
					
					tempvar fpr`j' sp`j' se`j' xcregion`j' ycregion`j' xpregion`j' ypregion`j'
					
					range `fpr`j'' `min`j'' `max`j''
					gen `sp`j'' = 1 - `fpr`j''
					
					/*HsROC parameters*/
					local b = (sqrt(`bvari'[2,2])/sqrt(`bvari'[1,1]))^0.5
					local beta = ln(sqrt(`bvari'[2,2]) / sqrt(`bvari'[1,1]))
					
					if `p' > 1 {
						local lambda = `b' * `selogodds'[`nrows', 1] + `splogodds'[`nrows', 1] / `b'
						local theta = 0.5 * (`b' * `selogodds'[`nrows', 1] -  `splogodds'[`nrows', 1]  /`b')

					}
					else {
						local lambda = `b' * `selogodds'[`j', 1] + `splogodds'[`j', 1] / `b'
						local theta = 0.5 * (`b' * `selogodds'[`j', 1] -  `splogodds'[`j', 1]  /`b')
					}
					
					local var_accu =  2*( sqrt(`bvari'[2,2]*`bvari'[1,1]) + `bvari'[2,1]) 
					local var_thresh = 0.5*( sqrt(`bvari'[2,2]*`bvari'[1,1]) - `bvari'[2,1]) 

					/*The curves*/
					if "`curve'" =="" {
						gen `se`j'' = invlogit(`lambda' * exp(-`beta' / 2) + exp(-`beta') * logit(`fpr`j''))
						local sroc "`sroc' (line `se`j'' `fpr`j'', lcolor(`color') `curveopt')"
						if `nlevels' == 1 {
							local ++index
							local legendlabel `"lab(`index' "SROC curve") `legendlabel'"'
							local legendorder `"`index'  `legendorder'"'					
						}
					}
					
					/*Joint confidence region*/
					local t = sqrt(2*invF(2, `=`N`j'' - 2', `level'/100))
					local nlen = 500
					if `p' > 1 {
						local rho = `vi'[`=2*`nrows'-1', `=2*`nrows'']/sqrt(`vi'[`=`ovindex'-1', `=`ovindex'-1']*`vi'[`=2*`nrows'', `=2*`nrows''])
					}
					else {
						local rho = `vi'[`j', `=`nlevels' + `j'']/sqrt(`vi'[`j', `j']*`vi'[`=`nlevels' + `j'', `=`nlevels' + `j''])
					}
					if "`stratify'" != "" {
						local rho = `vi'[1, 2]/sqrt(`vi'[1, 1]*`vi'[2, 2])
					}
					
					tempvar a 
					range `a' 0 2*_pi `nlen'
					if "`stratify'" != "" {
						gen `xcregion`j'' = 1 - invlogit(`splogodds'[`j', 1] + sqrt(`vi'[1, 1]) * `t' * cos(`a' + acos(`rho')))
						gen `ycregion`j'' = invlogit(`selogodds'[`j', 1] +  sqrt(`vi'[2, 2]) * `t' * cos(`a'))
					
					}
					else {
						if `p' > 1 {
							gen `xcregion`j'' = 1 - invlogit(`splogodds'[`nrows', 1] + sqrt(`vi'[`=`ovindex'-1', `=`ovindex'-1']) * `t' * cos(`a' + acos(`rho')))
							gen `ycregion`j'' = invlogit(`selogodds'[`nrows', 1] +  sqrt(`vi'[`ovindex', `ovindex']) * `t' * cos(`a'))
						}
						else {
							gen `xcregion`j'' = 1 - invlogit(`splogodds'[`j', 1] + sqrt(`vi'[`j', `j']) * `t' * cos(`a' + acos(`rho')))
							gen `ycregion`j'' = invlogit(`selogodds'[`j', 1] +  sqrt(`vi'[`=`nlevels' + `j'', `=`nlevels' + `j'']) * `t' * cos(`a'))
						}
					}

					local cregion `"`cregion' (line `ycregion`j'' `xcregion`j'', lcolor(`color') `ciopt')"'
					if `nlevels' == 1 {
						local ++index
						local legendlabel `"lab(`index' "Confidence region") `legendlabel'"'
						local legendorder `"`index'  `legendorder'"'					
					}
					
					/*Joint prediction region*/
					if "`prediction'" == "" {
						if `p' > 1 {
							local rho =  (`vi'[`=`ovindex'-1', `ovindex'] + `bvari'[1,2])/ sqrt((`vi'[`=`ovindex'-1', `=`ovindex'-1'] + `bvari'[2, 2]) * (`vi'[`ovindex', `ovindex'] + `bvari'[1, 1]))
						}
						else {
							local rho =  (`vi'[`=`nlevels' + `j'', `j'] + `bvari'[1,2])/ sqrt((`vi'[`j', `j'] + `bvari'[2, 2]) * (`vi'[`=`nlevels' + `j'', `=`nlevels' + `j''] + `bvari'[1, 1]))
						}
						if "`stratify'" != "" {
							local rho =  (`vi'[2, 1] + `bvari'[1,2])/ sqrt((`vi'[1, 1] + `bvari'[2, 2]) * (`vi'[2, 2] + `bvari'[1, 1]))
						}
						local d = acos(`rho')	
						if "`stratify'" != "" {
							gen `xpregion`j'' = 1 - invlogit(`splogodds'[`j', 1] + `t' * sqrt(`v'[1, 1] + `bvari'[2, 2]) * cos(`a' + acos(`rho')))
							gen `ypregion`j'' = invlogit(`selogodds'[`j', 1] +  sqrt(`vi'[2, 2] + `bvari'[1, 1]) * `t' * cos(`a'))
						}
						else {
							if `p' > 1 {
								gen `xpregion`j'' = 1 - invlogit(`splogodds'[`nrows', 1] + `t' * sqrt(`vi'[`=`ovindex'-1', `=`ovindex'-1'] + `bvari'[2, 2]) * cos(`a' + acos(`rho')))
								gen `ypregion`j'' = invlogit(`selogodds'[`nrows', 1] +  sqrt(`vi'[`ovindex', `ovindex'] + `bvari'[1, 1]) * `t' * cos(`a'))
							}
							else {
								gen `xpregion`j'' = 1 - invlogit(`splogodds'[`j', 1] + `t' * sqrt(`v'[`j', `j'] + `bvari'[2, 2]) * cos(`a' + acos(`rho')))
								gen `ypregion`j'' = invlogit(`selogodds'[`j', 1] +  sqrt(`vi'[`=`nlevels' + `j'', `=`nlevels' + `j''] + `bvari'[1, 1]) * `t' * cos(`a'))
							}
						}
						
						local pregion `"`pregion' (line `ypregion`j'' `xpregion`j'', `predciopt' lcolor(`color'))"'
						if `nlevels' == 1 {
							local ++index
							local legendlabel `"lab(`index' "Prediction region") `legendlabel'"'
							local legendorder `"`index'  `legendorder'"'					
						}
					}
				}
				if "`summaryonly'" =="" {
					if "`bubbles'" != "" {
					//bubbles
						local rings `"`rings' (scatter `se' `csp' [fweight = `Ni'] if `gvar' == `j',   mcolor(`color') `bubopt')"'
						
						if "`bubbleid'" != "" {
							local idbubble `"`idbubble' (scatter `se' `csp' if `gvar' == `j',  mcolor(`color') mlabcolor(`color') `bidopt')"'
						}
					}
					else {
					//points
						local points `"`points' (scatter `se' `csp' if `gvar' == `j',  mcolor(`color') `spointopt')"'
					}
					if `nlevels' == 1 {
						local ++index
						local legendlabel `"lab(`index' "Observed data") `legendlabel'"'
						local legendorder `"`index'  `legendorder'"'					
					}
				}
				if `nlevels' > 1 {
					local lab:label `gvar' `j' /*label*/
					local legendlabel `"lab(`j' "`lab'") `legendlabel'"'
					local legendorder `"`j'  `legendorder'"'
				}
			}
		}
		
		if strpos(`"`soptions'"', "legend") == 0 {
			local legendstr `"legend(order(`legendorder') `legendlabel' cols(1) ring(0) position(6))"'
		}
		if strpos(`"`soptions'"', "xscale") == 0 {
			local soptions `"xscale(range(0 1)) `soptions'"'
		}
		if strpos(`"`soptions'"', "yscale") == 0 {
			local soptions `"yscale(range(0 1)) `soptions'"'
		}
		if strpos(`"`soptions'"', "xtitle") == 0 {
			local soptions `"xtitle("1 - Specificity") `soptions'"'
		}
		if strpos(`"`soptions'"', "ytitle") == 0 {
			local soptions `"ytitle("Sensitivity") `soptions'"'
		}
		if strpos(`"`soptions'"', "xlabel") == 0 {
			local soptions `"xlabel(0(0.2)1) `soptions'"'
		}
		if strpos(`"`soptions'"', "ylabel") == 0 {
			local soptions `"ylabel(0(0.2)1, nogrid) `soptions'"'
		}
		if strpos(`"`soptions'"', "graphregion") == 0 {
			local soptions `"graphregion(color(white)) `soptions'"'
		}
		if strpos(`"`soptions'"', "plotregion") == 0 {
			local soptions `"plotregion(margin(medium)) `soptions'"'
		}
		if strpos(`"`soptions'"', "aspectratio") == 0 {
			local soptions `"aspectratio(1) `soptions'"'
		}
		if strpos(`"`soptions'"', "xsize") == 0 {
			local soptions `"xsize(5)  `soptions'"'
		}
		if strpos(`"`soptions'"', "ysize") == 0 {
			local soptions `"ysize(5)  `soptions'"'
		}
		
		#delimit ;
		graph tw 
			`centre'
			`kross'
			`sroc'
			`cregion'
			`pregion'
			`points'
			`rings'
			`idbubble'
			,
			`legendstr' `soptions' name(sroc, replace)
		;
		#delimit cr
		if "$by_index_" != "" {
			qui graph dir
			local gnames = r(list)
			local gname: word $by_index_ of `gnames'
			tokenize `gname', parse(".")
			if "`3'" != "" {
				local ext =".`3'"
			}
			
			qui graph rename sroc`ext' sroc$by_index_`ext', replace
			
		}
		
		if `"`graphsave'"' != `""' {
			di _n
			noi graph save `graphsave', replace
		}
		

	end

