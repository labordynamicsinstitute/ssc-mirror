*! version 1.1.0  05dec2025  Kelvin Law
*! Converts SIC codes to Fama-French industry classifications
*! Supports FF5, FF10, FF12, FF17, FF30, FF38, FF48, and FF49
*!
*! Features:
*!   - Handles both numeric and string SIC codes
*!   - Supports primary + fallback SIC variables (e.g., sich sic)
*!   - All schemes validated against Ken French's official Siccodes files
*!   - FF38 uses Ken French's simple 2-digit SIC-based classification
*!   - FF49 properly implements Software industry (SIC 7370-7373, 7375)
*!   - NOMISSING option to force all valid SICs into an industry
*!   - By default, FF17/30/38/48/49 leave unmapped SICs as missing per Ken French
*!
*! v1.1.0: FF12 (3622 stays in Manuf per Ken French), FF17 (complete rewrite),
*!         FF30 (added missing ranges), FF38 (uses correct simple 2-digit scheme)

program sic_to_ff
    version 14.0
    
    syntax varlist(min=1 max=2) [if] [in], GENerate(name) ///
        [SCHeme(string) LABels REPlace NOMISSING]
    
    * Set default scheme to FF48
    if "`scheme'" == "" {
        local scheme "48"
    }
    
    * Validate scheme
    if !inlist("`scheme'", "5", "10", "12", "17", "30", "38", "48", "49") {
        display as error "scheme() must be one of: 5, 10, 12, 17, 30, 38, 48, or 49"
        exit 198
    }
    
    * Check if variable already exists
    capture confirm variable `generate'
    if _rc == 0 {
        if "`replace'" == "" {
            display as error "variable `generate' already exists"
            display as error "use replace option to overwrite"
            exit 110
        }
        else {
            drop `generate'
            capture label drop `generate'_lbl
        }
    }
    
    * Mark sample
    marksample touse, novarlist
    
    * Parse primary and fallback SIC variables
    local nvars : word count `varlist'
    local sicvar1 : word 1 of `varlist'
    if `nvars' == 2 {
        local sicvar2 : word 2 of `varlist'
    }
    
    * Create working SIC variable that combines primary and fallback
    tempvar sic_combined
    
    * Process primary SIC variable (handles both string and numeric)
    capture confirm string variable `sicvar1'
    if _rc == 0 {
        * Primary is string
        quietly generate double `sic_combined' = real(`sicvar1') if `touse'
    }
    else {
        * Primary is numeric
        quietly generate double `sic_combined' = `sicvar1' if `touse'
    }
    
    * Process fallback SIC variable if provided
    if `nvars' == 2 {
        capture confirm string variable `sicvar2'
        if _rc == 0 {
            * Fallback is string
            quietly replace `sic_combined' = real(`sicvar2') if `touse' & missing(`sic_combined')
        }
        else {
            * Fallback is numeric
            quietly replace `sic_combined' = `sicvar2' if `touse' & missing(`sic_combined')
        }
        
        * Report how many were filled by fallback
        quietly count if `touse' & missing(`sicvar1') & !missing(`sic_combined')
        if r(N) > 0 {
            display as text "Note: " as result r(N) as text " observations filled using fallback variable (`sicvar2')"
        }
    }
    
    * Use combined SIC for classification
    local sicvar "`sic_combined'"
    
    * Generate the new variable
    quietly generate int `generate' = .
    
    * Determine if we should force all SICs into industries
    * FF5, FF10, FF12 always use catch-all "Other"
    * FF17, FF30, FF38, FF48, FF49 only use catch-all if nomissing specified
    local use_catchall = 0
    if inlist("`scheme'", "5", "10", "12") {
        local use_catchall = 1
    }
    else if "`nomissing'" != "" {
        local use_catchall = 1
    }
    
    * Call appropriate subroutine based on scheme
    if "`scheme'" == "5" {
        _sic_to_ff5 `sicvar' `generate' `touse' `use_catchall'
    }
    else if "`scheme'" == "10" {
        _sic_to_ff10 `sicvar' `generate' `touse' `use_catchall'
    }
    else if "`scheme'" == "12" {
        _sic_to_ff12 `sicvar' `generate' `touse' `use_catchall'
    }
    else if "`scheme'" == "17" {
        _sic_to_ff17 `sicvar' `generate' `touse' `use_catchall'
    }
    else if "`scheme'" == "30" {
        _sic_to_ff30 `sicvar' `generate' `touse' `use_catchall'
    }
    else if "`scheme'" == "38" {
        _sic_to_ff38 `sicvar' `generate' `touse' `use_catchall'
    }
    else if "`scheme'" == "48" {
        _sic_to_ff48 `sicvar' `generate' `touse' `use_catchall'
    }
    else if "`scheme'" == "49" {
        _sic_to_ff49 `sicvar' `generate' `touse' `use_catchall'
    }
    
    * Apply labels if requested
    if "`labels'" != "" {
        _apply_ff_labels `generate' `scheme'
    }
    
    * Report results
    quietly count if `generate' != . & `touse'
    local nmapped = r(N)
    quietly count if `generate' == . & `touse' & `sicvar' != .
    local nmissing = r(N)
    
    display as text ""
    display as text "Fama-French `scheme'-industry classification created: " as result "`generate'"
    display as text "Observations mapped: " as result "`nmapped'"
    if `nmissing' > 0 {
        display as text "Observations with valid SIC but no FF match: " as result "`nmissing'"
        if "`nomissing'" == "" & inlist("`scheme'", "17", "30", "38", "48", "49") {
            display as text "(Per Ken French, these remain unclassified. Use nomissing to force into Other.)"
        }
    }
    
end

*----------------------------------------------------------------------
* FF5 Industries
* Per Ken French: SIC 3622 assigned to HiTec (carved out from Manufacturing)
*----------------------------------------------------------------------
program _sic_to_ff5
    args sicvar generate touse use_catchall
    
    quietly {
        * 1 = Consumer (Cnsmr)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 100, 999)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2000, 2399)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2700, 2749)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2770, 2799)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 3100, 3199)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 3940, 3989)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2500, 2519)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2590, 2599)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 3630, 3659)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 3710, 3711)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 3714, 3714)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 3716, 3716)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 3750, 3751)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 3792, 3792)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 3900, 3939)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 3990, 3999)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 5000, 5999)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 7200, 7299)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 7600, 7699)
        
        * 2 = Manufacturing (Manuf)
        * Note: 3580-3629 split to exclude 3622 (assigned to HiTec per Ken French)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2520, 2589)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2600, 2699)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2750, 2769)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2800, 2829)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2840, 2899)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3000, 3099)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3200, 3569)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3580, 3621)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3623, 3629)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3700, 3709)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3712, 3713)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3715, 3715)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3717, 3749)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3752, 3791)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3793, 3799)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3860, 3899)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 1200, 1399)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2900, 2999)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 4900, 4949)
        
        * 3 = High-Tech (HiTec)
        * Note: Includes 3622 per Ken French
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3570, 3579)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3622, 3622)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3660, 3692)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3694, 3699)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3810, 3839)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 7370, 7379)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 7391, 7391)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 8730, 8734)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 4800, 4899)
        
        * 4 = Health (Hlth)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 2830, 2839)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 3693, 3693)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 3840, 3859)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 8000, 8099)
        
        * 5 = Other (always catch-all for FF5)
        if `use_catchall' {
            replace `generate' = 5 if `touse' & `generate' == . & `sicvar' != .
        }
    }
end

