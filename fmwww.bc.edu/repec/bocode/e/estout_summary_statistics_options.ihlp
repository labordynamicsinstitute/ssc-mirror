{p 4 8 2}
{cmd:stats(}{it:scalarlist}[{cmd:,} {it:stats_subopts}]{cmd:)} specifies one or
more scalar statistics - separated by white space - to be displayed
at the bottom of the table. The {it:scalarlist} may contain {cmd:e()}
scalars and the following statistics:

{p 12 18 2}{cmd:aic}{space 5}Akaike's information criterion{p_end}
{p 12 18 2}{cmd:bic}{space 5}Schwarz's information criterion{p_end}
{p 12 18 2}{cmd:rank}{space 4}rank of {cmd:e(V)}, i.e. the number of free parameters in model{p_end}
{p 12 18 2}{cmd:p}{space 7}the p-value of the model (overall model significance)

{p 8 8 2}
See help {help estimates} for details on the {cmd:aic} and {cmd:bic} statistics.
The rules for the determination of {cmd:p} are as follows (note that although
the procedure outlined below is appropriate for most models, there might be
some models for which it is not):

{p 12 15 2}
    1) p-value provided: If the {cmd:e(p)} scalar is provided by the
    estimation command, it will be interpreted as indicating the p-value
    of the model.

{p 12 15 2}
    2) F test: If {cmd:e(p)} is not provided, {cmd:estout} checks for the
      presence of the {cmd:e(df_m)}, {cmd:e(df_r)}, and {cmd:e(F)}
      scalars and, if they are present, the p-value of the model will be
      calculated as {cmd:Ftail(df_m,df_r,F)}. This p-value corresponds to
      the standard overall  F test of linear regression.

{p 12 15 2}
    3) chi2 test: Otherwise, if neither {cmd:e(p)} nor {cmd:e(F)} is
      provided, {cmd:estout} checks for the presence of {cmd:e(df_m)} and
      {cmd:e(chi2)} and, if they are present, calculates the p-value as
      {cmd:chi2tail(df_m,chi2)}. This p-value corresponds to the
      Likelihood-Ratio or Wald chi2 test.

{p 12 15 2}
    4) If neither {cmd:e(p)}, {cmd:e(F)}, nor {cmd:e(chi2)}
      is available, no p-value will be reported.

{p 8 8 2}
The following {it:stats_subopts} are available. Use:

{p 12 16 2}
  {cmd:fmt(}{it:fmtlist}{cmd:)} to set the display formats for the scalar
  statistics in {it:scalarlist}. For instance, {cmd:fmt(%9.3f %9.0f)}
  would be a good choice for {cmd:stats(r2_a N)}. See help {help format}. The
  last format in {it:fmtlist} is used for the remaining scalars if
  {it:scalarlist} has more elements than {it:fmtlist} does. Thus, only one
  format need be specified if all scalars are to be displayed in the same
  format. If no format is specified, the default format is the display format
  of the coefficients.

{p 12 16 2}
  {cmd:labels(}{it:str_list}[{cmd:,} {it:{help estout_label_subopts:label_subopts}}]{cmd:)} 
  to specify labels for the scalars in {it:scalarlist}. If specified, the labels are
  used instead of the scalar names. For example:

{p 20 20 2}
{cmd:. estout ..., stats(r2_a N, labels("Adj. R-Square" "Number of Cases"))}

{p 12 16 2}
  {cmd:star}[{cmd:(}{it:star_scalarlist}{cmd:)}] to specify that the overall
  significance of the model be denoted by stars. The stars are attached to
  the scalar statistics specified in {it:star_scalarlist}. If
  {it:star_scalarlist} is omitted, the stars are attached to the first
  reported scalar statistic. The printing of the stars is suppressed in
  empty results cells (i.e. if the scalar statistic in question is missing
  for a certain model). The determination of the model significance is
  based on the p-value of the model (see above).

{p 16 16 2}
  Hint: It is possible to attach the stars to different scalar statistics
  within the same table. For example, specify 
  {cmd:stats(,star(r2_a r2_p))} 
  when tabulating OLS estimates and, say, probit estimates. For
  the OLS models, the F test will be carried out and the significance
  stars will be attached to the {cmd:r2_a}; for the probit models, the
  chi2 test will be used and the stars will appear next to the
  {cmd:r2_p}.
