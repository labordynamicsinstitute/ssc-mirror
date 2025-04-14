{smcl}
{* version 01.0.0 10apr2025 Hans Gerhardt and Anneke Kappes}{...}
{hi:kldb10_3plus5_to_kldb10_2d()} {hline 2} Translate 3plus5-digit KldB-2010 to 2-digit KldB-2010 codes

{title:Syntax}

        {cmd:kldb10_3plus5_to_kldb10_2d(}{varname}{cmd:)}

{pstd}
    where {it:varname} contains 3plus5-digit KldB-2010 codes.

{title:Description}

{pstd}
    {helpb kldbrecode} table translating KldB-2010 occupational groups (3 digits) combined with the skill level (5th-digit) to KldB-2010 occupational main groups (2 digit codes) using {helpb crosswalk}.

{title:Source}

{pstd}
    {cmd:kldb10_3plus5_to_kldb10_2d()} is implemented as a wrapper for 
    {helpb _cwfcn_kldb10_3plus5_to_kldb10_3d:kldb10_3plus5_to_kldb10_3d()} followed by
    {helpb _cwfcn_kldb10_3d_to_kldb10_2d:kldb10_3d_to_kldb10_2d()}.
    {p_end}
    
{hline}
{asis}
.kldb10_3plus5_to_kldb10_3d
.kldb10_3d_to_kldb10_2d
