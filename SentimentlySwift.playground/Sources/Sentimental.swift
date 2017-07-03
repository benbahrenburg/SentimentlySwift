import Foundation

typealias TaggedToken = (String, String?)

public struct analysisResult {
    var score: Int
    var comparative: Double
    var words: [String]
    var positive: [String]
    var negative: [String]
    var LemmaTags: [TaggedToken]
}

public struct sentimentWeightValue {
    public init(word: String, score: Int) {
        self.word = word
        self.score = score
    }
    var word: String
    var score: Int
}

public protocol sentimentAdjusters {
    var negators: [String] {get set}
    var incrementors: [String] {get set}
    var hybrid: [String] {get set}
}

internal struct defaultAdjusters: sentimentAdjusters {
    var negators = [
        "cant",
        "can't",
        "didnt",
        "didn't",
        "dont",
        "don't",
        "doesnt",
        "doesn't",
        "not",
        "non",
        "wont",
        "won't",
        "isnt",
        "isn't"
    ]
    
    var incrementors = [
        "very", "really"
    ]
    
    var hybrid = [
        "super", "extremely"
    ]
}

internal struct utils {
    static fileprivate func loadWordList(fileName: String) -> [NSString: AnyObject]? {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "json") else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
            guard let jsonResult: Dictionary<NSString, AnyObject> = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [NSString: AnyObject] else {
                return [NSString: AnyObject]()
            }
            
            return jsonResult
            
        } catch let error as NSError {
            print(error.localizedDescription)
            return nil
        }
    }
}


public struct Sentimently {
    fileprivate var wordSource: [NSString: AnyObject]?
    fileprivate let weights: sentimentAdjusters
    
    public init(weights: sentimentAdjusters) {
        self.weights = weights
    }
    
    public init(fileName: String, weights: sentimentAdjusters) {
        self.wordSource = utils.loadWordList(fileName: fileName)
        self.weights = weights
    }
    
    public init(fileName: String) {
        self.wordSource = utils.loadWordList(fileName: fileName)
        self.weights = defaultAdjusters()
    }
    
    public init() {
        self.init(fileName: "AFINN")
    }

    fileprivate func lemmatize(_ text: String) -> [TaggedToken] {
        let options: NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther]
        let tagger = NSLinguisticTagger(tagSchemes: NSLinguisticTagger.availableTagSchemes(forLanguage: "en"),
                                        options: Int(options.rawValue))
        tagger.string = text
        
        var tokens: [TaggedToken] = []
        
        tagger.enumerateTags(in: NSMakeRange(0, text.characters.count), scheme:NSLinguisticTagSchemeLemma, options: options) { tag, tokenRange, _, _ in
            let token = (text as NSString).substring(with: tokenRange)
            tokens.append((token, tag))
        }
        return tokens
    }

    fileprivate func tagFlatten(token: TaggedToken) -> [String] {
        var output = [String]()
        let extractToken = token.0.lowercased()
        output.append(extractToken)
        if let extractTag = token.1 {
            let extractTag = extractTag.lowercased()
            if extractTag != extractToken {
                output.append(extractTag)
            }
        }
        return output
    }
    fileprivate func tokenize(tokens: [TaggedToken], wordSource: [NSString: AnyObject]) -> [String] {
        var output = [String]()
        
        for position in 0...tokens.count - 1 {
            var scope: Int = 0
            var word: String = tokens[position].0
            for tag in tagFlatten(token: tokens[position]) {
                if tag != word {
                    if let item = wordSource[tag as NSString] {
                        let itemScore = Int(item as! NSNumber)
                        if abs(scope) != abs(itemScore) {
                            scope = itemScore
                            word = tag
                        }
                    }
                }
            }
            output.append(word)
        }
        
        return output
    }
    
    func calculateScore(position: Int, word: String, wordSource: [NSString: AnyObject], tokens: [String]) -> Int {
        var itemScore: Int = 0
        
        if let item = wordSource[word as NSString] {
            itemScore += Int(item as! NSNumber)
            
            guard position > 0 else {
                return itemScore
            }
            
            let prevtoken = tokens[position - 1]
            
            if (weights.negators.filter {
                $0 == prevtoken
            }).count > 0 {
                itemScore += -1
            }
            
            if (weights.incrementors.filter {
                $0 == prevtoken
            }).count > 0 {
                itemScore += 1
            }
            
            if (weights.hybrid.filter {
                $0 == prevtoken
            }).count > 0 {
                if let _ = wordSource[prevtoken as NSString] {
                    itemScore += Int(item as! NSNumber)
                }
            }
        }
        
        return itemScore
    }
    
    public func score(_ phrase: String, addWeights: [sentimentWeightValue] = []) -> analysisResult {
        
        var output = analysisResult(score: 0, comparative: 0, words: [], positive: [], negative: [], LemmaTags: [])
        
        guard var wordSource = wordSource else {
            return output
        }

        if addWeights.count > 0  {
            for injectItem in addWeights {
                wordSource[injectItem.word as NSString] = injectItem.score as AnyObject
            }
        }
        
        output.LemmaTags = lemmatize(phrase.lowercased())
        guard output.LemmaTags.count > 0 else {
            return output
        }
        
        let tokens = tokenize(tokens: output.LemmaTags, wordSource: wordSource)
        guard tokens.count > 0 else {
            return output
        }
        
        for position in 0...tokens.count - 1 {
            let word = tokens[position]
            let itemScore = calculateScore(position: position, word: word, wordSource: wordSource, tokens: tokens)
            
            if itemScore > 0 {
                output.positive.append(word)
            }
            if itemScore < 0 {
                output.negative.append(word)
            }
            output.score += itemScore
        }
        
        output.comparative = tokens.count > 0 ? Double(Double(output.score) / Double(tokens.count)) : 0
        return output
    }
    
}
