{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar estimate" "help gvar_estimate"}{...}
{vieweralsosee "gvar irf" "help gvar_irf"}{...}
{vieweralsosee "gvar describe" "help gvar_describe"}{...}
{vieweralsosee "gvar bayes" "help gvar_bayes"}{...}
{viewerjumpto "Syntax" "gvar_solve##syntax"}{...}
{viewerjumpto "Description" "gvar_solve##description"}{...}
{viewerjumpto "Remarks" "gvar_solve##remarks"}{...}
{viewerjumpto "Examples" "gvar_solve##examples"}{...}
{viewerjumpto "Stored results" "gvar_solve##results"}{...}
{viewerjumpto "Options" "gvar_solve##options"}{...}
{title:Title}

{phang}
{bf:gvar solve} {hline 2} stack the country models and solve the GVAR


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar solve} [{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt tol:erance(#)}}tolerance for calling an eigenvalue a unit root. Default 1e-6.{p_end}
{synopt:{opt gr:aph}}plot the eigenvalue moduli.{p_end}
{synopt:{opt name(name)}}graph name.{p_end}
{synopt:{opt neigen(#)}}how many eigenvalues to list. Default 20.{p_end}
{synopt:{opt nosum:mary}}suppress the report.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar solve} builds {it:G0} and {it:H_l} from the country models through
the link matrices, inverts {it:G0} to obtain the reduced form
{it:x_t = d0 + d1 t + sum_l F_l x(t-l) + eta_t}, and reports the eigenvalues
of the companion matrix.

{pstd}
Nothing in the dynamic-analysis group works until this has run.


{marker options}{...}
{title:Options}

{phang}
{opt tolerance(#)} is how close to one an eigenvalue modulus must be before it
counts as a unit root. Default {cmd:1e-6}.

{pmore}
It matters more than it looks. The unit-root count is compared against
{it:K - sum(r_i)} as a specification check, so a tolerance that is too tight
splits a root that is genuinely at one into "just below" and reports a spurious
mismatch; too loose and it absorbs a root that is really at 0.999 and hides a
real one. If the reported count sits one or two away from the expected number,
vary this before concluding anything about the ranks.

{phang}
{opt graph} plots the eigenvalue moduli in descending order with a reference
line at one, which is the quickest way to see whether the model is marginally or
badly unstable -- a single modulus at 1.02 is a different problem from a dozen.

{phang}
{opt name(name)} names the graph, so a loop over specifications does not
overwrite its own output.

{phang}
{opt neigen(#)} how many of the largest moduli to list. Default 20. The
companion matrix has {it:K x pmax} eigenvalues -- 408 on the shipped demo,
whose dominant unit raises pmax to 3 -- so
listing them all is rarely useful; the largest are where the information is.

{phang}
{opt nosummary} suppresses the report but still solves the model and still fills
{cmd:r()}. Use it inside loops. Note it also suppresses the instability warning,
so check {cmd:r(stable)} yourself when running quietly.


{marker examples}{...}
{title:Examples}

{pstd}
The ordinary case, after {helpb gvar_estimate:gvar estimate}:{p_end}
{phang2}{cmd:. gvar solve}{p_end}

{pstd}
With the eigenvalue plot, and a looser unit-root tolerance because the count
came back one short:{p_end}
{phang2}{cmd:. gvar solve, graph tolerance(1e-4)}{p_end}

{pstd}
Quietly, inside a loop over cointegrating ranks, checking stability
programmatically:{p_end}
{phang2}{cmd:. gvar solve, nosummary}{p_end}
{phang2}{cmd:. if (r(stable) == 0) display as error "rank set `r' is explosive"}{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:The stability check is a specification test, not a formality.} A GVAR
with {it:K} variables and {it:sum r_i} cointegrating relations must have
exactly {it:K - sum r_i} eigenvalues on the unit circle. The command counts
them and compares. A mismatch means the ranks and the dynamics disagree, and
the usual cause is an overstated rank somewhere.

{pstd}
Any eigenvalue modulus above one is explosive and makes every impulse
response meaningless. The command says so rather than proceeding quietly.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar solve} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(eigen)}}the eigenvalue moduli{p_end}
{synopt:{cmd:r(maxmod)}}the largest modulus{p_end}
{synopt:{cmd:r(nunit)}}eigenvalues at one{p_end}
{synopt:{cmd:r(nexpl)}}eigenvalues above one{p_end}
{synopt:{cmd:r(expected)}}K minus the total rank{p_end}
{synopt:{cmd:r(K)}}endogenous variables{p_end}
{synopt:{cmd:r(pmax)}}the GVAR lag order{p_end}
{synopt:{cmd:r(stable)}}1 if no explosive root{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:solve_GVAR.m}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
