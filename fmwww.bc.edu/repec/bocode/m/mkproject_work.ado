*! version 2.0.1 15Sep2023 MLB
program define mkproject_work
    version 15.1
    syntax [anything], calling(string) [TEMPLate1(string) debug CREATE(string) query remove(string) default(string) RESETDEFault] *
    
    if `"`calling'"' != "project" & `"`calling'"' != "boilerplate" {
        di as err "{p}mkproject_work can only be called from mkproject or boilerplate{p_end}"
        exit 198
    }
    
    if "`default'" != "" & "`resetdefault'" != "" {
        di as err "{p}Cannot specify default() and resetdefault together{p_end}"
        exit 198
    }
    if `"`create'`query'`default'`resetdefault'`anything'`remove'"' == "" {
        di as err "{p}A name for your project is required{p_end}"
        exit 198
    }
    if "`create'`query'`default'`resetdefault'`remove'" != "" & `"`anything'"' != "" {
        di as err "{p}A name for a project cannot be specified together with the create(), remove(), query, default(), resetdefault options{p_end}"
        exit 198
    }   
    if "`create'`query'`default'`resetdefault'`remove'" != "" & "`type'" != "" {
        di as err "{p}A type cannot be specified together with the create(), remove(), query, default(), resetdefault options{p_end}"
        exit 198
    }   
	if `"`remove'"' != "" & `"`create'`default'`resetdefault'"' != "" {
		di as err "{p}cannot combine the the remove() option with either create(), default(), or resetdefault{p_end}"
		exit 198
	}

   	local proj mkproject__class_instance
    
    if `"`create'"' != "" {
        capture noisily Create `create', proj(`proj') calling("`calling'") `options'
        Cleanup , proj(`proj') rc(`=_rc') `debug'
        if "`query'`default'`resetdefault'" == "" exit
    }
    if `"`default'"' != "" {
        capture noisily Default `default', proj(`proj') calling("`calling'") 
        Cleanup , proj(`proj') rc(`=_rc') `debug'
        if "`query'`resetdefault'" == "" exit
    }
    if "`resetdefault'" != "" {
        capture noisily Resetdefault, proj(`proj') calling("`calling'")
        Cleanup , proj(`proj') rc(`=_rc') `debug'
        if "`query'" == "" exit        
    }
	if `"`remove'"' != "" {
		capture noisily Remove, proj(`proj') calling("`calling'") remove(`"`remove'"')
		Cleanup, proj(`proj') rc(`=_rc') `debug'
		if "`query'" == "" exit        
	}
    if "`query'" != "" {
        capture noisily Query, proj(`proj') calling("`calling'")
        Cleanup, proj(`proj') rc(`=_rc') `debug'
        exit
    }
    capture noisily mkproject_main `anything', `options' proj(`proj') template(`template1') calling("`calling'")
	Cleanup, proj(`proj') rc(`=_rc') `debug'	
end

program define Create
    syntax anything(name=create), proj(string) calling(string) [replace plus] *
    mata: `proj' = mpcreate()
    mata: `proj'.create("`calling'")
end

program define Query
    syntax, proj(string) calling(string)
    mata: `proj' = mpquery()
    mata: `proj'.run("`calling'")
end

program define Default
    syntax anything(name=default), proj(string) calling(string) 
    mata: `proj' = mpdefaults()
    mata: `proj'.write_default("`calling'", "`default'")
end

program define Resetdefault
    syntax, proj(string) calling(string)
    mata: `proj' = mpdefaults()
    mata: `proj'.reset("`calling'")
end

program define Remove
	syntax, proj(string) calling(string) remove(string)
	mata: `proj' = mpcreate()
	mata: `proj'.remove("`remove'", "`calling'")
end

program define mkproject_main 
	version 10
	syntax anything, proj(string) calling(string) ///
           [ DIRectory(string) TEMPLate1(string)]
    
    if "`calling'" == "project" {
        mata: `proj' = mkproject()
        mata: `proj'.run()
    }
    else if "`calling'" == "boilerplate" {
		if `"`directory'"' != "" {
			di as err "{p}option {bf:directory()} not allowed{p_end}"
			exit 198
		}
        mata: `proj' = boilerplate()
        mata: `proj'.copy_boiler(`"`anything'"', "`template1'")
		doedit `"`anything'"'
    }
end

program define Cleanup 
	version 10
	syntax, proj(string) rc(integer) [debug]
	
    if `rc' {
        mata:`proj'.graceful_exit()
    }
    if "`debug'" == "" {
		mata: mata drop `proj'
	}
    if `rc' {
        exit `rc'
    }
end
