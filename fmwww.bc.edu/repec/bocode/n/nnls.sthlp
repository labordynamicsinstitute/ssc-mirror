{smcl}
{* 15April2024}{...}
{cmd:help nnls}
{hline}

{title:Title}

{p2colset 5 16 21 2}{...}
{p2col :{hi:nnls} {hline 2}}Non-negative least squares in Stata{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{hi:nnls}
{it: depvar} 
{it: indepvars}
{ifin}{cmd:,}
[{cmd:graph}
{cmd:graph_save}{cmd:(}{it:graphname}{cmd:)}
{cmd:standardize}]

{dlgtab:Inputs}

{phang} {it: depvar}: numerical variable    

{phang} {it: indepvars}: list of numerical variables representing the features. When a feature is categorical,
please generate the categorical dummies related to this feature. As the command does not do it by default,
it is user's responsibility to generate the appropriate dummies.   

{dlgtab:Description}

{pstd} {cmd:nnls} is a command implementing non-negative least squares (NNLS) in Stata on top of Python using the Python function "nnls()". NNLS is a type of constrained least squares problem where the coefficients are not allowed to become negative. Generally, NNLS provides regularized (or sparse) solution, meaning that only a few parameters of the least squares regression are allowed to be positive and non-zero.        


{dlgtab: Options}

{synoptset 32 tabbed}{...}
{synopthdr :options}
{synoptline}
{synopt :{opt graph}}generates the importance index bar graph{p_end}
{synopt :{opt standardize}}compute NNLS on z-standardized variables (zero mean and unit variance){p_end}
{synoptline}


{dlgtab:Returns: general}

{synoptset 24 tabbed}{...}
{syntab:Macros}
{synopt:{cmd:e(num_features)}} number of features {p_end}
{synopt:{cmd:e(features)}} names of the features {p_end}
{synopt:{cmd:e(depvar)}} name of the dependent variable{p_end}
{syntab:Matrices}
{synopt:{cmd:e(Weights)}} matrix of the weights{p_end}
{synopt:{cmd:e(Std_Weights)}} matrix of the standardized weights (i.e., summing up to 1){p_end}
{synoptline}


{dlgtab:Remarks}

{phang}   
Remark 1: In order to execute this program, it is necessary to have both Stata 16 or newer versions and Python installed, starting from version 2.7 onwards. Detailed instructions for installing Python on your machine can be found at: https://www.python.org/downloads. We highly recommend using the Anaconda distribution for Python, which can be installed from: https://docs.anaconda.com/free/anaconda/install/index.html#. Additionally, prior to running the command, it is essential to ensure that the Python "SciPy" package and its related dependencies, as well as the Stata Function Interface (sfi) APIs, are installed.

{phang} 
Remark 2. Please, consider to keep updated with future versions of this command.  


{dlgtab:Example}

{pstd}{bf:Example}: Non-negative least squares applied to the Boston dataset{p_end}
{phang2} Load initial dataset from ancillary file{p_end}
{phang3} {stata use boston, clear}{p_end}
{phang2} Set the outcome{p_end}
{phang3} {stata global y "medv"}{p_end}
{phang2} Set the features{p_end}
{phang3} {stata global X "crim zn indus age lstat black"}{p_end}
{phang2} Run "nnls" using unstandardized variables{p_end}
{phang3} {stata nnls $y $X , graph graph_save("my_graph")}{p_end}
{phang2} Generate predictions{p_end}
{phang3} {stata predict PRED_ustd}{p_end}
{phang2} Run "nnls" using standardized variables{p_end}
{phang3} {stata nnls $y $X , graph graph_save("my_graph") standardize}{p_end}
{phang2} Generate predictions{p_end}
{phang3} {stata predict PRED_std}{p_end}


{dlgtab:References}

{pstd} 
Bro, R. and De Jong, S. 1997. A fast non-negativity-constrained least squares algorithm. {it:Journal of Chemometrics}, 11, 393-401. 

{pstd} 
Cerulli, G. 2023. {it:Fundamentals of Supervised Machine Learning: With Applications in Python, R, and Stata}, Springer. 


{dlgtab:Acknowledgment}

{pstd} 
The development of this software was supported by FOSSR (Fostering Open Science in Social Science Research), a project funded by the European Union - NextGenerationEU under the NPRR Grant agreement n. MURIR0000008.

{dlgtab:Author}

{phang}Giovanni Cerulli{p_end}
{phang}IRCrES-CNR{p_end}
{phang}Research Institute for Sustainable Economic Growth, National Research Council of Italy{p_end}
{phang}E-mail: {browse "mailto:giovanni.cerulli@ircres.cnr.it":giovanni.cerulli@ircres.cnr.it}{p_end}


{dlgtab:Also see}

{psee}
Online: {helpb regress}, {helpb lasso}
{p_end}
