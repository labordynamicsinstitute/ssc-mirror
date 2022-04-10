
*! version 1.3.0  7jan2022
*! author: Federico Belotti, Michele Mancini and Alessandro Borin
*! see end of file for version comments

program define icio_load, sclass
    syntax, [ICIOTable(string) Year(string) INFO ]

version 11

*** This is for us: Set this to 0 for distributed version
loc working_version 0

*** Get the right sysdir
loc sysdir_plus `"`c(sysdir_plus)'i/"'

*** Parsing iciotable() suboptions
gettoken iciotable opt_iciotable: iciotable, parse(",")
local iciotable = rtrim(ltrim("`iciotable'"))
local opt_iciotable = rtrim(ltrim(regexr(`"`opt_iciotable'"', ",", "")))

*** Parsing ICIOTable
ParseICIOTable iciotable : `"`iciotable'"'
if `"`opt_iciotable'"'!="" {
	ParseICIOTableUser, `opt_iciotable'
	loc user_defi_table 1
}
else loc user_defi_table 0


if `user_defi_table'==0 {

preserve
// Get the icio_releases file from the web (first time)
cap findfile icio_releases.csv, path(`".;`c(adopath)';`"`sysdir_plus'"'"') nodescend
if _rc {
	// Download the file from http://www.tradeconomics.com/icio/data
	qui insheet using "http://www.tradeconomics.com/icio/data/icio_releases.csv", c clear
	if "`working_version'"=="1" {
		local path4save `"`c(adopath)'"'
		gettoken path4save butta: path4save, parse(";")
	}
	else {
		loc path4save `"`sysdir_plus'"'
	}
	loc path4save = regexr("`path4save'", "/$", "")
	qui outsheet using `"`path4save'/icio_releases.csv"', c
}
else {
	qui insheet using `"`r(fn)'"', c clear
}

// Get table locals and _tab_rels matrix from icio_releases.csv

qui count
local numrel `r(N)'
loc num_rel 2
m _table_rels = J(`=`numrel'-`num_rel'',1,"")
m _tab_rels = J(`=`numrel'-`num_rel'',3,.)
loc j = 1
forvalues i = 1/`numrel' {
	if regexm("`: di table[`i']'", "_rel")==0 {
		loc `: di table[`i']' "`: di rel[`i']'"
		mat _tab_rels = nullmat(_tab_rels) \ (`: di rel[`i']', syear[`i'], eyear[`i'])
		m _table_rels[`j'] = "`: di table[`i']'"
		m _tab_rels[`j',.] = (`: di rel[`i']', `: di syear[`i']', `: di eyear[`i']')
		loc j = `j'+1
	}
	else loc `: di table[`i']' "`: di rel[`i']'"

	if regexm("`: di table[`i']'", "^`iciotable'$")==1 & "`year'"=="" local year `: di eyear[`i']'
}

// Here display the table releases and exit
if "`info'"!="" {
	qui {
		//mat _tab_rels = `wiodn', 2000, 2014 \ `tivan', 2005, 2015 \ `eora' , 1990, 2015 \ `adb', 2000, 2019 \ `wiodo', 1995, 2011 \ `tivao', 1995, 2011
		mat rownames _tab_rels = "wiodn" "tivan" "eora" "adb" "wiodo" "tivao"
		mat colnames _tab_rels = "version" "from" "to"
		noi matlist _tab_rels, row(table_name) cspec(|%5s|%9.0g|%9.0g|%9.0g|) rspec(--&&&&&-)
		cap mat drop _tab_rels
		sret clear
		exit
	}
}

if "`iciotable'" == "wiodn" local filename "icio_`wiodn'_wiod"
if "`iciotable'" == "wiodo" local filename "icio_`wiodo'_wiod"
if "`iciotable'" == "tivan" local filename "icio_`tivan'_tiva"
if "`iciotable'" == "tivao" local filename "icio_`tivao'_tiva"
if "`iciotable'" == "eora" local filename "icio_`eora_rel'_eora"
if "`iciotable'" == "adb" local filename "icio_`adb_rel'_adb"


*** Check if year has 4 digits
if "`user_defi_table'"=="0" {
	loc check_year = length("`year'")
	if "`check_year'"!="4" {
		di as error "-year()- incorrectly specified. It must be yyyy, e.g. 2011."
		exit 198
	}

	m range_avail = select(_tab_rels, _table_rels:=="`iciotable'")
	m range_avail = range_avail[., 2..cols(range_avail)]
	m st_local("_check_year", strofreal((`year'<range_avail[1,1] | `year'>range_avail[1,2])))

	if `_check_year'==1 {
		di as error "Year `year' is not available in the loaded table."
		error 198
	}
}

restore

local yy = substr("`year'",3,2)

} /* close the if on `user_defi_table'==0 */


*** Load country list
preserve
if regexm("`iciotable'","^wi") {
	if "`iciotable'" == "wiodo" local wiod_rel `wiodo'
	if "`iciotable'" == "wiodn" local wiod_rel `wiodn'
	cap findfile wiod_`wiod_rel'_countrylist.csv, path(`".;`c(adopath)';`"`sysdir_plus'"'"') nodescend
	if _rc {
		// Download the file from http://www.tradeconomics.com/icio/data/wiod
		qui insheet using "http://www.tradeconomics.com/icio/data/`iciotable'/wiod_`wiod_rel'_countrylist.csv", c clear
		if "`working_version'"=="1" {
			local path4save `"`c(adopath)'"'
			gettoken path4save butta: path4save, parse(";")
		}
		else {
			loc path4save `"`sysdir_plus'"'
		}
		loc path4save = regexr("`path4save'", "/$", "")
		qui outsheet using `"`path4save'/wiod_`wiod_rel'_countrylist.csv"', c nonames noquote
	}
	else {
		qui insheet using `"`r(fn)'"', c clear
	}
	qui levelsof v1, l(wiod_`wiod_rel'_countrylist) clean
	qui putmata _countryacr=v1 _areeacr=v1, replace
}
if regexm("`iciotable'","^ti") {
	if "`iciotable'" == "tivao" local tiva_rel `tivao'
	if "`iciotable'" == "tivan" local tiva_rel `tivan'
	cap findfile tiva_`tiva_rel'_countrylist.csv, path(`".;`c(adopath)';`"`sysdir_plus'"'"') nodescend
		if _rc {
		// Download the file from http://www.tradeconomics.com/icio/data/tiva
		qui insheet using "http://www.tradeconomics.com/icio/data/`iciotable'/tiva_`tiva_rel'_countrylist.csv", c clear
		if "`working_version'"=="1" {
			local path4save `"`c(adopath)'"'
			gettoken path4save butta: path4save, parse(";")
		}
		else {
			loc path4save `"`sysdir_plus'"'
		}
		loc path4save = regexr("`path4save'", "/$", "")
		qui outsheet using "`path4save'/tiva_`tiva_rel'_countrylist.csv", c nonames noquote
	}
	else {
		qui insheet using `"`r(fn)'"', c clear
	}
	qui levelsof v2, l(tiva_`tiva_rel'_countrylist) clean
	qui putmata _countryacr=v1 _areeacr=v2, replace
}
if "`iciotable'"=="eora" {
	cap findfile eora_countrylist.csv, path(`".;`c(adopath)';`"`sysdir_plus'"'"') nodescend
		if _rc {
		// Download the file from http://www.tradeconomics.com/icio/data/eora
		qui insheet using "http://www.tradeconomics.com/icio/data/`iciotable'/eora_countrylist.csv", c clear
		if "`working_version'"=="1" {
			local path4save `"`c(adopath)'"'
			gettoken path4save butta: path4save, parse(";")
		}
		else {
			loc path4save `"`sysdir_plus'"'
		}
		loc path4save = regexr("`path4save'", "/$", "")
		qui outsheet using "`path4save'/eora_countrylist.csv", c nonames noquote
	}
	else {
		qui insheet using `"`r(fn)'"', c clear
	}
	qui levelsof v1, l(eora_countrylist) clean
	qui putmata _countryacr=v1 _areeacr=v1, replace
}
if "`iciotable'"=="adb" {
	cap findfile adb_countrylist.csv, path(`".;`c(adopath)';`"`sysdir_plus'"'"') nodescend
		if _rc {
		// Download the file from http://www.tradeconomics.com/icio/data/adb
		qui insheet using "http://www.tradeconomics.com/icio/data/`iciotable'/adb_countrylist.csv", c clear
		if "`working_version'"=="1" {
			local path4save `"`c(adopath)'"'
			gettoken path4save butta: path4save, parse(";")
		}
		else {
			loc path4save `"`sysdir_plus'"'
		}
		loc path4save = regexr("`path4save'", "/$", "")
		qui outsheet using "`path4save'/adb_countrylist.csv", c nonames noquote
	}
	else {
		qui insheet using `"`r(fn)'"', c clear
	}
	qui levelsof v1, l(adb_countrylist) clean
	qui putmata _countryacr=v1 _areeacr=v1, replace
}
if "`iciotable'"=="user" {
	qui insheet using `"`s(icioclist_user)'"', c clear
	qui ds, has(type str#)
	loc wc: word count `r(varlist)'
	if `wc'> 2 {
		di as error "The country list file `s(icioclistname_user)' has more than 2 columns."
		exit 198
	}
    loc var1: word 1 of `r(varlist)'
	loc var2: word 2 of `r(varlist)'
	if "`var1'"!="" & "`var2'"=="" {
		qui levelsof `var1', l(user_countrylist) clean
		qui putmata _countryacr=`var1' _areeacr=`var1', replace
	}
	else if "`var1'"!="" & "`var2'"!="" {
		qui levelsof `var2', l(user_countrylist) clean
		qui putmata _countryacr=`var1' _areeacr=`var2', replace
	}
}
restore

if `user_defi_table'==0 {
	cap findfile `filename'`yy'.mmat , path(`".;`c(adopath)';`"`sysdir_plus'"'"') nodescend
	if _rc {
		noi di as result "Download `iciotable' `year' table..."
		if "`working_version'"=="1" {
			local path4save `"`c(adopath)'"'
			gettoken path4save butta: path4save, parse(";")
		}
		else {
			loc path4save `"`sysdir_plus'"'
		}
		loc path4save = regexr("`path4save'", "/$", "")
		copy "http://www.tradeconomics.com/icio/data/`iciotable'/`filename'`yy'.mmat.zip" "`path4save'/"
		loc getwd2reset "`c(pwd)'"
		qui cd "`path4save'"
		cap unzipfile "`filename'`yy'.mmat.zip"
		qui cd "`getwd2reset'"
		erase "`path4save'/`filename'`yy'.mmat.zip"
		//noi di as text "`iciotable' `year' table loaded."
		m __fh = fopen(`"`path4save'/`filename'`yy'.mmat"', "r")
		m io = fgetmatrix(__fh)
		m fclose(__fh)
		if "`c(os)'" != "MacOSX" cap rmdir "`path4save'/__MACOSX"

	}
	else {
		m __fh = fopen(`"`r(fn)'"', "r")
		m io = fgetmatrix(__fh)
		m fclose(__fh)
		//noi di as text "Loading table `iciotable' `year'...", _cont
	}
}
else if `user_defi_table'==1 {


/* check why _icio_insheet fails
the following fails because the eora file is too characters long.
The only solution is to interact with the OS
*/

/*
	! awk '{ print length($0); }' `s(iciotable_user)' > butta.txt

	capture noi mata: io = strtoreal(_icio_insheet(`"`s(iciotable_user)'"', ",",1,3))
	mata: rows(io),cols(io)


	if _rc == 0 noi di as result `"`s(iciotable_user)'"' as text " loaded"
	else {
		noi di as result `"`s(iciotable_user)'"' as error " not loaded"
		noi di as error "Check the path, the name and the format of the table."
		error 198
	}
	m _editmissing(io, 0)

*/

	preserve
	cap qui insheet using `"`s(iciotable_user)'"', c clear
	if _rc == 0 noi di as result `"Loading `s(iciotable_user)'..."', _cont
	else {
		noi di as result `"`s(iciotable_user)'"' as error " not loaded"
		noi di as error "Check the path, the name and the format of the table."
		error 198
	}

	qui ds
	loc allvars  "`r(varlist)'"
	m io = st_data(., st_local("allvars"))
	// check for missing vales and recode them = 0
	m _editmissing(io, 0)
	//m rows(io),cols(io)
	restore
}

// Fix parsing after the update on the possibility to use different versions of tiva and wiod
if inlist("`iciotable'", "wiodn", "wiodo") local iciotable "wiod"
if inlist("`iciotable'", "tivan", "tivao") local iciotable "tiva"

// This adds table release into the structure _in passing through the _icio_load() function
if inlist("`iciotable'", "tiva") local _trel "`tiva_rel'"
if inlist("`iciotable'", "wiod") local _trel "`wiod_rel'"
if inlist("`iciotable'", "eora") local _trel "`eora_rel'"
if inlist("`iciotable'", "adb") local _trel "`adb_rel'"

if "`iciotable'"!="user" {
	if inlist("`iciotable'", "wiod") local _countrylist "`wiod_`wiod_rel'_countrylist'"
	if inlist("`iciotable'", "tiva") local _countrylist "`tiva_`tiva_rel'_countrylist'"
	if inlist("`iciotable'", "eora") local _countrylist "`eora_countrylist'"
	if inlist("`iciotable'", "adb") local _countrylist "`adb_countrylist'"
}
else local _countrylist "`user_countrylist'"

if `user_defi_table'==0 di as text "Loading table `iciotable' `year'...", _cont
m _icio_in_ = _icio_load(io, _countryacr, "`iciotable'", "`_trel'", "`year'", "`_countrylist'", "`s(icioclist_user)'")
di in yel " loaded"
** get number of countries and sectors
m st_local("_icio_nr_countries", strofreal(_icio_in_.nr_pae))
m st_local("_icio_nr_sectors", strofreal(_icio_in_.nr_sett))

*** Info for Users
di in gr "For the available list of countries and sectors type{stata icio, info: icio, info}"
di in gr "For details about the {cmd:icio} syntax, help {help icio}"

loc mobjlist io __fh _areeacr _countryacr
foreach mo of local mobjlist {
	cap m mata drop `mo'
}

cap m mata drop _table_rels
cap m mata drop _tab_rels
cap m mata drop range_avail
cap matrix drop _tab_rels

end



/* ----------------------------------------------------------------- */

program define ParseICIOTable
	args returmac colon table

	local 0 ", `table'"
	syntax [, WIODO WIODN TIVAO TIVAN EORA ADB USER]

	local wc : word count `wiodo' `wiodn' `tivao' `tivan' `eora' `adb' `user'

	if `wc' > 1 {
		di as error "iciotable() invalid, only " /*
			*/ "one table type can be specified"
		exit 198
	}
	if `wc' == 0 {
		c_local `returmac' wiodn
	}
	else {
		if ("`wiodn'"=="wiodn") local iotable wiodn
		if ("`tivan'"=="tivan") local iotable tivan
		if ("`wiodo'"=="wiodo") local iotable wiodo
		if ("`tivao'"=="tivao") local iotable tivao
		if ("`eora'"=="eora") local iotable eora
		if ("`adb'"=="adb") local iotable adb
		if ("`user'"=="user") local iotable user
		c_local `returmac' `iotable'
	}

end


program define ParseICIOTableUser, sclass
	syntax, USERPath(string) TABLEName(string) COUNTRYListname(string)

	loc tablename = regexr("`tablename'",".csv$","")
	loc countrylistname = regexr("`countrylistname'",".csv$","")

	** check for double slash
	loc iciotable_user = subinstr(`"`userpath'/`tablename'.csv"',"//","/",.)
	loc icioclist_user = subinstr(`"`userpath'/`countrylistname'.csv"',"//","/",.)

	sreturn local iciotable `"`tablename'"'
	sreturn local iciotable_user `"`iciotable_user'"'
	sreturn local icioclist_user `"`icioclist_user'"'
	sreturn local icioclistname_user `"`countrylistname'.csv"'


end


/**** Versioning

* version 1.0.0  25mar2016 - First version
* version 1.0.1  10jun2017 - Country list loaded here now
* version 1.0.2  13sep2017 - User defined table can now be loaded
* version 1.1.0  23oct2017 - Country list is now endogenized and is loaded by the ado to parse the origin() destination() exporter() and importer() options
* version 1.1.1  4dec2018 - Fixed a bug preventing to load tables correctly
* version 1.1.2  23feb2019 - Fixed a bug preventing to load user-provided tables correctly
* version 1.2.0  1aug2019 - This version allows for two different releases of "wiod" and "tiva" and add "eora" as a new preloaded iotable in icio
* version 1.2.1  2aug2019 - Now _icio_load() has three arguments. this allows to transform eora in millions from the beginning
* version 1.2.2  10sep2019 - Fixed a bug preventing the download and load of the variuos vintages
* version 1.2.3  2oct2019 - Added -info- option and updated to work with tradeconomics.com
* version 1.2.4  27may2020 - Added ADB tables
* version 1.2.5 13nov2020 - Added links to help and -icio, info- after -icio_load-.
* version 1.2.6 10mar2021 - Now also eora and adb tables have the official release date/code in the name of each table
* version 1.3.0 7jan2022 - This is a huge update. It allows to update tables and their releases without the need of updating also the distributed ado files. It exploits the icio_releases.csv file
