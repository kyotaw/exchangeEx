//
//  PositionListViewCell.swift
//  zai
//
//  Created by Kyota Watanabe on 9/8/16.
//  Copyright © 2016 Kyota Watanabe. All rights reserved.
//

import Foundation
import UIKit


protocol PositionListViewCellDelegate {
    func pushedDeleteButton(cell: PositionListViewCell, position: Position)
    func pushedEditButton(cell: PositionListViewCell, position: Position)
    func pushedUnwindButton(cell: PositionListViewCell, position: Position, rate: Double)
}

class PositionListViewCell : UITableViewCell {
    
    public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = UITableViewCellSelectionStyle.none
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.selectionStyle = UITableViewCellSelectionStyle.none
    }
    
    func setPosition(_ position: Position?, btcJpyPrice: Int) {
        guard let p = position else {
            self.priceLabel.text = "-"
            self.amountLabel.text = "-"
            self.balanceLabel.text = "(-)"
            self.profitLabel.text = "-"
            self.profitPercentLabel.text = "(-)"
            self.statusLabel.text = "-"
            self.deleteAction = nil
            self.unwind100Action = nil
            self.unwind50Action = nil
            self.unwind20Action = nil
            self.editingAction = nil
            return
        }
        self.position = p
        
        self.priceLabel.text = formatValue(Int(p.price))
        self.amountLabel.text = formatValue(p.amount, digit: 4)
        self.balanceLabel.text = "(" + formatValue(p.balance) + ")"
        self.updateProfit(btcJpyPrice: btcJpyPrice)
        
        let status = PositionState(rawValue: p.status.intValue)!
        self.statusLabel.text = status.toString()
        
        self.deleteAction = nil
        self.unwind100Action = nil
        self.unwind50Action = nil
        self.unwind20Action = nil
        self.editingAction = nil
        if status.isDelete == false {
            self.deleteAction = UITableViewRowAction(style: .default, title: "\(LabelResource.delete)") { (_, _) in
                self.delegate?.pushedDeleteButton(cell: self, position: self.position!)
            }
            self.deleteAction?.backgroundColor = UIColor.red
        }
        
        /*
         if status.isOpen || status.isWaiting {
         self.editingAction = UITableViewRowAction(style: .normal, title: "Edit") { (_, _) in
         self.delegate?.pushedEditButton(cell: self, position: self.position!)
         }
         self.editingAction?.backgroundColor = Color.keyColor
         }
         */
        
        if status.isOpen {
            self.unwind100Action = UITableViewRowAction(style: .normal, title: "\(LabelResource.unwind)\n(100%)") { (_, _) in
                self.delegate?.pushedUnwindButton(cell: self, position: self.position!, rate: 1.0)
            }
            self.unwind100Action?.backgroundColor = Color.unwind100Color
            self.unwind50Action = UITableViewRowAction(style: .normal, title: "\(LabelResource.unwind)\n(50%)") { (_, _) in
                self.delegate?.pushedUnwindButton(cell: self, position: self.position!, rate: 0.5)
            }
            self.unwind50Action?.backgroundColor = Color.unwind50Color
            self.unwind20Action = UITableViewRowAction(style: .normal, title: "\(LabelResource.unwind)\n(20%)") { (_, _) in
                self.delegate?.pushedUnwindButton(cell: self, position: self.position!, rate: 0.2)
            }
            self.unwind20Action?.backgroundColor = Color.unwind20Color
        }
        
        if status.isClosed {
            self.backgroundColor = Color.closedPositionColor
        } else {
            self.backgroundColor = UIColor.white
        }
    }
    
    func updateProfit(btcJpyPrice: Int) {
        guard let position = self.position else {
            self.profitLabel.text = "-"
            self.profitPercentLabel.text = "(-)"
            return
        }
        if btcJpyPrice < 0 {
            self.profitLabel.text = "-"
            self.profitPercentLabel.text = "(-)"
            return
        }
        
        let profit = Int(position.calculateUnrealizedProfit(marketPrice: Double(btcJpyPrice)))
        let profitStr = formatValue(profit)
        self.profitLabel.text = profitStr
        if profit > 0 {
            self.profitLabel.text = "+" + profitStr
        }
        let profitPercent = round((Double(profit) / position.cost) * 10000.0) / 100.0
        var percentStr = formatValue(profitPercent, digit: 2)
        if profit > 0 {
            percentStr = "+" + percentStr
        }
        self.profitPercentLabel.text = "(\(percentStr)%)"
        if profit < 0 {
            self.profitLabel.textColor = Color.askQuoteColor
            self.profitPercentLabel.textColor = Color.askQuoteColor
        } else if profit > 0{
            self.profitLabel.textColor = Color.bidQuoteColor
            self.profitPercentLabel.textColor = Color.bidQuoteColor
        } else {
            self.profitLabel.textColor = UIColor.black
            self.profitPercentLabel.textColor = UIColor.black
        }
    }
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var profitLabel: UILabel!
    @IBOutlet weak var profitPercentLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var activeIndicator: UIActivityIndicatorView!
    
    var deleteAction: UITableViewRowAction?
    var editingAction: UITableViewRowAction?
    var unwind100Action: UITableViewRowAction?
    var unwind50Action: UITableViewRowAction?
    var unwind20Action: UITableViewRowAction?
    var position: Position?
    var delegate: PositionListViewCellDelegate?
}
