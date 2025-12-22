*! version 1.0  19dec2025  Kelvin Law
*! Converts NAICS codes to Fama-French industry classifications
*! Uses Dorn crosswalk + Census concordance + concordance chain for NAICS->SIC
*! Then calls sic_to_ff for SIC->FF classification
*!
*! Features:
*!   - Handles both numeric and string NAICS codes
*!   - 1,463 NAICS codes mapped (covers NAICS 1997-2022 vintages)
*!   - 99.8% coverage of NAICS 2022 codes via concordance chaining
*!   - fallback() option: use SIC variable when NAICS mapping fails
*!   - compustat() option: market-cap weighted NAICS->SIC from user data
*!   - method() options: maxweight (default), skipaux, first
*!   - compare() for validation against SIC-based classification
*!   - Supports FF5, FF10, FF12, FF17, FF30, FF38, FF48, and FF49 schemes
*!   - Returns detailed r() results for programmatic use
*!
*! Requirements:
*!   - sic_to_ff v1.1 or later must be installed
*!   - NAICS-to-SIC mapping data is embedded (no external .dta needed)
*!
*! Reference:
*!   Dorn crosswalk: Autor, Dorn & Hanson (2013) AER
*!   Census concordance: 2002 NAICS to 1987 SIC
*!   FF industries: Ken French Data Library

program naics_to_ff, rclass sortpreserve
    version 14.0

    syntax varname [if] [in], GENerate(name) ///
        [SCHeme(string) LABels REPlace NOMISSING DIAGnostics ///
         SICgen(name) SOURCEgen(name) WEIGHTgen(name) COMPare(varname) ///
         METHod(string) FALLback(varname) ///
         COMPUstat(string) YEARvar(varname) CYear(integer 0) NOFALLback]

    * Check that sic_to_ff is installed
    capture which sic_to_ff
    if _rc != 0 {
        display as error "naics_to_ff requires sic_to_ff to be installed"
        display as error "Install it first, then re-run naics_to_ff"
        exit 111
    }
    local __sic_path "`r(which)'"
    if "`__sic_path'" == "" local __sic_path "`r(fn)'"
    if "`__sic_path'" == "" {
        quietly capture findfile sic_to_ff.ado
        if _rc == 0 local __sic_path "`r(fn)'"
    }
    if "`__sic_path'" == "" {
        display as error "naics_to_ff could not locate sic_to_ff.ado on adopath"
        exit 111
    }

    * Lightweight version check using Stata file read (no Mata - avoids r(3000))
    * Parse first 10 lines of sic_to_ff.ado looking for "*! version X.Y"
    local __sic_version ""
    local __sic_major = 0
    local __sic_minor = 0
    tempname __fh
    capture file open `__fh' using "`__sic_path'", read text
    if _rc == 0 {
        forvalues __i = 1/20 {
            file read `__fh' __line
            if r(eof) continue, break
            * Look for version line using strpos (relaxed to handle BOM/leading chars)
            local __pos = strpos(`"`__line'"', "*! version ")
            if `__pos' >= 1 {
                * Extract version string after "*! version " (11 chars from position)
                local __verstr = substr(`"`__line'"', `__pos' + 11, .)
                * Extract major version (before first dot)
                local __dotpos = strpos("`__verstr'", ".")
                if `__dotpos' > 0 {
                    local __sic_major = substr("`__verstr'", 1, `__dotpos' - 1)
                    * Extract minor version (after dot, before space)
                    local __after_dot = substr("`__verstr'", `__dotpos' + 1, .)
                    local __spacepos = strpos("`__after_dot'", " ")
                    if `__spacepos' > 0 {
                        local __sic_minor = substr("`__after_dot'", 1, `__spacepos' - 1)
                    }
                    else {
                        local __sic_minor = "`__after_dot'"
                    }
                    * Handle X.Y.Z format - extract just the first number after dot
                    local __dotpos2 = strpos("`__sic_minor'", ".")
                    if `__dotpos2' > 0 {
                        local __sic_minor = substr("`__sic_minor'", 1, `__dotpos2' - 1)
                    }
                    local __sic_version "`__sic_major'.`__sic_minor'"
                    continue, break
                }
            }
        }
        file close `__fh'
    }

    * Check version: require >= 1.1
    local __version_ok = 0
    if `__sic_major' > 1 {
        local __version_ok = 1
    }
    else if `__sic_major' == 1 & `__sic_minor' >= 1 {
        local __version_ok = 1
    }
    if `__version_ok' == 0 {
        display as error "naics_to_ff requires sic_to_ff version 1.1 or later"
        if "`__sic_version'" != "" {
            display as error "Detected sic_to_ff version: `__sic_version'"
        }
        else {
            display as error "Could not detect sic_to_ff version"
        }
        exit 111
    }

    * Set default scheme to FF48
    if "`scheme'" == "" {
        local scheme "48"
    }

    * Validate scheme
    if !inlist("`scheme'", "5", "10", "12", "17", "30", "38", "48", "49") {
        display as error "scheme() must be one of: 5, 10, 12, 17, 30, 38, 48, or 49"
        exit 198
    }

    * Set default method and validate
    if "`method'" == "" {
        local method "maxweight"
    }
    if !inlist("`method'", "maxweight", "skipaux", "first") {
        display as error "method() must be one of: maxweight, skipaux, or first"
        exit 198
    }

    * Validation for compustat() option
    local use_compustat = 0
    if "`compustat'" != "" {
        local use_compustat = 1

        * Check file exists
        capture confirm file "`compustat'"
        if _rc != 0 {
            display as error "compustat(): file not found: `compustat'"
            exit 601
        }

        * Require yearvar() OR cyear() (not both, not neither)
        if "`yearvar'" == "" & `cyear' == 0 {
            display as error "compustat() requires either yearvar() or cyear() to specify weight timing"
            exit 198
        }
        if "`yearvar'" != "" & `cyear' != 0 {
            display as error "yearvar() and cyear() are mutually exclusive"
            exit 198
        }
        if `cyear' < 0 {
            display as error "cyear() must be a positive year (e.g., cyear(2020))"
            exit 198
        }

        * Validate yearvar exists in user's data and is numeric
        if "`yearvar'" != "" {
            capture confirm variable `yearvar'
            if _rc != 0 {
                display as error "yearvar(`yearvar'): variable not found in current dataset"
                exit 111
            }
            capture confirm numeric variable `yearvar'
            if _rc != 0 {
                display as error "yearvar(`yearvar'): variable must be numeric, found string"
                display as error "Please destring `yearvar' before using with yearvar()"
                exit 109
            }
        }

        * compustat() only works with method(maxweight)
        if "`method'" != "maxweight" {
            display as error "method(`method') is not compatible with compustat()"
            display as error "compustat() requires method(maxweight) (the default)"
            exit 198
        }
    }
    else {
        * Error if yearvar/cyear/nofallback used without compustat()
        if "`yearvar'" != "" {
            display as error "yearvar() requires compustat() to be specified"
            exit 198
        }
        if `cyear' != 0 {
            display as error "cyear() requires compustat() to be specified"
            exit 198
        }
        if "`nofallback'" != "" {
            display as error "nofallback requires compustat() to be specified"
            exit 198
        }
    }

    * CRITICAL: Block destructive name collisions before any variable operations
    * This prevents data loss if generate() equals input variable or other conflicts
    if "`generate'" == "`varlist'" {
        display as error "generate() must differ from the input NAICS variable"
        display as error "You specified: generate(`generate') on variable `varlist'"
        exit 198
    }
    if "`compare'" != "" & "`generate'" == "`compare'" {
        display as error "generate() must differ from the compare() variable"
        exit 198
    }
    * Check auxiliary output variables for conflicts
    foreach auxvar in sicgen sourcegen weightgen {
        local auxval = "``auxvar''"
        if "`auxval'" != "" {
            * Cannot equal input variable
            if "`auxval'" == "`varlist'" {
                display as error "`auxvar'() must differ from the input NAICS variable"
                exit 198
            }
            * Cannot equal generate variable
            if "`auxval'" == "`generate'" {
                display as error "`auxvar'() must differ from generate()"
                exit 198
            }
            * Cannot equal compare variable
            if "`compare'" != "" & "`auxval'" == "`compare'" {
                display as error "`auxvar'() must differ from compare()"
                exit 198
            }
        }
    }
    * Check for duplicates among auxiliary output variables
    if "`sicgen'" != "" & "`sourcegen'" != "" & "`sicgen'" == "`sourcegen'" {
        display as error "sicgen() and sourcegen() must have different names"
        exit 198
    }
    if "`sicgen'" != "" & "`weightgen'" != "" & "`sicgen'" == "`weightgen'" {
        display as error "sicgen() and weightgen() must have different names"
        exit 198
    }
    if "`sourcegen'" != "" & "`weightgen'" != "" & "`sourcegen'" == "`weightgen'" {
        display as error "sourcegen() and weightgen() must have different names"
        exit 198
    }
    * Block reserved internal variable names (prevents poisoning future runs)
    foreach reservedname in __n2f_sic __n2f_w __n2f_src {
        foreach optname in generate sicgen sourcegen weightgen {
            if "``optname''" == "`reservedname'" {
                display as error "`optname'(`reservedname') uses a reserved internal name"
                display as error "Please choose a different variable name"
                exit 198
            }
        }
    }
    * Block fallback() collisions with output names (prevents dropping fallback before use)
    if "`fallback'" != "" {
        if "`fallback'" == "`generate'" {
            display as error "fallback() cannot be the same as generate()"
            display as error "The fallback variable would be dropped before it can be used"
            exit 198
        }
        foreach auxvar in sicgen sourcegen weightgen {
            if "``auxvar''" != "" & "`fallback'" == "``auxvar''" {
                display as error "fallback() cannot be the same as `auxvar'()"
                display as error "With replace, the fallback variable would be dropped before it can be used"
                exit 198
            }
        }
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
        }
    }

    * Mark sample
    marksample touse, novarlist

    * Get the NAICS variable
    local naicsvar "`varlist'"

    * Create working NAICS variable (handles both string and numeric)
    * String cleaning: removes leading/trailing whitespace, internal spaces, and hyphens
    tempvar naics_num naics_clean naics_raw
    local n_parse_failed = 0
    local n_fractional = 0
    local n_range_pattern = 0
    capture confirm string variable `naicsvar'
    if _rc == 0 {
        * NAICS is string - clean and convert to numeric
        quietly generate str20 `naics_clean' = trim(`naicsvar') if `touse'
        
        * Treat Stata missing indicators (".", ".a", ".b", etc.) as missing, not parse-fail
        quietly replace `naics_clean' = "" if `touse' & regexm(`naics_clean', "^\.[a-z]?$")
        
        * Detect range patterns (e.g., "31-33", "44-45") BEFORE removing hyphens
        * Treat as missing only when the hyphenated digits do NOT form a 6-digit code
        * (e.g., "31-33" is a sector range; "541-711" is treated as a formatting variant of 541711)
        tempvar is_range __n2f_rangecheck
        quietly generate str40 `__n2f_rangecheck' = `naics_clean' if `touse'
        quietly replace `__n2f_rangecheck' = subinstr(`__n2f_rangecheck', " ", "", .) if `touse'
        quietly replace `__n2f_rangecheck' = subinstr(`__n2f_rangecheck', char(9), "", .) if `touse'
        quietly replace `__n2f_rangecheck' = subinstr(`__n2f_rangecheck', ",", "", .) if `touse'
        quietly generate byte `is_range' = regexm(`__n2f_rangecheck', "^[0-9]+-[0-9]+$") ///
            & strlen(subinstr(`__n2f_rangecheck', "-", "", .)) != 6 if `touse'
        quietly count if `touse' & `is_range' == 1
        local n_range_pattern = r(N)
        if `n_range_pattern' > 0 {
            display as text "  Warning: " as result `n_range_pattern' as text " observations have NAICS range patterns (e.g., '31-33'); treated as missing"
            quietly replace `naics_clean' = "" if `touse' & `is_range' == 1
        }
        drop `is_range' `__n2f_rangecheck'
        
        * Clean standard formatting issues
        quietly replace `naics_clean' = subinstr(`naics_clean', " ", "", .) if `touse'
        quietly replace `naics_clean' = subinstr(`naics_clean', ",", "", .) if `touse'  // handles "541,711"
        quietly replace `naics_clean' = subinstr(`naics_clean', "-", "", .) if `touse'  // handles "541-711" format
        quietly replace `naics_clean' = subinstr(`naics_clean', char(9), "", .) if `touse'  // tab character
        
        * First parse to double to detect fractional values
        quietly generate double `naics_raw' = real(`naics_clean') if `touse'
        * Count non-empty strings that failed to parse as numeric
        * (exclude empty strings which represent intentional missing)
        quietly count if `touse' & `naics_clean' != "" & `naics_raw' >= .
        local n_parse_failed = r(N)
        if `n_parse_failed' > 0 {
            display as text "  Warning: " as result `n_parse_failed' as text " observations have non-numeric NAICS values (ignored)"
        }
        * Detect and normalize dot-as-thousand-separator (e.g., "541.711" → 541711)
        * Strict check: original string must have EXACTLY 3 digits after decimal
        * Note: Stata regexm() doesn't support {n} quantifiers
        tempvar is_thousand_sep
        quietly generate byte `is_thousand_sep' = regexm(`naics_clean', "^[0-9]+[.][0-9][0-9][0-9]$") ///
            & floor(`naics_raw' * 1000) >= 100000 ///
            & floor(`naics_raw' * 1000) <= 999999 if `touse'
        quietly count if `touse' & `is_thousand_sep' == 1
        local n_thousand_sep = r(N)
        if `n_thousand_sep' > 0 {
            quietly replace `naics_raw' = `naics_raw' * 1000 if `touse' & `is_thousand_sep' == 1
        }
        drop `is_thousand_sep'

        * Count remaining fractional values (true decimals, not thousand-separator)
        quietly count if `touse' & `naics_raw' < . & floor(`naics_raw') != `naics_raw'
        local n_fractional = r(N)
        local n_thousand_sep_pattern = `n_thousand_sep'

        * Now convert to long using explicit floor() (not relying on implicit truncation)
        quietly generate long `naics_num' = floor(`naics_raw') if `touse'
        drop `naics_clean' `naics_raw'
    }
    else {
        * NAICS is numeric - detect and normalize dot-as-thousand-separator
        * Note: Cannot distinguish 541.71 from 541.710 in numeric form, but
        * if x*1000 is an integer in valid 6-digit range, assume thousand-separator
        tempvar naics_work is_thousand_sep
        quietly generate double `naics_work' = `naicsvar' if `touse'
        quietly generate byte `is_thousand_sep' = (`naics_work' < . ///
            & floor(`naics_work') != `naics_work' ///
            & abs(mod(`naics_work' * 1000, 1)) < 0.0001 ///
            & floor(`naics_work' * 1000) >= 100000 ///
            & floor(`naics_work' * 1000) <= 999999) if `touse'
        quietly count if `touse' & `is_thousand_sep' == 1
        local n_thousand_sep = r(N)
        if `n_thousand_sep' > 0 {
            quietly replace `naics_work' = `naics_work' * 1000 if `touse' & `is_thousand_sep' == 1
        }
        drop `is_thousand_sep'

        * Count remaining fractional values (true decimals, not thousand-separator)
        quietly count if `touse' & `naics_work' < . & floor(`naics_work') != `naics_work'
        local n_fractional = r(N)
        local n_thousand_sep_pattern = `n_thousand_sep'

        * Convert to long using explicit floor() (not relying on implicit truncation)
        quietly generate long `naics_num' = floor(`naics_work') if `touse'
        drop `naics_work'
    }

    * Count observations in sample
    quietly count if `touse'
    local n_total = r(N)

    quietly count if `touse' & `naics_num' < .
    local n_with_naics = r(N)

    * Warn about non-6-digit NAICS codes
    quietly count if `touse' & `naics_num' < . & (`naics_num' < 100000 | `naics_num' > 999999)
    local n_bad_digits = r(N)
    if `n_bad_digits' > 0 {
        display as text "  Warning: " as result `n_bad_digits' as text " observations have non-6-digit NAICS codes"
    }

    * Warn about fractional/decimal NAICS codes
    if `n_fractional' > 0 {
        display as text "  Warning: " as result `n_fractional' as text " observations have fractional NAICS codes (truncated)"
    }

    * Create SIC variable from NAICS mapping using merge
    tempvar sic_mapped mapping_weight mapping_source
    quietly generate long `sic_mapped' = .
    quietly generate double `mapping_weight' = .
    quietly generate str10 `mapping_source' = ""

    * Track Compustat-specific mapping counts
    local n_compustat_mapped = 0
    local n_dorn_fallback = 0

    * Apply NAICS to SIC mapping via merge
    if `use_compustat' == 1 {
        * Build Compustat market-cap weighted mapping
        tempfile compustat_map
        _build_compustat_mapping "`compustat'" `cyear' "`compustat_map'" "`yearvar'"

        * Merge with Compustat mapping
        _naics_to_sic_merge_compustat `naics_num' `sic_mapped' `mapping_weight' `mapping_source' `touse' "`compustat_map'" "`yearvar'" `cyear'

        * Count Compustat-mapped observations
        quietly count if `touse' & `mapping_source' == "compustat" & `sic_mapped' < .
        local n_compustat_mapped = r(N)

        * Fallback to Dorn for unmapped (unless nofallback specified)
        if "`nofallback'" == "" {
            * Use Dorn mapping for observations still missing SIC
            _naics_to_sic_merge `naics_num' `sic_mapped' `mapping_weight' `mapping_source' `touse' "maxweight"

            * Count how many were filled by Dorn fallback
            quietly count if `touse' & `mapping_source' == "dorn" & `sic_mapped' < .
            local n_dorn_fallback = r(N)
            quietly count if `touse' & `mapping_source' == "census" & `sic_mapped' < .
            local n_dorn_fallback = `n_dorn_fallback' + r(N)
            quietly count if `touse' & `mapping_source' == "manual" & `sic_mapped' < .
            local n_dorn_fallback = `n_dorn_fallback' + r(N)
        }
    }
    else {
        * Default: Uses embedded Dorn/Census employment-weighted mapping
        _naics_to_sic_merge `naics_num' `sic_mapped' `mapping_weight' `mapping_source' `touse' `method'
    }

    * Guard against auxiliary SIC codes (>9999) that would crash sic_to_ff
    * These occur in the Dorn crosswalk for certain NAICS (e.g., 493xxx warehousing,
    * 551114 holding companies, 950000 government). Treat as unmapped.
    * Also clear mapping_source/weight so fallback can correctly fill them
    quietly replace `mapping_source' = "" if `touse' & `sic_mapped' > 9999
    quietly replace `mapping_weight' = . if `touse' & `sic_mapped' > 9999
    quietly replace `sic_mapped' = . if `touse' & `sic_mapped' > 9999

    * Count NAICS mapping results BEFORE fallback (for accurate statistics)
    quietly count if `touse' & `naics_num' < . & `sic_mapped' < .
    local n_naics_mapped = r(N)

    quietly count if `touse' & `naics_num' < . & `sic_mapped' >= .
    local n_naics_unmapped = r(N)

    * Apply fallback for observations still missing SIC
    * Fallback applies when NAICS is missing OR present but unmapped
    * Use marker approach: explicitly track fallback-used rows and overwrite source/weight
    local n_fallback = 0
    if "`fallback'" != "" {
        tempvar fb_used
        capture confirm numeric variable `fallback'
        if _rc == 0 {
            * Numeric fallback (e.g., sich)
            quietly gen byte `fb_used' = (`touse' & `sic_mapped' >= . & `fallback' < . & inrange(`fallback', 1, 9999))
            quietly count if `fb_used'
            local n_fallback = r(N)
            if `n_fallback' > 0 {
                quietly replace `sic_mapped' = `fallback' if `fb_used'
                * Overwrite source/weight unconditionally for fallback rows
                quietly replace `mapping_source' = "fallback" if `fb_used'
                quietly replace `mapping_weight' = . if `fb_used'
            }
        }
        else {
            * String fallback - convert to numeric (with trim for whitespace handling)
            quietly gen byte `fb_used' = (`touse' & `sic_mapped' >= . & trim(`fallback') != "" & real(trim(`fallback')) < . & inrange(real(trim(`fallback')), 1, 9999))
            quietly count if `fb_used'
            local n_fallback = r(N)
            if `n_fallback' > 0 {
                quietly replace `sic_mapped' = real(trim(`fallback')) if `fb_used'
                * Overwrite source/weight unconditionally for fallback rows
                quietly replace `mapping_source' = "fallback" if `fb_used'
                quietly replace `mapping_weight' = . if `fb_used'
            }
        }
        drop `fb_used'
    }

    * Report NAICS to SIC mapping results
    if `n_naics_unmapped' > 0 {
        display as text "Note: " as result `n_naics_unmapped' as text " NAICS codes could not be mapped to SIC"
    }

    * If labels are requested, ensure the value label name that sic_to_ff will create
    * (typically `generate'_lbl) does not collide with labels used by other variables.
    * If it is in use elsewhere, copy it and reassign those variables before dropping.
    if "`labels'" != "" {
        local __n2f_target_lbl "`generate'_lbl"
        quietly capture label list `__n2f_target_lbl'
        if _rc == 0 {
            quietly ds, has(vallabel `__n2f_target_lbl')
            local __n2f_lbl_users "`r(varlist)'"
            local __n2f_lbl_others : list __n2f_lbl_users - generate
            if "`__n2f_lbl_others'" != "" {
                tempname __n2f_lbl_backup
                capture label copy `__n2f_target_lbl' `__n2f_lbl_backup'
                if _rc != 0 {
                    display as error "Value label collision: `__n2f_target_lbl' is used by other variables"
                    display as error "Unable to preserve existing label definitions; run without labels or resolve the collision"
                    exit 198
                }
                foreach __v of local __n2f_lbl_others {
                    label values `__v' `__n2f_lbl_backup'
                }
            }
            capture label drop `__n2f_target_lbl'
        }
    }

    * Build options for sic_to_ff call
    local sic_opts = ""
    if "`labels'" != "" local sic_opts "`sic_opts' labels"
    if "`nomissing'" != "" local sic_opts "`sic_opts' nomissing"

    * Call sic_to_ff to map SIC to FF industry
    * Use quietly to suppress sic_to_ff output (naics_to_ff has its own reporting)
    quietly sic_to_ff `sic_mapped' if `touse', generate(`generate') scheme(`scheme') `sic_opts' replace

    * Generate optional output variables for mapping transparency
    if "`sicgen'" != "" {
        capture confirm variable `sicgen'
        if _rc == 0 & "`replace'" == "" {
            display as error "variable `sicgen' already exists; use replace option"
            exit 110
        }
        capture drop `sicgen'
        quietly generate long `sicgen' = `sic_mapped' if `touse'
        label variable `sicgen' "SIC code mapped from NAICS"
    }
    if "`sourcegen'" != "" {
        capture confirm variable `sourcegen'
        if _rc == 0 & "`replace'" == "" {
            display as error "variable `sourcegen' already exists; use replace option"
            exit 110
        }
        capture drop `sourcegen'
        quietly generate str10 `sourcegen' = `mapping_source' if `touse'
        label variable `sourcegen' "NAICS-SIC mapping source"
    }
    if "`weightgen'" != "" {
        capture confirm variable `weightgen'
        if _rc == 0 & "`replace'" == "" {
            display as error "variable `weightgen' already exists; use replace option"
            exit 110
        }
        capture drop `weightgen'
        quietly generate double `weightgen' = `mapping_weight' if `touse'
        label variable `weightgen' "NAICS-SIC mapping weight"
    }

    * Compare with SIC-based classification if requested
    if "`compare'" != "" {
        * sic_to_ff accepts both string and numeric SIC variables
        tempvar ff_from_sic compare_sic_clean
        * Sanitize compare SIC (filter aux codes >9999 and invalid values to missing)
        capture confirm numeric variable `compare'
        if _rc == 0 {
            quietly gen long `compare_sic_clean' = `compare' if `touse'
            quietly replace `compare_sic_clean' = . if `compare_sic_clean' > 9999 | `compare_sic_clean' < 0
        }
        else {
            quietly gen long `compare_sic_clean' = real(trim(`compare')) if `touse'
            quietly replace `compare_sic_clean' = . if `compare_sic_clean' > 9999 | `compare_sic_clean' < 0
        }
        * Call sic_to_ff for the sanitized comparison variable
        * Note: nomissing is NOT passed for compare() to avoid inflating concordance
        quietly sic_to_ff `compare_sic_clean' if `touse', generate(`ff_from_sic') scheme(`scheme') replace

        * Count concordance (only where both are non-missing)
        quietly count if `generate' == `ff_from_sic' & `touse' & !missing(`generate') & !missing(`ff_from_sic')
        local n_concordant = r(N)
        quietly count if `generate' != `ff_from_sic' & `touse' & !missing(`generate') & !missing(`ff_from_sic')
        local n_discordant = r(N)

        local n_comparable = `n_concordant' + `n_discordant'
        if `n_comparable' > 0 {
            local concordance_rate = 100 * `n_concordant' / `n_comparable'
        }
        else {
            local concordance_rate = .
        }
    }

    * Count final results
    quietly count if `generate' < . & `touse'
    local n_ff_mapped = r(N)

    * N_ff_unmapped = SIC exists but FF assignment missing
    quietly count if `generate' >= . & `touse' & `sic_mapped' < .
    local n_ff_unmapped = r(N)

    * Calculate rates
    * naics_map_rate: percent of NAICS codes mapped (denominator = obs with NAICS)
    * ff_map_rate: percent of sample with FF assignment (denominator = total obs)
    if `n_with_naics' > 0 {
        local naics_map_rate = 100 * `n_naics_mapped' / `n_with_naics'
    }
    else {
        local naics_map_rate = 0
    }
    if `n_total' > 0 {
        local ff_map_rate = 100 * `n_ff_mapped' / `n_total'
    }
    else {
        local ff_map_rate = 0
    }

    * Display results
    display as text ""
    display as text "{hline 60}"
    display as text "Fama-French `scheme'-industry classification: " as result "`generate'"
    display as text "{hline 60}"
    display as text "Observations in sample:           " as result %10.0fc `n_total'
    display as text "Observations with NAICS code:     " as result %10.0fc `n_with_naics'
    display as text "NAICS mapped to SIC:              " as result %10.0fc `n_naics_mapped' ///
        as text " (" as result %5.1f `naics_map_rate' as text "%)"
    display as text "NAICS not mapped (method=`method'):" as result %9.0fc `n_naics_unmapped'
    display as text "Observations with FF`scheme':        " as result %10.0fc `n_ff_mapped' ///
        as text " (" as result %5.1f `ff_map_rate' as text "%)"
    if `n_ff_unmapped' > 0 {
        display as text "Valid NAICS but no FF match:      " as result %10.0fc `n_ff_unmapped'
        if "`nomissing'" == "" & inlist("`scheme'", "17", "30", "38", "48", "49") {
            display as text "(Use nomissing option to force unmapped codes into Other.)"
        }
    }
    display as text "{hline 60}"

    * Display comparison results if compare() was specified
    if "`compare'" != "" {
        display as text ""
        display as text "{hline 60}"
        display as text "Comparison with SIC-based classification (`compare')"
        display as text "{hline 60}"
        display as text "Comparable observations:          " as result %10.0fc `n_comparable'
        display as text "Concordant (same FF`scheme'):       " as result %10.0fc `n_concordant' ///
            as text " (" as result %5.1f `concordance_rate' as text "%)"
        display as text "Discordant (different FF`scheme'):  " as result %10.0fc `n_discordant'
        display as text "{hline 60}"
    }

    * Diagnostics option
    if "`diagnostics'" != "" {
        display as text ""
        display as text "{hline 60}"
        display as text "Diagnostics: Mapping Source Distribution"
        display as text "{hline 60}"

        * Count sources only where SIC was actually mapped (not missing)
        quietly count if `touse' & `mapping_source' == "compustat" & `sic_mapped' < .
        local n_compustat_diag = r(N)
        quietly count if `touse' & `mapping_source' == "dorn" & `sic_mapped' < .
        local n_dorn = r(N)
        quietly count if `touse' & `mapping_source' == "census" & `sic_mapped' < .
        local n_census = r(N)
        quietly count if `touse' & `mapping_source' == "manual" & `sic_mapped' < .
        local n_manual = r(N)
        quietly count if `touse' & `mapping_source' == "fallback" & `sic_mapped' < .
        local n_fallback_diag = r(N)

        * Display Compustat mappings first if used
        if `use_compustat' == 1 {
            display as text "Mapped via Compustat (mkt-cap):   " as result %10.0fc `n_compustat_diag'
            if "`yearvar'" != "" {
                display as text "  (Time-varying weights via `yearvar')"
            }
            else {
                display as text "  (Fixed year weights: `cyear')"
            }
            if "`nofallback'" == "" {
                display as text "Dorn fallback (unmapped NAICS):   " as result %10.0fc `n_dorn_fallback'
            }
        }
        else {
            display as text "Mapped via Dorn crosswalk:        " as result %10.0fc `n_dorn'
            display as text "Mapped via Census concordance:    " as result %10.0fc `n_census'
            if `n_manual' > 0 {
                display as text "Mapped via manual assignment:     " as result %10.0fc `n_manual'
            }
        }
        if `n_fallback_diag' > 0 {
            display as text "Mapped via fallback(`fallback'):  " as result %10.0fc `n_fallback_diag'
        }

        * Check for non-6-digit NAICS codes
        quietly count if `touse' & `naics_num' < . & (`naics_num' < 100000 | `naics_num' > 999999)
        if r(N) > 0 {
            display as text ""
            display as text "  Note: " as result r(N) as text " observations have non-6-digit NAICS codes"
        }

        * Report thousand-separator normalization
        if `n_thousand_sep_pattern' > 0 {
            display as text "  Note: " as result `n_thousand_sep_pattern' as text " observations had dot-as-thousand-separator NAICS (normalized)"
        }

        * Report remaining fractional NAICS codes (true decimals, not thousand-separator)
        if `n_fractional' > 0 {
            display as text "  Note: " as result `n_fractional' as text " observations had fractional NAICS codes (truncated)"
        }

        display as text ""
        display as text "FF`scheme' Industry Distribution:"
        quietly count if `touse'
        if r(N) > 0 {
            tab `generate' if `touse', missing
        }
        else {
            display as text "(no observations in sample)"
        }

        * Show top unmapped NAICS codes
        * Note: n_naics_unmapped is pre-fallback count; actual unmapped may be 0 after fallback
        if `n_naics_unmapped' > 0 {
            display as text ""
            display as text "Top 10 unmapped NAICS codes:"
            preserve
            capture noisily {
                quietly keep if `touse' & `naics_num' < . & `sic_mapped' >= .
                if _N > 0 {
                    tempvar __n2f_count
                    contract `naics_num', freq(`__n2f_count')
                    gsort -`__n2f_count'
                    local n_to_show = min(_N, 10)
                    list `naics_num' `__n2f_count' in 1/`n_to_show', noobs clean
                }
                else {
                    display as text "(all unmapped NAICS filled by fallback)"
                }
            }
            local __diag_rc = _rc
            restore
            if `__diag_rc' != 0 {
                display as error "Error displaying unmapped codes (diagnostics)"
            }
        }
    }

    * Store results
    return scalar N = `n_total'
    return scalar N_naics = `n_with_naics'
    return scalar N_naics_mapped = `n_naics_mapped'
    return scalar N_naics_unmapped = `n_naics_unmapped'
    return scalar N_ff_mapped = `n_ff_mapped'
    return scalar N_ff_unmapped = `n_ff_unmapped'
    return scalar naics_map_rate = `naics_map_rate'
    return scalar ff_map_rate = `ff_map_rate'
    return local scheme "`scheme'"
    return local varname "`generate'"
    return local method "`method'"

    * Fallback results (only if fallback() was specified)
    if "`fallback'" != "" {
        return scalar N_fallback = `n_fallback'
        return local fallback_var "`fallback'"
    }

    * Comparison results (only if compare() was specified)
    if "`compare'" != "" {
        return scalar N_concordant = `n_concordant'
        return scalar N_discordant = `n_discordant'
        return scalar N_comparable = `n_comparable'
        return scalar concordance_rate = `concordance_rate'
        return local compare_var "`compare'"
    }

    * Compustat results (only if compustat() was specified)
    if `use_compustat' == 1 {
        return scalar N_compustat_mapped = `n_compustat_mapped'
        return scalar N_dorn_fallback = `n_dorn_fallback'
        return local compustat_file "`compustat'"
        if "`yearvar'" != "" {
            return local yearvar "`yearvar'"
        }
        else {
            return scalar cyear = `cyear'
        }
        return scalar nofallback = ("`nofallback'" != "")
    }
