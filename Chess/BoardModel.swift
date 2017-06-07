//
//  Board.swift
//  Chess
//
//  Created by Jože Ws on 10/7/15.
//  Copyright © 2015 Self. All rights reserved.
//

import Foundation

// MARK: Piece Color

enum PieceColor: Int {
    case light, dark
}

// MARK: Piece Type

enum PieceType: Int, RawRepresentable {
    
    init?(raw: Int) {
        self.init(rawValue: raw)
    }
    
    case king, queen, rook, bishop, knight, pawn
}

// MARK: King Status

enum KingStatus: Int {
    case normal, checked, checkmated, stalemated
}

// MARK: Square

class Square: NSObject, NSCoding, NSCopying {
    
    let file: Int
    let rank: Int
    
    override var hashValue: Int {
        return file+rank*8
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let square = object as? Square {
            return file == square.file && rank == square.rank
        }
        return false
    }
    
    override var description: String {
        return String("\(self.file)\(self.rank)")
    }
    
    init(file: Int, rank: Int) {
        self.file = file
        self.rank = rank
    }
    
    func copy(with zone: NSZone?) -> Any {
        return Square(file: file, rank: rank)
    }
    
    required init?(coder aDecoder: NSCoder) {
        file = aDecoder.decodeInteger(forKey: "f")
        rank = aDecoder.decodeInteger(forKey: "r")
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(file, forKey: "f")
        aCoder.encode(rank, forKey: "r")
    }
}

// MARK: Piece

class Piece: NSObject, NSCoding, NSCopying {
    
    let initial: Square
    let color: PieceColor
    var type: PieceType
    
    override var description: String {
        return String("\(self.initial) \(self.color) \(self.type)")
    }
    
    override var hashValue: Int {
        return self.initial.hashValue
    }
    
    func copy(with zone: NSZone?) -> Any {
        return Piece(initial: initial, color: color, type: type)
    }
    
    init(initial: Square, color: PieceColor, type: PieceType) {
        self.initial = initial
        self.type = type
        self.color = color
    }
    
    required init?(coder aDecoder: NSCoder) {
        initial = aDecoder.decodeObject(forKey: "i") as! Square
        color = PieceColor(rawValue: aDecoder.decodeInteger(forKey: "c"))!
        type = PieceType(rawValue: aDecoder.decodeInteger(forKey: "t"))!
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(initial, forKey: "i")
        aCoder.encode(color.rawValue, forKey: "c")
        aCoder.encode(type.rawValue, forKey: "t")
    }
}

// MARK: Position Update

class PositionUpdate: NSObject, NSCoding {
    
    var move: (Square, Square)
    var capture: (piece: Piece?, square: Square?)
    var castle: (Square?, Square?)
    
    var promotionType: PieceType?
    
    var kingStatus: KingStatus = .normal
    
    init(square0: Square, square1: Square) {
        move = (square0, square1)
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        move = (aDecoder.decodeObject(forKey: "sq0") as! Square, aDecoder.decodeObject(forKey: "sq1") as! Square)
        capture = (aDecoder.decodeObject(forKey: "cp") as? Piece, aDecoder.decodeObject(forKey: "csq") as? Square)
        castle = (aDecoder.decodeObject(forKey: "c0") as? Square, aDecoder.decodeObject(forKey: "c1") as? Square)
        let promotionTypeRaw = aDecoder.decodeInteger(forKey: "pt")
        promotionType = promotionTypeRaw < 0 ? nil : PieceType(rawValue: promotionTypeRaw)
        kingStatus = KingStatus(rawValue: aDecoder.decodeInteger(forKey: "ks"))!
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(move.0, forKey: "sq0")
        aCoder.encode(move.1, forKey: "sq1")
        aCoder.encode(capture.piece, forKey: "cp")
        aCoder.encode(capture.square, forKey: "csq")
        aCoder.encode(castle.0, forKey: "c0")
        aCoder.encode(castle.1, forKey: "c1")
        aCoder.encode(promotionType == nil ? -1 : promotionType!.rawValue, forKey: "pt")
        aCoder.encode(kingStatus.rawValue, forKey: "ks")
    }
}

// MARK: Board Delegate

protocol BoardDelegate {
    func boardPromotedAtSquare(_ sq: Square)
}

// MARK: Board

class Board {
    
    let delegate: BoardDelegate
    var positions = [[Square: Piece]]()
    var updates = [PositionUpdate]()

    var lastPosition: [Square: Piece] {
        return positions.last!
    }
    var turnColor: PieceColor {
        return positions.count % 2 == 1 ? .light : .dark
    }
    
    fileprivate(set) var promoteSquare: Square?
    
    init(pieces: [Piece], delegate: BoardDelegate) {
        self.delegate = delegate
        var position = [Square: Piece]()
        for piece in pieces {
            position[piece.initial] = piece
        }
        positions.append(position)
    }
    
    func new(_ pieces: [Piece]) {
        positions.removeAll()
        updates.removeAll()
        var position = [Square: Piece]()
        for piece in pieces {
            position[piece.initial] = piece
        }
        positions.append(position)
    }
    
    func squareOfPiece(_ piece: Piece) -> Square? {
        for square in lastPosition.keys {
            if let p = lastPosition[square] {
                if p.initial == piece.initial {
                    return square
                }
            }
        }
        return nil
    }
    
    func squareOfKingOfColor(_ color: PieceColor) -> Square? {
        for square in lastPosition.keys {
            if let piece = lastPosition[square] {
                if piece.color == color && piece.type == .king {
                    return square
                }
            }
        }
        return nil
    }

    func piecesOfColor(_ color: PieceColor) -> [Piece] {
        var pieces = [Piece]()
        for piece in lastPosition.values {
            if piece.color == color {
                pieces.append(piece)
            }
        }
        return pieces
    }
    
    func promoteToType(_ type: PieceType) {
        let lastUpdate = updates.last!
        let promotePiece = lastPosition[lastUpdate.move.1]
        promotePiece!.type = type
        lastUpdate.promotionType = type
        promoteSquare = nil
    }
    
    func addPositionUpdate(_ update: PositionUpdate) {
        var position = [Square : Piece]()
        for key in lastPosition.keys {
            position[key] = lastPosition[key]
        }
        if update.capture.square != nil {
            update.capture.piece = position.removeValue(forKey: update.capture.square!)
        }
        let piece = position.removeValue(forKey: update.move.0)
        position.updateValue(piece!, forKey: update.move.1)
        if update.castle.0 != nil {
            let rook = position.removeValue(forKey: update.castle.0!)!
            position.updateValue(rook, forKey: update.castle.1!)
        }
        updates.append(update)
        positions.append(position)
        update.kingStatus = kingStatusOfTurnColor()
    }
    
    // MARK: King Status
    
