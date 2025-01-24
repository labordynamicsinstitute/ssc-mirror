/*	
	Authors: 
	
	Sem Vandekerckhove (HIVA-KU LEUVEN - sem.vandekerckhove@kuleuven.be)
	Sebastien Fontenay (UAH Alcalá (Madrid), ULB - sebastien.fontenay@uah.es)
	         
	Version: 4.0.0
	Last update: 22 January 2025
	What's new:
	- Import of tsv file recoded (use [altimport] if it fails)
	- Removed the [noerase] option (now undocumented)
	- Help file and dialog box are updated
 
	Thanks to:
	- Josip Arneric (jarneric@net.efzg.h): signaling broken start() and end() options.
	- Wolf-Fabian Hungerland (wolf-fabian.hungerland@bmwk.bund.de): suggestion to include uncompressed option.
	- Nikolaos Kanellopoulos (nkanel@kepe.gr): date fix.
	- Diego Jose Torres Torres (diegotorrestorres@gmail.com): some early syntax ideas.
	- Duarte Gonçalves: early feedback and help file.
	
	Notes: 
	- [nolabel] is faster and reduces file size
	- [long] is very useful, but for datasets with a high time frequency (e.g. monthly or daily data), 
		it may be faster to _not_ use it, and instead to reshape the data in your syntax.
	- For larger tables, the decompressing may fail. Use [uncompressed] in that case.
	- Use [uncompressed] also to avoid issues with cloud storage and shell commands.
	- The import code has been rewritten entirely. For an even faster import, use the [altimport] 
		option, but this uses some shell commands.
	- EUROSTAT has migrated its database in 2024. Some previous functionality 
		with respect to time variables and indicator labels, is now lost. 
	- Please let us know if you experience other issues in the mean time.

	Installation:
	- If you are using Stata on a Windows computer, you either need to specify 
		the [uncompressed] option or have 7-zip (http://www.7-zip.org/) installed 
		in the program files folder (C:\Program Files\7-Zip\7zG.exe) in order to 
		unzip the gunzip (.gz) files.
	- If you are behind a proxy, please consult: http://www.stata.com/support/faqs/web/common-connection-error-messages/      
	
*/

capture program drop eurostatuse
program define eurostatuse
version 14.0
syntax namelist(name=indicator) [,  long noflags nolabel ///
									start(string) end(string) geo(string) keepdim(string)  ///
									altimport uncompressed noerase save clear]

