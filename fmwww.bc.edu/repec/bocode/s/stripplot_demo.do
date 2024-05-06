//  (Stata's auto data)
. sysuse auto, clear
. stripplot mpg, name(ST1, replace) 
. stripplot mpg, aspect(0.05) name(ST2, replace)
. stripplot mpg, over(rep78) name(ST3, replace)
. stripplot mpg, over(rep78) by(foreign, note("")) name(ST4, replace)
. stripplot mpg, over(rep78) vertical yla(, ang(h)) name(ST5, replace)
. stripplot mpg, over(rep78) vertical stack yla(, ang(h)) name(ST6, replace)
. stripplot mpg, over(rep78) vertical stack yla(, ang(h)) h(0.4) name(ST7, replace)

. gen pipe = "|"
. stripplot mpg, ms(none) mlabpos(0) mlabel(pipe) mlabsize(*2) stack name(ST8, replace)
. stripplot price, over(rep78) ms(none) mla(pipe) mlabpos(0) name(ST9, replace)
. stripplot price, over(rep78) w(200) stack h(0.4) name(ST10, replace)

// (10 here is empirical: adjust for your variable)
. gen price1 = price - 10
. gen price2 = price + 10 
. stripplot price, over(rep78) box ms(none) addplot(rbar price1 price2 rep78, horizontal barw(0.2) bcolor(navy)) name(ST11, replace)

. stripplot mpg, over(rep78) stack h(0.5) bar(lcolor(red)) name(ST12, replace)
. stripplot mpg, over(rep78) box name(ST13, replace)
. stripplot mpg, over(rep78) box boffset(-0.3) name(ST14, replace)
. stripplot mpg, over(rep78) box(bfcolor(eltgreen)) boffset(-0.3) name(ST15, replace)
. stripplot mpg, over(rep78) box(bfcolor(eltgreen) barw(0.2)) boffset(-0.2) stack h(0.5) name(ST16, replace)
. stripplot mpg, over(rep78) box(bfcolor(black) blcolor(white) barw(0.2)) boffset(-0.2) stack h(0.5) name(ST17, replace)
. stripplot mpg, over(rep78) box(bfcolor(black) blcolor(white) barw(0.2)) iqr boffset(-0.2) stack h(0.5) name(ST18, replace)
. stripplot mpg, over(rep78) box(bfcolor(black) blcolor(white) barw(0.2)) pctile(10) whiskers(recast(rbar) bcolor(black) barw(0.02)) boffset(-0.2) stack h(0.5) name(ST19, replace)

. gen digit = mod(mpg, 10)
. stripplot mpg, stack vertical mla(digit) mlabpos(0) ms(i) over(foreign) height(0.2) yla(, ang(h)) xla(, ang(-0.001) tlength(*2) tlcolor(none)) name(ST20, replace)
. stripplot mpg, stack vertical mla(digit) mlabpos(0) ms(i) by(foreign, note("")) yla(, ang(h)) name(ST21, replace)

. stripplot mpg, over(rep78) separate(foreign) stack name(ST22, replace)
. stripplot mpg, by(rep78) separate(foreign) stack name(ST23, replace)

// (fulcrums to mark means as centres of gravity)
. gen rep78_1 = rep78 - 0.1
. egen mean = mean(mpg), by(foreign rep78)
. stripplot mpg, over(rep78) by(foreign, compact note("")) addplot(scatter rep78_1 mean, ms(T)) stack name(ST24, replace)

. egen mean_2 = mean(mpg), by(rep78)
. gen rep78_L = rep78 - 0.1
. gen rep78_U = rep78 - 0.02
. stripplot mpg, over(rep78) stack addplot(pcarrow rep78_L mean_2 rep78_U mean_2, msize(medlarge) barbsize(medlarge)) yla(, grid) name(ST25, replace)

. clonevar rep78_2 = rep78
. replace rep78_2 = cond(foreign, rep78 + 0.15, rep78 - 0.15)
. stripplot mpg, over(rep78_2) separate(foreign) yla(1/5) jitter(1 1) name(ST26, replace)

