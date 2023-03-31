// Main Code //
clear
set seed 0
set obs 20000
forv i = 1/30 {
    gen var_`i' = rnormal()
    label var var_`i' "Dep Var `i'"
}
gen D = runiform() > 0.5
tostring D, replace
dgraph var_*, by(D) long labangle(45) label scheme(white_tableau) title("Graph") reverse mc(black) msize(1) lw(0.2) ci(90) labsize(vsmall) saving(gr_sample) replace echo tabsaving(table)
