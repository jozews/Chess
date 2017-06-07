//
//  BoardView.swift
//  Chess
//
//  Created by Jože Ws on 10/3/15.
//  Copyright © 2015 Self. All rights reserved.
//

import UIKit

class PieceView: UIImageView {
    
    var type: PieceType {
        didSet {
            self.image = UIImage(named: imageNameForPieceType(type, pieceColor: color))
        }
    }
    var color: PieceColor {
        didSet {
            self.image = UIImage(named: imageNameForPieceType(type, pieceColor: color))
        }
    }
        
    init(boardView: BoardView, type: PieceType, color: PieceColor) {
        self.type = type
        self.color = color
        super.init(image: UIImage(named: imageNameForPieceType(type, pieceColor: color)))
        self.isUserInteractionEnabled = true
        self.frame.size = CGSize(width: boardView.squareLength, height: boardView.squareLength)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol BoardViewDelegate {
    var boardOrientation: PieceColor { get }
}

class BoardView: UIView {
    
    var sideLength: CGFloat
    var squareLength: CGFloat

    var delegate: BoardViewDelegate
    
    let lightColor = UIColor.white
    let darkColor = darkUIColor()
    
    let checkColor = checkUIColor()
    let moveColor = moveUIColor()
    let sq01Color = sq01UIColor()
    
    var sq0: Square? = nil {
        didSet {
            if oldValue != nil {
                let oldOrigin = selfOriginOfSquare(oldValue!)
                setNeedsDisplay(CGRect(x: oldOrigin.x, y: oldOrigin.y, width: squareLength, height: squareLength))
            }
            if sq0 != nil {
                let sq0Origin = selfOriginOfSquare(sq0!)
                setNeedsDisplay(CGRect(x: sq0Origin.x, y: sq0Origin.y, width: squareLength, height: squareLength))
            }
        }
    }
    
    var sq1s = [Square]() {
        didSet {
            for oldSq1 in oldValue {
                let oldSq1Origin = selfOriginOfSquare(oldSq1)
                setNeedsDisplay(CGRect(x: oldSq1Origin.x, y: oldSq1Origin.y, width: squareLength, height: squareLength))
            }
            for sq1 in sq1s {
                let sq1Origin = selfOriginOfSquare(sq1)
                setNeedsDisplay(CGRect(x: sq1Origin.x, y: sq1Origin.y, width: squareLength, height: squareLength))
            }
        }
    }
    
    var squareCheck: Square? {
        didSet {
            if oldValue != nil {
                let oldOrigin = selfOriginOfSquare(oldValue!)
                setNeedsDisplay(CGRect(x: oldOrigin.x, y: oldOrigin.y, width: squareLength, height: squareLength))
            }
            if squareCheck != nil {
                let checkOrigin = selfOriginOfSquare(squareCheck!)
                setNeedsDisplay(CGRect(x: checkOrigin.x, y: checkOrigin.y, width: squareLength, height: squareLength))
            }
        }
    }
    
    var move: (Square?, Square?) {
        didSet {
            if oldValue.0 != nil {
                let old0Origin = selfOriginOfSquare(oldValue.0!)
                setNeedsDisplay(CGRect(x: old0Origin.x, y: old0Origin.y, width: squareLength, height: squareLength))
            }
            
            if oldValue.1 != nil {
                let old1Origin = selfOriginOfSquare(oldValue.1!)
                setNeedsDisplay(CGRect(x: old1Origin.x, y: old1Origin.y, width: squareLength, height: squareLength))
            }
            
            if move.0 != nil {
                let move0Origin = selfOriginOfSquare(move.0!)
                setNeedsDisplay(CGRect(x: move0Origin.x, y: move0Origin.y, width: squareLength, height: squareLength))
            }
            
            if move.1 != nil {
                let move1Origin = selfOriginOfSquare(move.1!)
                setNeedsDisplay(CGRect(x: move1Origin.x, y: move1Origin.y, width: squareLength, height: squareLength))
            }
        }
    }
    
    var highlightWidth: CGFloat {
        return squareLength/24
    }
    
    init(origin: CGPoint, length: CGFloat, delegate: BoardViewDelegate) {
        self.sideLength = length
        self.squareLength = length/8
        self.delegate = delegate
        super.init(frame: CGRect(x: origin.x, y: origin.y, width: length, height: length))
    }
    
    func originOfSquare(_ sq: Square) -> CGPoint {
        if delegate.boardOrientation == .light {
            return CGPoint(x: frame.origin.x+CGFloat(sq.file)*squareLength, y: frame.origin.y+sideLength-CGFloat(sq.rank+1)*squareLength)
        }
        return CGPoint(x: frame.origin.x+sideLength-CGFloat(sq.file+1)*squareLength, y: frame.origin.y+CGFloat(sq.rank)*squareLength)
    }
    
    func squareAtCoordinatePoint(_ point: CGPoint) -> Square {
        if delegate.boardOrientation == .light {
            return Square(file: Int((point.x-frame.origin.x)/squareLength), rank: 7-Int((point.y-frame.origin.y)/squareLength))
        }
        return Square(file: 7-Int((point.x-frame.origin.x)/squareLength), rank: Int((point.y-frame.origin.y)/squareLength))
    }
    
    func selfOriginOfSquare(_ sq: Square) -> CGPoint {
        if delegate.boardOrientation == .light {
            return CGPoint(x: CGFloat(sq.file)*squareLength, y: sideLength-CGFloat(sq.rank+1)*squareLength)
        }
        return CGPoint(x: sideLength-CGFloat(sq.file+1)*squareLength, y: CGFloat(sq.rank)*squareLength)
    }
    
    override func draw(_ rect: CGRect) {
        
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.clear(rect)
        
        var color = darkColor
        for file in 0...7 {
            for rank in 0...7 {
                ctx.setFillColor(color.cgColor)
                ctx.fill(CGRect(x: CGFloat(file)*squareLength, y: CGFloat(rank)*squareLength, width: squareLength, height: squareLength))
                color = (color==lightColor) ? darkColor : lightColor
            }
            color = (color==lightColor) ? darkColor : lightColor
        }
        
        ctx.setFillColor(moveColor.cgColor)
        if move.0 != nil {
            let moveOrigin = selfOriginOfSquare(move.0!)
            ctx.fill(CGRect(origin: moveOrigin, size: CGSize(width: squareLength, height: squareLength)))
        }
        
        if move.1 != nil {
            let moveOrigin = selfOriginOfSquare(move.1!)
            ctx.fill(CGRect(origin: moveOrigin, size: CGSize(width: squareLength, height: squareLength)))
        }

        if squareCheck != nil {
            ctx.setFillColor(checkColor.cgColor)
            let checkOrigin = selfOriginOfSquare(squareCheck!)
            ctx.fill(CGRect(origin: checkOrigin, size: CGSize(width: squareLength, height: squareLength)))
        }
        
        ctx.setFillColor(sq01Color.cgColor)
        if sq0 != nil {
            let checkOrigin = selfOriginOfSquare(sq0!)
            ctx.fill(CGRect(origin: checkOrigin, size: CGSize(width: squareLength, height: squareLength)))
        }
        
        for sq1 in sq1s {
            let checkOrigin = selfOriginOfSquare(sq1)
            ctx.fill(CGRect(origin: checkOrigin, size: CGSize(width: squareLength, height: squareLength)))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

