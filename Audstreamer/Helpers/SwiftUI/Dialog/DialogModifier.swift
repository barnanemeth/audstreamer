//
//  DialogModifier.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 22..
//

import SwiftUI

@MainActor
struct DialogModifier {

    // MARK: Properties

    @Binding var isPresented: Bool
    let descriptor: DialogDescriptor

    // MARK: Private properties

    @State private var isAlertPresented = false
    @State private var isConfirmationDialogPresented = false

    // MARK: Init

    init(isPresented: Binding<Bool>, descriptor: DialogDescriptor) {
        self._isPresented = isPresented
        self.descriptor = descriptor
    }
}

// MARK: - ViewModifier

extension DialogModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .alert(
                descriptor.title,
                isPresented: $isAlertPresented,
                actions: { actions },
                message: { message }
            )
            .confirmationDialog(
                descriptor.title,
                isPresented: $isConfirmationDialogPresented,
                actions: { actions },
                message: { message }
            )
            .onChange(of: isPresented) { handleIsPresentedChange($1) }
            .onChange(of: isAlertPresented) { _, isPresented in
                guard !isPresented else { return }
                self.isPresented = isPresented
            }
            .onChange(of: isConfirmationDialogPresented) { _, isPresented in
                guard !isPresented else { return }
                self.isPresented = isPresented
            }
    }

    @ViewBuilder
    private var actions: some View {
        if let actions = descriptor.actions {
            ForEach(actions, id: \.title) { action in
                Button(action.title, role: buttonRole(for: action.type)) {
                    if let action = action.action {
                        action()
                    } else {
                        isPresented = false
                    }
                }
            }
        } else {
            Button(L10n.ok) { isPresented = false }
        }
    }

    @ViewBuilder
    private var message: some View {
        if let message = descriptor.message {
            Text(message)
        }
    }

    private func buttonRole(for actionType: DialogAction.`Type`) -> ButtonRole? {
        switch actionType {
        case .normal: nil
        case .cancel: .cancel
        case .destructive: .destructive
        }
    }

    private func handleIsPresentedChange(_ isPresented: Bool) {
        guard isPresented else { return }
        switch descriptor.type {
        case .alert:
            isAlertPresented = isPresented
        case .confirmationDialog:
            isConfirmationDialogPresented = isPresented
        }
    }
}

extension View {
    func alert(isPresented: Binding<Bool>,
               title: String,
               message: String? = nil,
               actions: [DialogAction]? = nil) -> some View {
        let descriptor = DialogDescriptor(title: title, message: message, type: .alert, actions: actions)
        return modifier(DialogModifier(isPresented: isPresented, descriptor: descriptor))
    }

    func confirmationDialog(isPresented: Binding<Bool>,
                            title: String,
                            message: String? = nil,
                            actions: [DialogAction]? = nil) -> some View {
        let descriptor = DialogDescriptor(title: title, message: message, type: .confirmationDialog, actions: actions)
        return modifier(DialogModifier(isPresented: isPresented, descriptor: descriptor))
    }

    func dialog(isPresented: Binding<Bool>, descriptor: DialogDescriptor) -> some View {
        modifier(DialogModifier(isPresented: isPresented, descriptor: descriptor))
    }

    func dialog(descriptor: Binding<DialogDescriptor?>) -> some View {
        let isPresented = Binding<Bool>(
            get: { descriptor.wrappedValue != nil },
            set: { isVisible in
                guard !isVisible else { return }
                descriptor.wrappedValue = nil
            }
        )
        let descriptor = if let descriptor = descriptor.wrappedValue {
            descriptor
        } else {
            DialogDescriptor(title: "")
        }
        return modifier(DialogModifier(isPresented: isPresented, descriptor: descriptor))
    }
}
