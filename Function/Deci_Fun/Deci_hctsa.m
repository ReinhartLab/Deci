function Deci_hctsa(Deci,info,data,params)

%% Seperate by Condition

for Cond = 1:length(Deci.Analysis.Conditions)
    maxt = length(find(cellfun(@(c) any(ismember(Deci.Analysis.Conditions{Cond},c)), Deci.DT.Markers)));
    info.alltrials = find(sum(ismember(data.events,Deci.Analysis.Conditions{Cond}),2) == maxt);

        %% ignore all locks with missing nans
    if Deci.Analysis.IgnoreNanLocks
        minamountofnans = min(mean(isnan(data.locks(info.alltrials,:)),2));
        info.nanlocks = mean(isnan(data.locks(info.alltrials,:)),2) ~= minamountofnans;
        
        if any(info.nanlocks)
            display(['ignoring ' num2str(length(find(info.nanlocks))) ' trials with missing locks'])
        end
    else
        info.nanlocks = logical(size(info.alltrials));
    end
    
    %% Reject Arts
    ccfg.trials =  info.alltrials(~info.nanlocks);
    
    dataplaceholder{Cond} = ft_selectdata(ccfg,data);
end
%% Do hctsa

%Deci.Analysis.CondTitle     = {'GG Correct'20 'GG Incorrect'10  'G0 Correct'10 'G0 Incorrect'0 ...
%                               'N0 Correct'0 'N0 Incorrect'-10 'NN Correct'-10 'NN Incorrect'20};  


%ismember(dataplaceholder{2}.label,{'FCz'})

[~,sizen2]=size(dataplaceholder{2}.trial);
[~,sizen1]=size(dataplaceholder{1}.trial);
bothconditions=[dataplaceholder{1}.trial dataplaceholder{2}.trial];
timeSeriesData=bothconditions;
bothkeys=[repmat({'condition_1'},1,sizen1) repmat({'condition_2'},1,sizen2)];
uniquelabel=cell(1,length(timeSeriesData));
for i=1:length(timeSeriesData)
    count=num2str(i);
    uniquelabel{1,i}=['Sample_' count];
end
labels=uniquelabel;
keywords=bothkeys;
save('INP_test.mat', 'timeSeriesData','labels','keywords')
TS_Init('INP_test.mat')
TS_Compute();
TS_Normalize('mixedSigmoid',[0.4,1.0]);
TS_LabelGroups('norm')

TS_PlotTimeSeries('norm')
TS_PlotDataMatrix('norm')
TS_Cluster()
TS_PlotDataMatrix('norm')
TS_PlotLowDim('norm','pca')
TS_PlotLowDim('norm','tsne')
TS_Classify('HCTSA_N.mat')
cfnParams=GiveMeDefaultClassificationParams('HCTSA_N.mat');
numNulls=100;
%TS_Classify('HCTSA_N.mat',cfnParams,numNulls,'doParallel',true)
featuresets= {'notLocationDependent','locationDependent','notLengthDependent','lengthDependent','notSpreadDependent','spreadDependent'};
TS_CompareFeatureSets('norm',cfnParams,featuresets)
TS_ClassifyLowDim('norm')

TS_TopFeatures('norm', 'classification')

end