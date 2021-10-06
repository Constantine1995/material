import UIKit

struct CalendarWeekCellModel {
    let largeStyle: Bool
    let date: Date
    let texts: [Int: String]
    let colors: [Int: UIColor]
    let events: [Int: [Event]]
    let notes: [Int: Note]
    weak var delegate: CalendarWeekCellDelegate?
}

protocol CalendarWeekCellDelegate: AnyObject {
    func daySelected(onCalendarWeekCell calendarWeekCell: CalendarWeekCell, weekDate: Date, dayIndex: Int, events: [Event]?, note: Note?)
}
