*! version 2.5  1/26/2021
version 13.1
cap program drop rctable
program define rctable
set more off
syntax [varlist] [using] [if] [pw aw fw], TREATment(varlist) [CONTrol(varlist fv) BASEControl(varlist) CLUSTer(varlist)  ESTimator(namelist) treated(varlist) PValue keep QValue(name) quiet latex sd sheet(string asis)]
pause on

quiet{
	
if "`pvalue'"!="" & 	"`qvalue'"!="" { 
	
	dis as error  "Cannot specify both p and q values"
			exit 100
}
	
if "`keep'"=="" {
	preserve
	foreach cvar in VAR LAB  N_ind N_clust A C COEF*  {
	capture confirm variable `cvar'
		if !_rc {
			dis as error  "Dataset should not include the following variables: VAR LAB  N_ind N_clust A C COEF* PVAL "
			exit 100
        }
	}
             
	quiet for any  VAR LAB  N_ind N_clust A C COEF* : cap drop X 
}

if "`qvalue'" !=""  {
	cap which qqvalue
	if _rc ssc install qqvalue
	if   "`qvalue'" =="bky" | "`qvalue'" =="bonferroni" | "`qvalue'" =="sidak" | "`qvalue'" =="holm" | "`qvalue'" =="holland" | "`qvalue'" =="hochberg" | "`qvalue'" =="simes" | "`qvalue'" =="yekutieli"{ 
		dis "Qvalues are based on `qvalue'" 
	}
	else { 
		dis as error `"Unrecognised method `qvalue' "'
	}
}


local c=1
foreach i in `treatment'  {
	quiet: gen COEF`c' ="" 
	local c=`c'+1
}

local c=`c'-1
	
forval h=1/`c' {
	local COEFS "`COEFS' COEF`h'"
	if `h'==1 { 
	local COEFS_tex "T`h'"
	}
	else{ 
	local COEFS_tex "`COEFS_tex' & T`h' "		
	}
}

