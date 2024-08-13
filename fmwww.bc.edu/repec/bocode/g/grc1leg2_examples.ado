*! version 2.26 4Nov2023 by Mead Over, Center for Global Development
*! Companion program to be executed by the help file: grc1leg2.sthlp
program grc1leg2_examples
	version 13.1
	if (_caller() < 13.1)  version 12
	else		      version 13.1

	set more off
	set graphics on
	`0'
	
	capture prog drop grc1leg2
end

program Msg
	di as txt
	di as txt "-> " as res `"`0'"'
end

program Xeq
	di as txt
	di as txt `"-> "' as res _asis `"`0'"'
	`0'
end

program define NewName
	args fn
	capture graph rename `fn' `fn'
	if _rc==0 {
		di as txt "{p 0 2 2}"
		di "Example cannot be run because a graph already in memory is named:"  ///
			_n "  {res:`fn'}."
		di as txt "Either drop this graph or simply click {stata graph drop _all}."  ///
			_n "Then start over with {stata graph drop _all}" _n
		di as err _n "graph -`fn'- already exists"
		error 110
	}
end

program setup
	graph drop _all
	capture sysuse auto2
	if _rc~=0 {
		Msg sysuse auto2
		di as err "no; data in memory would be lost"
		di as err "First {stata clear:clear} your memory before running these examples"
		exit
	}
	//	The -graph drop _all- command as the first line of -setup- obviates the following call to NewName
	/*
	foreach name in  ///
		grby3dflt grby3 grby5  ///  Three -by- graphs
		grcomb3 grcomb5 grcomb4 grcomb8  ///  Four -combined- graphs
		panel0 panel1 panel2 panel3 panel4 panel5 panel6 panel7 panel8 panel9 panel10 panel1_bis  ///  Twelve component panels
		pie_symbols sctr_markers sym_and_mark pie_dom_for bar_for pie_legend  ///  Additional component panels
		grc14dflt grc13woxtob1 grc13_offset grc13 grc13_bis grc18pnl grc14pnl  /// -grc1leg2- examples
		grc1fromby grc1fromcomb   /// ... demonstrating recursiveness
		grc13legscale grc13labsize    /// ... demonstrating legend scaling
		grc1y2tor1     /// -grc1leg- examples demonstrating moving y2 title to r1 title
		grc1hide grc1hide2     /// ... demonstrating use of a hiddne legend
		grc1bar_of_pie grc1bar_of_pie_edit     /// ... demonstrating -bar-of-pie- graph
		grc13_dispopts    /// ... demonstrating -gr display- opts
		grc1lcols grc1lcolsasis   /// ... demonstrating known problem with using lcol() or lrow()
	{	
		NewName `name'
	}
	*/

	set more off
	Xeq sysuse auto2
	Xeq drop if missing(rep78)
	Xeq gen byte qual = 1*(rep78<3)+2*(rep78==3)+3*(rep78>=4)
	Xeq lab def qual 1 "Low Quality"  2  "Medium Quality"  3  "High Quality"
	Xeq lab value qual qual
	Xeq lab var qual "Quality: Mapping of rep78 into trichotomy"
	Xeq tab rep78 qual
end

program grby3dflt
*	NewName grby3dflt  //  These checks are unnecessary because of the name() suboption -replace-
	Xeq twoway  ///
		(scatter mpg weight)  ///
		(lfit mpg weight ),  ///
			by(qual,  ///
				title("Ex. 1.0: Three panels, with legend at 6 o'clock")  ///
				subtitle("Use -twoway ..., by()- without options") ///
			)  ///
		name(grby3dflt, replace)
end

program grby3
*	NewName grby3  //  These checks are unnecessary because of the name() suboption -replace-
	set graphics on
	Xeq twoway  ///
		(scatter mpg weight)  ///
		(lfit mpg weight ),  ///
			legend(col(1)) ///
			by(qual,  ///
				legend(pos(0) at(4))  ///
				title("Ex. 1.1: Three panels, with legend in a hole")  ///
				subtitle("Use -twoway ..., by()- with -at(4) pos(5)-") ///
			)  ///
		name(grby3, replace)
end

