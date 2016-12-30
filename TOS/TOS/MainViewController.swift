//
//  MainViewController.swift
//  TOS
//
//  Created by steven on 2014/7/4.
//  Copyright (c) 2014年 steven. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

struct ContainerCell {
    var layer: CALayer?
    var color: UIColor?
    var startPoint: CGPoint?
}

class TOSContainer{
    var cells = [ContainerCell]()
    func initWithData(row: Int, column: Int, containerSize: Float) {
        for rowIndex in 0..<row {
            for columnIndex in 0..<column {
                let cell = ContainerCell(layer: nil, color: nil, startPoint: CGPoint(x: CGFloat(containerSize * Float(columnIndex)), y: CGFloat(containerSize * Float(rowIndex))))
                cells.append(cell)
            }
        }
        
    }
}

protocol CustomViewDelegate {
    func didSelect(touchPoint inTouchPoint: CGPoint)
    func didMove(touchPoint inTouchPoint: CGPoint)
    func didCancel()
}

class TOSView: UIView {
    
    var customDelegate: CustomViewDelegate?
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let path = CGMutablePath()
        for columnIndex in 0..<5 {
			path.move(to: CGPoint(x: 0.0, y: CGFloat(Float(columnIndex) * (320.0 / 6.0))))
			path.addLine(to: CGPoint(x: self.frame.size.width, y: CGFloat(Float(columnIndex) * (320.0 / 6.0))))
        }
        for rowIndex in 0..<6 {
			path.move(to: CGPoint(x: CGFloat(Float(rowIndex) * (320.0 / 6.0)), y:0.0))
			path.addLine(to: CGPoint(x: CGFloat(Float(rowIndex) * (320.0 / 6.0)), y:self.frame.size.height))
			
        }
        
        context?.addPath(path)
        context?.setStrokeColor(UIColor.white.cgColor);
        context?.setLineWidth(1.0)
        context?.strokePath()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let touch : UITouch = touches.first!
        let touchPoint = touch.location(in: self)
        customDelegate?.didSelect(touchPoint: touchPoint)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        let touch : UITouch = touches.first!
        let touchPoint = touch.location(in: self)
        customDelegate?.didMove(touchPoint: touchPoint)
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        customDelegate?.didCancel()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        customDelegate?.didCancel()
    }
}


protocol ProgressBarDelegate {
    func timeout()
}
class ProgressBar: CALayer {
    
    var timer: Timer?
    var time: CGFloat = 10.0
    var customeDelegate: ProgressBarDelegate?
    
    override func draw(in ctx: CGContext)  {
        let rect = CGRect(x: 0.0, y: 0.0, width: self.frame.size.width * time / 10.0, height: self.frame.size.height)
        ctx.saveGState();
        let path = CGPath(rect: rect, transform: nil)
        ctx.addPath(path);
        ctx.clip();
        if rect.size.width < 100.0 {
            ctx.setFillColor(UIColor.red.cgColor);
        }
        else if rect.size.width < 200 {
            ctx.setFillColor(UIColor.yellow.cgColor);
        }
        else {
            ctx.setFillColor(UIColor.green.cgColor);
        }
        ctx.fill(rect);
        ctx.restoreGState();
    }
    
    func _reset() {
        time = 10.0
        self.setNeedsDisplay()
    }
    
    func startTime() {
        if (timer != nil) {
            timer!.invalidate()
            timer = nil
        }
        time = 10.0
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ProgressBar._update), userInfo: nil, repeats: true)
    }
    
    func stopTime() {
        if (timer != nil) {
            timer!.invalidate()
            timer = nil
        }
        self._reset()
    }
    
    func _update() {
        time -= 1.0
        if time < 0 {
            if (timer != nil){
                timer!.invalidate()
            }
            customeDelegate?.timeout()
        }
        self.setNeedsDisplay()
    }
    
}

class MainViewController: UIViewController, CustomViewDelegate, ProgressBarDelegate {
    
