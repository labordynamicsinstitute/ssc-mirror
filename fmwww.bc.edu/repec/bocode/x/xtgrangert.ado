*! version 1.13 - 04.01.2023

cap program drop xtgrangert
program xtgrangert,eclass 
version 12.0

syntax varlist(numeric ts) [if][in][,lags(integer 1) ///
	maxlags(integer 0) het nodfc sum BOOTstrapindex BOOTstrapcmd(string) ///
	LAGOVERLAP 		/// allow lags to overlap in HPJ
	/*internal: */ 	///
	trace			 /// display more info	
	test0 			/// use old test0 program 
	]

marksample touse
preserve

*** part to allow for ts by JD
gettoken depvar indeps: varlist
tsunab o_depvar: `depvar'
tsunab o_indeps: `indeps'

if "`lagoverlap'" == "" local nonoverlap "nonoverlap"

tsrevar `depvar'
local depvar `r(varlist)'
tsrevar `indeps'
local indeps `r(varlist)'


quietly keep if `touse'

foreach var in `indeps'{
	quietly xtsum `var'
	if(r(sd_w)==0){
		display as error "Some variables are time-invariant."
		exit
	}
}

/// internal option trace
if "`trace'" != "" {
	local trace noi 
}
else {
	local trace qui
}

capture xtset
local idvar `r(panelvar)'
local tvar `r(timevar)'
local unbalanced = 0

if "`r(balanced)'" != "strongly balanced" {
	*display as error "Panel needs to be strongly balanced"
	*exit
	display "Unbalanced Panel detected - Variance will be bootstrapped"
	local unbalanced = 1
	local test0 ""
	qui sum `tvar' if `touse'
}

tempvar tnew
egen `tnew' = group(`tvar') if `touse'

qui sum `tnew' if `touse'
local t =r(max)-r(min)+1
local n =r(N)/`t'


if _rc {
	display as error "Panel variable not set; use xtset before running xtgrangert."
	exit
}

if (floor(`t'/2)<=1+`lags') {
	display as error "Not enough time series observations. Floor(T/2) must be greater than 1+lags."
	exit
}

