{smcl}
{* *! Sep2021}{...}
{hline}
{cmd:help ivolsdec}
{hline}

{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{hi:ivolsdec} {hline 2}}Decomposition of the IV-OLS coefficient gap{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 11 2} {cmd:ivolsdec} {it:outcome}
{cmd:(}{it:treatment}{cmd:=}{it:instruments}{cmd:)} {it:covariates} [{it:weight}] [{cmd:if} {it:exp}]
[{cmd:,} {cmdab:xnb:asis(}{it:varlist}{cmd:)}
{bind:{cmdab:wb:asis(}{it:varlist}{cmd:)}}
{bind:{cmdab:xib:asis(}{it:varlist}{cmd:)}}
{bind:{cmd:vce(}{it:vcetype}{cmd:)}}
{cmd:did}
{cmdab:rd:d}
{cmdab:bin:ary}
{bind:{cmdab:tl:evel(}{it:numlist}{cmd:)}}
{bind:{cmdab:cg:roup(}{it:varlist}{cmd:)}}
{bind:{cmd:format(}{it:fmt}{cmd:)}]}{p_end}

{pstd}{cmd:aweight}s, {cmd:fweight}s, {cmd:iweight}s and {cmd:pweight}s are allowed; see help {help weights}.{p_end}
{pstd}Factor variables are allowed in {it:instruments}, {it:covariates}, {cmdab:xnb:asis}, {cmdab:wb:asis}, {cmdab:xib:asis}, and {cmdab:cg:roup}.{p_end}

{title:Description}

{pstd}
{cmd:ivolsdec} performs a decomposition of the IV-OLS coefficient gap suggested by Ishimaru (2021). This decomposition accounts for nonlinearity and observed heterogeneity in a relation between the outcome variable and the treatment variable, generalizing the one suggested by Lochner and Moretti (2015).{p_end}

{pstd}
In the language of causal inference, {it:outcome} is an outcome variable (Y),
{it:treatment} is a treatment variable (X), {it:instruments} is a set of instruments (Z),
and {it:covariates} is a set of covariates (W).
The decomposition allows for the possibility that the true causal impact of X on Y is nonlinear in X and heterogeneous across W,
and assesses how the IV-OLS gap is influenced by the way in which IV and OLS estimates put weights on X and W. In particular, the IV-OLS gap is decomposed into the following three components.{p_end}
{p 5 5}(1) Covariate weight difference: the difference in how the IV and OLS coefficients place weights on the covariates W.{p_end}
{p 5 5}(2) Treatment-level weight difference: the difference in how they place weights on treatment levels X.{p_end}
{p 5 5}(3) Marginal effect difference: the difference between the IV- and OLS-identified marginal effects, which usually originates from endogeneity bias.{p_end}
{pstd} See Ishimaru (2021) for complete details about the underlying theoretical framework.{p_end}

{pstd}
In computing the decomposition, this command performs the following two auxiliary OLS regressions:{p_end}
{p 5} Y = W'a1 + (q(W)'b1)*X + e1, and{p_end}
{p 5} Y = W'a2 + (q(W)'b2)*X + q(W)'(C2)r(X) + p(X)'d2 + e2,{p_end}
{pstd} where q(W) is a set of basis functions of W specified by {cmdab:wb:asis} (the default is q(W)=W),
r(X) is a set of basis functions of X specified by {cmdab:xib:asis} (the default is r(X)=0),
and p(X) is a set of basis functions of X specified by {cmdab:xnb:asis} (must be chosen by the user).
In principle, q(W)'b1 in the first equation above should approximate a covariate-specific OLS coefficient b_OLS(W)=Cov(Y,X|W)/Var(X|W) well and the second equation as a whole should approximate E[Y|X,W] well. For practical convenience, this command uses simple series approximiations specified above. Users who want to work with a more flexible specification may refer to Section 4 of Ishimaru (2021) to implement the decomposition on their own.{p_end}

