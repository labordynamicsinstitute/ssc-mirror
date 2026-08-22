*! _gvar_foreign 1.0.1  21aug2026
*! gvar foreign -- construct the foreign-specific (star) variables x*_it.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   x*_it = sum_j w_ij x_jt                  <- Toolbox create_foreignvariables.m
*   renormalisation when a unit lacks a
*   variable (the SECOND normalisation)      <- same file, vind / wmatx block
*   year-by-year weighting                   <- Toolbox build_wmat.m tv branch
*                                               GVARX GVAR_Ft (list branch)
*   assembly of the unit models              <- Toolbox create_countrymodels.m

program define _gvar_foreign, rclass
    version 14.0

    syntax [, GENerate PREfix(name) SUFfix(name) REPLACE LIST noSUMmary ]

    _gvar_require setup

    * rebuild the star variables and the unit models from the current weights
    mata: gvar_specify()

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("K",  strofreal(gvar_getK()))
    mata: st_local("T",  strofreal(gvar_getT()))
    mata: st_local("cn", invtokens(gvar_getcname()'))

    * -----------------------------------------------------------------------
    * Optionally write the star variables back into the Stata dataset
    * -----------------------------------------------------------------------
    if ("`generate'" != "") {
        if ("`prefix'" == "" & "`suffix'" == "") local suffix "_star"
        mata: _gvar_write_stars("`prefix'", "`suffix'", "`replace'" != "")
        di as text "Foreign-specific variables written to the dataset."
    }

    if ("`summary'" != "nosummary") {
        * ---- one signature per unit ---------------------------------------
        local i 0
        foreach c of local cn {
            local ++i
            mata: st_local("yl", invtokens(gvar_getylist(`i')'))
            mata: st_local("sl", invtokens(gvar_getslist(`i')'))
            local sl2 ""
            foreach s of local sl {
                local sl2 "`sl2' `s'*"
            }
            local dom`i' = trim("`yl'")
            local exo`i' = trim("`sl2'")
            local sig`i' "`dom`i''  ||  `exo`i''"
        }

        * ---- the modal specification ---------------------------------------
        local bestn 0
        local besti 1
        forvalues i = 1/`N' {
            local cnt 0
            forvalues j = 1/`N' {
                if (`"`sig`i''"' == `"`sig`j''"') local ++cnt
            }
            if (`cnt' > `bestn') {
                local bestn `cnt'
                local besti `i'
            }
        }

        _gvar_title "Foreign-specific variables"
        di as text "  Cross-section units          " as result %8.0f `N'
        di as text "  Endogenous variables (K)     " as result %8.0f `K'
        di as text "  Time periods                 " as result %8.0f `T'
        di ""
        di as text "  Common specification, shared by " as result `bestn' ///
                   as text " of " as result `N' as text " units"
        di as text "    domestic         : " as result "`dom`besti''"
        di as text "    weakly exogenous : " as result "`exo`besti''"

        if (`bestn' < `N') {
            di ""
            di as text "  Units departing from it"
            di as text "  {hline 74}"
            local i 0
            foreach c of local cn {
                local ++i
                if (`"`sig`i''"' == `"`sig`besti''"') continue
                di as text "  {bf:`c'}"
                di as text "    domestic         : " as result "`dom`i''"
                di as text "    weakly exogenous : " as result "`exo`i''"
            }
            di as text "  {hline 74}"
        }
        di ""
        di as text "  A trailing * marks a foreign-specific variable."
        di as text "  Weights are renormalised over the units that own each variable."
        di as text "  Use {bf:gvar foreign, list} for the full per-unit listing."
        di ""
    }

    if ("`list'" != "") {
        _gvar_foreign_list
    }

    return scalar N = `N'
    return scalar K = `K'
    return scalar T = `T'
end

* ---------------------------------------------------------------------------
program define _gvar_foreign_list
    version 14.0
    mata: st_local("N", strofreal(gvar_getN()))
    mata: st_local("cn", invtokens(gvar_getcname()'))
    local i 0
    foreach c of local cn {
        local ++i
        mata: st_local("yl", invtokens(gvar_getylist(`i')'))
        mata: st_local("sl", invtokens(gvar_getslist(`i')'))
        di ""
        di as text "  {bf:`c'}"
        di as text "    endogenous      : " as result "`yl'"
        di as text "    weakly exogenous: " as result "`sl'"
    }
    di ""
end

* ---------------------------------------------------------------------------
