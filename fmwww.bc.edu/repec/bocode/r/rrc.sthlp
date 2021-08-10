{smcl}
{* 30jan2012}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "rxdays" "rxdays"}{...}
{vieweralsosee "rxdose" "rxdose"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf: rrc} {hline 2} Calculate adherence statistics

{title:Syntax}

{phang}{cmd:rrc using} {it:filename} {cmd:,} {cmdab:time:span(}{it:begin}{cmd:/}{it:interval}{cmd:/}{it:end)} 
[ {it:optional options} ]

{synoptset}
{synopthdr}
{synoptline}
{synopt :{cmdab:time:span()}}the period over (and periodicity with which) to measure adherence{p_end}
{synopt :{opth pt:id(varname)}}patient ids{p_end}
{synopt :{opth ix:date(varname)}}index date; ie, the dates from which {it:begin} and {it:end} are measured{p_end}
{synopt :{opth drug:id(varname)}}drug ids; must be numeric{p_end}
{synopt :{opth prdate(varname)}}prescription dates{p_end}
{synopt :{opth prdays(varname)}}prescription durations (ie, days supply){p_end}
{synoptline}

{phang}{cmd:using} specifies the name of the {it:output} file, which will replace the dataset in memory when the command is finished. Note that the specified file will be over-written without warning...

{title:Description}

{pstd}{cmd:rrc} calculates adherence, measured as the percent of days during which a patient has all the drug they're supposed to have. It requires (in the data file):

{phang2} o- a set of {bf:cases}, defined as a {bf:patient ID} combined with an {bf:index date}{p_end}
{phang2} o- a set of {bf:drugs}{p_end}
{phang2} o- for each case/drug, a list of prescription {bf:dates} & {bf:durations} (in days){p_end}

{pstd}The command also specifies the relevant timeperiods as {cmdab:time:span(}{it:begin}{cmd:/}{it:interval}{cmd:/}{it:end)}, where:

{phang2} o- {it:begin} is the offset from {bf:index date}, in days, at which to begin calculations.{p_end}
{phang2} o- {it:interval} is the number of days over which to calcuate each adherence statistic.{p_end}
{phang2} o- {it:end} is the offset from {bf:index date}, in days, at which to end calculations.{p_end}

{pstd}For example, {cmd:timespan(-90/30/180)} would calculate adherence for each 30-day period from 90 days before the {bf:index date}, till 180 days after the {bf:index date}.
(Note that the 180th day post-index would not actually be included, since it would not be part of a complete 30-day period.)

{title:Remarks}

{pstd}The 5 optional {it:varnames} should be treated as a group: either all specified or none. If the variables are the first 5 in the dataset, and ordered as above, they don't need to be explicitly specified.

{pstd}The output dataset will have one {bf:variable} for each {bf:value} of {cmd:drugid()} found in the input data. These variables will contain the adherence outcomes, numbers between 0 and 1.
There will also be 3 "header" fields: {bf:patient ID} and {bf:index date} (from the input file), and {bf:period}, an offset relative to the {bf:index date}.
The {bf:period} containing the index date will be 0; the one just before the index date would be numbered {bf:-1}; three periods prior would be {bf:-3}; just after would be {bf:1}, etc.

{pstd}{hline 10}

{pstd}To get the ({bf:case} specific) start- and end- dates for each {bf:period}, if {it:begin} is an exact multiple of {it:interval}, use the following calculations:

{pmore}start-date = {bf:index date} + {bf:period} *{it:interval}{p_end}
{pmore}{space 2}end-date = {bf:index date} + ({bf:period} +1)*{it:interval} -1{p_end}

{pstd}If {it:begin} is {bf:not} an exact multiple of {it:interval}, append the following to each calcultion:

{pmore}{opt +sign(begin)}{opt *mod(begin,interval)}

{pstd}{hline 10}

{pstd}To reiterate the description above, a set of prescription dates & durations must be present for {bf:each case}; that is, for each combination of {bf:patient ID} and {bf:index date}.
In particular, if adherence must be calculated for a single patient relative to two or more {bf:index dates}, some prescription records might have to be repeated in the input file.
In general, this should be a natural result of merging the required index dates with the prescription data.

