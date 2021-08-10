%'******************************************************************************
%'******************************************************************************
%'    Program Name: HJC calculator
%' 
%'    This module is produced using Octave for determining the optimal lag order
%'    of a VAR model based on the minimization of an information criterion
%'    suggested by Hatemi-J (2003, 2008).
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
%'    Prof. Abdulnasser Hatemi-J (Hatemi-J; 2003, 2008).
%'    Contacts:
%'       - Prof. Abdulnasser Hatemi-J: AHatemi@uaeu.ac.ae
%'       - Dr. Alan Mustafa: Alan.Mustafa@auk.edu.krd
%'
%'    Date: February 2017
%'
%'    © 2017 Prof. Abdulnasser Hatemi-J and Dr. Alan Mustafa
%'******************************************************************************
%'******************************************************************************

clear ; close all; clc  %clearning out the memory and screen

filename = uigetfile({'*.*'},'File Selector'); % asking user for the file name

ys = dlmread(filename,',',1,0);
 
[T_, k] = size(ys);   % T_ = data observation, and k = number of features

T = T_ -1;

while true
  prompt = {'Enter number of lags (p): '};
  dlgTitle = 'Value of Lags (p)';
  num_lines = 1;
  defaultValue = {'5'};
  p_value = inputdlg(prompt,dlgTitle,num_lines,defaultValue);
  p_value = str2num(p_value{1});

  if ((p_value>1) & (p_value<T/5))
    break;
  endif
  msgbox('The p value you entered is not acceptable. Please re-enter a new value between 1 and T/5.');  
endwhile

#################################

Z_all = [];

for p = 1:p_value
p;
  Y=[];
  Y_last = [];
  Z=[];
  Z_last = [];
  Z_all = [];
  B_hat = [];
  delta = [];
  omega = [];
  HJC = [];
  B_hat_all = [];
  delta_all = [];
  omega_all = [];
  HJC_all = [];

%  fprintf('====================   Calculating Y   ======================== \n');

  Y = ys(p+1:T,:)';   % because of indexing y0 is annotated as y1
  [nr_Y, nc_Y] = size(Y);
  Y_last = Y;
  
  for p_z = p : -1: 1
  p_z;
  Z = [];

      Z = ys(((p_z-1)+1 : (T+(p_z-p-1))),:)'; % +1 of rhe row is for indexing
      [nr_Z, nc_Z] = size(Z);

      Z_all = [Z_all; Z];

  end

  [nr_Z_all, nc_Z_all] = size(Z_all);
  
  Z_all = [ones(1,nc_Z_all); Z_all];

  size(Y_last*Z_all');
  B_hat_all = (Y_last*Z_all')*pinv(Z_all*Z_all');
 
  delta_all = Y_last - B_hat_all * Z_all;
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% prepring Z_all for the next round
  Z_all(1,:) = [];
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
 
 
  omega_all = delta_all*delta_all'/(T_-k*p-1);
  O_all(p) = det(omega_all);
 
  HJC_all = log(det(omega_all)) + p * (((k^2 * log(T_)) + (2 * k^2 * log(log(T_))))/(2*T_));
  
  X(p) = p;
  HJC_values_all(p) = HJC_all;
 
  
%  fprintf('######################################################################################################### \n');
end
%fprintf('######################################################################################################### \n');
%fprintf('######################################################################################################### \n');
O_all;
HJC_values_all;
X;

[Minmum_HJC_value_all,idx] = min(HJC_values_all);

%fprintf('######################################################################################################### \n');
%fprintf('######################################################################################################### \n');

  fprintf('############################################### \n');
  fprintf('# \n');
  fprintf('#   Minimum of HJC = %d \n', idx);
  fprintf('# \n');
  fprintf('############################################### \n');


%#############################################################################
%###############   Printing Results  #########################################
%#############################################################################

msgbox(sprintf('The minimum value of HJC is %d .', idx));

fid = fopen ("Minimumu_HJC.txt", "w");
fdisp (fid, "The minimum value of HJC (the best option for lage) is = ");
fdisp (fid, idx);
fclose (fid);

printf('\nPlease check the new file create named "Minimumu_HJC.txt" \nin the same folder as this program is placed.\n\n')

fprintf('Done. \n');