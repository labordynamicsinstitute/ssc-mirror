{smcl}
{* 23nov2025}{...}
{cmd:help opl_overlap}
{hline}

{title:Title}

{p2colset 5 16 21 2}{...}
{p2col :{hi:opl_overlap} {hline 2}} Assessing overlap between train and new data{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{hi:opl_overlap}
{cmd:,}
[{opt gr_save_ps(filename)} {opt gr_save_roc(filename)}]

{dlgtab:Description}

{pstd}
{cmd:opl_overlap} is a post–estimation command of the Optimal Policy Learning (OPL) toolbox.
It is designed to assess the overlap between the covariate distributions of the
training data (data used to learn the optimal policy) and the new data
(data on which the policy is meant to be applied).{p_end}

{pstd}
The command must be run after {helpb make_cate}, which sets up the
estimation environment and stores in {cmd:e()} the covariate list used for
policy learning. 

{pstd}
The procedure implemented by {cmd:opl_overlap} is as follows:{p_end}

{phang2}
1. It fits a logistic regression of a binary variable taking value 0 for
observations in the training and 1 for this in the new dataset on the covariates in
   {cmd:e(xvars)} returned by {helpb make_cate}. This model predicts the probability that an observation belongs to the new data rather than to the training data (reverse
   propensity score).{p_end}
{phang2}
2. It predicts the fitted probabilities, i.e. the generated variable {cmd:_ps_var}, and compares their distributions across training and new data by means of 
kernel density estimates.{p_end}
{phang2}
3. It computes the ROC curve and the Area Under the Curve (AUC) using
   {helpb lroc}. The AUC summarizes the degree of separability between
   training and new data in terms of the covariate distribution.{p_end}

{pstd}
If the two datasets have very similar covariate distributions, the reverse propensity score cannot distinguish well between them and the AUC is close to 0.5. Conversely, if the two datasets differ substantially, the AUC moves towards 1, signaling poor overlap and raising concerns about the external validity of the learned policy.{p_end}

{pstd}
The command produces two graphs:{p_end}

{phang2}
1) a graph comparing the kernel density of {cmd:_ps_var} in the training
   data versus the new data;{p_end}
{phang2}
2) the ROC curve associated with the logistic model predicting
   {cmd:group}.{p_end}

{pstd}
Internally, {cmd:opl_overlap} generates the following objects:{p_end}

{phang2}
– variable {cmd:_ps_var}: reverse propensity score (probability of belonging
  to the new data);{p_end}
{phang2}
– graph {cmd:_GR_PS_}: kernel density comparison of {cmd:_ps_var} by group;{p_end}
{phang2}
– graph {cmd:_GR_ROC_}: ROC curve from {cmd:lroc}.{p_end}

{pstd}
For safety, the command checks in advance that variable {cmd:_ps_var} and
graphs {cmd:_GR_PS_} and {cmd:_GR_ROC_} do not already exist in memory.
If any of them is found, the command throws a warning and exits without
overwriting the existing objects.{p_end}


{dlgtab:Options}

{synoptset 32 tabbed}{...}
{synopthdr :options}
{synoptline}
{synopt :{opt gr_save_ps(filename)}}specifies the file where the kernel density comparison graph of the reverse propensity score is to be saved. The in-memory graph name is {cmd:_GR_PS_}.{p_end}
{synopt :{opt gr_save_roc(filename)}}specifies the file where the ROC curve graph is to be saved. The in-memory graph name is {cmd:_GR_ROC_}.{p_end}
{synoptline}


{dlgtab:Output and interpretation}

{pstd}
{cmd:opl_overlap} prints on the screen a short qualitative assessment of
the overlap between training and new data based on the AUC:{p_end}

{phang2}
– AUC ≤ 0.60: overlap is classified as "Very Good".{p_end}
{phang2}
– 0.60 < AUC ≤ 0.70: overlap is classified as "Good".{p_end}
{phang2}
– 0.70 < AUC ≤ 0.80: overlap is classified as "Moderate".{p_end}
{phang2}
– 0.80 < AUC ≤ 0.90: overlap is classified as "Poor".{p_end}
{phang2}
– AUC  > 0.90: overlap is classified as "Very poor".{p_end}

{pstd}
These thresholds provide an empirical rule-of-thumb to judge to what
extent the policy learned on the training data can be reliably
extrapolated to the new data. High AUC values (poor overlap) suggest
that caution is needed when interpreting policy effects on the new
data and may motivate additional robustness checks or re–estimation
on a more comparable sample.{p_end}

{dlgtab:Stored results}

{pstd}
{cmd:opl_overlap} stores the following scalars in {cmd:r()}: {p_end}

{phang2}
{cmd:r(AUC)}    area under the ROC curve from {cmd:lroc}{p_end}
{phang2}
{cmd:r(N)}      number of observations used to estimate the ROC curve{p_end}

{dlgtab:Remarks}

{pstd}
{cmd:opl_overlap} is meant to be used within the OPL workflow after
{helpb make_cate} has been run. It is particularly useful in applications
where the policy is learned on one dataset (training) and then evaluated
or applied to another dataset (new) – for instance, when using historical
data to design a targeting rule to be implemented on a future population
or on a different region.{p_end}

{pstd}
A low AUC (close to 0.5) supports the idea that the covariate distribution
in the new data is well represented in the training data, strengthening
the credibility of policy recommendations. A high AUC, instead, warns that
the two datasets are easily separable based on observed covariates, which
may jeopardize the external validity of the learned policy.{p_end}


{dlgtab:Example}

{pstd}{bf:Example}: Assessing overlap between train and new data{p_end}
{phang2} Load initial dataset{p_end}
{phang3} {stata sysuse JTRAIN2, clear}{p_end}
{phang2} Split the original data into a "old" (training) and "new" (testing) dataset{p_end}
{phang3} {stata get_train_test, dataname(jtrain) split(0.60 0.40) split_var(svar) rseed(101)}{p_end}
{phang2} Use the "old" dataset (i.e. policy) for training{p_end}
{phang3} {stata use jtrain_train , clear}{p_end}
{phang2} Set the outcome{p_end}
{phang3} {stata global y "re78"}{p_end}
{phang2} Set the features{p_end}
{phang3} {stata global x "re74 re75 age agesq nodegree"}{p_end}
{phang2} Set the treatment variable{p_end}
{phang3} {stata global w "train"}{p_end}
{phang2} Set the selection variables{p_end}
{phang3} {stata global z "age mostrn"}{p_end}
{phang2} Run "make_cate" and generate training (old policy) and testing (new policy) CATE predictions{p_end}
{phang3} {stata make_cate $y $x , treatment($w) type("ra") model("linear") new_cate("my_cate_new") train_cate("my_cate_train") new_data("jtrain_test")}{p_end}
{phang2} Run the "opl_overlap" command{p_end}
{phang3} {stata opl_overlap}{p_end}
{phang2} Display the AUC{p_end}
{phang3} {stata return list}{p_end}


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
Online: {helpb make_cate}, {helpb opl_tb}, {helpb opl_tb_c}, {helpb opl_lc}, {helpb opl_lc_c}, {helpb opl_dt}, {helpb opl_dt_c}
{p_end}
