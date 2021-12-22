from sfi import Macro, Scalar
def calcsum(num1, num2):
	res = num1 + num2
	Scalar.setValue("result", res)
pya = int(Macro.getLocal("a"))
pyb = int(Macro.getLocal("b"))
calcsum(pya, pyb)