quietly {

/* For testing
local clear = "clear"
local indicator = "NAMA_10_GDP"
*local flags = "noflags"
local start = "1990"
local end = "2010"
local keepdim = "P3_P6 D3; PC_GDP"
local geo = "BE DE"	// testing
*local label = "nolabel"
local table = "/Users/semvandekerckhove/Temp/NAMA_10_GDP BU.tsv"
*local erase = "noerase"
*/


* Get data
* ========

if `"`clear'"' == "clear" {
	clear
	}

* Errors 
if (c(changed) == 1) & (`"`clear'"' == "" ) {
    error 4 // no; dataset in memory has changed since last saved
	}

* Set indicator variable capitalization
local indicator = lower(`"`indicator'"')
local upind = upper(`"`indicator'"')

* Harmonise time range
foreach trange in "start" "end" {
	local `trange' = subinstr("``trange''", "-","M",1)
	local `trange' = subinstr("``trange''", "-","D",1) 
	local `trange' = subinstr("``trange''", "MQ","Q",1) 
	local `trange' = subinstr("``trange''", "MS","S",1)
	local `trange' = subinstr("``trange''", "M0","M",1) 
	local `trange' = subinstr("``trange''", "D0","D",1) 
	local `trange' = lower("``trange''")
 }

* Check whether the database exists in the working directory, then online

capture confirm file `upind'.tsv
if _rc == 0 & ("`erase'" == "noerase") {
	noisily display as input "Using existing Eurostat table (`indicator')."
	}
else {
	copy "https://ec.europa.eu/eurostat/api/dissemination/files/inventory?type=data" databaselist.txt, replace
	insheet using databaselist.txt, clear names // this doesn't have the variable labels anymore
	keep if code == `"`upind'"'
	count
	if r(N)==0 {
		noisily display in red "Dataset `indicator' does not exist - Consult Eurostat website: https://ec.europa.eu/eurostat/data/database"
		clear
		exit
		}
	else {
		noisily display in green ///
		_newline _col(5) "Last update: " lastdatachange ///
		_newline
		clear
		}

	/* OLD (hope to recover this metadata)

	else {
		replace title=ltrim(title)
		noisily display in green ///
		_newline _col(5) "Dataset: " title ///
		_newline _col(5) "Last update: " lastupdateofdata ///
		_newline _col(5) "Start: " datastart ///
		_newline _col(5) "End: " dataend ///
		_newline
		clear
	}

	NEW: no start/end nor title, just latest change 
	*/

	* Check that 7-zip is installed on Windows computer
	if c(os) == "Windows" {
		local exepath = "C:\Program Files\7-Zip\7zG.exe" // change if installed elsewhere (also below)
		noi di "`exepath'"
		capture confirm file `"`exepath'"' 
			if _rc!=0 {
				noisily di in red "Install 7-zip here: C:\Program Files\7-Zip\7zG.exe, or edit ado."
				noisily di in red "Continuing with uncompressed option (larger and slower file transer)."
				local uncompressed = "uncompressed"
				}
		}

	cap erase databaselist.txt // keep when troubleshooting 

	// Download data from Eurostat bulk download facility (2024 migration)
	noisily display as text "Downloading and formatting data ..."

	if "`uncompressed'" == "uncompressed"  {
		copy  "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/`indicator'/?format=TSV&compressed=false" `upind'.tsv, replace
		}
	if "`uncompressed'" == "" {
		copy  "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/`indicator'/?format=TSV&compressed=true" `upind'.tsv.gz, replace
		if c(os) == "Windows" {
			shell "`exepath'" x -y "`upind'".tsv.gz
			*shell "C:\Program Files\7-Zip\7zG.exe" x -y "`upind'".tsv.gz
			}
		if c(os) == "MacOSX" {
			shell gunzip `upind'.tsv.gz
			}
		}
	}

* Load and clean data
* ===================
//insheet using `upind'.tsv, tab names double // old command

* Replace commas by tabs (could also be done using -split-)

//  alternative import (a bit faster but uses shell/powershell)
if "`altimport'" == "altimport" {
	tempfile outputfile
	if c(os) == "MacOSX" {
		shell sed 's/,/\t/g' "`upind'.tsv" > `outputfile' // output_file.tsv
		}
	if c(os) == "Windows" {
		shell powershell -Command "(Get-Content `upind'.tsv) -replace ',', [char]9 | Set-Content `outputfile'"
		}
	import delimited `outputfile', asdouble varnames(1) clear
	cap erase `outputfile'
	cap rename geotime_period geo // check whether some tables may not have a geo variable
	label var geo ""

	desc
	//list if geo == "BE" & na_item == "D3"

	* Fix time variable labels
	ds
	local firstvar : word 1 of `r(varlist)' 			// ususally this is "freq" (frequency of measurement)
	ds `firstvar'-geo, not								// this is assuming there is always a geo
	local tsvars = "`r(varlist)'"
	}

// default import
if "`altimport'" == "" {							// more like old syntax, less shell
	import delimited "`upind'.tsv", asdouble varnames(1) clear

	ds
	local firstvar : word 1 of `r(varlist)'
	rename `firstvar' DimensionS

	split DimensionS, parse(,) gen(Dimension_) destring
	order Dimension_*, first

	local DIMENSIONS : variable label DimensionS
	local DIMENSIONS : subinstr local DIMENSIONS "," " " , all
	local DIMENSIONS : subinstr local DIMENSIONS "\" " "
	local DIMENSIONS : subinstr local DIMENSIONS "TIME_PERIOD" " "
	local dn : word count `DIMENSIONS'
	*noisily display "Dimensions altimport (`dn'): `DIMENSIONS'"
	forvalues i=1/`dn' {
		capture local varname`i' : word `i' of `DIMENSIONS'
		capture rename Dimension_`i' `varname`i'' 
		}
	drop DimensionS

	ds
	local firstdim : word 1 of `r(varlist)'
	local lastdim : word `dn' of `r(varlist)'
	ds `firstdim'-`lastdim'
	local dimensions = "`r(varlist)'"
	ds `dimensions', not
	local tsvars = "`r(varlist)'"
	}

* Label, define, and select timeseries and dimensions
* ---------------------------------------------------
/* what to do if there is no time series? */
foreach var of varlist `tsvars' {
	qui display "`var'"
	local varlab : var label `var'

	// harmonize time label
	local varlab = subinstr("`varlab'", "-","M",1)
	local varlab = subinstr("`varlab'", "-","D",1) 
	local varlab = subinstr("`varlab'", "MQ","Q",1) 
	local varlab = subinstr("`varlab'", "MS","S",1)
	local varlab = subinstr("`varlab'", "M0","M",1) 
	local varlab = subinstr("`varlab'", "D0","D",1) 
	local varlab = lower("`varlab'")
	qui di "`varlab'"
	rename `var' `indicator'`varlab'
	}

ds
local firstvar : word 1 of `r(varlist)' // eg. "freq'

* Dimensions ("new")
ds `indicator'*, not
local newdimensions = "`r(varlist)'"


* Time series filter
if "`start'" == "" & "`end'" == "" {
	// keep all variables
	}
else {
	// select the time range
	ds `indicator'*
	local n : word count `r(varlist)'
	di "word count n = ", `n'
	local startvar : word 1 of `r(varlist)' // first measurement by default
	local endvar : word `n' of `r(varlist)'
	forvalues vn = 1/`n' {
		local tsvar : word `vn' of `r(varlist)'
		if "`tsvar'" == "`indicator'`start'" {
			local startvar = "`tsvar'"
			}
		if "`tsvar'" == "`indicator'`end'" {
			local endvar = "`tsvar'"
			}
		}
	//noi display "`startvar'"
	//noi display "`endvar'"
	ds `startvar'-`endvar'
	local timeseries = "`r(varlist)'"
	//noi di "`timeseries'"
	keep `newdimensions' `timeseries'
	}


* Geo filter
if "`geo'" == "" {
	}
else {
	tempvar select
	gene byte `select' = 0
	
	local n : word count `geo'
	display "geo number", `n'		// testing
	forvalues gn = 1/`n' {
		local i : word `gn' of `geo'
		display "country: `i'"
		replace `select' = 1 if geo == "`i'"
		}
	keep if `select' == 1
	drop `select'
	}

