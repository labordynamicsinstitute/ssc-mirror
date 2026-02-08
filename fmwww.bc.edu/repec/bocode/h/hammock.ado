program define hammock
*! 2.2.0   Jan 30, 2026: added labeling options: label_methodlist(), label_too_many(), new default colorlist
	syntax varlist [if] [in], [ ///
		Missing missing_fraction(real .1) ///
		BARwidth(real 1) MINBARfreq(int 1) ///
		hivar(str) HIVALues(string) /// 
		SPAce(real -1.0)  subspace(real 0.8) ///
		noLABel labelopt(str) label_methodlist(str) ///
		label_min_dist(real 3.0) label_too_many(int 8) label_format(str) ///
		SAMEscale(varlist)  ///
		noUNIbar uni_fraction(real .5) uni_colorlist(str) ///
		SHOWaxes ///
		ASPECTratio(real 0.72727) COLorlist(str) shape(str) outline  * ]

	foreach v of local varlist {
		capture confirm numeric variable `v'
		if _rc {
			//action for string variables
			di as error `"Variable "`v'" is not numeric. Please encode it first: "'
			di as error "   encode `v', gen(new_varname)"
			error 99
		}
	}

	local missing = "`missing'" != ""
	local missing_value=5  // label_coord[.,3]=`missing_value' to indicate missing values for that category
	local addlabel= 1- ("`label'" == "nolabel") //options that start with "no" have different syntax 
	local adduni= 1- ("`unibar'" == "nounibar") //options that start with "no" have different syntax 
	local showaxes = ("`showaxes'" == "showaxes") 
	local same = "`samescale'" !=""
	local outline = "`outline'" != "" 

	if ("`shape'"=="") local shape="rectangle"
	if ("`shape'"=="par") local shape="parallelogram"  // par is an abbreviation

	// percentage of space given to univariate bars/text as opposed to the graph
	if (`addlabel' | `adduni') & `space'==float(-1) {
		local space=0.3   // if space needed, default space 
	}
	else if `space'==float(-1) {
		local space=0  // if space not needed
	}
																		
	parse_hivalues, hivalues("`hivalues'") hiprefix("") 
	local hiprefix = r(hiprefix)  // if missing, this assigns hiprefix="."
	local hivalues = r(hivalues)  // caution : overwrites hivalues
	
	* observations to use 
	marksample touse , novarlist
	qui count if `touse' 
	if r(N) == 0 { 
		error 2000 
	} 

	preserve 
	qui keep if `touse' 
	tempvar id std_ylag width graphxlag colorgroup 
	tempname label_coord uni_matrix 
	qui gen long `id'  = _n 
	local N = _N
	local label_text="label_text"   // defines the variable to be used in frame connectors
	
	// Aspectratio
	// see "help region_options", "help aspect_option", see Glossary in Graphics manual
	// `xsize' and `ysize' define the whole-graph (*available area*) aspectratio.  
	// 		Stata's default up to version 17 was  ysize(4) xsize(5.5)
	// 		In Stata 18, the default scheme switched to stcolor ysize(4.5) and xsize(7.5), aspect= 0.8181,
	//		but I found leaving the old default, aspect=0.7272, used the available space better
	// `aspect' defines the *plot region* aspect ratio.
	// Stata defines aspect ratio as: height/width (rather than the other way around)
	// I chose as default: aspect=ysize/xsize=4/5.5=0.7272 ,
	//		i.e. I chose that the *plot region* has the same aspect ratio as the *available area*.) 
	// Outside of Stata, aspectratio is often defined the other way around 
	//		(including in initial versions of hammock.ado)
	// Therefore defining a second quantity:
	local ar_x= 1/`aspectratio'
	// aspectratio is explicitly specified in the syntax, but can be overwritten in "*"	
	// The aspectratio(#) option constrains the ratio of the *plot region* to #. 
	// The eventual plotting command below uses 
	//    plotregion(style(none) m(zero)) aspect(`aspectratio')
	// 		Because of margin(0): outer plotregion=inner plotregion
	
	// if "missing" not specified, drop observations with missing values
	// do this before range transformation; or else obs may generate labels for non-missing x-vars, but obs are later removed
	if (`missing'==0) {
		foreach v of var `varlist' { 
			qui drop if `v'==.
		}
	}

	local k : word count `varlist' 
	local max=`k'
	tokenize `varlist' 

	if "`hivar'"!=""  check_hivalues_exist, hivar(`hivar') hivalues(`"`hivalues'"')  hiprefix(`hiprefix')
	update_colorlists, colorlist(`"`colorlist'"') uni_colorlist(`"`uni_colorlist'"') miss(`missing') ///
		hivar(`hivar') hivalues("`hivalues'")
	local uni_colorlist= r(uni_colorlist) 
	local colorlist= r(colorlist)  // if all values highlighted, first color removed
	local highlight_all_levels=r(highlight_all_levels)
	
	/*generate colorgroup variable for highlighting*/
	/*later, missval replaces "." , so gen_colorgroup needs to go before*/
	if "`hivar'"!=""    qui gen_colorgroup , hivar(`hivar') hivalues(`hivalues') hiprefix(`hiprefix') ///
												highlight_all_levels(`highlight_all_levels')
	else 				qui gen colorgroup=1
	qui tab colorgroup
	local ncolors=r(r) // number of colors
	
	cap frame drop connectors
	frame create connectors   // only used if `addlabel' | `adduni'; but safer to create always
	if (`addlabel'==1 | `adduni') {		
		list_labels `varlist', label_text(`label_text') missing(`missing')  ///
			label_format(`"`label_format'"') missing_value(`missing_value')
		matrix `label_coord'= r(label_coord)  // coordinates of all labels, Excluding missing values	
		create_uni_matrix `varlist', ncolors(`ncolors') colorvar("colorgroup") missing(`missing') ///
			minbarfreq(`minbarfreq')		//univariate frequencies for each bar (separate by color)
		matrix `uni_matrix' = r(uni_matrix) 
		create_varlabel_method `varlist', too_many_levels(`label_too_many') label_methodlist(`label_methodlist')
	}
	

	* transform variables' range to be between 0 and 100, also adjust matrix w label coordinates
	// Note this computes the midpoints (between 0 and 100), the upper/lower points may be a little wider
	// Missing values after standardization (std_y) equal 0
	local std_y="std_y" // stub name of variables created
	local eps= 0  // adjust coordinates away from 0, 10, 100 by eps so that labels and bivariate bars print more nicely.
				  // not used for unibars cause for numerical vars may have values between 10 and 10+eps
				  // not used for bivariate bars: (or else bars don't connect to unibars )
				  // not used for labels : separate label_eps for labels
	if `same' local addtmp = `"samescale(`samescale')"'  // if `same' specify this option
	// subroutine changes `label_coord' 
	transform_variable_range `varlist', same(`same') addlabel(`addlabel') adduni(`adduni') std_y("`std_y'") ///
		missing_fraction(`missing_fraction') mat_label_coord("`label_coord'") miss(`missing') `addtmp'
	if (`addlabel' | `adduni') adjust_mat_label_coord,  eps(`eps') mat_label_coord("`label_coord'") ///
			miss(`missing') missing_fraction(`missing_fraction')	
	adjust_std_y  `std_y'* , eps(`eps')  miss(`missing') missing_fraction(`missing_fraction')	
	
    if (`addlabel' | `adduni')  decide_plot_label, mat_label_coord(`label_coord') /// 
		min_distance(`label_min_dist') missing_value(`missing_value') miss(`missing') missing_fraction(`missing_fraction')

	* construct xlabel
	local i=1
	foreach v of var `varlist' {
		local xl "`xl' `i'" 
		local lbl : variable label ``i''
		if ("`lbl'"=="") {  //if no label
			local xlabel `"`xlabel' `i' ``i''"'  // use variable name
		}
		else { // if label exists
			local xlabel `"`xlabel' `i' "`lbl'""'  //  use variable label
			//assume label `lbl' does not already have a set of quotes " "
			//i.e. we would get an error for the unlikely definition:  label var  x1 `""one" "two""'
		}
		local i = `i' + 1
	}
	local xlab_num "`xl'"


	* transform the data from one obs per data point to one obs per graphbox 
	* using reshape and contract

	* variables yvar need be listed std_y1 std_y2 std_y3 etc.   
	// "std_y" is a stub only; cannot replace by a tempvariable
	// at this point the variables in varlist are not going into long form and are lost
	qui reshape long std_y, i(`id') 
	keep std_y `id' _j colorgroup 

	* graphx is the variable index of std_y
	local graphx "_j"

	qui { 
		bysort `id' (`graphx') : gen `std_ylag' = std_y[_n+1] 
		drop if `std_ylag' == .  /*last variable doesn't connect to variable after it*/
	} 	

	* graphx is important for unique identification 
	* contract creates _freq variable
	contract std_y `std_ylag' `graphx' colorgroup
	qui replace _freq=max(`minbarfreq',_freq)


	*** preparation for graph 

	* compute `width' :  refers to a percentage of `range'
	summarize `std_ylag', meanonly 
	local range = r(max) - r(min)
	// Barwidth is a multiplicative increase from 0.2
	qui gen `width' =_freq / `N' * `range' * 0.2* `barwidth' 
	
	//reshape: previously each obs represented unique (box,color) combination
	//now each obs represents a unique box (with multiple colors). 
	// color variables contain the width of the color and are missing otherwise
	keep  `width' colorgroup `graphx' std_y `std_ylag' 
	qui reshape wide `width', j(colorgroup) i(`graphx'  std_y `std_ylag')

	tempvar x xlag
	qui gen `x'=`graphx'   // keep to identify x-variables for placement adjustment
	qui  gen `xlag'=`graphx'+ 1
	* make room for labels in between rectangles
	qui gen `graphxlag'= `graphx'+ (1-`space'/2)
	if (`space'>0)	{ 
		qui replace `graphx'= `graphx' + `space'/2 
	}
	
	// in trivial cases there may be fewer than 4 boxes. 
	// 4 obs are needed for the rectangle vars
	if (_N<4)  qui set obs 4 


	// labels + univariate bars
	label var `graphx' " "
	label var std_y " "
	lab define myxlab `xlabel'
	lab values  `graphx' myxlab
	tempvar  yhi_uni ylo_uni x_uni color_uni // init univariate bars
	qui gen `yhi_uni'=.
	qui gen `ylo_uni'=. 
	qui gen `x_uni'=.
	qui gen `color_uni'=.
	local uni_width= `subspace'  *`space'

	*xrange
    if (`adduni') { 
		local xrange= (`k'-1)+`uni_width'   // range expanded to accomodate left and right space of uni_bar
	}
	else {
		local xrange= `k'-1   // number of x variables-1==xrange 
		// when using shape(rectangle), the rectangle can protrude lower than 1 and higher than `k' and be a little off.
		// when plotting labels but not unibar, a long label does *not* distort xrange; longer labels are reach beyond axes
	}

	/*	
	list_connectors,  xstart(`graphx') xend(`graphxlag') ystart(std_y) yend(`std_ylag') ///
			width(`width') uni_ylo(`ylo_uni') uni_yhi(`yhi_uni') uni_x(`x_uni') ///
			uni_color(`color_uni') 
	*/
	
	if (`adduni') {
		add_unibars `yhi_uni' `ylo_uni' `x_uni' `color_uni', mat_label_coord(`label_coord') ///
			mat_uni(`uni_matrix') uni_fraction(`uni_fraction') ncolors(`ncolors') missing_fraction(`missing_fraction')
		local n_labels = rowsof(`label_coord')  //number of rows for one color
		adjust_bar_placement `yhi_uni' `ylo_uni', n_lab(`n_labels') missing_fraction(`missing_fraction') ///
			label_coord("`label_coord'")  m_val(`missing_value')  ystart(std_y) yend(`std_ylag') x(`x') xlag(`xlag')
		if (`addlabel'==1) {
			// after adjust_bar_placement 'cause label_coord used below 
			compute_addlabeltext ,  mat_label_coord(`label_coord') missing("`missing'") ///
				missing_fraction(`missing_fraction') ///
				label_text("`label_text'") labelopt(`"`labelopt'"')
			local addlabeltext=r(addlabeltext) 
		}
		else  local addlabeltext=""			
						
//local tmpmax= min(_N,20)
//di "after adduni: uni_ylo uni_yhi uni_x uni_color" 
//list  `ylo_uni' `yhi_uni' `x_uni' `color_uni' in 1/`tmpmax' 
//frame connectors: list _all
//matrix list `label_coord'
	}

	// compute ylabmin (midpoint-1/2 width) and ylabmax (midpoint+1/2 width)
	// If y_std contains missing values they are coded 0, just like any other minimum value
	/* needed to avoid that some coordinates are off the graph screen*/
	/* since def of width changes later this is only approximate */
	// accumulate the width for different colors
	tempvar width_total
	qui egen `width_total' = rsum(`width'*)
	computeylablimit std_y `std_ylag' `width_total'
	local ylabmax=r(ylabmax)  
	local ylabmin=r(ylabmin)

	cap drop `width_total'  // if parallelogram, meaning of width_total changes
	if ("`shape'"=="parallelogram") {
		// iterate through computing vertical width and  updating ylabmax, ylabmin
		iterate_width_range , xstart(`graphx') xend(`graphxlag')  ystart("std_y") yend(`std_ylag') ///
			width(`width') xrange(`xrange') ar_x(`ar_x') ///
			ncolors(`ncolors') ylabmax(`ylabmax') ylabmin(`ylabmin')
		local ylabmax=r(ylabmax)
		local ylabmin=r(ylabmin)
	}
	
	calc_yrange, ylabmax(`ylabmax') ylabmin(`ylabmin') uni_yhi("`yhi_uni'") uni_ylo("`ylo_uni'")
	local yrange=r(yrange)
	local ylabmin=r(ylabmin)
	local ylabmax=r(ylabmax)

	// for debugging; print variables
	//list_connectors,  xstart(`graphx') xend(`graphxlag') ystart(std_y) yend(`std_ylag') ///
	//		width(`width') uni_ylo(`ylo_uni') uni_yhi(`yhi_uni') uni_x(`x_uni') ///
	//		uni_color(`color_uni') 


	if (`space'!=float(1.0)) {
		// each obs represents a unique box (with multiple colors)
		// there is one `width' variable for each color: 
		// `width' is the stub of the variable names; `width'i contains the width of color i
		GraphBoxColor , xstart(`graphx') xend(`graphxlag') ystart(std_y) yend(`std_ylag') ///
			width(`width')  ylabmax(`ylabmax') ylabmin(`ylabmin') ///
			aspectratio(`aspectratio') ar_x(`ar_x') xrange(`xrange') yrange(`yrange') ///
			 xlab_num("`xlab_num'")  graphx("`graphx'") colorlist(`"`colorlist'"') ///
			 shape("`shape'") outline(`outline') ///
			 options(`"`options'"') addlabeltext(`"`addlabeltext'"')  ///
			 uni_ylo(`ylo_uni') uni_yhi(`yhi_uni') uni_x(`x_uni') uni_color(`color_uni') ///
			 uni_width(`uni_width') uni_colorlist(`"`uni_colorlist'"') ///
			 showaxes(`showaxes')
		// matrix `label_coord' is still around but not needed in GraphBoxColor 
	}
	else {   // only plot unibars; don't compute connecting boxes
		plot_unibars,  ///
			 ylabmax(`ylabmax') ylabmin(`ylabmin') ///
			 aspectratio(`aspectratio') ///
			 xlab_num("`xlab_num'")  graphx("`graphx'") colorlist(`"`colorlist'"') ///
			  outline(`outline') ///
			 options(`"`options'"') addlabeltext(`"`addlabeltext'"')  ///
			 uni_ylo(`ylo_uni') uni_yhi(`yhi_uni') uni_x(`x_uni') uni_color(`color_uni') ///
			 uni_width(`uni_width') uni_colorlist(`"`uni_colorlist'"')
	}
	
	cap frame drop connectors
	cap frame drop variables
end
/**********************************************************************************/
// only plot the unibars and the labels.
// this is the same plotting routine as in GraphBoxColor. See comment about a small change below
program plot_unibars 
	version 18
	syntax ,  graphx(str) ///
		ylabmin(real) ylabmax(real) xlab_num(str)  outline(int) ///
		aspectratio(real)  ///
		uni_ylo(str) uni_yhi(str)  uni_x(str) uni_color(str) uni_width(real) uni_colorlist(str) ///
		[  colorlist(str) addlabeltext(str)  options(str)  ]

	// changes relative to other scatter: `addplot' contains the boxes and is removed; option `addlabeltext' is then moved elsewhere
	twoway scatter std_y `graphx', ///
		ylab(`ylabmin' `ylabmax')  xlab(`xlab_num',valuelabel noticks nogrid) ylab(,valuelabel noticks nogrid)      ///
		legend(off) ytitle("") xtitle("") yscale(off) xscale(noline) msymbol(none)  ///
		plotregion(style(none) m(zero)) ///
		aspect(`aspectratio') `options' ///
		|| rbar `uni_ylo' `uni_yhi' `uni_x',  barwidth(`uni_width') legend(off) ///
			colorvar(`uni_color') colordiscrete colorlist(`uni_colorlist') clegend(off) ///
			colorfillonly lcolor(none) ///
			`addlabeltext'
		// "colorfillonly lcolor(none)" was added to prevent outlines of unibars. 
		// Due to a stata bug this does not work yet but will be fixed in a future Stata update
end 
/**********************************************************************************/
program iterate_width_range , rclass
// for parallelogram only: 
//		iterate through computing vertical width and  updating ylabmax, ylabmin
// on exit: recompute ylabmin and ylabmax   
//			(never shrinking range, could be slightly bigger than actual minima and maxima)
// on exit: width has changed (and now refers to vertical width)
	version 17
	syntax , xstart(str) xend(str) ystart(str) yend(str)  ///
			width(str) xrange(real) ar_x(real) ncolors(int) ///
			ylabmax(real) ylabmin(real)
			
	local tol_limit=0.01  //stop iterating if increase in ylabmin/ylabmax is less than tol_limit
	local ylabmax=`ylabmax'
	local ylabmin=`ylabmin'
	
	local width_ylist= "" 
	forvalues c=1/`ncolors'  {
		tempvar width_y`c'      // need one var for each color
		qui gen `width_y`c''=.
		local width_ylist= "`width_ylist' `width_y`c''"
		// macro `width_ylist' was created before loop and persists after loop;
		// the var name `width_y`c'' was created inside of the loop and does not (but var is there)
	}

	local tol=`tol_limit'+1 // initialize current tolerance
	while (`tol'>`tol_limit') { 
		// compute width 
		local yrange=`ylabmax'-`ylabmin'  // This is a key change; I used to use predefined range=100
		forvalues c=1/`ncolors' { 
			// compute width for one color  
			// strategy: call program with the same width`c' each time, but with a different yrange
			// on exit:  have different width_y`c'
			local width_y_c = word("`width_ylist'",`c')
			compute_vertical_width `xstart' `xend' `ystart' `yend'  ///
				`width'`c' `width_y_c' `xrange' `yrange' `ar_x'
		}

		// compute ylabmax, ylabmin
		cap drop `width_total'
		tempvar width_total
		qui egen `width_total' = rowtotal(`width_ylist')   //total width of a multi-color box
						//stata syntax change: rsum changed to rowtotal, but rsum still works also; 
						//both treat missing values as zero
		computeylablimit `ystart' `yend' `width_total'
		// tolerance is the increase either at the top or at the bottom range
		// only interested in increases:   labmax new -old , labmin old -new
		local tol=max( `r(ylabmax)'-`ylabmax' , `ylabmin'-`r(ylabmin)' )
		if ((`tol'>`tol_limit')) {  	// if I update ylabmax/ylabmin, I have to recalculate width 
										// no need to update if the range is shrinking
			local ylabmax=r(ylabmax)	// update only after computing tolerance
			local ylabmin=r(ylabmin)	// update only after computing tolerance
		}
		//di "Iteration: Tolerance= `=round(`tol',0.001)' ylabmax=`ylabmax'   ylabmin=`ylabmin'"
	}
	return local ylabmax `ylabmax'
	return local ylabmin `ylabmin'

	// caution: original `width' is lost after this
	forvalues c=1/`ncolors' { 
		local width_y_c = word("`width_ylist'",`c')
		qui replace `width'`c'=`width_y_c'
	}
end 
/**********************************************************************************/
// purpose: create addlabeltext for labels that ought to be printed [,3]!=0 
// input: mat_label_coord:  is a matrix name.  The matrix is NOT changed
// label_text:   name of the variable in frame connectors that holds the labels 
// output: addlabeltext:   text("ypos1 xpos1 "text1"  ypos2 xpos2 "text2" [...])
program  compute_addlabeltext, rclass
	version 16
	syntax , mat_label_coord(str) missing(str) missing_fraction(real) label_text(str) [ labelopt(str) ]

	local label_eps=2 // moving labels away from 0, 10,100
	* the labels are overwriting the plot. Plot before the graphboxes 
	local n_labels = rowsof(`mat_label_coord')
	local addlabeltext="text("   // no space between "text" and "("
	forval j=1/`n_labels' { 
		if (`mat_label_coord'[`j',2] !=0 &  `mat_label_coord'[`j',4]!=0) { 
			/* 2nd col==0 crucial if matrix has empty rows, otherwise graph disappears*/
			// text to plot ="``pos''"      y = `mat_label_coord'[`j',1]        x= `mat_label_coord'[`j',2]  
			// the matrix needs to be evaluated as  `=matrixelem'  ; otherwise just the name of the matrix elem appears
			
			local yy= `=`mat_label_coord'[`j',1]'
			if (`yy')==float(100) {
				local yy= `yy' - `label_eps'  // move down
			}
			else if (`yy')==float(0) {
				local yy= `yy' +`label_eps'
			}
			else if (`yy')==float(`missing_fraction'*100) {
				local yy= `yy' +`label_eps'    //by default, this is 10 
			}
			local addlabeltext= ///
			`"`addlabeltext'`yy' `=`mat_label_coord'[`j',2]' "`=_frval(connectors,`label_text',`j')'"  "'
			
			//local addlabeltext= ///
			//`"`addlabeltext'`=`mat_label_coord'[`j',1]' `=`mat_label_coord'[`j',2]' "`=_frval(connectors,`label_text',`j')'"  "'
		}
	}

	* add label options 
	local addlabeltext= `"`addlabeltext',`labelopt')"'	
	return local addlabeltext=`"`addlabeltext'"' // does not allow empty "" returns
end 
/**********************************************************************************/
// compute vars (yhi,ylo,x,color) from matrices to add Univariate Frequency bars 
//		Some bars may exceed [lower,upper]=[~0,~100]. (Elsewhere, adjust bar down or up) 
// input: 
//	mat_uni			matrix with univariate frequencies (For all colours,rows appended)
//	mat_label_coord	matrix with coordinates of labels (For the first colour only;
//										coordinates are not yet standardized to [0,100] )
//	uni_fraction	(real) fraction of the univariate space covered with bars
//	n_colors		(int) Number of colours 
//	output:			variables yhi_uni, ylo_uni, x_uni,color_uni changed globally.
program  add_unibars, rclass
	version 18
	syntax varlist (min=4 max=4), mat_label_coord(str) mat_uni(str) ///
		ncolors(int) uni_fraction(real) missing_fraction(real)

	tokenize `varlist'
	local yhi_uni `1'
	local ylo_uni `2'
	local x_uni   `3'
	local color_uni `4'
	
	local f=`uni_fraction'*.9  //determines what percentage of the univariate space is covered with bars.
								// .9 because `missing_fraction' (usually .1) is reserved for missings
	if (`f'<0 | `f'>1) {
		di as red "Unexpected input for uni_fraction(`f'). Expected values are 0.0-1.0" 
		di as res ""   // subsequent displays are in black
	}

	local n_labels = rowsof(`mat_label_coord')  //number of rows for one color

	tempname var_uni var_label_coord prop prop_one_color
	qui svmat `mat_uni', names(`var_uni') // this may increase number of obs as needed
	qui rename `var_uni'1 `prop'  //proportions (cumulative across colors) 
	qui replace `x_uni'    =`var_uni'2 
	qui replace `color_uni'=`var_uni'4
	qui rename `var_uni'5 `prop_one_color'  //proportions for one colour
	svmat `mat_label_coord', names(`var_label_coord') // after rows for first color, var_label_coord has missing in remainder

	// initialize for first color, (remember all colors appended after another) 
	// var_label_coord'1  has only first color, but has '.' in the remaining rows, syntax error avoided
	// *50 because the bar goes half way up and down (*0.5) times the scale *100
	qui replace `ylo_uni'= `var_label_coord'1-`prop'*`f'*50  if _n<=`n_labels' // 
	qui replace `yhi_uni'= `var_label_coord'1-`prop'*`f'*50 + `prop_one_color'*`f'*100  if _n<=`n_labels' //

	// additional colors
	// this statement requires `prop_one_color' be one long variable
	qui replace `yhi_uni'=  `yhi_uni'[_n-`n_labels']+ `prop_one_color'*`f'*100  if _n>`n_labels' // add to the prev. color
	qui replace `ylo_uni'=  `yhi_uni'[_n-`n_labels']  if _n>`n_labels' & !missing(`yhi_uni') // this line has to come after calc yhi_uni

	// prevent colors of width 0 to plot (Not tested whether needed)
	qui replace `x_uni'=. if `prop_one_color'==0 | `color_uni'==0   // `color_uni'=0 is for unused rows cause of missing vals
	qui replace `color_uni'=. if `color_uni'==0  // if missing , this may happen if not all rows are filled

