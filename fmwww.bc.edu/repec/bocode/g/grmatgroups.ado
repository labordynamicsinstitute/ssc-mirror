* grmatgroups
* Version 1.2
* 30/09/2022

program define grmatgroups
version 14


* Syntax
syntax varlist(min=3 numeric) [if] [in], OVER(varname numeric) ///
	[MISSing ///
	Half ///
	POSition(passthru) ///
	ring(passthru) ///
	span ///
	legend(passthru) /// 
	MARKEROPTIONS(string asis) ///
	XLABel(passthru) ///
	YLABel(passthru) ///
	XSCale(passthru) ///
	YSCale(passthru) ///
	mlabsize(passthru) ///
	mlabcolor(passthru) ///	
	scheme(passthru) ///
	nodraw ///
	name(passthru) ///
	saving(passthru) ///
	title(passthru) ///
	subtitle(passthru) ///
	note(passthru) ///
	caption(passthru) ///
	t1title(passthru) ///
	t2title(passthru) ///
	b1title(passthru) ///
	b2title(passthru) ///
	l1title(passthru) ///
	l2title(passthru) ///
	r1title(passthru) ///
	r2title(passthru) ///
	]


* Checks and Locals

** dependency grc1leg
capture findfile grc1leg.ado
if "`r(fn)'" == "" {
	di as error "user-written package grc1leg needs to be installed first;"
	di as error "use -ssc install grc1leg- to do that"
	exit 498
}

** Main Variables
local number : word count `varlist' 

** If and In
tempvar touse
mark `touse' `if' `in'

** Over Variable
quietly levelsof `over', local(overlevels) `missing'
	
local valuelabel : value label `over' // label container for over var
local n_overlevels : word count `overlevels'

if "`valuelabel'" == "" {
	dis as text "Note: {bf: over()} variable does not have valuelabels. Using real values for the legend instead."
	local novaluelabels "true"
	local valuelabel = "`overlevels'"
}

** Legend Options
if strpos("`legend'", "pos") | strpos("`legend'", "ring") | strpos("`legend'", "span") {
	di as text "You specified one of the following legend options: pos, ring, span."
	di as text "If you want to change the position of the legend, the above options need to be outside of the legend argument."
}

** Marker Options
while regexm(`"`markeroptions'"', "[1-9]+( +m[a-z]+\([^\)]+\))+") == 1 { // parse options for each marker
	local submarkeroptions = regexs(0)
	qui dis regexm(`"`submarkeroptions'"', "[1-9]+ ")
	local mo = real(regexs(0)) // extract number for rank of the over value
	local marker`mo'options = regexr(`"`submarkeroptions'"', "[1-9]+ ", "")
	local markeroptions = regexr(`"`markeroptions'"', "[1-9]+( +m[a-z]+\([^\)]+\))+", "") // remove substring from main string
	if `mo' > `n_overlevels' {
		local markeroptionserror "yes"
	}
}

capture assert trim(`"`markeroptions'"') == ""
if c(rc) != 0 {
	dis as error "Part of the marker options do not seem to match the required form."
	exit 197
}

if "`markeroptionserror'" != "" {
	dis  as text "Note: You specified marker options for values outside the range of the {bf: over()} variable."
}


** Axis options
if regexm("`xlabel'", "angle") == 1 | regexm("`ylabel'", "angle"){
	dis "Unfortunately, it is not possible to change the angle of the axis labels."
	dis as error "See –help grmatgroups– for more information."
	exit 498
}

if regexm("`xlabel'", "alt") == 1 | regexm("`ylabel'", "alt"){
	dis as error "Unfortunately, the alternate option is not compatible with grmatgroups."
	dis as error "See –help grmatgroups– for more information."
	exit 498
}

if regexm("`xlabel'", "labstyle") == 1 | regexm("`ylabel'", "labstyle"){
	dis as text "Changing the compound style of labels can lead to suboptimal reuslts."
	dis as text "See –help grmatgroups– for more information."
}

** Scheme
if "`scheme'" == "" {
	if !inlist("`c(scheme)'", "s1mono", "s2mono", "s1color", "s2color") {
		local schemeerror "yes"
	}
}
else {
	if !inlist("`scheme'", "scheme(s1mono)", "scheme(s2mono)", "scheme(s1color)", "scheme(s2color)") {
		local schemeerror "yes"
	}
}

if "`schemeerror'" != "" {
	dis as text "Note: Specified or active scheme is not one of the recommended ones for this command;"
	dis as text "The result will probably look bad. I recommend using one of the s1 or s2 schemes."
}


** Define String for "holes" argument, when "half" is specified (could probably be simplified with some Maths)
if "`half'" == "half" {
	matrix A = J(`number', `number', .)
	
	*** Fill Matrix with element numbers (rowwise)
	local m = 1
	forval k = 1/`number' {
		forval l = 1/`number' {
			matrix A[`k',`l'] = `m'
			local ++m
		}
	}

	*** Get only upper half
	local max = `number' - 1 
	local first = 2
	forval k = 1/`max' {
		forval l = `first'/`number' {
			local temp = A[`k',`l']
			local holes = "`holes'" + " `temp'"	
		}
		local ++first
	}
}


