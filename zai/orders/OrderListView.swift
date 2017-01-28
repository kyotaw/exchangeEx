//
//  OrderListView.swift
//  zai
//
//  Created by 渡部郷太 on 12/24/16.
//  Copyright © 2016 watanabe kyota. All rights reserved.
//

import Foundation
import UIKit


class OrderListView : NSObject, UITableViewDelegate, UITableViewDataSource, ActiveOrderDelegate, OrderListViewCellDelegate {
    
    init(view: UITableView, trader: Trader) {
        self.trader = trader
        self.orders = [ActiveOrder]()
        self.view = view
        self.view.tableFooterView = UIView()
        
        super.init()
        self.view.delegate = self
        self.view.dataSource = self
        self.orderMonitor = ActiveOrderMonitor(currencyPair: .BTC_JPY, api: self.trader.exchange.api)
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.orders.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "orderListViewCell", for: indexPath) as! OrderListViewCell
        let row = indexPath.row
        let order = self.orders[row]
        cell.setOrder(order: order)
        cell.delegate = self

        return cell
    }
    
    public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let cell = self.view.cellForRow(at: indexPath) as? OrderListViewCell else {
            return nil
        }
        var actions = [UITableViewRowAction]()
        if let action = cell.cancelAction {
            actions.append(action)
        }
        if actions.count == 0 {
            let empty = UITableViewRowAction(style: .normal, title: nil) { (_, _) in }
            empty.backgroundColor = UIColor.white
            return [empty]
        } else {
            return actions
        }
    }
    
    func pushedCancelButton(cell : OrderListViewCell, order: ActiveOrder) {
        if cell.activeIndicator.isAnimating {
            return
        }
        cell.activeIndicator.startAnimating()
        self.trader.cancelOrder(id: order.id) { err in
            if let e = err {
                if e.errorType == .INVALID_ORDER {
                    self.trader.exchange.api.cancelOrder(order: order, retryCount: 2) { _ in
                        cell.activeIndicator.stopAnimating()
                    }
                } else {
                    cell.activeIndicator.stopAnimating()
                }
            } else {
                cell.activeIndicator.stopAnimating()
            }
        }
    }
    
    internal func reloadData() {
        self.view.reloadData()
    }
    
    internal func startWatch() {
        self.orderMonitor?.monitoringInterval = getOrdersConfig().orderUpdateIntervalType
        self.orderMonitor?.delegate = self
    }
    
    internal func stopWatch() {
        self.orderMonitor?.delegate = nil
    }
    
    // MonitorableDelegate
    func getDelegateName() -> String {
        return "OrderListView"
    }
    
    // ActiveOrderDelegate
    func revievedActiveOrders(activeOrders: [String: ActiveOrder]) {
        let myOrders = self.filterOrders(activeOrders: activeOrders)
        let prevSize = self.orders.count
        self.orders.removeAll()
        for order in myOrders {
            self.orders.append(order)
        }
        self.orders = self.orders.sorted{ $0.timestamp < $1.timestamp }
        if prevSize != self.orders.count {
            DispatchQueue.main.async {
                self.reloadData()
            }
        } else {
            for i in 0 ..< self.orders.count {
                let index = IndexPath(row: i, section: 0)
                guard let cell = self.view.cellForRow(at: index) as? OrderListViewCell else {
                    DispatchQueue.main.async {
                        self.reloadData()
                    }
                    return
                }
                cell.setOrder(order: self.orders[i])
            }
        }
    }
    
    fileprivate func filterOrders(activeOrders: [String: ActiveOrder]) -> [ActiveOrder] {
        var myOrders = [ActiveOrder]()
        for order in self.trader.activeOrders {
            guard let id = order.orderId else {
                continue
            }
            guard let activeOrder = activeOrders[id] else {
                continue
            }
            myOrders.append(activeOrder)
        }
        return myOrders
    }
    
    fileprivate var orders: [ActiveOrder]
    fileprivate let view: UITableView
    
    var trader: Trader! = nil
    var orderMonitor: ActiveOrderMonitor?
}
