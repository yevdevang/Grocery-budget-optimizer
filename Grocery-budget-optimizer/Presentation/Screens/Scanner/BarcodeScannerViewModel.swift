//
//  BarcodeScannerViewModel.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 05/10/2025.
//

import Foundation
import AVFoundation
import SwiftUI
import Combine

@MainActor
class BarcodeScannerViewModel: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var isTorchOn = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var scanLineOffset: CGFloat = -90

    let session = AVCaptureSession()
    private var captureDevice: AVCaptureDevice?
    private var onBarcodeScanned: (String) -> Void
    private var hasScanned = false

    init(onBarcodeScanned: @escaping (String) -> Void) {
        self.onBarcodeScanned = onBarcodeScanned
        super.init()
    }

    func startScanning() {
        checkCameraPermission()
    }

    func stopScanning() {
        if session.isRunning {
            session.stopRunning()
        }
        isScanning = false
    }

    func toggleTorch() {
        guard let device = captureDevice, device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            device.torchMode = device.torchMode == .on ? .off : .on
            isTorchOn = device.torchMode == .on
            device.unlockForConfiguration()
        } catch {
            print("❌ Error toggling torch: \(error)")
        }
    }

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.showCameraPermissionError()
                    }
                }
            }
        case .denied, .restricted:
            showCameraPermissionError()
        @unknown default:
            showCameraPermissionError()
        }
    }

    private func setupCamera() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showError(message: "Unable to access camera")
            return
        }

        captureDevice = videoCaptureDevice

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)

            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            } else {
                showError(message: "Unable to add camera input")
                return
            }

            let metadataOutput = AVCaptureMetadataOutput()

            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [
                    .ean13,
                    .ean8,
                    .upce,
                    .code128,
                    .code39,
                    .qr
                ]
            } else {
                showError(message: "Unable to add metadata output")
                return
            }

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
                DispatchQueue.main.async {
                    self?.isScanning = true
                    self?.animateScanLine()
                }
            }

        } catch {
            showError(message: "Error setting up camera: \(error.localizedDescription)")
        }
    }

    private func animateScanLine() {
        guard isScanning else { return }

        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: true)) {
            scanLineOffset = 90
        }
    }

    private func showCameraPermissionError() {
        errorMessage = "Camera permission is required to scan barcodes. Please enable camera access in Settings."
        showError = true
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }

    func handleScannedBarcode(_ barcode: String) {
        guard !hasScanned else { return }

        hasScanned = true
        isScanning = false

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        print("📱 Barcode scanned: \(barcode)")
        onBarcodeScanned(barcode)
    }
}

extension BarcodeScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let barcode = readableObject.stringValue else {
            return
        }

        Task { @MainActor in
            handleScannedBarcode(barcode)
        }
    }
}
