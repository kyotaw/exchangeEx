//
//  OrdersViewController.swift
//  zai
//
//  Created by Kyota Watanabe on 12/24/16.
//  Copyright © 2016 Kyota Watanabe. All rights reserved.
//

import Foundation
import UIKit


class OrdersViewController : UIViewController, OrderListViewDelegate, AppBackgroundDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = Color.keyColor
        if let image = self.tabBarController?.tabBar.items?[0].selectedImage {
            self.tabBarController?.tabBar.items?[0].selectedImage = image.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        }
        if let image = self.tabBarController?.tabBar.items?[0].image {
            self.tabBarController?.tabBar.items?[0].image = image.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        }
        
        self.ordersHeadersLabel.backgroundColor = Color.keyColor2
        
        self.orderListView = OrderListView(view: self.orderTableView)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.start()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.stop()
    }
    
    fileprivate func start() {
        setBackgroundDelegate(delegate: self)
        let account = getAccount()!
        let trader = account.activeExchange.trader
        self.orderListView.delegate = self
        self.orderListView.startWatch(trader: trader)
        self.orderListView.reloadData()
        
        trader.stopWatch()
    }
    
    fileprivate func stop() {
        self.orderListView.stopWatch()
        self.orderListView.delegate = nil
    }
    
    @IBAction func pushSettingsButton(_ sender: Any) {
        let storyboard: UIStoryboard = self.storyboard!
        let settings = storyboard.instantiateViewController(withIdentifier: "settingsViewController") as! UINavigationController
        self.present(settings, animated: true, completion: nil)
    }
    
    // OrderListViewDelegate
    func error(error: ZaiError) {
        let errorView = createErrorModal(title: error.errorType.toString(), message: error.message)
        self.present(errorView, animated: false, completion: nil)
    }
    
    // AppBackgroundDelegate
    func applicationDidBecomeActive(_ application: UIApplication) {
        self.start()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        self.stop()
    }
    
    var account: Account?
    var orderListView: OrderListView!
    
    @IBOutlet weak var ordersHeadersLabel: UILabel!
    @IBOutlet weak var orderTableView: UITableView!
}
