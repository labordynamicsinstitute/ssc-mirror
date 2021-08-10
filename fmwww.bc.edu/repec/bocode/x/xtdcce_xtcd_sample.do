clear

*Requires testdataset, available at https://drive.google.com/file/d/0Bz0nTdXm8HD_VFpUZGJPSmRNMTg/view
use dcce_testdataset.dta

**xtdcce
xtdcce d.log_rgdpo L.log_rgdpo log_hc log_ck log_ngd , nocross reportc
xtdcce d.log_rgdpo L.log_rgdpo log_hc log_ck log_ngd , nocross
xtdcce d.log_rgdpo log_hc log_ck log_ngd , reportc
xtdcce d.log_rgdpo log_hc log_ck log_ngd , reportc cr(d.log_rgdpo log_hc log_ck log_ngd)
xtdcce d.log_rgdpo log_hc log_ck log_ngd , reportc cr(d.log_rgdpo log_hc log_ck log_ngd) cr_lags(0)
xtdcce d.log_rgdpo L.log_rgdpo log_hc log_ck log_ngd , reportc cr(d.log_rgdpo L.log_rgdpo log_hc log_ck log_ngd) cr_lags(3)
xtdcce d.log_rgdpo L.log_rgdpo log_hc log_ck log_ngd , reportc cr(d.log_rgdpo L.log_rgdpo log_hc log_ck log_ngd) cr_lags(3)
xtdcce d.log_rgdpo L.log_rgdpo log_hc log_ck log_ngd , reportc cr(d.log_rgdpo L.log_rgdpo log_hc log_ck log_ngd) cr_lags(3)
xtdcce d.log_rgdpo d.L.log_rgdpo d.log_hc d.log_ck d.log_ngd , reportc lr(L.log_rgdpo log_hc log_ck log_ngd) p(L.log_rgdpo log_hc log_ck log_ngd)
xtdcce d.log_rgdpo d.L.log_rgdpo d.log_hc d.log_ck d.log_ngd , reportc lr(L.log_rgdpo log_hc log_ck log_ngd) p(L.log_rgdpo log_hc log_ck log_ngd) lr_options(nodivide)
xtdcce d.log_rgdpo d.L.log_rgdpo d.log_hc d.log_ck d.log_ngd , reportc lr(L.log_rgdpo log_hc log_ck log_ngd) p(L.log_rgdpo log_hc log_ck log_ngd) lr_options(xtpmgnames)

*xtcd2
reg d.log_rgdpo log_hc log_ck log_ngd
xtcd2

reg d.log_rgdpo log_hc log_ck log_ngd
predict res, residuals
xtcd2 res
xtcd2 res, histogram
xtcd2 log_rgdpo, noestimation
