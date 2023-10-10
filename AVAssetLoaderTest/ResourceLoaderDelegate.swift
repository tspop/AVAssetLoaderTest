//
//  ResourceLoaderDelegate.swift
//  AVAssetLoaderSample
//
//  Created by Silviu Pop on 10/10/23.
//

import AVKit

typealias OnFinish = () -> Void

class MockDataRequest {
    let id: UUID
    let data: Data
    let loadingRequst: AVAssetResourceLoadingRequest
    let queue: DispatchQueue
    let backgroundQueue: DispatchQueue
    
    let bytesPerSecond = 100_000
    let ticksPerSecond = 100
    
    init(id: UUID, data: Data, loadingRequest: AVAssetResourceLoadingRequest, queue: DispatchQueue) {
        self.id = id
        self.data = data
        self.loadingRequst = loadingRequest
        self.queue = queue
        self.backgroundQueue = DispatchQueue(label: id.uuidString)
    }
    
    func start(onFinish: OnFinish?) {
        let bytesPerTick = bytesPerSecond / ticksPerSecond
        let sleepPerTick = 1.0 / TimeInterval(ticksPerSecond)
       
        backgroundQueue.async {
            var dataStart = 0
            
            while (true) {
                if self.loadingRequst.isCancelled {
                    break
                }
                
                let dataEnd = min(self.data.count, dataStart + bytesPerTick)
                
                let subData = self.data.subdata(in: dataStart..<dataEnd)
                
                self.queue.sync {
                    self.loadingRequst.dataRequest?.respond(with: subData)
                }
                
                if dataEnd == self.data.count {
                    self.queue.sync {
                        onFinish?()
                        self.loadingRequst.finishLoading()
                    }
                    print("✅ \(self.id): finished loading")
                    break
                }
                
                dataStart = dataEnd
                    
                Thread.sleep(forTimeInterval: sleepPerTick)
            }
        }
    }
}

class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    let data = try! Data(contentsOf: Bundle.main.url(forResource: "sample", withExtension: "mp4")!)
    
    let queue = DispatchQueue(label: "resource_loader")
    var loadingRequestToId = [AVAssetResourceLoadingRequest: UUID]()
    
    var startedRequests: [MockDataRequest] = []
    
    func fillContentInfo(_ loadingRequest: AVAssetResourceLoadingRequest) {
        guard let contentInfoRequest = loadingRequest.contentInformationRequest else { return }
        
        contentInfoRequest.isByteRangeAccessSupported = true
        contentInfoRequest.contentType = "video/mp4"
        contentInfoRequest.contentLength = Int64(data.count)
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        fillContentInfo(loadingRequest)
        
        let id = UUID()
        
        loadingRequestToId[loadingRequest] = id
        
        guard let dataRequest = loadingRequest.dataRequest else {
            loadingRequest.finishLoading()
            return true
        }
        
        let requestedRange = dataRequest.range(upperBound: data.count)
        let requestData = data.subdata(in: requestedRange)
        
        print("🚀 \(id): started  \(requestedRange.lowerBound) - \(requestedRange.upperBound)")
        
        let mockRequest = MockDataRequest(id: id,
                                          data: requestData,
                                          loadingRequest: loadingRequest,
                                          queue: queue)
                
        mockRequest.start {
            self.loadingRequestToId[loadingRequest] = nil
        }
        
        startedRequests.append(mockRequest)
        
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        let id = loadingRequestToId[loadingRequest]?.uuidString ?? "unknown"
        
        loadingRequestToId[loadingRequest] = nil
        
        print("❌ \(id): cancelled ")
    }
}
