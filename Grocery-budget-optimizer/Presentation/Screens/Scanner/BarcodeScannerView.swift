//
//  BarcodeScannerView.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 05/10/2025.
//

import SwiftUI
import CodeScanner

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isTorchOn = false
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var showTestBarcodes = false
    
    let onBarcodeScanned: (String) -> Void
    let onTestProductSelected: ((String, String)) -> Void  // (name, barcode)
    
        // Test barcodes for development - Real Israeli products from Open Food Facts
    private let testBarcodes = [
        ("Tnuva Milk 3%", "7290004131074"),
        ("Nescafe Coffee", "7290000072753"),
        ("Tnuva Cottage 5%", "7290004127329"),
        ("Osem Ketchup", "7290000072623"),
    ]

    var body: some View {
        NavigationStack {
            CodeScannerView(
                codeTypes: [.ean13, .ean8, .upce, .code128, .code39, .qr],
                scanMode: .once,
                scanInterval: 0.5,
                showViewfinder: true,
                simulatedData: "Simulated barcode data",
                completion: handleScan
            )
            .navigationTitle(L10n.Scanner.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            toggleTorch()
                        } label: {
                            Label(isTorchOn ? "Turn Off Flashlight" : "Turn On Flashlight", 
                                  systemImage: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                        }
                        
                        Divider()
                        
                        Menu("Test Barcodes") {
                            ForEach(testBarcodes, id: \.1) { product in
                                Button(product.0) {
                                    useTestBarcode(product.0, product.1)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert(L10n.Scanner.Error.title, isPresented: $showError) {
                Button(L10n.Common.ok, role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(errorMessage ?? L10n.Scanner.Error.message)
            }
            .overlay(alignment: .bottom) {
                Text(L10n.Scanner.instruction)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.bottom, 100)
            }
        }
    }
    
    private func handleScan(result: Result<ScanResult, ScanError>) {
        switch result {
        case .success(let scanResult):
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            print("📱 Barcode scanned: \(scanResult.string)")
            onBarcodeScanned(scanResult.string)
            // Don't dismiss here - let the ViewModel handle it after processing
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            return
        }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = device.torchMode == .on ? .off : .on
            isTorchOn = device.torchMode == .on
            device.unlockForConfiguration()
        } catch {
            print("❌ Error toggling torch: \(error)")
        }
    }
    
    private func useTestBarcode(_ productName: String, _ barcode: String) {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        print("🧪 Using test product: \(productName) - \(barcode)")
        onTestProductSelected((productName, barcode))
    }
}

// Keep AVFoundation import for torch functionality
import AVFoundation
