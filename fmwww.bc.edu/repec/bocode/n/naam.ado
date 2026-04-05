*! naam version 1.0.1
*! Author: Vijayshree Jayaraman (jvijayshree26@gmail.com)
*! GitHub: https://github.com/vijayshree-jayaraman
*! "What's in a naam?" -- consistent encoding, ID hashing, label management
*!
*! Inspired by codebookout (Das, 2014):
*!   Das, Kishor K. (2014). "CODEBOOKOUT: Stata module to save codebook in
*!   MS excel format." Statistical Software Components S457811,
*!   Boston College Department of Economics.
*!   RePEC: boc:bocode:s457811
*!   https://ideas.repec.org/c/boc/bocode/s457811.html
*!
*! Subcommands:
*!   naam encode  : encode string vars and save exact mappings to Excel
*!   naam apply   : reapply saved mappings to any file instantly
*!   naam id      : convert alphanumeric IDs to consistent numerics
*!   naam export  : save labels from already-encoded datasets
*!   naam list    : inspect a mapping file from inside Stata
*!   naam decode  : reverse encoding -- numeric back to string
*!   naam check   : compare in-memory labels against saved mapping
*!   naam compare : compare two mapping files against each other

program define naam
    version 14.0
    local subcmd = word("`0'", 1)
    local rest   = substr(`"`0'"', length("`subcmd'") + 2, .)
    if "`subcmd'" == "encode" {
        naam_encode `rest'
    }
    else if "`subcmd'" == "id" {
        naam_id `rest'
    }
    else if "`subcmd'" == "export" {
        naam_export `rest'
    }
    else if "`subcmd'" == "apply" {
        naam_apply `rest'
    }
    else if "`subcmd'" == "list" {
        naam_list `rest'
    }
    else if "`subcmd'" == "decode" {
        naam_decode `rest'
    }
    else if "`subcmd'" == "check" {
        naam_check `rest'
    }
    else if "`subcmd'" == "compare" {
        naam_compare `rest'
    }
    else {
        di as err "Subcommand must be: encode, apply, id, export, list, decode, check, or compare"
        exit 198
    }
end


* -----------------------------------------------------------------------------
program define naam_encode
* Encode string variables to numeric and save exact mappings to Excel.
* -----------------------------------------------------------------------------
    version 14.0
    syntax varlist using/ [, replace keep]
    local fname `"`using'"'
    if substr(`"`fname'"',-5,5)!=".xlsx" & substr(`"`fname'"',-4,4)!=".xls" {
        local fname `"`fname'.xlsx"'
    }
    local nvars : word count `varlist'
    local i 1
    foreach v of local varlist {
        local vtype : type `v'
        if substr("`vtype'",1,3) != "str" {
            di as txt "  (skipping `v': not a string)"
            local m_name_`i' "`v'"
            local m_nvals_`i' 0
            local ++i
            continue
        }
        local m_name_`i' "`v'"
        local m_vl_`i' : variable label `v'
        * Check unique value count before levelsof.
        * Stata's encode is limited to 65,536 categories, and levelsof
        * will exhaust macro memory on high-cardinality variables like IDs.
        quietly {
            tempvar _nuniq_flag
            bysort `v': gen byte `_nuniq_flag' = (_n == 1)
            count if `_nuniq_flag' == 1
            local nuniq = r(N)
            drop `_nuniq_flag'
        }
        if `nuniq' > 65536 {
            di as err "  `v': `nuniq' unique values -- too many for naam encode (limit: 65,536)."
            di as err "  If `v' is an ID variable use: naam id `v' using filename, replace"
            local m_name_`i' "`v'"
            local m_nvals_`i' 0
            local ++i
            continue
        }
        quietly levelsof `v', local(vals)
        local m_nvals_`i' 0
        local code 1
        foreach val of local vals {
            local ++m_nvals_`i'
            local m_code_`i'_`m_nvals_`i'' `code'
            local m_val_`i'_`m_nvals_`i'' `"`val'"'
            local ++code
        }
        local ++i
    }
    local i 1
    foreach v of local varlist {
        local vtype : type `v'
        if substr("`vtype'",1,3) != "str" {
            local ++i
            continue
        }
        if "`keep'" != "" {
            quietly clonevar _str_`v' = `v'
            label var _str_`v' "Original string: `v'"
        }
        quietly encode `v', gen(_enc_`v') label(`v')
        quietly drop `v'
        quietly rename _enc_`v' `v'
        local ++i
    }
    preserve
    quietly {
        clear
        local nvalid 0
        forval i = 1/`nvars' {
            if `m_nvals_`i'' > 0 {
                local ++nvalid
            }
        }
        if `nvalid' == 0 {
            di as err "No string variables found"
            exit 109
        }
        set obs `nvalid'
        gen str32  varname  = ""
        gen str244 varlabel = ""
        gen str10  type     = "encode"
        local j 1
        forval i = 1/`nvars' {
            if `m_nvals_`i'' == 0 {
                continue
            }
            replace varname  = "`m_name_`i''"  in `j'
            replace varlabel = `"`m_vl_`i''"'  in `j'
            local ++j
        }
        export excel varname varlabel type using `"`fname'"', ///
            sheet("index") sheetreplace firstrow(variables)
    }
    restore
    di as txt "  -> [index] written."
    forval i = 1/`nvars' {
        if `m_nvals_`i'' == 0 {
            continue
        }
        preserve
        quietly {
            clear
            set obs `m_nvals_`i''
            gen str20  numeric_code = ""
            gen str244 string_value = ""
            forval e = 1/`m_nvals_`i'' {
                replace numeric_code = "`m_code_`i'_`e''"  in `e'
                replace string_value = `"`m_val_`i'_`e''"' in `e'
            }
            local shname = substr("`m_name_`i''",1,31)
            export excel numeric_code string_value using `"`fname'"', ///
                sheet("`shname'") sheetreplace firstrow(variables)
        }
        restore
        di as txt "  -> [`m_name_`i''] written (`m_nvals_`i'' categories)."
    }
    di as res `"naam encode complete -> `fname'"'
