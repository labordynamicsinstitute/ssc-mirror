{smcl}
{* *! version 17.0 27jun2024}{...}
{viewerdialog bbandits_initialize "dialog bbandits_initialize"}{...}
{viewerjumpto "Syntax" "bbandits_initialize##syntax"}{...}
{viewerjumpto "Description" "bbandits_initialize##description"}{...}
{viewerjumpto "Options" "bbandits_initialize##options"}{...}
{viewerjumpto "Examples" "bbandits_initialize##examples"}{...}

{p2col:{bf:bbandits_initialize}} Initialize a multi-armed bandit experiment

{marker syntax}{...}
{title:Syntax}
{p}
{cmd:bbandits_initialize} [, {it:batch(int 3)} {it:arms(int 2)} {it:exploration_phase(int 1)} {it:sae}]

{marker description}{...}
{title:Description}
{pstd}
{cmd:bbandits_initialize} sets up the initial data structure for running a multi-armed bandit experiment. 
This includes initializing the necessary variables and setting up the experimental conditions.

{pstd}
The program follows the following procedure:

{phang2}
1. It requires a list of all treated units which should be saved in a variable where each row represents a treated unit (see Example 2 below).

{phang2}
2. Then, the program creates the variables {bf:reward}, {bf:chosen_arm}, {bf:batch} and {bf:chosen_arm_numeric} in Stata and initializes them so that they can be immediately used 
in combination with {bf:bbandits_update}. The variable {bf:reward} is empty and should be filled during the experiment. {bf:chosen_arm} contains randomly assigned arms if 
an exploration phase was defined, the rest of batches are empty and are filled during the experiment. {bf:chosen_arm_numeric} generates numeric labels for the {bf:chosen_arm}
which start from 0 to k (number of arms). It is recommended to use the numeric labels in combination with the {bf:bbandits_update} command. {bf:batch} indicates the batches.

{phang2}
3. The program separates all treated units into equal batches based on the original order of the data and the specified number of batches. Hence, if the order is not random it might be recommended
 to randomly reorder the data.

{phang2}
4. If an exploration phase is defined, the initialize command will randomly with uniform probability assign the treatment arms for the exploration phase.

{phang2}
5. If the Sequential Arm Elimination (SAE) algorithm is specified, it returns a macro of a numlist of the available arms 
which can directly be used for simulating an experiment based on the SAE algorithm (see example below).

{marker requirements}{...}
{title:Requirements}
{pstd} The underlying calculations are computed in Python. Therefore, Python and the respective Python packages have to be installed. The required Python packages are {it:scikit-learn}, {it:numpy}, 
{it:pandas}, {it:scipy}, {it:statsmodels}, and {it:sfi}.
At least Stata 16 is required. 

{marker options}{...}
{title:Options}
{phang}
{opt b:atch(int)} specifies the number of batches to divide the experiment into. The default is 3.

{phang}
{opt a:rms(int)} specifies the number of treatment arms in the bandit experiment. The default is 2.

{phang}
{opt ex:ploration_phase(int)} specifies the number of batches where the algorithm assigns the treatment uniformly. The default value is 1.

{phang}
{opt sae: } sets up the optimal data structure for applying the Sequential Arm Elimination algorithm which is presented in Esfandiari et al. (2021, p. 7343).

{marker examples}{...}
{title:Examples}
{hline}
{pstd}
Set up the multi-armed bandit experiment with default values:

{phang2}{cmd:. bbandits_initialize}

{pstd}
Setup with specified number of batches, arms, and exploration phase:

{phang2}{cmd:. bbandits_initialize, batches(5) arms(3) exploration_phase(2)}

{hline}{pstd}{bf:Example 2: Simulated workflow with the Bernoulli Thompson experiment }

{pstd}
Clear the dataset and create the required data structure. A dataset in which each row represents a unit that will be treated. A complete list of planned treated units is recommended:

{phang2}{cmd: clear}{p_end}
{phang2}{cmd: set obs 1000}{p_end}

{pstd}
Create an ID variable:

{phang2}{cmd: gen ID = ""}{p_end}

{pstd}
Populate the ID variable with values "school_1", "school_2", ..., "school_1000". Hence there are 1000 schools which are going to be treated:

