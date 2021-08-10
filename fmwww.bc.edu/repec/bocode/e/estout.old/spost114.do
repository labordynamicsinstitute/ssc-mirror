spex tobjob2
eststo tobit: quietly tobit jobcen fem phd ment fel art cit, ll(1) nolog
gen cens = -(jobcen<=1)
eststo cnreg: quietly cnreg jobcen fem phd ment fel art cit, censored(cens) nolog
gen jobcen0 = jobcen if jobcen>1
eststo intreg: quietly intreg jobcen0 jobcen fem phd ment fel art cit, nolog
estadd prvalue, x(ment=min)  label(ment=min)  : *
estadd prvalue, x(ment=mean) label(ment=mean) : *
estadd prvalue, x(ment=max)  label(ment=max)  : *
estadd prvalue post : *
esttab, se nostar eqlabels(none) mtitles
eststo clear