* Other filters
if !inlist("`keepdim'","",";") {
	tokenize `keepdim', parse(";")	
	local i = 1							// loops through tokens, which consist of words
	while "``i''" != "" { 				// the next token after the last is empty
		display as result "Dimension values: ``i''"
		if "``i''" != ";" {
			tempvar dselect
			gene byte `dselect' = .
			local semicolon = 0
			foreach var of varlist `newdimensions' {
				if !inlist("`var'","geo","freq") {
					display "`var'"
					local n : word count ``i''
					display "Number of values", `n' // testing
					forvalues dn = 1/`n' {
						local dimval : word `dn' of ``i''
						local dimval = trim("`dimval'")
						di "Value to check: `dimval'"
						replace `dselect' = 1 if trim(`var') == "`dimval'" //ok
						}
					}				
				}
			}
		if "``i''" == ";" {				// semicolons are also tokens: trigger a filter 
			local semicolon = 1
			//display as result "Keep selected values and move to next dimension or proceed"
			keep if `dselect' == 1
			drop `dselect'
			}
		local ++i
		}
	if `semicolon' != 1 {
		keep if `dselect' == 1
		drop `dselect'
		}
	}

* Separate flags from values
ds `newdimensions', not
foreach var of varlist `r(varlist)' {
	//display "`var'"
	label var `var' ""
	if "`flags'" != "noflags" {
		generate flags_`var' = `var'
		tostring flags_`var', replace force
		replace  flags_`var' = trim(substr(flags_`var',strpos(flags_`var'," "),.))
		order flags_`var', after(`var')
		}
	destring `var', replace ignore("b c d e f i n p r s u z :")
	}


* Reshape
* =======
/*
Either with or without flags.
Time format needs to be defined.
*/

if "`long'" == "long" {
	if "`flags'" == "noflags" {
		reshape long `indicator', i(`newdimensions') j(time, string)
		}
	else { 
		reshape long `indicator' flags_`indicator', i(`newdimensions') j(time, string)
		tostring flags, force replace
		replace flags = "" if flags == "."
		}

	levelsof freq
	return list
	rename time date
	if r(r) == 1 {
		local timefreq : word 1 of `r(levels)'
		di "`timefreq'"
		local annual = 1
		if "`timefreq'" == "Q" {
			noisily display as text "Quarterly time format"
			gen time=quarterly(date, "YQ")
			format time %tq
			local annual = 0
			}
		if "`timefreq'" == "M" {
			noisily display as text "Monthly time format"
			gen time=monthly(date, "YM")
			format time %tm
			local annual = 0
			}
		if "`timefreq'" == "S" {
			noisily display as text "Half yearly time format"
			gen time=halfyearly(date, "YH")
			format time %th
			local annual = 0
			}
		if "`timefreq'" == "D" {
			noisily display as text "Daily time format"
			gen time=daily(date, "YMD")
			format time %td
			local annual = 0
			}
		if `annual' == 1 {
			noisily di "Annual time format"
			gene time = date
			cap destring time, replace
			}
		}
	drop date
		
		
	}


* Labels
* ======

/* 

The 2024 inventory gives this download link (3.0, which does not work):			
https://ec.europa.eu/eurostat/api/dissemination/sdmx/3.0/structure/codelist/ESTAT/ACCIDENT/1.2?format=TSV&formatVersion=2.0

The online table shows this (works, 2.1, which works):
https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/codelist/ESTAT/EFFECT/?compressed=true&format=TSV&lang=en			

*/

* Download and apply labels from Eurostat bulk download facility (default: label variables)
noisily display as text "Downloading and formatting labels ..."

ds *`indicator'*, not // varlist of dimensions plus time
di "`r(varlist)'"

copy "https://ec.europa.eu/eurostat/api/dissemination/files/inventory?type=codelist" codelist.txt, replace // list with variable labels

foreach var of varlist `r(varlist)' {
	if !inlist("`var'","exludethis") {
		preserve
			// Step 1: variable labels - save a loop of locals with the label
			di "`var'"
			local upvar = upper("`var'")
			insheet using codelist.txt, clear
			keep if code == "`upvar'"
			local lb`var' = label[1]
			di as result "Variable label: `lb`var''"
			
			// Step 2: value labels, download, decompress and save in different tempfiles
			if "`label'" == "nolabel" {
				// do nothing
				}
			else {
				local upvar = upper("`var'")
				di "Variable: `upvar'"
				if "`uncompressed'" == "" {	
					copy "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/codelist/ESTAT/`upvar'/?format=TSV&compressed=true&lang=en" `upvar'.tsv.gz, replace

						if c(os) == "Windows" {
							*shell `"`exepath'"' x -y `"`upvar'.tsv.gz"'
							shell "`exepath'" x -y "`upvar'".tsv.gz
						}
						if c(os) == "MacOSX" {
							shell gunzip `upvar'.tsv.gz
						}
					}
				else {
					copy "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/codelist/ESTAT/`upvar'/?format=TSV&compressed=false&lang=en" `upvar'.tsv, replace
					}
				
				insheet using `upvar'.tsv, tab double clear
				*list in 1/10, clean
				tempfile `var'_file
				rename v1 `var'
				rename v2 `var'_label
				save ``var'_file', replace
				erase `upvar'.tsv
				}
		restore
		}
	}

cap erase codelist.txt // toggle for troubleshooting labels

ds *`indicator'*, not
di "`r(varlist)'"

foreach var of varlist `r(varlist)' {
	display as result "Labeling `var'"
	if !inlist("`var'","time") {
		label var `var' "`lb`var''"

		if "`label'" == "nolabel" {
			// do nothing
			}
		else {
			cap label var `var'_label "`lb`var''"
			cap merge m:1 `var' using ``var'_file', nogenerate keep(match)
			cap order `var'_label, after(`var')
			}
		}
	}
