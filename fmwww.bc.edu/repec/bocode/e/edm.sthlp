{smcl}


{title:edm Description}

{p 4 4 2}  The command {bf:edm} implements a series of tools that can be used for empirical dynamic
modeling in Stata. The core algorithm is written in C++ (with a Mata backup) to achieve reasonable execution speed. The
command keyword is {bf:edm}, and should be immediately followed by a subcommand such as explore or
xmap. A dataset must be declared as time-series or panel data by the tsset or xtset command prior to
using the edm command, and time-series operators including l., f., d., and s. can be used (the last
for seasonal differencing).


{title:Syntax}

{p 4 4 2}  The {bf:explore} subcommand follows the syntax below and supports one
variable for exploration using simplex projection or S-mapping.

{p 8 12 2}  {bf:edm} explore {bf:variable} [if {bf:exp}], [e(numlist ascending >=2)]
[tau(integer 1)] [theta(numlist ascending)] [k(integer 0)] [ALGorithm(string)] [REPlicate(integer 0)]
[seed(integer 0)] [full] [RANDomize] [PREDICTionsave(name)] [COPREDICTionsave(name)] [copredictvar(string)]
[CROSSfold(integer 0)] [CI(integer 0)] [EXTRAembed(string)] [ALLOWMISSing] [MISSINGdistance(real 0)]
[dt] [reldt] [DTWeight(real 0)] [DTSave(name)] [DETails] [reportrawe] [strict] [Predictionhorizon(string)]
[dot(integer 1)] [mata] [gpu] [nthreads(integer 0)] [savemanifold(name)] [idw(real 0)]
[lowmemory]

{p 4 4 2}  The second subcommand {bf:xmap} performs convergent cross-mapping (CCM). The subcommand
follows the syntax below and requires two variables to follow immediately after xmap. It shares many
of the same options with the explore subcommand although there are some differences given the
different purpose of the analysis.

{p 8 12 2}  {bf:edm} xmap {bf:variables} [if {bf:exp}], [e(integer 2)] [tau(integer 1)] [theta(real 1)]
[Library(numlist)] [RANDomize] [k(integer 0)] [ALGorithm(string)] [REPlicate(integer 0)] [strict]
[DIrection(string)] [seed(integer 0)] [PREDICTionsave(name)] [COPREDICTionsave(name)] [copredictvar(string)]
[CI(integer 0)] [EXTRAembed(string)] [ALLOWMISSing] [MISSINGdistance(real 0)] [dt] [reldt]
[DTWeight(real 0)] [DTSave(name)] [oneway] [DETails] [SAVEsmap(string)] [Predictionhorizon(string)]
[dot(integer 1)] [mata] [gpu] [nthreads(integer 0)] [savemanifold(name)] [idw(real 0)]
[lowmemory]

{p 4 4 2} The third subcommand {bf:update} updates the plugin to its latest version

{p 8 12 2}  {bf:edm} update, [develop] [replace]

{p 4 4 2} The fourth subcommand {bf:version} displays the current version number

{p 8 12 2}  {bf:edm} version

{marker options}{...} {title:Options}

{dlgtab: Options for explore and xmap subcommands}

{phang}  {bf:e(numlist ascending)}: This option specifies the number of dimensions E used for the
main variable in the manifold reconstruction. If a list of numbers is provided, the command will
compute results for all numbers specified. The xmap subcommand only supports a single integer as the
option whereas the explore subcommand supports the option as a numlist. The default value for E is
2, but in theory E can range from 2 to almost half of the total sample size. The actual E used in
the estimation may be different if additional variables are incorporated. A error message is
provided if the specified value is out of range. Missing data will limit the maximum E under the
default deletion method.

