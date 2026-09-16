*! version 1.2  13sep2026  Kelvin K.F. Law
*! Internal output and label utilities shipped with sic_to_ff
program ffcode_util, rclass
    version 14.0
    gettoken action 0 : 0, parse(" ,")
    if "`action'" == "version" {
        return scalar api = 112
        exit
    }
    if !inlist("`action'", "check", "commit", "prepare", "require") exit 198
    _ffcode_`action' `0'
    return add
end

program _ffcode_check
    version 14.0
    syntax, OUTPUTS(string) [INPUTS(string) RESERVED(string) REPLACE]
    local seen ""
    local existing ""
    capture unab existing : _all
    local special "_all _n _N _pi _b _coef _se _cons _pred _rc _skip"
    foreach target of local outputs {
        confirm name `target'
        if `: list target in special' {
            display as error "Output `target' is a reserved Stata name"
            exit 198
        }
        if `: list target in seen' {
            display as error "Output names must be distinct: `target'"
            exit 198
        }
        if `: list target in inputs' {
            display as error "Output `target' must differ from every input variable"
            exit 198
        }
        if `: list target in reserved' {
            display as error "Output `target' uses a reserved internal name"
            exit 198
        }
        if `: list target in existing' {
            if "`replace'" == "" {
                display as error "variable `target' already exists; use replace"
                exit 110
            }
        }
        else {
            * Validate a single variable name, including Stata's reserved names.
            confirm new variable `target', exact
        }
        local seen "`seen' `target'"
    }
end

program _ffcode_require
    version 14.0
    syntax, COMMAND(name)
    capture findfile `command'.ado
    if _rc {
        display as error "Install `command' version 1.2 or later, then restart Stata."
        exit 111
    }
    local path "`r(fn)'"
    tempname fh
    local detected ""
    file open `fh' using "`path'", read text
    forvalues i = 1/20 {
        file read `fh' line
        if r(eof) continue, break
        local pos = strpos(`"`line'"', "*! version ")
        if `pos' {
            local tail = substr(`"`line'"', `pos' + 11, .)
            gettoken detected rest : tail
            continue, break
        }
    }
    file close `fh'
    local parts : subinstr local detected "." " ", all
    local major : word 1 of `parts'
    local minor : word 2 of `parts'
    local patch : word 3 of `parts'
    if "`patch'" == "" local patch "0"
    local ok 0
    if !missing(real("`major'"), real("`minor'"), real("`patch'")) {
        local ok = real("`major'") > 1 | ///
            (real("`major'") == 1 & real("`minor'") >= 2)
    }
    if !`ok' {
        display as error "`command' version 1.2 or later is required (found `detected')."
        display as error "Update both packages and restart Stata before using them."
        exit 111
    }
end

program _ffcode_commit
    version 14.0
    syntax, OUTPUTS(string) STAGED(string) [REPLACE VARIABLE(varname) ///
        CANONICAL(name) LABEL(name) OWNED(integer 0)]
    _ffcode_check, outputs("`outputs'") `replace'
    local n : word count `outputs'
    if `n' != `: word count `staged'' exit 198
    foreach stage of local staged {
        confirm variable `stage', exact
    }
    if "`label'" != "" {
        confirm variable `variable', exact
        quietly label list `canonical'
    }
    * Register label ownership before any permanent definition is created.
    * Keep old variables until all label and rename operations have succeeded.
    local backups ""
    forvalues i = 1/`n' {
        tempvar backup`i'
        local old`i' 0
        local new`i' 0
    }
    nobreak {
        capture noisily {
            if "`label'" != "" {
                if `owned' label copy `canonical' `label'
                label values `variable' `label'
            }
            forvalues i = 1/`n' {
                local target : word `i' of `outputs'
                capture confirm variable `target', exact
                if _rc == 0 {
                    rename `target' `backup`i''
                    local old`i' 1
                    local backups "`backups' `backup`i''"
                }
                local stage : word `i' of `staged'
                rename `stage' `target'
                local new`i' 1
            }
        }
        local rc = _rc
        if `rc' {
            forvalues i = `n'(-1)1 {
                local target : word `i' of `outputs'
                local stage : word `i' of `staged'
                if `new`i'' rename `target' `stage'
                if `old`i'' rename `backup`i'' `target'
            }
            if "`label'" != "" & `owned' capture label drop `label'
        }
        else if "`backups'" != "" drop `backups'
    }
    if `rc' exit `rc'
end

program _ffcode_prepare, rclass
    version 14.0
    syntax, VARIABLE(varname) PUBLICNAME(name) SCHEME(string) CANONICAL(name)
    if !inlist("`scheme'", "5", "10", "12", "17", "30", "38", "48", "49") exit 198
    _ffcode_define `variable' `scheme' `canonical'
    * An undefined label can still be attached to a variable. Reserve those names.
    local associated ""
    unab variables : _all
    foreach v of local variables {
        local association : value label `v'
        if "`association'" != "" local associated "`associated' `association'"
    }
    local base = substr("`publicname'", 1, 28)
    local lbl "`base'_lbl"
    local suffix 0
    local available 0
    local owned 1
    while !`available' {
        capture quietly label list `lbl'
        if _rc == 0 {
            mata: st_local("same", strofreal(__ffcode_same_labels("`canonical'", "`lbl'")))
            if `same' {
                local available 1
                local owned 0
            }
        }
        else if !`: list lbl in associated' local available 1
        if !`available' {
            local ++suffix
            local tail "_lbl`suffix'"
            local lbl = substr("`publicname'", 1, 32 - strlen("`tail'")) + "`tail'"
        }
    }
    return local label "`lbl'"
    return scalar owned = `owned'
end

program _ffcode_define
    args varname scheme lbl
    
    
    if "`scheme'" == "5" {
        label define `lbl' ///
            1 "Cnsmr" ///
            2 "Manuf" ///
            3 "HiTec" ///
            4 "Hlth" ///
            5 "Other"
    }
    else if "`scheme'" == "10" {
        label define `lbl' ///
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
        label define `lbl' ///
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
        label define `lbl' ///
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
        label define `lbl' ///
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
        label define `lbl' ///
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
        label define `lbl' ///
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
        label define `lbl' ///
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
    
    label values `varname' `lbl'
end

capture mata: mata drop __ffcode_same_labels()
mata:
real scalar __ffcode_same_labels(string scalar a, string scalar b)
{
    real colvector av, bv
    string colvector at, bt
    st_vlload(a, av, at)
    st_vlload(b, bv, bt)
    if (rows(av) != rows(bv)) return(0)
    return(all(av :== bv) & all(at :== bt))
}
end
