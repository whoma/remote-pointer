//
//  QRCodeView.swift
//  remote-point
//
//  Created by 张文军 on 2024/11/2.
//

// QRCodeView.swift
import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let url: String
    
    var body: some View {
        if let qrImage = generateQRCode(from: url) {
            Image(nsImage: qrImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            Text("无法生成二维码")
                .foregroundColor(.red)
        }
    }
    
    private func generateQRCode(from string: String) -> NSImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        // 调整二维码大小
        let scale = CGAffineTransform(scaleX: 10.0, y: 10.0)
        let scaledImage = outputImage.transformed(by: scale)
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return NSImage(cgImage: cgImage, size: NSSize(width: scaledImage.extent.width, height: scaledImage.extent.height))
    }
}
