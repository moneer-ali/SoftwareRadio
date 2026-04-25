%% ========================================================================
% Cairo University | Faculty of Engineering
% Introduction to Communication Systems
% Project 2
% Team 11
% Submitted to Eng. Mohammed Khaled 
%
% Description: 
% This script generates, visualizes, and analyzes WSS random processes 
% using Unipolar NRZ, Polar NRZ, and Polar RZ line codes.
%
% NOTE: Please run this script section by section (using 'Run Section') 
%       to avoid triggering a fountain of plots all at once.
% =========================================================================

clear; clc; close all;

% Control Flags (Defaults)
control_flags.A = 4;
control_flags.sample_per_bit = 8;
control_flags.sample_period = 1e-3;
control_flags.n_bits = 100;
control_flags.n_waveforms = 500;

% === Execution ===

%% Generate Ensembles
ensembles_5h = generate_all_ensembles(control_flags);

%% Plot waveforms
plot_sample_waveforms(ensembles_5h);

%% Plot means
plot_means(ensembles_5h);

%% Ensemble auto correlations
plot_ensemble_autocorr(ensembles_5h{1}, "Unipolar NRZ");
plot_ensemble_autocorr(ensembles_5h{2}, "Polar NRZ");
plot_ensemble_autocorr(ensembles_5h{3}, "Polar RZ");

%% Plot Time auto correlation
plot_time_autocorrelations(ensembles_5h);

%% Plot PSD
plot_psd_from_ensembles(ensembles_5h);

% ==== Excution End ====



%% Functions

% Ensemble Generation
function ensembles = generate_all_ensembles(control_flags, n_waveforms, n_bits, A, spb)
    % Pass along optional arguments (empty brackets will trigger defaults in generate_ensemble)
    if nargin < 5, spb = []; end
    if nargin < 4, A = []; end
    if nargin < 3, n_bits = []; end
    if nargin < 2, n_waveforms = []; end

    % Generates ensembles in order: Unipolar, Polar NRZ, Polar RZ
    ens_uz = generate_ensemble(@unipolar_nrz, control_flags, n_waveforms, n_bits, A, spb);
    ens_pz = generate_ensemble(@polar_nrz, control_flags, n_waveforms, n_bits, A, spb);
    ens_rz = generate_ensemble(@polar_rz, control_flags, n_waveforms, n_bits, A, spb);
    
    ensembles = {ens_uz, ens_pz, ens_rz};
end
function ensemble = generate_ensemble(line_code_func, control_flags, n_waveforms, n_bits, A, spb)
    % Use provided arguments or fall back to control_flags struct
    if nargin < 6 || isempty(spb), spb = control_flags.sample_per_bit; end
    if nargin < 5 || isempty(A), A = control_flags.A; end
    if nargin < 4 || isempty(n_bits), n_bits = control_flags.n_bits; end
    if nargin < 3 || isempty(n_waveforms), n_waveforms = control_flags.n_waveforms; end
    
    % Direct allocation for memory efficiency
    waveform_length = n_bits * spb;
    ensemble = zeros(n_waveforms, waveform_length);
    
    for i = 1:n_waveforms
        random_bit_stream = randi([0 1], 1, n_bits);
        raw_wf = line_code_func(random_bit_stream, A, spb);
        
        % Apply random phase by circular shift and store directly in matrix
        phase = randi([0, spb-1]);
        ensemble(i, :) = circshift(raw_wf, [0, -phase]);
    end
end

