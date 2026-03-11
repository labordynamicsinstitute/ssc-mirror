{smcl}
{* *! version 16.0 15jul2020}{...}
{viewerdialog outlabs "dialog outlabs"}{...}
{viewerjumpto "Syntax" "epsilon_greedy##syntax"}{...}
{viewerjumpto "Menu" "epsilon_greedy##menu"}{...}
{viewerjumpto "Description" "epsilon_greedy##description"}{...}
{viewerjumpto "Options" "epsilon_greedy##options"}{...}
{viewerjumpto "Examples" "epsilon_greedy##examples"}{...}

{p2col:{bf:Epsilon greedy}} Multi-armed bandit simulations


{marker syntax}{...}
{title:Syntax}
{p}
{cmd:bbandits_sim} true_mean_values [, batch(int 25) size(int 100) eps(real 0.1) decay(real 1) clipping(real 0.05) exploration(int 0) greedy thompson plot_thompson twopts stacked monte_carlo n(int 1000) 
reference_arm(int 0) arm(int 1) standard_deviations(numlist) twoptions(twopts)}] 

{marker description}{...}
{title:Description}
{pstd}
{cmd:bbandits_sim} simulates data for different multi-armed bandit algorithms. Currently it supports the algorithms epsilon-greedy
 and Bernoulli Thompson sampling. {opt true_mean_values} are a numlist of the true expected values of each arm from
which the simulated data is drawn from. The option {opt greedy} specifies the epsilon-greedy algorithm. The option
{opt thompson} selects the Bernoulli Thompson algorithm. The default option is {opt greedy}. 

{pstd}
Under the {opt greedy} specification the algorithm uses simulated data from a normal distribution and applies the batched epsilon-greedy 
algorithm. The rewards for each arm are drawn
from a normal distribution with the given expected value and a standard deviation of 1. The first value 
is the expected value for the first arm, the second for the second and so on.  
The algorithm shows the data generating process of the batched epsilon-greedy algorithm.

{pstd}
Under the {opt thompson} data is simulated from a Bernoulli Thompson algorithm. Thompson sampling only allows
valid success probabilities as inputs. 

{marker requirements}{...}
{title:Requirements}
{pstd} The underlying calculations are computed in Python. Therefore, Python and the respective Python packages have to be installed. The required Python packages are {it:scikit-learn}, {it:numpy}, 
{it:pandas}, {it:scipy}, {it:statsmodels}, and {it:sfi}.
At least Stata 16 is required. 

{marker options}{...}
{title:Options}
{phang}{opt b:atch(integer)} specifies the number of batches. The default is 25 batches.

{phang}{opt s:ize(integer)} specifies the batch size. The default is 100 observations per batch.

{phang}{opt e:ps(real)} specifies the epsilon parameter for the epsilon-greedy algorithm. The default epsilon is 10\%. 

{phang}{opt d:ecay(real)} defines the decay rate for the epsilon-greedy algorithm. At the moment only a linear decay rate which multiplies the epsilon from the previous round with the decay factor is implemented. The default value is 1.

{phang}{opt c:lipping(real)} specifies the clipping rate for the Bernoulli Thompson algorithm. The default value is 5\%.

{phang}{opt ex:ploration(int 0)} specifies the number of batches where the algorithm assigns the treatment uniformly. The default value is 0.

{phang}{opt g:reedy} specifies the epsilon-greedy algorithm instead of the Bernoulli Thompson algorithm. The default is epsilon-greedy.

{phang}{opt sta:ndard_deviations(numlist)} specifies the standard deviations for the arms' rewards from the normal distribution under the epsilon-greedy algorithm. 
For example, standard_deviations(1 2) sets the reward distribution for arm 1 to normal(mu1,1) and for arm 2 to normal(mu2,2).

{phang}{opt t:hompson} specifies the Bernoulli Thompson sampling algorithm instead of the epsilon-greedy treatment assignment algorithm. The input values for {it: true_mean_values} have to be valid probabilities. 

{phang}{opt p:lot_thompson} generates plots of the beta distribution under the Thompson sampling algorithm.

{phang}{opt st:acked} plots the beta distribution under the Thompson sampling algorithm but vertically stacked.

{phang}{opt m:onte_carlo} specifies that instead of simulating a single bbandits experiment, {opt N} bandits experiments
are conducted. Using the {opt monte_carlo} option the command returns the test statistic for the OLS and BOLS in
each of the N runs. Additionally, the distribution of the test statistics is plotted. With the option {opt thompson}
or {opt greedy} the respective algorithm for the simulation is chosen. The program might take a while to run. The default value is 1,000 repetitions. Only two arms can be compared to each other even if multiple arms are specified. 

{phang}{opt n:(integer)} specifies the number of repetitions for the Monte Carlo simulation. Option only allowed in combination with the {opt monte_carlo} option.

{phang}{opt r:eference_arm(integer)} specifies the reference arm for the Monte Carlo simulation.

{phang}{opt a:rm(integer)} specifies the arm which is compared against the reference arm in the Monte Carlo simulation. The Monte Carlo simulation function only allows to compute the test statistic for two arms but the data can be drawn from a multi-arm simulation.

{phang}{opt tw:options(twopts)} specifies twoway options for graphs.


{marker results}{...}
{title:Stored results}

{pstd} 
{cmd:bbandits_sim} stores the following in {cmd:e()}:

{p2col 5 23 26 2: Matrices}{p_end}

{synoptset 20 tabbed}
{synopt:{cmd:e(decay_rate)}}Epsilon or clipping rate for each batch. When decay rate is specified, it becomes smaller for each batch.{p_end}


{marker examples}{...}
{title:Examples}
{hline}
{pstd}Setup

{phang2}{cmd:. bbandits_sim 1 2}

{pstd}Data is generated according to a batched epsilon-greedy algorithm (default option). The rewards are drawn from
a normal distribution with expected value 1 and standard deviation 1 (N(1,1)) for both arms.

{phang2}{cmd:. bbandits_sim 1 1 2, batch(10) size(100) eps(0.2) epsilon} 

{pstd} Three arms with expected mean values of 1, 1 and 2 are simulated and generated under the batched 
epsilon-greedy algorithm (explicitly specified). There are 10 batches {cmd: batch} and in each batch 100 rewards {cmd: size} are drawn. In each batch 20
percent {cmd: eps} of the rewards are randomly drawn (exploration), 80 percent are drawn from the arm with the highest 
estimated expected value up to the respective batch (exploitation).

{phang2} {cmd:. bbandits_sim 0.1 0.15 0.2, batch(10) size(100) clipping(0.1) thompson} 

{pstd} Three arms drawn from a Bernoulli distribution with the given probabilities. 

{phang2} {cmd:. bbandits_sim 0.5 0.5, monte_carlo thompson clipping(0.1) n(1000)} 

{pstd} Runs a simple Monte Carlo study for two arms with a zero margin. The specified algorithm is Bernoulli Thompson
Sampling. The clipping rate is 0.1 and 1000 trials will be simulated.

{phang2} {cmd:. bbandits_sim 1 1, monte_carlo greedy reference_arm(0) arm(1) test_value(0) n(500) eps(0.2) standard_deviations(1 2) tw(title("My Histogram Title"))} 

{pstd} Runs a simple Monte Carlo study for two arms with a zero margin. The specified algorithm is epsilon-greedy. The rewards are drawn from a normal distribution with mu1=mu2=1
and standard deviation 1 and 2. 

{hline}

{pstd}{bf: Literature}

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

