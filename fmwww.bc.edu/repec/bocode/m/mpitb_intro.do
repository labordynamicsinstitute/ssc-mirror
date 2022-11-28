/* Notes: 
	
	(1)	this script provides the code underlying the examples of the paper 
	"mpitb - mpitb: A toolbox for multidimensional poverty indices"
	
	(2) this script assumes the working directory to be the folder "mpitb_intro", 
	provided by the package. You may have to 
	
	cd mpitb_intro 
	
	(3) this scripts creates a folder "results" and several files within 
	that folder. If run repeatedly, please delete this folder previously.
	
	loc flist : dir "results/" files "*.dta"
	foreach f in `flist' {
		rm results/`f' 
	}
	rmdir results

	*/ 

cap log close 
log using mpitb_intro.txt , replace t nomsg

version 17 
frame reset 

*****************************************************
**# Example 1: A single year for a single country ***
*****************************************************

use syn_cdta.dta if t == 1 , clear 
sum 

svyset psu [pw=weight], strata(stratum)

mpitb set , na(trial01) d1(d_cm d_nutr, na(hl)) d2(d_satt d_educ, na(ed)) ///
	d3(d_elct d_wtr d_sani d_hsg d_ckfl d_asst, name(ls)) de(pref. spec)

mpitb est , name(trial01) meas(all) indmeas(all) aux(hd) klist(20 33 50) /// 
	weight(equal) svy lfr(myresults, replace) over(region area) 

cwf myresults 
d 

tab measure loa  

li measure b se if inlist(measure,"M0","H","A") & loa == "nat" & k == 33 , noob

recode subg (0=0 "rural") (1=1 "urban") if loa == "area" , gen(area)
lab var area area

tabdisp indicator measure area if inlist(measure,"hd","hdk") /// 
	& !mi(area) & inlist(k,33,.) , cell(b)

***************************************************
**# Example 2: Avoiding unnecessary estimations ***
***************************************************

mkdir results

use syn_cdta.dta if t == 1 , clear 

svyset psu [pw=weight], strata(stratum)

mpitb set , name(trial01) desc(preferred spec) ///
		d1(d_cm d_nutr, name(hl)) /// 
		d2(d_satt d_educ, name(ed)) /// 
		d3(d_elct d_wtr d_sani d_hsg d_ckfl d_asst, name(ls))

mpitb est , name(trial01) measures(all) indmeas(all) aux(hd) svy /// 
	k(1 10 20 33 40 (10) 100) over(region area, k(20 33 50) indk(30)) ///
	indk(20 33 40) weight(equal) lsa(results/trial01, replace) 

describe using results/trial01 , s

**********************************************************************
**# Example 3: Adding alternative weights and indicator selections ***
**********************************************************************

mpitb est , n(trial01) m(all) k(33) w(dimw(.5 .25 .25) name(health50)) /// 
	lsa(results/health50, replace) svy

mpitb est , n(trial01) m(all) k(33) w(dimw(.25 .5 .25) name(educ50)) /// 
	lsa(results/educ50, replace) svy

mpitb est , n(trial01) m(all) k(33) w(dimw(.25 .25 .5) name(livst50)) /// 
	lsa(results/livstd50, replace) svy

mpitb est , n(trial01) m(all) k(33) lsa(results/ind_equal, replace) ///
	w(indw(.1 .1 .1 .1 .1 .1 .1 .1 .1 .1) name(ind_equal)) svy 

mpitb set , n(trial02) d1(d_cm d_nutr, n(hl)) d2(d_satt d_educ, n(ed)) /// 
	d3(d_wtr d_sani d_hsg d_ckfl d_asst, name(ls)) desc(w/o electricity)

mpitb est , n(trial02) m(all) k(33) w(equal) svy /// 
	lsa(results/trial02, replace) 
	

save results/results  , replace emptyok
loc flist trial01 trial02 health50 educ50 livstd50 ind_equal 
foreach f in `flist' {
	append using results/`f' , nol 
}
save results/results , replace

*****************************************************
**# Example 4: Several years for a single country ***
*****************************************************

use syn_cdta.dta , clear 
svyset psu [pw=weight], strata(stratum)
mpitb set , name(trial01) desc(preferred spec) ///
		d1(d_cm d_nutr, name(hl)) /// 
		d2(d_satt d_educ, name(ed)) /// 
		d3(d_elct d_wtr d_sani d_hsg d_ckfl d_asst, name(ls))

mpitb est , name(trial01) measures(all) klist(1 33 50) weight(equal) /// 
	lframe(myresults, replace) svy over(region) /// 
	cotmeasures(M0 H A) cotframe(mycot, replace) tvar(t) cotyear(year)

frame myresults : sort t k
frame myresults : li measure wgts t k b se if measure == "H" & loa == "nat" ///
	, noobs sepby(t)

frame mycot : li measure wgts ann t0 t1 k ctype b se if measure == "H" /// 
	& loa == "nat" & ann == 0 , noobs sepby(k)

******************************************************
**# Example 5: A single year for several countries ***
******************************************************

dir cdta , wide	
	
mpitb refsh using results/refsh.dta, clear id(ccty) sid(region) p(cdta) ///
	char(ccty ccnum survey year cty) 

li ccty region region_name survey year fname in 1/5, noob sepby(ccty)

mkf rs
frame rs: use results/refsh.dta , clear 

frame rs: mpitb ctyselect ccty 
foreach cty in `r(ctylist)' {
	frame rs : qui levelsof fname if ccty == "`cty'" , loc(fname) clean
	use `"cdta/`fname'"' , clear 	
	svyset psu [pw=weight] , strata(stratum) singleunit(centered)	

	mpitb set , n(mympi) d1(d_cm d_nutr, n(hl)) /// 
		d2(d_satt d_educ, n(ed)) /// 
		d3(d_elct d_wtr d_sani d_hsg d_ckfl d_asst, name(ls))

	mpitb est , name(mympi) measures(all) klist(33) weight(equal) /// 
		lsa(results/`cty'_results, replace) over(region) /// 
		svy addmeta(ccty=`cty')
} 

clear 
save results/results , replace emptyok
loc flist : dir "results/" files "*_results.dta"
foreach f in `flist' {
	append using results/`f' , nol 
}

gen region = subg if loa == "region"
frlink m:1 ccty region , frame(rs) 
frget region_name , from(rs) 
save results/results.dta , replace

tabdisp ccty measure if loa == "nat" & inlist(k,33,.), cell(b)

tabdisp region_name measure if loa == "region" & inlist(k,33,.) & ccty == "ABC" , c(b) l 

log close 

exit


