function Data = preparedata_chewiemihi(delT,removelabel)

if nargin<2
    removelabel=[];
end


% Load neural (Y) and movement (X) datasets
load Chewie_12192013;
Dtrain1= out_struct;

load Chewie_10032013;
Dtrain2= out_struct;

load Mihi_small;
Dtest=out_struct;

% compute firing rates from spike data
tttr1  = ff_trial_table_co(Dtrain1);
tttr2  = ff_trial_table_co(Dtrain2);
ttte  =  ff_trial_table_co(Dtest);

[Data.Y1   , X1 ,  T1,  N1]  =  getFR(Dtrain1,  delT,  tttr1 );
[Data.Y2   , X2 ,  T2,  N2]  =  getFR(Dtrain2,  delT,  tttr2 );
[Y3   , X3 ,  T3,  N3]  =  getFR(Dtest,   delT,  ttte );
Data.Y3 = Y3;

clear Dtrain1
clear Dtrain2
clear Dtest

XN1=normal(X1);
XN2=normal(X2);
Xtr=[ XN1; XN2 ];
Ttr=[ T1; T2 ];
Ntr=[N1; N2];

dsz=size(Y3,1);
dsz1=round(dsz/3);

% Yte=Y3(dsz1+1:end, :);
% Xte=X3(dsz1+1:end, :);
% Tte=T3(dsz1+1:end, :);
% Nte=N3(dsz1+1:end, :);

Yte=Y3;
Xte=X3;
Tte=T3;
Nte=N3;




tindte = [];
tindtr = [];
if ~isempty(removelabel)
    for i=1:length(removelabel)
        tindte= [tindte, find(Tte == removelabel(i))'];
        tindtr= [tindtr, find(Ttr == removelabel(i))'];
    end
end
    
tindte = setdiff(1:length(Tte),tindte);
tindtr = setdiff(1:length(Ttr),tindtr);

Data.Xtrain= Xtr(tindtr,:);
Data.Ttrain= Ttr(tindtr,:);
Data.Ntrain= Ntr(tindtr,:);

Data.Ttest=Tte(tindte);
Data.Ytest=Yte(tindte,:);
Data.Xtest=Xte(tindte,:);
Data.Ntest=Nte(tindte,:);

end