end 
/**********************************************************************************/
//If any bars exceed [lower,upper]=[0,100], adjust bar down or up, and change label_coord 
//input:  	
//	n_labels: number of labels= number of boxes for any one color
//  missing_fraction:   0.1 by default
//  m_val :  missing_value, set to 5
//on output: 
//	yhi_uni, ylo_uni, label_coord are changed for some bars 
program adjust_bar_placement 
	version 18
	syntax varlist (min=2 max=2), n_lab(int) missing_fraction(real) label_coord(str) ///
		m_val(int)  ystart(str) yend(str) x(str) xlag(str)

	tokenize `varlist'
	local yhi_uni `1'
	local ylo_uni `2'

	local min_nonmissing= `missing_fraction'*100

	//If any bars exceed [lower,upper]=[0,100], adjust bar down or up 
	local upper=100
	local lower=0
	tempvar diff index i_within_color index2 sortorder diff2
	qui gen `diff'= `yhi_uni'-`ylo_uni'

	//strategy:
	//	indicator variable as to whether replacement needed for any color
	//	colors for the same box are at :   i,i+n_colors,i+2* n_colors,...
	//	for a given group of boxes, if any color exceeds `upper', then set the index for all colors to 1 (max of 0/1 index)
	//	replace ylo and yhi  if indicator variable is on
	qui gen `i_within_color' = mod(_n-1,`n_lab')+1   // 1..n_label for each color
	qui gen `sortorder'=_n
	quietly { // upper
		gen `index'= `yhi_uni'>`upper' & !missing(`yhi_uni') // 0/1 whether box exceeds upper limit for any color
		bysort `i_within_color': egen `index2'= max(`index')  // max ignores missing values
		sort `sortorder'
		//noi list `ylo_uni' `yhi_uni' `diff' `index2' `i_within_color'
		//noi bysort `i_within_color' : list `ylo_uni' `yhi_uni' `diff' `index2' `i_within_color'

		// establish the maximal value and move all colors of that group down 
		forvalues i = 1/`n_lab' {
			// for each group of boxes
			sum `yhi_uni' if `index2' & `i_within_color'==`i' 
			local i_max=r(max)
			local d = `i_max'-`upper'  //d= max value - upper limit
			replace `ylo_uni'= `ylo_uni'-`d' if `index2' & `i_within_color'==`i' //move all values down
			replace `yhi_uni'= `yhi_uni'-`d' if `index2' & `i_within_color'==`i'
			//di as red "i=`i'; d=`d' ; label_coord[i,1]=" `label_coord'[`i',1]
			if (`d'!=.) {
				// label_coord:  reduce corresponding entry in `label_coord' by `diff'. Label coord only has one entry per color
				replace `ystart'=`ystart'-`d' if  `ystart'==float(`label_coord'[`i',1]) & `x'==float(`label_coord'[`i',2])  // connectors x/y combination  
				replace `yend'=`yend'-`d'     if  `yend'  ==float(`label_coord'[`i',1]) & `xlag'==float(`label_coord'[`i',2])  // connectors
				matrix `label_coord'[`i',1]= `label_coord'[`i',1] -`d'    // labels and unibars
			}
		}
	}
	// if missing, for lower, I need to distinguish between missing values and non-missing values
	//    for missing values use `lower' as before
	//    for non-missing values use  `min_nonmissing' 
	quietly { // lower
		drop `index2' `index'
		gen `index'=.
		// label_coord only has `n_lab' rows, enough for the first color. But ylo_uni have #color*n_lab rows
		// mod(x,`n_lab')=0 if x=`n_lab' , therefore I have to add +  `n_lab' at the end when x=`n_lab'
		replace `index'= `ylo_uni'<`min_nonmissing'  if `label_coord'[mod(_n-1,`n_lab')+1,3]!=`m_val' // 0/1 whether box is below limit for any color
		replace `index'= `ylo_uni'<`lower'  if `label_coord'[mod(_n-1,`n_lab')+1,3]==`m_val'   // 0/1 whether box is below lower limit for any color
		bysort  `i_within_color': egen `index2'= max(`index')  // are any `index' values 1? max ignores missing values
		sort `sortorder'
		// establish the minimal value and move all colors of that group up 
		forvalues i = 1/`n_lab' {
			// for each group of boxes
			sum `ylo_uni' if `index2' & `i_within_color'==`i' 
			local i_min=r(min)   // minimum across all colors for this label `i'
			// non-missing
			local d = `min_nonmissing'-`i_min'  // (for non-missing values) 
			replace `ylo_uni'= `ylo_uni'+`d' if `index2' & `i_within_color'==`i' & `label_coord'[mod(_n-1,`n_lab')+1,3]!=`m_val' //move all values up
			replace `yhi_uni'= `yhi_uni'+`d' if `index2' & `i_within_color'==`i' & `label_coord'[mod(_n-1,`n_lab')+1,3]!=`m_val' // non-missing 

			if (`d'!=. & `label_coord'[`i',3]!=`m_val') { // non-missing, move connectors and unibars of low box
				// y-coordinate for missing is 0; don't change if missing
				replace `ystart'=`ystart'+`d' if  `ystart'==float(`label_coord'[`i',1]) & `x'==float(`label_coord'[`i',2])  // connectors x/y combination  
				replace `yend'=`yend'+`d'     if  `yend'  ==float(`label_coord'[`i',1]) & `xlag'==float(`label_coord'[`i',2])  // connectors
				matrix `label_coord'[`i',1]= `label_coord'[`i',1] +`d'   
			}
			
			// missing 
			local d = `lower'-`i_min'  //d= lower limit - min value  (for missing values)
			replace `ylo_uni'= `ylo_uni'+`d' if `index2' & `i_within_color'==`i' & `label_coord'[mod(_n-1,`n_lab')+1,3]==`m_val' //move all values up
			replace `yhi_uni'= `yhi_uni'+`d' if `index2' & `i_within_color'==`i' & `label_coord'[mod(_n-1,`n_lab')+1,3]==`m_val' // missing 			
			if (`d'!=. & `label_coord'[`i',3]==`m_val') { // missing, move connectors of missing box
				replace `ystart'=`ystart'+`d' if  `ystart'==float(`label_coord'[`i',1]) & `x'==float(`label_coord'[`i',2])  // connectors x/y combination  
				replace `yend'=`yend'+`d'     if  `yend'  ==float(`label_coord'[`i',1]) & `xlag'==float(`label_coord'[`i',2])  // connectors
			}

		}
	}
end 
/**********************************************************************************/
* creates matrix with coordinates for labels and "label_text" variable in frame connectors
* on input : missing_value:  This value,5, is needed in label_too_close, I didn't want to define it inside of the function
* on exit: `label_text' : variable in frame connectors with one row for each label 
* on exit: label_coord: matrix with one row for each label 
*    matrix has 3 cols: 
*    1 variable values/levels (actual value, not yet y-coordinate)  1..(# labels for corresponding variable)
*    2 variable index in `varlist'  (x-coordinate) 1...(#variables) 
*    3 takes one of two values: "."(start of a new variable,i.e. the first label of a new variable); "5"(=`missing_value') 
*	 4 plot the label (1) or not (0)?  (used in decide plot_label)
program define list_labels, rclass
	version 18
	syntax varlist , label_text(str) missing(int) missing_value(int) [ label_format(string) ]

	tempname one_ylabel label_coord

	n_level_program `varlist' , missing(`missing') // miss adds 1 level for _all_ vars
	local n_level= r(n_level)
	
	// Strategy: if display missing, and not all variables have missings, we may not populate the last rows of `label_coord'
	matrix `label_coord'=J(`n_level',4,0)
	mat colnames `label_coord' = value x  start_newvar plot_label
	// connectors has one obs per connector (bivariate box)
	qui frame connectors: set obs `n_level'
	qui frame connectors: gen `label_text'=""

	local i=0	/* the ith variable (for x-axis) */
	local offset=0  /* sum of the number of levels in previous x-variables */
	local miss="" /* ensure visibility outside of if */
	if (`missing'==1)  { 
		local miss = "m" 
	}

	foreach v of var `varlist' { 
		local i= `i'+1
		qui tab `v', matrow(`one_ylabel') `miss'   // unique value for missing, if present, is "."
		local n_one_ylabel=r(r)
		local g : value label `v'   // value label does not include missing
		forval  j = 1/`n_one_ylabel' {
			local w=`one_ylabel'[`j',1]
			matrix `label_coord'[`offset'+`j',2]=`i'  // i^th variable, also x-coordinate
			matrix `label_coord'[`offset'+`j',1]=`w'  // value of label, or . for missing
			if (`j'==1) {  
				* This marks when a new variable starts. Needed in decide_labels_too_close
				matrix `label_coord'[`offset'+`j',3]=.
			}
			// now save label text
			if "`g'"!="" {
				/* value label present */ 
				local l : label `g' `w'
				if ("`l'"=="") {
					di as error "A label value for `g' has only white space, creating problems"
					di as res ""  // any subsequent statements are in result mode (in black)
				}
				// missing values  (guard against  a non-missing value `w' that has a label `l'=="." )
				else if ("`l'"=="." & missing(`w')) {  // values not in the valuelabel are simply repeated, including "." 
					local l="missing"
					matrix `label_coord'[`offset'+`j',3]=`missing_value'
				}
				qui frame connectors: replace `label_text' = "`l'"  if _n==`offset'+`j' 
			}
			else {	
				/* no value label present */
				local format_w=string(`w',"%6.0g") 
				if "`label_format'"!="" {
					//non-numerical formats such as 10%s  give empty values "" 
					local format_w=string(`w',"`label_format'")
				}
				if ("`format_w'")=="" {
					// if label format was not valid/ string format, restore previous assignment.
					local format_w=string(`w',"%6.0g")
				}
				if ("`format_w'"==".")  {
					local format_w="missing"
					matrix `label_coord'[`offset'+`j',3]=`missing_value'
				}
				qui frame connectors: replace `label_text' = "`format_w'"  if _n==`offset'+`j'
			}
		}
		local offset=`offset'+`n_one_ylabel' 
	} 
	return matrix label_coord `label_coord'  // new matrices need be returned
end 
/**********************************************************************************/
* creates matrix with univariate frequencies to all labels, separately by color
* 	the rows of the matrix MUST Correspond to those in `label_coord'
*	The first section of the matrix is for color 1 , followed by rows for color 2, ETC.   
* on input: n_colors  : number of colors
* on exit: uni_matrix: matrix with one row for each label/color combination with four columns:
*		1 cum. proportion,  2 Variable index,  3  "." for the first label of a new variable, 4 color, 5 proportion by color
*		if minbarfreq>1 proportions and cum proportions are increased
program  create_uni_matrix, rclass
	version 17
	syntax varlist , ncolors(int) colorvar(str) missing(int) minbarfreq(int)

	tempname one_yfreq two_freq uni_matrix

	// strategy:
	// n_level has the sum of all levels, adding +1 for *all vars
	// We may not populate the last rows for a given color if some vars do not have missings
	// However, the next color always starts after n_level rows
	n_level_program `varlist',  missing(`missing')   //missing: count +1 for *all* vars
	local n_level= r(n_level)
	local nrow=`n_level'*`ncolors'
		
	matrix `uni_matrix'=J(`nrow',5,0)
	matrix colnames `uni_matrix'= cumprop variable  indicator color  prop
	local i=0	/* the ith variable (for x-axis) */
	local offset=0  /* sum of the number of levels in previous x-variables */
	local offset_color= -`n_level'
	local miss="" // ensure visibility outside of "if"
	if (`missing')  { 
		local miss="m"
	}
	
	// color must be the outer loop
	forval c = 1/`ncolors' {
		//reset offset because may not have used all rows: if `missing' not all vars have missing values.
		local offset_color = `offset_color' + `n_level' 
		local offset= `offset_color'   // offset is changed below; need separate offset_color
		local i=0  // new color, start with 1st variable again
		foreach v of var `varlist' { 
			local i= `i'+1
			
			
			// frequencies/proportions by color
			qui tab `v' `colorvar', matcell(`two_freq') `miss' //Crucial, achieves the same order
			local one_sum=r(N) // probably redundant
			if (`minbarfreq'>1){
				local rows = rowsof(`two_freq')
				local cols = colsof(`two_freq')
				forvalues jj = 1/`rows' {
					forvalues kk = 1/`cols' {
						if (`two_freq'[`jj',`kk']!=0 & `two_freq'[`jj',`kk'] < `minbarfreq') {
							local one_sum = `one_sum' + (`minbarfreq' - `two_freq'[`jj',`kk']) //increase
							matrix `two_freq'[`jj',`kk'] = `minbarfreq'
						}
					}
				}
			}		

			// cumulative frequencies/proportions; 
			// sum across columns in matrix by creating a column vector of 1s
			matrix `one_yfreq' = `two_freq' * J(colsof(`two_freq'), 1, 1)

			// turn into proportions
			matrix `two_freq'=`two_freq'/`one_sum' //divide by total sum; because colors get separate space	
			matrix `one_yfreq'=`one_yfreq'/`one_sum'   // turn frequencies to proportions 

			qui tab `v', `miss'					
			local n_one_yfreq=r(r)   // if `missing', adds 1 only if this particular var has missing 	

			// populate uni_matrix
			forval  j = 1/`n_one_yfreq' {
				local w=`one_yfreq'[`j',1]   // vector from one-way tab
				local w2=`two_freq'[`j',`c'] // matrix from two-way tab
				matrix `uni_matrix'[`offset'+`j',2]=`i'  //variable index
				matrix `uni_matrix'[`offset'+`j',1]=`w'  //cumulative proportion
				matrix `uni_matrix'[`offset'+`j',4]=`c'  //color
				matrix `uni_matrix'[`offset'+`j',5]=`w2'  //proportion individual bar by color
				if (`j'==1) {  
					* This marks when a new variable (or new color) starts. May not be needed; 
					* but I kept it analogous to matrix  `label_coord'
					matrix `uni_matrix'[`offset'+`j',3]=.
				}
			}
			
			
			local offset=`offset'+`n_one_yfreq'
		}
	}

	return matrix uni_matrix `uni_matrix'   //new matrices need be returned
	
end 
/**********************************************************************************/
// purpose: create a vector that specifies label method "all" "minmax" "min_dist" "none"
//			method applies to all labels of a variable
// output: varlabel_method: 
//			varlabel_method[,1]=  1.... <number of vars in varlist> 
//			varlabel_method[,2]=  "all","minmax", or "distance"
program create_varlabel_method , rclass
	syntax varlist ,   too_many_levels(int) [ label_methodlist(string) ]

	// frame name "variables" is hard coded
    capture frame drop variables
    frame create variables ///
		int order ///
        str32 varname ///
        int    nlevels ///
        str8   method

	if "`label_methodlist'"=="" {
		// default, label_methodlist not specified
		local i =0
		foreach var of local varlist {
			local ++i
			quietly levelsof `var', local(levels)
			local nlevels : word count `levels'

			if (`nlevels' > `too_many_levels') {
				frame post variables (`i') ("`var'") (`nlevels') ("minmax")
			}
			else {
				frame post variables (`i') ("`var'") (`nlevels') ("all")
			}
		}
	}
	else {   // label_methodlist not empty

		//  label_methodlist() must have same #words as varlist
		local nvar   : word count `varlist'
		local nlab   : word count `label_methodlist'

		if (`nlab' != `nvar') {
			di as error "label_methodvarlist() must have `nvar' words (one per variable in varlist); got `nlab'."
			exit 198
		}

		// Validate each label_methodlist word
		forvalues i = 1/`nlab' {
			local lw : word `i' of `label_methodlist'
			if !inlist("`lw'", "all", "minmax", "none","min_dist") {
				di as error "label_methodlist() word `i' is `lw' but must be all, minmax, or none."
				exit 198
			}
		}

		local i = 0
		foreach v of local varlist {
			local ++i
			quietly levelsof `v', local(levels)
			local nlevels : word count `levels'
			local labword : word `i' of `label_methodlist'

			frame post variables (`i') ("`v'") (`nlevels') ("`labword'")
		}
	}
		
	//frame variables: list, noobs abbreviate(20)

end
/**********************************************************************************/
program define n_level_program, rclass
	version 7
	* compute the sum of the number of levels of all variables
	* each level later corresponds to a label
	* if missing , add one category for EACH var, even if that var does not have missings
	syntax varlist , missing(int)

	* calc the sum of number of levels of all vars
	local n_level=0
	foreach v of var `varlist' { 
		qui tab `v'
		  local temp= r(r)
		local n_level=`n_level' + `temp'
	}

	if (`missing') {
		local n_var : word count `varlist'
		local n_level= `n_level'+ `n_var'   // add one missing for each variable
	}

	/* I used to set matsize here,
	 but in modern flavours of stata "set matsize" is obsolete
	 Stata flavour determines matsize (see help limits) */

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
   * compute the difference of the y coordinates needed 
   * width is right-angle width (distance between two parallel lines)
   * ar_x: (aspectratio) how much longer is the x axis relative to the y axis
   * on input : width_y has already been "generate"d 
   * width_y is computed as a result  
   *	(if width has missing values, then width_y also has missing values)
   
   args xstart xend ystart yend width width_y xrange yrange ar_x

   *xdiff is the fraction of space relative to the range occupied by any particular parallelogram. 
   *  For example, with 5 variables the xrange=5-1=4.   
   *  Going from the 2nd to the third x-variable has an xdiff = 1/ 4  * ar_x .
   *ydiff is the same thing for y, i.e. the fraction that y drops/increases for one box relative to its range.
   tempvar xdiff ydiff
   qui gen `xdiff'= .
   qui gen `ydiff'= .
   qui replace `xdiff'= (`xend'-`xstart')/`xrange' * `ar_x'
   qui replace `ydiff'= (`yend'-`ystart')/ `yrange'
   
   * The centerline of the parallelogram, xdiff and ydiff from a triangle with a right angle. 
   * theta is the angle between xdiff and the centerline of the parallelogram.
   * From this big triangle:  
   *     Cos(theta) = xdiff/  sqrt(xdiff^2 +ydiff^2) 
   * The angle theta reappears for width and width_y, as part of the parallelogram: 
   *     Cos(theta)= width/ width_y  .
   * Putting these together: 
   *    Width/ width_y = xdiff/ sqrt(xdiff^2 +ydiff^2)
   * Solving for width_y : 
   *            width_y = width  / xdiff   * sqrt(xdiff^2 +ydiff^2)
   qui replace `width_y'=`width' / `xdiff' * sqrt(`xdiff'*`xdiff'+`ydiff'*`ydiff') 

