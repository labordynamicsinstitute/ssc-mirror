capture program drop basetable_example_data
program define basetable_example_data
    *Retrieve a sample dataset:
    use low age race ftv smoke using "http://www.stata-press.com/data/r12/hospid2.dta", clear
    *Variable labels and value labels can be set to make the table publication ready:
    label define low 0 "Normal" 1 "Low"
    label values low low
    label define ftv 0 "0 visits" 1 "1 visit" 2 "2 visits" 3 "3 visits" 4 "4 visits" 5 "5 visits" 6 "6 visits"
    label values ftv ftv
    *Creating a sample dataset and missings:
    replace low = . in 4/6
    replace age = . in 5/8
    replace race = . in 3/8
    *Generate a significant test to demonstrate the use less than signs at P values:
    replace age = age + 2 if !low
end
