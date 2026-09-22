*! ff.ado   1.0.0   19sep2026
*! Browse and search Stata's built-in functions, read directly from the
*! function documentation that ships with Stata.
*!
*!     ff                       list the categories
*!     ff <text>                search function names and descriptions
*!     ff <name>, detail        full entry for one function
*!     ff, category(<cat>)      list one category
*!     ff, all                  list every function
*!     ff, names                search function names only
*!     ff <name>, open          open Stata's own help page for <name>
*!
*! Wildcards * and ? may be used in <text>.
*!
*! Authors:
*!   WU Lianghai
*!   School of Business, Anhui University of Technology (AHUT)
*!   Ma'anshan, Anhui, China
*!   agd2010@yeah.net
*!
*!   WU Hanyan
*!   Department of Accountancy, City University of Hong Kong (CityU)
*!   2325476320@qq.com

mata:

string scalar _ff_pad(string scalar s, real scalar w)
{
	string scalar out

	out = s
	while (strlen(out) < w) out = out + " "
	return(out + " ")
}

string scalar _ff_rule(real scalar n)
{
	string scalar out

	out = ""
	while (strlen(out) < n) out = out + "-"
	return(out)
}

string scalar _ff_word1(string scalar s)
{
	real scalar n, k, b
	string scalar ch

	n = strlen(s)
	k = 1
	while (k <= n) {
		ch = substr(s, k, 1)
		if (ch == " " | ch == char(9) | ch == char(10) | ch == char(13)) {
			k = k + 1
		} else {
			break
		}
	}
	b = k
	while (k <= n) {
		ch = substr(s, k, 1)
		if (ch == " " | ch == char(9) | ch == char(10) | ch == char(13)) {
			break
		} else {
			k = k + 1
		}
	}
	if (b > n) return("")
	return(substr(s, b, k - b))
}

real scalar _ff_drop(string scalar nm)
{
	string scalar w

	w = "|" + strlower(_ff_word1(nm)) + "|"
	if (strpos("|p_end|p2colreset|p2colset|p2col|smcl|break|phang2|phang|pstd|p|col|bind|space|marker|title|findalias|viewerjumpto|vieweralsosee|hline|c|*|...|", w) > 0) return(1)
	return(0)
}

real scalar _ff_pos(string scalar s, string scalar sub, real scalar from)
{
	real scalar p

	if (from > strlen(s)) return(0)
	p = strpos(substr(s, from), sub)
	if (p == 0) return(0)
	return(p + from - 1)
}

real scalar _ff_match(string scalar s, real scalar p, real scalar n)
{
	real scalar q, b, k, d
	string scalar cur

	q = _ff_pos(s, "}", p + 1)
	b = _ff_pos(s, "{", p + 1)
	if (b == 0) return(q)
	if (q > 0 & q < b) return(q)
	d = 0
	for (k = p; k <= n; k++) {
		cur = substr(s, k, 1)
		if (cur == "{") {
			d = d + 1
		} else if (cur == "}") {
			d = d - 1
			if (d == 0) return(k)
		}
	}
	return(0)
}

string scalar _ff_smcl(string scalar s)
{
	real scalar n, i, e, p, m, c, k, pb, pc, pe, last
	string scalar out, inner, name, content

	if (strpos(s, "{") == 0) return(s)
	n = strlen(s)
	out = ""
	i = 1
	last = 1
	while (i <= n) {
		p = _ff_pos(s, "{", i)
		if (p == 0) break
		e = _ff_match(s, p, n)
		if (e == 0) {
			i = p + 1
		} else {
			if (p > last) out = out + substr(s, last, p - last)
			inner = substr(s, p + 1, e - p - 1)
			m = strlen(inner)
			c = 0
			k = 1
			while (k <= m) {
				pc = _ff_pos(inner, ":", k)
				if (pc == 0) break
				pb = _ff_pos(inner, "{", k)
				if (pb > 0 & pb < pc) {
					pe = _ff_match(inner, pb, m)
					if (pe == 0) break
					k = pe + 1
				} else {
					c = pc
					break
				}
			}
			if (c > 0) {
				name = substr(inner, 1, c - 1)
				content = substr(inner, c + 1, m - c)
			} else {
				name = inner
				content = ""
			}
			if (_ff_drop(name) == 0) {
				if (c > 0) {
					out = out + _ff_smcl(content)
				} else {
					out = out + _ff_smcl(inner)
				}
			}
			i = e + 1
			last = i
		}
	}
	if (n >= last) out = out + substr(s, last, n - last + 1)
	return(out)
}

