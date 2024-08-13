capture log close
set more off
graph drop _all
serset clear
cap prog drop grc1leg2
cap prog drop grc1leg2_examples
mata : mata clear

log using grc1test, replace

*	Updated 4Nov2023 to use version 2.26 of -grc1leg2- and its help file

clear
graph drop _all
set graph on

*************************************************************************************
*	This DO file demonstrates alternative approaches to adding a single 
*	legend to a Stata graph with several panels.

*	For each of three approaches to creating a multi-panel graph with a single legend,
*	this DO file first executes examples from  the help file, -grc1leg2.sthlp-, 
*	and then runs code for the two-panel versions not included in the help file.

*	By default, Stata's -pause- setting is -off-.
*		Removing the asterisk in front of the following command 
*		causes this DO file to pause after each constructed graph,
*		allowing the user to follow the narrative by reading
*		the comments associated with each graph.

*pause on

*************************************************************************************

cap prog drop pause_msg
prog def pause_msg 
	pause Type "q" to continue or "BREAK" to stop:
end
*        0.  Set up the data
*        ===================

grc1leg2_examples setup

*	For some two-panel graph examples, 
*	we need a dichotomous variable with only two values.
gen byte qual2 = 2*(rep78<=3)+3*(rep78>=4)
	lab value qual2 qual
	
*	Here's how -qual- and -qual2- compare
tab qual qual2	

	pause_msg
*        1.  Examples of the one-step procedure, using -graph..., by()-
*        ===============================================================

*	Example 1.0 from -grc1leg2.sthlp-
grc1leg2_examples grby3dflt
	pause_msg

*	Example 1.1 from -grc1leg2.sthlp-
grc1leg2_examples grby3
	pause_msg

*	Example 1.2 from -grc1leg2.sthlp-
grc1leg2_examples grby5
	pause_msg

*	Example 1.3
*	(omitted from the help file for -grc1leg2-)

*	With only two panels, -graph twoway ..., by()- puts 
*	a common legend centrally spaced below the common xtitle.
*	Works well when the number of resulting panels is even.
twoway  ///
	(scatter mpg weight)  ///
	(lfit mpg weight),  ///
		by(qual2,  ///
			title("Ex. 1.3: Two panels using -twoway ..., by()-")  ///
			subtitle("With an even number of panels" "default legend placement at 6 o'clock is satisfactory") ///
		)  ///
	name(grby2_pos6, replace)
	pause_msg

*	Example 1.4 
*	(omitted from the help file for -grc1leg2-)

*	-graph twoway ..., by(,leg(ring(0) pos(0) at(2)))- 
*	can insert a common legend between two panels.
*	Only works if the -by variable- has exactly two values.
twoway  ///
	(scatter mpg weight)  ///
	(lfit mpg weight),  ///
		legend(col(1)) ///
		by(qual2,  ///
			cols(3) holes(2) legend(ring(0) pos(0) at(2)) ///
			title("Ex. 1.4: Two panels with legend in a hole")  ///
			subtitle( "-twoway ..., by(..., cols(3) holes(2) leg(ring(0) pos(0) at(2)))-" )  ///
		)  ///
	name(grby2_pos0, replace)
	pause_msg

*        2.  Examples of a two-step procedure, using gr combine:
*        =======================================================

*	Make four component graphs -panel0- ... -panel3-
*	These memory graphs are used here and 
*	also in demonstrating -grc1leg2- in section 3.
grc1leg2_examples make4panels
	pause_msg

*	Example 2.1 from -grc1leg2.sthlp-
grc1leg2_examples grcomb3
	pause_msg

*	Example 2.2 from -grc1leg2.sthlp-
grc1leg2_examples grcomb5
	pause_msg

*	Example 2.3 from -grc1leg2.sthlp-
grc1leg2_examples grcomb8
	pause_msg

*	Examples with -gr combine- using only two panels
*	(Examples 2.4, 2.5 and 2.6 are omitted from the help file for -grc1leg2-)
	
*	Example 2.4
*	(omitted from the help file for -grc1leg2-)	

gr combine panel1 panel2,  ///
	xcommon ycommon     ///
	title("Ex. 2.4: Two panels: -gr combine-, default")  ///
	name(grcomb2, replace) 
	pause_msg
	
