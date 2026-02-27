Description
	Metaplot is a novel graphical approach that gives a quick and easy indication of the studies responsible for the extreme heterogeneity across studies. 
	Metaplot is based on the ‘one-out’ sensitivity analysis according to the sequential and combinatorial algorithm. 
	Metaplot tells us to what extent the omission of a particular study may reduce the overall heterogeneity based on the I2 and χ2 statistics. 
	Metaplot has no limitations regarding the number of studies or types of outcome data (binomial or continuous data).

Data formats
	The 'metaplot' command is flexible and works with any measurement option including binary data (a b c d or effect size + standard error or effect size + confidence intervals)
	and continuous data (sample + mean + standard deviation). 

Details
	The full form of the 'metaplot' command is as follows:
	metaplot varlist [if] [in] [, id(study)]
	where 
	• "varlist" can be "a b c d" or "lnes se" or "es lles ules" or "n1 mean1 sd1 n0 mean0 sd0"
	•"id(study)" option displays studies identifications (the first authors and the year of publication) specified by the variable "study" in the dataset.
	
	The abbreviations in the above command represent the following terms.
	• "a b c d" represents "events" and "non-events" in the intervention (exposure) and control groups, respectively.
	• "lnes" represents Naperian logarithm of the effect size that may be risk ratio (lnrr) or odds ratio (lnor).
	• "se" represents the standard error of the effect size.
	• "es" represents the effect size that may be risk ratio (rr) or odds ratio (or).
	• "lles" represents the lower limit of the confidence interval for the effect size.
	• "ules" represents the upper limit of the confidence interval for the effect size.
	• "n1" and "n0" represent the sample size for the intervention (exposure) and control groups, respectively.
	• "mean1" and "mean0" represent the mean for the intervention (exposure) and control groups, respectively.
	• "sd1" and "sd0" represent the standard deviation for the intervention (exposure) and control groups, respectively.

Examples
	metaplot lnor se, id(study)
	metaplot es lles rules, id(study)
	metaplot n1 mean1 sd1 n0 mean0 sd0, id(study)

References
	1. Poorolajal J, Noornejad S. Metaplot: A new Stata module for assessing heterogeneity in a meta-analysis. Plos One. 2021; 16:e0253341.	
	
	2. Poorolajal J, Fotouhi A, Majdzadeh R, Mahmoodi M. MetaPlot: a novel Stata graph for assessing heterogeneity at a glance. Iran J Public Health. 2010; 39:102-4.
	
	3. Patsopoulos NA, Evangelou E, Ioannidis JPA. Sensitivity of between-study heterogeneity in meta-analysis: proposed metrics and empirical evaluation. Int J Epidemiol. 2008; 37:1148-57

Author
	Jalal Poorolajal
	Department of Epidemiology, School of Public Health, Hamadan University of Medical Sciences, Hamadan, Iran
	email: poorolajal@umsha.ac.ir

