//CPS-CPP: C++ Module for Transforming an Integrated Variable with Deterministic Trend Parts into Negative and Positive Cumulative Partial Sums.
//Authors: Youssef El-Khatib (The UAE University, Youssef_Elkhatib@uaeu.ac.ae) and Abdulnasser Hatemi-J (The UAE University, AHatemi@uaeu.ac.ae) 

// Asym_Caus.cpp : Defines the entry point for the console application.


#include "stdafx.h"

//
//  main.cpp
//  Asym_Causality
//
//

#include <iostream>
#include <cmath>
#include <fstream>
#include <cstdlib>
#include <algorithm>
#include <numeric>
#include <vector>

using namespace std;

double slope(const vector<double>& x, const vector<double>& y) {
	if (x.size() != y.size()) {
		throw exception("...");
	}
	double n = x.size();

	double avgX = accumulate(x.begin(), x.end(), 0.0) / n;
	double avgY = accumulate(y.begin(), y.end(), 0.0) / n;

	double numerator = 0.0;
	double denominator = 0.0;

	for (int i = 0; i<n; ++i) {
		numerator += (x[i] - avgX) * (y[i] - avgY);
		denominator += (x[i] - avgX) * (x[i] - avgX);
	}

	if (denominator == 0) {
		throw exception("...");
	}

	return numerator / denominator;
}

double intercept(const vector<double>& x, const vector<double>& y) {
	
	if (x.size() != y.size()) {
		throw exception("...");
	}

	double n = x.size();
	
	double avgX = accumulate(x.begin(), x.end(), 0.0) / n;
	double avgY = accumulate(y.begin(), y.end(), 0.0) / n;

	
	return avgY - slope(x, y)*avgX;
}

