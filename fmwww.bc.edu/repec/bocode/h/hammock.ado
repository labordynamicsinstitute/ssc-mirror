program define hammock
*! 1.1.2    19 May 2022: added argument to samescale option
	version 14.2
	syntax varlist [if] [in], [  Missing BARwidth(real 1) /// 
		hivar(str) HIVALues(numlist) SPAce(real 0.3) LABel labelopt(str) SAMEscale(varlist)    ///
		ysize(real 4) xsize(real 5.5) COLorlist(str)  * ]

	confirm numeric variable `varlist'

	local missing = "`missing'" != ""
	local addlabel= "`label'" != ""
	local same = "`samescale'" !=""
	
	local varnamewidth=`space' /*=percentage of space given to text as oppposed to the graph*/
	if `addlabel'==0 {
		local varnamewidth=0
	}

	* observations to use 
	marksample touse , novarlist
	qui count if `touse' 
	if r(N) == 0 { 
		error 2000 
	} 

	preserve 
	qui keep if `touse' 
	tempvar id std_ylag width graphxlag colorgroup
	tempname label_coord 
	gen long `id'  = _n 
	local N = _N
	local separator "@"  /*one letter only, separates variable names */
	*length of the (physical) x axis relative to the y axis: Stata's default is ysize(4) xsize(5.5)
	* these options are explicitly specified to prevent that they are collected in syntax argument "*"
	local aspectratio=`xsize'/`ysize'
	

	if `addlabel'==1 {
		list_labels `varlist', separator(`separator')
		matrix `label_coord'= r(label_coord)
		local label_text  "`r(label_text)'"
	}

	
	local k : word count `varlist' 
	local max=`k'
	tokenize `varlist' 
	
	// if "missing" not specified, drop observations with missing values
	// do this now, so the range calculations of earlier variables (with non-missing values)are not affected 
	// before we find a missing value in a later variable
	if (`missing'==0) {
		foreach v of var `varlist' { 
			qui drop if `v'==.
		}
	}

	* compute max,min values over the variables specified in samescale
	if `same' {
		globalminmax `samescale' 
		local globalmax=r(globalmax)
		local globalmin=r(globalmin)
		local globalrange=`globalmax'-`globalmin'
	}
	
	* create new variables that have a range between 0 and 100.
	local i=0
	foreach v of var `varlist' { 
		local i = `i' + 1   /*needed to find the right variables of label_coord */
		* new tempvar for each loop iteration 
		quietly sum `v'
		if (r(min)!=r(max)) {
			local range=r(max)-r(min)
		}
		else { 
			* var has only one value
			local range=1	
		}
		local min=r(min)
		if (`same' & ustrregexm("`samescale'","`v'")) {
			* override calculations with variables specified in samescale
			local range=`globalrange'
			local min=`globalmin'
		}
		if (`missing') {
			* missing option specified 
			local yline "yline(4, lcolor(black))" // horizontal line to separate missing values; number depends on range expansion
			local rangeexpansion=0.1  /*fraction space reserved for missing values*/
			local missval=`min'-`rangeexpansion'*`range'
			qui replace `v'=`missval' if `v'==.
			local min=`missval'  /* redefine minimum value and range */
			local range=`range'*(1+`rangeexpansion')
		}	
		local my_y  "std_y`i'"
		gen `my_y' = (`v'-`min')/ `range' * 100
		
		if `addlabel'==1 {
			local n_labels = rowsof(`label_coord') 
			forval ii = 1 / `n_labels' {
				if (`label_coord'[`ii',2]==`i') { 
					/* label belongs to variable `v' */
					matrix `label_coord'[`ii',1]= (`label_coord'[`ii',1] -`min')/ `range' * 100
				}
			}
		}
		
	} 	 

	* construct xlabel
	local i=1
	foreach v of var `varlist' {
		if mod(`i', 2)  local xl "`xl' `i'" 
      	else 			local tl "`tl' `i'" 
      	local xlabel "`xlabel' `i' ``i''"
      	local i = `i' + 1
   	}
   	local xl = substr("`xl'", 2, .)
   	local xlab_num "`xl'"
   	if (`k' > 10) 	local tlab = "tlab(" + substr("`tl'", 2, .) + ")"
   	else 			local xlab_num "`xl'`tl'" 

	/*generate colorgroup variable for highlighting*/
	/*gen_colorgroup overwrites 'varlist' and mustn't come earlier*/
	if "`hivar'"!="" 	gen_colorgroup `hivar' , hivalues(`hivalues') 
	else 				gen colorgroup=1

	
	
	* transform the data from one obs per data point to one obs per graphbox 
	* 	using reshape and contract

	* variables yvar need be listed std_y1 std_y2 std_y3 etc.   
	// "std_y" is a stub only; cannot replace by a tempvariable
	qui reshape long std_y, i(`id') 
	keep std_y `id' _j colorgroup 

	* graphx is the variable index of std_y
	local graphx "_j"

	qui { 
		bysort `id' (`graphx') : gen `std_ylag' = std_y[_n+1] 
		drop if `std_ylag' == .  /*last variable doesn't connect to variable after it*/
	} 	

	* graphx is important for unique identification 
	contract std_y `std_ylag' `graphx' colorgroup
	* scatter std_y  `graphx'


	
	*** preparation for graph 
      
    * make room for labels in between rectangles
	gen `graphxlag'= `graphx'+ (1-`varnamewidth'/2)
	if (`varnamewidth'>0)	{ 
		qui replace `graphx'= `graphx' + `varnamewidth'/2 
	}

	* compute `width' :  refers to a percentage of `range'
	summarize `std_ylag', meanonly 
	local range = r(max) - r(min)
	// 0.2 was the old default for barwidth. Now barwidth is a multiplicative increase from 0.2
	gen `width' =_freq / `N' * `range' * 0.2* `barwidth' 
	
	* modify width; compute graphxlag
 	local yrange= 100
	local xrange= max(3,`k')-1   /* number of x variables-1==xrange */
		/*Exception:when there are only 2 x-variables, Stata allocates space as if there were 3 */
	tempvar width_y
	qui gen `width_y'=.
 	rightangle_width `graphx' `graphxlag'  std_y `std_ylag'  `width' `width_y' /*
			*/	`xrange' `yrange' `aspectratio'
	qui replace `width'=`width_y' 
	*list `graphx' `graphxlag'  std_y `std_ylag'  `width' `width_y' 
	*di as res "xrange `xrange' yrange `yrange' " 
 

	/* computation of ylabmin and ylabmax */
	/* needed to avoid that some coordinates are off the graph screen*/
	/* since def of width changes later this is only approximate */	
	Computeylablimit std_y `std_ylag' `width' 
	local ylabmax=r(ylabmax)
	local ylabmin=r(ylabmin) 
 
    //reshape: previously each obs represented unique (box,color) combination
	//now each obs represents a unique box (with multiple colors). 
	// color variables contain the width of the color and are missing otherwise
    keep  `width' colorgroup `graphx' `graphxlag' std_y `std_ylag' 
    qui reshape wide `width', j(colorgroup) i(`graphx' `graphxlag' std_y `std_ylag')


	// labels
	label var `graphx' " "
	label var std_y " "
	lab define myxlab `xlabel'
	lab values  `graphx' myxlab

	*preparation for adding labels in plot
	* the labels are overwriting the plot . Plot before the graphboxes 
	if `addlabel'==1 {
		tokenize `label_text', parse(`separator')
		local addlabeltext="text("   // no space between "text" and "("
		forval j=1/`n_labels' { 
			if (`label_coord'[`j',2] !=0) { 
				/*crucial if matrix has empty rows, otherwise graph disappears*/
				local pos=`j'*2-1  /* positions 1,3,5,7, ...  */
				// text to plot ="``pos''"      y = `label_coord'[`j',1]        x= `label_coord'[`j',2]  
				// the matrix needs to be evaluated as  `=matrixelem'  ; otherwise just the name of the matrix elem appears
				local addlabeltext= `"`addlabeltext' `=`label_coord'[`j',1]' `=`label_coord'[`j',2]' "``pos''" "'
			}
		}
		if (`missing'==1) local addlabeltext= `"`addlabeltext' 0 1 "missing" "'
		* add label options 
		local addlabeltext= `"`addlabeltext',`labelopt')"'
	}
	

	// width is the stub of the variable names; width`i' contains the width of color `i'
	GraphBoxColor , xstart(`graphx') xend(`graphxlag') ystart(std_y) yend(`std_ylag') ///
	     width(`width')  range(`range') ylabmax(`ylabmax') ylabmin(`ylabmin') ///
		 xlab_num("`xlab_num'") tlab(`"`tlab'"') graphx("`graphx'") colorlist("`colorlist'") ///
		 xsize(`xsize') ysize(`ysize') ///
		 options(`"`options'"') addlabeltext(`"`addlabeltext'"') yline(`"`yline'"')

end

/**********************************************************************************/
* creates matrix with coordinates for labels
* on exit: label_text : single string separated by `separator; of all labels
* on exit: label_coord: matrix with one row for each label and two columns containing x and y coordinates
*      where the xcoordinates range from 1...(#variables( and the y coordinates from 1..(# labels for corresponding variable)
* on exit: label_coord: a single string with "y1 x1 y2 x2 ... y_nlabel x_nlabel" . For later use with tokenize
program define list_labels, rclass
   version 7
   syntax varlist , separator(string)

   tempname one_ylabel label_coord

   n_level_program `varlist'
   local n_level= r(n_level)
      
   matrix `label_coord'=J(`n_level',2,0)
   local label_text ""
   local i=0   /* the ith variable (for x-axis) */
   local offset=0  /* sum of the number of levels in previous x-variables */
   
   foreach v of var `varlist' { 
      local i= `i'+1
   	qui tab `v', matrow(`one_ylabel')
	local n_one_ylabel=r(r)

	local g : value label `v'
	forval  j = 1/`n_one_ylabel' {
		local w=`one_ylabel'[`j',1]
      	matrix `label_coord'[`offset'+`j',2]=`i'
		matrix `label_coord'[`offset'+`j',1]=`w'
		if "`g'"!="" {
			local l : label `g' `w'
			local label_text "`label_text'`l'`separator'"
		}
		else {	
			/* format numbers to display */
			local format_w=string(`w',"%6.0g") 
			local label_text "`label_text'`format_w'`separator'"
		}
      }
      local offset=`offset'+`n_one_ylabel'
   }
 
   return matrix label_coord `label_coord'
   return local label_text `"`label_text'"' 

end 

/**********************************************************************************/
program define n_level_program, rclass
   version 7
   * compute the sum of the number of levels of all variables
   * each level later corresponds to a label
   syntax varlist 

   * calc the sum of number of levels of all vars
   local n_level=0
   foreach v of var `varlist' { 
		qui tab `v'
		  local temp= r(r)
		local n_level=`n_level' + `temp'
   }
   if (`n_level'>40) {
		if (`n_level'<=800) {
			set matsize `n_level'
		}
		else {
			di as error "Error: Attempting to display more than 800 labels"
			error 2000
		}
   }
  return local n_level `n_level'

end 
/**********************************************************************************/
program define globalminmax, rclass
   version 7
	* compute min and max values over all variables
	syntax varlist

	local globalmax=-9999999
	local globalmin=9999999
	foreach v of var `varlist' { 
		qui sum `v'
		if (r(max)>`globalmax') {
			local globalmax=r(max)
		}
		if (r(min)<`globalmin') {
			local globalmin=r(min)
		}
	}
	return local globalmin `globalmin'
	return local globalmax `globalmax'

end 
/**********************************************************************************/
program define rightangle_width
   version 7
   * compute the difference of the y coordinates needed when width is taken to 
   * mean right-angle width (distance between two parallel lines)
   * aspectratio: how much longer is the x axis relative to the y axis
   * on input : width_y has already been "generate"d 
   * width_y is computed as a result 
   args xstart xend ystart yend width width_y xrange yrange aspectratio

   tempvar xdiff ydiff
   qui gen `xdiff'= .
   qui gen `ydiff'= .
   qui replace `xdiff'= (`xend'-`xstart')/`xrange' * `aspectratio'
   qui replace `ydiff'= (`yend'-`ystart')/ `yrange'
   qui replace `width_y'=`width' / `xdiff' * sqrt(`xdiff'*`xdiff'+`ydiff'*`ydiff') 

