

import UIKit

let sentiment = Sentimently()
print(sentiment.score("I love cats."))
print(sentiment.score("Cats are totally amazing!"))

print(sentiment.score("Cats are stupid."))
print(sentiment.score("Cats are very stupid."))

var testInject = [sentimentWeightValue]()
testInject.append(sentimentWeightValue(word: "cats", score: 5))
testInject.append(sentimentWeightValue(word: "amazing", score: 2))

print(sentiment.score("Cats are totally amazing!", addWeights: testInject))
