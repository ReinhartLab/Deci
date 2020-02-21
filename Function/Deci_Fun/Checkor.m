
function Deci = Checkor(Deci)


warning('off', 'MATLAB:MKDIR:DirectoryExists');
Deci.Folder.Definition   = [Deci.Folder.Version filesep 'Definition'];
Deci.Folder.Preproc      = [Deci.Folder.Version filesep 'PreProc'];
Deci.Folder.Artifact     = [Deci.Folder.Version filesep 'Artifact'];


if Deci.Retroactive && Deci.Step > 3
    disp('Deci is running retroactive subjects');
    if Deci.Step == 4
        Deci.Folder.Raw = [Deci.Folder.Artifact] ;
    else
        
        Deci.Analysis = Exist(Deci.Analysis,'ERP',[]);
        Deci.Analysis = Exist(Deci.Analysis,'Freq',[]);
        Deci.Analysis.ERP = Exist(Deci.Analysis.ERP,'do',false);
        Deci.Analysis.Freq = Exist(Deci.Analysis.Freq,'do', false);
        
        if Deci.Analysis.Freq.do
            Deci.Folder.Raw = [Deci.Analysis.Version filesep 'Analysis' filesep 'Freq_TotalPower'];
        else Deci.Analysis.ERP.do
            Deci.Folder.Raw = [Deci.Analysis.Version filesep 'Analysis' filesep 'Volt_ERP'];
        end
    end
end

if strcmp(Deci.SubjectList,'all')
    Deci.SubjectList = cellfun(@(c) strsplit(c,'.'),CleanDir(Deci.Folder.Raw),'un',0);
    Deci.SubjectList = unique(cellfun(@(c) c{1},Deci.SubjectList,'un',0));
    
    
elseif strcmp(Deci.SubjectList,'gui')
    Deci.SubjectList = cellfun(@(c) strsplit(c,'.'),CleanDir(Deci.Folder.Raw),'un',0);
    Deci.SubjectList = unique(cellfun(@(c) c{1},Deci.SubjectList,'un',0));
    
    fakeUI = figure;
    fakeUI.UserData = Deci.SubjectList;
    fakeUI.Visible =  'off';
    dc_select_labels(fakeUI,[],Deci.SubjectList);
    waitfor(findall(0,'Name','Select Labels'),'BeingDeleted','on');
    Deci.SubjectList = fakeUI.UserData;
    close(fakeUI);
end
disp(['Running Deci for ' num2str(length(Deci.SubjectList)) ' subjects'])
display(' ');

Pronouns = {'He','She','They'};

Deci = Exist(Deci,'Person',[]);

Deci.Person = Exist(Deci.Person,'Type','Concise'); % Concise
Deci.Person.Pro = [Pronouns(randi(3))];
end