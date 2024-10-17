{smcl}
{* *! version 1.0.0  14okt2024}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[D] Datetime conversion" "help datetime conversion"}{...}
{vieweralsosee "[FN] Date and time functions" "help datetime functions"}{...}
{vieweralsosee "[FN] date()" "help date()"}{...}
{vieweralsosee "[FN] birthday()" "help birthday()"}{...}
{vieweralsosee "[FN] age()" "help age()"}{...}
{vieweralsosee "[FN] age_frac()" "help age_frac()"}{...}
{viewerjumpto "Syntax" "gencpr##syntax"}{...}
{viewerjumpto "Description" "gencpr##description"}{...}
{viewerjumpto "Options" "gencpr##options"}{...}
{viewerjumpto "Remarks" "gencpr##remarks"}{...}
{viewerjumpto "Examples" "gencpr##examples"}{...}
{viewerjumpto "Author" "gencpr##contact"}{...}
{title:Title}

{phang}
{bf:gencpr} {hline 2} For users of Danish CPR numbers.  


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:gencpr}
{newvar}
{ifin}
{cmd:,} {opth from(varname)} [{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:* {opth f:rom(varname)}}takes odd patterns of CPR numbers storred in {it:varname} and generates {it:newvar} with the pattern ddmmyy-####{p_end}
{synopt:{opt mod:ulus}}generate variable {it:mod11} with the Modulus-11 test{p_end}
{synopt:{opt gend:er}}generate binary gender variable {it:koen}{p_end}
{synopt:{opt birth:day}}generate variable {it:birthday}{p_end}
{synopt:{opth age:at(varname)}}generate variable {it:age} at the date in {it:varname}{p_end}
{synopt:{opth agef:racat(varname)}}generate variable {it:age_frac}, age incl. its fractional part, at the date in {it:varname}{p_end}
{synopt:{opt gt:100}}use the 7th digit in {newvar} to determine the birth century{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opth f:rom(varname)} is required.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:gencpr} takes most odd patterns of CPR numbers storred in {bf:from({it:varname})} and generates a {it:newvar} containing CPR numbers with the standard pattern {it:ddmmyy-####}. 
{cmd:gencpr} is therefore useful for cleaning your current CPR variabel if it contains many different patterns of CPR numbers. 
Options performs a Modulus-11 test on the new CPR and generates gender, birthday and age.

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opth from(varname)}} is required. {it:varname} must be a {it:string} variable but it may contain mamy different patterns of CPR (e.g. ddmmyyyy-1234, dmmyy-xyz4, d.mm-yy, dd/mmyyyy).

{phang}
{opt modulus} generates a variable {it:mod11}, 
with the results of a Modulus-11 test of CPR validity. 
In {it:mod11}, 0 indicates an invalid CPR number and 1 indicated a valid CPR number. 
The Modulus 11 test will sometimes provide a wrong answer; for example, some CPR patterns (e.g. 000000-0000) will turn out as valid, and after 2007, some CPR munbers are Modulus-11 invalid 
(see {browse "https://da.wikipedia.org/w/index.php?title=Modulus_11&oldid=11133611"}).
So you should only use the Modulus-11 test as a guideline for CPR validity.

{phang}
{opt gender} generates a binary gender variable {it:koen} from the last digit in {it:newvar}. The last digit of the CPR is odd for males and even for females, and {it: koen} is 0 for females and 1 for males. 
If the last digit is not 0-9, {it:koen} is missing.

{phang}
{opt birthday} generates an {it:e_d} variable {it:birthday} form the first 6 numbers in {it:newvar}. 
If for example the CPR is 010160-1234, then {it:birthday} is {it:01jan1960}. 
See {help birthday()}; by default, {it:s_nl}="01mar" and {it:Y} is the current system year (see {help cretur##values}).
So the {it:birthday} is correct for people who are less than 100 years old.

{phang}
{opth ageat(varname)} generates the {it:age} in years at the e_d date in {it:varname}. 
See {help age()}; by default, {it:s_nl}="01mar" and {it:Y} is the current system year (see {help cretur##values}). So the {it:age} is correct for people who are less than 100 years old.

{phang}
{opth agefracat(varname)} generates the variable {it:age_frac}, the age in years, including its fractional part, at the e_d date in {it:varname}. 
See {help age_frac()}; by default, {it:s_nl}="01mar" and {it:Y} is the current system year (see {help cretur##values}). So the {it:age_frac} is correct for people who are less than 100 years old.

{phang}
{opt gt100} uses the 7th digit in the {it:newvar} to determine the birth century, so you should make sure that the 7th digits in {it:newvar} is correct when you use this option. 
If all people in your sample are less than 100 years old it is better to use the default setting. {opt gt100} will only influence variables {it:birthday}, {it:age} and {it:age_frac}.

{marker remarks}{...}
{title:Remarks}

{pstd}
For detailed information on the Danish CPR, see
{browse "https://da.wikipedia.org/w/index.php?title=CPR-nummer&oldid=11492353"}.

{marker examples}{...}
{title:Examples}

{phang}{cmd:. gencpr newcpr, from(oldcpr)}{p_end}

{phang}{cmd:. gencpr cleancpr, from(oddcpr) modulus gender birthday ageat(surveydate) agefracat(surveydate)}{p_end}

{phang}{cmd:. gencpr newcpr, from(oldcpr) birthday ageat(died) agefracat(died) gt100}{p_end}

{marker contact}{...}
{title:Author}

{pstd}Christoffer Scavenius{break}
VIVE – The Danish Centre for Social Science Research{break}
E-mail: {browse "mailto:css@vive.dk":css@vive.dk}
{p_end}
