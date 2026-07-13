{smcl}
{* *! version 1.0.0  11jul2026}{...}
{vieweralsosee "hpcm" "help hpcm"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "var" "help var"}{...}
{viewerjumpto "Overview" "hpcm_methods##over"}{...}
{viewerjumpto "One-way effect" "hpcm_methods##oneway"}{...}
{viewerjumpto "Cleaning x and y" "hpcm_methods##clean"}{...}
{viewerjumpto "The measures" "hpcm_methods##meas"}{...}
{viewerjumpto "Factorization" "hpcm_methods##fac"}{...}
{viewerjumpto "Inference" "hpcm_methods##infer"}{...}
{viewerjumpto "Step map" "hpcm_methods##map"}{...}
{viewerjumpto "Author" "hpcm_methods##author"}{...}
{title:Title}

{phang}
{bf:hpcm methods} {hline 2} the algorithm behind {helpb hpcm}, equation by equation


{marker over}{...}
{title:Overview}

{pstd}
Let {it:w(t)}=(x(t),y(t),z(t)) be a zero-mean second-order stationary process,
p1+p2+p3 = K dimensional.  {cmd:hpcm} fits a VAR({it:p}){p_end}

{p 12 12 2}A(L) w(t) = e(t),   Cov(e(t)) = Sy,   A(L)=I-A1 L-...-Ap L{c 94}p{p_end}

{pstd}
by OLS on the centered data, and works entirely from A(L) and Sy.  Index the
blocks o=(x,y) [size q=p1+p2] and 3=z [size p3].  All spectra use the convention
f({&lambda}) = (1/2{&pi}) {&Psi}(e{c 94}-i{&lambda}) Sy {&Psi}(e{c 94}-i{&lambda})*
with {&Psi}(z)=A(z){c 94}-1, so the innovation-representation transfer function is
{&Lambda}(z)=A(z){c 94}-1 Sy{c 94}1/2 and {&Lambda}(0){&Lambda}(0)'=Sy.{p_end}


{marker oneway}{...}
{title:The one-way-effect component of z}

{pstd}
z0,0,-1(t) is the residual of z(t) projected on H{x(t),y(t),z(t-1) and the past}.
At the innovation level this is simply the z-innovation orthogonalized on the
contemporaneous (x,y)-innovations:{p_end}

{p 12 12 2}z0,0,-1(t) = P e(t),   P = [ -Sy_3o Sy_oo{c 94}-1 , I(p3) ]{p_end}

{pstd}
a K-selecting p3xK matrix.  It is white noise with covariance
Sy_33.o = Sy_33 - Sy_3o Sy_oo{c 94}-1 Sy_o3 (the Schur complement), matching the
paper's ~f33({&lambda}) = (1/2{&pi}) Sy_33.o.{p_end}


{marker clean}{...}
{title:Cleaning x and y (eq 4.2)}

{pstd}
u(t) and v(t) are the residuals of x(t) and y(t) after projecting out {it:all}
leads and lags of z0,0,-1.  Removing the P-direction from the innovation covariance
gives the annihilated covariance{p_end}

{p 12 12 2}M Sy = Sy - Sy P' (Sy_33.o){c 94}-1 P Sy   (rank q),{p_end}

{pstd}
and the cleaned pair is (u,v)(t) = {&Psi}_o(L) M e(t), whose spectral density is{p_end}

{p 12 12 2}g({&lambda}) = (1/2{&pi}) {&Psi}_o(e{c 94}-i{&lambda}) (M Sy) {&Psi}_o(e{c 94}-i{&lambda})*,{p_end}

