//
//  WeatherVC.swift
//  openweathermap
//
//  Created by Constantine Likhachov on 23.12.2020.
//

import UIKit
import RxSwift

class WeatherVC: UIViewController, MVVMViewController {
    
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    var viewModel: WeatherVMProtocol!
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewDidLoad()
        setupObservers()
    }
    
    func setupObservers() {
        viewModel.displayProgress = { (show) in
            show ? LoaderView.sharedInstance.start() : LoaderView.sharedInstance.stop()
        }
        
        viewModel.screenState.observeOn(MainScheduler.asyncInstance).subscribe(onNext: { [weak self] (weather) in
            guard let strongSelf = self else {return}
            strongSelf.updateData(weather)
        }).disposed(by: disposeBag)
        
        viewModel.statusMessageHandler.observeOn(MainScheduler.asyncInstance).subscribe(onNext: { [weak self] (statusMessage) in
            guard let strongSelf = self else {return}
            strongSelf.handleStatusMessage(statusMessage)
        }).disposed(by: disposeBag)
    }
    
    func updateData(_ weather: WeatherData) {
        cityLabel.text = weather.name
        temperatureLabel.text = weather.main.temp.unitCelsius()
    }
}