if (floor(`t'/2)<=1+`maxlags') {
	display as error "Not enough time series observations. Floor(T/2) must be greater than 1+maxlags."
	exit
}

if (`lags'==0) {
	display as error "Number of lags need to be a positive integer."
	exit
}

if (`maxlags'!=0){
	if "`test0'" == "" {
		mata: test01("`depvar'","`indeps'","`idvar' `tnew'",`maxlags')
	}
	else {
		mata: test0("`depvar'","`indeps'",`t',`n',`maxlags')
	}
	
	local lags=r(p)
	matrix lag_BIC=r(lag_BIC)
}

*** bootstrap
local bootstrapdraws = 0
if "`bootstrapindex'" != "" {
	local bootstrapdraws = 100
}
if "`bootstrapcmd'" != "" {
	local 0 `bootstrapcmd'
	syntax anything(name=bootstrapdraws) , [seed(string)]

	if "`seed'" != "" set seed `seed'

}

markout `touse' `depvar' L(1/`lags').(`indeps')  L(1/`lags').`depvar'

`trace' mata: test1("`depvar'","L(1/`lags').(`indeps')","L(1/`lags').`depvar'","`idvar' `tnew'","`touse'",`n',`t',`lags',"`het'","`dfc'",`bootstrapdraws',"`nonoverlap'"!="",`unbalanced')

scalar W_HPJ=r(W_HPJ)
local k=r(k)
local df=`k'*`lags'
local BIC=r(BIC)
scalar rejection_HPJ=W_HPJ>invchi2(`df',0.95)
scalar pvalue_HPJ=chi2tail(`df',W_HPJ)
matrix b_HPJ=r(beta)'
matrix Var_HPJ=r(V)

*** read names back by JD
local depvar `o_depvar'
local indeps `o_indeps'

di as text _dup(78) "-"
di as text  "JKS non-causality test"
di as text ""

if (`k'==1){
	di in gr _col(1) "H0: " "`indeps'" " does not Granger-cause " "`depvar'""."
	di in gr _col(1) "H1: " "`indeps'" " does Granger-cause " "`depvar'" " for at least one panelvar."
}
else{
	di in gr _col(1) "H0: Selected covariates do not Granger-cause " "`depvar'""."
	di in gr _col(1) "H1: H0 is violated."
}
di as text ""
di in gr _col(1) "HPJ Wald test" _col(16) ": "  in ye %6.4f r(W_HPJ) 
di in gr _col(1) "p-value" _col(16) ": "		in ye %6.4f pvalue_HPJ

di as text _dup(78) "-"

if (`maxlags'!=0){
	di in gr "BIC selection:" 
	forvalues lag1=1/`maxlags'{
		if (`lag1'==`lags'){
		di in gr "    lags = " in ye lag_BIC[`lag1',1] in gr ", BIC = " in ye lag_BIC[`lag1',2] "*"
		}
		else{
		di in gr "    lags = " in ye lag_BIC[`lag1',1] in gr ", BIC = " in ye lag_BIC[`lag1',2]
		}
	}
di as text _dup(78) "-"
}

local name1 `indeps'
local names ""
foreach name of local name1{
	forvalues p1=1/`lags'{
		local names "`names' l`p1'.`name'"
	}
} 
matrix colname b_HPJ=`names'
matrix colname Var_HPJ=`names'
matrix rowname Var_HPJ=`names'

if (`lags'>1) {
matrix b_Sum_HPJ=r(beta_sum)'
matrix Var_Sum_HPJ=r(Svar)
matrix colnames b_Sum_HPJ= `indeps'
matrix colname Var_Sum_HPJ=`indeps'
matrix rowname Var_Sum_HPJ=`indeps'
}

tempname beta v
if ("`sum'"!="") & (`lags'>1) {
	di _col(8) "{bf:Sum of Half-Panel Jackknife coefficients across lags (lags>1)}" 
	mat `beta'=b_Sum_HPJ
	mat `v'=Var_Sum_HPJ
}
else{
	di _col(16) "{bf:Results for the Half-Panel Jackknife estimator}"
	mat `beta'=b_HPJ
	mat `v'=Var_HPJ
}
	
if ("`het'"!="") {
	di _col(8) "Cross-sectional heteroskedasticity-robust variance estimation"
	}
if("`dfc'"!=""){
	di _col(10) "No degrees-of-freedom correction in the variance estimator"
}
 
ereturn post `beta' `v'
ereturn display

ereturn scalar N = `n'
ereturn scalar T = `t'
ereturn scalar p=`lags'
if(`maxlags'!=0){
	ereturn scalar BIC=`BIC'
}
ereturn scalar W_HPJ=W_HPJ
ereturn scalar pvalue=pvalue_HPJ
ereturn matrix b_HPJ=b_HPJ
ereturn matrix Var_HPJ=Var_HPJ

if (`lags'>1) {
	ereturn matrix b_Sum_HPJ=b_Sum_HPJ
	ereturn matrix Var_Sum_HPJ=Var_Sum_HPJ
}
ereturn local cmd "xtgrangert"
ereturn local predict "xtgrangert_p"

/// hidden, added by JD for predict
ereturn hidden local depvar "`depvar'"
ereturn hidden local indepvar "`names'"

restore
end

/// version for mata programs
version 12.0
capture mata mata drop test0() test1() estBeta() ols_inner() test01()
	
