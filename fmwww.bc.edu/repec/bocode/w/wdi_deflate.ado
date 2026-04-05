*! wdi_deflate v2.7.0  2026-04-03
*! Convert monetary values across PPP, USD, and LCU using WDI deflators
*! Uses WDI: PA.NUS.PRVT.PP (PPP), FP.CPI.TOTL (CPI), PA.NUS.FCRF (XR)
*!
*! Author: Kalle Hirvonen, IFPRI (k.hirvonen@cgiar.org)

capture program drop wdi_deflate
program define wdi_deflate
    version 15

    * Parse subcommand
    gettoken subcmd rest : 0, parse(" ,")

    if "`subcmd'" == "build" {
        _wdi_deflate_build `rest'
    }
    else if "`subcmd'" == "describe" {
        _wdi_deflate_describe `rest'
    }
    else {
        * Default: treat as convert (first token is varlist)
        _wdi_deflate_convert `0'
    }
end

* =============================================================================
* BUILD subcommand: download PPP + CPI + XR from WDI and save deflator dataset
* =============================================================================
capture program drop _wdi_deflate_build
program define _wdi_deflate_build
    version 15
    syntax , SAVing(string) [Replace GDP SNAPshot(string) COUNTries(string)]

    * -----------------------------------------------------------------------
    * Check for wbopendata
    * -----------------------------------------------------------------------
    cap which wbopendata
    if _rc {
        di as error "wbopendata is required but not installed."
        di as error "Install with: {stata ssc install wbopendata}"
        exit 199
    }
    cap which tknz
    if _rc {
        di as error "tknz is required by wbopendata but not installed."
        di as error "Install with: {stata ssc install tknz}"
        exit 199
    }

    if `"`snapshot'"' != "" {
        cap mkdir `"`snapshot'"'
    }

    * -----------------------------------------------------------------------
    * Country filter: convert space-separated ISO3 to semicolon-separated
    * -----------------------------------------------------------------------
    if `"`countries'"' != "" {
        local cc_wb : subinstr local countries " " ";", all
        local wb_country `"country(`cc_wb')"'
        local cc_label `"`countries'"'
    }
    else {
        local wb_country ""
        local cc_label "ALL"
    }

    * Determine PPP indicator
    if "`gdp'" != "" {
        local ppp_ind "PA.NUS.PPP"
        local ppp_var "pa_nus_ppp"
        local ppp_lab "PPP conversion factor, GDP"
    }
    else {
        local ppp_ind "PA.NUS.PRVT.PP"
        local ppp_var "pa_nus_prvt_pp"
        local ppp_lab "PPP conversion factor, private consumption"
    }

    preserve

    * -------------------------------------------------------------------
    * Download PPP conversion factor
    * -------------------------------------------------------------------
    di as text ""
    di as text "{hline 60}"
    di as text "Downloading `ppp_lab'..."
    di as text "  Indicator: `ppp_ind'"
    di as text "{hline 60}"

    cap noisily wbopendata, indicator(`ppp_ind') `wb_country' long clear
    if _rc {
        di as error ""
        di as error "Failed to download `ppp_lab' from the World Bank API."
        di as error "The API may be temporarily unavailable."
        di as error "If you have a previously built deflator file, use the"
        di as error "using() option to avoid downloading:"
        di as error "  wdi_deflate varlist, country() from() to() using(deflator.dta)"
        restore
        exit 2
    }
    cap confirm variable `ppp_var'
    if _rc {
        di as error "Expected variable `ppp_var' not found after wbopendata download."
        di as error "wbopendata may have changed its variable naming."
        di as error "Try updating: {stata ssc install wbopendata, replace}"
        restore
        exit 111
    }
    qui keep countrycode countryname year `ppp_var'
    qui ren `ppp_var' ppp_factor
    qui drop if missing(ppp_factor)
    qui destring year, replace force
    qui drop if missing(year)

    tempfile ppp_data
    qui save `ppp_data'
    if `"`snapshot'"' != "" {
        qui save `"`snapshot'/ppp_factor.dta"', replace
    }

    local ppp_N = _N
    qui tab countrycode
    local ppp_countries = r(r)

    * -------------------------------------------------------------------
    * Download CPI
    * -------------------------------------------------------------------
    di as text ""
    di as text "{hline 60}"
    di as text "Downloading CPI (FP.CPI.TOTL)..."
    di as text "{hline 60}"

    cap noisily wbopendata, indicator(FP.CPI.TOTL) `wb_country' long clear
    if _rc {
        di as error ""
        di as error "Failed to download CPI from the World Bank API."
        di as error "The API may be temporarily unavailable."
        di as error "If you have a previously built deflator file, use the"
        di as error "using() option to avoid downloading."
        restore
        exit 2
    }
    cap confirm variable fp_cpi_totl
    if _rc {
        di as error "Expected variable fp_cpi_totl not found after wbopendata download."
        di as error "wbopendata may have changed its variable naming."
        di as error "Try updating: {stata ssc install wbopendata, replace}"
        restore
        exit 111
    }
    qui keep countrycode countryname year fp_cpi_totl
    qui ren fp_cpi_totl cpi
    qui drop if missing(cpi)
    qui destring year, replace force
    qui drop if missing(year)

    local cpi_N = _N
    qui tab countrycode
    local cpi_countries = r(r)

    tempfile cpi_data
    qui save `cpi_data'
    if `"`snapshot'"' != "" {
        qui save `"`snapshot'/cpi.dta"', replace
    }

    * -------------------------------------------------------------------
    * Download official exchange rate
    * -------------------------------------------------------------------
    di as text ""
    di as text "{hline 60}"
    di as text "Downloading exchange rate (PA.NUS.FCRF)..."
    di as text "{hline 60}"

    cap noisily wbopendata, indicator(PA.NUS.FCRF) `wb_country' long clear
    if _rc {
        di as error ""
        di as error "Failed to download exchange rate from the World Bank API."
        di as error "The API may be temporarily unavailable."
        di as error "If you have a previously built deflator file, use the"
        di as error "using() option to avoid downloading."
        restore
        exit 2
    }
    cap confirm variable pa_nus_fcrf
    if _rc {
        di as error "Expected variable pa_nus_fcrf not found after wbopendata download."
        di as error "wbopendata may have changed its variable naming."
        di as error "Try updating: {stata ssc install wbopendata, replace}"
        restore
        exit 111
    }
    qui keep countrycode year pa_nus_fcrf
    qui ren pa_nus_fcrf xr
    qui drop if missing(xr)
    qui destring year, replace force
    qui drop if missing(year)

    local xr_N = _N
    qui tab countrycode
    local xr_countries = r(r)
    if `"`snapshot'"' != "" {
        qui save `"`snapshot'/xr.dta"', replace
    }

    * -------------------------------------------------------------------
    * Merge all three
    * -------------------------------------------------------------------
    di as text ""
    di as text "Merging datasets..."

    qui merge 1:1 countrycode year using `cpi_data', nogen
    qui merge 1:1 countrycode year using `ppp_data', nogen
    qui sort countrycode year

    * Label
    label variable countrycode "ISO3 country code"
    label variable countryname "Country name"
    label variable year "Year"
    label variable ppp_factor "`ppp_lab' (LCU per intl $)"
    label variable cpi "Consumer price index (2010 = 100)"
    label variable xr "Official exchange rate (LCU per US$, period avg)"

    qui compress
    local final_N = _N
    qui tab countrycode
    local final_countries = r(r)
    qui sum year
    local yr_min = r(min)
    local yr_max = r(max)

    label data "WDI PPP + CPI + XR deflator data (built `c(current_date)')"
    note: Built by wdi_deflate build on `c(current_date)' at `c(current_time)'
    note: PPP indicator: `ppp_ind' (`ppp_lab')
    note: CPI indicator: FP.CPI.TOTL
    note: XR indicator: PA.NUS.FCRF (official exchange rate)

    char _dta[wdi_deflate_build_date] "`c(current_date)'"
    char _dta[wdi_deflate_countries] "`cc_label'"
    datasignature set

    qui save `"`saving'"', `replace'

    restore

    * -------------------------------------------------------------------
    * Report
    * -------------------------------------------------------------------
    di as text ""
    di as text "{hline 60}"
    di as result "Deflator dataset saved: `saving'"
    di as text "{hline 60}"
    di as text "  PPP: `ppp_N' obs across `ppp_countries' countries"
    di as text "  CPI: `cpi_N' obs across `cpi_countries' countries"
    di as text "  XR:  `xr_N' obs across `xr_countries' countries"
    di as text "  Merged: `final_N' obs, `final_countries' countries"
    di as text "  Years: `yr_min' - `yr_max'"
    if "`cc_label'" != "ALL" {
        di as text "  Countries filter: `cc_label'"
    }
    if `"`snapshot'"' != "" {
        di as text "  Snapshot:  `snapshot'/"
    }
    di as text "{hline 60}"
