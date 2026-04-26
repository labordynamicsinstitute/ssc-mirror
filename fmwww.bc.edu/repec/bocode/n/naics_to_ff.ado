*! version 1.1  20apr2026  Kelvin Law
*! Converts NAICS codes to Fama-French industry classifications
*! Uses Dorn's crosswalk + Census concordance + concordance chain for NAICS->SIC
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
*!   - NAICS-to-SIC lookup data file (naics_sic_lookup.dta) on adopath
*!
*! Reference:
*!   Dorn's crosswalk: Autor, Dorn & Hanson (2013) AER
*!   Census concordance: 2002 NAICS to 1987 SIC
*!   FF industries: Ken French Data Library

program naics_to_ff, rclass sortpreserve
    version 14.0

    * syntax does not accept underscore option names, so normalize the
    * documented comp_* aliases into compact internal spellings first.
    local __raw0 `"`0'"'
    local __under_opts "comp_naicsvar comp_sicvar comp_pricevar comp_sharesvar comp_fyearvar comp_weightvar"
    local __compact_opts "compnaicsvar compsicvar comppricevar compsharesvar compfyearvar compweightvar"
    forvalues __i = 1/6 {
        local __u : word `__i' of `__under_opts'
        local __c : word `__i' of `__compact_opts'
        local __uval ""
        local __cval ""
        if regexm(`"`__raw0'"', "`__u'[(]([^)]*)[)]") local __uval = strtrim(regexs(1))
        if regexm(`"`__raw0'"', "`__c'[(]([^)]*)[)]") local __cval = strtrim(regexs(1))
        if "`__uval'" != "" & "`__cval'" != "" & "`__uval'" != "`__cval'" {
            display as error "Specify either `__u'() or `__c'(), not both with different values"
            exit 198
        }
        if "`__cval'" == "" & "`__uval'" != "" {
            * Rewrite the option token only; this is robust to macro-expanded values.
            local 0 : subinstr local 0 "`__u'(" "`__c'(", all
        }
        else if "`__uval'" != "" {
            local 0 : subinstr local 0 "`__u'(`__uval')" "", all
        }
    }

    syntax varname [if] [in], GENerate(name) ///
        [SCHeme(string) LABels REPlace NOMISSING DIAGnostics ///
         SICgen(name) SOURCEgen(name) WEIGHTgen(name) COMPare(varname) ///
         METHod(string) FALLback(varname) ///
         COMPUstat(string) YEARvar(varname) CYear(integer 0) NOFALLback ///
         COMPNAICSvar(name) COMPSICvar(name) COMPPRICEvar(name) COMPSHARESvar(name) ///
         COMPFYEARvar(name) COMPWEIGHTvar(name)]

    if "`compnaicsvar'" == "" & "`comp_naicsvar'" != "" local compnaicsvar "`comp_naicsvar'"
    if "`compsicvar'" == "" & "`comp_sicvar'" != "" local compsicvar "`comp_sicvar'"
    if "`comppricevar'" == "" & "`comp_pricevar'" != "" local comppricevar "`comp_pricevar'"
    if "`compsharesvar'" == "" & "`comp_sharesvar'" != "" local compsharesvar "`comp_sharesvar'"
    if "`compfyearvar'" == "" & "`comp_fyearvar'" != "" local compfyearvar "`comp_fyearvar'"
    if "`compweightvar'" == "" & "`comp_weightvar'" != "" local compweightvar "`comp_weightvar'"

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
    local __scan_done = 0
    tempname __fh
    capture file open `__fh' using "`__sic_path'", read text
    if _rc == 0 {
        forvalues __i = 1/20 {
            if `__scan_done' == 0 {
                file read `__fh' __line
                if r(eof) {
                    local __scan_done = 1
                }
                else {
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
                            local __scan_done = 1
                        }
                    }
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

    * comp_* aliases are normalized into the compact locals above.

    * Validation for compustat() option
    local use_compustat = 0
    if "`compustat'" != "" {
        local use_compustat = 1

        * Defaults for flexible Compustat variable names
        if "`compnaicsvar'" == "" local compnaicsvar "naics"
        if "`compsicvar'" == "" local compsicvar "sich"
        if "`comppricevar'" == "" local comppricevar "prcc_f"
        if "`compsharesvar'" == "" local compsharesvar "csho"
        if "`compfyearvar'" == "" local compfyearvar "fyear"

        * Full pairwise distinctness guard for all active comp_*var() options.
        * Build list of active override variables, then check all pairs.
        local __comp_vars "compnaicsvar compsicvar compfyearvar"
        if "`compweightvar'" == "" {
            local __comp_vars "`__comp_vars' comppricevar compsharesvar"
        }
        else {
            local __comp_vars "`__comp_vars' compweightvar"
        }
        local __n_cvars : word count `__comp_vars'
        forvalues __i = 1/`__n_cvars' {
            local __vi : word `__i' of `__comp_vars'
            local __j = `__i' + 1
            forvalues __k = `__j'/`__n_cvars' {
                local __vk : word `__k' of `__comp_vars'
                if "``__vi''" == "``__vk''" {
                    local __vi_pub = subinstr("`__vi'", "comp", "comp_", 1)
                    local __vk_pub = subinstr("`__vk'", "comp", "comp_", 1)
                    display as error "`__vi_pub'() and `__vk_pub'() both reference '``__vi'''"
                    display as error "All comp_*var() options must reference distinct variables"
                    exit 198
                }
            }
        }

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
        if "`yearvar'" == "" & `cyear' <= 0 {
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

        * Guard against conflicting weighting specification
        if "`compweightvar'" != "" {
            if "`compweightvar'" == "`comppricevar'" | "`compweightvar'" == "`compsharesvar'" {
                * Allowed, but clarify precedence for users
                display as text "  Note: comp_weightvar() overrides comp_pricevar()/comp_sharesvar() when compustat() is used"
            }
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
        if "`compnaicsvar'" != "" | "`compsicvar'" != "" | "`comppricevar'" != "" | ///
           "`compsharesvar'" != "" | "`compfyearvar'" != "" | "`compweightvar'" != "" | ///
           "`comp_naicsvar'" != "" | "`comp_sicvar'" != "" | "`comp_pricevar'" != "" | ///
           "`comp_sharesvar'" != "" | "`comp_fyearvar'" != "" | "`comp_weightvar'" != "" {
            display as error "comp_*var() options require compustat() to be specified"
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

    * Validate shipped lookup exists before any destructive operations
    capture findfile naics_sic_lookup.dta
    if _rc != 0 {
        display as error "Could not locate NAICS lookup data file on adopath"
        display as error "Expected: naics_sic_lookup.dta"
        exit 601
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

        if `n_fractional' > 0 {
            display as error "Fractional numeric NAICS values are not allowed"
            display as error "Provide formatted NAICS as strings (for example, ""541.710"") or pre-clean them to six-digit integers"
            exit 198
        }

        * Now convert to long using explicit floor() (not relying on implicit truncation)
        quietly generate long `naics_num' = floor(`naics_raw') if `touse'
        drop `naics_clean' `naics_raw'
    }
    else {
        * Numeric NAICS must already be six-digit integers. Fractional values are
        * ambiguous after numeric coercion and therefore rejected.
        tempvar naics_work
        quietly generate double `naics_work' = `naicsvar' if `touse'
        quietly count if `touse' & `naics_work' < . & floor(`naics_work') != `naics_work'
        local n_fractional = r(N)
        local n_thousand_sep_pattern = 0

        if `n_fractional' > 0 {
            display as error "Fractional numeric NAICS values are not allowed"
            display as error "Provide formatted NAICS as strings (for example, ""541.710"") or pre-clean them to six-digit integers"
            exit 198
        }

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

    * Create SIC variable from the shipped cached lookup
    tempvar sic_mapped mapping_weight mapping_source
    quietly generate long `sic_mapped' = .
    quietly generate double `mapping_weight' = .
    quietly generate str10 `mapping_source' = ""

    * Track Compustat-specific mapping counts
    local n_compustat_mapped = 0
    local n_dorn_fallback = 0

    * Apply NAICS to SIC mapping via the cached shipped lookup
    if `use_compustat' == 1 {
        * Build Compustat market-cap weighted mapping
        tempfile compustat_map
        _build_compustat_mapping "`compustat'" `cyear' "`compustat_map'" "`yearvar'" ///
            "`compnaicsvar'" "`compsicvar'" "`comppricevar'" "`compsharesvar'" ///
            "`compfyearvar'" "`compweightvar'"

        * Merge with Compustat mapping
        _naics_to_sic_merge_compustat `naics_num' `sic_mapped' `mapping_weight' `mapping_source' `touse' "`compustat_map'" "`yearvar'" `cyear'

        * Count Compustat-mapped observations
        quietly count if `touse' & `mapping_source' == "compustat" & `sic_mapped' < .
        local n_compustat_mapped = r(N)

        * Fallback to shipped lookup for unmapped (unless nofallback specified)
        if "`nofallback'" == "" {
            * Use the shipped lookup for observations still missing SIC
            _naics_to_sic_merge `naics_num' `sic_mapped' `mapping_weight' `mapping_source' `touse' "maxweight"
        }
    }
    else {
        * Default: Uses the shipped Dorn/Census/manual lookup via cached Mata index
        _naics_to_sic_merge `naics_num' `sic_mapped' `mapping_weight' `mapping_source' `touse' `method'
    }

    * Guard against auxiliary SIC codes (>9999) that would crash sic_to_ff
    * These occur in the Dorn's crosswalk for certain NAICS (e.g., 493xxx warehousing,
    * 551114 holding companies, 950000 government). Treat as unmapped.
    * Also clear mapping_source/weight so fallback can correctly fill them
    quietly replace `mapping_source' = "" if `touse' & `sic_mapped' > 9999
    quietly replace `mapping_weight' = . if `touse' & `sic_mapped' > 9999
    quietly replace `sic_mapped' = . if `touse' & `sic_mapped' > 9999

    if `use_compustat' == 1 & "`nofallback'" == "" {
        quietly count if `touse' & inlist(`mapping_source', "dorn", "census", "manual") & `sic_mapped' < .
        local n_dorn_fallback = r(N)
    }

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
            quietly count if `touse' & `fallback' < . & floor(`fallback') != `fallback'
            if r(N) > 0 {
                display as error "fallback() does not accept fractional numeric SIC values"
                display as error "Keep formatted SIC values as strings or pre-clean them to valid 4-digit integers"
                exit 198
            }
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
            * String fallback - strip common formatting punctuation before numeric conversion
            tempvar __fb_clean __fb_num
            quietly gen str20 `__fb_clean' = trim(`fallback') if `touse'
            quietly replace `__fb_clean' = subinstr(`__fb_clean', " ", "", .) if `touse'
            quietly replace `__fb_clean' = subinstr(`__fb_clean', ",", "", .) if `touse'
            quietly replace `__fb_clean' = subinstr(`__fb_clean', "-", "", .) if `touse'
            quietly replace `__fb_clean' = subinstr(`__fb_clean', ".", "", .) if `touse'
            quietly replace `__fb_clean' = subinstr(`__fb_clean', char(9), "", .) if `touse'
            quietly gen double `__fb_num' = real(`__fb_clean') if `touse'
            quietly gen byte `fb_used' = (`touse' & `sic_mapped' >= . & `__fb_clean' != "" & `__fb_num' < . & inrange(`__fb_num', 1, 9999))
            quietly count if `fb_used'
            local n_fallback = r(N)
            if `n_fallback' > 0 {
                quietly replace `sic_mapped' = `__fb_num' if `fb_used'
                * Overwrite source/weight unconditionally for fallback rows
                quietly replace `mapping_source' = "fallback" if `fb_used'
                quietly replace `mapping_weight' = . if `fb_used'
            }
            drop `__fb_clean' `__fb_num'
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
            quietly count if `touse' & `compare' < . & floor(`compare') != `compare'
            if r(N) > 0 {
                display as error "compare() does not accept fractional numeric SIC values"
                display as error "Keep formatted SIC values as strings or pre-clean them to valid 4-digit integers"
                exit 198
            }
            quietly gen long `compare_sic_clean' = `compare' if `touse'
            quietly replace `compare_sic_clean' = . if `compare_sic_clean' > 9999 | `compare_sic_clean' < 0
        }
        else {
            tempvar __compare_clean __compare_num
            quietly gen str20 `__compare_clean' = trim(`compare') if `touse'
            quietly replace `__compare_clean' = subinstr(`__compare_clean', " ", "", .) if `touse'
            quietly replace `__compare_clean' = subinstr(`__compare_clean', ",", "", .) if `touse'
            quietly replace `__compare_clean' = subinstr(`__compare_clean', "-", "", .) if `touse'
            quietly replace `__compare_clean' = subinstr(`__compare_clean', ".", "", .) if `touse'
            quietly replace `__compare_clean' = subinstr(`__compare_clean', char(9), "", .) if `touse'
            quietly gen double `__compare_num' = real(`__compare_clean') if `touse'
            quietly gen long `compare_sic_clean' = `__compare_num' if `touse'
            quietly replace `compare_sic_clean' = . if `compare_sic_clean' > 9999 | `compare_sic_clean' < 0
            drop `__compare_clean' `__compare_num'
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

    * Notes about input normalization (always displayed, not just with diagnostics)
    if `n_thousand_sep_pattern' > 0 {
        display as text "  Note: " as result `n_thousand_sep_pattern' as text " observations had dot-as-thousand-separator NAICS (normalized)"
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
            if "`compweightvar'" == "" {
                display as text "Mapped via Compustat (mkt-cap):   " as result %10.0fc `n_compustat_diag'
            }
            else {
                display as text "Mapped via Compustat (custom wt): " as result %10.0fc `n_compustat_diag'
                display as text "  Weight variable: `compweightvar'"
            }
            if "`yearvar'" != "" {
                display as text "  (Time-varying weights via `yearvar')"
            }
            else {
                display as text "  (Fixed year weights: `cyear')"
            }
            if "`nofallback'" == "" {
                display as text "Shipped-lookup fallback:          " as result %10.0fc `n_dorn_fallback'
            }
        }
        else {
            display as text "Mapped via Dorn's crosswalk:        " as result %10.0fc `n_dorn'
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
                    rename `naics_num' naics_code
                    rename `__n2f_count' unmapped_count
                    gsort -unmapped_count
                    local n_to_show = min(_N, 10)
                    display as text "    naics_code   unmapped_count"
                    forvalues __i = 1/`n_to_show' {
                        display as text %12.0f =naics_code[`__i'] ///
                            "   " %16.0f =unmapped_count[`__i']
                    }
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
        return local comp_naicsvar "`compnaicsvar'"
        return local comp_sicvar "`compsicvar'"
        return local comp_fyearvar "`compfyearvar'"
        return local compnaicsvar "`compnaicsvar'"
        return local compsicvar "`compsicvar'"
        return local compfyearvar "`compfyearvar'"
        if "`compweightvar'" != "" {
            return local comp_weightvar "`compweightvar'"
            return local compweightvar "`compweightvar'"
        }
        else {
            return local comp_pricevar "`comppricevar'"
            return local comp_sharesvar "`compsharesvar'"
            return local comppricevar "`comppricevar'"
            return local compsharesvar "`compsharesvar'"
        }
        if "`yearvar'" != "" {
            return local yearvar "`yearvar'"
        }
        else {
            return scalar cyear = `cyear'
        }
        return scalar nofallback = ("`nofallback'" != "")
    }
end

*----------------------------------------------------------------------
* Build and reuse a session-cached Mata lookup for shipped NAICS mapping
*----------------------------------------------------------------------
program _naics_map_cache_init
    version 14.0

    _naics_lookup_path
    local lookup_path "`r(path)'"

    local __cache_ready 0
    local __cache_path "$N2F_CACHE_LOOKUP_PATH"
    capture confirm scalar __n2f_cache_ready
    if _rc == 0 {
        if scalar(__n2f_cache_ready) == 1 {
            if "`__cache_path'" == "`lookup_path'" {
                local __cache_ready 1
            }
        }
    }
    if `__cache_ready' {
        exit
    }

    preserve
    quietly use "`lookup_path'", clear
    foreach v in naics sic sic_skipaux sic_first weight source {
        capture confirm variable `v'
        if _rc != 0 {
            restore
            display as error "Lookup data file is missing required column: `v'"
            exit 610
        }
    }
    capture isid naics
    if _rc != 0 {
        restore
        display as error "Lookup data file has duplicate NAICS codes"
        exit 459
    }
    mata: __n2f_drop_cache()
    mata: __n2f_cache_from_data()
    restore

    capture scalar drop __n2f_cache_ready
    scalar __n2f_cache_ready = 1
    global N2F_CACHE_LOOKUP_PATH "`lookup_path'"

    exit
end

*----------------------------------------------------------------------
* Clear session-cached NAICS lookup (internal/test helper)
*----------------------------------------------------------------------
program _naics_sic_clearcache
    version 14.0
    capture scalar drop __n2f_cache_ready
    capture macro drop N2F_CACHE_LOOKUP_PATH
    mata: __n2f_drop_cache()
end

*----------------------------------------------------------------------
* NAICS to SIC mapping via cached Mata lookup
* Note: Despite its name, this helper dispatches to a cached Mata
* associative-array lookup, not a Stata merge. The name is retained
* for backward compatibility with test scripts.
*----------------------------------------------------------------------
program _naics_to_sic_merge
    args naicsvar sicvar weightvar sourcevar touse method

    _naics_map_cache_init
    mata: __n2f_apply_lookup("`naicsvar'", "`sicvar'", "`weightvar'", "`sourcevar'", "`touse'", "`method'")
end

*----------------------------------------------------------------------
* Resolve shipped NAICS lookup path
*----------------------------------------------------------------------
program _naics_lookup_path, rclass
    capture findfile naics_sic_lookup.dta
    if _rc == 0 {
        return local path "`r(fn)'"
        exit
    }
    display as error "Could not locate NAICS lookup data file on adopath"
    display as error "Expected: naics_sic_lookup.dta"
    exit 601
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
    args compustat_path year_filter mapfile yearvar_mode ///
        comp_naicsvar comp_sicvar comp_pricevar comp_sharesvar comp_fyearvar comp_weightvar

    preserve
    capture noisily {
        * Open the Compustat file once, validate required variables, then trim
        * to only the needed columns.
        local __required_vars "`comp_naicsvar' `comp_sicvar' `comp_fyearvar'"
        if "`comp_weightvar'" == "" {
            local __required_vars "`__required_vars' `comp_pricevar' `comp_sharesvar'"
        }
        else {
            local __required_vars "`__required_vars' `comp_weightvar'"
        }
        use using "`compustat_path'", clear

        * Validate required variables exist
        foreach v in `__required_vars' {
            capture confirm variable `v'
            if _rc != 0 {
                display as error "compustat(): Required variable `v' not found in file"
                exit 111
            }
        }
        keep `__required_vars'

        * Validate variable types (fail fast with clear messages)
        capture confirm numeric variable `comp_sicvar'
        if _rc != 0 {
            display as error "compustat(): Variable `comp_sicvar' must be numeric, found string"
            display as error "Please destring `comp_sicvar' before using compustat()"
            exit 109
        }
        capture confirm numeric variable `comp_fyearvar'
        if _rc != 0 {
            display as error "compustat(): Variable `comp_fyearvar' must be numeric, found string"
            display as error "Please destring `comp_fyearvar' before using compustat()"
            exit 109
        }
        if "`comp_weightvar'" == "" {
            capture confirm numeric variable `comp_pricevar'
            if _rc != 0 {
                display as error "compustat(): Variable `comp_pricevar' must be numeric, found string"
                exit 109
            }
            capture confirm numeric variable `comp_sharesvar'
            if _rc != 0 {
                display as error "compustat(): Variable `comp_sharesvar' must be numeric, found string"
                exit 109
            }
        }
        else {
            capture confirm numeric variable `comp_weightvar'
            if _rc != 0 {
                display as error "compustat(): Variable `comp_weightvar' must be numeric, found string"
                exit 109
            }
        }

        * Filter to valid observations
        * - Valid SIC (1-9999)
        * - Positive weighting input
        * - Non-missing year variable
        quietly keep if !missing(`comp_sicvar') & `comp_sicvar' >= 1 & `comp_sicvar' <= 9999 & !missing(`comp_fyearvar')
        if "`comp_weightvar'" == "" {
            quietly keep if `comp_pricevar' > 0 & `comp_sharesvar' > 0
        }
        else {
            quietly keep if `comp_weightvar' > 0
        }

        * Canonical names used internally from this point onward
        quietly rename `comp_sicvar' __n2f_sich
        quietly rename `comp_fyearvar' __n2f_fyear
        if "`comp_weightvar'" == "" {
            quietly rename `comp_pricevar' __n2f_price
            quietly rename `comp_sharesvar' __n2f_shares
        }
        else {
            quietly rename `comp_weightvar' __n2f_weightvar
        }

        * Handle string vs numeric NAICS
        * Mirror main NAICS cleaning: strip spaces, commas, hyphens before conversion
        capture confirm string variable `comp_naicsvar'
        if _rc == 0 {
            * String NAICS - clean and convert to numeric
            quietly replace `comp_naicsvar' = trim(`comp_naicsvar')
            quietly keep if `comp_naicsvar' != ""

            * Detect range patterns (e.g., "31-33") BEFORE removing hyphens
            * Range = digits-hyphen-digits AND result without hyphen is NOT 6 digits
            quietly gen str40 __n2f_rangecheck = `comp_naicsvar'
            quietly replace __n2f_rangecheck = subinstr(__n2f_rangecheck, " ", "", .)
            quietly replace __n2f_rangecheck = subinstr(__n2f_rangecheck, char(9), "", .)
            quietly replace __n2f_rangecheck = subinstr(__n2f_rangecheck, ",", "", .)
            quietly gen byte __is_range = regexm(__n2f_rangecheck, "^[0-9]+-[0-9]+$") ///
                & strlen(subinstr(__n2f_rangecheck, "-", "", .)) != 6
            quietly count if __is_range == 1
            if r(N) > 0 {
                display as text "  Warning: " as result r(N) as text " Compustat obs have NAICS range patterns (excluded)"
            }
            quietly replace `comp_naicsvar' = "" if __is_range == 1
            drop __n2f_rangecheck __is_range
            quietly keep if `comp_naicsvar' != ""

            * Strip formatting characters (same as main naics_to_ff cleaning)
            quietly replace `comp_naicsvar' = subinstr(`comp_naicsvar', " ", "", .)
            quietly replace `comp_naicsvar' = subinstr(`comp_naicsvar', ",", "", .)
            quietly replace `comp_naicsvar' = subinstr(`comp_naicsvar', "-", "", .)
            quietly replace `comp_naicsvar' = subinstr(`comp_naicsvar', char(9), "", .)  // tab

            * Convert to numeric - first to double to detect fractional values
            quietly gen double __naics_raw = real(`comp_naicsvar')
            quietly keep if __naics_raw < .

            * Detect dot-as-thousand-separator pattern (e.g., "541.711" = 541711)
            * Strict check: original string must have EXACTLY 3 digits after decimal
            * Pattern: digits, dot, exactly 3 digits (e.g., "541.711" but NOT "541.71")
            * Note: Stata regexm() doesn't support {n} quantifiers, use repeated [0-9] instead
            quietly gen byte __is_thousand_sep = regexm(`comp_naicsvar', "^[0-9]+[.][0-9][0-9][0-9]$") ///
                & floor(__naics_raw * 1000) >= 100000 ///
                & floor(__naics_raw * 1000) <= 999999
            quietly count if __is_thousand_sep == 1
            if r(N) > 0 {
                display as text "  Note: " as result r(N) as text " Compustat obs have dot-as-thousand-separator NAICS (normalized)"
                quietly replace __naics_raw = __naics_raw * 1000 if __is_thousand_sep == 1
            }
            drop __is_thousand_sep

            * Reject remaining fractional NAICS (true decimals, not thousand-separator)
            quietly count if __naics_raw < . & floor(__naics_raw) != __naics_raw
            if r(N) > 0 {
                display as error "Compustat NAICS values must be six-digit integers when stored numerically"
                display as error "Provide formatted NAICS as strings (for example, ""541.710"") or pre-clean them to six-digit integers"
                exit 198
            }

            * Convert to long integer
            quietly gen long naics_num = floor(__naics_raw)
            drop __naics_raw
        }
        else {
            * Numeric Compustat NAICS must already be six-digit integers.
            quietly count if `comp_naicsvar' < . & floor(`comp_naicsvar') != `comp_naicsvar'
            if r(N) > 0 {
                display as error "Compustat NAICS values must be six-digit integers when stored numerically"
                display as error "Provide formatted NAICS as strings (for example, ""541.710"") or pre-clean them to six-digit integers"
                exit 198
            }
            quietly keep if `comp_naicsvar' < .
            quietly gen long naics_num = floor(`comp_naicsvar')
        }
        drop `comp_naicsvar'
        rename naics_num naics
        rename __n2f_sich sich
        rename __n2f_fyear fyear

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
            if "`comp_weightvar'" == "" {
                display as error "(require: valid naics, `comp_sicvar' 1-9999, `comp_pricevar' > 0, `comp_sharesvar' > 0, non-missing `comp_fyearvar')"
            }
            else {
                display as error "(require: valid naics, `comp_sicvar' 1-9999, `comp_weightvar' > 0, non-missing `comp_fyearvar')"
            }
            exit 2000
        }

        * Build weighting variable
        if "`comp_weightvar'" == "" {
            quietly gen double mktcap = __n2f_price * __n2f_shares
        }
        else {
            quietly gen double mktcap = __n2f_weightvar
        }

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

mata:
/*
    Session-cached NAICS lookup index.
    The shipped naics_sic_lookup.dta file is loaded once in Stata, then cached
    in Mata as three asarrays keyed by numeric NAICS code. Runtime lookups use
    the cached index and do not rebuild or merge the lookup dataset.
*/

real scalar __n2f_source_code(string scalar src)
{
    if (src == "dorn")   return(1);
    if (src == "census") return(2);
    if (src == "manual") return(3);
    return(.);
}

string scalar __n2f_source_label(real scalar code)
{
    if (code == 1) return("dorn");
    if (code == 2) return("census");
    if (code == 3) return("manual");
    return("");
}

void __n2f_drop_cache()
{
    external transmorphic matrix __n2f_idx_maxweight;
    external transmorphic matrix __n2f_idx_skipaux;
    external transmorphic matrix __n2f_idx_first;

    __n2f_idx_maxweight = J(0, 0, .);
    __n2f_idx_skipaux   = J(0, 0, .);
    __n2f_idx_first     = J(0, 0, .);
}

void __n2f_cache_from_data()
{
    external transmorphic matrix __n2f_idx_maxweight;
    external transmorphic matrix __n2f_idx_skipaux;
    external transmorphic matrix __n2f_idx_first;

    real colvector naics, sic, sic_skipaux, sic_first, weight;
    string colvector source;
    real scalar i, src_code;
    real rowvector row_max, row_skip, row_first;

    naics       = st_data(., "naics");
    sic         = st_data(., "sic");
    sic_skipaux = st_data(., "sic_skipaux");
    sic_first   = st_data(., "sic_first");
    weight      = st_data(., "weight");
    source      = st_sdata(., "source");

    __n2f_idx_maxweight = asarray_create("real", 1);
    __n2f_idx_skipaux   = asarray_create("real", 1);
    __n2f_idx_first     = asarray_create("real", 1);

    asarray_notfound(__n2f_idx_maxweight, J(1, 3, .));
    asarray_notfound(__n2f_idx_skipaux,   J(1, 3, .));
    asarray_notfound(__n2f_idx_first,     J(1, 3, .));

    for (i = 1; i <= rows(naics); i++) {
        src_code  = __n2f_source_code(source[i]);
        row_max   = (sic[i],         weight[i], src_code);
        row_skip  = (sic_skipaux[i], weight[i], src_code);
        row_first = (sic_first[i],   weight[i], src_code);

        asarray(__n2f_idx_maxweight, naics[i], row_max);
        asarray(__n2f_idx_skipaux,   naics[i], row_skip);
        asarray(__n2f_idx_first,     naics[i], row_first);
    }
}

void __n2f_apply_index(
    transmorphic matrix idx,
    real colvector naics,
    real colvector sic,
    real colvector weight,
    string colvector source,
    real scalar use_weight
)
{
    real scalar i;
    real rowvector hit;

    for (i = 1; i <= rows(naics); i++) {
        if (missing(naics[i]) | !missing(sic[i])) continue;

        hit = asarray(idx, naics[i]);
        if (missing(hit[1])) continue;

        sic[i] = hit[1];
        if (use_weight == 1 & !missing(hit[2])) weight[i] = hit[2];
        source[i] = __n2f_source_label(hit[3]);
    }
}

void __n2f_apply_lookup(
    string scalar naicsvar,
    string scalar sicvar,
    string scalar weightvar,
    string scalar sourcevar,
    string scalar tousevar,
    string scalar method
)
{
    external transmorphic matrix __n2f_idx_maxweight;
    external transmorphic matrix __n2f_idx_skipaux;
    external transmorphic matrix __n2f_idx_first;

    real colvector naics, sic, weight;
    string colvector source;

    naics  = st_data(., naicsvar, tousevar);
    sic    = st_data(., sicvar, tousevar);
    weight = st_data(., weightvar, tousevar);
    source = st_sdata(., sourcevar, tousevar);

    if (method == "skipaux") {
        __n2f_apply_index(__n2f_idx_skipaux, naics, sic, weight, source, 0);
    }
    else if (method == "first") {
        __n2f_apply_index(__n2f_idx_first, naics, sic, weight, source, 0);
    }
    else {
        __n2f_apply_index(__n2f_idx_maxweight, naics, sic, weight, source, 1);
    }

    st_store(., sicvar, tousevar, sic);
    st_store(., weightvar, tousevar, weight);
    st_sstore(., sourcevar, tousevar, source);
}
end
