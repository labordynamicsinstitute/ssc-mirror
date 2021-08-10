sdist: A Stata Package for Simulating the Central Limit Theorem

    sdist -- Simulate the central limit theorem.


Syntax

        syntax [, samples(#) obs(#) type(string) par1(#) par2(#) round(#) dots]

    options               Description
    -------------------------------------------------------------------------
    samples(#)           The number of random samples to generate. The default is 200.
    obs(#)               The number of observations per sample. The default is 500.
    type(string)         The type of distribution from which the random samples should             
>                               be drawn. The default is type(uniform), which generates 
                                random samples from a rectangular uniform distribution. 
                                Normal and Poisson distributions are also available, 
                                indicated by type(normal) and type(poisson), respectively.       
    par1(#)              The first parameter to be specified depending on the distribution 
                                selected in type(). Since the default type() is the 
                                rectangular distribution, the default is the  lower end of 
                                the [a,b) interval. The samples are generated through the 
                                -runiform()- function so the default for a is 0, but this 
                                can be changed. If type(normal) is selected, this 
                                parameter is the mean, with a default of 0. If 
                                type(poisson) is selected, this parameter is the mean, 
                                also with a default of 0. 
    par2(#)              The second parameter to be specified depending on the 
                                distribution selected in type(). Since the default type() 
                                is the rectangular distribution, the default is the  
                                higher end of the [a,b) interval. The samples are 
                                generated through the -runiform()- function so the default 
                                for b is (nearly) 1 (or, more precisely, but this can be 
                                changed. If type(normal) is selected, this parameter is 
                                the standard deviation, with a default of 1.     
    round(#)             The decimal points to which the estimates should be rounded. The 
                                default is 0.001.
    dots                 Indicates whether or not the program should show simulation 
                                progress using the -_dots- function. The default is no 
                                dots.    
    -------------------------------------------------------------------------


Description

    -sdist- simulates the central limit theorem by (1) generating a matrix of randomly
    generated normal or non-normal variables, (2) plotting the associated empirical 
    sampling distribution of sample means, (3) comparing the true sampling distribution 
    standard deviation to the standard error from the first randomly-generated sample, and 
    (4) automatically producing a side-by-side comparison of the two distributions. 
    -sdist- also outputs two .dta files to the working directory. The first file, 
    random_vars.dta, is the matrix of randomly-generated samples. The second,
    sample_means.dta, is the column vector of the sample means. These datasets
    are made available should the instructor/student wish to personalize the plots
    or information presented when discussing the CLT.


Remarks

    For detailed information on the -savesome- command, see savesome.hlp.
    For more detailed information on the random number generators in Stata, see [FN] 
        Random-number functions.


Examples

    . sdist

    . sdist, samples(300) obs(10000) round(.0001)

    . sdist, samples(400) obs(400) type(poisson) dots 


Author
    Marshall A. Taylor, University of Notre Dame, IN, USA
    mtaylo15@nd.edu
