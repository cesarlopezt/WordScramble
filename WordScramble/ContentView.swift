//
//  ContentView.swift
//  WordScramble
//
//  Created by Cesar Lopez on 3/11/23.
//

import SwiftUI

struct Score {
    var word: String
    var score: Int
}

struct ScoreSheet: View {
    @Environment(\.dismiss) var dismiss
    var scores = [Score]()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(scores, id: \.word) { score in
                    HStack {
                        /*@START_MENU_TOKEN@*/Text(score.word)/*@END_MENU_TOKEN@*/
                        Spacer()
                        Text(score.score, format: .number)
                    }
                }

            }.navigationTitle("Scores")
            .toolbar {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}


struct ContentView: View {
    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""

    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    @State private var showingScoreSheet = false
    @State private var scores = [Score]()
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Enter your word", text: $newWord)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                Section {
                    ForEach(usedWords, id: \.self) { word in
                        HStack {
                            Image(systemName: "\(word.count).circle")
                            Text(word)
                        }
                    }
                } header: {
                    Text(usedWords.count > 0 ? "My Words - \(usedWords.count)" : "")
                } footer: {
                    Label("Enter all the words that you can imagine that are within the word provided on top.", systemImage: "questionmark.circle")
                }
                
            }
            .navigationTitle(rootWord)
            .onSubmit(addNewWord)
            .onAppear(perform: startGame)
            .alert(errorTitle, isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .toolbar{
                Button("Scores") {
                    showingScoreSheet = true
                }
                Button("New Word", action: restartGame)
            }
            .sheet(isPresented: $showingScoreSheet) {
                ScoreSheet(scores: scores)
            }
        }
    }
    
    func addNewWord() {
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard answer.count >= 3 else {
            wordError(title: "Word too short", message: "The word should be at least 3 letters")
            return
        }
        guard answer != rootWord else {
            wordError(title: "Word is the start word", message: "Be more original")
            return
        }
        guard isOriginal(word: answer) else {
            wordError(title: "Word used already", message: "Be more original")
            return
        }
        guard isPossible(word: answer) else {
            wordError(title: "Word not possible", message: "You can't spell that word from '\(rootWord)'!")
            return
        }
        guard isReal(word: answer) else {
            wordError(title: "Word not recognized", message: "You can't just make them up, you know!")
            return
        }
        
        withAnimation {
            usedWords.insert(answer, at: 0)
        }

        newWord = ""
    }
    
    func startGame() {
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL) {
                let allWords = startWords.components(separatedBy: "\n")
                rootWord = allWords.randomElement() ?? "silkworm"
                return
            }
        }
        fatalError("Could not load start.txt from bundle")
    }
    
    func restartGame() {
        scores.append(Score(word: rootWord, score: usedWords.count))
        startGame()
        usedWords = []
    }
    
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    
    func isPossible(word: String) -> Bool {
        var tempWord = rootWord
        for letter in word {
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                return false
            }
        }
        
        return true
    }
    
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return misspelledRange.location == NSNotFound
    }
    
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
