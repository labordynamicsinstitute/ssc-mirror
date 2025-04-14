{smcl}
{* version 01.0.0 10apr2025 Hans Gerhardt and Anneke Kappes}{...}
{hi:kldb10_5d_to_bibb()} {hline 2} Translate 5-digit KldB-2010 codes to BIBB-Occupational-Fields

{title:Syntax}

        {cmd:kldb10_5d_to_bibb(}{varname}{cmd:) [{help crosswalk##case:{it:case}}]{cmd:)}

{pstd}
    where {it:varname} contains 5-digit KldB-2010 codes.

{title:Description}

{pstd}
    {helpb kldbrecode} table translating KldB-2010 occupational types (5 digit codes) to BIBB occupational fields (2 digit codes) using {helpb crosswalk}.

{pstd}
    Besides the original crosswalk from the BIBB, this {helpb kldbrecode} table provides a modified version by Hans Gerhardt.
    The original crosswalk has been developed by Tiemann (2018) by maximizing the match of the task composition within 3plus5-digit KldB-2010 codes to the task composition that define the BIBB occupational field.
    The modified version improves the overlap in microcensus 2012 data when recoding both KldB-1992 and KldB-2010 codes to BIBB occupational fields.
    Therefore, it provides more consistent time series with microcensus data.
    To access the modified crosswalk from the second column specify the {help crosswalk##case:{it:case argument}}..
    {p_end}

        {cmd:kldb10_5d_to_bibb(}{varname} 2{cmd:)}

{title:Source}

{pstd}
    {cmd:kldb10_5d_to_bibb()} is implemented as a wrapper for 
    {helpb _cwfcn_kldb10_5d_to_kldb10_3plus5:kldb10_5d_to_kldb10_3plus5()} followed by
    {helpb _cwfcn_kldb10_3plus5_to_bibb:kldb10_3plus5_to_bibb()}.
    {p_end}
    
{hline}
{asis}
.kldb10_5d_to_kldb10_3plus5
.kldb10_3plus5_to_bibb
