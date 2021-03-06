% RL_ModelALL Runs all 3 types of model
    %1.) Per individual per condition
    %2.) All individuals per condition
    %3.) All individuals all conditions

% 7 types of models are currently available
%1.) Classic model with 2 parameters, alpha and beta
%2.) Classic model with 2 alphas for - and + Pe
%3.) Classic model with 2 alphas for - and + Pe, letting intial Q vary
%4.) Classic model with 2 alphas for - and + Q
%5.) Classic model with additional d parameters
%6.) Actor Critic model with 4 parameters, alphaA, AlphaC, d and beta
%7.) Hybrid AC/Q model with 6
    %Classic model with alphaQ
    %AC model with alphaA and alphaC
    %with outside parameters d,c and beta

% Model fit works by using fmincon to find the local minima (highest probability of state | action)
%from the randomized starting free parameter. The model is rurun multiple
%times to find the global minima.

%out - outgoing parameters of best fit, cell array 1x5

%QL - Free Parameters
%Ev - Expected value [q,w,v]
%Pe - Prediction Error
%PseudoR - Model Fitness
%AIC - Model comparison fitness

%Deci - Configuration File parameters
%.Folder.Analysis - Folder where all analysis data is saved
%.SubjectList - List of subject
%.Analysis.CondTitle - List of conditions

%info - Unique parameters for this instance of function run
%.subject_list - current subject index
%.Cond - current condition index

%dat - Output of step 3 from Deci, fieldtrip data file
%Artifact trial rejected
% Function is usually called from Analyzor line 172 so you can read
% how Analyzor loads an example Step 3 datafile.

%params - Free variables depending on model
%.State - Event code for all possible conditions
%.Actions - Event code for all possible Actions
%.Reward - Event code for all possible Rewards
%.Value - Value for each rewardxstate combo, cell format
%.Reps - number of iterations to run randomized starting free
%parameters
%.ModelNum - number array of models to run
%.Start - Starting Intial Expected Value for q,w,v
%.Seed - rng seed;

%Ex:
%params.States = [20 21 23 24];
%params.Value  = {[20 10] [10 0] [0 -10] [-10 -20]};
%params.Actions = [31 32];
%params.Reward  = [51 52];
%params.Start = {[0 0],[.01 .01],[0]};


trialtypes = dat.events;

%Basic Data Maintence for finding block numbers
% Deci segments blocks by negative numbers
if any(any(trialtypes < 0))
    trialtypes(:,find(trialtypes(1,:) < 1)) = ceil(trialtypes(:,find(trialtypes(1,:) < 1)));
    blocknumbers = sort(unique(trialtypes(:,find(trialtypes(1,:) < 1))),'descend');
else
    blocknumbers = -1;
end

Values = find(ismember(params.States,trialtypes));

%Sorting data into blocks
for blk = 1:length(blocknumbers)
    
    blkmrk = sum(ismember(trialtypes,[blocknumbers(blk)]),2) ==  1;
    
    Actmrk = logical(sum(ismember(trialtypes(blkmrk,:),[params.Actions]),1));
    Actions{blk} = trialtypes(blkmrk,Actmrk);
    
    Rewmrk = logical(sum(ismember(trialtypes(blkmrk,:),[params.Reward]),1));
    Rewards{blk} = trialtypes(blkmrk,Rewmrk);
    
    for rew = 1:length(params.Reward)
        Rewards{blk}(Rewards{blk} == params.Reward(rew)) = params.Value{Values}(rew);
    end
    
end

% Loop for running models N times with randomized starting conditinos

LLE = nan([7 params.Reps]);
LLE2 = nan([7 params.Reps]);


%1.) Classic model with 2 parameters, alpha and beta
%2.) Classic model with 2 alphas for - and + Pe
%3.) Classic model with 2 alphas for - and + Pe, letting intial Q vary
%4.) Classic model with 2 alphas for - and + Q
%5.) Classic model with additional d parameters
%6.) Actor Critic model with 4 parameters, alphaA, AlphaC, d and beta
%7.) Hybrid AC/Q model with 6
    %Classic model with alphaQ
    %AC model with alphaA and alphaC
    %with outside parameters d,c and beta

rng(params.Seed)

%try