end 
/**********************************************************************************/
* distinguish between colorgroup for strings and color group numeric
* string variables allowed only when highlighting a variable not in varlist
program define gen_colorgroup
	version 16
	syntax ,  hivar(varname) HIVALues(string) hiprefix(string) highlight_all_levels(int)

	if "`hiprefix'"!="." {
		qui gen_colorgroup_prefix,  hivar(`hivar') hivalues(`hivalues') hiprefix(`hiprefix')
	}
	else {
		capture confirm numeric variable `hivar'
		if !_rc {
			qui gen_colorgroup_num , hivar(`hivar') hivalues(`hivalues') ///
						highlight_all_levels(`highlight_all_levels')		//numeric variable
		}
		else {
			qui gen_colorgroup_str , hivar(`hivar') hivalues(`hivalues')  //string variable
		} 
	}
end
/**********************************************************************************/
* generate the colorgroup variable,numeric
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
program define gen_colorgroup_num
	version 7
	syntax  ,  hivar(varname) HIVALues(numlist missingokay) highlight_all_levels(int)

	local pen=1
	if (`highlight_all_levels') {
		local pen=0   //colorlist contains no default color; the first highlighted color should be 1
	}
	qui gen colorgroup=`pen'
	foreach v of numlist `hivalues' {
		local pen=`pen'+1  //increment pen by 1 
		qui replace colorgroup=`pen' if `hivar'==`v' 
		if ("`v'"==".") {
			qui replace colorgroup=`pen' if  `hivar'==.
		}
	}
