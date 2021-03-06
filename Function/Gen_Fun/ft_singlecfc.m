function crossfreq = ft_singlecfc(cfg,Deci,info,fourier,params)

% FT_CROSSFREQUENCYANALYSIS performs cross-frequency analysis
%
% Use as
%   crossfreq = ft_crossfrequencyanalysis(cfg, freq)
%   crossfreq = ft_crossfrequencyanalysis(cfg, freqlo, freqhi)
%
% The input data should be organised in a structure as obtained from the
% FT_FREQANALYSIS function. The configuration should be according to
%
%   cfg.freqlow    = scalar or vector, selection of frequencies for the low frequency data
%   cfg.freqhigh   = scalar or vector, selection of frequencies for the high frequency data
%   cfg.chanlow    = cell-array with selection of channels, see FT_CHANNELSELECTION
%   cfg.chanhigh    = cell-array with selection of channels, see FT_CHANNELSELECTION
%   cfg.method     = string, can be
%                     'coh' - coherence
%                     'plv' - phase locking value
%                     'mvl' - mean vector length
%                     'mi'  - modulation index
%   cfg.keeptrials = string, can be 'yes' or 'no'
%   cfg.timebins = scalar, number of bins to cut data into
%
% Various metrics for cross-frequency coupling have been introduced in a number of
% scientific publications, but these do not use a sonsistent method naming scheme,
% nor implement it in exactly the same way. The particular implementation in this
% code tries to follow the most common format, generalizing where possible. If you
% want details about the algorithms, please look into the code.
%
% The modulation index implements
%   Tort A. B. L., Komorowski R., Eichenbaum H., Kopell N. (2010). Measuring Phase-Amplitude
%   Coupling Between Neuronal Oscillations of Different Frequencies. J Neurophysiol 104:
%   1195?1210. doi:10.1152/jn.00106.2010
%
% See also FT_FREQANALYSIS, FT_CONNECTIVITYANALYSIS

% Copyright (C) 2014-2017, Donders Centre for Cognitive Neuroimaging
%
% This file is part of FieldTrip, see http://www.fieldtriptoolbox.org
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id$

% these are used by the ft_preamble/ft_postamble function and scripts
ft_revision = '$Id$';
ft_nargin   = nargin;
ft_nargout  = nargout;

% do the general setup of the function
ft_defaults
ft_preamble init
ft_preamble debug
ft_preamble loadvar freqlow freqhigh
ft_preamble provenance freqlow freqhi
ft_preamble trackconfig

% the ft_abort variable is set to true or false in ft_preamble_init
if ft_abort
    % do not continue function execution in case the outputfile is present and the user indicated to keep it
    return
end

freqhigh = fourier;
freqlow = fourier;

freqlow  = ft_checkdata(freqlow,  'datatype', 'freq', 'feedback', 'yes');
freqhigh = ft_checkdata(freqhigh, 'datatype', 'freq', 'feedback', 'yes');


chancfg.channel = cfg.chanlow;
freqlow = ft_selectdata(chancfg,freqlow);
chancfg.channel = cfg.chanhigh;
freqhigh = ft_selectdata(chancfg,freqhigh);

% prior to 19 Jan 2017 this function had input options cfg.chanlow and cfg.chanhigh,
% but nevertheless did not support between-channel CFC computations
% cfg = ft_checkconfig(cfg, 'forbidden', {'chanlow', 'chanhigh'});
%
% % this function only support CFC computations within channels, not between channels
%
%
% cfg.chanlow   = ft_getopt(cfg, 'chanlow',  'all');
% cfg.chanhigh    = ft_getopt(cfg, 'chanhigh',  'all');

cfg.freqlow    = ft_getopt(cfg, 'freqlow',  'all');
cfg.freqhigh   = ft_getopt(cfg, 'freqhigh', 'all');
cfg.keeptrials = ft_getopt(cfg, 'keeptrials','no');


for fl = 1:length(cfg.freqlow)
    switch cfg.freqlow{fl}
        case 'theta'
            LF(:,fl) = [4 8];
        case 'beta'
            LF(:,fl) = [12.5 30];
        case 'alpha'
            LF(:,fl) =[8 12.5];
        case 'lowgamma'
            LF(:,fl) =[30 55];
        case 'highgamma'
            LF(:,fl) = [55 80];
    end
end

