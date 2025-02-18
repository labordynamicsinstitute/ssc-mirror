program intllf_sged
version 13
        args lnf mu lnsigma p lambda

        tempvar xl xu zl zu Fl Fu s l
        local y1  "$ML_y1"
        local y2  "$ML_y2"
        local idx "$ML_y3"
        
        * Intermediate values: cdf@y1, cdf@y2 
        qui gen double `xl' = `y1'-`mu'                 if inlist(`idx',1,3,4)
        qui gen double `xu' = `y2'-`mu'                 if inlist(`idx',2,4)
        
        qui gen double `zl' = abs(`xl')^`p'                                 /*
        */ / [exp(`lnsigma')^`p' * (1+tanh(`lambda')*sign(`xl'))^`p']       /*
        */                                              if inlist(`idx',3,4)
        
        qui gen double `zu' = abs(`xu')^`p'                                 /*
        */ / [exp(`lnsigma')^`p' * (1+tanh(`lambda')*sign(`xu'))^`p']       /*
        */                                              if inlist(`idx',2,4)
        
        qui gen double `Fl' = .5*(1-tanh(`lambda'))                         /*
        */ + .5*(1+tanh(`lambda')*sign(`xl'))*sign(`xl')*gammap(1/`p',`zl') /*
        */                                              if inlist(`idx',3,4)
        
        qui gen double `Fu' = .5*(1-tanh(`lambda'))                         /*
        */ + .5*(1+tanh(`lambda')*sign(`xu'))*sign(`xu')*gammap(1/`p',`zu') /*
        */                                              if inlist(`idx',2,4) 
        
        * Intermediate values: pdf@y1
        qui gen double `s' = ln(`p')-abs(`xl')^`p'                           /*
        */ / [exp(`lnsigma')*(1+tanh(`lambda')*sign(`xl'))]^`p' if (`idx'==1)
        qui gen double `l' = ln(2)+`lnsigma'+lngamma(1/`p')    if (`idx'==1)
        
        * Fill in log likelihood values 
        qui replace `lnf' = `s'-`l'       if (`idx'==1) // uncensored
        qui replace `lnf' = ln(`Fu')      if (`idx'==2) // left censored
	qui replace `lnf' = ln(1-`Fl')    if (`idx'==3) // right censored
	qui replace `lnf' = ln(`Fu'-`Fl') if (`idx'==4) // interval    
end