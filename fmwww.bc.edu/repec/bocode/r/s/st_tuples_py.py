"""Implement Stata/Mata -tuples- in Python.

This script is supposed to be called by tuples.ado.

version 2.0.0 09aug2021 Joseph N. Luchman & daniel klein
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
    """Create the tuples and set the respective locals in Stata."""
    if len(conditionals) > 0:
        # conditionals are implemented in terms of positional arguments.
        # We enumerate the items in the list (anything) and later use the 
        # resulting numeric tuples as indices for the original list items.
        conditionals = rpn_to_infix(conditionals)
        anything_cpy = anything.copy()
        anything = list(range(len(anything)))
    
    count = 0
    for r in range(min, max+1):
        tuples = list(combinations(anything, r))
        
        if len(conditionals) > 0:
            tuples = eval("[tuple for tuple in tuples if "+conditionals+"]")
            
        if sort:
            tuples.reverse()
            
        for tuple in tuples:
            
            if len(conditionals) > 0:
                tuple = [anything_cpy[t] for t in tuple]
                
            count+=1
            mac_name = lmacname+str(count)
            mac_str  = " ".join(tuple)
            st_c_local(mac_name, mac_str)
            
            if display:
                Stata.displayln("{res}" + mac_name + ": {txt}" + mac_str)
        
    st_c_local("n"+lmacname+"s", str(count))


def st_c_local(mac_name, mac_str):
    """Mimic Stata's -c_local-."""
    # We use (extended) Macro functions to deal with awkward nested
    # double and single quotes in the tuples.  We use an awkward name 
    # for the local that we set in tuples.ado to avoid name conflicts.
    Macro.setLocal("t_u_p_l_e", mac_str)
    Stata.stata("c_local " + mac_name + " : copy local t_u_p_l_e")


def rpn_to_infix(conditionals):
    """Built logical statement to select the tuples.
    
    Input:
    string, -tuples- option -conditionals() ,
    space separated, reverse polish notation, checked for errors
    
    Return:
    string, logical statement in terms of tuple
    e.g., (4 in tuple & 2 in tuple)
    """
    stack = []
    for el in conditionals.split():
        if el.isnumeric():
            # Python indices run from 0 to n-1
            stack.append(str(int(el)-1)+" in tuple")
        elif el == "&":
            stack.append(pop_append(stack, "and"))
        elif el == "|":
            stack.append(pop_append(stack, "or"))
        elif el == "!":
            stack.append("(not "+stack.pop()+")")
        else:
            Stata.errprintln("unexpected error in st_tuples_py")
            Stata.exit(499)
    return "".join(stack)


def pop_append(stack, op):
    return "("+stack.pop(-2)+" "+op+" "+stack.pop(-1)+")"


# This is the entry point for -tuples.ado- to this Python script.
# We implement this as a script to avoid parsing awkward nested 
# double and single quotes in the supplied arguments.
st_tuples(
    int(sys.argv[1]),           # min
    int(sys.argv[2]),           # max
    sys.argv[3],                # conditionals
    sys.argv[4] == "display",   
    sys.argv[5] != "nosort",
    sys.argv[6],                # lmacname
    sys.argv[7:len(sys.argv)]   # anything
    )