program grby5
*	NewName grby5
	set graphics on
	Xeq twoway  ///
		(scatter mpg weight)  ///
		(lfit mpg weight ),  ///
			legend(col(1)) ///
			by(rep78,  ///
				legend(pos(0) at(6))  ///
				title("Ex. 1.2: Five panels, with legend in a hole")  ///
				subtitle("Use -twoway ..., by()- with -at(6) pos(0)-") ///
			)   ///
		name(grby5, replace)

end

program make4panels
*	NewName panel1
*	NewName panel2
*	NewName panel3
*	NewName panel0
	
	Xeq set graphics off
	
	Xeq twoway  ///
		(scatter mpg weight if qual==1)  ///
		(lfit mpg weight if qual==1),  ///
			ytitle(Miles per gallon)  ///
			subtitle("Low Quality")  ///
			legend(col(1) off) ///  Hidden legend has one column
			name(panel1, replace)

	Xeq twoway  ///
		(scatter mpg weight if qual==2)  ///
		(lfit mpg weight if qual==2),  ///
			ytitle(Miles per gallon)  ///
			subtitle("Medium Quality")  ///
			legend(row(1) off) ///  Hidden legend has one row
			name(panel2, replace)

	Xeq twoway  ///
		(scatter mpg weight if qual==3)  ///
		(lfit mpg weight if qual==3),  ///
			ytitle(Miles per gallon)  ///
			subtitle("High Quality")  ///
			legend(col(1) ring(0) pos(3) xoffset(55) )  ///
			name(panel3, replace)

	Xeq twoway  ///
		(scatter mpg weight)  ///
		(lfit mpg weight),  ///
			ytitle(Miles per gallon)  ///
			subtitle("Entire sample")  ///
			legend(col(1) ring(0) pos(3) xoffset(40) )  ///
			name(panel0, replace)

	Xeq set graphics on
	
	di as txt _n "*        List the named graphs now in memory"
	Xeq graph dir, memory // These named graphs are now in memory
	
end

program grcomb4
*	NewName grcomb4
	set graphics on
	Xeq gr combine panel1 panel2 panel3 panel0,  ///
		xcommon ycommon  ///
		title("Ex. 2.0: Four panels, with legend at bottom")  ///
		subtitle("Without tedious edits, the combined legend is misplaced")  ///
		name(grcomb4, replace) 
	
end

program grcomb3
*	NewName grcomb3
	set graphics on
	Xeq gr combine panel1 panel2 panel3,  ///
		xcommon ycommon ///
		title("Ex. 2.1: Three panels, with legend in a hole")  ///
		subtitle("Use -gr combine ... , having specified"  ///
			"-col(1) ring(0) pos(3) xoffset(55)- on -panel3-")  ///
		name(grcomb3, replace) 
	
end

program grcomb5
*	NewName grcomb5
	set graphics on
	Xeq gr combine panel1 panel2 panel1 panel2 panel0,  ///
		xcommon ycommon  ///
		title("Ex. 2.2: Five panels, with legend in a hole")  ///
		subtitle("Use -gr combine ... , having specified"  ///
			"-ring(0) pos(5) xoffset(40)- on the last panel")  ///
		name(grcomb5, replace) 
	
end

program grcomb8
*	NewName grcomb8
	set graphics on
	Xeq gr combine panel1 panel2 panel1 panel0 panel1 panel2 panel1 panel2,  ///
		xcommon ycommon holes(5)    ///
		title("Ex. 2.3: Eight panels, with legend in the middle")  ///
		subtitle("Use -gr combine ... , having specified"  ///
			"-ring(0) pos(3) xoffset(40)- on graph for the fourth panel")  ///
		name(grcomb8, replace) 

end

*	Example 3.0: Using grc1leg2 without options
program grc4dflt
*	NewName grc4dflt

	if "$grc1leg2_saving"~= "" {
		local saving saving(grc4dflt, replace $asis )
	}

	set graphics on
	Xeq grc1leg2 panel0 panel1 panel2 panel3 ,  ///
		title("Ex. 3.0: Four panels")  ///
		subtitle("Use -grc1leg2- to borrow the legend from panel0")  ///
		name(grc14dflt, replace)  `saving'
		
end

*	Example 3.1: Using grc1leg2 to display three panels with their legend in a "hole"
program grc3woxtob1
*	NewName grc3woxtob1

	if "$grc1leg2_saving"~= "" {
		local saving saving(grc3woxtob1, replace $asis )
	}

	set graphics on
	Xeq grc1leg2 panel1 panel2 panel3,  ///
		ring(0) pos(5)  ///
		title("Ex. 3.1: Three panels, with legend in a hole")  ///
		subtitle("Use -grc1leg2- with options -ring(0) pos(5)- " /// 
			"without the option -xtob1title-")  ///
		name(grc13woxtob1, replace)  `saving'
		
