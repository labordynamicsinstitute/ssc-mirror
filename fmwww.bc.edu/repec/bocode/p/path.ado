*! version 2.1.0 03aug2016 daniel klein

pr path , sclass
	vers 11.2
	
	gettoken subcmd 0 : 0
	if !inlist(`"`subcmd'"', ///
		"split", 	///
		"pieces", 	///
		"of", 		///
		"to", 		/// synonym for of
		"join", 	///
		"confirm") 	///
	{
		sret clear
		di as err `"invalid subcommand `subcmd'"'
		e 198
	}
	
	if ("`subcmd'" == "to") {
		loc subcmd of
	}
	
	if ("`subcmd'" == "confirm") {
		gettoken what : 0 , qed(q)
		if !(`q') {
			path_confirm_what , `what'
		}
		else {
			loc what // void
		}
		if (`"`what'"' != "") {
			gettoken dump 0 : 0
		}
	}
	else {
		sret clear
	}
	
	gettoken path 0 : 0 , qed(q)
	if mi(`"`path'"') {
		if ("`subcmd'" == "confirm") {
			loc rc 7
		}
		else {
			loc rc = !(`q') * ("`subcmd'" != "of") * 198
		}
		path_expected `rc'
	}
	
	if ("`subcmd'" == "join") {
		gettoken path2 0 : 0 , qed(q)
		path_expected `= ((!`q') & mi(`"`path2'"')) * 198'
	}
	
	gettoken void : 0
	if (`"`void'"' != "") {
		di as err `"invalid `void'"'
		e 198
	}
	
	m : path`subcmd'_ado()
end

pr path_confirm_what
	vers 11.2
	
	cap syntax ///
	[ , ///
		NEW 		///
		URL 		///
		ISURL 		/// not documented
		ABSolute 	///
		ISABSolute 	/// not documented
		* ///
	]
	
	if ("`new'" != "") {
		loc what new
	}
	else if ("`url'`isurl'" != "") {
		loc what url
	}
	else if ("`absolute'`isabsolute'" != "") {
		loc what abs
	}
	
	c_local what : copy loc what
end

pr path_expected
	vers 11.2
	
	if (`0') {
		di as err "'' found where path expected"
	}
	
	e `0'
end

vers 11.2

m :

void pathsplit_ado()
{
	string scalar path, directory, filename, suffix
	
	path = st_local("path")
	
	suffix = pathsuffix(path)
	path = pathrmsuffix(path)
	
	if ((filename = pathbasename(path)) == "") {
		directory = path
	}
	else {
		pathsplit(path, directory = "", filename = "")
	}
	
	st_global("s(directory)", directory)
	st_global("s(suffix)", suffix)
	st_global("s(extension)", suffix)
	st_global("s(filename)", filename)
}

void pathpieces_ado()
{
	string scalar path, piece
	real scalar i
	
	path = st_local("path")
	i = 0
	
	while (path != "") {
		pathsplit(path, path, piece)
		if (anyof(("/", "\"), piece)) {
			continue
		}
		st_global("s(piece" + strofreal(++i)+ ")", piece)
	}
	
	st_global("s(pieces)", strofreal(i))
}

void pathof_ado()
{
	string scalar path, pwd, piece
	
	path = st_local("path")
	pwd = c("pwd")
	
	while (pwd != "") {
		pathsplit(pwd, pwd, piece)
		if (anyof((piece, pwd), path)) {
			st_global("s(path)", pathjoin(pwd, piece))
			return
		}
	}
	
	errprintf("%s not found in current working directory\n", path)
	exit(601)
}

void pathjoin_ado()
{
	st_global("s(path)", ///
		pathjoin(st_local("path"), st_local("path2")))
}

void pathconfirm_ado()
{
	string scalar what, path, msg
	real scalar rc
	
	what = st_local("what")
	path = st_local("path")
	
	if (anyof(("", "new"), what)) {
		if (pathsuffix(path) != "") {
			rc = 698
			msg = sprintf("%s not a directory\n", path)
		}
		else if (what == "") {
			rc = direxists(path) ? 0 : 601
			msg = sprintf("directory %s not found\n", path)
		}
		else if (what == "new") {
			rc = direxists(path) ? 602 : 0
			msg = sprintf("directory %s already exists\n", path)
		}
		else {
			rc = 9
			msg = "internal error\n"
		}
	}
	else if (what == "url") {
		rc = pathisurl(path) ? 0 : 669
		msg = sprintf("%s not URL\n", path)
	}
	else if (what == "abs") {
		rc = pathisabs(path) ? 0 : 698
		msg = sprintf("%s not absolute path\n", path)
	}
	else {
		rc = 9
		msg = "internal error\n"
	}
	
	if (rc) {
		errprintf(msg)
	}
	exit(rc)
}

end
e

2.1.0	03aug2016	new subcommands pieces and of
2.0.0	03aug2016	improved code subcommand split
					omitting path is now an error
					new subcommand confirm (nclass)
					released on SSC
1.0.0	06apr2016	initial version (not released)
