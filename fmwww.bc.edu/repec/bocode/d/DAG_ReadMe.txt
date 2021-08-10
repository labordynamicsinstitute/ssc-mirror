The SAS program DAG_Estimation.sas contains a single SAS macro called JACKKNIFE. The macro 
calculates delete-an-observation estimated means for a given list of variables. Additionally,
standard errors are calculated for the list of variables in addition to totals. The macro
has 3 input parameters:

 1. LIBRARY: the library name (also called a folder) which contains the input file, 

 2. DATASET: the data set name with the data, 

 3. VARIABLES: the variable list. 

The default of the library name is c:\2007\. This will need to be changed by the
user to direct the program to the source data set on his/her computer. The default data set
name is MYDATA. This will need to be changed y the user to direct the program to the input
data set. Similarly, the variable list will need to reflect the variables on the new input
file. Do not separate the list with commas.

To run the code, "as is," 

1. Create a directory on your computer called c:\2007\ and copy the contents of the zip 
   file. 

2. Unzip the zip file into c:\2007\.

3. Start SAS.

4. Run Estimation.sas

5. The following results should print to the Output Window.

        The SAS System       08:53 Wednesday, August 8, 2007   4

                            std_
       mean_    total_     jack_      mean_    total_    std_jack_
Obs     rice     rice       rice     cotton    cotton      cotton

1      4.73     28.38    1.94841     7.75      46.5      2.02814
