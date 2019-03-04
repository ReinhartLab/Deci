function trl = expfunor(cfg)

startstop ={cfg.DT.Starts{:} cfg.DT.Ends{:}};
startstop = cellfun(@num2str,startstop,'un',0);
sstime = cfg.DT.Toi;

cfg.DT = Exist(cfg.DT,'Beha',[]);
cfg.DT.Beha = Exist(cfg.DT.Beha,'Acc',[]);
cfg.DT.Beha = Exist(cfg.DT.Beha,'RT',[]);

cfg.DT = Exist(cfg.DT,'Conditions',1:length(cfg.DT.Markers));

if ~strcmp(cfg.file_ending,'.mat')
    event = ft_read_event(cfg.dataset);
    hdr   = ft_read_header(cfg.dataset);
else
    events = [];
    load(cfg.dataset,'events');
    event = events;
    hdr.Fs = 1;
end

trl = [];

event =  StandardizeEventMarkers(event);

if rem(length(find(ismember({event.value},startstop)')),2) ~= 0
    error('invalid number of start and end pairings, check data!')
end

startstopseg = reshape(find(ismember({event.value},startstop)'),[2 length(find(ismember({event.value},startstop)'))/2]);

eachcond = unique(cfg.DT.Conditions);
RunningAccuracy= cell([1 length(eachcond)]);
RunningRT= cell([1 length(eachcond)]);

for j = 1:length(startstopseg)
    
    value = {event(startstopseg(1,j):startstopseg(2,j)).value};
    value = cellfun(@str2num,value);
    sample = {event(startstopseg(1,j):startstopseg(2,j)).sample};
    
    for i = 1:length(eachcond)
        
        markers = cfg.DT.Markers(ismember(cfg.DT.Conditions,eachcond(i)));
        
        posvalue = cell2mat(cellfun(@(c) all(ismember(c(c >= 0),value)),markers,'un',0));
        negvalue = cell2mat(cellfun(@(c) all(~ismember(abs(c(c <= 0)),value)),markers,'un',0));
        
        condvalue = find(posvalue & negvalue);
        
        if length(condvalue) == 1
            
            condlock = [];
            condlock = sample{ismember(value,cfg.DT.Locks)};
            
            begsample = condlock + sstime(1)*hdr.Fs;
            endsample = condlock + sstime(2)*hdr.Fs;
            offset        = sstime(1)*hdr.Fs;
           
            trl(end + 1,:) = [begsample endsample offset  i+condvalue*.01];
            
            if ~isempty(cfg.DT.Beha)
                
                if ~isempty(cfg.DT.Beha.Acc)
                    submarkers = cfg.DT.Beha.Acc(ismember(cfg.DT.Conditions,eachcond(i)));
                    
                    possubvalue = cell2mat(cellfun(@(c) all(ismember(c(c >= 0),value)),submarkers(condvalue),'un',0));
                    negsubvalue = cell2mat(cellfun(@(c) all(~ismember(abs(c(c <= 0)),value)),submarkers(condvalue),'un',0));
                    
                    condsubvalue = find(possubvalue & negsubvalue);
                    
                    if length(condsubvalue) == 1
                        
                        RunningAccuracy{i}(end+1) = 1;
                        
                    elseif length(condsubvalue) > 1
                        warning(['trial ' num2str(j) ' satisfies 2 or more behavioral definitions']);
                    else
                        RunningAccuracy{i}(end+1) = 0;
                    end
                end
                
                if ~isempty(cfg.DT.Beha.RT)
                    submarkers = cfg.DT.Beha.RT(ismember(cfg.DT.Conditions,eachcond(i)));
                    
                    RT = diff([sample{ismember(value,submarkers{condvalue})}]);
                    
                    
                    if length(RT) == 1
                        
                        RunningRT{i}(end+1) = RT;
                        
                    else
                        warning(['trial reaction time not found']);
                    end
                end
                
            end
            
        elseif length(condvalue) > 1
            error(['trial ' num2str(j) ' satisfies 2 or more trial definitions']);
        end
    end
end

if ~isempty(cfg.DT.Beha)
    
    if ~isempty(cfg.DT.Beha.Acc)
        
        disp(['Accuracy Perc: ' num2str(cellfun(@mean,RunningAccuracy))]);
    end
    if ~isempty(cfg.DT.Beha.RT)
        disp(['Reaction Time: ' num2str(cellfun(@mean,RunningRT))]);
    end
end

