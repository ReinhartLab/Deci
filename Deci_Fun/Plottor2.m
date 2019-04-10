function Plottor2(Deci)


%% File Checks

for subject_list = 1:length(Deci.SubjectList)
    
    if Deci.Run.Freq || Deci.Run.CFC
        if ~isempty(Deci.Plot.Freq) ||  ~isempty(Deci.Plot.PRP) ||  ~isempty(Deci.Plot.CFC)
            if ~isdir([Deci.Folder.Analysis filesep 'Four_TotalPower' filesep Deci.SubjectList{subject_list}])
                error(['Freq Analysis not found for '  Deci.SubjectList{subject_list}])
            end
        end
    end
    
    if Deci.Run.ERP
        if ~isempty(Deci.Plot.ERP) || ~isempty(Deci.Plot.PRP)
            if ~isdir([Deci.Folder.Analysis filesep 'Volt_ERP' filesep Deci.SubjectList{subject_list}])
                error(['ERP Analysis not found for '  Deci.SubjectList{subject_list}])
            end
        end
    end
    
    if Deci.Run.Behavior
        if ~isempty(Deci.Plot.Behv)
            
            switch Deci.Plot.Behv.Source
                case 'Definition'
                    if exist([Deci.Folder.Version filesep 'Definition' filesep Deci.SubjectList{subject_list} '.mat'],'file') ~= 2
                        error(['Definition (Behv) Analysis not found for '  Deci.SubjectList{subject_list}])
                    end
                case 'Freq'
                    if ~isempty(Deci.Plot.Freq) ||  ~isempty(Deci.Plot.PRP) ||  ~isempty(Deci.Plot.CFC)
                        if ~isdir([Deci.Folder.Analysis filesep 'Four_TotalPower' filesep Deci.SubjectList{subject_list}])
                            error(['Freq Analysis not found for '  Deci.SubjectList{subject_list}])
                        end
                    end
            end
            
        end
    end
end

if ~isempty(Deci.Folder.Plot)
    mkdir(Deci.Folder.Plot);
end


%% Split

if Deci.Run.Freq && ~isempty(Deci.Plot.Freq)
    Plottor_Freq(Deci);
end

if Deci.Run.ERP && ~isempty(Deci.Plot.ERP)

end

% if Deci.Run.PRP && ~isempty(Deci.Plot.PRP)
% 
% end

if Deci.Run.CFC && ~isempty(Deci.Plot.CFC)

end

if Deci.Run.Behavior && ~isempty(Deci.Plot.Behv)
    Plottor_Behv(Deci);
end

%% Plot

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
