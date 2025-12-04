//
//  UIPiPView.swift
//  RealtimeKitUI
//
//  Created by Shaunak Jagtap on 21/08/24.
//

import AVFoundation
import AVKit
import RealtimeKit
import RTKWebRTC
import UIKit

class SampleBufferVideoCallView: UIView {
    override class var layerClass: AnyClass {
        AVSampleBufferDisplayLayer.self
    }

    var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer {
        layer as! AVSampleBufferDisplayLayer
    }
}

class PipUserView: UIView {
    let videoDisplayView = SampleBufferVideoCallView()
    let profileAvatarView: RtkAvatarView = {
        let view = RtkAvatarView()
        view.setInitialName(font: UIFont.boldSystemFont(ofSize: 12))
        return view
    }()

    private var frameRenderer: RtkPipFrameRender?
    private let infoLabel: RtkLabel
    private var participant: RtkMeetingParticipant?
    private var flipFrameHorizonatlly: Bool

    init(flipFrameHorizonatlly: Bool) {
        self.flipFrameHorizonatlly = flipFrameHorizonatlly
        infoLabel = RtkUIUtility.createLabel()
        infoLabel.font = UIFont.systemFont(ofSize: 12)
        infoLabel.numberOfLines = 2
        super.init(frame: .zero)
        createSubView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createSubView() {
        addSubViews(profileAvatarView)
        addSubview(infoLabel)
        addSubview(videoDisplayView)
        infoLabel.set(.centerView(self), .leading(self, 20, .greaterThanOrEqual))
        profileAvatarView.set(.width(30), .height(30), .centerView(self))
        videoDisplayView.set(.fillSuperView(self))
    }

    func clean() {
        participant?.removeParticipantUpdateListener(participantUpdateListener: self)
        removeFrameFetcher()
    }

    func setParticipant(participant: RtkMeetingParticipant?) {
        self.participant?.removeParticipantUpdateListener(participantUpdateListener: self)
        if let participant {
            profileAvatarView.set(participant: participant)
            setFrameFetcher(participant: participant)
            videoDisplayView.isHidden = false
            participant.addParticipantUpdateListener(participantUpdateListener: self)
        }
        self.participant = participant
        updateVideoView()
    }

    private func setFrameFetcher(participant _: RtkMeetingParticipant) {
        removeFrameFetcher()
        let frameRenderer = RtkPipFrameRender(size: CGSize(width: bounds.size.width * 2.0, height: bounds.size.height * 2.0), displayLayer: videoDisplayView.sampleBufferDisplayLayer, flipFrame: flipFrameHorizonatlly)
        //        participant.videoTrack?.addRenderer(renderer: frameRenderer)
        self.frameRenderer = frameRenderer
    }

    private func removeFrameFetcher() {
        if let frameRenderer {
            frameRenderer.clean()
            //            participant.videoTrack?.removeRenderer(renderer: frameRenderer)
        }
        frameRenderer = nil
    }
}

extension PipUserView: RtkParticipantUpdateListener {
    func onAudioUpdate(participant _: RtkMeetingParticipant, isEnabled _: Bool) {}

    func onPinned(participant _: RtkMeetingParticipant) {}

    func onScreenShareUpdate(participant _: RtkMeetingParticipant, isEnabled _: Bool) {}

    func onUnpinned(participant _: RtkMeetingParticipant) {}

    func onUpdate(participant _: RtkMeetingParticipant) {}

    func onVideoUpdate(participant _: RtkMeetingParticipant, isEnabled _: Bool) {
        updateVideoView()
    }

    func updateVideoView() {
        if participant == nil {
            infoLabel.isHidden = false
            profileAvatarView.isHidden = true
            videoDisplayView.isHidden = true
        } else {
            if participant?.videoEnabled == false {
                infoLabel.isHidden = true
                profileAvatarView.isHidden = false
                videoDisplayView.isHidden = true
            } else {
                profileAvatarView.isHidden = true
                videoDisplayView.isHidden = false
            }
        }
    }
}

class PipDisplayView: UIView {
    var localUserView = PipUserView(flipFrameHorizonatlly: true)
    var otherUserView = PipUserView(flipFrameHorizonatlly: false)

