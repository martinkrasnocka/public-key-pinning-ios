//
//  ContentView.swift
//  PublicKeyPinning
//
//  Created by Martin Krasnocka on 29/09/2020.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var viewModel = ViewModel()
    
    var body: some View {
        Text(viewModel.result)
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
