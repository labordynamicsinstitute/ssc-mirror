%'******************************************************************************
%'******************************************************************************
%'    Program Name: TDICPS
%'    Description of the program: Transforming Data Into Cumulative Partial Sums
%'    Version: 1.0
%' 
%'    This module is developed using Octave which transforms an integrated
%'    variable into cumulative partial sums for positive and negative components.
%'    The underlying variable has both drift and trend. The transformed data can
%'    be used for implementing the asymmetric causality tests and estimating
%'    asymmetric impulses as developed by Hatemi-J (2012, 2014).
%'
%'    This program is released under GNU General Public License, version 3.
%'
%'    This program is free software: you can redistribute it and/or modify
%'    it under the terms of the GNU General Public License as published by
%'    the Free Software Foundation, either version 3 of the License, or
%'    (at your option) any later version.
%'
%'    This program is distributed in the hope that it will be useful,
%'    but WITHOUT ANY WARRANTY; without even the implied warranty of
%'    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%'    GNU General Public License for more details.
%'
%'    You should have received a copy of the GNU General Public License
%'    along with this program.  If not, see <http://www.gnu.org/licenses/>.
%'
%'    This software has been developed by Dr. Alan Mustafa under supervision of 
%'    Prof. Abdulnasser Hatemi-J (Hatemi-J; 2012, 2014).
%'    Contacts:
%'       - Prof. Abdulnasser Hatemi-J: AHatemi@uaeu.ac.ae
%'       - Dr. Alan Mustafa: Alan.Mustafa@auk.edu.krd
%'
%'    Date: July 2016
%'
%'    © 2016 Prof. Abdulnasser Hatemi-J and Dr. Alan Mustafa
%'******************************************************************************
%'******************************************************************************

clear ; close all; clc  %clearning out the memory and screen

theFile = uigetfile({'*.*'},'File Selector'); % asking user for the file name

y = load(theFile);    % loading the content of the file

m = length(y);        % Getting the size of row data set
 
for i = 1:m           % counting each row data as a unique value
 t(i,1) = i-1;
end

t0 = t(1);            % setting initial values for x-axis
y0 = y(1);            % setting initial values for y-axis

for i = 2:m           
 X(i-1, 1) = t(i);    % Looping through row data for x-axis values
 dy(i-1, 1) = y(i) - y(i-1); % % Looping through row data for dy values
end
LR = [X ones(size(X))] \ dy;  % Linear Regression values y = a + bx

Slope_value = LR(1);          % Slope value: 'b' in y = a + bx
Intercept_value = LR(2);      % Intercept value: 'a' in y = a + bx
    
e_value = dy - Intercept_value - Slope_value * X; % calucualating e_value

%#############################################################################
%###############   Calculating e_plus, e_minus  and their sums   #############
%#############################################################################

if e_value > 0 then
  e_plus = e_value;           
elseif e_value < 0 then
  e_minus = e_value;          
else
end
e_plus = (e_value >0) .*e_value;
e_minus = (e_value < 0) .*e_value;

S_e_plus(1) = e_plus(1);
S_e_minus(1) = e_minus(1);

for i = 2:size(e_plus)
  S_e_plus(i,1) = e_plus(i) + S_e_plus(i-1);
  S_e_minus(i,1) = e_minus(i) + S_e_minus(i-1);
end

%#############################################################################
%###############   Calculating y_plus, y_minus  ##############################
%#############################################################################

%fprintf('######################## \n')

y_plus = ((Intercept_value .* X + (Slope_value .* X .* (X + 1) / 2) + y0) / 2) + S_e_plus;
y_minus = ((Intercept_value .* X + (Slope_value .* X .* (X + 1) / 2) + y0) / 2) + S_e_minus;

y_plus_and_y_minus = [y_plus y_minus];

%#############################################################################
%###############   Printing Results  #########################################
%#############################################################################

dlmwrite('y+y-.txt',y_plus_and_y_minus,'delimiter','\t','precision',15);

csvwrite('y+y-.csv',y_plus_and_y_minus);

msgbox('The analysed data is ready in the same folder as your row data resides titled "y+y-".');
%plot(X,y)
%hold on;
%plot(X,y_plus,'r')
%plot(X,y_minus)
%legend('y+','y-')

fprintf('Done. \n');