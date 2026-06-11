{smcl}
{* *! version 1.0.0  28may2026}{...}
{cmd:help xtcsnardl_methodology}{right:also see:  {help xtcsnardl}  {help xtcsnardl_examples}  {help xtcsnardl_postestimation}  {help xtcsnardl_graph}}
{hline}

{title:Methodology and equations  {hline 2}  CS-NARDL}

{title:Unifying principle}

{pstd}
{bf:Every estimator in this package is the nonlinear (asymmetric) extension of a canonical
CCE/ARDL method.}  The asymmetric decomposition of Shin, Yu and Greenwood-Nimmo (2014) is
applied {ul:before} the chosen engine is called, so the seven estimators provided by
{cmd:xtcsnardl} are precisely:

{p2col 5 35 30 2:Engine}{...}Nonlinear extension of{p_end}
{p2col 5 35 30 2:{hline 35}}{hline 30}{p_end}
{p2col 5 35 30 2:{cmd:pmg / mg / dfe}}Panel ARDL (Pesaran-Shin-Smith 1999){p_end}
{p2col 5 35 30 2:{opt engine(csardl)}}CS-ARDL (Chudik-Pesaran 2015){p_end}
{p2col 5 35 30 2:{opt engine(csdl)}}CS-DL (Chudik-Pesaran 2015){p_end}
{p2col 5 35 30 2:{opt engine(dcce)}}Dynamic CCE (Chudik-Pesaran 2015){p_end}
{p2col 5 35 30 2:{opt engine(cce)}}Static CCE (Pesaran 2006){p_end}

{pstd}
The theoretical justification rests on the two foundational papers of the {bf:nonlinear panel CSD
literature}: {ul:Kapetanios, Mitchell and Shin (2014)} formalise the nonlinear panel data model
with interactive (factor) errors and establish that consistent estimation requires the proxy
set to include nonlinear transforms of the cross-sectional averages.  {ul:Hacioglu-Hoke and
Kapetanios (2020)} then sharpen this into an explicit CCE correction: the standard Pesaran
(2006) proxy set must be augmented with cross-sectional averages of the
nonlinear-transformed regressors -- in CS-NARDL, the positive and negative partial sums
{it:x}{sup:+} and {it:x}{sup:-}.  This is done automatically by every engine in {cmd:xtcsnardl}.


{title:Contents}

