# -*- coding: utf-8 -*-
"""
Created on Tue Nov 25 13:21:39 2025

@author: Jan Kemper
"""

# packages
from scipy import stats # for Jarque bera test
import numpy as np
import pandas as pd
from sklearn.preprocessing import OneHotEncoder # For onehot encoding
#from numpy.linalg import inv # For OLS function without statsmodels in appendix
from sfi import Matrix, Data, Macro, Scalar # has to be activated to use python in stata but deactivated when using normal python
import statsmodels.api as sm
import warnings # module to generate warnings in python

#### General comment ######
# Python code does not run when sfi model is included in python, only works when stata calls the function.py file
# It has to be removed to run the python functions in isolation
# The core packages are numpy, pandas and sfi --> statsmodel, sklearn and scipy are used for robustness of their functions but could be replaced by numpy solution
####################################################################################
### Load OLS and Batch interence functions
####################################################################################

# overwrite function # can be removed later
def olsfun_residuals(X, Y):
    # OLS function with statsmodels --> could also be coded without statsmodels
    # With degrees of freedom correction for the residuals
    
    # number of observations and parameters
    n,k = X.shape

    # Fit OLS model
    model = sm.OLS(Y, X, missing='drop')
    results = model.fit()
	# OLS parameter estimates
    beta = results.params
    # OLS residuals
    resid = results.resid
    
    # variance of the error term
    sig2 = 1/(n-k) * np.sum(resid**2)
    # covariance matrix 
    Vw = results.cov_HC0

    return beta,Vw, sig2

def olsfun(X, Y):
    # OLS function with statsmodels --> could also be coded without statsmodels 
    # number of observations and parameters
    n,k = X.shape
    # OLS parameter estimates
    # Fit OLS model
    model = sm.OLS(Y, X, missing='drop')
    results = model.fit()
    
    # OLS parameter estimates
    beta = results.params
    # OLS residuals
    resid = results.resid
    
    # Variance of the error term
    sig2 = np.var(resid)
    
    # Heteroscedasticity robust covariance matrix
    Vw = results.cov_HC0
	
    return beta, Vw, sig2



###############################################################################
##### Algorithms
###############################################################################


def greedy_alg_k(list_of_true_means, list_of_true_standard_deviations, epsilon, number_batches, batch_size, exploration_phase = 0, decay=1):
    
    """
    This function implements an epsilon-greedy algorithm with decay for a multi-armed bandit problem.
    
    Parameters:
        - list_of_true_means: List of true mean rewards for each arm (bandit).
        - list_of_true_standard_deviations: List of true standard deviation for reward from the normal distribution
        - epsilon: Initial exploration probability, which decays over time.
        - number_batches: Total number of batches (iterations).
        - batch_size: Number of trials per batch.
        - exploration_phase: Number of initial batches where arms are chosen randomly (pure exploration).
        - decay: Decay rate applied to epsilon after each batch.
    
    Process:
        1. During the exploration phase, arms are selected randomly.
        2. After the exploration phase, the epsilon-greedy strategy is applied:
            - With probability (1 - epsilon), it exploits the arm with the highest estimated mean reward.
            - With probability epsilon, it explores other arms randomly.
        3. The mean rewards for each arm are updated after every batch based on the rewards received.
        4. The exploration probability (epsilon) decays by the given decay factor after each batch.
    
    Returns:
        A dictionary containing:
        - chosen_arm_list: The list of arms chosen in each trial.
        - rewards_list: The rewards received in each trial.
        - batch_indicator_list: The batch each trial belongs to.
        - mean_array: The updated mean rewards for each arm.
        - decay_rate: The list of epsilon values (decayed) over the batches.
"""

    
    # Initialization
    k = len(list_of_true_means)  # number of arms
    mean_array = np.zeros(k)  # initialization of mean array
    reward_total = np.empty(0, dtype=float)  # necessary for concatenation
    chosen_arm_total = np.empty(0, dtype=int)
    batch = np.repeat(np.arange(0, number_batches), batch_size)
    decay_list = []
    
    for t in range(0, number_batches):
        
        if t < exploration_phase:
            # During the exploration phase, choose arms randomly
            chosen_arm = np.random.choice(np.arange(0, k), batch_size)
            decay_list.append(epsilon)
        else:
            # Epsilon decay
            epsilon = decay * epsilon
            decay_list.append(epsilon)
            
            # Determine the number of exploit and explore actions
            #exploit_size = round((1 - epsilon) * batch_size)
            #explore_size = round(epsilon * batch_size)
            # Correct exploit/explore sizes (avoids rounding error)
            exploit_size = int((1 - epsilon) * batch_size)
            explore_size = batch_size - exploit_size  # ensures total matches batch_size
        
            # Exploit: Choose the arm with the highest mean value
            exploit = np.random.choice(np.flatnonzero(mean_array == mean_array.max()), exploit_size, replace=True)
            
            # Explore: Randomly choose an arm
            explore = np.random.choice(np.arange(0, k), explore_size)
            
            # Combine exploit and explore choices
            chosen_arm = np.concatenate((exploit, explore))
        
        # Initialize rewards array
        reward = np.zeros(batch_size, dtype=float)  
                 
        # Loop through chosen arms to calculate rewards
        for i in range(k):
            random_numbers = np.random.normal(list_of_true_means[i], list_of_true_standard_deviations[i], size=(chosen_arm == i).sum())
            reward[chosen_arm == i] = random_numbers

        # Save values in arrays
        reward_total = np.concatenate((reward_total, reward))
        chosen_arm_total = np.concatenate((chosen_arm_total, chosen_arm))
        
        # Calculate mean array
        for i in range(k):
            arr1_filtered = reward_total[chosen_arm_total == i]
            if len(arr1_filtered) == 0:
                raise ValueError(f"No rewards have been collected yet for arm {i} in batch {t}. Increase your batch size so that each arm is at least played once in the first batch.")
            
            mean_array[i] = arr1_filtered.mean()
            
        # Collect results
        results = {"chosen_arm_list": chosen_arm_total, 
                   "rewards_list": reward_total, 
                   "batch_indicator_list": batch, 
                   "mean_array": mean_array,
                   "decay_rate": decay_list}
    
    return results


