function PCAnalyzor(Deci)

    Deci.Analysis = Exist(Deci.Analysis,'Function',[]);
    
    if ~isempty(Deci.Analysis.Function)
        AnalysisFunc = str2func(Deci.Analysis.Function);
    else
        AnalysisFunc = @Analyzor;
    end
     
   Deci.Analysis = Exist(Deci.Analysis,'Pool',false);

   if ~Deci.Analysis.Pool
    if Deci.PCom
        global PCom
        
        if isempty(PCom)
            PCom = parfeval(@numel,0,1);
        end
        
        for subject_list = 1:length(Deci.SubjectList)
           PCom(end+1)= parfeval(gcp,AnalysisFunc,0,Deci,subject_list);
        end
        
        delete(timerfindall)
        dc_PComTimer(Deci);
    else
      TimerAn = clock;
       for subject_list = 1:length(Deci.SubjectList)
            TimerSub = clock;
            AnalysisFunc(Deci,subject_list);
            disp(['Analyzed for ' Deci.SubjectList{subject_list} ' Time: ' num2str(etime(clock,TimerSub))])
       end
       disp(['Full Analysis Time:' num2str(etime(clock,TimerAn))])
    end
   else
       AnalysisFunc(Deci);
   end
end


