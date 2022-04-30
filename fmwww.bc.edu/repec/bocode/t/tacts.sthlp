{smcl}
{* *! version 1.0 29 Apr 2022}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "tacts##syntax"}{...}
{viewerjumpto "Description" "tacts##description"}{...}
{viewerjumpto "Options" "tacts##options"}{...}
{viewerjumpto "Remarks" "tacts##remarks"}{...}
{viewerjumpto "Examples" "tacts##examples"}{...}
{title:Title}
{phang}
{bf:tacts} {hline 2} A clinical trial simulator

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:tacts}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Required }

{synopt:{opt data(string)}}  specifies the data generating commands. {p_end}

{synopt:{opt analysis(string)}}  specifies the analysis commands. {p_end}

{synopt:{opt output(string)}}  specifies what is saved for each simulation. {p_end}

{synopt:{opt ss(string)}}  specifies the sample sizes for each stage of the design. {p_end}

{syntab:Optional}
{synopt:{opt decision(string)}} specifies what decisions are made at each interim analysis.

{synopt:{opt outputsummary(string)}} specifies commands used on the final simulated dataset.

{synopt:{opt nsims(#)}} specifies the number of simulations to carry out.

{synopt:{opt setup(string)}} specifies a set of commands to run at the start of the simulation.

{synopt:{opt saving(string)}} specifies the name of the final dataset.

{synopt:{opt replace}} specifies whether to replace the final saved dataset.

{synopt:{opt seed(#)}} specifies the random number seed.

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

{pstd}
 {cmd:tacts} simulates data from different types of trial and summarises the results.

{marker options}{...}
{title:Options}
{dlgtab:Main}

{phang}
{opt data(string)}  specifies the data generating commands.

{phang}
{opt analysis(string)}  specifies the analysis commands.

{phang}
{opt output(string)}  specifies what is saved for each simulation.

{phang}
{opt ss(string)}  specifies the sample sizes for each stage of the design.

{phang}
{opt decision(string)}  specifies what decisions are made at each interim analysis.

{phang}
{opt outputsummary(string)}  specifies commands used on the final simulated dataset.

{phang}
{opt nsims(#)}  specifies the number of simulations to carry out.

{phang}
{opt setup(string)}  specifies a set of commands to run at the start of the simulation.

{phang}
{opt saving(string)}  specifies the name of the final dataset.

{phang}
{opt replace} replace specifies whether to replace the final saved dataset.

{phang}
{opt seed(#)}  specifies the random number seed.



{marker examples}{...}
{title:Examples}


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
  Disjpower = ((tt12>)|(tt22>)|(tt32>)); 
  Marg_power1 = tt12>; Marg_power2 = tt22>; 
  Marg_power3 = tt32>; Stage2_SS_0=n_x02; Stage2_SS_1=n_x12; 
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
  FWER = ((tt12>)|(tt22>)|(tt32>)); 
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


{pstd}

{pstd}


{title:Author}
{p}

Prof Adrian Mander, Cardiff University.

Email {browse "mailto:mandera@cardiff.ac.uk":mandera@cardiff.ac.uk}