def bernoulli_thompson_batched_clipping(
    true_prob,
    number_batches,
    batch_size,
    clipping_rate=0.05,
    exploration_phase_length=0,
    decay=1,
    plot_true: bool = False,
    clipping: bool = True
):

    """
This function implements batched Bernoulli Thompson Sampling with optional exact lower-bounded clipping for arm selection. It allocates plays to arms in batches, draws rewards, updates posterior Beta parameters, and tracks the experiment history.

Parameters:
    - true_prob: List of true success probabilities for each arm.
    - number_batches: Total number of batches to run.
    - batch_size: Number of plays per batch.
    - clipping_rate: Minimum probability allowed for any arm (default 0.05).
    - exploration_phase_length: Number of initial batches with uniform exploration (default 0).
    - decay: Multiplicative decay factor for the clipping rate after each batch (default 1).
    - plot_true: Flag to plot true probabilities (not used here, default False).
    - clipping: Whether to apply clipping (default True).

Process:
    1. Initializes Beta(1,1) priors for all arms.
    2. For each batch:
        a. Samples from the Beta posterior for each arm.
        b. Computes arm selection shares based on posterior samples.
        c. Applies exact lower-bounded clipping if enabled.
        d. Overrides with uniform allocation during the exploration phase.
        e. Converts shares to integer allocations, correcting rounding errors to match the batch size.
        f. Draws rewards from Binomial distributions for each arm.
        g. Updates Beta posterior parameters.
        h. Records batch-level and play-level outcomes, including rewards, chosen arms, and clipping rates.
        i. Applies decay to the clipping rate if specified.

Returns:
    A dictionary containing:
    - Posterior samples, Beta parameters, chosen arms, rewards, batch indicators, and clipping rates for all batches.
"""


    number_arms = len(true_prob)

    # 1) initialize Beta priors
    alpha_values = [1] * number_arms
    beta_values = [1] * number_arms

    # storage
    chosen_arm_total = []
    reward_total = []
    batch_indicator = []
    chosen_arm_list = []
    rewards_list = []
    batch_indicator_list = []
    alpha_values_list = []
    beta_values_list = []
    clipping_rate_list = []

    for t in range(number_batches):

        # store prior state
        alpha_values_list.append(alpha_values.copy())
        beta_values_list.append(beta_values.copy())

        # sample from posterior
        beta_sample = np.random.beta(
            alpha_values, beta_values, size=(1, batch_size, number_arms)
        )

        # choose arm with highest sampled value
        max_arm = np.argmax(beta_sample[0], axis=1)
        counts = np.bincount(max_arm, minlength=number_arms)

        shares = counts / counts.sum()

        # -------------------------
        # Exact lower-bounded clipping
        # -------------------------
        if clipping:

            if number_arms * clipping_rate > 1:
                raise ValueError(
                    f"Clipping infeasible, clipping larger than 1.: number_arms * clipping_rate = {number_arms * clipping_rate} > 1. Decrease the clipping rate."
                )

            clipped = shares < clipping_rate
            shares_new = shares.copy()

            # Set clipped arms exactly to clipping rate
            shares_new[clipped] = clipping_rate

            # Remaining probability mass
            remaining_mass = 1.0 - clipped.sum() * clipping_rate

            if remaining_mass < 0:
                raise RuntimeError("Negative remaining mass after clipping")

            # Redistribute proportionally among unclipped arms
            if (~clipped).any():
                shares_new[~clipped] *= remaining_mass / shares[~clipped].sum()
            else:
                # Edge case: all arms clipped
                shares_new[:] = 1.0 / number_arms

            shares = shares_new

        # exploration phase override
        if t < exploration_phase_length:
            shares[:] = 1 / number_arms

        # convert shares to integer batch allocations
        chosen_arms = (shares * batch_size).round().astype(int)

        # correct rounding drift to preserve batch size
        diff = batch_size - chosen_arms.sum()
        chosen_arms[np.argmax(chosen_arms)] += diff

        # final safety
        chosen_arms = np.maximum(chosen_arms, 0)

        # -------------------------
        # draw rewards and update posteriors
        # -------------------------
        reward_batch = 0
        batch_rewards_list = []
        batch_chosen_arm_list = []

        for k in range(number_arms):
            reward = np.random.binomial(chosen_arms[k], true_prob[k])

            alpha_values[k] += reward
            beta_values[k] += chosen_arms[k] - reward

            reward_batch += reward

            # expand rewards into 0/1 list
            reward_format = reward * [1]
            failure_format = (chosen_arms[k]- reward) * [0]
            arm_k_rewards = reward_format + failure_format
            batch_rewards_list.extend(arm_k_rewards)
            batch_chosen_arm_list.extend([k] * chosen_arms[k])

        # bookkeeping
        batch_indicator_list.extend([t] * len(batch_chosen_arm_list))
        chosen_arm_list.extend(batch_chosen_arm_list)
        rewards_list.extend(batch_rewards_list)

        reward_total.append(reward_batch)
        chosen_arm_total.append(chosen_arms)
        batch_indicator.append(t)
        clipping_rate_list.append(clipping_rate)

        # decay clipping rate
        clipping_rate *= decay

    results = {
        "beta_sample": beta_sample,
        "alpha_values": alpha_values,
        "beta_values": beta_values,
        "alpha_values_list": alpha_values_list,
        "beta_values_list": beta_values_list,
        "chosen_arm_total": chosen_arm_total,
        "reward_total": reward_total,
        "batch_indicator": batch_indicator,
        "rewards_list": rewards_list,
        "chosen_arm_list": chosen_arm_list,
        "batch_indicator_list": batch_indicator_list,
        "clipping_rate_list": clipping_rate_list,
    }

    return results


def classic_experiment(list_of_true_means, n):
    
    """
This function simulates a classic (non-adaptive) multi-armed bandit experiment by drawing rewards from normal distributions for each arm and randomly selecting an arm at each time step.

Parameters:
    - list_of_true_means: List of true mean rewards for each arm.
    - n: Number of time steps (length of the simulation).

Process:
    1. Generates an (n × k) matrix of normally distributed rewards, where each column corresponds to an arm and each row to a time step.
    2. Randomly selects one arm for each time step.
    3. Records the reward obtained from the chosen arm at each step.

Returns:
    - chosen_values: Array of rewards collected from the randomly chosen arms over `n` time steps.
"""

    
    #n = length of result vector in previous simulation
    k = len(list_of_true_means)
    samples = np.random.normal(loc=list_of_true_means, size=(n, k))
    chosen_indices = np.random.choice(k, size=n)
    chosen_values = samples[np.arange(n), chosen_indices]

    return chosen_values
    


################################################################################
######## Inference
###############################################################################

