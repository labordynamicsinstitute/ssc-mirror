/* 
*! v1.2.1 Ian White 18may2023
	cope with zero probabilities in pc()
v1.2 was published in the Stata Journal: 
	net install st0700, from(http://www.stata-journal.com/software/sj23-1)
v1.2 Ian White 24jun2022
	change "arm" to "group"
	resubmit to SJ
v1.1.1 Ian White 20jun2022
	change to v14
v1.1 Ian White 1jun2022
	harmonise output with artbin
v1.0.1 Ian White 17feb2021
	Correct output formatting if power defaults
v1.0.0 Ian White 12feb2021
	renamed v1.0.0 at SJ submission & repo publication
v0.9.2 Ian White 5feb2021
	defaults to power(0.8) - to match power and art
	set version 13 
	better error checking for ologit option
	clearer error messages for non-increasing probabilities with cumulative option
	ologit is default
v0.9.1 Ian White 17dec2020
	rename best/worst to favourable/unfavourable
	- American spellings are allowed
	- updates to probtable
	bug fix in probtable; uses temp not permanent matrix
	new noheader option
v0.9 Ian White 3-9dec2020
	drop increase/decrease options: instead assume a RCT
	new options worst/best describing left-most level
		if specified, check it's correct
		if not specified, infer & print note
	this required moving the output after the calculation
		since inferring best/worst requires knowledge of the expected OR which comes from the ologit calculation
	and this required storing the probtable in a matrix
	help file will describe how to adapt for observational study
	rename super-superiority as substantial-superiority
	outcome type on separate line
	improved formatting of probtable
	changed ologit covariate from _stack to exptrt
	rr option works even when last level is specified
v0.8 Ian White 24-25nov2020 
	increase/decrease options - at present one of them is compulsory 
		(to auto-detect, will need to move output after calculation, to cover case where or is calculated)
	corresponding statements of AH
	check of sign(margin-or)
	svmat respects c(type) so prog works after -set type double-
	margin implies default or(1)
	help file updated for in/decrease and not stating left-most levels are preferable
v0.7.1 Ian White 10sep2020 - output notes "pre-release", posted on UCL website for Stata conf
v0.7 Ian White 12aug2020
	From Ella's testing:
		catch margin<=0
		identify super-superiority in output
	Others:
		add "pe null" to table of expected probabilities
		report average OR if treatment effect specified via pe or rr
	NB currently assuming left-most is worst - is this sustainable?
v0.6 Ian White 15jul2020
	Improve error messages following Ella's testing
	Make output like artbin's
	Default is ologit with margin()
v0.5.3 Ian White 9jun2020
	margin() - seems to work and I've tested in one setting
	"Probabilities in control arm" output specifies whether cumulative or not
	remove empty category (if prevs sum to 1 exactly)
	print only the NA result by default, and store in r(n)
v0.5.2 Ian White 5jun2020
	reports version
v0.5.1 Ian White 4jun2020
	add retvars option to return SN, SA
v0.5 Ian White 23apr2020
	rename back to artcat
v0.4 Ian White 9apr2020
	rename from artcat to artcati
v0.3 Ian White 30mar2020
	switch to an immediate command
		artcat, pc(.1 .3) or(#)|rr(#)|pe(# #)
v0.2 Ian White 27mar2020
	main syntaxes: 
		artcat, p0(var) or(#)|p1(var) n(#)|power(#)
From Ab Babiker's Sample_size.do program for IVIG trial
6-category ordinal outcome, ranging from death (cat=1, worst outcome) to out of hospital and resumed normal activities (cat = 6, best outcome)
*/

prog def artcat, rclass
version 14

local version 1.2.1
local date 18may2023
if _caller() >= 12 {
    local hidden hidden
}
return `hidden' local artcat_version "`version'"
return `hidden' local artcat_date "`date'"
if "`0'"=="which" exit

syntax, pc(numlist) [CUMulative /// control group options
	pe(numlist) or(string) rr(string) /// experimental group options
	MARgin(real 1) UNFavourable FAVourable UNFavorable FAVorable /// trial type options
	POwer(numlist max=1) n(numlist max=1) ARatio(numlist min=2 max=2) ALpha(real 0.05) ONESided  /// SS options
	WHITEhead ologit OLOGIT2(string) OLOGIT3(string) /// method options
	noPROBTable PROBFormat(string) FORMat(string) noRound noHEADer /// output options
	debug clear RETVars /// undocumented options
	]

