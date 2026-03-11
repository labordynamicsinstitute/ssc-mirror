*! _fcoint_cv_fadl.ado -- FADL critical value dispatcher
program define _fcoint_cv_fadl, rclass
  syntax, n(integer) k(integer) tobs(integer) model(string) [cumfreq]
  if "`cumfreq'" != "" {
    _fcoint_cv_fadl_cumul, n(`n') q(`k') tobs(`tobs') model(`model')
  }
  else {
    _fcoint_cv_fadl_single, n(`n') k(`k') tobs(`tobs') model(`model')
  }
  return scalar cv1  = r(cv1)
  return scalar cv5  = r(cv5)
  return scalar cv10 = r(cv10)
end
