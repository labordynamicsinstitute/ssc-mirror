*! nca_power v2 17 mar 2025

pro def nca_power, rclass
version 16
syntax ,[ n(numlist integer >0 sort) Rep(numlist integer >0 min=0 max=1 ) Effect(numlist min=0  max=1 >0 <1) Slope(real 1) Ceiling(namelist max=1) XDistribution(namelist max=1) YDistribution(namelist max=1) Testrep(numlist integer >0 max=1)  XMean(numlist min=0 max=1) XSd(numlist min=0 >0) YMean(numlist min=0 max=1)  YSd(numlist min=0 >0 max=1) Alpha(real `= 0.01*(100-$S_level)') saving(string asis)]
	CheckSaving2 `saving'

if ("`n'"=="") local n 20 50 100
if ("`effect'"=="") local effect = 0.1
if ("`ceiling'"=="") local ceiling "ce_fdh"
if ("`rep'"=="") local rep=100
if ("`testrep'"=="") local testrep=200
if ("`xdistribution'"=="") local xdistribution uniform
if ("`ydistribution'"=="") local ydistribution uniform
// local intercept=1-`effect'-0.5*`slope'
cap mata: st_local("intercept", strofreal(_nca_get_intercept(`effect', `slope') ))
if _rc {
	di as error "error in calculating the intercept"
	exit _rc
}

		if ("`xmean'"=="") local xmean=0.5 
		if ("`ymean'"=="") local ymean=0.5 
		if ("`xsd'"=="") local xsd=0.2 
		if ("`ysd'"=="") local ysd=0.2 
		
		
		if ("`xdistribution'"=="normal") local paramX (`xmean',`xsd')
		else local paramX (.,.)
		if ("`ydistribution'"=="normal") local paramY (`ymean',`ysd')
		else local paramY (.,.)
tempname res df
frame create `df'
	local nnobs=(`:word count of `n''-1)
	matrix `res'=J( `rep',`nnobs',.)
	*matrix rr=`res'
frame `df' {	
	 _dots 0, title(Iterations) reps(`=`rep'*`nnobs'')
	foreach nobs of local n {
		cap matrix drop pval`nobs'
		local namelist __Xx`nobs'_ __Yy`nobs'_
	/*quie mata:  _nca_random5(`nobs',   `rep',   ("`xdistribution'","`ydistribution'"), "`intercept'", "`slope'",  `paramX', `paramY' , "`namelist'",4)*/
	quie nca_random __Yy`nobs'_ __Xx`nobs'_, n(`nobs') i(`intercept') s(`slope') numsim(`rep') xdistribution(`xdistribution') xm(`xmean') xs(`xsd') ydistribution(`ydistribution') ym(`ymean') ys(`ysd') corner(1) clear

	local i=`i'+1
	quie forvalues r=1/`rep' {
		local iter=`iter'+1
		 noi _dots `iter' 0
		cap nca __Xx`nobs'_`r' __Yy`nobs'_`r', ceilings(`ceiling') testrep(`testrep') nograph nosummaries
		if (!_rc) {
			matrix res`nobs'=nullmat(res`nobs')\cond(e(testres)[1,1]<= `alpha',1,0 )
			matrix `res'[`r',`i'] = cond(e(testres)[1,1]<= `alpha',1,0 )
			matrix pval`nobs'=nullmat(pval`nobs')\e(testres)[1,1]
			}
		*if (!_rc) matrix `res'[`r',`i'] = e(testres)[1,1]  
		*matrix rr[`r',`i']=e(testres)[1,1]  
	}
local rnames `rnames' "n`nobs'"
	}
	clear 
	matrix colnames `res'=`rnames'
	quie svmat `res', names(col)
	quie tabstat *, save
	matrix `res'=r(StatTotal)
	matrix colnames `res'=`n'
	matrix rownames `res'=Power
	if ("`saving'"!="") save `saving'
	}
	matrix `res'=`res''
	
	di _n"{bf:Power analysis for NCA} (`rep' replications):" 
	di as text "effect size = " as result `effect'
	di as text "slope = " as result `slope'
	di as text "intercept= " as result `intercept'
	di as text "ceiling: {bf:`ceiling'}"
	di as text "distribution of X: {bf:`xdistribution'}"_n"distribution of Y: {bf:`ydistribution'}"
	di as text "alpha = " as result `alpha'
	
	matlist `res' , rowtitle("n=")
return matrix results=`res'
end

program CheckSaving2
	version 8.2
	capture syntax [anything(id="filename" equalok)] [, replace ]
	if c(rc) {
		di as err "invalid saving() option"
		syntax [anything(id="filename" equalok)] [, replace ]
		exit 198
	}
	if 	(substr(`"`anything'"', -4,4)!=".dta") 	{
		local anything "`anything'.dta"
	}
	if "`replace'" != "" & `"`anything'"' == "" {
		di as err "invalid saving() option, filename is required"
		exit 198
	}
	if "`replace'" == "" & `"`anything'"' != "" {
	cap confirm file `"`anything'"'
		if (!_rc) {
			di in red "file {bf:`anything'} already exists"
			exit 602
		} 
	}
	end
