{smcl}
{* naam.sthlp  version 1.0.1  4 April 2026}{...}
{hline}
help for {cmd:naam}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{hi:naam} {hline 2}}Consistent string encoding, ID hashing, and label
    management across multiple datasets{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:naam encode} {varlist} {cmd:using} {it:{help filename}}
    [{cmd:,} {opt replace} {opt keep}]

{p 8 17 2}
{cmd:naam apply} {cmd:using} {it:{help filename}}
    [{cmd:,} {opt varsonly} {opt labelsonly}]

{p 8 17 2}
{cmd:naam id} {varlist} {cmd:using} {it:{help filename}}
    [{cmd:,} {opt replace} {opt keep} {opt strict}]

{p 8 17 2}
{cmd:naam export} {cmd:using} {it:{help filename}}
    [{cmd:,} {opt replace}]

{p 8 17 2}
{cmd:naam list} {cmd:using} {it:{help filename}}
    [{cmd:,} {opt var:iable(varname)}]

{p 8 17 2}
{cmd:naam decode} {varlist} {cmd:using} {it:{help filename}}
    [{cmd:,} {opt keep}]

{p 8 17 2}
{cmd:naam check} [{varlist}] {cmd:using} {it:{help filename}}

{p 8 17 2}
{cmd:naam compare} {cmd:using} {it:filename1}
    {cmd:,} {opt using2(filename2)}

{pstd}
For all subcommands except {cmd:naam id}, {it:filename} refers to an Excel workbook (.xlsx);
the {cmd:.xlsx} extension is appended automatically if omitted.
{cmd:naam id} saves each variable's mapping as a separate Stata .dta file
({it:filename_varname.dta}), with no row-count limit.


{marker description}{...}
{title:Description}

{pstd}
{cmd:naam} ({c 34}What{c 39}s in a naam?{c 34}) solves a core problem in
large-scale survey and administrative data work: encoding string variables
{it:consistently} across multiple datasets or rounds.

{pstd}
Stata{c 39}s built-in {helpb encode} assigns numeric codes alphabetically
within each dataset independently. If a later file introduces a new category
{hline 2} a new region, industry, or district {hline 2} all alphabetically
subsequent codes shift, and any merge or append across files produces wrong
results with no error message.

{pstd}
{cmd:naam} encodes once, saves the exact string-to-numeric mapping for every
variable to a named Excel workbook, and reapplies those mappings instantly to
every subsequent file. The same string always receives the same numeric code.
New categories are detected automatically, assigned the next available code,
and the Excel file is updated. The Excel file also serves as a permanent,
human-readable audit record of every mapping in the project. ID variables
are handled separately by {cmd:naam id}, which saves mappings as native
Stata .dta files with no row-count limit.

{pstd}
{cmd:naam} requires no user-written dependencies. All subcommands read and
write standard .xlsx files using Stata{c 39}s built-in {helpb import excel}
and {helpb export excel}. {cmd:naam id} reads and writes .dta files using
{helpb use} and {helpb save}.


{marker subcommands}{...}
{title:Subcommands}

{p2colset 5 20 22 2}
{p2col:{cmd:naam encode}}Converts text columns such as "North" and "South"
    into numbers, and saves a record of exactly which text got which number
    into an Excel file so you can reuse it on the next file.{p_end}
{p2col:{cmd:naam apply}}When you receive the next file with the same text
    columns, this reads the Excel record saved by {cmd:naam encode} and
    applies the exact same numbers instead of starting fresh. New categories
    are assigned the next available code automatically.{p_end}
{p2col:{cmd:naam id}}When you have a unique identifier column such as
    HH-001-MH that you need to merge datasets on, this converts it to a
    number and saves a record so the same ID always gets the same number
    across every file. Mappings are saved as native Stata .dta files
    ({it:base_varname.dta}), one per ID variable, with no row-count limit.
    Use {cmd:naam id} on each file; do not use {cmd:naam apply} for ID
    variables.{p_end}
{p2col:{cmd:naam export}}When your dataset already has numbers with labels
    attached, this saves those labels into Excel so you can restore them
    later if they get stripped.{p_end}
{p2col:{cmd:naam list}}Opens your Excel mapping file and displays everything
    inside it directly in Stata, so you can see at a glance what number each
    category was assigned without opening Excel.{p_end}
{p2col:{cmd:naam decode}}Takes a numeric column and converts it back to the
    original text using the saved Excel mapping, useful when you need the
    original words back for a report or export. Works even if value labels
    have been stripped from the dataset.{p_end}
{p2col:{cmd:naam check}}Before merging or appending datasets, this compares
    the labels in your current dataset against the saved Excel mapping and
    flags any mismatches so you catch problems before they corrupt your
    analysis. Does not modify the dataset or the Excel file.{p_end}
{p2col:{cmd:naam compare}}When two people have encoded the same data
    independently, this compares their two Excel mapping files and tells you
    exactly where they assigned different numbers to the same
    category.{p_end}
{p2colreset}