for fh = 1:length(cfg.freqhigh)
    switch cfg.freqhigh{fh}
        case 'theta'
            HF(:,fh) = [4 8];
        case 'beta'
            HF(:,fh) = [12.5 30];
        case 'alpha'
            HF(:,fh) =[8 12.5];
        case 'lowgamma'
            HF(:,fh) =[30 55];
        case 'highgamma'
            HF(:,fh) = [55 80];
    end
end

ntrial = size(freqlow.fourierspctrm,1); % FIXME the dimord might be different
nchanlow  = size(freqlow.fourierspctrm,2); % FIXME the dimord might be different
nchanhigh  = size(freqhigh.fourierspctrm,2); % FIXME the dimord might be different

timebin = cfg.timebin;

latencylow = reshape([freqlow.time [nan(-rem(length(freqlow.time),cfg.timebin)+cfg.timebin,1)]],[ceil([length(freqlow.time)]/cfg.timebin) cfg.timebin]);
latencyhigh = reshape([freqhigh.time [nan(-rem(length(freqlow.time),cfg.timebin)+cfg.timebin,1)]],[ceil([length(freqlow.time)]/cfg.timebin) cfg.timebin]);

timelow = [min(latencylow,[],1); max(latencylow,[],1)];
timehigh = [min(latencyhigh,[],1); max(latencyhigh,[],1)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% prepare the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%TODO: make all instances of cfcdata the same dimensionality

for method = 1:length(Deci.Analysis.CFC.methods)
    
    switch Deci.Analysis.CFC.methods{method}
        
        case 'coh'
            % coherence
            cohdatas = zeros(ntrial,nchan,size(LF,2),size(HF,2)) ;
            for  i =1:nchan
                chandataLF = freqlow.fourierspctrm(:,i,:,:);
                chandataHF = freqhigh.fourierspctrm(:,i,:,:);
                for j = 1:ntrial
                    cohdatas(j,i,:,:) = data2coh(squeeze(chandataLF(j,:,:,:)),squeeze(chandataHF(j,:,:,:)));
                end
            end
            cfcdata = cohdatas;
            
        case 'plv'
            % phase locking value
            plvdatas = zeros(ntrial,nchanlow,nchanhigh,size(LF,2),size(HF,2),timebin) ;
            
            for t = 1:timebin
                for  i =1:nchanlow
                    for k = 1:nchanhigh
                        for fl = 1:size(LF,2)
                            for fh = 1:size(HF,2)
                                ltime = freqlow.time >= timelow(1,t) & freqlow.time <= timelow(2,t);
                                htime = freqhigh.time >= timehigh(1,t) & freqhigh.time <= timehigh(2,t);
                                
                                lfreq = freqlow.freq >= LF(1,fl) & freqlow.freq <= LF(2,fl);
                                hfreq = freqhigh.freq >= HF(1,fh) & freqhigh.freq <= HF(2,fh);
                                
                                chandataLF = freqlow.fourierspctrm(:,i,lfreq,ltime);
                                chandataHF = freqhigh.fourierspctrm(:,k,hfreq,htime);
                                for j = 1:ntrial
                                    plvdatas(j,i,k,fl,fh,t) = data2plv(permute(chandataLF(j,:,:,:),[4 2 3 1]),permute(chandataHF(j,:,:,:),[4 2 3 1]));
                                end
                            end
                        end
                    end
                end
            end
            cfcdata = plvdatas;
            
        case  'mvl'
            % mean vector length
            mvldatas = zeros(ntrial,nchan,size(LF,2),size(HF,2));
            for  i =1:nchan
                chandataLF = freqlow.fourierspctrm(:,i,:,:);
                chandataHF = freqhigh.fourierspctrm(:,i,:,:);
                for j = 1:ntrial
                    mvldatas(j,i,:,:) = data2mvl(squeeze(chandataLF(j,:,:,:)),squeeze(chandataHF(j,:,:,:)));
                end
            end
            cfcdata = mvldatas;
            
        case  'mi'
            % modulation index
            nbin       = 21; % number of phase bin + 1
            pacdatas = zeros(ntrial,nchanlow,nchanhigh,size(LF,2),size(HF,2),timebin) ;
            
            for t = 1:timebin
                for  i =1:nchanlow
                    for k = 1:nchanhigh
                        
                        for fl = 1:size(LF,2)
                            for fh = 1:size(HF,2)
                                ltime = freqlow.time >= timelow(1,t) & freqlow.time <= timelow(2,t);
                                htime = freqhigh.time >= timehigh(1,t) & freqhigh.time <= timehigh(2,t);
                                
                                lfreq = freqlow.freq >= LF(1,fl) & freqlow.freq <= LF(2,fl);
                                hfreq = freqhigh.freq >= HF(1,fh) & freqhigh.freq <= HF(2,fh);
                                
                                chandataLF = freqlow.fourierspctrm(:,i,lfreq,ltime);
                                chandataHF = freqhigh.fourierspctrm(:,k,hfreq,htime);
                                
                                for j = 1:ntrial
                                    pacdatas(j,i,k,fl,fh,t) = data2pac(squeeze(chandataLF(j,:,:,:)),squeeze(chandataHF(j,:,:,:)),nbin);
                                end
                                
                            end
                        end
                    end
                end
            end
            
            cfcdata = pacdatas;
        case 'cs_cl'
            pacdatas   = zeros(2,nchan,ntime) ;
            for  i =1:nchan
                chandataLF = circ_ang2rad(circ_mean(angle(freqlow.fourierspctrm(:,i,:,:)),[],3));
                chandataHF =  mean(abs(freqhigh.fourierspctrm(:,i,:,:)),3);
                for j = 1:ntime
                    [pacdatas(1,i,j) pacdatas(2,i,j)] = circ_corrcl(squeeze(chandataLF(:,:,:,j)),squeeze(chandataHF(:,:,:,j)));
                end
            end
            cfcdata = pacdatas;
        case 'cs_cc'
            pacdatas   = zeros(2,nchan,ntime) ;
            for  i =1:nchan
                chandataLF = circ_ang2rad(circ_mean(angle(freqlow.fourierspctrm(:,i,:,:)),[],3));
                chandataHF = circ_ang2rad(circ_mean(angle(freqhigh.fourierspctrm(:,i,:,:)),[],3));
                for j = 1:ntime
                    [pacdatas(1,i,j) pacdatas(2,i,j)] = circ_corrcc(squeeze(chandataLF(j,:,:,:)),squeeze(chandataHF(j,:,:,:)));
                end
            end
            cfcdata = pacdatas;
    end % switch method for data preparation
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % do the actual computation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    switch Deci.Analysis.CFC.methods{method}
        
        case 'coh'
            [ntrial,nchan,nlf,nhf] = size(cfcdata);
            if strcmp(cfg.keeptrials, 'no')
                crsspctrm = reshape(abs(mean(cfcdata,1)), [nchan, nlf, nhf]);
                dimord = 'chan_freqlow_freqhigh' ;
            else
                crsspctrm = abs(cfcdata);
                dimord = 'rpt_chan_freqlow_freqhigh' ;
            end
            
        case 'plv'
            [ntrial,nchanlow,nchanhigh,nlf,nhf,ntime] = size(cfcdata);
            
            crsspctrm = abs(cfcdata);
            dimord = 'rpt_chan_chan_freqlow_freqhigh_time' ;
            
            if strcmp(cfg.keeptrials, 'no')
                dimord = 'chan_chan_freqlow_freqhigh_time' ;
                crsspctrm =  permute(mean(crsspctrm,1),[2:length(size(crsspctrm)) 1]);
            end
            
        case  'mvl'
            [ntrial,nchan,nlf,nhf] = size(cfcdata);
            if strcmp(cfg.keeptrials, 'no')
                crsspctrm = reshape(abs(mean(cfcdata,1)), [nchan, nlf, nhf]);
                dimord = 'chan_freqlow_freqhigh' ;
            else
                crsspctrm = abs(cfcdata);
                dimord = 'rpt_chan_freqlow_freqhigh' ;
            end
            
        case  'mi'
            [ntrial,nchanlow,nchanhigh,nlf,nhf,nbin,ntime] = size(cfcdata);
            
            dimord = 'rpt_chan_chan_freqlow_freqhigh_time' ;
            crsspctrm = cfcdata;
            
            
            if strcmp(cfg.keeptrials, 'no')
                dimord = 'chan_chan_freqlow_freqhigh_time' ;
                crsspctrm =  permute(mean(crsspctrm,1),[2:length(size(crsspctrm)) 1]);
                cfcdata = permute(mean(cfcdata,1),[2:length(size(cfcdata)) 1]);
            end
            
    end % switch method for actual computation
    
    
    crossfreq.labellow      = freqlow.label;
    crossfreq.labelhigh      = freqhigh.label;
    crossfreq.crsspctrm  = crsspctrm;
    crossfreq.dimord     = dimord;
    crossfreq.freqlow    = cfg.freqlow;
    crossfreq.freqhigh   = cfg.freqhigh;
    crossfreq.timelow = mean(timelow,1);
    crossfreq.timehigh = mean(timehigh,1);
    
    ft_postamble debug
    ft_postamble trackconfig
    ft_postamble previous   freqlow freqhigh
    % ft_postamble provenance crossfreq
    ft_postamble history    crossfreq
    ft_postamble savevar    crossfreq
    
    
    mkdir([Deci.Folder.Analysis filesep 'CFC' filesep Deci.Analysis.CFC.methods{method} filesep Deci.SubjectList{info.subject_list}  filesep Deci.Analysis.LocksTitle{info.Lock}])
    save([Deci.Folder.Analysis filesep 'CFC' filesep Deci.Analysis.CFC.methods{method} filesep Deci.SubjectList{info.subject_list}  filesep Deci.Analysis.LocksTitle{info.Lock} filesep Deci.Analysis.CondTitle{info.Cond}],'crossfreq','-v7.3');
    
end % function

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [cohdata] = data2coh(LFsigtemp,HFsigtemp)

HFamp    = abs(HFsigtemp);
HFamp(isnan(HFamp(:))) = 0;                              % replace nan with 0
HFphas   = angle(hilbert(HFamp'))';
HFsig    = HFamp .* exp(sqrt(-1)*HFphas);

LFsig = LFsigtemp;
LFsig(isnan(LFsig(:))) = 0;                              % replace nan with 0

cohdata = zeros(size(LFsig,1),size(HFsig,1));
for i = 1:size(LFsig,1)
    for j = 1:size(HFsig,1)
        Nx  = sum(~isnan(LFsigtemp(i,:) .* LFsigtemp(i,:)));
        Ny  = sum(~isnan(HFsigtemp(j,:) .* HFsigtemp(j,:)));
        Nxy = sum(~isnan(LFsigtemp(i,:) .* HFsigtemp(j,:)));
        
        Px  = LFsig(i,:) * ctranspose(LFsig(i,:)) ./ Nx;
        Py  = HFsig(j,:) * ctranspose(HFsig(j,:)) ./ Ny;
        Cxy = LFsig(i,:) * ctranspose(HFsig(j,:)) ./ Nxy;
        
        cohdata(i,j) = Cxy / sqrt(Px * Py);
    end
end

end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [plvdata] = data2plv(LFsigtemp,HFsigtemp)

LFphas   = angle(LFsigtemp);
HFamp    = abs(HFsigtemp);
HFamp(isnan(HFamp(:))) = 0;                              % replace nan with 0
HFphas   = angle(hilbert(HFamp));
plvdata  = zeros(size(LFsigtemp,3),size(HFsigtemp,3));   % phase locking value

for i = 1:size(LFsigtemp,3)
    for j = 1:size(HFsigtemp,3)
        plvdata(i,j) = nanmean(exp(1i*(LFphas(:,:,i)-HFphas(:,:,j))));
    end
end

plvdata = mean(mean(plvdata,2),1);

end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mvldata] = data2mvl(LFsigtemp,HFsigtemp)
% calculate  mean vector length (complex value) per trial
% mvldata dim: LF*HF

LFphas   = angle(LFsigtemp);
HFamp    = abs(HFsigtemp);
mvldata  = zeros(size(LFsigtemp,1),size(HFsigtemp,1));    % mean vector length

for i = 1:size(LFsigtemp,1)
    for j = 1:size(HFsigtemp,1)
        mvldata(i,j) = nanmean(HFamp(j,:).*exp(1i*LFphas(i,:)));
    end
end

end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pacdata = data2pac(LFsigtemp,HFsigtemp,nbin)
% calculate phase amplitude distribution across trial
% pacdata dim: LF*HF*Phasebin

% WARNING, this isn't exactly the same as regular PAC! this is across
% trials and within a time range
Ang  = angle(LFsigtemp);
Amp  = abs(HFsigtemp);


[~,bin] = histc(Ang, linspace(-pi,pi,nbin));  % binned low frequency phase
Q =ones(nbin-1,1)/[nbin-1];

for i = 1:size(Ang,1)
    for j = 1:size(Amp,1)
        for k = 1:nbin-1
            idx = (bin(i,:)==k);
            
            tempA = Amp(j,:);
            pac(k,:) = mean(tempA(idx),2);
        end
        
        P = squeeze(pac)/ nansum(pac);
        pcdata(i,j) = nansum(P.* log2(P./Q))./log2(nbin-1);
        
        
    end
end

pacdata = mean(mean(pcdata,1),2);

end % function