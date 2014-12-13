%% Decision Making
%%
%% INPUT: a structure "info" containing various information about the 
%%        current state of the game and opponent betting history.
%% OUTPUT: an integer from 1 to 3 indicating:
%%         1: CALL or CHECK
%%         2: BET or RAISE
%%         3. FOLD


function decision = MakeDecision_Default(info)
    if (info.stage == 0) 
        decision = MakeDecisionPreFlop(info);
    else
        decision = MakeDecisionPostFlop(info);
    end
end
function decision = MakeDecisionPreFlop(info)
    
    N = info.num_oppo + 1; % # of players in game
    Nactive = sum(info.active);% # of players in hand
    
    cards = info.hole_card;
    ct = preflop_cardtype2(cards(1),cards(2));
    
    %fold_prob is the probability of folding given each hand category. The
    %fold probability is initialized. Then it is adjusted based on the # of
    %players in the current hand with the following properties. The fold 
    %proability is
    %unchanged if all players are in the pot. The fold probability
    %decreases as the number of players decreases, if there is nobody but
    %the agent in the pot, the fold probability should be 0. The
    %interpolation between the extreme cases is handled by the
    %fold_dampener function. This is a logistic function. A and B are
    %normalizing constants.
    fold_prob = [0,0,.20,.25,.95];
    A = 1/(1 + exp(N/2 - 1));
    B = 1/(1/(1 + exp(-N/2)) - A);
    fold_dampener = @(t) B*(1 ./ (1+exp(-(t - N/2)))- A);
    fold_prob = fold_prob*fold_dampener(Nactive);
    
    %Given the fold probability compute the call/raise probability by
    %fixing the ratio b/w the raise and call probability. Then solve the
    %equation fold_prob + call_prob + raise_prob = 1
    raisecallratio = [9,3,.5,.05,.01];
    probs = zeros(5,2);
    probs(:,1) = (1 - fold_prob) ./ (1 + raisecallratio);
    probs(:,2) = probs(:,1) .* raisecallratio';
    
    %Preflop decision is made probabalistically
    mustpay = info.cur_pot - info.paid(info.cur_pos);
    if mustpay > 0
        decision = sample_discrete([probs(ct,1) probs(ct,2) 1-probs(ct,1)-probs(ct,2)],1,1);
    else
        decision = sample_discrete([probs(ct,1) 1-probs(ct,1) 0],1,1);
    end
end
function decision = MakeDecisionPostFlop(info)

    %Calculate the probability of agent winning hand if it gets to showdown
    win_prob = PredictWin(info);
    
    if info.stage == 1
       bet_unit = 5;
    else 
       bet_unit = 10;
    end
    
    %can we check or is there a bet to us?
    mustpay = info.cur_pot - info.paid(info.cur_pos);
    
    %Compute call_odds. 
    %Call_odds =(approximately) (amount agent expected to put into pot in stage)/(total
    %amount agent can win)
    pot = info.pot;
    num_opp = sum(info.active) - 1;
    tocall = info.cur_pot - info.paid(info.cur_pos);
    num_raises_left = 4 - sum(sum(info.stage_bet == 2));
    call_odds = (tocall + bet_unit*num_raises_left)/ (pot + tocall + num_opp*bet_unit*(3/2));
    
    %If the win_prob is greater than the number of players, then raise.
    %If not, then check the call_odds
    %If no bet on table, never fold
    if mustpay > 0
        if win_prob > 1/(num_opp + 1)
            decision = 2;
        elseif win_prob > call_odds
            decision = 1;
        else
            decision = 3;
        end
    else
        if win_prob > 1/(num_opp + 1)
            decision = 2;
        else
            decision = 1;
        end
    end
end

function win_prob = PredictWin(info)
    %Using observed opponents hole cards in showdown, predict a
    %distribution over which hole cards the opponent tends to play. 
    %Calculate the probability the agent wins vs every possible opponent
    %hole card combination, then apply the distribution over opponent hole
    %cards to arrive at a win probability.
    
    stage = info.stage;
    hole_card_agent = info.hole_card;
    board_card = info.board_card;
    num_opp = sum(info.active) - 1;
    hand_agent = [hole_card_agent board_card];
    
    oppo_hole_dist = cell2mat(info.oppo);
    
    %Special handling for first game of session 
    if length(oppo_hole_dist) == 0
        oppo_hole_dist = ones(nchoosek(52,2),length(info.active)) / nchoosek(52,2);
    end
    
    %Remove agent and nonacitve players from opp_hole_dist;
    active_opp = info.active;
    active_opp(info.cur_pos) = 0;
    t = 1:length(info.active);
    active_opp_idx = t(active_opp == 1);
    oppo_hole_dist = oppo_hole_dist(:,active_opp_idx);
    
    %Generate all impossible hole card combinations for opponent (includes
    %cards on board and agent hole cards). For each impossible card find 
    %all 52 places it occurs in the opp_hole_dist vector. Zero out the corresponding
    %probabilities in opp_hole_dist and then normalize.
    impossible_cards = [hole_card_agent board_card(1:(2+stage))];
    impossible_index = imposs_cards_to_index(impossible_cards);
    oppo_hole_dist(impossible_index,:) = 0;
    oppo_hole_dist = normalise(oppo_hole_dist,1);

    if stage == 1 || stage == 2
        
        %unweighted final hand distribution for opponents in hand
        FH_DIST_OPP = info.su_info;
        
        %Weight the opponent final hand distribution by likelihood of hole card
        fh_dist_opp = FH_DIST_OPP*oppo_hole_dist;
        fhcdf_opp = cumsum(fh_dist_opp);
        
        %Get final hand distribution for agent and tie multiplier
        fh_dist_agent = hand2final_dist(hand_agent,stage);
        tf = tie_factor(hole_card_agent,board_card);
        
        %Assume independence to calculate win_prob for multiple agents
        win_prob = 1;
        for k = 1:num_opp
            temp_win_prob = sum(fh_dist_agent .* fhcdf_opp(:,k)) - sum(fh_dist_agent .* fh_dist_opp(:,k) .* (1 - tf));
            win_prob = win_prob * temp_win_prob;
        end
    end

    
    if stage == 3
        
        %agent_wins holds the simulation info
        agent_wins = info.su_info;
        
        win_prob = 1;
        for k = 1:num_opp
            win_prob = win_prob * sum(agent_wins .* oppo_hole_dist(:,k));
        end
    
    end
    
