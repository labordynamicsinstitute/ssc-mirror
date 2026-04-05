// (Stata's auto data)
sysuse auto, clear
strip mpg, name(STRIP1, replace)
strip mpg, aspect(0.05) name(STRIP2, replace)
strip mpg, over(rep78) name(STRIP3, replace)
strip mpg, over(rep78) by(foreign, note("")) name(STRIP4, replace)
strip mpg, over(rep78) vertical yla(, ang(h)) name(STRIP5, replace)
strip mpg, over(rep78) vertical stack yla(, ang(h)) name(STRIP6, replace)
strip mpg, over(rep78) vertical stack yla(, ang(h)) height(0.4) name(STRIP7, replace)

gen pipe = "|"
strip mpg, ms(none) mlabpos(0) mlabel(pipe) mlabsize(*2) stack name(STRIP8, replace) 
label var price "Price (USD)"
strip price, over(rep78) xla(3000(3000)15000) ms(none) mla(pipe) mlabpos(0) name(STRIP9, replace)
strip price, over(rep78) xla(3000(3000)15000) width(200) stack height(0.4) name(STRIP10, replace)

// (5 here is empirical: adjust for your variable)
gen price1 = price - 5
gen price2 = price + 5
strip price, over(rep78) xla(3000(3000)15000) ms(none) addplot(rbar price1 price2 rep78, horizontal barw(0.2) bcolor(gs6)) name(STRIP11, replace)

gen digit = mod(mpg, 10)
strip mpg, stack vertical mla(digit) mlabpos(0) ms(i) over(foreign) height(0.2) yla(, ang(h)) xla(, ang(-0.001) tlength(*2) tlcolor(none)) subtitle(stem-and-leaf plot) name(STRIP12, replace)
strip mpg, stack vertical mla(digit) mlabpos(0) ms(i) by(foreign, note("") subtitle(stem-and-leaf plot)) yla(, ang(h)) name(STRIP13, replace)

strip mpg, over(rep78) separate(foreign) stack name(STRIP14, replace)
strip mpg, by(rep78) separate(foreign) stack name(STRIP15, replace)

// (fulcrums to mark means as centres of gravity)
gen rep78_1 = rep78 - 0.1
egen mean = mean(mpg), by(foreign rep78)
strip mpg, over(rep78) by(foreign, compact note("")) yla(, glp(solid)) addplot(scatter rep78_1 mean, ms(T)) stack name(STRIP16, replace)

egen mean_2 = mean(mpg), by(rep78)
gen rep78_L = rep78 - 0.1
gen rep78_U = rep78 - 0.02
strip mpg, over(rep78) stack addplot(pcarrow rep78_L mean_2 rep78_U mean_2, msize(medlarge) barbsize(medlarge)) yla(, grid glp(solid)) name(STRIP17, replace)

clonevar rep78_2 = rep78
replace rep78_2 = cond(foreign, rep78 + 0.15, rep78 - 0.15)
strip mpg, over(rep78_2) separate(foreign) yla(1/5) jitter(1 1) name(STRIP18, replace)

logit foreign mpg
predict pre
strip mpg, over(foreign) stack ms(sh) height(0.15) subtitle(logit model) addplot(mspline pre mpg, bands(20)) name(STRIP19, replace)

// (reference lines where by() would seem natural)
// (labmask (Cox 2008) would be another solution for label fix)
egen group = group(foreign rep78)
replace group = cond(group <= 5, group, group + 1)
label def group 7 "3" 8 "4" 9 "5", modify
lab val group group
strip mpg, over(group) vertical quantile centre mcolor(blue) xmla(3 "Domestic" 8 "Foreign", tlength(*7) tlc(none) labsize(medium)) yla(, ang(h)) xtitle("") xli(6, lc(gs12) lw(vthin)) name(STRIP20, replace)

sysuse auto, clear 
egen median = median(mpg), by(foreign)
egen loq = pctile(mpg), by(foreign) p(25)
egen upq = pctile(mpg) , by(foreign) p(75)
egen mean = mean(mpg), by(foreign)
egen min = min(mpg)
egen n = count(mpg), by(foreign)
gen shown = "{it:n = }" + string(n)
gen foreign2 = foreign + 0.15
gen foreign3 = foreign - 0.15
gen showmean = string(mean, "%2.1f")
local box scatter median loq upq foreign2, ms(none ..) mla(median loq upq) mlabc(blue ..) mlabsize(*1.2 ..)
local mean scatter mean foreign3, ms(none) mla(showmean) mlabc(orange) mlabsize(*1.2) mlabpos(9)
local min scatter min foreign, ms(none) mla(shown) mlabc(black) mlabsize(*1.2) mlabpos(6)
strip mpg, over(foreign) centre quantile vertical height(0.4) addplot(`box' || `mean' || `min') xsc(r(. 1.2)) yla(, ang(h)) xla(, noticks) name(STRIP21, replace) note("mean on left, median and quartiles on right")

