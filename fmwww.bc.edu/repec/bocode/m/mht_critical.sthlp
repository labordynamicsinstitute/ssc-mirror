{smcl}
{* *! version 1.1.0  2026-04-27}{...}
{viewerjumpto "Syntax" "mht_critical##syntax"}{...}
{viewerjumpto "Quick start" "mht_critical##quick"}{...}
{viewerjumpto "Description" "mht_critical##description"}{...}
{viewerjumpto "Options" "mht_critical##options"}{...}
{viewerjumpto "Examples" "mht_critical##examples"}{...}
{viewerjumpto "Stored results" "mht_critical##stored"}{...}
{viewerjumpto "References" "mht_critical##refs"}{...}

{title:Title}

{phang}
{bf:mht_critical} {hline 2} Compute the optimal per-test significance level for multiple hypothesis testing


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mht_critical}{cmd:,} {opt j:hypotheses(#)} {opt alpha:bar(#)} [{it:options}]


{marker quick}{...}
{title:Quick start}

{pstd}Optimal alpha for 5 hypotheses, Linear/FDA calibration, alphabar=0.05:{p_end}
{phang2}{cmd:. mht_critical, jhypotheses(5) alphabar(0.05)}{p_end}

{pstd}Same with Cobb-Douglas / J-PAL calibration:{p_end}
{phang2}{cmd:. mht_critical, jhypotheses(5) alphabar(0.05) model(cobbdouglas)}{p_end}

{pstd}Linear model with a larger-than-benchmark sample (less conservative threshold):{p_end}
{phang2}{cmd:. mht_critical, jhypotheses(3) alphabar(0.025) nmratio(1.5)}{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mht_critical} computes the optimal per-test significance level alpha* for
multiple hypothesis testing based on Proposition 4.1 of Viviano, Wuthrich, and
Niehaus (2026):

{pmore}
alpha*(J, n/m) = C(J, n/m) / (b * omega_bar(J))

{pstd}
where C is the research cost function, b is the per-unit benefit of a true
rejection, and omega_bar is the sum of treatment weights. The command
also reports Bonferroni and Sidak critical values for comparison.

{pstd}
Two cost-function calibrations are supported:

{phang2}{bf:Linear model} (Equation 26): C = c_f + c_v * |J| * n, calibrated to
clinical-trial data (Sertkaya et al. 2016).{p_end}

{phang2}{bf:Cobb-Douglas model} (Appendix A): C = k * |J|^beta * n^iota, calibrated
to J-PAL field-experiment data.{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt j:hypotheses(#)} number of hypotheses |J| (positive integer).

{phang}
{opt alpha:bar(#)} benchmark single-hypothesis test size, in (0, 1).

{dlgtab:Cost model}

{phang}
{opt mod:el(string)} {bf:linear} (default) or {bf:cobbdouglas}.

{dlgtab:Linear model parameters}

{phang}
{opt cfs:hare(#)} fixed cost share c_f / E[C]. Default {bf:0.46}.

{phang}
{opt jbar(#)} average number of subgroups. Default {bf:3}.

{phang}
{opt nmr:atio(#)} per-arm-to-benchmark sample size ratio. Default {bf:1.0}.

{dlgtab:Cobb-Douglas parameters}

{phang}
{opt beta(#)} elasticity wrt |J|. Default {bf:0.13}.

{phang}
{opt iota(#)} elasticity wrt sample size. Default {bf:0.075}.


{marker examples}{...}
{title:Examples}

{pstd}Basic usage with Linear calibration:{p_end}
{phang2}{cmd:. mht_critical, jhypotheses(5) alphabar(0.05)}{p_end}

{pstd}Cobb-Douglas with J-PAL parameters:{p_end}
{phang2}{cmd:. mht_critical, jhypotheses(5) alphabar(0.05) model(cobbdouglas) beta(0.13) iota(0.075)}{p_end}

{pstd}Linear with a non-benchmark sample size:{p_end}
{phang2}{cmd:. mht_critical, jhypotheses(3) alphabar(0.025) nmratio(1.5)}{p_end}

{pstd}Loop to reproduce a portion of Table 1:{p_end}
{phang2}{cmd:. forvalues j = 1/9 {c -(}}{p_end}
{phang2}{cmd:.     mht_critical, jhypotheses(`j') alphabar(0.05)}{p_end}
{phang2}{cmd:.     display "J=`j': alpha_opt = " r(alpha_opt)}{p_end}
{phang2}{cmd:. {c )-}}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:mht_critical} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(alpha_opt)}}optimal test size{p_end}
{synopt:{cmd:r(t_star)}}optimal z-threshold{p_end}
{synopt:{cmd:r(alpha_bonf)}}Bonferroni test size{p_end}
{synopt:{cmd:r(t_bonf)}}Bonferroni z-threshold{p_end}
{synopt:{cmd:r(alpha_sidak)}}Sidak test size{p_end}
{synopt:{cmd:r(t_sidak)}}Sidak z-threshold{p_end}
{synopt:{cmd:r(alpha_bar)}}benchmark alpha (input){p_end}
{synopt:{cmd:r(J)}}number of hypotheses{p_end}
{synopt:{cmd:r(nm_ratio)}}sample size ratio used{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(model)}}cost model used{p_end}


{marker refs}{...}
{title:References}

{phang}
Viviano, D., K. Wuthrich, and P. Niehaus (2026).
{it:A model of multiple hypothesis testing}. arXiv:2104.13367v10.
{p_end}

{phang}
Sertkaya, A., H.-H. Wong, A. Jessup, and T. Beleche (2016).
Key cost drivers of pharmaceutical clinical trials in the United States.
{it:Clinical Trials} 13(2), 117-126.
{p_end}


{title:Also see}

{psee}
Online: {help mht_test}, {help mht_est}, {help mht_table}, {help mht_cost_estimate}
{p_end}
