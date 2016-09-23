//
//  Analyzer.swift
//  zai
//
//  Created by 渡部郷太 on 9/18/16.
//  Copyright © 2016 watanabe kyota. All rights reserved.
//

import Foundation

import ZaifSwift


class MarketPrice {
    init(btcJpy: Double, monaJpy: Double, xemJpy: Double) {
        self.btcJpy = btcJpy
        self.monaJpy = monaJpy
        self.xemJpy = xemJpy
    }
    let btcJpy: Double
    let monaJpy: Double
    let xemJpy: Double
}


protocol AnalyzerDelegate {
    func signaledBuy()
    func signaledSell()
}

class Analyzer : ZaifWatchDelegate {
    
    init() {
        self.marketPrice = MarketPrice(btcJpy: 0.0, monaJpy: 0.0, xemJpy: 0.0)
        self.macd = Macd(shortTerm: 12, longTerm: 26, signalTerm: 9)
        self.watch = ZaifWatch()
        self.watch.delegate = self
    }
    
    func didFetchBtcJpyMarketPrice(price: Double) {
        self.marketPrice = MarketPrice(btcJpy: price, monaJpy: self.marketPrice.monaJpy, xemJpy: self.marketPrice.xemJpy)
    }
    
    func didFetchMonaJpyMarketPrice(price: Double) {
        self.marketPrice = MarketPrice(btcJpy: self.marketPrice.btcJpy, monaJpy: price, xemJpy: self.marketPrice.xemJpy)
    }
    
    func didFetchXemJpyMarketPrice(price: Double) {
        self.marketPrice = MarketPrice(btcJpy: self.marketPrice.btcJpy, monaJpy: self.marketPrice.monaJpy, xemJpy: price)
    }
    
    func didFetchBtcJpyLastPrice(price: Double) {
        self.macd.addSampleValue(price)
        if self.macd.valid {
            let momentum = (self.macd.getLatestMacdValue() - self.macd.getPreviousMacdValue()) / self.watch.WATCH_LASTPRICE_INTERVAL
            let prevMomentum = self.momentum
            let isBullMomentum = prevMomentum < momentum
            if self.macd.isGoldenCross() && isBullMomentum && self.delegate != nil {
                self.isBullMarket = true
                self.delegate!.signaledBuy()
            } else if self.macd.isDeadCross() && self.delegate != nil {
                self.isBullMarket = false
                self.delegate!.signaledSell()
            } else {
                if self.isBullMarket && !isBullMomentum {
                    self.isBullMarket = false
                    self.delegate!.signaledSell()
                }
            }
            self.momentum = momentum
        }
    }
    
    var marketPrice: MarketPrice
    var macd: Macd
    let watch: ZaifWatch!
    var isBullMarket = false
    var momentum = 0.0
    var delegate: AnalyzerDelegate? = nil
}