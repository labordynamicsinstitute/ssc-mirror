*****************************************************
set more off
*****************************************************

* Programmer: Jared A. Greathouse

* Institution:    Georgia State University

* Contact: 		j.greathouse200@gmail.com

* Created on : Jan 2, 2022

* Last Edited: Jan 12/2022

* Contents: 1. Purpose

*  2. Program Versions

*****************************************************

* 1. Purpose

/* */


* 2. Program

cap prog drop scul // Drops previous iterations of the program

*! SCUL v1.0.0, Jared Greathouse, 7/23/22
prog define scul, rclass
version 16 // Stata MP- Lowest version it'll work on is 11

	
/**********************************************************
	* Installation*
Installs relevant commands needed.
**********************************************************/
/*
	loc package st0594 gr0034 dm0042_3 
	
	foreach x of loc package { // begin foreach

		qui: cap which cvlasso
	
			if _rc { // if command is missing

			qui: net inst `x'.pkg, replace
		
			} // ends if
	} // ends foreach
	
	loc comm gtools labvars coefplot
	
	foreach x of loc comm { // begin foreach

		qui: cap which `x'
	
			if _rc { // if command is missing

			qui: ssc inst `x', replace
		
			} // ends if
	} // ends foreach

	cap which rmse
	
	if _rc {
	
	qui net inst rmse.pkg, replace
	}
	
	cap set scheme white_hue
	
	if _rc {
		
		qui ssc inst schemepack, replace
	} */	

/**********************************************************

	
	
	* Preliminaries*


If the data aren't a balanced panel, something about the
user's dataset ain't right.
**********************************************************/


cap qui xtset
if _rc {
	
	disp as err "The data are not xtset"
	exit 498
}

gl time: disp "`r(timevar)'"

gl panel: disp "`r(panelvar)'"

gl time_format: di r(tsfmt)

//lab var $panel "group(regionname)"

marksample touse

_xtstrbal $panel $time `touse'

	* Confirm -cvlasso- program is installed
	capture cvlasso
	if _rc == 199 {
		di as err "-lassopack- package and cvlasso must be installed. Type -ssc install cvlasso, replace all-"
		exit 198
	}
			
	* Confirm -distinct- program is installed
	capture distinct
	if _rc == 199 {
		di as err "-distinct- package must be installed. Type -ssc install distinct-"
		exit 198
	}
	
	* Confirm -gtools- program is installed
	capture greshape
	if _rc == 199 {
		di as err "-greshape- package must be installed. Type -ssc install gtools-"
		exit 198
	}

	* Confirm -tabstatmat- program is installed
	capture tabstatmat
	if _rc == 199 {
		di as err "-tabstatmat- package must be installed. Type -ssc install tabstatmat-"
		exit 198
	}

	syntax anything [if], ///
		TReated(varname) /// We need a treatment variable as 0 1
		[ahead(numlist min=1 max=1 >=1 int)] /// Number of forecasting periods.
		[PLAcebos] /// Conducts iterative assignment of the intervention at time t
		[LAMBda(string)] /// specifies the lambda we're using
		[COVs(varlist)] ///
		[cv(string)] [scheme(string)] ///
		[sqerr(numlist min=0 max=1 >=0)] ///
		[before(numlist min=1 max=1 int)] ///
		[after(numlist min=1 max=1 int)] ///
		[rellab(numlist)] /// relabels event study axis
		[obscol(string)] ///
		[cfcol(string)] [conf(string)] ///
		[legpos(numlist min=1 max=1 >=1)] ///
		[TRANSform(string)] ///
		[avgs(numlist min=1 max=1 int)] ///
		[donadj(string)] ///
		[q(numlist min=0 max=1)] ///
		[plat] [times(numlist)]

tempvar touse
mark `touse' `if' `in'

if (length("`if'")+length("`in'")>0) {
    
    qui keep if `touse'
}

		
gettoken depvar anything: anything

unab depvar: `depvar'

local y_lab: variable lab `depvar'

loc outlab "`y_lab'" // Grabs the label of our outcome variable

if "`q'"=="" {
	
	loc q =1
}

if "`lambda'"=="" {
	
	loc lambda lopt
}

if "`ahead'"=="" {
	
	loc ahead = 1
}

local tr_lab: variable lab `treated'

		
/**********************************************************

	
	
	* Pre-Processing*


Assuming the user doesn't want placebo tests and hasn't specified
the multiple option, I presume they want the single-intervention
design. We break the command into two stages: data validation
and estimation.
**********************************************************/

qui insp $panel if `treated'==1

loc totaltreat = r(N_unique)

qui su $panel if `treated' ==1, mean

loc realunit = r(mean)

if "`placebos'" != "placebos" & "`plat'" == ""  & `totaltreat'==1 { // thus......

preserve // Keep the primary long dataset the exact same