end

*	Example 3.2: Using grc1leg2 to offset the combined legend
*		Saved file does NOT match displayed file (offset is undone)  FIXED
program grc3_offset
*	NewName grc3woxtob1
	if "$grc1leg2_saving"~= "" {
		local saving saving(grc3_offset, replace $asis)
	}

	set graphics on
	Xeq grc1leg2 panel1 panel2 panel3,  ///
		ring(0) pos(5)  ///
		lxoffset(-20) lyoffset(17)  ///
		title("Ex. 3.2: Three panels, with legend in a hole")  ///
		subtitle("Use -grc1leg2- with options -ring(0) pos(5)- " /// 
			 "fine-tuned with legend offset options")  ///
		name(grc13_offset, replace)   `saving' 
		
*	di as txt "To open and display the gph file from disk click {stata graph use grc3_offset.gph:here}."	


end

*	Example 3.3: Using grc1leg2 to suppress redundant axis titles
*		Previous issue: Titles were correctly moved, but legend offset is undone.  FIXED)
program grc3
*	NewName grc3
	if "$grc1leg2_saving"~= "" {
		local saving saving(grc3, replace $asis)
	}

	set graphics on
	Xeq grc1leg2 panel1 panel2 panel3,  ///
		xcommon ycommon ring(0) pos(5)  ///
		lxoffset(-10) lyoffset(17)  ///
		title("Ex. 3.3: Three panels, with legend in a hole")  ///
		subtitle("Use -grc1leg2- with options -ring(0) pos(5)- " /// 
			"with the offset options plus -xtob1title- and -ytol1title-")  ///
		xtob1title ytol1title  ///
		name(grc13, replace)  `saving' 

*	di as txt "To open and display the gph file from disk click {stata graph use grc3.gph:here}."	

end

*	Example 3.3_bis: Using grc1leg2 to suppress redundant main, sub or note text,
*		moving it to the combined graph.
program grc3_bis
*	NewName grc13_bis
	if "$grc1leg2_saving"~= "" {
		local saving saving(grc3_bis, replace $asis)
	}

	Xeq set graphics off

	Xeq twoway  ///
		(scatter mpg weight if qual==1, yaxis(1))  ///
		(lfit mpg weight if qual==1),  ///
			title("Ex. 3.3_bis: Move main title and note to combined graph")  ///
			subtitle("Low Quality")  ///
			note("Source: Gibbon, Edward (1890) The Decline and Fall of the Roman Empire."  ///
				"              London: F. Warne and Co.")  ///
			ytitle(Miles per gallon)  ///
			legend(col(1) off) ///
			name(panel1_bis, replace)

	Xeq set graphics on
	
	Xeq grc1leg2 panel1_bis panel2 panel3,  ///
		xcommon ycommon ring(0) pos(5)  ///
		lxoffset(-10) lyoffset(17)  ///
		xtob1title ytol1title maintotoptitle notetonote  ///
		name(grc13_bis, replace)  `saving' 

*	di as txt "To open and display the gph file from disk click {stata graph use grc13_bis.gph:here}."	

end

*	Examples 3.4a, 3.4b: Using grc1leg2 to edit characteristics of legend elements
program grc3legscale
*	NewName grc13legscale
	if "$grc1leg2_saving"~= "" {
		local saving saving(grc13legscale, replace $asis)
	}

	set graphics on
	Xeq grc1leg2 panel1 panel2 panel3,  ///
		xcommon ycommon ring(0) pos(5)  ///
		lxoffset(-6) lyoffset(14)  ///
		title("Ex. 3.4a: Three panels, with legend in a hole")  ///
		subtitle("Use -grc1leg2- with options -ring(0) pos(5)- " /// 
			"and with -legscale(*1.2) lmsize(*.8)-")  ///
		xtob1title ytol1title legscale(*1.2) lmsize(*.8)  ///
		name(grc13legscale, replace)  `saving' 

