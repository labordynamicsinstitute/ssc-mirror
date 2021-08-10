{smcl}
{* *! version 1.0  David Fisher  11may2017}{...}
{vieweralsosee "admetan" "help admetan"}{...}
{vieweralsosee "ipdmetan" "help ipdmetan"}{...}
{vieweralsosee "ipdover" "help ipdover"}{...}
{vieweralsosee "forestplot" "help forestplot"}{...}
{vieweralsosee "metan" "help metan"}{...}
{viewerjumpto "Syntax" "admetani##syntax"}{...}
{viewerjumpto "Description" "admetani##description"}{...}
{viewerjumpto "Options" "admetani##options"}{...}
{viewerjumpto "Saved results" "admetani##saved_results"}{...}
{title:Title}

{phang}
{cmd:admetani} {hline 2} Immediate form of {bf:{help admetan}}


{marker syntax}{...}
{title:Syntax}

{pstd}
{bf:{help matrix_define:matrix define}}-like syntax:

{p 8 18 2}
{cmd:admetani} {bf:(} {it:#}{bf:,} {it:#} [{bf:,} {it:#...}]
                {bf:\} {it:#}{bf:,} {it:#} [{bf:,} {it:#...}] [{bf:\} [{it:...}]] {bf:)}
		[{cmd:,} {it:options}]

{pstd}
{bf:{help tabulate_twoway:tabi}}-like syntax:

{p 8 18 2}
{cmd:admetani} {it:#} {it:#} [{it:#...}] {bf:\} {it:#} {it:#} [{it:#...}] [{bf:\} [{it:...}]] {bf:)}
		[{cmd:,} {it:options}]

{pstd}
Using a previously-defined matrix:

{p 8 18 2}
{cmd:admetani} {it:A} [{cmd:,} {it:options}]


{synoptset 34 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{it:{help admetan##options:admetan_options}}}any {bf:{help admetan}} options except {opt npts()}
and others requiring a {it:varname}{p_end}
{synopt :{bf:npts(}{it:{help numlist}}{bf:)}}specify participant numbers for each row of data (study){p_end}
{synopt :{opt rown:ames}}use matrix rownames to label studies in the table and forest plot{p_end}
{synopt :{opt rowt:itle(string)}}specify "variable label" for studies in the table and forest plot{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:admetani} performs meta-analysis on figures supplied directly to the command,
and is intended for situations where a quick calculation of the pooled effect of a small number of studies
is desired, without the relevant data being entered into variables.
{cmd:admetani} is not a true immediate command (see {help immed}) since by default it leaves behind
the same {help admetan##saved_results:new variables} as does {cmd:admetan} (although this may be suppressed with {opt nokeepvars}).
However, the functionality is otherwise similar.

{pstd}
Data may be supplied in any of the structures accepted by {bf:{help admetan}}.
In other words, each row of data (assumed to represent a study or trial) must contain two, three, four or six elements.
If two or three elements, participant numbers may be supplied in the form of a {it:{help numlist}} to the {opt npts()} option.


{marker options}{...}
{title:Options}

{phang}
{bf:npts(}{it:{help numlist}}{bf:)} specifies the number of participants associated with each study, for display in tables and forest plots.

{phang}
{opt rownames} extracts {help matrix_rownames:row names} from matrix {it:A} to form the study names (c.f. {opt study(varname)} in {bf:{help admetan}}).
If row names are not set, the default names {bf:r1}, {bf:r2} etc. will be used.

{phang}
{opt rowtitle(string)} specifies a title for the study names extracted from matrix row names,
equivalent to the {help label:variable label} of {opt study(varname)} in {bf:{help admetan}}.


{marker saved_results}{...}
{title:Saved results}

{pstd}
By default, {cmd:admetani} adds the same same {help admetan##saved_results:new variables} to the data set
and saves the same information in {bf:r()} as does {cmd:admetan}.


{title:Author}

{pstd}
David Fisher, MRC Clinical Trials Unit at UCL, London, UK.

{pstd}
Email {browse "mailto:d.fisher@ucl.ac.uk":d.fisher@ucl.ac.uk}


