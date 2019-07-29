function PreProcessor(Deci)

if Deci.PCom
    
    for subject_list = 1:length(Deci.SubjectList)
        PCCom(subject_list)= parfeval(@PCPreProcessor2,0,Deci,subject_list);
    end
    
    
    wait(PCCom);
    disp(['Mean Time is ' char(mean(minus([PCCom.FinishDateTime],[PCCom.StartDateTime])))]);
    disp(['Total Time is ' char(max(minus([PCCom.FinishDateTime],[PCCom.StartDateTime])))]);
    
else
    for subject_list = 1:length(Deci.SubjectList)
        PCPreProcessor2(Deci,subject_list);
    end
end

end