//
// HomeView.swift
// vulcan
//
// Created by royal on 24/06/2020.
//

import SwiftUI
import Vulcan
import AppNotifications

/// Home view, containing dashboard for user
struct HomeView: View {
	@EnvironmentObject private var vulcan: Vulcan
	
	@AppStorage(UserDefaults.AppKeys.userGroup.rawValue, store: .group) public var userGroup: Int = 0
	@AppStorage(UserDefaults.AppKeys.colorScheme.rawValue, store: .group) private var colorScheme: String = "Default"
	@AppStorage(UserDefaults.AppKeys.colorizeGrades.rawValue, store: .group) private var colorizeGrades: Bool = true
	
	@State private var isComposeSheetPresented: Bool = false
	@State private var messageToReply: Vulcan.Message?
	
	/// Data
	var helloString: LocalizedStringKey {
		let hour: Int = Calendar.autoupdatingCurrent.component(.hour, from: Date())
		var helloString: LocalizedStringKey = "HELLO : \(vulcan.currentUser?.name ?? "User")"
		
		if (hour >= 4 && hour < 13) {
			helloString = "GOOD_MORNING : \(vulcan.currentUser?.name ?? "User")"
		} else if (hour >= 13 && hour < 18) {
			helloString = "GOOD_AFTERNOON : \(vulcan.currentUser?.name ?? "User")"
		} else if ((hour >= 18 && hour < 24) || (hour >= 0 && hour < 4)) {
			helloString = "GOOD_EVENING : \(vulcan.currentUser?.name ?? "User")"
		}
		
		return helloString
	}
	
	var currentLesson: Vulcan.ScheduleEvent? {
		vulcan.schedule
			.flatMap(\.events)
			.filter { $0.group ?? userGroup == userGroup }
			.first(where: { $0.isCurrent ?? false })
	}
	
	var nextLesson: Vulcan.ScheduleEvent? {
		vulcan.schedule
			.flatMap(\.events)
			.filter { $0.group ?? userGroup == userGroup }
			.first(where: {
				guard let dateStarts = $0.dateStarts else {
					return false
				}
				
				return dateStarts > Date()
			})
	}
	
	var newExams: [Vulcan.Exam] {
		vulcan.tasks.exams
			.filter { $0.date >= Date().startOfWeek ?? Date().startOfMonth && $0.date <= Date().endOfWeek ?? Date().endOfMonth }
	}
	
	var newHomework: [Vulcan.Homework] {
		vulcan.tasks.homework
			.filter { $0.date >= Date().startOfWeek ?? Date().startOfMonth && $0.date <= Date().endOfWeek ?? Date().endOfMonth }
	}
	
	var newMessages: [Vulcan.Message] {
		vulcan.messages[.received]?.filter({ !$0.hasBeenRead }) ?? []
	}
	
	/// Divider view
	private var divider: some View {
		VStack {
			RoundedRectangle(cornerRadius: 2, style: .circular).fill(Color.primary).opacity(0.03)
				.frame(minWidth: .zero, maxWidth: .infinity, minHeight: 2, maxHeight: 2)
		}
	}
	
	/// Section containing anticipated grades.
	private var anticipatedGradesSection: some View {
		Section(header: Text("Anticipated grades").textCase(.none)) {
			if (vulcan.eotGrades.expected.count == 0) {
				Text("No grades")
					.opacity(0.5)
					.multilineTextAlignment(.center)
					.fullWidth()
			} else {
				ForEach(vulcan.eotGrades.expected, id: \.subjectID) { (grade) in
					FinalGradeCell(scheme: colorScheme, colorize: colorizeGrades, grade: grade)
						.id("anticipatedGrade:\(grade.subjectID)")
				}
			}
		}
		.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
		.loadingOverlay(vulcan.dataState.eotGrades.loading)
		.contentShape(Rectangle())
		.onTapGesture(count: 2) {
			generateHaptic(.light)
			vulcan.getEndOfTermGrades() { error in
				if let error = error {
					generateHaptic(.error)
					AppNotifications.shared.sendNotification(NotificationData(error: error.localizedDescription))
				}
			}
		}
	}
	
