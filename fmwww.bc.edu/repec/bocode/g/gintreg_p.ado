program define gintreg_p
        syntax newvarname [if] [in] [, noOFFset]

        if ("`e(cmd)'"!="gintreg") {
                di as err "gintreg was not the last estimation command"
                exit 301
        }
        
        marksample doit, novarlist
        
        local dist     "`e(distribution)'"
        local auxnames "`e(auxnames)'"
        
        // symmetric distributions
        if inlist("`dist'","","normal","ged","laplace","gt","t") {
                _predict `typlist' `varlist' if `doit', xb `offset'
                exit
        }
        
        // possibly asymmetric distributions
        foreach eqn in model `auxnames' {
                tempvar X`eqn'
                qui _predict double `X`eqn'' if `doit', xb eq(`eqn') `offset'
        }
        tempvar Xsigma
        qui gen double `Xsigma' = exp(`Xlnsigma') if `doit'
        replace `Xlambda' = tanh(`Xlambda')
        
        tempvar predicted
        if inlist("`dist'","snormal","laplace","slaplace","ged","sged") {
                qui gen `predicted' = `Xmodel'+2*`Xlambda'*`Xsigma'           /*
                */ *(exp(lngamma(2/`Xp'))/exp(lngamma(1/`Xp')))        if `doit'
        }
        else if inlist("`dist'","t","gt","st","sgt") {
                qui gen `predicted' = `Xmodel'+2*`Xlambda'*`Xsigma'           /*
                */ *((`Xq'^(1/`Xp'))*(exp(lngamma(2/`Xp')+lngamma(`Xq'        /*
                */ -(1/`Xp'))-lngamma((1/`Xp')+`Xq'))/exp(lngamma(1/`Xp')     /*
                */ +lngamma(`Xq'))-lngamma((1/`Xp')+`Xq')))            if `doit'
        }
        else if inlist("`dist'","lognormal","lnormal") {
                qui gen `predicted' = exp(`Xmodel'+(`Xsigma'^2/2))     if `doit'
        }
        else if inlist("`dist'","weibull","gamma","ggamma") {
                qui gen `predicted' = exp(`Xmodel')                           /*
                */ *[exp(lngamma(`Xp'+`Xsigma'))/(exp(lngamma(`Xp')))] if `doit'
        }
        else if inlist("`dist'","br3","dagum","br12","sm","gb2") {
                qui gen `predicted' = exp(`Xmodel')                           /*
                */ *[exp(lngamma(`Xp'+`Xsigma'))*exp(lngamma(`Xq'-`Xsigma'))  /*
                */ /(exp(lngamma(`Xp'))*exp(lngamma(`Xq')))]           if `doit'
        }
        gen `typlist' `varlist' = `predicted' if `doit'
end