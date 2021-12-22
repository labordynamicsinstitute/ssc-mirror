*! ma_dot v1.0 09/01/2021
*start with row per outcome
cap prog drop madot
cap postclose ma_dot 
program define madot, rclass 
version 16.1

/*
  DESCRIPTION: Creating a dot plot for pooled estimates from meta-analysis 
  */
  
syntax, outcome(varname) dot1(varname) dot2(varname) poolest(varname) n(varname) cil(varname) ciu(varname) ///
		textcol1(varname) textcol2(varname) textcol3(varname) ///
		textcol4(varname) textcol5(varname) textcol6(varname) ///
		[logoff(integer 0) ///
		leftxtitle(string) rightxtitle(string) ///
		leftcolor1(string)  leftcolsat1(integer 50) leftsymb1(string) ///
		leftcolor2(string) leftcolsat2(integer 50)  leftsymb2(string) ///
		rightxlinepat(string) rightxlinecolor(string) rightxlabel(numlist)  ///
		legendleftyn(integer 1) legendleft1(string) legendleft2(string) ///
		legendleftpos(integer 6) legendleftcol(integer 2)  legendleftrow(integer 1)  ///
		legendrightyn(integer 1) legendright1(string) legendright2(string) ///
		legendrightpos(integer 6) legendrightcol(integer 2) legendrightrow(integer 1) ///
		textcol1pos(real 5) textcol2pos(real 18) textcol3pos(real 55) ///
		textcol4pos(real 120) textcol5pos(real 240) textcol6pos(real 450) ///
		textcolposy(real 0.1) ///
		textcol1name(string) textcol2name(string) textcol3name(string) ///
		textcol4name(string) textcol5name(string) textcol6name(string)  ///
		grphcol(string) plotcol(string) title(string) subtitle(string) ///
		graphwidth(real 10) graphheight(real 5) iscale(real 0.55) ///
		margin(integer 0) clear]
      preserve

	  /* unused options: aspectleft(real 0) aspectright(real 0) */
	  
/*
        Syntax explanation
        outcome - Outcome name
        dot1 - variable to plot as dot; e.g. proportion of event out of total sample size in treatment grp, or mean of trt grp at baseline
        dot2 - variable to plot as dot; e.g. proportion of event out of total sample size in control grp, or mean of ctrl grp at baseline
        poolest - pooled estimates from meta-analysis, e.g. relative risk, mean difference
        n - order of outcomes or other variable for sorting
		cil - lower bound of 95% CI of pooled estimates
		cil - upper bound of 95% CI of  pooled estimates
		textcol1 to textcol6 - variables to show in the text columns
        */
		
