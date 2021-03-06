//
//  CandleChartView.swift
//  zai
//
//  Created by 渡部郷太 on 3/27/17.
//  Copyright © 2017 watanabe kyota. All rights reserved.
//

import Foundation

import Charts


protocol CandleChartViewDelegate {
    func recievedChart(chartData: CandleChartData, xFormatter: XValueFormatter, yFormatter: YValueFormatter, chart: CandleChart)
}


class CandleChartView : CandleChartDelegate {
    
    init(chart: CandleChart) {
        self.candleChart = chart
    }
    
    func switchChartIntervalType(type: ChandleChartType) {
        self.candleChart.switchInterval(interval: type)
    }
    
    var showBollingerBand: Bool {
        get {
            return self._showBollingerBand
        }
        set {
            self._showBollingerBand = newValue
        }
    }
    
    var showSma5: Bool {
        get {
            return self._showSma5
        }
        set {
            self._showSma5 = newValue
        }
    }
    
    var showSma25: Bool {
        get {
            return self._showSma25
        }
        set {
            self._showSma25 = newValue
        }
    }

    // CandleChartDelegate
    func recievedChart(chart: CandleChart, newCandles: [Candle], chartName: String) {
        let candleData = self.makeCandleData(chart: chart)
        let emptyData = self.makeEmptyData(chart: chart)
        
        var dataSet = [IChartDataSet]()
        if candleData.entryCount > 0 {
            dataSet.append(candleData)
        }
        if emptyData.entryCount > 0 {
            dataSet.append(emptyData)
        }
        
        if self.showBollingerBand {
            let sigma1Data = self.makeBollingerData(chart: chart, level: 1)
            let sigma2Data = self.makeBollingerData(chart: chart, level: 2)
            let aveData = self.makeAverageData(chart: chart)
            if sigma1Data.entryCount > 0 {
                dataSet.append(sigma1Data)
            }
            if sigma2Data.entryCount > 0 {
                dataSet.append(sigma2Data)
            }
            if aveData.entryCount > 0 {
                dataSet.append(aveData)
            }
        }
        
        if self.showSma5 {
            let sma5Data = self.makeSma5Data(chart: chart)
            if sma5Data.entryCount > 0 {
                dataSet.append(sma5Data)
            }
        }
        
        if self.showSma25 {
            let sma25Data = self.makeSma25Data(chart: chart)
            if sma25Data.entryCount > 0 {
                dataSet.append(sma25Data)
            }
        }
        
        let chartData = CandleChartData(dataSets: dataSet)
        
        let formatterX = self.makeXAxisFormatter(chart: chart)
        
        self.delegate?.recievedChart(chartData: chartData, xFormatter: formatterX, yFormatter: YValueFormatter(), chart: chart)
    }
    
    fileprivate func makeXAxisFormatter(chart: CandleChart) -> XValueFormatter {
        let formatter = XValueFormatter()
        for i in 0 ..< chart.candles.count {
            let candle = chart.candles[i]
            formatter.times[i] = formatHms(timestamp: candle.startDate)
        }
        return formatter
    }
    
    fileprivate func makeCandleData(chart: CandleChart) -> CandleChartDataSet {
        var entries = [CandleChartDataEntry]()
        let candles = self.extractAvaliableCandles(chart: chart)
        for i in 0 ..< candles.count {
            let candle = candles[i]
            if !candle.isEmpty {
                let h = candle.highPrice
                let l = candle.lowPrice
                let o = candle.openPrice
                let lp = candle.lastPrice
                let entry = CandleChartDataEntry(x: Double(i), shadowH: h!, shadowL: l!, open: o!, close: lp!)
                entries.append(entry)
            }
        }

        return self.makeDataSet(entries: entries, label: "data")
    }
    
    fileprivate func makeEmptyData(chart: CandleChart) -> CandleChartDataSet {
        var entries = [CandleChartDataEntry]()
        let candles = self.extractAvaliableCandles(chart: chart)
        for i in 0 ..< candles.count {
            let candle = candles[i]
            if candle.isEmpty {
                let average = chart.average
                let entry = CandleChartDataEntry(x: Double(i), shadowH: average, shadowL: average, open: average, close: average)
                entries.append(entry)
            }
        }
        
        let dataSet = self.makeDataSet(entries: entries, label: "data")
        dataSet.neutralColor = UIColor.white
        return dataSet
    }
    
