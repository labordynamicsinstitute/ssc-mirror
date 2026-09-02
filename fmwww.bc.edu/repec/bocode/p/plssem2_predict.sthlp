{smcl}
{* *! version 1.0.0  19Aug2026}{...}
{viewerjumpto "Syntax" "plssem2_predict##syntax"}{...}
{viewerjumpto "Description" "plssem2_predict##description"}{...}
{viewerjumpto "Options" "plssem2_predict##options"}{...}
{viewerjumpto "Examples" "plssem2_predict##examples"}{...}
{title:Title}

{p 4 18 2}
{hi:plssem2 predict} -- Latent variable (composite) scores after
{helpb plssem2}

{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{cmd:predict} [{it:type}] {it:newvarlist} {ifin} [{cmd:,} {it:{help plssem2_predict##options:options}}]

{marker description}{...}
{title:Description}

{pstd}
{cmd:predict} after {cmd:plssem2} creates new variables containing the
estimated latent variable (composite) scores.  By default, scores are
generated for {bf:all} latent variables of the model, so the number of
variables in {it:newvarlist} must equal {cmd:e(k_lv)}.  Use the {cmd:lv()}
option to request scores for a subset of latent variables.

{pstd}
The scores are the composite scores of the final PLS solution:
score_ij = sum_k w_jk x_ik (with standardized indicators unless the
{cmd:noscale} option was used), standardized to mean 0 and variance 1.

{marker options}{...}
{title:Options}

{phang}{opt lv(lvlist)}
a list of latent variable names of the model (see {cmd:e(lvs)}) for which
the scores are requested.  The number of new variables must equal the
number of latent variables requested.  Example:
{cmd:predict s_esg s_hqd, lv(ESG HQD)}.

{marker examples}{...}
{title:Examples}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. use esg_simdata, clear}{p_end}
{phang2}{cmd:. plssem2 (E > e1-e4) (S > s1-s4) (G > g1-g4) (RA > ra1-ra4) (MP > mp1-mp4) (RM > rm1-rm4)} ///{break}
{cmd: (Innov > in1-in4) (Effic > ef1-ef4) (Green > gr1-gr4), } ///{break}
{cmd: structural(HQD RA MP RM ESG, RA ESG, MP ESG, RM ESG)} ///{break}
{cmd: higher("ESG: E S G, formative; HQD: Innov Effic Green, reflective")}{p_end}

{pstd}Scores of all latent variables{p_end}
{phang2}{cmd:. predict E S G RA MP RM Innov Effic Green ESG HQD}{p_end}

{pstd}Scores of two latent variables{p_end}
{phang2}{cmd:. predict sc_esg sc_hqd, lv(ESG HQD)}{p_end}

{pstd}Use the scores in a regression{p_end}
{phang2}{cmd:. regress sc_hqd sc_esg ra mp rm}{p_end}
    {hline}

{title:Also see}

{p 4 6 2}
{helpb plssem2:plssem2} -- Partial least squares structural equation
modeling{p_end}
{p 4 6 2}
{helpb plssem2_estat:plssem2 postestimation} -- Postestimation commands{p_end}
