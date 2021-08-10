function [y,s,P] = remst(X,d,degree,glue);
%REMST Remove seasonal component and trend.
%   Y = REMST(X,D,DEGREE) returns time series Y with removed polynomial 
%   trend of degree DEGREE and seasonal components of period D from vector 
%   X. REMST uses the moving average technique (see [1], Section 2.4.3).
%   Y = REMST(X,D,DEGREE,1) glues the first and last D/2 values to the end 
%   and the beginning of X, respectively (recommended for short time 
%   series, i.e. of length 2-3 D).
%   [Y,S,P] = REMST(X,D,DEGREE) returns seasonal component S and 
%   polynomial coefficients P.
%
%   If DEGREE==-1 then only seasonal components are removed. 
%   If DEGREE==-2 then only seasonal components are removed and the minimum 
%   values of the original and deseasonalized series are aligned.
%   If DEGREE is a vector it is treated as a one-period (i.e. of length D) 
%   seasonal component and is subtracted from X.
%
%   Reference(s):
%   [1] R.Weron (2007) 'Modeling and Forecasting Electricity Loads and 
%   Prices: A Statistical Approach', Wiley, Chichester.   

%   Written by Joanna Nowicka-Zagrajek and Rafal Weron (2001.01.27, rev. 2006.09.23)
%   Copyright (c) 2001-2006 by Rafal Weron

if nargin<4,
    glue = 0;
end;

% Make a column vector
X = X(:);

% Make length X a multiple of d
N = length(X);
D = floor(N/d);

% Perform computations if no seasonal component was provided
if length(degree)<2,
    if glue == 1, % glue first and last d/2 values to the series
        if (d/2) == floor(d/2)
            q = d/2;
        else
            q = (d-1)/2;
        end;
        x = [X(1:D*d)' X(1:2*q+1)']';
    else % use the original series
        x = X(1:D*d);
    end;

    n = length(x);
    m = zeros(n,1);

    % Calculate mean
    if (d/2) == floor(d/2), % even
        q = d/2;
        for t = q+1:n-q
            m(t) = sum([0.5*x(t-q) x(t-q+1:t+q-1)' 0.5*x(t+q)])/d;
        end;
    else % odd
        q = (d-1)/2;
        for t = q+1:n-q
            m(t) = mean(x(t-q:t+q));
        end;
    end;
    x = x(q+1:n-q);
    m = m(q+1:n-q);

    % Subtract the mean
    xm = x - m;
    w = zeros(d,1);
    for k = 1:d
        w(k) = mean(xm(k:d:end));
    end;

    % Compute seasonal component for one period
    s = zeros(d,1);
    for k = 1:d
        s(mod(k+q-1,d)+1) = w(k) - mean(w);
    end;

else  % DEGREE is the one-period seasonal component  
    s = degree;
    s = s(:);
end % if (length(degree)<2)

% Compute seasonal component for the whole series
ss = zeros(N,1);
for i = 0:D-1,
    ss(i*d+1:i*d+d) = s;
end;
ss(d*D+1:N) = s(1:(N-D*d));

% Perform computations if no seasonal component was provided
if (length(degree)<2),
    if degree < 0, 
        y = X - ss;
        P = [];
    else
        T = 1:N;
        P = polyfit(T',X-ss,degree);

        y = zeros(N,1);
        for t = 1:N,
            y(t) = X(t) - ss(t) - dot(P(degree+1:-1:1),[1 cumprod(ones(1,degree)*t)]);
        end;
    end;
    if degree == -2,
        y = y + min(X) - min(y);
    end
else % DEGREE is the one-period seasonal component 
    y = X - ss;
    P = [];
end