ColNames = {};
SheetNames = {};

    for init = 1:params.Reps
        
        
        %1.) Classic model with 2 parameters, alpha and beta
        
         if ismember(1, params.ModelNum)
            Model1.LB = [0 1e-6];
            Model1.UB = [1 30];
            Model1.init =rand(1,length(Model1.LB)).*(Model1.UB-Model1.LB)+Model1.LB;
            
            
            [Value{1,init}] = ...
                fmincon(@(x) SimpleQ(params.Start{1},params.Actions,Actions,Rewards,x(1),x(2)),...
                [Model1.init],[],[],[],[],[Model1.LB],[Model1.UB],[],...
                optimset('TolX', 0.00001, 'TolFun', 0.00001, 'MaxFunEvals', 9e+9, 'Algorithm', 'interior-point','Display','off'));
            
            [LLE(1,init),out{1,init}] = SimpleQ(params.Start{1},params.Actions,Actions,Rewards, Value{1,init}(1),Value{1,init}(2));
            LLE2(1,init) = aicbic(-LLE(1,init),[2]);
            
            if init == 1
                ColNames{1} = {'1_Classic_Alp' '1_Classic_Beta'};
                SheetNames{1} = ('1_Classic_Model');
            end
            
        end
        
        %2.)  Classic model with 2 alphas for - and + Pe
        if ismember(2, params.ModelNum)
            Model2.LB = [0 0 1e-6];
            Model2.UB = [1 1 30];
            Model2.init =rand(1,length(Model2.LB)).*(Model2.UB-Model2.LB)+Model2.LB;
            
            [Value{2,init}] = ...
                fmincon(@(x) Model2Pes(params.Start{1},params.Actions,Actions,Rewards,x(1),x(2),x(3)),...
                [Model2.init],[],[],[],[],[Model2.LB],[Model2.UB],[],...
                optimset('TolX', 0.00001, 'TolFun', 0.00001, 'MaxFunEvals', 9e+9, 'Algorithm', 'interior-point','Display','off'));
            
            [LLE(2,init),out{2,init}] = Model2Pes(params.Start{1},params.Actions,Actions,Rewards, Value{2,init}(1),Value{2,init}(2),Value{2,init}(3));
            LLE2(2,init) = aicbic(-LLE(2,init),[3]);
            
             if init == 1
                ColNames{2} = {'2_2PEs_AlpR' '2_2PEs_AlpP' '2_2PEs_Beta'};
                SheetNames{2} = ('2_2PEs');
            end
        end
        
        %3.)  Classic model with 2 alphas for - and + Pe, letting intial Q vary
        if ismember(3,params.ModelNum)
            
            %Define Lower and Upper bounds of free parameters for FminCon
            Model3.LB = [min([params.Value{:}]) min([params.Value{:}]) 0 0 1e-6];
            Model3.UB = [max([params.Value{:}]) max([params.Value{:}]) 1 1 30];
            Model3.init =rand(1,length(Model3.LB)).*(Model3.UB-Model3.LB)+Model3.LB;
            
            [Value{3,init}] = ...
                fmincon(@(x)  Model2Pes([x(1) x(2)],params.Actions,Actions,Rewards,x(3),x(4),x(5)),...
                [Model3.init],[],[],[],[],[Model3.LB],[Model3.UB],[],...
                optimset('TolX', 0.00001, 'TolFun', 0.00001, 'MaxFunEvals', 9e+9, 'Algorithm', 'interior-point','Display','off'));
            
            [LLE(3,init),out{3,init}] = Model2Pes([Value{3,init}(1) Value{3,init}(2)],params.Actions,Actions,Rewards, Value{3,init}(3),Value{3,init}(4),Value{3,init}(5));
            LLE2(3,init) = aicbic(-LLE(3,init),[5]);
            
            if init == 1
                ColNames{3} = {'3_2PEsM_QOpt' '3_2PEsM_QWst' '3_2PEsM_AlpR' '3_2PEsM_AlpP' '3_2PesM_Beta'};
                SheetNames{3} = ('3_2PEsM');
            end
        end
        
        %4.)  Classic model with 2 alphas for - and + Pe
        if ismember(4, params.ModelNum)
            Model4.LB = [0 0 1e-6];
            Model4.UB = [1 1 30];
            Model4.init =rand(1,length(Model4.LB)).*(Model4.UB-Model4.LB)+Model4.LB;
            
            [Value{4,init}] = ...
                fmincon(@(x) Model2Q(params.Start{1},params.Actions,Actions,Rewards,x(1),x(2),x(3)),...
                [Model4.init],[],[],[],[],[Model4.LB],[Model4.UB],[],...
                optimset('TolX', 0.00001, 'TolFun', 0.00001, 'MaxFunEvals', 9e+9, 'Algorithm', 'interior-point','Display','off'));
            
            [LLE(4,init),out{4,init}] = Model2Q(params.Start{1},params.Actions,Actions,Rewards, Value{4,init}(1),Value{4,init}(2),Value{4,init}(3));
            LLE2(4,init) = aicbic(-LLE(4,init),[3]);
            
            if init == 1
                ColNames{4} = {'4_2Qs_AlpR' '4_2Qs_AlpP' '4_2Qs_Beta'};
                SheetNames{4} = ('4_2Qs');
            end
        end
        
       %5.) Classic model with additional d parameters
        
        if ismember(5, params.ModelNum)
            Model5.LB = [0 1e-6 0];
            Model5.UB = [1 30 1];
            Model5.init =rand(1,length(Model5.LB)).*(Model5.UB-Model5.LB)+Model5.LB;
            
            
            [Value{5,init}] = ...
                fmincon(@(x) NormalizedQ(params.Start{1},params.Actions,Actions,Rewards,x(1),x(2),x(3)),...
                [Model5.init],[],[],[],[],[Model5.LB],[Model5.UB],[],...
                optimset('TolX', 0.00001, 'TolFun', 0.00001, 'MaxFunEvals', 9e+9, 'Algorithm', 'interior-point','Display','off'));
            
            [LLE(5,init),out{5,init}] = NormalizedQ(params.Start{1},params.Actions,Actions,Rewards, Value{5,init}(1),Value{5,init}(2),Value{5,init}(3));
            LLE2(5,init) = aicbic(-LLE(5,init),[3]);
            
            
            if init == 1
                ColNames{5} = {'5_ClassicD_Alp' '5_ClassicD_Beta' '5_Classic_d'};
                SheetNames{5} = ('5_ClassicD');
            end
        end
        
        %6.) Actor Critic model with 4 parameters, alphaA, AlphaC, d and beta
        
        if ismember(6,params.ModelNum)
            
            %Define Lower and Upper bounds of free parameters for FminCon
            Model6.LB = [0 0 1e-6 0];
            Model6.UB = [1 1 30 1];
            Model6.init =rand(1,length(Model6.LB)).*(Model6.UB-Model6.LB)+Model6.LB;
            
            [Value{6,init}] = ...
                fmincon(@(x)  ActorCritic(params.Start{2},params.Start{3},params.Actions,Actions,Rewards,x(1),x(2),x(3),x(4)),...
                [Model6.init],[],[],[],[],[Model6.LB],[Model6.UB],[],...
                optimset('TolX', 0.00001, 'TolFun', 0.00001, 'MaxFunEvals', 9e+9, 'Algorithm', 'interior-point','Display','off'));
            
            [LLE(6,init),out{6,init}] = ActorCritic(params.Start{2},params.Start{3},params.Actions,Actions,Rewards, Value{6,init}(1),Value{6,init}(2),Value{6,init}(3),Value{6,init}(4));
            LLE2(6,init) = aicbic(-LLE(6,init),[4]);
            
            if init == 1
                ColNames{6} = {'6_ActorCritic_AlpC' '6_ActorCritic_AlpA' '6_ActorCritic_Beta' '6_ActorCritic_d'};
                SheetNames{6} = ('6_ClassicD');
            end
        end
        
        %7.) Hybrid AC/Q model with 6
        %Classic model with alphaQ
        %AC model with alphaA and alphaC
        %with outside parameters d,c and beta
        
        if ismember(7,params.ModelNum)
            
            %Define Lower and Upper bounds of free parameters for FminCon
            Model7.LB = [0 0 0 1e-6 0 0];
            Model7.UB = [1 1 1 30 1 1];
            Model7.init =rand(1,length(Model7.LB)).*(Model7.UB-Model7.LB)+Model7.LB;
            
            [Value{7,init}] = ...
                fmincon(@(x)  HybridModel(params.Start{1},params.Start{2},params.Start{3},params.Actions,Actions,Rewards,x(1),x(2),x(3),x(4),x(5),x(6)),...
                [Model7.init],[],[],[],[],[Model7.LB],[Model7.UB],[],...
                optimset('TolX', 0.00001, 'TolFun', 0.00001, 'MaxFunEvals', 9e+9, 'Algorithm', 'interior-point','Display','off'));
            
            [LLE(7,init),out{7,init}] = HybridModel(params.Start{1},params.Start{2},params.Start{3},params.Actions,Actions,Rewards, Value{7,init}(1),Value{7,init}(2),Value{7,init}(3),Value{7,init}(4),Value{7,init}(5),Value{7,init}(6));
            LLE2(7,init) = aicbic(-LLE(7,init),[6]);
            
            
            if init == 1
                ColNames{7} = {'7_Hybrid_AlpQ' '7_Hybrid_AlpA' '7_Hybrid_AlpC' '7_Hybrid_Beta' '7_Hybrid_d' '7_Hybrid_c'};
                SheetNames{7} = ('7_Hybrid');
            end
        end
        
    end