/*Optional commands
(1) leftxtitle(string) is optional, title for x axis (reversed y axis) of left dot plot - the default is Proportion or Baseline weighted means

(2) rightxtitle(string) is optional, title for x axisof right scatter plot

(3) leftcolor1(string) is optional, color of dot fill and outline on left dot plot for treatment 1 - default is red

(4) leftcolsat1(integer 50) is optional, color saturation on dot fill for dot plot - default is 50

(5) leftsymb1(string) is optional, marker symbol for first treatment group value on left dot plot symbol - default is triangle

(6) leftcolor2(string) is optional, color of dot fill and outline on left dot plot for treatment 2 - default is blue

(7) leftcolsat2(integer 50) is optional, color saturation on dot fill for dot plot - default is 50

(8) leftsymb2(string) is optional, marker symbol for second treatment group value on left dot plot symbol - default is circle

(9) rightxlinepat(string) is optional and can be used to change style of vertical line on right scatte rplot - default is dash

(10) rightxlinecolor(string) is optional and can be used to change color of vertical line on right scatterplot - default is bluishgray

(11) rightxlabel(numlist) allows user to specifie x axis tick labels on right scatter plot - default is 0.5 1 2 900

(12) legendleftyn(integer 1) is optional - default is 1 and indicates that legend turned on for left dot plot

(13) legendleft1(string) options to add legend of first group on left dot plot - default is "Treatment"

(14) legendleft2(string) options to add legend of second group on left dot plot - default is "Control"

(15) legendleftpos(integer 6) option to specify position of legend in left dot plot

(16) legendleftcol(integer 2) and legendleftrow(integer 1) options for number of columns and rows  of legend in left dot plot - defaults are are 2 columns and 1 row
         
(17) legendrightyn(integer 1) is optional - default is 1 and indicates that legend turned on for right scatterplot

(18) legendright1(string) options to add text of the legend in right scatter plot - default is "RR from MA" or "MD"

(19) legendright2(string) options to add text of the legend in right scatter plot - default is "95% CI"

(20) legendrightpos(integer 6) option to specify position of legend in right scatter plot

(21) legendrightcol(integer 2) and legendrightrow(integer 1) options for number of columns and rows in right scatter plot legend - defaults are are 2 columns and 1 row
         
(22) aspectleft(real 0)  sets the aspect of the scatterplot - need decide if this is necessary

(23) aspectright(real 0)  sets the aspect of the scatterplot - need decide if this is necessary

(24) grphcol(string) and plotcol(string) set graph and plot background color - defaults to white

(20) margin(integer 0) % increase added to the right of the the right plot - refer to margin help

(22) textcol1pos(real 5) x axis position to place the 1st text column - default is 5

(23) textcol2pos(real 18) x axis position to place the 2nd text column - default is 18

(25) textcol3pos(real 55) x axis position to place the 3rd text column - default is 55

(26) textcol4pos(real 120) x axis position to place the 4th text column - default is 120

(27) textcol5pos(real 240) x axis position to place the 5th text column - default is 240

(28) textcol6pos(real 450) x axis position to place the 6th text column - default is 450

(29) textcolposy(real 0.1) y axis position to place the labels of text columns - default is 0.1

(30) textcol1name(string) label for the 1st text column- default is "RR (95% CI)"

(31) textcol2name(string) label for the 2nd text column- default is ""Trt n/N""

(32) textcol3name(string) label for the 3rd text column- default is ""ctrl n/N""

(33) textcol4name(string) label for the 4th text column- default is "NTials", meaning number of trials

(34) textcol5name(string) label for the 5th text column- default is "I-squared"

(35) textcol6name(string) label for the 6th text column- default is "SOE"

(36) LOGoff(integer 0) used to indicate if x axis on the right plot shows log scale - default is 0 for log scale, 1 is for not log scale

(37) graphwidth is optional, width of overall graph - default is 10

(38) graphheight is optional, height of overall graph  - default is 5

(39) iscale is optional,  size of text and markers - default is 0.55

*/		
		
		
qui {

* local order = _n
	
*************Setting default colors before error checking************

*Setting default circle color in group one to red on dot plot
if "`leftcolor1'" == "" {
	local leftcolor1 = "red"
	}

*Setting default circle color in group two to blue on dot plot
if "`leftcolor2'" == "" {
	local leftcolor2 = "blue"
	}

*Setting default line color for xline on scatter plot to bluishgray - need to restrict what can be entered to lcolor 
if "`rightxlinecolor'" == "" {
        local rightxlinecolor = "bluishgray"
        }
		
  
*Setting default plot background color to white
if "`plotcol'" =="" {
        local plotcol = "white"
        }
        
*Setting default graph background color to white
if "`grphcol'" =="" {
        local grphcol = "white"
        }		
	
***Error checking colors****************
local test = c(sysdir_base)
local test2 = "`test'"+"style"
local coloropt : dir "`test2'" files "color-*.style"
local coloropt : list clean coloropt
local coloropt: subinstr local coloropt "color-" "", all
local coloropt: subinstr local coloropt ".style" "", all
local coloropt: subinstr local coloropt "blank" "", all


tempvar col1
gen `col1'=0 
if  "`rightxlinecolor'"!="" {
        foreach lname in `coloropt' {
                cap replace `col1'=1  if "`lname'"=="`rightxlinecolor'"
                }
        }
if `col1'== 0 {
        disp as error "`rightxlinecolor' is not a color. Please see Stata colorstyle for acceptable options"
        exit 198
        }       
        