string scalar _ff_collapse(string scalar s)
{
	string scalar ws

	ws = "[" + char(9) + char(10) + char(13) + " ]+"
	return(strtrim(ustrregexra(s, ws, " ")))
}

string colvector _ff_lines(string scalar path)
{
	string colvector L
	real scalar i

	L = cat(path)
	if (rows(L) > 0) {
		if (any(strpos(L, char(13)))) {
			for (i = 1; i <= rows(L); i++) {
				if (strlen(L[i]) > 0) {
					if (substr(L[i], strlen(L[i]), 1) == char(13)) {
						L[i] = substr(L[i], 1, strlen(L[i]) - 1)
					}
				}
			}
		}
	}
	return(L)
}

string colvector _ff_split(string scalar s)
{
	string colvector out
	real scalar i, n, b
	string scalar ch, tok

	out = J(0, 1, "")
	n = strlen(s)
	i = 1
	while (i <= n) {
		ch = substr(s, i, 1)
		if (ch == " " | ch == char(9) | ch == char(10) | ch == char(13)) {
			i = i + 1
		} else {
			b = i
			while (i <= n) {
				ch = substr(s, i, 1)
				if (ch == " " | ch == char(9) | ch == char(10) | ch == char(13)) {
					break
				} else {
					i = i + 1
				}
			}
			tok = substr(s, b, i - b)
			if (strlen(tok) > 1) {
				if (substr(tok, 1, 1) == char(34)) {
					if (substr(tok, strlen(tok), 1) == char(34)) {
						tok = substr(tok, 2, strlen(tok) - 2)
					}
				}
			}
			out = out \ tok
		}
	}
	return(out)
}

string scalar _ff_syntrim(string scalar s)
{
	real scalar p, k, n, d
	string scalar cur

	p = strpos(s, "(")
	if (p == 0) {
		if (strlen(s) > 40) return(substr(s, 1, 40))
		return(s)
	}
	n = strlen(s)
	d = 0
	for (k = p; k <= n; k++) {
		cur = substr(s, k, 1)
		if (cur == "(") {
			d = d + 1
		} else if (cur == ")") {
			d = d - 1
			if (d == 0) return(substr(s, 1, k))
		}
	}
	return(substr(s, 1, p - 1))
}

string scalar _ff_fname(string scalar s)
{
	real scalar p, i
	string scalar ch

	p = strpos(s, "(")
	if (p == 0) return("")
	i = p - 1
	while (i >= 1) {
		ch = substr(s, i, 1)
		if (strpos("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_", ch) > 0) {
			i = i - 1
		} else {
			break
		}
	}
	if (i >= p - 1) return("")
	return(substr(s, i + 1, p - i - 1))
}

