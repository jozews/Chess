//
//  BackgroundView.swift
//  Chess
//
//  Created by Jože Ws on 11/30/15.
//  Copyright © 2015 Self. All rights reserved.
//

import UIKit


protocol BackgroundViewDelegate {
    var boardOrientation: PieceColor { get }
}

class BackgroundView: UIView {

    let delegate: BackgroundViewDelegate
    
    init(frame: CGRect, delegate: BackgroundViewDelegate) {
        self.delegate = delegate
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        
        let sideWidth = frame.width-frame.height
        let boardWidth = frame.height
        let squareLength = (frame.height-frame.height/16)/8
        
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fill(CGRect(x: boardWidth, y: 0, width: sideWidth, height: frame.height))
        
        ctx.setFillColor(frameUIColor().cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: boardWidth-boardWidth/32, height: boardWidth/32))
        ctx.fill(CGRect(x: boardWidth-boardWidth/32, y: 0, width: boardWidth/32, height: boardWidth-boardWidth/32))
        ctx.fill(CGRect(x: boardWidth/32, y: boardWidth-boardWidth/32, width: boardWidth-boardWidth/32, height: boardWidth/32))
        ctx.fill(CGRect(x: 0, y: boardWidth/32, width: boardWidth/32, height: boardWidth-boardWidth/32))
        
        for idx in 0...7 {
            var string = NSString(string: "")
            if delegate.boardOrientation == .light {
                switch idx {
                case 0:
                    string = "a"
                case 1:
                    string = "b"
                case 2:
                    string = "c"
                case 3:
                    string = "d"
                case 4:
                    string = "e"
                case 5:
                    string = "f"
                case 6:
                    string = "g"
                case 7:
                    string = "h"
                default:
                    break
                }
            }
            else {
                switch idx {
                case 0:
                    string = "h"
                case 1:
                    string = "g"
                case 2:
                    string = "f"
                case 3:
                    string = "e"
                case 4:
                    string = "d"
                case 5:
                    string = "c"
                case 6:
                    string = "b"
                case 7:
                    string = "a"
                default:
                    break
                }
            }
            let x = boardWidth/32+CGFloat(idx+1)*squareLength-(1/2)*squareLength-(1/4)*(boardWidth/32)
            let y = boardWidth-boardWidth/32-(1/8)*boardWidth/32
            string.draw(at: CGPoint(x: x, y: y), withAttributes: [NSForegroundColorAttributeName : textUIColor(), NSFontAttributeName : UIFont.boldSystemFont(ofSize: boardWidth/32)])
        }
        
        for idx in 0...7 {
            var string = NSString(string: "")
            if delegate.boardOrientation == .dark {
                switch idx {
                case 0:
                    string = "1"
                case 1:
                    string = "2"
                case 2:
                    string = "3"
                case 3:
                    string = "4"
                case 4:
                    string = "5"
                case 5:
                    string = "6"
                case 6:
                    string = "7"
                case 7:
                    string = "8"
                default:
                    break
                }
            }
            else {
                switch idx {
                case 0:
                    string = "8"
                case 1:
                    string = "7"
                case 2:
                    string = "6"
                case 3:
                    string = "5"
                case 4:
                    string = "4"
                case 5:
                    string = "3"
                case 6:
                    string = "2"
                case 7:
                    string = "1"
                default:
                    break
                }
            }
            let x: CGFloat = (1/6)*boardWidth/32
            let y = boardWidth/32+CGFloat(idx+1)*squareLength-(1/2)*squareLength-(1/2)*(boardWidth/32)
            string.draw(at: CGPoint(x: x, y: y), withAttributes: [NSForegroundColorAttributeName : textUIColor(), NSFontAttributeName : UIFont.boldSystemFont(ofSize: boardWidth/32)])
            
        }
    }
}





