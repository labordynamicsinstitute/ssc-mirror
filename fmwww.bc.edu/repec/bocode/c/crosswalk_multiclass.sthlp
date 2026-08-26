{smcl}
{* version 2.0.0  18aug2026}{...}
{viewerjumpto "Description" "crosswalk_multiclass##description"}{...}
{viewerjumpto "Tables" "crosswalk_multiclass##tables"}{...}
{viewerjumpto "Employment status" "crosswalk_multiclass##case"}{...}
{viewerjumpto "Examples" "crosswalk_multiclass##examples"}{...}
{viewerjumpto "Where is ESeC?" "crosswalk_multiclass##esec"}{...}
{viewerjumpto "Sources" "crosswalk_multiclass##sources"}{...}
{viewerjumpto "References" "crosswalk_multiclass##refs"}{...}
{hi:crosswalk_multiclass} {hline 2} Crosswalk tables for the Multilevel Socio-Economic Classes class schemes


{marker description}{title:Description}

{pstd}
    {cmd:crosswalk_multiclass} provides {helpb crosswalk} tables translating
    ISCO-88com and ISCO-08 occupational codes into the Multilevel
    Socio-Economic Classes (MSEC) schemes. MSEC comprises of three social class
    schemas that are hierarchically nested in the well known ESeC schema (Harrison & Rose 2006). 
    The most disaggregated micro-level scheme (Micro-SEC) differentiates 30 occupational classes 
    based on tasks respecting ESeC employment relations. These occupational classes are nested in
     a meso-level scheme (Meso-SEC) differentiating 18 classes according to four work logics. 
     These are again nested within the macro-level scheme (Macro-SEC) constituting  a variant 
     of 11 ESeC classes including disaggregating the upper and lower salariat into managerial
     & professional fractions.

{p2colset 9 26 28 2}{...}
{p2col :{it:scheme}}{it:classes}  {it:description}{p_end}
{p2col :{cmd:micro}}30  Micro-SEC{p_end}
{p2col :{cmd:meso}}18  Meso-SEC{p_end}
{p2col :{cmd:macro}}11  Macro-SEC - ESEC + separating professionals from managers in ESEC classes I and II{p_end}
{p2colreset}{...}

{pstd}
    This package also contains a crosswalk for {cmd:microclass}, a 77  microclass scheme (ISCO-08 only, {bf:not} MSEC).
    The microclass scheme is an ISCO-08 implementation of Jonsson et al. (2009) ISCO-88 crosswalk. 
    The microclass scheme is not nested into ESEC or part of the MSEC. It is included here to facilitate replication of 
    Hertel, Barone and Smallenbroek (2025).


{pstd}
    This package does not define any commands: all 
    recoding is carried out by {helpb crosswalk}. Install it with

        {cmd:. ssc install crosswalk, replace}
        {cmd:. ssc install moremata, replace}

{marker tables}{title:Tables}


{pstd}
    Tables using 4-digit ISCO codes (e.g. 2130 for "Life science professionals"):

{p2colset 9 46 48 2}{...}
{p2col :{helpb _cwfcn_mc_isco88com_to_micro:mc.isco88com_to_micro()}}ISCO-88com to Micro-SEC{p_end}
{p2col :{helpb _cwfcn_mc_isco88com_to_meso:mc.isco88com_to_meso()}}ISCO-88com to Meso-SEC{p_end}
{p2col :{helpb _cwfcn_mc_isco88com_to_macro:mc.isco88com_to_macro()}}ISCO-88com to Macro-SEC{p_end}
{p2col :{helpb _cwfcn_mc_isco08_to_micro:mc.isco08_to_micro()}}ISCO-08 to Micro-SEC{p_end}
{p2col :{helpb _cwfcn_mc_isco08_to_meso:mc.isco08_to_meso()}}ISCO-08 to Meso-SEC{p_end}
{p2col :{helpb _cwfcn_mc_isco08_to_macro:mc.isco08_to_macro()}}ISCO-08 to Macro-SEC{p_end}
{p2col :{helpb _cwfcn_mc_isco08_to_microclass:mc.isco08_to_microclass()}}ISCO-08 to microclass (no case){p_end}
{p2colreset}{...}

