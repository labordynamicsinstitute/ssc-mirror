{smcl}
{* *! version 15.0 8nov2022}{...}
{hline}
{cmd:robnova} {it:Calculates two {ul:rob}ust A{ul:NOVA} statistics, Welch's and Brown-Forsythe's}
{hline}

{title:Syntax}

{cmd:robnova} {it:outcome} {it:predictor} {it:[if]}

{title:Description}

{p} Produces Fisher's {it:F}, Welch's {it:F}, and Brown-Forsythe's {it:F}. It is intended as an alternative to the {cmd:anova} command when homogeneity of variance is violated. {p_end}

{p} 1. The outcome variable must consist of three or more groups. {p_end}

{p} 2. The standard deviation of each group for the outcome variable must be > 0.00. {p_end}

{p} 3. Factor levels of the predictor variable must be integers (-5, 3, 100, etc.) and not fractional (-.25, 3.14, 5.22342, etc.). {p_end}

{title:Options}

There are no options.

{title:Example 1}

{p}
Let's explore a case where groups would report dissimilar variances for an outcome variable. Regional temperature data for January will do nicely. {p_end}	
{input:sysuse citytemp, clear}

{input:robvar tempjan, by(division)}

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


{p} Levene's statistic is significiant and indicates that groups report heterogeneous variances. Specifically, New England, Mid-Atlantic, and East-North-Central show lower variability in their January temperatures. {p_end}

{p} We could ignore this heterogeneity and simply run an {cmd:anova} command on the data but this may result in problematic inferences. {p_end}


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
	 

{p} Alternatively, running the {cmd:robnova} command will produce robust {it:F}-statistics that address the violation of homogeneity of variance. {p_end}
   
{input:robnova tempjan division}

Outcome variable is tempjan
Predictor variable is division

R-squared = 0.72712

  Test              |      F      df1      df2         p
--------------------+----------------------------------------
  Fisher's          | 314.7526     8    945.0000    0.0000
  Welch's           | 382.5897     8    293.4047    0.0000
  Brown-Forsythe's  | 306.7036     8    485.9155    0.0000
-------------------------------------------------------------


{p} {cmd:robnova} automatically produces the {it:F}-values, df1, df2, and p-values for Fisher's, Welch's, and Brown-Forsythe's statistics. Either of the latter two can be reported as robust ANOVAs. {p_end}

{p} Please, note that {cmd:robnova}'s results for Fisher's {it:F}-statistics are taken directly from the {cmd:anova} command. {p_end}

{title:Example 2}

{p} You may also restrict the sample using an 'if' qualifier. {p_end}

{input:sysuse citytemp, clear}
{input:robnova tempjan division if region == 1 | region == 4}

Outcome variable is tempjan
Predictor variable is division
R-squared = 0.71171

  Test              |      F      df1       df2         p
--------------------+----------------------------------------
  Fisher's          | 342.3335     3    416.0000    0.0000
  Welch's           |  99.7482     3    490.5824    0.0000
  Brown-Forsythe's  | 845.5398     3    871.7896    0.0000
-------------------------------------------------------------


{p} In this case the analyses will only consider respondents if they were in region 1 or region 4. {p_end}

{title:Scalars}

{p} {cmd:robnova} produces several scalars accessible by typing {cmd:return list}. Values related to Fisher's {it:F}-statistics and sums of squares are pulled from the {cmd:anova} command. {p_end}

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
                r(ssm) =  Sums of square model
                r(ssr) =  Sums of square residual
                r(sst) =  Sums of square total
                 r(r2) =  R-squared value (i.e., SSM/SST)
             r(lambda) =  Lambda correction used for Welch's F-statistic
			 
{title:Author}

Dr. David Speed
Department of Psychology
University of New Brunswick - Saint John
dspeed@unb.ca

{p}{it:Note 1.} While I have tested robnova it is offered 'as-is' with no warranty. However, if you encounter issues or errors, please email me. 

{p}{it:Note 2.} I used different internet sources and "{it:Field, A. P. (2009). Discovering statistics using SPSS (and sex and drugs and rock 'n' roll), 3rd Edition. London: Sage.}" for the formulas. Any mistakes are my own. {p_end}
{hline}
