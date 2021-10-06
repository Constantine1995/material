//
//  CalendarVC.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 24.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import UIKit
import Timepiece

enum CalendarTableData {
    /// The calendar month cell to show the month's title. First value is the month, the secodn the year.
    case month(CalendarMonth, Int)
    /// The calendar week cell representing a row of the month.
    case week(Date)
}

class CalendarVC: BaseViewController, MVVMViewController, BaseTableViewProtocol {

    private let tableView = BaseTableView()

    var calendar: () -> Calendar = {
        CommonDateFormatter.calendar
    }
    private var tableData = [[CalendarTableData]]()

    private var weekNamesView = WeekNamesView()
    var viewModel: CalendarVMProtocol!

    override func updateLargeStyle() {
        super.updateLargeStyle()
        tableView.reloadData()
        weekNamesView.largeStyle = largeStyle
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setData()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
        }, completion: { _ in
            self.setData()
        })
        super.viewWillTransition(to: size, with: coordinator)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        setupNavigationTitle(title: Localizations.Calendar.calendar_title)
        self.navigationView.rightButtonType = .add

        addTableView(tableView)
        tableView.register(CalendarMonthCell.self, forCellReuseIdentifier: CalendarMonthCell.cellIdentifier)
        tableView.register(CalendarWeekCell.self, forCellReuseIdentifier: CalendarWeekCell.cellIdentifier)

        view.addSubview(weekNamesView)
        weekNamesView.topAnchor.constraint(equalTo: navigationView.bottomAnchor).isActive = true
        weekNamesView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15).isActive = true
        weekNamesView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15).isActive = true

        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: weekNamesView.bottomAnchor, constant: 5).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    private func setData() {
        tableData = viewModel.createTableData(calendar: calendar(), tableData: tableData)
        tableView.reloadData()
        // Focus day
        let indexPathToFocus = indexPathForDate(Date())
        DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
            self?.tableView.scrollToRow(at: indexPathToFocus, at: .top, animated: false)
        }
    }

    //Returns the index path for a given date to show the month in the table view.
    private func indexPathForDate(_ date: Date) -> IndexPath {
        let calendar = self.calendar()
        let currentMonth = Date().startOfMonth()
        let seekedMonth = date.startOfMonth()
        let monthDiffs = currentMonth.months(to: seekedMonth, calendar: calendar)
        let clampedMonths = max(-Constant.month, min(Constant.month, monthDiffs))
        let section = Constant.month + clampedMonths
        return IndexPath(row: 0, section: section)
    }

    //Navigation
    override func leftButtonPressed() {
        viewModel.dismiss()
    }

    override func rightButtonPressed() {
        viewModel.addButtonPressed()
    }
}

extension CalendarVC: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = tableData[indexPath.section][indexPath.row]
        switch data {
        case let .month(month, year):
            return calendarMonthCell(month: month, year: year, indexPath: indexPath)
        case let .week(weekDate):
            return calendarWeekCell(weekDate: weekDate, indexPath: indexPath)
        }
    }

    private func calendarMonthCell(month: CalendarMonth, year: Int, indexPath: IndexPath) -> CalendarMonthCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CalendarMonthCell.cellIdentifier, for: indexPath) as? CalendarMonthCell  else {
            fatalError("No cell available")
        }
        let cellModel = viewModel.createCalendarMonthCellModel(month: month.titleString(), year: String(year), largeStyle: largeStyle)
        cell.config(model: cellModel)
        return cell
    }

    private func calendarWeekCell(weekDate: Date, indexPath: IndexPath) -> CalendarWeekCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CalendarWeekCell.cellIdentifier, for: indexPath) as? CalendarWeekCell  else {
            fatalError("No cell available")
        }
        let cellModel = viewModel.createCalendarWeekCellModel(calendar: self.calendar(), weekDate: weekDate, largeStyle: largeStyle, delegate: self)
        cell.config(model: cellModel)
        return cell
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

// MARK: - CalendarWeekCellDelegate
extension CalendarVC: CalendarWeekCellDelegate {
    func daySelected(onCalendarWeekCell calendarWeekCell: CalendarWeekCell, weekDate: Date, dayIndex: Int, events: [Event]?, note: Note?) {
        let calendar = self.calendar()
        let firstOfWeek = weekDate.startOfWeek(calendar: calendar)
        guard let selectedDate = firstOfWeek + dayIndex.days else { fatalError() }
        viewModel.daySelected(date: selectedDate, events: events, note: note)
    }
}
