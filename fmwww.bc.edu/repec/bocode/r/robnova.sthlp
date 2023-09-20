{smcl}
{* version 1.1 Revised September 20, 2023; David Speed; dspeed@unb.ca}{...}
{hline}
{cmd:robnova} {it:Calculates two {ul:rob}ust A{ul:NOVA} statistics, Welch's and Brown-Forsythe's}
{hline}

{title:Syntax}

{cmd:robnova} {depvar} {var} {ifin}

{title:Description}

{p} {cmd:robnova} produces Fisher's {it:F}, Welch's {it:F}, and Brown-Forsythe's {it:F}. It is intended as an alternative to the {cmd:anova} command when the assumption of homogeneity of variance is violated. {p_end}

{title:Example 1}

{p} Let's explore a case where groups would report dissimilar variances for an outcome variable. Regional temperature data for January will do nicely. {p_end}

{phang}{cmd:sysuse citytemp, clear} {p_end}

{phang}{cmd:des tempjan division} {p_end}

{asis}
                      storage   display    value
        variable name   type    format     label      variable label
        ------------------------------------------------------...---
        tempjan         float   %9.0g                 Average January temperature
        division        int     %8.0g      division   Census Division
{smcl}

{phang}{cmd:robvar tempjan, by(division)}  {p_end}
{asis}

                    |     Summary of Average January
             Census |             temperature
           Division |        Mean   Std. Dev.       Freq.
        ------------+------------------------------------
            N. Eng. |   26.931344   3.1932794          67
            Mid Atl |    28.54433   3.6373629          97
             E.N.C. |   22.791262   3.7612817         206
             W.N.C. |   18.797436   8.4316499          78
            S. Atl. |   49.157391   12.828518         115
             E.S.C. |   40.778261   6.2526763          46
             W.S.C. |    45.02809    6.624558          89
           Mountain |   32.701639   9.5515528          61
            Pacific |   50.455898    7.922557         195
        ------------+------------------------------------
              Total |   35.748952   14.188133         954

        W0  =  55.647319   df(8, 945)     Pr > F = 0.00000000

        W50 =  39.701835   df(8, 945)     Pr > F = 0.00000000

        W10 =  59.150555   df(8, 945)     Pr > F = 0.00000000

{smcl}
{p} Levene's statistic is significiant; groups in division report heterogeneous variances for their January temperatures. At a glance, New England, Mid-Atlantic, and East-North-Central show lower variability in their January temperatures. We could ignore this heterogeneity and simply run an {cmd:anova} command on the data but this may result in a problematic inference. {p_end}

{phang}{cmd:anova tempjan division}

{asis}
                   Number of obs =        954    R-squared     =  0.7271
                   Root MSE      =    7.44293    Adj R-squared =  0.7248

            Source | Partial SS         df         MS        F    Prob>F
        -----------+----------------------------------------------------
             Model |  139491.45          8   17436.431    314.75  0.0000
                   |
          division |  139491.45          8   17436.431    314.75  0.0000
                   |
          Residual |  52350.416        945   55.397265  
        -----------+----------------------------------------------------
             Total |  191841.86        953   201.30311  
	 
{smcl}

{p} Alternatively, running the {cmd:robnova} command will produce robust {it:F}-statistics that address the violation of homogeneity of variance. {p_end}

{phang}{cmd:robnova tempjan division}{p_end}

{asis}
        Outcome variable was tempjan and predictor variable was division
        
        Sum of Squares Model = 139491.4477
        Sum of Squares Residual = 52350.4158
        Sum of Squares Total = 191841.8635
        R-squared = 0.72712
        
        ---------------------------------------------------------
                    Test |     F        df1       df2        p   
        -----------------+---------------------------------------
        Brown-Forsythe's | 306.7036      8     485.9155   0.0000 
                Fisher's | 314.7526      8     945.0000   0.0000 
                 Welch's | 382.5897      8     293.4047   0.0000 
        ---------------------------------------------------------
        Total number of observations used was 954.

{smcl}
{p} Please, note that {cmd:robnova}'s results for Fisher's {it:F}-statistics are taken directly from the {cmd:oneway} command. {p_end}

{title:Example 2}

{p} You may also restrict the sample using either or both of the {ifin} qualifiers. {p_end}

{phang}{cmd:robnova tempjan division if region == 1 | region == 4}{p_end}

{asis}
        Outcome variable was tempjan and predictor variable was division
        
        Sum of Squares Model = 48372.2933
        Sum of Squares Residual = 19593.8336
        Sum of Squares Total = 67966.1269
        R-squared = 0.71171
        
        ---------------------------------------------------------
                    Test |     F        df1       df2        p   
        -----------------+---------------------------------------
        Brown-Forsythe's | 371.0895      3     155.3566   0.0000 
                Fisher's | 342.3335      3     416.0000   0.0000 
                 Welch's | 434.9838      3     175.5545   0.0000 
        ---------------------------------------------------------
        Total number of observations used was 420.
{smcl}

{p} In this case the analyses will only consider respondents if they were in region 1 or region 4. {p_end}

{title:Example 3}

{phang}{cmd:robnova tempjan division in 100/600} {p_end}

{asis}
        Outcome variable was tempjan and predictor variable was division
        
        Sum of Squares Model = 31522.9725
        Sum of Squares Residual = 11080.4170
        Sum of Squares Total = 42603.3895
        R-squared = 0.73992
        
        ---------------------------------------------------------
                    Test |     F        df1       df2        p   
        -----------------+---------------------------------------
        Brown-Forsythe's | 264.4825      6     216.4357   0.0000 
                Fisher's | 233.2840      6     492.0000   0.0000 
                 Welch's | 270.4163      6      59.1877   0.0000 
        ---------------------------------------------------------
        Total number of observations used was 499.
{smcl}

{p}In this case the analyses will only consider respondents if they were in rows 100 through 600.

{title:Scalars}

{p} {cmd:robnova} produces several scalars accessible by typing {cmd:return list}. {p_end}

              r(fis_F) =  Fisher's F-statistic
            r(fis_df1) =  Fisher's df1
            r(fis_df2) =  Fisher's df2
              r(fis_p) =  Fisher's p-value
              r(wel_F) =  Welch's F-statistic
            r(wel_df1) =  Welch's df1
            r(wel_df2) =  Welch's df2
              r(wel_p) =  Welch's p-value
               r(bf_F) =  Brown-Forsythe's F-statistic
             r(bf_df1) =  Brown-Forsythe's df1
             r(bf_df2) =  Brown-Forsythe's df2
               r(bf_p) =  Brown-Forsythe's p-value
                r(ssm) =  Sum of squares model
                r(ssr) =  Sum of squares residual
                r(sst) =  Sum of squares total
                 r(r2) =  R-squared value (i.e., SSM/SST)
             r(lambda) =  Lambda correction used for Welch's F-statistic
                  r(N) =  Number of observations
			 
{title:Author}

Dr. David Speed
Department of Psychology
University of New Brunswick - Saint John
dspeed@unb.ca

{p}{it:Note 1.} While I have tested robnova it is offered 'as-is' with no warranty. However, if you encounter issues or errors, please email me. 

{p}{it:Note 2.} I used different internet sources and "{it:Field, A. P. (2009). Discovering statistics using SPSS (and sex and drugs and rock 'n' roll), 3rd Edition. London: Sage.}" for the formulas. Any mistakes are my own. {p_end}

{p} robnova v1.1 now allows for [in] restictions, displays sum of squares value instead of only having them as stored results, and has a clarified help file. Factor variables can no longer be negative. {p_end}
{hline}
