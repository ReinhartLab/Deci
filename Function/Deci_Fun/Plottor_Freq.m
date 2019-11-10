function Plottor_Freq(Deci)


cfg        = [];
cfg.layout = Deci.Layout.eye;
cfg.channel = 'all';
cfg.interactive = 'yes';


%% Deci Checks

Dims = {'Topo' 'Square' 'Wire' 'Bar'};

for Dim = 1:length(Dims)
    
    if Deci.Plot.Freq.(Dims{Dim}).do
        if isequal(Deci.Plot.Freq.(Dims{Dim}).Channel,'Reinhart-All')
            Deci.Plot.Freq.(Dims{Dim}).Channel = [{'AF3'  } {'AF4'  }...
                {'AFz'  } {'C1'   } {'C2'   } {'C3'   } {'C4'   } {'C5'   } ...
                {'C6'   } {'CP1'  } {'CP2'  } {'CP3'  } {'CP4'  } {'CP5'  } {'CP6'  } ...
                {'CPz'  } {'Cz'   } {'F1'   } {'F2'   } {'F3'   } {'F4'   } {'F5'   } ...
                {'F6'   } {'F7'   } {'F8'   } {'FC1'  } {'FC2'  } {'FC3'  } {'FC4'  } ...
                {'FC5'  } {'FC6'  } {'FCz'  } {'FT7'  } {'FT8'  } {'Fz'   } {'O1'   } ...
                {'O2'   } {'Oz'   } {'P1'   } {'P2'   } {'P3'   } {'P4'   } {'P5'   } ...
                {'P6'   } {'P7'   } {'P8'   } {'PO3'  } {'PO4'  } {'PO7'  } {'PO8'  } ...
                {'POz'  } {'Pz'   } {'T7'   } {'T8'   } {'TP10' } {'TP7'  } {'TP8'  } ...
                {'TP9'  } ] ;
        end
        
        if isequal(Deci.Plot.Freq.(Dims{Dim}).Channel,'Reinhart-All_eyes')
            Deci.Plot.Freq.(Dims{Dim}).Channel = [{'AF3'  } {'AF4'  } {'AF7'  } ...
                {'AF8'  } {'AFz'  } {'C1'   } {'C2'   } {'C3'   } {'C4'   } {'C5'   } ...
                {'C6'   } {'CP1'  } {'CP2'  } {'CP3'  } {'CP4'  } {'CP5'  } {'CP6'  } ...
                {'CPz'  } {'Cz'   } {'F1'   } {'F2'   } {'F3'   } {'F4'   } {'F5'   } ...
                {'F6'   } {'F7'   } {'F8'   } {'FC1'  } {'FC2'  } {'FC3'  } {'FC4'  } ...
                {'FC5'  } {'FC6'  } {'FCz'  } {'FT7'  } {'FT8'  } {'Fz'   } {'O1'   } ...
                {'O2'   } {'Oz'   } {'P1'   } {'P2'   } {'P3'   } {'P4'   } {'P5'   } ...
                {'P6'   } {'P7'   } {'P8'   } {'PO3'  } {'PO4'  } {'PO7'  } {'PO8'  } ...
                {'POz'  } {'Pz'   } {'T7'   } {'T8'   } {'TP10' } {'TP7'  } {'TP8'  } ...
                {'TP9'  } {'RHEOG'} {'BVEOG'}] ;
        end
        
        Tois{Dim} = Deci.Plot.Freq.(Dims{Dim}).Toi;
        Fois{Dim} = Deci.Plot.Freq.(Dims{Dim}).Foi;
        Chois{Dim} = Deci.Plot.Freq.(Dims{Dim}).Channel;
    end
end

Tois = sort([Tois{:}]);
Tois = [Tois(1) Tois(end)];

Fois = sort([Fois{:}]);
Fois = [Fois(1) Fois(end)];

Chois = unique([Chois{:}]);

if length(Deci.Plot.Freq.Topo.Channel) == 1
    Deci.Plot.Freq.Topo.do = 0;
end

%% Load

