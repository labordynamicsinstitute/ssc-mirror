*! version 1.0.1  15aug2015 Robert Picard, picard@netbox.com
program define geo2xy_examples

	version 9.2
	
	set more off
	
	`0'
	
end

program define Echo

	di as txt
	
	di as res _asis `". `0'"'
	
	`0'

end


program define ex1

	preserve
	
	Echo use "geo2xy_us_data.dta", clear

	Echo spmap if _ID == 44 using "geo2xy_us_coor.dta", id(_ID)

end

program define ex2

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo geo2xy _Y _X, replace
	
	Echo save "geo2xy_us_coor_google.dta", replace
	
	Echo use "geo2xy_us_data.dta", clear

	Echo spmap if _ID == 44 using "geo2xy_us_coor_google.dta", id(_ID)
	
end

program define ex3

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo geo2xy _Y _X if _ID == 44, gen(ylat xlon)
	
	Echo return list
	
	Echo line ylat xlon, lwidth(vthin) lcolor(gray) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off)

end


program define ex4

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo drop if inlist(_ID, 55,54,32,28,29,37,40) // Alaska, Hawaii, territories

	Echo geo2xy _Y _X , gen(ylat xlon) tissot
	
	Echo return list
	
	Echo line ylat xlon if !mi(_ID), lwidth(vthin) lcolor(gray) cmissing(n) || ///
			line ylat xlon if mi(_ID), lwidth(vthin) lcolor(eltblue) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off)

end


program define ex5

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo drop if inlist(_ID, 55,54,32,28,29,37,40) // Alaska, Hawaii, territories

	Echo geo2xy _Y _X , gen(ylat xlon) proj(albers)
	
	Echo return list
	
	Echo line ylat xlon, lwidth(vthin) lcolor(gray) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off)

end


program define ex5t

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo drop if inlist(_ID, 55,54,32,28,29,37,40) // Alaska, Hawaii, territories

	Echo geo2xy _Y _X , gen(ylat xlon)  proj(albers) tissot
	
	Echo return list
	
	Echo line ylat xlon if !mi(_ID), lwidth(vthin) lcolor(gray) cmissing(n) || ///
			line ylat xlon if mi(_ID), lwidth(vthin) lcolor(eltblue) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off)

end


program define ex6

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo drop if inlist(_ID, 55,54,32,28,29,37,40) // Alaska, Hawaii, territories

	Echo geo2xy _Y _X , gen(ylat xlon) proj(picard)
	
	Echo return list
	
	Echo line ylat xlon, lwidth(vthin) lcolor(gray) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off) ///
			xline(-77.035279, lstyle(grid)) yline(38.889689, lstyle(grid)) 
		   
end 


program define ex6t

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo drop if inlist(_ID, 55,54,32,28,29,37,40) // Alaska, Hawaii, territories

	Echo geo2xy _Y _X , gen(ylat xlon) proj(picard) tissot
	
	Echo return list
	
	Echo line ylat xlon if !mi(_ID), lwidth(vthin) lcolor(gray) cmissing(n) || ///
			line ylat xlon if mi(_ID), lwidth(vthin) lcolor(eltblue) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off) ///
			xline(-77.035279, lstyle(grid)) yline(38.889689, lstyle(grid)) 

end


program define ex7

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo keep if _ID == 37
	
	Echo gen double _XX = cond(_X > 0, _X - 180, _X + 180)

	Echo geo2xy _Y _XX , gen(ylat xlon)
	
	Echo return list
	
	Echo line ylat xlon, lwidth(vthin) lcolor(gray) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off)
		   
end


program define ex7t

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo keep if _ID == 37
	
	Echo gen double _XX = cond(_X > 0, _X - 180, _X + 180)

	Echo geo2xy _Y _XX , gen(ylat xlon) tissot
	
	Echo return list
	
	Echo line ylat xlon if !mi(_ID), lwidth(vthin) lcolor(gray) cmissing(n) || ///
			line ylat xlon if mi(_ID), lwidth(vthin) lcolor(eltblue) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off)
		   
end


program define ex8

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo keep if _ID == 37
	
	Echo gen double _XX = cond(_X > 0, _X - 180, _X + 180)

	Echo geo2xy _Y _XX , gen(ylat xlon) proj(albers)
	
	Echo return list
	
	Echo line ylat xlon, lwidth(vthin) lcolor(gray) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off)
		   
end


program define ex8t

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo keep if _ID == 37
	
	Echo gen double _XX = cond(_X > 0, _X - 180, _X + 180)

	Echo geo2xy _Y _XX , gen(ylat xlon) proj(albers) tissot
	
	Echo return list
	
	Echo line ylat xlon if !mi(_ID), lwidth(vthin) lcolor(gray) cmissing(n) || ///
			line ylat xlon if mi(_ID), lwidth(vthin) lcolor(eltblue) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off)
		   
end




program define ex_web_mercator

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo keep if _ID == 44
	
	Echo geo2xy _Y _X, gen(ylat xlon) project(web_mercator,10 xtile ytile)
	
	Echo return list
	
	Echo list in 1/10

	Echo line ylat xlon, lwidth(vthin) lcolor(gray) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off)
			
	Echo summarize

end


program define ex_mercator_sphere

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo keep if _ID == 44
	
	Echo geo2xy _Y _X, gen(ylat xlon) project(mercator_sphere) tissot
	
	Echo return list
	
	Echo list in 1/10

	Echo line ylat xlon if !mi(_ID), lwidth(vthin) lcolor(gray) cmissing(n) || ///
			line ylat xlon if mi(_ID), lwidth(vthin) lcolor(eltblue) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off)
			
	Echo summarize

end


program define ex_equi_mi

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo keep if _ID == 44
	
	Echo geo2xy _Y _X, gen(ylat xlon) project(equidistant_cylindrical) tissot
	
	Echo return list
	
	Echo line ylat xlon if !mi(_ID), lwidth(vthin) lcolor(gray) cmissing(n) || ///
			line ylat xlon if mi(_ID), lwidth(vthin) lcolor(eltblue) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off)
			
	Echo summarize

end


program define ex_equi_ak

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo keep if _ID == 37
	
	Echo gen double _XX = cond(_X > 0, _X - 180, _X + 180)

	Echo geo2xy _Y _XX , gen(ylat xlon) proj(equidistant_cylindrical) tissot
	
	Echo line ylat xlon if !mi(_ID), lwidth(vthin) lcolor(gray) cmissing(n) || ///
			line ylat xlon if mi(_ID), lwidth(vthin) lcolor(eltblue) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off)
		   
end


program define ex_mercator

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo keep if _ID == 44
	
	Echo geo2xy _Y _X, gen(ys xs) project(mercator_sphere)
	
	Echo gen double xlons = xs * 6378137
	
	Echo gen double ylats = ys * 6378137

	Echo geo2xy _Y _X, gen(ylat xlon) project(mercator)
	
	Echo return list
	
	Echo list in 1/10

	Echo line ylat xlon, lwidth(vthin) lcolor(gray) cmissing(n) || ///
			line ylats xlons, lwidth(vthin) lcolor(eltblue) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off)

	Echo gen ydiff = ylats - ylat
			
	Echo summarize
	
	Echo summarize ydiff if _Y < 41.7
	Echo summarize ydiff if _Y > 48.19
	
end



program define ex_albers_sphere

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo drop if inlist(_ID, 55,54,32,28,29,37,40) // Alaska, Hawaii, territories

	Echo geo2xy _Y _X , gen(ylat xlon) proj(albers_sphere)
	
	Echo return list
	
	Echo sum _X
	
	Echo dis (r(min) + r(max)) / 2
	
	Echo geo2xy _Y _X , gen(ylat2 xlon2) proj(albers_sphere, 29.5 45.5 0 -95.856482)
	
	Echo return list
	
	Echo line ylat2 xlon2, lwidth(vthin) lcolor(gray) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off)

end


program define ex_albers_sphere_t

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo drop if inlist(_ID, 55,54,32,28,29,37,40) // Alaska, Hawaii, territories

	Echo geo2xy _Y _X , gen(ylat xlon) proj(albers_sphere) tissot
	
	Echo return list
	
	Echo sum _X
	
	Echo dis (r(min) + r(max)) / 2
	
	Echo geo2xy _Y _X , gen(ylat2 xlon2) proj(albers_sphere, 29.5 45.5 0 -95.856482) tissot
	
	Echo return list
	
	Echo line ylat2 xlon2 if !mi(_ID), lwidth(vthin) lcolor(gray) cmissing(n) || ///
			line ylat2 xlon2 if mi(_ID), lwidth(vthin) lcolor(eltblue) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off)

end


program define ex_albers

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo drop if inlist(_ID, 55,54,32,28,29,37,40) // Alaska, Hawaii, territories

	Echo geo2xy _Y _X , gen(ylat xlon) proj(albers)
	
	Echo return list
	
	Echo sum _X
	
	Echo dis (r(min) + r(max)) / 2
	
	Echo geo2xy _Y _X , gen(ylat2 xlon2) proj(albers, 6378137 298.257223563 29.5 45.5 0 -95.856482)
	
	Echo return list
	
	Echo line ylat2 xlon2, lwidth(vthin) lcolor(gray) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off)

end


program define ex_albers_t

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo drop if inlist(_ID, 55,54,32,28,29,37,40) // Alaska, Hawaii, territories

	Echo geo2xy _Y _X , gen(ylat xlon) proj(albers) tissot
	
	Echo return list
	
	Echo sum _X
	
	Echo dis (r(min) + r(max)) / 2
	
	Echo geo2xy _Y _X , gen(ylat2 xlon2) proj(albers, 6378137 298.257223563 29.5 45.5 0 -95.856482) tissot
	
	Echo return list
	
	Echo line ylat2 xlon2 if !mi(_ID), lwidth(vthin) lcolor(gray) cmissing(n) || ///
			line ylat2 xlon2 if mi(_ID), lwidth(vthin) lcolor(eltblue) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off)

end




program define ex_picard

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo drop if inlist(_ID, 55,54,32,28,29,37,40) // Alaska, Hawaii, territories

	Echo geo2xy _Y _X , gen(ylat xlon) proj(picard, 38.889689)
	
	Echo return list
	
	Echo line ylat xlon, lwidth(vthin) lcolor(gray) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off) ///
			xline(-77.035279, lstyle(grid)) yline(38.889689, lstyle(grid)) 
		   
end 


program define ex_picard_t

	preserve
	
	Echo use "geo2xy_us_coor.dta", clear
	
	Echo drop if inlist(_ID, 55,54,32,28,29,37,40) // Alaska, Hawaii, territories

	Echo geo2xy _Y _X , gen(ylat xlon) proj(picard, 38.889689) tissot
	
	Echo return list
	
	Echo line ylat xlon if !mi(_ID), lwidth(vthin) lcolor(gray) cmissing(n) || ///
			line ylat xlon if mi(_ID), lwidth(vthin) lcolor(eltblue) cmissing(n) ///
			ylabel(minmax, nogrid) yscale(off) xlabel(minmax, nogrid) xscale(off) ///
			aspectratio(`r(aspect)') legend(off) ///
			xline(-77.035279, lstyle(grid)) yline(38.889689, lstyle(grid)) 
		   
end 

