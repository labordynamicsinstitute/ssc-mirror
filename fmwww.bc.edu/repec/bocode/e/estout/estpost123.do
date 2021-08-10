label define race 1 "Race: White" 2 "Race: Black" 3 "Race: Other", modify
label define diabetes 0 "no diab." 1 "diabetes"
label values diabetes diabetes
estpost svy: tabulate race diabetes, row percent
esttab ., se nostar nostar unstack ///
    varlabels(`e(labels)') eqlabels(`e(eqlabels)')
