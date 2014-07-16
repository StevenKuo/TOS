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
    func initWithData(#row: Int, column: Int, containerSize: Float) {
        for rowIndex in 0..<row {
            for columnIndex in 0..<column {
                var cell = ContainerCell(layer: nil, color: nil, startPoint: CGPointMake(CGFloat(containerSize * Float(columnIndex)), CGFloat(containerSize * Float(rowIndex))))
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
    
    override func drawRect(rect: CGRect) {
        var context = UIGraphicsGetCurrentContext()
        var path = CGPathCreateMutable()
        for columnIndex in 0..<5 {
            CGPathMoveToPoint(path, nil, 0.0, CGFloat(Float(columnIndex) * (320.0 / 6.0)));
            CGPathAddLineToPoint(path, nil, self.frame.size.width, CGFloat(Float(columnIndex) * (320.0 / 6.0)))
        }
        for rowIndex in 0..<6 {
            CGPathMoveToPoint(path, nil, CGFloat(Float(rowIndex) * (320.0 / 6.0)), 0.0);
            CGPathAddLineToPoint(path, nil, CGFloat(Float(rowIndex) * (320.0 / 6.0)), self.frame.size.height)
        }
        
        CGContextAddPath(context, path)
        CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor);
        CGContextSetLineWidth(context, 1.0)
        CGContextStrokePath(context)
    }
    
    override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {
        super.touchesBegan(touches, withEvent: event)
        let touch : UITouch = touches.anyObject() as UITouch
        let touchPoint = touch.locationInView(self)
        customDelegate?.didSelect(touchPoint: touchPoint)
    }
    
    override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!) {
        let touch : UITouch = touches.anyObject() as UITouch
        let touchPoint = touch.locationInView(self)
        customDelegate?.didMove(touchPoint: touchPoint)
    }
    
    override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
        super.touchesBegan(touches, withEvent: event)
        customDelegate?.didCancel()
    }
    override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
        super.touchesBegan(touches, withEvent: event)
        customDelegate?.didCancel()
    }
}


class MainViewController: UIViewController, CustomViewDelegate {
    
    var container = TOSContainer()
    var basicView = TOSView()
    var moveLayer: CAShapeLayer!
    var startTouchPoint: CGPoint?
    var startMoveIndex = 0
    var clearTarget = [[Int]]()
    var shouldMoveIndex = [Int]()
    var score = 0
    
    init(coder aDecoder: NSCoder!) {
        super.init(coder:aDecoder)
        container.initWithData(row: 5, column: 6, containerSize: 320.0 / 6.0)
        basicView.customDelegate = self
    }
    
    override func loadView() {
        super.loadView()
        self.view.backgroundColor = UIColor.brownColor()
        basicView.frame = CGRectMake(0.0, self.view.frame.size.height - CGFloat(320.0 / 6.0 * 5.0), CGFloat(320.0 / 6.0 * 6.0), CGFloat(320.0 / 6.0 * 5.0))
        basicView.backgroundColor = UIColor.blackColor()
        self.view.addSubview(basicView)
        basicView.setNeedsDisplay()
        
        self._setCricle()
    }
    
