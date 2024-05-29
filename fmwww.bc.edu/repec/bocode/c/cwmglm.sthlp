{smcl}
{* 24oct2023}{...}
{hline}
help {hi:cwmglm}

{title:Title}
{cmd:cwmglm} - Cluster Weighted Model for Generalized Linear Models

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmd:cwmglm} {it:{help varname:depvar indepvars}} {ifin}, {cmdab:post:erior(stub)} [{cmd: start({it:svmethod)} k(#)} {cmdab:iter:ate(#)} {help cwmglm##xnormal_opts:{it:xnormal_opts}} {cmdab:xn:ormal(varlist)} {cmdab:xpoi:sson(varlist)} {cmdab:xbin:omial(varlist)} {cmdab:xmult:inomial(varlist)} {cmdab:nd:raw(#)} {cmdab:iteratex:norm(#)}  {cmdab:conv:crit(#)} {cmd:nolog} {cmdab:nocl:ustertable} {cmdab:nodev:iance} {cmdab:nomar:ginal} {cmdab:noregt:able}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main Options}
{synopt:{opt k(#)}} the number of mixture components. Default is 2. {p_end}

{syntab:Marginalization Options}
{synopt:{opt xnormal}({help varname:varlist})} normal covariates (marginal distribution)  {p_end}
{synopt:{opt xbinomial}({help varname:varlist})} binomial covariates (marginal distribution)  {p_end}
{synopt:{opt xmultinomial}({help varname:varlist})} multinomial covariates (marginal distribution)  {p_end}
{synopt:{opt xpoisson}({help varname:varlist})} xpoisson covariates (marginal distribution)  {p_end}
{synopt:{opt xnormal_opts}} parsimonious models for multivariate normal covariates. The possible options are eii, vii, eei, vei, evi, vvi, eee, vee, eve, vve, eev, vev, evv and vvv  {p_end}

{syntab:Regression Options}
{synopt:{opt family}({it:familyname})}  Family for the GLM. The allowed families are {it: gaussian, poisson} and {it: binomial}{p_end}

{syntab:Initialization}
{synopt:{opt start}({it:svmethod})}  set the initialization method. Allowed methods are {it: kmeans}, {it: randomid}, {it: randompr} {p_end}
{synopt:{opt initial}({help varname:varlist})} starting values of class membership. Applies only if start({it: custom}) is specified {p_end}

{syntab:Maximization options}
{synopt:{opt iterate(#)}} the number of iterations of the EM algorithm {p_end}
{synopt:{opt iteratexnorm(#)}} the number of iterations for the maximization of parsimonious models {p_end}
{synopt:{opt convcrit(#)}} the stopping criterion for the Aitken acceleration. (Default 1e-5)  {p_end}

{syntab:Display options}
{synopt:{opt nlog}} supresses iteration log {p_end}
{synopt:{opt noclustertable}} requests {cmd: cwmglm} not to display the clustering table  {p_end}
{synopt:{opt nodeviance}} requests {cmd: cwmglm} not to display the deviance measures {p_end}
{synopt:{opt nomarginal}} requests {cmd: cwmglm} not to display the parameters of the marginal distributions {p_end}
{synopt:{opt noregtable}} requests {cmd: cwmglm} not to display the regression table  {p_end}


{synoptline}
{p2colreset}{...}
{p 4 6 2}{it:indepvars} may contain factor variable operators; see {help fvvarlist}.{p_end}
{marker weight}{...}
{p 4 6 2} See {cmd: cwmglm postestimation} for features available after estimation. {p_end}


{title:Description}

{cmd:cwmglm} estimates mixtures of regression models with random covariates through maximum likelihood and expectation-maximization algorithm. 


{title:Options}
{synoptset 30 tabbed}{...}
{dlgtab:Main  options}

{synopt: {opt k(#)}} the number of mixture components. Default is 2 ,  the mimimum is 1. {p_end}

{dlgtab:Marginalization options}

{synopt: {opt xnormal(varlist)}}      variables having normal distributions {p_end}
{synopt: {opt xpoisson(varlist)}}     variables having poisson distributions {p_end}
{synopt: {opt xbinomial(varlist)}}    variables having binomial distributions. This options only accepts {0,1} binary variables. {p_end}
{synopt: {opt xmultinomial(varlist)}} variables having multinomial distributions. Factor variable syntax is not allowed. Categories are detected automatically. {p_end}
{synopt: {it: xnormal_opts}} indicates the parsimonious model to be fitted in {opt xnormal(varlist)} (see {help cwmglm##refrlink:Celeux and Govaert, 1995}) . If the number of variables in {opt xnormal(varlist)} is equal to one the possibile options are {opt eee} and {opt vvv}. Default is {opt vvv}. The possible multivariate normal models are the following{p_end}
{marker xnormal_opts}{...} 

{synopt: {opt eii}} Equal volume, spherical shape {p_end}
{synopt: {opt vii}} Variable volume, spherical shape {p_end}
{synopt: {opt eei}} Equal volume, equal shape, axis-aligned orientation {p_end}
{synopt: {opt vei}} Variable volume, equal shape, axis-aligned orientation {p_end}
{synopt: {opt evi}} Equal volume, variable shape, axis-aligned orientation {p_end}
{synopt: {opt vvi}} Variable volume, variable shape, axis-aligned orientation {p_end}
{synopt: {opt eee}} Equal volume, equal shape, equal orientation {p_end}
{synopt: {opt vee}} Variable volume, equal shape, equal orientation {p_end}
{synopt: {opt eve}} Equal volume, variable shape, equal orientation {p_end}
{synopt: {opt vve}} Variable volume, variable shape, equal orientation {p_end}
{synopt: {opt eev}} Equal volume, equal shape, variable orientation {p_end}
{synopt: {opt vev}} Variable volume, equal shape, variable orientation {p_end}
{synopt: {opt evv}} Equal volume, variable shape, variable orientation {p_end}
{synopt: {opt vvv}} Variable volume, variable shape, variable orientation {p_end}

{dlgtab:Regression options}

{synopt: {opt family(familyname)}} specifies the distribution of {help varname:depvar} for the GLM (see {help glm}). {cmd:family(gaussian}{cmd:)} (link indentity) is the default. The other allowed distributions are {cmd:family(binomial}{cmd:)} (link logit) and {cmd:family(poisson}{cmd:)} (link log).   {p_end}

{dlgtab:Initialization options}
{synopt: {opt start(svmethod)}} Specifies the initialization procedure of the component membership probabilities or the component memberships.  {p_end}
{synopt: {opt ndraws(#)}} specifies the number of random draws for selecting the starting values if {opt start(randompr)} or {opt start(randomid)} are specified. Starting values are selected if they have the highest log-likelihood value from the EM iterations. Default is 10. {p_end}
{phang2}
{opt start(kmeans)} specifies that starting values are computed by assigning each
observation to an initial latent class that is determined by running a {opt kmeans} cluster analysis on {it:{help varname:depvar indepvars}}.  This is the default.  {p_end}
{phang2}
{opt start(randomid)} specifies that starting values are computed by randomly assigning
observations to initial classes.  {p_end}
{phang2}
{opt start(randompr)} specifies that starting values are computed by randomly assigning initial class probabilities.  {p_end}
{phang2}
{opt start(custom)} specifies that starting values are provided by the user.  {p_end}
{phang2}
{opt initial(varlist)} starting values of class memberhsip. varlist must contain a list of k numeric variables. This option is ignored if   {opt start(custom)} is not specified. {p_end}
{dlgtab:Maximization options}

{synopt: {opt iterate(#)}} the number of EM iterations. Default is 1200 {p_end}
{synopt: {opt iteratexnorm(#)}} the number of iterations for the parisimonious models (see {cmd: xnorm(varlist)} and {help cwmglm##xnormal_opts:{it:xnormal_opts}} options). It affects only the estimations of vee, eve, vve, vev and vei models. Default is 200 {p_end}
{synopt: {opt convcrit(#)}} the stopping criterion for the Aitken acceleration procedure. Default threshold is 1e-5. {p_end}

{dlgtab:Display options}

{synopt:{opt nlog}} supresses iteration log {p_end}
{synopt:{opt noclustertable}} requests {cmd: cwmglm} not to display the clustering table  {p_end}
{synopt:{opt nodeviance}} requests {cmd: cwmglm} not to display the deviance measures {p_end}
{synopt:{opt nomarginal}} requests {cmd: cwmglm} not to display the parameters of the marginal distributions {p_end}
{synopt:{opt noregtable}} requests {cmd: cwmglm} not to display the regression table  {p_end}


{title:Saved Results}

{synoptset 15 tabbed}{...}
{phang2}{p_end}
{p2col 5 11 15 2:Scalars}{p_end}
{synopt:{cmd:e(k)}} Number components {p_end}
{synopt:{cmd:e(N)}} the number of observations {p_end}
{synopt:{cmd:e(df_r)}} the number of estimated parameters {p_end}
{synopt:{cmd:e(ll)}} log likelihood {p_end}
{synopt:{cmd:e(bic)}} Bayesian information criterion (BIC)  {p_end}
{synopt:{cmd:e(aic)}} Akaike information criterion (AIC) {p_end}
{synopt:{cmd:e(nmulti)}} Number of multinomial concomitant {p_end}

 
{synoptset 15 tabbed}{...}
{phang2}{p_end}
{p2col 5 11 15 2:Matrices}{p_end}
{synopt:{cmd:e(b)}} coefficient vector of the glm {p_end}
{synopt:{cmd:e(V)}} variance-covariance matrix of the glm{p_end}
{synopt:{cmd:e(phi0)}} dispersion parameter for the glm (see {cmd: help glm}) {p_end}
{synopt:{cmd:e(cl_table)}}  estimated group size {p_end}
{synopt:{cmd:e(localdeviance)}}  within deviance decomposition matrix for the glm{p_end}
{synopt:{cmd:e(globaldeviance)}}   the overall residual deviance, the overall explained deviance, the between deviance and the total deviance {p_end}
{synopt:{cmd:e(R2)}}  generalized coefficients of determination for the GLM {p_end}
{synopt:{cmd:e(prior)}} mixture components weights{p_end}
{synopt:{cmd:e(p_multi_#)}} probabilities of a each outcome for the {cmd: xmultinomial} variables . (returns n matrices where n is the number of multinomial variables) {p_end}
{synopt:{cmd:e(p_binomial)}} probabilities of a positive outcome for the {cmd: xbinomial} variables {p_end}
{synopt:{cmd:e(lambda)}} mean of the {cmd: xpoisson} variables{p_end}
{synopt:{cmd:e(mu)}} mean of the {cmd: xnorm} variables{p_end}
{synopt:{cmd:e(epsilon)}} variance-covariance matrices of the {cmd: xnorm} variables{p_end}
{synopt:{cmd:e(ic)}}  AIC and BIC {p_end}

{synoptset 15 tabbed}{...}
{phang2}{p_end}
{p2col 5 11 15 2:Macros}{p_end}
{synopt:{cmd:e(sample)}} marks estimation sample{p_end}
{synopt:{cmd:e(depvar)}} the dependent variable  {p_end}
{synopt:{cmd:e(indepvars)}} list of covariates for the regression model {p_end}
{synopt:{cmd:e(cmd)}} {cmd:cwmglm} {p_end}
{synopt:{cmd:e(xnorm)}} the variables with normal marginalization {p_end}
{synopt:{cmd:e(xnormodel)}} the parsimonious model used for the  normal marginalization {p_end}
{synopt:{cmd:e(xpoisson)}} the variables with poisson marginalization {p_end}
{synopt:{cmd:e(xbinomial)}} the variables with binomial marginalization {p_end}
{synopt:{cmd:e(xmultinomial)}} the variables with multinomial marginalization {p_end}
{synopt:{cmd:e(glmcmd)}} the command used for the glm {p_end}



{synoptset 15 tabbed}{...}
{phang2}{p_end}
{p2col 5 11 15 2:Function}{p_end}
{synopt:{cmd:e(sample)}} marks estmations sample {p_end}


{title:Examples}

{pstd}Setup{p_end}

{phang2}{cmd: . use covid, clear}

{phang2}{cmd: . describe}

{pstd}Mixture of Poisson GLM with random covariates (k=2){p_end}

{phang2}{cmd: . cwmglm y x1 x2 x3 n1 female, xnormal(x1 x2 x3) vvv xpoisson(n1) xbin(female) k(2)  family(poisson)}

{hline}

{pstd}Setup{p_end}

{phang2} {cmd:. use students, clear}    

{phang2} {cmd:. describe}    


{pstd}Mixture of regressions with random covariates, model EEE{p_end}
{phang2} {cmd:. cwmglm weight height heightf,  k(2)  xnormal(height heightf) eee  }

{hline}

{pstd}Setup{p_end}

{phang2} {cmd:. use multinorm, clear}

{pstd} Preparing the loop for information criteria model selection {p_end}

{phang2} {cmd:. local models vev evv vvv eei vei evi vvi eii vii eee vee eve vve eev }

{phang2} {cmd:. global CWMs}

{pstd} Looping over different parsimonious multivariate normal models and letting k range from 2 to 5 {p_end}

{phang2} {cmd:. foreach model of local models {c -(}}

{phang3} {cmd:. forval i=2/5 {c -(}}

{phang3} {c 47}{c 47} note the absence of {it: depvar indepvars}

{phang3} {cmd:. quietly cwmglm, xnorm(x1 x2) k(`i') `model'}

{phang3}{space 4}{cmd:.if (e(converged)==1) {c -(}}

{phang3}{space 4}{cmd:.estimates store `model'`i' }

{phang3}{space 4}{cmd:.global CWMs $CWMs `model'`i'}

{phang3}{space 4} {cmd:. {c )-}}

{phang3}{space 4} {cmd:. else di in red "model `model' with `i' mixture component did not converge"}
		
{phang3}{space 2}{cmd:. {c )-}}

{phang2}{space 2}{cmd:. {c )-}}

{pstd} Model selection {p_end}

{phang2}{space 2}{cmd:. cwmcompare $CWMs}

{pstd} Activating the estimates from the best model {p_end}

{phang2}{space 2}{cmd:. estimates restore `r(bestAIC)' }
 


{title:References}
{marker refrlink}{...} 
Celeux, G., & Govaert, G. (1995). {browse "https://www.sciencedirect.com/science/article/pii/0031320394001256": Gaussian parsimonious clustering models. Pattern recognition}, 28(5), 781-793.


Ingrassia, S., Punzo, A., Vittadini, G., & Minotti, S. C. (2015). {browse "https://link.springer.com/article/10.1007/s00357-015-9177-z" :Erratum to: The generalized linear mixed cluster-weighted model}. Journal of Classification, 32(2), 327-355.

{title:Authors}

{phang} Daniele Spinelli, corresponding author (University of Milano-Bicocca, daniele.spinelli@unimib.it) {p_end}
{phang} Salvatore Ingrassia (University of Catania, s.ingrassia@unict.it) {p_end}
{phang} Giorgio Vittadini (University of Milano-Bicocca, giorgio.vittadinid@unimib.it) {p_end}