end


* -----------------------------------------------------------------------------
program define naam_id
* Convert a string ID variable to consistent numeric codes across files.
* On first call: assigns codes 1, 2, 3... alphabetically and saves mapping.
* On subsequent calls: looks up saved mapping, adds new codes for new IDs.
* Accepts a varlist: each variable is processed in turn, each saved to its
* own .dta file (base_varname.dta). No row-count limit.
* -----------------------------------------------------------------------------
    version 14.0
    syntax varlist using/ [, replace keep strict]

    * -- Strip any extension to get a clean base name -------------------------
    local base `"`using'"'
    if substr(`"`base'"', -4, 4) == ".dta" {
        local base = substr(`"`base'"', 1, length(`"`base'"') - 4)
    }
    else if substr(`"`base'"', -5, 5) == ".xlsx" {
        local base = substr(`"`base'"', 1, length(`"`base'"') - 5)
    }
    else if substr(`"`base'"', -4, 4) == ".xls" {
        local base = substr(`"`base'"', 1, length(`"`base'"') - 4)
    }

    * -- Process each variable in the varlist ---------------------------------
    local n_processed 0
    foreach v of local varlist {

        local vtype : type `v'
        if substr("`vtype'",1,3) != "str" {
            di as err "  `v' is not a string variable -- skipping"
            di as err "  naam id requires a string variable. For ID conversion use a string ID."
            continue
        }
        local ++n_processed

        * One .dta per variable: base_varname.dta
        local fname `"`base'_`v'.dta"'

        local vl : variable label `v'
        quietly count
        di as txt "  `r(N)' observations, processing `v'..."

        * Always keep a string backup for mapping and for ,keep option
        quietly clonevar _str_`v' = `v'

        * -- Check if a valid mapping .dta already exists for this variable ---
        local file_exists 0
        capture confirm file `"`fname'"'
        if !_rc {
            preserve
            capture {
                quietly use `"`fname'"', clear
                confirm variable string_value
                confirm variable numeric_code
                quietly count if !missing(numeric_code)
                if r(N) == 0 error 1
            }
            if !_rc local file_exists 1
            restore
        }

        * -- CASE 1: No valid mapping -- assign fresh codes -------------------
        if !`file_exists' {
            di as txt "  No valid mapping found -- assigning fresh codes."
            if "`strict'" != "" {
                di as txt "  (,strict ignored -- no existing mapping yet)"
            }
            quietly {
                tempvar grp
                egen `grp' = group(`v')
                gen double _naam_id_`v' = `grp'
                drop `grp'
            }
        }

        * -- CASE 2: Valid mapping exists -- look up, add new if needed -------
        else {
            di as txt "  Existing mapping found -- looking up codes..."

            tempfile existing_map
            preserve
            quietly {
                use `"`fname'"', clear
                duplicates drop string_value, force
                save `"`existing_map'"', replace
            }
            restore

            quietly {
                rename _str_`v' string_value
                merge m:1 string_value using `"`existing_map'"', ///
                    keepusing(numeric_code) nogen keep(1 3)
                rename string_value _str_`v'
            }

            quietly count if missing(numeric_code)
            local nnew = r(N)

            if `nnew' > 0 & "`strict'" != "" {
                di as err "strict: `nnew' new IDs not in saved mapping for `v'."
                di as err "Remove ,strict to allow new IDs to be added."
                quietly drop numeric_code _str_`v'
                exit 459
            }

            if `nnew' > 0 {
                di as txt "  `nnew' new IDs -- assigning new codes."
                quietly {
                    summarize numeric_code, meanonly
                    local maxcode = r(max)
                    tempvar newgrp
                    egen `newgrp' = group(`v') if missing(numeric_code)
                    replace numeric_code = `maxcode' + `newgrp' ///
                        if missing(numeric_code)
                    drop `newgrp'
                }
            }
            else {
                di as txt "  All IDs matched. No new codes needed."
            }

            quietly gen double _naam_id_`v' = numeric_code
            quietly drop numeric_code
        }

        * -- Build updated mapping ---------------------------------------------
        tempfile new_mapping
        preserve
        quietly {
            keep _str_`v' _naam_id_`v'
            rename _str_`v'     string_value
            rename _naam_id_`v' numeric_code
            duplicates drop string_value, force
            sort numeric_code
            local ntotal = _N
            save `"`new_mapping'"', replace
        }
        restore

        * -- Apply to dataset --------------------------------------------------
        quietly drop `v'
        quietly rename _naam_id_`v' `v'
        label var `v' "`vl'"

        if "`keep'" == "" {
            quietly drop _str_`v'
        }
        else {
            label var _str_`v' "Original string ID: `v'"
        }

        di as txt "  -> `v' assigned: `ntotal' unique IDs in mapping."

        * -- Save mapping as .dta (no row-count limit) ------------------------
        preserve
        quietly {
            use `"`new_mapping'"', clear
            save `"`fname'"', replace
        }
        restore
        di as res `"naam id complete for `v' -> `fname'"'
    }

    if `n_processed' == 0 {
        di as err "No string variables found. naam id requires string variables."
        exit 109
    }
end


* -----------------------------------------------------------------------------
program define naam_export
* Save variable labels and value labels from an already-encoded dataset
* to Excel so they can be reattached later with naam apply.
* -----------------------------------------------------------------------------
    version 14.0
    syntax using/ [, replace]
    local fname `"`using'"'
    if substr(`"`fname'"',-5,5)!=".xlsx" & substr(`"`fname'"',-4,4)!=".xls" {
        local fname `"`fname'.xlsx"'
    }
    quietly ds
    local allvars `r(varlist)'
    local nvars : word count `allvars'
    local i 1
    foreach v of local allvars {
        local m_name_`i' "`v'"
        local m_lbl_`i'  : variable label `v'
        local m_type_`i' : type `v'
        local m_lbn_`i'  : value label `v'
        local lbname `"`m_lbn_`i''"'
        local m_nvals_`i' 0
        if `"`lbname'"' != "" {
            quietly label list `lbname'
            local kmin = r(min)
            local kmax = r(max)
            local entry 0
            forval code = `kmin'/`kmax' {
                local txt : label `lbname' `code', strict
                if `"`txt'"' != "" {
                    local ++entry
                    local m_vcode_`i'_`entry' `code'
                    local m_vtxt_`i'_`entry'  `"`txt'"'
                }
            }
            local m_nvals_`i' `entry'
        }
        local ++i
    }
    preserve
    quietly {
        clear
        set obs `nvars'
        gen str32  varname  = ""
        gen str244 varlabel = ""
        gen str16  vartype  = ""
        gen str32  lblname  = ""
        gen str10  type     = "export"
        forval i = 1/`nvars' {
            replace varname  = `"`m_name_`i''"'  in `i'
            replace varlabel = `"`m_lbl_`i''"'   in `i'
            replace vartype  = `"`m_type_`i''"'  in `i'
            replace lblname  = `"`m_lbn_`i''"'   in `i'
        }
        export excel varname varlabel vartype lblname type using `"`fname'"', ///
            sheet("index") sheetreplace firstrow(variables)
    }
    restore
    di as txt "  -> [index] written."
    local nsheets 0
    forval i = 1/`nvars' {
        if `m_nvals_`i'' == 0 {
            continue
        }
        preserve
        quietly {
            clear
            set obs `m_nvals_`i''
            gen str20  numeric_code = ""
            gen str244 string_value = ""
            forval e = 1/`m_nvals_`i'' {
                replace numeric_code = "`m_vcode_`i'_`e''"   in `e'
                replace string_value = `"`m_vtxt_`i'_`e''"'  in `e'
            }
            local shname = substr(`"`m_name_`i''"',1,31)
            export excel numeric_code string_value using `"`fname'"', ///
                sheet("`shname'") sheetreplace firstrow(variables)
        }
        restore
        local ++nsheets
    }
    if `nsheets' == 0 {
        di as txt "  (no value-labeled variables found)"
    }
    di as res `"naam export complete -> `fname'"'
