%% Update Opponent Model
%%
%% INPUT: a matrix recording K round history info containing
%%        the following field
%%        showdown: K by 1 binary vector, recording if a game finally went
%%                  to a showdown stage.
%%        board:    k by 5 matrix, recording all the board cards
%%        hole:     k by N*2 matrix, recording hole cards for all players.
%%                  If a player folds, his cards are hidden (-1)
%%        bet:      k*4 by N, betting history of each player in four
%%                  rounds.
%%
%% OUTPUT: a matrix recording opponent model parameters

%After each round look at all observed (in the showdown) hole cards for
%each player. Build a simple histogram based distribution which models the
%frequency with which each player plays each possible hole card combination

function oppo = UpdateOpponent(history,i)

    hist = history.hole;
    N = size(history.money,2);
    oppo = zeros(nchoosek(52,2),N);
    
    if length(hist) ~= 0
        for j = 1:N
            %For each player in the game, remove any -1's from hole card
            %history and compute hole_card_dist from hole cards we have
            %seen in the showdown
            one_opp_hist = hist(:,[2*j-1,2*j]);
            one_opp_hist(all(one_opp_hist == -1,2),:) = [];
            oppo(:,j) = opp_hole_dist(one_opp_hist);
        end 
    end
    
    %Special handling for first hand of session
    if length(hist) == 0
        oppo = ones(nchoosek(52,2),N) / nchoosek(52,2);
    end
end

function hole_card_DIST = opp_hole_dist(OBS)
    %Take as input a list of observed opponent hole cards (with -1's
    %removed). Generate a histogram type distribution over hole cards.
    %Beginning with an initial distribution, interpolate between initial
    %distribution and histogram distribution until there has been
    %MAX_OBS_DECAY hole card observations made for the opponent

    DECK_SIZE = 52;
    MAX_OBS_DECAY = 200;
    init_DIST = (1/nchoosek(DECK_SIZE,2)) * ones(1,nchoosek(DECK_SIZE,2));

    if isempty(OBS)
        hole_card_DIST = init_DIST;
    else
        NUM_OBS = size(OBS,1); %number of observed hole cards for player

        %Take each observed hole_card and map it to it's lexicographic 
        %position in all possible combinations
        low = min(OBS,[],2);
        high = max(OBS,[],2);
        OBS_pos = low*DECK_SIZE - (low .* (low+1) / 2) + (high - low);

        %Count number of times each hole_card pair is observed and create the
        %observed hole_card distribution
        [occurences,counts] = count_unique(OBS_pos);
        obs_DIST = zeros(1,nchoosek(DECK_SIZE,2));
        obs_DIST(occurences) = counts ./ NUM_OBS;

        %Combine initial distribution with observed distribution
        alpha = min(1,NUM_OBS/MAX_OBS_DECAY);
        hole_card_DIST = (1 - alpha)*init_DIST + alpha * obs_DIST;
    end
end

