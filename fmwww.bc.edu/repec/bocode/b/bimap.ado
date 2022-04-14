*! Bimap v1.0 Naqvi 8.Apr.2022


**********************************
* Step-by-step guide on Medium   *
**********************************

// if you want to go for even more customization, you can read this guide:

* Stata graphs: Bi-variate maps (07 Dec, 2021)
* https://medium.com/the-stata-guide/stata-graphs-bi-variate-maps-b1e96dd4c2be


cap program drop bimap


program bimap, sortpreserve

version 15
 
	syntax varlist(min=2 max=2 numeric) [if] [in] using/ , ///
		cut(string) palette(string) ///
		[ BOXsize(real 8) textx(string) texty(string) xscale(real 30) yscale(real 100) TEXTLABSize(real 2) TEXTSize(real 2.5) values ] ///
		[ polygon(string) ] ///
		[ ocolor(string) osize(string) ]   ///
		[ ndocolor(string) ndsize(string) ndocolor(string) ]   ///
		[ title(string) subtitle(string) note(string)  ] ///
		[ allopt graphopts(string asis) * ] 
		
		
		capture confirm file "`using'.dta"   
		if _rc {
			di as err "{p}File {bf:`using'} not found{p_end}"
			exit 601
		}
	
	
	// check dependencies
		capture findfile spmap.ado
		if _rc != 0 {
			display as error "spmap package is missing. Install the {stata ssc install spmap, replace:spmap}."
			exit
		}

		capture findfile colorpalette.ado
		if _rc != 0 {
			display as error "colorpalette package is missing. Install the {stata ssc install colorpalette, replace:colorpalette} and {stata ssc install colrspace, replace:colrspace} packages."
			exit
		}	
	
		marksample touse, strok
		gettoken var2 var1 : varlist 
	
		***** Get the cuts

	
