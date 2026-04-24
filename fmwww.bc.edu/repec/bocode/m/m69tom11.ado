

capture program drop m69tom11
program define mcc9tom11
    version 13.0
    syntax varname(numeric) , gen(name)

    quietly {
        gen `gen' = .

        * 1 Sleep
        replace `gen' = 1 if inlist(`varlist', 2, 3)

        * 2 Eating
        replace `gen' = 2 if inlist(`varlist', 5, 6, 39)

        * 3 Personal care
        replace `gen' = 3 if inlist(`varlist', 1, 4, 25)

        * 4 Paid work
        replace `gen' = 4 if inlist(`varlist', 7, 8, 9, 10, 11, 12, 13, 14)

        * 5 Education
        replace `gen' = 5 if inlist(`varlist', 15, 16, 17)

        * 6 Housework and shopping
        replace `gen' = 6 if inlist(`varlist', 18, 19, 20, 21, 22, 23, 24, 26, 27, 47)

        * 7 Care activities
        replace `gen' = 7 if inlist(`varlist', 28, 29, 30, 31, 32)

        * 8 Travel
        replace `gen' = 8 if inlist(`varlist', 62, 63, 64, 65, 66, 67, 68)

        * 9 Exercise and active leisure
        replace `gen' = 9 if inlist(`varlist', 42, 43, 44, 45, 46)

        * 10 In-home leisure
        replace `gen' = 10 if inlist(`varlist', 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61)

        * 11 Out-of-home leisure, social, civic and religion
        replace `gen' = 11 if inlist(`varlist', 33, 34, 35, 36, 37, 38, 40, 41, 48, 49)

        * 69 = no recorded activity -> missing
        replace `gen' = . if `varlist' == 69

        * Value labels
        capture label drop `gen'_lbl
        label define `gen'_lbl ///
            1  "sleep" ///
            2  "eating" ///
            3  "personal care" ///
            4  "paid work" ///
            5  "education" ///
            6  "housework and shopping" ///
            7  "care activities" ///
            8  "travel" ///
            9  "exercise and active leisure" ///
            10 "in-home leisure" ///
            11 "out-of-home leisure, social, civic and religion"

        label values `gen' `gen'_lbl
    }
end
