//
//  LTWebImageView.swift
//
//
//  Created by Pavel Razuvaev on 12/08/2016.
//  Copyright © 2016 LiveTyping. All rights reserved.
//

import Foundation
import UIKit

protocol DataLoadOperationDelegate {
    func dataWasLoaded()
}

class DataLoadOperation: NSOperation {
    var delegate:DataLoadOperationDelegate! = nil
    var url:NSString? = ""
    
    override func main() {
        if (self.url != nil) {
            let url:NSURL = NSURL.init(string: self.url as! String)!
            let localPath:NSString = self.url!.urlDataLocalPath()
            
            let data:NSData = NSData.init(contentsOfURL: url)!
            data.writeToFile(localPath as String, atomically: false)
            
            self.addSkipBackupAttributeToItemAtURL(url: url, localPath: localPath)
            
            delegate.dataWasLoaded()
        }
    }
    
    func addSkipBackupAttributeToItemAtURL(url url:NSURL, localPath:NSString) -> Bool {
        do {
            try url.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
            return true
        } catch _{
            return false
        }
    }
}

extension NSString {
    func urlDataLocalPath() -> NSString {
        let md5String = self.md5()
        let localPath:NSString = "\(NSHomeDirectory())/tmp/\(md5String)"
        return localPath
    }
    
    func md5() -> String {
        var digest = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)
        if let data = self.dataUsingEncoding(NSUTF8StringEncoding) {
            CC_MD5(data.bytes, CC_LONG(data.length), &digest)
        }
        
        var digestHex = ""
        for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
            digestHex += String(format: "%02x", digest[index])
        }
        
        return digestHex
    }
}

class LTWebImageView: UIImageView, DataLoadOperationDelegate {
    var url:NSString = ""
    var backgroundFromImage:Bool = false
    var queue:NSOperationQueue?
    
    //MARK: Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentMode = .ScaleAspectFit
        backgroundColor = UIColor.whiteColor()
        addSubview(self.activityIndicator)
        bringSubviewToFront(activityIndicator)
        
        activityIndicator.startAnimating()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: SetupUI
    lazy var activityIndicator:UIActivityIndicatorView = {
        var v = UIActivityIndicatorView()
        v.center = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2)
        v.hidesWhenStopped = true
        v.activityIndicatorViewStyle = .Gray
        return v
    }()
    
    func setImageWithUrl(url:NSString) {
        if (url.length > 0) {
            image = self.imageFromURL(url: url)
        }else {
            //TODO: вставь сюда картинку заглушки
            image = UIImage.init(named: "empty")
            backgroundColor = UIColor.whiteColor()
            activityIndicator.stopAnimating()
        }
    }
    
    func imageFromURL(url url:NSString) -> UIImage {
        self.url = url
        let localPath:NSString = url.urlDataLocalPath()
        let image:UIImage? = UIImage.init(contentsOfFile: localPath as String)
    
        if (image == nil) {
            let operation:DataLoadOperation = DataLoadOperation()
            operation.queuePriority = .VeryLow
            operation.url = url
            operation.delegate = self
            activityIndicator.startAnimating()
            
            if (queue == nil) {
                queue = NSOperationQueue()
                queue?.maxConcurrentOperationCount = 2
            }
            
            queue?.addOperation(operation)
            backgroundColor = UIColor.whiteColor()
            
            //TODO: вставь сюда картинку заглушки
            return UIImage.init(named: "empty")!
        }else {
            activityIndicator.stopAnimating()
            
            if self.backgroundFromImage {
                let rect:CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
                let drawImage:CGImageRef = CGImageCreateWithImageInRect(image?.CGImage, rect)!
                let patternImage:UIImage = UIImage.init(CGImage: drawImage)
                backgroundColor = UIColor.init(patternImage: patternImage)
            }
            
            return image!
        }
    }
    
    //MARK:Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        activityIndicator.center = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2)
    }
    
    //MARK:Data LoadOperationDelegate
    func dataWasLoaded() {
        backgroundColor = UIColor.whiteColor()
        image = self.imageFromURL(url: self.url)
    }
}