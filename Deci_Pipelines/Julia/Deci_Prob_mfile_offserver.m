%  Welcome to Deci
% A fluid pipeline to analyze EEG Data with ease
% Written and Compiled by @John Nguyen of Robert Reinhart Lab on 10/15/2018, contact: Akida@bu.edu
%
% 0. MainMenu

addpath(genpath('/projectnb/crc-nak/chartove/Julia/Deci'))
addpath(genpath('/projectnb/crc-nak/chartove/Julia/OurFieldTrip'))
addpath(genpath('C:\Users\User\Documents\GitHub\PACmeg'))

Deci = [];
Deci.Folder.Raw         = ['G:\Julia\New_Datasets\3_9_2020'];              % Raw Data Folder Directory
Deci.SubjectList        = 'gui';                                                % Cell Array of strings, 'all' or 'gui'
Deci.Step               = 5;                                            % Which Step to implement 1-TD, 2-PP, 3-Art, 4-Analysis, 5-Plot
Deci.Proceed            = false;                                                                  % Continue to next step when current step is done?
Deci.PCom               = true;                                                       % Activates Parallel Computing for PP and Analysis only
Deci.Folder.Version     = ['G:\Julia\ProcessedData'];        % Output Folder Directory

%% 1. Trial Definitions

Deci.DT.Type = 'Prob_Exp2';
Deci.DT.Starts     = {5};
Deci.DT.Ends       = {6};         %Cell Array of Markers for ETs End.
Deci.DT.Markers    = {[14 15 16] [41 42] [51 52] [31 34] [37 38] [22 23]};
Deci.DT.Locks      = [20];
Deci.DT.Toi        = [-4 5];

%MrkMake('C:\Users\User\Desktop\Prob_Stim\RawData',{{'111' '113' '115'} {'112' '114' '116'}},{'110' '117'},[-1/1000 1/1000])

Deci.DT.Block.Markers = {[100]};

%% 2. PreProcessing Steps
Deci.PP.filter.bpfreq = [.5 100];
Deci.PP.filter.bpfilter = 'yes';
Deci.PP.filter.detrend = 'yes';

Deci.ICA.do = true;

%% 3. Artifact Rejection
Deci.Art.do = true;
Deci.Art.crittoilim = [-.5 1.5]; %it was glitching when Deci.Analysis.Toi didn't match this
Deci.Art.AddComponents =  true;

%Deci.Art.More.channel = {'FCz'};

%% 4. Analysis
Deci.Analysis.Laplace       = false;
Deci.Analysis.LaplaceFile = ['standard_1020.elc'];	% Uses Captrak .bvct file with same name in RawData Folder
Deci.Analysis.Locks         = [1];                                                          % Which Lock to Analyze
Deci.Analysis.LocksTitle    = {'Fdb Onset'};                      % Folder Title to save each Lock as
Deci.Analysis.DownSample    = 1000;                                              % Downsample Pre-Analysis

Deci.Analysis.Conditions    = {[22] [23] [22 23]};
Deci.Analysis.CondTitle     = {'Cor' 'Inc' 'AllFeedback'};

Deci.Analysis.Channels = {'FCz'};
Deci.Analysis.Toi           = [-1 2];       %glitches if -1 2 which is what it was before                                      % Time Range to save
Deci.Analysis.Toilim        = [-4 5];


Deci.Analysis.Connectivity.Sets = {{{'FCz'} {'FCz'} 'lowf' 'beta' 'mi'}}; %...
%{{{'FCz'} {'FCz'} 'theta' 'beta' 'mi'}};
%{{'FCz'} {'FCz'} 'theta' 'lowgamma' 'nmcoupling'}};
Deci.Analysis.Connectivity.DownSample = 100;