    override init(frame: CGRect) {
        super.init(frame: frame)
        createSubView()
    }

    private func createSubView() {
        addSubview(localUserView)
        addSubview(otherUserView)
        localUserView.set(.leading(self),
                          .top(self),
                          .trailing(self),
                          .equateAttribute(.height, toView: self, toAttribute: .height, withRelation: .equal, multiplier: 0.5))
        otherUserView.set(.below(localUserView),
                          .leading(self),
                          .bottom(self),
                          .trailing(self))
    }

    func clean() {
        localUserView.clean()
        otherUserView.clean()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class RtkPipController: NSObject {
    private var videoView: UIView
    private var pipController: AVPictureInPictureController?
    var isPlayBackPaused = true
    private(set) var localUser: RtkSelfParticipant
    var videoViewToDisplayOnPip = PipDisplayView()
    private(set) var otherUser: RtkRemoteParticipant?
    private let size: CGSize
    private let scaleFactorWidth = 0.25
    private let scaleFactorHeight = 0.20

    init?(renderingView: UIView, localUser: RtkSelfParticipant) {
        videoView = renderingView
        self.localUser = localUser
        let screenSize = UIScreen.main.bounds.size
        size = CGSize(width: screenSize.width * scaleFactorWidth, height: screenSize.height * scaleFactorHeight)
        super.init()

        if #available(iOS 15.0, *) {
            let pipVideoCallViewController = AVPictureInPictureVideoCallViewController()
            pipVideoCallViewController.preferredContentSize = size
            pipVideoCallViewController.view.addSubview(videoViewToDisplayOnPip)
            videoViewToDisplayOnPip.set(.fillSuperView(pipVideoCallViewController.view))
            videoViewToDisplayOnPip.backgroundColor = DesignLibrary.shared.color.background.shade1000
            let pipContentSource = AVPictureInPictureController.ContentSource(
                activeVideoCallSourceView: self.videoView,
                contentViewController: pipVideoCallViewController,
            )
            pipController = AVPictureInPictureController(contentSource: pipContentSource)
            pipController?.delegate = self
            pipController?.canStartPictureInPictureAutomaticallyFromInline = true

        } else {
            // Fallback on earlier versions
            return nil
        }
    }

    func clean() {
        videoViewToDisplayOnPip.clean()
    }

    func setSecondaryUser(otherParticipant: RtkRemoteParticipant?) {
        otherUser = otherParticipant
        if pipController?.isPictureInPictureActive == true {
            videoViewToDisplayOnPip.otherUserView.setParticipant(participant: otherUser)
        }
    }
}

extension RtkPipController: AVPictureInPictureControllerDelegate {
    open func pictureInPictureControllerWillStartPictureInPicture(
        _: AVPictureInPictureController,
    ) {}

    func pictureInPictureControllerDidStartPictureInPicture(_: AVPictureInPictureController) {
        print("[RTK_PIP] Delegate PiP Did start.")
        videoViewToDisplayOnPip.localUserView.setParticipant(participant: localUser)
        videoViewToDisplayOnPip.otherUserView.setParticipant(participant: otherUser)
    }

    open func pictureInPictureControllerWillStopPictureInPicture(
        _: AVPictureInPictureController,
    ) {
        print("[RTK_PIP] Delegate  PiP will stop shortly.")
        videoViewToDisplayOnPip.clean()
    }

    func pictureInPictureControllerDidStopPictureInPicture(_: AVPictureInPictureController) {
        print("[RTK_PIP] Delegate  PiP DID stop shortly.")
    }

    open func pictureInPictureController(
        _: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error,
    ) {
        let error = error as NSError
        print("[RTK_PIP] Delegate Failed to start PiP with error: \(error.localizedDescription). \(error)")
    }
}

class RtkPipFrameRender: NSObject, RTKRTCVideoRenderer {
    var displayLayer: AVSampleBufferDisplayLayer
    let targetSize: CGSize
    let flipFrame: Bool

