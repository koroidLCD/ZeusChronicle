//
//  Row.swift
//  Zeus-Chronicles
//
//  Created by John on 12.03.2024.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var game = Game()
    
    var delegate: GameViewController
    
    init(delegate: GameViewController) {
        self.delegate = delegate
    }
    
    var body: some View {
        GeometryReader { geometry in
                VStack() {
                    Spacer(minLength: 10)
                    TitleView(game: game, controller: delegate)
                    TimerView(game: game, geometry: geometry)
                    DashBoardView(game: game)
                    GameGridsView(game: game)
                    Spacer()
                }
                .padding(.horizontal)
                .background(
                        Image("background")
                            .resizable()
                            .edgesIgnoringSafeArea(.all)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    )
        }
    }
}

struct DashBoardView: View {
    
    @ObservedObject var game: Game
    
    var body: some View {
        HStack(spacing: 16) {
            VStack {
                Text("SCORE")
                    .bold()
                    .font(.custom("Victoire", size: 30))
                    .foregroundColor(Color(red: 240/255, green: 224/255, blue: 213/255))
                
                Text("\(game.score)")
                    .bold()
                    .font(.custom("Victoire", size: 30))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background() {
                Image("score")
                            .resizable()
            }
            .cornerRadius(5)
            
            VStack {
                Text("BEST")
                    .bold()
                    .font(.custom("Victoire", size: 30))
                    .foregroundColor(Color(red: 240/255, green: 224/255, blue: 213/255))
                
                Text("\(game.bestScore)")
                    .bold()
                    .font(.custom("Victoire", size: 30))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background() {
                Image("score")
                            .resizable()
            }
            .cornerRadius(5)
        }
    }
}

import Foundation
import SwiftUI

enum GridType { case blank, oval, drop, app, circle, row, column, bomb, gift }

struct Grid {
    var gridType: GridType
    var foregroundColor: Color {
        switch self.gridType {
        case .blank: return .clear
        case .oval: return .orange
        case .drop: return Color(red: 237/255, green: 195/255, blue: 1/255)
        case .app: return .green
        case .circle: return .blue
        case .row: return .red
        case .column: return .red
        case .bomb: return .purple
        case .gift: return Color(red: 152/255, green: 76/255, blue: 11/255)
        }
    }
    var systemName: String {
        switch self.gridType {
        case .blank: return ""
        case .oval: return "symb_Y2"
        case .drop: return "symb_R"
        case .app: return "symb_Y"
        case .circle: return "symb_R2"
        case .row: return "left-right"
        case .column: return "up-down"
        case .bomb: return "bomb"
        case .gift: return "present"
        }
    }
}

import GameKit

class Game: ObservableObject {
    
    @AppStorage("bestScore") var bestScore = 0
    
    @Published var grids = Array(repeating: Grid(gridType: .blank), count: 63)
    @Published var score = 0
    @Published var combo = 0
    @Published var isMatch = false
    @Published var isProcessing = false
    
    @Published var gameTimeLast = 120
    @Published var isPlaying = false
    @Published var isStop = false
    
    private var startDate: Date?
    private var timer: Timer?
    
    func timerStart() {
        isStop = false
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.gameTimeLast -= 1
            if(self.gameTimeLast == 0) {
                self.timer?.invalidate()
                self.timer = nil
                if self.score > self.bestScore {
                        UserDefaults.standard.setValue(self.score, forKey: "thunder")
                    if GKLocalPlayer.local.isAuthenticated {
                        let scoreReporter = GKScore(leaderboardIdentifier: "topBoard")
                        scoreReporter.value = Int64(self.score)
                        
                        let scoreArray: [GKScore] = [scoreReporter]
                        
                        GKScore.report(scoreArray)
                        
                    }
                    self.bestScore = self.score
                    
                }
                self.isPlaying = false
                self.grids = Array(repeating: Grid(gridType: .blank), count: 63)
                self.gameTimeLast = 120
            }
        }
    }
    
    func timerStop() {
        isStop = true
        timer?.invalidate()
        timer = nil
    }
    
    func gameStart() {
        self.score = 0
        self.gameTimeLast = 120
        isPlaying = true
        withAnimation(.linear(duration: 0.4)) {
            (0...62).forEach { index in
                grids[index].gridType = [.oval, .drop, .app, .circle].randomElement()!
                if [2...6, 9...13].joined().contains(index) {
                    while([grids[index-2], grids[index-1]].allSatisfy({ $0.gridType == grids[index].gridType })) {
                        grids[index].gridType = [.oval, .drop, .app, .circle].randomElement()!
                    }
                } else if [stride(from: 14, to: 56, by: 7), stride(from: 15, to: 57, by: 7)].joined().contains(index) {
                    while([grids[index-14], grids[index-7]].allSatisfy({ $0.gridType == grids[index].gridType })) {
                        grids[index].gridType = [.oval, .drop, .app, .circle].randomElement()!
                    }
                } else if ![0, 1, 7, 8].contains(index) {
                    while(
                        [grids[index-2], grids[index-1]].allSatisfy({ $0.gridType == grids[index].gridType })
                        ||
                        [grids[index-14], grids[index-7]].allSatisfy({ $0.gridType == grids[index].gridType })
                    ) {
                        grids[index].gridType = [.oval, .drop, .app, .circle].randomElement()!
                    }
                }
            }
        }
        self.timerStart()
    }
    
    func checkMatch() {
        var checkList = Array(repeating: false, count: 63)
        // check row to generate checkList
        for row in 0...8 {
            for column in 0...4 {
                if [.oval, .drop, .app, .circle].contains(grids[row*7+column].gridType) && [grids[row*7+column+1], grids[row*7+column+2]].allSatisfy({ $0.gridType == grids[row*7+column].gridType }) {
                    (row*7+column...row*7+column+2).forEach { checkList[$0] = true }
                    isMatch = true
                }
            }
        }
        // check column to generate checkList
        for row in 0...6 {
            for column in 0...6 {
                if [.oval, .drop, .app, .circle].contains(grids[row*7+column].gridType) && [grids[row*7+column+7], grids[row*7+column+14]].allSatisfy({ $0.gridType == grids[row*7+column].gridType }) {
                    stride(from: row*7+column, through: row*7+column+14, by: 7).forEach { checkList[$0] = true }
                    isMatch = true
                }
            }
        }
        // check column gift 9
        for column in 0...6 {
            if stride(from: column, through: column+56, by: 7).allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[column].gridType }) {
                stride(from: column, through: column+56, by: 7).forEach { checkList[$0] = false }
                withAnimation(.linear(duration: 0.4)) {
                    stride(from: column, through: column+56, by: 7).forEach { grids[$0].gridType = .blank }
                    grids[column+56].gridType = .gift
                }
                score += 9
                combo += 1
            }
        }
        // check column gift 8
        for row in 0...1 {
            for column in 0...6 {
                if stride(from: row*7+column, through: row*7+column+7*7, by: 7).allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column].gridType }) {
                    stride(from: row*7+column, through: row*7+column+7*7, by: 7).forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        stride(from: row*7+column, through: row*7+column+7*7, by: 7).forEach { grids[$0].gridType = .blank }
                        grids[row*7+column+7*7].gridType = .gift
                    }
                    score += 8
                    combo += 1
                }
            }
        }
        // check column gift 7
        for row in 0...2 {
            for column in 0...6 {
                if stride(from: row*7+column, through: row*7+column+7*6, by: 7).allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column].gridType }) {
                    stride(from: row*7+column, through: row*7+column+7*6, by: 7).forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        stride(from: row*7+column, through: row*7+column+7*6, by: 7).forEach { grids[$0].gridType = .blank }
                        grids[row*7+column+7*6].gridType = .gift
                    }
                    score += 7
                    combo += 1
                }
            }
        }
        // check row gift 7
        for row in 0...8 {
            if (row*7...row*7+6).allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7].gridType }) {
                (row*7...row*7+6).forEach { checkList[$0] = false }
                withAnimation(.linear(duration: 0.4)) {
                    (row*7...row*7+6).forEach { grids[$0].gridType = .blank }
                    grids[row*7+3].gridType = .gift
                }
                score += 7
                combo += 1
            }
        }
        // check column gift 6
        for row in 0...3 {
            for column in 0...6 {
                if stride(from: row*7+column, through: row*7+column+7*5, by: 7).allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column].gridType }) {
                    stride(from: row*7+column, through: row*7+column+7*5, by: 7).forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        stride(from: row*7+column, through: row*7+column+7*5, by: 7).forEach { grids[$0].gridType = .blank }
                        grids[row*7+column+7*5].gridType = .gift
                    }
                    score += 6
                    combo += 1
                }
            }
        }
        // check row gift 6
        for row in 0...8 {
            for column in 0...1 {
                if (row*7+column...row*7+column+5).allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column].gridType }) {
                    (row*7+column...row*7+column+5).forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        (row*7+column...row*7+column+5).forEach { grids[$0].gridType = .blank }
                        grids[row*7+column+2].gridType = .gift
                    }
                    score += 6
                    combo += 1
                }
            }
        }
        // check column gift 5
        for row in 0...4 {
            for column in 0...6 {
                if stride(from: row*7+column, through: row*7+column+7*4, by: 7).allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column].gridType }) {
                    stride(from: row*7+column, through: row*7+column+7*4, by: 7).forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        stride(from: row*7+column, through: row*7+column+7*4, by: 7).forEach { grids[$0].gridType = .blank }
                        grids[row*7+column+7*4].gridType = .gift
                    }
                    score += 5
                    combo += 1
                }
            }
        }
        // check row gift 5
        for row in 0...8 {
            for column in 0...2 {
                if (row*7+column...row*7+column+4).allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column].gridType }) {
                    (row*7+column...row*7+column+4).forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        (row*7+column...row*7+column+4).forEach { grids[$0].gridType = .blank }
                        grids[row*7+column+2].gridType = .gift
                    }
                    score += 5
                    combo += 1
                }
            }
        }
        // check bomb
        for row in 1...7 {
            for column in 1...5 {
                if [row*7+column-7, row*7+column-1, row*7+column, row*7+column+1, row*7+column+7].allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column-7].gridType }) {
                    [row*7+column-7, row*7+column-1, row*7+column, row*7+column+1, row*7+column+7].forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        [row*7+column-7, row*7+column-1, row*7+column+1, row*7+column+7].forEach { grids[$0].gridType = .blank }
                        grids[row*7+column].gridType = .bomb
                    }
                    score += 5
                    combo += 1
                } else if [row*7+column-8, row*7+column-1, row*7+column+6, row*7+column+7, row*7+column+8].allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column-8].gridType }) {
                    [row*7+column-8, row*7+column-1, row*7+column+6, row*7+column+7, row*7+column+8].forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        [row*7+column-8, row*7+column-1, row*7+column+6, row*7+column+7, row*7+column+8].forEach { grids[$0].gridType = .blank }
                        grids[row*7+column+6].gridType = .bomb
                    }
                    score += 5
                    combo += 1
                } else if [row*7+column-8, row*7+column-7, row*7+column-6, row*7+column-1, row*7+column+6].allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column-8].gridType }) {
                    [row*7+column-8, row*7+column-7, row*7+column-6, row*7+column-1, row*7+column+6].forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        [row*7+column-8, row*7+column-7, row*7+column-6, row*7+column-1, row*7+column+6].forEach { grids[$0].gridType = .blank }
                        grids[row*7+column-8].gridType = .bomb
                    }
                    score += 5
                    combo += 1
                } else if [row*7+column-8, row*7+column-7, row*7+column-6, row*7+column+1, row*7+column+8].allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column-8].gridType }) {
                    [row*7+column-8, row*7+column-7, row*7+column-6, row*7+column+1, row*7+column+8].forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        [row*7+column-8, row*7+column-7, row*7+column-6, row*7+column+1, row*7+column+8].forEach { grids[$0].gridType = .blank }
                        grids[row*7+column-6].gridType = .bomb
                    }
                    score += 5
                    combo += 1
                } else if [row*7+column-6, row*7+column+1, row*7+column+6, row*7+column+7, row*7+column+8].allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column-6].gridType }) {
                    [row*7+column-6, row*7+column+1, row*7+column+6, row*7+column+7, row*7+column+8].forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        [row*7+column-6, row*7+column+1, row*7+column+6, row*7+column+7, row*7+column+8].forEach { grids[$0].gridType = .blank }
                        grids[row*7+column+8].gridType = .bomb
                    }
                    score += 5
                    combo += 1
                } else if [row*7+column-7, row*7+column, row*7+column+6, row*7+column+7, row*7+column+8].allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column-7].gridType }) {
                    [row*7+column-7, row*7+column, row*7+column+6, row*7+column+7, row*7+column+8].forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        [row*7+column-7, row*7+column, row*7+column+6, row*7+column+7, row*7+column+8].forEach { grids[$0].gridType = .blank }
                        grids[row*7+column+7].gridType = .bomb
                    }
                    score += 5
                    combo += 1
                } else if [row*7+column-8, row*7+column-1, row*7+column, row*7+column+1, row*7+column+6].allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column-8].gridType }) {
                    [row*7+column-8, row*7+column-1, row*7+column, row*7+column+1, row*7+column+6].forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        [row*7+column-8, row*7+column-1, row*7+column, row*7+column+1, row*7+column+6].forEach { grids[$0].gridType = .blank }
                        grids[row*7+column-1].gridType = .bomb
                    }
                    score += 5
                    combo += 1
                } else if [row*7+column-8, row*7+column-7, row*7+column-6, row*7+column, row*7+column+7].allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column-8].gridType }) {
                    [row*7+column-8, row*7+column-7, row*7+column-6, row*7+column, row*7+column+7].forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        [row*7+column-8, row*7+column-7, row*7+column-6, row*7+column, row*7+column+7].forEach { grids[$0].gridType = .blank }
                        grids[row*7+column-7].gridType = .bomb
                    }
                    score += 5
                    combo += 1
                } else if [row*7+column-6, row*7+column-1, row*7+column, row*7+column+1, row*7+column+8].allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column-6].gridType }) {
                    [row*7+column-6, row*7+column-1, row*7+column, row*7+column+1, row*7+column+8].forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        [row*7+column-6, row*7+column-1, row*7+column, row*7+column+1, row*7+column+8].forEach { grids[$0].gridType = .blank }
                        grids[row*7+column+1].gridType = .bomb
                    }
                    score += 5
                    combo += 1
                }
            }
        }
        // check row 4
        for row in 0...8 {
            for column in 0...3 {
                if (row*7+column...row*7+column+3).allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column].gridType }) {
                    (row*7+column...row*7+column+3).forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        (row*7+column...row*7+column+3).forEach { grids[$0].gridType = .blank }
                        grids[row*7+column+1].gridType = .row
                    }
                    score += 4
                    combo += 1
                }
            }
        }
        // check column 4
        for row in 0...5 {
            for column in 0...6 {
                if stride(from: row*7+column, through: row*7+column+7*3, by: 7).allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column].gridType }) {
                    stride(from: row*7+column, through: row*7+column+7*3, by: 7).forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        stride(from: row*7+column, through: row*7+column+7*3, by: 7).forEach { grids[$0].gridType = .blank }
                        grids[row*7+column+7*3].gridType = .column
                    }
                    score += 4
                    combo += 1
                }
            }
        }
        // check row 3
        for row in 0...8 {
            for column in 0...4 {
                if (row*7+column...row*7+column+2).allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column].gridType }) {
                    (row*7+column...row*7+column+2).forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        (row*7+column...row*7+column+2).forEach { grids[$0].gridType = .blank }
                    }
                    score += 3
                    combo += 1
                }
            }
        }
        // check column 3
        for row in 0...6 {
            for column in 0...6 {
                if stride(from: row*7+column, through: row*7+column+7*2, by: 7).allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column].gridType }) {
                    stride(from: row*7+column, through: row*7+column+7*2, by: 7).forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        stride(from: row*7+column, through: row*7+column+7*2, by: 7).forEach { grids[$0].gridType = .blank }
                    }
                    score += 3
                    combo += 1
                }
            }
        }
        // clear
        (0...62).forEach { index in
            if checkList[index] == true {
                withAnimation(.linear(duration: 0.4)) {
                    grids[index].gridType = .blank
                }
                score += 1
            }
        }
        if isMatch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.fallDown()
            }
        } else {
            combo = 0
            if self.checkDead() {
                grids.shuffle()
                self.fallDown()
            } else {
                isProcessing = false
            }
        }
    }
    
    func fallDown() {
        while grids.contains(where: { $0.gridType == .blank }) {
            (0...62).forEach { index in
                if grids[index].gridType == .blank {
                    if (0...6).contains(index) {
                        grids[index].gridType = [.oval, .drop, .app, .circle].randomElement()!
                    } else {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            grids.swapAt(index, index-7)
                        }
                    }
                }
            }
        }
        isMatch = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.checkMatch()
        }
    }
    
    func clearAll() {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids = Array(repeating: Grid(gridType: .blank), count: 63)
        }
        score += 63
        combo += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fallDown()
        }
    }
    
    func manyBomb(first: Int, second: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[first].gridType = .blank
            grids[second].gridType = .blank
        }
        score += 2
        combo += 1
        let randomGridType: GridType = [.oval, .drop, .app, .circle].randomElement()!
        (0...62).forEach { index in
            if grids[index].gridType == randomGridType {
                withAnimation(.easeInOut(duration: 0.4)) {
                    grids[index].gridType = .bomb
                }
            }
        }
        (0...62).forEach { index in
            if grids[index].gridType == .bomb {
                self.bomb(index: index)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fallDown()
        }
    }
    
    func manyRow(first: Int, second: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[first].gridType = .blank
            grids[second].gridType = .blank
        }
        score += 2
        combo += 1
        let randomGridType: GridType = [.oval, .drop, .app, .circle].randomElement()!
        (0...62).forEach { index in
            if grids[index].gridType == randomGridType {
                withAnimation(.easeInOut(duration: 0.4)) {
                    grids[index].gridType = .row
                }
            }
        }
        (0...62).forEach { index in
            if grids[index].gridType == .row {
                self.row(index: index)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fallDown()
        }
    }
    
    func manyColumn(first: Int, second: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[first].gridType = .blank
            grids[second].gridType = .blank
        }
        score += 2
        combo += 1
        let randomGridType: GridType = [.oval, .drop, .app, .circle].randomElement()!
        (0...62).forEach { index in
            if grids[index].gridType == randomGridType {
                withAnimation(.easeInOut(duration: 0.4)) {
                    grids[index].gridType = .column
                }
            }
        }
        (0...62).forEach { index in
            if grids[index].gridType == .column {
                self.column(index: index)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fallDown()
        }
    }
    
    func bigBomb(first: Int, second: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[first].gridType = .blank
            grids[second].gridType = .blank
        }
        score += 2
        combo += 1
        self.bomb(index: first)
        self.bomb(index: second)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fallDown()
        }
    }
    
    func bigCross(first: Int, second: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[first].gridType = .blank
            grids[second].gridType = .blank
        }
        score += 2
        combo += 1
        if second == 0 {
            self.row(index: 0)
            self.row(index: 7)
            self.column(index: 0)
            self.column(index: 1)
        } else if second == 6 {
            self.row(index: 0)
            self.row(index: 7)
            self.column(index: 5)
            self.column(index: 6)
        } else if second == 56 {
            self.row(index: 49)
            self.row(index: 56)
            self.column(index: 0)
            self.column(index: 1)
        } else if second == 62 {
            self.row(index: 49)
            self.row(index: 56)
            self.column(index: 5)
            self.column(index: 6)
        } else if (1...5).contains(second) {
            self.row(index: 0)
            self.row(index: 7)
            self.column(index: second-1)
            self.column(index: second)
            self.column(index: second+1)
        } else if stride(from: 7, through: 49, by: 7).contains(second) {
            self.row(index: second-7)
            self.row(index: second)
            self.row(index: second+7)
            self.column(index: 0)
            self.column(index: 1)
        } else if stride(from: 13, through: 55, by: 7).contains(second) {
            self.row(index: second-7)
            self.row(index: second)
            self.row(index: second+7)
            self.column(index: 5)
            self.column(index: 5)
        } else if (57...61).contains(second) {
            self.row(index: 49)
            self.row(index: 56)
            self.column(index: second-1)
            self.column(index: second)
            self.column(index: second+1)
        } else {
            self.row(index: second-7)
            self.row(index: second)
            self.row(index: second+7)
            self.column(index: second-1)
            self.column(index: second)
            self.column(index: second+1)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fallDown()
        }
    }
    
    func cross(first: Int, second: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[first].gridType = .blank
            grids[second].gridType = .blank
        }
        score += 2
        combo += 1
        self.row(index: second)
        self.column(index: second)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fallDown()
        }
    }
    
    func gift(gridType: GridType, index: Int) {
        isMatch = true
        grids[index].gridType = .blank
        score += 1
        (0...62).forEach { idx in
            if grids[idx].gridType == gridType {
                withAnimation(.easeInOut(duration: 0.4)) {
                    grids[idx].gridType = .blank
                }
                score += 1
            }
        }
        combo += 1
    }
    
    func bomb(index: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[index].gridType = .blank
        }
        score += 1
        if index == 0 {
            [1, 7, 8].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        } else if index == 6 {
            [5, 12, 13].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        } else if index == 56 {
            [49, 50, 57].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        } else if index == 62 {
            [54, 55, 61].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        } else if (1...5).contains(index) {
            [index-1, index+1, index+6, index+7, index+8].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        } else if stride(from: 7, through: 49, by: 7).contains(index) {
            [index-7, index-6, index+1, index+7, index+8].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        } else if stride(from: 13, through: 55, by: 7).contains(index) {
            [index-8, index-7, index-1, index+6, index+7].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        } else if (57...61).contains(index) {
            [index-8, index-7, index-6, index-1, index+1].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        } else {
            [index-8, index-7, index-6, index-1, index+1, index+6, index+7, index+8].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        }
        combo += 1
    }
    
    func row(index: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[index].gridType = .blank
        }
        score += 1
        (7*(index/7)...7*(index/7)+6).forEach { idx in
            switch grids[idx].gridType {
            case .blank:
                break;
            case .column:
                self.column(index: idx)
            case .bomb:
                self.bomb(index: idx)
            case .gift:
                self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
            default:
                withAnimation(.easeInOut(duration: 0.4)) {
                    grids[idx].gridType = .blank
                }
                score += 1
            }
        }
        combo += 1
    }
    
    func column(index: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[index].gridType = .blank
        }
        score += 1
        stride(from: index%7, through: index%7+7*8, by: 7).forEach { idx in
            switch grids[idx].gridType {
            case .blank:
                break;
            case .row:
                self.row(index: idx)
            case .bomb:
                self.bomb(index: idx)
            case .gift:
                self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
            default:
                withAnimation(.easeInOut(duration: 0.4)) {
                    grids[idx].gridType = .blank
                }
                score += 1
            }
        }
        combo += 1
    }
    
    func checkDead() -> Bool {
        if grids.contains(where: { [.row, .column, .bomb, .gift].contains($0.gridType) }) {
            return false
        }
        var testGrids = grids
        for index in 0...62 {
            if !stride(from: 6, through: 62, by: 7).contains(index) {
                testGrids.swapAt(index, index+1)
                for row in 0...8 {
                    for column in 0...4 {
                        if [.oval, .drop, .app, .circle].contains(testGrids[row*7+column].gridType) && [testGrids[row*7+column+1], testGrids[row*7+column+2]].allSatisfy({ $0.gridType == testGrids[row*7+column].gridType }) {
                            return false
                        }
                    }
                }
                // check column to generate checkList
                for row in 0...6 {
                    for column in 0...6 {
                        if [.oval, .drop, .app, .circle].contains(testGrids[row*7+column].gridType) && [testGrids[row*7+column+7], testGrids[row*7+column+14]].allSatisfy({ $0.gridType == testGrids[row*7+column].gridType }) {
                            return false
                        }
                    }
                }
                testGrids.swapAt(index, index+1)
            }
        }
        // test column
        for index in 0...62 {
            if !(56...62).contains(index) {
                testGrids.swapAt(index, index+7)
                // check row to generate checkList
                for row in 0...8 {
                    for column in 0...4 {
                        if [.oval, .drop, .app, .circle].contains(testGrids[row*7+column].gridType) && [testGrids[row*7+column+1], testGrids[row*7+column+2]].allSatisfy({ $0.gridType == testGrids[row*7+column].gridType }) {
                            return false
                        }
                    }
                }
                // check column to generate checkList
                for row in 0...6 {
                    for column in 0...6 {
                        if [.oval, .drop, .app, .circle].contains(testGrids[row*7+column].gridType) && [testGrids[row*7+column+7], testGrids[row*7+column+14]].allSatisfy({ $0.gridType == testGrids[row*7+column].gridType }) {
                            return false
                        }
                    }
                }
                testGrids.swapAt(index, index+7)
            }
        }
        return true
    }
}

