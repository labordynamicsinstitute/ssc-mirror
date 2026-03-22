{smcl}
{* Version 2.0, March 2026}{...}
{hline}
help for {hi:unemp (Version 2.0)}{right:Carlos Grad{c i'}n (March 2026)}
{hline}

{title:Measures of employment deprivation among households}

{title:Syntax}

{p 8 17 2}
{cmd:unemp} {it:gapvar} [{it:weights}] [{cmd:if} {it:exp}] [{cmd:in} {it:range}],
{cmdab:hid:}{it:(hidvar)}
[{cmdab:hs:ize}{it:(hsizevar)} {cmdab:th:ao}{it:(#)}
{cmdab:f:ormat}{it:(%9.#f)} {cmdab:g:amma}{it:(# [# ...])}
{cmdab:a:lpha}{it:(# [# ...])} {cmdab:gen:erate}{it:(newvar)}
{cmdab:dec:omp}]

{p 12 4 2}
{it:gapvar} is a variable containing individual employment gaps, either a
dummy (1=unemployed, 0=employed) or a continuous variable in [0, 1]
(e.g., relative gap in hours worked with respect to desired hours).

{p 12 4 2}
{cmd:fweights}, {cmd:aweights}, and {cmd:iweights} are allowed; see {help weights}.

{title:Description}

{p 4 4 2}
{cmd:unemp} computes aggregate household employment deprivation measures that
are sensitive to the distribution of employment among deprived households.

{p 4 4 2}
The program computes the FGT-type family of employment deprivation measures
at the household level proposed in Grad{c i'}n, Cant{c o'}, and Del R{c i'}o
({it:Review of Economics of the Household}, 2017).

{p 4 4 2}
{ul:Step 1: Household deprivation index}

{p 4 4 2}
For each household {it:i} with {it:H_i} active members, the index first computes
a household employment deprivation index:

{p 8 4 2}
{it:u_i(gamma) = (1/H_i) * sum_j (g_ij)^gamma}

{p 4 4 2}
where {it:g_ij} is the individual employment gap for person {it:j} in household
{it:i} (given by {it:gapvar}), and {it:gamma >= 0} controls the sensitivity
to the variability of gaps within the household.

{p 8 4 2}
If {it:gapvar} is a dummy (unemployment status), the index equals the
proportion of unemployed members regardless of gamma, so {cmdab:g:amma}{it:(1)}
is recommended. For continuous gaps (hours), different gamma values capture
different aspects of within-household inequality in employment.

{p 8 8 2}
Household deprivation indices can be saved using {cmdab:gen:erate}{it:(newvar)},
creating variables with subscripts for each gamma value
(e.g., {cmd:gen(u)} creates {it:u_0}, {it:u_1}, {it:u_2}, ...).
These can be used with {help glcurve} (employment deprivation curves)
or {help akdensity} (kernel densities), if installed.

{p 4 4 2}
{ul:Step 2: Aggregate index}

{p 4 4 2}
The program then aggregates household indices across the target population:

{p 8 4 2}
{it:U_alpha = (1/N) * sum_i u_i^alpha}

{p 4 4 2}
where {it:alpha >= 0} controls the sensitivity to inequality of deprivation
among deprived households.

{p 8 4 2}
By default, the aggregate index weights households by the number of
economically active members (as in official unemployment rates).
Use {cmdab:hs:ize} to weight by household size or any other variable.

{p 4 4 2}
A household is considered deprived if its deprivation level (for gamma=1)
exceeds the threshold {it:s}. Use {cmdab:th:ao}{it:(#)} to set this threshold
(default: 0). If {cmdab:th:ao}{it:(1)}, only fully deprived households contribute.


{title:Data requirements}

{p 4 4 2}
Microdata at the individual level, where observations are economically active
persons. A household identifier ({it:hidvar}) is required. {it:gapvar} must
be either a dummy (1=unemployed, 0=employed) or a continuous variable in
[0, 1] indicating the relative hours gap. Individuals with missing values are
excluded from calculations.


{title:Required option}

{p 4 8 2}
{cmdab:hid:}{it:(hidvar)} specifies the household identifier variable.


{title:Index options}

{p 4 8 2}
{cmdab:g:amma}{it:(# [# ...])} specifies the values of gamma (nonnegative
integers). Default: {cmdab:g:amma}{it:(0 1 2)}.

{p 12 12 2}
Gamma captures the sensitivity of household deprivation indices to variability
of employment gaps across members. If {it:gapvar} is a dummy, the index does
not vary with gamma; use {cmdab:g:amma}{it:(1)}.

{p 4 8 2}
{cmdab:a:lpha}{it:(# [# ...])} specifies the values of alpha (nonnegative
integers). Default: {cmdab:a:lpha}{it:(0 1 2)}.

{p 12 12 2}
Alpha captures the sensitivity of the aggregate measure to inequality of
employment deprivation among deprived households.

{p 4 8 2}
{cmdab:th:ao}{it:(#)} sets the deprivation threshold (real value between 0
and 1). For thao < 1, only households with u(gamma=1) > thao are considered
deprived. For thao = 1, only fully deprived households contribute.
Default: {cmdab:th:ao}{it:(0)} (any household with u_1 > 0 is deprived).


{title:Weighting and reporting options}

{p 4 8 2}
{cmdab:hs:ize}{it:(hsizevar)} weights each household by {it:hsizevar}
(e.g., number of household members). Without this option, households are
weighted by their number of active members.

{p 4 8 2}
{cmdab:gen:erate}{it:(newvar)} creates new variables containing household
employment deprivation indices for each gamma value. If combined with
{cmdab:hs:ize}, the variables only take values for one observation per household.

{p 4 8 2}
{cmdab:dec:omp} reports the decomposition of the aggregate index into
incidence, intensity, and inequality among deprived households:
{it:U_alpha = H * I^alpha * (1 + Ep)}.
For alpha=2, an alternative variance-based decomposition is also reported.

{p 4 8 2}
{cmdab:f:ormat}{it:(%9.#f)} changes the numeric format. Default:
{cmdab:f:ormat}{it:(%9.4f)}.


{title:Reported results}

{p 4 4 2}
{ul:Aggregate index} U(gamma, alpha) for all requested parameter combinations.

{p 4 4 2}
{ul:Decomposition} (with {cmdab:dec:omp}):

{p 8 4 2}
{it:U_alpha = H * I^alpha * (1 + Ep)}, where:{break}
- H = headcount ratio (proportion of deprived households){break}
- I = intensity (mean deprivation among deprived households){break}
- Ep = inequality of deprivation among deprived households (alpha > 1)

{p 4 4 2}
{ul:Alternative decomposition for alpha=2}:

{p 8 4 2}
{it:U_2 = H * [I^2 + V(u)]}, where:{break}
- V(u) = variance of u among deprived households{break}
- CV2(1-u) = squared coefficient of variation of (1-u), such that V(u) = CV2(1-u) * (1-I)^2


{title:Saved results}

{p 4 4 2}
Matrices:

{p 8 8 2}
{cmd:r(unemp)}: aggregate employment deprivation measure, and main
decomposition if {cmdab:dec:omp} is specified.

{p 8 8 2}
{cmd:r(dec2)}: alternative decomposition for alpha=2 if {cmdab:dec:omp}
is specified.

{p 4 4 2}
Scalars:

{p 8 8 2}
{cmd:r(U_i_j)}: aggregate employment deprivation U() for gamma={it:i}
and alpha={it:j}.

{p 8 8 2}
{cmd:r(N)}: number of observations used.


{title:Inference}

{p 4 4 2}
Bootstrap standard errors can be obtained using the returned scalars
(see example below).


{title:Examples}

{p 4 8 2}
. {stata use unemp.dta, clear}

{p 4 8 2}
. {stata desc}

{p 4 8 2}
{ul:1. Households weighted by number of active members (default):}

{p 8 8 2}
With a dummy indicating unemployment status (gamma=1 recommended):

{p 4 8 2}
. {stata unemp unemployed [aw=w], hid(hid) gamma(1)}

{p 8 8 2}
With a variable indicating the gap in hours (e.g., (desired-worked)/desired):

{p 4 8 2}
. {stata unemp hgap [aw=w], hid(hid)}

{p 8 8 2}
Saved results:

{p 4 8 2}
. {stata ret list}

{p 4 8 2}
{ul:2. Households equally weighted regardless of size:}

{p 4 8 2}
. {stata gen hs=1}

{p 4 8 2}
. {stata unemp hgap [aw=w], hid(hid) hs(hs)}

{p 4 8 2}
{ul:3. Households weighted by household size (including inactive members):}

{p 4 8 2}
. {stata unemp hgap [aw=w], hid(hid) hs(hsize)}

{p 4 8 2}
{ul:Generating household deprivation indices:}

{p 4 8 2}
. {stata unemp hgap [aw=w], hid(hid) hs(hsize) gen(u)}

{p 4 8 2}
. {stata desc u_*}

{p 4 8 2}
Employment deprivation curve (gamma=2) [{help glcurve} must be installed]:

{p 4 8 2}
. {stata gen mu_2=-u_2}

{p 4 8 2}
. {stata glcurve u_2 [aw=w*hsize], sort(mu_2)}

{p 4 8 2}
Density of household deprivation (gamma=1) [{help akdensity} must be installed]:

{p 4 8 2}
. {stata akdensity u_1 if u_1>0 [aw=w*hsize], at(u_1)}

{p 4 8 2}
{ul:Changing default parameters:}

{p 4 8 2}
. {stata unemp hgap [aw=w] if country==1, hid(hid) hs(hsize) th(.2) gamma(0 1 2 3) alpha(1 2 3 4)}

{p 4 8 2}
{ul:Special cases:}

{p 8 8 2}
Standard unemployment rate:

{p 4 8 2}
. {stata unemp unemployed [aw=w], hid(hid) g(1) a(1)}

{p 8 8 2}
Proportion of households with all active members unemployed:

{p 4 8 2}
. {stata unemp unemployed [aw=w], hid(hid) hs(hs) thao(1) g(1) a(1)}

{p 8 8 2}
Proportion of people in fully unemployed households:

{p 4 8 2}
. {stata unemp unemployed [aw=w], hid(hid) hs(hsize) thao(1) g(1) a(1)}

{p 4 8 2}
{ul:Decomposition:}

{p 4 8 2}
. {stata unemp hgap [aw=w], hid(hid) hs(hsize) decomp}

{p 4 8 2}
{ul:Bootstrapping} (example for alpha=2, gamma=0,1,2; BC confidence interval):

{p 8 8 2}
cap program drop hhu{break}
program define hhu{break}
unemp hgap [aw=w], hid(hid) hs(hsize){break}
end{break}

{p 8 8 2}
bootstrap r(U_0_2) r(U_1_2) r(U_2_2) if country==1, reps(10): hhu

{p 8 8 2}
estat bootstrap


{title:Author}

{p 4 4 2}
{browse "https://sites.google.com/view/cgradin": Carlos Grad{c i'}n}
<cgradin@uvigo.gal>{break}
Facultade de CC. Econ{c o'}micas{break}
Universidade de Vigo{break}
36310 Vigo, Galicia, Spain.


{title:References}

{p 4 8 2}
Grad{c i'}n, C., O. Cant{c o'}, and C. del R{c i'}o (2017), "Measuring
employment deprivation in the EU using a household-level index",
{it:Review of Economics of the Household}, 15(2): 639-667.

{p 4 8 2}
Foster, J., J. Greer, and E. Thorbecke (1984), "A Class of Decomposable
Poverty Measures", {it:Econometrica}, 52(3): 761-766.


{title:Also see}

{p 4 13 2}
{help akdensity} if installed;
{help glcurve} if installed
{p_end}
