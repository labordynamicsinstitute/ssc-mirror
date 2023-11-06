{smcl}
{viewerjumpto "Syntax" "mlmr2##syntax"}{...}
{viewerjumpto "Description" "mlmr2##description"}{...}
{viewerjumpto "Examples" "mlmr2##examples"}{...}
{viewerjumpto "Stored Results" "mlmr2##stored"}{...}
{viewerjumpto "Author" "mlmr2##author"}{...}
{viewerjumpto "References" "mlmr2##references"}{...}
{p2col:{cmd:mlmr2} {c -}{c -} a postestimation command that computes r-squared measures for models estimated by {cmd:mixed}}

{marker syntax}{...}
{title:Syntax}

{p 7}{cmd:mlmr2} [, {it:options}]

{p2colset 7 30 31 0}{...}
{p2col:{it:options}}Description{p_end}
      {hline}
{p2col:{opt c:wc}}specifies that the variance decomposition be done under the assumption that each predictor in the model varies at only 1 level (e.g., every predictor below the highest level is centered-within-clusters){p_end}
      {hline}

	  
{marker description}{...}
{title:Description}
{pstd}{cmd:mlmr2} produces r-squared measures for models estimated by {cmd:mixed}.  Using the Rights and Sterba (2019; 2021; 2023b) framework for decomposing the total model-implied outcome 
variance from a multilevel model into (potentially level-specific) sources, {cmd:mlmr2} computes measures of the proportion of explained variance attributable to each (or combinations) 
of those sources (e.g., level-1 predictors via fixed slopes).  {cmd:mlmr2} can be used as a postestimation command with any set of estimation results from mixed except for results from 
cross-classified models and/or models with more than 5 levels of clustering.  {cmd:mlmr2} offers the {opt c:wc} option, which applies the variance decomposition assuming that each
predictor only varies at 1 level (if this isn't true for the estimated model, an error message will report which predictors violated this assumption).  When the {opt c:wc} option is not
specified, a warning message will be printed with the output table that points out which measures are always safe to interpret.  The other measures will potentially be biased by conflation 
if any predictor varies at more than 1 level (Rights, 2023; Rights & Sterba, 2023a).


{marker examples}{...}
{title:Examples}
    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse nlswork}

{pstd}Random-intercept and random-slope (coefficient) model, correlated random effects{p_end}
{phang2}{cmd:. mixed ln_w grade age c.age#c.age ttl_exp tenure c.tenure#c.tenure || id: tenure, cov(unstruct)}

{pstd}Using mlmr2 to compute r-squared measures for the estimated model{p_end}
{phang2}{cmd:. mlmr2}

{pstd}There are multiple predictors in this model that vary at both levels, so using the {opt c:wc} option results in an error message reporting which predictors vary at more than 1 level{p_end}
{phang2}{cmd:. mlmr2, c}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse pig}

{pstd}Two-level model{p_end}
{phang2}{cmd:. mixed weight week || id:}

{pstd}The week variable has no variation across the id clusters, so the {opt c:wc} option can be used even though week is not centered-within-clusters{p_end}
{phang2}{cmd:. mlmr2, c}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse productivity}

{pstd}Three-level nested random interactions model with ANOVA DF{p_end}
{phang2}{cmd:. mixed gsp private emp hwy water other unemp || region:water || state:other, dfmethod(anova)}

{pstd}Using mlmr2 to compute r-squared measures for the estimated model{p_end}
{phang2}{cmd:. mlmr2}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse ovary}

{pstd}Linear mixed model with MA 2 errors{p_end}
{phang2}{cmd:. mixed follicles sin1 cos1 || mare: sin1, residuals(ma 2, t(time))}

{pstd}Using mlmr2 to compute r-squared measures for the estimated model{p_end}
{phang2}{cmd:. mlmr2}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse childweight}

{pstd}Linear mixed model with heteroskedastic error variances{p_end}
{phang2}{cmd:. mixed weight age || id:age, residuals(independent, by(girl))}

{pstd}Using mlmr2 to compute r-squared measures for the estimated model{p_end}
{phang2}{cmd:. mlmr2}

    {hline}


