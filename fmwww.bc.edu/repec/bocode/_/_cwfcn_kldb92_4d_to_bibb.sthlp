{smcl}
{* version 01.0.0 10apr2025 Hans Gerhardt and Anneke Kappes}{...}
{hi:kldb92_4d_to_bibb()} {hline 2} Translate 4-digit KldB-1992 codes to BIBB-Occupational-Fields

{title:Syntax}

        {cmd:kldb92_4d_to_bibb(}{varname} [{help crosswalk##case:{it:case}}]{cmd:)}

{pstd}
    where {it:varname} contains 4-digit KldB-1992 codes.

{title:Description}

{pstd}
    {helpb kldbrecode} table translating KldB-1992 types of occupations (4 digit codes) to BIBB-Occupational-Fields using {helpb crosswalk}.

{pstd}
    Besides the original crosswalk from the BIBB, this {helpb kldbrecode} table provides a modified version by Hans Gerhardt.
    The modified version improves the overlap in microcensus 2012 data when recoding both KldB-1992 and KldB-2010 codes to BIBB occupational fields. 
    Therefore, it provides more consistent time series with microcensus data.
    To access the modified crosswalk from the second column specify the {help crosswalk##case:{it:case argument}}.
    {p_end}

        {cmd:kldb92_4d_to_bibb(}{varname} 2{cmd:)}

{title:Source}

{pstd}
    {cmd:kldb92_4d_to_bibb()} is implemented as a wrapper for 
    {helpb _cwfcn_kldb92_4d_to_kldb92_3d:kldb92_4d_to_kldb92_3d()} followed by
    {helpb _cwfcn_kldb92_3d_to_bibb:kldb92_3d_to_bibb()}.
    {p_end}
    
{hline}
{asis}
.kldb92_4d_to_kldb92_3d
.kldb92_3d_to_bibb
