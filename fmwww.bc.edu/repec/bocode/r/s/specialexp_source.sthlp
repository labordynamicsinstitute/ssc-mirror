*! version 1.0.0 Matthew White 10sep2013
vers 11

loc RS	real scalar
loc RR	real rowvector
loc RC	real colvector
loc SS	string scalar
loc SR	string rowvector
loc SC	string colvector

// "ocq" for "open compound quote"
loc ocq		("`" + `"""')
// "ccq" for "close compound quote"
loc ccq		(`"""' + "'")

/* Comments below refer to "problematically unbalanced open quotes." An
unbalanced open quote is problematic if it is an open compound double quote or
if it is a left single quote followed by ` or the end of the string.

Examples:

`' and `""' are balanced quotes.

`x contains an unbalanced left single quote, but it is unproblematic, because it
is not followed by ` or the end of the string.

`"x, x`, and ``x all contain problematically unbalanced open quotes. */

mata:

/* -specialexp_other()- splits a string into separate strings when needed to
handle the ASCII characters 1-31, 127, and 255. For example, the string X\rY,
where \r is a carriage return, needs to be split into "X" + char(13) + "Y":
"X\rY" is not a valid expression.

-specialexp_other()- returns the split string as the rowvector els (for
"elements") along with a rowvector named literal that is 1 if the corresponding
element of els is a string literal and 0 otherwise. */
void function specialexp_other(`SS' s, `SR' els, `RR' literal)
{
	`RS' len, i
	`RR' ascii
	`SR' chars
	transmorphic t

	ascii = 1..31, 127, 255
	len = length(ascii)
	chars = J(1, len, "")
	for (i = 1; i <= len; i++) {
		chars[i] = char(ascii[i])
	}

	t = tokeninit("", chars, "")
	tokenset(t, s)
	els = tokengetall(t)

	literal = J(1, length(els), 1)
	for (i = 1; i <= len; i++) {
		literal = literal :& els :!= chars[i]
		els = subinstr(els, chars[i], sprintf("char(%f)", ascii[i]), .)
	}
}

// Split a string into separate strings when needed to correctly enclose a \.
// For example, the string \`x' needs to be split into "\" + "\`x'": "\`x'"
// results in `x', and "\\`x'" would expand the local macro.
`SR' function specialexp_escape(`SS' s)
{
	`RS' len, pos
	`SS' rest
	// "els for "elements"
	`SR' els

	// els will store the separate strings into which s will be split.
	els = ""
	// len (for "length") is the number of elements of els.
	len = 1
	rest = s
	while (rest != "") {
		pos = strpos(rest, "\")
		if (!pos) {
			els[len] = els[len] + rest
			rest = ""
		}
		else {
			els[len] = els[len] + substr(rest, 1, pos)
			rest = substr(rest, pos + 1, .)

			// If \ is followed by ` or $, start a new element.
			if (anyof(("`", "$"), substr(rest, 1, 1))) {
				els = els, ""
				len++
			}
		}
	}

	return(els)
}

/* -specialexp_balanced_quotes()- expects a colvector s that was tokenized from
a scalar x as follows:

t = tokeninit("", ("`", "'", `ocq', `ccq'), "")
tokenset(t, x)
s = tokengetall(t)'

-specialexp_balanced_quotes()- returns 1 if the concatenation of s (i.e., x)
does not contain a problematically unbalanced open quote and does not contain an
unbalanced close compound double quote; it returns 0 otherwise. */
// "probq" for "problematic quote"
`RS' function specialexp_balanced_quotes(`SC' s, |`RS' quotes, `RC' probq)
{
	// "inprob" for "inside problematic (quote)"
	`RS' rows, inside, inprob, row, i
	// "prob" for "problematic"; "isq" for "is quote"; "lsq" for "left single
	// quotes"; "ocq" for "open compound quotes."
	`RC' prob, isq, lsq, ocq
	`SS' type
	pointer(`RC') scalar pprob
	// "q" for "quotes"
	pointer(`SC') scalar q

	// If the quotes argument is specified, probq needs to be.
	assert(args() != 2)

	if (args() >= 2 & quotes) {
		q = &s
		pprob = &probq
	}
	else {
		rows = rows(s)
		prob = s[rows] == "`"
		if (rows > 1) {
			prob =
				s[|1 \ rows - 1|] :== "`" :&
				(s[|2 \ .|] :== "`" :|
				substr(s[|2 \ .|], 1, 1) :== `"""') \
				prob
		}
		prob = prob :| s :== `ocq'
		isq = s :== "`" :| s :== "'" :| s :== `ocq' :| s :== `ccq'
		q     = &select(s,    isq)
		pprob = &select(prob, isq)
	}
	rows = rows(*q)

	if (!rows)
		return(1)
	else if ((*q)[1] == "`" | (*q)[1] == `ocq') {
		lsq = ocq = inside = inprob = row = 0
		type = ""
		for (i = 1; i <= rows; i++) {
			lsq = lsq + ((*q)[i] == "`")   - ((*q)[i] == "'")
			ocq = ocq + ((*q)[i] == `ocq') - ((*q)[i] == `ccq')
			if (!inside) {
				if (lsq == 1 & (*q)[i] == "`" | ocq == 1 & (*q)[i] == `ocq') {
					type = (*q)[i]
					inside = 1
					inprob = (*pprob)[i]
					row = i
				}
				else if ((*q)[i] == `ccq')
					return(0)
			}
			else if (!lsq & type == "`" | !ocq & type == `ocq') {
				lsq = ocq = inside = inprob = 0
				if (i != row + 1) {
					if (!specialexp_balanced_quotes((*q)[|row + 1 \ i - 1|], 1,
						(*pprob)[|row + 1 \ i - 1|])) {
						return(0)
					}
				}
			}
		}

		if (!inside)
			return(1)
		else {
			// inprob = 1 if we're still inside a potentially problematic open
			// quote, for example, an open compound double quote.
			if (inprob)
				return(0)
			// !inprob & row == rows for a left single quote at the end of a
			// substring in the middle of the larger string. For example, `"`x"'
			// would result in a call of specialexp_balanced_quotes() with
			// s = "`" but probq = 0, in which case !inprob & row == rows.
			else if (row == rows)
				return(1)
			else {
				return(specialexp_balanced_quotes((*q)[|row + 1 \ .|], 1,
					(*pprob)[|row + 1 \ .|]))
			}
		}
		/*NOTREACHED*/
	}
	else if ((*q)[1] == "'") {
		if (rows == 1)
			return(1)
		else
			return(specialexp_balanced_quotes((*q)[|2 \ .|], 1, (*pprob)[|2 \ .|]))
		/*NOTREACHED*/
	}
	// Unbalanced close compound double quote
	else
		return(0)
	/*NOTREACHED*/
}

/* -specialexp_max_balanced()- expects a colvector s that was tokenized from a
scalar x as follows:

t = tokeninit("", ("`", "'", `ocq', `ccq'), "")
tokenset(t, x)
s = tokengetall(t)'

Further, it expects that s[1] is a left single quote or open compound double
quote.

-specialexp_max_balanced()- returns the maximum row such that the string formed
by concatenating the elements up to and including the row is enclosed by single
or compound double quotes and does not contain a problematically unbalanced open
quote. */
`RS' function specialexp_max_balanced(`SC' s)
{
	`RS' i
	// "balrows" for "balanced rows"
	`RC' balrows

	assert(s[1] == "`" | s[1] == `ocq')

	balrows = select(1::rows(s),
		!runningsum((s :== `ocq') - (s :== `ccq')) :&
		s :== (s[1] == "`" ? "'" : `ccq')
	)
	for (i = length(balrows); i >= 1; i--) {
		if (specialexp_balanced_quotes(s[|1 \ balrows[i]|]))
			return(balrows[i])
	}
	return(0)
}

// Split a string into separate strings when needed to correctly enclose a
// single or double quote. For example, the string `"' needs to be split into
// "`" + `"""' + "'".
// "unballsq" for "(problematically) unbalanced left single quote"
`SR' function specialexp_quotes(`SS' s, `RR' unballsq)
{
	// "dq" for "double quote"; "plen" for "piece length"; "prob" for
	// "problematic."
	`RS' len, dq, pos, plen, max, strdq, prob, i
	// "traillsq" for "trailing left single quote"
	`RR' traillsq
	// "c" for "character"
	`SS' rest, c, str
	// "els" for "elements"
	`SR' els
	// "trest" for "tokenized rest"
	`SC' trest
	transmorphic tinit, t

	// els will store the separate strings into which s will be split.
	els = ""
	// For each element of els, the corresponding element of unballsq is 1 if
	// the element contains a problematically unbalanced left single quote and
	// 0 otherwise.
	unballsq = 0
	// len (for "length") is the number of elements of els.
	len = 1
	// dq is 1 if the current element contains a double quote and 0 otherwise.
	dq = 0
	tinit = tokeninit("", ("`", "'", `ocq', `ccq'), "")
	rest = s
	while (rest != "") {
		pos = strpos(rest, "`") \ strpos(rest, "'") \ strpos(rest, `"""')
		if (!any(pos)) {
			els[len] = els[len] + rest
			rest = ""
		}
		else {
			pos = min(select(pos, pos))
			els[len] = els[len] + substr(rest, 1, pos - 1)
			rest = substr(rest, pos, .)
			c = substr(rest, 1, 1)

			// Unbalanced right single quote
			if (c == "'") {
				// If the right single quote would follow a ", start a new
				// element.
				if (substr(els[len], -1, 1) == `"""') {
					els = els, "'"
					unballsq = unballsq, 0
					len++
					dq = 0
				}
				else
					els[len] = els[len] + "'"
				plen = 1
			}
			// Simple double quote or unbalanced close compound double quote
			else if (c == `"""') {
				// If the element contains a problematically unbalanced left
				// single quote, start a new element.
				if (unballsq[len]) {
					els = els, `"""'
					unballsq = unballsq, 0
					len++
				}
				else
					els[len] = els[len] + `"""'
				dq = 1
				plen = 1

				// If it is an unbalanced close compound double quote, the
				// -c == "'"- case above will address the '.
			}
			// Left single quote or open compound double quote
			else {
				tokenset(t = tinit, rest)
				trest = tokengetall(t)'
				// If the quote is balanced...
				if (max = specialexp_max_balanced(trest)) {
					plen = sum(strlen(trest[|1 \ max|]))

					// Precede left single quotes by the \ escape character.
					trest = (trest :== "`") :* "\" :+ trest

					str = ""
					for (i = 1; i <= max; i++) {
						str = str + trest[i]
					}

					// If the element contains a problematically unbalanced left
					// single quote and str contains a double quote, start a new
					// element.
					strdq = strpos(str, `"""')
					if (unballsq[len] & strdq) {
						els = els, str
						unballsq = unballsq, 0
						len++
						dq = strdq
					}
					else {
						els[len] = els[len] + str
						dq = dq | strdq
					}
				}
				// If the quote is unbalanced...
				else {
					// If the quote is problematically unbalanced and the
					// element contains a double quote, start a new element.
					prob = anyof(("`", `"""', ""), substr(rest, 2, 1))
					if (dq & prob) {
						els = els, "\\`"
						unballsq = unballsq, 0
						len++
						dq = 0
					}
					else
						els[len] = els[len] + "\\`"
					unballsq[len] = unballsq[len] | prob
					plen = 1

					// If it is an unbalanced open compound double quote, the
					// -c == `"""'- case above will address the ".
				}
			}

			rest = substr(rest, plen + 1, .)
		}
	}

	/* Left single quotes need to be preceded by the \ escape character unless
	they are at the end of a string. Within a single string of the
	-specialexp()- expression, the \ is unnecessary for unbalanced left single
	quotes: "`x" is the same as "\`x". However, it is necessary across strings:
	for `\\', -specialexp()- should return "\`\" + "\'", not "`\" + "\'". The
	exception to this is a left single quote at the end of a string: for `"',
	"`" + `"""' + "'" is the same as "\`" + `"""' + "'". Similar rules hold for
	$. */
	traillsq = substr(els, -2, .) :== "\\`"
	els = !traillsq :* els + traillsq :* (substr(els, 1, strlen(els) :- 2) :+ "`")

	return(els)
}

