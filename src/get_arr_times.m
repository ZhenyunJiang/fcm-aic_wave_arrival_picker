%     FCM-AIC WAVE ARRIVAL PICKER
%     ---------------------------
%     Copyright (C) February 2020  Eduardo Valero Cano,
%     King Abdullah University of Science and Technology (KAUST).
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.

function [p_pick, s_pick] = get_arr_times(waveforms,p_window,s_window,tdom)
% extend p window
p_window(1) = p_window(1) - 2 * tdom;

% compute p wave SNR
waveforms_noise = waveforms(:,1:(p_window(1) - tdom));
p_wave = waveforms(:,p_window(1):p_window(2));
p_wave_snr = rms(p_wave,2) ./ rms(waveforms_noise,2);

% identify the component with highest p wave SNR
p_wave_snr(2) = 0;
[~,p_component] = max(p_wave_snr);

% pick p wave arrival
p_pick = pick_arrival_1(waveforms(p_component,:),p_window);

if isempty(s_window)
    s_pick = NaN;
else
    % extend s wave window
    s_window(1) = max(p_pick + tdom, s_window(1) - tdom);
    
    % s wave will be picked on the components different from p_wave_component
    s_components = 1:3;
    s_components(s_components == p_component) = [];
    
    % pick s wave arrival
    s_pick = pick_arrival_2(waveforms(s_components,:),s_window);
end
end


function aic = akaike_ic(waveform)
n_samples = length(waveform);
aic = zeros(1,n_samples-1);

for i = 1:(n_samples - 1)
    a = var(waveform(1:i));
    b = var(waveform(i + 1:n_samples));
    if a > 0
        a = log(a);
    else
        a = 0;
    end
    if b > 0
        b = log(b);
    else
        b = 0;
    end
    aic(i) = i * a + (n_samples - i - 1) * b;
end
end


function [pick,aic] = pick_arrival_1(waveform,window)
aic = akaike_ic(waveform(window(1):window(2)));
aic = minmaxn(aic);
[~,pick] = min(aic);
pick = pick + window(1) - 1;
end


function [pick,aic] = pick_arrival_2(waveforms,window)
n_waveforms = size(waveforms,1);
aic = zeros(n_waveforms,(window(2) - window(1)));

for i = 1:n_waveforms
    aic(i,:) = akaike_ic(waveforms(i,window(1):window(2)));
    aic(i,:) = minmaxn(aic(i,:));
end

aic_stack = sum(aic) .* (1 / n_waveforms);
[~,pick] = min(aic_stack);
pick = pick + window(1) - 1;
end
