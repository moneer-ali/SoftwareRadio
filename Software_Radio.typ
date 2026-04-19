#import "lib.typ": academic-document

#set page(fill: rgb("#fff"))
#show raw: it => {
  set text(size: 1.1em)
  if it.lang == none {
    raw(it.text, lang: "matlab", block: it.block)
  } else {
    it
  }
}






#let codeblock(body) = {
  show raw: it => {
    grid(
      rows: 1.2em, columns: (auto, auto), column-gutter: 1em, ..it
        .lines
        .enumerate()
        .map(((i, line)) => (text(fill: navy)[#(i + 1)], line))
        .flatten()
    )
  }
  block(
    stroke: 1.0pt + rgb("#e1e1e1"),
    fill: rgb("#eeeeee"),
    radius: 6pt,
    inset: 1em,
    clip: true,
    body,
  )
}

``

#set text(font: "New Computer Modern", size: 12pt)
// #context text.size
// --- Front page / document metadata ---
// #v(-2em)
#show: academic-document.with(
  course-name: "Introduction to Communications",
  course-code: "EECG232",
  // document-type: "Portfolio Thesis",
  title: "koftware Radio
  Random Process Analysis",

  authors: (
    (
      name: "Team 11",
      code: "",
    ),
  ),
  author-columns: 2,
  advisers: ((name: "Dr. Mohamed Nafi"),),
  page-break-after-sections: false,
  // abstract: include "sections/0-abstract.typ",
)



= Introduction

Software Radio is a technique wherein digital signal processing is used to perform radio communication functions traditionally implemented in analog hardware. This approach allows for greater flexibility and adaptability in communication systems, enabling the implementation of various modulation schemes, error correction techniques, and signal processing algorithms through software updates rather than hardware changes.

This project focuses on generating line encodings for randomly transmitted bits and analyzing the statistical properties of the resulting waveforms. The statistical analysis serves a practical engineering purpose as an ideal transmitted signal should form a stationary and ergodic random process.

Stationarity ensures that the signal's spectral density (PSD) is stable over time, enabling the definition of a fixed power spectral density and predictable bandwidth occupancy. Ergodicity ensures that a single observed waveform is statistically representative of the entire ensemble, which is critical in practice since it can greatly reduce costs by requiring fewer testing procedures during design validation and characterization. Together these properties form the theoretical foundation for receiver filter design, bandwidth estimation, and BER analysis.





= Line codes
This project explores 3 different encoding techniques. @encodings shows methods for representing the same binary data in a discrete method. The properties of each will be explored.

#figure(
  caption: [Different line encodings for the same bit sequence],
  {
    set text(size: 0.75em)
    grid(
      columns: 3,
      row-gutter: 0.3em,
      column-gutter: -1em,
      rows: 5,
      image("./images/unipolar_signaling.png"),
      image("./images/polar_nrz_signaling.png"),
      image("./images/polar_rz_signaling.png"),

      [a) Unipolar Signaling ], [ b) Polar NRZ Signaling ], [ c) Polar RZ Signaling ],
    )
  },
)<encodings>


== Generation of data
The following MATLAB code generates a random string of 100 bits:
#codeblock[````matlab
  bits = rand(100, 1) > 0.5; bits = bits(:)';
````]
The #raw(lang: "MATLAB", "rand(x,y)") function returns an $x times y$ array of uniformly distributed numbers between 0 and 1. Checking if the #raw(lang: "MATLAB", "rand") is more than $0.5$ can be used to create the boolean list of bits. Finally, the statement #raw(lang: "matlab", "bits = bits(:)';") transposes the bit array into a list of size $1 times 100$.


