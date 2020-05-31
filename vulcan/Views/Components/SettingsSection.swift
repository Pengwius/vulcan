//
//  SettingsSection.swift
//  Harbour
//
//  Created by royal on 05/04/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

/// Section used in SettingsView, containing particular cells
struct SettingsSection<Content>: View where Content: View {
	let content: Content
	let header: LocalizedStringKey
	let isLast: Bool
	
	var headerText: some View {
		Text(header)
			.font(.system(size: 22, weight: .bold))
			.opacity(1)
			.foregroundColor(Color.primary)
	}
	
	var normalSection: some View {
		Section(header: headerText) {
			Group {
				content
			}
			.padding(.vertical, 10)
		}
	}
	
	var lastSection: some View {
		Section(
			header: headerText,
			footer: VStack {
				Group {
					Text("Made with ❤️ (and ☕️) by @rrroyal")
						.bold()
					Text("Version \(Bundle.main.buildVersion) (Build \(Bundle.main.buildNumber))")
						.bold()
				}
				.font(.callout)
				.opacity(0.2)
				.multilineTextAlignment(.center)
				.foregroundColor(.primary)
				.fixedSize()
				.animation(.none)
			}
			.padding()
			.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: Alignment.center)
			.edgesIgnoringSafeArea(.bottom)
			.onTapGesture {
				guard let url = URL(string: "https://github.com/rrroyal") else { return }
				generateHaptic(.light)
				UIApplication.shared.open(url)
			}
		) {
			Group {
				content
			}
			.padding(.vertical, 10)
		}
	}

	init(header: LocalizedStringKey, isLast: Bool? = false, @ViewBuilder content: @escaping () -> Content) {
        self.content = content()
		self.header = header
		self.isLast = isLast ?? false
    }
	
	@ViewBuilder
	var body: some View {
		if isLast {
			lastSection
		} else {
			normalSection
		}
	}
}

/* struct SettingsSection_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSection()
    }
} */
