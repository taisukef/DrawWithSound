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

struct DrawPathView: View {
    var drawPointsArray: [DrawPoints] = []
    init(drawPointsArray: [DrawPoints]) {
        self.drawPointsArray = drawPointsArray
    }
    var body: some View {
        ZStack {
            ForEach(drawPointsArray) { data in
                Path { path in
                    path.addLines(data.points)
                }
                    .stroke(data.color, lineWidth: 10)
            }
        }
    }
}

struct DrawView: View {
    var audioGenerator = AudioGenerator()
    @State var tmpDrawPoints: DrawPoints = DrawPoints(points: [], color: .red)
    @State var endedDrawPoints: [DrawPoints] = []
    @State var startPoint: CGPoint = CGPoint.zero
    @State var selectedColor: Color = Color.red
    
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
                .frame(width: 400, height: 300, alignment: .center)
                .overlay(
                    DrawPathView(drawPointsArray: endedDrawPoints)
                        .overlay(
                            Path { path in
                                path.addLines(self.tmpDrawPoints.points)
                            }
                                .stroke(self.tmpDrawPoints.color, lineWidth: 10)
                        )
                )
                .gesture(
                    DragGesture()
                        .onChanged({ value in
                            if self.startPoint != value.startLocation {
                                if self.tmpDrawPoints.points.count == 0 {
                                    audioGenerator.setVolume(vol: 1.0)
                                }
                                self.tmpDrawPoints.points.append(value.location)
                                self.tmpDrawPoints.color = self.selectedColor
                            }
                        })
                        .onEnded({ value in
                            self.startPoint = value.startLocation
                            self.endedDrawPoints.append(self.tmpDrawPoints)
                            self.tmpDrawPoints = DrawPoints(points: [], color: self.selectedColor)
                            audioGenerator.setVolume(vol: 0.0)
                        })
                )
            VStack(spacing: 10) {
                Button(action: { self.selectedColor = Color.black }) { Text("黒") }
                Button(action: { self.selectedColor = Color.red }) { Text("赤") }
                Button(action: { self.selectedColor = Color.white }) { Text("消しゴム") }
                Button(action: {
                    if self.endedDrawPoints.count > 0 {
                        self.endedDrawPoints.removeLast()
                    }
                }) { Text("やり直し") }
                Spacer()
            }
                .frame(minWidth: 0.0, maxWidth: CGFloat.infinity)
                .background(Color.gray)
        }
    }
}