{pstd}
If neither {cmd:did} nor {cmdab:rd:d} option is active, the decomposition assumes that both E[X|W] and E[Z|W] are (approximately) linear in W, so that the original OLS and IV coefficients do not have omitted variable bias associated with unaccounted nonlinear effects of covariates. This linearity requirement is satisfied automatically if a vector W consists of indicators for disjoint groups. However, the choice of a covariate vector W requires caution in general. In the presence of continuous covariates, for example, it is desirable that a vector W flexibly accounts for nonlinear and interaction effects of these variables.{p_end}

{title:Options}

{phang}{cmd:xnbasis} specifies the basis functions of X not interacted with {cmd:wbasis}. {ul:This option is required} unless the option {cmd:binary} is active.{p_end}

{phang}{cmd:wbasis} specifies the basis functions of W that are interacted with X and {cmd:xibasis}. If not specified, variables in {it:covariates} are used.{p_end}

{phang}{cmd:xibasis} specifies the basis functions of X that are interacted with {cmd:wbasis}.{p_end}

{phang}{cmd:vce} specifies the type of standard errors reported. The default is {cmd:robust}. {it:vcetype} admits standard options in {cmd:regress} and {cmd:ivregress} commands, such as ({cmd:cluster} {it:clustvar}).{p_end}

{phang}{cmd:did} indicates that the original IV regression uses difference-in-differences variation in the instruments for identification; see Section 3 of Ishimaru (2021).{p_end}

{phang}{cmd:rdd} indicates that the original IV regression implements (fuzzy) regression discontinuity designs; see Section 3 of Ishimaru (2021).{p_end}

{phang}{cmd:binary} must be specified when {it:treatment} is a binary variable. The treatment-level weight difference is zero by construction in such a setting.

{phang}{cmd:tlevel} designates treatment levels. The OLS and IV weights on the degignated treatment levels will be displayed. In Ishimaru (2021), Figure 1 displays an empirical example and Appendix D.4 describes how to estimate the weights.

{phang}{cmd:cgroup} designates covariate groups. The variables in {it:varlist} must be binary and be generated from {it:covariates}. The OLS and IV weights on the designated covariate groups will be displayed. In Ishimaru (2021), Tables 2-4 present empirical examples and Appendix D.4 describes how to estimate the weights.

{phang}{cmd:format} specifies numerical display formats of the results; see help {help format}.{p_end}


{marker s_examples}{title:Example}

