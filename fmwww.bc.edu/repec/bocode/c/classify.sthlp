{smcl}
{* *! version 0.0.4 08mar2024}{...}
{vieweralsosee "[R] predict" "mansection R predict"}{...}
{vieweralsosee "[R] estat classification" "mansection R estat classification"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "classify##syntax"}{...}
{viewerjumpto "Description" "classify##description"}{...}
{viewerjumpto "Options" "classify##options"}{...}
{viewerjumpto "Examples" "classify##examples"}{...}
{viewerjumpto "Additional Information" "classify##additional"}{...}
{viewerjumpto "Contact" "classify##contact"}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 32 2}
{cmd:classify} # [ if ] {cmd:,} {cmdab:ps:tub(}{it:string asis}{cmd:)} [
{cmdab:thr:eshold(}{it:real}{cmd:)} {cmdab:pm:ethod(}{it:string asis}{cmd:)}
{cmdab:po:pts(}{it:string asis}{cmd:)}]{p_end}

{synoptset 25 tabbed}{...}
{synoptline}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{opt ps:tub}}a new variable name for predicted values{p_end}
{syntab:Optional}
{synopt :{opt thr:eshold}}positive outcome threshold; default is {cmd:threshold(0.5)}{p_end}
{synopt :{opt pm:ethod}}predicted statistic from {help predict}; default is {cmd:pmethod(pr)}{p_end}
{synopt :{opt po:pts}}options passed to {help predict} in addition to the method{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd} 
{cmd:classify} is part of the {help crossvalidate} suite of tools to implement 
cross-validation methods with Stata estimation commands. {cmd:classify} is used 
internally by the {help predictit} command to handle conversion of predicted 
probabilities into integer valued class memberships.  {cmd:classify} will work 
with binomial and multinomial (including ordinal) classification models.  For 
multinomial models, the class membership with the highest predicted probability 
is selected as the class predicted by the model.

{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt ps:tub} is used to define a new variable name/stub for the predicted values
from the validation/test set.  When K-Fold cross-validation is used, this 
option defines the name of the variable containing the predicted values from 
each of the folds and will be used as a variable stub to store the results from 
fitting the model to all of the training data. 

{dlgtab:Optional}

{phang}
{opt thr:eshold} defines the probability cutoff used to determine a positive 
classification for binary response models.  This value functions the same way 
as it does in the case of {help estat_classification:estat classification}.

{phang}
{opt pm:ethod} is passed internally to Stata's {help predict} command to 
generate the predicted values of the outcome for the out-of-sample data. The 
default in {cmd:classify} is to generate the predicted probabilities of class 
membership.

{phang}
{opt po:pts} is passed internally to Stata's {help predict} command to 
generate the predicted values of the outcome for the out-of-sample data. For 
multivariate outcome models, like {help sureg}, this option can be used to 
specify which of the equations should be used to predict the outcome of interest.  
It can also be used to specify the {opt nooff:set} option in single or 
multi-equation models.  Consult the {help predict} documentation for the model 
you are fitting for more details.

{marker examples}{...}
{title:Examples}

{p 4 4 2}Binary Classification Example{p_end}

{p 4 4 2}Load example data{p_end}
{p 8 4 2}{stata webuse lbw, clear}{p_end}
{p 4 4 2}Fit a model to the data{p_end}
{p 8 4 2}{stata logit low age smoke) c}{p_end}
{p 4 4 2}Use classify to generate the predicted classes{p_end}
{p 8 8 2}{stata classify 2 if e(sample), ps(pred)}{p_end}

{p 4 4 2}Multinomial Classification Example{p_end}

{p 4 4 2}Load example data{p_end}
{p 8 4 2}{stata webuse sysdsn1, clear}{p_end}
{p 4 4 2}Fit a model to the data{p_end}
{p 8 4 2}{stata mlogit insure age male i.site) c}{p_end}
{p 4 4 2}Use classify to generate the predicted classes{p_end}
{p 8 8 2}{stata classify 3 if e(sample), ps(pred)}{p_end}

{p 4 4 2}Ordinal Classification Example{p_end}

{p 4 4 2}Load example data{p_end}
{p 8 4 2}{stata webuse fullauto, clear}{p_end}
{p 4 4 2}Fit a model to the data{p_end}
{p 8 4 2}{stata ologit rep77 price foreign) c}{p_end}
{p 4 4 2}Use classify to generate the predicted classes{p_end}
{p 8 8 2}{stata classify 5 if e(sample), ps(pred)}{p_end}


{marker additional}{...}
{title:Additional Information}
{p 4 4 8}If you have questions, comments, or find bugs, please submit an issue in the {browse "https://github.com/wbuchanan/crossvalidate":crossvalidate GitHub repository}.{p_end}


{marker contact}{...}
{title:Contact}
{p 4 4 8}William R. Buchanan, Ph.D.{p_end}
{p 4 4 8}Sr. Research Scientist, SAG Corporation{p_end}
{p 4 4 8}{browse "https://www.sagcorp.com":SAG Corporation}{p_end}
{p 4 4 8}wbuchanan at sagcorp [dot] com{p_end}

{p 4 4 8}Steven D. Brownell, Ph.D.{p_end}
{p 4 4 8}Economist, SAG Corporation{p_end}
{p 4 4 8}{browse "https://www.sagcorp.com":SAG Corporation}{p_end}
{p 4 4 8}sbrownell at sagcorp [dot] com{p_end}
