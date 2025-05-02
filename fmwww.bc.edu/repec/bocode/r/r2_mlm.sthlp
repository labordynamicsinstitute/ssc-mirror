{smcl}
{viewerjumpto "Syntax" "r2_mlm##syntax"}{...}
{viewerjumpto "Description" "r2_mlm##description"}{...}
{viewerjumpto "Examples" "r2_mlm##examples"}{...}
{viewerjumpto "Stored Results" "r2_mlm##stored"}{...}
{viewerjumpto "Author" "r2_mlm##author"}{...}
{viewerjumpto "References" "r2_mlm##references"}{...}
{p2col:{cmd:r2_mlm} {c -}{c -} a postestimation command that computes r-squared measures for models estimated by {cmd:mixed}}

{marker syntax}{...}
{title:Syntax}

{p 7}{cmd:r2_mlm}

{marker description}{...}
{title:Description}

{pstd}{cmd:r2_mlm} produces r-squared measures for models estimated by {cmd:mixed}.  Using the Rights and Sterba (2019; 2021; 2023b) framework for decomposing the total model-implied outcome variance from a linear mixed model into its sources, {cmd:r2_mlm} computes measures of the proportion of explained variance attributable to each (or combinations) of those sources (e.g., level-1 portion of predictors via fixed slopes).  {cmd:r2_mlm} can be used as a postestimation command with any set of estimation results from {cmd:mixed} except for results from cross-classified models and/or models with more than 5 levels.  {cmd:r2_mlm} also assesses whether the model's fixed and random effects may be subject to conflation bias.  If {cmd:r2_mlm} detects any predictors at risk of having conflated fixed or random effects, the output will contain warning messages detailing which predictors are at risk.  These warning messages are to aid the user in avoiding conflation bias in the r-squared measures (Rights, 2023; Rights & Sterba, 2023a).


{marker examples}{...}
{title:Examples}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse nlswork}

{pstd}Random-intercept and random-slope (coefficient) model, correlated random effects{p_end}
{phang2}{cmd:. mixed ln_w grade age c.age#c.age ttl_exp tenure c.tenure#c.tenure || id: tenure, cov(unstruct)}

{pstd}Using r2_mlm to compute r-squared measures for the estimated model{p_end}
{phang2}{cmd:. r2_mlm}

{pstd}Note that every predictor except grade contains both level-1 and level-2 variation, and none of those predictors have their contextual effects accounted for (i.e., their corresponding cluster mean variables are not included as predictors), so {cmd:r2_mlm} produces warning messages about these predictors because they are all at risk of having their fixed and random effects biased by conflation.{p_end}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse pig}

{pstd}Two-level model{p_end}
{phang2}{cmd:. mixed weight week || id:}

{pstd}Using r2_mlm to compute r-squared measures for the estimated model{p_end}
{phang2}{cmd:. r2_mlm}

{pstd}Note that week has no variation across the id clusters, so {cmd:r2_mlm} produces no warning message because there is no risk of week's fixed effect being biased by conflation.{p_end}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse productivity}

{pstd}Three-level nested random interactions model with ANOVA DF{p_end}
{phang2}{cmd:. mixed gsp private emp hwy water other unemp || region:water || state:other, dfmethod(anova)}

{pstd}Using r2_mlm to compute r-squared measures for the estimated model{p_end}
{phang2}{cmd:. r2_mlm}

{pstd}Note that every predictor in this model contains level-1, level-2, and level-3 variation, and no contextual effects have been accounted for, so {cmd:r2_mlm} produces warning messages about the predictors because they are all at risk of having their fixed and random effects biased by conflation.{p_end}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse ovary}

{pstd}Linear mixed model with MA 2 errors{p_end}
{phang2}{cmd:. mixed follicles sin1 cos1 || mare: sin1, residuals(ma 2, t(time))}

{pstd}Using r2_mlm to compute r-squared measures for the estimated model{p_end}
{phang2}{cmd:. r2_mlm}