struct GameGridsView: View {
    
    @ObservedObject var game: Game
    
    @State private var startDetectDrag = false
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(spacing: 4), count: 7), spacing: 4) {
            ForEach(0..<63) { index in
                GeometryReader { geo in
                    Rectangle()
                        .frame(width: nil, height: geo.size.width)
                        .foregroundColor(.clear)
                        .cornerRadius(8)
                        .overlay {
                            if game.grids[index].gridType != .blank && !game.isStop {
                                Image( "\(game.grids[index].systemName)")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(8)
                                    .gesture(dragGesture(index: index))
                            }
                        }
                        .background() {
                            Image("btn_1")
                                        .resizable()
                        }
                }
                .aspectRatio(contentMode: .fit)
            }
        }
        .padding(12)
        .background() {
            Image("score")
            .resizable()
        }
        .cornerRadius(5)
        .overlay {
            if !game.isPlaying {
                Button {
                    game.gameStart()
                } label: {
                    Text("Game Start")
                        .bold()
                        .font(.custom("Victoire", size: 30))
                        .padding()
                        .foregroundColor(.white)
                        .background() {
                            Image("y_button")
                                        .resizable()
                        }
                        .cornerRadius(5)
                }
            }
            if game.isStop {
                VStack(spacing: 15) {
                    Button {
                        game.timerStart()
                    } label: {
                        (Text(Image(systemName: "arrowtriangle.right.circle")) + Text("  Continue"))
                            .bold()
                            .font(.custom("Victoire", size: 30))
                            .padding()
                            .foregroundColor(.white)
                            .background() {
                                Image("y_button")
                                            .resizable()
                            }
                            .cornerRadius(5)
                    }
                    Button {
                        game.gameStart()
                    } label: {
                        (Text(Image(systemName: "arrow.counterclockwise.circle")) + Text("  Restart"))
                            .bold()
                            .font(.custom("Victoire", size: 30))
                            .padding()
                            .foregroundColor(.white)
                            .background() {
                                Image("y_button")
                                            .resizable()
                            }
                            .cornerRadius(5)
                    }
                }
            }
        }
    }
    
    func dragGesture(index: Int) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if startDetectDrag && !game.isProcessing && game.isPlaying && !game.isStop {
                    if value.translation.width > 5 { // swipe right
                        if !stride(from: 6, through: 62, by: 7).contains(index) {
                            game.isMatch = false
                            game.isProcessing = true
                            withAnimation(.linear(duration: 0.4)) {
                                game.grids.swapAt(index, index+1)
                            }
                            let left = game.grids[index].gridType, right = game.grids[index+1].gridType
                            if [left, right].allSatisfy({ $0 == .gift }) {
                                game.clearAll()
                            } else if left == .gift && right == .bomb || left == .bomb && right == .gift {
                                game.manyBomb(first: index, second: index+1)
                            } else if left == .gift && right == .row || left == .row && right == .gift {
                                game.manyRow(first: index, second: index+1)
                            } else if left == .gift && right == .column || left == .column && right == .gift {
                                game.manyColumn(first: index, second: index+1)
                            } else if [left, right].allSatisfy({ $0 == .bomb }) {
                                game.bigBomb(first: index, second: index+1)
                            } else if [.row, .column].contains(left) && right == .bomb || left == .bomb && [.row, .column].contains(right) {
                                game.bigCross(first: index, second: index+1)
                            } else if [.row, .column].contains(left) && [.row, .column].contains(right) {
                                game.cross(first: index, second: index+1)
                            } else if left == .gift {
                                game.gift(gridType: right, index: index)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if right == .gift {
                                game.gift(gridType: left, index: index+1)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if left == .bomb {
                                game.bomb(index: index)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if right == .bomb {
                                game.bomb(index: index+1)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if left == .row {
                                game.row(index: index)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if right == .row {
                                game.row(index: index+1)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if left == .column {
                                game.column(index: index)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if right == .column {
                                game.column(index: index+1)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else {
                                game.checkMatch()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if !game.isMatch {
                                    withAnimation(.linear(duration: 0.4)) {
                                        game.grids.swapAt(index, index+1)
                                    }
                                }
                            }
                        }
                        startDetectDrag = false
                    } else if value.translation.width < -5 { // swipe left
                        if !stride(from: 0, through: 56, by: 7).contains(index) {
                            game.isMatch = false
                            game.isProcessing = true
                            withAnimation(.easeInOut(duration: 0.4)) {
                                game.grids.swapAt(index, index-1)
                            }
                            let left = game.grids[index-1].gridType, right = game.grids[index].gridType
                            if [left, right].allSatisfy({ $0 == .gift }) {
                                game.clearAll()
                            } else if left == .gift && right == .bomb || left == .bomb && right == .gift {
                                game.manyBomb(first: index, second: index-1)
                            } else if left == .gift && right == .row || left == .row && right == .gift {
                                game.manyRow(first: index, second: index-1)
                            } else if left == .gift && right == .column || left == .column && right == .gift {
                                game.manyColumn(first: index, second: index-1)
                            } else if [left, right].allSatisfy({ $0 == .bomb }) {
                                game.bigBomb(first: index, second: index-1)
                            } else if [.row, .column].contains(left) && right == .bomb || left == .bomb && [.row, .column].contains(right) {
                                game.bigCross(first: index, second: index-1)
                            } else if [.row, .column].contains(left) && [.row, .column].contains(right) {
                                game.cross(first: index, second: index-1)
                            } else if left == .gift {
                                game.gift(gridType: right, index: index-1)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if right == .gift {
                                game.gift(gridType: left, index: index)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if left == .bomb {
                                game.bomb(index: index-1)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if right == .bomb {
                                game.bomb(index: index)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if left == .row {
                                game.row(index: index-1)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if right == .row {
                                game.row(index: index)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if left == .column {
                                game.column(index: index-1)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if right == .column {
                                game.column(index: index)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else {
                                game.checkMatch()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if !game.isMatch {
                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        game.grids.swapAt(index, index-1)
                                    }
                                }
                            }
                        }
                        startDetectDrag = false
                    } else if value.translation.height < -5 { // swipe up
                        if (7...62).contains(index) {
                            game.isMatch = false
                            game.isProcessing = true
                            withAnimation(.easeInOut(duration: 0.4)) {
                                game.grids.swapAt(index, index-7)
                            }
                            let down = game.grids[index].gridType, up = game.grids[index-7].gridType
                            if [down, up].allSatisfy({ $0 == .gift }) {
                                game.clearAll()
                            } else if down == .gift && up == .bomb || down == .bomb && up == .gift {
                                game.manyBomb(first: index, second: index-7)
                            } else if down == .gift && up == .row || down == .row && up == .gift {
                                game.manyRow(first: index, second: index-7)
                            } else if down == .gift && up == .column || down == .column && up == .gift {
                                game.manyColumn(first: index, second: index-7)
                            } else if [down, up].allSatisfy({ $0 == .bomb }) {
                                game.bigBomb(first: index, second: index-7)
                            } else if [.row, .column].contains(down) && up == .bomb || down == .bomb && [.row, .column].contains(up) {
                                game.bigCross(first: index, second: index-7)
                            } else if [.row, .column].contains(down) && [.row, .column].contains(up) {
                                game.cross(first: index, second: index-7)
                            } else if up == .gift {
                                game.gift(gridType: down, index: index-7)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if down == .gift {
                                game.gift(gridType: up, index: index)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if down == .bomb {
                                game.bomb(index: index)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if up == .bomb {
                                game.bomb(index: index-7)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if down == .row {
                                game.row(index: index)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if up == .row {
                                game.row(index: index-7)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if down == .column {
                                game.column(index: index)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else if up == .column {
                                game.column(index: index-7)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    game.fallDown()
                                }
                            } else {
                                game.checkMatch()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if !game.isMatch {
                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        game.grids.swapAt(index, index-7)
                                    }
                                }
                            }
                        }
                        startDetectDrag = false
                    } else if value.translation.height > 5 { // swipe down
                        if (0...55).contains(index) {
                            game.isMatch = false
                            game.isProcessing = true
                            withAnimation(.easeInOut(duration: 0.4)) {
                                game.grids.swapAt(index, index+7)
                            }
                            let down = game.grids[index+7].gridType, up = game.grids[index].gridType
                            if [down, up].allSatisfy({ $0 == .gift }) {
                                game.clearAll()
                            } else if down == .gift && up == .bomb || down == .bomb && up == .gift {
                                game.manyBomb(first: index, second: index+7)
                            } else if down == .gift && up == .row || down == .row && up == .gift {
                                game.manyRow(first: index, second: index+7)
                            } else if down == .gift && up == .column || down == .column && up == .gift {
                                game.manyColumn(first: index, second: index+7)
                            } else if [down, up].allSatisfy({ $0 == .bomb }) {
                                game.bigBomb(first: index, second: index+7)
                            } else if [.row, .column].contains(down) && up == .bomb || down == .bomb && [.row, .column].contains(up) {
                                game.bigCross(first: index, second: index+7)
                            } else if [.row, .column].contains(down) && [.row, .column].contains(up) {
                                game.cross(first: index, second: index+7)
                            } else if up == .gift {
                                game.gift(gridType: down, index: index)
                                game.fallDown()
                            } else if down == .gift {
                                game.gift(gridType: up, index: index+7)
                                game.fallDown()
                            } else if down == .bomb {
                                game.bomb(index: index+7)
                                game.fallDown()
                            } else if up == .bomb {
                                game.bomb(index: index)
                                game.fallDown()
                            } else if down == .row {
                                game.row(index: index+7)
                                game.fallDown()
                            } else if up == .row {
                                game.row(index: index)
                                game.fallDown()
                            } else if down == .column {
                                game.column(index: index+7)
                                game.fallDown()
                            } else if up == .column {
                                game.column(index: index)
                                game.fallDown()
                            } else {
                                game.checkMatch()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if !game.isMatch {
                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        game.grids.swapAt(index, index+7)
                                    }
                                }
                            }
                        }
                        startDetectDrag = false
                    }
                } else {
                    if value.translation == .zero {
                        startDetectDrag = true
                    }
                }
            }
    }
}

struct TimerView: View {
    
    @ObservedObject var game: Game
    
    var geometry: GeometryProxy
    
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .frame(height: 40)
                .foregroundColor(.clear)
                .background() {
                    Image("btn_3")
                                .resizable()
                }
            
            Capsule()
                .frame(width: (geometry.size.width-32)*CGFloat(Double(game.gameTimeLast)/120.0), height: 40)
                .background() {
                    Image("btn_2")
                                .resizable()
                }
                .foregroundColor(.clear)
                .overlay(alignment: .trailing) {
                    if game.gameTimeLast > 15 {
                        Text("\(game.gameTimeLast)")
                            .bold()
                            .font(.custom("Victoire", size: 30))
                            .foregroundColor(.white)
                            .padding(.trailing, 8)
                    }
                }
        }
        .overlay(alignment: .leading) {
            if game.gameTimeLast <= 15 {
                Text("\(game.gameTimeLast)")
                    .bold()
                    .font(.custom("Victoire", size: 30))
                    .foregroundColor(Color(red: 120/255, green: 111/255, blue: 102/255))
                    .padding(.leading, 8)
            }
        }
    }
}

struct TitleView: View {
    
    @ObservedObject var game: Game
    var controller: GameViewController
    
    var body: some View {
        HStack(spacing: 8) {
            Button {
                controller.dismiss(animated: true)
            } label: {
                Image("btn_back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color(red: 236/255, green: 140/255, blue: 85/255))
            }
            
            Spacer()
            
            Text("Thunder Game")
                .bold()
                .font(.custom("Victoire", size: 30))
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                if game.isPlaying {
                    game.timerStop()
                }
            } label: {
                Image("pause")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color(red: 236/255, green: 140/255, blue: 85/255))
            }
        }
    }
}