	/// Section containing final grades.
	private var finalGradesSection: some View {
		Section(header: Text("Final grades").textCase(.none)) {
			if (vulcan.eotGrades.final.count == 0) {
				Text("No grades")
					.opacity(0.5)
					.multilineTextAlignment(.center)
					.fullWidth()
			} else {
				ForEach(vulcan.eotGrades.final, id: \.subjectID) { (grade) in
					FinalGradeCell(scheme: colorScheme, colorize: colorizeGrades, grade: grade)
						.id("finalGrade:\(grade.subjectID)")
				}
			}
		}
		.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
		.loadingOverlay(vulcan.dataState.eotGrades.loading)
		.contentShape(Rectangle())
		.onTapGesture(count: 2) {
			generateHaptic(.light)
			vulcan.getEndOfTermGrades() { error in
				if let error = error {
					generateHaptic(.error)
					AppNotifications.shared.sendNotification(NotificationData(error: error.localizedDescription))
				}
			}
		}
	}
	
	/// Section containing user notes.
	private var notesSection: some View {
		Section(header: Text("Notes").textCase(.none)) {
			if (vulcan.notes.count == 0) {
				Text("Nothing found")
					.opacity(0.5)
					.multilineTextAlignment(.center)
					.fullWidth()
			} else {
				ForEach(vulcan.notes) { (note) in
					NoteCell(note: note)
				}
			}
		}
		.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
		.loadingOverlay(vulcan.dataState.notes.loading)
		.contentShape(Rectangle())
		.onTapGesture(count: 2) {
			generateHaptic(.light)
			vulcan.getNotes() { error in
				if let error = error {
					generateHaptic(.error)
					AppNotifications.shared.sendNotification(NotificationData(error: error.localizedDescription))
				}
			}
		}
	}
	
