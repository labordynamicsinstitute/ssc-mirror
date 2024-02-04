*! tscb: Two-Stage Cluster Bootstrap (Abadie et al., 2023) Implementation
*! Version 1.0.0 January 28, 2024
*! dpailanir@fen.uchile.cl, dclarke@fen.uchile.cl

/*
Version 1.0.0: First version on SSC (Jan 28, 2024)
*/

cap program drop tscb 
program tscb, eclass
version 13.0

#delimit ;
    syntax varlist(min=3 max=3) [if] [in], qk(numlist max=1 >0 <=1)
    [
        seed(numlist integer >0 max=1)
        reps(integer 50)
        fe
    ]
    ;
#delimit cr

*------------------------------------------------------------------------------*
* (0) Error checks in parsing
*------------------------------------------------------------------------------*
tempvar touse
mark `touse' `if' `in'

local qm=1/`qk'
if mod(`qm',1)==0 {
    if `qm'!=1 di as text "1/q is an integer, so we expand the data by `qm' for each cluster"
}

if mod(`qm',1)!=0 {
    local f=floor(`qm')
    local alpha=1-(`qm'-`f')
    local qm=`f'+1
    di as text "1/q is not an integer, so we expand the data by `f' or `qm' for each cluster"
}

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
tempvar V
qui bys `3': egen `V' = mean(`2') if `touse'
qui sum `V' if `touse'
if r(min)==0 | r(max)==1 {
    di as error "Not all clusters have variance in treatment."
    di as error "Please ensure that treatment variable `2' has within-cluster variation"
    exit 222
}
drop `V'

*------------------------------------------------------------------------------*
* (1) Run TSCB
*------------------------------------------------------------------------------*
tokenize `varlist'
tempvar M
qui egen `M' = group(`3') if `touse'

*qui levelsof `M' //this works only for Stata > 15.0 versions
qui sum `M'
local rs=r(max)
local S=`rs'*`qm'

