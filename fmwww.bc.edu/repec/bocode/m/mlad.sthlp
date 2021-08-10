{smcl}
{*      *! version 1.0 2021-02-06}{...}
{vieweralsosee "ml" "help ml"}{...}
{vieweralsosee "python" "help python"}{...}
{vieweralsosee "mlad utility functions" "help mlad_utility"}{...}

{hline}

{title:Title}

{p2colset 5 13 17 2}{...}
{p2col :{hi:mlad }{hline 2}}Maximum likelihood estimation with automatic differentiation using Python.{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 20 2}
{cmd:mlad} 
{it:{help mlad##eq:eq}}
[{it:{help mlad##eq:eq}} ...]
{ifin},
llfile(filename) 
[{it:model_options}]

{marker options}{...}
{synoptset 29 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt adtype(adtype)}}type of automatic differentiation to calculate hessian{p_end}
{synopt :{opt id(varname)}}name of id variable to pass to Python{p_end}
{synopt :{opt init(init)}}set initial values{p_end}
{synopt :{opt llfile(filename)}}filename of Python likelihood file{p_end}
{synopt :{opt nojit}}Do not invoke just in time compliation{p_end}
{synopt :{opt mat:rices(mat list)}}list of matrices to pass to Python{p_end}
{synopt :{opt mat:names(list)}}names of matrices in Python{p_end}
{synopt :{opt mlmeth:od(method)}}method of estimation{p_end}
{synopt :{opt other:vars(varlist)}}variables to be passed to Python{p_end}
{synopt :{opt othervarsn:ames(list)}}names of variables in Python{p_end}
{synopt :{opt pyg:radient}}python gradient function provided{p_end}
{synopt :{opt pyh:essian}}python Hessian function provided{p_end}
{synopt :{opt othervarsn:ames(list)}}names of variables in Python{p_end}
{synopt :{opt pyset:up(filename)}}python file for data manipulation prior to estimation{p_end}
{synopt :{opt robustok}}calculate robust standard errors{p_end}
{synopt :{opt scal:ars(scalar list)}}list of scalars to pass to Python{p_end}
{synopt :{opt scalarn:ames(list)}}names of scalars in Python{p_end}
{synopt :{opt search(search option)}}initial values search options{p_end}
{synopt :{opt statics:calars(scalar list)}}scalars treated as static arguments in Python{p_end}
{synopt :{{manhelp maximize R}}}control the maximization process; seldom used{p_end}

{p2colreset}{...}
{p 4 6 2}

{title:Description}
{pstd}
{cmd:mlad} maximizes a log-likelihood function where the likelihood function is programmed in Python. 
This enables the gradients and Hessian matrix to be obtained using automatic differentiation and to take advantage of using multiple CPUs. 
With large datasets {cmd:mlad} tends to be substantially faster than {cmd:ml} 
and has the important advantage that you don't have to derive the gradients 
and the Hessian matrix analytically as these are obtained using automatic differentiation. 

{pstd}
{cmd:mlad} uses Stata's inbuilt optimizer, {cmd:ml}, but makes a call to Python to calculate the
log-likelihood function, gradients and Hessian matrix. This means that the likelihood function must be written as a Python function. The functions to derive the gradients and the Hessian matrix are obtained using automatic differentiation. 

{pstd}
{cmd:mlad} makes use the the {browse "https://jax.readthedocs.io/en/latest/":Jax} Python library. 
The Python function for the log-likelihood needs to use Jax's versions of the numpy and/or scipy Python libraries. 
Some of the advantages of using Jax are as follows.

{phang2}
1) Jax incorprates automatic differentiation. This means thee is no need and sit and derive the gradient and hessian functions for your log-likelihood.

{phang2}
2) Jax uses a XLA compiler for the Python code. This allows it to use multiple CPUs and potentially GPUs. This makes computation fast and allows those with multple CPUs to get the benefit, even without Stata MP.

{phang2}
3) Jax can use just-in-time compilation to further increase computational efficiency. 

{phang2}
4) Jax has has automatic vectorization, to improve performance - useful, for example, for numerical integration. 

{pstd}
In order to use {cmd:mlad} you need to have Stata 16 or above and access to Python. 
You also need certain Python modules installed. 
These are {cmd:jax}, {cmd:jaxlib}, {cmd:numpy}, {cmd: scipy} and {cmd:importlib}. 
Currently, there is not possible to directly install the {cmd:jaxlib} module for Windows, but it is possible to 
{browse "https://jax.readthedocs.io/en/latest/developer.html#additional-notes-for-building-jaxlib-from-source-on-windows":build from source}.
I can't help with this process. 