%connectivity statistics
Deci.Analysis.Connectivity.Zscore.do = false;
Deci.Analysis.Connectivity.Zscore.Runs = 500;
Deci.Analysis.Connectivity.keeptrials = 'no';
Deci.Analysis.Connectivity.list = [true];
Deci.Analysis.Connectivity.Functions = {'dc_connectivity'};
Deci.Analysis.Connectivity.Params = {{Deci.Analysis.Connectivity}};

%% 5. Plotting

if Deci.Step == 4
    Deci_Wavelet;
    
    Deci.Analysis.Freq.method        = 'wavelet';                                                  % Currently only uses 'wavelet' and 'hilbert'
    Deci.Analysis.Freq.foi           = exp(linspace(log(2),log(100),25));                           % Frequency of Interest
    Deci.Analysis.Freq.width         = exp(linspace(log(3),log(13),25));			%number of cycles
    Deci.Analysis.Freq.gwidth        = 4;											%width of gaussian
    
    Deci.Analysis.ERP.do  = false;
    Deci.Analysis.Freq.do  = true;
    Deci.Analysis.Freq.Extra.do = true;
    Deci.Analysis.Extra.do  = false;
    Deci.Analysis.Connectivity.do = false;
    
    %Deci.Analysis.Freq.Extra.Corr.phase_freqs = 2*(1.3.^[0:5]);
    %Deci.Analysis.Freq.Extra.Corr.amp_freqs = round(12*(1.15.^[0:15]));
    Deci.Analysis.Freq.Extra.Corr.phase_freqs = 2:0.5:8;
    Deci.Analysis.Freq.Extra.Corr.amp_freqs = 12:2:100;
    Deci.Analysis.Freq.Extra.Corr.filt_order = 3;
    Deci.Analysis.Freq.Extra.Corr.amp_bandw_method = 'number';
    Deci.Analysis.Freq.Extra.Corr.amp_bandw = 8;
    Deci.Analysis.Freq.Extra.Corr.method = 'tort';
    Deci.Analysis.Freq.Extra.Corr.surr_method = 'swap_trials';
    Deci.Analysis.Freq.Extra.Corr.surr_N = 500;
    Deci.Analysis.Freq.Extra.Corr.avg_PAC = 'no';
    Deci.Analysis.Freq.Extra.Corr.mask = [-0.5 0];
    
    Deci.Analysis.Freq.Extra.do = true;
    Deci.Analysis.Freq.Extra.list = [true];
    Deci.Analysis.Freq.Extra.Functions = {'Deci_PACmeg_wrapper'};
    Deci.Analysis.Freq.Extra.Params = {{Deci.Analysis.Freq.Extra.Corr}};
    
    Deci_Backend(Deci);
    Deci = rmfield(Deci,'Analysis');
