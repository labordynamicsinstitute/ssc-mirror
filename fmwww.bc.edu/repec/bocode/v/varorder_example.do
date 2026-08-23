version 16.0

/*
    varorder 1.0.0 example

    Place this file, varorder_example_data.dta, and varorder.ado in the same
    directory, start Stata in that directory, and run:

        do varorder_example.do
*/

clear all
set more off

capture confirm file "varorder.ado"
if _rc {
    display as error "varorder.ado was not found in the current directory"
    exit 601
}

capture confirm file "varorder_example_data.dta"
if _rc {
    display as error "varorder_example_data.dta was not found in the current directory"
    exit 601
}

quietly do "varorder.ado"
use "varorder_example_data.dta", clear

* Review the preview, then press Enter to apply the proposed order.
varorder

* Display the command's returned results.
return list

* Restore the physical variable order that preceded the successful varorder.
varorder, undo
