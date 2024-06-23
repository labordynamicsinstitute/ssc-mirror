*! number_exporting: number_exporting formats a given numeric value (numeric_value) based on user specifications. It outputs the formatted number into a LaTeX compatible .tex file. The function can handle absolute values, percentages, and specific decimal formatting, making it suitable for saving numeric data for reports or publications in LaTeX format.
*! Version: June, 2024
*! Authors: Olena Bogdan, Adrien Matray, Pablo E. Rodriguez, and Chenzi Xu
program define number_exporting
syntax anything, Name(string) [percent digits(integer 2) absolute]
version 13.0

* Take absolute value if specified
if "`absolute'" != "" {
    local anything = abs(`anything')
}

* Format the input value based on specified digits, and percent options
local digits_format = "%9." + string(`digits') + "fc"


* Format for percentage if specified
if "`percent'"!="" {
	local anything = `anything' * 100
    local anything = string(`anything', "`digits_format'")
    local temp = "`anything'\%%"  // Escape the percent sign for LaTeX
    local anything = "`temp'"
}
else{
	local anything = string(`anything', "`digits_format'")
    local temp = "`anything'%" 
    local anything = "`temp'"
	
}

* Print output
di "Final formatted output: `anything'"

* Set up file write
tempname `name'
file open `name' using "$number/`name'.tex", write text replace
file write `name' "`anything'"
file close `name'

end