*	di as txt "To open and display the gph file from disk click {stata graph use grc13legscale.gph:here}."

end 

program grc3labsize
*	NewName grc3labsize
	if "$grc1leg2_saving"~= "" {
		local saving saving(grc3labsize, replace $asis)
	}

	set graphics on
	Xeq grc1leg2 panel1 panel2 panel3,  ///
		xcommon ycommon ring(0) pos(5)  ///
		lxoffset(-6) lyoffset(14)  ///
		title("Ex. 3.4b: Three panels, with legend in a hole")  ///
		subtitle("Use -grc1leg2- with options -ring(0) pos(5)- and with the" /// 
			"offset, borrowed title, -labsize(*1.2)- and -symxsize(*1.2)- options")  ///
		xtob1title ytol1title labsize(*1.2) symxsize(*1.2) ///
		name(grc13labsize, replace)  `saving' 

*	di as txt "To open and display the gph file from disk click {stata graph use grc3labsize.gph:here}."	

end

*	Example 3.5: Using grc1leg2 to put a legend in the middle of eight panels
*		Works: Saved file matches displayed file
program grc8pnl
*	NewName grc8pnl
	if "$grc1leg2_saving"~= "" {
		local saving saving(grc8pnl, replace $asis)
	}

	set graphics on
	Xeq grc1leg2 panel1 panel2 panel3 panel2 panel3 panel2 panel3 panel2,  ///
		xcommon ycommon ring(0) pos(0) holes(5)  ///
		title("Ex. 3.5: Eight panels: with legend in middle")  ///
		subtitle("Use -grc1leg2- with options -ring(0) pos(0) holes(5)-  "  ///
			"with the options -xtob1title- and -ytol1title-")  ///
		xtob1title ytol1title  ///
		name(grc18pnl, replace) `saving' 

*	di as txt "To open and display the gph file from disk click {stata graph use grc8pnl.gph:here}."	

end
 
*	Example 3.6: Using grc1leg2 to put the legend below the -b1title-
program grc4pnl
*	NewName grc4pnl
	if "$grc1leg2_saving"~= "" {
		local saving saving(grc4pnl, replace)
	}

	set graphics on
	Xeq grc1leg2 panel0 panel1 panel2 panel3 ,  ///
		xcommon ycommon ring(2) legendfrom(panel2) ///
		title("Ex. 3.6: Four panels: with legend at bottom")  ///
		subtitle("Use -grc1leg2- with option -ring(2)-  "  ///
			"with the options -xtob1title- and -ytol1title-")  ///
		xtob1title ytol1title  ///
		name(grc14pnl, replace) `saving' 

*	di as txt "To open and display the gph file from disk click {stata graph use grc4pnl.gph:here}."	

end

*	Example 3.7: Borrowing the legend from a graph created by -graph ..., by()-
program grcfromby
*	NewName grcfromby
	if "$grc1leg2_saving"~= "" {
		local saving saving(grcfromby, replace $asis)
	}

	set graphics off
	cap gr des grby3
	if _rc>0 qui grby3
	cap gr des grcomb3
	if _rc>0 qui grcomb3
	set graphics on
	Xeq grc1leg2 grby3 grcomb3,  ///
		title("Ex. 3.7: Relocating the legend from a by() graph")  ///
		altshrink  ///
		name(grc1fromby, replace) `saving' 

*	di as txt "To open and display the gph file from disk click {stata graph use grcfromby.gph:here}."	

end
 
