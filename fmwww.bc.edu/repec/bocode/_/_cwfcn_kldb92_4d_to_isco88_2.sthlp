{smcl}
{* version 01.0.0 10apr2025 Hans Gerhardt and Anneke Kappes}{...}
{hi:kldb92_4d_to_isco88_2()} {hline 2} Translate 4-digit KldB-1992 to 2-digit ISCO-88

{title:Syntax}

        {cmd:kldb92_4d_to_isco88_2(}{varname}{cmd:)}

{pstd}
    where {it:varname} contains 4-digit KldB-1992 codes.

{title:Description}

{pstd}
    {helpb kldbrecode} table translating KldB-1992 types of occupations (4 digit codes)
    to 2-digit ISCO-88 codes (sub-major groups) using {helpb crosswalk}.

{pstd}
    {cmd:isco88_to_isco88_2()} is implemented as a wrapper for 
    {helpb _cwfcn_kldb92_4d_to_isco88:kldb92_4d_to_isco88()} followed by 
    {helpb _cwfcn_isco88_to_isco88_3:isco88_to_isco88_3()} followed by
    {helpb _cwfcn_isco88_3_to_isco88_2:isco88_3_to_isco88_2()}.
    {p_end}

{hline}
{asis}
.kldb92_4d_to_isco88_3
.isco88_3_to_isco88_2