end


* =============================================================================
* DESCRIBE subcommand: summarize contents of a deflator dataset
* =============================================================================
capture program drop _wdi_deflate_describe
program define _wdi_deflate_describe
    version 15
    syntax , USing(string)

    confirm file `"`using'"'

    preserve
    qui use `"`using'"', clear

    di as text ""
    di as text "{hline 60}"
    di as result "Deflator dataset: `using'"
    di as text "{hline 60}"

    qui sum year
    di as text "  Years:     `r(min)' - `r(max)'"

    qui tab countrycode
    di as text "  Countries: `r(r)'"

    di as text ""
    di as text "  Coverage for common reference years:"
    foreach y in 2005 2011 2017 2021 {
        qui count if year == `y' & !missing(ppp_factor) & !missing(cpi)
        local n_ppp = r(N)
        cap confirm variable xr
        if !_rc {
            qui count if year == `y' & !missing(xr) & !missing(cpi)
            local n_xr = r(N)
            di as text "    `y': `n_ppp' (PPP+CPI), `n_xr' (XR+CPI)"
        }
        else {
            di as text "    `y': `n_ppp' countries with PPP + CPI"
        }
    }

    * Show a few example countries
    di as text ""
    di as text "  Sample (ETH, TZA, USA):"
    cap confirm variable xr
    if !_rc {
        list countrycode year ppp_factor xr cpi if ///
            inlist(countrycode, "ETH", "TZA", "USA") & ///
            inlist(year, 2011, 2017, 2021), ///
            sep(3) noobs abbreviate(12)
    }
    else {
        list countrycode year ppp_factor cpi if ///
            inlist(countrycode, "ETH", "TZA", "USA") & ///
            inlist(year, 2011, 2017, 2021), ///
            sep(3) noobs abbreviate(12)
    }

    restore
