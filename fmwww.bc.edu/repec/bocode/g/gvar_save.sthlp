{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar use" "help gvar_use"}{...}
{vieweralsosee "gvar clear" "help gvar_clear"}{...}
{vieweralsosee "gvar describe" "help gvar_describe"}{...}
{vieweralsosee "gvar estimate" "help gvar_estimate"}{...}
{viewerjumpto "Syntax" "gvar_save##syntax"}{...}
{viewerjumpto "Description" "gvar_save##description"}{...}
{viewerjumpto "Remarks" "gvar_save##remarks"}{...}
{viewerjumpto "Examples" "gvar_save##examples"}{...}
{viewerjumpto "Stored results" "gvar_save##results"}{...}
{viewerjumpto "Options" "gvar_save##options"}{...}
{title:Title}

{phang}
{bf:gvar save} {hline 2} write the fitted GVAR to disk


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar save} {it:filename} [{cmd:,} {opt replace} {opt nosum:mary}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt replace}}overwrite {it:filename} if it exists.{p_end}
{synopt:{opt nosum:mary}}suppress the confirmation line.{p_end}
{synoptline}

{pstd}
If {it:filename} has no suffix, {cmd:.gvar} is added.


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar save} writes everything the package holds about the current model to
a single file: the panel it was built from, the weight matrices, every
country-model estimate, the residuals, the stacked system and the reduced
form. {helpb gvar_use:gvar use} reads it back.

{pstd}
The point is that estimating, solving and bootstrapping a model of realistic
size takes minutes. Do it once, save, and every later session starts from the
solved model.


{marker options}{...}
{title:Options}

{phang}
{it:filename} is required. The extension {cmd:.gvar} is added if none is given.

{phang}
{opt replace} overwrites an existing file. Without it, an existing file is an
error rather than being silently replaced -- a saved model represents a
specification that took work to arrive at.

{phang}
{opt nosummary} suppresses the report.

{pmore}
What is saved is the {bf:model}, not the data: the specification, the weights, the
estimates and whatever has been solved. Reload it with
{helpb gvar_use:gvar use}. The dataset is not stored with it, so keep the two
together if any command you plan to run afterwards writes variables back.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:The file is self-contained.} It carries its own copies of the data, so
after {cmd:gvar use} you can run {helpb gvar_irf:gvar irf},
{helpb gvar_fevd:gvar fevd}, {helpb gvar_spillover:gvar spillover} and the
rest with {bf:no dataset in memory at all}. Nothing in the dynamic analysis
reads the panel; it all reads the stored model. The exception is
{helpb gvar_setup:gvar setup} itself, which starts a new model rather than
using a saved one.

{pstd}
{bf:Save at whatever stage you have reached.} A model that is set up but not
estimated saves and restores just as well as a solved one;
{cmd:gvar use} reports which stage it found and tells you what to run next.

{pstd}
{bf:Version.} The file is a serialised Mata structure, so it can only be read
by a version of the package whose structure definition matches. If the package
is upgraded in a way that changes the structure, {cmd:gvar use} refuses with a
clear message rather than restoring something half-formed, and you re-estimate
and save again. For long-lived work keep the do-file that built the model, not
only the {cmd:.gvar} file.

{pstd}
{bf:Size.} The dominant term is the residual matrix and the stacked system, so
the file grows roughly with {it:K}^2. The 26-unit demo model is a few
megabytes.


{marker examples}{...}
{title:Examples}

{pstd}Fit once{p_end}
        {cmd:. use gvar_demo26, clear}
        {cmd:. gvar setup y Dp eq ep r lr, unit(country) time(quarter) global(poil pmat pmetal) gendog(poil=usa pmat=usa pmetal=usa) spec(gvar_demospec.dta)}
        {cmd:. gvar weights using gvar_flows.dta, flow(trade) source(partner) destination(home) year(year) years(2009 2011) type(1) map(gvar_demoagg.dta)}
        {cmd:. gvar foreign}
        {cmd:. gvar estimate}
        {cmd:. gvar solve}
        {cmd:. gvar save demo_fitted, replace}

{pstd}Analyse later, with no data in memory{p_end}
        {cmd:. clear all}
        {cmd:. gvar use demo_fitted}
        {cmd:. gvar irf, shock(usa:r) response(*:y) step(24) reps(200) shuffle}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar save} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(filename)}}the file written{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Utility command. There is no counterpart in the reference implementations:
GVAR Toolbox 2.0 persists its state in the MATLAB workspace, and the R
packages in the returned object.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