for  subject_list = 1:length(Deci.SubjectList)
    
    tic;
    
    for Conditions = 1:length(Deci.Plot.CondTitle)
        
        for Channel = 1:length(Chois)
            
            display(['Channel ' Chois{Channel} ' ' num2str(Channel) ' of ' num2str(length(Chois))])
            
            freq = [];
            
            switch Deci.Plot.Freq.Type
                case 'TotalPower'
                    load([Deci.Folder.Analysis filesep 'Freq_TotalPower' filesep Deci.SubjectList{subject_list}  filesep Deci.Plot.Lock filesep Deci.Plot.CondTitle{Conditions} filesep Chois{Channel} '.mat'],'freq');
                case 'ITPC'
                    load([Deci.Folder.Analysis filesep 'Freq_ITPC' filesep Deci.SubjectList{subject_list}  filesep Deci.Plot.Lock filesep Deci.Plot.CondTitle{Conditions} filesep Chois{Channel} '.mat'],'freq');
                case 'TotalPower Mean/Var'
                    load([Deci.Folder.Analysis filesep 'Freq_TotalPowerVar' filesep Deci.SubjectList{subject_list}  filesep Deci.Plot.Lock filesep Deci.Plot.CondTitle{Conditions} filesep Chois{Channel} '.mat'],'freq');
            end
            
            foi = freq.freq >= round(Fois(1),4) & freq.freq <= round(Fois(2),4);
            toi = round(freq.time,4) >= Tois(1) & round(freq.time,4) <= Tois(2);
            
            Chans{Channel} = freq;
            Chans{Channel}.freq =  Chans{Channel}.freq(foi);
            %Chans{Channel}.time =  Chans{Channel}.time(toi);
            Chans{Channel}.powspctrm  =Chans{Channel}.powspctrm(:,foi,:);
            Chans{Channel}.label = Chois(Channel);
            
        end
        toc;
        
        acfg.parameter = 'powspctrm';
        acfg.appenddim = 'chan';
        Subjects{subject_list,Conditions} = rmfield(ft_appendfreq(acfg,Chans{:}),'cfg');
        Subjects{subject_list,Conditions}.dimord = 'chan_freq_time';
    end
    clear Chans;
end

%% Baseline Correction
for Conditions = 1:size(Subjects,2)
    for subject_list = 1:size(Subjects,1)

        if ~strcmpi(Deci.Plot.BslRef,Deci.Plot.Lock)
            
            for Channel = 1:length(Chois)

                freq = [];
                    
                switch Deci.Plot.Freq.Type
                    case 'TotalPower'
                        load([Deci.Folder.Analysis filesep 'Freq_TotalPower' filesep Deci.SubjectList{subject_list}  filesep Deci.Plot.BslRef filesep Deci.Plot.CondTitle{Conditions} filesep Chois{Channel} '.mat'],'freq');
                    case 'ITPC'
                        load([Deci.Folder.Analysis filesep 'Freq_ITPC' filesep Deci.SubjectList{subject_list}  filesep Deci.Plot.BslRef filesep Deci.Plot.CondTitle{Conditions} filesep Chois{Channel} '.mat'],'freq');
                    case 'TotalPower Mean/Var'
                        load([Deci.Folder.Analysis filesep 'Freq_TotalPowerVar' filesep Deci.SubjectList{subject_list}  filesep Deci.Plot.BslRef filesep Deci.Plot.CondTitle{Conditions} filesep Chois{Channel} '.mat'],'freq');
                end
                
                foi = freq.freq >= round(Fois(1),4) & freq.freq <= round(Fois(2),4);
                Chans{Channel} = freq;
                Chans{Channel}.freq =  Chans{Channel}.freq(foi);
                Chans{Channel}.powspctrm  =Chans{Channel}.powspctrm(:,foi,:);
                Chans{Channel}.label = Chois(Channel);
                
            end
            
            acfg.parameter = 'powspctrm';
            acfg.appenddim = 'chan';
            Bsl{subject_list,Conditions} = rmfield(ft_appendfreq(acfg,Chans{:}),'cfg');
            
            ccfg.latency = Deci.Plot.Freq.Bsl;
            ccfg.avgovertime = 'yes';
            
            toi1 = round(Bsl{subject_list,Conditions}.time,4) >= Deci.Plot.Freq.Bsl(1) & round(Bsl{subject_list,Conditions}.time,4) <= Deci.Plot.Freq.Bsl(2);
            
            Bsl{subject_list,Conditions}.powspctrm =  Bsl{subject_list,Conditions}.powspctrm(:,:,toi1);
            Bsl{subject_list,Conditions}.time = Bsl{subject_list,Conditions}.time(toi1);
            Bsl{subject_list,Conditions} = ft_selectdata(ccfg, Bsl{subject_list,Conditions});
            Bsl{subject_list,Conditions}.powspctrm = repmat(Bsl{subject_list,Conditions}.powspctrm,[1 1 size(Subjects{subject_list,Conditions}.powspctrm ,3)]);
            
        else
            
            ccfg.latency = Deci.Plot.Freq.Bsl;
            ccfg.avgovertime = 'yes';
            
            toi1 = round(Subjects{subject_list,Conditions}.time,4) >= Deci.Plot.Freq.Bsl(1) & round(Subjects{subject_list,Conditions}.time,4) <= Deci.Plot.Freq.Bsl(2);
            Bsl{subject_list,Conditions} =Subjects{subject_list,Conditions};
            Bsl{subject_list,Conditions}.powspctrm =  Bsl{subject_list,Conditions}.powspctrm(:,:,toi1);
            Bsl{subject_list,Conditions}.time = Bsl{subject_list,Conditions}.time(toi1);
            Bsl{subject_list,Conditions} = ft_selectdata(ccfg, Bsl{subject_list,Conditions});
            Bsl{subject_list,Conditions}.powspctrm = repmat(Bsl{subject_list,Conditions}.powspctrm,[1 1 size(Subjects{subject_list,Conditions}.powspctrm ,3)]);
        end
        

        switch Deci.Plot.Freq.BslType
            case 'none'
            case 'absolute'
                Subjects{subject_list,Conditions}.powspctrm =  Subjects{subject_list,Conditions}.powspctrm - Bsl{subject_list,Conditions}.powspctrm;
            case 'relative'
                Subjects{subject_list,Conditions}.powspctrm=  Subjects{subject_list,Conditions}.powspctrm ./ Bsl{subject_list,Conditions}.powspctrm;
            case 'relchange'
                Subjects{subject_list,Conditions}.powspctrm = ( Subjects{subject_list,Conditions}.powspctrm - Bsl{subject_list,Conditions}.powspctrm) ./ Bsl{subject_list,Conditions}.powspctrm;
            case 'db'
                Subjects{subject_list,Conditions}.powspctrm = 10*log10( Subjects{subject_list,Conditions}.powspctrm ./ Bsl{subject_list,Conditions}.powspctrm);
        end
        
        Subjects{subject_list,Conditions}.time = Subjects{subject_list,Conditions}.time(toi);
        Subjects{subject_list,Conditions}.powspctrm = Subjects{subject_list,Conditions}.powspctrm(:,:,toi);
        
    end
