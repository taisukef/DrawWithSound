//
//  AudioGenerator.swift
//  test
//
//  Created by Taisuke Fukuno on 2020/12/31.
//  reference: https://qiita.com/kaede-san/items/e89b6e7e45302f7236f2
//

import Foundation
import AVFoundation
import AudioUnit

/// Audio Unitを使って、音を再生するクラス
class AudioGenerator {

    var audioUnit: AudioUnit?
    
    // static let sampleRate: Float = 384000.0 // 384kHz サンプリングレート cpu M1 25% buflen512(384kHz) buflen512(96kHz)
    // static let sampleRate: Float = 192000.0 // 192kHz サンプリングレート cpu M1 12%
    // static let sampleRate: Float = 96000.0 // 96kHz サンプリングレート cpu M1 4% buflen 128(384kHz), buflen 512(96kHz)
    static let sampleRate: Float = 48000.0 // サンプリングレート
    // static let sampleRate: Float = 44100.0 // サンプリングレート
    
    static var tone: Float = 440.0 // 440Hz = ラの音
    static var frame: Float = 0 // フレーム数
    static var volume: Float = 1.0

    /// 初期化
    init () {
        prepareAudioUnit()
    }
    // コールバック関数
    let renderCallback: AURenderCallback = {(
        inRefCon: UnsafeMutableRawPointer,
        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
        inTimeStamp: UnsafePointer<AudioTimeStamp>,
        inBusNumber: UInt32,
        inNumberFrames: UInt32,
        ioData: UnsafeMutablePointer<AudioBufferList>?
    ) -> OSStatus in
        // print(inNumberFrames);
        // チャンネルの数分のAudioBuffer参照の取り出し
        let abl = UnsafeMutableAudioBufferListPointer(ioData)
        // フレーム数分のメモリキャパシティ
        let capacity = Int(abl![0].mDataByteSize) / MemoryLayout<Float>.size
        // バッファに値を書き込む
        if let buffer: UnsafeMutablePointer<Float> = abl![0].mData?.bindMemory(to: Float.self, capacity: capacity) {
            for i: Int in 0 ..< Int(inNumberFrames) {
                // サイン波を生成
                buffer[i] = sin(frame * tone * Float(Double.pi) / sampleRate) * volume
                frame += 1
                if frame > sampleRate / 10.0 {
                    frame = 0
                    // 0:A 1:A+ 2:B 3:C 4:C+ 5:D 6:D+ 7:E 8:F 9:F+ 10:G 11:G+
                    let tones: [Int] = [0, 3, 7, 10]
                    let ntone = Int.random(in: 0 ... tones.count - 1)
                    tone = Float(440.0 * pow(2.0, Float(tones[ntone]) / 12.0))
                }
            }
        }

        return noErr
    }
    func prepareAudioUnit() {
        // RemoteIO AudioUnitのAudioComponentDescriptionを作成
        var acd = AudioComponentDescription()
        acd.componentType = kAudioUnitType_Output // カテゴリの指定
        // acd.componentSubType = kAudioUnitSubType_RemoteIO // 名前の指定（なぜかコンパイルできない）
        acd.componentManufacturer = kAudioUnitManufacturer_Apple // ベンダー名
        acd.componentFlags = 0 // 使用しない
        acd.componentFlagsMask = 0 // 使用しない

        // Audio Componentの定義を取得
        let audioComponent: AudioComponent = AudioComponentFindNext(nil, &acd)!

        // インスタンス化
        AudioComponentInstanceNew(audioComponent, &audioUnit)

        // 初期化
        AudioUnitInitialize(audioUnit!);
        
        // AURenderCallbackStruct構造体の作成
        var callbackStruct: AURenderCallbackStruct = AURenderCallbackStruct(
            inputProc: renderCallback, // コールバック関数の名前
            inputProcRefCon: nil // &audioUnit // コールバック関数内で参照するデータ
        )

        // コールバック関数の設定
        AudioUnitSetProperty(
            audioUnit!, // 対象のAudio Unit
            kAudioUnitProperty_SetRenderCallback, // 設定するプロパティ
            kAudioUnitScope_Input, // 入力スコープ
            0, // バスの値(出力なので0)
            &callbackStruct, // プロパティに設定する値
            UInt32(MemoryLayout.size(ofValue: callbackStruct)) // 値のデータサイズ
        )
        // AudioStreamBasicDescriptionの作成
        var asbd = AudioStreamBasicDescription()
        asbd.mSampleRate = Float64(AudioGenerator.sampleRate) // サンプリングレートの指定
        asbd.mFormatID = kAudioFormatLinearPCM // フォーマットID (リニアPCMを指定)
        asbd.mFormatFlags = kAudioFormatFlagIsFloat // フォーマットフラグの指定 (Float32形式)
        asbd.mChannelsPerFrame = 1 // チャンネル指定 (モノラル)
        asbd.mBytesPerPacket = UInt32(MemoryLayout<Float32>.size) // １パケットのバイト数
        asbd.mBytesPerFrame = UInt32(MemoryLayout<Float32>.size) // 1フレームのバイト数
        asbd.mFramesPerPacket = 1 // 1パケットのフレーム数
        asbd.mBitsPerChannel = UInt32(8 * MemoryLayout<UInt32>.size) // 1チャンネルのビット数
        asbd.mReserved = 0 // 使用しない

        // AudioUnitにASBDを設定
        AudioUnitSetProperty(
            audioUnit!, // 対象のAudio Unit
            kAudioUnitProperty_StreamFormat, // 設定するプロパティ
            kAudioUnitScope_Input, // 入力スコープ
            0, // 出力バス
            &asbd, // プロパティに設定する値
            UInt32(MemoryLayout.size(ofValue: asbd)) // 値のデータサイズ
        )
    }
    func start() {
        AudioGenerator.frame = 0
        AudioOutputUnitStart(audioUnit!) // Remote IO Unit 出力開始
        print("start")
    }
    func stop() {
        AudioOutputUnitStop(audioUnit!) // Remote IO Unit 出力停止
        print("stop")
    }
    func setVolume(vol: Float) {
        AudioGenerator.volume = vol
    }
    func dispose() {
        AudioUnitUninitialize(audioUnit!)
        AudioComponentInstanceDispose(audioUnit!)
    }
}
