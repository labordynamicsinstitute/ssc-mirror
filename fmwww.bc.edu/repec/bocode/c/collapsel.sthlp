{smcl}
{* 30may2013}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "C-function spec" "cfuncspec"}{...}
{vieweralsosee "tstats" "tstats"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:collapsel} {hline 2} Make dataset of summary statistics
 
{title:Syntax}

{pmore}{cmd:collapsel} [{it:{help cfuncspec:C-function spec}}] {ifin}, [{cmd:by(}{it:{help varelist}}{cmd:)} ...] [{opt noby}]


{title:Description}

{pstd}{cmd:collapsel} converts the dataset in memory into a dataset of means, sums, medians, etc.


{title:Options}

{phang}{cmd:by(}{it:{help varelist}}{cmd:)} works as usual, partitioning the dataset before calculating the statistics.

{pmore}It can be specified multiple times in a single command, which will result in multiple sets of observations, calculated on different partitions.

{pmore}When {opt by()} is not specified, a single overall summary observation is created.

{phang}{opt noby} adds a single, overall summary observation when one or more {opt by()} options are also specified.

