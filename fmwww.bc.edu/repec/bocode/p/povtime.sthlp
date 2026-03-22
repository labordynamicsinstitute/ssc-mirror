{smcl}
{* version 2.0.0  20mar2026}{...}
{hline}
help for {hi:povtime}{right:Carlos Gradin (v2.0, March 2026)}
{hline}

{title:Poverty measures accounting for time in a balanced panel}


{p 8 17 2} {cmd:povtime} [{it:weights}] [{cmd:if} {it:exp}] [{cmd:in} {it:range}] , {cmdab:y}{it:(y_stub)} {cmdab:z}{it:(z_stub)} {cmdab:t}{it:(#)} [ {cmdab:g:amma}{it:(# [# ...])}
 {cmdab:b:eta}{it:(# [# ...])} {cmdab:a:lpha}{it:(# [# ...])} {cmdab:non:normalized} {cmdab:th:ao}{it:(#)}
{cmdab:gen}{it:(newvar)} {cmdab:dec:omp} {cmdab:f:ormat}{it:(%9.#f)}  ]


{p 4 4 2} {cmd:fweights}, {cmd:aweights} and {cmd:iweights} are allowed; see {help weights}.


{title:Description}

{p 4 4 2}
{cmd:povtime} computes aggregate intertemporal poverty measures (poverty accounting for time) in a balanced panel of individuals
(with information on per-period income or expenditure (yt) and poverty lines (zt) for N individuals during T periods).

{p 4 4 2}
The program computes the family of FGT-type intertemporal poverty measures proposed in Gradin, Del Rio, and Canto (RIW, 2012)
and some descriptive statistics.
Other measures such as Foster (2007, 2009) and Bossert, D'Ambrosio and Chakravarty (JOEI, 2012) can be interpreted as
particular cases of this general family.

{p 4 4 2}
The aggregate index is defined as (Eq. 4 in the paper):

{p 8 8 2}
P(Y;z) = (1/N) * SUM_i [ (1/T) * SUM_t g_it^gamma * (s_it/T)^beta ]^alpha

{p 4 4 2}
where g_it^gamma is the per-period normalized poverty gap raised to gamma (Eq. 1), s_it is the duration of the poverty spell
that individual i is in at period t, and (s_it/T)^beta is the spell-duration weight.

{p 4 4 2}
The index first computes individual poverty indicators based on per-period normalized gaps of the form (zt-yt)/zt.
For using non-normalized gaps (zt-yt), specify the option {cmdab:non:normalized}.

{p 8 8 2}
Individual poverty indicators can be saved as new variables using {cmdab:gen}{it:(newvar)}.
New variables {it:(newvar_i_j)} are created with subscripts standing for the value of gamma (i) and the jth beta used.
This could be useful to further analyze their distribution drawing kernel densities (see {help akdensity} if installed)
or computing Intertemporal TIP curves (using {help glcurve} if installed).


{p 4 4 2}
In a second step, the program aggregates individual intertemporal poverty indicators over the entire population in order to
obtain a distribution-sensitive aggregate index of intertemporal poverty (Eq. 3).

{p 4 4 2}
By default, an individual is considered to be intertemporally poor if yt is below zt at least one period.
For restricting intertemporally poor to be at least a given number of periods below the poverty line,
use option {cmdab:th:ao}{it:(#)}, the default is {cmdab:th:ao}{it:(1)}.


{title:Special cases}

{p 4 4 2}
The following well-known indices are special cases of this family:

{p 8 8 2}
{it:Foster (2007, 2009)}: set beta=0 and alpha=1 (no duration weighting, no inequality aversion).

{p 8 8 2}
{it:Bossert, D'Ambrosio and Chakravarty (2012)}: set beta=1 and alpha=1 (proportional duration weighting, no inequality aversion).

{p 8 8 2}
{it:Static FGT}: set T=1 to recover the standard cross-sectional FGT measure.


{title:Data requirements}

{p 4 4 2}
The balanced panel of N individuals (or households) observed during T periods must be in wide form (see {help reshape}).
All observations must have the same number of periods; observations with missing values in any y or z variable will be
excluded from calculations.

{p 4 4 2}
Data must contain per-period measures of wellbeing (typically income or expenditure) indicated with {it:y_stub} and poverty
lines indicated with {it:z_stub}.
Income and poverty line variables must be numbered from 1 to T (i.e. {cmdab:y}{it:(y)} {cmdab:z}{it:(z)} for y1, y2, y3, ...
and z1, z2, z3,...).


{title:Reporting}

{p 4 4 2}
* Descriptive statistics:

{p 8 4 2}
- Percentage of the population that is intertemporally poor

{p 8 4 2}
- Distribution of the number of periods below the poverty line

{p 8 4 2}
- Distribution of the number of poverty spells

{p 8 4 2}
- For the intertemporally poor population:

{p 12 4 2}
Average number of periods below the poverty line

{p 12 4 2}
Average number of poverty spells

{p 12 4 2}
Average duration of poverty spells

{p 4 4 2}
* Aggregate measure of intertemporal poverty P(Y;z) for the specified values of the parameters:

{p 8 8 2}
. gamma (>= 0): sensitivity of individual poverty indicators to variability of per-period poverty gaps across time.
Higher gamma gives more weight to deeper poverty. Analogous to the FGT parameter.

{p 8 8 2}
. beta (>= 0): sensitivity of individual intertemporal poverty indicators to the duration of poverty spells.
beta=0 means no duration weighting; higher beta gives more relative weight to longer spells.

{p 8 8 2}
. alpha (>= 0): sensitivity of the aggregate intertemporal poverty index to inequality of individual poverty indicators
among the poor. alpha=0 yields headcount; alpha=1 accounts for intensity; alpha > 1 also accounts for inequality.


{p 4 4 2}
* If option {cmdab:dec:omp} is specified, the decomposition of the indices into poverty incidence (H), intensity (I),
and inequality among the poor (Ep) is also reported (Eq. 5 in the paper): P = H * I^alpha * (1 + Ep).


{title:Required Options}

{p 4 8 2}
{cmdab:y}{it:(y_stub)} to indicate the set of variables yt containing per-period income or expenditure.

{p 4 8 2}
{cmdab:z}{it:(z_stub)} to indicate the set of variables zt containing per-period poverty lines.

{p 4 8 2}
{cmdab:t}{it:(#)} to indicate the number T of periods to be used in the analysis.



{title:Other Options}

{p 4 8 2}
{cmdab:g:amma}{it:(# [# ...])} to indicate the values of gamma, the default is {cmdab:g:amma}{it:(0 1 2)}.

{p 4 8 2}
{cmdab:b:eta}{it:(# [# ...])} to indicate the values of beta (can be non-integer), the default is {cmdab:b:eta}{it:(0 1)}.

{p 4 8 2}
{cmdab:a:lpha}{it:(# [# ...])} to indicate the values of alpha, the default is {cmdab:a:lpha}{it:(0 1 2)}.

{p 4 8 2}
{cmdab:non:normalized} to use non-normalized per-period poverty gaps (zt-yt). By default, gaps are normalized by
dividing by the per-period poverty line: (zt-yt)/zt.

{p 4 8 2}
{cmdab:th:ao}{it:(#)} to set a chronicity threshold (tau in the paper): only individuals with at least the specified
number of periods below the poverty line will be considered as intertemporally poor.
The default is {cmdab:th:ao}{it:(1)}, i.e. at least 1 period out of T.

{p 4 8 2}
{cmdab:gen}{it:(newvar)} to create new variables containing individual poverty indicators, with subscripts _i_j
indicating gamma=i and the jth beta used.

{p 4 8 2}
{cmdab:dec:omp} to decompose the index into incidence (H), intensity (I), and inequality among the poor (Ep).
For alpha=2 with normalized gaps, it also reports the variance of individual poverty indicators V(p) and the
squared coefficient of variation of (1-p), CV2(1-p).

{p 4 8 2}
{cmdab:f:ormat}{it:(%9.4f)} to change numeric format, %9.4f is the default.

{title:Saved results}


{p 4 4 2}
Matrices:

{p 8 8 2}
r(pov) : poverty indices with columns gamma, beta, alpha, P (and H, I, Ep if option {cmdab:dec:omp} specified).

{p 8 8 2}
r(dec2) : alternative decomposition for alpha=2 with columns gamma, beta, alpha, P, H, I, CV2, V
(if option {cmdab:dec:omp} specified and normalized gaps used).


{p 4 4 2}
Scalars:

{p 8 8 2}
r(everpoor) : percentage of intertemporally poor individuals

{p 8 8 2}
r(npoor) : average number of poor periods (for those intertemporally poor)

{p 8 8 2}
r(npovspells) : average number of poverty spells (for those intertemporally poor)

{p 8 8 2}
r(meandur) : average duration of poverty spells (for those intertemporally poor)

{p 8 8 2}
r(P_i_j_k) : aggregate intertemporal poverty measure P(Y;z) for gamma=i, the jth beta, and alpha=k



{p 12 12 2}
Note: subscripts _i and _k indicate the values of gamma and alpha respectively (which are integers),
while _j indicates the {it:order} of beta (not its value), since beta can take non-integer values.
For example, if beta(0 .5 1), then _1 refers to beta=0, _2 to beta=.5, and _3 to beta=1.


{title:Inference}


{p 4 4 2}
Bootstrap standard errors can be obtained using the returned scalars (see example below).


{title:Examples}

{p 4 8 2}
. {stata use povtime.dta, clear }

{p 4 8 2}
. {stata desc}

{p 4 8 2}
Basic usage

{p 4 8 2}
. {stata povtime [aw=w] if country==1, y(y) z(z) t(6) }

{p 4 8 2}
Saved results

{p 4 8 2}
. {stata ret list}

{p 4 8 2}
Generating individual poverty indicators

{p 4 8 2}
. {stata povtime [aw=w] if country==1, y(y) z(z) t(6) gen(p)}

{p 4 8 2}
. {stata desc p*}

{p 4 8 2}
Computing Intertemporal TIP curve (gamma=2, beta=1) using {help glcurve} (must be installed)

{p 4 8 2}
. {stata gen mp_2_2=-p_2_2}

{p 4 8 2}
. {stata glcurve p_2_2 [aw=w] if country==1, sort(mp_2_2)}

{p 4 8 2}
Estimating the density of individual poverty indicators (gamma=2, beta=0) using {help akdensity} (must be installed)

{p 4 8 2}
. {stata akdensity p_2_1 if country==1 & p_2_1>0 [aw=w] , at(p_2_1)}

{p 4 8 2}
Changing default values of the parameters

{p 4 8 2}
. {stata povtime [aw=w] if country==2, y(y) z(z) t(6) thao(2) gamma(0 1 2 3 4) beta(0 .25 .50 .75 1 2) alpha(1 2 3 4 5 6) }

{p 4 8 2}
Decomposition

{p 4 8 2}
. {stata povtime [aw=w] if country==1, y(y) z(z) t(6) decomp}

{p 4 8 2}
Bootstrapping P(Y;z), example for (gamma=2, beta=0, alpha=2), and (gamma=2, beta=1, alpha=2) [BC estimates]

	cap program drop pt
	program def pt
	 povtime [aw=w] if country==1, y(y) z(z) t(6)
	end
	bootstrap r(P_2_1_2) r(P_2_2_2) if country==1, reps(10): pt
	estat bootstrap

{title:Author}


{p 4 4 2}{browse "http://webs.uvigo.es/cgradin": Carlos Gradin}
<cgradin@uvigo.gal>{break}
Facultade de CC. Economicas{break}
Universidade de Vigo{break}
36310 Vigo, Galicia, Spain.


{title:References}


{p 4 8 2}
Bossert, W., Chakravarty, S. and D'Ambrosio, C. (2012), Poverty and Time, Journal of Economic Inequality, 10(2): 145-162.

{p 4 8 2}
Foster, J.E. (2007) A class of chronic poverty measures, Working Paper No 07-W01, Department of Economics, Vanderbilt University.

{p 4 8 2}
Foster, J.E. (2009) A class of chronic poverty measures, in Poverty Dynamics: Interdisciplinary Perspectives, Addison, T., Hulme, D. and Kanbur, R. (Eds.), Chapter 3, Oxford University Press: Oxford.

{p 4 8 2}
Gradin, C., Del Rio, C. and Canto, O. (2012), Measuring Poverty Accounting for Time, Review of Income and Wealth, 58(2): 330-354.


{title:Also see}

{p 4 13 2}
{help akdensity} if installed; {help apoverty} if installed; {help povdeco} if installed; {help poverty} if installed; {help glcurve} if installed


