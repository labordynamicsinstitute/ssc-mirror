*! 7feb2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program source
version 11.1

mata: DoIt()
end

version 11.1
mata:
void DoIt() { //>>def func<<
	class tabel scalar t
	
	adopath=pathsubsysdir(pathlist())'
	input=st_local("0")
	if (input=="profile") {
		files=subfiles("`:environment USERPROFILE'","profile.do",1)
		if (!length(files)) fowrite(files=pathto("`:environment USERPROFILE'/profile.do"),"*put your startup stuff here"+eol())
		}
	else if (strpos(input,dirsep())) files=input //hope dirsep is always right
	else {
		if (strpos(input,".")) files=subfiles(adopath,input)
		else {
			files=subfiles(adopath,input+".ado")
			if (!sum(strlen(files))) files=subfiles(adopath,input+".mata")
			}
		}
	if (length(files)==1) {
		printf("{txt:%s}\n",files)
		launchfile(files)
		}
	else if (length(files)>1) {
		t.body=t.setLinks("stata",adorn(`"stata "source "',files,char(34)),files)
		t.present("-")
		}
	else printf("{txt:File not found: }{res:%s}",input)
	}
end 