end
/**********************************************************************************/
* generate the colorgroup variable, string
* same as for numeric; except the string comparison instead of ==  , and no missing values, and loop over i
program define gen_colorgroup_str
	version 16
	syntax  ,  hivar(varname) HIVALues(string) 

	local pen=1
	qui gen colorgroup=`pen'
	foreach v in `hivalues' {
		local i=1
		local pen=`pen'+1
		while (`i'<=_N) {
			qui replace colorgroup=`pen' in `i' if  ustrregexm(`hivar'[`i'],"`v'")    // `hivar'==`v' 
			local i=`i' + 1
		}
	} 
end
/**********************************************************************************/
* generate the colorgroup variable when the prefix ("<", ">",...) is present
* one highlighting color: 2
* all values not mentioned in hivalues get color=1
* syntax enforces that only a single hivalue is allowed
* missing values are not highlighted when specifying, e.g.  >3 
program define gen_colorgroup_prefix
	version 16
	syntax  ,  hivar(varname) HIVALues(real) hiprefix(string)

	qui gen colorgroup=1
	qui replace colorgroup=2 if `hivar' `hiprefix' `hivalues' & !missing(`hivar')
end
/**********************************************************************************/
// check whether trying to highlight a (numerical) value that does not exist 
//		if so, issue error
program check_hivalues_exist
	version 18
	syntax ,  hivar(str) hivalues(str) hiprefix(str)

	// hivalues(str) avoids an error in case the variable is a string variable)
	
	// if hiprefix="<" or ">" or similar, no need to check whether values exist
	if "`hiprefix'"=="." {
		capture confirm numeric variable `hivar'
		if !_rc {
			//action for numeric variables
			qui levelsof `hivar', local(x_values) missing  // Store unique values of x in local macro

			foreach h of local hivalues {
				local found=0
				foreach  x of local x_values {
					if (`h'==`x') {
						local found=1
					}
				}
				if (`found'==0) { 
					di as error "Variable `hivar' does not contain the value `h' you want to highlight. " 
					di as error "Existing values are `x_values'" 
					error 197
				}
			}
		}
		else {
			//		possible action for str# or strL variables
		}
	}
