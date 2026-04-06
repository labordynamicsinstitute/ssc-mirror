*! _xtpvarcoint_rscoef.ado — Response Surface Coefficients
*! Doornik (1998), Johansen et al. (2000), Trenkler et al. (2008),
*! Kurita & Nielsen (2019), Trenkler (2008)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _xpvc_rscoef_load
program define _xpvc_rscoef_load
  version 14.0
end

mata:

// ============================================================
// Response surface coefficients for moments of asymptotic
// LR test distributions under d = K - r_H0 stochastic trends
// ============================================================

// Doornik (1998:591, Tab.7-8): Basic Johansen cases
// Returns: 4-column matrix (TR_EZ, TR_VZ, ME_EZ, ME_VZ)
// Input: d_H0 vector (K-r_H0), type string
real matrix _xpvc_rscoef(real colvector d_H0, string scalar type)
{
  real matrix coef, rs_term, moments
  real scalar n
  real colvector d2, d, sd, ones, d1, d2dum
  
  n = rows(d_H0)
  d2 = d_H0:^2
  d = d_H0
  sd = sqrt(d_H0)
  ones = J(n, 1, 1)
  d1 = (d_H0 :== 1)
  d2dum = (d_H0 :== 2)
  
  // rs_term: [d^2, d, sqrt(d), 1, dum(d=1), dum(d=2)]
  rs_term = d2, d, sd, ones, d1, d2dum
  
  if (type == "Case1") {
    coef = (2, -1.0000, 0.00000, 0.07000, 0.07000, 0.000000 \
            3, -0.3300, 0.00000, -0.55000, 0.00000, 0.000000 \
            0, 6.0019, -2.77640, -2.75580, 0.67185, 0.114900 \
            0, 1.8806, 14.71400, -15.4990, 1.11360, 0.070508)
    moments = rs_term * coef'
  }
  else if (type == "Case2") {
    coef = (2, 2.0100, 0.00000, 0.00000, 0.06000, 0.050000 \
            3, 3.6000, 0.00000, 0.75000, -0.40000, -0.300000 \
            0, 5.9498, -2.36690, 0.43402, 0.04836, 0.018198 \
            0, 2.2231, 12.05800, -7.90640, 0.58592, -0.034324)
    moments = rs_term * coef'
  }
  else if (type == "Case3") {
    coef = (2, 1.0500, 0.00000, -1.55000, -0.50000, -0.230000 \
            3, 1.8000, 0.00000, 0.00000, -2.80000, -1.100000 \
            0, 5.8271, -1.56660, -1.64870, -1.61180, -0.259490 \
            0, 2.0785, 13.07400, -9.78460, -3.36800, -0.245280)
    moments = rs_term * coef'
  }
  else if (type == "Case4") {
    coef = (2, 4.0500, 0.00000, 0.50000, -0.23000, -0.070000 \
            3, 5.7000, 0.00000, 3.20000, -1.30000, -0.500000 \
            0, 5.8658, -1.75520, 2.55950, -0.34443, -0.077991 \
            0, 1.9955, 12.84100, -5.54280, 1.24250, 0.419490)
    moments = rs_term * coef'
  }
  else if (type == "Case5") {
    coef = (2, 2.8500, 1.35000, -5.10000, -0.10000, -0.060000 \
            3, 4.0000, 0.00000, 0.80000, -5.80000, -2.660000 \
            0, 5.6364, -0.21447, -0.90531, -3.51660, -0.479660 \
            0, 2.0899, 12.39300, -5.33030, -7.15230, -0.252600)
    moments = rs_term * coef'
  }
  else if (type == "SL_trend") {
    coef = (1.9996, 0.0000, 0.0000, 1.0365, -0.3469, -0.1112 \
            2.9715, 0.0000, 0.0000, 1.4089, 0.0000, 0.4297 \
            -0.0039, 6.1600, -3.3281, -0.5071, 0.3725, 0.0850 \
            -0.0418, 3.4915, 9.2061, -8.9114, 0.6652, 0.0000)
    moments = rs_term * coef'
  }
  else if (type == "SL_mean") {
    coef = (2.0000, -1.0134, 0.0000, 0.1309, 0.0218, 0.0000 \
            2.9778, 0.0000, 0.0000, -1.7144, 0.9507, 0.4259 \
            -0.0035, 6.1365, -3.2161, -2.3701, 0.5970, 0.1007 \
            -0.0258, 2.6655, 12.4462, -13.6992, 0.8563, 0.0000)
    moments = rs_term * coef'
  }
  else {
    moments = J(n, 4, .)
  }
  
  return(moments)
}


