*! ternary v1.0 (28 Aug 2024)
*! Asjad Naqvi (asjadnaqvi@gmail.com)

* v1.0 (28 Aug 2024) : Beta release


program ternary, sortpreserve  
	
	version 15 
	
	syntax varlist(min=3 max=3 numeric) [if] [in]  ///
		[ , cuts(real 5) showlabel LColor(string) LWidth(string) format(str)   ] ///
		[ msize(string) malpha(real 90) MLColor(string) MLWIDth(string) MColor(string) MSYMbol(string) TICKSize(string) LABColor(string) ]	///
		[ colorR(string) colorL(string) colorB(string)  ] ///
		[ fill points lines labels 	 ]	///
		[ zoom  * ]
	
	 
	marksample touse, strok
	
		
	if "`colorB'" == "" local colorB #DCB600
	if "`colorR'" == "" local colorR #FF6CFF
	if "`colorL'" == "" local colorL #00E0DF	
	
	
	if "`points'" != "" | "`fill'" != "" {
		qui {	
			preserve
				clear
				tempfile _triangles
				qui _ternary_triangles, cuts(`cuts') colorB(`colorB') colorR(`colorR') colorL(`colorL')
				save `_triangles'			
			restore		
		}
	}	
	
	if "`points'" != ""  {
		qui {	
			preserve
				clear
				tempfile _points
				use `_triangles'
				keep if _tag==1
				keep _id color
				ren _id tri_id
				save `_points'			
			restore		
		}
	}


	
quietly {	
	preserve
	
	keep if `touse'
	keep `varlist'

	foreach x of local varlist {
		if "`: var label `x''" != "" {
			lab var `x' "`: var label `x''"
		}
		else {
			lab var `x' `x'
		}
	}
	
	
	tokenize `varlist'
	
	
	ren `1' _R
	ren `2' _L
	ren `3' _B
	
	
	// run checks
	
	egen _check = rowtotal(_R _L _B)
	
	summ _check, meanonly
	
	if round(`r(max)') == 1 {
		noisily display in yellow "Normalization of 1 assumed."
		local normlvl = 1
	}
	else if round(`r(max)') == 100 {
		noisily display in yellow "Normalization of 100 assumed."
		local normlvl = 100
	}
	else {
		noisily display in red "Variables do not add up to 1 or 100."
		exit
	}
	
	if "`format'"  == "" {
		if `normlvl' == 1 	local format  %5.2f 
		if `normlvl' == 100 local format  %6.0f 
	} 	
	
	replace _L = _L / `normlvl'
	replace _R = _R / `normlvl'
	replace _B = _B / `normlvl'
	
	
	
	if "`zoom'" != "" {
		// determine the variable with the highest min
		local mymin = 0
		
		local i = 1
		foreach x in _R _L _B {
			summ `x', meanonly
			if `mymin' < `r(min)' {
				local mymin = (floor(`r(min)' * `cuts') / `cuts')
				local myvar `x'
			}
			
			local ++i
		}
		
		// normalize
		
		replace `myvar' = (`myvar' - `mymin') / (1 - `mymin')
		
		local others "_R _L _B" 
		local remove "`myvar'"
		
		local others : list others - remove
		
		foreach x of local others {
			replace `x' = `x' / (1 - `mymin')
		}
	}	


	// barycentric coordinates	
	gen double _yvar = _R * sqrt(3) / 2 
	gen double _xvar = 1 - (_R/2 + _L) 


	// add rows if required
	if _N < `=`cuts' + 5' set obs `=`cuts' + 5'
	
	local diff = 1 / `cuts'
	
	*** bottom
	gen double yB = .
	gen double xB = .
	gen _Blab = ""
	

	forval i = 1/`=`cuts' + 1' {
		
		local myval = (`i' - 1) / `cuts'
		
		replace xB = `myval'  	in `i'
		replace yB = 0 			in `i'
		
		local myval = (`i' - 1) / `cuts'
		
		if "`zoom'" != "" {
			if `myvar' == _B {
				replace _Blab = string( ((1 - `mymin')*`myval' + `mymin') * `normlvl' , "`format'") in `i'
			}
			else {
				replace _Blab = string( (`myval' * (1 - `mymin'))* `normlvl', "`format'") in `i'
			}
		}
		else {
			replace _Blab = string(`myval' * `normlvl', "`format'") in `i'
		}
	}
	
	*** right
	gen double yR = .
	gen double xR = .
	
	gen double yR_spike = .
	gen double xR_spike = .
	
	gen _Rlab = ""

	forval i = 1/`=`cuts' + 1' {
	
		local myval = (`i' - 1) / `cuts'
		
		replace yR = `myval' * sqrt(3) / 2 			in `i'
		replace xR = 1 - (yR / tan(60 * _pi / 180)) in `i'
		
		
		if "`zoom'" != "" {
			if `myvar' == _R {
				replace _Rlab = string( ((1 - `mymin')*`myval' + `mymin') * `normlvl' , "`format'") in `i'
			}
			else {
				replace _Rlab = string( (`myval' * (1 - `mymin') ) * `normlvl', "`format'") in `i'
			}
		}
		else {
			replace _Rlab = string(`myval' * `normlvl', "`format'") in `i'
		}
		
		replace yR_spike = (1 - `myval') * sqrt(3) / 2 			in `i'
		replace xR_spike = 1 - yR_spike / tan(60 * _pi / 180) 	in `i'		
		
	}
   
   
   *** left
	gen double yL = .
	gen double xL = .
	gen _Llab = ""
	

	forval i = 1/`=`cuts' + 1' {
		
		local myval = (`i' - 1) / `cuts'
		
		
		
		replace yL = `myval' * sqrt(3) / 2 			in `i'
		replace xL = yL / tan(60 * _pi / 180) 		in `i'
		
		
		if "`zoom'" != "" {
			if `myvar' == _L {
				replace _Llab = string( ((1 - `mymin')*(1 - `myval') + `mymin') * `normlvl' , "`format'") in `i'
			}
			else {
				replace _Llab = string( ((1 - `myval')*(1 - `mymin')) * `normlvl' , "`format'") in `i'
			}
		}
		else {
			replace _Llab = string( (1 - `myval') * `normlvl' , "`format'") in `i'
		}		
	}
	
	
	// generate the title labels
	gen tx = .
	gen ty = .
	gen tl = ""

	replace tx =  0.5 in 1
	replace ty = -0.1  in 1
	replace tl = "`: variable label _B'" in 1

	
	replace tx = 0.85 in 2
	replace ty = 0.5 in 2
	replace tl = "`: variable label _R'" in 2	
	

	replace tx =  0.15 in 3
	replace ty =  0.5 in 3
	replace tl = "`: variable label _L'" in 3
	
	
	gen mval = ""
	
	if "`showlabel'" != "" gen mval = string(_B, "`format'") + ", " + string(_L, "`format'")  + ", " + string_R, "`format'") 	
	
	**** return color triangles
	

	if "`msymbol'" == "" 	local msymbol circle
	if "`msize'"   == "" 	local msize   1.5
	if "`mcolor'"  == "" 	local mcolor  white
	if "`mlcolor'" == "" 	local mlcolor black
	if "`mlwidth'" == "" 	local mlwidth 0.1
	if "`lwidth'"  == "" 	local lwidth  0.15
	
	if "`lcolor'"  == "" {
		if "`fill'" != "" {
			local lcolor  white
		}
		else {
			local lcolor  gs8
		}
	}
	
	
	if "`ticksize'"  == "" 	local ticksize   1
	if "`labcolor'" == "" 	local labcolor  black
	
	// point colors
	
	
	if "`points'"!="" {
		
		gen _seq = _n
		
		gen double _ytr = _yvar * 2 / sqrt(3) 
		gen double _xtr = _xvar - (_ytr / 2)

		gen tri_id = .
		
		replace _ytr = _ytr * `cuts'
		replace _xtr = _xtr * `cuts'
		
		
		*** up triangles
		local counter = 1

		forval i = 1/`cuts' {
			
			local y1 = `cuts' - `i' 
			local y2 = `cuts' - `i' + 1
			local j = 1
			
			while `j' <= `i'  {
				local x1 = `j' - 1
				local x2 = `j'
				
				if `i' == 1 {
					local id = 1
				} 
				else {
					local id = 2 * `counter' - `i'
				}
				
				gen double A1 = abs((_xtr*(`y1' - `y2') + `x2'*(`y2' - _ytr) + `x1'*(_ytr - `y1')) ) if missing(tri_id)
				gen double A2 = abs((`x1'*(_ytr - `y2') + _xtr*(`y2' - `y1') + `x1'*(`y1' - _ytr)) ) if missing(tri_id)
				gen double A3 = abs((`x1'*(`y1' - _ytr) + `x2'*(_ytr - `y1') + _xtr*(`y1' - `y1')) ) if missing(tri_id)
				
				gen double temp_`id' = round((A1+A2+A3) * 10) / 10
				
				replace tri_id = `id' if missing(tri_id) & temp_`id'==1
				
				cap drop A1 A2 A3 temp_`id'		
				
				local ++j
				local ++counter
			}
		}	


		*** down triangles
		local counter = 1

		forval i = 1/`=`cuts'-1' {

			local y1 = `cuts' - `i' 
			local y2 = `cuts' - `i' - 1
			
			local j = 1
			
			while `j' <= `i'  {
				local x1 = `j' - 1
				local x2 = `j'
				
				if `i' == 1 {
					local id = 3
				} 
				else {
					local id = 2 * `counter' + `i'
				}		

				gen double A1 = abs((_xtr*(`y1' - `y2') + `x2'*(`y2' - _ytr) + `x2'*(_ytr - `y1')) ) if missing(tri_id)
				gen double A2 = abs((`x1'*(_ytr - `y2') + _xtr*(`y2' - `y1') + `x2'*(`y1' - _ytr)) ) if missing(tri_id)
				gen double A3 = abs((`x1'*(`y1' - _ytr) + `x2'*(_ytr - `y1') + _xtr*(`y1' - `y1')) ) if missing(tri_id)
				
				gen double temp_`id' = round((A1+A2+A3) * 10) / 10
				
				replace tri_id = `id' if missing(tri_id) & temp_`id'==1
				
				cap drop A1 A2 A3 temp_`id'					

				local ++j
				local ++counter
			}
		}			
		
		
		merge m:1 tri_id using `_points'
		
		sort _seq	
		drop if _m==2
		drop _merge _seq
		drop _ytr _xtr
		
		
		gen _i2 = _n
		
		levelsof tri_id, local(clrlvls)
		
		foreach x of local clrlvls {
		
			summ _i2 if tri_id==`x', meanonly
			local myclr = color[`r(min)'] 
			
			colorpalette `myclr', nograph
			
			local mypoints `mypoints' (scatter _yvar _xvar if tri_id==`x', msize(`msize') mc("`r(p1)'%`malpha'") mlc(`mlcolor') mlwidth(`mlwidth') mlab(mval)) 
				
		}
	}
	else {
			local mypoints (scatter _yvar _xvar, msymbol(`msymbol') msize(`msize') mc(`mcolor') mlc(`mlcolor') mlwidth(`mlwidth')  mlab(mval)) 
	}
	
	
	**** generate the triangles ****
    

	
	if "`fill'"!="" {

	
		append using `_triangles'
		gen _i = _n
		
		**** plot the triangles
		
		levelsof _id, local(lvls)

		foreach x of local lvls {

			summ _i if _id==`x' & _tag==1, meanonly
			local myclr = color[`r(mean)'] 
			
			colorpalette `myclr', nograph
			
			local triangles `triangles' (area y2 x2 if _id==`x', lc(white) lw(0.02) fi(100) cmiss(n) fc("`r(p1)'")) 
		
		}

	}	
	
	
	
	*********************
	**** Final graph ****
	*********************
	
	if "`labels'" != "" {
		colorpalette `colorR' `colorL' `colorB' , nograph
		local labclr1 `r(p1)'
		local labclr2 `r(p2)'
		local labclr3 `r(p3)'
	}
	else {
		local labclr1 `labcolor'
		local labclr2 `labcolor'
		local labclr3 `labcolor'
	}
	
	if "`lines'" != "" {
		colorpalette `colorR' `colorL' `colorB', nograph
	}
	else {
		colorpalette `lcolor' `lcolor' `lcolor', nograph
	}
	
	twoway ///
		`triangles'	///
		(pcspike yR xR yL xL if xL!=0   , lc("`r(p1)'")	lw(`lwidth'))	///
		(pcspike yB xB yL xL if xB!=1	, lc("`r(p2)'")	lw(`lwidth'))	///
		(pcspike yR_spike xR_spike yB xB if yR!=0, lc("`r(p3)'")	lw(`lwidth'))	///
		(connected yR xR, mlab(_Rlab) mlabpos(3)  mc("`labclr1'") mlabc("`labclr1'") lc("`r(p1)'") lw(`lwidth') msize(`ticksize') msymbol(|) msymangle( 90))	///
		(connected yL xL, mlab(_Llab) mlabpos(11) mc("`labclr2'") mlabc("`labclr2'") lc("`r(p2)'") lw(`lwidth') msize(`ticksize') msymbol(|) msymangle( 30))	///
		(connected yB xB, mlab(_Blab) mlabpos(7)  mc("`labclr3'") mlabc("`labclr3'") lc("`r(p3)'") lw(`lwidth') msize(`ticksize') msymbol(|) msymangle(-30))	///
		(scatter ty tx in 1, mlab(tl) mlabpos(0) mc(none) mlabsize(3) mlabcolor("`labclr3'")				  ) ///	
		(scatter ty tx in 2, mlab(tl) mlabpos(0) mc(none) mlabsize(3) mlabcolor("`labclr1'") mlabangle(-60) ) ///	
		(scatter ty tx in 3, mlab(tl) mlabpos(0) mc(none) mlabsize(3) mlabcolor("`labclr2'") mlabangle( 60) ) ///	
		`mypoints' ///
			, ///
			legend(off) aspect(1) xsize(1) ysize(1) ///
			xlabel(, nogrid) ylabel(, nogrid) xscale(off) yscale(off)	///
			`options'
	
		
		*/
		
	restore
}
		
end

**************************
**** return triangles ****
**************************

cap program drop _ternary_triangles
program _ternary_triangles
version 15	

	syntax , cuts(numlist max=1) colorB(string) colorR(string) colorL(string)

	set obs `=(`cuts'^2) * 5'

	gen _id = .		
	gen double _x  = .
	gen double _y  = .	
	gen _control = .

	gen B_seg = .
	gen R_seg = .
	gen L_seg = .
	gen _tag = .
	

	local counter = 1

	forval i = 1/`cuts' {
		
		local y1 = `cuts' - `i' 
		local y2 = `cuts' - `i' + 1
		local j = 1
		
		while `j' <= `i'  {
			local x1 = `j' - 1
			local x2 = `j'
			
			if `i' == 1 {
				local id = 1
			} 
			else {
				local id = 2 * `counter' - `i'
			}
			
			local start = (`id'-1)*5 + 1
			
			replace _x = `x1' in `start'
			replace _y = `y1' in `start'
			
			replace _x = `x2' in `=`start'+1'
			replace _y = `y1' in `=`start'+1'
			
			replace _x = `x1' in `=`start'+2'
			replace _y = `y2' in `=`start'+2'

			replace _x = `x1' in `=`start'+3'
			replace _y = `y1' in `=`start'+3'
			

			// controls
			replace _id 	 = `id' in `start'/`=`start'+4'
			replace _control = 0 	in `start'/`=`start'+4'
			
			// segments
			replace B_seg = `x2'  	in `start'
			replace R_seg = `y2'	in `start'	
			
			replace L_seg = `cuts' - ( `x2' + `y2' - 2) in `start'
			replace _tag = 1 in `start'
			
			local ++j
			local ++counter
		}
	}	


	local counter = 1

	forval i = 1/`=`cuts'-1' {

		local y1 = `cuts' - `i' 
		local y2 = `cuts' - `i' - 1
		
		local j = 1
		
		while `j' <= `i'  {
			local x1 = `j' - 1
			local x2 = `j'
			
			if `i' == 1 {
				local id = 3
			} 
			else {
				local id = 2 * `counter' + `i'
			}		
			
			local start = (`id'-1)*5 + 1
			
			replace _x = `x1' in `start'
			replace _y = `y1' in `start'
			
			replace _x = `x2' in `=`start'+1'
			replace _y = `y1' in `=`start'+1'
			
			replace _x = `x2' in `=`start'+2'
			replace _y = `y2' in `=`start'+2'

			replace _x = `x1' in `=`start'+3'
			replace _y = `y1' in `=`start'+3'
			
			replace B_seg = `x2'	in `start'
			replace R_seg = `y1'	in `start'
			replace L_seg = `cuts' - ( `x2' + `y1' - 1) in `start'
			
			replace _tag     = 1    in `start'
			replace _id      = `id' in `start'/`=`start'+4'
			replace _control = 1    in `start'/`=`start'+4'		
			
			local ++j
			local ++counter
		}
	}	
		
	drop if _id==.	


	**** normalize

	replace _x = _x / `cuts'
	replace _y = _y / `cuts'	

		
	**** transform
		
	gen double x2 = _x + (_y/2)
	gen double y2 = _y * sqrt(3)/2	
		
	drop _x _y
		
		
	**** generate centroids

	bysort _id: gen seq = _n

	bysort _id: egen double x2c = mean(x2) if inrange(seq, 1, 3)	
	bysort _id: egen double y2c = mean(y2) if inrange(seq, 1, 3)		

		
	*** generate ratios of color strength

	cap drop *_share

	gen double B_share = .	
	gen double L_share = .
	gen double R_share = .	
		
		
	foreach x in B L R {
		replace `x'_share = (`x'_seg - 1) / (`cuts' - 1) if _control==0
		replace `x'_share = ((2 *(`x'_seg - 1) + `x'_seg) / 3) / (`cuts' - 1)   if _control==1
	}	
		

	***** let's start adding colors

	cap drop color
	gen str15 color = ""


	levelsof _id, local(lvls)

	foreach x of local lvls {
		summ B_share if _id==`x' & _tag==1, meanonly
		colorpalette `colorB', intensify(`r(mean)') nograph
		tokenize `r(p1)'
		args b1 b2 b3
		
		summ L_share if _id==`x' & _tag==1, meanonly
		colorpalette `colorL', intensify(`r(mean)') nograph
		tokenize `r(p1)'
		args l1 l2 l3	
		
		summ R_share if _id==`x' & _tag==1, meanonly
		colorpalette `colorR', intensify(`r(mean)') nograph
		tokenize `r(p1)'
		args r1 r2 r3		
		
		local c1 = floor((`b1' * `r1' * `l1') / (255 * 255))
		local c2 = floor((`b2' * `r2' * `l2') / (255 * 255))
		local c3 = floor((`b3' * `r3' * `l3') / (255 * 255))

		replace color = char(34) + "`c1' `c2' `c3'" + char(34) if _id==`x' & _tag==1
		
	}	
	

end  
	





**** END ****



