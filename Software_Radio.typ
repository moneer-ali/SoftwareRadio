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
    block(
      stroke: 1.0pt + rgb("#EEE"),
      fill: rgb("#f3f5f6"),
      radius: 3pt,
      clip: true,
      width: 100%,
      {
        table(
          columns: (auto, 1fr),
          stroke: none,
          column-gutter: 0pt,
          inset: 0.8em,
          // sidebar background
          fill: (col, row) => if col == 0 { rgb("#eef0f2") },

          // COLUMN 1: Numbers
          align(right, text(fill: navy.lighten(20%), weight: "bold")[
            #it.lines.enumerate().map(((i, _)) => [#(i + 1)]).join([\ ])
          ]),

          // COLUMN 2: Code
          align(left)[
            #it.lines.map(l => l).join([\ ])
          ],
        )
      },
    )
  }
  body
}

``

#set text(font: "Times New Roman", size: 12pt)
#set par(first-line-indent: 1em)
// #context text.size
// --- Front page / document metadata ---
// #v(-2em)
#show: academic-document.with(
  course-name: "Introduction to Communications",
  course-code: "EECG232",
  // document-type: "Portfolio Thesis",
  title: "Software Radio
  Random Process Analysis",

  authors: (
    (
      name: "Team 11",
      code: [],
    ),
  ),
  author-columns: 1,
  advisers: ((name: "Dr. Mohamed Nafi"), (name: "Eng. Mohamed Khaled")),
  page-break-after-sections: false,
  // abstract: include "sections/0-abstract.typ",
)



= Introduction
Software Radio is a technique wherein digital signal processing is used to perform radio communication functions traditionally implemented in analog hardware. This approach allows for greater flexibility and adaptability in communication systems, enabling the implementation of various modulation schemes, error correction techniques, and signal processing algorithms through software updates rather than hardware changes.

This project focuses on generating line encodings for randomly transmitted bits and analyzing the statistical properties of the resulting waveforms. The statistical analysis serves a practical engineering purpose as an ideal transmitted signal should form a stationary and ergodic random process.

Stationarity ensures that the signal's spectral density (PSD) is stable over time, enabling the definition of a fixed power spectral density and predictable bandwidth occupancy. Ergodicity ensures that a single observed waveform is statistically representative of the entire ensemble, which is critical in practice since it can greatly reduce costs by requiring fewer testing procedures during design validation and characterization. Together these properties form the theoretical foundation for receiver filter design, bandwidth estimation, and BER analysis.

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

      [a) Unipolar Signaling], [ b) Polar NRZ Signaling ], [ c) Polar RZ Signaling ],
    )
  },
)<encodings>

= Control Flags
To easily configure and manage the entire simulation from a single centralized location, the following control parameters are defined at the very beginning of the script. They govern the data generation process: the signal amplitude (`A = 4`), the resolution of each bit (`sample_per_bit = 8`), and the physical time duration of a single sample (`sample_period = 10e-3`). Furthermore, the dimensions of the random process are defined by the length of each individual waveform (`n_bits = 100`) and the total number of simulated realizations within the ensemble (`n_waveforms = 500`).
#codeblock[```MATLAB
  % Control Flags (Defaults)
  control_flags.A = 4;
  control_flags.sample_per_bit = 8;
  control_flags.sample_period = 10e-3;
  control_flags.n_bits = 100;
  control_flags.n_waveforms = 500;
  ```
]
= Generation of data
The following MATLAB code generates a random bit stream of 100 bits:
#codeblock[```matlab
  random_bit_stream = randi([0 1], 1, 100);