{pstd}
    Tables using 3-digit ISCO codes known as minor ISCO groups (e.g. 213 for "Life science professionals"):

{p2colset 9 46 48 2}{...}
{p2col :{helpb _cwfcn_mc_isco88_3_to_micro:mc.isco88_3_to_micro()}}and {cmd:_to_meso()}, {cmd:_to_macro()}{p_end}
{p2col :{helpb _cwfcn_mc_isco08_3_to_micro:mc.isco08_3_to_micro()}}and {cmd:_to_meso()}, {cmd:_to_macro()}{p_end}
{p2colreset}{...}

{pstd}
    Type the tables with the {cmd:mc.} prefix. The prefix is what makes
    {helpb crosswalk} pick up this package's class labels.

{pstd}
    Micro-SEC, Meso-SEC and Macro-SEC are defined jointly over occupation
    {it:and} employment relation, so those tables take a
    {help crosswalk##case:case} argument; see
    {help crosswalk_multiclass##case:Employment status} below. The 77-category
    microclass scheme is purely occupational and takes no case.
    
{pstd}
    Case function:

{p2colset 9 46 48 2}{...}
{p2col :{helpb _cwcasefcn_mcempstat:case.mcempstat()}}case from {it:sempl} and {it:supvis}{p_end}
{p2colreset}{...}


{marker case}{title:Employment status}

{pstd}
    The case follows the same convention as the ESeC tables that ship with
    {helpb crosswalk}:

        1 = employment status unknown
        2 = employed, without supervisory status
        3 = employed, with supervisory status
        4 = self-employed, no employees
        5 = self-employed, 1-9 employees
        6 = self-employed, 10 or more employees

{pstd}
    Build it with {helpb _cwcasefcn_mcempstat:case.mcempstat()} from a
    self-employment indicator and a supervisory or employee-count variable.
    Note that {helpb crosswalk}'s {helpb _cwcasefcn_esec88:case.esec88()} 
    treats missing values of self-employement and number of employees/superivsees differently. 

{pstd}
    {bf:Column 1 is missing} {cmd:.} {bf:in every table.} Multilevel Socio-Economic Classes has no simplified
    variant for unknown employment status, so observations whose employment
    status is unknown come back uncoded rather than silently picking up
    another class. 


{marker examples}{title:Examples}

{pstd}From a self-employment indicator and a supervisory variable:{p_end}
{phang2}{cmd:. crosswalk micro = mc.isco08_to_micro(isco08 case.mcempstat(selfemp nsuperv))}{p_end}

{pstd}ISCO-88com to Macro-SEC:{p_end}
{phang2}{cmd:. crosswalk macro = mc.isco88com_to_macro(isco88 case.mcempstat(selfemp nsuperv))}{p_end}

{pstd}All three employment-relation schemes at once:{p_end}
{phang2}{cmd:. foreach s in micro meso macro {c -(}}{p_end}
{phang2}{cmd:.     crosswalk `s' = mc.isco08_to_`s'(isco08 case.mcempstat(selfemp nsuperv))}{p_end}
{phang2}{cmd:. {c )-}}{p_end}

{pstd}3-digit minor groups:{p_end}
{phang2}{cmd:. crosswalk meso = mc.isco08_3_to_meso(isco3 case.mcempstat(selfemp nsuperv))}{p_end}

{pstd}The microclass scheme, which takes no case:{p_end}
{phang2}{cmd:. crosswalk microclass = mc.isco08_to_microclass(isco08)}{p_end}


{marker esec}{title:Where is ESeC?}

{pstd}
    There is no {cmd:mc.}{it:origin}{cmd:_to_esec()} table. {helpb crosswalk}
    already ships {helpb _cwfcn_isco88_to_esec:isco88_to_esec()} and
    {helpb _cwfcn_isco08_to_esec:isco08_to_esec()} for the 9-class ESeC.{p_end}
{pstd}
    They take a {it:different} case function: {cmd:isco88_to_esec()} takes
    {helpb _cwcasefcn_esec88:case.esec88()} (6 columns, with an "unknown" case,
    the same numbering used here), while {cmd:isco08_to_esec()} takes
    {helpb _cwcasefcn_esec:case.esec()} (5 columns, {it:no} "unknown" case).
    Note these treat missing values differently from {helpb _cwcasefcn_mcempstat:case.mcempstat()}, 
    which treats any missing data as unknown employment status.{p_end} 

{marker sources}{title:Sources}

{pstd}
    Smallenbroek, Hertel and Barone (2022) introduced {cmd:Macro-SEC}. Hertel, Barone
    and Smallenbroek (2025) assessed Macro-SEC alongside other class schemes.{p_end}

{pstd}
    Note that the Micro-SEC assessed in Hertel et al. (2025) is an earlier
    prototype, whose development is documented at
    {browse "https://osf.io/preprints/socarxiv/962q3_v1"}. It is {it:not} the
    version of Micro-SEC shipped here. The paper documenting Micro-SEC and Meso-SEC
    implemented in this package is under review.{p_end}

{pstd}
    The microclass scheme is a separate 77-category schema built from ISCO-08
    occupational titles and descriptions, following the microclass approach of
    Grusky, Weeden and Sorensen (2000) and Weeden and Grusky (2005) and
    emulating the categories of Jonsson et al. (2009). It is documented in
    Smallenbroek, Hertel and Barone (2026).{p_end}

{marker refs}{title:References}


{phang}
    Smallenbroek, O., F. R. Hertel, C. Barone. 2022. Measuring Class
    Hierarchies in Postindustrial Societies: A Criterion and Construct
    Validation of EGP and ESEC Across 31 Countries. Sociological Methods &
    Research 53(3):1412-52. doi:10.1177/00491241221134522.
    {p_end}
   
{phang}
    Hertel, F. R., C. Barone, O. Smallenbroek. 2025. The Multiverse of Social
    Class. A Large-Scale Assessment of Macro-Level, Meso-Level and Micro-Level
    Approaches to Class Analysis. European Societies 1-65.
    doi:10.1162/euso_a_00044.
    {p_end}

{phang}
    Smallenbroek, O., F. R. Hertel, C. Barone. 2026. Adapting the Microclass
    Schema for Cross-national Research. Retrieved
    {browse "https://osf.io/preprints/socarxiv/xaqju_v1":osf.io/preprints/socarxiv/xaqju_v1}.
    {p_end}

{phang}
    Jonsson, J. O., D. B. Grusky, M. Di Carlo, R. Pollak, M. C. Brinton. 2009.
    Microclass Mobility: Social Reproduction in Four Countries. American
    Journal of Sociology 114(4):977-1036. doi:10.1086/596566.
    {p_end}

{phang}
    Weeden, K. A., D. B. Grusky. 2005. The Case for a New Class Map. American
    Journal of Sociology 111(1):141-212. doi:10.1086/428815.
    {p_end}

{phang}
    Grusky, D. B., K. A. Weeden, J. B. Sorensen. 2000. The Case for Realism in
    Class Analysis. Political Power and Social Theory 14:291-305.
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

{title:Author}

{pstd}
    Oscar Smallenbroek.

{pstd}
    Source and issue tracker:
    {browse "https://github.com/OscarSmallenbroek/crosswalk_multiclass"}.


{title:Also see}

{psee}
    {helpb crosswalk} {hline 2} the command that executes these tables
{p_end}
