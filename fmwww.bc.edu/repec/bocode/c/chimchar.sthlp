{smcl}
{* *! version 1.0.0  21august2022}{...}
{p2colset 1 17 19 2}{...}
{p2col:{bf:chimchar} {hline 2} Thoroughly clean string variables}{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

	{cmd:chimchar} {varlist} {cmd:,} {c -(}{opt numokay}{c |}{opt numremove}{c |}{opt numonly}{c )-} [{opt dpswitch}]

{synoptset 32 tabbed}{...}
{marker chimchar_options}{...}
{synopthdr :chimchar_options}
{synoptline}
{p2coldent :* {opt numokay}}keeps letters and numeric characters{p_end}
{p2coldent :* {opt numremove}}keeps only letters{p_end}
{p2coldent :* {opt numonly}}keeps only numeric characters{p_end}

{synopt :{cmdab:dpswitch}}switches commas to periods and periods to commas before running the rest of the command{p_end}
{synoptline}
{pstd}* Either {opt numokay}, {opt numremove}, or {opt numonly} is required.
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{opt chimchar} stands for CHanging IMpractical CHARacters. It removes characters from string variables that can impede functions like {opt destring} and {opt reclink}. You can choose to remove only special characters, remove both special characters and numeric characters, or remove all non-numeric characters altogether. If letters are not removed, special characters that are based on Latin letters are replaced with their closest ASCII (plain Latin) letter counterpart(s); for example, "Æ", "š" and "ĸ" would become "ae", "s", and "k", respectively.


{marker options}{...}
{title:Options}

{pstd}
Exactly one of {cmd:numokay}, {cmd:numremove}, or {cmd:numonly} must be specified. If more than one or none of these are specified, the command returns an error.

{phang}
{cmd:numokay} removes only special characters from the string variable(s) in {varlist}. It changes Latin letter-based characters to their simplest Latin equivalent, turning "Æ", "Ž" and "ĸ" into "ae", "z" and "k", respectively, while also removing special characters like quotes, parentheses, commas, and asterisks. It does not remove any numbers, the decimal point, or the minus sign. Therefore, using {cmd:numokay} would turn the string "2šec.(8)" into "2sec.8". This could be useful for cleaning variables like usernames that could contain mixtures of numbers and letters.

{phang}
{cmd:numremove} removes both special characters and numeric characters from the string variable(s) in {varlist}. It changes Latin letter-based characters to their simplest Latin equivalent, turning "Æ", "Ž" and "ĸ" into "ae", "z" and "k", respectively, while also removing special characters (like quotes, parentheses, commas, and asterisks), numbers, the decimal point, and the minus sign. Therefore, using {cmd:numremove} would turn the string "2šec.(8)" into "sec". This could be useful for cleaning variables like first names that should only contain letters.

{phang}
{cmd:numonly} removes both special characters and letters from the string variable(s) in {varlist}. It removes all Latin letter-based characters and all special characters (like quotes, parentheses, commas, and asterisks), leaving only numbers, the decimal point, and the minus sign. Therefore, using {cmd:numremove} would turn the string "2šec.(8)" into "2.8". This could be useful for preparing numeric variables for a future {opt destring}.

{phang}
{cmd:dpswitch} changes all commas to decimal points and all decimal points to commas prior to running the rest of the command. It should be used if your dataset contains string variables that should be numeric and comes from a place that uses the decimal comma.

{marker remarks}{...}
{title:Remarks}

{pstd}
As of right now, I don't have the programming skills to write an {cmd:ignore} option that would let you specify specific characters to keep. If you'd like to collaborate on that as an addition to this command, email me at labhours@tmorg.org and we'll get in contact!

{pstd}