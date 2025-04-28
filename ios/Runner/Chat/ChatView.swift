//
//  ChatView.swift
//  Runner
//
//  Created by Yogesh Markandey on 21/04/25.
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var viewModel: IVSChatManager
    @Binding var selectedMessage: Message?

    var body: some View {
        GeometryReader { geometry in
            SimpleChatView(selectedMessage: $selectedMessage)
        }
    }
}
