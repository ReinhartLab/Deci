function Plottor2(Deci)


for subject_list = 1:length(Deci.SubjectList)
    if ~isempty(Deci.Plot.Freq) ||  ~isempty(Deci.Plot.PRP)
        if ~isdir([Deci.Folder.Analysis filesep 'Four_TotalPower' filesep Deci.SubjectList{subject_list}])
            error(['Freq Analysis not found for '  Deci.SubjectList{subject_list}])
        end

        if isequal(Deci.Plot.Freq.Channel,'Reinhart-All')
            Deci.Plot.Freq.Channel = [{'AF3'  } {'AF4'  } {'AF7'  } ...
                {'AF8'  } {'AFz'  } {'C1'   } {'C2'   } {'C3'   } {'C4'   } {'C5'   } ...
                {'C6'   } {'CP1'  } {'CP2'  } {'CP3'  } {'CP4'  } {'CP5'  } {'CP6'  } ...
                {'CPz'  } {'Cz'   } {'F1'   } {'F2'   } {'F3'   } {'F4'   } {'F5'   } ...
                {'F6'   } {'F7'   } {'F8'   } {'FC1'  } {'FC2'  } {'FC3'  } {'FC4'  } ...
                {'FC5'  } {'FC6'  } {'FCz'  } {'FT7'  } {'FT8'  } {'Fz'   } {'O1'   } ...
                {'O2'   } {'Oz'   } {'P1'   } {'P2'   } {'P3'   } {'P4'   } {'P5'   } ...
                {'P6'   } {'P7'   } {'P8'   } {'PO3'  } {'PO4'  } {'PO7'  } {'PO8'  } ...
                {'POz'  } {'Pz'   } {'T7'   } {'T8'   } {'TP10' } {'TP7'  } {'TP8'  } ...
                {'TP9'  } ] ;
        end
        
        if length(Deci.Plot.Freq.Channel) == 1
           Deci.Plot.Freq.Topo = 0; 
        end
        
        Freq.Channels       = CleanDir([Deci.Folder.Analysis filesep 'Four_TotalPower' filesep Deci.SubjectList{subject_list} filesep Deci.Plot.Lock]);
        Freq.Channels       = cellfun(@(c) c(1:end-4),Freq.Channels,'un',0);
        
        if ~ischar(Deci.Plot.Freq.Channel)
            if ~any(ismember(Deci.Plot.Freq.Channel,Freq.Channels))
                error('Freq Channel Parameter has additional channels not found in Data')
            end
            
            Freq.Channels = Deci.Plot.Freq.Channel(ismember(Deci.Plot.Freq.Channel,Freq.Channels));
        end
    end
    
    if ~isempty(Deci.Plot.ERP) || ~isempty(Deci.Plot.PRP)
        if ~isdir([Deci.Folder.Analysis filesep 'Volt_ERP' filesep Deci.SubjectList{subject_list}])
            error(['ERP Analysis not found for '  Deci.SubjectList{subject_list}])
        end
        
        if isequal(Deci.Plot.ERP.Channel,'Reinhart-All')
            Deci.Plot.ERP.Channel = [{'AF3'  } {'AF4'  } {'AF7'  } ...
                {'AF8'  } {'AFz'  } {'C1'   } {'C2'   } {'C3'   } {'C4'   } {'C5'   } ...
                {'C6'   } {'CP1'  } {'CP2'  } {'CP3'  } {'CP4'  } {'CP5'  } {'CP6'  } ...
                {'CPz'  } {'Cz'   } {'F1'   } {'F2'   } {'F3'   } {'F4'   } {'F5'   } ...
                {'F6'   } {'F7'   } {'F8'   } {'FC1'  } {'FC2'  } {'FC3'  } {'FC4'  } ...
                {'FC5'  } {'FC6'  } {'FCz'  } {'FT7'  } {'FT8'  } {'Fz'   } {'O1'   } ...
                {'O2'   } {'Oz'   } {'P1'   } {'P2'   } {'P3'   } {'P4'   } {'P5'   } ...
                {'P6'   } {'P7'   } {'P8'   } {'PO3'  } {'PO4'  } {'PO7'  } {'PO8'  } ...
                {'POz'  } {'Pz'   } {'T7'   } {'T8'   } {'TP10' } {'TP7'  } {'TP8'  } ...
                {'TP9'  } ] ;
        end

    end
    
    if ~isempty(Deci.Plot.PRP)
        Deci.Plot.GA = 0;
        
        if isempty(Deci.Plot.PRP.label)
            Deci.Plot.Freq.BslType =  0;
            warning('Cannot Find label for PRP plot, setting as 0');
        end
        
        if isempty(Deci.Plot.PRP.ScatterToi)
            Deci.Plot.Freq.ScatterToi =  [-inf inf];
            warning('Cannot Find ScatterToi for PRPplot, setting as  [-inf inf]');
        end
    end
    
    if ~isempty(Deci.Plot.CFC)
        
        if isequal(Deci.Plot.CFC.chanlow,'Reinhart-All')
            Deci.Plot.CFC.chanlow = [{'AF3'  } {'AF4'  } {'AF7'  } ...
                {'AF8'  } {'AFz'  } {'C1'   } {'C2'   } {'C3'   } {'C4'   } {'C5'   } ...
                {'C6'   } {'CP1'  } {'CP2'  } {'CP3'  } {'CP4'  } {'CP5'  } {'CP6'  } ...
                {'CPz'  } {'Cz'   } {'F1'   } {'F2'   } {'F3'   } {'F4'   } {'F5'   } ...
                {'F6'   } {'F7'   } {'F8'   } {'FC1'  } {'FC2'  } {'FC3'  } {'FC4'  } ...
                {'FC5'  } {'FC6'  } {'FCz'  } {'FT7'  } {'FT8'  } {'Fz'   } {'O1'   } ...
                {'O2'   } {'Oz'   } {'P1'   } {'P2'   } {'P3'   } {'P4'   } {'P5'   } ...
                {'P6'   } {'P7'   } {'P8'   } {'PO3'  } {'PO4'  } {'PO7'  } {'PO8'  } ...
                {'POz'  } {'Pz'   } {'T7'   } {'T8'   } {'TP10' } {'TP7'  } {'TP8'  } ...
                {'TP9'  } ] ;
        end
        
        if isequal(Deci.Plot.CFC.chanhigh,'Reinhart-All')
            Deci.Plot.CFC.chanhigh = [{'AF3'  } {'AF4'  } {'AF7'  } ...
                {'AF8'  } {'AFz'  } {'C1'   } {'C2'   } {'C3'   } {'C4'   } {'C5'   } ...
                {'C6'   } {'CP1'  } {'CP2'  } {'CP3'  } {'CP4'  } {'CP5'  } {'CP6'  } ...
                {'CPz'  } {'Cz'   } {'F1'   } {'F2'   } {'F3'   } {'F4'   } {'F5'   } ...
                {'F6'   } {'F7'   } {'F8'   } {'FC1'  } {'FC2'  } {'FC3'  } {'FC4'  } ...
                {'FC5'  } {'FC6'  } {'FCz'  } {'FT7'  } {'FT8'  } {'Fz'   } {'O1'   } ...
                {'O2'   } {'Oz'   } {'P1'   } {'P2'   } {'P3'   } {'P4'   } {'P5'   } ...
                {'P6'   } {'P7'   } {'P8'   } {'PO3'  } {'PO4'  } {'PO7'  } {'PO8'  } ...
                {'POz'  } {'Pz'   } {'T7'   } {'T8'   } {'TP10' } {'TP7'  } {'TP8'  } ...
                {'TP9'  } ] ;
        end
    end
    
    
