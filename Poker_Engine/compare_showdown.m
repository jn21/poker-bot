function winner = compare_showdown(active, hole_card, board_card)
    final_card = [];
    for i = 1:size(active,2)        
        final_card = [final_card;[board_card hole_card(i,:)]];
    end  
    
    max_type = -1;
    max_card = -1;
    
    % look-up table for type -- number of max card 
    % this table how many high cards to track for different final type
    % Junk 5, One pair 1+3, Two pairs 2+1, 3K 1+2, S/F 1, Full House 2, 4K
    % 1+1, SF 1
    type_max_card = [5 4 3 3 1 1 2 2 1];
    
    for i = 1:size(final_card,1)
        if (active(i) == true)
            card = final_card(i,:);
            [type highcard] = final_type(card);
            card_sorted = SortCardVal(card);
            
            % regenerate the high card
            for curHighCard = 1:length(highcard)
                card_sorted = card_sorted(card_sorted~=highcard(curHighCard));
            end
            highcard = [highcard, card_sorted(end:-1:1)];
            highcard = highcard(1:type_max_card(type+1));
            
            if (type > max_type)         
               
                % New winner on hand type
                winner = i;
                max_type = type;
                max_card = highcard;
                
            elseif (type == max_type)
                
                % JIM modified, YL revised              
                % let us compare all highcards in descending order
                winFlag = 0;   % -1 lose; 0 tie; 1 win
                for curHighCard = 1:length(highcard)
                    if highcard(curHighCard) > max_card(curHighCard)
                        % New winner on high card
                        winFlag = 1;
                        break;
                    elseif highcard(curHighCard) < max_card(curHighCard)
                        % Current agent is weaker than the best hand
                        winFlag = -1;
                        break;
                    end
                end
                
                % win or tie
                if winFlag == 1
                    winner = i;
                    max_card = highcard;
                elseif winFlag == 0
                    winner = [winner i];
                end
                   
            end
            
        end
    end
end
function [sorted_card] = SortCardVal(card)

    card = card(card ~= -1); % Remove any -1 codes from undealt board cards
    card = sort(card);
    sorted_card = floor(card/4)+2; % card value
    %sorted_suit = mod(card,4);     % card suit
    
end