*----------------------------------------------------------------------
* FF10 Industries
* Per Ken French: SIC 3622 assigned to HiTec (carved out from Manufacturing)
*----------------------------------------------------------------------
program _sic_to_ff10
    args sicvar generate touse use_catchall
    
    quietly {
        * 1 = NoDur (Consumer NonDurables)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 100, 999)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2000, 2399)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2700, 2749)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2770, 2799)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 3100, 3199)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 3940, 3989)
        
        * 2 = Durbl (Consumer Durables)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2500, 2519)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2590, 2599)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3630, 3659)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3710, 3711)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3714, 3714)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3716, 3716)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3750, 3751)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3792, 3792)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3900, 3939)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3990, 3999)
        
        * 3 = Manuf (Manufacturing)
        * Note: 3580-3629 split to exclude 3622 (assigned to HiTec per Ken French)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 2520, 2589)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 2600, 2699)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 2750, 2769)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 2800, 2829)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 2840, 2899)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3000, 3099)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3200, 3569)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3580, 3621)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3623, 3629)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3700, 3709)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3712, 3713)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3715, 3715)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3717, 3749)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3752, 3791)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3793, 3799)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3860, 3899)
        
        * 4 = Enrgy (Energy)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 1200, 1399)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 2900, 2999)
        
        * 5 = HiTec (High-Tech)
        * Note: Includes 3622 per Ken French
        replace `generate' = 5 if `touse' & inrange(`sicvar', 3570, 3579)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 3622, 3622)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 3660, 3692)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 3694, 3699)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 3810, 3839)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 7370, 7379)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 7391, 7391)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 8730, 8734)
        
        * 6 = Telcm (Telecom)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 4800, 4899)
        
        * 7 = Shops (Retail)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 5000, 5999)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 7200, 7299)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 7600, 7699)
        
        * 8 = Hlth (Healthcare)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 2830, 2839)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 3693, 3693)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 3840, 3859)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 8000, 8099)
        
        * 9 = Utils (Utilities)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 4900, 4949)
        
        * 10 = Other (always catch-all for FF10)
        if `use_catchall' {
            replace `generate' = 10 if `touse' & `generate' == . & `sicvar' != .
        }
    }
end

*----------------------------------------------------------------------
* FF12 Industries
* Per Ken French: 3622 stays in Manuf (3580-3629 is single range)
* BusEq range is 3810-3829, not 3810-3839
*----------------------------------------------------------------------
program _sic_to_ff12
    args sicvar generate touse use_catchall
    
    quietly {
        * 1 = NoDur (Consumer NonDurables)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 100, 999)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2000, 2399)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2700, 2749)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2770, 2799)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 3100, 3199)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 3940, 3989)
        
        * 2 = Durbl (Consumer Durables)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2500, 2519)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2590, 2599)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3630, 3659)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3710, 3711)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3714, 3714)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3716, 3716)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3750, 3751)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3792, 3792)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3900, 3939)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 3990, 3999)
        
        * 3 = Manuf (Manufacturing)
        * Per Ken French: 3580-3629 is single range (includes 3622)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 2520, 2589)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 2600, 2699)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 2750, 2769)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3000, 3099)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3200, 3569)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3580, 3629)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3700, 3709)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3712, 3713)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3715, 3715)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3717, 3749)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3752, 3791)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3793, 3799)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3830, 3839)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 3860, 3899)
        
        * 4 = Enrgy (Energy)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 1200, 1399)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 2900, 2999)
        
        * 5 = Chems (Chemicals)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 2800, 2829)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 2840, 2899)
        
        * 6 = BusEq (Business Equipment)
        * Per Ken French: 3810-3829 (not 3839), no 3622
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3570, 3579)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3660, 3692)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3694, 3699)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3810, 3829)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 7370, 7379)
        
        * 7 = Telcm (Telecom)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 4800, 4899)
        
        * 8 = Utils (Utilities)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 4900, 4949)
        
        * 9 = Shops (Wholesale and Retail)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 5000, 5999)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 7200, 7299)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 7600, 7699)
        
        * 10 = Hlth (Healthcare)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 2830, 2839)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 3693, 3693)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 3840, 3859)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 8000, 8099)
        
        * 11 = Money (Finance)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 6000, 6999)
        
        * 12 = Other (always catch-all for FF12)
        if `use_catchall' {
            replace `generate' = 12 if `touse' & `generate' == . & `sicvar' != .
        }
    }
end

*----------------------------------------------------------------------
* FF17 Industries
* Complete rewrite to match Ken French's Siccodes17.txt exactly
*----------------------------------------------------------------------
program _sic_to_ff17
    args sicvar generate touse use_catchall
    
    quietly {
        * 1 = Food (Food)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 100, 299)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 700, 799)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 900, 999)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2000, 2099)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 5140, 5149)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 5150, 5159)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 5180, 5182)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 5191, 5191)
        
        * 2 = Mines (Mining and Minerals)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 1000, 1049)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 1060, 1099)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 1200, 1299)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 1400, 1499)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 5050, 5052)
        
        * 3 = Oil (Oil and Petroleum Products)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 1300, 1300)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 1310, 1329)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 1380, 1382)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 1389, 1389)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 2900, 2912)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 5170, 5172)
        
        * 4 = Clths (Textiles, Apparel & Footwear)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 2200, 2299)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 2300, 2399)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 3020, 3021)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 3100, 3151)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 3963, 3965)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 5130, 5139)
        
        * 5 = Durbl (Consumer Durables)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 2510, 2519)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 2590, 2599)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 3060, 3099)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 3630, 3652)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 3860, 3873)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 3910, 3915)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 3930, 3949)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 3960, 3962)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 5020, 5023)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 5064, 5064)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 5094, 5094)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 5099, 5099)
        
        * 6 = Chems (Chemicals)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 2800, 2829)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 2860, 2899)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 5160, 5169)
        
        * 7 = Cnsum (Drugs, Soap, Perfumes, Tobacco)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 2100, 2199)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 2830, 2844)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 5120, 5122)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 5194, 5194)
        
        * 8 = Cnstr (Construction and Construction Materials)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 800, 899)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 1500, 1799)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 2400, 2499)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 2850, 2859)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 2950, 2952)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 3200, 3299)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 3420, 3452)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 5030, 5039)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 5070, 5078)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 5198, 5198)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 5210, 5231)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 5250, 5251)
        
        * 9 = Steel (Steel Works Etc)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3300, 3399)
        
        * 10 = FabPr (Fabricated Products)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 3410, 3412)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 3443, 3444)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 3460, 3499)
        
        * 11 = Machn (Machinery and Business Equipment)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 3510, 3599)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 3600, 3699)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 3810, 3839)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 3950, 3955)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 5060, 5065)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 5080, 5081)
        
        * 12 = Cars (Automobiles)
        replace `generate' = 12 if `touse' & inrange(`sicvar', 3710, 3711)
        replace `generate' = 12 if `touse' & inrange(`sicvar', 3714, 3714)
        replace `generate' = 12 if `touse' & inrange(`sicvar', 3716, 3716)
        replace `generate' = 12 if `touse' & inrange(`sicvar', 3750, 3751)
        replace `generate' = 12 if `touse' & inrange(`sicvar', 3792, 3792)
        replace `generate' = 12 if `touse' & inrange(`sicvar', 5010, 5015)
        replace `generate' = 12 if `touse' & inrange(`sicvar', 5510, 5599)
        
        * 13 = Trans (Transportation)
        replace `generate' = 13 if `touse' & inrange(`sicvar', 3713, 3713)
        replace `generate' = 13 if `touse' & inrange(`sicvar', 3715, 3715)
        replace `generate' = 13 if `touse' & inrange(`sicvar', 3720, 3731)
        replace `generate' = 13 if `touse' & inrange(`sicvar', 3740, 3743)
        replace `generate' = 13 if `touse' & inrange(`sicvar', 3760, 3799)
        replace `generate' = 13 if `touse' & inrange(`sicvar', 4000, 4799)
        
        * 14 = Utils (Utilities)
        replace `generate' = 14 if `touse' & inrange(`sicvar', 4900, 4942)
        
        * 15 = Rtail (Retail Stores)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 5260, 5261)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 5270, 5271)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 5300, 5399)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 5400, 5499)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 5540, 5541)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 5550, 5551)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 5600, 5699)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 5700, 5736)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 5750, 5750)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 5800, 5899)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 5900, 5999)
        
        * 16 = Finan (Banks, Insurance, Other Financials)
        replace `generate' = 16 if `touse' & inrange(`sicvar', 6000, 6799)
        
        * 17 = Other (explicit ranges from Siccodes17.txt)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 4950, 4959)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 4960, 4961)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 4970, 4971)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 4990, 4991)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 5000, 5079)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 5080, 5099)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 5100, 5129)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 5200, 5509)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 5520, 5539)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 5560, 5599)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 5700, 5799)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 5800, 5899)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 6800, 6899)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 6900, 6999)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 7000, 7019)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 7020, 7021)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 7030, 7039)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 7040, 7049)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 7200, 7212)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 7213, 7213)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 7215, 7299)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 7300, 7399)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 7500, 7549)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 7600, 7699)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 7800, 7999)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 8000, 8099)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 8100, 8199)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 8200, 8299)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 8300, 8399)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 8400, 8499)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 8600, 8699)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 8700, 8799)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 8800, 8899)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 8900, 8999)
        
        * Optional catch-all for truly unmapped SICs
        if `use_catchall' {
            replace `generate' = 17 if `touse' & `generate' == . & `sicvar' != .
        }
    }
