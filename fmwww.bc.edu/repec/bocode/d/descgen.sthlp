{smcl}
{hline}
help for {cmd:descgen} {right:(Roger Newson)}
{hline}


{title:Add Stata dataset attribute variables to a {helpb xdir} resultsset}

{p 8 15}{cmd:descgen} {ifin} [ {cmd:,}
 {cmdab:fi:lename}{cmd:(}{varname}{cmd:)} {cmdab:di:rname}{cmd:(}{varname}{cmd:)}  {cmdab::no}{cmdab:dn:}
 {break}
 {opth is:dta(newvarname)} {opth no:bs(newvarname)} {opth nv:ar(newvarname)} {opth wi:dth(newvarname)} {opth si:ze(newvarname)}
 {break}
 {opth so:rtedby(newvarname)} {cmdab::no}{cmdab:sb:} {opth al:lvars(newvarname)} {cmdab::no}{cmdab:av:}
 {break}
 {cmd:replace}
 ]


{title:Description}

{pstd}
{cmd:descgen} is intended for use in output datasets (or resultssets) produced by the {helpb xdir} package,
which have one observation for each of a list of files,
and data on directory names and file names.
It inputs the file name variable and (optionally) the directory name variable,
and generates a list of new variables,
containing, in each observation, Stata dataset attributes
describing the Stata dataset stored in the corresponding file.
These attributes include numbers of variables and observations and sizes of an observation or of the dataset,
and (optionally) lists of variables in the dataset.
If the corresponding file is not a Stata dataset, then these dataset attribute variables will have missing values.


{title:Options}

{p 4 8 2}
{opth filename(varname)} specifies an existing string variable,
containing the file names.
If absent, then it is set to {cmd:filename}.

{p 4 8 2}
{opth dirname(varname)} specifies an existing string variable,
containing the directory names.
If absent, then it is set to {cmd:dirname}.

{p 4 8 2}
{cmd:nodn} specifies that the directory name variable specified by {cmd:dirname()} will not be used.
This option can be useful,
if the file name variable specified by {cmd:filename()} contains the full file path for each file,
including the directory name.

{p 4 8 2}
{opth isdta(newvarname)} specifies the name of the output variable containing an indicator
that the file is a Stata dataset that can be described using {helpb describe}.
It is 1 for Stata dataset files, 0 for non-dataset files,
and missing for observations out of the sample selected by the {helpb if} and {helpb in} qualifiers.
If absent, then it is set to {cmd:isdta}.

{p 4 8 2}
{opth nobs(newvarname)} specifies the name of the output variable containing the numbers of observations in the datasets.
If absent, then it is set to {cmd:nobs}.

{p 4 8 2}
{opth nvar(newvarname)} specifies the name of the output variable containing the numbers of variables in the datasets.
If absent, then it is set to {cmd:nvar}.

{p 4 8 2}
{opth width(newvarname)} specifies the name of the output variable containing the widths (in bytes) of observations in the datasets.
If absent, then it is set to {cmd:width}.

{p 4 8 2}
{opth size(newvarname)} specifies the name of the output variable containing the sizes (in bytes) of the full data areas in the datasets.
These sizes are equal to the product of the {cmd:nobs()} output variable and the {cmd:width()} output variable.
If absent, then it is set to {cmd:size}.

{p 4 8 2}
{opth sortedby(newvarname)} specifies the name of the output string variable containing the lists of variables by which the datasets are sorted.
If absent, then it is set to {cmd:sortedby}.

{p 4 8 2}
{cmd:nosb} specifies that the {cmd:sortedby()} output variable will not be produced.
This option can be useful to save space if the sort keys are very long,
which may be the case for datasets with many variables.

{p 4 8 2}
{opth allvars(newvarname)} specifies the name of the output string variable containing the lists of all variables in each dataset.
If absent, then it is set to {cmd:sortedby}.

{p 4 8 2}
{cmd:noav} specifies that the {cmd:allvars()} output variable will not be produced.
This option can be useful to save space, if the datasets have many variables.

{p 4 8 2}
{cmd:replace} specifies that any existing variables with the same names as the generated output variables will be replaced.


{title:Output variables created by {cmd:descgen}}

{pstd}
The {cmd: descgen} package creates the following list of variables:

{p2colset 4 20 22 2}{...}
{p2col:Default name}Description{p_end}
{p2line}
{p2col:{cmd:isdta}}Stata dataset status indicator{p_end}
{p2col:{cmd:nobs}}N of observations{p_end}
{p2col:{cmd:nvar}}N of variables{p_end}
{p2col:{cmd:width}}Width of observation (bytes){p_end}
{p2col:{cmd:size}}Size of dataset (bytes){p_end}
{p2col:{cmd:sortedby}}Sort list of variables{p_end}
{p2col:{cmd:allvars}}List of all variables{p_end}
{p2line}
{p2colreset}

