* chesspos
* Version 1.0
* 29/11/2022
* Dominik Flügel

program define chesspos
version 14

syntax anything [, Black name(passthru) saving(passthru) nodraw]

* Check Input
capture assert strlen("`1'") > 16
if c(rc) != 0 {
	dis in red "This does not seem to be a valid chess position in FEN notation."
	exit 198
}


* Maintain Scheme and Font
local scheme "`c(scheme)'"
set scheme s1mono
//graph set window fontfacesymbol default	

* Check value labels don't already exist
qui label dir
foreach label in lb_file lb_rank_black {
	if strpos("`r(names)'", "`label'") {
		dis as text "You have already defined one or more of the following three value labels:"
		dis as input "lb_file"
		dis as input "lb_rank_black"
		dis as text "Stata does not allow temporary value labels," ///	
					"please rename any of the three so that chesspos can use them."
		exit 
	}	
}


* Initiate temporary variables
tempvar touse file rank piece rank_white btm_file btm_rank btm_rank_white

* Generate and mark new observations
qui des, short
local n = r(N)
local new_start = r(N) + 1
local new_end	= r(N) + 64
qui set obs `new_end'

qui mark `touse' in `new_start'/`new_end'

* distribute ranks (1-8) and files (A-H)
qui gen `file' = .
qui label def lb_file 1 "A" -1 "A" 2 "B" -2 "B" 3 "C" -3 "C" 4 "D" -4 "D" ///
					  5 "E" -5 "E" 6 "F" -6 "F" 7 "G" -7 "G" 8 "H" -8 "H", modify
qui label val `file' lb_file
qui gen `rank' = .

local i = 0
forval x = 1/8 {
	forval y = 1/8 {
		local ++i
		qui replace `file' = `x' if _n == `n' + `i'
		qui replace `rank' = `y' if _n == `n' + `i'
	}
}

* parse position
local pos `1'
forval i = 1/8 {
	local x = substr("xxxxxxxx", 1, `i')
	local pos = ustrregexra("`pos'", "`i'", "`x'") // replace the number i (marking number of empty fields) in the string pos with a string of "x"s with the length of i
	*dis as text "`pos'"
}
local pos = ustrregexra("`pos'", "/", " ") // replace "/" with " "

* insert pieces in FEN notation
qui gen `piece' = ""
local y = 8 // FEN positions start with 8th rank
foreach col in `pos' {
	forval x = 1/8 {
		qui replace `piece' = substr("`col'", `x' , 1) if `rank' == `y' & `file' == `x'
	}
	local --y
}

* replace pieces with font letter
qui replace `piece' = "" if `piece' == "x"					 // empty field

qui replace `piece' = `"{fontface "Arial Unicode MS":♔}"' if `piece' == "K" // white king
qui replace `piece' = `"{fontface "Arial Unicode MS":♕}"' if `piece' == "Q" // white queen
qui replace `piece' = `"{fontface "Arial Unicode MS":♖}"' if `piece' == "R" // white rook
qui replace `piece' = `"{fontface "Arial Unicode MS":♘}"' if `piece' == "N" // white knight
qui replace `piece' = `"{fontface "Arial Unicode MS":♗}"' if `piece' == "B" // white bishop
qui replace `piece' = `"{fontface "Arial Unicode MS":♙}"' if `piece' == "P" // white pawn

qui replace `piece' = `"{fontface "Arial Unicode MS":♚}"' if `piece' == "k" // black king
qui replace `piece' = `"{fontface "Arial Unicode MS":♛}"' if `piece' == "q" // black queen
qui replace `piece' = `"{fontface "Arial Unicode MS":♜}"' if `piece' == "r" // black rook
qui replace `piece' = `"{fontface "Arial Unicode MS":♞}"' if `piece' == "n" // black knight
qui replace `piece' = `"{fontface "Arial Unicode MS":♝}"' if `piece' == "b" // black bishop
qui replace `piece' = `"{fontface "Arial Unicode MS":♟}"' if `piece' == "p" // black pawn

* create second variable for white fields (missings)
qui gen `rank_white' = `rank'

foreach y in 2 4 6 8 {
	qui replace `rank_white' = . if inlist(`file', 1, 3, 5, 7) & `rank' == `y'
}

foreach y in 1 3 5 7 {
	qui replace `rank_white' = . if inlist(`file', 2, 4, 6, 8) & `rank' == `y'
}


* Mirror board; (if black is to move, "btm")
qui gen `btm_rank' = `rank' * (-1)
qui gen `btm_rank_white' = `rank_white' * (-1)
label def lb_rank_black -1 "1" -2 "2" -3 "3" -4 "4" -5 "5" -6 "6" -7 "7" -8 "8"
label val `btm_rank' `btm_rank_white' lb_rank_black

qui gen `btm_file' = `file' * (-1)
label val `btm_file' lb_file



* Output (white to move)
capture noisily {
	if "`black'" == "" {
		scatter `rank_white' `file',						 						///
			msymbol(S) mcolor(black*.4) msize(*6.4) 								///
			xtitle("") ytitle("") aspectratio(1) ||									///
		scatter `rank' `file', msymbol(none) 										///
			mlabel(`piece') mlabpos(12) mlabsize(*3) mlabgap(*-5)					///
			xlabel(1(1)8, noticks nogrid val)		xscale(range(0.5 8.5))			///
			ylabel(1(1)8, noticks nogrid angle(0)) 	yscale(range(0.5 8.5))			///
			yline(0.5 8.5, lpattern(solid) lcolor(black))							///
			xline(0.5 8.5, lpattern(solid) lcolor(black))							///
			legend(off) `name' `draw' `saving'
	}
	* Output (black to move)
	else {
		scatter `btm_rank_white' `btm_file',				 						///
			msymbol(S) mcolor(black*.4) msize(*6.4) 								///
			xtitle("") ytitle("") aspectratio(1) ||									///
		scatter `btm_rank' `btm_file', msymbol(none)								///
			mlabel(`piece') mlabpos(12) mlabsize(*3) mlabgap(*-5)					///
			xlabel(-1(1)-8, noticks nogrid val) 		 xscale(range(-0.5 -8.5))	///
			ylabel(-1(1)-8, noticks nogrid val angle(0)) yscale(range(-0.5 -8.5))	///
			yline(-0.5 -8.5, lpattern(solid) lcolor(black))							///
			xline(-0.5 -8.5, lpattern(solid) lcolor(black))							///
			legend(off) `name' `draw' `saving'
	}	
}
	
* Reset Scheme and delete observations
set scheme `scheme'
qui drop if `touse'
label drop lb_file lb_rank_black

end
