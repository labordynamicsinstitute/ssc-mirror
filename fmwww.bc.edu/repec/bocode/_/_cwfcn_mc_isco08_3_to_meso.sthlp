{smcl}
{* version 1.0.0  18aug2026}{...}
{hi:mc_isco08_3_to_meso()} {hline 2} Translate 3-digit ISCO-08 to Meso-SEC

{title:Syntax}

        {cmd:mc.isco08_3_to_meso(}{it:varname} {it:case}{cmd:)}

{pstd}
    where {it:varname} contains 3-digit ISCO-08 minor group codes
    and {it:case} selects the employment status column.

{pstd}
    Typical usage:

        {cmd:mc.isco08_3_to_meso(}{it:varname} {cmd:case.mcempstat(}{it:sempl} {it:supvis}{cmd:)}{cmd:)}

{title:Description}

{pstd}
    {helpb crosswalk} table translating 3-digit ISCO-08 minor
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
011   .  21  21  21  21  21
020   .  23  23  23  23  23
021   .  23  22  23  23  23
030   .  23  23  23  23  23
031   .  23  22  23  23  23
100   .   .   .   .  14   .
110   .  21  21  21  21  21
111   .  21  21  21  21  21
112   .  21  21  21  21  21
120   .  21  21  14  14  21
121   .  21  21  14  14  21
122   .  21  21  14  14  21
130   .  21  21  14  14  21
131   .  22  22  15  15  21
132   .  22  22  14  14  21
133   .  21  21  14  14  21
134   .  21  21  14  14  21
140   .  22  22  14  14  21
141   .  22  22  14  14  21
142   .  22  22  14  14  21
143   .  22  22  14  14  21
200   .   .   .   .  21  21
210   .  41  21  41  21  21
211   .  41  21  41  21  21
212   .  41  21  41  21  21
213   .  41  21  41  21  21
214   .  41  21  41  21  21
215   .  41  21  41  21  21
216   .  41  21  41  21  21
220   .  31  21  31  21  21
221   .  31  21  31  21  21
222   .  32  22  32  22  21
223   .  32  22  32  22  21
224   .  36  36  14  14  21
225   .  31  21  31  21  21
226   .  31  21  31  21  21
230   .  31  21  31  21  21
231   .  31  21  31  21  21
232   .  31  21  31  21  21
233   .  32  22  32  22  21
234   .  32  22  32  22  21
235   .  31  21  31  21  21
240   .  21  21  21  21  21
241   .  21  21  21  21  21
242   .  22  22  22  22  21
243   .  21  21  21  21  21
250   .  41  21  41  21  21
251   .  41  21  41  21  21
252   .  42  22  42  22  21
260   .  32  22  32  22  21
261   .  21  21  21  21  21
262   .  32  22  32  22  21
263   .  31  21  31  21  21
264   .  32  22  32  22  21
265   .  32  22  32  22  21
300   .   .   .   .  14  21
310   .  42  22  42  22  21
311   .  42  22  42  22  21
312   .  42  22  42  22  21
313   .  46  22  14  14  21
314   .  42  22  42  22  21
315   .  42  22  42  22  21
320   .  36  36  14  14  21
321   .  32  22  32  22  21
322   .  32  22  32  22  21
323   .  32  22  32  22  21
324   .  33  36  14  14  21
325   .  33  22  14  14  21
330   .  21  21  21  21  21
331   .  21  21  21  21  21
332   .  21  21  21  21  21
333   .  22  22  22  22  21
334   .  23  22  14  14  21
335   .  22  22  22  22  22
340   .  33  22  14  14  21
341   .  33  22  32  22  21
342   .  33  22  14  14  21
343   .  33  22  14  14  21
350   .  23  22  14  14  21
351   .  23  22  14  14  21
352   .  23  22  14  14  21
400   .  23  22  14  14  21
410   .  23  22  14  14  21
411   .  23  22  14  14  21
412   .  23  22  14  14  21
413   .  23  22  14  14  21
420   .  27  26  14  14  21
421   .  27  26  14  14  21
422   .  37  26  14  14  21
430   .  23  22  14  14  21
431   .  23  22  14  14  21
432   .  27  22  14  14  21
440   .  23  26  14  14  21
441   .  23  26  14  14  21
500   .  37  36  14  14  21
510   .  37  36  14  14  21
511   .  37  36  14  14  21
512   .  37  36  14  14  21
513   .  37  36  14  14  21
514   .  37  36  14  14  21
515   .  37  36  14  14  21
516   .  37  36  14  14  21
520   .  27  36  14  14  21
521   .  39  27  14  14  21
522   .  27  36  14  14  21
523   .  27  26  14  14  21
524   .  27  36  14  14  21
530   .  37  36  14  14  21
531   .  37  36  14  14  21
532   .  37  36  14  14  21
540   .  37  36  23  23  23
541   .  37  36  23  23  23
600   .  48  46  15  15  21
610   .  48  46  15  15  21
611   .  48  46  15  15  21
612   .  48  46  15  15  21
613   .  48  46  15  15  21
620   .  48  46  15  15  21
621   .  48  46  15  15  21
622   .  48  46  15  15  21
630   .  15  15  15  15  15
631   .  15  15  15  15  15
632   .  15  15  15  15  15
633   .  15  15  15  15  15
634   .  15  15  15  15  15
700   .  48  46  14  14  21
710   .  48  46  14  14  21
711   .  48  46  14  14  21
712   .  48  46  14  14  21
713   .  48  46  14  14  21
720   .  48  46  14  14  21
721   .  48  46  14  14  21
722   .  48  46  14  14  21
723   .  48  46  14  14  21
730   .  48  46  14  14  21
731   .  48  46  14  14  21
732   .  48  46  14  14  21
740   .  48  46  14  14  21
741   .  48  46  14  14  21
742   .  46  46  14  14  21
750   .  48  46  14  14  21
751   .  48  46  14  14  21
752   .  48  46  14  14  21
753   .  48  46  14  14  21
754   .  48  46  14  14  21
800   .   .  46  14  14  21
810   .  49  46  14  14  21
811   .  49  46  14  14  21
812   .  49  46  14  14  21
813   .  49  46  14  14  21
814   .  49  46  14  14  21
815   .  49  46  14  14  21
816   .  49  46  14  14  21
817   .  49  46  14  14  21
818   .  49  46  14  14  21
820   .  49  46  14  14  21
821   .  49  46  14  14  21
830   .  48  46  14  14  21
831   .  48  46  14  14  21
832   .  39  46  14  14  21
833   .  48  46  14  14  21
834   .  49  46  14  14  21
835   .  48  46  14  14  21
900   .   .   .  14  14  21
910   .  39  36  14  14  21
911   .  39  36  14  14  21
912   .  39  36  14  14  21
920   .  49  46  15  15  21
921   .  49  46  15  15  21
930   .  49  46  15  15  21
931   .  49  46  14  14  21
932   .  49  46  14  14  21
933   .  39  46  14  14  21
940   .  39  36  14  14  21
941   .  39  36  14  14  21
950   .  39  36  14  14  21
951   .  39  36  14  14  21
952   .  39  36  14  14  21
960   .  39  46  14  14  21
961   .  39  46  14  14  21
962   .  39  46  14  14  21
