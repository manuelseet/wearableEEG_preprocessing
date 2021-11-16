clearvars
%Pipeline for preprocessing EEG Data from wearable headsets
%--Manuel Seet Jan 2021

%Note: check that your EEGLAB is working before running this


%study parameters%
study = 'myStudy_'; %study tag

subj = [1:59]; % all your subjects
sess = [1:6]; %session numbers 

%%DATA STORAGE file paths
frompath = 'E:\myStudy\eeg'; %where the raw data is from
topath = 'E:\myStudy\preprocessed'; %where the processed files will save into
topath_epoched = 'E:\myStudy\preprocessed\epoched'; %where the epoched files will save into
topath_ICAweight = 'E:\myStudy\preprocessed\ICAweighted'; %where postICA files will save into

% processing parameters
samp_rate = 500; %original sampling rate in Hz
downsamp_rate = 250; %downsample in Hz
ASR_epoch = 1;% nu. of seconds for ASR 
event_mark = '100'; %event marker of epoch
start_epoch = -2; %start in seconds, relative to event marker
end_epoch = 6; %end in seconds, relative to event marker
nChan_ICA = 19; %number of channels for ICA

%##########################################################
%#########################################################
%############# running the preprocessing################

for i = subj %subject number
    for j = sess %session (session 1-6)
        
        eeglab;
        %generate the uniq ID for the participant, based on the study tag
        %and session number
        id = strcat(study,sprintf( '%04d', i),j); 
        
        disp(strcat('================STARTING PREPROCESSING FOR:~~', id,'.====================='));
        
        %#### PREPROCESSING PIPELINE #####

        %STEP 0: Load Raw Data (.vhdr; require .eeg and .vmrk files), save as its own .set file
        EEG_raw = pop_loadbv(frompath, strcat(id,'.vhdr'));        
        pop_saveset(EEG_raw,strcat(id,'.set'),topath);
        
        EEG = pop_loadset(strcat(id,'.set'),topath); 
        
        %STEP 1: Channel Locs Lookup OR add custom Channel Loc file
        EEGa = pop_chanedit(EEG, 'lookup','C:\....\eeglab2021.0\plugins\dipfit\standard_BESA\standard-10-5-cap385.elp');
        pop_saveset(EEGa,strcat(id,'_stp1_chanloc.set'),topath); 
        
        %STEP 2: Filter with Chebyshev (requires Filter.m and filter_bandpass_cheby2.m files) 
        Filter(strcat(id,'_stp1_chanloc.set'),topath,strcat(id,'_stp2_flt.set'),topath);
 
        %STEP 3: Resample to 250Hz
        EEGb = pop_loadset(strcat(id,'_stp2_flt.set'),topath); 
        EEGc = pop_resample(EEGb, downsamp_rate);
        pop_saveset(EEGc,strcat(id,'_stp3_resampled.set'),topath); 
        
        %STEP 4: Automated Artifact Rejection (AAR)
        EEGd = pop_autobssemg(EEGc, ASR_epoch*downsamp_rate,ASR_epoch*downsamp_rate,'bsscca',{'eigratio', 1000000},...
            'emg_psd',{'ratio', 10,'fs', 250,'femg', 15,'estimator',spectrum.welch({'Hamming'}, 125)})
        pop_saveset(EEGd,strcat(id,'_stp4_AAR_EMG.set'),topath); 
        
        %STEP 5: Re-reference (Common Average)
        EEGe = pop_reref(EEGd, []); %default ref value is CA reference
        pop_saveset(EEGd,strcat(id,'_stp5_rerefCA.set'),topath);
        
        %STEP 6: Epoching (8 seconds from trial marker 100)
        EEGf = pop_epoch(EEGe, {event_mark}, [start_epoch end_epoch]);
        pop_saveset(EEGf,strcat(id,'_stp6_epoched.set'),topath); 
        pop_saveset(EEGf,strcat(id,'_stp6_epoched.set'),topath_epoched); 
        
        %STEP 7: ICA
        EEGg = pop_runica(EEGf, 'icatype', 'runica', 'chanind', [1:nChan_ICA]); %exclude A2, all irrev channels
        pop_saveset(EEGg,strcat(id,'_stp7_icaweight.set'),topath); 
        pop_saveset(EEGg,strcat(id,'_stp7_icaweight.set'),topath_ICAweight); 
        
        %Add automated component rejection here, if applicable
        
        disp(strcat('################### PREPROCESSING DONE FOR:~~', id,'.####################'));       
        
        %###END OF PREPROCESSING: proceed with manual ICA pruning, if applicable#########
 
        % clear EEG data from memory to avoid mix up
        clear EEG_raw EEG EEGa EEGb EEGc EEGd EEGe 
        
    end
end