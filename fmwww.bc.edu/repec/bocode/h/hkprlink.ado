* Authors:
* Chuntao Li, China Stata Club(爬虫俱乐部), (chtl@zuel.edu.cn)
* Tianyao Luo, China Stata Club(爬虫俱乐部), (cnl1426@163.com)
* Dr. Muhammad Usman，UE Business school, Division of Management and Administrative Sciences, University of Education, Lahore, Pakistan, (m.usman@ue.edu.pk)
* Haitao Si, Wuhan University, China, (sihaitao0114@163.com)
* Please do not use this code for commerical purpose

clear
capture program drop hkprlink
program define hkprlink

	if _caller() < 17.0 {
		disp as error "this is version `=_caller()' of Stata; it cannot run version 17.0 programs"
        exit 9
	}
	
	if c(os) != "Windows" {	
		disp as error "This command must be used in Windows"
		exit 691
	}
	
	syntax anything(name = list), [path(string)]
	
	clear
	local end: disp %dCYND date("`c(current_date)'", "DMY")
	
	if "`path'" != "" {
			cap mkdir `"`path'"'
        }
    else {
		local path `"`c(pwd)'"'
        di `"`path'"'
    }
	
	if ustrregexm("`path'", "[\u4e00-\u9fa5]") { 
		disp as error "The specified path cannot contain Chinese characters"
		exit 703
    }
    if regexm("`path'", "(/|\\)$") { 
		local path = regexr("`path'", ".$", "")
    }
	
	foreach code in `list' {
		qui {
			if length("`code'") >5 {
				disp as error `"`code' is an invalid stock code or Network anti-picking"'
				exit 601
			} 
			while length("`code'") < 5 {
				local code = "0" + "`code'"
			}				
			local url "https://www1.hkexnews.hk/search/prefix.do?&callback=callback&lang=ZH&type=A&name=`code'&market=SEHK" 
		}
		
		tempfile sctemp
		cap copy `"`url'"' `"`sctemp'.txt"', replace 
		local times = 0
		while _rc != 0 & _rc != 1 {
			if _rc == 601 {
				clear
				di as error "The code entered is wrong"
				exit 601
			}
			else {
				local times = `times' + 1
				sleep 1000
				cap copy `"`url'"' `"`sctemp'.txt"', replace
				if `times' > 10 {
					di as error "Internet speeds is too low to get the data"
					exit 2
				}
			}
		}	
		
		qui{
			clear
			set obs 1
			gen v = fileread(`"`sctemp'.txt"')
			gen x = ustrregexs(1) if ustrregexm(v, `"stockId"\:(.*?),"code"')
			local url "https://www1.hkexnews.hk/search/titleSearchServlet.do?sortDir=0&sortByOptions=DateTime&category=0&market=SEHK&stockId=`=x[1]'&documentType=11000&fromDate=19990401&toDate=`end'&title=&searchType=2&t1code=-2&t2Gcode=-2&t2code=-2&rowRange=1000&lang=zh"  
		}
		
		cap copy `"`url'"' `"`sctemp'.txt"', replace 
		local times = 0
		while _rc != 0 & _rc != 1 {
			if _rc == 601 {
				clear
				di as error "The code entered is wrong"
				exit 601
			}
			else {
				local times = `times' + 1
				sleep 1000
				cap copy `"`url'"' `"`sctemp'.txt"', replace
				if `times' > 10 {
					di as error "Internet speeds is too low to get the data"
					exit 2
				}
			}
		}
		
		qui{
			clear
			set obs 1
			gen v = fileread(`"`sctemp'.txt"')
			if length(v) < 200{
				disp as error "The code entered is wrong"
				exit 601
			}
			split v,p(`"\"TITLE\":\"')
			drop v v1
			stack v*, into(v) clear
			drop _stack
			drop if strpos(v,"摘要")
			gen title = ustrregexs(1) if ustrregexm(v,`"" (.*?)\\"')
			gen url = "https://www1.hkexnews.hk/" + (ustrregexs(1)) if ustrregexm(v,`"FILE_LINK\\":\\"(.*?)\\"')
			gen stkcd = ustrregexs(1) if ustrregexm(v,`""STOCK_CODE\\":\\"(.*?)\\"')
			replace stkcd = stkcd[_n-1] if stkcd == ""
			drop v
			save `path'/`code', replace
		}
		qui{	
			tempname handle
			file open `handle' using `path'/psfile.ps1, text write replace
			file write `handle' _newline "$" `"client = new-object System.Net.WebClient"' 
			forvalues num = 1/`=_N'{
				local Bt = url[`num']
				if strpos("`Bt'","pdf"){
					file write `handle'  _newline "$" `"client.DownloadFile('`Bt'', '`path'/`code'_`num'.pdf')"'
				}
				if strpos("`Bt'","htm"){
					file write `handle'  _newline "$" `"client.DownloadFile('`Bt'', '`path'/`code'_`num'.htm')"'
				}
				if strpos("`Bt'","doc"){
					file write `handle'  _newline "$" `"client.DownloadFile('`Bt'', '`path'/`code'_`num'.doc')"'
				}
				if strpos("`Bt'","docx"){
					file write `handle'  _newline "$" `"client.DownloadFile('`Bt'', '`path'/`code'_`num'.docx')"'
				}
			}
			file close `handle'
		}
		winexec powershell.exe -ExecutionPolicy Bypass -File `path'/psfile.ps1
		di "You've got the report link of `code'"
		di "Waiting powershell close,please"
		di "Report is downloading"
		sleep 3000
		local success =  fileexists(`"`path'/`code'_1.pdf"') + fileexists(`"`path'/`code'_1.htm"') + fileexists(`"`path'/`code'_1.doc"') + fileexists(`"`path'/`code'_1.docx"') 
		while `success' == 0  {
			winexec powershell.exe -ExecutionPolicy Bypass -File `path'/psfile.ps1
			dis "Failed to download the report of `code'"
			dis "Downloading again"
			sleep 10000
		}
	}
	winexec powershell.exe Remove-Item -Path "`path'/psfile.ps1 -recurse -force"
end