	/// View displayed when user is logged in.
	private var loggedInView: some View {
		List {
			// General
			Section {
				VStack(alignment: .leading) {
					// Welcome message
					VStack(alignment: .leading, spacing: 4) {
						Text(helloString)
							.font(.title2)
							.bold()
							.allowsTightening(true)
							.minimumScaleFactor(0.9)
						
						Text("DATE_CURRENTLY : \(Date().formattedDateString(timeStyle: .none, dateStyle: .full))")
							.font(.headline)
							.foregroundColor(.secondary)
							.allowsTightening(true)
							.minimumScaleFactor(0.9)
					}
					
					// Lessons
					Group {
						// Current lesson
						if let lesson = currentLesson {
							divider
							
							VStack(alignment: .leading, spacing: 0) {
								Text("Current lesson")
									.font(.headline)
									.foregroundColor(.secondary)
									.padding(.bottom, 2)
								Text("\(lesson.subjectName) (\(lesson.room))")
									.font(.headline)
									.lineLimit(2)
									.padding(.bottom, 2)
								Text("\((lesson.dateStarts ?? lesson.date).localizedTime) - \((lesson.dateEnds ?? lesson.date).localizedTime) • \(lesson.employee?.name ?? "Unknown employee") \(lesson.employee?.surname ?? "")")
									.font(.callout)
									.foregroundColor(.secondary)
									.lineLimit(2)
							}
						}
						
						// Next lesson
						if let lesson = nextLesson {
							divider
							
							VStack(alignment: .leading, spacing: 0) {
								Text("Next lesson")
									.font(.headline)
									.foregroundColor(.secondary)
									.padding(.bottom, 2)
								
								Text("\(lesson.subjectName) (\(lesson.room))")
									.font(.headline)
									.lineLimit(2)
									.padding(.bottom, 2)
								
								Group {
									if (Calendar.autoupdatingCurrent.isDateInToday(lesson.date)) {
										Text("\((lesson.dateStarts ?? lesson.date).localizedTime) - \((lesson.dateEnds ?? lesson.date).localizedTime) • \(lesson.employee?.name ?? "Unknown employee") \(lesson.employee?.surname ?? "")")
									} else {
										Text("\((lesson.dateStarts ?? lesson.date).formattedString(format: "EEEE").capitalingFirstLetter()), \((lesson.dateStarts ?? lesson.date).localizedTime) - \((lesson.dateEnds ?? lesson.date).localizedTime) • \(lesson.employee?.name ?? "Unknown employee") \(lesson.employee?.surname ?? "")")
									}
								}
								.font(.callout)
								.foregroundColor(.secondary)
								.lineLimit(2)
							}
						}
						
						// No lessons
						if (currentLesson == nil && nextLesson == nil) {
							divider
							Text("No lessons for now ☺️")
								.font(.headline)
								.opacity(0.35)
								.padding(.vertical, 5)
						}
					}
				}
				.padding(.vertical, 5)
			}
			
			// MARK: Tasks - Exams
			if (newExams.count > 0) {
				Section(header: Text("Exams").textCase(.none)) {
					ForEach(newExams) { (task) in
						TaskCell(task: task)
					}
				}
			}
			
			// MARK: Tasks - Homework
			if (newHomework.count > 0) {
				Section(header: Text("Homework").textCase(.none)) {
					ForEach(newHomework) { (task) in
						TaskCell(task: task)
					}
				}
			}
			
			// MARK: Messages
			if (newMessages.count > 0) {
				Section(header: Text("New messages").textCase(.none)) {
					ForEach(newMessages) { message in
						NavigationLink(destination: MessageDetailView(message: message)) {
							MessageCell(message: message, isComposeSheetPresented: $isComposeSheetPresented, messageToReply: $messageToReply)
						}
					}
				}
			}
			
			// MARK: Anticipated grades
			anticipatedGradesSection
			
			// MARK: Final grades
			finalGradesSection
			
			// MARK: Notes
			notesSection
		}
		.listStyle(InsetGroupedListStyle())
		.sheet(isPresented: $isComposeSheetPresented, content: { ComposeMessageView(isPresented: $isComposeSheetPresented, message: $messageToReply).environmentObject(vulcan) })
		.onAppear {
			if vulcan.currentUser == nil {
				return
			}
			
			// Notes
			if (vulcan.dataState.notes.lastFetched ?? Date(timeIntervalSince1970: 0)) > (Calendar.autoupdatingCurrent.date(byAdding: .minute, value: 5, to: Date()) ?? Date()) {
				vulcan.getNotes() { error in
					if let error = error {
						generateHaptic(.error)
						AppNotifications.shared.sendNotification(NotificationData(error: error.localizedDescription))
					}
				}
			}
			
			// EOT Grades
			if (vulcan.dataState.eotGrades.lastFetched ?? Date(timeIntervalSince1970: 0)) > (Calendar.autoupdatingCurrent.date(byAdding: .minute, value: 5, to: Date()) ?? Date()) {
				vulcan.getEndOfTermGrades() { error in
					if let error = error {
						generateHaptic(.error)
						AppNotifications.shared.sendNotification(NotificationData(error: error.localizedDescription))
					}
				}
			}
		}
		/* .onReceive(vulcan.userLoggedIn) { (loggedIn) in
			if (!loggedIn) {
				return
			}
			
			vulcan.getNotes() { (success, error) in
				if (!success) {
					generateHaptic(.error)
				}
			}
			
			vulcan.getEOTGrades() { (success, error) in
				if (!success) {
					generateHaptic(.error)
				}
			}
		} */
	}
	
	var body: some View {
		Group {
			if (vulcan.currentUser != nil) {
				loggedInView
			} else {
				Text("Not logged in")
					.foregroundColor(.secondary)
			}
		}
		.navigationTitle(Text("Home"))
		// .navigationViewStyle(StackNavigationViewStyle())
	}
}

struct HomeView_Previews: PreviewProvider {
  static var previews: some View {
    HomeView()
  }
}