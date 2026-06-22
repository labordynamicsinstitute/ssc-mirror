# -*- coding: utf-8 -*-
#******************************************************************************
#   Name of the program: PyTIVIPNC.py
#   Title of the program: Python Module for Transforming an Integrated Variable
#   with and without Deterministic Trend parts into Positive and Negative Components
#   Version: 01
# 
#   This program is released under GNU General Public License, version 3.
# 
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
# 
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
# 
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
#   This software has been developed by Dr. Alan Mustafa under supervision of 
#   Prof. Abdulnasser Hatemi-J.
#   Contacts:
#    - Prof. Abdulnasser Hatemi-J: AHatemi@uaeu.ac.ae
#    - Dr. Alan Mustafa: Alan.Mustafa@ieee.org
#
#   
#   In case this module is used it needs to be cited as the following:
#   Mustafa A. and Hatemi-J A. (2026) PyTIVIPNC: Python Module for Transforming an Integrated
#   Variable with and without Deterministic Trend parts into Positive and Negative Components
#   Statistical Software Components, Boston College Department of Economics
# 
#   Date: June 2026
#
#   © 2026 Dr. Alan Mustafa and Prof. Abdulnasser Hatemi-J
# 
#******************************************************************************
#!/usr/bin/env python3

from __future__ import annotations
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import os
from datetime import datetime
#######################################
import tkinter as tk
from tkinter.filedialog import askopenfilename
from tabulate import tabulate
import matplotlib.pyplot as plt

###############################################################################
#                         Start of GUI
###############################################################################

#========================= functions =========================================