end
function tf = tie_factor(hole_card,board_card)
% Given agent hand category, determine how strong of a hand_category the
% agent has. EG pair of K's is better than pair of 7's. 
% The output is a length 9 vector tf. tf(i) = x, implies that given an
% agent hand category of i, it is predicted that if one opponent also has
% a hand_category of i, agent will win x percent of the time vs that opp. 

global VALnames

tf_temp = ones(9,1);

agent_ft = final_type([hole_card board_card]);

agent_hc = hand_category(hole_card, board_card);
board_hc = hand_category(board_card);
agent_ktype = cardtype([hole_card board_card]);
board_ktype = cardtype(board_card);
agent_sftype = sftype([hole_card board_card]);
board_sftype = sftype(board_card);
high_hole_card = max(floor(hole_card ./ 4) + 2);
low_hole_card = min(floor(hole_card ./ 4) + 2);

cards_on_board = board_card(board_card >= 0);
num_cards_on_board = length(cards_on_board);
board_vals = sort(floor(cards_on_board/4) + 2);

%%Agent has Junk
%Set tie factor for junk and pair depending on high hole card
if agent_ft == 0
    tf_temp(1) = (high_hole_card/14)^2;
    tf_temp(2) = tf_temp(1);
end

%%Agent has Pair
%if there is a pair on board, set tie factor based on high hole card. If
%there is no pair on board, use the value of the pair and its rank among
%the cards on the board
if agent_ft == 1
    if board_ktype == 1
        tf_temp(2) = high_hole_card/14;
    else
        alpha1 = .6; alpha2 = .3;%controls weight of top/bot/mid pair idea 
        %vs overall pair value vs kicker         
        pairVal = find(VALnames == agent_hc(9)) + 1;
        kickVal = find(VALnames == agent_hc(10)) + 1;
        rank = sum(board_vals <= pairVal);
        tf_temp(2) = alpha1*rank/num_cards_on_board + alpha2*pairVal/14  + (1 - alpha1 - alpha2)*kickVal/14;
    end
end

%%Agent has Two pair
%If there is two pair on board, set tie factor based on high hole card.
%If there is one pair on board, set tie factor based on value of pair in
%hand.
%If there is no pair on board, set tie factor based on value of high hole
%card
if agent_ft == 2
    if board_ktype == 2
        tf_temp(3) = high_hole_card/14;
    elseif board_ktype == 1
        pairVal_high = find(VALnames == agent_hc(9)) + 1;
        pairVal_low = find(VALnames == agent_hc(10)) + 1;
        board_pair_val = find(VALnames == board_hc(9)) + 1;
        
        if board_pair_val == pairVal_high
            tf_temp(3) = pairVal_low/14;
        elseif board_pair_val == pairVal_low
            tf_temp(3) = pairVal_high/14;
        else
            %error!
            tf_temp(3) = 1;
        end
    else
        tf_temp(3) = high_hole_card/14;
    end
end

%%Agent has K3
%If there is K3 on board use highest hole card
%If there is K2 on board, use hole card not involved in the K3
%If there is no pair on board, use value of triple
if agent_ft == 3
    if board_ktype == 3
        tf_temp(4) = high_hole_card/14;
    elseif board_ktype == 1
        tripVal = find(VALnames == agent_hc(10)) + 1;
        if tripVal == high_hole_card
            tf_temp(4) = low_hole_card/14;
        else
            tf_temp(4) = high_hole_card/14;
        end
    else
        tripVal = find(VALnames == agent_hc(10)) + 1;
        rank = sum(board_vals <= tripVal);
        tf_temp(4) = rank/num_cards_on_board;
    end 
end

% tie factor for agent having straight or better are not calculated 
tf = tf_temp;

end
function imposs_index = imposs_cards_to_index(imposs_cards)
%Take as input a set of integers in 0,1,2 ... D-1
%Output the indices of the occurences of these integers in the
%lexicographic ordering of the two element subsets of {0,1, ..., D-1}
%this is the ordering as appears in nchoosek(0:(D-1),2)

D = 52; %deck size

index_to_remove = [];

for k=1:length(imposs_cards)
    
    start = [];
    finish = [];
    other_inds = [];
    
    x = imposs_cards(k);
    
    if x ~= (D-1)
        finish = (x+1)*(D-1) - x*(x+1)/2;
        start = finish - ((D-1) - x - 1);
    end
    
    % define triangular numbers
    T = @(n) n.*(n+1)/2;
    
    if x ~= 0
        other_inds = x*ones(1,x) + (D-1)*(0:(x-1)) - T(0:(x-1));
    end
    
    temp = [start:finish other_inds];
    index_to_remove = [index_to_remove temp];
end

imposs_index = unique(index_to_remove);
end


    
    

