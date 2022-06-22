//
//  HomeUIView.swift
//  MoneyRates
//
//  Created by Omar Gomez on 10/6/22.
//

import SwiftUI
import Combine

struct HomeUIView: View {
    
    @ObservedObject private var viewModel: HomeViewModelImpl
    @State private var sourceAmount: String = ""
    @State private var targetAmount: String = ""
    @State var errorAlert: Bool = false
    @FocusState private var sourceFocused: Bool
    @FocusState private var targetFocused: Bool
    
    init(viewModel: HomeViewModelImpl) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        HStack {
            Spacer()
                .frame(width: 16.0)
            VStack(spacing: 8.0) {
                ActivityIndicatorView(isAnimating: viewModel.busy)
                Spacer()
                Button(action: {
                    viewModel.pickSourceEvent()
                }, label: {
                    Text(viewModel.sourceTitle)
                })
                    .appButtonStyle()
                TextField("Source amount", text: $sourceAmount)
                    .focused($sourceFocused)
                    .onChange(of: sourceAmount, perform: { newValue in
                        if sourceFocused {
                            viewModel.onInput(source: newValue)
                        }
                    })
                    .appTextFieldStyle()
                Spacer()
                    .frame(height: 8.0)
                TextField("Target amount", text: $targetAmount)
                    .focused($targetFocused)
                    .onChange(of: targetAmount, perform: { newValue in
                        if targetFocused {
                            viewModel.onInput(target: newValue)
                        }
                    })
                    .appTextFieldStyle()
                Button(action: {
                    viewModel.pickTargetEvent()
                }, label: {
                    Text(viewModel.targetTitle)
                })
                    .appButtonStyle()
                Spacer()
            }
            Spacer()
                .frame(width: 16.0)
        }
        .onAppear(perform: {
            viewModel.onLoad()
        })
        .onChange(of: viewModel.targetResult, perform: { newValue in
            if !targetFocused, let text = newValue?.description {
                targetAmount = text
            }
        })
        .onChange(of: viewModel.sourceResult, perform: { newValue in
            if !sourceFocused, let text = newValue?.description {
                sourceAmount = text
            }
        })
        .onChange(of: viewModel.error, perform: { newValue in
            errorAlert = true
        })
        .alert(isPresented: $errorAlert, content: {
            Alert(title: Text(viewModel.error?.title ?? "--"), message:
                    Text(viewModel.error?.description ?? "--"),
                  dismissButton: .cancel())
        })
    }
}

private extension HomeUIView {
}

struct HomeUIView_Previews: PreviewProvider {
    static var previews: some View {
        HomeUIView(viewModel: HomeViewModelImpl())
    }
}