end
/**********************************************************************************/
//	check colorlist; and remove first color if not needed
//	create colour list for univariate boxes 
program update_colorlists, rclass 
	version 18
	syntax  ,  miss(int) [ hivar(str) hivalues(str) colorlist(str) uni_colorlist(str) ]
	
	// colorlist 
	check_sufficient_colors ,  hivar("`hivar'") hivalues("`hivalues'") colorlist(`"`colorlist'"') 
	// if ("`colorlist'"=="")	 local colorlist="blue%50 orange%50 green red teal  yellow sand maroon olive"  // old colorlist
	if ("`colorlist'"=="")	 local colorlist="ltblue sandb lavender ltbluishgray eggshell"
	
	// uni_colorlist
	if (`"`uni_colorlist'"')=="" {
		local uni_colorlist = `"`colorlist'"'
	}
	
	if ("`hivar'"!="") { 
		check_highlight_all_levels , hivar(`hivar') hivalues(`hivalues') miss(`miss')
		local highlight_all_levels=r(highlight_all_levels)
		if (`highlight_all_levels') {
			// remove default color from both colorlists
			// this works even with `"gray  "50 40 80" one two three"' as long as the first word is a normal word
			local uni_colorlist : subinstr local uni_colorlist "`: word 1 of `uni_colorlist''" "", all
			local colorlist : subinstr local uni_colorlist "`: word 1 of `colorlist''" "", all
		}
	}
	return local uni_colorlist "`uni_colorlist'"
	return local colorlist "`colorlist'"
	return local highlight_all_levels "`highlight_all_levels'"
