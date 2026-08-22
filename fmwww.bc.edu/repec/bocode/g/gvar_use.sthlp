{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar save" "help gvar_save"}{...}
{vieweralsosee "gvar clear" "help gvar_clear"}{...}
{vieweralsosee "gvar describe" "help gvar_describe"}{...}
{viewerjumpto "Syntax" "gvar_use##syntax"}{...}
{viewerjumpto "Description" "gvar_use##description"}{...}
{viewerjumpto "Remarks" "gvar_use##remarks"}{...}
{viewerjumpto "Examples" "gvar_use##examples"}{...}
{viewerjumpto "Stored results" "gvar_use##results"}{...}
{viewerjumpto "Options" "gvar_use##options"}{...}
{title:Title}

{phang}
{bf:gvar use} {hline 2} read a fitted GVAR back from disk


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar use} {it:filename} [{cmd:,} {opt clear} {opt nosum:mary}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt clear}}replace a model already in memory.{p_end}
{synopt:{opt nosum:mary}}suppress the description of what was loaded.{p_end}
{synoptline}

{pstd}
If {it:filename} has no suffix, {cmd:.gvar} is added.


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar use} restores a model written by {helpb gvar_save:gvar save} and
reports its dimensions and how far through the workflow it had got. After it,
every post-estimation and dynamic-analysis subcommand behaves exactly as it
did in the session that saved the model.

{pstd}
It does not touch the dataset in memory, and it does not need one.


{marker options}{...}
{title:Options}

{phang}
{it:filename} is required. The extension {cmd:.gvar} is assumed if none is given.

{phang}
{opt clear} allows a model already in memory to be replaced. Without it, an
existing model is an error -- reading a file over a model you were still using is
not something to do silently.

{phang}
{opt nosummary} suppresses the report.

{pmore}
The Mata engine is compiled before the file is read, because restoring a saved
structure requires its type to be known first. That happens automatically; it is
mentioned only because it is why {cmd:gvar use} takes a moment on a cold session.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:It will not silently overwrite.} If a GVAR is already in memory,
{cmd:gvar use} stops with an error rather than replacing it, because losing an
unsaved model to a mistyped filename is expensive. Add {cmd:clear}, or run
{helpb gvar_clear:gvar clear} first.

{pstd}
{bf:The dataset in memory is irrelevant.} The restored model carries its own
copy of everything it needs. You can load the saved model over an unrelated
dataset, or over no dataset, and the results are identical to the ones the
original session produced -- bit for bit, not approximately.

{pstd}
{bf:If it refuses to load,} the file was written by a version of the package
whose internal structure differs from the installed one. Re-run the do-file
that estimated the model and save it again. This is the reason to keep that
do-file.


{marker examples}{...}
{title:Examples}

{pstd}Restore and carry on{p_end}
        {cmd:. clear all}
        {cmd:. gvar use demo_fitted}
        {cmd:. gvar describe}
        {cmd:. gvar irf, shock(usa:r) response(*:y) step(24)}

{pstd}Replace whatever is in memory{p_end}
        {cmd:. gvar use demo_fitted, clear}

{pstd}Loop over saved specifications{p_end}
        {cmd:. foreach f in base altweights longlags {c -(}}
        {cmd:.     gvar use `f', clear nosummary}
        {cmd:.     quietly gvar irf, shock(usa:r) response(euro:y) step(24) nosummary}
        {cmd:.     matrix R_`f' = r(irf)}
        {cmd:. {c )-}}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar use} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(N)}}units{p_end}
{synopt:{cmd:r(K)}}endogenous variables{p_end}
{synopt:{cmd:r(T)}}periods{p_end}
{synopt:{cmd:r(estimated)}}1 if the country models are estimated{p_end}
{synopt:{cmd:r(solved)}}1 if the GVAR is solved{p_end}
{synoptline}


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
