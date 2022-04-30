*! Date    : 28 Apr 2022
*! Version : 1.01
*! Author  : Adrian Mander
*! Email   : mandera@cardiff.ac.uk
*! A command that is a clinical trials simulator

/*
16Jul21 v1.00 The command is born
28Apr22 v1.01 the nearly final version of the command
*/

/* START HELP FILE
title[A clinical trial simulator]

desc[
 {cmd:tacts} simulates data from different types of trial and summarises the results.
]

opt[data() specifies the data generating commands.]
opt[analysis() specifies the analysis commands.]
opt[output() specifies what is saved for each simulation.]
opt[ss() specifies the sample sizes for each stage of the design.]
opt[decision() specifies what decisions are made at each interim analysis.]
opt[outputsummary() specifies commands used on the final simulated dataset.]
opt[nsims() specifies the number of simulations to carry out.]
opt[setup() specifies a set of commands to run at the start of the simulation.]
opt[saving() specifies the name of the final dataset.]
opt[replace specifies whether to replace the final saved dataset.]
opt[seed() specifies the random number seed.]


example[

{p}
The first example is a two-arm parallel group trial, the treatment indicator is
x and outcome variable y is normally distributed (conditional on x) and
there is a difference of 2.6 between the two groups. The output is
whether the p-value from the t-test is below 5% and the sample size is 400. 

{phang}{stata tacts, data(x~fixed(0.5, 0.5); y~N(2.6*x, 8);) analysis(ttest y, by(x);) output(power = {r(p)} < 0.05;) ss(n=400) nsims(5000) saving(results) replace seed(1)}

{p}
The second example is the same trial but the outcome is simulated under no
difference between the two arms.

{phang}{stata tacts, data(x~fixed(0.5, 0.5); y~N(0, 8);) analysis(ttest y, by(x);) output(type = {r(p)} < 0.05;) ss(n=400) nsims(5000) saving(results) replace seed(2) }

{p}
Lastly this command has the same trial with the mean difference between the 
groups as 2.6 but now uses linear regression and estimates various statistics
at the end of the simulation.

{phang}{stata tacts, data(x~fixed(0.5, 0.5); y~N(2.6*x, 8);) analysis(reg y x; test x;) output(power = {r(p)} < 0.05; slope = _b[x];) ss(n=400) nsims(5000) seed(1) outputsummary(Bias = slope1-2.6; Power=power1; MSE=(slope1-2.6)^2;) }

{p}
The following examples show different designs with a small description but it does
not cover all the aspects of the code but they can be easily adapted.

{title:Group sequential design stopping only for efficacy}

{p}
A group sequential design with two  interim analyses and only stopping for efficacy under the 
alternative hypothesis.

{phang} tacts, ss(n=100 n=200 n=400) nsims(10000) data(x~fixed(0.5, 0.5);y~N(2.6*x, 8);) 
analysis(reg y x;) decision(n=100: stoptrialE if _b[x]/_se[x]> 2.5; 
n=200: stoptrialE if _b[x]/_se[x]> 2.2; n=400: stoptrialE if _b[x]/_se[x]> 2;) 
output(stop = {stoptrialE}; ttest = _b[x]/_se[x]; slope=_b[x];) 
outputsummary(Power=(stop1==1)+(stop2==1)+(stop3==1);PET=(stop1==1)+(stop2==1); 
ESS_H1=100*(stop1==1)+200*(stop2==1)+400*(stop1==0)*(stop2==0); 
Bias=cond(stop1==1,slope1-2.6,cond(stop2==1,slope2-2.6,slope3-2.6));) seed(1)

{p}
The same group sequential design as previous but under the null hypothesis, so as to
calculate the type 1 error.

{phang}
tacts, ss(n=100 n=200 n=400) nsims(10000) data(x~fixed(0.5, 0.5);y~N(0, 8)) 
analysis(reg y x; test x) decision(n=100: stoptrialE if _b[x]/_se[x]> 2.5; 
n=200: stoptrialE if _b[x]/_se[x]> 2.2; n=400: stoptrialE if _b[x]/_se[x]> 2;) 
output(stop = {stoptrialE}; ttest = _b[x]/_se[x]; slope=_b[x];) 
outputsummary(Power=(stop1==1)+(stop2==1)+(stop3==1);PET=(stop1==1)+(stop2==1); 
ESS_H1=100*(stop1==1)+200*(stop2==1)+400*(stop1==0)*(stop2==0); 
Bias=cond(stop1==1,slope1,cond(stop2==1,slope2,slope3));) seed(2)

{title: Survival analysis sample size calculations}

{p} 
A two-arm parallel groups trial with a survival endpoint.

{phang}
tacts, nsims(50000) ss(n=124) data(x~fixed(0.5,0.5); timein~U(0,18); 
S~Exp(1/(0.65*ln(2)/5.4*x+ln(2)/5.4*(1-x))); 
timeout= cond(timein+S < 24,timein+S,24); D= timeout < 24;) 
analysis(stset timeout, failure(D) origin(time timein); count if D==1; 
local E=r(N); count if D==1 & x==1; local E1=r(N);count if D==1 & x==0; 
local E0=r(N); sts test x; local pv=chi2tail(r(df), r(chi2)); stcox x;) 
output(pv ={pv}; lhr= _b[x]; ttest= _b[x]/_se[x]; nevents= {E}; n1events= {E1}; 
n0events= {E0};) outputsummary( HR= exp(lhr1); Bias= exp(lhr1)-0.65; 
Power= ttest < -0.8416; Power_rank= (pv1<0.4); Deaths= nevents1; 
Pr_E= nevents1/124; Pr_S1= (62-n1events1)/62; Pr_S0= (62-n0events1)/62;) seed(1)

{title: Co-primary endpoints}

{p}
A trial with three outcome variables generated under a multivariate normal distribution.
The outputs are various different definitions of power: marginal,conjunctive and disjunctive.

{phang}
mat SigmaInd = ( 1, 0, 0 \ 0, 1, 0 \ 0, 0, 1)

{phang}
tacts, nsims(10000) ss(n=1050) data(x~fixed(0.5,0.5); 
y~MVN((0.2*x, 0.2*x, 0.2*x), SigmaInd)) analysis(reg y1 x;test x;local pv1=r(p); 
reg y2 x; test x; local pv2=r(p); reg y3 x; test x; local pv3=r(p);) 
 output(Marg_pow1=({pv1}<0.01667);Marg_pow2=({pv2}<0.01667); 
 Marg_pow3=({pv3}<0.01667); 
 Disjpower = (({pv1}<0.01667) | ({pv2}<0.01667) | ({pv3}<0.01667)); 
 Conjpower = ({pv1}<0.01667)*({pv2}<0.01667)*({pv3}<0.01667); 
 Holm_power = 
 (({pv1}<0.01667)*({pv2}<0.0333)*({pv3}<0.05)+({pv1}<0.01667)*({pv3}<0.0333)* 
 ({pv2}<0.05)+({pv2}<0.01667)*({pv1}<0.0333)*({pv3}<0.05)+({pv2}<0.01667)* 
 ({pv3}<0.0333)*({pv1}<0.05)+ ({pv3}<0.01667)*({pv1}<0.0333)*({pv2}<0.05)+ 
 ({pv3}<0.01667)*({pv2}<0.0333)*({pv1}<0.05))>0;) 
 seed(1)
 
 {phang} 
 mat Sigma = ( 1, 0.5, 0.5 \ 0.5, 1, 0.5 \ 0.5, 0.5, 1) 
 
 {phang}
 tacts, nsims(10000) ss(n=1050) data(x~fixed(0.5,0.5); 
y~MVN((0.2*x, 0.2*x, 0.2*x), Sigma)) analysis(reg y1 x;test x;local pv1=r(p); 
reg y2 x; test x; local pv2=r(p); reg y3 x; test x; local pv3=r(p);) 
 output(Marg_pow1=({pv1}<0.01667);Marg_pow2=({pv2}<0.01667); 
 Marg_pow3=({pv3}<0.01667); 
 Disjpower = (({pv1}<0.01667) | ({pv2}<0.01667) | ({pv3}<0.01667)); 
 Conjpower = ({pv1}<0.01667)*({pv2}<0.01667)*({pv3}<0.01667); 
 Holm_power = 
 (({pv1}<0.01667)*({pv2}<0.0333)*({pv3}<0.05)+({pv1}<0.01667)*({pv3}<0.0333)* 
 ({pv2}<0.05)+({pv2}<0.01667)*({pv1}<0.0333)*({pv3}<0.05)+({pv2}<0.01667)* 
 ({pv3}<0.0333)*({pv1}<0.05)+ ({pv3}<0.01667)*({pv1}<0.0333)*({pv2}<0.05)+ 
 ({pv3}<0.01667)*({pv2}<0.0333)*({pv1}<0.05))>0;) 
 seed(1)
 
{title: Longitudinal group sequential trial design}

{p}
Similar code to the previous but now the multivariate normal distribution 
is used to generate longitudinal dataset.  Note the use of recruitment time and
that the interims are specified using the ss() option

{phang}
 mat Sig=(1,0,0,0,0\ 0,1,0,0,0\ 0,0,1,0,0\ 0,0,0,1,0\ 0,0,0,0,1)
 
 {phang}
 tacts, nsims(1000) ss(n=120,itime<=20 itime<=36) data(x~fixed(0.66667,0.33333); 
 y~MVN((0,0.1*x-0.1,0.2*x-0.2,0.3*x-0.3,0.4-0.7*x),Sig);ui~N(0,1);timein~U(0,24); 
 yy0=y1+ui;yy3=y2+ui;yy6=y3+ui;yy9=y4+ui;yy12=y5+ui; id=_n; 
 itime3=3+timein;itime6=6+timein;itime9= 9+timein;itime12=12+timein; 
 reshape long yy itime, i(id) j(time);) 
 analysis(xtmixed yy i.time#i.x, nocons || id:; local obs = e(N); 
 cap test [yy]12.time#1.x = [yy]12.time#0.x; 
 local rerror = _rc; 
 local p1=r(p); local trteff = _b[yy:12.time#1.x] - _b[yy:12.time#0.x];) 
 output(p = {p1}; nobs = {obs}; trteff = {trteff}; error={rerror};) 
 decision(itime<=20: stoptrial if {p1}>0.5;)  
 outputsummary(Power = p2<0.05; Eobs = cond(nobs2==.,nobs1, nobs2); 
 Trt = cond(nobs2==.,trteff1, trteff2);) seed(1)
 
{title:  Sample size re-estimation}

{p}
An example of a blinded sample size re-estimation for a two-arm parallel groups trial

{phang}
 tacts, ss(n=199 n=398) nsims(10000) data(x~fixed(0.5, 0.5); y~N(-2.6*x,8)) 
 analysis(reg y x; 
 local maxn = ceil(2*(invnorm(0.975)+invnorm(0.9))^2*2*(e(rmse)^2)/(2.6^2)); 
 local SS=e(N); test x;) output(pv = {r(p)}; maxn= {maxn}; ss = {SS};) 
 decision(n=199: SSR local n2 = {maxn}; stoptrialE if {maxn}<=199;) 
 outputsummary(Power = pv2<0.05; maxn=maxn1; final_ss=ss2;) seed(1)
 
 {p}
 Generating under the null distribution to get the type 1 error of the previous trial design.
 
 {phang}
 tacts, ss(n=199 n=398) nsims(10000) data(x~fixed(0.5, 0.5); y~N(0,8)) 
 analysis(reg y x; 
 local maxn = ceil(2*(invnorm(0.975)+invnorm(0.9))^2*2*(e(rmse)^2)/(2.6^2)); 
 local SS=e(N); test x;) output(pv = {r(p)}; maxn= {maxn}; ss = {SS};) 
 decision(n=199: SSR local n2 = {maxn}; stoptrialE if {maxn}<=199;) 
 outputsummary(Power = pv2<0.05; maxn=maxn1; final_ss=ss2;) seed(1)

 {p} 
 Generating data that is less variable than planned to show the efficiency gain
 in sample size re-estimation.
 
 {phang}
 tacts, ss(n=199 n=398) nsims(10000) data(x~fixed(0.5, 0.5); y~N(-2.6*x,6)) 
 analysis(reg y x; 
 local maxn = ceil(2*(invnorm(0.975)+invnorm(0.9))^2*2*(e(rmse)^2)/(2.6^2)); 
 local SS=e(N); test x;) output(pv = {r(p)}; maxn= {maxn}; ss = {SS};) 
 decision(n=199: SSR local n2 = {maxn}; stoptrialE if {maxn}<=199;) 
 outputsummary(Power = cond(maxn1>199, pv2<0.05, pv1<0.05); PET= (maxn1<=199); 
 final_ss= cond(maxn1>199,ss2, ss1);) seed(1)

{title: Response adaptive randomisation  }

{p}
An example of altering the allocation ratios at a single interim analysis in a four-arm
trial.

{phang}
 tacts, ss(n=200 n=584) nsims(10000) setup(local p0 0.25; local p1 0.25; 
 local p2 0.25; local p3 0.25;) data(x~fixed({p0},{p1},{p2},{p3}); 
 x1=x==1; x2=x==2; x3=x==3; y~N(-1*x1-0.5*x2-2.6*x3, 6)) 
 analysis(reg y x1 x2 x3; test x1; local pv1=r(p); test x2; local pv2=r(p); 
 test x3; local pv3=r(p); count if x1==1; local N1=r(N); count if x2==1; 
 local N2=r(N); count if x3==1; local N3=r(N); count if x1==0&x2==0&x3==0; 
 local N0 = r(N);) 
 output(n_x0={N0}; n_x1={N1}; n_x2={N2}; n_x3={N3}; pv_x1={pv1}; pv_x2={pv2}; 
  pv_x3={pv3};) 
 decision(n=200: RAR local p1=0.75*(1-{pv1})/(3-{pv1}-{pv2}-{pv3}); 
 RAR local p2=0.75*(1-{pv2})/(3-{pv1}-{pv2}-{pv3}); 
 RAR local p3=0.75*(1-{pv3})/(3-{pv1}-{pv2}-{pv3});)  
 outputsummary(Power1=pv_x12<0.01666; Power2=pv_x22<0.01666; Power3=pv_x32<0.01666; 
 Stage2_SS_0=n_x02; Stage2_SS_1=n_x12; Stage2_SS_2=n_x22; Stage2_SS_3=n_x32;) seed(1)

{title: Drop the loser design }

{p}
A drop the loser design under the alternative hypothesis

{phang}
 local final_bound = 1.978
 
 {phang}
 tacts, ss(n=240 n=360)  nsims(10000) 
  setup(local p0 0.25; local p1 0.25; local p2 0.25; local p3 0.25;) 
  data(x~fixed({p0},{p1},{p2},{p3}); x1=x==1; x2=x==2; x3=x==3; y~N(2.6*x1,6)) 
  analysis(reg y x1 x2 x3; local tt1=_b[x1]/_se[x1]; local tt2=_b[x2]/_se[x2]; 
  local tt3 = _b[x3]/_se[x3]; count if x1==1; local N1=r(N); count if x2==1; 
  local N2=r(N); count if x3==1; local N3=r(N); count if x1==0&x2==0&x3==0; 
  local N0 = r(N);) 
  output(n_x0={N0}; n_x1={N1}; n_x2={N2}; n_x3={N3}; tt1={tt1}; tt2={tt2}; 
  tt3={tt3};) 
  decision(n=240: droparm ({tt1}<{tt2} | {tt1}<{tt3}) local p1=0; 
  droparm ({tt2}<{tt1} | {tt2}<{tt3}) local p2=0; 
  droparm ({tt3}<{tt1} | {tt3}<{tt2}) local p3=0;) 
  outputsummary( 
  Disjpower = ((tt12>`final_bound')|(tt22>`final_bound')|(tt32>`final_bound')); 
  Marg_power1 = tt12>`final_bound'; Marg_power2 = tt22>`final_bound'; 
  Marg_power3 = tt32>`final_bound'; Stage2_SS_0=n_x02; Stage2_SS_1=n_x12; 
  Stage2_SS_2=n_x22; Stage2_SS_3=n_x32;) seed(1)

{p}
The same drop the loser design under the null hypothesis.

{phang}
 local final_bound = 1.978
 
 {phang}
 tacts, ss(n=240 n=360)  nsims(10000) 
  setup(local p0 0.25; local p1 0.25; local p2 0.25; local p3 0.25;) 
  data(x~fixed({p0},{p1},{p2},{p3}); x1=x==1; x2=x==2; x3=x==3; y~N(0,6)) 
  analysis(reg y x1 x2 x3; local tt1=_b[x1]/_se[x1]; local tt2=_b[x2]/_se[x2]; 
  local tt3 = _b[x3]/_se[x3]; count if x1==1; local N1=r(N); count if x2==1; 
  local N2=r(N); count if x3==1; local N3=r(N); count if x1==0&x2==0&x3==0; 
  local N0 = r(N);) 
  output(n_x0={N0}; n_x1={N1}; n_x2={N2}; n_x3={N3}; tt1={tt1}; tt2={tt2}; 
  tt3={tt3};) 
  decision(n=240: droparm ({tt1}<{tt2} | {tt1}<{tt3}) local p1=0; 
  droparm ({tt2}<{tt1} | {tt2}<{tt3}) local p2=0; 
  droparm ({tt3}<{tt1} | {tt3}<{tt2}) local p3=0;) 
  outputsummary( 
  FWER = ((tt12>`final_bound')|(tt22>`final_bound')|(tt32>`final_bound')); 
  Stage2_SS_0=n_x02; Stage2_SS_1=n_x12; Stage2_SS_2=n_x22; Stage2_SS_3=n_x32;) 
  seed(1)

{title: MAMS design  }

{p}
A MAMS design with two experimental arms and a single control arm, the trial stops 
as soon as any test associated with the experimental arms crosses a boundary.

{phang}
 tacts, nsims(10000) ss(n=132 n=264 n=396)  
  setup( local p0 = 0.5; local p1=0.25; local p2 = 0.25;) 
  data(x~fixed({p0}, {p1}, {p2}); x1=x==1; x2=x==2; y~N(2.6*x1, 6)) 
  analysis(reg y x1 x2; local N= {e(N)}; local in1 = r(N); count if x1==1; 
  local in1 = r(N); count if x2==1; local in2 = r(N); local tt1 = _b[x1]/_se[x1]; 
  local tt2 = _b[x2]/_se[x2];) 
  output(tt_x1 = {tt1}; tt_x2 = {tt2}; stop={stoptrial}; N={N};) 
  decision( 
  n=132: droparm ({tt1} < -2.27) local p1=0; local n2={n2}-33; local n3={n3}-66; 
  n=132: droparm ({tt2} < -2.27) local p2=0; local n2={n2}-33; local n3={n3}-66; 
  n=132: stoptrial if ({tt1}>2.27 | {tt2}>2.27);   
  n=132: stoptrial if ({tt1}<-2.27 & {tt2}<-2.27); 
  n=264: droparm ({tt1} < -2.27 & {in1}==66) local p1=0; local n3={n3}-33; 
  n=264: droparm ({tt2} < -2.27 & {in2}==66) local p2=0; local n3={n3}-33; 
  n=264: stoptrial if ({tt1}>2.27 | {tt2}>2.27);   
  n=264: stoptrial if ({tt1}<-2.27 & {tt2}<-2.27); 
  ) 
  outputsummary(Marg_power1=tt_x11>2.27 | (tt_x12>2.27 & tt_x12~=.) | 
  (tt_x13>2.27 & tt_x13~=.); 
  Marg_power2=tt_x21>2.27| (tt_x22>2.27 & tt_x22~=.) | (tt_x23>2.27 & tt_x23~=.); 
  Disjpower=tt_x11>2.27 | (tt_x12>2.27 & tt_x22~=.) | (tt_x13>2.27 & tt_x13~=.) 
  | tt_x21>2.27 |  (tt_x22>2.27 & tt_x22~=.) | (tt_x23>2.27 & tt_x23~=.); 
  SS = cond(N2==.,N1,cond(N3==.,N2,N3)); n2=N2; n3=N3;) seed(1)
 
 {p}
 The same MAMS design but now the study only stops if all experimental arms cross 
 boundaries
 
 {phang}
 tacts, nsims(10000) ss(n=128 n=256 n=384)  
  setup(local p0 0.5; local p1 0.25; local p2 0.25;) 
  data(x~fixed({p0}, {p1}, {p2}); x1=x==1; x2=x==2; y~N(2.6*x1, 6)) 
  analysis(reg y x1 x2; local N= {e(N)}; count if x1==1; local in1 = r(N); 
  count if x2==1; local in2=r(N); local tt1=_b[x1]/_se[x1]; 
  local tt2=_b[x2]/_se[x2];) 
  output(tt_x1={tt1}; tt_x2={tt2}; stop={stoptrial}; N={N}; IN1={in1}; IN2={in2};) 
  decision( 
  n=128:droparm ({tt1}>2.27|{tt1}<-2.27) local p1=0; local n2={n2}-32; local n3={n3}-64; 
  n=128:droparm ({tt2}>2.27|{tt2}<-2.27) local p2=0; local n2={n2}-32; local n3={n3}-64; 
  n=128:stoptrial if ({tt1}>2.27 & {tt2}>2.27); 
  n=128:stoptrial if ({tt1}<-2.27 & {tt2}<-2.27); 
  n=128:stoptrial if ({tt1}<-2.27 & {tt2}>2.27); 
  n=128:stoptrial if ({tt1}>2.27 & {tt2}<-2.27); 
  n=256:droparm (({tt1}>2.27|{tt1}<-2.27)&{in1}==64) local p1=0; local n3={n3}-32; 
  n=256:droparm (({tt2}>2.27|{tt2}<-2.27)&{in2}==64) local p2=0; local n3={n3}-32; 
  n=256:stoptrial if (({tt1}>2.27 | {in1}==32) & ({tt2}>2.27 | {in2}==32)); 
  n=256:stoptrial if (({tt1}<-2.27 | {in1}==32) & ({tt2}<-2.27 | {in2}==32)); 
  n=256:stoptrial if (({tt1}<-2.27 | {in1}==32) & ({tt2}>2.27 | {in2}==32)); 
  n=256:stoptrial if (({tt1}>2.27 | {in1}==32) & ({tt2}<-2.27 | {in2}==32)); 
  ) 
  outputsummary(Marg_power1=tt_x11>2.27 | (tt_x12>2.27 & tt_x12~=.) | 
  (tt_x13>2.27 & tt_x13~=.); 
  Marg_power2=tt_x21>2.27 | (tt_x22>2.27 & tt_x22~=.) | (tt_x23>2.27 & tt_x23~=.); 
  Disjpower=tt_x11>2.27 | (tt_x12>2.27 & tt_x12~=.) | (tt_x13>2.27 & tt_x13~=.) | 
  tt_x21>2.27 | (tt_x22>2.27 & tt_x22~=.) | (tt_x23>2.27 & tt_x23~=.); 
  SS = cond(N2==.,N1,cond(N3==.,N2,N3)); n2=N2; n3=N3;) seed(1)
]

author[Prof Adrian Mander]
institute[Cardiff University]
email[mandera@cardiff.ac.uk]

freetext[]

END HELP FILE */