*list `xdiff' `ydiff' `width_y'

end 
/**********************************************************************************/
* generate the colorgroup variable
* all values not mentioned in hivalues get color=1
* colors are generated in sequence of hivalues
* if value in hivalues not contained in hivar, then the corresponding color is just skipped
* if hivar does not exist will give error message "variable `hivar' not found
* if the same value is contained multiple times, only the last one is used and colors 
     *corresponding to earlier ones are skipped
* if hivalues contains more than 8 values earlier pens are being reused
* if hivalues contains all values of hivar, then the default color is never used
* hivalues does not accept labels at this point
* if hivalues not specified will give appropriate error
program define gen_colorgroup
   version 7
   syntax  varlist(max=1 numeric),  HIVALues(numlist)  
   *tokenize `varlist' 
   rename `1' hivar

   local pen=1
   gen colorgroup=`pen'
   foreach v of numlist `hivalues' {
   	local pen=mod(`pen',8)+1
   	qui replace colorgroup=`pen' if hivar==`v'
   }
   * list  hivar colorgroup

end
/**********************************************************************************/
program define Computeylablimit, rclass
	version 7
* compute maximum and minimum values for y to define graph region ylab
* If I attempt to draw beyond the graph region the graph may draw triangles instead of parallelograms
	args ystart yend width 

	local ylabmin =0 

	tempvar endmax startmax
	gen `endmax' = `yend'+`width'/2
	gen `startmax'= `ystart' +`width'/2
	qui sum `endmax'
	local ylabmax= r(max)
	qui sum `startmax'
	local max2=r(max)
	if (`max2'>`ylabmax') {
		local ylabmax=`max2'
	} 
	local ylabmax=round(`ylabmax',1)
	
	return local ylabmax `ylabmax'
	return local ylabmin `ylabmin'

end

/**********************************************************************************/
* draw all parallelograms
* each obs has a unique combination of "xstart xend ystart yend". 
* If more than one width`i' have non missing values then the box has more than one colors
* the variables are all passed as options (strings) because using tokenize `varlist' interferes with gph
* Parameters
* xstart xend ystart yend 	(vectors determining 2 midpoints of parallelogram)
* 		start and end of the line segments for the center of the parallelogram
* width 	width`i' contain the width of the parallelogram for color i in 1/9
*		The width of a box is the sum of all the color segements width`i'
* 		to make it appear solid
* range			 : upper value for y 
* ylabmin,ylabmax:  upper and lower ylabels for plotting. These can be slightly wider than range of y 
* 					because of the size of the bars
* xlabnum		 :   needed to construct xlabel
* tlab			 :  needed to construct xlabel; empty unless k>10
* graphx 		 : name of x variable for plotting
* addlabeltext   : string for adding labels:  text("ypos1 xpos1 "text1"  ypos2 xpos2 "text2" [...])
* colorlist		 : alternative user specified list of colors to be used

program define GraphBoxColor
	version 14.2
    syntax  , xstart(str) xend(str) ystart(str) yend(str) width(str)  range(real) graphx(str) ///
	    ylabmin(real) ylabmax(real) xlab_num(str) xsize(real) ysize(real) ///
		[ tlab(str)  colorlist(str) addlabeltext(str) ///
		yline(str)  options(str) ]
  
	tempvar xleft xlag yhigh ylaghigh ylaglow ylow w increment

	if ("`colorlist'"=="")		 local colorlist="black red  blue teal  yellow sand maroon orange olive magenta"

	quietly {
		egen `w'= rsum(`width'*)
		gen `xleft' =  `xstart' 
		gen `xlag' =  `xend' 
		gen `yhigh' = (`ystart' + `w' /2 ) 
		gen `ylaghigh' =  (`yend'   + `w' /2 ) 
		gen `ylaglow' =  (`yend'   -   `w' / 2) 
		gen `ylow' =  (`ystart' -  `w' / 2) 
		gen `increment'=0
	}
	
	local N=_N
	local addplot1 ""

	// for each color
	foreach k of numlist 1/9 { 
		local w_k="`width'`k'"
		capture confirm variable `w_k'
		if !_rc{ 
			/* variable w_k exists*/
			quietly {
				replace `ylaglow' =  (`yend'   -   `w' / 2) 
				replace `ylow' =  (`ystart' -  `w' / 2) 
			}
			local k1=`k'-1

			quietly {
				replace `ylaglow' = `ylaglow' + `increment' 
				replace `ylow' = `ylow'+ `increment' 
				replace `ylaglow'=. if `w_k'==.
				replace `ylow'=. if `w_k'==.
				replace `ylaghigh' = `ylaglow' +  `w_k'
				replace `yhigh' = `ylow' +  `w_k'
			}
				
			*********************************************************************************************
			// draw all parallelograms of one color
			//plot_one_color ,  yhigh(`yhigh') xleft(`xleft')  ylaghigh(`ylaghigh') xlag(`xlag') ///
			//   ylow(`ylow')  ylaglow(`ylaglow') k(`k')
			
			// translate k into a color 
			local color= word("`colorlist'",`k') 

			// for a given color k, plot one parallelogram at a time.			
			foreach i of  numlist 1/`N' {
				
				// for each  graph box
				local yhigh1= `yhigh'[`i']
				local xleft1=`xleft'[`i']
				local ylaghigh1= `ylaghigh'[`i']
				local xlag1= `xlag'[`i']
				local ylow1=`ylow'[`i']
				local ylaglow1=`ylaglow'[`i']
				
				// if graph box is non-missing (checking 1 macro; they should be all missing or all not missing)
				if (`yhigh'[`i']!=. ) {
					// temp variables die at end of a program; therefore define here where the plotting occurs
					tempvar hi`i'`k' lo`i'`k' x`i'`k'
					quietly {
						gen `hi`i'`k''=.
						gen `lo`i'`k''=.
						gen `x`i'`k''=.
					}
					plot_parallelogram `hi`i'`k'' `lo`i'`k'' `x`i'`k'', ///
						yhigh(`yhigh1') x1(`xleft1')  ylaghigh(`ylaghigh1') x2(`xlag1') ///
						ylow(`ylow1')  ylaglow(`ylaglow1') color(`color')
					local temp = r(addplot)
					assert "`temp'"!=""
					// caution : addplot might get tooo long
					if (`"`addplot'"'=="")  	local addplot  `"`temp'"'
					else 						local addplot  `"`addplot' || `temp'"'
				}
			}
			****************************************************************************************************			
			qui replace `increment' = `increment'+ `w_k' if `w_k'!=.   /* for the next round*/
		}
	}
	
	
//di `"  ylab(`ylabmin' `ylabmax') xlab(`xlab_num')  `options' `tlab'  `yline'"'
   


    // most work happens in `addplot' (all parallelograms) and `addlabeltext' (all labels)
	// the rest just sets up the coordinates but plots nothing because msymbol(none)
	// xscale and yscale are explicitly specified because they were needed earlier to compute aspectratio
	twoway scatter std_y `graphx', ///
		ylab(`ylabmin' `ylabmax')  xlab(`xlab_num',valuelabel noticks) ylab(,valuelabel noticks) `tlab'  `yline'     ///
		legend(off) ytitle("") xtitle("") msymbol(none)  ///
		plotregion(style(none)) yscale(off) xscale(noline)   ///
		xsize(`xsize') ysize(`ysize') `options' ||  `addplot' `addlabeltext'
   

end 

///////////////////////////////////////////////////////////////////////////////////////////////////////
//  prepare plotting a single parallelogram: 
//  create command `addplot' and create three variables needed for the plot
program define plot_parallelogram, rclass
	version 14.2
	syntax varlist (min=3 max=3), yhigh(real) ylow(real) x1(real) ylaghigh(real) ylaglow(real) x2(real) [ * ]

	if (`yhigh'==. | `x1'==. | `ylaghigh'==.) {
	  di as error "Bug: Missing values in plot_parallelogram"
	  di "`yhigh';  `ylow'; `x1';  `ylaghigh';  `ylaglow';  `x2' " 
	  exit 
	}
    tokenize `varlist'
	local hi `1'
	local lo `2'
	local x `3'
 
	quietly{
		replace `x'= `x1' in 1
		replace `x'= `x2' in 2
		replace `hi'= `yhigh' in 1
		replace `lo'= `ylow' in 1
		replace `hi'= `ylaghigh' in 2
		replace `lo'= `ylaglow' in 2
	}

	//twoway rarea  `hi' `lo' `x', `options'

	local addplot `"rarea  `hi' `lo' `x', `options'"'
	return local addplot `"`addplot'"'

end
////////////////////////////////////////////////////////
//Version 
//*! 1.0.0   21 February 2003 Matthias Schonlau 
//*! 1.0.1   2 March 2003: Allow variables with one value, Bug fixed when barwidth was too large \ 
//*! 1.0.2   13 March 2003: width changed to right-angle-width
//*! 1.0.3   20 Nov 2003: hivar and hival options implemented \
//*! 1.0.4	 no changes \
//*! 1.0.5	 4 Nov 2008: added samescale option, fixed bug related to >8 colors
//*! 1.1.0    ongoing 2017: major rewrite due to use of twoway rarea for parallelograms
//*! 1.1.1    17 May 2022: added labeltextsize option
//*! 1.1.2    19 May 2022: added argument to samescale option