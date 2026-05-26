//
//  SwiftConcurrencySupport.swift
//  RealtimeKitUI
//
//  Swift 6 strict concurrency: external SDK types used across actor
//  boundaries are declared @unchecked Sendable. These types are used
//  exclusively on the main thread in practice.
//

import CoreMedia
import RealtimeKit

extension RealtimeKitClient: @unchecked Sendable {}
extension RtkMeetingParticipant: @unchecked Sendable {}
extension RtkRemoteParticipant: @unchecked Sendable {}
extension RtkSelfParticipant: @unchecked Sendable {}
extension CMSampleBuffer: @unchecked Sendable {}
