program intllf_ggamma
version 13
        args lnf delta lnsigma p

        tempvar sigma x zl zu Fl Fu
        local y1  "$ML_y1"
        local y2  "$ML_y2"
        local idx "$ML_y3"
                
        qui gen double `sigma' = exp(`lnsigma')
        qui gen double `x' = [ln(`y1')-`delta']/`sigma'
        qui gen double `zl' = (`y1'/exp(`delta'))^(1/`sigma') if inlist(`idx',3,4)
        qui gen double `zu' = (`y2'/exp(`delta'))^(1/`sigma') if inlist(`idx',2,4)
        
        * Intermediate values: cdf@y1, cdf@y2 
        qui gen double `Fl' = gammap(`p',`zl') if inlist(`idx',3,4)
        qui gen double `Fu' = gammap(`p',`zu') if inlist(`idx',2,4)
        
        * Fill in log likelihood values 
        qui replace `lnf' = `p'*`x'-`lnsigma'-ln(`y1')-lngamma(`p')-exp(`x')  /*
        */                                if (`idx'==1) // uncensored
        qui replace `lnf' = ln(`Fu')      if (`idx'==2) // left censored
	qui replace `lnf' = ln(1-`Fl')    if (`idx'==3) // right censored
	qui replace `lnf' = ln(`Fu'-`Fl') if (`idx'==4) // interval    
end