foreach i in VAR LAB   A C N_ind N_clust  {
	 quiet: gen `i'=""
}


*** Add additional lines if number of test   > number of observations 
cap set obs `=wordcount("`varlist'")*3+5'

}	 
local pvalues=""
local j=1
local k=1
foreach i in `varlist' {
	
	if "`estimator'"=="" | "`estimator'"=="ITT" | "`estimator'"=="itt" {
	if "`quiet'" =="" dis "*******"
	if "`quiet'" =="" dis "Outcome `i'"
	if "`quiet'" =="" dis "Intent-to-Treat estimation"
	if "`quiet'" =="" dis "********"
	
	* if basecontrol is missing: do nothing special
	if "`basecontrol'"=="" {
		if "`quiet'" !="" { 
		quietly  reg  `i' `treatment'  `control' [`weight'`exp'] `if' , cluster(`cluster')  r
		}
		
		if "`quiet'" =="" { 
		reg  `i' `treatment'  `control' [`weight'`exp'] `if' , cluster(`cluster')  r
		}
	}
		
	* if basecontrol is not missing, first verify the number of baseline cont
	if "`basecontrol'"!="" {
	cap assert wordcount("`basecontrol'") == wordcount("`varlist'")	
		
		if _rc!=0 {
		dis as error  "Number of variables different from number of baseline control"
		exit 100
		}	
	* then add the control variable that corresponds to the control
	local cont: word `k' of `basecontrol'
	if "`quiet'" !="" { 
		quietly reg  `i' `treatment'  `control' `cont' [`weight'`exp'] `if' , cluster(`cluster')  r
	}
	if "`quiet'" =="" { 
		reg  `i' `treatment'  `control' `cont' [`weight'`exp'] `if' , cluster(`cluster')  r
	}
	}
	}
	
	if "`estimator'"=="LATE" | "`estimator'"=="late" | "`treated'"!="" {
	if "`quiet'" =="" dis "*******"
	if "`quiet'" =="" dis "Outcome `i'"
	if "`quiet'" =="" dis "Local Average Treatment Effect estimation"
	if "`quiet'" =="" dis "********"
		if "`treated'"=="" {
		dis as error  "treated variable is missing"
		exit 100
		}
		
		else {
			
			if "`basecontrol'"=="" {
			dis "Treatment on the treated estimation"
				if "`quiet'" !="" { 
				quiet ivregress 2sls  `i'  (`treated'=`treatment')  `control' [`weight'`exp'] `if' , cluster(`cluster')  r	
				}
				if "`quiet'" =="" { 
				ivregress 2sls  `i'  (`treated'=`treatment')  `control' [`weight'`exp'] `if' , cluster(`cluster')  r
				}
			
			}
			
			if "`basecontrol'"!="" { 
			 assert wordcount("`basecontrol'") == wordcount("`varlist'")
				
				if _rc!=0 {
				dis as error  "Number of variables different from number of baseline control"
				exit 100
				}	
			local cont: word `k' of `basecontrol'
				if "`quiet'" !="" { 
				ivregress 2sls  `i'  (`treated'=`treatment'=)  `control' `cont' [`weight'`exp'] `if' , cluster(`cluster')  r	
				}
				if "`quiet'" =="" { 
				ivregress 2sls  `i'  (`treated'=`treatment')  `control' `cont' [`weight'`exp'] `if' , cluster(`cluster')  r	
				}
			
			}
		}
	}	
	
	local t:  variable label `i'
	quiet: replace VAR="`i'" if _n==`j'
	quiet: replace LAB="`t'" if _n==`j'
	tokenize `treatment'
	local temoin "`1'==0"
	forval v=2/`c' {
		if "``v''"!= "" {
			local cond "`cond' & ``v''==0"
			local temoin "`temoin' &  ``v''==0"
		}
	}
	
	* Creation of a Control Tempvar taking value 1 when control and 0 otherwise.
	tempvar T0
	gen `T0' = cond(`temoin', 1, 0) if `1'!=.
	
	if "`if'"=="" {
	    quiet {
		sum `i' [`weight'`exp'] if `T0'==1 `cond' , d
		
		if abs(r(mean))>=1000 &  abs(r(mean))<10000 {
		quiet: replace C="`: display %7.2fc r(mean)'" if _n==`j'
		}
		if abs(r(mean))>=10000 &  abs(r(mean))<100000 {
		quiet: replace C="`: display %7.1fc r(mean)'" if _n==`j'
		}
		if abs(r(mean))>=100000 {
		quiet: replace C="`: display %7.0fc r(mean)'" if _n==`j'
		}
		if abs(r(mean)) <1000 {
		quiet: replace C="`: display %7.3fc r(mean)'" if _n==`j'
		}
		quiet: replace C= subinstr(C," ","",.) if _n==`j'
		
		
		if "`sd'" !="" {
			
		if abs(r(sd))>=1000 &  abs(r(sd))<10000 {
		quiet: replace C="`: display %7.2fc r(sd)'" if _n==`j'+1
		}
		if abs(r(sd))>=10000 &  abs(r(sd))<100000 {
		quiet: replace C="`: display %7.1fc r(sd)'" if _n==`j'+1
		}
		if abs(r(sd))>=100000 {
		quiet: replace C="`: display %7.0fc r(sd)'" if _n==`j'+1
		}
		if abs(r(sd)) <1000 {
		quiet: replace C="`: display %7.3fc r(sd)'" if _n==`j'+1
		}
		
		replace C=subinstr(C," ","",.) if _n==`j'+1
		replace C="["+C+"]" if  _n==`j'+1
		}
		}
		
	
		 quiet {
		 sum `i' [`weight'`exp'] , d
		 if abs(r(mean))>=1000 &  abs(r(mean))<10000 {
		quiet: replace A="`: display %7.2fc r(mean)'" if _n==`j'
		}
		if abs(r(mean))>=10000 &  abs(r(mean))<100000 {
		quiet: replace A="`: display %7.1fc r(mean)'" if _n==`j'
		}
		if abs(r(mean))>=100000 {
		quiet: replace A="`: display %7.0fc r(mean)'" if _n==`j'
		}
		if abs(r(mean)) <1000 {
		quiet: replace A="`: display %7.3fc r(mean)'" if _n==`j'
		}
		 replace A=subinstr(A," ","",.) if _n==`j'

		 }
		if "`sd'" !="" {
			quiet {
			 if abs(r(sd))>=1000 &  abs(r(sd))<10000 {
		quiet: replace A="`: display %7.2fc r(sd)'" if _n==`j'+1
		}
		if abs(r(sd))>=10000 &  abs(r(sd))<100000 {
		quiet: replace A="`: display %7.1fc r(sd)'" if _n==`j'+1
		}
		if abs(r(sd))>=100000 {
		quiet: replace A="`: display %7.0fc r(sd)'" if _n==`j'+1
		}
		if abs(r(sd)) <1000 {
		quiet: replace A="`: display %7.3fc r(sd)'" if _n==`j'+1
		}
			replace A=subinstr(A," ","",.) if _n==`j'+1
			replace A="["+A+"]" if  _n==`j'+1
			}
		}
	}
	
	else {
		quiet {
		sum `i' [`weight'`exp'] `if' & `T0'==1 `cond' , d
		if abs(r(mean))>=1000 &  abs(r(mean))<10000 {
		quiet: replace C="`: display %7.2fc r(mean)'" if _n==`j'
		}
		if abs(r(mean))>=10000 &  abs(r(mean))<100000 {
		quiet: replace C="`: display %7.1fc r(mean)'" if _n==`j'
		}
		if abs(r(mean))>=100000 {
		quiet: replace C="`: display %7.0fc r(mean)'" if _n==`j'
		}
		if abs(r(mean)) <1000 {
		quiet: replace C="`: display %7.3fc r(mean)'" if _n==`j'
		}
		replace C=subinstr(C," ","",.) if _n==`j'

		}		
		if "`sd'" !="" {
			quiet{ 
				if abs(r(sd))>=1000 &  abs(r(sd))<10000 {
		quiet: replace C="`: display %7.2fc r(sd)'" if _n==`j'+1
		}
		if abs(r(sd))>=10000 &  abs(r(sd))<100000 {
		quiet: replace C="`: display %7.1fc r(sd)'" if _n==`j'+1
		}
		if abs(r(sd))>=100000 {
		quiet: replace C="`: display %7.0fc r(sd)'" if _n==`j'+1
		}
		if abs(r(sd)) <1000 {
		quiet: replace C="`: display %7.3fc r(sd)'" if _n==`j'+1
		}
				replace C=subinstr(C," ","",.) if _n==`j'+1
				replace C="["+C+"]" if  _n==`j'+1
			}
		}
	
		quiet {
		sum `i' [`weight'`exp'] `if' , d
		}
		if "`sd'" !="" {
		quiet { 
			 if abs(r(sd))>=1000 &  abs(r(sd))<10000 {
		quiet: replace A="`: display %7.2fc r(sd)'" if _n==`j'+1
		}
		if abs(r(sd))>=10000 &  abs(r(sd))<100000 {
		quiet: replace A="`: display %7.1fc r(sd)'" if _n==`j'+1
		}
		if abs(r(sd))>=100000 {
		quiet: replace A="`: display %7.0fc r(sd)'" if _n==`j'+1
		}
		if abs(r(sd)) <1000 {
		quiet: replace A="`: display %7.3fc r(sd)'" if _n==`j'+1
		}
			replace A=subinstr(A," ","",.) if _n==`j'+1
			replace A="["+A+"]" if  _n==`j'+1
				}
		}
		quiet {
		if abs(r(mean))>=1000 &  abs(r(mean))<10000 {
		quiet: replace A="`: display %7.2fc r(mean)'" if _n==`j'
		}
		if abs(r(mean))>=10000 &  abs(r(mean))<100000 {
		quiet: replace A="`: display %7.1fc r(mean)'" if _n==`j'
		}
		if abs(r(mean))>=100000 {
		quiet: replace A="`: display %7.0fc r(mean)'" if _n==`j'
		}
		if abs(r(mean)) <1000 {
		quiet: replace A="`: display %7.3fc r(mean)'" if _n==`j'
		}
		replace A=subinstr(A," ","",.) if _n==`j'
		}
		}
		
quiet {
	replace N_ind="`: display %7.0fc e(N)'" if _n==`j'
	replace N_ind=subinstr(N_ind," ","",.) if _n==`j'

	replace N_clust="`: display %7.0fc e(N_clust)'" if _n==`j'
	replace N_clust=subinstr(N_clust," ","",.) if _n==`j'

	}
	
	if ("`estimator'"=="" & "`treated'"=="") | "`estimator'"=="ITT" | "`estimator'"=="itt" {

	forval h=1/`c' {
		quiet{
		* cleaning and stars
		* first row
		if abs(_b[``h''])>=10 &  abs(_b[``h''])<100 {
		quiet: replace COEF`h'="`: display %4.2fc _b[``h'']'" if _n==`j'
		}
		if abs(_b[``h''])>=100 &  abs(_b[``h''])<1000 {
		quiet: replace COEF`h'="`: display %4.1fc _b[``h'']'" if _n==`j'
		}
		if abs(_b[``h''])>=1000 {
		quiet: replace COEF`h'="`: display %4.0fc _b[``h'']'" if _n==`j'
		}
		if abs(_b[``h'']) <10 {
		quiet: replace COEF`h'="`: display %4.3fc _b[``h'']'" if _n==`j'
		}
		
		
		replace COEF`h'=subinstr(COEF`h'," ","",.) if _n==`j'
		replace COEF`h'=COEF`h'+"*" if   _n==`j' & 2*ttail(e(df_r),abs(_b[``h'']/_se[``h'']))<=0.1
		replace COEF`h'=COEF`h'+"*" if   _n==`j' & 2*ttail(e(df_r),abs(_b[``h'']/_se[``h'']))<=0.05
		replace COEF`h'=COEF`h'+"*" if   _n==`j' & 2*ttail(e(df_r),abs(_b[``h'']/_se[``h'']))<=0.01
		* second row (SE)
		
		if abs(_se[``h''])>=10 &  abs(_se[``h''])<100 {
		quiet: replace COEF`h'="`: display %4.2fc _se[``h'']'" if _n==`j'+1
		}
		if abs(_se[``h''])>=100 &  abs(_se[``h''])<1000 {
		quiet: replace COEF`h'="`: display %4.1fc _se[``h'']'" if _n==`j'+1
		}
		if abs(_se[``h''])>=1000 {
		quiet: replace COEF`h'="`: display %4.0fc _se[``h'']'" if _n==`j'+1
		}
		if abs(_se[``h'']) <10 {
		quiet: replace COEF`h'="`: display %4.3fc _se[``h'']'" if _n==`j'+1
		}
		
		
		replace COEF`h'=subinstr(COEF`h'," ","",.) if _n==`j'+1
		replace COEF`h'="("+COEF`h'+")" if  _n==`j'+1		
		* store pvalues for qvalue calculation
		if "`qvalue'" !="" {
			local p``h''=2 * ttail(e(df_r), abs(_b[``h'']/_se[``h'']))
			local pvalues="`pvalues' `p``h''' "
		}
		}	
	}