    func _setCricle() {
        for index in 0..<container.cells.count {
            let color = self.randomColor()
            var layer = CALayer()
            layer.frame = CGRectMake(container.cells[index].startPoint!.x, container.cells[index].startPoint!.y, 320.0 / 6.0, 320.0 / 6.0)
            layer.masksToBounds = true
            layer.cornerRadius = 25.0
            layer.backgroundColor = color.CGColor
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
            if container.cells[index].color == UIColor.redColor() {
                allRedCircle += index
            }
            if container.cells[index].color == UIColor.blueColor() {
                allBlueCircle += index
            }
            if container.cells[index].color == UIColor.yellowColor() {
                allYellowCircle += index
            }
            if container.cells[index].color == UIColor.purpleColor() {
                allPurpleCircle += index
            }
            if container.cells[index].color == UIColor.greenColor() {
                allGreenCircle += index
            }
        }
        
        self._clearWithColor(allRedCircle)
        self._clearWithColor(allBlueCircle)
        self._clearWithColor(allYellowCircle)
        self._clearWithColor(allPurpleCircle)
        self._clearWithColor(allGreenCircle)
        
        if clearTarget.count == 0 {
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
            println("\(score)")
            return
        }
        
        var delayToClear = 0.0 * Double(NSEC_PER_SEC)
        var delayToClearTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayToClear))
        for clearIndexs in clearTarget {
            score += clearIndexs.count
            delayToClear += 0.5 * Double(NSEC_PER_SEC)
            delayToClearTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayToClear))
            dispatch_after(delayToClearTime, dispatch_get_main_queue(), {
                for clearIndex in clearIndexs {
                    if self.container.cells[clearIndex].layer {
                        self.container.cells[clearIndex].layer!.opacity = 0.0
                        self.container.cells[clearIndex].layer!.removeFromSuperlayer()
                        self.container.cells[clearIndex].layer = nil
                        self.container.cells[clearIndex].color = nil
                    }
            }})

        }

        clearTarget.removeAll(keepCapacity: false)
        println("\(delayToClear)")
        var delayToReset = delayToClear + 0.5 * Double(NSEC_PER_SEC)
        var delayToResetTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayToReset))
        dispatch_after(delayToClearTime, dispatch_get_main_queue(), {
            self._resetAllCirclePosition()
        })
        
        let delayToAddNewCircle = delayToReset + 0.5 * Double(NSEC_PER_SEC)
        let delayToAddNewCircleTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayToAddNewCircle))
        dispatch_after(delayToAddNewCircleTime, dispatch_get_main_queue(), {self._addNewCircle()})

        
        let delayToMoveNewCicle = delayToAddNewCircle + 0.5 * Double(NSEC_PER_SEC)
        let delayToMoveNewCicleTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayToMoveNewCicle))
        dispatch_after(delayToMoveNewCicleTime, dispatch_get_main_queue(), {
            for index in self.shouldMoveIndex {
                self.container.cells[index].layer!.frame = CGRectMake(self.container.cells[index].startPoint!.x, self.container.cells[index].startPoint!.y, 320.0 / 6.0, 320.0 / 6.0)
            }
            self.shouldMoveIndex.removeAll(keepCapacity: false)
            
        })
        
        let delayToClearCircleAfterAddingNewCircle = delayToMoveNewCicle + 0.5 * Double(NSEC_PER_SEC)
        let delayToClearCircleAfterAddingNewCircleTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayToClearCircleAfterAddingNewCircle))
        dispatch_after(delayToClearCircleAfterAddingNewCircleTime, dispatch_get_main_queue(), {
            self._clearCircle()
        })
    }
    
    // add new circle
    func _addNewCircle() {
        for index in 0..<container.cells.count {
            if !container.cells[index].layer {
                shouldMoveIndex += index
                let color = self.randomColor()
                var layer = CALayer()
                layer.frame = CGRectMake(self.container.cells[index].startPoint!.x, -500.0, 320.0 / 6.0, 320.0 / 6.0)
                layer.masksToBounds = true
                layer.cornerRadius = 25.0
                layer.backgroundColor = color.CGColor
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
            var toIndex = lastIndex - 6
            for index in toIndex..<lastIndex {
                if !container.cells[index].layer {
                    var findLayerExistIndex = index - 6
                    while findLayerExistIndex >= 0 {
                        if container.cells[findLayerExistIndex].layer {
                            container.cells[findLayerExistIndex].layer!.frame = CGRectMake(container.cells[index].startPoint!.x, container.cells[index].startPoint!.y, container.cells[findLayerExistIndex].layer!.frame.size.width, container.cells[findLayerExistIndex].layer!.frame.size.width)
                            var tempLayer: CALayer? = container.cells[findLayerExistIndex].layer
                            var tempColor: UIColor? = container.cells[findLayerExistIndex].color
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
    func _clearWithColor(colorCircle: [Int]) {
        
        for startIndex in colorCircle {
            let rowLimitIndex = startIndex - (startIndex % 6)
            var linkCount = 0
            var checkIndex = startIndex - 1
            var shouldClearIndex = [Int]()
            shouldClearIndex += startIndex
            
            while true {
                if checkIndex < 0 || checkIndex < rowLimitIndex {
                    if linkCount >= 2 {
                        self.addToClearTarget(shouldClearIndex)
                    }
                    break
                }
                var bingo = contains(colorCircle, checkIndex)
                if bingo {
                    shouldClearIndex += checkIndex
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
            shouldClearIndex += startIndex
            
            while true {
                if checkIndex < 0 {
                    if bingoCount >= 2 {
                        self.addToClearTarget(shouldClearIndex)
                    }
                    break
                }
                var bingo = contains(colorCircle, checkIndex)
                if bingo {
                    shouldClearIndex += checkIndex
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
    func addToClearTarget(clears: [Int]) {
        if clearTarget.count > 0 {
            for index in 0..<clearTarget.count {
                for clearIndex in clears {
                    if contains(clearTarget[index], clearIndex) {
                        for addIndex in clears {
                            if !contains(clearTarget[index], addIndex) {
                                clearTarget[index] += addIndex
                            }
                        }
                        return
                    }
                }
            }
        }
        clearTarget += clears
    }
    
    // touch delegate
    func didSelect(touchPoint inTouchPoint: CGPoint) {
        startTouchPoint = inTouchPoint
        for index in 0..<container.cells.count {
            var cell = container.cells[index]
            if inTouchPoint.x > cell.startPoint!.x && inTouchPoint.x < cell.startPoint!.x + 320.0 / 6.0 && inTouchPoint.y > cell.startPoint!.y && inTouchPoint.y < cell.startPoint!.y + 320.0 / 6.0 {
                startMoveIndex = index
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                moveLayer = CAShapeLayer()
                moveLayer.path = UIBezierPath(roundedRect:CGRect(x: cell.startPoint!.x, y: cell.startPoint!.y, width: 320.0 / 6.0, height: 320.0 / 6.0) , cornerRadius: 100.0).CGPath
                moveLayer.fillColor = cell.color!.CGColor
                moveLayer.opacity = 1.0
                basicView.layer.addSublayer(moveLayer)
                CATransaction.commit()
                container.cells[startMoveIndex].layer!.opacity = 0.0
            }
            
        }
    }
    func didCancel() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        moveLayer.removeFromSuperlayer()
        moveLayer = nil
        CATransaction.commit()
        container.cells[startMoveIndex].layer!.opacity = 1.0
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        self._clearCircle()
    }
    
    func didMove(touchPoint inTouchPoint: CGPoint) {
        var x = inTouchPoint.x - startTouchPoint!.x
        var y = inTouchPoint.y - startTouchPoint!.y
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        moveLayer.frame = CGRectMake(x, y, moveLayer.frame.size.width, moveLayer.frame.size.height)
        CATransaction.commit()
        
        for index in 0..<container.cells.count {
            var cell = container.cells[index]
            if inTouchPoint.x > cell.startPoint!.x && inTouchPoint.x < cell.startPoint!.x + 320.0 / 6.0 && inTouchPoint.y > cell.startPoint!.y && inTouchPoint.y < cell.startPoint!.y + 320.0 / 6.0 {
                if index != startMoveIndex {
                    self._changeTargetCell(index)
                }
            }
            
        }
        
    }
    
    // change circle
    func _changeTargetCell(targetIndex: Int) {
        
        container.cells[startMoveIndex].layer!.frame = CGRectMake(container.cells[targetIndex].startPoint!.x, container.cells[targetIndex].startPoint!.y, container.cells[startMoveIndex].layer!.frame.size.width, container.cells[startMoveIndex].layer!.frame.size.height)
        container.cells[targetIndex].layer!.frame = CGRectMake(container.cells[startMoveIndex].startPoint!.x, container.cells[startMoveIndex].startPoint!.y, container.cells[targetIndex].layer!.frame.size.width, container.cells[targetIndex].layer!.frame.size.height)
        
        
        var tempStartLayer = container.cells[startMoveIndex].layer
        var tempStartColor = container.cells[startMoveIndex].color
        container.cells[startMoveIndex].layer = container.cells[targetIndex].layer
        container.cells[startMoveIndex].color = container.cells[targetIndex].color
        container.cells[targetIndex].layer = tempStartLayer
        container.cells[targetIndex].color = tempStartColor
        startMoveIndex = targetIndex
    }
    
    // randomColor
    func randomColor() -> UIColor {
        let index = arc4random() % 5
        if index == 0 {
            return UIColor.redColor()
        }
        else if index == 1 {
            return UIColor.blueColor()
        }
        else if index == 2 {
            return UIColor.yellowColor()
        }
        else if index == 3 {
            return UIColor.greenColor()
        }
        else if index == 4 {
            return UIColor.purpleColor()
        }
        return UIColor.whiteColor()
    }
    
}