import SwiftUI

struct SliderWithPoints: View {
    @Binding var value: Double
    let bounds: ClosedRange<Double>
    let step: Double
    
    init(value: Binding<Double>, in bounds: ClosedRange<Double>, step: Double = 1) {
        self._value = value
        self.bounds = bounds
        self.step = step
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Slider(value: $value, in: bounds, step: step)
                    .accentColor(.white)
                
                HStack(spacing: 0) {
                    ForEach(0..<6) { i in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .onTapGesture {
                                let newValue = bounds.lowerBound + (bounds.upperBound - bounds.lowerBound) * Double(i) / 6
                                value = newValue
                            }
                            .padding(.leading, i == 0 ? 0 : geometry.size.width / 6 )
                    }
                }
            }
        }
        .frame(height: 30)
    }
}

// Add this preview struct at the end of the file
#Preview {
    @Previewable @State var sliderValue = 50.0
    SliderWithPoints(value: $sliderValue, in: 0...100, step: 1)
        .padding().background(.blue)
}
