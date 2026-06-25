{smcl}
{* *! version 0.1.0 08jun2026}{...}
{title:ordaxaca}

{p2colset 5 22 24 2}{...}
{p2col:{hi:ordaxaca} {hline 2}}Nonlinear Oaxaca decomposition for ordered outcomes{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 15 2}
{cmd:ordaxaca} {it:depvar} {it:indepvars} {ifin} {weight},
{cmd:by(}{it:groupvar}{cmd:)}
{cmd:base(}{it:#}{cmd:)}
{cmd:compare(}{it:#}{cmd:)}
[
{cmd:model(ologit|oprobit)}
{cmd:outcomes(}{it:numlist}{cmd:)}
{cmd:svy}
{cmd:estopts(}{it:string}{cmd:)}
]

{title:Description}

{pstd}
{cmd:ordaxaca} estimates a twofold nonlinear Oaxaca decomposition for ordered
dependent variables. The command estimates separate ordered logit or ordered
probit models for a base group and a comparison group. It then decomposes
differences in predicted outcome probabilities into explained and unexplained
components.

{pstd}
For each requested ordered outcome category k, the command computes the base
group's mean predicted probability, the comparison group's mean predicted
probability, and a counterfactual mean predicted probability that applies the
base group's coefficient structure to the comparison group's covariate
distribution.

{title:Options}

{phang}
{cmd:by(}{it:groupvar}{cmd:)} specifies the grouping variable. This option is
required.

{phang}
{cmd:base(}{it:#}{cmd:)} specifies the base group. The reported difference is
base minus comparison. This option is required.

{phang}
{cmd:compare(}{it:#}{cmd:)} specifies the comparison group. This option is
required.

{phang}
{cmd:model(ologit|oprobit)} specifies the ordered-response model. The default is
{cmd:model(ologit)}.

{phang}
{cmd:outcomes(}{it:numlist}{cmd:)} specifies which outcome categories to
decompose. If omitted, all observed outcome categories are used.

{phang}
{cmd:svy} requests survey estimation using the current {cmd:svyset} design. When
{cmd:svy} is specified, the command estimates group-specific models using
{cmd:svy, subpop()}.

{phang}
{cmd:estopts(}{it:string}{cmd:)} passes additional estimation options to
{cmd:ologit} or {cmd:oprobit}.

{title:Decomposition}

{pstd}
For outcome category k, define:

{p 8 12 2}
Base mean: Pr(Y=k | X_base, b_base){p_end}

{p 8 12 2}
Counterfactual mean: Pr(Y=k | X_compare, b_base){p_end}

{p 8 12 2}
Comparison mean: Pr(Y=k | X_compare, b_compare){p_end}

{pstd}
The command reports:

{p 8 12 2}
Diff = Base mean - Comparison mean{p_end}

{p 8 12 2}
Explained = Base mean - Counterfactual mean{p_end}

{p 8 12 2}
Unexplained = Counterfactual mean - Comparison mean{p_end}

{title:Examples}

{pstd}
Basic ordered logit decomposition:

{phang2}
{cmd:. ordaxaca y x1 x2 i.x3, by(group) base(0) compare(1) outcomes(1 2 3)}
{p_end}

{pstd}
Ordered probit decomposition:

{phang2}
{cmd:. ordaxaca y x1 x2 i.x3, by(group) base(0) compare(1) outcomes(1 2 3) model(oprobit)}
{p_end}

{pstd}
Survey design example:

{phang2}
{cmd:. svyset psu [pweight=weight], strata(strata) singleunit(centered)}
{p_end}

{phang2}
{cmd:. ordaxaca y x1 x2 i.x3, by(group) base(0) compare(1) outcomes(1 2 3) svy}
{p_end}

{pstd}
Bootstrap example:

{phang2}
{cmd:. bootstrap diff_out3=_b[diff_out3] expl_out3=_b[expl_out3] unex_out3=_b[unex_out3], reps(500) seed(123): ordaxaca y x1 x2 i.x3, by(group) base(0) compare(1) outcomes(3)}
{p_end}

{title:Stored results}

{pstd}
{cmd:ordaxaca} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{synopt:{cmd:e(b)}}row vector of decomposition estimates{p_end}
{synopt:{cmd:e(V)}}variance matrix; zero matrix unless resampled externally{p_end}
{synopt:{cmd:e(decomp)}}matrix with outcome, base mean, counterfactual mean, comparison mean, difference, explained, and unexplained components{p_end}
{synopt:{cmd:e(N_base)}}number of observations in the base group{p_end}
{synopt:{cmd:e(N_compare)}}number of observations in the comparison group{p_end}
{synopt:{cmd:e(cmd)}}{cmd:ordaxaca}{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}independent variables{p_end}
{synopt:{cmd:e(by)}}grouping variable{p_end}
{synopt:{cmd:e(model)}}ordered-response model used{p_end}
{synopt:{cmd:e(outcomes)}}outcome categories decomposed{p_end}
{synopt:{cmd:e(base)}}base group{p_end}
{synopt:{cmd:e(compare)}}comparison group{p_end}
{synopt:{cmd:e(svy)}}survey option indicator{p_end}

{title:Remarks}

{pstd}
The decomposition is descriptive unless supported by a credible causal research
design. The unexplained component should not automatically be interpreted as
discrimination or as a causal structural effect.

{pstd}
For ordered logit, the model relies on the proportional-odds assumption. For
ordered probit, the analogous single-index threshold structure is assumed.

{pstd}
Poor overlap in covariates across groups can make counterfactual predictions
fragile. Users should inspect covariate overlap and conduct robustness checks.

{pstd}
This version reports aggregate twofold decomposition components. It does not yet
implement detailed variable-by-variable decomposition.

{title:Author}

{pstd}
Refat Mishuk{break}
UNM{break}
mishuk.refat@gmail.com