{smcl}
{* 19mar2012}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "emiss" "emiss"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:nmiss} {c -} Summarize missing data

{title:Syntax}

{pmore}
{cmdab:nmiss} [{it:{help varelist}}] {ifin} [{cmd:,} {opt n:labels(details)} {opt out(details)}]

{title:Description}

{pstd}{cmd:nmiss} summarizes missing data in a dataset. It produces two tables:

{phang}1.{space 2}The number and percent missing for each variable in {it:{help varelist}}.

{pmore}This table also includes the percent of {it:other data} missing when each variable is missing. That is: For the observations in which variable {it:X} is missing, for the {it:other} variables that are sometimes missing,
it reports the percent of data (cells) missing.

{phang}2.{space 2}The number and percent of observations at each increment of missing data. That is, observations with no missing, with one missing variable, etc.

{title:Options}

INCLUDE help tabel_options2

