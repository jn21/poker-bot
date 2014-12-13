function fh_dist = hand2final_dist(hand,stage)
%Input: A set of cards and the stage of the game
%Output: Probability distribution over final hands

global SFpred Kpred

k_type = cardtype(hand);
sf_type = sftype(hand);

k_dist = reshape(Kpred(stage,k_type+1,:), 1, 6);
sf_dist = reshape(SFpred(stage,sf_type+1,:), 1, 3);
fh_dist = CombineFinalHands(sf_dist,k_dist);

end