def bols_k_arms(chosen_arm, reward, batch, reference_arm = 0, arm = 1, test_value = 0):
    
    """
    This function performs a batch-wise regression analysis for comparing two arms (arm and reference_arm) in a multi-armed bandit setting using Ordinary Least Squares (OLS). It computes the difference in mean rewards between the two arms, provides statistical tests, and analyzes the results over multiple batches.
    
    Parameters:
        - chosen_arm: List of arms chosen during the trials.
        - reward: List of rewards received for each trial.
        - batch: List indicating the batch number for each trial.
        - reference_arm: The arm used as the reference for comparison (default: 0).
        - arm: The arm of interest to compare against the reference_arm (default: 1).
        - test_value: Hypothetical value for hypothesis testing, default is 0 (used for significance testing).
    
    Process:
        1. Filters the data to keep only observations where the chosen arm is either the arm of interest or the reference arm.
        2. Encodes the arms as dummy variables to prepare for regression.
        3. Runs a total regression on the full dataset to estimate the overall difference in mean rewards (beta) between the two arms, as well as the total regression variance.
        4. For each batch:
            - Slices the data by batch and runs a separate OLS regression to estimate the batch-specific coefficients and regression variance.
            - Calculates the test statistic for each batch, comparing the mean difference (beta) with the test_value using the batch-specific and total variances.
            - Counts the number of trials for each arm within each batch.
        5. Computes the overall test statistic (BOLS) by aggregating the batch-specific test statistics.
        6. Also computes a weighted test statistic and other summary statistics.
    
    Returns:
        A dictionary containing:
        - beta: The overall difference in mean rewards between the arm of interest and the reference arm.
        - bols_test_statistic: The BOLS test statistic calculated over all batches.
        - n_total: The total number of observations.
        - N_k_list, N_c_list: The number of trials for the arm of interest and the reference arm in each batch.
        - reg_var_total: The total regression variance.
        - N_k_total, N_c_total: The total number of trials for the arm of interest and reference arm, respectively.
        - beta_list: The batch-specific beta coefficients.
        - test_static_batch: The test statistic for each batch.
        - number_batches: The total number of batches.
        - beta_norm: The normalized beta coefficient (difference in means divided by standard error).
        - weights_list: The weights applied to each batch for aggregation.
        - beta_var: The variance-covariance matrix of the regression coefficients.
        - beta_test_statistic: The test statistic comparing beta against the test_value.
    """
    
    # Get number of batches
    number_batches = len(np.unique(batch))
    # Combine into one ndarry
    data_full =  np.array([chosen_arm, reward, batch]).T
    # Remove all rows which do not include arm k or reference arm
    data_full = data_full[np.where((data_full[:,0] == arm) | (data_full[:,0] == reference_arm))]
    # Calculate number of observations
    obs = len(data_full)
    # Get dummy variables
    encoder = OneHotEncoder()
    one_hot_arr = encoder.fit_transform(data_full[:, 0].reshape(-1, 1)).toarray()
    # find reference arm - if arm k > ref arm, then the reference arm is column 0
    if arm > reference_arm:
        one_hot_arr[:,0] = np.ones(obs) # works only for equal batch size # why? should work for all because it acts as constant
    else:
        one_hot_arr[:,1] = np.ones(obs)
        one_hot_arr = one_hot_arr[:, [1,0]] # changes order
        
    # Join dummy variables with main set
    data_full = np.append(data_full, one_hot_arr, axis = 1)
    
    # Total regression
    beta_all, beta_var, reg_var_total = olsfun(one_hot_arr, data_full[:, 1]) # get total mean difference and regression variance
    #beta_all, reg_var_total = olsfun_residuals(one_hot_arr, data_full[:, 1])
    beta = beta_all[1] # only coefficient of interest --> mean diff between arm k and arm reference
    # coefficient 1 
    beta_norm = beta/ np.sqrt(beta_var[1,1])
    
    # heteroscedastic var
    chosen_arm_list_filtered = one_hot_arr.sum(axis=1) # get one colum with chosen arm after non relevant arms were removed
    df_var = pd.DataFrame({'arm': chosen_arm_list_filtered, 'reward': data_full[:, 1]})
    # pandas.Series.var uses ddof=1 by default
    var_heteroscedastic = df_var.groupby('arm')['reward'].var()
    reg_var_arm_c = var_heteroscedastic.iloc[0]
    reg_var_arm_k = var_heteroscedastic.iloc[1]
    
    ### Calculate batches
    # Intialize variables of importance
    beta_list = np.zeros(number_batches) # coefficient per batch
    reg_var = np.zeros(number_batches) # Regression variance per batch
    test_static_batch = np.zeros(number_batches) # test statistic per batch
    N_k_list, N_c_list = np.zeros(number_batches), np.zeros(number_batches) # counts
    test_static_batch_no_normalization = np.zeros(number_batches) # test how normalization affects results
    weights_list_homo = np.zeros(number_batches) # save weights
    skipped_batches = []
    test_statistic_batch_list = []
    w_list = []
    
    for t in range(number_batches):
        
        # Slice specific batch t
        data_batch = data_full[np.where(data_full[:,2] == t)] # assumes first batch is 0
        
        # get counts per batch
        N_k = np.count_nonzero(data_batch[:, 0] == arm) # Count arm of interest in batch t
        N_c = np.count_nonzero(data_batch[:, 0] == reference_arm) # Count reference arm
        N_k_list[t], N_c_list[t] = N_k, N_c
        
        # Run regression -> but check first if sufficient observation for estimating sigma hat
        if N_k + N_c <=2:
            print(f"Batch {t} skipped because the number of observations was less than 3.")
            skipped_batches.append(t)
            w_list.append(np.nan)
            continue
            
        beta_t, beta_reg_t, reg_var_t = olsfun_residuals(data_batch[:, 3:5], data_batch[:, 1],) 
        beta_list[t] = beta_t[1] # batch specific coefficients
        reg_var[t] = reg_var_t # save regression variance
        
        # calculate test statistic by batch
        # take either batch specific variance or total variance - here batch specific
        #test_static_batch[t] = np.sqrt((N_k * N_c)/ ((N_k+N_c)*reg_var[t]))*(beta_list[t]-test_value)
        # total variance
        test_static_batch[t] = np.sqrt((N_k * N_c)/ ((N_k+N_c)*reg_var_total))*(beta_list[t]-test_value)
        weights_list_homo[t] = np.sqrt((N_k * N_c)/ (N_k+N_c))
        #print(beta_t, beta_list[t], reg_var[t], N_k, N_c, test_static_batch[t])
        # Heteroskedastic test statistic
        # If either arm is zero → skip and warn
        if N_k == 0 or N_c == 0:
            #warnings.warn(f"Batch {t} skipped because n_k={N_k}, n_r={N_c}")
            print(f"Batch {t} skipped because one of the arms was zero: n_k={N_k}, n_r={N_c}")
            skipped_batches.append(t)
            w_list.append(np.nan)
            continue

        se_t = np.sqrt((reg_var_arm_k / N_k) + (reg_var_arm_c / N_c))
        test_statistic_batch_list.append((beta_t[1] - test_value) / se_t)
        w_list.append(1/se_t)
    
    
    # estimator
    S = np.nansum(w_list) # denominator of weight - ignores nan
    weights_hetero = w_list / S
    bols_estimate_hetero = np.nansum(beta_list * weights_hetero)
    se = np.sqrt(len(test_statistic_batch_list))/ S # Standard error as in our paper # ignores batches without the arm being played
    # Bols test statistic heteroskedasticity
    bols_test_statistic_heteroskedastic = (1 / np.sqrt(len(test_statistic_batch_list))) * np.sum(test_statistic_batch_list)
    if len(test_statistic_batch_list) == 0:
        print("No batch test statistic calculated")
        bols_test_statistic_heteroskedastic = np.nan # If non of the batched test statistic can be caluclated (any arm not played), set it na
    # Calculate confidence interval
    c = 1.96
    C_low = bols_estimate_hetero - 1.96 * se 
    C_high = bols_estimate_hetero + 1.96 * se 
    
    # homoskedasticity
    bols_test_statistic_homoskedastic = (1/np.sqrt(number_batches))*np.sum(test_static_batch)
    # Get some total statistics
    N_k_total = np.sum(N_k_list)
    N_c_total = np.sum(N_c_list)
    n_total = N_k_total + N_c_total
    weights_list_homo = weights_list_homo/np.sum(weights_list_homo)
    beta_test = (beta - test_value)/(np.sqrt(beta_var[1,1])) # test statistic vs H0

    results = {"beta": beta,
               "bols_estimate_hetero": bols_estimate_hetero,
               "standard_error_bols_hetero": se,
               "bols_test_statistic_homoskedastic": bols_test_statistic_homoskedastic,
               "bols_test_statistic_heteroskedastic": bols_test_statistic_heteroskedastic,
               "C_low": C_low,
               "C_high": C_high,
               "n_total": n_total,
               "N_k_list": N_k_list,
               "N_c_list": N_c_list,
               "reg_var_total": reg_var_total,
               "N_k_total": N_k_total,
               "N_c_total": N_c_total,
               "beta_list": beta_list,
               "test_static_batch": test_static_batch,
               "number_batches": number_batches,
               "beta_norm": beta_norm,
               "weights_list_homo": weights_list_homo,
               "weights_hetero": weights_hetero,
               "beta_var": beta_var,
               "beta_test_statistic": beta_test}
     
    return results

# calculate confidence intervals

def confidence_inverval_algebra_k(N_k_list, N_c_list, sigma, number_batches, beta_list):
    
    """
This function calculates the confidence interval for the mean difference between two arms (arm of interest and reference arm) over multiple batches in a multi-armed bandit setting using BOLS regression. The function computes the lower and upper bounds of the confidence interval based on the standard error and the normal distribution.

Parameters:
    - N_k_list: List of the number of trials for the arm of interest in each batch.
    - N_c_list: List of the number of trials for the reference arm in each batch.
    - sigma: Estimated variance of the regression.
    - number_batches: Total number of batches.
    - beta_list: List of the mean differences (beta coefficients) between the arm of interest and the reference arm in each batch.

Process:
    1. The function first calculates the total number of trials (`n_t`) in each batch by summing the trials for the arm of interest (`N_k_list`) and the reference arm (`N_c_list`).
    2. Computes the square root of the product of `N_k_list` and `N_c_list`, divided by `n_t` for each batch.
    3. Using the above components, it calculates the confidence interval bounds:
        - `C_low`: The lower bound of the confidence interval.
        - `C_high`: The upper bound of the confidence interval.
        These are based on a 95% confidence level (using the constant `c = 1.96`), the standard error, and the aggregated batch coefficients (`beta_list`).
    4. Additionally, the function calculates the static component, which represents the weighted average of the batch-specific beta values.
    5. The function calculates the weights for the weighted average BOLS
Returns:
    A dictionary containing:
    - C_low: The lower bound of the confidence interval.
    - C_high: The upper bound of the confidence interval.
    - static_component: The weighted average of the batch-specific beta values.
"""
    
    c = 1.96
    # calculat n_t --> k and reference arm count in batch t
    n_t = N_k_list + N_c_list

    # calculate components individually
    list_k_c_squared = np.sqrt(N_k_list*N_c_list/n_t)
        
    # denominator
    
    C_low = (-c*np.sqrt(number_batches * sigma))/ (sum(list_k_c_squared)) + (sum(list_k_c_squared * beta_list)) / (sum(list_k_c_squared)) 
    C_high = (c*np.sqrt(number_batches * sigma))/ (sum(list_k_c_squared)) + (sum(list_k_c_squared * beta_list)) / (sum(list_k_c_squared)) 

    static_component = (sum(list_k_c_squared * beta_list)) / (sum(list_k_c_squared))
    w_total = (sum(list_k_c_squared))
    weights = list_k_c_squared/w_total
    
    results = {"C_low": C_low, "C_high": C_high, "static_component": static_component, "weights": weights}
    return results 


