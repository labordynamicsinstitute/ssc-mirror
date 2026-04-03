{smcl}
{* *! version 2.7.1 26mar2026  Ben A. Dwamena (University of Michigan)}

{vieweralsosee "midas" "help midas"}{...}
{vieweralsosee "midas_kendall" "help midas_kendall"}{...}
{vieweralsosee "midas_chiplot" "help midas_chiplot"}{...}
{vieweralsosee "midas_bvsroc" "help midas_bvsroc"}{...}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{cmd:midas_bivbox} {hline 2}}Robust bivariate boxplot for diagnostic test accuracy data{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 16 2}
{cmd:midas_bivbox} {it:tp} {it:fp} {it:fn} {it:tn} {ifin}
[{cmd:,} {opt robust} {opt classical}
{opt id(varname)}
{opt cutoff(#)}
{opt cc(#)}
{opt labeloutliers}
{opt innerlevel(#)}
{opt outerpattern(string)}
{opt innerpattern(string)}
{opt aspect(#)}
{opt xtitle(string)}
{opt ytitle(string)}
{opt title(string)}
{opt subtitle(string)}
{opt name(name)}
{opt replace}
{opt normtest}
{opt robnormtest}
{opt bacontest}
{it:twoway_options}]

{title:Description}

{pstd}
{cmd:midas_bivbox} draws a bivariate boxplot for diagnostic test accuracy
meta-analysis. Counts are internally transformed to logit sensitivity and
logit specificity. The plot shows an inner ellipse (central region), an outer
ellipse (outlier fence), and two symmetry lines.

{title:Options}

{phang}{opt robust} robust estimation (default).{p_end}
{phang}{opt classical} classical estimation.{p_end}
{phang}{opt cc(#)} continuity correction; default {cmd:0.5}.{p_end}
{phang}{opt cutoff(#)} outer ellipse multiplier; default {cmd:7}.{p_end}
{phang}{opt innerlevel(#)} inner ellipse quantile; default {cmd:0.50}.{p_end}
{phang}{opt id(varname)} study identifier.{p_end}
{phang}{opt labeloutliers} label studies outside the outer ellipse.{p_end}
{phang}{opt normtest} classical multivariate normality test ({cmd:mvtest normality}).{p_end}
{phang}{opt robnormtest} robust QQ ellipticity diagnostic.{p_end}
{phang}{opt bacontest} BACON multivariate outlier screening (requires {cmd:ssc install bacon}).{p_end}

{title:Stored results}

{pstd}Scalars: {cmd:r(n)}, {cmd:r(n_out)}, {cmd:r(corr)}, {cmd:r(cc)}, {cmd:r(cutoff)}{p_end}
{pstd}Matrices: {cmd:r(center)}, {cmd:r(scale)}, {cmd:r(bounds)}{p_end}
{pstd}Locals: {cmd:r(link)}, {cmd:r(input_mode)}, {cmd:r(diag_color)}, {cmd:r(diag_text)}{p_end}
{pstd}robnormtest: {cmd:r(robnorm_rqq)}, {cmd:r(robnorm_slope)}, {cmd:r(robnorm_intercept)}, {cmd:r(robnorm_maxdev)}{p_end}
{pstd}bacontest: {cmd:r(bacon_outliers)}, {cmd:r(bacon_prop)}{p_end}
{pstd}normtest: {cmd:r(normtest_p)}{p_end}

{title:Examples}

{phang2}{cmd:. midas_bivbox tp fp fn tn}{p_end}
{phang2}{cmd:. midas_bivbox tp fp fn tn, robust id(study) labeloutliers}{p_end}
{phang2}{cmd:. midas_bivbox tp fp fn tn, robust robnormtest}{p_end}
{phang2}{cmd:. midas_bivbox tp fp fn tn, normtest}{p_end}

{title:Author}

{pstd}Ben Adarkwa Dwamena, MD{break}
University of Michigan{break}
bdwamena@umich.edu