class create_window_menu_UI2(tk.Frame):
    def __init__(self, master):
        tk.Frame.__init__(self, master)
        self.master = master
        #============= Application Title --------------------------------------
        self.lblTitle = tk.Label(self, text="Transforming a Variable into Cumulative Partial Sums for Positive and Negative Components", font=("Helvetica", 14))
        self.lblTitle.grid(row=1, column=0, columnspan=5, sticky="EW")        
        
        hr = tk.Frame(self,height=3,width=850,bg="green")
        hr.grid(row=2, column=0, columnspan=5, sticky="NWNESWSE")

        
        #============= Adding a Blank Row -------------------------------------
        self.lblBlnkRow = tk.Label(self, text="", font=("Helvetica", 12))
        self.lblBlnkRow.grid(row=16, column=0, sticky="EW")

        #============= Load My Data Button ---------------------------------
        self.btnSelectDataFile = tk.Button(self, text="Select the Dataset File", command=lambda: [var_DatasetFile.set(os.path.split(askopenfilename())[1]),activateBtnCalcPD(self)], font=("Arial", 12), state='normal')
        self.btnSelectDataFile.grid(row=20, column=0, sticky="E")

        var_DatasetFile = tk.StringVar()
        self.tbx_DatasetFile = tk.Entry(self, textvariable=var_DatasetFile, font=("Helvetica", 10), state="disabled", justify="center")
        self.tbx_DatasetFile.grid(row=20, column=1, sticky="EW")

        #============= Adding a label for OR sign -----------------------------
        self.btnLoadMydata = tk.Label(self, text="OR ", font=("Arial Narrow", 12))
        self.btnLoadMydata.grid(row=20, column=2, sticky="EW")

        #============= Load Sample Data Button --------------------------------
        self.btnLoadSmplData = tk.Button(self, text="Load the Sample Data \nand Transform Data", command=lambda:[loadSampleData(driftTrend,self),disableBtnSelectDataFile(self),showInfoOnSampleData()], font=("Arial", 12), state="normal")
        self.btnLoadSmplData.grid(row=20, column=3, rowspan=2, sticky="WE")
        
        #============= Select the Transformational Options ---------------
        self.btnLoadMydata = tk.Label(self, text="Select the Transformational Options:", font=("Arial", 12))
        self.btnLoadMydata.grid(row=30, column=0, sticky="EW")
        
        # List of options:
            # 1. No_Drift_No_Trend: No Drift with No Trend
            # 2. Drift_No_Trend:       Drift with No Trend
            # 3. Drift_Trend:          Drift with    Trend
    
        driftTrend = tk.IntVar(self, value=3, name=None)    # variable to format the number of decimals of the outputing reports
        self.radio_No_Drift_No_Trend = tk.Radiobutton(self, text="No Drift with No Trend", variable=driftTrend, value=1, font=("Arial", 12))
        self.radio_No_Drift_No_Trend.grid(row=30, column=1, sticky="W")
        self.radio_Drift_No_Trend = tk.Radiobutton(self, text="Drift with No Trend", variable=driftTrend, value=2, font=("Arial", 12))
        self.radio_Drift_No_Trend.grid(row=31, column=1, sticky="W")
        self.radio_Drift_Trend = tk.Radiobutton(self, text="Drift with Trend", variable=driftTrend, value=3, font=("Arial", 12))
        self.radio_Drift_Trend.grid(row=32, column=1, sticky="W")
        
        vr = tk.Frame(self,height=10,width=1,bg="green")
        vr.grid(row=30, column=2, rowspan=30, sticky="NS")
        
        #============= Calculate Proftfolio Diversification Button ------------command=lambda:[funct1(),funct2()]
        self.btnCalcTDICPS = tk.Button(self, text="Transform Data", command=lambda:[indicatorActive(self),LoadDataFile(var_DatasetFile,driftTrend,self),indicatorEnd(self)], font=("Arial", 12), state="disable")
        self.btnCalcTDICPS.grid(row=51, column=0, sticky="E")
        
        #============= Data Processing Indicator ------------------------------
        self.lblIndicator = tk.Label(self, text=chr(9608), font=("Arial Narrow", 12), fg='#eee')
        self.lblIndicator.grid(row=51, column=1, sticky="WE")
        
        #============= Dataset File Selection ---------------------------------
        self.btnExit = tk.Button(self, text="    Close    ", command=self.master.destroy, font=("Arial", 12))
        self.btnExit.grid(row=51, column=3, sticky="WE")

        #============= Blankrow -----------------------------------------------
        self.lblBlankRow = tk.Label(self, text=" ", font=("Arial Narrow", 8))
        self.lblBlankRow.grid(row=55, column=0, columnspan=3, sticky="WE")
  
        #============= Output EndNote         ---------------------------------
        hr = tk.Frame(self,height=1,width=850,bg="green")
        hr.grid(row=60, column=0, columnspan=4, sticky="NWNESWSE")


        #============= Start Printing Intercept and Slope values ---------------
        self.lblPrint_Intercept_Slope = tk.Label(self, text=chr(9608), font=("Arial Narrow", 12), fg='#eee')
        self.lblPrint_Intercept_Slope.grid(row=70, column=1, sticky="WE")
        
        #=============  End Printing Intercept and Slope values ---------------
        
        #============= Output EndNote         ---------------------------------
        hr = tk.Frame(self,height=1,width=850,bg="green")
        hr.grid(row=200, column=0, columnspan=4, sticky="NWNESWSE")

        self.msgEndNote = tk.Message(self, text="", font=("Helvetica", 8, "italic"), anchor="w", justify="left", bg="#d4d4d4")
        self.msgEndNote.bind("<Configure>", lambda e: self.msgEndNote.configure(width=e.width-10))
        self.msgEndNote.grid(row=210, column=0, columnspan=4, sticky="ew")
        
###############################################################################
#                           End of GUI                                        #
###############################################################################

###############################################################################
##################      START OF SAMPLE DATA    ###############################
###############################################################################

