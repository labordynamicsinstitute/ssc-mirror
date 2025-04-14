{smcl}
{* version 01.0.0 10apr2025 Hans Gerhardt and Anneke Kappes}{...}
{hi:kldb10_5d_to_kldb10_2plus5()} {hline 2} Translate 5-digit KldB-2010 to 2plus5-digit KldB-2010 codes

{title:Syntax}

        {cmd:kldb10_5d_to_kldb10_2plus5(}{varname}{cmd:)}

{pstd}
    where {it:varname} contains 5-digit KldB-2010 codes.

{title:Description}

{pstd}
    {helpb kldbrecode} table translating KldB-2010 occupational types (5 digit codes) to to KldB-2010 occupational main groups (2 digit codes) combined with the skill level (5th-digit) using {helpb crosswalk}.

{title:Source}

{pstd}
    {cmd:kldb10_5d_to_kldb10_2plus5()} is implemented as a wrapper for 
    {helpb _cwfcn_kldb10_5d_to_kldb10_3plus5:kldb10_5d_to_kldb10_3plus5()} followed by
    {helpb _cwfcn_kldb10_3plus5_to_kldb10_2plus5:kldb10_3plus5_to_kldb10_2plus5()}.
    {p_end}
    
{hline}
{asis}
.kldb10_5d_to_kldb10_3plus5
.kldb10_3plus5_to_kldb10_2plus5
