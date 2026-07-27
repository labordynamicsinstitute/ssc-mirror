{smcl}
{* 23jul2026}{...}
{vieweralsosee "ffrals" "help ffrals"}{...}
{title:Title}

{phang}
{bf:ffrals methods} {hline 2} Formulas for the flexible-Fourier RALS LM test

{title:Flexible-Fourier LM detrending}

{pstd}
For a Fourier frequency {it:k} the deterministic component is {it:z_t} =
({it:t}, sin(2{it:pi k t/T}), cos(2{it:pi k t/T})). The LM score series is{p_end}

{pmore}{it:S_t} = {it:y_t} - {it:psi} - {it:z_t' delta},{p_end}

{pstd}
where {it:delta} is estimated from the first-differenced regression of {it:Dy_t}
on {it:Dz_t} and {it:psi} = {it:y_1} - {it:Dz_1' delta}. The augmented LM
regression at lag {it:p} is{p_end}

{pmore}{it:Dy_t} = {it:phi S_(t-1)} + c + {it:a' Dz_t} + sum_j {it:b_j D y_(t-j)}
+ {it:e_t},{p_end}

{pstd}
and the statistic is the {it:t}-ratio on {it:phi}. The frequency {it:k} is chosen
to minimise the residual sum of squares over 1..{it:fmax}; the lag {it:p} by AIC,
BIC or the general-to-specific {it:t}-rule.

{title:RALS augmentation}

{pstd}
Let {it:e_t} be the residuals of the LM regression and {it:m2}, {it:m3} the sample
second and third moments. The RALS terms are{p_end}

{pmore}{it:w_t} = ( {it:e_t^2} - {it:m2} ,  {it:e_t^3} - {it:m3} - 3 {it:m2 e_t} ),{p_end}

{pstd}
which capture the information in the non-normality of the errors. The augmented
regression adds {it:w_t} (RALS, {cmd:rals(1)}) and, for {cmd:rals(2)}, the supplied
common and group factors:{p_end}

{pmore}{it:Dy_t} = {it:phi S_(t-1)} + c + {it:a' Dz_t} + sum_j {it:b_j Dy_(t-j)}
+ {it:g' w_t} ( + {it:h' F_t} ) + {it:e_t}.{p_end}

{pstd}
The RALS statistic is the {it:t}-ratio on {it:phi} in the augmented regression and{p_end}

{pmore}{bf:rho-squared} = sigma^2(augmented) / sigma^2(unaugmented),{p_end}

{pstd}
the variance ratio that governs the (mixture) null distribution.

{title:Monte-Carlo p-value}

{pstd}
Under the null the flexible-Fourier LM statistic converges to a functional of a
detrended Brownian motion, {it:D_k}, that depends only on the frequency {it:k} and
sample size {it:T}. {cmd:ffrals} simulates {it:D_k} by generating {it:nsim} random
walks of length {it:T} and computing the LM0 statistic of each. For the plain test
the p-value is the fraction of the simulated {it:D_k} not exceeding the observed
statistic. For the RALS test the null is the mixture{p_end}

{pmore}sqrt({it:rho2}) {it:D_k} + sqrt(1 - {it:rho2}) {it:Z},   {it:Z} ~ N(0,1),{p_end}

{pstd}
and the p-value is the fraction of this simulated mixture below the observed
statistic. This reproduces the construction of the source GAUSS routines; only the
random draws (hence a small simulation error) differ.

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
