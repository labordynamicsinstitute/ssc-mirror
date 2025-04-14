{smcl}
{* version 01.0.0 10apr2025 Hans Gerhardt and Anneke Kappes}{...}
{hi:kldb75_3d_to_kldb88_2d()} {hline 2} Translate 3-digit KldB-1975 to 2-digit KldB-1988

{title:Syntax}

        {cmd:kldb75_3d_to_kldb88_2d(}{varname}{cmd:)}

{pstd}
    where {it:varname} contains 3-digit KldB-1975 codes.

{title:Description}

{pstd}
    {helpb kldbrecode} table translating KldB-1975 occupational orders (3 digit codes) to KldB-1988 occupational groups (2 digit codes) using {helpb crosswalk}.

{title:Source}

{pstd}
    {cmd:kldb75_3d_to_kldb88_2d()} is implemented as a wrapper for 
    {helpb _cwfcn_kldb75_3d_to_kldb88_3d:kldb75_3d_to_kldb88_3d()} followed by
    {helpb _cwfcn_kldb88_3d_to_kldb88_2d:kldb88_3d_to_kldb88_2d()}.
    {p_end}
    
{hline}
{asis}
.kldb75_3d_to_kldb88_3d
.kldb88_3d_to_kldb88_2d

