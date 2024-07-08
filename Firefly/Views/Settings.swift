//
//  Settings.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/06/13.
//

import SwiftUI

struct Settings: View {
    @State private var startTime = Date.now
    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsedTime = startTime.distance(to: Date.now)

            NavigationStack {
                List {
                    Group {
                        Section {
                            NavigationLink(destination: TokenSettings()) {
                                HStack {
                                    Image(systemName: "gear")
                                    Text("Credentials")
                                    Spacer()

                                }
                                .contentShape(Rectangle())

                            }

                        }
                    }

                    VStack {
                        Text("All the umbrellas")
                            .multilineTextAlignment(.center)
                            .font(Font.system(.title))
                            .fontWeight(.ultraLight)
                            .foregroundColor(.white)
                    }
                    .frame(width: 350, height: 350)
                    .background(
                        RoundedRectangle(
                            cornerRadius: /*@START_MENU_TOKEN@*/ 25.0 /*@END_MENU_TOKEN@*/
                        )
                        .fill(.grainGradient(time: elapsedTime)))

                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)

            }
        }
    }
}

#Preview {
    Settings()
}