{phang}  {bf:tau(integer)}: The tau (or τ) option allows researchers to specify the ‘time delay’,
which essentially sorts the data by the multiple τ. This is done by specifying lagged embeddings
that take the form: t,t-1τ,…,t-(E-1)τ, where the default is tau(1) (i.e., typical lags). However, if
tau(2) is set then every-other t is used to reconstruct the attractor and make predictions—this does
not halve the observed sample size because both odd and even t would be used to construct the set of
embedding vectors for analysis. This option is helpful when data are oversampled (i.e., spaced too
closely in time) and therefore very little new information about a dynamic system is added at each
occasion. However, the tau() setting is also useful if different dynamics occur at different times
scales, and can be chosen to reflect a researcher’s theory-driven interest in a specific time-scale
(e.g., daily instead of hourly). Researchers can evaluate whether τ>1 is required by checking for
large autocorrelations in the observed data (e.g., using Stata’s corrgram function). Of course, such
a linear measure of association may not work well in nonlinear systems and thus researchers can also
check performance by examining ρ and MAE at different values of τ.

{phang}  {bf:theta(numlist ascending)}: Theta (or θ) is the distance weighting parameter for the
local neighbours in the manifold. It is used to detect the nonlinearity of the system in the explore
subcommand for S-mapping. Of course, as noted above, for simplex projection and CCM a weight of
theta(1) is applied to neighbours based on their distance, which is reflected in the fact that the
default value of θ is 1. However, this can be altered even for simplex projection or CCM (two cases
that we do not cover here). Particularly, values for S-mapping to test for improved predictions as
they become more local may include the following command: theta(0 .00001 .0001 .001 .005 .01 .05 .1
.5 1 1.5 2 3 4 6 8 10).

{phang}  {bf:k(integer)}: This option specifies the number of neighbours used for prediction. When
set to 1, only the nearest neighbour is used, but as k increases the next-closest nearest neighbours
are included for making predictions. In the case that k is set 0, the number of neighbours used is
calculated automatically (typically as k = E + 1 to form a simplex around a target), which is the
default value. When k < 0 (e.g., k(-1)), all possible points in the prediction set are used (i.e.,
all points in the library are used to reconstruct the manifold and predict target vectors). This
latter setting is useful and typically recommended for S-mapping because it allows all points in the
library to be used for predictions with the weightings in theta. However, with large datasets this
may be computationally burdensome and therefore k(100) or perhaps k(500) may be preferred if T or NT
is large.

{phang}  {bf:ALGorithm(string)}: This option specifies the algorithm used for prediction. If not
specified, simplex projection (a locally weighted average) is used. Valid options include simplex
and smap, the latter of which is a sequential locally weighted global linear mapping (or S-map as
noted previously). In the case of the xmap subcommand where two variables predict each other, the
algorithm(smap) invokes something analogous to a distributed lag model with E + 1 predictors
(including a constant term c) and, thus, E + 1 locally-weighted coefficients for each predicted
observation/target vector—because each predicted observation has its own type of regression done
with k neighbours as rows and E + 1 coefficients as columns. As noted below, in this case special
options are available to save these coefficients for post-processing but, again, it is not actually
a regression model and instead should be seen as a manifold.

{phang}  {bf:RANDomize}: When splitting the observations into library and prediction sets, by default
the oldest observations go into the library set and the newest observations to the prediction set.
Though if the randomize option is specified, the data is allocated into the two sets in a random
fashion. If the replicate option is specified, then this randomization is enabled automatically.

{phang}  {bf:REPlicate(integer)}: The explore subcommand uses a random 50/50 split for simplex
projection and S-maps, whereas the xmap subcommand selects the observations randomly for library
construction if the size of the library L is smaller than the size of all available observations. In
these cases, results may be different in each run because the embedding vectors (i.e., the
E-dimensional points) used to reconstruct a manifold are chosen at random. The replicate option
takes advantages of this to allow repeating the randomization process and calculating results each
time. This is akin to a nonparametric bootstrap without replacement, and is commonly used for
inference using confidence intervals in EDM (Tsonis et al., 2015; van Nes et al., 2015; Ye et al.,
2015b). When replicate is specified, such as replicate(50), mean values and the standard deviations
of the results are reported across the 50 runs by default. As we note below, it is possible to save
all estimates for post-processing using typical Stata commands such as svmat, allowing the graphing
of results or finding percentile-based with the pctile command.

{phang}  {bf:PREDICTionsave(variable)}: This option allows you to save the edm predictions
as a variable, which could be useful for plotting and diagnosis.

{phang}  {bf:COPREDICTionsave(variable)}: This option allows you to save the copredictions
as a variable. You must specify the copredictvar(variables) options for this to work.