program define tacts
 /* Allow use on earlier versions of stata that have not been fully tested */
  local version = _caller()
  if `version' < 17.0 {
    di "{err}WARNING: Tested only for Stata version 17.0 and higher."
    di "{err}Your Stata version `version' is not officially supported."
  }
  else {
    version 17.0
  }
  syntax, data(string) analysis(string) output(string) ss(string) [decision(string) outputsummary(string) nsims(real 1000) setup(string) saving(string) replace SEED(integer -1) ]
  
  if ("`seed'"~="-1")  set seed `seed'
  di
  di "{err}Note: datasets will be cleared when running this command"
  /*start of simulations */
  clear
  tempname results
  frame create `results'
  local interim_notss 0 /* this indicates if there are suboptions to ss, that are if statements */
/*****************    HANDLING the SS() option     ****************************/
  /* First of all check how many interim analyses there are and then loop over these interims and final stage */
  /* introduced new syntax of  ss(n=120, itime=20 itime=30) as oposed to ss(n=10 n=20) this means both syntax must be handled */
  if "`ss'"~="" { /* can't be empty btw */
    /* if there is a comma this is the more complex syntax */
    if index("`ss'",",")~=0 {
      local interim_notss 1
      /* ss(n=120, itime=20 itime=30)  need to check there is a single n everything else is handled by if statements on itime */
      local chkcomma = length("`ss'")-length(subinstr("`ss'",",","",.))
      if `chkcomma'~=1 {
        di "Error: Too many commas in `ss'"
        exit(198)
      }
      tokenize "`ss'", parse(",")
      local ss "`1'" /* this should contain n=120*/
      local interims "`3'" /* this should contain itime=20  itime=40 */
      local wc: word count `ss' /* this is a quick error check*/
      if `wc' ~= 1 {
        di "{err} PLEASE avoid having spaces in the interim option other than to split the interim indicators"
        exit(198)
      }
      local master_n1 = substr("`ss'", strpos("`ss'","n=")+2,.)  /* only one sample size */
      tokenize "`interims'", parse("=<") /* check how many = to creat number of interims/finaldecision */
      local nstage 0
      while ("`1'"~="") {
        if ("`1'"=="<" | "`1'"=="="| "`1'"=="<=" ) { /* need to check if next symbol is a parsing character */
          if ("`2'"=="<" | "`2'"=="=") {
            di "{err}Error: the suboption of ss() contains spaces between operators "
            exit(198)
          }
          local nstage = `nstage'+1
        }
        mac shift 1
      } 
      /* need to have each interim if statement set up */
      local wc: word count `interims'
      if `wc'~=`nstage' {
        di "{err} PLEASE avoid having spaces in the interim option other than to split the interim indicators"
        exit(198)
      }
      forv i=1/`nstage' {
        local intif`i': word `i' of `interims'  /* this means the text n=10 is in macro int1  n=20   is in macro int2 */
        if "`intif`i''"=="" di "{err}Warning: empty if statement"
        local intif`i' "if `intif`i''"
      }
      di "{txt}Number of stages = {res}`nstage' {txt}(including final)"
      di _continue "{txt}    Sample size  = {res}`master_n1'{res}"  
    }
    else { /* not comma if*/
      local nstage = length("`ss'") - length(subinstr("`ss'", "=", "", .)) /* check how many = to creat number of interims/finaldecision */
      local wc: word count `ss' /* this is a quick error check*/
      if `wc' ~= `nstage' {
        di "{err} PLEASE avoid having spaces in the interim option other than to split the interim indicators"
        exit(198)
      }
      forv i=1/`nstage' {
        local int`i': word `i' of `ss'  /* this means the text n=10 is in macro int1  n=20   is in macro int2 */
        if strpos("`int`i''", "n=")~=0 {
          local master_n`i' = substr("`int`i''", strpos("`int`i''","n=")+2,.)  /*master_n keeps the planned original samplesize */
        }
        local ii `i'
      }
      local nstage = `nstage'  /* the number of stages = number of interims+final */
      di "{txt}Number of stages = {res}`nstage' {txt}(including final)"
      if "`nstage'"=="1" di _continue "{txt}    Sample size  = {res}"
      else di _continue "{txt}    Sample sizes = {res}"
      forv i=1/`nstage' {
        di _continue " `master_n`i'' "
      }
    } /* end of not comma if */
  } /* end of if ss */

  /**************** handling the decision () ****************************/
  if "`decision'"~="" { /* this can be empty if you are not processing the output */
    di
    di "{txt}The decisions being made at each interim and final analysis"
    local decision = ustrtrim("`decision'")
