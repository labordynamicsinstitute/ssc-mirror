*! nca_random v2 10 feb 2025
cap pro drop nca_random 
pro def nca_random
syntax [namelist], n(numlist min=1 max=1 integer >=1) Slopes(numlist) Intercepts(numlist) [ /// 
		XMean(numlist min=0 ) XSd(numlist min=0 >0) YMean(numlist min=0) YSd(numlist min=0 >0) /// 
		XDistribution(string) YDistribution(string) clear CORner(numlist max=1 integer >0 <5) numsim(integer 1)]
	version 15
	
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
  
  
forval i=1/`nslopes' {
	local ss: word `i' of `slopes'
	local ii: word `i' of `intercepts'
	local cond1 = (`ss' > 0) & (`ii' >= 1 | (`ii' + `ss') <= 0)
	local cond2 = (`ss' < 0) & (`ii' <= 0 | (`ii' + `ss') >= 1)
	local cond3 = (`ss' == 0) & (`ii' <= 0 | `ii' >= 1)
if (`cond1' | `cond2' | `cond3') {
	di as error "The combination of slope and intercept does not provide points in the [(0, 0), (1, 1)] area"
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
	/*
tempvar Xinteg Yinteg
tempname bdc
frame create `bdc' 
quietly frame `bdc' {
	clear 
	set obs 2
	gen `Xinteg'=0 in 1
	replace  `Xinteg'=1 in 2
	gen `Yinteg'=`slopes'*`Xinteg' + `intercepts'
	replace `Yinteg'=0 if `Yinteg'<=0
	replace `Yinteg'=1 if `Yinteg'>=1
	list `Xinteg' `Yinteg' in 1/2
	integ `Yinteg' `Xinteg', trap
}
local effsize=1-r(integral)
di in red `effsize'*/
local n=`n'*`numsim'
`clear'
set obs `n'
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
	gen `Xn'=.
	
	if (`corner'==1) {
		local xmin= max(0 , `=  - `int'/`slo'')
		local xmax=1
	}
	if (`corner'==3) {
		local xmin= max(0 , `=  (1 - `int')/`slo'')
		local xmax=1
	}
	if (`corner'==2) {
		local xmin=0	
		local xmax=min(1 , `= - `int'/`slo'')
	}
	if (`corner'==4) {
		local xmin=0	
		local xmax=min(1 , `=  (1 - `int')/`slo'')
	}
	while (`ok'==0) {
		if ("`xdistribution'"=="uniform") {
		replace  `Xn'=`fx' if !inrange(`Xn',`xmin',`xmax')
		}
		else rtnorm if !inrange(`Xn',`xmin',`xmax'), _x(`Xn') m(`xmean') s(`xsd')
		count if !inrange(`Xn',`xmin',`xmax')
		if (r(N)==0) local ok=1
		}

	
local cond="`cond' & `Yname' `sign'= `int' + `slo'*`Xn'	"
}

quie gen `Yname'=.
local ok=0
quie while (`ok'==0) {
	if ("`ydistribution'"=="uniform") {
	replace  `Yname'=`fy' if ! ( inrange(`Yname',0,1)  `cond')
	}
	else rtnorm if ! ( inrange(`Yname',0,1)  `cond'), _x(`Yname') m(`ymean') s(`ysd')
	count if ! ( inrange(`Yname',0,1)  `cond')
	if (r(N)==0) local ok=1
	}

if (`numsim'>1) {
	tempvar ii jj iii
	gen `ii'=mod(_n, `numsim')+1
	bys `ii': gen `jj'=_n
	quie reshape wide  `Xnames' `Yname', i(`jj') j(`ii') favor(speed) 
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

/*
nca_random2 , n(100) s(-1 -.3) i(1 1 ) clear numsim(3) yd(uniform) xd(uniform) corner(2) 
/*
tw (scatter Y1 X1) (function y=.5 + x, range(0 1))