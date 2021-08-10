{smcl}
{* 27oct2011}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy

{pstd}{bf:tone} {c -} Type-appropriate bivariate associations (Table One)

{title:Syntax}

{pmore}
{cmdab:tone} {varname} [{it:{help varelist}}] {ifin} [{cmd:,} {it:options}]

{synoptset 25}
{synopt:{help varelist##mods:Modifiers}}Description{p_end}
{synoptline}
{synopt:{cmd:(}{opt con:tinuous}{cmd:)}}Treat as continuous variable.{p_end}
{synopt:{cmd:(}{opt cat:egorical}{cmd:)}}Treat as categorical variable.{p_end}
{synopt:{cmd:(}{opt di:chotomous} [{it:expression}]{cmd:)}}Treat as dichotomous variable.{p_end}

{p2col 5 16 0 2:{bf:Example:}}{cmd:tone mainvar (cat) a w z (con)d-h}{p_end}
{p 15 15}would treat variables {cmd:a}, {cmd:w}, and {cmd:z} as categorical and variables {cmd:d} to {cmd:h} as continuous.

{synoptset 16}
{synopthdr}
{synoptline}
{synopt:{opt uni:var}}Report {it:only} overall summary. (treats {varname} as part of {it:{help varelist}}){p_end}

{synopt:{cmdab:cat:cut}}Set cutoff # of levels to define as categorical variable.{p_end}
{synopt:{cmdab:d:ecimal}}Extend percentages to 1 tenth of a percent.{p_end}
{synopt:{cmdab:std:iff}}Report standardized differences instead of p-values{p_end}
{synopt:{opt hi(value)}}Highlight low p-values or high standardized diffs{p_end}
{synopt:{opt sec:tion(details)}}Break {it:{help varelist}} into sections{p_end}

{synopt:{opt pub:lication}}Adjusts the formatting to more closely match common publication requirements.{p_end}
INCLUDE help tabel_options1


{title:Description}

{pstd}For each variable of {it:{help varelist}}, {cmd:tone} summarizes the variable, broken down by levels of {varname}, and includes a statistical test of association with {varname} (but see {opt uni:var}, below).

{pstd}The display and statistics for each variable of {it:{help varelist}} depend on its {bf:type}: continuous, categorical, or dichotomous. The {bf:type} is determined by the {help varelist##mods:modifier},
if present, or as described in {help tone##remarks:Remarks}, below.

{title:Modifiers}

{pstd}For {cmd:con}tinuous variables, the mean and sd are reported, along with a p-value from a one-way anova.

{pstd}For {cmd:cat}egorical variables, percent at each value is reported, along with a p-value from a chi-squared.

{pstd}For {cmd:di}chotomous variables, the percent "true" is shown, along with a p-value from a chi-sqaured.

{pmore}By default, "true" is any value other than zero or missing; however, "true" can be defined in the attached {it:expression}.

{pmore}If an {it:expression} is appended, nonzero, nonmissing values of {it:expression} will be treated as true. {it:expression} can include {cmd:#V} as a placeholder for the relevant variable. For example:

{phang2}o-{space 2}{cmd:tone dv date(di !mi(#V))} will treat {cmd:date} as a dichotomous variable, with true defined as not missing.

{phang2}o-{space 2}{cmd:tone likert(di #V>=3)} will treat {cmd:likert} as a dichotomous variable, with true defined as {cmd:likert}>=3.

{title:Options}

{phang}{cmdab:uni:var} treats {varname} as part of {it:{help varelist}}, and simply summarizes all variables overall, with no separate categories, and no p-values or standardized differences.

{phang}{cmdab:cat:cut(integer)} defines a cutoff for the number of unique values, below which a variable will be treated as categorical. See {help tone##remarks:Remarks}, below.

{phang}{cmdab:d:ecimal} will expand percentages to tenths of a percent.

{phang}{opt std:iff} reports standardized differences instead of p-values. For categorical variables, a difference is reported for each value of the variable.
If there are more than 2 levels of {help varname}, the greatest difference beween means is used, and the variance is pooled across all levels.

{phang}{opt hi(value)} will highlight p-values or standardized differences that cross the specified threshold: p-values less than or equal to {it:value}, or st-diffs greater than or equal to {it:value} are highlighted. {p_end}

{phang}{opt sec:tion(details)} can be specified multiple times to divide the display into multiple sections. The syntax for {it:details} is:

{phang3}[{it:text}]{cmd::}{it:section var}

{pmore2}where {it:text} will be displayed as a heading {bf:before} {it:section var}, and {it:section var} must be a variable from {it:{help varelist}}.

{phang}{opt pub:lication} adjusts the formatting: drops the overall N (not missing) for each variable; puts the category-n or sd in parentheses; adds row legends; drops column legends; uses one text color.

INCLUDE help tabel_options2n

{pmore}{it:nl1} governs the stub (row headings) and {it:nl2} governs the column headings.

INCLUDE help tabel_options2v

{pmore}{it:vl1} governs the stub (row headings) and {it:vl2} governs the column headings.

INCLUDE help tabel_out2


{marker remarks}{title:Remarks}

{pstd}String variables are always treated as {bf:type} {cmd:cat}. The {bf:type} of numeric variables is determined as follows:

{phang2}1.  Any {bf:type}s set with {help varelist##mods:modifiers} on the command line are used.{p_end}

{pstd}If {opt cat:cut(integer)} is specified, then:

{phang2}2.{space 2}Variables for which the only non-missing values are 0 and 1 will get the {bf:type} {cmd:di}{p_end}
{phang2}3.{space 2}Those which have less than or equal to {it:integer} (non-missing) unique values will get the {bf:type} {cmd:cat}{p_end}
{phang2}4.{space 2}Those remaining will get the {bf:type} {cmd:con}

{pstd}Otherwise:

{phang2}2. Any {bf:type}s assigned by (a prior) {cmd:tone} are used.{p_end}
{phang2}3. Variables for which the only non-missing values are 0 and 1 will get the {bf:type} {cmd:di}{p_end}
{phang2}4. Those which have a labeled non-missing value will get the {bf:type} {cmd:cat}{p_end}
{phang2}5. Those remaining will get the {bf:type} {cmd:con}

{pstd}{bf:type} assignments are stored with the variables.

{pstd}{bf:type}s can also be used to exclude variables from {cmd:tone} output: Variables with {bf:type}s other than those listed above are dropped from {it:{help varelist}}.
For example, if ID variables etc. were assigned the {bf:type} {cmd:admin}, they would not be included in the command, even if {it:{help varelist}} were {cmd:*}.
(The comparison variable, {varname}, is also ignored as part of {it:{help varelist}}.)

{space 4}{hline 10}
{pstd}The output headings use the symbols {it:mu} and {it:sigma} as shorthand to indicate {it:means} and {it:standard deviations}, without implying the usual exact statistical meanings.
Even more egregiously, Stata output uses {cmd:{c 243}} as a stand-in for sigma.


{title:Examples}

{pstd}{cmd:.tone gender age height weight1-weight5 bdate}

{pstd}{cmd:.tone gender age(cat) (con) weight*, hi(.05)}

{pstd}{cmd:.tone gender *}{p_end}

