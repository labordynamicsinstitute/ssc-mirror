use "MeritExampleDataDiDIntjl.dta", clear

* For more details, call:
* help didintjl_plot
preserve
keep if inlist(state, "34", "71", "11", "14")
didintjl_plot, outcome("coll") state("state") time("year") treatment_times("2000 1991") date_format("yyyy") covariates("asian male black") ccc("hom int")
restore

gen year_numeric = real(year) 
bysort state (year_numeric): egen gvar = min(cond(merit == 1, year_numeric, .))


didintjl_plot, outcome(coll) state(state) time(year_numeric) gvar(gvar) date_format("yyyy") covariates("asian male black") event(1) 