if "`pvalue'" !="" {
	forval h=1/`c' {
		quiet{
		* cleaning
		* third row (PV)
		replace COEF`h'="`: display %7.3fc 2*ttail(e(df_r),abs(_b[``h'']/_se[``h'']))'" if _n==`j'+2
		replace COEF`h'=subinstr(COEF`h'," ","",.) if _n==`j'+2

		replace COEF`h'="["+ COEF`h' + "]" if _n==`j'+2
		}
	}
	local j= `j'+3
}
	
if "`qvalue'" !=""  {
		local j= `j'+3
	}
if "`qvalue'" =="" & "`pvalue'" =="" {
		local j= `j'+2
	}
local k= `k'+1
}

	if "`estimator'"=="LATE" | "`estimator'"=="late" | "`treated'"!="" {
	    if `c'>1 { 
		    dis as error  "LATE not available with multiple treatment branches"
				exit 100
		}
	    
		if abs(_b[`treated'])>=10 &  abs(_b[`treated'])<100 {
		quiet: replace COEF`h'="`: display %4.2fc _b[`treated']'" if _n==`j'
		}
		if abs(_b[`treated'])>=100 &  abs(_b[`treated'])<1000 {
		quiet: replace COEF`h'="`: display %4.1fc _b[`treated']'" if _n==`j'
		}
		if abs(_b[`treated'])>=1000 {
		quiet: replace COEF`h'="`: display %4.0fc _b[`treated']'" if _n==`j'
		}
		if abs(_b[`treated']) <10 {
		quiet: replace COEF`h'="`: display %4.3fc _b[`treated']'" if _n==`j'
		}
		
		
		replace COEF`h'=subinstr(COEF`h'," ","",.) if _n==`j'
		replace COEF`h'=COEF`h'+"*" if   _n==`j' & 2*normal(-abs(_b[`treated']/_se[`treated']))<=0.1
		replace COEF`h'=COEF`h'+"*" if   _n==`j' & 2*normal(-abs(_b[`treated']/_se[`treated']))<=0.05
		replace COEF`h'=COEF`h'+"*" if   _n==`j' & 2*normal(-abs(_b[`treated']/_se[`treated']))<=0.01
		* second row (SE)
		
		if abs(_se[`treated'])>=10 &  abs(_se[`treated'])<100 {
		quiet: replace COEF`h'="`: display %4.2fc _se[`treated']'" if _n==`j'+1
		}
		if abs(_se[`treated'])>=100 &  abs(_se[`treated'])<1000 {
		quiet: replace COEF`h'="`: display %4.1fc _se[`treated']'" if _n==`j'+1
		}
		if abs(_se[`treated'])>=1000 {
		quiet: replace COEF`h'="`: display %4.0fc _se[`treated']'" if _n==`j'+1
		}
		if abs(_se[`treated']) <10 {
		quiet: replace COEF`h'="`: display %4.3fc _se[`treated']'" if _n==`j'+1
		}
		
		
		replace COEF`h'=subinstr(COEF`h'," ","",.) if _n==`j'+1
		replace COEF`h'="("+COEF`h'+")" if  _n==`j'+1		
		* store pvalues for qvalue calculation
		if "`qvalue'" !="" {
			local p``h''=2 *normal(abs(_b[`treated']/_se[`treated']))
			local pvalues="`pvalues' `p``h''' "
		}	
		

if "`pvalue'" !="" {
	forval h=1/`c' {
		quiet{
		* cleaning
		* third row (PV)
		replace COEF`h'="`: display %7.3fc 2*ttail(e(df_r),abs(_b[``h'']/_se[``h'']))'" if _n==`j'+2
		replace COEF`h'=subinstr(COEF`h'," ","",.) if _n==`j'+2

		replace COEF`h'="["+ COEF`h' + "]" if _n==`j'+2
		}
	}
	local j= `j'+3
}
	
if "`qvalue'" !=""  {
		local j= `j'+3
	}
if "`qvalue'" =="" & "`pvalue'" =="" {
		local j= `j'+2
	}
local k= `k'+1
}
	
}



* qvalues

if "`qvalue'" !="" & "`qvalue'" !="bky" {
	quietly {
		forval h=1/`c' {
			
			tempvar Q`h'
			tempvar q`h'
			gen `Q`h''=.
			
			local count=1
			
			foreach q in `pvalues' {
				replace `Q`h''=`q' if _n==`count'	
				local count= `count'+1 
			}
			
			qqvalue `Q`h'', method(`qvalue') qvalue(`q`h'')
				
			local j=0
			local qcount=0
			foreach varq in `varlist' { 
				local j= `j'+3
				local qcount= `qcount'+1
				replace COEF`h'="`: display %7.3fc `q`h''[`qcount']'" if _n==`j'
				replace COEF`h'=subinstr(COEF`h'," ","",.) if _n==`j'
				replace COEF`h'="["+COEF`h'+"]" if  _n==`j'
			} 
			drop `Q`h'' `q`h''
			
		}
	}
}

if  "`qvalue'" =="bky" {
quietly {
	forval h=1/`c' {
			
		tempvar Q`h'
		tempvar q`h'
		gen `Q`h''=.
		local count=1
			
		foreach q in `pvalues' {
			replace `Q`h''=`q' if _n==`count'	
			local count= `count'+1 
		}
			
	sum `Q`h''
	local totalpvals = r(N)
	* Sort the p-values in ascending order and generate a variable that codes each p-value's rank
	tempvar original_sorting_order
	 gen int `original_sorting_order' = _n
	 sort `Q`h''
	 tempvar rank
	 gen int `rank' = _n if `Q`h''!=.

	* Set the initial counter to 1 

	local qval = 1

	* Generate the variable that will contain the BKY (2006) sharpened q-values

	gen `q`h'' = 1 if `Q`h''!=.

	* Set up a loop that begins by checking which hypotheses are rejected at q = 1.000, then checks which hypotheses are rejected at q = 0.999, then checks which hypotheses are rejected at q = 0.998, etc.  The loop ends by checking which hypotheses are rejected at q = 0.001.

	while `qval' > 0 {
		
		* First Stage
		* Generate the adjusted first stage q level we are testing: q' = q/1+q
		local qval_adj = `qval'/(1+`qval')
		* Generate value q'*r/M
		tempvar fdr_temp1
		gen `fdr_temp1' = `qval_adj'*`rank'/`totalpvals'
		* Generate binary variable checking condition p(r) <= q'*r/M
		tempvar reject_temp1
		gen `reject_temp1' = (`fdr_temp1'>=`Q`h'') if `Q`h''!=.
		* Generate variable containing p-value ranks for all p-values that meet above condition
		tempvar  reject_rank1
		gen `reject_rank1' = `reject_temp1'*`rank'
		* Record the rank of the largest p-value that meets above condition
		tempvar total_rejected1
		egen `total_rejected1' = max(`reject_rank1')
		
		* Second Stage
		* Generate the second stage q level that accounts for hypotheses rejected in first stage: q_2st = q'*(M/m0)
		local qval_2st = `qval_adj'*(`totalpvals'/(`totalpvals'-`total_rejected1'[1]))
		* Generate value q_2st*r/M
		tempvar fdr_temp2
		gen `fdr_temp2' = `qval_2st'*`rank'/`totalpvals'
		* Generate binary variable checking condition p(r) <= q_2st*r/M
			tempvar reject_temp2

		gen `reject_temp2' = (`fdr_temp2'>=`Q`h'') if `Q`h''!=.
		* Generate variable containing p-value ranks for all p-values that meet above condition
		tempvar reject_rank2
		gen `reject_rank2' = `reject_temp2'*`rank'
		* Record the rank of the largest p-value that meets above condition
		tempvar total_rejected2
		egen `total_rejected2' = max(`reject_rank2')

		* A p-value has been rejected at level q if its rank is less than or equal to the rank of the max p-value that meets the above condition
		replace `q`h'' = `qval' if `rank' <= `total_rejected2' & `rank'!=.
		* Reduce q by 0.001 and repeat loop
		
		drop   `fdr_temp1' `reject_temp1' `reject_rank1' `total_rejected1' `fdr_temp2' `reject_temp2'  `reject_rank2' `total_rejected2'
		local qval = `qval' - .001
		
	}
	quietly sort `original_sorting_order'

			local j=0
			local qcount=0
			foreach varq in `varlist' { 
				local j= `j'+3
				local qcount= `qcount'+1
				replace COEF`h'="`: display %7.3fc `q`h''[`qcount']'" if _n==`j'
				replace COEF`h'=subinstr(COEF`h'," ","",.) if _n==`j'
				replace COEF`h'="["+COEF`h'+"]" if  _n==`j'
			} 

			drop `q`h'' `Q`h'' `original_sorting_order'

}
}
}
* Summary variable at the bottom of the table
quietly {
if "`if'"=="" { 
		
	replace VAR="Observations" if _n==`j'+1 
	count if  `1'!=.
	replace N_ind="`: display %7.0fc r(N)'" if _n==`j'+1
	replace N_ind= subinstr(N_ind," ","",.) if _n==`j'+1

	count if `T0'==1
	replace C="`: display %7.0fc r(N)'" if _n==`j'+1
	replace C= subinstr(C," ","",.) if _n==`j'+1
	
	local l=1
		foreach i in `treatment' {  
		count if `i'==1
		replace COEF`l'="`: display %7.0fc r(N)'" if _n==`j'+1
		replace COEF`l'= subinstr(COEF`l'," ","",.) if _n==`j'+1
		local l= `l'+1
		}

	if "`cluster'"!="" { 
	replace VAR="Clusters" if _n==`j'+2
	duplicates report `cluster' 
	replace N_ind="`: display %7.0fc r(unique_value)'" if _n==`j'+2
	replace N_ind= subinstr(N_ind," ","",.) if _n==`j'+2

	duplicates report `cluster' if `T0'==1
	replace C="`: display %7.0fc r(unique_value)'" if _n==`j'+2
	replace C= subinstr(C," ","",.) if _n==`j'+2
	
		local l=1
		foreach i in `treatment' {  
		duplicates report `cluster' if `i'==1
		replace COEF`l'="`: display %7.0fc r(unique_value)'" if _n==`j'+2
		replace COEF`l'= subinstr(COEF`l'," ","",.) if _n==`j'+2
		local l= `l'+1
		}
		

	}
}
	
if "`if'"!="" { 
	replace VAR="Observations" if  _n==`j'+1  
	count `if' & `1'!=.
	replace N_ind="`: display %7.0fc r(N)'" if _n==`j'+1
	replace N_ind= subinstr(N_ind," ","",.) if _n==`j'+1

	count `if' & `T0'==1
	replace C="`: display %7.0fc r(N)'" if _n==`j'+1 
	replace C= subinstr(C," ","",.) if _n==`j'+1
	
	local l=1
		foreach i in `treatment' {  
		count `if' & `i'==1
		replace COEF`l'="`: display %7.0fc r(N)'" if _n==`j'+1
		replace COEF`l'= subinstr(COEF`l'," ","",.) if _n==`j'+1
		local l= `l'+1
		}
		
	if "`cluster'"!="" { 
	replace VAR="Clusters" if _n==`j'+2
	duplicates report `cluster' `if'
	replace N_ind="`: display %7.0fc r(unique_value)'" if _n==`j'+2
	replace N_ind= subinstr(N_ind," ","",.) if _n==`j'+2
	
	local l=1
		foreach i in `treatment' {  
		duplicates report `cluster' `if' & `i'==1
		replace COEF`l'="`: display %7.0fc r(unique_value)'" if _n==`j'+2
		replace COEF`l'= subinstr(COEF`l'," ","",.) if _n==`j'+2
		local l= `l'+1
		}
		

	duplicates report `cluster' `if' & `T0'==1
	replace C="`: display %7.0fc r(unique_value)'" if _n==`j'+2
	replace C= subinstr(C," ","",.) if _n==`j'+2

	
	}
}
}

* Saving in excel 
	if `"`using'"'!="" & "`latex'" =="" {
		if `"`sheet'"'!=""   {  
			gettoken worksheet option: sheet, parse(,)
			export excel   VAR LAB   N_ind N_clust A C COEF*   `using',   sheet(`worksheet' `option')  first(var)
		}
		if `"`sheet'"'==""  { 
			export excel   VAR LAB   N_ind N_clust A C COEF*   `using', firstrow(var) replace
		}	
	}


*** export in LATEX FORMAT
if "`latex'" !="" { 
cap which listtab
if _rc ssc install listtab

local word= wordcount("`COEFS'")
forval C=1/`word'{ 
	local Cs = "`Cs' c" 
} 



#delimit ;
listtab LAB   N_ind  N_clust C `COEFS' if COEF1!="" | LAB!=""  `using', replace rstyle(tabular) head(" 
\begin{threeparttable}[htbp]
  \centering
  \caption{}
    \begin{tabular}{lccc`Cs'} 
    \toprule
    \toprule
	& N  & Cluster  & C  &  `COEFS_tex' \\ 
\cmidrule{2-`=4+`word''}")
foot(" \bottomrule \bottomrule
    \end{tabular}
  \label{}
          \begin{tablenotes}[flushleft]
\item
  \end{tablenotes}
\end{threeparttable}");
#delimit cr  
	}
	if  "`keep'"!="" {
	order  VAR LAB N_ind N_clust A C COEF*, last
	}
	
	if "`keep'"=="" {
	restore
	}
end