{pstd}
The variables {hi:sortedby} and {hi:allvars} can be absent,
if the user sets the options {cmd:nosb} and {cmd:noav},
respectively.
All these variables can be renamed,
using the options of the same names.


{title:Remarks}

{pstd}
{cmd:descgen} is designed for use in output datasets (or resultssets),
with one observation for each of a list of files,
created using the {helpb xdir} package,
which can be downloaded from {help ssc:SSC}.
It inputs the variables whose default names are {cmd: filename} and (optionally) {cmd:dirname},
containing the file names and directory names, respectively.
It outputs, in each observation,
the dataset attributes that may be output by the {helpb describe} command,
with the {helpb using} modifier,
if the file specified by the observation contains a Stata dataset.
If a file specified by an observation does not contain a Stata dataset,
then the values of the corresponding output variables will be missing.

{pstd}
{cmd:descgen} only stores a basic summary of the attributes of a dataset,
optionally including lists of variables.
If the user wants more detailed information on the attributes of the individual variables,
then the user should use {helpb describe},
or the {help ssc:SSC} package {helpb descsave}.


{title:Examples}

{pstd}
The examples are designed to be demonstrated in an output dataset (or resultsset)
produced by the {helpb xdir} package.
This resultsset has one observation for each of a list of Stata dataset files,
all of which are copied from the Stata datasets downloadable using the {helpb sysuse} command.
These Stata dataset files are all stored in a subdirectory of the current working directory,
produced using the commands in the set-up section.
Once these files have been created,
the {helpb xdir} command is used to create a resultsset in the memory,
with one observation for each of the Stata data files,
and two variables {cmd:dirname} and {cmd:filename},
containing the names of the directory and the file, respectively.
Once this resultsset is created,
the user can use {cmd:descgen} to add new variables,
containing the various dataset attributes.

{pstd}
Set-up:

{p 16 20}{cmd:. capture noisily mkdir ./dta}{p_end}
{p 16 20}{cmd:. local sysdta "auto auto2 autornd bplong bpwide"}{p_end}
{p 16 20}{cmd:. foreach DS in `sysdta' {c -(}}{p_end}
{p 16 20}{cmd:.   sysuse `DS', clear}{p_end}
{p 16 20}{cmd:.   describe, full}{p_end}
{p 16 20}{cmd:.   save ./dta/`DS', replace}{p_end}
{p 16 20}{cmd:. {c )-}}{p_end}
{p 16 20}{cmd:. xdir, dirname(./dta) pattern(*.dta) norestore}{p_end}
{p 16 20}{cmd:. describe, full}{p_end}
{p 16 20}{cmd:. list, abbr(32)}{p_end}

{pstd}
The following example creates the default full set of generated variables,
with the default names,
and describes and lists them.

{p 16 20}{cmd:. descgen}{p_end}
{p 16 20}{cmd:. describe, full}{p_end}
{p 16 20}{cmd:. list, abbr(32)}{p_end}

{pstd}
The following example discards the variables created in the previous example,
and creates a new reduced set of variables,
using the {cmd:nosb} and {cmd:noav} options
to omit the variable-list string variables {cmd:sortedby} and {cmd:allvars}.
These are also described and listed,
producing a more concise output.

{p 16 20}{cmd:. keep dirname filename}{p_end}
{p 16 20}{cmd:. descgen, nosb noav}{p_end}
{p 16 20}{cmd:. describe, full}{p_end}
{p 16 20}{cmd:. list, abbr(32)}{p_end}

{pstd}
The following example discards the variables created in the previous example,
and creates a new set of variables,
containing the same information as in the first example,
but with non-default names.
These are also described and listed.

{p 16 20}{cmd:. keep dirname filename}{p_end}
{p 16 20}{cmd:. describe, full}{p_end}
{p 16 20}{cmd:. descgen, isdta(isdset) nobs(N_obs) nvar(N_var) width(obswidth) size(datasize) sortedby(sortvars) allvars(fullvars)}{p_end}
{p 16 20}{cmd:. describe, full}{p_end}
{p 16 20}{cmd:. list, abbr(32)}{p_end}


{title:Author}

{pstd}
Roger Newson, Imperial College London, UK.
Email: {browse "mailto:r.newson@imperial.ac.uk":r.newson@imperial.ac.uk}


{title:Also see}

{p 4 13 2}
{bind: }Manual: {hi:[D] dir}, {hi:[D] describe}
{p_end}
{p 4 13 2}
On-line: help for {helpb dir}, {helpb describe}
 {break} help for {helpb xdir}, {helpb descsave} if installed
{p_end}
