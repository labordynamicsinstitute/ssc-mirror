{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar weights" "help gvar_weights"}{...}
{vieweralsosee "gvar setup" "help gvar_setup"}{...}
{vieweralsosee "gvar avgcorr" "help gvar_avgcorr"}{...}
{vieweralsosee "gvar estimate" "help gvar_estimate"}{...}
{viewerjumpto "Syntax" "gvar_foreign##syntax"}{...}
{viewerjumpto "Description" "gvar_foreign##description"}{...}
{viewerjumpto "Remarks" "gvar_foreign##remarks"}{...}
{viewerjumpto "Examples" "gvar_foreign##examples"}{...}
{viewerjumpto "Stored results" "gvar_foreign##results"}{...}
{viewerjumpto "Options" "gvar_foreign##options"}{...}
{title:Title}

{phang}
{bf:gvar foreign} {hline 2} build the foreign-specific variables


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar foreign} [{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt gen:erate}}write the foreign variables into the dataset.{p_end}
{synopt:{opt pre:fix(name)}}prefix for the generated names.{p_end}
{synopt:{opt suf:fix(name)}}suffix for the generated names. Default {cmd:_star}.{p_end}
{synopt:{opt replace}}overwrite existing variables.{p_end}
{synopt:{opt list}}list each unit's foreign block.{p_end}
{synopt:{opt nosum:mary}}suppress the report.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar foreign} constructs {it:x*_it = W_i x_t}, the weighted average of
the other units' variables that each country model treats as weakly
exogenous. It runs after {helpb gvar_weights:gvar weights} and before
{helpb gvar_estimate:gvar estimate}.

{pstd}
The summary reports the modal specification and then every unit that departs
from it. That is usually a short list and is the quickest way to see whether
the model is specified as intended.


{marker options}{...}
{title:Options}

{phang}
{opt generate} writes the foreign-specific series into the dataset as new
variables, rather than keeping them only inside the model. Useful when you want
to plot {it:y*} against {it:y}, or feed a star variable to some other command.

{phang}
{opt prefix(name)} and {opt suffix(name)} name those variables. Without either,
the default naming is used; give one or the other when the default would collide
with something already in the data. Only one is needed -- a prefix {it:or} a
suffix -- and supplying both is allowed but usually makes the names unwieldy.

{phang}
{opt replace} overwrites existing variables of the same name. Without it a
collision is an error, which is the safer default: a silently overwritten
{it:y_star} from a previous specification is very hard to notice later.

{phang}
{opt list} prints the weight vector actually used for each unit. Read it once
per new dataset. It is the cheapest way to catch a weight matrix that is
transposed, mis-scaled, or missing a country -- all of which produce star
variables that look plausible and are wrong.

{phang}
{opt nosummary} suppresses the report.


{marker remarks}{...}
{title:Remarks}

{pstd}
A foreign variable is built only over the units that own the matching domestic
variable, with the weights renormalised over those units. A weakly exogenous
{it:global} variable, owned by no unit, gets an unweighted indicator row
instead of a weighted average.

{pstd}
{bf:Blanks downstream start here.} If a unit has no long rate it has no
{it:lr} and no {it:lr*} entry in any later table. In the shipped demo fourteen
units have a short domestic block and the United States, as numeraire, carries
no exchange rate and only three foreign variables. Those are specification
facts; {helpb gvar_describe:gvar describe, varlist} lists them explicitly.

{pstd}
{bf:What the foreign variables are for.} Including them is what soaks up the
cross-section dependence that would otherwise invalidate the country-by-country
estimation. {helpb gvar_avgcorr:gvar avgcorr} measures whether it worked: in
the demo the average pairwise correlation falls from 0.6514 in the levels to
0.0484 in the residuals.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar foreign}
        {cmd:. gvar foreign, generate suffix(_star)}
        {cmd:. gvar foreign, list}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar foreign} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(N)}}units{p_end}
{synopt:{cmd:r(K)}}endogenous variables{p_end}
{synopt:{cmd:r(T)}}periods{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:create_foreignvariables.m}, {it:create_linkmatrices.m}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