tempvar col5
gen `col5'=0 
if  "`leftcolor1'"!="" {
        foreach lname in `coloropt' {
                cap replace `col5'=1  if "`lname'"=="`leftcolor1'"
                }
        }
if `col5'== 0 {
        disp as error "`leftcolor1' is not a color. Please see Stata colorstyle for acceptable options"
        exit 198
        }
        
tempvar col6
gen `col6'=0 
if  "`leftcolor2'"!="" {
        foreach lname in `coloropt' {
                cap replace `col6'=1  if "`lname'"=="`leftcolor2'"
                }
        }
if `col6'== 0 {
        disp as error "`leftcolor2' is not a color. Please see Stata colorstyle for acceptable options"
        exit 198
        }
		

tempvar col7
gen `col7'=0 
if  "`plotcol'"!="" {
        foreach lname in `coloropt' {
                cap replace `col7'=1  if "`lname'"=="`plotcol'"
                }
        }
if `col7'== 0 {
        disp as error "`plotcol' is not a color. Please see Stata colorstyle for acceptable options"
        exit 198
        }

tempvar col8
gen `col8'=0 
if  "`grphcol'"!="" {
        foreach lname in `coloropt' {
                cap replace `col8'=1  if "`lname'"=="`grphcol'"
                }
        }
if `col8'== 0 {
        disp as error "`grphcol' is not a color. Please see Stata colorstyle for acceptable options"
        exit 198
        }


**********Setting default symbols before error checking	
*Setting default symbol in group 1
if "`leftsymb1'" =="" {
	local leftsymb1= "triangle"
}

*Setting default symbol in group 2
if "`leftsymb2'" =="" {
	local leftsymb2= "circle"
}
	
	
**********************************************
*Code to display legend
**********************************************
	
*****************************************************************************	
*logoff can only take values 0 or 1
if `logoff' >1  | `logoff'<0 {  
	display as error "logoff can only take values 0 or 1"
	exit 7
	}


*legendrightyn can only take values 0 or 1
if `legendrightyn' >1  | `legendrightyn'<0 {  
	display as error "legendrightyn can only take values 0 or 1"
	exit 7
	}

*legendrightpos can only take integer values between 0 and 12
if `legendrightpos' >12 | `legendrightpos'<0  {  
	display as error "legendrightpos can only take integer values between 0 and 12 "
	exit 7
	}	
*****************************************************************************		

*Code to display legend - for dot plot
*If legendyn is 0 then legend switched off 
if `legendleftyn' ==0  {
        local legendtext = "off"
        }
                
if `legendleftyn' ==1 & "`legendleft1'"=="" {
        local legenddef1 = "Treatment"
        }

if `legendleftyn' ==1 & "`legendleft1'"!="" {
        local legenddef1 = "`legendleft1'"
        }
        
if `legendleftyn' ==1 & "`legendleft2'"=="" {
        local legenddef2 = "Control"
        }
if `legendleftyn' ==1 & "`legendleft2'"!="" {
        local legenddef2 = "`legendleft2'"
        }
        
if `legendleftyn' ==1 & "`legendleft1'"==""  & "`legendleft2'"=="" {
        local legenddef1 = "Treatment"
        local legenddef2 = "Control"
        }
        
if `legendleftyn' ==1 {
        local legendtext = "lab(1 `legenddef1') lab(2 `legenddef2')"
        }   
		
		
***** Code to display legend - for right plot
if `legendrightyn' ==0  {
        local legendtext_scat = "off"
        }		

if `legendrightyn' ==1 & "`legendright1'"=="" & `logoff' == 0{
	local legenddefscat1 = "RR from MA"
	}