=== Control Flags
Two parameters are used for the generation of the line encodings: the amplitude of the signal (`A=4`), and how many samples each bit occupies (`spb=8`).
== Unipolar Signaling
For unipolar signaling, the bits `[0 1]` map to `[0 A]` to get the logic levels. The Repeat Matrix function `repmat(levels, spb, 1)` duplicates the $1 times 100$ matrix (`spb` or 8) times vertically creating a $8 times (100 dot 1)$ matrix. The `reshape()` function transforms the matrix into a $1 times 700$ list along the columns:
#codeblock[```MATLAB
  function waveform = unipolar_nrz(bits, A, spb)
    levels = bits * A;
    waveform = reshape(repmat(levels, spb, 1), 1, []);
  endfunction
  ```
]
== Polar NRZ Signaling
The mapping for polar non-return-to-zero maps `[0 1]` into `[-A A]` through the following transformations:
$ "bits: "[0 thick 1] -->^(times 2) [0 thick 2] -->^(-1) [-1 thick 1] -->^(times "A") [-"A" thick "A"] $
MATLAB/Octave code for Polar NRZ:
#codeblock[ ```MATLAB
  function waveform = polar_nrz(bits, A, spb)
     levels = (2*bits - 1) * A;
    waveform = reshape(repmat(levels, spb, 1), 1, []);
  endfunction
  ```
]

== Polar RZ Signaling
For polar return-to-zero, we first initialize the waveform matrix size and only set half of the `spb` to `A` and `-A` for the high and low bits respectively:
#codeblock[```MATLAB
  function waveform = rz(bits, A, spb)
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
  ```
]

= Ensemble Generation
The Random Process is characterized by randomized bits and a phase shift implemented as a circular shift of a random integer between 0 and `spb-1` as shown in  #text(fill: navy)[Lines 7,8] below.

For a given random process $x(t)$, an experiment generates a *Realization* for the process. @desmos showcases an interactive polar nrz random process which can be tried #link("https://www.desmos.com/calculator/bxxjfclpyi")[Here.] Clicking the #text(fill: rgb("#0303ff"))[shuffle] button generates new realizations.
#figure(image("./images/desmos2.png"), caption: "Polar NRZ Random Process.")<desmos>
Multiple such realizations can be simulated to construct an *Ensemble* of random variables that can be used to calculate the statistical properties of the random process.
#codeblock[```matlab
function [ensemble, waveforms] = generate_ensemble(code_func, A, spb,
                                          n_waveforms=500, n_bits=100)
  waveforms = cell(n_waveforms, 1);
  for i = 1:n_waveforms
    bits = rand(n_bits, 1) > 0.5; bits = bits(:)';
    waveforms{i} = code_func(bits, A, spb);
    phase = randi([0 spb-1]);
    waveforms{i} = [waveforms{i}(1+phase:end), waveforms{i}(1:phase)];
  end
  waveform_length = length(waveforms{1});
  ensemble = zeros(n_waveforms, waveform_length);
  for i = 1:n_waveforms
    ensemble(i, :) = waveforms{i};
  end
endfunction
```]

== Cell preparation for calculating stat. mean and autocorr.
The waveforms are implemented using cell arrays such that it consists of 500 realizations and can be easily accessed using the '{' and '}' indexing operators. The `ensemble` is a $500 times 800$ matrix where each row corresponds to a realization and columns represent the random process for different realizations.

#figure(
  caption: [Realizations for each type of line encoding.],
  block(
    stroke: 3.0pt + rgb("#555555"),
    radius: 6pt,
    scale(095%, {
      set text(size: 0.75em)
      grid(
        columns: 2,
        row-gutter: 0.2em,
        column-gutter: 0em,
        rows: 2,
        image("./images/Unipolar_NRZ_Waveforms.png"), image("./images/Polar_NRZ_Waveforms.png"),

        grid.cell(colspan: 2, align(center, image("./images/Polar_RZ_Waveforms.png", width: 59%))),
      )
    }),
  ),
)<waveforms>

The waveforms in @waveforms were generated using the below code, showing a sample of the structure of the three line encodings.

#codeblock[```MATLAB
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
plot_waveforms3(@unipolar_nrz, "Unipolar NRZ")
plot_waveforms3(@polar_nrz, "Polar NRZ")
plot_waveforms3(@rz, "Polar RZ")
```]



= Analysis
The following analysis is performed on an ensemble of $N = 500$ waveforms, each containing $L = 100$ bits at $"spb" = 8$ samples per bit, giving a total waveform length of $L_s = 800$ samples. The amplitude is $A = 4$.

== The Statistical Mean
The statistical mean is the expected value of the random process at each time instant $t$, averaged across all $N$ realizations:

$ mu_x (t) = E[x(t)] = 1/N sum_(i=1)^(N) x_i(t) $

This yields a $1 times 800$ vector — one mean value per time sample. @means shows how the mean is nearly constant across time with a smaller variance over a larger ensemble.

#figure(
  caption: [The statistical mean of each line-encoding for 500 and 5k waveforms.],
  block(
    scale(095%, {
      set text(size: 0.75em)
      grid(
        columns: 2,
        image("./images/means_5h.png"), image("./images/means_5k.png"),
      )
    }),
  ),
)<means>

#codeblock[```matlab
function ensembles = generate_all_ensembles(n_waveforms=500)
 [ens_rz, wfs_rz] = generate_ensemble(@rz, n_waveforms);
 [ens_pz, wfs_pz] = generate_ensemble(@polar_nrz, n_waveforms);
 [ens_uz, wfs_uz] = generate_ensemble(@unipolar_nrz, n_waveforms);
  ensembles = {ens_rz, ens_pz, ens_uz};
