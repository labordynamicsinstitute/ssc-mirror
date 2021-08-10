{smcl}
{* *! version 1.0  24jul2020}{...}
{cmd:help ftruncreg}
{hline}

{title:Title}

{p2colset 5 20 22 2}{...} {phang} {bf:ftruncreg} {hline 2} Faster community-contributed substitute for {cmd:truncreg}{p_end} {p2colreset}{...}

{title:Syntax}

{p 10 17 2} {cmd:ftruncreg} {it:{help varlist:depvar}} {it:{help varlist:indepvars}} {ifin}, [{cmd:}{it:{help ftruncreg##options:options}}]

{synoptset 28 tabbed}{...}
{marker Variables}{...}
{synopthdr :Variables}
{synoptline}
{syntab :Model}
{synopt :{it:{help varname:depvars}}}left-hand-side variable{p_end}
{synopt :{it:{help varname:indepvars}}}right-hand-side variables{p_end}

{synoptset 28 tabbed}{...}
{synopthdr :options}
{synoptline}
{syntab :Main}
{synopt :{opt {ul on}nocons{ul off}tant}}suppress constant term{p_end}
{synopt :{opt {ul on}ll{ul off}}{bf:(}#{bf:)}}left-truncation limit{p_end}
{synopt :{opt {ul on}ul{ul off}}{bf:(}#{bf:)}}right-truncation limit{p_end}

{syntab :SE/Inference}
{synopt :{opt vce}{bf:(}{it:{help vce_option:vcetype}}{bf:)}}{it:vcetype} may be {opt oim}, {opt opg} or {opt robust}{p_end}
{synopt :{opt {ul on}r{ul off}obust}}equivalent to {opt vce(robust)}{p_end}

{syntab :Reporting}
{synopt :{opt lev:el(#)}}set confidence level; default as set by set level{p_end}
{synopt :{opt {ul on}nolog{ul off}}}suppress display of a log{p_end}
{synopt :{help ereturn##display_options :{it:display_options}}}further options for displaying output{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{it:indepvars} may contain factor variables; see {help fvvarlist}.{p_end}
{p 4 6 2}{help ereturn##display_options :{it:display_options}} are those available for {cmd:ereturn display}.{p_end}
{p 4 6 2}The prefix commands {cmd:bootstrap} and {cmd:jackknife} are allowed; {cmd:by} and {cmd:svy} are not allowed; see {help prefix}.{p_end}
{p 4 6 2}
{opt weight}s are ignored and waring is issued if {opt weight}s are specified; see {help weight}.{p_end}
{p 4 6 2}The available postestimation commands are (almost) the same as for {cmd:truncreg}; see
{help truncreg_postestimation :truncreg postestimation}.{p_end}


{title:Description}

{pstd}
{cmd:ftruncreg} is a speedier substitute for {cmd:truncreg} that uses the same syntax.
{cmd:ftruncreg} makes full use of Mata’s optimization routines and, for this reason, estimates the truncated regression model (Hausman and Wise, 1977) much faster than {cmd:truncreg}.
The gain in run time is indeed substantial.
For instance, for estimating the first example from {help truncreg##examples :truncreg examples}, {cmd:ftruncreg} on average requires roughly one-sixth of the computing time of {cmd:truncreg}.
The price for the gain in speed is a reduced set of available options and features.
{cmd:ftruncreg} is hence preferable to {cmd:truncreg} if computing time is a scarce resource.
{cmd:ftruncreg} uses a modified Newton-Raphson algorithm for optimization,
which is the quickest if the likelihood function excludes local maxima as is the case for the likelihood function of the truncated regression model (Orme, 1989); see {help mf_optimize##i_technique:mf_optimize}.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang} {opt noconstant} makes {cmd:ftruncreg} suppress the constant terms in the truncated regression.

{phang} {opt ll(#)} and {opt ul(#)} specify the lower and upper limits for truncation, respectively.
One or both may be specified.
Only real scalars are allowed, but no variables.
That is, unlike {cmd:truncreg}, {cmd:ftruncreg} does not accommodate truncation limits that vary across observations.
{opt ll(#)} and/or {opt ul(#)} needs to be specified.

{dlgtab:SE/Inference}

{phang} {opt vce(vcetype)} specifies the method {cmd:ftruncreg} uses for variance-covariance estimation.
The default is {opt vce(oim)}; thus by default {cmd:ftruncreg} uses {opt optimize_result_V_oim(S)} and returns {it:invsym(-H)}, which is the variance matrix obtained from the observed information matrix.
With {opt vce(opg)} {cmd:ftruncreg} uses {opt optimize_result_V_opg(S)} and returns {it:invsym(S'S)}, which is the variance matrix obtained from the outer product of the gradient vector;
{it:S} denotes the matrix of scores.
With {opt vce(robust)} {cmd:ftruncreg} uses {opt optimize_result_V_robust(S)} and returns  {it:invsym(-H)*(S'S)*invsym(-H)}, which is the sandwich estimator of the variance matrix.
For more details see {help mf_optimize##r_v:mf_optimize}.

{phang} {opt robust} is fully equivalent to {opt vce(robust)}.

{dlgtab:Reporting}

{phang} {opt level(#)}; see {helpb estimation options##level():[R] estimation options}. One may change the reported confidence level by retyping
{cmd:ftruncreg} without arguments and only specifying the option {opt level(#)}.

{phang} {opt nolog} prevents {cmd:ftruncreg} from displaying any output on the screen.

{phang} For further {it:display_options}, see {helpb estimation options##display_options:[R] estimation options}.


{title:Example} (see {help truncreg##examples :truncreg examples})

{pstd}Load data{p_end}
{phang2}{cmd:. webuse laborsub}{p_end}

{pstd}Truncated regression with left-truncation at zero{p_end}
{phang2}{cmd:. ftruncreg whrs kl6 k618 wa we, ll(0)}{p_end}

{pstd}Truncated regression with left-truncation at zero and robust standard errors{p_end}
{phang2}{cmd:. ftruncreg whrs kl6 k618 wa we, ll(0) r}{p_end}

{pstd}Truncated regression with left-truncation at zero and right-truncation at 200{p_end}
{phang2}{cmd:. ftruncreg whrs kl6 k618 wa we, ll(0) ul(200)}{p_end}


{title:Saved results}

{pstd}
{cmd:ftruncreg} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(converged)}}{opt 1} if converged, {opt 0} otherwise{p_end}
{synopt:{cmd:e(k_eq)}}number of equations in {opt e(b)}{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(sigma)}}estimate of sigma{p_end}
{synopt:{cmd:e(ll)}}log-likelihood value{p_end}
{synopt:{cmd:e(ic)}}number of iterations{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synoptset 20 tabbed}{...} {p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(cmd)}}{cmd:ftruncreg}{p_end}
{synopt:{cmd:e(depvar)}}name of {it:depvar}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {opt predict}{p_end}
{synopt:{cmd:e(marginsok)}}predictions allowed by {opt margins}{p_end}
{synopt:{cmd:e(properties)}}{opt b V}{p_end}
{synopt:{cmd:e(vce)}}either {opt oim} or {opt opg} or {opt robust}{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:Robust} if {opt e(vce)} : "robust"{p_end}
{synoptset 20 tabbed}{...} {p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}vector of estimated coefficients{p_end}
{synopt:{cmd:e(V)}}estimated variance-covariance matrix{p_end}

{synoptset 20 tabbed}{...}{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{title:References}

{pstd} Hausman, J. and Wise, D. (1977). Social experimentation, truncated distributions, and efficient estimation. {it:Econometrica} 45(4), 919-938.

{pstd} Orme, C. (1989). On the uniqueness of the maximum likelihood estimator in truncated regression models. {it:Econometric Reviews} 8(2), 217-222.


{title:Also see}

{psee} Manual:  {manlink R truncreg}, {manlink M-5 optimize()}

{psee} {space 2}Help:  {manhelp truncreg R:truncreg}, {manhelp mf_optimize M-5:optimize()}{break}

{psee} Online:  {helpb simarwilson :simarwilson}{p_end}


{title:Authors}

{psee} Oleg Badunenko{p_end}{psee} Brunel University{p_end}{psee} London,
UK{p_end}{psee}E-mail: oleg.badunenko@brunel.ac.uk {p_end}

{psee} Harald Tauchmann{p_end}{psee} Friedrich-Alexander-Universit{c a:}t Erlangen-N{c u:}rnberg (FAU){p_end}{psee} N{c u:}rnberg,
Germany{p_end}{psee}E-mail: harald.tauchmann@fau.de {p_end}


{title:Disclaimer}

{pstd} This software is provided "as is" without warranty of any kind, either expressed or implied. The entire risk as to the quality and
performance of the program is with you. Should the program prove defective, you assume the cost of all necessary servicing, repair or
correction. In no event will the copyright holders or their employers, or any other party who may modify and/or redistribute this software,
be liable to you for damages, including any general, special, incidental or consequential damages arising out of the use or inability to
use the program.{p_end}


{title:Acknowledgements}

{pstd} We would like to thank Joseph Newton and one anonymous referee for pointing us the run time issue when bootstrapping the truncated regression model using Stata.{p_end}

{pstd} {p_end}