*	Example 3.8: Borrowing the legend from a graph created by -graph combine-
*		Saved file does NOT match displayed file.  FIXED IN VERSION 1.62
program grcfromcomb
*	NewName grcfromcomb
	if "$grc1leg2_saving"~= "" {
		local saving saving(grcfromcomb, replace $asis)
	}

	cap gr des grby3
	if _rc>0 qui grby3 
	cap gr des grcomb3
	if _rc>0 qui grcomb3
	set graphics on
	Xeq grc1leg2 grcomb3 grby3,  ///
		title("Ex. 3.8: Relocating the legend from a combined graph")  ///
		altshrink  ///
		name(grc1fromcomb, replace)  `saving' 

*	di as txt "To open and display the gph file from disk click {stata graph use grcfromcomb.gph:here}."	

end

*	Example 3.9: Relocating the titles on a second y-axis
*		Titles and legend are correctly moved, but -lcols1()- is undone
*		So move the legend(cols(1)) option to the -panel4- legend.
program grcy2tor1
*	NewName grcy2tor1
	if "$grc1leg2_saving"~= "" {
		local saving saving(grcy2tor1, replace $asis)
	}
	
	set more off
	Xeq set graphics off
	Xeq twoway  ///
		(scatter mpg weight if qual==1, yaxis(1))  ///
		(scatter length weight if qual==1, yaxis(2)),  ///
			subtitle("Low Quality")  ///
			ylabel(,angle(hor) axis(2))  ///
			legend(cols(1))  ///
			name(panel4, replace)
	
	Xeq twoway  ///
		(scatter mpg weight if qual==2, yaxis(1))  ///
		(scatter length weight if qual==2, yaxis(2)),  ///
			subtitle("Medium Quality")  ///
			ylabel(,angle(hor) axis(2))  ///
			name(panel5, replace)
	
	Xeq twoway  ///
		(scatter mpg weight if qual==3, yaxis(1))  ///
		(scatter length weight if qual==3, yaxis(2)),  ///
			subtitle("High Quality")  ///
			ylabel(,angle(hor) axis(2))  ///
			name(panel6, replace)
	Xeq set graphics on
		
	Xeq grc1leg2 panel4 panel5 panel6,  ///
		title("Ex. 3.9: Relocating the title on yaxis(2)")  ///
		xtob1title ytol1title y2tor1title  ///
		pos(4) ring(0) lxoffset(-20) lyoffset(15)  ///
		name(grc1y2tor1, replace)  `saving' 

*	di as txt "To open and display the gph file from disk click {stata graph use grcy2tor1.gph:here}."	

end

*	Example 3.10: Making a composite legend using the -hidelegendfrom- option 
*		Setting the columns(1) option on the component legend sidesteps 
*		the difficulty with saving the effects of options -lcols()- and -lrows()-

*	Example 3.10a creates grchide, which combines several scatters with -lfitci-
program grchide
*	NewName grchide
	if "$grc1leg2_saving"~= "" {
		local saving saving(grchide, replace $asis)
	}

	set more off
	Xeq set graphics off
	
	Xeq twoway  ///
		(scatter mpg weight, mcolor(blue)),  ///
			name(panel7, replace)
	
	Xeq twoway  ///
		(scatter length weight, mcolor(red)),  ///
			name(panel8, replace)
	
	Xeq twoway  ///
		(scatter price weight, mcolor(green))  ///
		(lfitci  price weight, lcolor(green)),  ///
			ytitle(Price)  ///
			name(panel9, replace)
	
	Xeq twoway  ///  This is the component graph from which we take the legend
		(scatter mpg weight, mcolor(blue))  ///
		(scatter length weight, mcolor(red))  ///
		(scatter price weight, mcolor(green))  ///
		(lfitci  price weight, lcolor(green)),  ///
			legend(colfirst cols(2) order(1 2 3 5 4) holes(3))  ///  <- Alternative to -grc1leg2-'s -lcols()- 
			name(panel10, replace)
			
	Xeq set graphics on
	
	Xeq grc1leg2 panel7 panel8 panel9 panel10,  ///
		title("Ex. 3.10a: Assemble the legend keys from different panels"   ///
			"to construct the combined legend")  ///
		subtitle("Combining twoway graphs with different markers")  ///
		xtob1title legendfrom(panel10) hidelegendfrom  ///
		pos(4) ring(0) lyoffset(15)  ///
		name(grc1hide, replace)   `saving' 

*	di as txt "To open and display the gph file from disk click {stata graph use grchide.gph:here}."	

end 

*	Example 3.10b creates grchide2, which combines a pie chart with scatter plots.
program grchide2
*	NewName grchide2
	if "$grc1leg2_saving"~= "" {
		local saving saving(grchide2, replace $asis)
	}

	Xeq set graphics off

	//  The pie graph's legend has symbols.
	Xeq graph pie, over(qual) plabel(_all percent, format(%5.1f) size(vlarge))  ///
		name(pie_symbols, replace)

	//  The scatter plot's legend has markers.
	Xeq tw  (scatter price weight if qual==1, pstyle(p1pie) msym(Oh))  ///
		(scatter price weight if qual==2, pstyle(p2pie))  ///
		(scatter price weight if qual==3, pstyle(p3pie)),  ///
		name(sctr_markers, replace)
		
	//  The auxiliary graph needed for its legend has both symbols and markers 
	Xeq tw  (rarea price price weight if qual==1)  ///
		(rarea price price weight if qual==2)  ///
		(rarea price price weight if qual==3)   ///
		(scatter price weight if qual==1, pstyle(p1pie) msym(Oh))  ///
		(scatter price weight if qual==2, pstyle(p2pie))  ///
		(scatter price weight if qual==3, pstyle(p3pie)),  ///
		legend(  ///
			label(1 "Low Quality") ///
			label(2 "Medium Quality") ///
			label(3 "High Quality") ///
			label(4 "Low Quality") ///
			label(5 "Medium Quality") ///
			label(6 "High Quality") ///
			rows(2)  ///
		)  ///
		name(sym_and_mark, replace)

	Xeq set graphics on
	
	Xeq grc1leg2 pie_symbols sctr_markers sym_and_mark,  ///
		title("Ex. 3.10b: Assemble the legend keys from different panels"   ///
			"to construct the combined legend")  ///
		subtitle("Combining graphs with and without markers")  ///
		legendfrom(sym_and_mark) hidelegendfrom  ///
		name(grc1hide2, replace) `saving' 