if `legendrightyn' ==1 & "`legendright1'"!="" & `logoff' == 0{
	local legenddefscat1 = "`legendright1'"
	}
	
if `legendrightyn' ==1 & "`legendright2'"==""{
	local legenddefscat2 = "95% CI"
	}
	
if `legendrightyn' ==1 & "`legendright2'"!=""{
	local legenddefscat2 = "`legendright2'"
	}
	
if `legendrightyn' ==1 & "`legendright1'"==""  & "`legendright2'"=="" & `logoff' == 0{
	local legenddefscat1 = "RR from MA"
	local legenddefscat2 = "95% CI"
	}

if `legendrightyn' ==1 & `logoff' == 0{
	local legendtext_scat = "lab(1 `legenddefscat1') lab(2 `legenddefscat2')"
}

* plot for continuous outcome
if `legendrightyn' ==1 & "`legendright1'"=="" & `logoff' == 1{
	local legenddefscat1 = "MD"
	}

if `legendrightyn' ==1 & "`legendright1'"!="" & `logoff' == 1{
	local legenddefscat1 = "`legendright1'"
	}
	
	
if `legendrightyn' ==1 & "`legendright1'"==""  & "`legendright2'"=="" & `logoff' == 1{
	local legenddefscat1 = "MD"
	local legenddefscat2 = "95% CI"
	}

	if `legendrightyn' ==1 & `logoff' == 1{
	local legendtext_scat = "lab(1 `legenddefscat1') lab(2 `legenddefscat2')"
}
			
*Giving defaults for xaxis title and yaxis title (which is surpressed from view - but ensures legends are aligned)
if "`leftxtitle'" =="" & `logoff'==0 {
	local leftxtitle = "Proportion"
	}
	
if "`rightxtitle'" ==""& `logoff'==0 {
	local rightxtitle = "Decreased risk      Increased risk"
	}

if "`leftxtitle'" =="" & `logoff'==1 {
	local leftxtitle = "Weighted baseline  means"
	}
	
if "`rightxtitle'" ==""& `logoff'==1 {
	local rightxtitle = "MD"
	}


*********************************************************************************
**************Setting default linepattern to dash for xline on right plot**
if "`rightxlinepat'" == "" {    
        local rightxlinepat= "dash"
        }

		       
*Creating default right axis x label when rel risk option used to give meaningful labels
*Plot with rel risk and x-axis logged
if "`rightxlabel'" == "" & `logoff'==0 {
                local rightxlabel =  "0.5 1 2 900"
                }
				
if "`rightxlabel'" == "" & `logoff'==1 {
                local rightxlabel =  "-1 0 1 30"
                }				
                
if "`rightxlabel'" !="" {
        local rightxlabel `rightxlabel'
        }
        

		
local order = _n
local N = _N
local ymax = `N' + 0.4 


foreach num of numlist  1(1)`N' { 
	    local textcol1_`num' = `textcol1' in `num'              
		local textcol2_`num' = `textcol2' in `num'
		local textcol3_`num' = `textcol3' in `num'
		local textcol4_`num' = `textcol4' in `num'
		local textcol5_`num' = `textcol5' in `num'
		local textcol6_`num' = `textcol6' in `num'
		
		local numtexttit1 "`textcol1_`num''"
		local numtexttit2 "`textcol2_`num''"
		local numtexttit3 "`textcol3_`num''"
		local numtexttit4 "`textcol4_`num''"
		local numtexttit5 "`textcol5_`num''"
		local numtexttit6 "`textcol6_`num''"
		
		local otxt1 `" text(`num' `textcol1pos' "`numtexttit1'" , size(small)) "'
		local otxt2 `" text(`num' `textcol2pos' "`numtexttit2'" , size(small)) "' 
		local otxt3 `" text(`num' `textcol3pos' "`numtexttit3'" , size(small)) "' 
		local otxt4 `" text(`num' `textcol4pos' "`numtexttit4'" , size(small)) "' 
		local otxt5 `" text(`num' `textcol5pos' "`numtexttit5'" , size(small)) "' 
		local otxt6 `" text(`num' `textcol6pos' "`numtexttit6'" , size(small)) "' 
		
		local all_otxt "`all_otxt' `otxt1' `otxt2' `otxt3' `otxt4' `otxt5' `otxt6'"
	}
	
