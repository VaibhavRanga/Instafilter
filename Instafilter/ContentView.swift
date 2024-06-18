//
//  ContentView.swift
//  Instafilter
//
//  Created by Vaibhav Ranga on 18/06/24.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import StoreKit
import SwiftUI

struct ContentView: View {
    @State private var processedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var filterRadius = 0.5
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingFilters = false
    
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    
    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    if let processedImage {
                        processedImage
                            .resizable()
                            .scaledToFit()
                    } else {
                        ContentUnavailableView("No image", systemImage: "photo.badge.plus", description: Text("Tap to import an image"))
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: selectedItem, loadImage)
                
                Spacer()
                
                HStack {
                    Text("Intensity")
                        .containerRelativeFrame(.horizontal) { size, axis in
                            size * 20 / 100
                        }
                    Slider(value: $filterIntensity)
                        .onChange(of: filterIntensity, applyProcessing)
                }
                .disabled(disableSlider())
                
                HStack {
                    Text("Radius")
                        .containerRelativeFrame(.horizontal) { size, axis in
                            size * 20 / 100
                        }
                    Slider(value: $filterRadius)
                        .onChange(of: filterRadius, applyProcessing)
                }
                .disabled(disableSlider())
                
                HStack {
                    Button("Change filter", action: changeFilter)
                    
                    Spacer()
                    
                    if let processedImage {
                        ShareLink(item: processedImage, preview: SharePreview("Instafilter image", image: processedImage))
                    }
                }
                .disabled(disableSlider())
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("Instafilter")
            .confirmationDialog("Select a filter", isPresented: $showingFilters) {
                Button("Crystallize") {
                    setFilter(CIFilter.crystallize())   //radius, center        r 50
                }
                Button("Edges") {
                    setFilter(CIFilter.edges())         //intensity     i 15
                }
                Button("Gaussian Blur") {
                    setFilter(CIFilter.gaussianBlur())  //radius        r 10
                }
                Button("Pixellate") {
                    setFilter(CIFilter.pixellate())     //center scale      s 30
                }
                Button("Sepia Tone") {
                    setFilter(CIFilter.sepiaTone())     //intensity 0.0-1.0
                }
                Button("Unsharp Mask") {
                    setFilter(CIFilter.unsharpMask())   //radius intensity      i 2.5
                }
                Button("Vignette") {
                    setFilter(CIFilter.vignette())      //radius intensity      i 4
                }
                Button("Bloom") {
                    setFilter(CIFilter.bloom())         //radius intensity 0.0-1.0
                }
                Button("X-Ray") {
                    setFilter(CIFilter.xRay())
                }
                Button("Thermal") {
                    setFilter(CIFilter.thermal())
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    func changeFilter() {
        showingFilters = true
    }
    
    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
            guard let inputImage = UIImage(data: imageData) else { return }
            
            let beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyProcessing()
        }
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(filterIntensity * 10, forKey: kCIInputIntensityKey)
        }
        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(filterRadius * 50, forKey: kCIInputRadiusKey)
        }
        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey)
        }
        
        guard let outputImage = currentFilter.outputImage else { return }
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        processedImage = Image(uiImage: uiImage)
    }
    
    @MainActor func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
        
        filterCount += 1
        if filterCount >= 20 {
            requestReview()
        }
    }
    
    func disableSlider() -> Bool {
        selectedItem == nil
    }
}

#Preview {
    ContentView()
}
