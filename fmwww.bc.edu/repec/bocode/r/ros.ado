* TODO add empirical percentiles 
program define ros, rclass
  version 12
  syntax varlist(max=1 numeric) [if], Censor(varname numeric) /*
  */[ /*
    */noQuietly /*
    */Percentiles(numlist >0 <100 sort) /*
    */SCatter /*
    */RSqrtheta /*
    */Theta(real 1) /*
    */Start(real 0) /*
    */STep(real 0.25) /*
    */End(real 2) /*
    */ * /* Twoway graph options for scatter
  */]
  quietly su `varlist'
  if r(min) <= 0 mata: _error("Only positive values for the measurements")
  if "`percentiles'" == "" local percentiles 50 75 90 95 97.5 99
  local xlbl `"`: var l `varlist''"'
  if "`xlbl'" == "" local xlbl "`varlist'"
  if `theta' == 0 local xlbl log(`xlbl')
  else if `theta' != 1 local xlbl (`xlbl'){sup: `=string(`theta', "%5.3f")'}
  
  tempvar yraw zraw
  genrawvars `varlist' `censor', g(`yraw' `zraw') t(`theta')
  
  criterias `yraw' `zraw' `if'
  display "Adjusted Rsquared is " %6.4f r(r2_a)

  scalar rosmean = r(rosmean)
  scalar rossd = r(rossd)
  scalar r2_a = r(r2_a)
  scalar AIC = r(AIC)
  scalar BIC = r(BIC)
  
  if "`scatter'" != "" {
    local ylbl 
    local np : word count `percentiles'
    forvalues j = 1/`np' {
      local p : word `j' of `percentiles'
      local z = invnormal(`p' * 0.01)
      local ylbl `ylbl' `z' "z{sub:`p'%}"
    }
    local lb = `=rosmean' - 3 * `=rossd' 
    local ub = `=rosmean' + 3 * `=rossd' 
    twoway ///
      (scatter `zraw' `yraw', jitter(3)) ///
      (function y = (x - `=rosmean') / `=rossd' , range(`lb' `ub')) ///
      , legend(off) ytitle(Normal quantiles) xtitle(`"`xlbl'"') ///
      ylabel(`ylbl' -3(1)-1 3, format(%2.0f) glwidth(vthin) glcolor(gs12) glpattern(dash)) ///
      subtitle(`"R{sub:adj}{sup:2} = `=string(e(r2_a), "%6.4f")', theta = `=string(`theta', "%5.3f")'"', ring(0) position(5)) ///
      note(`"`title'"') name(`varlist'_scatter, replace) `options'
  }
  
  predictions `varlist', p(`percentiles')  t(`theta') m(`=rosmean') sd(`=rossd')
  matrix ros = r(ros)
  mata: st_local("nrowssep", (rows(st_matrix("ros")) - 1) * "&")
  matlist ros, cspec(& %20s & %12.2f & %12.2f &) rspec(||`nrowssep'|)
  
  R2_theta `varlist' `censor' `if', start(`start') step(`step') stop(`end')
  matrix rsqrtheta = r(rsqrtheta)
  matrix rsqrtheta = rsqrtheta[1..., 1],  rsqrtheta[1..., 4],  rsqrtheta[1..., 5]
  mata: rsqrtheta = st_matrix("rsqrtheta")[., 1..2]
  mata: st_local("nrowssep", (rows(rsqrtheta) - 1) * "&")
  matlist rsqrtheta, names(columns) underscore ///
    cspec(& %12.3f & %12.3f & %10.0f &) rspec(||`nrowssep'|)
  if "`rsqrtheta'" != "" {
	matrix _tmp = rsqrtheta
	svmat double _tmp
    twoway line _tmp1 _tmp2, ytitle(R{sub:adj}{sup:2}) ///
      name(`y'_R2_theta, replace) ylabel(, format(%5.3f)) xmtick(##2, grid) ///
      xlabel(`start'(`step')`end', format(%4.2f) ///
      glwidth(medium) glcolor(gs4) glpattern(dot)) ///
	  xtitle(theta) ytitle(Rsquared)
	drop _tmp?
	/*
    twoway line matamatrix(rsqrtheta) Rsquared theta, ytitle(R{sub:adj}{sup:2}) ///
      name(`y'_R2_theta, replace) ylabel(, format(%5.3f)) xmtick(##2, grid) ///
      xlabel(`start'(`step')`end', format(%4.2f) ///
      glwidth(medium) glcolor(gs4) glpattern(dot))
	*/
    }
  return matrix rsqrtheta = rsqrtheta

  if "`quietly'" != "" {
      generate _ros_z = `zraw' `if'
      generate _ros_y_trans = `yraw' `if'   
  }
  return scalar rosmean = rosmean
  return scalar rossd = rossd
  return scalar r2_a = r2_a
*  return scalar AIC = AIC
*  return scalar BIC = BIC
  return matrix ros = ros
end

program define genrawvars, sortpreserve rclass
  syntax varlist(min=2 max=2 numeric), Generate(namelist min=2 max=2) Theta(real)
  tokenize "`varlist'"
  local y `1'
  local c `2'
  sort `y'
  tokenize "`generate'"
  qui generate `2' = invnorm(_n / (_N + 1))
  quietly replace `2' = . if `c' != 0
  label variable `2' "Normal zvalues"
  qui generate `1' = cond(`theta', `y' ^ `theta' / abs(`theta'),  log(`y'))  if !mi(`2')
  label variable `1' "Transformed y values"
end

program define criterias, rclass
  syntax varlist(min=2 max=2) [if]
  quietly regress `varlist' `if'
  tokenize "`varlist'"
  return scalar rosmean = _b[_cons]
  return scalar rossd = _b[`2']
  return scalar r2_a = e(r2_a)
  quietly estat ic
  matrix S = r(S)
  return scalar AIC = (S[1,5])
  return scalar BIC = (S[1,6])
end

program define predictions, rclass
  syntax varlist(max=1 numeric), Percentiles(numlist >0 <100 sort) Mean(real) SD(real) Theta(real)
  local rnms
  local np : word count `percentiles'
  capture matrix drop ros
  forvalues j = 1/`np' {
    local p : word `j' of `percentiles'
    local rnms `rnms' P`p'%
    local z = invnormal(`p' * 0.01)
    scalar yhat = `mean' + `z' * `sd'
    scalar yhat = cond(`theta', ( abs(`theta') * yhat )^ (1 / `theta'), exp(yhat))
    qui centile `varlist', centile(`p')
    matrix ros = nullmat(ros) \ (yhat, r(c_1))
  }
  matrix roweq ros = `"theta(`=string(`theta', "%5.3f")')"'
  matrix rownames ros = `rnms'
  matrix colnames ros = Estimate Empirical
  return matrix ros = ros    
end

program define R2_theta, rclass
  syntax varlist(min=2 max=2) [if], [start(real 0) step(real 0.25) stop(real 2)]
  tokenize "`varlist'"
  
  mata: out = J(0,4,.)
  forvalues val = `start'(`step')`stop' {
    tempvar y z
    genrawvars `varlist', g(`y' `z') t(`val')
    criterias `y' `z' `if'
    mata: out = out \ `r(r2_a)', `r(AIC)', `r(BIC)', `val'
  }
  mata: optimal = out[.,1] :== colmax(out[.,1])
  mata: st_matrix("rsqrtheta", (out[., 1..4], optimal :/ optimal))
  matrix colnames rsqrtheta = R2_adj AIC BIC theta optimal
  mata: out = out[., (1,4)]
  return matrix rsqrtheta = rsqrtheta
end
