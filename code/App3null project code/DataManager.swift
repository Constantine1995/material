//
//  DataManager.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 23.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import Foundation
import CoreData

enum EntityNames: String {
    case User
    case Interval
    case IntervalSchedule
    case Event
    case Note
    case Contact
}

protocol DataManagerProtocol {

    // MARK: - User
    func createAndSaveUser()
    func getUser() -> User?
    func clearDB()
    func saveTaskContext()

    // MARK: - Intervals
    func getIntervals() -> [Interval]?
    func updateDrugName(for interval: Interval, name: String, eye: EyeType)
    func updateTime(for interval: Interval, time: Int)
    func getIntervalsForToday() -> [IntervalSchedule]?
    func intervalScheduleFetchController(fromDate: Date?, toDate: Date?) -> NSFetchedResultsController<NSFetchRequestResult>

    // MARK: - Event
    func getEvents(fromDate: Date?, toDate: Date?) -> [Event]?
    func getFalseEvent() -> Event
    func updateEvent()
    func createEvent(eventType: EventType, date: Date)
    func deleteEvent(event: Event)

    // MARK: - Notes
    func getNotes(fromDate: Date?, toDate: Date?) -> [Note]?
    func getFalseNote(forDate: Date) -> Note
    func insertFalseNote(note: Note)
    func updateNote()
    func createNote(date: Date, noteValue: String)
    func deleteNote(note: Note)

    // MARK: - Contact
    func getContact(type: ContactType) -> Contact?
    func updateContact()
    func createContact(type: ContactType)
    func deleteContact(contact: Contact)
}

class DataManager: DataManagerProtocol {

    let persistentContainer: NSPersistentContainer

    //==============================================================================

    init() {
        let container = NSPersistentContainer(name: "Model")
        persistentContainer = container

        container.loadPersistentStores { _, error in
            guard error == nil else {
                fatalError("Unresolved error \(error!)")
            }
            container.viewContext.automaticallyMergesChangesFromParent = false
            container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            container.viewContext.undoManager = nil
            container.viewContext.shouldDeleteInaccessibleFaults = true
            self.createIntervals()
            self.createIntervalScheduleForToday()
        }
    }

    //==============================================================
    // MARK: - Intervals
    //==============================================================

    /// Intervals should be create only once.
    private func createIntervals() {
        guard let intervals = getIntervals(), !intervals.isEmpty  else {
            let context = persistentContainer.viewContext
            //Hours
            let timeIntervals = [(6, 9), (9, 12), (12, 15), (15, 18), (18, 21), (21, 23)]

            for (start, end) in timeIntervals {
                let interval = Interval(context: context)
                interval.time = Int64(start.hoursToSeconds())
                interval.startTime = Int64(start.hoursToSeconds())
                interval.endTime = Int64(end.hoursToSeconds())
                interval.id = UUID()
            }

            context.saveContext()
            return
        }
    }

    //==============================================================================

    func getIntervals() -> [Interval]? {
        let context = persistentContainer.viewContext
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: EntityNames.Interval.rawValue)

