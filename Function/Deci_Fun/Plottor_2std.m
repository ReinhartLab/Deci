function Plottor_2std(Deci,Params)

for subject_list = 1:length(Deci.SubjectList)
    
    data = [];
    
    switch Deci.Plot.Extra.Std.Source
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
    
    
    for fig = find(Deci.Plot.Extra.Std.Acc.Figure)
        
        
        if exist('Acc') == 0 || length(Acc) < fig
            Acc{fig} = [];
        end
        
        if ~isempty(Deci.Plot.Extra.Std.Acc)
            Exist(Deci.Plot.Extra.Std.Acc,'Total');
            Exist(Deci.Plot.Extra.Std.Acc,'Subtotal');
            
            
            if isa(Deci.Plot.Extra.Std.Acc.Block,'function_handle')
                data.event(:,find(data.event(1,:) < 1)) = Deci.Plot.Extra.Std.Acc.Block(data.event(:,find(data.event(1,:) < 1)));
                
                AccBlock= unique(data.event(:,find(data.event(1,:) < 1)),'stable');
            elseif isempty(Deci.Plot.Extra.Std.Acc.Block)
                AccBlock = {-1};
            end
            
            for blk = 1:length(AccBlock)
                for draw = 1:length(Deci.Plot.Extra.Std.Acc.Total{fig})
                    
                    draws = Deci.Analysis.Conditions(Deci.Plot.Extra.Std.Acc.Total{fig}{draw});
                    
                    if isfield(Deci.Plot.Extra.Std,'Static')
                        
                        if sum(ismember(Deci.Plot.Extra.Std.Static,[draws{:}])) == 1
                            
                            eve = data.event(logical(sum(ismember(data.event,Deci.Plot.Extra.Std.Static(ismember(Deci.Plot.Extra.Std.Static,[draws{:}]))),2)),:);
                        else
                            eve = data.event;
                        end
                    else
                        eve = data.event;
                    end
                    eve = eve(find(any(ismember(eve,AccBlock(blk)),2)),:);
                    
                    eveTotal = nan([1 length(find(any(ismember(eve,AccBlock(blk)),2)))]);
                    
                    maxt = max(sum(ismember(eve,[draws{:}]),2));
                    trl = find([[sum(ismember(eve,[draws{:}]),2)] == maxt]);
                    
                    eveTotal(trl) = 0;
                    
                    subdraws = Deci.Analysis.Conditions(Deci.Plot.Extra.Std.Acc.Subtotal{fig}{draw});
                    maxt2 = max(sum(ismember(eve,[subdraws{:}]),2));
                    subtrl = [[sum(ismember(eve,[subdraws{:}]),2) ] == maxt2];
                    
                    eveTotal(subtrl) = 1;
                    
                    if size(eveTotal,2) ~= size(Acc{fig},4) && size(Acc{fig},1) ~= 0
                        
                        if size(eveTotal,2) > size(Acc{fig},4)
                            Acc{fig} = cat(4, Acc{fig}, nan(size(Acc{fig},1),size(Acc{fig},2),size(Acc{fig},3),size(eveTotal,2)-size(Acc{fig},4)));
                            Acc{fig}(subject_list,draw,blk,:) = eveTotal;
                        else
                            eveTotal = [eveTotal nan([1 size(Acc{fig},4)-size(eveTotal,2)])];
                            Acc{fig}(subject_list,draw,blk,:) = eveTotal;
                        end
                        
                    else
                        Acc{fig}(subject_list,draw,blk,:) = eveTotal;
                    end
                    
                    
                    Deci.Plot.Extra.Std.Acc.Collapse = Exist(Deci.Plot.Extra.Std.Acc.Collapse,'Movmean',[]);
                end
            end
            
        end
        
    end
    
end

%% sort 

for fig = find(Deci.Plot.Extra.Std.Acc.Figure)
    
    clear fAcc

    if ~isempty(Deci.Plot.Extra.Std.Acc) && ~isempty(find(Deci.Plot.Extra.Std.Acc.Figure))
        fullAcc{fig} = Acc{fig};
        
%         Accstd{fig} = nanstd(Acc{fig},[],4);
        Acc{fig} = nanmean(Acc{fig},4);

        if Deci.Plot.Extra.Std.Acc.Collapse.Block
%             Accstd{fig} = nanstd(Acc{fig},[],3);
            Acc{fig} = nanmean(Acc{fig},3);
            
        end
        
        AccMean{fig} = nanmean(Acc{fig},1);
        Accstd{fig} =  nanstd(Acc{fig},[],1);
%         Acc{fig} =  nanmean(Acc{fig},1);
        
        Sub.Acc = {'SubjAvg'};

    end
end


%% plot

liner = lines(size(Acc{fig},2));

for fig = find(Deci.Plot.Extra.Std.Acc.Figure)
    
    
    if ~isempty(Deci.Plot.Extra.Std.Acc)
            
            for draw = 1:size(Acc{fig},2)
                
                a = figure;
                a.Visible = 'on';
                
                scatty = reshape(Acc{fig}(:,draw,:),[size(Acc{fig},1)*size(Acc{fig},3) 1]);
                
                scatter(sort(repmat([1:size(Acc{fig},3)],[1 size(Acc{fig},1)])),reshape(Acc{fig}(:,draw,:),[size(Acc{fig},1)*size(Acc{fig},3) 1]),'MarkerEdgeColor',liner(draw,:));
                hold on
                
                dx = 0.1; dy = 0; % displacement so the text does not overlay the data points
                text(sort(repmat([1:size(Acc{fig},3)],[1 size(Acc{fig},1)]))+dx, reshape(Acc{fig}(:,draw,:),[size(Acc{fig},1)*size(Acc{fig},3) 1])+dy, repmat(Deci.SubjectList,[1 size(Acc{fig},3)]),'Interpreter','none');
                
                
                for blk = 1:size(Acc{fig},3)
                plot([.75+blk-1 1.25+blk-1],[AccMean{fig}(:,draw,blk)+2*Accstd{fig}(:,draw,blk) AccMean{fig}(:,draw,blk)+2*Accstd{fig}(:,draw,blk)],'LineWidth',2,'Color',liner(draw,:),'HandleVisibility','off');
                plot([.75+blk-1 1.25+blk-1],[AccMean{fig}(:,draw,blk)-2*Accstd{fig}(:,draw,blk) AccMean{fig}(:,draw,blk)-2*Accstd{fig}(:,draw,blk)],'LineWidth',2,'Color',liner(draw,:),'HandleVisibility','off');
                end
                
                xticks(1:size(Acc{fig},3))
                title(['Std Scatter Total for ' Sub.Acc{1} ': ' Deci.Plot.Extra.Std.Acc.Title{fig} ' '],'Interpreter','none')
                legend([Deci.Plot.Extra.Std.Acc.Subtitle{fig}(draw)])
                xticklabels(abs(AccBlock))
                ylabel('Accuracy (Percent)')
                xlabel('Block #');
                %disp(num2str(squeeze(Acc(subj,draw,:,:))*100))

            end
        
    end
end



end