def bols_inference_k(dataframe, chosen_arm: str, reward: str, batch: str, reference_arm = 0, test_value = 0, plot = False):
    
    
    """
This function performs inference using Batch Ordinary Least Squares (BOLS) for a multi-armed bandit experiment. It compares each arm to a reference arm using regression-based methods and calculates statistics like beta coefficients, z-values, p-values, and confidence intervals.

Parameters:
    - dataframe: Pandas DataFrame containing the experimental data.
    - chosen_arm: Column name for the arm selected in each trial.
    - reward: Column name for the rewards received.
    - batch: Column name for the batch or time period in which the trials occurred.
    - reference_arm: The arm used as the baseline for comparison (default is 0).
    - test_value: The null hypothesis value for the beta coefficient (default is 0).
    - plot: Boolean, if True, plots confidence intervals for BOLS estimates.

Process:
    1. The input data is preprocessed by converting relevant columns into integer types and transforming them into NumPy arrays.
    2. The function calculates BOLS test statistics for each arm compared to the reference arm using `bols_k_arms`.
    3. For each arm comparison, it:
        - Calculates confidence intervals using `confidence_inverval_algebra_k`.
        - Computes z-values, p-values, and confidence intervals.
        - Collects the total number of trials for both the treatment and reference arms.
        - Saves all results (OLS beta, aggregated BOLS beta, confidence intervals, etc.) in a Pandas DataFrame.
    4. Additional statistics are computed, including the optimal reward, actual reward, and uniform reward based on the experimental data.
    5. Optionally, the function plots confidence intervals for the BOLS estimates.

Returns:
    - results: DataFrame containing comparison results (Beta coefficients, z-values, p-values, confidence intervals).
    - ereturn_results: Dictionary with additional summary statistics, including the optimal and actual rewards, and the mean rewards for uniform and reference strategies.
"""

    
    dataframe[chosen_arm] = dataframe[chosen_arm].astype('int') 
    dataframe[batch] = pd.factorize(dataframe[batch])[0].astype('int') #+ 1
    reward, chosen_arm, batch = dataframe[reward], dataframe[chosen_arm], dataframe[batch]
    
    # transform input to numpy arrays
    chosen_arm, reward, batch = np.array(chosen_arm), np.array(reward), np.array(batch)
    
    # find number of arms
    number_arms = np.max(chosen_arm)  +1
    
    # initiate empty lists
    comparison_string_list = []
    beta_ols = []
    beta_BOLS_agg = []
    z_value = []
    p_value_list = []
    ci_lower_bound = []
    ci_upper_bound = []
    treatment_arm_n = []
    reference_arm_n = []
    weights_list = []
    se_bols = []
    # iterate through arms
    batch_beta = []
    arm_indicator_list = []
    
    for i in range(number_arms):
        
        if i == reference_arm:
            pass
        #Main result
        else:
            print(f"BOLS calculation for arm: {i}")
            t =  bols_k_arms(chosen_arm, reward, batch, reference_arm, i, test_value)
            #c =confidence_inverval_algebra_k(t["N_k_list"], t["N_c_list"], t["reg_var_total"], t["number_batches"] ,t["beta_list"])
            p_value = 2*(1 - stats.norm.cdf(abs(t["bols_test_statistic_heteroskedastic"])))
            
            # save all important results into 1 pandas dataframe
            # comparison string ,beta OLS, beta aggregated BOLS, z-value, p-value, confidence intervall 95 %, n-obs k, n-obs r
            comparison_string = "Arm " + str(i) + " vs. " + "Arm " + str(reference_arm)
            comparison_string_list.append(comparison_string)
            beta_ols.append(t["beta"])
            beta_BOLS_agg.append(t["bols_estimate_hetero"])
            z_value.append(t["bols_test_statistic_heteroskedastic"])
            p_value_list.append(p_value)
            ci_lower_bound.append(t["C_low"])
            ci_upper_bound.append(t["C_high"])
            treatment_arm_n.append(t["N_k_total"])
            reference_arm_n.append(t["N_c_total"])
            batch_beta.append(t["beta_list"])
            weights_list.append(t["weights_hetero"])
            se_bols.append(t["standard_error_bols_hetero"])
            arm_indicator_list.append(i)

    results = pd.DataFrame({"Comparison": comparison_string_list, "Beta_OLS": beta_ols, "Beta_BOLS_aggregated": beta_BOLS_agg, "Z-value": z_value, 
                            "P-value": p_value_list, "CI_lower_bound_95": ci_lower_bound, "CI_upper_bound_95": ci_upper_bound, 
                            "Treatment_arm_n": treatment_arm_n, "Reference_arm_n": reference_arm_n, "Standard_error_BOLS": se_bols, "Arm_indicator": arm_indicator_list})
    
    # Transfrom results for stata ereturn --> higher dimensions as above
    mean_list = [] # Necessary to consider also the reference arm
    n = dataframe.shape[0]
    mean_ref = dataframe[dataframe['chosen_arm'] == reference_arm]["reward"].mean()
    actual_reward = dataframe["reward"].sum()
    actual_reward_mean = dataframe["reward"].mean()
    mean_list = results["Beta_OLS"] + mean_ref
    mean_list = mean_list.tolist() # has to be transformed to list to append
    mean_list.append(mean_ref) # Full list of arm means
    uniform_reward_mean = np.mean(mean_list)
    uniform_reward = uniform_reward_mean * n
    optimal_mean = np.array(mean_list).max()
    optimal_reward = n * optimal_mean
    batch_beta = np.array(batch_beta).T
    weights = np.array(weights_list).T
    ereturn_results = {"batch_beta": batch_beta, 
                       "n": n,
                       "mean_ref": mean_ref,
                       "optimal_mean": optimal_mean,
                       "optimal_reward": optimal_reward,
                       "actual_reward": actual_reward,
                       "actual_reward_mean": actual_reward_mean,
                       "uniform_reward_mean": uniform_reward_mean,
                       "uniform_reward": uniform_reward,
                       "weights_bols": weights}
    
    if plot == True:
    # Now plot it - only for python in isolation
        plot_confidence_intervals(results.Beta_BOLS_aggregated,
        results.CI_lower_bound_95,
        results.CI_upper_bound_95,
        results.Comparison)
    else:
        pass
    
    return results, ereturn_results

#########################################################################
####### Simulation functions
########################################################################



def simulation_greedy(N, list_of_true_means, list_of_true_standard_deviations, epsilon,number_batches, batch_size, exploration_phase = 0, decay = 1, reference_arm = 0, arm = 1, test_value = 0):
    
    """
This function simulates the performance of a greedy algorithm in a multi-armed bandit setting over N repetitions and performs Batch Ordinary Least Squares (BOLS) inference to evaluate the statistical properties of the algorithm.

Parameters:
    - N: Number of simulation repetitions.
    - list_of_true_means: List containing the true mean rewards for each arm.
    - epsilon: Exploration rate used in the greedy algorithm.
    - number_batches: Number of batches in each simulation run.
    - batch_size: Size of each batch in the simulation.
    - exploration_phase: Number of initial batches dedicated to pure exploration (default is 0).
    - decay: Decay factor applied to epsilon after each batch (default is 1).
    - reference_arm: The arm to be used as the baseline for comparison in BOLS (default is 0).
    - arm: The arm being compared to the reference arm (default is 1).
    - test_value: The null hypothesis value for the beta coefficient (default is 0).

Process:
    1. The function runs N simulations of the greedy algorithm (`greedy_alg_k`) using the specified parameters.
    2. For each simulation run, it applies Batch OLS (`bols_k_arms`) to compare the specified arm to the reference arm.
    3. Collects two key statistics for each simulation:
        - BOLS test statistic.
        - Beta test statistic.
    4. After N simulations, it compiles the results into a dictionary.

Returns:
    - results: A dictionary containing lists of:
        - 'bols_test_statistic': The BOLS test statistic for each simulation.
        - 'beta_test_statistic': The beta test statistic for each simulation.
"""

    
    bols_test_statistic_heteroskedastic = []
    beta_test_statistic = []
    # run function
    for i in range(N):
        results = greedy_alg_k(list_of_true_means, list_of_true_standard_deviations, epsilon,number_batches, batch_size, exploration_phase = 0, decay=1)
        simulation = bols_k_arms(results["chosen_arm_list"], results["rewards_list"], results["batch_indicator_list"], reference_arm = reference_arm, arm = arm, test_value = test_value)
        bols_test_statistic_heteroskedastic.append(simulation["bols_test_statistic_heteroskedastic"])
        beta_test_statistic.append(simulation["beta_test_statistic"])
        
    results = {"bols_test_statistic": bols_test_statistic_heteroskedastic, "beta_test_statistic": beta_test_statistic}
    return results



