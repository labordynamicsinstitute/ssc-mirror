{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar datasets" "help gvar_datasets"}{...}
{vieweralsosee "gvar setup" "help gvar_setup"}{...}
{vieweralsosee "gvar weights" "help gvar_weights"}{...}
{viewerjumpto "Syntax" "gvar_getdata##syntax"}{...}
{viewerjumpto "Description" "gvar_getdata##description"}{...}
{viewerjumpto "Options" "gvar_getdata##options"}{...}
{viewerjumpto "Why the data is separate" "gvar_getdata##why"}{...}
{viewerjumpto "Examples" "gvar_getdata##examples"}{...}
{viewerjumpto "Stored results" "gvar_getdata##results"}{...}
{title:Title}

{phang}
{bf:gvar getdata} {hline 2} fetch the example datasets, which ship separately


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar getdata} [{it:group}] {cmd:,} {opt from(ssc|net)} {opt pkg(string)} [{it:options}]

{pstd}
{it:group} is {cmd:demo} (the default), {cmd:extra}, {cmd:weights}, {cmd:all},
or an explicit list of dataset names.

{synoptset 26 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt from(ssc|net)}}where to fetch from. Required.{p_end}
{synopt:{opt pkg(string)}}the SSC package name, or the URL for {cmd:from(net)}. Required.{p_end}
{synopt:{opt dir(path)}}where to put the files. Default: the current directory.{p_end}
{synopt:{opt list}}show the dataset names and groups, fetch nothing.{p_end}
{synopt:{opt replace}}overwrite files already present. Default: keep them.{p_end}
{synopt:{opt nosum:mary}}suppress the report.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar getdata} downloads the example datasets. They are {bf:not} installed
with the package, so this is how you get them.

{pstd}
Four are all the documented examples need:

{p 8 8 2}{cmd:gvar_demo26.dta}{space 4}the demo panel, 26 economies, 1979Q2-2013Q1{p_end}
{p 8 8 2}{cmd:gvar_flows.dta}{space 5}bilateral trade flows{p_end}
{p 8 8 2}{cmd:gvar_demospec.dta}{space 2}the specification grid{p_end}
{p 8 8 2}{cmd:gvar_demoagg.dta}{space 3}the euro-area crosswalk{p_end}

{pstd}
{cmd:gvar getdata, list} shows the rest: an unaggregated 33-country panel, a
regional crosswalk, effective exchange rates, an alternative panel, price
volatility series, and fifteen alternative link-weight matrices.


{marker options}{...}
{title:Options}

{phang}
{opt from(ssc|net)} names the mechanism. {cmd:ssc} uses {helpb ssc:ssc copy};
{cmd:net} uses {helpb net:net get} against a URL. There is {bf:no default}:
choosing a download source on your behalf is not this command's business.

{phang}
{opt pkg(string)} is the SSC package holding the datasets, or the URL with
{opt from(net)}. Also required, for the same reason.

{phang}
{opt dir(path)} sets the destination, created if absent. Whatever you choose
must be somewhere {helpb use} can find, or pass the full path to {cmd:use}.

{phang}
{opt replace} overwrites. Without it a file already present is kept and
reported as kept -- you may have edited a local copy, and this command should
not destroy it silently.

{pmore}
A fetch that fails reports the return code per file and says plainly that the
problem is with the {bf:source}, not with your installation, together with the
command to inspect that source. A download failure and a broken install need
different fixes and should not produce the same message.


{marker why}{...}
{title:Why the data is separate}

{pstd}
The SSC Archive caps a package description at {bf:100 lines}. Listing 26
datasets as {cmd:f} lines put this package at 114, and it was refused.

{pstd}
Kit Baum, who maintains the archive, gave the remedy: keep the data out of the
package and fetch it with one command --

{pmore}
{it:"if the .dta files could be installed from a single command, those files can
be available from SSC using ssc copy commands, so you would just need a single
ado that invokes ssc copy commands for each of the ... datasets"}

{pstd}
That is this command. {bf:Nothing was dropped from the project}: every dataset
the documentation mentions is still available. It arrives when you ask for it
instead of at install time.

{pstd}
The alternative -- deleting the data -- would have made the documented examples
unrunnable, and that is not a trade worth making to save lines in a
description file.

{pstd}
The 648 Pesaran-Shin-Smith cointegration critical values went the other way.
They used to ship as {cmd:gvar_cv.dta} and {helpb gvar_coint:gvar coint} read
them with {helpb findfile}, refusing with {bf:r(601)} if the file was missing.
They are {bf:constants}, so they now live in the Mata engine.
{cmd:gvar coint} needs no data file at all, and this command does not fetch
them because there is nothing to fetch.


{marker examples}{...}
{title:Examples}

{pstd}
See what there is:{p_end}
{phang2}{cmd:. gvar getdata, list}{p_end}

{pstd}
The four the examples use, from a companion SSC package:{p_end}
{phang2}{cmd:. gvar getdata demo, from(ssc) pkg(gvardata)}{p_end}

{pstd}
Everything, into a folder of your choosing:{p_end}
{phang2}{cmd:. gvar getdata all, from(ssc) pkg(gvardata) dir(C:/mydata)}{p_end}

{pstd}
Two named datasets, overwriting local copies:{p_end}
{phang2}{cmd:. gvar getdata gvar_demo26 gvar_flows, from(ssc) pkg(gvardata) replace}{p_end}

{pstd}
Then the worked analysis in {bf:net get gvar} runs.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar getdata} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(got)}}files fetched{p_end}
{synopt:{cmd:r(skipped)}}files already present and kept{p_end}
{synopt:{cmd:r(nfail)}}files not fetched{p_end}
{synopt:{cmd:r(files)}}the names requested{p_end}
{synopt:{cmd:r(failed)}}the names that failed{p_end}
{synoptline}

{pstd}
With {opt list}: {cmd:r(demo)}, {cmd:r(extra)}, {cmd:r(weights)}, {cmd:r(all)}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
