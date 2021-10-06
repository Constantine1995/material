//
//  WeatherVM.swift
//  openweathermap
//
//  Created by Constantine Likhachov on 23.12.2020.
//

import RxSwift
import RxCocoa

// MARK:- Protocol

protocol WeatherVMProtocol {
    var screenState: PublishSubject<WeatherData> { get set }
    var statusMessageHandler: PublishSubject<StatusMessage> { get set }
    var displayProgress: ((Bool) -> Void)? { get set }
    func viewDidLoad()
}

class WeatherVM: MVVMViewModel {
    
    let router: MVVMRouter
    let weatherService: WeatherServiceType
    
    var displayProgress: ((Bool) -> Void)?
    var statusMessageHandler = PublishSubject<StatusMessage>()
    var screenState = PublishSubject<WeatherData>()
    
    //==============================================================================
    
    init(with router: MVVMRouter, weatherService: WeatherServiceType) {
        self.router = router
        self.weatherService = weatherService
    }
    
    //==============================================================================
}

extension WeatherVM: WeatherVMProtocol {
   
    func viewDidLoad() {
        loadWeather()
    }
    
    func loadWeather() {
        weatherService.loadWeather { [weak self] (result) in
            guard let strongSelf = self else { return }
            strongSelf.displayProgress?(true)
            switch result {
            case .success(let weather):
                strongSelf.screenState.onNext(weather)
            case .failure(let statusMessage):
                strongSelf.statusMessageHandler.onNext(statusMessage)
            }
            strongSelf.displayProgress?(false)
        }
    }
    
}