{pstd}
Factor variables: {cmd:mlad} works with factor variables. However if speed is important to you, then you should create indicator variables / interactions  yourself as this will be  faster. 


Some examples of using {cmd:mlad} can be found here, {browse "https://pclambert.net/software/mlad":https://pclambert.net/software/mlad}.



{title:Options}

{phang}
{opt adtype(adtype)} the type(s) of automatic differentiation used when calculation the Hessian function.
This can be any combination of forward (fwd) and reverse (rev),
i.e. {cmd: revrev}, {cmd: revfwd}, {cmd: fwdrev}, {cmd: fwdfwd}.
The default is {cmd: revrev}.

{phang}
{opt id(varname)} gives the name of an id variable. This will be required if the log-likelihood needs to
calculated over groups, for example in random effects models. If the {cmd:robustok} option is used then 
cluster robust standard errors will be calculated.

{phang}
{opt init(varname)} sets the initial values, b_0. See {help ml##ml_noninteract_descript}

{phang}
{opt nojit} does not invoke just-in-time compilation. 
This can be useful when debugging as Python error messages can be more informative. 
In addition, to be jitable Python functions have to be written in a particular style 
and so it may not be possible to always use jit.
When writing the Python likelihood function, it is useful to first use the {cmd:nojit} option, 
get the function working and then check that 
it works without the {cmd:nojit} option. 
See {browse "https://jax.readthedocs.io/en/latest/jax-101/02-jitting.html":https://jax.readthedocs.io/en/latest/jax-101/02-jitting.html} for advice on making functions "jitable".

{phang}
{opt llfile(filename)} python filename containing log-likelhood function. The function must be named {cmd:python_ll}.

{phang}
{opt matrices(matrix list)} will pass matrices to Python if required for estimation of the log-likelihood. For example,the location of the knots when incorporating restricted cubic splines. 
These will be stored in a dictionary in Python with either the same names specified in {it: matrix list} or
the names specified in {cmd:matnames()} option.

{phang}
{opt matnames(list)} list of names that the matrices will be named in Python. 
If not specified these will default to the same names in the {cmd:matrices} option. 
However, these will often be ugly, tempory names and so it useful to give them more meaningful names.

{phang}
{opt mlmethod(method)} asks to use a ml method other than the default of {cmd:d2}. Only {cmd:dtype} estimators are available. 
This can be useful to check whether the gradients ({cmd:d1debug}) or Hessian ({cmd:d2debug}) have been calculated correctly
or for calculating the speed improvments when using automatic differentiation.

{phang}
{opt othervars(varlist)} give the names of other variables required for the estimation of the log-likelihood. 
This will include the outcome variable(s). 
Weights and offsets are automatically passed to the Python likelhood function. 
You do not need to include covariates in this option as these are automatically passed to the log-likelhood function. 
These will be stored in a dictionary in Python with either the same names specified in {it: varlist} or the names specified in {cmd:othervarnames()} option.

{phang}
{opt othervarnames(list)} list of names that the variables will be named in Python. 
If not specified these will default to the same names in the {cmd:othervars} option. 
However, these will often be ugly tempory names and so it useful to give them more meaningful names.

{phang}
{opt pygradient} Python gradient function is supplied in {it: llfile}. 
This means that automatic differentiation will not be used to calculate the gradient vector.
The function must be named {cmd:python_grad} with the same options as the log likelihood function.

{phang}
{opt pyhessian} Python Hessian function is supplied in {it: llfile}. 
This means that automatic differentiation will not be used to calculate the Hessian matrix.
The function must be named {cmd:python_hessian} with the same options as the log likelihood function.

{phang}
{opt pysetup(filename)} Python file to execute prior to estimation.

{phang}
{opt robustok} Will calculate robust stand errors. 
Note normally robust standard errors cannnot be obtained with {cmd:d-type} estimators, but {cmd:mlad} uses automatic differentiation to derive the score equations. 
If the {opt: id} option has been specified these will be cluster robust standard errors.

{phang}
{opt scalars(scalar list)} will pass scalars to Python if required for estimation of the log-likelihood. 
These will be stored in a dictionary in Python with either the same names specified in {it: scalar list} or the names specified in {cmd:scalarnames()} option.
Note that it be necessary to pass some scalars as static arguments so that the
Python likelhood function is "jitable" - see the {cmd:staticscalars()} option.

{phang}
{opt scalarnames(list)} list of names that the scalars will be named in Python. 
If not specified these will default to the same names in the {cmd:scalars} option. 
However, these will often be ugly,   tempory names and so it useful to give them more meaningful names.

{phang}
{opt search(search option)} gives the search option to be paseed to {cmd:ml}. See {help ml##ml_noninteract_descript}

{phang}
{opt staticscalars(scalar list)} will pass scalars to Python if required for estimation of the log-likelihood that are treated
as static arguments when using just in time compilation. 
This is necessary for arguments that affect the size of Python arrays.
For example, the number of groups in a random effects model.  


{title:Writing the Python log-likelhood function}

{phang}
{cmd:mlad} requires a Python function to calculate the log-likelhood. 
Once this is written and passed via the {cmd:llfile()} option to {cmd:mlad} the fitted model will be a Stata {cmd:d2} estimate and thus various postestimation commands can be used. 

{pstd}
There are some important rules when writing the Python program.

{phang2}
1) The function needs to be named {cmd:python_ll()}

{phang2}
2) The first 4 arguements of the Python function will always be {cmd:def python_ll(beta,X,wt,M):}

{phang3}
{cmd:beta} - is Python list containing a vector of parameters for each equation.

{phang3}
{cmd:X} - is a Python list containing an array of covariates for each equation.

{phang3}
{cmd:wt} - is a vector of weights or a column of 1's of not specified.

{phang3}
{cmd:M} - is a Python dictionary containing addition varibles, matrices or scalars passed using the {cmd:othervars()}, {cmd:matrices()} or {cmd:scalars()} options.
They can be referenced in Python using the same names as they were named in Stata or the names given in the {cmd:othervarames()}, {cmd:matnames()} or {cmd:scalarnames()} options.
In addition if the {cmd:pysetup()} option is used additional information can be stored in the Python dictionary.

{phang3}
There will be only additional function arguments if the {cmd:staticscalars()} option is specified.

{phang2}
3) Jax modules should be imported, for example rather than using {cmd:import numpy as np} you should use {cmd:import jax.numpy as jnp}. Importing other modules, such as {cmd:pandas} will very likely result in an error.

{phang2}
4) The function should be "pure". 
This means that all input data is passed through the function parameters (so you can't use Python global objects) and all results are passed through function results. 
For the purposes of {cmd:mlad} the only thing that should be returned is the log-likelihood as a single scalar. 

{phang2}
5) There are various other issues that can catch you out. See  {browse jax.readthedocs.io/en/latest/notebooks/Common_Gotchas_in_JAX.html:JAX The Sharp Bits} for discussion of style issues.
  