end

*----------------------------------------------------------------------
* FF30 Industries
* Rewritten to match Ken French's Siccodes30.txt exactly
*----------------------------------------------------------------------
program _sic_to_ff30
    args sicvar generate touse use_catchall
    
    quietly {
        * 1 = Food (Food Products)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 100, 299)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 700, 799)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 910, 919)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2000, 2046)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2048, 2048)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2050, 2068)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2070, 2079)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2086, 2092)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2095, 2099)
        
        * 2 = Beer (Beer & Liquor)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2080, 2085)
        
        * 3 = Smoke (Tobacco Products)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 2100, 2199)
        
        * 4 = Games (Recreation) - includes entertainment per Ken French
        replace `generate' = 4 if `touse' & inrange(`sicvar', 920, 999)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 3650, 3652)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 3732, 3732)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 3930, 3931)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 3940, 3949)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 7800, 7833)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 7840, 7841)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 7900, 7949)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 7980, 7980)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 7990, 7999)
        
        * 5 = Books (Printing and Publishing) - includes 3993 per Ken French
        replace `generate' = 5 if `touse' & inrange(`sicvar', 2700, 2759)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 2770, 2799)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 3993, 3993)
        
        * 6 = Hshld (Consumer Goods)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 2047, 2047)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 2391, 2392)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 2510, 2519)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 2590, 2599)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 2840, 2844)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3160, 3199)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3229, 3231)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3260, 3260)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3262, 3263)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3269, 3269)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3630, 3639)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3750, 3751)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3800, 3800)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3860, 3873)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3910, 3915)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3960, 3962)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3991, 3991)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3995, 3995)
        
        * 7 = Clths (Apparel)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 2300, 2390)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 3020, 3021)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 3100, 3111)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 3130, 3151)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 3963, 3965)
        
        * 8 = Hlth (Healthcare)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 2830, 2836)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 3693, 3693)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 3840, 3851)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 8000, 8099)
        
        * 9 = Chems (Chemicals)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 2800, 2829)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 2850, 2899)
        
        * 10 = Txtls (Textiles)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 2200, 2295)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 2297, 2299)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 2393, 2395)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 2397, 2399)
        
        * 11 = Cnstr (Construction and Construction Materials)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 800, 899)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 1500, 1549)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 1600, 1799)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 2400, 2499)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 2660, 2661)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 2950, 2952)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 3200, 3299)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 3420, 3452)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 3490, 3499)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 3996, 3996)
        
        * 12 = Steel (Steel Works Etc)
        replace `generate' = 12 if `touse' & inrange(`sicvar', 3300, 3379)
        replace `generate' = 12 if `touse' & inrange(`sicvar', 3390, 3399)
        
        * 13 = FabPr (Fabricated Products and Machinery)
        replace `generate' = 13 if `touse' & inrange(`sicvar', 3400, 3400)
        replace `generate' = 13 if `touse' & inrange(`sicvar', 3443, 3444)
        replace `generate' = 13 if `touse' & inrange(`sicvar', 3460, 3479)
        replace `generate' = 13 if `touse' & inrange(`sicvar', 3510, 3599)
        
        * 14 = ElcEq (Electrical Equipment)
        replace `generate' = 14 if `touse' & inrange(`sicvar', 3600, 3629)
        replace `generate' = 14 if `touse' & inrange(`sicvar', 3640, 3692)
        replace `generate' = 14 if `touse' & inrange(`sicvar', 3699, 3699)
        
        * 15 = Autos (Automobiles and Trucks)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 2296, 2296)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 2396, 2396)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 3010, 3011)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 3537, 3537)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 3647, 3647)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 3694, 3694)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 3700, 3716)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 3790, 3792)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 3799, 3799)
        
        * 16 = Carry (Aircraft, Ships, Railroad Equipment)
        replace `generate' = 16 if `touse' & inrange(`sicvar', 3720, 3729)
        replace `generate' = 16 if `touse' & inrange(`sicvar', 3730, 3731)
        replace `generate' = 16 if `touse' & inrange(`sicvar', 3740, 3743)
        
        * 17 = Mines (Precious Metals, Mining)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 1000, 1049)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 1050, 1119)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 1400, 1499)
        
        * 18 = Coal
        replace `generate' = 18 if `touse' & inrange(`sicvar', 1200, 1299)
        
        * 19 = Oil (Petroleum and Natural Gas)
        replace `generate' = 19 if `touse' & inrange(`sicvar', 1300, 1339)
        replace `generate' = 19 if `touse' & inrange(`sicvar', 1370, 1389)
        replace `generate' = 19 if `touse' & inrange(`sicvar', 2900, 2999)
        
        * 20 = Util (Utilities)
        replace `generate' = 20 if `touse' & inrange(`sicvar', 4900, 4942)
        
        * 21 = Telcm (Communication)
        replace `generate' = 21 if `touse' & inrange(`sicvar', 4800, 4899)
        
        * 22 = Servs (Personal and Business Services)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 7020, 7033)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 7200, 7299)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 7300, 7399)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 7500, 7549)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 7600, 7699)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 8100, 8499)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 8600, 8699)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 8700, 8748)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 8800, 8999)
        
        * 23 = BusEq (Business Equipment)
        replace `generate' = 23 if `touse' & inrange(`sicvar', 3570, 3579)
        replace `generate' = 23 if `touse' & inrange(`sicvar', 3622, 3622)
        replace `generate' = 23 if `touse' & inrange(`sicvar', 3661, 3669)
        replace `generate' = 23 if `touse' & inrange(`sicvar', 3670, 3695)
        replace `generate' = 23 if `touse' & inrange(`sicvar', 3810, 3839)
        replace `generate' = 23 if `touse' & inrange(`sicvar', 7373, 7373)
        
        * 24 = Paper (Business Supplies and Shipping Containers)
        replace `generate' = 24 if `touse' & inrange(`sicvar', 2440, 2449)
        replace `generate' = 24 if `touse' & inrange(`sicvar', 2520, 2549)
        replace `generate' = 24 if `touse' & inrange(`sicvar', 2600, 2659)
        replace `generate' = 24 if `touse' & inrange(`sicvar', 2670, 2699)
        replace `generate' = 24 if `touse' & inrange(`sicvar', 2760, 2761)
        replace `generate' = 24 if `touse' & inrange(`sicvar', 3220, 3221)
        replace `generate' = 24 if `touse' & inrange(`sicvar', 3410, 3412)
        replace `generate' = 24 if `touse' & inrange(`sicvar', 3950, 3955)
        
        * 25 = Trans (Transportation)
        replace `generate' = 25 if `touse' & inrange(`sicvar', 4000, 4049)
        replace `generate' = 25 if `touse' & inrange(`sicvar', 4100, 4249)
        replace `generate' = 25 if `touse' & inrange(`sicvar', 4400, 4799)
        
        * 26 = Whlsl (Wholesale)
        replace `generate' = 26 if `touse' & inrange(`sicvar', 5000, 5199)
        
        * 27 = Rtail (Retail)
        replace `generate' = 27 if `touse' & inrange(`sicvar', 5200, 5799)
        replace `generate' = 27 if `touse' & inrange(`sicvar', 5900, 5999)
        
        * 28 = Meals (Restaurants, Hotels, Motels)
        replace `generate' = 28 if `touse' & inrange(`sicvar', 5800, 5899)
        replace `generate' = 28 if `touse' & inrange(`sicvar', 7000, 7019)
        replace `generate' = 28 if `touse' & inrange(`sicvar', 7040, 7049)
        replace `generate' = 28 if `touse' & inrange(`sicvar', 7213, 7213)
        
        * 29 = Fin (Banking, Insurance, Real Estate, Trading)
        replace `generate' = 29 if `touse' & inrange(`sicvar', 6000, 6799)
        
        * 30 = Other (explicit ranges from Siccodes30.txt)
        replace `generate' = 30 if `touse' & inrange(`sicvar', 4950, 4959)
        replace `generate' = 30 if `touse' & inrange(`sicvar', 4960, 4961)
        replace `generate' = 30 if `touse' & inrange(`sicvar', 4970, 4971)
        replace `generate' = 30 if `touse' & inrange(`sicvar', 4990, 4991)
        
        if `use_catchall' {
            replace `generate' = 30 if `touse' & `generate' == . & `sicvar' != .
        }
    }
