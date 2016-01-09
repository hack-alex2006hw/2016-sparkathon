//
//  AF+Image+Extension.swift
//
//  Version 1.03
//
//  Created by Melvin Rivera on 7/5/14.
//  Copyright (c) 2014 All Forces. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import CoreGraphics


enum UIImageContentMode {
    case ScaleToFill, ScaleAspectFit, ScaleAspectFill
}

extension UIImage {
    
    private class func sharedCache() -> NSCache!
    {
        struct StaticSharedCache {
            static var sharedCache: NSCache? = nil
            static var onceToken: dispatch_once_t = 0
        }
        dispatch_once(&StaticSharedCache.onceToken) {
            StaticSharedCache.sharedCache = NSCache()
        }
        return StaticSharedCache.sharedCache!
    }
    
    // MARK: Image from solid color
    convenience init?(color:UIColor, size:CGSize = CGSizeMake(10, 10))
    {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        self.init(CGImage:UIGraphicsGetImageFromCurrentImageContext().CGImage)
        UIGraphicsEndImageContext()
    }
    
    // MARK:  Image from gradient colors
    convenience init?(gradientColors:[UIColor], size:CGSize = CGSizeMake(10, 10) )
    {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        var context = UIGraphicsGetCurrentContext()
        var colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = gradientColors.map {(color: UIColor) -> AnyObject! in return color.CGColor as AnyObject! } as NSArray
        var gradient = CGGradientCreateWithColors(colorSpace, colors, nil)
        CGContextDrawLinearGradient(context, gradient, CGPoint(x: 0, y: 0), CGPoint(x: 0, y: size.height), 0)
        self.init(CGImage:UIGraphicsGetImageFromCurrentImageContext().CGImage)
        UIGraphicsEndImageContext()
    }
    
    
    func applyGradientColors(gradientColors: [UIColor], blendMode: CGBlendMode = kCGBlendModeNormal) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()
        CGContextTranslateCTM(context, 0, size.height)
        CGContextScaleCTM(context, 1.0, -1.0)
        CGContextSetBlendMode(context, kCGBlendModeNormal)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        CGContextDrawImage(context, rect, self.CGImage)
        // Create gradient
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = gradientColors.map {(color: UIColor) -> AnyObject! in return color.CGColor as AnyObject! } as NSArray
        let gradient = CGGradientCreateWithColors(colorSpace, colors, nil)
        // Apply gradient
        CGContextClipToMask(context, rect, self.CGImage)
        CGContextDrawLinearGradient(context, gradient, CGPoint(x: 0, y: 0), CGPoint(x: 0, y: size.height), 0)
        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return image;
    }
    
    // MARK: Image with Text
    convenience init?(text: String, font: UIFont = UIFont.systemFontOfSize(18), color: UIColor = UIColor.whiteColor(), backgroundColor: UIColor = UIColor.grayColor(), size:CGSize = CGSizeMake(100, 100), offset: CGPoint = CGPoint(x: 0, y: 0))
    {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, backgroundColor.CGColor)
        CGContextFillRect(context, CGRect(origin: CGPoint(x: 0, y: 0), size: size))
        var style = NSMutableParagraphStyle()
        style.alignment = .Center
        let attr = [NSFontAttributeName:font, NSForegroundColorAttributeName:color, NSParagraphStyleAttributeName:style]
        let rect = CGRect(x: offset.x, y: offset.y, width: size.width, height: size.height)
        text.drawInRect(rect, withAttributes: attr)
        self.init(CGImage:UIGraphicsGetImageFromCurrentImageContext().CGImage)
        UIGraphicsEndImageContext()
    }
    
    
    
    // MARK: Image from uiview
    convenience init?(fromView view: UIView) {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        //view.drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
        view.layer.renderInContext(UIGraphicsGetCurrentContext())
        self.init(CGImage:UIGraphicsGetImageFromCurrentImageContext().CGImage)
        UIGraphicsEndImageContext()
    }
    
    func addShadow(blurSize: CGFloat = 6.0) -> UIImage {
        
        let data : UnsafeMutablePointer<Void> = nil
        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
        let shadowContext : CGContextRef = CGBitmapContextCreate(data, Int(self.size.width + blurSize), Int(self.size.height + blurSize), CGImageGetBitsPerComponent(self.CGImage), 0, CGColorSpaceCreateDeviceRGB(), bitmapInfo)
        
        CGContextSetShadowWithColor(shadowContext, CGSize(width: blurSize/2,height: -blurSize/2),  blurSize/2, UIColor.darkGrayColor().CGColor)
        CGContextDrawImage(shadowContext, CGRect(x: 0, y: blurSize, width: self.size.width, height: self.size.height), self.CGImage)
        
        let shadowedCGImage : CGImageRef = CGBitmapContextCreateImage(shadowContext)
        let shadowedImage : UIImage = UIImage(CGImage: shadowedCGImage)!
        
        return shadowedImage
    }
    
    // MARK: Image with Radial Gradient
    // Render a radial background
    // Originally from: http://developer.apple.com/library/ios/#documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_shadings/dq_shadings.html
    convenience init?(startColor: UIColor, endColor: UIColor, radialGradientCenter: CGPoint = CGPoint(x: 0.5, y: 0.5), radius:Float = 0.5, size:CGSize = CGSizeMake(100, 100))
    {
        
        // Init
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        
        let num_locations: Int = 2
        let locations: [CGFloat] = [0.0, 1.0]
        
        let startComponents = CGColorGetComponents(startColor.CGColor)
        let endComponents = CGColorGetComponents(endColor.CGColor)
        
        let components: [CGFloat] = [startComponents[0], startComponents[1], startComponents[2], startComponents[3], endComponents[0], endComponents[1], endComponents[2], endComponents[3]]
        
        var colorSpace = CGColorSpaceCreateDeviceRGB()
        var gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, num_locations)
        
        // Normalize the 0-1 ranged inputs to the width of the image
        let aCenter = CGPoint(x: radialGradientCenter.x * size.width, y: radialGradientCenter.y * size.height)
        let aRadius = CGFloat(min(size.width, size.height)) * CGFloat(radius)
        
        // Draw it
        CGContextDrawRadialGradient(UIGraphicsGetCurrentContext(), gradient, aCenter, 0, aCenter, aRadius, UInt32(kCGGradientDrawsAfterEndLocation))
        self.init(CGImage:UIGraphicsGetImageFromCurrentImageContext().CGImage)
        // Clean up
        UIGraphicsEndImageContext()
    }
    
    // MARK: Alpha

    
    // Returns true if the image has an alpha layer
    func hasAlpha() -> Bool
    {
        let alpha = CGImageGetAlphaInfo(self.CGImage)
        switch alpha {
        case .First, .Last, .PremultipliedFirst, .PremultipliedLast:
            return true
        default:
            return false
            
        }
    }
    
    // Returns a copy of the given image, adding an alpha channel if it doesn't already have one
    
    func applyAlpha() -> UIImage?
    {
        if hasAlpha() {
            return self
        }
        
        let imageRef = self.CGImage;
        let width = CGImageGetWidth(imageRef);
        let height = CGImageGetHeight(imageRef);
        let colorSpace = CGImageGetColorSpace(imageRef)
        
        // The bitsPerComponent and bitmapInfo values are hard-coded to prevent an "unsupported parameter combination" error
        let bitmapInfo = CGBitmapInfo(CGBitmapInfo.ByteOrderDefault.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue)
        let offscreenContext = CGBitmapContextCreate(nil, width, height, 8, 0, colorSpace, bitmapInfo)
        
        // Draw the image into the context and retrieve the new image, which will now have an alpha layer
        CGContextDrawImage(offscreenContext, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), imageRef)
        var imageWithAlpha = UIImage(CGImage: CGBitmapContextCreateImage(offscreenContext))
        return imageWithAlpha
    }
    
    // Returns a copy of the image with a transparent border of the given size added around its edges.
    func applyPadding(padding: CGFloat) -> UIImage?
    {
        // If the image does not have an alpha layer, add one
        var image = self.applyAlpha()
        if image == nil {
            return nil
        }
        let rect = CGRect(x: 0, y: 0, width: size.width + padding * 2, height: size.height + padding * 2)
        
        // Build a context that's the same dimensions as the new size
        let colorSpace = CGImageGetColorSpace(self.CGImage)
        let bitmapInfo = CGImageGetBitmapInfo(self.CGImage)
        let bitsPerComponent = CGImageGetBitsPerComponent(self.CGImage)
        let context = CGBitmapContextCreate(nil, Int(rect.size.width), Int(rect.size.height), bitsPerComponent, 0, colorSpace, bitmapInfo)
        
        // Draw the image in the center of the context, leaving a gap around the edges
        let imageLocation = CGRect(x: padding, y: padding, width: image!.size.width, height: image!.size.height)
        CGContextDrawImage(context, imageLocation, self.CGImage)
        
        // Create a mask to make the border transparent, and combine it with the image
        var transparentImage = UIImage(CGImage: CGImageCreateWithMask(CGBitmapContextCreateImage(context), imageRefWithPadding(padding, size: rect.size)))
        return transparentImage
    }
    
    // Creates a mask that makes the outer edges transparent and everything else opaque
    // The size must include the entire mask (opaque part + transparent border)
    // The caller is responsible for releasing the returned reference by calling CGImageRelease
    private func imageRefWithPadding(padding: CGFloat, size:CGSize) -> CGImageRef
    {
        // Build a context that's the same dimensions as the new size
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(CGBitmapInfo.ByteOrderDefault.rawValue | CGImageAlphaInfo.None.rawValue)
        let context = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), 8, 0, colorSpace, bitmapInfo)
        // Start with a mask that's entirely transparent
        CGContextSetFillColorWithColor(context, UIColor.blackColor().CGColor)
        CGContextFillRect(context, CGRect(x: 0, y: 0, width: size.width, height: size.height))
        // Make the inner part (within the border) opaque
        CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
        CGContextFillRect(context, CGRect(x: padding, y: padding, width: size.width - padding * 2, height: size.height - padding * 2))
        // Get an image of the context
        let maskImageRef = CGBitmapContextCreateImage(context)
        return maskImageRef
    }
    
    
    // MARK: Crop
    
    func crop(bounds: CGRect) -> UIImage?
    {
        return UIImage(CGImage: CGImageCreateWithImageInRect(self.CGImage, bounds))
    }
    
    func cropToSquare() -> UIImage? {
        let shortest = min(size.width, size.height)
        let left: CGFloat = size.width > shortest ? (size.width-shortest)/2 : 0
        let top: CGFloat = size.height > shortest ? (size.height-shortest)/2 : 0
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let insetRect = CGRectInset(rect, left, top)
        return crop(insetRect)
    }
    
    
    func resize(size: CGSize)-> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.drawInRect(CGRectMake(0, 0, size.width, size.height))
        var img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
    // MARK: Resize
    
       // MARK: Corner Radius
    
    func roundCorners(cornerRadius:CGFloat) -> UIImage?
    {
        // If the image does not have an alpha layer, add one
        var imageWithAlpha = applyAlpha()
        if imageWithAlpha == nil {
            return nil
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let width = CGImageGetWidth(imageWithAlpha?.CGImage)
        let height = CGImageGetHeight(imageWithAlpha?.CGImage)
        let bits = CGImageGetBitsPerComponent(imageWithAlpha?.CGImage)
        let colorSpace = CGImageGetColorSpace(imageWithAlpha?.CGImage)
        let bitmapInfo = CGImageGetBitmapInfo(imageWithAlpha?.CGImage)
        let context = CGBitmapContextCreate(nil, width, height, bits, 0, colorSpace, bitmapInfo)
        let rect = CGRect(x: 0, y: 0, width: size.width*scale, height: size.height*scale)
        
        CGContextBeginPath(context)
        if (cornerRadius == 0) {
            CGContextAddRect(context, rect)
        } else {
            CGContextSaveGState(context)
            CGContextTranslateCTM(context, rect.minX, rect.minY)
            CGContextScaleCTM(context, cornerRadius, cornerRadius)
            let fw = rect.size.width / cornerRadius
            let fh = rect.size.height / cornerRadius
            CGContextMoveToPoint(context, fw, fh/2)
            CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1)
            CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1)
            CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1)
            CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1)
            CGContextRestoreGState(context)
        }
        CGContextClosePath(context)
        CGContextClip(context)
        
        CGContextDrawImage(context, rect, imageWithAlpha?.CGImage)
        var image = UIImage(CGImage: CGBitmapContextCreateImage(context), scale:scale, orientation: .Up)
        UIGraphicsEndImageContext()
        return image
    }
    
    func setGradientToImage(frame:CGRect, locationList: [CGFloat], colorList: [CGFloat], startPoint: CGPoint, endPoint: CGPoint)->UIImage
    {
        // Allocate color space
        var colorSpace = CGColorSpaceCreateDeviceRGB()
        let componentCount : Int = Int(locationList.count)
        //allocate myGradient
        //var locationList: [CGFloat] = [0.0,1.0]
        //var colorList: [CGFloat] = [253.0/255.0, 76.0/255.0, 83.0 / 255.0, 1.0, 1.0, 1.0, 1.0, 0.0]
        var myGradient   = CGGradientCreateWithColorComponents(colorSpace, colorList, locationList, componentCount)
        
        // Allocate bitmap context
        
        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
        let bitmapContext = CGBitmapContextCreate(nil, Int(frame.width), Int(frame.height), 8, 0, colorSpace, bitmapInfo)
        
        //Draw Gradient Here
        
        CGContextDrawLinearGradient(bitmapContext, myGradient, startPoint, endPoint, 0)
        // Create a CGImage from context
        var cgImage = CGBitmapContextCreateImage(bitmapContext)
        // Create a UIImage from CGImage
        var uiImage = UIImage(CGImage: cgImage)
        
        return uiImage!
    }
    
    func roundCorners(cornerRadius:CGFloat, border:CGFloat, color:UIColor) -> UIImage?
    {
        return roundCorners(cornerRadius)?.applyBorder(border, color: color)
    }
    
    func roundCornersToCircle() -> UIImage?
    {
        let shortest = min(size.width, size.height)
        return cropToSquare()?.roundCorners(shortest/2)
    }
    
    func roundCornersToCircle(#border:CGFloat, color:UIColor) -> UIImage?
    {
        let shortest = min(size.width, size.height)
        return cropToSquare()?.roundCorners(shortest/2, border: border, color: color)
    }
    
    // MARK: Border
    
    func applyBorder(border:CGFloat, color:UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let width = CGImageGetWidth(self.CGImage)
        let height = CGImageGetHeight(self.CGImage)
        let bits = CGImageGetBitsPerComponent(self.CGImage)
        let colorSpace = CGImageGetColorSpace(self.CGImage)
        let bitmapInfo = CGImageGetBitmapInfo(self.CGImage)
        let context = CGBitmapContextCreate(nil, width, height, bits, 0, colorSpace, bitmapInfo)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        CGContextSetRGBStrokeColor(context, red, green, blue, alpha)
        CGContextSetLineWidth(context, border)
        let rect = CGRect(x: 0, y: 0, width: size.width*scale, height: size.height*scale)
        let inset = CGRectInset(rect, border*scale, border*scale)
        CGContextStrokeEllipseInRect(context, inset)
        CGContextDrawImage(context, inset, self.CGImage)
        let image = UIImage(CGImage: CGBitmapContextCreateImage(context))
        UIGraphicsEndImageContext()
        return image
    }
    
    // MARK: Image From URL
    
    class func imageFromURL(url: String, placeholder: UIImage, shouldCacheImage: Bool = true, closure: (image: UIImage?) -> ()) -> UIImage?
    {
        // From Cache
        if shouldCacheImage {
            if UIImage.sharedCache().objectForKey(url) != nil {
                closure(image: nil)
                return UIImage.sharedCache().objectForKey(url) as! UIImage!
            }
        }
        // Fetch Image
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        if let nsURL = NSURL(string: url) {
            session.dataTaskWithURL(nsURL, completionHandler: {
                (response: NSData!, data: NSURLResponse!, error: NSError!) in
                if (error != nil) {
                    dispatch_async(dispatch_get_main_queue()) {
                        closure(image: nil)
                    }
                }
                if let image = UIImage(data: response) {
                    if shouldCacheImage {
                        UIImage.sharedCache().setObject(image, forKey: url)
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                        closure(image: image)
                    }
                }
                
            }).resume()
        }
        return placeholder
    }
    
    // draw a polygone image
    func drawPolygoneImage(size:CGSize, points:[CGPoint], fillcolor: UIColor, strokecolor: UIColor)->UIImage{

        var polygonImg = UIImage()
        
        var imageViewWidth = size.width
        var imageViewHeight = size.height
        
        //set the graphics context to be the size of the image
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0);
        
        polygonImg.drawInRect(CGRectMake(0.0, 0.0, imageViewWidth, imageViewHeight))
        
        //set the line attributes
        var context = UIGraphicsGetCurrentContext()
        
        CGContextSetLineWidth(context, 0.05);
        
        //uses path ref
        var path = CGPathCreateMutable()
        //draw the triangle
        CGPathMoveToPoint(path, nil, points[0].x, points[0].y)
        for var index = 1; index < points.count; index++ {
            CGPathAddLineToPoint(path, nil, points[index].x, points[index].y)
        }
        CGPathAddLineToPoint(path, nil, points[0].x, points[0].y)
        
        //close the path
        CGPathCloseSubpath(path);
        //add the path to the context
        CGContextAddPath(context, path)
        CGContextSetFillColorWithColor(context, fillcolor.CGColor);
        CGContextSetStrokeColorWithColor(context, strokecolor.CGColor)
        CGContextFillPath(context);
        
        CGContextAddPath(context, path);
        CGContextStrokePath(context);
        
        //get the image
        polygonImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return polygonImg
    }

    func maskImage(image:UIImage, maskImage:UIImage)->UIImage{
        
        var maskRef = maskImage.CGImage;
        
        var mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
            CGImageGetHeight(maskRef),
            CGImageGetBitsPerComponent(maskRef),
            CGImageGetBitsPerPixel(maskRef),
            CGImageGetBytesPerRow(maskRef),
            CGImageGetDataProvider(maskRef), nil, false)
        
        var masked = CGImageCreateWithMask(image.CGImage, mask)
        
        return UIImage(CGImage: masked!)!
    }

    
}