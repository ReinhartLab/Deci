function dc_source(Deci,info,data,params)

%http://www.fieldtriptoolbox.org/workshop/oslo2019/forward_modeling/
%% Load Standards

if isfield(data,'freq')
    LF = dc_findfreq(params.foi);
else
    
    LF = 1;
    
end


elec = ft_read_sens('standard_1020.elc');
eleccheck = find(ismember(elec.label,data.label));
elec.chanpos = elec.chanpos(eleccheck,:);
elec.chantype = elec.chantype(eleccheck);
elec.chanunit = elec.chanunit(eleccheck);
elec.elecpos = elec.elecpos(eleccheck,:);
elec.label = elec.label(eleccheck);
elec = ft_convert_units(elec, 'cm');


mri = ft_read_mri('standard_seg.mat');
mri = ft_convert_units(mri, 'cm');
load('standard_bem.mat','vol')
vol = ft_convert_units(vol, 'cm');
%load('standard_sourcemodel3d8mm.mat','sourcemodel')
lf = [];
load('C:\Users\User\Documents\GitHub\Deci\Function\Xtra_Fun\subject1_lf.mat')

if size(params.toi,1) == 1 && [size(params.toi,1) ~= size(LF,1)]
latency = repmat(params.toi, [size(LF,1) 1])';
else
latency = params.toi;
end

for freqs = 1:size(LF,1)
    
    if ~isempty(latency)
        cfg.latency = latency(:,freqs);
    else
        cfg = [];
    end
    
    if isfield(data,'freq')
        cfg.frequency = LF(freqs,:);
        name = [params.type '_' params.foi{freqs}];
        
    else
        name = [params.type '_time'];
    end
    
    dat = ft_selectdata(cfg,data);
    
    if ~isfield(data,'freq')
        dat = ft_timelockanalysis(struct('covariance','yes'),dat);
    end
    
    %Load Elec
    % if exist([Deci.Folder.Raw  filesep Deci.SubjectList{info.subject_list} '.bvct']) == 2
    %     elec = ft_read_sens([Deci.Folder.Raw  filesep Deci.SubjectList{subject_list} '.bvct']);
    %
    %
    %     eleccheck = find(ismember(elec.label,dat.label));
    %     elec.chanpos = elec.chanpos(eleccheck,:);
    %     elec.chantype = elec.chantype(eleccheck);
    %     elec.chanunit = elec.chanunit(eleccheck);
    %     elec.elecpos = elec.elecpos(eleccheck,:);
    %     elec.label = elec.label(eleccheck);
    %     elec = ft_convert_units(elec, 'cm');
    %
    % else
    %elec = load('elec_source.mat');

    %
    % end
    
    
    %mri = ft_read_mri('Subject01.mri');
    %mri = ft_convert_units(mri, 'cm');
    
    
    % figure
    % ft_plot_sens(elec)
    % ft_plot_vol(vol,'facealpha',.05)
    % ft_plot_mesh(sourcemodel)
    
    
    % lcfg                 = [];
    % lcfg.elec            = elec;
    % lcfg.channel          =  Fourier.label;
    % lcfg.grid = sourcemodel;
    % lcfg.headmodel    = vol;
    % lcfg.senstype = 'EEG';
    % lcfg.normalize = 'yes';
    % %Fourier.label = cellfun(@lower,Fourier.label,'UniformOutput',false);
    %
    % lf = ft_prepare_leadfield(lcfg);
    % lf.inside(cellfun(@rank,lf.leadfield) ~= 3) = 0;
    %% Electro realignment
    
    % elec = ft_read_sens('standard_1020.elc');
    % eleccheck = find(ismember(elec.label,Fourier.label));
    % elec.chanpos = elec.chanpos(eleccheck,:);
    % elec.chantype = elec.chantype(eleccheck);
    % elec.chanunit = elec.chanunit(eleccheck);
    % elec.elecpos = elec.elecpos(eleccheck,:);
    % elec.label = elec.label(eleccheck);
    % elec = ft_convert_units(elec, 'cm');
    %
    % cfg=[];
    % cfg.output    = {'brain','skull','scalp'};
    % mri_seg =ft_volumesegment(cfg,mri);
    %
    % cfg=[];
    % cfg.tissues= {'scalp' 'skull' 'brain' };
    % cfg.numvertices = [6000 4000 2000];
    % bnd=ft_prepare_mesh(cfg,mri_seg);
    %
    % cfg = [];
    % cfg.method = 'interactive';
    % cfg.headshape = bnd(3); % scalp surface [rotate z 270, move x and z by 3.5]
    % cfg.elec = elec;
    % elec_realigned = ft_electroderealign(cfg);
    %
    % cfg = [];
    % cfg.method = 'project';
    % cfg.headshape = bnd(1); % scalp surface
    % cfg.elec = elec_realigned;
    % elec_realigned = ft_electroderealign(cfg);
    %
    % figure
    % hold on
    % ft_plot_sens(elec_realigned, 'elecsize', 40);
    % ft_plot_headshape(bnd, 'facealpha', 0.5);
    % view(90, 0)
    
    %% create headmodel
    
    % cfg=[];
    % cfg.output    = {'brain','skull','scalp'};
    % mri_seg =ft_volumesegment(cfg,mri);
    %
    % cfg=[];
    % cfg.tissues= {'scalp' 'skull' 'brain' };
    % cfg.numvertices = [6000 4000 2000];
    % bnd=ft_prepare_mesh(cfg,mri_seg);
    %
    % cfg = [];
    % cfg.method='openmeeg';
    % vol = ft_prepare_headmodel(cfg,bnd);
    %% create grid source\
    
    % Load Grid
    % grid = ft_read_headshape('cortex_5124.surf.gii');
    % grid = ft_convert_units(grid, 'cm');
    %
    % cfg             = [];
    % cfg.headmodel   = vol; % used to estimate extent of grid
    % cfg.resolution  = .75; % a source per 0.01 m -> 1 cm
    % cfg.elec = elec;
    % %cfg.inwardshift = 0.005; % moving sources 5 mm inwards from the skull, ...
    %                          % since BEM models may be unstable her
    % sourcemodel = ft_prepare_sourcemodel(cfg);
    
    % figure
    % hold on
    % ft_plot_mesh(sourcemodel, 'vertexsize', 20);
    % ft_plot_vol(vol, 'facealpha', 0.5)
    % view(90, 0)
    
    %% source
    
    % create cfg
    %cfg.lamda = .5;
    
    sacfg              = [];
    sacfg.method       = lower(params.type);
    sacfg.headmodel    = vol;
    sacfg.elec         = elec ;
    sacfg.channel = dat.label;
    %sacfg.(lower(cfg.type)).lambda = cfg.lamda;
    sacfg.(lower(params.type)).keepfilter   = 'yes';
    sacfg.(lower(params.type)).fixedori     = 'yes';
    sacfg.grid         = lf;
    sacfg.keepmom       = 'yes';
    
    source       = ft_sourceanalysis_checkless(sacfg, dat);
    
    mkdir([Deci.Folder.Analysis filesep 'Extra' filesep 'Source' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond}]);
    save([Deci.Folder.Analysis filesep 'Extra' filesep 'Source' filesep Deci.SubjectList{info.subject_list} filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond} filesep name ],'source','-v7.3');
    
end
end