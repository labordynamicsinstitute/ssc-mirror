"""Implement Stata/Mata -tuples- in Python.

This Python script is called by tuples.ado.

*! version 2.2.0  25sep2025
"""
import sys
from itertools import combinations 
from sfi       import Macro
from sfi       import SFIToolkit as Stata


def st_tuples(
        min,
        max,
        conditionals,
        display,
        sort,
        lmacname,
        anything
        ):
    """Select tuples and define local macros in Stata."""
    if bool(conditionals):
        conditionals_tokens = conditionals.split()
        # We enumerate the list items in anything to create numeric tuples.
        # We later use these tuples as indices into the original list items.
        anything_cc = anything.copy()
        anything = list(range(len(anything)))
        
    count = 0
    for r in range(min, max+1):
        tuples = list(combinations(anything, r))
        
        if bool(conditionals):
            tuples = [
                tuple for tuple in tuples 
                if satisfies_conditionals(tuple, conditionals_tokens)
            ]
            
        if bool(sort):
            tuples.reverse()
            
        for tuple in tuples:
            
            if bool(conditionals):
                tuple = [anything_cc[t] for t in tuple]
                
            count+=1
            macro_name = lmacname+str(count)
            macro_contents = " ".join(tuple)
            st_c_local(macro_name, macro_contents)
            
            if bool(display):
                Stata.displayln("{res}" + macro_name + ": {txt}" + macro_contents)
            
            Stata.pollstd()
        
    st_c_local("n"+lmacname+"s", str(count))


def st_c_local(macro_name, macro_contents):
    """Mimic Stata's non-documented -c_local- command."""
    Macro.setLocal("tuple_py", macro_contents)
    Stata.stata("c_local " + macro_name + " : copy local tuple_py")


def satisfies_conditionals(tuple, conditionals_tokens):
    """Evaluate postfix (Reverse Polish Notation) conditionals for a tuple."""
    stack = []
    for token in conditionals_tokens:
        if token.isnumeric():
            stack.append(int(token)-1 in tuple) # Python indices run from 0 to n-1
        elif token == "&":
            second_last, last = stack.pop(), stack.pop()
            stack.append(second_last and last)
        elif token == "|":
            second_last, last = stack.pop(), stack.pop()
            stack.append(second_last or last)
        elif token == "!":
            stack.append(not stack.pop())
        else:
            Stata.errprintln("unexpected error in st_tuples_py")
            Stata.exit(499)
    return stack.pop()


# Entry point for tuples.ado
st_tuples(
    int(sys.argv[1]),               # min
    int(sys.argv[2]),               # max
    Macro.getLocal(sys.argv[3]),    # conditionals; postfix notation
    sys.argv[4] == "display",   
    sys.argv[5] != "nosort",
    sys.argv[6],                    # lmacname
    sys.argv[7:len(sys.argv)]       # anything
    )
