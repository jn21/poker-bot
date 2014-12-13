%This script runs every time a betting decision has to be made. The input
%structure 'info' contains all the necessary information about the state of
%the game. On the flop/turn this script will return a matrix of size 9 x
%1326 which represents the distribution over the nine hand categories for
%every possible hole card combination given the current board cards. 
%On the river we return a boolean 
%vector of length 1326 which denotes whether our Agent wins the hand
%against each possible hole card combination. 
%
%Importantly, since our win probability calculations do not vary within
%each betting stage, we only need to do the full calculation described
%above once per stage.

function su_info = StageUpdater(info)
    
    info.stage_bet;
    info.first_pos;
    info.cur_pos;
    board_card = info.board_card;
    hole_card_agent = info.hole_card;
    stage = info.stage;
    
    stages_in_round = size(info.stage_bet,1);

    %Determine whether it's first decision of round
    if stages_in_round == 0
        first_decision_of_round = 1;
    elseif stages_in_round == 1
        if info.stage_bet(info.cur_pos) == 0
            first_decision_of_round = 1;
        else
            first_decision_of_round = 0;
        end
    else
        first_decision_of_round = 0;
    end
    

    if first_decision_of_round
        %Generate all possible hole cards for opponent. Note that the
        %oppHoleCardBank vector MUST!! include cards in agents hand and that
        %are on the board. This is to preserve coherence b/w vector
        %of opp hole card distributions and the hole cards themselves. 
        cards = 0:51;
        oppHoleCardBank = nchoosek(cards,2);
        num = length(oppHoleCardBank);
    
        if info.stage == 1 || info.stage == 2
            
            %For each possible (and impossible) hole cards, generate final
            %hand distribution
            final_hand_dist_opp = zeros(9,num);
            for i = 1:num
                hand_opp = [oppHoleCardBank(i,:) board_card];
                final_hand_dist_opp(:,i) = hand2final_dist(hand_opp,stage);
            end
            
            su_info = final_hand_dist_opp;
            
        elseif info.stage == 3
            %Simulate agent hand vs possible opponent hands
            %Count tie as win for agent
            winner = zeros(num,1);
            for i=1:num
                win = compare_showdown([1,1], [hole_card_agent;oppHoleCardBank(i,:)], board_card);
                winner(i,1) = win(1);
            end
            
            agent_wins = (winner == 1);
            su_info = agent_wins;
            
        else
            %Preflop - do nothing
            su_info = [];
        end
    else
        %'Not first decision of round!'
        %Return cached value of su_info
        su_info = info.su_info;
    end     

end


