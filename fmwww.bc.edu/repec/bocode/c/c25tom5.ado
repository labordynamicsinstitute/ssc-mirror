

capture program drop c25tom5
program define c25tom5
    version 13.0
    syntax varname(numeric) , gen(name)

    quietly {

        gen `gen' = .

        * 1 Personal
        replace `gen' = 1 if inlist(`varlist', 1, 2, 3)

        * 2 Paid work
        replace `gen' = 2 if inlist(`varlist', 4, 5, 17)

        * 3 Unpaid work
        replace `gen' = 3 if inlist(`varlist', 6, 7, 8, 9, 10, 11, 12, 13, 14)

        * 4 Leisure
        replace `gen' = 4 if inlist(`varlist', 15, 16, 19, 20, 21, 22, 23, 24)

        * 5 Travel
        replace `gen' = 5 if `varlist' == 18

        * Missing values → system missing
        replace `gen' = . if inlist(`varlist', 25) ///
            | `varlist'==.a | `varlist'==.b | `varlist'==.c | `varlist'==.d

        * Value label
        capture label drop `gen'_lbl
        label define `gen'_lbl ///
            1 "personal" ///
            2 "paid work" ///
            3 "unpaid work" ///
            4 "leisure" ///
            5 "travel"

        label values `gen' `gen'_lbl
    }
end