    func kingStatusOfTurnColor() -> KingStatus {
        
        // MARK: Appends King Checks
        let lastPosition = self.lastPosition
        let turnColor = self.turnColor
        let sqK = squareOfKingOfColor(turnColor)!
        var checkingPieces = [Piece]()
        
        piecesOfOppColor: for pi in piecesOfColor(oppositeColor(turnColor)) {
            let sqPi = squareOfPiece(pi)!
            switch pi.type {
            case.king:
                // breaks as king could not check another king
                break
            case.queen:
                // if queen's move to king's square is not horizontal, vertical or diagional there is no check
                if abs(sqK.file-sqPi.file) != abs(sqK.rank-sqPi.rank) && !(abs(sqK.file-sqPi.file)>0 && sqK.rank-sqPi.rank==0) && !(sqK.file-sqPi.file==0 && abs(sqK.rank-sqPi.rank)>0) {
                    continue piecesOfOppColor
                }
                var sqi = sqPi
                let grad = gradientFromFileDelta(sqK.file-sqPi.file, rankDelta: sqK.rank-sqPi.rank)
                // loops from queen's square to king's square
                while true {
                    sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                    if sqi == sqK {
                        break
                    }
                    // if square is occupied there is no check
                    if lastPosition[sqi] != nil {
                        continue piecesOfOppColor
                    }
                }
                checkingPieces.append(pi)
            case.rook:
                // if rook's move to king's square is not horizontal or vertical there is no check
                if !(abs(sqK.file-sqPi.file)>0 && sqK.rank-sqPi.rank==0) && !(sqK.file-sqPi.file==0 && abs(sqK.rank-sqPi.rank)>0) {
                    continue piecesOfOppColor
                }
                var sqi = sqPi
                let grad = gradientFromFileDelta(sqK.file-sqPi.file, rankDelta: sqK.rank-sqPi.rank)
                // loops from rook's square to king's square
                while true {
                    sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                    if sqi == sqK {
                        break
                    }
                    // if square is occupied there is no check
                    if lastPosition[sqi] != nil {
                        continue piecesOfOppColor
                    }
                }
                checkingPieces.append(pi)
            case.bishop:
                // if bishop's move to king's square is not diagional there is no check
                if abs(sqK.file-sqPi.file) != abs(sqK.rank-sqPi.rank) {
                    continue piecesOfOppColor
                }
                var sqi = sqPi
                let grad = gradientFromFileDelta(sqK.file-sqPi.file, rankDelta: sqK.rank-sqPi.rank)
                // loops from bishop's square to king's square
                while true {
                    sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                    if sqi == sqK {
                        break
                    }
                    // if square is occupied there is no check
                    if lastPosition[sqi] != nil {
                        continue piecesOfOppColor
                    }
                }
                checkingPieces.append(pi)
            case.knight:
                // if bishop's move to king's square is not 'L' there is no check
                if abs((sqK.file-sqPi.file)*(sqK.rank-sqPi.rank)) == 2 {
                    checkingPieces.append(pi)
                }
            case.pawn:
                // if bishop's move to king's square is not sideways there is no check
                if abs(sqK.file-sqPi.file)==1 && sqK.rank-sqPi.rank==(pi.color == .light ? 1:-1) {
                    checkingPieces.append(pi)
                }
            }
        }
        
        // MARK: Tests Valid King Moves
        
        var kHasValidSquares = false
        
        let kingGrads = [Square(file: 1, rank: 0), Square(file: 0, rank: 1), Square(file: -1, rank: 0), Square(file: 0, rank: -1), Square(file: 1, rank: 1), Square(file: 1, rank: -1), Square(file: -1, rank: 1), Square(file: -1, rank: -1)]
        kingGrads: for kingGrad in kingGrads {
            let sqi = Square(file: sqK.file+kingGrad.file, rank: sqK.rank+kingGrad.rank)
            if !squareIsInBounds(sqi) {
                continue kingGrads
            }
            if let pieceAtSqki = lastPosition[sqi] {
                if pieceAtSqki.color == turnColor {
                    continue kingGrads
                }
            }
            piecesOfOppColor: for pi in piecesOfColor(oppositeColor(turnColor)) {
                let sqf = sqi
                let sqI = squareOfPiece(pi)!
                switch pi.type {
                case.king:
                    if !(abs(sqf.file-sqI.file)<=1 && abs(sqf.rank-sqI.rank)<=1) {
                        continue piecesOfOppColor
                    }
                    // if king is eyeing the square continues grads
                    continue kingGrads
                case.queen:
                    // if its not a queen's eye continues piecesOfOppColor
                    if (abs(sqf.file-sqI.file) != abs(sqf.rank-sqI.rank) || sqf.file-sqI.file==0) && !(abs(sqf.file-sqI.file)>0 && sqf.rank-sqI.rank==0) && !(sqf.file-sqI.file==0 && abs(sqf.rank-sqI.rank)>0) {
                        continue piecesOfOppColor
                    }
                    var sqi = sqI
                    let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                    // loops from queen's square to potential square
                    while true {
                        sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                        if sqi==sqf {
                            break
                        }
                        if sqi==sqK {
                            break
                        }
                        if lastPosition[sqi] != nil {
                            continue piecesOfOppColor
                        }
                    }
                    // if queen is eyeing the square continues grads
                    continue kingGrads
                case.rook:
                    // if its not a rook's eye continues piecesOfOppColor
                    if !(abs(sqf.file-sqI.file)>0 && sqf.rank-sqI.rank==0) && !(sqf.file-sqI.file==0 && abs(sqf.rank-sqI.rank)>0) {
                        continue piecesOfOppColor
                    }
                    var sqi = sqI
                    let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                    // loops from rook's square to sqkOi
                    while true {
                        sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                        if sqi==sqf {
                            break
                        }
                        if sqi==sqK {
                            break
                        }
                        if lastPosition[sqi] != nil {
                            continue piecesOfOppColor
                        }
                    }
                    // if rook is eyeing the square continues grads
                    continue kingGrads
                case.bishop:
                    // if its not a bishop's eye continues piecesOfOppColor
                    if abs(sqf.file-sqI.file) != abs(sqf.rank-sqI.rank) || sqf.file-sqI.file==0 {
                        continue piecesOfOppColor
                    }
                    var sqi = sqI
                    let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                    // loops from bishop's square to sqkOi
                    while true {
                        sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                        if sqi==sqf {
                            break
                        }
                        if sqi==sqK {
                            break
                        }
                        if lastPosition[sqi] != nil {
                            continue piecesOfOppColor
                        }
                    }
                    // if bishop is eyeing the square continues grads
                    continue kingGrads
                case.knight:
                    // if knight is eyeing the square continues grads
                    if abs((sqf.file-sqI.file)*(sqf.rank-sqI.rank)) == 2 {
                        continue kingGrads
                    }
                case.pawn:
                    // if pawn is eyeing the square continues grads
                    if abs(sqf.file-sqI.file)==1 && sqf.rank-sqI.rank==(pi.color == .light ? 1:-1)  {
                        continue kingGrads
                    }
                }
            }
            // none pieces is eyeing the square
            kHasValidSquares = true
            break kingGrads
        }
        
        if checkingPieces.count>0 && kHasValidSquares {
            return .checked
        }
        // MARK: Tests for Check Covers
        
        if checkingPieces.count>0 && !kHasValidSquares  {
            // find if check can be covered
            if checkingPieces.count==1 {
                var canCover = false
                let checkPiece = checkingPieces.first!
                let sqChPi = squareOfPiece(checkPiece)!
                let grad = gradientFromFileDelta(sqK.file-sqChPi.file, rankDelta: sqK.rank-sqChPi.rank)
                let sqf = sqK
                var sqi = Square(file: sqChPi.file-grad.file, rank: sqChPi.rank-grad.rank)
                // loops from check piece's square -including it - to king0's square
                checkPath: while true {
                    sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                    if sqi == sqf {
                        break
                    }
                    pieces: for pi in piecesOfColor(turnColor) {
                        let sqPi = squareOfPiece(pi)!
                        switch pi.type {
                        case.king:
                            // king must not cover itself
                            break
                        case.queen:
                            // if queen's move is not vertical, horizontal or diagonal piece can't cover
                            if (abs(sqi.file-sqPi.file) != abs(sqi.rank-sqPi.rank) || sqi.file-sqPi.file==0) && !(abs(sqi.file-sqPi.file)>0 && sqi.rank-sqPi.rank==0) && !(sqi.file-sqPi.file==0 && abs(sqi.rank-sqPi.rank)>0) {
                                continue
                            }
                            var sqii = sqPi
                            let grad = gradientFromFileDelta(sqi.file-sqPi.file, rankDelta: sqi.rank-sqPi.rank)
                            // loops from queen's square to sqi in check path
                            while true {
                                sqii = Square(file: sqii.file+grad.file, rank: sqii.rank+grad.rank)
                                // breaks as there must be no piece in check path thus piece can cover
                                if sqii == sqi {
                                    canCover = true
                                    break
                                }
                                // if square is occupied piece can't cover
                                if lastPosition[sqii] != nil {
                                    continue pieces
                                }
                            }
                        case.rook:
                            // if rook's move is not vertical or horizontal returns false
                            if !(abs(sqi.file-sqPi.file)>0 && sqi.rank-sqPi.rank==0) && !(sqi.file-sqPi.file==0 && abs(sqi.rank-sqPi.rank)>0) {
                                continue
                            }
                            var sqii = sqPi
                            let grad = gradientFromFileDelta(sqi.file-sqPi.file, rankDelta: sqi.rank-sqPi.rank)
                            // loops from rook's square to sqi in check path
                            while true {
                                sqii = Square(file: sqii.file+grad.file, rank: sqii.rank+grad.rank)
                                // breaks as there must be no piece in check path
                                if sqii == sqi {
                                    canCover = true
                                    break
                                }
                                // if square is occupied returns false
                                if lastPosition[sqii] != nil {
                                    continue pieces
                                }
                            }
                        case.bishop:
                            // if bishop's move is not diagional returns false
                            if abs(sqi.file-sqPi.file) != abs(sqi.rank-sqPi.rank) || (sqi.file-sqPi.file==0) {
                                continue
                            }
                            var sqii = sqPi
                            let grad = gradientFromFileDelta(sqi.file-sqPi.file, rankDelta: sqi.rank-sqPi.rank)
                            // loops from bishop's square to sqi in check path
                            while true {
                                sqii = Square(file: sqii.file+grad.file, rank: sqii.rank+grad.rank)
                                // breaks as there must be no piece in check path
                                if sqii == sqi {
                                    canCover = true
                                    break
                                }
                                // if square is occupied returns false
                                if lastPosition[sqii] != nil {
                                    continue pieces
                                }
                            }
                        case.knight:
                            // if knight's move is not in 'L' returns false
                            if abs((sqi.file-sqPi.file)*(sqi.rank-sqPi.rank)) != 2 {
                                continue
                            }
                            canCover = true
                        case.pawn:
                            if sqi==sqChPi {
                                // if pawn's move is sideways
                                if abs(sqi.file-sqPi.file)==1 && sqi.rank-sqPi.rank==(pi.color == .light ? 1:-1) {
                                    canCover = true
                                }
                            }
                            else {
                                // if pawn's move is frontal or double frontal
                                if abs(sqi.file-sqPi.file)==0 && sqi.rank-sqPi.rank==(pi.color == .light ? 1:-1) {
                                    canCover = true
                                }
                                if abs(sqi.file-sqPi.file)==0 && sqi.rank-sqPi.rank==(pi.color == .light ? 2:-2) && lastPosition[Square(file: sqPi.file, rank: sqPi.rank+(pi.color == .light ? 1:-1))] == nil {
                                    canCover = true
                                }
                            }
                            // if move is enPassant
                        }
                        // if can cover test move doesn't causes discovery check
                        if canCover {
                            // if path is pinnable...
                            if abs(sqPi.file-sqK.file) == abs(sqPi.rank-sqK.rank) || (abs(sqPi.file-sqK.file)>0 && sqPi.rank-sqK.rank==0) || (sqPi.file-sqK.file==0 && abs(sqPi.rank-sqK.rank)>0) {
                                var sqii = sqK
                                let grad = gradientFromFileDelta(sqPi.file-sqK.file, rankDelta: sqPi.rank-sqK.rank)
                                var sqPiLooped = false
                                // loops from king's square to check piece's square
                                while true {
                                    sqii = Square(file: sqii.file+grad.file, rank: sqii.rank+grad.rank)
                                    if !squareIsInBounds(sqii) {
                                        break checkPath
                                    }
                                    if sqii == sqPi {
                                        sqPiLooped = true
                                        continue
                                    }
                                    if let pieceSqii = lastPosition[sqii] {
                                        // if piece is in between king' square and sqPi breaks loop
                                        if !sqPiLooped {
                                            break checkPath
                                        }
                                        else {
                                            if pieceSqii.color == turnColor {
                                                break checkPath
                                            }
                                            // if pieceSqii is a queen and grad is a queen's grad
                                            if pieceSqii.type == .queen && ((abs(grad.file)==1 && abs(grad.rank)==1) || (abs(grad.file)>0 && grad.rank==0) || (grad.file==0 && abs(grad.rank)>0)) {
                                                canCover = false
                                                continue pieces
                                            }
                                            // if pieceSqii is a rook and grad is a rook's grad
                                            if pieceSqii.type == .rook && (abs(grad.file)>0 && grad.rank==0 || (grad.file==0 && abs(grad.rank)>0)) {
                                                canCover = false
                                                continue pieces
                                            }
                                            // if pieceAtiSq is a bishop and grad is a bishop's grad
                                            if pieceSqii.type == .bishop && abs(grad.file)==1 && abs(grad.rank)==1 {
                                                canCover = false
                                                continue pieces
                                            }
                                            break checkPath
                                        }
                                    }
                                }
                            }
                            else {
                                break checkPath
                            }
                        }
                    }
                }
                // CHECKMATE
                if !canCover {
                    return .checkmated
                }
                // CHECK
                else {
                    return .checked
                }
            }
            // CHECKMATE as double check can be covered
            if checkingPieces.count==2 {
                return .checkmated
            }
        }
        
        // MARK: Tests Draw (Missing test for discovery check)
        if checkingPieces.count==0 && !kHasValidSquares {
            var thereIsValidMove = false
            piecesOfColor: for pi in piecesOfColor(turnColor) {
                let sqPi = squareOfPiece(pi)!
                switch pi.type {
                case.king:
                    break
                case.queen:
                    let queenGrads = [Square(file: 1, rank: 0), Square(file: 0, rank: 1), Square(file: -1, rank: 0), Square(file: 0, rank: -1), Square(file: 1, rank: 1), Square(file: 1, rank: -1), Square(file: -1, rank: 1), Square(file: -1, rank: -1)]
                    for queenGrad in queenGrads {
                        var sqi = sqPi
                        // loops from bishop's square to end of board
                        while true {
                            sqi = Square(file: sqi.file+queenGrad.file, rank: sqi.rank+queenGrad.rank)
                            if !squareIsInBounds(sqi) {
                                break
                            }
                            if let pieceAtSqi = lastPosition[sqi] {
                                if pieceAtSqi.color == pi.color {
                                    break
                                }
                            }
                            // move is valid
                            thereIsValidMove = true
                            break piecesOfColor
                        }
                    }
                case.rook:
                    let rookGrads = [Square(file: 1, rank: 0), Square(file: 0, rank: 1), Square(file: -1, rank: 0), Square(file: 0, rank: -1)]
                    for rookGrad in rookGrads {
                        var sqi = sqPi
                        // loops from bishop's square to end of board
                        while true {
                            sqi = Square(file: sqi.file+rookGrad.file, rank: sqi.rank+rookGrad.rank)
                            if !squareIsInBounds(sqi) {
                                break
                            }
                            if let pieceAtSqi = lastPosition[sqi] {
                                if pieceAtSqi.color == pi.color {
                                    break
                                }
                            }
                            // move is valid
                            thereIsValidMove = true
                            break piecesOfColor
                        }
                    }
                case.bishop:
                    let bishopGrads = [Square(file: 1, rank: 1), Square(file: 1, rank: -1), Square(file: -1, rank: 1), Square(file: -1, rank: -1)]
                    for bishopGrad in bishopGrads {
                        var sqi = sqPi
                        // loops from bishop's square to end of board
                        while true {
                            sqi = Square(file: sqi.file+bishopGrad.file, rank: sqi.rank+bishopGrad.rank)
                            if !squareIsInBounds(sqi) {
                                break
                            }
                            if let pieceAtSqi = lastPosition[sqi] {
                                if pieceAtSqi.color == pi.color {
                                    break
                                }
                            }
                            // move is valid
                            thereIsValidMove = true
                            break piecesOfColor
                        }
                    }
                case.knight:
                    let knightGrads = [Square(file: 1, rank: 2), Square(file: 1, rank: -2), Square(file: -1, rank: 2), Square(file: -1, rank: -2), Square(file: 2, rank: 1), Square(file: 2, rank: -1), Square(file: -2, rank: 1), Square(file: -2, rank: -1)]
                    for knightGrad in knightGrads {
                        let sqi = Square(file: sqPi.file+knightGrad.file, rank: sqPi.rank+knightGrad.rank)
                        if !squareIsInBounds(sqi) {
                            continue
                        }
                        if let pieceAtSqi = lastPosition[sqi] {
                            if pieceAtSqi.color == turnColor {
                                continue
                            }
                        }
                        // move is valid
                        thereIsValidMove = true
                        break piecesOfColor
                    }
                case.pawn:
                    // if pawn can move single frontal...
                    if lastPosition[Square(file: sqPi.file, rank: sqPi.rank+(pi.color == .light ? 1:-1))] == nil {
                        thereIsValidMove = true
                        break piecesOfColor
                    }
                    // if pawn can move sideways...
                    if lastPosition[Square(file: sqPi.file+1, rank: sqPi.rank+(pi.color == .light ? 1:-1))] != nil || lastPosition[Square(file: sqPi.file-1, rank: sqPi.rank+(pi.color == .light ? 1:-1))] != nil {
                        thereIsValidMove = true
                        break piecesOfColor
                    }
                    // if pawn can move en passant...
                    
                }
            }
            if !thereIsValidMove {
                return .stalemated
            }
        }
        return .normal
    }
    
