%%%% script to run 3D alignment (run DAD on real datasets)

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 1. Setup experiment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

setuppath
savevars = 0; % set to 1 if you want to save the results
numA = 180; %every 2 deg
Ts=.20; 
gridsz = 3;
numsol = 5; 
M1{1} = 'FA'; % dont need dr toolbox for factor analysis 
percent_test = 1;
numsteps=length(percent_test);
method = 'KL';
randseed = randi(100,1);
rng(randseed)
removedir = [0, 1, 2];
Ntot = 1027;
numIter = 1;

%%%%% user input
percent_samp = input('Amount to train on (scalar between 0,1): ');
supmethod = input('Enter 1 if you want to run the supervised method: '); 

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 2. Prepare training and test datasets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute firing rates and remove directions 
Data0 = prepare_superviseddata(Ts,'chewie1','mihi',[]);
Data = prepare_superviseddata(Ts,'mihi','mihi',[],0);
[~,~,~,XtrC,~,~,~,~] = removedirdata(Data0,removedir);
[Xtest,Ytest,Ttest,Xtrain,Ytrain,Ttrain,~,Ntrain] = removedirdata(Data,removedir);
clear Data Data0

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 3. Run DAD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize variables
R2M = zeros(1,numIter);
R2C = zeros(1,numIter);
R2MC = zeros(1,numIter);

R2Sup = zeros(2,numIter);
R2Ave = zeros(3,numIter);
 
for nn = 1:numIter % random train/test split
        
        % only uses 70% of neurons
        %permz = randperm(size(Ytr,2));
        %numNeurons = round(size(Ytr,2)*0.7);
        %[Xtr,Ytr,Ttr,Xte,Yte,Tte,trainid,testid] = splitdataset(Xtrain,Ytrain(:,permz(1:numNeurons)),Ttrain,Ntrain,percent_samp);  
        
        % uses all neurons
        [Xtr,Ytr,Ttr,Xte,Yte,Tte,trainid,testid] = splitdataset(Xtrain,Ytrain,Ttrain,Ntrain,percent_samp); 
        numte = size(Yte,1);
        permzte = randperm(numte);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Step 3A. Run 3D DAD (M)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        ResM = runDAD(Yte,Xtr,gridsz,Tte,Xte,method);
        R2M(nn) = ResM.R2;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Step 3B. Run 3D DAD (MC)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% now for augmented training
        ResMC = runDAD(Yte,[Xtr; XtrC],gridsz,Tte,Xte,method);
        R2MC(nn) = ResMC.R2;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Step 3C. Run 3D DAD (C)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % now chewie training only
        ResC = runDAD(Yte,XtrC,gridsz,Tte,Xte,method);
        R2C(nn) = ResC.R2;
        
        %%%% supervised & least-squares
        if supmethod==1
            fldnum=10; lamnum=500;
            [Wsup, ~, ~, ~]= crossVaL(Ytr, Xtr, Yte, lamnum, fldnum);
            Xsup = [Yte,ones(size(Yte,1),1)]*Wsup;
            r2sup = evalR2(mapX3D(Xte),mapX3D(Xsup));     
            warning off, Wls = (Yte\Xte); 
            r2ls = evalR2(mapX3D(Xte),mapX3D(Yte*Wls)); 
            R2Sup(:,nn) = [r2sup,r2ls];
        
            % compute average of DAD + Sup
            Xave = normal((ResM.V + mapX3D(Xsup))/2);
            r2avem = evalR2(mapX3D(Xte),Xave); 
            Xave = normal((ResMC.V + mapX3D(Xsup))/2);
            r2avemc = evalR2(mapX3D(Xte),Xave); 
            Xave = normal((ResC.V + mapX3D(Xsup))/2);
            r2avec = evalR2(mapX3D(Xte),Xave); 
            
            r2avetot = [r2avem,r2avemc,r2avec]; 
            
            display(['DAD (Sup), R2 = ', num2str(r2sup,3)])
            display(['DAD (LS), R2 = ', num2str(r2ls,3)])
            display(['DAD (Ave), R2 = ', num2str(max(r2avetot),3)])
            
            R2Ave(:,nn) = r2avetot; 
        end
        
        display(['DAD (M), R2 = ', num2str(ResM.R2,3)])   
        display(['DAD (MC), R2 = ', num2str(ResMC.R2,3)])    
        display(['DAD (C), R2 = ', num2str(ResC.R2,3)])
        
        display('***~~~~~~++++~+~+~+~+~++~+~+~***')  
               
end

% Figure - boxplot comparison of DAD and supervised approach
figure; boxplot([R2M; R2MC; R2C; R2Sup(1,:); R2Ave(1,:); R2Sup(2,:)]');
title([int2str(percent_train*100), '% train, ', num2str((1-percent_train)*100), '% test'])

% Figure - Visualization of 3D decoding
figure; 
subplot(1,3,1); colorData(Xte,Tte); title('Ground truth')
%subplot(1,3,1); colorData(ResM.V,Tte); title('Ground truth')


%%%%%%%%%% end script 
% output =  ResM (results of DAD-M)
%           ResMC (results of DAD-MC)
%           ResC (results of DAD-C)