end

*----------------------------------------------------------------------
* FF38 Industries
* Ken French's FF38 is a SIMPLE 2-digit SIC-based classification
* Completely different from FF48's detailed structure
*----------------------------------------------------------------------
program _sic_to_ff38
    args sicvar generate touse use_catchall
    
    quietly {
        * 1 = Agric (Agriculture, forestry, and fishing)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 100, 999)
        
        * 2 = Mines (Mining)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 1000, 1299)
        
        * 3 = Oil (Oil and Gas Extraction)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 1300, 1399)
        
        * 4 = Stone (Nonmetallic Minerals Except Fuels)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 1400, 1499)
        
        * 5 = Cnstr (Construction)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 1500, 1799)
        
        * 6 = Food (Food and Kindred Products)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 2000, 2099)
        
        * 7 = Smoke (Tobacco Products)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 2100, 2199)
        
        * 8 = Txtls (Textile Mill Products)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 2200, 2299)
        
        * 9 = Apprl (Apparel and other Textile Products)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 2300, 2399)
        
        * 10 = Wood (Lumber and Wood Products)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 2400, 2499)
        
        * 11 = Chair (Furniture and Fixtures)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 2500, 2599)
        
        * 12 = Paper (Paper and Allied Products)
        replace `generate' = 12 if `touse' & inrange(`sicvar', 2600, 2661)
        
        * 13 = Print (Printing and Publishing)
        replace `generate' = 13 if `touse' & inrange(`sicvar', 2700, 2799)
        
        * 14 = Chems (Chemicals and Allied Products)
        replace `generate' = 14 if `touse' & inrange(`sicvar', 2800, 2899)
        
        * 15 = Ptrlm (Petroleum and Coal Products)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 2900, 2999)
        
        * 16 = Rubbr (Rubber and Miscellaneous Plastics Products)
        replace `generate' = 16 if `touse' & inrange(`sicvar', 3000, 3099)
        
        * 17 = Lethr (Leather and Leather Products)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 3100, 3199)
        
        * 18 = Glass (Stone, Clay and Glass Products)
        replace `generate' = 18 if `touse' & inrange(`sicvar', 3200, 3299)
        
        * 19 = Metal (Primary Metal Industries)
        replace `generate' = 19 if `touse' & inrange(`sicvar', 3300, 3399)
        
        * 20 = MtlPr (Fabricated Metal Products)
        replace `generate' = 20 if `touse' & inrange(`sicvar', 3400, 3499)
        
        * 21 = Machn (Machinery, Except Electrical)
        replace `generate' = 21 if `touse' & inrange(`sicvar', 3500, 3599)
        
        * 22 = Elctr (Electrical and Electronic Equipment)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 3600, 3699)
        
        * 23 = Cars (Transportation Equipment)
        replace `generate' = 23 if `touse' & inrange(`sicvar', 3700, 3799)
        
        * 24 = Instr (Instruments and Related Products)
        replace `generate' = 24 if `touse' & inrange(`sicvar', 3800, 3879)
        
        * 25 = Manuf (Miscellaneous Manufacturing Industries)
        replace `generate' = 25 if `touse' & inrange(`sicvar', 3900, 3999)
        
        * 26 = Trans (Transportation)
        replace `generate' = 26 if `touse' & inrange(`sicvar', 4000, 4799)
        
        * 27 = Phone (Telephone and Telegraph Communication)
        replace `generate' = 27 if `touse' & inrange(`sicvar', 4800, 4829)
        
        * 28 = TV (Radio and Television Broadcasting)
        replace `generate' = 28 if `touse' & inrange(`sicvar', 4830, 4899)
        
        * 29 = Utils (Electric, Gas, and Water Supply)
        replace `generate' = 29 if `touse' & inrange(`sicvar', 4900, 4949)
        
        * 30 = Garbg (Sanitary Services)
        replace `generate' = 30 if `touse' & inrange(`sicvar', 4950, 4959)
        
        * 31 = Steam (Steam Supply)
        replace `generate' = 31 if `touse' & inrange(`sicvar', 4960, 4969)
        
        * 32 = Water (Irrigation Systems)
        replace `generate' = 32 if `touse' & inrange(`sicvar', 4970, 4979)
        
        * 33 = Whlsl (Wholesale)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 5000, 5199)
        
        * 34 = Rtail (Retail Stores)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 5200, 5999)
        
        * 35 = Money (Finance, Insurance, and Real Estate)
        replace `generate' = 35 if `touse' & inrange(`sicvar', 6000, 6999)
        
        * 36 = Srvc (Services)
        replace `generate' = 36 if `touse' & inrange(`sicvar', 7000, 8999)
        
        * 37 = Govt (Public Administration)
        replace `generate' = 37 if `touse' & inrange(`sicvar', 9000, 9999)
        
        * 38 = Other (Almost Nothing - catch-all)
        if `use_catchall' {
            replace `generate' = 38 if `touse' & `generate' == . & `sicvar' != .
        }
    }
