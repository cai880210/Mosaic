//
//  Mosaic.swift
//  Mosaic
//
//  Created by Boris Emorine on 10/11/19.
//  Copyright © 2019 Boris Emorine. All rights reserved.
//

import UIKit

public final class Mosaic {
    
    /// The numbner of tiles in the mosaic per length (width & height).
    static let numberOfTiles: CGFloat = 40
    
    private let poolManager: ImagePoolManager
    private let resizedImageManager = ResizedImageManager()
    
    public init(imagePool: [UIImage]) throws {
        guard imagePool.count > 3 else {
            let error = NSError()
            throw error
        }
        
        poolManager = ImagePoolManager(images: imagePool)
        print("Finished Generating Image Pool")
    }
    
    public func generateMosaic(for image: UIImage) -> UIImage? {
        let imageSize = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        let tileSize = CGSize(width: imageSize.width / Mosaic.numberOfTiles, height: imageSize.height / Mosaic.numberOfTiles)
        
        let imageSequence = ImageTileSequence(tileSize: tileSize, imageSize: imageSize)
        let averageColorFinder = AverageColorFinder(image: image)
        
        var tileImagePositions = [ImagePositionMap]()
        
        var frames = [CGRect.zero]
        
        imageSequence.forEach { (frame) in
            frames.append(frame)
        }
        
        var averageColors = Array(repeating: UIColor.black, count: frames.count)
                
        DispatchQueue.concurrentPerform(iterations: frames.count) { (iteration) in
            let frame = frames[iteration]
            let averageColor = averageColorFinder.computeAverageColor(for: frame)!
            averageColors[iteration] = averageColor
        }
        
        print("Finished Getting Average Colors")
        
        guard averageColors.count == frames.count else {
            fatalError()
        }
        
        for (index, averageColor) in averageColors.enumerated() {
            let frame = frames[index]
            let closestTileImage = poolManager.closestImage(from: averageColor)
            let closestTileResizedImage = resizedImageManager.resizedImage(for: closestTileImage, size: tileSize)
            let imagePositionMap = ImagePositionMap(image: closestTileResizedImage, position: frame.origin)
            tileImagePositions.append(imagePositionMap)
        }
        
        print("Finished Getting Right Resized Pool Image")
                
        let mosaicImage = ImageStitcher.stitch(images: tileImagePositions, to: imageSize)
        
        print("Finished Stitching")
        
        return mosaicImage
    }
    
}

struct ImagePositionMap {
    
    let image: UIImage
    let position: CGPoint
    
}
