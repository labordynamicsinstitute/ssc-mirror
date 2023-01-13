{smcl}
{* *! version 14.2 06nov2022}{...}
{cmd:help divratio}

{title:Title}

{phang}
{bf: divratio} {hline 2} Computes shares and diversions using a semiparametric logit model that assumes homogemous preferences
for groups of observably similar observations. Based on Raval, Rosenbaum, and Tenn (2017). Often referred to as the "bin method."

{title:Syntax}

{p 8 16 2}
{cmdab:div:ratio}
{it: a_side b_side loc_id firm_id geo prod}
{if}
{cmd:,}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt: {opt groups(varlist)}} patient characteristic variables to define groups. {p_end}
{synopt: {opt wtp}} calculate willingness-to-pay in addition to diversion ratios. {p_end}
{synopt: {opt ungrouped(string)}} instructions on what to do with observations that cannot be grouped. {p_end}
{synopt: {opt weight(varlist)}} a weight for each observation in the data. {p_end}
{synopt: {opt allow_within}} allows hospital-to-hospital diversions within the same owner. {p_end}
{synopt: {opt replacement}} groups variables based on resampling with replacement. {p_end}
{synopt: {opt geo_ref(string)}} specify the service area reference firm. {p_end}
{synopt: {opt prod_ref(string)}} specify the products of reference firm. {p_end}
{synopt: {opt svc_pct(integer)}} specify service area percentage. {p_end}
{synopt: {opt outside_cutoff(real)}} specify share percentage to be considered in choice set. {p_end}
{synopt: {opt min_group_size(integer)}} minimum number of observations per group. {p_end}
{synopt: {opt topcode(real)}} percentage to ensure probabilities are less than one for WTP calculations. {p_end}
{synopt: {opt inter_input(string)}} inputs saved group probabilities from previous runs of the program. {p_end}

{syntab:Results}
{synopt: {opt save_inter(string)}} save intermediate files; specify filepath. {p_end}
{synopt: {opt output(string)}} save results; specify filepath. {p_end}
{synopt: {opt disp_str(integer)}} characters to display for strings in results. {p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:divratio} computes diversions using a model that groups 
observably similar observations, and assumes that within each group or bin, the 
idiosyncratic error of each observation's preferences are iid Extreme Value. As 
a result, the share of location choices takes on a logit form and diversions 
within each bin can be computed analytically. 

{pstd}
The inputs are as follows: {opt a_side} is an indicator variable that equals 1 
for observations that chose the A-side, {opt b_side} is an indicator variable 
that equals 1 for observations that chose the B-side, {opt loc_id} is a categorical
variable that represents store locations, {opt firm_id} is a categorical variable
that represents the firm that owns the store locations, {opt geo} is a categorical 
variable that represents geographic regions (e.g. zip codes), and {opt prod} is 
a categorical variable that represents products offered by the firm.

{pstd}
This function will automatically compute diversion for the {opt svc_pct}%
service area based on {opt geo} for products the A-side and B-side both sell based 
on {opt prod}. The grouping variables are specified using {opt groups(varlist)}.

{title:Options}
{dlgtab:Main}
{phang}
{opt groups(varlist)} specifies patient characteristic variables used to create the 
groups. If omitted, share-based diversions will be calculated.

{phang}
{opt wtp} is a flag such that when used, WTP analysis is calculated in addition to diversions. If omitted, 
only diversion ratios will be calculated.

{phang}
{opt ungrouped(string)} specifies what the program should do with ungrouped observations using the "groups"
variables. The input can either be "keep", in which a degenerate variable "all" will be created and 
used as the first group, or "drop", in which the ungrouped observations will be dropped. If unspecified,
the ungrouped observations will be dropped. 

{phang}
{opt weight(varlist)} specifies variable used to weight each observation. For example,
if an observation in the data represents customer counts, then the count variable 
should be use here. If omitted, will assume each observation represents an individual.

