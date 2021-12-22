*! version 4.1  Thursday, July 3, 2003 at 12:23  (SJ3-3: st0000)

program define miset
    version 7.0

    syntax using/ [, Mimps(integer 5) CLEAR]
    cap assert `mimps'>1
    if _rc {
        di "{err}more than one dataset is required"
        exit 198
    }
    cap assert `mimps'< 10
    if _rc {
        di "{err}maximum 9 datasets"
        exit 198
    }

    forvalues j=1/`mimps' {
        confirm file "`using'`j'.dta"
    }

    nobreak {
        forvalues j=1/`mimps' {
            cap erase "_mitemp`j'.dta"
            qui copy "`using'`j'.dta" "_mitemp`j'.dta"
        }
        forvalues j=1/`mimps'{
            qui use "_mitemp`j'.dta", `clear'
            qui note: "copied from `using'`j'.dta"
            qui save, replace
        }

        global mi_uf "`using'"
        global mi_sf _mitemp
        global mimps "`mimps'"

        local this 1
        qui use _mitemp1.dta, clear

        if $mimps==2{
            #delimit ;
            di "{p}{txt}`using'1.dta and `using'$mimps.dta have been copied to _mitemp1.dta and _mitemp$mimps.dta" ;
            #delimit cr
        }
        else {
            #delimit ;
            di "{p}{txt}`using'1.dta to `using'$mimps.dta were loaded
            to $mi_sf`this'.dta to $mi_sf$mimps.dta respectively" ;
            #delimit cr
        }
    }
end
/*  syntax:
        miset using <filename prefix> [, mimps(integer 5)]

    Once miset, the using files are copied into temporary files
    _mitemp1.dta,..., _mitemp$nim.dta. Any changes are done to
    these temporary files.
*/
