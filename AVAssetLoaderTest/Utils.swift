//
//  Utils.swift
//  AVAssetLoaderSample
//
//  Created by Silviu Pop on 10/10/23.
//

import AVKit

extension AVAssetResourceLoadingDataRequest {
    func range(upperBound: Int) -> Range<Int> {
        let start = Int(requestedOffset)
        var end = start
        if requestsAllDataToEndOfResource {
            end = upperBound
        } else {
            end += requestedLength
        }
        
        return start..<end
    }
}