*	di as txt "To open and display the gph file from disk click {stata graph use grchide2.gph:here}."	

end 

*	Example 3.10c creates -bar_of_pie-, which combines an exploded pie chart with a bar chart
*		This example demonstrates a graph with a "landscape" aspect ratio. 
program bar_of_pie
*	NewName grc1bar_of_pie
	if "$grc1leg2_saving"~= "" {
		local saving saving(grc1bar_of_pie, replace $asis)
	}

	cap drop forcntry
	cap label drop forcntry
	di _n as txt "Generate a discrete variable with three categories of foreign cars by country of manfacture"
	Xeq gen byte forcntry = 1 if foreign
		Xeq replace forcntry = 2 if inlist(word(make,1),"VW", "BMW", "Audi")
		Xeq replace forcntry = 3 if inlist(word(make,1),"Datsun", "Honda", "Mazda", "Toyota")
	
		label define forcntry 1 "Other foreign" 2 "Germany" 3 "Japan" 
		label values forcntry forcntry
	
	di _n as txt "The new categorical variable is defined only for foreign cars"
	Xeq tab forcntry foreign, mi
	
	Xeq set graphics off

	di _n as txt "The big picture: Foreign as a share of all models in 1978"
	Xeq gr pie , over(foreign) angle(305) plabel(_all percent, size(large) format(%6.1f)) ///
		subtitle(Shares of domestic and foreign models)  ///
		pie(1) pie(2, explode)   ///
		graphregion(margin(l -25) ) ///  <- to prepare for landscape orientation
		name(pie_dom_for, replace)

	di _n as txt "Zoom in on the distribution of foreign models by country of origin"
	Xeq gr bar (percent), over(forcntry) asyvars stack yalternate  ///
		bar(1, bstyle(p3bar)) bar(2, bstyle(p4bar)) bar(3, bstyle(p5bar) ) ///
		blabel(bar ,pos(center) size(large) format(%6.1f))  ///
		graphregion(margin(r +25) ) fxsize(35)  ///  <- to prepare for landscape orientation  
		subtitle("Breakdown of foreign models")  ///
		name(bar_for, replace) `saving'
	
	di _n as txt `"We create a "dummy graph" with five categories for the sole purpose of using its legend in the combined graph."'
	Xeq gr pie , over(rep78) ///
		legend(colfirst cols(6) holes(3/15)  ///
			title("Location of manufacturer")  ///
			order(  ///
				1 "Domestic" ///
				2 "Foreign"  ///
				5 "Japan"    ///
				4 "Germany"  /// 
				3 "Other foreign"  ///
			) )  ///
		name(pie_legend, replace)

	Xeq set graphics on
	di _n as txt "-grc1leg2- allows us to apply the legend from the dummy graph to the combined graph"
	Xeq grc1leg2 pie_dom_for bar_for pie_legend, legendfrom(pie_legend) hidelegendfrom  ///
		title("Ex. 3.10c: Distribution of automobile models by domestic and foreign"  ///
		"and within foreign, by country of origin")  ///
		xsize(9) ysize(5)  ///  <- landscape orientation
		name(grc1bar_of_pie, replace) `saving'

*	di as txt "To open and display the gph file from disk click {stata graph use grc1bar_of_pie.gph:here}."	

end 

*	Play the pre-recorded -grec- file to add the arrows to the bar_of_pie graph
program play_grec_on_Ex_3_10c
*	NewName grc1bar_of_pie_edit
	if "$grc1leg2_saving"~= "" {
		local saving gr save grc1bar_of_pie_edit, replace $asis
	}

	set graphics off 
	cap gr display grc1bar_of_pie
	if _rc>0 {
		di as txt "The graph named -grc1bar_of_pie- produced by Example 3.10c must be present "  ///
			_n as txt "as a memory graph before it can be edited."  ///
			_n as txt "First, quietly execute Example 3.10c to create the memory graph -grc1bar_of_pie-:"
		di as smcl `"{it:({stata "qui grc1leg2_examples bar_of_pie":click to create -grc1bar_of_pie-})}"'
		di as err "Then try again to add the arrows:"
		di as smcl `"{it:({stata "grc1leg2_examples play_grec_on_Ex_3_10c":click to add arrows to the "bar of pie" graph})}"'
		exit
	}

	cap graph copy grc1bar_of_pie grc1bar_of_pie_edit, replace
	
	// Line from the bottom of the exploded slice to the bottom of the stacked bar
	//    First two numbers are coordinates of the arrow        X-coord   Y-coord
	//    Second two numbers are coordinates of the base                            X-coord   Y-coord
	_gm_edit .grc1bar_of_pie_edit.plotregion1.graph2.plotregion1.AddLine added_lines editor     0.        0.     -230.0     12.0
	_gm_edit .grc1bar_of_pie_edit.plotregion1.graph2.plotregion1.added_lines_new = 1
	_gm_edit .grc1bar_of_pie_edit.plotregion1.graph2.plotregion1.added_lines_rec = 1
	// edits
	
	_gm_edit .grc1bar_of_pie_edit.plotregion1.graph2.plotregion1.added_lines[1].style.editstyle linestyle(pattern(dash)) editcopy
	_gm_edit .grc1bar_of_pie_edit.plotregion1.graph2.plotregion1.added_lines[1].style.editstyle headpos(tail) editcopy
	// line[1] edits
	
	// Line from the top of the exploded slice to the top of the stacked bar
	//    First two numbers are coordinates of the arrow        X-coord   Y-coord
	//    Second two numbers are coordinates of the base                            X-coord   Y-coord
	_gm_edit .grc1bar_of_pie_edit.plotregion1.graph2.plotregion1.AddLine added_lines editor     0.      100.0     -230.0    90.0
	_gm_edit .grc1bar_of_pie_edit.plotregion1.graph2.plotregion1.added_lines_new = 2
	_gm_edit .grc1bar_of_pie_edit.plotregion1.graph2.plotregion1.added_lines_rec = 2
	// edits
	
	_gm_edit .grc1bar_of_pie_edit.plotregion1.graph2.plotregion1.added_lines[2].style.editstyle linestyle(pattern(dash)) editcopy
	_gm_edit .grc1bar_of_pie_edit.plotregion1.graph2.plotregion1.added_lines[2].style.editstyle headpos(tail) editcopy
	// line[2] edits
	
	set graphics on
	di as txt "Displaying memory graphs -grc1bar_of_pie- and -grc1bar_of_pie_edit-" _n 
	gr display grc1bar_of_pie
	gr draw grc1bar_of_pie_edit
	`saving'
		
	exit	
	
