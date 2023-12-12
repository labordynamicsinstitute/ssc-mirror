#******************************************************************************
# * TITLE:  "REGULARIZED MULTINOMIAL CLASSIFICATION USING CROSS-VALIDATION" 
# * DATE:   02/11/2021
# * AUTHOR: GIOVANNI CERULLI
# *****************************************************************************
# * USE THE "scikit-learn" PYTHON PACKAGE, METHOD: "LogisticRegression()"
# *****************************************************************************

# IMPORT THE NEEDED PYTHON PACKAGES
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import GridSearchCV
from sfi import Macro, Scalar
from sfi import Data , SFIToolkit
import numpy as np
import pandas as pd
import os

# SET THE DIRECTORY
dir=Macro.getLocal("dir")
os.chdir(dir)

# SET THE TRAIN/TEST DATASET AND THE NEW-INSTANCES-DATASET
dataset=Macro.getLocal("data_fitting")

# LOAD A STATA DATASET LOCATED INTO THE DIRECTORY AS PANDAS DATAFRAME
df = pd.read_stata(dataset)
print(df)
df.info()

# DEFINE y THE TARGET VARIABLE
y=df.iloc[:,0]
print(y)

# DEFINE X THE FEATURES
X=df.iloc[:,1::]
print(X)

# READ THE "SEED" FROM STATA
R=int(Macro.getLocal("seed"))

# INITIALIZE THE MODEL
model = LogisticRegression(penalty='elasticnet',C=0.5, solver='saga',
                                   multi_class='multinomial', l1_ratio = 0.2)

# MLRC "CROSS-VALIDATION" FOR "C" AND "GAMMA" BY PRODUCING A "GRID SEARCH"
# GENERATE THE TWO PARAMETERS' GRID AS A "LIST":
# 1. C = INVERSE OF REGULARIZATION STRENGTH (SMALLER VALUES SPECIFY STRONGER REGULARIZATION)
# 2. G = "l1_ratio"= THE ELASTIC-NET MIXING PARAMETER (WITH 0 <= l1_ratio <= 1)

# Grid for "C"
gridC=[1.2,2,5,10,15,20,40,60,80,120,150,180,200,250,300]

# Grid for "G"
gridG=[0,0.2,0.5,0.8,1]

# PUT THE GENERATED GRIDS INTO A PYTHON DICTIONARY 
param_grid = {'C': gridC, 'l1_ratio': gridG}

# READ THE NUMBER OF CV-FOLDS "n_folds" FROM STATA
n_folds=int(Macro.getLocal("n_folds"))

# INSTANTIATE THE GRID
grid = GridSearchCV(model, param_grid, cv=n_folds, scoring='accuracy', return_train_score=True)

# FIT OVER THE GRID
grid.fit(X, y)

# VIEW THE RESULTS 
CV_RES=pd.DataFrame(grid.cv_results_)[['mean_train_score','mean_test_score','std_test_score']]
D=Macro.getLocal("cross_validation") 
D=D+".dta"
CV_RES.to_stata(D)


# EXAMINE THE BEST MODEL AND PUT RESULTS INTO STATA
# EXAMINE THE BEST MODEL
print("                                                      ")
print("                                                      ")
print("------------------------------------------------------")
print("CROSS-VALIDATION RESULTS TABLE")
print("------------------------------------------------------")
print("The best score is:")                           
print(grid.best_score_)
Scalar.setValue('OPT_SCORE',grid.best_score_,vtype='visible')
print("------------------------------------------------------")
print("The best parameters are:")
print(grid.best_params_)

# PUT OPTIMAL PARAMETER(S) INTO STATA SCALAR(S)
params_values=list(grid.best_params_.values()) 
Scalar.setValue('OPT_LEARNING_RATE',params_values[0],vtype='visible')
Scalar.setValue('OPT_N_ESTIMATORS',params_values[1],vtype='visible')
print("------------------------------------------------------")
print("The best estimator is:")
print(grid.best_estimator_)
print("------------------------------------------------------")
print("The best index is:")
print(grid.best_index_)
print("------------------------------------------------------")


# STORE THE TWO BEST PARAMETERS INTO TWO VARIABLES 
# STORE THE TWO BEST PARAMETERS INTO TWO VARIABLES 
opt_c=grid.best_params_.get('C')
Scalar.setValue('OPT_PENALIZATION',opt_c,vtype='visible')

opt_gamma=grid.best_params_.get('l1_ratio')
Scalar.setValue('OPT_L1_RATIO',opt_gamma,vtype='visible')


# USING THE BEST PARAMETERS TO MAKE PREDICTIONS
# TRAIN YOUR MODEL USING ALL DATA AND THE BEST PARAMETERS
model = LogisticRegression(penalty='elasticnet',C=opt_c, solver='saga',
                         multi_class='multinomial',l1_ratio=opt_gamma)

# FIT THE MODEL
model.fit(X, y)

# MAKE IN-SAMPLE PREDICTION FOR y and prob, AND PUT IT INTO A DATAFRAME
y_hat = model.predict(X)
prob = model.predict_proba(X)
#dfprob=pd.DataFrame(prob)

# STACK THE PREDICTIONS
in_sample=np.column_stack((y_hat,prob))
in_sample = pd.DataFrame(in_sample)
                
# GET RESULTS INTO STATA
# (NOTE: the first column is the prediction "y_hat")
D=Macro.getLocal("in_prediction") 
D=D+".dta"
in_sample.to_stata(D)

################################################################################
# MAKE OUT-OF-SAMPLE "LABEL" PREDICTION FOR y USING A PREPARED DATASET
################################################################################
D=Macro.getLocal("out_sample_x") 
D=D+".dta"
Xnew = pd.read_stata(D)
ynew = model.predict(Xnew)

# MAKE OUT-OF-SAMPLE "PROBABILITY" PREDICTION FOR y USING A PREPARED DATASET
prob_new = model.predict_proba(Xnew)
Prob_new  = pd.DataFrame(prob_new )

# EXPORT LABEL PREDICTION FOR y INTO AN EXCEL FILE
Ynew = pd.DataFrame(ynew)

# MERGE LABEL AND PROBABILITY PREDICTION FOR y INTO AN EXCEL FILE
# Use "numpy" to stack by column 'ynew' and 'prob_new'
out=np.column_stack((ynew,prob_new))
# Generate a dataframe 'OUT' from the previous array
OUT = pd.DataFrame(out)
                
# Get to the Stata (Excel) for results
# (NOTE: the first column is the prediction "y_hat")
D=Macro.getLocal("out_prediction") 
D=D+".dta"
OUT.to_stata(D)

# END