. logit foreign mpg
. predict pre
. stripplot mpg, over(foreign) stack ms(sh) height(0.15) addplot(mspline pre mpg, bands(20)) name(ST27, replace)

// (reference lines where by() would seem natural)
// (labmask (Cox 2008) would be another solution for label fix)
. egen group = group(foreign rep78)
. replace group = cond(group <= 5, group, group + 1)
. label def group 7 "3" 8 "4" 9 "5", modify
. lab val group group
. stripplot mpg, over(group) vertical cumul cumprob refline box centre mcolor(blue) xmla(3 "Domestic" 8 "Foreign", tlength(*7) tlc(none) labsize(medium)) yla(, ang(h)) xtitle("") xli(6, lc(gs12) lw(vthin)) name(ST28, replace)

. sysuse auto, clear
. egen median = median(mpg), by(foreign)
. egen loq = pctile(mpg), by(foreign) p(25)
. egen upq = pctile(mpg) , by(foreign) p(75)
. egen mean = mean(mpg), by(foreign)
. egen min = min(mpg)
. egen n = count(mpg), by(foreign)
. gen shown = "{it:n} = " + string(n)
. gen foreign2 = foreign + 0.15
. gen foreign3 = foreign - 0.15
. gen showmean = string(mean, "%2.1f")
. stripplot mpg, over(foreign) box(barw(0.2)) centre cumul cumprob vertical height(0.4) addplot(scatter median loq upq foreign2, ms(none ..) mla(median loq upq) mlabc(blue ..) mlabsize(*1.2 ..) || scatter mean foreign3, ms(none) mla(showmean) mlabc(orange) mlabsize(*1.2) mlabpos(9) || scatter min foreign, ms(none) mla(shown) mlabc(black) mlabsize(*1.2) mlabpos(6)) xsc(r(. 1.2)) yla(, ang(h)) xla(, noticks) name(ST29, replace)

// (Stata's blood pressure data)
. sysuse bplong, clear
. egen group = group(age sex), label
. stripplot bp*, bar over(when) by(group, compact col(1) note("")) ysc(reverse) subtitle(, pos(9) ring(1) nobexpand bcolor(none) placement(e)) ytitle("") xtitle(Systolic blood pressure (mm Hg)) name(ST30, replace)

// (Stata's US city temperature data)
. sysuse citytemp, clear
. label var tempjan "Mean January temperature ({&degree}F)"
. stripplot tempjan, over(region) cumul vertical yla(14 32 50 68 86, ang(h)) xla(, noticks) refline centre name(ST31, replace)
. stripplot tempjan, over(region) cumul vertical yla(14 32 50 68 86, ang(h) grid) xla(, noticks) refline(lc(red) lw(medium)) centre name(ST32, replace)

. gen id = _n
. reshape long temp, i(id) j(month) string
. replace month = cond(month == "jan", "January", "July")
. label var temp "Mean temperature ({&degree}F)"
. stripplot temp, over(region) by(month, note("")) cumul vertical yla(14 32 50 68 86, ang(h)) bar centre name(ST33, replace)
. stripplot temp, over(region) by(month, note("")) cumul cumpr vertical yla(14 32 50 68 86, ang(h)) box(barw(0.5) blcolor(gs12)) height(0.4) centre name(ST34, replace)
. stripplot temp, over(region) by(month, note("") subtitle(normal quantile plots with means)) cumul cumpr trscale(invnormal(@)) centre vertical yla(14 32 50 68 86, ang(h))  refline name(ST35, replace)

. gen tempC = (5/9) * temp - 32
. label var tempC "Mean temperature ({&degree}C)"
. stripplot tempC, over(division) by(month, xrescale note("whiskers to 5 and 95% points")) xla(, ang(h)) box pctile(5) outside(ms(oh) mcolor(red)) ms(none) name(ST36, replace)

// (Tufte, quartile or midgap plots)
. sysuse auto, clear
. stripplot mpg , over(foreign) stack tufte boffset(-0.07) yla(, ang(h)) xla(, noticks) vertical ms(Sh) height(0.2) name(ST37, replace)
 
