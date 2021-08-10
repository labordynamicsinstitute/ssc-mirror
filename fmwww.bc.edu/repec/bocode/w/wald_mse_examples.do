//
//Code to reproduce the examples from "wald_mse: Evaluating the Maximum MSE of Mean Estimates with Missing Data"
//
//----------------------------------------------------------

clear all

//Section 4.1 Examples
wald_mse mean, samp_size(10) dist("bernoulli") miss_r(0)

wald_mse MMRzero, samp_size(10) dist("bernoulli") miss_r(0)

wald_mse MMRzero, samp_size(10) dist("bernoulli") miss_r(0.5)

wald_mse midmean, samp_size(10) dist("bernoulli") miss_r(0.5)

wald_mse MMRzero, samp_size(10) dist("bernoulli") miss_r(0.5) h_distance(0)

wald_mse midmean, samp_size(10) dist("bernoulli") miss_r(0.5) h_distance(0)


//Section 4.2 Examples

wald_mse mean, samp_size(650) dist("continuous") miss_r(0.5) mon_select(2) mc_iter(1000)

wald_mse midmean, samp_size(650) dist("continuous") miss_r(0.5) mon_select(2) mc_iter(1000)

wald_mse monotone_mean, samp_size(650) dist("continuous") miss_r(0.5) mon_select(2) mc_iter(1000) user_def

wald_mse mean, samp_size(650) dist("continuous") miss_r(0.5) mon_select(2) mc_iter(1000) h_distance(0.3)

wald_mse midmean, samp_size(650) dist("continuous") miss_r(0.5) mon_select(2) mc_iter(1000) h_distance(0.3)

wald_mse monotone_mean, samp_size(650) dist("continuous") miss_r(0.5) mon_select(2) mc_iter(1000) h_distance(0.3) user_def

wald_mse mean, samp_size(650) dist("continuous") miss_r(0.5) mc_iter(1000)

wald_mse midmean, samp_size(650) dist("continuous") miss_r(0.5) mc_iter(1000)

wald_mse monotone_mean, samp_size(650) dist("continuous") miss_r(0.5) mc_iter(1000) user_def

