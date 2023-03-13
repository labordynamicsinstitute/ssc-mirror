{smcl}
{* Copyright 2007-2012 Brendan Halpin brendan.halpin@ul.ie }
{* Distribution is permitted under the terms of the GNU General Public Licence }
{* 17June2012}{...}
{cmd:help sadi}
{hline}

{title:Title}

{p2colset 5 17 23 2}{...}
{p2col:{hi:sadi} {hline 2}}Sequence analysis distance measures and utilities{p_end}
{p2colreset}{...}

{title:Description}

{pstd}{cmd:sadi} is a package of tools for sequence analysis. It
provides a range of distance measures, including Hamming, standard OM,
Hollister's localised OM, Halpin's duration-adjusted OM, Time-Warp Edit
Distance, and a duration-weighted version of Elzinga's Number of Common
Subsequences measure. It also provides a number of utilities.

{pstd}Several of the distance measures are coded using C plugins, for
speed. These are faster than Mata but less portable. On some platforms
the plugins will not work. Please let me know if you have problems in
this regard. 

{pstd}Some of the distance measures deal with duplicates efficiently
(i.e., by not re-estimating the distances redundantly). This facility
requires the mata function {cmd:mm_expand()} from Ben Jann's
{cmd:moremata} package. You can install this by doing
{cmd:ssc install moremata}.

{title:Author}

{pstd}Brendan Halpin, brendan.halpin@ul.ie{p_end}


{title:Also see}

{psee}Distance measures: {p_end}
{col 5}{bf:{help sdhamming}}{...}
{pstd}Hamming distance{p_end}
{col 5}{bf:{help oma}}{...}
{pstd}Optimal Matching Algorithm{p_end}
{col 5}{bf:{help omav}}{...}
{pstd}Halpin's duration-adjusted OM{p_end}
{col 5}{bf:{help sdhollister}}{...}
{pstd}Hollister's "Localised OM"{p_end}
{col 5}{bf:{help dynhamming}}{...}
{pstd}An implementation of Lesnard's Dynamic Hamming measure{p_end}
{col 5}{bf:{help twed}}{...}
{pstd}Time-Warp Edit Distance{p_end}
{col 5}{bf:{help combinadd}}{...}
{pstd}Elzinga's number of common subsequences measure, duration-weighted{p_end}

{psee}Utilities: {p_end}
{col 5}{bf:{help combinprep}}{...}
{pstd}Change data from wide calendar to wide spell format (needed for {cmd:combinadd}){p_end}
{col 5}{bf:{help trans2subs}}{...}
{pstd}Generate substitution costs for OM and related distances based on observed transition rates{p_end}
{col 5}{bf:{help maketrpr}}{...}
{pstd}Calculate smoothed time-dependent transition rates (needed for {cmd:dynhamming}){p_end}
{col 5}{bf:{help sdstripe}}{...}
{pstd}Generates a string representation of the sequence{p_end}
{col 5}{bf:{help metricp}}{...}
{pstd}Tests distance matrices for the triangle inequality{p_end}
{col 5}{bf:{help permtab}}{...}
{pstd}Compare two cluster solutions by permuting one to maximise the agreement{p_end}
{col 5}{bf:{help ari}}{...}
{pstd}Calculate the Adjusted Rand Index of agreement between two cluster solutions{p_end}
{col 5}{bf:{help corrsqm}}{...}
{pstd}Calculate the correlation between two distance matrices{p_end}
{col 5}{bf:{help nspells}}{...}
{pstd}Calculate the number of spells in a sequence{p_end}
{col 5}{bf:{help cumuldur}}{...}
{pstd}Calculate the cumulative duration in each state{p_end}
{col 5}{bf:{help sdentropy}}{...}
{pstd}Calculate the Shannon entropy of a sequence {p_end}
{col 5}{bf:{help sddiscrep}}{...}
{pstd}Calculate the Studer Discrepancy{p_end}

{psee}Visualisation: {p_end}
{col 5}{bf:{help sdchronoplot}}{...}
{pstd}Graph the time-dependent state distribution{p_end}
{col 5}{bf:{help sdindexplot}}{...}
{pstd}Indexplots graph trajectories, maintaining individual detail.{p_end}
{col 5}{bf:{help trprgr}}{...}
{pstd}Graph the time-dependent structure of transitions{p_end}
