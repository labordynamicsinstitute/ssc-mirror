{smcl}
{* *! version 1.1.2  07oct2024}{...}
{viewerjumpto "Syntax" "usort##syntax"}{...}
{viewerjumpto "Description" "usort##description"}{...}
{viewerjumpto "Methods and formulas" "usort##methods"}{...}
{viewerjumpto "Examples" "usort##examples"}{...}
{p2colset 1 15 17 2}{...}

{title:Title}
{phang}
{bf:usort} {hline 2} byable locale-based ascending and descending sort that
supports conditional statements, observation ranges, and user-defined handling
of substrings and missing values

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:usort}
[{cmd:+}|{cmd:-}]
{varname}
[[{cmd:+}|{cmd:-}]
{varname} {it:...}]
{ifin}
[{cmd:,} {it:options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Substrings and missing values}
{synopt:{opth f:irst(strings:string [, pos|rpos|regex]])}} sort the words, i.e.,
        substrings (not) enclosed in double quotes and separated by
        whitespace(s), within the {help strings:{it:string}}: first (for
        [+]{varname}) or last (for -{varname}) in the specified order (word 1
        is first, word 2 is second, etc.). Sorting is done by: a)
        comparing {varname} with each word (without options), b) using
        {help f_ustrpos:ustrpos({it:varname}, word)} (for {it:pos}), c) using
        {help f_ustrrpos:ustrrpos({it:varname}, word)} (for {it:rpos}), or
        d) using {help f_ustrregexm:ustrregexm({it:varname}, word)} (for
        {it:regex}). {break} {bf:Note:} System numerical and string missing
        values are coded as {bf:.}, while non-system missing values are coded as
        {bf:.a}, {bf:.b}, etc. in non-regex representation. For regular
        expressions, you can use {bf:^[.]$}, {bf:^[.]a$}, {bf:^[.]b$}, etc. in
        {bf:first(}{help strings:{it:string}}, {it:regex}{bf:)}.{p_end}
{synopt:{opth l:ast(strings:string [, pos|rpos|regex]])}}  sort the words, i.e.,
        substrings not enclosed in double quotes and separated by
        whitespace(s), within the {help strings:{it:string}}: last (for
        [+]{varname}) or first (for -{varname}) in the specified order (word 1
        is last, word 2 is second to last, etc.). Sorting is performed by: a)
        comparing {varname} with each word (without options), b) using
        {help f_ustrpos:ustrpos({it:varname}, word)} (for {it:pos}), c) using
        {help f_ustrrpos:ustrrpos({it:varname}, word)} (for {it:rpos}), or
        d) using {help f_ustrregexm:ustrregexm({it:varname}, word)} (for
        {it:regex}). {break} {bf:Note:} System numerical and string missing
        values are coded as {bf:.}, while non-system missing values are coded as
        {bf:.a}, {bf:.b}, etc. in non-regex representation. For regular
        expressions, you can use {bf:^[.]$}, {bf:^[.]a$}, {bf:^[.]b$}, etc. in
        {bf:first(}{help strings:{it:string}}, {it:regex}{bf:)}.{p_end}
{synopt:{opt ignorec}}ignore case sensitivity in {bf:first()} and {bf:last()}.
        {p_end}
{synopt:{opt mf:irst}}sort missing values first (for [+]{varname}) or last (for
        -{varname}).{p_end}
{synopt:{opt ml:ast}}sort missing values last (for [+]{varname}) or first (for
        -{varname}).{p_end}
{synopt:{opt ignorem}}ignore missing values when using {bf:first()},
        {bf:last()}, {bf:mfirst}, and {bf:mlast}.{p_end}