mata:
void test0 (string scalar depvar,string scalar indeps, numeric scalar t, numeric scalar n,numeric scalar l)
{
	z1=st_data(.,depvar,.) //the transfer (t*n)*1 matrix
	z2=st_data(.,indeps,.)
	k=cols(z2)
		
	y = colshape(z1',t)'
	x = colshape(z2',t)'

	lag_BIC=J(l,2,0)
	//calculata smallest BIC
	if(l!=0){
		for(z=1; z<=l; z++){
			row=t-z
			cols=z*k
			xi=J(row,cols,.)
			zi=J(row,z+1,.)
			yi=J(row,1,.)
			Mi=J(row,row,0)
			RSS=0	


			for(i=1; i<=n; i++) {
				st_subview(yi,y,(z+1)::t,i) 
				for(m=1; m<=row; m++) { 
					for(q=1; q<=z+1; q++) { 	
						if (q==1) {
							zi[m,q]=1
						}
						else {
							zi[m,q]=y[z+m-q+1,i]
						}
					}		
					for(o=1; o<=k; o++) { 		
						for(j=1; j<=z; j++) { 
							xi[m,(o-1)*z+j]=x[z+m-j,i+(o-1)*n]
						}
					}	
				}

				Mi=I(row)-zi*luinv(zi'*zi)*zi'
				tempxx=xi'*Mi*xi
				tempxy=xi'*Mi*yi
				tempbeta=cross(cholinv(tempxx),tempxy)
				RSS=RSS+(yi-xi*tempbeta)'*Mi*(yi-xi*tempbeta)
			}
			
			
			BIC_p_p=n*(t-1-z-z)*log(RSS/(n*(t-1-z-z)))+z*log(n*(t-1-z-z))
			lag_BIC[z,1]=z
			lag_BIC[z,2]=BIC_p_p
			if (z==1) {
					BIC=BIC_p_p
					p=1
				}
				else{
					if(BIC>BIC_p_p){
						BIC=BIC_p_p
						p=z
					}
				}

			
		}
	}	

	st_numscalar("r(p)",p)
	st_matrix("r(lag_BIC)",lag_BIC)
}	
end	


mata:
void test01 (string scalar depvar,string scalar indeps, string scalar idt ,numeric scalar l)
{
	z1=st_data(.,depvar,.) //the transfer (t*n)*1 matrix
	z2=st_data(.,indeps,.)

	idx = st_data(.,idt,.)
	index = panelsetup(idx,1)
	stats = panelstats(index)
	n = stats[1]
	Tmin = stats[3]
	/// check if smallest panel is long enough to add lags
	if (Tmin <= l) {
			exit(error(2001))
	}
	else {
		k=cols(z2)
		lag_BIC=J(l,2,0)	
		

		for (ll=1;ll<=l;ll++) {
			RSS=0	
			nt = 0
			for (i=1;i<=n;i++) {

				xis = panelsubmatrix(z2,i,index)
				yis = panelsubmatrix(z1,i,index)

				Ti = rows(yis)			
				yi = yis[|ll+1,.\ Ti,.|]

				/// create lags of y
				Lyi = J(Ti-ll,1,1)
				xi = J(rows(Lyi),0,.)
				for (s=1;s<=ll;s++) {

					Lyi = Lyi , yis[|s,.\ Ti-ll+s-1,.|]
					xi = xi, xis[|s,.\ Ti-ll+s-1,.|]
				}
				
				Mi=I(rows(Lyi))-Lyi*luinv(Lyi'*Lyi)*Lyi'
				
				tempxx=xi'*Mi*xi
				tempxy=xi'*Mi*yi
				tempbeta=cross(cholinv(tempxx),tempxy)
				
				RSS=RSS+(yi-xi*tempbeta)'*Mi*(yi-xi*tempbeta)

				nt = nt + Ti - 1- ll - ll
			}
			
			BIC_p_p=nt*log(RSS/(nt))+ll*log(nt)
			lag_BIC[ll,1]=ll
			lag_BIC[ll,2]=BIC_p_p
			if (ll==1) {
				BIC=BIC_p_p
				p=1
			}
			else{
				if(BIC>BIC_p_p){
					BIC=BIC_p_p
					p=ll
				}
			}

		}
		

		st_numscalar("r(p)",p)
		st_matrix("r(lag_BIC)",lag_BIC)
	}
}	
end


mata:
void test1(string scalar depvar,string scalar indeps, string scalar depvarlag,string scalar idtn, string scalar tousen, numeric scalar n, numeric scalar t, numeric scalar p,string scalar het,string scalar dfc,real scalar bootdraws , numeric scalar overlap, numeric scalar unbalanced)
{
	if (unbalanced == 1 & bootdraws == 0) bootdraws = 100

	z1=st_data(.,depvar,tousen) //the transfer (t*n)*1 matrix-y
	z2=st_data(.,indeps,tousen)
	z3=st_data(.,depvarlag,tousen)

	idt = st_data(.,idtn,tousen)
	/// ensure time col points to 1.
	idt[.,2] = idt[.,2] :- min(idt[.,2]):+1

	k=cols(z2)/p
	
	index = panelsetup(idt,1)
	stats = panelstats(index)
	n = stats[1]

	/// inital draw with no bootstrap
	beta = estBeta(z1,z2,z3,index,(1::n),p,RSS=0,b=.,dof=0,overlap)
	///	BIC=n*(t-1-p-p)*log(RSS/(n*(t-1-p-p)))+p*log(n*(t-1-p-p))
	/// dof is n*(t-t-p-p)
	BIC=dof*log(RSS/(dof))+p*log(dof)
	"RSS, BIC, BIC dof adjust."
	RSS,BIC,dof
	/// Mata Output
	stata(`"noi di in gr ""')
	stata(`"noi di in gr "Juodis, Karavias and Sarafidis (2021) Granger non-causality Test""')
	stata(`"noi di as text _dup(78) "-"')

	stata(sprintf(`"noi di in gr "Number of units" _col(16) "= " in ye %s _col(45) in gr "Obs. per unit (T)" _col(63) "= " _col(64) in ye  %s"',strofreal(n),strofreal((t-p))))
	stata(sprintf(`"noi di in gr "Number of lags" _col(16) "= "  in ye %s _col(45) in gr "BIC" _col(63) "= " _col(64) in  ye %s"',strofreal(p),strofreal(BIC)))


	/// Variance estimation
	if (bootdraws == 0) {
		var = calcVar(z1,z2,z3,b,index,(1::n),het,dfc,p)
	}
	else {
		stata(`"noi di as text _dup(78) "-""')
		msg = sprintf("noi _dots 0, title(Bootstrap Variances for HPJ test) reps(%s) ",strofreal(bootdraws))
		stata(msg)
		beta_r = J(bootdraws,rows(beta),0)
		beta_r[bootdraws,.] = beta'

		for (r = 1;r<=bootdraws-1;r++) {
			/// draw from uniform distribution units
			beta_rr = estBeta(z1,z2,z3,index,(floor(n:*runiform(n,1) :+ 1)),p,tmp1=0,tmp2=.,tmp3=.,overlap)
			beta_r[r,.] = beta_rr'
			msg = sprintf("noi _dots %s 0",strofreal(r))
			stata(msg)
		}
		msg = sprintf("noi _dots %s 0",strofreal(bootdraws))
		stata(msg)
		var = quadvariance(beta_r)
	}

	W_HPJ=beta'*luinv(var)*beta	
	
	///calculate the sum of beta
	beta_sum=J(k,1,0)
	for(i=1; i<=k; i++){
		for(j=1; j<=p; j++){
			beta_sum[i]=beta_sum[i]+beta[p*(i-1)+j]
		}
	}
	
	Svar=J(k,k,0)
	for(i=1; i<=k; i++){
		for(j=1; j<=k; j++){
			for(m=1; m<=p; m++){
				for(o=1; o<=p; o++){
					Svar[i,j]=Svar[i,j]+var[m*i,j*o]
				}
			}
		}
	}	
	
	st_numscalar("r(W_HPJ)",W_HPJ) 
	st_numscalar("r(k)",k)
	st_numscalar("r(BIC)",BIC)
	st_matrix("r(beta)",beta)
	st_matrix("r(V)",var) 
	st_matrix("r(beta_sum)",beta_sum)
	st_matrix("r(Svar)",Svar)
	st_numscalar("n",n)
	st_numscalar("t",t)
}
end


mata:
	function estBeta(real matrix y, real matrix x, real matrix Ly, real matrix index,  real matrix sel,real scalar p,real scalar RSS, real matrix b,real scalar dof,numeric scalar overlap_opt)
	{

		"start estimation program"
		pointer(real matrix) yp, xp, Lyp

		yp = &y
		xp = &x
		Lyp = &Ly	
		
		if (overlap_opt==1) overlap = p
		else overlap = 0

		N = rows(index)

		xx_f = xx_u = xx = J(cols(x),cols(x),0)
		xy_f = xy_u = xy = J(cols(x),1,0)

		RSS = 0	
		"start loop"
		n_t = 0
		for (i=N;i>0;i--) {		
			
			ii = sel[i]				
			yi = panelsubmatrix(*yp,ii,index)			
			xi = panelsubmatrix(*xp,ii,index)			
			Lyi = J(rows(yi),1,1),panelsubmatrix(*Lyp,ii,index)			
			ti = rows(yi)+overlap
			n_t = n_t+ ti - 1 - p - p
			mid = floor(ti/2)
			"i, id, mid, Ti"
			i, ii, mid,ti
			/// full panel
			ols_inner(yi,xi,Lyi,xx,xy,RSS)

			/// First part of panel
			ols_inner(yi[|1,. \ mid-overlap,.|],xi[|1,. \ mid-overlap,.|],Lyi[|1,. \ mid-overlap,.|],xx_f,xy_f,tmp=.)

			// Second Part of panel
			ols_inner(yi[|mid+1,. \ .,.|],xi[|mid+1,. \ .,.|],Lyi[|mid+1,. \ .,.|],xx_u,xy_u,tmp=.)
		}

		b=quadcross(cholinv(xx),xy)
		b_f=quadcross(cholinv(xx_f),xy_f)
		b_l=quadcross(cholinv(xx_u),xy_u)
		beta=2*b-(b_f+b_l)/2   //beta 
		"Coefficient Estimates"
		"all - 1st - 2nd - HPJ"
		b,b_f,b_l, beta
		"obs - 1st - 2nd - t - mid point - N"
		rows(y),rows(yi[|1,. \ mid-overlap,.|]),rows(yi[|mid+1,. \ .,.|]),ti,mid, N

		dof = n_t

		return(beta)
	}
end


mata:
	function ols_inner(real matrix y, real matrix x, real matrix z, xx,xy ,RSS)
	{
		if (rows(z) < cols(z) | rows(x) < cols(x)) {
			exit(error(2001))
		}
		Mi = I(rows(z)) - z * luinv(quadcross(z,z)) * z'

		tempxx=x'*Mi*x
		tempxy=x'*Mi*y

		tempbeta=quadcross(cholinv(tempxx),tempxy)
		RSS=RSS + (y-x*tempbeta)'*Mi*(y-x*tempbeta)
		xx = xx + tempxx
		xy = xy + tempxy
	}

end

mata:
	function calcVar(real matrix y, real matrix x, real matrix z, real matrix beta, real matrix index, real matrix sel, string scalar het, string scalar dfc,real scalar p)
	{

		panelstats = panelstats(index)
		n = panelstats[1]
		t = panelstats[2]/n
		/// t missing lags, need them here
		t = t + p
		pointer(real matrix) yp, xp, Lyp

		yp = &y
		xp = &x
		zp = &z	
		
		xx = J(cols(x),cols(x),0)
		xy =  J(cols(x),1,0)

		sum_het = J(cols(x),cols(x),0)
		sum = 0
		nt = 0
		for (i=n;i>0;i--) {
			yi = panelsubmatrix(*yp,i,index)
			xi = panelsubmatrix(*xp,i,index)
			zi = J(rows(yi),1,1),panelsubmatrix(*zp,i,index)			

			Mi = I(rows(zi)) - zi * luinv(quadcross(zi,zi)) * zi'

			xx = xx + xi'*Mi*xi

			ei = yi - xi * beta
			
			if (het=="") {
				tmp = ei'*Mi*ei
				sum = sum + tmp 
			}
			else { 
				tmp = ei'*Mi*xi
				sum_het = sum_het + quadcross(tmp,tmp)
			}
			nt = nt + rows(yi)+p
		}
		
		if(dfc=="") {
			///degree=n*t-n*1-n*p-cols(x)
			degree=nt-n*1-n*p-cols(x)
		}
		else{
			///degree=n*t
			degree=nt
		}
		
		if (het=="") {	
			var=sum/degree*luinv(xx)
		}	
		else{
			temp=sum_het/degree
			var=luinv(xx)*temp*luinv(xx)*(nt)
		}

		return(var)
	}

end

