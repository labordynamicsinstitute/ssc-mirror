clear all

program define reshapelabel, nclass
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

* 1. Test that it fails when ivar does not uniquely identify data
clear
input str6 firm str3 month sales
"Firm A" "Jan" 10
"Firm A" "Jan" 12
"Firm A" "Feb" 15
end

capture reshapelabel, metric(sales) jvar(firm) ivar(month)
assert _rc == 459

* 2. Test that it succeeds on valid long data
clear
input str6 firm str3 month int sales
"Firm A" "Jan" 10
"Firm A" "Feb" 12
"Firm B" "Jan"  8
"Firm B" "Feb"  9
end

reshapelabel, metric(sales) jvar(firm) ivar(month)
assert _rc == 0

* 3. Test that reshape worked
confirm variable sales1
confirm variable sales2

*4. Test that values reshaped correctly
assert sales1 == 10 if month == "Jan"
assert sales1 == 12 if month == "Feb"
assert sales2 ==  8 if month == "Jan"
assert sales2 ==  9 if month == "Feb"

*5. Test that variable labels were preserved from jvar
local lbl1 : variable label sales1
local lbl2 : variable label sales2

assert "`lbl1'" == "Firm A"
assert "`lbl2'" == "Firm B"
