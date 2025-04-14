{smcl}
{* version 01.0.0 10apr2025 Hans Gerhardt and Anneke Kappes}{...}
{hi:kldb10_2plus5_to_bas25()} {hline 2} Translate 2plus5-digit KldB-2010 to BAS-2|5 scores.

{title:Syntax}

        {cmd:kldb10_2plus5_to_bas25(}{varname}{cmd:)}

{pstd}
    where {it:varname} contains 2plus5-digit KldB-2010 codes.

{title:Description}

{pstd}
    {helpb kldbrecode} table translating KldB-2010 occupational main groups (2 digits) combined with the skill level (5th-digit) to BAS-2|5 occupational prestige scores
    using {helpb crosswalk}.
    
{pstd}
    Ebner and Rohrbach-Schmidt provide two versions of the occupational prestige scores. 
    V1 is estimated on the basis of the simple mean prestige ratings.
    V2 is estimated on the basis of a cross-classified multi-level regression model controlling for rater characteristics.
    The version to be matched can be specified via the {help crosswalk##case:{it:case argument}}. 
    To generate V2 scores, which are listed in the second column, specify
    {p_end}

        {cmd:kldb10_2plus5_to_bas25(}{varname} 2{cmd:)}.

{title:Reference}

{pstd}
    Ebner, C. and Rohrbach-Schmidt, D. 2021. 
    Das gesellschaftliche Ansehen von Berufen. Konstruktion einer neuen 
    beruflichen Ansehensskala und empirische Befunde für Deutschland
    [The Social Prestige of Occupations. Construction of a New 
    Occupational Prestige Scale and Empirical Results for Germany]. 
    Zeitschrift für Soziologie, 50(6), 349-372.
    DOI: {browse "https://doi.org/10.1515/zfsoz-2021-0026":10.1515/zfsoz-2021-0026}.
    {p_end}

{title:Source}
{pstd}
    Ebner, C., Rohrbach-Schmidt, D. 2022.
    Occupational Prestige Scale (BAS) for Occupational Main Group Level (2-Digit Level) 
    combined with the 5-digit Level of the German Classification of Occupations (BAS-2|5). 
    Public Use File provided by the 
    Research Data Center at the Federal Institute for Vocational Education and Training (BIBB), Bonn.
    DOI: {browse "https://doi.org/10.7803/582.18.1.0.10":10.7803/582.18.1.0.10}.
    {p_end}

{hline}
{asis}
012   5.447189   5.441998
013   5.174644   5.634591
014   6.368631   6.277408
111   4.017875   3.607471
112   5.299568   5.300488
113   5.916268   5.683005
114   6.865923   6.535371
121   4.023768   4.093229
122    5.45096   5.276045
123   5.575625   5.581146
124   6.036039   6.035695
211   4.539421   4.002159
212    5.04344   5.065507
213    5.66463   5.725005
214    7.09232   6.724747
221   3.922016   3.986749
222   5.470634   5.701616
223   6.128298   6.086049
224    6.92347     6.8166
231   4.367915   4.149618
232   5.416764   5.347586
233   6.361087    6.19112
234   5.641573   5.834924
241    4.41154   4.571226
242   5.558558   5.495714
243   6.089866   5.720531
244    6.92347     6.8166
251   5.713054   5.654203
252    6.13757   5.868639
253   6.857918   6.857412
254   7.683449   7.629824
261   3.903019   4.235198
262   6.918934   6.740023
263   6.708075   6.830139
264   7.444693    7.23556
272   5.705971   5.646199
273   6.358086   6.149959
274   7.600088    7.52702
281   3.476136   3.422843
282   4.354124   4.396362
283   4.999251   5.109892
284   5.408178   5.420557
291   4.238147    4.35874
292   5.368558    5.54881
293   5.377195   5.505092
294   6.974164   6.643894
312   6.210703   6.265263
313   6.759871   6.211067
314   6.931004   6.711808
321   4.426411   3.900383
322   4.988713   4.977181
323    5.17724    5.02931
324   7.025648   7.104314
331   4.843493   4.743177
332   5.807773   5.607265
333   5.043245   5.207753
341   5.260574   5.585972
342    5.07987   4.887388
343   4.993322    5.04742
344   7.155783   7.644009
411   5.042959   4.429486
412    6.23044   5.993053
413   6.671444   6.430125
414   6.974489   6.878443
422   4.350023   4.891396
423   6.003678   6.115106
424   6.649081   6.677367
432   7.318816    7.26303
433   7.177849   6.930338
434   7.212156   7.031186
511   3.864966   3.749629
512   5.019768   4.864808
513    5.28945   5.180942
514   5.694667   5.483326
521   4.171001   3.967165
522   4.344809   4.578039
523   7.481602   7.648756
524   5.796911   5.682678
531   3.372807    3.14626
532   6.075339   5.928539
533   7.155076   6.694493
534   5.910515   5.904181
541   4.320048   4.162645
542   4.783622   4.667387
543   6.102823   5.924885
612   5.892426    5.76524
613   4.837314   4.909207
614   5.624351   5.722488
621   3.454617   3.357252
622    4.94112   4.916628
623   5.776124   5.770254
624   5.934398   5.678746
631   3.888334   3.932474
632   5.098983    5.23797
633   6.527173   6.459091
634   5.974836    5.65683
711   4.392198   4.628742
712   5.727726   5.590302
713   6.520536   6.308929
714   6.321793   6.050738
722   5.480823   5.342572
723   5.410535   5.368099
724   6.046362   5.902743
731   4.548146    4.62404
732    5.60669   5.328098
733   5.682091   5.584341
734   6.518659   6.479567
811   6.179841   6.365504
812   6.366016   6.449102
813   7.111681   6.805782
814   7.115466   7.180926
821   5.113268   5.292842
822   5.955461   5.924037
823   6.065288   6.012815
824   6.030208   5.950037
831   5.105302    5.10076
832   5.969979   5.927689
833   6.414664   6.383923
834   5.669693   5.777029
842   5.658653   5.529463
843   6.003154   5.835052
844    6.62512    6.58782
911   3.117989   3.329315
912   5.197173   4.812505
913   5.472366   5.620208
914   6.104805   5.998129
922   4.200632   4.221305
923   5.691213   5.705213
924   6.005056   5.902946
932   5.669808   5.486003
933   5.184392   5.506302
934   5.699007   5.768758
942   5.736735   5.627329
943   5.785808   5.744761
944   5.911237   5.924937
