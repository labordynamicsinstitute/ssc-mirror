*! Authors:
*! Chuntao Li, Ph.D. , China Stata Club(爬虫俱乐部)(chtl@henu.edu.cn)
*! Xueren Zhang, China Stata Club(爬虫俱乐部)(snowmanzhang@whu.edu.cn)
*! June 23th, 2023
*! Program written by Dr. Chuntao Li, Xueren Zhang
*! Used to interact with ChatGPT within Stata software and obtain Stata usage recommendations from ChatGPT.
*! and can only be used in Stata version 16.0 or above
*! Original Service Source: https://platform.openai.com/docs/api-reference/introduction
*! Please do not use this code for commerical purpose

cap prog drop chatgpt
program define chatgpt

	if _caller() < 14 {
		disp as error "this is version `=_caller()' of Stata; it cannot run version 14.0 programs"
		exit 199
	}
	version 14
	syntax anything, [set_session(string) ///
				openai_api_key(string) ///
				replace stata ///
				engine(string) ///
				systemprompt(string) ///  
				command(string) /// 
				session(string) ///
				file(string) ///
				do(string)]

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

	//3. print the python version
	//!python "`cmdurl'/chatgpt_script.py" "version"
	
	//3. split anything args	
	tokenize `anything'
	local anything "`2'"

	//4. download init payload file
	if "`engine'" == ""{
		local engine = "gpt-3.5-turbo"
		local engine_inner ""
	}
	else{
		local engine_inner "1"
	}
	if !inlist("`engine'", "gpt-3.5-turbo", "gpt-3.5-turbo-0301"){
		disp as error "engine() option incorrectly specified."
		exit 198
	}
	capture confirm file "`cmdurl'/payload-`engine'.txt"
	if _rc != 0 {
		!python "`cmdurl'/chatgpt_script.py" "gen" "`engine'" "`cmdurl'"
	}
	



	//Test
	//---------
	if "`1'" == "test"{
		//1. find the python script.py
		capture confirm file "`cmdurl'/chatgpt_script.py"
		if _rc! = 0{
			di as error "file chatgpt_script.py can not found!"
		}
		else{
			di as text "√ file chatgpt_script.py found."
		}

		//2. before curl
		cap erase chatgpt_test_log.txt
		!python "`cmdurl'/chatgpt_script.py" "gen" "`engine'" "`cmdurl'"
		local sp = ustrtohex("test中文")
		cap erase payload.txt
		copy "`cmdurl'/payload-`engine'.txt" payload.txt  
		!python "`cmdurl'/chatgpt_script.py" "system" ". `sp'" "payload.txt"
		local cmd = ustrtohex("test中文")
		!python "`cmdurl'/chatgpt_script.py" "add" "`cmd'"
		local arg1 = ustrtohex("chatgpt_test.do")
		file open myfile using "chatgpt_test.do", write replace
		file write myfile "Hello, world!"
		file close myfile
		!python "`cmdurl'/chatgpt_script.py" "read" "`arg1'" "do"

		//3. check curl
		cap erase curl_version.txt
		!curl --version > curl_version.txt
		cap confirm file "curl_version.txt"
		if _rc!=0{
			di as error "system can not found curl!"
		}
		else{
			di as text "√ curl had installed successfully."
		}

		shell curl https://api.openai.com/v1/chat/completions ///
			-H "Content-Type: application/json" ///
			-H "Authorization: Bearer sk-errorkey" ///
			--data "@payload.txt" ///
			-o "res.txt"

		//4. after curl
		!python "`cmdurl'/chatgpt_script.py" "log" "chat-default.log"
		!python "`cmdurl'/chatgpt_script.py" "type"
		
		//5. check curl
		disp as text "The Python script has six testing items: gen, system, add, read, log, and type. The successful tests are:"
		cap confirm file "chatgpt_test_log.txt"
		if _rc == 0{
			type chatgpt_test_log.txt
		}
	}

	//Session
	//-----------
	if "`1'" == "session"{
		//1. check option
		foreach option in "command" "session" "file" "do"{
			if "``option''" != ""{
				di as error "`option'() option is not allowed in chatgpt session"
				exit 198
			}
		}
		
		//2. check set_session
		if "`set_session'" == ""{
			local tmp = uniform()
			local session = "random_" + subinstr("`tmp'", ".", "", .)

			disp as text "Since the set_session option was not specified, the command has automatically generated a session with the id `session'"
		}
		else{
			local session "`set_session'"
		}
		
	
		//3. check openai_api_key
		if "`openai_api_key'" == ""{
			disp as error "openai_api_key() option is required in chatgpt session."
			exit 100
		}
		else{
			global `session' "`openai_api_key'"
		}
		
		//4. check the replace
		if "`replace'" != ""{
			cap erase `session'.log
		}
		
		//5. new the session log file
		copy "`cmdurl'/payload-`engine'.txt" `session'.log
		
		//6. add info in log file
		if "`stata'" != "" {
			!python "`cmdurl'/chatgpt_script.py" "system" "You are a helpful assistant that proficient in using Stata software. I will present my requirements to you, and you will provide me with the most suitable Stata Command based on my needs. Please keep your responses as concise as possible." "`session'.log"
		}

		if "`systemprompt'" != ""{
			local sp = ustrtohex("`systemprompt'")
			!python "`cmdurl'/chatgpt_script.py" "system" ". `sp'" "`session'.log"
		}
	}
	
	
	// Talk & Read
	// ----------
	if inlist("`1'", "talk", "read"){

		//1. check error option
		foreach option in "set_session" "replace"{
			if "``option''" != ""{
				di as error "`option'() option is not allowed in chatgpt `1'"
				exit 198
			}
		}

	
		//2. check session and init payload.txt
		cap erase payload.txt
		if "`session'" != ""{
			local key $`session'
			copy `session'.log payload.txt
			
			foreach option in "openai_api_key" "systemprompt" "stata"{
				if "``option''" != ""{
					di as text "`option'() option is not allowed in chatgpt `1', it will be ignored. You can specify it in chatgpt session"
				}
			}			
			if "`engine_inner'" != ""{
				di as text "engine() option is not allowed in chatgpt `1', it will be ignored. You can specify it in chatgpt session"
			} 			
		}
		else{
			if "`openai_api_key'" == ""{
				disp as error "openai_api_key() option is required in chatgpt `1'."
				exit 100
			}
			else{
				local key "`openai_api_key'"
			}
			
			copy "`cmdurl'/payload-`engine'.txt" payload.txt  		
			//engine option is added in P3 stage

			if "`stata'" != "" {
				!python "`cmdurl'/chatgpt_script.py" "system" "You are a helpful assistant that proficient in using Stata software. I will present my requirements to you, and you will provide me with the most suitable Stata Command based on my needs. Please keep your responses as concise as possible." "payload.txt"
			}

			if "`systemprompt'" != ""{
				local sp = ustrtohex("`systemprompt'")
				!python "`cmdurl'/chatgpt_script.py" "system" ". `sp'" "payload.txt"
			}
		}
		
		
		//3. prepare the args Read the file
		if "`1'" == "read"{
			if "`anything'" == "other"{
				if "`file'" == "" {
					disp as error "Please enter the path of the file to be read."
					exit
				}
				local filepath "`=ustrregexra("`file'","\\","/")'"
				local arg1 = ustrtohex("`filepath'")
				local arg2 = "other"
			}
			else if "`anything'" == "data"{
				if "`do'" == ""{
					local do "sum *,detail"
				}
				else{
					qui cap `do'
					if _rc != 0 {
						disp "Please provide the correct command"
						exit
					}
				}
				
				log using data.log,replace nomsg
				`do'
				log close
				local arg1 = "data.log"
				local arg2 = "data"
			}
			else{
				if index("`anything'",".") == 0{
					disp as error "Please input the file suffix"
					exit
				}
				local suffix = ustrregexra("`anything'","^(.+)\.","")
				
				if "`suffix'" == "ado"{
					qui findfile `anything'
					local arg1 = "`=ustrregexra("`r(fn)'","\\","/")'"
					local arg2 = "ado"
				}
				else if "`suffix'" == "sthlp"{
					qui findfile `anything'
					local arg1 = "`=ustrregexra("`r(fn)'","\\","/")'"
					local arg2 = "sthlp"
				}
				else if "`suffix'" == "do"{
					local filepath "`=ustrregexra("`anything'","\\","/")'"
					local arg1 = ustrtohex("`filepath'")
					local arg2 = "do"
				}
				else{
					disp as error "Please give a do/ado/sthlp file, or use `chatgpt read other,file(the path of the file to be read)`"
					exit
				}
			}
			if "`command'" == ""{
				local command "Please introduce this file content"
			}
			!python "`cmdurl'/chatgpt_script.py" "read" "`arg1'" "`arg2'"
		}

		//4. add the command
		local cmd = ustrtohex("`command'")
		!python "`cmdurl'/chatgpt_script.py" "add" "`cmd'"
		
		
		//5. curl the target url

		shell curl https://api.openai.com/v1/chat/completions ///
			-H "Content-Type: application/json" ///
			-H "Authorization: Bearer `key'" ///
			--data "@payload.txt" ///
			-o "res.txt"

		//6. complete the log file and type the reply
		if "`session'" != ""{
			!python "`cmdurl'/chatgpt_script.py" "log" "`session'.log"
		}
		else{
			!python "`cmdurl'/chatgpt_script.py" "log" "chat-default.log"
		}
		!python "`cmdurl'/chatgpt_script.py" "type"
		ltype output.txt

	}
end

cap prog drop ltype
program define ltype
	version 15.1
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
