*! version 1.0, 2024may31. Noah J. Case.

program define _gdistinct, nclass sortpreserve
    version 7.0

    gettoken type 0 : 0
    gettoken newvarname   0 : 0
    gettoken eqs  0 : 0    // known to be "="

    syntax varlist [if] [in], [BY(varlist) BYMISSOK]
    marksample touse, novarlist strok
    tempvar t1 t2
    if !missing("`bymissok'") {
        if !missing("`by'") {
            local bymissing ", missing"
        }
        else if missing("`by'") {
            display as error "Option " as input "bymissok" ///
                as error " cannot be specified without without " as input "by"
            exit 198
        }
    }

    if !missing("`by'") { // Checks if `by` is specified
        egen byte `t1' = tag(`by' `varlist') if `touse'`bymissing'
        bysort `by': egen `type' `t2' = total(`t1') if `touse'
    }

    else {
        egen byte `t1' = tag(`varlist') if `touse' // `bymissok` illegal here
        egen `type' `t2' = total(`t1') if `touse'
    }

    assert !missing(`t2') & `t2' >= 0 if `touse'
    rename `t2' `newvarname'
end program
