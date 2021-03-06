function [Y,TC] = simmotorneurons(X,N,model,linkfn)
% X is a T x 2 matrix (kinematics)
% N = number of neurons to simulate
% Ts = sampling period (X)
% parameters are optimized for samp. period Ts = 0.2 (200 ms)

if nargin<4
    linkfn = 'exp';
end

if nargin<3
    model = 'base';
end

T = size(X,1);
magV = norms(X')';
theta_dir = atan2(X(:,2),X(:,1));
pref_dir = 2*pi*rand(N,1);

In = zeros(T,N);
for i=1:N
    % (0) original model (from kk)
    %In(:,i) = amod(i)*magV./mean(magV).*cos(theta_dir - pref_dir(i)) ;
    
    % (1) creates circular embedding (no x0)
    %In(:,i) = cos(theta_dir - pref_dir(i)); 
    
    % (2) creates smashed distribution (separable clusters but warped) (no x0)
    % In(:,i) = (magV./max(magV)).*cos(theta_dir - pref_dir(i)); 
    
    % (3) creates more separable clusters than (2) (no x0)
    % In(:,i) = (magV./mean(magV)).*cos(theta_dir - pref_dir(i)); 
    
    % (4) creates inseparable clusters (smashed into center) 
    % In(:,i) = magV./norm(magV).*cos(theta_dir - pref_dir(i));
    
    % (5) creates garbage
    %amod = randn(N,1);
    %In(:,i) = amod(i)*magV.*cos(theta_dir - pref_dir(i)) + x0(i);
    
    % (6) creates clusters with spread similar to real data 
    % (USE FOR SIMULATIONS)
    if strcmp(model,'base')
        amod = ones(N,1);
        %x0 = randn(N,1)*0.05;
        x0 = ones(N,1)*2;
        In(:,i) = (1/mean(magV))*magV.*cos(theta_dir - pref_dir(i)) + x0(i);
    
    elseif strcmp(model,'modbase')
        % (7) added modulation and baseline
        amod = ones(N,1)+randn(N,1)*0.02; 
        x0 = randn(N,1)*0.05;
        In(:,i) = amod(i)*(1/mean(magV))*magV.*cos(theta_dir - pref_dir(i)) + x0(i);
        
    elseif strcmp(model,'3D')
        % (7) added modulation and baseline + speed
        amod = ones(N,1)+randn(N,1)*0.02; 
        cspeed = ones(N,1)+randn(N,1)*0.05; 
        x0 = randn(N,1)*0.05;
        In(:,i) = amod(i)*(1/mean(magV))*magV.*cos(theta_dir - pref_dir(i)) + x0(i) + cspeed(i)*(1/mean(magV))*magV;
    else
       error('That model doesnt exist!!!!')
    end
    
    % (7) creates garbage
    %amod = randn(N,1); x0 = randn(N,1)*0.05;
    %In(:,i) = amod(i)*magV.*cos(theta_dir - pref_dir(i)) + x0(i);
    
end

if strcmp(linkfn,'exp')
    Y = poissrnd(exp(In));
else
    Y = poissrnd(max(0,In));
end

TC.amod = amod;
TC.x0 = x0;
TC.pref_dir = pref_dir;

end