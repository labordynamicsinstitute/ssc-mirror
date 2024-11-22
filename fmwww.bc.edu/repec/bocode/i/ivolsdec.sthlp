{smcl}
{* *! Nov2024}{...}
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

{pstd}{cmd:ivolsdec} performs a decomposition of the IV-OLS coefficient gap suggested by Ishimaru (2024).
This decomposition accounts for nonlinearity and observed heterogeneity in the causal relationship between an outcome variable and a treatment variable, 
generalizing the approach proposed by Lochner and Moretti (2015).
See Ishimaru (2024) for complete details about the underlying theoretical framework.{p_end}

{pstd}In the language of causal inference, {it:outcome} is an outcome variable (Y), {it:treatment} is a treatment variable (X), 
{it:instruments} is a set of instruments (Z), and {it:covariates} is a set of covariates (W).
The decomposition allows for the possibility that the true causal impact of X on Y is nonlinear in X and heterogeneous across W, 
and assesses how the IV-OLS gap is influenced by differences in the weights that IV and OLS estimators assign to X and W.
In particular, the IV-OLS gap is decomposed into the following three components.{p_end}
{p 5 5}(1) Covariate weight difference: the difference in how the IV and OLS coefficients weight the covariates (W).{p_end}
{p 5 5}(2) Treatment-level weight difference: the difference in how they place weight treatment levels (X).{p_end}
{p 5 5}(3) Marginal effect difference: the difference between the marginal effects identified by IV and OLS, which typically originates from endogeneity bias.{p_end}

{pstd} The true causal relationship may exhibit nonlinearity and heterogeneity in various ways.
However, accounting for this relationship using a fully nonparametric approach is often infeasible.
To address this, this package employs a flexible parametric specification, allowing users to determine the degree of flexibility based on their needs.
It is crucial that users carefully select an appropriate specification, informed by their understanding of the data and the specific context of their study.
In performing the decomposition, {cmd:ivolsdec} uses the following two auxiliary OLS regressions:{p_end}
{p 5} Y = W'a1 + (q(W)'b1)*X + e1, and{p_end}
{p 5} Y = W'a2 + (q(W)'b2)*X + q(W)'(C2)r(X) + p(X)'d2 + e2,{p_end}
{pstd} where q(W) is a set of basis functions of W specified by {cmdab:wb:asis} (the default is q(W)=W),
r(X) is a set of basis functions of X specified by {cmdab:xib:asis} (the default is r(X)=0),
and p(X) is a set of basis functions of X specified by {cmdab:xnb:asis} (must be chosen by the user).
In principle, q(W)'b1 in the first equation should approximate the covariate-specific OLS coefficient b_OLS(W)=Cov(Y,X|W)/Var(X|W) well and the second equation as a whole should approximate E[Y|X,W] well.
For practical convenience, this command uses simple series approximations specified above. 
Users who want to work with a more flexible specification may refer to Section 4 of Ishimaru (2024) for guidance on implementing the decomposition independently.{p_end}

{pstd} If neither {cmd:did} nor {cmdab:rd:d} option is active, the decomposition assumes that both E[X|W] and E[Z|W] are (approximately) linear in W. 
Under this assumption, the OLS and IV coefficients do not suffer from omitted variable bias associated with unaccounted nonlinear effects of covariates.
This linearity requirement is automatically satisfied if W consists of indicators for disjoint groups. 
However, the choice of a covariate vector W requires caution in general. 
In the presence of continuous covariates, for example, it is desirable that a vector W flexibly accounts for nonlinear and interaction effects of these covariates.{p_end}

{title:Options}

{phang}{cmd:xnbasis} specifies the basis functions of X that are {ul:not} interacted with {cmd:wbasis}. 
{ul:This option is required} unless the option {cmd:binary} is active. 
{it:varlist} must consist of {ul:nonlinear} transformations of the treatment variable X (e.g., X^k, I{X>=i}, etc.).{p_end}

{phang}{cmd:wbasis} specifies the basis functions of W that are interacted with X and {cmd:xibasis}. If not specified, variables in {it:covariates} are used.{p_end}

{phang}{cmd:xibasis} specifies the basis functions of X that are interacted with {cmd:wbasis}. {it:varlist} must consist of {ul:nonlinear} transformations of the treatment variable X.{p_end}

{phang}{cmd:vce} specifies the type of standard errors reported. The default is {cmd:robust}. {it:vcetype} admits standard options in {cmd:regress} and {cmd:ivregress} commands, such as ({cmd:cluster} {it:clustvar}).{p_end}

{phang}{cmd:did} indicates that the original IV regression uses difference-in-differences variation in the instruments for identification; see Section 3 of Ishimaru (2024).{p_end}

