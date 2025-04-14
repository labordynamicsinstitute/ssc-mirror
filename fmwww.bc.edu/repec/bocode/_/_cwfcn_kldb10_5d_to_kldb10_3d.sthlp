{smcl}
{* version 01.0.0 10apr2025 Hans Gerhardt and Anneke Kappes}{...}
{hi:kldb10_5d_to_kldb10_3d()} {hline 2} Translate 5-digit KldB-2010 to 3-digit KldB-2010 codes

{title:Syntax}

        {cmd:kldb10_5d_to_kldb10_3d(}{varname}{cmd:)}

{pstd}
    where {it:varname} contains 5-digit KldB-2010 codes.

{title:Description}

{pstd}
    {helpb kldbrecode} table translating KldB-2010 occupational types (5 digit codes) to KldB-2010 occupational groups (3 digit codes) using {helpb crosswalk}.

{title:Source}

{pstd}
    {cmd:kldb10_5d_to_kldb10_3d()} is implemented as a wrapper for 
    {helpb _cwfcn_kldb10_5d_to_kldb10_4d:kldb10_5d_to_kldb10_4d()} followed by
    {helpb _cwfcn_kldb10_4d_to_kldb10_3d:kldb10_4d_to_kldb10_3d()}.
    {p_end}
    
{hline}
{asis}
.kldb10_5d_to_kldb10_4d
.kldb10_4d_to_kldb10_3d
