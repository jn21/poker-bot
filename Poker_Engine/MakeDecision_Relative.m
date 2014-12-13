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
%%  J               0.0     0.0     0.0
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

% Relative decision maker
% Decision depends on assessmeent of probability of winning relative to a
% default prior distribution over 7 card final hands
% Does not reflect any assessment of pot odds
%
function decision = MakeDecision_Default(info)
    if (info.stage == 0) 
        decision = MakeDecisionPreFlop(info);
    else
        decision = MakeDecisionPostFlop(info);
    end
end

function decision = MakeDecisionPreFlop(info)
    decision = 1;
end

function decision = MakeDecisionPostFlop(info)
    global SFpred Kpred FHprior FHcdf
    
    if info.stage < 3
        
        % Compute final hand prob
        hand = [info.hole_card info.board_card];
        [ct high_ct] = cardtype(hand);
        [sf high_sf] = sftype(hand);

        SF = reshape(SFpred(info.stage,sf+1,:), 1, 3);
        K = reshape(Kpred(info.stage,ct+1,:), 1, 6);
        FH = CombineFinalHands(SF, K);
        
        % numO = size(info.active, 2)-1;
        winP = PredictWin(FH, info.num_oppo, FHprior, FHcdf);
    else
        % In final round and know hand
        assert(size(find(info.board_card == -1),2)==0);
        hand = [info.hole_card info.board_card];
        ft = final_type(hand);
        
        winP = PredictWin_Final(ft, info.num_oppo, FHprior, FHcdf);
    end
    
    % fprintf(1, '\nStage %d:  Win prob %0.4f\n\n', info.stage, winP);
    
    mustpay = info.cur_pot - info.paid(info.cur_pos);
    if mustpay > 0
        % Can't check
        winP = winP+0.2;
        if winP > 1.0
            winP = 1.0;
        end
        decision = sample_discrete([winP/2 winP/2 1.0-winP], 1, 1);
    else
        decision = sample_discrete([1.0-winP winP 0.0], 1, 1);
    end

end

% Compute probability of winning vs N opponents
% Inputs:
%   PA - distribution over final hands for agent
%   numO - Number of opponents
%   PO - distribution over final hands for opponent
%   POcdf - CDF of opponent distribution
%
% Assumes that all opponents are described independently by the same final
% hand distribution. Computes probability of direct win and tie. Tie is
% then added to win assuming that ties are broken by choosing uniformly at
% random from the tieing players.
%
function win_prob = PredictWin(PA, numO, PO, POcdf)
    win_prob = 0.0;
    m = size(PA, 2);
    % Work from highest hand to lowest, prob of beating all lower hands
    for i=m:-1:2
        win_prob = win_prob + PA(i)*(POcdf(i-1)^numO);
    end
    tmptie = zeros(m,numO);
    % Estimate ties among varying numbers of opponents, from 1 to numO
    % Tie is when some number of other players have the same hand as you,
    % and the rest have hands below you.
    for i=m:-1:2
        for j=1:numO
            tmptie(i,j) = PA(i)*nchoosek(numO,j)*(PO(i)^j)*(POcdf(i-1)^(numO-j));
        end
    end
    tmptie(1,numO) = PA(1)*PO(1)^numO;
    tie_prob = sum(tmptie,1);
    % Assign probability mass of ties to win based on equal proportions
    for j=1:numO
        win_prob = win_prob + tie_prob(j)/(j+1);
    end
end

% Predict win for case of final round, where agent hand is completely
% known.
%
function win_prob = PredictWin_Final(ft, numO, PO, POcdf)
    tie_prob = zeros(1,numO);

    % Beat all hands ranked below yours
    if ft > 0
        win_prob = POcdf(ft);  % Note: use ft here because it ranges from 0 to m-1, and this gives the position below
        
        % Estimate ties among varying numbers of opponents, from 1 to numO
        for j=1:numO
            tie_prob(j) = nchoosek(numO,j)*(PO(ft+1)^j)*(POcdf(ft)^(numO-j));
        end
    else
        win_prob = 0;
        % For junk case, all we can hope for is tie since we can't see high
        % cards at this level of analysis
        tie_prob(numO) = PO(ft+1)^numO;
    end

    % Assign probability mass of ties to win based on equal proportions
    for j=1:numO
        win_prob = win_prob + tie_prob(j)/(j+1);
    end
end


