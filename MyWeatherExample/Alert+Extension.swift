//
//  Alert+Extension.swift
//  MyMediaUIExample
//
//  Created by bro on 2022/05/06.
//

import UIKit

extension UIViewController {
    
    func showAlert(title: String, message: String, okTitle: String, okAction: @escaping () -> () ) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        
        let ok = UIAlertAction(title: okTitle, style: .default) { _ in
            okAction()
        }
        
        alert.addAction(cancel)
        alert.addAction(ok)
        
        self.present(alert, animated: true)
    }
    
    func openSettingURL() {
        guard let settingURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(settingURL) {
            UIApplication.shared.open(settingURL, options: [:], completionHandler: nil)
        }
    }
}
