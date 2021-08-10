spex regjob2
quietly regress job fem phd ment fel art cit
estadd prvalue, x(ment=min)  label(ment=min)
estadd prvalue, x(ment=mean) label(ment=mean)
estadd prvalue, x(ment=max)  label(ment=max)
estadd prvalue post
esttab, ci nostar wide eqlabels(none)
