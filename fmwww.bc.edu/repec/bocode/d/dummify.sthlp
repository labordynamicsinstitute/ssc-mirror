{smcl}
{* version 1.0.0  10jun2026  Gorkem Aksaray <aksarayg@tcd.ie>}{...}
{viewerjumpto "Syntax" "dummify##syntax"}{...}
{viewerjumpto "Description" "dummify##description"}{...}
{viewerjumpto "Options" "dummify##options"}{...}
{viewerjumpto "Examples" "dummify##examples"}{...}
{viewerjumpto "Stored results" "dummify##results"}{...}
{viewerjumpto "Author" "dummify##author"}{...}
{vieweralsosee "gautils" "help gautils"}{...}
{cmd:help dummify}{right: {browse "https://github.com/gaksaray/stata-gautils/"}}
{hline}

{title:Title}

{phang}
{bf:dummify} {hline 2} Create indicator variables with automatic variable labels


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:dummify} {varname} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opt stub(name)}}prefix for the new indicator variables; default is {it:varname}{p_end}
{synopt :{opt label(string)}}stem used in the variable labels; default is the variable label of {it:varname}{p_end}

{syntab:Base category}
{synopt :{opt base}}omit the lowest level, creating no indicator for it{p_end}
{synopt :{opt base(#)}}omit the level whose value is {it:#}{p_end}

{syntab:Display}
{synopt :{opt force}}proceed even when {it:varname} has more than 100 distinct levels{p_end}
{synopt :{opt all}}show every row of the summary table{p_end}

{syntab:Positioning}
{synopt :{it:order_options}}{opt f:irst}, {opt l:ast}, {opt b:efore(varname)}, {opt a:fter(varname)}; see {helpb order}{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:dummify} creates a set of indicator (0/1) variables from a categorical
variable, one for each level, and labels each one automatically in the form
{it:"variable label = value label"}. It also reports a compact summary table
listing each level, its value label, and the indicator created for it.
Essentially, it is a more convenient implementation of
{helpb tabulate oneway:tabulate}{cmd:, generate()}, producing indicators that
carry meaningful variable labels rather than the bare stems that
{cmd:tabulate, generate()} leaves behind.

{pstd}
{varname} must be numeric and contain only non-negative integer values. By
default an indicator is created for every level; {opt base} or {opt base(#)}
designates one level as an omitted reference category. An indicator equals 1
where {it:varname} takes the corresponding value and 0 elsewhere, and is left
missing wherever {it:varname} is missing.

{marker options}{...}
{title:Options}

{phang}
{cmd:stub(}{it:name}{cmd:)} specifies the prefix for the new indicator
variables. The default is {it:varname}. Each indicator is named
{it:stub}{it:#}, such as {cmd:region1} or {cmd:region2}.

{pmore}
When {it:stub} ends in a digit, an underscore is inserted between the {it:stub}
and the level so the value stays legible: {cmd:region1} yields {cmd:region1_1}
rather than the ambiguous {cmd:region11}.

{phang}
{cmd:label(}{it:string}{cmd:)} specifies the stem used to build the variable
labels, which take the form {it:"string = value label"}. The default is the
variable label of {varname}, or its name if it has no variable label.

{phang}
{cmd:base} designates the lowest level of {varname} as the omitted base
category. No indicator is created for it.

{phang}
{cmd:base(}{it:#}{cmd:)} designates the level whose {it:value} is {it:#} as the
omitted base category, in the same way that {bf:ib}{it:#}{bf:.} sets the base
level for factor variables. It is an error to specify a value that does not
occur in {varname}. {opt base} and {opt base()} may not be combined.

{phang}
{cmd:force} allows {cmd:dummify} to proceed when {varname} has more than 100
distinct levels. Before creating any variables, {cmd:dummify} checks that the
whole operation can complete, so it never leaves a half-built set behind. It
stops when {varname} has more than 100 distinct levels (a safeguard against
accidental use on a near-continuous variable, which {opt force} overrides), or
when too few free variable slots remain; see {helpb memory}.

{phang}
{cmd:all} shows every row of the summary table. By default, when {varname} has
more than 21 levels, only the first and last 10 are shown (plus the base
category, if any), with the omitted rows collapsed into a single divider.

{phang}
{it:order_options} are {opt f:irst}, {opt l:ast}, {opt b:efore(varname)}, and
{opt a:fter(varname)}, which position the new indicators in the dataset; see
{helpb order}. By default the indicators are placed immediately after
{varname}.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang}{cmd:. sysuse lifeexp, clear}{p_end}

{pstd}One indicator per region, placed first in the dataset{p_end}
{phang}{cmd:. dummify region, first}{p_end}

{pstd}Custom stub and label, with value 2 as the omitted base category{p_end}
{phang}{cmd:. dummify region, stub(cont) label(Continent) base(2)}{p_end}

{pstd}A variable with no value labels; the label stem is paired with each value{p_end}
{phang}{cmd:. dummify lexp, label(Life expectancy)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:dummify} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(k)}}number of indicator variables created{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(varname)}}name of the source variable{p_end}
{synopt:{cmd:r(indicators)}}names of the indicator variables created{p_end}
{synopt:{cmd:r(base)}}base category value, if any{p_end}
{p2colreset}{...}


{marker author}{...}
{title:Author}

{pstd}
Gorkem Aksaray, Trinity College Dublin.{p_end}
{p 4}Email: {browse "mailto:aksarayg@tcd.ie":aksarayg@tcd.ie}{p_end}
{p 4}Personal Website: {browse "https://sites.google.com/site/gorkemak/":sites.google.com/site/gorkemak}{p_end}
{p 4}GitHub: {browse "https://github.com/gaksaray/":github.com/gaksaray}{p_end}
