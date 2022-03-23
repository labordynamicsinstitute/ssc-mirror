{smcl}
{* 16Mar2022}{...}
{cmd:help r_ml_stata_cv}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{hi:r_ml_stata_cv}{hline 1}}Machine learning regression in Stata{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{hi:r_ml_stata_cv}
{it:outcome} 
{it:features} ,
{cmd:mlmodel}{cmd:(}{it:{help r_ml_stata_cv##modeltype:modeltype}}{cmd:)}
{cmd:data_test}{cmd:(}{it:filename}{cmd:)}
{cmd:seed}{cmd:(}{it:integer}{cmd:)}
{cmd:[}{it:{help r_ml_stata_cv##learner_options:learner_options}}{cmd:}
{cmd:}{it:{help r_ml_stata_cv##cv_options:cv_options}}{cmd:}
{cmd:}{it:{help r_ml_stata_cv##other_options:other_options}}{cmd:]}


{dlgtab:Inputs}

{phang} {it:outcome}: numerical variable    

{phang} {it:features}: list of numerical variables representing the features. When a feature is categorical,
please generate the categorical dummies related to this feature. As the command does not do it by default,
it is user's responsibility to generate the appropriate dummies   


{dlgtab:Description}

{pstd} {cmd:r_ml_stata_cv} is a command for implementing machine learning regression algorithms in Stata 16.
It uses the Stata/Python integration ({browse "https://www.stata.com/python/api16/Data.html":sfi}) 
capability of Stata 16 and allows to implement the following regression
algorithms: ordinary least squares, elastic net, tree, boosting, random forest, neural network, nearest neighbor,
support vector machine. It provides hyper-parameters' optimal tuning via K-fold cross-validation using greed search.  
This command makes use of the Python {browse "https://scikit-learn.org/stable/":Scikit-learn} API to carry out both cross-validation and prediction.

    
{dlgtab: Main options}

{synoptset 32 tabbed}{...}
{synopthdr :options}
{synoptline}
{syntab :Main}
{synopt :{opt mlmodel(modeltype)}}where {it:modeltype} indicates the ML model to fit{p_end}
{synopt :{opt data_test(filename)}}where {it:filename} is a Stata dataset used as testing dataset{p_end}
{synopt :{opt seed(#)}}where {it:#} is an integer number used as random seed{p_end}
{synoptline}


{dlgtab: Model options}

{marker modeltype}{...}
{synopthdr:modeltype_options}
{synoptline}
{syntab:Model}
{synopt:{opt ols}}Ordinary least squares{p_end}
{synopt:{opt elasticnet}}Elastic net{p_end}
{synopt:{opt tree}}Tree regression{p_end}
{synopt:{opt randomforest}}Bagging and random forests{p_end}
{synopt:{opt boost}}Boosting{p_end}
{synopt:{opt nearestneighbor}}Nearest neighbor{p_end}
{synopt:{opt neuralnet}}Neural network{p_end}
{synopt:{opt svm}}Support vector machine{p_end}
{synoptline}


{dlgtab: Learner options}

{marker learner_options}{...}
{synopthdr:learner_options}
{synoptline}
{syntab:Tree}
{synopt:{opt tree_depth(#)}}Maximum tree depth. # = integer{p_end}

{syntab:Elastic net}
{synopt:{opt alpha(#)}}Penalization parameter. # = float{p_end}
{synopt:{opt l1_ratio(#)}}Elastic parameter. # = float{p_end}

{syntab:Random forest}
{synopt:{opt tree_depth(#)}}Maximum tree depth. # = integer{p_end}
{synopt:{opt max_features(#)}}Maximum number of splitting features. # = integer{p_end}
{synopt:{opt n_estimators(#)}}Number of bootstrapped trees. # = integer{p_end}

{syntab:Boosting}
{synopt:{opt tree_depth(#)}}Maximum tree depth. # = integer{p_end}
{synopt:{opt learning_rate(#)}}Learning rate. # = float{p_end}
{synopt:{opt n_estimators(#)}}Number of sequential trees. # = integer{p_end}

{syntab:Nearest neighbor}
{synopt:{opt nn(#)}}Number of nearest neighbors. # = integer{p_end}

{syntab:Neural network}
{synopt:{opt n_neurons_l1(#)}}Number of neurons in the first layer. # = integer{p_end}
{synopt:{opt n_neurons_l2(#)}}Number of neurons in the second layer. # = integer{p_end}
{synopt:{opt alpha(#)}}L2 penalization parameter. # = float{p_end}

{syntab:Support vector machine}
{synopt:{opt c(#)}}Margin parameter. # = float{p_end}
{synopt:{opt gamma(#)}}Inverse of the radius of influence of observations selected as support vectors. # = float{p_end}
{synoptline}


{dlgtab: Cross-validation options}

{marker cv_options}{...}
{synopthdr:cv_options}
{synoptline}
{syntab:CV options}
{synopt:{opt n_folds(#)}}Number of cross-validation folds. # = integer{p_end}
{synopt:{opt cross_validation(name)}}{it:name} specifies the name of the dataset containing cross-validation results{p_end}
{synoptline}


{dlgtab: Other options}

{marker other_options}{...}
{synopthdr:other_options}
{synoptline}
{syntab:Other options}
{synopt:{opt prediction(name)}}Generating predictions of the outcome variable of name {it:name}{p_end}
{synopt:{opt default}}Running the specified model with parameters equal to the Scikit-learn's default values{p_end}
{synopt:{opt graph_cv}}Displaying the cross-validation graph{p_end}
{synopt:{opt save_graph_cv(name)}}Saving the cross-validation graph with name {it:name}{p_end}
{synoptline}


{dlgtab:Returns: general}

{synoptset 24 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:e(N_train_all)}}Total number of observations in the initial training dataset{p_end}
{synopt:{cmd:e(N_train_used)}}Number of training observations actually used{p_end}
{synopt:{cmd:e(N_test_all)}}Total number of observations in the initial testing dataset{p_end}
{synopt:{cmd:e(N_test_used)}}Number of testing observations actually used{p_end}
{synopt:{cmd:e(N_features)}}Number of features{p_end}
{synopt:{cmd:e(TRAIN_ACCURACY)}}K-fold cross-validation training average accuracy (= explained variance){p_end}
{synopt:{cmd:e(TEST_ACCURACY)}}K-fold cross-validation testing average accuracy (= explained variance){p_end}
{synopt:{cmd:e(SE_TEST_ACCURACY)}}K-fold cross-validation stad. err. of the testing average accuracy (= explained variance){p_end}
{synopt:{cmd:e(BEST_INDEX)}}Best cross-validation index{p_end}
{synopt:{cmd:e(N_FOLDS)}}Number of folds used for cross-validation{p_end}
{synopt:{cmd:e(Train_mse)}}Mean squared error on training data{p_end}
{synopt:{cmd:e(Test_mse)}}Mean squared error on testing data{p_end}
{synopt:{cmd:e(Train_mape)}}Mean absolute prediction error on training data{p_end}
{synopt:{cmd:e(Test_mape)}}Mean absolute prediction error on testing data{p_end}


{dlgtab:Returns: by learner}

{synoptset 24 tabbed}{...}
{synoptline}
{syntab:Boosting}
{syntab:Scalars}
{synopt:{cmd:e(OPT_LEARNING_RATE)}}Optimal coefficient that shrinks the contribution of each tree to the Boosting's prediction{p_end}
{synopt:{cmd:e(OPT_N_ESTIMATORS)}}Optimal number of sequential trees for the Boosting ensemble prediction{p_end}
{synopt:{cmd:e(OPT_TREE_DEPTH)}}Optimal depth of the single tree{p_end}
{synoptline}

{syntab:Elastic net}
{syntab:Scalars}
{synopt:{cmd:e(OPT_ALPHA)}}Optimal shrinkage parameter: constant multiplying the penalty term{p_end}
{synopt:{cmd:e(OPT_L1_RATIO)}}Optimal elastic net parameter: 0=Lasso, 1=Ridge regression{p_end}
{synoptline}

{syntab:Nearest neighbor}
{syntab:Scalars}
{synopt:{cmd:e(OPT_NN)}}Optimal number of nearest neighbors to use{p_end}
{syntab:Macro}
{synopt:{cmd:e(OPT_WEIGHT)}}Optimal kernel weighting scheme: (1) {it:uniform}: uniform weights (observations equally weighted); 
or (2) {it:distance} (observations weighted by the inverse of their distance from the point of imputation){p_end}
{synoptline}

{syntab:Neural network}
{syntab:Scalars}
{synopt:{cmd:e(OPT_NEURONS_L_1)}}Optimal number of neurons (or hidden units) in the first (hidden) layer{p_end}
{synopt:{cmd:e(OPT_NEURONS_L_2)}}Optimal number of neurons (or hidden units) in the second (hidden) layer{p_end}
{synopt:{cmd:e(OPT_ALPHA)}}Optimal L2 penalization parameter{p_end}
{synoptline}

{syntab:Random forests}
{syntab:Scalars}
{synopt:{cmd:e(OPT_N_ESTIMATORS)}}Optimal number of bootstrapped trees for the Boosting ensemble prediction{p_end}
{synopt:{cmd:e(OPT_TREE_DEPTH)}}Optimal depth of the single tree{p_end}
{synopt:{cmd:e(OPT_MAX_FEATURES)}}Optimal number of features to consider at each tree best split{p_end}
{synoptline}

{syntab:Support vector machine}
{syntab:Scalars}
{synopt:{cmd:e(OPT_C)}}Optimal regularization parameter, where the strength of the regularization is inversely proportional to C{p_end}
{synopt:{cmd:e(OPT_GAMMA)}}Optimal kernel coefficient for the polynomial or radial kernel{p_end}
{synoptline}

{syntab:Regression tree}
{syntab:Scalars}
{synopt:{cmd:e(OPT_DEPTH)}}Optimal maximum depth of the tree{p_end}
{synoptline}


{dlgtab:Remarks}

{phang} To run this program you need to have both Stata 16 (or later versions) and Python 
           (from version 2.7 onwards) installed. You can find information about how to install 
           Python in your machine here: https://www.python.org/downloads.
           Also, the Python Scikit-learn (and related dependencies) and the Stata Function Interface (sfi) APIs
           must be uploaded before running the command. You can find information about how to install/use
           them here (observe that the SFI API is already installed in your Stata 16 or later versions): 
           (1) Scikit-learn: https://scikit-learn.org/stable/install.html; (2) sfi: https://www.stata.com/python/api17. 

{phang} Please, remember to have the most recent up-to-date version of this program installed.


{dlgtab:Example}

{pstd}{bf:Example 1}: Default regression tree with train/test predictions{p_end}
{phang2} Load intial dataset{p_end}
{phang3} {stata sysuse auto, clear}{p_end}
{phang2} Split dataset into train and test datasets{p_end}
{phang3} {stata splitsample, generate(svar, replace) split(0.80 0.20)}{p_end}
{phang2} Form the train dataset{p_end}
{phang3} {stata preserve}{p_end}
{phang3} {stata keep if svar==1}{p_end}
{phang3} {stata save auto_train , replace}{p_end}
{phang3} {stata restore}{p_end}
{phang2} Form the test dataset{p_end}
{phang3} {stata preserve}{p_end}
{phang3} {stata keep if svar==2}{p_end}
{phang3} {stata save auto_test , replace}{p_end}
{phang3} {stata restore}{p_end}
{phang2} Load train dataset{p_end}
{phang3} {stata use auto_train, clear}{p_end}
{phang2} Run tree regression{p_end}
{phang3} {stata r_ml_stata_cv price mpg rep78 headroom , mlmodel("tree") data_test("auto_test") default prediction("pred") seed(10)}{p_end}

{pstd}{bf:Example 2}: Regression tree with train/test predictions, and cross-validation{p_end}
{phang2} Load intial dataset{p_end}
{phang3} {stata sysuse auto, clear}{p_end}
{phang2} Split dataset into train and test datasets{p_end}
{phang3} {stata splitsample, generate(svar, replace) split(0.80 0.20)}{p_end}
{phang2} Form the train dataset{p_end}
{phang3} {stata preserve}{p_end}
{phang3} {stata keep if svar==1}{p_end}
{phang3} {stata save auto_train , replace}{p_end}
{phang3} {stata restore}{p_end}
{phang2} Form the test dataset{p_end}
{phang3} {stata preserve}{p_end}
{phang3} {stata keep if svar==2}{p_end}
{phang3} {stata save auto_test , replace}{p_end}
{phang3} {stata restore}{p_end}
{phang2} Load train dataset{p_end}
{phang3} {stata use auto_train, clear}{p_end}
{phang2} Run tree regression{p_end}
{phang3} {stata r_ml_stata_cv price mpg rep78 headroom , mlmodel("tree") data_test("auto_test") tree_depth(3) prediction("pred") cross_validation("CV") n_folds(5) seed(10)}{p_end}        
        
{pstd}{bf:Example 3}: Regression tree with train/test predictions, cross-validation, and optimal tuning{p_end}
{phang2} Load intial dataset{p_end}
{phang3} {stata sysuse auto, clear}{p_end}
{phang2} Split dataset into train and test datasets{p_end}
{phang3} {stata splitsample, generate(svar, replace) split(0.80 0.20)}{p_end}
{phang2} Form the train dataset{p_end}
{phang3} {stata preserve}{p_end}
{phang3} {stata keep if svar==1}{p_end}
{phang3} {stata save auto_train , replace}{p_end}
{phang3} {stata restore}{p_end}
{phang2} Form the test dataset{p_end}
{phang3} {stata preserve}{p_end}
{phang3} {stata keep if svar==2}{p_end}
{phang3} {stata save auto_test , replace}{p_end}
{phang3} {stata restore}{p_end}
{phang2} Load train dataset{p_end}
{phang3} {stata use auto_train, clear}{p_end}
{phang2} Run tree regression{p_end}
{phang3} {stata r_ml_stata_cv price mpg rep78 headroom , mlmodel("tree") data_test("auto_test") tree_depth(2 3 4 5 6 7 8) prediction("pred") cross_validation("CV") n_folds(5) seed(10)}{p_end}   


{dlgtab:Reference}

{phang}
Cerulli, G. 2021. Improving econometric prediction by machine learning, {it:Applied Economics Letters}, 28, 16, 1419-1425, 2021.

{phang}
Gareth, J., Witten, D., Hastie, D.T., Tibshirani, R. 2013. {it:An Introduction to Statistical Learning : with Applications in R}. New York, Springer.

{phang} 
Raschka, S., Mirjalili, V. 2019. {it:Python Machine Learning}. 3rd Edition, Packt Publishing.


{dlgtab:Author}

{phang}Giovanni Cerulli{p_end}
{phang}IRCrES-CNR{p_end}
{phang}Research Institute for Sustainable Economic Growth, National Research Council of Italy{p_end}
{phang}E-mail: {browse "mailto:giovanni.cerulli@ircres.cnr.it":giovanni.cerulli@ircres.cnr.it}{p_end}


{dlgtab:Also see}

{psee}
Online: {helpb python}, {helpb c_ml_stata}, {helpb srtree}, {helpb srtree}, {helpb subset}
{p_end}
