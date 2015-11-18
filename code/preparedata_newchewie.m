function Data = preparedata_newchewie(Dtr1,Dte,delT,removelabel)

if nargin<3
    removelabel=[];
end

tttr1  = ff_trial_table_co(Dtr1);
ttte  =  ff_trial_table_co(Dte);

[~   , X1 ,  T1,  N1]  =  getFR(Dtr1,  delT,  tttr1 );
[Y3   , X3 ,  T3,  N3]  =  getFR(Dte,   delT,  ttte );

clear Dtr1
clear Dte

XN1=normal(X1);

Xtr= XN1;
Ttr= T1;
Ntr= N1;

dsz=size(Y3,1);
dsz1=round(dsz/3);

Yte=Y3(dsz1+1:end, :);
Xte=X3(dsz1+1:end, :);
Tte=T3(dsz1+1:end, :);
Nte=N3(dsz1+1:end, :);

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

Data.Xtrain = Xtr(tindtr,:);
Data.Ttrain = Ttr(tindtr,:);
Data.Ntrain = Ntr(tindtr,:);

Data.Xtest = Xte(tindte,:);
Data.Ytest = Yte(tindte,:);
Data.Ttest = Tte(tindte,:);
Data.Ntest = Nte(tindte,:);

end