    var container: TOSContainer!
    var basicView = TOSView()
    var moveLayer: CAShapeLayer!
    var startTouchPoint: CGPoint?
    var startMoveIndex = 0
    var clearTarget = [[Int]]()
    var shouldMoveIndex = [Int]()
    var score = 0
    var progressBar = ProgressBar()
    var timing = false
    var timerLabel = UILabel()
    var maskView = UIView()
    var startButton = UIButton(type: UIButtonType.system)
    var gameTimer: Timer?
    var currentTime = 0
    var scoreLabel = UILabel()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        
        container = TOSContainer()
        container.initWithData(row: 5, column: 6, containerSize: 320.0 / 6.0)
        basicView.customDelegate = self
    }
    
    override func loadView() {
        super.loadView()
        self.view.backgroundColor = UIColor.brown
        
        
        timerLabel.frame = CGRect(x: 0.0, y: 30.0, width: self.view.frame.size.width, height: 30.0)
        timerLabel.backgroundColor = UIColor.white
        timerLabel.text = "spend time : 0"
        timerLabel.textAlignment = NSTextAlignment.center
        self.view.addSubview(timerLabel)
        
        scoreLabel.frame = CGRect(x: 0.0, y: 100.0, width: self.view.frame.size.width, height: 30.0)
        scoreLabel.backgroundColor = UIColor.gray
        scoreLabel.text = "now score : 0"
        scoreLabel.textAlignment = NSTextAlignment.center
        self.view.addSubview(scoreLabel)
        
        basicView.frame = CGRect(x: 0.0, y: self.view.frame.size.height - CGFloat(320.0 / 6.0 * 5.0), width: CGFloat(320.0 / 6.0 * 6.0), height: CGFloat(320.0 / 6.0 * 5.0))
        basicView.backgroundColor = UIColor.black
        self.view.addSubview(basicView)
        basicView.setNeedsDisplay()

        progressBar.frame = CGRect(x: 0.0, y: basicView.frame.minY - 44.0, width: self.view.frame.size.width, height: 44.0)
        progressBar.customeDelegate = self
        progressBar.backgroundColor = UIColor.black.cgColor
        self.view.layer.addSublayer(progressBar)
        self.progressBar.setNeedsDisplay()
        
        self._setCricle()
        
        maskView.frame = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        maskView.backgroundColor = UIColor.black
        maskView.alpha = 0.7
        self.view.addSubview(maskView)
        
        startButton.frame = CGRect(x: 0.0, y: (self.view.frame.size.height - 44.0) / 2.0, width: self.view.frame.size.width, height: 44.0)
        startButton.backgroundColor = UIColor.white
        startButton.setTitle("Start", for: UIControlState())
        startButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: 20.0)
        startButton.addTarget(self, action: #selector(MainViewController._gameStart), for: UIControlEvents.touchUpInside)
        self.view.addSubview(startButton)
    }
    
    func _gameStart() {
        startButton.isHidden = true
        maskView.isHidden = true
        score = 0
        currentTime = 0
        scoreLabel.text = "now score : 0"
        timerLabel.text = "spend time : 0"
        if (gameTimer != nil) {
            gameTimer!.invalidate()
            gameTimer = nil
        }
        gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(MainViewController._updateTimer), userInfo: nil, repeats: true)
    }
    
    func _reStart() {
        for index in 0..<container.cells.count {
            if (container.cells[index].layer != nil) {
                container.cells[index].layer!.removeFromSuperlayer()
            }
        }
        if (container != nil) {
            container = nil
        }
        container = TOSContainer()
        container.initWithData(row: 5, column: 6, containerSize: 320.0 / 6.0)
        self._setCricle()
        self._gameStart()
    }
    
    
    func _updateTimer() {
        currentTime += 1
        timerLabel.text = "spend time : \(currentTime)"
    }
    
    func _setCricle() {
        for index in 0..<container.cells.count {
            let color = self.randomColor()
            let layer = CALayer()
            layer.frame = CGRect(x: container.cells[index].startPoint!.x, y: container.cells[index].startPoint!.y, width: 320.0 / 6.0, height: 320.0 / 6.0)
            layer.masksToBounds = true
            layer.cornerRadius = 25.0
            layer.backgroundColor = color.cgColor
            container.cells[index].layer = layer
            container.cells[index].color = color
            basicView.layer.addSublayer(layer)
        }
    }
    
    func _clearCircle() {
        
        var allRedCircle = [Int]()
        var allBlueCircle = [Int]()
        var allYellowCircle = [Int]()
        var allPurpleCircle = [Int]()
        var allGreenCircle = [Int]()
        
        for index in 0..<container.cells.count {
            if container.cells[index].color == UIColor.red {
                allRedCircle.append(index)
            }
            if container.cells[index].color == UIColor.blue {
                allBlueCircle.append(index)
            }
            if container.cells[index].color == UIColor.yellow {
                allYellowCircle.append(index)
            }
            if container.cells[index].color == UIColor.purple {
                allPurpleCircle.append(index)
            }
            if container.cells[index].color == UIColor.green {
                allGreenCircle.append(index)
            }
        }
        
        self._clearWithColor(allRedCircle)
        self._clearWithColor(allBlueCircle)
        self._clearWithColor(allYellowCircle)
        self._clearWithColor(allPurpleCircle)
        self._clearWithColor(allGreenCircle)
        
        if clearTarget.count == 0 {
            UIApplication.shared.endIgnoringInteractionEvents()
            if score >= 100 {
                startButton.removeTarget(self, action: #selector(MainViewController._gameStart), for: UIControlEvents.touchUpInside)
                startButton.addTarget(self, action: #selector(MainViewController._reStart), for: UIControlEvents.touchUpInside)
                startButton.isHidden = false
            }
            return
        }
        
        var delayToClear = 0.0 * Double(NSEC_PER_SEC)
        var delayToClearTime = DispatchTime.now() + Double(Int64(delayToClear)) / Double(NSEC_PER_SEC)
        for clearIndexs in clearTarget {
            delayToClear += 0.5 * Double(NSEC_PER_SEC)
            delayToClearTime = DispatchTime.now() + Double(Int64(delayToClear)) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayToClearTime, execute: {
                self.score += clearIndexs.count
                if self.score >= 100 {
                    self.maskView.isHidden = false
                    if (self.gameTimer != nil) {
                        self.gameTimer!.invalidate()
                        self.gameTimer = nil
                    }
                }
                self.scoreLabel.text = "now score : \(self.score)"
                for clearIndex in clearIndexs {
                    if (self.container.cells[clearIndex].layer != nil) {
                        self.container.cells[clearIndex].layer!.opacity = 0.0
                        self.container.cells[clearIndex].layer!.removeFromSuperlayer()
                        self.container.cells[clearIndex].layer = nil
                        self.container.cells[clearIndex].color = nil
                    }
            }})

        }

        clearTarget.removeAll(keepingCapacity: false)

        let delayToReset = delayToClear + 0.5 * Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayToClearTime, execute: {
            self._resetAllCirclePosition()
        })
        
        let delayToAddNewCircle = delayToReset + 0.5 * Double(NSEC_PER_SEC)
        let delayToAddNewCircleTime = DispatchTime.now() + Double(Int64(delayToAddNewCircle)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayToAddNewCircleTime, execute: {self._addNewCircle()})

        
        let delayToMoveNewCicle = delayToAddNewCircle + 0.5 * Double(NSEC_PER_SEC)
        let delayToMoveNewCicleTime = DispatchTime.now() + Double(Int64(delayToMoveNewCicle)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayToMoveNewCicleTime, execute: {
            for index in self.shouldMoveIndex {
                self.container.cells[index].layer!.frame = CGRect(x: self.container.cells[index].startPoint!.x, y: self.container.cells[index].startPoint!.y, width: 320.0 / 6.0, height: 320.0 / 6.0)
            }
            self.shouldMoveIndex.removeAll(keepingCapacity: false)
            
        })
        
        let delayToClearCircleAfterAddingNewCircle = delayToMoveNewCicle + 0.5 * Double(NSEC_PER_SEC)
        let delayToClearCircleAfterAddingNewCircleTime = DispatchTime.now() + Double(Int64(delayToClearCircleAfterAddingNewCircle)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayToClearCircleAfterAddingNewCircleTime, execute: {
            self._clearCircle()
        })
    }
    
    // add new circle
    func _addNewCircle() {
        for index in 0..<container.cells.count {
            if (container.cells[index].layer == nil) {
                shouldMoveIndex.append(index)
                let color = self.randomColor()
                let layer = CALayer()
                layer.frame = CGRect(x: self.container.cells[index].startPoint!.x, y: -500.0, width: 320.0 / 6.0, height: 320.0 / 6.0)
                layer.masksToBounds = true
                layer.cornerRadius = 25.0
                layer.backgroundColor = color.cgColor
                container.cells[index].layer = layer
                container.cells[index].color = color
                basicView.layer.addSublayer(layer)
            }
        }
        

    }
    
    // reset position after clear circle
    func _resetAllCirclePosition() {
        var lastIndex = container.cells.count
        while lastIndex > 0 {
            let toIndex = lastIndex - 6
            for index in toIndex..<lastIndex {
                if (container.cells[index].layer == nil) {
                    var findLayerExistIndex = index - 6
                    while findLayerExistIndex >= 0 {
                        if (container.cells[findLayerExistIndex].layer != nil) {
                            container.cells[findLayerExistIndex].layer!.frame = CGRect(x: container.cells[index].startPoint!.x, y: container.cells[index].startPoint!.y, width: container.cells[findLayerExistIndex].layer!.frame.size.width, height: container.cells[findLayerExistIndex].layer!.frame.size.width)
                            let tempLayer: CALayer? = container.cells[findLayerExistIndex].layer
                            let tempColor: UIColor? = container.cells[findLayerExistIndex].color
                            container.cells[index].layer = tempLayer
                            container.cells[index].color = tempColor
                            container.cells[findLayerExistIndex].layer = nil
                            container.cells[findLayerExistIndex].color = nil
                            break
                        }
                        findLayerExistIndex -= 6
                    }
                }
            }
            lastIndex -= 6
        }
    }
    
    // calculate circle link status
    func _clearWithColor(_ colorCircle: [Int]) {
        
        for startIndex in colorCircle {
            let rowLimitIndex = startIndex - (startIndex % 6)
            var linkCount = 0
            var checkIndex = startIndex - 1
            var shouldClearIndex = [Int]()
            shouldClearIndex.append(startIndex)
            
            while true {
                if checkIndex < 0 || checkIndex < rowLimitIndex {
                    if linkCount >= 2 {
                        self.addToClearTarget(shouldClearIndex)
                    }
                    break
                }
                let bingo = colorCircle.contains(checkIndex)
                if bingo {
                    shouldClearIndex.append(checkIndex)
                    linkCount += 1
                    checkIndex -= 1
                }
                else {
                    if linkCount >= 2 {
                        self.addToClearTarget(shouldClearIndex)
                    }
                    break
                }

            }
        }
        
        for startIndex in colorCircle {

            var bingoCount = 0
            var checkIndex = startIndex - 6
            var shouldClearIndex = [Int]()
            shouldClearIndex.append(startIndex)
            
            while true {
                if checkIndex < 0 {
                    if bingoCount >= 2 {
                        self.addToClearTarget(shouldClearIndex)
                    }
                    break
                }
                let bingo = colorCircle.contains(checkIndex)
                if bingo {
                    shouldClearIndex.append(checkIndex)
                    bingoCount += 1
                    checkIndex -= 6
                }
                else {
                    if bingoCount >= 2 {
                        self.addToClearTarget(shouldClearIndex)
                    }
                    break
                }
                
            }
        }
    }
    
    // add circle should be clear into clearTarget
    func addToClearTarget(_ clears: [Int]) {
        if clearTarget.count > 0 {
            for index in 0..<clearTarget.count {
                for clearIndex in clears {
                    if clearTarget[index].contains(clearIndex) {
                        for addIndex in clears {
                            if !clearTarget[index].contains(addIndex) {
                                clearTarget[index].append(addIndex)
                            }
                        }
                        return
                    }
                }
            }
        }
        clearTarget.append(clears)
    }
    
    // touch delegate
    func didSelect(touchPoint inTouchPoint: CGPoint) {
        startTouchPoint = inTouchPoint
        for index in 0..<container.cells.count {
            let cell = container.cells[index]
            if inTouchPoint.x > cell.startPoint!.x && inTouchPoint.x < cell.startPoint!.x + 320.0 / 6.0 && inTouchPoint.y > cell.startPoint!.y && inTouchPoint.y < cell.startPoint!.y + 320.0 / 6.0 {
                startMoveIndex = index
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                moveLayer = CAShapeLayer()
                moveLayer.path = UIBezierPath(roundedRect:CGRect(x: cell.startPoint!.x, y: cell.startPoint!.y, width: 320.0 / 6.0, height: 320.0 / 6.0) , cornerRadius: 100.0).cgPath
                moveLayer.fillColor = cell.color!.cgColor
                moveLayer.opacity = 1.0
                basicView.layer.addSublayer(moveLayer)
                CATransaction.commit()
                container.cells[startMoveIndex].layer!.opacity = 0.0
            }
            
        }
    }
    func didCancel() {
        if !timing {
            return
        }
        else {
            timing = false
            progressBar.stopTime()
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        moveLayer.removeFromSuperlayer()
        moveLayer = nil
        CATransaction.commit()
        container.cells[startMoveIndex].layer!.opacity = 1.0
        UIApplication.shared.beginIgnoringInteractionEvents()
        self._clearCircle()
    }
    
    func didMove(touchPoint inTouchPoint: CGPoint) {
        
        let x = inTouchPoint.x - startTouchPoint!.x
        let y = inTouchPoint.y - startTouchPoint!.y
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        moveLayer.frame = CGRect(x: x, y: y, width: moveLayer.frame.size.width, height: moveLayer.frame.size.height)
        CATransaction.commit()
        
        for index in 0..<container.cells.count {
            let cell = container.cells[index]
            if inTouchPoint.x > cell.startPoint!.x && inTouchPoint.x < cell.startPoint!.x + 320.0 / 6.0 && inTouchPoint.y > cell.startPoint!.y && inTouchPoint.y < cell.startPoint!.y + 320.0 / 6.0 {
                if index != startMoveIndex {
                    self._changeTargetCell(index)
                }
            }
            
        }
        
    }
    
    // change circle
    func _changeTargetCell(_ targetIndex: Int) {
        if !timing {
            timing = true
            progressBar.startTime()
        }
        container.cells[startMoveIndex].layer!.frame = CGRect(x: container.cells[targetIndex].startPoint!.x, y: container.cells[targetIndex].startPoint!.y, width: container.cells[startMoveIndex].layer!.frame.size.width, height: container.cells[startMoveIndex].layer!.frame.size.height)
        container.cells[targetIndex].layer!.frame = CGRect(x: container.cells[startMoveIndex].startPoint!.x, y: container.cells[startMoveIndex].startPoint!.y, width: container.cells[targetIndex].layer!.frame.size.width, height: container.cells[targetIndex].layer!.frame.size.height)
        
        
        let tempStartLayer = container.cells[startMoveIndex].layer
        let tempStartColor = container.cells[startMoveIndex].color
        container.cells[startMoveIndex].layer = container.cells[targetIndex].layer
        container.cells[startMoveIndex].color = container.cells[targetIndex].color
        container.cells[targetIndex].layer = tempStartLayer
        container.cells[targetIndex].color = tempStartColor
        startMoveIndex = targetIndex
    }
    
    // progress delegate
    func timeout() {
        self.didCancel()
    }
    
    // randomColor
    func randomColor() -> UIColor {
        let index = arc4random() % 5
        if index == 0 {
            return UIColor.red
        }
        else if index == 1 {
            return UIColor.blue
        }
        else if index == 2 {
            return UIColor.yellow
        }
        else if index == 3 {
            return UIColor.green
        }
        else if index == 4 {
            return UIColor.purple
        }
        return UIColor.white
    }
    
}
