//
//  ViewController.swift
//  silverblog
//
//  Created by qwe7002 on 2018/3/11.
//  Copyright © 2018年 qwe7002. All rights reserved.
//

import UIKit
import Alamofire
import public_func

class ViewController: UIViewController {
    let USER_CONFIG = UserDefaults(suiteName: public_func.USER_DEFAULTS_GROUP)!
    var config_list: [String: Any] = [:]
    @IBOutlet weak var server_name: UITextField!
    @IBOutlet weak var password: UITextField!

    @IBOutlet weak var previson_button: UIButton!
    @IBAction func on_previson_click(_ sender: Any) {
        let actionSheetController: UIAlertController = UIAlertController(title: "Config list", message: "Please select the config", preferredStyle: .actionSheet)
        config_list.forEach { (key,value) in
            actionSheetController.addAction(UIAlertAction(title: key, style: .default,handler: { (action: UIAlertAction!) -> () in
                let self_server_url = key
                let self_password = value as! String
                self.save_info(server: self_server_url,password: self_password)
                self.push_view()
            }))
        }
        if(config_list.count != 0){
            actionSheetController.addAction(UIAlertAction(title: "Clean", style: .destructive,handler: {(action: UIAlertAction!) -> () in
                self.config_list = [:]
                self.USER_CONFIG.set(self.config_list,forKey: "config_list_v2")
                self.USER_CONFIG.synchronize()
            }))
        }
        actionSheetController.popoverPresentationController?.sourceView = self.previson_button
        actionSheetController.popoverPresentationController?.sourceRect = self.previson_button.bounds
        actionSheetController.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler: nil))
        self.present(actionSheetController, animated: true, completion: nil)
    }
    @IBAction func on_enter_click(_ sender: Any) {
        self.view.endEditing(true)
        let self_password=public_func.hmac_hex(hashName: "SHA256", message: public_func.md5(password.text!), key: "SiLvErBlOg")
        let self_server_url=server_name.text!.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "http://", with: "").replacingOccurrences(of: "https://", with: "")
        if (self_password == "" || self_server_url == "") {
            let alertController = UIAlertController(title: "Error", message: "site address or password cannot be blank.", preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "ok", style: UIAlertAction.Style.default)
            alertController.addAction(okAction);
            self.present(alertController, animated: true, completion: nil)
            return
        }
        let doneController = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating();
        doneController.view.addSubview(loadingIndicator)
        self.present(doneController, animated: true, completion: nil)
        AF.request("https://" + self_server_url + "/control", method: .options).validate(statusCode: 204...204).responseJSON { response in
            doneController.dismiss(animated: true)
            switch response.result {
            case .success:
                self.password.text = ""
                self.server_name.text = ""
                self.save_info(server: self_server_url, password: self_password)
                self.push_view()
            case .failure(let error):
                print(error)
                let alert = UIAlertController(title: "Failure", message: "This site cannot be connected.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
        }


    }
    func push_view(){
        let sb = UIStoryboard(name:"Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "post_list") as! UITabBarController
        self.navigationController!.pushViewController(vc, animated:true)
    }
    func save_info(server: String,password: String){
            USER_CONFIG.set(server, forKey: "server")
            USER_CONFIG.set(password, forKey: "password")
            config_list[server] = password
            USER_CONFIG.set(config_list,forKey: "config_list_v2")
            USER_CONFIG.synchronize()
            global_value.server_url=server
            global_value.password=password
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (global_value.is_scan){
            global_value.is_scan=false
            //scan_result
            save_info(server: global_value.server_url,password: global_value.password)
            push_view()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if (USER_CONFIG.dictionary(forKey: "config_list_v2") != nil){
            config_list = USER_CONFIG.dictionary(forKey: "config_list_v2")!
        }
    }
}