{pstd}
with {&Psi}_o = the first q rows of A(e{c 94}-i{&lambda}){c 94}-1.  This is algebraically
identical to Hosoya's eq (4.2), g = f_oo - 2{&pi} ~f_o3 ~f33{c 94}-1 ~f_3o, but is
computed in the numerically clean annihilated form above (the two agree because
M Sy M' = M Sy).{p_end}


{marker meas}{...}
{title:The partial measures}

{pstd}
Partition g into u-block (1) and v-block (2).  With {&Sigma} the one-step
prediction-error covariance of (u,v) and B(e{c 94}-i{&lambda})={&Gamma}(0)
{&Gamma}(e{c 94}-i{&lambda}){c 94}-1 its canonical factor (below):{p_end}

{p 8 12 2}{bf:Directional} (eq 4.5), with Q_b=[-{&Sigma}21{&Sigma}11{c 94}-1, I],
{&Sigma}22:1={&Sigma}22-{&Sigma}21{&Sigma}11{c 94}-1{&Sigma}12, and
~g21({&lambda})=Q_b B(e{c 94}-i{&lambda}) g({&lambda})[:,1:p1]:{p_end}

{p 14 14 2}PM(y{&rarr}x:z)({&lambda}) = ln det g11 - ln det[ g11 - 2{&pi} ~g12 {&Sigma}22:1{c 94}-1 ~g21 ]{p_end}

{p 8 12 2}PM(x{&rarr}y:z)({&lambda}) is the mirror image (swap blocks 1 and 2).{p_end}

{p 8 12 2}{bf:Association} (eq 4.6):{p_end}
{p 14 14 2}PM(x,y:z)({&lambda}) = ln det g11 + ln det g22 - ln det g{p_end}

{p 8 12 2}{bf:Reciprocity} (Theorem 4.2, by identity):{p_end}
{p 14 14 2}PM(x:y:z)({&lambda}) = PM(x,y:z)({&lambda}) - PM(x{&rarr}y:z)({&lambda}) - PM(y{&rarr}x:z)({&lambda}){p_end}

{pstd}
Each overall measure is (1/{&pi}){&int}_0{c 94}{&pi} M({&lambda})d{&lambda} (the
integrand is even in {&lambda}; Theorem 3.1 / 4.1), evaluated by the trapezoidal
rule on the grid, augmented with the {cmd:band()} endpoints so band integrals are
exact at the edges.  All measures are floored at 0 (they are non-negative in theory;
tiny negative values from quadrature are set to 0).{p_end}


{marker fac}{...}
{title:Canonical factorization of the cleaned pair}

{pstd}
The directional measures need {&Gamma}(0){&Gamma}(e{c 94}-i{&lambda}){c 94}-1.  For
a finite VAR this equals the lag polynomial evaluated on the unit circle, so
{cmd:hpcm} represents (u,v) by a long VAR({it:m}): it forms the autocovariances{p_end}

{p 12 12 2}R(h) = {&Sigma}_j {&Psi}_o(j+h) (M Sy) {&Psi}_o(j)',   {&Psi}(j)=companion MA weights,{p_end}

{pstd}
solves the multivariate Yule-Walker system Brow = rvec (block-Toeplitz){c 94}-1 for
B1..Bm and {&Sigma}=R(0)-Brow rvec', and sets B(e{c 94}-i{&lambda})=I-{&Sigma}Bk
e{c 94}-ik{&lambda}.  As m grows this converges (geometrically for a stable VAR) to
the exact canonical factor.  {cmd:mlag()} sets m; {cmd:matrunc()} truncates the R(h)
sum.{p_end}


{marker infer}{...}
{title:Wald inference (Section 6)}

{pstd}
Let {&theta}=(vec A1..Ap, vech Sy) with finite-sample covariance V (OLS:
V_A={&Sigma}{&otimes}(Z'Z){c 94}-1 for the lag block, V_S=(1/T) form for vech Sy,
independent under Gaussianity).  Let G({&theta}) collect the band measures
[PM(y{&rarr}x:z), PM(x{&rarr}y:z)].  With the numerical Jacobian
D{&theta}G (central differences) the paper's statistic reduces to{p_end}

{p 12 12 2}W = G' [ D{&theta}G V D{&theta}G' ]{c 94}-1 G  ~  {&chi}{c 178}(m),{p_end}

{pstd}
(the factor T of the textbook form cancels the T in V).  {cmd:hpcm} reports the two
single-direction tests (m=1) and the joint test (m=2).  Under H0 a measure lies on
the boundary 0, so D{&theta}G may be near zero and the {&chi}{c 178} is conservative;
this is a documented property of the method.{p_end}


{marker map}{...}
{title:Step -> equation map}

{p2colset 6 40 42 2}{...}
{p2col:{bf:code step}}{bf:paper reference}{p_end}
{p2col:hpcm_fit (OLS VAR of x,y,z)}Section 5, eq (5.5); Sec 3 factorization{p_end}
{p2col:hpcm_msig (P, Sy_33.o, M Sy)}Sec 2-4, one-way component; ~f33{p_end}
{p2col:g = (1/2{&pi}) {&Psi}_o M Sy {&Psi}_o*}eq (4.2){p_end}
{p2col:hpcm_acov + hpcm_yw}Sec 3 canonical factorization; Hosoya (1991){p_end}
{p2col:directional M({&lambda})}eq (3.9)-(3.11), (4.4)-(4.5){p_end}
{p2col:association M({&lambda})}eq (4.6){p_end}
{p2col:reciprocity M({&lambda})}Theorem 4.2, eq (4.8){p_end}
{p2col:overall = (1/{&pi}){&int}M}Theorem 3.1 / 4.1{p_end}
{p2col:difference()}Sec 5 reproducible reduction, eq (5.4){p_end}
{p2col:Wald test}Section 6{p_end}


{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
