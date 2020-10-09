//
//  Provider.swift
//  Widget
//
//  Created by royal on 03/09/2020.
//

import WidgetKit
import SwiftUI
import Intents
import Vulcan
import CoreData

struct Provider: TimelineProvider {
	typealias Entry = ScheduleEntry

	var schedule: [Vulcan.ScheduleEvent] {
		let context = CoreDataModel.shared.persistentContainer.viewContext
		let fetchRequest: NSFetchRequest<StoredScheduleEvent> = StoredScheduleEvent.fetchRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(StoredScheduleEvent.dateStartsEpoch), ascending: true)]
		
		if let storedSchedule = try? context.fetch(fetchRequest) {
			return storedSchedule
				.compactMap { entity -> Vulcan.ScheduleEvent? in
					guard var event = Vulcan.ScheduleEvent(from: entity) else {
						return nil
					}
					
					let employeeFetchRequest: NSFetchRequest = DictionaryEmployee.fetchRequest()
					employeeFetchRequest.predicate = NSPredicate(format: "id == %d", event.employeeID)
					if let employee: DictionaryEmployee = (try? context.fetch(employeeFetchRequest))?.first {
						event.employee = employee
					}
					
					let timeFetchRequest: NSFetchRequest = DictionaryLessonTime.fetchRequest()
					timeFetchRequest.predicate = NSPredicate(format: "id == %d", event.lessonTimeID)
					guard let time: DictionaryLessonTime = (try? context.fetch(timeFetchRequest))?.first else {
						return nil
					}
					event.dateStartsEpoch = TimeInterval(event.dateEpoch + Int(time.start) + 3600)
					event.dateEndsEpoch = TimeInterval(event.dateEpoch + Int(time.end) + 3600)
					
					return event
				}
				.sorted { $0.dateStarts ?? $0.date < $1.dateStarts ?? $0.date }
				.filter { $0.userSchedule }
		} else {
			return []
		}
	}

	func placeholder(in context: Context) -> ScheduleEntry {
		ScheduleEntry(date: Date(), event: nil)
	}
	
	func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
		var event: Vulcan.ScheduleEvent = Vulcan.ScheduleEvent(dateEpoch: Int(Date().startOfDay.timeIntervalSince1970), lessonOfTheDay: 1, lessonTimeID: 0, subjectID: 0, subjectName: NSLocalizedString("Spanish", comment: ""), divisionShort: nil, room: "03", employeeID: 1, helpingEmployeeID: nil, oldEmployeeID: nil, oldHelpingEmployeeID: nil, scheduleID: 1, note: nil, labelStrikethrough: false, labelBold: false, userSchedule: false, employeeFullName: "Ben Chang")
		event.dateStarts = Date()
		event.dateEnds = Calendar.autoupdatingCurrent.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
		
		let entry = ScheduleEntry(date: Date(), event: event)
		completion(entry)
	}
	
	func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
		var entries: [ScheduleEntry] = self.schedule
			.filter { $0.dateEnds ?? $0.date >= Date().startOfDay }
			.timeline()
			.map { date, event in
				ScheduleEntry(date: date, event: event)
			}
			.sorted { $0.date < $1.date }
		
		entries.append(ScheduleEntry(date: entries.last?.event?.dateEnds ?? Date(), event: nil))
		
		completion(Timeline(entries: entries, policy: .atEnd))
	}
	
	static var noEventSubtitle: String {
		let strings: [String] = [
			"Watermelon is 92% water.",
			"The opening scene in \"Friends\" wasn't shot in New York.",
			"You look good today."
		]
		
		return NSLocalizedString(strings[Int.random(in: 0...(strings.count - 1))], comment: "")
	}
}
