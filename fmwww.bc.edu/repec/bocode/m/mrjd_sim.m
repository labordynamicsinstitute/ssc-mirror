function X = mrjd_sim(ntraj, T, x0, P)
%MRJD_SIM Simulate trajectories of a MRJD model.
%   X = MRJD_SIM(NTRAJ,T,X0,P) returns a vector of NTRAJ realizations of 
%   the Mean Reverting Jump Diffusion (MRJD) process:
%     dX = (alpha - beta*X)*dt + sigma*dB + N(mu,gamma)*dN(lambda) 
%	over a time period 0,1,...,T and an initial value X0. 
%   The timestep dt is set to 1. The Euler scheme is used.
%   P = [ALPHA,BETA,SIGMA,MU,GAMMA,LAMBDA] is the parameter vector.
%
%   Sample use:
%       >> r = mrjd_sim(10,1000,5,[.5,.1,.2,4,1,.01]);
%       >> plot(r')

%   Written by Rafal Weron (2007.11.23)
%   Revised by Rafal Weron (2010.11.08)
%   Copyright (c) 2007-2010 by Rafal Weron

% Initialize output matrix
X = zeros(ntraj,T+1);
X(:,1) = repmat(x0,ntraj,1);

% Diffusion (normal) noise
r = randn(ntraj,T);

% Jump occurences 
rjump = rand(ntraj,T);

alpha = P(1); beta = P(2); sigma = P(3); mu = P(4); gamma = P(5); lambda = P(6);

for j=1:ntraj,
    for i=1:T,
        if rjump(j,i)>lambda, 
            % No jump
            X(j,i+1) = X(j,i) + alpha - beta*X(j,i) + sigma*r(j,i);
        else                        
            % Jump
            X(j,i+1) = X(j,i) + alpha - beta*X(j,i) + mu + sqrt(gamma^2+sigma^2)*r(j,i);
        end
    end;
end
