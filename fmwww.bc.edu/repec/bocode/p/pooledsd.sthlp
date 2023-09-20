{smcl}
[*!version 1.0 20sep2023]{...}
{hline}
{cmd:pooledsd} {it:Calculates pooled standard deviation for a continuous variable by a factor variable.} 
{hline}

{title:Syntax}

{cmd:pooledsd} {depvar} {ifin}, by({var}) [mdiff(num)]

{title:Description}

{p} Calculates the pooled standard deviation for a continuous variable using the groups listed in a factor variable {p_end}

{phang} sqrt((({it:n}_1-1)*{it:sd}_1^2 + ({it:n}_2-1)*{it:sd}_2^2 + ... ({it:n}_{it:k}-1)*{it:sd}_{it:k}^2)/({it:n}_1 + {it:n}_2 + ... {it:n}_{it:k} - {it:k})) {p_end}

{p}Where:  {p_end}

{phang} {it:n} = the number of observations in a given group. {p_end}
{phang} {it:sd} = the standard deviation for a continuous variable for a given group. {p_end}
{phang} {it:k} = the total number of groups for which the standard deviation is being pooled. {p_end}

{title:Options}

{opt by(var)} is required. Specifies for which factor variable the depvar should be pooled.

{opt mdiff} is optional. The mdiff value will be divided by the pooled standard deviation value and Cohen's d will be reported in the output.
	
