{smcl}
{* *! version 1.0 20240927}{...}
{p2colset 1 25 27 2}{...}
{p2col:{bf:mi impute from} {hline 2}}Impute using an external imputation model{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 19 2}{cmd:mi} {cmdab:imp:ute} {cmdab:from} 
{it:ivar} [{it:{help if}}]
[{cmd:,}  {it:options}] 

{synoptset 22 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Main}
{synopt: {cmd:b(}matname{cmd:)}} vector of regression coefficients used to impute {p_end}
{synopt: {cmd:v(}matname{cmd:)}} corresponding matrix of variance/covariances used to impute {p_end}
{synopt: {cmd:qreg}} quantile regression model for the quantitative variable {it:ivar} {p_end}
{synopt: {cmd:mlogit}} multinomial logistic regression model for the categorical variable {it:ivar} {p_end}
{synopt: {cmd:logit}} logistic regression model for the binary variable {it:ivar} {p_end}

{synoptline}
{p 4 6 2}
You must {cmd:mi set} your data before using {cmd:mi} {cmd:impute} {cmd:from};
see {manhelp mi_set MI:mi set}. Factor variables in {it:{help indepvars}} are not allowed. {p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:mi} {cmd:impute} {cmd:from} fills in missing values using an estimated imputation model estimated in one or multiple studies. 
A quantitative missing variable can be imputed passing the estimates of 99 (q=0.01(.01).99) linear predictors of quantile regression models.
A categorical missing variable with {it:k} levels can be imputed passing {it:k} linear predictors of multinomial logistic regression models.
A binary (0/1) missing variable can be imputed passing the linear predictors of logistic regression models. 
The command assumes that variables used in the imputation model are available in the current data. 
The {helpb mi_impute_from_get:mi_impute_from_get} is reading the files containing the estimated models, estimate a weighted inverse variance least square model to combine regression coefficients of the imputation model across studies, and formatting matrices to be passed to {cmd:mi} {cmd:impute} {cmd:from}.

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{cmd:b(}matname{cmd:)} specifies a vector of regression coefficients for the imputation model to be used for {it:ivar}.

{phang}
{cmd:v(}matname{cmd:)} specifies a matrix of variance/covariances for the imputation model to be used for {it:ivar}.

{phang}
{cmd:qreg} specifies that the matrix {cmd:b(}matname{cmd:)} contains 99 (q=0.01(.01)0.99) linear predictors of the quantitative variable {it:ivar} to be imputed.

{phang}
{cmd:mlogit} the imputation model is a multinomial logistic regression model for the categorical variable {it:ivar}.

{phang}
{cmd:logit} the imputation model is a logistic regression model for the binary variable {it:ivar}.

{phang}
{cmd:add()}, {cmd:replace}, {cmd:rseed()}, {cmd:double}; see
{manhelp mi_impute MI:mi impute}.

