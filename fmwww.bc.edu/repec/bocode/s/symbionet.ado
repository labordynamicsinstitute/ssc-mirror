*This version Feb 2025
*Charlie Joyez & Nadia Von Jacobi

capture program drop symbionet
program symbionet , rclass
	version 9
	syntax varlist[, SYMmetric bootstrap(string) slevel(string) output(string) keepsignchange strict keepall dag plot]
	
	
	if "`symmetric'" == "" {
				noi di "Symbiotic network is being computed."

	quietly{	
		if "`bootstrap'" == "" {
		local reps=400
	}
	else{
		local reps=`bootstrap'
	}
	
	if "`slevel'" == "" | "`slevel'" =="1" | "`slevel'" =="5" | "`slevel'" =="10" |"`slevel'" =="100" {
		if "`slevel'" == "" |"`slevel'"=="10"  {
			local tstat=1.645
			local slevel=10
		}
		if "`slevel'"=="5"{
			local tstat=1.96
		}
		if "`slevel'"=="1"{
			local tstat=2.575
		}
		if "`slevel'"=="100" | "`slevel'"=="all"{
			local tstat=0
		}
	}
	else {	
		noi di as error "slevel should be 1, 5, 10 (default), or all"
	}
	
	if "`output'"=="" |"`output'"=="edgelist" |"`output'"=="initial" |"`output'"=="matrix" |"`output'"=="detail"  {
	}
	else{
		noi di as error "output should be edgelist (default), detail , matrix, or initial"
	}
	
	if "`output'"==""{
	local output="edgelist"
	}
	
	if  "`output'"=="initial"{
		tempfile initial
		save `initial'
	}
	
	*noi di "output is set to : `output'"
		keep `varlist'

	/*removing string variables*/
	ds `varlist', has(type numeric)
capture keep `r(varlist)'

quietly describe _all, varlist /*_all = nonstring variables among the varlist listed*/
local varlist = r(varlist)

*noi di `varlist'
qui describe
local nvars=r(k)
local nvars2=`nvars'*`nvars'
mata q20=J(`nvars2',1,.)
mata q35=J(`nvars2',1,.)
mata q50=J(`nvars2',1,.)
mata q65=J(`nvars2',1,.)
mata q80=J(`nvars2',1,.)
mata E=J(`nvars2',1,"")
mata S=J(`nvars2',1,"")
mata T=J(`nvars2',1,"")


	
local i=0
noi di "progress : " _cont
capture noisily {
foreach firstvar in `varlist' {
	foreach secondvar in `varlist' {

	local m=round(`i'/`nvars2'*100,1)
	
	forvalues k=0(5)`nvars2' {
		if `i'==`k'{
			noi di " `m'% ... "  _cont
		}
	}
				

		local i=`i'+1
			
			
		mata E[`i',1]="`secondvar'->`firstvar'"
	  	if `firstvar'!=`secondvar' {
		mata T[`i',1]="`firstvar'"
		mata S[`i',1]="`secondvar'" /*we regress Y(first) = aX(second) so second is the source and first the target*/
		
	   	*timer clear
		timer on 97
			local se20=. 
			local se35=.
			local se50=.
			local se65=.
			local se80=.
			
		capture qreg `firstvar' `secondvar', quantile (.2)  
		capture local q20=_b[`secondvar']
		capture local se20 =_se[`secondvar']

		capture qreg `firstvar' `secondvar', quantile (.35) 
		capture local q35=_b[`secondvar']
		capture local se35=_se[`secondvar']
		
		capture qreg `firstvar' `secondvar', quantile (.5) 
		capture local q50=_b[`secondvar']
		capture local se50=_se[`secondvar']
		
		capture qreg `firstvar' `secondvar', quantile (.65) 
		capture local q65=_b[`secondvar']
		capture local se65=_se[`secondvar']
		
		capture qreg `firstvar' `secondvar', quantile (.8) 
		capture local q80=_b[`secondvar']
		capture local se80=_se[`secondvar']
		
		quie timer off 97
		quie timer list
		local timereg= r(t97)
		if `timereg'>10000 {
			noi di as error _newline "convergence took too long on quantile regression qreg `firstvar' `secondvar'. Check for possible distribution or missing variable issues. "   _newline 
		}
		if `se20'==. & `se35'==. & `se50'==. & `se65'==. & `se80'==.{
			noi di as error   _newline "convergence not achieved regressing `firstvar' over `secondvar'. Check for possible collinearity issues "   _newline 
		}
		
		*firstvar is the dependent variable while secondvar is the explanatory

		mata q20[`i',1]=`q20'
		mata q35[`i',1]=`q35'
		mata q50[`i',1]=`q50'
		mata q65[`i',1]=`q65'
		mata q80[`i',1]=`q80'
		
		
		*identifying statistical significance
		
		local Tq20 = abs(`q20'/`se20')
		local Tq35 = abs(`q35'/`se35')
		local Tq50 = abs(`q50'/`se50')
		local Tq65 = abs(`q65'/`se65')
		local Tq80 = abs(`q80'/`se80')
	
	
	mata q20f=q20
	mata q35f=q35
	mata q50f=q50
	mata q65f=q65
	mata q80f=q80 
		if `Tq20'<`tstat'{
				mata q20[`i',1]=.
	}
		if `Tq35'<`tstat'{
				mata q35[`i',1]=.
	}
		if `Tq50'<`tstat'{
				mata q50[`i',1]=.
	}
		if `Tq65'<`tstat'{
				mata q65[`i',1]=.
	}
		if `Tq80'<`tstat'{
				mata q80[`i',1]=.
	}
		
	
	   }
	  }
	}
}
	mata Q=(q20,q35,q50,q65,q80)
	mata MN=rowmissing(Q)
	keep if _n==0
	set obs `nvars2'
	capt drop if _n>`nvars2'
	getmata E S T q20 q35 q50 q65 q80 MN q20f q35f q50f q65f q80f
	keep E S T q* M
	rename E edge
	rename S source
	rename T target 
	drop if source==target
	rename MN nbnonsignificantcoef 
	
		egen bil_id=group(source target)
			foreach v in `varlist' {
		foreach w in `varlist'{
			su bil_id if source=="`v'" & target=="`w'"
			local bilid=r(mean)
			if `bilid'!=.{
			replace bil_id=`bilid' if source=="`w'" & target=="`v'"
			}
		}
	}
	sort bil_id

	  
	foreach q in 20 35 50 65 80{ /*keep unsignificant coefs?*/
	bysort bil_id : gen q`q'_op =q`q'[_n+1]
bysort bil_id : replace q`q'_op =q`q'[_n-1] if q`q'_op==.	
	}

	  drop if nbnonsignificantcoef>2 /*at least 3 out of 5 significant coeff*/
	gen nbsignifcoef=5-nbnonsignificantcoef /*variable A5 or A10 in Nadia's file*/

	
	
	capt drop dif
	gen dif=q80-q20 if  q20!=. & q80!=.
	replace dif= q65-q20 if dif==. & q20!=. & q65!=.
	replace dif= q50-q20 if dif==. & q20!=. & q50!=.
	replace dif= q80-q35 if dif==. & q35!=. & q80!=.
	replace dif= q80-q50 if dif==. & q50!=. & q80!=.
	replace dif= q65-q35 if dif==. & q65!=. & q35!=.
	gen increasing=(dif>0)
	
	
	/*take the coefficient of the maximum quintile*/
	gen maxq=q80 
	replace maxq=q65 if maxq==.
	replace maxq=q50 if maxq==.
	replace maxq=q35 if maxq==.
	
	gen minq=q20 
	replace minq=q35 if minq==.
	replace minq=q50 if minq==.
	replace minq=q65 if minq==.

*detect sign changes :
gen _signchange=(minq<0 & maxq>0)

gen dmq = (abs(maxq) - abs(minq))/ abs(minq)  

gen A`slevel'source_target_bil=. 
gen dms=.	
		foreach v in `varlist' {
		foreach w in `varlist'{
			su dmq if source=="`v'" & target=="`w'"
			local d1=r(mean)
			su dmq if source=="`w'" & target=="`v'"
			local d2=r(mean)
			replace dms= abs(`d1')-abs(`d2') if source=="`v'" & target=="`w'" 
			
			su nbsignifcoef if source=="`v'" & target=="`w'"
			local d3=r(mean)
			su nbsignifcoef if source=="`w'" & target=="`v'"
			local d4=r(mean)			
		replace A`slevel'source_target_bil=`d3'+`d4' if source=="`v'" & target=="`w'"
		}
	}

gen DOM=.	/*Dominance =1 if dms>0*/
		foreach v in `varlist' {
		foreach w in `varlist'{
			su dmq if source=="`v'" & target=="`w'"
			local d1=r(mean)
			su dmq if source=="`w'" & target=="`v'"
			local d2=r(mean)
			replace DOM=1 if abs(`d1')>abs(`d2') & source=="`v'" & target=="`w'" 
		}
	}
	
	
	gen commensalist=0
	foreach v in `varlist' {
		foreach w in `varlist'{
			su dif if source=="`v'" & target=="`w'"
			local d1=r(mean)
			su dif if source=="`w'" & target=="`v'"
			local d2=r(mean)
			replace commensalist=1 if source=="`v'" & target=="`w'" & `d1'>`d2' & increasing==1
		}
	}


	gen shape=""
		replace shape = "Monotonic increasing" if q20f<q35f & q35f<q50f & q50f<q65f & q65f<q80f 				
		replace shape = "Monotonic decreasing" if  q20f>=q35f & q35f>=q50f & q50f>=q65f & q65f>=q80f 
		replace shape = "A-shaped" if   q20f<=q35f & q35f<=q50f & q50f>=q65f & q65f>=q80f
		replace shape = "A-shaped" if   q20==. & q35f<=q50f & q50f>=q65f & q65f>=q80f
		replace shape = "A-shaped" if   q20f<=q50 & q35==. & q50f>=q65f & q65f>=q80f
		replace shape = "A-shaped" if   q20f<=q35f & q35f<=q65 & q50==. & q65f>=q80f
		replace shape = "A-shaped" if   q20f<=q35f & q35f<=q50f & q65==. & q80>=q50
		replace shape = "A-shaped" if   q20f<=q35f & q35f<=q50f & q50f>=q65f & q80==.
		
		replace shape = "U-shaped" if   q20f>=q35f & q35f>=q50f & q50f<=q65f & q65f<=q80f
		replace shape = "U-shaped" if   q20==. & q35f>=q50f & q50f<=q65f & q65f<=q80f
		replace shape = "U-shaped" if   q20f>=q50 & q35==. & q50f<=q65f & q65f<=q80f
		replace shape = "U-shaped" if   q20f>=q35f & q35f>=q65 & q50==. & q65f<=q80f
		replace shape = "U-shaped" if   q20f>=q35f & q35f>=q50f & q65==. & q80<=q50
		replace shape = "U-shaped" if   q20f>=q35f & q35f>=q50f & q50f<=q65f & q80==.		

		
		
		replace shape = "else" if shape=="" 

	
	
}
		if "`keepall'" == "" {
	if "`keepsignchange'" == "" {
drop if _signchange==1
	}

keep if DOM==1	/*Edge direction : keep only the positive direction*/
keep if commensalist==1 /*edge selection to commensalistedges only*/
	if "`strict'" != "" {
keep if shape = "Monotonic increasing"
	}
}
	
drop q*f 
rename dms weight

putmata weight
putmata edge

	if  "`output'"=="initial"{
		preserve 
		capture nwfromedge source target A`slevel'source_target_bil ,name(signimat) /*matrix of significance*/
		restore 
		capture nwfromedge source target weight ,name(symbionetwork)
		putmata Mat=(net*)
			if "`plot'"!=""{
				capture nwplot symbionetwork, label(_nodelab) edgesize(symbionetwork) edgecolor(signimat)
			}

	}
	
		if  "`output'"=="matrix"{
		preserve 
		capture nwfromedge source target A`slevel'source_target_bil ,name(signimat) /*matrix of significance*/
		restore 
		capture nwfromedge source target weight ,name(symbionetwork)
		putmata Mat=(net*)
			if "`plot'"!=""{
				capture nwplot symbionetwork, label(_nodelab) edgesize(symbionetwork) edgecolor(signimat)

			}
	}
	
	if  "`output'"=="edgelist"{
		preserve
		capture nwfromedge source target weight ,name(symbionetwork)
		putmata Mat=(net*)
		restore
		preserve
		capture nwfromedge source target A`slevel'source_target_bil ,name(signimat)
			if "`plot'"!=""{
				capture nwplot symbionetwork, label(_nodelab) edgesize(symbionetwork) edgecolor(signimat)
			}
		restore 
		keep source target weight
	}
		if  "`output'"=="detail"{
		preserve
		capture nwfromedge source target weight ,name(symbionetwork)
		putmata Mat=(net*)		
		restore
		preserve
		capture nwfromedge source target A`slevel'source_target_bil ,name(signimat)
			if "`plot'"!=""{
				capture nwplot symbionetwork, label(_nodelab) edgesize(symbionetwork) edgecolor(signimat)
			}
		restore 
	}
	
	
	if "`dag'" != "" {
		*Is a DAG? If yes, should not have positive diagonal terms (self cycles)
	mata M=Mat
	mata d=trace(M)
	forvalues j=2/`nvars'{
	mata M=M*M
	mata d=d+trace(M)
	}
	mata st_local("d", strofreal(d))

	if `d'>0 {
	noi di as result "The network is not a Directed Acyclic Graph"
	}
	if `d'==0 {
	noi di as result "The network is a Directed Acyclic Graph. "
	}

	
}
if  "`output'"=="initial"{
		use `initial',clear

}


}	

if "`symmetric'" != "" {
		noi di "Symmetric correlation network is being computed"
		quietly{
	
	
	if "`slevel'" == "" | "`slevel'" =="1" | "`slevel'" =="5" | "`slevel'" =="10" |"`slevel'" =="100" | "`slevel'"=="all" {
		if "`slevel'"=="10"  {
			local tstat=1.645
		}
		if   "`slevel'" == "" | "`slevel'"=="5"{
			local tstat=1.96
		}
		if "`slevel'"=="1"{
			local tstat=2.575
		}
		if "`slevel'"=="100" | "`slevel'"=="all"{
			local tstat=0
		}
	}
	else {	
		noi di as error "slevel should be 1, 5 (default), 10 or 100 (all ties, no significativity threshold) "
	}
	
	if "`output'"==""{
		local output="edgelist"
	}
	
	if  "`output'"=="initial"{
		tempfile initial
		save `initial'
	}

	keep `varlist'

	/*removing string variables*/
	ds `varlist', has(type numeric)
capture keep `r(varlist)'

quietly describe _all, varlist /*_all = nonstring variables among the varlist listed*/
local varlist = r(varlist)


*noi di `varlist'
qui describe
local nvars=r(k)
local nvars2=`nvars'*`nvars'
mata C=J(`nvars2',1,.)
mata E=J(`nvars2',1,"")
mata S=J(`nvars2',1,"")
mata T=J(`nvars2',1,"")
mata tv=J(`nvars2',1,.)

local i=0
foreach firstvar in `varlist' {
	foreach secondvar in `varlist' {
		local i=`i'+1
		corr `firstvar' `secondvar' // now if you type return list you will see what results were saved
		scalar corr_`firstvar'_`secondvar' = r(rho) // so you will have a scalar called, e.g. corr_var1_var2
		scalar obs_`firstvar'_`secondvar' = r(N)
		gen tval_`firstvar'_`secondvar'= corr_`firstvar'_`secondvar'* sqrt((obs_`firstvar'_`secondvar'-2)/(1-(corr_`firstvar'_`secondvar')^2))

		gen `firstvar'_corr_`secondvar' = corr_`firstvar'_`secondvar' if abs(tval_`firstvar'_`secondvar')>`tstat'
		
		mata E[`i',1]="`secondvar'->`firstvar'"
		mata S[`i',1]="`firstvar'"
		mata T[`i',1]="`secondvar'"
		su  `firstvar'_corr_`secondvar'
		local c=r(mean)
		mata C[`i',1]=`c'
		drop `firstvar'_corr_`secondvar'
		su tval_`firstvar'_`secondvar'
		local tv=r(mean)
		mata tv[`i',1]=`tv'
		drop tval_*
		mata W=abs(C)
		mata Tv=abs(tv)
		}
	}
	
	
	keep if _n==1
	set obs `nvars2'
	capt drop if _n>`nvars2'
	getmata E S C T W Tv
	keep E S T C W Tv
	rename E edge
	rename S source
	rename T target 
	rename W weight
	rename C corrcoeff
	rename Tv significance
	if  "`output'"!="detail"{
		drop if source==target
		drop if weight==.
	}
	gen invweight = 1/weight
	gsort - weight

	
	egen bil_id=group(source target)
			foreach v in `varlist' {
		foreach w in `varlist'{
			su bil_id if source=="`v'" & target=="`w'"
			local bilid=r(mean)
			replace bil_id=`bilid' if source=="`w'" & target=="`v'"
		}
	}
	sort bil_id
	bysort bil_id (source) : keep if _n==1
	sort source
}

	if  "`output'"=="initial"{
		preserve
		capture nwfromedge source target significance,name(signimat)		
		restore
		capture nwfromedge source target weight,name(symbionetwork) undirected
		capture putmata Mat=(net*)
			if "`plot'"!=""{
				 nwplot symbionetwork, label(_nodelab) edgesize(symbionetwork) edgecolor(signimat)
			}
		
	}
	if  "`output'"=="matrix"{
		preserve
		capture nwfromedge source target significance,name(signimat)		
		restore
		capture nwfromedge source target weight,name(symbionetwork) undirected
		capture putmata Mat=(net*)
			if "`plot'"!=""{
				capture nwplot symbionetwork, label(_nodelab) edgesize(symbionetwork) edgecolor(signimat)
			}
	}
	if  "`output'"=="edgelist"{
		preserve
		capture nwfromedge source target significance,name(signimat)		
		restore
		preserve
		capture nwfromedge source target weight,name(symbionetwork) undirected
		capture putmata Mat=(net*)
			if "`plot'"!=""{
				capture nwplot symbionetwork, label(_nodelab) edgesize(symbionetwork) edgecolor(signimat)
			}
		restore
		keep source target weight corrcoeff
		order source target weight corrcoeff
	}
	if  "`output'"=="detail"{
		preserve
		capture nwfromedge source target significance,name(signimat)		
		restore
		preserve
		capture nwfromedge source target weight,name(symbionetwork) undirected
		capture putmata Mat=(net*)
			if "`plot'"!=""{
				capture nwplot symbionetwork, label(_nodelab) edgesize(symbionetwork) edgecolor(signimat)
			}
		restore
		order source target weight
	}
	



if  "`output'"=="initial"{
		use `initial',clear
	}
}	
end