*	To add a single legend to a combined graph made with -gr combine-,
*	one can choose among alternative versions of panel 2 with legends offset  
*	to appear where desired in the combined graph.
*	This approach requires fine tuning the offset values 
*	to get the most visually placement in the combined graph.

*	Example 2.5
*	(omitted from the help file for -grc1leg2-)	

*	This version of the second panel places the common legend below the combined graph
twoway  ///
	(scatter mpg weight if qual==2)  ///
	(lfit mpg weight if qual==2),  ///
		subtitle("Medium")  ///
		legend(ring(0) pos(0) xoffset(-35) yoffset(-40))  ///
		name(panel2_yoff, replace)

*	With the -imargin()- option creating space at the bottom of the combined graph,
*	a common legend can be attached to the two combined panels like this.
gr combine panel1 panel2_yoff,  ///
	xcommon ycommon imargin(5 5 15 5)     ///
	title("Ex. 2.5: Two panels: -gr combine-, legend below")  ///
	subtitle("Use -gr combine ..., imargin(5 5 15 5)- having specified"   ///
		"-ring(0) pos(0) xoffset(-35) yoffset(-40)- on the right-most graph") ///
	name(grcomb2_below, replace) 
	pause_msg

*	In Example 1.4 above, -gr ..., by()- inserts a common legend
*	between two panels by deploying the option -holes()-.
*	But the -holes()- option appears to have no effect on -gr combine- 
*	when it combines only two graphs.

*	Example 2.6
*	(omitted from the help file for -grc1leg2-)	

*	So in order to embed a single legend within the array of panels 
*	created by -gr combine-, one can instead overlay the legend as follows:

twoway  ///  This version overlays the common legend onto the combined graph
	(scatter mpg weight if qual==2)  ///
	(lfit mpg weight if qual==2),  ///
		subtitle("Medium")  ///
		legend(ring(0) pos(5) col(1) xoffset(-45) yoffset(5))  ///
		name(panel2_xoff, replace)

gr combine panel1 panel2_xoff,  ///
	xcommon ycommon     ///
	title("Ex. 2.6: Two panels: -gr combine-, legend overlaid")  ///
	subtitle("Fine tune legend placement in component graph -panel2_xoff-") ///
	name(grcomb2_onto, replace) 
	pause_msg


*    3.  Examples of a two-step procedure using grc1leg2
*        ===============================================

*	Example 3.0 from -grc1leg2.sthlp-

grc1leg2_examples grc4dflt
	pause_msg

*	Example 3.1 from -grc1leg2.sthlp-
grc1leg2_examples grc3woxtob1
	pause_msg

*	Example 3.2 from -grc1leg2.sthlp-
grc1leg2_examples grc3_offset
	pause_msg

*	Example 3.3 from -grc1leg2.sthlp-
grc1leg2_examples grc3
	pause_msg

*	Example 3.3_bis from -grc1leg2.sthlp-
*	Move a main -title- and/or a -note- from a component graph to the combined graph. 
grc1leg2_examples grc3_bis
	pause_msg

*	Example 3.4a from -grc1leg2.sthlp-
grc1leg2_examples grc3legscale
	pause_msg

*	Example 3.4b from -grc1leg2.sthlp-
grc1leg2_examples grc3labsize
	pause_msg

*	Example 3.5 from -grc1leg2.sthlp-
grc1leg2_examples grc8pnl
	pause_msg

*	Example 3.6 from -grc1leg2.sthlp-
grc1leg2_examples grc4pnl
	pause_msg

*	Example 3.7 from -grc1leg2.sthlp-
grc1leg2_examples grcfromby
	pause_msg

*	Example 3.8 from -grc1leg2.sthlp-
grc1leg2_examples grcfromcomb
	pause_msg

*	Example 3.9 from -grc1leg2.sthlp-
grc1leg2_examples grcy2tor1
	pause_msg

*	Example 3.10 from -grc1leg2.sthlp-
*		Ex. 3.10a: Combining twoway graphs with different markers 
grc1leg2_examples grchide
	pause_msg

*		Ex. 3.10b: Combining a graph with markers with a graph with color swatches
grc1leg2_examples grchide2
	pause_msg

*		Ex. 3.10c: Add arrows from the exploded slice to the bar
grc1leg2_examples bar_of_pie
	pause_msg

