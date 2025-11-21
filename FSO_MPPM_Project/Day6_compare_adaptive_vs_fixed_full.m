% Day6_compare_adaptive_vs_fixed_full.m
% Full Monte-Carlo comparison: adaptive vs fixed M/K over visibility sweep
clear; close all; clc;
rng(0);

% === simulation parameters (adjust for runtime) ===
vis_list = [20 10 5 2 1 0.5 0.3 0.1]; % km
noiseSigma = 0.08;
distance_km = 1;
Ptx = 1;
useGG = true;

Ntrials = 10;             % number of independent trials per visibility
Nbits_per_trial = 5e4;    % bits per trial (increase for accuracy)
frameBits = 2000;

% fixed modes to compare
fixedModes = [8 1; 8 2; 16 1; 16 2];

% store final aggregated results in table
T = [];

for vi = 1:length(vis_list)
    vis = vis_list(vi);
    fprintf('=== Visibility = %.2f km ===\n', vis);

    % accumulators per mode
    adaptiveBERs = zeros(Ntrials,1);
    adaptiveThrs = zeros(Ntrials,1);
    fixedBERs = zeros(Ntrials, size(fixedModes,1));
    fixedThrs = zeros(Ntrials, size(fixedModes,1));

    for t = 1:Ntrials
        bits = randi([0 1], Nbits_per_trial, 1);

        % --- Adaptive closed-loop run (frame-by-frame) ---
        Nframes = floor(Nbits_per_trial / frameBits);
        ptr = 1;
        curM = 8; curK = 2;
        BER_frames = zeros(Nframes,1);
        thr_frames = zeros(Nframes,1);
        for f=1:Nframes
            frameBitsVec = bits(ptr:ptr+frameBits-1); ptr = ptr + frameBits;
            [txSymbols, bitsPerSym] = mppm_mod(frameBitsVec, curM, curK);
            rxSymbols = channel_fso(txSymbols, vis, distance_km, Ptx, noiseSigma, useGG);
            estSNR = estimate_snr_frame(rxSymbols);
            rxBits = mppm_demod(rxSymbols, curM, curK, bitsPerSym);
            txTrim = frameBitsVec(1:length(rxBits));
            ber = mean(txTrim ~= rxBits);
            BER_frames(f) = ber;
            thr_frames(f) = throughput_calc(bitsPerSym, ber);

            % adaptation rules (same as Day5)
            if estSNR > 1.5
                if curM < 32, curM = min(32,curM*2); curK = max(1,curK); end
            elseif estSNR < 0.3
                if curK < curM-1, curK = min(curM-1, curK+1);
                else curM = max(4, curM/2); curK = min(curK,curM-1); end
            end
            curM = round(curM); curK = round(curK);
            if curK >= curM, curK = max(1,curM-1); end
        end
        adaptiveBERs(t) = mean(BER_frames);
        adaptiveThrs(t) = mean(thr_frames);

        % --- Fixed modes (single-shot per trial) ---
        for mIdx = 1:size(fixedModes,1)
            Mfixed = fixedModes(mIdx,1); Kfixed = fixedModes(mIdx,2);
            [txSymbolsAll, bitsPerSymFixed] = mppm_mod(bits, Mfixed, Kfixed);
            rxSymbolsAll = channel_fso(txSymbolsAll, vis, distance_km, Ptx, noiseSigma, useGG);
            rxBitsAll = mppm_demod(rxSymbolsAll, Mfixed, Kfixed, bitsPerSymFixed);
            txTrimAll = bits(1:length(rxBitsAll));
            fixedBERs(t, mIdx) = mean(txTrimAll ~= rxBitsAll);
            fixedThrs(t, mIdx) = throughput_calc(bitsPerSymFixed, fixedBERs(t,mIdx));
        end
    end

    % Aggregate statistics (mean ± std)
    row.Adaptive_vis = vis;
    row.Adaptive_BER_mean = mean(adaptiveBERs);
    row.Adaptive_BER_std  = std(adaptiveBERs);
    row.Adaptive_thr_mean = mean(adaptiveThrs);
    row.Adaptive_thr_std  = std(adaptiveThrs);

    % fixed modes stats
    for mIdx = 1:size(fixedModes,1)
        row.(['M' num2str(fixedModes(mIdx,1)) '_K' num2str(fixedModes(mIdx,2)) '_BER_mean']) = mean(fixedBERs(:,mIdx));
        row.(['M' num2str(fixedModes(mIdx,1)) '_K' num2str(fixedModes(mIdx,2)) '_BER_std'])  = std(fixedBERs(:,mIdx));
        row.(['M' num2str(fixedModes(mIdx,1)) '_K' num2str(fixedModes(mIdx,2)) '_thr_mean']) = mean(fixedThrs(:,mIdx));
        row.(['M' num2str(fixedModes(mIdx,1)) '_K' num2str(fixedModes(mIdx,2)) '_thr_std'])  = std(fixedThrs(:,mIdx));
    end

    T = [T; struct2table(row)];
    % save intermediate results to file (in case run is long)
    writetable(struct2table(row), sprintf('Day6_partial_vis_%.2f.csv',vis));
end

% Final save for all vis
writetable(T,'Day6_full_results.csv');
disp('Full Monte-Carlo complete. Results saved to Day6_full_results.csv');

% === PLOTS: BER vs Visibility (adaptive vs fixed) ===
vis_vals = T.Adaptive_vis;
% adaptive stats
adaptive_mean = T.Adaptive_BER_mean;

figure; semilogy(vis_vals, adaptive_mean, '-ok','LineWidth',1.5); hold on;
for mIdx = 1:size(fixedModes,1)
    colName = ['M' num2str(fixedModes(mIdx,1)) '_K' num2str(fixedModes(mIdx,2)) '_BER_mean'];
    plot(vis_vals, T.(colName), '-o','LineWidth',1.2);
end
set(gca,'XDir','reverse'); grid on;
xlabel('Visibility (km)'); ylabel('BER'); legend(['Adaptive', arrayfun(@(i) sprintf('M%dK%d',fixedModes(i,1),fixedModes(i,2)),1:size(fixedModes,1),'UniformOutput',false)]);
title('BER vs Visibility: Adaptive vs Fixed');
saveas(gcf,'Day6_BER_vs_visibility.png');

% Throughput plot
figure; plot(vis_vals, T.Adaptive_thr_mean, '-k','LineWidth',1.5); hold on;
for mIdx = 1:size(fixedModes,1)
    colName = ['M' num2str(fixedModes(mIdx,1)) '_K' num2str(fixedModes(mIdx,2)) '_thr_mean'];
    plot(vis_vals, T.(colName), '-o','LineWidth',1.2);
end
set(gca,'XDir','reverse'); grid on;
xlabel('Visibility (km)'); ylabel('Throughput (bits/sym)'); legend(['Adaptive', arrayfun(@(i) sprintf('M%dK%d',fixedModes(i,1),fixedModes(i,2)),1:size(fixedModes,1),'UniformOutput',false)]);
title('Throughput vs Visibility: Adaptive vs Fixed');
saveas(gcf,'Day6_Throughput_vs_visibility.png');
