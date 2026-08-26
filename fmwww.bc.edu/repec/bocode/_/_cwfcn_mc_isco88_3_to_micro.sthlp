{smcl}
{* version 1.0.0  18aug2026}{...}
{hi:mc_isco88_3_to_micro()} {hline 2} Translate 3-digit ISCO-88(com) to Micro-SEC

{title:Syntax}

        {cmd:mc.isco88_3_to_micro(}{it:varname} {it:case}{cmd:)}

{pstd}
    where {it:varname} contains 3-digit ISCO-88(com) minor group codes
    and {it:case} selects the employment status column.

{pstd}
    Typical usage:

        {cmd:mc.isco88_3_to_micro(}{it:varname} {cmd:case.mcempstat(}{it:sempl} {it:supvis}{cmd:)}{cmd:)}

{title:Description}

{pstd}
    {helpb crosswalk} table translating 3-digit ISCO-88(com) minor
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
    Note that this table is based on
    {browse "https://warwick.ac.uk/fac/soc/ier/research/classification/isco88":ISCO-88(COM)},
    the European Union variant of the ISCO-88. If your data contains ISCO-88
    codes you might first want to translate these codes to ISCO-88(COM) using
    {helpb _cwfcn_isco88_to_isco88com:isco88_to_isco88com()}.

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
010   .  10  10  10  11  11
011   .  52  30  52  52  52
100   .   .  10   .  61  11
110   .  10  10  11  11  11
111   .  10  10  10  11  11
112   .  10  10  11  11  11
113   .  10  10  11  11  11
114   .  10  10  10  11  11
120   .  10  10  61  61  11
121   .  10  10  61  61  11
122   .  30  30  61  61  11
123   .  10  10  61  61  11
130   .  30  30  61  61  11
131   .  30  30  61  61  11
200   .   .  10   .  11  11
210   .  22  10  22  11  11
211   .  22  10  22  11  11
212   .  22  10  22  11  11
213   .  22  10  22  11  11
214   .  22  10  22  11  11
220   .  21  10  21  11  11
221   .  22  10  22  11  11
222   .  21  10  21  11  11
223   .  41  30  41  30  11
230   .  44  30  44  30  11
231   .  23  10  23  11  11
232   .  44  30  44  30  11
233   .  44  30  44  30  11
234   .  44  30  44  30  11
235   .  23  10  23  11  11
240   .  20  10  20  11  11
241   .  20  10  20  11  11
242   .  20  10  20  11  11
243   .  42  30  42  30  11
244   .  44  30  44  30  11
245   .  42  30  42  30  11
246   .  42  30  42  30  11
247   .  40  30  40  30  11
300   .   .   .   .  61  11
310   .  43  30  43  30  11
311   .  43  30  43  30  11
312   .  43  30  43  30  11
313   .  80  30  61  61  11
314   .  43  30  43  30  11
315   .  82  82  61  61  11
320   .  41  30  41  30  11
321   .  43  30  43  30  11
322   .  41  30  41  30  11
323   .  41  30  41  30  11
324   .  41  30  41  30  11
330   .  51  30  61  61  11
331   .  51  30  61  61  11
332   .  51  30  61  61  11
333   .  51  30  61  61  11
334   .  42  30  42  30  11
340   .  50  30  61  61  11
341   .  50  30  61  61  11
342   .  40  30  40  30  11
343   .  50  30  61  61  11
344   .  40  30  40  30  30
345   .  40  30  40  30  30
346   .  51  30  61  61  11
347   .  51  30  61  61  11
348   .  42  30  42  30  11
400   .  50  30  61  61  11
410   .  50  30  61  61  11
411   .  50  30  61  61  11
412   .  50  30  61  61  11
413   .  93  80  61  61  11
414   . 111  82  61  61  11
419   .  50  30  61  61  11
420   .  50  30  61  61  11
421   .  93  82  61  61  11
422   .  92  82  61  61  11
500   .   .  81  60  62  11
510   .  91  81  60  62  11
511   .  92  81  60  62  11
512   . 111  81  60  62  11
513   .  91  81  60  62  11
514   .  93  81  60  62  11
515   .  91  81  60  62  11
516   .  92  81  52  52  52
520   .  93  82  60  62  11
521   .  42  30  60  62  11
522   .  93  82  60  62  11
523   .  93  82  60  62  11
600   . 100  80  70  70  11
610   . 100  80  70  70  11
611   . 100  80  70  70  11
612   . 100  80  70  70  11
613   . 100  80  70  70  11
614   . 100  80  70  70  11
615   . 103  80  70  70  11
620   . 100  80  70  70  11
621   .  70  70  70  70  70
700   . 102  80  60  62  11
710   . 102  80  60  62  11
711   . 102  80  60  62  11
712   . 102  80  60  62  11
713   . 102  80  60  62  11
714   . 102  80  60  62  11
720   . 102  80  60  62  11
721   . 102  80  60  62  11
722   . 102  80  60  62  11
723   . 102  80  60  62  11
724   . 102  80  60  62  11
730   .  80  80  60  62  11
731   .  80  80  60  62  11
732   . 102  80  60  62  11
733   . 102  80  60  62  11
734   . 102  80  60  62  11
740   . 102  80  60  62  11
741   . 102  80  60  62  11
742   . 102  80  60  62  11
743   . 102  80  60  62  11
744   . 102  80  60  62  11
800   .   .  80  60  62  11
810   . 110  80  60  62  11
811   . 110  80  60  62  11
812   . 110  80  60  62  11
813   . 110  80  60  62  11
814   . 110  80  60  62  11
815   . 110  80  60  62  11
816   . 110  80  60  62  11
817   . 110  80  60  62  11
820   . 110  80  60  62  11
821   . 110  80  60  62  11
822   . 110  80  60  62  11
823   . 110  80  60  62  11
824   . 110  80  60  62  11
825   . 103  80  60  62  11
826   . 110  80  60  62  11
827   . 110  80  60  62  11
828   . 110  80  60  62  11
829   . 110  80  60  62  11
830   . 110  80  60  62  11
831   . 103  80  60  62  11
832   . 110  80  60  62  11
833   . 110  80  60  62  11
834   . 103  80  60  62  11
900   .   .   .  60  62  11
910   . 111  81  60  62  11
911   .  93  81  60  62  11
912   . 111  81  60  62  11
913   . 111  81  60  62  11
914   . 111  81  60  62  11
915   . 111  81  60  62  11
916   . 111  80  60  62  11
920   . 110  80  70  70  11
921   . 110  80  70  70  11
930   . 110  80  60  62  11
931   . 110  80  60  62  11
932   . 110  80  60  62  11
933   . 111  80  60  62  11
