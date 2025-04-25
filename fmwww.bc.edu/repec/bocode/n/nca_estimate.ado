
************START NCA_ESTIMATE

pro def nca_estimate, eclass 
syntax varlist (numeric min=2) [if] [in], [CEILings(string asis) nograph  TESTrep(integer 0)  GRAPHNAmes(string) nocombine BOTtlenecks(numlist sort) BOTtlenecks_default SCOpe(numlist missingokay)  flipx flipy CORner(numlist integer missingokay) steps(integer 10) stepsize(numlist max=1 >=0) XBOTtlenecks(string) YBOTtlenecks(string) cutoff(integer 0) noSummaries Version(integer 3)]
marksample touse //setting the estimation sample

local version "v`version'"
if (`cutoff'>2) {
	di as error "invalid {bf: cutoff}"
	exit 144
	}

//parsing ceilings
if ("`ceilings'"=="") local ceilings ce_fdh cr_fdh 
if ("`ceilings'"=="all") local ceilings ce_fdh cr_fdh ce_vrs cr_vrs 
else {
	local allowed_methods ce_vrs ce_fdh cr_vrs cr_fdh
	if !(`:list ceilings in allowed_methods') {
		display as error "error in {bf: ceilings}, please choose any between ce_vrs, ce_fdh, cr_vrs and cr_fdh"
		exit 144
	}	
	
}
//parsing scopes (scopeX and ScopeY are the extremes of the empirical scope)
tempname scopeX scopeY scopemat empirical_scopemat
nca_parse_scope `varlist', scope(`scope')
matrix `scopeY'=r(scopeY)
matrix `scopeX'=r(scopeX)
matrix `scopemat'=r(scopematrix)
if ("`scope'"!="") matrix `empirical_scopemat'=r(empirical_scopematrix)
local ymin=`scopeY'[1,1]
local ymax=`scopeY'[1,2]

//parsing corners
if ("`flipx'`flipy'"!="" & "`corner'"!="") {
	di "WARNING: options {bf: flipx} and {bf: flipy} are conflicting with {bf: corner}. Overrding {bf: corner}."
}

if "`flipx'`flipy'"=="flipx" local corner 2
if "`flipx'`flipy'"=="flipy" local corner 3
if "`flipx'`flipy'"=="flipxflipy" local corner 4
if ("`corner'"=="") local corner 1
if (`: word count `corner''==1) {
	if (!inrange(`corner',1,4)) {
		di as error "error in option {bf:corner}: you must supply one integer between 1 and 4"
		exit 125
		}
	
	local corner= `=`: word count `varlist''-1'*"`corner' "
}
else {
	cap numlist "`corner'", min(`=`: word count `varlist''-1') max(`=`: word count `varlist''-1') range(>=1 <=4) 
	if _rc {
		di as error "invalid {bf:corner}: you must supply `=`: word count `varlist''-1' integers between 1 and 4"
		exit 125
		}	
	
}
// I need a copy of the corner list to be returned at the end of the program
local corners `corner'


//parsing y and X (dependent variable last)
local y: word `: word count `varlist'' of `varlist'
local X: subinstr local varlist "`y'" "", word

if (`:word count `X''>4) local graph nograph

//parsing bottlenecks

	if ("`xbottlenecks'"=="") local xbottlenecks perc_range
	 else if (!inlist("`xbottlenecks'", "perc_max", "perc_range", "actual","percentile") ) opts_exclusive "perc_max perc_range actual percentile" xbottlenecks 
	if ("`ybottlenecks'"=="") local ybottlenecks perc_range
	 else if (!inlist("`ybottlenecks'", "perc_max", "perc_range", "actual","percentile") ) opts_exclusive "perc_max perc_range actual percentile" ybottlenecks 
if ("`bottlenecks'"!="" | "`bottlenecks_default'" !="")	  {
	 
if ("`bottlenecks'"!="") {
	if ("`ybottlenecks'"!="actual") {
		cap numlist "`bottlenecks'", range(>=0 <=100)
		if _rc {
			di as error "elements of {bf:bottlenecks} are out of allowed range(>=0 <=100) "
			exit 125
		}	
		local bottlenecks=r(numlist)	
	}	
}	
else if ("`bottlenecks_default'" !="") {
	if ("`ybottlenecks'"=="actual") quie numlist "`ymin'(`=(`ymax'-`ymin')/`steps'')`ymax'"
	else quie numlist "0(`=100/`steps'')100"
	local bottlenecks=r(numlist)					
	}


//now I need to express the values in percentages in actual values
if ("`ybottlenecks'"=="percentile") {
	tempname centiles_y
	matrix `centiles_y'= (`:subinstr local bottlenecks " " "\",all')
	quie nca_centiles `y' if `touse', centiles(`bottlenecks') 
	local bottlenecks
	
	forval i=1/`=rowsof(r(centiles))' {
	local bottlenecks `bottlenecks'   `=r(centiles)[`i',1]'
	}
	
}
if ("`ybottlenecks'"=="perc_max") {
	foreach i of numlist `bottlenecks' {
		local bottlenecks2 `bottlenecks2' `=`i'*`ymax'/100'
	}
	local bottlenecks `bottlenecks2'	
}
if ("`ybottlenecks'"=="perc_range") {
	foreach i of numlist `bottlenecks' {
		local bottlenecks2 `bottlenecks2' `=`ymin'+`i'/100*(`ymax'-`ymin')'
	}
	local bottlenecks `bottlenecks2'	
}
	}	

/*VECCHIA SINTASSI FUNZIONANTE
if ("`bottlenecks_default'" !="" & "`bottlenecks'"=="") {
	if ("`stepsize'"=="") {
		*if ("`ybottlenecks'"=="actual") {
			local stepsize=(`ymax'-`ymin')/`steps'
			quie numlist "`ymin'(`stepsize')`ymax'"
			local bottlenecks=r(numlist)	
		/*}
		if ("`ybottlenecks'"=="percentile") {
			quie centile `y', centile(0(`=100/`steps'')100) 
		}*/
		
	 }
	} 
	*/


local plotcmd
tempname result_x scopex bottlenecks_x results bnecks_table
_rmcoll `X', expand
_rmdcoll `y' `X'
	quie cap gen ______ToUsE=`touse'
foreach x of local X {
	local plotcmd 
	matrix `scopex'=`scopeX'[rownumb(`scopeX',"`x'"),1..2]
	gettoken corner_x corner : corner
	 m: _nca_main("`y'", "`x'" ,"`touse'", "`scopeY'", "`scopex'", `corner_x', "`ceilings'" , "`bottlenecks'", "`graphnames'" , `cutoff')

	matrix colnames `result_x'=`ceilings'
	matrix coleq `result_x'=`x'
		matrix `results'=nullmat(`results') , `result_x'
	if ("`bottlenecks'"!="") {
	if ("`xbottlenecks'"=="perc_max") matrix `bottlenecks_x'=100*`bottlenecks_x'/`result_x'[4,1]
	if ("`xbottlenecks'"=="perc_range") {
		//matlist `bottlenecks_x'
		matrix `bottlenecks_x'=100*(`bottlenecks_x'-J(rowsof(`bottlenecks_x'),colsof(`bottlenecks_x'), `result_x'[3,1] )  )/(`result_x'[4,1]-`result_x'[3,1] )
			}
		if ("`xbottlenecks'"=="percentile") {
		nca_get_centiles `x' if `touse',matrix(`bottlenecks_x') corner(`corner_x')
		 matrix `bottlenecks_x'=r(centiles)
	}
	
	matrix colnames `bottlenecks_x'=`ceilings'
	matrix coleq `bottlenecks_x'=`x'

	if ("`ybottlenecks'"=="perc_max") {
		matrix `bottlenecks_y'=100*`bottlenecks_y'/`result_x'[6,1]
		if inlist(`corner_x',3,4) matrix `bottlenecks_y'=J(rowsof(`bottlenecks_y'),1,100)-`bottlenecks_y'
		
				}
	if ("`ybottlenecks'"=="perc_range") {
		matrix `bottlenecks_y'=100*(`bottlenecks_y'-J(rowsof(`bottlenecks_y'),colsof(`bottlenecks_y'), `result_x'[5,1] )  )/(`result_x'[6,1]-`result_x'[5,1] )
		if inlist(`corner_x',3,4) matrix `bottlenecks_y'=J(rowsof(`bottlenecks_y'),1,100)-`bottlenecks_y'

		}
		if ("`ybottlenecks'"=="percentile") {
		*nca_get_centiles `y' if `touse',matrix(`bottlenecks_y')
		matrix `bottlenecks_y'=`centiles_y' 
	}

	
	matrix colnames `bottlenecks_x'=`ceilings'
	matrix coleq `bottlenecks_x'=`x'
	matrix colnames `bottlenecks_y'=`y'
	matrix coleq `bottlenecks_y'=`x'
	matrix `bnecks_table'=nullmat(`bnecks_table'),(`bottlenecks_y',`bottlenecks_x')

	}
	if ("`graph'"=="nograph") continue

	
	`plotcmd' xtitle(`=cond("`:variable label `x''"=="","`x'" ,"`:variable label `x''")' ) ytitle(`=cond("`:variable label `y''"=="","`y'" ,"`:variable label `y''")') 
	local plotlist `plotlist' `graphnames'`x'
	
}
cap drop ______ToUsE
if ("`graph'"!="nograph") grc1leg `plotlist', rows(`=floor( `=sqrt(`: word count `X'' )') ') ycommon
matrix rownames `results'= "Number of observations" /// 
	"Scope" /// 
	"Xmin" /// 
	"Xmax" /// 
	"Ymin" /// 
	"Ymax" ///
	 "Ceiling zone" /// 
	 "Effect size" ///
	 "# above" ///
	 "c-accuracy (%)" /// 
	 "Fit (%)" /// 
	 "Slope" /// 
	 "Intercept" /// 
	 "Abs. ineff." /// 
	 "Rel. ineff. (%)" /// 
	 "Condition ineff. (%)" /// 
	 "Outcome ineff. (%)"	

	 //returning results
	 ereturn post, esample(`touse')   
foreach x of local X{
foreach ceil of local ceilings {
	ereturn  scalar es_`x'_`ceil' =  `results'[8, "`x':`ceil'"]
	local permlist `permlist' e(es_`x'_`ceil')
	}
}

ereturn hidden local depvar "`y'"
ereturn local outcome="`y'"
ereturn matrix results=`results'
ereturn hidden local permlist="`permlist'"
ereturn matrix scopeY=`scopeY'
ereturn matrix scopeX=`scopeX'
ereturn hidden local indepvars = "`X'"
ereturn local conditions = "`X'"
ereturn local ceilings=  "`ceilings'" 
ereturn local cmd="nca"
ereturn local corners="`corners'"
ereturn local cutoff=`cutoff'
ereturn local ybottlenecks="`ybottlenecks'"
ereturn local xbottlenecks="`xbottlenecks'"
if ("`scope'"!="") ereturn hidden matrix empirical_scopemat=`empirical_scopemat'

if ("`bottlenecks'"!="") {
	matrix rownames  `bnecks_table'=""
	ereturn matrix bottlenecks=`bnecks_table'	
	ereturn hidden local bnecks_subtitle="Y=`ybottlenecks', X=`xbottlenecks'"
	matrix `bottlenecks_y'=(`: subinstr local bottlenecks " " "\", all')
	ereturn hidden matrix bottlenecks_y=  `bottlenecks_y'
	}
ereturn scalar testrep=`testrep'
ereturn hidden local memorygraph="`plotlist'"

end

***END NCA_ESTIMATE