{title:Example #1}

{p}We are interested in exploring the variability in average January temperatures. {p_end}

{phang} {cmd:sysuse citytemp, clear} {p_end}

{phang} {cmd:des tempjan division} {p_end}
{asis}
        
                      storage   display    value
        variable name   type    format     label      variable label
        --------------------------------------------------------------...--------
        tempjan         float   %9.0g                 Average January temperature
        division        int     %8.0g      division   Census Division
{smcl}

{phang} {cmd:tabstat tempjan, statistics(n mean sd)} {p_end}
{phang2} {asis}
            variable |         N      mean        sd
        -------------+------------------------------
             tempjan |       954  35.74895  14.18813

{smcl}

{p}As we can see, the standard deviation for temperature is 14.188 degrees. But, this estimate is based on the grand mean for the contiguous USA and isn't accounting for regional variation across the country. {p_end}

{phang} {cmd:tabstat tempjan, statistics(n mean sd) by(division)} {p_end}
{asis}
        Summary for variables: tempjan
             by categories of: division (Census Division)
        
        division |         N      mean        sd
        ---------+------------------------------
         N. Eng. |        67  26.93134  3.193279
         Mid Atl |        97  28.54433  3.637363
          E.N.C. |       206  22.79126  3.761282
          W.N.C. |        78  18.79744   8.43165
         S. Atl. |       115  49.15739  12.82852
          E.S.C. |        46  40.77826  6.252676
          W.S.C. |        89  45.02809  6.624558
        Mountain |        61  32.70164  9.551553
         Pacific |       195   50.4559  7.922557
        ---------+------------------------------
           Total |       954  35.74895  14.18813
        ----------------------------------------

{smcl}
{p}Looking at the standard deviation column, we come to suspect there is unequal variability in temperature across census divisions. For example, the standard deviation for South Atlantic is {it:four times larger} than the standard deviation for New England. We should incorporate information regarding {it: division} into the estimate of standard deviation. The {cmd:pooledsd} command will do that for us. {p_end}

{phang} {cmd:pooledsd tempjan, by(division)} {p_end}

{asis}
        Pooled standard deviation for groups 1 2 3 4 5 6 7 8 9 in division.
        There were a total of 954 observations used in the calculation.
        
        ----------------------------------
        Census        |
        Division      |        n        sd
        --------------+-------------------
         #1 (N. Eng.) |       67   3.19328
         #2 (Mid Atl) |       97  3.637363
          #3 (E.N.C.) |      206  3.761282
          #4 (W.N.C.) |       78   8.43165
         #5 (S. Atl.) |      115  12.82852
          #6 (E.S.C.) |       46  6.252676
          #7 (W.S.C.) |       89  6.624558
        #8 (Mountain) |       61  9.551553
         #9 (Pacific) |      195  7.922557
        ----------------------------------
        The pooled standard deviation is 7.4429
{smcl}

{p}The pooled standard deviation is approximately half of what the unpooled standard deviation was. This makes sense given that the estimate is now incorporating information about geographical locale, which will be related to variability in temperature. {p_end}

{title:Example #2}

{p}Assume we are interested in testing if Group #1 (New England) reports a different mean temperature than the pooled means of Group #2 (Mid-Atlantic) and Group #3 (East-North-Central). We run an ANOVA on these data and follow up with a {cmd:contrast} test. {p_end}

{phang} {cmd:qui anova tempjan division} {p_end}
{phang} {cmd:contrast {division -1 .5 .5 0 0 0 0 0 0}, effects} {p_end}

{asis}      
        Contrasts of marginal linear predictions
        
        Margins      : asbalanced
        
        ------------------------------------------------
                     |         df           F        P>F
        -------------+----------------------------------
            division |          1        1.54     0.2149
                     |
         Denominator |        945
        ------------------------------------------------
        
        ------------------------------------------------------------------------------
                     |   Contrast   Std. Err.      t    P>|t|     [95% Conf. Interval]
        -------------+----------------------------------------------------------------
            division |
                (1)  |  -1.263548   1.018249    -1.24   0.2149    -3.261838    .7347432
        ------------------------------------------------------------------------------
{smcl}

{p}Although our hypothesis was not supported (p < .05), we still want to report our findings with a metric of effect size for the two-group comparison. Unfortunately, there's not an obvious method to produce an effect size estimate. While it's possible to recode division and take advantage of Stata's {cmd:esize twosample} command, this will produce a problem. {p_end}

{phang} {cmd:qui recode division (1=2) (2/3=1) (*=.), gen(pooled)} {p_end}

{phang} {cmd:ttest tempjan, by(pooled)} {p_end}

{asis}
        Two-sample t test with equal variances
        ------------------------------------------------------------------------------
           Group |     Obs        Mean    Std. Err.   Std. Dev.   [95% Conf. Interval]
        ---------+--------------------------------------------------------------------
               1 |     303      24.633    .2634905    4.586552    24.11449    25.15151
               2 |      67    26.93134    .3901212    3.193279    26.15244    27.71025
        ---------+--------------------------------------------------------------------
        combined |     370    25.04919    .2314825    4.452655      24.594    25.50438
        ---------+--------------------------------------------------------------------
            diff |            -2.29834    .5898923               -3.458323   -1.138358
        ------------------------------------------------------------------------------
            diff = mean(1) - mean(2)                                      t =  -3.8962
        Ho: diff = 0                                     degrees of freedom =      368
        
            Ha: diff < 0                 Ha: diff != 0                 Ha: diff > 0
         Pr(T < t) = 0.0001         Pr(|T| > |t|) = 0.0001          Pr(T > t) = 0.9999
{smcl}

{p} As can be seen, the mean difference has nearly doubled from |1.26| to |2.30|. This is because Group #2 (Mid-Atlantic) and Group #3 (East-North-Central) had a different number of observations and the estimate is biased toward the mean of East-North-Central. If we use the {cmd:esize twosample} command--which will use the same mean difference as the t-test--we will overestimate the resulting effect size. {cmd:pooledsd} offers an alternative. {p_end}

{phang} {cmd:pooledsd tempjan, by(division) mdiff(-1.263548)} {p_end}

{asis}
        Pooled standard deviation for groups 1 2 3 4 5 6 7 8 9 in division.
        There were a total of 954 observations used in the calculation.
        
        ------------------------------------
        Census        |
        Division      |         n         sd
        --------------+---------------------
         #1 (N. Eng.) |        67  3.1932794
         #2 (Mid Atl) |        97  3.6373629
          #3 (E.N.C.) |       206  3.7612817
          #4 (W.N.C.) |        78  8.4316499
         #5 (S. Atl.) |       115  12.828518
          #6 (E.S.C.) |        46  6.2526763
          #7 (W.S.C.) |        89   6.624558
        #8 (Mountain) |        61  9.5515528
         #9 (Pacific) |       195   7.922557
        ------------------------------------
        The pooled standard deviation is 7.4429
        The Cohen's d estimate is -0.1698
{smcl}

{p}By using {cmd:pooledsd} and specifying the contrast value in {opt mdiff} we can produce an estimate of effect size based on the pooled standard deviation of all groups. {p_end}

{title:Example #3}

{p}While the previous use of {cmd:pooledsd} produced an estimate of Cohen's d, it used the pooled standard deviation of all groups in {it:division}. As can be seen in the output Group #1, Group #2, and Group #3, seem to have lower variability with respect to their temperatures. Consequently, we should exclude Groups #4/#9 to ensure our effect size estimate better reflects the groups being compared. Let's only include respondents who were in Group #1 or Group #2 or Group #3. {p_end}

{phang}{cmd:pooledsd tempjan if division == 1 | division == 2 | division == 3, by(division) mdiff(-1.263548)}{p_end}

{asis}
        Pooled standard deviation for groups 1 2 3 in division.
        There were a total of 370 observations used in the calculation.
        
        -----------------------------------
        Census       |
        Division     |         n         sd
        -------------+---------------------
        #1 (N. Eng.) |        67  3.1932794
        #2 (Mid Atl) |        97  3.6373629
         #3 (E.N.C.) |       206  3.7612817
        -----------------------------------
        The pooled standard deviation is 3.6328
        The Cohen's d estimate is -0.3478
{smcl}

{p}Only groups who were given a non-zero weight in the contrast command are now included in the pooled standard deviation estimate. Our Cohen's {it:d} estimate is |0.35|, which is conventionally interpreted to be a small effect.  {p_end}

{title:Scalars}

{p} {cmd:pooledsd} produces two scalars. {p_end}

{asis}
        scalars:
                       r(cohd) =  Cohen's d estimate
                        r(psd) =  Pooled standard deviation estimate
{smcl}

{title:Author}

Dr. David Speed
Department of Psychology
University of New Brunswick - Saint John
dspeed@unb.ca

{p}{it:Note 1.} While I have tested pooledsd it is offered 'as-is' with no warranty. However, if you encounter issues or errors, please email me. 

{hline}
