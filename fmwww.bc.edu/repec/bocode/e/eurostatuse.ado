/*	
	Authors: Sebastien Fontenay (UAH, ULB- sebastien.fontenay@uah.es / sebastien.fontenay@ulb.be)
	         Sem Vandekerckhove (HIVA, KUL - sem.vandekerckhove@kuleuven.be)

	Version: 3.0
	Last update: Januari 2024
 
	This program uses syntax from Diego Jose Torres Torres (diegotorrestorres@gmail.com).
	We also thank Duarte Gonçalves for the early feedback and spontaneously sent help file.

	**********************************************************************************************************************************
	**********************************************************************************************************************************
	**	                                            	                                                                            **
	**	If you are using Stata on a Windows computer, you need to have 7-zip (http://www.7-zip.org/)                                **
	**	installed in the program files folder (C:\Program Files\7-Zip\7zG.exe) in order to unzip the gunzip (.gz) files.            **
	**	                                                                                                                	        **
	**	Note that downloading from Stata is preferred over downloading through a browser, as                                        **
	**	Eurostat data is wrongly transferred over http in some browsers (notably using Google Chrome).                              **
	**	                                                                                                         	                **
	**	If you are behind a proxy you should consult: http://www.stata.com/support/faqs/web/common-connection-error-messages/       **
	**                                                                                                                              **
	**********************************************************************************************************************************
	*********************************************************************************************************************************/

program define eurostatuse
version 11.0
syntax namelist(name=indicator) [, long noflags nolabel noerase save ///
								   start(string) end(string) geo(string) ///
								   keepdim(string) clear]

quietly {

local indicator = upper("`indicator'")

// Clear data and check whether the database exists

if `"`clear'"' == "clear" {
	clear
} 
if (c(changed) == 1) & (`"`clear'"' == "" ) {
    error 4
}

copy "https://ec.europa.eu/eurostat/api/dissemination/files/inventory?type=data" databaselist.txt, replace
insheet using databaselist.txt, clear names
keep if code=="`indicator'"
count
if r(N)==0 {
	noisily display in red "Dataset does not exist - Consult Eurostat website: https://ec.europa.eu/eurostat/data/database"
	clear
	exit
}

/* OLD (hope to recover this from another source)

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
*/

/* NEW: no start/end nor title, just latest change */
else {
	noisily display in green ///
	_newline _col(5) "Last update: " lastdatachange ///
	_newline
	clear
}


// Check that 7-zip is installed on Windows computer

if c(os)=="Windows" {
	capture confirm file "C:\Program Files\7-Zip\7zG.exe"
		if _rc==0 {
		}
		else {
			noisily di in red "Install 7-zip here: C:\Program Files\7-Zip\7zG.exe, or edit ado."
			exit
		}
}

cap erase databaselist.txt 


// Download data from Eurostat bulk download facility (2024 migration)

noisily di "Downloading and formating data ..."
copy  "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/`indicator'/?format=TSV&compressed=true" `indicator'.tsv.gz, replace
if c(os)=="Windows" {
	shell "C:\Program Files\7-Zip\7zG.exe" x -y `indicator'.tsv.gz
}
if c(os)=="MacOSX" {
	shell gunzip `indicator'.tsv.gz
}

insheet using `indicator'.tsv, tab names double
ds
local firstvar : word 1 of `r(varlist)'
rename `firstvar' DimensionS

// Keep only specified time range

if "`start'"!="" {
	lookfor \time
	if "`r(varlist)'"=="DimensionS" {
		lookfor `start'
		if "`r(varlist)'"=="" {
			noisily display in red "Start time not in range or no data for this time period"
			clear
			cap erase `indicator'.tsv.gz
			cap erase `indicator'.tsv
			exit 197
		}
		local num : word count `r(varlist)'
		local varend : word `num' of `r(varlist)'
		keep DimensionS-`varend'
	}
	else {
		noisily display in red "No time dimension - cannot specify [, start()] option"
		clear
		cap erase `indicator'.tsv.gz
		cap erase `indicator'.tsv
		exit 197
	}
}

if "`end'"!="" {
		lookfor \time
		if "`r(varlist)'"=="DimensionS" {
			lookfor `end'
			if "`r(varlist)'"=="" {
			noisily display in red "End time not in range or no data for this time period"
			clear
			cap erase `indicator'.tsv.gz
			cap erase `indicator'.tsv
			exit 197
			}
			local varfirst : word 1 of `r(varlist)'
			ds
			local num : word count `r(varlist)'
			local lastvar : word `num' of `r(varlist)'
			keep DimensionS `varfirst'-`lastvar'
		}
		else {
			noisily display in red "No time dimension - cannot specify [, end()] option"
			clear
			cap erase `indicator'.tsv.gz
			cap erase `indicator'.tsv
			exit 197
	}
}

