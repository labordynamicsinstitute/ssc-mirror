function [ddata,ltsc,stsc] = deseasonalize(data,met1,met2,param,plots)
%DESEASONALIZE Remove short and long term seasonal components.
%   [DDATA,LTSC,STSC] = DESEASONALIZE(DATA,MET1,MET2,PARAM) returns
%   deseasonalized data vector DATA and long term seasonal component LTSC. 
%   Parameters METHOD1 and METHOD2 define the short and long term seasonal 
%   decomposition techniques, respectively:
%       MET1 = 0 -> remove mean short term seasonal component (STSC) 
%                   of period PARAM(1) using REMSTSC (see below)
%       MET1 = 1 -> remove median STSC of period PARAM(1) using REMSTSC
%       MET1 = 2 -> remove moving average-based STSC of period PARAM(1) 
%                   using REMST.M
%       MET2 = 0 -> remove LTSC using wavelet transform of order PARAM(2)
%       MET2 = 1,2,.. -> remove sinusoidal LTSC of period PARAM(2); for
%                   LTSC function definitions see LTSC_SCOREF below.
%   Default values are MET1 = 2, MET2 = 0, PARAM = [7 8].
%
%   Sample use:
%       >> data = load(data.txt);
%       >> [desdata1,ltsc1,stsc1] = deseasonalize(data,0,0,[7 6],1);
%       >> [desdata2,ltsc2,stsc2] = deseasonalize(data,1,3,[7 365],1);
%
%   Reference(s):
%   [1] R.Weron (2006) 'Modeling and Forecasting Electricity Loads and 
%   Prices: A Statistical Approach', Wiley, Chichester.   

%   Written by Rafal Weron (2009.02.10, rev. 2009.08.18, 2010.04.26)
%   Copyright (c) 2009-2010 by Rafal Weron

% set default values
if nargin<2, met1 = 2; end
if nargin<3, met2 = 0; end
if nargin<4, param = [7 8]; end
if nargin<5, plots = 1; end

data = data(:);
N = length(data);
ddata = zeros(N,1);

% remove LTSC
if met2 == 0,
    % set wavelet decomposition mode
    dwtmode('sp0','nodisp') 
    % wavelet smoothing
    [C,L] = wavedec(data,param(2)+2,'db24');
    ltsc = wrcoef('a',C,L,'db24',param(2));
else % sinusoid methods
    period = param(2);
    LTSCparam = fminsearch(@ltsc_scoref,ones(1,6)*10,[],data,period,met2);  
    x = (1:N)'/period;
    [RMSE,ltsc] = ltsc_scoref(LTSCparam,data,period,met2);
    if plots,
        % display RMSE and LTSC params
        disp(['RMSE = ' num2str(RMSE) ', LTSCparam = ' num2str(LTSCparam)])
    end
end
% remove LTSC
ddata = data - ltsc; 

% remove STSC
if met1<2,
    [ddata,stsc] = remmedian(ddata,param(1),met1);
else
    [ddata,stsc] = remst(ddata,param(1),-2);
end
% align min values of the raw and deseasonalized prices 
ddata = ddata + min(data) - min(ddata);
        
if plots,
    figure(1)
    subplot(2,1,1)
    plot(data,'k')
    hold on
    plot(ltsc,'linewidth',2)
    hold off
    set(gca,'xlim',[1 N])
    ylabel(['Price'])
    xlabel('Days')
    legend('Original data','LTSC')
        
    subplot(2,1,2)
    plot(data,'k')
    hold on
    plot(ddata,'r')
    hold off
    set(gca,'xlim',[1 N])
    ylabel(['Price'])
    xlabel('Days')
    legend('Original data','Deseasonalized data')
    
    figure(2)
    subplot(2,1,1)
    periodogram(data)
    title('Periodogram of original data')  
    subplot(2,1,2)
    periodogram(ddata)
    title('Periodogram of deseasonalized data')
end

%%%%%%%%%%%%% INTERNALLY USED ROUTINE %%%%%%%%%%%%%

function [y,s,means] = remmedian(X,d,meanmed);
%REMMEDIAN Remove mean- or median-based seasonal component.
%   Y = REMMEDIAN(X,D) returns time series X with removed 
%   mean-based seasonal component of period D. E.g. REMMEDIAN(X,7) 
%   returns daily data without the mean week as in [1], Section 2.4.2.
%   Y = REMMEDIAN(X,D,1) returns time series X with removed 
%   median-based seasonal component.  
%   [Y,S,MEANS] = REMMEDIAN(X,D) additionally returns the seasonal  
%   component S and the mean level MEANS of the seasonal component S.
%
%   Reference(s):
%   [1] R.Weron (2007) 'Modeling and Forecasting Electricity Loads and 
%   Prices: A Statistical Approach', Wiley, Chichester.   

%   Written by Rafal Weron (2005.08.07)
%   Copyright (c) 2005-2006 by Rafal Weron

if nargin<3,
   meanmed = 0;
end;
% Make a column vector
X = X(:);
% Make length X a multiple of d
N = length(X);
D = floor(N/d);
x = X(1:D*d); 
% Reshape data
rx = (reshape(x,d,D))';
if meanmed == 1,  
    mx = median(rx);    % meadian
else            
    mx = mean(rx);      % mean
end
% Seasonal component
means = mean(mx);
s = mx' - means;
S = repmat(s,D,1);
% Remove seasonal component
y = X - [S; S(1:N-D*d)];

%%%%%%%%%%%%% INTERNALLY USED ROUTINE %%%%%%%%%%%%%

function [RMSE,ltsc] = ltsc_scoref(A,data,period,fun)
%LTSC_SCOREF Long term seasonal component score function with square error. 

%   Written by Rafal Weron (2009.08.18)
%   Copyright (c) 2009 by Rafal Weron

N = length(data);
x = (1:N)'/period;
switch fun
    case 1      % sinusoid with linear trend
        ltsc = A(1).*sin( 2.*pi.*(x+A(2)) ) + A(3) + A(4)*x;
    case 2      % sinusoid with cubic trend
        ltsc = A(1).*sin( 2.*pi.*(x+A(2)) ) + A(3) + A(4)*x + A(5)*x.^2;
    case 3      % sinusoid with linear trend and linear amplitude
        ltsc = (A(1) + A(6)*x).*sin( 2.*pi.*(x+A(2)) ) + A(3) + A(4)*x;
    case 4      % sinusoid with cubic trend and linear amplitude
        ltsc = (A(1) + A(6)*x).*sin( 2.*pi.*(x+A(2)) ) + A(3) + A(4)*x + A(5)*x.^2;
    case 5      % 2 sinusoids with cubic trend and linear amplitude
        ltsc = (A(1) + A(6)*x).*( sin( 2.*pi.*(x+A(2)) ) + sin( pi.*(x+A(2)) ) )+ A(3) + A(4)*x + A(5)*x.^2;
end
% subtract level and compute score (sum of squared errors, SSE)
RMSE = ( mean( (abs(data - ltsc)).^2 ) )^0.5;
