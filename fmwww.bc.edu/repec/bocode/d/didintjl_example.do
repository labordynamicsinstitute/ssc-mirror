use "MeritExampleDataDiDIntjl.dta", clear

* aggregation is by "cohort" (treatment time cohort) and weighting is set to "both" (applies weighting while computing sub-aggregate level ATTs and when computing the aggregate ATT from the sub-aggregate ATTs) by default. The ccc() option is set to "int" by default. 
* For more details, call:
help didintjl

* CCC : two-way intersection
didintjl, outcome("coll") state("state") time("year") treated_states("34 57 58 59 61 64 71 72 85 88") treatment_times("2000 1998 1993 1997 1999 1996 1991 1998 1997 2000") date_format("yyyy") covariates("asian male black") ccc("int") agg("cohort") weighting("both") seed(1234)

* It is also possible to generate a gvar column
* and use syntax similar to csdid:
* (note that the variable merit is 1 for treated obs and 0 for non-treated obs)
gen year_numeric = real(year) 
bysort state (year_numeric): egen gvar = min(cond(merit == 1, year_numeric, .))
replace gvar = 0 if missing(gvar) // This line is actually optional, you can leave non-treated states as having a missing gvar value


didintjl, outcome(coll) state(state) time(year_numeric) gvar(gvar) covariates(asian male black) seed(1234)

// Other ccc options include :
* "time"
* "state"
* "int" (default)
* "add"
* "hom"

// Other agg options include :
* "cohort" (default)
* "state"
* "simple"
* "none"
* "sgt"
* "time"

// Other weighting options include :
* "both" (default)
* "att"
* "diff"
* "none"

* CCC : time
didintjl, outcome("coll") state("state") time("year") treated_states("34 57 58 59 61 64 71 72 85 88") treatment_times("2000 1998 1993 1997 1999 1996 1991 1998 1997 2000") date_format("yyyy") covariates("asian male black") ccc("time")

* CCC : state
didintjl, outcome("coll") state("state") time("year") treated_states("34 57 58 59 61 64 71 72 85 88") treatment_times("2000 1998 1993 1997 1999 1996 1991 1998 1997 2000") date_format("yyyy") covariates("asian male black") ccc("state")


* CCC : additive
didintjl, outcome("coll") state("state") time("year") treated_states("34 57 58 59 61 64 71 72 85 88") treatment_times("2000 1998 1993 1997 1999 1996 1991 1998 1997 2000") date_format("yyyy") covariates("asian male black") ccc("add") agg("state") weighting("none")

* CCC : homogenous
didintjl, outcome("coll") state("state") time("year") treated_states("34 57 58 59 61 64 71 72 85 88") treatment_times("2000 1998 1993 1997 1999 1996 1991 1998 1997 2000") date_format("yyyy") covariates("asian male black") ccc("hom") agg("state") weighting("none")
