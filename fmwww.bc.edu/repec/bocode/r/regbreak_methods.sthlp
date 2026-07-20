{smcl}
{* *! version 1.0.0  19jul2026}{...}
{vieweralsosee "regbreak" "help regbreak"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Model" "regbreak_methods##model"}{...}
{viewerjumpto "Bai-Perron procedure" "regbreak_methods##bp"}{...}
{viewerjumpto "Joint variance-coefficient tests" "regbreak_methods##joint"}{...}
{viewerjumpto "UDmax" "regbreak_methods##udmax"}{...}
{viewerjumpto "Error options" "regbreak_methods##errors"}{...}
{viewerjumpto "Step-to-code map" "regbreak_methods##map"}{...}
{viewerjumpto "Author" "regbreak_methods##author"}{...}
{title:Title}

{phang}
{bf:regbreak methods} {hline 2} Methods and formulas for {helpb regbreak}

{marker model}{...}
{title:The model}

{pstd}
Consider the linear regression with {it:m} coefficient breaks and {it:n} variance
breaks partitioning {it:1,...,T} into segments,

{p 8 8 2}{it:y_t = z_t' {c 100}_j + x_t' {c 946} + u_t},{space 4}Var({it:u_t}) = {it:{c 963}_k^2},{p_end}

{pstd}
where {it:z_t} ({it:q}{c 215}1) carries the coefficients that {it:change} across
regimes, {it:x_t} ({it:p}{c 215}1) carries coefficients that are {it:constant},
{it:{c 100}_j} is the coefficient vector of coefficient-regime {it:j}, and
{it:{c 963}_k^2} is the error variance of variance-regime {it:k}. The coefficient
and variance break dates need not coincide. Bai & Perron (1998) is the special
case {it:n{c 61}0} (constant variance); the pure mean-shift model is
{it:z_t{c 61}1}, {it:p{c 61}0}.

{marker bp}{...}
{title:Bai-Perron coefficient-break procedure (default)}

{pstd}
{bf:1. Global minimization.} For each {it:m}, the break dates minimize the total
sum of squared residuals. A dynamic-programming recursion evaluates the SSR of
every admissible segment once and inserts breaks optimally, so that only
{it:O(T{c 178})} least-squares problems are solved
({help regbreak_methods##map:{cmd:rb_dating}}; partial-change model
{cmd:rb_datingpart}).

{pstd}
{bf:2. Sup F test of 0 vs. m breaks.} With {c 100} the stacked regime
coefficients and {it:R} the ({it:mq}{c 215}({it:m}+1){it:q}) matrix that
differences adjacent regimes,

{p 8 8 2}{it:F(m) = [(T{c 45}(m+1)q{c 45}p)/(T m)] {c 183} {c 100}'R'[R V R']^{c 45}{c 185}R {c 100}},{p_end}

{pstd}
where {it:V} is the (optionally HAC) covariance of {c 100}
({cmd:rb_pftest}, {cmd:rb_pvdel}).

{pstd}
{marker udmax}{bf:3. UDmax.} The double-maximum statistic
{it:UDmax = max_m F(m)} guards against a poor choice of {it:m}; its critical
values are tabulated separately ({cmd:rb_cvdmax}).

{pstd}
{bf:4. Sequential Sup F(l+1|l).} Given the {it:l} global breaks, each segment is
searched for one more break and the largest resulting F is compared with the
sequential critical value ({cmd:rb_spflp1}). The estimated number of breaks is
the first {it:l} that is not rejected.

{pstd}
{bf:5. Information criteria.} BIC (Yao 1988), LWZ (Liu-Wu-Zidek 1997) and the
modified KT criterion (Kurozumi-Tuvaandorj 2011) are minimized over {it:m}
({cmd:rb_ic}).

{pstd}
{bf:6. Break-date confidence intervals.} Under the shrinking-shifts asymptotics
the standardized break date has the Bai (1997) limiting distribution; its
quantiles are obtained by numerically inverting the density
({cmd:rb_funcg}, {cmd:rb_cvg}) and mapped to date bounds ({cmd:rb_interval}).
Corrected coefficient standard errors come from the diagonal of {it:V}
({cmd:rb_estim}).

{marker joint}{...}
{title:Joint variance-and-coefficient tests ({opt joint})}

{pstd}
{bf:1. Labelings.} With {it:m} coefficient and {it:n} variance breaks there are
{it:K} distinct dates, each tagged as a coefficient break, a variance break, or
both. Every admissible tagging is enumerated ({cmd:rb_numcase},
{cmd:rb_brcvcase}) and the statistic maximized over them.

{pstd}
{bf:2. Joint dating.} For a given labeling the break dates are estimated by the
Qu & Perron (2007) algorithm: an MLE dynamic program locates the {it:K} dates
({cmd:rb_dating_MLE}, {cmd:rb_mlef}), a restriction matrix splits them into
coefficient and variance breaks ({cmd:rb_segmake}), feasible GLS estimates the
regime coefficients under the regime variances ({cmd:rb_estimbr}), and the
variance-break dates are refined by maximizing the Gaussian segment likelihood
({cmd:rb_dating_M2}) until convergence ({cmd:rb_estdate}).

{pstd}
{bf:3. The five sup-LR statistics}
({cmd:rb_pslr0}{c 45}{cmd:rb_pslr4}):

{p2colset 9 22 24 2}{...}
{p2col:Sup LR}{it:m} coefficient breaks given {it:no} variance breaks{p_end}
{p2col:Sup LR1}{it:n} variance breaks given {it:no} coefficient breaks{p_end}
{p2col:Sup LR2}{it:n} variance breaks given {it:m} coefficient breaks{p_end}
{p2col:Sup LR3}{it:m} coefficient breaks given {it:n} variance breaks{p_end}
{p2col:Sup LR4}{it:m} coefficient {it:and} {it:n} variance breaks, jointly{p_end}
{p2colreset}{...}

{pstd}
The coefficient piece is a HAC-robust Wald form and the variance piece is scaled
by the two-sided long-run correction {it:{c 966}}
({cmd:rb_correct1}); LR4 combines them.

{pstd}
{bf:4. UDmax4} maximizes Sup LR4 over 1{c 45}{it:M} and 1{c 45}{it:N}
({cmd:rb_cvdmax4}).

{pstd}
{bf:5. Sequential SeqLR9 / SeqLR10} test {it:m}+1 versus {it:m} coefficient
breaks given {it:n} variance breaks, and {it:n}+1 versus {it:n} variance breaks
given {it:m} coefficient breaks ({cmd:rb_pslr9}, {cmd:rb_pslr10}); the estimated
dates come from {cmd:rb_jdateestim}.

{marker errors}{...}
{title:Error options}

{p2colset 9 22 24 2}{...}
{p2col:{opt robust}}HAC covariance (quadratic-spectral kernel, Andrews (1991)
AR(1) bandwidth) versus i.i.d.{p_end}
{p2col:{opt prewhite}}AR(1) prewhitening of {it:z_t u_t} before the kernel.{p_end}
{p2col:{opt hetdat}}segment-specific data moment matrices in {it:V}.{p_end}
{p2col:{opt hetvar}}segment-specific residual variances in {it:V}.{p_end}
{p2col:{opt hetomega}}segment-specific long-run variances in the break-date CI.{p_end}
{p2col:{opt hetq}}segment-specific data moments in the break-date CI.{p_end}
{p2col:{opt vrobust}}robust long-run correction for the variance statistics.{p_end}
{p2col:{opt typek}}residuals used to build the kernel: H0, H1 or hybrid.{p_end}
{p2colreset}{...}

{marker map}{...}
{title:Step-to-code map}

{pstd}The engine is a Mata library ({cmd:lregbreak.mlib}); each paper step maps to
a named function:{p_end}

{p2colset 9 30 32 2}{...}
{p2col:SSR dynamic program}{cmd:rb_dating}, {cmd:rb_parti}, {cmd:rb_ssr}{p_end}
{p2col:partial-change dating}{cmd:rb_datingpart}{p_end}
{p2col:variance-LR dating}{cmd:rb_dating_M2}, {cmd:rb_parti2}{p_end}
{p2col:joint MLE dating}{cmd:rb_dating_MLE}, {cmd:rb_mlef}{p_end}
{p2col:FGLS estimation}{cmd:rb_estimbr}, {cmd:rb_estdate}{p_end}
{p2col:labelings}{cmd:rb_numcase}, {cmd:rb_brcvcase}, {cmd:rb_segmake}{p_end}
{p2col:HAC / long-run var}{cmd:rb_correct1}, {cmd:rb_hac}, {cmd:rb_jhatpr1}, {cmd:rb_bandw}{p_end}
{p2col:Sup F / covariance}{cmd:rb_pftest}, {cmd:rb_pvdel}, {cmd:rb_psigmq}{p_end}
{p2col:sequential Sup F}{cmd:rb_spflp1}, {cmd:rb_onebp}{p_end}
{p2col:break-date CI}{cmd:rb_interval}, {cmd:rb_cvg}, {cmd:rb_funcg}{p_end}
{p2col:information criteria}{cmd:rb_ic}{p_end}
{p2col:Sup LR0-4}{cmd:rb_pslr0} ... {cmd:rb_pslr4}{p_end}
{p2col:SeqLR9 / SeqLR10}{cmd:rb_pslr9}, {cmd:rb_pslr10}, {cmd:rb_jdateestim}{p_end}
{p2col:critical values}{cmd:rb_cv1}, {cmd:rb_cv2}, {cmd:rb_cv4}, {cmd:rb_cvdmax}, {cmd:rb_cvdmax4}{p_end}
{p2colreset}{...}

{pstd}
The Bai-Perron path is verified against the {cmd:mbreaks} R package and the joint
path against the Perron{c 45}Yamamoto{c 45}Zhou MATLAB programs; on the reference
data sets the statistics, break dates, coefficients and confidence intervals
agree to machine precision.

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
