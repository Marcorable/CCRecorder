import SwiftUI

struct OnboardView: View {
    @State private var pages: [Page] = (0...4).map { Page(id: $0) }
    
    @Binding var isPrsented: Bool
    
    var body: some View {
        TabView {
            ForEach(pages.indices, id: \.self) { index in
                Image(pages[index].assetName)
                    .resizable()
                    .scaledToFit()
                    .overlay(alignment: .bottom) {
                        if index == pages.count - 1 {
                            Button(
                                action: {
                                    withAnimation { 
                                        isPrsented.toggle()
                                    }
                                }, label: {
                                    Text("앱 시작하기")
                                        .tint(.white)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .padding()
                                        .background(Color.Any.icon)
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
        .background(Color.Light.recorder)
    }
    
}

fileprivate struct Page {
    let id: Int
    var assetName: String { "iphoneX_\(id)" }
}

#Preview {
    OnboardView(isPrsented: .constant(true))
}