end


* -----------------------------------------------------------------------------
program define naam_apply
* Read a naam Excel file and reattach all saved mappings to the dataset
* currently in memory. Handles type=encode, type=export, and type=id.
* -----------------------------------------------------------------------------
    version 14.0
    syntax using/ [, VARSOnly LABELSOnly]
    local fname `"`using'"'
    if substr(`"`fname'"',-5,5)!=".xlsx" & substr(`"`fname'"',-4,4)!=".xls" {
        local fname `"`fname'.xlsx"'
    }
    confirm file `"`fname'"'

    * Read index into locals
    tempfile idxtmp
    preserve
    quietly {
        import excel using `"`fname'"', sheet("index") firstrow clear allstring
        capture confirm variable varname
        if _rc {
            restore
            di as err "Sheet [index] missing or malformed"
            exit 111
        }
        save `"`idxtmp'"', replace
    }
    restore

    preserve
    quietly use `"`idxtmp'"', clear
    local nrows = _N
    forval i = 1/`nrows' {
        local r_vname_`i'   = varname[`i']
        local r_vlabel_`i'  = varlabel[`i']
        local r_type_`i'    = type[`i']
        capture local r_lbname_`i' = lblname[`i']
        if _rc {
            local r_lbname_`i' ""
        }
    }
    restore

    * Reattach variable labels (all types)
    if "`labelsonly'" == "" {
        local n_vl 0
        forval i = 1/`nrows' {
            local v   "`r_vname_`i''"
            local lbl `"`r_vlabel_`i''"'
            capture confirm variable `v'
            if _rc {
                continue
            }
            if `"`lbl'"' == "" {
                continue
            }
            label variable `v' `"`lbl'"'
            local ++n_vl
        }
        di as txt "Variable labels reattached: `n_vl'"
    }

    * Reattach value labels / mappings (type-aware)
    if "`varsonly'" == "" {
        local n_encode 0
        local n_export 0
        local n_id     0

        forval i = 1/`nrows' {
            local v      "`r_vname_`i''"
            local lbname "`r_lbname_`i''"
            local vtype  "`r_type_`i''"

            capture confirm variable `v'
            if _rc {
                continue
            }

            * Read the mapping sheet for this variable
            tempfile valtmp
            local sheet_ok 1
            preserve
            quietly {
                capture {
                    import excel using `"`fname'"', ///
                        sheet("`v'") firstrow clear allstring
                    confirm variable numeric_code
                    save `"`valtmp'"', replace
                }
                if _rc {
                    local sheet_ok 0
                }
            }
            restore
            if !`sheet_ok' {
                continue
            }

            * Load mapping into locals
            preserve
            quietly use `"`valtmp'"', clear
            local nval = _N
            forval j = 1/`nval' {
                local c_`j' = numeric_code[`j']
                local l_`j' = string_value[`j']
            }
            restore

            * -- TYPE: encode -------------------------------------------------
            if "`vtype'" == "encode" {
                if "`lbname'" == "" {
                    local lbname "`v'"
                }
                local maxcode 0
                forval j = 1/`nval' {
                    local cj = real("`c_`j''")
                    if `cj' > `maxcode' {
                        local maxcode `cj'
                    }
                }
                quietly levelsof `v', local(cur_vals)
                local new_added 0
                foreach val of local cur_vals {
                    local found 0
                    forval j = 1/`nval' {
                        if `"`l_`j''"' == `"`val'"' {
                            local found 1
                        }
                    }
                    if !`found' {
                        local ++maxcode
                        local ++nval
                        local c_`nval' `maxcode'
                        local l_`nval' `"`val'"'
                        local ++new_added
                        di as txt "  [`v'] new category added: `val' -> `maxcode'"
                    }
                }
                local vt : type `v'
                if substr("`vt'",1,3) == "str" {
                    local vl_save : variable label `v'
                    quietly gen long _naam_`v' = .
                    forval j = 1/`nval' {
                        local cj = real("`c_`j''")
                        quietly replace _naam_`v' = `cj' if `v' == `"`l_`j''"'
                    }
                    quietly drop `v'
                    quietly rename _naam_`v' `v'
                    if `"`vl_save'"' != "" {
                        label variable `v' `"`vl_save'"'
                    }
                    di as txt "  [`v'] string encoded to numeric using saved mapping."
                }
                local code1 = real("`c_1'")
                label define `lbname' `code1' `"`l_1'"', replace
                forval j = 2/`nval' {
                    local cj = real("`c_`j''")
                    label define `lbname' `cj' `"`l_`j''"', add
                }
                label values `v' `lbname'
                if `new_added' > 0 {
                    preserve
                    quietly {
                        clear
                        set obs `nval'
                        gen str20  numeric_code = ""
                        gen str244 string_value = ""
                        forval j = 1/`nval' {
                            replace numeric_code = "`c_`j''"   in `j'
                            replace string_value = `"`l_`j''"' in `j'
                        }
                        local shname = substr("`v'",1,31)
                        export excel numeric_code string_value ///
                            using `"`fname'"', ///
                            sheet("`shname'") sheetreplace firstrow(variables)
                    }
                    restore
                    di as txt "  [`v'] Excel mapping updated with `new_added' new category(ies)."
                }
                local ++n_encode
            }

            * -- TYPE: export -------------------------------------------------
            else if "`vtype'" == "export" {
                if "`lbname'" == "" {
                    local lbname "`v'"
                }
                local code1 = real("`c_1'")
                label define `lbname' `code1' `"`l_1'"', replace
                forval j = 2/`nval' {
                    local cj = real("`c_`j''")
                    label define `lbname' `cj' `"`l_`j''"', add
                }
                label values `v' `lbname'
                local ++n_export
            }

            * -- TYPE: id -----------------------------------------------------
            else if "`vtype'" == "id" {
                local ++n_id
                di as txt "  [`v'] is an ID variable -- use naam id to convert a new file."
            }
        }

        if `n_encode' > 0 {
            di as txt "Encode mappings reattached: `n_encode' variable(s)"
        }
        if `n_export' > 0 {
            di as txt "Value labels reattached:    `n_export' variable(s)"
        }
        if `n_id' > 0 {
            di as txt "ID variables noted:         `n_id' variable(s)"
        }
    }

    di as res "naam apply complete."
