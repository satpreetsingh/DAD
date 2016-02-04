% script 3D alignment
% test synthetic + real data with same methods

%% (1) within subjects (iteration over different partitions of train/test sets)

% removedir = [0, 2, 7]; 

addname = input('Enter name for end of mat file (to save)');
removedir = [0, 2, 7];  %%%% 0.5 with few fails
A = 180; %every 2 deg
Ts=.20; 
percent_samp = 0.15;
numsteps = 9;
numsol = 5;
numIter = 100;
M1{1} = 'FA'; 
      

%%% prepare data
Data0 = prepare_superviseddata(Ts,'chewie1','mihi',[]);
Data = prepare_superviseddata(Ts,'mihi','mihi',[],0);
[~,~,~,XtrC,~,~,~,~] = removedirdata(Data0,removedir);
[Xtest,Ytest,Ttest,Xtrain,Ytrain,Ttrain,~,Ntrain] = removedirdata(Data,removedir);
clear Data Data0

% initalize variables
R2 = cell(numIter,1);
R2MC = cell(numIter,1);
minVal = cell(numIter,1);

% setup pool
p = gcp;
if isempty(p)
   parpool(8)
end

parfor nn = 1:numIter % random train/test split

        [Xtr,Ytr,Ttr,Xte0,Yte0,Tte0,trainid,testid] = splitdataset(Xtrain,Ytrain,Ttrain,Ntrain,percent_samp); 
        numte = size(Yte0,1);
        permzte = randperm(numte);
          
        R2X = zeros(3+numsol,numsteps);
        R2sup = zeros(1,numsteps);
        R2ls = zeros(1,numsteps);
        
        R2XMC = zeros(3+numsol,numsteps);
        R2supMC = zeros(1,numsteps);
        R2lsMC = zeros(1,numsteps);
        
        for mm = 1:numsteps % loop over amount of test data

            numtest = ceil(0.1*(mm+1)*numte);
            Xte = Xte0(permzte(1:numtest),:);
            Yte = Yte0(permzte(1:numtest),:);
            Tte = Tte0(permzte(1:numtest),:);

            %%%% supervised & least-squares
            fldnum=10; lamnum=500;
            [Wsup, ~, ~, ~]= crossVaL(Ytr, Xtr, Yte, lamnum, fldnum);
            r2sup = evalR2(Xte,[Yte,ones(size(Yte,1),1)]*Wsup);     
            % least squares error (best 2 dim projection)
            warning off, Wls = (Yte\Xte); r2ls = evalR2(Xte,Yte*Wls); 

            % throw away neurons that dont fire
            id2 = find(sum(Yte)<20); 
            Yr = Yte; 
            Yr(:,id2)=[];

            % dimensionality reduction
            [Vr,Methods] = computeV(Yr,3,M1);

            X3D = mapX3D(Xtr); % split (training set + extra chewie training for DAD)
            [Rtmp, ~] = run3Ddad(X3D,Vr,Xte,A,Methods,numsol);
            R2X(:,mm) = Rtmp;
            R2sup(mm) = r2sup; 
            R2ls(mm) = r2ls;
            
            X3D = mapX3D([Xtr; XtrC]); % split (training set + extra chewie training for DAD)
            [Rtmp, ~] = run3Ddad(X3D,Vr,Xte,A,Methods,numsol);
            
            R2XMC(:,mm) = Rtmp;
            R2supMC(mm) = r2sup; 
            R2lsMC(mm) = r2ls;

            display(['Supervised decoder, R2 = ', num2str(r2sup,3)])    
            display(['Least-squares Projection, R2 = ', num2str(r2ls,3)])
            display(['Num test = ', int2str(numtest), ' Iter # ', int2str(nn)])
        end
        
        tmp = [R2X;R2sup;R2ls];
        R2{nn} = tmp;
        
        tmp = [R2XMC;R2supMC;R2lsMC];
        R2MC{nn} = tmp;

end

R2order{1} = 'Xfinal';
R2order{2} = 'Xicp';
R2order{3} = 'Vfa';
R2order{4} = 'Vlocalmin';

save(['Results-2-3-2016-psamp-', int2str(100*percent_samp),'-', addname'])


%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%



