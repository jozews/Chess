//
//  PromoteViewController.swift
//  Chess
//
//  Created by Jože Ws on 11/2/15.
//  Copyright © 2015 Self. All rights reserved.
//

import UIKit

protocol PromotePopoverDelegate {
    func promotePopoverPromotedToType(_ type: PieceType, atSquare square: Square)
}

class PromoteViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    let viewSize: CGFloat
    let square: Square
    let promoteColor: PieceColor
    let delegate: PromotePopoverDelegate
    
    init(viewSize: CGFloat, square: Square, promoteColor: PieceColor, delegate: PromotePopoverDelegate) {
        self.viewSize = viewSize
        self.square = square
        self.promoteColor = promoteColor
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        self.popoverPresentationController!.delegate = self
        
        let queenButton = UIButton(frame: CGRect(x: 0*viewSize, y: 0, width: viewSize, height: viewSize))
        queenButton.setImage(UIImage(named: imageNameForPieceType(.queen, pieceColor: promoteColor)), for: UIControlState())
        queenButton.tag = 0
        queenButton.addTarget(self, action: #selector(PromoteViewController.buttonHandler(_:)), for: UIControlEvents.touchUpInside)
        view.addSubview(queenButton)
        
        let rookButton = UIButton(frame: CGRect(x: 1*viewSize, y: 0, width: viewSize, height: viewSize))
        rookButton.setImage(UIImage(named: imageNameForPieceType(.rook, pieceColor: promoteColor)), for: UIControlState())
        rookButton.tag = 1
        rookButton.addTarget(self, action: #selector(PromoteViewController.buttonHandler(_:)), for: UIControlEvents.touchUpInside)
        view.addSubview(rookButton)

        let bishopButton = UIButton(frame: CGRect(x: 2*viewSize, y: 0, width: viewSize, height: viewSize))
        bishopButton.setImage(UIImage(named: imageNameForPieceType(.bishop, pieceColor: promoteColor)), for: UIControlState())
        bishopButton.tag = 2
        bishopButton.addTarget(self, action: #selector(PromoteViewController.buttonHandler(_:)), for: UIControlEvents.touchUpInside)
        view.addSubview(bishopButton)

        let knightButton = UIButton(frame: CGRect(x: 3*viewSize, y: 0, width: viewSize, height: viewSize))
        knightButton.setImage(UIImage(named: imageNameForPieceType(.knight, pieceColor: promoteColor)), for: UIControlState())
        knightButton.tag = 3
        knightButton.addTarget(self, action: #selector(PromoteViewController.buttonHandler(_:)), for: UIControlEvents.touchUpInside)
        view.addSubview(knightButton)
    }
    
    func buttonHandler(_ sender: UIButton) {
        self.dismiss(animated: true) { () -> Void in
            switch sender.tag {
            case 0:
                self.delegate.promotePopoverPromotedToType(.queen, atSquare: self.square)
            case 1:
                self.delegate.promotePopoverPromotedToType(.rook, atSquare: self.square)
            case 2:
                self.delegate.promotePopoverPromotedToType(.bishop, atSquare: self.square)
            case 3:
                self.delegate.promotePopoverPromotedToType(.knight, atSquare: self.square)
            default:
                break
            }
        }
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return false
    }
    
}






