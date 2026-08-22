{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar weights" "help gvar_weights"}{...}
{vieweralsosee "gvar foreign" "help gvar_foreign"}{...}
{vieweralsosee "gvar describe" "help gvar_describe"}{...}
{vieweralsosee "gvar datasets" "help gvar_datasets"}{...}
{vieweralsosee "gvar dominant" "help gvar_dominant"}{...}
{vieweralsosee "gvar import" "help gvar_import"}{...}
{viewerjumpto "Syntax" "gvar_setup##syntax"}{...}
{viewerjumpto "Description" "gvar_setup##description"}{...}
{viewerjumpto "Remarks" "gvar_setup##remarks"}{...}
{viewerjumpto "Examples" "gvar_setup##examples"}{...}
{viewerjumpto "Stored results" "gvar_setup##results"}{...}
{viewerjumpto "Options" "gvar_setup##options"}{...}
{title:Title}

{phang}
{bf:gvar setup} {hline 2} declare the panel and the model specification


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar setup} {varlist} {ifin} {cmd:,} {opt unit(varname)} {opt time(varname)} [{it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt u:nit(varname)}}the cross-section identifier. Required.{p_end}
{synopt:{opt t:ime(varname)}}the time identifier. Required.{p_end}
{synopt:{opth glo:bal(varlist)}}variables common to every unit, such as commodity prices.{p_end}
{synopt:{opt gend:og(spec)}}make a global variable endogenous to one unit, as {cmd:gendog(poil=usa)}. This is the Dees-di Mauro-Pesaran-Smith device of attaching the oil price to the United States.{p_end}
{synopt:{opt for:eign(spec)}}override which variables enter a unit's foreign block.{p_end}
{synopt:{opt nofor:eign(spec)}}suppress the foreign counterpart of a variable.{p_end}
{synopt:{opt exc:lude(spec)}}drop a variable from a unit's domestic block.{p_end}
{synopt:{opt cas:e(spec)}}deterministic case 2, 3 or 4, globally or per unit.{p_end}
{synopt:{opt wt:ype(spec)}}which weight matrix each variable uses.{p_end}
{synopt:{opt psc(#)}}order of the serial-correlation F test carried through to {helpb gvar_diag:gvar diag}. Default {cmd:psc(4)}.{p_end}
{synopt:{opt spec(filename)}}read the whole specification grid from a dataset.{p_end}
{synopt:{opt nosum:mary}}suppress the report.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar setup} reads a balanced long panel and declares which variable
belongs to which unit, which variables are global, and how each country model
is specified. Nothing else in the package works until it has run.

{pstd}
A variable that is entirely missing for a unit is treated as {bf:absent} for
that unit, exactly as the Toolbox's {it:dvflag} does. Missing is the encoding
for "this unit does not have this series", not a gap to be filled. The command
reports which series are absent and which are only partially observed, so a
data problem cannot pass silently as a specification.


{marker options}{...}
{title:Options}

{phang}
{opt unit(varname)} and {opt time(varname)} identify the panel. If both are
omitted the data must already be {helpb xtset}, and the {cmd:xtset} identifiers
are used. {it:unit} may be a string, a numeric with a value label, or a plain
numeric; the unit names in every later table come from whichever it is, so a
labelled numeric or a string gives readable output and a bare numeric gives
integers.

{phang}
{opt global(varlist)} names variables that are common to every unit -- an oil
price, a commodity index. They are not any one country's variables and are
carried once rather than per unit.

{phang}
{opt gendog(spec)} attaches a global variable to one unit's block as an
{bf:endogenous} variable, as {it:var=unit}, e.g. {cmd:gendog(poil=usa)}. That
gives the oil price the US model's dynamics and puts a US-specific shock on it.
Contrast {opt dominant()}.

{phang}
{opt dominant(varlist)} instead gives the global variables {bf:their own block},
estimated by {helpb gvar_dominant:gvar dominant}. Use this when the variable is
nobody's domestic variable: it then has its own dynamics and its own shock, and
feeds back from the world with a lag rather than being driven by one country
contemporaneously. The two options answer the same question differently and
should not be used for the same variable.

{phang}
{opt foreign(spec)} and {opt noforeign(spec)} control which domestic variables
get a foreign-specific counterpart. By default every domestic variable does.
{opt noforeign()} is how you say that a variable has no meaningful {it:star}
version for a unit -- and it changes the model, since a star variable that
should not be there is a weakly exogenous regressor that does not belong.

{phang}
{opt exclude(spec)} drops individual (unit, variable) pairs from the model, for
the case where a country genuinely does not have a series. Note that a
{bf:missing} series already encodes this: {cmd:gvar setup} does not mark out
observations on the domestic varlist, because doing so would delete the whole
unit. Use {opt exclude()} when the data are present but should not be used.

{phang}
{opt case(spec)} sets the deterministic specification, 2, 3 or 4 in
Pesaran-Shin-Smith's numbering, either globally or per unit. Case 4 -- restricted
trend -- is the default and the Toolbox's. This choice propagates: it sets the
critical values {helpb gvar_coint:gvar coint} uses and the deterministic terms
recovered by {helpb gvar_estimate:gvar estimate}.

{phang}
{opt wtype(#)} selects which of the weight types loaded by
{helpb gvar_weights:gvar weights} builds the star variables, when more than one
is available.

{phang}
{opt psc(#)} is the number of principal components used in the cross-section
augmentation. Default 4.

{phang}
{opt spec(filename)} reads the per-unit lag orders, ranks and deterministic
cases from a dataset instead of setting them by hand -- which is how the shipped
{cmd:gvar_demospec} reproduces the Toolbox's published specification exactly.
{helpb gvar_datasets:gvar datasets} describes its layout.

{phang}
{opt nosummary} suppresses the report. {bf:Read it at least once per dataset.}
It is where partially observed series are named, and a series that is present for
only part of the window is dropped from its unit -- which changes the model
silently if you never look.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:On spec().} The grid is one row per unit and variable with columns
{cmd:dv}, {cmd:fv}, {cmd:gv}, {cmd:p}, {cmd:q}, {cmd:case} and {cmd:rank}. It
fixes, per unit, which variables are endogenous, which have foreign
counterparts, the lag orders, the deterministic case and the cointegrating
rank. This is the equivalent of the Toolbox's interface workbook and the only
reliable way to reproduce a published model: without it, ranks come from
{helpb gvar_coint:gvar coint} and lag orders from
{helpb gvar_lags:gvar lags}, which will not in general agree with someone
else's choices.

{pstd}
{bf:Read the report before continuing.} It lists each unit's domestic block,
weakly exogenous block and lag orders. An unexpected blank almost always means
a variable name did not match, not that the unit lacks the series. The counts
of absent and partially observed series at the foot are there for the same
reason.

{pstd}
{bf:On the sample.} Only the unit and time identifiers are used to define the
estimation sample. Casewise deletion on the domestic variables would drop
whole units, because in a GVAR a missing series is a specification fact
rather than a missing observation.


{marker examples}{...}
{title:Examples}

        {cmd:. use gvar_demo26}
        {cmd:. gvar setup y Dp eq ep r lr, unit(country) time(quarter) ///}
                {cmd:global(poil pmat pmetal) gendog(poil=usa pmat=usa pmetal=usa) ///}
                {cmd:spec(gvar_demospec.dta)}

{pstd}
Without a grid, giving every unit case 3:

        {cmd:. gvar setup y Dp r, unit(country) time(quarter) case(3)}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar setup} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(N)}}units{p_end}
{synopt:{cmd:r(K)}}total endogenous variables in x(t){p_end}
{synopt:{cmd:r(T)}}periods{p_end}
{synopt:{cmd:r(V)}}distinct domestic variables{p_end}
{synopt:{cmd:r(G)}}global variables{p_end}
{synopt:{cmd:r(units)}}unit names{p_end}
{synopt:{cmd:r(domestic)}}domestic variable names{p_end}
{synopt:{cmd:r(global)}}global variable names{p_end}
{synopt:{cmd:r(unitvar)}}the unit identifier{p_end}
{synopt:{cmd:r(timevar)}}the time identifier{p_end}
{synopt:{cmd:r(absent)}}series absent for at least one unit{p_end}
{synopt:{cmd:r(partial)}}series only partially observed{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:gvar.m} data-loading block; the {it:dvflag}, {it:fvflag} and
{it:gvflag} grid.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