    fileprivate func makeBollingerData(chart: CandleChart, level: Int) -> CandleChartDataSet {
        var entries = [CandleChartDataEntry]()
        let candles = self.extractAvaliableCandles(chart: chart)
        for i in 0 ..< candles.count {
            let candle = candles[i]
            if !candle.isEmpty {
                let sigmaL = candle.getSigmaLower(level: level)
                let sigmaU = candle.getSigmaUpper(level: level)
                if sigmaL > 0.0 && sigmaU > 0.0 {
                    let entryL = CandleChartDataEntry(x: Double(i), shadowH: sigmaL, shadowL: sigmaL, open: sigmaL, close: sigmaL)
                    entries.append(entryL)
                    let entryU = CandleChartDataEntry(x: Double(i), shadowH: sigmaU, shadowL: sigmaU, open: sigmaU, close: sigmaU)
                    entries.append(entryU)
                }
            }
        }
        
        let dataSet = self.makeDataSet(entries: entries, label: "sigma" + level.description)
        let color = Color.bollingerColors[level - 1]
        dataSet.decreasingColor = color
        dataSet.increasingColor = color
        dataSet.neutralColor = color
        return dataSet
    }
    
    fileprivate func makeAverageData(chart: CandleChart) -> CandleChartDataSet {
        var entries = [CandleChartDataEntry]()
        let candles = self.extractAvaliableCandles(chart: chart)
        for i in 0 ..< candles.count {
            let candle = candles[i]
            if !candle.isEmpty {
                let ave = candle.totalAverage
                if ave > 0.0 {
                    let entry = CandleChartDataEntry(x: Double(i), shadowH: ave, shadowL: ave, open: ave, close: ave)
                    entries.append(entry)
                }
            }
        }
        
        let dataSet = self.makeDataSet(entries: entries, label: "average")
        dataSet.decreasingColor = Color.averageColor
        dataSet.increasingColor = Color.averageColor
        dataSet.neutralColor = Color.averageColor
        return dataSet
    }
    
    fileprivate func makeSma5Data(chart: CandleChart) -> CandleChartDataSet {
        var entries = [CandleChartDataEntry]()
        let candles = self.extractAvaliableCandles(chart: chart)
        for i in 0 ..< candles.count {
            let candle = candles[i]
            if !candle.isEmpty {
                let ave = candle.sma5
                if ave > 0.0 {
                    let entry = CandleChartDataEntry(x: Double(i), shadowH: ave, shadowL: ave, open: ave, close: ave)
                    entries.append(entry)
                }
            }
        }
        
        let dataSet = self.makeDataSet(entries: entries, label: "sma5")
        dataSet.decreasingColor = Color.averageColor
        dataSet.increasingColor = Color.averageColor
        dataSet.neutralColor = Color.averageColor
        return dataSet
    }
    
    fileprivate func makeSma25Data(chart: CandleChart) -> CandleChartDataSet {
        var entries = [CandleChartDataEntry]()
        let candles = self.extractAvaliableCandles(chart: chart)
        for i in 0 ..< candles.count {
            let candle = candles[i]
            if !candle.isEmpty {
                let ave = candle.sma25
                if ave > 0.0 {
                    let entry = CandleChartDataEntry(x: Double(i), shadowH: ave, shadowL: ave, open: ave, close: ave)
                    entries.append(entry)
                }
            }
        }
        
        let dataSet = self.makeDataSet(entries: entries, label: "sma25")
        dataSet.decreasingColor = Color.antiKeyColor2
        dataSet.increasingColor = Color.antiKeyColor2
        dataSet.neutralColor = Color.antiKeyColor2
        return dataSet
    }
    
    fileprivate func makeDataSet(entries: [CandleChartDataEntry], label: String) -> CandleChartDataSet {
        
        let dataSet = CandleChartDataSet(values: entries, label: label)
        dataSet.axisDependency = YAxis.AxisDependency.left;
        dataSet.shadowColorSameAsCandle = true
        dataSet.shadowWidth = 0.7
        dataSet.decreasingColor = Color.askQuoteColor
        dataSet.decreasingFilled = true
        dataSet.increasingColor = Color.bidQuoteColor
        dataSet.increasingFilled = true
        dataSet.neutralColor = UIColor.black
        dataSet.setDrawHighlightIndicators(false)
        return dataSet
    }
    
    fileprivate func extractAvaliableCandles(chart: CandleChart) -> [Candle] {
        return [Candle](chart.candles.suffix(self.availableCandleCount))
    }
    
    var delegate: CandleChartViewDelegate? = nil {
        willSet {
            if newValue == nil {
                if self.candleChart != nil {
                    self.candleChart.delegate = nil
                }
            } else {
                if self.candleChart != nil {
                    self.candleChart.delegate = self
                }
            }
        }
    }
    
    var monitoringInterval: UpdateInterval {
        get {
            return self.candleChart.monitoringInterval
        }
        set {
            self.candleChart.monitoringInterval = newValue
        }
    }
    
    var candleChart: CandleChart!
    fileprivate var _showBollingerBand = false
    fileprivate var _showSma5 = false
    fileprivate var _showSma25 = false
    let availableCandleCount = 60
}
