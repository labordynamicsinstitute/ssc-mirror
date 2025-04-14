{smcl}
{* version 01.0.0 10apr2025 Hans Gerhardt and Anneke Kappes}{...}
{hi:kldb92_4d_to_kldb10_3d()} {hline 2} Translate 4-digit KldB-1992 to 3-digit KldB-2010 codes

{title:Syntax}

        {cmd:kldb92_4d_to_kldb10_3d(}{varname}{cmd:)}

{pstd}
    where {it:varname} contains 4-digit KldB-1992 codes.

{title:Description}

{pstd}
    {helpb kldbrecode} table translating KldB-1992 types of occupations (4 digit codes) to KldB-2010 occupational groups (3 digit codes) using {helpb crosswalk}.

{pstd}
    {cmd:kldb92_4d_to_kldb10_3d()} is implemented as a wrapper for 
    {helpb _cwfcn_kldb92_4d_to_kldb10_5d:kldb92_4d_to_kldb10_5d()} followed by
    {helpb _cwfcn_kldb10_5d_to_kldb10_4d:kldb10_5d_to_kldb10_4d()} followed by
    {helpb _cwfcn_kldb10_4d_to_kldb10_3d:kldb10_4d_to_kldb10_3d()}.
    {p_end}
   
{pstd}  
    {helpb _cwfcn_kldb92_4d_to_kldb10_5d:kldb92_4d_to_kldb10_5d()} is non-unique and requires option {helpb crosswalk##dupl:duplicates()}.
    {p_end}

{hline}
{asis}
.kldb92_4d_to_kldb10_5d
.kldb10_5d_to_kldb10_4d
.kldb10_4d_to_kldb10_3d