end

*	Example 3.11: Changing the overall look of a combined graph
*		Saved file does NOT match displayed file: FIXED
program grc3_dispopts
*	NewName grc13_dispopts
	if "$grc1leg2_saving"~= "" {
		local saving saving(grc3_dispopts, replace $asis)
	}

	set graphics on
	Xeq grc1leg2 panel1 panel2 panel3,  ///
		xcommon ycommon ring(0) pos(5)  ///
		lxoffset(-5) lyoffset(15)  ///
		xtob1title ytol1title  ///
		xsize(8) ysize(8) scheme(s1rcolor)  ///
		title("Ex. 3.11: is 3.3 with a different overall look")  ///
		subtitle("From the same component panels,"  ///
			"alter the overall look of the combined graph" /// 
			"using the xsize(), ysize() and scheme() options")  ///
		name(grc13_dispopts, replace)   `saving' 

*	di as txt "To open and display the gph file from disk click {stata graph use grc3_dispopts.gph:here}."	

end

*	Example 3.12: Change the legend's row and column arrangement
*		Show that saved "live" file does not preserve the changed arrangement.
program grclcols
*	NewName grclcols
	set graphics on
	Xeq grc1leg2 panel7 panel8 panel9 panel10,  ///
		title("Ex. 3.12: Change the legend's row and column arrangement"  ///
		`"with lcols(1) and save to disk as a "live" gph file"')  ///
		xtob1title legendfrom(panel10) hidelegendfrom  ///
		pos(4) ring(0) lxoffset(-5) lyoffset(15) lcols(1) ///
		name(grc1lcols, replace) saving(grclcols, replace)

