import Foundation

public struct analysisResult {
    var score: Int
    var comparative: Double
    var words: [String]
    var positive: [String]
    var negative: [String]
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
    static fileprivate func loadWordList(fileName: String) -> Dictionary<NSString, AnyObject>? {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "json") else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
            guard let jsonResult: Dictionary<NSString, AnyObject> = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<NSString, AnyObject> else {
                return Dictionary<NSString, AnyObject>()
            }
            
            return jsonResult
            
        } catch let error as NSError {
            print(error.localizedDescription)
            return nil
        }
    }
}


public struct Sentimently {
    fileprivate var wordSource: Dictionary<NSString, AnyObject>?
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
    
    fileprivate func tokenize(_ phrase: String) -> [String]? {
        var phrase = phrase.lowercased()
        var characterSet = CharacterSet.alphanumerics
        characterSet.insert(charactersIn: " ")
        
        phrase = phrase.components(separatedBy: characterSet.inverted)
            .joined()
        
        return phrase.components(separatedBy: " ")
    }
    
    func calculateScore(position: Int, word: String, wordSource: Dictionary<NSString, AnyObject>, tokens: [String]) -> Int {
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
        
        var output = analysisResult(score: 0, comparative: 0, words: [], positive: [], negative: [])
        
        guard var wordSource = wordSource else {
            return output
        }
        
        guard let tokens = tokenize(phrase) else {
            return output
        }
        
        guard tokens.count > 0 else {
            return output
        }
        
        if addWeights.count > 0  {
            for injectItem in addWeights {
                wordSource[injectItem.word as NSString] = injectItem.score as AnyObject
            }
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