*** PARSE
if !mi("`or'") {
	cap local or = `or' // evaluates expression
	if _rc exit198 or() must be an expression
	if `or'<=0 exit198 or must be >0
}
if !mi("`rr'") {
	cap local rr = `rr' // evaluates expression
	if _rc exit198 rr() must be an expression
	if `rr'<=0 exit198 rr must be >0
}
if (!mi("`ologit'") & !mi("`ologit2'"))| !mi("`ologit3'") exit198 duplicate ologit option not allowed
if !mi("`ologit2'") local ologit = upper("`ologit2'")
if !mi("`whitehead'") & !mi("`ologit'") exit198 please don't specify both whitehead and ologit
if !mi("`whitehead'") & mi("`or'") exit498 Whitehead method requires or
if mi("`whitehead'`ologit'") local ologit NA
if "`ologit'"=="ologit" local ologit NA
if !inlist("`ologit'","","NN","NA","AA") exit498 ologit(`ologit') not allowed

local nmethods = !mi("`pe'") + !mi("`or'") + !mi("`rr'")
if `nmethods'==0 {
	if `margin'!=1 {
		di as txt "Note: assuming anticipated odds ratio = 1"
		local or 1
	}
	else exit198 please specify one of pe, or, rr
}
if `nmethods'>1 exit198 please don't specify more than one of pe, or, rr
if mi("`power'") & mi("`n'") local power .8
if !mi("`power'") & !mi("`n'") exit198 please don't specify both power and n
if !mi("`power'") if `power'<=0 | `power'>=1 exit198 power must be between 0 and 1
if !mi("`n'") if `n'<=0 exit198 n must be greater than 0 
if `alpha'<=0 | `alpha'>=1 exit198 alpha must be between 0 and 1
if mi("`or'") & !mi("`whitehead'") exit198 Whitehead method requires or
if mi("`debug'") local qui qui

if mi("`format'") local format = cond(!mi("`power'"),cond(mi("`round'"),"%6.0f","%6.1f"),"%6.3f")
if mi("`probformat'") local probformat %5.3f // previously had %-5.1f (left-justified)

local pc2 : subinstr local pc " " ",", all
tempname pmat
mat `pmat' = (`pc2')'

if !mi("`pe'") {
	local pe2 : subinstr local pe " " ",", all
	tempname pemat
	mat `pemat' = (`pe2')'
	cap mat `pmat' = `pmat', `pemat'
	if _rc exit498 pc and pe have different lengths
}
if !mi("`debug'") di as txt "Parsing is complete"
if !mi("`debug'") mat l `pmat', title(p matrix)

if mi("`aratio'") local aratio 1 1
tokenize "`aratio'"
local A = `1'/`2'
local aratiolong `1':`2'

local sides = cond(mi("`onesided'"), 2,1)
local sidestext = cond(`sides'==2, "two-sided", "one-sided")

if `margin'!=1 { // check margin
	if `margin'<=0 exit198 margin must be expressed as an odds ratio greater than 0
}

* accommodate American spellings
if !mi("`favorable'") local favourable favourable
if !mi("`unfavorable'") local unfavourable unfavourable

if !mi("`unfavourable'") & !mi("`favourable'") exit198 please don't specify both unfavourable and favourable

* END OF PARSING

*** OUTPUT THE ARTCAT BANNER

* settings for output
local maxwidth = 61 + length("`version' `date'")
local col1 1 
local col2 41
* and specifically for probtable (start at col3)
local col3 = `col2' - 20 // for levels
local col4 = `col2' // for "pc %"
tokenize "`probformat'", parse("%.")
local probformatwidth = abs(`2')
local stringformat %-`probformatwidth's
local probtablecolwidth = max(`probformatwidth' + 2, 6)
local probtablecolwidth2 = max(`probtablecolwidth', 11)
local col5 = `col4' + `probtablecolwidth'  // for "pe %"
local col6 = `col5' + `probtablecolwidth' // for "pe null %"
forvalues i=1/6 {
	local col`i' _col(`col`i'')
}

* standard banner
if mi("`header'") {
	di as txt _n "{hi:ART} - {hi:A}NALYSIS OF {hi:R}ESOURCES FOR {hi:T}RIALS (categorical version `version' `date')"
	*di as txt "{hi:PRE-RELEASE VERSION FOR COLLEAGUES AT THE UK STATA CONFERENCE 2020 ONLY}"
	di as txt "{hline `maxwidth'}"
	di as txt "A sample size program by Ian White with input and support from"
	di as txt "Ella Marley-Zagar, Tim Morris, Max Parmar, Patrick Royston and Ab Babiker."
	di as txt "MRC Clinical Trials Unit at UCL, London WC1V 6LJ, UK." 
}
di as txt "{hline `maxwidth'}"

*** START THE CALCULATION
local za = invnormal(1-`alpha'/`sides')
if !mi("`power'") local zb = -invnormal(1-`power')

if mi("`clear'") preserve
clear
qui svmat `c(type)' `pmat', names(p)

if mi("`cumulative'") {
	gen p1sum = sum(p1)
	drop p1
	if !mi("`pe'") {
		gen p2sum = sum(p2)
		drop p2
	}
}
else {
	rename p1 p1sum 
	if !mi("`pe'") rename p2 p2sum
}
* we now have variables: p1sum and optionally p2sum

cap assert p1sum<=1
if _rc==9 exit498 probabilities in pc sum to more than 1
cap assert p2sum<=1
if _rc==9 exit498 probabilities in pe sum to more than 1

if !mi("`or'") { // OR syntax
	gen p2sum = `or'*p1sum / (1-p1sum+`or'*p1sum)
}
if !mi("`rr'") { // RR syntax
	gen p2sum = `rr'*p1sum
	qui replace p2sum = 1 if p1sum==1
	cap assert p2sum<=1
	if _rc exit498 rr option implies pe sums to more than 1
}
* we now have variables: p1sum and p2sum

if p1sum[_N]==1 { // probabilities sum to 1
	if p2sum[_N]!=1 exit498 pc sums to 1 but pe doesn't
}
else { // add row to make probabilities sum to 1
	qui set obs `=_N+1'
	forvalues r=1/2 {
		qui replace p`r'sum = 1 in l
	}
}
* we now have variables: p1sum and p2sum going up to 1

* to display pe null
gen p3sum = `margin'*p1sum / (1-p1sum+`margin'*p1sum)
	
forvalues r=1/3 {
	gen p`r' = p`r'sum - cond(_n>1,p`r'sum[_n-1],0)
}
drop p1sum p2sum p3sum
* we now have variables: level p1 p2 p3

* new to handle semi-zero counts
qui count if p1==0 & p2==0
if r(N) {
	qui drop if p1==0 & p2==0
	di as error "Warning: " r(N) " levels dropped due to zero probability in both arms"
}
local levels =_N
gen int level = _n

if mi("`probtable'") { // create matrix of anticipated probabilities
	if `margin'!=1 local p3 p3
	tempname probmatrix
	mkmat p1 p2 `p3', matrix(`probmatrix') 
}
drop p3

cap assert p1>=0
if _rc {
	if mi("`cumulative'") exit498 negative probabilities found in pc
	else exit498 decreasing cumulative probabilities found in pc
}
cap assert p2>=0
if _rc {
	if mi("`cumulative'") exit498 negative probabilities found in pe
	else exit498 decreasing cumulative probabilities found in pe
}

gen pbar=(`A'*p1+p2)/(`A'+1)

if !mi("`whitehead'") { // WHITEHEAD METHOD, REQUIRES OR()
	if `margin'!=1 exit498 the Whitehead method is not available for non-inferiority trials
	gen pbar3 = sum(pbar^3)
	local sumpbar3=pbar3[_N]
	if mi("`power'") { // calculate power
		local zb = sqrt( `n' * ((log(`or')^2)*(1-`sumpbar3')) / 12 ) - `za'
		local power_whitehead = 1-normal(-`zb')
	}
	else { // calculate n
		local n_whitehead = 3*(`A'+1)^2*((`za'+`zb')^2)/(`A'*(log(`or')^2)*(1-`sumpbar3'))
	}
}

if !mi("`ologit'") { // OLOGIT METHOD
	stack level p1 level p2, into(level p) clear
	gen exptrt = _stack==2
	drop _stack
	qui replace p = p * cond(exptrt,1,`A')/(`A'+1)
	`qui' di _n as text "Debug option: Analysis of treatment effect under alternative"
	`qui' ologit level exptrt [iw=p]
	local logor = _b[exptrt] + log(`margin')
	local SA = _se[exptrt]
	if mi("`or'") local orcalc = exp(-_b[exptrt])

	`qui' di _n as text "Debug option: Fit null model"
	tempvar offset
	gen `offset' = log(`margin') * exptrt
	`qui' ologit level [iw=p], offset(`offset')
	
	tempvar pred poff
	qui predict `pred'*
	qui gen `poff' = .
	forvalues i=1/`levels' {
		qui replace `poff' = `pred'`i' * cond(exptrt,1,`A')/(`A'+1) if level==`i'
	}
	drop `pred'* `offset'
	`qui' di _n as text "Debug option: Analysis of treatment effect under null"
	`qui' ologit level exptrt [iw=`poff']
	local SN = _se[exptrt]

	if !mi("`retvars'") {
		return scalar SN = `SN'
		return scalar SA = `SA'
		di as txt "    Null SD = " as res `SN' as txt "/sqrt(N)"
		di as txt "    Alt. SD = " as res `SA' as txt "/sqrt(N)"
	}

	foreach m1 in N A {
	foreach m2 in N A {
		if "`m1'`m2'"=="AN" continue
		if mi("`power'") { // calculate power
			local zb = (	sqrt(`n') * abs(`logor') - `za'*`S`m1'' ) / `S`m2'' 
			local power_ologit_`m1'`m2' = 1 - normal(-`zb')
		}
		else { // calculate n
			local n_ologit_`m1'`m2' = (`za'*`S`m1''+`zb'*`S`m2'')^2 / (`logor')^2
		}
	}
	}
}

