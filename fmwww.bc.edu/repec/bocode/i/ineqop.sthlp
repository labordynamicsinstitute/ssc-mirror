{smcl}
{* *! version 1.0  March 2026}{...}
{viewerjumpto "Syntax" "ineqop##syntax"}{...}
{viewerjumpto "Description" "ineqop##description"}{...}
{viewerjumpto "Options" "ineqop##options"}{...}
{viewerjumpto "Stored results" "ineqop##results"}{...}
{viewerjumpto "Examples" "ineqop##examples"}{...}
{viewerjumpto "References" "ineqop##references"}{...}
{title:Title}

{phang}
{bf:ineqop} {hline 2} Inequality of opportunity decomposition using direct, indirect, and Shapley approaches


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:ineqop}
{it:depvar}
{ifin}
{weight}
{cmd:,} {opt t:ype(varlist)} [{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt t:ype(varlist)}}one or more circumstance variables defining types{p_end}

{syntab:Indices}
{synopt:{opt gi:ni}}include the Gini index (default){p_end}
{synopt:{opt nogi:ni}}exclude the Gini index{p_end}
{synopt:{opt ge(numlist)}}GE indices to compute; default is {cmd:ge(-1 0 1 2)}{p_end}

{syntab:Output}
{synopt:{opt pat:tern}}produce 2x2 figure of IO shares across indices for one group{p_end}
{synopt:{opt bypat:tern}}produce combined 2x2 figure of IO shares over by-groups (use with {cmd:bys}){p_end}
{synopt:{opt contr:ibutions}}produce stacked bar chart of Shapley RIF contributions by type{p_end}
{synopt:{opt contrt:able}}display table with Shapley RIF contributions by type{p_end}
{synopt:{opt contri:ndex(string)}}index for contributions graph; default is {cmd:gini}{p_end}
{synopt:{opt desc:riptives}}display table with distribution of circumstance variables{p_end}
{synopt:{opt tr:end}}plot trends of inequality levels and IO shares over by-groups (use with {cmd:bys}){p_end}
{synopt:{opt tr:endindex(string)}}index for trend levels graph; default is {cmd:gini}{p_end}
{synopt:{opt gen:erate(namelist)}}generate variables for smoothed ({it:y_b}) and standardized ({it:y_w}) distributions{p_end}
{synopt:{opt lor:enz}}produce Lorenz curve graphs (direct and Shapley){p_end}
{synopt:{opt det:ail}}show additional details (e.g., BM decomposition for Gini){p_end}
{synopt:{opt all}}turn on all output options at once{p_end}

{syntab:Formatting}
{synopt:{opt f:ormat(string)}}display format for levels; default is {cmd:%9.4f}{p_end}
{synopt:{opt form:atp(string)}}display format for percentages; default is {cmd:%9.1f}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{cmd:aweight}s, {cmd:fweight}s, and {cmd:iweight}s are allowed;
see {help weight}.{p_end}
{p 4 6 2}{cmd:by} is allowed; see {help by}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:ineqop} estimates the contribution of birth circumstances (inequality of
opportunity, IO) to overall inequality, following the methodology in
Gradin and Zapata Roman (2026).

{pstd}
The program decomposes total inequality into between-type inequality
(inequality of opportunity, IO) and within-type inequality (residual
inequality, IR), where types are defined by combinations of observable
circumstances beyond individual control (e.g., gender, parental education,
ethnicity, region of birth).

{pstd}
Three approaches are reported:

{phang2}1. {bf:Direct approach} ({it:IO{sup:D}}): IO is measured as inequality
in the smoothed distribution {it:y_b} where each person's income is replaced
by their type mean. The remaining inequality {it:I(y) - I(y_b)} is attributed
to residual factors.{p_end}

{phang2}2. {bf:Indirect approach} ({it:IO{sup:I}}): IO is measured as the
reduction in inequality after equalizing type means (standardized distribution
{it:y_w}). That is, {it:IO{sup:I} = I(y) - I(y_w)}.{p_end}

