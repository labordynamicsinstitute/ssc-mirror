//	matwrite version history

//	0.81	First test release

//	0.82	Fixed some stability issues
//			Some improved code efficiency
//			Changed some error messages/codes
	
//	0.90	User can now group variables to export as a matrix
//			Now reading names from local macro

#include "stplugin.h"
#include <stdio.h>
#include <string.h>
#include <io.h>
#include <math.h>
#include <stdlib.h>
#include <ctype.h>
#include <float.h>

//#define DEBUG

// my matFile class to write MAT-file level 4 files
// these will be compatible with any MATLAB version

class matFile
{
public:
	matFile()
	{
		thisRep=1;
	}
	
	bool matOpen(char *fileName, char fileMode[4])
	{
		fp = fopen(fileName,fileMode);
		if (fp==NULL) return true;
		else return false;
	}

	bool matClose()
	{
		if (fclose(fp)) return true;
		else return false;
	}
	
	bool matWrite(char *matName, const ST_double *data, int row, int col, int rep)
	{
		typedef struct {
			long type;
			long mrows;
			long ncols;
			long imagf;
			long namelen;
			} matHeader;

		int mn = row*col;
		int writtenCheck = mn;
		size_t written=0; //to evaluate success

		if (thisRep==1)
		{
			matHeader thisHeader;

			thisHeader.type    = 0000;
			thisHeader.mrows   = row;
			thisHeader.ncols   = col*rep;
			thisHeader.imagf   = 0;
			thisHeader.namelen = strlen(matName) + 1;

			writtenCheck += 1 + thisHeader.namelen;

			written += fwrite(&thisHeader, sizeof(matHeader), 1,                  fp);
			written += fwrite(matName,     sizeof(char),      thisHeader.namelen, fp);
		}

		written += fwrite(data, sizeof(ST_double), mn, fp);

		if (thisRep<rep) thisRep++;
		else thisRep=1;

        if (written!= writtenCheck) return true;
        else return false;

	}

private:
	FILE *fp;
	int thisRep;
};

//checks for legal variable name
int matlabLegal(char *varname);

