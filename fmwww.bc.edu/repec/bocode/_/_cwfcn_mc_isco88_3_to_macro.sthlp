{smcl}
{* version 1.0.0  18aug2026}{...}
{hi:mc_isco88_3_to_macro()} {hline 2} Translate 3-digit ISCO-88(com) to Macro-SEC

{title:Syntax}

        {cmd:mc.isco88_3_to_macro(}{it:varname} {it:case}{cmd:)}

{pstd}
    where {it:varname} contains 3-digit ISCO-88(com) minor group codes
    and {it:case} selects the employment status column.

{pstd}
    Typical usage:

        {cmd:mc.isco88_3_to_macro(}{it:varname} {cmd:case.mcempstat(}{it:sempl} {it:supvis}{cmd:)}{cmd:)}

{title:Description}

{pstd}
    {helpb crosswalk} table translating 3-digit ISCO-88(com) minor
    groups to the Macro-SEC - ESEC plus differentiation of SC I and II (11 classes). The table also
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
    Multilevel Socio-Economic Classes crosswalk files for Macro-SEC,
    introduced in Smallenbroek, Hertel and Barone (2022); see
    References.
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
000   .   .   .   .   .   .
010   .   1   1   1   1   1
011   .   5   3   5   5   5
100   .   .   1   .   6   1
110   .   1   1   1   1   1
111   .   1   1   1   1   1
112   .   1   1   1   1   1
113   .   1   1   1   1   1
114   .   1   1   1   1   1
120   .   1   1   6   6   1
121   .   1   1   6   6   1
122   .   3   3   6   6   1
123   .   1   1   6   6   1
130   .   3   3   6   6   1
131   .   3   3   6   6   1
200   .   .   1   .   1   1
210   .   2   1   2   1   1
211   .   2   1   2   1   1
212   .   2   1   2   1   1
213   .   2   1   2   1   1
214   .   2   1   2   1   1
220   .   2   1   2   1   1
221   .   2   1   2   1   1
222   .   2   1   2   1   1
223   .   4   3   4   3   1
230   .   4   3   4   3   1
231   .   2   1   2   1   1
232   .   4   3   4   3   1
233   .   4   3   4   3   1
234   .   4   3   4   3   1
235   .   2   1   2   1   1
240   .   2   1   2   1   1
241   .   2   1   2   1   1
242   .   2   1   2   1   1
243   .   4   3   4   3   1
244   .   4   3   4   3   1
245   .   4   3   4   3   1
246   .   4   3   4   3   1
247   .   4   3   4   3   1
300   .   .   .   .   6   1
310   .   4   3   4   3   1
311   .   4   3   4   3   1
312   .   4   3   4   3   1
313   .   8   3   6   6   1
314   .   4   3   4   3   1
315   .   .   8   6   6   1
320   .   4   3   4   3   1
321   .   4   3   4   3   1
322   .   4   3   4   3   1
323   .   4   3   4   3   1
324   .   4   3   4   3   1
330   .   5   3   6   6   1
331   .   5   3   6   6   1
332   .   5   3   6   6   1
333   .   5   3   6   6   1
334   .   4   3   4   3   1
340   .   5   3   6   6   1
341   .   5   3   6   6   1
342   .   4   3   4   3   1
343   .   5   3   6   6   1
344   .   4   3   4   3   3
345   .   4   3   4   3   3
346   .   5   3   6   6   1
347   .   5   3   6   6   1
348   .   4   3   4   3   1
400   .   5   3   6   6   1
410   .   5   3   6   6   1
411   .   5   3   6   6   1
412   .   5   3   6   6   1
413   .   9   8   6   6   1
414   .  11   8   6   6   1
419   .   5   3   6   6   1
420   .   5   3   6   6   1
421   .   9   8   6   6   1
422   .   9   8   6   6   1
500   .   .   8   6   6   1
510   .   9   8   6   6   1
511   .   9   8   6   6   1
512   .  11   8   6   6   1
513   .   9   8   6   6   1
514   .   9   8   6   6   1
515   .   9   8   6   6   1
516   .   9   8   5   5   5
520   .   9   8   6   6   1
521   .   4   3   6   6   1
522   .   9   8   6   6   1
523   .   9   8   6   6   1
600   .  10   8   7   7   1
610   .  10   8   7   7   1
611   .  10   8   7   7   1
612   .  10   8   7   7   1
613   .  10   8   7   7   1
614   .  10   8   7   7   1
615   .  10   8   7   7   1
620   .  10   8   7   7   1
621   .   7   7   7   7   7
700   .  10   8   6   6   1
710   .  10   8   6   6   1
711   .  10   8   6   6   1
712   .  10   8   6   6   1
713   .  10   8   6   6   1
714   .  10   8   6   6   1
720   .  10   8   6   6   1
721   .  10   8   6   6   1
722   .  10   8   6   6   1
723   .  10   8   6   6   1
724   .  10   8   6   6   1
730   .   8   8   6   6   1
731   .   8   8   6   6   1
732   .  10   8   6   6   1
733   .  10   8   6   6   1
734   .  10   8   6   6   1
740   .  10   8   6   6   1
741   .  10   8   6   6   1
742   .  10   8   6   6   1
743   .  10   8   6   6   1
744   .  10   8   6   6   1
800   .   .   8   6   6   1
810   .  11   8   6   6   1
811   .  11   8   6   6   1
812   .  11   8   6   6   1
813   .  11   8   6   6   1
814   .  11   8   6   6   1
815   .  11   8   6   6   1
816   .  11   8   6   6   1
817   .  11   8   6   6   1
820   .  11   8   6   6   1
821   .  11   8   6   6   1
822   .  11   8   6   6   1
823   .  11   8   6   6   1
824   .  11   8   6   6   1
825   .  10   8   6   6   1
826   .  11   8   6   6   1
827   .  11   8   6   6   1
828   .  11   8   6   6   1
829   .  11   8   6   6   1
830   .  11   8   6   6   1
831   .  10   8   6   6   1
832   .  11   8   6   6   1
833   .  11   8   6   6   1
834   .  10   8   6   6   1
900   .   .   .   6   6   1
910   .  11   8   6   6   1
911   .   9   8   6   6   1
912   .  11   8   6   6   1
913   .  11   8   6   6   1
914   .  11   8   6   6   1
915   .  11   8   6   6   1
916   .  11   8   6   6   1
920   .  11   8   7   7   1
921   .  11   8   7   7   1
930   .  11   8   6   6   1
931   .  11   8   6   6   1
932   .  11   8   6   6   1
933   .  11   8   6   6   1
