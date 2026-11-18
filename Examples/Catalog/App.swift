import SwiftUI
import UIBehaviorCore
import UIBehaviorSwiftUI
import UIBehaviorUIKit

@main
struct CatalogApp: App {
    var body: some Scene { WindowGroup { Catalog() } }
}

struct Catalog: View {
    @State private var selection = Selection<String>(mode: .multiple)
    @State private var details = Disclosure()
    @State private var sheet = Disclosure()
    @State private var volume = BoundedValue(40, in: 0...100, step: 10)
    @State private var name = ""
    @State private var validation = FieldValidation()
    var body: some View {
        NavigationStack {
            Form {
                Section("Selection + focus + typeahead") {
                    BehaviorChoiceList(["SwiftUI", "UIKit", "Unavailable"], selection: $selection,
                                       disabled: ["Unavailable"], label: { $0 }) { id, selected in
                        HStack { Text(id); Spacer(); if selected { Image(systemName: "checkmark.circle.fill") } }
                            .frame(minHeight: 44)
                    }
                    Text("Selected: " + selection.selected.sorted().joined(separator: ", "))
                        .accessibilityIdentifier("selection-status")
                }
                Section("Disclosure + native presentation") {
                    BehaviorDisclosure($details) { Text("How it works") } content: {
                        Text("Compose small behaviors. Keep your own design.")
                    }
                    Button("Open sheet") { sheet.open() }
                }
                Section("One value, two controls") {
                    BehaviorSlider($volume) { Text("Volume") }
                    BehaviorStepper($volume) { Text("Volume: \(Int(volume.value))") }
                }
                Section("Field validation") {
                    BehaviorField("Project name", text: $name, validation: $validation) {
                        $0.isEmpty ? ["Enter a project name"] : []
                    }
                }
                Section("UIKit adapter") {
                    NavigationLink("Open UIKit choices") { UIKitChoices().ignoresSafeArea(edges: .bottom) }
                }
            }
            .navigationTitle("iosUI-sdk")
            .behaviorSheet($sheet) {
                VStack(spacing: 24) {
                    Text("Native presentation").font(.title)
                    Button("Close sheet") { sheet.dismiss(.action) }
                }.padding()
            }
        }
    }
}

struct UIKitChoices: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> BehaviorChoiceController<String> {
        BehaviorChoiceController(["Selection", "Focus", "Typeahead"], label: { $0 })
    }
    func updateUIViewController(_ controller: BehaviorChoiceController<String>, context: Context) {}
}