{pstd}Note that there is a warning message for cos1 but not for sin1.  This is because the level-2 variance of sin1 is so small that it's basically zero (it's less than 10^-10), meaning that there is basically no risk of its fixed or random effect being biased by conflation.  Conversely, the level-2 variance of cos1 is technically nonzero (it's about 0.00003) and its level-2 cluster means have not been included in the model as a predictor, so there is technically a risk of its fixed effect being biased by conflation.  However, considering the level-1 variance of cos1 (about 0.51) is many magnitudes larger than its level-2 variance, there is probably very little risk of conflation bias, and this warning message can be ignored.{p_end}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse childweight}

{pstd}Linear mixed model with heteroskedastic error variances{p_end}
{phang2}{cmd:. mixed weight age || id:age, residuals(independent, by(girl))}

{pstd}Using r2_mlm to compute r-squared measures for the estimated model{p_end}
{phang2}{cmd:. r2_mlm}

    {hline}


{marker stored}{...}
{title:Stored Results}

{pstd}{cmd:r2_mlm} stores the following in {cmd:r()}:

{pstd}Scalars{p_end}
{p2colset 7 30 31 0}{...}
{p2col:{cmd:r(Var_{it:l})}}estimate of level-{it:l} model-implied outcome variance{p_end}
{p2col:{cmd:r(Var_t)}}estimate of total model-implied outcome variance{p_end}
{p2col:{cmd:r(r2L{it:l}_t)}}proportion of total outcome variance explained by level-{it:l} sources{p_end}
{p2col:{cmd:r(r2f{it:l}_{it:l})}}proportion of level-{it:l} outcome variance explained by the level-{it:l} portion of predictors via fixed slopes{p_end}
{p2col:{cmd:r(r2v{it:lq}_{it:l})}}proportion of level-{it:l} outcome variance explained by the level-{it:l} portion of predictors via level-{it:q} random slope (co)variation{p_end}
{p2col:{cmd:r(resid_1)}}proportion of level-1 outcome variance explained by the level-1 residuals (i.e., proportion of unexplained level-1 variance){p_end}
{p2col:{cmd:r(r2m{it:q}_{it:q})}}proportion of level-{it:q} outcome variance explained by level-{it:q} outcome means via level-{it:q} random intercept variation{p_end}
{p2col:{cmd:r(r2f{it:l}_t)}}proportion of total outcome variance explained by the level-{it:l} portion of predictors via fixed slopes{p_end}
{p2col:{cmd:r(r2v{it:lq}_t)}}proportion of total outcome variance explained by the level-{it:l} portion of predictors via level-{it:q} random slope (co)variation{p_end}
{p2col:{cmd:r(r2v{it:q}_t)}}proportion of total outcome variance explained by all predictors via level-{it:q} random slope (co)variation{p_end}
{p2col:{cmd:r(r2m{it:q}_t)}}proportion of total outcome variance explained by level-{it:q} outcome means via level-{it:q} random intercept variation{p_end}
{p2col:{cmd:r(r2f_t)}}proportion of total outcome variance explained by all predictors via fixed slopes{p_end}
{p2col:{cmd:r(r2v_t)}}proportion of total outcome variance explained by all predictors via random slope (co)variation{p_end}
{p2col:{cmd:r(r2m_t)}}proportion of total outcome variance explained by all outcome means via random intercept variation{p_end}
{p2col:{cmd:r(r2fv_t)}}proportion of total outcome variance explained by all predictors via fixed slopes and all random slope (co)variation{p_end}
{p2col:{cmd:r(r2fvm_t)}}proportion of total outcome variance explained by the whole model{p_end}
{p2col:{cmd:r(resid_t)}}proportion of total outcome variance explained by level-1 residuals (i.e., proportion of unexplained variance){p_end}

{pstd}Matrices{p_end}
{p2colset 7 30 31 0}{...}
{p2col:{cmd:r(R2)}}matrix containing each of the r-squared measures{p_end}

{pstd}For the returned scalars, 1 ≤ {it:l} ≤ {it:L} and 2 ≤ {it:q} ≤ {it:L}, where {it:L} is the number of levels in the model.{p_end}


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