    init(size: CGSize, displayLayer: AVSampleBufferDisplayLayer, flipFrame: Bool = false) {
        self.displayLayer = displayLayer
        targetSize = size
        self.flipFrame = flipFrame
    }

    func setSize(_: CGSize) {}

    var shouldRenderFrame = true

    func clean() {
        shouldRenderFrame = false
    }

    private var pixelBufferPool: CVPixelBufferPool?
    private var frameProcessingQueue = DispatchQueue(label: "FrameProcessingQueue")
    private let synchronizationQueue = DispatchQueue(label: "com.yourapp.synchronizationQueue")

    var isReady = true
    func renderFrame(_ frame: RTKRTCVideoFrame?) {
        guard let frame else {
            print("[RTK_PIP] Frame passed is nil")
            return
        }

        synchronizationQueue.async { [weak self] in
            guard let self else { return }
            if isReady {
                isReady = false
                frameProcessingQueue.async { [weak self] in
                    guard let self else { return }
                    if let sampleBuffer = handleRTCVideoFrame(frame) {
                        DispatchQueue.main.async { [weak self] in
                            guard let self else { return }
                            if displayLayer.isReadyForMoreMediaData, shouldRenderFrame {
                                displayLayer.enqueue(sampleBuffer)
                            }
                        }
                    }
                    synchronizationQueue.async {
                        self.isReady = true
                    }
                }
            }
        }
    }

    // Helper function to convert RTCVideoFrame to CVPixelBuffer
    private func frameToPixelBuffer(frame: RTKRTCVideoFrame) -> CVPixelBuffer? {
        if let buffer = frame.buffer as? RTKRTCCVPixelBuffer {
            return buffer.pixelBuffer
        } else if let buffer = frame.buffer as? RTKRTCI420Buffer {
            return createPixelBuffer(from: buffer, targetSize: targetSize)
        }
        print("[RTK_PIP] buffer should be of type RTKRTCCVPixelBuffer")
        return nil
    }

    private func handleRTCVideoFrame(_ frame: RTKRTCVideoFrame) -> CMSampleBuffer? {
        // Example: Convert frame to CVPixelBuffer for further processing
        if let pixelBuffer = frameToPixelBuffer(frame: frame) {
            // Use pixelBuffer as needed
            return createSampleBufferFromPixelBuffer(pixelBuffer: pixelBuffer)
        }
        print("[RTK_PIP] pixel buffer cannot be created")
        return nil
    }

    var pixelBuffer: CVPixelBuffer?
    var pixelBufferKey: String?

