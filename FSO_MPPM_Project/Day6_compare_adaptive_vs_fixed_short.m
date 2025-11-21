% Short quick comparison - Day6 (fast)
clear; close all; clc;
rng(1);

% quick parameters (fast)
vis_list = [5 2 0.8 0.3];    % km (small set)
noiseSigma = 0.08;
distance_km = 1;
Ptx = 1;
useGG = true;

% trial settings (kept small)
Ntrials = 5;           % Monte Carlo trials (repeatability)
Nbits_per_trial = 1e4; % small for quick run
frameBits = 2000;      % frame length for adaptation logic

% fixed modes to compare (M,K)
fixedModes = [8 1; 8 2; 16 1]; % rows = [M K]

% result storage
results = [];

for vi = 1:length(vis_list)
    vis = vis_list(vi);
    fprintf('--- Visibility = %.2f km ---\n', vis);
    for t = 1:Ntrials
        bits = randi([0 1], Nbits_per_trial, 1);

        % 1) Adaptive closed-loop (use Day5 closed-loop logic per trial)
        % Use small internal loop to simulate adaptation per frame
        Nframes = floor(Nbits_per_trial / frameBits);
        ptr = 1;
        BER_adaptive_frames = zeros(Nframes,1);
        thr_adaptive_frames = zeros(Nframes,1);
        curM = 8; curK = 2;
        for f=1:Nframes
            frameBitsVec = bits(ptr:ptr+frameBits-1); ptr = ptr + frameBits;
            [txSymbols, bitsPerSym] = mppm_mod(frameBitsVec, curM, curK);
            rxSymbols = channel_fso(txSymbols, vis, distance_km, Ptx, noiseSigma, useGG);
            estSNR = estimate_snr_frame(rxSymbols);
            rxBits = mppm_demod(rxSymbols, curM, curK, bitsPerSym);
            txTrim = frameBitsVec(1:length(rxBits));
            ber = mean(txTrim ~= rxBits);
            BER_adaptive_frames(f) = ber;
            thr_adaptive_frames(f) = throughput_calc(bitsPerSym, ber);

            % simple closed-loop rule (same as Day5)
            if estSNR > 1.5
                if curM < 32, curM = min(32,curM*2); curK = max(1,curK); end
            elseif estSNR < 0.3
                if curK < curM-1, curK = min(curM-1, curK+1);
                else curM = max(4, curM/2); curK = min(curK,curM-1); end
            end
            curM = round(curM); curK = round(curK);
            if curK >= curM, curK = max(1,curM-1); end
        end
        avgBER_adaptive = mean(BER_adaptive_frames);
        avgThr_adaptive = mean(thr_adaptive_frames);

        % 2) Fixed modes
        for mIdx = 1:size(fixedModes,1)
            Mfixed = fixedModes(mIdx,1);
            Kfixed = fixedModes(mIdx,2);
            [txSymbolsAll, bitsPerSymFixed] = mppm_mod(bits, Mfixed, Kfixed);
            rxSymbolsAll = channel_fso(txSymbolsAll, vis, distance_km, Ptx, noiseSigma, useGG);
            rxBitsAll = mppm_demod(rxSymbolsAll, Mfixed, Kfixed, bitsPerSymFixed);
            txTrimAll = bits(1:length(rxBitsAll));
            ber_fixed = mean(txTrimAll ~= rxBitsAll);
            thr_fixed = throughput_calc(bitsPerSymFixed, ber_fixed);

            results = [results; vis, t, 1, avgBER_adaptive, avgThr_adaptive, Mfixed, Kfixed, ber_fixed, thr_fixed];
            % columns: vis, trial, modeFlag(1=adaptive), avgBER_adaptive, avgThr_adaptive, Mfixed,Kfixed, ber_fixed, thr_fixed
        end
        % store adaptive alone as row with M/K as zeros for clarity
        results = [results; vis, t, 0, avgBER_adaptive, avgThr_adaptive, 0, 0, NaN, NaN];
    end
end

% quick print
disp('results columns: vis, trial, flag(0=adapt,1=fixedRow), avgBER_adaptive, avgThr_adaptive, Mfixed,Kfixed, ber_fixed, thr_fixed');
disp(results);

% Save lightweight CSV
writematrix(results,'Day6_short_results.csv');
fprintf('Short run complete. Results saved to Day6_short_results.csv\n');