{marker options}{...}
{title:Options}

{dlgtab:naam encode and naam id}

{phang}
{opt replace} overwrites the mapping file if it already exists. For
{cmd:naam encode} and {cmd:naam export} this is the .xlsx file; for
{cmd:naam id} this is the per-variable .dta file. Required the first
time a mapping file is created for a given filename.

{phang}
{opt keep} retains the original string variable alongside the new numeric
variable, renamed {it:_str_varname}.

{dlgtab:naam id only}

{phang}
{opt strict} exits with an error if the current dataset contains any ID
value not found in the saved mapping. Use this to enforce that no unexpected
new observations appear in a subsequent file.

{dlgtab:naam apply only}

{phang}
{opt varsonly} reattaches variable labels only; skips value labels and
encodings.

{phang}
{opt labelsonly} reattaches value labels and encodings only; skips variable
labels.

{dlgtab:naam export only}

{phang}
{opt replace} overwrites the Excel file if it already exists.

{dlgtab:naam list only}

{phang}
{opt var:iable(varname)} prints only the mapping for the named variable
instead of all variables in the file.

{dlgtab:naam decode only}

{phang}
{opt keep} retains the original numeric variable alongside the new string
variable, renamed {it:_num_varname}.

{dlgtab:naam compare only}

{phang}
{opt using2(filename)} specifies the second Excel mapping file. Required.


{marker details}{...}
{title:Subcommand details}

{dlgtab:naam encode}

{pstd}
Encodes each string variable in {varlist} to numeric using Stata{c 39}s
{helpb encode} and writes the complete string-to-numeric mapping for each
variable as a separate named sheet in the Excel workbook. Variables that are
already numeric are skipped with a note. Run {cmd:naam encode} once on the
first file in a multi-file workflow; use {cmd:naam apply} on every subsequent
file.

{dlgtab:naam apply}

{pstd}
Reads the {it:index} sheet of the specified Excel workbook to determine which
variables are present and what type of mapping applies to each, then processes
each variable as follows:

{p2colset 8 20 22 2}
{p2col:{it:type = encode}}If the variable is still a string, converts it to
    numeric using the saved mapping. If already numeric, reattaches the saved
    value labels. New categories are assigned new codes and the Excel file is
    updated.{p_end}
{p2col:{it:type = export}}The variable is already numeric. Reattaches the
    saved value labels.{p_end}
{p2col:{it:type = id}}Prints a note only. Does {it:not} perform the
    string-to-numeric conversion. Call {cmd:naam id} on each new file that
    requires the conversion.{p_end}
{p2colreset}

{dlgtab:naam id}

{pstd}
Converts each string ID variable in {varlist} to a consistent numeric ID.
On the {it:first} file, codes 1, 2, 3, ... are assigned in alphabetical
order using {helpb egen} {opt group()}, and the mapping is saved as a
native Stata .dta file ({it:base_varname.dta}). On every {it:subsequent}
file, the saved mapping is read: known IDs receive their original codes,
and new IDs receive the next available sequential codes. There is no
row-count limit.

{dlgtab:naam export}

{pstd}
For datasets that are already numeric with value labels attached. Saves all
variable labels and value labels to Excel so they can be reattached with
{cmd:naam apply}. A common trigger is {cmd:label drop _all}, importing from
a .csv file, or receiving a raw dataset without a .dta file. Does not encode
or modify anything in the dataset.

