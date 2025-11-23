{smcl}
{* *! version 1.1.0 20nov2025 author: J.D. Lopez Blanco}
{title:Title}

{phang}
{bf:cno11isco08} — Recode Spanish CNO-11 occupational codes into ISCO-08 (2, 3, or 4 digits)

{title:Syntax}

{p 8 17 2}
{cmd:cno11isco08} {it:varname} 
[{cmd:,} {opt gen:erate(newvar)} {opt replace} {opt three} {opt four}]

{synoptset 18 tabbed}{...}
{synopthdr:Options}
{synoptline}
{synopt:{opt gen(erate(newvar))}}name of the new ISCO variable (default depends on mode){p_end}
{synopt:{opt replace}}overwrite the output variable if it already exists{p_end}
{synopt:{opt three}}apply 3-digit CNO-11 → ISCO-08 recode{p_end}
{synopt:{opt four}}apply 4-digit CNO-11 → ISCO-08 recode{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:cno11isco08} converts occupational codes from the Spanish
{bf:Clasificación Nacional de Ocupaciones 2011 (CNO-11)} into the international
{bf:ISCO-08} classification, using the official correspondence tables produced
by the Instituto Nacional de Estadística (INE). The command supports harmonisation
at the 2-, 3-, and 4-digit levels.

{pstd}
The 2-digit mode is the default. Use {cmd:three} for 3-digit input or
{cmd:four} for 4-digit input. The command automatically generates the output
variable unless otherwise specified.

{title:Background}

{pstd}
The Spanish CNO-11 is aligned conceptually with ISCO-08 but differs in numeric
structure and category boundaries. This makes direct international comparison
difficult when working with Spanish microdata that uses CNO-11.

{pstd}
{cmd:cno11isco08} implements a transparent harmonisation of CNO-11 into
ISCO-08 following the official INE correspondence tables, allowing researchers
to integrate Spanish datasets with ISCO-coded surveys such as EU-LFS, EU-SILC,
ESS, SHARE, or census harmonisations.

{title:Ambiguous cases and rule-of-thumb}

{pstd}
The harmonisation implemented by {cmd:cno11isco08} is based on the official
INE correspondence tables between CNO-11 and ISCO-08. In most cases, the mapping
from a given CNO-11 category to ISCO-08 is unique. However, a small number of
exceptions arise where more than one ISCO-08 code could be considered valid.

{pstd}
At the {bf:4-digit level}, these ambiguous cases are extremely rare. Whenever
the INE tables indicate that a single CNO-11 unit group may correspond to more
than one ISCO-08 unit group, the categories involved were examined {it:case by
case} using the official nomenclature. In practice, these situations concern
closely related, collindant categories with very short conceptual distance. The
final assignment always respects the INE crosswalk and documentation.

{pstd}
When moving to {bf:more aggregated levels} (3-digit and especially 2-digit),
these overlaps naturally become more frequent: aggregating detailed CNO-11
categories into broader groups implies that some resulting aggregates are linked
to several possible ISCO-08 aggregates. In these situations, the command applies
a general conservative rule-of-thumb:

{p 12 12 2}{bf:When two possible ISCO-08 outcomes exist for an aggregated CNO-11 code, the command assigns the occupation to the higher ISCO-08 code (i.e., the category with lower skill level).}

{pstd}
This rule follows a conservative logic widely used in the literature. Many
researchers employ ISCO-08 codes to derive occupational class schemes such as
EGP, ISEI, SIOPS, OEPS, or other socio-economic status scales. In these
frameworks, assigning ambiguous occupations to the {it:less skilled} ISCO-08
category prevents overstating occupational status and keeps classifications
consistent with a lower-bound interpretation of skill requirements.

{pstd}
Choosing the higher ISCO-08 code therefore provides a conservative treatment,
reducing the risk that borderline or heterogeneous occupations are assigned to a
higher skill group than warranted.

{pstd}
{bf:Example:} CNO-11 distinguishes between National Police, Guardia Civil, and
regional or local police forces. According to the INE tables, these groups may
map to ISCO-08 categories used both for general police officers and for border
guards. In such cases, {cmd:cno11isco08} follows the conservative rule and
assigns the occupations to the higher ISCO-08 code (the less skilled group),
maintaining consistency with standard practices in occupational stratification
research.

{title:Remarks}

{pstd}
The command must be run with {cmd:version 13} or higher.  
All code is compatible with {cmd:set varabbrev off}.  



{title:Examples}

{pstd}
The following toy dataset illustrates how to use {cmd:cno11isco08} with
CNO-11 codes at 2-, 3-, and 4-digit levels.

{cmd}
    clear all
    set more off

    *-----------------------------------------------
    * 1. Toy dataset with CNO-11 in 2, 3 and 4 digits
    *-----------------------------------------------
    input ///
        id  cno11_2  cno11_3  cno11_4
        1   11       725      1111
        2   12       421      1219
        3   21       111      1329
        4   24       121      2111
        5   34       131      2411
        6   59       132      3121
        7   31       241      5821
        8   33       332      7111
        9   71       562      9811
        10  83       572      5721
    end

    label var cno11_2 "CNO-11 (2-digit, toy)"
    label var cno11_3 "CNO-11 (3-digit, toy)"
    label var cno11_4 "CNO-11 (4-digit, toy)"

    *-----------------------------------------------
    * 2. Apply the command in its three modes
    *-----------------------------------------------

    * 2.1. Default mode: 2-digit CNO-11 -> 2-digit ISCO-08
    cno11isco08 cno11_2, gen(isco08_2_test)

    * 2.2. 3-digit mode: CNO-11 3-digit -> ISCO-08 3-digit
    cno11isco08 cno11_3, three gen(isco08_3_test)

    * 2.3. 4-digit mode: CNO-11 4-digit -> ISCO-08 4-digit
    cno11isco08 cno11_4, four gen(isco08_4_test)

    list, sep(0)
{txt}


{title:Author}

{pstd}
J.D Lopez Blanco, University of Bologna{break}
email: jose.lopezblanco@unibo.it