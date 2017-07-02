

import UIKit


let sentiment = Sentimently()
print(sentiment.score("Cats are stupid."))
print(sentiment.score("Cats are totally amazing!"))
var testInject = [sentimentWeightValue]()
testInject.append(sentimentWeightValue(word: "cats", score: 5))
testInject.append(sentimentWeightValue(word: "amazing", score: 2))

print(sentiment.score("Cats are totally amazing!", addWeights: testInject))
print(sentiment.score("I very love cats"))
print(sentiment.score("I super love cats"))
