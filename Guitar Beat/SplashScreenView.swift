//
//  SplashScreenView.swift
//  Guitar Beat
//
//  Created by Wenjing Wang on 1/1/26.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var opacity = 1.0
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                // Background color
                Color.black
                    .ignoresSafeArea()
                
                // Your launch image
                Image("LaunchImage")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(opacity)
            }
            .onAppear {
                // Show splash screen for 2 seconds, then fade out
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        opacity = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
