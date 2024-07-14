import SwiftUI

struct LoadingView: View {
    @State private var isLocked = true
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.top, 50)
                    .transition(.opacity)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                            self.isLocked.toggle()
                        }
                    }
                Spacer()
            }
            Text("Loading...")
                .font(.largeTitle)
                .padding(.top, 20)
            Spacer()
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
