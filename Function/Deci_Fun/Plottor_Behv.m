
function Plottor_Behv(Deci)

for subject_list = 1:length(Deci.SubjectList)
    
    data = [];
    
    switch Deci.Plot.Behv.Source
        case 'PostArt'
            load([Deci.Folder.Artifact filesep Deci.SubjectList{subject_list} '_info']);
            data.trialinfo = data.condinfo{1};
            data.event = data.condinfo{2};
            data.trialnum = data.condinfo{3};
            
            data.full = data.preart(2:3);
            
        case 'Definition'
            load([Deci.Folder.Version filesep 'Definition' filesep Deci.SubjectList{subject_list}]);
            data = cfg;
            data.trialinfo = data.trl(:,end-length(Deci.DT.Locks)+1:end);
            
            data.full{1} = data.event;
            data.full{2} = data.trialnum;
    end
    
    
    for fig = find(Deci.Plot.Behv.RT.Figure)
        if ~isempty(Deci.Plot.Behv.RT)
            
            if length(Deci.DT.Locks) <2 || length(Deci.Plot.Behv.RT.Locks) ~= 2
                error('DT.Locks seems to not have enough to calculate Locks(2)-Locks(1)')
            end
            
            if isempty(Deci.Plot.Behv.RT.Block)
                Deci.Plot.Behv.RT.Block = {-1};
            end
            
            
            for blk = 1:length(Deci.Plot.Behv.RT.Block)
                for draw = 1:length(Deci.Plot.Behv.RT.Draw{fig})
                    
                    
                    if any(any(data.event < 0))
                        iblk = -1;
                    else
                        iblk = 1;
                    end
                    
                    draws = Deci.Analysis.Conditions(Deci.Plot.Behv.RT.Draw{fig}{draw});
                                        
                    if isfield(Deci.Plot.Behv,'Static')
                       
                        if sum(ismember(Deci.Plot.Behv.Static,[draws{:}])) == 1
                            
                           eve = data.event(logical(sum(ismember(data.event,Deci.Plot.Behv.Static(ismember(Deci.Plot.Behv.Static,[draws{:}]))),2)),:);
                           eve = eve(find(any(ismember(eve,iblk*Deci.Plot.Behv.RT.Block(blk)),2)),:);
                        else
                           eve = data.event;
                        end
                    else
                        eve = data.event;
                    end
                    
                    eveTotal = nan([1 length(find(any(ismember(eve,iblk*Deci.Plot.Behv.RT.Block(blk)),2)))]);
                    
                    maxt = max(sum(ismember(eve,[draws{:}]),2));
                    trl = [sum(ismember(eve,[draws{:}]),2) == maxt];
                    
                    eveTotal(trl) =  [-data.trialinfo(trl,Deci.Plot.Behv.RT.Locks(2)) - -data.trialinfo(trl,Deci.Plot.Behv.RT.Locks(1))];
                    
                    
                    RT{fig}(subject_list,draw,blk,:) = eveTotal;
                    
                    
                end
            end
            
            %disp([Deci.SubjectList{subject_list} ' RT:']);
            %disp(RT(subject_list,:,:));
        end
    end
    
    for fig = find(Deci.Plot.Behv.Acc.Figure)
        
        if ~isempty(Deci.Plot.Behv.Acc)
            Exist(Deci.Plot.Behv.Acc,'Total');
            Exist(Deci.Plot.Behv.Acc,'Subtotal');
            
            if isempty(Deci.Plot.Behv.Acc.Block)
                Deci.Plot.Behv.Acc.Block = {-1};
            end
            
            
            for blk = 1:length(Deci.Plot.Behv.Acc.Block)
                for draw = 1:length(Deci.Plot.Behv.Acc.Total{fig})
                    
                    if any(any(data.event < 0))
                        iblk = -1;
                    else
                        iblk = 1;
                    end
                    
                    draws = Deci.Analysis.Conditions(Deci.Plot.Behv.Acc.Total{fig}{draw});
                    
                    if isfield(Deci.Plot.Behv,'Static')
                       
                        if sum(ismember(Deci.Plot.Behv.Static,[draws{:}])) == 1
                            
                           eve = data.event(logical(sum(ismember(data.event,Deci.Plot.Behv.Static(ismember(Deci.Plot.Behv.Static,[draws{:}]))),2)),:);
                           eve = eve(find(any(ismember(eve,iblk*Deci.Plot.Behv.Acc.Block(blk)),2)),:);
                        else
                           eve = data.event;
                        end
                    else
                        eve = data.event;
                    end
                    
                    eveTotal = nan([1 length(find(any(ismember(eve,iblk*Deci.Plot.Behv.Acc.Block(blk)),2)))]);
                    
                    maxt = max(sum(ismember(eve,[draws{:}]),2));
                    trl = find([[sum(ismember(eve,[draws{:}]),2)] == maxt]);
                    
                    eveTotal(trl) = 0;
                    
                    subdraws = Deci.Analysis.Conditions(Deci.Plot.Behv.Acc.Subtotal{fig}{draw});
                    maxt2 = max(sum(ismember(eve,[subdraws{:}]),2));
                    subtrl = [[sum(ismember(eve,[subdraws{:}]),2) ] == maxt2];
                    
                    eveTotal(subtrl) = 1;
                    
                    Acc{fig}(subject_list,draw,blk,:) = eveTotal;

                    
                    
                    Deci.Plot.Behv.Acc.Collapse = Exist(Deci.Plot.Behv.Acc.Collapse,'Movmean',[]);
                    
                    
                    if ~isempty(Deci.Plot.Behv.Acc.Collapse.Movmean)
                        
                        if Deci.Plot.Behv.Acc.Collapse.Movmean(fig)
                            
                            if isfield(Deci.Plot.Behv.Acc.Collapse,'MovWindow')
                                
                                MovWindow = Deci.Plot.Behv.Acc.Collapse.MovWindow;
                                
                                if MovWindow == -1
                                    MovWindow = length( Acc{fig}(subject_list,draw,blk,:));
                                end
                                
                            else
                                MovWindow = length( Acc{fig}(subject_list,draw,blk,:));
                            end
                            
                            Acc{fig}(subject_list,draw,blk,:) = movmean(Acc{fig}(subject_list,draw,blk,:),[MovWindow 0],'omitnan');
                        end
                    end
                end
            end
            
            %disp([Deci.SubjectList{subject_list} ' Acc:']);
            %disp(Acc(subject_list,:,:));
        end
        
    end