endfunction
function plot_means(ensembles)
  names = {'RZ', 'Polar NRZ', 'Unipolar NRZ'};
  colors = {'r', 'b', 'k'};
  n_waveforms = size(ensembles{1}, 1);
  figure;
  hold on;
  for i = 1:length(ensembles)
      ens_mean = mean(ensembles{i}, 1);   %1 x 800 array
      average = mean(ens_mean); variance = var(ens_mean);
      plot(ens_mean, 'Color', colors{i}, 'DisplayName', names{i});
  end
endfunction
ens_5h = generate_all_ensembles(500);
plot_means(ens_5h)
ens_5k = generate_all_ensembles(5000);
plot_means(ens_5k)
```]

== The Ensemble Autocorrelation Function

The ensemble autocorrelation function says how much a certain reading influences the next one separated by a lag $tau$:
$ R_x (t,tau) = E[x(t) dot x(t+tau)] = 1/N sum_(i=1)^(N) 1/(L_s - tau) sum_(t=1)^(L_s - tau) x_i (t) dot x_i (t + tau) $

In @autocorr, the autocorrelation function is calculated for varying start times over varying lags. It can be seen that $R_x (t,tau)$ doesn't depend on the initial time and only depends on the time difference ($R_x (t,tau) = R_x (tau)$). Additionally, since $mu_x$ was calculated to be a constant over time, the random process is *Wide Sense Stationary (WSS)*. That can also be verified by observing how the autocorrelation is an even function.

#figure(
  caption: [Statistical Autocorrelation of each line-encoding for different start times.],
  block(
    scale(095%, {
      set text(size: 0.75em)
      grid(
        columns: 3,
        column-gutter: -2.9em,
        image("./images/autocorr_rz.png"), image("./images/autocorr_pnrz.png"), image("./images/autocorr_unrz.png"),
        [a) Polar RZ Autocorrelation #v(-0.5em) ($R_x (0)=8$, Roll-off$=0$\@4) ],
        [b) Polar NRZ Autocorrelation #v(-0.5em) ($R_x (0)=16$, Roll-off$=0$\@8) ],
        [c) Unipolar NRZ Autocorrelation #v(-0.5em) ($R_x (0)=8$, Roll-off$=4$\@8) ],
      )
    }),
  ),
)<autocorr>

#codeblock[```matlab
function rx = autocorr_from_t(ensemble, max_lag, t_start=1)
  sub = ensemble(:, t_start:end);
  [n_waveforms, n_samples] = size(sub);
  rx = zeros(1, 2*max_lag+1);
  for k = -max_lag:max_lag
    if k>=0
      product = sub(:,1:n_samples-k) .* sub(:,k+1:n_samples); %NxLs
    else
      product = sub(:,-k+1:n_samples) .* sub(:,1:n_samples+k); %NxLs
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
  ylabel('Rx'); title(sprintf('t_0 = %d', t1-1)); grid on;
  subplot(3,1,2); plot(lags, rx2, 'r', 'LineWidth', 2);
  ylabel('Rx'); title(sprintf('t_0 = %d', t2-1)); grid on;
  subplot(3,1,3); plot(lags, rx3, 'g', 'LineWidth', 2);
  ylabel('Rx'); title(sprintf('t_0 = %d', t3-1)); grid on;;