// Keep only selected geo entities

if "`geo'"!="" {
	lookfor \time
	if "`r(varlist)'"=="DimensionS" {
		gen DimensionS2=","+DimensionS+","
		gen dimcomplex=.
			foreach dim of local geo {	
				count if regexm(DimensionS2, ",`dim',")
				if r(N)!=0 {
				replace dimcomplex=1 if regexm(DimensionS2, ",`dim',")		
				}
				else {
					noisily display in red "No data for one geo entity or wrong code"
					clear
					cap erase `indicator'.tsv.gz
					cap erase `indicator'.tsv
					exit 197
				}
			}
			drop if dimcomplex!=1
			drop dimcomplex	DimensionS2		
	}

	lookfor \geo
	if "`r(varlist)'"=="DimensionS" {
	local geo2=lower("`geo'")
	foreach dim of local geo2 {
		lookfor `dim'
		if "`r(varlist)'"=="" {
			noisily display in red "No data for one geo entity or wrong code"
			clear
			cap erase `indicator'.tsv.gz
			cap erase `indicator'.tsv
			exit 197
		}
	}
	keep DimensionS `geo2'
	}
}

// Keep only selected dimensions

if "`keepdim'"!="" {
gen DimensionS2=","+DimensionS+","
tokenize `keepdim', parse(";")
local i = 1
while "``i''" != "" {
	if "``i''"!=";" {
		gen dimcomplex=.
			foreach dim of local `i' {
				count if regexm(DimensionS2, ",`dim',")
				if r(N)==0 {
					noisily display in red "No data for one dimension or wrong code"
					clear
					cap erase `indicator'.tsv.gz
					cap erase `indicator'.tsv
					exit 197	
				}
				replace dimcomplex=1 if regexm(DimensionS2, ",`dim',")
			}
			drop if dimcomplex!=1
			drop dimcomplex
		}			
	local i = `i' + 1
	}
drop DimensionS2
}

// Separate values and flags (default: have flags)

ds DimensionS, not
foreach var of varlist `r(varlist)' {
	local geotime : variable label `var'
	rename `var' `indicator'`geotime'
	label var `indicator'`geotime'
	if "`flags'" != "noflags" {
		generate flags_`indicator'`geotime' = `indicator'`geotime'
		order flags_`indicator'`geotime', after(`indicator'`geotime')
		tostring flags_`indicator'`geotime', replace force
		replace flags_`indicator'`geotime' = trim(substr(flags_`indicator'`geotime',strpos(flags_`indicator'`geotime'," "),.))
	}
	destring `indicator'`geotime', replace ignore("b c d e f i n p r s u z :")
}

// Reshape dataset to long format (option)

if "`long'" == "long" {
	noisily di "Reshaping dataset ..."
	if "`flags'" == "noflags" {
		reshape long `indicator', i(DimensionS) j(geotime, string)
	}
	else {
		reshape long `indicator' flags_`indicator', i(DimensionS) j(geotime, string)
	}
	order geotime, before(`indicator')

// Fix time or geo dimension

lookfor \time
if "`r(varlist)'"=="DimensionS" { 
	rename geotime date
	*Daily
	if regexm(date, "D") {
	replace date=subinstr(date, "M", "/", .)
	replace date=subinstr(date, "D", "/", .)
	gen time=daily(date, "YMD")
	format time %td
	}
	*Monthly
	if regexm(date, "M") {
	gen time=monthly(date, "YM")
	format time %tm
	}
	*Quarterly
	if regexm(date, "Q") {
	gen time=quarterly(date, "YQ")
	format time %tq
	}
	*Yearly
	cap destring date, replace
	cap gen time=date
	cap order time, after(date)
	cap drop date
}
lookfor \geo
if "`r(varlist)'"=="DimensionS" {
	rename geotime geo
}
}

