{smcl}
{* *! version 1.0.0  20aug2025}{...}
{viewerjumpto "Syntax" "cconv##syntax"}{...}
{viewerjumpto "Description" "cconv##description"}{...}
{viewerjumpto "Options" "cconv##options"}{...}
{viewerjumpto "Remarks" "cconv##remarks"}{...}
{viewerjumpto "Examples" "cconv##examples"}{...}
{title:Title}

{phang}
{bf:cconv} {hline 2} Convert a string variable to a classification from
a built-in or user-defined JSON file using libjson (regular expressions with
Unicode support), the default being ISO 3166-1 (country codes and names)

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:cconv}
{help varname:{it:varname}} or {help strings:{it:string}}
[{cmd:,} {it:options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Classification}
{synopt :{opth from:(strings:string)}}is a relative or absolute path
        to the JSON file (omittable){p_end}
{synopt :{opth to:(strings:string)}}is a classification from the JSON file,
        by default, {bf:"iso3"}, {bf:"iso2"}, {bf:"isoN"}, {bf:"name_en"},
        or {bf:"name_fr"}, or a filepath{p_end}

{syntab:Write to data}
{p2coldent :* {opth g:enerate(strings:string)}}specify a new
        {help varname:{it:varname}} for the a) result of conversion or
        b) classification {p_end}
{p2coldent :* {opt replace}}replace provided {help varname:{it:varname}} with
        the a) result of conversion or b) classification {p_end}
{p2coldent :* {opt print}}print the result, do not generate or replace
        variables{p_end}
{synoptline}
{p2colreset}{...}
{pstd}* One of {opth generate:(strings:string)}, {opt replace} or {opt print}
is required if {help varname:{it:varname}} or "__classification" are specified.
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{bf:cconv} converts a string variable to a classification from a built-in
or user-defined JSON file using libjson (regular expressions with Unicode
support).
{break}By default, country names (in English) or codes are converted to
ISO 3166-1 codes (alpha-2, alpha-3, and numeric) and to full names (in English
and in French).

{pstd}
{cmd:. cconv {help varname:{it:varname}}, to({help strings:{it:string}})}
{break}performs the conversion of {help varname:{it:varname}} to the specified
classification and is followed by
{help cconv##options:{it:generate(string)}},
{help cconv##options:{it:replace}} or
{help cconv##options:{it:print}}.

{pstd}
{cmd:. cconv __classification, to({help strings:{it:string}})}
{break} returns the specified classification as a whole and is followed by
{help cconv##options:{it:generate(string)}} or
{help cconv##options:{it:print}}.

{pstd}
{cmd:. cconv __info}
{break}prints metadata and sources, no options are required.

{pstd}
{cmd:. cconv __dump}
{break}returns the full mapping (filtered of metadata/sources). No conversion
is performed.

{marker options}{...}
{title:Options}

{phang}
{opth from:(strings:string)} allows the user to work with a user-defined JSON
file to replace the default classification (ISO 3166-1). The file must contain
a list of dictionaries (the terms 'list', 'dictionary' and 'key' are from
Python's vocabulary) where "regex" is a compulsory key in each dictionary. The
default JSON file was prepared with the help of
{bf:pyconvertu __dump, to({help strings:{it:string}})} because {helpb libjson}
is read–only and does not provide JSON‐writing capabilities from within Stata.
{break}For it, data in memory must include headings "Data", "Metadata" and
"Sources" in the first variable, immediately followed by content. Alternatively,
the user can recur to Python's built-in {bf:json} package:
{cmd:>>> import json; ...; json.dump(...)}), consult
{browse "https://docs.python.org/3/library/json.html"} for documentation.
{break}The JSON file should have the following structure:

    [

        {
            "regex":    "^(.*afgh.*|\\s*AFG\\s*|\\s*AF\\s*|\\s*4\\s*)$",
            "name_en":    "Afghanistan",         # classification A
            "name_fr":    "Afghanistan (l')",    # classification B
            "iso3":        "AFG",                # ...
            "iso2":        "AF",
            "isoN":        "4"
        },

        ...

        {
            "metadata": {
                "name_en": "English short name",
                "name_fr": "French short name",
                "iso3": "alpha-3 code",
                "iso2": "alpha-2 code",
                "isoN": "numeric"
            }
        },

        {
            "sources": [
                "[https://www.iso.org/iso-3166-country-codes.html](ISO 3166 COUNTRY CODES)",
                "[https://en.wikipedia.org/wiki/List_of_alternative_country_names](ALTERNATIVE NAMES)"
            ]
        }

    ]

{phang}
{opth to:(strings:string)} is a key from the JSON file which corresponds to
one of the classifications, by default, {bf:"iso3"} is ISO 3166-1 alpha-3, 
{bf:"iso2"} is ISO 3166-1 alpha-2, {bf:"isoN"} is ISO 3166-1 numeric,
{bf:"name_en"} are names in English, and {bf:"name_fr"} are names in French.

{phang}
{opth g:enerate(strings:string)} is required to write the a) result of
conversion or b) classification to data in form of a new variable.

{phang}
{opt replace} is required to replace the contents of
{help varname:{it:varname}} in
{cmd:. cconv {help varname:{it:varname}}, to({help strings:{it:string}})}
with the a) result of conversion or b) classification.

{phang}
{opt print} negates {help cconv##options:{it:generate(string)}} or
{help cconv##options:{it:replace}} (if specified) and prints the
a) result of conversion or b) classification instead of writing them to
data. The user can utilize {help cconv##options:{it:print}} to check
the result before modifying the data.

{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:cconv} requires {helpb libjson}, which is installed on first run.
{break}For Python users, there is a standalone Python implementation {browse "https://pypi.org/project/pyconvertu/"} with the same functionality.
{break}Likewise, for R users, there is an R equivalent {browse "https://cran.r-project.org/web/packages/rconvertu/"}.

{pstd}
For a Python-based Stata alternative, consult {helpb pyconvertu}.

{marker examples}{...}
{title:Examples}

        * write the complete default JSON file (ISO 3166-1)
        * to data
        {cmd:. clear}
        {cmd:. cconv __classification, to(iso3) gen(iso3)}
        {cmd:. foreach s in "iso2" "isoN" "name_en" "name_fr" {c -(}}
        {cmd:.     cconv iso3, to(`s') gen(`s')}
        {cmd:. {c )-}}

        * print metadata and sources for the default JSON file
        {cmd:. cconv __info}

        * generate panel dimensions
        * (ISO 3166-1 alpha-3 codes for the years 2000-2020)
        {cmd:. clear}
        {cmd:. cconv __classification, to(iso3) gen(iso3)}
        {cmd:. expand `=(2020 - 2000) + 1'}
        {cmd:. by iso3, sort: gen year = 2000 + (_n - 1)}

        * convert ISO 3166-1 alpha-3 to ISO 3166-1 numeric (where possible)
        * in a dataset
        {cmd:. ssc install wbopendata}
        {cmd:. sysuse world-d, clear}
        {cmd:. cconv countrycode, to(isoN) replace}

        * same example, print the result of conversion instead of writing it
        * to data
        {cmd:. sysuse world-d, clear}
        {cmd:. cconv countrycode, to(isoN) print}

{title:Author}

{pstd}
{bf:Ilya Bolotov}
{break}Prague University of Economics and Business
{break}Prague, Czech Republic
{break}{browse "mailto:ilya.bolotov@vse.cz":ilya.bolotov@vse.cz}

{pstd}
    Thanks for citing this software and my works on the topic.
