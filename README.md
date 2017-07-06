# SentimentlySwift

A Sentiment Analysis Swift Playground using the [AFINN-165](http://www2.imm.dtu.dk/pubdb/views/publication_details.php?id=6010) wordlist and [Emoji Sentiment Ranking](http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0144296) to perform [sentiment analysis](http://en.wikipedia.org/wiki/Sentiment_analysis) on a given phrase.

More details available in [this blog post](https://bencoding.com/2017/07/06/sentiment-analysis-using-swift/).

### Features
- Provider own weight adjustments or use the defaults
- Phrase tokenized using NSLinguisticTagger
-[ Lemmatization](https://nlp.stanford.edu/IR-book/html/htmledition/stemming-and-lemmatization-1.html) word matching used to determine weights
- Override / provide weights at an instance or phrase level


#### Considerations
- English only, ie AFINN and Emoji Ranking are in English.  Would be grateful for PRs with additional language support
- Swift 3 support, only at the moment


#### Roadmap
- CocoaPods Support
- Swift 4

SentimentlySwift is based on the [sentiment](https://github.com/thisandagain/sentiment) and [sentiment-v2](https://github.com/rajatsharma305/sentiment-v2) node.js packages.
