*! version 2.2  Thursday, July 3, 2003 at 12:20
/*
    This code runs estcmd for each of miset data file, saves results
    for later use.

    INPUT :
        estcmd -- the original estimation command, possibly with options
        optindiv -- option to display individual estimation tables.

    OUTPUT:
        data file named "`outfile'" and macros
*/

program define _mi_ESTIMATE, rclass
    version 7
    args estcmd optindiv outfile
    tempfile mast usef
    tempname theb theV
    forvalues i=1/$mimps {
        qui use $mi_sf`i', clear
        if `i'==1 &"`optindiv'"=="indiv" { di }
        if "`optindiv'"=="indiv" {
            local qui
            local di di
            local diovall ->
            __mydis $mi_sf `i'
            local dis di in gr "-> dataset = `r(this)'.dta"
        }
        else {
            local dis
            local qui qui
        }
        `qui' di
        `dis'
        cap est drop _mimodel`i'
        `qui' `estcmd'
        `di'
        return scalar obs`i'=e(N)
        return scalar n_sub`i'=e(N_sub)
        return scalar df_m`i'=e(df_m)
        return local depv=e(depvar)
        return local est_cmd=e(cmd)
        mat `theb' = e(b)
        mat `theV' = e(V)


/*get column names of e(b) - for test to determine whether fitted model differs across datasets*/
        local names`i': colnames `theb'

        if `i'==1 {
               local nameb: colfullnames `theb'
               local nameVr: rowfullnames `theV'
               local nameVc: colfullnames `theV'
               _mi_abbrev "`nameb'" mi_mifit_nameb
               _mi_abbrev "`nameVr'" mi_mifit_nameVr
               _mi_abbrev "`nameVc'" mi_mifit_nameVc

        }

        qui save $mi_sf`i', replace
        local n=e(N)

        qui _parmest
        est hold _mimodel`i'
        local numcoef=colsof(`theb')
        return local numcoef`i' `numcoef'
        return matrix b_`i' `theb'
        return matrix V_`i' `theV'
        qui rename stderr se
        qui rename estimate est
        qui gen obs=`n'
        keep parm est se obs

        if `numcoef'>1 { egen dumyid=fill(1 2) }
        else { gen dumyid=1 }
        gen tt = `i'

        if `i'==1 {
            cap erase `mast'.dta
            qui save `mast'
        }
        else {
            append using `mast'
            qui save `mast', replace
        }

    }    /*  the varibles parm est and se, for all imputed datasets, are in mast.dta now */
    sort dumyid tt
    cap erase  `outfile'
    qui save `outfile'

/*Set error flag, $mi_combine2, to F if colnames of e(b) not the same across datasets
 - to test whether fitted model differs across datasets. Error displayed back in mifit */
    forvalues i=2/$mimps {
        local j=`i'-1
        if "`names`i''" != "`names`j''" {
            global mi_combine2 F
        }
    }

/*Set error flag, $mi_combine1, to F if se or est is missing
 - to test for collinearity. Error displayed back in mifit */
    qui count if est==. | se==. | se==0
    if r(N) { global mi_combine1 F  }

end

program define __mydis, rclass
    args data i
    local short = abbrev("`data'`i'",12)
    return local this "`short'"
end

program define _mi_abbrev, rclass
    args longnamelist  shrt
    tokenize `longnamelist'
    local b
    while "`1'"!="" {
        local a = abbrev("`1'",12)
        local b `b' `a'
        mac shift
    }
    global `shrt' `b'
end
