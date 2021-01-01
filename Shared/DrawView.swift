//
//  OverlayView.swift
//  EditorApp
//
//  Created by satoutakeshi on 2019/11/29.
//  Copyright © 2019 satoutakeshi. All rights reserved.
//  reference: https://blog.personal-factory.com/2019/11/30/draw-application-by-swiftui/
//  Modified by @taisukef 2020.12.31

import SwiftUI

struct DrawPoints: Identifiable {
    var points: [CGPoint]
    var color: Color
    var id = UUID()
}

class UserData: ObservableObject {
    @Published var tmpDrawPoints: DrawPoints = DrawPoints(points: [], color: .red)
    @Published var endedDrawPoints: [DrawPoints] = []
}

struct DrawView: View {
    @ObservedObject var data: UserData = UserData()
    @State var selectedColor: Color = Color.red
    @State var startPoint: CGPoint = CGPoint.zero
    var audioGenerator = AudioGenerator()

    init() {
        audioGenerator.setVolume(vol: 0.0)
        audioGenerator.start()
    }
    func dispose() {
        audioGenerator.stop()
        audioGenerator.dispose()
    }
    var body: some View {
        VStack {
            Rectangle()
                .foregroundColor(Color.white)
                .frame(width: 300, height: 300, alignment: .center)
                .overlay(
                    ZStack {
                        ForEach(data.endedDrawPoints) { data in
                            Path { path in
                                path.addLines(data.points)
                            }
                                .stroke(data.color, lineWidth: 10)
                        }
                        Path { path in
                            path.addLines(data.tmpDrawPoints.points)
                        }
                            .stroke(data.tmpDrawPoints.color, lineWidth: 10)
                    }
                )
                .gesture(
                    DragGesture()
                        .onChanged({ value in
                            if self.startPoint != value.startLocation {
                                if data.tmpDrawPoints.points.count == 0 {
                                    audioGenerator.setVolume(vol: 1.0)
                                }
                                data.tmpDrawPoints.points.append(value.location)
                                data.tmpDrawPoints.color = self.selectedColor
                            }
                        })
                        .onEnded({ value in
                            self.startPoint = value.startLocation
                            data.endedDrawPoints.append(data.tmpDrawPoints)
                            data.tmpDrawPoints = DrawPoints(points: [], color: self.selectedColor)
                            audioGenerator.setVolume(vol: 0.0)
                        })
                )
            VStack(spacing: 10) {
                Button(action: { self.selectedColor = Color.black }) { Text("黒") }
                Button(action: { self.selectedColor = Color.red }) { Text("赤") }
                Button(action: { self.selectedColor = Color.white }) { Text("消しゴム") }
                Button(action: {
                    if data.endedDrawPoints.count > 0 {
                        data.endedDrawPoints.removeLast()
                    }
                }) { Text("やり直し") }
                Spacer()
            }
                .frame(minWidth: 0.0, maxWidth: CGFloat.infinity)
                .background(Color.gray)
        }
    }
}