string rowvector _ff_parse(string scalar path, real scalar full)
{
	string colvector L
	string scalar txt, rest, blk, head, body, t, sig, desc, lim, headdesc
	string scalar key, val, cur, arg
	real scalar i, p, q, e, d, k, m, start, np, nq, bn, pos, rlen, stop

	L = _ff_lines(path)
	txt = ""
	for (i = 1; i <= rows(L); i++) txt = txt + L[i] + char(10)

	sig = ""
	desc = ""
	lim = ""
	headdesc = ""
	stop = 0

	rest = txt
	while (strlen(rest) > 0 & stop == 0) {
		p = strpos(rest, "{p2colreset}")
		if (p > 0) {
			blk = substr(rest, 1, p - 1)
			rest = substr(rest, p + 12, strlen(rest) - p - 11)
		} else {
			blk = rest
			rest = ""
		}

		q = strpos(blk, "{p2colset")
		if (q > 0) {
			head = substr(blk, 1, q - 1)
			body = substr(blk, q, strlen(blk) - q + 1)
		} else {
			head = blk
			body = ""
		}

		t = _ff_collapse(_ff_smcl(head))
		if (strlen(t) > 0) {
			if (headdesc == "") headdesc = t
			if (sig == "" | full == 1) {
				t = _ff_syntrim(t)
				if (sig == "") {
					sig = t
				} else {
					sig = sig + " ; " + t
				}
			}
		}

		if (body != "" & stop == 0) {
			bn = strlen(body)
			pos = 1
			while (pos <= bn & stop == 0) {
				p = strpos(substr(body, pos, bn - pos + 1), "{p2col:")
				if (p == 0) {
					pos = bn + 1
				} else {
					start = pos + p + 7
					e = 0
					d = 0
					for (k = start; k <= bn; k++) {
						cur = substr(body, k, 1)
						if (cur == "{") {
							d = d + 1
						} else if (cur == "}") {
							if (d == 0) {
								e = k
								break
							} else {
								d = d - 1
							}
						}
					}
					if (e == 0) {
						pos = bn + 1
					} else {
						key = _ff_collapse(_ff_smcl(substr(body, start, e - start)))
						if (strlen(key) > 0) {
							if (substr(key, strlen(key), 1) == ":") {
								key = substr(key, 1, strlen(key) - 1)
							}
						}
						key = _ff_collapse(key)

						rlen = bn - e
						np = strpos(substr(body, e + 1, rlen), "{p_end}")
						nq = strpos(substr(body, e + 1, rlen), "{p2col:")
						m = 0
						if (np > 0 & nq > 0) {
							m = min((np, nq))
						} else if (np > 0) {
							m = np
						} else if (nq > 0) {
							m = nq
						}
						if (m > 0) {
							val = substr(body, e + 1, m - 1)
							pos = e + m
						} else {
							val = substr(body, e + 1, rlen)
							pos = bn + 1
						}
						val = _ff_collapse(_ff_smcl(val))

						if (key == "Description") {
							if (desc == "") {
								desc = val
								if (full == 0) stop = 1
							}
						} else if (full == 1) {
							if (key == "Range") {
								if (lim == "") {
									lim = "range: " + val
								} else {
									lim = lim + " ; range: " + val
								}
							} else if (substr(key, 1, 6) == "Domain") {
								if (strlen(key) > 6) {
									arg = _ff_collapse(substr(key, 7, strlen(key) - 6))
								} else {
									arg = ""
								}
								if (arg == "") {
									t = "domain: " + val
								} else {
									t = arg + ": " + val
								}
								if (lim == "") {
									lim = t
								} else {
									lim = lim + " ; " + t
								}
							}
						}
					}
				}
			}
		}
	}

	if (sig == "") sig = headdesc
	if (desc == "") desc = headdesc
	return((sig, desc, lim))
}

string scalar _ff_catlabel(string scalar stem)
{
	if (stem == "math_functions") return("math")
	if (stem == "string_functions") return("string")
	if (stem == "datetime_functions") return("date")
	if (stem == "density_functions") return("stat")
	if (stem == "random_number_functions") return("random")
	if (stem == "trig_functions") return("trig")
	if (stem == "programming_functions") return("prog")
	if (stem == "matrix_functions") return("matrix")
	if (stem == "time_series_functions") return("ts")
	return("")
}

real scalar _ff_rank(string scalar cat)
{
	string rowvector R
	real scalar i

	R = ("math","string","date","stat","random","trig","prog","matrix","ts","other")
	for (i = 1; i <= cols(R); i++) {
		if (cat == R[i]) return(i)
	}
	return(10)
}

