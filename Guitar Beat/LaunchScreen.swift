//
//  LaunchScreen.swift
//  Guitar Beat
//
//  Created by Wenjing Wang on 1/1/26.
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Background color (optional, you can customize this)
            Color.black
                .ignoresSafeArea()
            
            // Your launch image
            Image("LaunchImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }
}

#Preview {
    LaunchScreenView()
}
