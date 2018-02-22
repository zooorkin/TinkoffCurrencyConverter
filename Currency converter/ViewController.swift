//
//  ViewController.swift
//  Currency converter
//
//  Created by Андрей Зорькин on 09.02.18.
//  Copyright © 2018 Андрей Зорькин. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var oneLabel: UILabel!
    @IBOutlet weak var equalLabel: UILabel!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var pickerFrom: UIPickerView!
    @IBOutlet weak var pickerTo: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var activityIndicatorLarge: UIActivityIndicatorView!
    var currencies = [String]()
    @IBOutlet weak var updateLabel: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var usdLabel: UIButton!
    @IBOutlet weak var eurLabel: UIButton!
    @IBOutlet weak var gbpLabel: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.oneLabel.isHidden = true
        self.pickerFrom.isHidden = true
        self.equalLabel.isHidden = true
        self.label.isHidden = true
        self.pickerTo.isHidden = true

        self.updateLabel.isHidden = true
        self.messageLabel.isHidden = true
        
        self.usdLabel.isEnabled = false
        self.eurLabel.isEnabled = false
        self.gbpLabel.isEnabled = false
        
        self.label.text = "1"
        self.pickerFrom.dataSource = self
        self.pickerTo.dataSource = self
        
        self.pickerFrom.delegate = self
        self.pickerTo.delegate = self
        
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicatorLarge.hidesWhenStopped = true
        
        self.requestCurrentCurrencies()

    }
    
    func goto(from: String, to: String){
        if let fromIndex = currencies.index(of: from), let toIndex = currencies.index(of: to){
        pickerFrom.selectRow(fromIndex, inComponent: 0, animated: true)
        pickerTo.selectRow(toIndex, inComponent: 0, animated: true)
        self.requestCurrentCurrencyRate()
        }
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return currencies.count
        
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return currencies[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
                if pickerFrom.selectedRow(inComponent: 0) == pickerTo.selectedRow(inComponent: 0) {
                    label.text = "1"
                }else{
                    requestCurrentCurrencyRate()
        }
    }
    
    func requestCurrentCurrencyRate(){
        self.activityIndicator.startAnimating()
        self.label.text = ""
        
        let baseCurrencyIndex = self.pickerFrom.selectedRow(inComponent: 0)
        let toCurrencyIndex = self.pickerTo.selectedRow(inComponent: 0)

        let baseCurrency = self.currencies[baseCurrencyIndex]
        let toCurrency = self.currencies[toCurrencyIndex]
        
        self.retrieveCurrencyRate(baseCurrency: baseCurrency, toCurrency: toCurrency){ [weak self] (value) in
            DispatchQueue.main.async(execute:{
                if let strongSelf = self{
                    strongSelf.label.text = value
                    strongSelf.activityIndicator.stopAnimating()
                }
            })
        }
    }
    
    func requestCurrentCurrencies(){
        self.updateLabel.isHidden = true
        self.messageLabel.isHidden = true
        self.activityIndicatorLarge.startAnimating()
        self.retrieveCurrencies(){ [weak self] (names) in
            DispatchQueue.main.async(execute:{
                if let strongSelf = self{
                    strongSelf.oneLabel.isHidden = true
                    strongSelf.pickerFrom.isHidden = true
                    strongSelf.equalLabel.isHidden = true
                    strongSelf.label.isHidden = true
                    strongSelf.pickerTo.isHidden = true
                    strongSelf.usdLabel.isHidden = true
                    strongSelf.eurLabel.isHidden = true
                    strongSelf.gbpLabel.isHidden = true
                    strongSelf.usdLabel.isEnabled = false
                    strongSelf.eurLabel.isEnabled = false
                    strongSelf.gbpLabel.isEnabled = false
                    
                    if names.count != 0{
                    strongSelf.currencies = names
                        strongSelf.pickerFrom.reloadAllComponents()
                        strongSelf.pickerTo.reloadAllComponents()
                        strongSelf.activityIndicatorLarge.stopAnimating()
                        strongSelf.oneLabel.isHidden = false
                        strongSelf.pickerFrom.isHidden = false
                        strongSelf.equalLabel.isHidden = false
                        strongSelf.label.isHidden = false
                        strongSelf.pickerTo.isHidden = false
                        strongSelf.goto(from: "USD", to: "RUB")
                        strongSelf.usdLabel.isHidden = false
                        strongSelf.eurLabel.isHidden = false
                        strongSelf.gbpLabel.isHidden = false
                        strongSelf.usdLabel.isEnabled = true
                        strongSelf.eurLabel.isEnabled = true
                        strongSelf.gbpLabel.isEnabled = true
                    }else {
                        strongSelf.activityIndicatorLarge.stopAnimating()
                        strongSelf.updateLabel.isHidden = false
                        strongSelf.messageLabel.isHidden = false
                    }

                }
            })
        }
        
    }

    func requestCurrencyRates(baseCurrency: String, parseHandler: @escaping (Data?, Error?)-> Void){
        let url = URL(string: "https://api.fixer.io/latest?base=" + baseCurrency)!
        let dataTask = URLSession.shared.dataTask(with: url){
            (dataRecieved, response, error) in
            parseHandler(dataRecieved, error)
        }
        dataTask.resume()
    }
    
    func requestCurrencies(parseHandler: @escaping (Data?, Error?)-> Void){
        let url = URL(string: "https://api.fixer.io/latest")!
        let dataTask = URLSession.shared.dataTask(with: url){
            (dataRecieved, response, error) in
            parseHandler(dataRecieved, error)
        }
        dataTask.resume()
    }
    
    func parseCurrencyRatesResponse(data: Data?, toCurrency: String) -> String{
        var value: String = ""
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: [])
                as? Dictionary<String, Any>
            if let parsedJSON = json{
                print(parsedJSON)
                if let rates = parsedJSON["rates"] as? Dictionary<String, Double>{
                    if let rate = rates[toCurrency]{
                        value = String(rate)
                    } else {
                        value = "No rate for currency \"\(toCurrency)\" found"
                    }
                } else{
                    value = "No \"rates\" field found"
                }
            } else {
                value = "No JSON value parsed"
            }
        } catch {
            value = error.localizedDescription
        }
        return value
    }
    
    func parseCurrenciesResponse(data: Data?) -> [String]{
        var names = [String]()
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: [])
                as? Dictionary<String, Any>
            if let parsedJSON = json{
                print(parsedJSON)
                if let base = parsedJSON["base"] as? String, let rates = parsedJSON["rates"] as? Dictionary<String, Double>{
                   names.append(base)
                    for each in rates{
                        names.append(each.key)
                    }
                }
            }
        } catch {
        }
        print(names)
        names.sort()
        return names
    }

    func retrieveCurrencyRate(baseCurrency: String, toCurrency: String,
                              complition: @escaping (String) -> Void){
        self.requestCurrencyRates(baseCurrency: baseCurrency){
            [weak self] (data, error) in
            var string = "No currency retrieved!"
            
            if error != nil{
                if let strongSelf = self{
                    string = ""
                    strongSelf.requestCurrentCurrencies()
                }
                //string = currentError.localizedDescription
            } else {
                if let strongSelf = self{
                    string = strongSelf.parseCurrencyRatesResponse(data: data, toCurrency: toCurrency)
                }
            }
            
            complition(string)
        }
    }
    
    func retrieveCurrencies(complition: @escaping ([String]) -> Void){
        self.requestCurrencies(){ [weak self] (data, error) in
            var strings = [String]()
            
            if error == nil{
                if let strongSelf = self{
                    strings = strongSelf.parseCurrenciesResponse(data: data)
                }
            }
            
            complition(strings)
        }
    }
    
    @IBAction func usd(_ sender: Any) {
        self.goto(from: "USD", to: "RUB")
    }
    @IBAction func eur(_ sender: Any) {
        self.goto(from: "EUR", to: "RUB")
    }
    @IBAction func gbp(_ sender: Any) {
        self.goto(from: "GBP", to: "RUB")
    }
    
    @IBAction func update(_ sender: Any) {
        requestCurrentCurrencies()
    }
}

