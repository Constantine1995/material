//
//  TrainingsVM.swift
//  c4institut
//
//  Created by Constantine Likhachov on 25.06.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import Foundation
import CoreData
import Combine

// MARK:- Protocol

protocol TrainingsVMProtocol {
    var reloadTableView: PassthroughSubject<Void, Never> { get set }
    func fetchTrainings()
    func viewDidLoad()
    func getTableViewCellVM(at indexPath: IndexPath) ->  TableViewCellVM?
    func numberOfSections() -> Int
    func numberOfRow(in section: Int) -> Int
    func cellDidSelect(at indexPath: IndexPath)
    func sectionTitle(for section: Int) -> String
}

class TrainingsVM: NSObject, MVVMViewModel {
    
    let router: MVVMRouter
    let trainingsService: TrainingsServiceType
    var reloadTableView = PassthroughSubject<Void, Never>()
    private var trainingsFetchController: NSFetchedResultsController<NSFetchRequestResult>
    
    //==============================================================================
    
    init(with router: MVVMRouter, trainingsService: TrainingsServiceType) {
        self.router = router
        self.trainingsService = trainingsService
        self.trainingsFetchController = trainingsService.dataManager.fetchController(entityName: EntityNames.Training.rawValue)
        super.init()
    }
    
    //==============================================================================
    
    func viewDidLoad() {
        do {
            try trainingsFetchController.performFetch()
            self.trainingsFetchController.delegate = self
        } catch {}
    }
    
    //==============================================================================
    
    func getTableViewCellVM(at indexPath: IndexPath) ->  TableViewCellVM? {
        let training = trainingsFetchController.object(at: indexPath) as! Training
        var hideDate = false
        var strDate = ""
        if let date = training.startDate {
            strDate = Constant.dateFormatter.string(from: date)
        }
        if let type = TrainingType(rawValue: Int(training.type)), type == .all {
            hideDate = true
        }
        
        return TableViewCellVM(title: training.title ?? "", dateStr: strDate, hideDate: hideDate)
    }
    
    //==============================================================================
    
    func numberOfSections() -> Int {
        return trainingsFetchController.sections?.count ?? 0
    }
    
    //==============================================================================
    
    func numberOfRow(in section: Int) -> Int {
        if let sections = trainingsFetchController.sections {
            return sections[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    //==============================================================================
    
    func sectionTitle(for section: Int) -> String {
        if let sections = trainingsFetchController.sections {
            return sections[section].name == TrainingType.all.rawValue.description ? Localizations.Trainings.all_trainings : Localizations.Trainings.my_trainings
        } else {
            return ""
        }
    }
    
    //==============================================================================
    
    func cellDidSelect(at indexPath: IndexPath) {
        let training = trainingsFetchController.object(at: indexPath) as! Training
        router.enqueueRoute(with: TrainingsRouter.RouteType.showDetails(training))
    }
    
    //==============================================================================
    
    deinit {
       print(ConsoleHeader.dealloc(String(describing: self)))
    }
}

extension TrainingsVM: TrainingsVMProtocol {
    func fetchTrainings() {
        trainingsService.loadTrainings { [weak self] (result) in
            guard let self = self else {return}
            do {
                //self.trainingsFetchController.managedObjectContext.reset()
                try self.trainingsFetchController.performFetch()
            } catch {
                fatalError("Unresolved error \(error)")
            }
            self.reloadTableView.send(())
        }
    }
}

extension TrainingsVM: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        reloadTableView.send(())
    }
    
}