{syntab:Locale}
{synopt:{opth loc:ale(string)}}locale code from the {stata unicode locale list}
        or {bf:c(locale_functions)} by default.{p_end}
{synopt:{opth st(#)}}argument {it:st} in
        {help f_ustrsortkeyex:ustrsortkeyex()}, with a default value of {bf:-1}.
        {p_end}
{synopt:{opth case(#)}}argument {it:case} in
        {help f_ustrsortkeyex:ustrsortkeyex()}, with a default value of {bf:-1}.
        {p_end}
{synopt:{opth cslv(#)}}argument {it:cslv} in
        {help f_ustrsortkeyex:ustrsortkeyex()}, with a default value of {bf:-1}.
        {p_end}
{synopt:{opth norm(#)}}argument {it:norm} in
        {help f_ustrsortkeyex:ustrsortkeyex()}, with a default value of {bf:-1}.
        {p_end}
{synopt:{opth num(#)}}argument {it:num} in
        {help f_ustrsortkeyex:ustrsortkeyex()}, with a default value of {bf:-1}.
        {p_end}
{synopt:{opth alt(#)}}argument {it:alt} in
        {help f_ustrsortkeyex:ustrsortkeyex()}, with a default value of {bf:-1}.
        {p_end}
{synopt:{opth fr(#)}}argument {it:fr} in
        {help f_ustrsortkeyex:ustrsortkeyex()}, with a default value of {bf:-1}.
        {p_end}

{syntab:Miscellaneous}
{synopt:{opth format(%fmt)}}format for converting numerical sort variables into
        strings (sorting is performed on string values only). The default format
        is {bf:%32.16f}.{p_end}
{synopt:{opth codepoint(#)}}code point location of a symbol from the bottom of
        the UTF-8 table used to make {bf:last()} work. The default value is
        {bf:129769}.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{opt by} is allowed; see {help by}.{p_end}
{marker weight}{...}
{p 4 6 2}
{opt weight}s are not allowed; see {help weights}.
{p_end}

{marker description}{...}
{title:Description}

{pstd}
This program is a byable sort command, which allows for: a) custom first and
last substrings, including system missing values ({bf:.}) and all other missing
values, b) {helpb gsort}-like syntax for sorting in ascending or descending
order, and c) conditional sorting using [{help if:{it:if}}] or range-based
sorting using [{help in:{it:in}}]. The program is built around Stata's
{helpb sort} command and will mark the dataset as sorted (sorted by) if all rows
are selected. If a subset of rows is selected, it applies {help mata:Mata}'s
{help mf_sort:_collate()}.

{pstd}
Sorting large datasets may be more taxing on machine CPU, memory, and/or disk
space as compared to {helpb sort} and {helpb gsort}.

{marker methods}{...}
{title:Methods and Formulas}
{pstd}
Sorting occurs in {bf:two steps}:

{pstd}
{bf:1.} Generating a permutation vector in {help mata:Mata} from the sort
variables under {helpb preserve}. Since non-numeric sorting values cannot be
'destringed', the sort variable type must be {help data_types:{it:str#/strL}}
to  allow sorting them as a single matrix using {help mata:Mata}'s
{help mf_sort:sort()} function. The precision for sorting 'tostringed' numeric
values is determined by the {help format:{it:%fmt}} (either default or
user-specified) in {bf:format()}.

{pmore}
To ensure that substrings specified by the {bf:first()} option are sorted first,
they are replaced within the sort variables by {bf:" #"}, where {bf:" "} is a
string of whitespaces (a Unicode character from the top of the UTF-8 table) with
a length of max(strlen(sort variable)). This step is skipped for already
'tostringed' missing values ({bf:.}, {bf:.a}, ..., {bf:.z}) if {bf:ignorem} is
specified.

{pmore}
To ensure that substrings specified by the {bf:last()} option are sorted last,
they are replaced within the sort variables by {bf:"©#"}, where {bf:"©"} is a
string of identical Unicode characters from the bottom of the UTF-8 table. The
code point for this character (either default or user-specified) is set by
{bf:codepoint()}, and the length is again max(strlen(sort variable)). This step
is also skipped for 'tostringed' missing values if {bf:ignorem} is specified.

{pmore}
For natural sorting, leading zeros are appended to the integer parts of
'tostringed' numeric values.

{pstd}
{bf:2.} Collating all rows with or a subset without adding the data-sorted flag
(sorted by) using the permutation vector.

{pmore}
The flag is created by preserving the original string and numeric values of the
sort variables in two ancillary matrices in {help mata:Mata}, replacing them
with the permutation vector, performing the regular Stata {helpb sort} (i.e.,
reordering and collating), and then restoring the original sort variable values,
now collated on the permutation vector, using {help mata:Mata}'s
{help mf_sort:_collate()}.

{pmore}
The program sets a {bf:data-changed flag} when variable rows are collated.

{pstd}
{bf:Note:} The {helpb by} prefix is processed using {helpb egen} {it:group},
in conjunction with {helpb preserve}, {helpb append}, and {helpb save}, which
store interim results in a temporary file.

{marker examples}{...}
{title:Examples}
{pstd}Setup:{p_end}
{phang2}{cmd:. sysuse auto}

{pstd}Sort observations in ascending order by {cmd:price}:{p_end}
{phang2}{cmd:. usort price}

{pstd}Sort observations in ascending order by {cmd:rep78}, missing first:{p_end}
{phang2}{cmd:. usort rep78, mfirst}

{pstd}Sort observations in ascending order by {cmd:make} in Czech, grouped by
{cmd:foreign}, with VW models placed at the top:{p_end}
{phang2}{cmd:. bysort foreign: usort make, first(VW, pos) loc(cs_CS)}

{pstd}Sort observations in descending order by {cmd:mpg} and {cmd:price}:{p_end}
{phang2}{cmd:. usort -mpg -price}

{pstd}Sort observations in descending order by {cmd:price} for domestic cars
only:{p_end}
{phang2}{cmd:. usort -mpg -price if ! foreign}

{title:Acknowledgements}
{pstd}
A special thanks to Leonardo Guizzetti for requesting and testing this program.

{title:Author}

{pstd}
{bf:Ilya Bolotov}
{break}Prague University of Economics and Business
{break}Prague, Czech Republic
{break}{browse "mailto:ilya.bolotov@vse.cz":ilya.bolotov@vse.cz}

{pstd}
Thanks for citing this software and my works on the topic:

{p 8 8 2}
    Bolotov, I. (2024). USORT: Stata module to perform locale-based ascending
    and descending sort that supports conditional statements, observation
    ranges, and user-defined handling of substrings and missing values.
    Available from {browse "https://ideas.repec.org/c/boc/bocode/s459385.html"}.
