function [pvalesallm,Results]=AnnInptSigTest(y,x)

%--------------------------------------------------------------------------
% This code tests the statistical significance of inputs by using an 
% artificial neural network with a flexible structure. The code tries to find 
% the best number of neurons for the neural network for testing significance 
% of inputs, if you do not have any idea about number of neurons, please press 
% OK button for running with default values. Nrepit is for stabilizing results.
% Because of different initial values for the neural network,result of the 
% test changes at each time of running. A Higher number of Nrepit may 
% stabilize the results but running time will be longer. 

% Inputs: 
% Variable y is dependent or target variable, and X stands for independent 
% or input variable. The

% Outputs:
% Pvalesmall is probability values(significance level) of inputs and
% results is pvalesmall in a table format.

% Ref: Mohammadi, S.(2018), A new test for the significance of neural network
% inputs, Neurocomputing 273 (2018) 304-322. 

% Copyright(c) Shapour Mohammadi, University of Tehran, 2018.
% shmohmad@ut.ac.ir

% Keywords: Neural Networks, Input Significance Test,Nonlinear models,
% Nuisance parameters, Variable selection,Pruning of Neural Networks. 
%--------------------------------------------------------------------------


%-----------------------Preprocessing of Data------------------------------
% Suppressing probable warnings.
warning('off')

% To make data to cloumn vector
[rowsx, columsx]=size(x);
if rowsx>columsx
    x0=[];
for i=1:columsx
    x0(i,:)=x(:,i);
end
    y=y(:)';
    x=x0;
end

% Discarding NaN values
index0=isnan(x(end,:));
index=find(index0==1);
if length(index)>0
maxindex=max(index)+1;
x=x(:,maxindex:end);
y=y(:,maxindex:end);
end
[rowsx, columsx]=size(x);

%------Diallog box for choosing architecure of neural network by user------

prompt = {'Maximum Number of Neurons for the 1st Hidden Layer(Large numbers take much more time):',...
    'Maximum Number of Neurons for the 2nd Hidden Layer(Large numbers take much more time):',...
    'Activation Function1(e.g. tansig,logsig,...)','Activation Function2(e.g. tansig,logsig,...)',...
    'Training Algorithm(e.g. trainbr,trainlm,...',...
    'Number of Initial Weights(Large numbers take much more time):'};
dlg_title = 'Network Architecture:For Running Code with Default Values Press OK';
defaultans = {'10','0','tansig','tansig','trainbr','30'};
paramvalues= inputdlg(prompt,dlg_title,[1 100],defaultans);

h = waitbar(0,'Please wait','Name','Number of Trained Networks');

Nernum1=str2double(paramvalues{1});
Nernum2=str2double(paramvalues{2});
ActivationFun1=paramvalues{3};
ActivationFun2=paramvalues{4};
TrainingAlgo=paramvalues{5};
Nrepit=str2double(paramvalues{6});


%----Finding the best number of neurons for a one layer neural network-----

 if Nernum2==0   
