* doiplot version 1.0 - 27 Oct 2021
* Authors: Chang Xu, Luis Furuya-Kanamori & Suhail A.R. Doi


program define doiplot, rclass
version 14

syntax varlist(min=2 max=2 numeric) [if] [in] [, dp fp gp df dg]

tokenize `varlist'

preserve

marksample touse, novarlist 
quietly keep if `touse'

*Check required packages
foreach package in metabias lfk {
capture which `package'
if _rc==111 ssc install `package'
}


*Data entry (error/warning messages)
if "`1'" != "" & "`2'" == "" {
	display as error "Must specify variables as ES seES"
	exit 198
}
*

*Data entry (error/warning messages)
if "`1'" == "" & "`2'" != "" {
	display as error "Must specify variables as ES seES"
	exit 198
}
*


if "`1'" == "" & "`2'" == "" {
	display as error "Must specify variables as ES seES"
	exit 198
}
*



*Theta SE_Theta input 
if "`1'" != "" & "`2'" != ""{
	
	
		quietly{
			gen __Effect = `1'
			gen __seEffect = `2'
			lfk __Effect __seEffect, nograph rsample
			}
}
*


*****Doi plot
	gen __z_abs = abs(_z)
	egen __max_se = max(__seEffect)
	egen __max_z= max(__z_abs)
	sort __z_abs 
	gen __es_z_min = __Effect[1] 
	local es_z_min_1 = __es_z_min[1]
	sort _z


**Egger's test
    qui metabias __Effect __seEffect, egger
    qui gen __egger_bias = _b[bias]
    qui gen __egger_se=_se[bias]
    qui gen double __z_eg = round(__egger_bias/__egger_se, 0.01)
    qui gen __egger_test = r(p_bias)
	local egger_test = round(__egger_test[1], 0.001)
	local egger_coef = round(__egger_bias[1], 0.001)

  


*****Galbraith	
	qui gen __stand_es = __Effect/__seEffect
	qui gen __pre = 1/__seEffect
	qui reg __stand_es __pre, noconstant
	qui predict _phat
	qui predict _se_stand_es, stdf
	quietly gen _pll = _phat - 2 
    quietly gen _pul = _phat + 2 
	
	qui sum _pll, detail
    if r(min)>=-2 {
       local mny=-2
    } 
    else {
       local mny=r(min)
    }
    qui sum _pul, detail
    if r(max)<=2 {
       local mxy=2
    } 
    else {
       local mxy=r(max)
    }
    local new=_N+1
    qui set obs `new'
    qui replace __stand_es=0 in l
    qui replace __pre=0 in l
    qui replace _phat=0 in l
    qui replace _pll=-2 in l
    qui replace _pul=2 in l 
    
	


***CI of funnel plot (pooled ES and se_ES)
    qui gen rank3=_n if __Effect != .
	qui egen __k= max(rank3)
    qui gen __vvar = __seEffect^2
    qui gen __w  = 1/__vvar
    qui egen __sw  = sum(__w) 
    qui gen  __wl = __w/__sw * __Effect
    qui egen __ES_pooled = sum(__wl) 
	qui gen _se_pooled = 1/__sw
	
    sort rank3
    
    local rxl=__ES_pooled[1]
	
	qui gen __lci = `rxl' - 1.96*__seEffect
	qui gen __uci = `rxl' + 1.96*__seEffect

	
*LFK as string + output
	quietly tostring _lfk, gen(__lfk_str) force
	quietly gen ___lfk_str1 = substr(__lfk_str,1, strpos(__lfk_str,".")+2)
	local lfk_str1 = ___lfk_str1[1]



*Plot entry (error/warning messages)
qui gen _count = 0
qui replace _count=_count + 1 if "`dp'" == "dp"
qui replace _count=_count + 1 if "`fp'" == "fp"
qui replace _count=_count + 1 if "`gp'" == "gp"
qui replace _count=_count + 1 if "`df'" == "df"
qui replace _count=_count + 1 if "`dg'" == "dg"
local _count_1 = _count[1]


