/*
If you use this code in your research, please cite the following paper:

   Adams, Brian R., Frank W. Rusco and W. David Walls.  "Professional Bettors,
      Odds-Arbitrage Competition, and Betting Market Equilibrium."  Singapore
      Economic Review, volume 47, number 1, pages 111-127, April 2002.
*/

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAXLINE 2048
#define MAXHORSES 20

double arrayb[MAXHORSES] = {0.0};  // BET VECTOR ZEROED TO START
double arrayX[MAXHORSES];
double arrayPi[MAXHORSES];

double poolW;
double B = 0.85;            // HARDWIRE TRACK TAKE
double tolerance = 0.01;    // HARDWIRE TOLERANCE

int numHorses;

/* FUNCTION: sumPoolW                                   */
/* Sums win pool poolW from current X vector arrayX     */
/*                                                      */
void sumPoolW(void)
{
    int ii;

    poolW = 0.0;

    for (ii = 0; ii < numHorses; ii++)
        poolW += arrayX[ii];
}

/* FUNCTION: upgradeBet                                 */
/* Applies formula trying to upgrade a horse's bet      */
/*  Arguments:   hh: which horse we're upgrading        */
/*  Returns:     new bet if meets tolerance test, else  */
/*               0.0 if fails                           */
double upgradeBet(int hh)
{
    // LOCAL ACCUMULATORS AND TEMP. VARIABLES
    double sumA = 0.0; 
    double sumB = 0.0;
    double tempD, tempB;
    int ii;
        
    // COMPUTE SUM B: SUM OF ALL BETS EXCLUDING OUR HORSE hh
    for (ii = 0; ii < numHorses; ii++)
    {
        if (ii != hh)
            sumB += arrayb[ii];
    }

    // COMPUTE SUM A: THE OTHER SUM IN THE EQUATION (W/ FRACTION)
    for (ii = 0; ii < numHorses; ii++)
    {
        if (ii != hh)
            sumA += (
                      (arrayPi[ii] * arrayb[ii]) / (arrayX[ii])
                    );
    }

    // SUM UP CURRENT WIN POOL poolW (ALL Xs)
    sumPoolW();
    
    // COMPUTE TEMP INTERMEDIATE OPERAND FOR SQUARE ROOT
    tempD =
    1.0 + 
    (
      (
        arrayPi[hh] / (1.0 - (arrayPi[hh]*B) - (B*sumA) ) 
      ) *
      (
        (B*(poolW) / arrayX[hh]) - ( (1.0 - B*sumA) / arrayPi[hh]) 
      )
    );

    // IF SQUARE ROOT OPERAND NEGATIVE, ABORT AND RETURN FAILURE
    if (tempD < 0.0)
        return(0.0);
    else 
    {   // FINISH BET CALCULATION
        tempB = arrayX[hh] * ( sqrt(tempD) - 1.0);
        if (tempB - arrayb[hh] >= tolerance)  // BEATS OLD BET?
            return(tempB);                    //   YES, RETURN BET
        else 
            return(0.0);                      //   NO, RETURN FAIL
    }
}

/* FUNCTION: upgradeBetVector                                   */
/* Makes a single upgrade pass through bet vector               */
/*  Returns:     # of bets upgraded                             */
int upgradeBetVector(void)
{
    int ii;
    int numUpgrades = 0;
    double newBet;

    for (ii = 0; ii < numHorses; ii++)
    {
        // TEMPORARILY SUBTRACT CURRENT BET FROM Xi
        arrayX[ii] -= arrayb[ii];

        // ATTEMPT TO UPGRADE BET ON THIS HORSE
        if ( (newBet = upgradeBet(ii) ) > 0.0)
        {
            // SUCCESS:
            arrayX[ii] += newBet; // ADD NEW BET TO Xi
            arrayb[ii] = newBet;  // REPLACE OLD BET WITH NEW
            numUpgrades++;        // INCREMENT UPGRADE COUNTER
        }
        else // FAIL:
            arrayX[ii] += arrayb[ii]; // ADD OLD BET BACK INTO Xi
    }

    return(numUpgrades);  // RETURN # UPGRADES (IF ANY)
}

/* FUNCTION: optimizeBetVector                                  */
/* Upgrades bet vector until an upgrade pass fails              */
/*  Returns:     # of upgrade iterations                        */
int optimizeBetVector(void)
{
    int numPasses = 0;
    int ii;

    // KEEP UPGRADING BET VECTOR UNTIL UPGRADE FAILS
    while (upgradeBetVector() != 0)
    {
        printf("  pass %d bs: ", numPasses + 1);
        for (ii = 0; ii < numHorses; ii++)
            printf("%6.4f ", arrayb[ii]);
        printf("\n");

        numPasses++;
    }

    printf("\n");
    return(numPasses);
}

