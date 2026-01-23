
program define reshapelabel, nclass
	version 18.5
    syntax, METRIC(varname) JVAR(varname) IVAR(varlist)

    * Verify that the user entered a string as their jvar input
    * Verify that the string is smaller than the maximum length of a var label
    confirm string variable `jvar'
    assert strlen(`jvar') <= 80

    * Verify that the combination of the `ivar' list and the specified
    * `jvar' uniquely identifies the dataset
    capture isid `ivar' `jvar'
    if _rc {
        display as error "The combination of ivar() and jvar() must uniquely identify the dataset."
        exit 459
    }

    * Generate a sorting variable that preserves the original sort order
    tempvar rank
    bysort `jvar': generate long `rank' = _n

    * Create an encoded variable that holds the `jvar' strings as labels
    tempvar num_j
    encode `jvar', generate (`num_j')
    drop `jvar'

    * Store the count of unique values of the `jvar' variable
    quietly tabulate `num_j'
    local unique_count = r(r)

        * Loop over the count of unique values to store label1 through _N
    forvalues code = 1/`unique_count' {
        local label`code' : label (`num_j') `code'
    }

    reshape wide `metric', i(`ivar' `rank') j(`num_j')

    * After reshaping, apply the labels to each variable
    forvalues code = 1/`unique_count' {
        label variable `metric'`code' "`label`code''"
    }

    sort `rank'
    drop `rank'

end
