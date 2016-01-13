function KLD = evalKL(X,Y,k,rhoX)

if nargin<4
    k=ceil(size(X,1)^0.3);
end
    
dMatT=getDist(X,Y);
[sdMatT,~]=sort(dMatT);
sdMat=sdMatT;
rhoY=sdMat(k,:);
%KLD = mean( log( rhoY ./ rhoX ) ) +log( scaleparam );
KLD = mean( log( rhoY ./ rhoX ) );

end