end

if ~isempty(Deci.Plot.Behv.Acc) && ~isempty(find(Deci.Plot.Behv.Acc.Figure))
    mkdir([Deci.Folder.Version filesep 'Plot'])
    save([Deci.Folder.Version filesep 'Plot' filesep 'Acc'],'Acc');
end

if ~isempty(Deci.Plot.Behv.RT) &&  ~isempty(find(Deci.Plot.Behv.RT.Figure))
    mkdir([Deci.Folder.Version filesep 'Plot'])
    save([Deci.Folder.Version filesep 'Plot' filesep 'RT'],'RT');
end

%% sort

for fig = find(Deci.Plot.Behv.Acc.Figure)
    
    clear fAcc

    if ~isempty(Deci.Plot.Behv.Acc) && ~isempty(find(Deci.Plot.Behv.Acc.Figure))
        fullAcc{fig} = Acc{fig};
        
        if Deci.Plot.Behv.Acc.Collapse.Trial
            Accsem{fig} = nanstd(Acc{fig},[],4)/sqrt(size(Acc{fig},4));
            Acc{fig} = nanmean(Acc{fig},4);
            
        end
        
        if Deci.Plot.Behv.Acc.Collapse.Block
            Accsem{fig} = nanstd(Acc{fig},[],3)/sqrt(size(Acc{fig},3));
            Acc{fig} = nanmean(Acc{fig},3);
            
        end
        
        Sub.Acc = Deci.SubjectList;
        if Deci.Plot.Behv.Acc.Collapse.Subject
            Accsem{fig} =  nanstd(Acc{fig},[],1)/sqrt(size(Acc{fig},1));
            Acc{fig} =  nanmean(Acc{fig},1);
            
            Sub.Acc = {'SubjAvg'};
        end
        
        save([Deci.Folder.Version filesep 'Plot' filesep 'SimAcc'],'Acc','fullAcc');
    end
end

