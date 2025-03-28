{smcl}
{* *! version 3.2 20250324}{...}
{hline}
{pstd}help file for {hi:repadolog}{p_end}
{hline}

{title:Title}

{phang}{bf:repadolog} - Outputs a report of what commands are installed in the PLUS folder
{p_end}

{title:Syntax}

{phang}{bf:repadolog} [{bf:using}] , [{bf:{ul:d}etail} {bf:{ul:s}ave} {bf:{ul:savep}ath}({it:string}) {bf:{ul:qui}etly}]
{p_end}

{synoptset 16}{...}
{p2coldent:{it:options}}Description{p_end}
{synoptline}
{synopt: {bf:{ul:d}etail}}Display one line per command instead of one line per package{p_end}
{synopt: {bf:{ul:s}ave}}Save the report in the current PLUS folder{p_end}
{synopt: {bf:{ul:savep}ath}({it:string})}Define a custom path for the report{p_end}
{synopt: {bf:{ul:qui}etly}}Do not display the report in the result window{p_end}
{synoptline}

{title:Description}

{pstd}{inp:repadolog} is a command that list what packages and commands are installed in the current PLUS folder together with meta data on these packages and commands. The meta data comes from the {it:stata.trk} which is what Stata use to keep track of which packages and which versions of these packages is installed in the current PLUS folder. This report can be used to get an inventory of installed commands. 
{p_end}

{pstd}Another, and perhaps more important, usage is as a reproducibility tool. This report can be shared to show exactly what commands and what version of them were installed on the computer that generated results intended to be reproducible.
{p_end}

{pstd}This command can be used independently, but it also fits very well with the command {inp:repado}. {inp:repado} allows a team to set up a project specific PLUS folder shared in the team such that everyone in the team (and anyone reproducing the results in the future) use the exact same version of community contributed commands. 
{p_end}

{title:Options}

{pstd}{bf:using} is used to use another {it:stata.trk} file than the one currently active. This is an advanced use case and this is expected to be rarely used. See the command {browse "https://worldbank.github.io/repkit/reference/repado.html":repado} for how to change which folder to use as the current PLUS folder and thereby change which is the current {it:stata.trk} file used.
{p_end}

{pstd}{bf:{ul:d}etail} generates a more detailed report. The default is to generate a report where each row represents a package where all commands in this package is listed in a column. When this option is used each row is a command. The same package meta data is included regardless if this option is used or not. However, command specific meta data is only included if this option is used.
{p_end}

{pstd}{bf:{ul:s}ave} is used to save the report generated in a CSV file to disk. Unless {inp:savepath()} is also used, the report is saved in the same location as the {it:stata.trk} file. If {inp:savepath()} is used, then this option is redundant. The report is always overwritten if it already exists. 
{p_end}

{pstd}{bf:{ul:savep}ath}({it:string}) is used to specify the location and name of the CSV file where the report will be saved to disk. The report is always overwritten if it already exists.
{p_end}

{pstd}{bf:{ul:qui}etly} is used to suppress showing the report in Stata{c 39}s result window.
{p_end}

{title:Examples}

{dlgtab:Example 1.}

{pstd}This shows the most basic use case of {inp:repadolog}. It searches for the {it:stata.trk} using the {inp:adopaths} in the current Stata session. It outputs the report in the result window. 
{p_end}

{input}{space 8}repadolog
{text}
{dlgtab:Example 2.}

{pstd}In this example the option {inp:detail} is used to provide meta info on all the commands installed in addition to meta info on the packages. 
{p_end}

{input}{space 8}repadolog, detail
{text}
{dlgtab:Example 3.}

{pstd}In this example, a CSV file named {it:reapdolog.csv} is saved with the report generated by this command in the code folder.
{p_end}

{input}{space 8}repadolog, detail savepath("${code}/repadolog.csv")
{text}
{title:Feedback, bug reports and contributions}

{pstd}Read more about these commands on {browse "https://github.com/worldbank/repkit":this repo} where this package is developed. Please provide any feedback by {browse "https://github.com/worldbank/repkit/issues":opening an issue}. PRs with suggestions for improvements are also greatly appreciated.
{p_end}

{title:Authors}

{pstd}LSMS Team, The World Bank lsms@worldbank.org
DIME Analytics, The World Bank dimeanalytics@worldbank.org
{p_end}
