*! ccv: Causal Cluster Variance (Abadie et al., 2023) Implementation
*! Version 1.0.0 January 28, 2024
*! dpailanir@fen.uchile.cl, dclarke@fen.uchile.cl

/*
Versions: 0.0.1 november14   - add if/in and create unique id in ccv
        : 0.0.2 november21   - add FE option and return results
        : 1.0.0 Jan 28, 2024 - SSC first version
*/


cap program drop ccv
program ccv, eclass
version 13.0

#delimit ;
    syntax varlist(min=3 max=3) [if] [in],
        qk(numlist max=1 >0 <=1) 
        pk(numlist max=1 >0 <=1)
        [
            seed(numlist integer >0 max=1)
            reps(integer 4)
            fe
        ];
#delimit cr
tokenize `varlist'

*-------------------------------------------------------------------------------
*--- (0) Error checks and unpack parsing
*-------------------------------------------------------------------------------
tempvar touse
mark `touse' `if' `in'

//CHECK IF DEPENDENT VARIABLE IS NUMERIC
confirm numeric variable `1'

//CHECK IF TREATMENT IS BINARY
qui sum `2' if `touse'
local t_error = 0
if r(min)!=0 | r(max)!=1 {
    local t_error = 1
}
else {
    qui tab `2'
    if r(r)!=2 local t_error=1
}
if `t_error'==1 {
    dis as error "Please ensure that treatment variable `2' is binary."
    exit 222
}

//CHECK IF THERE IS VARIATION IN TREATMENT WITHIN EACH GROUP
tempvar M
qui bys `3': egen `M' = mean(`2') if `touse'
qui sum `M' if `touse'
if r(min)==0 | r(max)==1 {
    di as error "Not all clusters have variance in treatment."
    di as error "Please ensure that treatment variable `2' has within-cluster variation"
    exit 222
}

