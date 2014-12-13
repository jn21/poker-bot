%% Decision Making
%%
%% INPUT: a structure "info" containing the following field
%%        stage, pot, cur_pos, cur_pot, first_pos, board card,
%%        hole_card, active, paid, history, su_info, oppo_model
%% OUTPUT: an integer from 1 to 3 indicating:
%%         1: CALL or CHECK
%%         2: BET or RAISE
%%         3. FOLD

%% We provide some auxiliary probability tables, see section 3.4 
%% in the write-up. If you use BNT by Kevin Murphy, please check
%% sample BNT code student_BNT.m in T-Square to see how to use it.
%%
%% Some zero entrie do not really mean zero probability, instead
%% they mean states we do not care about because they can not
%% contribute to any effective hand category in the showdown

%% Table 1: Prior probability of final categories given 7 cards

%%  Busted          0.1728
%%  One Pair        0.438
%%  Two Pair        0.2352
%%  3 of a Kind     0.0483
%%  Straight        0.048
%%  Flush           0.0299
%%  Full House      0.0255
%%  4 of a Kind     0.0019
%%  Straight Flush	0.0004

%% Table 2: Straight and Flush CPT from flop (given two draws)

%%                  SF      Flush	Straight
%%	SFO3            0.0028	0.0389	0.0416
%%	SFO4            0.0842	0.2784	0.2414
%%	SFI4            0.0426	0.3145	0.1249
%%	F3              0       0.0416	0
%%	F4              0       0.3497	0
%%	SO3             0       0       0.0444
%%	SO4             0       0       0.3145
%%	SI4             0       0       0.1647
%%	SF03 & F4       0.0028	0.3469	0.0416
%%	SF03 & SI4      0.0028	0.0389	0.1360
%%	SF03 & SO4      0.0028	0.0389	0.2784
%%	SI4 & F3        0       0.0416	0.1647
%%	SI4 & F4        0       0.3497	0.1249
%%	SO3 & F3        0    	0.0416	0.0416
%%	SO3 & F4        0    	0.3497	0.0250
%%	SO4 & F3        0    	0.0416	0.2756
%%	SO4 & F4        0    	0.3497	0.2414

%% Table 3: N of a Kind CPT from flop (given two draws)

%%          K4      K3K2	K3      K2K2	K2      Junk
%%  K4      1.0     0.0     0.0     0.0     0.0     0.0
%%	K3K2	0.0435	09565   0.0     0.0  	0.0     0.0
%%	K3      0.0426	0.1249	0.8326  0.0     0.0     0.0
%%	K2K2	0.0019	0.1619	0.0000	0.8362  0.0     0.0
%%	K2      0.0009	0.0250	0.0666	0.3000	0.6075  0.0
%%	Junk	0.0000	0.0000	0.0139	0.0832	0.4440  0.4589

%% Table 4: Straight and Flush CPT from turn (given one draw)

%%          SF      Flush	Straight
%%	SFO4	0.0435	0.1522	0.1739
%%	SFI4	0.0217	0.1739	0.0870
%%	F4      0       0.1957	0
%%	SO4     0       0       0.1739
%%	SI4     0       0       0.0870

%% Table 5: N of a Kind CPT from turn (given one draw)

%%          K4          K3K2	K3      K2K2	K2      Junk
%%  K4      1.0         0.0     0.0     0.0     0.0     0.0
%%	K3K2	0.0217      0.9783  0.0     0.0     0.0     0.0
%%	K3      0.0217      0.196	0.7823  0.0     0.0     0.0
%%	K2K2	0.0000      0.0870	0.0     0.9130  0.0     0.0
%%	K2      0.0000      0.0     0.0435	0.2609	0.6956  0.0
%%	Junk	0.0000      0.0     0.0     0.0     0.3910  0.609

% Randomized version of the decision function
% No analysis of hand strength whatsoever, just a random decision
%
function decision = MakeDecision_Random(info)
    num = floor(rand(1)*100);
    if (num <= 60)
        decision = 1;
    elseif (num <= 90)
        decision = 2;
    else
        decision = 3;
    end
end

% function decision = MakeDecisionPreFlop(info)
%     pfcat = preflop_cardtype(info.hole_card(1), info.hole_card(2));
%     
%     
%     %% ----- FILL IN THE MISSING CODE ----- %%
%     win_prob = PredictWin(info);
%     %% ----- FILL IN THE MISSING CODE ----- %%
%     
%     %% The following is just a sample of randomly generating different
%     %% decisions. Please comment them after you finish your part.
%     num = floor(rand(1)*100);
%     if (num <= 60)
%         decision = 1;
%     elseif (num <= 90)
%         decision = 2;
%     else
%         decision = 3;
%     end    
% end
% 
% function decision = MakeDecisionPostFlop(info)
%    
%     %% ----- FILL IN THE MISSING CODE ----- %%
%     win_prob = PredictWin(info);
%     %% ----- FILL IN THE MISSING CODE ----- %%
%     
%     %% The following is just a sample of randomly generating different
%     %% decisions. Please comment them after you finish your part.
%     num = floor(rand(1)*100);
%     if (num <= 60)
%         decision = 1;
%     elseif (num <= 90)
%         decision = 2;
%     else
%         decision = 3;
%     end  
% end
% 
% function win_prob = PredictWin(info)
%     %% The following is just a sample of randomly generating different
%     
%     %% ONLY for testing, do not forget to comment the following line
%     win_prob = 1;
% end
