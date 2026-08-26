{smcl}
{* version 1.0.0  18aug2026}{...}
{hi:mc_isco08_3_to_micro()} {hline 2} Translate 3-digit ISCO-08 to Micro-SEC

{title:Syntax}

        {cmd:mc.isco08_3_to_micro(}{it:varname} {it:case}{cmd:)}

{pstd}
    where {it:varname} contains 3-digit ISCO-08 minor group codes
    and {it:case} selects the employment status column.

{pstd}
    Typical usage:

        {cmd:mc.isco08_3_to_micro(}{it:varname} {cmd:case.mcempstat(}{it:sempl} {it:supvis}{cmd:)}{cmd:)}

{title:Description}

{pstd}
    {helpb crosswalk} table translating 3-digit ISCO-08 minor
    groups to the Multilevel Socio-Economic Classes: Micro-SEC (30 classes). The table also
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
    Multilevel Socio-Economic Classes crosswalk files for Micro-SEC,
    the 30-class scheme assessed in Hertel, Barone and Smallenbroek
    (2025); see References.
    {p_end}

{pstd}
    Class labels: {helpb _cwfcn_labels_mc_micro:labels_mc_micro()}
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
010   .  10  10  10  10  10
011   .  10  10  10  10  10
020   .  52  52  52  52  52
021   .  52  30  52  52  52
030   .  52  52  52  52  52
031   .  52  30  52  52  52
100   .   .   .   .  61   .
110   .  10  10  11  11  11
111   .  10  10  11  11  11
112   .  10  10  11  11  11
120   .  10  10  61  61  11
121   .  10  10  61  61  11
122   .  10  10  61  61  11
130   .  10  10  61  61  11
131   .  30  30  70  70  11
132   .  30  30  61  61  11
133   .  10  10  61  61  11
134   .  10  10  61  61  11
140   .  30  30  61  61  11
141   .  30  30  61  61  11
142   .  30  30  61  61  11
143   .  30  30  61  61  11
200   .   .   .   .  11  11
210   .  22  10  22  11  11
211   .  22  10  22  11  11
212   .  22  10  22  11  11
213   .  22  10  22  11  11
214   .  22  10  22  11  11
215   .  22  10  22  11  11
216   .  22  10  22  11  11
220   .  21  10  21  11  11
221   .  21  10  21  11  11
222   .  41  30  41  30  11
223   .  41  30  41  30  11
224   .  81  81  61  61  11
225   .  21  10  21  11  11
226   .  21  10  21  11  11
230   .  23  10  23  11  11
231   .  23  10  23  11  11
232   .  23  10  23  11  11
233   .  44  30  44  30  11
234   .  44  30  44  30  11
235   .  23  10  23  11  11
240   .  20  10  20  11  11
241   .  20  10  20  11  11
242   .  40  30  40  30  11
243   .  20  10  20  11  11
250   .  22  10  22  11  11
251   .  22  10  22  11  11
252   .  43  30  43  30  11
260   .  42  30  42  30  11
261   .  20  10  20  11  11
262   .  42  30  42  30  11
263   .  23  10  23  11  11
264   .  42  30  42  30  11
265   .  42  30  42  30  11
300   .   .   .   .  61  11
310   .  43  30  43  30  11
311   .  43  30  43  30  11
312   .  43  30  43  30  11
313   .  80  30  61  61  11
314   .  43  30  43  30  11
315   .  43  30  43  30  11
320   .  81  81  61  61  11
321   .  41  30  41  30  11
322   .  41  30  41  30  11
323   .  41  30  41  30  11
324   .  51  81  61  61  11
325   .  51  30  61  61  11
330   .  20  10  20  11  11
331   .  20  10  20  11  11
332   .  20  10  20  11  11
333   .  40  30  40  30  11
334   .  50  30  61  61  11
335   .  40  30  40  30  30
340   .  51  30  61  61  11
341   .  51  30  42  30  11
342   .  51  30  61  61  11
343   .  51  30  61  61  11
350   .  50  30  61  61  11
351   .  50  30  61  61  11
352   .  50  30  61  61  11
400   .  50  30  61  61  11
410   .  50  30  61  61  11
411   .  50  30  61  61  11
412   .  50  30  61  61  11
413   .  50  30  61  61  11
420   .  93  82  61  61  11
421   .  93  82  61  61  11
422   .  92  82  61  61  11
430   .  50  30  61  61  11
431   .  50  30  61  61  11
432   .  93  30  61  61  11
440   .  50  82  61  61  11
441   .  50  82  61  61  11
500   .  92  81  60  62  11
510   .  92  81  60  62  11
511   .  92  81  60  62  11
512   .  92  81  60  62  11
513   .  92  81  60  62  11
514   .  92  81  60  62  11
515   .  92  81  60  62  11
516   .  91  81  60  62  11
520   .  93  81  60  62  11
521   . 111  93  60  62  11
522   .  93  81  60  62  11
523   .  93  82  60  62  11
524   .  93  81  60  62  11
530   .  91  81  60  62  11
531   .  91  81  60  62  11
532   .  91  81  60  62  11
540   .  92  81  52  52  52
541   .  92  81  52  52  52
600   . 100  80  70  70  11
610   . 100  80  70  70  11
611   . 100  80  70  70  11
612   . 100  80  70  70  11
613   . 100  80  70  70  11
620   . 100  80  70  70  11
621   . 100  80  70  70  11
622   . 103  80  70  70  11
630   .  70  70  70  70  70
631   .  70  70  70  70  70
632   .  70  70  70  70  70
633   .  70  70  70  70  70
634   .  70  70  70  70  70
700   . 102  80  60  62  11
710   . 102  80  60  62  11
711   . 102  80  60  62  11
712   . 102  80  60  62  11
713   . 102  80  60  62  11
720   . 102  80  60  62  11
721   . 102  80  60  62  11
722   . 102  80  60  62  11
723   . 102  80  60  62  11
730   . 102  80  60  62  11
731   . 102  80  60  62  11
732   . 102  80  60  62  11
740   . 102  80  60  62  11
741   . 102  80  60  62  11
742   .  80  80  60  62  11
750   . 102  80  60  62  11
751   . 102  80  60  62  11
752   . 102  80  60  62  11
753   . 102  80  60  62  11
754   . 102  80  60  62  11
800   .   .  80  60  62  11
810   . 110  80  60  62  11
811   . 110  80  60  62  11
812   . 110  80  60  62  11
813   . 110  80  60  62  11
814   . 110  80  60  62  11
815   . 110  80  60  62  11
816   . 110  80  60  62  11
817   . 110  80  60  62  11
818   . 110  80  60  62  11
820   . 110  80  60  62  11
821   . 110  80  60  62  11
830   . 103  80  60  62  11
831   . 103  80  60  62  11
832   . 111  80  60  62  11
833   . 103  80  60  62  11
834   . 110  80  60  62  11
835   . 103  80  60  62  11
900   .   .   .  60  62  11
910   . 111  81  60  62  11
911   . 111  81  60  62  11
912   . 111  81  60  62  11
920   . 110  80  70  70  11
921   . 110  80  70  70  11
930   . 110  80  70  70  11
931   . 110  80  60  62  11
932   . 110  80  60  62  11
933   . 111  80  60  62  11
940   . 111  81  60  62  11
941   . 111  81  60  62  11
950   . 111  81  60  62  11
951   . 111  81  60  62  11
952   . 111  81  60  62  11
960   . 111  80  60  62  11
961   . 111  80  60  62  11
962   . 111  80  60  62  11
