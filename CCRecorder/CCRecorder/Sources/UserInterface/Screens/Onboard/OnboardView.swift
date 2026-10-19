import SwiftUI

struct OnboardView: View {
    private let pages: [ImageResource] = [
        .Onboarding.page0,
        .Onboarding.page1,
        .Onboarding.page2,
        .Onboarding.page3,
        .Onboarding.page4
    ]
    
    @Binding var isPrsented: Bool
    
    var body: some View {
        TabView {
            ForEach(pages.indices, id: \.self) { index in
                Image(pages[index])
                    .resizable()
                    .scaledToFit()
                    .overlay(alignment: .bottom) {
                        if index == pages.count - 1 {
                            Button(
                                action: {
                                    withAnimation { 
                                        isPrsented.toggle()
                                    }
                                },
                                label: {
                                    Text("앱 시작하기")
                                        .tint(.white)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .padding()
                                        .background(Color.Icon.accent)
                                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                                }
                            )
                            .clipShape(.rect(cornerRadius: 15))
                            .padding(40)
                        }
                    }
                    .clipShape(.rect(cornerRadius: 50))
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(Color.Surface.Recorder.prominent)
    }
    
}

#Preview {
    OnboardView(isPrsented: .constant(true))
}