if `_count_1' > 1 {
	
	display as text "Two or more graph options assigned - please correct to only one"
	exit 198	
}
*

	
	
		
*Default Doi-Galbraith plot 
if "`dp'" == "" & "`fp'" == "" & "`gp'" == "" & "`df'" == "" & "`dg'" == ""{
	
	local es_z_min_1 = __es_z_min[1]
	local lfk_1 = round(_lfk[1],0.01)
	local max_se = __max_se[1]
	local max_z = __max_z[1]
	local _k = __k[1]
	
	twoway (scatter __stand_es __pre if (__stand_es !=0 & __pre !=0), msymbol(circle) mcolor(black)  yaxis(2) xaxis(2) msize(medlarge)) (scatter __stand_es __pre if (__stand_es ==0 & __pre ==0), msymbol(circle) mcolor(white)  yaxis(2) xaxis(2)) (line _pll __pre, lcolor(black) lpattern(solid) yaxis(2) xaxis(2)) (line _pul __pre, lcolor(black) lpattern(solid) yaxis(2) xaxis(2))(connected __z_abs __Effect, yaxis(1) ysc(rev axis(1)) xaxis(1) xline(`es_z_min_1', lcolor(black) noextend) mcolor(black) msize(vlarge) msymbol(circle) mlwidth(medthick) mfcolor(white) lcolor(black) lpattern(shortdash)) , ytitle(| Z-score |, axis(1) size(large)) ytitle(Standardized estimate, axis(2) size(large)) xtitle(Effect size, axis(1) size(large)) xtitle(Precision, axis(2) size(large)) aspectratio(1.2) graphregion(fcolor(white)) plotregion(fcolor(white)) note(LFK index = `lfk_str1', margin(small)) leg(off)  ylabel(, labsize(large) angle(horizontal) labgap(half_tiny) nogrid)  ylabel(, labgap(half_tiny) labsize(large) angle(horizontal) axis(2)) xlabel(, labsize(large) angle(horizontal) labgap(half_tiny) nogrid)  xlabel(, labsize(large) labgap(half_tiny) angle(horizontal) axis(2))

	di as text "{hline 59}"
	display as text "Data input format ES seES assumed"
	display as text "Doi-Galbraith plot was selected" 
	display as text "Number of studies = " as result `_k'
	di as text "{hline 59}"	
}
*

*Doi plot 
if "`dp'" == "dp" & "`fp'" == "" & "`gp'" == "" & "`df'" == "" & "`dg'" == ""{
	local es_z_min_1 = __es_z_min[1]
	local lfk_1 = round(_lfk[1],0.01)
	local _k = __k[1]
	
		twoway (connected __z_abs __Effect, yaxis(1) ysc(rev) xline(`es_z_min_1', lcolor(black) noextend) mcolor(black) msize(vlarge) msymbol(circle) mlwidth(medthick) mfcolor(white) lcolor(black) lpattern(shortdash)) , ytitle(| Z-score |) ytitle(, size(large)) ylabel(, labsize(large) angle(horizontal) labgap(half_tiny) nogrid) xtitle(Effect Size) xtitle(, size(large)) xlabel(, labsize(large) labgap(half_tiny)) aspectratio(1.3) graphregion(fcolor(white)) note(LFK index = `lfk_str1' , margin(medium)) leg(off)  

	di as text "{hline 59}"	
	display as text "Data input format ES seES assumed"
	display as text "Doi plot was selected" 
	display as text "Number of studies = " as result `_k'
	di as text "{hline 59}"			
		
}
*


*Funnel plot 
if "`dp'" == "" & "`fp'" == "fp" & "`gp'" == "" & "`df'" == "" & "`dg'" == ""{
	local _k = __k[1]
	
		twoway (scatter __seEffect __Effect, ysc(rev) msize(medlarge) mcolor(black))(line __seEffect __lci , lcolor(black) lpattern(dash)) (line __seEffect __uci , lcolor(black) lpattern(dash)), ytitle(Standard error) ytitle(, size(large)) ylabel(, labsize(large) angle(horizontal) labgap(small) nogrid) xtitle(Effect Size) xtitle(, size(large)) xlabel(, labsize(large) labgap(half_tiny)) graphregion(fcolor(white)) note(Egger's test (p_value) = `egger_test', margin(medium)) leg(off) ylabel(, labsize(large) angle(horizontal) labgap(half_tiny) nogrid) aspectratio(1)

	di as text "{hline 59}"	
	display as text "Data input format ES seES assumed"
	display as text "Funnel plot was selected" 
	display as text "Number of studies = " as result `_k'
	di as text "{hline 59}"			
}
*


*Galbraith plot
if "`dp'" == "" & "`fp'" == "" & "`gp'" == "gp" & "`df'" == "" & "`dg'" == ""{
	local _k = __k[1]
	
	sort __pre
	
	twoway (line _phat __pre, lcolor(black) lw(medthin)) (scatter __stand_es __pre if (__stand_es !=0 & __pre !=0), msymbol(circle) mcolor(black) msize(medlarge)) (scatter __stand_es __pre if (__stand_es ==0 & __pre ==0), msymbol(circle) mcolor(white) msize(medlarge)) (line _pll __pre, lcolor(black) lw(medthin) lpattern(longdash)) (line _pul __pre, lcolor(black) lw(medthin) lpattern(longdash)), ytitle(Standardized estimate, axis(1) size(large))  xtitle(Precision) xtitle(, size(large)) xlabel(, labsize(large) labgap(half_tiny)) graphregion(fcolor(white)) plotregion(fcolor(white)) leg(off) ylabel(, labsize(large) angle(horizontal) labgap(half_tiny) nogrid) aspectratio(0.4)
	      

	
	di as text "{hline 59}"	
	display as text "Data input format ES seES assumed"
	display as text "Galbraith plot was selected" 
	display as text "Number of studies = " as result `_k'
	di as text "{hline 59}"	
}
*


*Doi-funnel plot

if "`dp'" == "" & "`fp'" == "" & "`gp'" == "" & "`df'" == "df" & "`dg'" == ""{
	local es_z_min_1 = __es_z_min[1]
	local lfk_1 = round(_lfk[1],0.01)
	local max_se = __max_se[1]
	local max_z = __max_z[1]
	local _k = __k[1]
	
	
	twoway (scatter __seEffect __Effect, yaxis(2) ysc(rev axis(2)) msize(medlarge) mcolor(black))  (connected __z_abs __Effect, yaxis(1) ysc(rev axis(1)) xline(`es_z_min_1', lcolor(black) noextend) mcolor(black) msize(vlarge) msymbol(circle) mlwidth(medthick) mfcolor(white) lcolor(black) lpattern(shortdash)) , ytitle(| Z-score |, axis(1) size(large)) ytitle(Standard error, axis(2) size(large))  ylabel(, labsize(medlarge)) xtitle(Effect Size) xtitle(, size(medlarge)) xlabel(, labsize(medlarge)) aspectratio(1.3) graphregion(fcolor(white)) note(LFK index = `lfk_str1'; Egger's test (p_value) = `egger_test', margin(small)) plotregion(fcolor(white)) leg(off) ylabel(, labsize(large) angle(horizontal) labgap(half_tiny) nogrid)  ylabel(, labgap(half_tiny) labsize(large) angle(horizontal) axis(2)) xlabel(, labsize(large) angle(horizontal) labgap(half_tiny) nogrid)  

		
   	di as text "{hline 59}"	
	display as text "Data input format ES seES assumed"
	display as text "Doi-funnel plot was selected" 
	display as text "Number of studies = " as result `_k'
	di as text "{hline 59}"		
}
*



*Doi-Galbraith plot 
if "`dp'" == "" & "`fp'" == "" & "`gp'" == "" & "`df'" == "" & "`dg'" == "dg"{
	local es_z_min_1 = __es_z_min[1]
	local lfk_1 = round(_lfk[1],0.01)
	local max_se = __max_se[1]
	local max_z = __max_z[1]
	local _k = __k[1]
	
	twoway (scatter __stand_es __pre if (__stand_es !=0 & __pre !=0), msymbol(circle) mcolor(black)  yaxis(2) xaxis(2) msize(medlarge)) (scatter __stand_es __pre if (__stand_es ==0 & __pre ==0), msymbol(circle) mcolor(white)  yaxis(2) xaxis(2)) (line _pll __pre, lcolor(black) lpattern(solid) yaxis(2) xaxis(2)) (line _pul __pre, lcolor(black) lpattern(solid) yaxis(2) xaxis(2)) (connected __z_abs __Effect, yaxis(1) ysc(rev axis(1)) xaxis(1) xline(`es_z_min_1', lcolor(black) noextend) mcolor(black) msize(vlarge) msymbol(circle) mlwidth(medthick) mfcolor(white) lcolor(black) lpattern(shortdash)) , ytitle(| Z-score |, axis(1) size(large)) ytitle(Standardized estimate, axis(2) size(large)) xtitle(Effect size, axis(1) size(large)) xtitle(Precision, axis(2) size(large)) aspectratio(1.3) graphregion(fcolor(white)) plotregion(fcolor(white)) note(LFK index = `lfk_str1', margin(small)) leg(off)  ylabel(, labsize(large) angle(horizontal) labgap(half_tiny) nogrid)  ylabel(, labgap(half_tiny) labsize(large) angle(horizontal) axis(2)) xlabel(, labsize(large) angle(horizontal) labgap(half_tiny) nogrid)  xlabel(, labsize(large) labgap(half_tiny) angle(horizontal) axis(2))

	di as text "{hline 59}"	
	display as text "Data input format ES seES assumed"
	display as text "Doi-Galbraith plot was selected" 
	display as text "Number of studies = " as result `_k'
	di as text "{hline 59}"	
}
*


restore 
end
exit

