program intllf_lognormal
version 13
        args lnf mu lnsigma
        
        local y1  "$ML_y1"
	local y2  "$ML_y2"
	local idx "$ML_y3"
        
        tempvar Fu Fl  
        qui gen double `Fu' = .
        qui gen double `Fl' = .
        
	* Intermediate values: pdf@y1, cdf@y1, cdf@y2
	tempvar f Fu Fl
	qui gen double `f' = normalden(ln(`y1'),`mu',exp(`lnsigma'))*(1/`y1') /*
        */                                                      if (`idx'==1)
	qui gen double `Fl' = normal((ln(`y1')-`mu')/exp(`lnsigma'))          /*
        */                                              if inlist(`idx', 3, 4)
	qui gen double `Fu' = normal((ln(`y2')-`mu')/exp(`lnsigma'))          /*
        */                                              if inlist(`idx', 2, 4)

	* Fill in log likelihood values
	qui replace `lnf' = ln(`f')       if (`idx'==1) // uncensored
	qui replace `lnf' = ln(`Fu')      if (`idx'==2) // left censored
	qui replace `lnf' = ln(1-`Fl')    if (`idx'==3) // right censored
	qui replace `lnf' = ln(`Fu'-`Fl') if (`idx'==4) // interval
end 