int main(int argc, const char * argv[]) {

	char MyFileName[50];
	double kelma;
	double kelma2;
	int i = 0;
	int N = 1;
	ifstream  my_instream;
	ifstream  fileop2;
	ofstream myfile;


	cout << "CPS-CPP: C++ Module for Transforming an Integrated Variable with Deterministic Trend Parts into Negative and Positive Cumulative Partial 		Sums.\n\n";
	cout << "Authors: Youssef El-Khatib (The UAE University, Youssef_Elkhatib@uaeu.ac.ae) and Abdulnasser Hatemi-J (The UAE University, 			AHatemi@uaeu.ac.ae)\n \n \n";
	cout << "This program provides the positive and negative parts of an integrated variable with deterministic trend parts.\n  \n";
	cout << "For technical description, see  Asymetric Causality paper of A.Hatemi - J & El - Khatib Y.,\n";
	cout<< "published in Applied Economics, 48, 2016. \n  \n \n \n";
	cout << "The program requires a .txt file with only one column containing the data.\n";
	cout<< "No words(or blanc rows) should be in the file only data values \n \n \n \n";
	cout << "If Your .txt file is in the same folder as the executable file of this program,\n"; 
	cout << "             "<<"write its name with txt exntension, like this file_name.txt \n \n \n";
	cout << "If Your .txt file is in not is not the same folder as the executable file of this program,\n";
	cout << "             " << "write its path then its name with txt exntension,\n";
	cout << "             " << "for example if your.txt file is in the desktop, \n";
	cout << "             " << "you write like this: C:\\Users\\User_Name\\Desktop\\file_name.txt \n \n \n \n";
	cout << "The program generates the -Res.txt- file the positives and negatives parts\n \n";
	cout << "Enter the file name \n";

	cin.getline(MyFileName, 50);

	my_instream.open(MyFileName);

	if (my_instream.fail()) {
	
		system("pause");

		cout << "The program is closing because the file you enters its name is not recognised. Please make sure \n \n";
		cout << "		 "<< "The name file your enters is not recognised. \n \n \n Please make sure ";
		cout<< "		 " << "that you have the file in the same folder as the excutable file or entered its path \n \n";
		cout << "If Your .txt file is in the same folder as the executable file of this program, write its name with txt exntension, like this file_name.txt \n";
		cout << "If Your .txt file is in not is not the same folder as the executable file of this program, write its path then its name with txt exntension, for example if your .txt file is in the desktop, you write like this: C:\\Users\\User_Name\\Desktop\\file_name.txt \n";

		exit(EXIT_FAILURE);
	}
	cout << "The program is runining \n";
	cout << "---------------------------- Please wait ----------------------\n";

	cout << "-------------------------------------------\n";

	cout << "-------------------------------------------\n";
	cout << "-------------------------------------------\n";

	my_instream >> kelma;
	while (my_instream.good()) {

		my_instream >> kelma;
		i++;
	}
	my_instream.close();
	N = i + 1;


	std::vector<double> Val;
	std::vector<double> TT;


	
	fileop2.open(MyFileName);

	if (!fileop2.is_open()) {
		exit(EXIT_FAILURE);
	}

	fileop2 >> kelma2;

	
	Val.push_back(kelma2);
	int l = 1;

	while (fileop2.good()) {

		fileop2 >> kelma2;

		Val.push_back(kelma2);
		TT.push_back(l);
		l++;

	}
	fileop2.close();

	std::vector<double> DVal; 
	std::vector<double> E;

	std::vector<double> Eplus;
	std::vector<double> Eminus;

	std::vector<double> SEplus;
	std::vector<double> SEminus;

	std::vector<double> Valplus;
	std::vector<double> Valminus;

	std::vector<double> Valcheck;	

	for (int k = 0; k<N-1; k++) {
		
		DVal.push_back(0.);
		E.push_back(0.);
		Eplus.push_back(0.);
		Eminus.push_back(0.);
		SEplus.push_back(0.);
		SEminus.push_back(0.);
		Valplus.push_back(0.);
		Valminus.push_back(0.);
	}
	for (int k = 0; k < N; k++) {
		Valcheck.push_back(0.);
	}
	for (int kk = 0; kk < N - 1; kk++) {
		DVal[kk] = Val[kk + 1] - Val[kk];
	}
	double b_slop = slope(TT, DVal);
	double a_interc = intercept(TT, DVal);


	for (int kk = 0; kk<N - 1; kk++) {
		E[kk] = DVal[kk] - a_interc - b_slop*(kk + 1);
		if (E[kk]>0) {
			Eplus[kk] = E[kk];
			Eminus[kk] = 0.;
		}
		else {
			Eminus[kk] = E[kk];
			Eplus[kk] = 0.;
		}

	}

	SEplus[0] = Eplus[0];
	SEminus[0] = Eminus[0];
	for (int j = 1; j<N - 1; j++) {

		SEplus[j] = SEplus[j - 1] + Eplus[j];
		SEminus[j] = SEminus[j - 1] + Eminus[j];
	}

	Valcheck[0] = Val[0];
	for (int d = 1; d<N; d++) {
		Valplus[d - 1] = SEplus[d - 1] + (Val[0] + a_interc*d + (d*(d + 1)*0.5)*b_slop)*0.5;
		Valminus[d - 1] = SEminus[d - 1] + (Val[0] + a_interc*d + (d*(d + 1)*0.5)*b_slop)*0.5;
		Valcheck[d] = Valplus[d - 1] + Valminus[d - 1];
	}



	myfile.open("Res.txt");


	myfile << "This file provides the different....\n";
	myfile << "t" << "                        " << "X" << "                        " << "V+" << "                         " << "V-";
	myfile << "\n";
	myfile << 0 << "        " << Val[0] <<"                                                ";
	myfile << "\n";

	for (int jk = 0; jk < N - 1; jk++) {

		myfile << jk + 1 << "                                " << Val[jk + 1] << "                                " << Valplus[jk] << "                                " << Valminus[jk];
		myfile << "\n";

	}

	cout << "\n \n \n Your Res.txt is now ready, it is in the same folder as the file \n \n \n"<< MyFileName;
	cout << "\n \n \n ---------------------------- \n \n \n";
	cout << "Good bye\n \n \n \n";

	system("pause");
	return 0;
}