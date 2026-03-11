{smcl}
{* *! version 17.0 27jun2024}{...}
{viewerdialog bbandits_update "dialog bbandits_update"}{...}
{viewerjumpto "Syntax" "bbandits_update##syntax"}{...}
{viewerjumpto "Description" "bbandits_update##description"}{...}
{viewerjumpto "Options" "bbandits_update##options"}{...}
{viewerjumpto "Examples" "bbandits_update##examples"}{...}

{p2col:{bf:bbandits_update}} Update a multi-armed bandit experiment

{marker syntax}{...}
{title:Syntax}
{p}
{cmd:bbandits_update} {it:varlist} [, {it:thompson} {it:greedy} {it:sae} {it:clipping(real 0.05)} {it:epsilon(real 0.1)} {it:active_arms(numlist)} {it:batch_sae(int)} {it:excel("path")}]

{marker description}{...}
{title:Description}
{pstd}
{cmd:bbandits_update} updates the data structure for running a multi-armed bandit experiment based on the provided reward, chosen arm, and batch variables.
The chosen arm variable is required to be numeric. It is recommended to number the arms with integers starting from 0 up to arm k.
The command implements re-encoding of chosen arm values, performing the specified updating algorithm (Thompson Sampling, Epsilon-Greedy or Sequential Arm Elimination), and preparing the data for the next batch.

{pstd}
The program performs the following steps:

{phang2}
1. Re-encodes the chosen arm variable to be zero-indexed. 

{phang2}
2. Preprocesses data for the specified updating algorithm (Bernoulli Thompson Sampling, Epsilon-Greedy or Sequential Arm Elimination).

{phang2}
3. Applies the algorithm within a Python function (Python installation necessary for this program).

{phang2}
4. Stores the updated variables back into the Stata dataset.

{phang2}
5. Optionally exports the dataset to an Excel file if the {opt excel} option is specified.

{pstd}
The underlying algorithms are implemented in Python; therefore, a Python installation is necessary. The clipping rate or epsilon rate
has to be sufficiently high so that each arm is at least played once, otherwise for the respective batch the BOLS estimate is not defined.

{marker options}{...}
{title:Options}
{phang}
{opt t:hompson} specifies Bernoulli Thompson sampling algorithm. The Bernoulli Thompson Sampling algorithm only accepts 1 (successes) and 0 (failures) as rewards.

{phang}
{opt g:reedy} specifies the Epsilon-Greedy algorithm.

{phang}
{opt sae: } specifies the Sequential Arm Elimination (SAE) algorithm which is an implementation of the algorithm presented in Esfandiari et al. (2021, p. 7343).
For this option the units have to be randomly ordered because the algorithm assigns the arms blockwise per batch and does not randomly reshuffle.

{phang}
{opt c:lipping(real)} specifies the clipping rate for the Bernoulli Thompson algorithm. The default value is 0.05.

{phang}
{opt e:psilon(real)} specifies the epsilon rate for the Epsilon-Greedy algorithm. The default value is 0.1.

{phang}
{opt ac:tive_arms(numlist)} specifies the number of active arms according to the sequential elimination algorithm (sae) formatted as a numlist (e.g. 0 2 3 7). 
It is a required input for the sae algorithm. In the initial stage all available arms are active. The numeric index saved in the column "chosen_arm_numeric" should be used 
to specify the respective arms. 

{phang}
{opt ba:tch_sae(int)} requires the total number of batches in the successive arm elimination setting.

{phang}
{opt ex:cel("path")} indicates that the updated data is saved as an Excel file under the specified path. The saved file can be used to impute the newly observed rewards.
The replace option is activated, hence it overwrites excel files with the same name in the same directory.

{marker requirements}{...}
{title:Requirements}
{pstd} The underlying calculations are computed in Python. Therefore, Python and the respective Python packages have to be installed. The required Python packages are {it:scikit-learn}, {it:numpy}, 
{it:pandas}, {it:scipy}, {it:statsmodels}, and {it:sfi}.
At least Stata 16 is required.

{marker examples}{...}
{title:Examples}
{hline}
{pstd}
Update the multi-armed bandit experiment using the Thompson Sampling algorithm:

{phang2}{cmd: bbandits_update reward chosen_arm batch, thompson}

{pstd}
Update the multi-armed bandit experiment using the Epsilon-Greedy algorithm with specified epsilon and seed:

{phang2}{cmd: bbandits_update reward chosen_arm batch, greedy epsilon(0.2)}

{pstd}
Update according to the Sequential Arm Elimination algorithm. It saves a numlist of the active arms in a macro so that it can be used for further analysis:

{phang2}{cmd: bbandits_update reward chosen_arm batch, sae active_arms(0 1 2) batch_sae(5)}

{pstd}
Update and export the dataset to an Excel file:

{phang2}{cmd: bbandits_update reward chosen_arm batch, greedy excel("path")}

{hline}{pstd}{bf:Example 2: Simulated Bernoulli Thompson experiment to get started}

{pstd}
Clear the dataset and create the required data structure. A dataset in which each row represents a unit to be treated. A complete list of planned treated units is recommended:

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

{pstd} Initialize the bandit experiment

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

{pstd} Run subsequent batches. Capture is necessary because in last round of the loop, nothing can be updated anymore.

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


{hline}{pstd}{bf:Example 3: Simulated Sequential Arm Elimination experiment}

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
Initialize the bandit experiment using the Sequential Arm Elimination algorithm:

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
Update assignments using Sequential Arm Elimination:

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
