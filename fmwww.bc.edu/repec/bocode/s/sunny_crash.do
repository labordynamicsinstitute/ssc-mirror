cd "E:\益友学术\鼎园会计142期\report"

cap mkdir "E:/益友学术/鼎园会计142期/report/result/"
crash using returns.xlsx, savepath(./result/)

cap mkdir "E:/益友学术/鼎园会计142期/report/results/"
crash using returns.xlsx, savepath(./results/) sheetnames(Sheet1 Sheet2 Sheet3 Sheet4 Market) minweeks(40) clear

cap mkdir "E:/益友学术/鼎园会计142期/report/results2/"
cd "E:\益友学术\鼎园会计142期\report\results2"
crash using returns.xlsx, savepath(./results2/) sheetnames(Individual Market)