for fig = find(Deci.Plot.Behv.RT.Figure)
        clear fRT
    if ~isempty(Deci.Plot.Behv.RT) &&  ~isempty(find(Deci.Plot.Behv.RT.Figure))

        fullRT{fig} = RT{fig};
        
        if Deci.Plot.Behv.RT.Collapse.Trial
            RTsem{fig} = nanstd(RT{fig},[],4)/sqrt(size(RT{fig},4));
            RT{fig} = nanmean(RT{fig},4);
        end
        
        if Deci.Plot.Behv.RT.Collapse.Block
            RTsem{fig} = nanstd(RT{fig},[],3)/sqrt(size(RT{fig},3));
            RT{fig} = nanmean(RT{fig},3);
        end
        
        Sub.RT = Deci.SubjectList;
        if Deci.Plot.Behv.RT.Collapse.Subject
            RTsem{fig} = nanstd(RT{fig},[],1)/sqrt(size(RT{fig},1));
            RT{fig} =  nanmean(RT{fig},1);
            Sub.RT = {'SubjAvg'};
        end
        
        save([Deci.Folder.Version filesep 'Plot' filesep 'SimRT'],'RT','fullRT');
    end
    
end

%% Table outputs for SPSS


Deci.Plot.Behv = Exist(Deci.Plot.Behv,'WriteExcel',false);

if Deci.Plot.Behv.WriteExcel

for fig = find(Deci.Plot.Behv.Acc.Figure)
    
    subs= [];
    conds = [];
    blks = [];
    trls = [];

    
    for sub = 1:size(fullAcc{fig},1)
        for cond = 1:size(fullAcc{fig},2)
            for blk = 1:size(fullAcc{fig},3)
                for trl = 1:size(fullAcc{fig},4)
                    subs(end+1) =  sub;
                    conds(end+1) = cond;
                    blks(end+1) = blk;
                    trls(end+1) = trl;
                end
                
            end
        end
    end
    excelAccdata = table(Deci.SubjectList(subs)',Deci.Plot.Behv.Acc.Subtitle{fig}(conds)',blks',trls',fullAcc{fig}(:),'VariableNames',{'Subj' 'Cond' 'Blk' 'Trl','Accuracy'});
    writetable(excelAccdata,[Deci.Folder.Plot filesep  Deci.Plot.Behv.Acc.Title{fig} ' Behavioral Outputs' ],'FileType','spreadsheet','Sheet','Accuracy_Full');
    
    subs= [];
    conds = [];
    blks = [];
    trls = [];

    for sub = 1:size(Acc{fig},1)
        for cond = 1:size(Acc{fig},2)
            for blk = 1:size(Acc{fig},3)
                for trl = 1:size(Acc{fig},4)
                    subs(end+1) =  sub;
                    conds(end+1) = cond;
                    blks(end+1) = blk;
                    trls(end+1) = trl;
                end
            end
        end
    end
    
    
    fAcc = Acc{fig}';
    fAccsem = Accsem{fig}';
    
    
    excelAccdata = table(Deci.SubjectList(subs)',Deci.Plot.Behv.Acc.Subtitle{fig}(conds)',blks',trls',fAcc(:),fAccsem(:),'VariableNames',{'Subj' 'Cond' 'Blk'  'Trl' 'Accuracy' 'SEM'});
    writetable(excelAccdata,[Deci.Folder.Plot filesep Deci.Plot.Behv.Acc.Title{fig} ' Behavioral Outputs' ],'FileType','spreadsheet','Sheet','Accuracy_Summary');
    
end

for fig = find(Deci.Plot.Behv.RT.Figure)
    
    subs= [];
    conds = [];
    blks = [];
    trls = [];
    
    
    for sub = 1:size(fullRT{fig},1)
        for cond = 1:size(fullRT{fig},2)
            for blk = 1:size(fullRT{fig},3)
                for trl = 1:size(fullRT{fig},4)
                    subs(end+1) =  sub;
                    conds(end+1) = cond;
                    blks(end+1) = blk;
                    trls(end+1) = trl;
                end
            end
        end
    end
    
    excelAccdata = table(subs',conds',blks',trls',fullRT{fig}(:),'VariableNames',{'Subj' 'Cond' 'Blk' 'Trl','ReactonTime'});
    writetable(excelAccdata,[Deci.Folder.Plot filesep  Deci.Plot.Behv.RT.Title{fig} ' Behavioral Outputs' ],'FileType','spreadsheet','Sheet','RT_Full');
    
    subs= [];
    conds = [];
    blks = [];
    trls = [];
    
    
    for sub = 1:size(RT{fig},1)
        for cond = 1:size(RT{fig},2)
            for blk = 1:size(RT{fig},3)
                for trl = 1:size(RT{fig},4)
                    subs(end+1) =  sub;
                    conds(end+1) = cond;
                    blks(end+1) = blk;
                    trls(end+1) = trl;
                end
            end
        end
    end
    
    fRT = RT{fig}';
    fRTsem = RT{fig}';
    
    
    excelAccdata = table(Deci.SubjectList(subs)',conds',blks',trls',fRT(:),fRTsem(:),'VariableNames',{'Subj' 'Cond' 'Blk'  'Trl' 'ReactionTime','SEM'});
    writetable(excelAccdata,[Deci.Folder.Plot filesep Deci.Plot.Behv.RT.Title{fig} ' Behavioral Outputs' ],'FileType','spreadsheet','Sheet','RT_Summary');
    
