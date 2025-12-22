//
//  AsyncButton.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 22..
//

import SwiftUI

@MainActor
public struct AsyncButton<Label: View>: View {

    // MARK: Private properties

    private let title: (any StringProtocol)?
    private let role: ButtonRole?
    @ViewBuilder
    private let label: () -> Label
    private let action: @MainActor () async -> Void

    @State private var actionTask: Task<Void, Never>?
    @State private var thresholdTimerTask: Task<Void, Never>?
    @State private var isLoading = false
    @State private var isHitTestingAllowed = true
    @Environment(\.isLoading) private var externalLoading
    @Environment(\.isFeedbackEnabled) private var isFeedbackEnabled

    private let loadingStartThresholdTime: Duration = .seconds(0.15)
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    // MARK: Init

    public init(_ title: any StringProtocol,
                role: ButtonRole? = nil,
                action: @escaping @MainActor () async -> Void) where Label == EmptyView {
        self.title = title
        self.role = role
        self.label = { EmptyView() }
        self.action = action
    }

    public init(role: ButtonRole? = nil,
                action: @escaping @MainActor () async -> Void,
                @ViewBuilder label: @escaping () -> Label) {
        self.title = nil
        self.role = role
        self.label = label
        self.action = action
    }

    // MARK: UI

    public var body: some View {
        Button(role: role) {
            impactFeedbackIfNeeded()
            performAction()
        } label: {
            if isLoading {
                ProgressView()
                    .transition(.scale)
            } else {
                content
                    .transition(.opacity)
            }
        }
        .animation(.default, value: isLoading)
        .environment(\.isLoading, isLoading)
        .allowsHitTesting(isHitTestingAllowed)
        .onChange(of: externalLoading) { isLoading = $1 }
        .onAppear { feedbackGenerator.prepare() }
        .onDisappear {
            actionTask?.cancel()
            thresholdTimerTask?.cancel()
        }
    }

    @ViewBuilder
    private var content: some View {
        if let title {
            Text(title)
        } else {
            label()
        }
    }
}

// MARK: - Helpers

extension AsyncButton {
    private func performAction() {
        actionTask = Task { @MainActor in
            defer {
                isLoading = false
                isHitTestingAllowed = true
            }
            isHitTestingAllowed = false
            await action()
            thresholdTimerTask?.cancel()
        }
        thresholdTimerTask = Task { @MainActor in
            try? await Task.sleep(for: loadingStartThresholdTime, tolerance: .zero)
            guard !Task.isCancelled else { return }
            isLoading = true
        }
    }

    private func impactFeedbackIfNeeded() {
        guard isFeedbackEnabled else { return }
        feedbackGenerator.impactOccurred()
    }
}
