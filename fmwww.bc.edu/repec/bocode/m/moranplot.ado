*Author: Zhenhuan Chen
*Date: 25 January 2021
*Institution: Northeast Forestry University, China
*Email：czh2017@nefu.edu.cn, 317792209@qq.com
*Tel：13224219262
*Postcode：150040
*Address：College of Economics and Management, Northeast Forestry University, NO.26 Hexing Road, Harbin, Heilongjiang, China

capture program drop moranplot
program define moranplot
version 16.1
   syntax varlist(numeric) [if], w(name) id(varname) [note(numlist min=1 max=1)] [mlabel(varname)]
      capture spmat use `w' using `w'.spmat
	  if "`if'" != ""{
	  	 preserve
		 keep `if'
	     if "`note'" != ""{
		   foreach z of local varlist {
		   quietly summarize `z'
		   tempvar var
	       capture generate `var'=(`z'-r(mean))/r(sd)
	       capture spmat lag double `w'`var' `w' `var', id(`id')
	       quietly regress `w'`var' `var'
	       tempname m1
	       generate `m1'=round(e(b)[1,1], 0.001)
		   local num=`m1'
		   if "`mlabel'" != ""{
	       quietly grss graph twoway (scatter `w'`var' `var', msymbol(Oh) msize(medlarge) mcolor(black) mlabel(`mlabel') mlabcolor(black)) || (lfit `w'`var' `var', estopts(noc) lpattern(solid) lcolor(black) lwidth(medium)), ytitle(Wz, size(medium) color(black)) xtitle(z,size(medium) color(black)) yline(0, lpattern(dash) lcolor(black)) xline(0, lpattern(dash) lcolor(black)) legend(off) plotregion(lstyle(yxline) lcolor(black)) ylabel(,nogrid) title(Moran scatterplot of `z' (Moran' I = `num'), size(medium) color(black)) note(The moran scatterplot of `z' in `note', size(medsmall) color(black))
		                      }
		   else{
		   quietly grss graph twoway (scatter `w'`var' `var', msymbol(Oh) msize(medlarge) mcolor(black)) || (lfit `w'`var' `var', estopts(noc) lpattern(solid) lcolor(black) lwidth(medium)), ytitle(Wz, size(medium) color(black)) xtitle(z,size(medium) color(black)) yline(0, lpattern(dash) lcolor(black)) xline(0, lpattern(dash) lcolor(black)) legend(off) plotregion(lstyle(yxline) lcolor(black)) ylabel(,nogrid) title(Moran scatterplot of `z' (Moran' I = `num'), size(medium) color(black)) note(The moran scatterplot of `z' in `note', size(medsmall) color(black))	
		       }
	       capture drop `w'_*
	       cls
                                   }
                           }
	  
		 else{
		   foreach z of local varlist {
	       quietly summarize `z'
		   tempvar var
	       capture generate `var'=(`z'-r(mean))/r(sd)
	       capture spmat lag double `w'`var' `w' `var', id(`id')
	       quietly regress `w'`var' `var'
	       tempname m1
	       generate `m1'=round(e(b)[1,1], 0.001)
		   local num=`m1'
	       if "`mlabel'" != ""{
	       quietly grss graph twoway (scatter `w'`var' `var', msymbol(Oh) msize(medlarge) mcolor(black) mlabel(`mlabel') mlabcolor(black)) || (lfit `w'`var' `var', estopts(noc) lpattern(solid) lcolor(black) lwidth(medium)), ytitle(Wz, size(medium) color(black)) xtitle(z,size(medium) color(black)) yline(0, lpattern(dash) lcolor(black)) xline(0, lpattern(dash) lcolor(black)) legend(off) plotregion(lstyle(yxline) lcolor(black)) ylabel(,nogrid) title(Moran scatterplot of `z' (Moran' I = `num'), size(medium) color(black))
		                      }
		   else{
		   quietly grss graph twoway (scatter `w'`var' `var', msymbol(Oh) msize(medlarge) mcolor(black)) || (lfit `w'`var' `var', estopts(noc) lpattern(solid) lcolor(black) lwidth(medium)), ytitle(Wz, size(medium) color(black)) xtitle(z,size(medium) color(black)) yline(0, lpattern(dash) lcolor(black)) xline(0, lpattern(dash) lcolor(black)) legend(off) plotregion(lstyle(yxline) lcolor(black)) ylabel(,nogrid) title(Moran scatterplot of `z' (Moran' I = `num'), size(medium) color(black))
		       }
		   capture drop `w'_*
		   cls
		                             }
	         }
	     restore
	                 }
	  else{
	     if "`note'" != ""{
		   foreach z of local varlist {
		   quietly summarize `z'
		   tempvar var
	       capture generate `var'=(`z'-r(mean))/r(sd)
	       capture spmat lag double `w'`var' `w' `var', id(`id')
	       quietly regress `w'`var' `var'
	       tempname m1
	       generate `m1'=round(e(b)[1,1], 0.001)
		   local num=`m1'
	       if "`mlabel'" != ""{
	       quietly grss graph twoway (scatter `w'`var' `var', msymbol(Oh) msize(medlarge) mcolor(black) mlabel(`mlabel') mlabcolor(black)) || (lfit `w'`var' `var', estopts(noc) lpattern(solid) lcolor(black) lwidth(medium)), ytitle(Wz, size(medium) color(black)) xtitle(z,size(medium) color(black)) yline(0, lpattern(dash) lcolor(black)) xline(0, lpattern(dash) lcolor(black)) legend(off) plotregion(lstyle(yxline) lcolor(black)) ylabel(,nogrid) title(Moran scatterplot of `z' (Moran' I = `num'), size(medium) color(black)) note(The moran scatterplot of `z' in `note', size(medsmall) color(black))
		                      }
		   else{
		   quietly grss graph twoway (scatter `w'`var' `var', msymbol(Oh) msize(medlarge) mcolor(black)) || (lfit `w'`var' `var', estopts(noc) lpattern(solid) lcolor(black) lwidth(medium)), ytitle(Wz, size(medium) color(black)) xtitle(z,size(medium) color(black)) yline(0, lpattern(dash) lcolor(black)) xline(0, lpattern(dash) lcolor(black)) legend(off) plotregion(lstyle(yxline) lcolor(black)) ylabel(,nogrid) title(Moran scatterplot of `z' (Moran' I = `num'), size(medium) color(black)) note(The moran scatterplot of `z' in `note', size(medsmall) color(black))	
		       }
	       capture drop `w'_*
	       cls
                                      }
                           }
	  
		 else{
		   foreach z of local varlist {
	       quietly summarize `z'
		   tempvar var
	       capture generate `var'=(`z'-r(mean))/r(sd)
	       capture spmat lag double `w'`var' `w' `var', id(`id')
	       quietly regress `w'`var' `var'
	       tempname m1
	       generate `m1'=round(e(b)[1,1], 0.001)
		   local num=`m1'
	       if "`mlabel'" != ""{
	       quietly grss graph twoway (scatter `w'`var' `var', msymbol(Oh) msize(medlarge) mcolor(black) mlabel(`mlabel') mlabcolor(black)) || (lfit `w'`var' `var', estopts(noc) lpattern(solid) lcolor(black) lwidth(medium)), ytitle(Wz, size(medium) color(black)) xtitle(z,size(medium) color(black)) yline(0, lpattern(dash) lcolor(black)) xline(0, lpattern(dash) lcolor(black)) legend(off) plotregion(lstyle(yxline) lcolor(black)) ylabel(,nogrid) title(Moran scatterplot of `z' (Moran' I = `num'), size(medium) color(black))
		                      }
		   else{
		   quietly grss graph twoway (scatter `w'`var' `var', msymbol(Oh) msize(medlarge) mcolor(black)) || (lfit `w'`var' `var', estopts(noc) lpattern(solid) lcolor(black) lwidth(medium)), ytitle(Wz, size(medium) color(black)) xtitle(z,size(medium) color(black)) yline(0, lpattern(dash) lcolor(black)) xline(0, lpattern(dash) lcolor(black)) legend(off) plotregion(lstyle(yxline) lcolor(black)) ylabel(,nogrid) title(Moran scatterplot of `z' (Moran' I = `num'), size(medium) color(black))	
		       }
		   capture drop `w'_*
		   cls
		                              }
	         }	
	     }
   end
   quietly grss