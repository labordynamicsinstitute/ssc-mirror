*! version 1.0.0  15nov2023
program wgtdistrim
    
    version 16.1
    
    syntax varname(numeric) [ if ] [ in ] ///
    , Generate(namelist max=2)            ///
      UPper(real)                         ///
    [                                     ///
        LOwer(real 0)                     ///
        ITERate(integer 10)               ///
        TOLerance(real 0)                 ///
        NORMalize                         ///
    ]
    
    marksample touse
    
    local wgtvar : copy local varlist
    
    typlist_and_varlist_of `generate'
    
    /*
        We now have local macros
        
            wgtvar  <varname> holding untrimmed weights
            typlist  type of new variable from generate(), e.g., float
            varlist  name of new variable from generate()
    */
    
    if ( (`upper'<0) | (`upper'>=1) ) ///
        option_invalid upper() 125
    
    if ( (`lower'<0) | (`lower'>=1) ) ///
        option_invalid lower() 125
    
    if (`iterate' < 1) ///
        option_invalid iterate() 125
    
    if (`tolerance' < 0) ///
        option_invalid tolerance() 125
    
    mata : wgtdistrim(                ///
        st_local("wgtvar"),           ///
        st_local("touse"),            ///
        (`lower', 1-`upper'),         ///
        `iterate',                    ///
        `tolerance',                  ///
        ("`normalize'"=="normalize"), ///
        st_local("typlist"),          ///
        st_local("varlist")           ///
        )
    
end


program typlist_and_varlist_of
    
    capture noisily syntax newvarname(numeric)
    if ( _rc ) ///
        option_invalid generate() _rc
    
    if ("`varlist'" == "") ///
        option_invalid generate() 102
    
    c_local typlist : copy local typlist
    c_local varlist : copy local varlist
    
end


program option_invalid
    
    args option rc
    
    display as err "option `option' invalid"
    exit `rc'
    
end


/*  _________________________________________________________________________
                                                                     Mata  */

version 16.1


mata :


mata set matastrict   on
mata set mataoptimize on


void wgtdistrim(
    
    string scalar    wgtvar,
    string scalar    touse,
    real   rowvector lower_upper,
    real   scalar    iter,
    real   scalar    tolerance,
    real   scalar    normalize,
    string scalar    typlist,
    string scalar    varlist
    
    )
{
    real colvector w_kt
    real scalar    n
    real scalar    i
    
    
    w_kt = st_data(., wgtvar, touse)
    n    = rows(w_kt)
    
    confirm_sampling_weights(w_kt, n)
    
    summarize_iteration(0, minmax(w_kt), .)
    
    for (i=1; i<=iter; i++) {
        
        if (mreldif_w_kt(w_kt,n,lower_upper,i) <= tolerance)
            break
        
    }
    
    if ( normalize ) {
        
        w_kt = w_kt:/mean(w_kt)
        summarize_iteration(min((i,iter)), minmax(w_kt), .)
        
    }
    
    st_store(., st_addvar(typlist,varlist), touse, w_kt)
}


real scalar mreldif_w_kt(
    
    real colvector w_kt,
    real scalar    n,
    real rowvector lower_upper,
    real scalar    iteration
    
    )
{
    real scalar    w_bar
    real scalar    s2
    real scalar    alpha
    real scalar    beta
    real rowvector w_op
    real scalar    mreldif
    
    
    w_bar = mean(w_kt)
    s2    = quadvariance(w_kt)
    /*
        (6) in Potter (1990, 227) uses the population variance
        method of moments estimator, dividing by n, not (n-1)
        
    s2    = quadcolsum((w_kt:-w_bar):^2 / n)
    */
    
    alpha = (w_bar*(n*w_bar-1) / (n*s2)) + 2
    beta  = (n*w_bar-1)*(alpha-1)
    
    w_op = 1:/(n*invibetatail(alpha,beta,lower_upper))
    
    mreldif = trim_weights(w_kt, w_op)
    
    summarize_iteration(iteration, minmax(w_kt), mreldif)
    
    return(mreldif)
}


real scalar trim_weights(
    
    real colvector w_kt,
    real rowvector w_op
    
    )
{
    real matrix    kappa
    real scalar    gamma
    real colvector w_was
    
    
    /*
        The notation below follows Chen et al. (2017, 232)
    */
    
    kappa = (w_kt:<=w_op[1], w_kt:>=w_op[2])
    
    if ( !any(kappa) )
        return(0)
    
    w_was = w_kt
    
    gamma = (
        (quadcolsum(w_kt)-quadsum(kappa:*w_op)) 
        / 
        quadcolsum((1:-rowsum(kappa)):*w_kt)
        )
    
    w_kt = gamma:*w_kt
    
    if ( any(kappa[,1]) )
        w_kt[selectindex(kappa[,1])] = J(colsum(kappa[,1]),1,w_op[1])
    
    if ( any(kappa[,2] ) )
        w_kt[selectindex(kappa[,2])] = J(colsum(kappa[,2]),1,w_op[2])
    
    return( mreldif(w_kt,w_was) )
}


void summarize_iteration(
    
    real scalar    iteration,
    real rowvector min_max,
    real scalar    mreldif
    
    )
{
    printf("{txt}Iteration %f:", iteration)
    printf("{col 20}{txt}min = {res}%9.0g", min_max[1])
    printf("{col 40}{txt}max = {res}%9.0g", min_max[2])
    printf("{col 60}{txt}rel. diff = {res}%9.0g", mreldif)
    printf("\n")
}


void confirm_sampling_weights(
    
    real colvector w_kt,
    real scalar    n
    
    )
{
    if (n < 2)
        exit(error(2000+n)) // insufficient observations
    
    /*
        Potter (1990, 227)
        
            f(w) = n (1/nw)^(a+1)*(1 - 1/nw)^(b-1) / B(a,b)
            
                for 1/n <= w <= .
    */
    
    if ( !all((1/n):<=w_kt) ) {
        
        errprintf("weights must be greater than %f\n", 1/n)
        exit(any(w_kt:<0) ? 402 : 459)
        
    }
    
    if ( any(w_kt:<1) )
        printf("{txt}note: weights less than 1 encountered\n\n")
}


end


exit


/*  _________________________________________________________________________
                                                              version history

1.0.0   15nov2023   release on public GitHub repository
0.5.0   14nov2023   option upper() required; no default
                    minor refactoring
0.4.0   14nov2023   defaults upper(.01) lower(0)
                    use (unbiased) sample variance 
                    no longer allow zero weights
                    more informative error message for generate()
0.3.0   14nov2023   specify separate trimming levels for upper and lower bound
0.2.0   11nov2023   trim large weights from upper tail only
                    warning for sampling weights < 1
0.1.0   10nov2023   upload to private GitHub repository
