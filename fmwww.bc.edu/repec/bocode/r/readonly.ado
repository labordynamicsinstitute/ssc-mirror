*! 13nov2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program readonly
version 11

mata: DoIt()
end


version 11
mata:
void DoIt() { //>>def func<<
	if (c("os")!="Windows") errel("readonly is only written for Windows, so far.")
	syntaxl(st_local("0"),&(path="anything"))
	path=pcanon(path,"fex",".dta")
	sput(script="","Const ReadOnly = 1")
	sput(script,`"Set objFSO = CreateObject("Scripting.FileSystemObject")"')
	sput(script,sprintf(`"Set objFile = objFSO.GetFile("%s")"',path))
	sput(script,"objFile.Attributes = objFile.Attributes OR ReadOnly")
	fowrite(vbfile=pathto("_readonly.vbs","inst"),script)
	stata(sprintf(`"shell "%s""',vbfile))
	}
end
