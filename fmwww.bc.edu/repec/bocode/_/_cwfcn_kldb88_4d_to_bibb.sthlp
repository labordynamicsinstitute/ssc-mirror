{smcl}
{* version 01.0.0 10apr2025 Hans Gerhardt and Anneke Kappes}{...}
{hi:kldb88_4d_to_bibb()} {hline 2} Translate 4-digit KldB-1988 to BIBB occupational fields (2 digit)

{title:Syntax}

        {cmd:kldb88_4d_to_bibb(}{varname}{cmd:)}

{pstd}
    where {it:varname} contains 4-digit KldB-1988 codes.

{title:Description}

{pstd}
    {helpb kldbrecode} table translating KldB-1988 types of occupations (4 digit codes) to BIBB occupational fields (2 digit) 
    using {helpb crosswalk}.

{title:Source}

{pstd}
    {cmd:kldb88_4d_to_bibb()} is implemented as a wrapper for 
    {helpb _cwfcn_kldb88_4d_to_kldb88_3d:kldb88_4d_to_kldb88_3d()} followed by
    {helpb _cwfcn_kldb88_3d_to_bibb:kldb88_3d_to_bibb()}.
    {p_end}
    
{hline}
{asis}
.kldb88_4d_to_kldb88_3d
.kldb88_3d_to_bibb