% catch
%     %sometimes the model crashes from the given randomized starting free
%     %parameers, so we try to catch it. Still unsure why, but I usually just
%     %rerun the code again if it happens.
%     error(['init ' num2str(Model3.init) ' ' num2str(Model2.init) ' ' num2str(Model1.init) ' ']);
% end


[Best,I] = nanmin(LLE,[],2);
[Best2,I2] = nanmin(LLE2,[],2);


for m = 1:length(I2)
    if ismember(m,params.ModelNum)
    BestMod(m) = Value(m,I2(m));
    BestOut(m) = out(m,I2(m));
    PseudoR(m) = 1 - [-Best(m)/[length(cat(1,Actions{:}))*log(.05)]];
    
    end
end

warning('off', 'MATLAB:MKDIR:DirectoryExists');

% Let's save some data

mkdir([Deci.Folder.Version filesep 'Plot']);
if info.subject_list == 1
   delete([Deci.Folder.Version filesep 'Plot' filesep 'ModelOutputs.xls']); 
end

if info.subject_list == 1
    writecell(['Subject' SheetNames(:)'],[ Deci.Folder.Version filesep 'Plot' filesep 'ModelOutputs.xls'],'Sheet','Summary_LLE','Range','A1');
    writecell(['Subject' SheetNames(:)'],[ Deci.Folder.Version filesep 'Plot' filesep 'ModelOutputs.xls'],'Sheet','Summary_AIC','Range','A1');
    writecell(['Subject' SheetNames(:)'],[ Deci.Folder.Version filesep 'Plot' filesep 'ModelOutputs.xls'],'Sheet','Summary_PseudoR','Range','A1');
end


writecell([Deci.SubjectList(info.subject_list) mat2cell([Best'],[1],ones([length([Best]) 1]))],[ Deci.Folder.Version filesep 'Plot' filesep 'ModelOutputs.xls'],'Sheet','Summary_LLE','Range',['A' num2str(info.subject_list+1)]);
writecell([Deci.SubjectList(info.subject_list) mat2cell([Best2'],[1],ones([length([Best2]) 1]))],[ Deci.Folder.Version filesep 'Plot' filesep 'ModelOutputs.xls'],'Sheet','Summary_AIC','Range',['A' num2str(info.subject_list+1)])
writecell([Deci.SubjectList(info.subject_list) mat2cell([PseudoR],[1],ones([length([PseudoR]) 1]))],[ Deci.Folder.Version filesep 'Plot' filesep 'ModelOutputs.xls'],'Sheet','Summary_PseudoR','Range',['A' num2str(info.subject_list+1)])

if params.saveall
    for m = 1:length(I2)
        if ismember(m,params.ModelNum)
            
            if info.subject_list == 1
                writecell(['Subject' ColNames{m}],[ Deci.Folder.Version filesep 'Plot' filesep 'ModelOutputs.xls'],'Sheet',SheetNames{m},'Range','A1')
            end
            
            writecell([Deci.SubjectList(info.subject_list) mat2cell([BestMod{m}],[1],ones([length([BestMod{m}]) 1]))],[ Deci.Folder.Version filesep 'Plot' filesep 'ModelOutputs.xls'],'Sheet',SheetNames{m},'Range',['A' num2str(info.subject_list+1)]);
            
            ModelParams = fields(BestOut{m});
            
            for MP = 1:length(ModelParams)
                
                param = BestOut{m}.(ModelParams{MP});
                
                mkdir([Deci.Folder.Analysis filesep 'Extra' filesep SheetNames{m} filesep ModelParams{MP} filesep Deci.SubjectList{info.subject_list}])
                save([Deci.Folder.Analysis filesep 'Extra' filesep SheetNames{m} filesep ModelParams{MP} filesep Deci.SubjectList{info.subject_list}  filesep Deci.Analysis.CondTitle{info.Cond}],'param');
                
            end
            
            
        end
    end
end

%% Models



    function [LLE,out] = SimpleQ(starting_q,possible_actions,a,r,alp,beta)
        
        % This is the Classic model with no change.
        
        %What are the possible Actions?
        possible_actions;
        
        % Function can run model on multiple blocks at once.
        for block = 1:length(a)
            
            %get the intial starting expected value
            qout{block}(1,:) = starting_q;
            
            %Now loop through the actions and find reward, Pe, Q(t+1) and P
            for Act = 1:length(a{block})
                
                %Which action is it?
                which = find(a{block}(Act) == possible_actions);
                
                %What is the expected value of that action?
                qout{block}(Act,which);
                
                %What is the Pe?
                PE{block}(Act) = (r{block}(Act) - qout{block}(Act,which));
                
                %What is the Probability of that action?
                
                P{block}(Act) = exp(qout{block}(Act,which)/beta)/ ...
                    [exp(qout{block}(Act,which)/beta) + exp(qout{block}(Act,find(a{block}(Act) ~= possible_actions))/beta)];
                
                % sometimes the probabilty is 1, but the
                % formula outputs a nan and so we have to
                % compensate for that.
                if isnan(P{block}(end))
                    P{block}(end) = qout{block}(Act,which) > qout{block}(Act,find(a{block}(Act) ~= possible_actions));
                end
                
                %update the expected value of the chosen action
                qout{block}(Act+1,which) = qout{block}(Act,which) + alp*PE{block}(Act);
                
                %keep the unchosen action's expected value the same.
                qout{block}(Act+1,find(a{block}(Act) ~= possible_actions))  = qout{block}(Act,find(a{block}(Act) ~= possible_actions));
            end
            
            %remove last, because it's not needed.
            qout{block} = qout{block}(1:end-1,:);
        end
        
        %fmincon finds the the local minima, so we will sum up all the
        %probabilities and get the negative value of that. In theory, the
        %higher the P, the higher the model were able to predict that the
        %probability of the choice.
        LLE = -sum(log([P{:}]));
        
        out.q = qout;
        out.P = P;
        out.Pe = PE;
        
    end

    function [LLE,out] = Model2Pes(starting_q,possible_actions,a,r,alpP,alpN,beta)
        
        % This is the model with that has two different alphas, for
        % negative and positive Pe
        
        
        %What are the possible Actions?
        possible_actions;
        
        % Function can run model on multiple blocks at once.
        for block = 1:length(a)
            
            %get the intial starting expected value
            qout{block}(1,:) = starting_q;
            
            %Now loop through the actions and find reward, Pe, Q(t+1) and P
            for Act = 1:length(a{block})
                
                %Which action is it?
                which = find(a{block}(Act) == possible_actions);
                
                %What is the expected value of that action?
                qout{block}(Act,which);
                
                %What is the Pe?
                PE{block}(Act) = (r{block}(Act) - qout{block}(Act,which));
                
                %What is the Probability of that action?
                
                P{block}(Act) = exp(qout{block}(Act,which)/beta)/ ...
                    [exp(qout{block}(Act,which)/beta) + exp(qout{block}(Act,find(a{block}(Act) ~= possible_actions))/beta)];
                
                % sometimes the probabilty is 1, but the
                % formula outputs a nan and so we have to
                % compensate for that.
                if isnan(P{block}(end))
                    P{block}(end) = qout{block}(Act,which) > qout{block}(Act,find(a{block}(Act) ~= possible_actions));
                end
                
                %update the expected value of the chosen action
                % depending on the Pe's abs val
                if PE{block}(Act) > 0
                    qout{block}(Act+1,which) = qout{block}(Act,which) + alpP*PE{block}(Act);
                else
                    qout{block}(Act+1,which) = qout{block}(Act,which) + alpN*PE{block}(Act);
                end
                
                %keep the unchosen action's expected value the same.
                qout{block}(Act+1,find(a{block}(Act) ~= possible_actions))  = qout{block}(Act,find(a{block}(Act) ~= possible_actions));
            end
            
              %remove last, because it's not needed.
            qout{block} = qout{block}(1:end-1,:);
        end
        
        %fmincon finds the the local minima, so we will sum up all the
        %probabilities and get the negative value of that. In theory, the
        %higher the P, the higher the model were able to predict that the
        %probability of the choice.
        LLE = -sum(log([P{:}]));
        
        out.q = qout;
        out.P = P;
        out.Pe = PE;
    end

    function [LLE,out] = Model2Q(starting_q,possible_actions,a,r,alpP,alpN,beta)
        
        % This is the model with that has two different alphas, for
        % negative and positive Q (expected values)
        
        
        %What are the possible Actions?
        possible_actions;
        
        % Function can run model on multiple blocks at once.
        for block = 1:length(a)
            
            %get the intial starting expected value
            qout{block}(1,:) = starting_q;
            
            %Now loop through the actions and find reward, Pe, Q(t+1) and P
            for Act = 1:length(a{block})
                
                %Which action is it?
                which = find(a{block}(Act) == possible_actions);
                
                %What is the expected value of that action?
                qout{block}(Act,which);
                
                %What is the Pe?
                PE{block}(Act) = (r{block}(Act) - qout{block}(Act,which));
                
                %What is the Probability of that action?
                
                P{block}(Act) = exp(qout{block}(Act,which)/beta)/ ...
                    [exp(qout{block}(Act,which)/beta) + exp(qout{block}(Act,find(a{block}(Act) ~= possible_actions))/beta)];
                
                % sometimes the probabilty is 1, but the
                % formula outputs a nan and so we have to
                % compensate for that.
                if isnan(P{block}(end))
                    P{block}(end) = qout{block}(Act,which) > qout{block}(Act,find(a{block}(Act) ~= possible_actions));
                end
                
                %update the expected value of the chosen action
                % depending on the Pe's abs val
                if r{block}(Act) > 0
                    qout{block}(Act+1,which) = qout{block}(Act,which) + alpP*PE{block}(Act);
                else
                    qout{block}(Act+1,which) = qout{block}(Act,which) + alpN*PE{block}(Act);
                end
                
                %keep the unchosen action's expected value the same.
                qout{block}(Act+1,find(a{block}(Act) ~= possible_actions))  = qout{block}(Act,find(a{block}(Act) ~= possible_actions));
            end
            
              %remove last, because it's not needed.
            qout{block} = qout{block}(1:end-1,:);
        end
        
        %fmincon finds the the local minima, so we will sum up all the
        %probabilities and get the negative value of that. In theory, the
        %higher the P, the higher the model were able to predict that the
        %probability of the choice.
        LLE = -sum(log([P{:}]));
        
        out.q = qout;
        out.P = P;
        out.Pe = PE;
    end



    function [LLE,out] = NormalizedQ(starting_q,possible_actions,a,r,alp,beta,d)
        
        % This is the Classic model with no change.
        
        %What are the possible Actions?
        possible_actions;
        
        % Function can run model on multiple blocks at once.
        for block = 1:length(a)
            
            %get the intial starting expected value
            qout{block}(1,:) = starting_q;
            
            %Now loop through the actions and find reward, Pe, Q(t+1) and P
            for Act = 1:length(a{block})
                
                %Which action is it?
                which = find(a{block}(Act) == possible_actions);
                
                %What is the expected value of that action?
                qout{block}(Act,which);
                
                %determine the outcome
                if r{block}(Act) > 0
                    outcome = 1 - d;
                elseif r{block}(Act) < 0
                    outcome = -d;
                elseif r{block}(Act) == 0
                    outcome = 0;
                else
                    error('nan in reward structure?')
                end
                
                %What is the Pe?
                PE{block}(Act) = (outcome - qout{block}(Act,which));
                
                %What is the Probability of that action?
                
                P{block}(Act) = exp(qout{block}(Act,which)/beta)/ ...
                    [exp(qout{block}(Act,which)/beta) + exp(qout{block}(Act,find(a{block}(Act) ~= possible_actions))/beta)];
                
                % sometimes the probabilty is 1, but the
                % formula outputs a nan and so we have to
                % compensate for that.
                if isnan(P{block}(end))
                    P{block}(end) = qout{block}(Act,which) > qout{block}(Act,find(a{block}(Act) ~= possible_actions));
                end
                
                %update the expected value of the chosen action
                qout{block}(Act+1,which) = qout{block}(Act,which) + alp*PE{block}(Act);
                
                %keep the unchosen action's expected value the same.
                qout{block}(Act+1,find(a{block}(Act) ~= possible_actions))  = qout{block}(Act,find(a{block}(Act) ~= possible_actions));
            end
            
              %remove last, because it's not needed.
            qout{block} = qout{block}(1:end-1,:);
        end
        
        %fmincon finds the the local minima, so we will sum up all the
        %probabilities and get the negative value of that. In theory, the
        %higher the P, the higher the model were able to predict that the
        %probability of the choice.
        LLE = -sum(log([P{:}]));
        
        out.q = qout;
        out.P = P;
        out.Pe = PE;
    end


    function [LLE,out] = ActorCritic(starting_w,starting_v,possible_actions,a,r,alpC,alpA,beta,d)
        
        % This is the basic ActorCritic Model
        
        
        %What are the possible Actions?
        possible_actions;
        
        % Function can run model on multiple blocks at once.
        for block = 1:length(a)
            
            %get the intial starting expected value
            vout{block}(1) = starting_v;
            
            %get the intial starting actor values
            wout{block}(1,:) = starting_w;
            
            %Now loop through the actions and find reward, Pe, Q(t+1) and P
            for Act = 1:length(a{block})
                
                %Which action is it?
                which = find(a{block}(Act) == possible_actions);
                
                % Which action isn't it?
                isnt = find(a{block}(Act) ~= possible_actions);
                
                %What is the expected value?
                vout{block}(Act);
                
                %determine the outcome
                if r{block}(Act) > 0
                    outcome = 1 - d;
                elseif r{block}(Act) < 0
                    outcome = -d;
                elseif r{block}(Act) == 0
                    outcome = 0;
                else
                    error('nan in reward structure?')
                end
                
                %What is the Pe?
                PE{block}(Act) = (outcome - vout{block}(Act));
                
                
                %Update the critic
                vout{block}(Act+1) = vout{block}(Act) + alpC*PE{block}(Act);
                
                %Update the Actor
                wout{block}(Act+1,which) = wout{block}(Act,which) + alpA*PE{block}(Act);
                
                %keep the unchosen Actor the same.
                wout{block}(Act+1,isnt)  = wout{block}(Act,isnt);
                
                %Normalize the Actors
                wout{block}(Act+1,which) = wout{block}(Act,which)/[abs(wout{block}(Act,which)) + abs(wout{block}(Act,isnt))];
                wout{block}(Act+1,isnt) = wout{block}(Act,isnt)/[abs(wout{block}(Act,which)) + abs(wout{block}(Act,isnt))];
                
                %What is the Probability of that action?
                
                P{block}(Act) = exp(wout{block}(Act,which)/beta)/ ...
                    [exp(wout{block}(Act,which)/beta) + exp(wout{block}(Act,isnt)/beta)];
                
                % sometimes the probabilty is 1, but the
                % formula outputs a nan and so we have to
                % compensate for that.
                if isnan(P{block}(end))
                    P{block}(end) = wout{block}(Act,which) > wout{block}(Act,isnt);
                end
                
                
            end
            
             %remove last, because it's not needed.
            vout{block} = vout{block}(1:end-1,:);
            wout{block} = wout{block}(1:end-1,:);
        end
        
        %fmincon finds the the local minima, so we will sum up all the
        %probabilities and get the negative value of that. In theory, the
        %higher the P, the higher the model were able to predict that the
        %probability of the choice.
        LLE = -sum(log([P{:}]));
        
        out.v = vout;
        out.w = wout;
        out.P = P;
        out.Pe = PE;
    end

    function [LLE,out] = HybridModel(starting_q,starting_w,starting_v,possible_actions,a,r,alpQ,alpC,alpA,beta,d,c)
        
        % This is the basic ActorCritic Model
        
        
        %What are the possible Actions?
        possible_actions;
        
        % Function can run model on multiple blocks at once.
        for block = 1:length(a)
            
            %get the intial starting expected value
            qout{block}(1,:) = starting_q;
            
            %get the intial starting critic value
            vout{block}(1) = starting_v;
            
            %get the intial starting actor values
            wout{block}(1,:) = starting_w;
            
            %Now loop through the actions and find reward, Pe, Q(t+1) and P
            for Act = 1:length(a{block})
                
                %Which action is it?
                which = find(a{block}(Act) == possible_actions);
                
                % Which action isn't it?
                isnt = find(a{block}(Act) ~= possible_actions);
                
                %What is the expected value of that action?
                qout{block}(Act,which);
                
                
                %determine the outcome
                if r{block}(Act) > 0
                    outcome = 1 - d;
                elseif r{block}(Act) < 0
                    outcome = -d;
                elseif r{block}(Act) == 0
                    outcome = 0;
                else
                    error('nan in reward structure?')
                end
                
                % ------------------- QL -------------------
                %What is the QL Pe?
                PE_QL{block}(Act) = (outcome - qout{block}(Act,which));
                
                
                %update the expected value of the chosen action
                qout{block}(Act+1,which) = qout{block}(Act,which) + alpQ*PE_QL{block}(Act);
                
                %keep the unchosen action's expected value the same.
                qout{block}(Act+1,isnt)  = qout{block}(Act,isnt);
                

                % ------------------- AC -------------------
                
                 %What is the AC Pe?
                PE_AC{block}(Act) = (outcome - vout{block}(Act));
                
                
                %Update the critic
                vout{block}(Act+1) = vout{block}(Act) + alpC*PE_AC{block}(Act);
                
                %Update the Actor
                wout{block}(Act+1,which) = wout{block}(Act,which) + alpA*PE_AC{block}(Act);
                
                %keep the unchosen Actor the same.
                wout{block}(Act+1,isnt)  = wout{block}(Act,isnt);
                
                %Normalize the Actors
                wout{block}(Act+1,which) = wout{block}(Act,which)/[abs(wout{block}(Act,which)) + abs(wout{block}(Act,isnt))];
                wout{block}(Act+1,isnt) = wout{block}(Act,isnt)/[abs(wout{block}(Act,which)) + abs(wout{block}(Act,isnt))];
                
                % ------------------- Hybrid -------------------
                
                %Determine the Model Contributions
                H{block}(Act,which) = [1-c]*wout{block}(Act,which) + [c]*qout{block}(Act,which);
                H{block}(Act,isnt) = [1-c]*wout{block}(Act,isnt) + [c]*qout{block}(Act,isnt);
                
                %What is the Probability of that action?
                
                P{block}(Act) = exp(H{block}(Act,which)/beta)/ ...
                    [exp(H{block}(Act,which)/beta) + exp(H{block}(Act,isnt)/beta)];
                
                % sometimes the probabilty is 1, but the
                % formula outputs a nan and so we have to
                % compensate for that.
                if isnan(P{block}(end))
                    P{block}(end) = H{block}(Act,which) > H{block}(Act,isnt);
                end
                
                
            end
                        
             %remove last, because it's not needed.
            qout{block} = qout{block}(1:end-1,:);
            vout{block} = vout{block}(1:end-1,:);
            wout{block} = wout{block}(1:end-1,:);
        end
        
        %fmincon finds the the local minima, so we will sum up all the
        %probabilities and get the negative value of that. In theory, the
        %higher the P, the higher the model were able to predict that the
        %probability of the choice.
        LLE = -sum(log([P{:}]));
        
        out.q = qout;
        out.v = vout;
        out.w = wout;
        out.P = P;
        out.QPe = PE_QL;
        out.QAC = PE_AC;
    end