{phang2}{cmd: forval i = 1/1000 {c -(} } {p_end}
{phang2}{cmd:     qui replace ID = "school_" + string(`i') if _n == `i'}{p_end}
{phang2}{cmd: {c )-}}{p_end}

{pstd} Initialize the bandit experiment. The "bbandit_initialize" command sets up the optimal data structure for running an experiment with the "bbandits" command.

{phang2}{cmd: bbandits_initialize, batches(10) arms(3) exploration_phase(2)}{p_end}

{pstd} Assign treatment and observe rewards during the exploration phase

{phang2}{cmd: generate rand = runiform()}{p_end}
{phang2}{cmd: replace reward = .}{p_end}

{phang2}{cmd: forval i = 1/2 {c -(}} {p_end}
{phang2}{cmd:     replace reward = 0 if batch == `i'}{p_end}
{phang2}{cmd:     replace reward = 1 if rand < 0.4 & batch == `i' & chosen_arm_numeric == 2}{p_end}
{phang2}{cmd:     replace reward = 1 if rand < 0.5 & batch == `i' & chosen_arm_numeric == 1}{p_end}
{phang2}{cmd:     replace reward = 1 if rand < 0.6 & batch == `i' & chosen_arm_numeric == 0}{p_end}
{phang2}{cmd: {c )-}}{p_end}

{pstd}
Update assignments using Thompson Sampling:

{phang2}{cmd: bbandits_update reward chosen_arm_numeric batch, thompson clipping(0.2)}{p_end}

{pstd} Run subsequent batches. Capture necessary because in last round of the loop, nothing can be updated anymore.

{phang2}{cmd: forval i = 3/10 {c -(}} {p_end}
{phang2}{cmd:     display `i'}{p_end}
{phang2}{cmd:     replace reward = 0 if batch == `i'}{p_end}
{phang2}{cmd:     replace reward = 1 if rand < 0.4 & batch == `i' & chosen_arm_numeric == 2}{p_end}
{phang2}{cmd:     replace reward = 1 if rand < 0.5 & batch == `i' & chosen_arm_numeric == 1}{p_end}
{phang2}{cmd:     replace reward = 1 if rand < 0.6 & batch == `i' & chosen_arm_numeric == 0}{p_end}
{phang2}{cmd:     capture bbandits_update reward chosen_arm_numeric batch, thompson clipping(0.2)}{p_end}
{phang2}{cmd: {c )-}}{p_end}

{pstd}
Inspect final assignments:

{phang2}{cmd: bbandits reward chosen_arm_numeric batch}{p_end}


{hline}{pstd}{bf:Example 3: Simulated workflow with the Sequential Arm Elimination algorithm}

{pstd}
Clear the dataset and create 1,000 observations:

{phang2}{cmd: clear}{p_end}
{phang2}{cmd: set obs 1000}{p_end}

{pstd}
Create an ID variable:

{phang2}{cmd: gen ID = ""}{p_end}

{pstd}
Populate the ID variable with values "school_1", "school_2", ..., "school_1000":

{phang2}{cmd: forval i = 1/1000 {c -(}}{p_end}
{phang2}{cmd:     qui replace ID = "school_" + string(`i') if _n == `i'}{p_end}
{phang2}{cmd: {c )-}}{p_end}

{pstd}
Initialize the bandit experiment using the sequential arm elimination algorithm:

{phang2}{cmd: bbandits_initialize, batches(5) arms(3) sae}{p_end}

{pstd}
Display the active arms macro which can be used in the subsequent batches of the bbandits_update command. Alternatively, they can be manually specified:

{phang2}{cmd: di "$active_arms_macro"}{p_end}

{pstd}
Generate random rewards:

{phang2}{cmd: generate rand = runiform()}{p_end}
{phang2}{cmd: replace reward = .}{p_end}

{pstd}
Assign rewards in the first batch:

{phang2}{cmd: forval i = 1/1 {c -(}}{p_end}
{phang2}{cmd:     replace reward = 0 if batch == `i'}{p_end}
{phang2}{cmd:     replace reward = 1 if rand < 0.4 & batch == `i' & chosen_arm == 1}{p_end}
{phang2}{cmd:     replace reward = 1 if rand < 0.5 & batch == `i' & chosen_arm == 2}{p_end}
{phang2}{cmd:     replace reward = 1.5 if rand < 0.8 & batch == `i' & chosen_arm == 3}{p_end}
{phang2}{cmd: {c )-}}{p_end}

{pstd}
Update assignments using sequential arm elimination:

{phang2}{cmd: bbandits_update reward chosen_arm_numeric batch, sae active_arms("$active_arms_macro") batch_sae(5)}{p_end}

{pstd}
Assign rewards in the second batch:

{phang2}{cmd: forval i = 2/2 {c -(}}{p_end}
{phang2}{cmd:     replace reward = 0 if batch == `i'}{p_end}
{phang2}{cmd:     replace reward = 1 if rand < 0.4 & batch == `i' & chosen_arm_numeric == 0}{p_end}
{phang2}{cmd:     replace reward = 1 if rand < 0.5 & batch == `i' & chosen_arm_numeric == 1}{p_end}
{phang2}{cmd:     replace reward = 1.5 if rand < 0.8 & batch == `i' & chosen_arm_numeric == 2}{p_end}
{phang2}{cmd: {c )-}}{p_end}

{pstd}
Display updated active arms and update assignments:

{phang2}{cmd: bbandits_update reward chosen_arm_numeric batch, sae active_arms("$active_arms_macro") batch_sae(5)}{p_end}

{hline}

{pstd}{bf: Literature}

{pstd} Esfandiari, H., Karbasi, A., Mehrabian, A., & Mirrokni, V. (2021). "Regret Bounds for Batched Bandits." {it:Proceedings of the AAAI Conference on Artificial Intelligence}, 35(8), 7340–7348.

{pstd} Kemper, J., & Rostam-Afschar, D. (2026). "Earning While Learning: How to Run Batched Bandit Experiments." {it:Stata Journal}.


{hline}
{pstd}{bf: Disclaimer}

{pstd} This software is provided "as is" without warranty of any kind, either expressed or implied. The entire risk as to the quality and performance of the program is with you. 

{pstd} Should the program prove defective, you assume the cost of all necessary servicing, repair, or correction.

{pstd} In no event will the copyright holders or their employers, or any other party who may modify and/or redistribute this software, be liable to you for damages, including any general, special, incidental, 
or consequential damages arising out of the use or inability to use the program.


{hline}

{pstd}
Authors: Jan Kemper, Davud Rostam-Afschar


