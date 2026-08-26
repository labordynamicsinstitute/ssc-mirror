{smcl}
{* version 1.0.0  18aug2026}{...}
{hi:mc_isco88com_to_macro()} {hline 2} Translate 4-digit ISCO-88(com) to Macro-SEC

{title:Syntax}

        {cmd:mc.isco88com_to_macro(}{it:varname} {it:case}{cmd:)}

{pstd}
    where {it:varname} contains 4-digit ISCO-88(com) codes
    and {it:case} selects the employment status column.

{pstd}
    Typical usage:

        {cmd:mc.isco88com_to_macro(}{it:varname} {cmd:case.mcempstat(}{it:sempl} {it:supvis}{cmd:)}{cmd:)}

{pstd}
    with {it:sempl} and {it:supvis} as described in
    {helpb _cwcasefcn_mcempstat:case.mcempstat()}.

{title:Description}

{pstd}
    {helpb crosswalk} table translating 4-digit ISCO-88(com) codes to
    the Macro-SEC - ESEC plus differentiation of SC I and II (11 classes). Note that the Multilevel Socio-Economic Classes
    are defined at the level of minor ISCO groups
    (3 digit); that is, all unit groups within a minor group
    translate into the same class.

{pstd}
    Cases (destination columns), following the same convention as the ESeC
    tables shipped with {helpb crosswalk}:

        1 = employment status unknown
        2 = employed, without supervisory status
        3 = employed, with supervisory status
        4 = self-employed, no employees
        5 = self-employed, 1-9 employees
        6 = self-employed, 10 or more employees

{pstd}
    Column 1 is {cmd:.} throughout: the Multilevel Socio-Economic Classes have no simplified
    variant for unknown employment status, so observations whose employment
    status is unknown come back uncoded rather than picking up another class.

{title:Source}

{pstd}
    Multilevel Socio-Economic Classes crosswalk files for Macro-SEC,
    introduced in Smallenbroek, Hertel and Barone (2022); see
    References.
    {p_end}

{pstd}
    {cmd:mc_isco88com_to_macro()} is implemented as a wrapper for
    {helpb _cwfcn_isco88_to_isco88_3:isco88_to_isco88_3()} followed by
    {helpb _cwfcn_mc_isco88_3_to_macro:mc_isco88_3_to_macro()}.
    {p_end}

{pstd}
    Note that this table is based on
    {browse "https://warwick.ac.uk/fac/soc/ier/research/classification/isco88":ISCO-88(COM)},
    the European Union variant of the ISCO-88. If your data contains ISCO-88
    codes you might first want to translate these codes to ISCO-88(COM) using
    {helpb _cwfcn_isco88_to_isco88com:isco88_to_isco88com()}.

{pstd}
    For plain 9-class ESeC, use {helpb crosswalk}'s own
    {helpb _cwfcn_isco88_to_esec:isco88_to_esec()} /
    {helpb _cwfcn_isco08_to_esec:isco08_to_esec()} rather than a table from
    this package; see {help crosswalk_multiclass##esec:crosswalk_multiclass}
    for why, and note that they take a different case function
    ({helpb _cwcasefcn_esec88:case.esec88()} /
    {helpb _cwcasefcn_esec:case.esec()}, not
    {helpb _cwcasefcn_mcempstat:case.mcempstat()}).

{pstd}
    Class labels: {helpb _cwfcn_labels_mc_macro:labels_mc_macro()}
    {p_end}

{title:References}

{phang}
    Hertel, F. R., C. Barone, O. Smallenbroek. 2025. The Multiverse of Social
    Class. A Large-Scale Assessment of Macro-Level, Meso-Level and Micro-Level
    Approaches to Class Analysis. European Societies 1-65.
    doi:10.1162/euso_a_00044.
    {p_end}

{phang}
    Smallenbroek, O., F. R. Hertel, C. Barone. 2022. Measuring Class
    Hierarchies in Postindustrial Societies: A Criterion and Construct
    Validation of EGP and ESEC Across 31 Countries. Sociological Methods &
    Research 53(3):1412-52. doi:10.1177/00491241221134522.
    {p_end}

{phang}
    Harrison, E., D. Rose. 2006. The European Socio-economic Classification
    (ESeC) User Guide. Institute for Social and Economic Research, University
    of Essex.
    {p_end}

{phang}
    Jann, B. 2025. crosswalk: Stata module to recode variables based on
    crosswalk tables. Statistical Software Components S459534, Boston College
    Department of Economics.
    {p_end}

{hline}
{asis}
.isco88_to_isco88_3
.mc_isco88_3_to_macro