    // Mark: Posible Squares
    
    func possibleSquaresFromSquare(_ sq0: Square) -> [Square] {
        
        var squares = [Square]()
        
        if lastPosition[sq0] == nil {
            return squares
        }
        
        let turnColor = self.turnColor
        let p0 = lastPosition[sq0]!
        
        if p0.color != turnColor {
            return squares
        }
        
        let kingStatus = kingStatusOfTurnColor()
        if kingStatus == .checkmated || kingStatus == .stalemated {
            return squares
        }
        
        // MARK: Appends Valid Squares
        
        switch p0.type {
        case.king:
            let kingGrads = [Square(file: 1, rank: 0), Square(file: 0, rank: 1), Square(file: -1, rank: 0), Square(file: 0, rank: -1), Square(file: 1, rank: 1), Square(file: 1, rank: -1), Square(file: -1, rank: 1), Square(file: -1, rank: -1)]
            kingGrads: for kingGrad in kingGrads {
                let sqi = Square(file: sq0.file+kingGrad.file, rank: sq0.rank+kingGrad.rank)
                // if squares is not in bounds...
                if !squareIsInBounds(sqi) {
                    continue kingGrads
                }
                // if there is piece at sqi...
                if let pieceAtSqi = lastPosition[sqi] {
                    if pieceAtSqi.color == turnColor {
                        continue kingGrads
                    }
                }
                piecesOfOppColor: for pi in piecesOfColor(oppositeColor(turnColor)) {
                    let sqf = sqi
                    let sqI = squareOfPiece(pi)!
                    switch pi.type {
                    case.king:
                        if !(abs(sqf.file-sqI.file)<=1 && abs(sqf.rank-sqI.rank)<=1) {
                            continue piecesOfOppColor
                        }
                        // if king is eyeing the square continues grads
                        continue kingGrads
                    case.queen:
                        // if its not a queen's eye continues piecesOfOppColor
                        if (abs(sqf.file-sqI.file) != abs(sqf.rank-sqI.rank) || sqf.file-sqI.file==0) && !(abs(sqf.file-sqI.file)>0 && sqf.rank-sqI.rank==0) && !(sqf.file-sqI.file==0 && abs(sqf.rank-sqI.rank)>0) {
                            continue piecesOfOppColor
                        }
                        var sqi = sqI
                        let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                        // loops from queen's square to potential square
                        while true {
                            sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                            if sqi==sqf {
                                break
                            }
                            if sqi==sq0 {
                                break
                            }
                            if lastPosition[sqi] != nil {
                                continue piecesOfOppColor
                            }
                        }
                        // if queen is eyeing the square continues grads
                        continue kingGrads
                    case.rook:
                        // if its not a rook's eye continues piecesOfOppColor
                        if !(abs(sqf.file-sqI.file)>0 && sqf.rank-sqI.rank==0) && !(sqf.file-sqI.file==0 && abs(sqf.rank-sqI.rank)>0) {
                            continue piecesOfOppColor
                        }
                        var sqi = sqI
                        let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                        // loops from rook's square to sqkOi
                        while true {
                            sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                            if sqi==sqf {
                                break
                            }
                            if sqi==sq0 {
                                break
                            }
                            if lastPosition[sqi] != nil {
                                continue piecesOfOppColor
                            }
                        }
                        // if rook is eyeing the square continues grads
                        continue kingGrads
                    case.bishop:
                        // if its not a bishop's eye continues piecesOfOppColor
                        if abs(sqf.file-sqI.file) != abs(sqf.rank-sqI.rank) || sqf.file-sqI.file==0 {
                            continue piecesOfOppColor
                        }
                        var sqi = sqI
                        let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                        // loops from bishop's square to sqkOi
                        while true {
                            sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                            if sqi==sqf {
                                break
                            }
                            if sqi==sq0 {
                                break
                            }
                            if lastPosition[sqi] != nil {
                                continue piecesOfOppColor
                            }
                        }
                        // if bishop is eyeing the square continues grads
                        continue kingGrads
                    case.knight:
                        // if knight is eyeing the square continues grads
                        if abs((sqf.file-sqI.file)*(sqf.rank-sqI.rank)) == 2 {
                            continue kingGrads
                        }
                    case.pawn:
                        // if pawn is eyeing the square continues grads
                        if abs(sqf.file-sqI.file)==1 && sqf.rank-sqI.rank==(pi.color == .light ? 1:-1)  {
                            continue kingGrads
                        }
                    }
                }
                // none pieces is eyeing the square
                squares.append(sqi)
            }
        case.queen:
            let queenGrads = [Square(file: 1, rank: 0), Square(file: 0, rank: 1), Square(file: -1, rank: 0), Square(file: 0, rank: -1), Square(file: 1, rank: 1), Square(file: 1, rank: -1), Square(file: -1, rank: 1), Square(file: -1, rank: -1)]
            for queenGrad in queenGrads {
                var sqi = sq0
                // loops from queen's square to end of board
                while true {
                    sqi = Square(file: sqi.file+queenGrad.file, rank: sqi.rank+queenGrad.rank)
                    if !squareIsInBounds(sqi) {
                        break
                    }
                    if let pieceAtSqi = lastPosition[sqi] {
                        if pieceAtSqi.color == p0.color {
                            break
                        }
                        squares.append(sqi)
                        break
                    }
                    squares.append(sqi)
                }
            }
        case.rook:
            let rookGrads = [Square(file: 1, rank: 0), Square(file: 0, rank: 1), Square(file: -1, rank: 0), Square(file: 0, rank: -1)]
            for rookGrad in rookGrads {
                var sqi = sq0
                // loops from bishop's square to end of board
                while true {
                    sqi = Square(file: sqi.file+rookGrad.file, rank: sqi.rank+rookGrad.rank)
                    if !squareIsInBounds(sqi) {
                        break
                    }
                    if let pieceAtSqi = lastPosition[sqi] {
                        if pieceAtSqi.color == p0.color {
                            break
                        }
                        squares.append(sqi)
                        break
                    }
                    squares.append(sqi)
                }
            }
        case.bishop:
            let bishopGrads = [Square(file: 1, rank: 1), Square(file: 1, rank: -1), Square(file: -1, rank: 1), Square(file: -1, rank: -1)]
            for bishopGrad in bishopGrads {
                var sqi = sq0
                // loops from bishop's square to end of board
                while true {
                    sqi = Square(file: sqi.file+bishopGrad.file, rank: sqi.rank+bishopGrad.rank)
                    if !squareIsInBounds(sqi) {
                        break
                    }
                    if let pieceAtSqi = lastPosition[sqi] {
                        if pieceAtSqi.color == p0.color {
                            break
                        }
                        squares.append(sqi)
                        break
                    }
                    squares.append(sqi)
                }
            }
        case.knight:
            let knightGrads = [Square(file: 1, rank: 2), Square(file: 1, rank: -2), Square(file: -1, rank: 2), Square(file: -1, rank: -2), Square(file: 2, rank: 1), Square(file: 2, rank: -1), Square(file: -2, rank: 1), Square(file: -2, rank: -1)]
            for knightGrad in knightGrads {
                let sqi = Square(file: sq0.file+knightGrad.file, rank: sq0.rank+knightGrad.rank)
                if !squareIsInBounds(sqi) {
                    continue
                }
                if let pieceAtSqi = lastPosition[sqi] {
                    if pieceAtSqi.color == turnColor {
                        continue
                    }
                }
                // move is valid
                squares.append(sqi)
            }
        case.pawn:
            // if pawn can move single frontal...
            let sq1Frontal = Square(file: sq0.file, rank: sq0.rank+(p0.color == .light ? 1 : -1))
            if lastPosition[sq1Frontal] == nil {
                squares.append(sq1Frontal)
            }
            // if pawn can move double frontal...
            let sq2Frontal = Square(file: sq0.file, rank: sq0.rank+(p0.color == .light ? 2 : -2))
            if sq0.rank == (p0.color == .light ? 1 : 6) && lastPosition[sq1Frontal] == nil && lastPosition[sq2Frontal] == nil {
                squares.append(sq2Frontal)
            }
            // if pawn can move sideways...
            let sqSideway0 = Square(file: sq0.file+1, rank: sq0.rank+(p0.color == .light ? 1 : -1))
            if let pi = lastPosition[sqSideway0] {
                if pi.color == oppositeColor(p0.color) {
                    squares.append(sqSideway0)
                }
            }
            // else if pawn can take enPassant...
            else {
                if let lastUpdate = updates.last {
                    let lastMove = lastUpdate.move
                    let lastMovePiece = lastPosition[lastMove.1]!
                    if sq0.rank == (p0.color == .light ? 4 : 3) && lastMovePiece.type == .pawn && abs(lastMove.1.rank-lastMove.0.rank) == 2 && sqSideway0.file == lastMove.1.file {
                        squares.append(sqSideway0)
                    }
                }
            }
            // if pawn can move sideways...
            let sqSideway1 = Square(file: sq0.file-1, rank: sq0.rank+(p0.color == .light ? 1:-1))
            if let pi = lastPosition[sqSideway1] {
                if pi.color == oppositeColor(p0.color) {
                    squares.append(sqSideway1)
                }
            }
            // else if pawn can take enPassant...
            else {
                if let lastUpdate = updates.last {
                    let lastMove = lastUpdate.move
                    let lastMovePiece = lastPosition[lastMove.1]!
                    if sq0.rank == (p0.color == .light ? 4 : 3) && lastMovePiece.type == .pawn && abs(lastMove.1.rank-lastMove.0.rank) == 2 && sqSideway1.file == lastMove.1.file {
                        squares.append(sqSideway1)
                    }
                }
            }
        }
        
        // MARK: Tests Castle 
        
        if p0.type == .king && sq0.file == 4 && sq0.rank == (p0.color == .light ? 0 : 7) {
            let sqCorner0 = Square(file: 0, rank: p0.color == .light ? 0 : 7)
            let sqCorner1 = Square(file: 7, rank: p0.color == .light ? 0 : 7)
            sqCorners: for sqCorner in [sqCorner0, sqCorner1] {
                let piCorner = lastPosition[sqCorner]
                // if no piece at corner continues
                if piCorner == nil {
                    continue
                }
                // if piece is no rook of p0 color continues
                if piCorner!.type != .rook || piCorner!.color != p0.color {
                    continue
                }
                if updates.count==0 {
                    continue
                }
                // if rook has moved returns false
                for idx in 0...updates.count-1 {
                    if positions[idx][updates[idx].move.0] == piCorner {
                        continue sqCorners
                    }
                }
                // if king has moved returns false
                for idx in 0...updates.count-1 {
                    if positions[idx][updates[idx].move.0] == p0 {
                        continue sqCorners
                    }
                }
                // loops from king's square to corner in the direction of castling
                var sqi = sq0
                while true {
                    sqi = Square(file: sqi.file + (sqCorner.file-sq0.file>0 ? 1 : -1), rank: sqi.rank)
                    if sqi==sqCorner {
                        break
                    }
                    // continues as there is piece in path
                    if lastPosition[sqi] != nil {
                        continue sqCorners
                    }
                }
                // loops from king's square to king's final castling square
                castlePath: for sqf in [sq0, Square(file: sq0.file + (sqCorner.file-sq0.file>0 ? 1 : -1), rank: sq0.rank), Square(file: sq0.file + (sqCorner.file-sq0.file>0 ? 2 : -2), rank: sq0.rank)] {
                    // loops from pieces of king's opposite color
                    piecesOfOppColor: for pi in piecesOfColor(oppositeColor(p0.color)) {
                        let sqI = squareOfPiece(pi)!
                        switch pi.type {
                        case.king:
                            if !(abs(sqf.file-sqI.file)<=1 && abs(sqf.rank-sqI.rank)<=1) {
                                continue piecesOfOppColor
                            }
                            // if king is eyeing the square returns false
                            continue sqCorners
                        case.queen:
                            // if its not a queen's eye continues piecesOfOppColor
                            if abs(sqf.file-sqI.file) != abs(sqf.rank-sqI.rank) && !(abs(sqf.file-sqI.file)>0 && sqf.rank-sqI.rank==0) && !(sqf.file-sqI.file==0 && abs(sqf.rank-sqI.rank)>0) {
                                continue piecesOfOppColor
                            }
                            var sqi = sqI
                            let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                            // loops from queen's square to sqs
                            while true {
                                sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                                if sqi == sqf {
                                    break
                                }
                                if lastPosition[sqi] != nil {
                                    continue piecesOfOppColor
                                }
                            }
                            // continues as queen is eyeing the square
                            continue sqCorners
                        case.rook:
                            // if its not a rook's eye continues piecesOfOppColor
                            if !(abs(sqf.file-sqI.file)>0 && sqf.rank-sqI.rank==0) && !(sqf.file-sqI.file==0 && abs(sqf.rank-sqI.rank)>0) {
                                continue piecesOfOppColor
                            }
                            var sqi = sqI
                            let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                            // loops from rook's square to sqi
                            while true {
                                sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                                if sqi == sqf {
                                    break
                                }
                                if lastPosition[sqi] != nil {
                                    continue piecesOfOppColor
                                }
                            }
                            // continues as rook is eyeing the square
                            continue sqCorners
                        case.bishop:
                            // if its not a bishop's eye continues piecesOfOppColor
                            if abs(sqf.file-sqI.file) != abs(sqf.rank-sqI.rank) {
                                continue piecesOfOppColor
                            }
                            var sqi = sqI
                            let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                            // loops from bishop's square to sqi
                            while true {
                                sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                                if sqi == sqf {
                                    break
                                }
                                if lastPosition[sqi] != nil {
                                    continue piecesOfOppColor
                                }
                            }
                            // continues as bishop is eyeing the square
                            continue sqCorners
                        case.knight:
                            // if its not a kinght's eye continue piecesOfOppColor
                            if abs((sqf.file-sqI.file)*(sqf.rank-sqI.rank)) != 2 {
                                continue piecesOfOppColor
                            }
                            // continues as knight is eyeing the square
                            continue sqCorners
                        case.pawn:
                            // if its not a paws's eye continue piecesOfOppColor
                            if !(abs(sqf.file-sqI.file)==1 && sqf.rank-sqI.rank==(pi.color == .light ? 1:-1))  {
                                continue piecesOfOppColor
                            }
                            // cotinues as pawn is eyeing the square
                            continue sqCorners
                        }
                    }
                }
                squares.append(Square(file: sq0.file + (sqCorner.file-sq0.file>0 ? 2 : -2), rank: sq0.rank))
            }
        }
        
        // MARK: Tests For No Discovery Check
        
        let sqK = squareOfKingOfColor(p0.color)!
        
        if kingStatus == .normal && p0.type != .king {
            for square in squares {
                if abs(sq0.file-sqK.file) == abs(sq0.rank-sqK.rank) || (abs(sq0.file-sqK.file)>0 && sq0.rank-sqK.rank==0) || (sq0.file-sqK.file==0 && abs(sq0.rank-sqK.rank)>0) {
                    var sqI = sqK
                    let grad = gradientFromFileDelta(sq0.file-sqK.file, rankDelta: sq0.rank-sqK.rank)
                    var sq0WasLooped = false
                    // loops from king's square to end of board
                    while true {
                        sqI = Square(file: sqI.file+grad.file, rank: sqI.rank+grad.rank)
                        if !squareIsInBounds(sqI) {
                            break
                        }
                        if sqI == sq0 {
                            sq0WasLooped = true
                            continue
                        }
                        // if piece remains in pinnable path breaks loop
                        if sqI == square {
                            break
                        }
                        if lastPosition[sqI] != nil {
                            // if square is in between king' square and sq0 breaks loop
                            if !sq0WasLooped {
                                break
                            }
                            else {
                                // returns false if piece
                                if let pieceI = lastPosition[sqI] {
                                    if pieceI.color == turnColor {
                                        break
                                    }
                                    // if pieceI is a queen and grad is a queen's grad
                                    if pieceI.type == .queen && ((abs(grad.file)==1 && abs(grad.rank)==1) || (abs(grad.file)>0 && grad.rank==0) || (grad.file==0 && abs(grad.rank)>0)) {
                                        squares.remove(at: squares.index(of: square)!)
                                    }
                                    // if pieceAtiSq is a rook and grad is a rook's grad
                                    if pieceI.type == .rook && (abs(grad.file)>0 && grad.rank==0 || (grad.file==0 && abs(grad.rank)>0)) {
                                        squares.remove(at: squares.index(of: square)!)
                                    }
                                    // if pieceAtiSq is a bishop and grad is a bishop's grad
                                    if pieceI.type == .bishop && abs(grad.file)==1 && abs(grad.rank)==1 {
                                        squares.remove(at: squares.index(of: square)!)
                                    }
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // MARK: Test For Check Cover
        
        if kingStatus == .checked && p0.type != .king {
            var checkingPieces = [Piece]()
            pieceOfOppColor: for pi in piecesOfColor(oppositeColor(turnColor)) {
                let sqf = sqK
                let sqI = squareOfPiece(pi)!
                switch pi.type {
                case.king:
                    // breaks as king could not check another king
                    break
                case.queen:
                    // if queen's move to king's square is not horizontal, vertical or diagional there is no check
                    if abs(sqI.file-sqf.file) != abs(sqI.rank-sqf.rank) && !(abs(sqI.file-sqf.file)>0 && sqI.rank-sqf.rank==0) && !(sqI.file-sqf.file==0 && abs(sqI.rank-sqf.rank)>0) {
                        continue pieceOfOppColor
                    }
                    var sqi = sqI
                    let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                    // loops from queen's square to king's square
                    while true {
                        sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                        if sqi == sqf {
                            break
                        }
                        // if square is occupied there is no check
                        if lastPosition[sqi] != nil {
                            continue pieceOfOppColor
                        }
                    }
                    checkingPieces.append(pi)
                case.rook:
                    // if rook's move to king's square is not horizontal or vertical there is no check
                    if !(abs(sqI.file-sqf.file)>0 && sqI.rank-sqf.rank==0) && !(sqI.file-sqf.file==0 && abs(sqI.rank-sqf.rank)>0) {
                        continue pieceOfOppColor
                    }
                    var sqi = sqI
                    let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                    // loops from rook's square to king's square
                    while true {
                        sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                        if sqi == sqf {
                            break
                        }
                        // if square is occupied there is no check
                        if lastPosition[sqi] != nil {
                            continue pieceOfOppColor
                        }
                    }
                    checkingPieces.append(pi)
                case.bishop:
                    // if bishop's move to king's square is not diagional there is no check
                    if abs(sqI.file-sqf.file) != abs(sqI.rank-sqf.rank) {
                        continue pieceOfOppColor
                    }
                    var sqi = sqI
                    let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                    // loops from bishop's square to king's square
                    while true {
                        sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                        if sqi == sqf {
                            break
                        }
                        // if square is occupied there is no check
                        if lastPosition[sqi] != nil {
                            continue pieceOfOppColor
                        }
                    }
                    checkingPieces.append(pi)
                case.knight:
                    // if bishop's move to king's square is not 'L' there is no check
                    if abs((sqI.file-sqf.file)*(sqI.rank-sqf.rank)) != 2 {
                        continue pieceOfOppColor
                    }
                    checkingPieces.append(pi)
                case.pawn:
                    // if bishop's move to king's square is not sideways there is no check
                    if !(abs(sqI.file-sqf.file)==1 && sqI.rank-sqf.rank==(p0.color == .light ? 1:-1))  {
                        continue pieceOfOppColor
                    }
                    checkingPieces.append(pi)
                }
            }
            for square in squares {
                // if checking piece is taken continues
                if square == squareOfPiece(checkingPieces.first!)! {
                    continue
                }
                var sqi = squareOfPiece(checkingPieces.first!)!
                let grad = gradientFromFileDelta(sqK.file-sqi.file, rankDelta: sqK.rank-sqi.rank)
                // loops from check piece's square to king's square
                while true {
                    sqi = Square(file: sqi.file+grad.0, rank: sqi.rank+grad.1)
                    // check is covered
                    if square == sqi {
                        break
                    }
                    // check is not covered
                    if sqi == sqK {
                        squares.remove(at: squares.index(of: square)!)
                        break
                    }
                }
            }
        }
        return squares
    }
    
    // MARK: Position Updates

    func positionUpdateFromSquare(_ sq0: Square, toSquare sq1: Square) -> PositionUpdate? {
        
        //** if sq0 or sq1 are not in bounds returns false
        if !squareIsInBounds(sq0) || !squareIsInBounds(sq1) {
            return nil
        }
        
        let lastPosition = self.lastPosition
        
        //** if there is no piece to move returns false
        if lastPosition[sq0] == nil {
            return nil
        }
        
        let turnColor = self.turnColor
        let p0 = lastPosition[sq0]!
        let p1 = lastPosition[sq1]
        
        //** if color of p0 is not color to move returns false
        if p0.color != turnColor {
            return nil
        }
        
        //** if p1 is of same color as p0 returns false
        if p1 != nil {
            if p1!.color == p0.color {
                return nil
            }
        }
        
        // MARK: Tests Castle
        
        var castle = false
        if p0.type == .king && abs(sq1.file-sq0.file)==2 && sq1.rank-sq0.rank==0 && sq0.rank==(p0.color == .light ? 0:7) {
            castle = true
            // square in the corner of the direction of castle
            let sqCorner = Square(file: sq1.file-sq0.file>0 ? 7:0, rank: p0.color == .light ? 0:7)
            let cornerRook = lastPosition[sqCorner]
            let king = p0
            if cornerRook != nil {
                // if no rook is missing returns false
                if !(cornerRook!.type == .rook && cornerRook!.color == p0.color) {
                    return nil
                }
            }
            // if there is no piece at corner returns false
            else {
                return nil
            }
            // if rook has moved returns false
            for idx in 0...updates.count-1 {
                if positions[idx][updates[idx].move.0] == cornerRook {
                    return nil
                }
            }
            // if king has moved returns false
            for idx in 0...updates.count-1 {
                if positions[idx][updates[idx].move.0] == king {
                    return nil
                }
            }
            var sqi = squareOfPiece(p0)!
            // loops from king's square to corner in the direction of castling
            while true {
                sqi = Square(file: sqi.file + (sq1.file-sq0.file>0 ? 1 : -1), rank: sqi.rank)
                if sqi==sqCorner {
                    break
                }
                // returns false there is piece in path
                if lastPosition[sqi] != nil {
                    return nil
                }
            }
            // loops from king's square to king's final castling square
            for sqf in [sq0, Square(file: (sq0.file+sq1.file)/2, rank: sq0.rank),sq1] {
                // loops from pieces of king's opposite color
                piecesOfOppColor: for pi in piecesOfColor(oppositeColor(p0.color)) {
                    let sqI = squareOfPiece(pi)!
                    switch pi.type {
                    case.king:
                        if !(abs(sqI.file-sqf.file)<=1 && abs(sqI.rank-sqf.rank)<=1) {
                            continue piecesOfOppColor
                        }
                        // if king is eyeing the square returns false
                        return nil
                    case.queen:
                        // if its not a queen's eye continues piecesOfOppColor
                        if abs(sqI.file-sqf.file) != abs(sqI.rank-sqf.rank) && !(abs(sqI.file-sqf.file)>0 && sqI.rank-sqf.rank==0) && !(sqI.file-sqf.file==0 && abs(sqI.rank-sqf.rank)>0) {
                            continue piecesOfOppColor
                        }
                        var sqi = sqI
                        let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                        // loops from queen's square to sqs
                        while true {
                            sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                            if sqi == sqf {
                                break
                            }
                            if lastPosition[sqi] != nil {
                                continue piecesOfOppColor
                            }
                        }
                        // if queen is eyeing the square returns false
                        return nil
                    case.rook:
                        // if its not a rook's eye continues piecesOfOppColor
                        if !(abs(sqf.file-sqI.file)>0 && sqf.rank-sqI.rank==0) && !(sqf.file-sqI.file==0 && abs(sqf.rank-sqI.rank)>0) {
                            continue piecesOfOppColor
                        }
                        var sqi = sqI
                        let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                        // loops from rook's square to sqi
                        while true {
                            sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                            if sqi == sqf {
                                break
                            }
                            if lastPosition[sqi] != nil {
                                continue piecesOfOppColor
                            }
                        }
                        // if rook is eyeing the square returns false
                        return nil
                    case.bishop:
                        // if its not a bishop's eye continues piecesOfOppColor
                        if abs(sqf.file-sqI.file) != abs(sqf.rank-sqI.rank) {
                            continue piecesOfOppColor
                        }
                        var sqi = sqI
                        let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                        // loops from bishop's square to sqi
                        while true {
                            sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                            if sqi == sqf {
                                break
                            }
                            if lastPosition[sqi] != nil {
                                continue piecesOfOppColor
                            }
                        }
                        // if bishop is eyeing the square returns false
                        return nil
                    case.knight:
                        // if its not a kinght's eye continue piecesOfOppColor
                        if abs((sqf.file-sqI.file)*(sqf.rank-sqI.rank)) != 2 {
                            continue piecesOfOppColor
                        }
                        // if knight is eyeing the square returns false
                        return nil
                    case.pawn:
                        // if its not a paws's eye continue piecesOfOppColor
                        if !(abs(sqf.file-sqI.file)==1 && sqf.rank-sqI.rank==(pi.color == .light ? 1:-1))  {
                            continue piecesOfOppColor
                        }
                        // if pawn is eyeing the square returns false
                        return nil
                    }
                }
            }
        }

        // MARK: Tests Gradient
        
        var enPassantSq: Square?
        if true {
            switch p0.type {
            case.king:
                // if king's move is not moving to contiguous square or castling returns false
                if !(abs(sq1.file-sq0.file)<=1 && abs(sq1.rank-sq0.rank)<=1) && !castle {
                    return nil
                }
            case.queen:
                // if king's move is not vertical, horizontal or diagonal returns false
                if (abs(sq1.file-sq0.file) != abs(sq1.rank-sq0.rank) || sq1.file-sq0.file==0) && !(abs(sq1.file-sq0.file)>0 && sq1.rank-sq0.rank==0) && !(sq1.file-sq0.file==0 && abs(sq1.rank-sq0.rank)>0) {
                    return nil
                }
                var sqi = sq0
                let grad = gradientFromFileDelta(sq1.file-sq0.file, rankDelta: sq1.rank-sq0.rank)
                // loops from queen's sq0 to sq1
                while true {
                    sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                    // breaks as there can only be piece of opposite color at sq1 as tested above
                    if sqi == sq1 {
                        break
                    }
                    // if square is occupied returns false
                    if lastPosition[sqi] != nil {
                        return nil
                    }
                }
            case.rook:
                // if rook's move is not vertical or horizontal returns false
                if !(abs(sq1.file-sq0.file)>0 && sq1.rank-sq0.rank==0) && !(sq1.file-sq0.file==0 && abs(sq1.rank-sq0.rank)>0) {
                    return nil
                }
                var sqi = sq0
                let grad = gradientFromFileDelta(sq1.file-sq0.file, rankDelta: sq1.rank-sq0.rank)
                // loops from rook's sq0 to sq1
                while true {
                    sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                    // breaks as there can only be piece of opposite color at sq1 as tested above
                    if sqi == sq1 {
                        break
                    }
                    // if square is occupied returns false
                    if lastPosition[sqi] != nil {
                        return nil
                    }
                }
            case.bishop:
                // if bishop's move is not diagional returns false
                if abs(sq1.file-sq0.file) != abs(sq1.rank-sq0.rank) || sq1.file-sq0.file==0 {
                    return nil
                }
                var sqi = sq0
                let grad = gradientFromFileDelta(sq1.file-sq0.file, rankDelta: sq1.rank-sq0.rank)
                // loops from bishop sq0 to sq1
                while true {
                    sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                    // breaks as there can only be piece of opposite color at sq1 as tested above
                    if sqi == sq1 {
                        break
                    }
                    // if square is occupied returns false
                    if lastPosition[sqi] != nil {
                        return nil
                    }
                }
            case.knight:
                // if kinght's move is not in 'L' returns false
                if abs((sq1.file-sq0.file)*(sq1.rank-sq0.rank)) != 2 {
                    return nil
                }
            case.pawn:
                // if pawn's move is frontal and p1 is not nil returns false
                if sq1.file-sq0.file==0 && sq1.rank-sq0.rank==(p0.color == .light ? 1:-1) {
                    if p1 != nil {
                        return nil
                    }
                }
                // if pawn's move is double frontal
                else if sq1.file-sq0.file==0 && sq1.rank-sq0.rank==(p0.color == .light ? 2:-2) {
                    // if pawn is not in its initial square returns false
                    if sq0.rank != (p0.color==PieceColor.light ? 1:6) {
                        return nil
                    }
                    // if sq in between is occupied returns false
                    if lastPosition[Square(file: sq1.file, rank: (sq1.rank+sq0.rank)/2)] != nil {
                        return nil
                    }
                    // if pq is not nil returns false
                    if p1 != nil {
                        return nil
                    }
                }
                // if pawn's move is sideways
                else if abs(sq1.file-sq0.file)==1 && sq1.rank-sq0.rank==(p0.color == .light ? 1:-1) {
                    // checks for enPassant move take if piece1 is nil
                    if p1 == nil {
                        if let lastUpdate = updates.last {
                            let lastMove = lastUpdate.move
                            let lastMovePiece = lastPosition[lastMove.1]!
                            if sq0.rank != (p0.color == .light ? 4 : 3) || lastMovePiece.type != .pawn || abs(lastMove.1.rank-lastMove.0.rank) != 2 || sq1.file != lastMove.1.file {
                                return nil
                            }
                            enPassantSq = lastMove.1
                        }
                        else {
                            return nil
                        }
                    }
                }
                // returns false as pawn's move is not frontal, double frontal, sideways or enPassant
                else {
                    return nil
                }
            }
        }
        
        // MARK: Tests Check
        if p0.type == .king {
            // loops from pieces of king's opposite color
            let sqf = sq1
            piecesOfOppColor: for pi in piecesOfColor(oppositeColor(p0.color)) {
                let sqI = squareOfPiece(pi)!
                switch pi.type {
                case.king:
                    if !(abs(sqI.file-sqf.file)<=1 && abs(sqI.rank-sqf.rank)<=1) {
                        continue piecesOfOppColor
                    }
                    // if king is eyeing the square returns false
                    return nil
                case.queen:
                    // if its not a queen's eye continues piecesOfOppColor
                    if (abs(sqI.file-sqf.file) != abs(sqI.rank-sqf.rank) || sqI.file-sqf.file==0) && !(abs(sqI.file-sqf.file)>0 && sqI.rank-sqf.rank==0) && !(sqI.file-sqf.file==0 && abs(sqI.rank-sqf.rank)>0) {
                        continue piecesOfOppColor
                    }
                    var sqi = sqI
                    let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                    // loops from queen's square to sqs
                    while true {
                        sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                        if sqi==sqf {
                            break
                        }
                        // king is in check and is no exiting check path
                        if sqi==sq0 {
                            break
                        }
                        if lastPosition[sqi] != nil {
                            continue piecesOfOppColor
                        }
                    }
                    // if queen is eyeing the square returns false
                    return nil
                case.rook:
                    // if its not a rook's eye continues piecesOfOppColor
                    if !(abs(sqf.file-sqI.file)>0 && sqf.rank-sqI.rank==0) && !(sqf.file-sqI.file==0 && abs(sqf.rank-sqI.rank)>0) {
                        continue piecesOfOppColor
                    }
                    var sqi = sqI
                    let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                    // loops from rook's square to sqi
                    while true {
                        sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                        if sqi==sqf {
                            break
                        }
                        // king is in check and is no exiting check path
                        if sqi==sq0 {
                            break
                        }
                        if lastPosition[sqi] != nil {
                            continue piecesOfOppColor
                        }
                    }
                    // if rook is eyeing the square returns false
                    return nil
                case.bishop:
                    // if its not a bishop's eye continues piecesOfOppColor
                    if abs(sqI.file-sqf.file) != abs(sqI.rank-sqf.rank) || sqI.file-sqf.file==0 {
                        continue piecesOfOppColor
                    }
                    var sqi = sqI
                    let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                    // loops from bishop's square to sqi
                    while true {
                        sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                        if sqi==sqf {
                            break
                        }
                        // king is in check and is no exiting check path
                        if sqi==sq0 {
                            break
                        }
                        if lastPosition[sqi] != nil {
                            continue piecesOfOppColor
                        }
                    }
                    // if bishop is eyeing the square returns false
                    return nil
                case.knight:
                    // if its not a kinght's eye continue piecesOfOppColor
                    if abs((sqf.file-sqI.file)*(sqf.rank-sqI.rank)) != 2 {
                        continue piecesOfOppColor
                    }
                    // if knight is eyeing the square returns false
                    return nil
                case.pawn:
                    // if its not a paws's eye continue piecesOfOppColor
                    if !(abs(sqf.file-sqI.file)==1 && sqf.rank-sqI.rank==(pi.color == .light ? 1:-1))  {
                        continue piecesOfOppColor
                    }
                    // returns false as pawn is eyeing the square
                    return nil
                }
            }
        }
        
        // MARK: Appends Check

        let sqK = squareOfKingOfColor(p0.color)!
        var checkingPieces = [Piece]()
        
        pieceOfOppColor: for pi in piecesOfColor(oppositeColor(turnColor)) {
            let sqf = sqK
            let sqI = squareOfPiece(pi)!
            switch pi.type {
            case.king:
                // breaks as king could not check another king
                break
            case.queen:
                // if queen's move to king's square is not horizontal, vertical or diagional there is no check
                if abs(sqI.file-sqf.file) != abs(sqI.rank-sqf.rank) && !(abs(sqI.file-sqf.file)>0 && sqI.rank-sqf.rank==0) && !(sqI.file-sqf.file==0 && abs(sqI.rank-sqf.rank)>0) {
                    continue pieceOfOppColor
                }
                var sqi = sqI
                let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                // loops from queen's square to king's square
                while true {
                    sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                    if sqi == sqf {
                        break
                    }
                    // if square is occupied there is no check
                    if lastPosition[sqi] != nil {
                        continue pieceOfOppColor
                    }
                }
                checkingPieces.append(pi)
            case.rook:
                // if rook's move to king's square is not horizontal or vertical there is no check
                if !(abs(sqI.file-sqf.file)>0 && sqI.rank-sqf.rank==0) && !(sqI.file-sqf.file==0 && abs(sqI.rank-sqf.rank)>0) {
                    continue pieceOfOppColor
                }
                var sqi = sqI
                let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                // loops from rook's square to king's square
                while true {
                    sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                    if sqi == sqf {
                        break
                    }
                    // if square is occupied there is no check
                    if lastPosition[sqi] != nil {
                        continue pieceOfOppColor
                    }
                }
                checkingPieces.append(pi)
            case.bishop:
                // if bishop's move to king's square is not diagional there is no check
                if abs(sqI.file-sqf.file) != abs(sqI.rank-sqf.rank) {
                    continue pieceOfOppColor
                }
                var sqi = sqI
                let grad = gradientFromFileDelta(sqf.file-sqI.file, rankDelta: sqf.rank-sqI.rank)
                // loops from bishop's square to king's square
                while true {
                    sqi = Square(file: sqi.file+grad.file, rank: sqi.rank+grad.rank)
                    if sqi == sqf {
                        break
                    }
                    // if square is occupied there is no check
                    if lastPosition[sqi] != nil {
                        continue pieceOfOppColor
                    }
                }
                checkingPieces.append(pi)
            case.knight:
                // if bishop's move to king's square is not 'L' there is no check
                if abs((sqI.file-sqf.file)*(sqI.rank-sqf.rank)) != 2 {
                    continue pieceOfOppColor
                }
                checkingPieces.append(pi)
            case.pawn:
                // if bishop's move to king's square is not sideways there is no check
                if !(abs(sqI.file-sqf.file)==1 && sqI.rank-sqf.rank==(p0.color == .light ? 1:-1))  {
                    continue pieceOfOppColor
                }
                checkingPieces.append(pi)
            }
        }
        
        //** MARK: Tests Check Cover
        if p0.type != .king && checkingPieces.count == 1 && sq1 != squareOfPiece(checkingPieces.first!)! {
            // if check piece cannot be taken as en passant...
            if enPassantSq==nil || checkingPieces.first!.type != .pawn {
                var sqi = squareOfPiece(checkingPieces.first!)!
                let grad = gradientFromFileDelta(sqK.file-sqi.file, rankDelta: sqK.rank-sqi.rank)
                // loops from check piece's square to king's square
                while true {
                    sqi = Square(file: sqi.file+grad.0, rank: sqi.rank+grad.1)
                    // check is covered
                    if sq1 == sqi {
                        break
                    }
                    // check is not covered
                    if sqi == sqK {
                        return nil
                    }
                }
            }
        }
        
        //** if piece is not king and there is double check returns false
        if p0.type != .king && checkingPieces.count == 2 {
            return nil
        }
        
        // MARK: Tests Discovery Check
        if p0.type != .king && abs(sq0.file-sqK.file) == abs(sq0.rank-sqK.rank) || (abs(sq0.file-sqK.file)>0 && sq0.rank-sqK.rank==0) || (sq0.file-sqK.file==0 && abs(sq0.rank-sqK.rank)>0) {
            var sqI = sqK
            let grad = gradientFromFileDelta(sq0.file-sqK.file, rankDelta: sq0.rank-sqK.rank)
            var sq0WasLooped = false
            // loops from king's square to end of board
            while true {
                sqI = Square(file: sqI.file+grad.file, rank: sqI.rank+grad.rank)
                if !squareIsInBounds(sqI) {
                    break
                }
                if sqI == sq0 {
                    sq0WasLooped = true
                    continue
                }
                // if piece remains in pinnable path breaks loop
                if sqI == sq1 {
                    break
                }
                if lastPosition[sqI] != nil {
                    // if square is in between king' square and sq0 breaks loop
                    if !sq0WasLooped {
                        break
                    }
                    else {
                        // returns false if piece
                        if let pieceI = lastPosition[sqI] {
                            if pieceI.color == turnColor {
                                break
                            }
                            // if pieceI is a queen and grad is a queen's grad
                            if pieceI.type == .queen && ((abs(grad.file)==1 && abs(grad.rank)==1) || (abs(grad.file)>0 && grad.rank==0) || (grad.file==0 && abs(grad.rank)>0)) {
                                return nil
                            }
                            // if pieceAtiSq is a rook and grad is a rook's grad
                            if pieceI.type == .rook && (abs(grad.file)>0 && grad.rank==0 || (grad.file==0 && abs(grad.rank)>0)) {
                                return nil
                            }
                            // if pieceAtiSq is a bishop and grad is a bishop's grad
                            if pieceI.type == .bishop && abs(grad.file)==1 && abs(grad.rank)==1 {
                                return nil
                            }
                            break
                        }
                    }
                }
            }
        }
    
        // MARK: Creates position
        
        let update = PositionUpdate(square0: sq0, square1: sq1)
        if enPassantSq != nil {
            update.capture = (lastPosition[enPassantSq!], enPassantSq!)
        }
        else if p1 != nil {
            update.capture = (p1, sq1)
        }
        if p0.type == .king && abs(sq1.file-sq0.file)==2 {
            update.castle = (Square(file: sq1.file-sq0.file>0 ? 7:0, rank: p0.color == .light ? 0:7), Square(file: (sq0.file+sq1.file)/2, rank: sq0.rank))
        }
        if p0.type == .pawn && sq1.rank==(p0.color == .light ? 7:0) {
            promoteSquare = sq1
            delegate.boardPromotedAtSquare(promoteSquare!)
        }
        return update
    }
}





