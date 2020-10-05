//
//  TasksView.swift
//  vulcan
//
//  Created by royal on 24/06/2020.
//

import SwiftUI
import Vulcan
import AppNotifications

/// View containing current user tasks.
struct TasksView: View {
	@EnvironmentObject var vulcan: Vulcan
	@EnvironmentObject var settings: SettingsModel
	#if os(iOS)
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	#endif
	
	@State private var date: Date = Date()
	
	/// Loads the data for the current month.
	private func fetch(timeIntervalSince1970: Double? = nil) {
		if (vulcan.dataState.tasks.loading) {
			return
		}
		
		let previousDate: Date = self.date
		let startDate: Date = date.startOfMonth
		let endDate: Date = date.endOfMonth
		
		vulcan.getTasks(isPersistent: self.date.startOfMonth <= Date() && self.date.endOfMonth >= Date(), from: startDate, to: endDate) { error in
			if let error = error {
				generateHaptic(.error)
				self.date = previousDate
				AppNotifications.shared.sendNotification(NotificationData(error: error.localizedDescription))
			}
		}
	}
	
	private var exams: [Vulcan.Exam] {
		vulcan.tasks.exams
			.filter { $0.date >= Date().startOfMonth && $0.date <= Date().endOfMonth }
	}
	
	private var homework: [Vulcan.Homework] {
		vulcan.tasks.homework
			.filter { $0.date >= Date().startOfMonth && $0.date <= Date().endOfMonth }
	}
	
	/// Date picker
	private var datePicker: some View {
		DatePicker("Date", selection: $date, displayedComponents: .date)
			.datePickerStyle(CompactDatePickerStyle())
			.labelsHidden()
			.onChange(of: date.timeIntervalSince1970, perform: fetch)
	}
	
    var body: some View {
		List {
			// Exams
			Section(header: Text("Exams").textCase(.none)) {
				if (exams.count > 0) {
					ForEach(exams) { task in
						TaskCell(task: task, type: task.type)
					}
				} else {
					Text("No exams for this month 😊")
						.opacity(0.5)
						.multilineTextAlignment(.center)
						.fullWidth()
				}
			}
			
			// Homework
			Section(header: Text("Homework").textCase(.none)) {
				if (homework.count > 0) {
					ForEach(homework) { task in
						TaskCell(task: task, type: nil)
					}
				} else {
					Text("No homework for this month 😊")
						.opacity(0.5)
						.multilineTextAlignment(.center)
						.fullWidth()
				}
			}
		}
		.listStyle(InsetGroupedListStyle())
		.navigationTitle(Text("Tasks"))
		/* .navigationBarItems(
			leading: datePicker,
			trailing: RefreshButton(loading: (vulcan.dataState.tasksExams.loading || vulcan.dataState.tasksHomework.loading), iconName: "arrow.clockwise", edge: .trailing) {
				generateHaptic(.light)
				loadTasks()
			}
		) */
		.toolbar {
			// Date picker
			ToolbarItem(placement: .cancellationAction) {
				datePicker
			}
			
			// Refresh button
			ToolbarItem(placement: .primaryAction) {
				RefreshButton(loading: vulcan.dataState.tasks.loading, iconName: "arrow.clockwise", edge: .trailing) {
					generateHaptic(.light)
					fetch()
				}
			}
		}
		.onAppear {
			if AppState.networking.monitor.currentPath.isExpensive || vulcan.currentUser == nil {
				return
			}
			
			let nextFetch: Date = Calendar.autoupdatingCurrent.date(byAdding: .minute, value: 5, to: vulcan.dataState.tasks.lastFetched ?? Date(timeIntervalSince1970: 0)) ?? Date()
			if nextFetch <= Date() {
				fetch()
			}
		}
    }
}

struct TasksView_Previews: PreviewProvider {
    static var previews: some View {
        TasksView()
    }
}