*** INFER THE OUTCOME DIRECTION
if !mi("`or'") local orcalc `or'
local orcalcdisp = string(`orcalc',"%9.0g")
if mi("`favourable'`unfavourable'") { // infer outcome direction 
	if `orcalc'<`margin' local unfavourable unfavourable
	else if `orcalc'>`margin' local favourable favourable
	local direction inferred
}
local leftnature = cond(!mi("`unfavourable'"),"unfavourable","favourable")
local rightnature = cond(!mi("`unfavourable'"),"favourable","unfavourable")
local lefttext = cond(!mi("`unfavourable'"),"least favourable","most favourable")
local righttext = cond(!mi("`unfavourable'"),"most favourable","least favourable")

if `margin'==1 local trialtype "sup"
else if (`margin'<1 & !mi("`favourable'")) | (`margin'>1 & !mi("`unfavourable'")) local trialtype "ni"
else if (`margin'<1 & !mi("`unfavourable'")) | (`margin'>1 & !mi("`favourable'")) local trialtype "ss"


*** OUTPUT THE TRIAL DESIGN

if !mi("`cumulative'") local cumbrackets " (cumulative)"
local ltgt = cond(!mi("`unfavourable'"),"<",">")

* trial type
di as txt `col1' "Type of trial" _c
if "`trialtype'"=="sup" di as res `col2' "superiority"
else if "`trialtype'"=="ni" di as res `col2' "non-inferiority" 
else if "`trialtype'"=="ss" di as res `col2' "substantial-superiority"
else di as error "Program error: trialtype undefined"