def loadSampleData(driftTrend_,self):
    
    headers=["Date_of_Assets","USD-JPY","Brent Oil","DAX","Dow Jones"]

    dates = ['02/01/2019', '03/01/2019', '04/01/2019', '07/01/2019', '08/01/2019', '09/01/2019', '10/01/2019', '11/01/2019', '14/01/2019', '15/01/2019', '16/01/2019',
             '17/01/2019', '18/01/2019', '21/01/2019', '22/01/2019', '23/01/2019', '24/01/2019', '25/01/2019', '28/01/2019', '29/01/2019', '30/01/2019', '31/01/2019',
             '01/02/2019', '04/02/2019', '05/02/2019', '06/02/2019', '07/02/2019', '08/02/2019', '11/02/2019', '12/02/2019', '13/02/2019', '14/02/2019', '15/02/2019',
             '18/02/2019', '19/02/2019', '20/02/2019', '21/02/2019', '22/02/2019', '25/02/2019', '26/02/2019', '27/02/2019', '28/02/2019', '01/03/2019', '04/03/2019',
             '05/03/2019', '06/03/2019', '07/03/2019', '08/03/2019', '11/03/2019', '12/03/2019', '13/03/2019', '14/03/2019', '15/03/2019', '18/03/2019', '19/03/2019',
             '20/03/2019', '21/03/2019', '22/03/2019', '25/03/2019', '26/03/2019', '27/03/2019', '28/03/2019', '29/03/2019']

    asset1 = [108.88, 107.67, 108.53, 108.72, 108.75, 108.17, 108.42, 108.55, 108.17, 108.67, 109.09, 109.24, 109.78, 109.67, 109.38, 109.6, 109.64, 109.55, 109.36,
    109.39, 109.03, 108.88, 109.5, 109.89, 109.97, 109.97, 109.81, 109.73, 110.38, 110.48, 111, 110.48, 110.5, 110.62, 110.62, 110.86, 110.7, 110.69, 111.06, 110.58,
    111, 111.39, 111.92, 111.75, 111.89, 111.77, 111.59, 111.17, 111.2, 111.36, 111.17, 111.72, 111.47, 111.42, 111.39, 110.69, 110.81, 109.92, 109.97, 110.64, 110.52,
    110.64, 110.86]
    
    asset2 = [54.91, 55.95, 57.06, 57.33, 58.72, 61.44, 61.68, 60.48, 58.99, 60.64, 61.32, 61.18, 62.7, 62.74, 61.5, 61.14, 61.09, 61.64, 59.93, 61.32, 61.65, 61.89,
    62.75, 62.51, 61.98, 62.69, 61.63, 62.1, 61.51, 62.42, 63.61, 64.57, 66.25, 66.5, 66.45, 67.08, 67.07, 67.12, 64.76, 65.21, 66.39, 66.03, 65.07, 65.67, 65.86, 65.99,
    66.3, 65.74, 66.58, 66.67, 67.55, 67.23, 67.16, 67.54, 67.61, 68.5, 67.86, 67.03, 67.21, 67.97, 67.83, 67.82, 68.39]
    
    asset3 = [10580.19, 10416.66, 10767.69, 10747.81, 10803.98, 10893.32, 10921.59, 10887.46, 10855.91, 10891.79, 10931.24, 10918.62, 11205.54, 11136.2, 11090.11,
    11071.54, 11130.18, 11281.79, 11210.31, 11218.83, 11181.66, 11173.1, 11180.66, 11176.58, 11367.98, 11324.72, 11022.02, 10906.78, 11014.59, 11126.08, 11167.22, 11089.79,
    11299.8, 11299.2, 11309.21, 11401.97, 11423.28, 11457.7, 11505.39, 11540.79, 11487.33, 11515.64, 11601.68, 11592.66, 11620.74, 11587.63, 11517.8, 11457.84, 11543.48,
    11524.17, 11572.41, 11587.47, 11685.69, 11657.06, 11788.41, 11603.89, 11549.96, 11364.17, 11346.65, 11419.48, 11419.04, 11428.16, 11526.04]
    
    asset4 = [23346.24, 22686.22, 23433.16, 23531.35, 23787.45, 23879.12, 24001.92, 23995.95, 23909.84, 24065.59, 24207.16, 24370.1, 24706.35, 24706.35, 24404.48,
    24575.62, 24553.24, 24737.2, 24528.22, 24579.96, 25014.86, 24999.67, 25063.89, 25239.37, 25411.52, 25390.3, 25169.53, 25106.33, 25053.11, 25425.76, 25543.27, 25439.39,
    25883.25, 25883.25, 25891.32, 25954.44, 25850.63, 26031.81, 26091.95, 26057.98, 25985.16, 25916, 26026.32, 25819.65, 25806.63, 25673.46, 25473.23, 25450.24, 25650.88,
    25554.66, 25702.89, 25709.94, 25848.87, 25914.1, 25887.38, 25745.67, 25962.51, 25502.32, 25516.83, 25657.73, 25625.59, 25717.46, 25928.68]
    
    csvFileName = 'PyTIVIPNC_SampleData.csv' # PD: Portfolio Diversification

    df = pd.DataFrame(dates)
    df['Asset1'] = asset1
    df['Asset2'] = asset2
    df['Asset3'] = asset3
    df['Asset4'] = asset4
    
    df.columns = headers
    df.to_csv(csvFileName, header=True, index=False)
    
    #-----------------------------------------
    #driftTrend = 3;
    driftTrend = driftTrend_.get()
    assetName = 'Asset1'
    theDataSet = asset1
    
    Transformation_context(assetName,theDataSet,driftTrend,self)