{marker stored}{...}
{title:Stored Results}

{pstd}{cmd:mlmr2} stores the following in {cmd:r()}:

{pstd}Scalars{p_end}
{p2colset 7 30 31 0}{...}
{p2col:{cmd:r(f1)}}estimate of outcome variance attributable to the level-1 portion of predictors via fixed slopes{p_end}
{p2col:{cmd:r(f2)}}estimate of outcome variance attributable to the level-2 portion of predictors via fixed slopes{p_end}
{p2col:{cmd:r(f3)}}estimate of outcome variance attributable to the level-3 portion of predictors via fixed slopes{p_end}
{p2col:{cmd:r(f4)}}estimate of outcome variance attributable to the level-4 portion of predictors via fixed slopes{p_end}
{p2col:{cmd:r(f5)}}estimate of outcome variance attributable to the level-5 portion of predictors via fixed slopes{p_end}
{p2col:{cmd:r(f)}}estimate of outcome variance attributable to all predictors via fixed slopes{p_end}
{p2col:{cmd:r(v12)}}estimate of outcome variance attributable to the level-1 portion of predictors via level-2 random slope (co)variation{p_end}
{p2col:{cmd:r(v22)}}estimate of outcome variance attributable to the level-2 portion of predictors via level-2 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(v32)}}estimate of outcome variance attributable to the level-3 portion of predictors via level-2 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(v42)}}estimate of outcome variance attributable to the level-4 portion of predictors via level-2 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(v52)}}estimate of outcome variance attributable to the level-5 portion of predictors via level-2 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(v2)}}estimate of outcome variance attributable to all predictors via level-2 random slope (co)variation{p_end}
{p2col:{cmd:r(v13)}}estimate of outcome variance attributable to the level-1 portion of predictors via level-3 random slope (co)variation{p_end}
{p2col:{cmd:r(v23)}}estimate of outcome variance attributable to the level-2 portion of predictors via level-3 random slope (co)variation{p_end}
{p2col:{cmd:r(v33)}}estimate of outcome variance attributable to the level-3 portion of predictors via level-3 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(v43)}}estimate of outcome variance attributable to the level-4 portion of predictors via level-3 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(v53)}}estimate of outcome variance attributable to the level-5 portion of predictors via level-3 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(v3)}}estimate of outcome variance attributable to all predictors via level-3 random slope (co)variation{p_end}
{p2col:{cmd:r(v14)}}estimate of outcome variance attributable to the level-1 portion of predictors via level-4 random slope (co)variation{p_end}
{p2col:{cmd:r(v24)}}estimate of outcome variance attributable to the level-2 portion of predictors via level-4 random slope (co)variation{p_end}
{p2col:{cmd:r(v34)}}estimate of outcome variance attributable to the level-3 portion of predictors via level-4 random slope (co)variation{p_end}
{p2col:{cmd:r(v44)}}estimate of outcome variance attributable to the level-4 portion of predictors via level-4 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(v54)}}estimate of outcome variance attributable to the level-5 portion of predictors via level-4 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(v4)}}estimate of outcome variance attributable to all predictors via level-4 random slope (co)variation{p_end}
{p2col:{cmd:r(v15)}}estimate of outcome variance attributable to the level-1 portion of predictors via level-5 random slope (co)variation{p_end}
{p2col:{cmd:r(v25)}}estimate of outcome variance attributable to the level-2 portion of predictors via level-5 random slope (co)variation{p_end}
{p2col:{cmd:r(v35)}}estimate of outcome variance attributable to the level-3 portion of predictors via level-5 random slope (co)variation{p_end}
{p2col:{cmd:r(v45)}}estimate of outcome variance attributable to the level-4 portion of predictors via level-5 random slope (co)variation{p_end}
{p2col:{cmd:r(v55)}}estimate of outcome variance attributable to the level-5 portion of predictors via level-5 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(v5)}}estimate of outcome variance attributable to all predictors via level-5 random slope (co)variation{p_end}
{p2col:{cmd:r(m2)}}estimate of outcome variance attributable to level-2 outcome means via level-2 random intercept variation{p_end}
{p2col:{cmd:r(m3)}}estimate of outcome variance attributable to level-3 outcome means via level-3 random intercept variation{p_end}
{p2col:{cmd:r(m4)}}estimate of outcome variance attributable to level-4 outcome means via level-4 random intercept variation{p_end}
{p2col:{cmd:r(m5)}}estimate of outcome variance attributable to level-5 outcome means via level-5 random intercept variation{p_end}
{p2col:{cmd:r(s2)}}estimate of outcome variance attributable to level-1 residuals (i.e., amount of unexplained variance){p_end}
{p2col:{cmd:r(L1_MI_Var)}}estimate of level-1 model-implied outcome variance{p_end}
{p2col:{cmd:r(L2_MI_Var)}}estimate of level-2 model-implied outcome variance{p_end}
{p2col:{cmd:r(L3_MI_Var)}}estimate of level-3 model-implied outcome variance{p_end}
{p2col:{cmd:r(L4_MI_Var)}}estimate of level-4 model-implied outcome variance{p_end}
{p2col:{cmd:r(L5_MI_Var)}}estimate of level-5 model-implied outcome variance{p_end}
{p2col:{cmd:r(Total_MI_Var)}}estimate of total model-implied outcome variance{p_end}
{p2col:{cmd:r(R2_f1_L1)}}proportion of level-1 outcome variance explained by the level-1 portion of predictors via fixed slopes{p_end}
{p2col:{cmd:r(R2_v12_L1)}}proportion of level-1 outcome variance explained by the level-1 portion of predictors via level-2 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v13_L1)}}proportion of level-1 outcome variance explained by the level-1 portion of predictors via level-3 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v14_L1)}}proportion of level-1 outcome variance explained by the level-1 portion of predictors via level-4 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v15_L1)}}proportion of level-1 outcome variance explained by the level-1 portion of predictors via level-5 random slope (co)variation{p_end}
{p2col:{cmd:r(Resid_L1)}}proportion of level-1 outcome variance explained by the level-1 residuals (i.e., proportion of unexplained level-1 variance){p_end}
{p2col:{cmd:r(R2_f2_L2)}}proportion of level-2 outcome variance explained by the level-2 portion of predictors via fixed slopes{p_end}
{p2col:{cmd:r(R2_v22_L2)}}proportion of level-2 outcome variance explained by the level-2 portion of predictors via level-2 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(R2_v23_L2)}}proportion of level-2 outcome variance explained by the level-2 portion of predictors via level-3 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v24_L2)}}proportion of level-2 outcome variance explained by the level-2 portion of predictors via level-4 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v25_L2)}}proportion of level-2 outcome variance explained by the level-2 portion of predictors via level-5 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_m2_L2)}}proportion of level-2 outcome variance explained by level-2 outcome means via level-2 random intercept variation{p_end}
{p2col:{cmd:r(R2_f3_L3)}}proportion of level-3 outcome variance explained by the level-3 portion of predictors via fixed slopes{p_end}
{p2col:{cmd:r(R2_v32_L3)}}proportion of level-3 outcome variance explained by the level-3 portion of predictors via level-2 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(R2_v33_L3)}}proportion of level-3 outcome variance explained by the level-3 portion of predictors via level-3 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v34_L3)}}proportion of level-3 outcome variance explained by the level-3 portion of predictors via level-4 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v35_L3)}}proportion of level-3 outcome variance explained by the level-3 portion of predictors via level-5 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_m3_L3)}}proportion of level-3 outcome variance explained by level-3 outcome means via level-3 random intercept variation{p_end}
{p2col:{cmd:r(R2_f4_L4)}}proportion of level-4 outcome variance explained by the level-4 portion of predictors via fixed slopes{p_end}
{p2col:{cmd:r(R2_v42_L4)}}proportion of level-4 outcome variance explained by the level-4 portion of predictors via level-2 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(R2_v43_L4)}}proportion of level-4 outcome variance explained by the level-4 portion of predictors via level-3 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v44_L4)}}proportion of level-4 outcome variance explained by the level-4 portion of predictors via level-4 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v45_L4)}}proportion of level-4 outcome variance explained by the level-4 portion of predictors via level-5 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_m4_L4)}}proportion of level-4 outcome variance explained by level-4 outcome means via level-4 random intercept variation{p_end}
{p2col:{cmd:r(R2_f5_L5)}}proportion of level-5 outcome variance explained by the level-5 portion of predictors via fixed slopes{p_end}
{p2col:{cmd:r(R2_v52_L5)}}proportion of level-5 outcome variance explained by the level-5 portion of predictors via level-2 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(R2_v53_L5)}}proportion of level-5 outcome variance explained by the level-5 portion of predictors via level-3 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v54_L5)}}proportion of level-5 outcome variance explained by the level-5 portion of predictors via level-4 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v55_L5)}}proportion of level-5 outcome variance explained by the level-5 portion of predictors via level-5 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_m5_L5)}}proportion of level-5 outcome variance explained by level-5 outcome means via level-5 random intercept variation{p_end}
{p2col:{cmd:r(R2_f1_Total)}}proportion of total outcome variance explained by the level-1 portion of predictors via fixed slopes{p_end}
{p2col:{cmd:r(R2_f2_Total)}}proportion of total outcome variance explained by the level-2 portion of predictors via fixed slopes{p_end}
{p2col:{cmd:r(R2_f3_Total)}}proportion of total outcome variance explained by the level-3 portion of predictors via fixed slopes{p_end}
{p2col:{cmd:r(R2_f4_Total)}}proportion of total outcome variance explained by the level-4 portion of predictors via fixed slopes{p_end}
{p2col:{cmd:r(R2_f5_Total)}}proportion of total outcome variance explained by the level-5 portion of predictors via fixed slopes{p_end}
{p2col:{cmd:r(R2_f_Total)}}proportion of total outcome variance explained by all predictors via fixed slopes{p_end}
{p2col:{cmd:r(R2_v12_Total)}}proportion of total outcome variance explained by the level-1 portion of predictors via level-2 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v22_Total)}}proportion of total outcome variance explained by the level-2 portion of predictors via level-2 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(R2_v32_Total)}}proportion of total outcome variance explained by the level-3 portion of predictors via level-2 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(R2_v42_Total)}}proportion of total outcome variance explained by the level-4 portion of predictors via level-2 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(R2_v52_Total)}}proportion of total outcome variance explained by the level-5 portion of predictors via level-2 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(R2_v2_Total)}}proportion of total outcome variance explained by all predictors via level-2 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v13_Total)}}proportion of total outcome variance explained by the level-1 portion of predictors via level-3 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v23_Total)}}proportion of total outcome variance explained by the level-2 portion of predictors via level-3 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v33_Total)}}proportion of total outcome variance explained by the level-3 portion of predictors via level-3 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(R2_v43_Total)}}proportion of total outcome variance explained by the level-4 portion of predictors via level-3 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(R2_v53_Total)}}proportion of total outcome variance explained by the level-5 portion of predictors via level-3 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(R2_v3_Total)}}proportion of total outcome variance explained by all predictors via level-3 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v14_Total)}}proportion of total outcome variance explained by the level-1 portion of predictors via level-4 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v24_Total)}}proportion of total outcome variance explained by the level-2 portion of predictors via level-4 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v34_Total)}}proportion of total outcome variance explained by the level-3 portion of predictors via level-4 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v44_Total)}}proportion of total outcome variance explained by the level-4 portion of predictors via level-4 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(R2_v54_Total)}}proportion of total outcome variance explained by the level-5 portion of predictors via level-4 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(R2_v4_Total)}}proportion of total outcome variance explained by all predictors via level-4 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v15_Total)}}proportion of total outcome variance explained by the level-1 portion of predictors via level-5 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v25_Total)}}proportion of total outcome variance explained by the level-2 portion of predictors via level-5 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v35_Total)}}proportion of total outcome variance explained by the level-3 portion of predictors via level-5 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v45_Total)}}proportion of total outcome variance explained by the level-4 portion of predictors via level-5 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v55_Total)}}proportion of total outcome variance explained by the level-5 portion of predictors via level-5 random slope (co)variation (when {opt c:wc} is not specified){p_end}
{p2col:{cmd:r(R2_v5_Total)}}proportion of total outcome variance explained by all predictors via level-5 random slope (co)variation{p_end}
{p2col:{cmd:r(R2_v_Total)}}proportion of total outcome variance explained by all predictors via random slope (co)variation{p_end}
{p2col:{cmd:r(R2_m2_Total)}}proportion of total outcome variance explained by level-2 outcome means via level-2 random intercept variation{p_end}
{p2col:{cmd:r(R2_m3_Total)}}proportion of total outcome variance explained by level-3 outcome means via level-3 random intercept variation{p_end}
{p2col:{cmd:r(R2_m4_Total)}}proportion of total outcome variance explained by level-4 outcome means via level-4 random intercept variation{p_end}
{p2col:{cmd:r(R2_m5_Total)}}proportion of total outcome variance explained by level-5 outcome means via level-5 random intercept variation{p_end}
{p2col:{cmd:r(R2_m_Total)}}proportion of total outcome variance explained by all outcome means via random intercept variation{p_end}
{p2col:{cmd:r(R2_fv_Total)}}proportion of total outcome variance explained by all predictors via fixed slopes and all random slope (co)variation{p_end}
{p2col:{cmd:r(R2_fvm_Total)}}proportion of total outcome variance explained by the whole model{p_end}
{p2col:{cmd:r(Resid_Total)}}proportion of total outcome variance explained by level-1 residuals (i.e., proportion of unexplained variance){p_end}
{p2col:{cmd:r(R2_L1_Total)}}proportion of total outcome variance explained by level-1 sources{p_end}
{p2col:{cmd:r(R2_L2_Total)}}proportion of total outcome variance explained by level-2 sources{p_end}
{p2col:{cmd:r(R2_L3_Total)}}proportion of total outcome variance explained by level-3 sources{p_end}
{p2col:{cmd:r(R2_L4_Total)}}proportion of total outcome variance explained by level-4 sources{p_end}
{p2col:{cmd:r(R2_L5_Total)}}proportion of total outcome variance explained by level-5 sources{p_end}

