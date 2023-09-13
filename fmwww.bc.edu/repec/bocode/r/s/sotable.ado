*! version 14.1.0 02Mar2023
//  changed supw to maxt
// version 14.0.0 07Sep2022
//    documented alternative and made default level
//       c(level) if alternative=="two"
//       c(level) + (100-c(level))/2 if alternative!="two"
// version 13.0.0 07Sep2022
//    added message for possible constant term
// version 13.0.0 07Sep2022
// 		renamed sci to sotable
// version 12.0.1 04Sep2022
// 		Updated output
// version 12.0.0 06May2022
// 		replace UPPERtail and LOWERtail with
//  		UNDOCUMENTED ALTernative(upper | lower | two)
//
// 		  added p-values for upper-tail and lower-tail tests against zero
// 		  added p-values for upper-tail and lower-tail tests against zero
// version 11.0.0 07Jan2022
// 		add Genz-Bretz method implemented by Grayling and Mander
// version 11 changes default draws to be 1000000 for simulation-based methods
// version 11 requires Grayling-Mander code
// version 10.0.0 04Jan2022
// version 10 add pvalues
// version 9 adds UNDCOUMENTED options UPPERtail and LOWERtail
// version 8.0.0  05Jul2021 was submitted to SJ with Multiple CB article
program define sotable, rclass

	version 16

	syntax  [, 							///
		pnames(string) 					///
		pelements(string) 				///
		ALTernative(string)				/// 
		level(numlist min=1 max=1 >=5 <=99.5 )					///
		draws(string)					///
		NORMAL							/// 
		method(string) 					/// NOT DOCUMENTED
		nmethod(string)				    /// SIMulation or GBretz (NOT DOCUMENTED)
		]


	if "`e(properties)'" != "b V" {
		if "`e(prefix)'" == "bayes" {
			di "{p}{err}Bayesian commands not supported{p_end}"
		}
		else { // This also catches bayesmh
			di "{p}{err}`e(cmd)' does not have properties b and V{p_end}"
		}
		exit 498
	}

	nmethodparse , `nmethod'
	local nmethod `r(nmethod)'