{pstd}Load Card (1995) data{p_end}
{phang2}{bf:{stata "use http://www.stata.com/data/jwooldridge/eacsap/card, clear" : . use http://www.stata.com/data/jwooldridge/eacsap/card, clear}}{p_end}

{pstd} Run OLS and IV regressions as usual ({cmd:ivolsdec} works even without running these commands beforehand) {p_end}
{phang2}{bf:{stata "regress lwage educ age black smsa66 south66 sinmom14 kww, robust" : . regress lwage educ age black smsa66 south66 sinmom14 kww, robust}}{p_end}
{phang2}{bf:{stata "ivregress 2sls lwage (educ=nearc4) age black smsa66 south66 sinmom14 kww, robust" : . ivregress 2sls lwage (educ=nearc4) age black smsa66 south66 sinmom14 kww, robust}}{p_end}

{pstd}Run {cmd:ivolsdec} command to decompose the IV-OLS gap{p_end}
{phang2}{bf:{stata "ivolsdec lwage (educ=nearc4) age black smsa66 south66 sinmom14 kww, xnb(i.educ) format(%7.3f)" : . ivolsdec lwage (educ=nearc4) age black smsa66 south66 sinmom14 kww, xnb(i.educ) format(%7.3f)}}{p_end}

{pstd}May try a different specification{p_end}
{phang2}{bf:{stata "gen educ_c=max(educ-12,0)" : . gen educ_c=max(educ-12,0)}}{p_end}
{phang2}{bf:{stata "ivolsdec lwage (educ=nearc4) age black smsa66 south66 sinmom14 kww, xnb(i.educ) xib(educ_c) format(%7.3f)" : . ivolsdec lwage (educ=nearc4) age black smsa66 south66 sinmom14 kww, xnb(i.educ) xib(educ_c) format(%7.3f)}}{p_end}

{pstd}Display weights on covariate groups and treatment levels in addition to the decomposition{p_end}
{phang2}{bf:{stata "xtile kww_g=kww, nq(3)" : . xtile kww_g=kww, nq(3)}}{p_end}
{phang2}{bf:{stata "ivolsdec lwage (educ=nearc4) age black smsa66 south66 sinmom14 kww, xnb(i.educ) tlevel(9/18) cgroup(ibn.south66 sinmom14 ibn.kww_g) format(%7.3f)" : . ivolsdec lwage (educ=nearc4) age black smsa66 south66 sinmom14 kww, xnb(i.educ) tlevel(9/18) cgroup(ibn.south66 sinmom14 ibn.kww_g) format(%7.3f)}}{p_end}


{title:Stored results}

{p 4 4 2}{cmd:ivolsdec} stores {cmd:r(D)}, which is a matrix that contains the estimates (Column 1) and the standard errors (Column 2) of:{p_end}
{p 5 5}(Row 1) OLS coefficient of X,{p_end}
{p 5 5}(Row 2) IV (TSLS) coefficient,{p_end}
{p 5 5}(Row 3) IV-OLS gap,{p_end}
{p 5 5}(Row 4) covariate weight difference,{p_end}
{p 5 5}(Row 5) treatment-level weight difference, and{p_end}
{p 5 5}(Row 6) Marginal effect difference.{p_end}

{p 4 4}Note: Standard errors of OLS and IV estimates are directly taken from {cmd:regress} and {cmd:ivregress} commands. 
Standard errors of decomposition estimators are computed by {cmd:regress}, using the asymptotic formula provided in Section 4 of Ishimaru (2021).{p_end}  

{p 4 4 2}A matrix {cmd:r(LW)} will be stored when the option {cmd:tlevel} is specified. Each row of the matrix corresponds to a treatment level designated by {cmd:tlevel}. The matrix has four columns:{p_end}
{p 5 5}(Column 1) OLS weights on the treatment levels,{p_end}
{p 5 5}(Column 2) Standard errors of the OLS weights,{p_end}
{p 5 5}(Column 3) IV weights on the treatment levels, and{p_end}
{p 5 5}(Column 4) Standard errors of the IV weights.{p_end}

{p 4 4 2}A matrix {cmd:r(CW)} will be stored when the option {cmd:cgroup} is specified. Each row of the matrix corresponds to a covariate group designated by {cmd:cgroup}. The matrix has five columns:{p_end}
{p 5 5}(Column 1) Shares of the groups in the data,{p_end}
{p 5 5}(Column 2) OLS weights on the groups,{p_end}
{p 5 5}(Column 3) Standard errors of the OLS weights,{p_end}
{p 5 5}(Column 4) IV weights on the groups, and{p_end}
{p 5 5}(Column 5) Standard errors of the IV weights.{p_end}

{marker references}{...}
{title:References}

{marker LM2015}{...}
{phang}
Lochner, L. and Moretti, E., 2015. Estimating and Testing Models with Many Treatment Levels and Limited Instruments. {it:The Review of Economics and Statistics}, 97(2), pp.387-397.{p_end}

{marker Ishimaru2021}{...}
{phang}
Ishimaru, S., 2021. Empirical Decomposition of the IV-OLS gap with Heterogeneous and Nonlinear Effects. {it:{browse "https://arxiv.org/abs/2101.04346":arXiv:2101.04346}}.{p_end}

{marker authors}{...}
{title:Author}

{pstd}Shoya Ishimaru{p_end}
{pstd}Hitotsubashi University{p_end}
{pstd}Tokyo, Japan{p_end}
{pstd}shoya.ishimaru@r.hit-u.ac.jp{p_end}

{marker also}{...}
{title:Also see}

{p 7 14 2}Help: {helpb locmtest}
(if installed) {p_end}




