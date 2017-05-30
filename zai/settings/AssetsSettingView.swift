//
//  AssetsSettingView.swift
//  zai
//
//  Created by Kyota Watanabe on 1/18/17.
//  Copyright © 2017 Kyota Watanabe. All rights reserved.
//

import Foundation
import UIKit


protocol AssetsSettingViewDelegate {
    func changeUpdateInterval(setting: AssetsSettingView)
}



class AssetsSettingView : SettingView, VariableSettingCellDelegate {
    
    override init(section: Int, tableView: UITableView) {
        self._config = getAssetsConfig()
        super.init(section: section, tableView: tableView)
    }
    
    override func getCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        switch row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "variableSettingCell", for: indexPath) as! VariableSettingCell
            cell.nameLabel.text = LabelResource.updateInterval
            cell.valueLabel.text = self._config.assetUpdateIntervalType.string
            cell.delegate = self
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "readOnlySettingCell", for: indexPath) as! ReadOnlySettingCell
            return cell
        }
    }
    
    override func shouldHighlightRowAt(row: Int) -> Bool {
        switch row {
        case 0:
            return true
        default:
            return false
        }
    }
    
    func updateAutoUpdateInterval(tableView: UITableView, interval: UpdateInterval) {
        let index = IndexPath(row: 0, section: self.section)
        guard let cell = tableView.cellForRow(at: index) as? VariableSettingCell else {
            return
        }
        cell.valueLabel.text = interval.string
    }
    
    // VariableSettingCellDelegate
    func touchesEnded(id: Int, name: String, value: String) {
        self.delegate?.changeUpdateInterval(setting: self)
    }
    
    // ChangeUpdateIntervalDelegate
    override func saved(interval: UpdateInterval) {
        self._config.assetUpdateIntervalType = interval
        self.updateAutoUpdateInterval(tableView: self.tableView, interval: interval)
    }
    
    override var sectionName: String {
        return "Assets"
    }
    
    override var rowCount: Int {
        return 1
    }
    
    override var updateInterval: UpdateInterval {
        return self.self._config.assetUpdateIntervalType
    }
    
    
    let _config: AssetsConfig
    var delegate: AssetsSettingViewDelegate?
}
