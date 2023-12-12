{smcl}
{* 26jan2022}{...}
{cmd:help c_ml_stata}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{hi:c_ml_stata}{hline 1}}Implementing machine learning classification in Stata{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{hi:c_ml_stata}
{it:outcome} 
[{it:varlist}],
{cmd:mlmodel}{cmd:(}{it:{help c_ml_stata##modeltype:modeltype}}{cmd:)}
{cmd:out_sample_x}{cmd:(}{it:filename}{cmd:)}
{cmd:out_sample_y}{cmd:(}{it:filename}{cmd:)}
{cmd:in_prediction}{cmd:(}{it:name}{cmd:)}
{cmd:out_prediction}{cmd:(}{it:name}{cmd:)}
{cmd:cross_validation}{cmd:(}{it:name}{cmd:)}
{cmd:seed}{cmd:(}{it:integer}{cmd:)}
{cmd:n_folds}{cmd:(}{it:integer}{cmd:)}
[{cmd:save_graph_cv}{cmd:(}{it:name}{cmd:)}]


where: 

{phang} {it:outcome} is a numerical discrete dependent variable representing
the different classes. It is recommended to recode this 
variable so to take values [1,2,...,M] in a M-class setting. 
For example, if {it:outcome} is binary taking values [0,1], please record it so to take values [1,2].
Missing values are not allowed.  

{phang} {it:varlist} is a list of numerical variables representing the features. When a feature is categorical,
please generate the categorical dummies related to this feature. As the command does not do it by default,
it is user's responsibility to generate the appropriate dummies.
Missing values are not allowed.    
 

{title:Description}

{pstd} {cmd:c_ml_stata} is a command for implementing machine learning classification algorithms in Stata 16.
It uses the Stata/Python integration ({browse "https://www.stata.com/python/api16/Data.html":sfi}) 
capability of Stata 16 and allows to implement the following classification
algorithms: tree, boosting, random forest, regularized multinomial, neural network, naive Bayes, nearest neighbor,
support vector machine, standard (unregularized) multinomial. 
It provides hyper-parameters' optimal tuning via K-fold cross-validation using greed search. 
For each observation (or instance), this command generates both predicted class probabilities 
and predicted labels using the Bayes classification rule.  
This command makes use of the Python {browse "https://scikit-learn.org/stable/":Scikit-learn}
API to carry out both cross-validation and prediction.


{title:Options}
    
{phang} {cmd:mlmodel}{cmd:(}{it:{help c_ml_stata##modeltype:modeltype}}{cmd:)} 
specifies the machine learning algorithm to be estimated.   

{phang} {cmd:out_sample_x}{cmd:(}{it:filename}{cmd:)}
requests to provide a dataset as {it:filename} containing the testing observations over which estimating predictions. 
This dataset contains only predictors.

{phang} {cmd:out_sample_y}{cmd:(}{it:filename}{cmd:)}
requests to provide a dataset as {it:filename} containing the outcome of the testing observations over which estimating predictions. This dataset must contain only the outcome. When the outcome is unknown, this can be inserted as a variable with all missing values.  

{phang} {cmd:in_prediction}{cmd:(}{it:name}{cmd:)}
requires to specify a {it:name} for the file that will contain in-sample predictions. 

{phang} {cmd:out_prediction}{cmd:(}{it:name}{cmd:)}
requires to specify a {it:name} for the file that will contain out-sample predictions.
These predictions are those obtained from the option {cmd:out_sample}{cmd:(}{it:filename}{cmd:)}.   

{phang} {cmd:cross_validation}{cmd:(}{it:name}{cmd:)}
requires to specify a {it:name} for the dataset that will contain cross-validation results. 

{phang} {cmd:seed}{cmd:(}{it:integer}{cmd:)} requests to specify a integer seed to assure replication
of same results.  

{phang} {cmd:n_folds}{cmd:(}{it:integer}{cmd:)} requests to specify the number of folds to catty out {it:K}-fold cross-validation.

{phang} {cmd:save_graph_cv}{cmd:(}{it:name}{cmd:)} allows to obtain the cross-validation optimal tuning graph drawing both train and test accuracy.   


{marker modeltype}{...}
{synopthdr:modeltype_options}
{synoptline}
{syntab:Model}
{p2coldent : {opt tree}}Classification tree{p_end}
{p2coldent : {opt randomforest}}Bagging and random forests{p_end}
{p2coldent : {opt boost}}Boosting{p_end}
{p2coldent : {opt regularizedmultinomial}}Regularized multinomial{p_end}
{p2coldent : {opt nearestneighbor}}Nearest Neighbor{p_end}
{p2coldent : {opt neuralnet}}Neural network{p_end}
{p2coldent : {opt naivebayes}}Naive Bayes{p_end}
{p2coldent : {opt svm}}Support vector machine{p_end}
{p2coldent : {opt multinomial}}Standard multinomial{p_end}
{synoptline}


{title:Returns}

{pstd} {cmd:c_ml_stata} returns into e-return scalars (if numeric) or macros (if string) 
the "optimal hyper-parameters", the "optimal train accuracy", the "optimal test accuracy", 
and the "standard error of the optimal test accuracy" obtained via cross-validation. 
For each learner, the list and meaning of the tuned hyper-parameters are:

{phang} {cmd:Boosting} (option "boost"):

{phang} -> {it:e(OPT_LEARNING_RATE)}: scalar. It is the coefficient that shrinks the contribution of each tree to the Boosting's prediction. 

{phang} -> {it:e(OPT_N_ESTIMATORS)}: scalar. It is the number of boosting iteration to perform. 

{phang} {cmd:Nearest-neighbor} (option "nearestneighbor")

{phang} -> {it:e(OPT_NN)}: scalar. It is the number of nearest neighbors to use. 

{phang} -> {it:e(OPT_WEIGHT)}: local macro. It returns the kernel weighting scheme, that can be: 
(1) {it:uniform}: uniform weights, where all observations in each neighborhood are weighted equally; 
or (2) {it:distance}, weighting observations by the inverse of their distance from the point of imputation. 

{phang} {cmd:Naive Bayes} (option "naivebayes")

{phang} -> {it:e(OPT_VAR_SMOOTHING)}: scalar. Portion of the largest variance of all predictors that is added to variances for calculation stability.

{phang} {cmd:Neural network} (option "neuralnet")

{phang} -> {it:e(OPT_NEURONS_L_1)}: scalar. It is the number of neurons (or hidden units) in the first (hidden) layer. 
 
{phang} -> {it:e(OPT_NEURONS_L_2)}: scalar. It is the number of neurons (or hidden units) in the second (hidden) layer.   

{phang} {cmd:Random forests} (option "randomforest")

{phang} -> {it:e(OPT_MAX_DEPTH)}: scalar. It is the maximum depth of the tree. 

{phang} -> {it:e(OPT_MAX_FEATURES)}: scalar. It is the number of features (or predictors) 
to consider when looking for the tree best split. 

{phang} {cmd:Regularized multinomial} (option "regularizedmultinomial")

{phang} -> {it:e(OPT_PENALIZATION)}: scalar. It is the inverse of regularization strength (positive coefficient). Like in the support vector machine, smaller values specify stronger regularization.

{phang} -> {it:e(OPT_L1_RATIO)}: scalar. It is the elastic mixing parameter, varying between zero (Lasso regression) and one (Ridge regression). Intermediate values of this parameter weigh differently the Lasso and Ridge penalization terms. 

{phang} {cmd:Support vector machine} (option "svm")

{phang} -> {it:e(OPT_C)}: scalar. It is the SVM regularization parameter, 
where the strength of the regularization is inversely proportional to C. It is strictly positive.

{phang} -> {it:e(OPT_GAMMA)}: scalar. It is the kernel coefficient for the polynomial or radial kernel. 

{phang} {cmd:Regression tree} (option "tree")

{phang} -> {it:e(OPT_DEPTH)}: scalar. It is the maximum depth of the tree. 

{pstd} {cmd:c_ml_stata} provides model predictions both as predicted labels and as predicted probabilities. 


{title:Remarks}

{phang} -> When running {cmd:c_ml_stata}, one has to prepare in advance three datasets: 
(i) the main dataset to open and use in the current Stata session: it is the {it:training} dataset, employed also for carrying out K-fold cross-validation;
(ii) a dataset (located in the current working directory) to insert as {it:filename} in option {cmd:out_sample_x}{cmd:(}{it:filename}{cmd:)}: 
it is the {it:testing} dataset, only containing the predictors of testing observations; 
(iii) a dataset (located in the current working directory) to insert as {it:filename} 
in option {cmd:out_sample_y}{cmd:(}{it:filename}{cmd:)}: it is the {it:testing} dataset, 
only containing the outcome of testing observations. 
The datasets defined in (i) and (ii) must not contain missing values. 
Before running this command, please check whether these datasets contain missing values and delete observations containing them (listwise). 
Of course, the datasets in (ii) and (iii) must have the same size and refer to the same out-of-sample observations.   

{phang} -> The order in which the predictors appear in the testing dataset to insert in {cmd:out_sample_x}{cmd:(}{it:filename}{cmd:)} must be the same as the one of the training dataset.

{phang} -> If the variables appearing in the used Stata datasets contain value labels, it is recommended to eliminate them. Indeed, Python cannot read data with labeled values. 
           
{phang} -> To run this program you need to have both Stata 16 (or later versions) and Python 
           (from version 2.7 onwards) installed. You can find information about how to install 
           Python in your machine here: https://www.python.org/downloads.
           Also, the Python Scikit-learn (and related dependencies) and the Stata Function Interface (sfi) APIs
           must be uploaded before running the command. You can find information about how to install/use
           them here (observe that the SFI API is already installed in your Stata 16 or later versions): 
           (1) Scikit-learn: https://scikit-learn.org/stable/install.html; (2) sfi: https://www.stata.com/python/api17.    

{phang} -> Please, remember to have the most recent up-to-date version of this program installed.


{title:Example}

{phang} *** {bf:RUNNING A CLASSIFICATION TREE} ***

{phang} * {bf:Download these {browse "https://www.dropbox.com/sh/iy4lr4heij6az88/AABSTXILhQQCQmlNKV1ZApcWa?dl=0":datasets}, by putting them in the same directory:}

{phang} * Dataset 1: "c_data" -> the complete dataset

{phang} * Dataset 2: "c_data_x" -> the test dataset containing "only" the features X 

{phang} * Dataset 3: "c_data_y" -> the test dataset containing "only" the outcome y  

{phang} * {bf:Load the complete dataset}

{phang} . use "c_data" , clear

{phang} * {bf:Run the "c_ml_stata" command with model option "tree"}

{phang} #delimit ;

{phang} . c_ml_stata y x1 x2 x3 x4 , mlmodel("tree") in_prediction("in_pred") cross_validation("CV") out_sample_x("c_data_x") out_sample_y("c_data_y") out_prediction("out_pred") seed(10) n_folds(10) save_graph_cv("graph_cv");

{phang} #delimit cr

{phang} * {bf:Look at the main results} 

{phang} . ereturn list

{phang} * {bf:Look at the cross-validation results}

{phang} . use CV , clear

{phang} . list

{phang} * {bf:Look at the out-of-sample predictions}

{phang} . use out_pred , clear

{phang} . list


{title:Reference}

{phang}
Cerulli, G. 2021. Improving econometric prediction by machine learning, {it:Applied Economics Letters}, 28, 16, 1419-1425, 2021.

{phang}
Gareth, J., Witten, D., Hastie, D.T., Tibshirani, R. 2013. {it:An Introduction to Statistical Learning : with Applications in R}. New York, Springer.

{phang} 
Raschka, S., Mirjalili, V. 2019. {it:Python Machine Learning}. 3rd Edition, Packt Publishing.


{title:Author}

{phang}Giovanni Cerulli{p_end}
{phang}IRCrES-CNR{p_end}
{phang}Research Institute for Sustainable Economic Growth, National Research Council of Italy{p_end}
{phang}E-mail: {browse "mailto:giovanni.cerulli@ircres.cnr.it":giovanni.cerulli@ircres.cnr.it}{p_end}


{title:Also see}

{psee}
Online: {helpb python}, {helpb r_ml_stata}, {helpb srtree}, {helpb srtree}, {helpb subset}
{p_end}