end
end

%% plot


for fig = find(Deci.Plot.Behv.Acc.Figure)
    
    
    if ~isempty(Deci.Plot.Behv.Acc)
        for subj = 1:size(Acc{fig},1)
            
            a = figure;
            a.Visible = 'on';
            
            
            for draw = 1:size(Acc{fig},2)
                
                
                if length(find(size(squeeze(Acc{fig}(subj,draw,:,:))) ~= 1)) ==1
                    
                    top = squeeze(Acc{fig}(subj,draw,:,:))*100 + squeeze(Accsem{fig}(subj,draw,:,:))*100;
                    bot = squeeze(Acc{fig}(subj,draw,:,:))*100 - squeeze(Accsem{fig}(subj,draw,:,:))*100;
                    
                    shapes = [1:length(Acc{fig}(subj,draw,:,:)) length(Acc{fig}(subj,draw,:,:)):-1:1];
                    shapes(isnan([top' fliplr(bot')])) = nan;
                    
                    pgon = polyshape(shapes,[top' fliplr(bot')],'Simplify', false);
                    b = plot(pgon,'HandleVisibility','off');
                    hold on
                    b.EdgeAlpha = 0;
                    b.FaceAlpha = .15;
                    
                    h = plot(squeeze(Acc{fig}(subj,draw,:))*100);
                    h.Parent.YLim = [0 100];
                    h.Color = b.FaceColor;
                    h.LineWidth = 1;
                    hold on;
                    title(h.Parent,[Sub.Acc{subj} ' ' Deci.Plot.Behv.Acc.Title{fig}],'Interpreter','none');
                    
                    if ~Deci.Plot.Behv.Acc.Collapse.Block && length(find(size(squeeze(Acc{fig}(subj,draw,:,:))) ~= 1)) ==1
                        h.Parent.XLabel.String = 'Block #';
                    elseif ~Deci.Plot.Behv.Acc.Collapse.Trial && length(find(size(squeeze(Acc{fig}(subj,draw,:,:))) ~= 1)) ==1
                        h.Parent.XLabel.String = 'Trial #';
                    end
                           
                    h.Parent.YLabel.String = 'Percent (%)';
                    legend(h.Parent,[ Deci.Plot.Behv.Acc.Subtitle{fig}]);
                    
                elseif length(find(size(squeeze(Acc{fig}(subj,draw,:,:))) ~= 1)) ==2
                    
                    subplot(size(Acc{fig},2),1,draw)
                    h = imagesc(squeeze(Acc{fig}(subj,draw,:,:))*100);
                    h.Parent.CLim = [0 100];
                    h.Parent.YLabel.String = 'Block #';
                    h.Parent.XLabel.String = 'Trial #';
                    title(h.Parent,[Sub.Acc{subj} ' ' Deci.Plot.Behv.Acc.Subtitle{fig}{draw}],'Interpreter','none');
                    
                else
                    disp(['Acc Total for ' Sub.Acc{subj} ' ' Deci.Plot.Behv.Acc.Title{fig} ' ' num2str(squeeze(Acc{fig}(subj,draw,:,:))*100) '%' ' +- ' num2str(squeeze(Accsem{fig}(subj,draw,:,:))*100)]);
                    
                    if draw == 1
                        CleanBars(Acc{fig}(subj,:,:,:),Accsem{fig}(subj,:,:,:))
                        ylim([0 1]);
                        title(['Acc Total for ' Sub.Acc{subj} ': ' Deci.Plot.Behv.Acc.Title{fig} ' '],'Interpreter','none')
                        legend([Deci.Plot.Behv.Acc.Subtitle{fig}])
                        xticklabels(Sub.Acc{subj})
                        ylabel('Accuracy (Percent)')
                        %disp(num2str(squeeze(Acc(subj,draw,:,:))*100))
                    end
                    
                end
                
                
            end
            
            if length(find(size(squeeze(Acc{fig}(subj,draw,:,:))) ~= 1)) == 2
                suptitle([Sub.Acc{subj} ' ' Deci.Plot.Behv.Acc.Title{fig}]);
            end
        end
        
        
    end