// Split DimensionS

split DimensionS, parse(,) gen(Dimension_) destring
order Dimension_*
local DIMENSIONS : variable label DimensionS
local DIMENSIONS : subinstr local DIMENSIONS "," " " , all
local DIMENSIONS : subinstr local DIMENSIONS "\" " "
local N_DIMENSIONS : word count `DIMENSIONS'
forvalues i=1/`N_DIMENSIONS' {
	capture local varname`i' : word `i' of `DIMENSIONS'
	capture rename Dimension_`i' `varname`i'' 
}

drop DimensionS

/* NEW */

/* 

the new (2024) inventory gives this download link (3.0, which does not work):			
https://ec.europa.eu/eurostat/api/dissemination/sdmx/3.0/structure/codelist/ESTAT/ACCIDENT/1.2?format=TSV&formatVersion=2.0

the online table shows this (works, 2.1, which works):
https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/codelist/ESTAT/EFFECT/?compressed=true&format=TSV&lang=en			

*/	

// Download labels from Eurostat bulk download facility (default: label variables)

preserve

	// new database has upper case variables, ado appears to not accept placeholder for all variables
	ds 
	foreach var of varlist `r(varlist)' {
		local upper = upper("`var'")
		cap rename `var' `upper'
		}

	if "`label'" == "nolabel" {
	}
	else {
		noisily display in green "Downloading and formating labels ..."
	}

	ds *`indicator'*, not
	
	// First download the list before looping (varlist still in memory)
	
	copy "https://ec.europa.eu/eurostat/api/dissemination/files/inventory?type=codelist" codelist.txt, replace
	insheet using codelist.txt, clear
	
	foreach var in `r(varlist)' {
	di "`var'"
		*insheet using "https://ec.europa.eu/eurostat/estat-navtree-portlet-prod/BulkDownloadListing?sort=1&file=dic%2Fen%2Fdimlst.dic", tab clear
		insheet using codelist.txt, clear
		*replace v1=lower(v1)
		gene v1 = lower(code)
		keep if v1=="`var'"
		*local lb`var'=v2
		local lb`var'=label
		
		* Download value labels (need to be unzipped)
		if "`label'" == "nolabel" {
			}
		else {
			local lbls = upper("`var'")
			di "`lbls'"
			copy "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/codelist/ESTAT/`lbls'/?compressed=true&format=TSV&lang=en" `lbls'.tsv.gz, replace
				if c(os)=="Windows" {
					shell "C:\Program Files\7-Zip\7zG.exe" x -y `lbls'.tsv.gz
				}
				if c(os)=="MacOSX" {
					shell gunzip `lbls'.tsv.gz
				}
			insheet using `lbls'.tsv, tab double clear
			
				cap tempfile `var'_file
				cap rename v1 `var'
				cap rename v2 `var'_label
				cap save ``var'_file', replace
				erase `lbls'.tsv
			}
		}
		
restore

cap erase codelist.txt

	ds 
	foreach var of varlist `r(varlist)' {
		local upper = upper("`var'")
		cap rename `var' `upper'
		}
	ds
	
ds *`indicator'*, not
foreach var of varlist `r(varlist)' {
	if "`var'"!="time" {
	label var `var' "`lb`var''"
	}
		if "`label'" == "nolabel" {
		}
		else {
			if "`var'"!="time" {
			cap merge m:1 `var' using ``var'_file', nogenerate keep(match)
			cap order `var'_label, after(`var')
			}
		}
	
}

// Sort data

ds *`indicator'*, not
sort `r(varlist)'

// Erase working files  (default: erase)

cap erase `indicator'.tsv.gz
if "`erase'" == "noerase" {
	noisily display in green "raw data stored as `indicator'.tsv"
}
else {
	erase `indicator'.tsv
}


// Save in Stata format with lower case variables

compress

ds 
foreach var of varlist `r(varlist)' {
	local lower = lower("`var'")
	cap rename `var' `lower'
	}

if "`save'" == "save" {
	save `indicator'.dta, replace
	noisily	display in green "file `indicator'.dta saved"
}

}

end