###############################################################################
##################      END SAMPLE DATA      ##################################
###############################################################################

###############################################################################
##################      START OF LOADING DATA FILE       ######################
###############################################################################

def LoadDataFile(fileName,driftTrend_,self):
    driftTrend = driftTrend_.get()
    
    theFile = pd.read_csv(fileName.get(), sep = ',', decimal = ',', header=0, index_col=False)
    df2 = pd.DataFrame(theFile)
    headers_list = list(df2.columns.values)
    
    assetName = headers_list[0]
    
    for column in headers_list[1:]:
        df2[column] = df2[column].astype(np.float64)
    
    theDataSet = df2
    
    Transformation_context(assetName,theDataSet,driftTrend,self)

###############################################################################
##################       END OF LOADING DATA FILE          ####################
###############################################################################


###############################################################################
#       Start of Calculations: Tranformation Context                          #
###############################################################################
def Transformation_context(assetName,theDataSet,driftTrend,self):

    print("--------------------------")    
    print("Name of the asset: " + str(assetName))
    print("File name: " + str(rprtsFileName(assetName)))
    print("--------------------------")    

    result, slope_value, intercept_value = tivipnc_transform(theDataSet,driftTrend)

    #result.columns = ['Asset1+', 'Asset1-']
    assetName_plus = str(assetName) + "+"
    assetName_minus = str(assetName) + "-"

    result = pd.DataFrame(result, columns=[assetName_plus, assetName_minus])
    
    theFilePath, theRprtFldrName = create_rprt_file(assetName,result,slope_value,intercept_value,self)

    EndNote(theFilePath,self)
    
    result_plus  = result.iloc[:, 0]   # first column
    result_minus = result.iloc[:, 1]   # second column

    #-----------------   START: Generate Results -> Dataset files   ---------------------------------
    # Print the result in a csv file format.
    createCsvFile(assetName_plus,result_plus,theRprtFldrName) # asset as filename
    createCsvFile(assetName_minus,result_minus,theRprtFldrName) # asset as filename
    
    # Print the result in a txt file format.
    createTxtFile(assetName_plus,result_plus,theRprtFldrName)  # asset as filename
    createTxtFile(assetName_minus,result_minus,theRprtFldrName)  # asset as filename
    
    #-----------------    END: Generate Results -> Dataset files    ---------------------------------
    
    #-----------------   START: Generate Graphs for Results     ---------------------------------
    # 1. Graphs for original Dataset
    # 2. Graph for Result+
    # 3. Graph for Result-
    
    datasets = {
        assetName: result,
        assetName_plus: result_plus,
        assetName_minus: result_minus
    }
    
    for name, data in datasets.items():
        save_plot(name, data, theRprtFldrName)
    
    #-----------------    END:  Generate Graphs for Results     ---------------------------------
    
    return
