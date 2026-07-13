{smcl}
{* *! version 1.0.0  12jul2026  Dr Merwan Roudane}{...}
{vieweralsosee "xtbchpanel" "help xtbchpanel"}{...}
{viewerjumpto "Model" "xtbchpanel_methods##model"}{...}
{viewerjumpto "Deviation regressor" "xtbchpanel_methods##dev"}{...}
{viewerjumpto "Estimators" "xtbchpanel_methods##est"}{...}
{viewerjumpto "Step-to-equation map" "xtbchpanel_methods##map"}{...}
{viewerjumpto "Compatibility notes" "xtbchpanel_methods##notes"}{...}
{title:Methods and formulas for xtbchpanel}

{marker model}{...}
{title:1. Model (general)}

{pstd}
For unit i, {cmd:xtbchpanel} fits by OLS the dynamic heterogeneous ARDL(p,q) model with any
number of regressors x_k, and (optionally) a common-correlated-effects control:

{p 8 8 2}y(i,t) = a(i) + {&Sigma}(l=1..p) {&phi}(i,l) y(i,t-l)
+ {&Sigma}(k) {&Sigma}(l=0..q) {&beta}_k(i,l) x_k(i,t-l)
[+ {&gamma}(i) cce(i,t-1)] + u(i,t).{p_end}

{pstd}
The long-run effect of each regressor k is

{p 8 8 2}{bf:theta_k(i) = [ {&Sigma}(l=0..q) {&beta}_k(i,l) ] / [ 1 - {&Sigma}(l=1..p) {&phi}(i,l) ]},{p_end}

{pstd}
and the estimators below average theta_k(i) across units (one long-run coefficient per
regressor). With {opt difference}, every model variable enters in first differences; with
{opt cce} or {opt world()} the control cce(i,t-1) is a one-period-lagged cross-section average
of the dependent (or the user's series), which renders the cross-unit errors weakly rather
than strongly dependent (Chudik & Pesaran 2015).

{marker dev}{...}
{title:2. Climate-deviation mode (optional; Centorrino et al. 2026 / Kahn et al. 2021)}

{pstd}
When {opt ma()} and {opt mavars()} are given, each named regressor is first replaced by its
annualized absolute deviation from an m-year backward moving average,

{p 8 8 2}x(i,t;m) = (2/(m+1)) * | x(i,t) - (1/m) {&Sigma}(j=1..m) x(i,t-j) |,{p_end}

{pstd}
built on levels, before any {opt difference}. The factor 2/(m+1) annualizes the deviation
from the norm; larger m encodes slower adaptation. Combined with {opt difference} (growth) and
{opt cce} (world-growth term), this reproduces the climate-macro specification exactly, and one
table column is produced per norm window m. Outside this mode the regressors enter untransformed
and the command is a general long-run panel estimator.

{marker est}{...}
{title:3. Estimators and variances}

{pstd}{bf:MG} (Pesaran & Smith 1995):
theta_MG = mean(theta(i)); Var = [1/(n(n-1))] {&Sigma}(theta(i)-theta_MG)^2.{p_end}

{pstd}{bf:HPJ-MG} (ordering A, Chudik & Pesaran 2015): split each unit's time series in
half, obtain theta^1i and theta^2i, and form
theta~(i) = 2*theta^(i) - 0.5(theta^1i + theta^2i); then average with the Pesaran-Smith SE
of theta~(i). This SE is algebraically identical to the paper's
4Var(theta^)+0.25(Var1+Var2+2Cov12)-2Cov(1,.)-2Cov(2,.) expression.{p_end}

{pstd}{bf:BC1} (Kiviet & Phillips 1993 COLS, ordering with short-run correction): for each
unit the O(T^-1) bias of the OLS coefficient vector a=({&phi},{&beta}') is

{p 8 8 2}B_a = -s2 * Dh^-1 [ Zbar'*C*Zbar*Dh^-1*e1 + tr(Zbar'*C*Zbar*Dh^-1)*e1
+ 2*s2*(e1'*Dh^-1*e1)*tr(C*C'*C)*e1 ],{p_end}

{p 8 8 2}Dh = Zbar'Zbar + s2*tr(C'C)*e1*e1', Zbar = [y0*F + C*X*bhat : X],{p_end}

{pstd}with C the strictly lower-triangular matrix C[t,s]={&phi}^(t-1-s), F=[1,{&phi},...,
{&phi}^(T-1)]', e1 the first unit vector; the corrected vector is a~ = a^ - B_a and
theta(i) is recomputed from a~. (Theorem 7 / eq. 26.){p_end}

