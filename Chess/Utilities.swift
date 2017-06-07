//
//  HelperFunctions.swift
//  Chess
//
//  Created by Jože Ws on 10/2/15.
//  Copyright © 2015 Self. All rights reserved.
//

import Foundation
import UIKit

//////////************

func == (sq1: Square, sq2: Square) -> Bool {
    return sq1.hashValue==sq2.hashValue
}

func != (sq1: Square, sq2: Square) -> Bool {
    return !(sq1.hashValue==sq2.hashValue)
}

func == (p1: Piece, p2: Piece) -> Bool {
    return p1.hashValue==p2.hashValue
}

func != (p1: Piece, p2: Piece) -> Bool {
    return !(p1.hashValue==p2.hashValue)
}

func oppositeColor(_ color: PieceColor) -> PieceColor {
    return color==PieceColor.light ? PieceColor.dark : PieceColor.light
}

func squareIsInBounds(_ sq: Square) -> Bool {
    return sq.file>=0 && sq.file<=7 && sq.rank>=0 && sq.rank<=7
}

func gradientFromFileDelta(_ fileDelta: Int, rankDelta: Int) -> (file: Int, rank: Int) {
    if fileDelta != 0 && rankDelta != 0 {
        let gdc = greatestCommonDivisor(fileDelta, b: rankDelta)
        return (fileDelta/abs(gdc), rankDelta/abs(gdc))
    }
    else if fileDelta == 0 {
        if rankDelta>0 {
            return (0,1)
        }
        if rankDelta<0 {
            return (0,-1)
        }
    }
    else if rankDelta == 0 {
        if fileDelta>0 {
            return (1,0)
        }
        if fileDelta<0 {
            return (-1,0)
        }
    }
    return (0,0)
}

func standardPieceSet() -> [Piece] {
    
    var pieces = [Piece]()
    
    pieces.append(Piece(initial: Square(file: 0, rank: 0), color: .light, type: .rook))
    pieces.append(Piece(initial: Square(file: 1, rank: 0), color: .light, type: .knight))
    pieces.append(Piece(initial: Square(file: 2, rank: 0), color: .light, type: .bishop))
    pieces.append(Piece(initial: Square(file: 3, rank: 0), color: .light, type: .queen))
    pieces.append(Piece(initial: Square(file: 4, rank: 0), color: .light, type: .king))
    pieces.append(Piece(initial: Square(file: 5, rank: 0), color: .light, type: .bishop))
    pieces.append(Piece(initial: Square(file: 6, rank: 0), color: .light, type: .knight))
    pieces.append(Piece(initial: Square(file: 7, rank: 0), color: .light, type: .rook))
    
    pieces.append(Piece(initial: Square(file: 0, rank: 1), color: .light, type: .pawn))
    pieces.append(Piece(initial: Square(file: 1, rank: 1), color: .light, type: .pawn))
    pieces.append(Piece(initial: Square(file: 2, rank: 1), color: .light, type: .pawn))
    pieces.append(Piece(initial: Square(file: 3, rank: 1), color: .light, type: .pawn))
    pieces.append(Piece(initial: Square(file: 4, rank: 1), color: .light, type: .pawn))
    pieces.append(Piece(initial: Square(file: 5, rank: 1), color: .light, type: .pawn))
    pieces.append(Piece(initial: Square(file: 6, rank: 1), color: .light, type: .pawn))
    pieces.append(Piece(initial: Square(file: 7, rank: 1), color: .light, type: .pawn))
    
    pieces.append(Piece(initial: Square(file: 0, rank: 7), color: .dark, type: .rook))
    pieces.append(Piece(initial: Square(file: 1, rank: 7), color: .dark, type: .knight))
    pieces.append(Piece(initial: Square(file: 2, rank: 7), color: .dark, type: .bishop))
    pieces.append(Piece(initial: Square(file: 3, rank: 7), color: .dark, type: .queen))
    pieces.append(Piece(initial: Square(file: 4, rank: 7), color: .dark, type: .king))
    pieces.append(Piece(initial: Square(file: 5, rank: 7), color: .dark, type: .bishop))
    pieces.append(Piece(initial: Square(file: 6, rank: 7), color: .dark, type: .knight))
    pieces.append(Piece(initial: Square(file: 7, rank: 7), color: .dark, type: .rook))
    
    pieces.append(Piece(initial: Square(file: 0, rank: 6), color: .dark, type: .pawn))
    pieces.append(Piece(initial: Square(file: 1, rank: 6), color: .dark, type: .pawn))
    pieces.append(Piece(initial: Square(file: 2, rank: 6), color: .dark, type: .pawn))
    pieces.append(Piece(initial: Square(file: 3, rank: 6), color: .dark, type: .pawn))
    pieces.append(Piece(initial: Square(file: 4, rank: 6), color: .dark, type: .pawn))
    pieces.append(Piece(initial: Square(file: 5, rank: 6), color: .dark, type: .pawn))
    pieces.append(Piece(initial: Square(file: 6, rank: 6), color: .dark, type: .pawn))
    pieces.append(Piece(initial: Square(file: 7, rank: 6), color: .dark, type: .pawn))
    
    return pieces
}


