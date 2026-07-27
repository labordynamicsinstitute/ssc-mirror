{smcl}
{* 23jul2026}{...}
{vieweralsosee "xtbreaklm" "help xtbreaklm"}{...}
{vieweralsosee "xtpdroot (library)" "help xtpdroot"}{...}
{title:Title}

{phang}
{bf:xtbreaklm methods} {hline 2} Formulas for the panel LM tests with breaks

{title:Enders-Lee flexible-Fourier panel LM}

{pstd}
For each unit the LM detrending regression uses a broken trend approximated by a
Fourier expansion. Let {it:z_t} = ({it:t}, sin(2{it:pi k t/T}), cos(2{it:pi k
t/T})) for {it:k}=1..{it:m}. The score (LM) series is{p_end}

{pmore}{it:S_t} = {it:y_t} - {it:psi} - {it:z_t' delta},{p_end}

{pstd}
where {it:delta} is estimated from the differenced regression {it:Dy_t} on
{it:Dz_t} and {it:psi} = {it:y_1} - {it:z_1' delta}. The test statistic is the
t-ratio {it:tau} on {it:phi} in{p_end}

{pmore}{it:Dy_t} = {it:phi S_(t-1)} + {it:Dz_t' gamma} + sum_j {it:c_j D S_(t-j)}
+ {it:e_t}.{p_end}

{pstd}
The number of lags is chosen by AIC, BIC or the general-to-specific t-rule
(t=1.645). Each {it:tau_i} is mapped to a p-value {it:p_i} through the MacKinnon-
type response surface of the Fourier LM distribution (indexed by {it:m} and the
selected lag length), and the p-values are pooled:{p_end}

{pmore}{bf:P}  = -2 sum_i ln({it:p_i})  ~ chi2(2N){p_end}
{pmore}{bf:Pm} = (P - 2N) / sqrt(4N)    ~ N(0,1){p_end}
{pmore}{bf:Choi Z} = sum_i {c -(} Phi^{c -(}-1{c )-}({it:p_i}){c )-} / sqrt(N)
~ N(0,1).{p_end}

{title:Lee-Tieslau two-break panel LM}

{pstd}
Each unit is tested for a unit root allowing {it:two} sharp breaks in level and
trend. With break dates ({it:TB1},{it:TB2}) the deterministic block is{p_end}

{pmore}{it:z_t} = ({it:t}, {it:DU1_t}, {it:DT1_t}, {it:DU2_t}, {it:DT2_t},
{it:D1_t}, {it:D2_t}),{p_end}

{pstd}
where {it:DU} are level dummies, {it:DT} broken trends and {it:D} one-time
impulse dummies. The LM score series {it:S_t} is formed as above, rescaled within
each regime (the Lee-Strazicich transformation), and the augmented LM regression
gives the t-ratio {it:tau}. The two break dates are chosen by grid search over
15%-85% of the sample to {it:minimize} {it:tau}. The panel statistic is the
standardized cross-unit average{p_end}

{pmore}{bf:Panel LM} = sqrt(N) ( mean_i {it:tau_i} - E ) / sqrt(V),{p_end}

{pstd}
where (E,V) are the mean and variance of the individual LM statistic under the
null, read from the tabulated two-trend-break moments as a function of the number
of lags and the time dimension {it:T}. Under the null {bf:Panel LM} ~ N(0,1) and
rejects for large negative values.

{title:Notes on replication}

{pstd}
The augmentation-lag maximum {cmd:pmax(3)} reproduces the panel results reported
in Nazlioglu et al. (2023). Because the general-to-specific rule trims downward
from {it:pmax}, changing {cmd:pmax()} changes the selected lag and hence the
statistic, exactly as in the original GAUSS routines.

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