def simulation_thompson(N, list_of_true_means, number_batches, batch_size, clipping_rate = 0.05, exploration_phase = 0, reference_arm = 0, arm = 1, test_value = 0):
    
    """
This function simulates a Thompson Sampling algorithm with batched clipping in a multi-armed bandit setting over N repetitions. It performs Batch Ordinary Least Squares (BOLS) inference to evaluate the statistical properties of the algorithm and gathers additional metrics related to arm selection.

Parameters:
    - N: Number of simulation repetitions.
    - list_of_true_means: List containing the true mean rewards for each arm.
    - number_batches: Number of batches in each simulation run.
    - batch_size: Size of each batch in the simulation.
    - clipping_rate: Minimum share assigned to any arm when clipping is applied (default is 0.05).
    - exploration_phase: Number of initial batches dedicated to pure exploration (default is 0).
    - reference_arm: The arm used as the baseline for comparison in BOLS (default is 0).
    - arm: The arm being compared to the reference arm (default is 1).
    - test_value: The null hypothesis value for the beta coefficient (default is 0).

Process:
    1. The function runs N simulations of Thompson Sampling with batched clipping using the specified parameters.
    2. For each simulation, it applies Batch OLS (`bols_k_arms`) to compare the specified arm to the reference arm.
    3. Tracks the following metrics for each simulation:
        - BOLS test statistic.
        - OLS test statistic.
        - Total counts of arm k (specified arm) and the reference arm.
    4. After N simulations, the function computes the ratio of how often the specified arm was played relative to the total of arm k and the reference arm.
    5. It also calculates rejection rates for both the beta test statistic and BOLS test statistic, based on a 95% confidence level (threshold of 1.96).

Returns:
    - results: A dictionary containing:
        - 'bols_test_statistic': The BOLS test statistic for each simulation.
        - 'beta_test_statistic': The beta test statistic for each simulation.
        - 'n_k_arm': Total count of how often the specified arm (k) was played.
        - 'n_r_arm': Total count of how often the reference arm was played.
        - 'ratio_played_arms': The ratio of how often arm k was played relative to the total of arm k and the reference arm.
        - 'share_rej_ols': Proportion of simulations where the beta test statistic exceeded 1.96 (rejected null hypothesis).
        - 'share_rej_bols': Proportion of simulations where the BOLS test statistic exceeded 1.96 (rejected null hypothesis).
"""

    
    bols_test_statistic = []
    beta_test_statistic = []
    n_k_arm = [] # how often arm k was played
    n_r_arm = [] # how often the reference arm was played
    
    # run function
    for i in range(N):
        results =  bernoulli_thompson_batched_clipping(list_of_true_means, number_batches, batch_size, clipping_rate, exploration_phase, plot_true= False, clipping= True)
        # Reference arm indicates which arms should be the "arm" be compared to
        simulation = bols_k_arms(results["chosen_arm_list"], results["rewards_list"], results["batch_indicator_list"], reference_arm = reference_arm, arm = arm, test_value = test_value)
        bols_test_statistic.append(simulation["bols_test_statistic_heteroskedastic"])
        beta_test_statistic.append(simulation["beta_test_statistic"])
        n_k_arm.append(simulation["N_k_total"])     
        n_r_arm.append(simulation["N_c_total"])
        
    ratio_played_arms = np.array(n_k_arm)/ (np.array(n_k_arm) + np.array(n_r_arm))
    #get rejection rates
    share_rej_ols = np.mean(np.abs(beta_test_statistic) > 1.96)
    share_rej_bols = np.mean(np.abs(bols_test_statistic) > 1.96)
    
    results = {"bols_test_statistic": bols_test_statistic, 
               "beta_test_statistic": beta_test_statistic,
               "n_k_arm": n_k_arm,
               "n_r_arm": n_r_arm,
               "ratio_played_arms": ratio_played_arms,
               "share_rej_ols": share_rej_ols,
               "share_rej_bols": share_rej_bols}
    return results




#########################################################################
######## Updating
#########################################################################

def thompson_updating(chosen_arm, reward, batch, batch_size,
                      clipping_rate = 0.05, clipping: bool = True):
    
    """
The function `thompson_updating` performs an arm-selection process using the Thompson Sampling approach, with optional clipping to ensure no arm is assigned a proportion of plays below a specified threshold. The process includes updating posterior distributions based on rewards and selecting arms based on draws from Beta distributions.

Parameters:
    - chosen_arm: A list or array indicating which arm was chosen in each round.
    - reward: A list or array of the rewards received from the chosen arms.
    - batch: A list or array indicating the batch in which the rewards were received.
    - batch_size: The number of arms to be selected in each batch.
    - clipping_rate: The minimum share assigned to any arm when clipping is applied (default is 0.05).
    - clipping: A boolean flag that controls whether to apply the clipping procedure (default is True).

Process:
    1. Inputs are combined into a NumPy array for easier processing.
    2. Alpha (success) and Beta (failure) values are computed for each arm based on historical rewards:
        - Alpha is the count of successes (rewards) for each arm.
        - Beta is the count of failures (non-rewards) for each arm.
    3. Alpha and Beta values are incremented by 1 to avoid zeros, ensuring a valid Beta distribution.
    4. Using these updated Alpha and Beta values, the function draws samples from the Beta distribution for each arm, simulating potential rewards.
    5. The arm with the maximum Beta sample in each of the batch iterations is selected.
    6. Counts and shares of selected arms are calculated, and if clipping is enabled:
        - Shares below the `clipping_rate` are adjusted to meet the minimum threshold.
        - Remaining share values are adjusted so that the total share sums to 1.
    7. The final number of times each arm is chosen is computed based on the adjusted shares and batch size.

Returns:
    - shares: The proportion of times each arm is selected in the batch after applying the clipping procedure.
    - chosen_arms: The final number of times each arm is selected in the batch, rounded to the nearest integer.
"""
    
    # process inputs
    # combine into one ndarry
    data_full =  np.array([chosen_arm, reward, batch],  dtype='int').T
    # get alpha and beta values from t
    # Use numpy.bincount to calculate the sum of rewards for each chosen_arm value
    alpha_values = np.bincount(data_full[:, 0], weights=data_full[:, 1])  # I added +1 to avoid 0 --> is that correct?
    beta_values = np.bincount(data_full[:, 0])-alpha_values 
    # add + 1 to avoid 0
    alpha_values += 1
    beta_values += 1    
    # get number of arms
    # Get the unique values in the chosen_arm column
    number_arms = np.unique(data_full[:, 0])
    # Get the number of unique values
    number_arms = len(number_arms)
    # draw many values from beta distribution
    beta_sample = np.random.beta(alpha_values, beta_values, size = (1, batch_size, number_arms))
    beta_sample[0]
    # get position (arm) of max value
    max_arm = np.argmax(beta_sample[0], axis = 1)
      
    # count how often each arm is played
    counts = np.bincount(max_arm, minlength = number_arms) # counts for every integer how often it appears
    # get shares
    total_sum = np.sum(counts)
    shares = (counts/total_sum)
    # clipping condition
    if clipping:
        # check that clipping rate total is less than 1
        if number_arms * clipping_rate > 1:
            raise ValueError(
                f"Clipping infeasible, clipping larger than 1.: number_arms * clipping_rate = {number_arms * clipping_rate} > 1. Decrease the clipping rate."
            )

        clipped = shares < clipping_rate
        shares_new = shares.copy()

        # Set clipped arms exactly to clipping rate
        shares_new[clipped] = clipping_rate

        # Remaining probability mass
        remaining_mass = 1.0 - clipped.sum() * clipping_rate

        if remaining_mass < 0:
            raise RuntimeError("Negative remaining mass after clipping")

        # Redistribute proportionally among unclipped arms
        if (~clipped).any():
            shares_new[~clipped] *= remaining_mass / shares[~clipped].sum()
        else:
            # Edge case: all arms clipped
            shares_new[:] = 1.0 / number_arms

        shares = shares_new

    # convert shares to integer batch allocations
    chosen_arms = (shares * batch_size).round().astype(int)
    # final safety
    chosen_arms = np.maximum(chosen_arms, 0)
    # correct rounding drift to preserve batch size
    diff = batch_size - chosen_arms.sum()
    chosen_arms[np.argmax(chosen_arms)] += diff

    return shares, chosen_arms



