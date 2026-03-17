/*==============================================================================
For your verification convenience, I have conducted a complete standard parallel-trends test and an equivalent test using the lsaplot command with the same code and data. The results confirm that lsaplot yields identical estimation outcomes to the full manual parallel-trends test, while significantly simplifying the code.
————————————————————————————————————————————————————————————————————————————————	
net install lsaplot, from(https://raw.githubusercontent.com/hurilen/lsaplot/main/) replace
net install lsaplot, from(https://gitee.com/lilinze626/lsaplot/raw/main/) replace
==============================================================================*/
/*==============================================================================
Standard Event Study Method
==============================================================================*/
use "lsaplot_data.dta" ,clear
graph set window fontface "Times New Roman"
gen policy = year - 2018
tab policy
forvalues i = 5(-1)1{
gen pre_`i' = (policy == -`i' & treat == 1)
}
forvalues i = 0(1)3{
gen post_`i' = (policy == `i' & treat == 1)
}
replace pre_1 = 0
*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
reghdfe lnemp pre_*  post_* Size ROA ATO Cashflow FIXED Growth Top1 SOE,absorb(stkcd year#city_num) cl(id)

capt which coefplot
if _rc != 0 {
	ssc inst coefplot
}

coefplot , baselevels omitted ///                
   keep( pre_*  post_* )  ///
   coeflabels( pre_5 = -5 pre_4 = -4 pre_3 = -3     ///
    pre_2 = -2  ///
	pre_1 = -1 ///
	post_0 = 0 ///
      post_1 = 1 post_2 = 2 post_3 = 3 )       ///
   vertical                             ///
   recast(connected) ///
      lcolor(black%50) lwidth(medium) lpattern(dash) ///
   yline(0, lcolor(black))             ///
   xline(5, lpattern(dash) lcolor(red%50))            ///显示基期
   ytitle(`"{fontface "宋体":动态处理效应}"',size(medium)) ///
   ylabel(,angle(horizontal) labsize(medium) grid) ///
   xtitle(`"{fontface "宋体":距政策发生的时间}"',size(medium)) ///
   xlabel(,labsize(medium) ) ///          
   ciopts(lpattern(dash) recast(rcap) msize(medium) lcolor(navy)) ///
   mcolor(navy)                        ///
   scheme(s1mono)       ///
   levels(95)                          ///
   graphregion(color(white))           ///
   plotregion(lcolor(white) style(none)) ///
   title(`"{fontface "宋体":平行趋势检验}"', size(medium)) name(A1,replace)
*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
lsaplot lnemp Size ROA ATO Cashflow FIXED Growth Top1 SOE , treat(action) id(stkcd) time(year) absorb(stkcd year#city_num) cl(id) name(A2,replace)
*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
graph combine A1 A2, iscale(1) imargin(tiny)  xsize(15) ysize(6.5) 
/*==============================================================================
Event Study Method with Binned Pre-periods (3 periods)
==============================================================================*/
use "lsaplot_data.dta" ,clear
graph set window fontface "Times New Roman"
gen policy = year - 2018
tab policy
replace policy = -3 if policy <= -3
forvalues i = 3(-1)1{
gen pre_`i' = (policy == -`i' & treat == 1)
}
forvalues i = 0(1)3{
gen post_`i' = (policy == `i' & treat == 1)
}
replace pre_1 = 0
*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
reghdfe lnemp pre_*  post_* Size ROA ATO Cashflow FIXED Growth Top1 SOE,absorb(stkcd year#city_num) cl(id)

coefplot , baselevels omitted ///                
   keep( pre_*  post_* )  ///
   coeflabels(  pre_3 = -3     ///
    pre_2 = -2  ///
	pre_1 = -1 ///
	post_0 = 0 ///
      post_1 = 1 post_2 = 2 post_3 = 3 )       ///
   vertical                             ///
   recast(connected) ///
      lcolor(black%50) lwidth(medium) lpattern(dash) ///
   yline(0, lcolor(black))             ///
   xline(3, lpattern(dash) lcolor(red%50))            ///显示基期
   ytitle(`"{fontface "宋体":动态处理效应}"',size(medium)) ///
   ylabel(,angle(horizontal) labsize(medium) grid) ///
   xtitle(`"{fontface "宋体":距政策发生的时间}"',size(medium)) ///
   xlabel(,labsize(medium) ) ///          
   ciopts(lpattern(dash) recast(rcap) msize(medium) lcolor(navy)) ///
   mcolor(navy)                        ///
   scheme(s1mono)       ///
   levels(95)                          ///
   graphregion(color(white))           ///
   plotregion(lcolor(white) style(none)) ///
   title(`"{fontface "宋体":平行趋势检验（归并）}"', size(medium)) name(A3,replace)
*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
lsaplot lnemp Size ROA ATO Cashflow FIXED Growth Top1 SOE , treat(action) id(stkcd) time(year) absorb(stkcd year#city_num) cl(id) name(A4,replace) start(-3) bin
*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
graph combine A3 A4, iscale(1) imargin(tiny)  xsize(15) ysize(6.5) 
/*==============================================================================
Event Study Method with Truncated Pre-periods (3 periods)
==============================================================================*/
use "lsaplot_data.dta" ,clear
graph set window fontface "Times New Roman"
gen policy = year - 2018
tab policy
drop if policy < -3
forvalues i = 3(-1)1{
gen pre_`i' = (policy == -`i' & treat == 1)
}
forvalues i = 0(1)3{
gen post_`i' = (policy == `i' & treat == 1)
}
replace pre_1 = 0
*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
reghdfe lnemp pre_*  post_* Size ROA ATO Cashflow FIXED Growth Top1 SOE,absorb(stkcd year#city_num) cl(id)

coefplot , baselevels omitted ///                
   keep( pre_*  post_* )  ///
   coeflabels(  pre_3 = -3     ///
    pre_2 = -2  ///
	pre_1 = -1 ///
	post_0 = 0 ///
      post_1 = 1 post_2 = 2 post_3 = 3 )       ///
   vertical                             ///
   recast(connected) ///
      lcolor(black%50) lwidth(medium) lpattern(dash) ///
   yline(0, lcolor(black))             ///
   xline(3, lpattern(dash) lcolor(red%50))            ///显示基期
   ytitle(`"{fontface "宋体":动态处理效应}"',size(medium)) ///
   ylabel(,angle(horizontal) labsize(medium) grid) ///
   xtitle(`"{fontface "宋体":距政策发生的时间}"',size(medium)) ///
   xlabel(,labsize(medium) ) ///          
   ciopts(lpattern(dash) recast(rcap) msize(medium) lcolor(navy)) ///
   mcolor(navy)                        ///
   scheme(s1mono)       ///
   levels(95)                          ///
   graphregion(color(white))           ///
   plotregion(lcolor(white) style(none)) ///
   title(`"{fontface "宋体":平行趋势检验（截断）}"', size(medium)) name(A5,replace)
*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
lsaplot lnemp Size ROA ATO Cashflow FIXED Growth Top1 SOE , treat(action) id(stkcd) time(year) absorb(stkcd year#city_num) cl(id) name(A6,replace) start(-3) trim
*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
graph combine A5 A6, iscale(1) imargin(tiny)  xsize(15) ysize(6.5) 
*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
graph combine A1 A2 A3 A4 A5 A6, iscale(0.5) imargin(tiny)  xsize(23) ysize(30) row(3) 