end


for fig = find(Deci.Plot.Behv.RT.Figure)
    
    if ~isempty(Deci.Plot.Behv.RT) &&  ~isempty(find(Deci.Plot.Behv.RT.Figure))
        for subj = 1:size(RT{fig},1)
            
            
            b = figure;
            b.Visible = 'on';
            
            
            for draw = 1:size(RT{fig},2)
                
                
                if length(find(size(squeeze(RT{fig}(subj,draw,:,:))) ~= 1)) ==1
                    
                    
                    top = squeeze(RT{fig}(subj,draw,:,:)) + squeeze(RTsem{fig}(subj,draw,:,:));
                    bot = squeeze(RT{fig}(subj,draw,:,:)) - squeeze(RTsem{fig}(subj,draw,:,:));
                    
                    top = top(~isnan(top));
                    bot = bot(~isnan(bot));
               
                    pgon = polyshape([1:length(find(~isnan(RT{fig}(subj,draw,:,:)))) length(find(~isnan(RT{fig}(subj,draw,:,:)))):-1:1],[top' fliplr(bot')],'Simplify', false);
                    b = plot(pgon,'HandleVisibility','off');
                    hold on
                    b.EdgeAlpha = 0;
                    b.FaceAlpha = .15;
                    
                    h = plot(squeeze(RT{fig}(subj,draw,:)));
                    h.Color = b.FaceColor;
                    h.LineWidth = 1;
                    hold on;
                    
                    title(h.Parent,[Sub.RT{subj} ' ' Deci.Plot.Behv.RT.Title{fig}],'Interpreter','none');
                    
                    if ~Deci.Plot.Behv.RT.Collapse.Block && length(find(size(squeeze(RT{fig}(subj,draw,:,:))) ~= 1)) ==1
                        h.Parent.XLabel.String = 'Block #';
                    elseif ~Deci.Plot.Behv.RT.Collapse.Trial && length(find(size(squeeze(RT{fig}(subj,draw,:,:))) ~= 1)) ==1
                        h.Parent.XLabel.String = 'Trial #';
                    end
                    
                    h.Parent.YLabel.String = 'Reaction Time (ms)';
                    legend(h.Parent,[Deci.Plot.Behv.RT.Subtitle{fig}]);
                    
                elseif length(find(size(squeeze(RT{fig}(subj,draw,:,:))) ~= 1)) ==2
                    
                    subplot(size(RT{fig},2),1,draw)
                    h = imagesc(squeeze(RT{fig}(subj,draw,:,:)));
                    h.Parent.YLabel.String = 'Block #';
                    h.Parent.XLabel.String = 'Trial #';
                    title(h.Parent,[Sub.RT{subj} ' ' Deci.Plot.Behv.RT.Subtitle{fig}{draw}],'Interpreter','none');
                    
                else
                    disp(['RT Total for ' Sub.RT{subj} ' ' Deci.Plot.Behv.RT.Subtitle{fig}{draw} ' ' num2str(squeeze(RT{fig}(subj,draw,:,:))) ' +- ' num2str(squeeze(RTsem{fig}(subj,draw,:,:)))])
                    
                    if draw == 1
                        CleanBars(RT{fig}(subj,:,:,:),RTsem{fig}(subj,:,:,:))
                        title(['RT Total for ' Sub.Acc{subj} ': ' Deci.Plot.Behv.RT.Title{fig} ' '],'Interpreter','none')
                        legend([Deci.Plot.Behv.RT.Subtitle{fig}])
                        xticklabels(Sub.RT{subj})
                        ylabel('Reaction Time (ms)')
                    end
                end
                
            end
            
            if length(find(size(squeeze(RT{fig}(subj,draw,:,:))) ~= 1)) ==2
                suptitle([Sub.RT{subj} ' ' Deci.Plot.Behv.RT.Title{fig}]);
            end
            
        end
        
        
    end
end

end
