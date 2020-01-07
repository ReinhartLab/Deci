function dc_source(Deci,info,Fourier,params)


%% Load Standards


%Load Elec
if exist([Deci.Folder.Raw  filesep Deci.SubjectList{subject_list} '.bvct']) == 2
    elec = ft_read_sens([Deci.Folder.Raw  filesep Deci.SubjectList{subject_list} '.bvct']);
else
    elec = ft_read_sens('standard_1020.elc');
end
eleccheck = find(ismember(elec.label,Fourier.label));
elec.chanpos = elec.chanpos(eleccheck,:);
elec.chantype = elec.chantype(eleccheck);
elec.chanunit = elec.chanunit(eleccheck);
elec.elecpos = elec.elecpos(eleccheck,:);
elec.label = elec.label(eleccheck);

%Load HeadModel
load('standard_bem.mat','vol')

% Make Sure same Units
vol= ft_convert_units(vol, 'cm');
elec = ft_convert_units(elec, 'cm');

% Load Grid
grid = ft_read_headshape('cortex_5124.surf.gii');
grid = ft_convert_units(grid, 'cm');

% create LeadField
lcfg                 = [];
lcfg.elec            = elec;
lcfg.channel          =  Fourier.label;
lcfg.grid = grid;
lcfg.headmodel    = vol;
lcfg.senstype = 'EEG';
lcfg.normalize = 'yes';
lf = ft_prepare_leadfield(lcfg,Fourier);

% create cfg
cfg.type = 'eloreta';
cfg.lamda = .5;

sacfg              = [];
sacfg.method       = lower(cfg.type);
sacfg.headmodel    = vol;
sacfg.elec         = elec ;
sacfg.channel = Fourier.label;
sacfg.(lower(cfg.type)).lambda = cfg.lamda;
sacfg.(lower(cfg.type)).keepfilter   = 'yes';
sacfg.(lower(cfg.type)).fixedori     = 'yes';
sacfg.grid         = lf;

%% Set Localize
%param.toi = [-.2 0];

cfg.latency = [.25 .5];
Fourier = ft_selectdata(cfg,Fourier);

source_cmp       = ft_sourceanalysis_checkless(sacfg, Fourier);
source_cmp.avg.mom(~source_cmp.inside) = {zeros([3 size(source_cmp.cumtapcnt,1)])};
source_cmp.avg.mom = cat(3,source_cmp.avg.mom{:});
source_cmp.avg.mom = permute(source_cmp.avg.mom,[3 2 1]);

mri = ft_read_mri('standard_seg.mat');
mri = ft_convert_units(mri, 'cm');

mcfg = [];

fieldname = params.fieldname;


%source_cmp.avg.(fieldname) =  mean(source_cmp.avg.(fieldname),2);
mcfg.interpmethod = 'nearest';


mcfg.parameter = fieldname;
source_int = ft_sourceinterpolate(mcfg, source_cmp, mri);
mcfg = [];
mcfg.method        = 'ortho';
mcfg.opacitymap    = 'vdown';
mcfg.atlas = ft_read_atlas('ROI_MNI_V4.nii');
mcfg.atlas = ft_convert_units(mcfg.atlas, 'cm');


G = source_int.pow(source_int.inside);
C = jet(50);
L = size(C,1);
Gs = round(interp1(linspace(min(G(:)),max(G(:)),L),1:L,G));
source_int.H = zeros([size(source_int.pos,1) 3]);
source_int.H(source_int.inside,:) = C(Gs,:);
%
ft_plot_mesh(source_int.pos(source_int.inside,:),'vertexcolor',source_int.H(source_int.inside,:))

mcfg.funparameter = fieldname;
mcfg.maskparameter = fieldname;

%                     source_int.pow = mean(source_int.pow,2);
ft_sourceplot(mcfg, source_int);



m=source_cmp.avg.pow(:,1); % plotting the result at the 450th time-point that is
% 500 ms after the zero time-point
figure;


v = source_cmp.avg.pow; % my matrix
map =  CoolMap;
minv = min(v(:));
maxv = max(v(:));
ncol = size(map,1);
s = round(1+(ncol-1)*(v-minv)/(maxv-minv));
rgb_image = ind2rgb(s,map);

figure;
ft_plot_mesh(source_cmp, 'vertexcolor', squeeze(rgb_image));

end