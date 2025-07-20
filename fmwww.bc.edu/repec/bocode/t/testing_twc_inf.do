*author: Yannick Guyonvarch, date: July 7 2025. Version 2.

*do-file which loads twc_inf_db.dta and runs the twc_inf Stata command on these
*data. Many different examples with varying option assortments are given.

use "C:\Users\yanni\Inrae EcoPub Dropbox\Yannick Guyonvarch\Clustering with two way FE\Stata_package\twc_inf_db.dta", clear

*run the command
twc_inf Yreg X1 X2, cl(rowclust colclust) alpha(10)
twc_inf Yreg X1 X2, cl(rowclust colclust) alpha(10) method(regress)
twc_inf Yreg X1 X2 in 1/150, cl(rowclust colclust) alpha(10) method(regress)
twc_inf Yreg X1 X2, cl(rowclust colclust) alpha(10) nodofcorr
twc_inf Yreg X1 X2, cl(rowclust colclust)
twc_inf Yreg X1 X2, cl(rowclust colclust) nodofcorr
twc_inf Ybinary X1 X2, cl(rowclust colclust) alpha(10) method(logit)
twc_inf Ybinary X1 X2, cl(rowclust colclust) alpha(10) nodofcorr method(logit)
twc_inf Ybinary X1 X2, cl(rowclust colclust) method(logit)
twc_inf Ybinary X1 X2, cl(rowclust colclust) nodofcorr method(logit)
twc_inf Ybinary X1 X2, cl(rowclust colclust) alpha(10) method(probit)
twc_inf Ybinary X1 X2, cl(rowclust colclust) alpha(10) nodofcorr method(probit)
twc_inf Ybinary X1 X2, cl(rowclust colclust) method(probit)
twc_inf Ybinary X1 X2, cl(rowclust colclust) nodofcorr method(probit)
twc_inf Ypoisson X1 X2, cl(rowclust colclust) alpha(10) method(poisson)
twc_inf Ypoisson X1 X2, cl(rowclust colclust) alpha(10) nodofcorr method(poisson)
twc_inf Ypoisson X1 X2, cl(rowclust colclust) method(poisson)
twc_inf Ypoisson X1 X2, cl(rowclust colclust) nodofcorr method(poisson)

*display results stored in eclass objects
return list
matrix list r(se_vec)
matrix list r(eigenvals_Vu)
matrix list r(V1)
matrix list r(V2)
matrix list r(V12)
matrix list r(Vu)