endfunction
plot_autocorrs(ens_5h{1})
plot_autocorrs(ens_5h{2})
plot_autocorrs(ens_5h{3})
```]



== The Time Mean and Autocorrelation of One Waveform
For a single realization $x_i (t)$, the time mean and autocorrelation both operate on a single $1 times 800$ row of the ensemble matrix, producing a scalar mean and a $1 times (tau_"max" + 1)$ autocorrelation vector respectively as shows in @timestat1.

$
  chevron.l x(t) chevron.r = overline(x)_i = 1/L_s sum_(t=1)^(L_s) x_i (t) \
  chevron.l x(t) dot x(t+tau) chevron.r = 1/(L_s - tau) sum_(t=1)^(L_s - tau) x_i (t) dot x_i (t + tau)
$

While similar, the time-based autocorrelation differs from the ensemble $R_x$ in @autocorr.#linebreak()
#h(1em) However, increasing the number of bits makes it converge to the ensemble $R_x$. @timestat2 shows the calculation for the mean and autocorrelation of a waveform generated with 100 kilobits.

#grid(
  columns: (1.0fr, 1fr),
  // column-gutter: 1em,
  [
    #set text(size: 0.69em);

    #figure(caption: [Mean and autocorrelation of one [100-bit] waveform.], image(
      "./images/time_stat_1e2.png",
      width: 80%,
    )) <timestat1>
  ],
  [
    #set text(size: 0.69em);
    #figure(caption: [Mean and autocorrelation of a $10^5$-bit waveform.], image(
      "./images/time_stat_1e5.png",
      width: 80%,
    ))<timestat2>
  ],
)

This characterizes the random process as *Ergodic*, meaning that the process statistics can be characterized through a single sufficiently long observation window.

#codeblock[```matlab
function rx_time = time_autocorr(waveform, max_lag=16)
  n = length(waveform);
  rx_time = zeros(1, 2*max_lag + 1);
  for k = -max_lag:max_lag
    if k>=0
    rx_time(k+max_lag+1) = mean(waveform(1:n-k) .* waveform(k+1:n));
    else
    rx_time(k+max_lag+1) = mean(waveform(-k+1:n) .* waveform(1:n+k));
    end
  end
endfunction

hold on; grid on; n = 1e5;
funcs = {@rz, @polar_nrz, @unipolar_nrz}; colors = {'b', 'r', 'k'};
names = {'RZ', 'Polar NRZ', 'Unipolar NRZ'};
for i = 1:3
  wv = ens_5h{i}(1,:);  % Swap this with 17 to generate Figure 6
  wv = generate_ensemble(funcs{i}, 1, n); % Make a 1e5 bit waveform
    plot(-32:32, time_autocorr(wv,32), 'Color', colors{i}, ...
         'LineWidth', 1.5);
    stats_text = sprintf('%s: \\mu = %.4f', names{i}, mean(wv));
    text(0.02, 0.98 - (i-1)*0.06, stats_text, 'Units', ...
        'normalized', 'Color', colors{i}, 'FontSize', 10, ...
        'FontWeight', 'bold', 'VerticalAlignment', 'top');
