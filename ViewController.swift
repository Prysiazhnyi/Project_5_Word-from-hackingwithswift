//
//  ViewController.swift
//  Project-5
//
//  Created by Serhii Prysiazhnyi on 27.10.2024.
//

import UIKit

class ViewController: UITableViewController {
    
    var allWords = [String]()
    var usedWords = [String]()
    var gameLanguage = String()
    
    var tempWord = String()
    var tempWordUA = String()
    var tempWordEN = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadScores()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promptForAnswer))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Нове слово", style: .plain, target: self, action: #selector(startGame))
        
        
        if allWords.isEmpty {
            allWords = ["silkworm"]
        }
        
        chooseGameMode()
        
    }
    
    func chooseGameMode() {
        let ac = UIAlertController(title: "Виберіть режим гри", message: nil, preferredStyle: .alert)
        
        let enMode = UIAlertAction(title: "EN", style: .default) { [weak self] _ in
            self?.gameLanguage = "en"
            self?.loadWords(from: "start")
            self?.start()
        }
        
        let uaMode = UIAlertAction(title: "UA", style: .default) { [weak self] _ in
            self?.gameLanguage = "uk"
            self?.loadWords(from: "start_ua")
            self?.start()
            
        }
        
        ac.addAction(enMode)
        ac.addAction(uaMode)
        present(ac, animated: true)
    }
    
    func loadWords(from fileName: String) {
        if let startWordsURL = Bundle.main.url(forResource: fileName, withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL) {
                allWords = startWords.components(separatedBy: "\n")
            }
        }
        
        if allWords.isEmpty {
            allWords = ["silkworm"]
        }
    }
    
    func start() {
 
        if tempWord.isEmpty {
            title = allWords.randomElement()
            usedWords = []
            tempWord = title ?? ""
        } else {
            title = tempWord
        }
        tableView.reloadData()
        print("START  Из загрузки  --- \(title)")
    }
    
    
    @objc func startGame() {
        
        title = allWords.randomElement()
        print("START-GAME Из загрузки  --- \(title)")
        
        usedWords.removeAll(keepingCapacity: true)
        tableView.reloadData()
        tempWord.removeAll()
        saveScores()
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usedWords.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        
        cell.textLabel?.text = usedWords[indexPath.row]
        return cell
        tableView.reloadData()
    }
    @objc func promptForAnswer() {
        let ac = UIAlertController(title: "Введіть відповідь", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Надіслати", style: .default) { [weak self, weak ac] action in
            guard let answer = ac?.textFields?[0].text else { return }
            self?.submit(answer)
        }
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    func submit(_ answer: String) {
        let lowerAnswer = answer.lowercased()
        
        if isPossible(word: lowerAnswer) {
            if isOriginal(word: lowerAnswer) {
                if isReal(word: lowerAnswer) {
                    if notRulles(word: lowerAnswer) {
                        usedWords.insert(answer, at: 0)
                        
                        print(usedWords)
                        saveScores()
                        
                        let indexPath = IndexPath(row: 0, section: 0)
                        tableView.insertRows(at: [indexPath], with: .automatic)
                        return
                        
                    } else {
                        showErrorMessage(errorTitle: "Правила не виконуються", errorMessage: "Ви не можете написати це слово з меше 3 літер або починати з перших 3-х літер")
                    }
                } else {
                    showErrorMessage(errorTitle: "Слово не розпізнано", errorMessage: "Ви не можете просто вигадати їх, знаєте!")
                }
            } else {
                showErrorMessage(errorTitle: "Слово вже використано", errorMessage: "Будь оригінальнішим!")
            }
        } else {
            guard let title = title?.lowercased() else { return }
            showErrorMessage(errorTitle: "Слово неможливо", errorMessage: "Ви не можете написати це слово з \(title)")
        }
    }
    
    func showErrorMessage(errorTitle: String, errorMessage: String) {
        let ac = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        
    }
    
    func isPossible(word: String) -> Bool {
        guard var tempWord = title?.lowercased() else { return false }
        
        for letter in word {
            if let position = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: position)
            } else {
                return false
            }
        }
        return true
    }
    
    func isOriginal(word: String) -> Bool {
        return !usedWords.contains(word)
    }
    
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: gameLanguage)
        
        return misspelledRange.location == NSNotFound
        
    }
    
    func notRulles(word: String) -> Bool {
        guard let tempWord = title?.lowercased() else { return true }
        if word.utf16.count < 3 { return false }
        if word.lowercased().prefix(3) == tempWord.prefix(3) { return false }
        
        return true
    }
    
    func saveScores() {
        let defaults = UserDefaults.standard
        let jsonEncoder = JSONEncoder()
        
        if let savedTempWord = try? jsonEncoder.encode(tempWord),
           let savedUsedWords = try? jsonEncoder.encode(usedWords) {
            defaults.set(savedTempWord, forKey: "tempWord")
            defaults.set(savedUsedWords, forKey: "usedWords")
        }
        print("Cохранение tempWord: \(tempWord), usedWords: \(usedWords)")
    }
    
    func loadScores() {
        let defaults = UserDefaults.standard
        let jsonDecoder = JSONDecoder()
        
        if let savedTempWord = defaults.data(forKey: "tempWord"),
           let savedUsedWords = defaults.data(forKey: "usedWords") {
            tempWord = (try? jsonDecoder.decode(String.self, from: savedTempWord)) ?? "silkworm"
            usedWords = (try? jsonDecoder.decode([String].self, from: savedUsedWords)) ?? []
            
            print("Загрузка tempWord: \(tempWord), usedWords: \(usedWords)")
        }
    }
}
