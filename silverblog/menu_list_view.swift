//
//  menu_list_view.swift
//  silverblog
//
//  Created by qwe7002 on 2018/3/28.
//  Copyright © 2018年 qwe7002. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class menu_list_view: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var array_json = JSON()
    let refreshControl = UIRefreshControl()
    let net = NetworkReachabilityManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.refreshControl = refreshControl

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (global_value.reflush || array_json == JSON()) {
            global_value.reflush = false
            if net?.isReachable == false {
                let alert = UIAlertController(title: "Failure", message: "No network connection.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                self.refreshControl.endRefreshing()
                return
            }
            self.load_data(first_load: true)
        }
        self.tabBarController!.title = "Menu"

    }

    func load_data(first_load: Bool) {
        let alertController = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        if (first_load) {
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = UIActivityIndicatorView.Style.gray
            loadingIndicator.startAnimating();
            alertController.view.addSubview(loadingIndicator)
            self.present(alertController, animated: true, completion: nil)
        }

        AF.request("https://" + global_value.server_url + "/control/"+global_value.version+"/get/list/menu", method: .post, parameters: [:], encoding: JSONEncoding.default).validate().responseJSON { response in
            if (first_load) {
                alertController.dismiss(animated: true) {
                }
            }
            switch response.result.isSuccess {
            case true:
                if let value = response.result.value {
                    let jsonobj = JSON(value)
                    if (self.array_json != jsonobj) {
                        self.array_json = jsonobj
                        self.tableView.reloadData()
                    }
                }
            case false:
                let alert = UIAlertController(title: "Failure", message: "This site cannot be connected.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            self.refreshControl.endRefreshing()
        }
    }

    @objc func refresh(refreshControl: UIRefreshControl) {
        if net?.isReachable == false {
            let alert = UIAlertController(title: "Failure", message: "No network connection.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        load_data(first_load: false)

    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        if array_json[indexPath.row]["absolute"].string != nil {
            let url = URL(string: array_json[indexPath.row]["absolute"].string!)
            UIApplication.shared.open(url!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            return
        }
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "edit_post_view") as! edit_post_view
        vc.uuid = self.array_json[indexPath.row]["uuid"].string!
        vc.menu = true
        self.navigationController!.pushViewController(vc, animated: true)

    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.array_json.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        cell.textLabel?.text = self.array_json[indexPath.row]["title"].string
        return cell
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
