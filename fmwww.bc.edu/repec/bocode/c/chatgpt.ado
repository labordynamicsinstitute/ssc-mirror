*! Authors:
*! Chuntao Li, Ph.D. , China Stata Club(爬虫俱乐部)(chtl@henu.edu.cn)
*! Xueren Zhang, China Stata Club(爬虫俱乐部)(snowmanzhang@whu.edu.cn)
*! August 8th, 2024
*! Program written by Dr. Chuntao Li, Xueren Zhang
*! Used to interact with GPT within Stata software and obtain Stata usage recommendations from GPT.
*! and can only be used in Stata version 15.0 or above
*! Original Service Source: https://platform.openai.com/docs/api-reference/introduction
*! Please do not use this code for commerical purpose

cap prog drop chatgpt
program define chatgpt

	if _caller() < 15 {
		disp as error "this is version `=_caller()' of Stata; it cannot run version 14.0 programs"
		exit 199
	} 
	version 15
	syntax anything, [command(string) /// 
				File(string) ///
				DO(string) ///
				GENerate(string) ///
				Config(string) ///
				KEY_openai(string) ///
				agenturl(string) ///
				Proxy(string) ///
				STATA ///
				SYStem(string) ///  
				Model(string) ///
				TEMPerature(real 0.2) ///
				MAX_tokens(real 0) ///
				]

	//Pre-Process
	//----------------
	
	//1. get the script address
	qui findfile chatgpt.ado
	local precmdurl = ustrregexra(r(fn),"/chatgpt.ado","")
	local cmdurl "`=ustrregexra("`precmdurl'","\\","/")'"

	//2. download script
	capture confirm file "`cmdurl'/chatgpt_script.py"
	if _rc != 0 {
		copy "https://stata-command.oss-cn-hangzhou.aliyuncs.com/chatgpt/chatgpt_script.py" "`cmdurl'/chatgpt_script.py"
	}

	//3. split subcommand args
	tokenize `anything'
	local anything "`2'"
	
	//4. temperature and max_tokens
	if `temperature' == 0.2{
		local temperature ""
	}
	if `max_tokens' == 0{
		local max_tokens ""
	}


	//Test
	//---------
	if "`1'" == "test"{
		//1. check forbid option
		foreach option in "command" "file" "do" "config" "generate" "key_openai" "agenturl" "stata" "system" "model" "temperature" "max_tokens"{
			if "``option''" != ""{
				di as error "`option'() option is not allowed in chatgpt `1'"
				exit 198
			}
		}
		
		//2. set the proxy
		if "`proxy'" == ""{
			local x_proxy ""
		}
		else if !ustrregexm("`proxy'","^[\d\.]+:\d+$"){
			disp as error "proxy() option incorrectly specified. It should be like 127.0.0.1:7890"
			exit 662
		}
		else{
			local x_proxy `"-x "`proxy'""'
		}
		
		//3. init the test prog
		cap erase res.txt
		local BugFound = 0
		
		//4. confirm the python script.py
		capture confirm file "`cmdurl'/chatgpt_script.py"
		if _rc! = 0{
			di as error "file chatgpt_script.py can not found!"
			local BugFound = `BugFound' + 1
		}
		else{
			di as text "√ file chatgpt_script.py found."
		}
		//p.s. print the python version
		//!python "`cmdurl'/chatgpt_script.py" "version"

		//5. before curl
		cap erase chatgpt_test_log.txt
		!python "`cmdurl'/chatgpt_script.py" "gen" "gpt-3.5-turbo" "0" "0.2" "`cmdurl'"
		local sp = ustrtohex("test中文")
		cap erase payload.txt
		copy "`cmdurl'/payload-gpt-3.5-turbo.txt" payload.txt  
		!python "`cmdurl'/chatgpt_script.py" "system" ". `sp'" "payload.txt"
		local cmd = ustrtohex("test中文")
		!python "`cmdurl'/chatgpt_script.py" "add" "`cmd'" "prompt" "payload.txt"

		//6. check curl
		cap erase curl_version.txt
		!curl --version > curl_version.txt
		cap confirm file "curl_version.txt"
		if _rc!=0{
			di as error "system can not found curl!"
			local BugFound = `BugFound' + 1
		}
		else{
			di as text "√ curl had installed successfully."
		}

		shell curl "https://api.openai.com/v1/chat/completions" ///
			-H "Content-Type: application/json" ///
			-H "Authorization: Bearer sk-errorkey" ///
			--data "@payload.txt" ///
			-o "res.txt" `x_proxy'

		//7. after curl
		!python "`cmdurl'/chatgpt_script.py" "log" "chat-default.log"
		!python "`cmdurl'/chatgpt_script.py" "type"
		
		//8. type the result
		disp as text "The Python script has five testing items: gen, system, add, log, and type. Details are as follows:"
		cap confirm file "chatgpt_test_log.txt"
		if _rc == 0{
			type chatgpt_test_log.txt
			local info = fileread("chatgpt_test_log.txt")
			if ustrregexm("`info'","No such file or directory: 'res.txt'") & "`BugFound'"=="0"{
				di as error "Open AI service connection failed, please ensure your network environment supports Open AI services."
				local BugFound = `BugFound' + 1
			}
		}
		cap earse chatgpt_test_log.txt
	}

	//Config
	//-----------
	if "`1'" == "config"{
		//1. check forbid option
		foreach option in "command" "file" "do" "config" "generate"{
			if "``option''" != ""{
				di as error "`option'() option is not allowed in chatgpt `1'"
				exit 198
			}
		}
		
		//2. generate config file
		//2.1 init the config file
		if "`2'" == ""{
		    local 2 "chat-default"
		}
		file open myfile using "`2'.conf", write text replace
		file close myfile
		
		//2.2 add the openai_api_key
		file open myfile using "`2'.conf", write text append
		file write myfile "key_openai `key_openai'" _n
		file close myfile
				
		//2.4 add stata mark
		file open myfile using "`2'.conf", write text append
		file write myfile "stata `stata'" _n
		file close myfile
		
		//2.5 add prompt mark
		file open myfile using "`2'.conf", write text append
		file write myfile "system `system'" _n
		file close myfile
		
		//2.6 add model
		file open myfile using "`2'.conf", write text append
		file write myfile "model `model'" _n
		file close myfile
		
		//2.7 add proxy
		file open myfile using "`2'.conf", write text append
		file write myfile "proxy `proxy'" _n
		file close myfile
		
		//2.8 add agenturl
		file open myfile using "`2'.conf", write text append
		file write myfile "agenturl `agenturl'" _n
		file close myfile
	}
	
	
	// Talk & LongTalk & MultiTalk Mode
	// ----------
	if inlist("`1'", "talk", "longtalk", "multitalk"){

		//1. check forbid option		
		if "`generate'" != ""{
			di as error "generate() option is not allowed in chatgpt `1'. You should specify it in chatgpt update"
			exit 198
		}
	
		//2. prepare option
		if "`config'" != ""{
			foreach option in "key_openai" "system" "stata" "model" "proxy" "agenturl" "temperature" "max_tokens"{
				if "``option''" != ""{
					if "`1'" == "longtalk"{
						di as error "`option'() option is not allowed in chatgpt `1'."
						exit 198
					}
					else{
						di as error "options `option'() and config() may not be combined in chatgpt `1'."
						exit 184

					}
				}
			}
			//2.1 load args from config file
			file open myfile using "`config'.conf", read text
			file read myfile line
			local `line'
			while r(eof) == 0 {
				file read myfile line
				cap local `line'
			}
			file close myfile
		}
		else{
		    if "`1'" == "longtalk"{
			    di as error "config() option is required in chatgpt `1'."
				exit 198
			}
			local config "chat-default"
		}
		
		//2.2 check required option:openai_api_key
		if "`key_openai'" == ""{
			disp as error "key_openai() option is required in chatgpt `1' or config() option."
			exit 198
		}

		
		//2.3 set the proxy
		if "`proxy'" == ""{
			local x_proxy ""
		}
		else if !ustrregexm("`proxy'","^[\d\.]+:\d+$"){
			disp as error "proxy() option incorrectly specified. It should be like 127.0.0.1:7890"
			exit 662
		}
		else{
			local x_proxy `"-x "`proxy'""'
		}
		
		//2.4 set the agenturl
		if "`agenturl'" == ""{
			local agenturl "https://api.openai.com/v1/chat/completions"
		}
		
		
		
		//2.5 set the model
		if "`model'" == ""{
			local model = "gpt-4"
		}
		if !inlist("`model'","gpt-4o-mini","gpt-4o", "gpt-3.5-turbo","gpt-4","gpt-4-turbo-preview","gpt-4-turbo"){
			disp as error "model() option incorrectly specified."
			exit 198
		}
		

		//2.6 set the Temp and tokens
		if "`temperature'" == ""{
		    local temperature 0.2
		}
		if "`max_tokens'" == ""{
		    local max_tokens 0
		}
		
		//3. generate payload file
		!python "`cmdurl'/chatgpt_script.py" "gen" "`model'" "`max_tokens'" "`temperature'" "`cmdurl'"
				
		cap confirm file "`config'.log"
		if "`1'" != "longtalk" | _rc{
			copy "`cmdurl'/payload-`model'.txt" `config'.log,replace
				
			if "`stata'" != "" {
				!python "`cmdurl'/chatgpt_script.py" "system" "You are a helpful assistant that proficient in using Stata software. I will present my requirements to you, and you will provide me with the most suitable Stata Command based on my needs. Please keep your responses as concise as possible." "`config'.log"
			}
			if "`system'" != ""{
				//local sp = ustrtohex("`system'")
				local sp = ustrregexra("`system'","\n"," ")
				!python "`cmdurl'/chatgpt_script.py" "system" ". `sp'" "`config'.log"
			} 
		}
		
		
		//4 Talk Mode
		if "`1'" != "multitalk"{
		
			//4.1 prepare the file option
			if "`file'" != "" {
				if index("`file'",".") == 0{
					disp as error "Please input the file suffix"
					exit 198
				}
				local suffix = ustrregexra("`file'","^(.+)\.","")
				if "`suffix'" == "ado"{
					qui findfile `file'
					local arg1 = "`=ustrregexra("`r(fn)'","\\","/")'"
					local arg2 = "ado"
				}
				else if "`suffix'" == "sthlp"{
					qui findfile `file'
					local arg1 = "`=ustrregexra("`r(fn)'","\\","/")'"
					local arg2 = "sthlp"
				}
				else{
					local arg1 "`=ustrregexra("`file'","\\","/")'"
					//local arg1 = ustrtohex("`filepath'")
					local arg2 = "other"
					}
				!python "`cmdurl'/chatgpt_script.py" "add" "`arg1'" "`arg2'" "`config'.log"
			}
					
			//4.2 prepare the do option
			if "`do'" != ""{
				qui cap `do'
				if _rc != 0 {
					disp "Please provide the correct command"
					exit
				}
				log using data.log,replace nomsg
				`do'
				log close
				local arg1 = "data.log"
				local arg2 = "data"
				!python "`cmdurl'/chatgpt_script.py" "add" "`arg1'" "`arg2'" "`config'.log"
			}
			
			//4.3 add the command
			//local cmd = ustrtohex("`command'")
			!python "`cmdurl'/chatgpt_script.py" "add" "`command'" "prompt" "`config'.log"
			
			//4.4 curl the target url
			shell curl `agenturl' ///
				-H "Content-Type: application/json" ///
				-H "Authorization: Bearer `key_openai'" ///
				--data "@`config'.log" ///
				-o "res.txt" `x_proxy'
			
			//4.5 complete the log file and type the reply
			!python "`cmdurl'/chatgpt_script.py" "log" "`config'.log"
			!python "`cmdurl'/chatgpt_script.py" "type"
			ltype output.txt
		}
		else{
			cap mkdir _chatgpt_tmpdata
			
			//4.1 check forbid option
			if "`do'" != ""{
				di as error "do() option is not allowed in chatgpt `1'"
				exit 198
			}
			
			//for loop
			forvalues num = 1/`=_N'{
				//4.2 prepare the payload.txt of each query
				copy "`config'.log" "_chatgpt_tmpdata/payload_`num'.txt",replace
				
				if "`file'" != "" { //在multitalk状态下，file选项默认为变量名
					!python "`cmdurl'/chatgpt_script.py" "add" "`=`file'[`num']'" "other" "_chatgpt_tmpdata/payload_`num'.txt"
				}
				
				local mod1 = subinstr("`command'","}","[`num']'",.)
				local mod2 = subinstr("`mod1'","{","`=",.)
				//local cmd = ustrtohex("`mod2'")
				!python "`cmdurl'/chatgpt_script.py" "add" "`mod2'" "prompt" "_chatgpt_tmpdata/payload_`num'.txt"
				
				//4.3 curl the target url of each query
				shell start curl `agenturl' ///
				-H "Content-Type: application/json" ///
				-H "Authorization: Bearer `key_openai'" ///
				--data "@_chatgpt_tmpdata/payload_`num'.txt" ///
				-o "_chatgpt_tmpdata/res_`num'.txt" `x_proxy'
			}
			//ending
			disp as text "This program will execute a few minute, Please use `chatgpt update` after this ok"
		}
	}
	
	// Update
	// ----------
	if "`1'" == "update"{
		//1. check forbid option
		foreach option in "command" "file" "do" "proxy" "key_openai" "agenturl" "stata" "system" "model" "temperature" "max_tokens"{
			if "``option''" != ""{
				di as error "`option'() option is not allowed in chatgpt `1'"
				exit 198
			}
		}
		
		//2. check gen() option
		if "`generate'" == ""{
			local generate "gpt_res"
		}
		
		//3. set the config()
		if "`config'" == ""{
			local config "chat-default"
		}
		else{
			file open myfile using "`config'.conf", read text
			file read myfile line
			local `line'
			while r(eof) == 0 {
				file read myfile line
				cap local `line'
			}
			file close myfile
		}
				
		
		//4. complete the log file and type the reply
		cap drop `generate'
		gen `generate' = ""
		!python "`cmdurl'/chatgpt_script.py" "multilog" "`config'.log" "`=_N'"
		forvalues num = 1/`=_N'{
			cap replace `generate' = fileread("_chatgpt_tmpdata/output_`num'.txt") in `num'
			cap erase "_chatgpt_tmpdata/output_`num'.txt"
			cap erase "_chatgpt_tmpdata/payload_`num'.txt"
			cap erase "_chatgpt_tmpdata/res_`num'.txt"
		}
	}
	
	
	//Wrong Mode
	if !inlist("`1'", "talk", "longtalk", "multitalk", "test", "config", "update"){
		di as error "Wrong subcommand is specified."
		exit 199
	}
	
	//Debug Info in Non-test subcommand
	local debug = fileread("chatgpt_test_log.txt")
	if ustrregexm("`debug'","failed") & "`1'" != "test"{
		di as error "The Python script encountered an error as follows:"
		type chatgpt_test_log.txt
	}
	cap erase chatgpt_test_log.txt
	
end

cap prog drop ltype
program define ltype
	version 14.0
	local 0 `"using `0'"'
	syntax using/
	tempname fh
	local linenum = 0
	file open `fh' using `"`using'"', read
	file read `fh' line
	while r(eof)==0 {
		local linenum = `linenum' + 1
		display as result `" `macval(line)'"'
		file read `fh' line
	}
	file close `fh'
end