`SS' function specialexp(`SS' s, |`RS' nstrs)
{
	// "els" suffix for "elements": "nels" for "number of elements."
	`RS' nels, i
	// "escliteral" for "escape literal";
	// "unballsq" for "(problematically) unbalanced left single quote";
	// "prob" for "problematic."
	`RR' otherliteral, escliteral, literal, unballsq, prob, match
	`SR' otherels, escels, split, els

	if (strpos(s, char(0))) {
		errprintf("s cannot contain binary 0\n")
		exit(198)
		/*NOTREACHED*/
	}

	if (s == "") {
		nstrs = 1
		return(`""""')
	}

	// ASCII characters 1-31, 127, and 255
	pragma unset otherels
	pragma unset otherliteral
	specialexp_other(s, otherels, otherliteral)

	// \ escape character
	escels = J(1, 0, "")
	escliteral = J(1, 0, .)
	nels = length(otherels)
	for (i = 1; i <= nels; i++) {
		if (otherliteral[i]) {
			split = specialexp_escape(otherels[i])
			escels = escels, split
			escliteral = escliteral, J(1, length(split), 1)
		}
		else {
			escels = escels, otherels[i]
			escliteral = escliteral, 0
		}
	}

	// Single and double quotes
	els = J(1, 0, "")
	literal = unballsq = J(1, 0, .)
	nels = length(escels)
	pragma unset prob
	for (i = 1; i <= nels; i++) {
		if (escliteral[i]) {
			split = specialexp_quotes(escels[i], prob)
			els = els, split
			literal = literal, J(1, length(split), 1)
			unballsq = unballsq, prob
		}
		else {
			els = els, escels[i]
			literal = literal, 0
			unballsq = unballsq, 0
		}
	}

	// Precede $ by the escape character \ unless it is at the end of an
	// element. (See -specialexp_quotes()- for an explanation of when left
	// single quotes and $ need the \.)
	els = subinstr(els, "$", "\\$", .)
	match = substr(els, -2, .) :== "\\$"
	els = !match :* els + match :* (substr(els, 1, strlen(els) :- 2) :+ "$")

	/* If an element ends in the escape character \ and (1) the next element is
	a left single quote and the current element does not contain a double quote,
	or (2) the next element is $, or (3) the next element starts with an open
	compound double quote and the current element does not contain a
	problematically unbalanced left single quote, add an extra \ to the current
	element and concatenate it with the next one. */
	nels = length(els)
	for (i = 1; i <= nels - 1; i++) {
		if (substr(els[i], -1, 1) == "\" &
			(els[i + 1] == "`" & !strpos(els[i], `"""') |
			els[i + 1] == "$" |
			substr(els[i + 1], 1, 2) == `ocq' & !unballsq[i])
		) {
			els[i] = els[i] + "\" + els[i + 1]
			els[i + 1] = ""
			i++
		}
	}
	literal = select(literal, els :!= "")
	els = select(els, els :!= "")

	// Adorn els in double quotes.
	match = strpos(els, `"""') :!= 0
	els = literal :* (match :* "`" :+ `"""') :+
		els :+
		literal :* (`"""' :+ match :* "'")

	nstrs = length(els)
	return(invtokens(els, " + "))
}

end