{phang2}3. {bf:Shapley approach} ({it:IO{sup:s}}): The average of direct and
indirect measures, splitting the interaction term equally between IO and IR:
{it:I_sb = I(y_b) + (1/2)*I_bw}, where
{it:I_bw = I(y) - I(y_b) - I(y_w)}.{p_end}

{pstd}
For path-independent measures (MLD), all three approaches give the same result.
For path-dependent measures (Gini, Theil, etc.), they can differ substantially
due to the interaction term.

{pstd}
The program also supports RIF-based decomposition of each type's contribution
to IO and IR using the Shapley approach (Figure 6 in the paper).


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt type(varlist)} specifies one or more variables defining the types
(population groups sharing the same circumstances). If a single variable is
specified, it is used directly as the type variable. If multiple variables are
specified, the program creates types from all observed combinations using
{cmd:egen group()}.

{dlgtab:Indices}

{phang}
{opt gini} includes the Gini index in the decomposition. This is the default.

{phang}
{opt nogini} excludes the Gini index.

{phang}
{opt ge(numlist)} specifies the alpha values for the Generalized Entropy
indices to compute. The default is {cmd:ge(-1 0 1 2)}, corresponding to
GE(-1), MLD (GE(0)), Theil (GE(1)), and half the squared coefficient of
variation (GE(2)).

{dlgtab:Output}

{phang}
{opt pattern} produces a combined 2x2 figure with four panels, mirroring the
layout of Figure 2 in Gradin and Zapata Roman (2026):
(a) Direct IO{sup:D}, (b) Indirect IO{sup:I}, (c) Interaction I_bw/I(y), and
(d) Shapley IO{sup:s}. Each panel plots the IO share (as % of overall
inequality) across the computed GE indices using connected markers along the
{it:alpha} axis, showing how IO varies with the sensitivity parameter. The
Gini index, being a different family, is shown as a separate standalone marker
(diamond). When used with {cmd:bys year:}, one combined figure is produced per
group, allowing the user to compare patterns over time.

{phang}
{opt bypattern} produces a combined 2x2 figure similar to {opt pattern} but
accumulating results across all by-groups (e.g., years) and drawing them
together in a single figure. Each panel (Direct IO{sup:D}, Indirect IO{sup:I},
Interaction I_bw/I(y), Shapley IO{sup:s}) shows connected lines with different
colors and markers for each computed index (Gini, MLD, Theil, etc.), with the
by-variable values (e.g., years) along the horizontal axis.
This option requires the use of {cmd:bys} (e.g., {cmd:bys year:}).
The combined figure is produced after the last by-group is processed.

{phang}
{opt contributions} produces a stacked bar chart showing the Shapley
contribution of each type to IO (between) and IR (within) as a percentage of
overall inequality. Types are sorted in descending order by their IO
contribution. The index used for the graph is determined by {opt contrindex()}.
Also displays the contributions table.

{phang}
{opt contrtable} displays a table with the Shapley RIF contributions of each
type to IO and IR for all selected indices, without producing a graph.

{phang}
{opt contrindex(string)} specifies which inequality index to use for the
contributions graph. Valid values are {cmd:gini} (default), {cmd:ge-1},
{cmd:ge0}, {cmd:ge1}, or {cmd:ge2}, provided the corresponding index is
being computed. For example, {cmd:contrindex(ge1)} produces the graph using
the Theil index.

{phang}
{opt descriptives} displays a table with the weighted distribution (percentage)
of each circumstance variable specified in {opt type()}, as in Table A2 of
Gradin and Zapata Roman (2026). For each variable, the percentage of each
category in the (weighted) population is shown, along with the total sample
size. When used with {cmd:bys}, results are accumulated across by-groups and
a single combined table is displayed after the last group, with one column per
by-group value (e.g., year). Without {cmd:bys}, a single-column table is
displayed.