end

%% Math
if ~isempty(Deci.Plot.Math)
    for conds = 1:length(Deci.Plot.Math)
        for subj = 1:size(Subjects,1)
            scfg.parameter = 'powspctrm';
            scfg.operation = Deci.Plot.Math{conds};
            MathData{subj} = ft_math(scfg,Subjects{subj,:});
        end 
        Subjects(:,size(Subjects,2)+1) = MathData;
        
    end
end

%% Data Management

if size(Subjects,1) == 1
    Deci.Plot.GrandAverage = false;  
end

for conds = 1:size(Subjects,2)
    
    if Deci.Plot.GrandAverage
        facfg.parameter =  'powspctrm';
        facfg.type = 'mean';
        facfg.keepindividual = 'yes';
        FreqData{1,conds} = rmfield(ft_freqgrandaverage(facfg,Subjects{:,conds}),'cfg');
    else
        Deci.Plot.Stat.do = false;
        FreqData(:,conds) = Subjects(:,conds);
    end
    
    for subj = 1:size(FreqData(:,conds),1)
        
        if Deci.Plot.Freq.Topo.do
            tcfg = [];
            tcfg.nanmean = 'yes';
            
            tcfg.latency = Deci.Plot.Freq.Topo.Toi;
            tcfg.frequency = Deci.Plot.Freq.Topo.Foi;
            tcfg.channel = Deci.Plot.Freq.Topo.Channel;
            
            topodata{subj,conds} = ft_selectdata(tcfg,FreqData{subj,conds});
            
            
            if strcmpi(Deci.Plot.FreqYScale,'log')
                topodata{subj,conds}.freq = log(topodata{subj,conds}.freq);
            end
            
            tcfg.avgoverfreq = 'yes';
            tcfg.avgovertime = 'yes';
            topotdata{subj,conds} = ft_selectdata(tcfg,topodata{subj,conds});

        end
        
        if Deci.Plot.Freq.Square.do
            tcfg = [];
            tcfg.nanmean = 'yes';
            
            tcfg.latency = Deci.Plot.Freq.Square.Toi;
            tcfg.frequency = Deci.Plot.Freq.Square.Foi;
            tcfg.channel = Deci.Plot.Freq.Square.Channel;
            
            squaredata{subj,conds} = ft_selectdata(tcfg,FreqData{subj,conds});
            
            if strcmpi(Deci.Plot.FreqYScale,'log')
                squaredata{subj,conds}.freq = log(squaredata{subj,conds}.freq);
            end

            tcfg.avgoverchan = 'yes';
            squaretdata{subj,conds} = ft_selectdata(tcfg,squaredata{subj,conds}); 
        end
        
        if Deci.Plot.Freq.Wire.do
            tcfg = [];
            tcfg.nanmean = 'yes';
            
            tcfg.latency = Deci.Plot.Freq.Wire.Toi;
            tcfg.frequency = Deci.Plot.Freq.Wire.Foi;
            tcfg.channel = Deci.Plot.Freq.Wire.Channel;
            
            wiredata{subj,conds} = ft_selectdata(tcfg,FreqData{subj,conds});
            
            
            if strcmpi(Deci.Plot.FreqYScale,'log')
                wiredata{subj,conds}.freq = log(wiredata{subj,conds}.freq);
            end

            tcfg.avgoverchan = 'yes';
            tcfg.avgoverfreq = 'yes';
            wiretdata{subj,conds} = ft_selectdata(tcfg,wiredata{subj,conds}); 
        end
        
        if Deci.Plot.Freq.Bar.do
            tcfg = [];
            %tcfg.avgoverchan = 'yes';
            %tcfg.avgoverfreq = 'yes';
            %tcfg.avgovertime = 'yes';
            tcfg.nanmean = 'yes';
            
            tcfg.latency = Deci.Plot.Freq.Bar.Toi;
            tcfg.frequency = Deci.Plot.Freq.Bar.Foi;
            tcfg.channel = Deci.Plot.Freq.Bar.Channel;
            
            bardata{subj,conds} = ft_selectdata(tcfg,FreqData{subj,conds});
            
            if strcmpi(Deci.Plot.FreqYScale,'log')
                bardata{subj,conds}.freq = log(bardata{subj,conds}.freq);
            end
            
            tcfg.avgoverchan = 'yes';
            tcfg.avgoverfreq = 'yes';
            tcfg.avgovertime = 'yes';
            
            bartdata{subj,conds} = ft_selectdata(tcfg,bardata{subj,conds}); 

        end
    end
