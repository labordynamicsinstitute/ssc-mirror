import sys																							# used to pull in arguments passed to Python from Stata
import itertools as it																				# key module used for collecting all combinations
import sfi																							# Stata function interface
import re																							# regular expression module

count = 0																							# initialize count of tuples

tuple_args = sys.argv[7:sys.argv.__len__()] 														# separate all pieces to be used in combination generation for tuples


# check whether numeric list references are in the range 0<#<n
# n := lenght of tuples list
# Note: tuples.ado asserts that only " 0123456789()!&|" are used
def check_conditionals(condits, max_val):
	tokens_condits = condits.split(" ")
	for cs in tokens_condits:
		if not conditional_statement_OK(cs, max_val) == True:
			sfi.SFIToolkit.errprintln("option conditionals() invalid")
			sfi.SFIToolkit.errprintln("Statement '" + cs + "' contains an illiegal list element reference.")
			sfi.SFIToolkit.exit(198)

def conditional_statement_OK(cs, max_val):
	cs_vals = list(map(int, re.findall("[0-9]+", cs)))
	max_cs_vals = max(cs_vals)
	min_cs_vals = min(cs_vals)
	if max_cs_vals > max_val or min_cs_vals < 1:
		return(False)
	else:
		return(True)


def parse_conditionals(condits):																	# function to reproduce behavior of conditionals() in Mata
	py_condits = condits.split(" ")							# split the conditionals string
	py_condits = ["(" + condit for condit in py_condits]	# remove right parens
	py_condits = [condit + ")" for condit in py_condits]	# remove left parens
	py_condits = " and ".join(py_condits)					# combine all statements with "and"s
	py_condits = re.sub("\!", " not ", py_condits)			# change to python "not"
	py_condits = re.sub("\|", " or ", py_condits)			# change to python "or"
	py_condits = re.sub("\&", " and ", py_condits)			# change to python "and"
	for arg in range(0, tuple_args.__len__()):														# loop over all elements of tuple_args (the elements of the list from which to create tuples) function...
		py_condits = re.sub('(?<![0-9])'+str(arg+1)+'(?![0-9])', chr(34) + tuple_args[arg] + chr(34)  +						# ... because the conditionals are represented as numbers (needed to be to work in Mata), they are replaced with their names here in Python - this loop does so and adds "in tupl" to make the filter + lambda function in line 33 work
		" in tupl " , py_condits)
		
	return(py_condits)																				# return the formatted conditionals


if sys.argv[3].__len__() > 0: 
	check_conditionals(sys.argv[3], tuple_args.__len__())
	py_condits = parse_conditionals(sys.argv[3])													# invoke the parse_conditionals() function on the conditional statements to format them for removal in the main loop below
	
for n_combs in range(int(sys.argv[1]), int(sys.argv[2])+1):											# loop computing combinations by looping over numbers of elements in a combination ...

	tuplelist = list(it.combinations(tuple_args, n_combs))
	
	if sys.argv[4] not in ['nosort']: tuplelist.reverse()
	
	if sys.argv[3].__len__() > 0:
		exec("tuplelist = list(filter(lambda tupl: " + py_condits + ", tuplelist))")
	
	for tuple_comb in range(0, tuplelist.__len__()):
		
		count = count + 1
		
		sfi.SFIToolkit.stata("c_local " + sys.argv[6] + str(count) + chr(32) + chr(96) + chr(34) + chr(32).join(tuplelist[tuple_comb]) + chr(34) + chr(39) )
		
		if sys.argv[5].__len__() > 0: 
			sfi.SFIToolkit.displayln("{res}" + sys.argv[6] + str(count) + ": {txt}" + " ".join(tuplelist[tuple_comb]))

sfi.SFIToolkit.stata("c_local " + 'n'+sys.argv[6]+'s' + " " + str(count) )									# return number of "ntuples" macro
