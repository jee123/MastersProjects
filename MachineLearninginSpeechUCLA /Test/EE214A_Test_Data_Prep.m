clear all;
clc;
%--------------------------
% Define parameter
%--------------------------
frameShift = 0.001;     % [sec]

NumFeatures = 71;        % Number of features  
%NumFolds = 5;           % Number of cross validation folds
NumTrees =30;

%--------------------------
% Get label
%--------------------------
load('dataLabel.mat')
load('crossValIdx.mat')
NumPairs = size(dataLabel,1);
NumFolds = size(crossValIdx,2);

x = NaN*ones(NumPairs, NumFeatures);  % features
y = NaN*ones(NumPairs, NumFeatures);  % variable to predict
z = NaN*ones(NumPairs, 1);  % class label

for n=1:NumPairs
    waitbar(n/NumPairs)
    %--------------------------
    % Read sound files
    %--------------------------
    
    % NEW MATLAB VERSION
    
    [snd1,Fs1] = audioread(['WavData/' dataLabel{n,1} '.wav']);
    [snd2,Fs2] = audioread(['WavData/' dataLabel{n,2} '.wav']);
    
    if Fs1~=Fs2
        warning('The sounds do not have same sampling rate')
    else
        Fs=Fs1;
    end
    
    %--------------------------
    % Extract feature
    %--------------------------
    datalen1 = floor(length(snd1) / Fs  / frameShift);
    datalen2 = floor(length(snd2) / Fs  / frameShift);
    
    % Fundamental frequency (Using MBSC)
    [F0_1, ~] = fast_mbsc_fixedWinlen_tracking(snd1, Fs1);
    [F0_2, ~] = fast_mbsc_fixedWinlen_tracking(snd2, Fs2);
    
    % Averaged F0
    mF0_1 = nanstd(F0_1(F0_1>0));
    mF0_2 = nanstd(F0_2(F0_2>0));
    load(['Formants/' dataLabel{n,1} '.mat']);
    F1_1 = sF1;
    F2_1 = sF2;
    F3_1 = sF3;
    F4_1 = sF4;
    
    % Formants
    clear sF1;
    load(['Formants/' dataLabel{n,2} '.mat']);
    F1_2=sF1;
    F2_2 = sF2;
    F3_2 = sF3;
    F4_2 = sF4;
    
    % H1-H2
    load(['H1-H2/' dataLabel{n,1} '.mat']);
    H1H2c_1 =H1H2c; 
    
    
    load(['H1-H2/' dataLabel{n,2} '.mat']);
    H1H2c_2 =H1H2c; 
  
    %CPP
    load(['CPP/' dataLabel{n,1} '.mat']);
    cpp_1 =CPP; 
    
    load(['CPP/' dataLabel{n,2} '.mat']);
    cpp_2 =CPP; 
    
    %HNR
    load(['HNR/' dataLabel{n,1} '.mat']);
    hnr05_1 =HNR05; 
    
    load(['HNR/' dataLabel{n,2} '.mat']);
    hnr05_2 =HNR05; 
    
    % MFCC
    [c_1,tc_1] = melcepst(snd1,Fs1,'M',13);
    [c_2,tc_2] = melcepst(snd2,Fs2,'M',13);
    
    % LPC
    [ar_1,e_1] = lpc(snd1,50);
    [ar_2,e_2] = lpc(snd2,50);
    
    lpcc_1=lpc2lpcc(ar_1(1,2:size(ar_1,2)),size(ar_1,2)-1);
    lpcc_2=lpc2lpcc(ar_2(1,2:size(ar_2,2)),size(ar_2,2)-1) ;
    
    %--------------------------
    % Save into variables
    %--------------------------
    x(n,1) = abs(nanmean(F0_1) - nanmean(F0_2)); % Use the difference between mean pitch
    x(n,2) = abs(nanmean(F1_1) - nanmean(F1_2));
    x(n,3) = abs(nanmean(F2_1) - nanmean(F2_2));
    x(n,4) = abs(nanmean(F3_1) - nanmean(F3_2));
    x(n,5) = abs(nanmean(F4_1) - nanmean(F4_2));
    x(n,6) = abs(nanmean(H1H2c_1) - nanmean(H1H2c_2));
    x(n,7) = abs(nanmean(cpp_1) - nanmean(cpp_2));
    x(n,8) = abs(nanmean(hnr05_1) - nanmean(hnr05_2));
    x(n,9:8+size(c_1,2)) = abs(mean(c_1) - mean(c_2));
    %x(n,22:21+50) =abs((ar_1(1,2:size(ar_1,2))) - (ar_2(1,2:size(ar_2,2))));
    x(n,22:21+50) =abs((lpcc_1) - (lpcc_2));
    y(n,:) = dataLabel{n,3}; % perceptual dis-similarity
    z(n) = dataLabel{n,4}; % intra-speaker indicator
    
end
test_x=x;
test_y=y;
test_z=z;
save('testVariable.mat','test_x','test_y','test_z');
load('testVariable.mat');
h=waitbar(0,'Classification and Regression in progress......');
load('variable.mat')
NumFolds =1;
rmsErr = NaN*ones(NumFolds,NumFeatures);
errRate= NaN*ones(NumFolds,1);
NumTrees = [100 200 300 400 500 600 700 800 900 1000];
%for i =1:size(NumTrees,2)
for n=1:NumFolds
    waitbar(n/NumFolds)
    % features
    
    x_train = x(:,:);   % Takes the index where cross =0 that is, train on speech by diff speakers.
    x_test  = test_x;
    
    
    % perceptual dissimilarity label
    y_train = y(:,:);
    y_test  = test_y;
    
    % intra-speaker indication label
    
    z_train = z(:,:);
    z_test  = test_z;
  
    %--------------------------
    % Linear regression
    %--------------------------
    
    %Modify your code here >>>>>>>>>>>>>>>>>>>>>>>>>>>>

    RegressionModel = fitensemble(x_train,y_train(:,1),'Bag',200,'Tree', 'Type','Regression');
    %p = polyfit(x_train(:,9:71),y_train(:,9:71),3);
    %f = polyval(p,x_test(:,9:71));
    f = predict(RegressionModel,x_test);
    
    
    err = y_test(:,1)-f;
    rmsErr(n,1) = mean(sqrt( mean( (err).^2) ));
    
    %rmsErr(n,2) = sqrt( mean( err(:,2).^2) );
%     if (i==1)
%         Model = fitNaiveBayes(x_train,z_train);
%     elseif(i==2)
%         Model = fitcsvm(x_train,z_train,'Kernelfunction','Linear');
%     else
%         Model = fitensemble(x_train,z_train,'AdaBoostM1',100,'Tree');
%     end
    %--------------------------
    % Ensemble Classifier
    %--------------------------
    Model = fitensemble(x_train,z_train,'AdaBoostM1',100,'Tree');
    z_test_hat = predict(Model,x_test);
    
    %% <<<<<<<<<<<<<<<<<<<<<<<<<<<<<  Modify your code here
    
    err = (z_test_hat) ~= z_test;
    errRate(n,1) = sum(err)/length(z_test);
    
end
% rmsErrorArr(i,1) =nanmean(nanmean(rmsErr));
% classArray(i,1) = 100* mean(errRate)
fprintf('Averaged RMS = %.2f\n', nanmean(nanmean(rmsErr)));
fprintf('Averaged Classification Error = %.2f %% \n', 100* mean(errRate));
delete(h);
perceptualDissimilarity = f;
labelsTest = z_test_hat
save('output.mat','perceptualDissimilarity','labelsTest')
%end