end


* -----------------------------------------------------------------------------
program define naam_list
* Inspect a naam Excel mapping file from inside Stata.
* Prints a clean summary of every variable and its categories to the
* Results window. No dataset in memory is required or affected.
* -----------------------------------------------------------------------------
    version 14.0
    syntax using/ [, VARiable(string)]
    local fname `"`using'"'
    if substr(`"`fname'"',-5,5)!=".xlsx" & substr(`"`fname'"',-4,4)!=".xls" {
        local fname `"`fname'.xlsx"'
    }
    confirm file `"`fname'"'

    * Read index
    tempfile idxtmp
    preserve
    quietly {
        import excel using `"`fname'"', sheet("index") firstrow clear allstring
        capture confirm variable varname
        if _rc {
            restore
            di as err "Sheet [index] missing or malformed in `fname'"
            exit 111
        }
        save `"`idxtmp'"', replace
    }
    restore

    preserve
    quietly use `"`idxtmp'"', clear
    local nrows = _N
    forval i = 1/`nrows' {
        local r_vname_`i' = varname[`i']
        local r_vlab_`i'  = varlabel[`i']
        local r_type_`i'  = type[`i']
    }
    restore

    * Header
    di as txt _newline "{hline 60}"
    di as res "  naam mapping file: `fname'"
    di as txt "{hline 60}"

    local printed 0
    forval i = 1/`nrows' {
        local v    "`r_vname_`i''"
        local vlab "`r_vlab_`i''"
        local vtyp "`r_type_`i''"

        * If user requested a specific variable, skip others
        if "`variable'" != "" & "`v'" != "`variable'" {
            continue
        }

        * Try to load this variable's mapping sheet
        tempfile valtmp
        local sheet_ok 1
        preserve
        quietly {
            capture {
                import excel using `"`fname'"', ///
                    sheet("`v'") firstrow clear allstring
                confirm variable numeric_code
                save `"`valtmp'"', replace
            }
            if _rc local sheet_ok 0
        }
        restore

        di as txt _newline "  Variable : " as res "`v'"
        if `"`vlab'"' != "" {
            di as txt "  Label    : `vlab'"
        }
        di as txt "  Type     : `vtyp'"

        if !`sheet_ok' {
            di as txt "  (no mapping sheet found)"
            local ++printed
            continue
        }

        preserve
        quietly use `"`valtmp'"', clear
        local nval = _N
        restore

        if "`vtyp'" == "id" {
            di as txt "  IDs saved: `nval'"
        }
        else {
            di as txt "  Categories (`nval'):"
            preserve
            quietly use `"`valtmp'"', clear
            forval j = 1/`nval' {
                local cj = numeric_code[`j']
                local lj = string_value[`j']
                di as txt "    `cj'  =  `lj'"
            }
            restore
        }
        local ++printed
    }

    if `printed' == 0 & "`variable'" != "" {
        di as err "  Variable '`variable'' not found in `fname'"
        exit 111
    }

    di as txt _newline "{hline 60}"
    di as txt "  Total variables in file: `nrows'"
    di as txt "{hline 60}"