void _ff_map(string scalar base, string scalar clist,
             string colvector mtopic, string colvector mcat)
{
	string colvector L, stems
	string scalar path, t, cat
	real scalar i, j, p
	real colvector w

	mtopic = J(0, 1, "")
	mcat = J(0, 1, "")
	stems = _ff_split(clist)
	for (j = 1; j <= rows(stems); j++) {
		cat = _ff_catlabel(stems[j])
		if (cat != "") {
			path = base + substr(stems[j], 1, 1) + "/" + stems[j] + ".sthlp"
			L = _ff_lines(path)
			for (i = 1; i <= rows(L); i++) {
				p = strpos(L[i], "INCLUDE help ")
				if (p > 0) {
					t = _ff_collapse(substr(L[i], p + 13, strlen(L[i]) - p - 12))
					if (substr(t, 1, 2) == "f_") {
						w = selectindex(mtopic :== t)
						if (rows(w) * cols(w) == 0) {
							mtopic = mtopic \ t
							mcat = mcat \ cat
						}
					}
				}
			}
		}
	}
}

string matrix _ff_catalog(string scalar base, string scalar clist, string scalar listfile)
{
	string matrix C
	string colvector L, mtopic, mcat, files
	string rowvector v
	string scalar path, t, fname, topic
	real scalar i, n, r
	real colvector rk, idx, w

	_ff_map(base, clist, mtopic, mcat)

	files = J(0, 1, "")
	L = _ff_lines(listfile)
	for (i = 1; i <= rows(L); i++) {
		if (L[i] != "") files = files \ L[i]
	}
	n = rows(files)
	if (n == 0) {
		files = mtopic
		n = rows(files)
	}

	C = J(n, 6, "")
	for (i = 1; i <= n; i++) {
		fname = files[i]
		if (substr(fname, strlen(fname) - 4, 5) == ".ihlp") {
			topic = substr(fname, 1, strlen(fname) - 5)
		} else {
			topic = fname
		}
		path = base + "f/" + topic + ".ihlp"
		v = _ff_parse(path, 0)
		t = _ff_fname(v[1])
		if (t == "") t = substr(topic, 3, strlen(topic) - 2)
		C[i, 1] = t
		w = selectindex(mtopic :== topic)
		if (rows(w) * cols(w) == 0) {
			C[i, 2] = "other"
		} else {
			C[i, 2] = mcat[w[1]]
		}
		C[i, 3] = v[1]
		C[i, 4] = v[2]
		C[i, 5] = v[3]
		C[i, 6] = topic
	}

	rk = J(n, 1, 0)
	for (i = 1; i <= n; i++) rk[i] = _ff_rank(C[i, 2])
	idx = J(0, 1, 0)
	for (r = 1; r <= 10; r++) {
		for (i = 1; i <= n; i++) {
			if (rk[i] == r) idx = idx \ i
		}
	}
	return(C[idx, .])
}

void _ff_list(string matrix C, real colvector idx)
{
	real scalar i, w, dmax
	string scalar line, ds

	w = st_numscalar("c(linesize)")
	if (w == . | w < 78) w = 90
	dmax = w - 32
	for (i = 1; i <= rows(idx); i++) {
		ds = C[idx[i], 4]
		if (strlen(ds) > dmax) ds = substr(ds, 1, dmax - 3) + "..."
		line = "  " + _ff_pad(C[idx[i], 1], 18) + _ff_pad("[" + C[idx[i], 2] + "]", 11) + ds
		printf("%s\n", line)
	}
}