// default draws is 1,000,000 for simulation
// default draws is 2,000    for gbretz
	drawsparse , draws(`draws') nmethod(`nmethod')
	local draws `r(draws)'

	altparse , `alternative'
	local alternative `r(alternative)'

	if "`alternative'" == "two" {
		if "`level'" == "" {
			local level = c(level)
		}
	}
	else {
		if "`level'" == "" {
			local level = c(level) + (100-c(level))/2
		}
	}

	tempname b V results c
	if "`pnames'" != "" & "`pelements'" != ""  {
		di "{err}pnames() may not be specified with pelements()"
		di "   specify pnames() or pelements(), not both"
		exit 498
	}
	else if "`pnames'" != "" {
		sotable_getextract , plist(`pnames')
		local toget "`r(toget)'"
		if "`toget'" == "" {
			di "{err}no parameters found"
			exit 498
		}
		
		matrix `b' = e(b)
		matrix `V' = e(V)
		mata: GetEof("`b'", "`V'", "`toget'")
	}
	else if "`pelements'" != "" {

// parse and get elements in pelements
		local p = colsof(e(b))
		numlist "`pelements'" , integer ascending range(>=1 <=`p')
		local toget "`r(numlist)'"
		matrix `b' = e(b)
		matrix `V' = e(V)
		mata: GetEof("`b'", "`V'", "`toget'")
	}
	else {
// Use all parameters
		matrix `b' = e(b)
		matrix `V' = e(V)

		local fnames : colfullnames `b'
		local bk = colsof(`b')
		forvalues j=1/`bk' {
			if `V'[`j',`j'] != 0 {
				local rlist `rlist' `j'
				local tmp : word `j' of `fnames'
				local nnames `nnames' `tmp'
			}
		}
		tempname rv
		mata: `rv' = strtoreal(tokens("`rlist'"))
		mata: `V' = st_matrix("`V'")
		mata: st_matrix("`V'", `V'[`rv'', `rv'])
		mata: `b' = st_matrix("`b'")
		mata: st_matrix("`b'", `b'[1, `rv'])
		mata: mata drop `rv' `V' `b'

		matrix colnames `b' = `nnames'
		matrix colnames `V' = `nnames'
		matrix rownames `V' = `nnames'

	}
	
	local tmp : colnames `b'
	local tmp : subinstr local tmp "_cons" "_cons" , word count(local hascons)

	local p2 = colsof(`b')
	if `p2'==1 {
		local method "scomparison"
	}

// method can be    interest                doc/not doc    nmethod 
// maxt				main interest		    document       simulation or gbretz
// bonferroni	    historical interest     document       simulation
// scomparison      only one parameter		not document   Stata functions
// other #          testing only			not document   simulation
	if "`method'" != "" {

		local method_orig
		mparse , `method'
		local method `r(method)'

		if "`method'" == "" {
			di "{red}method(`method_orig') invalid"
			exit 498
		}
	}
	else {
		local method maxt
	}

	if "`normal'"=="" {
		local df_r = e(df_r)
		if `df_r'<. {
			local distribution "t"
		}
		else {
			local distribution "z"
			local df_r = .
		}
	}
	else  {
		local distribution "z"
		local df_r = .
	} 

	if "`method'" == "maxt" & "`nmethod'" == "gbretz" {
		gbretz , b(`b') v(`V')  alternative(`alternative') level(`level') 	///
			distribution(`distribution' `df_r') draws(`draws')
		matrix `results' = r(results)
		scalar `c' = r(c)
	}
	else {
		mata: GetResults(		///
			"`b'", 				///
			"`V'", 				///
			"`method'",			///
			"`alternative'",	///
			`level',			///
			"`distribution'",	///
			`df_r',				///
			`draws',			///
			"`results'",		///
			"`c'"				///
		)
	}
		
	local colnames : colfullnames `b'
	matrix colnames `results' = `colnames'
	matrix rownames `results' = b se `distribution' pvalues low up

	tempname rm 
	matrix `rm' = `results'
	return clear
	return matrix results = `results'
	return matrix b       = `b'
	return matrix V       = `V'
	return scalar c       = `c'
	return scalar draws   = `draws'
	return local hascons  = cond(`hascons'>=1, "hascons", "")
	return local method      "`method'"
	return local nmethod     "`nmethod'"
	return local dist      "`distribution'"
	return local level     `level'
	if (`df_r'<.) {
		return scalar df_r = `df_r'
	}
	return local alternative `alternative'

// Store overall p-value
	tempname overall_p
	mata: st_numscalar("`overall_p'", min(st_matrix("`rm'")[4,.]))
	return scalar p = `overall_p' 

	Header , method(`method') c(`c') p(`overall_p') df_r(`df_r')
	_my_tab2, rm(`rm') distribution(`distribution') level(`level')
	if `hascons'>=1 {
		di "{p 4 4}One of the included parameters may be a constant term{p_end}"
	}

end

program define Getpvgm, rclass
	
	syntax , tvalue(real) draws(numlist max=1 integer >=1000) 	///
		sigma(string) side(string) distribution(string)

// NB: distribution z . or t #
	gettoken dist df : distribution

// side is lower, upper, two

	local k = colsof(`sigma')
	forvalues j=1/`k' {
	if `j' < `k' {
			local comma ","
		}
		else {
			local comma ""
		}


		if "`side'" == "two" {
			local val  = abs(`tvalue')
			local mval = -1*`val'
		}
		else if "`side'" == "lower" {
			local val  = .
			local mval = (`tvalue')
		}
		else if "`side'" == "upper" {
			local val  = (`tvalue')
			local mval = .
		}
		else {
			di "{err}invalid side(`side')"
			exit 498
		}
		local lower `lower' `mval'`comma'
		local upper `upper' `val'`comma'    
		
	}

	if "`dist'" == "z" {
		qui pmvnormal,  lower(`lower') upper(`upper') samples(`draws') sigma(`sigma')
		local integral = r(integral)
//		local pv = 1 - r(integral)
	}
	else { // must be t(df)
		qui mvt,  lower(`lower') upper(`upper') samples(`draws') df(`df') sigma(`sigma')
		local integral = r(integral)
//		local pv = 1 - r(integral)
	}
	if "`side'" == "lower" {
		local pv = 1- `integral'
	}
	else {
		local pv = 1 - `integral'
	}

	return scalar pvalue = `pv'

end

program define gbretz, rclass

	syntax , b(string) v(string) level(string) 					///
		alternative(string)										///
		[ distribution(string) df(numlist integer max=1 >=10)	///
		draws(string) ]	

// removed oneside(string) 

// tail is my word used in Getpvgm
// qtail is Grayling-Mander word used in invmvnormal and invmvt

	if "`alternative'" == "two" {
		local tail    = "two"
		local qtail   = "both"
	}
	else if "`alternative'" == "lower" {
		local tail    = "lower"
		local qtail   = "lower"
	}
	else if "`alternative'" == "upper" {
		local tail    = "upper"
		local qtail   = "lower"
	}
	else {
		di "{red}alternative `alternative' invalid"
		exit 498
	}

/*
	if "`oneside'" == "" {
		local tail    = "two"
		local qtail   = "both"
	}
	else if "`oneside'" == "lowertail" {
		local tail    = "lower"
		local qtail   = "lower"
	}
	else if "`oneside'" == "uppertail" {
		local tail    = "upper"
		local qtail   = "lower"
	}
	else {
		di "{red}oneside value of `oneside' invalid"
		exit 498
	}
*/

	tempname tvalues pvalues se C low up
	mata: `se' = sqrt(diagonal(st_matrix("`v'"))')
	mata: st_matrix("`se'", `se')
	mata: `b'  = st_matrix("`b'")

	mata: st_matrix("`tvalues'", `b':/`se')
	mata: mata drop `se' `b'

	matrix `C'       = corr(`v')
	local   k        = colsof(`C')
	matrix `pvalues' = J(1, `k', .)
	matrix `low'     = J(1, `k', .)
	matrix `up'      = J(1, `k', .)

// NB: distribution z . or t #
	gettoken dist df : distribution
// Get critical value
	
	local plevel = `level'/100
	if "`dist'" == "z" {
		qui invmvnormal , p(`plevel') sigma(`C') tail(`qtail') samples(`draws')
		local c = r(quantile)

		forvalues j=1/`k' {
			local tval = `tvalues'[1,`j']
			Getpvgm , tvalue(`tval') draws(`draws') sigma(`C') distribution(`distribution') side(`tail')
			matrix `pvalues'[1,`j'] = r(pvalue)
		}
	}
	else if "`dist'" == "t" {
//NB: df is either empty or a valid integer
//!! can be unusably slow

		di "{p 4 4 2}Note: This computation can take a very long time{p_end}"
		di "{p 7 7 2}{bf:invmvt} can take a very long time when there are "
		di "many parameters{p_end}"

		qui invmvt , p(`plevel') sigma(`C') tail(`qtail') samples(`draws') df(`df') 
		local c = r(quantile)

		forvalues j=1/`k' {
			local tval = `tvalues'[1,`j']
			Getpvgm , tvalue(`tval') draws(`draws') sigma(`C') distribution(`distribution') side(`tail')
			matrix `pvalues'[1,`j'] = r(pvalue)
		}
	}
	else {
		di "{err}distribution(`distribution') invalid"
		exit 498
	}

	if "`alternative'" == "two" {
		forvalues j = 1/`k' {
			matrix `low'[1,`j'] = `b'[1,`j'] - `c'*`se'[1,`j']
			matrix `up'[1,`j']  = `b'[1,`j'] + `c'*`se'[1,`j']
		}
	}
	else if "`alternative'" == "upper" {
		forvalues j = 1/`k' {
			matrix `low'[1,`j'] = `b'[1,`j'] - `c'*`se'[1,`j']
			matrix `up'[1,`j']  =  .
		}
	}
	else if "`alternative'" == "lower" {
		local c = -(`c')
		forvalues j = 1/`k' {
			matrix `low'[1,`j'] = .
			matrix `up'[1,`j']  = `b'[1,`j'] - `c'*`se'[1,`j'] 
		}
	}
	else {
		di "{err}alternative `alternative' invalid"
		exit 498
	}

	tempname results
	matrix `results'      = (`b' \ `se' \ `tvalues' \ `pvalues' \ `low' \ `up') 

	return matrix results = `results'
	return scalar c       = `c'
end

program Header

	syntax , method(string)  c(name) p(name) [df_r(string)]

	gettoken method value : method
	
	if "`method'" == "scomparison" {
		di
		di "Single-comparison results "
	}
	else if "`method'" == "bonferroni" {
		di
		di "Bonferroni results"
	}
	else if "`method'" == "other" {
		di
		di "Simultaneous results (other method)"
	}
	else if "`method'" == "maxt" {
		di
		di "Max-t results"
	}
	else {
		di "{err}method `method' invalid"
		exit 498
	}
	di "       p-value = " %-5.3f `p'
	di "Critical value = " %-7.3f `c'
end

// _my_tab2.ado
program _my_tab2

	syntax , rm(string) distribution(string) level(cilevel)

	tempname results
	matrix `results' = `rm'

	tempname mytab z t p ll ul w
	.`mytab' = ._tab.new, col(7) lmargin(0)
        .`mytab'.width    13   |12    12     7     8    12    12
        .`mytab'.titlefmt  .     .     .     .     .  %24s     .
        .`mytab'.pad       .     2     1     1     2     3     2
        .`mytab'.numfmt    . %9.0g %9.0g %7.3f %5.3f  %9.0g %9.0g
        local namelist : colname `results'
        local eqlist : coleq `results'
        local k : word count `namelist'
        .`mytab'.sep, top
        if `:word count `e(depvar)'' == 1 {
                local depvar "`e(depvar)'"
        }
		else {
                local depvar "depvar"
		}
        .`mytab'.titles "`depvar'"                      /// 1
                        "Coef."                         /// 2
                        "Std. Err."                     /// 3
                        "`distribution'"           		/// 4
						"   P>|`distribution'|"         /// 5
                        "[`level'% Conf. Band]" ""  	//  6 7
        forvalues i = 1/`k' {
                local name : word `i' of `namelist'
                local eq   : word `i' of `eqlist'
                if "`eq'" != "_" {
                        if "`eq'" != "`eq0'" {
                                .`mytab'.sep
                                local eq0 `"`eq'"'
                                .`mytab'.strcolor result  .  .  .  .  .  . 
                                .`mytab'.strfmt    %-12s  .  .  .  .  .  .
                                .`mytab'.row      "`eq'" "" "" "" "" "" ""
                                .`mytab'.strcolor   text  .  .  .  .  .  . 
                                .`mytab'.strfmt     %12s  .  .  .  .  .  .
                        }
                        local beq "[`eq']"
                }
                else if `i' == 1 {
                        local eq
                        .`mytab'.sep
                }
				local b   = `results'[1,`i']
                local se  = `results'[2,`i'] 
                local w   = `results'[3,`i'] 
				local pv  = `results'[4,`i'] 
                local low = `results'[5,`i']
                local up  = `results'[6,`i'] 

                .`mytab'.row    "`name'" `b' `se' `w' `pv' `low' `up'
                                
        }
        .`mytab'.sep, bottom
end

// _my_tab.ado
program _my_tab

	syntax , rm(string) distribution(string) level(cilevel)

	tempname results
	matrix `results' = `rm'

	tempname mytab z t p ll ul w
	.`mytab' = ._tab.new, col(6) lmargin(0)
        .`mytab'.width    13   |12    12  6    12    12
        .`mytab'.titlefmt  .     .     .  .     %24s  .
        .`mytab'.pad       .     2     1  1     3     2
        .`mytab'.numfmt    . %9.0g %9.0g %6.2f %9.0g %9.0g
        local namelist : colname `results'
        local eqlist : coleq `results'
        local k : word count `namelist'
        .`mytab'.sep, top
        if `:word count `e(depvar)'' == 1 {
                local depvar "`e(depvar)'"
        }
		else {
                local depvar "depvar"
		}
        .`mytab'.titles "`depvar'"                      /// 1
                        "Coef."                         /// 2
                        "Std. Err."                     /// 3
                        "`distribution'"           		/// 4
                        "[`level'% Conf. Band]" ""  	//  5 6
        forvalues i = 1/`k' {
                local name : word `i' of `namelist'
                local eq   : word `i' of `eqlist'
                if "`eq'" != "_" {
                        if "`eq'" != "`eq0'" {
                                .`mytab'.sep
                                local eq0 `"`eq'"'
                                .`mytab'.strcolor result  .  .  .  . . 
                                .`mytab'.strfmt    %-12s  .  .  .  . .
                                .`mytab'.row      "`eq'" "" "" "" "" ""
                                .`mytab'.strcolor   text  .  .  .  . .
                                .`mytab'.strfmt     %12s  .  .  .  . .
                        }
                        local beq "[`eq']"
                }
                else if `i' == 1 {
                        local eq
                        .`mytab'.sep
                }
				local b   = `results'[1,`i']
                local se  = `results'[2,`i'] 
                local w   = `results'[3,`i'] 
                local low = `results'[5,`i']
                local up  = `results'[6,`i'] 

                .`mytab'.row    "`name'" `b' `se' `w' `low' `up'
                                
        }
        .`mytab'.sep, bottom
