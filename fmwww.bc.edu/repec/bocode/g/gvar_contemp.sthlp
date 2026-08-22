{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar estimate" "help gvar_estimate"}{...}
{vieweralsosee "gvar wetest" "help gvar_wetest"}{...}
{viewerjumpto "Syntax" "gvar_contemp##syntax"}{...}
{viewerjumpto "Description" "gvar_contemp##description"}{...}
{viewerjumpto "Remarks" "gvar_contemp##remarks"}{...}
{viewerjumpto "Examples" "gvar_contemp##examples"}{...}
{viewerjumpto "Stored results" "gvar_contemp##results"}{...}
{viewerjumpto "Options" "gvar_contemp##options"}{...}
{title:Title}

{phang}
{bf:gvar contemp} {hline 2} contemporaneous effects of the foreign variables


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar contemp} [{cmd:,} {opt vce(string)} {opt all} {opt nosum:mary} {opt saving(name)}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt vce(string)}}{cmd:ols}, {cmd:robust} or {cmd:nwest}. Default {cmd:nwest}.{p_end}
{synopt:{opt all}}report every element of {it:Lambda_0}, not only the matching pairs.{p_end}
{synopt:{opt nosum:mary}}suppress the table.{p_end}
{synopt:{opt saving(name)}}save the results matrix.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar contemp} reports the elements of {it:Lambda_0} whose domestic and
foreign variable names coincide: the impact elasticity of each domestic
variable with respect to its own foreign counterpart. These are the
coefficients on {it:D x*} in the VECMX*, with t-ratios beneath.


{marker options}{...}
{title:Options}

{phang}
{opt vce(string)} the standard errors for the contemporaneous coefficients:
OLS, White or Newey-West.

{phang}
{opt all} reports every (unit, variable) pair rather than the summary.

{phang}
{opt level(#)} the confidence level for the reported interval.

{phang}
{opt graph}, {opt name()}, {opt saving()} and {opt nosummary} as elsewhere.

{pmore}
These elasticities are the {it:Lambda_0} block -- the impact of the foreign
variable on its domestic counterpart within the period. They are the most directly
interpretable numbers in a GVAR and are quoted routinely, which is why the
standard-error choice is exposed here: with {it:T} = 134 the difference between
OLS and Newey-West is not always cosmetic.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:How to read them.} These are impact elasticities. A value near one means
the domestic variable moves one for one with its foreign counterpart on
impact, which is strong contemporaneous international transmission. Dees, di
Mauro, Pesaran and Smith (2007, Table 6) is the standard comparison.

{pstd}
{bf:A dot means the pair does not exist,} either because the unit does not own
that domestic variable or because its foreign counterpart is not in the
model. Only variables appearing on both sides have a contemporaneous
coefficient; in the demo that is 105 pairs.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar contemp}
        {cmd:. gvar contemp, vce(robust)}
        {cmd:. gvar contemp, all saving(L0)}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar contemp} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(contemp)}}the coefficients and three sets of standard errors{p_end}
{synopt:{cmd:r(vce)}}the standard-error type reported{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:contmpcoeff.m}; White errors from the {it:mlcoint.m} HCW block,
Newey-West from {it:neweywest.m}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