% Line Coding Functions
function waveform = unipolar_nrz(bits, A, spb)
    levels = bits * A;
    waveform = reshape(repmat(levels(:)', spb, 1), 1, []);
end
function waveform = polar_nrz(bits, A, spb)
    levels = (2*bits(:)' - 1) * A;
    waveform = reshape(repmat(levels, spb, 1), 1, []);
end
function waveform = polar_rz(bits, A, spb)
    half_spb = floor(spb / 2);
    levels = (2*bits(:)' - 1) * A;
    raw_matrix = repmat(levels, spb, 1);
    
    % Zero out the second half of each bit period to make it Return-to-Zero
    raw_matrix(half_spb+1:end, :) = 0; 
    
    waveform = reshape(raw_matrix, 1, []);
end

% Analysis Functions
function rx = autocorr_from_t(ensemble, max_lag, t_start)
    if nargin < 3 || isempty(t_start), t_start = 1; end 
    sub = ensemble(:, t_start:end);
    [~, n_samples] = size(sub);
    rx = zeros(1, 2*max_lag+1);
    for k = -max_lag:max_lag
        if k >= 0
            product = sub(:, 1:n_samples-k) .* sub(:, k+1:n_samples);
        else
            product = sub(:, -k+1:n_samples) .* sub(:, 1:n_samples+k);
        end
        rx(k+max_lag+1) = mean(mean(product, 2));
    end
end
function rx_time = time_autocorr(waveform, max_lag)
    n = length(waveform);
    rx_time = zeros(1, 2*max_lag + 1);
    for k = -max_lag:max_lag
        if k >= 0
            rx_time(k+max_lag+1) = mean(waveform(1:n-k) .* waveform(k+1:n));
        else
            rx_time(k+max_lag+1) = mean(waveform(-k+1:n) .* waveform(1:n+k));
        end
    end
end


% Visualization Functions

function plot_sample_waveforms(ensembles, n_show, samples_to_show)
    % Default arguments
    if nargin < 2 || isempty(n_show), n_show = 5; end
    if nargin < 3 || isempty(samples_to_show), samples_to_show = 240; end
    
    names = {'Unipolar NRZ', 'Polar NRZ', 'Polar RZ'};
    num_line_codes = length(ensembles);
    
    % Create a large figure to fit the grid
    figure('Name', 'Sample Waveforms');
    
    for lc_idx = 1:num_line_codes
        current_ens = ensembles{lc_idx};
        
        % Ensure we don't try to show more waveforms/samples than exist
        n = min(n_show, size(current_ens, 1));
        max_samples = min(samples_to_show, size(current_ens, 2));
        
        % Find y-limits dynamically based on the ensemble's max amplitude
        max_amp = max(max(abs(current_ens(1:n, :))));
        y_limits = [-(max_amp + 1), (max_amp + 1)];
        
        for wf_idx = 1:n
            % Calculate the linear index for the subplot grid (row-major)
            subplot_idx = (wf_idx - 1) * num_line_codes + lc_idx;
            subplot(n, num_line_codes, subplot_idx);
            
            % Plot the specific waveform slice
            plot(current_ens(wf_idx, 1:max_samples), 'LineWidth', 1.5, 'Color', '#0072BD');
            ylim(y_limits);
            xlim([1, max_samples]);
            grid on;
            
            % Add column titles only on the top row
            if wf_idx == 1
                title(names{lc_idx}, 'FontWeight', 'bold', 'FontSize', 11);
            end
            
            % Add X-axis labels only on the bottom row
            if wf_idx == n
                xlabel('Sample Index');
            end
        end
    end
end
function plot_means(ensembles)
    % Ordered: Unipolar NRZ, Polar NRZ, Polar RZ
    names = {'Unipolar NRZ', 'Polar NRZ', 'Polar RZ'};
    colors = {'k', 'b', 'r'}; 
    n_waveforms = size(ensembles{1}, 1);
    
    figure; hold on;
    for i = 1:length(ensembles)
        current_ens = ensembles{i};
        ens_mean = mean(current_ens, 1);
        average = mean(ens_mean);
        variance = var(ens_mean);
        
        plot(ens_mean, 'Color', colors{i}, 'LineWidth', 1.5, 'DisplayName', names{i});
        stats_text = sprintf('%s: \\mu = %.4f, \\sigma^2 = %.4e', names{i}, average, variance);
        text(0.02, 0.98 - (i-1)*0.06, stats_text, 'Units', 'normalized', ...
            'Color', colors{i}, 'FontSize', 10, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
    end
    ylim([-1, 4]); xlabel('Samples'); ylabel('Ensemble Mean Amplitude');
    title(sprintf('Ensemble Means and Variance (%d waveforms)', n_waveforms));
    legend('Location', 'northeast'); grid on; hold off;
end
function plot_time_autocorrelations(ensembles)
    figure; hold on; grid on;
    % Ordered: Unipolar NRZ, Polar NRZ, Polar RZ
    names = {'Unipolar NRZ', 'Polar NRZ', 'Polar RZ'};
    colors = {'k', 'b', 'r'}; 
    
    for i = 1:3
        wv = ensembles{i}(1,:); 
        plot(-32:32, time_autocorr(wv, 32), 'Color', colors{i}, 'LineWidth', 1.5);
        stats_text = sprintf('%s: \\mu = %.4f', names{i}, mean(wv));
        text(0.02, 0.98 - (i-1)*0.06, stats_text, 'Units', 'normalized', ...
            'Color', colors{i}, 'FontSize', 10, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
    end
    ylabel('Autocorrelation Rx'); legend(names); hold off;
end
function plot_psd_from_ensembles(ensembles, control_flags)
    if nargin < 2 || isempty(sample_period), sample_period = control_flags.sample_period; end
    max_lag = 32; 
    N = 2 * max_lag + 1;
    k = -(N-1)/2 : (N-1)/2;
    freq_axis = k * (1 / (sample_period * N));
    
    % Ordered: Unipolar NRZ, Polar NRZ, Polar RZ
    names = {'Unipolar NRZ', 'Polar NRZ', 'Polar RZ'};
    colors = {'k', 'b', 'r'}; 
    
    figure; hold on; grid on;
    p = zeros(1, 3);
    for i = 1:3
        rx = autocorr_from_t(ensembles{i}, max_lag);
        PSD = abs(fft(rx));
        PSD = PSD / max(PSD);
        PSD0 = fftshift(PSD);
        p(i) = plot(freq_axis, PSD0, 'Color', colors{i}, 'LineWidth', 1.5);
        
        ind = find(PSD0 == min(PSD0));
        labels = cellstr(num2str(freq_axis(ind)', '%.2f Hz'));
        plot(freq_axis(ind), PSD0(ind), 'ro', 'Color', colors{i}, 'MarkerSize', 10, 'LineWidth', 2);
        text(-5 + freq_axis(ind), i * 3.8e-2 + 0.08 + PSD0(ind), labels, ...
            'Color', colors{i}, 'FontSize', 10, 'FontWeight', 'bold');
    end
    legend(p, names);
    xlabel('Frequency (Hz)');
    ylabel('Normalized PSD');
    title('Normalized PSD with bandwidth labeling');
end
function plot_ensemble_autocorr(ensemble, name , max_lag, start_times)
    % Set default values if arguments are missing
    if nargin < 3 || isempty(max_lag), max_lag = 16; end
    if nargin < 4 || isempty(start_times), start_times = [1, 101, 354]; end
    
    % Create the lag vector for the x-axis
    lags = -max_lag:max_lag;
    num_starts = length(start_times);
    
    % Initialize the figure window and automatically center it
    fig = figure('Name', name);
    
    % Pre-define a color palette to cycle through
    colors = {'b', 'r', 'g', 'm', 'c', 'k'};
    
    for i = 1:num_starts
        t_start = start_times(i);
        
        % Calculate autocorrelation anchored at this specific starting time
        rx = autocorr_from_t(ensemble, max_lag, t_start);
        
        % Create subplot stacked vertically
        subplot(num_starts, 1, i);
        
        % Pick a color, looping back to the start if num_starts > length(colors)
        c_idx = mod(i - 1, length(colors)) + 1;
        
        % Plot the data
        plot(lags, rx, 'Color', colors{c_idx}, 'LineWidth', 2);
        ylabel('R_x', 'FontWeight', 'bold');
        title(sprintf('Starting Time t_0 = %d', t_start - 1));
        grid on;
        
        % Only add the X-label to the very bottom subplot for cleaner visuals
        if i == num_starts
            xlabel('Lag', 'FontWeight', 'bold');
        end
    end
end