* fav/unfav outcome
di as txt `col1' "Favourable/unfavourable outcome" _c
di as res `col2' "`unfavourable'`favourable'"
if "`direction'" == "inferred" di as res `col2' "{it:inferred by the program}"
* null hypothesis
if "`trialtype'"=="sup" {
	di as txt `col1' "Null hypothesis" as res `col2' "odds ratio = 1"
	di as txt `col1' "Superiority region" as res `col2' "odds ratio `ltgt' 1"
}
else if "`trialtype'"=="ni" {
	di as txt `col1' "Null hypothesis" as res `col2' "odds ratio = " `probformat' `margin'
	di as txt `col1' "Non-inferiority region" as res `col2' "odds ratio `ltgt' " `probformat' `margin'
}
else if "`trialtype'"=="ss" {
	di as txt `col1' "Null hypothesis" as res `col2' "odds ratio = " `probformat' `margin'
	di as txt `col1' "Substantial-superiority region" as res `col2' "odds ratio `ltgt' " `probformat' `margin'
}


* other settings
di as txt `col1' "Allocation ratio C:E" as res `col2' "`aratiolong'"
di as txt `col1' "Anticipated probabilities, control" as res `col2' "`pc'`cumbrackets'"
di as txt `col1' "                      experimental" _c
if !mi("`or'") di as res `col2' "given by odds ratio = " `probformat' `or'
else if !mi("`rr'") di as res `col2' "given by risk ratio = " `probformat' `rr'
else di as res `col2' `probformat' "`pe' `cumbrackets'"

*** check and output the outcome direction
if mi("`or'") di as txt "Anticipated average odds ratio" `col2' as res `probformat' `orcalcdisp'
if `orcalc'==`margin' exit498 or = margin makes a trial impossible
*if "`direction'"=="inferred" {
*	di as txt _n "{it:The program has inferred that the left-most outcome level is the `lefttext'.}"
*	di as txt "{it:You can avoid seeing this message in future by specifying the {cmd:`leftnature'} option.}"
*}
if "`direction'"!="inferred" {
	if !mi("`favourable'") & `orcalc'<`margin' exit498 or (`orcalcdisp') < margin (`margin') is incompatible with favourable option
	if !mi("`unfavourable'") & `orcalc'>`margin' exit498 or (`orcalcdisp') > margin (`margin') is incompatible with unfavourable option
}