end


program define mparse, rclass

	syntax , [ bonferroni maxt scomparison 	///
		other(numlist max=1 min=1 >0)]

	local spec `bonferroni' `maxt' `scomparison' `other'
	local n_spec : word count `spec'
	if `n_spec' > 1 {
		di "{err}method(`0') invalid"
		di "only only method may be specified"
		exit 498
	}

	if "`other'" != "" {
		return local  method   other `other'

	}
	else {
		return local method  `spec'
	}
	

end

program define drawsparse, rclass

	syntax , nmethod(string) [ draws(numlist integer max=1 >=1000) ]

	if `"`nmethod'"' == "simulation" {
		if "`draws'" == "" {
			local draws 1000000
		}

		if (`draws'<10000) {
			display "note: Very few draws used to estimate critical value"
		}

		if (`draws'<1000) {
			display "{err}Too few draws used to estimate critical value"
			exit 498
		}
	}
	else if `"`nmethod'"' == "gbretz" {
		if "`draws'" == "" {
			local draws 2000
		}
	}
	else {
		di "{err}illegal nmethod passed to drawsparse"
		exit 498
	}

	return local draws `draws'
end

program define altparse, rclass

	syntax , [ lower upper two ]

	local ocount : word count `lower' `upper' `two'
	if `ocount' == 0 {
		local alternative two
	}
	else if `ocount' > 1 {
		di "{err}More than one alternative specified"
		di "Only one of the alternatives may be specified."
		exit 498
	}
	else {
		local alternative `lower' `upper' `two'
	}

	return local alternative `alternative'