/* MAIN PROGRAM */
main(int argc, char **argv)
{
    int numPasses;
    int ii;
    FILE *inputFp;
    FILE *outputFp;
    char inLine[MAXLINE];
    char *token;
    char *t1;
    char *t2;
    double tempPi;

    if (argc == 3)
    {
        if ( (inputFp = fopen(argv[1], "r") ) == NULL)
        {
            printf("\nError opening input file %s\n\n", argv[1]);
            exit(0);
        }

        if ( (outputFp = fopen(argv[2], "a") ) == NULL)
        {
            printf("\nError opening output file %s\n\n", argv[2]);
            fclose(inputFp);
            exit(0);
        }
    }
    else
    {
        printf("\n   Usage:  horse <input_file> <output_file>\n\n");
        exit(0);
    }

    // PROCESS EACH LINE OF THE INPUT FILE AS A NEW RACE
    while (fgets(inLine, sizeof(inLine), inputFp) )
    {
        // ZERO WIN POOL AND BETS
        poolW = 0.0;
        tempPi = 0.0;
        for (ii = 0; ii < MAXHORSES; ii++)
            arrayb[ii] = 0.0;

        if ( (token = strtok(inLine, " \t") ) == NULL)
        {
            printf("\nError: missing numHorses value\n\n");
            exit(0);
        }

        numHorses = atoi(token);
        if (numHorses < 2)
        {
            fprintf(stderr, "Error:  %d horse doth not make a race!\n",
                numHorses);
            exit(0);
        }
        
        if (numHorses > 20)
        {
            fprintf(stderr, "Error:  %d is too many horses!\n", numHorses);
            exit(0);
        }

        if ( (token = strtok(NULL, " \t") ) == NULL)
        {
            printf("\nError: missing beta value\n\n");
            exit(0);
        }
        
        B = atof(token);
        if (B >= 1.0)
        {
            fprintf(stderr, "Error:  Beta %1.2f is too large\n", B);
            exit(0);
        }

        if ( (token = strtok(NULL, " \t") ) == NULL)
        {
            fprintf(stderr, "\nError: missing tolerance value\n\n");
            exit(0);
        }

        tolerance = atof(token);

        // READ STARTING Pi's
        for (ii = 0; ii < numHorses; ii++)
        {
            if ( (token = strtok(NULL, " \t") ) == NULL)
            {
                printf("\nError: missing Pi #%d value\n\n", ii);
                exit(0);
            }

            if (strchr(token, '.') )
                arrayPi[ii] = atof(token);
            else if ( (t1 = strchr(token, '/') ) )
            {
                t2 = strrchr(token, '/');
                if (t1 != t2)
                {
                    printf("\nError: Pi #%d contains too many '/'s\n\n",
                        ii);
                    exit(0);
                }

                t2++;
                *t1 = '\0';
  
                arrayPi[ii] = atof(token) / atof(t2);
            }
            else
            {
                printf("\nError: Pi #%d must contain '.' or '/'\n\n", ii);
                exit(0);
            }
            
            if (arrayPi[ii] >= 1.0)
            {
                printf("\nError: Pi #%d must be < 1.0\n\n", ii);
                exit(0);
            }
                
            tempPi += arrayPi[ii];
        }

        if (tempPi != 1.0)
        {
            tempPi =
                1.0 - (tempPi - arrayPi[numHorses - 1]);
            printf("\nAdjusting last Pi from %1.4f to %1.4f\n\n",
                arrayPi[numHorses - 1], tempPi);
            arrayPi[numHorses - 1] = tempPi;
        }

        // READ STARTING X's
        for (ii = 0; ii < numHorses; ii++)
        {
            if ( (token = strtok(NULL, " \t") ) == NULL)
            {
                printf("\nError: missing X #%d value\n\n", ii);
                exit(0);
            }
            
            arrayX[ii] = atof(token);
        }

        // PRINT STARTING VALUES TO OUTPUT
        fprintf(outputFp,"%d ", numHorses);
        fprintf(outputFp,"%1.2f ", B);
        fprintf(outputFp,"%1.2f ", tolerance);
        for (ii = 0; ii < numHorses; ii++)
            fprintf(outputFp,"%1.4f ", arrayPi[ii]);
        for (ii = 0; ii < numHorses; ii++)
            fprintf(outputFp,"%1.2f ", arrayX[ii]);

        // OPTIMIZE THIS RACE'S (LINE'S) BET VECTOR
        numPasses = optimizeBetVector();

        // SUM FINAL WIN POOL
        sumPoolW();

        // PRINT FINAL VALUES TO OUTPUT FILE
        for (ii = 0; ii < numHorses; ii++)
            fprintf(outputFp,"%1.2f ", arrayX[ii]);
/*
        for (ii = 0; ii < numHorses; ii++)
            fprintf(outputFp,"%1.2f ", arrayb[ii]);
*/
        fprintf(outputFp,"\n");
    }
    fclose(inputFp);
    fclose(outputFp);

    exit(0);
}