void _ff_detail(string matrix C, real scalar i, string rowvector v)
{
	printf("\n")
	printf("%s\n", "  " + C[i, 1] + "   [" + C[i, 2] + "]")
	printf("%s\n", "  " + _ff_rule(66))
	printf("%s\n", "  Syntax:       " + v[1])
	printf("%s\n", "  Description:  " + v[2])
	if (v[3] != "") printf("%s\n", "  Limits:       " + v[3])
	printf("%s\n", "  Category:     " + C[i, 2] + "      (ff, category(" + C[i, 2] + "))")
	printf("%s\n", "  Stata help:   help " + C[i, 1] + "      ff " + C[i, 1] + ", open")
	printf("\n")
}

void _ff_show_cats(string colvector cats, real colvector cnt, real scalar total)
{
	real scalar i
	string scalar line

	printf("\n")
	printf("%s\n", "  Stata built-in functions: " + strofreal(total) + " functions in " + strofreal(rows(cats)) + " categories")
	printf("\n")
	for (i = 1; i <= rows(cats); i++) {
		line = "  " + _ff_pad(cats[i], 10) + _ff_pad(strofreal(cnt[i]) + " functions", 16) + "ff, category(" + cats[i] + ")"
		printf("%s\n", line)
	}
	printf("\n")
	printf("%s\n", "  Search by name or meaning:   ff <text>")
	printf("%s\n", "  Full entry for one function: ff <name>, detail")
	printf("%s\n", "  List everything:             ff, all")
	printf("%s\n", "  Open Stata's own help:       ff <name>, open")
	printf("\n")
}

void _ff_categories(string matrix C)
{
	string colvector allcat, cats
	real colvector cnt, w
	real scalar i, n, k

	n = rows(C)
	allcat = C[., 2]
	cats = J(0, 1, "")
	cnt = J(0, 1, 0)
	for (i = 1; i <= n; i++) {
		w = selectindex(cats :== allcat[i])
		if (rows(w) * cols(w) == 0) {
			cats = cats \ allcat[i]
			cnt = cnt \ 1
		} else {
			k = w[1]
			cnt[k] = cnt[k] + 1
		}
	}
	_ff_show_cats(cats, cnt, n)
}

void _ff_counts(string scalar base, string scalar clist, string scalar listfile)
{
	string colvector L, mtopic, mcat, files, cats
	string rowvector R
	string scalar topic
	real colvector cnt, cnt2, w
	real scalar i, j, n, k

	_ff_map(base, clist, mtopic, mcat)
	R = ("math","string","date","stat","random","trig","prog","matrix","ts","other")

	files = J(0, 1, "")
	L = _ff_lines(listfile)
	for (i = 1; i <= rows(L); i++) {
		if (L[i] != "") files = files \ L[i]
	}
	n = rows(files)

	cnt = J(10, 1, 0)
	for (i = 1; i <= n; i++) {
		topic = files[i]
		if (substr(topic, strlen(topic) - 4, 5) == ".ihlp") {
			topic = substr(topic, 1, strlen(topic) - 5)
		}
		k = 10
		w = selectindex(mtopic :== topic)
		if (rows(w) * cols(w) > 0) {
			for (j = 1; j <= 10; j++) {
				if (mcat[w[1]] == R[j]) {
					k = j
					break
				}
			}
		}
		cnt[k] = cnt[k] + 1
	}

	cats = J(0, 1, "")
	cnt2 = J(0, 1, 0)
	for (j = 1; j <= 10; j++) {
		if (cnt[j] > 0) {
			cats = cats \ R[j]
			cnt2 = cnt2 \ cnt[j]
		}
	}
	_ff_show_cats(cats, cnt2, n)
}