{dlgtab:naam list}

{pstd}
Reads a naam Excel file and prints its full contents to the Results window:
each variable, its type, and every numeric code with its corresponding string
value. Applies to variables encoded with {cmd:naam encode} or exported with
{cmd:naam export}. ID variable mappings are stored in separate .dta files
and are not displayed by {cmd:naam list}; use {helpb use} or {helpb browse}
to inspect them directly. The dataset in memory is not used or modified.

{dlgtab:naam decode}

{pstd}
Reverses a naam encoding using the saved Excel mapping. Observations whose
numeric value has no match in the mapping are set to missing and a warning
is printed.

{dlgtab:naam check}

{pstd}
Compares the value labels currently attached in memory against the saved
Excel mapping and prints a code-by-code report: OK, CONFLICT (label
differs), or MISSING (code in Excel but not in memory). Also flags codes
in memory that are not in the Excel file. If no {varlist} is given, all
variables in the index are checked. Neither the dataset nor the Excel file
is modified.

{dlgtab:naam compare}

{pstd}
Compares two naam Excel files without requiring any dataset in memory.
Useful when two teams have encoded data independently and need to confirm
consistency before combining files.


{marker limitations}{...}
{title:Limitations}

{phang}
{c 149} {cmd:naam apply} does {it:not} perform the string-to-numeric
conversion for ID variables. Call {cmd:naam id} on each new file.

{phang}
{c 149} {cmd:naam encode} skips variables that are already numeric.

{phang}
{c 149} {cmd:naam export} saves only value labels that are already defined
and attached in the dataset.

{phang}
{c 149} {cmd:naam decode} sets unmatched observations to missing and prints
a warning.

{phang}
{c 149} Excel sheet names are truncated to 31 characters if the variable
name is longer. This applies to {cmd:naam encode} and {cmd:naam export};
{cmd:naam id} is unaffected as it writes .dta files, not Excel sheets.


{marker excel}{...}
{title:Output file structure}

{pstd}
{ul:Excel files} ({cmd:naam encode}, {cmd:naam export}, {cmd:naam apply}):

{p2colset 5 24 26 2}
{p2col:Sheet {it:index}}One row per processed variable. Columns:
    {it:varname}, {it:varlabel}, {it:type} (encode / export / id),
    and for {cmd:naam export} also {it:lblname} and {it:vartype}.{p_end}
{p2col:Sheet {it:<varname>}}One sheet per variable with a mapping.
    Columns: {it:numeric_code} and {it:string_value}.{p_end}
{p2colreset}

{pstd}
These files are fully human-readable in Excel and should be archived
alongside the datasets they describe.

{pstd}
{ul:.dta files} ({cmd:naam id}): one file per ID variable, named
{it:base_varname.dta}. Each contains two variables: {it:string_value}
and {it:numeric_code}, sorted by code. No row-count limit.


{marker examples}{...}
{title:Examples}

{pstd}
The following examples use two sample household survey datasets installed
with {cmd:naam}: {cmd:naam_round1.dta} (200 households, 7 districts) and
{cmd:naam_round2.dta} (200 households, 8 districts -- Amravati is new).
Both contain string variables {cmd:district}, {cmd:occupation}, and
{cmd:religion}, and an alphanumeric household ID {cmd:hhid} in the
format HH-MH-NNNNN. Install them with:{p_end}

{phang2}{cmd:. ssc install naam, all}{p_end}

{pstd}{ul:Example 1 -- naam encode and naam apply}

{pstd}Setup{p_end}
{phang2}{stata "use naam_round1.dta, clear":. use naam_round1.dta, clear}{p_end}

{pstd}Encode Round 1 and save the mapping{p_end}
{phang2}{stata "naam encode district occupation religion using naam_maps.xlsx, replace":. naam encode district occupation religion using naam_maps.xlsx, replace}{p_end}
{phang2}{stata "naam id hhid using naam_ids, replace keep":. naam id hhid using naam_ids, replace keep}{p_end}
{phang2}{cmd:* produces naam_ids_hhid.dta}{p_end}
{phang2}{stata "save naam_enc1.dta, replace":. save naam_enc1.dta, replace}{p_end}

