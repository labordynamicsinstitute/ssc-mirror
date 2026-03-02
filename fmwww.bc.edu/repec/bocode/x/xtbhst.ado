*! xtbhst
*! Version 1.0.0
*! Bootstrap slope heterogeneity test based on Blomquist & Westerlund (2015)
*! Author: Dr Merwan Roudane
*! Email: merwanroudane920@gmail.com
*! Modified from xthst by Tore Bersvendsen and Jan Ditzen
capture program drop xtbhst
program define xtbhst, rclass sortpreserve
    syntax varlist(min=2 ts) [if] [in] , reps(integer) [ blocklength(integer -1) partial(varlist ts) NOCONStant NOOUTput seed(string) CRosssectional(string) GRaph ]
    
    version 14
    
    if "`seed'" != "" {
        set seed `seed'
    }
    
    qui {
        local lhsrhs `varlist'
        tempvar touse   
        marksample touse
        
        qui xtset
        local idvar "`r(panelvar)'"
        local tvar "`r(timevar)'"   
        sort `idvar' `tvar'
        
        *** Create cross-sectional averages if requested
        if "`crosssectional'" != "" {
            local 0 `crosssectional'
            syntax varlist(ts) , [cr_lags(numlist)]
            local crosssectional `varlist'
            tempname csa
            if "`cr_lags'" == "" {
                local cr_lags = 0
            }
            xtdcce2_csa `crosssectional' , idvar(`idvar') tvar(`tvar') cr_lags(`cr_lags') touse(`touse') csa(`csa')           
            local csa `r(varlist)'  
            local cross_structure "`r(cross_structure)'"
            markout `touse' `csa'   
        }   

        *** check for partial vars
        if "`partial'" != "" {
            local lhsrhs: list lhsrhs - partial
            tsrevar `partial'
            local partial `r(varlist)'
        }

        tsrevar `lhsrhs'
        tokenize `r(varlist)'
            
        local lhs `1'
        macro shift
        local rhs `*'
        
        if "`noconstant'" == "" {
            tempvar const
            gen double `const' = 1
            local partial `partial' `const'
        }
        
        tempname results delta_st delta_adj pval_st pval_adj blocklen delta_mat beta_mat betafe_mat
        
        mata st_matrix("`results'", xtbhst_bootstrap("`lhs'","`rhs'","`partial' `csa'","`idvar' `tvar'","`touse'", `reps', `blocklength', "`delta_mat'", "`beta_mat'", "`betafe_mat'"))
        
        scalar `delta_st'  = `results'[1,1]
        scalar `delta_adj' = `results'[1,2]
        scalar `pval_st'   = `results'[1,3]
        scalar `pval_adj'  = `results'[1,4]
        scalar `blocklen'  = `results'[1,5]
    }
    
    local partial = subinstr("`partial'","`const'","constant",.)
    if wordcount("`cr_lags'") > 1 {
        local crosssectional_output "`cross_structure'"
    }
    else {
        local crosssectional_output "`crosssectional'"
    }
    
    if "`nooutput'" == "" {
        noi disp ""
        noi disp as text "Bootstrap test for slope heterogeneity"
        noi disp as text "(Blomquist & Westerlund, 2015. Empirical Economics)"
        noi disp "H0: slope coefficients are homogenous"
        di as text "{hline 40}"
        noi disp as result _col(10) "Delta" _col(25) "BS p-value"
        noi disp as result  _col(7) %9.3f `delta_st' _col(25) %9.3f `pval_st'
        noi disp as result  _col(2) "adj." _col(7) %9.3f `delta_adj'  _col(25) %9.3f `pval_adj'
        di as text "{hline 40}"
        noi disp as txt "Bootstrap replications: `reps'"
        noi disp as txt "Block length: " `blocklen'
        if "`partial'" != "" noi disp "Variables partialled out: `partial'"
        if "`crosssectional'" != "" display  as text "Cross Sectional Averaged Variables: `crosssectional_output'"
    }
    
    if "`graph'" != "" {
        preserve
        qui drop _all
        
        tempvar d_stars coef_i
        qui svmat `delta_mat', name(`d_stars')
        qui svmat `beta_mat', name(`coef_i')
        
        local d_val = `delta_st'
        local d_adj_val = `delta_adj'
        
        * Bootstrap Distribution Plot - Delta
        twoway (histogram `d_stars'1, density fcolor(ltblue%60) lcolor(white)) ///
               (kdensity `d_stars'1, lcolor(navy) lwidth(medthick)), ///
               xline(`d_val', lcolor(cranberry) lwidth(thick) lpattern(dash)) ///
               title("Bootstrap Distr: Delta", size(medsmall) color(black)) ///
               subtitle("Observed = `: display %9.3f `d_val''", size(small) color(gs5)) ///
               xtitle("Delta") ytitle("Density") ///
               legend(off) ///
               graphregion(color(white)) scheme(s2color) name(xtbhst_bs1, replace) nodraw

        * Bootstrap Distribution Plot - Adj. Delta
        twoway (histogram `d_stars'2, density fcolor(ltblue%60) lcolor(white)) ///
               (kdensity `d_stars'2, lcolor(navy) lwidth(medthick)), ///
               xline(`d_adj_val', lcolor(cranberry) lwidth(thick) lpattern(dash)) ///
               title("Bootstrap Distr: Adj. Delta", size(medsmall) color(black)) ///
               subtitle("Observed = `: display %9.3f `d_adj_val''", size(small) color(gs5)) ///
               xtitle("Adj. Delta") ytitle("Density") ///
               legend(off) ///
               graphregion(color(white)) scheme(s2color) name(xtbhst_bs2, replace) nodraw
               
        local graphlist "xtbhst_bs1 xtbhst_bs2"
        local numvars : word count `rhs'
        
        forvalues k = 1/`numvars' {
            local vname : word `k' of `rhs'
            local fe_val = `betafe_mat'[`k',1]
            
            * Coefficient Heterogeneity Plot for variable k
            twoway (histogram `coef_i'`k', density fcolor(teal%40) lcolor(white)) ///
                   (kdensity `coef_i'`k', lcolor(teal) lwidth(medthick)), ///
                   xline(`fe_val', lcolor(cranberry) lpattern(dash) lwidth(thick)) ///
                   title("Slopes: `vname'", size(medsmall) color(black)) ///
                   xtitle("Estimate") ytitle("Density") ///
                   legend(off) ///
                   graphregion(color(white)) scheme(s2color) name(xtbhst_coef`k', replace) nodraw
                   
            local graphlist "`graphlist' xtbhst_coef`k'"
        }
               
        graph combine `graphlist', ///
            title("xtbhst - Slope Heterogeneity Visual Diagnostics", size(medium) color(black)) ///
            graphregion(color(white)) name(xtbhst_diag, replace)
            
        restore
        noi disp ""
        noi disp "Graphical diagnostic plots generated (xtbhst_diag)."
    }

    return clear
    tempname delta delta_p
    matrix `delta' = (`delta_st' \ `delta_adj')
    matrix rownames `delta' = Delta Delta_adjusted
    matrix colnames `delta' = TestStat.
    return matrix delta = `delta'
    
    matrix `delta_p' = `pval_st' \ `pval_adj'
    matrix rownames `delta_p' = Delta Delta_adjusted
    matrix colnames `delta_p' = p-Value
    return matrix delta_p = `delta_p'
    return scalar blocklength = `blocklen'
    return scalar reps = `reps'
    if "`partial'" != "" return local partial "`partial'"
    if "`crosssectional_output'" != "" return local crosssectional "`crosssectional_output'"
end

mata:
function xtbhst_bootstrap( string scalar lhsname, string scalar rhsname, string scalar rhspartialname, string scalar idtname, string scalar tousename, real scalar reps, real scalar blocklength, string scalar deltamatname, string scalar betamatname, string scalar betafe_name) {
    real matrix Y, X, idt, Z, index, E, E_star
    real scalar N_g, K, Kpartial, i, starti, endi, T_g
    real matrix tmp_xx_array, tmp_xx1_array, tmp_zz1_array
    
    Y = st_data(.,lhsname,tousename)
    X = st_data(.,rhsname,tousename)
    idt = st_data(.,idtname,tousename)

    Z = .
    if (rhspartialname[1,1]:!= " ") Z = st_data(.,rhspartialname,tousename)
    
    N_g = rows(uniqrows(idt[.,1]))
    K = cols(X)     
    Kpartial = 0
    index = panelsetup(idt[.,1],1)
    
    T_g = index[1,2] - index[1,1] + 1
    for (i=2; i<=N_g; i++) {
        if (index[i,2] - index[i,1] + 1 != T_g) {
            errprintf("xtbhst requires a strongly balanced panel for the block bootstrap procedure\n")
            exit(498)
        }
    }
    
    if (blocklength == -1) blocklength = floor(2 * T_g^(1/3))
    if (blocklength < 1) blocklength = 1

    tmp_xx_array = J(K*N_g, K, .) 
    tmp_xx1_array = J(K*N_g, K, .)
    if (Z[1,1] != .) {
        Kpartial = cols(Z)
        tmp_zz1_array = J(Kpartial*N_g, Kpartial, .)
    }
    
    E = J(T_g, N_g, .)
    sigma2 = J(N_g,1,.)
    beta2i = J(N_g,K,.)
    beta2wfe_up = 0
    beta2wfe_low = J(K,K,0)
    
    for (i=1; i<=N_g; i++) {
        starti = index[i,1]
        endi = index[i,2]
        
        Yi = Y[|starti, 1 \ endi, 1|]
        Xi = X[|starti, 1 \ endi, K|]
        
        if (Kpartial > 0) {
            Zi = Z[|starti, 1 \ endi, Kpartial|]
            tmp_zz = quadcross(Zi,Zi)
            tmp_zz1 = invsym(tmp_zz)
            tmp_zz1_array[| (i-1)*Kpartial+1, 1 \ i*Kpartial, Kpartial |] = tmp_zz1
            Yi = Yi - Zi * tmp_zz1*quadcross(Zi,Yi)
            Xi = Xi - Zi * tmp_zz1*quadcross(Zi,Xi)
            Y[|starti, 1 \ endi, 1|] = Yi
            X[|starti, 1 \ endi, K|] = Xi
        }
    }
    
    real matrix tmp_xx_global, b_fe, resid_fe
    tmp_xx_global = quadcross(X,X)
    b_fe = invsym(tmp_xx_global) * quadcross(X,Y)
    resid_fe = Y - X * b_fe
    
    for (i=1; i<=N_g; i++) {
        starti = index[i,1]
        endi = index[i,2]
        
        Yi = Y[|starti, 1 \ endi, 1|]
        Xi = X[|starti, 1 \ endi, K|]
        
        tmp_xx = quadcross(Xi,Xi)
        tmp_xx1 = invsym(tmp_xx)
        tmp_xy = quadcross(Xi,Yi)
        
        tmp_xx_array[| (i-1)*K+1, 1 \ i*K, K |] = tmp_xx
        tmp_xx1_array[| (i-1)*K+1, 1 \ i*K, K |] = tmp_xx1
        
        beta_i = tmp_xx1 * tmp_xy
        beta2i[i,.] = beta_i'
        
        residi = Yi - Xi * beta_i
        E[., i] = residi
        
        real matrix residi_fe
        residi_fe = resid_fe[|starti, 1 \ endi, 1|]
        sigma2[i] =  (residi_fe' * residi_fe) / (T_g - Kpartial)
        
        beta2wfe_up = beta2wfe_up :+ tmp_xy :/ sigma2[i]
        beta2wfe_low = beta2wfe_low :+  tmp_xx :/ sigma2[i]
    }
    
    beta2wfe_orig = invsym(beta2wfe_low) * beta2wfe_up 
    
    S_tilde = 0
    for(i=1; i<=N_g; i++) {
        beta_i = beta2i[i,.]'
        tmp_xx = tmp_xx_array[| (i-1)*K+1, 1 \ i*K, K |] :/ sigma2[i]
        S_tilde = S_tilde + (beta_i - beta2wfe_orig)' * tmp_xx * (beta_i - beta2wfe_orig)         
    }

    delta_orig = sqrt(N_g) * (S_tilde/N_g - K) / sqrt(2*K)
    var_st = 2*K*(T_g-K-Kpartial-1)/(T_g-Kpartial+1)
    delta_adj_orig = sqrt(N_g)*(((S_tilde/N_g)-K)/sqrt(var_st))
    
    delta_stars = J(reps, 1, .)
    delta_adj_stars = J(reps, 1, .)
    
    for (b=1; b<=reps; b++) {
        E_star = J(T_g, N_g, .)
        t_start = 1
        while (t_start <= T_g) {
            rand_idx = ceil(runiform(1,1) * (T_g - blocklength + 1))
            len = min((blocklength, T_g - t_start + 1))
            E_star[|t_start, 1 \ t_start+len-1, N_g|] = E[|rand_idx, 1 \ rand_idx+len-1, N_g|]
            t_start = t_start + len
        }
        
        real matrix Y_star_global
        Y_star_global = J(rows(Y), 1, .)
        
        for (i=1; i<=N_g; i++) {
            starti = index[i,1]
            endi = index[i,2]
            Xi = X[|starti, 1 \ endi, K|]
            Ei_star = E_star[., i]
            
            tilde_Ei_star = Ei_star
            if (Kpartial > 0) {
                Zi = Z[|starti, 1 \ endi, Kpartial|]
                tmp_zz1 = tmp_zz1_array[| (i-1)*Kpartial+1, 1 \ i*Kpartial, Kpartial |]
                tilde_Ei_star = Ei_star - Zi * tmp_zz1 * quadcross(Zi, Ei_star)
            }
            
            Y_star = Xi * beta2wfe_orig + tilde_Ei_star
            Y_star_global[|starti, 1 \ endi, 1|] = Y_star
        }
        
        real matrix b_fe_star, resid_fe_star
        b_fe_star = invsym(tmp_xx_global) * quadcross(X, Y_star_global)
        resid_fe_star = Y_star_global - X * b_fe_star
        
        sigma2_star = J(N_g, 1, .)
        beta_star = J(N_g, K, .)
        betawfe_up = 0
        betawfe_low = J(K, K, 0)
        
        for (i=1; i<=N_g; i++) {
            starti = index[i,1]
            endi = index[i,2]
            Xi = X[|starti, 1 \ endi, K|]
            Y_star = Y_star_global[|starti, 1 \ endi, 1|]
            
            tmp_xx1 = tmp_xx1_array[| (i-1)*K+1, 1 \ i*K, K |]
            tmp_xx = tmp_xx_array[| (i-1)*K+1, 1 \ i*K, K |]
            
            tmp_xy_star = quadcross(Xi, Y_star)
            beta_i_star = tmp_xx1 * tmp_xy_star
            beta_star[i, .] = beta_i_star'
            
            real matrix residi_fe_star
            residi_fe_star = resid_fe_star[|starti, 1 \ endi, 1|]
            sigma2_star[i] = (residi_fe_star' * residi_fe_star) / (T_g - Kpartial)
            
            betawfe_up = betawfe_up :+ tmp_xy_star :/ sigma2_star[i]
            betawfe_low = betawfe_low :+ tmp_xx :/ sigma2_star[i]
        }
        
        beta2wfe_star = invsym(betawfe_low) * betawfe_up
        
        S_tilde_star = 0
        for (i=1; i<=N_g; i++) {
            beta_i_star = beta_star[i, .]'
            tmp_xx = tmp_xx_array[| (i-1)*K+1, 1 \ i*K, K |] :/ sigma2_star[i]
            S_tilde_star = S_tilde_star + (beta_i_star - beta2wfe_star)' * tmp_xx * (beta_i_star - beta2wfe_star)
        }
        
        d_star = sqrt(N_g) * (S_tilde_star/N_g - K) / sqrt(2*K)
        d_adj_star = sqrt(N_g) * ((S_tilde_star/N_g - K) / sqrt(var_st))
        
        delta_stars[b] = d_star
        delta_adj_stars[b] = d_adj_star
    }

    pval_delta = sum(delta_stars :> delta_orig) / reps
    pval_delta_adj = sum(delta_adj_stars :> delta_adj_orig) / reps

    st_matrix(deltamatname, (delta_stars, delta_adj_stars))
    st_matrix(betamatname, beta2i)
    st_matrix(betafe_name, beta2wfe_orig)

    return ((delta_orig, delta_adj_orig, pval_delta, pval_delta_adj, blocklength))
}
end

/* Program from xtdcce2 to calculate CSA; creates csa and returns list with tempvars */ 
capture program drop xtdcce2_csa
program define xtdcce2_csa, rclass
        syntax varlist(ts) , idvar(varlist) tvar(varlist) cr_lags(numlist) touse(varlist) csa(string) 
               tsunab olist: `varlist'
               
               tsrevar `varlist'
                local varlist `r(varlist)'
                
                foreach var in `varlist' {
                                local ii `=strtoname("`var'")'
                                tempvar `ii'
                                by `tvar' (`idvar'), sort: egen ``ii'' = mean(`var') if `touse'                         
                                local clist `clist' ``ii''
                        }
                        if "`cr_lags'" == "" {
                                local cr_lags = 0
                        }
                        local i = 1
                        local lagidef = 0
                        foreach var in `clist' {
                                local lagi = word("`cr_lags'",`i')
                                if "`lagi'" == "" {
                                        local lagi = `lagidef'
                                }
                                else {
                                        local lagidef = `lagi'                                  
                                }
                                sort `idvar' `tvar'
                                tsrevar L(0/`lagi').`var'
                                
                                local cross_structure "`cross_structure' `=word("`olist'",`i')'(`lagi')"
                                local clistfull `clistfull' `r(varlist)'
                                local i = `i' + 1
                        }
                        local i = 1
                        foreach var in `clistfull' {
                                rename `var' `csa'_`i'
                                local clistn `clistn' `csa'_`i'
                                local i = `i' + 1
                        }
                        
                return local varlist "`clistn'"
                return local cross_structure "`cross_structure'"
end