end

program define nmethodparse, rclass

	syntax [, SIMulation GBretz  *]
	if `"`options'"' != "" {
		di `"{err}nmethod(`0') invalid"'
		exit 498
	}

	if "`simulation'" != "" & "`gbretz'" != "" {
		di "{err}simulation and gbretz cannot both be specified"
		exit 498
	}
	else if "`simulation'" == "" & "`gbretz'" == "" {
		local nmethod simulation
	}
	else {
		local nmethod `simulation' `gbretz'
	}

	return local nmethod `nmethod'

end


mata:

void GetEof(				///
	string scalar	bname, 	///
	string scalar	vname,	///
	string scalar	toget
)
{

	real vector 	r, b
	real matrix		V
	string matrix	colstripe

	r         = strtoreal(tokens(toget))
	b         = st_matrix(bname)
	V         = st_matrix(vname)

	colstripe = st_matrixcolstripe(bname)
	colstripe = colstripe[r', .]
	st_matrix(bname, b[1, r])
	st_matrix(vname, V[r', r])
	st_matrixcolstripe(bname, colstripe)
	st_matrixcolstripe(vname, colstripe)
	st_matrixrowstripe(vname, colstripe)


}
// see -centile- methods and formulas
real scalar MyCentile(real colvector w, real scalar p)
{
	real scalar 	k, d, q, n, v
	real colvector 	x

	x = sort( w, 1)
	n = rows(x)
	v = p*(n+1)
	k = floor(v)
	d = v - k

	if (k==0) {
		q = x[1]
	}
	else if (k<n) {
		q = x[k] + d*(x[k+1] - x[k])	
	}
	else { // k>=n
		q = x[n]
	}

	return(q)
}

void GetResults(			///
	string scalar bname,	/// in  vector of point estimates
	string scalar vname,	/// in  matrix with VCE
	string scalar method,	/// in  method to use
	string scalar alternative,	/// in upper, lower, or two
	real   scalar level,	/// in  CI level
	string scalar distribution,	/// in  distribution is "t" or "z"
	real   scalar df_r,		/// in  degrees of freedom for t distribution
	real   scalar draws,    /// in  number of MC draws
	string scalar rname,	/// out name of Stata matrix to hold CI
	string scalar cname 	/// out name of Stata scalar to hold critical value
)
{

	real scalar		c, aotwo, n_mc, p, ig, j, k
	real rowvector	b, up, low, tvals, pvals
	real vector		se, m
	real matrix		V, P, Z
	string vector	methodvec

	n_mc = draws
	b    = st_matrix(bname)
	V    = st_matrix(vname)
	se   = sqrt(diagonal(V)')
	p    = cols(b)
	tvals = b:/se
	k     = cols(tvals)
	pvals = J(1, cols(b), .)
	
	alpha = 1 - level/100

	method = tokens(method)
	if (method[1]=="scomparison") {
		if (alternative=="two") {
			aotwo   = 1 - alpha/2
		}
		else if (alternative == "upper") {
			aotwo   = 1 - alpha
		}
		else { // alternative of lower
			aotwo   = alpha
		}
		if (distribution=="t") {
			if (alternative=="two") {
				pvals   = 2*ttail(df_r, abs(tvals))
			}
			else if (alternative == "upper") {
				pvals   = ttail(df_r, tvals)
			}
			else { // alternative of lower
				pvals   = t(df_r, tvals)
			}
			c     = invt(df_r, aotwo) 
		}
		else {
			if (alternative=="two") {
				pvals = 2*(1:-normal(abs(tvals)))
			}
			else if (alternative == "upper") {
				pvals = (1:-normal(tvals))
			}
			else { // alternative of lower
				pvals   = normal(tvals)
			}
			c     = invnormal(aotwo) 
		}
	}
	else if (method[1]=="bonferroni") {
		if (alternative=="two") {
			aotwo  = 1 - alpha/(2*p)
		}
		else {
			aotwo  = 1 - alpha/(p) 		//!! check this 
		}
		if (distribution=="t") {
			c   = invt(df_r, aotwo) 
			pvals = p*2*ttail(df_r, abs(tvals))
		}
		else {
			c   = invnormal(aotwo) 
			pvals = p*2*(1:-normal(abs(tvals)))
		}

		for(j=1; j<=k; j++) {
			if (pvals[1,j] > 1) {
				pvals[1,j] = 1
			}
		}
	}
	else if (method[1]=="maxt") {
		P = cholesky(V)
		if (missing(P)>0) {
			printf("{err}VCE is is not full rank\n")
			printf("{text}Cannot calculate critical value when the ")
			printf("the VCE is not full rank\n")
			printf("Request subset of parameters that has full rank VCE\n")
			exit(error(498))
		}
		Z = rnormal(n_mc, cols(V), 0, 1)
		Z = Z*(P')
		if (distribution=="t") {
			ig =  sqrt(df_r:/rchi2(n_mc, 1, df_r))
			Z = Z:*ig 
		}
		if (alternative=="two") {
			m = rowmax(abs(Z:/se))
			c = MyCentile(m, level/100)
			for(j = 1; j<=cols(b); j++) {
				pvals[j] = (1/rows(m))*sum(m :> abs(tvals[j]))
			}
		}
		else if (alternative == "upper") {
			m = rowmax(Z:/se)
			c = MyCentile(m, level/100)
			for(j = 1; j<=cols(b); j++) {
				pvals[j] = (1/rows(m))*sum(m :> tvals[j])
			}
		}
		else { // alternative of lower
			m = rowmin((Z:/se))			
			c = MyCentile(m, (100-level)/100) // NB: c<0
			for(j = 1; j<=cols(b); j++) {
				pvals[j] = (1/rows(m))*sum(m :< tvals[j])
			}
		}
	}
	else if (method[1]=="other") {
		c = strtoreal(method[2])
	}
	else {
		printf("method %s invalid\n", invtokens(method))
		exit(error(498))
	}

	if (alternative == "lower") {
		low   = J(1, cols(b), .)
		up    = b - c*se		 
	}
	else if (alternative == "upper") {
		low   = b - c*se
		up    = J(1, cols(b), .)
	}
	else if (alternative == "two") {
		low   = b - c*se
		up    = b + c*se
	}
	else {
		printf("{err}alternative must be lower, upper, or two\n")
		exit(error(498))
	}

	st_matrix(rname, (b \ se \ tvals \ pvals \ low \ up))
	st_numscalar(cname, c)

}

end

exit

syntax [, pnames({namelist}|{numlist}) method(bonferroni|maxt) ]

examples

sotable 
	produces maxt CI for all the parameters in e(V)

sotable , pnames({namelist}) produces maxt CI for the parameters in namelist
	namelist operates on parameters in first equation by default
	include eqn name in namelist to include parameters from other equations

sotable , pelements({numlist}) 
	produces maxt CI for the parameters in numlist

scsi , method(bonferroni) 
	produces bonferroni CI for all the parameters in e(V)


saved results

	e(results) 
	1 x p matrix containing

	b
	lower
	upper

	col names are names from e(b)
	row names b, lower, upper, respectively
// notes
// version 2, add pnames
