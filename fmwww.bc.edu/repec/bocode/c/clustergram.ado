program define clustergram
*! 1.1.0 August 2022, replacing Stata 7 graph routine "gph" with twoway rarea

	version 17 
	syntax varlist [if] [in], CLuster(varlist) [ FRaction(real 0.2) ///
	XLAbel(numlist)  COnnect(str) Symbol(str)  ///
	ASPECTratio(real 0.72727) color(str) * ]

	* trap -connect()-, -symbol()- 
	foreach opt in connect symbol {
		if "``opt''" != "" { 
			di as err "`opt'() not supported: please see help" 
			exit 198 
		}	
	} 

	* observations to use 
	marksample touse 
	qui count if `touse' 
	if r(N) == 0  error 2000  

	* check whether jth variable defines j clusters 
	local nc = 0
	foreach v of var `cluster' {
		local nc = `nc' + 1
		tab `v' if `touse', nofreq
		if `nc' != `r(r)' {
			di as txt "Warning: `v' does not define `nc' clusters"
		}
	}
	
	// Aspectratio
	// Stata define aspectratio as height/width of the inner plotregion (see "help aspect"). I chose as default: aspect=4/5.5=0.7272
	// Because it refers to the *inner* plot region, it is not affected by the xlabels at the bottom.
	// aspectratio is explicitly specified in the syntax, but can be overwritten in "*"	
	// Outside of Stata, the aspectratio is often defined the other way around (including in the initial drafts of this program)
	// Therefore defining a second quantity:
	local ar_x= 1/`aspectratio'
	// `xsize' and `ysize' define the whole-graph aspectratio.  `aspect' defines the plot aspect ratio.
	// Stata's default is ysize(4) xsize(5.5)
	// see "help region_options"
	

	preserve 
	qui keep if `touse' 

	tempvar id clustery clmean clmeanlag width clus_nlag 
	gen long `id'  = _n 
	local N = _N
	
	* stack the y variables into one variable clustery.
	tempname clustery  
	local k : word count `varlist' 
	tokenize `varlist' 
	forval i = 1 / `k' { 
		rename ``i'' `clustery'`i' 
	}
	qui reshape long `clustery', i(`id')   

	local max : word count `cluster' 
	
	* for each obs replace the cluster number with the cluster mean
	quietly foreach v of var `cluster' { 
		tempvar clmean
		bysort `v' : egen `clmean' = mean(`clustery')
		local clmeans "`clmeans' `clmean'" 
	} 	

	* data now contain (#id's * #y's) observations 
	* the cluster mean is the same across all y's, can collapse
	* (mean) clustery is not used 
	collapse (mean) `clustery', by(`id' `clmeans')


	* data now contain (#id's) observations and variables: 
	* id, the clmeans, clustery

	* clus_n is the index of clmean
	foreach v of varlist `clmeans' { 
		local args "`args' `v' `id'" 
	}
	stack `args', into(`clmean' `id') clear  
	local clus_n "_stack"
	qui { 
		bysort `id' (`clus_n') : gen `clmeanlag' = `clmean'[_n+1] 
		drop if `clmeanlag' == .
	} 	
	
	* clus_n is important in case there are the same means at 
	* different cluster sizes  
	contract `clmean' `clmeanlag' `clus_n' 
	
	* preparation for graph 
	label var `clus_n' "Number of clusters"  // not needed
	label var `clmean' "Cluster mean"		 // not needed
	
	* set `range' and use it to standardize `width'
	qui summarize `clmeanlag', meanonly 
	local range = r(max) - r(min)

	// Here, width is vertical width. (In the hammock plot, I changed width to orthogonal width
	// before calling GraphBoxColor.)
	qui gen `width' =_freq / `N' * `range' * `fraction'

	if "`xlabel'" == "" { 
		local xlabel "1 (1) `max'" 
		} 

	qui gen `clus_nlag' = `clus_n' + 1

	// adapting to GraphBoxColor, a more general function from hammock.ado
	qui gen colorgroup=1
	local colorlist = "black"
	if ("`color'"!="")  { 
		local colorlist = "`color'" 
	}
	qui summarize `clmeanlag', meanonly 
	local ylabmax=r(max)   // if user supplied ylab and "rectangle", this may not be right
	local ylabmin=r(min)   // if user supplied ylab and "rectangle", this may not be right
	local xrange = `max' -1    // from 1... `max'
	local yrange = `range'     
	local shape="parallelogram"
	//local shape="rectangle"  	// rectangle works when user does not specify ylab
								// width is vertical width; displaying a rectangle does not make sense.
	local addlabeltext=""
	local xlab_num="`xlabel'"    
	local graphx="`clus_n'" 
	qui gen std_y = `clmean'   
	qui gen `width'1= `width'   // we have only one color
	qui drop `width'  			// otherwise  "rsum(`width'*)" will sum over `width' also


	// each obs represents a unique box (with multiple colors)
	// there is one `width' variable for each color: 
	// `width' is the stub of the variable names; `width'i contains the width of color i
	GraphBoxColor , xstart(`clus_n') xend(`clus_nlag') ystart(`clmean') yend(`clmeanlag') ///
	     width(`width')  ylabmax(`ylabmax') ylabmin(`ylabmin') ///
		 aspectratio(`aspectratio') ar_x(`ar_x') xrange(`xrange')  yrange(`yrange') ///
		 xlab_num("`xlab_num'")  graphx("`graphx'") colorlist("`colorlist'") ///
		 shape("`shape'") ///
		 options(`"`options'"') addlabeltext(`"`addlabeltext'"') yline(`"`yline'"') 
	
end
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
// from here on code almost identical to hammock.ado, 
// except:
//  -the shrinkage code block during initialization is blocked out
//  -changes in the final plotting command (titles etc)
/**********************************************************************************/
// compute_addlabeltext (needed for GraphBoxColor)
// input: mat_label_coord arg is a matrix name. Matrix is manipulated. 
//			Manipulations persist after this program closes.
//          In this program the matrix is NOT changed
// label_text: Shakespeare example: label_text="adult@adolescent@child@0@1@2@3@4@5@20@0@1@2@3@4@5@6@7@female@male@"
program  compute_addlabeltext, rclass
	version 16
	syntax , mat_label_coord(str) missing(str) label_text(str) separator(str)

		* the labels are overwriting the plot. Plot before the graphboxes 
		local n_labels = rowsof(`mat_label_coord')
		tokenize `label_text', parse(`separator')
		local addlabeltext="text("   // no space between "text" and "("
		forval j=1/`n_labels' { 
			if (`mat_label_coord'[`j',2] !=0) { 
				/*crucial if matrix has empty rows, otherwise graph disappears*/
				local pos=`j'*2-1  /* positions 1,3,5,7, ...  */
				// text to plot ="``pos''"      y = `mat_label_coord'[`j',1]        x= `mat_label_coord'[`j',2]  
				// the matrix needs to be evaluated as  `=matrixelem'  ; otherwise just the name of the matrix elem appears
				local addlabeltext= `"`addlabeltext' `=`mat_label_coord'[`j',1]' `=`mat_label_coord'[`j',2]' "``pos''" "'
			}
		}
		if (`missing'==1) {
			local addlabeltext= `"`addlabeltext' 0 1 "missing" "'
		}
		* add label options 
		local addlabeltext= `"`addlabeltext',`labelopt')"'
	
		return local addlabeltext=`"`addlabeltext'"' // does not allow empty "" returns
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
program define compute_vertical_width
   version 7
   * compute the difference of the y coordinates needed when width is taken to 
   * mean right-angle width (distance between two parallel lines)
   * ar_x: (aspectratio) how much longer is the x axis relative to the y axis
   * on input : width_y has already been "generate"d 
   * width_y is computed as a result 
   args xstart xend ystart yend width width_y xrange yrange ar_x

   tempvar xdiff ydiff
   qui gen `xdiff'= .
   qui gen `ydiff'= .
   qui replace `xdiff'= (`xend'-`xstart')/`xrange' * `ar_x'
   qui replace `ydiff'= (`yend'-`ystart')/ `yrange'
   qui replace `width_y'=`width' / `xdiff' * sqrt(`xdiff'*`xdiff'+`ydiff'*`ydiff') 

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
   syntax  ,  hivar(varname) HIVALues(numlist missingokay) 

	local pen=1
	qui gen colorgroup=`pen'
	foreach v of numlist `hivalues' {
		local pen=mod(`pen',8)+1
		qui replace colorgroup=`pen' if `hivar'==`v' 
		if ("`v'"==".") {
			qui replace colorgroup=`pen' if  `hivar'==.
		}
	}
	* list  `hivar' colorgroup

end
/**********************************************************************************/
program define Computeylablimit, rclass
	version 7
* compute maximum and minimum values for y to define graph region ylab
* If I attempt to draw beyond the graph region the graph may draw triangles instead of parallelograms
	args ystart yend width 

	local ylabmin =0
	local ylabmax = 100

	tempvar endmax startmax
	qui gen `endmax' = `yend'+`width'/2
	qui gen `startmax'= `ystart' +`width'/2
	qui sum `endmax'
	local ylabmax= r(max)
	qui sum `startmax'
	local max2=r(max)
	if (`max2'>`ylabmax') {
		local ylabmax=`max2'
	} 
	local ylabmax=round(`ylabmax',1)
	
	// compute ylabmin (copied from Tiancheng's code)
	tempvar endmin startmin
	qui gen `endmin' = `yend'-`width'/2
	qui gen `startmin'= `ystart' -`width'/2
	qui sum `endmin'
	local ylabmin= r(min)
	qui sum `startmin'
	local min2=r(min)
	if (`min2'<`ylabmin') {
		local ylabmin=`min2'
	}
	local ylabmin=round(`ylabmin',1)
	
	
	return local ylabmax `ylabmax'
	return local ylabmin `ylabmin'

end

/**********************************************************************************/
* draw all boxes
* each obs has a unique combination of "xstart xend ystart yend". 
* If more than one width`i' have non missing values then the box has more than one colors 
* xstart xend ystart yend 	(vectors determining 2 midpoints of parallelogram)
* 				start and end of the line segments for the center of the parallelogram
* width 		width`i' contain the  width of the parallelogram for color i in 1/9
*				The width of a box is the sum of all the color segments width`i'
*				For parallelogram, this is the vertical width.
*				For rectangles, this is the rightangle width.
* ylabmin,ylabmax:  upper and lower ylabels for plotting. These can be slightly wider 
*					than range of y because of the size of the bars
* aspectratio:   Aspect ratio y/x (stata's definition). 
* ar_x			 Aspect ratio x/y.   (Safer to carry forward than to recompute)
* xrange : 		 #xvars -1. It's safer to carry it forward rather than to recompute it.
* xlabnum		 :   needed to construct xlabel
* graphx 		 : name of x variable for plotting
* addlabeltext   : string for adding labels:  text("ypos1 xpos1 "text1"  ypos2 xpos2 "text2" [...])
* colorlist		 : list of colors to be used
*
* Strategy: 
* For each box, 3 variables (yhigh, ylow, and x) are created. 
* For a parallelogram, they have 2 observations representing beginning and end of the parallelogram
* For a rectangle, need 4 observations for the 4 different x-values for each corner
* The plotting command for each box is added to `addplot'. 
* Thoughts: 
*	-The number of variables could be  greatly reduced by using one set of 3 variables 
*		with many obs rather than many sets of variables with 4 obs. 
*		However, then may have to reset number of observations, 
*		and unclear whether reducing the number of variables improves anything.

program define GraphBoxColor 
	version 14.2
    syntax , xstart(str) xend(str) ystart(str) yend(str) width(str) graphx(str) ///
	    ylabmin(real) ylabmax(real) xlab_num(str) shape(str) ///
		aspectratio(real) ar_x(real) xrange(real) yrange(real) ///
		[  colorlist(str) addlabeltext(str) yline(str)  options(str) ]
  
	tempvar w increment
	qui egen `w'= rsum(`width'*)  // total width of a multi-color box
	qui gen `increment'=0	// sum of w_k before the current color
	
	// initialize, so I can use "replace" later
	tempvar yhigh ylaghigh ylaglow xlow xhigh xlaghigh xlaglow ylow
	foreach var of newlist `xlow' `xhigh' `xlaghigh' `xlaglow' `yhigh' `ylaghigh' `ylaglow' `ylow' {
		qui gen `var'=.
	}
	// when "`shape'"=="rectangle", initialize and shrink x coordinates
	if ("`shape'"=="rectangle") {
		// o_tempvars hold the outer corners of the entire rectangle
		tempvar o_ylow o_yhigh o_ylaglow o_ylaghigh o_xlow o_xhigh o_xlaglow o_xlaghigh 
		foreach var of newlist `o_ylow' `o_yhigh' `o_ylaglow' `o_ylaghigh' `o_xlow' `o_xhigh' ///
			`o_xlaglow' `o_xlaghigh'  {
				qui gen `var'=.
		}
		init_rectangle, xstart(`xstart') xend(`xend') ystart(`ystart') yend(`yend') w(`w') ///
			o_ylow(`o_ylow') o_yhigh(`o_yhigh') o_ylaglow(`o_ylaglow') o_ylaghigh(`o_ylaghigh') ///
			o_xlow(`o_xlow') o_xhigh(`o_xhigh') o_xlaglow(`o_xlaglow') o_xlaghigh(`o_xlaghigh') ///
			xrange(`xrange') yrange(`yrange') ar_x(`ar_x') ylabmin(`ylabmin') ylabmax(`ylabmax')

		// we do not shrink x coordinates for rectangles anymore
        // because we have predefined a global max min yrange
        //shrink_x_coordinates, shape("rectangle") xlow(`o_xlow') xhigh(`o_xhigh') xlaglow(`o_xlaglow') xlaghigh(`o_xlaghigh') ///
        //    yrange(`yrange') ylabmax(`ylabmax') ylabmin(`ylabmin')
	}
	// when "`shape'"=="parallelogram", shrink x coordinates for xstart and xend
	// comment out the whole code block in the else condition if we don't want this behaviour
/*  This shrink code block from hammock.ado does not work for the clustergram. 
	else{
	    tempvar xstart_shrinked xend_shrinked
	    qui gen `xstart_shrinked'=.
	    qui gen `xend_shrinked'=.
	    shrink_x_coordinates, shape("parallelogram") xlow(`xstart_shrinked') xhigh(`xstart') xlaglow(`xend_shrinked') xlaghigh(`xend') ///
                    yrange(`yrange') ylabmax(`ylabmax') ylabmin(`ylabmin')
        qui replace `xstart'=`xstart_shrinked'
        qui replace `xend'=`xend_shrinked'

	}
*/

	local N=_N
	local addplot1 ""

	// for each color
	foreach k of numlist 1/9 { 
		// draw all parallelograms of one color 
		local w_k="`width'`k'"
		capture confirm variable `w_k'
		if !_rc{ 
			/* variable w_k exists*/
			if "`shape'"=="parallelogram" {
				compute_4corners_parallelogram,  increment(`increment') w_k(`w_k') w(`w') ///
					ystart(`ystart') yend(`yend')  xstart(`xstart') xend(`xend') ///
					ylow(`ylow') yhigh(`yhigh') ylaglow(`ylaglow') ylaghigh(`ylaghigh') ///
					xlow(`xlow') xhigh(`xhigh') xlaglow(`xlaglow') xlaghigh(`xlaghigh')  
			}
			else if "`shape'"=="rectangle" {
				compute_4corners_rectangle,  increment(`increment') w_k(`w_k') w(`w') ///
					o_ylow(`o_ylow') o_yhigh(`o_yhigh') o_ylaglow(`o_ylaglow') o_ylaghigh(`o_ylaghigh') ///
					o_xlow(`o_xlow') o_xhigh(`o_xhigh') o_xlaglow(`o_xlaglow') o_xlaghigh(`o_xlaghigh') ///
					ylow(`ylow') yhigh(`yhigh') ylaglow(`ylaglow') ylaghigh(`ylaghigh') ///
					xlow(`xlow') xhigh(`xhigh') xlaglow(`xlaglow') xlaghigh(`xlaghigh')
			}
			else {
				di as error "Unrecognized shape (2)"
				exit
			}

			
			// translate k into a color 
			local color= word("`colorlist'",`k') 

			// for a given color k, plot one parallelogram at a time.			
			foreach i of  numlist 1/`N' {
				
				// for each  graph box
				local yhigh1= `yhigh'[`i']
				local ylaghigh1= `ylaghigh'[`i']
				local ylow1=`ylow'[`i']
				local ylaglow1=`ylaglow'[`i']
				local xhigh1= `xhigh'[`i']
				local xlaghigh1= `xlaghigh'[`i']
				local xlow1=`xlow'[`i']
				local xlaglow1=`xlaglow'[`i']
				
				// if graph box is non-missing (checking 1 macro; they should be all missing or all not missing)
				if (`yhigh'[`i']!=. ) {
					// temp variables die at end of a program; therefore define here where the plotting occurs
					tempvar hi`i'`k' lo`i'`k' x`i'`k'
					quietly {
						gen `hi`i'`k''=.
						gen `lo`i'`k''=.
						gen `x`i'`k''=.
					}
					if ("`shape'"=="parallelogram") { 
						// still using this because it's a little faster than quadrangle
						// for entire hammock.ado speed advantage using this routine is 1%-6%
						plot_parallelogram `hi`i'`k'' `lo`i'`k'' `x`i'`k'', ///
							yhigh(`yhigh1') ylaghigh(`ylaghigh1') x1(`xlow1') x2(`xlaglow1') ///
							ylow(`ylow1')  ylaglow(`ylaglow1') color(`color')
					}
					else {						
						// works for both general quadrangles and for parallelogram as a special case
						plot_quadrangle `hi`i'`k'' `lo`i'`k'' `x`i'`k'', color(`color') ///
							xhigh(`xhigh1') yhigh(`yhigh1') ///	     
							xlow(`xlow1') ylow(`ylow1') ///
							xlaghigh(`xlaghigh1') ylaghigh(`ylaghigh1') ///
							xlaglow(`xlaglow1') ylaglow(`ylaglow1') 
					}
					local temp = r(addplot)
					assert "`temp'"!=""
					// caution : addplot might get tooo long
					if (`"`addplot'"'=="")  {
						local addplot  `"`temp'"'
					}
					else {
				 		local addplot  `"`addplot' || `temp'"'
					}
			}						
			qui replace `increment' = `increment'+ `w_k' if `w_k'!=.   // for the next color
		}
	}
	
    // *most work happens in `addplot' (all parallelograms) and `addlabeltext' (all labels)
	// the rest just sets up the coordinates but plots nothing because msymbol(none)
	// *xscale and yscale are explicitly specified because they were needed earlier to compute aspectratio
	// *The twoway command cannot be moved up to the caller program because the caller program does not have 
	// 	access to the many (e.g.200) variables used in `addplot'

    /* 
	//for debugging: This helps seeing the frame in the plot area on which aspectratio is built.
	twoway scatter std_y `graphx', ///
		ylab(`ylabmin' `ylabmax')  xlab(`xlab_num',) ylab(,valuelabel)  `yline'     ///
		legend(off) ytitle("") xtitle("") msymbol(none)  ///
		plotregion(lstyle(dashed) m(zero) ) yscale(on)  ///
		aspect(`aspectratio') `options'  ||  `addplot' `addlabeltext'
	*/

	twoway scatter std_y `graphx', ///
		xlab(`xlab_num')  `yline'     ///
		ytitle("Cluster mean") xtitle("Number of clusters")  ///
		legend(off) msymbol(none)  ///
		plotregion(style(none)) ///
		aspect(`aspectratio') `options'  ||  `addplot' `addlabeltext'

		// removing: plotregion(m(zero))     // needed for rectangle because of aspectratio 

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
	
	// restricting to two obs "in 1/2" can reduce speed by  ~25%
	local addplot `"rarea `hi' `lo' `x' in 1/2, `options'"'
	return local addplot `"`addplot'"'

end
///////////////////////////////////////////////////////////////////////////////////////////////////////
//  prepare plotting a single quadrangle  (can be used for rectangles)
//  create command `addplot' and create three variables needed for the plot
//  varlist has only 3 variables, because rarea only needs 3 variables
program define plot_quadrangle, rclass
	version 17.0
	syntax varlist (min=3 max=3), ///
		xhigh(real) yhigh(real) ///	     
		xlow(real) ylow(real) ///
		xlaghigh(real) ylaghigh(real) ///
		xlaglow(real) ylaglow(real)  [ * ]

	if (`yhigh'==. | `xhigh'==. | `ylaghigh'==.) {
	  di as error "Bug: Missing values in plot_quadrangle"
	  di "`yhigh';  `ylow'; `xhigh';  `ylaghigh';  `ylaglow';  `xlaghigh' " 
	  exit 
	}
    tokenize `varlist'
	local yhi `1'
	local ylo `2'
	local x `3'

	if (`yhigh' <= `ylaghigh'){

        // compute y2hi, the missing upper point for the first sub-area
        slopes, xleft(`xhigh') yleft(`yhigh')  xright(`xlaghigh') yright(`ylaghigh')
        local y2hi= `=r(intercept)' + `=r(slope)' * `xlow'

        // compute y3lo, the missing lower point for the third sub-area
        slopes, xleft(`xlow') yleft(`ylow')  xright(`xlaglow') yright(`ylaglow')
        local y3lo= `=r(intercept)' + `=r(slope)' * `xlaghigh'

        // for each x-value, give the upper and lower y-values of the area (could be identical)
        quietly{
            replace `x'= `xhigh' in 1
            replace `yhi'= `yhigh' in 1
            replace `ylo'= `yhigh' in 1

            replace `x'= `xlow' in 2
            replace `yhi'= `y2hi' in 2
            replace `ylo'= `ylow' in 2

            replace `x'= `xlaghigh' in 3
            replace `yhi'= `ylaghigh' in 3
            replace `ylo'= `y3lo' in 3

            replace `x'= `xlaglow' in 4
            replace `yhi'= `ylaglow' in 4
            replace `ylo'= `ylaglow' in 4
        }
    }
    else{
        // compute y2hi, the missing upper point for the first sub-area
        slopes, xleft(`xlow') yleft(`ylow')  xright(`xlaglow') yright(`ylaglow')
        local y2low= `=r(intercept)' + `=r(slope)' * `xhigh'

        // compute y3lo, the missing lower point for the third sub-area
        slopes, xleft(`xhigh') yleft(`yhigh')  xright(`xlaghigh') yright(`ylaghigh')
        local y3high= `=r(intercept)' + `=r(slope)' * `xlaglow'

        // for each x-value, give the upper and lower y-values of the area (could be identical)
        quietly{
            replace `x'= `xlow' in 1
            replace `yhi'= `ylow' in 1
            replace `ylo'= `ylow' in 1

            replace `x'= `xhigh' in 2
            replace `yhi'= `yhigh' in 2
            replace `ylo'= `y2low' in 2

            replace `x'= `xlaglow' in 3
            replace `yhi'= `y3high' in 3
            replace `ylo'= `ylaglow' in 3

            replace `x'= `xlaghigh' in 4
            replace `yhi'= `ylaghigh' in 4
            replace `ylo'= `ylaghigh' in 4
        }
    }

	//twoway rarea  `yhi' `ylo' `x', `options'
	
	local addplot `"rarea `yhi' `ylo' `x' in 1/4, `options'"'
	return local addplot `"`addplot'"'

end

////////////////////////////////////////////////////////
program shrink_x_coordinates
	version 17
    syntax, shape(str) xlow(str) xhigh(str) xlaglow(str) xlaghigh(str) ///
		yrange(real) ylabmax(real) ylabmin(real)

    local ymaxmin_diff= (`ylabmax'-`ylabmin') 
    // the case for rectangle is currently deprecated: we do not shrink x coordinates for rectangles anymore
    // because we have predefined a global max min yrange
    if "`shape'"=="rectangle" {

        // Calculate the middle points for each pair of xs
        // mid points will be the center for the shrinkage
        tempvar xdiff_xhigh_xlaglow xdiff_xlow_xlaghigh xmid
        gen `xdiff_xhigh_xlaglow' = abs(`xlaglow' - `xhigh')
        gen `xdiff_xlow_xlaghigh' = abs(`xlaghigh' - `xlow')
        gen `xmid' =  `xhigh' + `xdiff_xhigh_xlaglow' / 2

        // Calculate the scale ratio
        // The ratio is the proportion for the shrinkage
        // The ratio is calculated based on the expected yrange and the actual yrange which is ylabmax-ylabmin
        local ratio = `yrange'/`ymaxmin_diff'

        // shrink the horizontal size of the plot by shrinking the x coordinates to the mid points by the
        // ratio calculated above
        qui replace `xhigh' = `xmid' - `xdiff_xhigh_xlaglow'*`ratio'/2
        qui replace `xlaglow' = `xmid' + `xdiff_xhigh_xlaglow'*`ratio'/2
        qui replace `xlow' = `xmid' - `xdiff_xlow_xlaghigh'*`ratio'/2
        qui replace `xlaghigh' = `xmid' + `xdiff_xlow_xlaghigh'*`ratio'/2

    }
    else {
        // Calculate the middle points for each pair of xs
        // mid points will be the center for the shrinkage
        tempvar xdiff xmid
        gen `xdiff' = abs(`xlaghigh' - `xhigh')
        gen `xmid' =  `xhigh' + `xdiff' / 2

        // Calculate the scale ratio
        // The ratio is the proportion for the shrinkage
        // The ratio is calculated based on the expected yrange and the actual yrange which is ylabmax-ylabmin
        local ratio = `yrange'/`ymaxmin_diff'

        // shrink the horizontal size of the plot by shrinking the x coordinates to the mid points by the
        // ratio calculated above

        // in the case of parallelogram, xlow and xlaglow are placeholder for the empty vars which will be
        // used to update the xstart and xend
        qui replace `xlow' = `xmid' - `xdiff'*`ratio'/2
        qui replace `xlaglow' = `xmid' + `xdiff'*`ratio'/2
    }


end

////////////////////////////////////////////////////////
// compute the "outer" corners of a multi-color rectangle
// input: 	xstart, xend, ystart, yend, w 
//			reals: xrange, ylabmin ylabmax, ar_x  (needed to compute alpha's)
// output: 	o_ylow o_yhigh o_ylaglow o_ylaghigh 
//			o_xlow o_xhigh o_xlaglow o_xlaghigh 
	// Notation as used in the paper's appendix : 
	// B' = o_ylow , o_xlow
	// A'=  o_yhigh, o_xhigh
	// M= xstart, ystart 
	// AC=w
	// A,B,C,E  do not have existing variables and need be computed
	// xend, yend have no corresponding letter, but it's the middle between Afar and Cfar
// note convert:  degrees = radians * 180/_pi 
program init_rectangle
	version 17
	syntax, xstart(str) xend(str) ystart(str) yend(str) w(str) ///
		o_ylow(str) o_yhigh(str) o_ylaglow(str) o_ylaghigh(str) ///
		o_xlow(str) o_xhigh(str) o_xlaglow(str) o_xlaghigh(str) ///
        xrange(real) yrange(real) ylabmin(real) ylabmax(real) ar_x(real)
			
	// y  (~0..~100) has a different scale than x (1..#xvar-1)
	// When plotting, use the variables on their usual scale
	// For computations with angles, need to account for the different scales and aspectratio
	// the angle refers to the physical distance on the plot, not to distances with different ranges in x and y
	
	// compute alpha, cosalpha, sinalpha, for each graph box
	tempvar deltax deltay alpha cosalpha sinalpha 
	qui gen `alpha'=.
	qui gen `cosalpha'=.   // cos(alpha)
	qui gen `sinalpha'=.   // sin(alpha)
	// deltax and deltay are not the physical scatter plot distance, but const multiplier cancels in ratio
	// need to calculate the y max and min difference for standardize delta y
	local ymaxmin_diff= (`ylabmax'-`ylabmin')
	qui gen `deltax'= (`xend'-`xstart')/`xrange' *`ar_x' //same calc as in compute_vertical_width
	qui gen `deltay'= (`yend'-`ystart')/`ymaxmin_diff'   			 	//same calc as in compute_vertical_width

	// Loop because trigonometric functions don't take variables as arguments. 
	// (could convert to a matrix as an alternative.)
	// Alpha appears correct; The default layout atan(5.5/4) = 54 degrees which is similar to simple example
	foreach i of numlist 1/`=_N' { 
		local ratio= `deltay'[`i']/`deltax'[`i']  
		qui replace `alpha' = atan(`ratio')  in `i' //alpha is in radians
		qui replace `cosalpha'=cos(`alpha'[`i']) in `i'
		qui replace `sinalpha'=sin(`alpha'[`i']) in `i'
	}
	
	quietly{
		tempvar vertical_w 
		gen `vertical_w'= `w' / `cosalpha'   // alpha must be in radians

		// A
		tempvar ax ay
		gen `ax' = `xstart'
		gen `ay' = `ystart' + 0.5 * `vertical_w'

		// B
		tempvar bx by
		gen `bx' = `xstart'
		gen `by' = `ystart' - 0.5 * `vertical_w'

		// C 
		tempvar cx cy

		// sinalpha was computed on scaled w, scaled cx.
		// Unscaling is achieved by replacing:  cx_scaled = cx/ xrange *ar_x ,etc.
		// for y the unscaling cancels out	
		gen `cx' = `ax'+ `w'*`sinalpha'  /`ymaxmin_diff' * `xrange'/`ar_x'
		gen `cy' = `ay'- `w'*`cosalpha'

		// E  
		tempvar ex ey 
		gen `ex' = (`ax' + `cx')/2
		gen `ey' = (`ay' + `cy')/2

		// A'  
		replace `o_xhigh' =  `ax' + `xstart' - `ex' 
		replace `o_yhigh' =  `ay' + `ystart' - `ey'

		// C'  
		replace `o_xlow' =  `cx' + `xstart' - `ex'  
		replace `o_ylow' =  `cy' + `ystart' - `ey'

		// "Afar"  Starting from the far midpoint , go up 
		replace `o_xlaghigh' = `xend' + (`o_xhigh' - `xstart')
		replace `o_ylaghigh' = `yend' + (`o_yhigh' - `ystart') 

		// "Cfar"  Starting from the far midpoint , go down
		replace `o_xlaglow' = `xend' - (`o_xhigh' - `xstart')
		replace `o_ylaglow' = `yend' - (`o_yhigh' - `ystart')
	}
	
	// for debugging: look at one box (=observation) at a time
	// this only works for default aspect ratio
	/*
	local box=1
	twoway scatteri `=`ay'[`box']' `=`ax'[`box']'  "A"  ///
					`=`by'[`box']' `=`bx'[`box']'  "B"  ///
					`=`cy'[`box']' `=`cx'[`box']'  "C"  ///
					`=`ey'[`box']' `=`ex'[`box']'  "E"  ///
					`=`o_ylow'[`box']' `=`o_xlow'[`box']'  "o_low"  ///
					`=`o_yhigh'[`box']' `=`o_xhigh'[`box']'  "o_high"  ///
					`=`o_ylaglow'[`box']' `=`o_xlaglow'[`box']' (9) "o_laglow"  ///
					`=`o_ylaghigh'[`box']' `=`o_xlaghigh'[`box']' (9) "o_laghigh" ///
					`=`yend'[`box']' `=`xend'[`box']' (9) "Mid end" ///
					, name(box`box', replace) plotr(m(zero)) ///
					ytitle("") xtitle("") 
	// view using  "graph display box<#>"
	*/
end
////////////////////////////////////////////////////////
// compute a,b in simple linear regression
// opted not to use "regress" because that requires variables 
//    and I would use preserve/ restore which is too slow
program slopes , rclass
   version 17
   syntax , xleft(real) xright(real) yleft(real) yright(real)

   local n=2 // sample size 
   local sumx= `xleft'+`xright'
   local sumy= `yleft'+`yright'
   local sumxsqr= (`xleft')^2+(`xright')^2
   local crossxy = `xleft'*`yleft'+`xright'*`yright'

   local num= `n' * `crossxy' - (`sumx' * `sumy')
   local denum=`n'*`sumxsqr' - (`sumx')^2
   local b=`num'/`denum'
   local a=(`sumy' - `b'*`sumx' )/`n'
   
   return local slope `b'
   return local intercept `a'
end
///////////////////////////////////////////////////////////////////
// compute coordinates of 4 corners for all graph boxes of the same color
// each obs has a unique combination of "xstart xend ystart yend" (multi-color box)
// but this program only deals with the color specified by w_k
// input: 
// w_k: 	name of width variable for color k. 
// w:		total width of a graph box (across all colors)
// increment: sum of w_k for all previous (k-1) colors
// ystart, yend, xstart, xend: names of input coordinates 
// other strings are names of output coordinates of 4 corners
program compute_4corners_parallelogram 
	version 17
	syntax , increment(str) w_k(str) w(str) ///
		ystart(str) yend(str) xstart(str) xend(str) ///
		ylow(str) yhigh(str) ylaglow(str) ylaghigh(str) ///
		xlow(str) xhigh(str) xlaglow(str) xlaghigh(str) 
	
	quietly {
		replace `ylaglow' =  (`yend'   -   `w' / 2)  // outer lower corner
		replace `ylow' =  (`ystart' -  `w' / 2)    // outer lower corner
		replace `ylaglow' = `ylaglow' + `increment' 
		replace `ylow' = `ylow'+ `increment' 
		replace `ylaglow'=. if `w_k'==.
		replace `ylow'=. if `w_k'==.
		replace `ylaghigh' = `ylaglow' +  `w_k'
		replace `yhigh' = `ylow' +  `w_k'
		replace `xhigh'=`xstart'  // for parallelogram xhigh and xlow  are the same
		replace `xlow'=`xstart'
		replace `xlaghigh'=`xend'  // for parallelogram xlaghigh and xlaglow  are the same
		replace `xlaglow'= `xend'
	}
end 
///////////////////////////////////////////////////////////////////////////////////////////
// compute corners of an inside rectangle for color k
// strategy:
// a) (previously) compute the outer 4 corners (o_*) of the whole multi-color box 
// b) compute 2 left corners for the current box
//	  by moving `increment'/`w' along the vector (o_xlow,o_ylow)->(o_xhigh,o_yhigh) 
//	  compute 2 right corners for the current box
//	  by moving (`increment'+`w_k')/`w' along the vector (o_xlow,o_ylow)->(o_xhigh,o_yhigh)
// This program is called once per color
// input : coordinates of the outer rectangle (multi-color box)
// output: coordinates of the inner rectangle for color `k' , or missing if w_k==. 
program compute_4corners_rectangle
	version 17
	syntax , increment(str) w_k(str)  w(str) ///
		ylow(str) yhigh(str) ylaglow(str) ylaghigh(str) ///
		xlow(str) xhigh(str) xlaglow(str) xlaghigh(str) ///
		o_ylow(str) o_yhigh(str) o_ylaglow(str) o_ylaghigh(str) ///
		o_xlow(str) o_xhigh(str) o_xlaglow(str) o_xlaghigh(str) 
	
	quietly {
		// lower left 
		replace `xlow' = `o_xlow'+ `increment'/`w' * (`o_xhigh'-`o_xlow')
		replace `ylow' = `o_ylow'+ `increment'/`w' * (`o_yhigh'-`o_ylow')
		replace `ylow'=. if `w_k'==.  
		// upper left 
		replace `xhigh' = `o_xlow'+ (`increment'+`w_k')/`w' * (`o_xhigh'-`o_xlow')
		replace `yhigh' = `o_ylow'+ (`increment'+`w_k')/`w' * (`o_yhigh'-`o_ylow')
		// lower right 
		replace `xlaglow' = `o_xlaglow'+ `increment'/`w' * (`o_xlaghigh'-`o_xlaglow')
		replace `ylaglow' = `o_ylaglow'+ `increment'/`w' * (`o_ylaghigh'-`o_ylaglow')			
		replace `ylaglow'=. if `w_k'==.
		// upper right 
		replace `xlaghigh' = `o_xlaglow'+ (`increment'+`w_k')/`w' * (`o_xlaghigh'-`o_xlaglow')
		replace `ylaghigh' = `o_ylaglow'+ (`increment'+`w_k')/`w' * (`o_ylaghigh'-`o_ylaglow')	
	}
end
///////////////////////////////////////////////////////////////////////////////////////////
// colorlist should not be smaller than number of values in hivalues + 1 (default color)
program define check_sufficient_colors
	version 16
	syntax,  [ hivar(str) HIVALues(numlist missingokay)  COLorlist(str) ] 

	if ("`hivar'"!="" & "`colorlist'"!="") {
		local hicount: word count `hivalues'
		local colcount: word count `colorlist'
		if (`colcount'<`hicount'+1) {
			di as error " There are not enough colors for highlighting. "
			di as error "(The first color is the default color and is not used for highlighting.)"
			error 2000
		}
	}
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// purpose :  	transform variables to have a range between 0 and 100, 
//				compute corresponding label positions
// output: variables in varlist changed (we are in "preserve" mode, so changes disappear at the end)
// output: label_coord matrix changed if labels are used
// note: miss is an int; previously option missing was present/absent
program transform_variable_range 
	version 16.0
	syntax varlist ,  addlabel(int) same(int) mat_label_coord(str) miss(int) rangeexpansion(real) [ samescale(varlist) ]

	* compute max,min values over the variables specified in samescale
	if `same' {
		globalminmax `samescale' 
		local globalmax=r(globalmax)
		local globalmin=r(globalmin)
		local globalrange=`globalmax'-`globalmin'
	}

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
		if (`miss') {
			* missing option specified 
			local yline "yline(4, lcolor(black))" // horizontal line to separate missing values; number depends on range expansion
			local missval=`min'-`rangeexpansion'*`range'
			qui replace `v'=`missval' if `v'==.
			local min=`missval'  /* redefine minimum value and range */
			local range=`range'*(1+`rangeexpansion')
		}	
		local my_y  "std_y`i'"
		qui gen `my_y' = (`v'-`min')/ `range' * 100
		
		if `addlabel'==1 {
			local n_labels = rowsof(`mat_label_coord') 
			forval ii = 1 / `n_labels' {
				if (`mat_label_coord'[`ii',2]==`i') { 
					/* label belongs to variable `v' */
					matrix `mat_label_coord'[`ii',1]= (`mat_label_coord'[`ii',1] -`min')/ `range' * 100
				}
			}
		}
		
	} 	
end
///////////////////////////////////////////////////////////////////////////////////////////////
// version history
//*! 1.0.0 August 1, 2002 Matthias Schonlau 
//*! 1.0.1 May 8, 2003, label of y axis changed if k==1 
//*! 1.1.0 August 2022, replacing Stata 7 graph routine "gph" with twoway rarea
