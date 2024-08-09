{smcl}
{* *! version 0.0.3 01mar2024}{...}
{vieweralsosee "[R] predict" "mansection R predict"}{...}
{vieweralsosee "[R] estat classification" "mansection R estat_classification"}{...}
{vieweralsosee "[P] creturn" "mansection P creturn"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Overview" "crossvalidate##overview"}{...}
{viewerjumpto "Commands" "crossvalidate##cmds"}{...}
{viewerjumpto "Additional Information" "crossvalidate##additional"}{...}
{viewerjumpto "Contact" "crossvalidate##contact"}{...}
{title:Cross-Validation in Stata}

{marker overview}{title:Overview}

{pstd}
The crossvalidate package includes several commands and a Mata library that 
provide a range of possible cross-validation techniques that can be used with 
any {help program:eclass} Stata estimation command.  For the majority of users, 
the prefix commands (see {help xv} or {help xvloo}) should handle any of your 
needs.  On what we believe will be uncommon or rare occassions, a user made need 
a bit more control over the process.  In those cases, the lower level commands 
provide a way for users to avoid programming the entire cross-validation process 
while retaining the benefits that these commands provide.

{pstd}
{bf:IMPORTANT!!!} If you intend to only use the lower-level commands, you will 
need to call {help libxv} first.  This compiles the Mata source code into libxv 
on your machine.  If you are using either of the prefix commands {help xv} or 
{help xvloo}, they will handle this step for you.  However, if you intend to use 
metric functions that you have defined prior to {help libxv} compiling the mata 
library, you should call {help libxv}, then define your function, and then call 
{help xv} or {help xvloo}.  Prior to compiling {help libxv}, the contents of 
Mata are cleared to ensure that {help libxv} only contains the functions that 
should be included in the library.

{pstd}
This help file provides an overview of the commands included in the crossvalidate 
package.  We leave detailed information to the documentation for each of the 
individual commands.

{marker cmds}{title:Commands}

{synoptset 15 tabbed}{...}
{synoptline}
{synopthdr:Command Name}
{synoptline}
{syntab:Prefix Commands}
{synopt :{opt {help xv}}}Cross-Validation{p_end}
{synopt :{opt {help xvloo}}}Leave-One-Out Cross-Validation{p_end}
{syntab:Lower Level Commands}
{synopt :{opt {help splitit}}}Splits the dataset into train/test or train/validation/test splits{p_end}
{synopt :{opt {help fitit}}}Calls the estimation command on the appropriate split{p_end}
{synopt :{opt {help predictit}}}Predicts the outcome on the appropriate split{p_end}
{synopt :{opt {help validateit}}}Computes {p_end}
{syntab:Utility Commands}
{synopt :{opt {help classify}}}Used to manage {p_end}
{synopt :{opt {help cmdmod}}}Used for metaprogramming tasks in commands above{p_end}
{synopt :{opt {help state}}}Retrieves current settings and binds to the dataset{p_end}
{synoptline}

{dlgtab:Prefix Commands}

{phang}
{help xv} is a prefix command that should address the majority of use cases for 
cross-validation.  Use the prefix and provide the required arguments, then write 
the estimation command you would use to fit your model under normal circumstances.  
The command will handle spliting the data, fitting the model to the appropriate 
subsets of data, generating the predicted values, and computing the quantities 
of interest that describe the quality of the results.  You can create simple 
train/test and train/validation/test splits with or without K-Folds, using 
simple random sampling or clustered sampling (including sampling of panel units).

{phang}
{help xvloo} is also a prefix command but is used to perform leave-one-out (LOO) 
cross-validation.  LOO can be though of as a special case of K-Fold 
cross-validation where K is equal to the number of observations, or clusters, in 
the training set; another way to think of this is using a jackknife for 
cross-validation.  Therefore, we strongly recommend only using this command when 
working with smaller sample sizes.  Additionally, if the number of observations 
in your dataset plus the number of variables in the dataset plus 2 is greater 
than the number of variables your version of Stata can support you will not be 
able to use this prefix.

{dlgtab:Lower Level Commands}

{phang}
{help splitit} is a command called by the prefix commands to create the splits 
in the data in memory.  As mentioned above, you can create train/test and 
train/validation/test splits with or without K-Folds, using simple random 
sampling or clustered sampling (which includes sampling panel units).  This 
command generates a new variable to identify the splits in the dataset which is 
required to be passed to the subsequent commands below.

{phang}
{help fitit} is a command called by the prefix commands to update and execute 
the user supplied estimation command.  The "update" made by this command is the 
insertion, or modification, of an if expression that is used to ensure that the 
estimation command you passed (either as an argument to this command or via the 
prefix) is executed for the subset of data you intended.  When used with K-Fold 
cross-validation this command will also fit the model to the entire training set 
in addition to each of the K-Folds, unless you tell it otherwise.

{phang}
{help predictit} is a command called by the prefix commands to manage and 
generate the predicted values based on the previously fitted model.  In the case 
of K-Fold cross-validation, it ensures all the predicted values are stored in a 
single variable with appropriate storage type (double precision for continuous 
outcomes and byte for categorical outcomes).  Like {help fitit}, this command 
will also generate predictions based on the model fitted to the entire training 
set when using K-Fold cross-validation unless you tell it otherwise.

{phang}
{help validateit} is the last command called by the prefix commands and is used 
to compute the validation/test metric of your choosing.  We've included a 
selection of metrics in the Mata library distributed with this package and they 
are listed in the help file for {help validateit}.  Additionally, if there is a 
validation metric that we have not implemented you may be able to use it by 
defining a Mata function that follows our function signature requirements and 
passing the name of that function to the appropriate option.

{dlgtab:Utility Commands}

{phang}
{help classify} is a utility called by the {help predictit} command when fitting 
classification models.  This utility ensures that class identifiers are returned 
as the predicted values for binomial, multinomial, and ordinal outcomes.

{phang}
{help cmdmod} is a utility called by {help fitit} and possible {help predictit} 
to create the updated estimation command string and if expression for prediction. 

{phang}
{help state} is a utility called by the {help xv} and {help xvloo} commands as 
an option to bind information about the current state of the computer and 
pseudo-random number generator if requested.


{marker additional}{...}
{title:Additional Information}
{p 4 4 8}If you have questions, comments, or find bugs, please submit an issue in the {browse "https://github.com/wbuchanan/crossvalidate":crossvalidate GitHub repository}.{p_end}


{marker contact}{...}
{title:Contact}
{p 4 4 8}William R. Buchanan, Ph.D.{p_end}
{p 4 4 8}Sr. Research Scientist, SAG Corporation{p_end}
{p 4 4 8}{browse "https://www.sagcorp.com":SAG Corporation}{p_end}
{p 4 4 8}wbuchanan at sagcorp [dot] com{p_end}

{p 4 4 8}Steven D. Brownell, Ph.D.{p_end}
{p 4 4 8}Economist, SAG Corporation{p_end}
{p 4 4 8}{browse "https://www.sagcorp.com":SAG Corporation}{p_end}
{p 4 4 8}sbrownell at sagcorp [dot] com{p_end}