    private func createPixelBuffer(from i420Buffer: RTKRTCI420Buffer, targetSize: CGSize) -> CVPixelBuffer? {
        // Calculate the scale factor based on the target size and the original buffer size
        let widthScaleFactor = targetSize.width / CGFloat(i420Buffer.width)
        let heightScaleFactor = targetSize.height / CGFloat(i420Buffer.height)

        // Choose the smaller scale factor to maintain aspect ratio
        let scaleFactor = min(widthScaleFactor, heightScaleFactor)

        // Calculate the new width and height based on the scale factor
        var width = Int(CGFloat(i420Buffer.width) * scaleFactor)
        var height = Int(CGFloat(i420Buffer.height) * scaleFactor)

        if width % 2 != 0 {
            width += 1
        }
        if height % 2 != 0 {
            height += 1
        }

        let tempKey = "\(width)_\(height)"
        if tempKey != pixelBufferKey {
            pixelBuffer = nil
            pixelBufferKey = tempKey
        }

        if pixelBuffer == nil {
            let attributes: [String: Any] = [
                kCVPixelBufferCGImageCompatibilityKey as String: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
                kCVPixelBufferIOSurfacePropertiesKey as String: [:],
            ]

            let status = CVPixelBufferCreate(
                kCFAllocatorDefault,
                width,
                height,
                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                attributes as CFDictionary,
                &pixelBuffer,
            )
            // Create a CVPixelBuffer with the specified width, height, and pixel format type
            guard status == kCVReturnSuccess else {
                print("Failed to create CVPixelBuffer.")
                return nil
            }
        }

        guard let createdPixelBuffer = pixelBuffer else {
            print("Failed to load CVPixelBuffer.")
            return nil
        }

        // Lock the pixel buffer base address for writing
        CVPixelBufferLockBaseAddress(createdPixelBuffer, [])

        // Resize and copy the Y plane
        if let yBaseAddress = CVPixelBufferGetBaseAddressOfPlane(createdPixelBuffer, 0) {
            let yDestination = yBaseAddress.assumingMemoryBound(to: UInt8.self)
            let ySource = i420Buffer.dataY
            let yStride = CVPixelBufferGetBytesPerRowOfPlane(createdPixelBuffer, 0)

            for row in 0 ..< height {
                let origRow = Int(ceilf(Float(row) / Float(scaleFactor)))
                for col in 0 ..< width {
                    let origCol = Int(ceilf(Float(col) / Float(scaleFactor)))
                    if flipFrame {
                        let flippedCol = Int(i420Buffer.width) - 1 - origCol
                        yDestination[row * yStride + col] = ySource[origRow * Int(i420Buffer.strideY) + flippedCol]
                    } else {
                        yDestination[row * yStride + col] = ySource[origRow * Int(i420Buffer.strideY) + origCol]
                    }
                }
            }
        }

        // Resize and copy the UV plane (interleaved UV format)
        if let uvBaseAddress = CVPixelBufferGetBaseAddressOfPlane(createdPixelBuffer, 1) {
            let uvDestination = uvBaseAddress.assumingMemoryBound(to: UInt8.self)
            let uSource = i420Buffer.dataU
            let vSource = i420Buffer.dataV
            let uvStride = CVPixelBufferGetBytesPerRowOfPlane(createdPixelBuffer, 1)

            for row in 0 ..< height / 2 {
                let origRow = Int(ceilf(Float(row) / Float(scaleFactor)))

                for col in 0 ..< width / 2 {
                    let origCol = Int(ceilf(Float(col) / Float(scaleFactor)))

                    let uvIndex = row * uvStride + col * 2
                    if flipFrame {
                        let flippedCol = Int(i420Buffer.width / 2) - 1 - origCol
                        // Interleave U and V
                        uvDestination[uvIndex] = uSource[origRow * Int(i420Buffer.strideU) + flippedCol]
                        uvDestination[uvIndex + 1] = vSource[origRow * Int(i420Buffer.strideV) + flippedCol]
                    } else {
                        // Interleave U and V
                        uvDestination[uvIndex] = uSource[origRow * Int(i420Buffer.strideU) + origCol]
                        uvDestination[uvIndex + 1] = vSource[origRow * Int(i420Buffer.strideV) + origCol]
                    }
                }
            }
        }

        // Unlock the pixel buffer base address
        CVPixelBufferUnlockBaseAddress(createdPixelBuffer, [])

        return createdPixelBuffer
    }

    private func createSampleBufferFromPixelBuffer(pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil,
                                                     imageBuffer: pixelBuffer,
                                                     formatDescriptionOut: &formatDescription)

        guard let formatDescription else {
            print("[RTK_PIP] not able to create format description")
            return nil
        }

        var sampleBuffer: CMSampleBuffer?
        var timingInfo = CMSampleTimingInfo()
        timingInfo.duration = CMTime.invalid
        timingInfo.decodeTimeStamp = CMTime.invalid
        timingInfo.presentationTimeStamp = CMTime(value: CMTimeValue(CACurrentMediaTime() * 1000), timescale: 1000)

        let status = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                        imageBuffer: pixelBuffer,
                                                        dataReady: true,
                                                        makeDataReadyCallback: nil,
                                                        refcon: nil,
                                                        formatDescription: formatDescription,
                                                        sampleTiming: &timingInfo,
                                                        sampleBufferOut: &sampleBuffer)
        if status != noErr {
            print("[RTK_PIP] Failed to create CMSampleBuffer: \(status)")
            return nil
        }

        return sampleBuffer
    }

    deinit {
        print("[Rtk_PIP] Deinit frame fetcher")
    }
}
