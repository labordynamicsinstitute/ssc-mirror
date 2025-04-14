{smcl}
{* version 01.0.0 10apr2025 Hans Gerhardt and Anneke Kappes}{...}
{hi:kldb10_4d_to_kldb10_2d()} {hline 2} Translate 4-digit KldB-2010 to 2-digit KldB-2010 codes

{title:Syntax}

        {cmd:kldb10_4d_to_kldb10_2d(}{varname}{cmd:)}

{pstd}
    where {it:varname} contains 4-digit KldB-2010 codes.

{title:Description}

{pstd}
    {helpb kldbrecode} table translating KldB-2010 occupationals sub-groups (4 digit codes) to KldB-2010 occupational main groups (2 digit codes) using {helpb crosswalk}.

{pstd}
    {cmd:kldb10_4d_to_kldb10_2d()} is implemented as a wrapper for 
    {helpb _cwfcn_kldb10_4d_to_kldb10_3d:kldb10_4d_to_kldb10_3d()} followed by
    {helpb _cwfcn_kldb10_3d_to_kldb10_2d:kldb10_3d_to_kldb10_2d()}.
    {p_end}
    
{hline}
{asis}
.kldb10_4d_to_kldb10_3d
.kldb10_3d_to_kldb10_2d
