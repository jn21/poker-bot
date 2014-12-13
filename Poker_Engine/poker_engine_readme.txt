Changelog
* Fixed the CPT table for SFpred

1. Background
Card Representation: We use an integer 0 to 51 to represent all cards(from diamonds 2 to spades Ace). The value is computed as: val = floor(card/4)+2. (Value 14 means Ace). The suite is computed as: suit = mod(card,4), in which 0-diamonds 1-clubs 2-hearts 3-spades.

Texas Hold'Em: There are four stages: pre-flop, flop, turn, river. Our game engine will call function MakeDecision(info) at every stage. At each stage your decision could be 1-Call or Check 2-Bet or Raise 3-Fold. If you fold, you lose money previously invested and are out of the game.

2. Tips and Notes
poker_main.m is the main game engine. Our scaffolding code already contains several top agents from last year. These agents are provided for a 10-player game. Do not worry about your performance at this stage since most of the agents has implemented all three parts of the project. If you just run it without writing your own code, you should be able to see the records in your console. It records game info and player status of every round in every game. Make sure you understand this output before you proceed. 

You can modify poker_main.m for debugging purposes. For example you can output more variables to "record.txt". HOWEVER, PLEASE DO NOT ADD VARIABLES OR ADDITIONAL FUNCTIONS. In the testing, we'll replace this file with a standard version.

The function MakeDecision(info) is the most important function. All other functions you wrote serve for the purpose of generating a decision in each round. Please make sure it has the correct value(1 to 3). If not, our engine will assume your agent decide to fold.

There are some helper functions computing card types(cardtype.m, preflop_cardtype.m, sftype.m). You do not need to read the details of implementation as long as you understand the input and output format. Same with poker_main.m, you don't need to understand all variables. But you should know where to call the function and what do input/output of those function mean. 

Try playing with it for a few rounds with the existing agents. It would be helpful to set breakpoint and check the values if you want to understand the variables quickly.

3. What to submit in Part I, Part II and Part III
Please compress your version of the following files: 
Part I:   MakeDecision.m, along with your report into a single file.
Part II:  MakeDecision.m, along with your report into a single file.
Part III: MakeDecision.m UpdateOpponent.m StageUpdater.m, along with your report into a single file.

4. Dependencies
The poker engine is self-contained and does not require any third-party library. However, some of the included agents require BNT. Please make sure that you have installed BNT correctly.  

5. Some additional notes on the game engine code.

Betting History

In the model for history.bet, the betting for each stage of the game can occupy multiple rows in the bet matrix. The first row is padded with zeros until the position of the first player is reached, and the last row is also padded with zeros after the last betting action has been taken. A typical scenario might look like this:

0 0 0 1 1 1 2 1
1 2 1 1 1 3 3 1
1 0 0 0 0 0 0 0

In this example, player 4 is in first position and begins by checking, player 7 places the first bet and then player 2 re-raises, with everyone calling, except players 6 and 7 who fold.

In order to accommodate the fact that games take a variable number of rows, there is a field history.start, which contains a matrix that is n x 4, where n is the number of games that have been played so far. Each row of history.start contains an index to the start of the row in the bet matrix for each of the game stages. An example would look like:

row 2:  12 14 17 18

which means that the preflop betting round for game 2 begins at row 12 in history.bet, the postflop betting round begins at 14 (and ends at 16), and the rounds for the turn and river begin on 17 and 18. You can use these indices to examine the betting behavior for a particular stage of a particular game if you care to do so.

Note that in order to simplify the implementation, the history.start field is not updated until the game is over, but history.bet is updated incrementally at the end of each game stage. If you want to access history.bet within a game (while it is being played) the indices to rows are stored temporarily in history.stage_starts, which is updated incrementally and then copied into history.start when the game is over.

Note that you can search the columns of history.bet to obtain information about a given player. See lines 379-400 in the new version of poker_main.m for an example of how to extract such betting behavior.

In poker, ties are handled by dividing the pot among the players with the same hand. In games with 8 players this happens maybe 5% of the time. The function compare_showdown in poker_main.m implements this

Make Decision

The file MakeDecision_Default contains stub code for you to fill in the functions you will use for deciding how to bet. This file is where you should start with Part I of the project. It implements at random betting behavior by default. The file MakeDecision_Random implements the same random behavior. The file MakeDecision_Absolute implements a more sophisticated approach which uses the absolution strength of the hand to bias a randomized betting strategy. In simulations this decision criteria is an improvement over MakeDecision_Random. Your pot odds based strategy should provide further improvement. Take a look at MakeDecision_Absolute to see how to access the different hand information from the data structures.

Playing a Game

Type poker_main to run the game engine and play a match Constants at the start of that file control how many players and how many hands will be played. The default behavior is to pause for a keypress after every game, to allow you the chance to look back over the history. You can modify variable rounds_not_to_pause to control the pause . In order to compute statistically-meaningful summaries of performance you will need to simulate at least 100's of hands or more.

Factored State Space - Implementation
 
To save computation we factor the hand categories into two groups, Straight-Flush (SF) and N of a Kind (K). When predicting final hand we treat these as independent. The question is how to combine them into a single distribution over final hands. This is a slightly tricky but doable problem. The key is to realize that the two categories are interleaved in the final hand ranking. The probability for any state in the final hand is the product of two probabilities: The probability of achieving that state in whatever category it is (e.g. SF) multiplied by the probability that the other category will come in at lower hand value (because otherwise it would dominate). To see this, consider a simpler case where x and y are two independent categories which taken on values 1 and 2. y models the SF categories and p(y=1)=p1 and p(y=2)=p2. x models the K categories and p(x=1)=t1 and p(x=2)=t2 with t1+t2=1. We can also have y=0 (no SF category) and p(y=0) = 1-p1-p2. The final hands are ordered as follows: 1) y=1; 2) x=1; 3) y=2; 4) x=2. We can make a truth table of the possible combinations of x and y categories and the resulting final category, along with its probability:
 
y              x              F              Prob
----------------
0              1              2              (1-p1-p2)t1
0              2              4              (1-p1-p2)t2
1              1              1              p1t1
1              2              1              p1t2
2              1              2              p2t1
2              2              3              p2t2
 
We can see that the total probability sums to 1, so this defines a valid distribution over F=1,2,3,4. We can compute the distribution over F:
P(F=1) = p1t1 + p1t2 = p1
P(F=2) = (1-p1-p2)t1 + p2t1 = (1-p1)t1
P(F=3) = p2t2
P(F=4) = (1-p1-p2)t2
 
The pattern is clear. Each value of F corresponds to either x or y. It's probability is given by the probability of occurring from the distribution it comes from times the probability that the other category variable came in at a lower position. e.g. P(y=2|FH) = P(y=2|Y)*P(x<2|X) = p2t2. This part is implemented in CombineFinalHands.m. See MakeDecision_Absolute for an example. 