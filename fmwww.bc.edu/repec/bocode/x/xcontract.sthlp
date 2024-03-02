{smcl}
{hline}
help for {cmd:xcontract} and {cmd:freqtop}{right:(Roger Newson)}
{hline}

{title:Create or extend dataset of variable combinations with frequencies and percents}

{p 8 17 2}{cmd:xcontract} {it:varlist} [{it:weight}] [{cmd:if} {it:exp}] [{cmd:in} {it:range}] [{cmd:,}
 {break}
 {cmdab:li:st}{cmd:(} [{it:varlist}] [{cmd:if} {it:exp}] [{cmd:in} {it:range}] [ , [{it:list_options}] ] {cmd:)}
 {break}
 {cmdab:fra:me}{cmd:(} {it:framename} [ , replace {cmdab:ch:ange} ] {cmd:)}
 {break}
 {cmdab:sa:ving}{cmd:(}{it:filename}[{cmd:,replace}]{cmd:)} {cmdab::no}{cmdab:re:store} {cmd:fast}
 {cmdab:fl:ist}{cmd:(}{it:global_macro_name}{cmd:)}
 {break}
 {cmdab:f:req:(}{it:newvarname}{cmd:)} {cmdab:p:ercent:(}{it:newvarname}{cmd:)}
 {cmdab:cf:req:(}{it:newvarname}{cmd:)} {cmdab:cp:ercent:(}{it:newvarname}{cmd:)}
 {break}
 {cmdab:pty:pe}{cmd:(}{it:storage_type}{cmd:)} {cmdab:pfo:rmat}{cmd:(}{it:format}{cmd:)} {cmdab:zto:tal}{cmd:(}{it:#}{cmd:)}
 {break}
 {cmd:by(}{it:by_varlist}{cmd:)}
 {break}
 {cmdab:z:ero} {cmd:nomiss}
 {break}
 {cmdab:idn:um}{cmd:(}{it:#}{cmd:)} {cmdab:nidn:um}{cmd:(}{it:newvarname}{cmd:)}
 {cmdab:ids:tr}{cmd:(}{it:string}{cmd:)} {cmdab:nids:tr}{cmd:(}{it:newvarname}{cmd:)}
 {break}
 {cmdab:fo:rmat}{cmd:(}{it:varlist_1 format_1 ... varlist_n format_n}{cmd:)}
 {break}
 ]

 {p 8 17 2}{cmd:freqtop} [{cmd:if} {it:exp}] [{cmd:in} {it:range}] [{cmd:,}
  {break}
 {cmdab:f:req:(}{it:newvarname}{cmd:)} {cmdab:p:ercent:(}{it:newvarname}{cmd:)}
 {cmdab:cf:req:(}{it:newvarname}{cmd:)} {cmdab:cp:ercent:(}{it:newvarname}{cmd:)}
 {break}
 {cmdab:pty:pe}{cmd:(}{it:storage_type}{cmd:)} {cmdab:pfo:rmat}{cmd:(}{it:format}{cmd:)} {cmdab:zto:tal}{cmd:(}{it:#}{cmd:)}
 {break}
 {cmd:by(}{it:by_varlist}{cmd:)}
 {break}
 {cmd:fast} {cmd:replace}
 {break}
 ]

 
{p 4 4 2}
{cmd:fweight}s, {cmd:aweight}s, {cmd:pweight}s, and {cmd:iweight}s are allowed for {cmd:xcontract},
and are all treated in the same way;
see help for {help weights}.


{title:Description}

{p 4 4 2}
{cmd:xcontract} is an extended version of {helpb contract}.
It creates an output data set (or resultsset),
with 1 observation per combination of values of the variables in {it:varlist},
and data on the frequencies and percents of those combinations of values
in the existing data set,
and, optionally, the cumulative frequencies and percents of those combinations.
If the {cmd:by()} option is used, then the output data set
has one observation per combination of values of the {it:varlist} variables per by-group,
and percents are calculated within each by-group.
The output data set created by {cmd:xcontract}
may be listed to the Stata log, or saved to a {help frame:data frame}, or saved to a disk file, or written to the memory
(overwriting any pre-existing data set).
{cmd:freqtop} inputs an existing frequency variable in the current dataset,
which is typically an output dataset made by {cmd:xcontract}.
It generates new variables, in the same dataset,
containing the corresponding cumulative frequencies and/or percents and/or cumulative percents,
optionally defined within user-specified by-groups.


{title:Options for use with {cmd:xcontract} and {cmd:freqtop}}

{p}
{cmd:xcontract} and {cmd:freqtop} have a large number of options, which are listed in 4 groups:

{p 0 4}{bf:1.} Options for {cmd:xcontract} and {cmd:freqtop}.{p_end}

{p 0 4}{bf:2.} Output-destination options for {cmd:xcontract}.
(These specify where the output data set will be written.){p_end}

{p 0 4}{bf:3.} Other options for {cmd:xcontract} only.{p_end}

{p 0 4}{bf:4.} Other options for {cmd:freqtop}.{p_end}


{title:Options for {cmd:xcontract} and {cmd:freqtop}}

{p 4 8 2}{cmd:freq}{cmd:(}{it:newvarname}{cmd:)} specifies a name for the output frequency
variable (for {cmd:xcontract})
or the input frequency variable (for {cmd:freqtop}).
If not specified, the name {cmd:_freq} is used.

{p 4 8 2}{cmd:percent}{cmd:(}{it:newvarname}{cmd:)} specifies a name for the percent
variable.  If not specified, {cmd:_percent} is used.
If the {cmd:by()} option is used,
then the percent for each combination of values of the
{it:varlist} variables in each by-group is calculated as a percent of the by-group.

{p 4 8 2}{cmd:cfreq}{cmd:(}{it:newvarname}{cmd:)} specifies a name for the cumulative
frequency variable.  If not specified, no cumulative frequency variable is created.
If the {cmd:by()} option is used,
then the cumulative frequency for each combination of values of the
{it:varlist} variables in each by-group is calculated as a cumulative frequency within the by-group.

{p 4 8 2}{cmd:cpercent}{cmd:(}{it:newvarname}{cmd:)} specifies a name for the cumulative
percent variable.  If not specified, no cumulative percent variable is created.
If the {cmd:by()} option is used,
then the cumulative percent for each combination of values of the
{it:varlist} variables in each by-group is calculated as a cumulative percent of the by-group.

{p 4 8 2}{cmd:ptype(}{it:storage_type}{cmd:)} specifies a {help type:storage type}
for generating the percent variables specified by {cmd:percent()} and {cmd:cpercent()}.
If {cmd:type()} is not specified, then these variables will be generated as variables
of type {helpb float}. All generated variables are compressed to the smallest
storage type possible without loss of precision. See help for {helpb compress}.

{p 4 8 2}{cmd:pformat(}{it:format}{cmd:)} specifies a {help format:display format}
for the percent variables specified by {cmd:percent()} and {cmd:cpercent()}.
If {cmd:pformat()} is not specified,
then these variables will have format {cmd:%8.2f},
unless the formats are changed using the {cmd:format()} option.

{p 4 8 2}{cmd:ztotal(}{it:#}{cmd:)} specifies a numeric value (usually {help missing})
to which percents are evaluated if the denominator from which they are derived is zero.
For instance, {cmd:ztotal(.z)} evaluates such percents to the missing value {cmd:.z}.
The default is {cmd:ztotal(.)}, using the standard numeric missing value.

{p 4 8 2}{cmd:by(}{it:by_varlist}{cmd:)} specifies a list of by-variables. If {cmd:by()}
is specified, then all percents will be calculated as percents of their by-groups.
Note that, if the {helpb if} expression or the {help weight} expression contains the
reserved names {hi:_n} and {hi:_N}, then these will be interpreted as the observation sequence number
and the number of observations, respectively, within the whole data set, not within the by-group.


{title:Output-destination options for {cmd:xcontract}.}

{p 4 8 2}
{cmd:list(}{it:varlist} [{cmd:if} {it:exp}] [{cmd:in} {it:range}] [, {it:list_options} ] {cmd:)}
specifies a list of variables in the output
data set, which will be listed to the Stata log by {cmd:xcontract}.
The {cmd:list()} option can be used with the {cmd:format()} option (see below)
to produce a list of frequencies and/or percents
with user-specified numbers of decimal places or significant figures.
The user may optionally also specify {helpb if} or {helpb in} qualifiers to list subsets of combinations
of variable values,
or change the display style using a list of {it:list_options} allowed as options by the {helpb list} command.
If {cmd:by(}{it:by_varlist}{cmd:)} is used, then the combinations are listed by the by-groups defined by
{it:by_varlist}.

{p 4 8 2}
{cmd:frame(} {it:name}, [ {cmd:replace} {cmd:change} ] {cmd:)} specifies an output {help frame:data frame},
to be generated to contain the output data set.
If {cmd:replace} is specified, then any existing data frame of the same name is overwritten. 
If {cmd:change} is specified,
then the current data frame will be changed to the output data frame after the execution of {cmd:xcontract}.
The {cmd:frame()} option may not specify the current data frame.
To do this, use one of the options {cmd:norestore} or {cmd:fast}.

{p 4 8 2}
{cmd:saving(}{it:filename}[{cmd:,replace}]{cmd:)} saves the output data set to a disk file.
If {cmd:replace} is specified, and a file of that name already exists,
then the old file is overwritten.

{p 4 8 2}
{cmd:norestore} specifies that the output data set will be written to the memory,
overwriting any pre-existing data set. This option is automatically set if {cmd:fast} is
specified. Otherwise, if {cmd:norestore} is not specified, then the pre-existing data set is restored
in the memory after the execution of {cmd:xcontract}.

{p 4 8 2}
{cmd:fast} is a stronger version of {cmd:norestore}, intended for use by programmers.
It specifies that the pre-existing data set in the memory will not be restored,
even if the user presses {helpb break:Break} during the execution of {cmd:xcontract}.
If {cmd:norestore} is specified and {cmd:fast} is absent,
then {cmd:xcontract} will go to extra work so that
it can restore the original data if the user presses {helpb break:Break}.

{p 4 8 2}
Note that the user must specify at least one of the five options {cmd:list()}, {cmd:frame()},
{cmd:saving()}, {cmd:norestore}, and {cmd:fast}.
These options specify whether the output data set is listed to the Stata log,
saved to a disk file, or written to the memory (overwriting any pre-existing data set). More than
one of these options can be specified.

{p 4 8 2}
{cmd:flist(}{it:global_macro_name}{cmd:)} specifies the name of a global macro, containing
a filename list (possibly empty). If {cmd:saving()} is also specified, then
{cmd:xcontract} will append the name of the data set specified in the
{cmd:saving()} option to the value of the global macro specified in {cmd:flist()}. This
enables the user to build a list of filenames in a global macro, containing the
output of a sequence of output data sets.
These files may later be concatenated using {helpb append}.


{title:Other options for {cmd:xcontract} only}

{p 4 8 2}{cmd:zero} specifies that combinations of values of the variables in {it:varlist}
with zero frequency in the input data set will be included in the output data set.

{p 4 8 2}{cmd:nomiss} specifies that observations with missing values for any of
the variables in {it:varlist} will be excluded from the output data set.
If not specified, all observations are included,
except if excluded by the {helpb if} and {helpb in} qualifiers or given zero {help weights}.

{p 4 8 2}{cmd:idnum(}{it:#}{cmd:)} specifies an ID number for the output data set.
It is used to create a numeric variable, with default name {hi:idnum}, in the output data set,
with that value for all observations.
This is useful if the output data set is concatenated with other {cmd:xcontract} output data sets
using {helpb append}.

{p 4 8 2}{cmd:nidnum(}{it:newvarname}{cmd:)} specifies a name for the numeric ID variable
evaluated by {cmd:idnumrher  If {cmd:idnum()} is present and {cmd:nidnum()} is absent,
then the name of the numeric ID variable is set to {hi:idnum}.

{p 4 8 2}{cmd:idstr(}{it:string}{cmd:)} specifies an ID string for the output data set.
It is used to create a string variable, with default name {hi:idstr} in the output data set,
with that value for all observations.
This is useful if the output data set is concatenated with other {cmd:xcontract} output data sets
using {helpb append}.

{p 4 8 2}{cmd:nidstr(}{it:newvarname}{cmd:)} specifies a name for the string ID variable
evaluated by {cmd:idstr()}. If {cmd:idstr()} is present and {cmd:nidstr()} is absent,
then the name of the string ID variable is set to {hi:idstr}.

{p 4 8 2}{cmd:format(}{it:varlist_1 format_1 ... varlist_n format_n}{cmd:)}
specifies a list of pairs of {help varlist:variable lists} and {help format:display formats}.
The {help format:formats} will be allocated to
the variables in the output data set specified by the corresponding {it:varlist_i}
lists.
If the {cmd:format()} option is absent, then the percent variables have the format {hi:%8.2f},
the frequency variables have the format {hi:%12.0g},
and the other variables have the same formats as the variables of the same names
in the input data set.


{title:Other options for {cmd:freqtop}}

{p 4 8 2}
{cmd:fast} is intended for use by programmers.
It specifies that the pre-existing data set in the memory will not be restored,
even if the user presses {helpb break:Break} during the execution of {cmd:freqtop}.
If {cmd:fast} is absent,
then {cmd:freqtop} will go to extra work so that
it can restore the original data if the user presses {helpb break:Break}.

{p 4 8 2}
{cmd:replace} specifies that, if there are existing variables in the current dataset,
with the same names as the output percents and/or cumulative frequencies created by {cmd:freqtop},
then those existing variables will be replaced.


{title:Examples}

{p}
The following examples use the {cmd:list()} option to list the output data set to the Stata log.
After these examples are executed, there is no new data set either in the memory or on disk.

{p 4 8 2}{cmd:. xcontract foreign rep78, list(,)}{p_end}

{p 4 8 2}{cmd:. xcontract foreign rep78, zero list(,clean noobs)}{p_end}

{p 4 8 2}{cmd:. xcontract foreign rep78, f(count) p(percent) cf(ccount) cp(cpercent) zero nomiss list(*,clean noobs)}{p_end}

{p 4 8 2}{cmd:. xcontract rep78, by(foreign) fr(frequency) per(percentage) cf(cumfreq) cp(cumperc) pty(double) format(percentage cumperc %4.0f) list(rep78-cumperc,clean noobs abbrev(16))}{p_end}

{p 4 8 2}{cmd:. xcontract _all, list(*,clean noobs)}

{p}
The following examples use the {cmd:norestore} option to create an output data set in the memory,
overwriting any pre-existing data set.

{p 4 8 2}{cmd:. xcontract foreign rep78, norestore}{p_end}

{p 4 8 2}{cmd:. xcontract foreign rep78, zero norestore}{p_end}

{p 4 8 2}{cmd:. xcontract foreign rep78, f(count) p(percent) cf(ccount) cp(cpercent) zero nomiss norestore}{p_end}

{p 4 8 2}{cmd:. xcontract rep78, by(foreign) fr(frequency) per(percentage) cf(cumfreq) cp(cumperc) pty(double) format(percentage cumperc %4.0f) norestore}{p_end}

{p 4 8 2}{cmd:. xcontract _all, norestore}

{p}
The following examples use the {cmd:saving()} option to create an output data set in a disk file.

{p 4 8 2}{cmd:. xcontract foreign rep78, saving(myfreq1.dta)}{p_end}

{p 4 8 2}{cmd:. xcontract foreign rep78, zero saving(myfreq2.dta,replace)}{p_end}

{p 4 8 2}{cmd:. xcontract foreign rep78, f(count) p(percent) cf(ccount) cp(cpercent) zero nomiss  saving(myfreq3.dta,replace)}{p_end}

{p 4 8 2}{cmd:. xcontract rep78, by(foreign) fr(frequency) per(percentage) cf(cumfreq) cp(cumperc) pty(double) format(percentage cumperc %4.0f)  saving(myfreq4.dta,replace)}{p_end}

{p 4 8 2}{cmd:. xcontract _all,  saving(myfreq5.dta,replace)}

{p}
The following examples use the {cmd:frame()} option to create an output data set in a data frame.

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. xcontract rep78, by(foreign) frame(outframe)}{p_end}
{p 4 8 2}{cmd:. frame outframe {c -(}}{p_end}
{p 4 8 2}{cmd:. describe, full}{p_end}
{p 4 8 2}{cmd:. by foreign: list, abbr(32)}{p_end}
{p 4 8 2}{cmd:. {c )-}}{p_end}
{p 4 8 2}{cmd:. frame drop outframe}{p_end}

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. xcontract rep78, by(foreign) frame(outframe, replace change)}{p_end}
{p 4 8 2}{cmd:. describe, full}{p_end}
{p 4 8 2}{cmd:. twoway bar _percent rep78 [fweight=_freq], hori by(foreign, col(1)) yscale(reverse) ylab(1(1)5)}{p_end}
{p 4 8 2}{cmd:. frame change default}{p_end}
{p 4 8 2}{cmd:. describe, full}{p_end}
{p 4 8 2}{cmd:. frame drop outframe}{p_end}

{p}
The following advanced example
uses {cmd:freqtop} to add row and column percents
to a resultsset created by {cmd:xcontract}.
We start by creating the resultsset using {cmd:xcontract},
with 1 observation per combination of {cmd:foreign} and {cmd:rep78},
including combinations with no observations (because of the {cmd:zero} option),
and overwriting the dataset in memory (because of the {cmd:fast} option).
We then add a variable {cmd:_colpercent},
containing percents foreach each {cmd:rep78} value in by-groups defined by {cmd:foreign} values.
We then add a variable {cmd:_rowpercent},
containing percents foreach each {cmd:foreign} value in by-groups defined by {cmd:rep78} values.
The dataset then represents a table, with columns corresponding to {cmd:foreign} values,
and rows corresponding to {cmd:rep78} values.
Note that the column percents sum to 100.00 percent
in the columns (but not in the rows),
and the row percents sum to 100.00 percent
in the rows (but not in the columns).

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. xcontract foreign rep78, zero fast}{p_end}
{p 4 8 2}{cmd:. describe, full}{p_end}
{p 4 8 2}{cmd:. by foreign: list, abbr(32)}{p_end}
{p 4 8 2}{cmd:. freqtop, percent(_colpercent) by(foreign)}{p_end}
{p 4 8 2}{cmd:. describe, full}{p_end}
{p 4 8 2}{cmd:. by foreign: list, abbr(32) sum(_percent _colpercent)}{p_end}
{p 4 8 2}{cmd:. freqtop, percent(_rowpercent) by(rep78)}{p_end}
{p 4 8 2}{cmd:. describe, full}{p_end}
{p 4 8 2}{cmd:. by foreign: list, abbr(32) sum(_percent _colpercent _rowpercent)}{p_end}
{p 4 8 2}{cmd:. bysort rep78 (foreign): list, abbr(32) sum(_percent _colpercent _rowpercent)}{p_end}


{title:Acknowledgements}

{p}
I would like to thank Nicholas J. Cox of Durham University, UK
for some very helpful advice about writing efficient code,
and also for writing the original version of {helpb contract}, from which I re-engineered some of
the code for {cmd:xcontract}.
I would also like to thank Jeremy Freese of Stanford University for writing the {help ssc:SSC} package {helpb frameappend},
from which I also re-engineered some of the code for {cmd:xcontract}.
I would also like to thank StataCorp for writing {helpb fillin}, from which
I also re-engineered some of the code for {cmd:xcontract}.


{title:Author}

{p}
Roger Newson, Queen Mary University London, UK.
Email: {browse "mailto:r.newson@qmul.ac.uk":r.newson@qmul.ac.uk}


{title:Also see}

{p 4 13 2}
Manual:  {hi:[R] contract}, {hi:[R] collapse}, {hi:[R] fillin}, {hi:[R] compress}, {hi:[R] format},
{hi:[R] expand}, {hi:[R] duplicates}
{p_end}

{p 4 13 2}
Online:  help for {helpb contract}, {helpb collapse}, {helpb fillin}, {helpb compress}, {helpb format},
{helpb expand}, {helpb duplicates}
{break} help for {helpb xcollapse} if installed
{p_end}
