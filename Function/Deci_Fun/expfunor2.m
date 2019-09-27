function [trl,trialinfo] = expfunor(cfg)

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

if ~isempty(cfg.DT.Block)
    
    
    for sets = 1:size(cfg.DT.Block.Markers)
        
        bstartstop{sets} = [cfg.DT.Block.Markers(:)];
        bstartstop{sets} = cellfun(@num2str,bstartstop{sets},'un',0);
        
        bstartstop{sets} = [find(ismember({event.value},bstartstop{sets}))];
        
    end
end

for j = 1:length(startstopseg)
    
    value = {event(startstopseg(1,j):startstopseg(2,j)).value};
    value = cellfun(@str2num,value);
    sample = {event(startstopseg(1,j):startstopseg(2,j)).sample};
    
    begsample = sample{1} + sstime(1)*hdr.Fs;
    endsample = sample{end} + sstime(2)*hdr.Fs;
    
    offsets = begsample - [sample{ismember(value,cfg.DT.Locks)}];
    
    trl(end + 1,1:4+length(cfg.DT.Locks)) = nan;
    trl(end ,1:4) = [begsample endsample 0 j];
    
    trl(end,logical([0 0 0 0 ismember(cfg.DT.Locks,value)])) = offsets;
    
    
    for i = 1:length(cfg.DT.Markers)
        
        if any(ismember([cfg.DT.Markers{i}],value))
            
            
            trialinfo(size(trl,1),i) = cfg.DT.Markers{i}(ismember([cfg.DT.Markers{i}],value));
        else
            trialinfo(size(trl,1),i) = nan;
        end
    end
    
    if ~isempty(cfg.DT.Block)
        
        for sets = 1:size(cfg.DT.Block.Markers)
            
            trialinfo(size(trl,1),length(cfg.DT.Markers)+1) = nan;
            
            trialinfo(size(trl,1),length(cfg.DT.Markers)+1) = [-10*[sets-1]]+[-1*find([event(startstopseg(1,j)).sample] >  [event(bstartstop{sets}).sample],1,'last')];

            
        end
        
    end
    
    
end

if ~isempty(cfg.DT.Block)
   
    for bisect = Deci.DT.Block.Bisect
        
       bisextindex =  -10*[sets-1];
        
    end
    
end



if isfield(cfg.DT,'Displace')
    
    cfg.DT.Displace = Exist(cfg.DT.Displace,'Num',0);
    
    
    
    
    if cfg.DT.Displace.Num ~= 0
        
        blk = sort(unique(trialinfo(:,end)),'descend');
        
        blkpos = find(mean(trialinfo < 0));
        
        
        Displace = cfg.DT.Displace.Num;
        
        for dura = 1:cfg.DT.Displace.Duration
            
            for stat = 1:length(cfg.DT.Displace.Static)
                
                statictrialinfo = trialinfo(logical(sum(ismember(trialinfo,cfg.DT.Displace.Static(stat)),2)),:);
                statictrl = trl(logical(sum(ismember(trialinfo,cfg.DT.Displace.Static(stat)),2)),:);
                
                
                for dis = 1:length(blk)
                    
                    block{stat,dis,dura}  = statictrialinfo(find(statictrialinfo(:,blkpos) == blk(dis)),:);
                    
                    shift{stat,dis,dura} = statictrl(find(statictrialinfo(:,blkpos) == blk(dis)),:);
                    
                    if ~isempty(cfg.DT.Displace.Markers)
                        
                        for dmrk = 1:length(cfg.DT.Displace.Markers)
                            
                            dmrks{stat,dis,dura} = statictrialinfo(find(statictrialinfo(:,blkpos) == blk(dis)),:);
                            
                            dmrks{stat,dis,dura} = dmrks{stat,dis,dura}(:,find(mean(ismember(dmrks{stat,dis,dura},cfg.DT.Displace.Markers{dmrk}))))+1000*dura;
                            
                            if cfg.DT.Displace.Num > 0
                                dmrks{stat,dis,dura} = [dmrks{stat,dis,dura}(1+[cfg.DT.Displace.Num+dura-1]:end);nan([cfg.DT.Displace.Num+dura-1 size(dmrks{stat,dis,dura},2)])];
                            else
                                dmrks{stat,dis,dura} = [nan([cfg.DT.Displace.Num+dura-1 size(dmrks{stat,dis,dura},2)]); dmrks{stat,dis,dura}(1:end-[cfg.DT.Displace.Num+dura-1])];
                            end
                            
                            block{stat,dis,dura} = [block{stat,dis,dura} dmrks{stat,dis,dura}];
                            
                        end
                    end
                    
                    
                end
                
            end
            
            Displace = Displace + 1;
            
            trl = cat(1,shift{:,:,dura});
            
            [strl,I] = sort(trl(:,1));
            
            trl = trl(I,:);
            
            trialinfo = cat(1,block{:,:,dura});
            trialinfo = trialinfo(I,:);
            
        end
        
        
        
    end
    
end