end


* -----------------------------------------------------------------------------
program define naam_decode
* Reverse a naam encoding: convert numeric variables back to their original
* strings using the saved mapping in the Excel file.
* Works even if value labels have been stripped from the dataset.
* -----------------------------------------------------------------------------
    version 14.0
    syntax varlist using/ [, keep]
    local fname `"`using'"'
    if substr(`"`fname'"',-5,5)!=".xlsx" & substr(`"`fname'"',-4,4)!=".xls" {
        local fname `"`fname'.xlsx"'
    }
    confirm file `"`fname'"'

    foreach v of local varlist {

        * Confirm the variable is numeric
        local vtype : type `v'
        if substr("`vtype'",1,3) == "str" {
            di as txt "  (skipping `v': already a string)"
            continue
        }

        * Try to load the mapping sheet for this variable
        tempfile valtmp
        local sheet_ok 1
        preserve
        quietly {
            capture {
                import excel using `"`fname'"', ///
                    sheet("`v'") firstrow clear allstring
                confirm variable numeric_code
                confirm variable string_value
                save `"`valtmp'"', replace
            }
            if _rc local sheet_ok 0
        }
        restore

        if !`sheet_ok' {
            di as err "  No mapping sheet found for `v' in `fname' -- skipping"
            continue
        }

        * Load mapping into locals
        preserve
        quietly use `"`valtmp'"', clear
        local nval = _N
        forval j = 1/`nval' {
            local c_`j' = numeric_code[`j']
            local l_`j' = string_value[`j']
        }
        restore

        * Determine the longest string value to set type
        local maxlen 1
        forval j = 1/`nval' {
            local slen = length(`"`l_`j''"')
            if `slen' > `maxlen' {
                local maxlen `slen'
            }
        }

        * Optionally keep the numeric variable
        if "`keep'" != "" {
            quietly clonevar _num_`v' = `v'
            label var _num_`v' "Numeric encoding of `v'"
        }

        * Generate string variable
        quietly gen str`maxlen' _str_`v' = ""
        forval j = 1/`nval' {
            local cj = real("`c_`j''")
            quietly replace _str_`v' = `"`l_`j''"' if `v' == `cj'
        }

        * Count unmatched observations
        quietly count if `v' != . & _str_`v' == ""
        local nunmatched = r(N)
        if `nunmatched' > 0 {
            di as txt "  warning: `nunmatched' observation(s) in `v' had no match in the mapping."
        }

        * Replace original variable with decoded string
        local vlab : variable label `v'
        quietly drop `v'
        quietly rename _str_`v' `v'
        label var `v' "`vlab'"

        di as txt "  -> `v' decoded to string (`nval' categories mapped)."
    }

    di as res "naam decode complete."
