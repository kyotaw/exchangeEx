//
//  ShortPosition.swift
//  
//
//  Created by Kyota Watanabe on 8/31/16.
//
//

import Foundation
import CoreData

import ZaifSwift


@objc(ShortPosition)
class ShortPosition: Position {
    
    override internal var balance: Double {
        get {
            var balance = 0.0
            for log in self.tradeLogs {
                let l = log as! TradeLog
                let action = TradeAction(rawValue: l.tradeAction)
                if action == .OPEN_SHORT_POSITION {
                    balance += l.amount!.doubleValue
                } else if action == .UNWIND_SHORT_POSITION {
                    balance -= l.amount!.doubleValue
                }
            }
            return balance
        }
    }
    
    override internal var profit: Double {
        get {
            var profit = 0.0
            for log in self.tradeLogs {
                let l = log as! TradeLog
                let action = TradeAction(rawValue: l.tradeAction)
                if action == .OPEN_SHORT_POSITION {
                    profit += l.price!.doubleValue * l.amount!.doubleValue
                } else if action == .UNWIND_SHORT_POSITION {
                    profit -= l.price!.doubleValue * l.amount!.doubleValue
                }
            }
            return profit
        }
    }
    
    override internal var currencyPair: ApiCurrencyPair {
        get {
            var currencyPair = ApiCurrencyPair.BTC_JPY
            for log in self.tradeLogs {
                let l = log as! TradeLog
                let action = TradeAction(rawValue: l.tradeAction)
                if action == .OPEN_SHORT_POSITION {
                    currencyPair = ApiCurrencyPair(rawValue: l.currencyPair!)!
                }
            }
            return currencyPair
        }
    }
    
    override internal var type: String {
        get {
            return "short"
        }
    }
    
    override var timestamp: Int64 {
        get {
            for log in self.tradeLogs {
                let l = log as! TradeLog
                let action = TradeAction(rawValue: l.tradeAction)
                if action == .OPEN_SHORT_POSITION {
                    return l.timestamp.int64Value
                }
            }
            return 0
        }
    }
    
    override func unwind(_ amount: Double?=nil, price: Double?, cb: @escaping (ZaiError?, Double) -> Void) {
        if self.status.intValue != PositionState.OPEN.rawValue {
            cb(nil, 0.0)
            return
        }
        
        self.status = NSNumber(value: PositionState.UNWINDING.rawValue)
        
        let balance = self.balance
        var amt = amount
        if amount == nil {
            // close this position completely
            amt = balance
        }
        if balance < amt! {
            amt = balance
        }
        
        let order = OrderRepository.getInstance().createSellOrder(currencyPair: self.currencyPair, price: price, amount: amt!, api: self.trader!.exchange.api)
        
        order.excute() { (err, res) in
            cb(err, amt!)
            order.delegate = self
        }
    }
    
    // OrderDelegate
    override func orderPromised(order: Order, promisedOrder: PromisedOrder) {
        return
    }
    override func orderPartiallyPromised(order: Order, promisedOrder: PromisedOrder) {
        return
    }
    override func orderCancelled(order: Order) {
        return
    }
}
