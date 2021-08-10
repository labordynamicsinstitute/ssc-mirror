capture program drop kapgof 
program define kapgof, rclass
*! 1.4 28 Aug 2002 Jan Brogger jan.brogger@med.uib.no
*28Aug2002 Small bug fixed. Scalar N was refered to directly, not as a tempname. Fixed throughout.
*8July2001 Bug in agreement pointed out by Jose Maria Pacheco de Souza
*Bug fixed in May by M. Reichenheim (michael@ims.uerj.br)
*Confidence intervals for kappa constructed according to
*Donner & Eliasziw, Statistics in medicine; 1992: 11: 1511-1519
*Variable must be coded as 0 (failure) and 1 (success)
*Intermediate results are stored as scalars for precision
	version 6.0
	syntax varlist(max=2 min=2) [,  level(real 0.05) *]
	tempname tab2x2 rkappa rprop_e rprop_o rN rse rz N a b c d n1 n2 n3 p chi1 y1 y2 y3 V W theta kappal kappau agr agrub agrlb agrN

	if "`options'"~="" {local options=", `options'"}

	tokenize "`varlist'"
	while "`1'"~="" {
		qui count if !(`1'==1 |  `1'==0 | `1'==.)
		if (`r(N)'>0)  {
			di in red "Both variables must be coded 0 or 1." _n "If you think this is silly, fix it yourself and publish it"
			error 149
			}
		mac shift 1
	}


	*Call kappa and get midpoints
	qui  kap `varlist' `options'

	scalar `rkappa' = `r(kappa)'
	scalar `rprop_e'=`r(prop_e)'
	scalar `rprop_o'=`r(prop_o)'
	scalar `rN'=`r(N)'
	scalar `rse'=`r(se)'
	scalar `rz'=`r(z)'


	*Extract table data 
	qui tab2 `varlist' , matcell(`tab2x2')

	scalar `a'=`tab2x2'[1,1]
	scalar `b'=`tab2x2'[1,2]
	scalar `c'=`tab2x2'[2,1]
	scalar `d'=`tab2x2'[2,2]
	scalar `agrN'=`a'+`b'+`c'+`d'

	*Do confidence intervals for agreement
	scalar `agr'=`a' + `d'
	qui cii  `agrN' `agr'
	scalar `agrub'=`r(ub)'
	scalar `agrlb'=`r(lb)'

	*Now do confidence intervals for kappa

	*rating (1,1):
	scalar `n1'=`a'
	*rating (0,1) or (1,0):
	scalar `n2'=`b'+`c'
	*rating (0,0):
	scalar `n3'=`d'
	scalar `N'=`n1'+`n2'+`n3'

	*Let i index each subject, from 1 to the number of subjects
	*Let j index each rater, from 1 to 2

	*p (pi hat) is defined as:
	*				N			2
	*p = (1/2N) SUMMA	* SUMMA(Xij)
	*				i=1			j=1
	*
	*this is equivalent to the following: 
	scalar `p' = (1/(2*`N'))*(2*`a'+`b'+`c')


	*the 100(1-alfa level) percentile point of the chi-square distribution with 1 df.
	scalar `chi1' = invchi(1,`level')
		
	scalar `y1'=((`n2'-2*`N'*`p'*(1-`p'))^2 + 4*`N'^2*`p'^2*(1-`p')^2)/(4*`N'*`p'^2*(1-`p')^2*(`chi1'+`N')) -1
	scalar `y2'=(`n2'^2-4*`N'*`p'*(1-`p')*(1-4*`p'*(1-`p'))*`chi1') / (4*`N'*`p'^2*(1-`p')^2*(`chi1'+`N')) -1
	scalar `y3'=(`n2'+(1-2*`p'*(1-`p'))*`chi1')/(`p'*(1-`p')*(`chi1'+`N')) - 1

	scalar `V'=(1/27)*`y3'^3-(1/6)*(`y2'*`y3'-3*`y1')
	scalar `W'=( (1/9)*`y3'^2-(1/3)*`y2')^(3/2)

	scalar `theta'=acos(`V'/`W')

	scalar `kappal' = sqrt((1/9)*`y3'^2)*( cos((`theta'+2*_pi)/3) + sqrt(3)*sin((`theta'+2*_pi)/3)) - (1/3)*`y3'
	scalar `kappau'=2*sqrt((1/9)*`y3'^2-(1/3)*`y2')*( cos((`theta'+5*_pi)/3)) - (1/3)*`y3'


	noisily di in gr _col(2) "Expected" _n _col(2) "Agreement" _col(12)  "Agreement "  _col(22) "[" %2.0f (1-`level')*100  "% conf.interval]" _col(42) "Kappa   " _col(50) "[" %2.0f (1-`level')*100  "% conf.interval]" _n _dup(65) "-"
	noisily di _col(2) %5.2f `rprop_e'*100 "%" _col(12) %4.2f `rprop_o'*100 "%" _col(22) "[" %4.2f `agrlb'*100 %12.2f `agrub'*100 "]" _col(42) %6.3f `rkappa'  _col(50) "["  %4.3f `kappal' %12.3f `kappau' "]   " %12.4f 

 
	*return the stuff we stole from kap.ado
	*return values from kappa
	return scalar  kappa=`rkappa'
	return scalar prop_e=`rprop_e'
	return scalar prop_o=`rprop_o'
	return scalar N=`rN'
	return scalar se=`rse'
	return scalar z=`rz'
	*return the stuff we computed
	return scalar goflb=`kappal'
	return scalar gofub=`kappau'
	return scalar agrub=`agrub'
	return scalar agrlb=`agrlb'
end


