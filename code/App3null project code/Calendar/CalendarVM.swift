//
//  CalendarVM.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 24.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import Foundation
import Timepiece

// MARK: - Protocol

protocol CalendarVMProtocol {
    func createTableData(calendar: Calendar, tableData: [[CalendarTableData]]) -> [[CalendarTableData]]
    func createCalendarWeekCellModel(calendar: Calendar, weekDate: Date, largeStyle: Bool, delegate: CalendarWeekCellDelegate?) -> CalendarWeekCellModel
    func createCalendarMonthCellModel(month: String, year: String, largeStyle: Bool) -> CalendarMonthCellModel
    func getEvents(fromDate: Date, toDate: Date) -> [Event]?
    func getNotes(fromDate: Date, toDate: Date) -> [Note]?
    func daySelected(date: Date, events: [Event]?, note: Note?)
    func addButtonPressed()
    func dismiss()
}

class CalendarVM: MVVMViewModel {

    let router: MVVMRouter
    let dataManager: DataManagerProtocol

    //==============================================================================

    init(with router: MVVMRouter, dataManager: DataManagerProtocol) {
        self.router = router
        self.dataManager = dataManager
    }

    //==============================================================================
}

extension CalendarVM: CalendarVMProtocol {

    func createTableData(calendar: Calendar, tableData: [[CalendarTableData]]) -> [[CalendarTableData]] {
        var currentTableData = tableData

        // Current month's date.
        guard let currentMonth = Date().truncated(from: .hour)?.changed(day: 1) else { fatalError() }

        // Add the months before today.
        for diff in -Constant.month ... -1 {
            guard let date = currentMonth + diff.months else { fatalError() }
            let section = tableDataSection(calendar: calendar, date: date)
            currentTableData.append(section)
        }

        // Add the current month.
        let section = tableDataSection(calendar: calendar, date: currentMonth)
        currentTableData.append(section)

        // Add the months after today.
        for diff in 1 ... Constant.month {
            guard let date = currentMonth + diff.months else { fatalError() }
            let section = tableDataSection(calendar: calendar, date: date)
            currentTableData.append(section)
        }
        return currentTableData
    }

    private func tableDataSection(calendar: Calendar, date: Date) -> [CalendarTableData] {
        var section = [CalendarTableData]()

        // Add month title cell.
        let monthValue = date.month
        let yearValue = date.year
        guard let month = CalendarMonth(rawValue: monthValue) else { fatalError() }
        let monthCellType = CalendarTableData.month(month, yearValue)
        section.append(monthCellType)

        // Append the week cells.
        //        let currentCalendar = calendar
        let firstOfMonth = date.startOfMonth(calendar: calendar)
        let lastOfMonth = date.endOfMonth(calendar: calendar)
        var weekDate = firstOfMonth
        while weekDate <= lastOfMonth {
            let weekCellType = CalendarTableData.week(weekDate)
            section.append(weekCellType)
            weekDate = (weekDate + 1.week) ?? lastOfMonth
        }
        // Append the last week, handled explicitly because of the calculation.
        let firstOfWeek = weekDate.startOfWeek(calendar: calendar)
        if firstOfWeek <= lastOfMonth {
            let weekCellType = CalendarTableData.week(lastOfMonth)
            section.append(weekCellType)
        }
        return section
    }

    func createCalendarWeekCellModel(calendar: Calendar, weekDate: Date, largeStyle: Bool, delegate: CalendarWeekCellDelegate?) -> CalendarWeekCellModel {

        // Go through all days of the week.
        let firstOfWeek = weekDate.startOfWeek(calendar: calendar)
        let dayColors = [Int: UIColor]()
        var dayTexts = [Int: String]()

        //
        let lastOfWeek = (firstOfWeek + 7.days) ?? firstOfWeek
        let weeksEvents = getEvents(fromDate: firstOfWeek, toDate: lastOfWeek) ?? []
        let weeksNotes = getNotes(fromDate: firstOfWeek, toDate: lastOfWeek) ?? []
        var dayEvents = [Int: [Event]]()
        var dayNotes = [Int: Note]()
        //

        for dayIndex in 0 ..< 7 {
            // Make sure the day's date is shown in the month's week cell.
            guard let dayDate = firstOfWeek + dayIndex.days else { fatalError() }
            let dayNumber = dayDate.day
            let shown = dayDate.isInSameMonth(date: weekDate, calendar: calendar)
            guard shown else { continue }

            // Save the day's number as text for the day label.
            dayTexts[dayIndex] = String(dayNumber)

            // Setup events for days
            dayEvents[dayIndex] = []
            if !weeksEvents.isEmpty {
                dayEvents[dayIndex] = weeksEvents.filter({
                    if let date = $0.date {
                        return Calendar.current.isDate(date, inSameDayAs: dayDate)
                    }
                    return false
                })
            }
            // Setup notes for days
            if !weeksNotes.isEmpty {
                dayNotes[dayIndex] = weeksNotes.filter({
                    if let date = $0.date {
                        return Calendar.current.isDate(date, inSameDayAs: dayDate)
                    }
                    return false
                }).first
            }
        }

        let cellModel = CalendarWeekCellModel(
            largeStyle: largeStyle,
            date: weekDate,
            texts: dayTexts,
            colors: dayColors,
            events: dayEvents,
            notes: dayNotes,
            delegate: delegate)
        return cellModel
    }

    func createCalendarMonthCellModel(month: String, year: String, largeStyle: Bool) -> CalendarMonthCellModel {
        return CalendarMonthCellModel(largeStyle: largeStyle, month: month, year: year)
    }

    func getEvents(fromDate: Date, toDate: Date) -> [Event]? {
        return self.dataManager.getEvents(fromDate: fromDate, toDate: toDate)
    }

    func getNotes(fromDate: Date, toDate: Date) -> [Note]? {
        return self.dataManager.getNotes(fromDate: fromDate, toDate: toDate)
    }

    func daySelected(date: Date, events: [Event]?, note: Note?) {
        let falseNote = dataManager.getFalseNote(forDate: date)
        self.router.enqueueRoute(with: CalendarRouter.RouteType.showEventDetails(events: events, note: note ?? falseNote))
    }

    func addButtonPressed() {
        self.router.enqueueRoute(with: CalendarRouter.RouteType.showEvents)
    }

    func dismiss() {
        router.dismiss(animated: false, context: nil, completion: nil)
    }

}
