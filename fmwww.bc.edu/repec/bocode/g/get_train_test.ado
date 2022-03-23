program get_train_test , rclass
syntax , dataname(name) split(numlist) split_var(name) rseed(integer)
qui{
splitsample, generate(`split_var', replace) split(`split') rseed(`rseed')
preserve
keep if `split_var'==1
save `dataname'_train , replace  
restore
preserve
keep if `split_var'==2
save `dataname'_test , replace  
restore
}
end
