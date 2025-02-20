{smcl}
{* *! version 2.0.2  19february2025}{...}
{p2colset 1 17 19 2}{...}
{p2col:{bf:chimchar} {hline 2} Thoroughly clean string variables}{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

	{cmd:chimchar} [{varlist}] {cmd:,} {c -(}{opt numokay}{c |}{opt numremove}{c |}{opt numonly}{c )-} [{opt dpswitch}]

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
{opt chimchar} stands for CHanging IMpractical CHARacters. It modifies characters in string variables that are unfriendly to functions like {cmd:destring} and {cmd:reclink}. In particular, it can replace special characters that are based on Latin letters with their closest plain Latin letter counterpart(s); for example, "Æ", "š" and "ĸ" become "ae", "s", and "k", respectively. You can choose to change special characters, fix special characters and remove numeric characters, or remove all non-numeric characters altogether.

{pstd}
If you do not specify {varlist}, the command will run over all variables in the currently loaded dataset.


{marker options}{...}
{title:Options}

{pstd}
Exactly one of {cmd:numokay}, {cmd:numremove}, or {cmd:numonly} must be specified. If more than one or none of these are specified, the command returns an error. 

{phang}
{cmd:numokay} changes Latin letter-based characters to their simplest Latin equivalent, turning "Æ", "Ž" and "ĸ" into "ae", "z" and "k", respectively, while also removing special characters like quotes, parentheses, commas, and asterisks. It does not remove any numbers, the decimal point, or the minus sign. Therefore, using {cmd:numokay} would turn the string "-2šec..(8)" into "-2sec..8". This could be useful for cleaning variables like usernames or addresses that could contain mixtures of numbers and letters.

{phang}
{cmd:numremove} removes both special characters and numeric characters from the string variable(s) in {varlist}. It changes Latin letter-based characters to their simplest Latin equivalent, turning "Æ", "Ž" and "ĸ" into "ae", "z" and "k", respectively, while also removing special characters (like quotes, parentheses, commas, and asterisks), numbers, the decimal point, and the minus sign. Therefore, using {cmd:numremove} would turn the string "-2šec..(8)" into "sec". This could be useful for cleaning variables like people's names that should only contain letters.

{phang}
{cmd:numonly} removes both special characters and letters from the string variable(s) in {varlist}. It removes all Latin letter-based characters and all special characters like quotes, parentheses, commas, and asterisks, leaving only numbers, a single decimal point (if present), and a single minus sign (if present). Therefore, using {cmd:numremove} would turn the string "-2šec..(8)" into "-2.8". This could be useful for preparing variables that should be numeric for a future {cmd:destring}.

{phang}
{cmd:dpswitch} changes all commas to decimal points and all decimal points to commas prior to running the rest of the command. It should be used if your dataset contains string variables that should be numeric that use the comma as a decimal delineator.

{marker remarks}{...}
{title:Remarks}

{pstd}
As of right now, I don't have the programming skills to write an {cmd:ignore} option that would let you specify specific characters to keep. If you'd like to collaborate on that as an addition to this command, email me at tommy@tmorg.org and I will be in contact!

{pstd}