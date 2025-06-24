capture program drop cacheit_examples
program cacheit_examples
    version 16.1
    args EXAMPLE
    set more off

    noi di `"cache contents on this examples are stored in c(tmpdir): {cmd:{ccl tmpdir}}"'
    local tmp_cache "${cache_dir}"
    global cache_dir "`c(tmpdir)'"
    
    tempname nframe
    frame create `nframe' 
    frame `nframe' {
        cap noi `EXAMPLE'
    }

    if ("`tmp_cache'" != "") {
        noi disp `"{cmd:NOTE:} global {it:cache_dir} set back to: {it:"`tmp_cache'"}"'
    }
    
    global cache_dir "`tmp_cache'"
end


*  ----------------------------------------------------------------------------
*  Basic example
*  ----------------------------------------------------------------------------
program define cacheit_ex01
    //Load Stata's auto dataset, and cache a command
    
    sysuse auto
    cacheit: regress price weight length

    //Now, inspect return list and ereturn list to see elements returned by the regress command

    return list
    ereturn list

    //Now, issue alternative command so that return lists will be altered

    cacheit: sum price weight length

    //Finally, call cacheit again, and confirm that cacheit has reloaded all original command output without re-running the command:

    cacheit: regress price weight length
    return list

end



*  ----------------------------------------------------------------------------
*  Basic documenting time savings
*  ----------------------------------------------------------------------------
program define cacheit_ex02
    //Load Stata's auto dataset, set a timer, cache a command which will take 
    // considerable time to run and then turn off the timer
    sysuse auto
    timer on 1
    cacheit: bootstrap, reps(5000) dots(100): reg price mpg
    timer off 1

    // Now, set a second timer and run the command from the cached version:

    timer on 2
    cacheit: bootstrap, reps(5000) dots(100): reg price mpg
    timer off 2
    timer list

end 

*  ----------------------------------------------------------------------------
*  An example with post estimation
*  ----------------------------------------------------------------------------
program define cacheit_ex03
    //Load Stata's food_consumption dataset and implement resource-heavy demandsys
    webuse food_consumption, clear
    cacheit: demandsys quaids w_dairy w_proteins w_fruitveg w_flours w_misc, prices(p_dairy p_proteins p_fruitveg p_flours p_misc) expenditures(expfd) demographics(n_kids n_adults) labels(Dairy Meats FruitVeg Flours Misc) nolog
    
    // Now, also cache the post-estimation command, which requires elements from previous command:
    cacheit, keepall: estat elasticities, uncompensated
end 