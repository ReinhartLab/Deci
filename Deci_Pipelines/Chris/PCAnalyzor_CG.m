function PCAnalyzor_CG(Deci)

if Deci.PCom
%     global PCom
    
    parfor subject_list = 1:length(Deci.SubjectList)
        Analyzor_CG(Deci,subject_list);
    end
    
else
    for subject_list = 1:length(Deci.SubjectList)
        Analyzor_CG(Deci,subject_list);
    end
end


