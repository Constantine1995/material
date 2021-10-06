//
//  Double+Extension.swift
//  openweathermap
//
//  Created by Constantine Likhachov on 23.12.2020.
//

import Foundation

extension Double {
    func unitCelsius() -> String {
        let temperature = Measurement(value: self, unit: UnitTemperature.celsius)
        return String(format: "%.0f \(temperature.unit.symbol)", temperature.value)
    }
}
