*! version 1.0.0  20jul2026  Eric A. Booth  (eric.a.booth@gmail.com)
*! projectbackup : zip up a project folder, subfolders included, in native Stata
*! (no external programs -- zipfile + Mata only)

program define projectbackup, rclass
	version 14

	syntax [anything(name=folder id="folder")] [, ///
		ARCHive(string)      /// where zips go; default <folder>/_archive
		PREfix(string)       /// zip name prefix; default backup_<foldername>
		TIMEstamp            /// append _YYYYMMDD_HHMMSS to the zip name
		LABel(string)        /// custom tag appended to the zip name
		replace              /// overwrite an existing zip of the same name
		TOC                  /// create/update _backup_log.md in the archive dir
		NOTE(string)         /// note recorded in the log entry (implies toc)
		EXclude(string asis) /// top-level entries to skip; * and ? wildcards ok
		NODOTfiles           /// skip top-level dotfiles/dirs (.git .DS_Store ...)
		KEEP(numlist max=1 integer >0) /// prune archive to the newest # backups
		REMOVEall            /// delete all matching backups; make no new one
		ZIPPY                /// also save a .zippy copy (Stata Journal email-safe)
		MANifest             /// write <zipname>_manifest.txt listing every file
		DRYrun               /// scan and report only; nothing written
		FORCE                /// override the size/count safety stops
		]

	local t0 = clock("`c(current_date)' `c(current_time)'", "DMY hms")
	if `"`note'"' != "" local toc toc

	*--- resolve and validate the source folder ------------------------------
	local folder `folder'                        // strip any outer quotes
	if `"`folder'"' == "" local folder `"`c(pwd)'"'
	local pwd0 `"`c(pwd)'"'
	capture quietly cd `"`folder'"'
	if _rc {
		di as err `"projectbackup: folder not found: `folder'"'
		exit 601
	}
	local folder `"`c(pwd)'"'                    // now absolute + normalized
	quietly cd `"`pwd0'"'
	mata: st_local("base", pathbasename(st_local("folder")))
	if `"`base'"' == "" local base "project"

	*--- destinations and names ----------------------------------------------
	if `"`prefix'"' == "" local prefix = "backup_" + subinstr(`"`base'"', " ", "_", .)
	else                  local prefix = subinstr(`"`prefix'"', " ", "_", .)

	if `"`archive'"' == "" local archive `"`folder'/_archive"'
	mata: st_local("adexists", strofreal(direxists(st_local("archive"))))
	if !`adexists' & "`dryrun'" == "" {
		capture mkdir `"`archive'"'
		mata: st_local("adexists", strofreal(direxists(st_local("archive"))))
		if !`adexists' {
			di as err `"projectbackup: cannot create archive folder: `archive'"'
			di as err "(its parent folder must already exist)"
			exit 693
		}
	}
	if `adexists' {                              // absolutize + normalize
		quietly cd `"`archive'"'
		local archive `"`c(pwd)'"'
		quietly cd `"`pwd0'"'
	}

	*--- removeall: sweep the archive and stop -------------------------------
	if "`removeall'" != "" {
		local ndel 0
		foreach ext in zip zippy {
			local todel : dir `"`archive'"' files "`prefix'*.`ext'", respectcase nofail
			foreach f of local todel {
				capture rm `"`archive'/`f'"'
				if !_rc {
					di as txt `"  removed  `f'"'
					local ++ndel
				}
			}
		}
		if "`toc'" != "" & `ndel' > 0 {
			_projbk_logline `"`archive'"' "(removed `ndel' backups)" "" "" `"`note'"'
		}
		di as txt "projectbackup: removed " as res `ndel' as txt " backup file(s) from " ///
			`"{browse `"`archive'"'}"'
		return local archive `"`archive'"'
		return scalar nremoved = `ndel'
		exit
	}

	*--- exclusion patterns (whitespace-separated; wildcards ok) ----------------
	* strip any quotes so exclude("a b*") and exclude(a b*) behave identically;
	* use a wildcard (e.g. exclude(raw*)) to match a name that contains spaces.
	local exlist : subinstr local exclude `"""' "", all
	if "`nodotfiles'" != "" local exlist `exlist' .*
	* always exclude the archive folder itself when it sits at the top level
	if strpos(`"`archive'"', `"`folder'/"') == 1 {
		local relarch = substr(`"`archive'"', strlen(`"`folder'"') + 2, .)
		if !strpos(`"`relarch'"', "/") & !strpos(`"`relarch'"', "\") {
			local exlist `exlist' `"`relarch'"'
		}
		else {
			di as txt "note: archive() is nested below the top level of the source folder,"
			di as txt "      so earlier backups will be swept into every new backup."
			di as txt "      Consider a top-level folder (the default) or one outside the project."
		}
	}
	else if `"`archive'"' == `"`folder'"' {
		di as txt "note: archive() is the source folder itself; earlier backups at the top"
		di as txt "      level will be swept into every new backup."
	}
	* tab-join the patterns so Mata can split them safely
	local exjoined
	foreach pat of local exlist {
		local exjoined `"`exjoined'`=char(9)'`pat'"'
	}

	*--- zip name ---------------------------------------------------------------
	local stamp
	if "`timestamp'" != "" {
		local d : di %tdCCYYNNDD daily("`c(current_date)'", "DMY")
		local stamp = "_`d'_" + subinstr("`c(current_time)'", ":", "", .)
	}
	local lab
	if `"`label'"' != "" local lab = "_" + subinstr(`"`label'"', " ", "_", .)
	local zipbase `prefix'`lab'`stamp'
	local zipname `zipbase'.zip
	local zipfull `"`archive'/`zipname'"'

	capture confirm file `"`zipfull'"'
	if !_rc & "`replace'" == "" & "`dryrun'" == "" {
		if "`timestamp'" != "" {
			* a timestamped name is meant to be unique; a same-second collision
			* just gets a counter so rapid/scripted backups never fail.
			local k 1
			while !_rc {
				local zipbase `prefix'`lab'`stamp'_`k'
				local zipname `zipbase'.zip
				local zipfull `"`archive'/`zipname'"'
				local ++k
				capture confirm file `"`zipfull'"'
			}
		}
		else {
			di as err `"projectbackup: `zipname' already exists in the archive folder"'
			di as err "specify {bf:replace} to overwrite it, or {bf:timestamp} for unique names"
			exit 602
		}
	}

	*--- scan the tree (native Mata walk: counts, bytes, path lengths) ---------
	local manifile
	if "`manifest'" != "" & "`dryrun'" == "" local manifile `"`archive'/`zipbase'_manifest.txt"'
	mata: _projbk_scan(st_local("folder"), st_local("exjoined"), st_local("manifile"))
	* sets: pb_nfiles pb_ndirs pb_bytes pb_maxdepth pb_maxplen pb_maxpfile
	*       pb_bigbytes pb_bigfile pb_nskip

	if `pb_nfiles' == 0 {
		di as err `"projectbackup: nothing to back up in `folder'"'
		di as err "(no files found after exclusions)"
		exit 459
	}

	_projbk_sizestr `pb_bytes'
	local sizestr `r(s)'
	_projbk_sizestr `pb_bigbytes'
	local bigstr `r(s)'
	local nfc : di %20.0fc `pb_nfiles'
	local nfc = strtrim("`nfc'")

	*--- safety checks -----------------------------------------------------------
	* hard stops (override with force); soft warnings otherwise
	local stop 0
	local warn 0
	if `pb_bytes' > 2147483648 {
		di as `= cond("`force'" == "", "err", "txt")' ///
			"projectbackup: total size is `sizestr' -- over the 2 GB safety limit."
		local stop 1
	}
	if `pb_bigbytes' > 2147483648 {
		di as `= cond("`force'" == "", "err", "txt")' ///
			"projectbackup: a single file is over 2 GB (`bigstr'):"
		di as `= cond("`force'" == "", "err", "txt")' ///
			`"  `pb_bigfile'"'
		local stop 1
	}
	if `pb_nfiles' > 100000 {
		di as `= cond("`force'" == "", "err", "txt")' ///
			"projectbackup: `nfc' files -- over the 100,000-file safety limit."
		local stop 1
	}
	if `stop' & "`force'" == "" & "`dryrun'" == "" {
		_projbk_advice
		di as err "add {bf:force} to zip anyway, {bf:dryrun} to just measure, or see the advice above"
		exit 498
	}
	if `pb_bytes' > 524288000 & `pb_bytes' <= 2147483648 {
		di as txt "note: total size is `sizestr'; zipping may take a while."
		local warn 1
	}
	if `pb_nfiles' > 20000 & `pb_nfiles' <= 100000 {
		di as txt "note: `nfc' files; zipping may take a while."
		local warn 1
	}
	if `pb_maxplen' > 200 {
		di as txt "note: longest relative path is " as res `pb_maxplen' as txt " characters:"
		di as txt `"        `pb_maxpfile'"'
		di as txt "      Windows callers may hit the 260-character MAX_PATH limit when"
		di as txt "      this zip is extracted under a deep folder.  Consider shortening"
		di as txt "      nested folder/file names or extracting near the drive root."
		local warn 1
	}

	*--- dryrun: report and stop ---------------------------------------------------
	if "`dryrun'" != "" {
		di as txt ""
		di as txt "projectbackup dry run " as txt "{hline 40}"
		di as txt "  source folder:   " as res `"`folder'"'
		di as txt "  would write:     " as res `"`zipfull'"'
		di as txt "  files:           " as res "`nfc'"
		di as txt "  subfolders:      " as res `pb_ndirs'
		di as txt "  total size:      " as res "`sizestr'"
		di as txt "  largest file:    " as res "`bigstr'" as txt `"  (`pb_bigfile')"'
		di as txt "  deepest nesting: " as res `pb_maxdepth' as txt " level(s)"
		di as txt "  longest path:    " as res `pb_maxplen' as txt " character(s)"
		if `pb_nskip' > 0 ///
			di as txt "  excluded:        " as res `pb_nskip' as txt " top-level entr(ies)"
		if `stop' {
			di as txt ""
			_projbk_advice
		}
		else if !`warn' di as txt "  no size or path concerns found."
		di as txt "{hline 62}"
	}
	else {
		*--- zip it (paths stored relative to the source folder) ---------------
		local ziplist
		local tdirs  : dir `"`folder'"' dirs  "*", respectcase nofail
		local tfiles : dir `"`folder'"' files "*", respectcase nofail
		foreach grp in tdirs tfiles {
			foreach f of local `grp' {
				local skip 0
				foreach pat of local exlist {
					if strmatch(lower(`"`f'"'), lower(`"`pat'"')) local skip 1
				}
				if !`skip' local ziplist `"`ziplist' `"`f'"'"'
			}
		}
		quietly cd `"`folder'"'
		capture quietly zipfile `ziplist', saving(`"`zipfull'"', replace)
		local rc = _rc
		quietly cd `"`pwd0'"'
		if `rc' {
			di as err "projectbackup: zipfile failed (r(`rc'))"
			exit `rc'
		}

		mata: st_local("zipbytes", strtrim(sprintf("%20.0f", _projbk_fsize(st_local("zipfull")))))
		_projbk_sizestr `zipbytes'
		local zsizestr `r(s)'

		*--- optional .zippy copy (Stata Journal submissions) --------------------
		if "`zippy'" != "" {
			capture copy `"`zipfull'"' `"`archive'/`zipbase'.zippy"', replace
			if _rc di as txt "note: could not write the .zippy copy (r(`=_rc'))"
		}

		*--- optional backup log ---------------------------------------------------
		if "`toc'" != "" {
			_projbk_logline `"`archive'"' `"`zipname'"' "`nfc'" "`zsizestr'" `"`note'"'
		}

		*--- optional rotation -------------------------------------------------------
		* Rotate only the timestamped series -- their names sort chronologically,
		* so a name sort is a date sort.  Labelled or plain backups are left alone.
		if "`keep'" != "" {
			local zl : dir `"`archive'"' files "`prefix'*.zip", respectcase nofail
			mata: _projbk_k = J(0, 1, "")
			local nts 0
			foreach f of local zl {
				if regexm(`"`f'"', "_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9]+(_[0-9]+)?\.zip$") {
					mata: _projbk_k = _projbk_k \ st_local("f")
					local ++nts
				}
			}
			if `nts' == 0 {
				di as txt "note: keep() rotates only timestamped backups; none found, nothing pruned."
				di as txt "      add {bf:timestamp} so each backup gets a unique, sortable name."
			}
			mata: _projbk_k = sort(_projbk_k, 1)
			mata: st_local("nz", strofreal(rows(_projbk_k)))
			local ndel = `nz' - `keep'
			forvalues i = 1/`=max(`ndel',0)' {
				mata: st_local("f", _projbk_k[`i'])
				capture rm `"`archive'/`f'"'
				capture rm `"`archive'/`= substr(`"`f'"', 1, strlen(`"`f'"') - 4)'.zippy"'
				di as txt `"  pruned   `f'"'
			}
			mata: mata drop _projbk_k
			if `ndel' > 0 di as txt "  (kept the newest `keep' backups; names sort " ///
				"chronologically when you use {bf:timestamp})"
		}

		*--- summary --------------------------------------------------------------------
		local t1 = clock("`c(current_date)' `c(current_time)'", "DMY hms")
		local secs = (`t1' - `t0') / 1000
		di as txt ""
		di as txt "projectbackup " as txt "{hline 48}"
		di as txt "  source:   " as res `"`folder'"'
		di as txt "            " as res "`nfc'" as txt " files, " as res `pb_ndirs' ///
			as txt " subfolders, " as res "`sizestr'"
		di as txt "  archive:  " as res `"`zipname'"' as txt "  (" as res "`zsizestr'" as txt ")"
		if "`zippy'"    != "" di as txt "  zippy:    " as res `"`zipbase'.zippy"'
		if "`manifest'" != "" di as txt "  manifest: " as res `"`zipbase'_manifest.txt"'
		if "`toc'"      != "" di as txt "  log:      " as res "_backup_log.md" as txt "  (updated)"
		di as smcl `"  folder:   {browse `"`archive'"'}"'
		di as txt "{hline 62}"

		return local  zipfile `"`zipfull'"'
		if "`zippy'" != "" return local zippy `"`archive'/`zipbase'.zippy"'
		return scalar zipbytes = `zipbytes'
		return scalar seconds  = `secs'
	}

	*--- returns common to dryrun and real runs --------------------------------------
	return local  folder  `"`folder'"'
	return local  archive `"`archive'"'
	return local  size    "`sizestr'"
	return scalar nfiles   = `pb_nfiles'
	return scalar ndirs    = `pb_ndirs'
	return scalar bytes    = `pb_bytes'
	return scalar maxdepth = `pb_maxdepth'
	return scalar maxplen  = `pb_maxplen'
end


*--- append one row to _backup_log.md, creating it with a header if needed ------
program define _projbk_logline
	args archive zipname nfiles size note
	local tocfile `"`archive'/_backup_log.md"'
	local note = subinstr(`"`note'"', "|", "/", .)
	tempname fh
	capture confirm file `"`tocfile'"'
	if _rc {
		file open `fh' using `"`tocfile'"', write text
		file write `fh' "# Backup log" _n _n
		file write `fh' "Maintained by projectbackup (Stata).  Newest entries last." _n _n
		file write `fh' "| date | time | archive | files | size | note |" _n
		file write `fh' "|------|------|---------|-------|------|------|" _n
	}
	else file open `fh' using `"`tocfile'"', write text append
	file write `fh' `"| `c(current_date)' | `c(current_time)' | `zipname' | `nfiles' | `size' | `note' |"' _n
	file close `fh'
end


*--- human-readable byte counts -----------------------------------------------
program define _projbk_sizestr, rclass
	args b
	if `b' < 0 {
		return local s "unknown"
		exit
	}
	if `b' >= 1073741824      local s : di %9.2f (`b'/1073741824)
	else if `b' >= 1048576    local s : di %9.2f (`b'/1048576)
	else if `b' >= 1024       local s : di %9.1f (`b'/1024)
	else                      local s "`b'"
	local s = strtrim("`s'")
	if `b' >= 1073741824      return local s "`s' GB"
	else if `b' >= 1048576    return local s "`s' MB"
	else if `b' >= 1024       return local s "`s' KB"
	else                      return local s "`s' bytes"
end


*--- advice for oversized projects ----------------------------------------------
program define _projbk_advice
	di as txt "advice for large projects:"
	di as txt "  - {bf:exclude()} the heavy subfolders (raw data, output, .git) and back"
	di as txt "    up code separately from data:"
	di as txt `"      projectbackup, exclude("data output .git") timestamp"'
	di as txt "  - back up big subfolders one at a time, each to its own zip:"
	di as txt `"      projectbackup "data/wave1", archive(../_archive) timestamp"'
	di as txt "  - Stata's {help zipfile} reads the whole tree through one process and"
	di as txt "    offers no compression tuning; for multi-GB folders a dedicated"
	di as txt "    archiver (7-Zip, tar) or a sync service is faster and safer, and"
	di as txt "    zips over 2 GB can fail to open in older unzip tools."
end


version 14
mata:

// split a tab-joined pattern list into a rowvector
string rowvector _projbk_splittab(string scalar s)
{
	string rowvector r
	string scalar    rest, tok
	real scalar      p

	r    = J(1, 0, "")
	rest = s
	while (rest != "") {
		p = strpos(rest, char(9))
		if (p == 0) {
			tok  = rest
			rest = ""
		}
		else {
			tok  = substr(rest, 1, p - 1)
			rest = substr(rest, p + 1, .)
		}
		if (tok != "") r = r, tok
	}
	return(r)
}

// file size in bytes without reading the file; -1 if unreadable
real scalar _projbk_fsize(string scalar fn)
{
	real scalar fh, sz

	fh = _fopen(fn, "r")
	if (fh < 0) return(-1)
	fseek(fh, 0, 1)
	sz = ftell(fh)
	fclose(fh)
	return(sz)
}

real scalar _projbk_match(string scalar name, string rowvector ex)
{
	real scalar j

	for (j = 1; j <= cols(ex); j++) {
		if (strmatch(strlower(name), strlower(ex[j]))) return(1)
	}
	return(0)
}

struct _projbk_S {
	real scalar     nfiles, ndirs, bytes, maxdepth, maxplen, bigbytes, nskip, np
	string scalar   bigfile, maxpfile
	string colvector paths
}

void _projbk_walk(string scalar root, string scalar rel, real scalar depth,
	string rowvector ex, struct _projbk_S scalar S)
{
	string colvector fls, drs
	string scalar    rpath, here
	real scalar      i, sz

	here = (rel == "" ? root : root + "/" + rel)
	fls  = dir(here, "files", "*", 0)
	drs  = dir(here, "dirs",  "*", 0)

	for (i = 1; i <= rows(fls); i++) {
		if (rel == "" & cols(ex) > 0 & _projbk_match(fls[i], ex)) {
			S.nskip = S.nskip + 1
			continue
		}
		rpath    = (rel == "" ? fls[i] : rel + "/" + fls[i])
		S.nfiles = S.nfiles + 1
		sz = _projbk_fsize(root + "/" + rpath)
		if (sz > 0)             S.bytes = S.bytes + sz
		if (sz > S.bigbytes) {
			S.bigbytes = sz
			S.bigfile  = rpath
		}
		if (strlen(rpath) > S.maxplen) {
			S.maxplen  = strlen(rpath)
			S.maxpfile = rpath
		}
		if (depth > S.maxdepth) S.maxdepth = depth
		if (S.np >= rows(S.paths)) S.paths = S.paths \ J(rows(S.paths), 1, "")
		S.np          = S.np + 1
		S.paths[S.np] = rpath
	}
	for (i = 1; i <= rows(drs); i++) {
		if (rel == "" & cols(ex) > 0 & _projbk_match(drs[i], ex)) {
			S.nskip = S.nskip + 1
			continue
		}
		S.ndirs = S.ndirs + 1
		_projbk_walk(root, (rel == "" ? drs[i] : rel + "/" + drs[i]), depth + 1, ex, S)
	}
}

void _projbk_scan(string scalar root, string scalar exjoined, string scalar manifile)
{
	struct _projbk_S scalar S
	string rowvector ex
	string colvector p
	real scalar      fh, i

	S.nfiles   = 0
	S.ndirs    = 0
	S.bytes    = 0
	S.maxdepth = 0
	S.maxplen  = 0
	S.bigbytes = 0
	S.nskip    = 0
	S.np       = 0
	S.bigfile  = ""
	S.maxpfile = ""
	S.paths    = J(1024, 1, "")

	ex = _projbk_splittab(exjoined)
	_projbk_walk(root, "", 1, ex, S)

	if (manifile != "" & S.np > 0) {
		p = sort(S.paths[|1 \ S.np|], 1)
		unlink(manifile)
		fh = fopen(manifile, "w")
		fput(fh, "manifest for: " + root)
		fput(fh, sprintf("files: %g", S.nfiles))
		fput(fh, "")
		for (i = 1; i <= rows(p); i++) fput(fh, p[i])
		fclose(fh)
	}

	st_local("pb_nfiles",   strtrim(sprintf("%20.0f", S.nfiles)))
	st_local("pb_ndirs",    strtrim(sprintf("%20.0f", S.ndirs)))
	st_local("pb_bytes",    strtrim(sprintf("%20.0f", S.bytes)))
	st_local("pb_maxdepth", strtrim(sprintf("%20.0f", S.maxdepth)))
	st_local("pb_maxplen",  strtrim(sprintf("%20.0f", S.maxplen)))
	st_local("pb_bigbytes", strtrim(sprintf("%20.0f", S.bigbytes)))
	st_local("pb_nskip",    strtrim(sprintf("%20.0f", S.nskip)))
	st_local("pb_bigfile",  S.bigfile)
	st_local("pb_maxpfile", S.maxpfile)
}

end