end

*---------------------------------------------------------------------
* NAICS to SIC mapping via merge
* Uses embedded mapping data (sic, sic_skipaux, sic_first)
* Sources: Dorn crosswalk + Census concordance + concordance chain (NAICS 1997-2022)
* Total mappings: 1,463
*
* Methods:
*   - maxweight: SIC with highest employment weight (default)
*   - skipaux: SIC with highest weight excluding auxiliary SIC codes
*   - first: First-listed SIC by code order (Census-style, no weighting)
*---------------------------------------------------------------------
program _naics_to_sic_merge
    args naicsvar sicvar weightvar sourcevar touse method

    * Create a merge key
    tempvar naics_key
    quietly generate long `naics_key' = `naicsvar' if `touse'

    * Use tempvars for merge results
    tempvar merge_sic merge_w merge_src_temp

    * Build mapping data from embedded table
    * Using capture noisily pattern to ensure restore on errors
    tempfile mapcopy
    preserve
    capture noisily {
        _naics_sic_embedded_data

        * Validate required columns in embedded mapping
        foreach v in naics sic sic_skipaux sic_first weight source {
            capture confirm variable `v'
            if _rc != 0 {
                display as error "Embedded mapping data is missing required column: `v'"
                exit 610
            }
        }

        * Assert uniqueness of NAICS keys (guards against duplicate rows in embedded data)
        capture isid naics
        if _rc != 0 {
            display as error "Embedded mapping data has duplicate NAICS codes"
            exit 459
        }

        * Select SIC column based on method
        if "`method'" == "skipaux" {
            rename sic_skipaux __n2f_sic
            drop sic sic_first
        }
        else if "`method'" == "first" {
            rename sic_first __n2f_sic
            drop sic sic_skipaux
        }
        else {
            rename sic __n2f_sic
            drop sic_skipaux sic_first
        }

        * Rename for merge
        rename naics `naics_key'
        rename weight __n2f_w
        rename source __n2f_src
        keep `naics_key' __n2f_sic __n2f_w __n2f_src
        quietly save `mapcopy', replace
    }
    local __merge_rc = _rc
    restore
    if `__merge_rc' != 0 {
        exit `__merge_rc'
    }

    * Check for variable name collisions
    capture confirm variable __n2f_sic
    if _rc == 0 {
        display as error "Variable __n2f_sic already exists in your data."
        display as error "Please rename it before running naics_to_ff."
        exit 110
    }
    capture confirm variable __n2f_w
    if _rc == 0 {
        display as error "Variable __n2f_w already exists in your data."
        display as error "Please rename it before running naics_to_ff."
        exit 110
    }
    capture confirm variable __n2f_src
    if _rc == 0 {
        display as error "Variable __n2f_src already exists in your data."
        display as error "Please rename it before running naics_to_ff."
        exit 110
    }

    quietly merge m:1 `naics_key' using `mapcopy', keep(master match) nogenerate

    * Move merged results to tempvars
    quietly generate long `merge_sic' = __n2f_sic
    quietly generate double `merge_w' = __n2f_w
    quietly generate str6 `merge_src_temp' = __n2f_src
    drop __n2f_sic __n2f_w __n2f_src

    * Fill output variables from merged results
    * Only fill where sicvar is still missing (don't overwrite Compustat values)
    * Weight and source are ONLY filled when this merge provides the SIC
    * (prevents mixed-source outputs where SIC comes from Compustat but weight/source from Dorn)
    tempvar sic_was_missing
    quietly gen byte `sic_was_missing' = (`sicvar' >= .) if `touse'

    quietly replace `sicvar' = `merge_sic' if `touse' & `sic_was_missing' & `merge_sic' < .

    if "`method'" != "maxweight" {
        quietly replace `merge_w' = .
    }

    * Only fill weight/source if THIS merge provided the SIC (sicvar was missing and got filled)
    quietly replace `weightvar' = `merge_w' if `touse' & `sic_was_missing' & `sicvar' < . & `merge_w' < .
    quietly replace `sourcevar' = `merge_src_temp' if `touse' & `sic_was_missing' & `sicvar' < . & `merge_src_temp' != ""
end

*----------------------------------------------------------------------
* Build Compustat market-cap weighted NAICS->SIC mapping
* Creates a mapping file with maxweight SIC for each NAICS (and optionally year)
*
* Arguments:
*   compustat_path - Path to Compustat annual fundamental .dta file
*   year_filter    - Fixed year (cyear mode) or 0 (yearvar mode)
*   mapfile        - Tempfile path to save mapping
*   yearvar_mode   - If non-empty, indicates yearvar mode (include fyear in mapping)
*
* Expected Compustat variables: naics, sich, prcc_f, csho, fyear
*----------------------------------------------------------------------
program _build_compustat_mapping
    args compustat_path year_filter mapfile yearvar_mode

    preserve
    capture noisily {
        * Load Compustat with only needed variables
        use naics sich prcc_f csho fyear using "`compustat_path'", clear

        * Validate required variables exist
        foreach v in naics sich prcc_f csho fyear {
            capture confirm variable `v'
            if _rc != 0 {
                display as error "compustat(): Required variable `v' not found in file"
                display as error "Expected variables: naics, sich, prcc_f, csho, fyear"
                exit 111
            }
        }

        * Validate variable types (fail fast with clear messages)
        capture confirm numeric variable sich
        if _rc != 0 {
            display as error "compustat(): Variable 'sich' must be numeric, found string"
            display as error "Please destring sich before using with compustat()"
            exit 109
        }
        capture confirm numeric variable fyear
        if _rc != 0 {
            display as error "compustat(): Variable 'fyear' must be numeric, found string"
            display as error "Please destring fyear before using with compustat()"
            exit 109
        }
        capture confirm numeric variable prcc_f
        if _rc != 0 {
            display as error "compustat(): Variable 'prcc_f' must be numeric, found string"
            exit 109
        }
        capture confirm numeric variable csho
        if _rc != 0 {
            display as error "compustat(): Variable 'csho' must be numeric, found string"
            exit 109
        }

        * Filter to valid observations
        * - Non-empty NAICS
        * - Valid SIC (1-9999)
        * - Positive price and shares
        * - Non-missing fyear (required for proper year-based weighting)
        quietly keep if !missing(sich) & sich >= 1 & sich <= 9999 & prcc_f > 0 & csho > 0 & !missing(fyear)

        * Handle string vs numeric NAICS
        * Mirror main NAICS cleaning: strip spaces, commas, hyphens before conversion
        capture confirm string variable naics
        if _rc == 0 {
            * String NAICS - clean and convert to numeric
            quietly replace naics = trim(naics)
            quietly keep if naics != ""

            * Detect range patterns (e.g., "31-33") BEFORE removing hyphens
            * Range = digits-hyphen-digits AND result without hyphen is NOT 6 digits
            quietly gen str40 __n2f_rangecheck = naics
            quietly replace __n2f_rangecheck = subinstr(__n2f_rangecheck, " ", "", .)
            quietly replace __n2f_rangecheck = subinstr(__n2f_rangecheck, char(9), "", .)
            quietly replace __n2f_rangecheck = subinstr(__n2f_rangecheck, ",", "", .)
            quietly gen byte __is_range = regexm(__n2f_rangecheck, "^[0-9]+-[0-9]+$") ///
                & strlen(subinstr(__n2f_rangecheck, "-", "", .)) != 6
            quietly count if __is_range == 1
            if r(N) > 0 {
                display as text "  Warning: " as result r(N) as text " Compustat obs have NAICS range patterns (excluded)"
            }
            quietly replace naics = "" if __is_range == 1
            drop __n2f_rangecheck __is_range
            quietly keep if naics != ""

            * Strip formatting characters (same as main naics_to_ff cleaning)
            quietly replace naics = subinstr(naics, " ", "", .)
            quietly replace naics = subinstr(naics, ",", "", .)
            quietly replace naics = subinstr(naics, "-", "", .)
            quietly replace naics = subinstr(naics, char(9), "", .)  // tab

            * Convert to numeric - first to double to detect fractional values
            quietly gen double __naics_raw = real(naics)
            quietly keep if __naics_raw < .

            * Detect dot-as-thousand-separator pattern (e.g., "541.711" = 541711)
            * Strict check: original string must have EXACTLY 3 digits after decimal
            * Pattern: digits, dot, exactly 3 digits (e.g., "541.711" but NOT "541.71")
            * Note: Stata regexm() doesn't support {n} quantifiers, use repeated [0-9] instead
            quietly gen byte __is_thousand_sep = regexm(naics, "^[0-9]+[.][0-9][0-9][0-9]$") ///
                & floor(__naics_raw * 1000) >= 100000 ///
                & floor(__naics_raw * 1000) <= 999999
            quietly count if __is_thousand_sep == 1
            if r(N) > 0 {
                display as text "  Note: " as result r(N) as text " Compustat obs have dot-as-thousand-separator NAICS (normalized)"
                quietly replace __naics_raw = __naics_raw * 1000 if __is_thousand_sep == 1
            }
            drop __is_thousand_sep

            * Warn about remaining fractional NAICS (true decimals, not thousand-separator)
            quietly count if __naics_raw < . & floor(__naics_raw) != __naics_raw
            if r(N) > 0 {
                display as text "  Warning: " as result r(N) as text " Compustat observations have fractional NAICS (truncated)"
            }

            * Convert to long integer
            quietly gen long naics_num = floor(__naics_raw)
            drop __naics_raw
        }
        else {
            * Numeric NAICS - detect dot-as-thousand-separator pattern
            * Note: Cannot distinguish 541.71 from 541.710 in numeric form, but
            * if x*1000 is an integer in valid 6-digit range, assume thousand-separator
            quietly gen byte __is_thousand_sep = (naics < . ///
                & floor(naics) != naics ///
                & abs(mod(naics * 1000, 1)) < 0.0001 ///
                & floor(naics * 1000) >= 100000 ///
                & floor(naics * 1000) <= 999999)
            quietly count if __is_thousand_sep == 1
            if r(N) > 0 {
                display as text "  Note: " as result r(N) as text " Compustat obs have dot-as-thousand-separator NAICS (normalized)"
                quietly replace naics = naics * 1000 if __is_thousand_sep == 1
            }
            drop __is_thousand_sep

            * Warn about remaining fractional NAICS (not thousand-separator pattern)
            quietly count if naics < . & floor(naics) != naics
            if r(N) > 0 {
                display as text "  Warning: " as result r(N) as text " Compustat observations have fractional NAICS (truncated)"
            }
            quietly keep if naics < .
            quietly gen long naics_num = floor(naics)
        }
        drop naics
        rename naics_num naics

        * Filter to requested year (if cyear mode)
        if `year_filter' > 0 {
            quietly keep if fyear == `year_filter'
            quietly count
            if r(N) == 0 {
                display as error "cyear(`year_filter'): No observations found in Compustat file"
                exit 2000
            }
        }

        * Check we have data
        quietly count
        if r(N) == 0 {
            display as error "compustat(): No valid observations after filtering"
            display as error "(require: naics, sich 1-9999, prcc_f > 0, csho > 0, non-missing fyear)"
            exit 2000
        }

        * Calculate market cap
        quietly gen double mktcap = prcc_f * csho

        * Aggregate by NAICS-SIC-year (sum market cap)
        quietly collapse (sum) mktcap_sum=mktcap, by(naics sich fyear)

        * Calculate weight within each NAICS-year
        quietly bysort naics fyear: egen double total = total(mktcap_sum)
        quietly gen double weight = mktcap_sum / total

        * Keep maxweight SIC for each NAICS-year
        * Tie-breaking: when weights are equal, deterministically pick lowest SIC code
        * (gsort with descending weight and ascending sich, then keep first per group)
        quietly gsort naics fyear -weight sich
        quietly by naics fyear: keep if _n == 1

        * For cyear mode, drop fyear (not needed for merge)
        if `year_filter' > 0 {
            drop fyear
        }

        * If yearvar mode is empty and year_filter is 0, this is an error
        * (should not happen due to validation, but guard anyway)

        rename sich sic
        keep naics sic weight `=cond(`year_filter'>0, "", "fyear")'

        quietly save "`mapfile'", replace
    }
    local __build_rc = _rc
    restore
    if `__build_rc' != 0 {
        exit `__build_rc'
    }