*-------------------------------------------------------------------------------
*--- (1) Run CCV
*-------------------------------------------------------------------------------
cap set seed `seed'
qui putmata data = (`1' `2' `M') if `touse', replace
mata: ccv=J(`reps',1,.)
mata: Wbar = mean(data[,2])
mata: Ntot = rows(data)

*-------------------------------------------------------------------------------
*--- (1.1) FE
*-------------------------------------------------------------------------------
if "`fe'"=="fe" {
    // calculate tau FE
    mata: b = FE(data[,1], data[,2], data[,3])
    mata: st_local("b", strofreal(b))

    // robust and cluster SE FE
    mata: tildes = auxsum(data[,1], data[,2], data[,3], b)
    mata: r_V = Ntot*(tildes[1,1]/tildes[3,1]^2)
    mata: se_r = sqrt(r_V)/sqrt(Ntot)
    mata: st_local("se_r", strofreal(se_r))
    mata: Mk = rows(uniqrows(data[,3]))
    mata: K = Mk+1+1 
    mata: C  = sqrt(Mk/(Mk-1)*(Ntot-1)/(Ntot-K))
    mata: cluster_V = Ntot*(tildes[2,1]/tildes[3,1]^2)
    mata: se_cl = C*sqrt(cluster_V)/sqrt(Ntot)
    mata: st_local("se_cl", strofreal(se_cl))

    // adjust for qk<1 OLS
    mata: Mk = rows(uniqrows(data[,3]))
    mata: lambdak = 1 - `qk'*((tildes[4,1]/Mk)^2/(tildes[5,1]/Mk))
    mata: ccv = lambdak*cluster_V + (1 - lambdak)*r_V
    mata: se = sqrt(ccv)/sqrt(Ntot)
    mata: st_local("se", strofreal(se))
	
    mata: Rsq = 1-(tildes[6,1]/sum((data[,1]:-mean(data[,1])):^2))
    mata: st_local("Rsq", strofreal(Rsq))
}

*-------------------------------------------------------------------------------
*--- (1.1) OLS
*-------------------------------------------------------------------------------
else {

    dis "Causal Cluster Variance with (`reps') sample splits."
    dis "----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5"

    forval i=1/`reps' {
        display in smcl "." _continue
        if mod(`i',50)==0 dis "     `i'"
	
        tempvar split
        qui gen `split' = runiform()<=0.5 if `touse'
        qui putmata split = (`split') if `touse', replace
        mata: ccv[`i',1]=CCV(data[,1], data[,2], data[,3], split, `pk', `qk')
    }

    // robust SE OLS
    mata: wbar_factor = (Wbar^2)*(1-Wbar)^2
    mata: alpha = sum(data[,1]:*(1:-data[,2]))/sum(1:-data[,2])
    mata: b = sum(data[,1]:*(data[,2]))/sum(data[,2]) - alpha
    mata: Uhat = data[,1] :- alpha :- data[,2]:*b
    mata: r_V = mean((Uhat:^2 :* (data[,2]:-Wbar):^2))/wbar_factor
    mata: se_r = sqrt(r_V)/sqrt(Ntot)
    mata: st_local("se_r", strofreal(se_r))
    mata: st_local("b", strofreal(b))

    // cluster SE OLS
    mata: Mk = rows(uniqrows(data[,3]))
    mata: C  = sqrt(Mk/(Mk-1)*(Ntot-1)/(Ntot-2))
    mata: cluster_V = cluster_SE(Uhat, data[,2], data[,3], Wbar)
    mata: cluster_V = cluster_V/(Ntot*wbar_factor)
    mata: se_cl = C*sqrt(cluster_V)/sqrt(Ntot)
    mata: st_local("se_cl", strofreal(se_cl))

    // adjust for qk<1 OLS
    mata: ccv = ccv:*`qk' :+ (1-`qk')*cluster_V
    mata: se = sqrt((1/`reps')*sum(ccv))/sqrt(Ntot)
    mata: st_local("se", strofreal(se))
	
    mata: Rsq = 1-(sum(Uhat:^2)/sum((data[,1]:-mean(data[,1])):^2))
    mata: st_local("Rsq", strofreal(Rsq))
}

*-------------------------------------------------------------------------------
* (2) Return output
*-------------------------------------------------------------------------------
// mata to stata
mata: st_local("Ntot", strofreal(Ntot))
mata: st_matrix("b", b)

// output
matrix V = `se'^2
matrix colnames b = `2' 
matrix rownames b = `1'
matrix colnames V = `2'
matrix rownames V = `2'
ereturn post b V, depname(`1') obs(`Ntot')

local zr = `b'/`se_r'
local zc = `b'/`se_cl'
local pr = 2 * (1-normal(abs(`zr')))
local pc = 2 * (1-normal(abs(`zc')))
local lci_r = `b'+invnormal(0.025)*`se_r'
local uci_r = `b'+invnormal(0.975)*`se_r'
local lci_c = `b'+invnormal(0.025)*`se_cl'
local uci_c = `b'+invnormal(0.975)*`se_cl'

if "`fe'"=="" local title "OLS regression with Causal Cluster Variance"
else          local title "Fixed effect regression with Causal Cluster Variance"

local spaces "                                                "

di as text ""
di as text "`title'"
di as text "`spaces'Number of obs     = " as result %10.0fc `Ntot'
di as text "`spaces'R-squared         =  " as result  %9.4f `Rsq'
di as text ""
ereturn display, plus cformat(%9.3f)
di as text " Robust SE   {c |}             " as result %9.3f `se_r'  "" _continue
di as result %9.2f `zr' as result %8.3f `pr' "    "                     _continue
di as result %9.3f `lci_r' "   " as result %9.3f `uci_r'
di as text " Cluster SE  {c |}             " as result %9.3f `se_cl' "" _continue
di as result %9.2f `zc' as result %8.3f `pc' "    "                     _continue
di as result %9.3f `lci_c' "   " as result %9.3f `uci_c'
di as text "{hline 13}{c BT}{hline 64}"

qui tab `3'
local rs=r(r)

ereturn clear
ereturn scalar beta       = `b'
ereturn scalar se_ccv     = `se' 
ereturn scalar se_robust  = `se_r' 
ereturn scalar se_cluster = `se_cl' 
ereturn scalar reps       = `reps'
ereturn scalar N_clust    = `rs'

ereturn local cmdline  "ccv `0'"
ereturn local clustvar "`3'"
ereturn local depvar   "`1'"
ereturn local cmd      "ccv"

end

*-------------------------------------------------------------------------------
*--- (3) Mata functions
*-------------------------------------------------------------------------------
mata: 
real scalar CCV(vector Y, vector W, vector M, vector u, scalar pk, scalar qk) {
    // u is split variable: 1 if estimation, 0 if calculate    
    //Calculate alpha and tau for split 1
    //[CONFIRM IF FASTER TO JUST SELECT SUB-VECTORS]
    alpha = sum(Y:*(1:-W):*(1:-u))/sum((1:-W):*(1:-u))
    tau = sum(Y:*(W):*(1:-u))/sum((W):*(1:-u)) - alpha
    // Calculate tau for full sample
    tau_full = sum(Y:*(W))/sum(W) - sum(Y:*(1:-W))/sum(1:-W)
    //Calculate pk term
    pk_term = 0
    ncount = 0
    uniqM = uniqrows(M)
    NM = rows(uniqM)
    tau_ms = J(NM,1,.)
    for(m=1;m<=NM;++m) {
        cond = M:==uniqM[m]
        y = select(Y,cond)
        w = select(W,cond)
        u_m = select(u,cond)
        Nm = rows(y)
        ncount = ncount + Nm
		
        if (variance(vec(w))==0) {
            tau_ms[m,1] = tau
            tau_full_ms = tau_full
        }
        else {
            tau_ms[m,1] = sum(y:*(w):*(1:-u_m))/sum((w):*(1:-u_m)) -
                          sum(y:*(1:-w):*(1:-u_m))/sum((1:-w):*(1:-u_m))
            tau_full_ms = sum(y:*(w))/sum(w) - sum(y:*(1:-w))/sum(1:-w)
        }
		
        aux_pk = Nm*((tau_full_ms - tau)^2)
        pk_term = pk_term + aux_pk
    }	
    // Calculate residual
    resU = Y :- alpha :- W:*tau
    // Wbar
    Wbar = sum(W:*(1:-u))/(sum((1:-W):*(1:-u)) + sum((W):*(1:-u)))
    // pk
    pk_term = pk_term*(1-pk)/ncount
    // Calculate avg Z
    Zavg = sum(u)/ncount
    // Calculate the normalized CCV using second split
    n = ncount*(Wbar^2)*((1-Wbar)^2)
    sum_CCV = 0
    for(m=1;m<=NM;++m) {
        cond = M:==uniqM[m]
        cond = cond:*u
        y = select(Y,cond)
        w = select(W,cond)
        resu = select(resU,cond)
		
        // tau
        tau_term = (tau_ms[m,1] - tau)*Wbar*(1-Wbar)
        // Residual
        res_term = (w :- Wbar):*resu
        // square of sums
        sq_sum = (sum(res_term :- tau_term))^2
        // sum of squares
        sum_sq = sum((res_term :- tau_term):^2)
        // Calculate CCV
        sum_CCV = sum_CCV+(1/(Zavg^2))*sq_sum-((1-Zavg)/(Zavg^2))*sum_sq+n*pk_term
    }
	
    V_CCV = sum_CCV/n

    // Place-holder
    return(V_CCV)
}
end

mata:
real scalar FE(vector Y, vector W, vector Cluster) {
    //A = (Y, W)
    //Acoll = _mm_collapse2(A, 1, Cluster)
    //y = Y - Acoll[,1]
    Wmean = _mm_collapse2(W, 1, Cluster)
    w = W - Wmean
    tau_fe = sum(Y:*w)/sum(W:*w)
    return(tau_fe)
}
end

mata:
real matrix auxsum(vector Y, vector W, vector M, scalar fe) {
    sum_tildeU = 0
    sum_tildeW = 0
    sum_tildeU_FE = 0
    num_lambdak = 0
    den_lambdak = 0
    sum_res = 0
    T = J(6,1,.)
	
    uniqM = uniqrows(M)
    NM = rows(uniqM)
    for(m=1;m<=NM;++m) {
        cond = M:==uniqM[m]
        y = select(Y,cond)
        w = select(W,cond)
        Ym = mean(y)
        Wmbar = mean(w)
        Wtilde = w :- Wmbar
        Utilde = y :- Ym :- (Wtilde:*fe)
        sum_tildeU = sum_tildeU + sum((Wtilde:^2):*(Utilde:^2))
        sum_tildeU_FE = sum_tildeU_FE + (sum(Wtilde:*Utilde))^2
        sum_tildeW = sum_tildeW + sum(Wtilde:^2)
		
        num_lambdak = num_lambdak + Wmbar*(1-Wmbar)
        den_lambdak = den_lambdak + (Wmbar^2)*((1-Wmbar)^2)
		
        sum_res = sum_res + sum((Utilde:^2))
    }
	extrasum
    T[1,1] = sum_tildeU
    T[2,1] = sum_tildeU_FE
    T[3,1] = sum_tildeW
    T[4,1] = num_lambdak
    T[5,1] = den_lambdak
    T[6,1] = sum_res
    return(T)
}
end

mata: 
real scalar cluster_SE(vector Uhat, vector W, vector M, scalar Wbar) {
    uniqM = uniqrows(M)
    NM = rows(uniqM)
    cluster_SE = 0
    for(m=1;m<=NM;++m) {
        cond = M:==uniqM[m]
        uhat = select(Uhat,cond)
        w = select(W,cond)
        err = sum(uhat :* (w :- Wbar))^2
        cluster_SE = cluster_SE + err
    }
    return(cluster_SE)
}
end