*Creating default labels for columns*
if "`textcol1name'"=="" & `logoff' == 0 {
	local textcol1name = "RR (95% CI)"
	}

if "`textcol1name'"==""  & `logoff' == 1 {
	local textcol1name = "MD (95% CI)"
	}
	
if "`textcol1name'"!="" {
	local textcol1name = "`textcol1name'"
	}
	
	
if "`textcol2name'"=="" & `logoff' == 0 {
	local textcol2name = "Trt n/N"
	}
	
	
if "`textcol2name'"=="" & `logoff' == 1 {
	local textcol2name = "Trt BL mean"
	}

if "`textcol2name'"!="" {
	local textcol2name = "`textcol2name'"
	}
		
		
if "`textcol3name'"=="" & `logoff' == 0 {
	local textcol3name = "Ctrl n/N"
	}
	
if "`textcol3name'"=="" & `logoff' == 1 {
	local textcol3name = "Ctrl BL mean"
	}
	
if "`textcol3name'"!="" {
	local textcol3name = "`textcol3name'"
	}	
	
	
if "`textcol4name'"=="" {
	local textcol4name = "NTrials"
	}
	
if  "`textcol4name'"!="" {
	local textcol4name = "`textcol4name'"
	}
	
	
if "`textcol5name'"=="" {
	local textcol5name = "I{sup:2}"
	}
if  "`textcol5name'"!="" {
	local textcol5name = "`textcol5name'"
	}
	

if "`textcol6name'"=="" {
	local textcol6name = "SOE"
	}
	
if "`textcol6name'"!="" {
	local textcol6name = "`textcol6name'"
	}	
	
**********************************************
* Plots
**********************************************

tempfile graph_abs
tempfile graph_rel
tempfile graph_rd
    
