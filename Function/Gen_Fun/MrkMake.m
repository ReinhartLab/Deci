function MrkMake(folder,refmrk,newmrk,displace)

% folder - path to folder of data to process
% refmrk - reference marker, cells of cells of strings 
                %children cell collapses as a collective reference
% newmrk - new added marker, cells of strings
                %index correlates to rermrk
% displace - displacement in seconds

% The function allows for consequential refmrk to be newly created newmrk
% from previous refmrks

% ex: MrkMake(['Raw_Data' filesep 'New_data'],{{'10','11'},{'300'}},{'300','400'},[-2,-1/250])
% 10/11 creates 300 mrk at -2 sec [signifies beginning of exp]
% newly created 300 mrk then creates a 400 mrk at -1/250 second (1/2s)
        %[end is 1 sample before the next beginning]

        if ~isempty(dir([folder filesep '*.dat']))
            exp_files = dir([folder filesep '*.dat']);
        elseif  ~isempty(dir([folder filesep '*.bdf']))
            exp_files = dir([folder filesep '*.bdf']);
        elseif ~isempty(dir([folder filesep '*.eeg']))
            exp_files = dir([folder filesep '*.eeg']);
        elseif ~isempty(dir([folder filesep '*.cnt']))
            exp_files = dir([folder filesep '*.cnt']);
        end
        
mkdir([folder '_new'])


for k = 1:length(exp_files)
    
    disp(['Subject :' exp_files(k).name ' starting...'])
    
    hdr   = ft_read_header([folder filesep exp_files(k).name]);
    event = ft_read_event([folder filesep exp_files(k).name]); %Mk<Marker number>=<Type>,<Description>,<Position in data points>,
    dat   = ft_read_data([folder filesep exp_files(k).name]);
    
    event = StandardizeEventMarkers(event);
    
    event2 = event;
    for j = 1:length(refmrk)
         new_event  = event2(1);
        for i=1:length(event2)
            
            
            if mean(strcmp(event2(i).value,refmrk{j})) ~= 0
                
                new = event2(i);
                new.value = newmrk{j};
                
                
                if [new.sample + [hdr.Fs * displace(j)]] >= event2(1).sample || [new.sample + [hdr.Fs * displace(j)]] <= event2(end).sample
                new.sample = new.sample + [hdr.Fs * displace(j)];
                
%                 elseif [new.sample + [hdr.Fs * displace(j)]] <= event2(1)
%                 new.sample = event2(1) + 1;
%                 
%                 elseif [new.sample + [hdr.Fs * displace(j)]] >= event2(end)
%                 
%                 new.sample = event2(end) - 1;
%                     
                end
                
                new_event(end+1)  = new;
                
            end
             new_event(end+1) = event2(i);
        end
        
        new_event = new_event(1:end);
        [tmp,ind]=sortrows({new_event.sample}');
        event2=new_event(ind);
    end
 
    string = strsplit(exp_files(k).name,'.');
    
%     string{1} = strsplit(string{1},'_');
%     
%     if length(string{1}) == 2
%         
%         string{1} = ['FCz_CDATemp4vis_' string{1}{2}]
%         
%     else
%         string{1} = ['FCz_CDATemp4vis_' string{1}{2} '0' string{1}{3}];
%     end
   
    
    hdr.orig.MarkerFile = [folder '_new' filesep  string{1}  '.vmrk'];
    hdr.orig.DataFile = [folder '_new' filesep  string{1}  '.eeg'];
    
    ft_write_data([folder '_new' filesep  string{1}],dat,'header',hdr,'dataformat','brainvision_eeg','event',event2)
    
    disp(['Subject :' exp_files(k).name ' done...'])
    
end


end