{pstd}
To show some of these issues a simple example follows,

{pstd}
We will maximize a Weibull regression model, i.e. the same as using {cmd:streg} with the {cmd:dist(weibull)} option. This is a survival model. The survival function for a Weibull model is,

{phang2}
{bf: S(t) = exp(-lambda*t^gamma)}

{phang}
with hazard function

{phang2}
{bf: h(t) = lambda*gamma*t^(gamma - 1)}

{pstd}
Both lambda and gamma must be positive thus when estimating the parameters it is usual to model log(lambda) and log(gamma). 
Incoporating covariates for log(lambda) means that the estimated coefficents are log hazard ratios if log(gamma) does not vary by covariates.

{pstd}
With survival data the log-likelhood conribution of the ith individual can be expressed as,

{phang2}
{bf:lli  = d_i*ln[h(t_i)] + log[S(t_i)]} 

{phang}
Where {bf:t_i} is the survival time and {bf:d_i} the event indicator for the ith individual. So for the Weibull model
the log-likelhood can be expressed as, 

{phang2}
{bf:lli = d_i*(ln(lambda) + ln(gamma) + (gamma-1)*ln(t)) - lambda*t^(gamma-1)} 
 
{pstd}
If using {cmd:ml} then an ado file would be written, here named {cmd:weib_d0}. Using a {cmd:d0} evaluator, this could be,

    {cmd:program define weib_d0}
      {cmd:version 16.1}
      {cmd:args todo b lnf g H}
  
      {cmd:tempvar lnlambda lngamma}
      {cmd:mleval `lnlambda' = `b', eq(1)}
      {cmd:mleval `lngamma'  = `b', eq(2)}
  
      {cmd:mlsum `lnf' = _d*(`lnlambda' + `lngamma' + (exp(`lngamma') - 1)*ln(_t)) - ///}
                    {cmd:exp(`lnlambda')*_t^(exp(`lngamma'))} 
      {cmd:if (`todo'==0 | `lnf'>=.) exit}
    {cmd:end}

{pstd}
For details, see {help ml}, but in brief, the program extracts the linear predictor for both ln(lambda) and ln(gamma) using {cmd:mleval} and then feeds these into the log-likelhood function, which is summed using {cmd:mlsum}. 

{pstd}
An example of fiting the model can be seen below

      {cmd:. webuse brcancer}
      {cmd:. stset rectime, failure(censrec==1) scale(365.24)}
      {cmd:. rename x1 age}
      {cmd:. ml model d0 weib_d0 (ln_lambda: = hormon age) (ln_gamma: = hormon), maximize} 
      {cmd:. ml display} 

{pstd}
This will give the same parameter estimates as {cmd:streg}.
            
{pstd}
Fitting the same model using {cmd:mlad} requires writing a Python program to calculate the likelihood. This is shown below.

      {cmd:import jax.numpy as jnp}   
      {cmd:import mladutil  as mu}

      {cmd:def python_ll(beta1,X,wt,M):}
        {cmd:lnlam =  mu.linpred(beta,X,1)}
        {cmd:lngam  = mu.linpred(beta ,X,2)}
        {cmd:gam = jnp.exp(lngam)}
      
        {cmd:return(jnp.sum(d*(lnlam + lngam + (gam - 1)*jnp.log(t)) - jnp.exp(lnlam)*t**(gam)))}

{phang2}
First two modules are imported. The first is JAX's version of {cmd:numpy}. 
This will nearly always have to be imported. 

{phang2}
The second, {cmd:mladutil}, is a set of utility programs for {cmd:mlad}. 

{phang2}
The function name must always be {cmd:python_ll}. 
There are 4 function arguments (as statics scalars are not needed for this example). 

{phang2}
The first argument, {cmd:beta}, is a list with the first item the parameters for ln(lambda) and the second item the parameters for ln(gamma).

{phang2}
The second function arguement is {cmd:X}. The covariates are automatically transferred to Python and stored in a list with the covariates for the first equation in {cmd:X[1]} and the kth equation in {cmd:X[k]}. 
If any offsets have been specified, these will also be included in X[0]. 

{phang2}
The third argument defines any weights that have been specified or a columns of 1's if they have not been specified.

{phang2}
The final arguement, {bf:M}, is a dictionary containing any variables specified in the {cmd:othervars()} option of {cmd:mlad}, 
matrices specified in the {cmd:matrices()} option or 
scalars  specified in the {cmd:scalars()} option.
Here the survival time ({cmd:_t}) and the event indicator ({cmd:_d}) are needed to calculate the liklehood function. 
Note that these will be named {cmd:t} and {cmd:d} in the Python dictionary, M, as defined in the {cmd:othervarnames()} option. See below.

{phang2}
{cmd:linpred} is a utility function to get the current predicted value for the kth equation given X and beta.
It is recommended that you use this function. {cmd:linpred} will automatically incorporate any offsets if specified.

{pstd}
The likelihood is the same as that specified in the Stata ado file. Note that this needs to be summed over observations and thus is returned as a single scalar.

{pstd}
The syntax for {cmd:mlad} in terms of specifiying equations is the same as {cmd:ml}.

        {cmd:. mlad (ln_lambda: = hormon age)   ///}
                    {cmd:(ln_gamma: = hormon)   ///} 
                    {cmd:othervars(_t _d)       ///}
                    {cmd:othervarnames(t d)     ///}
                    {cmd:llfile(weib_like_jax)}  
        {cmd:. ml display}

{pstd}
The are three additional options of {cmd:mlad}. 
The {cmd:othervars()} option specifies that {bf:_t} and {bf:_d} will be passed to the
Python likelihood function in a Python dictionary. 
The {cmd:othervarsnames()} option defines the keys used in the Python dictionary.
If not specified these woudl be the same as specified in the {cmd:othervars()} option.
Note that {cmd:mlad} always calls {cmd:ml} in non-interactive mode, so there is no {cmd:maximize} option.
 

{title:Description}
{pstd}
Some examples of using {cmd:mlad} can be found here, {browse "https://pclambert.net/software/mlad":https://pclambert.net/software/mlad}.





