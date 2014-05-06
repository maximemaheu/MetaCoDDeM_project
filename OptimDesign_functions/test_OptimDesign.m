clear all; close all

% Set the chancelevel used within the sigmoid:
chancelevel = 0.5; % 0 0.5 1/24
sigmoid_binomial_nogradients(chancelevel);

DATA.Fit.Psychometric.Func = @sigmoid_binomial_nogradients; %(u,Phi) sigm(u,struct('G0',1,'S0',0,'beta',1,'INV',0),Phi);

DATA.Fit.Psychometric.Estimated = [log(10);0.5];
DATA.Fit.Psychometric.EstimatedVariance = diag([log(10),10])%1e2*eye(2);

DATA.Fit.Psychometric.GridU = 0:1e-2:1;
%DATA.Fit.Psychometric.GridU = 10.^[-5:.1:0]

% Initialize the bayesian gas factory
OptimDesign('initialize', ...
    DATA.Fit.Psychometric.Func, ...
    DATA.Fit.Psychometric.Estimated, ...
    DATA.Fit.Psychometric.EstimatedVariance, ...
    DATA.Fit.Psychometric.GridU);

phi_target = [log(20*rand);.4*rand+.1];
%phi_target = [log(30);.2392];

NTrials = 100;
efficiency = zeros(NTrials,1);

initial_grid = [];

% Prepare the graph window
x = min(DATA.Fit.Psychometric.GridU):0.001:max(DATA.Fit.Psychometric.GridU);
%y_target = sigmf(x, phi, chancelevel);
y_target = sigmoid_binomial_nogradients([],phi_target,x);
fig = figure(1);
plot(x, y_target, 'r-.');
hold on
plot(x, chancelevel, 'r:');
hold on
axis([min(DATA.Fit.Psychometric.GridU), max(DATA.Fit.Psychometric.GridU), 0, 1]);

pseudo_subject = @(phi,c) ...
    sampleFromArbitraryP([DATA.Fit.Psychometric.Func([],phi,c),1-DATA.Fit.Psychometric.Func([],phi,c)]',[1,0]',1);

% This is our Pseudo subject
%proba(t)  = DATA.Fit.Psychometric.Func([],phi_target,DATA.Paradigm.Phasis1.Coherences(Trial_number),[]);
% Response by this pseudo subject
%[y(t)] = sampleFromArbitraryP([proba(t),1-proba(t)]',[1,0]',1);


% First: N trials
Grid_init = [];%repmat(.1:.1:.5,1,4);
N_init = numel(Grid_init);
for i=1:N_init
    y(i) = pseudo_subject(DATA.Fit.Psychometric.Estimated,Grid_init(i));
    DATA.Paradigm.Phasis1.Coherences(i) = Grid_init(i);   
    DATA.Answers.Correction(i,1) = y(i);
    OptimDesign('register',y(i),Grid_init(i),i);
end

% At each trial
for Trial_number = (N_init+1):NTrials
    
    if (size(initial_grid, 1) ~= 0)
        % update MBB-VBA with it befor starting optimization
    end
    
    [DATA.Paradigm.Phasis1.Coherences(Trial_number),efficiency(Trial_number)] = OptimDesign('nexttrial');
    
    fprintf('Trial %d\n',Trial_number);
    t = Trial_number;
    
    y(t) = pseudo_subject(phi_target,DATA.Paradigm.Phasis1.Coherences(Trial_number));
    DATA.Answers.Correction(Trial_number,1) = y(t);
    
    % Register
    OptimDesign('register',DATA.Answers.Correction(Trial_number,1));
    
    % Monitor
    [DATA.Fit.Psychometric.Parameters(:,Trial_number)] = OptimDesign('results');
    DATA.Fit.Psychometric.Parameters(:,Trial_number)
    
    Phi = DATA.Fit.Psychometric.Parameters(:,Trial_number);
    
    %s = 1/(1-chancelevel);
    %th = Phi(2);
    %beta = exp(Phi(1));
    %beta_min = atan((chancelevel+1)/(2*th));
    %beta = s.*(beta_min + beta);
    
    %y_arrow = sigmf(x, [beta;th], chancelevel);
    y_arrow = sigmoid_binomial_nogradients([],Phi,x);

    % Display the bayesian guess
    try
    if (Trial_number > N_init+1)
        delete(bayesian_guess);
    end
    bayesian_guess = plot(x, y_arrow, 'b-');       
    bayesian_guess(2) = bar(0.05:.05:1,histc([DATA.Paradigm.Phasis1.Coherences],[0.05:.05:.95 1])/100);
    bayesian_guess(3) = bar(0.05:.05:1,histc([DATA.Paradigm.Phasis1.Coherences(y==1)],[0.05:.05:.95 1])/100,'FaceColor','g');
    %bayesian_guess(4) = plot([DATA.Paradigm.Phasis1.Coherences(y==1)],.2+rand(sum(y==1),1)/10,'og')
    %bayesian_guess(4) = plot([DATA.Paradigm.Phasis1.Coherences(y==0)],.1+rand(sum(y==0),1)/10,'or')
    drawnow
    end
    
%fit=OptimDesign('state');


end                    

[DATA.Fit.Psychometric.muPhi,DATA.Fit.Psychometric.SigmaPhi] = OptimDesign('results');

DATA.Fit.Psychometric.Quality = [abs(DATA.Fit.Psychometric.muPhi(1) - phi_target(1));abs(DATA.Fit.Psychometric.muPhi(2) - phi_target(2))];
DATA.Fit.Psychometric.Quality