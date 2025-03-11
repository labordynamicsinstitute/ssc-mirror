capture program drop cache_examples
program cache_examples
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
program define cache_ex01
    //Load Stata's auto dataset, and cache a command
    
    sysuse auto
    cache: regress price weight length

    //Now, inspect return list and ereturn list to see elements returned by the regress command

    return list
    ereturn list

    //Now, issue alternative command so that return lists will be altered

    cache: sum price weight length

    //Finally, call cache again, and confirm that cache has reloaded all original command output without re-running the command:

    cache: regress price weight length
    return list

end



*  ----------------------------------------------------------------------------
*  Basic documenting time savings
*  ----------------------------------------------------------------------------
program define cache_ex02
    //Load Stata's auto dataset, set a timer, cache a command which will take 
    // considerable time to run and then turn off the timer
    sysuse auto
    timer on 1
    cache: bootstrap, reps(5000) dots(100): reg price mpg
    timer off 1

    // Now, set a second timer and run the command from the cached version:

    timer on 2
    cache: bootstrap, reps(5000) dots(100): reg price mpg
    timer off 2
    timer list

end 