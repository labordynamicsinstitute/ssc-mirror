{smcl}
{* *! version 1.4.1  19sep2026  Ben Adarkwa Dwamena}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "bayesmh" "help bayesmh"}{...}
{vieweralsosee "" "--"}{...}
{title:Title}

{phang}
{bf:bayesinits} {hline 2} Automated chain-specific initialization for {cmd:bayesmh}


{title:Syntax}

{p 8 17 2}
{cmd:bayesinits}, {cmd:nchains(}{it:#}{cmd:)}
[{cmd:unconstrained(}{it:namelist}{cmd:)}
 {cmd:positive(}{it:namelist}{cmd:)}
 {cmd:corr(}{it:namelist}{cmd:)}
 {cmd:fisherz(}{it:namelist}{cmd:)}
 {cmd:phi(}{it:namelist}{cmd:)}
 {cmd:simplex(}{it:namelist}{cmd:)}
 {cmd:center(}{it:name}{cmd:=}{it:expr} ...{cmd:)}
 {cmd:scale(}{it:name}{cmd:=}{it:#} ...{cmd:)}
 {cmd:mle}
 {cmd:estimates(}{it:name}{cmd:)}
 {cmd:inflate(}{it:#}{cmd:)}
 {cmd:map(}{it:name}{cmd:=}{it:coefname} ...{cmd:)}
 {cmd:seed(}{it:#}{cmd:)}
 {cmd:rngstream(}{it:#}{cmd:)}
 {cmd:fmt(}{it:"%fmt"}{cmd:)}
 {cmd:compact} ]


{title:Description}

{pstd}
{cmd:bayesinits} generates domain-aware, randomized initial values for one or more
Markov chains to be used with {cmd:bayesmh}'s {cmd:init#()} options.

{pstd}
The command constructs a separate initialization string for each chain, respecting
parameter domains such as unconstrained, positive, correlation, Fisher-z, angular,
and simplex parameters.  The strings are stored in returned macros
{cmd:r(init1)}, {cmd:r(init2)}, ..., {cmd:r(initK)}, where {it:K} is given by
{cmd:nchains()}.  Two composite strings, {cmd:r(init_all)} and
{cmd:r(init_all_wrap)}, are also returned for convenience.

{pstd}
The initialization strings use the syntax

{p 12 16 2}
{cmd:{c -(}}{it:parm}{cmd:{c )-}} {it:value}

{pstd}
for each parameter, that is, the parameter name enclosed in braces followed by
the numeric value, without an equals sign.  For example, a valid initialization
string for a single chain might look like

{p 12 16 2}
{cmd:{c -(}beta0{c )-} 0.12345 {c -(}beta1{c )-} -0.45678 {c -(}sigma2{c )-} 1.23456 {c -(}rho12{c )-} 0.21789}

{pstd}
These strings can be passed directly to {cmd:bayesmh} via its {cmd:init#()} options.
The goal of {cmd:bayesinits} is to automate dispersed, domain-consistent, and
reproducible starting values across multiple chains.


{title:Options}

{dlgtab:Main}

{phang}
{cmd:nchains(}{it:#}{cmd:)} is required and specifies the number of Markov
chains for which to generate initialization strings.  For each
{it:k} = 1, ..., {cmd:nchains()}, {cmd:bayesinits} stores a chain-specific
string in {cmd:r(init}{it:k}{cmd:)}.

{dlgtab:Parameter-domain options}

{phang}
{cmd:unconstrained(}{it:namelist}{cmd:)} specifies the list of parameters that
are unconstrained on the real line, such as regression coefficients or
intercepts.  For each parameter {it:theta} in this list, initial values are
drawn from a normal distribution,

{p 16 20 2}
{cmd:theta ~ Normal(mu, sigma^2)}

{pstd}
on the raw scale, where {it:mu} and {it:sigma} are determined by the default
domain settings and may be overridden by {cmd:center()} and {cmd:scale()}.

{phang}
{cmd:positive(}{it:namelist}{cmd:)} specifies the list of parameters that must
be strictly positive, such as variances or other scale parameters.  Sampling is
performed on the logarithmic scale.  For each parameter {it:lambda},

{p 16 20 2}
{cmd:log(lambda) ~ Normal(mu, sigma^2)}

{pstd}
and the initial value is {cmd:lambda = exp(log(lambda))}.  Extreme values are
truncated to a reasonable range (by default roughly between 1e-6 and 1e+6).

{phang}
{cmd:corr(}{it:namelist}{cmd:)} specifies correlation parameters {it:rho} in
(-1, 1).  Sampling is performed on the Fisher-z scale:

{p 16 20 2}
{cmd:z = atanh(rho) ~ Normal(mu, sigma^2)}

{pstd}
and the initial value is {cmd:rho = tanh(z)}.  Values are truncated so that
|{it:rho}| < 0.995 to avoid boundary issues.

{phang}
{cmd:fisherz(}{it:namelist}{cmd:)} specifies parameters that are already
parameterized on the Fisher-z scale, as is sometimes done in hierarchical
correlation models.  For such parameters, sampling is directly on the z-scale:

{p 16 20 2}
{cmd:z ~ Normal(mu, sigma^2)}

{pstd}
with no additional transformation.

{phang}
{cmd:phi(}{it:namelist}{cmd:)} specifies angular parameters {it:phi}, typically
in (0, pi), such as those arising from spherical or trigonometric
reparameterizations (for example, {it:rho} = cos({it:phi})).  For each
{it:phi},

{p 16 20 2}
{cmd:phi ~ Normal(pi/2, sigma^2)}

{pstd}
with values clipped to the open interval (0.001, pi - 0.001).  Centers and
scales may again be overridden with {cmd:center()} and {cmd:scale()}.

{phang}
{cmd:simplex(}{it:namelist}{cmd:)} specifies a collection of parameters
{cmd:(p1, ..., pG)} that represent a single simplex, that is, each element is
positive and the sum across the group equals 1.  For {it:G} = 1, the single
element is fixed to 1.  For {it:G} > 1, {cmd:bayesinits} draws

{p 16 20 2}
{cmd:w_j = exp(sigma * z_j)}

{pstd}
with {cmd:z_j ~ Normal(0, 1)}, and then sets

{p 16 20 2}
{cmd:p_j = w_j / sum_j w_j}

{pstd}
thus ensuring positivity and unit sum.  At most one simplex group may be
specified per {cmd:bayesinits} invocation.

{dlgtab:Center and scale options}

{phang}
{cmd:center(}{it:name}{cmd:=}{it:expr} ...{cmd:)} overrides the default
domain-specific centers for selected parameters.  The argument is a
space-separated list of {it:name}={it:expr} pairs, for example,

{p 16 20 2}
{cmd:center(beta0=0 beta1=1 sig2=2)}

{pstd}
The {it:name} must match the parameter name exactly as it appears in the
domain options.  Expressions {it:expr} are evaluated as numeric expressions
(for example, {cmd:center(phi1=c(pi)/2)}).  For positive and correlation
parameters, {cmd:center()} is specified on the natural scale (the variance or
correlation itself) and is transformed internally to the working scale (log
for {cmd:positive()}, Fisher-z for {cmd:corr()}).

{phang}
{cmd:scale(}{it:name}{cmd:=}{it:#} ...{cmd:)} overrides the default
domain-specific scales.  The syntax is analogous to {cmd:center()}, for
example,

{p 16 20 2}
{cmd:scale(beta0=2 rho12=0.4)}

{pstd}
The specified values are interpreted as standard deviations on the working
scale.  If a parameter is not listed in {cmd:center()} or {cmd:scale()}, the
domain defaults are used.

{dlgtab:MLE-based initialization}

{phang}
{cmd:mle} derives centers and scales from the estimation results currently in
memory (or from a stored set; see {cmd:estimates()}), typically a maximum
likelihood or least-squares fit of the same or a closely related model.  For
each parameter listed in {cmd:unconstrained()}, {cmd:positive()},
{cmd:corr()}, or {cmd:fisherz()} whose coefficient can be located in
{cmd:e(b)}, the center is set to the point estimate on the natural scale, and
the scale is set to {cmd:inflate()} times the standard error from {cmd:e(V)},
transformed to the working scale by the delta method: SE for unconstrained
and Fisher-z parameters, SE/{it:lambda-hat} on the log scale for positive
parameters, and SE/(1 - {it:rho-hat}^2) on the Fisher-z scale for correlation
parameters.  Parameters without a matching coefficient, and all {cmd:phi()}
and {cmd:simplex()} parameters, keep their domain defaults.  Explicit
{cmd:center()} and {cmd:scale()} entries override {cmd:mle}-derived values.
If no estimation results are in memory, {cmd:mle} exits with error 301.

{phang}
{cmd:estimates(}{it:name}{cmd:)} specifies a stored estimation set (see
{helpb estimates store}) to use instead of the current results.  The named
set is restored before centers and scales are derived.

{phang}
{cmd:inflate(}{it:#}{cmd:)} multiplies the delta-method standard errors to
produce overdispersed starting points; the default is {cmd:inflate(2)}.
Values near 1 would concentrate all chains in the immediate neighborhood of
the MLE - an approximation of the posterior itself - which defeats the
purpose of between-chain convergence diagnostics; values of 2-4 are
recommended (Gelman and Rubin 1992).

{phang}
{cmd:map(}{it:name}{cmd:=}{it:coefname} ...{cmd:)} links {cmd:bayesinits}
parameter names to coefficient names in {cmd:e(b)} when the two differ, which
is the usual case: {cmd:regress y x} produces coefficients {cmd:x} and
{cmd:_cons}, while the corresponding {cmd:bayesmh} parameters might be named
{cmd:b1} and {cmd:b0}.  For example, {cmd:map(b0=_cons b1=x)}.  Equation-
qualified names such as {cmd:lnsig:_cons} are allowed; if {it:coefname} alone
is not found, {it:coefname}{cmd::_cons} is also tried.  Parameters not listed
in {cmd:map()} are matched by their own names.  For a quantity with no
coefficient in {cmd:e(b)} (for example, the residual variance after
{cmd:regress}), use {cmd:center()} directly, which accepts expressions such
as {cmd:center(sig2=e(rmse)^2)} and overrides {cmd:mle}.

{dlgtab:Random-number controls}

{phang}
{cmd:seed(}{it:#}{cmd:)} sets the random-number seed before any draws are
taken, ensuring reproducible initialization across runs.  The default is
{cmd:seed(12345)}.

{phang}
{cmd:rngstream(}{it:#}{cmd:)} optionally sets Stata's random-number stream at
the start of each chain.  When {cmd:rngstream()} is specified with a positive
integer {it:S}, chain {it:k} uses stream {it:S} + {it:k} - 1.  This provides
independent streams across chains and is particularly useful when running
multiple chains in parallel.

{dlgtab:Formatting and compactness}

{phang}
{cmd:fmt(}{it:"%fmt"}{cmd:)} specifies the numeric display format to use when
converting generated values into text via {cmd:strofreal()}.  The default is
{cmd:fmt("%9.5f")}.  Shorter formats such as {cmd:fmt("%8.4f")} can help
shorten the resulting initialization strings.

{phang}
{cmd:compact} suppresses spaces between tokens in the initialization string,
so that

{p 16 20 2}
{cmd:{c -(}beta0{c )-}0.12345{c -(}beta1{c )-}-0.45678}

{pstd}
is produced instead of

{p 16 20 2}
{cmd:{c -(}beta0{c )-} 0.12345 {c -(}beta1{c )-} -0.45678}

{pstd}
This can significantly reduce the total command length when many parameters
are present.


{title:Domain defaults}

{pstd}
Unless overridden by {cmd:center()} or {cmd:scale()}, {cmd:bayesinits} uses
the following default centers and scales (on the working scale):

{p2colset 12 30 30 2}{...}
{p2col:{it:Domain}}{it:Center}{col 42}{it:Scale}{p_end}
{p2line}
{p2col:unconstrained}0{col 42}1{p_end}
{p2col:positive}1{col 42}0.5  (log scale){p_end}
{p2col:corr}0{col 42}0.5  (Fisher-z scale){p_end}
{p2col:fisherz}0{col 42}0.5{p_end}
{p2col:phi}pi/2{col 42}0.7{p_end}
{p2col:simplex}0{col 42}0.3  (log-normal jitter){p_end}
{p2line}


{title:Stored results}

{pstd}
{cmd:bayesinits} is an {cmd:rclass} command.  It stores the following in
{cmd:r()}:

{synoptset 25 tabbed}{...}
{synopt:{cmd:r(init1)}, ..., {cmd:r(initK)}}chain-specific initialization strings{p_end}
{synopt:{cmd:r(init_all)}}composite single-line string {cmd:init1(}...{cmd:)} {cmd:init2(}...{cmd:)} ...{p_end}
{synopt:{cmd:r(init_all_wrap)}}composite string with {cmd:///} line breaks for long calls{p_end}


{title:Remarks}

{pstd}
{cmd:bayesinits} is intended for use with {cmd:bayesmh} and its
{cmd:init#()} options.  A typical workflow for {it:K} chains is

{phang2}{cmd:. bayesinits, nchains(3) unconstrained(beta0 beta1) positive(sig2) corr(rho12)}{p_end}
{phang2}{cmd:. bayesmh y = ({c -(}beta0{c )-} + {c -(}beta1{c )-}*x), likelihood(normal({c -(}sig2{c )-})) ///}{p_end}
{phang2}{cmd:      prior({c -(}beta0{c )-}, normal(0,10)) prior({c -(}beta1{c )-}, normal(0,10)) ///}{p_end}
{phang2}{cmd:      prior({c -(}sig2{c )-}, igamma(0.001, 0.001)) ///}{p_end}
{phang2}{cmd:      prior({c -(}rho12{c )-}, normal(0,1)) ///}{p_end}
{phang2}{cmd:      `r(init_all)'}{p_end}

{pstd}
The {cmd:initrandom} option of {cmd:bayesmh} also generates random initial
values, drawing from the specified priors when possible.  However,
{cmd:initrandom} does not explicitly distinguish parameter domains (positive,
correlation, simplex, etc.) and does not provide chain-specific, formatted
strings in {cmd:r()}.  {cmd:bayesinits} complements {cmd:initrandom} by
offering fine-grained, domain-aware, and reproducible initialization that can
be inspected and reused explicitly.

{pstd}
You should not combine {cmd:initrandom} with user-specified {cmd:init#()}
options.  When using {cmd:bayesinits}, rely on the {cmd:init#()} options
it generates and omit {cmd:initrandom} from the {cmd:bayesmh} call.

{pstd}
Running multiple chains from dispersed (overdispersed) starting points is the
basis of standard MCMC convergence diagnostics such as the Gelman-Rubin
potential scale reduction factor; see Gelman and Rubin (1992), Brooks and
Gelman (1998), and Vehtari et al. (2021).  The Fisher-z transformation used
for correlation parameters is due to Fisher (1915).  The {cmd:mle} option
operationalizes a common variant of this advice: center the chains at a
preliminary maximum likelihood fit and disperse them by an inflated multiple
of its standard errors, so that every chain starts in the high-density
region of the likelihood while remaining overdispersed relative to the
posterior.


{title:Examples}

{pstd}
Basic use with unconstrained and positive parameters

{phang2}{cmd:. bayesinits, nchains(2) unconstrained(beta0 beta1) positive(sig2)}{p_end}

{phang2}{cmd:. return list}{p_end}

{pstd}
Adding correlation and simplex parameters

{phang2}{cmd:. bayesinits, nchains(3) ///}{p_end}
{phang2}{cmd:      unconstrained(beta0 beta1) ///}{p_end}
{phang2}{cmd:      positive(sig2_tau sig2_eps) ///}{p_end}
{phang2}{cmd:      corr(rho12) ///}{p_end}
{phang2}{cmd:      simplex(p1 p2 p3)}{p_end}

{pstd}
Passing the composite initialization to {cmd:bayesmh}

{phang2}{cmd:. bayesmh y = ({c -(}beta0{c )-}+{c -(}beta1{c )-}*x), likelihood(normal({c -(}sig2_tau{c )-})) ///}{p_end}
{phang2}{cmd:      prior({c -(}beta0{c )-}, normal(0,10)) ///}{p_end}
{phang2}{cmd:      prior({c -(}beta1{c )-}, normal(0,10)) ///}{p_end}
{phang2}{cmd:      prior({c -(}sig2_tau{c )-}, igamma(0.001,0.001)) ///}{p_end}
{phang2}{cmd:      prior({c -(}rho12{c )-}, normal(0,1)) ///}{p_end}
{phang2}{cmd:      `r(init_all)'}{p_end}

{pstd}
Centering at maximum likelihood estimates with inflated dispersion

{phang2}{cmd:. regress y x}{p_end}

{phang2}{cmd:. bayesinits, nchains(4) unconstrained(b0 b1) positive(sig2) ///}{p_end}
{phang2}{cmd:      mle map(b0=_cons b1=x) inflate(3) center(sig2=e(rmse)^2)}{p_end}

{pstd}
Using formatted output and compact strings

{phang2}{cmd:. bayesinits, nchains(4) unconstrained(beta0 beta1) ///}{p_end}
{phang2}{cmd:      positive(sig2) fmt("%8.4f") compact}{p_end}


{title:References}

{phang}
Brooks, S. P., and A. Gelman.  1998.
General methods for monitoring convergence of iterative simulations.
{it:Journal of Computational and Graphical Statistics} 7: 434-455.
{browse "https://doi.org/10.1080/10618600.1998.10474787":https://doi.org/10.1080/10618600.1998.10474787}.

{phang}
Fisher, R. A.  1915.
Frequency distribution of the values of the correlation coefficient in
samples from an indefinitely large population.
{it:Biometrika} 10: 507-521.
{browse "https://doi.org/10.1093/biomet/10.4.507":https://doi.org/10.1093/biomet/10.4.507}.

{phang}
Gelman, A., J. B. Carlin, H. S. Stern, D. B. Dunson, A. Vehtari, and
D. B. Rubin.  2013.
{it:Bayesian Data Analysis}.  3rd ed.  Boca Raton, FL: Chapman & Hall/CRC.
{browse "https://doi.org/10.1201/b16018":https://doi.org/10.1201/b16018}.

{phang}
Gelman, A., and D. B. Rubin.  1992.
Inference from iterative simulation using multiple sequences.
{it:Statistical Science} 7: 457-472.
{browse "https://doi.org/10.1214/ss/1177011136":https://doi.org/10.1214/ss/1177011136}.

{phang}
StataCorp.  2025.
{it:Stata Bayesian Analysis Reference Manual}.
College Station, TX: Stata Press.
{browse "https://www.stata.com/manuals/bayes.pdf":https://www.stata.com/manuals/bayes.pdf}.

{phang}
Vehtari, A., A. Gelman, D. Simpson, B. Carpenter, and P.-C. Buerkner.  2021.
Rank-normalization, folding, and localization: An improved R-hat for
assessing convergence of MCMC (with discussion).
{it:Bayesian Analysis} 16: 667-718.
{browse "https://doi.org/10.1214/20-BA1221":https://doi.org/10.1214/20-BA1221}.


{title:Author}

{pstd}
Ben Adarkwa Dwamena, M.D.{break}
University of Michigan, Department of Radiology{break}
Division of Nuclear Medicine and Molecular Imaging{break}
Email: {browse "mailto:bdwamena@umich.edu":bdwamena@umich.edu}


{title:Also see}

{psee}
Online:  {help bayesmh}, {help bayes}, {help set rngstream}, {help strofreal()}
{p_end}