```]
The #raw(lang: "matlab", "randi([0 1], x, y)") function returns an $x times y$ array of uniformly distributed numbers between 0 and 1.

== Unipolar Signaling
For unipolar signaling, the bits `[0 1]` map to `[0 A]` to get the logic levels. The Repeat Matrix function `repmat(levels, spb, 1)` duplicates the $1 times$ `n_bits` matrix (`spb`) times vertically creating a `spb` $times$ `n_bit` matrix. The `reshape()` function transforms the matrix into a $1 times$(`spb` $dot$ `n_bits` list along the columns:

A visualized example if `n_bit = 2` and `spb = 2`
$
  "bits: " [0 thick 1] -->^(times "A") [0 thick "A"] arrow.long.r^("repmat") mat(delim: "[", 0, "A"; 0, "A") -->^("reshape") [0 thick 0 thick "A" thick "A"]
$

#codeblock[```MATLAB
  function waveform = unipolar_nrz(bits, A, spb)
    levels = bits * A;
    waveform = reshape(repmat(levels(:)', spb, 1), 1, []);
  end
  ```
]
== Polar NRZ Signaling
The mapping for polar non-return-to-zero maps `[0 1]` into `[-A A]` through the following transformations:
$ "bits: "[0 thick 1] -->^(times 2) [0 thick 2] -->^(-1) [-1 thick 1] -->^(times "A") [-"A" thick "A"] $
MATLAB/Octave code for Polar NRZ:
#codeblock[ ```MATLAB
  function waveform = unipolar_nrz(bits, A, spb)
    levels = bits * A;
    waveform = reshape(repmat(levels(:)', spb, 1), 1, []);
  end
  ```
]

== Polar RZ Signaling
For polar return-to-zero, we first initialize the waveform matrix size and only set half of the `spb` to `A` and `-A` for the high and low bits respectively:

A visualized example if `n_bit = 2` and `spb = 4`
$
  [0 thick 1] -->^(times 2) [0 thick 2] -->^(-1) [-1 thick 1] -->^(times "A") [-"A" thick "A"]
  arrow.long.r^("repmat") mat(delim: "[", -"A", "A"; -"A", "A"; -"A", "A"; -"A", "A") arrow.long.r^("Zero") mat(delim: "[", -"A", "A"; -"A", "A"; 0, 0; 0, 0)-->^("reshape") [-"A" thick -"A" thick 0 thick 0 thick "A" thick "A" thick 0 thick 0]
$

#codeblock[```MATLAB
  function waveform = polar_rz(bits, A, spb)
    half_spb = floor(spb / 2);
    levels = (2*bits(:)' - 1) * A;
    raw_matrix = repmat(levels, spb, 1);

    % Zero out the second half of each bit period
    raw_matrix(half_spb+1:end, :) = 0;

    waveform = reshape(raw_matrix, 1, []);
  end
  ```
]

== Ensemble Generation
The Random Process is characterized by randomized bits and a phase shift implemented as a circular shift of a random integer between 0 and `spb-1`.

For a given random process $x(t)$, an experiment generates a *Realization* for the process. @desmos showcases an interactive polar NRZ random process which can be tried #link("https://www.desmos.com/calculator/bxxjfclpyi")[Here.] Clicking the #text(fill: rgb("#00005b"))[shuffle] button generates new realizations.
#figure(image("./images/desmos2.png"), caption: "Polar NRZ Random Process.")<desmos>
Multiple of such realizations can be simulated to construct an *Ensemble* of random variables that can be used to calculate the statistical properties of the random process.

`generate_ensemble()` acts as the core engine for generating a random process, using a flexible input system where `nargin` and `isempty` checks and prioritize user-provided arguments over the default values stored in `control_flags`.

To ensure high performance, it pre-allocates the ensemble matrix with `zeros(n_waveforms, waveform_length)`.

Inside the for loop, it generates a unique `random_bit_stream` for every realization and passes it to the `line_code_func` handle, allowing it to produce waveforms based on the desired line code.

To model a WSS random process, the code calculates a phase variable ranging from `0` to `spb-1`. It then applies this offset using `circshift(raw_wf, [0, -phase])`, which ensures that the bit transitions do not always align perfectly with the start of the sample buffer. Each shifted `raw_wf` is then stored as a row in the final matrix, creating a comprehensive ensemble ready for statistical analysis.


#codeblock[```matlab
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
```]


To make things cleaner, a function called `generate_all_ensembles()` is implemented to return a cell array containing 3 ensembles, one for each line code.

#codeblock([```matlab
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

  ```
])

== visualizing waveforms


A function called `plot_sample_waveforms()` which takes the all_ensembles and generates a plot of the first 5 waveforms of each ensemble was implemented but it's not shown here as it has nothing to do with the core logic of the simulation you can check it in the Full code.

The function is used in the following code to plot the first 5 waveforms of each ensemble

#codeblock[```MATLAB

%% Generate Ensembles
ensembles_5h = generate_all_ensembles(control_flags);

%% Plot waveforms
plot_sample_waveforms(ensembles_5h, control_flags);

```]
#figure(
  caption: [Realizations for each type of line encoding.],
  image("./images/waveforms.png"),
)<waveforms>

The waveforms in @waveforms were generated using the above code, showing a sample of the structure of the three line codes.

#pagebreak()
= Analysis
The following analysis is performed on an ensemble of $N = 500$ waveforms, each containing $L = 100$ bits at $"spb" = 8$ samples per bit, giving a total waveform length of $L_s = 800$ samples. The amplitude is $A = 4$.

== The Statistical Mean
The statistical mean is the expected value of the random process at each time instant $t$, averaged across all $N$ realizations:

$ m_x (t) = E[x(t)] = 1/N sum_(i=1)^(N) x_i(t) quad #cite(<lec4_s6>) $ <ensemble_mean>

This yields a $1 times 800$ vector — one mean value per time sample. @means shows how the mean is nearly constant across time with a smaller variance over a larger ensemble.

A function called `plot_means()` was implemented. It takes a cell array of ensembles then calculates the mean and plots it for every ensemble

#codeblock([```matlab
ens_5h = generate_all_ensembles(500);
plot_means(ens_5h)

ens_5k = generate_all_ensembles(5000);
plot_means(ens_5k)
```])


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

function plot_means(ensembles)
  names = {'Unipolar NRZ', 'Polar NRZ', 'Polar RZ'};
  colors = {'k', 'b', 'r'};
  n_waveforms = size(ensembles{1}, 1);

  figure; hold on;
  for i = 1:length(ensembles)
      current_ens = ensembles{i};
      ens_mean = mean(current_ens, 1);
      average = mean(ens_mean);
      variance = var(ens_mean);

      plot(ens_mean, 'Color', colors{i},...
       'LineWidth', 1.5, 'DisplayName', names{i});
      stats_text = sprintf('%s: \\mu = %.4f, \\sigma^2 = %.4e', names{i}, average, variance);
      text(0.02, 0.98 - (i-1)*0.06,...
       stats_text, 'Units', 'normalized', ...
          'Color', colors{i}, 'FontSize', 10,...
           'FontWeight', 'bold', 'VerticalAlignment', 'top');
  end
  ylim([-1, 4]); xlabel('Samples'); ylabel('Ensemble Mean Amplitude');
  title(sprintf('Ensemble Means and Variance (%d waveforms)', n_waveforms));
  legend('Location', 'northeast'); grid on; hold off;
end
```]

== The Ensemble Autocorrelation Function

The ensemble autocorrelation function says how much a certain reading influences the next one separated by a lag $tau$:
$
  R_x (t,tau) = E[x(t) dot x(t+tau)] = 1/N sum_(i=1)^(N) 1/(L_s - tau) sum_(t=1)^(L_s - tau) x_i (t) dot x_i (t + tau) quad #cite(<lec4_s7>)
$

In @autocorr, the autocorrelation function is calculated for varying start times over varying lags. It can be seen that $R_x (t,tau)$ doesn't depend on the initial time and only depends on the time difference ($R_x (t,tau) = R_x (tau)$). Additionally, since $m_x$ was calculated to be a constant over time, the random process is *Wide Sense Stationary (WSS)*. That can also be verified by observing how the autocorrelation is an even function.

#codeblock[```matlab
plot_ensemble_autocorr(ensembles_5h{1}, "Unipolar NRZ");
plot_ensemble_autocorr(ensembles_5h{2}, "Polar NRZ");
plot_ensemble_autocorr(ensembles_5h{3}, "Polar RZ");
```]

#figure(
  caption: [Statistical Autocorrelation of each line-encoding for different start times.],
  block(
    scale(095%, {
      set text(size: 0.75em)
      grid(
        columns: 3,
        column-gutter: -2.9em,
        image("./images/autocorr_unrz.png"), image("./images/autocorr_pnrz.png"), image("./images/autocorr_rz.png"),
        [a) Unipolar NRZ Autocorrelation #v(-0.5em) ($R_x (0)=8$, Roll-off$=4$\@8) ],
        [b) Polar NRZ Autocorrelation #v(-0.5em) ($R_x (0)=16$, Roll-off$=0$\@8) ],
        [c) Polar RZ Autocorrelation #v(-0.5em) ($R_x (0)=8$, Roll-off$=0$\@4) ],
      )
    }),
  ),
)<autocorr>



The function `ensemble_autocorr` calculates the autocorrelation function ($R_x$) for a signal ensemble by averaging across both time and all realizations (the statistical ensemble).

Sub-sampling: It isolates a portion of the ensemble starting from t_start to focus the analysis on a specific time window.

Lag Loop: It iterates through a range of time offsets from -max_lag to +max_lag.Time-Shifting: For each lag $k$, it multiplies the original ensemble by a shifted version of itself.

Double Averaging: It uses `mean(mean(product, 2))` to compute the average over all samples (time average) and all rows (ensemble average).
#codeblock[```matlab
function rx = ensemble_autocorr(ensemble, max_lag, t_start)
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
```]

Then function `plot_ensemble_autocorr` takes a specific ensemble and it's line code name and a vector of starting times and plots the ensemble auto correlation functions for each starting time and stack them vertically. If start_times vector was not given it uses a default set of [1, 101, 354].

#codeblock[```matlab
function plot_ensemble_autocorr(ensemble, name , max_lag, start_times)
    % Set default values if arguments are missing
    if nargin < 3 || isempty(max_lag), max_lag = 16; end
    if nargin < 4 || isempty(start_times), start_times = [1, 101, 354]; end

    % Create the lag vector for the x-axis
    lags = -max_lag:max_lag;
    num_starts = length(start_times);
    fig = figure('Name', name);
    % Pre-define a color palette to cycle through
    colors = {'b', 'r', 'g', 'm', 'c', 'k'};

    for i = 1:num_starts
        t_start = start_times(i);
        % Calculate autocorrelation anchored at this specific starting time
        rx = ensemble_autocorr(ensemble, max_lag, t_start);
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
```]



== The Time Mean and Autocorrelation of One Waveform
For a single realization $x_i (t)$, the time mean and autocorrelation both operate on a single $1 times 800$ row of the ensemble matrix, producing a scalar mean and a $1 times (tau_"max" + 1)$ autocorrelation vector respectively as shows in @timestat1.

$
  chevron.l x(t) chevron.r = overline(x)_i = 1/L_s sum_(t=1)^(L_s) x_i (t) \
  chevron.l x(t) dot x(t+tau) chevron.r = 1/(L_s - tau) sum_(t=1)^(L_s - tau) x_i (t) dot x_i (t + tau) quad #cite(<lec4_s23>)
$

While similar, the time-based autocorrelation differs from the ensemble $R_x$ in @autocorr.#linebreak()
#h(1em) However, increasing the number of bits makes it converge to the ensemble $R_x$. @timestat2 shows the calculation for the mean and autocorrelation of a waveform generated with 100 kilobits.

#codeblock[```matlab
plot_time_autocorrelations(ensembles_5h);
plot_time_autocorrelations(ensembles_5h_100kb);
```]

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

function plot_time_autocorrelations(ensembles)
    figure; hold on; grid on;
    % Ordered: Unipolar NRZ, Polar NRZ, Polar RZ
    names = {'Unipolar NRZ', 'Polar NRZ', 'Polar RZ'};
    colors = {'k', 'b', 'r'};

    for i = 1:3
        wv = ensembles{i}(1,:);
        plot(-32:32, time_autocorr(wv, 32), ...
            'Color', colors{i}, 'LineWidth', 1.5);
        stats_text = sprintf('%s: \\mu = %.4f', names{i}, mean(wv));
        text(0.02, 0.98 - (i-1)*0.06, stats_text, ...
            'Units', 'normalized', ...
            'Color', colors{i}, ...
            'FontSize', 10, ...
            'FontWeight', 'bold', ...
            'VerticalAlignment', 'top');
    end
    ylabel('Autocorrelation Rx'); legend(names); hold off;
end
```]
#pagebreak()
== Bandwidth of the Transmitted Signal
The power spectral density is obtained as the Fourier transform of the autocorrelation function. Applying the FFT gives the PSD in @psd, assuming that each sample corresponds to a time window of $10"ms"$.

#figure(
  caption: [The PSD of each line codes with the first null marked.],
  image("./images/PSD.png", width: 80%),
)<psd>

For the bandwidth, we choose the point of first zero of the $S_x (f)$ function giving the baseband bandwidth shown in the figure. The passband bandwidth is given by:
$
  "Passband BW" = cases(
    2 times 12.31 =24.62 "Hz for Unipolar NRZ",
    2 times 12.31 =24.62 "Hz for Polar NRZ",
    2 times 24.62 =49.24 "Hz for Polar RZ",
  )
$

Analytically, the $S_x (f)$ is given as a $sinc^2()$ function for each encoding since it is the transform of a convolved $"rect"()$. Accordingly, the first zero is given by $1/T_p$ where $T_p=80"ms"$ is the pulse width. This gives a passband bandwidth of $2/T_p=25"Hz"$ aligning with the NRZ encodings.

The discrepancy in the RZ encoding happens since it only transmits data for half the pulse. Effectively having a $T_p$ of $40"ms"$ and double the bandwidth of NRZ encodings.



#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr),
    inset: 10pt,
    align: horizon,
    fill: (x, y) => if y == 0 { gray.lighten(80%) },
    stroke: 0.5pt + gray,
    [*Encoding*], [*Effective $T_p$*], [*Analytical BW* ($1/T_p$)], [*Simulation BW*],
    [Unipolar NRZ], [80 ms], [12.5 Hz], [12.31 Hz],
    [Polar NRZ], [80 ms], [12.5 Hz], [12.31 Hz],
    [Polar RZ], [40 ms], [25 Hz], [24.62 Hz],
  ),
  caption: [Comparison of Analytical vs. Simulation Baseband Bandwidth],
)