end


* -----------------------------------------------------------------------------
program define naam_check
* Compare the value labels currently attached to variables in memory against
* the saved mapping in the Excel file. Reports matches, conflicts, and any
* categories present in one but not the other.
* Does not modify the dataset or the Excel file.
* -----------------------------------------------------------------------------
    version 14.0
    syntax [anything(name=rawvars)] using/
    local fname `"`using'"'
    if substr(`"`fname'"',-5,5)!=".xlsx" & substr(`"`fname'"',-4,4)!=".xls" {
        local fname `"`fname'.xlsx"'
    }
    confirm file `"`fname'"'

    * Build the varlist -- skip any names that don't exist in the dataset
    local varlist ""
    if "`rawvars'" != "" {
        foreach v of local rawvars {
            capture confirm variable `v'
            if _rc {
                di as txt "  `v': not found in dataset -- skipped"
            }
            else {
                local varlist `varlist' `v'
            }
        }
    }

    * If no varlist given (or none survived), read all variables from the index
    if "`varlist'" == "" & "`rawvars'" == "" {
        tempfile idxtmp
        preserve
        quietly {
            import excel using `"`fname'"', sheet("index") firstrow clear allstring
            capture confirm variable varname
            if _rc {
                restore
                di as err "Sheet [index] missing or malformed"
                exit 111
            }
            save `"`idxtmp'"', replace
        }
        restore

        preserve
        quietly use `"`idxtmp'"', clear
        local nrows = _N
        forval i = 1/`nrows' {
            local varlist `varlist' `=varname[`i']'
        }
        restore
    }

    local any_conflict 0
    local any_missing  0

    di as txt _newline "{hline 60}"
    di as res "  naam check: `fname'"
    di as txt "{hline 60}"

    foreach v of local varlist {

        * Check variable has a value label attached
        local lbname : value label `v'
        if "`lbname'" == "" {
            di as txt _newline "  `v': no value label attached in dataset"
        }

        * Try to load mapping sheet from Excel
        tempfile valtmp
        local sheet_ok 1
        preserve
        quietly {
            capture {
                import excel using `"`fname'"', ///
                    sheet("`v'") firstrow clear allstring
                confirm variable numeric_code
                confirm variable string_value
                save `"`valtmp'"', replace
            }
            if _rc local sheet_ok 0
        }
        restore

        if !`sheet_ok' {
            di as txt _newline "  `v': no mapping sheet in Excel file -- skipped"
            continue
        }

        * Load Excel mapping into locals
        preserve
        quietly use `"`valtmp'"', clear
        local nxl = _N
        forval j = 1/`nxl' {
            local xc_`j' = real(numeric_code[`j'])
            local xl_`j' = string_value[`j']
        }
        restore

        * Compare each Excel entry against the in-memory value label
        local n_ok       0
        local n_conflict 0
        local n_missing  0

        di as txt _newline "  Variable: " as res "`v'"
        di as txt "  {hline 50}"

        forval j = 1/`nxl' {
            local code  = `xc_`j''
            local xl_lbl `"`xl_`j''"'

            if "`lbname'" != "" {
                local mem_lbl : label `lbname' `code', strict
            }
            else {
                local mem_lbl ""
            }

            if `"`mem_lbl'"' == "" & `"`xl_lbl'"' != "" {
                di as txt "    code `code': " as txt "not in dataset" ///
                    as txt "  (Excel: `xl_lbl')"
                local ++n_missing
                local any_missing 1
            }
            else if `"`mem_lbl'"' != `"`xl_lbl'"' {
                di as txt "    code `code': " as err "CONFLICT" as txt ///
                    "  dataset=`mem_lbl'  |  Excel=`xl_lbl'"
                local ++n_conflict
                local any_conflict 1
            }
            else {
                local ++n_ok
            }
        }

        * Check for codes in memory not in Excel
        if "`lbname'" != "" {
            quietly label list `lbname'
            local kmin = r(min)
            local kmax = r(max)
            forval code = `kmin'/`kmax' {
                local mem_lbl : label `lbname' `code', strict
                if `"`mem_lbl'"' == "" continue
                local found 0
                forval j = 1/`nxl' {
                    if `xc_`j'' == `code' {
                        local found 1
                    }
                }
                if !`found' {
                    di as txt "    code `code': " as err "in dataset but NOT in Excel" ///
                        as txt "  (dataset: `mem_lbl')"
                    local ++n_conflict
                    local any_conflict 1
                }
            }
        }

        di as txt "  {hline 50}"
        di as txt "    OK: `n_ok'  |  Conflicts: `n_conflict'  |  Missing in dataset: `n_missing'"
    }

    di as txt _newline "{hline 60}"
    if `any_conflict' {
        di as err "  CHECK FAILED: label conflicts detected. Review output above."
    }
    else if `any_missing' {
        di as txt "  CHECK NOTE: some mapping categories are not present in this dataset."
        di as res "  No conflicts -- all codes that exist in the dataset match the saved mapping."
    }
    else {
        di as res "  CHECK PASSED: all labels match the saved mapping."
    }
    di as txt "{hline 60}"
    exit 0
