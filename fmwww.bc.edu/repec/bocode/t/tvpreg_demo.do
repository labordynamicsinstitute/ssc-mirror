global exportpath "/Users/lingyunzhou/Library/CloudStorage/Dropbox/2024_TVPLPIV Stata Package/code/results"
// global exportpath "/Users/lingyunzhou/Library/CloudStorage/Dropbox/应用/Overleaf/tvpreg"
global workpath "/Users/lingyunzhou/Library/CloudStorage/Dropbox/2024_TVPLPIV Stata Package/code"
// global exportpath "/Users/yiru/Dropbox/2024_TVPLPIV Stata Package/code/results"
// global workpath "/Users/yiru/Dropbox/2024_TVPLPIV Stata Package/code"

cd "$workpath"
set seed 1234

* Create log file
cap log close demo
cap rm "demo.log"
log using "demo.log", name(demo)

graph drop _all
set scheme sj

* Estimator I: TVP-VAR (Monetary Policy)
// Step 1:  Import the data
use data_MP.dta, clear
tsset time
// Step 2: Create the C grid
* Input correct # of parameters
mata: ny = 3; nlag = 2; ncons = 1
* Input C grids for different blocks of parameters
mata: cB = (0.6*(0::5))'; ca = (1.2*(0::5))'; cl = (3*(0::5))'
* Automatic calculations
mata: nB = ny * (ny * nlag + ncons)
mata: na = ny * (ny - 1) / 2; nl = ny
mata: ncB = cols(cB); nca = cols(ca); ncl = cols(cl)
mata: cB = cB # J(1,nca*ncl,1)
mata: ca = J(1,ncB,1) # ca # J(1,ncl,1)
mata: cl = cl = J(1,ncB*nca,1) # cl
mata: cmat = (J(nB,1,1) # cB) \ (J(na,1,1) # ca) \ (J(nl,1,1) # cl)
mata: st_matrix("cmat",cmat)
// Step 3: Estimate the TVP-VAR model
tvpreg pi urate irate if time <= yq(2005,4), var varlag(1/2) level(90) ///
cmatrix(cmat) chol nhor(0/20)
// Step 4: Plot the estimation results
gen period = 0
replace period = 1 if time == yq(1975,1) | time == yq(1981,1) | ///
time == yq(1996,1) // Prepare time indicator for figures
tvpplot, plotvarirf(pi:pi pi:urate pi:irate urate:pi urate:urate ///
urate:irate irate:pi irate:urate irate:irate) plotconst period(period) ///
name(figure1_1) periodlegend(1975Q1, 1981Q1, 1996Q1) tvpcolor(gray)
tvpplot, plotcoef(pi:L.pi pi:L.urate pi:L.irate urate:L.pi urate:L.urate ///
urate:L.irate irate:L.pi irate:L.urate irate:L.irate) name(figure1_2) ///
tvpcolor(gray)
tvpplot, plotcoef(l1) name(figure1_3) tvpcolor(gray) ///
title("Log standard deviation of shocks in inflation equation")
tvpplot, plotcoef(l2) name(figure1_4) tvpcolor(gray) ///
title("Log standard deviation of shocks in unemployment equation")
tvpplot, plotcoef(l3) name(figure1_5) tvpcolor(gray) ///
title("Log standard deviation of shocks in interest rate equation")
// Step 5: Save the estimation results as new variables
predict pihat uhat ihat, xb y(pi urate irate)
predict pires ures ires, residual y(pi urate irate)
predict coef_pi_l1urate, coef(pi:L.urate)
predict irf1_pi_urate, varirf(pi:urate) h(1)

* Estimator II: TVP-LP (Government spending to a one-unit news shock)
// Step 1:  Import the data
use data_Fiscal.dta, clear
tsset time
// Step 2: Create the C grid
mat define cmat = (0,3,6,9,12,15)
// Step 3: Estimate the TVP-LP model
tvpreg gs shock gs_l* gdp_l* shock_l*, newey cmatrix(cmat) nhor(0/19) chol ///
getband
// Step 4: Plot the estimation results
tvpplot, plotcoef(gs:shock) plotconst name(figure2_1) tvpcolor(gray)
tvpplot, plotcoef(gs:shock) period(recession) name(figure2_2) tvpcolor(gray)
tvpplot, plotcoef(gs:shock) plotnhor(1) plotconst name(figure2_3) ///
tvpcolor(gray)
tvpplot, plotcoef(gs:shock) plotnhor(1) period(recession) name(figure2_4) ///
tvpcolor(gray)
// Step 5: Save the estimation results as new variables
predict gshat, xb h(0)
predict gsres1, residual h(1)
predict coef2_gs_shock, coef(gs:shock) h(2)

* Estimator III: TVP-LP-IV (Fiscal multiplier)
// Step 1:  Import the data
use data_Fiscal.dta, clear
tsset time
// Step 2: Create the C grid
* Input correct # of parameters
mata: ny = 1; nx = 1; nz1 = 13; nz2 = 1
* Input C grids for different blocks of parameters
mata: cB = (3*(0::5))'; cv = (3*(0::5))'
* Automatic calculations 
mata: nz = nz1 + nz2
mata: nB = nx * nz + ny * nx + ny * nz1
mata: nv = (nx + ny) * (nx + ny + 1) / 2
mata: ncB = cols(cB); ncv = cols(cv)
mata: cB = cB # J(1,ncv,1); cv = J(1,ncB,1) # cv
mata: cmat = (J(nB,1,1) # cB) \ (J(nv,1,1) # cv)
mata: st_matrix("cmat",cmat)
// Step 3: Estimate the TVP-LP-IV model
tvpreg gdp gs_l* gdp_l* shock_l* (gs = shock), cmatrix(cmat) nwlag(8) ///
nhor(4/20) cum
// Step 4: Plot the estimation results
tvpplot, plotcoef(gdp:gs) period(recession) name(figure3_1) tvpcolor(gray)
tvpplot, plotcoef(gdp:gs) plotnhor(8) name(figure3_2) tvpcolor(gray)
// Step 5: Save the estimation results as new variables
predict gdphat4, xb h(4) y(gdp)
predict gsres8, residual h(8) y(gs)
predict coef4_gdp_gs, coef(gdp:gs) h(4)

* Estimator IV: TVP-weakIV (Phillips curve with weak instruments)
// Step 1:  Import the data
use data_PC_weak.dta, clear
tsset time
// Step 2: Create the C grid
mat define cmat = (0, 1, 2, 3, 4, 5)
// Step 3: Estimate the TVP-weakIV model
tvpreg pi pib (x pif = x_l*), weakiv cmatrix(cmat) level(90) nwlag(19) ///
 getband nodisplay
// Step 4: Plot the estimation results
tvpplot, plotcoef(pi:x) movavg(7) name(figure4_1) tvpcolor(gray)
tvpplot, plotcoef(pi:pif) movavg(7) name(figure4_2) tvpcolor(gray)
tvpplot, plotcoef(pi:pib) movavg(7) name(figure4_3) tvpcolor(gray)
// Step 5: Save the estimation results as new variables
predict pihat, xb
predict coef_pi_x, coef(pi:x)

* Export the graphs
graph dir
foreach v in `r(list)' {
	graph display `v'
	graph export "$exportpath/`v'.eps", as(eps) replace
}

graph drop _all

log close demo