{phang}
{opt trend} produces two trend figures that accumulate results across by-groups
(e.g., years), as in Figures 3 and 4 of Gradin and Zapata Roman (2026).
This option requires the use of {cmd:bys} (e.g., {cmd:bys year:}).
The first figure ({it:trend_levels}) plots the evolution of inequality levels
for one index: I(y), I(y_b), and I(y_w) as solid connected lines, and the
Shapley values I_sb and I_sw as dashed connected lines.
The second figure ({it:trend_shares}) plots the Shapley IO share (IO{sup:s},
as % of overall inequality) for all computed indices on the same graph,
showing how the contribution of circumstances varies over time across indices.

{phang}
{opt trendindex(string)} specifies which inequality index to use for the
trend levels figure (first figure). Valid values are {cmd:gini} (default),
{cmd:ge-1}, {cmd:ge0}, {cmd:ge1}, or {cmd:ge2}. For example,
{cmd:trendindex(ge0)} plots MLD levels over time.

{phang}
{opt generate(namelist)} creates two new variables containing the smoothed
({it:y_b}) and standardized ({it:y_w}) distributions. Exactly two variable
names must be specified: the first for {it:y_b} (each observation replaced by
its type mean) and the second for {it:y_w} (rescaled so all types have the
overall mean). For example, {cmd:gen(yb yw)} creates variables {cmd:yb} and
{cmd:yw}.

{phang}
{opt lorenz} produces two Lorenz curve figures, as in Figure A3 of Gradin and
Zapata Roman (2026). The first figure ({it:lorenz_a}) plots the empirical
Lorenz curves for the overall ({it:y}), between-type ({it:y_b}, smoothed), and
within-type ({it:y_w}, standardized) distributions, along with the 45-degree
line. The second figure ({it:lorenz_b}) plots the Shapley Lorenz curves:
{it:L_sb(p) = L_b(p) + (1/2)[L(p) - L_b(p) - L_w(p)]} and
{it:L_sw(p) = L_w(p) + (1/2)[L(p) - L_b(p) - L_w(p)]}, along with the
overall Lorenz curve L(y). These satisfy {it:L(y) = L_sb + L_sw}.

{phang}
{opt detail} shows additional decomposition details, including the
Bhattacharya-Mahalanobis (BM) within-group weighted sum and residual for the
Gini index.

{phang}
{opt all} activates all output options at once: {opt pattern}, {opt bypattern},
{opt contributions}, {opt contrtable}, {opt descriptives}, {opt trend},
{opt lorenz}, and {opt detail}. This is a convenience shortcut equivalent to
specifying each option individually. The default indices
({opt contrindex(gini)}, {opt trendindex(gini)}) apply unless overridden.
Note that {opt generate()} must be specified separately if desired.

{dlgtab:Formatting}

{phang}
{opt format(string)} specifies the display format for index levels.
Default is {cmd:%9.4f}.

