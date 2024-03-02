{smcl}
{* *! version 0.31}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install diagt" "ssc install diagt"}{...}
{vieweralsosee "Help diagt (if installed)" "help diagt"}{...}
{viewerjumpto "Syntax" "confmat##syntax"}{...}
{viewerjumpto "Description" "confmat##description"}{...}
{viewerjumpto "Examples" "confmat##examples"}{...}
{viewerjumpto "Stored results" "crossmat##results"}{...}
{viewerjumpto "Author and support" "crossmat##author"}{...}
{title:Title}
{phang}
{bf:confmat} {hline 2} Confusion matrix calculations

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:confmat}
{it:gold_std_var test_var} 
[{help if}]
[{help in}]
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Optional}
{synopt:{opt by:(varname numeric)}} Compare two confusion matrices grouped by {it:varname}.

{synopt:{opt sc:ale(#)}} Scale estimates and confidence intervals. Default value is 100 (ie %).

{synopt:{opt le:vel(cilevel)}} level for confidence intervals. Default is c(level).

{synopt:{opt ci:type(string)}} Type of confidence intervals. See options at {help ci##prop_options:cii proportions}.

{synopt:{opt la:bels}} Use labels when possible.

{synopt:{opt noq:uietly}} Show underlying code and log output.

{synopt:{opt coleq(string)}} Add coleq label to single confusion matrix.

{synopt:{opt cmp:type(string)}} Type of comparison for two confusion matrices. 
Is always a test. Option {bf:rr} adds relative risks with confidence intervals.
Option {bf:rd} adds risk differences. See {help cs:cs}.

{synopt:{opt e:xact}} Whether the test is chisquare test (default) or Fisher's 
exact test. See {help cs:cs}.

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}Given a binary variable for the gold standard and a binary variable for 
the test {cmd:confmat} returns sensitivity, specificity, prevalence, accuracy, 
ppv and npv (ie derived values from the confusion matrix) with confidence intervals.

{pstd}When a binary grouping variable is specified in option {opt by:} the 
confusion matrix for each grouping values is reported as well as comparison tests.

{pstd}To learn more about confusion matrices see 
{browse "https://en.wikipedia.org/wiki/Sensitivity_and_specificity" : Wikipedia on sensitivity and specificity}  
and {browse "https://en.wikipedia.org/wiki/Confusion_matrix" : Wikipedia on Confusion_matrix}  

{marker examples}{...}
{title:Examples}

{pstd}Example data from {browse: "https://en.wikipedia.org/wiki/Sensitivity_and_specificity"}
    {cmd:cls}
    {cmd:clear}
    {cmd:input actual test n}
    {cmd:0 0 1820}
    {cmd:0 1 180}
    {cmd:1 0 10}
    {cmd:1 1 20}
    {cmd:end}
    {cmd:expand n}

{pstd}To get sensitivity, specificity, prevalence, accuracy, ppv and npv 
(ie derived values from the confusion matrix) with confidence intervals.

    {cmd:confmat actual test}

{pstd}Example data for two confusion matrices

    {cmd:clear}
    {cmd:input actual test n grp}
    {cmd:0 0 1820 1}
    {cmd:0 1 180 1}
    {cmd:1 0 10 1}
    {cmd:1 1 20 1}
    {cmd:0 0 1620 2}
    {cmd:0 1 150 2}
    {cmd:1 0 18 2}
    {cmd:1 1 40 2}
    {cmd:end}
    {cmd:expand n}

{pstd}One can condition to get a single confusion matrix.

    {cmd:confmat actual test if grp == 1}
    
          -------------------------------
                        test            
                            0    1  Total
          -------------------------------
          actual  0      1820  180   2000
                  1        10   20     30
                  Total  1830  200   2030
          -------------------------------
            
          -----------------------------------------------------------
                                      N   p(%)  [95% Conf.  interval]
          -----------------------------------------------------------
          Sensitivity  P(TP|C+)      30  66.67       47.19      82.71
          Specificity  P(TN|C-)    2000  91.00       89.66      92.22
          Prevalence   P(C+)       2030   1.48        1.00       2.10
          Accuracy     P(TP + TN)  2030  90.64       89.29      91.87
          PPV          P(TP|P+)     200  10.00        6.22      15.02
          NPV          P(TN|P-)    1830  99.45       99.00      99.74
          -----------------------------------------------------------


{pstd}Or get a comparison report including relative risks of the two confusion matrices.

    {cmd:confmat actual test, by(grp) cmp("rr")}
    
        -----------------------------------------------------------------------------------------------------------------------------------------------------
                                 grp(1)                                grp(2)                                grp(1 vs 2)                                     
                                      N   p(%)  [95% Conf.  interval]       N   p(%)  [95% Conf.  interval]           RR  [95% Conf.  interval]  P(Chisquare)
        -----------------------------------------------------------------------------------------------------------------------------------------------------
        Sensitivity  P(TP|C+)        30  66.67       47.19      82.71      58  68.97       55.46      80.46         0.97        0.71       1.31          0.83
        Specificity  P(TN|C-)      2000  91.00       89.66      92.22    1770  91.53       90.13      92.78         0.99        0.97       1.01          0.57
        Prevalence   P(C+)         2030   1.48        1.00       2.10    1828   3.17        2.42       4.08         0.47        0.30       0.72          0.00
        Accuracy     P(TP + TN)    2030  90.64       89.29      91.87    1828  90.81       89.39      92.10         1.00        0.98       1.02          0.86
        PPV          P(TP|P+)       200  10.00        6.22      15.02     190  21.05       15.49      27.54         0.47        0.29       0.78          0.00
        NPV          P(TN|P-)      1830  99.45       99.00      99.74    1638  98.90       98.27      99.35         1.01        1.00       1.01          0.07
        -----------------------------------------------------------------------------------------------------------------------------------------------------


{pstd}Labels can be included in the returned matrix.

    {cmd:label variable grp "Group"}
    {cmd:label define grp 1 "Poor" 2 "Rich"}
    {cmd:label values grp grp}
    {cmd:confmat actual test, by(grp) label}

        ----------------------------------------------------------------------------------------------------------------------------------
                                 Group(Poor)                                Group(Rich)                                Group(Poor vs Rich)
                                           N   p(%)  [95% Conf.  interval]            N   p(%)  [95% Conf.  interval]         P(Chisquare)
        ----------------------------------------------------------------------------------------------------------------------------------
        Sensitivity  P(TP|C+)             30  66.67       47.19      82.71           58  68.97       55.46      80.46                 0.83
        Specificity  P(TN|C-)           2000  91.00       89.66      92.22         1770  91.53       90.13      92.78                 0.57
        Prevalence   P(C+)              2030   1.48        1.00       2.10         1828   3.17        2.42       4.08                 0.00
        Accuracy     P(TP + TN)         2030  90.64       89.29      91.87         1828  90.81       89.39      92.10                 0.86
        PPV          P(TP|P+)            200  10.00        6.22      15.02          190  21.05       15.49      27.54                 0.00
        NPV          P(TN|P-)           1830  99.45       99.00      99.74         1638  98.90       98.27      99.35                 0.07
        ----------------------------------------------------------------------------------------------------------------------------------

    
{marker results}{...}
{title:Stored results}

{pstd}
{cmd:confmat} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(confmat)}}The estimated values from one or two confusion matrices 
and if two matrices comparison calculations in a table/matrix.{p_end}


{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}
