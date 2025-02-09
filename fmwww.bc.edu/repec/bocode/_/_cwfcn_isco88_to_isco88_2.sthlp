{smcl}
{* version 1.0.0  06feb2025  Ben Jann}{...}
{hi:isco88_to_isco88_2()} {hline 2} Translate 4-digit ISCO-88 to 2-digit ISCO-88

{title:Syntax}

        {cmd:isco88_to_isco88_2(}{varname}{cmd:)}

{pstd}
    where {it:varname} contains 4-digit ISCO-88 codes.

{title:Description}

{pstd}
    {helpb crosswalk} table translating 4-digit ISCO-88 codes (unit groups)
    to 2-digit ISCO-88 codes (sub-major groups).

{title:Source}

{pstd}
    {cmd:isco88_to_isco88_2()} is implemented as a wrapper for 
    {helpb _cwfcn_isco88_to_isco88_3:isco88_to_isco88_3()} followed by
    {helpb _cwfcn_isco88_3_to_isco88_2:isco88_3_to_isco88_2()}.
    {p_end}
{hline}
{asis}
.isco88_to_isco88_3
.isco88_3_to_isco88_2
