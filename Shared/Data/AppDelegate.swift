//
//  AppDelegate.swift
//  vulcan
//
//  Created by royal on 25/06/2020.
//

#if canImport(UIKit)
import UIKit
#endif

import Combine
import BackgroundTasks
import os
import Vulcan
import WidgetKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
	// MARK: - App Lifecycle
	private let logger: Logger = Logger(subsystem: "Vulcan", category: "AppDelegate")
	
	private var cancellableSet: [AnyCancellable] = []
	
	/// Called when app is launched
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {		
		// Background fetch
		BGTaskScheduler.shared.register(forTaskWithIdentifier: "dev.niepostek.vulcan.refreshData", using: nil) { (task) in
			self.handleAppRefresh(task)
		}
		
		// WatchConnectivity session
		WatchSessionManager.shared.startSession()
		
		// Networking
		AppState.networking.monitor.start(queue: .global())
		
		// UserNotifications
		let notifications: Notifications = Notifications.shared
		notifications.notificationCenter.delegate = notifications
		
		// Listeners
		Vulcan.shared.$currentUser
			.sink { user in
				let watchData: [String: Any] = [
					"type": "Vulcan",
					"data": [
						"currentUser": try? JSONEncoder().encode(user)
					]
				]
				
				try? WatchSessionManager.shared.sendData(watchData)
			}
			.store(in: &cancellableSet)
		
		Vulcan.shared.scheduleDidChange
			.sink { isPersistent in
				if !isPersistent {
					return
				}
				
				// Widget
				WidgetCenter.shared.reloadTimelines(ofKind: "ScheduleWidget")
				
				// Watch
				let watchData: [String: Any] = [
					"type": "Vulcan",
					"data": [
						"schedule": try? JSONEncoder().encode(Vulcan.shared.schedule)
					]
				]
				
				try? WatchSessionManager.shared.sendData(watchData)
			}
			.store(in: &cancellableSet)
		
		return true
	}
	
	// MARK: - Helper functions
	
	/// Sets the currently visible shortcuts
	/// - Parameter visible: Should shortcuts be visible?
	public func setShortcuts(visible: Bool) {
		if visible {
			let shortcutGradesItem = UIApplicationShortcutItem(type: "shortcutGrades", localizedTitle: NSLocalizedString("Grades", comment: ""), localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "rosette"), userInfo: nil)
			let shortcutScheduleItem = UIApplicationShortcutItem(type: "shortcutSchedule", localizedTitle: NSLocalizedString("Schedule", comment: ""), localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "calendar"), userInfo: nil)
			let shortcutTasksItem = UIApplicationShortcutItem(type: "shortcutTasks", localizedTitle: NSLocalizedString("Tasks", comment: ""), localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "doc.on.clipboard.fill"), userInfo: nil)
			let shortcutMessagesItem = UIApplicationShortcutItem(type: "shortcutMessages", localizedTitle: NSLocalizedString("Messages", comment: ""), localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "text.bubble.fill"), userInfo: nil)
			UIApplication.shared.shortcutItems = [shortcutGradesItem, shortcutScheduleItem, shortcutTasksItem, shortcutMessagesItem]
		} else {
			UIApplication.shared.shortcutItems = []
		}
	}
	
	// MARK: - Background refresh
	/// Schedules a background refresh task
	public func scheduleBackgroundRefresh() {
		logger.debug("Scheduling app refresh.")
		do {
			let request = BGAppRefreshTaskRequest(identifier: "dev.niepostek.vulcan.refreshData")
			request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
			try BGTaskScheduler.shared.submit(request)
		} catch {
			logger.warning("Error scheduling: \(error.localizedDescription)")
		}
	}
	
	/// Executed when app is launched by background refresh.
	/// - Parameter task: Task to execute
	func handleAppRefresh(_ task: BGTask) {
		if (!UserDefaults.group.bool(forKey: UserDefaults.AppKeys.isLoggedIn.rawValue)) {
			task.setTaskCompleted(success: true)
			return
		}
		
		logger.notice("Refreshing in the background...")
		
		let queue = OperationQueue()
		queue.maxConcurrentOperationCount = 6
		queue.addOperation { Vulcan.shared.getGrades() }
		
		if let startOfWeek: Date = Date().startOfWeek,
		   let endOfWeek: Date = Date().endOfWeek {
			queue.addOperation { Vulcan.shared.getSchedule(isPersistent: true, from: startOfWeek, to: endOfWeek) }
		}
		
		queue.addOperation { Vulcan.shared.getTasks(isPersistent: true, from: Date().startOfMonth, to: Date().startOfMonth) }
		queue.addOperation { Vulcan.shared.getMessages(tag: .received, isPersistent: true, from: Date().startOfMonth, to: Date().endOfMonth) }
		queue.addOperation { Vulcan.shared.getEndOfTermGrades() }
		
		task.expirationHandler = {
			self.logger.warning("Refresh expired!")
			queue.cancelAllOperations()
		}
		
		let lastOperation = queue.operations.last
		lastOperation?.completionBlock = {
			task.setTaskCompleted(success: !(lastOperation?.isCancelled ?? false))
		}
		
		self.scheduleBackgroundRefresh()
	}
}