{p 8 12 2}
{help xtcsnardl_methodology##overview:1.}  Big picture: three layers of generalisation{break}
{help xtcsnardl_methodology##nardl:2.}     Asymmetric decomposition (NARDL){break}
{help xtcsnardl_methodology##cce:3.}        CCE and dynamic CCE (Pesaran 2006; Chudik-Pesaran 2015){break}
{help xtcsnardl_methodology##nlcce:4.}      Nonlinear CCE (Kapetanios-Mitchell-Shin 2014 & Hacioglu-Hoke-Kapetanios 2020){break}
{help xtcsnardl_methodology##model:5.}      The CS-NARDL model{break}
{help xtcsnardl_methodology##ecm:6.}        Error-correction reparameterisation (estimated form){break}
{help xtcsnardl_methodology##csdl:7.}       Relation to CS-DL and CS-ARDL{break}
{help xtcsnardl_methodology##estimation:8.} Estimation (PMG / MG / DFE) and identification{break}
{help xtcsnardl_methodology##asymtests:9.}  Tests for asymmetry{break}
{help xtcsnardl_methodology##multipliers:10.} Asymmetric long-run and dynamic multipliers{break}
{help xtcsnardl_methodology##cd:11.}        CSD diagnostics{break}
{help xtcsnardl_methodology##interp:12.}    How to read CS-NARDL output


{marker overview}{...}
{title:1. Big picture: three layers of generalisation}

{pstd}
The CS-NARDL nests three orthogonal extensions of the classical panel ARDL:

{p 4 4 2}
{bf:Layer A {hline 2} Asymmetry}.  Drop the implicit linearity restriction
{&beta}{sup:+} = {&beta}{sup:-} on regressors that may impact y differently when they
{ul:rise} vs when they {ul:fall}.  Implemented as cumulative partial sums after
{help xtcsnardl_methodology##nardl:Shin, Yu and Greenwood-Nimmo (2014)}.
{p_end}

{p 4 4 2}
{bf:Layer B {hline 2} Cross-section dependence (linear CCE)}.  Replace the strict
cross-sectional independence assumption with an interactive factor structure and
proxy the unobserved factors by cross-sectional averages (CSA), per
{help xtcsnardl_methodology##cce:Pesaran (2006)} and
{help xtcsnardl_methodology##cce:Chudik and Pesaran (2015)}.
{p_end}

{p 4 4 2}
{bf:Layer C {hline 2} Nonlinear CCE}.  When the conditional mean is nonlinear
(here: positive/negative cumulative sums), the Pesaran proxy set must be augmented
with CSA of the nonlinear-transformed regressors to preserve consistency, per
{help xtcsnardl_methodology##nlcce:Hacioglu-Hoke and Kapetanios (2020)}.
{p_end}

{pstd}
{cmd:xtcsnardl} implements {ul:all three layers simultaneously}.


{marker nardl}{...}
{title:2. Asymmetric decomposition (NARDL)}

{pstd}
Shin, Yu and Greenwood-Nimmo (2014) modify the Pesaran-Shin-Smith (1999) ARDL by replacing
selected regressors with their {ul:positive} and {ul:negative} cumulative partial sums.  Let
{&Delta}x{sub:it} = x{sub:it} {c -} x{sub:i,t-1}.  Define

{p 8 8 2}
x{sup:+}{sub:it} = {&Sigma}{sub:s=1..t} max({&Delta}x{sub:is}, 0)  {hline 2} cumulative positive shocks{break}
x{sup:-}{sub:it} = {&Sigma}{sub:s=1..t} min({&Delta}x{sub:is}, 0)  {hline 2} cumulative negative shocks
{p_end}

{pstd}
By construction x{sub:it} = x{sub:i0} + x{sup:+}{sub:it} + x{sup:-}{sub:it}, so the
decomposition reparametrises the path of x without information loss.  Replacing
{&beta}x{sub:it} in the cointegrating vector with {&beta}{sup:+}x{sup:+}{sub:it} +
{&beta}{sup:-}x{sup:-}{sub:it} allows the long-run elasticity to differ between rises and
falls.  The linear ARDL is the nested null {&beta}{sup:+} = {&beta}{sup:-}; rejecting this
restriction is the {ul:test of long-run asymmetry} (Table 5).

{pstd}
The partial-sum variables generated by {cmd:xtcsnardl} are named
{cmd:varname_pos} and {cmd:varname_neg}, and they are retained in the dataset after estimation.
You can recover them for diagnostics, plotting, or future regressions.


{marker cce}{...}
{title:3. CCE and Dynamic CCE}

{pstd}
The linear CCE-MG estimator of Pesaran (2006) models the error structure of a heterogeneous
panel as

{p 8 8 2}
y{sub:it} = a{sub:i} + {&beta}{sub:i}'x{sub:it} + u{sub:it},
{space 5}u{sub:it} = {&gamma}{sub:i}'f{sub:t} + {&epsilon}{sub:it},
{space 5}x{sub:it} = {&Lambda}{sub:i}'f{sub:t} + v{sub:it}
{p_end}

{pstd}
where f{sub:t} is a vector of {ul:unobserved} common factors.  The
{ul:cross-sectional averages} z{c -}{sub:t} = (y{c -}{sub:t}, x{c -}{sub:t})' are then a
linear function of f{sub:t} (up to O(N{sup:-1/2})), so including them in the regression
removes the factor-induced endogeneity:

{p 8 8 2}
y{sub:it} = a{sub:i} + {&beta}{sub:i}'x{sub:it} + {&delta}{sub:i}'z{c -}{sub:t} + e{sub:it}.
{p_end}

{pstd}
{bf:Dynamic CCE} (Chudik and Pesaran 2015) extends this to ARDL-type dynamics by adding p{sub:T}
{ul:lags} of z{c -}{sub:t}, where the optimal lag-length is

{p 8 8 2}
p{sub:T} = {&lfloor}T{sup:1/3}{&rfloor}
{p_end}

{pstd}
under standard assumptions.  This is the default rule used by {cmd:xtcsnardl} via the
{opt cr_lags(#)} option {hline 2} set to {opt cr_lags(-1)} for the floor(T{sup:1/3}) heuristic
or override with any non-negative integer.


{marker nlcce}{...}
{title:4. Nonlinear CCE (Kapetanios-Mitchell-Shin 2014 and Hacioglu-Hoke & Kapetanios 2020)}

{pstd}
The nonlinear panel CSD framework rests on {ul:two foundational papers}.  {cmd:xtcsnardl}
uses both, and the methodology page describes their distinct contributions explicitly.

{p 4 6 2}
{bf:Step A. The nonlinear panel model with CSD (Kapetanios, Mitchell and Shin 2014).}
KMS introduce a general nonlinear panel data model in which the dependent variable is a
nonlinear function of the regressors and a vector of unobserved common factors.  Their
contribution is two-fold.  First, they {ul:formalise} a panel with heterogeneous coefficients,
nonlinear conditional mean and an interactive (factor) error structure of the form{p_end}

{p 12 12 2}
y{sub:it} = m{sub:i}(x{sub:it}, {&theta}{sub:i}) + {&lambda}{sub:i}'f{sub:t} + {&epsilon}{sub:it},
{space 5}x{sub:it} = {&Pi}{sub:i}'f{sub:t} + v{sub:it}.
{p_end}

{p 4 6 2}
Second, they study the {ul:asymptotic identification} of {&theta}{sub:i} when N, T -> infinity and
propose a sieve-CCE strategy: factors are proxied not only by linear cross-sectional averages
but also by nonlinear transforms of them.  KMS (2014) thus establish the principle that
nonlinear panel CSD models {ul:require nonlinear CSA proxies}.{p_end}

{p 4 6 2}
{bf:Step B. CCE corrections for nonlinear conditional mean (Hacioglu-Hoke and Kapetanios 2020).}
HHK refine and operationalise the KMS programme for nonlinear conditional-mean models of the
form{p_end}

{p 12 12 2}
y{sub:it} = g(x{sub:it}, {&gamma}{sub:0})'{&beta}{sub:i} + u{sub:it},
{space 5}u{sub:it} = {&lambda}{sub:i}'f{sub:t} + {&epsilon}{sub:it}.
{p_end}

{p 4 6 2}
They show that when g is nonlinear, the cross-sectional average y{c -}{sub:t} contains
X{c -}({&gamma}){sub:t} = (1/N){&Sigma}{sub:i} g(x{sub:it}, {&gamma}), which is {ul:no longer}
a linear function of the factors.  The Pesaran (2006) rank condition fails, so the naive proxy
set Z{c -} = (y{c -}, x{c -}) does {ul:not} consistently estimate {&beta}.{p_end}

{p 4 6 2}
HHK (2020, Theorem 2) prove that consistency is restored by augmenting the proxy set with the
{ul:CSA of the nonlinear-transformed regressors}: Z{c -}{sub:{&gamma}} = (z{c -}, X{c -}({&gamma})).
They derive consistent pooled and Mean Group estimators with sqrt(N)-asymptotic normality
under standard assumptions.{p_end}

{pstd}
{bf:Application to CS-NARDL.}  In our setting the nonlinear transformation g is precisely
the Shin-Yu-Greenwood-Nimmo positive/negative partial-sum decomposition.  Combining
KMS (2014) and HHK (2020) the prescription becomes:

{p 8 8 2}
{ul:Take CSA of every x{sup:+} and every x{sup:-}}, in addition to CSA of y and the linear
controls -- and add Chudik-Pesaran (2015) lags of these CSA series.
{p_end}

{pstd}
This is exactly what {cmd:xtcsnardl} does by default.  KMS (2014) supplies the framework
({ul:why} we need nonlinear CSA at all); HHK (2020) supplies the operational rule
({ul:which} nonlinear CSA series to add and {ul:how} to derive consistent estimators).  The
{opt csavars(varlist)} option lets you override the proxy set when you have a theoretical
reason; the default proxy set is jointly KMS- and HHK-compliant.


{marker model}{...}
{title:5. The CS-NARDL model}

{pstd}
For panel i = 1, ..., N and period t = 1, ..., T{sub:i}, let y{sub:it} be the dependent
variable, x{sub:it} a k-vector of asymmetric regressors and c{sub:it} an m-vector of symmetric
controls.  The CS-NARDL data-generating process is

{p 8 8 2}
y{sub:it} = a{sub:i} + {&beta}{sup:+}'x{sup:+}{sub:it} + {&beta}{sup:-}'x{sup:-}{sub:it} +
{&beta}{sub:c}'c{sub:it} + u{sub:it},                                         (Long-run){p_end}

{p 8 8 2}
u{sub:it} = {&lambda}{sub:i}'f{sub:t} + {&epsilon}{sub:it},                  (Common factors){p_end}

{p 8 8 2}
x{sub:it} = {&Pi}{sub:i}'f{sub:t} + v{sub:it}.                               (Reduced form for x){p_end}

{pstd}
{&beta}{sup:+}, {&beta}{sup:-} and {&beta}{sub:c} are the long-run elasticities of interest.
{&epsilon}{sub:it} is idiosyncratic and {&lambda}{sub:i}'f{sub:t} captures common shocks
(global cycles, energy prices, policy waves, ...).


{marker ecm}{...}
{title:6. Error-correction reparameterisation (estimated form)}

{pstd}
The full CS-NARDL ECM (the form actually estimated by {cmd:xtcsnardl} via {cmd:xtpmg}) is

{p 8 8 2}
{&Delta}y{sub:it}
= {&phi}{sub:i} [ y{sub:i,t-1} {c -} {&beta}{sup:+}'x{sup:+}{sub:i,t-1} {c -} {&beta}{sup:-}'x{sup:-}{sub:i,t-1} {c -} {&beta}{sub:c}'c{sub:i,t-1}{break}
{space 10} {c -} {&Sigma}{sub:k=0}{sup:p_T} {&psi}{sub:k}'z{c -}{sub:t-k} ]
+ {&Sigma}{sub:j=1}{sup:p} {&gamma}{sub:ij} {&Delta}y{sub:i,t-j}{break}
+ {&Sigma}{sub:j=0}{sup:q-1} ({&omega}{sup:+}{sub:ij}'{&Delta}x{sup:+}{sub:i,t-j} + {&omega}{sup:-}{sub:ij}'{&Delta}x{sup:-}{sub:i,t-j})
+ {&Sigma}{sub:j=0}{sup:q-1} {&delta}{sub:ij}'{&Delta}c{sub:i,t-j}
+ {&eta}{sub:i}'{&Delta}z{c -}{sub:t}
+ {&epsilon}{sub:it}.
{p_end}

{pstd}
Reading off the parts:

{p 4 6 2}
{c 149} {&phi}{sub:i} < 0 is the {ul:speed of adjustment} of unit i to its long-run
equilibrium.  Strict {&phi}{sub:i} < 0 is the cointegration condition.{p_end}

{p 4 6 2}
{c 149} The square-bracketed term in {&Delta}y is the {ul:cointegrating residual}
EC{sub:i,t-1}.  Its coefficients {&beta}{sup:+}, {&beta}{sup:-} are the long-run elasticities;
{&psi}{sub:k} are nuisance loadings on CSA{c -}lags.{p_end}

{p 4 6 2}
{c 149} {&omega}{sup:+}{sub:ij}, {&omega}{sup:-}{sub:ij} are the {ul:short-run asymmetric}
coefficients.{p_end}

{p 4 6 2}
{c 149} {&eta}{sub:i}'{&Delta}z{c -}{sub:t} is the {ul:short-run CSA term} (additional
nuisance, contemporaneous correction for common shocks in the {&Delta}-equation).{p_end}


{marker csdl}{...}
{title:7. Relation to CS-DL and CS-ARDL}

{pstd}
{bf:CS-DL} (Cross-Section Distributed Lag, Chudik and Pesaran 2015) writes

{p 8 8 2}
y{sub:it} = a{sub:i} + {&beta}{sub:i}'x{sub:it} + {&Sigma}{sub:k=0}{sup:p_T} {&psi}{sub:k}'z{c -}{sub:t-k} + e{sub:it}{p_end}

{pstd}
with no lagged y on the right-hand side.  It estimates the long-run elasticity {ul:directly}
but provides no information on the short-run dynamics.  The {bf:nonlinear} CS-DL is the same
equation after replacing {&beta}{sub:i}'x{sub:it} with {&beta}{sup:+}{sub:i}'x{sup:+}{sub:it} +
{&beta}{sup:-}{sub:i}'x{sup:-}{sub:it}.

{pstd}
{bf:CS-ARDL} (Chudik, Mohaddes, Pesaran and Raissi 2017) writes the ARDL(p,q) form

{p 8 8 2}
y{sub:it} = a{sub:i} + {&Sigma}{sub:j=1}{sup:p} {&phi}{sub:ij}y{sub:i,t-j}
+ {&Sigma}{sub:j=0}{sup:q-1} {&beta}{sub:ij}'x{sub:i,t-j}
+ {&Sigma}{sub:k=0}{sup:p_T} {&psi}{sub:k}'z{c -}{sub:t-k} + e{sub:it}{p_end}

{pstd}
and recovers the long-run elasticities through the standard ARDL transformation
{&beta}{sub:LR} = {&Sigma}{sub:j}{&beta}{sub:ij} / (1 {c -} {&Sigma}{sub:j}{&phi}{sub:ij}).  The
{ul:nonlinear} CS-ARDL replaces x with x{sup:+}, x{sup:-}.

{pstd}
{bf:CS-NARDL = nonlinear CS-ARDL in error-correction form}.  The estimated equation in section
{help xtcsnardl_methodology##ecm:6} is the algebraic reparameterisation of the CS-ARDL with
the partial-sum decomposition substituted in.  This unifies short-run and long-run
asymmetric inference in a single regression and exposes the speed of adjustment {&phi}{sub:i}
as an estimable parameter.


{marker estimation}{...}
{title:8. Estimation (PMG / MG / DFE)}

{pstd}
{cmd:xtcsnardl} delegates estimation to {cmd:xtpmg}.  Three flavours are available:

{p 4 4 2}
{bf:PMG (default).}  Long-run coefficients {&beta}{sup:+}, {&beta}{sup:-}, {&beta}{sub:c} and
all CSA loadings are {ul:pooled} (equal across panels); the speed of adjustment {&phi}{sub:i},
the short-run dynamics and the intercept are panel-specific.  Estimation is by maximum
likelihood as in Pesaran, Shin and Smith (1999), implemented in xtpmg via Newton-Raphson.
PMG is the workhorse of the empirical CS-NARDL literature (e.g. Mehta & Derbeneva 2024;
Wang et al. 2022).{p_end}

{p 4 4 2}
{bf:MG.}  All slopes are heterogeneous; the reported estimates are simple cross-section
averages with Pesaran-Smith (1995) standard errors.  Use MG when the Hausman test rejects
long-run pooling.{p_end}

{p 4 4 2}
{bf:DFE.}  All slopes are pooled; only panel-specific intercepts remain.  Useful for very
short T and as a baseline.{p_end}

{pstd}
{bf:Identification.}  Under Pesaran (2006, Assumption A3) and Hacioglu-Hoke & Kapetanios
(2020, Theorem 2):

{p 4 4 2}
{c 149} N, T {c -}> {&infin} with T/N {c -}> {&kappa} {c <=} 1;{p_end}
{p 4 4 2}
{c 149} the factor loadings are i.i.d. and independent of the errors;{p_end}
{p 4 4 2}
{c 149} the CSA proxy set Z{c -}{sub:{&gamma}} = (y{c -}, x{c -}{sup:+}, x{c -}{sup:-}, c{c -})
contains {ul:at least as many series} as the number of factors (rank condition);{p_end}
{p 4 4 2}
{c 149} the cointegrating relationship holds in {ul:each} panel.{p_end}

{pstd}
The PMG estimator is then sqrt(N)-consistent and asymptotically normal.


{marker asymtests}{...}
{title:9. Tests for asymmetry}

{pstd}
For each variable in {opt asymmetric()}, {cmd:xtcsnardl} reports two Wald tests
(asymptotically {&chi}{sup:2}(1)):

{p 4 4 2}
{bf:Long-run asymmetry.}  H{sub:0}: {&beta}{sup:+} = {&beta}{sup:-} against
{&beta}{sup:+} {&ne} {&beta}{sup:-}.  Rejection means the {ul:cumulative} effect of a unit
rise differs in magnitude from the cumulative effect of a unit fall.{p_end}

{p 4 4 2}
{bf:Short-run asymmetry.}  H{sub:0}: {&gamma}{sup:+} = {&gamma}{sup:-}.  Rejection means the
{ul:immediate} response (within the period) differs between rises and falls.{p_end}

{pstd}
A common pattern in the empirical literature is to find {ul:long-run asymmetry without
short-run asymmetry} {hline 2} markets respond symmetrically to rises and falls in the
short run but accumulate the imbalance over the cointegrating horizon.


{marker multipliers}{...}
{title:10. Asymmetric long-run and dynamic multipliers}

{pstd}
{bf:Long-run asymmetric multipliers.}  Read directly from the cointegrating vector:

{p 8 8 2}
m{sup:+}({&infin}) = {&beta}{sup:+},        m{sup:-}({&infin}) = {&beta}{sup:-},
{space 5}{ul:Asymmetry} = {&beta}{sup:+} {c -} {&beta}{sup:-}.
{p_end}

{pstd}
{bf:Cumulative dynamic multipliers.}  For horizon h = 0, 1, 2, ..., {cmd:xtcsnardl} computes

{p 8 8 2}
m{sup:+}(h) = {&Sigma}{sub:k=0}{sup:h} {&part}y{sub:i,t+k} / {&part}x{sup:+}{sub:i,t},
{space 5}m{sup:-}(h) = {&Sigma}{sub:k=0}{sup:h} {&part}y{sub:i,t+k} / {&part}x{sup:-}{sub:i,t}.
{p_end}

{pstd}
Using the AR(1) approximation of the cointegrating recursion under PMG (Shin-Yu-Greenwood-Nimmo
2014, eq. 18), the trajectories satisfy

{p 8 8 2}
m{sup:+}(h+1) = m{sup:+}(h) + {&phi}*(m{sup:+}(h) {c -} {&beta}{sup:+}),     m{sup:+}(0) = 1{p_end}

{p 8 8 2}
m{sup:-}(h+1) = m{sup:-}(h) + {&phi}*(m{sup:-}(h) {c -} {&beta}{sup:-}),     m{sup:-}(0) = -1{p_end}

{pstd}
with {&phi}* the cross-section average of {&phi}{sub:i} over convergent panels.  Both
trajectories converge to their long-run targets at rate {c -}{&phi}*; the {ul:asymmetry
curve} m{sup:+}(h) {c -} m{sup:-}(h) measures the cumulative imbalance.

{pstd}
The {bf:half-life} of disequilibrium is

{p 8 8 2}
HL = ln(2) / |{&phi}*|.
{p_end}

{pstd}
A typical convergent CS-NARDL has |{&phi}*| {c ~}= 0.3 and HL {c ~}= 2.3 periods.


{marker cd}{...}
{title:11. Cross-sectional dependence diagnostics}

{pstd}
After estimation {cmd:xtcsnardl} runs the {bf:Pesaran (2004) CD test} on the residuals:

{p 8 8 2}
CD = sqrt(2T / (N(N-1))) * {&Sigma}{sub:i<j} {&rho}{c -}{sub:ij}    {c -}> N(0,1)
{p_end}

{pstd}
under H{sub:0}: residual cross-sectional independence.  It also reports the average pairwise
correlation {&rho}{c -}{sub:bar} and the {bf:Pesaran (2015) absolute correlation} measure
|{&rho}{c -}{sub:bar}|.

{p 4 4 2}
{c 149} CD p-value > 0.10  {c -}>  CSA augmentation appears sufficient.{p_end}
{p 4 4 2}
{c 149} CD p-value < 0.05  {c -}>  residual CSD remains; increase {opt cr_lags()} or extend
{opt csavars()}.{p_end}

{pstd}
Use {opt nocdtest} to suppress this diagnostic.  For independent confirmation, run
{help xtcd2:xtcd2} on the residuals manually.


{marker interp}{...}
{title:12. How to read CS-NARDL output}

{pstd}
A typical "good" CS-NARDL printout looks like this:

{phang}
{bf:Table 1} {hline 2} {&beta}{sup:+} and {&beta}{sup:-} are both significant but {ul:different
in magnitude or sign}.  Their {ul:CIs do not overlap}.{p_end}

{phang}
{bf:Table 2} {hline 2} {&phi} is negative and significant, half-life under 5 periods, class
{ul:strong} or {ul:moderate}.{p_end}

{phang}
{bf:Table 3} {hline 2} short-run coefficients smaller in magnitude than long-run ones (full
adjustment takes several periods).{p_end}

{phang}
{bf:Table 5} {hline 2} Long-run Wald test rejects (asymmetry confirmed); short-run Wald test
may or may not reject.{p_end}

{phang}
{bf:Table 10} {hline 2} CD test does {ul:not} reject (residuals are weakly dependent after
CSA augmentation).{p_end}

{pstd}
{bf:Red flags to watch for:}

{p 4 6 2}
{c 149} {&phi} positive or {&phi} {c <} {c -}2 {c -}>  no convergence; model is misspecified
or no cointegration.{p_end}

{p 4 6 2}
{c 149} Standard errors of {&beta}{sup:+}/{&beta}{sup:-} larger than the point estimates
{c -}>  weak identification, often from too many CSA lags or too few panels.{p_end}

{p 4 6 2}
{c 149} CD test rejects {c -}>  residual common factors; CSA augmentation insufficient.{p_end}

{p 4 6 2}
{c 149} Hausman test rejects PMG and the per-panel {&phi}{sub:i} are widely dispersed
{c -}>  switch to MG.{p_end}


{title:Further reading}

{phang}{help xtcsnardl_examples:Worked examples} - five complete specifications with output and
interpretation.

{phang}{help xtcsnardl_postestimation:Post-estimation} - {cmd:e()} returns, custom Wald tests,
prediction, manual multipliers.

{phang}{help xtcsnardl_graph:Graphs} - publication-quality plots.

{phang}{help xtcsnardl:Main reference} - syntax and options.


{title:Author}

{pstd}
{bf:Dr Merwan Roudane}{break}
{bf:merwanroudane920@gmail.com}{break}
{cmd:xtcsnardl} v1.0.0, 28 May 2026{p_end}


{title:Also see}

{psee}
Related Stata packages:  {help xtpmg}  {help pnardl}  {help xtdcce2}  {help xtcspqardl}  {help xtcd2}  {help xtcse2}  {help xtbreak}{p_end}