{phang}  {bf:copredictvar(variable)}: This option specifies the variable used for coprediction.
A second prediction is run for each configuration of E, library, etc., using the same library set
but with a prediction set built from the lagged embedding of this variable.

{phang}  {bf:Predictionhorizon(integer)}: This option adjusts the default number of observations ahead
which we predict. By default, the explore mode predict τ observations ahead and the xmap mode uses p(0).
This parameter can be negative.

{phang}  {bf:DETails}: By default, only mean values and standard deviations are reported when the
replicate option is specified. The details option overrides this behaviour by providing results for
each individual run. Irrespective of using this option, all results can be saved for
post-processing.

{phang}  {bf:CI(integer)}: When used with replicate() or crossfold(), this option reports the
confidence interval for the mean of the estimates (MAE and/or ρ), as well as the percentiles of
their distribution. The first row of output labelled “Est. mean CI” reports the estimated confidence
interval of the mean ρ, assuming that ρ has a normal distribution—estimated as the corrected sample
standard deviation (with N-1 in the denominator) divided by the squared root of the number of
replications. The reported range can be used to compare mean ρ across different (hyper) parameter
values (e.g., different E, θ, or L) using the same datasets as if the sample was the entire
population (such that uncertainty is reduced to 0 when the number of replications →∞). These
intervals can be used to test which (hyper) parameter values best describe a sample, as might be
typically used when using crossfold validation methods. The row labelled with “Pc (Est.)” follows
the same normality assumption and reports the estimated percentile values based on the corrected
sample standard deviation of the replicated estimates. The row labelled “Pc (Obs.)” reports the
actual observed percentile values from the replicated estimates. In both of these latter cases the
percentile values offer alternative metrics for comparisons across distributions, which would be
more useful for testing typical hypotheses about population differences in estimates across
different (hyper) parameter values (e.g., different E, θ, or L), such as testing whether a dynamical
system appears to be nonlinear in a population (i.e., testing whether ρ is maximized when θ > 0).
The number specified within the ci() bracket determines the confidence level and the locations of
the percentile cut-offs. For example, ci(90) instructs edm to return 90% CI as well as the cut-off
values for the 5th and 95th percentile values—because ρ and MAE values cannot or are not expected to
take on negative values, we typically prefer one-tailed hypothesis tests and therefore would use
ci(90) to get a one-tailed 95% interval. These estimated ranges are also included in the e() return
list as a series of scalars with names starting with “ub” for upper bound and “lb” for lower bound
values of the CIs. These return values can be used for further post-processing.

{phang}  {bf:seed(integer)}: This option specifies the seed used for the random number. In some
special cases users may wish to use this in order to keep library and prediction sets the same
across simplex projection and S-mapping with a single variable, or across multiple CCM runs with
different variables. Note: if "set rng" has been used to change Stata's random number generation
algorithm, then edm will temporarily change it the default 64 bit Mersenne twister internally.

{phang}  {bf:strict}: When this option is specified, the computation will fail if the requested
number of neighboring observations is not present. By default, if not all of the request neighbors
are available, the computation will just continue using as many as possible.

{phang}  {bf:ALLOWMISSing} This option allows observations with missing values to be used in the
manifold. Vectors with at least one non-missing values will be used in the manifold construction.
Distance computations are adapted to allow missing values when this option is specified.

{phang}  {bf:MISSINGdistance(real)}: This option allows users to specify the assumed distance
between missing values and any values (including missing) when estimating the Euclidean distance of
the vector. This enables computations with missing values. The option implies allowmissing. By
default, the distance is set to the expected distance of two random draws in a normal distribution,
which equals to 2/sqrt(pi) * standard deviation of the mapping variable.

{phang}  {bf:EXTRAembed(variables)}: This option allows incorporating additional variables into the
embedding (multivariate embedding), e.g. extra(z l.z). Time series lists are unabbreviated here,
e.g. extra(L(1/3).z) will be equivalent to extra(L1.z L2.z L3.z). Normally, lagged versions of the
extra variables are not included in the embedding, however the syntax extra(z(e)) includes e lags
of z in the embedding.

