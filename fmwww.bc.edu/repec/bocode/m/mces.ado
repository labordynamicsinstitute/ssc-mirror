*mces.ado
*Version 2.0--November 12, 2021

capture program drop mces
program mces, rclass
version 12.0

syntax  [ , SDBYvar(string) SDUpdate COHensd HEDgesg NOWarning Force]

tempname RT
matrix `RT' = r(table_vs)

if `c(userversion)' > 12 version `c(userversion)'
	
tempname B C E D

local coh `" if "`cohensd'" == "cohensd" "'
local unw " "
`coh' local unw "unweighted"

local hedges `" else if "`hedgesg'" == "hedgesg" "'

if "`cohensd'" != "cohensd" & "`hedgesg'" != "hedgesg" local rmseo = 1
else local rmseo = 0

`coh' local esname `"Cohen's d"'
`hedges' local esname `"Hedges's g"'
else {
	if `c(version)' < 14 local esname "RMSE-based Delta"
	else local esname "RMSE-based Δ"
	}

*If Cohen's d or Hedges's g, confirm sdbyvar
if "`cohensd'" == "cohensd" | "`hedgesg'" == "hedgesg" {
	capture confirm variable `sdbyvar'
	if _rc {
	    di as error _n "When using the {cmd:cohensd} or {cmd:hedgesg} options, you must specify a valid {cmd:sdbyvar}."
		exit = 198   
		}
	}
*If not, make sure there's no sdbyvar
else {
	if "`sdbyvar'" != "" {
	    di as error _n "Only specify an {cmd:sdbyvar} when also using the {cmd:cohensd} or {cmd:hedgesg} options."
		exit = 198   
		}	
	}
	
*check to see if it's svyset, mi svyset, or not
capture mi svyset
if !_rc {
    if "`r(settings)'" == ", clear" local svyflag = 0
    else local svyflag = 1
    }
else {
    capture svyset
    local rsettings = "`r(settings)'"
    if "`rsettings'" != ", clear" local svyflag = 1
    else {
        local svyflag = 0
        }
    }

*make sure that margins included -pwcompare- 
if `"`e(cmd)'"' != "pwcompare" {
    di as error _n "{cmd:mces} is designed for use after {cmd:margins} with the {cmd:pwcompare post} options." 
    exit = 301
    }

*check that -pwcompare- actually has something to compare
if strpos(`"`e(cmdline)'"', "pwcompare") > 0 & `"`e(cmd)'"' != "pwcompare" {
    di as error _n "{cmd:mces} requires at least two estimates for comparison."
    exit = 301    
    }

*make sure that the last command was -margins- or -mimrgns-
if `"`e(cmd2)'"' == "margins" {
    local miflag = 0
    }
else if `"`e(cmd2)'"' == "mimrgns"  {
    local miflag = 1
    }
else {
    di as error _n "{cmd:mces} works after {cmd:margins, pwcompare post} or {cmd:margins, contrast post} only." 
    exit = 301
    }

local mi "if `miflag' == 1"

*Name matrices

matrix `B' = e(b_vs)
local nummargins = colsof(`B')

matrix `C' = `B'


`mi' matrix `D' = e(df_mi)


matrix `E' = e(error_vs)


*Confirm that matrices exist
local er1 "Either something has cleared the stored estimation results,"
local er2 "or your estimation command is not supported." 
local errmsg `"_n `er1'" _n "`er2'"'

capture confirm matrix `B'
if _rc {
	di as error "`errmsg'"
	exit = 301
	} 

capture confirm matrix `E'
if _rc {
    di as error "`errmsg'"
    exit = 301
    }

*get the dependent variable from -margins- or -mimrgns-
local cmdline `e(est_cmdline)'

local pos = 1
while `pos' > 0 {
    local pos = ustrpos(`"`cmdline'"',":")
    local len = ustrlen(`"`cmdline'"')
    local rlen = `len' - `pos'
    local cmdline = ustrright(`"`cmdline'"',`rlen')
    }

tokenize `"`cmdline'"'
local i = 1
while `i' < 111 {
    capture confirm variable `1'
    if _rc {
        local ++i 
        macro shift
        }
    else {
        local depvar `"`1'"'
        continue, break
        }
    }