*		Ex. 3.10c: Creating an Excel-style bar_of_pie graph
grc1leg2_examples play_grec_on_Ex_3_10c
	pause_msg

*	Example 3.11 from -grc1leg2.sthlp-
grc1leg2_examples grc3_dispopts
	pause_msg

*	Example 3.12 from -grc1leg2.sthlp-
grc1leg2_examples grclcols
	pause_msg

*	Example 3.13 from -grc1leg2.sthlp-
grc1leg2_examples grclcolsasis
	pause_msg

*	Example 3.14
*	(omitted from the help file for -grc1leg2-)	

*	Examples with -grc1leg2- using only two panels
*		-grc1leg2-'s default resembles Example 2.5	
grc1leg2 panel1 panel2,  ///
	xcommon ycommon    /// 
	title("Ex. 3.14: Two panels: -grc1leg2-, legend below")  ///
	subtitle("Use -grc1leg2- with default legend options ")  ///
	name(grc2_below, replace)

	pause_msg
	
*	Example 3.15
*	(omitted from the help file for -grc1leg2-)	

*		With options ring(0) and pos(0), -grc1legs-'s 
*		graph resembles Example 2.6
grc1leg2 panel1 panel2,  ///
	xcommon ycommon ring(0) pos(0)    ///
	title("Ex. 3.15: Two panels: -grc1leg2-, legend overlaid")  ///
	subtitle("Use -grc1leg2- with options:"  ///
		"ring(0) pos(0) xtob1title ytol1title") /// 
	xtob1title ytol1title ///
	name(grc2_onto, replace)
	
*	-grc1leg2- inherits -gr combine-'s blindness to the -holes()- options 
*	when there are only two graphs being combined.	

	pause_msg
	
*	Executing the utility -displaygph- displays all or a subset 
*	of the memory graphs created in this DO file for easy review.
*	Execution time increases with the number of graphs to be displayed.

*	-displaygph- can be installed from CGD's Stata repository 
*  by typing "search displaygph" or clicking here:
di `"{stata `"view net describe displaygph, from("http://digital.cgdev.org/doc/stata/MO/Misc")"'}"'


*	If -displaygph- is already installed, click here 
*	to display the named memory graphs created by -grc1leg2-:
di "{stata displaygph grc1* , mem}"

*	Experiment with various legend(order()) options to see if -order()- can break -grc1le2-
*		Start with Example 3.10a, but keep only the ci
set graph off

twoway  ///  This is the component graph from which we take the legend
	(scatter mpg weight, mcolor(blue))  ///
	(scatter length weight, mcolor(red))  ///
	(scatter price weight, mcolor(green))  ///
	(lfitci  price weight, lcolor(green)),  ///
		legend(order(4))  ///
		name(dummy_onlyci, replace)
	
set graph on

grc1leg2 panel7 panel8 panel9 dummy_onlyci,  ///
	title("Can -order()- break -grc1leg2-, ver. 2.25?")   ///
	subtitle("dummy_onlyci keeps only the symbol for the CI (key #4)")  ///
	xtob1title legendfrom(dummy_onlyci) hidelegendfrom  ///
	pos(4) ring(0) lyoffset(15)  ///
	name(ex_onlyci, replace)

*		Add lines of text inside -order()-
set graph off

twoway  ///  This is the component graph from which we take the legend
	(scatter mpg weight, mcolor(blue))  ///
	(scatter length weight, mcolor(red))  ///
	(scatter price weight, mcolor(green))  ///
	(lfitci  price weight, lcolor(green)),  ///
		legend(colfirst cols(2) order(1 2 - "Text line #1" - "Text line #2" 3 5 4 6) )  ///
		name(dummy_addtext, replace)
	
set graph on

grc1leg2 panel7 panel8 panel9 dummy_addtext,  ///
	title("Can -order()- break -grc1leg2-, ver. 2.25?")   ///
	subtitle("dummy_addtext adds text lines inside -order()-")  ///
	xtob1title legendfrom(dummy_addtext) hidelegendfrom  ///
	pos(4) ring(0) lyoffset(15)  ///
	name(ex_addtext, replace)

*	If -displaygph- is already installed, click here 
*	to display the named memory graphs created by -grc1leg2-:
di "{stata displaygph ex_* , mem}"

log close
view grc1test.smcl