qui {
		
	preserve	
		tempvar cat_`var1' cat_`var2'
		
		if "`cut'" == "pctile" {
			xtile `cat_`var1'' = `var1' if `touse', n(3)
			xtile `cat_`var2'' = `var2' if `touse', n(3)
		}
		
		if "`cut'" == "equal" {
			egen `cat_`var1'' = cut(`var1') if `touse', at(0,33,66,100) icodes
			egen `cat_`var2'' = cut(`var2') if `touse', at(0,33,66,100) icodes
			
			
			replace `cat_`var1'' = `cat_`var1'' + 1 
			replace `cat_`var2'' = `cat_`var2'' + 1
		}	
	
		sort `cat_`var1'' `cat_`var2''
		
		tempvar grp_cut
		egen `grp_cut' = group(`cat_`var1'' `cat_`var2'')
	
	
	
		***** store the cut-offs for labels	
		
		summ `var1' if `cat_`var1'' == 1
		local var11 = r(max)
		local var11 : di %05.1f `var11'
		
		summ `var1' if `cat_`var1'' == 2
		local var12 = r(max)
		local var12 : di %05.1f `var12'
		
		summ `var1' if `cat_`var1'' == 3
		local var13 = r(max)
		local var13 : di %05.1f `var13'
		
		summ `var2' if `cat_`var2'' == 1
		local var21 = r(max)
		local var21 : di %05.1f `var21'
		
		summ `var2' if `cat_`var2'' == 2
		local var22 = r(max)
		local var22 : di %05.1f `var22'
		
		summ `var2' if `cat_`var2'' == 3
		local var23 = r(max)
		local var23 : di %05.1f `var23'
	
		***** define the colors (https://www.joshuastevens.net/cartography/make-a-bivariate-choropleth-map/)
	
		// from spmap
   
		if "`palette'" != "" {
			local LIST "pinkgreen bluered greenblue purpleyellow"
			local LEN = length("`palette'")
			local check = 0
			foreach z of local LIST { 
				if ("`palette'" == substr("`z'", 1, `LEN')) {
					local check = 1
				}
			}
			
			if !`check' {
				di in yellow "Wrong palette specified. The supported palettes are {ul:pinkgreen}, {ul:bluered}, {ul:greenblue}, {ul:purpleyellow}."
				exit 198
			}
	

		if "`palette'" == "pinkgreen" {
			local color #e8e8e8 #dfb0d6 #be64ac #ace4e4 #a5add3 #8c62aa #5ac8c8 #5698b9 #3b4994
		}
		
		if "`palette'" == "bluered" {
			local color #e8e8e8 #b0d5df #64acbe #e4acac #ad9ea5 #627f8c #c85a5a #985356 #574249 
		}
		
		if "`palette'" == "greenblue" {
			local color #e8e8e8 #b8d6be #73ae80 #b5c0da #90b2b3 #5a9178 #6c83b5 #567994 #2a5a5b
		}	

		if "`palette'" == "purpleyellow" {
			local color #e8e8e8 #cbb8d7 #9972af #e4d9ac #c8ada0 #976b82 #c8b35a #af8e53 #804d36
		}		
	
		if "`polygon'" == "" {
			local polyadd 
		}
		else {
			local polyadd `polygon'
		}

	
		local lc = cond("`ocolor'" == "", "white", "`ocolor'")
		
		local lw = cond("`osize'" == "", "0.02", "`osize'")
	
	
	
		// finally the map!
		
		colorpalette `color', nograph 
		local colors `r(p)'

		spmap `grp_cut' using "`using'", ///
			id(_ID) clm(unique)  fcolor("`colors'") ///
			ocolor(`lc' ..) osize(`lw' ..) ///	
			ndocolor(gs6 ..) ndsize(`lw' ..) ndfcolor(gs14)  ///
			polygon(`polyadd') ///
			legend(off)  ///
			name(_map, replace) nodraw
	

	
		**** add the legend
		
		clear
		set obs 9
		
		egen y = seq(), b(3)  
		egen x = seq(), t(3) 	
		
		cap drop spike*
	
	
		if "`textx'" == "" {
			local labx = "`var1'"
		}
		else {
			local labx = "`textx'"
		}
		
		if "`texty'" == "" {
			local laby = "`var2'"
		}
		else {
			local laby = "`texty'"
		}
	
	
		// arrows
		gen spike1_x1  = 0.35 in 1
		gen spike1_x2  = 3.6 in 1 
		gen spike1_y1  = 0.35 in 1	
		gen spike1_y2  = 0.35 in 1	
		gen spike1_m   = "`labx'" in 1
			
		gen spike2_y1  = 0.35 in 1
		gen spike2_y2  = 3.6 in 1 
		gen spike2_x1  = 0.35 in 1		
		gen spike2_x2  = 0.35 in 1		
		gen spike2_m   = "`laby'" in 1
		
		// ticks
		gen xvalx = .
		gen xvaly = .
		gen xvaln = .
	
		replace xvaly = 0.36 in 1/3
		replace xvalx = 0.8 in 1
		replace xvalx = 1.8 in 2
		replace xvalx = 2.8 in 3
		
		replace xvaln = `var11' in 1
		replace xvaln = `var12' in 2
		replace xvaln = `var13' in 3
		

		gen yvalx = .
		gen yvaly = .
		gen yvaln = .

		replace yvalx = 0.33 in 1/3
		replace yvaly = 1.1 in 1
		replace yvaly = 2.1 in 2
		replace yvaly = 3.1 in 3	
		
		replace yvaln = `var21' in 1
		replace yvaln = `var22' in 2
		replace yvaln = `var23' in 3
		
	
		// axis labels
		
		gen labx = .
		gen laby = .
		gen labn = ""
		
		replace labx = 2 in 1
		replace laby = 0 in 1
		replace labn = "`labx'" in 1
		
		replace labx = 0 in 2
		replace laby = 3 in 2
		replace labn = "`laby'" in 2
	
	
		// colors
		
		colorpalette `color', nograph 

			local color11 `r(p1)'
			local color12 `r(p2)'
			local color13 `r(p3)'

			local color21 `r(p4)'
			local color22 `r(p5)'
			local color23 `r(p6)'

			local color31 `r(p7)'
			local color32 `r(p8)'
			local color33 `r(p9)'	
					
			levelsof x, local(xlvl)	
			levelsof y, local(ylvl)


		local boxes

		foreach x of local xlvl {
			foreach y of local ylvl {
				local boxes `boxes' (scatter y x if x==`x' & y==`y', msymbol(square) msize(`boxsize') mc("`color`x'`y''")) ///
			
			}
		}
	
	
		if "`values'" != "" {
			
			local xvals (scatter xvaly xvalx, mcolor(none) mlab(xvaln) mlabpos(4) mlabsize(`textlabsize'))
			
			local yvals (scatter yvaly yvalx, mcolor(none) mlab(yvaln) mlabpos(11) mlabsize(`textlabsize') mlabangle(90))
		
		}
	
  
		twoway ///
			`boxes' ///
			(pcarrow spike1_y1 spike1_x1 spike1_y2 spike1_x2, lcolor(gs6) mcolor(gs6) msize(0.8) ) ///
			(pcarrow spike2_y1 spike2_x1 spike2_y2 spike2_x2, lcolor(gs6) mcolor(gs6) msize(0.8) ) ///
			(scatter laby labx in 1, mcolor(none) mlab(labn) mlabsize(`textsize') mlabpos(6))  ///
			(scatter laby labx in 2, mcolor(none) mlab(labn) mlabsize(`textsize') mlabpos(9) mlabgap(3.5) mlabangle(90))  ///
			`xvals' ///
			`yvals' ///
			, ///
				xlabel(, nogrid) ylabel(, nogrid) ///
				yscale(range(0 4)) xscale(range(0 4)) ///
				xscale(off) yscale(off) ///
				aspectratio(1) ///
				xsize(1) ysize(1) ///
				fxsize(`xscale') fysize(`yscale') ///
				legend(off)		///
					ytitle("`laby'") 	xtitle("`labx'") ///
					name(_legend, replace)  nodraw   

			
		restore			
	
	 **** combine the two	
	 
	  graph combine _map _legend, ///
		imargin(zero) ///
		title(`title') ///
		subtitle(`subtitle') ///
		note(`note')
	
	}	 
}

end



*********************************
******** END OF PROGRAM *********
*********************************
