global A_default samples_per_bit_default
A_default = 4;
samples_per_bit_default = 8;

function waveform = unipolar_nrz(bits, A, spb)
  global A_default samples_per_bit_default
  if nargin < 3, spb = samples_per_bit_default; end
  if nargin < 2, A = A_default; end
  levels = bits * A;
  waveform = reshape(repmat(levels, spb, 1), 1, []);
endfunction

function waveform = polar_nrz(bits, A, spb)
  global A_default samples_per_bit_default
  if nargin < 3, spb = samples_per_bit_default; end
  if nargin < 2, A = A_default; end
  levels = (2*bits - 1) * A;
  waveform = reshape(repmat(levels, spb, 1), 1, []);
endfunction

function waveform = rz(bits, A, spb)
  global A_default samples_per_bit_default
  if nargin < 3, spb = samples_per_bit_default; end
  if nargin < 2, A = A_default; end
  n = length(bits);
  waveform = zeros(1, n * spb);
  half_spb = floor(spb / 2);
  for i = 0:n-1
    if bits(i+1) == 1
      waveform(i*spb+1 : i*spb+half_spb) = A;
    else
      waveform(i*spb+1 : i*spb+half_spb) = -A;
    end
  end
endfunction

function [ensemble, waveforms] = generate_ensemble(code_func, n_waveforms=500, n_bits=100, A, spb)
  global A_default samples_per_bit_default
  if nargin < 5, spb = samples_per_bit_default; end
  if nargin < 4, A = A_default; end
  waveforms = cell(n_waveforms, 1);
  for i = 1:n_waveforms
    bits = rand(n_bits, 1) > 0.5; bits = bits(:)';
    waveforms{i} = code_func(bits, A, spb);
    phase = randi([0 spb-1]);
    waveforms{i} = [ waveforms{i}(1+phase:end), waveforms{i}(1:phase) ];
  end
  waveform_length = length(waveforms{1});
  ensemble = zeros(n_waveforms, waveform_length);
  for i = 1:n_waveforms
    ensemble(i, :) = waveforms{i};
  end
endfunction
function ensembles = generate_all_ensembles(n_waveforms=500)
 [ens_rz, wfs_rz] = generate_ensemble(@rz, n_waveforms);
 [ens_pz, wfs_pz] = generate_ensemble(@polar_nrz, n_waveforms);
 [ens_uz, wfs_uz] = generate_ensemble(@unipolar_nrz, n_waveforms);
  ensembles = {ens_rz, ens_pz, ens_uz};
endfunction

function plot_waveforms3(code_func, name, n_show=5)
  [ensemble, waveforms] = generate_ensemble(code_func);
  n = min(n_show, length(waveforms));
  figure;
  for i = 1:n
    subplot(n, 1, i);
    plot(waveforms{i}(1:30*8), 'LineWidth', 2);
    ylabel('Amp');
    ylim([-6 6]);
    if i == 1
      title(sprintf('First %d %s Waveforms', n, name));
    end
  end
  xlabel('Sample');
endfunction

function plot_means(ensembles)
  names = {'RZ', 'Polar NRZ', 'Unipolar NRZ'};
  colors = {'r', 'b', 'k'};
  n_waveforms = size(ensembles{1}, 1);
  figure;
  hold on;
  for i = 1:length(ensembles)
      current_ens = ensembles{i};
      ens_mean = mean(current_ens, 1);   % This produces a 1 x 800 array
      % Calculate the mean of means and variance of means
      average = mean(ens_mean);
      variance = var(ens_mean);
      % Plot the 1 x 800 ensemble mean
      plot(ens_mean, 'Color', colors{i}, 'LineWidth', 1.5, 'DisplayName', names{i});
      stats_text = sprintf('%s: \\mu = %.4f, \\sigma^2 = %.4e', ...
                          names{i}, average, variance);
      text(0.02, 0.98 - (i-1)*0.06, stats_text, 'Units', 'normalized', ...
          'Color', colors{i}, 'FontSize', 10, 'FontWeight', 'bold', ...
          'VerticalAlignment', 'top');
  end
  ylim([-1, 4]);
  xlabel('Samples');
  ylabel('Ensemble Mean Amplitude');
  title(sprintf('Ensemble Means and Variance (%d waveforms)', n_waveforms));
  legend('Location', 'northeast');
  grid on;
  hold off;
endfunction

