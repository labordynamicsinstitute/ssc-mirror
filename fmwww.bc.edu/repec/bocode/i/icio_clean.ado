
*! version 1.1.0  7jan2022
*! author: Federico Belotti, Michele Mancini and Alessandro Borin
*! see end of file for version comments

program define icio_clean, sclass
    syntax

	version 11

	*** This is for us: Set this to 0 for distributed version
	loc working_version 0

	*** Get the right sysdir
	loc sysdir_plus `"`c(sysdir_plus)'i/"'

	local files2be_deleted: dir "`c(sysdir_plus)'/i" files "icio_*.mmat", nofail respectcase

	di in gr "Cleaning ..."

	local tot_tf = 0
	foreach f of local files2be_deleted {
		cap erase "`c(sysdir_plus)'/i/`f'"
		local tot_tf = `tot_tf' + 1
	}

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
			m _table_rels[`j'] = "`: di table[`i']'"
			m _tab_rels[`j',.] = (`: di rel[`i']', `: di syear[`i']', `: di eyear[`i']')
			loc j = `j'+1
		}
	}
	restore

	local tot_aux = 0
	foreach tt in tivao wiodo tivan wiodn {
		m year_to_be_checked = select(_tab_rels, _table_rels:=="`tt'")
		m st_local("y2bechck", strofreal(year_to_be_checked[1,1]))
		if regexm("`tt'", "tiva") {
			cap erase "`c(sysdir_plus)'/i/tiva_`y2bechck'_countrylist.csv"
			if _rc==0 local tot_aux = `tot_aux' + 1
			cap erase "`c(sysdir_plus)'/i/tiva_`y2bechck'_sectorlist.csv"
			if _rc==0 local tot_aux = `tot_aux' + 1
		}
		if regexm("`tt'", "wiod") {
			cap erase "`c(sysdir_plus)'/i/wiod_`y2bechck'_countrylist.csv"
			if _rc==0 local tot_aux = `tot_aux' + 1
			cap erase "`c(sysdir_plus)'/i/wiod_`y2bechck'_sectorlist.csv"
			if _rc==0 local tot_aux = `tot_aux' + 1
		}
	}

	cap erase "`c(sysdir_plus)'/i/eora_countrylist.csv"
	if _rc==0 local tot_aux = `tot_aux' + 1
	cap erase "`c(sysdir_plus)'/i/adb_countrylist.csv"
	if _rc==0 local tot_aux = `tot_aux' + 1
	cap erase "`c(sysdir_plus)'/i/eora_sectorlist.csv"
	if _rc==0 local tot_aux = `tot_aux' + 1
	cap erase "`c(sysdir_plus)'/i/adb_sectorlist.csv"
	if _rc==0 local tot_aux = `tot_aux' + 1
	cap erase "`c(sysdir_plus)'/i/icio_releases.csv"
	if _rc==0 local tot_aux = `tot_aux' + 1

	di in yel " `tot_tf'" in gr " icio tables deleted"
	di in yel " `tot_aux'" in gr " icio ancillary files deleted"

end




exit




* version 1.0.1  9mar2021 - First release. -icio_clean- cleans system directories from previously downloaded icio tables and ancillary files
* version 1.1.0  7jan2022 - Following the huge update in -icio_load-, this version allows to clean previously downloaded icio tables and ancillary files, even after any update in the available tables and their releases, without the need of updating the distributed ado files. It also exploits the icio_releases.csv file
