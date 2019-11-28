function Deci_hctsa(Deci,params)

%% Load Data

if isequal(params.Channel,'all')
    params.Channel = [{'AF3'  } {'AF4'  } {'AF7'  } ...
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


for subject_list = 1:length(Deci.SubjectList)
    for Conditions = 1:length(Deci.Plot.CondTitle)
        
        for Channel = 1:length(params.Channel)
            load([Deci.Folder.Analysis filesep 'Volt_Raw' filesep Deci.SubjectList{subject_list}  filesep Deci.Plot.Lock filesep Deci.Plot.CondTitle{Conditions} filesep params.Channel{Channel} ])
        
            Chan{Channel} = erp;
        
        end

        Condition{subject_list,Conditions} = rmfield(ft_appenddata([],Chan{:}),'cfg');
    end
end

end