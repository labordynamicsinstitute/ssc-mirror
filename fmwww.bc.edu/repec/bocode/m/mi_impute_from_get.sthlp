{smcl}
{* *! version 1.0 20240917}{...}
{p2colset 1 25 27 2}{...}
{p2col:{bf:mi_impute_from_get} {hline 2}}Read files and return matrices for external imputation model{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 19 2}{cmd:mi_impute_from_get} [{cmd:,}  {it:options}] 

{synoptset 30 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Main}
{synopt: {cmd:b(}filename [filename [...]]{cmd:)}} list of file names containing the regression coefficients of the imputation model {p_end}
{synopt: {cmd:v(}filename [filename [...]]{cmd:)}} list of file names containing the variance/covariances of the imputation model {p_end}
{synopt: {cmd:colnames(}string{cmd:)}} list of variable names included in the linear predictor of the imputation model {p_end}
{synopt: {cmd:tf(}string{cmd:)}} format of the files (either tab delimited .txt or excel .xlsx) {p_end}
{synopt: {cmd:imodel(}string{cmd:)}} type of imputation model (qreg, mlogit, logit) {p_end}
{synopt: {cmd:values(}numlist{cmd:)}} values taken by the categorical variable, if imodel(mlogit), to be imputed {p_end}
{synopt: {cmd:path(}string{cmd:)}} location of the files{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:mi_impute_from_get} faciliates the use of external imputation models by reading the files and formatting matrices to be passed to {helpb mi_impute_from: mi_impute_from}.
If multiple files are specified, {cmd:mi_impute_from_get} combines regression coefficients across files using an inverse-variance weighted 
least squares model.  
  
{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{cmd:b(}string{cmd:)} specifies a list of files containing the estimated regression coefficients for the imputation model for {it:ivar}.

{phang}
{cmd:v(}string{cmd:)} specifies a list of files containing the estimated variance/covariances of the regression coefficients for the imputation model for {it:ivar}.

{phang}
{cmd:colnames(}string{cmd:)} specifies list of variable names (including the constant _cons) included in the linear predictor of the imputation model. 

{phang}
{cmd:tf(}delimited|excel{cmd:)} format of the files (either tab delimited .txt or excel .xlsx) containing the estimated imputation model.
Adding the format (.txt, .xlsx) to each file name in b() and v() is not needed. The default format for all the files is tab delimited (.txt). 

{phang}
{cmd:imodel(}string{cmd:)} the type of imputation model (qreg, mlogit, logit) passed in b(). Of note, for a quantitative variable one has to pass the linear predictor for 99 (q=0.01(.01).99) quantiles of the imputation model. A loop can be used to combine all the estimated linear predictors in a single file. 
For a categorical  variable with {it:k} levels one has to pass {it:k} linear predictors of multinomial logistic regression models. The reference outcome level is recognized by the fact that all regression coefficients are equal to zero.

{phang}
{cmd:values(}numlist{cmd:)} specifies all the numerical values of the categorical variable to be imputed. This is needed when using imodel(mlogit) as imputation model. 

{phang}
{cmd:path(}string{cmd:)} specifies the location of the file names specified in options b() and v(). 

{marker example}{...}

{title:Example #1: Estimate 99 quantiles of the imputation model for a quantitative variable z}
			
{bf: * Export the estimates of imputation models based on quantile regression using Study #2, #3, #4, and #5}

quietly forv s = 2/5 {
	use http://www.stats4life.se/data/from/qreg_study_`s', clear
	qreg z y x c, q(1)
	mat ib = e(b)  
	mat iV = e(V)  
	forv i = 2/99 {
		qreg z y x c, q(`i')
		mat ib = ib , e(b)
		mata: iV = blockdiag(st_matrix("iV"), st_matrix("e(V)"))
		mata: st_matrix("iV", iV)
	}
	svmat ib 
	export delimited ib* using e_qreg_b_s`s'.txt in 1 , replace 
	svmat iV 
	export delimited iV* using e_qreg_v_s`s'.txt if iV1 != . , replace 
}

{bf: * Open the Study #1 with missing data on the quantitative variable z}

use http://www.stats4life.se/data/from/qreg_study_1, clear
mi set wide
mi register imputed z

{bf: * Read the imputation model from just Study #2}

mi_impute_from_get , b(e_qreg_b_s2) v(e_qreg_v_s2) ///
	colnames(y x c _cons) imodel(qreg) path(http://www.stats4life.se/data/from/)
	 
mat ib = r(get_ib)
mat iV = r(get_iV)

{bf: * External imputation using -mi impute from-}

mi impute from z , add(10) b(ib) v(iV) imodel(qreg)

{bf: * Read the imputation models from Study #2, #3, #4, and #5}

mi_impute_from_get , b(e_qreg_b_s2 e_qreg_b_s3 e_qreg_b_s4 e_qreg_b_s5) ///
				v(e_qreg_v_s2 e_qreg_v_s3 e_qreg_v_s4 e_qreg_v_s5) ///
				 colnames(y x c _cons) imodel(qreg)  ///
				 path(http://www.stats4life.se/data/from/)

mat ib = r(get_ib)
mat iV = r(get_iV)

{bf: * External imputation using -mi impute from-}

mi impute from z , add(10) b(ib) v(iV) imodel(qreg)

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:mi_impute_from_get} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:r(get_ib)}} regression coefficients for the imputation model{p_end}
{synopt:{cmd:r(get_iV)}} var/covariance of the regression coefficients for the imputation model{p_end}
