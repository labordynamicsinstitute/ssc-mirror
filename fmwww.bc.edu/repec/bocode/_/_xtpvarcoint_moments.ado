*! _xtpvarcoint_moments.ado — Simulated Moment Tables
*! For panel test statistics (Larsson et al. 2001, Breitung 2005,
*! Arsova & Oersal 2018, Silvestre & Surdeanu 2011)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _xpvc_moments_load
program define _xpvc_moments_load
  version 14.0
end

mata:

// ============================================================
// Simulated moments for panel combination tests
// ============================================================

// Moments from Larsson et al. (2001:114, Tab.1) for Case1
// Rows: d = K-r = 1,...,12 stochastic trends
// Cols: (TR_EZ, TR_VZ)
real matrix _xpvc_moments_Case1()
{
  return( ///
    (1.137,  2.212 \
     6.086, 10.535 \
    14.955, 24.733 \
    27.729, 45.264 \
    44.392, 71.284 \
    64.960, 103.452 \
    89.360, 139.680 \
   117.519, 183.997 \
   149.441, 233.053 \
   185.082, 286.483 \
   224.450, 343.179 \
   267.708, 411.679) )
}

// Moments from Breitung (2005:171, Tab.B1)
// (20,000 replications with T=500) for Case2
real matrix _xpvc_moments_Case2()
{
  return( ///
    (3.051,  7.003 \
     9.990, 18.460 \
    20.880, 35.860 \
    35.670, 58.070 \
    54.330, 85.130 \
    76.940, 119.700) )
}

// Moments for Case3
real matrix _xpvc_moments_Case3()
{
  return( ///
    (0.980,  1.910 \
     8.270, 14.280 \
    19.350, 31.840 \
    34.180, 54.280 \
    53.050, 83.500 \
    75.610, 116.700) )
}

// Moments for Case4
real matrix _xpvc_moments_Case4()
{
  return( ///
    (6.270, 10.450 \
    16.280, 25.500 \
    30.210, 45.130 \
    48.010, 72.950 \
    69.650, 104.070 \
    94.930, 139.700) )
}

// SL trend moments from Arsova,Oersal (2018:Appendix, Tab.A1)
// via response surface approximation
real matrix _xpvc_moments_SL_trend()
{
  return( ///
    (2.689,  4.396 \
     8.924, 13.725 \
    19.011, 28.501 \
    33.036, 48.837 \
    51.023, 75.430 \
    73.042, 107.953 \
    99.036, 147.468 \
   129.025, 193.158 \
   163.003, 241.215 \
   200.971, 297.598 \
   242.960, 360.760 \
   289.002, 428.035) )
}

// SL trend moments from Oersal,Droge (2014:6, Tab.1)
real matrix _xpvc_moments_SL_trd14()
{
  return( ///
    (2.690,  4.380 \
     8.860, 13.370 \
    18.850, 28.230 \
    32.780, 47.940 \
    50.580, 73.740 \
    72.440, 105.330 \
    97.910, 143.680 \
   127.550, 187.280 \
   161.200, 238.000 \
   198.430, 300.910 \
   239.700, 357.050 \
   284.870, 424.860) )
}


// ============================================================
// MSB test moments from Silvestre,Surdeanu (2011:10, Tab.1)
// Used for panel MSB unit root tests
// ============================================================

