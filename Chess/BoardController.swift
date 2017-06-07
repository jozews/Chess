//
//  BoardViewController.swift
//  Chess
//
//  Created by Jože Ws on 10/27/15.
//  Copyright © 2015 Self. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class BoardController: UIViewController, BackgroundViewDelegate, PromotePopoverDelegate, BoardViewDelegate, BoardDelegate, UIPickerViewDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate {
    
    // MARK: BoardView Vars
    
    var boardView: BoardView!
    var board: Board!
    var boardOrientation: PieceColor = .light
    
    var pieceViews = [Square: PieceView]()
    var touch: UITouch?
    var sq0: Square? = nil
    var sqBegan: Square? = nil
    var possibleSqs = [Square]()
    
    var positionIndex = 0
    
    // MARK: Sideview Vars
    
    var localName = "" {
        didSet {
            localNameLabel.text = localName
        }
    }
    var nearbyName = "" {
        didSet {
            nearbyNameLabel.text = nearbyName
        }
    }
    let timeControls = [TimeControl(initial: 60, bonus: 0), TimeControl(initial: 60, bonus: 1), TimeControl(initial: 180, bonus: 0), TimeControl(initial: 180, bonus: 2), TimeControl(initial: 300, bonus: 0), TimeControl(initial: 300, bonus: 4), TimeControl(initial: 600, bonus: 0), TimeControl(initial: 900, bonus: 0)]
    
    var timeControlIdx0 = 4 {
        didSet {
            time0 = timeControl0.initial
        }
    }
    var timeControlIdx1 = 4 {
        didSet {
            time1 = timeControl1.initial
        }
    }
    var timeControl0: TimeControl {
        get {
            return timeControls[timeControlIdx0]
        }
    }
    var timeControl1: TimeControl {
        get {
            return timeControls[timeControlIdx1]
        }
    }
    var time0: Double = 300 {
        didSet {
            time0Label.text = timeStringFromSeconds(time0)
        }
    }
    var time1: Double = 300 {
        didSet {
            time1Label.text = timeStringFromSeconds(time1)
        }
    }
    
    var localNameLabel: UILabel!
    var nearbyNameLabel: UILabel!
    var time0Label: UILabel!
    var time1Label: UILabel!
    var popTimeControl0Button: UIButton!
    var popTimeControl1Button: UIButton!
    var mainButton: UIButton!
    var activityIndicator: UIActivityIndicatorView!
    var flipButton: UIButton!
    var leftButton: UIButton!
    var rightButton: UIButton!
    
    var leftButtonPressed = false
    var rightButtonPressed = false
    
    var timer: CADisplayLink!

    // MARK: Connection Vars
    
    let serviceType = "Chess-Multi"
    var peerID = MCPeerID(displayName: UIDevice.current.name)
    var session: MCSession!
    var browser: MCNearbyServiceBrowser!
    var deniedPeerIDs = [MCPeerID]()
    var advertiser: MCNearbyServiceAdvertiser!
    
    // MARK: State Vars
    
    var gameIsOn = false
    var boardDismissed = true
    var browsing = false
    var invited = false
    
    // MARK: Constants
    
    let animateDuration = 0.15
    let leftRightHandlerDelay = 0.33
    
    // MARK: View Controller

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        view = BackgroundView(frame: view.frame, delegate: self)

        let boardLength = min(view.frame.height, view.frame.width)
        let landsLength = max(view.frame.height, view.frame.width)
        let sideWidth = landsLength-boardLength
        
        boardView = BoardView(origin: CGPoint(x: boardLength/32, y: boardLength/32), length: (15/16)*boardLength, delegate: self)
        view.addSubview(self.boardView!)
        
        board = Board(pieces: standardPieceSet(), delegate: self)
        presentPosition(board.lastPosition)
        
        localNameLabel = UILabel(frame: CGRect(x: landsLength-sideWidth, y: boardView.frame.origin.y+(7+1/2)*boardView.squareLength, width: sideWidth, height: (3/8)*boardView.squareLength))
        localNameLabel.textAlignment = NSTextAlignment.center
        localNameLabel.text = ""
        localNameLabel.textColor = UIColor.black
        localNameLabel.font = UIFont.systemFont(ofSize: localNameLabel.frame.height)
        localNameLabel.adjustsFontSizeToFitWidth = true
        view.addSubview(localNameLabel)
        
        nearbyNameLabel = UILabel(frame: CGRect(x: landsLength-sideWidth, y: boardView.frame.origin.y+(1/8)*boardView.squareLength, width: sideWidth, height: (3/8)*boardView.squareLength))
        nearbyNameLabel.textAlignment = .center
        nearbyNameLabel.text = ""
        nearbyNameLabel.textColor = UIColor.black
        nearbyNameLabel.font = UIFont.systemFont(ofSize: nearbyNameLabel
            .frame.height)
        nearbyNameLabel.adjustsFontSizeToFitWidth = true
        view.addSubview(nearbyNameLabel)

        time0Label = UILabel(frame: CGRect(x: landsLength-sideWidth, y: boardView.frame.origin.y+(6+1/2)*boardView.squareLength, width: sideWidth, height: boardView.squareLength))
        time0Label.textAlignment = .center
        time0Label.text = timeStringFromSeconds(time0)
        time0Label.textColor = UIColor.black
        time0Label.font = UIFont(name: "Arial", size: time0Label.frame.height)
        view.addSubview(time0Label)

        time1Label = UILabel(frame: CGRect(x: landsLength-sideWidth, y: boardView.frame.origin.y+(1/2)*boardView.squareLength, width: sideWidth, height: boardView.squareLength))
        time1Label.textAlignment = .center
        time1Label.text = timeStringFromSeconds(time1)
        time1Label.textColor = UIColor.black
        time1Label.font = UIFont(name: "Arial", size: time1Label.frame.height)
        view.addSubview(time1Label)

        popTimeControl0Button = UIButton(frame: CGRect(x: landsLength-(1/2)*sideWidth-(1/2/2)*boardView.squareLength, y: boardView.frame.origin.y+(6)*boardView.squareLength, width: (1/2)*boardView.squareLength, height: (1/2)*boardView.squareLength))
        popTimeControl0Button.setImage(UIImage(named: "Up.png"), for: UIControlState())
        popTimeControl0Button.addTarget(self, action: #selector(BoardController.popTimeControl0Handler(_:)), for: .touchUpInside)
        popTimeControl0Button.tag = 0
        view.addSubview(popTimeControl0Button)

        popTimeControl1Button = UIButton(frame: CGRect(x: landsLength-(1/2)*sideWidth-(1/2/2)*boardView.squareLength, y: boardView.frame.origin.y+(1+1/2)*boardView.squareLength, width: (1/2)*boardView.squareLength, height: (1/2)*boardView.squareLength))
        popTimeControl1Button.setImage(UIImage(named: "Down.png"), for: UIControlState())
        popTimeControl1Button.addTarget(self, action: #selector(BoardController.popTimeControl1Handler(_:)), for: .touchUpInside)
        popTimeControl1Button.tag = 1
        view.addSubview(popTimeControl1Button)
        
        mainButton = UIButton(type: .system)
        mainButton.frame.size = CGSize(width: (3/4)*sideWidth, height: (1/2)*boardView.squareLength)
        mainButton.center = CGPoint(x: landsLength-(1/2)*sideWidth, y: (1/2)*boardLength)
        mainButton.titleLabel!.font = UIFont.systemFont(ofSize: mainButton.frame.height)
        mainButton.setTitle("connect", for: UIControlState())
        mainButton.titleLabel!.textAlignment = .center
        mainButton.addTarget(self, action: #selector(BoardController.mainHandler), for: .touchUpInside)
        mainButton.tag = 0
        view.addSubview(mainButton)
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.center = mainButton.center
        activityIndicator.color = UIColor.darkGray
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        leftButton = UIButton(frame: CGRect(x: landsLength-(1/2)*sideWidth-(4/5)*boardView.squareLength, y: boardView.frame.origin.y+(3+1/2)*boardView.squareLength-(4/5)*boardView.squareLength, width: (4/5)*boardView.squareLength, height: (4/5)*boardView.squareLength))
        leftButton.setImage(UIImage(named: "Undo.png"), for: UIControlState())
        leftButton.isMultipleTouchEnabled = false
        leftButton.addTarget(self, action: #selector(BoardController.leftDownHandler), for: .touchDown)
        leftButton.addTarget(self, action: #selector(BoardController.leftUpHandler), for: .touchUpInside)
        leftButton.addTarget(self, action: #selector(BoardController.leftRepeatHandler), for: .touchDownRepeat)
        view.addSubview(leftButton)
                
        rightButton = UIButton(frame: CGRect(x: landsLength-(1/2)*sideWidth, y: boardView.frame.origin.y+(3+1/2)*boardView.squareLength-(4/5)*boardView.squareLength, width: (4/5)*boardView.squareLength, height: (4/5)*boardView.squareLength))
        rightButton.setImage(UIImage(named: "Redo.png"), for: UIControlState())
        rightButton.isMultipleTouchEnabled = false
        rightButton.addTarget(self, action: #selector(BoardController.rightDownHandler), for: .touchDown)
        rightButton.addTarget(self, action: #selector(BoardController.rightUpHandler), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(BoardController.rightRepeatHandler), for: .touchDownRepeat)
        view.addSubview(rightButton)
        
        flipButton = UIButton(frame: CGRect(x: landsLength-(1/2)*sideWidth-(1/2)*(4.2/5)*boardView.squareLength, y: boardView.frame.origin.y+(4+1/2)*boardView.squareLength, width: (4.2/5)*boardView.squareLength, height: (4.2/5)*boardView.squareLength))
        flipButton.setImage(UIImage(named: "Flip.png"), for: UIControlState())
        flipButton.addTarget(self, action: #selector(BoardController.flipHandler), for: .touchUpInside)
        view.addSubview(flipButton)
        
        timer = CADisplayLink(target: self, selector: #selector(BoardController.timerHandler))
        timer.isPaused = true
        timer.frameInterval = 60
        timer.add(to: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        
        leftButton.isHidden = true
        rightButton.isHidden = true
        flipButton.isHidden = true
    }
    
    override var prefersStatusBarHidden : Bool {
        return true;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("receive memory warning")
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    // MARK: Utilities
    
    func presentPosition(_ position: [Square : Piece]) {
        for file in 0...7 {
            for rank in 0...7 {
                let square = Square(file: file, rank: rank)
                let pieceView = pieceViews[square]
                let piece = position[square]
                if piece == nil && pieceView == nil {
                    continue
                }
                if piece != nil && pieceView == nil {
                    let newPieceView = PieceView(boardView: boardView, type: piece!.type, color: piece!.color)
                    newPieceView.frame.origin = boardView.originOfSquare(square)
                    pieceViews.updateValue(newPieceView, forKey: square)
                    view.addSubview(newPieceView)
                }
                if piece == nil && pieceView != nil {
                    pieceView!.removeFromSuperview()
                    pieceViews[square] = nil
                }
                if piece != nil && pieceView != nil {
                    if piece!.color == pieceView!.color && piece!.type == pieceView!.type {
                        continue
                    }
                    else {
                        pieceView!.type = piece!.type
                        pieceView!.color  = piece!.color
                    }
                }
            }
        }
    }

    func flipCurrentPosition() {
        view.setNeedsDisplay()
        for square in pieceViews.keys {
            if let pieceView = pieceViews[square] {
                pieceView.frame.origin = boardView.originOfSquare(square)
            }
        }
    }
    
    func presentPreviousPosition() -> Bool {
        if positionIndex<=0 {
            return false
        }
        let update = board.updates[positionIndex-1]
        let pieceView = pieceViews.removeValue(forKey: update.move.1)!
        if update.promotionType != nil {
            pieceView.type = .pawn
        }
        positionIndex -= 1
        pieceViews.updateValue(pieceView, forKey: update.move.0)
        UIView.animate(withDuration: animateDuration, animations: { () -> Void in
            pieceView.frame.origin = self.boardView.originOfSquare(update.move.0)
        }) 
        if update.capture.piece != nil {
            let captureView = PieceView(boardView: boardView, type: update.capture.piece!.type, color: update.capture.piece!.color)
            captureView.frame.origin = boardView.originOfSquare(update.capture.square!)
            pieceViews[update.capture.square!] = captureView
            view.addSubview(captureView)
        }
        view.bringSubview(toFront: pieceView)
        if update.castle.0 != nil {
            let rookView = pieceViews.removeValue(forKey: update.castle.1!)
            pieceViews.updateValue(rookView!, forKey: update.castle.0!)
            rookView!.frame.origin = boardView.originOfSquare(update.castle.0!)
        }
        boardView.move = (update.move.0, update.move.1)
        return true
    }
    
    
    func presentNextPosition(_ animated: Bool) -> Bool {
        if positionIndex>=board.positions.count-1 {
            return false
        }
        let update = board.updates[positionIndex]
        var captureView: PieceView? = nil
        if update.capture.piece != nil {
            captureView = self.pieceViews.removeValue(forKey: update.capture.square!)
        }
        let pieceView = self.pieceViews.removeValue(forKey: update.move.0)!
        view.bringSubview(toFront: pieceView)
        if update.promotionType != nil {
            pieceView.type = update.promotionType!
        }
        self.pieceViews.updateValue(pieceView, forKey: update.move.1)
        if animated {
            UIView.animate(withDuration: animateDuration, animations: { () -> Void in
                pieceView.frame.origin = self.boardView.originOfSquare(update.move.1)

                }, completion: { (flag: Bool) -> Void in
                    if captureView != nil {
                        captureView!.removeFromSuperview()
                    }
            })
        }
        else {
            pieceView.frame.origin = self.boardView.originOfSquare(update.move.1)
            if captureView != nil {
                captureView!.removeFromSuperview()
            }
        }
        if update.castle.0 != nil {
            let rookView = self.pieceViews.removeValue(forKey: update.castle.0!)
            self.pieceViews.updateValue(rookView!, forKey: update.castle.1!)
            rookView!.frame.origin = self.boardView.originOfSquare(update.castle.1!)
        }
        self.boardView.move = (update.move.0, update.move.1)
        self.positionIndex += 1
        return true
    }
    
    func noPeersFound() {
        if browsing {
            browsing = false
            self.activityIndicator.stopAnimating()
            browser.stopBrowsingForPeers()
            let title = deniedPeerIDs.count == 0 ? "No devices were found" : "No other devices were found"
            let alert = UIAlertController(title: title, message: "Make sure Wifi and Bluetooth is enabled for both devices", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) -> Void in
                self.mainButton.isHidden = false
            })
            alert.addAction(defaultAction)
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: Responder
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if touch != nil {
            return
        }
        
        touch = touches.first!
        
        sqBegan = boardView.squareAtCoordinatePoint(touch!.location(in: view))

        if sq0 != nil {
            return
        }
        
        if let pieceView = touch!.view as? PieceView {
            view.bringSubview(toFront: pieceView)
            if boardDismissed && positionIndex == board.positions.count-1 {
                boardView.sq0 = sqBegan
                if !session.connectedPeers.isEmpty ? board.turnColor == boardOrientation : true {
                    boardView.sq1s = board.possibleSquaresFromSquare(sqBegan!)
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if touch == nil {
            return
        }
        
        if !touches.contains(touch!) {
            return
        }
        
        if let pieceView = touch!.view as? PieceView {
            pieceView.center = touch!.location(in: view)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if touch == nil {
            return
        }
        if !touches.contains(touch!) {
            return
        }
        let pieceView = touch!.view as? PieceView
        let sqEnded = boardView.squareAtCoordinatePoint(touch!.location(in: view))
        touch = nil
        if sqBegan == sqEnded {
            if sq0 == nil {
                sq0 = sqBegan
                if pieceView != nil {
                    pieceView!.frame.origin = boardView.originOfSquare(sqBegan!)
                }
                return
            }
        }
        else {
            sq0 = sqBegan
        }
        if sq0 == nil {
            if pieceView != nil {
                pieceView!.frame.origin = boardView.originOfSquare(sqBegan!)
            }
            return
        }
        let update = board.positionUpdateFromSquare(sq0!, toSquare: sqEnded)
        sq0 = nil
        boardView.sq0 = nil
        boardView.sq1s = []
        if update == nil  {
            if pieceView != nil {
                pieceView!.frame.origin = boardView.originOfSquare(sqBegan!)
            }
            return
        }
        if gameIsOn && positionIndex != board.positions.count-1 {
            if pieceView != nil {
                pieceView!.frame.origin = boardView.originOfSquare(sqBegan!)
            }
            rightRepeatHandler()
            return
        }
        if !gameIsOn && boardDismissed {
            timer.isPaused = false
            mainButton.setTitle("end", for: UIControlState())
            popTimeControl0Button.isHidden = true
            popTimeControl1Button.isHidden = true
            leftButton.isHidden = false
            rightButton.isHidden = false
            gameIsOn = true
            if session.connectedPeers.isEmpty {
                flipButton.isHidden = false
            }
            else {
                flipButton.isHidden = true
                do {
                    let info = ["start" : "true"]
                    try self.session.send(NSKeyedArchiver.archivedData(withRootObject: info), toPeers: self.session.connectedPeers, with: .reliable)
                }
                catch {}
            }
        }
        if !gameIsOn {
            if pieceView != nil {
                pieceView!.frame.origin = boardView.originOfSquare(sqBegan!)
            }
            return
        }
        if !session.connectedPeers.isEmpty && board.turnColor != boardOrientation {
            if pieceView != nil {
                pieceView!.frame.origin = boardView.originOfSquare(sqBegan!)
            }
            return
        }
        if board.positions.count>1 {
            mainButton.setTitle("resign", for: UIControlState())
        }
        _ = board.addPositionUpdate(update!)
        _ = presentNextPosition(false)
        if !session.connectedPeers.isEmpty {
            do {
                try session.send(NSKeyedArchiver.archivedData(withRootObject: update!), toPeers: session.connectedPeers, with: .reliable)
            }
            catch { }
        }
        if board.promoteSquare == nil {
            let kingStatus = board.kingStatusOfTurnColor()
            if kingStatus == .normal {
                boardView.squareCheck = nil
            }
            else if kingStatus == .checked {
                boardView.squareCheck = board.squareOfKingOfColor(board.turnColor)
            }
            if kingStatus == .checkmated || kingStatus == .stalemated {
                timer.isPaused = true
                let alertController = UIAlertController(title: kingStatus == .checkmated ? !session.connectedPeers.isEmpty ? "You Win By Checkmate" : "\(oppositeColor(board.turnColor)) Wins By Checkmate" : "Draw By Stalemate", message: nil, preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) -> Void in
                    if self.gameIsOn {
                        self.boardDismissed = false
                        self.mainButton.setTitle("new", for: UIControlState())
                        self.gameIsOn = false
                    }
                })
                alertController.addAction(alertAction)
                present(alertController, animated: true, completion: nil)
            }
            else {
                if gameIsOn {
                    if board.turnColor == boardOrientation {
                        time1 += timeControl1.bonus
                        let secToNextTimeUpdate = time0.truncatingRemainder(dividingBy: 1)
                        timer.frameInterval = secToNextTimeUpdate == 0 ? 60 : Int(secToNextTimeUpdate*60)
                    }
                    else {
                        time0 += timeControl0.bonus
                        let secToNextTimeUpdate = time1.truncatingRemainder(dividingBy: 1)
                        timer.frameInterval = secToNextTimeUpdate == 0 ? 60 : Int(secToNextTimeUpdate*60)
                        if !session.connectedPeers.isEmpty {
                            do {
                                let info = ["time" : "\(time0)"]
                                try session.send(NSKeyedArchiver.archivedData(withRootObject: info), toPeers: session.connectedPeers, with: .reliable)
                            }
                            catch {}
                        }
                    }
                }
            }
            if !session.connectedPeers.isEmpty {
                do {
                    let info = ["kingStatus" : "\(kingStatus.rawValue)"]
                    try session.send(NSKeyedArchiver.archivedData(withRootObject: info), toPeers: session.connectedPeers, with: .reliable)
                }
                catch {}
            }
        }
    }
    
    // MARK: Handlers
    
    func mainHandler() {
        
        // Game starts with connection
        if !gameIsOn && boardDismissed && !self.session.connectedPeers.isEmpty {
            mainButton.setTitle("end", for: UIControlState())
            popTimeControl0Button.isHidden = true
            popTimeControl1Button.isHidden = true
            leftButton.isHidden = false
            rightButton.isHidden = false
            flipButton.isHidden = true
            gameIsOn = true
            let info = ["start" : "true"]
            do {
                try self.session.send(NSKeyedArchiver.archivedData(withRootObject: info), toPeers: self.session.connectedPeers, with: .reliable)
            }
            catch {}
            return
        }
        // Browsing starts for peers
        if !gameIsOn && boardDismissed && self.session.connectedPeers.isEmpty {
            mainButton.isHidden = true
            activityIndicator.startAnimating()
            browser.startBrowsingForPeers()
            browsing = true
            perform(#selector(BoardController.noPeersFound), with: nil, afterDelay: 10)
            return
        }
        // New game presented
        if !gameIsOn && !boardDismissed {
            time0 = self.timeControl0.initial
            time1 = self.timeControl1.initial
            popTimeControl0Button.isHidden = false
            popTimeControl1Button.isHidden = false
            leftButton.isHidden = true
            rightButton.isHidden = true
            board.new(standardPieceSet())
            positionIndex = 0
            presentPosition(board.positions[positionIndex])
            boardView.move = (nil, nil)
            boardDismissed = true
            if self.session.connectedPeers.isEmpty {
                flipButton.isHidden = true
                mainButton.setTitle("connect", for: UIControlState())
            }
            else {
                flipButton.isHidden = false
                mainButton.setTitle("start", for: UIControlState())
                let info = ["new" : "true"]
                do {
                    try self.session.send(NSKeyedArchiver.archivedData(withRootObject: info), toPeers: self.session.connectedPeers, with: .reliable)
                }
                catch { }
            }
            return
        }
        // Game resigned
        if gameIsOn && board.positions.count>2 {
            let alert = UIAlertController(title: "Resign", message: "Do you want to resign?", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "No", style: .cancel, handler: { (alertAction: UIAlertAction) -> Void in
            })
            let destructiveAction = UIAlertAction(title: "Yes", style: .destructive, handler: { (alertAction: UIAlertAction) -> Void in
                self.boardDismissed = false
                self.timer.isPaused = true
                self.mainButton.setTitle("new", for: UIControlState())
                self.gameIsOn = false
                self.boardView.sq0 = nil
                self.boardView.sq1s = []
                self.boardView.squareCheck = nil
                if !self.session.connectedPeers.isEmpty {
                    let info = ["resign" : "true"]
                    do {
                        try self.session.send(NSKeyedArchiver.archivedData(withRootObject: info), toPeers: self.session.connectedPeers, with: .reliable)
                    }
                    catch {}
                }
            })
            alert.addAction(cancelAction)
            alert.addAction(destructiveAction)
            present(alert, animated: true, completion: nil)
            return
        }
        // Game ended
        if gameIsOn && board.positions.count<=2 {
            timer.isPaused = true
            popTimeControl0Button.isHidden = false
            popTimeControl1Button.isHidden = false
            time0 = timeControl0.initial
            time1 = timeControl1.initial
            leftButton.isHidden = true
            rightButton.isHidden = true
            flipButton.isHidden = true
            board.new(standardPieceSet())
            positionIndex = 0
            presentPosition(board.positions[positionIndex])
            self.boardView.sq0 = nil
            self.boardView.sq1s = []
            self.boardView.squareCheck = nil
            boardView.move = (nil, nil)
            gameIsOn = false
            if self.session.connectedPeers.isEmpty {
                flipButton.isHidden = true
                mainButton.setTitle("connect", for: UIControlState())
            }
            else {
                flipButton.isHidden = false
                mainButton.setTitle("start", for: UIControlState())
                let info = ["end" : "true"]
                do {
                    try self.session.send(NSKeyedArchiver.archivedData(withRootObject: info), toPeers: self.session.connectedPeers, with: .reliable)
                }
                catch {}
            }
            return
        }
    }
    
    func leftHandlerLoop() {
        if !leftButton.isSelected {
            return
        }
        _ = presentPreviousPosition()
        perform(#selector(BoardController.leftHandlerLoop), with: nil, afterDelay: leftRightHandlerDelay)
    }
    
    func leftDownHandler() {
        leftButton.isSelected = true
        _ = presentPreviousPosition()
        perform(#selector(BoardController.leftHandlerLoop), with: nil, afterDelay: leftRightHandlerDelay)
    }
    
    func leftUpHandler() {
        leftButton.isSelected = false
    }
    
    func leftRepeatHandler() {
        while presentPreviousPosition() {}
    }
    
    func rightHandlerLoop() {
        if !rightButton.isSelected {
            return
        }
        _ = presentNextPosition(true)
        perform(#selector(BoardController.rightHandlerLoop), with: nil, afterDelay: leftRightHandlerDelay)
    }
    
    func rightDownHandler() {
        rightButton.isSelected = true
        _ = presentNextPosition(true)
        perform(#selector(BoardController.rightHandlerLoop), with: nil, afterDelay: leftRightHandlerDelay)
    }
    
    func rightUpHandler() {
        rightButton.isSelected = false
    }
    
    func rightRepeatHandler() {
        while presentNextPosition(false) {}
    }
    
    func timerHandler() {
        timer.frameInterval = 60
        if boardOrientation == board.turnColor {
            time0 -= 1
            time0 = Double(Int(time0))
            if time0<=0 {
                timer.isPaused = true
                let alertController = UIAlertController(title: !session.connectedPeers.isEmpty ? "You Lose On Time" : "\(oppositeColor(boardOrientation)) Wins On Time", message: nil, preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) -> Void in
                    if self.gameIsOn {
                        self.boardDismissed = false
                        self.mainButton.setTitle("new", for: UIControlState())
                        self.presentPosition(self.board.positions[self.positionIndex])
                        self.boardView.sq0 = nil
                        self.boardView.sq1s = []
                        self.boardView.squareCheck = nil
                        self.touch = nil
                        self.gameIsOn = false
                    }
                })
                alertController.addAction(alertAction)
                present(alertController, animated: true, completion: nil)
                if !self.session.connectedPeers.isEmpty {
                    let info = ["timeOut" : "true"]
                    do {
                        try self.session.send(NSKeyedArchiver.archivedData(withRootObject: info), toPeers: self.session.connectedPeers, with: .reliable)
                    }
                    catch {}
                }
            }
        }
        else {
            time1 -= 1
            time1 = Double(Int(time1))
            if time1<=0 {
                if session.connectedPeers.isEmpty {
                    timer.isPaused = true
                    let alertController = UIAlertController(title: "\(boardOrientation) Wins On Time", message: nil, preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) -> Void in
                        if self.gameIsOn {
                            self.boardDismissed = false
                            self.mainButton.setTitle("new", for: UIControlState())
                            self.presentPosition(self.board.positions[self.positionIndex])
                            self.boardView.sq0 = nil
                            self.boardView.sq1s = []
                            self.boardView.squareCheck = nil
                            self.touch = nil
                            self.gameIsOn = false
                        }
                    })
                    alertController.addAction(alertAction)
                    present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func flipHandler() {
        if gameIsOn {
            let lowerTime0 = time0
            let upperTime0 = time1
            time0 = upperTime0
            time1 = lowerTime0
        }
        let move = boardView.move
        boardView.move = (nil, nil)
        boardOrientation = boardOrientation == .light ? .dark : .light
        flipCurrentPosition()
        boardView.move = move
        if !self.session.connectedPeers.isEmpty {
            let info = ["boardOrientation" : "\(boardOrientation)"]
            do {
                try self.session.send(NSKeyedArchiver.archivedData(withRootObject: info), toPeers: self.session.connectedPeers, with: .reliable)
            }
            catch {}
        }
    }
    
    func popTimeControl0Handler(_ sender: UIButton) {
        
        // user action sheet for iphone
        if UIDevice.current.userInterfaceIdiom == .phone {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            for (idx, timeControl) in timeControls.enumerated() {
                let action = UIAlertAction(title: timeControl.title, style: .default, handler: { (action: UIAlertAction) in
                    self.updateTimeControl(tag: 0, withIndex: idx)
                })
                actionSheet.addAction(action)
            }
            let cancelAction = UIAlertAction(title: "cancel", style: .cancel, handler: nil)
            actionSheet.addAction(cancelAction)
            present(actionSheet, animated: true, completion: nil)
        }
            
        // use popover for iPad
        else {
            let timeControlPop = TimeControlPopover(selectIndex: timeControlIdx0, numberOfComponents: timeControls.count)
            timeControlPop.modalPresentationStyle = .popover
            let sideWidth = view.frame.width-boardView.frame.width-view.frame.height/16
            timeControlPop.preferredContentSize = CGSize(width: (4/5)*sideWidth, height: (2)*boardView.squareLength)
            let setTimePresentation = timeControlPop.popoverPresentationController!
            setTimePresentation.permittedArrowDirections = .down
            setTimePresentation.sourceView = popTimeControl0Button
            setTimePresentation.sourceRect = CGRect(x: (1/2)*popTimeControl0Button.frame.width, y: 0, width: 0, height: 0)
            setTimePresentation.sourceRect = (sender.tag==0 ? CGRect(x: (1/2)*popTimeControl0Button.frame.width, y: 0, width: 0, height: 0):CGRect(x: (1/2)*popTimeControl0Button.frame.width, y: popTimeControl0Button.frame.height, width: 0, height: 0))
            present(timeControlPop, animated: true) { () -> Void in
                timeControlPop.timePicker.delegate = self
                timeControlPop.timePicker.tag = 0
            }
        }
    }
    
    func popTimeControl1Handler(_ sender: UIButton) {
        // user action sheet for iphone
        if UIDevice.current.userInterfaceIdiom == .phone {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            for (idx, timeControl) in timeControls.enumerated() {
                let action = UIAlertAction(title: timeControl.title, style: .default, handler: { (action: UIAlertAction) in
                    self.updateTimeControl(tag: 0, withIndex: idx)
                })
                actionSheet.addAction(action)
            }
            let cancelAction = UIAlertAction(title: "cancel", style: .cancel, handler: nil)
            actionSheet.addAction(cancelAction)
            present(actionSheet, animated: true, completion: nil)
        }
        else {
            let timeControlPop = TimeControlPopover(selectIndex: timeControlIdx1, numberOfComponents: timeControls.count)
            timeControlPop.modalPresentationStyle = .popover
            let sideWidth = view.frame.width-boardView.frame.width-view.frame.height/16
            timeControlPop.preferredContentSize = CGSize(width: (4/5)*sideWidth, height: (2)*boardView.squareLength)
            let setTimePresentation = timeControlPop.popoverPresentationController!
            setTimePresentation.permittedArrowDirections = .up
            setTimePresentation.sourceView = popTimeControl1Button
            setTimePresentation.sourceRect = CGRect(x: (1/2)*popTimeControl1Button.frame.width,y: popTimeControl1Button.frame.height, width: 0, height: 0)
            present(timeControlPop, animated: true) { () -> Void in
                timeControlPop.timePicker.delegate = self
                timeControlPop.timePicker.tag = 1
            }
        }
    }
    
    // MARK: Board Delegate
    
    func boardPromotedAtSquare(_ sq: Square) {
        let promotePopover = PromoteViewController(viewSize: boardView.squareLength, square: sq, promoteColor: board.turnColor, delegate: self)
        promotePopover.preferredContentSize = CGSize(width: 4*boardView!.squareLength, height: boardView!.squareLength)
        promotePopover.modalPresentationStyle = .popover
        let promotePresentaton = promotePopover.popoverPresentationController!
        promotePresentaton.sourceView = boardView!
        let originOfSq = boardView.originOfSquare(sq)
        promotePresentaton.permittedArrowDirections = boardOrientation == .light ? .up : .down
        promotePresentaton.sourceRect = CGRect(x: originOfSq.x, y: originOfSq.y, width: boardView!.squareLength,  height: boardView!.squareLength)
        self.present(promotePopover, animated: true, completion: nil)
    }
    
    // MARK: Promote Delegate
    
    func promotePopoverPromotedToType(_ type: PieceType, atSquare square: Square) {
        board.promoteToType(type)
        pieceViews[square]!.type = type
        let kingStatus = board.kingStatusOfTurnColor()
        if !session.connectedPeers.isEmpty {
            do {
                let info = ["promote" : "\(type.rawValue)"]
                try session.send(NSKeyedArchiver.archivedData(withRootObject: info), toPeers: session.connectedPeers, with: .reliable)
            }
            catch {}
        }
        if kingStatus == .normal {
            boardView.squareCheck = nil
        }
        else if kingStatus == .checked {
            boardView.squareCheck = board.squareOfKingOfColor(board.turnColor)
        }
        if kingStatus == .checkmated || kingStatus == .stalemated {
            timer.isPaused = true
            let alertController = UIAlertController(title: kingStatus == .checkmated ? !session.connectedPeers.isEmpty ? "You Win By Checkmate" : "\(oppositeColor(board.turnColor)) Wins By Checkmate" : "Draw By Stalemate", message: nil, preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) -> Void in
                if self.gameIsOn {
                    self.boardDismissed = false
                    self.mainButton.setTitle("new", for: UIControlState())
                    self.gameIsOn = false
                }
            })
            alertController.addAction(alertAction)
            present(alertController, animated: true, completion: nil)
        }
        else {
            if gameIsOn {
                timer.isPaused = false
                if board.turnColor == boardOrientation {
                    time1 += timeControl1.bonus
                    let secToNextTimeUpdate = time0.truncatingRemainder(dividingBy: 1)
                    timer.frameInterval = secToNextTimeUpdate == 0 ? 60 : Int(secToNextTimeUpdate*60)
                }
                else {
                    time0 += timeControl0.bonus
                    let secToNextTimeUpdate = time1.truncatingRemainder(dividingBy: 1)
                    timer.frameInterval = secToNextTimeUpdate == 0 ? 60 : Int(secToNextTimeUpdate*60)
                    if !session.connectedPeers.isEmpty {
                        do {
                            let info = ["time" : "\(time0)"]
                            try session.send(NSKeyedArchiver.archivedData(withRootObject: info), toPeers: session.connectedPeers, with: .reliable)
                        }
                        catch {}
                    }
                }
            }
        }
        if kingStatus != .normal && !session.connectedPeers.isEmpty {
            do {
                let info = ["kingStatus" : "\(kingStatus.rawValue)"]
                try session.send(NSKeyedArchiver.archivedData(withRootObject: info), toPeers: session.connectedPeers, with: .reliable)
            }
            catch {}
        }
    }
    
    // MARK: Picker View Delegate

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        updateTimeControl(tag: pickerView.tag, withIndex: row)
    }
    
    func updateTimeControl(tag: Int, withIndex index: Int) {
        if tag == 0 {
            self.presentedViewController!.dismiss(animated: true, completion: { () -> Void in
                self.timeControlIdx0 = index
            })
        }
        else if tag == 1 {
            self.presentedViewController!.dismiss(animated: true, completion: { () -> Void in
                self.timeControlIdx1 = index
            })
        }
        if !session.connectedPeers.isEmpty {
            let info = ["timeControlIdx\(tag)" : "\(index)"]
            do {
                try self.session.send(NSKeyedArchiver.archivedData(withRootObject: info), toPeers: self.session.connectedPeers, with: .reliable)
            }
            catch {}
        }
    }
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?  {
        return timeControls[row].title
    }
    
    // MARK: Session Delegate
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        OperationQueue.main.addOperation { () -> Void in
            if state == .connected {
                self.activityIndicator.stopAnimating()
                self.mainButton.isHidden = false
                self.mainButton.setTitle("start", for: UIControlState())
                self.localName = self.peerID.displayName
                self.nearbyName = peerID.displayName
                self.flipButton.isHidden = false
                if self.invited {
                    let info = ["boardOrientation" : "\(self.boardOrientation)", "timeControlIdx0" : "\(self.timeControlIdx0)", "timeControlIdx1" :  "\(self.timeControlIdx1)"]
                    do {
                        try session.send(NSKeyedArchiver.archivedData(withRootObject: info), toPeers: self.session.connectedPeers, with: .reliable)
                    }
                    catch {}
                }
            }
            else if state == .connecting {
                self.mainButton.isHidden = true
                self.activityIndicator.startAnimating()
                if self.gameIsOn {
                    self.timer.isPaused = true
                    self.time0 = self.timeControl0.initial
                    self.time1 = self.timeControl1.initial
                    self.board.new(standardPieceSet())
                    self.presentPosition(self.board.lastPosition)
                    self.leftButton.isHidden = true
                    self.rightButton.isHidden = true
                    self.gameIsOn = false
                }
                if !self.boardDismissed {
                    self.time0 = self.timeControl0.initial
                    self.time1 = self.timeControl1.initial
                    self.board.new(standardPieceSet())
                    self.presentPosition(self.board.lastPosition)
                    self.leftButton.isHidden = true
                    self.rightButton.isHidden = true
                    self.flipButton.isHidden = true
                    self.boardDismissed = true
                }
            }
            else if state == .notConnected {
                let failedAlert = UIAlertController(title: "Connection failed", message: nil, preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ok", style: .cancel, handler: { (alertAction: UIAlertAction) -> Void in
                    self.activityIndicator.stopAnimating()
                    self.mainButton.isHidden = false
                    self.mainButton.setTitle("connect", for: UIControlState())
                    self.localName = ""
                    self.nearbyName = ""
                    self.flipButton.isHidden = true
                    if self.gameIsOn {
                        self.timer.isPaused = true
                        self.time0 = self.timeControl0.initial
                        self.time1 = self.timeControl1.initial
                        self.board.new(standardPieceSet())
                        self.presentPosition(self.board.lastPosition)
                        self.leftButton.isHidden = true
                        self.rightButton.isHidden = true
                        self.boardView.move = (nil, nil)
                        self.boardView.squareCheck = nil
                        self.gameIsOn = false
                    }
                    if !self.boardDismissed {
                        self.mainButton.setTitle("new", for: UIControlState())
                    }
                })
                failedAlert.addAction(cancelAction)
                self.present(failedAlert, animated: true, completion: nil)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        OperationQueue.main.addOperation { () -> Void in
            if let update = NSKeyedUnarchiver.unarchiveObject(with: data) as? PositionUpdate {
                self.board.addPositionUpdate(update)
                _ = self.presentNextPosition(true)
                self.timer.frameInterval = self.time0 == 0 ? 60 : Int((self.time0.truncatingRemainder(dividingBy: 1)) * 60)
            }
            else if let info = NSKeyedUnarchiver.unarchiveObject(with: data) as? Dictionary<String, String> {
                if let timeControlIdx0 = info["timeControlIdx0"] {
                    self.timeControlIdx1 = Int(timeControlIdx0)!
                }
                if let timeControlIdx1 = info["timeControlIdx1"] {
                    self.timeControlIdx0 = Int(timeControlIdx1)!
                }
                if let boardOrientation = info["boardOrientation"] {
                    self.boardOrientation = boardOrientation == "Light" ? .dark : .light
                    self.flipCurrentPosition()
                }
                else if let time = info["time"] {
                    self.time1 = Double(time)!
                }
                else if let promote = info["promote"] {
                    let type = PieceType(rawValue: Int(promote)!)!
                    self.board.promoteToType(type)
                    self.pieceViews[self.board.updates.last!.move.1]!.type = type
                }
                else if let _ = info["start"] {
                    self.timer.isPaused = false
                    self.mainButton.setTitle("end", for: UIControlState())
                    self.popTimeControl0Button.isHidden = true
                    self.popTimeControl1Button.isHidden = true
                    self.leftButton.isHidden = false
                    self.rightButton.isHidden = false
                    self.flipButton.isHidden = true
                    self.gameIsOn = true
                }
                else if let _ = info["new"] {
                    self.mainButton.setTitle("start", for: UIControlState())
                    self.time0 = self.timeControl0.initial
                    self.time1 = self.timeControl1.initial
                    self.popTimeControl0Button.isHidden = false
                    self.popTimeControl1Button.isHidden = false
                    self.leftButton.isHidden = true
                    self.rightButton.isHidden = true
                    self.flipButton.isHidden = false
                    self.board.new(standardPieceSet())
                    self.boardView.move = (nil, nil)
                    self.positionIndex = 0
                    self.presentPosition(self.board.positions[self.positionIndex])
                    self.boardDismissed = true
                }
                else if let _ = info["resign"] {
                    self.timer.isPaused = true
                    let alertController = UIAlertController(title: "You Win By Resignation", message: nil, preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) -> Void in
                        self.boardDismissed = false
                        self.mainButton.setTitle("new", for: UIControlState())
                        self.presentPosition(self.board.positions[self.positionIndex])
                        self.touch = nil
                        self.boardView.sq0 = nil
                        self.boardView.sq1s = []
                        self.boardView.squareCheck = nil
                        self.gameIsOn = false
                    })
                    alertController.addAction(alertAction)
                    self.present(alertController, animated: true, completion: nil)
                }
                else if let _ = info["end"] {
                    self.timer.isPaused = true
                    self.mainButton.setTitle("start", for: UIControlState())
                    self.time0 = self.timeControl0.initial
                    self.time1 = self.timeControl1.initial
                    self.popTimeControl0Button.isHidden = false
                    self.popTimeControl1Button.isHidden = false
                    self.leftButton.isHidden = true
                    self.rightButton.isHidden = true
                    self.flipButton.isHidden = false
                    self.board.new(standardPieceSet())
                    self.positionIndex = 0
                    self.presentPosition(self.board.positions[self.positionIndex])
                    self.touch = nil
                    self.boardView.move = (nil, nil)
                    self.gameIsOn = false
                    // play sound
                }
                else if let _ = info["timeOut"] {
                    self.timer.isPaused = true
                    self.time1 = 0
                    let alertController = UIAlertController(title: "You Win On Time", message: nil, preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) -> Void in
                        self.boardDismissed = false
                        self.mainButton.setTitle("new", for: UIControlState())
                        self.presentPosition(self.board.positions[self.positionIndex])
                        self.touch = nil
                        self.boardView.sq0 = nil
                        self.boardView.sq1s = []
                        self.boardView.squareCheck = nil
                        self.gameIsOn = false
                    })
                    alertController.addAction(alertAction)
                    self.present(alertController, animated: true, completion: nil)
                }
                else if let kingStatusRaw = info["kingStatus"] {
                    let kingStatus = KingStatus(rawValue: Int(kingStatusRaw)!)
                    if kingStatus == .normal {
                        self.boardView.squareCheck = nil
                    }
                    else if kingStatus == .checked {
                        self.boardView.squareCheck = self.board.squareOfKingOfColor(self.board.turnColor)
                    }
                    else if kingStatus == .checkmated || kingStatus == .stalemated {
                        self.timer.isPaused = true
                        let alertController = UIAlertController(title: kingStatus == .checkmated ? "You Lose By Checkmate" : "Draw By Stalemate", message: nil, preferredStyle: .alert)
                        let alertAction = UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) -> Void in
                            if self.gameIsOn {
                                self.boardDismissed = false
                                self.mainButton.setTitle("new", for: UIControlState())
                                self.presentPosition(self.board.positions[self.positionIndex])
                                self.touch = nil
                                self.gameIsOn = false
                            }
                        })
                        alertController.addAction(alertAction)
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    // MARK: Browse Delegate
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if deniedPeerIDs.contains(peerID) {
            return
        }
        let inviteAlert = UIAlertController(title: "Connect", message: "Do you wish to connect with \(peerID.displayName)?", preferredStyle: .alert)
        let destructiveAction = UIAlertAction(title: "No", style: .destructive) { (alert: UIAlertAction) -> Void in
            self.deniedPeerIDs.append(peerID)
        }
        let defaultAction = UIAlertAction(title: "Yes", style: .default) { (alert: UIAlertAction) -> Void in
            self.browser.stopBrowsingForPeers()
            self.browsing = false
            self.invited = true
            self.browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
        }
        inviteAlert.addAction(destructiveAction)
        inviteAlert.addAction(defaultAction)
        present(inviteAlert, animated: true, completion: nil)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    }
    
    // MARK: Advertise Delegate
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        let invitationRequest = UIAlertController(title: "Connect", message: "Would you like to connect with \(peerID.displayName)?", preferredStyle: .alert)
        let destructiveAction = UIAlertAction(title: "No", style: .destructive, handler: { (alertAction: UIAlertAction) -> Void in
            invitationHandler(false, self.session)
        })
        let defaultAction = UIAlertAction(title: "Yes", style: .default, handler: { (alertAction: UIAlertAction) -> Void in
            self.invited = false
            invitationHandler(true, self.session)
        })
        invitationRequest.addAction(destructiveAction)
        invitationRequest.addAction(defaultAction)
        self.present(invitationRequest, animated: true, completion: nil)
    }
    
    // MARK: Other Delegate
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        // did finish receiving resoruce with name
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // did receive stream
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // did start receivein resource
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        // did not start advertising
    }
}