def epsilon_greedy_updating(chosen_arm, reward, batch, batch_size,
                      epsilon = 0.1):
    
    """
   Implements an epsilon-greedy strategy for updating arm choices in a multi-armed bandit problem.
   
   Parameters:
   chosen_arm : numpy array
       Current choices of arms.
   reward : numpy array
       Corresponding rewards for each chosen arm.
   batch_size : int
       Total number of arms to select.
   epsilon : float, optional
       Exploration-exploitation parameter. Default is 0.1.
       
   Returns:
   shares : numpy array
       Proportion (shares) of each arm chosen.
   chosen_arm : numpy array
       Shuffled list of chosen arms reflecting the epsilon-greedy strategy.
   """
    
    # get exploitation and exploration size
    exploit_size = (1-epsilon) * batch_size
    explore_size = epsilon * batch_size
     
    # Convert to integers by rounding
    exploit_size = round(exploit_size)
    explore_size = round(explore_size)
    
    # Adjust to ensure the sum is exactly batch_size
    while exploit_size + explore_size > batch_size:
        if exploit_size > explore_size:
            exploit_size -= 1
        else:
            explore_size -= 1
    
    while exploit_size + explore_size < batch_size:
        if exploit_size < explore_size:
            exploit_size += 1
        else:
            explore_size += 1
        
    ### Calculate current mean value
    chosen_arm = chosen_arm.astype(int)
    # Calculate the sum of rewards for each arm
    sum_rewards = np.bincount(chosen_arm, weights=reward)
    # Calculate the count of rewards for each arm
    count_rewards = np.bincount(chosen_arm)
    # Calculate the mean rewards
    mean_rewards = sum_rewards / count_rewards
    # Exploit: Choose the arm with the highest mean value
    exploit_arm = np.random.choice(np.flatnonzero(mean_rewards == mean_rewards.max()), exploit_size, replace=True)
    # number of arms
    number_arms = len(np.unique(chosen_arm))
    # Explore: Randomly choose an arm
    explore_arms = np.random.choice(np.arange(0, number_arms), explore_size)
    
    # Combine exploit and explore choices
    chosen_arm = np.concatenate((exploit_arm, explore_arms))
    # get randomization by randomly reshuffling the order
    np.random.shuffle(chosen_arm) # should not be assigned, seems to be a method rather than a function
    # shares
    unique_values, counts = np.unique(chosen_arm, return_counts=True)
    # Calculate shares
    total_count = len(chosen_arm)
    print("Total Counts: ", total_count)
    print("Arm Counts: ", counts)
    print("Current Arm Means", mean_rewards)
    shares = counts / total_count
    
    return shares, chosen_arm, unique_values


def esfandiari_batch_size_intialize(df,arms, batch):
    
    """
This function initializes batch sizes and data structures for a batched multi-armed bandit experiment following the schedule described in Esfandiari-style batched exploration. It assigns initial pulls for each arm in the first batch and prepares the dataframe to track rewards, batch indices, and chosen arms.

Parameters:
    - df: Pandas DataFrame that will store the experiment history. Its length determines the total time horizon.
    - arms: Total number of arms (K) in the bandit problem.
    - batch: Total number of batches (B) to divide the time horizon into.

Process:
    1. The function first translates the inputs into notation consistent with the theoretical setup:
        - `K` represents the number of arms.
        - `B` represents the total number of batches.
        - `T` is the total number participants in the experiments, taken as the number of rows in `df`.
    2. It computes the batch growth factor `q = T^(1/B)`, which determines how batch sizes increase geometrically across batches.
    3. For each batch `i = 1, ..., B`, it calculates the per-arm batch size as `floor(q^i)` and stores these values in `batch_size_list_arm`.
    4. The function initializes tracking columns in the dataframe:
        - `reward` for observed rewards (initialized as NaN),
        - `batch` for batch index,
        - `chosen_arm` for the arm selected at each time step.
    5. It assigns all time steps of the first batch:
        - The total size of the first batch is `K * batch_size_list_arm0`, where `batch_size_list_arm0` is the per-arm allocation for batch 1.
        - These rows are labeled as belonging to batch 1.
    6. Within the first batch, the function allocates an equal number of initial pulls to each arm by filling the `chosen_arm` column sequentially for each arm.
    7. It records all arms as initially active, since each arm is sampled in the first batch.

Returns:
    A dictionary containing:
    - df: The updated dataframe with initialized `reward`, `batch`, and `chosen_arm` columns.
    - batch_size_list_arm: A list of dictionaries specifying the per-arm sample size for each batch.
    - active_arms: A list of all arms that are active after initialization (initially all arms).
"""

    
    # to have consistent notation with the paper translate into paper notation
    K = arms
    B = batch
    T = len(df)
    q = T**(1/B)
    batch_size_list_arm = []
    for i in range(1, B+1):
        value = int(np.floor(q**i))
        batch_size_list_arm.append({"batch": i, "batch_size_arm": value})
    # generate dataframe
    df["reward"] = np.nan 
    df["batch"] = np.nan
    df["chosen_arm"] = np.nan
    # update batch value for the first batch
    # fill the first batch_size_batch0 rows with 0
    batch_size_list_arm0 = batch_size_list_arm[0]["batch_size_arm"] # played arm in first batch
    batch_size0 = K * batch_size_list_arm0
    df.loc[:batch_size0 - 1, [ "batch"]] = 1
    # Now fill the arms
    row = 0
    active_arms = []
    for arm in range(0, arms):
        df.loc[row : row + batch_size_list_arm0 - 1, "chosen_arm"] = arm
        row += batch_size_list_arm0
        active_arms.append(arm)
    
    results = {"df": df,
               "batch_size_list_arm": batch_size_list_arm,
               "active_arms": active_arms}
    return results