{pstd}{bf:BC2} (Pesaran & Zhao 1999, ordering B): each unit's short-run vector is bias-
corrected by the Autoregressive Wild Bootstrap of Smeekes & Urbain (2014) --
xi(t)={&rho}*xi(t-1)+sqrt(1-{&rho}^2)*z(t), errors e*(t)=xi(t)*e^(t), the dynamic series is
regenerated recursively and re-estimated on every replication (explosive draws discarded).
b~(i) = 2*b^(i) - mean(b*(i)); the MG long-run is formed from the averaged corrected short-
run, with the delta-method variance J'*Sigma_MG*J.{p_end}

{pstd}{bf:BC3} (HPJ, ordering C): b~(i) = 2*b^(i) - 0.5(b^1i + b^2i) on the short-run
vector; theta(i) from b~(i); then averaged.{p_end}

{pstd}{bf:TMG} ({it:preferred}; Pesaran & Yang 2024, eq. 4.5 & Theorem 2): with
d(i)=det(W(i)'W(i)), a_n = C_n * n^(-1/3), C_n = mean(d(i)),
delta(i)=(d(i)/a_n - 1)*1(d(i)<=a_n),
theta~(i)=(1+delta(i))*theta^(i), and

{p 8 8 2}theta_TMG = (1/n) {&Sigma} (1+delta(i))/(1+deltabar) * theta^(i),
{space 3}Var = (1/n^2) {&Sigma} (theta~(i) - theta_TMG)^2.{p_end}

{pstd}{bf:HPJ-FE} (pooled benchmark; Chudik-Pesaran-Yang 2018): country fixed effects are
absorbed by the within transform (no world term, matching Eq. 1);
beta~ = 2*beta^ - 0.5(beta_a + beta_b), and the Proposition-4 sandwich
Var(beta~)=Q^-1 R Q^-1 / (NT) with R=[1/NT]{&Sigma} d*(it) d*(it)' u^2(it) and the FE-only
d*(it) construction; the long-run SE follows by the delta method.{p_end}

{marker map}{...}
{title:4. Step-to-equation map (faithfulness)}

{synoptset 30 tabbed}{...}
{synopt:{bf:code step}}{bf:paper reference}{p_end}
{synoptline}
{synopt:deviation regressor x(i,s;m)}Centorrino et al. Eq. p.6{p_end}
{synopt:ARDL(p,q)-in-D + CCE term}Eq. 2{p_end}
{synopt:theta(i)=sum(beta)/(1-sum(phi))}p.5{p_end}
{synopt:MG + Pesaran-Smith SE}Pesaran & Smith (1995){p_end}
{synopt:HPJ-MG jackknife + variance}p.6-7; Chudik & Pesaran (2015){p_end}
{synopt:BC1 COLS bias vector}Kiviet & Phillips (1993) Thm 7, eq. 26{p_end}
{synopt:BC2 AWB bootstrap + delta SE}Pesaran & Zhao (1999); Smeekes & Urbain (2014); p.7{p_end}
{synopt:BC3 short-run jackknife}Table 2 note (HPJ, ordering C){p_end}
{synopt:TMG trimming + Thm-2 variance}Pesaran & Yang (2024) eq. 4.5, Thm 2; p.8{p_end}
{synopt:HPJ-FE within + Prop-4 SE}Chudik-Pesaran-Yang (2018) eq. 12, Prop. 4; Table 1{p_end}
{synoptline}

{marker notes}{...}
{title:5. Compatibility notes and practical guidance}

{phang}o {bf:Validation.} The shipped {cmd:xtbchpanel_example.do} simulates a dynamic
heterogeneous panel with KNOWN country long-run effects; the MG family recovers the true
cross-country mean to 2-3 decimals (e.g. -1.407 vs a truth of -1.408).{p_end}

{phang}o {bf:BC1 scope.} The Kiviet-Phillips COLS is exact for a single lagged dependent
variable (p=1, the paper's specification). For p>1 the command falls back to a leading-order
correction of the autoregressive coefficient and reports it as such.{p_end}

{phang}o {bf:HPJ-FE reproduces Eq. 1}, i.e. the homogeneous benchmark with country fixed
effects and NO world-growth term. It is expected to differ from the heterogeneous estimators
-- that divergence is the paper's central point, not an error. With an uncontrolled
persistent common factor it can be badly biased (the factor loads onto the lagged dependent
variable); use the heterogeneous estimators with the CCE / {opt world()} control.{p_end}

{phang}o {bf:TMG is preferred.} Under correlated heterogeneity and near-singular unit
designs, MG is high-variance and outlier-sensitive; TMG shrinks unreliable units and is the
recommended summary.{p_end}

{phang}o {bf:Data needs.} Per-unit OLS requires enough usable time observations after
forming the m-year norm, differencing, and lagging; units with fewer than (regressors+2)
usable points are dropped from that cell. Longer m needs longer series.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