*If -sdupdate-, make sure that there is an sdbyvar
if "`sdupdate'" == "sdupdate" & `rmseo' == 0 {
		di as error _n "Option {cmd:sdbyvar} is required for option {cmd:sdupdate}."
		exit = 198   
	}

*If -sdupdate-, make sure that the request is either cohensd or hedgesg
if "`sdupdate'" == "sdupdate" & `rmseo' == 1 {
		di as error _n "Option {cmd:sdupdate} is only allowed with the {cmd:hedgesg} and {cmd:cohensd} options."
		exit = 198   
	}

*Make sure sdbyvar and depvar are not the same (for d and g)
if `rmseo' != 1 {
	if "`sdbyvar'" == "`depvar'" {
		di as error _n "The {cmd:sdbyvar} may not be the same as the outcome variable."
		exit = 198
		}
	}
local vallab `"`: value label `depvar''"'
qui tab `depvar'

*Make sure the dependent variable is continuous
if  "`vallab'" == "Cont" | "`vallab'" == "" | `r(r)' > 8 {
    }
else if "`force'" != "force" {
    di as error _n "{cmd:mces} may not be appropriate for your " ///
                "outcome variable as it appears to be categorical."
	di "It is designed to be used with continuous outcome variables."
    di "Use the {cmd:force} option to bypass this check in the future."
    exit = 499
    }

local w1 "The standard deviation used for estimation only applies to ceteris paribus"
local w2 "    comparisons between groups defined by {cmd:`sdbyvar'}. Otherwise, the results are invalid."
local w3 "Ensure that this condition applies to each line of the {cmd:margins} results."
local w4 "You may want to run {cmd:margins, pwcompare post} followed by {cmd:mces} once per dichotomous comparison."
local warning `"_n as error "WARNING: " as text "`w1'" _n "`w2'" _n "`w3'" _n "`w4'" _n"'

local rw2 "    comparisons between groups defined by a single dichotomous variable. Otherwise, the results are invalid."
local rwarning `"_n as error "WARNING: " as text "`w1'" _n "`rw2'" _n "`w3'" _n "`w4'" _n"'

local e1 "The standard deviation used for estimation only applies to ceteris"
local e2 "    paribus comparisons between the two groups defined by {cmd:`sdbyvar'}."
local e3 "The estimated effect sizes are invalid if the {cmd:marginlist} contains more than one variable,"
local e4 "    or if there are too many {cmd:by/over/within/at} variables,"
local e5 "    or if there are more than two values of a {cmd:by/over/within/at} variable."
local e6 "You may want to run {cmd:margins, pwcompare post} followed by {cmd:mces} once per dichotomous comparison."
local e7 "You might also try {cmd:recode, generate()} to generate dichotomous comparison variables."
local exit_warning `"_n as error "ERROR: " as text "`e1'" _n "`e2'" _n "`e3'" _n "`e4'" _n "`e5'" _n "`e6'" _n "`e7'" _n"'
	
*count mvars
tokenize "`e(cmdline)'", parse(",")
tokenize "`1'"
local mvars = 0

while "`1'" != "" {
    capture confirm variable `1'
    if !_rc local ++mvars
    macro shift
    }

*count mvar categories
tokenize "`e(margins)'", parse(".")
tokenize "`1'", parse(")i( ")
local marvals = 0
while "`1'" != "" {
    local isnum = real("`1'")
    if `isnum' != . local ++marvals
    macro shift
    }

*count byvars
tokenize "`e(by)'"
local byvars = 0

while "`1'" != "" {
    local ++byvars
    macro shift
    }

*count atvar categories
if "`e(atstats2)'" != "" local atvars = 2
else if "`e(atstats1)'" != "" local atvars = 1
else local atvars = 0

*Multiple mvars or 1 mvar & 2+ byvars
if `mvars' > 1 | (`mvars' == 1 & `byvars' > 1) {
    di `exit_warning'
    exit = 103
    }
*Too many byvars or values, or 3+ at values
else if  "`e(atstats3)'" != "" | "`e(by5)'" != "" | `byvars' >= 3 {
    di `exit_warning'
    exit = 134
    }
*Too many values of mvar
else if `marvals' > 2 {
    di `exit_warning'
    exit = 134
    }
*One mvar, one atvar (not oneat), one byvar
else if `mvars' >= 1 & `byvars' == 1 & `atvars' == 2 {
    di `exit_warning'
    exit = 134
    }
*One mvar, one atvar (oneat), one byvar
else if `mvars' == 1 & `byvars' == 1 & `atvars' == 1 {
    local warn = 1
    }
*One mvar, no atvar (or one atspec), one byvar
else if `mvars' == 1 & `byvars' == 1 & `atvars' <= 1 {
    local warn = 1
    }
*Two atstats plus one byvar or one mvar 
else if `atvars' == 2 & (`byvars' >= 1 | `mvars' >= 1) {
    local warn = 1
    }