end

if Deci.Plot.Stat.do
    
    neighbours       = load('easycap_neighbours','neighbours');
    Deci.Plot.Stat.neighbours = neighbours.neighbours;
    Deci.Plot.Stat.ivar = 1;
    
    for conds = 1:length(Deci.Plot.Draw)
        design = [];
       
        
        
        switch Deci.Plot.Stat.Comp
            case 'Conditions'
                
                Deci.Plot.Stat.uvar = 2;
    
                
                for subcond = 1:length(Deci.Plot.Draw{conds})
                    for subj = 1:size(Subjects,1)
                        design(1,subj+size(Subjects,1)*[subcond-1]) =  subcond;
                        design(2,subj+size(Subjects,1)*[subcond-1]) = subj;
                    end
                end
                
                Deci.Plot.Stat.design = design;
                
                if length(Deci.Plot.Draw{conds}) > 2
                    Deci.Plot.Stat.tail = 1;
                    Deci.Plot.Stat.statistic = 'depsamplesFmultivariate';
                    Deci.Plot.Stat.clustertail      = 1;
                else
                    Deci.Plot.Stat.statistic = 'depsamplesT';
                    Deci.Plot.Stat.tail = 0;
                    Deci.Plot.Stat.clustertail      = 0;
                end
                
                if Deci.Plot.Freq.Topo.do
                    [topostat{conds}] = ft_freqstatistics(Deci.Plot.Stat, topotdata{Deci.Plot.Draw{conds}});
                end
                
                if Deci.Plot.Freq.Square.do
                    [squarestat{conds}] = ft_freqstatistics(Deci.Plot.Stat, squaretdata{:,Deci.Plot.Draw{conds}});
                end
                
                if Deci.Plot.Freq.Wire.do
                    [wirestat{conds}] = ft_freqstatistics(Deci.Plot.Stat, wiretdata{:,Deci.Plot.Draw{conds}});
                end
                
                if Deci.Plot.Freq.Bar.do
                    [barstat{conds}] = ft_freqstatistics(Deci.Plot.Stat, bartdata{Deci.Plot.Draw{conds}});
                end
                
            case 'Bsl'
                Deci.Plot.Stat.tail = 0;
                Deci.Plot.Stat.statistic = 'indepsamplesT';
                
                Deci.Plot.Stat.design = ones(size(Subjects,1));
                
                
                if Deci.Plot.Freq.Topo.do
                    alltopotdata = ft_freqgrandaverage([],topotdata{Deci.Plot.Draw{conds}});
                    alltopotdata.dimord = 'rpt_chan_freq_time';
                    [topostat{conds}] = ft_freqstatistics(Deci.Plot.Stat, alltopotdata);
                end
                
                if Deci.Plot.Freq.Square.do
                    allsquaretdata = ft_freqgrandaverage([],squaretdata{Deci.Plot.Draw{conds}});
                    allsquaretdata.dimord = 'rpt_chan_freq_time';
                    [squarestat{conds}] = ft_freqstatistics(Deci.Plot.Stat, allsquaretdata);
                end
                
                if Deci.Plot.Freq.Wire.do
                    allwiretdata = ft_freqgrandaverage([],wiretdata{Deci.Plot.Draw{conds}});
                    allwiretdata.dimord = 'rpt_chan_freq_time';
                    [wirestat{conds}] = ft_freqstatistics(Deci.Plot.Stat, allwiretdata);
                end
                
                if Deci.Plot.Freq.Bar.do
                    allbartdata = ft_freqgrandaverage([],bartdata{Deci.Plot.Draw{conds}});
                    allbartdata.dimord = 'rpt_chan_freq_time';
                    [barstat{conds}] = ft_freqstatistics(Deci.Plot.Stat, allbartdata);
                end
                
        end 
    end
