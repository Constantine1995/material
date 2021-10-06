//
//  CalendarRouter.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 24.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import Foundation
import UIKit

class CalendarRouter: MVVMRouter {

    enum PresentationContext {
        case fromHome
    }

    enum RouteType {
        case showEventDetails(events: [Event]?, note: Note)
        case showEvents
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

        let vc = CalendarVC.instantiateFromStoryboard(storyboardName: "Calendar", storyboardId: "CalendarVC")
        let viewModel = CalendarVM.init(with: self, dataManager: self.dependencies.dataManager)
        vc.viewModel = viewModel

        switch presentationContext {
        case .fromHome:
            nc.pushViewController(viewController: vc, animated: animated, completion: {
                completion?(true)
            })
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
        case .showEventDetails(let events, let note):
            let router = EventDetailsRouter(dependencies: dependencies)
            let context = EventDetailsRouter.PresentationContext.pushWith(events: events, note: note)
            router.present(on: nc, animated: true, context: context, completion: nil)
        case .showEvents:
            let eventsRouter = EventsRouter(dependencies: dependencies)
            let eventsContext = EventsRouter.PresentationContext.fromHome
            eventsRouter.present(on: nc, animated: true, context: eventsContext, completion: nil)
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
