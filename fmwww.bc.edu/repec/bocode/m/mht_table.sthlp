{smcl}
{* *! version 1.2.0  2026-04-27}{...}
{viewerjumpto "Syntax" "mht_table##syntax"}{...}
{viewerjumpto "Quick start" "mht_table##quick"}{...}
{viewerjumpto "Description" "mht_table##description"}{...}
{viewerjumpto "Options" "mht_table##options"}{...}
{viewerjumpto "Examples" "mht_table##examples"}{...}
{viewerjumpto "Stored results" "mht_table##stored"}{...}
{viewerjumpto "References" "mht_table##refs"}{...}

{title:Title}

{phang}
{bf:mht_table} {hline 2} Table of optimal MHT critical values; reproduces Table 1 of the paper


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:mht_table} [{cmd:,} {it:options}]


{marker quick}{...}
{title:Quick start}

{pstd}{bf:With no arguments, mht_table reproduces Table 1 of the paper EXACTLY}
(Linear/FDA calibration; |J|=1..9 plus infinity; four alphabar values at n/m=100%;
single alphabar=0.025 at n/m=50/150/200%; two Sidak benchmark columns):{p_end}
{phang2}{cmd:. mht_table}{p_end}

{pstd}Same structure under the Cobb-Douglas (J-PAL) calibration:{p_end}
{phang2}{cmd:. mht_table, model(cobbdouglas)}{p_end}

{pstd}Custom: smaller table, single alphabar across user-specified n/m ratios:{p_end}
{phang2}{cmd:. mht_table, alphabar(0.05) jrange(1 2 3 5 9) nmratios(0.5 1.0 2.0)}{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mht_table} displays a table of optimal critical values alpha*(|J|, n/m) under
the model in Viviano, Wuthrich, and Niehaus (2026). When called {bf:with no
arguments}, it reproduces {bf:Table 1 of the paper exactly} -- compound headers,
ten rows (|J|=1..9 and infinity), four alphabar values at n_bar/m_bar=100%, a
single alphabar=0.025 at n_bar/m_bar in {0.5, 1.5, 2.0}, and two Sidak benchmark
columns at alphabar in {0.025, 0.05}.

{pstd}
With one or more of {opt alphabar()}, {opt jrange()}, {opt nmratios()} specified,
the command switches to a {bf:custom layout} with a single alphabar across the
chosen n/m ratios -- useful for quick exploration.

{pstd}
For every cell the command internally calls {helpb mht_critical}; all displayed
values are also stored in {cmd:r()}.


{marker options}{...}
{title:Options}

{dlgtab:Default-mode behavior}

{phang}
With {bf:no arguments}, {cmd:mht_table} reproduces paper Table 1 under the Linear
calibration. Pass {opt model(cobbdouglas)} to switch the calibration while keeping
the Table-1 layout. Pass {opt noinf} to suppress the |J|=Inf row.

{dlgtab:Custom-mode options}

{phang}
{opt alpha:bar(#)} benchmark single-hypothesis significance level. Triggers custom mode.

{phang}
{opt jr:ange(numlist)} J values used as table rows.

{phang}
{opt nmr:atios(numlist)} n/m ratios used as table columns.

{phang}
{opt sidakbars(numlist)} alpha_bar values for Sidak benchmark columns.
Default {bf:0.025 0.05}.

{phang}
{opt nosidak} suppress Sidak columns.

{phang}
{opt noinf} suppress the |J|=Inf row.

{dlgtab:Cost model}

{phang}
{opt mod:el(string)} {bf:linear} (default) or {bf:cobbdouglas}.

{phang}
{opt cfs:hare(#)} fixed cost share (Linear). Default {bf:0.46}.

{phang}
{opt jbar(#)} average number of subgroups (Linear). Default {bf:3}.

{phang}
{opt beta(#)} elasticity wrt |J| (Cobb-Douglas). Default {bf:0.13}.

{phang}
{opt iota(#)} elasticity wrt sample size (Cobb-Douglas). Default {bf:0.075}.


{marker examples}{...}
{title:Examples}

{pstd}{bf:Reproduce paper Table 1 exactly (default mode)}{p_end}
{phang2}{cmd:. mht_table}{p_end}

{pstd}{bf:Same structure, Cobb-Douglas calibration}{p_end}
{phang2}{cmd:. mht_table, model(cobbdouglas)}{p_end}

{pstd}{bf:Custom J range, single alphabar, multiple n/m}{p_end}
{phang2}{cmd:. mht_table, alphabar(0.05) jrange(1 2 3 5 9) nmratios(0.5 1.0 2.0)}{p_end}

{pstd}{bf:Higher benchmark alpha}{p_end}
{phang2}{cmd:. mht_table, alphabar(0.10) jrange(1 2 3 4 5)}{p_end}

{pstd}{bf:Suppress Sidak and infinity row}{p_end}
{phang2}{cmd:. mht_table, alphabar(0.05) nosidak noinf}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:mht_table} stores the following in {cmd:r()}:

{synoptset 28 tabbed}{...}
{p2col 5 28 32 2: Default mode (paper Table 1)}{p_end}
{synopt:{cmd:r(alpha_}{it:j}{cmd:_100_}{it:ab}{cmd:)}}optimal alpha at |J|={it:j}, n/m=100%, alphabar={it:ab}{p_end}
{synopt:{cmd:r(alpha_}{it:j}{cmd:_}{it:nm}{cmd:_0p025)}}optimal alpha at |J|={it:j}, n/m={it:nm}, alphabar=0.025{p_end}
{synopt:{cmd:r(sidak_}{it:ab}{cmd:_}{it:j}{cmd:)}}Sidak level at |J|={it:j}, alphabar={it:ab}{p_end}

{p2col 5 28 32 2: Custom mode}{p_end}
{synopt:{cmd:r(alpha_}{it:j}{cmd:_}{it:nm}{cmd:)}}optimal alpha for |J|={it:j}, nm_ratio={it:nm}{p_end}
{synopt:{cmd:r(alpha_bar)}}benchmark alpha used{p_end}

{p2col 5 28 32 2: Macros}{p_end}
{synopt:{cmd:r(model)}}cost model used (linear or cobbdouglas){p_end}

{pstd}
Decimal points in {it:nm} and {it:ab} keys are replaced by 'p' (e.g.
{cmd:r(alpha_3_100_0p025)} for |J|=3, n/m=100%, alphabar=0.025).


{marker refs}{...}
{title:References}

{phang}
Viviano, D., K. Wuthrich, and P. Niehaus (2026).
{it:A model of multiple hypothesis testing}. arXiv:2104.13367v10.
{p_end}


{title:Also see}

{psee}
Online: {help mht_critical}, {help mht_test}, {help mht_est}, {help mht_cost_estimate}
{p_end}
