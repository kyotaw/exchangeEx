//
//  Fund.swift
//  zai
//
//  Created by 渡部郷太 on 8/19/16.
//  Copyright © 2016 watanabe kyota. All rights reserved.
//

import Foundation

import SwiftyJSON

import ZaifSwift


internal class JPYFund {
    init(api: PrivateApi) {
        self.privateApi = api
    }
 
    func getMarketCapitalization(cb: ((ZaiError?, Int) -> Void)) {
        self.privateApi.getInfo() { (err, res) in
            if let e = err {
                cb(ZaiError(errorType: .ZAIF_API_ERROR, message: e.message), 0)
            } else {
                if let info = res {
                    var total = info["return"]["deposit"]["jpy"].doubleValue
                    let btc = info["return"]["deposit"]["btc"].doubleValue
                    let mona = info["return"]["deposit"]["mona"].doubleValue
                    let xem = info["return"]["deposit"]["xem"].doubleValue
                    BitCoin.getPriceFor(.JPY) { (err, btcPrice) in
                        if let e = err {
                            cb(ZaiError(errorType: .ZAIF_API_ERROR, message: e.message), 0)
                        } else {
                            total += (btc * Double(btcPrice))
                            MonaCoin.getPriceFor(.JPY) { (err, monaPrice) in
                                if let e = err {
                                    cb(ZaiError(errorType: .ZAIF_API_ERROR, message: e.message), 0)
                                } else {
                                    total += (mona * monaPrice)
                                    XEM.getPriceFor(.JPY) { (err, xemPrice) in
                                        if let e = err {
                                            cb(ZaiError(errorType: .ZAIF_API_ERROR, message: e.message), 0)
                                        } else {
                                            total += (xem * xemPrice)
                                            cb(nil, Int(total))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func calculateHowManyAmountCanBuy(currency: Currency, price: Double? = nil, rate: Double = 1.0, cb: (ZaiError?, Double) -> Void) {
        self.privateApi.getInfo() { (err, res) in
            if let e = err {
                cb(ZaiError(errorType: .ZAIF_API_ERROR, message: e.message), 0)
            } else {
                if let info = res {
                    let jpyFund = info["return"]["deposit"]["jpy"].doubleValue
                    var currencyPair = CurrencyPair.BTC_JPY
                    switch currency {
                    case .MONA:
                        currencyPair = .MONA_JPY
                    case .XEM:
                        currencyPair = .XEM_JPY
                    default: break
                    }
                    if let p = price {
                        let amount = jpyFund * rate / p
                        cb(nil, amount)
                    } else {
                        PublicApi.lastPrice(currencyPair) { (err, res) in
                            if let e = err {
                                cb(ZaiError(errorType: .ZAIF_API_ERROR, message: e.message), 0)
                            } else {
                                let price = res!["last_price"].doubleValue
                                let amount = jpyFund * rate / price
                                cb(nil, amount)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private let privateApi: PrivateApi
}