spex tobjob2
gen jobcen0 = jobcen if jobcen>1
intreg jobcen0 jobcen fem phd ment fel art cit, nolog
estadd fitstat
estadd listcoef
esttab, aux(b_std) wide scalars(r2_mfadj r2_ml r2_cu r2_mz)