{phang}  {bf:dt}: This option allows automatic inclusion of the timestamp differencing in the
embedding. There will be E dt variables included for an embedding with E dimensions. By default,
the weights used for these additional variables equal to the standard deviation of the main
mapping variable divided by the standard deviation of the time difference. This can be overridden by
the `dtweight()` option. `dt` option will be ignored when running with data with no sampling
variation in the time lags. The first dt variable embeds the time of the between the most recent
observation and the time of the corresponding target/predictand.

{phang}  {bf:reldt}: This option, to be read as 'relative dt', is like the 'dt' option above in
that it includes E extra variables for an embedding with E dimensions. However the timestamp
differences added are not the time between the corresponding observations, but the time of the
target/predictand minus the time of the lagged observations.

{phang}  {bf:DTWeight(real)}: This option specifies the weight used for the timestamp differencing
variable.

{phang}  {bf:DTSave(variable)}: This option allows users to save the internally generated timestamp
differencing variable.

{phang}  {bf:nthreads(integer)}: The number of threads the C++ plugin will use for parallel
computations. The default is the number of cores available on the host computer.

{phang}  {bf:idw(real)}: This parameter is used when xtset indicates that the current dataset
is panel data. Then, idw specifies a penalty that is added to the distances between points in the
manifold which correspond to observations from different panels. By default idw is 0, so the data
from all panels is mixed together and treatly equally. If idw(-1) is set (or any other negative
value), then the weight is treated as 'infinity', so neighbours will never be selected which cross
the boundaries between panels. Setting idw(-1) with k(-1) means we may use a different number of
neighbors for different predictions (i.e. if the panels are unbalanced).

{phang}  {bf:lowmemory}: It is possible that RAM may be depleted while running edm on large datasets
with large values of E. The lowmemory flag directs the plugin to try to save as much space as possible
by more efficiently using memory, though for small datasets this will likely slow down the computations
by a small but noticeable amount.

{phang}  Besides the shared parameters, edm explore supports the following extra options:

{phang}  {bf:CROSSfold(integer)}: This option asks the program to run a cross-fold validation of the
predicted variables. crossfold(5) indicates a 5-fold cross validation. Note that this cannot be used
together with replicate. This option is only available with the `explore` subcommand.

{phang}  {bf:full}: When this option is specified, the explore command will use all possible
observations in the manifold construction instead of the default 50/50 split. This is effectively
the same as leave-one-out cross-validation as the observation itself is not used for the prediction.

{phang}  {bf:reportrawe}: By default, the program reports the actual E used in the manifold. With
this option, the program will only report the number of dimensions constructed from the main
variable.

{phang}  {bf:Library(numlist ascending)}: 	This option specifies the total library size L used for
the manifold reconstruction. Varying the library size is used to estimate the convergence property
of the cross-mapping, with a minimum value Lmin = E + 2 and the maximum equal to the total number of
observations minus sufficient lags (e.g., in the time-series case without missing data this is Lmax
= T + 1 – E). An error message is given if the L value is beyond the allowed range. To assess the
rate of convergence (i.e., the rate at which ρ increases as L grows), the full range of library
sizes at small values of L can be used, such as if E = 2 and T = 100, with the setting then perhaps
being library(4(1)25 30(5)50 54(15)99). This option is only available with the `xmap` subcommand.

