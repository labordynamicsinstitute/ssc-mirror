*! version 1.0.0  25Sep2005
* Hilbe Canonical Negative binomial: log likelihood  function :Joseph Hilbe
program define jhhnb_ll
version  9.1
args lnf xb  alpha

tempvar a mu
qui gen  double `a' = exp(`alpha')
qui gen double `mu' = 1/(`a'* (exp(-`xb')-1)) *  `a'
qui replace `lnf' = $ML_y1 *  ln(`mu'/(1+`mu'))   -  ///
ln(1+`mu')/`a' +  lngamma($ML_y1 + 1/`a') -  ///
lngamma($ML_y1 + 1) -  lngamma(1/`a')

end
