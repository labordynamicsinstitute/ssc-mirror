*! version 1.0.1  31dec2020
program def pyconvertu
	version 16.0
	/*
		By default, this small program converts country names (in English) to
		ISO 3166-1 codes (alpha-2, alpha-3, and numeric) and to full names
		in English and French using regular expressions with Unicode support.
		The from() option allows the user to import an external JSON file as
		a dictionary to replace the default classification.
		The template JSON file structure is the following ("regex" is a
		compulsory key and saving using Python's json.dump() is recommended):
		[
			{
				"regex":"^(.*afgh.*|\\s*AFG\\s*|\\s*AF\\s*|\\s*4\\s*)$",
				"name_en":"Afghanistan",        # classification A
				"name_fr":"Afghanistan (l')",   # classification B
				"iso3":"AFG",                   # ...
				"iso2":"AF",
				"isoN":"4"
			},
			...
		]
		Author: Ilya Bolotov, MBA, Ph.D.
		Date: 31 December 2020
	*/
	syntax 																	///
	name(name=name) [, to(string) Generate(string) replace print]			///
	[from(string) *]
	tempvar converted
	// import classification
	if `"`from'"' == "" {
		qui findfile `"pyconvertu_classification.json"'
		local from `"`r(fn)'"'
	}
	// convert the variable to classification
	cap confirm variable `name'
	if ! _rc {
		/* check options for errors */
		if `"`to'"' == "" {					// check for missing options
			di as err "option to() required"
			exit 198
		}
		if `"`replace'`generate'`print'"' == "" {
			di as err "must specify either generate, replace or print option"
			exit 198
		}
		/* ado + python */
		python: l = _pyconvertu(r'`from'', Data.get('`name''), '`to'')
		if `"`print'"' == "" {				// store the converted variable
			g `converted' = ""
			python: Data.store('`converted'', None, l)
			if `"`generate'"'  != "" {		// generate a new variable
				g `generate' = `converted'
			}
			if `"`replace'"'   != "" {		// replace the existing one
				replace `name' = `converted'
			}
		}
		else {								// print only
			python: print('`"' + '""'.join(l).replace('""', '"\', `"') + '"\'')
		}
		exit 0
	}
	// save classification into a variable
	if `"`name'"' == "__classification" {
		/* check options for errors */
		if `"`to'"' == "" {
			di as err "option to() required"
			exit 198
		}
		if `"`generate'`print'"' == "" {
			di as err "must specify either generate or print option"
			exit 198
		}
		/* ado + python */
		python: l = _pyconvertu_list(r'`from'', '`to'')
		python: n = len(l) - Data.getObsTotal()
		if `"`print'"' == "" {				// store the classification
			g `converted' = ""
			python: Data.addObs((lambda n: n if n > 0 else 0)(n))
			python: Data.store('`converted'', [i for i in range(0, len(l))], l)
			if `"`generate'"' != "" {		// generate a new variable
				g `generate' = `converted'
			}
		}
		else {								// print only
			python: print('\`"' + '"\' \`"'.join(l) + '"\'')
		}
		exit 0
	}
	// print metadata and sources
	if `"`name'"' == "__info" {
		python: l = _pyconvertu_info(r'`from'')
		python: print(f'\n'.join(l))
		exit 0
	}
	// or display error
	di as err "must specify either a variable, __classification or __info"
	exit 198
end

* Python 3 code ***********
python:
# Stata Function Interface
from sfi import Data

# Python Modules
import json
import re

# User-defined Functions
def _pyconvertu(
	source_file=r'', from_list=[], to_classification='', *args, **kwargs
):
	"""
	/*
		Converts a list of strings (from_list) to classification
		(to_classification) based on a JSON file (source_file),
		unmatched strings are returned unchanged.
	*/
	"""
	try:
		#// load classification
		with open(source_file) as f:
			classification = list(filter(
				lambda d: not d.get('metadata') and not d.get('sources'),
				json.load(f)
			))
		#// convert list
		return list(map(
			lambda s:
				(lambda l, s: 
					l[1].get(to_classification) if len(l) > 1 else l[0]
				)(
					[s] + list(filter(
						lambda d: re.search(
							r'' + d.get('regex') + r'', s, flags=re.I|re.M
						),
						classification
					)),
					str(s)
				),
			from_list
		))
	except:
		return {}

def _pyconvertu_list(
	source_file=r'', from_classification='', *args, **kwargs
):
	"""
	/*
		Creates a list of strings from classification
		(from_classification) based on a JSON file (source_file).
	*/
	"""
	try:
		#// load classification
		with open(source_file) as f:
			classification = list(filter(
				lambda d: not d.get('metadata') and not d.get('sources'),
				json.load(f)
			))
		#// create list
		return list(map(
			lambda d: d.get(from_classification),
			classification
		))
	except:
		return {}

def _pyconvertu_info(
	source_file=r'', *args, **kwargs
):
	"""
	/*
		Returns a list based on a JSON file (source_file).
	*/
	"""
	try:
		#// load classification metadata
		with open(source_file) as f:
			metadata = list(filter(
				lambda d: d.get('metadata') or d.get('sources'),
				json.load(f)
			))
		#// create list
		return list(map(
			lambda d: str(d),
			metadata
		))
	except:
		return {}

end