end

%% Plot

if Deci.Plot.GrandAverage
    Deci.SubjectList = {'Group 1'};
end

for cond = 1:length(Deci.Plot.Draw)
    if Deci.Plot.Stat.do
        
        if Deci.Plot.Freq.Square.do
            tacfg = cfg;
            tacfg.parameter = 'stat';
            squarestat{cond}.mask = double(squarestat{cond}.mask);
            squarestat{cond}.mask(squarestat{cond}.mask == 0) = .2;
            tacfg.maskparameter = 'mask';
            
            if Deci.Plot.Stat.FPlots
                squaret(cond) = figure;
                squaret(cond).Visible = 'on';
                
                ft_singleplotTFR(tacfg,squarestat{cond})
                title([Deci.Plot.Stat.Type ' ' Deci.Plot.Title{cond} ' Square (alpha = ' num2str(Deci.Plot.Stat.alpha) ')']);
                          
                ButtonH=uicontrol('Parent', squaret(cond),'Style','pushbutton','String','p Mask','Position',[10 10 100 25],'Visible','on','Callback',@pmask);
                ButtonH.UserData = @ones;
                
                colormap('jet'); %'hot' 'gray'
                ylabel('F score');
                xlabel('time');
            end
        end
        
        if Deci.Plot.Freq.Topo.do
            tcfg = cfg;
            tcfg.parameter = 'stat';
            topostat{cond}.mask = double(topostat{cond}.mask);
            topostat{cond}.mask(topostat{cond}.mask == 0) = .2;
            
            if Deci.Plot.Stat.FPlots
                topot(cond)  = figure;
                topot(cond).Visible = 'on';
                
                tcfg.clim = 'maxmin';
                tcfg.maskparameter ='mask';
                
                ButtonH=uicontrol('Parent', topot(cond),'Style','pushbutton','String','p Mask','Position',[10 10 100 25],'Visible','on','Callback',@pmask);
                ButtonH.UserData = @ones;
                
                ft_topoplotER(tcfg, topostat{cond});
                title([Deci.Plot.Stat.Type ' ' Deci.Plot.Title{cond} ' Square (alpha = ' num2str(Deci.Plot.Stat.alpha) ')']);
                colormap('jet'); %'hot' 'gray'
            end
        end
        
        if Deci.Plot.Freq.Wire.do
            
            tcfg = cfg;
            tcfg.parameter = 'stat';
            wirestat{cond}.mask = double(wirestat{cond}.mask);
            if Deci.Plot.Stat.FPlots
                wiret(cond)  = figure;
                wiret(cond).Visible = 'on';
                
                plot(squeeze(wirestat{cond}.time),squeeze(wirestat{cond}.stat))
                title([Deci.Plot.Stat.Type ' ' Deci.Plot.Title{cond} ' Square (alpha = ' num2str(Deci.Plot.Stat.alpha) ')']);
            end
            
        end
        
        if Deci.Plot.Freq.Bar.do
            tcfg = cfg;
            tcfg.parameter = 'stat';
              barstat{cond}.mask= double(barstat{cond}.mask);
              barstat{cond}.mask(barstat{cond}.mask == 0) = .2;

            if Deci.Plot.Stat.FPlots
                bart(cond)  = figure;
                bart(cond).Visible = 'on';
                
                bar(barstat{cond}.stat)
                title([Deci.Plot.Stat.Type ' ' Deci.Plot.Title{cond} ' Square (alpha = ' num2str(Deci.Plot.Stat.alpha) ')']);
                colormap('jet'); %'hot' 'gray'
            end
        end
        
    end 

    for subj = 1:size(FreqData,1)
            
        if Deci.Plot.Freq.Square.do
            square(subj) = figure;
            
            if Deci.Plot.Stat.do
                ButtonH=uicontrol('Parent', square(subj),'Style','pushbutton','String','p Mask','Position',[10 10 100 25],'Visible','on','Callback',@pmask);
                ButtonH.UserData = @ones;
            end
        end
        
        if Deci.Plot.Freq.Topo.do
            topo(subj)  = figure;
            
            if Deci.Plot.Stat.do
                ButtonH=uicontrol('Parent', topo(subj),'Style','pushbutton','String','p Mask','Position',[10 10 100 25],'Visible','on','Callback',@pmask);
                ButtonH.UserData = @ones;
            end
        end
        
        if Deci.Plot.Freq.Wire.do
            wire(subj)  = figure;
        end

        %freq plots
        clear b;
        for subcond = 1:length(Deci.Plot.Draw{cond})
            
            if Deci.Plot.Freq.Topo.do
                if length(Deci.Plot.Freq.Topo.Channel) ~= 1
                    
                    
                    set(0, 'CurrentFigure', topo(subj))
                    topo(subj).Visible = 'on';
                    cirky(subj,subcond)    =  subplot(length(Deci.Plot.Draw{cond}),1,subcond);
                    
                    pcfg = cfg;
                    if Deci.Plot.Stat.do
                        
                        pcfg.clim = 'maxmin';
                        pcfg.maskparameter ='mask';
                     topodata{subj,Deci.Plot.Draw{cond}(subcond)}.mask = repmat(topostat{cond}.mask',[size(topodata{subj,Deci.Plot.Draw{cond}(subcond)}.powspctrm,1) 1 length(topodata{subj,Deci.Plot.Draw{cond}(subcond)}.freq) length(topodata{subj,Deci.Plot.Draw{cond}(subcond)}.time)]);
                    end
                    
                    ft_topoplotER(pcfg, topodata{subj,Deci.Plot.Draw{cond}(subcond)});
                    
                    %title([Deci.SubjectList{subj} ' ' Deci.Plot.Freq.Type ' '  Deci.Plot.Subtitle{cond}{subcond} ' trial count: ' num2str(TotalCount{subj,Deci.Plot.Draw{cond}(subcond)})]);
                    title([Deci.SubjectList{subj} ' ' Deci.Plot.Freq.Type ' '  Deci.Plot.Subtitle{cond}{subcond}]);

                    colorbar('vert');
                    map = colormap('pink'); %'hot' 'gray'
                    colormap(map);
                    
                else
                    close topo
                end       
            end
            
            if Deci.Plot.Freq.Square.do
                set(0, 'CurrentFigure', square(subj) )
                square(subj).Visible = 'on';
                subby(subj,subcond) = subplot(length(Deci.Plot.Draw{cond}),1,subcond );
                
                
                pcfg = cfg;
                if Deci.Plot.Stat.do
                    
                    pcfg.clim = 'maxmin';
                    pcfg.maskparameter ='mask';
                    squaredata{subj,Deci.Plot.Draw{cond}(subcond)}.mask = repmat(squarestat{cond}.mask,[length(squaredata{subj,Deci.Plot.Draw{cond}(subcond)}.label) 1 1]);
                end
                
                ft_singleplotTFR(pcfg,squaredata{subj,Deci.Plot.Draw{cond}(subcond)});
                title([Deci.Plot.Subtitle{cond}{subcond}]);

                colorbar('vert');
                map = colormap('pink'); %'hot' 'gray'
                colormap(map);
            end
            
            if Deci.Plot.Freq.Wire.do
                set(0, 'CurrentFigure', wire(subj) )
                wire(subj).Visible = 'on';
                
                top = squeeze(nanmean(nanmean(nanmean(wiredata{subj,Deci.Plot.Draw{cond}(subcond)}.powspctrm,1),2),3)) + squeeze(nanstd(nanmean(nanmean(wiredata{subj,Deci.Plot.Draw{cond}(subcond)}.powspctrm,2),3),[],1))/sqrt(size(wiredata{subj,Deci.Plot.Draw{cond}(subcond)}.powspctrm,1));
                bot = squeeze(nanmean(nanmean(nanmean(wiredata{subj,Deci.Plot.Draw{cond}(subcond)}.powspctrm,1),2),3)) - squeeze(nanstd(nanmean(nanmean(wiredata{subj,Deci.Plot.Draw{cond}(subcond)}.powspctrm,2),3),[],1))/sqrt(size(wiredata{subj,Deci.Plot.Draw{cond}(subcond)}.powspctrm,1));
                
                 if Deci.Plot.GrandAverage
                pgon = polyshape([wiredata{subj,Deci.Plot.Draw{cond}(subcond)}.time fliplr(wiredata{subj,Deci.Plot.Draw{cond}(subcond)}.time)],[top' fliplr(bot')],'Simplify', false);
                b(subcond) = plot(pgon,'HandleVisibility','off');
                hold on
                b(subcond).EdgeAlpha = 0;
                b(subcond).FaceAlpha = .15;
                 end
                

                
                if Deci.Plot.Stat.do
                wiredata{subj,Deci.Plot.Draw{cond}(subcond)}.mask = repmat(wirestat{cond}.mask,[length(wiredata{subj,Deci.Plot.Draw{cond}(subcond)}.label) 1 1]);
                end
            end
            
        end
        
        if Deci.Plot.Freq.Wire.do
            set(0, 'CurrentFigure', wire(subj) )
            wire(subj).Visible = 'on';
            
            
            pcfg = cfg;
            pcfg.clim = 'maxmin';
            
            if Deci.Plot.Stat.do
                pcfg.maskparameter ='mask';
                
            end
            pcfg.ylim = ylim;
            pcfg.graphcolor = lines;
            pcfg.linewidth = 1;
            ft_singleplotER(pcfg,wiredata{subj,Deci.Plot.Draw{cond}});
            
            if Deci.Plot.GrandAverage
            arrayfun(@(c) uistack(c,'top'),b);
            end

            axis tight
            hold on
            plot([wiredata{cond}.time(1), wiredata{cond}.time(end)], [0 0], 'k--') % hor. line
            plot([0 0], ylim, 'k--') % vert. l
            
            if Deci.Plot.Stat.do
                
                boxes = wire(subj).Children(2).Children.findobj('Type','Patch');
                
                for bb = 1:length(boxes)
                    if ~isempty(boxes)
                        boxes(bb).FaceAlpha = .35;
                        uistack(boxes(bb),'bottom')
                        boxes(bb).HandleVisibility = 'off';
                    end
                end
            end
            %title([Deci.Plot.Subtitle{cond}{subcond}]);
            
            %h = plot(wiredata{subj,Deci.Plot.Draw{cond}(subcond)}.time,squeeze(mean(wiredata{subj,Deci.Plot.Draw{cond}(subcond)}.powspctrm,1)));
            %h.Color = b.FaceColor;
            %h.LineWidth = 1;
            
            
            l = legend(Deci.Plot.Subtitle{cond});
            title([Deci.SubjectList{subj} ' ' Deci.Plot.Freq.Type ' ' Deci.Plot.Title{cond} ' Wire'])
            set(l, 'Interpreter', 'none')
            xlim([wiredata{cond}.time(1) wiredata{cond}.time(end)])
            %                         if Deci.Plot.Freq.Wire &&subcond == 1
            %                          ax1 = axes;
            %                          hold on
            %                          imagesc(ax1,wirestatdraw{cond}.time,mean(ylim)/2,squeeze(wirestatdraw{cond}.prob <= .05),'alphadata',squeeze(wirestatdraw{cond}.prob <= .05))
            %                          ax1.Visible = 'off';
            %
            %                         end
            xlabel('Time');
        end
        
        
        if Deci.Plot.Freq.Bar.do
            
            barfig(subj)  = figure;
            
            %             if Deci.Plot.Stat.do
            %                 ButtonH=uicontrol('Parent', barfig(subj),'Style','pushbutton','String','p Mask','Position',[10 10 100 25],'Visible','on','Callback',@pmask);
            %                 ButtonH.UserData = 0;
            %             end
            
            set(0, 'CurrentFigure', barfig(subj) )
            barfig(subj).Visible = 'on';
            
            
            CleanBars(mean(cell2mat(arrayfun(@(c) nanmean(nanmean(nanmean(c.powspctrm,2),3),4),[bardata{subj,Deci.Plot.Draw{cond}}],'UniformOutput',false)),1), ...
                nanstd(cell2mat(arrayfun(@(c) nanmean(nanmean(nanmean(c.powspctrm,2),3),4),[bardata{subj,Deci.Plot.Draw{cond}}],'UniformOutput',false)),[],1) ...
                /sqrt(size(cell2mat(arrayfun(@(c) nanmean(nanmean(nanmean(c.powspctrm,2),3),4),[bardata{subj,Deci.Plot.Draw{cond}}],'UniformOutput',false)),1)));
            
            l = legend(Deci.Plot.Subtitle{cond});
            title([Deci.SubjectList{subj} ' ' Deci.Plot.Freq.Type ' ' Deci.Plot.Title{cond} ' Wire'])
            set(l, 'Interpreter', 'none')
            if Deci.Plot.Stat.do
                hold on
                
                if barstat{cond}.prob < Deci.Plot.Stat.alpha
                    plot([.75 1.25],[max(ylim) max(ylim)]*.90, '-k', 'LineWidth',2);
                    plot([1],[max(ylim)]*.95, '*k');
                end
            end
        end
        