def esfandiari_update(df,arms, active_arms, batch):
    
    """
This function updates the state of a batched multi-armed bandit experiment using an elimination-based strategy based on theorem 1 in Esfandiari et al. (2021) multi-armed bandit exploration framework. It determines whether another full exploration batch can be run and eliminates suboptimal arms based on confidence bounds; otherwise, it switches to exploitation of the best empirical arm.

Parameters:
    - df: Pandas DataFrame containing the experiment history, including chosen arms, observed rewards, and batch assignments.
    - arms: Total number of arms (K) in the bandit problem.
    - active_arms: List of arms that are still active (not eliminated) at the current stage.
    - batch: Total number of batches (B) planned for the experiment.

Process:
    1. The function maps inputs to theoretical notation:
        - `K` is the total number of arms.
        - `B` is the total number of batches.
        - `T` is the time horizon, equal to the number of rows in `df`.
    2. It computes the geometric batch growth factor `q = T^(1/B)` and reconstructs the per-arm batch sizes for all batches as `floor(q^i)` for `i = 1, ..., B`.
    3. The current batch is identified from the `batch` column of the dataframe, and the next batch index is determined.
    4. The function calculates how many time steps remain unassigned (`T_remain`) and checks whether there is enough remaining horizon to run the next exploration batch with all currently active arms.
    5. If there is enough horizon left:
        a. It computes the empirical mean reward for each active arm using past observations.
        b. It calculates the total number of samples per arm so far (`c_i`) across completed batches.
        c. A confidence threshold is formed:
           max_mean − sqrt(2 * log(2*K*T*B) / c_i),
           where `max_mean` is the highest empirical mean among active arms.
        d. Arms with empirical means below this threshold are eliminated.
        e. The next batch is scheduled by:
            - Assigning the appropriate batch index to the next set of unfilled rows.
            - Allocating an equal number of pulls in this batch to each remaining active arm.
    6. If there is not enough horizon left to run another full batch:
        a. The function computes empirical mean rewards for active arms.
        b. It identifies the arm with the highest empirical mean reward.
        c. Instead of scheduling a new exploration batch, the function signals that the remaining horizon should exploit this best arm.

Returns:
    A dictionary containing:
    - df: The updated dataframe with new batch assignments and chosen arms if a new batch is scheduled.
    - batch_size_list_arm: A list of dictionaries specifying the per-arm sample size for each batch (NaN if no further batch is scheduled).
    - active_arms: The updated list of active arms after elimination (unchanged if no elimination occurs).
    - arm_max_reward (only in the exploitation case): The arm with the highest empirical mean reward to be played for the remaining horizon.
"""
    
    # to have consistent notation with the paper translate into paper notation
    K = arms
    B = batch
    T = len(df)
    q = T**(1/B)
    

    batch_size_list_arm = []
    batch_size_list_values = []
    for i in range(1, B+1):
        value = int(np.floor(q**i))
        batch_size_list_arm.append({"batch": i, "batch_size_arm": value})
        batch_size_list_values.append(value)

    # determine current batch
    current_batch = int(max(np.unique(df["batch"])))
    print(f"current batch: {current_batch}")
    next_batch = current_batch +1
    current_q = batch_size_list_arm[current_batch-1]["batch_size_arm"]
    next_q = batch_size_list_arm[next_batch-1]["batch_size_arm"]
    print(f"next q: {next_q}")
    A = len(active_arms)
    # T calculate remaining
    T_remain = df["batch"].isna().sum()
    print(f"T remain: {T_remain}")
    # Eliminate arm
    if next_q * A < T_remain:
        
        print("Continue")
        
        reward_by_arm = (
            df[df["chosen_arm"].isin(active_arms)]
            .groupby("chosen_arm")["reward"]
            .mean()
            )
        # Convert into a dataframe for easier calculations
        reward_by_arm = reward_by_arm.reset_index()
        reward_by_arm["chosen_arm"] = reward_by_arm["chosen_arm"].astype(int)
        # Determine c_i
        c_i = sum(batch_size_list_values[:current_batch])
        max_mean = reward_by_arm["reward"].max()
        # compute threshold
        threshold = max_mean - np.sqrt(2 * np.log(2*K*T*B) / c_i)        
        # add elimination column
        reward_by_arm["eliminated_arms"] = reward_by_arm["reward"] < threshold
        number_eliminated_arms = sum(reward_by_arm["eliminated_arms"])
        # Save active arms
        active_arms_new = reward_by_arm.loc[
                ~reward_by_arm["eliminated_arms"], 
                "chosen_arm"
            ].tolist()
        number_active_arms = (~reward_by_arm["eliminated_arms"]).sum()
        # fill the first batch_size_batch0 rows with 0
        batch_size_list_arm_next = batch_size_list_arm[next_batch-1]["batch_size_arm"] # played arm in first batch
        batch_size_next = number_active_arms * batch_size_list_arm_next
        # 1. find the first index where batch is NaN
        start = df["batch"].isna().idxmax()   # first NaN position
        # 2. fill the next batch_size_next rows with the batch number
        df.loc[start : start + batch_size_next - 1, "batch"] = next_batch
        # Now fill the arms

        for arm in active_arms_new:
            #print(arm)
            df.loc[start : start + batch_size_list_arm_next - 1, "chosen_arm"] = arm
            start += batch_size_list_arm_next
        # return results
        results = {"df": df,
                   "batch_size_list_arm": batch_size_list_arm,
                   "active_arms": active_arms_new}
        return results
        
    else:
        reward_by_arm = (
            df[df["chosen_arm"].isin(active_arms)]
            .groupby("chosen_arm")["reward"]
            .mean()
            )
        # Convert into a dataframe for easier calculations
        reward_by_arm = reward_by_arm.reset_index()
        reward_by_arm["chosen_arm"] = reward_by_arm["chosen_arm"].astype(int)
        # Determine c_i
        c_i = sum(batch_size_list_values[:current_batch])
        max_mean = reward_by_arm["reward"].max()
        arm_with_max_reward = reward_by_arm.loc[reward_by_arm["reward"].idxmax(), "chosen_arm"]
        
        print(f"Horizon not large enough, play arm with current highest mean reward (Max arm = {arm_with_max_reward})")
        results = {"df": df,
                   "batch_size_list_arm": np.nan,
                   "active_arms": active_arms,
                   "arm_max_reward": arm_with_max_reward}
        return results
    



#################################################################################
######## Extras
#################################################################################

def get_alpha_beta(reward, chosen_arm, batch):
    
    """
    The function `get_alpha_beta` computes alpha (successes) and beta (failures) values for each arm in a multi-armed bandit scenario across batches, based on the observed rewards. It generates cumulative alpha and beta values, which can be used for Thompson Sampling.
    
    
    Parameters:
        - reward: A list or array representing the rewards received from chosen arms.
        - chosen_arm: A list or array indicating which arm was chosen in each round.
        - batch: A list or array indicating the batch in which the arms were played.
    
    Process:
        1. A DataFrame is created containing the `reward`, `chosen_arm`, and `batch` columns.
        2. The DataFrame is grouped by `batch` and `chosen_arm` to calculate:
            - `reward_sum`: The sum of rewards for each arm in each batch.
            - `count`: The number of times each arm was selected in each batch.
        3. The number of failures for each arm (i.e., non-rewards) is computed by subtracting `reward_sum` from `count`.
        4. The result is then "pivoted" into wide-format DataFrames where rows represent batches and columns represent arms:
            - `widened_alpha`: Contains the sum of rewards for each arm in each batch.
            - `widened_beta`: Contains the count of failures for each arm in each batch.
        5. Missing values in the pivoted DataFrames are filled with zeros.
        6. Alpha and beta lists (matrices) are created by converting the wide-format DataFrames to NumPy arrays.
        7. A row of ones is prepended to both alpha and beta lists to represent the initial prior (each arm starts with 1 success and 1 failure). The last row (which may represent a non-existent or future batch) is removed.
        8. Cumulative sums of the alpha and beta values are calculated across batches, providing cumulative alpha and beta matrices.
        
    Returns:
        - `alpha_list`: The matrix of alpha (success) values, where rows represent batches and columns represent arms.
        - `beta_list`: The matrix of beta (failure) values, where rows represent batches and columns represent arms.
        - `alpha_list_cum`: The cumulative sum of alpha values across batches.
        - `beta_list_cum`: The cumulative sum of beta values across batches.
    """
    
     
    data = pd.DataFrame({"reward": reward, "chosen_arm": chosen_arm, "batch": batch})
    
    result = data.groupby(['batch', 'chosen_arm']).agg(
        reward_sum=('reward', 'sum'),
        count=('reward', 'size')
    ).reset_index()
    
    # Subtract reward_sum from count
    result['failures'] = result['count'] - result['reward_sum']
    
    result = result.drop("count", axis=1)
    
    widened_alpha = result.pivot(index='chosen_arm', columns='batch', values='reward_sum').fillna(0).reset_index()
    widened_alpha = widened_alpha.set_index('chosen_arm').T
    
    widened_beta = result.pivot(index='chosen_arm', columns='batch', values='failures').fillna(0).reset_index()
    widened_beta = widened_beta.set_index('chosen_arm').T
    
    alpha_list = widened_alpha.values
    beta_list = widened_beta.values
    
    # Now add the first row with ones to show the initial stage and remove the last row as this is not implemented anymore
    # Determine the number of columns
    num_arms = alpha_list.shape[1]
     
     # Create a row of ones with the same number of columns
    ones_row = np.ones((1, num_arms), dtype=int)
     
     # Add the row of ones in front
    alpha_list = np.vstack((ones_row, alpha_list))
    beta_list = np.vstack((ones_row, beta_list))
     # Remove the last row
    alpha_list, beta_list = alpha_list[:-1], beta_list[:-1]
    # get cumulative list
    alpha_list_cum = np.cumsum(alpha_list, axis=0)
    beta_list_cum = np.cumsum(beta_list, axis=0)
         
    results = {"alpha_list": alpha_list,
               "beta_list": beta_list,
               "alpha_list_cum": alpha_list_cum,
               "beta_list_cum": beta_list_cum} 
    return results


