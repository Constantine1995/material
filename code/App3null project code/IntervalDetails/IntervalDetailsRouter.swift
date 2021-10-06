//
//  IntervalDetailsRouter.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 30.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import UIKit

class IntervalDetailsRouter: MVVMRouter {

    enum PresentationContext {
        case fromInterval(Interval)
    }

    enum RouteType {
        case showTimeEntry(interval: Interval, delegate: TimeEntryDelegate?)
        case showMedicationEntry(data: MedNameData, delegate: MedNameEntryDelegate?)
    }

    weak var baseViewController: UIViewController?
    let dependencies: AppDependencies

    //==============================================================================

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    //==============================================================================

    func present(on baseVC: UIViewController, animated: Bool, context: Any?, completion: ((Bool) -> Void)?) {

        guard let presentationContext = context as? PresentationContext else {
            assertionFailure("The context type missmatch")
            return
        }

        guard let nc = baseVC as? UINavigationController else {
            assertionFailure("The baseVC should be UINavigationController")
            return
        }
        baseViewController = baseVC

        let vc = IntervalDetailsVC.instantiateFromStoryboard(storyboardName: "IntervalDetails", storyboardId: "IntervalDetailsVC")

        switch presentationContext {
        case .fromInterval(let interval):
            let viewModel = IntervalDetailsVM.init(with: self, dataManager: dependencies.dataManager, interval: interval)
            vc.viewModel = viewModel
            nc.pushViewController(vc, animated: false)
        }
    }

    //==============================================================================

    func enqueueRoute(with context: Any?, animated: Bool, completion: ((Bool) -> Void)?) {
        guard let routeType = context as? RouteType else {
            assertionFailure("The route type missmatches")
            return
        }

        guard let nc = baseViewController as? UINavigationController else {
            assertionFailure("The baseVC should be UINavigationController")
            return
        }

        switch routeType {
        case .showTimeEntry(let interval, let delegate):
            let timeEntryRouter = TimeEntryRouter(dependencies: dependencies)
            let timeEntryContext = TimeEntryRouter.PresentationContext.fromIntervalDetails(interval: interval, delegate: delegate)
            timeEntryRouter.present(on: nc, animated: true, context: timeEntryContext, completion: nil)
        case .showMedicationEntry(let data, let delegate):
            let medicationEntryRouter = MedNameEntryRouter(dependencies: dependencies)
            let medicationEntryContext = MedNameEntryRouter.PresentationContext.fromIntervalDetails(data: data, delegate: delegate)
            medicationEntryRouter.present(on: nc, animated: true, context: medicationEntryContext, completion: nil)
        }
    }

    //==============================================================================

    func dismiss(animated: Bool, context: Any?, completion: ((Bool) -> Void)?) {
        guard let nc = baseViewController as? UINavigationController else {
            assertionFailure("The baseVC should be UINavigationController")
            return
        }
        nc.popViewController(animated: true)
    }

    //==============================================================================
}