{pstd}Matrices{p_end}
{p2colset 7 30 31 0}{...}
{p2col:{cmd:r(R2)}}matrix containing each of the r-squared measures{p_end}

{pstd}Note that results regarding levels above the highest level in the estimated model will not be stored (e.g., {cmd:r(R2_f5_Total)} will not be stored if the estimated model has fewer than 5 levels).{p_end}


{marker author}{...}
{title:Author}

{pstd}Anthony J. Gambino, University of Connecticut, anthony.gambino@uconn.edu


{marker references}{...}
{title:References}

{pstd}Rights, J. D. 2023. Aberrant distortion of variance components in multilevel models under conflation of level-specific effects. {it:Psychological Methods}, 28: 1154–1177.{p_end}

{pstd}Rights, J. D., and S. K. Sterba. 2019. Quantifying explained variance in multilevel models: An integrative framework for defining R-squared measures. {it:Psychological Methods}, 24: 309–338. {p_end}

{pstd}Rights, J. D., and S. K. Sterba. 2021. Effect size measures for longitudinal growth analyses: Extending a framework of multilevel model r-squareds to accommodate heteroscedasticity, autocorrelation, nonlinearity, and alternative centering strategies. {it:New Directions for Child and Adolescent Development}, 2021: 65–110.{p_end}

{pstd}Rights, J. D., and S. K. Sterba. 2023a. On the common but problematic specification of conflated random slopes in multilevel models. {it:Multivariate Behavioral Research}: 1–28.{p_end}

{pstd}Rights, J. D., and S. K. Sterba. 2023b. R-squared measures for multilevel models with three or more levels. {it:Multivariate Behavioral Research}, 58: 340–367.{p_end}

