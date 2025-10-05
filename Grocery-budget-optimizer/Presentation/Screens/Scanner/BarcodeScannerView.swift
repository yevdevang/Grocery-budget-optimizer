//
//  BarcodeScannerView.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 05/10/2025.
//

import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @StateObject private var viewModel: BarcodeScannerViewModel
    @Environment(\.dismiss) private var dismiss

    init(onBarcodeScanned: @escaping (String) -> Void) {
        _viewModel = StateObject(wrappedValue: BarcodeScannerViewModel(onBarcodeScanned: onBarcodeScanned))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera preview
                CameraPreview(session: viewModel.session)
                    .ignoresSafeArea()

                // Dark overlay with cutout
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .ignoresSafeArea()
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .frame(width: 280, height: 180)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()

                // Scanning overlay
                VStack {
                    Spacer()

                    // Targeting rectangle
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 280, height: 180)
                        .overlay {
                            if viewModel.isScanning {
                                // Scanning animation line
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.clear, .green, .clear]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 2)
                                    .offset(y: viewModel.scanLineOffset)
                            }
                        }

                    Text(L10n.Scanner.instruction)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.top, 20)

                    Spacer()
                }
            }
            .navigationTitle(L10n.Scanner.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.toggleTorch()
                    } label: {
                        Image(systemName: viewModel.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                    }
                }
            }
            .alert(L10n.Scanner.Error.title, isPresented: $viewModel.showError) {
                Button(L10n.Common.ok, role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(viewModel.errorMessage ?? L10n.Scanner.Error.message)
            }
            .onAppear {
                viewModel.startScanning()
            }
            .onDisappear {
                viewModel.stopScanning()
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}