// Full moment lookup function that dispatches to the right method
real matrix _xpvc_CointMoments(real scalar dim_K, real colvector r_H0,
                                string scalar type)
{
  real colvector d_H0
  
  d_H0 = dim_K :- r_H0
  return(_xpvc_rscoef(d_H0, type))
}


// ============================================================
// SL_ortho response surface (Trenkler 2008:Tab.7)
// ============================================================

real matrix _xpvc_rscoef_SLortho(real colvector d_H0)
{
  real matrix coef, rs_term, moments
  real scalar n
  real colvector d2, d, sd, ones, d1, d2dum
  
  n = rows(d_H0)
  d2 = d_H0:^2
  d = d_H0
  sd = sqrt(d_H0)
  ones = J(n, 1, 1)
  d1 = (d_H0 :== 1)
  d2dum = (d_H0 :== 2)
  
  rs_term = d2, d, sd, ones, d1, d2dum
  
  coef = (2.0008, -2.0990, 0.4463, 0.0000, 0.0000, -0.0503 \
          3.0152, -3.0099, 2.1117, 0.0000, 0.0000, -0.8004 \
          0.0000, 5.8766, -1.9791, -4.8042, 0.0000, 0.0000 \
          0.0000, 1.3279, 17.6880, 1.3279, 0.0000, 0.0000)
  moments = rs_term * coef'
  
  return(moments)
}


// ============================================================
// JMN STRUCTURAL BREAK COEFFICIENTS
// Johansen, Mosconi, Nielsen (2000:229, Tab.4)
// Log-moments for trace test with up to 2 breaks
// ============================================================

