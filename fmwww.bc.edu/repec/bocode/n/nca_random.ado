*! nca_random v0.7 09 jul 2025
cap pro drop nca_random 
pro def nca_random
syntax [namelist], n(numlist min=1 max=1 integer >=1) Slopes(numlist) Intercepts(numlist) [ /// 
		XMean(numlist min=0 ) XSd(numlist min=0 >0) YMean(numlist min=0) YSd(numlist min=0 >0) /// 
		XDistribution(string) YDistribution(string) clear Corner(numlist max=1 integer >0 <5) numsim(integer 1) burn(real 1) ] 
	version 15
	`clear'
		if ("`xdistribution'"=="") local xdistribution uniform
		if ("`ydistribution'"=="") local ydistribution uniform
		if ("`xdistribution'"!="normal" &  "`xdistribution'"!="uniform") {
			di as error "please specify {bf: normal} or {bf: uniform} in option {bf: xdistribution}"
			exit 198
		} 
		if ("`ydistribution'"!="normal" &  "`ydistribution'"!="uniform") {
			di as error "please specify {bf: normal} or {bf: uniform} in option {bf: ydistribution}"
			exit 198
		} 

		if (`:word count `slopes''>1 & `:word count `intercepts''==1) local intercepts=`:word count `slopes''*"`intercepts' "
		if (`:word count `slopes''==1 & `:word count `intercepts''>1) local slopes=`:word count `intercepts''*"`slopes' "
		if (`:word count `slopes''!=`:word count `intercepts'') {
			di as error "{bf: intercepts} and {bf: slopes} should have the same number of arguments"
			exit 198
		}
		if ("`corner'"=="") local corner=1
		if (inlist(`corner',2,3) ) {
			cap numlist "`slopes'", range(<0)
			if (_rc) {
				di in red "{bf:corner(2)} and {bf:corner(3)} are possible only with negative {bf:slopes}" 			
			exit 198
			}
		}
		else if (inlist(`corner',1,4) ) {
			cap numlist "`slopes'", range(>0)
			if (_rc) {
			di in red "{bf:corner(1)} and {bf:corner(4)} are possible only with positive {bf:slopes}" 
			exit 198
			}
		}			
  local nslopes: list sizeof slopes
  
  m: st_local("maxES", strofreal( max_effsize("`slopes'", "`intercepts'", `corner')))


forval i=1/`nslopes' {
	local ss: word `i' of `slopes'
	local ii: word `i' of `intercepts'
	local cond1 = (`ss' > 0) & (`ii' >= 1 | (`ii' + `ss') <= 0)
	local cond2 = (`ss' < 0) & (`ii' <= 0 | (`ii' + `ss') >= 1)
	local cond3 = (`ss' == 0) & (`ii' <= 0 | `ii' >= 1)
if (`cond1' | `cond2' | `cond3') {
	di as error "The combination of slope (`ss') and intercept (`ii') does not provide points in the [(0, 0), (1, 1)] area"
	exit 198
}
  }
if ("`namelist'"=="") {
	if (`nslopes'==1) local Xnames X 
	else m: st_local("Xnames", invtokens("X":+strofreal(1..`nslopes')))
	local Yname Y
	local namelist `Yname' `Xnames'
	}
	else gettoken Yname Xnames : namelist


	cap assert `:word count of `namelist''== `=`nslopes'+2'
	if _rc {
		di as error "incorrect variable namelist (`namelist')"
		exit 198
	}

local n=`n'*`numsim'

quie set obs `=ceil(`burn'`n'/(1-`maxES')*(1+`maxES'))'
  
local ints `intercepts'
local slos `slopes'

if inlist(`corner',3,4) local sign >
else local sign <

		if ("`xdistribution'"=="normal") {
			if ("`xmean'"=="") local xmean=0.5 
			if ("`xsd'"=="") local xsd=0.2 
			local fx rnormal(`xmean',`xsd')

					}
	
		if ("`ydistribution'"=="normal"){
			if ("`ymean'"=="") local ymean=0.5 
			if ("`ysd'"=="") local ysd=0.2 
			local fy rnormal(`ymean',`ysd')
				}
if ("`xdistribution'"=="uniform") local fx runiform()
if ("`ydistribution'"=="uniform") local fy runiform()


quie foreach Xn of local Xnames {
	local ok=0
	gettoken slo slos : slos
	gettoken int ints : ints
	if ("`xdistribution'"=="uniform") gen  `Xn'=runiform()
	else rtnorm , _x(`Xn') m(`xmean') s(`xsd')

local cond="`cond' & `Yname' `sign'= `int' + `slo'*`Xn'	"
}


if ("`ydistribution'"=="uniform") gen `Yname'=runiform()
else rtnorm , _x(`Yname') m(`ymean') s(`ysd') 
quie keep if inrange(`Yname', 0,1)   `cond' 
quie keep in 1/`=`n''
if (_N!=`n') {
	di as error "WARNING: generated less than the required observations. Increase the {bf: burn} option" 
	}
if (`numsim'>1) {
	tempvar ii jj iii
	gen `ii'=mod(_n, `numsim')+1
	bys `ii': gen `jj'=_n
	quie reshape wide  `Xnames' `Yname', i(`jj') j(`ii') /*favor(speed) */
	} 	
end

cap pro drop rtnorm
pro def rtnorm
syntax [if] [in], _x(string) [m(real 0.5) s(real 0.2)]
marksample touse
cap gen `_x'=.
quie replace `_x'=runiform( normal((0-`m')  / `s' ), normal((1-`m')  / `s' )   ) if `touse'
quie replace `_x'=invnormal(`_x')*`s' + `m' if `touse'

end


