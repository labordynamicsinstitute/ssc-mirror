{smcl}
{* 13aug2009}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "usel" "usel"}{...}
{vieweralsosee "savel" "savel"}{...}
{vieweralsosee "findd" "finddata"}{...}
{vieweralsosee "collect" "collect"}{...}
INCLUDE help also_vlowy
{title:Title} 
 
{pstd}{bf:callst} {hline 2} Call StatTransfer from Stata

{title:Syntax}

{pmore}{cmdab:callst} [{it:{help path_el}}]  
[{cmd:,} {cmdab:d:estination(}{it:{help path_el}}{cmd:)} {opt c:onfig(SToptions)} ]

{title:Description}

{pstd}{cmd:callst} invokes StatTransfer to copy data to and from Stata data files (ie, extension {cmd:.dta}).

{pstd}In general, to get non-Stata data files into and out of Stata, it will be easier to use the commands that do that directly: {help usel}, {help savel}, {help collect}, {help finddata}.
But, to create a translation of a data file, this will usually be easier than opening up StatTransfer.

{pstd}The command's main parameter is the source, or data file {it:to be translated}. When the transfer is from an ODBC data source (and only then), no main parameter is supplied.

{pstd}For setting the default behavior of StatTransfer when used from Stata, see {bf:Remarks}, below.

{title:Options}

{phang}{cmdab:d:estination(}{it:{help path_el}}{cmd:)} specifies a pathname for the newly translated data.
If {opt d:estination()} is not specified, the new name and location will the the same as the original file, with only the extension changed. (Usually, that would be to {cmd:.dta})

{phang}{opt c:onfig(SToptions)} passes configuration information along to StatTransfer. There are six possible suboptions:

{phang2}{opt type(file-type)} specifies the format of the foreign data, whether source or destination.
This sub-option is only needed when the file extension is ambiguous (or misleading). {helpb callst##type:see below}

{phang2}{opt keep(varlist)} specifies variables from the orignating file to be kept. A Stata {varlist} should generally work; variables with odd characters should be single-quoted.

{phang2}{opt drop(varlist)} specifies variables from the orignating file to be dropped. A Stata {varlist} should generally work; variables with odd characters should be single-quoted.

{phang2}{opt where(expression)} is the equivalent of a Stata {bf:if} clause, specifying observations to keep. The format is slightly different. {helpb callst##where:see below}

{phang2}{opt set(setup-option)} passes along StatTransfer {cmd:SET} commands. Any number of {opt set()} sub-options may be included in {opt c:onfig()}. 
For example: {cmd:config(set(preserve-case Y) set(read-sas-fmts N))}.

{phang2}{opt copy(table/worksheet/cells/member)} specifies, for some file types, which part of the file to use. {helpb callst##piece:see below}

{title:Remarks}

{pstd}Seems that these remarks, if they ever existed, have been misplaced. In the meantime, see the StatTransfer docs.
