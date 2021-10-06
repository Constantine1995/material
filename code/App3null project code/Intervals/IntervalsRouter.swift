//
//  IntervalsRouter.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 30.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import Foundation
import UIKit

class IntervalsRouter: MVVMRouter {

    enum PresentationContext {
        case fromHome
    }

    enum RouteType {
        case showIntervalDetails(Interval)
        case showIntervalSchedules
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

        let vc = IntervalsVC.instantiateFromStoryboard(storyboardName: "Intervals", storyboardId: "IntervalsVC")
        let viewModel = IntervalsVM.init(with: self, dataManager: dependencies.dataManager)
        vc.viewModel = viewModel

        switch presentationContext {
        case .fromHome:
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
        case .showIntervalDetails(let interval):
            let intervalDetailsRouter = IntervalDetailsRouter(dependencies: dependencies)
            let intervalDetailsContext = IntervalDetailsRouter.PresentationContext.fromInterval(interval)
            intervalDetailsRouter.present(on: nc, animated: true, context: intervalDetailsContext, completion: nil)
        case .showIntervalSchedules:
            let router = IntervalSchedulesRouter(dependencies: dependencies)
            let context = IntervalSchedulesRouter.PresentationContext.setAsRoot
            router.present(on: nc, animated: true, context: context, completion: nil)
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
