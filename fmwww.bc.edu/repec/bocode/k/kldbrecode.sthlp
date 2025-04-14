{smcl}
{* version 0.03.0 04apr2025}{...}
{vieweralsosee "[D] crosswalk" "help crosswalk"}{...}
{viewerjumpto "Syntax" "kldbrecode##syntax"}{...}
{viewerjumpto "Translations" "kldbrecode##kldbrec"}{...}
{viewerjumpto "Labels" "kldbrecode##kldblbl"}{...}
{viewerjumpto "Examples" "kldbrecode##examples"}{...}
{viewerjumpto "References" "kldbrecode##references"}{...}
{viewerjumpto "Authors" "kldbrecode##author"}{...}
{hi:help kldbrecode}{...}
{right:{browse "https://github.com/hagerhardt/kldbrecode"}}
{hline}

{title:Title}

{pstd}{hi:kldbrecode} {hline 2} Crosswalk tables to translate German Classifications of Occupations (KldB)

{marker syntax}{...}
{title:Syntax}

{pstd}
    The recodings can be performed using the {help crosswalk:crosswalk} command by Ben Jann.

    Recode a variable using crosswalk table {it:kldbrec}{cmd:()}

{p 8 15 2}
    {cmd:crosswalk} {newvar} {cmd:=}
    {help kldbrecode##kldbrec:{it:kldbrec}}{cmd:(}{it:varname} [{help crosswalk##case:{it:case}}]{cmd:)}
    {ifin} [{cmd:,} {help crosswalk##opt:{it:crosswalk options}} ]

{pstd}
    Assign {it:kldblbl} (to existing variables)

{p 8 15 2}
    {cmd:crosswalk} {cmdab:l:abel} {help kldbrecode##kldblbl:{it:kldblbl}}
    [{varlist}] [{cmd:,} {help crosswalk##lblopt:{it:crosswalk label_options}} ]

{pstd}
    For options and more utilities see help for {help crosswalk:crosswalk}.

{synoptset 33}{...}
{marker kldbrec}{synopt :{it:kldbrec}()}Description{p_end}
{synoptset 33 tabbed}{...}
{synoptline}

{synopt : {ul: Translations from KldB-2010}}{p_end}

{synopt :{helpb _cwfcn_kldb10_5d_to_kldb88_3d:kldb10_5d_to_kldb88_3d()}}KldB-2010 (5 digit) to KldB-1988; also see{break}
    {helpb _cwfcn_kldb10_5d_to_kldb88_2d:kldb10_5d_to_kldb88_2d()}{break}
    {helpb _cwfcn_kldb10_5d_to_kldb88harm:kldb10_5d_to_kldb88harm()}{p_end}
{synopt :{helpb _cwfcn_kldb10_5d_to_isco08:kldb10_5d_to_isco08()}}KldB-2010 (5 digit) to ISCO-08 (non-unique); also see{break}
    {helpb _cwfcn_kldb10_5d_to_isco08_3:kldb10_5d_to_isco08_3()}{break}
    {helpb _cwfcn_kldb10_5d_to_isco08_2:kldb10_5d_to_isco08_2()}{break}
    {helpb _cwfcn_kldb10_5d_to_isco08_1:kldb10_5d_to_isco08_1()}{p_end}
{synopt :{helpb _cwfcn_kldb10_3plus5_to_isco08:kldb10_3plus5_to_isco08()}}KldB-2010 (3plus5 digit) to ISCO-08 (non-unique); also see{break}
    {helpb _cwfcn_kldb10_3plus5_to_isco08_3:kldb10_3plus5_to_isco08_3()}{break}
    {helpb _cwfcn_kldb10_3plus5_to_isco08_2:kldb10_3plus5_to_isco08_2()}{break}
    {helpb _cwfcn_kldb10_3plus5_to_isco08_1:kldb10_3plus5_to_isco08_1()}{p_end}
{synopt :{helpb _cwfcn_kldb10_3plus5_to_bibb:kldb10_3plus5_to_bibb()}}KldB-2010 (3plus5 digit) to BIBB occupational fields; also see{break}
    {helpb _cwfcn_kldb10_5d_to_bibb:kldb10_5d_to_bibb()}{p_end}


{synopt : {ul: Translations from KldB-1992}}{p_end}

{synopt :{helpb _cwfcn_kldb92_4d_to_kldb10_5d:kldb92_4d_to_kldb10_5d()}}KldB-1992 (4 digit) to KldB-2010 (5 digit) (non-unique); also see{break}
    {helpb _cwfcn_kldb92_4d_to_kldb10_3plus5:kldb92_4d_to_kldb10_3plus5()}{break}
    {helpb _cwfcn_kldb92_4d_to_kldb10_2plus5:kldb92_4d_to_kldb10_2plus5()}{break}
    {helpb _cwfcn_kldb92_4d_to_kldb10_4d:kldb92_4d_to_kldb10_4d()}{break}
    {helpb _cwfcn_kldb92_4d_to_kldb10_3d:kldb92_4d_to_kldb10_3d()}{break}
    {helpb _cwfcn_kldb92_4d_to_kldb10_2d:kldb92_4d_to_kldb10_2d()}{p_end}
{synopt :{helpb _cwfcn_kldb92_3d_to_kldb10_2d:kldb92_3d_to_kldb10_2d()}}KldB-1992 (3 digit) to KldB-2010 (2-digit) (non-unique){p_end}
{synopt :{helpb _cwfcn_kldb92_3d_to_kldb10_3d:kldb92_3d_to_kldb10_3d()}}KldB-1992 (3 digit) to KldB-2010 (3-digit) (non-unique){p_end}
{synopt :{helpb _cwfcn_kldb92_3d_to_kldb10_2plus5:kldb92_3d_to_kldb10_2plus5()}}KldB-1992 (3 digit) to KldB-2010 (2plus5-digit) (non-unique){p_end}
{synopt :{helpb _cwfcn_kldb92_3d_to_kldb88_3d:kldb92_3d_to_kldb88_3d()}}KldB-1992 (3 digit) to KldB-1988; also see{break}
    {helpb _cwfcn_kldb92_4d_to_kldb88_3d:kldb92_4d_to_kldb88_3d()}{break}
    {helpb _cwfcn_kldb92_3d_to_kldb88_2d:kldb92_3d_to_kldb88_2d()}{break}
    {helpb _cwfcn_kldb92_4d_to_kldb88_2d:kldb92_4d_to_kldb88_2d()}{p_end}
{synopt :{helpb _cwfcn_kldb92_3d_to_kldb88harm:kldb92_3d_to_kldb88harm()}}KldB-1992 (3 digit) to KldB-1988, harmonized version; also see{break}
    {helpb _cwfcn_kldb92_4d_to_kldb88harm:kldb92_4d_to_kldb88harm()}{p_end}
{synopt :{helpb _cwfcn_kldb92_4d_to_isco88_3:kldb92_4d_to_isco88_3()}}KldB-1992 (4 digit) to ISCO-88 (3 digit); also see{break}
    {helpb _cwfcn_kldb92_4d_to_isco88_2:kldb92_4d_to_isco88_2()}{break}
    {helpb _cwfcn_kldb92_4d_to_isco88_1:kldb92_4d_to_isco88_1()}{p_end}
{synopt :{helpb _cwfcn_kldb92_3d_to_bibb:kldb92_3d_to_bibb()}}KldB-1992 (3 digit) to BIBB occupational fields; also see{break}
    {helpb _cwfcn_kldb92_4d_to_bibb:kldb92_4d_to_bibb()}{p_end}


{synopt : {ul: Translations from KldB-1988}}{p_end}

{synopt :{helpb _cwfcn_kldb88_4d_to_kldb10_5d:kldb88_4d_to_kldb10_5d()}}KldB-1988 (4 digit) to KldB-2010 (5 digit) (non-unique); also see{break}
    {helpb _cwfcn_kldb88_4d_to_kldb10_3plus5:kldb88_4d_to_kldb10_3plus5()}{break}
    {helpb _cwfcn_kldb88_4d_to_kldb10_2plus5:kldb88_4d_to_kldb10_2plus5()}{break}
    {helpb _cwfcn_kldb88_4d_to_kldb10_4d:kldb88_4d_to_kldb10_4d()}{break}
    {helpb _cwfcn_kldb88_4d_to_kldb10_3d:kldb88_4d_to_kldb10_3d()}{break}
    {helpb _cwfcn_kldb88_4d_to_kldb10_2d:kldb88_4d_to_kldb10_2d()}{p_end}
{synopt :{helpb _cwfcn_kldb88_3d_to_kldb10_5d:kldb88_3d_to_kldb10_5d()}}KldB-1988 (3 digit) to KldB-2010 (5 digit) (non-unique); also see{break}
    {helpb _cwfcn_kldb88_3d_to_kldb10_3plus5:kldb88_3d_to_kldb10_3plus5()}{break}
    {helpb _cwfcn_kldb88_3d_to_kldb10_2plus5:kldb88_3d_to_kldb10_2plus5()}{break}
    {helpb _cwfcn_kldb88_3d_to_kldb10_4d:kldb88_3d_to_kldb10_4d()}{break}
    {helpb _cwfcn_kldb88_3d_to_kldb10_3d:kldb88_3d_to_kldb10_3d()}{break}
    {helpb _cwfcn_kldb88_3d_to_kldb10_2d:kldb88_3d_to_kldb10_2d()}{p_end}
{synopt :{helpb _cwfcn_kldb88_3d_to_kldb88harm:kldb88_3d_to_kldb88harm()}}KldB-1988 (3 digit) to KldB-1988, harmonized version; also see{break}
    {helpb _cwfcn_kldb88_4d_to_kldb88harm:kldb88_4d_to_kldb88harm()}{p_end}
{synopt :{helpb _cwfcn_kldb88_3d_to_bibb:kldb88_3d_to_bibb()}}KldB-1988 (3 digit) to BIBB occupational fields; also see{break}
    {helpb _cwfcn_kldb88_4d_to_bibb:kldb88_4d_to_bibb()}{p_end}


{synopt : {ul: Translations from KldB-1975}}{p_end}

{synopt :{helpb _cwfcn_kldb75_3d_to_kldb88_3d:kldb75_3d_to_kldb88_3d()}}KldB-1975 (3 digit) to KldB-1988; also see{break}
    {helpb _cwfcn_kldb75_3d_to_kldb88_2d:kldb75_3d_to_kldb88_2d()}{p_end}
{synopt :{helpb _cwfcn_kldb75_3d_to_kldb88harm:kldb75_3d_to_kldb88harm()}}KldB-1975 (3 digit) to KldB-1988, harmonized version{p_end}


{synopt : {ul: Translation from ISCO-08}}{p_end}

{synopt :{helpb _cwfcn_isco08_to_kldb10_3plus5:isco08_to_kldb10_3plus5()}}ISCO-08 (4 digit) to KldB-2010 (3plus5 digit) (non-unique); also see{break}
    {helpb _cwfcn_isco08_to_kldb10_2plus5:isco08_to_kldb10_2plus5()}{break}
    {helpb _cwfcn_isco08_to_kldb10_3d:isco08_to_kldb10_3d()}{break}
    {helpb _cwfcn_isco08_to_kldb10_2d:isco08_to_kldb10_2d()}{p_end}
{synopt :{helpb _cwfcn_isco08_to_bibb:isco08_to_bibb()}}ISCO-08 (4 digit) to (modified) BIBB fields{p_end}


{synopt : {ul: Occupational Prestige Scale for KldB-2010} by {help kldbrecode##bas:Ebner and Rohrbach-Schmidt (2021)}}{p_end}

{synopt :{helpb _cwfcn_kldb10_2plus5_to_bas25:kldb10_2plus5_to_bas25()}}Occupational Prestige Scale (BAS-2|5) for KldB-2010 (2plus5-digit); also see{break}
    {helpb _cwfcn_kldb10_5d_to_bas25:kldb10_5d_to_bas25()}{break}
    {helpb _cwfcn_kldb10_3plus5_to_bas25:kldb10_3plus5_to_bas25()}{p_end}
{synopt :{helpb _cwfcn_kldb10_3d_to_bas3:kldb10_3d_to_bas3()}}Occupational Prestige Scale (BAS-3) for KldB-2010 (3-digit); also see{break}
    {helpb _cwfcn_kldb10_5d_to_bas3:kldb10_5d_to_bas3()}{break}
    {helpb _cwfcn_kldb10_4d_to_bas3:kldb10_4d_to_bas3()}{break}
    {helpb _cwfcn_kldb10_3plus5_to_bas3:kldb10_3plus5_to_bas3()}{p_end}


{synopt : {ul: Aggregation}}{p_end}

{synopt :{helpb _cwfcn_kldb10_5d_to_kldb10_3plus5:kldb10_5d_to_kldb10_3plus5()}}5-digit to 3plus5-digit KldB-2010{p_end}

{synopt :{helpb _cwfcn_kldb10_3plus5_to_kldb10_2plus5:kldb10_3plus5_to_kldb10_2plus5()}}3plus5-digit to 2plus5-digit KldB-2010; also see{break}
    {helpb _cwfcn_kldb10_5d_to_kldb10_2plus5:kldb10_5d_to_kldb10_2plus5()}{p_end}

{synopt :{helpb _cwfcn_kldb10_5d_to_kldb10_4d:kldb10_5d_to_kldb10_4d()}}5-digit to 4-digit KldB-2010{p_end}

{synopt :{helpb _cwfcn_kldb10_4d_to_kldb10_3d:kldb10_4d_to_kldb10_3d()}}4-digit to 3-digit KldB-2010; also see{break}
    {helpb _cwfcn_kldb10_5d_to_kldb10_3d:kldb10_5d_to_kldb10_3d()}{break}
    {helpb _cwfcn_kldb10_3plus5_to_kldb10_3d:kldb10_3plus5_to_kldb10_3d()}{p_end}

{synopt :{helpb _cwfcn_kldb10_3d_to_kldb10_2d:kldb10_3d_to_kldb10_2d()}}3-digit to 2-digit KldB-2010; also see{break}
    {helpb _cwfcn_kldb10_5d_to_kldb10_2d:kldb10_5d_to_kldb10_2d()}{break}
    {helpb _cwfcn_kldb10_4d_to_kldb10_2d:kldb10_4d_to_kldb10_2d()}{break}
    {helpb _cwfcn_kldb10_2plus5_to_kldb10_2d:kldb10_2plus5_to_kldb10_2d()}{break}
    {helpb _cwfcn_kldb10_3plus5_to_kldb10_2d:kldb10_3plus5_to_kldb10_2d()}{p_end}

{synopt :{helpb _cwfcn_kldb88_4d_to_kldb88_3d:kldb88_4d_to_kldb88_3d()}}4-digit to 3-digit KldB-1988{p_end}

{synopt :{helpb _cwfcn_kldb88_3d_to_kldb88_2d:kldb88_3d_to_kldb88_2d()}}3-digit to 2-digit KldB-1988; also see{break}
    {helpb _cwfcn_kldb88_4d_to_kldb88_2d:kldb88_4d_to_kldb88_2d()}{p_end}

{synopt :{helpb _cwfcn_kldb92_4d_to_kldb92_3d:kldb92_4d_to_kldb92_3d()}}4-digit to 3-digit KldB-1992{p_end}

{synopt :{helpb _cwfcn_kldb92_3d_to_kldb92_2d:kldb92_3d_to_kldb92_2d()}}3-digit to 2-digit KldB-1992; also see{break}
    {helpb _cwfcn_kldb92_4d_to_kldb92_2d:kldb92_4d_to_kldb92_2d()}{p_end}

{synoptline}

{synoptset 16}{...}
{marker kldblbl}{synopthdr:kldblbl}
{synoptline}

{synopt :{helpb _cwfcn_labels_kldb10_5d:kldb10_5d}}KldB-2010 occupational types (5 digits){p_end}

{synopt :{helpb _cwfcn_labels_kldb10_4d:kldb10_4d}}KldB-2010 occupationals sub-groups (4 digits){p_end}

{synopt :{helpb _cwfcn_labels_kldb10_3d:kldb10_3d}}KldB-2010 occupational groups (3 digits){p_end}

{synopt :{helpb _cwfcn_labels_kldb10_2d:kldb10_2d}}KldB-2010 occupational main groups (2 digits){p_end}

{synopt :{helpb _cwfcn_labels_kldb10_1d:kldb10_1d}}KldB-2010 occupational areas (1 digit){p_end}

{synopt :{helpb _cwfcn_labels_kldb10_3plus5:kldb10_3plus5}}KldB-2010 occupational groups (3 digits) combined with the skill level (5th-digit){p_end}

{synopt :{helpb _cwfcn_labels_kldb10_2plus5:kldb10_2plus5}}KldB-2010 occupational main groups (2 digits) combined with the skill level (5th-digit){p_end}

{synopt :{helpb _cwfcn_labels_kldb88_4d:kldb88_4d}}KldB-1988 types of occupations (4 digits){p_end}

{synopt :{helpb _cwfcn_labels_kldb88_3d:kldb88_3d}}KldB-1988 occupational orders (3 digits){p_end}

{synopt :{helpb _cwfcn_labels_kldb88_2d:kldb88_2d}}KldB-1988 occupational groups (2 digits){p_end}

{synopt :{helpb _cwfcn_labels_kldb88harm:kldb88harm}}harmonized KldB-1988 occupational orders by {help kldbrecode##opte:Maier (2020)} {break} 
        (3 digit codes harmonizing KldB-1988, KldB-1992 and KldB-1975){p_end}

{synopt :{helpb _cwfcn_labels_kldb92_4d:kldb92_4d}}KldB-1992 types of occupations (4 digits){p_end}

{synopt :{helpb _cwfcn_labels_kldb92_3d:kldb92_3d}}KldB-1992 occupational orders (3 digits){p_end}

{synopt :{helpb _cwfcn_labels_kldb92_2d:kldb92_2d}}KldB-1992 occupational groups (2 digits){p_end}

{synopt :{helpb _cwfcn_labels_bibb:bibb}}BIBB occupational fields by {help kldbrecode##opte:Tiemann et al. (2008)}{p_end}

{synoptline}

{marker examples}{...}
{title:Examples}

 {dlgtab:Translate KldB-2010 to ISCO-08}

        {com}crosswalk isco08 = kldb10_5d_to_isco08(occ_kldb10), duplicates(first){txt}

{pstd}   
    {helpb _cwfcn_kldb10_5d_to_isco08:kldb10_5d_to_isco08()} is a non-unique crosswalk table, meaning that a single 5-digit KldB-2010 code 
    may be matched to multiple ISCO-08 codes and requires option {helpb crosswalk##dupl:duplicates()}.
    In the example, the crosswalk function uses the first (topmost) match.
    {p_end}

{dlgtab:Generate prestige scores (BAS-3) from KldB-2010}

        {com}crosswalk bas3_v2 = kldb10_5d_to_bas3(occ_kldb10 {it:2}){txt}

{pstd}   
    Ebner and Rohrbach-Schmidt provide two versions of BAS-3 (see {helpb _cwfcn_kldb10_3d_to_bas3:kldb10_3d_to_bas3()}).
    In the example, the  {helpb crosswalk##case:{it:case argument}} with the value {cmd: {it:2}} specifies that V2 is to be generated.
    {p_end}

{dlgtab:Generate ISEI scores from KldB-2010}

{pstd}   
    With {cmd: crosswalk define}, we can define custom crosswalk functions as a wrapper for crosswalk tables. 
    In the example, we combine {helpb _cwfcn_kldb10_5d_to_isco08:kldb10_5d_to_isco08()} from {cmd: kldbrecode} 
    and {helpb _cwfcn_isco08_to_isei:isco08_to_isei()} from {cmd: crosswalk}. 
    {p_end}

        // define kldb10_5d_to_isei08 crosswalk function
        {com}crosswalk define kldb10_5d_to_isei08()
            .kldb10_5d_to_isco08
            .isco08_to_isei
            end{txt}
           
        // Apply kldb10_5d_to_isei08 to kldb10_5d codes
        {com}crosswalk isei = kldb10_5d_to_isei08(occ_kldb10), duplicates(first)
        crosswalk isei_alt = kldb10_5d_to_isei08(occ_kldb10), duplicates(mean){txt}
    

{pstd}   
      {cmd: kldb10_5d_to_isco08()} is a non-unique crosswalk table,
      we need to specify how duplicates should be handled.
      For example, the ISEI score of the first mapped ISCO code could be used 
      or alternatively the mean value of all possible mappings.
    {p_end}

{marker references}{...}
{title:Measures and occupational statistics based on KldB}

{pstd}
    The different variants and aggregations of the German KldB allow for matching 
    a large number of occupational statistics and different measures 
    that we were unable to provide in this package. 
    An overview of occupation-based measures with a focus on the German context 
    is given by {help kldbrecode##occmeasures:Christoph, Matthes and Ebner (2020)}.
    Easily accessible statistics on socio-structural information, 
    complemented by a number of other measures such as task profiles, 
    substitutability or the greening of job tasks, 
    are provided by the IAB occupational panels 
    ({help kldbrecode##occupan:Grienberger, Janser, and Lehmer, 2022}
    and {help kldbrecode##occpan:Hausmann, Zucco, and Kleinert, 2015}).
    {p_end}

{title:References}

{marker occmeasures}{...}
{phang}
    Christoph, B., Matthes, B. and Ebner, C. 2020.
    Occupation-Based Measures. An Overview and Discussion. 
    Kölner Zeitschrift für Soziologie, 72(Suppl 1), 41–78. 
    DOI: {browse "https://doi.org/10.1007/s11577-020-00673-4"":10.1007/s11577-020-00673-4}.
    {p_end}

{marker bas}{...}
{phang}
    Ebner, C. and Rohrbach-Schmidt, D. 2021. 
    Das gesellschaftliche Ansehen von Berufen. Konstruktion einer neuen 
    beruflichen Ansehensskala und empirische Befunde für Deutschland
    [The Social Prestige of Occupations. Construction of a New 
    Occupational Prestige Scale and Empirical Results for Germany]. 
    Zeitschrift für Soziologie, 50(6), 349-372.
    DOI: {browse "https://doi.org/10.1515/zfsoz-2021-0026":10.1515/zfsoz-2021-0026}.
    {p_end}

{marker occupan}{...}
{phang}
    Grienberger, K., Janser, M. and Lehmer, F. 2022. 
    The Occupational Panel for Germany. 
    Journal of Economics and Statistics.
    DOI: {browse "https://doi.org/10.1515/jbnst-2022-0053":10.1515/jbnst-2022-0053}.

{pmore}
    Public Use File provided by the 
    Research Data Center (FDZ) at the Institute for Employment Research (IAB), Nürnberg.
    Available from {browse "https://iab.de/en/daten/iab-occupational-panel/"}.
    {p_end}

{marker occpan}{...}
{phang}
    Hausmann, A.-C., Zucco, A. and Kleinert, C. 2015. 
    Berufspanel für Westdeutschland 1976-2010 (OccPan).
    [Occupational Panel for West Germany 1976-2010].
    FDZ-Methodenreport 09/2015.
    Research Data Center (FDZ) at the Institute for Employment Research (IAB), Nürnberg.
    Available from {browse "https://doku.iab.de/fdz/reporte/2015/MR_09-15.pdf"}.
    {p_end}

{pmore}
    Public Use File provided by the 
    Research Data Center (FDZ) at the Institute for Employment Research (IAB), Nürnberg.
    Available from {browse "http://doku.iab.de/fdz/reporte/2015/MR_09-15_Daten.zip"}.
    {p_end}

{marker crosswalk}{...}
{phang}
    Jann, B. 2025. crosswalk: Stata module to recode variable based on
    crosswalk table (bulk recoding). Available from
    {browse "https://ideas.repec.org/c/boc/bocode/s459420.html"}.
    {p_end}

{marker opte}{...}
{phang}
    Maier, T. 2020. Occupational Panel on Tasks and Education (OPTE) for Western Germany from 1973 to 2011. 
    GESIS, Cologne. Data File Version 1.0.0. DOI: {browse "https://doi.org/10.7802/2126":10.7802/2126}.
    {p_end}

{phang}
    Maier, T. 2022. Change in occupational tasks and its implications.
    Evidence from a task panel from 1973 to 2011 for Western Germany. 
    Quality & Quantity. DOI: {browse "https://doi.org/10.1007/s11135-021-01158-y":10.1007/s11135-021-01158-y}.
    {p_end}

{marker bibbfields}{...}
{phang}
    Tiemann, M., Schade, H. J., Helmrich, R., Hall, A., Braun, U., Bott, P. (2008).  Berufsfeld-Definitionen
    des BIBB.  Bonn: Federal Institute for Vocational Education and Training (BIBB).
    {p_end}

{phang}
    Tiemann, M. (2018).  Die Berufsfelder des BIBB.  Überarbeitung und Anpassung an die KldB 2010
    (Schriftenreihe des Bundesinstituts für Berufsbildung, Heft 190).  Bonn: Federal Institute for Vocational
    Education and Training (BIBB).
    {p_end}

{marker author}{...}
{title:Authors}

{pstd}
    Hans Gerhardt and Anneke Kappes, WZB Berlin Social Science Center

{pmore}   
    Contact: hans.gerhardt@wzb.eu

{pstd}
    The material is subject to the Creative Commons License {browse "https://creativecommons.org/licenses/by-sa/4.0/":CC BY-NC-SA 4.0}.

{pstd}
    Thanks for citing this software as follows:

{pmore}   
    Gerhardt, H. and Kappes, A. (2025). kldbrecode: Stata module to translate KldB codes. Available from 
    {browse "https://github.com/hagerhardt/kldbrecode"}.
    