void _ff_main(string scalar pattern, string scalar cat, real scalar namesonly,
              real scalar detail, real scalar listall, string scalar base,
              string scalar clist, string scalar listfile)
{
	string matrix C
	string rowvector v
	string scalar plow, clow
	real colvector idx, m1, w
	real scalar i, n, hit, wild

	if (pattern == "" & cat == "" & listall == 0) {
		_ff_counts(base, clist, listfile)
		return
	}

	C = _ff_catalog(base, clist, listfile)
	n = rows(C)

	if (cat != "") {
		clow = strlower(cat)
		idx = J(0, 1, 0)
		for (i = 1; i <= n; i++) {
			if (strlower(C[i, 2]) == clow) idx = idx \ i
		}
		if (rows(idx) == 0) {
			printf("\n  ff: no category named %s\n", cat)
			_ff_categories(C)
			return
		}
		printf("\n  %s: %s functions\n\n", C[idx[1], 2], strofreal(rows(idx)))
		_ff_list(C, idx)
		printf("\n")
		return
	}

	if (listall == 1) {
		printf("\n  All Stata built-in functions (%s)\n\n", strofreal(n))
		_ff_list(C, (1::n))
		printf("\n")
		return
	}

	if (pattern == "") {
		_ff_categories(C)
		return
	}

	plow = strlower(pattern)
	wild = strpos(plow, "*") + strpos(plow, "?")

	idx = J(0, 1, 0)
	for (i = 1; i <= n; i++) {
		hit = 0
		if (wild > 0) {
			hit = strmatch(strlower(C[i, 1]), plow)
		} else if (namesonly == 1) {
			if (strpos(strlower(C[i, 1]), plow) > 0) hit = 1
		} else {
			if (strpos(strlower(C[i, 1]), plow) > 0) hit = 1
			if (strpos(strlower(C[i, 4]), plow) > 0) hit = 1
		}
		if (hit > 0) idx = idx \ i
	}

	if (rows(idx) == 0) {
		printf("\n  ff: nothing matches %s\n", pattern)
		printf("%s\n", "  Try fewer characters, or run ff to see the categories.")
		printf("\n")
		return
	}

	if (detail == 1) {
		m1 = C[idx, 1] :== plow
		if (sum(m1) > 0) {
			w = selectindex(m1)
			idx = idx[w]
		}
		if (rows(idx) == 1) {
			v = _ff_parse(base + "f/" + C[idx[1], 6] + ".ihlp", 1)
			_ff_detail(C, idx[1], v)
			return
		}
		printf("\n  %s functions match %s\n\n", strofreal(rows(idx)), pattern)
		_ff_list(C, idx)
		printf("\n%s\n", "  Add , detail to an exact function name for its full entry.")
		printf("\n")
		return
	}

	if (rows(idx) == 1) {
		printf("\n  1 function matches %s\n\n", pattern)
	} else {
		printf("\n  %s functions match %s\n\n", strofreal(rows(idx)), pattern)
	}
	_ff_list(C, idx)
	printf("\n")
}

end

program define ff
	version 14.0

	syntax [anything(name=pat)] [, Category(string) Names Detail All Open]

	local base "`c(sysdir_base)'"

	if ("`open'" != "") {
		if ("`pat'" == "") {
			capture noisily help functions
			if _rc display as error "ff: could not open Stata's function help"
			exit
		}
		capture noisily help `pat'
		if _rc {
			capture noisily help f_`pat'
			if _rc {
				display as error "ff: no Stata help page found for `pat'"
				exit 111
			}
		}
		exit
	}

	local cl ""
	foreach stem in math_functions string_functions datetime_functions ///
		density_functions random_number_functions trig_functions ///
		programming_functions matrix_functions time_series_functions {
		capture confirm file "`base'`=substr("`stem'",1,1)'/`stem'.sthlp"
		if _rc == 0 local cl "`cl' `stem'"
	}

	local fl : dir "`base'f" files "f_*.ihlp"
	tempfile fflist
	file open ffh using "`fflist'", write text
	foreach f of local fl {
		file write ffh "`f'" _n
	}
	file close ffh

	local optnames  = cond("`names'"  != "", "1", "0")
	local optdetail = cond("`detail'" != "", "1", "0")
	local optall    = cond("`all'"    != "", "1", "0")

	mata: _ff_main(`"`pat'"', `"`category'"', `optnames', `optdetail', `optall', `"`base'"', `"`cl'"', `"`fflist'"')
end