end 
/**********************************************************************************/
program define computeylablimit, rclass
	version 7
	* compute maximum and minimum values for y to define graph region ylab
	* ylabmax and ylabmin are rounded to full numbers
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
*				For rectangles, this is the right-angle width.
* ylabmin,ylabmax:  upper and lower ylabels for plotting. These can be slightly wider 
*					than range of y because of the size of the bars
* aspectratio:   Aspect ratio y/x (stata's definition). 
* ar_x			 Aspect ratio x/y.   (Safer to carry forward than to recompute)
* xrange : 		 #xvars -1. It's safer to carry it forward rather than to recompute it.
* xlabnum		 :   needed to construct xlabel
* graphx 		 : name of x variable for plotting
* addlabeltext   : string for adding labels:  text("ypos1 xpos1 "text1"  ypos2 xpos2 "text2" [...])
* uni_yhi uni_ylo uni_x, uni_color: Variable names to plot Univariate bars 
* uni_width		 : width  / space of the univariate area 
* colorlist		 : list of colors to be used
* outline		 : 1/0: whether or not boxes should have an outline (using lcolor)
* showaxes	     : 1/0. Whether or not to add a frame to the plot to see how it is plotted
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
	version 18
	syntax , xstart(str) xend(str) ystart(str) yend(str) width(str) graphx(str) ///
		ylabmin(real) ylabmax(real) xlab_num(str) shape(str) outline(int) ///
		aspectratio(real) ar_x(real) xrange(real) yrange(real) ///
		uni_ylo(str) uni_yhi(str)  uni_x(str) uni_color(str) uni_width(real) uni_colorlist(str) ///
		showaxes(int) ///
		[  colorlist(str) addlabeltext(str) options(str)  ]

	tempvar w increment
	qui egen `w'= rsum(`width'*)  // total width of a multi-color box
	qui gen `increment'=0	// sum of w_k before the current color
		
	local no_outline=""
	if (`outline'==0)	local no_outline = "lcolor(black%0)"  // boxes have no, i.e. translucent outline
	//If there is an outline, my tests indicate that the outline is correctly inside the area as in "lalign(inside)" 
	//      lalign(outside) would be a problem as there would be overlap with neighboring lines
	

	// initialize, so I can use "replace" later
	tempvar yhigh ylaghigh ylaglow xlow xhigh xlaghigh xlaglow ylow
	foreach var of newlist `xlow' `xhigh' `xlaghigh' `xlaglow' `yhigh' `ylaghigh' `ylaglow' `ylow' {
		qui gen `var'=.
	}
	// when "`shape'"=="rectangle", initialize 
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
			xrange(`xrange') ar_x(`ar_x') yrange(`yrange')
	}

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
			tokenize `"`colorlist'"'
			local color= "``k''"  // need double single quotes

			// for a given color k, plot one parallelogram at a time.	
			if (`N'>1600) {
				// the number 1600 is not exact; it was empirically determined
				di as error "You are drawing many boxes (" _N ")between axes. "
				di as error "If there is an error, try highlighting fewer observations or removing one of the numerical variables."
				di as error " " 
			}
			forval i= 1/`=_N' {
				
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
							ylow(`ylow1')  ylaglow(`ylaglow1') color("`color'") `no_outline'
					}
					else {						
						// works for both general quadrangles and for parallelogram as a special case
						plot_quadrangle `hi`i'`k'' `lo`i'`k'' `x`i'`k'', color("`color'") `no_outline' ///
							xhigh(`xhigh1') yhigh(`yhigh1') ///	     
							xlow(`xlow1') ylow(`ylow1') ///
							xlaghigh(`xlaghigh1') ylaghigh(`ylaghigh1') ///
							xlaglow(`xlaglow1') ylaglow(`ylaglow1') 	
					}
					local temp = r(addplot)
					assert `"`temp'"'!=""
					// caution : addplot might get tooo long
					if (`"`addplot'"'=="")  local addplot  `"`temp'"'
					else 					local addplot  `"`addplot' || `temp'"'
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

	//for debugging (important): This helps seeing the frame in the plot area on which aspectratio is built.
	if `showaxes' {
		local ll=1+`uni_width'/2  // unibars are not plotted from .85 to 1.15, but instead a smaller fraction 
		twoway scatter std_y `graphx', ///
			ylab(`ylabmin' 10(10)90 `ylabmax')  xlab(`xlab_num' `ll',) ylab(,valuelabel) ///
			legend(off) ytitle("") xtitle("") msymbol(none)  ///
			plotregion( m(zero) ) yscale(on)  ///
			aspect(`aspectratio') `options'  ||  `addplot' `addlabeltext' ///
			|| rbar `uni_ylo' `uni_yhi' `uni_x',  barwidth(`uni_width') legend(off) ///
				colorvar(`uni_color') colordiscrete colorlist(`uni_colorlist') clegend(off) 
	} 
	else {
		twoway scatter std_y `graphx', ///
			ylab(`ylabmin' `ylabmax')  xlab(`xlab_num', valuelabel noticks nogrid) ///
			ylab(,valuelabel noticks nogrid)  ///
			legend(off) ytitle("") xtitle("") yscale(off) xscale(noline) msymbol(none)  ///
			plotregion(style(none) m(zero)) ///
			aspect(`aspectratio') `options'  ///
			||  `addplot'  `addlabeltext'  ///
			|| rbar `uni_ylo' `uni_yhi' `uni_x', barwidth(`uni_width') legend(off) ///
				colorvar(`uni_color') colordiscrete colorlist(`uni_colorlist') clegend(off) ///
				colorfillonly lcolor(none) 
		// "colorfillonly lcolor(none)" was added to prevent outlines of unibars. 
		// Due to a stata bug this does not work yet but will be fixed in a future Stata update
	}

	// These options below produce a graph without any margins except for the x-labels at the bottom
	// scatter y x,plotr(m(zero)) graphr(m(zero)) ytitle("") xtitle("") yscale(off) xscale(noline) 
	//  graphr(m(zero)) : I can't set these to zero because the numbers go off the right/left side

end 

///////////////////////////////////////////////////////////////////////////////////////////////////////
//  prepare plotting a single parallelogram: 
//  create command `addplot' and create three variables needed for the plot
//  rarea needs a different observation for each x-value. A parallelogram has 2 x-values, 
//      so there are 2 observations here.
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
//  rarea needs a different observation for each of the four different x-values;
//     the rectangle is plotted in 3 segements between the 4 x-values
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
	  error 197 
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
// compute the "outer" corners of a multi-color rectangle
// input: 	xstart, xend, ystart, yend, w 
//			reals: xrange, ylabmin ylabmax, ar_x  (needed to compute alpha's)
// output: 	o_ylow o_yhigh o_ylaglow o_ylaghigh 
//			o_xlow o_xhigh o_xlaglow o_xlaghigh 
	// Notation as used in the JCGS paper's online appendix : 
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
		xrange(real)  ar_x(real) yrange(real)
			
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
	//local ymaxmin_diff= (`ylabmax'-`ylabmin')  // before May 2025
	local ymaxmin_diff= `yrange'   // changed May 2025; yrange can be larger than ylabmax-ylabmin bec of higher unibars
	qui gen `deltax'= (`xend'-`xstart')/`xrange' *`ar_x' //same calc as in compute_vertical_width
	qui gen `deltay'= (`yend'-`ystart')/`ymaxmin_diff'   			 	//same calc as in compute_vertical_width

	// Loop because trigonometric functions don't take variables as arguments. 
	// (could convert to a matrix as an alternative.)
	// Alpha appears correct; The default layout atan(5.5/4) = 54 degrees which is similar to simple example
	forval i  = 1/`=_N' {
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
//	and I would use preserve/ restore which is too slow
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
// parse hivalues: remove the <,>,<=,>= sign , if present
// ">3" parses to prefix=">", hivalues="3"
// "2 3 5" parses to  prefix="", hivalues="2 3 5"
// "> 2 3 5" is nonsensical but does not produce an error(caught later in gen_colorgroup_prefix)
// ">=2" parses to prefix">=", hivalues"2"
// "=2" prases to  prefix="", hivalues"2"
// "mild"  parses in prefix="" and hivalues="mild"
program parse_hivalues, rclass
	version 17
	syntax , [ hivalues(string) hiprefix(string) ]
	
	local hiprefix=""
	if "`hivalues'"!="" {
		tokenize `hivalues', parse(">=<")
		//note: ">=2" is parsed as ">=","2"
		if "`3'"!="" {
			di as error "Unexpected string in hivalues. (string was parsed into 3 or more substrings)" 
			exit 
		}
		else if "`1'"=="<" || "`1'"==">" || "`1'"==">=" || "`1'"=="<=" {
			local hiprefix="`1'"
			local hivalues="`2'"
		}
		else if "`1'"=="=" {
			// remove "=" from string, don't use it as a prefix
			local hivalues="`2'"
		}
		// else leave hivalues as is 
	}
	return local hivalues "`hivalues'"
	return local hiprefix "`hiprefix'"
end 
///////////////////////////////////////////////////////////////////////////////////////////
// colorlist should not be smaller than number of values in hivalues + 1 (default color)
program define check_sufficient_colors
	version 16
	syntax,  [ hivar(str) HIVALues(string)  COLorlist(str) ] 

	if ("`hivar'"!="" & "`colorlist'"!="") {
		local hicount: word count `hivalues'
		
		// colorlist may contain strings, so "word count" does not work
		local colcount=0
		tokenize `"`colorlist'"'
		while "`*'" ~= "" {
			macro shift
			local colcount= `colcount' +1 
		}
		if (`colcount'<`hicount'+1) {
			di as error " There are not enough colors for highlighting. "
			di as error "(The first color is the default color and is not used for highlighting.)"
			error 2000
		}
	}
end
///////////////////////////////////////////////////////////////////////////////////////////
//  purpose: highlighting all values? 
//			if so, need to remove default color from uni_colorlist later 
program define check_highlight_all_levels, rclass
	version 18
	syntax, miss(int)  [ hivar(str) HIVALues(string)  ] 

	if (`miss') {
		qui tab `hivar',m
	}
	else {
		qui tab `hivar'
	}
	local levels=r(r)
	
	// counts number of hivalues. Does not check whether values exist in hivar (could lead to an error)
	local hicount: word count `hivalues'
	
	local highlight_all_levels=0
	if (`hicount' == `levels') {
		local highlight_all_levels =1
	}
	return local highlight_all_levels  `highlight_all_levels' 
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// purpose :  	transform variables to have a range between 0 and 100, 
//				compute corresponding label positions
//				Specifically, this refers to the center positions of the parallelograms.
//				(Later, range will be extended to accommodate upper and lower points, and missing vals)
// output: variables in varlist changed (we are in "preserve" mode, so changes disappear at the end)
// output: label_coord matrix changed if labels are used
// output: std_y`i' variables generated (lowest values (e.g. missing values) are standardized to 0)
// note: miss is an int; previously option missing was prestransform_variable_rangeent/absent
program transform_variable_range , rclass
	version 16.0
	syntax varlist ,  addlabel(int) adduni(int) same(int) mat_label_coord(str) miss(int) std_y(str) ///
		missing_fraction(real) [ samescale(varlist) ]

	if (`missing_fraction'>=1 | `missing_fraction'<=0) {
		di as error "Unexpected value for missing_fraction: `missing_fraction' "
		di as error "Value should be:  (0<missing_fraction<1)"
		error 99
		exit 
		}

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
		local min_nonmissing=r(min)  // save the value
		if (`same' & ustrregexm("`samescale'","`v'")) {
			* override calculations with variables specified in samescale
			local range=`globalrange'
			local min_nonmissing=`globalmin'
		}
		local my_y  "`std_y'`i'"
		qui gen `my_y'=`v'   
		if (`miss') {
			* missing option specified 
			local missval=0  // specify 0 rather than `missing_fraction'/2*100 because the lowest box is adjusted later anyways
					//and I don't want to tell stata it does not have to start at 0.
			// if `v' appears multiple times in varlist, it is important to change `my_y' and not `v' itself
		}	
		// compress placements of values between 10 and 100 (i.e. `missing_fraction'*100 and 100)
		qui replace `my_y' = (1-`missing_fraction') * (`my_y'-`min_nonmissing')/ `range' * 100 + `missing_fraction'*100  // standardize to min=missing_fraction*100, max=100 
		if (`miss')  qui replace `my_y'=`missval' if `my_y'==.   
		
		//this next part is inside the variable loop but otherwise unconnected to the previous; could be a separate subroutine.
		if (`addlabel'==1 | `adduni')  {
			local n_labels = rowsof(`mat_label_coord') 
			forval ii = 1 / `n_labels' {
				if (`mat_label_coord'[`ii',2]==`i') { /* label belongs to variable `v' */
					if (`mat_label_coord'[`ii',1]!=.) {
						matrix `mat_label_coord'[`ii',1]= (1-`missing_fraction')*(`mat_label_coord'[`ii',1] -`min_nonmissing')/ `range'*100+ `missing_fraction'*100
					}
					else { //missing value
						matrix `mat_label_coord'[`ii',1]= `missval'   // position of label for missing vals
					}
				}
			}
		}
		
	}
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose : change position in label_coord by `eps' avoiding  0, (missing_fraction*100), and 100.
//		change by eps because I don't know the midpoints yet
//		this mirrors adjustments for uni_bars such that the bottom (rather than midpoint) 
//			starts at  0, (missing_fraction*100) and the top at 100.
program adjust_mat_label_coord , rclass
	version 18.0
	syntax  ,  eps(real) mat_label_coord(str) miss(int) missing_fraction(real)

	local  ten= `missing_fraction'*100  // by default this will be 10 (with missings) or 0 (without missings)
	local n_labels = rowsof(`mat_label_coord')

	forval i = 1 / `n_labels' {
		if (float(`mat_label_coord'[`i',1])==float(0))  {
			matrix `mat_label_coord'[`i',1]=`eps'
		}
		else if ((float(`mat_label_coord'[`i',1])==float(`ten'))) {
			matrix `mat_label_coord'[`i',1]=`ten'+`eps'	
		}
		else if (float(`mat_label_coord'[`i',1])==float(100))  {
			matrix `mat_label_coord'[`i',1]=100-`eps'	
		}
	}
end 
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: change y_std  by `eps' avoiding  0, missing_fraction*100, and 100.
//		analogous to adjust_mat_label_coord
// on output: changes std_y`i'
program adjust_std_y 
	version 18.0
	syntax varlist, eps(real) miss(int) missing_fraction(real)
	
	local ten= `missing_fraction'*100  // by default this will be 10 (with missings) or 0 (without missings)
	foreach var of varlist `varlist' {
		qui replace `var'=`eps' if  `var'==float(0)
		qui replace `var'=100-`eps' if `var'==float(100)
		qui replace `var'=`ten'+`eps' if `var'==float(`ten')
	}
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// purpose :   decide whether the label distance on the y-axis is too close. 
//			   If too close, set mat_label_coord[,4]==0
//			   This has to happen *after* transforming variables to have a range between 0 and 100
// input :	  
//			  min_distance: minimum distance between labels  (on a scale from 0-100)
//			  add_dist  : previous distance to previously plotted label
//			  j  		:  row to evaluate
// assume :	  labels are sorted in ascending order
// output:	  mat_label_coord[,4] contains decision (0= do not plot, 1= plot)
//			  add_dist:  current distance to last label
program decide_label_too_close , rclass
	version 16.0
	syntax ,  mat_label_coord(name) min_distance(real) missing_value(int) add_dist(real) j(int)

	local n_labels = rowsof(`mat_label_coord') 

	if (`mat_label_coord'[`j',3]==`missing_value') { 
		// missing value label
		matrix `mat_label_coord'[`j',4]= 1 // plot 
	}
	else if (`mat_label_coord'[`j',3]!=.) {
		/* if not the first label of a new variable,  distance = y_current - y_last */
		assert `j'>1   // if j==1 then new variable, and `mat_label_coord'[`j',3]==.  cannot happen here
		local distance= `add_dist' + (`mat_label_coord'[`j',1]- `mat_label_coord'[`j'-1,1])
		if (`distance'<`min_distance') {
			matrix `mat_label_coord'[`j',4]=0  // do not plot
			local add_dist= `distance' // distance to previously plotted label
		}
		else {
			matrix `mat_label_coord'[`j',4]= 1 //plot
			local add_dist=0
		} 
	 }
	else if (`mat_label_coord'[`j',3]==.)  { 
		// first label of a new variable
		matrix `mat_label_coord'[`j',4]= 1 //plot
		local add_dist=0  // reset add_dist for new variable
	}
	else {
		// cannot happen
		di as red  "Error in decide_label_too_close "
	}
		
	return scalar add_dist = `add_dist'
	// `mat_label_coord' is altered but need not be returned
