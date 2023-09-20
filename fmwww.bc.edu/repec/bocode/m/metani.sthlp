{smcl}
{* *! version 4.07  David Fisher  15sep2023}{...}
{vieweralsosee "metan" "help metan"}{...}
{vieweralsosee "forestplot" "help forestplot"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "ipdmetan" "help ipdmetan"}{...}
{vieweralsosee "ipdover" "help ipdover"}{...}
{viewerjumpto "Syntax" "metani##syntax"}{...}
{viewerjumpto "Description" "metani##description"}{...}
{viewerjumpto "Options" "metani##options"}{...}
{viewerjumpto "Saved results" "metani##saved_results"}{...}
{title:Title}

{phang}
{cmd:metani} {hline 2} Immediate form of {bf:{help metan}}


{marker syntax}{...}
{title:Syntax}

{pstd}
{bf:{help matrix_define:matrix define}}-like syntax:

{p 8 18 2}
{cmd:metani} {bf:(} {it:#}{bf:,} {it:#} [{bf:,} {it:#...}]
                {bf:\} {it:#}{bf:,} {it:#} [{bf:,} {it:#...}] [{bf:\} [{it:...}]] {bf:)}
		[{cmd:,} {it:options}]

{pstd}
{bf:{help tabulate_twoway:tabi}}-like syntax:

{p 8 18 2}
{cmd:metani} {it:#} {it:#} [{it:#...}] {bf:\} {it:#} {it:#} [{it:#...}] [{bf:\} [{it:...}]] {bf:)}
		[{cmd:,} {it:options}]

{pstd}
Using a previously-defined matrix:

{p 8 18 2}
{cmd:metani} {it:A} [{cmd:,} {it:options}]


{synoptset 34 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{cmd:npts(}{it:{help numlist}}{cmd:)}}specify participant numbers for each row of data (study){p_end}
{synopt :{opt rown:ames} [{opt quoted}]}use matrix {help matrix_rownames:{it:rownames}} to label studies in the table and forest plot{p_end}
{synopt :{opt rowf:ullnames} [{opt quoted}]}use matrix {help matmacfunc:{it:rowfullnames}} to label studies in the table and forest plot{p_end}
{synopt :{opt rowe:q} [{opt quoted}]}use matrix {help matrix_rownames:{it:roweqnames}} to label studies in the table and forest plot{p_end}
{synopt :{opt rowt:itle(string)}}specify {help label:variable label} for studies in the table and forest plot{p_end}
{synopt :{opt studyt:itle(string)}}synonym for {opt rowtitle()}{p_end}
{synopt :{opt rowl:abel(string)}}specify {help label:value label} for studies in the table and forest plot{p_end}
{synopt :{opt studyl:abel(string)}}synonym for {opt rowlabel()}{p_end}
{synopt :{opt var:iances}}specify that variances are supplied instead of standard errors{p_end}
{synopt :{it:{help metan##options:metan_options}}}any {bf:{help metan}} options except {opt npts()}
and others requiring a {it:varname}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:metani} performs meta-analysis on figures supplied directly to the command,
and is intended for situations where a quick calculation of the pooled effect of a small number of studies
is desired, without the relevant data being entered into variables.
It may also be useful for constructing a forest plot of estimates from a regression or from {bf:{help margins}},
by passing to {cmd:metani} a matrix derived from a coefficient vector and variance-covariance matrix.
{cmd:metani} is not a true immediate command (see {help immed}) since by default it leaves behind
the same {help metan##saved_results:new variables} as does {cmd:metan} (although this may be suppressed with {opt nokeepvars}).
However, the functionality is otherwise similar.

{pstd}
Data may be supplied in any of the structures accepted by {bf:{help metan}}.
In other words, each row of data (assumed to represent a study or trial) must contain two, three, four or six elements.
If two or three elements, participant numbers may be supplied in the form of a {it:{help numlist}} to the {opt npts()} option.


{marker options}{...}
{title:Options}

{phang}
{cmd:npts(}{it:{help numlist}}{cmd:)} specifies the number of participants associated with each study, for display in tables and forest plots.

{phang}
{opt rownames}, {opt rowfullnames}, {opt roweq} extract the row names, {it:fullname}s (defined as {it:roweqname}{bf::}{it:rowname})
or equation names from matrix {it:A} to form the study names (c.f. {opt study(varname)} in {bf:{help metan}}).
In the absence of one of these options, or if row names are not set,
then observations (rows) will be labelled sequentially as "1", "2", etc.

{pmore}
{opt quoted}, used with any of the above, specifies that the contents of the {it:row}[{it:eq}]{it:name}s may contain spaces,
and therefore should be {help matmacfunc:enclosed in double quotes} during manipulation.
(Note that such quotes will {ul:not} appear on-screen or in the forest plot.)

{phang}
{opt rowtitle(string)} (or its synonym, {opt studytitle(string)}) specifies a title for the observations extracted from the matrix,
equivalent to the {help label:variable label} of {opt study(varname)} in {bf:{help metan}}.
If not supplied, the default variable label "Matrix rowname" is used.

{phang}
{opt rowlabel(string)} (or its synonym, {opt studylabel(string)}) applies an existing {help label:value label} to numerical values
stored in the {it:row}[{it:eq}]{it:name}s of the matrix, if applicable; or to the default sequential numbering (see above under {opt rownames}).

{phang}
{opt variances} specifies that the second of two columns supplied to {cmd:metani} contains variances rather than standard errors.
This may be useful if passing a matrix to {cmd:metani} which was derived from a coefficient vector and variance-covariance matrix.


{marker saved_results}{...}
{title:Saved results}

{pstd}
By default, {cmd:metani} adds the same same {help metan##saved_results:new variables} to the data set
and saves the same information in {bf:r()} as does {cmd:metan}.


{title:Author}

{pstd}
David Fisher, MRC Clinical Trials Unit at UCL, London, UK.

{pstd}
Email {browse "mailto:d.fisher@ucl.ac.uk":d.fisher@ucl.ac.uk}


