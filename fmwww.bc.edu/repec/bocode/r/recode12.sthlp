{smcl}
{* *! version 1.1.0  19jul2026}{...}
{vieweralsosee "recode" "help recode"}{...}
{vieweralsosee "encode" "help encode"}{...}
{vieweralsosee "label values" "help label_values"}{...}
{title:Title}

{phang}
{bf:recode12} {hline 2} Standardize numeric 1/2 variables and corresponding two-category string variables as labeled 0/1 indicators

{title:Syntax}

{p 8 17 2}
{cmd:recode12} [{varlist}]{cmd:,} {opt yesvalue(#)} [{opt suffix(name)} {opt replace} {opt display}]

{title:Description}

{pstd}
{cmd:recode12} standardizes eligible numeric variables coded 1/2 and eligible
two-category string variables as labeled 0/1 indicators. For string variables,
the first and second distinct nonmissing categories serve as the counterparts
of numeric source codes 1 and 2. Numeric and string variables may be processed
alone or together with the same command.

{pstd}
An eligible numeric variable contains both 1 and 2, may contain ordinary system
missing ({cmd:.}), and contains no other values. A variable containing only 1
plus {cmd:.}, only 2 plus {cmd:.}, an extended missing value ({cmd:.a} through
{cmd:.z}, including {cmd:.m} or {cmd:.n}), any other numeric value, or no
nonmissing observations is skipped.

{pstd}
An eligible string variable contains exactly two distinct nonmissing categories,
and both must be observed. For this eligibility check, {cmd:recode12} treats an
empty string, a whitespace-only string, and the trimmed literal string {cmd:"."}
as missing. It scans observations in their current order, ignores these missing
representations and repeated categories, and treats the first distinct
nonmissing category encountered as source category 1 and the second as source
category 2. A string variable containing only one category plus missing values,
no nonmissing categories, or any additional distinct value, including a marker
such as {cmd:m}, {cmd:n}, {cmd:.m}, or {cmd:.n}, is skipped.

{pstd}
The string rule corresponds directly to the numeric rule. For numeric variables,
source categories 1 and 2 are the literal values 1 and 2. For string variables,
the first and second distinct nonmissing categories encountered are treated as the
counterparts of numeric source values 1 and 2. The same {opt yesvalue()} is then
applied without a separate string mapping: {opt yesvalue(1)} maps source
category 1 to 1 ({it:Yes}) and source category 2 to 0 ({it:No});
{opt yesvalue(2)} maps source category 1 to 0 and source category 2 to 1.
Ordinary numeric missing values and the string missing representations described
above remain missing in the generated numeric result.

{pstd}
By default, the command creates a new byte variable and leaves the source
variable unchanged. If {it:varlist} is omitted, every variable in the dataset
is examined and only eligible variables are processed.

{pstd}
After recoding, the command verifies every converted observation against the
selected mapping and confirms that every nonmissing result is 0 or 1. It
reports success only after all verification checks pass.

{pstd}
By default, the Results window displays only the mapping rule and the
verification result. Detailed numeric and string-source counts and resulting
variable names are available with {opt display} and are always stored in
{cmd:r()}.

{title:Options}

{phang}
{opt yesvalue(#)} is required. The argument must be 1 or 2 and selects which
source category becomes 1 ({it:Yes}). It applies uniformly to every eligible
numeric and string variable in the command.

{phang}
{opt suffix(name)} specifies the suffix for generated variables. The default is
{cmd:suffix(_01)}. The resulting name must be a legal, unused Stata variable
name.

{phang}
{opt replace} overwrites each eligible source variable with its recoded 0/1
values instead of creating a new variable. For eligible string variables this
changes the source variable from string to numeric while retaining its name.
{opt replace} may not be combined with {opt suffix()} and should be used only
when the original values are no longer needed.

{phang}
{opt display} reports the number and resulting names of standardized numeric
and string-source variables. Names are printed in groups of no more than seven
per line. In {opt replace} mode, these are the retained source-variable names.

{title:Remarks}

{pstd}
The command determines eligibility from observed values, not from variable
names or substantive meaning. It does not attempt to decide whether a category
is favorable, unfavorable, affirmative, or negative.

{pstd}
For numeric variables, source categories 1 and 2 are the observed values 1 and
2. When those values have category labels, the category selected by
{opt yesvalue()} is stated in the generated variable label. If no category
label is available, the label states the numeric condition explicitly.

{pstd}
For string variables, source-category order is based on first occurrence among
trimmed nonmissing observations. For example, for the sequence {cmd:"."},
{it:Plum}, blank, {it:Plum}, {it:Peach}, source category 1 is {it:Plum} and
source category 2 is {it:Peach}. The dot and blank remain missing. With
{cmd:yesvalue(2)}, Plum is mapped to 0 and Peach to 1. With
{cmd:yesvalue(1)}, the direction is reversed.

{pstd}
Because string-category order follows the current observation order, sorting
the dataset before running {cmd:recode12} can change which string category is
source category 1. The selected category is stated in the generated variable
label.

{pstd}
Generated or replaced variables use the shared value label
{cmd:recode12_NoYes}, defining 0 as {it:No} and 1 as {it:Yes}. A generated
variable label begins with {it:Recoded}, identifies the category mapped to 1,
and states {it:(0=No; 1=Yes)}.

{pstd}
Only after every post-recode check passes, the command creates or updates the
string variable {cmd:recode12_status} and fills every observation with
{it:confirmed}. A preexisting variable with this name is reused only when it was
previously created by {cmd:recode12}; otherwise the command stops. This status
confirms computational consistency, not the substantive suitability of the
user's chosen direction.

{title:Examples}

{pstd}
Load the supplied example dataset:

{phang2}{cmd:. use recode12_example_data.dta, clear}{p_end}

{pstd}
Process eligible numeric variables only:

{phang2}{cmd:. recode12 female employed, yesvalue(2)}{p_end}

{pstd}
Process eligible string variables only:

{phang2}{cmd:. recode12 exam_result_text preferred_fruit, yesvalue(2)}{p_end}

{pstd}
Process numeric and string variables together:

{phang2}{cmd:. recode12 female employed exam_result_text preferred_fruit, yesvalue(2)}{p_end}

{pstd}
Examine all variables and process every eligible numeric and string variable:

{phang2}{cmd:. recode12, yesvalue(2)}{p_end}

{pstd}
Overwrite eligible source variables:

{phang2}{cmd:. recode12 employed exam_result_text, yesvalue(2) replace}{p_end}

{title:Stored results}

{pstd}
{cmd:recode12} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(n_recoded)}}number of variables recoded{p_end}
{synopt:{cmd:r(yesvalue)}}source category mapped to 1 ({it:Yes}){p_end}
{synopt:{cmd:r(verified)}}1 if at least one variable was recoded and all checks passed; otherwise 0{p_end}
{synopt:{cmd:r(recoded)}}generated or replaced variables{p_end}
{synopt:{cmd:r(source)}}all eligible source variables{p_end}
{synopt:{cmd:r(numeric_source)}}eligible numeric source variables{p_end}
{synopt:{cmd:r(string_source)}}eligible string source variables{p_end}
{synopt:{cmd:r(numeric_recoded)}}generated or replaced numeric variables{p_end}
{synopt:{cmd:r(string_recoded)}}generated or replaced string-source variables{p_end}
{synopt:{cmd:r(n_numeric_recoded)}}number of numeric variables recoded{p_end}
{synopt:{cmd:r(n_string_recoded)}}number of string-source variables recoded{p_end}
{synopt:{cmd:r(skipped)}}examined variables not meeting the applicable rule{p_end}
{synopt:{cmd:r(value_label)}}name of the attached value label{p_end}
{synopt:{cmd:r(status_variable)}}name of the confirmation variable{p_end}

{title:Version history}

{phang}
{bf:1.1.0, 19 July 2026.} Added eligible two-category string variables, mixed
numeric/string processing, first-occurrence string category ordering, explicit
string-missing rules, and type-specific stored results. The original numeric
1/2 eligibility and {opt yesvalue()} mapping rules remain unchanged.

{phang}
{bf:1.0.0, 12 July 2026.} Initial SSC release for eligible numeric variables
coded 1/2.

{title:Author}

{pstd}
Hao Ma{break}
Email: {browse "mailto:shouhuoxiwang2027@gmail.com":shouhuoxiwang2027@gmail.com}

{title:Citation}

{pstd}
If you use {cmd:recode12} in published work, please cite:

{phang}
Ma, Hao. 2026. {it:recode12: A Stata command for standardizing numeric 1/2
variables and corresponding two-category string variables as labeled 0/1
indicators}. Version 1.1.0.

{title:License}

{pstd}
{cmd:recode12} is distributed under the MIT License. Copyright (c) 2026 Hao Ma.

{title:Also see}

{psee}
Manual: {manhelp recode D}, {manhelp encode D}, {manhelp label D}
