{smcl}
{* *! version 1.0 13 Apr 2023}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "nca_estimate##syntax"}{...}
{viewerjumpto "Description" "nca_estimate##description"}{...}
{viewerjumpto "Options" "nca_estimate##options"}{...}
{viewerjumpto "Remarks" "nca_estimate##remarks"}{...}
{viewerjumpto "Examples" "nca_estimate##examples"}{...}
{title:Title}
{phang}
{bf:nca} {hline 2} Necessary Condition Analysis (NCA)

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:nca}
{it:{help varname: conditions outcome}}
(numeric
min=2)
[{help if}]
[{help in}]
[{cmd:,}
{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Optional}
{synopt:{opt ceil:ings(string)}} Ceilings to estimate. The allowed ceilings are {bf: ce_fdh}, {bf: cr_fdh}, {bf: ce_vrs} and {bf: cr_vrs}. The default are {bf: ce_fdh} and {bf: cr_fdh}.  {p_end}
{synopt:{opt test:rep(#)}} Number of replications for the permutation test. The default is 0.{p_end}
{synopt:{opt sco:pe(numlist)}} a theoretical scope in format : (x.low, x.high, y.low, y.high)  {p_end}
{synopt:{opt flipx}} Reverse the sign of the conditions {p_end}
{synopt:{opt flipy}} Reverse the sign of the outcome {p_end}
{synopt:{opt cor:ner(numlist)}} either an integer or a numlist of integers, indicating the corner to analyze {p_end}
{synopt:{opt cutoff(#)}} option for controlling how to display the x and y values that are outside the observed range. Default value is 0.{p_end}
{synopt:{opt xbot:tlenecks(string)}}  options for controlling the scale of the conditions in the bottleneck table {p_end}
{synopt:{opt ybot:tlenecks(string)}}  options for controlling the scale of the outcome in the bottleneck table {p_end}
{synopt:{opt bot:tlenecks(numlist)}} Values of depvar to calculate bottlenecks. numlist is optional.  {p_end}
{synopt:{opt steps(#)}}  Number of steps for Default value is 10.{p_end}
{synopt:{opt stepsize(numlist)}} an integer that defines the step size in the bottleneck table.   {p_end}
{synopt:{opt nograph}}  Prevents {cmd: nca} from showing the graph. {p_end}
{synopt:{opt nosumm:aries}}  Prevents {cmd: nca} from displaying the summaries. {p_end}
{synopt:{opt graphna:mes(stub)}} Prefix for the graph names to be saved in memory  {p_end}
{synopt:{opt nocombine}} Do not combine the single plots.  {p_end}
{synoptline}
{p 4 6 2}
{it:conditions} (also referred as x, throughout this help fle) is a varlist, {it:outcome} (also referred as y) is a single variable. They must not contain
factor variable and time-series operators.{p_end}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd} {cmd: nca} performs a Necessary Condition Analysis (NCA). NCA identifies a necessary condition X for an outcome Y in datasets. NCA draws a ceiling line  Y = f(X) in an XY plot. The  line separates the area without observations (the area of 'no Y without X')  from the area with observations (Dul, 2016; Dul, 2020). NCA estimates several parameters including necessity effect size and its p value  (Dul, van der Laan and Kuik, 2020).


{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt ceil:ings(string asis)} Ceilings to estimate.  The allowed ceilings are: {p_end}
{phang2} {bf: ce_fdh} requests {opt nca} to estimate a Ceiling Envelopment with Free Disposal Hull (default) {p_end}
{phang2} {bf: cr_fdh} requests {opt nca} to estimate a Ceiling Regression with Free Disposal Hull (default) {p_end}
{phang2} {bf: ce_vrs} requests {opt nca} to estimate a Ceiling Envelopment with Variable Returns to Scale {p_end}
{phang2} {bf: cr_vrs} requests {opt nca} to estimate a Ceiling Regression with Variable Returns to Scale {p_end}
{phang}
{opt test:rep(#)}   Number of permutation for the permutation test, the default is 0 and means that no permuation test is executed and, thus, no p-value is reported. {p_end}
{phang}
{opt sco:pe(numlist)}  a theoretical scope to be expressed in xlow, xhigh, ylow, yhigh  {p_end}
{phang}
{opt flipx}  forces {opt nca} to reverse the sign of all the conditions  {p_end}
{phang}
{opt flipy}  forces {opt nca} to reverse the sign of the outcome  {p_end}
{phang}
{opt cor:ner(numlist)}  an integer constant or a vector of integers indicating the corners to analyze, this option is equivalent to the combinations of {opt flipx} and {opt flipy}. If a single integer is specified by the user {opt nca} estimates the same corner for all the conditions. Users can specify a different corner for each condition. The default is 1 and means that neither the outcome nor the conditions are reversed in sign. {opt cor:ner(2)} is equivalent to {opt flipx}, {opt cor:ner(3)} is equivalent to {opt flipy} and {opt cor:ner(4)} is equivalent to {opt flipx flipy}.
{p_end}
{dlgtab:Bottlenecks table}
{phang}
{opt bottlenecks}[{bf:(}{it:numlist}{bf:)}]  the values of the {it: outcome} to be used in the bottleneck table. numlist is optional and, when it is not specified, the values of the outcome to be displayed in the bottleneck table are controlled by {opt steps} and {opt stepsize}. If numlist is specified {cmd: nca} overrides {opt steps} and {opt stepsize}  {p_end}
{phang}
{opt steps(#)} number of intervals of equal length to divide the bottleneck table, the default is 10.  {p_end}
{phang}
{opt stepsize(numlist)} Step size for the bottleneck table. {p_end}
{phang}
{opt xbottlenecks(string)} and {opt ybottlenecks(string)} control the scale of the conditions and of the outcome in the bottleneck table. The possible arguments are{p_end}
{phang2} - {it: perc_range} :  express the conditions (or the outcome). The default.{p_end}
{phang2} - {it: perc_range} : express the conditions (or the outcome) as a percentage of the range{p_end}
{phang2} - {it: perc_max} : express the conditions (or the outcome) as a percentage of the maximum{p_end}
{phang2} - {it: percentile} : express the conditions (or the outcome) in percentiles{p_end}
{phang}
{opt cutoff(#)}  option for controlling how to display the x and y values that are outside the observed range. The possible options are.  {p_end}
{phang2} - 0 : NN (non necessary) and NA (not available) {p_end}
{phang2} - 1 : NN and highest observed values {p_end}
{phang2} - 2 : calculated values {p_end}
{dlgtab:Graph}
{phang}
{opt nograph}  Prevents {cmd: nca} from showing the graph. Estimation is considerably faster.  {p_end}
{phang}
{opt graphna:mes(stub)} prefix for the graph names. The suffix of the graphs is given by the condition they refer to.   {p_end}
{phang}
{opt nocombine}  Do not combine the graphs of each condition after the estimation.  {p_end}
{dlgtab:Display}
{phang}
{opt nosum:maries}  Prevents {cmd: nca} from displaying the ceiling summaries, this is useful for the users who are only interested in the bottlenecks table.  {p_end}

{marker examples}{...}
{title:Examples}
{pstd} Load the dataset (data from Dul, 2020) {p_end}
{phang2} {cmd:. use ncaexample.dta,clear}{p_end}

{pstd}NCA using individualism as condition and innovationperformance as outcome. FDH and VRS ceiling (CE and CR) and show default bottlenecks table{p_end}
{phang2}{cmd:. nca individualism innovationperformance, ceilings( ce_vrs cr_vrs ce_fdh cr_fdh) bottlenecks}{p_end}

{pstd}NCA using individualism and risktaking as condition and innovationperformance as outcome. Absence of X- absence of Y FDH ceiling (CE and CR) and show custom bottlenecks table based on percentiles of X {p_end}
{phang2}{cmd:. nca individualism risktaking  innovationperformance , corner(4) bottlenecks(10 20(7.5)50) xbottlenecks(percentile)}{p_end}

{pstd}NCA using individualism as condition and innovationperformance as outcome. CE-FDH ceiling. Execute permutation test with 1000 replications {p_end}
{phang2}{cmd:. nca individualism innovationperformance, ceilings( ce_fdh) testrep(1000) nograph}{p_end}


{title:Stored Results}

{synoptset 15 tabbed}{...}
{phang2}{p_end}
{p2col 5 11 20 2:Scalars}{p_end}
{synopt:{cmd:e(es_{it: depvarname}_{it: ceiling name}) }} the effect size for ceiling given by {it: ceiling name} and condition {it: depvarname}  {p_end}
{synopt:{cmd: e(testrep) }} the number of replications for the permutation test {p_end}

 
{synoptset 15 tabbed}{...}
{phang2}{p_end}
{p2col 5 11 20 2:Matrices}{p_end}
{synopt:{cmd:   e(bottlenecks)}} the bottlenecks table {p_end}
{synopt:{cmd: e(scopeX) }} the extremes of the scope of each condition {p_end}
{synopt:{cmd: e(scopeY) }} the extremes of the scope of the outcome {p_end}
{synopt:{cmd: e(results) }} the summary table of the NCA {p_end}

{synoptset 20 tabbed}{...}
{phang2}{p_end}

{p2col 5 11 20 2:Macros}{p_end}
{synopt:{cmd:  e(xbottlenecks) }} Rendition of the conditions in the bottlenecks table (actual, perc_min, perc_range or perc_max) {p_end}
{synopt:{cmd:e(ybottlenecks)}} Rendition of the conditions in the bottlenecks table (actual, perc_min, perc_range or perc_max) {p_end}
{synopt:{cmd:e(cutoff)}} The type of cutoff (0,1 or 2)  {p_end}
{synopt:{cmd:e(corners)}} The corner. Indicates presence/presence, absence/presence, presence/absence and absence/absence of X and Y on the necessity condtion {p_end}
{synopt:{cmd:e(cmd)}} {cmd:nca}{p_end}
{synopt:{cmd:e(ceilings)}} the ceiling techniques {p_end}
{synopt:{cmd:e(conditions) }} the list of conditions {p_end}
{synopt:{cmd:e(outcome)}} the outcome {p_end}
{synopt:{cmd:e(sample)}} marks the estimation sample {p_end}

{title:References}
{pstd} Dul, J. (2016). Necessary condition analysis (NCA) logic and methodology of "necessary but not sufficient" causality. Organizational Research Methods, 19(1), 10-52. {p_end}

{pstd} Dul, J. (2020) "Conducting Necessary Condition Analysis"   SAGE Publications, ISBN: 9781526460141   https://uk.sagepub.com/en-gb/eur/conducting-necessary-condition-analysis-for-business-and-management-students/book262898 {p_end}

{pstd}  Dul, J., van der Laan, E., & Kuik, R. (2020).   A statistical significance test for Necessary Condition Analysis."   Organizational Research Methods, 23(2), 385-395.   https://journals.sagepub.com/doi/10.1177/1094428118795272 {p_end}

{title:Authors}
{pstd}Daniele Spinelli{p_end}
{pstd}Department of Statistics and Quantitative Methods {p_end}
{pstd}University of Milano-Bicocca{p_end}
{pstd}Milan, Italy{p_end}
{pstd}daniele.spinelli@unimib.it{p_end}

{pstd}Jan Dul{p_end}
{pstd}Department of Technology & Operations Management{p_end}
{pstd}Rotterdam School of Management{p_end}
{pstd}Rotterdam, The Netherlands{p_end}
{pstd}jdul@rsm.nl{p_end}

{title:Acknowledgements}
{pstd}We are grateful to Govert Buijs, Ricardo Ernesto Buitrago, Marno Verbeek and Caroline Witte for their beta testing. {p_end}