*Two atstats OR two byvars 
else if `atvars' == 2 | `byvars' == 2 {
    local warn = 1
    }
else {
    local warn = 0
    }
	
*Sampling weights
if `rmseo' != 1 {
	if `svyflag' == 1 {
		*check to see if -svysd- is necessary
		capture confirm scalar sd_byvar
		if _rc scalar sd_byvar = " "

		if "`sdupdate'" == "sdupdate" { // -sdupdate- option
			svysd `depvar', sdbyvar(`sdbyvar') force `unw'
			}
		else {
			capture confirm scalar sdisfor
			if _rc { // sdisfor is NOT a scalar
				svysd `depvar', sdbyvar(`sdbyvar') force `unw'
				}
			else {
				capture confirm scalar `sdscalar'
				if _rc { // the sdscalar is NOT a scalar
					svysd `depvar', sdbyvar(`sdbyvar') force `unw'
					}
				else if "`depvar'" != "`=sdisfor'" { // SD exists but wrong depvar
					svysd `depvar', sdbyvar(`sdbyvar') force `unw'
					}
				else if "`=sd_byvar'" != "`sdbyvar'" { // the SD exists but wrong sdvar
					svysd `depvar', sdbyvar(`sdbyvar') force `unw'
					}
				else {
					di _n as text "Using previously calculated standard deviation " ///
					"for " as result "`=sdisfor'" as text ", by " ///
					as result "`sdbyvar'" as text "..."
					}
			   }
			}
		}
	*Unweighted
	else {
		qui levelsof `sdbyvar'
		tokenize "`r(levels)'"
		scalar m_0 = `1'
		macro shift
		scalar m_1 = `1'
		macro shift
		if "`1'" != "" {
			di as error _n "The {cmd:sdbyvar} must be dichotomous to calculate " ///
							"the effect size."
			di as text "You might use {cmd:recode, generate()} to " ///
						"achieve a dichotomous variable."
			exit = 198
			}
		qui summ `depvar' if `sdbyvar' == `=m_0'
		scalar sd_m0 = `r(sd)'
		scalar n_m0 = `r(N)'
		qui summ `depvar' if `sdbyvar' == `=m_1'
		scalar sd_m1 = `r(sd)'
		scalar n_m1 = `r(N)'
		`coh' scalar pooledsd = sqrt( (sd_m0^2+sd_m1^2)/2 )
		else scalar sdstar = sqrt((((n_m0-1)*(sd_m0^2)) + ((n_m1-1)*(sd_m1^2)))/(n_m0 + n_m1 - 2))
		}
	}


*Obtaining the RMSE
if `rmseo' == 1 scalar rmse = e(rmse)
else scalar rmse = .

*If necessary, re-run regression to get the RMSE
if `rmseo' == 1 & `=rmse' == . {
	capture svyset
    local rsettings = `"`r(settings)'"' //if not svyset
	if "`rsettings'" == ", clear" {
		local newcmd `"`e(est_cmdline)'"'
		}
	else { // if svyset
		local cmdline `"`e(est_cmdline)'"'
		tokenize "`cmdline'", parse(":")
		forvalues i = 1/6 {
			if `"``i''"' == "" {
				local j = `i'-1
				local cmd = `"``j''"'
				continue, break
				}
			}
		tokenize "`rsettings'", parse("[")
		forvalues i = 1/6 {
			local itis = regexm("``i''","]")
			if `itis' == 1 {
				tokenize `"``i''"', parse("]")
				continue, break
			}
		}

		local newcmd "`cmd' [`1']"
		}
	*Re-estimate the regression in a new frame, and store the rmse
	tempname rmseframe currest
	qui estimates store `currest' 
	frame copy default `rmseframe'
	frame `rmseframe' {
		qui `newcmd'
		scalar rmse = `e(rmse)'
		di as text _n "The estimated RMSE from this regression is " ///
						as res "`=rmse'" as text " "
		}
	qui estimates restore `currest' 
	}
	
*Standard deviation name
`coh' {
	local sdscalar pooledsd
	local sd = `=pooledsd'
	local sdname "Pooled SD"
	}
`hedges' {
	local sdscalar sdstar
	local sd = `=sdstar'
	local sdname "Weighted SD*"
	}
else {
	local sd = `=rmse'
	local sdname "RMSE"
	}


