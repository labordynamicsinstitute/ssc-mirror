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

#define MAXLINE     2048
#define MAXBETTORS  100000
#define MAXJUMP     0.0005
#define MINJUMP     0.0001
#define STARTBET    0.000001

/*****************************************************************************

ROUTINE:        findBet()
RETURNS:        void
OUTPUTS:        *bet = -2.0     Error: ln(x), x <= 0
                *bet = -1.0     Error: bet >= poolW
                *bet > 0.0      Success

DESCRIPTION:    Find bet which yields F(bet) = 0

        Iterate with trial bets, starting very small, increasing
        the bet until the function crosses zero, then interpolate
        the func=0 bet value from the two func values which bracket
        zero.  By adjusting the bet increment on-the-fly to keep
        the function delta very small, the interpolation will be
        based on two values which are extremely close to zero, thus
        minimizing interpolation error.
            
        A "natural log" transform is applied to the function to
        lessen the slope and facilitate interpolating near zero.
        
        Stop looping if bet ever gets as large as the win pool to
        prevent looping forever (impossible? but prudent ;-)

******************************************************************************
*/

void findBet(int numBettors, double beta, double pi, double XX, double poolW,
                double tolerance, double *bet)
{
    double inc;
    double tempFunc;
    double oldTempFunc = -1.0;
    double diffTempFunc;
    double absDiffTempFunc;
    
    double trialBet;
    double oldTrialBet = -1.0;

    double tempFloat;
    double diffTrialBet;

    
    inc = 0.00001;  // STARTING BET INCREMENT

    // MAIN TRIAL BET LOOP
    for (trialBet = STARTBET; trialBet < poolW; trialBet += inc )
    {
        // COMPUTE FUNCTION SUBTRAHEND
        tempFloat = (XX + ( (numBettors - 1.0) * trialBet) ) *
            (
                (
                    sqrt( (pi * beta) / (1.0 - pi * beta) ) *
                    sqrt
                    (
                        (
                            (
                                (poolW + ( (numBettors - 1.0) * trialBet) ) /
                                (XX + ( (numBettors - 1.0) * trialBet) ) 
                            )
                            - 1.0
                        )
                    )
                )
                - 1.0
            );

        // CHECK FOR INVALID NEGATIVE BEFORE DOING NAT. LOG
        if (tempFloat <= 0.0)
        {
            *bet = -2.0;
            return;
        }

        // HERE'S THE NAT LOG TRANSFORM APPLIED TO FUNCTION
        tempFunc = log(trialBet) - log(tempFloat);

#ifdef DEBUG
printf("f=%1.8f b=%1.8f inc=%1.2f\n", tempFunc, trialBet, inc);
#endif

        if (tempFunc >= 0.0)
        {

            if (tempFunc == 0.0)    // EXACTLY ZERO?  BINGO (UNLIKELY!)
                *bet = trialBet;
            else                    // ELSE INTERPOLATE ZERO CROSSING
            {
                diffTempFunc = tempFunc - oldTempFunc;
                diffTrialBet = trialBet - oldTrialBet;

                *bet =  oldTrialBet +
                    (fabs(oldTempFunc) * diffTrialBet / diffTempFunc);
            }

            // SUCCESSFUL RETURN!
            return;
        }
        
        // ADJUST INCREMENT SO THAT THE CHANGE IN FUNCTION VALUE
        // FROM PREVIOUS ITERATION FALLS BETWEEN MINJUMP AND MAXJUMP

        
        if (oldTempFunc != -1.0)  // ONLY IF NOT VERY FIRST ITERATION
        {
            absDiffTempFunc = fabs(tempFunc - oldTempFunc);

            if (absDiffTempFunc > MAXJUMP)
                inc /= 10.0;
            else if (absDiffTempFunc < MINJUMP)
                inc *= 10.0;
        }

        oldTrialBet = trialBet;  // SAVE OLD VALUES
        oldTempFunc = tempFunc;

    }

    // IF WE MADE IT THIS FAR BY FALLING OUT OF LOOP, BET MUST BE AS
    // LARGE AS THE WIN POOL, SO WE FAILED TO FIND A USEFUL BET

    *bet = -1.0;
    
#ifdef DEBUG    
printf("\n");
#endif

    return;
}


