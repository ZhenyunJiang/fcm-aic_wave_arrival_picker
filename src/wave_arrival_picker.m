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

function output = wave_arrival_picker(waveforms,par)
% create taper for trace features
n_samples = length(waveforms);
left_taper = 1:par.lta_window;
right_taper = (n_samples - par.mean_window + 1):n_samples;
features_taper = [left_taper, right_taper];

features = cell(3,1);
signal_membership = zeros(3,n_samples-length(features_taper));

% clustering of receiver components using fuzzy c-means
for i = 1:3
    features{i} = compute_trace_features(waveforms(i,:),par.dt,par.mean_window,...
        par.ppsd_window,par.sta_window,par.lta_window,features_taper);
    
    memberships = fuzzy_c_means(features{i},par.n_clusters,par.n_iterations,par.fuzzifier,...
        par.stop_criteria);
    
    signal_membership(i,:) = determine_signal_cluster(memberships);
end

% signal membership stacking
s_signal_membership = sum(signal_membership,1) .* (1 / 3);
signal_threshold = 2 * mean(s_signal_membership);
s_signal_membership = [zeros(1,length(left_taper)), s_signal_membership, zeros(1,length(right_taper))];

% candidate-arrivals windows computation
candidate_arr_windows = get_candidate_arr_windows(s_signal_membership,signal_threshold,par.tdom);

if isempty(candidate_arr_windows)
    fprintf('\t* No candidate arrival windows identified.\n');
    output = end_arrival_picker();
    return;
end

% p- and s-wave arrival windows computation
[p_window,s_window,waveforms_rot] = get_arr_windows(waveforms,candidate_arr_windows,par.rectilinearity_threshold);

% p- and s-wave arrival time picking
if isnan(p_window)
    fprintf('\t* No P-wave and S-wave windows identified.\n');
    output = end_arrival_picker();
    return;
elseif isnan(s_window)
    fprintf('\t* No S-wave window identified. S-wave arrival cannot be picked.\n');
    p_pick = get_arr_times(waveforms_rot,p_window,[],par.tdom);
    s_pick = NaN;
else
    [p_pick,s_pick] = get_arr_times(waveforms_rot,p_window,s_window,par.tdom);
end

% output windows and arrivals of p- and s-wave
output = struct('p_window',p_window,'p_pick',p_pick,'s_window',s_window,'s_pick',s_pick);
end


function [signal_membership] = determine_signal_cluster(memberships)
c1_mean_membership = mean(memberships(:,1));
c2_mean_membership = mean(memberships(:,2));

if c1_mean_membership < c2_mean_membership
    signal_membership = memberships(:,1);
else
    signal_membership = memberships(:,2);
end
end


function output = end_arrival_picker()
fprintf('\t* Arrival picking failed.\n');
output = struct('p_window',[NaN NaN],'p_pick',NaN,'s_window',[NaN NaN],'s_pick',NaN);
end