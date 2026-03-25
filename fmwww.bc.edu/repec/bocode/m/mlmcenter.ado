*! mlmcenter v1.0.0  Subir Hait  2026
*! Center variables for multilevel modeling
*! Grand-mean, group-mean, or within-between decomposition
program define mlmcenter
    version 14.1
    syntax varlist(numeric) [if] [in] ,        ///
        [ Cluster(varname)                      ///
          Type(string)                          ///
          Suffix_within(string)                 ///
          Suffix_between(string) ]

    // ---------- defaults ---------------------------------------------------
    if "`type'"           == "" local type           "grand"
    if "`suffix_within'"  == "" local suffix_within  "_within"
    if "`suffix_between'" == "" local suffix_between "_between"

    // ---------- validate type ----------------------------------------------
    if !inlist("`type'", "grand", "group", "both") {
        di as error "type() must be one of: grand  group  both"
        exit 198
    }

    if inlist("`type'", "group", "both") & "`cluster'" == "" {
        di as error "cluster() must be specified for type(group) or type(both)"
        exit 198
    }

    marksample touse, novarlist

    // ---------- loop over variables ----------------------------------------
    foreach v of local varlist {

        // confirm does not already exist
        if "`type'" == "grand" {
            capture confirm new variable `v'_c
            if _rc {
                di as error "Variable `v'_c already exists. Drop it first."
                exit 110
            }
        }
        if inlist("`type'", "group") {
            capture confirm new variable `v'_c
            if _rc {
                di as error "Variable `v'_c already exists. Drop it first."
                exit 110
            }
        }

        // ---- grand-mean centering -----------------------------------------
        if "`type'" == "grand" {
            quietly summarize `v' if `touse'
            local gm = r(mean)
            quietly generate double `v'_c = `v' - `gm' if `touse'
            label variable `v'_c "`v' (grand-mean centered)"
            di as text "Created: " as result "`v'_c" ///
               as text "  (grand mean = " as result %8.4f `gm' as text ")"
        }

        // ---- group-mean centering -----------------------------------------
        else if "`type'" == "group" {
            tempvar grpmean
            quietly bysort `cluster' (`touse'): ///
                egen `grpmean' = mean(`v') if `touse'
            quietly generate double `v'_c = `v' - `grpmean' if `touse'
            label variable `v'_c "`v' (group-mean centered on `cluster')"
            di as text "Created: " as result "`v'_c" ///
               as text "  (group-mean centered within `cluster')"
        }

        // ---- within-between decomposition ---------------------------------
        else if "`type'" == "both" {
            local wvar "`v'`suffix_within'"
            local bvar "`v'`suffix_between'"
            foreach nv in `wvar' `bvar' {
                capture confirm new variable `nv'
                if _rc {
                    di as error "Variable `nv' already exists. Drop it first."
                    exit 110
                }
            }
            tempvar grpmean
            quietly bysort `cluster' (`touse'): ///
                egen `grpmean' = mean(`v') if `touse'
            quietly generate double `wvar' = `v' - `grpmean' if `touse'
            quietly generate double `bvar' = `grpmean'         if `touse'
            label variable `wvar' "`v' (within `cluster')"
            label variable `bvar' "`v' (between: cluster mean on `cluster')"
            di as text "Created: " as result "`wvar'" ///
               as text " (within)  and  " as result "`bvar'" as text " (between)"
        }
    }
end
