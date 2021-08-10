* Parametric likelihood definition for Waiting Time Distribution
* with LogNormal FRD and Uniform h, no censoring
* Henrik Støvring, Dec 2001
* Updated and simplified with invlogit, HS Aug 30, 2016

program define mlwtd_lnorm
        version 14.0
	args lnf logitp mu lnsigma 

qui{
        replace `lnf' = ln(invlogit(`logitp') *                   /*
                        */ normal(-(ln($ML_y1) - `mu')/exp(`lnsigma')) /*
                        */ / exp(`mu' + exp(2 * `lnsigma')/2)  /*
                        */ + invlogit(-`logitp') / $wtddelta )
      }
end