* Draw Scatter Plots
//local aspectratio "aspectratio(0.7273)"
local var1number = 0
local i = 1
foreach var1 of varlist `varlist' {
	local ++var1number
	local var2number = 0
	foreach var2 of varlist `varlist' {
		local ++var2number
		
		** Specify additional labelopts for scatter plots
		/* they are merge-explicit, so can just be added to contradictory options, 
		   however the ordering is crucial: having all plots the same size is 
		   achieved by specifying invisible labels for every second plot. In order
		   to not let this be overwritten by passthru options, these must come prior 
		   to the fixed options for invisible labels, and after fixed options for 
		   visible labels. */
		   
		local labelopts "" // otherwise, the value of the last iteration is left
		
		*** Options
		local xscale_black		"xscale(on noline)"
		local yscale_black 		"yscale(on noline)"
		
		local xscale_bg			"xscale(on noline) xlabel(, labcolor(bg) tlcolor(bg))"
		local yscale_bg			"yscale(on noline) ylabel(, labcolor(bg) tlcolor(bg))"

		
		*** 0: No labels whatsoever
		local xlabelopts "xscale(off)"
		local ylabelopts "yscale(off)"
		
		*** 1: Labels Above
		if mod(`var2number', 2) == 0 & `var1number' == 1 {
			local xlabelopts "`xscale_black' xscale(alt) `xlabel' `xscale'"
		}

		*** 2: Invisible Labels above
		if mod(`var2number', 2) == 1 & `var1number' == 1 {
			local xlabelopts "`xlabel' `xscale' `xscale_bg' xscale(alt)"
		}

		*** 3: Labels below
		if mod(`var2number', 2) == 1 & `var1number' == `number' {
			local xlabelopts "`xscale_black' `xlabel' `xscale'"
		}

		*** 4: Invisibel Labels below
		if mod(`var2number', 2) == 0 & `var1number' == `number' {
			local xlabelopts "`xlabel' `xscale'`xscale_bg'"
		}
		
		*** 5: Labels left
		if mod(`var1number', 2) == 0 & `var2number' == 1 {
			local ylabelopts "`yscale_black' `ylabel' `yscale'"
		}
		
		*** 6: invisible labels left
		if mod(`var1number', 2) == 1 & `var2number' == 1 {
			local ylabelopts "`ylabel' `yscale' `yscale_bg'"
		}
		
		*** 7: labels right
		if mod(`var1number', 2) == 1 & `var2number' == `number' {
			local ylabelopts "`yscale_black' yscale(alt) `ylabel' `yscale'"
		}
				
		*** 8: invisible labels right
		if mod(`var1number', 2) == 0 & `var2number' == `number' {
			local ylabelopts "`ylabel' `yscale' `yscale_bg' yscale(alt)"
		}
		
		
		** Scatter Plots for diagonal plots containing titles
		if "`var1'" == "`var2'" {
			local varlab : variable label `var1'
			qui sum `var1', detail
			local varmean = (r(max) + r(min)) / 2
			tw	(scatter `var1' `var2' if `touse' ///
					, msymbol(none) xtitle("") ytitle("")) ///
				(scatteri 1 1 "`varlab'" ///
					, msymbol(none)  mlabpos(0) ///
					xaxis(2) xscale(axis(2) off) yaxis(2) yscale(axis(2) off) /// 
					mlabsize(huge) mlabcolor(black) `mlabsize' `mlabcolor') ///
				, `xlabelopts' `ylabelopts' ylabel(, nogrid) xlabel(, nogrid)  ///
				  plotregion(lstyle(axisline)) graphregion(margin(zero)) ///
				  legend(off) `aspectratio' name(plot`i', replace) `scheme' nodraw
			local combine_string = "`combine_string'" + "plot`i' "
			local ++i
			continue
		}
		

		** Scatter Plots
		if strpos("`holes'", "`i'") == 0 {
			local jn = 1
			local scatter_string ""
			local legend_string ""
			foreach j of numlist `overlevels' {
				local scatter_string = `"`scatter_string'"' + `" (scatter `var1' `var2' if `touse' & `over' == `j', `marker`jn'options')"'
				if "`novaluelabels'" == "true" {
					local label : word `jn' of `valuelabel'
				}
				else {
					local label : label `valuelabel' `j', strict
				}
				local legend_string = `"`legend_string'"' + `" `jn' "`label'" "'
				local ++jn
			}
			tw `scatter_string' ///
				, xtitle("") ytitle("") ///
				  `xlabelopts' `ylabelopts' xlabel(, nogrid) ylabel(, nogrid) ///
				  plotregion(lstyle(axisline)) graphregion(margin(zero)) ///
				  `aspectratio' legend(order(`legend_string')) ///
				  `legend' `scheme' ///
				  nodraw name(plot`i', replace)
			local combine_string = "`combine_string'" + "plot`i' "
		}
		local ++i
	}
}


* Draw Matrix of Scatter Plots
if `"`legend'"' == "legend(off)" {
	graph combine `combine_string', ///
		rows(`number') holes(`holes') ///
		`nodraw' `name' `saving' `title' `subtitle' `note' `caption' 
	exit
}

if "`half'" == "half" {
	local legendfrom = 1 + `number'
	grc1leg `combine_string', ///
		rows(`number') legendfrom(plot`legendfrom') holes(`holes') ///
		`position' `ring' `span' ///
		`nodraw' `name' `saving' `title' `subtitle' `note' `caption' 
}
else {
	grc1leg `combine_string', ///
		rows(`number') legendfrom(plot2) ///
		`position' `ring' `span' ///
		`nodraw' `name' `saving' `title' `subtitle' `note' `caption' 
}
end


