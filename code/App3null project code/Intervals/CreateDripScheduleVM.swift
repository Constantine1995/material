//
//  IntervalsVM.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 30.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import Foundation

// MARK: - Protocol

struct MedicationData {
    var id: Int
    var title: String
    var intervalMax: Date
    var intervalMin: Date
}

protocol IntervalsVMProtocol {
    func numberOfRows() -> Int
    func getInterval(at index: Int) -> Interval
    func didSelectRow(at index: Int)
    func addButtonPressed()
    func dismiss()
}

class IntervalsVM: MVVMViewModel {

    let router: MVVMRouter
    let dataManager: DataManagerProtocol
    private let dataSource: [Interval]

    //==============================================================================

    init(with router: MVVMRouter, dataManager: DataManagerProtocol) {
        self.router = router
        self.dataManager = dataManager
        dataSource = (self.dataManager.getIntervals() ?? []).sorted(by: { $0.startTime < $1.startTime })
    }

    //==============================================================================
}

extension IntervalsVM: IntervalsVMProtocol {

    func numberOfRows() -> Int {
        return dataSource.count
    }

    func getInterval(at index: Int) -> Interval {
        let index = dataSource[index]
        return index
    }

    func didSelectRow(at index: Int) {
        let interval = getInterval(at: index)
        router.enqueueRoute(with: IntervalsRouter.RouteType.showIntervalDetails(interval))
    }

    func addButtonPressed() {
        print("addButtonPressed")
    }

    func dismiss() {
        dataManager.getIntervalsForToday() != nil ? showDripSchedule() : showHome()
    }

    private func showDripSchedule() {
        router.enqueueRoute(with: IntervalsRouter.RouteType.showDripSchedule)
    }

    private func showHome() {
        router.dismiss(animated: false, context: nil, completion: nil)
    }
}
