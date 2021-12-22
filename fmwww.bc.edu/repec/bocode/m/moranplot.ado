*Author: Zhenhuan Chen
*Date: 25 January 2021
*Institution: Northeast Forestry University, China
*Email：czh2017@nefu.edu.cn, 317792209@qq.com
*Tel：+86 13224219262
*Postcode：150040
*Address：College of Economics and Management, Northeast Forestry University, NO.26 Hexing Road, Harbin, Heilongjiang, China
*！version 1.0.3, 13th September 2021

capture program drop moranplot
program define moranplot
version 13.0
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
	       quietly regress `w'`var' `var', cformat(%5.3f)
	       local num=string(_b[`var'],"%5.3f")
		   if "`mlabel'" != ""{
	       quietly grss graph twoway (scatter `w'`var' `var', msymbol(Oh) msize(medlarge) mcolor(black) mlabel(`mlabel') mlabcolor(black) yscale(lcolor(none)) xscale(lcolor(none))) || (lfit `w'`var' `var', estopts(noc) lpattern(solid) lcolor(black) lwidth(medium) yscale(lcolor(none)) xscale(lcolor(none))), ytitle(Wz, size(medium) color(black)) xtitle(z,size(medium) color(black)) yline(0, lpattern(dash) lcolor(black)) xline(0, lpattern(dash) lcolor(black)) legend(off) plotregion(lstyle(yxline) lcolor(black)) ylabel(,nogrid) title(Moran scatterplot of `z' (Moran' I = `num'), justification(left) size(medium) color(black)) note(The moran scatterplot of `z' in `note', size(medsmall) color(black))
		                      }
		   else{
		   quietly grss graph twoway (scatter `w'`var' `var', msymbol(Oh) msize(medlarge) mcolor(black) yscale(lcolor(none)) xscale(lcolor(none))) || (lfit `w'`var' `var', estopts(noc) lpattern(solid) lcolor(black) lwidth(medium) yscale(lcolor(none)) xscale(lcolor(none))), ytitle(Wz, size(medium) color(black)) xtitle(z,size(medium) color(black)) yline(0, lpattern(dash) lcolor(black)) xline(0, lpattern(dash) lcolor(black)) legend(off) plotregion(lstyle(yxline) lcolor(black)) ylabel(,nogrid) title(Moran scatterplot of `z' (Moran' I = `num'), justification(left) size(medium) color(black)) note(The moran scatterplot of `z' in `note', size(medsmall) color(black))	
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
	       quietly regress `w'`var' `var', cformat(%5.3f)
	       local num=string(_b[`var'],"%5.3f")
	       if "`mlabel'" != ""{
	       quietly grss graph twoway (scatter `w'`var' `var', msymbol(Oh) msize(medlarge) mcolor(black) mlabel(`mlabel') mlabcolor(black) yscale(lcolor(none)) xscale(lcolor(none))) || (lfit `w'`var' `var', estopts(noc) lpattern(solid) lcolor(black) lwidth(medium) yscale(lcolor(none)) xscale(lcolor(none))), ytitle(Wz, size(medium) color(black)) xtitle(z,size(medium) color(black)) yline(0, lpattern(dash) lcolor(black)) xline(0, lpattern(dash) lcolor(black)) legend(off) plotregion(lstyle(yxline) lcolor(black)) ylabel(,nogrid) title(Moran scatterplot of `z' (Moran' I = `num'), justification(left) size(medium) color(black))
		                      }
		   else{
		   quietly grss graph twoway (scatter `w'`var' `var', msymbol(Oh) msize(medlarge) mcolor(black) yscale(lcolor(none)) xscale(lcolor(none))) || (lfit `w'`var' `var', estopts(noc) lpattern(solid) lcolor(black) lwidth(medium) yscale(lcolor(none)) xscale(lcolor(none))), ytitle(Wz, size(medium) color(black)) xtitle(z,size(medium) color(black)) yline(0, lpattern(dash) lcolor(black)) xline(0, lpattern(dash) lcolor(black)) legend(off) plotregion(lstyle(yxline) lcolor(black)) ylabel(,nogrid) title(Moran scatterplot of `z' (Moran' I = `num'), justification(left) size(medium) color(black))
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
	       quietly regress `w'`var' `var', cformat(%5.3f)
	       local num=string(_b[`var'],"%5.3f")
	       if "`mlabel'" != ""{
	       quietly grss graph twoway (scatter `w'`var' `var', msymbol(Oh) msize(medlarge) mcolor(black) mlabel(`mlabel') mlabcolor(black) yscale(lcolor(none)) xscale(lcolor(none))) || (lfit `w'`var' `var', estopts(noc) lpattern(solid) lcolor(black) lwidth(medium) yscale(lcolor(none)) xscale(lcolor(none))), ytitle(Wz, size(medium) color(black)) xtitle(z,size(medium) color(black)) yline(0, lpattern(dash) lcolor(black)) xline(0, lpattern(dash) lcolor(black)) legend(off) plotregion(lstyle(yxline) lcolor(black)) ylabel(,nogrid) title(Moran scatterplot of `z' (Moran' I = `num'), justification(left) size(medium) color(black)) note(The moran scatterplot of `z' in `note', size(medsmall) color(black))
		                      }
		   else{
		   quietly grss graph twoway (scatter `w'`var' `var', msymbol(Oh) msize(medlarge) mcolor(black) yscale(lcolor(none)) xscale(lcolor(none))) || (lfit `w'`var' `var', estopts(noc) lpattern(solid) lcolor(black) lwidth(medium) yscale(lcolor(none)) xscale(lcolor(none))), ytitle(Wz, size(medium) color(black)) xtitle(z,size(medium) color(black)) yline(0, lpattern(dash) lcolor(black)) xline(0, lpattern(dash) lcolor(black)) legend(off) plotregion(lstyle(yxline) lcolor(black)) ylabel(,nogrid) title(Moran scatterplot of `z' (Moran' I = `num'), justification(left) size(medium) color(black)) note(The moran scatterplot of `z' in `note', size(medsmall) color(black))	
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
	       quietly regress `w'`var' `var', cformat(%5.3f)
	       local num=string(_b[`var'],"%5.3f")
	       if "`mlabel'" != ""{
	       quietly grss graph twoway (scatter `w'`var' `var', msymbol(Oh) msize(medlarge) mcolor(black) mlabel(`mlabel') mlabcolor(black) yscale(lcolor(none)) xscale(lcolor(none))) || (lfit `w'`var' `var', estopts(noc) lpattern(solid) lcolor(black) lwidth(medium) yscale(lcolor(none)) xscale(lcolor(none))), ytitle(Wz, size(medium) color(black)) xtitle(z,size(medium) color(black)) yline(0, lpattern(dash) lcolor(black)) xline(0, lpattern(dash) lcolor(black)) legend(off) plotregion(lstyle(yxline) lcolor(black)) ylabel(,nogrid) title(Moran scatterplot of `z' (Moran' I = `num'), justification(left) size(medium) color(black))
		                      }
		   else{
		   quietly grss graph twoway (scatter `w'`var' `var', msymbol(Oh) msize(medlarge) mcolor(black) yscale(lcolor(none)) xscale(lcolor(none))) || (lfit `w'`var' `var', estopts(noc) lpattern(solid) lcolor(black) lwidth(medium) yscale(lcolor(none)) xscale(lcolor(none))), ytitle(Wz, size(medium) color(black)) xtitle(z,size(medium) color(black)) yline(0, lpattern(dash) lcolor(black)) xline(0, lpattern(dash) lcolor(black)) legend(off) plotregion(lstyle(yxline) lcolor(black)) ylabel(,nogrid) title(Moran scatterplot of `z' (Moran' I = `num'), justification(left) size(medium) color(black))	
		       }
		   capture drop `w'_*
		   cls
		                              }
	         }	
	     }
   end
   quietly grss
   
* Version history
* 1.0.3 Update the display of decimal point in the title
* 1.0.2 Revise the line of yscale in graph
* 1.0.1 Revise the moranplot.sthlp
* 1.0.0 Submit the initial version of moranplot