end

*----------------------------------------------------------------------
* FF48 Industries (most commonly used)
*----------------------------------------------------------------------
program _sic_to_ff48
    args sicvar generate touse use_catchall
    
    quietly {
        * 1 = Agric (Agriculture)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 100, 199)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 200, 299)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 700, 799)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 910, 919)
        replace `generate' = 1 if `touse' & inrange(`sicvar', 2048, 2048)
        
        * 2 = Food (Food Products)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2000, 2009)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2010, 2019)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2020, 2029)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2030, 2039)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2040, 2046)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2050, 2059)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2060, 2063)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2070, 2079)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2090, 2095)
        replace `generate' = 2 if `touse' & inrange(`sicvar', 2098, 2099)
        
        * 3 = Soda (Candy and Soda)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 2064, 2068)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 2086, 2087)
        replace `generate' = 3 if `touse' & inrange(`sicvar', 2096, 2097)
        
        * 4 = Beer (Beer and Liquor)
        replace `generate' = 4 if `touse' & inrange(`sicvar', 2080, 2085)
        
        * 5 = Smoke (Tobacco Products)
        replace `generate' = 5 if `touse' & inrange(`sicvar', 2100, 2199)
        
        * 6 = Toys (Recreation)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 920, 999)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3650, 3652)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3732, 3732)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3930, 3931)
        replace `generate' = 6 if `touse' & inrange(`sicvar', 3940, 3949)
        
        * 7 = Fun (Entertainment) - using precise Ken French ranges
        replace `generate' = 7 if `touse' & inrange(`sicvar', 7800, 7833)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 7840, 7841)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 7900, 7900)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 7910, 7911)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 7920, 7933)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 7940, 7949)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 7980, 7980)
        replace `generate' = 7 if `touse' & inrange(`sicvar', 7990, 7999)
        
        * 8 = Books (Printing and Publishing)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 2700, 2709)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 2710, 2719)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 2720, 2729)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 2730, 2739)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 2740, 2749)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 2770, 2771)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 2780, 2789)
        replace `generate' = 8 if `touse' & inrange(`sicvar', 2790, 2799)
        
        * 9 = Hshld (Consumer Goods)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 2047, 2047)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 2391, 2392)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 2510, 2519)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 2590, 2599)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 2840, 2844)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3160, 3161)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3170, 3172)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3190, 3199)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3229, 3231)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3260, 3260)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3262, 3263)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3269, 3269)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3630, 3639)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3750, 3751)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3800, 3800)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3860, 3861)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3870, 3873)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3910, 3911)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3914, 3915)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3960, 3962)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3991, 3991)
        replace `generate' = 9 if `touse' & inrange(`sicvar', 3995, 3995)
        
        * 10 = Clths (Apparel)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 2300, 2390)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 3020, 3021)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 3100, 3111)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 3130, 3131)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 3140, 3149)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 3150, 3151)
        replace `generate' = 10 if `touse' & inrange(`sicvar', 3963, 3965)
        
        * 11 = Hlth (Healthcare)
        replace `generate' = 11 if `touse' & inrange(`sicvar', 8000, 8099)
        
        * 12 = MedEq (Medical Equipment)
        replace `generate' = 12 if `touse' & inrange(`sicvar', 3693, 3693)
        replace `generate' = 12 if `touse' & inrange(`sicvar', 3840, 3849)
        replace `generate' = 12 if `touse' & inrange(`sicvar', 3850, 3851)
        
        * 13 = Drugs (Pharmaceutical Products)
        replace `generate' = 13 if `touse' & inrange(`sicvar', 2830, 2831)
        replace `generate' = 13 if `touse' & inrange(`sicvar', 2833, 2836)
        
        * 14 = Chems (Chemicals)
        replace `generate' = 14 if `touse' & inrange(`sicvar', 2800, 2809)
        replace `generate' = 14 if `touse' & inrange(`sicvar', 2810, 2819)
        replace `generate' = 14 if `touse' & inrange(`sicvar', 2820, 2829)
        replace `generate' = 14 if `touse' & inrange(`sicvar', 2850, 2859)
        replace `generate' = 14 if `touse' & inrange(`sicvar', 2860, 2869)
        replace `generate' = 14 if `touse' & inrange(`sicvar', 2870, 2879)
        replace `generate' = 14 if `touse' & inrange(`sicvar', 2890, 2899)
        
        * 15 = Rubbr (Rubber and Plastic Products)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 3031, 3031)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 3041, 3041)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 3050, 3053)
        replace `generate' = 15 if `touse' & inrange(`sicvar', 3060, 3099)
        
        * 16 = Txtls (Textiles)
        replace `generate' = 16 if `touse' & inrange(`sicvar', 2200, 2284)
        replace `generate' = 16 if `touse' & inrange(`sicvar', 2290, 2295)
        replace `generate' = 16 if `touse' & inrange(`sicvar', 2297, 2299)
        replace `generate' = 16 if `touse' & inrange(`sicvar', 2393, 2395)
        replace `generate' = 16 if `touse' & inrange(`sicvar', 2397, 2399)
        
        * 17 = BldMt (Construction Materials)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 800, 899)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 2400, 2439)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 2450, 2459)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 2490, 2499)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 2660, 2661)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 2950, 2952)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 3200, 3200)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 3210, 3211)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 3240, 3241)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 3250, 3259)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 3261, 3261)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 3264, 3264)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 3270, 3275)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 3280, 3281)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 3290, 3293)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 3295, 3299)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 3420, 3433)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 3440, 3442)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 3446, 3446)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 3448, 3452)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 3490, 3499)
        replace `generate' = 17 if `touse' & inrange(`sicvar', 3996, 3996)
        
        * 18 = Cnstr (Construction)
        replace `generate' = 18 if `touse' & inrange(`sicvar', 1500, 1511)
        replace `generate' = 18 if `touse' & inrange(`sicvar', 1520, 1549)
        replace `generate' = 18 if `touse' & inrange(`sicvar', 1600, 1699)
        replace `generate' = 18 if `touse' & inrange(`sicvar', 1700, 1799)
        
        * 19 = Steel (Steel Works)
        replace `generate' = 19 if `touse' & inrange(`sicvar', 3300, 3300)
        replace `generate' = 19 if `touse' & inrange(`sicvar', 3310, 3317)
        replace `generate' = 19 if `touse' & inrange(`sicvar', 3320, 3325)
        replace `generate' = 19 if `touse' & inrange(`sicvar', 3330, 3341)
        replace `generate' = 19 if `touse' & inrange(`sicvar', 3350, 3357)
        replace `generate' = 19 if `touse' & inrange(`sicvar', 3360, 3379)
        replace `generate' = 19 if `touse' & inrange(`sicvar', 3390, 3399)
        
        * 20 = FabPr (Fabricated Products)
        replace `generate' = 20 if `touse' & inrange(`sicvar', 3400, 3400)
        replace `generate' = 20 if `touse' & inrange(`sicvar', 3443, 3444)
        replace `generate' = 20 if `touse' & inrange(`sicvar', 3460, 3479)
        
        * 21 = Mach (Machinery)
        replace `generate' = 21 if `touse' & inrange(`sicvar', 3510, 3536)
        replace `generate' = 21 if `touse' & inrange(`sicvar', 3538, 3538)
        replace `generate' = 21 if `touse' & inrange(`sicvar', 3540, 3569)
        replace `generate' = 21 if `touse' & inrange(`sicvar', 3580, 3582)
        replace `generate' = 21 if `touse' & inrange(`sicvar', 3585, 3586)
        replace `generate' = 21 if `touse' & inrange(`sicvar', 3589, 3599)
        
        * 22 = ElcEq (Electrical Equipment)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 3600, 3600)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 3610, 3613)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 3620, 3621)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 3623, 3629)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 3640, 3646)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 3648, 3649)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 3660, 3660)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 3690, 3692)
        replace `generate' = 22 if `touse' & inrange(`sicvar', 3699, 3699)
        
        * 23 = Autos (Automobiles and Trucks)
        replace `generate' = 23 if `touse' & inrange(`sicvar', 3710, 3711)
        replace `generate' = 23 if `touse' & inrange(`sicvar', 3713, 3716)
        replace `generate' = 23 if `touse' & inrange(`sicvar', 3790, 3792)
        replace `generate' = 23 if `touse' & inrange(`sicvar', 3799, 3799)
        
        * 24 = Aero (Aircraft)
        replace `generate' = 24 if `touse' & inrange(`sicvar', 3720, 3721)
        replace `generate' = 24 if `touse' & inrange(`sicvar', 3723, 3725)
        replace `generate' = 24 if `touse' & inrange(`sicvar', 3728, 3729)
        
        * 25 = Ships (Shipbuilding, Railroad Equipment)
        replace `generate' = 25 if `touse' & inrange(`sicvar', 3730, 3731)
        replace `generate' = 25 if `touse' & inrange(`sicvar', 3740, 3743)
        
        * 26 = Guns (Defense)
        replace `generate' = 26 if `touse' & inrange(`sicvar', 3760, 3769)
        replace `generate' = 26 if `touse' & inrange(`sicvar', 3795, 3795)
        replace `generate' = 26 if `touse' & inrange(`sicvar', 3480, 3489)
        
        * 27 = Gold (Precious Metals)
        replace `generate' = 27 if `touse' & inrange(`sicvar', 1040, 1049)
        
        * 28 = Mines (Non-Metallic and Industrial Metal Mining)
        replace `generate' = 28 if `touse' & inrange(`sicvar', 1000, 1039)
        replace `generate' = 28 if `touse' & inrange(`sicvar', 1050, 1119)
        replace `generate' = 28 if `touse' & inrange(`sicvar', 1400, 1499)
        
        * 29 = Coal
        replace `generate' = 29 if `touse' & inrange(`sicvar', 1200, 1299)
        
        * 30 = Oil (Petroleum and Natural Gas)
        replace `generate' = 30 if `touse' & inrange(`sicvar', 1300, 1300)
        replace `generate' = 30 if `touse' & inrange(`sicvar', 1310, 1339)
        replace `generate' = 30 if `touse' & inrange(`sicvar', 1370, 1382)
        replace `generate' = 30 if `touse' & inrange(`sicvar', 1389, 1389)
        replace `generate' = 30 if `touse' & inrange(`sicvar', 2900, 2912)
        replace `generate' = 30 if `touse' & inrange(`sicvar', 2990, 2999)
        
        * 31 = Util (Utilities)
        replace `generate' = 31 if `touse' & inrange(`sicvar', 4900, 4900)
        replace `generate' = 31 if `touse' & inrange(`sicvar', 4910, 4911)
        replace `generate' = 31 if `touse' & inrange(`sicvar', 4920, 4925)
        replace `generate' = 31 if `touse' & inrange(`sicvar', 4930, 4932)
        replace `generate' = 31 if `touse' & inrange(`sicvar', 4939, 4942)
        
        * 32 = Telcm (Communication)
        replace `generate' = 32 if `touse' & inrange(`sicvar', 4800, 4800)
        replace `generate' = 32 if `touse' & inrange(`sicvar', 4810, 4813)
        replace `generate' = 32 if `touse' & inrange(`sicvar', 4820, 4822)
        replace `generate' = 32 if `touse' & inrange(`sicvar', 4830, 4841)
        replace `generate' = 32 if `touse' & inrange(`sicvar', 4880, 4899)
        
        * 33 = PerSv (Personal Services)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7020, 7021)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7030, 7033)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7200, 7200)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7210, 7212)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7214, 7217)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7219, 7221)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7230, 7231)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7240, 7241)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7250, 7251)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7260, 7299)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7395, 7395)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7500, 7500)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7520, 7549)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7600, 7600)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7620, 7620)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7622, 7622)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7623, 7629)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7630, 7631)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7640, 7641)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7690, 7699)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 8100, 8199)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 8200, 8299)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 8300, 8399)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 8400, 8499)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 8600, 8699)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 8800, 8899)
        replace `generate' = 33 if `touse' & inrange(`sicvar', 7510, 7515)
        
        * 34 = BusSv (Business Services)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 2750, 2759)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 3993, 3993)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 7300, 7300)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 7310, 7342)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 7349, 7353)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 7359, 7372)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 7374, 7385)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 7389, 7394)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 7396, 7397)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 7399, 7399)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 7519, 7519)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 8700, 8700)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 8710, 8713)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 8720, 8721)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 8730, 8734)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 8740, 8748)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 8900, 8999)
        replace `generate' = 34 if `touse' & inrange(`sicvar', 4220, 4229)
        
        * 35 = Comps (Computers)
        replace `generate' = 35 if `touse' & inrange(`sicvar', 3570, 3579)
        replace `generate' = 35 if `touse' & inrange(`sicvar', 3680, 3689)
        replace `generate' = 35 if `touse' & inrange(`sicvar', 3695, 3695)
        replace `generate' = 35 if `touse' & inrange(`sicvar', 7373, 7373)
        
        * 36 = Chips (Electronic Equipment)
        replace `generate' = 36 if `touse' & inrange(`sicvar', 3622, 3622)
        replace `generate' = 36 if `touse' & inrange(`sicvar', 3661, 3666)
        replace `generate' = 36 if `touse' & inrange(`sicvar', 3669, 3669)
        replace `generate' = 36 if `touse' & inrange(`sicvar', 3670, 3679)
        replace `generate' = 36 if `touse' & inrange(`sicvar', 3810, 3810)
        replace `generate' = 36 if `touse' & inrange(`sicvar', 3812, 3812)
        
        * 37 = LabEq (Measuring and Control Equipment)
        replace `generate' = 37 if `touse' & inrange(`sicvar', 3811, 3811)
        replace `generate' = 37 if `touse' & inrange(`sicvar', 3820, 3827)
        replace `generate' = 37 if `touse' & inrange(`sicvar', 3829, 3839)
        
        * 38 = Paper (Paper Business Supplies)
        replace `generate' = 38 if `touse' & inrange(`sicvar', 2520, 2549)
        replace `generate' = 38 if `touse' & inrange(`sicvar', 2600, 2639)
        replace `generate' = 38 if `touse' & inrange(`sicvar', 2670, 2699)
        replace `generate' = 38 if `touse' & inrange(`sicvar', 2760, 2761)
        replace `generate' = 38 if `touse' & inrange(`sicvar', 3950, 3955)
        
        * 39 = Boxes (Shipping Containers)
        replace `generate' = 39 if `touse' & inrange(`sicvar', 2440, 2449)
        replace `generate' = 39 if `touse' & inrange(`sicvar', 2640, 2659)
        replace `generate' = 39 if `touse' & inrange(`sicvar', 3220, 3221)
        replace `generate' = 39 if `touse' & inrange(`sicvar', 3410, 3412)
        
        * 40 = Trans (Transportation)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4000, 4013)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4040, 4049)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4100, 4100)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4110, 4121)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4130, 4131)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4140, 4142)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4150, 4151)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4170, 4173)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4190, 4199)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4200, 4200)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4210, 4219)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4230, 4231)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4240, 4249)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4400, 4499)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4500, 4599)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4600, 4699)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4700, 4700)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4710, 4712)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4720, 4749)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4780, 4780)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4782, 4785)
        replace `generate' = 40 if `touse' & inrange(`sicvar', 4789, 4789)
        
        * 41 = Whlsl (Wholesale)
        replace `generate' = 41 if `touse' & inrange(`sicvar', 5000, 5000)
        replace `generate' = 41 if `touse' & inrange(`sicvar', 5010, 5015)
        replace `generate' = 41 if `touse' & inrange(`sicvar', 5020, 5023)
        replace `generate' = 41 if `touse' & inrange(`sicvar', 5030, 5060)
        replace `generate' = 41 if `touse' & inrange(`sicvar', 5063, 5065)
        replace `generate' = 41 if `touse' & inrange(`sicvar', 5070, 5078)
        replace `generate' = 41 if `touse' & inrange(`sicvar', 5080, 5088)
        replace `generate' = 41 if `touse' & inrange(`sicvar', 5090, 5094)
        replace `generate' = 41 if `touse' & inrange(`sicvar', 5099, 5100)
        replace `generate' = 41 if `touse' & inrange(`sicvar', 5110, 5113)
        replace `generate' = 41 if `touse' & inrange(`sicvar', 5120, 5122)
        replace `generate' = 41 if `touse' & inrange(`sicvar', 5130, 5172)
        replace `generate' = 41 if `touse' & inrange(`sicvar', 5180, 5182)
        replace `generate' = 41 if `touse' & inrange(`sicvar', 5190, 5199)
        
        * 42 = Rtail (Retail)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5200, 5200)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5210, 5231)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5250, 5251)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5260, 5261)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5270, 5271)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5300, 5300)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5310, 5311)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5320, 5320)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5330, 5331)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5334, 5334)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5340, 5349)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5390, 5400)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5410, 5412)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5420, 5469)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5490, 5500)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5510, 5579)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5590, 5700)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5710, 5722)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5730, 5736)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5750, 5750)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5900, 5900)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5910, 5912)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5920, 5932)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5940, 5990)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5992, 5995)
        replace `generate' = 42 if `touse' & inrange(`sicvar', 5999, 5999)
        
        * 43 = Meals (Restaurants, Hotels, Motels)
        replace `generate' = 43 if `touse' & inrange(`sicvar', 5800, 5813)
        replace `generate' = 43 if `touse' & inrange(`sicvar', 5890, 5890)
        replace `generate' = 43 if `touse' & inrange(`sicvar', 7000, 7000)
        replace `generate' = 43 if `touse' & inrange(`sicvar', 7010, 7019)
        replace `generate' = 43 if `touse' & inrange(`sicvar', 7040, 7049)
        replace `generate' = 43 if `touse' & inrange(`sicvar', 7213, 7213)
        
        * 44 = Banks (Banking)
        replace `generate' = 44 if `touse' & inrange(`sicvar', 6000, 6000)
        replace `generate' = 44 if `touse' & inrange(`sicvar', 6010, 6036)
        replace `generate' = 44 if `touse' & inrange(`sicvar', 6040, 6062)
        replace `generate' = 44 if `touse' & inrange(`sicvar', 6080, 6082)
        replace `generate' = 44 if `touse' & inrange(`sicvar', 6090, 6100)
        replace `generate' = 44 if `touse' & inrange(`sicvar', 6110, 6113)
        replace `generate' = 44 if `touse' & inrange(`sicvar', 6120, 6179)
        replace `generate' = 44 if `touse' & inrange(`sicvar', 6190, 6199)
        
        * 45 = Insur (Insurance)
        replace `generate' = 45 if `touse' & inrange(`sicvar', 6300, 6300)
        replace `generate' = 45 if `touse' & inrange(`sicvar', 6310, 6331)
        replace `generate' = 45 if `touse' & inrange(`sicvar', 6350, 6351)
        replace `generate' = 45 if `touse' & inrange(`sicvar', 6360, 6361)
        replace `generate' = 45 if `touse' & inrange(`sicvar', 6370, 6379)
        replace `generate' = 45 if `touse' & inrange(`sicvar', 6390, 6411)
        
        * 46 = RlEst (Real Estate)
        replace `generate' = 46 if `touse' & inrange(`sicvar', 6500, 6500)
        replace `generate' = 46 if `touse' & inrange(`sicvar', 6510, 6553)
        replace `generate' = 46 if `touse' & inrange(`sicvar', 6590, 6599)
        replace `generate' = 46 if `touse' & inrange(`sicvar', 6610, 6611)
        
        * 47 = Fin (Trading)
        replace `generate' = 47 if `touse' & inrange(`sicvar', 6200, 6299)
        replace `generate' = 47 if `touse' & inrange(`sicvar', 6700, 6700)
        replace `generate' = 47 if `touse' & inrange(`sicvar', 6710, 6726)
        replace `generate' = 47 if `touse' & inrange(`sicvar', 6730, 6733)
        replace `generate' = 47 if `touse' & inrange(`sicvar', 6740, 6779)
        replace `generate' = 47 if `touse' & inrange(`sicvar', 6790, 6799)
        
        * 48 = Other (explicit Ken French mapping)
        * Siccodes48: 4950-4959, 4960-4961, 4970-4971, 4990-4991
        replace `generate' = 48 if `touse' & inrange(`sicvar', 4950, 4959)
        replace `generate' = 48 if `touse' & inrange(`sicvar', 4960, 4961)
        replace `generate' = 48 if `touse' & inrange(`sicvar', 4970, 4971)
        replace `generate' = 48 if `touse' & inrange(`sicvar', 4990, 4991)

        * Optional catch-all for any remaining valid SICs
        if `use_catchall' {
            replace `generate' = 48 if `touse' & `generate' == . & `sicvar' != .
        }
    }