end

*----------------------------------------------------------------------
* Merge user data with Compustat-based NAICS->SIC mapping
*
* Arguments:
*   naicsvar   - NAICS variable in user data
*   sicvar     - Output SIC variable
*   weightvar  - Output weight variable
*   sourcevar  - Output source variable
*   touse      - Sample marker
*   mapfile    - Tempfile with Compustat mapping
*   yearvar    - Year variable in user data (empty if cyear mode)
*   cyear      - Fixed year (0 if yearvar mode)
*----------------------------------------------------------------------
program _naics_to_sic_merge_compustat
    args naicsvar sicvar weightvar sourcevar touse mapfile yearvar cyear

    * Create merge keys
    tempvar naics_key year_key

    quietly generate long `naics_key' = `naicsvar' if `touse'

    if "`yearvar'" != "" {
        * yearvar mode: merge by NAICS + year
        quietly generate long `year_key' = `yearvar' if `touse'
    }

    * Load mapping and merge
    tempfile mapcopy
    preserve
    capture noisily {
        use "`mapfile'", clear

        * Rename for merge
        rename naics `naics_key'
        rename weight __n2f_cstat_w
        rename sic __n2f_cstat_sic

        if "`yearvar'" != "" {
            * yearvar mode: rename fyear for merge
            rename fyear `year_key'
        }

        quietly save `mapcopy', replace
    }
    local __load_rc = _rc
    restore
    if `__load_rc' != 0 {
        exit `__load_rc'
    }

    * Check for variable name collisions
    capture confirm variable __n2f_cstat_sic
    if _rc == 0 {
        display as error "Variable __n2f_cstat_sic already exists in your data."
        display as error "Please rename it before running naics_to_ff."
        exit 110
    }
    capture confirm variable __n2f_cstat_w
    if _rc == 0 {
        display as error "Variable __n2f_cstat_w already exists in your data."
        display as error "Please rename it before running naics_to_ff."
        exit 110
    }

    * Perform merge
    if "`yearvar'" != "" {
        * yearvar mode: merge by NAICS + year (time-varying weights)
        quietly merge m:1 `naics_key' `year_key' using `mapcopy', keep(master match) nogenerate
    }
    else {
        * cyear mode: merge by NAICS only (fixed year weights)
        quietly merge m:1 `naics_key' using `mapcopy', keep(master match) nogenerate
    }

    * Move merged results to output variables
    * Only fill where we got a match AND output variable is still missing
    quietly replace `sicvar'    = __n2f_cstat_sic if `touse' & `sicvar' >= . & __n2f_cstat_sic < .
    quietly replace `weightvar' = __n2f_cstat_w   if `touse' & `weightvar' >= . & __n2f_cstat_w < .
    quietly replace `sourcevar' = "compustat"     if `touse' & `sourcevar' == "" & __n2f_cstat_sic < .

    * Clean up merge variables
    capture drop __n2f_cstat_sic __n2f_cstat_w
end