###############################################################################
#         End of Calculations: Tranformation Context                          #
###############################################################################


###############################################################################
#       Start of Calculations: TIVIPNC                                        #
###############################################################################

def tivipnc_transform(y: np.ndarray, driftTrend: int) -> tuple[np.ndarray, float, int]:
    
    y = np.asarray(y, dtype=float).reshape(-1)

    dy = np.diff(y)   # length = m-1
    t = np.arange(1, len(dy) + 1, dtype=float)
    slope_value, intercept_value = np.polyfit(t, dy, 1)

    print("slope_value: ",slope_value)
    print("intercept_value: ",intercept_value)
    #print("driftTrend: ",driftTrend)
    print("======================")
   
    # Regression residuals
    #e_value = dy - intercept_value - slope_value * X
    
    match driftTrend:
        case 1:
            print("1. No Drift with No Trend")
            drift = 0;
            trend = 0;
        case 2:
            print("2. Drift with No Trend")
            drift = 1;
            trend = 0;
        case _:
            print("3. Drift with Trend")
            drift = 1;
            trend = 1;
    
    # Residuals
    e_value = dy - (drift * intercept_value) - (trend * slope_value * t)
    
    #print("======================")
    #print("e_value: ",e_value)
    #print("======================")
 
    # Positive and negative residual components
    e_plus = np.where(e_value > 0, e_value, 0.0)
    e_minus = np.where(e_value < 0, e_value, 0.0)

    # Cumulative partial sums
    S_e_plus = np.cumsum(e_plus)
    S_e_minus = np.cumsum(e_minus)

    y0 = float(y[0])

    deterministic_component = (
        intercept_value * t
        + slope_value * t * (t + 1.0) / 2.0
        + y0
    ) / 2.0

    y_plus = deterministic_component + S_e_plus
    y_minus = deterministic_component + S_e_minus

    y_plus_and_y_minus = np.column_stack((y_plus, y_minus))

    return y_plus_and_y_minus, slope_value, intercept_value

###############################################################################
#        End of Calculations: TIVIPNC                                         #
###############################################################################

################################################
def create_rprt_file(assetName,result,slope_value,intercept_value,self):    # result: New DataFrame
   
    theRprtFldrName = rprtsFldrName(assetName)
    theRprtFileName = rprtsFileName(assetName)

    # create folder 
    file_path = os.path.join(theRprtFldrName, theRprtFileName)
    output_rprt_file = open(file_path,'w')

    output_rprt_file.write('#############################################################################\n')
    output_rprt_file.write('#                                                                           #\n')
    output_rprt_file.write('#            TRANSFORMED INTEGRATED VARIABLE INTO CUMULATIVE                #\n')
    output_rprt_file.write('#           PARTIAL SUMS FOR POSITIVE AND NEGATIVE COMPONENTS               #\n')
    output_rprt_file.write('#                                                                           #\n')
    output_rprt_file.write('#############################################################################\n')
    output_rprt_file.write("slope_value = " + str(slope_value) + "\n")
    output_rprt_file.write("intercept_value = " + str(intercept_value) + "\n")
    output_rprt_file.write('-----------------------------------------------------------------------------\n')
    output_rprt_file.write(tabulate(result, headers='keys'))
    output_rprt_file.write('\n')

    output_rprt_file.close
    return(file_path,theRprtFldrName)

