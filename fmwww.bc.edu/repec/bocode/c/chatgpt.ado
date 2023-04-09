*! Authors:
*! Chuntao Li, Ph.D. , China Stata Club(爬虫俱乐部)(chtl@henu.edu.cn)
*! Xueren Zhang, China Stata Club(爬虫俱乐部)(snowmanzhang@whu.edu.cn)
*! March 29th, 2023
*! Program written by Dr. Chuntao Li, Xueren Zhang
*! Used to interact with ChatGPT within Stata software and obtain Stata usage recommendations from ChatGPT.
*! and can only be used in Stata version 14.0 or above
*! Original Service Source: https://platform.openai.com/docs/api-reference/introduction
*! Please do not use this code for commerical purpose

cap prog drop chatgpt
program define chatgpt

	if _caller() < 14.0 {
		disp as error "this is version `=_caller()' of Stata; it cannot run version 14.0 programs"
		exit 9
	}
	version 14
	syntax, openai_api_key(string) command(string) [chatmode(string) dataupdate logupdate]

	
	local cmd = ustrtohex("`command'")
	if "`dataupdate'" != ""{
		local datainfo ""
	}

	if "`chatmode'" == "" local chatmode = "short"
	if !inlist("`chatmode'", "short", "long") {
		disp as error "you specify the option chatmode() wrongly."
		exit 198
	}

	capture confirm file rawpayload.txt
	if _rc != 0 {
	    copy https://stata-command.oss-cn-hangzhou.aliyuncs.com/chatgpt/rawpayload.txt ./rawpayload.txt
	}


	if "`chatmode'" == "short"{
		capture erase longchat.txt
		! jq ".messages = .messages + [{\"role\": \"user\", \"content\": \"`cmd'\"}]" ./rawpayload.txt > payload.txt
	
		shell curl https://api.openai.com/v1/chat/completions ///
			-H "Content-Type: application/json" ///
			-H "Authorization: Bearer $OPENAI_API_KEY" ///
			--data "@payload.txt" ///
			-o "res.txt"
	}
	else{
		capture confirm file longchat.txt
		if _rc != 0 {
	    	copy ./rawpayload.txt longchat.txt
		}

		! jq ".messages = .messages + [{\"role\": \"user\", \"content\": \"`cmd'\"}]" ./longchat.txt > ./newlongchat.txt
		!del longchat.txt
		!rename newlongchat.txt longchat.txt
	
		shell curl https://api.openai.com/v1/chat/completions ///
			-H "Content-Type: application/json" ///
			-H "Authorization: Bearer $OPENAI_API_KEY" ///
			--data "@longchat.txt" ///
			-o "res.txt"

		!jq -s ".[0].messages = .[0].messages + [.[1].choices[0].message] | .[0]" ./longchat.txt ./res.txt > ./newlongchat.txt
		!del longchat.txt
		!rename newlongchat.txt longchat.txt
	}


	! jq .choices[0].message.content res.txt > response.txt
	type response.txt



end