real matrix _xpvc_rscoef_JMN(real colvector d_H0, real scalar dim_T,
                              real colvector t_break,
                              string scalar type)
{
  real matrix moments
  real scalar n, dim_q, j
  real colvector vs, ls
  real scalar l1, l2
  real colvector rs_subs
  real matrix rs_term, coef_EZ, coef_VZ
  
  n = rows(d_H0)
  dim_q = rows(t_break) + 1
  
  if (dim_q > 3 | dim_q < 2) {
    moments = J(n, 4, .)
    return(moments)
  }
  
  // Compute relative sub-sample lengths
  real colvector zeros
  zeros = J(4 - dim_q, 1, 0)
  vs = sort((zeros \ (t_break :- 1) \ dim_T), 1)
  ls = sort(vs[2..rows(vs)] - vs[1..rows(vs)-1], 1) / dim_T
  l1 = ls[1]
  l2 = ls[2]
  
  rs_subs = (3 - dim_q) * d_H0
  
  if (type == "Case2") {
    // JMN Case2 (H_c) coefficients
    rs_term = J(n, 1, 1), d_H0, J(n, 1, l1), J(n, 1, l2), ///
              d_H0:^2, d_H0*l1, d_H0*l2, J(n, 1, l1^2), J(n, 1, l1*l2), J(n, 1, l2^2), ///
              d_H0:^3, d_H0:*(l1^2), J(n, 1, l1^3), J(n, 1, l1*l2^2), J(n, 1, l1^2*l2), J(n, 1, l2^3), ///
              1:/d_H0, l1:/d_H0, l2:/d_H0, (l1^2):/d_H0, (l1*l2):/d_H0, (l2^2):/d_H0, (l1^3):/d_H0, (l1*l2^2):/d_H0, (l2^3):/d_H0, ///
              1:/(d_H0:^2), l2:/(d_H0:^2), (l1^2):/(d_H0:^2), (l2^2):/(d_H0:^2), (l1^3):/(d_H0:^2), (l2^3):/(d_H0:^3)
    
    coef_EZ = (2.8000, 0.5010, 1.4300, 0.399, -0.03090, -0.0600, 0.0000, -5.7200, -1.1200, -1.7000, ///
               0.000974, 0.168, 6.34, 1.89, 0.00, 1.850, ///
               -2.19, -0.438, 1.79, 6.03, 3.08, -1.97, -8.08, -5.79, 0.00, ///
               0.717, -1.290, -1.52, 2.87, 0.0, -2.03)'
    coef_VZ = (3.7800, 0.3460, 0.8590, 0.000, -0.01060, -0.0339, 0.0000, -2.3500, 0.0000, 0.0000, ///
               0.000000, 0.000, 3.95, 0.00, 0.00, -0.282, ///
               -2.73, 0.874, 2.36, -2.88, 0.00, -4.44, 0.00, 0.00, 4.31, ///
               1.020, -0.807, 0.00, 0.00, 0.0, 0.00)'
  }
  else if (type == "Case4") {
    // JMN Case4 (H_l) coefficients
    rs_term = J(n, 1, 1), d_H0, J(n, 1, l1), J(n, 1, l2), ///
              d_H0:^2, d_H0*l1, d_H0*l2, J(n, 1, l1^2), J(n, 1, l1*l2), J(n, 1, l2^2), ///
              d_H0:^3, d_H0:*(l1^2), J(n, 1, l1^3), J(n, 1, l1*l2^2), J(n, 1, l1^2*l2), J(n, 1, l2^3), ///
              1:/d_H0, l1:/d_H0, l2:/d_H0, (l1^2):/d_H0, (l1*l2):/d_H0, (l2^2):/d_H0, (l1^3):/d_H0, (l1*l2^2):/d_H0, (l2^3):/d_H0, ///
              1:/(d_H0:^2), l2:/(d_H0:^2), (l1^2):/(d_H0:^2), (l2^2):/(d_H0:^2), (l1^3):/(d_H0:^2), (l2^3):/(d_H0:^3)
    
    coef_EZ = (3.0600, 0.4560, 1.4700, 0.993, -0.02690, -0.0363, -0.0195, -4.2100, 0.0000, -2.3500, ///
               0.000840, 0.000, 6.01, 0.00, -1.33, 2.040, ///
               -2.05, -0.304, 1.06, 9.35, 3.82, 2.12, -22.80, -7.15, -4.95, ///
               0.681, -0.828, -5.43, 0.00, 13.1, 1.50)'
    coef_VZ = (3.9700, 0.3140, 1.7900, 0.256, -0.00898, -0.0688, 0.0000, -4.0800, 0.0000, 0.0000, ///
               0.000000, 0.000, 4.75, 0.00, 0.00, -0.587, ///
               -2.47, 1.620, 3.13, -4.52, -1.21, -5.87, 0.00, 0.00, 4.89, ///
               0.874, -0.865, 0.00, 0.00, 0.0, 0.00)'
  }
  else {
    moments = J(n, 4, .)
    return(moments)
  }
  
  // Log-moments → moments
  real colvector log_EZ, log_VZ
  log_EZ = rs_term * coef_EZ
  log_VZ = rs_term * coef_VZ
  
  moments = exp(log_EZ) - rs_subs, ///
            exp(log_VZ) - 2 * rs_subs, ///
            J(n, 1, .), J(n, 1, .)
  
  return(moments)
}


// ============================================================
// TSL STRUCTURAL BREAK COEFFICIENTS
// Trenkler, Saikkonen, Luetkepohl (2008:349, Tab.AI)
// Log-moments for trace test with trend breaks
// ============================================================