################################################
def EndNote(file_path,self):
    
    output_rprt_file = open(file_path,'a');

    output_rprt_file.write('\n');
    output_rprt_file.write('===============================================================================\n');
    output_rprt_file.write('|                                  REFERENCES                                 |\n');
    output_rprt_file.write('| - Hatemi-J A. (2012) Asymmetric causality tests with an application,        |\n');
    output_rprt_file.write('| Empirical Economics, vol. 43(1), 447-456.                                   |\n');
    output_rprt_file.write('| - Hatemi-J, A. (2014) Asymmetric generalized impulse responses with an      |\n');
    output_rprt_file.write('| application in finance, Economic Modelling, vol. 36(C), 18-22.              |\n');
    output_rprt_file.write('| - Hatemi-J, A. and El-Khatib Y. (2016) An extension of the asymmetric       |\n');
    output_rprt_file.write('| causality tests for dealing with deterministic trend components,            |\n');
    output_rprt_file.write('| Applied Economics, 48(42), 4033-4041.                                      |\n');
    output_rprt_file.write('|                                                                             |\n');
    output_rprt_file.write('===============================================================================\n');
    output_rprt_file.write('\n');

    output_rprt_file.write('===============================================================================\n');
    output_rprt_file.write('|                           ADDITIONAL INFORMATION                            |\n');
    output_rprt_file.write('|                                                                             |\n');
    output_rprt_file.write('| This program code is the copyright of the authors. Applications are allowed |\n');
    output_rprt_file.write('| only if proper reference and acknowledgments are provided.                  |\n');
    output_rprt_file.write('| For non-Commercial  applications only. No performance guarantee is          |\n');
    output_rprt_file.write('| made. Bug reports are welcome. If this code is used for research or in any  |\n');
    output_rprt_file.write('| other code, proper attribution needs to be included.                        |\n');
    output_rprt_file.write('|                                                                             |\n');
    output_rprt_file.write('| © 2026 Dr. Alan Mustafa and Prof. Abdulnasser Hatemi-J                      |\n');
    output_rprt_file.write('===============================================================================\n');
    
    """
- Hatemi-J A. (2012) Asymmetric causality tests with an application, Empirical Economics, vol. 43(1), 447-456.

- Hatemi-J, A. (2014) Asymmetric generalized impulse responses with an application in finance, Economic Modelling, vol. 36(C), 18-22.
- Hatemi-J, A. and El-Khatib Y. (2016) An extension of the asymmetric causality tests for dealing with deterministic trend components, Applied Economics, 48(42), 4033-4041.
    """
    
    output_rprt_file.close;
    # --------------------------------------------------------------------------
    
    txtEndNote = "";
    txtEndNote = txtEndNote + """REFERENCES:
    - Hatemi-J A. (2012) Asymmetric causality tests with an application, Empirical Economics, vol. 43(1), 447-456.
    - Hatemi-J, A. (2014) Asymmetric generalized impulse responses with an application in finance, Economic Modelling, vol. 36(C), 18-22.
    - Hatemi-J, A. and El-Khatib Y. (2016) An extension of the asymmetric causality tests for dealing with deterministic trend components, Applied Economics, 48(42), 4033-4041.

    ADDITIONAL INFORMATION:
    This program code is the copyright of the authors. Applications are allowed only if proper reference and acknowledgments are provided. For non-Commercial 
    applications only. No performance guarantee is made. Bug reports are welcome. If this code is used for research or in any other code, proper attribution 
    needs to be included.
    © 2026 Dr. Alan Mustafa and Prof. Abdulnasser Hatemi-J
    """
    self.msgEndNote["text"] = "%s" % (txtEndNote)
    
    return;    

################################################

def createCsvFile(fileName_,result,theRprtFldrName):
    fileName = str(fileName_) + '.csv'
    theFile = os.path.join(theRprtFldrName, fileName)
    df = pd.DataFrame(result)
    df.to_csv(theFile,
              index=False,
              header=True,
              encoding="utf-8")
    return

################################################

