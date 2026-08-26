{smcl}
{* version 1.0.0  18aug2026}{...}
{hi:mc_isco08_3_to_macro()} {hline 2} Translate 3-digit ISCO-08 to Macro-SEC

{title:Syntax}

        {cmd:mc.isco08_3_to_macro(}{it:varname} {it:case}{cmd:)}

{pstd}
    where {it:varname} contains 3-digit ISCO-08 minor group codes
    and {it:case} selects the employment status column.

{pstd}
    Typical usage:

        {cmd:mc.isco08_3_to_macro(}{it:varname} {cmd:case.mcempstat(}{it:sempl} {it:supvis}{cmd:)}{cmd:)}

{title:Description}

{pstd}
    {helpb crosswalk} table translating 3-digit ISCO-08 minor
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
011   .   1   1   1   1   1
020   .   5   .   5   5   5
021   .   5   3   5   5   5
030   .   5   .   5   5   5
031   .   5   3   5   5   5
100   .   1   1   6   6   1
110   .   1   1   1   1   1
111   .   1   1   1   1   1
112   .   1   1   1   1   1
120   .   1   1   6   6   1
121   .   1   1   6   6   1
122   .   1   1   6   6   1
130   .   1   1   6   6   1
131   .   3   3   7   7   1
132   .   3   3   6   6   1
133   .   1   1   6   6   1
134   .   1   1   6   6   1
140   .   3   3   6   6   1
141   .   3   3   6   6   1
142   .   3   3   6   6   1
143   .   3   3   6   6   1
200   .   2   1   2   1   1
210   .   2   1   2   1   1
211   .   2   1   2   1   1
212   .   2   1   2   1   1
213   .   2   1   2   1   1
214   .   2   1   2   1   1
215   .   2   1   2   1   1
216   .   2   1   2   1   1
220   .   2   1   2   1   1
221   .   2   1   2   1   1
222   .   4   3   4   3   1
223   .   4   3   4   3   1
224   .   8   8   6   6   1
225   .   2   1   2   1   1
226   .   2   1   2   1   1
230   .   2   1   2   1   1
231   .   2   1   2   1   1
232   .   2   1   2   1   1
233   .   4   3   4   3   1
234   .   4   3   4   3   1
235   .   2   1   2   1   1
240   .   2   1   2   1   1
241   .   2   1   2   1   1
242   .   4   3   4   3   1
243   .   2   1   2   1   1
250   .   2   1   2   1   1
251   .   2   1   2   1   1
252   .   4   3   4   3   1
260   .   4   3   4   3   1
261   .   2   1   2   1   1
262   .   4   3   4   3   1
263   .   2   1   2   1   1
264   .   4   3   4   3   1
265   .   4   3   4   3   1
300   .   5   3   6   6   1
310   .   4   3   4   3   1
311   .   4   3   4   3   1
312   .   4   3   4   3   1
313   .   8   3   6   6   1
314   .   4   3   4   3   1
315   .   4   3   4   3   1
320   .   8   8   6   6   1
321   .   4   3   4   3   1
322   .   4   3   4   3   1
323   .   4   3   4   3   1
324   .   5   8   6   6   1
325   .   5   3   6   6   1
330   .   2   1   2   1   1
331   .   2   1   2   1   1
332   .   2   1   2   1   1
333   .   4   3   4   3   1
334   .   5   3   6   6   1
335   .   4   3   4   3   3
340   .   5   3   6   6   1
341   .   5   3   4   3   1
342   .   5   3   6   6   1
343   .   5   3   6   6   1
350   .   5   3   6   6   1
351   .   5   3   6   6   1
352   .   5   3   6   6   1
400   .   5   3   6   6   1
410   .   5   3   6   6   1
411   .   5   3   6   6   1
412   .   5   3   6   6   1
413   .   5   3   6   6   1
420   .   9   8   6   6   1
421   .   9   8   6   6   1
422   .   9   8   6   6   1
430   .   5   3   6   6   1
431   .   5   3   6   6   1
432   .   9   3   6   6   1
440   .   5   8   6   6   1
441   .   5   8   6   6   1
500   .   9   8   6   6   1
510   .   9   8   6   6   1
511   .   9   8   6   6   1
512   .   9   8   6   6   1
513   .   9   8   6   6   1
514   .   9   8   6   6   1
515   .   9   8   6   6   1
516   .   9   8   6   6   1
520   .   9   8   6   6   1
521   .  11   9   6   6   1
522   .   9   8   6   6   1
523   .   9   8   6   6   1
524   .   9   8   6   6   1
530   .   9   8   6   6   1
531   .   9   8   6   6   1
532   .   9   8   6   6   1
540   .   9   8   5   5   5
541   .   9   8   5   5   5
600   .  10   8   7   7   1
610   .  10   8   7   7   1
611   .  10   8   7   7   1
612   .  10   8   7   7   1
613   .  10   8   7   7   1
620   .  10   8   7   7   1
621   .  10   8   7   7   1
622   .  10   8   7   7   1
630   .   7   7   7   7   7
631   .   7   7   7   7   7
632   .   7   7   7   7   7
633   .   7   7   7   7   7
634   .   7   7   7   7   7
700   .  10   8   6   6   1
710   .  10   8   6   6   1
711   .  10   8   6   6   1
712   .  10   8   6   6   1
713   .  10   8   6   6   1
720   .  10   8   6   6   1
721   .  10   8   6   6   1
722   .  10   8   6   6   1
723   .  10   8   6   6   1
730   .  10   8   6   6   1
731   .  10   8   6   6   1
732   .  10   8   6   6   1
740   .  10   8   6   6   1
741   .  10   8   6   6   1
742   .   8   8   6   6   1
750   .  10   8   6   6   1
751   .  10   8   6   6   1
752   .  10   8   6   6   1
753   .  10   8   6   6   1
754   .  10   8   6   6   1
800   .  11   8   6   6   1
810   .  11   8   6   6   1
811   .  11   8   6   6   1
812   .  11   8   6   6   1
813   .  11   8   6   6   1
814   .  11   8   6   6   1
815   .  11   8   6   6   1
816   .  11   8   6   6   1
817   .  11   8   6   6   1
818   .  11   8   6   6   1
820   .  11   8   6   6   1
821   .  11   8   6   6   1
830   .  10   8   6   6   1
831   .  10   8   6   6   1
832   .  11   8   6   6   1
833   .  10   8   6   6   1
834   .  11   8   6   6   1
835   .  10   8   6   6   1
900   .  11   8   6   6   1
910   .  11   8   6   6   1
911   .  11   8   6   6   1
912   .  11   8   6   6   1
920   .  11   8   7   7   1
921   .  11   8   7   7   1
930   .  11   8   7   7   1
931   .  11   8   6   6   1
932   .  11   8   6   6   1
933   .  11   8   6   6   1
940   .  11   8   6   6   1
941   .  11   8   6   6   1
950   .  11   8   6   6   1
951   .  11   8   6   6   1
952   .  11   8   6   6   1
960   .  11   8   6   6   1
961   .  11   8   6   6   1
962   .  11   8   6   6   1
