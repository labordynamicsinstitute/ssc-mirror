/*--------------------------------ScoreContributions ------------------------------*//* 	This is a modification of Num1Derivative that allows the function to	be vector valued, as with Gauss's gradp. The function returns n x 1, 	the parameter is p x 1, and the derivative is n x p. The matrix of	derivatives is passed as the third argument, just as with Num1Derivative.		Michael Creel, mcreel@volcano.uab.es	21 Aug. 1998*/const decl SQRT_EPS =1E-8;        /* appr. square root of machine precision */const decl DIFF_EPS1=5E-6; /* Rice's formula: log(DIFF_EPS)=log(MACH_EPS)/3 */static dFiniteDiff1(const x){    return max( (fabs(x) + SQRT_EPS) * SQRT_EPS, DIFF_EPS1);}ScoreContributions(const func, vP, const avScore){    decl i, cp = rows(vP), left, right, fknowf = FALSE, p, h, f, fm, fp, v;       for (i = 0; i < cp; i++)    /* get 1st derivative by central difference */    {         p = double(vP[i][0]);        h = dFiniteDiff1(p);        vP[i][0] = p + h;        right = func(vP, &fp, 0, 0);		if(i==0)			v = new matrix[rows(fp)][cp];  	   	vP[i][0] = p - h;        left = func(vP, &fm, 0, 0);        vP[i][0] = p;                         /* restore original parameter */        if (left && right)       		v[][i] = (fp - fm) / (2 * h);       /* take central difference */        else            return FALSE;    }    avScore[0] = v;return TRUE;}