def createTxtFile(fileName_,result,theRprtFldrName):
    fileName = str(fileName_) + '.txt'
    theFile = os.path.join(theRprtFldrName, fileName)
    df = pd.DataFrame(result)
    df.to_csv(theFile,
              index=False,
              header=True,
              encoding="utf-8")
    return

################################################

def save_plot(assetName, df, folder_path):
    import matplotlib.pyplot as plt
    import os

    os.makedirs(folder_path, exist_ok=True)

    # Handle both DataFrame and Series
    if hasattr(df, "iloc") and len(df.shape) == 2:
        y = df.iloc[:, 0]
    else:
        y = df

    # X starts from 1
    x = list(range(1, len(y) + 1))

    fig, ax = plt.subplots()
    ax.plot(x, y)

    # Make axes meet at zero
    ax.spines['left'].set_position('zero')
    ax.spines['bottom'].set_position('zero')

    # Remove extra borders
    ax.spines['right'].set_color('none')
    ax.spines['top'].set_color('none')

    # IMPORTANT: remove gap
    ax.set_xlim(0, len(y))

    # Axis ticks
    ax.xaxis.set_ticks_position('bottom')
    ax.yaxis.set_ticks_position('left')

    # Labels
    ax.set_xlabel('Observations')
    ax.set_ylabel('Value')
    ax.set_title('Time Plot of ' + str(assetName))

    fileName = str(assetName) + '.png'
    file_path = os.path.join(folder_path, fileName)

    plt.savefig(file_path, dpi=300)
    plt.close()

    return


def rprtsFldrName(assetName):
    now = datetime.now()
    theRprtFldrName_ = 'PyTIVIPNC_' + str(assetName) + "_" + now.strftime("%Y%m%d_%H%M%S")
    os.makedirs(theRprtFldrName_, exist_ok=True)
    return(theRprtFldrName_)
    
def rprtsFileName(assetName):
    theRprtFileName_ = 'rprt_TIVIPNC_on_' + str(assetName) + '.txt'
    return(theRprtFileName_)
    

###############################################################################
#             Start of Formating Numbers                                      #
###############################################################################
def fDcml(value,frmtDec):   # fDcml = Format the value with Decimal
    return (round(value, frmtDec))
###############################################################################
#              End of Formating Numbers                                       #
###############################################################################

def activateBtnCalcPD(self):
    if self.tbx_DatasetFile.get() != '':
        self.btnCalcTDICPS['state'] = 'normal'
        self.btnLoadSmplData['state'] = 'disable'
        
    else:
        self.btnCalcTDICPS['state'] = 'disable'
        self.btnLoadSmplData['state'] = 'disable'
        
def disableBtnSelectDataFile(self):
    self.btnSelectDataFile['state'] = 'disable'

def indicatorActive(self):
    self.lblIndicator['fg'] = '#e52b50'
    self.lblIndicator['text'] = '  ' + chr(9608) + ' in progress ...'
    self.update()

def indicatorEnd(self):
    self.lblIndicator['fg'] = '#53af9b'
    self.lblIndicator['text'] = '  ' + chr(9608) + ' Complete!      '
    self.update()

def lblPrint_Intercept_Slope(self):
    self.lblIndicator['fg'] = '#e52b50'
    self.lblIndicator['text'] = 'Intercept + Slope'
    self.update()

    
def showInfoOnSampleData():
    txtShowInfo = "A copy of sample data has been created in the same folder as this module resides in, labeled as PyTIVIPNC_SampleData.csv\nMake sure your dataset is in the same format."
    tk.messagebox.showinfo("Info on sample data",  txtShowInfo)


#In the main function, create the GUI and pass it to the App class
def main():

    window2= tk.Tk()
    window2.title("PyTIVIPNC-v1")
    window2.geometry('850x700+10+10')

    create_window_menu_UI2(window2).grid(row=0, column=0, columnspan=1, sticky="W")
    window2.mainloop()

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        raise SystemExit(1)

