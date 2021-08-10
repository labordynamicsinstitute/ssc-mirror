* Parametric likelihood definition for Waiting Time Distribution
* with Exponential FRD and Uniform h, no censoring
* Henrik Støvring, Dec 2001
* Updated and simplified with invlogit, HS Aug 30, 2016

program define mlwtd_exp
        version 14.0
	args lnf logitp lnbeta 

qui{
        replace `lnf' = ln(invlogit(`logitp') * exp(`lnbeta') ///
                           * exp(- exp(`lnbeta') * $ML_y1) + /*
                              */ invlogit(-`logitp') / $wtddelta)
      }
end
