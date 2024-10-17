*! version 3.0.2 Mai 23, 2022 @ 21:48:43 UK
* This is -holrein- reloaded

// 1.0.0 Initial version
// 1.0.1 File type kind does not work -> fixed.
// 1.0.2 Blanks positions in varlist returned an error -> fixed.
// 2.0 Updated to Stata 11
// 3.0 Updated to GSOEP after wave "z" 
// 3.0.1. Bug-fix
// 3.0.2. Option fast not used. -> fixed
// 4.0 New identifier variables

program soepadd
version 11
	
	// Option clear
	// ------------

	syntax anything ,  ///
	  Ftyp(string) Waves(numlist >= 1984 integer sort) ///  
	  [ Ost(string) onlyost uc fast ]
	
	// Additional syntax checks
	// ------------------------
	
	if strpos("`ost'","g") & !strpos("`waves'","1990") {
		di as error "ost(g) requires waves() to include 1990"
		exit 198
	}
	if strpos("`ost'","h") & !strpos("`waves'","1991") {
		di as error "ost(h) requires waves() to include 1991"
		exit 198
	}
	
	if "`onlyost'" != "" & "`ost'" == "" {
		di as error "onlyost() requires ost()"
		exit 198
	}

	// Catch dirname from soepuse
	// --------------------------

	local using: char _dta[soepusedir]

	
	// Set up alhanumerical wavelists
	// -----------------------------
	
	foreach year of local waves {
		local token: word `=`year'-1983' of `c(alpha)'
		if `year' == 1990 & strpos("`ost'","g") local token "g gost"
		if `year' == 1991 & strpos("`ost'","h") local token "h host"
		if `year' >= 2010 local token "b`:word `=max(1,`=`year'-2009')' of `c(alpha)''"
		local wavelist "`wavelist' `token'"
	}
	if "`onlyost'" != "" {
		local wavelist: subinstr local wavelist "g" "", word
		local wavelist: subinstr local wavelist "h" "", word
	}
	local shortwlist: subinstr local wavelist "gost" "", word
	local shortwlist: subinstr local shortwlist "host" "", word

	// Set identifier
	// --------------
	
	if substr("`ftyp'",1,1) =="p" | "`ftyp'" == "kind" 	{
		local identif  "cid hid pid"
		local match "1:1"
	}
	else if substr("`ftyp'",1,1) =="h" {
		local identif  "cid hid"
		local match "n:1"
	}
	else {
		di in red "filetype not valid"
        exit 198
	}
	
	// Value for interview
	// -------------------
	
	local intvalue = cond("`oldnetto'"=="",10,1) 
	
	// Check Namelist
	// -------------
	
	// Namelist can only be complete, if the number of variables is 
	// a multiple of the numbers of waves. This is only necassary
	// but not sufficent. However it is an indicator and very fast to control
	
	local nwaves: word count `wavelist'
	local nvars: word count `anything'
	if mod(`nvars',`nwaves') {
		di as error "namelist does not seem to fit wavelist"
	}
	
	// Build Filenames
	// ---------------
	
	foreach w of local wavelist {
		if "`w'" == "gost" | "`w'" == "host" {
			local token = substr("`w'",1,1)
			local filelist "`filelist' `token'`ftyp'ost"
		}
		else local filelist "`filelist' `w'`ftyp'"
	}
	
	// Option UC 
	// ---------
	
	if "`uc'"~="" {
        foreach var of local anything {
			local varl "`varl' `=lower("`var'")'"
		}
		local anything "`varl'"
	}
	
	// Option fast
	// -----------
	
	// By default we run an addtional check before starting
	if "`fast'" == "" {
		quietly {
			local i 1
			foreach file of local filelist {
				tokenize `anything'  
				forv j = `i++'(`nwaves')`nvars' {        
					if "``j''" != "-" local vars "`vars' ``j''"
				}
				capture describe `identif' `vars' using `"`using'/`file'"'
				if _rc {
					noi display "{err} Varlist invalid for file `file'"
					exit _rc
				}
				macro drop _vars
			}
		}
	}

	
	preserve
	drop _all
	
	// Use vars and save files
	local i 1 
	foreach file of local filelist {
		tokenize `anything'  
		forv j = `i++'(`nwaves')`nvars' {        
			if substr("``j''",1,1) ~= "-" {
				local vars "`vars' ``j''"
			}
		}
		qui use `identif' `vars' using `"`using'/`file'"'
		sort `identif'
		tempfile `file'
		quietly save ``file''
		macro drop _vars
	}
	
	restore

	// Merge Using files
	// -----------------

	quietly {
		local i 1
		gen long hid = .
		foreach file of local filelist {
			if "`file'" == "gpost" | "`file'" == "ghost" | "`file'" == "gpkalost" local year = 1990
			else if "`file'" == "hpost" | "`file'" == "gpkalost" local year = 1991
			else {
				local year `:word `i' of `waves''
				local i = `i' +1
			}
			replace hid = hid_`year'
			sort `identif'
			merge `match' `identif' using ``file'', keep(1 3) nogen
		}
		drop hid
	}
	
end
exit

Author: Ulrich Kohler
Tel. +49 331 9773565
Email ukohler@uni-potsdam.de
