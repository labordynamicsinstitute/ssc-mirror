{smcl}
{* 16Mar2022}{...}
{cmd:help get_train_test}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{hi:get_train_test}{hline 1}}Splitting an initial dataset into training and testing datasets{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{hi:get_train_test},
{cmd:dataname}{cmd:(}{it:data_name}{cmd:)}
{cmd:split}{cmd:(}{it:shares}{cmd:)}
{cmd:split_var}{cmd:(}{it:name}{cmd:)}
{cmd:rseed}{cmd:(}{it:integer}{cmd:)}


{dlgtab:Description}

{pstd} The {hi:get_train_test} command generates the training and testing datasets from an initial dataset loaded in the current Stata session. 

 
{dlgtab: Options}

{synoptset 32 tabbed}{...}
{synopthdr :options}
{synoptline}

{synopt :{opt dataname(data_name)}}specifies the name of the dataset open in the current Stata session{p_end}

{synopt :{opt split(shares)}}requests to provide two numbers (ranging from 0 to 1) 
representing the shares of the training and testing datasets.{p_end}

{synopt :{opt split_var(name)}}generates a flag variable distinguishing the training and testing observations.{p_end}

{synopt :{opt seed(#)}}where {it:#}specifies a integer seed to assure replication of same results.{p_end}
{synoptline}


{dlgtab:Returns}

{phang} The {hi:get_test_train} command generates the training dataset as 
{it:data_name}_train and a testing datset as {it:data_name}_test. 
They are automatically located in the Stata current directory. 



{dlgtab:Author}

{phang}Giovanni Cerulli{p_end}
{phang}IRCrES-CNR{p_end}
{phang}Research Institute for Sustainable Economic Growth, National Research Council of Italy{p_end}
{phang}E-mail: {browse "mailto:giovanni.cerulli@ircres.cnr.it":giovanni.cerulli@ircres.cnr.it}{p_end}


{dlgtab:Also see}

{psee}
Online: {helpb python}, {helpb c_ml_stata_cv}, {helpb r_ml_stata_cv}
{p_end}
