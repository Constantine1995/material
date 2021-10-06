//
//  IntervalsVM.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 30.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import Foundation

// MARK: - Protocol

protocol IntervalsVMProtocol {
    func numberOfRows() -> Int
    func getInterval(at index: Int) -> Interval
    func didSelectRow(at index: Int)
    func speakButtonPressed(indexPaths: [IndexPath])
    func dismiss()
    var delegate: TableViewDelegate? { get set }
}

class IntervalsVM: NSObject, MVVMViewModel {

    let router: MVVMRouter
    let dataManager: DataManagerProtocol
    private let dataSource: [Interval]
    lazy var speechSynthesizer: SpeechSynthesizerInterface = {
        SpeechSynthesizer(delegate: self)
    }()
    weak var delegate: TableViewDelegate?
    var speechData = [SpeechData]()

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
        speechSynthesizer.stopSpeaking()
        let interval = getInterval(at: index)
        router.enqueueRoute(with: IntervalsRouter.RouteType.showIntervalDetails(interval))
    }

    func setSpeechData(data: [SpeechData]) {
        speechSynthesizer.setSpeechData(data: data)
    }

    func speakButtonPressed(indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let interval = dataSource[indexPath.row]
            let data = SpeechData(text: interval.title, indexPath: indexPath)
            speechData.append(data)
            setSpeechData(data: speechData)
        }
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking()
        } else {
            speechSynthesizer.startSpeaking()
        }
    }

    func dismiss() {
        speechSynthesizer.stopSpeaking()
        dataManager.getIntervalsForToday() != [] ? showIntervalSchedules() : showHome()
    }

    private func showIntervalSchedules() {
        speechSynthesizer.stopSpeaking()
        router.enqueueRoute(with: IntervalsRouter.RouteType.showIntervalSchedules)
    }

    private func showHome() {
        router.dismiss(animated: false, context: nil, completion: nil)
    }
}

// MARK: - SpeechSynthesizerDelegate

extension IntervalsVM: SpeechSynthesizerDelegate {
    func speechStarted(for speechData: SpeechData) {
        delegate?.setHighlightCell(for: speechData, highlight: true)
    }

    func speechEnded(for speechData: SpeechData) {
        delegate?.setHighlightCell(for: speechData, highlight: false)
        self.speechData.removeAll()
    }

    func speechFinished() {
        delegate?.scrollToTop()
    }
}
