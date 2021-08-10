*! version 2.1  Thursday, July 3, 2003 at 12:20

program define _mi_RUBIN
    version 7
    args nparam inputfile outfile level

/* NB: inputfile for _mi_RUBIN is a long-form dataset containing
      the following variables:
              parm dumyid tt obs est se lb ub
      where:
      dumyid is the i variable indexing the parameters being estimated,
      parm contains names of the parameters,
      tt is the j variable, indicating which imputed dataset the estimate
      comes from. Other vars are:
      obs = no. of valid observations used for that estimate
      est = estimate
      se = std error
      lb = lower bound of CI
      ub = upper bound of CI.
      Variables must have these exact names.

      Output file reshapes the input to wide form. In addition,
      8 new variables are created:
              avest (average of est1, est2,...)
              totalv (total variance of avest, as in Rubin87)
              milb (overall lower CI bound, as in Rubin87)
              miub (overall upper CI bound, as in Rubin87)
              miobs (= min of obs1,obs2,...),
              midof (MI degrees of freedom),
              RIV (relative increase in variance, as in Rubin87).
*/

    qui use `inputfile', clear
    tempvar v
    tempfile abit
    gen `v' = se^2
        qui reshape wide est se `v' obs lb ub , i(dumyid) j(tt)
        sort dumyid
        qui save `abit'

/* Combine */
        use `inputfile', clear
        gen `v' = se^2
        tempname memhold
        tempfile results
        postfile `memhold' dumyid avest totalv midof /*
            */ milb miub riv using `results'

        forvalues i=1/`nparam' {
            qui sum est if dumyid == `i'
            local avest = r(mean)
            local between = r(Var)
            qui sum `v' if dumyid == `i'
            local m=r(N)
            local within = r(mean)
            local totalv = `within' + ( 1 + 1/`m' )*`between'
            if `between'==0 {
                global mi_combine3 F
            }
            if `between'<=0 {
                local dof .
                local ii=`i'*$mimps
                local lb=lb in `ii'
                local ub=ub in `ii'
                local riv=0
            }
            else {
                local dof = ( 1 + 1/`m' )*`between'
                local riv = `dof'/`within'
                local dof = (`m'-1)*(1 + 1/`riv')^2
                if `dof'>1e+10 { local dof=1e+10 }
                local invt = invttail(`dof', (1-`level'/100)/2)
                local lb = `avest' - `invt' * sqrt(`totalv')
                local ub = `avest' + `invt' * sqrt(`totalv')
            }
            post  `memhold' (`i') (`avest')/*
                */ (`totalv') (`dof') (`lb') (`ub') (`riv')
        }
        postclose `memhold'

/* Merge back individual results */

           qui use "`results'",clear
           qui sort dumyid
           qui merge dumyid using `abit'

           keep parm est* se* lb* ub* avest totalv mi* obs*  riv
           order parm avest totalv mi*  riv
           qui compress

           qui save `outfile', replace


end
/*
   _mi_RUBIN calculates overall point estimates and overall
   variance using Rubin's combining rule (Rubin 1987).

   Let est1,..., estm and v1,...,vm be points & variance estimates using
   m imputed datasets. Rubin's within-imputation variance is the average
   of v1, ..., vm, denoted by W. The between-imputation variance, B, is
   the variance of est1,..., estm. The total variance is defined by
       T = W + ( 1 + 1/m )B
   T^{-1/2}(est-avest)T^{1/2} approx ~ t_df
   where df = (m-1){ 1 + W/[(1+1/m)B] }^2.

   (1+1/m)B/W is relative increase in variance due to non-response.

   This program takes a data file as input. This data file should be in the form
            parm  tt  est    se  obs  dumyid  tt  lb   ub
             y1      1.1    0.1  500       1   1   0    0
             y1      1.0    0.1  500       1   2   0    0
             y1      0.9   0.12  500       1   3   0    0
             y2      3.2   0.01  500       2   1   0    0
             y2      3.1   0.02  500       2   2   0    0
             y2      3.0   0.00  501       2   3   0    0

    The output file is of the form:
    parm  avest  totalv   midof   milb  miub  riv   est1  se1  obs1 lb1 ub1  ...  ub5
      y1    .28     .03 31307.9   -.07   .63  .01    .30  .18   600   0   0  ...    0
      y2  -4.94     .69  2595.8  -6.57 -3.35  .04  -5.09  .85   600   0   0  ...    0

  Call : _mi_unique.ado
*/