**** dichotomous outcomes ****
* gen max = _N

 if `logoff'==0 {
 
	**** left plot ****
	graph dot `dot1' `dot2', over(`outcome', sort(`n')) ///
			marker(1, mfcolor(`leftcolor1'%`leftcolsat1') mlcolor(`leftcolor1') msymbol(`leftsymb1')) ///
			marker(2, mfcolor(`leftcolor2'%`leftcolsat2') mlcolor(`leftcolor2') msymbol(`leftsymb2')) ///
			ytitle(`leftxtitle', size(small)) yscale(range (0 `max')) ///
			legend(`legendtext'  pos(`legendleftpos') col(`legendleftcol') row(` legendleftrow') region(lwidth(none))) ///
			dots(mcolor(gray)) ///
			graphregion(color(white)) aspect(0)
			
			* nofill ///   /* option for removing missing values */
	
	graph save Graph `graph_abs'.gph , replace
	
		
	**** right plot ****
	local N = _N
	local ymax = `N' + 0.4
	
	twoway (dot `poolest' `n', ysc(off) horizontal sort(`n') dcolor(white) mcolor(gs1) msymbol(square) msize(vsmall)) ///
		(rcap `cil' `ciu' `n', horizontal sort(`n') lcolor(gs1)), /// /* ad CI of RR */ 
		ylabel( "", angle(0) noticks nogrid) ytitle("" ) yscale(reverse) yscale(range(0.5 `ymax'))  ///
		xscale(log)  ///
		xlabel(`rightxlabel' , angle(0))  xtitle(`rightxtitle' , color(black) size(small)) ///
		xline(1 ,  lpattern(`rightxlinepat') lcolor(`rightxlinecolor') lwidth(0.5)) ///
		legend(`legendtext_scat' pos(`legendrightpos') col(`legendscatcol') row(`legendrightrow') region(lwidth(none))) ///  
		graphregion(color(`grphcol')) plotregion(color(`plotcol')) aspect(0) ///
		plotr(style(none) margin(r `margin')) ///
		text(`textcolposy' `textcol1pos' "`textcol1name'", size(small)) ///
		text(`textcolposy' `textcol2pos' "`textcol2name'", size(small)) /// 
		text(`textcolposy' `textcol3pos' "`textcol3name'", size(small)) ///
		text(`textcolposy' `textcol4pos' "`textcol4name'", size(small)) ///
		text(`textcolposy' `textcol5pos' "`textcol5name'", size(small)) ///
		text(`textcolposy' `textcol6pos' "`textcol6name'", size(small)) ///
		`all_otxt'
		
	graph save Graph `graph_rel'.gph , replace
	
	graph combine  `graph_abs'.gph  `graph_rel'.gph, xcommon ycommon iscale(`iscale') scale(1.35) graphregion(color(`grphcol')) ysize(`graphheight') xsize(`graphwidth')  title(`title') subtitle(`subtitle') 
 }
 
 
 if `logoff'==1 {
	
	local order = _n
	local N = _N
	local ymax = `N' + 0.4 
			

	**** left plot ****
	graph dot `dot1' `dot2', over(`outcome', sort(`n')) ///
			marker(1, mfcolor(`leftcolor1'%`leftcolsat1') mlcolor(`leftcolor1') msymbol(`leftsymb1')) ///
			marker(2, mfcolor(`leftcolor2'%`leftcolsat2') mlcolor(`leftcolor2') msymbol(`leftsymb2')) ///
			ytitle(`leftxtitle', size(small)) yscale(range (0 `max')) ///
			legend(`legendtext'  pos(`legendleftpos') col(`legendleftcol') row(` legendleftrow') region(lwidth(none))) ///
			dots(mcolor(gray)) ///
			graphregion(color(white)) aspect(0)
			
			* nofill ///   /* option for removing missing values */
	
	graph save Graph `graph_abs'.gph , replace
	
		
	**** right plot ****
	local N = _N
	local ymax = `N' + 0.5
	
	twoway (dot `poolest' `n', ysc(off) horizontal sort(`n') dcolor(white) mcolor(gs1) msymbol(square) msize(vsmall)) ///
		(rcap `cil' `ciu' `n', horizontal sort(`n') lcolor(gs1)), /// /* ad CI of RR */ 
		ylabel( "", angle(0) noticks nogrid) ytitle("" ) yscale(reverse) yscale(range(0.6 `ymax'))  ///
		xlabel(`rightxlabel' , angle(0))  xtitle(`rightxtitle' , color(white) size(medsmall)) ///
		xline(0 ,  lpattern(`rightxlinepat') lcolor(`rightxlinecolor') lwidth(0.5)) ///
		legend(`legendtext_scat' pos(`legendrightpos') col(`legendscatcol') row(`legendrightrow') region(lwidth(none))) ///  
		graphregion(color(`grphcol')) plotregion(color(`plotcol')) aspect(0) ///
		plotr(style(none) margin(r `margin')) ///
		text(`textcolposy' `textcol1pos' "`textcol1name'", size(small)) /// 
		text(`textcolposy' `textcol2pos' "`textcol2name'", size(small)) ///
		text(`textcolposy' `textcol3pos' "`textcol3name'", size(small)) ///
		text(`textcolposy' `textcol4pos' "`textcol4name'", size(small)) ///
		text(`textcolposy' `textcol5pos' "`textcol5name'", size(small)) ///
		text(`textcolposy' `textcol6pos' "`textcol6name'", size(small)) ///
		`all_otxt'
		
	graph save Graph `graph_rel'.gph , replace
	
	graph combine  `graph_abs'.gph  `graph_rel'.gph, xcommon ycommon iscale(`iscale') scale(1.35) graphregion(color(`grphcol')) ysize(`graphheight') xsize(`graphwidth')  title(`title') subtitle(`subtitle') 
}
 
}


end
exit