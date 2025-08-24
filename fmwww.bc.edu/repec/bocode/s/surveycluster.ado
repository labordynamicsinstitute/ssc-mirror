
*! 1.0.0 KNK 10 August 2025

program define surveycluster, rclass

    version 12
	
    syntax, [COnfidence(numlist >=10.00 <=99.99)] [MOe(numlist >0.00 <1.00)] [ICc(numlist >=0.00 <0.99)] [CLuster_size(integer 25)] [POPulation(integer 0)]
	
	* Set default values
	if "`confidence'" == "" {
		local confidence = 95
	}

	if "`moe'" == "" {
		local moe = 0.10
	}

	if "`icc'" == "" {
		local icc = 0.20
	}
	
	* Validate parameter combinations
	if `icc' > 0.5 {
		di as text "Warning: ICC of `icc' is unusually high. Typical values are 0.05 to 0.30"
	}
	
	if `cluster_size' < 5 {
		di as text "Warning: Cluster size of `cluster_size' is very small and may not benefit from cluster sampling"
	}
	
	if `cluster_size' > 100 {
		di as text "Warning: Cluster size of `cluster_size' is unusually large. Consider if this reflects your actual design"
	}
	
	if `moe' < 0.05 {
		di as text "Warning: Margin of error of `moe'σ (standard deviations) is very small and may require a large sample size"
	}
	
	if `moe' > 0.5 {
		di as text "Warning: Margin of error of `moe'σ (standard deviations) is very large and may not provide useful precision"
	}
  
    * Critical values for various confidence levels
	
	local zvalue = abs(invnormal((100 - `confidence')/200))
	
	* Calculate Design Effect
	local de = 1 + (`icc' * (`cluster_size' - 1))
	
    * Calculate the required sample size 
    local n0 =      ((`zvalue' / `moe')^2) * `de'
	local n  = ceil(((`zvalue' / `moe')^2) * `de')
	
	* Store original n for comparison
	local n_original = `n'
	
	* Apply finite population correction if population is specified
if `population' > 0 {
    * Always apply FPC when population is specified
    local n_fpc = `n0' / (1 + ((`n0' - 1) / `population'))
    local n_fpc = ceil(`n_fpc')
    
    * Display the adjustment if it makes a meaningful difference
    if `n_fpc' < `n' {
        di as txt ""
        di as txt "Finite population correction applied."
        local n_formatted : di %9.0f `n'
        local n_formatted = trim("`n_formatted'")
        di as txt "Original required sample: " as result "`n_formatted'"
        
        local n_fpc_formatted : di %9.0f `n_fpc'
        local n_fpc_formatted = trim("`n_fpc_formatted'")
        di as txt "Adjusted for population of `population': " as result "`n_fpc_formatted'"
        
        local reduction = `n' - `n_fpc'
        local reduction_formatted : di %9.0f `reduction'
        local reduction_formatted = trim("`reduction_formatted'")
        local reduction_pct : di %4.1f ((`n' - `n_fpc')/`n' * 100)
        local reduction_pct = trim("`reduction_pct'")
        di as txt "Reduction in sample size: " as result "`reduction_formatted'" as txt " (" as result "`reduction_pct'" as txt "%)"
    }
    
    * Use the adjusted n for further calculations
    local n = `n_fpc'
}

    * Calculate the number of clusters, rounding up to the nearest whole number
    local num_clusters = ceil(`n' / `cluster_size')
    
	* Calculate actual sample size (after rounding up clusters)
	local actual_n = `num_clusters' * `cluster_size'
	
	* Extreme edge case 
	if `population' > 0 & `actual_n' > `population' {
    local actual_n = `population'
	local num_clusters = ceil(`population' / `cluster_size') 
    di as text "Note: Actual sample size capped at population size"
}
	
	* Calculate actual margin of error achieved
if `population' > 0  {
    * Use finite population correction in MOE calculation
    local actual_moe = `zvalue' / sqrt(`actual_n' / `de') * sqrt((`population' - `actual_n') / (`population' - 1))
}
else {
    * Standard MOE calculation without FPC
    local actual_moe = `zvalue' / sqrt(`actual_n' / `de')
}
	
	* Output results
	di as txt ""
	local de_formatted : di %9.2f `de'
	local de_formatted = trim("`de_formatted'")
	di as txt "Design Effect based on ICC of `icc' and cluster size of `cluster_size' is: " as result "`de_formatted'"
	di as txt ""
	di as txt "Based on the confidence level of `confidence'%,"
	di as txt "ICC of `icc',"
	di as txt "margin of error of `moe'σ (standard deviations),"
	if `population' > 0 {
		di as txt "finite population size of `population',"
	}
	di as txt "and an average cluster size of `cluster_size':"
	di as txt ""
	
	local n_formatted : di %9.0f `n'
	local n_formatted = trim("`n_formatted'")
	di as txt "Required sample size: " as result "`n_formatted'"
	
	local num_clusters_formatted : di %9.0f `num_clusters'
	local num_clusters_formatted = trim("`num_clusters_formatted'")
	di as txt "Number of clusters needed: " as result "`num_clusters_formatted'"
	
	local actual_n_formatted : di %9.0f `actual_n'
	local actual_n_formatted = trim("`actual_n_formatted'")
	di as txt "Actual total sample size: " as result "`actual_n_formatted'"
	
	local actual_moe_formatted : di %6.3f `actual_moe'
	local actual_moe_formatted = trim("`actual_moe_formatted'")
	di as txt "Actual margin of error achieved: " as result "`actual_moe_formatted'" as txt "σ"
	
	* Store results for programmatic access
	return scalar n = `n'
	return scalar n_original = `n_original'
	return scalar clusters = `num_clusters'
	return scalar actual_n = `actual_n'
	return scalar de = `de'
	return scalar confidence = `confidence'
	return scalar moe = `moe'
	return scalar actual_moe = `actual_moe'
	return scalar icc = `icc'
	return scalar cluster_size = `cluster_size'
	return scalar z_value = `zvalue'
	if `population' > 0 {
		return scalar population = `population'
		return scalar sampling_fraction = `actual_n' / `population'
	}
		
end