# initializes data structure when user reads in data the first time
def intialize(df, batches, arms, exploration):
    
    """
The function `initialize` prepares a pandas DataFrame (`df`) for a multi-armed bandit experiment by assigning batches and initializing arm selections during an exploration phase. It does the following:

Parameters:
    - df: The pandas DataFrame that holds the data for the experiment.
    - batches: The total number of batches the data will be split into.
    - arms: The number of arms (options) available in the bandit experiment.
    - exploration: The number of initial batches dedicated to exploration, where arms are chosen randomly.

Process:
    1. The function starts by initializing a new column in `df` called `"reward"` and assigns `NaN` values to it.
    2. It creates an array, `probabilities`, with equal probability for each arm, and `arm_values` contains the possible arm numbers (from 1 to the total number of arms).
    3. The DataFrame is split into batches:
        - `group_size` determines the number of rows in each batch.
        - A new column `"batch"` is created, where each row is assigned a batch number ranging from 1 to the total number of batches.
        - The function loops through each batch and assigns the appropriate batch number to a corresponding group of rows.
    4. During the exploration phase, arms are randomly assigned to rows in batches that are part of the exploration phase:
        - For batches less than or equal to the `exploration` threshold, arms are randomly chosen according to the defined `probabilities` and assigned to the `"chosen_arm"` column.

Returns:
    - The updated DataFrame `df` with three new columns:
        - `"reward"`: Initialized with `NaN` values.
        - `"batch"`: Batch numbers assigned to each row.
        - `"chosen_arm"`: Randomly assigned arm numbers during the exploration phase.
"""

    df["reward"] = np.nan
    probabilities = np.full(arms, 1/arms)
    arm_values = np.arange(1,arms+1)
    ### Generate batches
    
    # Assuming you have a pandas DataFrame named 'df'
    n = len(df)  # Get the number of observations
    group_size = int(np.ceil(n / batches))

    # Create a new variable named 'batch'
    df['batch'] = 0
    # Loop over the number of groups to assign the values
    for i in range(1, batches + 1):
        start = (i - 1) * group_size
        end = min(i * group_size, n)
        df.loc[start:end, 'batch'] = i
        
    ### Generate randomly assigned chosen arms --> fix proportion
    df.loc[df['batch'] <= exploration, 'chosen_arm'] = np.random.choice(arm_values, size=(df['batch'] <= exploration).sum(), p=probabilities)

    return df

def thompson_updating_preprocessing(df):
    
    """
This function preprocesses the experiment history dataframe for the Thompson Sampling update function. It identifies where completed data ends, keeps only fully observed batches, and extracts key information needed for the next update step.

Parameters:
    - df: Pandas DataFrame containing the bandit history with columns `reward`, `chosen_arm`, `batch`, and `chosen_arm_label`.

Process:
    1. Detects the start of the next (unfilled) batch by finding the first occurrence of three consecutive NaN values in `chosen_arm`.
    2. Determines the index of this upcoming batch (`next_batch`) and its size (`batch_size`).
    3. Filters the dataframe to include only completed batches (`batch < next_batch`).
    4. Extracts the unique integer arm indices observed so far (`arm_values`).

Returns:
    A dictionary containing:
    - df: Filtered dataframe with only completed batch data.
    - next_batch: The index of the next batch to be processed.
    - batch_size: The size of the upcoming batch.
    - arm_values: Array of unique arms observed in the filtered data.
"""

    
    # return the correct data structure for updating function
    # Df with the following structure required df = pd.DataFrame({"reward": reward, "chosen_arm": chosen_arm, "batch": batch, "chosen_arm_label": chosen_arm_label})
    # chosen_arm_label is a character vector 
    
    # Find the index where at least three nan's are in a row for the first time --> where batch stops
    nan_mask = df['chosen_arm'].isna()
    consecutive_nans = nan_mask.rolling(window=3).sum() == 3
    an_index = consecutive_nans.idxmax()
    next_batch = df.loc[an_index, 'batch']
    
    # batch size
    batch_size = df[df["batch"] == next_batch].shape[0]


    # Only return data before next batch (filled out)
    df = df[df["batch"] < next_batch].copy()
    
    # arm values - get unique values of chosen_arm
    # should be integers
    # Take values after conditioning on played batches --> otherwise nas are included
    arm_values = np.unique(df["chosen_arm"]).astype(int)    
    
    # Dictionary
    results = {"df": df, "next_batch": next_batch, "batch_size": batch_size, "arm_values": arm_values}
    return results

# Update dataframe according to given probabilities from update function
def update_randomization(df, next_batch, probabilities, arm_values, seed = 1234):
    
    """
This function randomly assigns arms to all observations in the specified next batch using a given probability distribution.

Parameters:
    - df: DataFrame containing `batch` and `chosen_arm` columns.
    - next_batch: Batch index to be filled.
    - probabilities: Assignment probabilities for each arm.
    - arm_values: Array of possible arm indices.
    - seed: Random seed for reproducibility.

Process:
    1. Sets the random seed.
    2. Randomly samples arms according to `probabilities`.
    3. Fills the `chosen_arm` column for rows in `next_batch`.

Returns:
    - df: DataFrame with updated arm assignments for the batch.
"""
    
    np.random.seed(seed)    
    df.loc[df['batch'] == next_batch, 'chosen_arm'] = np.random.choice(arm_values, size=(df['batch'] == next_batch).sum(), p=probabilities)
    return df


def update_shuffling(df, next_batch, chosen_arms):
    
    """
This function assigns a predefined sequence of arms to all observations in the specified next batch.

Parameters:
    - df: DataFrame containing `batch` and `chosen_arm` columns.
    - next_batch: Batch index to be filled.
    - chosen_arms: Sequence of arm assignments for that batch.

Process:
    1. Selects rows belonging to `next_batch`.
    2. Fills their `chosen_arm` values using `chosen_arms`.

Returns:
    - df: DataFrame with updated arm assignments for the batch.
"""

    
    df.loc[df['batch'] == next_batch, 'chosen_arm'] = chosen_arms
    return df


def check_and_run_greedy(
    list_of_true_means,
    list_of_standard_deviations,
    greedy_alg_k,
    eps, batch, size, exploration, decay
):
    
    """
This function validates the reward standard deviation inputs before running a greedy bandit algorithm. If no valid list of standard deviations is provided, it defaults to using 1 for all arms.

Parameters:
    - list_of_true_means: List of true mean rewards for each arm.
    - list_of_standard_deviations: List of reward standard deviations for each arm.
    - greedy_alg_k: Greedy bandit algorithm function to be executed.
    - eps: Exploration parameter for the greedy algorithm.
    - batch: Number of batches.
    - size: Total horizon or sample size.
    - exploration: Exploration strategy parameter.
    - decay: Decay parameter controlling exploration over time.

Process:
    1. Checks whether the number of provided standard deviations matches the number of arm means.
    2. If they match, runs the greedy algorithm with the given standard deviations.
    3. If they do not match, prints a warning and creates a default list of standard deviations equal to 1 for all arms.
    4. Runs the greedy algorithm using this default list instead.

Returns:
    - The output of `greedy_alg_k` using either the provided or default standard deviations.
"""

    
    if len(list_of_true_means) == len(list_of_standard_deviations):
        # Lengths match → use the standard deviations
        return greedy_alg_k(
            list_of_true_means,
            list_of_standard_deviations,
            eps, batch, size, exploration, decay
        )
    else:
        # Lengths do NOT match → create list of ones
        print("""The standard deviation of the normal reward distribution is set to a default value of 1 for all arms. Because standard deviations were not provided, or the number of standard deviations does not match the number of means.""")
        new_std_list = [1] * len(list_of_true_means)
        return greedy_alg_k(
            list_of_true_means,
            new_std_list,
            eps, batch, size, exploration, decay
        )
    
def stata_to_numpy(var):
    
    """
This function converts a Stata-style variable into a NumPy array of floats and replaces Stata missing values with `np.nan`.

Parameters:
    - var: List or array-like object containing numeric values from Stata (including missing values).

Process:
    1. Converts the input `var` to a NumPy array of type float.
    2. Replaces values greater than 8.988e307 (Stata missing values) with `np.nan`.

Returns:
    - arr: NumPy array with Stata missing values replaced by `np.nan`.
"""

    
    arr = np.asarray(var, dtype=float)          # convert list to numpy array
    arr[arr > 8.988e307] = np.nan               # replace Stata missing values (., .a, .b, …) with np.nan
    return arr