else
    
    Deci.Run.Behavior = false;
    Deci.Run.Freq = false;
    Deci.Run.ERP =false;
    Deci.Run.Extra = true;
    
    Deci.Plot.BslRef ='Fdb Onset';
    Deci.Plot.Lock = 'Fdb Onset';
    
    Deci.Plot.GrandAverage = true;
    
    Deci.Analysis.CondTitle     = {'Cor' 'Inc' 'AllFeedback'};
    Deci.Plot.CondTitle     = {'Cor' 'Inc' 'AllFeedback'};
    
    Deci.Plot.Math         = {'x1-x2','x1-x3','x2-x3'};           % Condition Math done after Bsl, Condition Indexes are appended on.
    Deci.Plot.Draw         = {[1:2] [4:6]};                   % Cell array of Condition Index for each figure
    Deci.Plot.Figures      = [true true];                             % Which figure to plot currently
    Deci.Plot.Title        = {'All Trials' 'Subtraction'};          % Title for each figure
    Deci.Plot.Subtitle     = {{'Cor' 'Inc'} {'Cor - Inc' 'Cor-All' 'Inc-All'}};     % Cell array of strings of subtitles for each Condition
    
    
    Deci.Plot.Topo.do    =false;
    Deci.Plot.Topo.Foi     = [3 8];                   % Frequency of Interest
    Deci.Plot.Topo.Toi     = [];                   % Time of Interest
    Deci.Plot.Topo.Channel = ['Reinhart-All'];                   % Channel of Interest
    
    Deci.Plot.Square.do  =true;
    Deci.Plot.Square.Foi     = [];                 % Frequency of Interest
    Deci.Plot.Square.Toi     = [];                   % Time of Interest
    Deci.Plot.Square.Channel = [{'FCz'}];                % Channel of Interest
    
    Deci.Plot.Wire.do    =false;
    Deci.Plot.Wire.Foi     = [2 3];           % Frequency of Interest
    Deci.Plot.Wire.Toi     = [];                   % Time of Interest
    Deci.Plot.Wire.Channel = [{'FCz'}];              % Channel of Interest
    
    Deci.Plot.Bar.do    =false;
    Deci.Plot.Bar.Foi     =  [2 3];                 % Frequency of Interest
    Deci.Plot.Bar.Toi     = [.5 1];                   % Time of Interest
    Deci.Plot.Bar.Channel =  [{'FCz'}];
    
    Deci.Plot.Freq.Type    = 'TotalPower'; %this can be TotalPower, ITPC, or TotalPowerVar
    
    %set the baseline reference time
    if  strcmpi(Deci.Plot.BslRef, 'Response Onset')
        Deci.Plot.Bsl     = [-.5 -.3];
    else
        Deci.Plot.Bsl     = [-.5 0];
    end
    
    %     if Deci.Run.Extra
    %         Deci.Plot.BslType = 'absolute';
    %         Deci.Plot.Roi = 'maxabs';
    %         Deci.Plot.ColorMap = flip(CoolMap);
    %
    %         Deci.Plot.Stat.do = false;
    %         Deci.Plot.Stat.Type = 'Anova/T-test';
    %         Deci.Plot.Stat.alpha = .05;
    %         Deci.Plot.Stat.correctm = 'fdr';
    %
    %
    
    if  Deci.Plot.Square.do
        Omnibus = true;
        
        %statistics
        Deci.Plot.Stat.do = true;
        if Omnibus == true %F statistic
            Deci.Plot.Stat.Comp = 'Bsl';
            Deci.Plot.Stat.alpha = .05;
            Deci.Plot.Stat.correctm = 'no';
            Deci.Plot.BslType = 'relchange';
            Deci.Plot.Stat.FPlots =  false;
        else %bootstrap
            Deci.Plot.Stat.do = true;
            Deci.Plot.Stat.Type = 'Randomize Permutation';
            Deci.Plot.Stat.alpha = .05;
        end
        Deci.Plot.Stat.FPlots =  false;
    elseif Deci.Plot.Topo.do
        Perma = true;
        
        if Perma == true
            Deci.Plot.Stat.Type = 'Randomize Permutation';
            Deci.Plot.Stat.alpha = .05;
            Deci.Plot.Stat.FPlots =  false;
        end
    elseif Deci.Plot.Wire.do
        Deci.Plot.Stat.do = true;
        Deci.Plot.Stat.Type = 'Anova/T-test';
        Deci.Plot.Stat.alpha = .05;
        Deci.Plot.Stat.FPlots =  false;
        Deci.Plot.Stat.correctm = 'no';
        Deci.Plot.BslType = 'relchange';
    elseif Deci.Plot.Bar.do
        Deci.Plot.Stat.do = true;
        Deci.Plot.Stat.Type = 'Anova/T-test';
        Deci.Plot.Stat.alpha = .05;
        Deci.Plot.Stat.FPlots =  false;
        Deci.Plot.Stat.correctm = 'fdr';
        Deci.Plot.BslType = 'relchange';
    end
    
    % conn plots
    
    Deci.Plot.Extra.Conn.List = Deci.Analysis.Connectivity.Sets([true]);
    Deci.Plot.Extra.Conn.toi = [];
    
    %frequency low vs frequency high
    Deci.Plot.Extra.Conn.FL_FH.do =  true;
    Deci.Plot.Extra.Conn.FL_FH.toi = [];
    
    Deci.Plot.Extra.Conn.CL_CH.do =  true;
    Deci.Plot.Extra.Conn.CL_CH.toi = [];
    
    %frequency vs time
    Deci.Plot.Extra.Conn.FL_time.do =  true;
    Deci.Plot.Extra.Conn.FH_time.do =  true;
    
    %channel vs time
    Deci.Plot.Extra.Conn.CL_time.do =  true;
    Deci.Plot.Extra.Conn.CH_time.do =  true;
    
    %Deci.Plot.Extra.Conn.phase_freqs = 2*(1.3.^[0:5]);
    % Deci.Plot.Extra.Conn.amp_freqs = round(12*(1.15.^[0:15]));
    Deci.Plot.Extra.Conn.phase_freqs = 2:0.5:8;
    Deci.Plot.Extra.Conn.amp_freqs = 12:2:100;
    Deci.Plot.Extra.Conn.trialflag = false;
    Deci.Plot.Extra.Conn.trialnums = [1:30];
    Deci.Plot.Extra.Conn.latencyflag = true;
    Deci.Plot.Extra.Conn.latency = [-0.5 0];
    %the following is a really kludgy way of doing this but basically this
    %is selecting conditions from Deci.Plot.CondTitle
    Deci.Plot.Extra.Conn.PAC_cond1 = 1;
    Deci.Plot.Extra.Conn.PAC_cond2 = 2;
    %Deci.Plot.Extra.List = [true,true];
    %Deci.Plot.Extra.Functions = { 'Plottor_Conn','Deci_get_PAC_stats'};
    %Deci.Plot.Extra.Params = {{Deci.Plot.Extra.Conn},{Deci.Plot.Extra.Conn}};
    Deci.Plot.Extra.List = [true];
    Deci.Plot.Extra.Functions = {'Deci_get_PAC_stats'};
    Deci.Plot.Extra.Params = {{Deci.Plot.Extra.Conn}};
    
    %behavioral plots
    Deci.Plot.Behv = [];
    Deci.Plot.Behv.Source = 'Definition';
    Deci.Plot.Behv.Static = [];
    Deci.Plot.Behv.WriteExcel = true;
    
    Deci.Plot.Behv.Acc.Figure = [true];
    Deci.Plot.Behv.Acc.Total = {{[1 2]}};
    Deci.Plot.Behv.Acc.Subtotal = {{1}};
    
    Deci.Plot.Behv.Acc.Title = {'Correctness'};
    Deci.Plot.Behv.Acc.Subtitle = {{'Correctness'}};
    
    Deci.Plot.Behv.Acc.Collapse.Movmean =  [true];
    Deci.Plot.Behv.Acc.Collapse.MovWindow = 36;
    
    Deci.Plot.Behv.Acc.Block = @ceil;
    Deci.Plot.Behv.Acc.Collapse.Trial = false ;
    Deci.Plot.Behv.Acc.Collapse.Block = true ;
    Deci.Plot.Behv.Acc.Collapse.Subject = true ;
    
    Deci.Plot.Behv.RT.Figure = [false];
    % Deci.Plot.Behv.RT.Draw = {{[1] [2]}};
    % Deci.Plot.Behv.RT.Title = {' RT'};
    % Deci.Plot.Behv.RT.Subtitle = {{'Correct' 'Incorrect'}};
    % Deci.Plot.Behv.RT.Locks = [1 2];
    %
    % Deci.Plot.Behv.RT.Block = @ceil;
    % Deci.Plot.Behv.RT.Collapse.Trial = true;
    % Deci.Plot.Behv.RT.Collapse.Block = false;
    % Deci.Plot.Behv.RT.Collapse.Subject = false;
    
    
    %%  6. Run
    Deci_Backend(Deci);
end