// (Stata's blood pressure data)
sysuse bplong, clear
egen group = group(age sex), label
strip bp*, over(when) by(group, compact col(1) note("") subtitle(Systolic blood pressure (mm Hg))) ysc(reverse) subtitle(, pos(9) ring(1) nobexpand bcolor(none) placement(e)) ytitle("") xtitle("")  xsc(alt) name(STRIP22, replace)

// (Stata's US city temperature data)
sysuse citytemp, clear
label var tempjan "Mean January temperature ({&degree}F)"
strip tempjan, over(region) subtitle(quantile plots) quantile vertical yla(14 32 50 68 86, ang(h)) xla(, noticks) centre name(STRIP23, replace)

gen id = _n
reshape long temp, i(id) j(month) string
replace month = cond(month == "jan", "January", "July")
label var temp "Mean temperature ({&degree}F)"
strip temp, over(region) by(month, note("") subtitle(quantile plots)) quantile vertical yla(14 32 50 68 86, ang(h)) centre name(STRIP24, replace)
strip temp, over(region) by(month, note("") subtitle(normal quantile plots)) quantile trscale(invnormal(@)) centre vertical yla(14 32 50 68 86, ang(h)) name(STRIP25, replace)

egen mean = mean(temp), by(region month)
gen regionL = region - 0.4
gen regionR = region + 0.4
strip temp, over(region) by(month, note("") subtitle(normal quantile plots with means)) quantile trscale(invnormal(@)) centre vertical yla(14 32 50 68 86, ang(h)) addplot(rspike  regionL regionR mean, horizontal) name(STRIP26, replace)

* The following examples use datasets from Whitlock and Schluter (2020) and require 
* (1) internet access to download the data; 
* (2) previous installation of -pctilesets-; 
* (3) Stata 18 up to allow use of stc2 (but just change the local macro otherwise).

import delimited using https://whitlockschluter3e.zoology.ubc.ca/Data/chapter02/chap02e3bHumanHemoglobinElevation.csv, clear
label var hemoglobin "Hemoglobin concentration (g dl{sup:-1})"
egen mean = mean(hemoglobin), by(population)
egen n = count(hemoglobin), by(population)
gen shown = "{it:n}  = " + strofreal(n)
gen where = 9
encode population, gen(x)
gen xL = x - 0.4
gen xR = x + 0.4
strip hemoglobin, over(population) vertical quantile centre trscale(invnormal(@)) xla(, tlength(0)) xtitle("") addplot(scatter where x, ms(none) mla(shown) mlabpos(0) mlabsize(medium) || rspike xL xR mean, horizontal lc(black)) subtitle(normal quantile plots with added means) name(STRIP27, replace) 

import delimited using https://whitlockschluter3e.zoology.ubc.ca/Data/chapter12/chap12q17StalkieEyespan.csv, clear
gen diet = food + " diet"
label var eyespan "Eye span (mm)"
save eyespan, replace 
pctilesets eyespan, over(diet) pctile(25 50 75) min max saving(eyespan_pctiles, replace)
clonevar origgvar=diet 
merge m:1 origgvar using eyespan_pctiles 
gen xbox = cond(food == "Corn", 0.9, 1.9)
local color stc2 
strip eyespan , over(diet) quantile vertical height(0.25) xla(, tlcolor(none)) addplot(rbar p25 p75 xbox, barwidth(0.16) lcolor(`color') fcolor(none) || scatter p50 xbox, ms(Dh) mcolor(`color') msize(medium) || rspike p75 max xbox, lcolor(`color') || rspike p25 min xbox, lcolor(`color')) yla(1 1.2 1.4 1.6 1.8 2 2.2) aspect(1.2) xtitle("") name(STRIP28, replace)

import delimited using https://whitlockschluter3e.zoology.ubc.ca/Data/chapter13/chap13e1MarineReserve.csv, clear 
label var biomassratio "Biomass rato"
means biomassratio
scalar gmean = r(mean_g)
su biomassratio
strip biomassratio, vertical quantile ysc(log) yli(`=gmean', lp(solid)) aspect(1) text(`=gmean + 0.1' 1.1 "geometric mean") yla(`r(min)' 1/4 `r(max)') name(STRIP29, replace)

import delimited using https://whitlockschluter3e.zoology.ubc.ca/Data/chapter15/chap15q09HippocampalVolumeRatio.csv, clear
encode group, gen(GROUP)
label define GROUP 1 "febrile" 2 "non-febrile" 3 none, modify
label var GROUP "Childhood seizures"
label var hippovolumeratio "Hippocampal volume ratio (%)"
egen median = median(hippovolumeratio), by(group)
gen GROUPL = GROUP - 0.4
gen GROUPR = GROUP + 0.4
su hippovolumeratio
gen where = r(min) - 5
egen count = count(hippovolumeratio), by(GROUP)
gen shown = "{it:n} = " + strofreal(count)
strip hippovolumeratio , over(GROUP) vertical quantile center xla(, tlc(none)) ms(O ..) addplot(rspike GROUPL GROUPR median, horizontal || scatter where GROUP, ms(none) mla(shown) mlabsize(medium) mlabpos(0) mlabcolor(black)) yla(47 50(10)100) note(horizontal lines show medians, pos(11)) name(STRIP30, replace)

