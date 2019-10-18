
function DefineTrialor(Deci)

disp('----------------------');
disp('Starting DefineTrialor');
tic;
for subject_list = 1:length(Deci.SubjectList)
     
    % Step 0: file check 
    if ~isempty(dir([Deci.Folder.Raw filesep Deci.SubjectList{subject_list} '.mat']))
        files_ending = {'.mat'};
    elseif   ~isempty(dir([Deci.Folder.Raw filesep Deci.SubjectList{subject_list} '.dat']))
        files_ending = {'.dat','.vmrk','.vhdr'};
    elseif   ~isempty(dir([Deci.Folder.Raw filesep Deci.SubjectList{subject_list} '.bdf']))
        files_ending = {'.bdf'};
    elseif ~isempty(dir([Deci.Folder.Raw filesep Deci.SubjectList{subject_list} '.eeg']))
        files_ending = {'.eeg','.vmrk','.vhdr'};
    elseif  ~isempty(dir([Deci.Folder.Raw filesep Deci.SubjectList{subject_list} '.cnt']))
        files_ending = {'.cnt'};
    elseif  ~isempty(dir([Deci.Folder.Raw filesep Deci.SubjectList{subject_list} '.rdf']))
        files_ending = {'.rdf','.vmrk','.vhdr'};
    elseif ~isempty(dir([Deci.Folder.Raw filesep Deci.SubjectList{subject_list} '.vhdr']))
        files_ending = {'.vhdr','.vmrk'};
    end
     
    for file_ending = 1:length(files_ending)
        if ~exist([Deci.Folder.Raw filesep Deci.SubjectList{subject_list} files_ending{file_ending}],'file')
            error([Deci.SubjectList{subject_list} ' does not have files for ' files_ending{file_ending} ' in raw data folder']);
        end
    end
    
    cfg = [];
    cfg.dataset = [Deci.Folder.Raw filesep Deci.SubjectList{subject_list} files_ending{1}];
    cfg.DT = Deci.DT;
    cfg.trialfun = cfg.DT.Type;
    cfg.file_ending = files_ending{1};
    evalc('cfg = ft_definetrial(cfg);'); % will return cfg.trl, the segmented data
    
    cfg.trialnum = cfg.trl(:,4);
    cfg.trl = cfg.trl(:,[1:3 5:end]);
    
    trllength = num2str(length(find(~isnan(mean(cfg.trl,2)))));
    disp(['Found ' num2str(trllength) ' trials out of ' num2str(size(cfg.trl,1)) ' for ' Deci.SubjectList{subject_list}]);
    save([Deci.Folder.Definition filesep Deci.SubjectList{subject_list}],'cfg')

end

disp(['Finished DefineTrial at ' num2str(toc)]);
disp('----------------------');
end