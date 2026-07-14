{smcl}
{* *! version 1.0.0  12jul2026}{...}
{vieweralsosee "recode" "help recode"}{...}
{vieweralsosee "label values" "help label_values"}{...}
{title:Title}

{phang}
{bf:recode12} {hline 2} Standardize 1/2-coded variables as labeled 0/1 indicators

{title:Syntax}

{p 8 17 2}
{cmd:recode12} [{varlist}]{cmd:,} {opt yesvalue(#)} [{opt suffix(name)} {opt replace}]

{title:Description}

{pstd}
{cmd:recode12} identifies numeric variables whose values are 1, 2, or ordinary
system missing ({cmd:.}), with both 1 and 2 observed. Variables containing an
extended missing value ({cmd:.a} through {cmd:.z}), any other numeric value,
only one of the two categories, or no nonmissing observations are skipped.

{pstd}
For each eligible variable, {cmd:recode12} maps the source value selected by
{opt yesvalue()} to 1 and the other source value to 0, preserves numeric missing
values, and assigns the value label 0 {it:No} and 1 {it:Yes}. The required
{opt yesvalue()} option records the mapping explicitly. By default, the command
creates a new byte variable and leaves the source variable unchanged.

{pstd}
If {it:varlist} is omitted, all numeric variables in the dataset are examined.
The mapping must still be specified with {opt yesvalue()}.

{pstd}
After recoding, the command verifies every converted observation against the
selected mapping, confirms that ordinary system missing values were preserved,
and confirms that every nonmissing result is 0 or 1. It reports
success only after all verification checks pass.

{title:Options}

{phang}
{opt yesvalue(#)} is required and specifies which source value becomes 1
({it:Yes}). The argument must be 1 or 2. Specify
{cmd:yesvalue(1)} to map source 1 to Yes/1, or {cmd:yesvalue(2)} to map source 2
to Yes/1.

{phang}
{opt suffix(name)} specifies the suffix for generated variables. The default is
the neutral suffix {cmd:suffix(_01)}. Suffixes should describe the coding format
rather than assume category meaning. The resulting name must be a legal, unused
Stata variable name.

{phang}
{opt replace} changes eligible source variables in place. It may not be combined
with {opt suffix()}. Because this operation overwrites values and replaces the
attached variable and value labels, users should normally retain the default behavior.

{title:Remarks}

{pstd}
The command determines eligibility from values, not from the meaning of a
variable. The category selected by {opt yesvalue()} becomes 1 and the other
category becomes 0. When the source values have category labels, those meanings
are stated explicitly in the generated variable label.

{pstd}
For example, if {cmd:sex} is coded 1 Female and 2 Male, {cmd:yesvalue(1)}
generates 1 for Female and 0 for Male, whereas {cmd:yesvalue(2)} generates 1 for
Male and 0 for Female. {cmd:recode12} does not infer category meaning. A
generated variable begins with {it:Recoded}, names the category mapped to
Yes/1, and states the common coding explicitly. For example,
{cmd:yesvalue(1)} produces {it:Recoded Female (0=No; 1=Yes)}.
If the selected source value has no category label, the generated variable
label states the numeric condition explicitly, for example
{it:Recoded x == 1 (0=No; 1=Yes)}.

{pstd}
Generated variables use the shared value label {cmd:recode12_NoYes}, defining
0 as {it:No} and 1 as {it:Yes}. Its name is returned in {cmd:r(value_label)}.

{pstd}
Only after every post-recode check passes, the command creates or updates the
string variable {cmd:recode12_status} and fills every observation with
{it:confirmed}. If verification fails, the command reports an error and does
not write {it:confirmed}. A preexisting variable with this name is reused only
when it was previously created by {cmd:recode12}; otherwise the command stops
to avoid overwriting user data. This status confirms computational consistency
with the specified mapping; it does not establish that the user's substantive
choice of {opt yesvalue()} is correct for the research question.

{title:Examples}

{pstd}
The example dataset supplied with this package can be loaded as follows:

{phang2}{cmd:. use example_data.dta, clear}{p_end}
{phang2}{cmd:. recode12 employed owns_home insured, yesvalue(2)}{p_end}
{phang2}{cmd:. recode12 female, yesvalue(1)}{p_end}
{phang2}{cmd:. recode12 white veteran owns_car, yesvalue(2) suffix(_bin)}{p_end}
{phang2}{cmd:. recode12 female, yesvalue(2) suffix(_male)}{p_end}
{phang2}{cmd:. recode12 employed owns_home, yesvalue(2) replace}{p_end}
{phang2}{cmd:. recode12 female, yesvalue(2) replace}{p_end}

{pstd}
For {cmd:yesvalue(1)}, the command displays
{cmd:mapping: source 1 -> 1 (Yes); source 2 -> 0 (No)}. For
{cmd:yesvalue(2)}, it displays
{cmd:mapping: source 1 -> 0 (No); source 2 -> 1 (Yes)}.

{title:Stored results}

{pstd}
{cmd:recode12} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(n_recoded)}}number of variables recoded{p_end}
{synopt:{cmd:r(yesvalue)}}source value mapped to 1 ({it:Yes}){p_end}
{synopt:{cmd:r(verified)}}1 if at least one variable was recoded and all checks passed; otherwise 0{p_end}
{synopt:{cmd:r(recoded)}}generated or replaced variables{p_end}
{synopt:{cmd:r(source)}}eligible source variables{p_end}
{synopt:{cmd:r(skipped)}}examined variables not meeting the rule{p_end}
{synopt:{cmd:r(value_label)}}name of the attached value label{p_end}
{synopt:{cmd:r(status_variable)}}name of the confirmation variable{p_end}

{title:Author}

{pstd}
Hao Ma{break}
Email: {browse "mailto:shouhuoxiwang2027@gmail.com":shouhuoxiwang2027@gmail.com}

{title:Citation}

{pstd}
If you use {cmd:recode12} in published work, please cite:

{phang}
Ma, Hao. 2026. {it:recode12: A Stata command for standardizing 1/2-coded
variables as labeled 0/1 indicators}. Version 1.0.0.

{title:License}

{pstd}
{cmd:recode12} is distributed under the MIT License. Copyright (c) 2026 Hao Ma.

{title:Also see}

{psee}
Manual: {manhelp recode D}, {manhelp label D}
