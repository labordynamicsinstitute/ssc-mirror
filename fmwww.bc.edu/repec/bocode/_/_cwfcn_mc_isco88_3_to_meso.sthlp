{smcl}
{* version 1.0.0  18aug2026}{...}
{hi:mc_isco88_3_to_meso()} {hline 2} Translate 3-digit ISCO-88(com) to Meso-SEC

{title:Syntax}

        {cmd:mc.isco88_3_to_meso(}{it:varname} {it:case}{cmd:)}

{pstd}
    where {it:varname} contains 3-digit ISCO-88(com) minor group codes
    and {it:case} selects the employment status column.

{pstd}
    Typical usage:

        {cmd:mc.isco88_3_to_meso(}{it:varname} {cmd:case.mcempstat(}{it:sempl} {it:supvis}{cmd:)}{cmd:)}

{title:Description}

{pstd}
    {helpb crosswalk} table translating 3-digit ISCO-88(com) minor
    groups to the Multilevel Socio-Economic Classes: Meso-SEC (18 classes). The table also
    carries rows for sub-major (2-digit) and major (1-digit)
    groups, written as 3-digit codes padded with zeros on the
    right, so that partially coded observations still match.

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

{pstd}
    Cells that the source tables leave unclassified are coded
    {cmd:.} and produce a missing value.

{title:Source}

{pstd}
    Multilevel Socio-Economic Classes crosswalk files for Meso-SEC,
    the 18-class scheme assessed in Hertel, Barone and Smallenbroek
    (2025); see References.
    {p_end}

{pstd}
    Note that this table is based on
    {browse "https://warwick.ac.uk/fac/soc/ier/research/classification/isco88":ISCO-88(COM)},
    the European Union variant of the ISCO-88. If your data contains ISCO-88
    codes you might first want to translate these codes to ISCO-88(COM) using
    {helpb _cwfcn_isco88_to_isco88com:isco88_to_isco88com()}.

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
000   .   .   .   .   .   .
010   .  21  21  21  21  21
011   .  23  22  23  23  23
100   .   .  21   .  14  21
110   .  21  21  21  21  21
111   .  21  21  21  21  21
112   .  21  21  21  21  21
113   .  21  21  21  21  21
114   .  21  21  21  21  21
120   .  21  21  14  14  21
121   .  21  21  14  14  21
122   .  22  22  14  14  21
123   .  21  21  14  14  21
130   .  22  22  14  14  21
131   .  22  22  14  14  21
200   .   .  21   .  21  21
210   .  41  21  41  21  21
211   .  41  21  41  21  21
212   .  41  21  41  21  21
213   .  41  21  41  21  21
214   .  41  21  41  21  21
220   .  31  21  31  21  21
221   .  41  21  41  21  21
222   .  31  21  31  21  21
223   .  32  22  32  22  21
230   .  32  22  32  22  21
231   .  31  21  31  21  21
232   .  32  22  32  22  21
233   .  32  22  32  22  21
234   .  32  22  32  22  21
235   .  31  21  31  21  21
240   .  21  21  21  21  21
241   .  21  21  21  21  21
242   .  21  21  21  21  21
243   .  32  22  32  22  21
244   .  32  22  32  22  21
245   .  32  22  32  22  21
246   .  32  22  32  22  21
247   .  22  22  22  22  21
300   .   .   .   .  14  21
310   .  42  22  42  22  21
311   .  42  22  42  22  21
312   .  42  22  42  22  21
313   .  46  22  14  14  21
314   .  42  22  42  22  21
315   .  26  26  14  14  21
320   .  32  22  32  22  21
321   .  42  22  42  22  21
322   .  32  22  32  22  21
323   .  32  22  32  22  21
324   .  32  22  32  22  21
330   .  33  22  14  14  21
331   .  33  22  14  14  21
332   .  33  22  14  14  21
333   .  33  22  14  14  21
334   .  32  22  32  22  21
340   .  23  22  14  14  21
341   .  23  22  14  14  21
342   .  22  22  22  22  21
343   .  23  22  14  14  21
344   .  22  22  22  22  22
345   .  22  22  22  22  22
346   .  33  22  14  14  21
347   .  33  22  14  14  21
348   .  32  22  32  22  21
400   .  23  22  14  14  21
410   .  23  22  14  14  21
411   .  23  22  14  14  21
412   .  23  22  14  14  21
413   .  27  46  14  14  21
414   .  39  26  14  14  21
419   .  23  22  14  14  21
420   .  23  22  14  14  21
421   .  27  26  14  14  21
422   .  37  26  14  14  21
500   .   .  36  14  14  21
510   .  37  36  14  14  21
511   .  37  36  14  14  21
512   .  39  36  14  14  21
513   .  37  36  14  14  21
514   .  27  36  14  14  21
515   .  37  36  14  14  21
516   .  37  36  23  23  23
520   .  27  26  14  14  21
521   .  32  22  14  14  21
522   .  27  26  14  14  21
523   .  27  26  14  14  21
600   .  48  46  15  15  21
610   .  48  46  15  15  21
611   .  48  46  15  15  21
612   .  48  46  15  15  21
613   .  48  46  15  15  21
614   .  48  46  15  15  21
615   .  48  46  15  15  21
620   .  48  46  15  15  21
621   .  15  15  15  15  15
700   .  48  46  14  14  21
710   .  48  46  14  14  21
711   .  48  46  14  14  21
712   .  48  46  14  14  21
713   .  48  46  14  14  21
714   .  48  46  14  14  21
720   .  48  46  14  14  21
721   .  48  46  14  14  21
722   .  48  46  14  14  21
723   .  48  46  14  14  21
724   .  48  46  14  14  21
730   .  46  46  14  14  21
731   .  46  46  14  14  21
732   .  48  46  14  14  21
733   .  48  46  14  14  21
734   .  48  46  14  14  21
740   .  48  46  14  14  21
741   .  48  46  14  14  21
742   .  48  46  14  14  21
743   .  48  46  14  14  21
744   .  48  46  14  14  21
800   .   .  46  14  14  21
810   .  49  46  14  14  21
811   .  49  46  14  14  21
812   .  49  46  14  14  21
813   .  49  46  14  14  21
814   .  49  46  14  14  21
815   .  49  46  14  14  21
816   .  49  46  14  14  21
817   .  49  46  14  14  21
820   .  49  46  14  14  21
821   .  49  46  14  14  21
822   .  49  46  14  14  21
823   .  49  46  14  14  21
824   .  49  46  14  14  21
825   .  48  46  14  14  21
826   .  49  46  14  14  21
827   .  49  46  14  14  21
828   .  49  46  14  14  21
829   .  49  46  14  14  21
830   .  49  46  14  14  21
831   .  48  46  14  14  21
832   .  49  46  14  14  21
833   .  49  46  14  14  21
834   .  48  46  14  14  21
900   .   .   .  14  14  21
910   .  39  36  14  14  21
911   .  27  36  14  14  21
912   .  39  36  14  14  21
913   .  39  36  14  14  21
914   .  39  36  14  14  21
915   .  39  36  14  14  21
916   .  39  46  14  14  21
920   .  49  46  15  15  21
921   .  49  46  15  15  21
930   .  49  46  14  14  21
931   .  49  46  14  14  21
932   .  49  46  14  14  21
933   .  39  46  14  14  21
