{smcl}
{* *! version 0.1.4  8 Nov 2022}{...}
{vieweralsosee "mpitb" "help mpitb"}{...}
{viewerjumpto "Syntax" "mpitb##syntax"}{...}
{viewerjumpto "Description" "mpitb##description"}{...}
{viewerjumpto "Workflow" "mpitb##workflow"}{...}
{viewerjumpto "Examples" "mpitb##examples"}{...}
{viewerjumpto "References" "mpitb##references"}{...}
{viewerjumpto "Author" "mpitb##author"}{...}
{viewerjumpto "License" "mpitb##license"}{...}
{viewerjumpto "Citation" "mpitb##citation"}{...}
{viewerjumpto "Acknowledgements" "mpitb##acknowledgements"}{...}
{p2colset 1 10 12 2}{...}
{p2col:{bf:mpitb} {hline 2}} Toolbox to estimate and analyze multidimensional poverty indices (MPI){p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:mpitb} {it:subcommand} ... [{cmd:,} {it:options}]

{synoptset 16 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{syntab:Core tools}
{synopt :{helpb mpitb set:set}}specifies the deprivation indicators of a MPI {p_end}
{synopt :{helpb mpitb est:est}}estimates MPIs and their subindices{p_end}

{syntab:Cross-country tools}
{synopt :{helpb mpitb refsh:refsh}}creates or updates a reference sheet{p_end}
{synopt :{helpb mpitb ctyselect:ctyselect}}selects a subset or all of the available countries{p_end}

{syntab:Low-level tools}
{synopt :{helpb mpitb show:show}}shows details of a particular specification (e.g., weights){p_end}
{synopt :{helpb mpitb setwgts:setwgts}}sets indicator weights based on dimensional weights{p_end}
{synopt :{helpb mpitb gafvars:gafvars}}generates variables for the Alkire-Foster framework{p_end}
{synopt :{helpb mpitb rframe:rframe}}prepares result frames{p_end}
{synopt :{helpb mpitb stores:stores}}stores estimates into results frame{p_end}
{synopt :{helpb mpitb estcot:estcot}}estimates changes over time{p_end}

{syntab:Auxiliary tools}
{synopt :{helpb mpitb assoc:assoc}}calculates association measures for indicators{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:mpitb} is a toolbox that offers several commands to facilitate specification, 
estimation, and analysis of multidimensional poverty indices (MPI) and supports the popular
Alkire-Foster (AF) framework to multidimensional poverty measurement. In particular 
this toolbox supports M0, a member of the Alkire-Foster class of measures, several 
of its subindices and related auxiliary measures, see Alkire and Foster ({help mpitb##AF2011:2011}) and 
Alkire et al. ({help mpitb##AFSSRB2015:2015}).{p_end} 
{pstd}
{cmd:mpitb} has been developed to facilitate the production process of the 
global multidimensional poverty index. Indeed, {cmd:mpitb} has been developed in tandem
with a particular workflow now underlying the global MPI estimations. This workflow 
seeks to provide more efficient and flexible estimation routines with results that 
are also easy to replicate (Suppa {help mpitb##S2021:2021}).{p_end} 

{marker workflow}{...}
{title:Workflow}

{pstd}
The generic workflow for a single country is follows:{p_end}

{phang2}
{cmd:use} ...{p_end}
{phang2}
{cmd:svyset} ...{p_end}
{phang2}
{cmd:mpitb set} ...{p_end}
{phang2}
{cmd:mpitb est} ...{p_end}

{pstd}
The two-step procedure of {cmd:set} and {cmd:est} has several advantages. First, 
overly long commands and unnecessary repetitions can be avoided. This is also useful
for more intense and comprehensive estimation, as the indicators have to be chosen 
only once, whereas results can be conveniently allocated into different files. 
Second, it also allows a more interactive analyses of MPIs.{p_end}

{pstd}
The generic workflow for a cross-country analysis is as follows:{p_end}

{phang2}
{cmd:mpitb refsh} ... {p_end}
{phang2}
{cmd:mpitb ctyselect} ... {p_end}  
{phang2}
{cmd:foreach cty in `r(ctylist)'} { {p_end}
{phang3}
{cmd:use} ...{p_end}
{phang3}
{cmd:svyset} ...{p_end}
{phang3}
{cmd:mpitb set} ...{p_end}
{phang3}
{cmd:mpitb est ... , addmeta(ccty=`cty') ...}{p_end}
{phang2}
}
{p_end}

{pstd}
See Suppa ({help mpitb##S2022:2022}) for further illustrations using synthetic data shipped with 
this toolbox as ancillary files.
{p_end}

{marker remarks}{...}
{title:Remarks}

{phang}
(1) A careful {bf:folder structure} is strongly recommended for the use of this toolbox,
in particular if used in a cross-country setting. This recommendation directly  follows 
from the desiderata of the global MPI workflow to allow flexible re-estimations and 
avoid unnecessary ones. Storing results to disk and only replacing 
them as needed does precisely that. Sloppy data management is anyhow discouraged 
for replicable research, but may be particular detrimental in the present case.
{p_end}

{phang}
(2) {bf:Low-level tools} are subcommands called by core tools. Low-level tools may
be interesting for advanced users and programmers who wish to implement 
additional types of analyses. Users who are exclusively interested in established 
analyses can ignore these commands and should use {helpb mpitb set} and 
{helpb mpitb est} instead which additionally perform plausibility checks on user 
inputs. Low-level tools require correct user input.{p_end}

{phang}
(3) This toolbox is still under {bf:active development}. Many tweaks and extensions 
may be obvious and some of them are, in fact, already scheduled for the next round 
of code revision. Likewise, bugs and other issues may still emerge despite thorough 
testing in different settings. Therefore, feedback on (i) successes and failures in 
using this software package, (ii) bugs and related issues as well as (iii) suggestions 
for tweaks and extensions are highly welcome.{p_end}

{phang}
(4) {cmd:mpitb} issues warnings or errors in many instances when the user is about to 
commit an error or provides implausible information. Additionally, {cmd:mpitb} is tested 
in various ways and contexts. Using {cmd:mpitb}, by itself, however does not guarantee to 
obtain meaningful, informative or even correct results. Ultimately, living up to this
expectation remains the {bf:responsibility of the user} and requires a proper understanding 
of data, methods and analysis.{p_end}

{marker references}{...}
{title:References}
{marker AFSSRB2015}
{phang}Alkire, S., Foster, J.E., Seth, S., Santos, M.E., Roche, J.M., and Ballón, P. (2015):
{it:Multidimensional Poverty Measurement and Analysis: A Counting Approach}, Oxford 
University Press. ({browse "https://global.oup.com/academic/product/multidimensional-poverty-measurement-and-analysis-9780199689491":website}){p_end}
{marker AF2011}
{phang}Alkire, S. and Foster, J.E. (2011): Counting and Multidimensional Poverty 
Measurement. {it:Journal of Public Economics}, Vol. 95 (7-8), pp. 476-487.
({browse "https://www.sciencedirect.com/science/article/abs/pii/S0047272710001660":website}){p_end}
{marker S2022}
{phang}Suppa (2022): mpitb: A toolbox for multidimensional poverty indices. 
{it:OPHI Research in Progress} 62a, Oxford Poverty and Human Development 
Initiative (OPHI), University of Oxford [{browse "https://ophi.org.uk/rp-62a/":download}].{p_end}
{marker S2021}
{phang}Suppa (2021): The production process of the global MPI, presentation at the 
UK Stata Conference, virtual, UK. ({browse "https://www.stata.com/meeting/uk21/slides/UK21_Suppa.zip":zip})

{marker author}{...}
{title:Author}

{pstd}
Nicolai Suppa, Centre for Demographic Studies, Autonomous University of Barcelona 
(nsuppa@ced.uab.es) and Oxford Poverty and Human Development Initiative (OPHI), 
University of Oxford.
{p_end}

{pstd}
Please report bugs and other issues (including incomprehensible parts of the 
documentation) to the {browse "https://gitlab.com/nsuppa/mtb/-/issues":issue tracker} 
of the gitlab repository. Feature requests, other suggestions, and more generally
any kind of feedback is always highly welcome!{p_end}

{marker license}{...}
{title:License}

{pstd}
This software package is published under the MIT license, see 
{browse "https://gitlab.com/nsuppa/mpitb/-/blob/main/LICENSE":here} for details.{p_end}

{marker citation}{...}
{title:Citation}

{pstd}
If you publish results obtained using this software package please cite it as
{p_end}

{phang2}Suppa, Nicolai (2022): "mpitb - A toolbox for multidimensional poverty 
indices", {it:OPHI Research in Progress} 62a, Oxford Poverty and Human Development 
Initiative (OPHI), University of Oxford.
{p_end}

{marker acknowledgements}{...}
{title:Acknowledgements}

{pstd}
As this toolbox was developed in the context of several releases of the global MPI 
since 2018, its development benefited from many helpful discussions with the wider OPHI 
team, ranging from specific aspects of the estimation to user needs. 
Code, documentation or paper benefited in particular from comments made by Jakob Dirksen, 
Stephen Jenkins, Ricardo Nogales and an anonymous reviewer for the Stata Journal.
Finally, countless discussions with Usha Kanagaratnam, who is leading the global MPI 
since 2018, have been essential for both identifying the overall workflow and packaging 
parts of the code into this toolbox.{p_end}
