import SwiftUI

struct CrisisResourcesView: View {
    private let resources: [(region: String, info: String)] = [
        ("USA", "988 Suicide & Crisis Lifeline (Call or Text 988)"),
        ("Canada", "Talk Suicide Canada: 1-833-456-4566"),
        ("UK", "Samaritans: 116 123"),
        ("EU", "European helplines: ehelp.eutel.europa.eu"),
        ("Global", "Find help: findahelpline.com")
    ]

    var body: some View {
        List {
            Section(footer: Text("If you are in immediate danger, call your local emergency number.")) {
                ForEach(resources, id: \.region) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.region).font(.headline)
                        Text(item.info).font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Crisis Resources")
        .accessibilityElement(children: .contain)
    }
}

struct CrisisResourcesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { CrisisResourcesView() }
    }
}