end


* -----------------------------------------------------------------------------
program define naam_compare
* Compare two naam Excel mapping files against each other.
* Reports variables present in one file but not the other, and any
* code-to-label conflicts for variables that appear in both.
* Does not require any dataset in memory.
* -----------------------------------------------------------------------------
    version 14.0
    syntax using/ [, USing2(string)]

    if `"`using2'"' == "" {
        di as err "naam compare requires two filenames: using filename1, using2(filename2)"
        exit 198
    }

    local fname1 `"`using'"'
    local fname2 `"`using2'"'

    if substr(`"`fname1'"',-5,5)!=".xlsx" & substr(`"`fname1'"',-4,4)!=".xls" {
        local fname1 `"`fname1'.xlsx"'
    }
    if substr(`"`fname2'"',-5,5)!=".xlsx" & substr(`"`fname2'"',-4,4)!=".xls" {
        local fname2 `"`fname2'.xlsx"'
    }

    confirm file `"`fname1'"'
    confirm file `"`fname2'"'

    * Read index from file 1
    tempfile idx1 idx2
    preserve
    quietly {
        import excel using `"`fname1'"', sheet("index") firstrow clear allstring
        capture confirm variable varname
        if _rc {
            restore
            di as err "Sheet [index] missing or malformed in `fname1'"
            exit 111
        }
        save `"`idx1'"', replace
    }
    restore

    preserve
    quietly use `"`idx1'"', clear
    local n1 = _N
    forval i = 1/`n1' {
        local f1_var_`i' = varname[`i']
        local f1_type_`i' = type[`i']
    }
    restore

    * Read index from file 2
    preserve
    quietly {
        import excel using `"`fname2'"', sheet("index") firstrow clear allstring
        capture confirm variable varname
        if _rc {
            restore
            di as err "Sheet [index] missing or malformed in `fname2'"
            exit 111
        }
        save `"`idx2'"', replace
    }
    restore

    preserve
    quietly use `"`idx2'"', clear
    local n2 = _N
    forval i = 1/`n2' {
        local f2_var_`i' = varname[`i']
        local f2_type_`i' = type[`i']
    }
    restore

    * Header
    di as txt _newline "{hline 60}"
    di as res "  naam compare"
    di as txt "  File 1: `fname1'"
    di as txt "  File 2: `fname2'"
    di as txt "{hline 60}"

    * Find variables only in file 1
    forval i = 1/`n1' {
        local v "`f1_var_`i''"
        local found 0
        forval j = 1/`n2' {
            if "`f2_var_`j''" == "`v'" local found 1
        }
        if !`found' {
            di as txt _newline "  `v': " as err "only in File 1"
        }
    }

    * Find variables only in file 2
    forval j = 1/`n2' {
        local v "`f2_var_`j''"
        local found 0
        forval i = 1/`n1' {
            if "`f1_var_`i''" == "`v'" local found 1
        }
        if !`found' {
            di as txt _newline "  `v': " as err "only in File 2"
        }
    }

    * Compare variables present in both files
    local any_conflict 0
    forval i = 1/`n1' {
        local v "`f1_var_`i''"

        * Check if v is in file 2
        local in2 0
        forval j = 1/`n2' {
            if "`f2_var_`j''" == "`v'" local in2 1
        }
        if !`in2' continue

        * Load mapping from file 1
        tempfile m1 m2
        local s1_ok 1
        preserve
        quietly {
            capture {
                import excel using `"`fname1'"', ///
                    sheet("`v'") firstrow clear allstring
                confirm variable numeric_code
                save `"`m1'"', replace
            }
            if _rc local s1_ok 0
        }
        restore
        if !`s1_ok' continue

        * Load mapping from file 2
        local s2_ok 1
        preserve
        quietly {
            capture {
                import excel using `"`fname2'"', ///
                    sheet("`v'") firstrow clear allstring
                confirm variable numeric_code
                save `"`m2'"', replace
            }
            if _rc local s2_ok 0
        }
        restore
        if !`s2_ok' continue

        * Load into locals
        preserve
        quietly use `"`m1'"', clear
        local nv1 = _N
        forval j = 1/`nv1' {
            local m1c_`j' = real(numeric_code[`j'])
            local m1l_`j' = string_value[`j']
        }
        restore

        preserve
        quietly use `"`m2'"', clear
        local nv2 = _N
        forval j = 1/`nv2' {
            local m2c_`j' = real(numeric_code[`j'])
            local m2l_`j' = string_value[`j']
        }
        restore

        * Compare file 1 entries against file 2
        local n_ok      0
        local n_conf    0
        local hdr_shown 0

        forval j = 1/`nv1' {
            local code `m1c_`j''
            local lbl1 `"`m1l_`j''"'
            local lbl2 ""
            forval k = 1/`nv2' {
                if `m2c_`k'' == `code' {
                    local lbl2 `"`m2l_`k''"'
                }
            }
            if `"`lbl2'"' == "" {
                if !`hdr_shown' {
                    di as txt _newline "  Variable: " as res "`v'"
                    di as txt "  {hline 50}"
                    local hdr_shown 1
                }
                di as txt "    code `code': " as err "only in File 1" ///
                    as txt "  (`lbl1')"
                local ++n_conf
                local any_conflict 1
            }
            else if `"`lbl1'"' != `"`lbl2'"' {
                if !`hdr_shown' {
                    di as txt _newline "  Variable: " as res "`v'"
                    di as txt "  {hline 50}"
                    local hdr_shown 1
                }
                di as txt "    code `code': " as err "CONFLICT" as txt ///
                    "  File1=`lbl1'  |  File2=`lbl2'"
                local ++n_conf
                local any_conflict 1
            }
            else {
                local ++n_ok
            }
        }

        * Codes in file 2 not in file 1
        forval k = 1/`nv2' {
            local code `m2c_`k''
            local lbl2 `"`m2l_`k''"'
            local found 0
            forval j = 1/`nv1' {
                if `m1c_`j'' == `code' local found 1
            }
            if !`found' {
                if !`hdr_shown' {
                    di as txt _newline "  Variable: " as res "`v'"
                    di as txt "  {hline 50}"
                    local hdr_shown 1
                }
                di as txt "    code `code': " as err "only in File 2" ///
                    as txt "  (`lbl2')"
                local ++n_conf
                local any_conflict 1
            }
        }

        if `hdr_shown' {
            di as txt "  {hline 50}"
            di as txt "    OK: `n_ok'  |  Conflicts / missing: `n_conf'"
        }
    }

    di as txt _newline "{hline 60}"
    if `any_conflict' {
        di as err "  COMPARE FAILED: differences found. Review output above."
    }
    else {
        di as res "  COMPARE PASSED: both files are fully consistent."
    }
    di as txt "{hline 60}"
end
