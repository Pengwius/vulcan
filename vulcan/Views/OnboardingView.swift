//
//  OnboardingView.swift
//  vulcan
//
//  Created by royal on 04/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct TitleView: View {
	var body: some View {
		VStack {
			Image("vulcan")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(width: 130, alignment: .center)
				.accessibility(hidden: true)
				.padding(5)
			
			Text("Welcome to")
				.customTitleText()
			
			Text("vulcan")
				.customTitleText()
				.foregroundColor(.mainColor)
		}
	}
}

struct InformationDetailView: View {
	var title: LocalizedStringKey = ""
	var subtitle: LocalizedStringKey = ""
	var imageName: String = ""
	
	var body: some View {
		HStack(alignment: .center) {
			Image(systemName: imageName)
				.font(.largeTitle)
				.foregroundColor(.mainColor)
				.padding()
				.accessibility(hidden: true)
			
			VStack(alignment: .leading) {
				Text(title)
					.font(.headline)
					.foregroundColor(.primary)
					.accessibility(addTraits: .isHeader)
				
				Text(subtitle)
					.font(.body)
					.foregroundColor(.secondary)
					.fixedSize(horizontal: false, vertical: true)
			}
		}
		.padding(.top)
	}
}

struct InformationContainerView: View {
	var body: some View {
		VStack(alignment: .leading) {
			InformationDetailView(title: "ONBOARDING_FUNCTION1_TITLE", subtitle: "ONBOARDING_FUNCTION1_DESCRIPTION", imageName: "command")
			InformationDetailView(title: "ONBOARDING_FUNCTION2_TITLE", subtitle: "ONBOARDING_FUNCTION2_DESCRIPTION", imageName: "bell.fill")
			InformationDetailView(title: "ONBOARDING_FUNCTION3_TITLE", subtitle: "ONBOARDING_FUNCTION3_DESCRIPTION", imageName: "heart.fill")
		}
		.padding(.horizontal)
	}
}

/// Onboarding, displayed on first launch, hosting SetupView
struct OnboardingView: View {
	@EnvironmentObject var VulcanAPI: VulcanAPIModel
	@Binding var isPresented: Bool
	@State var showSetup: Bool = false
	
	var body: some View {
		VStack(alignment: .center) {
			if (!showSetup) {
				VStack {
					Spacer()
					TitleView()
					Spacer()
					InformationContainerView()
					Spacer()
					Button(action: {
						generateHaptic(.light)
						withAnimation {
							self.showSetup = true
						}
					}) {
						Text("Continue")
							.customButton(Color.mainColor)
					}
				}
				.padding()
				.transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
			} else {
				SetupView(isPresented: $showSetup, isParentPresented: $isPresented, hasParent: true)
					.environmentObject(self.VulcanAPI)
					.transition(.move(edge: .trailing))
			}
		}
		.onAppear {
			UserDefaults.standard.set(true, forKey: "launchedBefore")
		}
	}
}

struct OnboardingView_Previews: PreviewProvider {
	static var previews: some View {
		OnboardingView(isPresented: .constant(true))
			.environmentObject(VulcanAPIModel())
	}
}
