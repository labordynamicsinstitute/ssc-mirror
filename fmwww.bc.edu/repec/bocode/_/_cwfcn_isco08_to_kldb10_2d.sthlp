{smcl}
{* version 01.0.0 10apr2025 Hans Gerhardt and Anneke Kappes}{...}
{hi:isco08_to_kldb10_2d()} {hline 2} Translate 4-digit ISCO-08 to 2-digit KldB-2010

{title:Syntax}

        {cmd:isco08_to_kldb10_2d(}{varname}{cmd:)}

{pstd}
    where {it:varname} contains 4-digit ISCO-08 codes.

{title:Description}

{pstd}
    {helpb kldbrecode} table translating  4-digit ISCO-08 codes to KldB-2010 occupational main groups (2 digit codes) using {helpb crosswalk}.
    {p_end}

{pstd}
    {cmd:isco08_to_kldb10_2d()} is implemented as a wrapper for 
    {helpb _csfnc_isco08_to_kldb10_3plus5:isco08_to_kldb10_3plus5()} followed by
    {helpb _cwfcn_kldb10_3plus5_to_kldb10_3d:kldb10_3plus5_to_kldb10_3d()} followed by
    {helpb _cwfcn_kldb10_3d_to_kldb10_2d:kldb10_3d_to_kldb10_2d()}.
    {p_end}
 
{pstd}
    {helpb _cwfcn_isco08_to_kldb10_3plus5:isco08_to_kldb10_3plus5()} is non-unique and requires option {helpb crosswalk##dupl:duplicates()}.
    {p_end}
   
{hline}
{asis}
.isco08_to_kldb10_3plus5
.kldb10_3plus5_to_kldb10_3d
.kldb10_3d_to_kldb10_2d
