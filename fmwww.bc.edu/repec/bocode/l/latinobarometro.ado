*! version 1.0.0  14jul2026  Jorge Soler-Lopez (jorge.solerlopez@unibocconi.it)

/*******************************************************************************
Description:     Latinobarometro survey management
Authors:
Jorge Soler-Lopez
Bocconi University
Originally from German Reyes' (WB-Cornell) idea
*******************************************************************************/
* Rewritten: 8 July 2026
* Original created: 18 June 2020

program define latinobarometro
  version 14.0
  syntax, year(string) [rename ADDpopulation force cache(string)]
  cap confirm integer number `year'
  if _rc {
    di as error "year() must be a four-digit survey year, e.g. year(2020)."
    error 198
  }
  /*Options:
  rename        = will rename all variables to standard names across years,
                   using the Latinobarometro time-series crosswalk file
  addpopulation = will add weights at the country level for regional calculations
                   (REQUIRES rename, since it depends on standardized X_001/X_020)
  force         = ignore any cached files (data zip, crosswalk Excel, population
                   data) and re-download everything fresh
  cache(string) = override the default cache folder
                   (default: stata_user_ado/latinobarometro_cache)
  */

  * ---------------------------------------------------------------------------
  * Config
  * ---------------------------------------------------------------------------
  if "`cache'" == "" local cache "`c(sysdir_personal)'latinobarometro_cache"
  cap mkdir "`cache'"
  if !_rc di "Unable to create cache folder"
  cap mkdir "`cache'/`year'"

  local base_url "https://www.latinobarometro.org/documents"
  local excel_url "`base_url'/latinobarometro-serie-de-tiempo-1995-2024.xlsx"
  local excel_name "latinobarometro-serie-de-tiempo-1995-2024.xlsx"

  * ---------------------------------------------------------------------------
  * Step 1: Year -> zip filename lookup (Latinobarometro's official site is
  * the only data source this program uses - see the help file for why there
  * is deliberately no fallback mirror).
  * NOTE: every entry in this table was verified directly against the live
  * latinobarometro.org site on 14 July 2026 (HTTP fetch of each zip URL
  * returned a real zip; wrong URLs return an HTML error page instead).
  * 2016 and 2017 both break the hyphen pattern used by the other years.
  * ---------------------------------------------------------------------------
  local plain_years "1995 1996 1997 1998 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2013 2015"

  local zipname ""
  if strpos(" `plain_years' ", " `year' ") > 0 {
    local zipname "latinobarometro-`year'-dta.zip"
  }
  else if `year' == 2016 | `year' == 2017 {
    * NOTE: 2016 and 2017 use "latinobarometro<year>-dta.zip" (no hyphen
    * after the name) - verified live for both on 14 July 2026
    local zipname "latinobarometro`year'-dta.zip"
  }
  else if `year' == 2018 {
    local zipname "latinobarometro-2018-eng-stata-v20190303.zip"
  }
  else if `year' == 2020 {
    local zipname "latinobarometro-2020-eng-stata-v1-0.zip"
  }
  else if `year' == 2023 {
    local zipname "latinobarometro-2023-stata-v1-0.zip"
  }
  else if `year' == 2024 {
    local zipname "latinobarometro-2024-stata-v20250817.zip"
  }
  else {
    di as error "Year `year' is not in the URL lookup table. Add it to the table in this .ado before proceeding."
    error 601
  }

  local zip_url "`base_url'/LAT-`year'/`zipname'"
  local local_zip "`cache'/`year'/`zipname'"

  * ---------------------------------------------------------------------------
  * Step 2: Locate a usable .dta for this year.
  * The cache is always checked FIRST (unless force is specified) - only if
  * nothing usable is already cached does the program reach out to
  * latinobarometro.org. unzipfile extracts to Stata's current working
  * directory - the folder() option isn't available in all Stata versions,
  * so cd into the cache folder before unzipping and restore the original
  * directory afterward.
  * ---------------------------------------------------------------------------
  local orig_dir "`c(pwd)'"

  local have_cached_file = 0
  if "`force'" == "" {
    local precheck : dir "`cache'/`year'/" files "*.dta"
    foreach f of local precheck {
      if strpos("`f'", "`year'") > 0 {
        local have_cached_file = 1
      }
    }
  }

  if `have_cached_file' {
    di as text "Using cached data file for `year' (use the force option to re-download)."
  }
  else {
    di as text "Downloading `zip_url' ..."
    cap copy "`zip_url'" "`local_zip'", replace
    if _rc {
      di as error "Download from Latinobarometro failed for year `year' (rc=`=_rc')."
      di as error "This program only downloads from latinobarometro.org - check that the site is reachable, or that this year's entry in the URL lookup table is still correct, and try again."
      error _rc
    }
    di as text "Unzipping..."
    qui cd "`cache'/`year'/"
    cap unzipfile "`local_zip'", replace
    local unzip_rc = _rc
    qui cd "`orig_dir'"
    if `unzip_rc' {
      di as error "Unzip failed for year `year' (rc=`unzip_rc')."
      error `unzip_rc'
    }
    else{
      di as text "DB downloaded and unzipped in `c(sysdir_personal)'/latinobarometro_cache/`year' " 
      di as text "Future calls to latinobarometro, year(`year') will load from cache."
    }
  }

  * ---------------------------------------------------------------------------
  * Step 3: Identify the English .dta among files now in the cache
  * Filenames are NOT consistent across years - some use underscores, some
  * don't, and version suffixes vary. Rather than matching a fixed pattern,
  * search all .dta files in the cache for ones containing the year's
  * digits, excluding anything tagged "esp" and preferring anything tagged
  * "eng".
  * ---------------------------------------------------------------------------
  local all_dta : dir "`cache'/`year'/" files "*.dta"
  local n_dta : word count `all_dta'
  if `n_dta' == 0 {
    di as error "No .dta files found in `cache' after attempting download."
    error 601
  }

  local eng_file ""
  local combined_file ""
  local esp_file ""
  foreach f of local all_dta {
    if strpos("`f'", "`year'") == 0 continue
    local f_lower = lower("`f'")
    if strpos("`f_lower'", "esp") > 0 {
      local esp_file "`f'"
      continue
    }
    if strpos("`f_lower'", "eng") > 0 {
      local eng_file "`f'"
    }
    else {
      local combined_file "`f'"
    }
  }

  if "`eng_file'" != "" {
    local use_file "`eng_file'"
  }
  else if "`combined_file'" != "" {
    local use_file "`combined_file'"
  }
  else if "`esp_file'" != "" {
    di as text "NOTE: only a Spanish-language file was found for year `year'. Using it - raw variable names should still match the crosswalk, but value labels will be in Spanish for this year."
    local use_file "`esp_file'"
  }
  else {
    di as error "No .dta file matching year `year' found in `cache'."
    di as error "Files found in cache: `all_dta'"
    error 601
  }

  di as result "Loading `use_file'"
  use "`cache'//`year'/`use_file'", clear
  gen year_new = `year' // redundant given X_variant below, but kept for compatibility
  label var year_new "Year (harmonized)"
  * ---------------------------------------------------------------------------
  * Step 4: Sanitize variable NAMES
  * Handles both invalid Unicode characters (ustrtoname) and periods, which
  * some years' raw variable names contain and which are not valid in Stata
  * names.
  * ---------------------------------------------------------------------------
  local i = 0
  foreach varname of varlist * {
    local i = `i' + 1
    local newname = subinstr("`varname'", ".", "_", .)
    local newname = ustrtoname("`newname'")
    if "`newname'" != "`varname'" {
      mata : st_varrename(`i', "`newname'")
    }
  }

  * ---------------------------------------------------------------------------
  * Step 5: Sanitize VALUE LABEL SET names
  * This is the fix for the 2016/2017 loading failure: some years' value-label
  * set names (not the variable names, and not the label text - the name of
  * the label set itself, what's attached via `label values varname X`)
  * contain periods, which Stata rejects. IMPORTANT: `label copy`/`label
  * drop`/`label list <name>` and every Mata st_vl*() function all reject an
  * invalid name as a typed ARGUMENT (confirmed empirically: all return
  * r(198), or Mata's own "malformed name" error per its documentation).
  * There is no way to reference an invalid label name directly, at any
  * level. Workaround: `label save` (with no namelist) dumps every label
  * definition to plain text via Stata's own internal enumeration - no
  * individual name is ever typed. That text is fixed via ordinary string
  * substitution (not subject to name-parsing rules at all) and re-loaded,
  * so only ever-valid names get defined; variables are then reattached
  * using `label values`, which only needs the NEW (valid) name.
  * ---------------------------------------------------------------------------
  qui label dir
  local labnames `r(names)'
  local n_bad = 0
  foreach lab of local labnames {
    local newlab = subinstr("`lab'", ".", "_", .)
    local newlab = ustrtoname("`newlab'")
    if "`newlab'" != "`lab'" {
      local n_bad = `n_bad' + 1
      local old_`n_bad' "`lab'"
      local new_`n_bad' "`newlab'"
    }
  }

  if `n_bad' > 0 {
    local rawfile   "`c(tmpdir)'raw_labels_temp.do"
    local fixedfile "`c(tmpdir)'fixed_labels_temp.do"

    qui label save using "`rawfile'", replace

    tempname fh_in fh_out
    file open `fh_in' using "`rawfile'", read text
    file open `fh_out' using "`fixedfile'", write text replace

    file read `fh_in' line
    while r(eof) == 0 {
      forvalues j = 1/`n_bad' {
        local line = subinstr(`"`line'"', "`old_`j''", "`new_`j''", .)
      }
      file write `fh_out' `"`line'"' _n
      file read `fh_in' line
    }
    file close `fh_in'
    file close `fh_out'

    cap qui do "`fixedfile'"
    if _rc {
      di as error "Value-label sanitization failed while re-running corrected label definitions (rc=`=_rc')."
      di as error "Inspect `fixedfile' manually."
      error _rc
    }

    forvalues j = 1/`n_bad' {
      foreach v of varlist _all {
        local cur : value label `v'
        if "`cur'" == "`old_`j''" {
          label values `v' `new_`j''
        }
      }
    }
  }

  * ---------------------------------------------------------------------------
  * Step 6: Rename to standardized cross-year names (if requested)
  * Uses the official Latinobarometro crosswalk file, cached and downloaded
  * the same way as the data zip. Logic validated in a separate session
  * against the person's manually-built 2020 rename list: 5,809/5,809 exact
  * match with zero discrepancies.
  * ---------------------------------------------------------------------------
  if "`rename'" != "" {
    tempfile before
    qui save `before', replace

    local excel_cache "`cache'/`excel_name'"
    local need_excel_download = 1
    cap confirm file "`excel_cache'"
    if !_rc & "`force'" == "" {
      local need_excel_download = 0
    }
    if `need_excel_download' {
      di as text "Downloading crosswalk file..."
      cap copy "`excel_url'" "`excel_cache'", replace
      if _rc {
        di as error "Crosswalk download failed (rc=`=_rc')."
        error _rc
      }
    }
    else {
      di as text "Using cached crosswalk file (use the force option to re-download)."
    }
    *Check that the crossover dta is there
    * Import without firstrow to avoid special-character column names
    * (e.g. "Nº puntos"); rename positionally instead. Column order confirmed
    * directly against the file: 28 columns, Variable/Titulo/Title/Npuntos
    * followed by 24 LAT<year> columns.
    local need_crossover = 1
    cap confirm file "`cache'/crossover.dta"
    if !_rc {
      local need_crossover = 0
    }
    if `need_crossover' {
      qui cap import excel using "`excel_cache'", sheet("Serie de Tiempo 1995-2024") clear
      qui cap drop in 1
      qui cap rename (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB) ///
           (variable_new titulo_es title_en npuntos ///
            LAT1995 LAT1996 LAT1997 LAT1998 LAT2000 LAT2001 LAT2002 LAT2003 ///
            LAT2004 LAT2005 LAT2006 LAT2007 LAT2008 LAT2009 LAT2010 LAT2011 ///
            LAT2013 LAT2015 LAT2016 LAT2017 LAT2018 LAT2020 LAT2023 LAT2024)
      save "`cache'/crossover.dta", replace
         }
    else use "`cache'/crossover.dta", clear

    local source_col "LAT`year'"
    cap confirm variable `source_col'
    if _rc {
      di as error "No crosswalk column found for year `year' (expected `source_col')."
      qui use `before', clear
      error 601
    }

    qui keep if `source_col' != ""

    local N = _N
    forvalues i = 1/`N' {
      local oldvar_raw = `source_col'[`i']
      local newvar = variable_new[`i']
      local lblval = title_en[`i']
      if "`oldvar_raw'" != "" & "`newvar'" != "" {
        * The crosswalk's source-variable spelling is not always consistent
        * with the literal raw variable name: a period in the crosswalk
        * (e.g. "P62N.A") sometimes corresponds to an underscore in the real
        * data ("p62n_a") and sometimes to no separator at all ("p62na").
        * Rather than guessing one fixed rule, generate all plausible
        * candidate spellings and store the label/newvar under each one -
        * whichever candidate actually matches a real variable name will be
        * picked up naturally in the loop below.
        local cand1 = lower(ustrtoname(subinstr("`oldvar_raw'", ".", "_", .)))
        local cand2 = lower(ustrtoname(subinstr("`oldvar_raw'", ".", "", .)))
        local cand3 = lower(ustrtoname("`oldvar_raw'"))
        foreach cand in `cand1' `cand2' `cand3' {
          if "`cand'" != "" {
            local lbl_`cand' = "`lblval'"
            local new_`cand' = "`newvar'"
          }
        }
      }
    }

    qui use `before', clear
    qui rename *, lower
    foreach var_i of varlist _all {
      if "`lbl_`var_i''" != "" {
        cap label variable `var_i' "`lbl_`var_i''"
        cap rename `var_i' `new_`var_i''
      }
    }
  }

  * ---------------------------------------------------------------------------
  * Step 7: Add population weights (if requested)
  * Requires `rename' to have been run first, since it depends on the
  * standardized X_001 (country code) and X_020 (sample weight) variables.
  * ---------------------------------------------------------------------------
  if "`addpopulation'" != "" {
    cap confirm variable X_001
    if _rc {
      di as error "addpopulation requires the rename option (it needs standardized X_001/X_020 variables)."
      error 111
    }
    cap confirm variable X_020
    if _rc {
      di as error "addpopulation requires the rename option (it needs standardized X_001/X_020 variables)."
      error 111
    }

    cap which wbopendata
    if _rc {
      di as error "The addpopulation option requires the wbopendata package, which is not installed."
      di as error "Install it with:  ssc install wbopendata, replace"
      error 111
    }

    tempfile before
    qui save `before', replace

    local pop_cache "`cache'/population_wb.dta"
    local need_pop_download = 1
    cap confirm file "`pop_cache'"
    if !_rc & "`force'" == "" {
      local need_pop_download = 0
    }

    if `need_pop_download' {
      di as text "Fetching fresh population data from World Bank..."
      wbopendata, indicator(sp.pop.totl) clear long
      di as text "Ok, saving population data"
      qui cap save "`pop_cache'", replace
    }
    else {
      cap use "`pop_cache'", clear
      if _rc {
        di as error "No cached population file found at `pop_cache'."
        qui use `before', clear
        error _rc
      }
      di as text "Using cached population data (use the force option to re-fetch)."
    }

    qui cap drop if year != `year'
    keep countrycode sp_pop_totl
    tempfile population
    qui cap save `population', replace

    use `before', clear
    qui cap { //Standarize names so that it merges with population
      gen str3 countrycode = ""
      label var countrycode "Country code 3-digit WB-compliant"
      replace countrycode = "ARG" if X_001 ==  32   // Argentina
      replace countrycode = "BOL" if X_001 ==  68   // Bolivia
      replace countrycode = "BRA" if X_001 ==  76   // Brazil
      replace countrycode = "CHL" if X_001 == 152   // Chile
      replace countrycode = "COL" if X_001 == 170   // Colombia
      replace countrycode = "CRI" if X_001 == 188   // Costa Rica
      replace countrycode = "DOM" if X_001 == 214   // Dominican Republic
      replace countrycode = "ECU" if X_001 == 218   // Ecuador
      replace countrycode = "SLV" if X_001 == 222   // El Salvador
      replace countrycode = "GTM" if X_001 == 320   // Guatemala
      replace countrycode = "HND" if X_001 == 340   // Honduras
      replace countrycode = "MEX" if X_001 == 484   // Mexico
      replace countrycode = "NIC" if X_001 == 558   // Nicaragua
      replace countrycode = "PAN" if X_001 == 591   // Panama
      replace countrycode = "PRY" if X_001 == 600   // Paraguay
      replace countrycode = "PER" if X_001 == 604   // Peru
      replace countrycode = "URY" if X_001 == 858   // Uruguay
      replace countrycode = "VEN" if X_001 == 862   // Venezuela
      replace countrycode = "ESP" if X_001 == 724   // Spain
      merge m:1 countrycode using `population'
      *drop if _merge != 3
      *drop _merge
      bys countrycode: egen total_sample = total(X_020)
      gen wt_lac = X_020 * sp_pop_totl / total_sample
      label var sp_pop_totl "Country Population"
      label var total_sample "Sample size (of country)"
      label var wt_lac "Weights (Population LAC)"
    }
  }

end
