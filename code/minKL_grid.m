function Results = minKL_grid(V,X,angVals,sVals,method,k)
% minimize KL (rotation + scaling) over a normalized grid
% input = Y >> test dataset
% input = X >> kinematics data (target distribution)
% input = numA >> number of angles to sweep over

%% Step 0. Set things up

bsz = 50; % dimension of grid (for computing heat maps)

% default options (if not specified)
if nargin<5
    method = 'KL';
    k=[];
end

if nargin<6
    k=[];
end

% initialize variables
numS = length(sVals);
numA = length(angVals);

VLr  = cell(2*numA,1);
VLsc = cell(numS,1);
KLD = zeros(2*numA,1);
KLS = zeros(numS,1);

%% Step 1. Dimensionality reduction

% normalize embedding
mnV = mean(V);
V = normal(V-repmat(mnV,size(V,1),1));

Results.V = V;

%% Step 1. Find best rotation (grid search)

% compute heat map for training data
p_train = prob_grid(normal(X),bsz,k);
im_train = probmap2im(p_train,bsz); 
Results.Itrain = im_train;

% compute cosine for angles (angVals)
cosg = cos(angVals);
sing  = sin(angVals);

% grid search over rotation and flips of V
for p=1:2*numA
    pm = mod(p-1,numA)+1;
    ps = 2*floor((p-1)/numA)-1;
    rm = [ps,0;0,1]*[cosg(pm),-sing(pm);sing(pm),cosg(pm)];
    VLr{p} = V * rm;
    p_rot = prob_grid(normal(VLr{p}),bsz,k);
    
    if strcmp(method,'KL')
        KLD(p) = p_rot'*log(p_rot./p_train);
    elseif strcmp(method,'KL2')
        KLD(p) = p_train'*log(p_train./p_rot);
    elseif strcmp(method,'L2')
        im_rot = probmap2im(p_rot,bsz); 
        KLD(p) = norm(im_train(:)-im_rot(:))./norm(im_train(:));
    end
end 
[~, minInd ]   = min( KLD );
pm = mod(minInd-1,numA)+1;
ps = 2*floor((minInd-1)/numA)-1;
Results.RotMat = [ps,0;0,1]*[cosg(pm),-sing(pm);sing(pm),cosg(pm)];  

VrKLR  = VLr{minInd}; % find best rotation!
p_rot = prob_grid(normal(VrKLR),bsz,k);
Results.Irot =  probmap2im(p_rot,bsz); 
Results.Vrot  = VrKLR;

%flipInd = mod(minInd-1+numA,2*numA)+1;

% find next peak in divergence (next best solution)
[pks,KLid] = findpeaks(-KLD);
[~,id] = sort(pks,'descend');
flipInd = KLid(id(2));

VrKLRf  = VLr{flipInd}; % flipped version
Results.Vflip  = VrKLRf; 


%% Step 2. Find best scaling (grid search)
%%%% find best scaling 
for p=1:numS
    VLsc{p} = sVals(p)*VrKLR;
    p_rot = prob_grid(normal(VLsc{p}),bsz,k);
    
    if strcmp(method,'KL')
        KLS(p) = p_rot'*log(p_rot./p_train);
    elseif strcmp(method,'KL2')
        KLS(p) = p_train'*log(p_train./p_rot);
    elseif strcmp(method,'L2')
        im_rot = probmap2im(p_rot,bsz); 
        KLS(p) = norm(im_train(:)-im_rot(:))./norm(im_train(:));
    end
         
end

[minVal , minInd]   = min( KLS );
p_rot = prob_grid(normal(VLsc{minInd}),bsz,k);
Results.Iout =  probmap2im(p_rot,bsz); 
Results.Xrec  = VLsc{minInd};
Results.minVal = minVal; 

end % end main function

