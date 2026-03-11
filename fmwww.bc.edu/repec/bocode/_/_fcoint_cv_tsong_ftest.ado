*! _fcoint_cv_tsong_ftest.ado -- Tsong F-test critical values
program define _fcoint_cv_tsong_ftest, rclass
  syntax, model(string)
  if "`model'" == "trend" {
    return scalar cv10 = 3.306
    return scalar cv5  = 4.019
    return scalar cv1  = 5.860
  }
  else {
    return scalar cv10 = 3.352
    return scalar cv5  = 4.066
    return scalar cv1  = 5.774
  }
end
