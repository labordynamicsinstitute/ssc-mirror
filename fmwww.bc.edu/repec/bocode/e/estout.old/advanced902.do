sysuse auto
xi: reg price weight mpg i.rep
capt matrix drop nobs
foreach cat of varlist _Irep* {
    count if `cat'==1 & e(sample)
    matrix nobs = nullmat(nobs), r(N)
    local collab "`collab'`cat' "
}
matrix colname nobs = `collab'
estadd matrix nobs
esttab, cells("b(fmt(a3)) t(fmt(2)) nobs") nogap