*Calculate effect size

di as text _n "Calculating values of `esname'..."

if "`nowarning'" != "nowarning" & `rmseo' == 0 {
    if `warn' == 1  di `warning'
    }
else if "`nowarning'" != "nowarning" & `rmseo' == 1 {
	if `warn' == 1  di `rwarning'
	}
	
*Cohen's d
`coh' {
    forvalues b = 1/`nummargins' {
        matrix `B'[1,`b'] = el(`B',1,`b')/`=pooledsd'
 		local diff`b' = el(`B',1,`b')
 		local es`b' = el(`B',1,`b')/`=pooledsd'
       }
    matrix rownames `B' = d
    }

*Hedges's g
`hedges' {
    forvalues b = 1/`nummargins' {
        matrix `B'[1,`b'] = el(`B',1,`b')/`=sdstar'
		local diff`b' = el(`B',1,`b')
		local es`b' = el(`B',1,`b')/`=sdstar'
        }
    matrix rownames `B' = g
   }

*RMSE Delta
else {
	forvalues b = 1/`nummargins' {
		matrix `B'[1,`b'] = el(`B',1,`b')/`=rmse'
		local diff`b' = el(`B',1,`b')
		local es`b' = el(`B',1,`b')/`=rmse'
		}
	matrix rownames `B' = Delta
	}

	
*Display effect size

if `c(version)' < 17 { //Prior to version 17
	tempname EB
	matrix `EB' = e(b_vs)
	local nummargins = colsof(`EB')
	tokenize "`: colnames `EB''"

	tempname mytab
	.`mytab' = ._tab.new, col(4) lmargin(0)

	local cw = 20
	forvalues i = 1/`nummargins' {
		local len = ustrlen("``i''")
		if `len' > `cw' local cw = `len' + 2
		}
	
	if `rmseo' == 1 {
		.`mytab'.width    `cw'   |11    15     16
		.`mytab'.titlefmt  .     %9s  %10s   %16s
		.`mytab'.pad       .     0     0     0 
		.`mytab'.numfmt    . %9.2f %10.2f %16.2f
		}
	else {
		.`mytab'.width    `cw'   |11    15     10
		.`mytab'.titlefmt  .     %9s  %10s   %10s    
		.`mytab'.pad       .     0     0     0   
		.`mytab'.numfmt    . %9.2f %10.2f %10.2f 
		}
	
	.`mytab'.sep, top

	.`mytab'.titles "`depvar'"  "Contrast" "`sdname'"  "`esname'"
	.`mytab'.sep, middle

	forvalues i = 1/`nummargins' {
		.`mytab'.row    "``i''" `diff`i'' `sd' `es`i''
		}
	.`mytab'.sep, bottom
	
	}

else { //Version 17 and above
	forvalues b = 1/`nummargins' {
		matrix `RT'[1,`b'] = el(`C',1,`b')
		matrix `RT'[2,`b'] = `sd'
		matrix `RT'[3,`b'] = el(`B',1,`b')
		}
	
	quietly {
		capture collect drop _all
		collect get result = (`RT')
		
		collect remap result = unused
		collect remap rowname[b] = result[_contrast]
		collect remap rowname[se] = result[_sd]
		collect remap rowname[t] = result[_esize]

		collect label levels result ///
				_contrast "Contrast" ///
				_sd "`sdname'" ///
				_esize "`esname'" ///
				, replace
		collect style column, extraspace(2) 
		collect style cell, nformat(%6.2f) halign(right)
		}
	qui collect layout (colname) (result[_contrast _sd _esize])
	collect preview
	}
	
local sdby = abbrev("`sdbyvar'",12)

`coh' {
    return scalar pooledsd = `=pooledsd'
	return matrix d = `B', copy
    }
`hedges' {
    return scalar sdstar = `=sdstar'
	return matrix g = `B', copy
    }
else {
	return scalar RMSE = `=rmse'
	return matrix Delta = `B', copy
	}

if `rmseo' != 1 {
	return scalar   sd_`sdby'_at_`=m_1' = `=sd_m1'
	return scalar   sd_`sdby'_at_`=m_0' = `=sd_m0'
	return scalar   n_`sdby'_at_`=m_1' = `=n_m1'
	return scalar   n_`sdby'_at_`=m_0' = `=n_m0'
	return local    sdbyvar "`sdbyvar'"
	}

return local    depvar "`depvar'"
capture scalar drop rmse //leaving sd* & pooledsd in case they are needed again

end