end 
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// purpose :  decide whether label should be plotted  by changing mat_label_coord[,3]
// input :	  mat_label_coord[,3]="." for the first element of each variable 
//			  mat_label_coord[,3]=5  for any the missing values (always last)
//			  mat_label_coord[,3]=0 otherwise (no entries are currently =1)
// assume :	  labels are sorted in ascending order, where missing mat_label_coord[,3]==5 is at the end 
// 			  frame variables lists teh variables in the same order as  mat_label_coord[,2]  (varlist order)
// output:	  mat_label_coord[,4] contains decision (0= do not plot, 1= plot) 
program define decide_plot_label  
	version 18.0
	syntax ,  mat_label_coord(name) min_distance(real) missing_value(int) miss(int) missing_fraction(real)

	local n_labels = rowsof(`mat_label_coord') 
	local add_dist=0  // needed for min_dist

	local yy = float(`missing_fraction'*100) // by default yy=10

	frame variables {
		forvalues j = 1/`n_labels' {
			local k = el(`mat_label_coord', `j', 2) // value 2 indexes variables
			capture assert `k' >= 0 & `k' <= _N   //  _N=number of variables in frame
			if (_rc) {
				di as error "decide_plot_label: index k=`k' out of range (1.. " _N   " )"
				exit 198
			}
			
			// k can sometimes be 0 in the last row(s) of the matrix, not corresponding to any label
			if (`k'!=0) {
				if  method[`k']=="all" { 
					matrix `mat_label_coord'[`j',4] = 1
				}
				else if method[`k']=="minmax" {
					// plot for max(100), min(0) If missing, plot(10).  
					// Caution: If !`miss' but missing values exist, min is also 10 (rather than 0)
					if (el(`mat_label_coord',`j',1)==0)   ///
					| (`miss' & el(`mat_label_coord',`j',1)==`yy')    ///
					| (!`miss' & el(`mat_label_coord',`j',3)==. & el(`mat_label_coord',`j',1)==`yy') ///
					|  (el(`mat_label_coord',`j',1)==100) { 
						matrix `mat_label_coord'[`j',4] = 1
					}
				}
				else if method[`k']=="none" {
					// do nothing; don't set any elements to 1
				}
				else if method[`k']=="min_dist" {
					decide_label_too_close, mat_label_coord(`mat_label_coord') min_distance(`min_distance') /// 
						missing_value(`missing_value') add_dist(`add_dist') j(`j')
					local add_dist=r(add_dist)
				}
			}
		}
	}