end

%% Load

if ~isempty(Deci.Plot.Freq) || ~isempty(Deci.Plot.PRP)
        for  subject_list = 1:length(Deci.SubjectList)
            
            tic;
            for Channel = 1:length(Freq.Channels)
                
                display(['Channel ' Freq.Channels{Channel} ' of ' num2str(length(Freq.Channels))])
                
                freq = [];
                load([Deci.Folder.Analysis filesep 'Four_TotalPower' filesep Deci.SubjectList{subject_list} filesep Deci.Plot.Lock filesep Freq.Channels{Channel}],'freq');
                
                foi = freq.freq >= round(Deci.Plot.Freq.Foi(1),4) & freq.freq <= round(Deci.Plot.Freq.Foi(2),4);
                toi = round(freq.time,4) >= Deci.Plot.Freq.Toi(1) & round(freq.time,4) <= Deci.Plot.Freq.Toi(2);
                
                Chans{Channel} = freq;
                Chans{Channel}.freq =  Chans{Channel}.freq(foi);
                Chans{Channel}.time =  Chans{Channel}.time(toi);
                Chans{Channel}.powspctrm  =Chans{Channel}.fourierspctrm(:,:,foi,toi);
                Chans{Channel}.label = Freq.Channels(Channel);
                
            end
            toc;
            
            acfg.parameter = 'powspctrm';
            acfg.appenddim = 'chan';
            Chans = rmfield(ft_appendfreq(acfg,Chans{:}),'cfg');
            
            acfg.latency = Deci.Plot.Freq.Bsl;
            acfg.avgovertime = 'yes';
            
            
            if Deci.Plot.Var
                a = figure;
                for Channel = 1:length(Chans.label)
                    
                    plot(reshape(squeeze(10*log10(mean(mean(abs(Chans.powspctrm(:,Channel,:,:)).^2,3),2)))',[1 size(Chans.powspctrm,1)*size(Chans.powspctrm,4)]));
                    hold on
                end
                a.Visible = 'on';
                title([Deci.SubjectList{subject_list} ' Chan']);
                
                waitfor(a)
                
                b = figure;
                for Channel = 1:length(Chans.freq)
                    
                    plot(reshape(squeeze(10*log10(mean(mean(abs(Chans.powspctrm(:,:,Channel,:)).^2,3),2)))',[1 size(Chans.powspctrm,1)*size(Chans.powspctrm,4)]));
                    hold on
                end
                b.Visible = 'on';
                title([Deci.SubjectList{subject_list} ' Freq'])
                waitfor(b)
                
            end
            
            
        
            for Conditions = 1:length(Deci.Plot.Conditions)
                
                maxt = max(sum(ismember(freq.condinfo{2},Deci.Plot.Conditions{Conditions}),2));
                
                trl = sum(ismember(freq.condinfo{2},Deci.Plot.Conditions{Conditions}),2) == maxt;
                
                Subjects{subject_list,Conditions} = Chans;
                Subjects{subject_list,Conditions}.powspctrm = Chans.powspctrm(trl,:,:,:);
                
                TrialCount{subject_list,Conditions} = length(find(trl));
                
                switch Deci.Plot.Freq.Type
                    case 'TotalPower'
                Subjects{subject_list,Conditions}.powspctrm = permute(mean(abs(Subjects{subject_list,Conditions}.powspctrm).^2 ,1),[2 3 4 1]);
                    case 'ITPC'
                Subjects{subject_list,Conditions}.powspctrm = permute(abs(mean(Subjects{subject_list,Conditions}.powspctrm./abs(Subjects{subject_list,Conditions}.powspctrm),1)),[2 3 4 1]) ;   
                    case 'TotalPower Std'
                Subjects{subject_list,Conditions}.powspctrm = permute(std(abs(Subjects{subject_list,Conditions}.powspctrm).^2 ,1),[2 3 4 1]);        
                   case 'TotalPower Mean/Std'
                Subjects{subject_list,Conditions}.powspctrm = permute(mean(abs(Subjects{subject_list,Conditions}.powspctrm).^2 ,1),[2 3 4 1])./permute(std(abs(Subjects{subject_list,Conditions}.powspctrm).^2 ,1),[2 3 4 1]);        
               
                end
                
                bsl = ft_selectdata(acfg, Subjects{subject_list,Conditions});
                bsl = repmat(bsl.powspctrm,[1 1 size(Subjects{subject_list,Conditions}.powspctrm ,3)]);
            
                switch Deci.Plot.Freq.BslType
                    case 'absolute'
                        Subjects{subject_list,Conditions}.powspctrm =  Subjects{subject_list,Conditions}.powspctrm - bsl;
                    case 'relative'
                        Subjects{subject_list,Conditions}.powspctrm=  Subjects{subject_list,Conditions}.powspctrm ./ bsl;
                    case 'relchange'
                       Subjects{subject_list,Conditions}.powspctrm = ( Subjects{subject_list,Conditions}.powspctrm - bsl) ./ bsl;
                    case 'db'
                       Subjects{subject_list,Conditions}.powspctrm = 10*log10( Subjects{subject_list,Conditions}.powspctrm ./ bsl);
                end
                
                
                  Subjects{subject_list,Conditions}.dimord = 'chan_freq_time';
            end
            clear Chans;
        end
        
        
        
        if Deci.Plot.GA
            
            for conds = 1:size(Subjects,2)
            facfg.parameter =  'powspctrm';
            FreqData{conds} = rmfield(ft_freqgrandaverage(facfg,Subjects{:,conds}),'cfg');
            
            TotalCount{conds} = mean([TrialCount{:,conds}]);
            
            end
        else
            FreqData = Subjects;
            TotalCount = TrialCount;
        end
        clear Subjects;
    
    
    if ~isempty(Deci.Plot.PRP)
        if strcmp(Deci.Plot.PRP.Dim,'trials')
            for  Condition =  1:length(Deci.Plot.Conditions)
                for  subject_list = 1:length(Deci.SubjectList)
                    for Channel = 1:length(Freq.Channels)
                        
                        display(['Channel ' Freq.Channels{Channel} ' of ' num2str(length(Freq.Channels))])
                        
                        freq = [];
                        load([Deci.Folder.Analysis filesep 'Four_' Deci.Plot.Freq.Type filesep Deci.SubjectList{subject_list} filesep Deci.Plot.Conditions{Condition} filesep Freq.Channels{Channel}],'freq');
                        
                        foi = freq.freq >= round(Deci.Plot.Freq.Foi(1),4) & freq.freq <= round(Deci.Plot.Freq.Foi(2),4);
                        toi = round(freq.time,4) >= Deci.Plot.Freq.Toi(1) & round(freq.time,4) <= Deci.Plot.Freq.Toi(2);
                        
                        Chans{Channel} = freq;
                        Chans{Channel}.freq =  Chans{Channel}.freq(foi);
                        Chans{Channel}.time =  Chans{Channel}.time(toi);
                        Chans{Channel}.powspctrm  =Chans{Channel}.powspctrm(:,:,foi,toi);
                        Chans{Channel}.label = Freq.Channels(Channel);
                        
                    end
                    
                    acfg.parameter = 'powspctrm';
                    acfg.appenddim = 'chan';
                    Subjects{subject_list} = rmfield(ft_appendfreq(acfg,Chans{:}),'cfg');
                    clear Chans;
                    
                    if  exist([Deci.Folder.Version  filesep 'Redefine' filesep 'BSL' filesep Deci.SubjectList{subject_list} filesep num2str(Condition) '.mat']) ~= 2 || ~isequal(Deci.Plot.Freq.Bsl,[0 0])
                        
                        acfg.latency = Deci.Plot.Freq.Bsl;
                        acfg.avgovertime = 'yes';
                        bsl = ft_selectdata(acfg,freq);
                    else
                        
                        bsl = [];
                        load([Deci.Folder.Version  filesep 'Redefine' filesep 'BSL' filesep Deci.SubjectList{subject_list} filesep num2str(Condition) '.mat']);
                    end
                    
                    bsl = repmat(bsl.powspctrm(:,ismember(bsl.label,Freq.Channels),foi,:),[1 1 1 size(Subjects{subject_list}.powspctrm ,4)]);
                    
                    switch Deci.Plot.Freq.BslType
                        case 'absolute'
                            Subjects{subject_list}.powspctrm = Subjects{subject_list}.powspctrm - bsl;
                        case 'relative'
                            Subjects{subject_list}.powspctrm= Subjects{subject_list}.powspctrm ./ bsl;
                        case 'relchange'
                            Subjects{subject_list}.powspctrm = (Subjects{subject_list} - bsl) ./ bsl;
                        case 'db'
                            Subjects{subject_list}.powspctrm = 10*log10(Subjects{subject_list}.powspctrm ./ bsl);
                    end
                    
                end
                
                if Deci.Plot.GA
                    facfg.parameter =  'powspctrm';
                    FreqData{Condition,1} = rmfield(ft_freqgrandaverage(facfg,Subjects{:}),'cfg');
                    
                else
                    FreqData(Condition,:) = Subjects(:);
                end
                
            end
        end
    end
    
    
    if ~isempty(Deci.Plot.Math)
        
        if isequal(Deci.Plot.Math.Form,'Hemifield')
            
            for subj = 1:size(FreqData,2)
                HemiData = FreqData(:,subj);
                Hemis = length(HemiData);
                
                for Hem = 1:Hemis
                    HemiData{Hem} = hemifieldflip(HemiData{Hem});
                end
                
                Hemidata = [FreqData(:,subj);HemiData];
                
                for Hem = 1:Hemis
                    scfg.operation = ['x' num2str(Hem) '-x' num2str(Hem+Hemis)];
                    
                    scfg.parameter = 'powspctrm';
                    
                    MathData{Hem,subj} = ft_math(scfg,Hemidata{:});
                    
                    scfg.channel =  MathData{Hem,subj}.label(cell2mat(cellfun(@(c) any(rem(c(isstrprop(c,'digit')),2)),  MathData{Hem,subj}.label,'un',0)));
                    MathData{Hem,subj} = ft_selectdata(scfg, MathData{Hem,subj});
                end
                
                
                
            end
            
            FreqData = MathData;
            
        else
            
            if Deci.Plot.Math.Type ~= 0
            
            for cond = 1:length(Deci.Plot.Math.Form)
                for subj = 1:size(FreqData,1)
                    scfg.parameter = 'powspctrm';
                    scfg.operation = Deci.Plot.Math.Form{cond};
                    MathData{subj} = ft_math(scfg,FreqData{subj,:});
                end
                
                FreqData(:,length(Deci.Plot.Conditions)+cond) = MathData;
                TotalCount(:,length(Deci.Plot.Conditions)+cond) = num2cell(nan(size(FreqData,1),1));
            end
            
            if Deci.Plot.Math.Type == 1
                FreqData = FreqData(:,length(Deci.Plot.Conditions)+1:end);
                TotalCount = TotalCount(:,length(Deci.Plot.Conditions)+1:end);
            end
            
            
            end
        end
        
        
        
    end
    
    if ~isempty(Deci.Plot.Freq.Wires)
        for subj = 1:size(FreqData,1)
            for cond = 1:size(FreqData,2)
                WireData{subj,cond} =  ft_selectdata(Deci.Plot.Freq.Wires,FreqData{subj,cond});
            end
        end
    end
    
    
end





if ~isempty(Deci.Plot.ERP)|| ~isempty(Deci.Plot.PRP)
    for  Condition =  1:length(Deci.Plot.Conditions)
        for  subject_list = 1:length(Deci.SubjectList)
            
            time = [];
            load([Deci.Folder.Analysis filesep 'Volt_ERP' filesep Deci.SubjectList{subject_list} filesep Deci.Plot.Conditions{Condition}],'time');
            
            toi = round(time.time,4) >= Deci.Plot.ERP.Toi(1) & round(time.time,4) <= Deci.Plot.ERP.Toi(2);
            time.time =  time.time(toi);
            time.avg  =time.avg(:,toi);
            
            if ~ischar(Deci.Plot.ERP.Channel)
                if ~any(ismember(Deci.Plot.ERP.Channel,time.label))
                    error('Channel Parameter has additional channels not found in Data')
                end
                
                tcfg.channel = Deci.Plot.ERP.Channel;
                time = ft_selectdata(tcfg,time);
            end
            
            Subjects{subject_list} = time;
            clear time;
        end
        
        if Deci.Plot.GA
            facfg.parameter =  'avg';
            TimeData{Condition,1} = rmfield(ft_timelockgrandaverage(facfg,Subjects{:}),'cfg');
            
        else
            TimeData(Condition,:) = Subjects(:);
        end
        clear Subjects;
        
    end
    
    
    if Deci.Plot.Math.Type ~= 0
        
        if isequal(Deci.Plot.Math.Form,'Hemifield')
            
            for subj = 1:size(TimeData,2)
                HemiData = TimeData(:,subj);
                Hemis = length(HemiData);
                
                for Hem = 1:Hemis
                    HemiData{Hem} = hemifieldflip(HemiData{Hem});
                end
                
                Hemidata = [TimeData(:,subj);HemiData];
                
                for Hem = 1:Hemis
                    scfg.operation = ['x' num2str(Hem) '-x' num2str(Hem+Hemis)];
                    
                    scfg.parameter = 'avg';
                    
                    MathData{Hem,subj} = ft_math(scfg,Hemidata{:});
                    
                    scfg.channel =  MathData{Hem,subj}.label(cell2mat(cellfun(@(c) any(rem(c(isstrprop(c,'digit')),2)),  MathData{Hem,subj}.label,'un',0)));
                    MathData{Hem,subj} = ft_selectdata(scfg, MathData{Hem,subj});
                end
                
            end
            
            TimeData = MathData;
            
        else
            
            for cond = 1:length(Deci.Plot.Math.Form)
                for subj = 1:size(TimeData,2)
                    scfg.parameter = 'avg';
                    scfg.operation = Deci.Plot.Math.Form{cond};
                    MathData{subj} = ft_math(scfg,TimeData{:,subj});
                end
                
                TimeData(length(Deci.Plot.Conditions)+cond,:) = MathData;
            end
            
            if Deci.Plot.Math.Type == 1
                TimeData = TimeData(length(Deci.Plot.Conditions)+1:end,:);
            end
        end
        
        
        
    end
    
    
    
    
end


if ~isempty(Deci.Plot.CFC)
    for  subject_list = 1:length(Deci.SubjectList)
        tic;
        for Channel = 1:length(Deci.Plot.CFC.chanhigh)
            
            display(['High Channel ' Deci.Plot.CFC.chanhigh{Channel} ' of ' num2str(length(Deci.Plot.CFC.chanhigh))])
            
            freq = [];
            load([Deci.Folder.Analysis filesep 'Four_TotalPower' filesep Deci.SubjectList{subject_list} filesep Deci.Plot.Lock filesep Deci.Plot.CFC.chanhigh{Channel}],'freq');
            
            foi = freq.freq >= round(Deci.Plot.CFC.freqhigh(1),4) & freq.freq <= round(Deci.Plot.CFC.freqhigh(2),4);
            toi = round(freq.time,4) >= Deci.Plot.CFC.latencyhigh(1) & round(freq.time,4) <= Deci.Plot.CFC.latencyhigh(2);
            
            HighChans{Channel} = freq;
            HighChans{Channel}.freq =  HighChans{Channel}.freq(foi);
            HighChans{Channel}.time =  HighChans{Channel}.time(toi);
            HighChans{Channel}.fourierspctrm  = HighChans{Channel}.fourierspctrm(:,:,foi,toi);
        end
        toc;
        
        acfg.parameter = 'fourierspctrm';
        acfg.appenddim = 'chan';
        HighChans = rmfield(ft_appendfreq(acfg,HighChans{:}),'cfg');
        
        tic;
        for Channel = 1:length(Deci.Plot.CFC.chanlow)
            
            display(['Low Channel ' Deci.Plot.CFC.chanlow{Channel} ' of ' num2str(length(Deci.Plot.CFC.chanlow))])
            
            freq = [];
            load([Deci.Folder.Analysis filesep 'Four_TotalPower' filesep Deci.SubjectList{subject_list} filesep Deci.Plot.Lock filesep Deci.Plot.CFC.chanlow{Channel}],'freq');
            
            foi = freq.freq >= round(Deci.Plot.CFC.freqlow(1),4) & freq.freq <= round(Deci.Plot.CFC.freqlow(2),4);
            toi = round(freq.time,4) >= Deci.Plot.CFC.latencylow(1) & round(freq.time,4) <= Deci.Plot.CFC.latencylow(2);
            
            LowChans{Channel} = freq;
            LowChans{Channel}.freq =  LowChans{Channel}.freq(foi);
            LowChans{Channel}.time =  LowChans{Channel}.time(toi);
            LowChans{Channel}.fourierspctrm  = LowChans{Channel}.fourierspctrm(:,:,foi,toi);
            
        end
        toc;
        
        acfg.parameter = 'fourierspctrm';
        acfg.appenddim = 'chan';
        LowChans = rmfield(ft_appendfreq(acfg,LowChans{:}),'cfg');

        for m = 1:length(Deci.Plot.CFC.methods)
            for Conditions = 1:length(Deci.Plot.Conditions)
                maxt = max(sum(ismember(freq.condinfo{2},Deci.Plot.Conditions{Conditions}),2));
                trl = sum(ismember(freq.condinfo{2},Deci.Plot.Conditions{Conditions}),2) == maxt;
                
                TrialCount{subject_list,Conditions} = length(find(trl));
                
                High = HighChans;
                High.fourierspctrm = HighChans.fourierspctrm(trl,:,:,:);
                Low = LowChans;
                Low.fourierspctrm = LowChans.fourierspctrm(trl,:,:,:);
                

                Deci.Plot.CFC.method = Deci.Plot.CFC.methods{m};
                CFCData{subject_list,Conditions,m} =  ft_singlecfc(Deci.Plot.CFC,Low,High);
                
            end
            
        end

    end
end

%% Plot


if Deci.Plot.GA
    Deci.SubjectList = {'Group 1'};
end

if ~isempty(Deci.Folder.Plot)
    mkdir(Deci.Folder.Plot);
end

cfg        = [];
cfg.layout = Deci.Layout.eye;
cfg.channel = 'all';
cfg.interactive = 'yes';

if ~isempty(Deci.Plot.Freq)
    
    for subj = 1:size(FreqData,1)
        
        if Deci.Plot.Freq.Square
            square(subj) = figure;
        end
        
        if Deci.Plot.Freq.Topo
            topo(subj)  = figure;
        end
        
        if ~isempty(Deci.Plot.Freq.Wires)
            wire(subj)  = figure;
        end
        
        for cond = 1:size(FreqData,2)
            
            if Deci.Plot.Freq.Topo
                if length(Freq.Channels) ~= 1
                    
                    
                    set(0, 'CurrentFigure', topo(subj) )
                    topo(subj).Visible = 'on';
                    cirky(subj,cond)    =  subplot(size(FreqData,2),1,cond);
                    ft_topoplotER(cfg, FreqData{subj,cond});
                    
                    
                    %                     hold on
                    %                     a = get(gca,'Children');
                    %                     conty = a(arrayfun(@(c) strcmp(c.Type,'contour'),a));
                    %                     surfy  = a(arrayfun(@(c) strcmp(c.Type,'surface'),a));
                    %
                    %                     spot = find(arrayfun(@(c) strcmp(c.Type,'contour'),a));
                    %
                    %                     actmin = min(min(surfy.CData(~isnan(surfy.CData))));
                    %                     actmax = max(max(surfy.CData(~isnan(surfy.CData))));
                    %
                    %                     h = figure;
                    %                     [~,cont] = contourf(gca,surfy.CData,linspace(actmin,actmax,6));
                    %                     a(spot).LevelList = cont.LevelList;
                    %                     a(spot).TextList = cont.TextList;
                    %                     a(spot).Fill = 'on';
                    %                     delete(h);
                    
                    %                     axis xy
                    title([Deci.SubjectList{subj} ' ' Deci.Plot.Freq.Type ' Cond'  num2str(cond)]);
                    colorbar('vert');
                    map = colormap('jet'); %'hot' 'gray'
                    colormap(map);
                    
                else
                    close topo
                end
            end
            
            
            if strcmpi(Deci.Plot.Scale,'log')
                FreqData{subj,cond}.freq = log(FreqData{subj,cond}.freq);
                
                if ~isempty(Deci.Plot.Freq.Wires)
                    WireData{subj,cond}.freq = log(WireData{subj,cond}.freq);
                end
            end
            
            if Deci.Plot.Freq.Square
                set(0, 'CurrentFigure', square(subj) )
                square(subj).Visible = 'on';
                subby(subj,cond) = subplot(size(FreqData,2),1,cond);
                ft_singleplotTFR(cfg,FreqData{subj,cond})
                
                title([Deci.SubjectList{subj} ' ' Deci.Plot.Freq.Type ' Cond'  num2str(cond) ' trial count: ' num2str(TotalCount{subj,cond})]);
                colorbar('vert');
                map = colormap('jet'); %'hot' 'gray'
                colormap(map);
            end
            
            
            
            
        end
        
        if ~isempty(Deci.Plot.Freq.Wires)
            
            set(0, 'CurrentFigure', wire(subj) )
            curvy(subj)    =  axes;
            
            for cond = 1:size(WireData,1)
                
                if strcmpi(Deci.Plot.Freq.Wires.Collapse,'Freq')
                    plot(WireData{subj,cond}.time,squeeze(WireData{subj,cond}.powspctrm));
                    
                    xlabel('Time');
                elseif  strcmpi(Deci.Plot.Freq.Wires.Collapse,'Time')
                    
                    if strcmpi(Deci.Plot.Scale,'log')
                        WireData{subj,cond}.freq = exp(WireData{subj,cond}.freq);
                    end
                    
                    plot(WireData{subj,cond}.freq,squeeze(WireData{subj,cond}.powspctrm));
                    xlabel('Freq')
                end
                ylabel('Power')
                hold on
            end
            legend(curvy(subj),strsplit(num2str(1:size(FreqData,2))))
            title([Deci.SubjectList{subj} ' ' Deci.Plot.Freq.Type]);
            
            if ~isempty(Deci.Folder.Plot)
                saveas(wire(subj),[Deci.Folder.Plot filesep Deci.SubjectList{subj} '_wire'],Deci.Plot.Save.Format);
            end
            
        end
        
    end
    
    
    for subj = 1:size(FreqData,1)
        if length(Freq.Channels) ~= 1
            
            if Deci.Plot.Freq.Topo
                set(0, 'CurrentFigure', topo(subj) )
                topo(subj).Visible = 'on';
                
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
                    saveas(topo(subj),[Deci.Folder.Plot filesep Deci.SubjectList{subj} '_topo'],Deci.Plot.Save.Format);
                end
                
            end
            
            
        end
        
        if Deci.Plot.Freq.Square
            set(0, 'CurrentFigure', square(subj))
            square(subj).Visible = 'on';
            
            for r = 1:length(subby(:))
                
                if length(Deci.Plot.Freq.Roi) == 2 && isnumeric(Deci.Plot.Freq.Roi)
                    subby(r).CLim = Deci.Plot.Freq.Roi;
                elseif strcmp(Deci.Plot.Freq.Roi,'maxmin')
                    subby(r).CLim = [min([subby.CLim]) max([subby.CLim])];
                elseif strcmp(Deci.Plot.Freq.Roi,'maxabs')
                    subby(r).CLim = [-1*max(abs([subby.CLim])) max(abs([subby.CLim]))];
                end
            end
            
            if strcmpi(Deci.Plot.Scale,'log')
                for r = 1:length(subby(:))
                    subby(r).YTickLabels = exp(subby(r).YTick);
                end
            end
            
            if ~isempty(Deci.Folder.Plot)
                saveas(square(subj),[Deci.Folder.Plot filesep Deci.SubjectList{subj} '_square'],Deci.Plot.Save.Format);
            end
            
        end
        
        
    end
end

if ~isempty(Deci.Plot.ERP)
    if Deci.Plot.ERP.Plot
        for subj = 1:size(TimeData,2)
            
            topoERP(subj)  = figure;
            
            
            for cond = 1:size(TimeData,1)
                
                set(0, 'CurrentFigure', topoERP)
                tippy(subj,cond)    = subplot(size(TimeData,1),1,cond);
                ft_topoplotER(cfg, TimeData{subj,cond});
                
                
            end
            
            wireERP(subj)  = figure;
            ft_singleplotER(cfg, TimeData{:,subj});
            
        end
        
        for r = 1:length(tippy(:))
            tippy(r).CLim = [min([tippy.CLim]) max([tippy.CLim])];
        end
    end
end

if ~isempty(Deci.Plot.PRP)
    
    
    PRPPlot = figure;
    colors = reshape(hsv(size(FreqData,2)),[3 size(FreqData,2) 1]);
    
    for subj = 1:size(FreqData,1)
        for cond = 1:size(FreqData,2)
            
            %Collapse Freq and Channel
            FreqData{subj,cond}.avg = permute(nanmean(nanmean(FreqData{subj,cond}.powspctrm,2),1),[1 3 2]);
            FreqData{subj,cond} = rmfield(FreqData{subj,cond},'powspctrm');
            FreqData{subj,cond}.label = {'mix'};
            FreqData{subj,cond}.dimord = 'chan_time';
            Hz = regexprep(num2str(num2str(minmax(FreqData{subj,cond}.freq)),'%.3g '),' +','-');
            FreqData{subj,cond} = rmfield(FreqData{subj,cond},'freq');
            
            %Collapse Channel
            TimeData{subj,cond}.avg = mean(TimeData{subj,cond}.avg,1);
            TimeData{subj,cond}.label = {'mix'};
            TimeData{subj,cond}.dimord = 'chan_time';
        end
    end
    
    
    
    for cond = 1:size(FreqData,2)
        
        clear SF ST
        
        for  subj = 1:size(FreqData,1)
            
            for k = 1:length(TimeData{subj,cond}.time)
                SF(subj,k) = FreqData{subj,cond}.avg(:,k);
                ST(subj,k) = TimeData{subj,cond}.avg(:,k);
            end
            
            ax4 = subplot(2,2,4);
            ax4.XAxisLocation = 'origin';
            ax4.YAxisLocation = 'origin';
            hold(ax4,'on');
            scattoi = TimeData{subj,cond}.time >= Deci.Plot.PRP.ScatterToi(1) &  TimeData{subj,cond}.time <= Deci.Plot.PRP.ScatterToi(2);
            scat(subj,cond,1) = nanmean(FreqData{subj,cond}.avg(:,scattoi),2);
            scat(subj,cond,2) = nanmean(TimeData{subj,cond}.avg(:,scattoi),2);
            scattitle = regexprep(num2str(num2str(minmax(TimeData{subj,cond}.time(scattoi))),'%.3g '),' +','-');
            
            scatter(ax4,scat(subj,cond,1),scat(subj,cond,2),'MarkerFaceColor',colors(:,cond))
            
            if Deci.Plot.PRP.label
                t =  text(ax4, scat(subj,cond,1),scat(subj,cond,2),Deci.SubjectList{subj});
                set(t, 'Clipping', 'on','Interpreter', 'none');
            end
            
            
        end
        
        for k = 1:length(TimeData{subj,cond}.time)
            RHO(k) = corr(SF(:,k),ST(:,k));
        end
        
        ax3 = subplot(2,2,3);
        ax3.XAxisLocation = 'origin';
        ax3.YAxisLocation = 'origin';
        RHOim = plot(ax3,TimeData{subj,cond}.time,RHO,'Color',colors(:,cond));
        hold(ax3,'on');
        
        tcfg.parameter = 'avg';
        SFreq = rmfield(ft_timelockgrandaverage(tcfg,FreqData{cond,:}),'cfg');
        STime = rmfield(ft_timelockgrandaverage(tcfg,TimeData{cond,:}),'cfg');
        
        ax1 = subplot(2,2,1);
        ax1.XAxisLocation = 'origin';
        ax1.YAxisLocation = 'origin';
        plot(ax1,FreqData{subj,cond}.time,SFreq.avg,'Color',colors(:,cond));
        hold(ax1,'on');
        
        ax2 = subplot(2,2,2);
        ax2.XAxisLocation = 'origin';
        ax2.YAxisLocation = 'origin';
        plot(ax2,TimeData{subj,cond}.time,STime.avg,'Color',colors(:,cond));
        hold(ax2,'on');
        set(ax2,'YDir','reverse');
        
        mxb = polyfit(scat(cond,:,1),scat(cond,:,2),1);
        slope(cond) = mxb(1);
        plot(ax4,ax4.XLim,polyval(mxb,ax4.XLim),'Color',colors(:,cond));
    end
    
    xlabel(ax1, 'Time');
    ylabel(ax1, 'Total Power ');
    
    xlabel(ax2, 'Time');
    ylabel(ax2, 'Voltage (uV)');
    
    xlabel(ax3, 'Rho value');
    ylabel(ax3, 'P value');
    title(ax3,{['Between Trial Correlation with p and rho']} );
    
    
    xlabel(ax3,'Time(secs)');
    ylabel(ax3, 'Rho' );
    title(ax3,{['Correlation by time']} )
    
    xlabel(ax4,'Total Power');
    ylabel(ax4, 'ERP Power (uV)' );
    
    title(ax4,{['Correlation Total Power-ERP by subject'] ['at times ' scattitle]})
    
    
end

if ~isempty(Deci.Plot.CFC)
    
    for met = 1:size(CFCData,3)
        for subj = 1:size(CFCData,1)
            
            if Deci.Plot.CFC.Square
                CFCsquare(subj,met) = figure;
            end
            
            if Deci.Plot.CFC.Topo
                CFCtopo(subj,met)  = figure;
            end
            
            if Deci.Plot.CFC.Hist
                CFChist(subj,met)  = figure;
            end
            
            for cond = 1:size(CFCData,2)
                
                if Deci.Plot.CFC.Topo
                    set(0, 'CurrentFigure', CFCtopo(subj,met) )
                    CFCtopo(subj,met).Visible = 'on';
                    
                    ctopo(subj,cond,met)    =  subplot(size(CFCData,1),2,cond);
                    
                    
                    Cross.labelcmb = CombVec(CFCData{subj,cond,1}.labellow',CFCData{subj,cond,1}.labelhigh')';
                    Cross.freq = CFCData{subj,cond,1}.freqlow;
                    Cross.cohspctrm = CFCData{subj,cond,met}.crsspctrm(:,:,2);
                    Cross.dimord = CFCData{subj,cond,1}.dimord;
                    
                    Crosscfg =[];
                    Crosscfg.foi = [min([Deci.Plot.CFC.freqhigh Deci.Plot.CFC.freqlow]) max([Deci.Plot.CFC.freqhigh Deci.Plot.CFC.freqlow])];
                    Crosscfg.layout = Deci.Layout.Noeye;
                    title([Deci.SubjectList{subj} ' ' Deci.Plot.CFC.methods{met} ' Cond '  num2str(cond)],'Interpreter', 'none');
                    %               ft_topoplotCC(Crosscfg,Cross);
                    
                    ctopo(subj,cond,met).UserData = {Cross,Crosscfg,CFCData{subj,cond,met}.crsspctrm};
                end
                
                if Deci.Plot.CFC.Hist
                    set(0, 'CurrentFigure', CFChist(subj,met) )
                    CFChist(subj,met).Visible = 'on';
                    
                    chist(subj,cond,met)    =  subplot(size(CFCData,1),2,cond);
                    chist(subj,cond,met).UserData = CFCData{subj,cond,met}.crsspctrm;
                    bar(reshape(CFCData{subj,cond,met}.crsspctrm,[size(CFCData{subj,cond,met}.crsspctrm,1)*size(CFCData{subj,cond,met}.crsspctrm,2) size(CFCData{subj,cond,met}.crsspctrm,3)]));
                    
                    title([Deci.SubjectList{subj} ' ' Deci.Plot.CFC.methods{met} ' Cond '  num2str(cond)],'Interpreter', 'none');
                    
                end
                
                
                if Deci.Plot.CFC.Square
                    
                    set(0, 'CurrentFigure', CFCsquare(subj,met) )
                    CFCsquare(subj,met).Visible = 'on';
                    csquare(subj,cond,met)    =  subplot(size(CFCData,1),2,cond);
                    
                    xdat = CFCData{subj,cond,1}.labellow;
                    ydat = CFCData{subj,cond,1}.labelhigh;
                    PLVim = imagesc(1:length(xdat),1:length(ydat),CFCData{subj,cond,met}.crsspctrm(:,:,1));
                    xticks(1:length(xdat));
                    xticklabels(xdat);
                    yticks(1:length(ydat))
                    yticklabels(ydat);
                    title([Deci.SubjectList{subj} ' ' Deci.Plot.CFC.methods{met} ' Cond '  num2str(cond)],'Interpreter', 'none');
                    
                    csquare(subj,cond,met).UserData = CFCData{subj,cond,met}.crsspctrm;
                    colorbar;
                end
            end
            
            if Deci.Plot.CFC.Hist
                set(0, 'CurrentFigure', CFChist(subj,met));
                UpdateAxes(chist(subj,:,met),Deci.Plot.CFC.Roi,'Y',0)
                
                for HistLim = 1:length(chist(subj,:,met))
                    
                    chist(subj,HistLim,met).YLim(1) = chist(subj,HistLim,met).YLim(1) *.98;
                    chist(subj,HistLim,met).YLim(2) = chist(subj,HistLim,met).YLim(2) *1.02;
                    
                    Vect = CombVec(CFCData{subj,cond,met}.labellow',CFCData{subj,cond,met}.labelhigh')';
                    
                    xticklabels(chist(subj,HistLim,met), arrayfun(@(c) [Vect{c,1} Vect{c,2}],1:size(Vect,2),'un',0));
                    xtickangle(chist(subj,HistLim,met),-20);
                    
                    legend(chist(subj,HistLim,met),[repmat('FreqLow Time ',[size(CFCData{subj,cond,met}.timelow',1) 1]) num2str([CFCData{subj,cond,met}.timelow']) repmat(' - FreqHigh Time ',[size(CFCData{subj,cond,met}.timelow',1) 1]) num2str([CFCData{subj,cond,met}.timelow'])])
                end
            end
            
            
            if Deci.Plot.CFC.Topo
                
                set(0, 'CurrentFigure', CFCtopo(subj,met) )
                uicontrol('style','text','position',[225 75 100 25],'String','Time of Interest');
                
                slide = uicontrol('style','slider','position',[75 10 400 20],...
                    'min',1,'max',size(CFCData{1,subj,met}.crsspctrm,3),'callback',{@ChangeDimTopo,ctopo(subj,:,met),Deci.Plot.CFC.Roi}, ...
                    'value',1,'SliderStep',[1/size(CFCData{1,subj,met}.crsspctrm,3) 1/size(CFCData{1,subj,met}.crsspctrm,3)]);
                
                ChangeDimTopo(slide,[],ctopo(subj,:,met),Deci.Plot.CFC.Roi);
                
                
                for tick = 1:size(CFCData{1,subj,met}.crsspctrm,3)
                    uicontrol('style','text','position',[75+[[[slide.Position(3)]/5]*[tick-1]]+20 55 40 25],'String',num2str(round(CFCData{1,subj,met}.timelow(tick),2)));
                    uicontrol('style','text','position',[75+[[[slide.Position(3)]/5]*[tick-1]]+20 30 40 25],'String',num2str(round(CFCData{1,subj,met}.timehigh(tick),2)));
                end
                uicontrol('style','text','position',[45 55 60 25],'String','FreqLow');
                uicontrol('style','text','position',[45 30 60 25],'String','FreqHigh');
            end
            
            
            if Deci.Plot.CFC.Square
                
                set(0, 'CurrentFigure', CFCsquare(subj,met) )
                uicontrol('style','text','position',[225 75 100 25],'String','Time of Interest');
                
                slide = uicontrol('style','slider','position',[75 10 400 20],...
                    'min',1,'max',size(CFCData{1,subj,met}.crsspctrm,3),'callback',{@ChangeDim,csquare(subj,:,met),Deci.Plot.CFC.Roi,'C'}, ...
                    'value',1,'SliderStep',[1/size(CFCData{1,subj,met}.crsspctrm,3) 1/size(CFCData{1,subj,met}.crsspctrm,3)]);
                
                UpdateAxes(csquare(subj,:,met),Deci.Plot.CFC.Roi,'C',1);
                
                for tick = 1:size(CFCData{1,subj}.crsspctrm,3)
                    uicontrol('style','text','position',[75+[[[slide.Position(3)]/5]*[tick-1]]+20 55 40 25],'String',num2str(round(CFCData{1,subj,met}.timelow(tick),2)));
                    uicontrol('style','text','position',[75+[[[slide.Position(3)]/5]*[tick-1]]+20 30 40 25],'String',num2str(round(CFCData{1,subj,met}.timehigh(tick),2)));
                end
                uicontrol('style','text','position',[45 55 60 25],'String','FreqLow');
                uicontrol('style','text','position',[45 30 60 25],'String','FreqHigh');
            end
            
        end
        
    end
    
end

    function ChangeDim(popup,event,Axes,Roi,Lim)
        popup.Value = round(popup.Value);
        
        for i = 1:length(Axes)
            Axes(i).Children.CData = Axes(i).UserData(:,:,popup.Value);
        end
        
        UpdateAxes(Axes,Roi,Lim,1)
        
    end

    function UpdateAxes(Axes,Roi,Lim,Userdata)
        
        if Userdata == 1
            Dats = cell2mat(arrayfun(@(c) c.UserData,Axes,'un',0));
        else
            Dats = cell2mat(arrayfun(@(c) [c.Children.([Lim 'Data'])],Axes,'un',0));
        end
        
        for Axe = 1:length(Axes(:))
            if isequal(Roi,'maxmin')
                Axes(Axe).([Lim 'Lim']) = [min(Dats(:)) max(Dats(:))];
            elseif isequal(Roi,[0 1])
                Axes(Axe).([Lim 'Lim']) = [0 1];
            elseif length(Roi) == 2 && isnumeric(Roi)
                Axes(Axe).([Lim 'Lim']) = Roi;
            end
        end
    end

    function ChangeDimTopo(popup,event,Axes,Roi)
        popup.Value = round(popup.Value);
        
        if isequal(Roi,'maxmin')
            CLim = cell2mat(arrayfun(@(c) c.UserData{3},Axes,'un',0));
        elseif isequal(Roi,[0 1])
            CLim = [0 1];
        elseif length(Roi) == 2 && isnumeric(Roi)
            CLim = Roi;
        end
        
        for Axe =  1:length(Axes)
            set(Axes(Axe).Parent, 'currentaxes', Axes(Axe))
            
            NewCross = Axes(Axe).UserData{1};
            NewCross.cohspctrm =  Axes(Axe).UserData{3}(:,:,popup.Value);
            NewCrossCfg = Axes(Axe).UserData{2};
            NewCrossCfg.CLim = minmax(CLim(:)');
            ft_topoplotCC(NewCrossCfg ,NewCross);
            
        end
        
    end

end