        do {
            return try context.fetch(fetch) as? [Interval]
        } catch {
            return nil
        }
    }

    //==============================================================================

    /// Updates name for Interval and for future IntervalSchedule. Deletes IntervalSchedule if drugs name fields are empty.
    func updateDrugName(for interval: Interval, name: String, eye: EyeType) {
        switch eye {
        case .left:
            interval.leftEyeDrugName = name
        case .right:
            interval.rightEyeDrugName = name
        }

        let context = persistentContainer.viewContext
        context.saveContext()

        guard let intervalSchedule = findLatestIntervalSchedule(for: interval) else {
            let (hours, minutes) = Int(interval.time).secondsToHourAndMin()
            guard let date = Calendar.current.date(bySettingHour: hours, minute: minutes, second: 0, of: Date()) else { return  }
            if date > Date() {
                createIntervalSchedule(for: interval)
                context.saveContext()
            }
            return
        }
        if !intervalSchedule.isExpired {
            if interval.isDrugs {
                switch eye {
                case .left:
                    intervalSchedule.leftEyeDrugName = name
                case .right:
                    intervalSchedule.rightEyeDrugName = name
                }
            } else {
                context.delete(intervalSchedule)
            }
            context.saveContext()
        }
    }

    //==============================================================================

    /// Updates time for Interval and for future IntervalSchedule
    func updateTime(for interval: Interval, time: Int) {
        interval.time = Int64(time)
        let context = persistentContainer.viewContext
        context.saveContext()

        guard let intervalSchedule = findLatestIntervalSchedule(for: interval) else { return }
        if !intervalSchedule.isExpired {
            let (hours, minutes) = Int(interval.time).secondsToHourAndMin()
            let date = Calendar.current.date(bySettingHour: hours, minute: minutes, second: 0, of: Date())
            intervalSchedule.date = date
            context.saveContext()
        }
    }

    //==============================================================================

    func createIntervalSchedule(for interval: Interval) {
        let context = persistentContainer.viewContext
        let intervalSchedule = IntervalSchedule(context: context)
        intervalSchedule.intervalID = interval.id
        intervalSchedule.leftEyeDrugName = interval.leftEyeDrugName
        intervalSchedule.rightEyeDrugName = interval.rightEyeDrugName
        let (hours, minutes) = Int(interval.time).secondsToHourAndMin()
        let date = Calendar.current.date(bySettingHour: hours, minute: minutes, second: 0, of: Date())
        intervalSchedule.date = date
    }

    //==============================================================================

    func findLatestIntervalSchedule(for interval: Interval) -> IntervalSchedule? {
        guard let date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) else { return nil }
        let context = persistentContainer.viewContext
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: EntityNames.IntervalSchedule.rawValue)
        let predicate = NSPredicate(format: "intervalID == %@ AND date > %@", interval.id! as CVarArg, date as NSDate)
        fetch.predicate = predicate
        do {
            let schedules = try context.fetch(fetch) as? [IntervalSchedule]
            return schedules?.first
        } catch {
            return nil
        }
    }

    //==============================================================================

    func intervalScheduleFetchController(fromDate: Date?, toDate: Date?) -> NSFetchedResultsController<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: EntityNames.IntervalSchedule.rawValue)
        let completedDate = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [ completedDate]

        var predicate: NSPredicate?

        if let fromDate = fromDate, let toDate = toDate {
            let from = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: fromDate) ?? Date()
            let to = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: toDate) ?? Date()
            predicate = NSPredicate(format: "date >= %@ AND date <= %@", from as NSDate, to as NSDate)
        } else {
            let date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) ?? Date()
            predicate = NSPredicate(format: "date > %@", date as NSDate)
        }

        if predicate != nil {
            fetchRequest.predicate = predicate
        }

        let fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchController
    }

    //==============================================================================

    func getIntervalsForToday() -> [IntervalSchedule]? {
        guard let date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) else { return nil }
        let context = persistentContainer.viewContext
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: EntityNames.IntervalSchedule.rawValue)
        let predicate = NSPredicate(format: "date > %@", date as NSDate)
        fetch.predicate = predicate
        do {
            let schedules = try context.fetch(fetch) as? [IntervalSchedule]
            return schedules
        } catch {
            return []
        }
    }

    //==============================================================================

    /// Each new day we should generate new IntervalSchedules from the Intervals for the current date.
    private func createIntervalScheduleForToday() {
        // Check, maybe we olready have IntervalSchedules for today
        if let intervalSchedules = getIntervalsForToday(), !intervalSchedules.isEmpty {
            return
        }
        guard let intervals = getIntervals() else { return }

        for interval in intervals {
            if interval.isDrugs {
                createIntervalSchedule(for: interval)
            }
        }
        let context = persistentContainer.viewContext
        context.saveContext()
    }

    //==============================================================
    // MARK: - EVENTs
    //==============================================================

    func getEvents(fromDate: Date?, toDate: Date?) -> [Event]? {
        let context = persistentContainer.viewContext
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Event")
        if let fromDate = fromDate as NSDate?, let toDate = toDate as? NSDate {
            let predicate = NSPredicate(format: "date >= %@ AND date <= %@", fromDate, toDate)
            fetch.predicate = predicate
            fetch.sortDescriptors = [NSSortDescriptor.init(key: "date", ascending: true)]
        }
        do {
            let events = try context.fetch(fetch) as? [Event]
            return events
        } catch {
            return []
        }
    }

    //==============================================================

    func getFalseEvent() -> Event {
        let context = persistentContainer.viewContext
        let eventNoteDescription = NSEntityDescription.entity(forEntityName: "Event", in: context)
        let eventNote = NSManagedObject(entity: eventNoteDescription!, insertInto: nil)
        return eventNote as! Event // swiftlint:disable:this force_cast
    }

    //==============================================================

    func updateEvent() {

    }

    //==============================================================

    func createEvent(eventType: EventType, date: Date) {
        let context = persistentContainer.viewContext

        let event = NSEntityDescription.insertNewObject(forEntityName: EntityNames.Event.rawValue, into: context) as? Event

        event?.eventType = eventType.rawValue
        event?.date = date

        // add contact info
        if let contactType = eventType.contactType, let contact = getContact(type: contactType) {
            event?.contactName = contact.contactName
            event?.address1 = contact.address1
            event?.address2 = contact.address2
        }

        do {
            try context.save()
        } catch {

        }

    }

    //==============================================================

    func deleteEvent(event: Event) {
        let context = persistentContainer.viewContext
        context.delete(event)
        do {
            try context.save()
        } catch {

        }
    }

    //==============================================================
    // MARK: - NOTEs
    //==============================================================

    func getNotes(fromDate: Date?, toDate: Date?) -> [Note]? {
        let context = persistentContainer.viewContext
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
        if let fromDate = fromDate as? NSDate, let toDate = toDate as? NSDate {
            let predicate = NSPredicate(format: "date >= %@ AND date <= %@", fromDate, toDate)
            fetch.predicate = predicate
            fetch.sortDescriptors = [NSSortDescriptor.init(key: "date", ascending: false)]
        }
        do {
            let notes = try context.fetch(fetch) as? [Note]
            return notes
        } catch {
            return []
        }
    }

    //==============================================================

    func getFalseNote(forDate: Date) -> Note {
        let context = persistentContainer.viewContext
        let noteDescription = NSEntityDescription.entity(forEntityName: "Note", in: context)
        let note = NSManagedObject(entity: noteDescription!, insertInto: nil)  as! Note // swiftlint:disable:this force_cast
        note.date = forDate
        return note
    }

    //==============================================================

    func insertFalseNote(note: Note) {
        let context = persistentContainer.viewContext
        context.insert(note)
        context.saveContext()
    }

    //==============================================================

    func updateNote() {

    }

    //==============================================================

    func createNote(date: Date, noteValue: String) {
        let context = persistentContainer.viewContext
        let note = NSEntityDescription.insertNewObject(forEntityName: EntityNames.Note.rawValue, into: context) as? Note

        note?.note = noteValue
        note?.date = date

        do {
            try context.save()
        } catch {

        }
    }

    //==============================================================

    func deleteNote(note: Note) {
        let context = persistentContainer.viewContext
        context.delete(note)
        do {
            try context.save()
        } catch {

        }
    }

    //==============================================================
    // MARK: - CONTACT
    //==============================================================

    func getContact(type: ContactType) -> Contact? {
        let context = persistentContainer.viewContext
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Contact")
        let predicate = NSPredicate(format: "contactType == %@", type.rawValue)
        fetch.predicate = predicate

        var contact: Contact?
        do {
            contact = try (context.fetch(fetch) as? [Contact])?.first
        } catch {

        }
        if contact == nil {
            contact = NSEntityDescription.insertNewObject(forEntityName: EntityNames.Contact.rawValue, into: context) as? Contact
            contact?.contactType = type.rawValue
            context.saveContext()
        }
        return contact
    }

    //==============================================================

    func updateContact() {

    }

    //==============================================================

    func createContact(type: ContactType) {
        let context = persistentContainer.viewContext
        let contact = NSEntityDescription.insertNewObject(forEntityName: EntityNames.Contact.rawValue, into: context) as? Contact

        contact?.contactType = type.rawValue
        do {
            try context.save()
        } catch {

        }
    }

    //==============================================================

    func deleteContact(contact: Contact) {
        let context = persistentContainer.viewContext
        context.delete(contact)
        do {
            try context.save()
        } catch {

        }
    }

    //==============================================================
    // MARK: - USER
    //==============================================================

    func getUser() -> User? {
        let context = persistentContainer.viewContext
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: EntityNames.User.rawValue)
        fetch.fetchLimit = 1
        do {
            let user = try context.fetch(fetch) as? [User]
            return user?.first
        } catch {
            return nil
        }
    }

    //==============================================================================

    func createAndSaveUser() {
        let context = persistentContainer.viewContext
        if getUser() != nil {
            print("User alerdy exists")
        } else {
            do {
                let user = NSEntityDescription.insertNewObject(forEntityName: EntityNames.User.rawValue, into: context) as? User
                user?.firstRun = true
                try context.save()
            } catch {}
        }
    }

    //==============================================================
    // MARK: - OTHERS
    //==============================================================

    func clearDB() {
        let context = self.persistentContainer.viewContext
        let entities = self.persistentContainer.managedObjectModel.entities
        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name!)
            do {
                guard let objects = try context.fetch(fetchRequest) as? [NSManagedObject] else { return }
                for object in objects {
                    context.delete(object)
                }
            } catch { print(error) }
        }
        try? context.save()
    }

    //==============================================================

    func saveTaskContext() {
        let context = self.persistentContainer.viewContext
        context.saveContext()
    }

    //==============================================================
}

extension NSManagedObjectContext {
    func saveContext() {
        do {
            try save()
        } catch {
            print("Failure to save context: \(error)")
        }
    }
}
