function [y,Hd,z,p] = filter_bandpass_cheby2(x, Fs, Fc1, Fc2)
n = 6;
R = 40;
[z,p,k] = cheby2(n,R,[Fc1 Fc2]/(Fs/2),'bandpass');
[sos,g] = zp2sos(z,p,k);   % Convert to SOS form
Hd = dfilt.df2tsos(sos,g);  % Create a dfilt object
% h = fvtool(Hd,'FrequencyScale','log');
y = filtfilt(sos,g,x);
end