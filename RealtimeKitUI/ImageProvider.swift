//
//  ImageProvider.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 30/11/22.
//

import UIKit

public class ImageProvider {
    /// for any image located in bundle where this class has built
    public static func image(named: String) -> UIImage? {
        UIImage(named: named, in: Bundle.resources, with: nil)
    }
}

public class FileDownloader {
    static func downloadFile(from url: URL, to destinationURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        let session = URLSession(configuration: .default)

        let downloadTask = session.downloadTask(with: url) { location, _, error in
            guard let location else {
                completion(false, error)
                return
            }

            do {
                try FileManager.default.moveItem(at: location, to: destinationURL)
                completion(true, nil)
            } catch {
                completion(false, error)
            }
        }

        downloadTask.resume()
    }
}

final class ImageUtil {
    var session = URLSession(configuration: .default)
    var cache: NSCache<NSString, UIImage>!
    static let shared = ImageUtil()
    private init() {
        session = URLSession.shared
        cache = NSCache()
    }

    func obtainImageWithPath(url: URL, completionHandler: @escaping (UIImage, URL) -> Void) -> (UIImage?, URLSessionTask?) {
        obtainImageWithPath(imagePath: url.absoluteString, completionHandler: completionHandler)
    }

    func obtainImageWithPath(imagePath: String, completionHandler: @escaping (UIImage, URL) -> Void) -> (UIImage?, URLSessionTask?) {
        if let image = cache.object(forKey: imagePath as NSString) {
            return (image, nil)
        } else {
            guard let placeholder = ImageProvider.image(named: "icon_image") else { return (nil, nil) }
            if let url = URL(string: imagePath) {
                let task = session.dataTask(with: URLRequest(url: url)) { data, response, error in
                    if let data, error == nil, let url = response?.url {
                        if let img = UIImage(data: data) {
                            self.cache.setObject(img, forKey: url.absoluteString as NSString)
                            DispatchQueue.main.async {
                                completionHandler(img, url)
                            }
                        }
                    }
                }
                task.resume()

                return (placeholder, task)
            }

            print(Constants.errorLoadingImage)
            return (nil, nil)
        }
    }
}