STDLL stata_call(int argc, char *argv[])         
	{
	
    ST_int          i;           //for looping around variables
    ST_long         j, k, m, n;  //for looping around matrix elements
    ST_retcode	    rc;          //stata return code

	const ST_double inf = HUGE_VAL; //matlab will read this as +inf
	
	bool replace  = false;
	bool thiswarn = false;
	int  error    = 0;
	char buf[1024];

	// first argument is always the save file name given by using

    char *file = new char[strlen(argv[0]) + 1];
	strcpy(file,argv[0]);

	#ifdef DEBUG
		FILE *debuglog;
		debuglog = fopen("matwrite.log","w+");
		strcpy(buf,"matwrite debug log\n");
		fwrite(buf,sizeof(char),strlen(buf) + 1,debuglog);
	#endif DEBUG

 	//check file existence and access

    replace =! strcmp(argv[2],"replace");	

	#ifdef DEBUG
		strcpy(buf,"Checking file existence and access...\n");
		fwrite(buf,sizeof(char),strlen(buf) + 1,debuglog);
	#endif DEBUG

	if (_access(file,0)!=0)
	{
		strcpy(buf,"(note: file ");
		strcat(buf, file);
		strcat(buf, " not found)\n");
		SF_display(buf);
	}

    if ((_access(file,0)==0) && (!replace))
    {
        strcpy(buf,"file ");
        strcat(buf, file);
        strcat(buf, " already exists\n");
		error = 602;
    }

    if (_access(file,0)==0 && _access(file,2))
    {
        strcpy(buf,"file ");
        strcat(buf, file);
        strcat(buf, " is read-only; cannot be modified or erased\n");
		error = 608;
	}

	if (error)
	{
		SF_error(buf);
		delete [] file;
        return(error);
	}

	//check whether we should append previous data set
	
	char version[4];	
	
	switch(atoi(argv[1]))
	{
        case 0:
			strcpy(version,"a+b");
			break;   
        case 1:
			strcpy(version,"wb");
			break;
        default:
			SF_error("invalid save option\n");
			delete [] file;
			return(102); //invalid syntax
			break;
    }

	#ifdef DEBUG
		strcpy(buf,"Opening MAT-file...\n");
		fwrite(buf,sizeof(char),strlen(buf) + 1,debuglog);
	#endif DEBUG

	matFile pMat;

    if (pMat.matOpen(file,version))
    {
        SF_error("error opening MAT-file\n");
		delete [] file;
		return(603); //file could not be opened
    }           

	//variable names read from local macro

    char *token;
    int matCount, matColumn, allNamesLen;

	if (replace)
	{
		matCount = atoi(argv[3]);    
		allNamesLen = atoi(argv[4]) + 1;
	}
	else
	{
		matCount = atoi(argv[2]);
   	    allNamesLen = atoi(argv[3]) + 1;
	}

	char *allNames    = new char[allNamesLen];
	if (rc = SF_macro_use("_allNames", allNames, allNamesLen)) return(rc);

	#ifdef DEBUG
		strcpy(buf,"AllNames: [");
		fwrite(buf,sizeof(char),strlen(buf) + 1,debuglog);
		fwrite(allNames,sizeof(char),strlen(allNames) + 1,debuglog);
		strcpy(buf,"]\n");
		fwrite(buf,sizeof(char),strlen(buf) + 1,debuglog);
	#endif DEBUG

	token = strtok(allNames, " ");

	m = 0;
	int thisMat = 1;
	bool newMat = true;

    if (SF_nvars()>0)
    {                	          
        for(i=0; i < SF_nvars(); i++)
        {   

			ST_double *arrayDouble = new ST_double[SF_nobs()];

            if (newMat)
			{
				if (i>0) token = strtok(NULL, " ");
				//check whether a matlab legal variable name
				
				switch (matlabLegal(token))
		        {
			        case 1:
				        strcpy(buf, "variable name ");
					    strcat(buf, token);
	                    strcat(buf, " is a reserved MATLAB word\n");
		                SF_error(buf);
						error = 198;
				        break;
				    case 2:
		                strcpy(buf, "variable ");
		                strcat(buf, token);
		                strcat(buf, " has an illegal variable name\n");
		                SF_error(buf);
		                SF_error("variable names must begin with a letter\n");
						error = 198;
						break;
		            case 3:
		                strcpy(buf, "variable ");
		                strcat(buf, token);
		                strcat(buf, " has an illegal variable name\n");
		                SF_error(buf);
		                SF_error("variable names can only contain underscores and alphanumeric characters\n");
		                error = 198;
						break;
					default:
						break;
		        }
		
				if (error)
				{	
					delete [] token;
					delete [] allNames;
					delete [] file;
					
					delete [] arrayDouble;
					arrayDouble = NULL;
					
					return(error); //invalid name
				}
	
				if (thisMat<=matCount)
				{
					matColumn = atoi(strtok(NULL, " ")); 
					thisMat++;
				}
				else matColumn = 1;
			
				n = 1;
				thiswarn = false;
			
			} //if newMat

			if (n<matColumn)
			{
				n++;
				newMat = false;
			}
			else newMat = true;

            // store stata variable in a dynamic array
    	    // this will then be copied to Matlab matrix
    	
            m = 0; //keeps track of elements in variable

			#ifdef DEBUG
				fwrite(token,sizeof(char),strlen(token) + 1,debuglog);
				sprintf(buf,", var %d:",i);
				fwrite(buf,sizeof(char),strlen(buf) + 1,debuglog);
			#endif DEBUG

            if (SF_nobs()>0)
            {
				for(j = SF_in1(); j <= SF_in2(); j++) 
        		{
        			if(SF_ifobs(j)) 
					{
						
            			if (rc = SF_vdata(i+1,j,&arrayDouble[m])) return rc;
        				if (SF_is_missing(arrayDouble[m]))
        				{
        					arrayDouble[m] = inf;
							if (!thiswarn)
        					{
        						strcpy(buf, "warning: ");
        						strcat(buf, token);
        						strcat(buf, " contains missing values\n");
        						SF_display(buf);
        						thiswarn = true;

								#ifdef DEBUG
									strcpy(buf," MISSING,");
									fwrite(buf,sizeof(char),strlen(buf) + 1,debuglog);
								#endif DEBUG

							}    
        				}   
        				m++;
        			}
        		}

			    if (m>0)
			    {

			        if (pMat.matWrite(token,arrayDouble,m,1,matColumn))
		 		    {
		 	            strcpy(buf,"error creating variable ");
		                strcat(buf,token);
		                strcpy(buf,"\n");
		                SF_error(buf);
						delete [] token;
						delete [] allNames;					
						delete [] file;
						delete [] arrayDouble;
						arrayDouble = NULL;                    
						return(198); //invalid syntax	    
					}

					#ifdef DEBUG
						strcpy(buf," SAVED.\n");
						fwrite(buf,sizeof(char),strlen(buf) + 1,debuglog);
					#endif DEBUG


					delete [] arrayDouble;
           			arrayDouble = NULL;

		 		} //if m>0 		

			} //if SF_nobs>0       
 	
    	} // nvars loop 

    	if (m==0) SF_display("warning: no observations\n");

    } // if nvars>0

    int nMat = 0;
    int index = 0;

	token = strtok(NULL, " ");

	while( token != NULL )
	{
        if (SF_col(token)==0)
        {
            if (SF_row(token)==0)
            {
                strcpy(buf,"warning: matrix ");
                strcat(buf,token);
                strcat(buf," does not exist\n");
                SF_display(buf);
            }
            if (SF_row(token)==1)
            {
                strcpy(buf,"warning: matrix ");
                strcat(buf,token);
                strcat(buf," has zero dimension\n");
                SF_display(buf);
            }
        }    
        else
        {
			switch (matlabLegal(token))
			{
				case 1:
					strcpy(buf, "matix name ");
					strcat(buf, token);
					strcat(buf, " is a reserved MATLAB word\n");
					SF_error(buf);
					error = 198;
					break;
				case 2:
					strcpy(buf, "matrix ");
					strcat(buf, token);
					strcat(buf, " has an illegal variable name\n"); 
					SF_error(buf);
					SF_error("matrix names must begin with a letter\n");
					error = 198;
					break;
				case 3:
					strcpy(buf, "matrix ");
					strcat(buf, token);
					strcat(buf, " has an illegal variable name\n");
					SF_error(buf);
					SF_error("matrix names can only contain underscores and alphanumeric characters\n");
					error = 198;
					break;
				default:
					break;
			} //switch  

			if (error)
			{
				delete [] token;
				delete [] allNames;
				delete [] file;
				return(error);
			}		
			
			ST_double *arrayDouble = new ST_double[SF_col(token)*SF_row(token)];

			thiswarn = false;

            nMat++;

			for (j=1;j<=SF_row(token);j++)
			{
				for (k=1;k<=SF_col(token);k++)
				{
				    index = j + (k-1)*SF_row(token) - 1;                          
					if (rc = SF_mat_el(token,j,k,&arrayDouble[index])) return rc;
					if (SF_is_missing(arrayDouble[index]))
                        {
						arrayDouble[index] = inf;
                        if (!thiswarn)
						{
							strcpy(buf, "warning: matrix ");
							strcat(buf, token);
							strcat(buf, " contains missing values\n");
							SF_display(buf);
							thiswarn = true;
						}    
					}                                 
				}
			}

            pMat.matWrite(token,arrayDouble,SF_row(token),SF_col(token),1);

            delete [] arrayDouble;
           	arrayDouble = NULL;
    	
        } //else   

		token = strtok(NULL, " ");

	} //while

	delete [] token;  
	delete [] allNames;

	#ifdef DEBUG
		strcpy(buf,"Closing MAT-file...\n");
		fwrite(buf,sizeof(char),strlen(buf) + 1,debuglog);
	#endif DEBUG

    if (pMat.matClose())
    {
        SF_error("can't close MAT-file\n");
        error = 608;
    }

    if (SF_nvars()==0 && nMat==0)
    {   
        SF_error("no variables or matrices exported\n");
        if (rc = remove(file))
		{
			strcpy(buf,"can't delete file ");
			strcat(buf,file);
			strcat(buf,"\n");
			SF_error(buf);
        }
		error = 198;
	}

    if (m==0 && nMat==0)
    {
        SF_error("no observations and no matrices exported\n");
        if (rc = remove(file))
		{
			strcpy(buf,"can't delete file ");
			strcat(buf,file);
			strcat(buf,"\n");
			SF_error(buf);
		}
		error = 198;
    }               

	//success!

	#ifdef DEBUG
		strcpy(buf,"Completed.\n");
		fwrite(buf,sizeof(char),strlen(buf) + 1,debuglog);
		fclose(debuglog);
	#endif DEBUG
	
	delete [] file;
    return(error);

} //STDLL stata_call
	
int matlabLegal(char *varname)
{
	const char reserved[] = " break case catch continue else endif end for function global if otherwise persistent return switch try while "; 
    int unsigned i;
	int error = 0;

	char *thisvarname = new char[strlen(varname)+3];
	strcpy(thisvarname," ");
	strcat(thisvarname,varname);
	strcat(thisvarname," ");

	//reserved word?
	if (strstr(reserved,thisvarname)) error = 1;

    //initial character
    if (!isalpha(thisvarname[1]))     error = 2;

    //all other characters must be alphanumeric or underscore
    //not sure why first condition is not capturing "£"

	// not sure if this works properly...

    if (strlen(thisvarname)>1)
    {
        for (i=2;i<strlen(thisvarname)-1;i++)
		{
            if ((!__iscsym(thisvarname[i])) || (!strcmp(&thisvarname[i],"£")))
			{
				error = 3;
				break;
			}
		}
	}

	delete [] thisvarname;
	return error;
}    
