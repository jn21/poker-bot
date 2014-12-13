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
%%  Junk            0.0     0.0     0.0
%%  SF              1.0     0.0     0.0
%%	SFO4            0.0842	0.2784	0.2414
%%	SFO3            0.0028	0.0389	0.0416
%%	SFI4            0.0426	0.3145	0.1249
%%  F               0.0     1.0     0.0
%%	F4              0       0.3497	0
%%	F3              0       0.0416	0
%%  S               0       0       1.0
%%	SO4             0       0       0.3145
%%	SO3             0       0       0.0444
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
%%  SF      1.0     0.0     0.0
%%	SFO4	0.0435	0.1522	0.1739
%%	SFI4	0.0217	0.1739	0.0870
%%  F       0.0     1.0     0.0
%%	F4      0       0.1957	0
%%  S       0       0       1.0
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

% Absolute decision maker
% Decision depends on absolute strength of agent's hand
% Does not reflect any relative assessment of hand strength or the pot
%
function decision = MakeDecision_Absolute(info)

    if (info.stage == 0)
        % pre flop
        decision = MakeDecisionPreFlop(info);
    else
        % flop / turn / river
        decision = MakeDecisionPostFlop(info);
    end
    
end

function decision = MakeDecisionPreFlop(info)
    persistent decProb
    decProb = [0.1 0.9 0.0; 0.3 0.7 0.0; 0.5 0.5 0.0; 0.7 0.3 0.0; 0.2 0.0 0.8];
    
    % this is a simple pre flop decision making function
    pfcat = preflop_cardtype(info.hole_card(1), info.hole_card(2));
    decision = sample_discrete(decProb(pfcat,:), 1, 1);
end

function decision = MakeDecisionPostFlop(info)
    global SFpred Kpred
    persistent finalprob
    finalprob = [0.1 0.0 0.9; 0.1 0.0 0.9; 0.8 0.2 0.0; 0.6 0.4 0.0; 0.4 0.6 0.0; 0.2 0.8 0.0; 0.1 0.9 0.0; 0.0 1.0 0.0; 0.0 1.0 0.0];
    
    if info.stage < 3
        % Compute final hand prob
        hand = [info.hole_card info.board_card];
        [ct high_ct] = cardtype(hand);
        [sf high_sf] = sftype(hand);
        
        % check CPT and get the prob of category SF
        SF = reshape(SFpred(info.stage,sf+1,:), 1, 3);
        % check CPT and get the prob of cateegory K
        K = reshape(Kpred(info.stage,ct+1,:), 1, 6);
        % combine p(SF) and p(K) for the final hand prob
        FH = CombineFinalHands(SF, K);
        
        % Assume straight or higher a winner
        winP = sum(FH(5:end)); 
        % Assume pair(1/4) to 3 of a kind keeps you in
        callP = sum(FH(3:4)) + FH(2)/4.0; 
        
        mustpay = info.cur_pot - info.paid(info.cur_pos);
        if mustpay > 0
            % Can't check
            decision = sample_discrete([callP winP 1.0-callP-winP], 1, 1);
        else
            decision = sample_discrete([1.0-winP winP 0.0], 1, 1);
        end
    else
        % In final round and know hand
        assert(size(find(info.board_card == -1),2)==0);
        hand = [info.hole_card info.board_card];
        ft = final_type(hand);
        decision = sample_discrete(finalprob(ft+1), 1, 1);
    end

end

% function win_prob = PredictWin(info)
%     %% The following is just a sample of randomly generating different
%     
%     %% ONLY for testing, do not forget to comment the following line
%     win_prob = 1;
% end


    