end 
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// purpose:  list connectors between axes. For debugging only.
program list_connectors
	version 17.0
	
	syntax, [ xstart(str) xend(str) ystart(str) yend(str) ///
			width(str) ///
			uni_ylo(str) uni_yhi(str) uni_x(str) uni_color(str) ]
	
	label var `xstart' xstart
	label var `xend'  xend
	label var `ystart' ystart
	label var `yend' yend
	//label var `width' width  // if highlighting width will give an error because there are multiple vars
	
	label var `uni_ylo' uni_ylo 
	label var `uni_yhi' uni_yhi
	label var `uni_x'   uni_x 
	label var `uni_color' uni_color
	
	foreach v of varlist _all {
		display "`v': `:var label `v''"
	}
	list
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// purpose:  calculate yrange, and adjust ylabmax/ylabmin if needed. 
//		This is important to get the rectangles right later on.
// strategy: use temporary variable to find out what the largest value is from the unibars or from  ylabmax.
program calc_yrange ,  rclass
    syntax ,  ylabmax(real) ylabmin(real) uni_yhi(str) uni_ylo(str)
	// note: yrange covers the range of the bivariate connectors; it does not adjust for univariate bars going higher or lower.
	qui summarize `uni_yhi'
	local temphi= r(max)
	qui summarize `uni_ylo'
	local templo= r(min)
	
	//local temphi=max(`ylabmax',`temphi')
	//local templo=min(`ylabmin',`templo')
	//local yrange=`temphi'-`templo'
	local ylabmax=max(`ylabmax',`temphi')
	local ylabmin=min(`ylabmin',`templo')
	local yrange=`ylabmax' - `ylabmin'
	
	return local yrange `yrange'
	return local ylabmax `ylabmax'
	return local ylabmin `ylabmin'
end
///////////////////////////////////////////////////////////////////////////////////////////////
//Version 
//*! 1.0.0   Feb 21, 2003 Matthias Schonlau 
//*! 1.0.1   Mar  2, 2003: Allow variables with one value, Bug fixed when barwidth was too large 
//*! 1.0.2   Mar 13, 2003: width changed to right-angle-width
//*! 1.0.3   Nov 20, 2003: hivar and hival options implemented 
//*! 1.0.4   no changes 
//*! 1.0.5   Nov  4, 2008: added samescale option, fixed bug related to >8 colors
//*! 1.1.0   ongoing 2017: major rewrite due to use of twoway rarea for parallelograms
//*! 1.1.1   May 17, 2022: added labeltextsize option
//*! 1.1.2   May 19, 2022: added argument to samescale option
//*! 1.1.3   Jun 30, 2022: fixed bug when not enough colors specified for highlighting
//*! 1.1.4   Jul  7, 2022: missing values can now be highlighted
//*! 1.2.0   Aug 11, 2022: shape rectangle added 
//*! 1.2.1   Nov 15, 2022: rectangle is default shape, space allowed w/o label, update helpfile
//*! 1.2.2   Jan 27, 2023: minbarfreq option added
//*! 1.2.3   Apr 12, 2023: Added warning if label value contains only white space
//*! 1.2.4   May 24, 2023: label_min_dist option
//*! 1.2.5   Oct 10, 2023: added option outline 
//*! 1.2.6   Nov 10, 2023: allow hivar to be a string variable 
//*! 1.2.7   Nov 13, 2023: remove display statement leftover from debugging
//*! 1.2.8   Nov 16, 2023: fixed bug related to "labelopt" 
//*! 1.2.9   Nov 17, 2023: colorlist now allows RGB values
//*! 1.3.0   Jan 26, 2024: removed duplicate code, improved documentation compute_vertical_width
//*! 1.4.0   Feb 21, 2024: For parallelogram, iterate between computing range and vertical width
//*! 1.4.1   Apr 01, 2024: fixed bug plotting labels for obs with missing values when not specifying missing
//*! 1.4.2   Apr 03, 2024: removed "set matsize" (obsolete in modern Stata) and corresponding error msg
//*! 1.4.3   Apr 05, 2024: allow hivalues with <=,>= signs , e.g. hivalues(>=2) 
//*! 1.4.4   Jul 22, 2024: accommodate scheme stcolor Stata18 adding xlab(,nogrid) ylab(,nogrid)
//*! 1.4.5   Jul 23, 2024: documentation on aspect ratio
//*! 2.0.0   Sep  5, 2024: add univariate bars
//*! 2.0.1   Sep 12, 2024: fixed bug related to labels with missing values
//*! 2.0.2   Sep 20, 2024: added label_format
//*! 2.0.3   Sep 26, 2024: changed default color to gs10
//*! 2.0.4   Nov 14, 2024: rewrote labels (using frames instead of tokenize). Better error message for string variables
//*! 2.0.5   Nov 18, 2024: fixed bug: missing lowest non-missing uni-bar pushed into missing
//*! 2.0.6   Nov 21, 2024: allow space(1.0); added subspace option
//*! 2.0.7   Feb 26, 2025: changed default color; add check_hivalues_exist; draft add_unibars_compare
//*! 2.0.8   Mar 28, 2025: option missing_fraction
//*! 2.0.9   Mar 31, 2025: removed bug for non-missing values with a missing label "."
//*! 2.1.0 	 Apr 18, 2025: redesigned/fixed placement of lowest, highest, and missing bars
//*! 2.1.1 	 May  2, 2025: axes label with variable *labels*; options label as default; outline off by default
//*! 2.1.2 	 May 12, 2025: fixed bug placing the highest label, added option unibar,fixed bug related to samescale
//*! 2.1.3   June 1, 2025: recomputed xrange/yrange; stata bug resolved re `uni_color' during scatter
//*! 2.1.4   June 4, 2025: fixed bugs: related to missings/string label format; related to space=0; added label_eps
//*! 2.1.5   June 9, 2025: moved connectors of uppermost and lowermost boxes to middle of box
//*! 2.1.6   June 13, 2025: added minbarfreq for univariate bars, compound quotes uni_colorlist
//*! 2.2.0   Jan 30, 2026: added individual labeling options: label_methodlist(), label_too_many(), , new default colorlist