.

* Finish process
* ==============

ds *`indicator'*, not
order `r(varlist)'
sort `r(varlist)'

* Erase working files  (default: erase)
cap erase `upind'.tsv.gz
if "`erase'" == "noerase" {
	noisily display as result "Original table stored as `upind'.tsv, use [noerase] to use this file next time."
	}
else {
	erase `upind'.tsv
	}

// Save in Stata format with lower case variables and file name
compress

if "`save'" == "save" {
	save `indicator'.dta, replace
	noisily	display as result "File `indicator'.dta was saved"
	}

noisily display as result "Program completed"

} // end quietly
end


/* -waitfor- ado

	/* 
	Stata may proceed before the shell script or copy has finished.
	Another issue is that unzipping larger tables on cloud drives may fail. Using a local
	drive, or using the uncompressed option, are solutions. 

	https://u.osu.edu/odden.2/2015/03/10/using-semaphores-to-make-stata-wait-on-a-winexec-result/

	Alternatively, a timer can be programmed to check with intervals whether the file exist. Although
	the approach makes sense, it doesn't work and the [uncompressed] option is your way out.
	*/

// give the shell some time 
local proceed = 0
while `proceed' == 0 {
capture confirm file `upvar'.tsv
if _rc !=0 {
	noisily display "." _continue
	sleep 1000
	//shell gunzip `"$gfile"'
	}
else {
	local ++proceed
	}
}
// file should be decompressed
*/

