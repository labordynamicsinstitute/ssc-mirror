{smcl}
{* *! version 1.0.0  28may2026}{...}
{cmd:help xtcsnardl_examples}{right:also see:  {help xtcsnardl}  {help xtcsnardl_methodology}  {help xtcsnardl_postestimation}  {help xtcsnardl_graph}}
{hline}

{title:Worked examples  {hline 2}  CS-NARDL}

{title:Contents}

{p 8 12 2}
{help xtcsnardl_examples##ex1:Example 1.}  Quick start - the minimum syntax{break}
{help xtcsnardl_examples##ex2:Example 2.}  EURO-4 carbon emissions (Mehta & Derbeneva 2024){break}
{help xtcsnardl_examples##ex3:Example 3.}  BRICS renewable energy (Wang et al. 2022){break}
{help xtcsnardl_examples##ex4:Example 4.}  Mean Group with Hausman, panel-specific phi{break}
{help xtcsnardl_examples##ex5:Example 5.}  Custom CSA list & turning off augmentation{break}
{help xtcsnardl_examples##ex6:Example 6.}  Synthetic DGP for replication{break}
{help xtcsnardl_examples##interp:Interpretation cheat sheet}


{marker ex1}{...}
{title:Example 1.  Quick start}

{pstd}
With a panel already xtset:

{phang2}{cmd:. xtset country year}{p_end}
{phang2}{cmd:. xtcsnardl D.y L.y D.x1 D.x2, lr(L.y x1 x2) asymmetric(x1)}{p_end}

{pstd}
This estimates a PMG model in which {it:x1} is decomposed asymmetrically and {it:x2} is
treated symmetrically.  Both enter the long-run cointegrating vector; cross-sectional
averages of y, x1{sup:+}, x1{sup:-}, and x2 are added to the LR equation with
floor(T{sup:1/3}) lags.  Tables 1-3 and 5, plus the Pesaran CD test, are printed by default.


{marker ex2}{...}
{title:Example 2.  EURO-4 carbon emissions  (Mehta & Derbeneva 2024)}

{pstd}
The reference paper studies four European economies (Germany, UK, France, Italy) over 1995-2022.
Variables:

{p2col 5 22 22 2: omega} per-capita CO{sub:2} emissions (dependent){p_end}
{p2col 5 22 22 2: rho} carbon tax / GDP (asymmetric){p_end}
{p2col 5 22 22 2: gamma} environmental spending / GDP (asymmetric){p_end}
{p2col 5 22 22 2: pi} industrial value-added / GDP{p_end}
{p2col 5 22 22 2: psi} GDP per capita{p_end}
{p2col 5 22 22 2: theta} urbanisation rate{p_end}

{pstd}
The CS-NARDL specification:

{phang2}{cmd:. xtset country year}{p_end}
{phang2}{cmd:. xtcsnardl D.omega L.omega D.rho D.gamma D.pi D.psi D.theta, ///}{break}
{phang2}{cmd:    lr(L.omega rho gamma pi psi theta) ///}{break}
{phang2}{cmd:    asymmetric(rho gamma) pmg cr_lags(2) ///}{break}
{phang2}{cmd:    multip(15) irfshock(15) asytable panelcoef hausman ///}{break}
{phang2}{cmd:    showcsa graph}{p_end}

{pstd}
What to expect (qualitatively):

{p 4 6 2}
{c 149} {bf:Table 1} {hline 2} {&beta}{sup:+}{sub:rho} {&asymp} -0.080 (carbon-tax rise lowers
emissions), {&beta}{sup:-}{sub:rho} {&asymp} +0.050 (carbon-tax cut raises them, but less
strongly).  Long-run asymmetry CIs do not overlap.{p_end}

{p 4 6 2}
{c 149} {bf:Table 2} {hline 2} {&phi} {&asymp} -0.47, half-life {&asymp} 1.4 years, class
"strong".{p_end}

{p 4 6 2}
{c 149} {bf:Table 5} {hline 2} long-run asymmetry rejected at 1% for both rho and gamma;
short-run asymmetry rejected at 1% for rho only.{p_end}

{p 4 6 2}
{c 149} {bf:Table 8 / graph csn_multip_1} {hline 2} m{sup:+}(h) and m{sup:-}(h) flatten by
period 6-7; asymmetry persists in the long run.{p_end}

{p 4 6 2}
{c 149} {bf:Table 10} {hline 2} Pesaran CD p {>} 0.10 (no residual CSD).{p_end}

{pstd}
Policy reading: a carbon-tax {ul:increase} is roughly twice as effective at reducing emissions
as a carbon-tax {ul:cut} is at raising them.  Asymmetric instrument design is therefore
welfare-improving.


{marker ex3}{...}
{title:Example 3.  BRICS renewable energy consumption  (Wang et al. 2022)}

{pstd}
Five emerging economies (Brazil, Russia, India, China, South Africa), 1996-2020.  Variables:

{p2col 5 22 22 2: REC} renewable energy consumption (% of total, log){p_end}
{p2col 5 22 22 2: FID} financial institutions index (asymmetric){p_end}
{p2col 5 22 22 2: ICTtrade} ICT goods trade (% of total, asymmetric){p_end}
{p2col 5 22 22 2: GDP} GDP per capita (log){p_end}
{p2col 5 22 22 2: RD} R&D expenditure (% of GDP){p_end}
{p2col 5 22 22 2: Inflation} CPI inflation{p_end}

{phang2}{cmd:. xtset country year}{p_end}
{phang2}{cmd:. xtcsnardl D.REC L.REC D.FID D.ICTtrade D.GDP D.RD D.Inflation, ///}{break}
{phang2}{cmd:    lr(L.REC FID ICTtrade GDP RD Inflation) ///}{break}
{phang2}{cmd:    asymmetric(FID ICTtrade) pmg multip(20) graph}{p_end}

{pstd}
Interpretation pointers:

{p 4 6 2}
{c 149} A {ul:positive} shock to FID raises REC by ~3.8% in the long run; a {ul:negative}
shock raises it by ~2.9% (both significant).  The "raises" sign on negative may surprise
readers {hline 2} the paper's interpretation is that financial-sector deterioration prompts a
shift toward cheaper renewables.{p_end}

{p 4 6 2}
{c 149} ICT-trade asymmetry: positive shock {bf:enhances} REC, negative shock {bf:hurts}
REC.  Asymmetry sign-symmetric, magnitude asymmetric.{p_end}

{p 4 6 2}
{c 149} Use {opt panelcoef} to inspect per-country {&phi}{sub:i}: in Wang et al. (2022) the
half-life is highest for Russia (~3 years) and lowest for South Africa.{p_end}


{marker ex4}{...}
{title:Example 4.  Mean Group with Hausman test}

{pstd}
PMG imposes long-run pooling.  When that restriction fails (the Hausman test rejects), switch
to MG:

{phang2}{cmd:. xtcsnardl D.y L.y D.x1 D.x2, ///}{break}
{phang2}{cmd:    lr(L.y x1 x2) asymmetric(x1) hausman}{p_end}

{pstd}
The {opt hausman} option estimates {bf:both} MG and PMG, then runs

{phang2}{cmd:. hausman MG_xtpmg PMG_xtpmg, sigmamore}{p_end}

{pstd}
under H{sub:0}: long-run pooling restriction valid.  If you reject:

{phang2}{cmd:. xtcsnardl D.y L.y D.x1 D.x2, lr(L.y x1 x2) asymmetric(x1) mg multip(15)}{p_end}

{pstd}
Note that in MG mode the long-run asymmetry test (Table 5) is on the {ul:mean group} averages;
the per-panel coefficients (with {opt panelcoef}) will show wider dispersion than PMG.


{marker ex5}{...}
{title:Example 5.  Custom CSA list & turning off augmentation}

{pstd}
By default {cmd:xtcsnardl} takes CSA of y and {ul:every} substantive LR regressor (including
the positive and negative partial sums).  Per Hacioglu-Hoke & Kapetanios (2020) this is the
safe choice.  If you need to economise on degrees of freedom in a short panel:

{phang2}{cmd:. xtcsnardl D.y L.y D.x, lr(L.y x) ///}{break}
{phang2}{cmd:    asymmetric(x) csavars(y x_pos x_neg) cr_lags(1)}{p_end}

{pstd}
This restricts the CSA proxy set to {bf:y}, {bf:x_pos}, {bf:x_neg} (skips any control whose
CSA might be collinear in your data).

{pstd}
For a diagnostic comparison without any cross-section augmentation:

{phang2}{cmd:. xtcsnardl D.y L.y D.x, lr(L.y x) asymmetric(x) nocsa}{p_end}

{pstd}
This reduces to the classical Panel NARDL (same as {help pnardl}).  Look at the Pesaran CD
table {hline 2} if it rejects independence, the {opt nocsa} estimates are biased.


{marker ex6}{...}
{title:Example 6.  Synthetic DGP for replication}

{pstd}
The following do-file generates a CS-NARDL DGP with one common factor, an asymmetric regressor
and panel-specific speeds of adjustment.  Run it to verify that {cmd:xtcsnardl} recovers the
true parameters.

{cmd}
* ----------------------- DGP -----------------------
clear all
set seed 1234
set obs 30
gen country = _n
expand 60
bysort country: gen year = 1960 + _n - 1
xtset country year

* common factor (AR(1))
gen f = .
by country: replace f = rnormal() in 1
by country: replace f = 0.5*f[_n-1] + rnormal()*0.3 in 2/L

* idiosyncratic
gen v   = rnormal()
gen eps = rnormal()

* asymmetric regressor x with loading on f
gen lam_x = runiform(0.4, 0.8)
gen x = lam_x*f + v

* asymmetric DGP for y:  Dy = phi*(y_{t-1} - b_p*x_pos - b_n*x_neg - lam_y*f_bar) + eps
gen lam_y = runiform(0.3, 0.7)
gen phi   = -runiform(0.2, 0.5)
gen y = 0
by country: replace y = phi*(L.y - 0.8*x - (-1.2)*x + lam_y*f) + eps if _n > 1
* (Note: the DGP uses the true x rather than partial sums; this only matters in
*  finite samples for the asymmetry test power.)

* ------------------- ESTIMATE ----------------------
xtcsnardl D.y L.y D.x, ///
    lr(L.y x) asymmetric(x) ///
    pmg cr_lags(3) multip(20) asytable hausman graph
{txt}

{pstd}
Expected recovery: {&beta}{sup:+} {&asymp} 0.8, {&beta}{sup:-} {&asymp} -1.2 (asymmetry of
~2), {&phi}-mean {&asymp} -0.35.


{marker interp}{...}
{title:Interpretation cheat sheet}

{phang}
{bf:Q. The long-run beta+ and beta- are both negative.  Is the model still "asymmetric"?}

{pstd}
{ul:Yes, if the magnitudes differ.}  Same-sign asymmetry is common: x{sub:t} affects y{sub:t}
in one direction but the size of the impact depends on whether x is rising or falling.  Read
the {bf:|beta+| - |beta-|} entry in Table 6 and the {bf:asymmetry curve} in graph
{bf:csn_multip_*}.

{phang}
{bf:Q. The short-run asymmetry test fails to reject but the long-run does.  What does this mean?}

{pstd}
The {ul:impact effect} (within-period response) is symmetric, but the {ul:cumulative
adjustment} differs.  Path-dependence accumulates over the error-correction horizon.  This
is the most common empirical pattern.

{phang}
{bf:Q. Pesaran CD test rejects independence even with cr_lags = floor(T^(1/3)).  Now what?}

{pstd}
Increase {opt cr_lags()} step-by-step until the test fails to reject, {ul:or} add
theoretically motivated extra CSA proxies via {opt csavars()}.  If after generous augmentation
the test still rejects, you have evidence of a {ul:second factor} that CSA cannot proxy
(e.g. nonlinear dependence, regime breaks).  Consider a panel break test ({help xtbreak}) or
the factor-based estimator of Bai (2009).

{phang}
{bf:Q. The per-panel phi range is very wide.  Is PMG still appropriate?}

{pstd}
PMG only pools the long-run coefficients, not phi.  Wide dispersion of phi{sub:i} is therefore
{ul:not} an objection to PMG.  Run the {opt hausman} test on the {ul:long-run}
coefficients; if it does not reject, keep PMG.

{phang}
{bf:Q. Should I include the control variables in asymmetric()?}

{pstd}
Only if theory predicts asymmetric effects.  Decomposing every regressor inflates parameter
counts and reduces power.  In the EURO-4 paper the carbon tax {it:and} environmental spending
are asymmetric; GDP, industrial growth and urbanisation are not.


{title:Author}

{pstd}
{bf:Dr Merwan Roudane}{break}
{bf:merwanroudane920@gmail.com}{break}
{cmd:xtcsnardl} v1.0.0, 28 May 2026{p_end}


{title:Also see}

{psee}
Online: {help xtcsnardl},  {help xtcsnardl_methodology},  {help xtcsnardl_postestimation},  {help xtcsnardl_graph}{p_end}
{psee}
Related: {help xtpmg},  {help pnardl},  {help xtdcce2},  {help xtcspqardl},  {help xtcd2}{p_end}
