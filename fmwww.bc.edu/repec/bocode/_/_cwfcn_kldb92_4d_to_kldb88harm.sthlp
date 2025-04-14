{smcl}
{* version 01.0.0 10apr2025 Hans Gerhardt and Anneke Kappes}{...}
{hi:kldb92_4d_to_kldb88harm()} {hline 2} Translate 4-digit KldB-1992 to harmonized 3-digit KldB-1988 codes

{title:Syntax}

        {cmd:kldb92_4d_to_kldb88harm(}{varname}{cmd:)}

{pstd}
    where {it:varname} contains 4-digit KldB-1992 codes.

{title:Description}

{pstd}
    {helpb kldbrecode} table translating KldB-1992 types of occupations (4 digit codes) to harmonized KldB-1988 occupational orders using {helpb crosswalk}.

{title:Source}

{pstd}
    {cmd:kldb92_4d_to_kldb88harm()} is implemented as a wrapper for 
    {helpb _cwfcn_kldb92_4d_to_kldb92_3d:kldb92_4d_to_kldb92_3d()} followed by
    {helpb _cwfcn_kldb92_3d_to_kldb88harm:kldb92_3d_to_kldb88harm()}.
    {p_end}

{hline}
{asis}
.kldb92_4d_to_kldb92_3d
.kldb92_3d_to_kldb88harm
