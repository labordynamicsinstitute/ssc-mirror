program intllf_gb2
version 13
        args lnf delta lnsigma p q

        tempvar sigma xl xu Fl Fu
        local y1  "$ML_y1"
        local y2  "$ML_y2"
        local idx "$ML_y3"
                
        qui gen double `sigma' = exp(`lnsigma')
        qui gen double `xl' = [ln(`y1')-`delta']/`sigma'
        qui gen double `xu' = [ln(`y2')-`delta']/`sigma'
        
        * Intermediate values: cdf@y1, cdf@y2 
        qui gen double `Fl' = ibeta(`p',`q',exp(`xl')/(1+exp(`xl')))          /*
        */                                              if inlist(`idx',3,4)
        
        qui gen double `Fu' = ibeta(`p',`q',exp(`xu')/(1+exp(`xu')))          /*
        */                                              if inlist(`idx',2,4)
        
        * Fill in log likelihood values 
        qui replace `lnf' = `p'*`xl'-`lnsigma'-ln(`y1')-lngamma(`p')          /*
        */ -lngamma(`q')+lngamma(`p'+`q')-(`p'+`q')*ln(1+exp(`xl'))           /*
        */                                if (`idx'==1) // uncensored
        qui replace `lnf' = ln(`Fu')      if (`idx'==2) // left censored
	qui replace `lnf' = ln(1-`Fl')    if (`idx'==3) // right censored
	qui replace `lnf' = ln(`Fu'-`Fl') if (`idx'==4) // interval    
end