{marker example}{...}
{title:Example #1: Quantitative variable 100% missing}
			
	{stata "use http://www.stats4life.se/data/from/qreg_study_1, clear"}

	{stata "mi set wide"}
	{stata "mi register imputed z"}

	// Get imputation model from one study (tab delimited .txt)

	{stata "mi_impute_from_get , b(e_qreg_b_s2) v(e_qreg_v_s2) colnames(y x c _cons) imodel(qreg) path(http://www.stats4life.se/data/from/)"}
		
	{stata "mat ib = r(get_ib)"}
	{stata "mat iV = r(get_iV)"}

	{stata "mi impute from z , add(10) b(ib) v(iV) imodel(qreg)"}
	{stata "mi estimate, post eform imp(1/10): logit y x c z"}

	// Get imputation model from 4 different studies

	{stata "mi_impute_from_get , b(e_qreg_b_s2 e_qreg_b_s3 e_qreg_b_s4 e_qreg_b_s5) v(e_qreg_v_s2 e_qreg_v_s3 e_qreg_v_s4 e_qreg_v_s5) colnames(y x c _cons) imodel(qreg) path(http://www.stats4life.se/data/from/)"}
			
	{stata "mat ib = r(get_ib)"}
	{stata "mat iV = r(get_iV)"}

	{stata "mi impute from z , add(10) b(ib) v(iV) imodel(qreg)"}
	{stata "mi estimate, post eform imp(11/20): logit y x c z"}

{title:Example #2: Categorical variable 100% missing}

	{stata "use http://www.stats4life.se/data/from/study_mlogit, clear"}

	{stata "mi set wide"}
	{stata "mi register imputed z"}

	// Get imputation model from one study (tab delimited .txt)

	{stata "mi_impute_from_get , b(e_mlogit_b_s2) v(e_mlogit_v_s2) values(0 1 2 3)  colnames(y x c _cons) imodel(mlogit) path(http://www.stats4life.se/data/from/)"}
			
	{stata "mat ib = r(get_ib)"}
	{stata "mat iV = r(get_iV)"}

	{stata "mi impute from z , add(10) b(ib) v(iV) imodel(mlogit)"}
	{stata "mi estimate, post eform imp(1/10): logit y x c z"}

	// Get imputation model from 4 different studies

{stata "mi_impute_from_get , b(e_mlogit_b_s2 e_mlogit_b_s3 e_mlogit_b_s4 e_mlogit_b_s5) v(e_mlogit_v_s2 e_mlogit_v_s3 e_mlogit_v_s4 e_mlogit_v_s5) colnames(y x c _cons) imodel(mlogit) path(http://www.stats4life.se/data/from/) values(0 1 2 3)"}
			
	{stata "mat ib = r(get_ib)"}
	{stata "mat iV = r(get_iV)"}

	{stata "mi impute from z , add(10) b(ib) v(iV) imodel(mlogit)"}
	{stata "mi estimate, post eform imp(11/20): logit y x c z"}

	{title:Example #3: Binary variable 100% missing}

	{stata "use http://www.stats4life.se/data/from/study_logit, clear"}

	{stata "mi set wide"}
	{stata "mi register imputed z"}

	// Get imputation model from one study (tab delimited .txt)

	{stata "mi_impute_from_get , b(e_logit_b_s2) v(e_logit_v_s2) colnames(y x c _cons) imodel(logit) path(http://www.stats4life.se/data/from/)"}
			
	{stata "mat ib = r(get_ib)"}
	{stata "mat iV = r(get_iV)"}

	{stata "mi impute from z , add(10) b(ib) v(iV) imodel(logit)"}
	{stata "mi estimate, post eform imp(1/10): logit y x c z"}

	// Get imputation model from 4 different studies

{stata "mi_impute_from_get , b(e_logit_b_s2 e_logit_b_s3 e_logit_b_s4 e_logit_b_s5) v(e_logit_v_s2 e_logit_v_s3 e_logit_v_s4 e_logit_v_s5) colnames(y x c _cons) imodel(logit) path(http://www.stats4life.se/data/from/)"}
			
	{stata "mat ib = r(get_ib)"}
	{stata "mat iV = r(get_iV)"}

	{stata "mi impute from z , add(10) b(ib) v(iV) imodel(logit)"}
	{stata "mi estimate, post eform imp(11/20): logit y x c z"}
	
{title:Reference}

{p 4 8 2} Thiesmeier R., Bottai M, Orsini N. 2024. Systematically missing data in distributed research networks: multiple imputation when data cannot be pooled. {it:Journal of Statistical Computation and Simulation}.
{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:mi impute from} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:r(M)}}total number of imputations{p_end}
{synopt:{cmd:r(N)}}total number of observations{p_end}
{synopt:{cmd:r(N_incomplete)}}total number of missing observations{p_end}
{synopt:{cmd:r(M_add)}}number of added imputations{p_end}
{synopt:{cmd:r(M_update)}}number of updated imputations{p_end}
{synopt:{cmd:r(k_ivars)}}number of imputed variables (always {cmd:1}){p_end}

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:r(method)}}name of imputation method ({cmd:from}){p_end}
{synopt:{cmd:r(ivars)}}name of imputation variable{p_end}
{synopt:{cmd:r(rngstate)}}random-number state used{p_end}

