//
//  RtkNotification.swift
//  RealtimeKitUI
//
//  Created by Shaunak Jagtap on 19/05/23.
//

import AVFAudio
import Foundation

public class RtkNotification {
    public init() {}
    public func playNotificationSound(type: RtkNotificationType) {
        var resource = ""
        switch type {
        case .Chat(_), .Poll:
            resource = "notification_message"
        case .Joined, .Leave:
            resource = "notification_join"
        }

        let frameworkBundle = Bundle.resources
        guard let url = frameworkBundle.url(forResource: resource, withExtension: "mp3") else { return }
        var mySound: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &mySound)
        AudioServicesPlaySystemSound(mySound)
    }
}