%         if Deci.Plot.Stat.do
%             if Deci.Plot.Freq.Wire
%                 
%                 set(0, 'CurrentFigure', wire(subj) )
%                 wire(subj).Visible = 'on';
%                 
%                 wiret = repmat(squeeze(wirestat{cond}.prob)' <= .05 ,[ceil(diff(ylim)) 1]);
%                 
%                 h =imagesc(wirestat{cond}.time,min(ylim):max(ylim),wiret);
%                 h.AlphaData = squeeze(wirestat{cond}.prob)' <= .05;
%                 hold on
%                 
%                 set(gca,'YDir','normal');
%                 if Deci.Plot.Stat.do
%                     ButtonH=uicontrol('Parent', wire(subj),'Style','pushbutton','String','p Mask','Position',[10 10 100 25],'Visible','on','Callback',@pmask);
%                     ButtonH.UserData = @zeros;
%                 end
%             end
%         end
    end
    
    for subj = 1:size(FreqData,1)
        
        
        if length(Deci.Plot.Freq.Topo.Channel) ~= 1
            
            if Deci.Plot.Freq.Topo.do
                set(0, 'CurrentFigure', topo(subj) )
                topo(subj).Visible = 'on';
                suptitle(Deci.Plot.Title{cond});
                colormap(jet)
                for r = 1:length(cirky(:))
                    
                    if length(Deci.Plot.Freq.Roi) == 2 && isnumeric(Deci.Plot.Freq.Roi)
                        cirky(r).CLim = Deci.Plot.Freq.Roi;
                    elseif strcmp(Deci.Plot.Freq.Roi,'maxmin')
                        cirky(r).CLim = [min([cirky.CLim]) max([cirky.CLim])];
                    elseif strcmp(Deci.Plot.Freq.Roi,'maxabs')
                        cirky(r).CLim = [-1*max(abs([cirky.CLim])) max(abs([cirky.CLim]))];
                    end
                    
                end
                
                
                
                if ~isempty(Deci.Folder.Plot)
                    mkdir([Deci.Folder.Plot filesep Deci.Plot.Title{cond}]);
                    %saveas(topo(subj),[Deci.Folder.Plot filesep Deci.Plot.Title{cond} filesep Deci.SubjectList{subj} '_topo'],Deci.Plot.Save.Format);
                end
                
            end
            
            
        end
        
        if Deci.Plot.Freq.Square.do
            set(0, 'CurrentFigure', square(subj))
            square(subj).Visible = 'on';
            suptitle([Deci.SubjectList{subj} ' ' Deci.Plot.Freq.Type ' ' Deci.Plot.Title{cond}]);
            colormap(jet)
            for r = 1:length(subby(:))
                
                if length(Deci.Plot.Freq.Roi) == 2 && isnumeric(Deci.Plot.Freq.Roi)
                    subby(r).CLim = Deci.Plot.Freq.Roi;
                elseif strcmp(Deci.Plot.Freq.Roi,'maxmin')
                    subby(r).CLim = [min([subby.CLim]) max([subby.CLim])];
                elseif strcmp(Deci.Plot.Freq.Roi,'maxabs')
                    subby(r).CLim = [-1*max(abs([subby.CLim])) max(abs([subby.CLim]))];
                end
            end
            
            if strcmpi(Deci.Plot.FreqYScale,'log')
                for r = 1:length(subby(:))
                    subby(r).YTickLabels = exp(subby(r).YTick);
                end
            end
            
            if ~isempty(Deci.Folder.Plot)
                mkdir([Deci.Folder.Plot filesep Deci.Plot.Title{cond}]);
                %saveas(square(subj),[Deci.Folder.Plot filesep Deci.Plot.Title{cond} filesep Deci.SubjectList{subj} '_square'],Deci.Plot.Save.Format);
            end
            
        end
        
        
    end
    
end

    function pmask(PushButton, EventData)
        
        Axes = PushButton.Parent.Children.findobj('Type','Axes');
        Axes = Axes(arrayfun(@(c) ~isempty(c.String), [Axes.Title]));
        
        for a = 1:length(Axes)
            
            imag = Axes(a).Children.findobj('Type','Image');
            
            if isempty(imag)
                imag =  Axes(a).Children.findobj('Type','Surface');
                
            end
            
            if isempty(imag.UserData)
                imag.UserData = logical(~isnan(imag.CData));
            end
            
            placeholder = imag.UserData;
            imag.UserData = imag.AlphaData;
            imag.AlphaData = placeholder;
        end
    end

end
