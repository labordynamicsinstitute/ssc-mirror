*! xtoutliers 1.0.0  18jul2026
*! Overview / launcher for the xtoutliers suite of panel-data outlier tools.
*! Commands:  xtvsom  (variance-shift outlier model, postestimation)
*!            xtrobust (S-estimator & WLE robust FE/RE estimation)
*!            xtlossf (distribution-free loss-function detector)
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! GitHub: https://github.com/merwanroudane
program define xtoutliers
    version 14.0
    di as text ""
    di as text "{hline 70}"
    di as text "  xtoutliers 1.0.0 — outlier detection & robust estimation for panels"
    di as text "{hline 70}"
    di as text "  Three complementary approaches to panel-data outliers:"
    di as text ""
    di as text "  {cmd:xtvsom}   " as text "Variance Shift Outlier Model (VSOM). Detects and"
    di as text "             accommodates outliers by shifting their variance."
    di as text "             Runs as postestimation after xtreg,fe / regress /"
    di as text "             ivregress 2sls.   {help xtvsom:help xtvsom}"
    di as text ""
    di as text "  {cmd:xtrobust} " as text "Robust FE/RE estimation with the S-estimator and the"
    di as text "             Weighted Likelihood Estimator (WLE)."
    di as text "             {help xtrobust:help xtrobust}"
    di as text ""
    di as text "  {cmd:xtlossf}  " as text "Distribution-free loss-function outlier detection"
    di as text "             (nonnegative & mixed-sign data)."
    di as text "             {help xtlossf:help xtlossf}"
    di as text ""
    di as text "  Methods help: {help xtoutliers_methods:help xtoutliers methods}"
    di as text "{hline 70}"
    di as text "  Dr Merwan Roudane — github.com/merwanroudane"
    di as text "{hline 70}"
end
