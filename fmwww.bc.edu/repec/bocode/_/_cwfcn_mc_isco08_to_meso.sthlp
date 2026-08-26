{smcl}
{* version 1.0.0  18aug2026}{...}
{hi:mc_isco08_to_meso()} {hline 2} Translate 4-digit ISCO-08 to Meso-SEC

{title:Syntax}

        {cmd:mc.isco08_to_meso(}{it:varname} {it:case}{cmd:)}

{pstd}
    where {it:varname} contains 4-digit ISCO-08 codes
    and {it:case} selects the employment status column.

{pstd}
    Typical usage:

        {cmd:mc.isco08_to_meso(}{it:varname} {cmd:case.mcempstat(}{it:sempl} {it:supvis}{cmd:)}{cmd:)}

{pstd}
    with {it:sempl} and {it:supvis} as described in
    {helpb _cwcasefcn_mcempstat:case.mcempstat()}.

{title:Description}

{pstd}
    {helpb crosswalk} table translating 4-digit ISCO-08 codes to
    the Multilevel Socio-Economic Classes: Meso-SEC (18 classes). Note that the Multilevel Socio-Economic Classes
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
    Multilevel Socio-Economic Classes crosswalk files for Meso-SEC,
    the 18-class scheme assessed in Hertel, Barone and Smallenbroek
    (2025); see References.
    {p_end}

{pstd}
    {cmd:mc_isco08_to_meso()} is implemented as a wrapper for
    {helpb _cwfcn_isco08_to_isco08_3:isco08_to_isco08_3()} followed by
    {helpb _cwfcn_mc_isco08_3_to_meso:mc_isco08_3_to_meso()}.
    {p_end}

{pstd}
    Class labels: {helpb _cwfcn_labels_mc_meso:labels_mc_meso()}
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
.isco08_to_isco08_3
.mc_isco08_3_to_meso