end

*----------------------------------------------------------------------
* FF49 Industries
* FF49 = FF48 + Software industry (SIC 7370-7373, 7375) carved from BusSv/Comps
* Per Ken French's changes_ind documentation
*----------------------------------------------------------------------
program _sic_to_ff49
    args sicvar generate touse use_catchall
    
    quietly {
        * Start with FF48 classification (but without catch-all)
        _sic_to_ff48 `sicvar' `generate' `touse' 0
        
        * Renumber industries 36-48 to 37-49 to make room for Software at 36
        * Work backwards to avoid overwriting
        replace `generate' = 49 if `touse' & `generate' == 48
        replace `generate' = 48 if `touse' & `generate' == 47
        replace `generate' = 47 if `touse' & `generate' == 46
        replace `generate' = 46 if `touse' & `generate' == 45
        replace `generate' = 45 if `touse' & `generate' == 44
        replace `generate' = 44 if `touse' & `generate' == 43
        replace `generate' = 43 if `touse' & `generate' == 42
        replace `generate' = 42 if `touse' & `generate' == 41
        replace `generate' = 41 if `touse' & `generate' == 40
        replace `generate' = 40 if `touse' & `generate' == 39
        replace `generate' = 39 if `touse' & `generate' == 38
        replace `generate' = 38 if `touse' & `generate' == 37
        replace `generate' = 37 if `touse' & `generate' == 36
        
        * Create new industry 36 = Softw (Computer Software)
        * Per Ken French: SIC 7370-7373, 7375
        * Note: 7374 (Computer Processing) stays in BusSv, not Software
        replace `generate' = 36 if `touse' & inrange(`sicvar', 7370, 7373)
        replace `generate' = 36 if `touse' & inrange(`sicvar', 7375, 7375)
        
        * 49 = Other (only if nomissing specified)
        if `use_catchall' {
            replace `generate' = 49 if `touse' & `generate' == . & `sicvar' != .
        }
    }