*----------------------------------------------------------------------
* Embedded NAICS to SIC mapping data (1,463 rows)
* Columns: naics, sic, sic_skipaux, sic_first, weight, source
* Sources: Dorn crosswalk (NAICS 1997) + Census concordance (NAICS 2002)
*----------------------------------------------------------------------
program _naics_sic_embedded_data
    version 14.0
    clear
    tempname __posth
    tempfile __map
    postfile `__posth' long naics long sic long sic_skipaux long sic_first double weight str6 source using "`__map'", replace
    post `__posth' (111110) (116) (116) (116) (.) ("census")
    post `__posth' (111120) (119) (119) (119) (.) ("census")
    post `__posth' (111130) (119) (119) (119) (.) ("census")
    post `__posth' (111140) (111) (111) (111) (.) ("census")
    post `__posth' (111150) (115) (115) (115) (.) ("census")
    post `__posth' (111160) (112) (112) (112) (.) ("census")
    post `__posth' (111191) (119) (119) (119) (.) ("census")
    post `__posth' (111199) (119) (119) (119) (.) ("census")
    post `__posth' (111211) (134) (134) (134) (.) ("census")
    post `__posth' (111219) (139) (139) (139) (.) ("census")
    post `__posth' (111310) (174) (174) (174) (.) ("census")
    post `__posth' (111320) (174) (174) (174) (.) ("census")
    post `__posth' (111331) (175) (175) (175) (.) ("census")
    post `__posth' (111332) (172) (172) (172) (.) ("census")
    post `__posth' (111333) (171) (171) (171) (.) ("census")
    post `__posth' (111334) (171) (171) (171) (.) ("census")
    post `__posth' (111335) (173) (173) (173) (.) ("census")
    post `__posth' (111336) (179) (179) (179) (.) ("census")
    post `__posth' (111339) (175) (175) (175) (.) ("census")
    post `__posth' (111411) (182) (182) (182) (.) ("census")
    post `__posth' (111419) (182) (182) (182) (.) ("census")
    post `__posth' (111421) (181) (181) (181) (.) ("census")
    post `__posth' (111422) (181) (181) (181) (.) ("census")
    post `__posth' (111910) (132) (132) (132) (.) ("census")
    post `__posth' (111920) (131) (131) (131) (.) ("census")
    post `__posth' (111930) (133) (133) (133) (.) ("census")
    post `__posth' (111940) (139) (139) (139) (.) ("census")
    post `__posth' (111991) (133) (133) (133) (.) ("census")
    post `__posth' (111992) (139) (139) (139) (.) ("census")
    post `__posth' (111998) (139) (139) (139) (.) ("census")
    post `__posth' (112111) (212) (212) (212) (.) ("census")
    post `__posth' (112112) (211) (211) (211) (.) ("census")
    post `__posth' (112120) (241) (241) (241) (.) ("census")
    post `__posth' (112210) (213) (213) (213) (.) ("census")
    post `__posth' (112310) (252) (252) (252) (.) ("census")
    post `__posth' (112320) (251) (251) (251) (.) ("census")
    post `__posth' (112330) (253) (253) (253) (.) ("census")
    post `__posth' (112340) (254) (254) (254) (.) ("census")
    post `__posth' (112390) (259) (259) (259) (.) ("census")
    post `__posth' (112410) (214) (214) (214) (.) ("census")
    post `__posth' (112420) (214) (214) (214) (.) ("census")
    post `__posth' (112511) (273) (273) (273) (.) ("census")
    post `__posth' (112512) (273) (273) (273) (.) ("census")
    post `__posth' (112519) (273) (273) (273) (.) ("census")
    post `__posth' (112910) (279) (279) (279) (.) ("census")
    post `__posth' (112920) (272) (272) (272) (.) ("census")
    post `__posth' (112930) (271) (271) (271) (.) ("census")
    post `__posth' (112990) (219) (219) (219) (.) ("census")
    post `__posth' (113110) (811) (811) (811) (1) ("dorn")
    post `__posth' (113210) (831) (831) (831) (1) ("dorn")
    post `__posth' (113310) (2411) (2411) (2411) (1) ("dorn")
    post `__posth' (114111) (912) (912) (912) (1) ("dorn")
    post `__posth' (114112) (913) (913) (913) (1) ("dorn")
    post `__posth' (114119) (919) (919) (919) (1) ("dorn")
    post `__posth' (114210) (971) (971) (971) (1) ("dorn")
    post `__posth' (115111) (724) (724) (724) (1) ("dorn")
    post `__posth' (115112) (711) (711) (711) (1) ("dorn")
    post `__posth' (115113) (722) (722) (722) (1) ("dorn")
    post `__posth' (115114) (723) (723) (723) (1) ("dorn")
    post `__posth' (115115) (761) (761) (761) (1) ("dorn")
    post `__posth' (115116) (762) (762) (762) (1) ("dorn")
    post `__posth' (115210) (751) (751) (751) (1) ("dorn")
    post `__posth' (115310) (851) (851) (851) (1) ("dorn")
    post `__posth' (211111) (1311) (1311) (1311) (1) ("dorn")
    post `__posth' (211112) (1321) (1321) (1321) (1) ("dorn")
    post `__posth' (211120) (1311) (1311) (1311) (1) ("dorn")
    post `__posth' (211130) (1311) (1311) (1311) (1) ("dorn")
    post `__posth' (212111) (1221) (1221) (1221) (1) ("dorn")
    post `__posth' (212112) (1222) (1222) (1222) (1) ("dorn")
    post `__posth' (212113) (1231) (1231) (1231) (1) ("dorn")
    post `__posth' (212114) (1221) (1221) (1221) (1) ("dorn")
    post `__posth' (212115) (1222) (1222) (1222) (1) ("dorn")
    post `__posth' (212210) (1011) (1011) (1011) (1) ("dorn")
    post `__posth' (212220) (1041) (1041) (1041) (1) ("dorn")
    post `__posth' (212221) (1041) (1041) (1041) (1) ("dorn")
    post `__posth' (212222) (1044) (1044) (1044) (1) ("dorn")
    post `__posth' (212230) (1031) (1031) (1031) (1) ("dorn")
    post `__posth' (212231) (1031) (1031) (1031) (1) ("dorn")
    post `__posth' (212234) (1021) (1021) (1021) (1) ("dorn")
    post `__posth' (212290) (1094) (1094) (1094) (1) ("dorn")
    post `__posth' (212291) (1094) (1094) (1094) (1) ("dorn")
    post `__posth' (212299) (1099) (1099) (1099) (1) ("dorn")
    post `__posth' (212311) (1411) (1411) (1411) (1) ("dorn")
    post `__posth' (212312) (1422) (1422) (1422) (1) ("dorn")
    post `__posth' (212313) (1423) (1423) (1423) (1) ("dorn")
    post `__posth' (212319) (1429) (1429) (1429) (.9882778525352478) ("dorn")
    post `__posth' (212321) (1442) (1442) (1442) (1) ("dorn")
    post `__posth' (212322) (1446) (1446) (1446) (1) ("dorn")
    post `__posth' (212323) (1455) (1455) (1455) (1) ("dorn")
    post `__posth' (212324) (1455) (1455) (1455) (1) ("dorn")
    post `__posth' (212325) (1459) (1459) (1459) (1) ("dorn")
    post `__posth' (212390) (1474) (1474) (1474) (1) ("dorn")
    post `__posth' (212391) (1474) (1474) (1474) (1) ("dorn")
    post `__posth' (212392) (1475) (1475) (1475) (1) ("dorn")
    post `__posth' (212393) (1479) (1479) (1479) (1) ("dorn")
    post `__posth' (212399) (1499) (1499) (1499) (1) ("dorn")
    post `__posth' (213111) (1381) (1381) (1381) (1) ("dorn")
    post `__posth' (213112) (1389) (1389) (1382) (.9610621929168701) ("dorn")
    post `__posth' (213113) (1241) (1241) (1241) (1) ("dorn")
    post `__posth' (213114) (1081) (1081) (1081) (1) ("dorn")
    post `__posth' (213115) (1481) (1481) (1481) (1) ("dorn")
    post `__posth' (221111) (4911) (4911) (4911) (.8596205711364746) ("dorn")
    post `__posth' (221112) (4911) (4911) (4911) (.7615528106689453) ("dorn")
    post `__posth' (221113) (4911) (4911) (4911) (.771007239818573) ("dorn")
    post `__posth' (221114) (4911) (4911) (4911) (.835106372833252) ("dorn")
    post `__posth' (221115) (4911) (4911) (4911) (.835106372833252) ("dorn")
    post `__posth' (221116) (4911) (4911) (4911) (.835106372833252) ("dorn")
    post `__posth' (221117) (4911) (4911) (4911) (.835106372833252) ("dorn")
    post `__posth' (221118) (4911) (4911) (4911) (.835106372833252) ("dorn")
    post `__posth' (221119) (4911) (4911) (4911) (.835106372833252) ("dorn")
    post `__posth' (221121) (4911) (4911) (4911) (.6778329014778137) ("dorn")
    post `__posth' (221122) (4911) (4911) (4911) (.5861990451812744) ("dorn")
    post `__posth' (221210) (4924) (4924) (4923) (.610383152961731) ("dorn")
    post `__posth' (221310) (4941) (4941) (4941) (.952171266078949) ("dorn")
    post `__posth' (221320) (4952) (4952) (4952) (1) ("dorn")
    post `__posth' (221330) (4961) (4961) (4961) (1) ("dorn")
    post `__posth' (233110) (6552) (6552) (6552) (1) ("dorn")
    post `__posth' (233210) (1521) (1521) (1521) (.7671474814414978) ("dorn")
    post `__posth' (233220) (1522) (1522) (1522) (.8106120824813843) ("dorn")
    post `__posth' (233310) (1541) (1541) (1531) (.9666512608528137) ("dorn")
    post `__posth' (233320) (1542) (1542) (1522) (.8948068022727966) ("dorn")
    post `__posth' (234110) (1611) (1611) (1611) (.9967443346977234) ("dorn")
    post `__posth' (234120) (1622) (1622) (1622) (.9982622265815735) ("dorn")
    post `__posth' (234910) (1623) (1623) (1623) (.9989850521087646) ("dorn")
    post `__posth' (234920) (1623) (1623) (1623) (.9937203526496887) ("dorn")
    post `__posth' (234930) (1629) (1629) (1629) (.9931814074516296) ("dorn")
    post `__posth' (234990) (1629) (1629) (1629) (.8792081475257874) ("dorn")
    post `__posth' (235110) (1711) (1711) (1711) (1) ("dorn")
    post `__posth' (235210) (1721) (1721) (1721) (.9782010912895203) ("dorn")
    post `__posth' (235310) (1731) (1731) (1731) (1) ("dorn")
    post `__posth' (235410) (1741) (1741) (1741) (1) ("dorn")
    post `__posth' (235420) (1742) (1742) (1742) (.9618610739707947) ("dorn")
    post `__posth' (235430) (1743) (1743) (1743) (1) ("dorn")
    post `__posth' (235510) (1751) (1751) (1751) (1) ("dorn")
    post `__posth' (235520) (1752) (1752) (1752) (1) ("dorn")
    post `__posth' (235610) (1761) (1761) (1761) (1) ("dorn")
    post `__posth' (235710) (1771) (1771) (1771) (1) ("dorn")
    post `__posth' (235810) (1781) (1781) (1781) (1) ("dorn")
    post `__posth' (235910) (1791) (1791) (1791) (1) ("dorn")
    post `__posth' (235920) (1793) (1793) (1793) (.969767153263092) ("dorn")
    post `__posth' (235930) (1794) (1794) (1794) (1) ("dorn")
    post `__posth' (235940) (1795) (1795) (1795) (1) ("dorn")
    post `__posth' (235950) (1796) (1796) (1796) (1) ("dorn")
    post `__posth' (235990) (1799) (1799) (1799) (1) ("dorn")
    post `__posth' (236115) (1521) (1521) (1521) (.) ("census")
    post `__posth' (236116) (1522) (1522) (1522) (.) ("census")
    post `__posth' (236117) (1531) (1531) (1531) (.) ("census")
    post `__posth' (236118) (1521) (1521) (1521) (.) ("census")
    post `__posth' (236210) (1531) (1531) (1531) (.) ("census")
    post `__posth' (236220) (1522) (1522) (1522) (.) ("census")
    post `__posth' (237110) (1623) (1623) (1623) (.) ("census")
    post `__posth' (237120) (1389) (1389) (1389) (.) ("census")
    post `__posth' (237130) (1623) (1623) (1623) (.) ("census")
    post `__posth' (237210) (6552) (6552) (6552) (.) ("census")
    post `__posth' (237310) (1611) (1611) (1611) (.) ("census")
    post `__posth' (237990) (1622) (1622) (1622) (.) ("census")
    post `__posth' (238110) (1771) (1771) (1771) (.) ("census")
    post `__posth' (238120) (1791) (1791) (1791) (.) ("census")
    post `__posth' (238130) (1751) (1751) (1751) (.) ("census")
    post `__posth' (238140) (1741) (1741) (1741) (.) ("census")
    post `__posth' (238150) (1793) (1793) (1793) (.) ("census")
    post `__posth' (238160) (1761) (1761) (1761) (.) ("census")
    post `__posth' (238170) (1761) (1761) (1761) (.) ("census")
    post `__posth' (238190) (1791) (1791) (1791) (.) ("census")
    post `__posth' (238210) (1711) (1711) (1711) (.) ("census")
    post `__posth' (238220) (1711) (1711) (1711) (.) ("census")
    post `__posth' (238290) (1796) (1796) (1796) (.) ("census")
    post `__posth' (238310) (1742) (1742) (1742) (.) ("census")
    post `__posth' (238320) (1721) (1721) (1721) (.) ("census")
    post `__posth' (238330) (1752) (1752) (1752) (.) ("census")
    post `__posth' (238340) (1743) (1743) (1743) (.) ("census")
    post `__posth' (238350) (1751) (1751) (1751) (.) ("census")
    post `__posth' (238390) (1761) (1761) (1761) (.) ("census")
    post `__posth' (238910) (1081) (1081) (1081) (.) ("census")
    post `__posth' (238990) (1771) (1771) (1771) (.) ("census")
    post `__posth' (311111) (2047) (2047) (2047) (1) ("dorn")
    post `__posth' (311119) (2048) (2048) (2048) (1) ("dorn")
    post `__posth' (311211) (2041) (2041) (2034) (.9991405606269836) ("dorn")
    post `__posth' (311212) (2044) (2044) (2044) (1) ("dorn")
    post `__posth' (311213) (2083) (2083) (2083) (1) ("dorn")
    post `__posth' (311221) (2046) (2046) (2046) (1) ("dorn")
    post `__posth' (311222) (2075) (2075) (2075) (1) ("dorn")
    post `__posth' (311223) (2074) (2074) (2074) (.7589051127433777) ("dorn")
    post `__posth' (311224) (2075) (2075) (2075) (1) ("dorn")
    post `__posth' (311225) (2079) (2079) (2074) (.8970180153846741) ("dorn")
    post `__posth' (311230) (2043) (2043) (2043) (1) ("dorn")
    post `__posth' (311311) (2061) (2061) (2061) (1) ("dorn")
    post `__posth' (311312) (2062) (2062) (2062) (1) ("dorn")
    post `__posth' (311313) (2063) (2063) (2063) (1) ("dorn")
    post `__posth' (311314) (2061) (2061) (2061) (1) ("dorn")
    post `__posth' (311320) (2066) (2066) (2066) (1) ("dorn")
    post `__posth' (311330) (2064) (2064) (2064) (.8950442671775818) ("dorn")
    post `__posth' (311340) (2064) (2064) (2064) (.7756350040435791) ("dorn")
    post `__posth' (311351) (2066) (2066) (2066) (1) ("dorn")
    post `__posth' (311352) (2064) (2064) (2064) (.8950442671775818) ("dorn")
    post `__posth' (311411) (2037) (2037) (2037) (1) ("dorn")
    post `__posth' (311412) (2038) (2038) (2038) (1) ("dorn")
    post `__posth' (311421) (2033) (2033) (2033) (.8760465979576111) ("dorn")
    post `__posth' (311422) (2032) (2032) (2032) (1) ("dorn")
    post `__posth' (311423) (2034) (2034) (2034) (.9634162783622742) ("dorn")
    post `__posth' (311511) (2026) (2026) (2026) (1) ("dorn")
    post `__posth' (311512) (2021) (2021) (2021) (1) ("dorn")
    post `__posth' (311513) (2022) (2022) (2022) (1) ("dorn")
    post `__posth' (311514) (2023) (2023) (2023) (1) ("dorn")
    post `__posth' (311520) (2024) (2024) (2024) (1) ("dorn")
    post `__posth' (311611) (2011) (2011) (2011) (.999143123626709) ("dorn")
    post `__posth' (311612) (2013) (2013) (2013) (.9597172737121582) ("dorn")
    post `__posth' (311613) (2077) (2077) (2077) (1) ("dorn")
    post `__posth' (311615) (2015) (2015) (2015) (1) ("dorn")
    post `__posth' (311710) (2091) (2091) (2077) (.9942282438278198) ("dorn")
    post `__posth' (311711) (2091) (2091) (2077) (.9942282438278198) ("dorn")
    post `__posth' (311712) (2092) (2092) (2077) (.9855470657348633) ("dorn")
    post `__posth' (311811) (5461) (5461) (5461) (1) ("dorn")
    post `__posth' (311812) (2051) (2051) (2051) (.9984652400016785) ("dorn")
    post `__posth' (311813) (2053) (2053) (2053) (1) ("dorn")
    post `__posth' (311821) (2052) (2052) (2052) (1) ("dorn")
    post `__posth' (311822) (2045) (2045) (2045) (1) ("dorn")
    post `__posth' (311823) (2098) (2098) (2098) (1) ("dorn")
    post `__posth' (311824) (2045) (2045) (2045) (1) ("dorn")
    post `__posth' (311830) (2099) (2099) (2099) (1) ("dorn")
    post `__posth' (311911) (2068) (2068) (2068) (.8909749388694763) ("dorn")
    post `__posth' (311919) (2096) (2096) (2052) (.905998170375824) ("dorn")
    post `__posth' (311920) (2095) (2095) (2043) (.803334653377533) ("dorn")
    post `__posth' (311930) (2087) (2087) (2087) (1) ("dorn")
    post `__posth' (311941) (2035) (2035) (2035) (.9105334877967834) ("dorn")
    post `__posth' (311942) (2099) (2099) (2087) (.752905547618866) ("dorn")
    post `__posth' (311991) (2099) (2099) (2099) (1) ("dorn")
    post `__posth' (311999) (2099) (2099) (2015) (.6259863972663879) ("dorn")
    post `__posth' (312111) (2086) (2086) (2086) (1) ("dorn")
    post `__posth' (312112) (2086) (2086) (2086) (1) ("dorn")
    post `__posth' (312113) (2097) (2097) (2097) (1) ("dorn")
    post `__posth' (312120) (2082) (2082) (2082) (1) ("dorn")
    post `__posth' (312130) (2084) (2084) (2084) (1) ("dorn")
    post `__posth' (312140) (2085) (2085) (2085) (1) ("dorn")
    post `__posth' (312210) (2141) (2141) (2141) (1) ("dorn")
    post `__posth' (312221) (2111) (2111) (2111) (1) ("dorn")
    post `__posth' (312229) (2121) (2121) (2121) (.5382785797119141) ("dorn")
    post `__posth' (312230) (2141) (2141) (2141) (1) ("dorn")
    post `__posth' (313110) (2281) (2281) (2281) (.9763294458389282) ("dorn")
    post `__posth' (313111) (2281) (2281) (2281) (.9763294458389282) ("dorn")
    post `__posth' (313112) (2282) (2282) (2282) (1) ("dorn")
    post `__posth' (313113) (2284) (2284) (2284) (.994907557964325) ("dorn")
    post `__posth' (313210) (2221) (2221) (2211) (.580422043800354) ("dorn")
    post `__posth' (313220) (2241) (2241) (2241) (.9987336993217468) ("dorn")
    post `__posth' (313221) (2241) (2241) (2241) (.9987336993217468) ("dorn")
    post `__posth' (313222) (2397) (2397) (2397) (1) ("dorn")
    post `__posth' (313230) (2297) (2297) (2297) (.8112210631370544) ("dorn")
    post `__posth' (313240) (2257) (2257) (2257) (1) ("dorn")
    post `__posth' (313241) (2257) (2257) (2257) (1) ("dorn")
    post `__posth' (313249) (2258) (2258) (2258) (.9388576149940491) ("dorn")
    post `__posth' (313310) (2261) (2261) (2231) (.4167544841766357) ("dorn")
    post `__posth' (313311) (2261) (2261) (2231) (.4167544841766357) ("dorn")
    post `__posth' (313312) (2269) (2269) (2231) (.3808053731918335) ("dorn")
    post `__posth' (313320) (2295) (2295) (2295) (.8718081712722778) ("dorn")
    post `__posth' (314110) (2273) (2273) (2273) (1) ("dorn")
    post `__posth' (314120) (2391) (2391) (2391) (.823753297328949) ("dorn")
    post `__posth' (314121) (2391) (2391) (2391) (.823753297328949) ("dorn")
    post `__posth' (314129) (2392) (2392) (2392) (1) ("dorn")
    post `__posth' (314910) (2393) (2393) (2392) (.9697785973548889) ("dorn")
    post `__posth' (314911) (2393) (2393) (2392) (.9697785973548889) ("dorn")
    post `__posth' (314912) (2394) (2394) (2394) (1) ("dorn")
    post `__posth' (314991) (2298) (2298) (2298) (1) ("dorn")
    post `__posth' (314992) (2296) (2296) (2296) (1) ("dorn")
    post `__posth' (314994) (2298) (2298) (2298) (1) ("dorn")
    post `__posth' (314999) (2399) (2399) (2299) (.5035824775695801) ("dorn")
    post `__posth' (315111) (2251) (2251) (2251) (.964901328086853) ("dorn")
    post `__posth' (315119) (2252) (2252) (2252) (1) ("dorn")
    post `__posth' (315120) (2251) (2251) (2251) (.964901328086853) ("dorn")
    post `__posth' (315191) (2253) (2253) (2253) (.9582993984222412) ("dorn")
    post `__posth' (315192) (2254) (2254) (2254) (.964285671710968) ("dorn")
    post `__posth' (315210) (2325) (2325) (2311) (.3071347177028656) ("dorn")
    post `__posth' (315211) (2325) (2325) (2311) (.3071347177028656) ("dorn")
    post `__posth' (315212) (2339) (2339) (2331) (.3974654376506805) ("dorn")
    post `__posth' (315221) (2322) (2322) (2322) (.8080861568450928) ("dorn")
    post `__posth' (315222) (2311) (2311) (2311) (.9441954493522644) ("dorn")
    post `__posth' (315223) (2321) (2321) (2321) (.9852319955825806) ("dorn")
    post `__posth' (315224) (2325) (2325) (2325) (.9561141729354858) ("dorn")
    post `__posth' (315225) (2326) (2326) (2326) (1) ("dorn")
    post `__posth' (315228) (2329) (2329) (2329) (.9528883099555969) ("dorn")
    post `__posth' (315231) (2341) (2341) (2341) (.819607138633728) ("dorn")
    post `__posth' (315232) (2331) (2331) (2331) (.8530445694923401) ("dorn")
    post `__posth' (315233) (2335) (2335) (2335) (.8817967772483826) ("dorn")
    post `__posth' (315234) (2337) (2337) (2337) (.8765898942947388) ("dorn")
    post `__posth' (315239) (2339) (2339) (2339) (.9283682107925415) ("dorn")
    post `__posth' (315250) (2322) (2322) (2322) (.8080861568450928) ("dorn")
    post `__posth' (315291) (2369) (2369) (2341) (.4954002201557159) ("dorn")
    post `__posth' (315292) (2386) (2386) (2371) (.7308052182197571) ("dorn")
    post `__posth' (315299) (2389) (2389) (2329) (.5427032113075256) ("dorn")
    post `__posth' (315990) (2353) (2353) (2353) (1) ("dorn")
    post `__posth' (315991) (2353) (2353) (2353) (1) ("dorn")
    post `__posth' (315992) (2381) (2381) (2381) (.684492826461792) ("dorn")
    post `__posth' (315993) (2323) (2323) (2323) (1) ("dorn")
    post `__posth' (315999) (2396) (2396) (2339) (.4589187502861023) ("dorn")
    post `__posth' (316110) (3111) (3111) (3111) (.9785205721855164) ("dorn")
    post `__posth' (316210) (3021) (3021) (3021) (1) ("dorn")
    post `__posth' (316211) (3021) (3021) (3021) (1) ("dorn")
    post `__posth' (316212) (3142) (3142) (3142) (1) ("dorn")
    post `__posth' (316213) (3143) (3143) (3143) (1) ("dorn")
    post `__posth' (316214) (3144) (3144) (3144) (1) ("dorn")
    post `__posth' (316219) (3149) (3149) (3149) (1) ("dorn")
    post `__posth' (316990) (3171) (3171) (3171) (1) ("dorn")
    post `__posth' (316991) (3161) (3161) (3161) (1) ("dorn")
    post `__posth' (316992) (3171) (3171) (3171) (1) ("dorn")
    post `__posth' (316993) (3172) (3172) (3172) (1) ("dorn")
    post `__posth' (316999) (3199) (3199) (3131) (.8689695000648499) ("dorn")
    post `__posth' (321113) (2421) (2421) (2421) (.9974616169929504) ("dorn")
    post `__posth' (321114) (2491) (2491) (2491) (1) ("dorn")
    post `__posth' (321211) (2435) (2435) (2435) (1) ("dorn")
    post `__posth' (321212) (2436) (2436) (2436) (1) ("dorn")
    post `__posth' (321213) (2439) (2439) (2439) (1) ("dorn")
    post `__posth' (321214) (2439) (2439) (2439) (1) ("dorn")
    post `__posth' (321215) (2439) (2439) (2439) (1) ("dorn")
    post `__posth' (321219) (2493) (2493) (2493) (1) ("dorn")
    post `__posth' (321911) (2431) (2431) (2431) (1) ("dorn")
    post `__posth' (321912) (2421) (2421) (2421) (.55591881275177) ("dorn")
    post `__posth' (321918) (2431) (2431) (2421) (.7214698195457458) ("dorn")
    post `__posth' (321920) (2448) (2448) (2429) (.7625845670700073) ("dorn")
    post `__posth' (321991) (2451) (2451) (2451) (1) ("dorn")
    post `__posth' (321992) (2452) (2452) (2452) (1) ("dorn")
    post `__posth' (321999) (2499) (2499) (2421) (.9544925689697266) ("dorn")
    post `__posth' (322110) (2611) (2611) (2611) (1) ("dorn")
    post `__posth' (322120) (2621) (2621) (2621) (.7783334255218506) ("dorn")
    post `__posth' (322121) (2621) (2621) (2621) (.7783334255218506) ("dorn")
    post `__posth' (322122) (2621) (2621) (2621) (1) ("dorn")
    post `__posth' (322130) (2631) (2631) (2631) (1) ("dorn")
    post `__posth' (322211) (2653) (2653) (2653) (1) ("dorn")
    post `__posth' (322212) (2657) (2657) (2657) (1) ("dorn")
    post `__posth' (322213) (2652) (2652) (2652) (1) ("dorn")
    post `__posth' (322214) (2655) (2655) (2655) (1) ("dorn")
    post `__posth' (322215) (2656) (2656) (2656) (1) ("dorn")
    post `__posth' (322219) (2652) (2652) (2652) (1) ("dorn")
    post `__posth' (322220) (2671) (2671) (2671) (1) ("dorn")
    post `__posth' (322221) (2671) (2671) (2671) (1) ("dorn")
    post `__posth' (322222) (2672) (2672) (2672) (.8483261466026306) ("dorn")
    post `__posth' (322223) (2673) (2673) (2673) (1) ("dorn")
    post `__posth' (322224) (2674) (2674) (2674) (1) ("dorn")
    post `__posth' (322225) (3497) (3497) (3497) (1) ("dorn")
    post `__posth' (322226) (2675) (2675) (2675) (1) ("dorn")
    post `__posth' (322230) (2675) (2675) (2675) (.82391357421875) ("dorn")
    post `__posth' (322231) (2675) (2675) (2675) (.82391357421875) ("dorn")
    post `__posth' (322232) (2677) (2677) (2677) (1) ("dorn")
    post `__posth' (322233) (2678) (2678) (2678) (1) ("dorn")
    post `__posth' (322291) (2676) (2676) (2676) (.8973888158798218) ("dorn")
    post `__posth' (322299) (2679) (2679) (2675) (.9007077813148499) ("dorn")
    post `__posth' (323110) (2752) (2752) (2752) (.9991447925567627) ("dorn")
    post `__posth' (323111) (2754) (2754) (2754) (1) ("dorn")
    post `__posth' (323112) (2759) (2759) (2759) (1) ("dorn")
    post `__posth' (323113) (2759) (2759) (2396) (.5247504115104675) ("dorn")
    post `__posth' (323114) (2752) (2752) (2752) (.8885584473609924) ("dorn")
    post `__posth' (323115) (2759) (2759) (2759) (1) ("dorn")
    post `__posth' (323116) (2761) (2761) (2761) (.723414421081543) ("dorn")
    post `__posth' (323117) (2732) (2732) (2732) (1) ("dorn")
    post `__posth' (323118) (2782) (2782) (2782) (1) ("dorn")
    post `__posth' (323119) (2759) (2759) (2759) (.9881572723388672) ("dorn")
    post `__posth' (323120) (2789) (2789) (2789) (1) ("dorn")
    post `__posth' (323121) (2789) (2789) (2789) (1) ("dorn")
    post `__posth' (323122) (2791) (2791) (2791) (.5266903042793274) ("dorn")
    post `__posth' (324110) (2911) (2911) (2911) (1) ("dorn")
    post `__posth' (324121) (2951) (2951) (2951) (1) ("dorn")
    post `__posth' (324122) (2952) (2952) (2952) (1) ("dorn")
    post `__posth' (324191) (2992) (2992) (2992) (1) ("dorn")
    post `__posth' (324199) (2999) (2999) (2999) (.5284663438796997) ("dorn")
    post `__posth' (325110) (2869) (2869) (2865) (.7252124547958374) ("dorn")
    post `__posth' (325120) (2813) (2813) (2813) (.7034102082252502) ("dorn")
    post `__posth' (325130) (2816) (2816) (2816) (1) ("dorn")
    post `__posth' (325131) (2816) (2816) (2816) (1) ("dorn")
    post `__posth' (325132) (2865) (2865) (2865) (1) ("dorn")
    post `__posth' (325180) (2812) (2812) (2812) (1) ("dorn")
    post `__posth' (325181) (2812) (2812) (2812) (1) ("dorn")
    post `__posth' (325182) (2895) (2895) (2816) (1) ("dorn")
    post `__posth' (325188) (2819) (2819) (2819) (.9950887560844421) ("dorn")
    post `__posth' (325191) (2861) (2861) (2861) (1) ("dorn")
    post `__posth' (325192) (2865) (2865) (2865) (1) ("dorn")
    post `__posth' (325193) (2869) (2869) (2869) (1) ("dorn")
    post `__posth' (325194) (2861) (2861) (2861) (1) ("dorn")
    post `__posth' (325199) (2869) (2869) (2869) (.9712082743644714) ("dorn")
    post `__posth' (325211) (2821) (2821) (2821) (1) ("dorn")
    post `__posth' (325212) (2822) (2822) (2822) (1) ("dorn")
    post `__posth' (325220) (2823) (2823) (2823) (1) ("dorn")
    post `__posth' (325221) (2823) (2823) (2823) (1) ("dorn")
    post `__posth' (325222) (2824) (2824) (2824) (1) ("dorn")
    post `__posth' (325311) (2873) (2873) (2873) (1) ("dorn")
    post `__posth' (325312) (2874) (2874) (2874) (1) ("dorn")
    post `__posth' (325314) (2875) (2875) (2875) (1) ("dorn")
    post `__posth' (325315) (2875) (2875) (2875) (1) ("dorn")
    post `__posth' (325320) (2879) (2879) (2879) (1) ("dorn")
    post `__posth' (325411) (2833) (2833) (2833) (1) ("dorn")
    post `__posth' (325412) (2834) (2834) (2834) (.9728469252586365) ("dorn")
    post `__posth' (325413) (2835) (2835) (2835) (1) ("dorn")
    post `__posth' (325414) (2836) (2836) (2836) (1) ("dorn")
    post `__posth' (325510) (2851) (2851) (2851) (.9921922087669373) ("dorn")
    post `__posth' (325520) (2891) (2891) (2891) (1) ("dorn")
    post `__posth' (325611) (2841) (2841) (2841) (.9314461946487427) ("dorn")
    post `__posth' (325612) (2842) (2842) (2842) (1) ("dorn")
    post `__posth' (325613) (2843) (2843) (2843) (1) ("dorn")
    post `__posth' (325620) (2844) (2844) (2844) (1) ("dorn")
    post `__posth' (325910) (2893) (2893) (2893) (1) ("dorn")
    post `__posth' (325920) (2892) (2892) (2892) (1) ("dorn")
    post `__posth' (325991) (3087) (3087) (3087) (1) ("dorn")
    post `__posth' (325992) (3861) (3861) (3861) (1) ("dorn")
    post `__posth' (325998) (2899) (2899) (2819) (.9427537322044373) ("dorn")
    post `__posth' (326111) (2673) (2673) (2673) (1) ("dorn")
    post `__posth' (326112) (2671) (2671) (2671) (1) ("dorn")
    post `__posth' (326113) (3081) (3081) (3081) (1) ("dorn")
    post `__posth' (326121) (3082) (3082) (3082) (1) ("dorn")
    post `__posth' (326122) (3084) (3084) (3084) (.7887555956840515) ("dorn")
    post `__posth' (326130) (3083) (3083) (3083) (1) ("dorn")
    post `__posth' (326140) (3086) (3086) (3086) (1) ("dorn")
    post `__posth' (326150) (3086) (3086) (3086) (1) ("dorn")
    post `__posth' (326160) (3085) (3085) (3085) (1) ("dorn")
    post `__posth' (326191) (3088) (3088) (3088) (1) ("dorn")
    post `__posth' (326192) (3996) (3996) (3069) (.9248764514923096) ("dorn")
    post `__posth' (326199) (3089) (3089) (3089) (.9940328598022461) ("dorn")
    post `__posth' (326211) (3011) (3011) (3011) (1) ("dorn")
    post `__posth' (326212) (7534) (7534) (7534) (1) ("dorn")
    post `__posth' (326220) (3052) (3052) (3052) (1) ("dorn")
    post `__posth' (326291) (3061) (3061) (3061) (1) ("dorn")
    post `__posth' (326299) (3069) (3069) (3069) (1) ("dorn")
    post `__posth' (327110) (3261) (3261) (3261) (1) ("dorn")
    post `__posth' (327111) (3261) (3261) (3261) (1) ("dorn")
    post `__posth' (327112) (3269) (3269) (3262) (.6180334687232971) ("dorn")
    post `__posth' (327113) (3264) (3264) (3264) (1) ("dorn")
    post `__posth' (327120) (3251) (3251) (3251) (1) ("dorn")
    post `__posth' (327121) (3251) (3251) (3251) (1) ("dorn")
    post `__posth' (327122) (3253) (3253) (3253) (1) ("dorn")
    post `__posth' (327123) (3259) (3259) (3259) (1) ("dorn")
    post `__posth' (327124) (3255) (3255) (3255) (1) ("dorn")
    post `__posth' (327125) (3297) (3297) (3297) (1) ("dorn")
    post `__posth' (327211) (3211) (3211) (3211) (1) ("dorn")
    post `__posth' (327212) (3229) (3229) (3229) (1) ("dorn")
    post `__posth' (327213) (3221) (3221) (3221) (1) ("dorn")
    post `__posth' (327215) (3231) (3231) (3231) (1) ("dorn")
    post `__posth' (327310) (3241) (3241) (3241) (1) ("dorn")
    post `__posth' (327320) (3273) (3273) (3273) (1) ("dorn")
    post `__posth' (327331) (3271) (3271) (3271) (1) ("dorn")
    post `__posth' (327332) (3272) (3272) (3272) (1) ("dorn")
    post `__posth' (327390) (3272) (3272) (3272) (1) ("dorn")
    post `__posth' (327410) (3274) (3274) (3274) (1) ("dorn")
    post `__posth' (327420) (3275) (3275) (3275) (.9584304094314575) ("dorn")
    post `__posth' (327910) (3291) (3291) (3291) (1) ("dorn")
    post `__posth' (327991) (3281) (3281) (3281) (1) ("dorn")
    post `__posth' (327992) (3295) (3295) (3295) (1) ("dorn")
    post `__posth' (327993) (3296) (3296) (3296) (1) ("dorn")
    post `__posth' (327999) (3299) (3299) (3272) (.4980137348175049) ("dorn")
    post `__posth' (331110) (3312) (3312) (3312) (.9833462834358215) ("dorn")
    post `__posth' (331111) (3312) (3312) (3312) (.9833462834358215) ("dorn")
    post `__posth' (331112) (3313) (3313) (3313) (1) ("dorn")
    post `__posth' (331210) (3317) (3317) (3317) (1) ("dorn")
    post `__posth' (331221) (3316) (3316) (3316) (1) ("dorn")
    post `__posth' (331222) (3315) (3315) (3315) (1) ("dorn")
    post `__posth' (331311) (2819) (2819) (2819) (1) ("dorn")
    post `__posth' (331312) (3334) (3334) (3334) (1) ("dorn")
    post `__posth' (331313) (2819) (2819) (2819) (1) ("dorn")
    post `__posth' (331314) (3341) (3341) (3341) (.9273160696029663) ("dorn")
    post `__posth' (331315) (3353) (3353) (3353) (1) ("dorn")
    post `__posth' (331316) (3354) (3354) (3354) (1) ("dorn")
    post `__posth' (331318) (3354) (3354) (3354) (1) ("dorn")
    post `__posth' (331319) (3355) (3355) (3355) (.6170459985733032) ("dorn")
    post `__posth' (331410) (3331) (3331) (3331) (1) ("dorn")
    post `__posth' (331411) (3331) (3331) (3331) (1) ("dorn")
    post `__posth' (331419) (3339) (3339) (3339) (1) ("dorn")
    post `__posth' (331420) (3351) (3351) (3351) (1) ("dorn")
    post `__posth' (331421) (3351) (3351) (3351) (1) ("dorn")
    post `__posth' (331422) (3357) (3357) (3357) (1) ("dorn")
    post `__posth' (331423) (3341) (3341) (3341) (.757822573184967) ("dorn")
    post `__posth' (331491) (3356) (3356) (3356) (.666241466999054) ("dorn")
    post `__posth' (331492) (3399) (3399) (3313) (.5007752180099487) ("dorn")
    post `__posth' (331511) (3321) (3321) (3321) (.9695120453834534) ("dorn")
    post `__posth' (331512) (3324) (3324) (3324) (1) ("dorn")
    post `__posth' (331513) (3325) (3325) (3325) (1) ("dorn")
    post `__posth' (331521) (3363) (3363) (3363) (1) ("dorn")
    post `__posth' (331522) (3364) (3364) (3364) (1) ("dorn")
    post `__posth' (331523) (3363) (3363) (3363) (1) ("dorn")
    post `__posth' (331524) (3365) (3365) (3365) (1) ("dorn")
    post `__posth' (331525) (3366) (3366) (3366) (1) ("dorn")
    post `__posth' (331528) (3369) (3369) (3369) (1) ("dorn")
    post `__posth' (331529) (3366) (3366) (3366) (1) ("dorn")
    post `__posth' (332111) (3462) (3462) (3462) (1) ("dorn")
    post `__posth' (332112) (3463) (3463) (3463) (1) ("dorn")
    post `__posth' (332114) (3449) (3449) (3449) (1) ("dorn")
    post `__posth' (332115) (3466) (3466) (3466) (1) ("dorn")
    post `__posth' (332116) (3469) (3469) (3469) (1) ("dorn")
    post `__posth' (332117) (3499) (3499) (3499) (1) ("dorn")
    post `__posth' (332119) (3466) (3466) (3466) (1) ("dorn")
    post `__posth' (332211) (3421) (3421) (3421) (.9910062551498413) ("dorn")
    post `__posth' (332212) (3423) (3423) (3423) (.852325975894928) ("dorn")
    post `__posth' (332213) (3425) (3425) (3425) (1) ("dorn")
    post `__posth' (332214) (3469) (3469) (3469) (1) ("dorn")
    post `__posth' (332215) (3421) (3421) (3421) (.9910062551498413) ("dorn")
    post `__posth' (332216) (3423) (3423) (3423) (.852325975894928) ("dorn")
    post `__posth' (332311) (3448) (3448) (3448) (1) ("dorn")
    post `__posth' (332312) (3441) (3441) (3441) (.9065747857093811) ("dorn")
    post `__posth' (332313) (3443) (3443) (3443) (1) ("dorn")
    post `__posth' (332321) (3442) (3442) (2499) (.9736603498458862) ("dorn")
    post `__posth' (332322) (3444) (3444) (3444) (1) ("dorn")
    post `__posth' (332323) (3446) (3446) (3446) (.9002355337142944) ("dorn")
    post `__posth' (332410) (3443) (3443) (3443) (1) ("dorn")
    post `__posth' (332420) (3443) (3443) (3443) (1) ("dorn")
    post `__posth' (332431) (3411) (3411) (3411) (1) ("dorn")
    post `__posth' (332439) (3412) (3412) (3412) (.4234016835689545) ("dorn")
    post `__posth' (332510) (3429) (3429) (3429) (.9542168378829956) ("dorn")
    post `__posth' (332611) (3493) (3493) (3493) (1) ("dorn")
    post `__posth' (332612) (3495) (3495) (3495) (1) ("dorn")
    post `__posth' (332613) (3493) (3493) (3493) (1) ("dorn")
    post `__posth' (332618) (3496) (3496) (3315) (.9057261943817139) ("dorn")
    post `__posth' (332710) (3599) (3599) (3599) (1) ("dorn")
    post `__posth' (332721) (3451) (3451) (3451) (1) ("dorn")
    post `__posth' (332722) (3452) (3452) (3452) (1) ("dorn")
    post `__posth' (332811) (3398) (3398) (3398) (1) ("dorn")
    post `__posth' (332812) (3479) (3479) (3479) (1) ("dorn")
    post `__posth' (332813) (3471) (3471) (3471) (1) ("dorn")
    post `__posth' (332911) (3491) (3491) (3491) (1) ("dorn")
    post `__posth' (332912) (3492) (3492) (3492) (1) ("dorn")
    post `__posth' (332913) (3432) (3432) (3432) (1) ("dorn")
    post `__posth' (332919) (3494) (3494) (3429) (.9419926404953003) ("dorn")
    post `__posth' (332991) (3562) (3562) (3562) (1) ("dorn")
    post `__posth' (332992) (3482) (3482) (3482) (1) ("dorn")
    post `__posth' (332993) (3483) (3483) (3483) (1) ("dorn")
    post `__posth' (332994) (3484) (3484) (3484) (1) ("dorn")
    post `__posth' (332995) (3489) (3489) (3489) (1) ("dorn")
    post `__posth' (332996) (3498) (3498) (3353) (1) ("dorn")
    post `__posth' (332997) (3543) (3543) (3543) (1) ("dorn")
    post `__posth' (332998) (3431) (3431) (3431) (1) ("dorn")
    post `__posth' (332999) (3499) (3499) (3291) (.8060705661773682) ("dorn")
    post `__posth' (333111) (3523) (3523) (3523) (1) ("dorn")
    post `__posth' (333112) (3524) (3524) (3524) (1) ("dorn")
    post `__posth' (333120) (3531) (3531) (3531) (1) ("dorn")
    post `__posth' (333131) (3532) (3532) (3532) (1) ("dorn")
    post `__posth' (333132) (3533) (3533) (3533) (1) ("dorn")
    post `__posth' (333210) (3553) (3553) (3553) (1) ("dorn")
    post `__posth' (333220) (3559) (3559) (3559) (1) ("dorn")
    post `__posth' (333241) (3556) (3556) (3556) (1) ("dorn")
    post `__posth' (333242) (3559) (3559) (3559) (1) ("dorn")
    post `__posth' (333243) (3553) (3553) (3553) (1) ("dorn")
    post `__posth' (333248) (3555) (3555) (3555) (.9909256100654602) ("dorn")
    post `__posth' (333291) (3554) (3554) (3554) (1) ("dorn")
    post `__posth' (333292) (3552) (3552) (3552) (1) ("dorn")
    post `__posth' (333293) (3555) (3555) (3555) (.9909256100654602) ("dorn")
    post `__posth' (333294) (3556) (3556) (3556) (1) ("dorn")
    post `__posth' (333295) (3559) (3559) (3559) (1) ("dorn")
    post `__posth' (333298) (3559) (3559) (3559) (.9982033371925354) ("dorn")
    post `__posth' (333310) (3827) (3827) (3699) (.9973150491714478) ("dorn")
    post `__posth' (333311) (3581) (3581) (3581) (1) ("dorn")
    post `__posth' (333312) (3582) (3582) (3582) (1) ("dorn")
    post `__posth' (333313) (3579) (3579) (3578) (.9348661303520203) ("dorn")
    post `__posth' (333314) (3827) (3827) (3699) (.9973150491714478) ("dorn")
    post `__posth' (333315) (3861) (3861) (3699) (1) ("dorn")
    post `__posth' (333319) (3589) (3589) (3559) (.7761728763580322) ("dorn")
    post `__posth' (333411) (3564) (3564) (3564) (1) ("dorn")
    post `__posth' (333412) (3564) (3564) (3564) (1) ("dorn")
    post `__posth' (333413) (3564) (3564) (3564) (1) ("dorn")
    post `__posth' (333414) (3433) (3433) (3433) (.9119840860366821) ("dorn")
    post `__posth' (333415) (3585) (3585) (3443) (.9971701502799988) ("dorn")
    post `__posth' (333511) (3544) (3544) (3544) (1) ("dorn")
    post `__posth' (333512) (3541) (3541) (3541) (.9822273850440979) ("dorn")
    post `__posth' (333513) (3542) (3542) (3542) (1) ("dorn")
    post `__posth' (333514) (3544) (3544) (3544) (1) ("dorn")
    post `__posth' (333515) (3545) (3545) (3545) (1) ("dorn")
    post `__posth' (333516) (3547) (3547) (3547) (1) ("dorn")
    post `__posth' (333517) (3541) (3541) (3541) (.9822273850440979) ("dorn")
    post `__posth' (333518) (3549) (3549) (3549) (1) ("dorn")
    post `__posth' (333519) (3547) (3547) (3547) (1) ("dorn")
    post `__posth' (333611) (3511) (3511) (3511) (1) ("dorn")
    post `__posth' (333612) (3566) (3566) (3566) (1) ("dorn")
    post `__posth' (333613) (3568) (3568) (3568) (1) ("dorn")
    post `__posth' (333618) (3519) (3519) (3519) (.9996763467788696) ("dorn")
    post `__posth' (333911) (3561) (3561) (3561) (1) ("dorn")
    post `__posth' (333912) (3563) (3563) (3563) (1) ("dorn")
    post `__posth' (333913) (3586) (3586) (3586) (1) ("dorn")
    post `__posth' (333914) (3561) (3561) (3561) (1) ("dorn")
    post `__posth' (333921) (3534) (3534) (3534) (1) ("dorn")
    post `__posth' (333922) (3535) (3535) (3523) (.9919189810752869) ("dorn")
    post `__posth' (333923) (3531) (3531) (3531) (.5697235465049744) ("dorn")
    post `__posth' (333924) (3537) (3537) (3537) (1) ("dorn")
    post `__posth' (333991) (3546) (3546) (3546) (1) ("dorn")
    post `__posth' (333992) (3548) (3548) (3548) (.9968451261520386) ("dorn")
    post `__posth' (333993) (3565) (3565) (3565) (1) ("dorn")
    post `__posth' (333994) (3567) (3567) (3567) (1) ("dorn")
    post `__posth' (333995) (3593) (3593) (3593) (1) ("dorn")
    post `__posth' (333996) (3594) (3594) (3594) (1) ("dorn")
    post `__posth' (333997) (3596) (3596) (3596) (1) ("dorn")
    post `__posth' (333998) (3596) (3596) (3596) (1) ("dorn")
    post `__posth' (333999) (3569) (3569) (3569) (.8190872073173523) ("dorn")
    post `__posth' (334111) (3571) (3571) (3571) (1) ("dorn")
    post `__posth' (334112) (3572) (3572) (3572) (1) ("dorn")
    post `__posth' (334113) (3575) (3575) (3575) (1) ("dorn")
    post `__posth' (334118) (3575) (3575) (3575) (1) ("dorn")
    post `__posth' (334119) (3577) (3577) (3577) (.9285197257995605) ("dorn")
    post `__posth' (334210) (3661) (3661) (3661) (1) ("dorn")
    post `__posth' (334220) (3663) (3663) (3663) (.9008579254150391) ("dorn")
    post `__posth' (334290) (3669) (3669) (3669) (1) ("dorn")
    post `__posth' (334310) (3651) (3651) (3651) (1) ("dorn")
    post `__posth' (334411) (3671) (3671) (3671) (1) ("dorn")
    post `__posth' (334412) (3672) (3672) (3672) (1) ("dorn")
    post `__posth' (334413) (3674) (3674) (3674) (1) ("dorn")
    post `__posth' (334414) (3675) (3675) (3675) (1) ("dorn")
    post `__posth' (334415) (3676) (3676) (3676) (1) ("dorn")
    post `__posth' (334416) (3677) (3677) (3661) (.9869795441627502) ("dorn")
    post `__posth' (334417) (3678) (3678) (3678) (1) ("dorn")
    post `__posth' (334418) (3679) (3679) (3661) (.9452248215675354) ("dorn")
    post `__posth' (334419) (3679) (3679) (3679) (1) ("dorn")
    post `__posth' (334510) (3845) (3845) (3699) (.8664337396621704) ("dorn")
    post `__posth' (334511) (3812) (3812) (3699) (.9967899918556213) ("dorn")
    post `__posth' (334512) (3822) (3822) (3822) (1) ("dorn")
    post `__posth' (334513) (3823) (3823) (3823) (1) ("dorn")
    post `__posth' (334514) (3824) (3824) (3824) (1) ("dorn")
    post `__posth' (334515) (3825) (3825) (3825) (1) ("dorn")
    post `__posth' (334516) (3826) (3826) (3699) (.9958549737930298) ("dorn")
    post `__posth' (334517) (3844) (3844) (3844) (1) ("dorn")
    post `__posth' (334518) (3873) (3873) (3495) (.891520619392395) ("dorn")
    post `__posth' (334519) (3829) (3829) (3699) (.9991453886032104) ("dorn")
    post `__posth' (334610) (3695) (3695) (3695) (1) ("dorn")
    post `__posth' (334611) (7379) (7379) (7379) (1) ("dorn")
    post `__posth' (334612) (3652) (3652) (3652) (.6495264768600464) ("dorn")
    post `__posth' (334613) (3695) (3695) (3695) (1) ("dorn")
    post `__posth' (335110) (3641) (3641) (3641) (1) ("dorn")
    post `__posth' (335121) (3645) (3645) (3089) (.9270568490028381) ("dorn")
    post `__posth' (335122) (3646) (3646) (3646) (1) ("dorn")
    post `__posth' (335129) (3648) (3648) (3648) (.9995623826980591) ("dorn")
    post `__posth' (335131) (3645) (3645) (3089) (.9270568490028381) ("dorn")
    post `__posth' (335132) (3646) (3646) (3646) (1) ("dorn")
    post `__posth' (335139) (3641) (3641) (3641) (1) ("dorn")
    post `__posth' (335210) (3634) (3634) (3634) (1) ("dorn")
    post `__posth' (335211) (3634) (3634) (3634) (1) ("dorn")
    post `__posth' (335212) (3635) (3635) (3635) (1) ("dorn")
    post `__posth' (335220) (3631) (3631) (3631) (1) ("dorn")
    post `__posth' (335221) (3631) (3631) (3631) (1) ("dorn")
    post `__posth' (335222) (3632) (3632) (3632) (1) ("dorn")
    post `__posth' (335224) (3633) (3633) (3633) (1) ("dorn")
    post `__posth' (335228) (3639) (3639) (3639) (1) ("dorn")
    post `__posth' (335311) (3612) (3612) (3548) (1) ("dorn")
    post `__posth' (335312) (3621) (3621) (3621) (.952401340007782) ("dorn")
    post `__posth' (335313) (3613) (3613) (3613) (1) ("dorn")
    post `__posth' (335314) (3625) (3625) (3625) (1) ("dorn")
    post `__posth' (335910) (3691) (3691) (3691) (1) ("dorn")
    post `__posth' (335911) (3691) (3691) (3691) (1) ("dorn")
    post `__posth' (335912) (3692) (3692) (3692) (1) ("dorn")
    post `__posth' (335921) (3357) (3357) (3357) (1) ("dorn")
    post `__posth' (335929) (3357) (3357) (3357) (1) ("dorn")
    post `__posth' (335931) (3643) (3643) (3643) (1) ("dorn")
    post `__posth' (335932) (3644) (3644) (3644) (1) ("dorn")
    post `__posth' (335991) (3624) (3624) (3624) (1) ("dorn")
    post `__posth' (335999) (3699) (3699) (3629) (.5825624465942383) ("dorn")
    post `__posth' (336110) (3711) (3711) (3711) (1) ("dorn")
    post `__posth' (336111) (3711) (3711) (3711) (1) ("dorn")
    post `__posth' (336112) (3711) (3711) (3711) (1) ("dorn")
    post `__posth' (336120) (3711) (3711) (3711) (1) ("dorn")
    post `__posth' (336211) (3713) (3713) (3711) (.9630047678947449) ("dorn")
    post `__posth' (336212) (3715) (3715) (3715) (1) ("dorn")
    post `__posth' (336213) (3716) (3716) (3716) (1) ("dorn")
    post `__posth' (336214) (3792) (3792) (3792) (.6030223369598389) ("dorn")
    post `__posth' (336310) (3592) (3592) (3592) (1) ("dorn")
    post `__posth' (336311) (3592) (3592) (3592) (1) ("dorn")
    post `__posth' (336312) (3714) (3714) (3714) (1) ("dorn")
    post `__posth' (336320) (3647) (3647) (3647) (1) ("dorn")
    post `__posth' (336321) (3647) (3647) (3647) (1) ("dorn")
    post `__posth' (336322) (3694) (3694) (3679) (.5468159317970276) ("dorn")
    post `__posth' (336330) (3714) (3714) (3714) (1) ("dorn")
    post `__posth' (336340) (3714) (3714) (3292) (1) ("dorn")
    post `__posth' (336350) (3714) (3714) (3714) (1) ("dorn")
    post `__posth' (336360) (2396) (2396) (2396) (.4833991229534149) ("dorn")
    post `__posth' (336370) (3465) (3465) (3465) (1) ("dorn")
    post `__posth' (336390) (3585) (3585) (3585) (1) ("dorn")
    post `__posth' (336391) (3585) (3585) (3585) (1) ("dorn")
    post `__posth' (336399) (3714) (3714) (3519) (.994864284992218) ("dorn")
    post `__posth' (336411) (3721) (3721) (3721) (1) ("dorn")
    post `__posth' (336412) (3724) (3724) (3724) (1) ("dorn")
    post `__posth' (336413) (3728) (3728) (3728) (1) ("dorn")
    post `__posth' (336414) (3761) (3761) (3761) (1) ("dorn")
    post `__posth' (336415) (3764) (3764) (3764) (1) ("dorn")
    post `__posth' (336419) (3769) (3769) (3769) (1) ("dorn")
    post `__posth' (336510) (3743) (3743) (3531) (.9300541281700134) ("dorn")
    post `__posth' (336611) (3731) (3731) (3731) (1) ("dorn")
    post `__posth' (336612) (3732) (3732) (3732) (1) ("dorn")
    post `__posth' (336991) (3751) (3751) (3751) (.9942501783370972) ("dorn")
    post `__posth' (336992) (3795) (3795) (3711) (.9137871265411377) ("dorn")
    post `__posth' (336999) (3799) (3799) (3799) (1) ("dorn")
    post `__posth' (337110) (2434) (2434) (2434) (.8017469644546509) ("dorn")
    post `__posth' (337121) (2512) (2512) (2512) (.9472163915634155) ("dorn")
    post `__posth' (337122) (2511) (2511) (2511) (.9619487524032593) ("dorn")
    post `__posth' (337124) (2514) (2514) (2514) (1) ("dorn")
    post `__posth' (337125) (2519) (2519) (2519) (1) ("dorn")
    post `__posth' (337126) (2514) (2514) (2514) (1) ("dorn")
    post `__posth' (337127) (2599) (2599) (2531) (.5873672366142273) ("dorn")
    post `__posth' (337129) (2517) (2517) (2517) (1) ("dorn")
    post `__posth' (337211) (2521) (2521) (2521) (1) ("dorn")
    post `__posth' (337212) (2541) (2541) (2541) (1) ("dorn")
    post `__posth' (337214) (2522) (2522) (2522) (1) ("dorn")
    post `__posth' (337215) (2542) (2542) (2426) (.5899551510810852) ("dorn")
    post `__posth' (337910) (2515) (2515) (2515) (1) ("dorn")
    post `__posth' (337920) (2591) (2591) (2591) (1) ("dorn")
    post `__posth' (339111) (3821) (3821) (3821) (1) ("dorn")
    post `__posth' (339112) (3841) (3841) (3829) (.9951678514480591) ("dorn")
    post `__posth' (339113) (3842) (3842) (2599) (.9657152891159058) ("dorn")
    post `__posth' (339114) (3843) (3843) (3699) (1) ("dorn")
    post `__posth' (339115) (3851) (3851) (3851) (1) ("dorn")
    post `__posth' (339116) (8072) (8072) (8072) (1) ("dorn")
    post `__posth' (339910) (3911) (3911) (3479) (.9977281093597412) ("dorn")
    post `__posth' (339911) (3911) (3911) (3479) (.9977281093597412) ("dorn")
    post `__posth' (339912) (3914) (3914) (3479) (.9840532541275024) ("dorn")
    post `__posth' (339913) (3915) (3915) (3915) (1) ("dorn")
    post `__posth' (339914) (3961) (3961) (3479) (.9590338468551636) ("dorn")
    post `__posth' (339920) (3949) (3949) (3949) (1) ("dorn")
    post `__posth' (339930) (3942) (3942) (3942) (1) ("dorn")
    post `__posth' (339931) (3942) (3942) (3942) (1) ("dorn")
    post `__posth' (339932) (3944) (3944) (3944) (1) ("dorn")
    post `__posth' (339940) (3951) (3951) (3951) (1) ("dorn")
    post `__posth' (339941) (3951) (3951) (3951) (1) ("dorn")
    post `__posth' (339942) (3952) (3952) (2531) (.7277847528457642) ("dorn")
    post `__posth' (339943) (3953) (3953) (3953) (1) ("dorn")
    post `__posth' (339944) (3955) (3955) (3955) (1) ("dorn")
    post `__posth' (339950) (3993) (3993) (3993) (1) ("dorn")
    post `__posth' (339991) (3053) (3053) (3053) (1) ("dorn")
    post `__posth' (339992) (3931) (3931) (3931) (1) ("dorn")
    post `__posth' (339993) (3965) (3965) (3131) (.9975771307945251) ("dorn")
    post `__posth' (339994) (3991) (3991) (2392) (.8250327110290527) ("dorn")
    post `__posth' (339995) (3995) (3995) (3995) (1) ("dorn")
    post `__posth' (339999) (3999) (3999) (2499) (.8146674633026123) ("dorn")
    post `__posth' (421110) (5012) (5012) (5012) (1) ("dorn")
    post `__posth' (421120) (5013) (5013) (5013) (1) ("dorn")
    post `__posth' (421130) (5014) (5014) (5014) (1) ("dorn")
    post `__posth' (421140) (5015) (5015) (5015) (1) ("dorn")
    post `__posth' (421210) (5021) (5021) (5021) (1) ("dorn")
    post `__posth' (421220) (5023) (5023) (5023) (1) ("dorn")
    post `__posth' (421310) (5031) (5031) (5031) (1) ("dorn")
    post `__posth' (421320) (5032) (5032) (5032) (1) ("dorn")
    post `__posth' (421330) (5033) (5033) (5033) (1) ("dorn")
    post `__posth' (421390) (5039) (5039) (5039) (1) ("dorn")
    post `__posth' (421410) (5043) (5043) (5043) (1) ("dorn")
    post `__posth' (421420) (5044) (5044) (5044) (1) ("dorn")
    post `__posth' (421430) (5045) (5045) (5045) (1) ("dorn")
    post `__posth' (421440) (5046) (5046) (5046) (1) ("dorn")
    post `__posth' (421450) (5047) (5047) (5047) (1) ("dorn")
    post `__posth' (421460) (5048) (5048) (5048) (1) ("dorn")
    post `__posth' (421490) (5049) (5049) (5049) (1) ("dorn")
    post `__posth' (421510) (5051) (5051) (5051) (1) ("dorn")
    post `__posth' (421520) (5052) (5052) (5052) (1) ("dorn")
    post `__posth' (421610) (5063) (5063) (5063) (1) ("dorn")
    post `__posth' (421620) (5064) (5064) (5064) (1) ("dorn")
    post `__posth' (421690) (5065) (5065) (5065) (1) ("dorn")
    post `__posth' (421710) (5072) (5072) (5072) (1) ("dorn")
    post `__posth' (421720) (5074) (5074) (5074) (1) ("dorn")
    post `__posth' (421730) (5075) (5075) (5075) (1) ("dorn")
    post `__posth' (421740) (5078) (5078) (5078) (1) ("dorn")
    post `__posth' (421810) (5082) (5082) (5082) (1) ("dorn")
    post `__posth' (421820) (5083) (5083) (5083) (1) ("dorn")
    post `__posth' (421830) (5084) (5084) (5084) (.9222474098205566) ("dorn")
    post `__posth' (421840) (5085) (5085) (5085) (1) ("dorn")
    post `__posth' (421850) (5087) (5087) (5087) (1) ("dorn")
    post `__posth' (421860) (5088) (5088) (5088) (1) ("dorn")
    post `__posth' (421910) (5091) (5091) (5091) (1) ("dorn")
    post `__posth' (421920) (5092) (5092) (5092) (1) ("dorn")
    post `__posth' (421930) (5093) (5093) (5093) (1) ("dorn")
    post `__posth' (421940) (5094) (5094) (5094) (1) ("dorn")
    post `__posth' (421990) (5099) (5099) (5099) (.8837045431137085) ("dorn")
    post `__posth' (422110) (5111) (5111) (5111) (1) ("dorn")
    post `__posth' (422120) (5112) (5112) (5112) (1) ("dorn")
    post `__posth' (422130) (5113) (5113) (5113) (1) ("dorn")
    post `__posth' (422210) (5122) (5122) (5122) (1) ("dorn")
    post `__posth' (422310) (5131) (5131) (5131) (1) ("dorn")
    post `__posth' (422320) (5136) (5136) (5136) (1) ("dorn")
    post `__posth' (422330) (5137) (5137) (5137) (1) ("dorn")
    post `__posth' (422340) (5139) (5139) (5139) (1) ("dorn")
    post `__posth' (422410) (5141) (5141) (5141) (1) ("dorn")
    post `__posth' (422420) (5142) (5142) (5142) (1) ("dorn")
    post `__posth' (422430) (5143) (5143) (5143) (1) ("dorn")
    post `__posth' (422440) (5144) (5144) (5144) (1) ("dorn")
    post `__posth' (422450) (5145) (5145) (5145) (1) ("dorn")
    post `__posth' (422460) (5146) (5146) (5146) (1) ("dorn")
    post `__posth' (422470) (5147) (5147) (5147) (1) ("dorn")
    post `__posth' (422480) (5148) (5148) (5148) (1) ("dorn")
    post `__posth' (422490) (5149) (5149) (5149) (1) ("dorn")
    post `__posth' (422510) (5153) (5153) (5153) (1) ("dorn")
    post `__posth' (422520) (5154) (5154) (5154) (1) ("dorn")
    post `__posth' (422590) (5159) (5159) (5159) (1) ("dorn")
    post `__posth' (422610) (5162) (5162) (5162) (1) ("dorn")
    post `__posth' (422690) (5169) (5169) (5169) (1) ("dorn")
    post `__posth' (422710) (5171) (5171) (5171) (1) ("dorn")
    post `__posth' (422720) (5172) (5172) (5172) (1) ("dorn")
    post `__posth' (422810) (5181) (5181) (5181) (1) ("dorn")
    post `__posth' (422820) (5182) (5182) (5182) (1) ("dorn")
    post `__posth' (422910) (5191) (5191) (5191) (1) ("dorn")
    post `__posth' (422920) (5192) (5192) (5192) (1) ("dorn")
    post `__posth' (422930) (5193) (5193) (5193) (1) ("dorn")
    post `__posth' (422940) (5194) (5194) (5194) (1) ("dorn")
    post `__posth' (422950) (5198) (5198) (5198) (1) ("dorn")
    post `__posth' (422990) (5199) (5199) (5199) (1) ("dorn")
    post `__posth' (423110) (5012) (5012) (5012) (.) ("census")
    post `__posth' (423120) (5013) (5013) (5013) (.) ("census")
    post `__posth' (423130) (5014) (5014) (5014) (.) ("census")
    post `__posth' (423140) (5015) (5015) (5015) (.) ("census")
    post `__posth' (423210) (5021) (5021) (5021) (.) ("census")
    post `__posth' (423220) (5023) (5023) (5023) (.) ("census")
    post `__posth' (423310) (5031) (5031) (5031) (.) ("census")
    post `__posth' (423320) (5032) (5032) (5032) (.) ("census")
    post `__posth' (423330) (5033) (5033) (5033) (.) ("census")
    post `__posth' (423390) (5039) (5039) (5039) (.) ("census")
    post `__posth' (423410) (5043) (5043) (5043) (.) ("census")
    post `__posth' (423420) (5044) (5044) (5044) (.) ("census")
    post `__posth' (423430) (5045) (5045) (5045) (.) ("census")
    post `__posth' (423440) (5046) (5046) (5046) (.) ("census")
    post `__posth' (423450) (5047) (5047) (5047) (.) ("census")
    post `__posth' (423460) (5048) (5048) (5048) (.) ("census")
    post `__posth' (423490) (5049) (5049) (5049) (.) ("census")
    post `__posth' (423510) (5051) (5051) (5051) (.) ("census")
    post `__posth' (423520) (5052) (5052) (5052) (.) ("census")
    post `__posth' (423610) (5063) (5063) (5063) (.) ("census")
    post `__posth' (423620) (5064) (5064) (5064) (.) ("census")
    post `__posth' (423690) (5065) (5065) (5065) (.) ("census")
    post `__posth' (423710) (5072) (5072) (5072) (.) ("census")
    post `__posth' (423720) (5074) (5074) (5074) (.) ("census")
    post `__posth' (423730) (5075) (5075) (5075) (.) ("census")
    post `__posth' (423740) (5078) (5078) (5078) (.) ("census")
    post `__posth' (423810) (5082) (5082) (5082) (.) ("census")
    post `__posth' (423820) (5083) (5083) (5083) (.) ("census")
    post `__posth' (423830) (5084) (5084) (5084) (.) ("census")
    post `__posth' (423840) (5085) (5085) (5085) (.) ("census")
    post `__posth' (423850) (5087) (5087) (5087) (.) ("census")
    post `__posth' (423860) (5088) (5088) (5088) (.) ("census")
    post `__posth' (423910) (5091) (5091) (5091) (.) ("census")
    post `__posth' (423920) (5092) (5092) (5092) (.) ("census")
    post `__posth' (423930) (5093) (5093) (5093) (.) ("census")
    post `__posth' (423940) (5094) (5094) (5094) (.) ("census")
    post `__posth' (423990) (5099) (5099) (5099) (.) ("census")
    post `__posth' (424110) (5111) (5111) (5111) (.) ("census")
    post `__posth' (424120) (5112) (5112) (5112) (.) ("census")
    post `__posth' (424130) (5113) (5113) (5113) (.) ("census")
    post `__posth' (424210) (5122) (5122) (5122) (.) ("census")
    post `__posth' (424310) (5131) (5131) (5131) (.) ("census")
    post `__posth' (424320) (5136) (5136) (5136) (.) ("census")
    post `__posth' (424330) (5137) (5137) (5137) (.) ("census")
    post `__posth' (424340) (5139) (5139) (5139) (.) ("census")
    post `__posth' (424350) (5136) (5136) (5136) (.) ("census")
    post `__posth' (424410) (5141) (5141) (5141) (.) ("census")
    post `__posth' (424420) (5142) (5142) (5142) (.) ("census")
    post `__posth' (424430) (5143) (5143) (5143) (.) ("census")
    post `__posth' (424440) (5144) (5144) (5144) (.) ("census")
    post `__posth' (424450) (5145) (5145) (5145) (.) ("census")
    post `__posth' (424460) (5146) (5146) (5146) (.) ("census")
    post `__posth' (424470) (5147) (5147) (5147) (.) ("census")
    post `__posth' (424480) (5148) (5148) (5148) (.) ("census")
    post `__posth' (424490) (5149) (5149) (5149) (.) ("census")
    post `__posth' (424510) (5153) (5153) (5153) (.) ("census")
    post `__posth' (424520) (5154) (5154) (5154) (.) ("census")
    post `__posth' (424590) (5159) (5159) (5159) (.) ("census")
    post `__posth' (424610) (5162) (5162) (5162) (.) ("census")
    post `__posth' (424690) (5169) (5169) (5169) (.) ("census")
    post `__posth' (424710) (5171) (5171) (5171) (.) ("census")
    post `__posth' (424720) (5172) (5172) (5172) (.) ("census")
    post `__posth' (424810) (5181) (5181) (5181) (.) ("census")
    post `__posth' (424820) (5182) (5182) (5182) (.) ("census")
    post `__posth' (424910) (5191) (5191) (5191) (.) ("census")
    post `__posth' (424920) (5192) (5192) (5192) (.) ("census")
    post `__posth' (424930) (5193) (5193) (5193) (.) ("census")
    post `__posth' (424940) (5194) (5194) (5194) (.) ("census")
    post `__posth' (424950) (5198) (5198) (5198) (.) ("census")
    post `__posth' (424990) (5199) (5199) (5199) (.) ("census")
    post `__posth' (425110) (5012) (5012) (5012) (.) ("census")
    post `__posth' (425120) (5012) (5012) (5012) (.) ("census")
    post `__posth' (441110) (5511) (5511) (5511) (1) ("dorn")
    post `__posth' (441120) (5521) (5521) (5521) (1) ("dorn")
    post `__posth' (441210) (5561) (5561) (5561) (1) ("dorn")
    post `__posth' (441221) (5571) (5571) (5571) (1) ("dorn")
    post `__posth' (441222) (5551) (5551) (5551) (1) ("dorn")
    post `__posth' (441227) (5571) (5571) (5571) (1) ("dorn")
    post `__posth' (441229) (5599) (5599) (5599) (1) ("dorn")
    post `__posth' (441310) (5531) (5531) (5013) (.5248358845710754) ("dorn")
    post `__posth' (441320) (5531) (5531) (5014) (.7978394031524658) ("dorn")
    post `__posth' (441330) (5531) (5531) (5013) (.5248358845710754) ("dorn")
    post `__posth' (441340) (5531) (5531) (5014) (.7978394031524658) ("dorn")
    post `__posth' (442110) (5712) (5712) (5021) (.94487464427948) ("dorn")
    post `__posth' (442210) (5713) (5713) (5023) (.7880668640136719) ("dorn")
    post `__posth' (442291) (5719) (5719) (5714) (.5354468822479248) ("dorn")
    post `__posth' (442299) (5719) (5719) (5719) (1) ("dorn")
    post `__posth' (443111) (5722) (5722) (5722) (1) ("dorn")
    post `__posth' (443112) (5731) (5731) (5731) (.8955393433570862) ("dorn")
    post `__posth' (443120) (5734) (5734) (5045) (.7286438941955566) ("dorn")
    post `__posth' (443130) (5946) (5946) (5946) (1) ("dorn")
    post `__posth' (444110) (5211) (5211) (5211) (1) ("dorn")
    post `__posth' (444120) (5231) (5231) (5198) (.8741181492805481) ("dorn")
    post `__posth' (444130) (5251) (5251) (5251) (1) ("dorn")
    post `__posth' (444140) (5251) (5251) (5251) (1) ("dorn")
    post `__posth' (444180) (5211) (5211) (5031) (.4922715425491333) ("dorn")
    post `__posth' (444190) (5211) (5211) (5031) (.4922715425491333) ("dorn")
    post `__posth' (444210) (5261) (5261) (5083) (.762944221496582) ("dorn")
    post `__posth' (444220) (5191) (5191) (5191) (.5186830163002014) ("dorn")
    post `__posth' (444230) (5261) (5261) (5083) (.762944221496582) ("dorn")
    post `__posth' (444240) (5191) (5191) (5191) (.5186830163002014) ("dorn")
    post `__posth' (445110) (5411) (5411) (5411) (1) ("dorn")
    post `__posth' (445120) (5411) (5411) (5411) (1) ("dorn")
    post `__posth' (445131) (5411) (5411) (5411) (1) ("dorn")
    post `__posth' (445132) (5962) (5962) (5962) (1) ("dorn")
    post `__posth' (445210) (5421) (5421) (5411) (.7589424848556519) ("dorn")
    post `__posth' (445220) (5421) (5421) (5421) (1) ("dorn")
    post `__posth' (445230) (5431) (5431) (5431) (1) ("dorn")
    post `__posth' (445240) (5421) (5421) (5411) (.7589424848556519) ("dorn")
    post `__posth' (445250) (5421) (5421) (5421) (1) ("dorn")
    post `__posth' (445291) (5461) (5461) (5461) (1) ("dorn")
    post `__posth' (445292) (5441) (5441) (5441) (1) ("dorn")
    post `__posth' (445298) (5499) (5499) (5451) (.6854882836341858) ("dorn")
    post `__posth' (445299) (5499) (5499) (5451) (.6854882836341858) ("dorn")
    post `__posth' (445310) (5921) (5921) (5921) (1) ("dorn")
    post `__posth' (445320) (5921) (5921) (5921) (1) ("dorn")
    post `__posth' (446110) (5912) (5912) (5912) (1) ("dorn")
    post `__posth' (446120) (5999) (5999) (5087) (.9707911610603333) ("dorn")
    post `__posth' (446130) (5995) (5995) (5995) (1) ("dorn")
    post `__posth' (446191) (5499) (5499) (5499) (1) ("dorn")
    post `__posth' (446199) (5999) (5999) (5047) (.7626287937164307) ("dorn")
    post `__posth' (447110) (5541) (5541) (5411) (.7051552534103394) ("dorn")
    post `__posth' (447190) (5541) (5541) (5541) (1) ("dorn")
    post `__posth' (448110) (5611) (5611) (5611) (1) ("dorn")
    post `__posth' (448120) (5621) (5621) (5621) (1) ("dorn")
    post `__posth' (448130) (5641) (5641) (5641) (1) ("dorn")
    post `__posth' (448140) (5651) (5651) (5651) (1) ("dorn")
    post `__posth' (448150) (5632) (5632) (5632) (.8773394227027893) ("dorn")
    post `__posth' (448190) (5699) (5699) (5632) (.5759096741676331) ("dorn")
    post `__posth' (448210) (5661) (5661) (5661) (1) ("dorn")
    post `__posth' (448310) (5944) (5944) (5944) (1) ("dorn")
    post `__posth' (448320) (5948) (5948) (5948) (1) ("dorn")
    post `__posth' (449110) (5712) (5712) (5021) (.94487464427948) ("dorn")
    post `__posth' (449121) (5713) (5713) (5023) (.7880668640136719) ("dorn")
    post `__posth' (449122) (5719) (5719) (5714) (.5354468822479248) ("dorn")
    post `__posth' (449129) (5719) (5719) (5719) (1) ("dorn")
    post `__posth' (449210) (5722) (5722) (5722) (1) ("dorn")
    post `__posth' (451110) (5941) (5941) (5941) (1) ("dorn")
    post `__posth' (451120) (5945) (5945) (5945) (1) ("dorn")
    post `__posth' (451130) (5949) (5949) (5714) (.9731428027153015) ("dorn")
    post `__posth' (451140) (5736) (5736) (5736) (1) ("dorn")
    post `__posth' (451211) (5942) (5942) (5942) (1) ("dorn")
    post `__posth' (451212) (5994) (5994) (5994) (1) ("dorn")
    post `__posth' (451220) (5735) (5735) (5735) (1) ("dorn")
    post `__posth' (452110) (5311) (5311) (5311) (1) ("dorn")
    post `__posth' (452111) (5311) (5311) (5311) (.) ("census")
    post `__posth' (452112) (5311) (5311) (5311) (.) ("census")
    post `__posth' (452910) (5311) (5311) (5311) (.6918948292732239) ("dorn")
    post `__posth' (452990) (5399) (5399) (5331) (.5306164026260376) ("dorn")
    post `__posth' (453110) (5992) (5992) (5992) (1) ("dorn")
    post `__posth' (453210) (5112) (5112) (5049) (.7793336510658264) ("dorn")
    post `__posth' (453220) (5947) (5947) (5947) (1) ("dorn")
    post `__posth' (453310) (5932) (5932) (5932) (1) ("dorn")
    post `__posth' (453910) (5999) (5999) (5999) (1) ("dorn")
    post `__posth' (453920) (5999) (5999) (5999) (1) ("dorn")
    post `__posth' (453930) (5271) (5271) (5271) (1) ("dorn")
    post `__posth' (453991) (5993) (5993) (5993) (1) ("dorn")
    post `__posth' (453998) (5999) (5999) (5999) (1) ("dorn")
    post `__posth' (454110) (5961) (5961) (5045) (.943646252155304) ("dorn")
    post `__posth' (454111) (5961) (5961) (5961) (.) ("census")
    post `__posth' (454112) (5961) (5961) (5961) (.) ("census")
    post `__posth' (454113) (5961) (5961) (5961) (.) ("census")
    post `__posth' (454210) (5962) (5962) (5962) (1) ("dorn")
    post `__posth' (454311) (5983) (5983) (5171) (.8581857681274414) ("dorn")
    post `__posth' (454312) (5984) (5984) (5171) (.8761889338493347) ("dorn")
    post `__posth' (454319) (5989) (5989) (5989) (1) ("dorn")
    post `__posth' (454390) (5963) (5963) (5421) (.9814746975898743) ("dorn")
    post `__posth' (455110) (5311) (5311) (5311) (.) ("census")
    post `__posth' (455211) (5311) (5311) (5311) (.) ("census")
    post `__posth' (455219) (5399) (5399) (5331) (.5306164026260376) ("dorn")
    post `__posth' (456110) (5912) (5912) (5912) (1) ("dorn")
    post `__posth' (456120) (5999) (5999) (5087) (.9707911610603333) ("dorn")
    post `__posth' (456130) (5995) (5995) (5995) (1) ("dorn")
    post `__posth' (456191) (5499) (5499) (5499) (1) ("dorn")
    post `__posth' (456199) (5999) (5999) (5047) (.7626287937164307) ("dorn")
    post `__posth' (457110) (5541) (5541) (5411) (.7051552534103394) ("dorn")
    post `__posth' (457120) (5541) (5541) (5541) (1) ("dorn")
    post `__posth' (457210) (5983) (5983) (5171) (.8581857681274414) ("dorn")
    post `__posth' (458110) (5611) (5611) (5611) (1) ("dorn")
    post `__posth' (458210) (5661) (5661) (5661) (1) ("dorn")
    post `__posth' (458310) (5944) (5944) (5944) (1) ("dorn")
    post `__posth' (458320) (5948) (5948) (5948) (1) ("dorn")
    post `__posth' (459110) (5941) (5941) (5941) (1) ("dorn")
    post `__posth' (459120) (5945) (5945) (5945) (1) ("dorn")
    post `__posth' (459130) (5949) (5949) (5714) (.9731428027153015) ("dorn")
    post `__posth' (459140) (5736) (5736) (5736) (1) ("dorn")
    post `__posth' (459210) (5942) (5942) (5942) (1) ("dorn")
    post `__posth' (459310) (5992) (5992) (5992) (1) ("dorn")
    post `__posth' (459410) (5112) (5112) (5049) (.7793336510658264) ("dorn")
    post `__posth' (459420) (5947) (5947) (5947) (1) ("dorn")
    post `__posth' (459510) (5932) (5932) (5932) (1) ("dorn")
    post `__posth' (459910) (5999) (5999) (5999) (1) ("dorn")
    post `__posth' (459920) (5999) (5999) (5999) (1) ("dorn")
    post `__posth' (459930) (5271) (5271) (5271) (1) ("dorn")
    post `__posth' (459991) (5993) (5993) (5993) (1) ("dorn")
    post `__posth' (459999) (5999) (5999) (5999) (1) ("dorn")
    post `__posth' (481111) (4512) (4512) (4512) (1) ("dorn")
    post `__posth' (481112) (4512) (4512) (4512) (1) ("dorn")
    post `__posth' (481211) (4522) (4522) (4522) (1) ("dorn")
    post `__posth' (481212) (4522) (4522) (4522) (1) ("dorn")
    post `__posth' (481219) (4522) (4522) (4522) (1) ("dorn")
    post `__posth' (482111) (4011) (4011) (4011) (.) ("census")
    post `__posth' (482112) (4013) (4013) (4013) (.) ("census")
    post `__posth' (483111) (4412) (4412) (4412) (1) ("dorn")
    post `__posth' (483112) (4481) (4481) (4481) (1) ("dorn")
    post `__posth' (483113) (4424) (4424) (4424) (.5784693360328674) ("dorn")
    post `__posth' (483114) (4481) (4481) (4481) (.5122086405754089) ("dorn")
    post `__posth' (483211) (4449) (4449) (4449) (.6785417795181274) ("dorn")
    post `__posth' (483212) (4489) (4489) (4482) (.6485832929611206) ("dorn")
    post `__posth' (484110) (4212) (4212) (4212) (.8791190385818481) ("dorn")
    post `__posth' (484121) (4213) (4213) (4213) (.9774943590164185) ("dorn")
    post `__posth' (484122) (4213) (4213) (4213) (.9774943590164185) ("dorn")
    post `__posth' (484210) (4213) (4213) (4212) (.5286269783973694) ("dorn")
    post `__posth' (484220) (4212) (4212) (4212) (.9295461773872375) ("dorn")
    post `__posth' (484230) (4213) (4213) (4213) (.9774943590164185) ("dorn")
    post `__posth' (485111) (4111) (4111) (4111) (1) ("dorn")
    post `__posth' (485112) (4111) (4111) (4111) (1) ("dorn")
    post `__posth' (485113) (4111) (4111) (4111) (1) ("dorn")
    post `__posth' (485119) (4111) (4111) (4111) (1) ("dorn")
    post `__posth' (485210) (4131) (4131) (4131) (1) ("dorn")
    post `__posth' (485310) (4121) (4121) (4121) (1) ("dorn")
    post `__posth' (485320) (4119) (4119) (4119) (1) ("dorn")
    post `__posth' (485410) (4151) (4151) (4119) (.9721555709838867) ("dorn")
    post `__posth' (485510) (4142) (4142) (4141) (.7238509654998779) ("dorn")
    post `__posth' (485991) (4119) (4119) (4119) (1) ("dorn")
    post `__posth' (485999) (4111) (4111) (4111) (.9257217645645142) ("dorn")
    post `__posth' (486110) (4612) (4612) (4612) (1) ("dorn")
    post `__posth' (486210) (4922) (4922) (4922) (.5632177591323853) ("dorn")
    post `__posth' (486910) (4613) (4613) (4613) (1) ("dorn")
    post `__posth' (486990) (4619) (4619) (4619) (1) ("dorn")
    post `__posth' (487110) (4119) (4119) (4119) (.8335967063903809) ("dorn")
    post `__posth' (487210) (4489) (4489) (4489) (.7632710337638855) ("dorn")
    post `__posth' (487990) (4522) (4522) (4522) (.9418060183525085) ("dorn")
    post `__posth' (488111) (4581) (4581) (4581) (1) ("dorn")
    post `__posth' (488119) (4581) (4581) (4581) (.9985560178756714) ("dorn")
    post `__posth' (488190) (4581) (4581) (4581) (1) ("dorn")
    post `__posth' (488210) (4789) (4789) (4789) (1) ("dorn")
    post `__posth' (488310) (4491) (4491) (4491) (1) ("dorn")
    post `__posth' (488320) (4491) (4491) (4491) (1) ("dorn")
    post `__posth' (488330) (4492) (4492) (4492) (.7397222518920898) ("dorn")
    post `__posth' (488390) (4499) (4499) (4499) (.6841776967048645) ("dorn")
    post `__posth' (488410) (7549) (7549) (7549) (1) ("dorn")
    post `__posth' (488490) (4789) (4789) (4173) (.7204545736312866) ("dorn")
    post `__posth' (488510) (4731) (4731) (4731) (1) ("dorn")
    post `__posth' (488991) (4783) (4783) (4783) (1) ("dorn")
    post `__posth' (488999) (4789) (4789) (4729) (.949715793132782) ("dorn")
    post `__posth' (491110) (4311) (4311) (4311) (.) ("census")
    post `__posth' (492110) (4215) (4215) (4215) (.6853953003883362) ("dorn")
    post `__posth' (492210) (4215) (4215) (4215) (1) ("dorn")
    post `__posth' (493110) (70001) (4225) (4225) (.4644961357116699) ("dorn")
    post `__posth' (493120) (70001) (4222) (4222) (.4644961357116699) ("dorn")
    post `__posth' (493130) (70001) (4221) (4221) (.4644961357116699) ("dorn")
    post `__posth' (493190) (70001) (4226) (4226) (.4644961357116699) ("dorn")
    post `__posth' (511110) (2711) (2711) (2711) (1) ("dorn")
    post `__posth' (511120) (2721) (2721) (2721) (1) ("dorn")
    post `__posth' (511130) (2731) (2731) (2731) (1) ("dorn")
    post `__posth' (511140) (2741) (2741) (2741) (.7657778263092041) ("dorn")
    post `__posth' (511191) (2771) (2771) (2771) (1) ("dorn")
    post `__posth' (511199) (2741) (2741) (2741) (1) ("dorn")
    post `__posth' (511210) (7372) (7372) (7372) (1) ("dorn")
    post `__posth' (512110) (7812) (7812) (7812) (1) ("dorn")
    post `__posth' (512120) (7822) (7822) (7822) (1) ("dorn")
    post `__posth' (512131) (7832) (7832) (7832) (1) ("dorn")
    post `__posth' (512132) (7833) (7833) (7833) (1) ("dorn")
    post `__posth' (512191) (7819) (7819) (7819) (1) ("dorn")
    post `__posth' (512199) (7819) (7819) (7819) (.7445612549781799) ("dorn")
    post `__posth' (512210) (8999) (8999) (8999) (1) ("dorn")
    post `__posth' (512220) (8999) (8999) (8999) (1) ("dorn")
    post `__posth' (512230) (8999) (8999) (2731) (.4613610208034515) ("dorn")
    post `__posth' (512240) (7389) (7389) (7389) (1) ("dorn")
    post `__posth' (512250) (8999) (8999) (8999) (1) ("dorn")
    post `__posth' (512290) (7389) (7389) (7389) (.5092838406562805) ("dorn")
    post `__posth' (513110) (2711) (2711) (2711) (1) ("dorn")
    post `__posth' (513111) (4832) (4832) (4832) (1) ("dorn")
    post `__posth' (513112) (4832) (4832) (4832) (1) ("dorn")
    post `__posth' (513120) (4833) (4833) (4833) (1) ("dorn")
    post `__posth' (513130) (2731) (2731) (2731) (1) ("dorn")
    post `__posth' (513140) (2741) (2741) (2741) (.7657778263092041) ("dorn")
    post `__posth' (513191) (2771) (2771) (2771) (1) ("dorn")
    post `__posth' (513199) (2741) (2741) (2741) (1) ("dorn")
    post `__posth' (513210) (4841) (4841) (4841) (1) ("dorn")
    post `__posth' (513220) (4841) (4841) (4841) (1) ("dorn")
    post `__posth' (513310) (4813) (4813) (4813) (.9981813430786133) ("dorn")
    post `__posth' (513321) (4812) (4812) (4812) (1) ("dorn")
    post `__posth' (513322) (4812) (4812) (4812) (.9687965512275696) ("dorn")
    post `__posth' (513330) (4813) (4813) (4812) (.8697881698608398) ("dorn")
    post `__posth' (513340) (4899) (4899) (4899) (1) ("dorn")
    post `__posth' (513390) (4899) (4899) (4899) (1) ("dorn")
    post `__posth' (514110) (7383) (7383) (7383) (1) ("dorn")
    post `__posth' (514120) (8231) (8231) (8231) (1) ("dorn")
    post `__posth' (514191) (7375) (7375) (7375) (1) ("dorn")
    post `__posth' (514199) (8999) (8999) (8999) (1) ("dorn")
    post `__posth' (514210) (7374) (7374) (7374) (.8649320602416992) ("dorn")
    post `__posth' (515111) (4832) (4832) (4832) (.) ("census")
    post `__posth' (515112) (4832) (4832) (4832) (.) ("census")
    post `__posth' (515120) (4833) (4833) (4833) (.) ("census")
    post `__posth' (515210) (4841) (4841) (4841) (.) ("census")
    post `__posth' (516110) (2711) (2711) (2711) (.) ("census")
    post `__posth' (516120) (4833) (4833) (4833) (.) ("census")
    post `__posth' (516210) (4832) (4832) (4832) (.) ("census")
    post `__posth' (517110) (4813) (4813) (4813) (.) ("census")
    post `__posth' (517111) (4813) (4813) (4813) (.) ("census")
    post `__posth' (517112) (4812) (4812) (4812) (.) ("census")
    post `__posth' (517121) (4812) (4812) (4812) (.) ("census")
    post `__posth' (517122) (4812) (4812) (4812) (.) ("census")
    post `__posth' (517211) (4812) (4812) (4812) (.) ("census")
    post `__posth' (517212) (4812) (4812) (4812) (.) ("census")
    post `__posth' (517310) (4812) (4812) (4812) (.) ("census")
    post `__posth' (517410) (4899) (4899) (4899) (.) ("census")
    post `__posth' (517510) (4841) (4841) (4841) (.) ("census")
    post `__posth' (517810) (4899) (4899) (4899) (.) ("census")
    post `__posth' (517910) (4899) (4899) (4899) (.) ("census")
    post `__posth' (518111) (7375) (7375) (7375) (.) ("census")
    post `__posth' (518112) (8999) (8999) (8999) (.) ("census")
    post `__posth' (518210) (7374) (7374) (7374) (.) ("census")
    post `__posth' (519110) (7383) (7383) (7383) (.) ("census")
    post `__posth' (519120) (7829) (7829) (7829) (.) ("census")
    post `__posth' (519190) (7389) (7389) (7389) (.) ("census")
    post `__posth' (519210) (7829) (7829) (7829) (.) ("census")
    post `__posth' (519290) (2711) (2711) (2711) (.) ("census")
    post `__posth' (521110) (6011) (6011) (6011) (1) ("dorn")
    post `__posth' (522110) (6021) (6021) (6021) (.5693491101264954) ("dorn")
    post `__posth' (522120) (6035) (6035) (6035) (.6770088076591492) ("dorn")
    post `__posth' (522130) (6061) (6061) (6061) (.5988762974739075) ("dorn")
    post `__posth' (522180) (6035) (6035) (6035) (.6770088076591492) ("dorn")
    post `__posth' (522190) (6022) (6022) (6022) (1) ("dorn")
    post `__posth' (522210) (6022) (6022) (6021) (.4291426241397858) ("dorn")
    post `__posth' (522220) (6141) (6141) (6141) (.5267773270606995) ("dorn")
    post `__posth' (522291) (6141) (6141) (6141) (1) ("dorn")
    post `__posth' (522292) (6162) (6162) (6111) (.9803705215454102) ("dorn")
    post `__posth' (522293) (6082) (6082) (6081) (.6567620635032654) ("dorn")
    post `__posth' (522294) (6111) (6111) (6111) (.8128104209899902) ("dorn")
    post `__posth' (522298) (5932) (5932) (5932) (.4985241591930389) ("dorn")
    post `__posth' (522299) (6082) (6082) (6081) (.6567620635032654) ("dorn")
    post `__posth' (522310) (6163) (6163) (6163) (1) ("dorn")
    post `__posth' (522320) (6153) (6153) (6019) (.3815494179725647) ("dorn")
    post `__posth' (522390) (6099) (6099) (6099) (.5264396071434021) ("dorn")
    post `__posth' (523110) (6211) (6211) (6211) (1) ("dorn")
    post `__posth' (523120) (6211) (6211) (6211) (1) ("dorn")
    post `__posth' (523130) (6221) (6221) (6099) (.4494357109069824) ("dorn")
    post `__posth' (523140) (6221) (6221) (6221) (1) ("dorn")
    post `__posth' (523150) (6211) (6211) (6211) (1) ("dorn")
    post `__posth' (523160) (6221) (6221) (6099) (.4494357109069824) ("dorn")
    post `__posth' (523210) (6231) (6231) (6231) (1) ("dorn")
    post `__posth' (523910) (6799) (6799) (6211) (.8867055177688599) ("dorn")
    post `__posth' (523920) (6282) (6282) (6282) (.9946439266204834) ("dorn")
    post `__posth' (523930) (6282) (6282) (6282) (1) ("dorn")
    post `__posth' (523940) (6282) (6282) (6282) (.9946439266204834) ("dorn")
    post `__posth' (523991) (6289) (6289) (6091) (.4706226587295532) ("dorn")
    post `__posth' (523999) (6289) (6289) (6099) (.8832800984382629) ("dorn")
    post `__posth' (524113) (6311) (6311) (6311) (.9214923977851868) ("dorn")
    post `__posth' (524114) (6324) (6324) (6321) (.948307991027832) ("dorn")
    post `__posth' (524126) (6331) (6331) (6331) (.980237603187561) ("dorn")
    post `__posth' (524127) (6361) (6361) (6361) (1) ("dorn")
    post `__posth' (524128) (6399) (6399) (6399) (1) ("dorn")
    post `__posth' (524130) (6311) (6311) (6311) (.5696050524711609) ("dorn")
    post `__posth' (524210) (6411) (6411) (6411) (1) ("dorn")
    post `__posth' (524291) (6411) (6411) (6411) (1) ("dorn")
    post `__posth' (524292) (6411) (6411) (6371) (.7491766810417175) ("dorn")
    post `__posth' (524298) (6411) (6411) (6411) (1) ("dorn")
    post `__posth' (525110) (6371) (6371) (6371) (.) ("census")
    post `__posth' (525120) (6371) (6371) (6371) (.) ("census")
    post `__posth' (525190) (6321) (6321) (6321) (.) ("census")
    post `__posth' (525910) (6722) (6722) (6722) (1) ("dorn")
    post `__posth' (525920) (6733) (6733) (6733) (.) ("census")
    post `__posth' (525930) (6798) (6798) (6798) (1) ("dorn")
    post `__posth' (525990) (6726) (6726) (6726) (1) ("dorn")
    post `__posth' (531110) (6513) (6513) (6513) (.9001135230064392) ("dorn")
    post `__posth' (531120) (6512) (6512) (6512) (1) ("dorn")
    post `__posth' (531130) (4225) (4225) (4225) (1) ("dorn")
    post `__posth' (531190) (6515) (6515) (6515) (.7903144359588623) ("dorn")
    post `__posth' (531210) (6531) (6531) (6531) (1) ("dorn")
    post `__posth' (531311) (6531) (6531) (6531) (1) ("dorn")
    post `__posth' (531312) (6531) (6531) (6531) (1) ("dorn")
    post `__posth' (531320) (6531) (6531) (6531) (1) ("dorn")
    post `__posth' (531390) (6531) (6531) (6531) (1) ("dorn")
    post `__posth' (532111) (7514) (7514) (7514) (1) ("dorn")
    post `__posth' (532112) (7515) (7515) (7515) (1) ("dorn")
    post `__posth' (532120) (7513) (7513) (7513) (.9598845243453979) ("dorn")
    post `__posth' (532210) (7359) (7359) (7359) (1) ("dorn")
    post `__posth' (532220) (7299) (7299) (7299) (.9720005989074707) ("dorn")
    post `__posth' (532230) (7841) (7841) (7841) (1) ("dorn")
    post `__posth' (532281) (7299) (7299) (7299) (.9720005989074707) ("dorn")
    post `__posth' (532282) (7841) (7841) (7841) (1) ("dorn")
    post `__posth' (532283) (7352) (7352) (7352) (1) ("dorn")
    post `__posth' (532284) (7999) (7999) (7999) (1) ("dorn")
    post `__posth' (532289) (7359) (7359) (7299) (.99376380443573) ("dorn")
    post `__posth' (532291) (7352) (7352) (7352) (1) ("dorn")
    post `__posth' (532292) (7999) (7999) (7999) (1) ("dorn")
    post `__posth' (532299) (7359) (7359) (7299) (.99376380443573) ("dorn")
    post `__posth' (532310) (7359) (7359) (7359) (1) ("dorn")
    post `__posth' (532411) (7359) (7359) (4499) (.603046178817749) ("dorn")
    post `__posth' (532412) (7353) (7353) (7353) (.7906607389450073) ("dorn")
    post `__posth' (532420) (7377) (7377) (7359) (.7588906288146973) ("dorn")
    post `__posth' (532490) (7359) (7359) (7352) (.566895067691803) ("dorn")
    post `__posth' (533110) (6794) (6794) (6792) (.9689050912857056) ("dorn")
    post `__posth' (541110) (8111) (8111) (8111) (.9987845420837402) ("dorn")
    post `__posth' (541191) (6541) (6541) (6541) (.9987845420837402) ("dorn")
    post `__posth' (541199) (7389) (7389) (7389) (1) ("dorn")
    post `__posth' (541211) (8721) (8721) (8721) (.9525570869445801) ("dorn")
    post `__posth' (541213) (7291) (7291) (7291) (.9525570869445801) ("dorn")
    post `__posth' (541214) (8721) (8721) (7819) (.564938485622406) ("dorn")
    post `__posth' (541219) (8721) (8721) (8721) (.9525570869445801) ("dorn")
    post `__posth' (541310) (8712) (8712) (8712) (1) ("dorn")
    post `__posth' (541320) (781) (781) (781) (1) ("dorn")
    post `__posth' (541330) (8711) (8711) (8711) (1) ("dorn")
    post `__posth' (541340) (7389) (7389) (7389) (1) ("dorn")
    post `__posth' (541350) (7389) (7389) (7389) (1) ("dorn")
    post `__posth' (541360) (8713) (8713) (1081) (.6961130499839783) ("dorn")
    post `__posth' (541370) (8713) (8713) (7389) (.9647006392478943) ("dorn")
    post `__posth' (541380) (8734) (8734) (8734) (1) ("dorn")
    post `__posth' (541410) (7389) (7389) (7389) (1) ("dorn")
    post `__posth' (541420) (7389) (7389) (7389) (1) ("dorn")
    post `__posth' (541430) (7336) (7336) (7336) (.9976794123649597) ("dorn")
    post `__posth' (541490) (7389) (7389) (7389) (1) ("dorn")
    post `__posth' (541511) (7371) (7371) (7371) (1) ("dorn")
    post `__posth' (541512) (7373) (7373) (7373) (.6154814958572388) ("dorn")
    post `__posth' (541513) (7376) (7376) (7376) (1) ("dorn")
    post `__posth' (541519) (7379) (7379) (7379) (1) ("dorn")
    post `__posth' (541611) (8742) (8742) (8742) (1) ("dorn")
    post `__posth' (541612) (7361) (7361) (7361) (.4731194674968719) ("dorn")
    post `__posth' (541613) (8742) (8742) (8742) (1) ("dorn")
    post `__posth' (541614) (8742) (8742) (8742) (1) ("dorn")
    post `__posth' (541618) (8748) (8748) (4731) (.8967669010162354) ("dorn")
    post `__posth' (541620) (8999) (8999) (8999) (1) ("dorn")
    post `__posth' (541690) (8748) (8748) (8748) (.6825000643730164) ("dorn")
    post `__posth' (541710) (8731) (8731) (8731) (.4530733227729797) ("dorn")
    post `__posth' (541713) (8731) (8731) (8731) (.4530733227729797) ("dorn")
    post `__posth' (541714) (8731) (8731) (8731) (.4530733227729797) ("dorn")
    post `__posth' (541715) (8731) (8731) (8731) (.4530733227729797) ("dorn")
    post `__posth' (541720) (8732) (8732) (8732) (.3889302015304565) ("dorn")
    post `__posth' (541810) (7311) (7311) (7311) (.961032509803772) ("dorn")
    post `__posth' (541820) (8743) (8743) (8743) (.961032509803772) ("dorn")
    post `__posth' (541830) (7319) (7319) (7319) (.961032509803772) ("dorn")
    post `__posth' (541840) (7313) (7313) (7313) (.961032509803772) ("dorn")
    post `__posth' (541850) (7319) (7319) (7312) (.6142596006393433) ("dorn")
    post `__posth' (541860) (7331) (7331) (7331) (.961032509803772) ("dorn")
    post `__posth' (541870) (7319) (7319) (7319) (.961032509803772) ("dorn")
    post `__posth' (541890) (5199) (5199) (5199) (.423271507024765) ("dorn")
    post `__posth' (541910) (8732) (8732) (8732) (1) ("dorn")
    post `__posth' (541921) (7221) (7221) (7221) (1) ("dorn")
    post `__posth' (541922) (7335) (7335) (7335) (.9924905300140381) ("dorn")
    post `__posth' (541930) (7389) (7389) (7389) (1) ("dorn")
    post `__posth' (541940) (741) (741) (741) (1) ("dorn")
    post `__posth' (541990) (7389) (7389) (7389) (1) ("dorn")
    post `__posth' (551111) (6712) (6712) (6712) (1) ("dorn")
    post `__posth' (551112) (6719) (6719) (6082) (.9997371435165405) ("dorn")
    post `__posth' (551114) (70001) (90001) (20001) (.3413562476634979) ("dorn")
    post `__posth' (561110) (8741) (8741) (8741) (1) ("dorn")
    post `__posth' (561210) (8744) (8744) (8744) (1) ("dorn")
    post `__posth' (561310) (7361) (7361) (7361) (.9800172448158264) ("dorn")
    post `__posth' (561311) (7361) (7361) (7361) (.9800172448158264) ("dorn")
    post `__posth' (561312) (7361) (7361) (7361) (.4731194674968719) ("dorn")
    post `__posth' (561320) (7363) (7363) (7363) (.9982207417488098) ("dorn")
    post `__posth' (561330) (7363) (7363) (7363) (.9982207417488098) ("dorn")
    post `__posth' (561410) (7338) (7338) (7338) (1) ("dorn")
    post `__posth' (561421) (7389) (7389) (4813) (.7877479791641235) ("dorn")
    post `__posth' (561422) (7389) (7389) (7389) (1) ("dorn")
    post `__posth' (561431) (7389) (7389) (7389) (1) ("dorn")
    post `__posth' (561439) (7334) (7334) (7334) (1) ("dorn")
    post `__posth' (561440) (7322) (7322) (7322) (1) ("dorn")
    post `__posth' (561450) (7323) (7323) (7323) (1) ("dorn")
    post `__posth' (561491) (7389) (7389) (7322) (.9460646510124207) ("dorn")
    post `__posth' (561492) (7338) (7338) (7338) (1) ("dorn")
    post `__posth' (561499) (7389) (7389) (7389) (1) ("dorn")
    post `__posth' (561510) (4724) (4724) (4724) (1) ("dorn")
    post `__posth' (561520) (4725) (4725) (4725) (1) ("dorn")
    post `__posth' (561591) (7389) (7389) (7389) (1) ("dorn")
    post `__posth' (561599) (8699) (8699) (4729) (.3683519065380096) ("dorn")
    post `__posth' (561611) (7381) (7381) (7381) (.9975903630256653) ("dorn")
    post `__posth' (561612) (7381) (7381) (7381) (.9975903630256653) ("dorn")
    post `__posth' (561613) (7381) (7381) (7381) (.9975903630256653) ("dorn")
    post `__posth' (561621) (7382) (7382) (7382) (1) ("dorn")
    post `__posth' (561622) (7699) (7699) (7699) (1) ("dorn")
    post `__posth' (561710) (7342) (7342) (7342) (.9982602000236511) ("dorn")
    post `__posth' (561720) (7349) (7349) (4581) (.9905553460121155) ("dorn")
    post `__posth' (561730) (782) (782) (782) (1) ("dorn")
    post `__posth' (561740) (7217) (7217) (7217) (.9982602000236511) ("dorn")
    post `__posth' (561790) (7389) (7389) (4959) (.4335680603981018) ("dorn")
    post `__posth' (561910) (7389) (7389) (7389) (1) ("dorn")
    post `__posth' (561920) (7389) (7389) (7389) (1) ("dorn")
    post `__posth' (561990) (7389) (7389) (7389) (.9415770173072815) ("dorn")
    post `__posth' (562111) (4212) (4212) (4212) (1) ("dorn")
    post `__posth' (562112) (4212) (4212) (4212) (1) ("dorn")
    post `__posth' (562119) (4212) (4212) (4212) (1) ("dorn")
    post `__posth' (562211) (4953) (4953) (4953) (1) ("dorn")
    post `__posth' (562212) (4953) (4953) (4953) (1) ("dorn")
    post `__posth' (562213) (4953) (4953) (4953) (1) ("dorn")
    post `__posth' (562219) (4953) (4953) (4953) (1) ("dorn")
    post `__posth' (562910) (4959) (4959) (1799) (.5444455146789551) ("dorn")
    post `__posth' (562920) (4953) (4953) (4953) (1) ("dorn")
    post `__posth' (562991) (7699) (7699) (7359) (.8184456825256348) ("dorn")
    post `__posth' (562998) (4959) (4959) (4959) (1) ("dorn")
    post `__posth' (611110) (8211) (8211) (8211) (1) ("dorn")
    post `__posth' (611210) (8222) (8222) (8222) (1) ("dorn")
    post `__posth' (611310) (8221) (8221) (8221) (1) ("dorn")
    post `__posth' (611410) (8244) (8244) (8244) (1) ("dorn")
    post `__posth' (611420) (8243) (8243) (8243) (1) ("dorn")
    post `__posth' (611430) (8299) (8299) (8299) (1) ("dorn")
    post `__posth' (611511) (7231) (7231) (7231) (.9411137104034424) ("dorn")
    post `__posth' (611512) (8299) (8299) (8249) (.7547463178634644) ("dorn")
    post `__posth' (611513) (8249) (8249) (8249) (1) ("dorn")
    post `__posth' (611519) (8249) (8249) (8243) (.9735813140869141) ("dorn")
    post `__posth' (611610) (7911) (7911) (7911) (.6459816694259644) ("dorn")
    post `__posth' (611620) (7999) (7999) (7999) (1) ("dorn")
    post `__posth' (611630) (8299) (8299) (8299) (1) ("dorn")
    post `__posth' (611691) (8299) (8299) (8299) (1) ("dorn")
    post `__posth' (611692) (8299) (8299) (8299) (1) ("dorn")
    post `__posth' (611699) (8299) (8299) (8299) (1) ("dorn")
    post `__posth' (611710) (8748) (8748) (8299) (.6578156352043152) ("dorn")
    post `__posth' (621111) (8011) (8011) (8011) (.9660244584083557) ("dorn")
    post `__posth' (621112) (8011) (8011) (8011) (.9720348119735718) ("dorn")
    post `__posth' (621210) (8021) (8021) (8021) (1) ("dorn")
    post `__posth' (621310) (8041) (8041) (8041) (1) ("dorn")
    post `__posth' (621320) (8042) (8042) (8042) (1) ("dorn")
    post `__posth' (621330) (8049) (8049) (8049) (1) ("dorn")
    post `__posth' (621340) (8049) (8049) (8049) (1) ("dorn")
    post `__posth' (621391) (8043) (8043) (8043) (1) ("dorn")
    post `__posth' (621399) (8049) (8049) (8049) (1) ("dorn")
    post `__posth' (621410) (8093) (8093) (8093) (.9814038276672363) ("dorn")
    post `__posth' (621420) (8093) (8093) (8093) (1) ("dorn")
    post `__posth' (621491) (8011) (8011) (8011) (1) ("dorn")
    post `__posth' (621492) (8092) (8092) (8092) (1) ("dorn")
    post `__posth' (621493) (8011) (8011) (8011) (1) ("dorn")
    post `__posth' (621498) (8093) (8093) (8093) (1) ("dorn")
    post `__posth' (621511) (8071) (8071) (8071) (1) ("dorn")
    post `__posth' (621512) (8071) (8071) (8071) (1) ("dorn")
    post `__posth' (621610) (8082) (8082) (8082) (1) ("dorn")
    post `__posth' (621910) (4119) (4119) (4119) (.9561973214149475) ("dorn")
    post `__posth' (621991) (8099) (8099) (8099) (1) ("dorn")
    post `__posth' (621999) (8099) (8099) (8099) (1) ("dorn")
    post `__posth' (622110) (8062) (8062) (8062) (.9796776175498962) ("dorn")
    post `__posth' (622210) (8063) (8063) (8063) (.9531491994857788) ("dorn")
    post `__posth' (622310) (8069) (8069) (8069) (1) ("dorn")
    post `__posth' (623110) (8053) (8053) (8053) (1) ("dorn")
    post `__posth' (623210) (8053) (8053) (8053) (1) ("dorn")
    post `__posth' (623220) (8361) (8361) (8361) (1) ("dorn")
    post `__posth' (623311) (8053) (8053) (8053) (1) ("dorn")
    post `__posth' (623312) (8361) (8361) (8361) (1) ("dorn")
    post `__posth' (623990) (8361) (8361) (8361) (1) ("dorn")
    post `__posth' (624110) (8322) (8322) (8322) (.7222606539726257) ("dorn")
    post `__posth' (624120) (8322) (8322) (8322) (1) ("dorn")
    post `__posth' (624190) (8322) (8322) (8322) (1) ("dorn")
    post `__posth' (624210) (8322) (8322) (8322) (1) ("dorn")
    post `__posth' (624221) (8322) (8322) (8322) (1) ("dorn")
    post `__posth' (624229) (8322) (8322) (8322) (1) ("dorn")
    post `__posth' (624230) (8322) (8322) (8322) (1) ("dorn")
    post `__posth' (624310) (8331) (8331) (8331) (1) ("dorn")
    post `__posth' (624410) (8351) (8351) (7299) (.9984078407287598) ("dorn")
    post `__posth' (711110) (7922) (7922) (5812) (.8805612921714783) ("dorn")
    post `__posth' (711120) (7922) (7922) (7922) (1) ("dorn")
    post `__posth' (711130) (7929) (7929) (7929) (1) ("dorn")
    post `__posth' (711190) (7929) (7929) (7929) (.7029796242713928) ("dorn")
    post `__posth' (711211) (7941) (7941) (7941) (1) ("dorn")
    post `__posth' (711212) (7948) (7948) (7948) (1) ("dorn")
    post `__posth' (711219) (7948) (7948) (7948) (.8914192914962769) ("dorn")
    post `__posth' (711310) (7922) (7922) (6512) (.5274540781974792) ("dorn")
    post `__posth' (711320) (7922) (7922) (7922) (.5363327860832214) ("dorn")
    post `__posth' (711410) (7922) (7922) (7389) (.690913200378418) ("dorn")
    post `__posth' (711510) (8999) (8999) (7819) (.4566301107406616) ("dorn")
    post `__posth' (712110) (8412) (8412) (8412) (1) ("dorn")
    post `__posth' (712120) (8412) (8412) (8412) (1) ("dorn")
    post `__posth' (712130) (8422) (8422) (8422) (1) ("dorn")
    post `__posth' (712190) (8422) (8422) (7999) (.5964670181274414) ("dorn")
    post `__posth' (713110) (7996) (7996) (7996) (1) ("dorn")
    post `__posth' (713120) (7993) (7993) (7993) (1) ("dorn")
    post `__posth' (713210) (7999) (7999) (7999) (1) ("dorn")
    post `__posth' (713290) (7999) (7999) (7993) (.7122013568878174) ("dorn")
    post `__posth' (713910) (7997) (7997) (7992) (.7196843028068542) ("dorn")
    post `__posth' (713920) (7999) (7999) (7999) (1) ("dorn")
    post `__posth' (713930) (4493) (4493) (4493) (1) ("dorn")
    post `__posth' (713940) (7991) (7991) (7991) (.5740267038345337) ("dorn")
    post `__posth' (713950) (7933) (7933) (7933) (1) ("dorn")
    post `__posth' (713990) (7999) (7999) (7911) (.544022262096405) ("dorn")
    post `__posth' (721110) (7011) (7011) (7011) (.998242199420929) ("dorn")
    post `__posth' (721120) (7011) (7011) (7011) (1) ("dorn")
    post `__posth' (721191) (7011) (7011) (7011) (1) ("dorn")
    post `__posth' (721199) (7011) (7011) (7011) (1) ("dorn")
    post `__posth' (721211) (7033) (7033) (7033) (1) ("dorn")
    post `__posth' (721214) (7032) (7032) (7032) (1) ("dorn")
    post `__posth' (721310) (7041) (7041) (7021) (.5483105778694153) ("dorn")
    post `__posth' (722110) (5812) (5812) (5812) (1) ("dorn")
    post `__posth' (722211) (5812) (5812) (5812) (1) ("dorn")
    post `__posth' (722212) (5812) (5812) (5812) (1) ("dorn")
    post `__posth' (722213) (5812) (5812) (5461) (.7669790387153625) ("dorn")
    post `__posth' (722310) (5812) (5812) (5812) (1) ("dorn")
    post `__posth' (722320) (5812) (5812) (5812) (1) ("dorn")
    post `__posth' (722330) (5963) (5963) (5963) (1) ("dorn")
    post `__posth' (722410) (5813) (5813) (5813) (1) ("dorn")
    post `__posth' (722511) (5812) (5812) (5812) (1) ("dorn")
    post `__posth' (722513) (5812) (5812) (5812) (1) ("dorn")
    post `__posth' (722514) (5812) (5812) (5812) (1) ("dorn")
    post `__posth' (722515) (5812) (5812) (5461) (.7669790387153625) ("dorn")
    post `__posth' (811111) (7538) (7538) (7538) (.9814345240592957) ("dorn")
    post `__posth' (811112) (7533) (7533) (7533) (.9814345240592957) ("dorn")
    post `__posth' (811113) (7537) (7537) (7537) (.9814345240592957) ("dorn")
    post `__posth' (811114) (7533) (7533) (7533) (.9814345240592957) ("dorn")
    post `__posth' (811118) (7539) (7539) (7539) (.9814345240592957) ("dorn")
    post `__posth' (811121) (7532) (7532) (7532) (.9814345240592957) ("dorn")
    post `__posth' (811122) (7536) (7536) (7536) (.9814345240592957) ("dorn")
    post `__posth' (811191) (7549) (7549) (7549) (.9814345240592957) ("dorn")
    post `__posth' (811192) (7542) (7542) (7542) (.9814345240592957) ("dorn")
    post `__posth' (811198) (7549) (7549) (7534) (.7828235030174255) ("dorn")
    post `__posth' (811210) (7622) (7622) (7622) (.9814345240592957) ("dorn")
    post `__posth' (811211) (7622) (7622) (7622) (.9814345240592957) ("dorn")
    post `__posth' (811212) (7378) (7378) (7378) (.8417272567749023) ("dorn")
    post `__posth' (811213) (7622) (7622) (7622) (.8446288704872131) ("dorn")
    post `__posth' (811219) (7629) (7629) (7629) (.8147472739219666) ("dorn")
    post `__posth' (811310) (7699) (7699) (7623) (.7747044563293457) ("dorn")
    post `__posth' (811411) (7699) (7699) (7629) (.802339494228363) ("dorn")
    post `__posth' (811412) (7629) (7629) (7623) (.7964076995849609) ("dorn")
    post `__posth' (811420) (7641) (7641) (7641) (.9814345240592957) ("dorn")
    post `__posth' (811430) (7251) (7251) (7251) (.9188050627708435) ("dorn")
    post `__posth' (811490) (7692) (7692) (3732) (.3354723453521729) ("dorn")
    post `__posth' (812111) (7241) (7241) (7241) (1) ("dorn")
    post `__posth' (812112) (7231) (7231) (7231) (1) ("dorn")
    post `__posth' (812113) (7231) (7231) (7231) (1) ("dorn")
    post `__posth' (812191) (7299) (7299) (7299) (1) ("dorn")
    post `__posth' (812199) (7299) (7299) (7299) (1) ("dorn")
    post `__posth' (812210) (7261) (7261) (7261) (1) ("dorn")
    post `__posth' (812220) (6553) (6553) (6531) (.9663123488426208) ("dorn")
    post `__posth' (812310) (7215) (7215) (7215) (1) ("dorn")
    post `__posth' (812320) (7216) (7216) (7211) (.8156366944313049) ("dorn")
    post `__posth' (812331) (7213) (7213) (7213) (.9844973683357239) ("dorn")
    post `__posth' (812332) (7218) (7218) (7218) (1) ("dorn")
    post `__posth' (812910) (752) (752) (752) (1) ("dorn")
    post `__posth' (812921) (7384) (7384) (7384) (1) ("dorn")
    post `__posth' (812922) (7384) (7384) (7384) (1) ("dorn")
    post `__posth' (812930) (7521) (7521) (7521) (1) ("dorn")
    post `__posth' (812990) (7299) (7299) (4899) (.7930836081504822) ("dorn")
    post `__posth' (813110) (8661) (8661) (8661) (1) ("dorn")
    post `__posth' (813211) (6732) (6732) (6732) (1) ("dorn")
    post `__posth' (813212) (8399) (8399) (8399) (1) ("dorn")
    post `__posth' (813219) (8399) (8399) (8399) (1) ("dorn")
    post `__posth' (813311) (8399) (8399) (8399) (1) ("dorn")
    post `__posth' (813312) (8399) (8399) (8399) (.5321696400642395) ("dorn")
    post `__posth' (813319) (8399) (8399) (8399) (1) ("dorn")
    post `__posth' (813410) (8641) (8641) (8641) (.9991602301597595) ("dorn")
    post `__posth' (813910) (8611) (8611) (8611) (.9420247673988342) ("dorn")
    post `__posth' (813920) (8621) (8621) (8621) (1) ("dorn")
    post `__posth' (813930) (8631) (8631) (8631) (1) ("dorn")
    post `__posth' (813940) (8651) (8651) (8651) (1) ("dorn")
    post `__posth' (813990) (6531) (6531) (6531) (.6484127640724182) ("dorn")
    post `__posth' (814110) (8811) (8811) (8811) (.) ("census")
    post `__posth' (921110) (9111) (9111) (9111) (.) ("census")
    post `__posth' (921120) (9121) (9121) (9121) (.) ("census")
    post `__posth' (921130) (9311) (9311) (9311) (.) ("census")
    post `__posth' (921140) (9131) (9131) (9131) (.) ("census")
    post `__posth' (921150) (8641) (8641) (8641) (.) ("census")
    post `__posth' (921190) (9199) (9199) (9199) (.) ("census")
    post `__posth' (922110) (9211) (9211) (9211) (.) ("census")
    post `__posth' (922120) (9221) (9221) (9221) (.) ("census")
    post `__posth' (922130) (9222) (9222) (9222) (.) ("census")
    post `__posth' (922140) (9223) (9223) (9223) (.) ("census")
    post `__posth' (922150) (8322) (8322) (8322) (.) ("census")
    post `__posth' (922160) (9224) (9224) (9224) (.) ("census")
    post `__posth' (922190) (9229) (9229) (9229) (.) ("census")
    post `__posth' (923110) (9411) (9411) (9411) (.) ("census")
    post `__posth' (923120) (9431) (9431) (9431) (.) ("census")
    post `__posth' (923130) (9441) (9441) (9441) (.) ("census")
    post `__posth' (923140) (9451) (9451) (9451) (.) ("census")
    post `__posth' (924110) (9511) (9511) (9511) (.) ("census")
    post `__posth' (924120) (9512) (9512) (9512) (.) ("census")
    post `__posth' (925110) (9531) (9531) (9531) (.) ("census")
    post `__posth' (925120) (9532) (9532) (9532) (.) ("census")
    post `__posth' (926110) (9611) (9611) (9611) (.) ("census")
    post `__posth' (926120) (9621) (9621) (9621) (.) ("census")
    post `__posth' (926130) (9631) (9631) (9631) (.) ("census")
    post `__posth' (926140) (9641) (9641) (9641) (.) ("census")
    post `__posth' (926150) (9651) (9651) (9651) (.) ("census")
    post `__posth' (927110) (9661) (9661) (9661) (.) ("census")
    post `__posth' (928110) (9711) (9711) (9711) (.) ("census")
    post `__posth' (928120) (9721) (9721) (9721) (.) ("census")
    post `__posth' (950000) (40001) (90001) (20001) (.335962325334549) ("dorn")
    * Manual mappings for new industries without NAICS 2002 ancestor
    post `__posth' (517919) (4899) (4899) (4899) (.) ("manual")
    post `__posth' (519130) (7375) (7375) (7375) (.) ("manual")
    postclose `__posth'
    use "`__map'", clear
end
