*! version 1.0.0 August 14, 2026
*! Ben A. Dwamena: bdwamena@umich.edu
*! midas_d0 : d0 likelihood evaluator for the bivariate mixed-effects
*! logistic model estimated by maximum simulated likelihood.
*! Called by -midas qrsim- via ml model derivative0.
cap prog drop midas_d0
program define midas_d0
  args todo b lnf
  tempvar eta1 eta2 random1 random2 lj pi1 pi2 sum lnpi L xlast
  tempname lnsig1 lnsig2 corr12 sigma1 sigma2 cov12
  mleval `eta1'   = `b', eq(1)
  mleval `eta2'   = `b', eq(2)
  mleval `lnsig1'  = `b', eq(3) scalar
  mleval `lnsig2'  = `b', eq(4) scalar
  mleval `corr12' = `b', eq(5) scalar
  scalar `sigma1'=(exp(`lnsig1'))^2
  scalar `sigma2'=(exp(`lnsig2'))^2
  scalar `cov12'=[exp(2*`corr12')-1]/[exp(2*`corr12')+1]*(exp(`lnsig2'))*(exp(`lnsig1'))

  bysort __midas_studyid : gen byte `xlast'=(_n==_N)

  gen double `random1' = 0
  gen double `random2' = 0
  gen double `lnpi'=0
  gen double `sum'=0
  gen double `L'=0

  gen double `pi1'= 0
  gen double `pi2'= 0
  matrix W = (`sigma1' , `cov12' \ `cov12' , `sigma2')
  capture matrix L=cholesky(W)

	local l11=L[1,1]
	local l12=L[2,1]
	local l22=L[2,2]

	qui {
	forvalues r = 1/${draws}  {
	replace `random1' = random1`r'*`l11'
	replace `random2' = random2`r'*`l22'+ random1`r'*`l12'
	replace `pi1' =invlogit(`eta1' + `random1')
	replace `pi2'= invlogit(`eta2' + `random2')
	replace `lnpi'= cond(__midas_dtruth == 1, ///
	(__midas_dep*ln(`pi1' ))+((__midas_denom-__midas_dep)*ln(1-`pi1')), ///
	(__midas_dep*ln(`pi2' ))+((__midas_denom-__midas_dep)*ln(1-`pi2')))
	by __midas_studyid : replace `sum'= sum(`lnpi')
	by __midas_studyid : replace `L' = `L' + exp(`sum') if `xlast'
	}
	}
	mlsum `lnf' = ln(`L'/${draws}) if `xlast'

	if (`todo'==0|`lnf'>.) exit

	end
