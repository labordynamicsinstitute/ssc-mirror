*! _fcoint_cv_tsong.ado -- Tsong et al. (2016) critical values, Table 1
program define _fcoint_cv_tsong, rclass
  syntax, p(integer) k(integer) model(string)
  if `p' < 1 local p = 1
  if `p' > 4 local p = 4
  if `k' < 1 local k = 1
  if `k' > 3 local k = 3
  * m=0 (constant)
  local ts_1_1_0 "0.095 0.124 0.198"
  local ts_1_2_0 "0.200 0.276 0.473"
  local ts_1_3_0 "0.225 0.304 0.507"
  local ts_2_1_0 "0.070 0.092 0.155"
  local ts_2_2_0 "0.132 0.182 0.328"
  local ts_2_3_0 "0.148 0.202 0.383"
  local ts_3_1_0 "0.059 0.076 0.130"
  local ts_3_2_0 "0.098 0.132 0.215"
  local ts_3_3_0 "0.112 0.146 0.250"
  local ts_4_1_0 "0.050 0.061 0.096"
  local ts_4_2_0 "0.072 0.097 0.171"
  local ts_4_3_0 "0.086 0.111 0.192"
  * m=1 (constant + trend)
  local ts_1_1_1 "0.042 0.048 0.063"
  local ts_1_2_1 "0.078 0.099 0.163"
  local ts_1_3_1 "0.090 0.114 0.170"
  local ts_2_1_1 "0.038 0.045 0.059"
  local ts_2_2_1 "0.063 0.081 0.127"
  local ts_2_3_1 "0.075 0.094 0.143"
  local ts_3_1_1 "0.036 0.042 0.055"
  local ts_3_2_1 "0.051 0.066 0.103"
  local ts_3_3_1 "0.061 0.075 0.116"
  local ts_4_1_1 "0.034 0.038 0.050"
  local ts_4_2_1 "0.044 0.055 0.086"
  local ts_4_3_1 "0.053 0.065 0.099"
  local mi = 0
  if "`model'" == "trend" local mi = 1
  local cvstr = "`ts_`p'_`k'_`mi''"
  tokenize `cvstr'
  return scalar cv10 = `1'
  return scalar cv5  = `2'
  return scalar cv1  = `3'
end
