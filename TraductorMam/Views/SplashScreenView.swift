//
//  SwiftUIView.swift
//  TraductorMam
//
//  Created by Freddy Morales on 12/05/26.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var opacity: Double = 1.0
    @StateObject var vm = TraductorViewModel()

    var body: some View {
        ZStack {
            if isActive {
                ContentView()
                    .transition(.opacity)
            } else {
                VStack {
                    Image("logoInicio")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                    Text("Utz iwon")
                        .font(.title)
                        .foregroundColor(.black)
                }
                .opacity(opacity)
                .onAppear {
                    
                    withAnimation(.easeOut(duration: 2.4)) {
                        opacity = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            isActive = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
