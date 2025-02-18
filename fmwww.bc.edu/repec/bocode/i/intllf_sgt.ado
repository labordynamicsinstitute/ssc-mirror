program intllf_sgt
version 13
        args lnf mu sigma p q lambda

        local y1  "$ML_y1"
        local y2  "$ML_y2"
        local idx "$ML_y3"
        local cond 0.75
        
        * Intermediate values: pdf@y1
        tempvar xl xu v m
        qui gen double `xl' = `y1'-`mu'                 if inlist(`idx',1,3,4)
        qui gen double `xu' = `y2'-`mu'                 if inlist(`idx',2,4)
        
        qui gen double `v' = (`q'^(-1/`p')) / [(3*(tanh(`lambda')^2)+1)       /*
        */ *(exp(lngamma(3/`p')+lngamma(`q'-2/`p')-lngamma(3/`p'+`q'-2/`p'))  /*
        */ /exp(lngamma(1/`p')+lngamma(`q')-lngamma(1/`p'+`q')))              /*
        */ -4*(tanh(`lambda')^2)*((exp(lngamma(2/`p')+lngamma(`q'-1/`p')      /*
        */ -lngamma(2/`p'+`q'-1/`p')))^(2)/((exp(lngamma(1/`p')+lngamma(`q')  /*
        */ -lngamma(1/`p'+`q')))^2))]^(1/2)                       if (`idx'==1)
        
        qui gen double `m' = (2*`v'*exp(`sigma')*tanh(`lambda')*`q'^(1/`p')   /*
        */ *exp(lngamma(2/`p')+lngamma(`q'-1/`p')-lngamma(2/`p'+`q'-1/`p')))  /*
        */ /(exp(lngamma(1/`p')+lngamma(`q')-lngamma(1/`p'+`q'))) if (`idx'==1)

        * Intermediate values: cdf@y1, cdf@y2 
        tempvar zl zu Fl Fu
        
        qui gen double `zl' = 1 /*
        */ / [1+`q'*((exp(`sigma')*(1+tanh(`lambda')*sign(`xl')))/(abs(`xl')))^`p'] /*
        */                                              if inlist(`idx',3,4)
        
        qui gen double `zu' = 1 /*
        */ / [1+`q'*((exp(`sigma')*(1+tanh(`lambda')*sign(`xu')))/(abs(`xu')))^`p'] /*
        */                                              if inlist(`idx',2,4)
        
        qui gen double `Fl' = .5*(1-tanh(`lambda'))                           /*
        */ + .5*(1+tanh(`lambda')*sign(`xl'))*sign(`xl')*cond(`zl'<=`cond',   /*
        */ ibeta(1/`p',`q',`zl'), 1-ibeta(`q',1/`p',1-`zl'))                  /*
        */                                              if inlist(`idx',3,4)
        
        qui gen double `Fu' = .5*(1-tanh(`lambda'))                           /*
        */ + .5*(1+tanh(`lambda')*sign(`xu'))*sign(`xu')*cond(`zu'<=`cond',   /*
        */ ibeta(1/`p',`q',`zu'), 1-ibeta(`q',1/`p',1-`zu'))                  /*
        */                                              if inlist(`idx',2,4)
        
        * Fill in log likelihood values 
        qui replace `lnf' = ln(`p')-ln(2)-ln(`v')-ln(exp(`sigma'))-(1/`p')    /*
        */ *ln(`q')-(lngamma(1/`p')+lngamma(`q')-lngamma(1/`p'+`q'))          /*
        */ -(1/`p'+`q')*ln((((abs(`xl'+`m'))^(`p'))/(`q'*(`v'*exp(`sigma'))   /*
        */ ^(`p')*(tanh(`lambda')*sign(`xl'+`m')+1)^(`p')))+1)                /*
        */                                if (`idx'==1) // uncensored
        qui replace `lnf' = ln(`Fu')      if (`idx'==2) // left censored
	qui replace `lnf' = ln(1-`Fl')    if (`idx'==3) // right censored
	qui replace `lnf' = ln(`Fu'-`Fl') if (`idx'==4) // interval 
end