//  di "STARTDECISION +++++ `decision'"
    forv inter = 1/`=`nstage'' { /* this is the main macro containing decisions */
      local commandi 1
      while (strpos("`decision'", "`int`inter'':")>0 ) {
        local starti = strpos("`decision'", "`int`inter'':")+strlen("`int`inter'':") /* This strips out first n=123: ... but I need to loop over each one. */
   //     di "starti `starti'"
        local tempdecision = substr("`decision'", strpos("`decision'", "`int`inter'':")+strlen("`int`inter'':"),.)   /*strip out start value n=xx: */
 //       di "tempdecision `tempdecision'"
        local endi 1000000
        local endii 1000000
        forv interinter = 1/`=`nstage'' { /* this loop strips out the others */
          if strpos("`tempdecision'", "`int`interinter'':")>0 {
            local endi = min(`endi', strpos("`tempdecision'", "`int`interinter'':")-1 )
            local endii = min(`endii', strpos("`tempdecision'", "`int`interinter'':")+strlen("`int`interinter'':"))
          }
        }
  //      di "`endi' endii `endii'"
        local dec`inter'_`commandi' = strtrim(substr("`tempdecision'", 1, `endi')) /* this shoudl now contain all commands between two n=x: ....  n=xx:*/
  //        di " dec inter  `dec`inter'_`commandi''"
        local decision = substr("`tempdecision'", `endi', .) /* put the remaining text back into decision macro*/
        
  //      di "DECISION = `decision'"
        local commandi = `commandi'+1
    //    di "COMMAND`commandi' ===== `decision'"
       
      } /* end of while*/
      local ndec`inter' = `commandi'-1
      if "`inter'"=="`nstage'" {
        forv i = 1/`ndec`inter'' {
          di "{txt}FINAL `inter':{res} `dec`inter'_`i''"
        }
      }
      else {
        forv i = 1/`ndec`inter'' {
          di "{txt}Interim `inter':{res} `dec`inter'_`i''"
        }
      }
    }
  } /* end of if decision*/

/****************** Start of simulation code ***************************/
  di _n "{txt}Simulations about to start..."   
  forv simi = 1/`nsims' {
    /* displaying stuff during simulations to keep up the interest*/
    if mod(`simi',20)==0 di _continue "{res}."
    if mod(`simi',100)==0 di _continue "`simi'"
    
    /*
      Creating some code to predict how long the simulations are due to take 
      from the first 10, 100 and 1000 simulations 
      - Probably should have an option to turn this off?
    */
    if (`simi'==1 & `nsims'>10) {
       timer clear 1
       timer clear 2
       timer clear 3
       timer on 1
       timer on 2
       timer on 3
    }
    if (`simi'==10 & `nsims'>10) {
      timer off 1
      qui timer list 1
      local time_end = `nsims'/10*`r(t1)'
      if (`time_end'<60) local timee: di "{res}" %3.0f `time_end' "s"
      else if (`time_end'< 3600) {
         local mins = floor(`time_end'/60)
         local secs = floor(`time_end'-`mins'*60)
         local timee: di "{res}`mins'm `secs's"
      }
      else if (`time_end'<86400) {
        local hrs = floor(`time_end'/3600)
        local mins = floor((`time_end' - `hrs'*3600)/60)
        local secs = floor(`time_end'-`mins'*60 -  `hrs'*3600)
        if (`hrs'==1) local timee: di "{res}`hrs'hour `mins'm `secs's"  
        else local timee: di "{res}`hrs'hours `mins'm `secs's"      
      }
      di _n "{txt}Note: Simulations predicted to take `timee' {txt}from first 10 simulations"
    }
    if (`simi'==100 & `nsims'>100) {
      timer off 2
      qui timer list 2
      local time_end = `nsims'/100*`r(t2)'
      if (`time_end'<60) local timee: di "{res}" %3.0f `time_end' "s"
      else if (`time_end'< 3600) {
         local mins = floor(`time_end'/60)
         local secs = floor(`time_end'-`mins'*60)
         local timee: di "{res}`mins'm `secs's"
      }
      else if (`time_end'<86400) {
        local hrs = floor(`time_end'/3600)
        local mins = floor((`time_end' - `hrs'*3600)/60)
        local secs = floor(`time_end'-`mins'*60 -  `hrs'*3600)
        if (`hrs'==1) local timee: di "{res}`hrs'hour `mins'm `secs's"  
        else local timee: di "{res}`hrs'hours `mins'm `secs's"      
      }
      di _n "{txt}Note: Simulations predicted to take `timee' {txt}from first 100 simulations"
    }
    if (`simi'==1000 & `nsims'>1000) {
      timer off 3
      qui timer list 3
      local time_end = `nsims'/1000*`r(t3)'
      if (`time_end'<60) local timee: di "{res}" %3.0f `time_end' "s"
      else if (`time_end'< 3600) {
         local mins = floor(`time_end'/60)
         local secs = floor(`time_end'-`mins'*60)
         local timee: di "{res}`mins'm `secs's"
      }
      else if (`time_end'<86400) {
        local hrs = floor(`time_end'/3600)
        local mins = floor((`time_end' - `hrs'*3600)/60)
        local secs = floor(`time_end'-`mins'*60 -  `hrs'*3600)
        if (`hrs'==1) local timee: di "{res}`hrs'hour `mins'm `secs's"  
        else local timee: di "{res}`hrs'hours `mins'm `secs's"
      }
      di _n "{txt}Note: Simulations predicted to take `timee' {txt}from first 1000 simulations"
    }

    
/*******************     Pre trial set up  ****************************/
    drop _all /*need to clear the data at the start of each trial*/
    forv inter = 1/`nstage' { /* have to reset sample sizes for each stage at the beginning of each trial */
      if (`interim_notss') local n1 "`master_n1'" /* for time interims there is only the main sample size */
      else local n`inter' "`master_n`inter''"
    }
    if "`setup'"~="" { /* the use of setup commands, not sure this is used */
      tokenize "`setup'", parse(";")
      while "`1'"~="" {
        if index("`1'", ";")~=0 {
          mac shift 1
          continue
        }
        qui `1'
        mac shift 1
      }
    }

/*******************       Data creation per stage ******************************/  
/******************* (an additional loop within a simulation) *******************/
    tempname rorder
    forv inter = 1/`nstage' { /* loop over the interim analysis  and final analysis */
//di "stage `inter' `n`inter''  ||  n1 `n1' n2 `n2' n3 `n3' || (`p0', `p1', `p2') "
      if (`interim_notss') { /* set the observations only once */
        if `inter'==1 qui set obs `n1'
      }
      else qui set obs `n`inter''   /* works for sample size interims */
      /* Now parse the data generation string by semicolon */
      tokenize "`data'", parse(";")
      while "`1'"~="" {
        if index("`1'", ";")~=0 {
          mac shift 1
          continue
        }
        /***********   FIXED distribution ***************/
        else if index("`1'", "fixed(")~=0 & (!`interim_notss' | (`interim_notss' & `inter'==1)) { /* generate a fixed category variable */
          local plistall = subinstr(subinstr("`1'", "{","`",.),"}","'",.)  /* strip out  {} to mean local macro */
          local plist = substr("`plistall'", index("`plistall'","(")+1, index("`plistall'",")")-index("`plistall'","(")-1) /* make a list of probabilities and the variable name*/
          local plist = subinstr("`plist'", ",", " ",.)      
          local variable = substr("`plistall'", 1, index("`plistall'","~")-1)

          if `inter'>1 local minn = `n`=`inter'-1''
          else { 
            qui gen `variable'=.  /* generate the new variable to be empty*/
            local minn 0
          }
          if `inter'>1 {
            qui replace `rorder'=uniform() if `rorder'==.
            sort `variable' `rorder'
          }
          else {
            qui gen `rorder'=uniform()
            sort `rorder'
          }
/* NOTE rounding errors might creep an error in here!*/          
          local cprob 0   /* the cumulative probability */
          local cproblast 0 /* the previous cum. prob. */
          local level 0 /* the first level of the variable */
          local sump 0
          foreach p of numlist `plist' {
             local sump = `sump'+`p'
          }
          foreach p of numlist `plist' {
            local cprob = `cprob'+`p'/`sump'
            if `inter'>1  qui replace `variable' = `level' if _n<= `cprob'*(`n`inter''-`minn')+`minn' & _n> `cproblast'*(`n`inter''-`minn')+`minn' & `variable'==.
            else qui replace `variable' = `level' if _n<= `cprob'*(`n`inter''-`minn')+`minn' & _n> `cproblast'*(`n`inter''-`minn')+`minn' 
            local cproblast "`cprob'"
            local level = `level'+1
          }
        } /* end of fixed distribution */ 
        /******* NORMAL distribution ********/
        else if (index("`1'", "N(")~=0 & index("`1'", "MVN(")==0)  & (!`interim_notss' | (`interim_notss' & `inter'==1))  { /* generate a normal distribution */
          local internal = substr("`1'", index("`1'","(")+1, index("`1'",")")-index("`1'","(")-1)
          local mean = substr("`internal'", 1, index("`internal'",",")-1)
          local sd = substr("`internal'",  index("`internal'",",")+1,. )
          local variable = substr("`1'", 1, index("`1'","~")-1)
          if `inter'>1 qui replace `variable' = `mean' + rnormal(0 ,`sd') if `variable'==.
          else qui gen `variable' = `mean' + rnormal(0 ,`sd')
        } /* end of generate N( mu, var) */
       
        /******* MUltvariate NORMAL distribution  ********/
        else if (index("`1'", "MVN(")~=0)  & (!`interim_notss' | (`interim_notss' & `inter'==1))  { /* generate a  multivariatenormal distribution */
          local outcomes ""
          local variable = substr("`1'", 1, index("`1'","~")-1)
          local dist = substr("`1'", index("`1'","MVN")+3,.)
          /* Now count how many ( and how many ) should be two each */
          local leftcount = length("`dist'")-length(subinstr("`dist'", "(", "", .))
          local rightcount = length("`dist'")-length(subinstr("`dist'", ")", "", .))
          if `leftcount'~=2 &`rightcount'~=2 {
            di "{err}Warning: MVN`dist' does not contain 2 left brackets and 2 right brackets"
            exit(198)
          }
          /* strip out leading and trailing bracket */
          local dist = substr("`dist'", strpos("`dist'","(")+1,.)
          local dist = substr("`dist'", 1, strrpos("`dist'",")")-1)
          local means = substr("`dist'", strpos("`dist'","(")+1,.)
          local means = substr("`means'", 1, strpos("`means'",")")-1)
          local cov = substr("`dist'", strpos("`dist'",")")+1, .) /*strip var part out */
          local cov = substr("`cov'",strpos("`cov'",",")+1,.) /* strip out leading comma */
          /* count how many outcomes number of commas plus 1 */
          local nouts = length("`means'") - length(subinstr("`means'",",","",.))+1
          forv i=1/`nouts' {
            local outcomes "`outcomes' `variable'`i'"
          }
          qui drawnorm `outcomes', cov(`cov') /* draw with mean 0 next bit handles the means */
          forv i=1/`nouts' {
              /* get current mean */
              if strpos("`means'",",") > 0 local mni = substr("`means'", 1, strpos("`means'",","))
              else local mni = substr("`means'", 1, .)
              local means = substr("`means'", strpos("`means'",",")+1,.)
              qui replace `variable'`i'  = `variable'`i'+ `mni'
          }
        } /* end of generate MVN( (mu), Var)*/
        /************ Bernoulli distribution ***************/
        else if (index("`1'", "Bern(")~=0)  & (!`interim_notss' | (`interim_notss' & `inter'==1))  { /* generate a bernoulli distribution */
          local internal = substr("`1'", index("`1'","(")+1, index("`1'",")")-index("`1'","(")-1)
          local prob = "`internal'"
          local variable = substr("`1'", 1, index("`1'","~")-1)
          if `inter'>1 qui replace `variable' = uniform()<=`prob' if `variable'==.
          else qui gen `variable' = uniform()<=`prob'
        } /* end of generate N( mu, var)*/
        /************ Uniform distribution  ***************/
        else if (index("`1'", "U(")~=0)  & (!`interim_notss' | (`interim_notss' & `inter'==1))  { /* generate a uniform distribution */
          local internal = substr("`1'", index("`1'","(")+1, index("`1'",")")-index("`1'","(")-1)
          local prob = "`internal'"
          local variable = substr("`1'", 1, index("`1'","~")-1)
          if `inter'>1 qui replace `variable' = runiform(`prob') if `variable'==.
          else qui gen `variable' = runiform(`prob')
        } /* end of generate N( mu, var)*/
        /************    Exponential distribution  ***************/
        else if (index("`1'", "Exp(")~=0)  & (!`interim_notss' | (`interim_notss' & `inter'==1))  { /* generate an exponential distribution */
          local internal = substr("`1'", strpos("`1'","(")+1, strrpos("`1'",")")-strpos("`1'","(")-1)  /* not last bracket strrpos.. to allow for brackets in command */
          local prob = "`internal'"
          local variable = substr("`1'", 1, index("`1'","~")-1)
          if `inter'>1 qui replace `variable' = rexponential(`prob') if `variable'==.
          else qui gen `variable' = rexponential(`prob')
        } /* end of generate N( mu, var)*/
        /************** Handle other commands
        if there is a replace or a reshape command we do them as they are... 
        if there is no stata pretext then it is a generate/replace command
        *************/
        else if  (!`interim_notss' | (`interim_notss' & `inter'==1))  { /* statements left must have an equal sign!!! */
          local doword: word 1 of `1'
          if "`doword'"=="reshape" {
            qui `1'
          }
          else {
            local variable = substr("`1'", 1, index("`1'","=")-1) /* need a variable name*/
            if `inter'>1  qui replace `1' if `variable'==. /* replace earlier variables */
            else qui gen `1'
          }
        }
        mac shift 1
      }

      
/**********************           ANALYSIS             **********************/
      /* Now the analysis  looping through each command split by ;   BUT also considering interim analyses n=100[ ]  time=10[  ]  */
      tokenize "`analysis'", parse(";")
      local first 1
      while "`1'"~="" {
        if "`1'"==";" {
          mac shift 1
          continue
        }
        local analysisnow = subinstr(subinstr("`1'", "{","`",.),"}","'",.)  /* strip out  {} to mean local macro */
        /* now need to check whether to add an if statement for the interim analysis and ONLY add it to the first command! */
        if (`interim_notss') & (`first') {
          qui `analysisnow' `intif`inter''
          local first 0
        }
        else qui `analysisnow'
        mac shift 1 
      }

/**********************   DECISIONS     **************************/     
      /* Now handle any decisions that need to be made per interim analysis and final analysis
      and there could be mulitple decisions separated by semicolon */
      local stoptrialE 0
      local stoptrialF 0
      local stoptrial 0
      if "`dec`inter'_1'"~= "" { /* we know there is a decision in first interim/final */
        forv ii = 1/`ndec`inter'' { /* this loops over each decision per interim/final */
        
//di "{err}INTERIM `inter' decision `dec`inter'_`ii''{txt}" 
        /* check for semicolon and then parse the multiple decisions */
          if (length("`dec`inter'_`ii''") - length(subinstr("`dec`inter'_`ii''", ";", "", .)))==0 {
            di "{err}ERROR no semicolon in the decision" 
            exit(198)
          }
          tokenize "`dec`inter'_`ii''", parse(";")   /* split on the semicolon */     
          while "`1'"~="" {
            local action: word 1 of `1'
            if "`action'"=="stoptrialE" {
              local actionif = strtrim(substr("`1'", strpos("`1'", "if")+2,.))
              local actionif = subinstr(subinstr("`actionif'", "{","`",.),"}","'",.) /* strip out  {} to mean local macro */
              if (`actionif') local stoptrialE 1 
//if (`actionif') di "stopE `actionif'"
              mac shift 1
            }
            else if "`action'"=="stoptrialF" {
              local actionif = strtrim(substr("`1'", strpos("`1'", "if")+2,.))
              local actionif = subinstr(subinstr("`actionif'", "{","`",.),"}","'",.)  /* strip out  {} to mean local macro */
              if (`actionif') local stoptrialF 1 
              mac shift 1
            }
            else if "`action'"=="SSR" {
              local actionif = strtrim(substr("`1'", strpos("`1'", "SSR")+3,.)) /* strip out the action*/
              local actionif = subinstr(subinstr("`actionif'", "{","`",.),"}","'",.)  /* strip out  {} to mean local macro */
              `actionif'
              mac shift 1
            }
            else if "`action'"=="RAR" {
              local actionif = strtrim(substr("`1'", strpos("`1'", "RAR")+3,.)) /* strip out the action*/
              local actionif = subinstr(subinstr("`actionif'", "{","`",.),"}","'",.)  /* strip out  {} to mean local macro */
              `actionif'
              mac shift 1
            }
            else if "`action'"=="droparm" {
//di "droparm |1`1'|2`2'|3`3'|4`4'|"              
              local action = strtrim(substr("`1'", strrpos("`1'",")")+1,.))   /* strip out the action after last bracket */
              local actionif = strtrim(substr("`1'", strpos("`1'", "droparm")+7,strrpos("`1'",")")+1-7)) /* strip out the actions after last bracket */
              local actionif = subinstr(subinstr("`actionif'", "{","`",.),"}","'",.)  /* strip out  {} to mean local macro */
              local action= subinstr(subinstr("`action'", "{","`",.),"}","'",.)  /* strip out  {} to mean local macro */
//di "BUG if `actionif' `action'"
              if `actionif' `action'
              mac shift 1    
              while (strpos("`1'","stoptrialE")==0 & strpos("`1'","stoptrialF")==0 & strpos("`1'","stoptrial")==0 & strpos("`1'","SSR")==0 & strpos("`1'","RAR")==0 & strpos("`1'","droparm")==0  & "`1'"~="") {
                if "`1'"~=";" {
                  local action = subinstr(subinstr("`1'", "{","`",.),"}","'",.)  /* strip out  {} to mean local macro */
                  if `actionif' `action'
                }
                mac shift 1   
              }
            }
            else if "`action'"=="stoptrial" {
              local actionif = strtrim(substr("`1'", strpos("`1'", "if")+2,.))
              local actionif = subinstr(subinstr("`actionif'", "{","`",.),"}","'",.)  /* strip out  {} to mean local macro */
              if (`actionif') local stoptrial 1 
              mac shift 1
            }
            else {
              mac shift 1
            }
          }
        }    
      } /* end of interim/final decisions */
      
/**********************         final decision     OLD CODE???    *************************/
/*
      if "`finaldecision''"~= "" & `inter'==`nstage' { 
        /* check for semicolon and then parse the multiple decisions */
        if (length("`finaldecision'") - length(subinstr("`finaldecision'", ";", "", .)))>0 {
          tokenize "`finaldecision'", parse(";")       
          while "`1'"~="" {
            local action: word 1 of `1'
            if (strpos("`action'","droparm")~=0) {
              local actionif = strtrim(substr("`1'", strpos("`1'", "droparm")+7,strrpos("`1'",")") -7)) /* strip out the if statement LAST ) action*/
              local actionif = subinstr(subinstr("`actionif'", "{","`",.),"}","'",.)  /* strip out  {} to mean local macro */
              local actions1 = strtrim(substr("`1'", strrpos("`1'",")")+1,.)) /* strip out the first action after LAST ) */
              local nactions 1
              mac shift 1     
              while (strpos("`1'","stoptrialE")==0 & strpos("`1'","stoptrialF")==0 & strpos("`1'","SSR")==0 & strpos("`1'","RAR")==0 & strpos("`1'","droparm")==0 & "`1'"~="") {
                if "`1'"~=";" {
                  local nactions = `nactions'+1
                  local action = subinstr(subinstr("`1'", "{","`",.),"}","'",.)  /* strip out  {} to mean local macro */
                  local actions`nactions' "`action'"
                }
                mac shift 1
              }
              local DOALLACTIONS = `=`actionif'' /* some of the current actions may change the status of doing the action... */
              forv i=1/`nactions' {
                if `DOALLACTIONS' `actions`i''
              }
            } 
          }
        }
        else { /* SINGLE final decision */
          local action: word 1 of `finaldecision'
          if "`action'"=="stoptrialE" {
            local actionif = strtrim(substr("`finaldecision'", strpos("`finaldecision'", "if")+2,.))
            if (`actionif') local stoptrialE 1 
          }
          else if "`action'"=="stoptrialF" {
            local actionif = strtrim(substr("`finaldecision'", strpos("`finaldecision'", "if")+2,.))
            if (`actionif') local stoptrialF 1 
          }
          else if (strpos("`action'","droparm")~=0) {
            local actionif = strtrim(substr("`finaldecision'", strpos("`finaldecision'", "droparm")+7,.)) /* strip out the action*/
            local actionif = subinstr(subinstr("`actionif'", "{","`",.),"}","'",.)  /* strip out  {} to mean local macro */
            `actionif'
          } /* end of drop arm*/
        } /* end of else */
      }
   
*/
/********************        SAVE RESULTS         ***************************/
      /* Save any results in another frame along the way */
      frame change `results'
      qui {
        set obs `simi'
        tokenize "`output'", parse(";")
        while "`1'"~="" {
          if "`1'"==";" {
            mac shift 1
            continue
          } 
          /* now macro 1 should contain the generate statement and now split into varname_inter = f() */
          local vname = strtrim(substr("`1'", 1, strpos("`1'","=")-1))
          local vcont = strtrim(substr("`1'", strpos("`1'","=")+1, .)) /* if the first word of vcont is local then strip it out*/
          local vcont = subinstr(subinstr("`vcont'", "{","`",.),"}","'",.)  /* strip out  {} to mean local macro */ 
          cap gen `vname'`inter' = `vcont' in `simi'
          if _rc==110 replace `vname'`inter' = `vcont' in `simi'
          mac shift 1
        }
        frame change default
      } /* end of save results */
      
    if (`stoptrialE') continue, break /* after stopping the trial need to get to next sim so skip interims loop but needed it here to save results!*/
    if (`stoptrialF') continue, break /* after stopping the trial need to get to next sim so skip interims loop but needed it here to save results!*/
    if (`stoptrial') continue, break /* after stopping the trial need to get to next sim so skip interims loop but needed it here to save results!*/
    } /* end of interims loop */
    local simi = `simi'+1
  } /* end of sims */
 di
   
/*************   Summarise results **************************/
  frame change `results'
  if "`outputsummary'"~="" {
    local vlist ""
    tokenize "`outputsummary'", parse(";")
    while "`1'"~="" {
      if "`1'"==";" {
        mac shift 1
        continue
      }
      local vname=substr("`1'",1, strpos("`1'","=")-1)
      local vlist "`vlist' `vname'"
      qui gen `1'
      mac shift 1
    }
  }
  su `vlist'
  //list
  if "`saving'"~="" save `saving', `replace'
  frame change default
  frame drop `results'

//restore
  
end