end


* =============================================================================
* CONVERT: merge deflator and compute converted values
* =============================================================================
capture program drop _wdi_deflate_convert
program define _wdi_deflate_convert, rclass
    version 15
    syntax varlist(numeric) [if] [in], COUNTry(varname string) ///
        FROM(string) TO(integer) ///
        [USing(string) SUFfix(string) Replace Quiet USD DEFlate FROMppp FROMusd GDP]

    marksample touse
    markout `touse' `country', strok

    * -----------------------------------------------------------------------
    * Validate options
    * -----------------------------------------------------------------------
    if "`usd'" != "" & "`deflate'" != "" {
        di as error "Cannot specify both usd and deflate"
        exit 198
    }
    if "`fromppp'" != "" & "`fromusd'" != "" {
        di as error "Cannot specify both fromppp and fromusd"
        exit 198
    }
    * fromppp + usd is blocked: PPP->USD would require PPP->LCU->CPI adjust->XR,
    * which is a conceivable path but not currently implemented.
    if "`fromppp'" != "" & "`usd'" != "" {
        di as error "fromppp cannot be combined with usd"
        exit 198
    }
    if "`fromusd'" != "" & "`usd'" == "" & "`deflate'" == "" {
        di as error "fromusd requires the usd or deflate option"
        exit 198
    }
    if "`suffix'" != "" & "`replace'" != "" {
        di as error "Cannot specify both suffix() and replace"
        exit 198
    }

    * Determine conversion mode
    if "`usd'" != "" {
        local mode "usd"
        local mode_lab "nominal USD"
        local default_suffix "_usd`to'"
    }
    else if "`deflate'" != "" {
        local mode "deflate"
        local mode_lab "constant `to' LCU"
        local default_suffix "_real`to'"
    }
    else {
        local mode "ppp"
        local mode_lab "PPP intl $"
        local default_suffix "_ppp`to'"
    }

    if "`suffix'" == "" & "`replace'" == "" {
        local suffix "`default_suffix'"
    }

    * Auto-download WDI data when using() is omitted
    if `"`using'"' == "" {
        * Extract unique country codes from user data for fast download
        qui levelsof `country' if `touse', local(cc_list) clean
        tempfile __wdi_auto
        _wdi_deflate_build, saving(`"`__wdi_auto'"') `gdp' countries(`cc_list')
        local using "`__wdi_auto'"
    }
    else if "`gdp'" != "" {
        di as text "(note: gdp option ignored when using() is specified)"
    }

    confirm file `"`using'"'

    * -----------------------------------------------------------------------
    * Parse from(): integer scalar or numeric variable
    * -----------------------------------------------------------------------
    cap confirm integer number `from'
    if !_rc {
        local from_type "scalar"
        local from_val `from'
    }
    else {
        cap confirm numeric variable `from'
        if _rc {
            di as error "from(`from'): must be an integer or numeric variable"
            exit 198
        }
        local from_type "variable"
    }

    * -----------------------------------------------------------------------
    * Preserve sort order
    * -----------------------------------------------------------------------
    tempvar sortorder
    gen long `sortorder' = _n

    * -----------------------------------------------------------------------
    * Create merge keys with safe names
    * -----------------------------------------------------------------------
    * Drop each internal variable individually — a single cap drop with
    * multiple variables fails entirely if ANY variable is absent, which
    * silently leaves stale values from a prior wdi_deflate call.
    cap drop __ppp_*

    * Country key (ISO3) — warn if codes are not 3 characters
    qui gen str3 __ppp_cc = trim(`country')
    qui count if length(trim(`country')) != 3 & `touse'
    if r(N) > 0 {
        di as error "Warning: `r(N)' obs in `country' are not 3-character ISO3 codes (truncated or short)."
        di as error "Ensure `country' contains ISO 3166-1 alpha-3 codes (e.g. ETH, TZA)."
    }

    * Source year key
    if "`from_type'" == "scalar" {
        qui gen int __ppp_yr = `from_val'
    }
    else {
        qui gen int __ppp_yr = `from'
    }

    * -----------------------------------------------------------------------
    * Step 1: Merge source-year CPI (+ PPP if fromppp, + XR if fromusd)
    * -----------------------------------------------------------------------
    tempfile src_lookup tgt_lookup

    preserve
    qui use `"`using'"', clear
    local deflator_date : char _dta[wdi_deflate_build_date]
    local deflator_countries : char _dta[wdi_deflate_countries]
    local deflator_sig  : char _dta[_datasignature]
    if "`deflator_sig'" != "" {
        cap datasignature confirm
        local deflator_modified = _rc
    }
    else {
        local deflator_modified = 0
    }
    if "`fromppp'" != "" {
        qui keep countrycode year cpi ppp_factor
        qui drop if missing(cpi) | missing(ppp_factor)
    }
    else if "`fromusd'" != "" {
        qui keep countrycode year cpi xr
        qui drop if missing(cpi) | missing(xr)
    }
    else {
        qui keep countrycode year cpi
        qui drop if missing(cpi)
    }
    qui ren countrycode __ppp_cc
    qui ren year __ppp_yr
    qui ren cpi __ppp_src_cpi
    if "`fromppp'" != "" {
        qui ren ppp_factor __ppp_src_ppp
    }
    if "`fromusd'" != "" {
        qui ren xr __ppp_src_xr
    }
    qui sort __ppp_cc __ppp_yr
    qui save `src_lookup'
    restore

    qui sort __ppp_cc __ppp_yr
    if "`fromppp'" != "" {
        qui merge m:1 __ppp_cc __ppp_yr using `src_lookup', ///
            keep(master match) nogen keepusing(__ppp_src_cpi __ppp_src_ppp)
    }
    else if "`fromusd'" != "" {
        qui merge m:1 __ppp_cc __ppp_yr using `src_lookup', ///
            keep(master match) nogen keepusing(__ppp_src_cpi __ppp_src_xr)
    }
    else {
        qui merge m:1 __ppp_cc __ppp_yr using `src_lookup', ///
            keep(master match) nogen keepusing(__ppp_src_cpi)
    }

    * -----------------------------------------------------------------------
    * Step 2: Merge target-year CPI + divisor (PPP, XR, or CPI only)
    * -----------------------------------------------------------------------
    preserve
    qui use `"`using'"' if year == `to', clear

    qui count
    if r(N) == 0 {
        di as error "Target year `to' not found in deflator dataset."
        di as error "Check that `to' falls within the year range of: `using'"
        restore
        cap drop __ppp_*
        sort `sortorder'
        exit 198
    }

    if "`mode'" == "ppp" {
        qui keep countrycode cpi ppp_factor
        qui drop if missing(cpi) | missing(ppp_factor)
        qui ren ppp_factor __ppp_tgt_ppp
    }
    else if "`mode'" == "usd" {
        cap confirm variable xr
        if _rc {
            di as error "Exchange rate (xr) not found in deflator dataset."
            di as error "Rebuild with: wdi_deflate build, saving(...) replace"
            restore
            cap drop __ppp_*
            sort `sortorder'
            exit 111
        }
        qui keep countrycode cpi xr
        qui drop if missing(cpi) | missing(xr)
        qui ren xr __ppp_tgt_xr
    }
    else {
        * deflate: only need target CPI
        qui keep countrycode cpi
        qui drop if missing(cpi)
    }

    qui ren countrycode __ppp_cc
    qui ren cpi __ppp_tgt_cpi
    qui sort __ppp_cc
    qui save `tgt_lookup'
    restore

    if "`mode'" == "ppp" {
        qui merge m:1 __ppp_cc using `tgt_lookup', ///
            keep(master match) nogen keepusing(__ppp_tgt_cpi __ppp_tgt_ppp)
    }
    else if "`mode'" == "usd" {
        qui merge m:1 __ppp_cc using `tgt_lookup', ///
            keep(master match) nogen keepusing(__ppp_tgt_cpi __ppp_tgt_xr)
    }
    else {
        qui merge m:1 __ppp_cc using `tgt_lookup', ///
            keep(master match) nogen keepusing(__ppp_tgt_cpi)
    }

    * -----------------------------------------------------------------------
    * Step 3: Compute conversion
    * -----------------------------------------------------------------------
    *   ppp:              PPP$_y = LCU * (CPI_tgt / CPI_src) / PPP_tgt
    *   ppp + fromppp:    PPP$_y = PPP$_x * PPP_src * (CPI_tgt / CPI_src) / PPP_tgt
    *   usd:              USD    = LCU * (CPI_tgt / CPI_src) / XR_tgt
    *   usd + fromusd:    USD_y  = USD_x * XR_src * (CPI_tgt / CPI_src) / XR_tgt
    *   deflate:          LCU'   = LCU * (CPI_tgt / CPI_src)
    *   deflate + fromppp: LCU_y = PPP$_x * PPP_src * (CPI_tgt / CPI_src)
    *   deflate + fromusd: LCU_y = USD_x * XR_src * (CPI_tgt / CPI_src)

    local converted_vars ""

    foreach var of varlist `varlist' {

        * Build the expression
        if "`mode'" == "ppp" & "`fromppp'" != "" {
            local expr "`var' * __ppp_src_ppp * (__ppp_tgt_cpi / __ppp_src_cpi) / __ppp_tgt_ppp"
            local vlab "`var' rebased to `to' PPP intl $"
        }
        else if "`mode'" == "ppp" {
            local expr "`var' * (__ppp_tgt_cpi / __ppp_src_cpi) / __ppp_tgt_ppp"
            local vlab "`var' in `to' PPP intl $"
        }
        else if "`mode'" == "usd" & "`fromusd'" != "" {
            local expr "`var' * __ppp_src_xr * (__ppp_tgt_cpi / __ppp_src_cpi) / __ppp_tgt_xr"
            local vlab "`var' rebased to `to' nominal USD"
        }
        else if "`mode'" == "usd" {
            local expr "`var' * (__ppp_tgt_cpi / __ppp_src_cpi) / __ppp_tgt_xr"
            local vlab "`var' in `to' nominal USD"
        }
        else if "`mode'" == "deflate" & "`fromppp'" != "" {
            local expr "`var' * __ppp_src_ppp * (__ppp_tgt_cpi / __ppp_src_cpi)"
            local vlab "`var' converted from PPP to constant `to' LCU"
        }
        else if "`mode'" == "deflate" & "`fromusd'" != "" {
            local expr "`var' * __ppp_src_xr * (__ppp_tgt_cpi / __ppp_src_cpi)"
            local vlab "`var' converted from USD to constant `to' LCU"
        }
        else {
            local expr "`var' * (__ppp_tgt_cpi / __ppp_src_cpi)"
            local vlab "`var' in constant `to' LCU"
        }

        if "`replace'" != "" {
            qui replace `var' = `expr' if `touse'
            local converted_vars "`converted_vars' `var'"
        }
        else {
            local newvar "`var'`suffix'"
            cap confirm new variable `newvar'
            if _rc {
                di as error "Variable `newvar' already exists. " ///
                    "Use replace option or different suffix()."
                cap drop __ppp_*
                sort `sortorder'
                exit 110
            }
            qui gen double `newvar' = `expr' if `touse'
            label variable `newvar' "`vlab'"
            local converted_vars "`converted_vars' `newvar'"
        }
    }

    * -----------------------------------------------------------------------
    * Diagnostics (always compute counts for r-class returns)
    * -----------------------------------------------------------------------
    qui count if `touse'
    local N_converted = r(N)

    qui count if missing(__ppp_src_cpi) & `touse'
    local miss_src = r(N)

    if "`mode'" == "ppp" {
        qui count if missing(__ppp_tgt_ppp) & `touse'
        local miss_tgt = r(N)
        local divisor_lab "PPP"
        local tgt_miss_var "__ppp_tgt_ppp"
    }
    else if "`mode'" == "usd" {
        qui count if missing(__ppp_tgt_xr) & `touse'
        local miss_tgt = r(N)
        local divisor_lab "XR"
        local tgt_miss_var "__ppp_tgt_xr"
    }
    else {
        qui count if missing(__ppp_tgt_cpi) & `touse'
        local miss_tgt = r(N)
        local divisor_lab "CPI"
        local tgt_miss_var "__ppp_tgt_cpi"
    }

    if "`fromppp'" != "" {
        qui count if missing(__ppp_src_ppp) & `touse'
        local miss_src_ppp = r(N)
    }
    if "`fromusd'" != "" {
        qui count if missing(__ppp_src_xr) & `touse'
        local miss_src_xr = r(N)
    }

    * --- Display only if not quiet ---
    if "`quiet'" == "" {
        di as text ""
        di as text "{hline 60}"
        di as result "wdi_deflate: converted `varlist' -> `mode_lab'"
        di as text "{hline 60}"
        di as text "  Converted:    `N_converted' obs"

        if "`from_type'" == "scalar" {
            di as text "  Source year:  `from_val' (fixed)"
        }
        else {
            qui sum `from'
            di as text "  Source year:  `from' (variable, range `r(min)'-`r(max)')"
        }
        di as text "  Target year:  `to'"
        if "`deflator_date'" != "" {
            di as text "  Deflator:     built `deflator_date' (sig: `deflator_sig')"
        }
        else {
            di as text "  Deflator:     `using'"
        }
        if `deflator_modified' {
            di as error "  Warning: deflator file has been modified since it was built"
        }

        if "`mode'" == "ppp" & "`fromppp'" != "" {
            di as text "  Input unit:   PPP intl $ (fromppp)"
            di as text "  Formula:      PPP$_`to' = PPP$_src * PPP_src * (CPI_`to'/CPI_src) / PPP_`to'"
        }
        else if "`mode'" == "ppp" {
            di as text "  Formula:      PPP$ = LCU * (CPI_`to'/CPI_src) / PPP_`to'"
        }
        else if "`mode'" == "usd" & "`fromusd'" != "" {
            di as text "  Input unit:   nominal USD (fromusd)"
            di as text "  Formula:      USD_`to' = USD_src * XR_src * (CPI_`to'/CPI_src) / XR_`to'"
        }
        else if "`mode'" == "usd" {
            di as text "  Formula:      USD  = LCU * (CPI_`to'/CPI_src) / XR_`to'"
        }
        else if "`mode'" == "deflate" & "`fromppp'" != "" {
            di as text "  Input unit:   PPP intl $ (fromppp)"
            di as text "  Formula:      LCU_`to' = PPP$_src * PPP_src * (CPI_`to'/CPI_src)"
        }
        else if "`mode'" == "deflate" & "`fromusd'" != "" {
            di as text "  Input unit:   nominal USD (fromusd)"
            di as text "  Formula:      LCU_`to' = USD_src * XR_src * (CPI_`to'/CPI_src)"
        }
        else {
            di as text "  Formula:      LCU' = LCU * (CPI_`to'/CPI_src)"
        }

        if "`replace'" != "" {
            di as text "  Variables:    `varlist' (replaced in place)"
        }
        else {
            di as text "  New vars:    `converted_vars'"
        }

        if `miss_src' > 0 {
            di as text ""
            di as error "  Warning: `miss_src' obs missing source-year CPI"
            qui levelsof __ppp_cc if missing(__ppp_src_cpi) & `touse', local(_miss) clean separate(", ")
            di as text "  -> `_miss'"
        }
        if "`fromppp'" != "" {
            if `miss_src_ppp' > 0 {
                di as text ""
                di as error "  Warning: `miss_src_ppp' obs missing source-year PPP factor"
                qui levelsof __ppp_cc if missing(__ppp_src_ppp) & `touse', local(_miss) clean separate(", ")
                di as text "  -> `_miss'"
            }
        }
        if "`fromusd'" != "" {
            if `miss_src_xr' > 0 {
                di as text ""
                di as error "  Warning: `miss_src_xr' obs missing source-year exchange rate"
                qui levelsof __ppp_cc if missing(__ppp_src_xr) & `touse', local(_miss) clean separate(", ")
                di as text "  -> `_miss'"
            }
        }
        if `miss_tgt' > 0 {
            di as text ""
            di as error "  Warning: `miss_tgt' obs missing target-year `divisor_lab'"
            qui levelsof __ppp_cc if missing(`tgt_miss_var') & `touse', local(_miss) clean
            if "`deflator_countries'" != "" & "`deflator_countries'" != "ALL" {
                * Check which missing countries are absent from the deflator
                local not_in_defl ""
                local in_defl_no_data ""
                foreach _cc of local _miss {
                    local _found 0
                    foreach _dc of local deflator_countries {
                        if "`_cc'" == "`_dc'" {
                            local _found 1
                            continue, break
                        }
                    }
                    if `_found' == 0 {
                        local not_in_defl "`not_in_defl' `_cc'"
                    }
                    else {
                        local in_defl_no_data "`in_defl_no_data' `_cc'"
                    }
                }
                local not_in_defl = strtrim("`not_in_defl'")
                local in_defl_no_data = strtrim("`in_defl_no_data'")
                if "`not_in_defl'" != "" {
                    di as text "  -> `not_in_defl' (not in deflator; rebuild with these countries or use a full-world deflator)"
                }
                if "`in_defl_no_data'" != "" {
                    di as text "  -> `in_defl_no_data' (in deflator but no `divisor_lab' for `to' in WDI)"
                }
            }
            else {
                local _miss_disp : subinstr local _miss " " ", ", all
                di as text "  -> `_miss_disp'"
            }
        }
        di as text "{hline 60}"
    }

    * -----------------------------------------------------------------------
    * Clean up
    * -----------------------------------------------------------------------
    cap drop __ppp_*
    qui sort `sortorder'

    * -----------------------------------------------------------------------
    * r-class returns
    * -----------------------------------------------------------------------
    return scalar N        = `N_converted'
    return scalar miss_src = `miss_src'
    return scalar miss_tgt = `miss_tgt'
    return scalar to       = `to'
    return local  mode       "`mode'"
    return local  newvars    "`converted_vars'"
end