{pstd}Apply same mapping to Round 2; Amravati detected and auto-assigned{p_end}
{phang2}{stata "use naam_round2.dta, clear":. use naam_round2.dta, clear}{p_end}
{phang2}{stata "naam apply using naam_maps.xlsx":. naam apply using naam_maps.xlsx}{p_end}
{phang2}{stata "naam id hhid using naam_ids, keep":. naam id hhid using naam_ids, keep}{p_end}
{phang2}{cmd:* reads naam_ids_hhid.dta, assigns same codes + any new ones}{p_end}

{pstd}Append: every district code is now consistent across both rounds{p_end}
{phang2}{stata "append using naam_enc1.dta":. append using naam_enc1.dta}{p_end}
{phang2}{stata "tab district":. tab district}{p_end}

{pstd}Inspect the full mapping from inside Stata{p_end}
{phang2}{stata "naam list using naam_maps.xlsx":. naam list using naam_maps.xlsx}{p_end}

{pstd}{ul:Example 2 -- naam export and naam apply}

{pstd}Setup{p_end}
{phang2}{stata "sysuse auto, clear":. sysuse auto, clear}{p_end}

{pstd}Save value labels before they are lost{p_end}
{phang2}{stata "naam export using naam_labels.xlsx, replace":. naam export using naam_labels.xlsx, replace}{p_end}

{pstd}Simulate receiving the data with no labels attached{p_end}
{phang2}{stata "label drop _all":. label drop _all}{p_end}
{phang2}{stata "tab foreign":. tab foreign}{p_end}

{pstd}Restore with a single command{p_end}
{phang2}{stata "naam apply using naam_labels.xlsx":. naam apply using naam_labels.xlsx}{p_end}
{phang2}{stata "tab foreign":. tab foreign}{p_end}

{pstd}{ul:Other subcommands}

{pstd}{cmd:naam decode} -- convert numeric variables back to their original strings{p_end}
{phang2}{cmd:. naam decode district occupation using naam_maps.xlsx}{p_end}

{pstd}{cmd:naam check} -- verify labels match the saved mapping before a merge{p_end}
{phang2}{cmd:. naam check district occupation religion using naam_maps.xlsx}{p_end}

{pstd}{cmd:naam compare} -- compare two mapping files from two teams{p_end}
{phang2}{cmd:. naam compare using naam_teamA.xlsx, using2(naam_teamB.xlsx)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:naam} does not store results in {cmd:r()} or {cmd:e()}.
Output is written to the Excel file or .dta file specified in {cmd:using}.


{marker requirements}{...}
{title:Requirements}

{pstd}
Stata 14 or higher. No user-written packages are required.
{cmd:naam} relies only on {helpb import excel}, {helpb export excel},
{helpb use}, {helpb save}, {helpb encode}, {helpb egen},
{helpb label}, and {helpb levelsof}.


{marker citation}{...}
{title:Citation}

{pstd}
{cmd:naam} is inspired by {cmd:codebookout}. If you use {cmd:naam},
please also cite the original package:

{phang2}
Das, Kishor K. (2014). {c 34}CODEBOOKOUT: Stata module to save codebook
in MS excel format.{c 34} {it:Statistical Software Components} S457811,
Boston College Department of Economics.{break}
{browse "https://ideas.repec.org/c/boc/bocode/s457811.html":https://ideas.repec.org/c/boc/bocode/s457811.html}
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Vijayshree Jayaraman{break}
Email: {browse "mailto:jvijayshree26@gmail.com":jvijayshree26@gmail.com}{break}
GitHub: {browse "https://github.com/vijayshree-jayaraman":https://github.com/vijayshree-jayaraman}


{marker alsosee}{...}
{title:Also see}

{psee}
Manual: {manhelp encode D}, {manhelp label D}, {manhelp merge D},
{manhelp append D}, {manhelp egen D}
{p_end}

{psee}
{helpb encode},
{helpb label},
{helpb egen},
{helpb levelsof},
{helpb merge},
{helpb append},
{helpb import excel},
{helpb export excel}
{p_end}