end
ylabel('Autocorrelation Rx'); legend(names); hold off;
```]

== Bandwidth of the Transmitted Signal
The power spectral density is obtained as the Fourier transform of the autocorrelation function. Applying the FFT gives the PSD in @psd, assuming that each sample corresponds to a time window of $10"ms"$.

#figure(
  caption: [The PSD of each line encoding with the first null marked.],
  image("./images/PSD.png", width: 80%),
)<psd>

For the bandwidth, we choose the point of first zero of the $S_x (f)$ function giving the baseband bandwidth shown in the figure. The passband bandwidth is given by:
$
  "Passband BW" = cases(
    23.85+25.38=49.23"Hz for Polar RZ",
    11.54+13.08=24.62"Hz for Polar NRZ",
    11.54+13.08=24.62"Hz for Unipolar NRZ",
  )
$

Analytically, the $S_x (f)$ is given as a $sinc^2()$ function for each encoding since it is the transform of a convolved $"rect"()$. Accordingly, the first zero is given by $1/T_p$ where $T_p=80"ms"$ is the pulse width. This gives a passband bandwidth of $2/T_p=25"Hz"$ aligning with the NRZ encodings.

The discrepancy in the RZ encoding happens since it only transmits data for half the pulse. Effectively having a $T_p$ of $40"ms"$ and double the bandwidth of NRZ encodings.



#codeblock[```matlab
max_lag = 32; N=2*max_lag+1;
freq_axis = ( -0.5: 1/N : 0.5 - 1/N ); %N elements
freq_axis = freq_axis * 1/10e-3 ; % 1sample -> 10ms
funcs = {@rz, @polar_nrz, @unipolar_nrz}; colors = {'b', 'r', 'k'};
names = {'RZ', 'Polar NRZ', 'Unipolar NRZ'};
for i = 1:3
  rxs{i} = autocorr_from_t(ens_5h{i}, max_lag);
  rxs_shift{i} = ifftshift(rxs{i}); % Centers at lag 0 [0..16 -1..-16]
  PSDs{i} = abs(fft(rxs_shift{i}));
  PSDs{i} = PSDs{i}/max(PSDs{i});   % Normalize the FFT
  PSDs0{i} = fftshift(PSDs{i});     % Centers the 0Hz frequency

  hold on;
  p(i) = plot(freq_axis, PSDs0{i}, 'Color', colors{i},...
              'LineWidth', 1.5);
  ind = find(PSDs0{i} == min(PSDs0{i}));
  labels = cellstr(num2str(freq_axis(ind)', '%.2f Hz'));
  plot(freq_axis(ind), PSDs0{i}(ind), 'ro', 'Color', colors{i},...
       'MarkerSize', 10, 'LineWidth', 2);
  text(-5+freq_axis(ind), i*3.8e-2+0.08+PSDs0{i}(ind), labels,...
      'Color', colors{i}, 'FontSize', 10, 'FontWeight', 'bold');
end
legend(p, names); xlabel('Frequency (Hz)'); ylabel('Normalized PSD');
```]

// = Conclusion
// #pagebreak()

= Full MATLAB code

#codeblock[```matlab
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

function [ensemble, waveforms] = generate_ensemble(code_func, ...
  n_waveforms=500, n_bits=100, A, spb)
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
      ens_mean = mean(current_ens, 1);   % A 1 x 800 array
      % Calculate the mean of means and variance of means
      average = mean(ens_mean);
      variance = var(ens_mean);
      % Plot the 1 x 800 ensemble mean
      plot(ens_mean, 'Color', colors{i}, 'LineWidth', 1.5, ...
           'DisplayName', names{i});
      stats_text = sprintf('%s: \\mu = %.4f, \\sigma^2 = %.4e', ...
                          names{i}, average, variance);
      text(0.02, 0.98 - (i-1)*0.06, stats_text, 'Units', ...
          'normalized', 'Color', colors{i}, 'FontSize', 10, ...
          'FontWeight', 'bold', ...
          'VerticalAlignment', 'top');
  end
  ylim([-1, 4]);
  xlabel('Samples');
  ylabel('Ensemble Mean Amplitude');
  title(sprintf('Ensemble Means and Variance (%d waveforms)', ...
        n_waveforms));
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
  title(sprintf('t_0 = %d', t3-1)); grid on;
endfunction

function rx_time = time_autocorr(waveform, max_lag=16)
  n = length(waveform);
  rx_time = zeros(1, 2*max_lag + 1);
  for k = -max_lag:max_lag
    if k>=0
    rx_time(k+max_lag+1) = mean(waveform(1:n-k) .* waveform(k+1:n));
    else
    rx_time(k+max_lag+1) = mean(waveform(-k+1:n) .* waveform(1:n+k));
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
    text(0.02, 0.98 - (i-1)*0.06, stats_text, 'Units', ...
        'normalized', 'Color', colors{i}, 'FontSize', 10, ...
        'FontWeight', 'bold', 'VerticalAlignment', 'top');
  end
  ylabel('Autocorrelation R_x');
  xlabel('Lag (samples)');
  title('Time-Averaged Autocorrelation');
  legend(names);
  hold off;
endfunction

function plot_psd_from_ensembles(ensembles, sample_period=10e-3)
  % Calculates and plots Normalized PSD
  max_lag = 32; N = 2 * max_lag + 1;
  % Frequency axis setup
  freq_axis = (-0.5 : 1/N : 0.5 - 1/N) * (1/sample_period);
  colors = {'b', 'r', 'k'};
  names = {'RZ', 'Polar NRZ', 'Unipolar NRZ'};
  figure; clf; hold on; grid on;
  for i = 1:3
    rx = autocorr_from_t(ensembles{i}, max_lag);
    % wv = generate_ensemble(funcs{i}, 1, 1e5) ;
    % rx = time_autocorr(wv, max_lag);
    rx_shift = ifftshift(rx);
    psd_raw = abs(fft(rx_shift));
    psd_norm = psd_raw / max(psd_raw);
    psd_plot = fftshift(psd_norm);
p(i) = plot(freq_axis, PSDs0{i}, 'Color', colors{i},'LineWidth',1.5);
    ind = find(PSDs0{i} == min(PSDs0{i}));
    labels = cellstr(num2str(freq_axis(ind)', '%.2f Hz'));
    plot(freq_axis(ind), PSDs0{i}(ind), 'ro', 'Color', colors{i}, ...
          'MarkerSize', 10, 'LineWidth', 2);
    text(-5+freq_axis(ind), i*3.8e-2+0.08+PSDs0{i}(ind), labels, ...
        'Color', colors{i}, 'FontSize', 10, 'FontWeight', 'bold');
  end
  legend(p, names);
  xlabel('Frequency (Hz)'); ylabel('Normalized PSD');
  title('Normalized PSD with bandwidth');
endfunction
```]