end

*----------------------------------------------------------------------
* Apply Value Labels
*----------------------------------------------------------------------
program _apply_ff_labels
    args varname scheme
    
    capture label drop `varname'_lbl
    
    if "`scheme'" == "5" {
        label define `varname'_lbl ///
            1 "Cnsmr" ///
            2 "Manuf" ///
            3 "HiTec" ///
            4 "Hlth" ///
            5 "Other"
    }
    else if "`scheme'" == "10" {
        label define `varname'_lbl ///
            1 "NoDur" ///
            2 "Durbl" ///
            3 "Manuf" ///
            4 "Enrgy" ///
            5 "HiTec" ///
            6 "Telcm" ///
            7 "Shops" ///
            8 "Hlth" ///
            9 "Utils" ///
            10 "Other"
    }
    else if "`scheme'" == "12" {
        label define `varname'_lbl ///
            1 "NoDur" ///
            2 "Durbl" ///
            3 "Manuf" ///
            4 "Enrgy" ///
            5 "Chems" ///
            6 "BusEq" ///
            7 "Telcm" ///
            8 "Utils" ///
            9 "Shops" ///
            10 "Hlth" ///
            11 "Money" ///
            12 "Other"
    }
    else if "`scheme'" == "17" {
        label define `varname'_lbl ///
            1 "Food" ///
            2 "Mines" ///
            3 "Oil" ///
            4 "Clths" ///
            5 "Durbl" ///
            6 "Chems" ///
            7 "Cnsum" ///
            8 "Cnstr" ///
            9 "Steel" ///
            10 "FabPr" ///
            11 "Machn" ///
            12 "Cars" ///
            13 "Trans" ///
            14 "Utils" ///
            15 "Rtail" ///
            16 "Finan" ///
            17 "Other"
    }
    else if "`scheme'" == "30" {
        * Updated to match Ken French Siccodes30.txt
        label define `varname'_lbl ///
            1 "Food" ///
            2 "Beer" ///
            3 "Smoke" ///
            4 "Games" ///
            5 "Books" ///
            6 "Hshld" ///
            7 "Clths" ///
            8 "Hlth" ///
            9 "Chems" ///
            10 "Txtls" ///
            11 "Cnstr" ///
            12 "Steel" ///
            13 "FabPr" ///
            14 "ElcEq" ///
            15 "Autos" ///
            16 "Carry" ///
            17 "Mines" ///
            18 "Coal" ///
            19 "Oil" ///
            20 "Util" ///
            21 "Telcm" ///
            22 "Servs" ///
            23 "BusEq" ///
            24 "Paper" ///
            25 "Trans" ///
            26 "Whlsl" ///
            27 "Rtail" ///
            28 "Meals" ///
            29 "Fin" ///
            30 "Other"
    }
    else if "`scheme'" == "38" {
        * Ken French's FF38 is a simple 2-digit SIC scheme
        label define `varname'_lbl ///
            1 "Agric" ///
            2 "Mines" ///
            3 "Oil" ///
            4 "Stone" ///
            5 "Cnstr" ///
            6 "Food" ///
            7 "Smoke" ///
            8 "Txtls" ///
            9 "Apprl" ///
            10 "Wood" ///
            11 "Chair" ///
            12 "Paper" ///
            13 "Print" ///
            14 "Chems" ///
            15 "Ptrlm" ///
            16 "Rubbr" ///
            17 "Lethr" ///
            18 "Glass" ///
            19 "Metal" ///
            20 "MtlPr" ///
            21 "Machn" ///
            22 "Elctr" ///
            23 "Cars" ///
            24 "Instr" ///
            25 "Manuf" ///
            26 "Trans" ///
            27 "Phone" ///
            28 "TV" ///
            29 "Utils" ///
            30 "Garbg" ///
            31 "Steam" ///
            32 "Water" ///
            33 "Whlsl" ///
            34 "Rtail" ///
            35 "Money" ///
            36 "Srvc" ///
            37 "Govt" ///
            38 "Other"
    }
    else if "`scheme'" == "48" {
        label define `varname'_lbl ///
            1 "Agric" ///
            2 "Food" ///
            3 "Soda" ///
            4 "Beer" ///
            5 "Smoke" ///
            6 "Toys" ///
            7 "Fun" ///
            8 "Books" ///
            9 "Hshld" ///
            10 "Clths" ///
            11 "Hlth" ///
            12 "MedEq" ///
            13 "Drugs" ///
            14 "Chems" ///
            15 "Rubbr" ///
            16 "Txtls" ///
            17 "BldMt" ///
            18 "Cnstr" ///
            19 "Steel" ///
            20 "FabPr" ///
            21 "Mach" ///
            22 "ElcEq" ///
            23 "Autos" ///
            24 "Aero" ///
            25 "Ships" ///
            26 "Guns" ///
            27 "Gold" ///
            28 "Mines" ///
            29 "Coal" ///
            30 "Oil" ///
            31 "Util" ///
            32 "Telcm" ///
            33 "PerSv" ///
            34 "BusSv" ///
            35 "Comps" ///
            36 "Chips" ///
            37 "LabEq" ///
            38 "Paper" ///
            39 "Boxes" ///
            40 "Trans" ///
            41 "Whlsl" ///
            42 "Rtail" ///
            43 "Meals" ///
            44 "Banks" ///
            45 "Insur" ///
            46 "RlEst" ///
            47 "Fin" ///
            48 "Other"
    }
    else if "`scheme'" == "49" {
        * Per Ken French: FF49 labels with Software at 36, Other at 49
        label define `varname'_lbl ///
            1 "Agric" ///
            2 "Food" ///
            3 "Soda" ///
            4 "Beer" ///
            5 "Smoke" ///
            6 "Toys" ///
            7 "Fun" ///
            8 "Books" ///
            9 "Hshld" ///
            10 "Clths" ///
            11 "Hlth" ///
            12 "MedEq" ///
            13 "Drugs" ///
            14 "Chems" ///
            15 "Rubbr" ///
            16 "Txtls" ///
            17 "BldMt" ///
            18 "Cnstr" ///
            19 "Steel" ///
            20 "FabPr" ///
            21 "Mach" ///
            22 "ElcEq" ///
            23 "Autos" ///
            24 "Aero" ///
            25 "Ships" ///
            26 "Guns" ///
            27 "Gold" ///
            28 "Mines" ///
            29 "Coal" ///
            30 "Oil" ///
            31 "Util" ///
            32 "Telcm" ///
            33 "PerSv" ///
            34 "BusSv" ///
            35 "Hardw" ///
            36 "Softw" ///
            37 "Chips" ///
            38 "LabEq" ///
            39 "Paper" ///
            40 "Boxes" ///
            41 "Trans" ///
            42 "Whlsl" ///
            43 "Rtail" ///
            44 "Meals" ///
            45 "Banks" ///
            46 "Insur" ///
            47 "RlEst" ///
            48 "Fin" ///
            49 "Other"
    }
    
    label values `varname' `varname'_lbl
end