{phang}
{opt formatp(string)} specifies the display format for percentages.
Default is {cmd:%9.1f}.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:ineqop} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars (for each index X = G, GEm1, GE0, GE1, GE2)}{p_end}
{synopt:{cmd:r(X_y)}}overall inequality I(y){p_end}
{synopt:{cmd:r(X_yb)}}between-type inequality I(y_b){p_end}
{synopt:{cmd:r(X_yw)}}within-type inequality I(y_w){p_end}
{synopt:{cmd:r(X_Ibw)}}interaction term I_bw{p_end}
{synopt:{cmd:r(X_Isb)}}Shapley between-type I_sb{p_end}
{synopt:{cmd:r(X_Isw)}}Shapley within-type I_sw{p_end}
{synopt:{cmd:r(X_IOD)}}direct IO share (% of overall){p_end}
{synopt:{cmd:r(X_IOI)}}indirect IO share (% of overall){p_end}
{synopt:{cmd:r(X_IOs)}}Shapley IO share (% of overall){p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}summary matrix with all decomposition results{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Basic decomposition from circumstance variables:{p_end}
{phang2}{cmd:. ineqop y [aw=weight], type(gender educ_parents region ethnicity)}

{pstd}Decomposition with a pre-created type variable:{p_end}
{phang2}{cmd:. ineqop y [aw=weight], type(type)}

{pstd}Decomposition for all years using {cmd:bys}:{p_end}
{phang2}{cmd:. bys year: ineqop y [aw=weight], type(type)}

{pstd}IO shares across indices (pattern graph):{p_end}
{phang2}{cmd:. ineqop y [aw=weight], type(type) pattern}

{pstd}With detailed BM decomposition for Gini:{p_end}
{phang2}{cmd:. ineqop y [aw=weight], type(type) detail}

{pstd}With Shapley RIF contributions graph (Gini, default):{p_end}
{phang2}{cmd:. ineqop y [aw=weight], type(type) contributions}

{pstd}Contributions graph using the Theil index:{p_end}
{phang2}{cmd:. ineqop y [aw=weight], type(type) contributions contrindex(ge1)}

{pstd}Table of RIF contributions only (no graph):{p_end}
{phang2}{cmd:. ineqop y [aw=weight], type(type) contrtable}

{pstd}Only entropy measures (no Gini), custom alphas:{p_end}
{phang2}{cmd:. ineqop y [aw=weight], type(type) nogini ge(0 1)}

{pstd}Distribution of circumstances for all years:{p_end}
{phang2}{cmd:. bys year: ineqop y [aw=weight], type(gender educ_parents region ethnicity) descriptives}

{pstd}Combined IO pattern across all years:{p_end}
{phang2}{cmd:. bys year: ineqop y [aw=weight], type(type) bypattern}

{pstd}Trend of Gini levels and IO shares over time:{p_end}
{phang2}{cmd:. bys year: ineqop y [aw=weight], type(type) trend}

{pstd}Trend using MLD levels:{p_end}
{phang2}{cmd:. bys year: ineqop y [aw=weight], type(type) trend trendindex(ge0)}

{pstd}Generate smoothed and standardized distributions:{p_end}
{phang2}{cmd:. ineqop y [aw=weight], type(type) gen(yb yw)}

{pstd}Lorenz curves (direct and Shapley):{p_end}
{phang2}{cmd:. ineqop y [aw=weight], type(type) lorenz}

{pstd}Everything at once for all years:{p_end}
{phang2}{cmd:. bys year: ineqop y [aw=weight], type(gender educ_parents region ethnicity) all}


{marker references}{...}
{title:References}

{phang}
Gradin, C. and Zapata-Roman, G. (2026). Unpacking the contribution of birth
circumstances to inequality using a Shapley decomposition: the case of Chile.
{it:Review of Income and Wealth}, forthcoming (open access).

{phang}
Shorrocks, A.F. (2013). Decomposition procedures for distributional analysis:
a unified framework based on the Shapley value.
{it:Journal of Economic Inequality}, 11, 99-126.

{phang}
Chantreuil, F. and Trannoy, A. (2013). Inequality decomposition values: the
trade-off between marginality and efficiency.
{it:Journal of Economic Inequality}, 11, 83-98.

{phang}
Foster, J.E. and Shneyerov, A.A. (2000). Path independent inequality measures.
{it:Journal of Economic Theory}, 91(2), 199-222.

{phang}
Firpo, S., Fortin, N. and Lemieux, T. (2009). Unconditional quantile
regressions. {it:Econometrica}, 77(3), 953-973.


{marker author}{...}
{title:Author}

{pstd}
Carlos Gradin{p_end}
{pstd}
Universidade de Vigo{p_end}
{pstd}
Email: {browse "mailto:cgradin@uvigo.gal":cgradin@uvigo.gal}{p_end}

{pstd}
{it:This code was developed with the assistance of AI tools; all code has been reviewed, tested with the paper's original data, and validated by the author.}
{p_end}

{title:Also see}

{psee}
{space 2}Help:  {help iop} (if installed)
{p_end}