function rx = autocorr_from_t(ensemble, max_lag, t_start=1)
  sub = ensemble(:, t_start:end);
  [n_waveforms, n_samples] = size(sub);
  rx = zeros(1, 2*max_lag+1);
  for k = -max_lag:max_lag
    if k>=0
      product = sub(:,1:n_samples-k) .* sub(:,k+1:n_samples); %NxS
    else
      product = sub(:,-k+1:n_samples) .* sub(:,1:n_samples+k); %NxS
    end
    average_per_waveform = mean(product, 2); %Nx1
    rx(k+max_lag+1) = mean(average_per_waveform);  %1x1
  end
endfunction

function plot_autocorrs(ensemble, max_lag=16, t1=1, t2=101, t3=354)
  rx1 = autocorr_from_t(ensemble, max_lag, t1);
  rx2 = autocorr_from_t(ensemble, max_lag, t2);
  rx3 = autocorr_from_t(ensemble, max_lag, t3);
  lags = -max_lag:max_lag;
  figure;
  subplot(3,1,1); plot(lags, rx1, 'b', 'LineWidth', 2);
  title(sprintf('t_0 = %d', t1-1)); grid on;
  subplot(3,1,2); plot(lags, rx2, 'r', 'LineWidth', 2);
  title(sprintf('t_0 = %d', t2-1)); grid on;
  subplot(3,1,3); plot(lags, rx3, 'g', 'LineWidth', 2);
  title(sprintf('t_0 = %d', t3-1)); grid on; %xlabel('lag (samples)'); 
endfunction

function rx_time = time_autocorr(waveform, max_lag=16)
  n = length(waveform);
  rx_time = zeros(1, 2*max_lag + 1);
  for k = -max_lag:max_lag
    if k>=0
    rx_time(k+max_lag+1) = mean(waveform(1:n-k) .* waveform(k+1:n));  %1x1
    else
    rx_time(k+max_lag+1) = mean(waveform(-k+1:n) .* waveform(1:n+k));  %1x1
    end
  end
endfunction

function plot_time_autocorr(n_bits=1e5)
  funcs = {@rz, @polar_nrz, @unipolar_nrz}; 
  colors = {'b', 'r', 'k'};
  names = {'RZ', 'Polar NRZ', 'Unipolar NRZ'};
  figure; clf; hold on; grid on;
  for i = 1:3
    wv = generate_ensemble(funcs{i}, 1, n_bits); 
    % wv = ens_5h{i}(1,:);  % Swap this with 17 to generate Figure 6
    rx = time_autocorr(wv, 32);
    plot(-32:32, rx, 'Color', colors{i}, 'LineWidth', 1.5);
    stats_text = sprintf('%s: \\mu = %.4f', names{i}, mean(wv));
    text(0.02, 0.98 - (i-1)*0.06, stats_text, 'Units', 'normalized', ...
         'Color', colors{i}, 'FontSize', 10, 'FontWeight', 'bold', ...
         'VerticalAlignment', 'top');
  end
  ylabel('Autocorrelation R_x'); 
  xlabel('Lag (samples)');
  title('Time-Averaged Autocorrelation');
  legend(names); 
  hold off;
endfunction

function plot_psd_from_ensembles(ensembles, sample_period=10e-3)
  % Calculates and plots Normalized PSD from the ensemble autocorrelation
  max_lag = 32;
  N = 2 * max_lag + 1;
  % Frequency axis setup
  freq_axis = (-0.5 : 1/N : 0.5 - 1/N) * (1/sample_period);
  
  colors = {'b', 'r', 'k'};
  names = {'RZ', 'Polar NRZ', 'Unipolar NRZ'};
  figure; clf; hold on; grid on;
  for i = 1:3
    rx = autocorr_from_t(ensembles{i}, max_lag);
    % wv = generate_ensemble(funcs{i}, 1, 1e5) ; % Make a 1e5 bit waveform 18 
    % rx = time_autocorr(wv, max_lag);
    rx_shift = ifftshift(rx);
    psd_raw = abs(fft(rx_shift));
    psd_norm = psd_raw / max(psd_raw);
    psd_plot = fftshift(psd_norm);

    p(i) = plot(freq_axis, PSDs0{i}, 'Color', colors{i}, 'LineWidth', 1.5);
    ind = find(PSDs0{i} == min(PSDs0{i}));
    labels = cellstr(num2str(freq_axis(ind)', '%.2f Hz'));
    plot(freq_axis(ind), PSDs0{i}(ind), 'ro', 'Color', colors{i}, 'MarkerSize', 10, 'LineWidth', 2);
    text(-5+freq_axis(ind), i*3.8e-2+0.08+PSDs0{i}(ind), labels, 'Color', colors{i}, 'FontSize', 10, 'FontWeight', 'bold');
  end
  legend(p, names);
  xlabel('Frequency (Hz)');
  ylabel('Normalized PSD');
  title('Normalized PSD with bandwidth');
  hold off;
endfunction