real matrix _xpvc_rscoef_TSL(real colvector d_H0, real scalar dim_T,
                              real colvector t_break)
{
  real matrix moments
  real scalar n, dim_q
  real colvector vs, ls
  real scalar l1, l2
  real matrix rs_term
  real colvector coef_EZ, coef_VZ
  
  n = rows(d_H0)
  dim_q = rows(t_break) + 1
  
  if (dim_q > 3 | dim_q < 2) {
    moments = J(n, 4, .)
    return(moments)
  }
  
  // Compute relative sub-sample lengths (TSL use t_sub-1+1)
  real colvector zeros
  zeros = J(4 - dim_q, 1, 0)
  vs = sort((zeros \ t_break \ dim_T), 1)
  ls = sort(vs[2..rows(vs)] - vs[1..rows(vs)-1], 1) / dim_T
  l1 = ls[1]
  l2 = ls[2]
  
  // TSL coefficients (Trenkler et al 2008:349, Tab.AI)
  rs_term = J(n, 1, 1), d_H0, J(n, 1, l1), J(n, 1, l2), ///
            d_H0:^2, d_H0*l1, d_H0*l2, J(n, 1, l1^2), J(n, 1, l1*l2), J(n, 1, l2^2), ///
            d_H0:^3, (d_H0:^2)*l1, (d_H0:^2)*l2, d_H0*(l1^2), d_H0*(l1*l2), d_H0*(l2^2), ///
            J(n, 1, l1^3), J(n, 1, l1^2*l2), J(n, 1, l1*l2^2), J(n, 1, l2^3), ///
            1:/d_H0, l1:/d_H0, l2:/d_H0, (l1^2):/d_H0, (l1*l2):/d_H0, (l2^2):/d_H0, ///
            (l1^3):/d_H0, (l1^2*l2):/d_H0, (l1*l2^2):/d_H0, (l2^3):/d_H0, ///
            1:/(d_H0:^2), l1:/(d_H0:^2), l2:/(d_H0:^2), (l1^2):/(d_H0:^2), (l2^2):/(d_H0:^2), ///
            (l1^3):/(d_H0:^2), (l1^2*l2):/(d_H0:^2), (l1*l2^2):/(d_H0:^2), (l2^3):/(d_H0:^2)
  
  coef_EZ = (2.4402, 0.5664, 1.6881, -0.1674, -0.0367, -0.1265, 0.0286, -7.2613, -1.9837, -1.6794, ///
             0.0012, 0.0044, -0.0014, 0.1830, 0.0293, 0.0303, 11.8030, -2.4871, 4.0200, 2.1430, ///
             -3.0135, 1.1124, 5.1272, 4.3452, 3.5022, -8.6823, -16.7672, 5.9728, -7.0978, 5.7110, ///
             1.0331, -0.6479, -2.9655, 0.0000, 7.6083, 5.7696, -6.5948, 0.0000, -6.9392)'
  
  coef_VZ = (2.2377, 0.6725, -1.8646, 1.5842, -0.0440, 0.0000, -0.2485, 12.0954, 5.0822, -1.5583, ///
             0.0013, 0.0105, 0.0135, -0.4765, -0.2405, 0.0898, -22.1045, 7.7659, -8.7651, -0.3356, ///
             -1.6753, 11.7097, -1.8672, -60.2299, -10.1422, 4.5029, 129.7558, -58.2770, 32.3138, 0.0000, ///
             0.2956, -4.9776, 4.3265, 30.9656, -14.4186, -82.5994, 48.3167, -15.3335, 10.8817)'
  
  // Log-moments → moments (TSL uses exp() )
  real colvector log_EZ, log_VZ
  log_EZ = rs_term * coef_EZ
  log_VZ = rs_term * coef_VZ
  
  moments = exp(log_EZ), exp(log_VZ), J(n, 1, .), J(n, 1, .)
  
  return(moments)
}


// ============================================================
// ENHANCED CointMoments with structural break support
// Dispatches to JMN, TSL, or basic Doornik
// ============================================================

real matrix _xpvc_CointMoments_break(real scalar dim_K,
                                      real colvector r_H0,
                                      string scalar type,
                                      real scalar dim_T,
                                      real colvector t_break)
{
  real colvector d_H0
  d_H0 = dim_K :- r_H0
  
  if (type == "JMN_Case2" | type == "JMN_Case4") {
    string scalar base_type
    if (type == "JMN_Case2") base_type = "Case2"
    else base_type = "Case4"
    return(_xpvc_rscoef_JMN(d_H0, dim_T, t_break, base_type))
  }
  else if (type == "TSL_trend") {
    return(_xpvc_rscoef_TSL(d_H0, dim_T, t_break))
  }
  else if (type == "SL_ortho") {
    return(_xpvc_rscoef_SLortho(d_H0))
  }
  else {
    // Fall back to basic Doornik (1998) coefficients
    return(_xpvc_rscoef(d_H0, type))
  }
}


end