#codeblock[```matlab
function plot_psd_from_ensembles(ensembles, control_flags, sample_period)
    if nargin < 3 || isempty(sample_period)
        sample_period = control_flags.sample_period;
    end
    max_lag = 32;
    N = 2 * max_lag + 1;
    fs = 1 / sample_period;
    freq_axis = (-(N-1)/2:(N-1)/2) * (fs / N);

    % Ordered: Unipolar NRZ, Polar NRZ, Polar RZ
    names = {'Unipolar NRZ', 'Polar NRZ', 'Polar RZ'};
    colors = {'k', 'r', 'b'};

    figure; hold on; grid on;
    p = zeros(1, 3);
    for i = 1:3
        rxs = ensemble_autocorr(ensembles{i}, max_lag);
        PSD = abs(fft(ifftshift(rxs)));
        PSD = PSD / max(PSD);
        PSD0 = fftshift(PSD);
        p(i) = plot(freq_axis, PSD0, ...
            'Color', colors{i}, 'LineWidth', 1.5);

        % Find all local minima (peaks of the negative PSD)
        % with max threshold 0.2
        [~, all_nulls] = findpeaks(-PSD0, MinPeakHeight=-0.2);

        % Identify nulls closest to the center (DC) frequency
        center_idx   = (N + 1) / 2;
        idx_before   = all_nulls(find(all_nulls < center_idx, 1, 'last'));
        idx_after    = all_nulls(find(all_nulls > center_idx, 1, 'first'));
        ind = [idx_before, idx_after];

        labels = cellstr(num2str(freq_axis(ind)', '%.2f Hz'));
        plot(freq_axis(ind), PSD0(ind), 'ro',...
            'Color', colors{i}, ...
            'MarkerSize', 10, 'LineWidth', 2);

        text(-5 + freq_axis(ind), i * 3.8e-2 + 0.08 + PSD0(ind), ...
            labels, 'Color', colors{i}, ...
            'FontSize', 10, ...
            'FontWeight', 'bold');
    end
    legend(p, names);
    xlabel('Frequency (Hz)');
    ylabel('Normalized PSD');
    title('Normalized PSD');
end

```]

// = Conclusion
// #pagebreak()

#pagebreak()

= Full MATLAB code

#codeblock[```matlab
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
control_flags.sample_period = 10e-3;
control_flags.n_bits = 100;
control_flags.n_waveforms = 500;

% === Execution ===

%% Generate Ensembles
ensembles_5h = generate_all_ensembles(control_flags);

%% Plot waveforms

plot_sample_waveforms(ensembles_5h, control_flags);

%% Plot means
plot_means(ensembles_5h);

%% Ensemble auto correlations
plot_ensemble_autocorr(ensembles_5h{1}, "Unipolar NRZ");
plot_ensemble_autocorr(ensembles_5h{2}, "Polar NRZ");
plot_ensemble_autocorr(ensembles_5h{3}, "Polar RZ");

%% Plot Time auto correlation
plot_time_autocorrelations(ensembles_5h);

%% Plot PSD
plot_psd_from_ensembles(ensembles_5h, control_flags);

% ==== Execution End ====

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
function rx = ensemble_autocorr(ensemble, max_lag, t_start)
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

function plot_sample_waveforms(ensembles, control_flags, n_show, samples_to_show)
    % Default arguments
    if nargin < 3 || isempty(n_show), n_show = 5; end
    if nargin < 4 || isempty(samples_to_show), samples_to_show = 240; end

    names = {'Unipolar NRZ', 'Polar NRZ', 'Polar RZ'};
    num_line_codes = length(ensembles);

    % Create a large figure to fit the grid
    figure('Name', 'Sample Waveforms');

    for lc_idx = 1:num_line_codes
        current_ens = ensembles{lc_idx};
        % Ensure we don't try to show more waveforms/samples than exist
        n = min(n_show, size(current_ens, 1));
        max_samples = min(samples_to_show, size(current_ens, 2));

        y_limits = [-control_flags.A-1, control_flags.A+1]; % Find y-limits

        for wf_idx = 1:n
            subplot_idx = (wf_idx - 1) * num_line_codes + lc_idx;
            subplot(n, num_line_codes, subplot_idx);
            % Plot the specific waveform slice
            plot(current_ens(wf_idx, 1:max_samples), ...
                'LineWidth', 1.5, ...
                'Color', '#0072BD');
            ylim(y_limits);
            grid on;
            % Add column titles only on the top row
            if wf_idx == 1
                title(names{lc_idx} ...
                    , 'FontWeight', 'bold', ...
                    'FontSize', 11);
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
    colors = {'k', 'r', 'b'};
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
    colors = {'k', 'r', 'b'};

    for i = 1:3
        wv = ensembles{i}(1,:);
        plot(-32:32, time_autocorr(wv, 32), ...
            'Color', colors{i}, 'LineWidth', 1.5);
        stats_text = sprintf('%s: \\mu = %.4f', names{i}, mean(wv));
        text(0.02, 0.98 - (i-1)*0.06, stats_text, ...
            'Units', 'normalized', ...
            'Color', colors{i}, ...
            'FontSize', 10, ...
            'FontWeight', 'bold', ...
            'VerticalAlignment', 'top');
    end
    ylabel('Autocorrelation Rx'); legend(names); hold off;
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
        rx = ensemble_autocorr(ensemble, max_lag, t_start);

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

function plot_psd_from_ensembles(ensembles, control_flags, sample_period)
    if nargin < 3 || isempty(sample_period)
        sample_period = control_flags.sample_period;
    end
    max_lag = 32;
    N = 2 * max_lag + 1;
    fs = 1 / sample_period;
    freq_axis = (-(N-1)/2:(N-1)/2) * (fs / N);

    % Ordered: Unipolar NRZ, Polar NRZ, Polar RZ
    names = {'Unipolar NRZ', 'Polar NRZ', 'Polar RZ'};
    colors = {'k', 'r', 'b'};

    figure; hold on; grid on;
    p = zeros(1, 3);
    for i = 1:3
        rxs = ensemble_autocorr(ensembles{i}, max_lag);
        PSD = abs(fft(ifftshift(rxs)));
        PSD = PSD / max(PSD);
        PSD0 = fftshift(PSD);
        p(i) = plot(freq_axis, PSD0, ...
            'Color', colors{i}, 'LineWidth', 1.5);

        % Find all local minima (peaks of the negative PSD)
        % with max threshold 0.2
        [~, all_nulls] = findpeaks(-PSD0, MinPeakHeight=-0.2);

        % Identify nulls closest to the center (DC) frequency
        center_idx   = (N + 1) / 2;
        idx_before   = all_nulls(find(all_nulls < center_idx, 1, 'last'));
        idx_after    = all_nulls(find(all_nulls > center_idx, 1, 'first'));
        ind = [idx_before, idx_after];

        labels = cellstr(num2str(freq_axis(ind)', '%.2f Hz'));
        plot(freq_axis(ind), PSD0(ind), 'ro',...
            'Color', colors{i}, ...
            'MarkerSize', 10, 'LineWidth', 2);

        text(-5 + freq_axis(ind), i * 3.8e-2 + 0.08 + PSD0(ind), ...
            labels, 'Color', colors{i}, ...
            'FontSize', 10, ...
            'FontWeight', 'bold');
    end
    legend(p, names);
    xlabel('Frequency (Hz)');
    ylabel('Normalized PSD');
    title('Normalized PSD');
end

```]
#pagebreak()
#bibliography("sources.bib")