{phang}
{opt allow_within} is a flag such that when used, diversions are computed including
other hospitals that are owned by the system as specified by {opt owner_id}. If omitted, 
the model will not allow for customers to divert to hospitals owned by the same system. 

{phang}
{opt replacement} is a flag such that when used, group probabilities will be calculated by
resampling the entire dataset for all customers that satisfy each grouping level. If omitted,
group probabilities will be calculated only using customers that were not previously used
to calculate group probabilities at a higher grouping level.

{phang}
{opt geo_ref(string)} specifies the reference hospitals in which to compute geographic
service areas. Can either be the A-side, B-side, combined, or union. Set equal to "a-side" for the A-side,
"b-side" for the B-side, "combined" for the combined service area, or "union" for the union of the 
two service areas. If ommitted, will use the union of the two service areas.

{phang}
{opt prod_ref(string)} specifies the reference hospitals in which to consider relevant
products. Can either be the A-side, B-side, overlapping, or union. Set equal to "a-side" for 
the A-side, "b-side" for the B-side, "union" for all, or "overlap" for the overlapping. 
If ommitted, will calculate for overlapping products.

{phang}
{opt svc_pct(integer)} specifies the what percent service area should be used. If
omitted, the analysis will use the 75% service area.

{phang}
{opt min_group_size(integer)} specifies the minimum number of observations within a 
group. This is the "tuning parameter" in Raval, et. al. If omitted, the minimum number 
of observations per group will be set to 20. 

{phang}
{opt outside_cutoff(real)} specifies what share percentage to use to consider which firm
locations are considered as in the choice set. If omitted, a 0.005% cutoff will
be used.

{phang}
{opt inter_input(string)} inputs the choice probabilities file from previous runs of the 
program to save time. If used {opt save_inter} in previous run, then input file will be 
given by "Results - Choice Probabilities.dta".

{dlgtab: Results}
{phang}
{opt save_inter(string)} is used to save the intermediate files that are created 
in the analysis in the specified file location {it: string}. This includes files 
that specify overlapping products, the service areas, the samples used to conduct 
analysis, etc. If omitted, no files will be saved.

{phang}
{opt output(string)} is used to save the final results to a file specified in 
{it: string}. If both {opt save_inter} and {opt output} are both omitted, no 
files will be saved. If only {opt output} is omitted, the results will save to
the the filepath specified in {opt save_inter}.

{phang}
{opt disp_str(integer)} specifies the nubmer of characters for string variables
to be displayed in the output results. If omitted, the results will display 30 
characters.


{title:Example}
{pstd}
For hospital mergers, an example may be:

	divratio a_side b_side hospital current_system pat_zip drg, groups(pat_county pat_zip mdc drg age female) svc_pct(90)

{pstd}
This command will compute diversions for each hospital in {opt hospital} within the 
90% combined service area for the A-side and B-side based on patient zip codes. This will also focus on DRGs
in which the parties overlap. In addition, it will estimate the diversions from 
the A-side hospital to each hospital in {opt hospital} and from 
the B-side hospital to each hospital in {opt hospital} using the semiparametric model 
that groups over pat_county, pat_zip, mdc, drg, age, and female.

{title:Additional Notes}
{pstd}
If you do not want to limit over geographic regions or products, set {opt geo} or
{opt prod} equal to a degenerate variable, e.g. a vector of all ones. If you do
not want to limit service areas, set the option {opt svc_pct} equal to 100.

{title:References}
{pstd}
Raval, Devesh, Ted Rosenbaum and Steve Tenn. "Semiparametric Discrete Choice Model: An Application to Hospital Mergers." Economic Inquiry, 2017, 55(4), 1919-1944.

{pstd}
Raval, Devesh, Ted Rosenbaum and Nathan Wilson. "Using Disaster Induced Closures to Evaluate Discrete Choice Models of Hospital Demand." RAND Journal of Economics, 2022, 53(3), 561-589.

{title:Contact Information}
{pstd}
Author: Christopher V. Lau

{pstd}
Email: chris.vlau@gmail.com 