// Return MSB moments for given T and trend spec
real matrix _xpvc_moments_MSB(real scalar dim_T, string scalar spec)
{
  if (spec == "mean") {
    if (dim_T >= 800) {
      return( (0.50445, 0.34863 \
               0.08580, 0.00364 \
               0.04048, 0.00039 \
               0.02578, 0.00009 \
               0.01884, 0.00003 \
               0.01475, 0.00002) )
    }
    else if (dim_T >= 400) {
      return( (0.49960, 0.31146 \
               0.08806, 0.00378 \
               0.04191, 0.00040 \
               0.02708, 0.00010 \
               0.01995, 0.00004 \
               0.01571, 0.00002) )
    }
    else if (dim_T >= 150) {
      return( (0.50454, 0.32442 \
               0.09049, 0.00386 \
               0.04356, 0.00042 \
               0.02864, 0.00011 \
               0.02115, 0.00003 \
               0.01710, 0.00002) )
    }
    else if (dim_T >= 75) {
      return( (0.50363233, 0.29973853 \
               0.09293090, 0.00387378 \
               0.04653255, 0.00042435 \
               0.03106941, 0.00010149 \
               0.02378946, 0.00003807 \
               0.01969598, 0.00001723) )
    }
    else {
      return( (0.49534851, 0.30860402 \
               0.09760915, 0.00380154 \
               0.05269258, 0.00037111 \
               0.03900235, 0.00008941 \
               0.03267331, 0.00002977 \
               0.02924112, 0.00001272) )
    }
  }
  else {  // trend
    if (dim_T >= 800) {
      return( (0.16622, 0.02267 \
               0.05539, 0.00095 \
               0.03132, 0.00017 \
               0.02172, 0.00005 \
               0.01651, 0.00002 \
               0.01323, 0.00001) )
    }
    else if (dim_T >= 400) {
      return( (0.16825, 0.02122 \
               0.05705, 0.00106 \
               0.03281, 0.00018 \
               0.02270, 0.00005 \
               0.01744, 0.00002 \
               0.01427, 0.00001) )
    }
    else if (dim_T >= 150) {
      return( (0.17637, 0.02195 \
               0.05943, 0.00109 \
               0.03431, 0.00018 \
               0.02454, 0.00006 \
               0.01900, 0.00002 \
               0.01570, 0.00001) )
    }
    else if (dim_T >= 75) {
      return( (0.17829789, 0.02079461 \
               0.06172200, 0.00108132 \
               0.03708937, 0.00019160 \
               0.02696152, 0.00005735 \
               0.02160916, 0.00002413 \
               0.01831139, 0.00001183) )
    }
    else {
      return( (0.17309672, 0.01673810 \
               0.06820676, 0.00094535 \
               0.04504875, 0.00016972 \
               0.03587122, 0.00004706 \
               0.03122986, 0.00001728 \
               0.02864541, 0.00000913) )
    }
  }
}

// ============================================================
// Main accessor: get moments for a given panel test type
// type: Case1, Case2, Case3, Case4, SL_trend, SL_trd14
// Returns: K x 2 matrix (EZ, VZ) sliced for d = dim_K - r_H0
// ============================================================

real matrix _xpvc_get_moments(string scalar type, real scalar dim_K)
{
  real matrix mom_all
  
  if (type == "Case1") {
    mom_all = _xpvc_moments_Case1()
  }
  else if (type == "Case2") {
    mom_all = _xpvc_moments_Case2()
  }
  else if (type == "Case3") {
    mom_all = _xpvc_moments_Case3()
  }
  else if (type == "Case4") {
    mom_all = _xpvc_moments_Case4()
  }
  else if (type == "SL_trend") {
    mom_all = _xpvc_moments_SL_trend()
  }
  else if (type == "SL_trd14") {
    mom_all = _xpvc_moments_SL_trd14()
  }
  else {
    // Fallback: use response surface approximation
    real colvector d_H0
    d_H0 = (dim_K::1)
    mom_all = _xpvc_rscoef(d_H0, type)
    if (cols(mom_all) >= 2) mom_all = mom_all[., 1..2]
    return(mom_all)
  }
  
  // Slice to K rows (d = K,...,1 for r=0,...,K-1)
  // Tables are indexed by d = 1,2,...,d_max
  // We need d = K, K-1, ..., 1
  if (dim_K <= rows(mom_all)) {
    real matrix result
    result = J(dim_K, 2, .)
    real scalar k
    for (k = 1; k <= dim_K; k++) {
      real scalar d
      d = dim_K - k + 1  // d = K-r_H0
      result[k, .] = mom_all[d, .]
    }
    return(result)
  }
  else {
    // Dimensions exceed tabled values — use response surface
    real colvector d_H0_b
    d_H0_b = (dim_K::1)
    return(_xpvc_rscoef(d_H0_b, type)[., 1..2])
  }
}

end