for j=1:Nernum1
       netallinp=fitnet(j,TrainingAlgo);
       netallinp.layers{1}.transferFcn = ActivationFun1;
       netallinp.trainParam.showWindow = false;
       netallinp.trainParam.showCommandLine = false;
       netallinp.trainParam.epochs=500;
       netallinp=train(netallinp,x,y);
       yj=netallinp(x);
       numpram=j*(rowsx+2)+1;
       sig2=((y-yj)*(y-yj)')/(columsx-numpram);
       SBC(j,1)=log(sig2)+numpram*log(columsx)/columsx;
 end

indner=find(SBC==min(SBC));
 end

 % Finding the best number of neurons for a two layers neural network.
 if Nernum2>0
    for j=1:Nernum1
        for i=1:Nernum2
          netallinp=fitnet([j i],TrainingAlgo);
          netallinp.layers{1}.transferFcn = ActivationFun1;
          netallinp.layers{2}.transferFcn = ActivationFun2;
          netallinp.trainParam.showWindow = false;
          netallinp.trainParam.showCommandLine = false;
          netallinp.trainParam.epochs=500;
          netallinp=train(netallinp,x,y);
          yj=netallinp(x);
          numpram=j*(rowsx+1)+j+i*(j+1)+i+1;
          sig2=((y-yj)*(y-yj)')/(columsx-numpram);
          SBC(j,i)=log(sig2)+numpram*log(columsx)/columsx;
        end
    end
         SBCmin=min(min(SBC));
         
         for j=1:Nernum1
             for i=1:Nernum2
                 if SBC(j,i)==SBCmin
                     indner1=j;
                     indner2=i;           
                 end   
             end
         end         
 end 
    
%-----Training Nrepit numbers of neural networks for taking to account 
% different initial values-------------------------------------------------

YHATM=zeros(columsx,rowsx);
for kk=1:Nrepit
if Nernum2==0 
    net=fitnet(indner,TrainingAlgo);
    net.layers{1}.transferFcn = ActivationFun1;
elseif Nernum2>0 
    net=fitnet([indner1 indner2],TrainingAlgo); 
    net.layers{1}.transferFcn = ActivationFun1;
    net.layers{2}.transferFcn = ActivationFun2;
end

net.trainParam.epochs=500;
net.trainParam.showWindow = false;
net.trainParam.showCommandLine = false;
net=train(net,x,y); 

meanx=mean(x,2);
omatrix=ones(1,columsx);
YHAT=zeros(columsx,rowsx);
for  i=1:rowsx
    
    %Getting regressors after fixing all variable except the variable
    %subject to the test in their mean level.
    if i==1
    X=[x(i,:); kron(meanx(i+1:end),omatrix)];
    elseif i==rowsx
    X=[kron(meanx(1:i-1,:),omatrix);x(i,:)];    
    else
    X=[kron(meanx(1:i-1,:),omatrix);x(i,:);kron(meanx(i+1:end,:),omatrix)];
    end
    
    
   yhat=sim(net,X);
   
   % Because neural networks generate some extreme values in this section 
   % observations with more 3sigma deviation from mean is replaced by the  
   % mean of the variable for getting more stable results.
   myhat=mean(yhat);
   stdyhat=std(yhat);
   
  
   yhat(abs(yhat-myhat)>3*stdyhat)=myhat;
   YHAT(:,i)=yhat';
    
end

YHATM=YHATM+YHAT;


 waitbar(kk / Nrepit,h,sprintf('%d',kk))
end

[mohstats]=moholsforann(y',[ones(length(y'),1) YHATM/Nrepit]);
pvals=mohstats{3,1};
Pvalesall=pvals(2:end);
pvalesallm=Pvalesall;
close(h)

%-------------------Printing Results in Command Window---------------------
disp(' ')
disp(['                    ','H0','                        ', 'Pvalues',...
    '    ','Conclusion About H0'])
disp(['------------------------------------------','    ','---------',...
    '  ','----------------------'])
for i=1:length(pvalesallm)
name = 'X'; 
indice=i;
if pvalesallm(i,1)>0.1
    concl='H0 cannot be rejected';
elseif  pvalesallm(i,1)<0.01
    concl='H0 is rejected at 1%';
    
elseif  pvalesallm(i,1)<0.05
    concl='H0 is rejected at 5%';
elseif  pvalesallm(i,1)<0.10
     concl='H0 is rejected at 10%';
end
disp([sprintf('%s%d does not have a significant effect on',name,indice),...
    ' ','y','    ',sprintf('%0.5f',pvalesallm(i,1)),'    ',concl]);
end
disp(' ')
name2=[];
for i=1:length(pvalesallm)
name2=[name2 {(sprintf('X%d', i))}];
end

Results = table(pvalesallm);
Results.Properties.VariableNames = {'PValues'};
Results.Properties.RowNames = name2;

%-----A Fast Function for Estimation by Ordinary Least Squares Method------
function [mohstats]=moholsforann(y,x)
[rx, cx]=size(x);
betaols=x\y;
yfit=x*betaols;
e=y-yfit;
sigma2hat=e'*e/(rx-cx);
VC=sigma2hat*(x'*x)^(-1);
SEbeta=(diag(VC)).^.5;
tstudent=betaols./SEbeta;
nu=rx-cx;
pvalues=2*(1-tcdf(abs(tstudent),nu));     
R2=1-e'*e/((y-mean(y))'*(y-mean(y)));
mohstats{1,1}=betaols;
mohstats{2,1}=tstudent;
mohstats{3,1}=pvalues;
mohstats{4,1}=SEbeta;

%------------------------------END-----------------------------------------