{phang}  {bf:SAVEsmap(string)}: This option allows smap coefficients to be stored in variables with
a specified prefix. For example, specifying “edm xmap x y, algorithm(smap) savesmap(beta) k(-1)” will
create a set of new variables such as beta1_b0_rep1. The string prefix (e.g., ‘beta’) must not be
shared with any variables in the dataset, and the option is only valid if the algorithm(smap) is
specified. In terms of the saved variables such as beta1_b0_rep1, the first number immediately after
the prefix ‘beta’ is 1 or 2 and indicates which of the two listed variables is treated as the
dependent variable in the cross-mapping (i.e., the direction of the mapping). For the “edm xmap x y”
case, variables starting with beta1_ contain coefficients derived from the manifold M_X created
using the lags of the first variable ‘x’ to predict Y, or Y|M_X. This set of variables therefore
store the coefficients related to ‘x’ as an outcome rather than a predictor in CCM. Keep in mind
that any Y→X effect associated with the beta1_ prefix is shown as Y|M_X, because the outcome is used
to cross-map the predictor, and thus the reported coefficients will be scaled in the opposite
direction of a typical regression (because in CCM the outcome variable predicts the cause). To get
more familiar regression coefficients (which will be locally weighted), variables starting with
beta2_ store the coefficients estimated in the other direction, where the second listed variable ‘y’
is used for the manifold reconstruction M_Y for the mapping X|M_Y in the “edm xmap x y” case, testing
the opposite X→Y effect in CCM, but with reported S-map coefficients that map to a Y→X regression.
We appreciate that this may be unintuitive, but because CCM causation is tested by predicting the
causal variable with the outcome, to get more familiar regression coefficients requires reversing
CCM’s causal direction to a more typical predictor→outcome regression logic. This can be clarified
by reverting to the conditional notation such as X|M_Y, which in CCM implies a left-to-right X→Y
effect, but for the S-map coefficients will be scaled as a locally-weighted regression in the
opposite direction Y→X. Moving on, following the 1 and 2 is the letter b and a number. The numerical
labeling scheme generally follows the order of the lag for the main variable and then the order of
the extra variables introduced in the case of multivariate embedding. b0 is a special case which
records the coefficient of the constant term in the regression. The final term rep1 indicates the
coefficients are from the first round of replication (if the replicate() option is not used then
there is only one). Finally, the coefficients are saved to match the observation t in the dataset
that is being predicted, which allows plotting each of the E estimated coefficients against time
and/or the values of the variable being predicted. The variables are also automatically labelled for
clarity. This option is only available with the `xmap` subcommand.

{phang}  {bf:DIrection(string)}: This option allows users to control whether the cross mapping is
calculated bidirectionally or unidirectionally, the latter of which reduces computation times if
bidirectional mappings are not required. Valid options include “oneway” and “both”, the latter of
which is the default and computes both possible cross-mappings. When oneway is chosen, the first
variable listed after the xmap subcommand is treated as the potential dependent variable following
the conventions in the regression syntax of Stata such as the‘reg’ command, so “edm xmap x y,
direction(oneway)” produces the cross-mapping Y|M_X, which pertains to a Y→X effect. This is
consistent with the beta1_ coefficients from the previous savesmap(beta) option. On this point, the
direction(oneway) option may be especially useful when an initial “edm xmap x y”procedure shows
convergence only for a cross-mapping Y|M_X, which pertains to a Y→X effect. To save time with large
datasets, any follow-up analyses with the algorithm(smap) option can then be conducted with “edm
xmap x y, algorithm(smap) savesmap(beta) direction(oneway)”.  To make this easier there is also a
simplified oneway option that implies direction(oneway). This option is only available with the
`xmap` subcommand.

{phang}  {bf:oneway}: This option is equivalent to "direction(oneway)"

{dlgtab: Options for update subcommand}

{phang}  The update subcommand supports the following options:

{phang}  {bf:develop}: This option updates the command to its latest development version. The
development version usually contains more features but may be less tested compared with the older
version distributed on SSC. 

{phang}  {bf:replace}: This option specifies whether you allow the update to override your local ado
files.


{title:Examples}

{p 4 4 4}
     
Chicago crime dataset example (included in the auxiliary file) 

    {cmd: use chicago,clear}

    {cmd: edm explore temp, e(2/30)}
    
    {cmd: edm xmap temp crime}
    
    {cmd: edm xmap temp crime, alg(smap) savesmap(beta) e(6) k(-1)}


{title:Updates}

{phang}  To install the stable version or upgrade directly through Stata:

{phang}  {cmd:edm update, replace}

{phang}  To install the development version directly through Stata:

{phang}  {cmd:edm update, develop replace}


{title:Suggested Citation}

{phang}  Li, J, Zyphur, M & Sugihara, G. Beyond linearity, stability, and
equilibrium: The edm package for empirical dynamic modeling and convergent cross-mapping, Stata
Journal


{title:Contact}

{phang}  Jinjing Li, National Centre for Social and Economic Modelling, University of Canberra,
Australia {browse "mailto:jinjing.li@canberra.edu.au":jinjing.li@canberra.edu.au}