mata: States = J(`S',1,NULL)
local i=1

local m=0
forval r=1/`qm' {
    if `r'>1 local ++m
    forval s=1/`rs' {
        qui putmata S`i'=(`M' `1' `2') if `M'==`s' & `touse', replace
        mata: States[`i'] = &(S`i')
        if `i'>`s' {
            mata: (*States[`i'])[,1] = (*States[`i'])[,1]:+`m'*`rs'
        }
        local ++i
    }
}

mata: Data=(range(1,`S',1), J(`S',1,.))
mata: W=J(`S',1,.)
forval s=1/`S' {
    mata: W[`s',1]    = mean((*States[`s'])[,3])
    mata: Data[`s',2] = rows((*States[`s'])[,1])
}

//bootstrap procedure
local b = 1
mata: taus = J(`reps',1,.)
cap set seed `seed'

dis "Two-Stage Cluster Bootstrap replications (`reps')."
dis "----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5"

preserve
while `b'<=`reps' {
    display in smcl "." _continue
    if mod(`b',50)==0 dis "     `b'"

    //select Wmean randomly
    mata: Data2 = NewData(Data,W,`S')
		
    //array for sampled clusters SST=Treated, SSU=Untreated, SS=T+U
    mata: SST  = J(`S',1,NULL) 
    mata: SSU  = J(`S',1,NULL) 
    mata: SS   = J(`S',1,NULL) 
    mata: SSTU = J(1,3,.) 

    if `qk'==1 {
        local upperS=`S'
        mata: newi=Data[,1]
    }
    else {
        local upperS=`rs'
        local C=`S'
		
        if mod(1/`qk',1)!=0 {
            mata: ud=rdiscrete(1, 1, (`alpha',1-`alpha'))
            mata: st_local("ud", strofreal(ud))
            if `ud'==1 local C=`f'*`rs'
            else       local C=`qm'*`rs'		
        }
		
        mata: newi=sort(SSelect(`C', `rs', Data[1..`C',1]),1)
    }

    forval i=1/`upperS' {		
        //base for regression
        mata: i=newi[`i',1]
        mata: SS[`i']=SSample(Data2, States, SST, SSU, i)
        mata: SSTU=(SSTU\(*SS[`i']))
    }
	
    //run regression and save estimators
    if "`fe'"=="fe" {
       mata: taus[`b',] = FE(SSTU[,2], SSTU[,3], SSTU[,1])
    }
	else {
       mata: alpha = sum(SSTU[,2]:*(1:-SSTU[,3]))/sum(1:-SSTU[,3])
       mata: taus[`b',] = sum(SSTU[,2]:*SSTU[,3])/sum(SSTU[,3]) - alpha
    }
    local ++b
}
restore

mata: se = sqrt((`reps'-1)/`reps') * sqrt(variance(vec(taus)))
mata: st_local("se", strofreal(se))

*-------------------------------------------------------------------------------
* (2) Robust and Cluster Variances
*-------------------------------------------------------------------------------
qui putmata data = (`1' `2' `M') if `touse', replace
mata: Wbar = mean(data[,2])
mata: Ntot = rows(data)

if "`fe'"=="fe" {
    // robust and cluster SE FE
    mata: b = FE(data[,1], data[,2], data[,3])
    mata: st_local("b", strofreal(b))
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
	
    mata: Rsq = 1-(tildes[6,1]/sum((data[,1]:-mean(data[,1])):^2))
    mata: st_local("Rsq", strofreal(Rsq))
}	

else { 
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

    mata: Rsq = 1-(sum(Uhat:^2)/sum((data[,1]:-mean(data[,1])):^2))
    mata: st_local("Rsq", strofreal(Rsq))
}

*-------------------------------------------------------------------------------
* (3) Return output
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

if "`fe'"=="fe" local title "Fixed effect regression with Two-Stage Cluster Bootstrap Variance"
else            local title "OLS regression with Two-Stage Cluster Bootstrap Variance"

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

ereturn clear
ereturn scalar beta       = `b'
ereturn scalar se_tscb    = `se' 
ereturn scalar se_robust  = `se_r' 
ereturn scalar se_cluster = `se_cl' 
ereturn scalar reps       = `reps'
ereturn scalar N_clust    = `rs'

ereturn local cmdline  "tscb `0'"
ereturn local clustvar "`3'"
ereturn local depvar   "`1'"
ereturn local cmd      "tscb"

end

*------------------------------------------------------------------------------*
* (2) Mata Functions
*------------------------------------------------------------------------------*
mata:
    matrix NewData(matrix D, matrix W, S) {
        p=J(S,1,1/S)
        index=rdiscrete(S,1,p)
        Wsample=W[index[,1],1]
        D2=(D,round(D[.,2]:*Wsample),round(D[.,2]:*(1:-Wsample)))
        return(D2)
    }
end 

mata:
    matrix SSample(matrix Data2, pointer States, pointer SST, pointer SSU, i) {
    NT=Data2[i,3]
    NU=Data2[i,4]
    NT_original=rows((*States[i])[selectindex((*States[i])[,3]:==1),])
    NU_original=rows((*States[i])[selectindex((*States[i])[,3]:==0),])
    indexT=ceil(NT_original*runiform(NT,1))
    indexU=ceil(NU_original*runiform(NU,1))
	
    //treated
    matauxT=(*States[i])[selectindex((*States[i])[,3]:==1),]
    SST[i]=&(matauxT[indexT[,1],])
		
    //untreated
    matauxU=(*States[i])[selectindex((*States[i])[,3]:==0),]
    SSU[i]=&(matauxU[indexU[,1],])
		
    //append treated to un-treated in each state
    SS=&((*SST[i])\(*SSU[i]))
	
    return(SS)
    }
end

mata: 
    real vector SSelect(S, rs, D) {
    index=(runiform(S,1),D)
    s=sort(index,-1)[1..rs,2]
    return(s)
    }
end

mata:
real scalar FE(vector Y, vector W, vector Cluster) {
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


