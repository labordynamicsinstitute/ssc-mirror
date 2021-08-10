*!version1.0 14jul2017

/* -----------------------------------------------------------------------------
** PROGRAM NAME: CPTEST
** VERSION: 1.0
** DATE: JULY 14, 2017
** -----------------------------------------------------------------------------
** CREATED BY: JOHN GALLIS, LIZ TURNER, FAN LI, HENGSHI YU
** -----------------------------------------------------------------------------
** PURPOSE: PERFORM CLUSTERED PERMUTATION TEST
** -----------------------------------------------------------------------------

** -----------------------------------------------------------------------------
*/

program define cptest, rclass
	version 14
	
	#delimit ;
	syntax varlist(min=1),
		 clustername(varname) directory(string) cspacedatname(string) outcometype(string) [categorical(varlist)]
	;
	
	#delimit cr
	
	marksample touse, novarlist
	quietly count if `touse'
	
	/* error if there are no observations in the dataset */
	if `r(N)' == 0 {
		error 2000
	}
	
	if "`outcometype'" == "" {
		di as err "Error: Specify outcometype as continuous or binary"
		exit 198
	}

	
	if "`categorical'"!="" {
		local ncatvars: word count `categorical'
		tokenize `categorical'
		
		forval i=1/`ncatvars' {
			/* generate dummy variables */
			quietly tabulate ``i'', gen(``i''_)
			/* give warning if variable only has one level */
			if r(r) == 1 {
				di as text "--"
				di as text "Warning: variable ``i'' only has one level. It will not be used in the program"
				di as text "--"
			}
			/* drop one of the dummy variables */
			drop ``i''_1
			/* count number of dummy variables */
			local ``i''_num=r(r) - 1
			forval j=1/```i''_num' {
				local k=`j'+1
				local add "``i''_`k'"
				/* code that adds the dummy variables to `varlist' */
				local varlist : list varlist | add
			}
			/* code that removes categorical variables from varlist */
			local varlist : list varlist-categorical
		}
	}
	
	/* for error checking */
	local outcome `: word 1 of `varlist''
	
	capture drop _resid
	if "`outcometype'" == "continuous" | "`outcometype'" == "Continuous" {
		quietly tab `outcome'
		if `r(r)' <= 1 {
			di as error "Error: Outcome does not have enough variability!"
			exit 198
		}
		if `r(r)'== 2 {
			di as result "Warning: Outcome specified as continuous but has two levels"
		}
		quietly regress `varlist'
		predict double _resid, residuals
		di as result "Linear regression was performed"
	}
	else if "`outcometype'" == "binary" | "`outcometype'" == "Binary" {
		quietly tab `outcome'
		if `r(r)' <= 1 {
			di as error "Error: Outcome does not have enough variability!"
			exit 198
		}
		if `r(r)' != 2 {
			di as err "Error: Outcome specified as binary but does not have two levels"
			exit 198
		}
		quietly logit `varlist'
		predict double _resid, residuals
		di as result "Logistic regression was performed"
	}
	else {
		di as err "Error: Invalid outcometype specification; must be either continuous or binary"
		exit 198
	}
	
	preserve
	local nvar: word count `clustername'
	tokenize `clustername'
	/* average residual by cluster */
	forval i=1/`nvar' {
		bys ``i'': egen _residmn = mean(_resid)
		egen _tag = tag(``i'')
	}
	
	quietly tab _tag
	if `r(r)' == 1 {
		di as err "Error: Data is at the cluster-level!  cptest requires individual-level data"
		exit 198
	}
	
	quietly keep if _tag == 1
	keep _residmn
	
	
	local spacedat "use `cspacedatname', clear"
	
	quietly cd "`directory'"

	mata: ptest("`spacedat'")
	restore
	
	/* drop dummy variables from the dataset */
	if "`categorical'"!="" {
		local ncatvars: word count `categorical'
		tokenize `categorical'
		
		forval i=1/`ncatvars' {
			quietly tabulate ``i'',
			local ``i''_num=r(r) - 1
			forval j=1/```i''_num' {
				local k=`j'+1
				local add "``i''_`k'"
				/* code that drops the dummy variables  */
				drop `add'
			}
			
		}
	}
	/* drop residuals */
	capture drop _resid _residmn
	
end

mata:
matrix ptest(string scalar spacedat) {

//stata(resdat)
res=st_data(.,.)

stata(spacedat)
stata("drop chosen_scheme")
stata("quietly recode * (0=-1)")
st_view(cspace=.,.,.)

// column matrix of test statistics
teststat=abs(cspace*res)


stata(spacedat)
stata("quietly keep if chosen_scheme==1")
stata("quietly drop chosen_scheme")
chosen=st_data(1,.)'
printf("Final chosen scheme used by the cptest program:")
chosen

stata(spacedat)
stata("quietly keep chosen_scheme")
stata("gen obs=_n")
stata("quietly keep if chosen_scheme==1")
stata("quietly keep obs")
cspacerow=st_data(.,.)

// null test statistic, based on chosen scheme
null = teststat[cspacerow,.]
indmat = teststat :> null

pval = mean(indmat)
printf(" \n")
printf("Clustered permutation test p-value = %9.4f\n",pval)
printf("Note: test may be anti-conservative if number of intervention clusters does not equal number of control clusters")

}
end