/* MAIN PROGRAM */
main(int argc, char **argv)
{

    double  poolW;
    double  beta;
    double  tolerance = 0.001;
    double  pi;
    double  X;
    double  bet;
    int     numBettors;

    FILE    *inputFp;
    FILE    *outputFp;
    char    inLine[MAXLINE];
    char    *token;
    char    *t1;
    char    *t2;

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
        printf("\n   Usage:  singhors <input_file> <output_file>\n\n");
        exit(0);
    }

    // PROCESS EACH LINE OF THE INPUT FILE AS A NEW SET OF INPUTS
    while (fgets(inLine, sizeof(inLine), inputFp) )
    {
        if ( (token = strtok(inLine, " \t") ) == NULL)
        {
            printf("\nError: missing numBettors value\n\n");
            exit(0);
        }

        numBettors = atoi(token);
        if (numBettors < 1)
        {
            fprintf(stderr,
                "Error:  %d bettors is not very interesting!\n", numBettors);
            exit(0);
        }
        
        if (numBettors > MAXBETTORS)
        {
            fprintf(stderr, "Error:  %d is too many bettors!\n", numBettors);
            exit(0);
        }

        if ( (token = strtok(NULL, " \t") ) == NULL)
        {
            printf("\nError: missing beta value\n\n");
            exit(0);
        }
        
        beta = atof(token);
        if (beta >= 1.0)
        {
            fprintf(stderr, "Error:  Beta %1.2f is too large\n", beta);
            exit(0);
        }

        if ( (token = strtok(NULL, " \t") ) == NULL)
        {
            printf("\nError: missing Pi value\n\n");
            exit(0);
        }

        if (strchr(token, '.') )
            pi = atof(token);
        else if ( (t1 = strchr(token, '/') ) )
        {
            t2 = strrchr(token, '/');
            if (t1 != t2)
            {
                printf("\nError: Pi contains too many '/'s\n\n");
                exit(0);
            }

            t2++;
            *t1 = '\0';
  
            pi = atof(token) / atof(t2);
        }
        else
        {
            printf("\nError: Pi must contain '.' or '/'\n\n");
            exit(0);
        }
            
        if (pi >= 1.0)
        {
            printf("\nError: Pi must be < 1.0\n\n");
            exit(0);
        }

        if ( (token = strtok(NULL, " \t") ) == NULL)
        {
            printf("\nError: missing X value\n\n");
            exit(0);
        }
            
        X = atof(token);

        if ( (token = strtok(NULL, " \t") ) == NULL)
        {
            printf("\nError: missing W value\n\n");
            exit(0);
        }
            
        poolW = atof(token);

        // CHECK FOR NOSENSICAL Pi VALUE
        if (pi <= X / (poolW * beta) )
        {
            printf("Pi <= X / (poolW * beta) : No profitable bets\n");
            continue;
        }

        // PRINT STARTING VALUES TO OUTPUT
        fprintf(outputFp,"%5d ", numBettors);
        fprintf(outputFp,"%1.2f ", beta);
        fprintf(outputFp,"%1.4f ", pi);
        fprintf(outputFp,"%1.2f ", X);
        fprintf(outputFp,"%1.2f ", poolW);
        fprintf(outputFp,"%1.8f ", beta * poolW / X);

        // COMPUTE b VALUE FOR GIVEN INPUTS
        findBet(numBettors, beta, pi, X, poolW, tolerance, &bet);

        // PRINT FINAL VALUE OF bet AND bet * numBettors TO OUTPUT FILE
        if (bet != -1.0 && bet != -2.0)
        {
            fprintf(outputFp, "%1.8f ", bet);
            fprintf(outputFp, "%1.8f ", bet * numBettors);
            fprintf(outputFp, "%1.8f",
                (beta * (poolW + (bet * numBettors) ) ) /
                    (X + (bet * numBettors) ) );
        }
        else
        {
            fprintf(outputFp, "    x.xx ");
        }

        fprintf(outputFp,"\n");
        printf(".");
    }

    fclose(inputFp);
    fclose(outputFp);

    return(0);
}