numcheck, unit($panel) ///
	time($time) ///
	transform(`transform') ///
	depvar(`depvar') /// Routine 1
	q(`q') treated(`treated')


// Routine 2

treatprocess, time($time) ///
	unit($panel) ///
	covs(`covs') treated(`treated')

data_org, unit($panel) ///
	time($time) ///
	depvar(`depvar') ///
	covs(`covs') treated(`treated')

loc trdate = e(interdate)
/**********************************************************

	
	
	* Estimation*


This is where we do estimaiton if the dataset above passes.
**********************************************************/


est_lasso, time($time) h(`ahead') interdate(`trdate') ///
	lambda(`lambda') cv(`cv') scheme(`scheme') ///
	obscol(`obscol') cfcol(`cfcol') conf(`conf') ///
	legpos(`legpos') transform(`transform') intname(`tr_lab') ///
	rellab(`rellab') q(`q') outlab(`outlab')
	
restore // brings back the long panel dataset

if "`covs'" == "" {

loc weight_cols: colsof e(beta)

// Synthetic Weights

mat W = e(beta)[1, 1..`weight_cols'-1]'

// everything but the constant

loc q: rowfullnames W
// getting the rownames

local newrow : subinstr loc q " " ",", all
// put commas between these elements

foreach v of var `depvar' {

local newrow : subinstr local newrow "`v'" "", all

qui levelsof $panel if inlist($panel,`newrow'), l(labs2) sep(",")

decode $panel, g(id2)

qui levelsof id2 if inlist($panel,`labs2'), l(labs)

mat rownames W = `labs'
mat colnames W = Weights
}
mata : st_matrix("r(W)", st_matrix("W"))
mata : st_matrixrowstripe("r(W)", st_matrixrowstripe("W"))
mata : st_matrixcolstripe("r(W)", st_matrixcolstripe("W"))
collect clear
collect get r(W)
collect style cell colname, nformat(%4.3f)

collect layout (rowname)(colname)
return mat Weights = W

return loc donors `labs2'

drop id2

/*
collect get r(W)
collect layout (rowname)(colname)
*/
}
}
if "`placebos'" == "placebos" & "`plat'" == "" & `totaltreat'==1 { // However, if we DO want placebos...

if mi("`sqerr'") {
	
	di in red "You must specify a threshold using the sqerr option."
	exit 498
}


qui {	
local files : dir "`c(pwd)'" files "*scul_placebos_*"
qui foreach l of loc files {
	erase "`l'" // Erases previous placebo files. Maybe make into tempfiles?
}
}
di "Running placebos..."

di "This usually takes a long time..."

/**********************************************************

	
	
	* Placebo Comments*

Here are my placebo comments.

We basically loop through all of the units. I presumse the
user has already narrowed down their panel data to an acceptable
level.
**********************************************************/
qui levelsof $panel, l(placebo_units) // For each unit...
di as txt "Estimating... This could take a while..."
foreach x of loc placebo_units {
	
qui su $time if `treated' ==1

loc trdate = r(min)


preserve

loc clab: label ($panel) `x'
loc currentlab: disp "`clab'"

		
qui numcheck, unit($panel) time($time) 	transform(`transform') ///
	depvar(`depvar') /// Routine 1
	treated(`treated')

qui placebos_process, treatunit(`x') /// 
	time($time) ///
	unit($panel) ///
	interdate(`trdate') //

qui data_org_placebos, unit($panel) ///
	time($time) ///
	depvar(`depvar') ///
	covs(`covs')
	

*We repreat the above checking. It doesn't change at all



/**********************************************************

	
	
	* Estimation*


Unlike the single group treated option, I don't make gap
plots for every single unit. I leave that to the end/
**********************************************************/


qui est_placebos, time($time) h(`ahead') ///
interdate(`trdate') treatunit(`x') ///
lambda(`lambda') ///
cv(`cv') scheme(`scheme') transform(`transform') q(`q')

noi di "`currentlab' is done..." _continue
restore // again, bring back the long data
}	

local files : dir "`c(pwd)'" files "*scul_placebos_*" // gather the placebos...

loc first_file: word 1 of `files' // Get the first one

u "`first_file'", clear // bring it in

loc n: word count `files'


forv i = 1/`n' {

loc a: word `i' of `files'


cap joinby $time using "`a'", unmatched(none) // Join them side by side to reshape them.

}

keep diff* $time cf* relative // We onlt need the difference from the treated and untreated, the counterfactual, and time vars

qui greshape long diff_ cf_, i($time) j($panel) // using the good reshape!

/*

qui { // Cohen's d
g real = cf+diff


qui su real, mean

bys $panel: g std_dev = sqrt((real -`r(mean)')^2) if relative < 0

bys $panel relative: g frac = abs((real - cf)/std_dev)

g cohen = .

cls
qui levelsof $panel, l(units)
foreach x of loc units {
qui su frac if relative < 0 & $panel ==`x', mean

qui replace cohen = `r(mean)' if relative < 0 & $panel ==`x'
}

levelsof $panel if cohen > 0.25 & relative < 0, l(drops) 


foreach l of loc drops {
	
qui	drop if $panel == `l'
}
}
*/

sort $panel relative


g byte treated = $panel == `realunit'
rename diff_ diff

qui {
foreach x in mean sd {
egen diff_`x' = `x'(diff) if treated == 0, by($time)
}
su relative if treated ==1
g upper = diff_mean+(1.96*(diff_sd/sqrt(`r(N)')))
g lower = diff_mean-(1.96*(diff_sd/sqrt(`r(N)')))
}

sort $panel $time

loc x : word count `intname'

if `x'== 0 {
	
	loc intname Event
}


lab var relative "Relative Time to `intname'"
/*
00
qui separate diff_mean, by(treated) veryshortlabel
cap drop rmse 
*/

tempvar real err2 err3

qui g `real' = cf_ + diff

g premse = .

g `err2' = diff^2 if relative < 0

qui levelsof $panel, l(unit)

foreach x of loc unit {

qui mean `err2' if relative < 0 & $panel ==`x'

replace premse = sqrt(e(b)[1,1]) if $panel ==`x'


}

g postmse = .

g `err3' = diff^2 if relative >= 0

qui levelsof $panel, l(unit)

qui foreach x of loc unit {

mean `err3' if relative >= 0 & $panel ==`x'

replace postmse = sqrt(e(b)[1,1]) if $panel ==`x'


}


*Grey
loc cb_col red

loc plavg black

loc placebos gs10


qui su diff if relative >= 0 & treated==1

loc ATT: disp %6.4g `r(mean)'

qui su premse if treated == 1, mean

loc drops_error = `sqerr' * r(mean)

qui levelsof $panel if premse > `drops_error' & relative < 0, l(dropids)

foreach x of loc dropids {

qui drop if $panel ==`x'
}
tempvar N
qbys $time: gen `N' = _N
g ratio = postmse/premse
	
	
qui gsort $time -ratio
qbys $time: gen rmspe_rank = _n  if relative >= 0
qui g pval = rmspe_rank/`N' if relative >= 0

sort $panel $time
/*
qui su rel, mean

loc relmax = r(max)

loc rel_graph_min = 0-`relmax'
*/


if "`transform'" == "norm" {
	
	loc ytitle "Normalized Outcome Gap (%)"
}

else if "`transform'" != "norm" {
	
	loc ytitle Gap
}

if mi("`obscol'") {
	
	loc obscol black
}


tw ///
	line diff relative ///
	if !treated,           ///
    connect(L) xlab(`rellab')                    /// <-- the key option
    lcolor("`placebos'%50") lwidth(vthin) ///
     ||                                          ///
	line diff relative ///
	if treated,             ///
    lcol(`obscol') lwidth(thick) legend(pos(7) col(1) ring(0) size(medlarge) ///
	lab(1 "{bf:Y}{subscript:c}") ///
	lab(2 "{bf:Y}{subscript:t}") ///
	lab(3 "{bf:Y}{subscript:c}{superscript:?} Average") ///
	lab(4 "95% CI") ///
	lab(5 "") region(fcol(none)))         ///        
    yti(`ytitle') ///
    || ///
	line diff_mean relative, ///
	c(L ..) lcol("`plavg'") lpat(---) lwidth(medium) || ///
	rarea upper lower relative, lwidth(vvthin) color("`cb_col'%15") caption("ATT: `ATT'", pos(6)) ///
	scheme(`scheme') ///
	xli(0, lcol(gs8) lpat(dash)) ///
	xti("t-`=ustrunescape("\u2113")' until `intname'") name(placeboestimates, replace) ///
	ti("In-Space Placebo Studies")
	
preserve


gcollapse (firstnm) premse postmse ratio rmspe_rank pval, by($panel)
sort rmspe_rank
decode $panel, g(panel)

mkmat premse postmse ratio rmspe_rank pval, rownames(panel) mat(errmat)

matname errmat "Pre-MSE" "Post-MSE" "Ratio" "Rank" "pvalue", columns(1..5) explicit

restore
return mat errs = errmat

sa placebos_scul, replace	
	
if "`avgs'" !="" {

tempfile core core2 core3

preserve


keep if treated

sa "`core'"

restore

qui distinct $panel if !treated

loc controls = r(ndistinct)


*** Placebo Averages

preserve
qui levelsof $panel if treated ==1, local(trunits)
		
qui drop if treated

foreach x of loc dropids {

qui drop if $panel ==`x'
}


qui save "`core2'", replace



set seed 12345
		forval n = 1/`avgs' {
			
			* Randomly select a placebo treated unit from each actually treated unit
			qui u "`core2'", clear
			qui g p = runiform() if !mi(relative)
			qui sort treated p
			qbys treated: g px = (_n == 1)
			qbys $panel treated: egen keepdonor = max(px)
			qui keep if keepdonor == 1
			qui sort $panel $time

			gcollapse (mean) diff*, by(relative)
			qui compress
			qui gen _placeboID = `n'
			if `n' > 1 {
				qui append using "`core3'"
			}
			qui save "`core3'", replace
		}
		
qui append using "`core'"

twoway line diff relative if mi(treated),           ///
    connect(L) xlab(`rellab') ///
    lcolor(gs12%30)                        ///
    lwidth(thin)                                 ///
     ||                                          ///
       line diff relative if treated==1, connect(L)            ///
    lcol(`obscol') lwidth(medthick) lp(solid) legend(off)          ///         
    xli(-1, lcol(black) lwidth(medium) lpat(--)) ///
    yti(Gap, margin(vsmall)) caption("`avgs' permutations, `controls' donors.") ///
    name(draws, replace)
    
    sa permutations_scul, replace
    
    
/*
replace treated = 0 if treated==.

gcollapse (mean) diff if rel >= 0, by(_placeboID treated)


qui su diff if treated

loc x = r(mean)


histogram diff, xli(`x') xlab(-.15(.05)0.15) xti(ATT)

*/
  restore 
}


local files : dir "`c(pwd)'" files "*scul_placebos_*" // gather the placebos...

loc n: word count `files'


forv i = 1/`n' {

loc a: word `i' of `files'


erase "`a'"

}

}

if "`plat'" == "plat" & `totaltreat'==1 {

loc placount: word count `times'

cap as `placount' != 0
if _rc {
	
	di in red "You must specify time-to-event palcebos."
	exit 498
}

	
local files : dir "`c(pwd)'" files "*sculitp*"
qui foreach l of loc files {
	erase "`l'" // Erases previous placebo files. Maybe make into tempfiles?
}

numcheck_itp, unit($panel) ///
	time($time) ///
	transform(`transform') ///
	depvar(`depvar') /// Routine 1
	q(`q') treated(`treated')

loc mastertrdate = e(interdate)
foreach placebo of num 0 `times' {
loc npp = `mastertrdate'-`placebo'
if `placebo' > 0 {
noi di "`gap'`npp' (`placebo' pre-periods)" _continue
loc gap ...
}


preserve
treatprocess_itp, time($time) ///
	unit($panel) ///
	covs(`covs') treated(`treated') times(`placebo')
	
loc trdate = e(interdate)
	
data_org_itp, unit($panel) ///
	time($time) ///
	depvar(`depvar') ///
	covs(`covs') ///
	treated(`treated') ///
	times(`placebo')

est_placebos_itp, time($time) ///
	h(`ahead') ///
	interdate(`trdate') ///
	lambda(`lambda') ///
	cv(`cv') ///
	transform(`transform') ///
	q(`q') ///
	treatunit(`realunit') ///
	times(`placebo')

restore
	}

local files : dir "`c(pwd)'" files "*sculitp*" // gather the placebos...

loc first_file: word 1 of `files' // Get the first one

u "`first_file'", clear // bring it in

loc n: word count `files'


forv i = 1/`n' {

loc a: word `i' of `files'


cap joinby $time using "`a'", unmatched(none) // Join them side by side to reshape them.

}
qui tsset $time

qui su $time if relative_0==0

loc interdate = r(mean)

rename cf_itp_0 cf_0

order *cf*, last seq

twoway (tsline `depvar'*, lcolor(`obscol') lwidth(thick)) ///
(tsline cf_0, lcolor(`cfcol') lpat(dash) lwidth(medthick)) ///
 (tsline *itp*, lcolor(gs12%30 ..) lwidth(thin)), ///
 legend(pos(`legpos') ring(0) ///
 order(1 "Observed $treat_lab" 2 "Original Counterfactual" 3 "Backdates") ///
 fcolor(white) region(fcolor(none))) ///
 tline(`interdate', lcol("52 44 44") lpat(dash) lwidth(thin)) ///
 yti("`outlab'") ti("In-Time Placebos")  name(backdates, replace)
 
 twoway (tsline `depvar'*, lcolor(`obscol') lwidth(thick)) ///
(tsline cf_0, lcolor(`cfcol') lpat(dash) lwidth(medthick)) ///
 (tsline *itp*, lcolor(gs12%30 ..) lwidth(thin)) if relative_0 < 1, ///
 legend(pos(`legpos') ring(0) ///
 order(1 "Observed $treat_lab" 2 "Original Counterfactual" 3 "Backdates") ///
 fcolor(white) region(fcolor(none))) ///
 tline(`interdate', lcol("52 44 44") lpat(dash) lwidth(thin)) ///
 yti("`outlab'") ti("In-Time Placebos")  name(backdatespre, replace)
 
 
tempname e123 cont treat loss means B

mkmat `depvar'* if relative_0 < 0, mat(`treat')


mata A=J(0,1,.)

foreach x of var *cf* {

mkmat `x' if relative_0 < 0, mat(`cont')

mat `loss' = (`treat' - `cont')' * (`treat' - `cont')

mat `loss' = `loss''/ rowsof(`treat')

mata: X = round(sqrt(st_matrix("`loss'")),.000000001)

mata: st_matrix("`loss'", X)

loc err =`loss'[1,1]

 matrix `e123'=`err'

 mata: A=A\st_matrix("`e123'")
}

mata: st_matrix("`B'",A)

mata C="RMSE"
mata C=C,J(1,1," ")
mata st_matrix("`B'",A)
mata st_matrixcolstripe("`B'",C)

local rn
qui foreach i of num 0 `times' { //
    local rn `rn' `:display `i''
}
mat rownames `B' = `rn'

order *diff*, last seq

qui mean diff* if relative_0 >= 0

mat `means' = e(b)'

mat colnames `means' = ATTs

matrix itplacebos = `B' , `means'

qui sa timeplacebos, replace
local files : dir "`c(pwd)'" files "*sculitp*" // gather the placebos...

loc first_file: word 1 of `files' // Get the first one

u "`first_file'", clear // bring it in

loc n: word count `files'


forv i = 1/`n' {

loc a: word `i' of `files'


erase "`a'"

}

macro drop treat_lab
}

if `totaltreat' > 1 {
	
if "`treated'"=="" {
	
	di in red "You must specify a treatment variable."
	exit 498
}

if "`donadj'"=="" {
	
	di in red "You must specify a way to adjust the donor pool."
	exit 498
}	

cap as !mi("`before'") & !mi("`after'")

if _rc {
	
	di in red "You must specify a before and after period to average effects over."
	exit 498
}

tempvar pre post

bys $panel: egen `pre'= total(!`treated')
bys $panel: egen `post'= total(`treated')

drop if (`pre'< `after' | `post'< `before') & `post'!=0


drop `pre' `post'

/**********************************************************

	
	
	* Multi-Intervention*


Assuming the user has multiple interventions,
then we handle it in this section.
**********************************************************/
levelsof $panel if `treated' == 1, l(mun)


qui {	
local files : dir "`c(pwd)'" files "*mscul_*"
foreach l of loc files {
	erase "`l'" // Erases previous placebo files. Maybe make into tempfiles?
}
}

foreach x of loc mun {
	
preserve

qui su $time if `treated' ==1 & $panel == `x'

loc treatdate = r(min)


numcheck_multi, unit($panel) time($time) depvar(`depvar') treatunit(`x') treatdate(`treatdate') treated(`treated') transform(`transform') // Routine 1



treatprocess_multi, unit($panel) time($time) treated(`treated') treatunit(`x') donadj(`donadj')


data_org_multi, unit($panel) ///
	time($time) ///
	depvar(`depvar') ///
	covs(`covs') ///
	treatunit(`x')
	
est_lasso_multi, time($time) h(`ahead') lambda(`lambda') treatunit(`x') cv(`cv') scheme(`scheme') ///
q(`q') transform(`transform')

restore
}


local files : dir "`c(pwd)'" files "*mscul*" // gather the placebos...

loc first_file: word 1 of `files' // Get the first one

u "`first_file'", clear // bring it in

loc n: word count `files'


forv i = 1/`n' {

loc a: word `i' of `files'


 joinby $time using "`a'", unmatched(none) // Join them side by side to reshape them.

}

keep *diff* $time *bound* cf* *relative* // We onlt need the difference from the treated and untreated, the counterfactual, and time vars

qui greshape long diff_ lowbound_ upbound_  cf_ relative_, i($time) j($panel) // using the good reshape!

loc x : word count `intname'

if `x'== 0 {
	
	loc intname Event
}

lab var relative_ "Relative Time to `intname'"

qui {
xtset $panel $time
sa atts_scul, replace
}
clear matrix

keep if inrange(relative_,-`before',`after')


qui distinct $panel

if r(ndistinct) < 10 {

loc last =r(ndistinct)+1

if "`transform'" == "norm" {
	
	loc ytitle "Normalized Outcome Gap (%)"
}

else if "`transform'" != "norm" {
	
	loc ytitle Pointwise Impact
}

preserve
decode $panel, gen(id2)
qui tabstat diff_ lowbound_ upbound_ if relative_ >= 0, stat(mean)  by(id2) save


qui tabstatmat Z

svmat Z

qui levelsof id2, l(colnames)


keep Z*

keep if !mi(Z1)


mkmat Z*, mat(Z)
mat Z= Z'

mat rownames Z = ATT LB UB

mat colnames Z = `colnames' Overall


loc ATT: di %6.4g Z[1,`last']

coefplot matrix(Z), ///
	ci((Z[2] Z[3])) ///
	caption("ATT = `ATT' across all treated units.") ///
	ti("SCUL, Staggered Implementation") xli(0, lcolor("`cfcol'") lwidth(thin)) ///
	scheme(`scheme') ysize(4) xsize(4.5) name(postplot, replace)
restore

preserve

gcollapse (mean) diff_ lowbound_ upbound_, by(relative_)

qui su diff_ if relative_ >= 0, mean

loc ATT: disp %6.4g `r(mean)'

if "`donadj'" == "et" {
	
loc adjtype Donors includes units which were eventually treated.
}
else if "`donadj'" == "nt" {
	
loc adjtype Donors include only never-treated units.

	
}



**# Multi-Intervention Graph

tw (line diff_ relative_, xlab(`rellab') mcolor("`obscol'") msize(medium) ///
	lcolor("`obscol'") lwidth(thick)) || ///
	(line upbound_ relative_, lcolor("`cfcol'")) || ///
	(line lowbound_ relative_, lcolor("`cfcol'")), ///
		legend(order(1 "SCUL" 2 "Confidence Interval") pos(7) ring(0) region(fcolor(none))) ///
		caption("ATT = `ATT'. `adjtype'", pos(6)) ///
		xti("t-`=ustrunescape("\u2113")' until `intname'") name(eventplot, replace) scheme(`scheme') ///
		yti("`ytitle'") yli(0, lpat(solid) lwidth(thin)) ///
		xli(-1, lpat(dash) lcolor("`cfcol'") lwidth(thin)) ti("Event-Study") ///
		xsize(7) ysize(4)
restore
}

else if r(ndistinct) > 10 {
	
su diff if relative_ > = 0
	
loc ATT: di %6.4g r(mean)
preserve

gcollapse (mean) diff_ lowbound_ upbound_, by(relative_)

qui su diff_ if relative_ >= 0, mean

loc ATT: disp %6.4g `r(mean)' 

twoway (connected diff_ relative_, xlab(`rellab') mcolor("`obscol'") msize(medium) ///
	msymbol(circle) lcolor("`cfcol'") lwidth(thick)) || ///
	(connected upbound_ relative_, mcolor("`cfcol'") lcolor("`cfcol'")) || ///
	(connected lowbound_ relative_, mcolor("`cfcol'")  lcolor("`cfcol'")), ///
		legend(order(1 "SCUL" 2 "Confidence Interval") pos(7) ring(0) region(fcolor(none))) ///
		caption("ATT = `ATT'. `adjtype'", pos(6)) ///
		xti("t-`=ustrunescape("\u2113")' until `intname'") name(eventplot, replace) scheme(`scheme') ///
		yti("`ytitle'") yli(0, lpat(solid) lwidth(thin)) ///
		xli(-1, lpat(dash) lcolor("`cfcol'") lwidth(thin)) ti("Event-Study") xsize(7) ysize(4)
restore

}

qui {	
local files : dir "`c(pwd)'" files "*mscul_*"
foreach l of loc files {
	erase "`l'" // Erases previous placebo files. Maybe make into tempfiles?
}
}

mat Z= Z'
return mat ATTs = Z

}


/*
Future version
if `totaltreat'>1  & "`placebos'"=="placebos"{

	
if mi("`treated'") {
	
	di in red "You must specify a treatment variable."
	exit 498
}

if mi("`donadj'") {
	
	di in red "You must specify a way to adjust the donor pool."
	exit 498
}	

cap as !mi("`before'") & !mi("`after'")

if _rc {
	
	di in red "You must specify a before and after period to average effects over."
	exit 498
}

tempvar pre post

bys $panel: egen `pre'= total(!`treated')
bys $panel: egen `post'= total(`treated')

qui drop if (`pre'< `after' | `post'< `before') & `post'!=0


qui drop `pre' `post'

qui levelsof $panel if `treated' == 1, l(treateds)

numcheck_multi_placebos, unit($panel) time($time) depvar(`depvar') treated(`treated')
	
qui levelsof $panel, loc(units)

foreach x of loc treateds {
	
qui su $time if `treated' ==1 & $panel == `x', mean

loc int_time = r(min)

qui levelsof id, loc(units)
foreach q of loc units {

preserve
**# MultPlacebos
 placebos_treat_multi , time($time) ///
unit($panel) ///
treated(`treated') ///
covs(`covs') ///
treatunit(`x') ///
donadj(`donadj') ///
tredate(`int_time') placebounit(`q')

placebos_org_multi, unit($panel) ///
	time($time) ///
	depvar(`depvar') ///
	covs(`covs') ///
	plaunit(`q')

restore
}
}
}

0
*/

end


/**********************************************************

	*Section 1: Data Setup
	
**********************************************************/

cap prog drop numcheck // Subroutine 1.1
prog numcheck
// Original Data checking
syntax, ///
	unit(varname) ///
	time(varname) ///
	depvar(varname) ///
	[transform(string)] ///
	[q(numlist min=0 max=1)] ///
	treated(varname)
	
		
/*#########################################################

	* Section 1.1: Extract panel vars

	Before SCM can be done, we need panel data.
	
	
	Along with the R package, I'm checking that
	our main vairables of interest, that is,
	our panel variables and outcomes are all:
	
	a) Numeric
	b) Non-missing and
	c) Non-Constant
	
*########################################################*/

cap as `q' ==1

if !_rc {
	
	loc optimizer "LASSO"
}

cap as `q' ==0 

if !_rc {
	
	loc optimizer "Ridge"
}

cap as `q' !inlist(`q',0,1)

if !_rc {
	
	loc optimizer "Elastic-Net"
}

cap if mi("`q'")  {
	
	loc optimizer "LASSO"
}

di as txt "{hline}"
di as txt "Algorithm: Synthetic `optimizer', Single Unit Treated"
di as txt "{hline}"
di as txt "First Step: Data Setup"
di as txt "{hline}"
di as txt "Checking that setup variables make sense."

tempvar obs_count
qbys `unit' (`time'): g `obs_count' = _N
qui su `obs_count'

qui drop if `obs_count' < `r(max)'

/*The panel should be balanced, but in case it isn't somehow, we drop any variable
without the maximum number of observations (unbalanced) */


	foreach v of var `unit' `time' `depvar' {
	cap {	
		conf numeric v `v', ex // Numeric?
		
		as !mi(`v') // Not missing?
		
		qui: su `v'
		
		as r(sd) ~= 0 // Does the unit ID change?
	}
	}
	if !_rc {
		
		
		di as res "Setup successful!! All variables `unit' (ID), `time' (Time) and `depvar' (Outcome) pass."
		di as txt ""
		di as res "All are numeric, not missing and non-constant."
	}
	
	else if _rc {
		
		
		
		disp as err "All variables `unit' (ID), `time' (Time) and `depvar' must be numeric, not missing and non-constant."
		exit 498
	}
	
	qui su $time if `treated'==1
	
	if "`transform'" == "norm" {
		
	di "You've asked me to normalize `depvar'."
	
	tempvar _XnormVar _xXnormVar
			
	loc pretreatm1 = r(min)-1
	
	qui g `_XnormVar' = `depvar' if `time' == `pretreatm1'
	
	
	qbys `unit': egen `_xXnormVar' = max(`_XnormVar')
	
	qui replace `depvar' = 1*`depvar'/`_xXnormVar'
	}
	
	
end

cap prog drop treatprocess // Subroutine 1.2
prog treatprocess
        
syntax, time(varname) unit(varname) [covs(varlist)] treated(varname)

/*#########################################################

	* Section 1.2: Check Treatment Variable

	Before SCM can be done, we need a treatment variable.
	
	
	The treatment enters at a given time and never leaves.
*########################################################*/

di as txt "{hline}"
di as txt "Inspecting our treatment variable..."
di as txt "{hline}"

qui su `time' if `treated' ==1

loc last_date = r(max)
loc interdate = r(min)

qui su `unit' if `treated'==1

loc treated_unit = r(min)

qui insp `time' if `treated' ~= 1 & `unit'==`treated_unit'

loc npp = r(N)


	if !_rc {
		
		su `unit' if `treated' ==1, mean
		
		loc clab: label (`unit') `treated_unit'
		gl treat_lab: disp "`clab'"
		
		
		qui: levelsof `unit' if `treated' == 0 & `time' > `interdate', l(labs)

		local lab : value label `unit'

		foreach l of local labs {
		    local all `all' `: label `lab' `l'',
		}

		loc controls: display "`all'"
				
		di as txt ""
		display "Treatment is measured from " $time_format `interdate' " to " $time_format  `last_date' " (`npp' pre-periods)"
		
		
		qui distinct `unit' if `treated' == 0
		
		loc dp_num = r(ndistinct) - 1
		
		cap as `dp_num' > 2
		if _rc {
			
		di in red "You need at least 2 donors for every treated unit"
		exit 489
		}
		di as res "{hline}"
		di "{txt}{p 15 50 0} Treated Unit: {res}$treat_lab {p_end}"
		di as res "{hline}"
		di as txt ""
		di "{txt}{p 15 30 0} Control Units: {res}`dp_num' total donor pool units{p_end}"
		di as res "{hline}"
		di as txt ""
		di "{txt}{p 15 30 0} Specifically: {res}`controls'{p_end}"

	}	

		if !mi("`covs'") {
		di as res "{hline}"
		di "{txt}{p 15 30 0} You've adjusted for the following covariates: `covs' {p_end}"
		}

end



cap prog drop data_org // Subroutine 1.3
prog data_org, eclass
        
syntax, time(varname) depvar(varname) unit(varname) [covs(varlist)] treated(varname)

/*#########################################################

	* Section 1.3: Reorganizing the Data into Matrix Form

	We need a wide dataset to do what we want.
*########################################################*/

di as txt "{hline}"
di as txt "Second Step: Data Reorganizing"
di as txt "{hline}"

qui su `unit' if `treated' ==1, mean

loc treat_id = `r(mean)'

qui su `time' if `treated' ==1
ereturn scalar interdate = r(min)

keep `unit' `time' `depvar' `covs'
di "Reshaping..."
qui greshape wide `depvar' `covs', j(`unit') i(`time')


foreach v in `covs' {
	
	cap drop `v'`treat_id'

}

di as txt "Done!"
di as txt ""
qui: tsset `time'

order `depvar'`treat_id', a(`time')
//sa dataprocess, replace

end

cap prog drop est_lasso // Subroutine 2.1

prog est_lasso, eclass
	
syntax, ///
	time(varname) ///
	h(numlist min=1 max=1 >=1 int) ///
	interdate(numlist min=1 max=1 >=1 int) ///
	lambda(string) ///
	[cv(string)] ///
	[scheme(string)] ///
	[obscol(string)] ///
	[cfcol(string)] ///
	[conf(string)] ///
	[legpos(numlist min=1 max=1 >=1)] ///
	[transform(string)] ///
	[intname(string)] ///
	[rellab(numlist)] ///
	[q(numlist min=0 max=1)] [outlab(string)]
	
di as txt "{hline}"
di as txt "Third Step: Estimation"
di as txt "{hline}"


qui ds

loc temp: word 1 of `r(varlist)'

loc time: disp "`temp'"

loc t: word 2 of `r(varlist)'

loc treated_unit: disp "`t'"

loc a: word 3 of `r(varlist)'

loc donor_one: disp "`a'" // First donor unit...

local nwords :  word count `r(varlist)'

loc b: word `nwords' of `r(varlist)'

loc last_donor: disp "`b'" // Last donor...

cap as "`lambda'" =="lopt"

if !_rc {
	
	loc ltype "optimal lambda"
}

cap as "`lambda'" =="lse"

if !_rc {
	
	loc ltype "one standard error lambda"
}


di as txt "Optimizing (`ltype')... This could take quite a while..."
di as txt ""
di as txt ""


timer clear 1
timer on 1

qui cvlasso `treated_unit' ///
	`donor_one'-`last_donor' ///
	if `time' < `interdate', ///
	`lambda' ///
	lglmnet ///
	roll ///
	h(`h') `cv' postres alpha(`q') ///
	prest
	
timer off 1


qui timer list

loc minutes: di %3.2f r(t1)/60

di as txt "Optimization took `minutes' minutes"	

qui{
cap drop cf
qui predict double cf, `lambda' // Here is our counterfactual

keep `time' `treated_unit' cf // We only need these

	if "`transform'" == "norm" {
			
	qui replace cf = 1 if `time' ==`interdate'-1
	}

lab var cf "Counterfactual"

lab var `treated_unit' "$treat_lab"

g relative = `time'- `interdate' // Generate an event-time variable

g diff_ = `treated_unit'- cf // Difference between the cf and the observed outcomes


/* Strictly, this should be quite close to 0 before the intervention, and
moderate to large after the intervention. */

qui su if relative < 0

if r(N) > = 10 {

loc obs_pre = r(N)

qui su if relative > = 0

loc obs_post = r(N)

loc K = 3

loc r: di floor((`obs_pre'/`K')/`obs_post')

loc sd_lheq = sqrt(1+(`K'*`r'/`obs_post'))

*di `sd_lheq'

loc right_sd_t1 = 1/(`K'-1)

*di `sd_lheq'*sqrt(`right_sd_t1')

cap drop te_*

cap drop te

tempvar ssd

qui g `ssd' = diff_^2

qui su `ssd'

loc sd_scm: di sqrt(`sd_lheq')*sqrt(`right_sd_t1'*`r(sum)')

loc sqk = sqrt(`K')

qui su diff_ if relative > 0

loc te = r(mean)

qui su diff_ if relative < 0

loc cfmean = r(mean)

loc tau = abs((`sqk'*(`te'-`cfmean'))/`sd_scm')

local czw_t : di %6.4g round(`tau',0.001)

loc se = `sd_scm'/`sqk'

g te_ub = diff_+((`tau'*(1 - .95/2))*`se')

g te_lb = diff_-((`tau'*(1 - .95/2))*`se')
}

else if r(N) < 10 {
loc obs_pre = r(N)

qui su if relative > = 0

loc obs_post = r(N)

loc r: di floor((`obs_pre'/5)/`obs_post')

loc sd_lheq = sqrt(1+(5*`r'/`obs_post'))

*di `sd_lheq'

loc right_sd_t1 = 1/(5-1)

*di `sd_lheq'*sqrt(`right_sd_t1')

cap drop te_*

cap drop te

tempvar ssd

qui g `ssd' = diff_^2

qui su `ssd'

loc sd_scm: di sqrt(`sd_lheq')*sqrt(`right_sd_t1'*`r(sum)')

loc sqk = sqrt(5)

qui su diff_ if relative > 0

loc te = r(mean)

qui su diff_ if relative < 0

loc cfmean = r(mean)

loc tau = abs((`sqk'*(`te'-`cfmean'))/`sd_scm')

local czw_t : di %6.4g round(`tau',0.001)

loc se = `sd_scm'/`sqk'

g te_ub = diff_+(`tau'*(1 - .95/2)*`se')

g te_lb = diff_-(`tau'*(1 - .95/2)*`se')
	
	
}
/*
g cf_lb = cf + te_lb
g cf_ub = cf + te_ub
*/
g cf_ub = .
replace cf_ub = cf+abs( te_lb) if relative >= -1 & te_lb < 0
g cf_lb = .
replace cf_lb = cf-abs( te_ub) if relative >= -1 & te_ub < 0

replace cf_ub = cf+abs( te_lb) if relative >= -1 & te_lb > 0

replace cf_lb = cf-abs( te_ub) if relative >= -1 & te_ub > 0

cap drop `ssd'
qui sa "scul_$treat_lab.dta", replace // Make a dataset of the 5 variables

tempname treat contr loss err ///
trpost cpost losspost errpost

mkmat `treated_unit' if relative < 0, mat(`treat')

mkmat cf if relative < 0, mat(`contr')

mat `loss' = (`treat' - `contr')' * (`treat' - `contr')

mat `loss' = `loss' / rowsof(`treat')

mata: X = round(sqrt(st_matrix("`loss'")),.000000001)

mata: st_matrix("`loss'", X)

sca `err' =`loss'[1,1]

local errround : di %6.3f scalar(`err')
***

mkmat `treated_unit' if relative >= 0, mat(`trpost')

mkmat cf if relative >= 0, mat(`cpost')

mat `losspost' = (`trpost' - `cpost')' * (`trpost' - `cpost')

mat `losspost' = `losspost' / rowsof(`trpost')

mata: X = round(sqrt(st_matrix("`losspost'")),.000000001)

mata: st_matrix("`losspost'", X)

sca `errpost' =`losspost'[1,1]

local errroundtwo : di %6.3f scalar(`errpost')


/*
qui: esize unpaired `treated_unit' == cf if relative < 0, cohensd

loc D: disp float(`r(d)')
*/

qui: su diff_ if relative >= 0, mean

sca ATT1 =`r(mean)'

/* This is the ATT for a single intervention. The
average of the difference after the intervention. */


local ATT : di %12.3f scalar(ATT1)

loc x : word count `cfcol'

if `x'== 0 {
	
	loc cfcol blue
}

loc x : word count `intname'

if `x'== 0 {
	
	loc intname Event
}

lab var relative "Relative Time to `intname'"

**# Single Treated Graphs


if "`conf'"=="ci" {

tw ///
	(line `treated_unit' cf `time', ///
		lcol("`obscol'" "`cfcol'") ///
		lpat(solid shortdash) ///
		lwidth(medium medthin) xlab(, noticks)) /// Real Outcomes
	 (rarea cf_lb cf_ub `time', fcolor(gs6%50) lcolor(pink) lwidth(none)),,, /// Potential Outcomes
		legend(order(1 "Real $treat_lab" 2 "Synthetic $treat_lab" 3 "Upper/Lower Bound") ///
		color(black) fcolor(white) region(fcolor("214 211 202")) ring(0) position(`legpos') rows(3)) ///
		yti("`outlab'") ///
		ylab(#4, noticks) name("Real_1", replace) ///
		scheme(`scheme') xsize(6) ysize(4) ///
		caption("RMSE = `errround', ATT: `ATT'", position(6)) ///
		note("Dashed reference line is `intname', `:di $time_format `interdate''.") ///
		xli(`interdate', lcol("52 44 44") lpat(dash) lwidth(thin)) //
		
		
		if mi("`transform'") {
	

		twoway (line diff_ relative, xlab(`rellab', noticks) ///
		lcolor("`cfcol'") lwidth(medium)) ///
		(rarea te_lb te_ub relative, fcolor(gs6%50) lcolor(gs14%50) lwidth(none)), ///
		xli(0, lcol("52 44 44") lpat(dash) lwidth(thin)) ///
		yti("Pointwise Treatment Effect") ///
		xti("t-`=ustrunescape("\u2113")' until `intname'") ///
		name(sculgap, replace) scheme(`scheme') ///
		xsize(6) ysize(4)  ///
		legend(order(1 "Causal Impact" 2 "95% Confidence Interval") ///
		color(black) fcolor(white) region(fcolor("214 211 202")) ring(0) position(`legpos') rows(2)) //
		}
		if "`transform'" == "norm" {
		
		twoway (line diff_ relative, ///
		lcolor("`cfcol'") lwidth(medium) xlab(`rellab', noticks)) ///
		(rarea te_lb te_ub relative, fcolor(gs6%50) lcolor(gs14%50) lwidth(none)), ///
		xli(-1, lcol("52 44 44") lpat(dash) lwidth(thin)) ///
		yti("Normalized Effect (%)") ///
		xti("t-`=ustrunescape("\u2113")' until `intname'") ///
		name(sculgap, replace) scheme(`scheme') ///
		xsize(6) ysize(4) ///
		legend(order(1 "Causal Impact" 2 "95% Confidence Interval") ///
		color(black) fcolor(white) region(fcolor("214 211 202")) ring(0) position(`legpos') rows(2))
	}


	}
	
if "`conf'" !="ci" {

tw ///
	(line `treated_unit' cf `time', ///
		lcol("`obscol'" "`cfcol'") ///
		lpat(solid dash) lwidth(medium medthin)), /// Real Outcomes
		legend(order(1 "Real $treat_lab" 2 "Synthetic $treat_lab") ///
		color(black) fcolor(white) region(fcolor(gs14%50)) ring(0) position(`legpos') rows()) /// gs14%50
		yti(`outlab') ///
		ylab(#4, noticks) xlab(, noticks) name("Real_1", replace) ///
		scheme(`scheme') xsize(6) ysize(4) ///
		caption("RMSE = `errround', ATT: `ATT'", position(6)) ///
		note("Dashed reference line is `intname', `:di $time_format `interdate''.") ///
		xli(`interdate', lcol("52 44 44") lpat(dash) lwidth(thin)) //
		
		
	if "`transform'" == "norm" {
		
		
		
twoway (line diff_ relative, lcolor("`obscol'") lwidth(medium)), ///
ytitle(Normalized Effect (%)) ///
xline(-1, lpattern(dash) lwidth(thin) lcol("52 44 44")) xti("t-`=ustrunescape("\u2113")' to `intname'") ///
name(sculgap, replace) scheme(`scheme')  xsize(6) ysize(4)
/*
		twoway (line diff_ relative, ///
		lcolor(`obscol') lwidth(thick)), ///
		xlab(`rellab', noticks), ///
		ytitle(Normalized Effect (%)) ///
		xline(-1, lpattern(solid)) ///
		xti("t-`=ustrunescape("\u2113")' until `intname'") ///
		name(sculgap, replace)
*/
	}
	
	if "`transform'"!="norm" {
	
		twoway (line diff_ relative, ///
		lcolor("`cfcol'") lpat(dash) lwidth(medium) xlab(`rellab', noticks)), ///
		xli(0, lpattern(dash) lwidth(thin) lcol("52 44 44")) ///
		yti("Pointwise Treatment Effect") ///
		xti("t-`=ustrunescape("\u2113")' until `intname'") ///
		name(sculgap, replace) scheme(`scheme') ///
		xsize(6) ysize(4)

}
	}

su te_lb if relative >=0
loc LB: disp %6.3f `r(mean)'

su te_ub if relative >=0
loc UB: disp %6.3f `r(mean)'

ereturn scalar ATT = `ATT'
ereturn scalar LB = `LB'
ereturn scalar UB = `UB'

ereturn scalar MSE = `err'

ereturn scalar PMSE = `errpost'

ereturn scalar ratio = `errpost'/`err'

}
qui lab var cf "Counterfactual"
qui lab var `treated_unit' "$treat_lab"
tabdisp relative, cell(`treated_unit' cf)
macro drop treat_lab outlab int_date
end
	
cap prog drop placebos_process // Subroutine 2.2
prog placebos_process
	
syntax, time(varname) unit(varname) treatunit(numlist min=1 max=1 >=1 int) [transform(string)] interdate(numlist min=1 max=1 >=1 int)

/*#########################################################

	* Section 1.2: Check Treatment Variable

	Before SCM can be done, we need the treatment to make sense.
	
	
	Making sense is simply the treatment being non-missing
	and being either 0 or 1
*########################################################*/

di as txt "{hline}"
di as txt "Checking that the treatment makes sense..."
di as txt "{hline}"


g treated_synth = 1 if `unit' == `treatunit' & `time' > = `interdate'

replace treated_synth = 0 if mi(treated_synth)

qui: su `time' if treated_synth ==1
loc last_date = r(max)


	if !_rc {
		
		su $panel if treated_synth ==1, mean
		gl treat_id = `r(mean)'
		loc clab: label ($panel) `r(mean)'
		gl treat_lab: disp "`clab'"
		
		
		qui: levelsof $panel if treated_synth == 0 & $time > `interdate', l(labs)

		local lab : value label $panel
qui {
		foreach l of local labs {
		    local all `all' `: label `lab' `l'',
		}
}
		loc controls: display "`all'"
		
		
		disp as res "The intervention variable `treat' passes. Continue."		
		di as txt ""
		disp as res "Intervention is measured between $int_date to `last_date'"
		
		qui: distinct `unit' if treated_synth == 0
		
		loc dp_num = r(ndistinct) - 1
		
		as `dp_num' > 2
		di as res "{hline}"
		di as res "Treated Unit: $treat_lab"
		di as txt ""
		di as res "Control Units: `dp_num' total donor pool units"
		di as txt ""
		di as res "Specifically: `controls'"

	}	

	if "`transform'" == "norm" {
		
	di "You've asked me to normalize `depvar'."
	
	tempvar _XnormVar _xXnormVar
			
	loc pretreatm1 = `trdate'-1
	
	qui g `_XnormVar' = `depvar' if `time' == `pretreatm1'
	
	
	qbys `unit': egen `_xXnormVar' = max(`_XnormVar')
	
	qui replace `depvar' = 1*`depvar'/`_xXnormVar'
	}


end

cap prog drop data_org_placebos // Subroutine 2.3
prog data_org_placebos
	
syntax, time(varname) depvar(varname) unit(varname) [covs(varlist)]

/*#########################################################

	* Section 1.3: Reorganizing the Data into Matrix Form

	We need a wide dataset to do what we want.
*########################################################*/

di as txt "{hline}"
di as txt "Reshaping Data..."

su `unit' if treated_synth ==1, mean

loc treat_id: disp `r(mean)'


keep `unit' `time' `depvar' `covs'
di as txt "Reshaping..."
qui: greshape wide `depvar' `covs', j(`unit') i(`time')


foreach v in `covs' {
	
	cap drop `v'`treat_id'

}
di as txt "Done"
qui: tsset `time'

order `depvar'`treat_id', a(`time')

end


/**********************************************************

	*Section 2: Estimating Causal Effects
	
**********************************************************/

cap prog drop est_placebos // Subroutine 2.1
prog est_placebos
	
syntax, time(varname) h(numlist min=1 max=1 >=1 int) ///
interdate(numlist min=1 max=1 >=1 int) ///
treatunit(numlist min=1 max=1 >=1 int) ///
 lambda(string) [cv(string)] [scheme(string)] ///
 [transform(string)] [q(numlist min=0 max=1)]

qui: ds

loc temp: word 1 of `r(varlist)'

loc time: disp "`temp'"

loc t: word 2 of `r(varlist)'

loc treated_unit: disp "`t'"

loc a: word 3 of `r(varlist)'

loc donor_one: disp "`a'"

local nwords :  word count `r(varlist)'

loc b: word `nwords' of `r(varlist)'

loc last_donor: disp "`b'"

cap cvlasso `treated_unit' `donor_one'-`last_donor' if `time' < `interdate', `lambda' lglmnet roll h(`h') `cv' ///
alpha(`q') prest

cap drop cf_$treat_id
qui predict double cf_$treat_id, `lambda'


qui: keep `time' `treated_unit' cf_$treat_id

	if "`transform'" == "norm" {
			
	qui replace cf_$treat_id = 1 if `time' ==`interdate'-1
	}


qui g relative = `time'- `interdate'

qui g diff_$treat_id = `treated_unit'- cf_$treat_id

qui compress
qui sa "scul_placebos_$treat_lab", replace

macro drop treat_lab outlab int_date
end


/**********************************************************

	*Section 3: Multi-treated unit Routines
	
**********************************************************/

cap prog drop numcheck_multi // Subroutine 1.1
prog numcheck_multi
// Original Data checking
syntax, unit(varname) ///
	time(varname) ///
	depvar(varname) ///
	treated(varname) ///
	treatunit(numlist min=1 max=1 >=1 int) ///
	treatdate(numlist min=1 max=1 >=1 int) ///
	[transform(string)]
	
		
/*#########################################################

	* Section 1.1: Extract panel vars

	Before SCM can be done, we need panel data.
	
	
	Along with the R package, I'm checking that
	our main vairables of interest, that is,
	our panel variables and outcomes are all:
	
	a) Numeric
	b) Non-missing and
	c) Non-Constant
	
*########################################################*/

di as txt "{hline}"
di as txt "Algorithm: Synthetic LASSO, Multiple Interventions"
di as txt "{hline}"
di as txt "First Step: Data Setup"
di as txt "{hline}"
di as txt "Checking that setup variables make sense."

qui distinct `unit' if `treated'==1

cap as r(ndistinct) >= 2 & inlist(`treated',0,1)

*## Unit Test 1: Ensure Multiple Units Were Actually Treated

	if _rc { 
		
		
		di as err "When you specify the multi-treatment option, you need more than one unit to be treated."
		di as txt ""
		di as err "At present, `r(ndistinct)' units are treated."
		di as err "Also, the treatment must either be 0 or 1."
		exit 498
	}


tempvar obs_count
qbys `unit' (`time'): g `obs_count' = _N
qui su `obs_count'

qui drop if `obs_count' < `r(max)'

/*The panel should be balanced, but in case it isn't somehow, we drop any variable
without the maximum number of observations (unbalanced) */

	foreach v of var `unit' `time' `depvar' `treated' {
	cap {	
		conf numeric v `v', ex // Numeric?
		
		as !mi(`v') // Not missing?
		
		qui: su `v'
		
		as r(sd) ~= 0 // Does the unit ID change?
	}
	}
	if !_rc {
		
		
		di as res "Setup successful!! All variables `unit' (ID), `time' (Time), `treated' (Intervention) and `depvar' (Outcome) pass."
		di as txt ""
		di as res "All are numeric, not missing and non-constant."
	}
	
	else if _rc {
		
		
		
		disp as err "All variables `unit' (ID), `time' (Time), `treated' (Intervention) and `depvar' must be numeric, not missing and non-constant."
		exit 498
	}
	
	if "`transform'" == "norm" {
		
	di "You've asked me to normalize `depvar'."
	
	tempvar _XnormVar _xXnormVar
			
	loc pretreatm1 = `treatdate'-1
	
	qui g `_XnormVar' = `depvar' if `time' == `pretreatm1'
	
	qbys `unit': egen `_xXnormVar' = max(`_XnormVar')
	
	qui replace `depvar' = 1*`depvar'/`_xXnormVar'
	}

end


cap prog drop treatprocess_multi // Subroutine 3.2
prog treatprocess_multi

syntax, time(varname) ///
unit(varname) ///
treated(varname) ///
[covs(varlist)] ///
treatunit(numlist min=1 max=1 >=1 int) ///
donadj(string)

/*#########################################################

	* Section 1.2: Check Treatment Variable

	Before SCM can be done, we need a treatment variable.
	
	
	The treatment enters at a given time and never leaves.
*########################################################*/

di as txt "{hline}"
di as txt "Collecting our treated units..."
di as txt "{hline}"

if !inlist("`donadj'","et","nt") & !mi("`donadj'") {
	
	di in red "Ever or never treated units are the only options."
	di in red "Specify either et or nt."
	exit 498
}


if "`donadj'" == "et" {
qui su `time' if `unit' == `treatunit' & `treated' == 1

// if panel == treatedid

qui levelsof `unit' if `time' < r(min) & `treated' == 1, l(previous)

loc dropped: word count `previous'

	foreach l of loc previous {
qui	drop if `unit' == `l'
	
	}
	}
	
if "`donadj'" == "nt" {
	
qui levelsof `unit' if `treated'==1 & `unit' != `treatunit', loc(drops) sep(",")

loc dropped: word count `drops'

drop if inlist(`unit',`drops')

	}
	
qui insp `time' if `treated' ~= 1 & `unit'==`treatunit'

loc npp = r(N)
		
		su `unit' if `treated' ==1, mean
		
		loc clab: label (`unit') `treatunit'
		gl treat_lab: disp "`clab'"
		
		
		qui: levelsof `unit' if `treated' == 0 & `time' > r(min) & `unit' ~= `treatunit', l(labs)

		local lab : value label `unit'

		foreach l of local labs {
		    local all `all' `: label `lab' `l'',
		}

		loc controls: display "`all'"
		
		qui su `time' if `treated' ==1, mean
		di as txt ""
		display "Treatment is measured from " $time_format r(min) " to " $time_format  r(max) " (`npp' pre-periods)"
		
		qui: distinct `unit' if `treated' == 0
		
		loc dp_num = r(ndistinct) - 1
		
		cap as `dp_num' > 2
		
		if _rc {
			
			di in red "You need at least 2 donors for every treated unit"
			exit 489
		}
		di as res "{hline}"
		di as res "Treated Unit: $treat_lab"
		if `dropped' ~= 0 & "`donadj'" == "et" {
		di "Other already-treated units encountered in the pre-period, `dropped' unit(s) dropped."
		
		else if `dropped' ~= 0 & "`donadj'" == "nt" {
		di "Other treated units encountered, `dropped' unit(s) dropped."

}
		}
		di as txt ""
		di as res "Control Units: `dp_num' total donor pool units"
		di as txt ""
		di as res "Specifically: `controls'"
		
		if "`covs'"=="`covs'" {
			
			disp "`covs'"
		}
		
qui su `time' if `treated', mean

gl int_date = r(min)

end




cap prog drop data_org_multi // Subroutine 3.3
prog data_org_multi
        
syntax, time(varname) depvar(varname) unit(varname) [covs(varlist)] treatunit(numlist min=1 max=1 >=1 int) [scheme(string)]

/*#########################################################

	* Section 1.3: Reorganizing the Data into Matrix Form

	We need a wide dataset to do what we want.
*########################################################*/

di as txt "{hline}"
di as txt "Second Step: Data Reorganizing"
di as txt "{hline}"

su `unit' if `unit' == `treatunit', mean

gl treat_id: disp `r(mean)'


keep `unit' `time' `depvar' `covs'
di as txt "Reshaping..."
qui: greshape wide `depvar' `covs', j(`unit') i(`time')


foreach v in `covs' {
	
	cap drop `covs'$treat_id

}

di as txt "Done"
qui: tsset `time'

order `depvar'$treat_id, a(`time')

*qui sa `treat_id'_wide, replace

end


cap prog drop est_lasso_multi // Subroutine 3.4
prog est_lasso_multi
	
syntax, time(varname) h(numlist min=1 max=1 >=1 int) lambda(string) treatunit(numlist min=1 max=1 >=1 int) [cv(string)] [scheme(string)] ///
[q(numlist min=0 max=1)] [transform(string)]

di as txt "{hline}"
di as txt "Third Step: Estimation"
di as txt "{hline}"


qui: ds

loc temp: word 1 of `r(varlist)'

loc time: disp "`temp'"

loc t: word 2 of `r(varlist)'

loc treated_unit: disp "`t'"

loc a: word 3 of `r(varlist)'

loc donor_one: disp "`a'" // First donor unit...

local nwords :  word count `r(varlist)'

loc b: word `nwords' of `r(varlist)'

loc last_donor: disp "`b'" // Last donor...

di as txt "Estimating... This could take quite a while..."


qui cvlasso `treated_unit' ///
	`donor_one'-`last_donor' ///
	if `time' < $int_date, ///
	`lambda' ///
	lglmnet ///
	roll ///
	h(`h') `cv' alpha(`q')
//set tr on
qui{
cap drop cf_$treat_id
predict double cf_$treat_id, `lambda' // Here is our counterfactual
}

	if "`transform'" == "norm" {
			
	qui replace cf = 1 if `time' ==$int_date - 1
	}

qui: keep `time' `treated_unit' cf_$treat_id // We only need these three

g relative_$treat_id = `time'- $int_date // Generate an event-time variable

g diff_$treat_id = `treated_unit'- cf_$treat_id // Difference between the cf and the observed outcomes

/* Strictly, this should be quite close to 0 before the intervention, and
moderate to large agter the intervention. */

qui su if relative_$treat_id < 0

loc obs_pre = r(N)

qui su if relative_$treat_id > = 0

loc obs_post = r(N)

loc r: di floor((`obs_pre'/`e(nfolds)')/`obs_post')

loc sd_lheq = sqrt(1+(`e(nfolds)'*`r'/`obs_post'))

*di `sd_lheq'

loc right_sd_t1 = 1/(`e(nfolds)'-1)

*di `sd_lheq'*sqrt(`right_sd_t1')

cap drop te_*

cap drop te

tempvar ssd

qui g `ssd' = diff_$treat_id ^2

qui su `ssd'

loc sd_scm: di sqrt(`sd_lheq')*sqrt(`right_sd_t1'*`r(sum)')

loc sqk = sqrt(`e(nfolds)')

qui su diff_$treat_id if relative_$treat_id > 0

loc te = r(mean)

qui su diff_$treat_id if relative_$treat_id < 0

loc cfmean = r(mean)

loc tau = abs((`sqk'*(`te'-`cfmean'))/`sd_scm')

local czw_t : di %6.4g round(`tau',0.001)

loc se = `sd_scm'/`sqk'

g lowbound_$treat_id = diff_$treat_id-(`tau'*(1 - .95/2)*`se')

g upbound_$treat_id = diff_$treat_id+(`tau'*(1 - .95/2)*`se')

/* Strictly, this should be quite close to 0 before the intervention, and
moderate to large agter the intervention. */

drop `ssd'

qui sa "mscul_$treat_lab.dta", replace // Make a dataset of the 5 variables

macro drop treat_lab outlab int_date
end


/**********************************************************

	*Section 3: Staggered Placebos
	
**********************************************************/


cap prog drop numcheck_multi_placebos // Subroutine 1.1
prog numcheck_multi_placebos
// Original Data checking
syntax, unit(varname) time(varname) depvar(varname) treated(varname)
	
		
/*#########################################################

	* Section 1.1: Extract panel vars

	Before SCM can be done, we need panel data.
	
	
	Along with the R package, I'm checking that
	our main vairables of interest, that is,
	our panel variables and outcomes are all:
	
	a) Numeric
	b) Non-missing and
	c) Non-Constant
	
*########################################################*/

di as txt "{hline}"
di as txt "Algorithm: Synthetic LASSO, Multiple Interventions"
di as txt "{hline}"
di as txt "First Step: Data Setup"
di as txt "{hline}"
di as txt "Checking that setup variables make sense."

di as txt in red "Note that this will take a long time...."

qui distinct `unit' if `treated'==1

cap as r(ndistinct) >= 2 & inlist(`treated',0,1)

*## Unit Test 1: Ensure Multiple Units Were Actually Treated

	if _rc { 
		
		
		di as err "When you specify the multi-treatment option, you need more than one unit to be treated."
		di as txt ""
		di as err "At present, `r(ndistinct)' units are treated."
		di as err "Also, the treatment must either be 0 or 1."
		exit 498
	}


tempvar obs_count
qbys `unit' (`time'): g `obs_count' = _N
qui su `obs_count'

qui drop if `obs_count' < `r(max)'

/*The panel should be balanced, but in case it isn't somehow, we drop any variable
without the maximum number of observations (unbalanced) */

	foreach v of var `unit' `time' `depvar' `treated' {
	cap {	
		conf numeric v `v', ex // Numeric?
		
		as !mi(`v') // Not missing?
		
		qui: su `v'
		
		as r(sd) ~= 0 // Does the unit ID change?
	}
	}
	if !_rc {
		
		
		di as res "Setup successful!! All variables `unit' (ID), `time' (Time), `treated' (Intervention) and `depvar' (Outcome) pass."
		di as txt ""
		di as res "All are numeric, not missing and non-constant."
	}
	
	else if _rc {
		
		
		
		disp as err "All variables `unit' (ID), `time' (Time), `treated' (Intervention) and `depvar' must be numeric, not missing and non-constant."
		exit 498
	}
	

end

cap prog drop placebos_treat_multi 
prog placebos_treat_multi 
        
syntax, time(varname) ///
unit(varname) ///
treated(varname) ///
[covs(varlist)] ///
treatunit(numlist min=1 max=1 >=1 int) ///
donadj(string) ///
tredate(numlist min=1 max=1) ///
placebounit(numlist min=1 max=1)

/*#########################################################

	* Section 1.2: Check Treatment Variable

	Before SCM can be done, we need a treatment variable.
	
	
	The treatment enters at a given time and never leaves.
*########################################################*/

di as txt "{hline}"
di as txt "Collecting our treated units..."
di as txt "{hline}"

if !inlist("`donadj'","et","nt") & !mi("`donadj'") {
	
	di in red "Ever or never treated units are the only options."
	di in red "Specify either et or nt."
	exit 498
}


if "`donadj'" == "et" {
qui su `time' if `unit' == `treatunit' & `treated' == 1

// if panel == treatedid

qui levelsof `unit' if `time' < r(min) & `treated' == 1, l(previous)

loc dropped: word count `previous'

	foreach l of loc previous {
qui	drop if `unit' == `l'
	
	}
	}
	
if "`donadj'" == "nt" {
	
qui levelsof `unit' if `treated'==1 & `unit' != `treatunit', loc(drops) sep(",")

loc dropped: word count `drops'

qui drop if inlist(`unit',`drops')

	}
		
		su `unit' if `treated' ==1, mean
		
		loc clab: label (`unit') `placebounit'
		gl treat_lab: disp "`clab'"
		
		
		qui: levelsof `unit' if `treated' == 0 & `time' > r(min) & `unit' ~= `placebounit', l(labs)

		local lab : value label `unit'

		foreach l of local labs {
		    local all `all' `: label `lab' `l'',
		}

		loc controls: display "`all'"
		
		qui su `time' if `treated' ==1, mean
		di as txt ""
		display "Treatment is measured from " $time_format `tredate' " to " $time_format  r(max)
		
		qui: distinct `unit' if `treated' == 0
		
		loc dp_num = r(ndistinct) - 1
		
		cap as `dp_num' > 2
		
		if _rc {
			
			di in red "You need at least 2 donors for every treated unit"
			exit 489
		}
		di as res "{hline}"
		di as res "Treated Unit: $treat_lab"
		if `dropped' ~= 0 & "`donadj'" == "et" {
		di "Other already-treated units encountered in the pre-period, `dropped' unit(s) dropped."
		
		else if `dropped' ~= 0 & "`donadj'" == "nt" {
		di "Other treated units encountered, `dropped' unit(s) dropped."

}
		}
		di as txt ""
		di as res "Control Units: `dp_num' total donor pool units"
		di as txt ""
		di as res "Specifically: `controls'"
		
		if "`covs'"=="`covs'" {
			
			disp "`covs'"
		}

end

cap prog drop placebos_org_multi // Subroutine 3.3
prog placebos_org_multi
        
syntax, time(varname) depvar(varname) unit(varname) [covs(varlist)] plaunit(numlist min=1 max=1 >=1 int) [scheme(string)]

/*#########################################################

	* Section 1.3: Reorganizing the Data into Matrix Form

	We need a wide dataset to do what we want.
*########################################################*/

di as txt "{hline}"
di as txt "Second Step: Data Reorganizing"
di as txt "{hline}"


keep `unit' `time' `depvar' `covs'
di as txt "Reshaping..."
qui: greshape wide `depvar' `covs', j(`unit') i(`time')


foreach v in `covs' {
	
	cap drop `covs'$treat_id

}

di as txt "Done"
qui: tsset `time'

order `depvar'`plaunit', a(`time')

*qui sa `treat_id'_wide, replace

end

cap prog drop numcheck_itp
prog numcheck_itp, eclass
// Original Data checking
syntax, ///
	unit(varname) ///
	time(varname) ///
	depvar(varname) ///
	[transform(string)] ///
	[q(numlist min=0 max=1)] ///
	treated(varname)
	
		
/*#########################################################

	* Section 1.1: Extract panel vars

	Before SCM can be done, we need panel data.
	
	
	Along with the R package, I'm checking that
	our main vairables of interest, that is,
	our panel variables and outcomes are all:
	
	a) Numeric
	b) Non-missing and
	c) Non-Constant
	
*########################################################*/

cap as `q' ==1

if !_rc {
	
	loc optimizer "LASSO"
}

cap as `q' ==0 

if !_rc {
	
	loc optimizer "Ridge"
}

cap as `q' !inlist(`q',0,1)

if !_rc {
	
	loc optimizer "Elastic-Net"
}

cap if mi("`q'")  {
	
	loc optimizer "LASSO"
}

di as txt "{hline}"
di as txt "Algorithm: Synthetic `optimizer', Single Unit Treated"
di as txt ""
di as txt "In Time Placebos..."
di as txt "{hline}"
di as txt "First Step: Data Setup"
di as txt "{hline}"
di as txt "Checking that setup variables make sense."

tempvar obs_count
qbys `unit' (`time'): g `obs_count' = _N
qui su `obs_count'

qui drop if `obs_count' < `r(max)'

/*The panel should be balanced, but in case it isn't somehow, we drop any variable
without the maximum number of observations (unbalanced) */


	foreach v of var `unit' `time' `depvar' {
	cap {	
		conf numeric v `v', ex // Numeric?
		
		as !mi(`v') // Not missing?
		
		qui: su `v'
		
		as r(sd) ~= 0 // Does the unit ID change?
	}
	}
	if !_rc {
		
		
		di as res "Setup successful!! All variables `unit' (ID), `time' (Time) and `depvar' (Outcome) pass."
		di as txt ""
		di as res "All are numeric, not missing and non-constant."
	}
	
	else if _rc {
		
		
		
		disp as err "All variables `unit' (ID), `time' (Time) and `depvar' must be numeric, not missing and non-constant."
		exit 498
	}
	
	qui su $time if `treated'==1
	
	loc interdate = r(min)
	
	if "`transform'" == "norm" {
		
	di "You've asked me to normalize `depvar'."
	
	tempvar _XnormVar _xXnormVar
			
	loc pretreatm1 = r(min)-1
	
	qui g `_XnormVar' = `depvar' if `time' == `pretreatm1'
	
	
	qbys `unit': egen `_xXnormVar' = max(`_XnormVar')
	
	qui replace `depvar' = 1*`depvar'/`_xXnormVar'
	}
	
ereturn scalar interdate = `interdate'	
end

cap prog drop treatprocess_itp // Subroutine 1.2
prog treatprocess_itp, eclass
        
syntax, time(varname) unit(varname) [covs(varlist)] treated(varname) times(numlist)

/*#########################################################

	* Section 1.2: Check Treatment Variable

	Before SCM can be done, we need a treatment variable.
	
	
	The treatment enters at a given time and never leaves.
*########################################################*/
if `times' == 0 {
di as txt "{hline}"

di as txt "Inspecting our treatment variable..."
di as txt "{hline}"
}
qui su `time' if `treated' ==1

loc last_date = r(max)
loc interdate = r(min)-`times'

qui su `unit' if `treated'==1

loc treated_unit = r(min)

qui insp `time' if `treated' ~= 1 & `unit'==`treated_unit'

loc npp = r(N)-`times'

cap as `npp' > 5

if _rc {
	
	di in red "You need more than 5 periods"
}



	if !_rc {
		
		su `unit' if `treated' ==1, mean
		
		loc clab: label (`unit') `treated_unit'
		gl treat_lab: disp "`clab'"
		
		
		qui: levelsof `unit' if `treated' == 0 & `time' > `interdate', l(labs)

		local lab : value label `unit'

		foreach l of local labs {
		    local all `all' `: label `lab' `l'',
		}

		loc controls: display "`all'"
if `times' == 0 {				
		di as txt ""
		display "Treatment is measured from " $time_format `interdate' " to " $time_format  `last_date' " (`npp' pre-periods)"
		
		
		qui distinct `unit' if `treated' == 0
		
		loc dp_num = r(ndistinct) - 1
		
		cap as `dp_num' > 2
		if _rc {
			
		di in red "You need at least 2 donors for every treated unit"
		exit 489
		}
		di as res "{hline}"
		di "{txt}{p 15 50 0} Treated Unit: {res}$treat_lab {p_end}"
		di as res "{hline}"
		di as txt ""
		di "{txt}{p 15 30 0} Control Units: {res}`dp_num' total donor pool units{p_end}"
		di as res "{hline}"
		di as txt ""
		di "{txt}{p 15 30 0} Specifically: {res}`controls'{p_end}"

	}	

		if !mi("`covs'") {
		di as res "{hline}"
		di "{txt}{p 15 30 0} You've adjusted for the following covariates: `covs' {p_end}"
		}
		}
ereturn scalar interdate = `interdate'

end

cap prog drop data_org_itp // Subroutine 1.3
prog data_org_itp
        
syntax, time(varname) depvar(varname) unit(varname) [covs(varlist)] treated(varname) times(numlist)

/*#########################################################

	* Section 1.3: Reorganizing the Data into Matrix Form

	We need a wide dataset to do what we want.
*########################################################*/
if `times' == 0 {
di as txt "{hline}"
di as txt "Second Step: Data Reorganizing"
di as txt "{hline}"
}
qui su `unit' if `treated' ==1, mean

loc treat_id = `r(mean)'

qui su `time' if `treated' ==1

keep `unit' `time' `depvar' `covs'
if `times' == 0 {
di "Reshaping..."
}
qui greshape wide `depvar' `covs', j(`unit') i(`time')


foreach v in `covs' {
	
	cap drop `v'`treat_id'

}
if `times' == 0 {
di as txt "Done!"
di as txt ""

di as inp "Estimating in-time placebos..."
}
qui: tsset `time'

order `depvar'`treat_id', a(`time')
//sa dataprocess, replace
//dataex
end

cap prog drop est_placebos_itp // Subroutine 2.1
prog est_placebos_itp
	
syntax, time(varname) h(numlist min=1 max=1 >=1 int) ///
interdate(numlist min=1 max=1 >=1 int) ///
treatunit(numlist min=1 max=1 >=1 int) ///
 lambda(string) [cv(string)] [scheme(string)] ///
 [transform(string)] [q(numlist min=0 max=1)] times(numlist)

qui: ds

loc temp: word 1 of `r(varlist)'

loc time: disp "`temp'"

loc t: word 2 of `r(varlist)'

loc treated_unit: disp "`t'"

loc a: word 3 of `r(varlist)'

loc donor_one: disp "`a'"

local nwords :  word count `r(varlist)'

loc b: word `nwords' of `r(varlist)'

loc last_donor: disp "`b'"

cap cvlasso `treated_unit' `donor_one'-`last_donor' if `time' < `interdate', `lambda' lglmnet roll h(`h') `cv' ///
alpha(`q') prest
	

cap drop cf_$treat_id
qui predict double cf_itp_`times', `lambda'

lab var cf_itp_`times' "SCUL $treat_lab, `interdate'"

lab var `treated_unit' "Real $treat_lab"

	if "`transform'" == "norm" {
			
	qui replace cf_itp_`times' = 1 if `time' ==`interdate'-1
	}


qui g relative_`times' = `time'- `interdate'

qui g diff_`times' = `treated_unit'- cf_itp_`times'

keep `treated_unit' `time' cf* relative* diff*

cap as `times' > 0
if !_rc {
	
	drop `treated_unit' rel*
}

qui compress
qui sa "sculitp_$treat_lab`times'", replace

macro drop outlab int_date
end





