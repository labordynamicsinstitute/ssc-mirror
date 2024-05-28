{smcl}
{* *! version 1.0 27.05.2024}{...}
{* *! Lars Zeigermann}{...}

{cmd:help mixlelast}

{hline}

{title:Title}

{phang}
{bf:mixlelast} {hline 2} Mixed logit sample elasticities and marginal 
effects

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:mixlelast}
{ifin}
{cmd:,}
{bind:{cmdab:alternatives(}varname{cmd:)}[{it:options}]}

{synoptset 32 tabbed}{...}
{synopthdr :options}
{synoptline}
{syntab:Main}
{p2coldent :* {opth alt:ernatives(varname)}}use {it:varname} to identify alternatives{p_end}
{synopt:{opth for(varname)}}compute elasticities/marginal effects for {it: varname}{p_end}
{synopt:{opt marginal:effects}}compute marginal effects; default is elasticities{p_end}
{synopt:{opt absolute:change(#)}}compute arc elasticities/marginal effects for an attribute change of #{p_end}
{synopt:{opt percent:change(#)}}compute arc elasticities/marginal effects for an attribute change of # percent{p_end}
{synopt:{opt dum:my}}compute arc elasticities/marginal effects for a dummy change{p_end}
{synopt:{opt w:eighted}}probability weighted sample elasticities/marginal effects; default is unweighted{p_end}
{synopt:{opt nrep(#)}}set number of Halton draws to #{p_end}
{synopt:{opt burn(#)}}drop # initial elements from Halton sequences{p_end}

{syntab:Reporting}
{synopt:{opt nosd}}do not compute standard deviations{p_end}
{synopt:{opt qui:etly}}suppress output{p_end}

{syntab:Heterogeneous Choice Sets}
{synopt:{opth het:type(type)}}specifies aggregation type if choice sets are heterogeneous; type may be I, IIa or IIb. Default is I.{p_end}

{syntab:Krinsky-Robb Bootstrap}
{synopt:{opt kr:obb(#)}}set number of repetitions for Krinksy-Robb bootstrap to #{p_end}
{synopt:{opth krse(varname)}}compute standard errors; default is confidence intervals{p_end}
{synopt:{opt krlevel(#)}}set confidence level; default is level(95){p_end}
{synopt:{opt krburn(#)}}drop # initial elements from Halton sequences for Krinsky-Robb bootstrap{p_end}
{synopt:{opt kruser:draws}}use user-provided random numbers for Krinksy-Robb bootstrap{p_end}
{synoptline}
{pstd}
* {opth alternatives(varname)} is required.
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:mixlelast} is a post-estimation command for {cmd: mixlogit} (Hole 2007) that computes mixed logit samlpe elasticities and marginal 
effects. It produces a matrix of dimension JxJ, where J is the number alternatives. Diagonal elements are direct effects, off-diagonal 
elements are cross effects where each entry is the effect on the row alternative given an attribute change in the column alternative. Unless 
the nosd option is specified, {cmd:mixlelast} reports standard deviations in addition to the average effects over all decision makers 
in the sample.{p_end}

{pstd} {cmd:mixlelast} allows the user to compute elasticities/marginal effects for marginal attribute changes (point method), which is the 
default, or for non-marginal changes (arc method). Non-marginal changes can be either be specified as a percentage or an absolute change. The 
dummy option allows the user to obtain effects for dummy variables.{p_end}

{pstd}
With heterogeneous choice sets, i.e. when alternatives are not identical across choice situations, the user can choose between different types of 
aggregation, namely type I, IIa or IIb, see details below.{p_end}

{pstd}
{cmd:mixlelast} further allows to obtain standard errors and confidence intervals computed by the Krinsky-Robb parametric bootstrap. For the Krinsky-Robb 
parametric bootstrap, multiple vectors of coefficients are drawn from a multivariate normal distribution with mean and covariance as estimated 
by {cmd:mixlogit}. For each draw, the JxJ matrix of elasticities/marginal effects is computed. The standards errors are then 
the quare roots of the variances. Alternatively, confidence intervals on a user-specified confidence level can be obtained.{p_end}


{marker options}{...}
{title:Options for {cmd:mixlelast}}

{dlgtab:Main}

{phang}
{opth alternatives(varname)} is required and specifies the variable identifying the alternatives.

{phang}
{opth for(varname)} specifies the variable for which elasticities/marginal effects are calculated. The default is the first variable specifed in 
mixlogit's {opt rand()} option. Elasticities/marginal effects can be computed for all fixed and random independent variables specified in 
{cmd:mixlogit}.

{phang}
{opt marginaleffects} allows the user to obtain marginal effects. The default is elasticities.

{phang}
{opt percentchange(#)} allows the user to compute arc elasticities/marginal effects for an attribute change of # percent. This 
option cannot be combined with {opt absolutechange} and {opt dummy}.

{phang}
{opt absolutechange(#)} allows the user to compute arc elasticities/marginal effects for an absolute attribute change of #. 
This option cannot be combined with [opt percentchange} and {opt dummy}.

{phang}
{opt dummy} allows the user to compute arc elasticities/marginal effects for dummy variables.
This option cannot be combined with {opt percentchange} and {opt absolutechange}.

{phang}
{opt weighted} specifies that probability weighted sample averages are calculated. The default is unweighted sample averages.

{phang}
{opt nrep(#)} set number of Halton draws to #. The default is the number of draws specified in {cmd :mixlogit}, which has a default of 50 draws}.

{phang}
{opt burn(#)} specifies the number of initials elements dropped then creating the Halton sequences. The default is {opt burn(15)}.

{dlgtab:Reporting}

{phang}
{opt quietly} suppresses the output. This might be useful if the number of alternatives and hence the output table is large. All results are 
stored in {cmd:r()}.{p_end}

{phang}
{opt nosd} prevents {cmd:mixlelast} from computing standard deviations. For large data sets with many alternatives, this saves significantly on 
memory.{p_end}

{dlgtab:Heterogeneous Choice Sets}

{phang}{marker hettype}{...}
{opt hettype(type)} specifies the type of aggregation when choice sets are heterogeneous. Type may be I, IIa or IIb. The default is I.

{pmore} type I: average over all decision makers in the sample, even if they do not have the respective alternative/s in their choice set. 
(Note: individual effects are set to zero if the alternative/s were not present in the individual choice set)

{pmore}type IIa: for direct effects, average over all individuals who have the respective alternative in their choice set. For cross effects 
average over who have the row alternative in their choice set (not matter if the column alternative is in the decision maker's choice set 
or not)

{pmore} type IIb: for direct effects, see type IIa. For cross effects, consider only those decision makers who have both the row and the column 
alternative in their choice set.

{dlgtab:Krinsky-Robb Parametric Bootstrap}

{phang}
{opth krobb(real)} specifies the number of repetitions used in Krinsky-Robb parametric bootstrap to obtain standard errors or 
confidence intervalls.{p_end}

{phang}
{opt krse} specifies that standard errors are displayed. The default is confidence intervals.

{phang}
{opt krlevel(#)} set confidence level for Krinsky-Robb bootstrap. The default is {opt level(95)}.

{phang}
{opt krburn(#)} sets the number of initial values from the sequence dropped to #. The default is {opt krburn(15)}.{p_end}

{phang}
{opt kruserdraws} allows the user to provide (pseudo-)random numbers in a Mata matric (mixl_KRUSERDRAWS). The matrix must have the number of
rows equal to the number coefficients in the model and the number of columns equal to the number of choice occasions times the number of 
repititions. If kruserdraws is not specified, the default is Halton draws for up to 10 coefficients and random draws otherwise.{p_end}



{marker example}{...}
{title:Examples}

{pstd}
Load data with homogeneous choice sets
{p_end}
{phang2}
{stata `"use choice_hom.dta, clear"'}
{p_end}

{pstd}
Fit mixed logit model{p_end}
{phang2}
{stata `"mixlogit y brand quality, rand(price) group(gid) id(pid) "'}
{p_end}

{pstd}
Obtain elasticities for a marginal change in price{p_end}
{phang2}
{stata `"mixlelast, alternatives(alt)"'}
{p_end}

{pstd}
Compute probability-weighted elasticities without standard deviations
{p_end}
{phang2}
{stata `"mixlelast, alternatives(alt) weighted nosd"'}
{p_end}

{pstd}
Compute elasticities for an increase in quality of 1
{p_end}
{phang2}
{stata `"mixlelast, alternatives(alt) for(quality) absolutechange(1)"'}
{p_end}

{pstd}
Obtain marginal effects
{p_end}
{phang2}
{stata `"mixlelast, altid(alt) marginal"'}
{p_end}

{pstd}
Use Krinsky-Robb parametric bootstrap to get 90 percent confidence intervals with 500 repetitions
{p_end}
{phang2}
{stata `"mixlelast, altid(alt) krobb(500) level(90)"'}
{p_end}

{hline}

{pstd}
Load data with heterogeneous choice set
{p_end}
{phang2}
{stata `"use choice_het.ado, clear"'}
{p_end}

{pstd}
Compute elasticities of type I (default)
{p_end}
{phang2}
{stata `"mixlelast, altid(alt)"'}
{p_end}

{pstd}
Obtain elasticities of type IIa
{p_end}
{phang2}
{stata `"mixlelast, altid(alt) hettype(IIa)"'}
{p_end}

{hline}


{marker storedresults}{...}
{title:Stored results}

{pstd}
{cmd:mixlelast} saves the following results to {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}} number of observations{p_end}
{synopt:{cmd:r(N_group)}} number of choice occasions{p_end}
{synopt:{cmd:r(N_id)}} number of decision makers{p_end}
{synopt:{cmd:r(N_alt)}} number of alternatives{p_end}
{synopt:{cmd:r(het)}} 1 if heterogeneous choice sets, 0 otherwise{p_end}
{synopt:{cmd:r(absolutechange)}} absolute change in attribute{p_end}
{synopt:{cmd:r(percentchange)}} percentage change in attribute{p_end}
{synopt:{cmd:r(marginal)}} 1 if marginal effects, 0 if elasticities{p_end}
{synopt:{cmd:r(weighted)}} 1 if probability weighted, 0 otherwise{p_end}
{synopt:{cmd:r(nosd)}} 1 if standard deviations suppressed, 0 
otherwise{p_end}
{synopt:{cmd:r(nrep)}} number of repetitions{p_end}
{synopt:{cmd:r(burn)}} number of initial to drop when creating Halton 
sequence{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}} {cmd:mixlelast}{p_end}
{synopt:{cmd:r(group)}} name of {opt group()} variable{p_end}
{synopt:{cmd:r(id)}} name of {opt id()} variable{p_end}
{synopt:{cmd:r(alternatives)}} name of variable identifying 
alternatives{p_end}
{synopt:{cmd:r(for)}} name of variable for which effects are computed{p_end}
{synopt:{cmd:r(method)}} calculation method{p_end}
{synopt:{cmd:r(change)}} type of change in {opt for()} variable{p_end}
{synopt:{cmd:r(hettype)}} type of aggregation for heterogeneous choice 
sets{p_end}
{synopt:{cmd:r(title)}} title of output table{p_end}
{synopt:{cmd:r(subtitle)}} subtitle of output table{p_end}
{synopt:{cmd:r(krsubtitle)}} subtitle if Krinsky-Robb bootstrap{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(mean)}} matrix of mean elasticities/marginal effects{p_end}
{synopt:{cmd:r(sd)}} matrix of standard deviations{p_end}
{synopt:{cmd:r(krse)}} matrix of standard errors if Krinsky-Robb 
bootstrap{p_end}
{synopt:{cmd:r(CI_upper)}} matrix of lower bounds of confidence 
intervals if Krinsky-Robb bootstrap{p_end}
{synopt:{cmd:r(CI_lower)}} matrix of upper bounds of confidence 
intervals if Krinsky-Robb bootstrap{p_end}


{title:References}

{phang}
Hole, A. R. 2007.
{browse 
"http://www.stata-journal.com/article.html?article=st0133":Fitting Mixed 
Logit Models by Using Maximum Simulated Likelihood}.
{it:Stata Journal} 7: 388-401.

{phang}
Krinsky I., and A. Robb. 1986. On Approximating the Statistical 
Properties of Elasticities. Review of Economics and Statistics. 68(4):715-9.

{phang}
Krinsky I., and A. Robb. 1990. On Approximating the Statistical 
Properties of Elasticities: A Correction. Review of Economics and 
Statistics. 72(1):189-90.

{phang}
Revelt, D., and K. Train. 2000. Customer-specific Taste Parameters and Mixed
Logit: Households' Choice of Electricity Supplier. Working Paper, Department
of Economics, University of California, Berkeley.

{phang}
Train, K. E. 2009. {it:Discrete Choice Methods with Simulation}.
Cambridge: Cambridge University Press.


{title:Author}

{pstd}
Lars Zeigermann, {browse 
"mailto:lars.zeigermann@posteo.de":lars.zeigermann@posteo.de}.{p_end}

{title:Acknowledgements}

{pstd}
I would like to thank Anna Lu and Arne Risa Hole for very helpful 
comments and suggestions. {cmd:mixlelast} builds on {cmd:mixlpred} (Hole 
2007). All remaining errors are my own.
{p_end}