end

*	Example 3.13: Scale one marker and one symbol in the combined graph
*		Saved file matches displayed file for one marker AND/OR one symbol: 
program grclcolsasis
*	NewName grclcolsasis
	set graphics on
	Xeq grc1leg2 panel7 panel8 panel9 panel10,  ///
		title("Ex. 3.13: Change the legend's row and column arrangement"  ///
		`"with lcols(1) and save to disk as an "asis" gph file"')  ///
		xtob1title legendfrom(panel10) hidelegendfrom  ///
		pos(4) ring(0) lxoffset(-5) lyoffset(15) lcols(1) ///
		name(grc1lcolsasis, replace) saving(grc1lcolsasis, replace asis)

end

*	Version 1.0.0 by Mead Over 1Apr2016
*		Based on Stata's gr_example2.ado, version 1.4.4  27aug2014
*	V. 1.0.1 11Apr2016: Adds the program -grc3lsize-
*	V. 1.0.2 23Jan2021: Renames it -grc3labsize-, adds -set graphics on- commands
*	V. 1.1	29Jan2021: Add the options xtsize, ytsize, mtsize and Example 3.6 (grc4pnl) 
*	V. 1.2	23Mar2021: Add the options xtsize, ytsize, mtsize and Example 3.6 (grc4pnl)
*	V. 1.3	26Mar2021: Add the program -grcy2tor1- to demonstrate reloaction of the y2-axis 
*	V. 1.5	4Apr2021: Demonstrate the option -lcols(1)- in -grchide-
*	V. 1.6  15Jun2021: Demo. added options for -gr display-
*	V. 2.0  3Mar2022: Substantial changes to work with revised -grc1leg2.sthlp-
*		In particular, the options -lcols()- and -lrows()- are moved to examples 12 and 13.
*		Examples 3.0, 3.4a and 3.4b are new.
*	V. 2.1  12Mar2022: Change panel9 to use -lfitci- and change Examples 3.10, 3.12 and 3.13.
*		Add Example 3.10_bis to demonstrate Known Issue #1.
*	V. 2.11 13Mar2022: Change Example 3.10_bis to specify that only *marker* resizing is disabled by an incomplete legend.
*	V. 2.20 15Jun2022: Add example 3.3_bis to show how a main title or a note can be suppressed or moved.
*	V. 2.21 15Nov2022: Add -graph drop _all- to the program -setup-
*	V. 2.22 1Dec2022: Add the example -grchide2- to Ex. 3.10
*	V. 2.23 10Dec2022: In Ex. 3.11, change to xsize(8), ysize(8)
*	V. 2.25 10Oct2023: Add Ex. 3.10c.  Remove example 3.10_bis, which was intended 
*		to crash -grc1leg2- when a legend had been modified by -order()- but no longer does so.
*	V. 2.26 4Nov2023: Update the list of named graphs checked by NewName
*		Add "set graphics on" as line 8.
*		Deprecate calls to NewName in favor of -graph drop _all- and name(..., replace)