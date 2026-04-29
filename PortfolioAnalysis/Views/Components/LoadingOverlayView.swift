//
//  LoadingOverlayView.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/28/2026.
//


//
//  LoadingOverlayView.swift
//  PortfolioAnalysis
//
//  Small reusable loading overlay with spinner, message, and optional countdown/elapsed timer.
//

import SwiftUI
import Combine

struct LoadingOverlayView: View {
    /// Message to show above the spinner
    let message: String

    /// If non-nil, the overlay will show a countdown starting from this value and decrement each second.
    /// If nil, the overlay will show an elapsed timer instead.
    let countdownStart: Int?

    /// Called when the user taps Cancel (if you want to support canceling)
    var onCancel: (() -> Void)?

    @State private var remaining: Int = 0
    @State private var elapsed: Int = 0
    @State private var timerCancellable: AnyCancellable?

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.1)

            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)

            if let _ = countdownStart {
                Text(timerText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Time remaining \(timerText)")
            } else {
                Text("Elapsed: \(elapsedString)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Elapsed time \(elapsedString)")
            }

            if onCancel != nil {
                HStack(spacing: 12) {
                    Button("Cancel") {
                        stopTimer()
                        onCancel?()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 6)
            }
        }
        .padding(18)
        .background(VisualEffectBlur(blurStyle: .systemMaterial))
        .cornerRadius(12)
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
        .onChange(of: countdownStart) { _ in
            startTimer()
        }
    }

    private var timerText: String {
        let mins = remaining / 60
        let secs = remaining % 60
        return String(format: "%02d:%02d remaining", mins, secs)
    }

    private var elapsedString: String {
        let mins = elapsed / 60
        let secs = elapsed % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func startTimer() {
        stopTimer()
        if let start = countdownStart {
            remaining = max(0, start)
            timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    if remaining > 0 {
                        remaining -= 1
                    } else {
                        // keep at zero; you could call a timeout handler here if desired
                        stopTimer()
                    }
                }
        } else {
            elapsed = 0
            timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    elapsed += 1
                }
        }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}

// MARK: - VisualEffectBlur helper (light wrapper for a blurred background)
fileprivate struct VisualEffectBlur: UIViewRepresentable {
    let blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
