{smcl}
{* *! version 1.0.2  24may2026}{...}
{vieweralsosee "[asycaus] main" "help asycaus"}{...}
{vieweralsosee "asycaus static" "help asycaus_static"}{...}

{title:Title}

{phang}{bf:asycaus efficient} {hline 2} Hatemi-J (2024) efficient asymmetric causality tests (SUR-based)

{title:Syntax}

{p 8 17 2}
{cmd:asycaus efficient} {it:depvar} {it:causvar} {ifin} [{cmd:,} {it:options}]

{title:Description}

{pstd}
{bf:Hatemi-J (2024)} argues that running two independent VARs on the positive
and negative components is inefficient because residuals across the two
systems are correlated. He proposes a {bf:seemingly unrelated regression}
(SUR) joint estimation that exploits the cross-equation covariance. Within
that single system four hypotheses are tested:{p_end}

{phang}{bf:H1.} No causality from {it:causvar} to {it:depvar} via POSITIVE shocks{p_end}
{phang}{bf:H2.} No causality from {it:causvar} to {it:depvar} via NEGATIVE shocks{p_end}
{phang}{bf:H3.} Joint no causality (H1 AND H2){p_end}
{phang}{bf:H4.} {bf:Equality of positive and negative causal coefficients} — the key asymmetry test introduced by the paper. Rejection means the positive and negative causal mechanisms differ in size.{p_end}

{title:Options}

{synoptset 22 tabbed}{...}
{synopt :{opt maxl:ag(#)}}max VAR lag (default 8){p_end}
{synopt :{opt ic(string)}}IC (default hjc){p_end}
{synopt :{opt into:rder(#)}}TY augmentation lags (default 1){p_end}
{synopt :{opt ln:form}}log of inputs{p_end}
{synopt :{opt nograph}}suppress graph{p_end}
{synopt :{opt sav:ing(name)}}save graph{p_end}

{title:Examples}

{phang}{stata "webuse lutkepohl2, clear"}{p_end}
{phang}{stata "tsset qtr"}{p_end}
{phang}{stata "asycaus efficient dln_inv dln_inc, maxlag(4)"}{p_end}

{title:Stored results}

{synoptset 22 tabbed}{...}
{synopt :{cmd:r(Wpos)} {cmd:r(p_pos)}}Wald and p-value for H1: no Pos causality{p_end}
{synopt :{cmd:r(Wneg)} {cmd:r(p_neg)}}H2: no Neg causality{p_end}
{synopt :{cmd:r(Wjoint)} {cmd:r(p_joint)}}H3: joint{p_end}
{synopt :{cmd:r(Wdiff)} {cmd:r(p_diff)}}H4: equality Pos = Neg{p_end}
{synopt :{cmd:r(dof)}}degrees of freedom (= lag p){p_end}

{title:References}

{phang}Hatemi-J, A. (2024). Efficient Asymmetric Causality Tests. {it:arXiv} 2408.03137.{p_end}

{title:Author}
{pstd}{bf:Dr Merwan Roudane} {hline 2} {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
{pstd}See {help asycaus:asycaus} for the package overview.{p_end}