{phang}{cmd:rdd} indicates that the original IV regression implements (fuzzy) regression discontinuity designs; see Section 3 of Ishimaru (2024).{p_end}

{phang}{cmd:binary} must be specified when {it:treatment} is a binary variable. The treatment-level weight difference is zero by construction in such a setting.

{phang}{cmd:tlevel} designates treatment levels. The OLS and IV weights on the designated treatment levels will be displayed.
In Ishimaru (2024), Figure 1 displays an empirical example and Appendix D.4 describes how to estimate the weights.

{phang}{cmd:cgroup} designates covariate groups. The variables in {it:varlist} must be binary and be generated from {it:covariates}.
The OLS and IV weights on the designated covariate groups will be displayed.
In Ishimaru (2024), Tables 2-4 present empirical examples and Appendix D.4 describes how to estimate the weights.

{phang}{cmd:format} specifies numerical display formats of the results; see help {help format}.{p_end}


{marker s_examples}{title:Example}

{pstd}Load Card (1995) data{p_end}
{phang2}. {stata "use http://www.stata.com/data/jwooldridge/eacsap/card, clear"}{p_end}

{pstd} Run OLS and IV regressions as usual ({cmd:ivolsdec} does not require these commands to be run beforehand){p_end}
{phang2}. {stata "regress lwage educ age black smsa66 south66 sinmom14 kww, robust"}{p_end}
{phang2}. {stata "ivregress 2sls lwage (educ=nearc4) age black smsa66 south66 sinmom14 kww, robust"}{p_end}

{pstd}Run {cmd:ivolsdec} to decompose the IV-OLS gap{p_end}
{phang2}. {stata "ivolsdec lwage (educ=nearc4) age black smsa66 south66 sinmom14 kww, xnb(i.educ) format(%7.3f)"}

{pstd}Experiment with various specifications to check robustness{p_end}
{phang2}. {stata "gen educ_c=max(educ-12,0)"}{p_end}
{phang2}. {stata "ivolsdec lwage (educ=nearc4) age black smsa66 south66 sinmom14 kww, xnb(i.educ) xib(educ_c) format(%7.3f)"}{p_end}

{pstd}Polynomials (and other nonlinear transformations) can also be basis functions{p_end}
{phang2}. {stata "gen educ2=educ^2"}{p_end}
{phang2}. {stata "gen educ3=educ^3"}{p_end}
{phang2}. {stata "ivolsdec lwage (educ=nearc4) age black smsa66 south66 sinmom14 kww, xnb(educ2 educ3) xib(educ2 educ3) format(%7.3f)"}{p_end}

{pstd}Most factor variable operators are allowed{p_end}
{phang2}. {stata "ivolsdec lwage (educ=nearc4) age black smsa66 south66 sinmom14 kww, xnb(c.educ#c.educ c.educ#c.educ#c.educ) xib(c.educ#c.educ c.educ#c.educ#c.educ) format(%7.3f)"}{p_end}

{pstd}Display weights on covariate groups and treatment levels in addition to the decomposition{p_end}
{phang2}. {stata "xtile kww_g=kww, nq(3)"}{p_end}
{phang2}. {stata "ivolsdec lwage (educ=nearc4) age black smsa66 south66 sinmom14 kww, xnb(i.educ) tlevel(9/18) cgroup(ibn.south66 sinmom14 ibn.kww_g) format(%7.3f)"}{p_end}

{title:Stored results}

{p 4 4 2}{cmd:ivolsdec} stores {cmd:r(D)}, which is a matrix that contains the estimates (Column 1) and the standard errors (Column 2) of:{p_end}
{p 5 5}(Row 1) OLS coefficient of X,{p_end}
{p 5 5}(Row 2) IV (TSLS) coefficient,{p_end}
{p 5 5}(Row 3) IV-OLS gap,{p_end}
{p 5 5}(Row 4) covariate weight difference,{p_end}
{p 5 5}(Row 5) treatment-level weight difference, and{p_end}
{p 5 5}(Row 6) marginal effect difference.{p_end}

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
Lochner, L. and Moretti, E., 2015. "Estimating and Testing Models with Many Treatment Levels and Limited Instruments." {it:The Review of Economics and Statistics}, 97(2), pp.387-397.{p_end}

{marker Ishimaru2021}{...}
{phang}
Ishimaru, S., 2024. "Empirical Decomposition of the IV-OLS gap with Heterogeneous and Nonlinear Effects."
{it:The Review of Economics and Statistics}, 106(2), pp.505-520.
(Also see {it:{browse "https://arxiv.org/abs/2101.04346":arXiv:2101.04346}}).{p_end}

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




