*! version 1.1  Thursday, July 3, 2003 at 12:23    (SJ3-3: st0000)
*
* This program implements the algorithm for the multivariate Wald test
* as described in Li, K., T. Raghunathan, and D. Rubin. 1991

program define mitestparm
    version 8
    syntax varlist
    capture assert "$mimps"~=""&"$mi_sf"~=""
    if _rc {
        display as error "please set up your data with -{help miset}- first"
        exit 198
    }

    local m = $mimps

    forvalues t=1/`m' {
        matrix _b`t' = e(b_`t')
        matrix _V`t' = e(V_`t')
    }

    tokenize `varlist'
    * find column numbers (and hence row numbers by symmetry) for each var in `varlist'
    local k = 0
    while "`1'"~="" {
        local k = `k'+1
        local var`k' = colnumb(_b1,"`1'")
        mac shift
    }

    * build new coefficient vectors, b`t', containing just the elements corresponding to vars in `varlist'
    forvalues t=1/`m' {
        matrix b`t' = J(1,`k',0)
        forvalues j=1/`k' {
            matrix b`t'[1,`j']= _b`t'[1,`var`j'']
        }
    }

    * similarly build new variance-covariance matrices, V`t'
    forvalues t=1/`m' {
        matrix V`t' = J(`k',`k',0)
        forvalues i=1/`k' {
            forvalues j=1/`k' {
                matrix V`t'[`i',`j']= _V`t'[`var`i'',`var`j'']
            }
        }
    }

    * calculate average of coefficient vectors
    matrix matsum = J(1,`k',0) /*set `matsum' to 1xk zero matrix*/
    forvalues t=1/`m' {
        matrix matsum = matsum + b`t'
    }
    matrix Qbar = 1/`m' * matsum

    * calculate within imputation variance, Ubar
    matrix matsum = J(`k',`k',0) /*set `matsum' to kxk zero matrix*/
    forvalues t=1/`m' {
        matrix matsum = matsum + V`t'
    }
    matrix Ubar = 1/`m' * matsum

    * calculate between imputation variance, B
    matrix matsum = J(`k',`k',0) /*set `matsum' to kxk zero matrix*/
    forvalues t=1/`m' {
        matrix matsum = matsum + (b`t'-Qbar)'*(b`t'-Qbar)
    }
    matrix B = 1/(`m'-1) * matsum

    * calculate total variance estimate, Ttilde
    matrix Ubarinv = inv(Ubar)
    matrix B_Ubarinv = B * Ubarinv
    local r = 1/(`m'-1) * trace(B_Ubarinv)/`k'
    matrix Ttilde = (1-`r') * Ubar

    * calculate test statistic, dee
    matrix Q_0 = J(1,`k',0)
    matrix Qdiff = Qbar-Q_0
    matrix Ttildeinv = inv(Ttilde)
    matrix D = Qdiff * Ttildeinv * Qdiff'/`k'
    local dee = trace(D)

    * calculate approximation for degrees of freedom, df
    local a = `k'*(`m'-1)
    if `a'>4 {
        local df = 4 + (`a'-4)*(1+(1- 2/`a')/`r')^2
    }
    else {
        local df = `a'*(1+1/`k')*(1+1/`r')^2/2
    }

    * calculate p-value from F distribution
    local p = Ftail(`k',`df',`dee')

    * display results
    di
    tokenize `varlist'
    forvalues i=1/`k' {
        di as txt " ( `i')" as res "  `1' = 0"
        mac shift
    }
    di
    di as txt "       F(" %3.0f `k' "," %6.0f `df' ") =" as res %8.2f `dee'
            di as txt _col(13) "Prob > F =" as res %10.4f `p'
end
