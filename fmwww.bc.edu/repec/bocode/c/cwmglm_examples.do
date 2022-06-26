/*******************************************************************************
								The students dataset
*******************************************************************************/
use students, clear
cwmglm weight height heightf,  k(2)  posterior(z) xnormal(height heightf) eee

matlist e(mu)
matlist e(sigma)

cap drop group

predict group
tab group gender


tw (scatter height weight if group==1 & gender=="M", mcolor(red) msymbol(T)) ///
 (scatter height weight if group==2 & gender=="M", mcolor(blue) msymbol(T)) ///
 (scatter height weight if group==1 & gender=="F", mcolor(green) msymbol(O)) ///
 (scatter height weight if group==2 & gender=="F", mcolor(red) msymbol(O)), ///
 legend(off) saving(g1,replace)

 tw (scatter height heightf if group==1 & gender=="M", mcolor(red) msymbol(T)) ///
 (scatter height heightf if group==2 & gender=="M", mcolor(blue) msymbol(T)) ///
 (scatter height heightf if group==1 & gender=="F", mcolor(green) msymbol(O)) ///
 (scatter height heightf if group==2 & gender=="F", mcolor(red) msymbol(O)), ///
 legend(off) saving(g2,replace) 

 tw (scatter heightf weight if group==1 & gender=="M", mcolor(red) msymbol(T)) ///
 (scatter heightf weight if group==2 & gender=="M", mcolor(blue) msymbol(T)) ///
 (scatter heightf weight if group==1 & gender=="F", mcolor(green) msymbol(O)) ///
 (scatter heightf weight if group==2 & gender=="F", mcolor(red) msymbol(O)), ///
 legend(off) saving(g3,replace)
 graph combine g1.gph g2.gph g3.gph, rows(1)

cap drop z1 z2
cwmglm w height heightf,  k(2)  posterior(z) xnormal(height heightf) eee

cwmbootstrap, nreps(5)

matlist r(b)

matlist r(mu)

/*******************************************************************************
								The multinorm dataset
*******************************************************************************/
use multinorm, clear

tw (scatter x1 x2 if group==1) /// 
(scatter x1 x2 if group==2) ///
(scatter x1 x2 if group==3), ///
legend(order (1 "comp. 1" 2 "comp. 2" 3 "comp. 3")) ///
legend( rows(1)) title(Artificial Data)


local models vev evv vvv eei vei evi vvi eii vii eee vee eve vve eev 
local bestbic=10e20
local bestaic=10e20
cap matrix drop res

foreach model of local models {
	forval i=2/5 {
	 	cap drop _tau*
		qui cwmglm, xnorm(x1 x2) k(`i') posterior(_tau) `model'
		if (e(converged)==1) {
				    matrix ic=(e(ic),`i', e(ll))
					matrix rownames ic= "`model'"
					matrix res = nullmat(res) \ ic
		local current_BIC=e(ic)[1,2]
		if (`current_BIC'<`bestbic') {
			local bestbic=`current_BIC'
			local bestk_BIC=`i'
			local bestmodel_BIC `model'
			}
		local current_AIC=e(ic)[1,1]
		if (`current_AIC'<`bestaic') {
			local bestaic=`current_AIC'
			local bestk_AIC=`i'
			local bestmodel_AIC `model'
			}
		}
		else di in red ///
		"model `model' with `i' mixture component did not converge"
	}
}
di as result "best model according to BIC: k=`bestk_BIC' type `bestmodel_BIC'"
di as result "best model according to AIC: k=`bestk_AIC' type `bestmodel_AIC'"
***res is the matrix that collects all the cwm that have converged
matrix colnames res=AIC BIC k ll
matlist res

***** re-estimating selected model
cap drop _tau*
cwmglm, xnorm(x1 x2) k(`bestk_BIC') posterior(_tau) `bestmodel_BIC'
matlist e(mu)
matlist e(sigma)
predict map

tw (hist x1) (kdensity x1 [aw=_tau1], lcolor(navy)) (kdensity x1 [aw=_tau2], ///
lcolor(maroon)) (kdensity x1 [aw=_tau3], lcolor(forest_green)), ///
legend(rows(1)) ///
legend(order(1 "Observed PDF" 2 "comp.1" 3 "comp.2" 4 "comp.3")) ///
saving(gg1,replace) title(x1)

tw (hist x2) (kdensity x2 [aw=_tau1], lcolor(navy)) (kdensity x2 [aw=_tau2], ///
lcolor(maroon)) (kdensity x2 [aw=_tau3], lcolor(forest_green)), ///
legend(rows(1)) ///
legend(order(1 "Observed PDF" 2 "comp.1" 3 "comp.2" 4 "comp.3")) ///
saving(gg2,replace) title(x2)

tab map group
tw (scatter x1 x2 if map==1) (scatter x1 x2 if map==2) ///
(scatter x1 x2 if map==3), ///
legend(order (1 "CWM Comp. 1" 2 "CWM Comp. 2" 3 "CWM Comp. 3")) ///
legend( rows(1)) title(Artificial Data) subtitle(Estimated components)
graph combine g1.gph g2.gph g3.gph, rows(1) ycommon

/*******************************************************************************
								The gsem_mixture dataset
*******************************************************************************/


webuse gsem_mixture, clear
set seed 435162
***supplying the same starting values to cwmgl and fmm
gen start=rbinomial(1,.5)
replace start=1+start
quietly tab start, gen(class)
cwmglm drvisits private medicaid c.age##c.age actlim chronic, ///
family(poisson) k(2)  posterior(tau) start(custom) initial(class1 class2)
predict map_cwm

fmm 2, emopts(iterate(500))   startvalues(classid start): ///
poisson drvisits private medicaid c.age##c.age actlim chronic
predict z1,  classposteriorpr class(1)
predict z2,  classposteriorpr class(2)
estat lcprob
estat ic


cap drop map_fmm
corr z1 tau1

tw (scatter z1 tau1) (function y=x), ///
ytitle(CWM posterior probability) xtitle(FMM posterior probability) ///
title(class 1) legend(off) saving(g1,replace) subtitle({&rho}=0.992)
tw (scatter z2 tau2) (function y=x), ///
ytitle(CWM posterior probability) xtitle("FMM posterior probability") ///
title(class 2)  legend(off) saving(g2,replace) subtitle({&rho}=0.992)

gen map_fmm=cond(z1>z2,1,2)


tab map_fmm map_cwm


graph combine g1.gph g2.gph
