function Filter(infilename,infilepath,outfilename, outfilepath)

EEG = pop_loadset(infilename, infilepath);
L = EEG.pnts;
Data = double(EEG.data);
R = EEG.srate;
C_num = EEG.nbchan;

%Cheb2 filter
Data_f = zeros(C_num,L);
for i = 1:C_num
    [Data_f(i,:),Hd] = filter_bandpass_cheby2(Data(i,:),R,0.3,40);
end

EEG2 = EEG;
EEG2.data = Data_f;
pop_saveset(EEG2,outfilename, outfilepath);

end