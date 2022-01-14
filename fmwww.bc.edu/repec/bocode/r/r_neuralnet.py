################################################################################
#! "r_neuralnet.py": Neural network regression using Python Scikit-learn 
#! Author: Giovanni Cerulli
#! Version: 4
#! Date: 13 January 2022
################################################################################

# IMPORT NEEDED PACKAGES
from sklearn.neural_network import MLPRegressor
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
y

# DEFINE X THE FEATURES
X=df.iloc[:,1::]
X

# READ THE "SEED" FROM STATA
R=int(Macro.getLocal("seed"))

# ESTIMATE A "neuralnet" AT GIVEN PARAMETERS (JUST TO TRY IF IT WORKS)
model = MLPRegressor(solver='lbfgs', alpha=1e-5,hidden_layer_sizes=(5, 5), random_state=R)

# DEFINE THE PARAMETER VALUES THAT SHOULD BE SEARCHED FOR CROSS-VALIDATION
# 1. "NUMBER OF NEURONS FOR LAYER 1" 
# 2. "NUMBER OF NEURONS FOR LAYER 2" 
# 3. "RANDOM SEED" 

# CREATE A PARAMETER GRID AS A 2D "LIST" FOR NEURONS-LAYER-1 AND NEURONS-LAYER-2
grid=[]
for i in range(1,10,1):
  for j in range(1,6,1):
     g=(i,j)
     grid.append(g)
print(grid)

# GENERATE THE GRID (JUST ONE NUMBER) FOR THE "RANDOM SEED"	
gridR=[1]
	
# PUT THE GENERATED GRIDS INTO A PYTHON DICTIONARY 
param_grid={'hidden_layer_sizes': grid , 'random_state':gridR }
#print(param_grid)

# READ THE NUMBER OF CV-FOLDS "n_folds" FROM STATA
n_folds=int(Macro.getLocal("n_folds"))

# INSTANTIATE THE GRID
grid = GridSearchCV(model, param_grid, cv=n_folds, scoring='explained_variance', return_train_score=True)

# FIT THE GRID
grid.fit(X, y)

# VIEW THE RESULTS 
CV_RES=pd.DataFrame(grid.cv_results_)[['mean_train_score','mean_test_score','std_test_score']]
D=Macro.getLocal("cross_validation") 
D=D+".dta"
CV_RES.to_stata(D)

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

# PUT THE BEST PARAMETERS INTO STATA SCALARS
opt_nn=grid.best_params_.get('hidden_layer_sizes')
opt_neurons1=opt_nn[0]
opt_neurons2=opt_nn[1]
Scalar.setValue('OPT_NEURONS_L_1',opt_neurons1,vtype='visible')
Scalar.setValue('OPT_NEURONS_L_2',opt_neurons2,vtype='visible')

print("------------------------------------------------------")
print("The best estimator is:")
print(grid.best_estimator_)
print("------------------------------------------------------")
print("The best index is:")
print(grid.best_index_)
print("------------------------------------------------------")

################################################################################
# OUT-OF-SAMPLE PREDICTION
################################################################################

# TRAIN YOUR MODEL USING ALL DATA AND THE BEST KNOWN PARAMETERS
model=MLPRegressor(solver='lbfgs', alpha=1e-5,hidden_layer_sizes=opt_nn, random_state=R)

# FIT THE MODEL
model.fit(X, y)

# MAKE IN-SAMPLE PREDICTION FOR y, AND PUT IT INTO A DATAFRAME
y_hat = model.predict(X)
#print(y_hat)
D=Macro.getLocal("in_prediction") 
Data.addVarByte(D)
Data.store(D, None, y_hat)

################################################################################

# SET THE TRAIN/TEST DATASET AND THE NEW-INSTANCES-DATASET
D=Macro.getLocal("out_sample_x") 
D=D+".dta"

# LOAD A STATA DATASET LOCATED INTO THE DIRECTORY AS PANDAS DATAFRAME
#Xnew = pd.read_stata("data")
Xnew = pd.read_stata(D)

#print(Xnew)
ynew = model.predict(Xnew)
print(ynew)
type(ynew)

# EXPORT LABEL PREDICTION FOR y INTO AN EXCEL FILE
Ynew = pd.DataFrame(ynew)

# Generate a dataframe 'OUT' from the previous array
OUT = pd.DataFrame(Ynew)
                
# Get to the Stata (Excel) for results
# (NOTE: the first column is the prediction "y_hat")
D=Macro.getLocal("out_prediction") 
D=D+".dta"
OUT.to_stata(D)
################################################################################












