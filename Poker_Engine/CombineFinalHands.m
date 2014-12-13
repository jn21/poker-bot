% Given two distributions over final hands, one for the SF category and the
% other for the K category, combine them into a single distribution over
% final hands. Assuming that they are independent events, the formula is to
% take the probability of a particular hand based on its particular
% category (K or SF) and then multiply it by the probability that the other
% hand came in at a lower value.
% 
% The 9 hand categories are:
%   1 -- Junk
%   2 -- One Pair
%   3 -- Two Pair
%   4 -- Three of a Kind
%   5 -- Straight
%   6 -- Flush
%   7 -- Full House
%   8 -- Four of a Kind
%   9 -- Straight Flush

function FHpred = CombineFinalHands(SFpred, Kpred)

    FHpred = zeros(9,1);
    % Simplest to just handle case by case
    FHpred(9) = SFpred(1);
    lowSF = 1 - SFpred(1);
    FHpred(8) = Kpred(1)*lowSF;
    FHpred(7) = Kpred(2)*lowSF;
    lowK = 1 - Kpred(1) - Kpred(2);
    FHpred(6) = SFpred(2)*lowK;
    FHpred(5) = SFpred(3)*lowK;
    lowSF = 1 - SFpred(1) - SFpred(2) - SFpred(3);
    FHpred(4) = Kpred(3)*lowSF;
    FHpred(3) = Kpred(4)*lowSF;
    FHpred(2) = Kpred(5)*lowSF;
    FHpred(1) = Kpred(6)*lowSF;
end