if mi("`probtable'") {
	di _n as text "Table of anticipated probabilities" _c
	di as txt `col4' `stringformat' "C" `col5' `stringformat' "E" _c
	if `margin'!=1 di `col6' `stringformat' "E null" _c
	di
	forvalues level=1/`levels' {
		local levlab `level'
		if `level'==1 local levlab `levlab' `lefttext'
		else if `level'==`levels' local levlab `levlab' `righttext'
		di as txt `col3' "`levlab'" _c
		di as res `col4' `probformat' `probmatrix'[`level',1] _c
		di as res `col5' `probformat' `probmatrix'[`level',2] _c
		if `margin'!=1 di as res `col6' `probformat' `probmatrix'[`level',3] _c
		di
	}
}

di
di as txt `col1' "Alpha" as res `col2' `probformat' `alpha' " (`sidestext')"
if !mi("`power'") di as txt `col1' "Power (designed)" as res `col2' `probformat' `power'
if !mi("`n'")     di as txt `col1' "Total sample size (designed)" as res `col2' `n'
di as txt `col1' "Method" _c
if !mi("`whitehead'") di as res `col2' "Whitehead"
else di as res `col2' "ologit (variance `ologit')"

// OUTPUT RESULT
di
if mi("`n'") {
	foreach method in whitehead ologit_NN ologit_NA ologit_AA {
		if !mi("`n_`method''") {
			local n_`method'_E = `n_`method'' / (1+`A')
			local n_`method'_C = `n_`method'_E' * `A'
			if mi("`round'") {
				local n_`method'_C = ceil(`n_`method'_C')
				local n_`method'_E = ceil(`n_`method'_E')
				local n_`method' = `n_`method'_C' + `n_`method'_E'
			}
*			di as txt `col1' "Method `method'" as res `col2' `format' `n_`method''
			return scalar n_`method' = `n_`method''
		}
	}
	if "`whitehead'"=="whitehead" local methodend whitehead
	else local methodend ologit_`ologit'
	local N = `n_`methodend''
	local N_C = `n_`methodend'_C'
	local N_E = `n_`methodend'_E'
	return scalar n = `N'
	return scalar nC = `N_C'
	return scalar nE = `N_E'
	di as txt "Total sample size (calculated)" as res `col2' string(`N',"`format'")
	di as txt "Sample size per group (calculated)" as res `col2' string(`N_C',"`format'") " " string(`N_E',"`format'") 
}
if mi("`power'") {
	foreach method in whitehead ologit_NN ologit_NA ologit_AA {
		if !mi("`power_`method''") {
*			di as txt `col1' "Method `method'" as res `col2' `format' `power_`method''
			return scalar power_`method' = `power_`method''
		}
	}
	if "`whitehead'"=="whitehead" local POWER=`power_whitehead'
	else local POWER=`power_ologit_`ologit''
	return scalar power = `POWER'
	di as txt "Power (calculated)" as res `col2' string(`POWER',"`format'")
}

di as txt "{hline `maxwidth'}"

if !mi("`clear'") {
	cap rename `poff' pnull
	di as txt "Data loaded into memory."
}
end

prog def exit198
di as error `"artcat: `0'"'
exit 198
end

prog def exit498
di as error `"artcat: `0'"'
exit 498
end

prog def readp
syntax anything, matrix(name)
cap mat `matrix' = (`anything')'
if _rc {
	numlist "`anything'" 
	foreach num of numlist `anything' {
		if !mi("`commalist'") local commalist `commalist',
		local commalist `commalist' `num'
	}
	mat `matrix' = (`commalist')'
}
end

