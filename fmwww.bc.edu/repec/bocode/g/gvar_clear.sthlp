{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar save" "help gvar_save"}{...}
{vieweralsosee "gvar use" "help gvar_use"}{...}
{vieweralsosee "gvar setup" "help gvar_setup"}{...}
{viewerjumpto "Syntax" "gvar_clear##syntax"}{...}
{viewerjumpto "Description" "gvar_clear##description"}{...}
{viewerjumpto "Remarks" "gvar_clear##remarks"}{...}
{viewerjumpto "Examples" "gvar_clear##examples"}{...}
{viewerjumpto "Options" "gvar_clear##options"}{...}
{title:Title}

{phang}
{bf:gvar clear} {hline 2} drop the GVAR from memory


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar clear} [{cmd:,} {opt nosum:mary}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar clear} drops the fitted model. It leaves the compiled Mata engine in
place, so the next {helpb gvar_setup:gvar setup} starts immediately instead of
recompiling.

{pstd}
It is not an error to run it when there is no model; it says so and exits.


{marker options}{...}
{title:Options}

{pstd}
{cmd:gvar clear} takes no options. It drops the model from Mata memory and leaves
the data alone.

{pstd}
Use it rather than {helpb clear:clear all} between specifications in a do-file.
{cmd:clear all} also drops every program and Mata function defined in the
session, which in a test file means the reporting programs vanish and the run
dies with "command not recognized" several lines later.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:There is no undo.} If the model took minutes to fit, run
{helpb gvar_save:gvar save} first.

{pstd}
{bf:You rarely need it.} {helpb gvar_setup:gvar setup} replaces any existing
model, so the ordinary way to start again is simply to set up again. Use
{cmd:gvar clear} when you want to free the memory, when you are about to
{helpb gvar_use:gvar use} a saved model, or when you want a later
{cmd:gvar} subcommand to fail loudly rather than quietly report results from a
model you had forgotten was there.

{pstd}
{bf:How this relates to Stata's own clearing commands.}

{synoptset 18 tabbed}{...}
{synopt:{cmd:gvar clear}}drops the model, keeps the engine.{p_end}
{synopt:{cmd:clear all}}drops both, and everything else.{p_end}
{synopt:{cmd:discard}}drops {bf:neither}. Interactively compiled Mata survives
{cmd:discard}, which is worth knowing when you are editing the package
yourself: after changing a Mata function you must {cmd:clear all}, not
{cmd:discard}, or you will keep running the old code.{p_end}
{synoptline}


{marker examples}{...}
{title:Examples}

        {cmd:. gvar clear}

{pstd}Save, drop, restore{p_end}
        {cmd:. gvar save demo_fitted, replace}
        {cmd:. gvar clear}
        {cmd:. gvar use demo_fitted}


{marker source}{...}
{title:Source}

{pstd}
Utility command; see {helpb gvar_save:gvar save}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
