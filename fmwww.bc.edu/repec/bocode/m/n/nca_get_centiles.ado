cap pro drop nca_get_centiles
pro def nca_get_centiles, rclass
syntax varlist (max=1) [if] [in], matrix(namelist) [corner(integer 1)]
marksample touse
tempname out
matrix `out'=J(rowsof(`matrix'), colsof(`matrix'),.)
quie count if `touse'
local Nobs=r(N)
if inlist(`corner',1,3) local sign <
else local sign>
forval i=1/`=rowsof(`matrix')' {
	forval j=1/`=colsof(`matrix')' {
	if missing(`matrix'[`i',`j']) continue
	quie count if `varlist' `sign' `matrix'[`i',`j'] & `touse'
	matrix `out'[`i',`j']=100*`=r(N)'/`Nobs'
	}
	
}
return matrix centiles=`out'
end