func labelForPiece(_ piece: Piece, squareSize sqSize: CGFloat) -> UILabel {
    
    let pieceView = UILabel(frame: CGRect(x: 0, y: 0, width: sqSize, height: sqSize))
    pieceView.textAlignment = NSTextAlignment.center
    pieceView.font = UIFont(name: "Arial", size: 50)
    pieceView.textColor = (piece.color == .light) ? UIColor.lightGray : UIColor.black
    
    switch piece.type {
    case.king:
        pieceView.text = "K"
    case.queen:
        pieceView.text = "Q"
    case.rook:
        pieceView.text = "R"
    case.bishop:
        pieceView.text = "B"
    case.knight:
        pieceView.text = "Kn"
    case.pawn:
        pieceView.text = "P"
    }
    return pieceView
}

func imageNameForPieceType(_ type: PieceType, pieceColor color: PieceColor) -> String {
    
    var name = String()
    name += color == .dark ? "Dark" : "Light"
    
    switch type {
    case .king:
        name += "King"
    case .queen:
        name += "Queen"
    case .rook:
        name += "Rook"
    case .bishop:
        name += "Bishop"
    case .knight:
        name += "Knight"
    case .pawn:
        name += "Pawn"
    }
    
    name += ".png"
    return name
}

func darkUIColor() -> UIColor {
    return UIColor(red: 115/255, green: 160/255, blue: 200/255, alpha: 1.0)
}

func checkUIColor() -> UIColor {
    return UIColor(red: 255/255, green: 190/255, blue: 190/255, alpha: 0.90)
}

func moveUIColor() -> UIColor {
    return UIColor(red: 122.5/255, green: 122.5/255, blue: 255/255, alpha: 0.90)
}

func sq01UIColor() -> UIColor {
    return UIColor(red: 190/255, green: 190/255, blue: 255/255, alpha: 0.90)
}

func sq1HighUIColor() -> UIColor {
    return UIColor(red: 190/255, green: 190/255, blue: 255/255, alpha: 0.80)
}

func frameUIColor() -> UIColor {
    return UIColor(red: 115/255, green: 160/255, blue: 200/255, alpha: 0.90)
}

func textUIColor() -> UIColor {
    return UIColor(red: 50/255, green: 115/255, blue: 170/255, alpha: 1.0)
}

func randomPieceColor() -> PieceColor {
    return (Int(arc4random_uniform(2)) % 2 == 1) ? PieceColor.light : PieceColor.dark
}

func timeStringFromSeconds(_ seconds: Double) -> String {
    if seconds != -1000 {
        return String.localizedStringWithFormat("%d:%02d", Int(seconds)/60, Int(seconds)%60)
    }
    return "Ad Inf"
}

extension Array {
    func contains<T>(_ obj: T) -> Bool where T : Equatable {
        return self.filter({$0 as? T == obj}).count > 0
    }
}

func greatestCommonDivisor(_ a: Int, b: Int) -> Int {
    return b==0 ? a : greatestCommonDivisor(b, b: a%b)
}

